import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:aquatrack_pro/core/models/book_chunk.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';
import 'package:aquatrack_pro/core/services/knowledge_base_service.dart';
import 'package:aquatrack_pro/core/services/prompt_builder.dart';
import 'package:aquatrack_pro/core/services/web_search_service.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/models/ai_message_model.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/repositories/ai_repository_impl.dart';

class MockDataSource extends Mock implements AiRemoteDataSource {}
class MockKnowledgeBase extends Mock implements KnowledgeBaseService {}
class MockWebSearch extends Mock implements WebSearchService {}
class MockPromptBuilder extends Mock implements PromptBuilder {}

AiMessageModel _makeModel({String answer = 'AI answer', String question = 'q'}) {
  return AiMessageModel(
    id: 'm1', userId: 'u', athleteId: 'a',
    question: question, answer: answer, timestamp: DateTime.now(),
  );
}

void main() {
  late AiRepositoryImpl repository;
  late MockDataSource mockDataSource;
  late MockKnowledgeBase mockKnowledgeBase;
  late MockWebSearch mockWebSearch;
  late MockPromptBuilder mockPromptBuilder;

  setUpAll(() {
    registerFallbackValue(AiMessageModel(
      id: '1', userId: 'u', athleteId: 'a',
      question: 'q', answer: 'a', timestamp: DateTime.now(),
    ));
    registerFallbackValue(AiCategory.general);
    registerFallbackValue('userId');
    registerFallbackValue('athleteId');
    registerFallbackValue(UserFeedback.helpful);
    registerFallbackValue(const <BookChunk>[]);
    registerFallbackValue(const <WebSearchResult>[]);
    registerFallbackValue(const <String>[]);
  });

  setUp(() {
    mockDataSource = MockDataSource();
    mockKnowledgeBase = MockKnowledgeBase();
    mockWebSearch = MockWebSearch();
    mockPromptBuilder = MockPromptBuilder();

    repository = AiRepositoryImpl(
      remoteDataSource: mockDataSource,
      knowledgeBase: mockKnowledgeBase,
      webSearch: mockWebSearch,
      promptBuilder: mockPromptBuilder,
    );

    when(() => mockKnowledgeBase.searchExpanded(any(), limit: any(named: 'limit'), minScore: any(named: 'minScore')))
        .thenReturn([]);
    when(() => mockWebSearch.search(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockPromptBuilder.buildSystemPrompt(
      swimmerContext: any(named: 'swimmerContext'),
      kbResults: any(named: 'kbResults'),
      webResults: any(named: 'webResults'),
      userQuery: any(named: 'userQuery'),
      conversationHistory: any(named: 'conversationHistory'),
    )).thenReturn('system prompt');
  });

  group('sendMessage', () {
    test('returns Right with message on success', () async {
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'),
        context: any(named: 'context'),
        category: any(named: 'category'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
        history: any(named: 'history'),
      )).thenAnswer((_) async => _makeModel(answer: 'AI answer'));
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(
        userId: 'user1',
        athleteId: 'athlete1',
        athleteName: 'أحمد',
        question: 'how to swim?',
        context: {'age': '14', 'gender': 'ذكر'},
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (l) => fail('expected Right'),
        (r) {
          expect(r.answer, 'AI answer');
          expect(r.question, 'how to swim?');
          expect(r.athleteId, 'athlete1');
        },
      );
    });

    test('uses _fullContext when available in context map', () async {
      String? capturedContext;
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'),
        context: captureAny(named: 'context'),
        category: any(named: 'category'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
        history: any(named: 'history'),
      )).thenAnswer((inv) async {
        capturedContext = inv.namedArguments[const Symbol('context')] as String?;
        return _makeModel();
      });
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'test',
        question: 'q',
        context: {'_fullContext': 'full swimmer profile with all data'},
      );

      expect(capturedContext, 'full swimmer profile with all data');
    });

    test('builds context string when _fullContext absent', () async {
      String? capturedContext;
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'),
        context: captureAny(named: 'context'),
        category: any(named: 'category'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
        history: any(named: 'history'),
      )).thenAnswer((inv) async {
        capturedContext = inv.namedArguments[const Symbol('context')] as String?;
        return _makeModel();
      });
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'سارة',
        question: 'q',
        context: {'age': '14', 'sleep': '8', 'hr': '65'},
      );

      expect(capturedContext, contains('سارة'));
      expect(capturedContext, contains('14'));
      expect(capturedContext, contains('8'));
      expect(capturedContext, contains('65'));
    });

    test('returns Left on datasource exception', () async {
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'),
        context: any(named: 'context'),
        category: any(named: 'category'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
      )).thenThrow(Exception('network error'));

      final result = await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'test',
        question: 'q', context: {},
      );

      expect(result.isLeft(), isTrue);
      result.fold(
        (l) => expect(l.message, contains('network error')),
        (r) => fail('expected Left'),
      );
    });

    test('infers category from question', () async {
      AiCategory? capturedCategory;
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'),
        context: captureAny(named: 'context'),
        category: any(named: 'category'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
        history: any(named: 'history'),
      )).thenAnswer((inv) async {
        capturedCategory = inv.namedArguments[const Symbol('category')] as AiCategory?;
        return _makeModel();
      });
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'test',
        question: 'نصايح تغذية',
        context: {},
      );

      expect(capturedCategory, AiCategory.nutrition);
    });
  });

  group('_inferCategory', () {
    test('returns sleep for sleep-related queries', () async {
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'), context: any(named: 'context'),
        category: any(named: 'category'), history: any(named: 'history'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
      )).thenAnswer((_) async => _makeModel());
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'test',
        question: 'كيف أحسن نومي', context: {'_fullContext': ''},
      );
      result.fold((l) => null, (r) => expect(r.category, AiCategory.sleep));
    });

    test('returns injury for injury-related queries', () async {
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'), context: any(named: 'context'),
        category: any(named: 'category'), history: any(named: 'history'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
      )).thenAnswer((_) async => _makeModel());
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'test',
        question: 'عندي إصابة في الكتف', context: {'_fullContext': ''},
      );
      result.fold((l) => null, (r) => expect(r.category, AiCategory.injury));
    });

    test('returns general for unknown queries', () async {
      when(() => mockDataSource.sendToGemini(
        userId: any(named: 'userId'),
        athleteId: any(named: 'athleteId'),
        question: any(named: 'question'), context: any(named: 'context'),
        category: any(named: 'category'), history: any(named: 'history'),
        systemPrompt: any(named: 'systemPrompt'),
        kbChunks: any(named: 'kbChunks'),
        webResults: any(named: 'webResults'),
      )).thenAnswer((_) async => _makeModel());
      when(() => mockDataSource.saveMessage(any())).thenAnswer((_) async {});

      final result = await repository.sendMessage(
        userId: 'u', athleteId: 'a', athleteName: 'test',
        question: 'مرحبا', context: {'_fullContext': ''},
      );
      result.fold((l) => null, (r) => expect(r.category, AiCategory.general));
    });
  });

  group('getHistory', () {
    test('returns Right with messages on success', () async {
      when(() => mockDataSource.getHistory(any(), any())).thenAnswer((_) async => [
        _makeModel(question: 'hi', answer: 'hello'),
      ]);

      final result = await repository.getHistory(userId: 'u', athleteId: 'a');

      expect(result.isRight(), isTrue);
      result.fold((l) => fail('expected Right'), (r) => expect(r.length, 1));
    });

    test('returns Left on exception', () async {
      when(() => mockDataSource.getHistory(any(), any())).thenThrow(Exception('db error'));

      final result = await repository.getHistory(userId: 'u', athleteId: 'a');

      expect(result.isLeft(), isTrue);
    });
  });

  group('getMessagesUsedToday', () {
    test('returns count on success', () async {
      when(() => mockDataSource.getMessageCountToday('u')).thenAnswer((_) async => 5);

      final result = await repository.getMessagesUsedToday('u');

      result.fold((l) => fail('expected Right'), (r) => expect(r, 5));
    });

    test('returns Left on exception', () async {
      when(() => mockDataSource.getMessageCountToday('u')).thenThrow(Exception('fail'));

      final result = await repository.getMessagesUsedToday('u');

      expect(result.isLeft(), isTrue);
    });
  });

  group('clearHistory', () {
    test('returns Right(null) on success', () async {
      when(() => mockDataSource.clearHistory('u', 'a')).thenAnswer((_) async {});

      final result = await repository.clearHistory('u', 'a');

      expect(result.isRight(), isTrue);
    });

    test('returns Left on exception', () async {
      when(() => mockDataSource.clearHistory('u', 'a')).thenThrow(Exception('fail'));

      final result = await repository.clearHistory('u', 'a');

      expect(result.isLeft(), isTrue);
    });
  });
}
