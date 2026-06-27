import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aquatrack_pro/core/constants/firebase_constants.dart';
import 'package:aquatrack_pro/core/errors/exceptions.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';
import 'package:aquatrack_pro/core/services/ai_model_router.dart';
import 'package:aquatrack_pro/core/services/minhash_service.dart';
import 'package:aquatrack_pro/core/services/web_search_service.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/models/ai_message_model.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';

abstract class AiRemoteDataSource {
  Future<AiMessageModel> sendToGemini({
    required String userId,
    required String athleteId,
    required String question,
    required String context,
    required AiCategory category,
    required String systemPrompt,
    required List<String> kbChunks,
    required List<WebSearchResult> webResults,
    List<AiMessageEntity> history = const [],
  });

  Stream<String> sendToGeminiStream({
    required String userId,
    required String athleteId,
    required String question,
    required String context,
    required AiCategory category,
    required String systemPrompt,
    required List<String> kbChunks,
    required List<WebSearchResult> webResults,
    List<AiMessageEntity> history = const [],
  });

  Future<void> saveMessage(AiMessageModel message);

  Future<List<AiMessageModel>> getHistory(String userId, String athleteId);

  Future<int> getMessageCountToday(String userId);

  Future<void> clearHistory(String userId, String athleteId);

  Future<void> updateFeedback(String messageId, UserFeedback feedback);
}

class AiRemoteDataSourceImpl implements AiRemoteDataSource {
  final FirebaseFirestore firestore;
  final AiModelRouter router;
  final WebSearchService webSearch;
  final MinHashService minhash;

  static const int _cacheMaxSize = 20;
  static const Duration _cacheTtl = Duration(minutes: 5);
  static const Duration _persistentCacheTtl = Duration(days: 7);

  final LinkedHashMap<String, _CacheEntry> _responseCache = LinkedHashMap();

  AiRemoteDataSourceImpl({
    required this.firestore,
    required this.router,
    required this.webSearch,
    MinHashService? minhash,
  }) : minhash = minhash ?? MinHashService();

  String _cacheKey(String question, String context) =>
      '${question.trim().toLowerCase()}|${context.hashCode}';

  AiMessageModel? _getCached(String key) {
    final entry = _responseCache[key];
    if (entry != null && !entry.isExpired(_cacheTtl)) {
      _responseCache.remove(key);
      _responseCache[key] = entry;
      return entry.response;
    }
    if (entry != null) _responseCache.remove(key);
    return null;
  }

  void _setCache(String key, AiMessageModel response) {
    if (_responseCache.length >= _cacheMaxSize) {
      _responseCache.remove(_responseCache.keys.first);
    }
    _responseCache[key] = _CacheEntry(response);
  }

  String _persistentCacheKey(String userId, String athleteId, String question) {
    final normalized = question.trim().toLowerCase();
    final hash = normalized.hashCode.toRadixString(16).padLeft(8, '0');
    return '${userId}_${athleteId}_$hash';
  }

  Future<AiMessageModel?> _getPersistentCache(
    String userId, String athleteId, String question, {AiCategory? category,
  }) async {
    try {
      final key = _persistentCacheKey(userId, athleteId, question);
      final doc = await firestore
          .collection(FirebaseCollections.aiCache)
          .doc(key)
          .get();
      if (!doc.exists) return null;
      final data = doc.data()!;
      final cachedAt = (data['cachedAt'] as Timestamp).toDate();
      if (DateTime.now().difference(cachedAt) > _persistentCacheTtl) {
        await doc.reference.delete();
        return null;
      }
      return AiMessageModel(
        id: data['messageId'] as String? ?? key,
        userId: userId,
        athleteId: athleteId,
        question: question,
        answer: data['answer'] as String? ?? '',
        citations: (data['citations'] as List<dynamic>?)
            ?.map((e) => e as String).toList() ?? [],
        category: data['category'] != null
            ? AiCategory.values.firstWhere((e) => e.name == data['category'])
            : (category ?? AiCategory.general),
        timestamp: cachedAt,
      );
    } catch (e) {
      debugPrint('[AiDS] Persistent cache error: $e');
      return null;
    }
  }

  Future<void> _saveToPersistentCache({
    required String userId,
    required String athleteId,
    required String question,
    required String answer,
    required List<String> citations,
    required AiCategory category,
    required String messageId,
  }) async {
    try {
      final key = _persistentCacheKey(userId, athleteId, question);
      await firestore
          .collection(FirebaseCollections.aiCache)
          .doc(key)
          .set({
        'messageId': messageId,
        'userId': userId,
        'athleteId': athleteId,
        'question': question.trim().toLowerCase(),
        'answer': answer,
        'citations': citations,
        'category': category.name,
        'cachedAt': Timestamp.fromDate(DateTime.now()),
      });
    } catch (e) {
      debugPrint('[AiDS] Persistent cache save error: $e');
    }
  }

  @override
  Future<AiMessageModel> sendToGemini({
    required String userId,
    required String athleteId,
    required String question,
    required String context,
    required AiCategory category,
    required String systemPrompt,
    required List<String> kbChunks,
    required List<WebSearchResult> webResults,
    List<AiMessageEntity> history = const [],
  }) async {
    final q = question.trim();
    if (q.isEmpty) throw ServerException(message: 'السؤال فارغ.');

    final hasStrongKB = kbChunks.isNotEmpty;
    final citations = <String>[];
    if (hasStrongKB) {
      citations.add('📚 المكتبة المرجعية');
    }
    for (final r in webResults) {
      citations.add('${r.sourceLabel}: ${r.url}');
    }

    // L1: In-memory cache (exact match, fast)
    final cacheKey = _cacheKey(q, context);
    final memCached = _getCached(cacheKey);
    if (memCached != null && history.isEmpty) {
      debugPrint('[AiDS] Memory cache hit for: $q');
      return memCached;
    }

    // L1.5: MinHash semantic cache (similar questions)
    if (history.isEmpty) {
      final semHit = minhash.findSimilar(
        userId: userId,
        athleteId: athleteId,
        contextHash: context.hashCode,
        question: q,
      );
      if (semHit != null) {
        debugPrint('[AiDS] MinHash semantic cache hit for: $q');
        final semantic = AiMessageModel(
          id: '${userId}_${athleteId}_${q.trim().toLowerCase().hashCode.toRadixString(16).padLeft(8, '0')}_sem',
          userId: userId,
          athleteId: athleteId,
          question: q,
          answer: semHit.answer,
          citations: List.from(semHit.citations),
          category: AiCategory.values.firstWhere(
            (e) => e.name == semHit.categoryName,
            orElse: () => category,
          ),
          timestamp: semHit.timestamp,
        );
        _setCache(cacheKey, semantic);
        return semantic;
      }
    }

    // L2: Firestore persistent cache (survives restarts)
    if (history.isEmpty) {
      final persistent = await _getPersistentCache(userId, athleteId, q);
      if (persistent != null) {
        debugPrint('[AiDS] Firestore cache hit for: $q');
        _setCache(cacheKey, persistent);
        minhash.add(
          userId: userId,
          athleteId: athleteId,
          contextHash: context.hashCode,
          question: q,
          answer: persistent.answer,
          citations: persistent.citations,
          categoryName: persistent.category.name,
        );
        return persistent;
      }
    }

    // Route through AI models
    try {
      final complexity = router.classifyQuery(q);
      debugPrint('[AiDS] Routing (complexity: $complexity)...');

      final stopwatch = Stopwatch()..start();
      final response = await router.route(systemPrompt, q, complexity: complexity);
      stopwatch.stop();

      debugPrint('[AiDS] Success: ${response.modelName} (${stopwatch.elapsed.inSeconds}s)');

      _logUsage(
        modelName: response.modelName,
        provider: response.provider,
        complexity: complexity.name,
        success: true,
        elapsedMs: stopwatch.elapsedMilliseconds,
        hasStrongKB: hasStrongKB,
        webSearchUsed: webResults.isNotEmpty,
      );

      citations.add('🤖 ${response.modelName}');

      final result = AiMessageModel.fromGeminiResponse(
        userId: userId,
        athleteId: athleteId,
        question: q,
        answer: response.text.trim().isNotEmpty
            ? response.text.trim()
            : 'عذراً، لم أتمكن من إنشاء رد.',
        citations: citations,
        category: category,
      );
      _setCache(cacheKey, result);
      await _saveToPersistentCache(
        userId: userId,
        athleteId: athleteId,
        question: q,
        answer: result.answer,
        citations: result.citations,
        category: category,
        messageId: result.id,
      );
      minhash.add(
        userId: userId,
        athleteId: athleteId,
        contextHash: context.hashCode,
        question: q,
        answer: result.answer,
        citations: result.citations,
        categoryName: category.name,
      );
      return result;
    } on AllModelsExhausted {
      debugPrint('[AiDS] All AI models exhausted — using trusted web fallback');
      _logUsage(
        modelName: '',
        provider: '',
        complexity: '',
        success: false,
        errorType: 'AllModelsExhausted',
        hasStrongKB: hasStrongKB,
        webSearchUsed: webResults.isNotEmpty,
      );
      return await _fallbackWithTrustedWeb(q, category, kbChunks);
    } catch (e) {
      debugPrint('[AiDS] Unexpected error: $e');
      _logUsage(
        modelName: '',
        provider: '',
        complexity: '',
        success: false,
        errorType: e.runtimeType.toString(),
        hasStrongKB: hasStrongKB,
        webSearchUsed: webResults.isNotEmpty,
      );
      return await _fallbackWithTrustedWeb(q, category, kbChunks);
    }
  }

  @override
  Stream<String> sendToGeminiStream({
    required String userId,
    required String athleteId,
    required String question,
    required String context,
    required AiCategory category,
    required String systemPrompt,
    required List<String> kbChunks,
    required List<WebSearchResult> webResults,
    List<AiMessageEntity> history = const [],
  }) async* {
    final q = question.trim();
    if (q.isEmpty) throw ServerException(message: 'السؤال فارغ.');

    final citations = <String>[];
    if (kbChunks.isNotEmpty) {
      citations.add('📚 المكتبة المرجعية');
    }
    for (final r in webResults) {
      citations.add('${r.sourceLabel}: ${r.url}');
    }

    try {
      final complexity = router.classifyQuery(q);
      final chunks = <String>[];
      await for (final chunk in router.routeStream(systemPrompt, q, complexity: complexity)) {
        chunks.add(chunk);
        yield chunk;
      }
      final fullAnswer = chunks.join();
      citations.add('🤖 $complexity');

      final result = AiMessageModel.fromGeminiResponse(
        userId: userId,
        athleteId: athleteId,
        question: q,
        answer: fullAnswer.trim().isNotEmpty ? fullAnswer.trim() : 'عذراً، لم أتمكن من إنشاء رد.',
        citations: citations,
        category: category,
      );
      _setCache(_cacheKey(q, context), result);
      await _saveToPersistentCache(
        userId: userId,
        athleteId: athleteId,
        question: q,
        answer: result.answer,
        citations: result.citations,
        category: category,
        messageId: result.id,
      );
      minhash.add(
        userId: userId,
        athleteId: athleteId,
        contextHash: context.hashCode,
        question: q,
        answer: result.answer,
        citations: result.citations,
        categoryName: category.name,
      );
    } on AllModelsExhausted {
      yield '⚠️ جميع النماذج غير متوفرة حالياً. سيتم استخدام المصادر الموثوقة.';
    } catch (e) {
      debugPrint('[AiDS] Stream error: $e');
      yield '⚠️ حدث خطأ أثناء إنشاء الرد: $e';
    }
  }

  void _logUsage({
    required String modelName,
    required String provider,
    required String complexity,
    required bool success,
    String? errorType,
    int? elapsedMs,
    required bool hasStrongKB,
    required bool webSearchUsed,
  }) {
    try {
      firestore.collection(FirebaseCollections.modelUsage).add({
        'modelName': modelName,
        'provider': provider,
        'complexity': complexity,
        'success': success,
        'errorType': errorType,
        'elapsedMs': elapsedMs,
        'hasStrongKB': hasStrongKB,
        'webSearchUsed': webSearchUsed,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('[AiDS] Usage logging failed: $e');
    }
  }

  Future<AiMessageModel> _fallbackWithTrustedWeb(
    String question,
    AiCategory category,
    List<String> kbChunks,
  ) async {
    final citations = <String>['⚠️ رد تلقائي — المواقع الموثوقة'];
    String answer;

    try {
      final trusted = await webSearch.searchTrusted(question, limit: 2);
      if (trusted.isNotEmpty) {
        final parts = <String>[];
        parts.add('بناءً على مصادر طبية ورياضية موثوقة:');
        parts.add('');
        for (int i = 0; i < trusted.length; i++) {
          final r = trusted[i];
          parts.add('━━━━━━━━━━━━━━━━━━');
          parts.add('**${r.title}**');
          parts.add('');
          parts.add(r.snippet);
          parts.add('');
          parts.add('المصدر: ${r.sourceLabel}');
          parts.add('');
          citations.add('${r.sourceLabel}: ${r.url}');
        }
        answer = parts.join('\n');
      } else if (kbChunks.isNotEmpty) {
        final snippet = kbChunks.first.length > 500
            ? '${kbChunks.first.substring(0, 500)}...'
            : kbChunks.first;
        answer = 'من المكتبة المرجعية:\n\n$snippet';
      } else {
        answer = 'عذراً، لم أتمكن من العثور على إجابة في قاعدة المعرفة أو المصادر الموثوقة. يرجى المحاولة مرة أخرى لاحقاً.';
      }
    } catch (e) {
      debugPrint('[Fallback] Error: $e');
      if (kbChunks.isNotEmpty) {
        final snippet = kbChunks.first.length > 500
            ? '${kbChunks.first.substring(0, 500)}...'
            : kbChunks.first;
        answer = snippet;
      } else {
        answer = 'عذراً، حدث خطأ أثناء البحث. يرجى المحاولة مرة أخرى.';
      }
    }

    return AiMessageModel.fromGeminiResponse(
      userId: '',
      athleteId: '',
      question: question,
      answer: '$answer\n\n(⚠️ تم تجاوز حصة النماذج الأساسية — تم استخدام المصادر الموثوقة)',
      citations: citations,
      category: category,
      timestamp: DateTime.now(),
    );
  }

  @override
  Future<void> saveMessage(AiMessageModel message) async {
    await firestore
        .collection(FirebaseCollections.aiRecommendations)
        .doc(message.id)
        .set(message.toFirestore());
  }

  /// Requires Firestore composite index on [userId, athleteId, timestamp]
  @override
  Future<List<AiMessageModel>> getHistory(String userId, String athleteId) async {
    final query = await firestore
        .collection(FirebaseCollections.aiRecommendations)
        .where('userId', isEqualTo: userId)
        .where('athleteId', isEqualTo: athleteId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return query.docs
        .map((doc) => AiMessageModel.fromFirestore(doc))
        .toList();
  }

  /// Requires Firestore composite index on [userId, timestamp] for optimal performance.
  /// Falls back to client-side filtering if index is missing.
  @override
  Future<int> getMessageCountToday(String userId) async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    try {
      final query = await firestore
          .collection(FirebaseCollections.aiRecommendations)
          .where('userId', isEqualTo: userId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .get();
      return query.docs.length;
    } catch (_) {
      final all = await firestore
          .collection(FirebaseCollections.aiRecommendations)
          .where('userId', isEqualTo: userId)
          .get();
      final cutoff = Timestamp.fromDate(startOfDay);
      return all.docs.where((d) {
        final ts = d.data()['timestamp'] as Timestamp?;
        return ts != null && ts.seconds >= cutoff.seconds;
      }).length;
    }
  }

  @override
  Future<void> clearHistory(String userId, String athleteId) async {
    const batchLimit = 500;
    QuerySnapshot query;
    do {
      query = await firestore
          .collection(FirebaseCollections.aiRecommendations)
          .where('userId', isEqualTo: userId)
          .where('athleteId', isEqualTo: athleteId)
          .limit(batchLimit)
          .get();
      if (query.docs.isEmpty) break;
      final batch = firestore.batch();
      for (final doc in query.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } while (query.docs.length >= batchLimit);
  }

  @override
  Future<void> updateFeedback(String messageId, UserFeedback feedback) async {
    try {
      await firestore
          .collection(FirebaseCollections.aiRecommendations)
          .doc(messageId)
          .update({'feedback': feedback.name});
    } catch (e) {
      debugPrint('[AiDS] Feedback update error: $e');
    }
  }
}

class _CacheEntry {
  final AiMessageModel response;
  final DateTime _cachedAt;

  _CacheEntry(this.response) : _cachedAt = DateTime.now();

  bool isExpired(Duration ttl) =>
      DateTime.now().difference(_cachedAt) > ttl;
}
