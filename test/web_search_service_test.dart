import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dio/dio.dart';
import 'package:aquatrack_pro/core/services/web_search_service.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';

class MockDio extends Mock implements Dio {}

void main() {
  late WebSearchService service;
  late MockDio mockDio;

  setUp(() {
    mockDio = MockDio();
    service = WebSearchService(dio: mockDio);
  });

  group('stripHtml', () {
    test('strips HTML tags', () {
      expect(service.stripHtml('<b>bold</b> and <i>italic</i>'), 'bold and italic');
    });

    test('decodes HTML entities', () {
      expect(service.stripHtml('A &amp; B'), 'A & B');
      expect(service.stripHtml('&lt;3'), '<3');
      expect(service.stripHtml('&gt;'), '>');
      expect(service.stripHtml('&quot;hello&quot;'), '"hello"');
      expect(service.stripHtml('&#39;test&#39;'), "'test'");
    });

    test('trims whitespace', () {
      expect(service.stripHtml('  hello  '), 'hello');
    });
  });

  group('decodeDdgUrl', () {
    test('extracts uddg parameter', () {
      final url = 'https://lite.duckduckgo.com/lite/?uddg=https%3A%2F%2Fexample.com%2Fpage';
      expect(service.decodeDdgUrl(url), 'https://example.com/page');
    });

    test('returns original URL when no uddg', () {
      expect(service.decodeDdgUrl('https://example.com'), 'https://example.com');
    });

    test('returns original URL on invalid input', () {
      expect(service.decodeDdgUrl('not-a-url'), 'not-a-url');
    });
  });

  group('isTrustedDomain', () {
    test('returns true for known trusted domains', () {
      expect(service.isTrustedDomain('https://mayoclinic.org/article'), isTrue);
      expect(service.isTrustedDomain('https://www.nhs.uk/conditions'), isTrue);
      expect(service.isTrustedDomain('https://medlineplus.gov/'), isTrue);
      expect(service.isTrustedDomain('https://pubmed.ncbi.nlm.nih.gov/123'), isTrue);
      expect(service.isTrustedDomain('https://usaswimming.org/resource'), isTrue);
    });

    test('matches subdomains of trusted domains', () {
      expect(service.isTrustedDomain('https://sub.mayoclinic.org/page'), isTrue);
    });

    test('rejects untrusted domains', () {
      expect(service.isTrustedDomain('https://example.com'), isFalse);
      expect(service.isTrustedDomain('https://random-blog.com/article'), isFalse);
    });

    test('returns false on invalid URL', () {
      expect(service.isTrustedDomain('not a url'), isFalse);
    });
  });

  group('search', () {
    setUp(() {
      registerFallbackValue(Uri.parse('http://example.com'));
      registerFallbackValue(BaseOptions());
    });

    test('returns cached results when TTL valid', () async {
      service.cache['q_test_5'] = CacheEntry(
        results: [WebSearchResult(title: 'cached', snippet: 'cached', url: 'https://x.com', source: 'web')],
        cachedAt: DateTime.now(),
      );

      final results = await service.search('test');

      expect(results.length, 1);
      expect(results.first.title, 'cached');
      verifyNever(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')));
    });

    test('skips expired cache and fetches fresh', () async {
      service.cache['q_test_5'] = CacheEntry(
        results: [WebSearchResult(title: 'stale', snippet: 'stale', url: 'https://x.com', source: 'web')],
        cachedAt: DateTime.now().subtract(const Duration(minutes: 10)),
      );

      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => Response(data: '<html></html>', statusCode: 200, requestOptions: RequestOptions(path: '')));

      await service.search('test');

      verify(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options'))).called(1);
    });

    test('evicts oldest cache entry when at capacity', () async {
      service.cache['q_old_5'] = CacheEntry(results: [], cachedAt: DateTime.now());
      for (int i = 0; i < 19; i++) {
        service.cache['q_fill_${i}_5'] = CacheEntry(results: [], cachedAt: DateTime.now());
      }
      expect(service.cache.length, 20);

      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => Response(data: '<html></html>', statusCode: 200, requestOptions: RequestOptions(path: '')));

      await service.search('evict-me');

      expect(service.cache.length, 20);
      expect(service.cache.containsKey('q_old_5'), isFalse);
      expect(service.cache.containsKey('q_evict-me_5'), isTrue);
    });

    test('falls back to Wikipedia when DuckDuckGo fails', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.connectionTimeout));
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {
                  'query': {
                    'search': [
                      {'title': 'WikiResult', 'snippet': 'Wiki <b>snippet</b>'},
                    ],
                  },
                },
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final results = await service.search('test fallback');

      expect(results.isNotEmpty, isTrue);
      expect(results.first.title, 'WikiResult');
    });

    test('returns empty list when all sources fail', () async {
      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.connectionTimeout));
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenThrow(DioException(requestOptions: RequestOptions(path: ''), type: DioExceptionType.connectionTimeout));

      final results = await service.search('fail');

      expect(results, isEmpty);
    });
  });

  group('searchTrusted', () {
    setUp(() {
      registerFallbackValue(Uri.parse('http://example.com'));
      registerFallbackValue(BaseOptions());
    });

    test('uses cache when available', () async {
      service.cache['t_cache-me_3'] = CacheEntry(
        results: [WebSearchResult(title: 'trusted cached', snippet: 'cached', url: 'https://mayoclinic.org', source: 'trusted')],
        cachedAt: DateTime.now(),
      );

      final results = await service.searchTrusted('cache-me');

      expect(results.length, 1);
      verifyNever(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')));
    });

    test('tries Wikipedia first, then DuckDuckGo with trusted filter', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {'query': {'search': []}},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final ddgHtml = '''
<html><body>
<table>
<tr class="result_header"><td></td><td><a href="https://lite.duckduckgo.com/lite/?uddg=https%3A%2F%2Fexample.com%2Fpage">Example</a></td></tr>
<tr class="result_snippet"><td></td><td>An example snippet</td></tr>
<tr class="result_header"><td></td><td><a href="https://lite.duckduckgo.com/lite/?uddg=https%3A%2F%2Fmayoclinic.org%2Farticle">Mayo Article</a></td></tr>
<tr class="result_snippet"><td></td><td>Medical info from Mayo</td></tr>
</table>
</body></html>''';

      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => Response(data: ddgHtml, statusCode: 200, requestOptions: RequestOptions(path: '')));

      final results = await service.searchTrusted('health');

      expect(results.any((r) => r.url.contains('mayoclinic.org')), isTrue);
      expect(results.any((r) => r.url.contains('example.com')), isFalse);
    });

    test('uses unfiltered DuckDuckGo as ultimate fallback', () async {
      when(() => mockDio.get(any(), queryParameters: any(named: 'queryParameters')))
          .thenAnswer((_) async => Response(
                data: {'query': {'search': []}},
                statusCode: 200,
                requestOptions: RequestOptions(path: ''),
              ));

      final ddgHtml = '''
<html><body>
<table>
<tr class="result_header"><td></td><td><a href="https://lite.duckduckgo.com/lite/?uddg=https%3A%2F%2Fexample.com">Example</a></td></tr>
<tr class="result_snippet"><td></td><td>Generic snippet</td></tr>
</table>
</body></html>''';

      when(() => mockDio.post(any(), data: any(named: 'data'), options: any(named: 'options')))
          .thenAnswer((_) async => Response(data: ddgHtml, statusCode: 200, requestOptions: RequestOptions(path: '')));

      final results = await service.searchTrusted('generic');

      expect(results.isNotEmpty, isTrue);
      expect(results.first.source, 'duckduckgo');
    });
  });

  group('clearCache', () {
    test('removes all cached entries', () {
      service.cache['q_test_5'] = CacheEntry(results: [], cachedAt: DateTime.now());
      service.cache['t_test_3'] = CacheEntry(results: [], cachedAt: DateTime.now());
      expect(service.cache.length, 2);

      service.clearCache();

      expect(service.cache, isEmpty);
    });
  });

  group('formatResults', () {
    test('returns empty string for empty list', () {
      expect(service.formatResults([]), '');
    });

    test('formats results with source labels', () {
      final results = [
        WebSearchResult(title: 'Title1', snippet: 'Snippet1', url: 'https://example.com/1', source: 'duckduckgo'),
        WebSearchResult(title: 'Title2', snippet: 'Snippet2', url: 'https://wikipedia.org/wiki/Swim', source: 'wikipedia'),
      ];

      final formatted = service.formatResults(results);

      expect(formatted, contains('Title1'));
      expect(formatted, contains('Snippet1'));
      expect(formatted, contains('Title2'));
      expect(formatted, contains('Snippet2'));
      expect(formatted, contains('DuckDuckGo'));
      expect(formatted, contains('Wikipedia'));
    });
  });
}
