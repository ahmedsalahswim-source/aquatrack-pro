import 'package:dartz/dartz.dart';
import 'package:uuid/uuid.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';
import 'package:aquatrack_pro/core/services/knowledge_base_service.dart';
import 'package:aquatrack_pro/core/services/prompt_builder.dart';
import 'package:aquatrack_pro/core/services/web_search_service.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/models/ai_message_model.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/entities/ai_message_entity.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';

class AiRepositoryImpl implements AiRepository {
  final AiRemoteDataSource remoteDataSource;
  final KnowledgeBaseService knowledgeBase;
  final WebSearchService webSearch;
  final PromptBuilder promptBuilder;

  static const double _strongKbScore = 0.4;
  static const double _minKbScore = 0.1;

  AiRepositoryImpl({
    required this.remoteDataSource,
    required this.knowledgeBase,
    required this.webSearch,
    required this.promptBuilder,
  });

  @override
  Future<Either<Failure, AiMessageEntity>> sendMessage({
    required String userId,
    required String athleteId,
    required String athleteName,
    required String question,
    required Map<String, dynamic> context,
    List<AiMessageEntity> history = const [],
  }) async {
    try {
      final contextStr = _buildContextString(athleteName, context);
      final category = _inferCategory(question);
      final q = question.trim();
      if (q.isEmpty) return Left(ServerFailure(message: 'السؤال فارغ.'));

      // 1. Search KB (massive context for deep professional usage)
      final kbResults = knowledgeBase.searchExpanded(q, limit: 30, minScore: _minKbScore);
      final hasStrongKB = kbResults.any((r) => r.score >= _strongKbScore);
      final kbChunks = kbResults.map((r) => r.chunk).toList();

      // 2. Only search web if KB is insufficient
      final webResults = hasStrongKB
          ? <WebSearchResult>[]
          : await webSearch.search(q, limit: 3);

      // 3. Build system prompt with all context
      final conversationHistory = _formatConversationHistory(history);
      final systemPrompt = promptBuilder.buildSystemPrompt(
        swimmerContext: contextStr,
        kbResults: kbChunks,
        webResults: webResults,
        userQuery: q,
        conversationHistory: conversationHistory,
      );

      final model = await remoteDataSource.sendToGemini(
        userId: userId,
        athleteId: athleteId,
        question: question,
        context: contextStr,
        category: category,
        systemPrompt: systemPrompt,
        kbChunks: kbChunks.map((c) => c.content).toList(),
        webResults: webResults,
        history: history,
      );

      final savedModel = AiMessageModel(
        id: const Uuid().v4(),
        userId: userId,
        athleteId: athleteId,
        question: question,
        answer: model.answer,
        citations: model.citations,
        category: category,
        timestamp: DateTime.now(),
      );

      await remoteDataSource.saveMessage(savedModel);
      return Right(savedModel);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Stream<String> sendMessageStream({
    required String userId,
    required String athleteId,
    required String athleteName,
    required String question,
    required Map<String, dynamic> context,
    List<AiMessageEntity> history = const [],
  }) async* {
    final contextStr = _buildContextString(athleteName, context);
    final category = _inferCategory(question);
    final q = question.trim();
    if (q.isEmpty) return;

    final kbResults = knowledgeBase.searchExpanded(q, limit: 30, minScore: _minKbScore);
    final kbChunks = kbResults.map((r) => r.chunk).toList();
    final webResults = kbResults.any((r) => r.score >= _strongKbScore)
        ? <WebSearchResult>[]
        : await webSearch.search(q, limit: 3);

    final conversationHistory = _formatConversationHistory(history);
    final systemPrompt = promptBuilder.buildSystemPrompt(
      swimmerContext: contextStr,
      kbResults: kbChunks,
      webResults: webResults,
      userQuery: q,
      conversationHistory: conversationHistory,
    );

    yield* remoteDataSource.sendToGeminiStream(
      userId: userId,
      athleteId: athleteId,
      question: question,
      context: contextStr,
      category: category,
      systemPrompt: systemPrompt,
      kbChunks: kbChunks.map((c) => c.content).toList(),
      webResults: webResults,
      history: history,
    );
  }

  List<String> _formatConversationHistory(List<AiMessageEntity> history) {
    if (history.isEmpty) return [];
    final lastMessages = history.length > 6 ? history.sublist(history.length - 6) : history;
    return lastMessages.map((m) {
      final role = m.trigger == AiTrigger.userQuery ? 'المستخدم' : 'المساعد';
      return '$role: ${m.trigger == AiTrigger.userQuery ? m.question : m.answer}';
    }).toList();
  }

  String _buildContextString(String athleteName, Map<String, dynamic> ctx) {
    if (ctx.containsKey('_fullContext')) {
      return ctx['_fullContext'] as String;
    }
    final parts = <String>[];
    parts.add('الرياضي: $athleteName');
    if (ctx['age'] != null) parts.add('العمر: ${ctx['age']} سنة');
    if (ctx['gender'] != null) parts.add('الجنس: ${ctx['gender']}');
    if (ctx['sleep'] != null) parts.add('النوم اليوم: ${ctx['sleep']} ساعات');
    if (ctx['hr'] != null) parts.add('نبض الراحة: ${ctx['hr']} BPM');
    if (ctx['acwr'] != null) parts.add('ACWR: ${ctx['acwr']}');
    if (ctx['stress'] != null) parts.add('مؤشر الإجهاد: ${ctx['stress']}');
    if (ctx['avgSleep'] != null) {
      parts.add('متوسط النوم (7 أيام): ${ctx['avgSleep']} ساعات');
    }
    if (ctx['avgHr'] != null) {
      parts.add('متوسط النبض (7 أيام): ${ctx['avgHr']} BPM');
    }
    return parts.join('\n');
  }

  AiCategory _inferCategory(String question) {
    final q = question.toLowerCase();
    if (q.contains('نوم') || q.contains('sleep') || q.contains('nap')) {
      return AiCategory.sleep;
    }
    if (q.contains('تغذ') || q.contains('اكل') || q.contains('food') ||
        q.contains('nutrition') || q.contains('eat') || q.contains('protein')) {
      return AiCategory.nutrition;
    }
    if (q.contains('تدريب') || q.contains('تمرين') || q.contains('train') ||
        q.contains('practice') || q.contains('workout')) {
      return AiCategory.training;
    }
    if (q.contains('تعافي') || q.contains('راحة') || q.contains('recovery') ||
        q.contains('rest') || q.contains('fatigue')) {
      return AiCategory.recovery;
    }
    if (q.contains('إصابة') || q.contains('الم') || q.contains('injury') ||
        q.contains('pain') || q.contains('hurt')) {
      return AiCategory.injury;
    }
    return AiCategory.general;
  }

  @override
  Future<Either<Failure, List<AiMessageEntity>>> getHistory({
    required String userId,
    required String athleteId,
  }) async {
    try {
      final models = await remoteDataSource.getHistory(userId, athleteId);
      return Right(models);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, int>> getMessagesUsedToday(String userId) async {
    try {
      final count = await remoteDataSource.getMessageCountToday(userId);
      return Right(count);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> clearHistory(
    String userId, String athleteId) async {
    try {
      await remoteDataSource.clearHistory(userId, athleteId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> updateFeedback(
    String messageId, UserFeedback feedback) async {
    try {
      await remoteDataSource.updateFeedback(messageId, feedback);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(message: e.toString()));
    }
  }
}
