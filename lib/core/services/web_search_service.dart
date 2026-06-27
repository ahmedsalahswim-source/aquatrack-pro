import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';

@visibleForTesting
class CacheEntry {
  final List<WebSearchResult> results;
  final DateTime cachedAt;
  const CacheEntry({required this.results, required this.cachedAt});
}

class WebSearchService {
  final Dio _dio;
  static const String _liteUrl = 'https://lite.duckduckgo.com/lite/';
  static const String _wikiApi = 'https://en.wikipedia.org/w/api.php';
  static const String _wikiApiAr = 'https://ar.wikipedia.org/w/api.php';

  static const int _maxCacheSize = 20;
  static const Duration _cacheTtl = Duration(minutes: 5);
  final LinkedHashMap<String, CacheEntry> _cache = LinkedHashMap();

  @visibleForTesting
  Map<String, CacheEntry> get cache => _cache;

  static const List<String> _trustedDomains = [
    'mayoclinic.org',
    'nhs.uk',
    'medlineplus.gov',
    'who.int',
    'cdc.gov',
    'acsm.org',
    'usaswimming.org',
    'swimmingworldmagazine.com',
    'swimsmooth.com',
    'humankinetics.com',
    'pubmed.ncbi.nlm.nih.gov',
    'ncbi.nlm.nih.gov',
    'bjsm.bmj.com',
    'sportsmed.org',
    'scienceforsport.com',
    'simplifaster.com',
    'coachesinsider.com',
    'traineracademy.org',
    'sportsscientists.com',
  ];

  WebSearchService({Dio? dio})
      : _dio = dio ?? Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 15),
        ));

  Future<List<WebSearchResult>> search(String query, {int limit = 5}) async {
    final cacheKey = 'q_${query.toLowerCase().trim()}_$limit';
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      _cache.remove(cacheKey);
      _cache[cacheKey] = cached;
      debugPrint('[WebSearch] Cache hit for "$query"');
      return cached.results;
    }

    final results = <WebSearchResult>[];
    try {
      results.addAll(await _searchDuckDuckGoLite(query, limit));
    } catch (e) {
      debugPrint('[WebSearch] DuckDuckGo Lite failed: $e');
    }
    if (results.length < limit) {
      try {
        results.addAll(await _searchWikipedia(query, limit - results.length));
      } catch (e) {
        debugPrint('[WebSearch] Wikipedia failed: $e');
      }
    }
    final finalResults = results.take(limit).toList();

    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = CacheEntry(results: finalResults, cachedAt: DateTime.now());

    return finalResults;
  }

  Future<List<WebSearchResult>> searchTrusted(String query, {int limit = 3}) async {
    final cacheKey = 't_${query.toLowerCase().trim()}_$limit';
    final cached = _cache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.cachedAt) < _cacheTtl) {
      _cache.remove(cacheKey);
      _cache[cacheKey] = cached;
      debugPrint('[WebSearch] Cache hit (trusted) for "$query"');
      return cached.results;
    }

    final results = <WebSearchResult>[];

    // 1. Always try Wikipedia first (trusted, free, structured)
    try {
      results.addAll(await _searchWikipedia(query, limit));
    } catch (e) {
      debugPrint('[WebSearch] Wikipedia (trusted fallback) failed: $e');
    }

    // 2. DuckDuckGo Lite with domain filter
    if (results.length < limit) {
      try {
        final ddgResults = await _searchDuckDuckGoLite(query, limit * 3);
        for (final r in ddgResults) {
          if (isTrustedDomain(r.url)) {
            results.add(WebSearchResult(
              title: r.title,
              snippet: r.snippet,
              url: r.url,
              source: 'trusted',
            ));
            if (results.length >= limit) break;
          }
        }
      } catch (e) {
        debugPrint('[WebSearch] DuckDuckGo (trusted fallback) failed: $e');
      }
    }

    if (results.isEmpty) {
      try {
        results.addAll(await _searchDuckDuckGoLite(query, limit));
      } catch (e) {
        debugPrint('[WebSearch] DuckDuckGo (ultimate fallback) failed: $e');
      }
    }

    final finalResults = results.take(limit).toList();
    if (_cache.length >= _maxCacheSize) {
      _cache.remove(_cache.keys.first);
    }
    _cache[cacheKey] = CacheEntry(results: finalResults, cachedAt: DateTime.now());
    return finalResults;
  }

  @visibleForTesting
  bool isTrustedDomain(String url) {
    try {
      final uri = Uri.parse(url);
      final host = uri.host.toLowerCase();
      return _trustedDomains.any((d) => host == d || host.endsWith('.$d'));
    } catch (_) {
      return false;
    }
  }

  void clearCache() => _cache.clear();

  Future<List<WebSearchResult>> _searchDuckDuckGoLite(String query, int limit) async {
    final response = await _dio.post(
      _liteUrl,
      data: {'q': query},
      options: Options(headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
      }),
    );

    final html = response.data as String;
    final results = <WebSearchResult>[];

    // Parse DuckDuckGo Lite tables: each result has a header row and a snippet row
    final headerRegex = RegExp(
      r'<tr class="result_header">\s*<td[^>]*>.*?</td>\s*<td[^>]*><a[^>]*href="([^"]*)"[^>]*>(.*?)</a></td>\s*</tr>',
      dotAll: true,
    );
    final snippetRegex = RegExp(
      r'<tr class="result_snippet">\s*<td[^>]*>.*?</td>\s*<td[^>]*>(.*?)</td>\s*</tr>',
      dotAll: true,
    );

    final headers = headerRegex.allMatches(html).toList();
    final snippets = snippetRegex.allMatches(html).toList();

    for (int i = 0; i < headers.length && results.length < limit; i++) {
      final url = decodeDdgUrl(headers[i].group(1)?.trim() ?? '');
      final title = stripHtml(headers[i].group(2)?.trim() ?? '');
      final snippet = i < snippets.length ? stripHtml(snippets[i].group(1)?.trim() ?? '') : '';

      if (title.isNotEmpty) {
        results.add(WebSearchResult(
          title: title,
          snippet: snippet,
          url: url,
          source: 'duckduckgo',
        ));
      }
    }

    return results;
  }

  @visibleForTesting
  String decodeDdgUrl(String url) {
    if (url.contains('uddg=')) {
      try {
        final uri = Uri.parse(url);
        final uddg = uri.queryParameters['uddg'];
        if (uddg != null && uddg.isNotEmpty) return Uri.decodeQueryComponent(uddg);
      } catch (_) {}
    }
    return url;
  }

  Future<List<WebSearchResult>> _searchWikipedia(String query, int limit) async {
    final isArabic = RegExp(r'[\u0600-\u06FF]').hasMatch(query);
    final apiUrl = isArabic ? _wikiApiAr : _wikiApi;

    final response = await _dio.get(apiUrl, queryParameters: {
      'action': 'query',
      'list': 'search',
      'srsearch': query,
      'format': 'json',
      'srlimit': limit,
      'srprop': 'snippet',
    });

    final data = response.data as Map<String, dynamic>;
    final queryResult = data['query'] as Map<String, dynamic>?;
    if (queryResult == null) return [];

    final searchResults = queryResult['search'] as List<dynamic>?;
    if (searchResults == null || searchResults.isEmpty) return [];

    return searchResults.take(limit).map((r) {
      final rMap = r as Map<String, dynamic>;
      final pageTitle = rMap['title'] as String? ?? '';
      final snippet = stripHtml(rMap['snippet'] as String? ?? '');
      final lang = isArabic ? 'ar' : 'en';
      return WebSearchResult(
        title: pageTitle,
        snippet: snippet,
        url: 'https://$lang.wikipedia.org/wiki/${Uri.encodeComponent(pageTitle.replaceAll(' ', '_'))}',
        source: 'wikipedia',
      );
    }).toList();
  }

  @visibleForTesting
  String stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .trim();
  }

  String formatResults(List<WebSearchResult> results) {
    if (results.isEmpty) return '';
    final buf = StringBuffer('\n--- نتائج البحث من الويب ---\n');
    for (int i = 0; i < results.length; i++) {
      final r = results[i];
      buf.writeln('${i + 1}. ${r.title}');
      buf.writeln('   ${r.snippet}');
      buf.writeln('   ${r.sourceLabel}: ${r.url}');
    }
    return buf.toString();
  }
}
