import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:aquatrack_pro/core/config/ai_config.dart';

enum QueryComplexity {
  simple,
  normal,
  complex,
  analytical,
}

class AiResponse {
  final String text;
  final String modelName;
  final String provider;

  const AiResponse({
    required this.text,
    required this.modelName,
    required this.provider,
  });
}

class AllModelsExhausted implements Exception {
  final String message;
  const AllModelsExhausted([this.message = '']);
}

class AiModelRouter {
  final Dio _dio;
  final List<AiModelConfigData> _models;
  final Duration _cooldownDuration;
  int _rpmCounter = 0;
  DateTime _rpmResetAt = DateTime.now();

  AiModelRouter({
    Dio? dio,
    List<AiModelConfigData>? models,
    Duration? cooldownDuration,
  })  : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 20),
          contentType: 'application/json',
        )),
        _models = (models ?? AiConfig.models).toList(),
        _cooldownDuration = cooldownDuration ?? const Duration(minutes: 3);

  QueryComplexity classifyQuery(String query) {
    final q = query.toLowerCase().trim();
    final wordCount = q.split(RegExp(r'\s+')).length;

    if (wordCount < 3) return QueryComplexity.simple;

    final hasGreeting = RegExp(r'^(مرحبا|اهلا|السلام|hi|hello|hey|شلون|كيف)\b').hasMatch(q);
    if (hasGreeting && wordCount < 5) return QueryComplexity.simple;

    final hasQuestionMark = q.contains('?') || q.contains('؟');
    final hasComparison = RegExp(r'(مقارنة|الفرق|أفضل|compare|difference|vs\.|أو|ne?ither|better)').hasMatch(q);
    final hasAnalysis = RegExp(r'(حلل|قيم|explain|why|how|لذا|بسبب|أسباب|تحليل|تقييم)').hasMatch(q);
    final hasMultipleQuestions = q.split(RegExp(r'[؟?]\s*')).length > 2;

    final hasDataRef = RegExp(r'(نبض|نوم|acwr|بيانات|معدل|متوسط|إجهاد|stress|heart rate|sleep|hr)').hasMatch(q);

    if (hasDataRef && hasAnalysis) return QueryComplexity.analytical;
    if ((hasComparison || hasMultipleQuestions) && (hasAnalysis || wordCount > 12)) return QueryComplexity.complex;
    if (hasComparison || hasAnalysis || wordCount > 15) return QueryComplexity.complex;
    if (hasDataRef && hasQuestionMark) return QueryComplexity.analytical;

    if (wordCount > 8 && hasQuestionMark) return QueryComplexity.normal;
    if (wordCount > 5) return QueryComplexity.normal;

    return QueryComplexity.simple;
  }

  List<AiModelConfigData> _modelsForComplexity(QueryComplexity complexity, {Set<ModelCapability>? required}) {
    List<AiModelConfigData> candidates;

    switch (complexity) {
      case QueryComplexity.simple:
        candidates = _models.where((m) =>
          m.capabilities.contains(ModelCapability.fastResponse) &&
          !m.capabilities.contains(ModelCapability.deepReasoning)
        ).toList();
        if (candidates.length < 2) {
          candidates = _models.where((m) =>
            m.capabilities.contains(ModelCapability.fastResponse)
          ).toList();
        }
        break;
      case QueryComplexity.normal:
        candidates = _models.where((m) =>
          m.capabilities.contains(ModelCapability.multilingual)
        ).toList();
        break;
      case QueryComplexity.complex:
        candidates = _models.where((m) =>
          m.capabilities.contains(ModelCapability.deepReasoning)
        ).toList();
        if (candidates.isEmpty) {
          candidates = _models.where((m) =>
            m.capabilities.contains(ModelCapability.reasoning)
          ).toList();
        }
        break;
      case QueryComplexity.analytical:
        candidates = _models.where((m) =>
          m.capabilities.contains(ModelCapability.deepReasoning) &&
          m.capabilities.contains(ModelCapability.longContext)
        ).toList();
        if (candidates.isEmpty) {
          candidates = _models.where((m) =>
            m.capabilities.contains(ModelCapability.reasoning)
          ).toList();
        }
        break;
    }

    final requiredCaps = required;
    if (requiredCaps != null && requiredCaps.isNotEmpty) {
      candidates = candidates.where((m) =>
        requiredCaps.every((c) => m.capabilities.contains(c))
      ).toList();
    }

    return candidates;
  }

  void _checkDailyReset(AiModelConfigData model) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (model.dayResetAt == null || model.dayResetAt!.isBefore(today)) {
      final idx = _models.indexOf(model);
      if (idx != -1) {
        _models[idx] = model.copyWith(todayUsageCount: 0, dayResetAt: today);
      }
    }
  }

  void _checkRpmReset() {
    final now = DateTime.now();
    if (now.difference(_rpmResetAt).inSeconds > 60) {
      _rpmCounter = 0;
      _rpmResetAt = now;
    }
  }

  AiModelConfigData? _modelAvailable(AiModelConfigData model) {
    _checkDailyReset(model);
    if (!model.available) {
      if (DateTime.now().isBefore(model.nextRetryAt)) return null;
      return model.copyWith(available: true);
    }
    if (model.todayUsageCount >= model.dailyLimit) return null;
    return model;
  }

  Future<AiResponse> route(
    String systemPrompt,
    String userPrompt, {
    Set<ModelCapability>? required,
    QueryComplexity? complexity,
  }) {
    final actualComplexity = complexity ?? classifyQuery(userPrompt);
    debugPrint('[AiRouter] Complexity: $actualComplexity for "${userPrompt.substring(0, userPrompt.length.clamp(0, 60))}"');

    final modelsToTry = _modelsForComplexity(actualComplexity, required: required);

    // Fall back to all models if no candidates match
    if (modelsToTry.isEmpty) {
      return _tryModels(_models, systemPrompt, userPrompt, required: required);
    }

    return _tryModels(modelsToTry, systemPrompt, userPrompt, required: required);
  }

  Future<AiResponse> _tryModels(
    List<AiModelConfigData> models,
    String systemPrompt,
    String userPrompt, {
    Set<ModelCapability>? required,
  }) async {
    for (final model in models) {
      final availableModel = _modelAvailable(model);
      if (availableModel == null) continue;
      if (required != null && !required.every((c) => availableModel.capabilities.contains(c))) continue;

      final modelIdx = _models.indexOf(availableModel);
      if (modelIdx == -1) continue;

      final keysToTry = availableModel.apiKeys.length;
      for (int attempt = 0; attempt < keysToTry; attempt++) {
        _checkRpmReset();
        if (_rpmCounter >= availableModel.rpmLimit) {
          debugPrint('[AiRouter] RPM limit hit for ${availableModel.name}, skipping');
          continue;
        }

        final keyIndex = availableModel.currentKeyIndex;
        final key = availableModel.apiKeys[keyIndex];

        try {
          final text = await _callModel(availableModel, key, systemPrompt, userPrompt);
          _rpmCounter++;
          _models[modelIdx] = availableModel.copyWith(
            currentKeyIndex: (keyIndex + 1) % availableModel.apiKeys.length,
            todayUsageCount: availableModel.todayUsageCount + 1,
          );
          debugPrint('[AiRouter] ✓ ${_models[modelIdx].name} via ${_models[modelIdx].provider} (day: ${_models[modelIdx].todayUsageCount}/${_models[modelIdx].dailyLimit})');
          return AiResponse(text: text, modelName: _models[modelIdx].name, provider: _models[modelIdx].provider);
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 429 || status == 401 || status == 403) {
            debugPrint('[AiRouter] Quota/auth ${availableModel.name}: $status');
            if (attempt == keysToTry - 1) {
              _models[modelIdx] = availableModel.copyWith(
                available: false,
                nextRetryAt: DateTime.now().add(_cooldownDuration),
              );
            }
            continue;
          }
          debugPrint('[AiRouter] Error ${availableModel.name}: ${e.message}');
          if (attempt == keysToTry - 1) {
            _models[modelIdx] = availableModel.copyWith(
              available: false,
              nextRetryAt: DateTime.now().add(_cooldownDuration),
            );
          }
        } catch (e) {
          debugPrint('[AiRouter] Unexpected ${availableModel.name}: $e');
          if (attempt == keysToTry - 1) {
            _models[modelIdx] = availableModel.copyWith(
              available: false,
              nextRetryAt: DateTime.now().add(_cooldownDuration),
            );
          }
        }
      }
    }
    throw const AllModelsExhausted('جميع نماذج الذكاء الاصطناعي غير متوفرة حالياً.');
  }

  Future<String> _callModel(AiModelConfigData model, String key, String systemPrompt, String userPrompt) {
    switch (model.provider) {
      case 'gemini':
        return _callGemini(model, key, systemPrompt, userPrompt);
      case 'openai':
        return _callOpenAICompatible(model, key, systemPrompt, userPrompt);
      default:
        throw UnsupportedError('Provider ${model.provider} not supported');
    }
  }

  Stream<String> routeStream(
    String systemPrompt,
    String userPrompt, {
    Set<ModelCapability>? required,
    QueryComplexity? complexity,
  }) async* {
    final actualComplexity = complexity ?? classifyQuery(userPrompt);
    final modelsToTry = _modelsForComplexity(actualComplexity, required: required);
    final candidates = modelsToTry.isEmpty ? _models : modelsToTry;

    for (final model in candidates) {
      final availableModel = _modelAvailable(model);
      if (availableModel == null) continue;
      if (required != null && !required.every((c) => availableModel.capabilities.contains(c))) continue;

      final modelIdx = _models.indexOf(availableModel);
      if (modelIdx == -1) continue;

      final keysToTry = availableModel.apiKeys.length;
      for (int attempt = 0; attempt < keysToTry; attempt++) {
        _checkRpmReset();
        if (_rpmCounter >= availableModel.rpmLimit) continue;

        final keyIndex = availableModel.currentKeyIndex;
        final key = availableModel.apiKeys[keyIndex];

        try {
          _rpmCounter++;
          final chunks = <String>[];
          await for (final chunk in _callModelStream(availableModel, key, systemPrompt, userPrompt)) {
            chunks.add(chunk);
            yield chunk;
          }
          _models[modelIdx] = availableModel.copyWith(
            currentKeyIndex: (keyIndex + 1) % availableModel.apiKeys.length,
            todayUsageCount: availableModel.todayUsageCount + 1,
          );
          return;
        } on DioException catch (e) {
          final status = e.response?.statusCode;
          if (status == 429 || status == 401 || status == 403) {
            if (attempt == keysToTry - 1) {
              _models[modelIdx] = availableModel.copyWith(
                available: false,
                nextRetryAt: DateTime.now().add(_cooldownDuration),
              );
            }
            continue;
          }
          if (attempt == keysToTry - 1) {
            _models[modelIdx] = availableModel.copyWith(
              available: false,
              nextRetryAt: DateTime.now().add(_cooldownDuration),
            );
          }
        } catch (e) {
          if (attempt == keysToTry - 1) {
            _models[modelIdx] = availableModel.copyWith(
              available: false,
              nextRetryAt: DateTime.now().add(_cooldownDuration),
            );
          }
        }
      }
    }
    throw const AllModelsExhausted('جميع نماذج الذكاء الاصطناعي غير متوفرة حالياً.');
  }

  Stream<String> _callModelStream(AiModelConfigData model, String key, String systemPrompt, String userPrompt) {
    switch (model.provider) {
      case 'gemini':
        return _callGeminiStream(model, key, systemPrompt, userPrompt);
      case 'openai':
        return _callOpenAICompatibleStream(model, key, systemPrompt, userPrompt);
      default:
        throw UnsupportedError('Provider ${model.provider} not supported');
    }
  }

  Stream<String> _callGeminiStream(AiModelConfigData model, String key, String systemPrompt, String userPrompt) async* {
    final url = '${model.baseUrl}/models/${model.model}:streamGenerateContent';
    try {
      final response = await _dio.post(url,
        queryParameters: {'key': key, 'alt': 'sse'},
        data: {
          'contents': [{'parts': [{'text': userPrompt}]}],
          'systemInstruction': {'parts': [{'text': systemPrompt}]},
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': model.maxTokens,
          },
        },
        options: Options(responseType: ResponseType.stream),
      );
      final stream = response.data.stream as Stream<List<int>>;
      final lines = stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr.isEmpty) continue;
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final text = _parseGeminiStreamChunk(data);
            if (text.isNotEmpty) yield text;
          } catch (_) {}
        }
      }
    } finally {}
  }

  Stream<String> _callOpenAICompatibleStream(AiModelConfigData model, String key, String systemPrompt, String userPrompt) async* {
    final url = '${model.baseUrl}/chat/completions';
    final headers = <String, dynamic>{'Authorization': 'Bearer $key'};
    if (model.baseUrl?.contains('openrouter') ?? false) {
      headers['HTTP-Referer'] = 'https://aquatrack-pro.app';
      headers['X-Title'] = 'AquaTrack Pro';
    }
    try {
      final response = await _dio.post(url,
        options: Options(
          headers: headers,
          responseType: ResponseType.stream,
        ),
        data: {
          'model': model.model,
          'messages': [
            {'role': 'system', 'content': systemPrompt},
            {'role': 'user', 'content': userPrompt},
          ],
          'temperature': 0.7,
          'max_tokens': model.maxTokens,
          'stream': true,
        },
      );
      final stream = response.data.stream as Stream<List<int>>;
      final lines = stream
          .transform(const Utf8Decoder())
          .transform(const LineSplitter());
      await for (final line in lines) {
        if (line.startsWith('data: ')) {
          final jsonStr = line.substring(6).trim();
          if (jsonStr == '[DONE]') break;
          try {
            final data = jsonDecode(jsonStr) as Map<String, dynamic>;
            final text = _parseOpenAIStreamChunk(data);
            if (text.isNotEmpty) yield text;
          } catch (_) {}
        }
      }
    } finally {}
  }

  String _parseGeminiStreamChunk(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>?;
    if (content == null) return '';
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';
    return (parts.first as Map<String, dynamic>)['text'] as String? ?? '';
  }

  String _parseOpenAIStreamChunk(Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return '';
    final first = choices.first as Map<String, dynamic>;
    final delta = first['delta'] as Map<String, dynamic>?;
    if (delta == null) return '';
    return delta['content'] as String? ?? '';
  }

  Future<String> _callGemini(AiModelConfigData model, String key, String systemPrompt, String userPrompt) async {
    final url = '${model.baseUrl}/models/${model.model}:generateContent';
    final response = await _dio.post(url, queryParameters: {'key': key}, data: {
      'contents': [{'parts': [{'text': userPrompt}]}],
      'systemInstruction': {'parts': [{'text': systemPrompt}]},
      'generationConfig': {
        'temperature': 0.7,
        'maxOutputTokens': model.maxTokens,
      },
    });
    return _parseGeminiResponse(response.data);
  }

  Future<String> _callOpenAICompatible(AiModelConfigData model, String key, String systemPrompt, String userPrompt) async {
    final url = '${model.baseUrl}/chat/completions';
    final headers = <String, dynamic>{'Authorization': 'Bearer $key'};
    if (model.baseUrl?.contains('openrouter') ?? false) {
      headers['HTTP-Referer'] = 'https://aquatrack-pro.app';
      headers['X-Title'] = 'AquaTrack Pro';
    }
    final response = await _dio.post(url, options: Options(headers: headers), data: {
      'model': model.model,
      'messages': [
        {'role': 'system', 'content': systemPrompt},
        {'role': 'user', 'content': userPrompt},
      ],
      'temperature': 0.7,
      'max_tokens': model.maxTokens,
    });
    return _parseOpenAIResponse(response.data);
  }

  String _parseGeminiResponse(Map<String, dynamic> data) {
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return '';
    final first = candidates.first as Map<String, dynamic>;
    final content = first['content'] as Map<String, dynamic>?;
    if (content == null) return '';
    final parts = content['parts'] as List<dynamic>?;
    if (parts == null || parts.isEmpty) return '';
    return (parts.first as Map<String, dynamic>)['text'] as String? ?? '';
  }

  String _parseOpenAIResponse(Map<String, dynamic> data) {
    final choices = data['choices'] as List<dynamic>?;
    if (choices == null || choices.isEmpty) return '';
    final first = choices.first as Map<String, dynamic>;
    final message = first['message'] as Map<String, dynamic>?;
    if (message == null) return '';
    return message['content'] as String? ?? '';
  }

  void resetAvailability() {
    for (int i = 0; i < _models.length; i++) {
      _models[i] = _models[i].copyWith(available: true, nextRetryAt: DateTime(2000));
    }
  }
}
