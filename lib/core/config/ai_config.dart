import 'package:flutter_dotenv/flutter_dotenv.dart';

enum ModelCapability {
  arabic,
  english,
  multilingual,
  reasoning,
  deepReasoning,
  longContext,
  fastResponse,
}

class AiModelConfigData {
  final String name;
  final String provider;
  final String model;
  final List<String> apiKeys;
  final String? baseUrl;
  final bool requiresAccountId;
  final Set<ModelCapability> capabilities;
  final int maxTokens;
  final int dailyLimit;
  final int rpmLimit;
  final bool available;
  final int currentKeyIndex;
  final int todayUsageCount;
  final DateTime nextRetryAt;
  final DateTime? dayResetAt;

  AiModelConfigData({
    required this.name,
    required this.provider,
    required this.model,
    required this.apiKeys,
    this.baseUrl,
    this.requiresAccountId = false,
    this.capabilities = const {ModelCapability.multilingual, ModelCapability.fastResponse},
    this.maxTokens = 2048,
    this.dailyLimit = 100,
    this.rpmLimit = 30,
    this.available = true,
    this.currentKeyIndex = 0,
    this.todayUsageCount = 0,
    DateTime? nextRetryAt,
    DateTime? dayResetAt,
  })  : nextRetryAt = nextRetryAt ?? DateTime(2000),
        dayResetAt = dayResetAt ?? DateTime(2000);

  AiModelConfigData copyWith({
    bool? available,
    int? currentKeyIndex,
    int? todayUsageCount,
    DateTime? nextRetryAt,
    DateTime? dayResetAt,
  }) {
    return AiModelConfigData(
      name: name,
      provider: provider,
      model: model,
      apiKeys: apiKeys,
      baseUrl: baseUrl,
      requiresAccountId: requiresAccountId,
      capabilities: capabilities,
      maxTokens: maxTokens,
      dailyLimit: dailyLimit,
      rpmLimit: rpmLimit,
      available: available ?? this.available,
      currentKeyIndex: currentKeyIndex ?? this.currentKeyIndex,
      todayUsageCount: todayUsageCount ?? this.todayUsageCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      dayResetAt: dayResetAt ?? this.dayResetAt,
    );
  }
}

class AiConfig {
  AiConfig._();

  static String _env(String key, [String fallback = '']) =>
      dotenv.env[key] ?? fallback;

  static List<String> _keys(String prefix) {
    final keys = <String>[];
    for (int i = 1; ; i++) {
      final k = _env('$prefix$i');
      if (k.isEmpty) break;
      keys.add(k);
    }
    return keys;
  }

  static List<AiModelConfigData> get models {
    final list = <AiModelConfigData>[];

    _addGemini(list);
    _addGroq(list);
    _addDeepSeek(list);
    _addOpenRouter(list);

    return list;
  }

  static void _addGemini(List<AiModelConfigData> list) {
    final geminiKeys = _keys('GEMINI_API_KEY');
    if (geminiKeys.isEmpty) return;

    list.add(AiModelConfigData(
      name: 'Gemini 2.0 Flash Lite',
      provider: 'gemini',
      model: 'gemini-2.0-flash-lite',
      apiKeys: geminiKeys,
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      capabilities: {ModelCapability.multilingual, ModelCapability.fastResponse, ModelCapability.arabic},
      rpmLimit: 60,
      dailyLimit: 1500,
    ));

    if (geminiKeys.length > 1) {
      list.add(AiModelConfigData(
        name: 'Gemini 1.5 Flash',
        provider: 'gemini',
        model: 'gemini-1.5-flash',
        apiKeys: geminiKeys,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.deepReasoning, ModelCapability.longContext, ModelCapability.arabic},
        maxTokens: 4096,
        rpmLimit: 60,
        dailyLimit: 1500,
      ));
      list.add(AiModelConfigData(
        name: 'Gemini 1.5 Pro',
        provider: 'gemini',
        model: 'gemini-1.5-pro',
        apiKeys: geminiKeys,
        baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
        capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.deepReasoning, ModelCapability.longContext, ModelCapability.arabic},
        maxTokens: 8192,
        rpmLimit: 30,
        dailyLimit: 100,
      ));
    }
  }

  static void _addGroq(List<AiModelConfigData> list) {
    final groqKeys = _keys('GROQ_API_KEY');
    if (groqKeys.isEmpty) return;

    list.add(AiModelConfigData(
      name: 'Llama 3.1 70B (Groq)',
      provider: 'openai',
      model: 'llama-3.1-70b-versatile',
      apiKeys: groqKeys,
      baseUrl: 'https://api.groq.com/openai/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.deepReasoning, ModelCapability.english, ModelCapability.arabic},
      rpmLimit: 30,
      dailyLimit: 14400,
    ));
    list.add(AiModelConfigData(
      name: 'Llama 3.1 8B (Groq)',
      provider: 'openai',
      model: 'llama-3.1-8b-instant',
      apiKeys: groqKeys,
      baseUrl: 'https://api.groq.com/openai/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.fastResponse, ModelCapability.arabic},
      rpmLimit: 30,
      dailyLimit: 14400,
    ));
    list.add(AiModelConfigData(
      name: 'Mixtral 8x7B (Groq)',
      provider: 'openai',
      model: 'mixtral-8x7b-32768',
      apiKeys: groqKeys,
      baseUrl: 'https://api.groq.com/openai/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.arabic},
      maxTokens: 4096,
      rpmLimit: 30,
      dailyLimit: 14400,
    ));
  }

  static void _addDeepSeek(List<AiModelConfigData> list) {
    final deepseekKeys = _keys('DEEPSEEK_API_KEY');
    if (deepseekKeys.isEmpty) return;

    list.add(AiModelConfigData(
      name: 'DeepSeek V2',
      provider: 'openai',
      model: 'deepseek-chat',
      apiKeys: deepseekKeys,
      baseUrl: 'https://api.deepseek.com/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.longContext, ModelCapability.arabic},
      maxTokens: 4096,
      rpmLimit: 10,
      dailyLimit: 500,
    ));
  }

  static void _addOpenRouter(List<AiModelConfigData> list) {
    final openrouterKeys = _keys('OPENROUTER_API_KEY');
    if (openrouterKeys.isEmpty) return;

    list.add(AiModelConfigData(
      name: 'Llama 3.1 70B (OpenRouter)',
      provider: 'openai',
      model: 'meta-llama/llama-3.1-70b-instruct',
      apiKeys: openrouterKeys,
      baseUrl: 'https://openrouter.ai/api/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.deepReasoning, ModelCapability.arabic},
      rpmLimit: 20,
      dailyLimit: 200,
    ));
    list.add(AiModelConfigData(
      name: 'Mistral 7B (OpenRouter)',
      provider: 'openai',
      model: 'mistralai/mistral-7b-instruct',
      apiKeys: openrouterKeys,
      baseUrl: 'https://openrouter.ai/api/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.fastResponse, ModelCapability.arabic},
      rpmLimit: 20,
      dailyLimit: 200,
    ));
    list.add(AiModelConfigData(
      name: 'Qwen 2 72B (OpenRouter)',
      provider: 'openai',
      model: 'qwen/qwen-2-72b-instruct',
      apiKeys: openrouterKeys,
      baseUrl: 'https://openrouter.ai/api/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.deepReasoning, ModelCapability.arabic},
      maxTokens: 4096,
      rpmLimit: 20,
      dailyLimit: 200,
    ));
    list.add(AiModelConfigData(
      name: 'Gemma 2 9B (OpenRouter)',
      provider: 'openai',
      model: 'google/gemma-2-9b-it',
      apiKeys: openrouterKeys,
      baseUrl: 'https://openrouter.ai/api/v1',
      capabilities: {ModelCapability.multilingual, ModelCapability.reasoning, ModelCapability.arabic},
      maxTokens: 4096,
      rpmLimit: 20,
      dailyLimit: 200,
    ));
    list.add(AiModelConfigData(
      name: 'Phi-3 Mini 128K (OpenRouter)',
      provider: 'openai',
      model: 'microsoft/phi-3-mini-128k-instruct',
      apiKeys: openrouterKeys,
      baseUrl: 'https://openrouter.ai/api/v1',
      capabilities: {ModelCapability.fastResponse, ModelCapability.longContext},
      maxTokens: 2048,
      rpmLimit: 30,
      dailyLimit: 200,
    ));
  }
  }
