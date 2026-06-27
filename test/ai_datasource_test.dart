import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';
import 'package:aquatrack_pro/core/services/ai_model_router.dart';
import 'package:aquatrack_pro/core/services/web_search_service.dart';
import 'package:aquatrack_pro/core/errors/exceptions.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/datasources/ai_remote_datasource.dart';

class MockFirestore extends Mock implements FirebaseFirestore {}
class MockRouter extends Mock implements AiModelRouter {}
class MockWebSearch extends Mock implements WebSearchService {}

void main() {
  late AiRemoteDataSourceImpl dataSource;
  late MockFirestore mockFirestore;
  late MockRouter mockRouter;
  late MockWebSearch mockWebSearch;

  setUp(() {
    mockFirestore = MockFirestore();
    mockRouter = MockRouter();
    mockWebSearch = MockWebSearch();

    dataSource = AiRemoteDataSourceImpl(
      firestore: mockFirestore,
      router: mockRouter,
      webSearch: mockWebSearch,
    );

    registerFallbackValue(QueryComplexity.simple);
    registerFallbackValue(const AiResponse(text: 'test', modelName: 'test', provider: 'test'));
    registerFallbackValue(const <WebSearchResult>[]);
    registerFallbackValue(const <String>[]);
    registerFallbackValue(AiCategory.general);
    registerFallbackValue('userId');
    registerFallbackValue('athleteId');

    when(() => mockWebSearch.searchTrusted(any(), limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockRouter.classifyQuery(any())).thenReturn(QueryComplexity.normal);
    when(() => mockRouter.route(any(), any(), complexity: any(named: 'complexity')))
        .thenAnswer((_) async => const AiResponse(text: 'AI answer', modelName: 'test-model', provider: 'test'));
  });

  group('basic', () {
    test('throws on empty question', () async {
      expect(
        () => dataSource.sendToGemini(
          userId: 'u', athleteId: 'a', question: '', context: 'ctx',
          category: AiCategory.general, systemPrompt: 'sp', kbChunks: const [], webResults: const [],
        ),
        throwsA(isA<ServerException>()),
      );
    });

    test('returns AI answer on success', () async {
      final result = await dataSource.sendToGemini(
        userId: 'u', athleteId: 'a', question: 'how to swim?', context: 'ctx',
        category: AiCategory.general, systemPrompt: 'system', kbChunks: const [], webResults: const [],
      );

      expect(result.answer, 'AI answer');
      expect(result.citations, anyElement(contains('test-model')));
    });
  });

  group('fallback', () {
    test('uses trusted web when all AI models exhaust', () async {
      when(() => mockRouter.route(any(), any(), complexity: any(named: 'complexity')))
          .thenThrow(const AllModelsExhausted());
      when(() => mockWebSearch.searchTrusted(any(), limit: any(named: 'limit')))
          .thenAnswer((_) async => [WebSearchResult(title: 'Trusted', snippet: 'Medical info', url: 'https://mayoclinic.org/article', source: 'trusted')]);

      final result = await dataSource.sendToGemini(
        userId: 'u', athleteId: 'a', question: 'injury recovery?', context: 'data',
        category: AiCategory.injury, systemPrompt: 'sp', kbChunks: const [], webResults: const [],
      );

      expect(result.answer, contains('مصادر طبية ورياضية موثوقة'));
      expect(result.citations, anyElement(contains('mayoclinic')));
    });

    test('falls back to KB chunks when trusted web also fails', () async {
      when(() => mockRouter.route(any(), any(), complexity: any(named: 'complexity')))
          .thenThrow(const AllModelsExhausted());

      final result = await dataSource.sendToGemini(
        userId: 'u', athleteId: 'a', question: 'recovery?', context: 'data',
        category: AiCategory.recovery, systemPrompt: 'sp',
        kbChunks: ['Important recovery info from the book.'], webResults: const [],
      );

      expect(result.answer, contains('Important recovery info from the book.'));
    });

    test('returns apology when everything fails', () async {
      when(() => mockRouter.route(any(), any(), complexity: any(named: 'complexity')))
          .thenThrow(const AllModelsExhausted());

      final result = await dataSource.sendToGemini(
        userId: 'u', athleteId: 'a', question: 'unknown?', context: 'data',
        category: AiCategory.general, systemPrompt: 'sp', kbChunks: const [], webResults: const [],
      );

      expect(result.answer, contains('عذراً'));
    });
  });

  test('all tests ran', () {});
}
