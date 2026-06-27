import 'dart:math';

class SemanticCacheHit {
  final String answer;
  final List<String> citations;
  final String categoryName;
  final DateTime timestamp;

  SemanticCacheHit({
    required this.answer,
    required this.citations,
    required this.categoryName,
    required this.timestamp,
  });
}

class _CacheEntry {
  final List<int> signature;
  final String userId;
  final String athleteId;
  final int contextHash;
  final String question;
  final String answer;
  final List<String> citations;
  final String categoryName;
  final DateTime timestamp;

  _CacheEntry({
    required this.signature,
    required this.userId,
    required this.athleteId,
    required this.contextHash,
    required this.question,
    required this.answer,
    required this.citations,
    required this.categoryName,
    required this.timestamp,
  });
}

class MinHashService {
  static const int _numHashes = 100;
  static const int _shingleSize = 3;
  static const int _bands = 10;
  static const int _rowsPerBand = _numHashes ~/ _bands;

  final List<int> _hashSeeds = List.generate(_numHashes, (i) => i * 104729 + 7919);
  final Map<String, List<_CacheEntry>> _lshBuckets = {};
  final List<_CacheEntry> _allEntries = [];
  static const int _maxEntries = 500;
  static const double _similarityThreshold = 0.92;

  List<int> _shingles(String text) {
    final normalized = text.toLowerCase().trim();
    if (normalized.length < _shingleSize) return [normalized.hashCode];
    final shingles = <int>{};
    for (int i = 0; i <= normalized.length - _shingleSize; i++) {
      shingles.add(normalized.substring(i, i + _shingleSize).hashCode);
    }
    return shingles.toList();
  }

  int _minHash(List<int> shingles, int seed) {
    if (shingles.isEmpty) return 0;
    int minVal = 2147483647;
    for (final sh in shingles) {
      final hash = (sh ^ seed) * 16777619;
      final mixed = (hash ^ (hash >> 32)).abs();
      if (mixed < minVal) minVal = mixed;
    }
    return minVal;
  }

  List<int> computeSignature(String text) {
    final shingles = _shingles(text);
    return _hashSeeds.map((seed) => _minHash(shingles, seed)).toList();
  }

  String _bucketKey(List<int> signature, int bandIndex) {
    final start = bandIndex * _rowsPerBand;
    final end = min(start + _rowsPerBand, signature.length);
    var hash = 0;
    for (int i = start; i < end; i++) {
      hash = (hash * 31 + signature[i]) & 0x7FFFFFFF;
    }
    return 'b${bandIndex}_$hash';
  }

  Set<String> _buckets(List<int> signature) {
    final result = <String>{};
    for (int i = 0; i < _bands; i++) {
      result.add(_bucketKey(signature, i));
    }
    return result;
  }

  double similarity(List<int> sig1, List<int> sig2) {
    if (sig1.length != sig2.length) return 0;
    int matches = 0;
    for (int i = 0; i < sig1.length; i++) {
      if (sig1[i] == sig2[i]) matches++;
    }
    return matches / sig1.length;
  }

  void add({
    required String userId,
    required String athleteId,
    required int contextHash,
    required String question,
    required String answer,
    required List<String> citations,
    required String categoryName,
  }) {
    final signature = computeSignature(question);
    final entry = _CacheEntry(
      signature: signature,
      userId: userId,
      athleteId: athleteId,
      contextHash: contextHash,
      question: question,
      answer: answer,
      citations: citations,
      categoryName: categoryName,
      timestamp: DateTime.now(),
    );

    if (_allEntries.length >= _maxEntries) {
      final oldest = _allEntries.removeAt(0);
      for (final bucketSet in _lshBuckets.values) {
        bucketSet.removeWhere((e) => e == oldest);
      }
    }

    _allEntries.add(entry);
    for (final bucket in _buckets(signature)) {
      _lshBuckets.putIfAbsent(bucket, () => []).add(entry);
    }
  }

  SemanticCacheHit? findSimilar({
    required String userId,
    required String athleteId,
    required int contextHash,
    required String question,
  }) {
    final signature = computeSignature(question);
    final candidates = <_CacheEntry>{};

    for (final bucket in _buckets(signature)) {
      final entries = _lshBuckets[bucket];
      if (entries == null) continue;
      for (final entry in entries) {
        if (entry.userId == userId &&
            entry.athleteId == athleteId &&
            entry.contextHash == contextHash) {
          candidates.add(entry);
        }
      }
    }

    if (candidates.isEmpty) return null;

    _CacheEntry? best;
    double bestScore = 0;
    for (final candidate in candidates) {
      final sim = similarity(signature, candidate.signature);
      if (sim > bestScore) {
        bestScore = sim;
        best = candidate;
      }
    }

    if (best != null && bestScore >= _similarityThreshold) {
      return SemanticCacheHit(
        answer: best.answer,
        citations: List.from(best.citations),
        categoryName: best.categoryName,
        timestamp: best.timestamp,
      );
    }
    return null;
  }

  void clear() {
    _lshBuckets.clear();
    _allEntries.clear();
  }
}
