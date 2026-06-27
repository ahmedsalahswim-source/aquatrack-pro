import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:aquatrack_pro/core/models/book_chunk.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class KnowledgeBaseService {
  static const String _kbFileName = 'knowledge_base.json';
  List<BookChunk> _chunks = [];
  Map<String, List<int>> _invertedIndex = {};
  bool _ready = false;

  bool get isReady => _ready;
  int get chunkCount => _chunks.length;
  List<BookChunk> get allChunks => List.unmodifiable(_chunks);

  @visibleForTesting
  set ready(bool value) => _ready = value;

  @visibleForTesting
  void addChunksInMemory({required String title, required String content}) {
    final chunks = _chunkTextIntelligently(content, title);
    for (final chunk in chunks) {
      _chunks.add(chunk);
    }
    _buildIndex();
  }

  Future<void> init() async {
    try {
      await _loadFromDisk();
      if (_chunks.isEmpty) {
        await _loadBuiltInBooks();
      }
      _buildIndex();
      _ready = true;
      debugPrint('[KnowledgeBase] Loaded ${_chunks.length} chunks from disk');
    } catch (e) {
      debugPrint('[KnowledgeBase] Init error: $e');
    }
  }

  Future<void> _loadBuiltInBooks() async {
    try {
      final manifestJson = await rootBundle.loadString('assets/knowledge_base/manifest.json');
      final manifest = jsonDecode(manifestJson) as Map<String, dynamic>;
      final books = manifest['books'] as List<dynamic>;
      debugPrint('[KnowledgeBase] Loading ${books.length} built-in books...');

      for (int i = 0; i < books.length; i++) {
        final entry = books[i] as Map<String, dynamic>;
        final fileName = entry['file'] as String;
        final title = entry['title'] as String;
        final path = 'assets/knowledge_base/books/$fileName';

        try {
          String content;
          if (fileName.endsWith('.pdf')) {
            final byteData = await rootBundle.load(path);
            final bytes = byteData.buffer.asUint8List();
            content = _extractPdfBytes(bytes);
          } else {
            content = await rootBundle.loadString(path);
          }

          if (content.trim().isNotEmpty && content.length > 100) {
            await addBook(title: title, content: content);
            debugPrint('[KnowledgeBase] ✓ ${i+1}/${books.length}: $title');
          } else {
            debugPrint('[KnowledgeBase] ✗ ${i+1}/${books.length}: $title (فارغ أو قصير جداً)');
          }
        } catch (e) {
          debugPrint('[KnowledgeBase] ✗ ${i+1}/${books.length}: $title — $e');
        }
      }
      debugPrint('[KnowledgeBase] Built-in books loaded: ${_chunks.length} chunks');
    } catch (e) {
      debugPrint('[KnowledgeBase] Error loading built-in books: $e');
    }
  }

  String _extractPdfBytes(List<int> bytes) {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final buf = StringBuffer();
      for (int i = 0; i < doc.pages.count; i++) {
        final pageText = PdfTextExtractor(doc).extractText(startPageIndex: i, endPageIndex: i);
        if (pageText.trim().isNotEmpty) {
          buf.writeln(pageText);
        }
      }
      doc.dispose();
      final extracted = buf.toString().trim();
      if (extracted.length > 100) return extracted;
    } catch (e) {
      debugPrint('[KnowledgeBase] PDF extract error: $e');
    }
    return '';
  }

  Future<String> get _kbDir async {
    if (kIsWeb) return '';
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/knowledge_base');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir.path;
  }

  Future<void> _loadFromDisk() async {
    if (kIsWeb) return;
    final dir = await _kbDir;
    final file = File('$dir/$_kbFileName');
    if (!await file.exists()) return;
    final json = jsonDecode(await file.readAsString()) as List<dynamic>;
    _chunks = json.map((e) => BookChunk.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _saveToDisk() async {
    if (kIsWeb) return;
    final dir = await _kbDir;
    final file = File('$dir/$_kbFileName');
    await file.writeAsString(jsonEncode(_chunks.map((c) => c.toJson()).toList()));
  }

  @visibleForTesting
  List<String> tokenize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s\u0600-\u06FF]'), '')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1)
        .toList();
  }

  void _buildIndex() {
    _invertedIndex = {};
    for (int i = 0; i < _chunks.length; i++) {
      final tokens = tokenize('${_chunks[i].bookTitle} ${_chunks[i].pathLabel} ${_chunks[i].content}');
      for (final token in tokens.toSet()) {
        _invertedIndex.putIfAbsent(token, () => []).add(i);
      }
    }
  }

  List<({BookChunk chunk, double score})> search(String query, {int limit = 5, double minScore = 0.0}) {
    if (!_ready || _chunks.isEmpty || query.trim().isEmpty) return [];
    final queryTokens = tokenize(query);
    if (queryTokens.isEmpty) return [];

    final scores = <int, double>{};
    final docLengths = <int, int>{};
    final totalDocs = _chunks.length;

    for (int i = 0; i < _chunks.length; i++) {
      final tokens = tokenize('${_chunks[i].bookTitle} ${_chunks[i].pathLabel} ${_chunks[i].content}');
      docLengths[i] = tokens.length;
      scores[i] = 0;
    }

    final avgDocLength = docLengths.values.isEmpty
        ? 1.0
        : docLengths.values.fold<int>(0, (a, b) => a + b) / totalDocs;

    const k1 = 1.5;
    const b = 0.75;

    for (final qt in queryTokens) {
      final posting = _invertedIndex[qt];
      if (posting == null) continue;
      final df = posting.length;
      final idf = log((totalDocs - df + 0.5) / (df + 0.5) + 1.0);

      for (final docId in posting) {
        final dl = docLengths[docId] ?? 1;
        final docTokens = tokenize(
          '${_chunks[docId].bookTitle} ${_chunks[docId].pathLabel} ${_chunks[docId].content}',
        );
        final tf = docTokens.where((t) => t == qt).length;
        final numerator = tf * (k1 + 1);
        final denominator = tf + k1 * (1 - b + b * (dl / avgDocLength));
        scores[docId] = (scores[docId] ?? 0) + idf * (numerator / denominator);
      }
    }

    _titleBoost(queryTokens, scores);

    final sorted = scores.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final top = sorted.take(limit).map((e) => (chunk: _chunks[e.key], score: e.value)).toList();

    final expanded = _expandWithContext(top, limit);
    if (minScore > 0) {
      return expanded.where((r) => r.score >= minScore).take(limit).toList();
    }
    return expanded;
  }

  List<({BookChunk chunk, double score})> _expandWithContext(
    List<({BookChunk chunk, double score})> results, int limit) {
    if (results.isEmpty) return results;
    final seen = <String>{};
    final expanded = <({BookChunk chunk, double score})>[];

    for (final r in results) {
      if (seen.contains(r.chunk.id)) continue;
      seen.add(r.chunk.id);
      expanded.add(r);

      // جلب المقطع الذي قبل هذا المقطع (نفس الفصل)
      final prevIdx = r.chunk.chunkIndex - 1;
      if (prevIdx >= 0) {
        final prev = _chunks.where(
          (c) => c.bookTitle == r.chunk.bookTitle && c.chapterTitle == r.chunk.chapterTitle && c.chunkIndex == prevIdx,
        ).toList();
        for (final p in prev) {
          if (seen.add(p.id)) {
            expanded.add((chunk: p, score: r.score * 0.7));
          }
        }
      }

      // جلب المقطع الذي بعد هذا المقطع (نفس الفصل)
      final nextIdx = r.chunk.chunkIndex + 1;
      final next = _chunks.where(
        (c) => c.bookTitle == r.chunk.bookTitle && c.chapterTitle == r.chunk.chapterTitle && c.chunkIndex == nextIdx,
      ).toList();
      for (final n in next) {
        if (seen.add(n.id)) {
          expanded.add((chunk: n, score: r.score * 0.6));
        }
      }

      if (expanded.length >= limit * 3) break;
    }

    return expanded.take(limit).toList();
  }

  void _titleBoost(List<String> queryTokens, Map<int, double> scores) {
    for (int i = 0; i < _chunks.length; i++) {
      final titleTokens = tokenize('${_chunks[i].bookTitle} ${_chunks[i].pathLabel}');
      for (final qt in queryTokens) {
        if (titleTokens.contains(qt)) {
          scores[i] = (scores[i] ?? 0) + 2.0;
        }
      }
    }
  }

  Future<BookChunk> addBook({
    required String title,
    required String content,
    String chapter = 'عام',
  }) async {
    final chunks = _chunkTextIntelligently(content, title);
    for (final chunk in chunks) {
      _chunks.add(chunk);
    }
    _buildIndex();
    await _saveToDisk();
    debugPrint('[KnowledgeBase] Added "$title" — ${chunks.length} chunks');
    return chunks.first;
  }

  /// ----- التقسيم الذكي الذي يكشف الأبواب والفصول والأقسام -----
  @visibleForTesting
  static final RegExp headingPattern = RegExp(
    r'^[#*]{1,4}\s+(.+)$'           // # or * markdown-style
    r'|^(الفصل\s+(الأول|الثاني|الثالث|الرابع|الخامس|السادس|السابع|الثامن|التاسع|العاشر|\d+))[\s:\.\-]*'  // الفصل الأول/1
    r'|^(الباب\s+(الأول|الثاني|الثالث|الرابع|الخامس|\d+))[\s:\.\-]*'   // الباب الأول/1
    r'|^(المبحث\s+(الأول|الثاني|\d+))[\s:\.\-]*'         // المبحث
    r'|^(المطلب\s+(الأول|الثاني|\d+))[\s:\.\-]*'         // المطلب
    r'|^(الفرع\s+(الأول|الثاني|\d+))[\s:\.\-]*'          // الفرع
    r'|^(Chapter\s+\d+[\s:\.\-]+.+)$'                      // English chapter
    r'|^(Section\s+\d+\.[\d\s:\.\-]+.+)$'
    r'|^(Part\s+\d+[\s:\.\-]+.+)$'
    r'|^INTRODUCTION$'
    r'|^(\d+\.\d+\s+.+)$'                                   // 1.1 Section
    r'|^(\d+\.\s+[A-Z].+)$',                                // 1. Title
    multiLine: true,
    caseSensitive: false,
  );

  @visibleForTesting
  static bool looksLikeArabicHeading(String line) {
    final trimmed = line.trim();
    if (trimmed.length > 80 || trimmed.length < 3) return false;
    if (trimmed.endsWith('.') || trimmed.endsWith('،') || trimmed.endsWith('؛')) return false;
    // يتكون من كلمات عربية أو إنجليزية قليلة (أقل من 15 كلمة)
    final wordCount = trimmed.split(RegExp(r'\s+')).length;
    if (wordCount > 14) return false;
    return true;
  }

  List<BookChunk> _chunkTextIntelligently(String text, String bookTitle) {
    // 1. Split into paragraphs first
    final paragraphs = text.split(RegExp(r'\n\s*\n'));
    if (paragraphs.isEmpty) return [];

    // 2. Detect hierarchical headings
    final struct = <({int level, String kind, String title, int startPara})>[];
    int totalChapters = 0;

    for (int i = 0; i < paragraphs.length; i++) {
      final para = paragraphs[i].trim();
      if (para.isEmpty) continue;

      final firstLine = para.split('\n').first.trim();

      // Check heading patterns
      String? detectedType;
      String? detectedTitle;

      final m = headingPattern.firstMatch(firstLine);
      if (m != null) {
        final cap = m.group(0) ?? firstLine;
        detectedTitle = cap.trim();
        if (m.group(1) != null) {
          detectedType = 'chapter';
        } else {
          final lower = cap.toLowerCase();
          if (lower.startsWith('chapter') || lower.startsWith('الفصل')) {
            detectedType = 'chapter';
          } else if (lower.startsWith('part') || lower.startsWith('الباب')) {
            detectedType = 'part';
          } else if (lower.startsWith('section') || lower.startsWith('المبحث') || lower.startsWith('المطلب') || lower.startsWith('الفرع')) {
            detectedType = 'section';
          } else if (RegExp(r'^\d+\.\d+\s+').hasMatch(lower)) {
            detectedType = 'section';
          } else if (RegExp(r'^\d+\.\s+').hasMatch(lower)) {
            detectedType = 'chapter';
          } else {
            detectedType = 'section';
          }
        }
      } else if (looksLikeArabicHeading(firstLine) && i > 0) {
        detectedType = 'section';
        detectedTitle = firstLine;
      }

      if (detectedType != null && detectedTitle != null) {
        struct.add((
          level: struct.length,
          kind: detectedType,
          title: detectedTitle,
          startPara: i,
        ));
        if (detectedType == 'chapter') totalChapters++;
      }
    }

    // 3. Assign paragraphs to sections
    final sections = <({int startPara, int endPara, String kind, String title})>[];
    for (int i = 0; i < struct.length; i++) {
      final end = i + 1 < struct.length ? struct[i + 1].startPara : paragraphs.length;
      sections.add((
        startPara: struct[i].startPara,
        endPara: end,
        kind: struct[i].kind,
        title: struct[i].title,
      ));
    }

    // If no sections detected, treat whole as one chapter
    if (sections.isEmpty) {
      sections.add((
        startPara: 0,
        endPara: paragraphs.length,
        kind: 'chapter',
        title: 'عام',
      ));
      totalChapters = 1;
    }

    // 4. Build hierarchy for each section and chunk
    final currentHierarchy = <BookSection>[];
    currentHierarchy.add(BookSection(level: 'book', title: bookTitle));

    final List<BookChunk> result = [];
    const maxChunkSize = 800;
    const overlap = 100;

    for (final sec in sections) {
      // Update hierarchy based on kind
      if (sec.kind == 'part') {
        currentHierarchy.removeWhere((h) => h.level == 'part');
        currentHierarchy.removeWhere((h) => h.level == 'chapter' || h.level == 'section');
        currentHierarchy.add(BookSection(level: 'part', title: sec.title));
      } else if (sec.kind == 'chapter') {
        currentHierarchy.removeWhere((h) => h.level == 'chapter' || h.level == 'section');
        currentHierarchy.add(BookSection(level: 'chapter', title: sec.title));
      } else if (sec.kind == 'section') {
        currentHierarchy.removeWhere((h) => h.level == 'section');
        currentHierarchy.add(BookSection(level: 'section', title: sec.title));
      }

      final secText = paragraphs.sublist(sec.startPara, sec.endPara)
          .where((p) => p.trim().isNotEmpty)
          .join('\n\n')
          .trim();

      if (secText.isEmpty) continue;

      // 5. Chunk this section's text by word count
      final words = secText.split(RegExp(r'\s+'));
      if (words.length <= maxChunkSize) {
        result.add(BookChunk(
          id: const Uuid().v4(),
          bookTitle: bookTitle,
          hierarchy: List.from(currentHierarchy),
          content: secText,
          chunkIndex: 0,
          totalChunks: 1,
          totalChapters: totalChapters,
        ));
      } else {
        int start = 0;
        int ci = 0;
        while (start < words.length) {
          final end = (start + maxChunkSize).clamp(0, words.length);
          final chunkWords = words.sublist(start, end);
          result.add(BookChunk(
            id: const Uuid().v4(),
            bookTitle: bookTitle,
            hierarchy: List.from(currentHierarchy),
            content: chunkWords.join(' '),
            chunkIndex: ci,
            totalChunks: ((words.length + maxChunkSize - 1) / maxChunkSize).ceil(),
            totalChapters: totalChapters,
          ));
          start += maxChunkSize - overlap;
          ci++;
        }
      }
    }

    return result;
  }

  /// ----- استخراج النص من PDF بمكتبة Syncfusion احترافية -----
  String extractTextFromBytes(Uint8List bytes) {
    final extracted = _parsePdfBytes(bytes);
    if (extracted != null && extracted.isNotEmpty) {
      debugPrint('[KnowledgeBase] PDF extracted ${extracted.length} chars from bytes');
      return extracted;
    }
    return 'تعذر استخراج النص من هذا PDF. يُفضل استخدام ملفات .txt للكتب العربية.';
  }

  Future<String> readTextFile(String filePath) {
    if (kIsWeb) return Future<String>.value('');
    return File(filePath).readAsString();
  }

  Future<String> extractTextFromPdf(String filePath) async {
    try {
      if (kIsWeb) return '';
      final bytes = await File(filePath).readAsBytes();
      final extracted = _parsePdfBytes(bytes);
      if (extracted != null && extracted.isNotEmpty) {
        debugPrint('[KnowledgeBase] PDF extracted ${extracted.length} chars via Syncfusion');
        return extracted;
      }
    } catch (e) {
      debugPrint('[KnowledgeBase] Syncfusion error: $e');
    }
    // Fallback basic
    final basic = _basicPdfExtraction(filePath);
    if (basic.isNotEmpty) return basic;
    return 'تعذر استخراج النص من هذا PDF. يُفضل استخدام ملفات .txt للكتب العربية.';
  }

  String? _parsePdfBytes(List<int> bytes) {
    try {
      final doc = PdfDocument(inputBytes: bytes);
      final buf = StringBuffer();
      for (int i = 0; i < doc.pages.count; i++) {
        final pageText = PdfTextExtractor(doc).extractText(startPageIndex: i, endPageIndex: i);
        buf.writeln('--- صفحة ${i + 1} ---');
        buf.writeln(pageText);
      }
      doc.dispose();
      final extracted = buf.toString().trim();
      return extracted.isNotEmpty ? extracted : null;
    } catch (e) {
      debugPrint('[KnowledgeBase] Syncfusion extract error: $e');
      return null;
    }
  }

  String _basicPdfExtraction(String path) {
    try {
      final bytes = File(path).readAsBytesSync();
      final text = String.fromCharCodes(bytes);
      final buf = StringBuffer();

      // Extract text between parentheses (PDF text objects)
      final parenRegex = RegExp(r'\(([^)]*)\)');
      for (final match in parenRegex.allMatches(text)) {
        final part = match.group(1)!;
        if (part.length > 2 && !part.startsWith('\\')) {
          buf.write('$part ');
        }
      }

      final extracted = buf.toString().trim();
      if (extracted.isNotEmpty) return extracted;

      // Try UTF-16 / Unicode extraction
      final unicodeBuf = StringBuffer();
      for (int i = 0; i < bytes.length - 1; i += 2) {
        final code = (bytes[i + 1] << 8) | bytes[i];
        if (code >= 32 && code <= 0xFFFF && code != 0xFEFF && code < 0xFFFE) {
          unicodeBuf.writeCharCode(code);
        }
      }
      final unicodeText = unicodeBuf.toString().trim();
      if (unicodeText.length > 100) return unicodeText;

      return '';
    } catch (_) {
      return '';
    }
  }

  Future<void> addBookFromFile(String filePath) async {
    if (kIsWeb) throw UnsupportedError('لا يمكن قراءة الملفات المحلية على الويب');
    final file = File(filePath);
    final name = file.uri.pathSegments.last.replaceAll(RegExp(r'\.(txt|pdf)$'), '');

    String content;
    if (filePath.endsWith('.pdf')) {
      content = await extractTextFromPdf(filePath);
    } else {
      content = await file.readAsString();
    }

    if (content.trim().isEmpty) {
      throw Exception('الملف فارغ أو غير قابل للقراءة');
    }

    await addBook(title: name, content: content);
  }

  List<({BookChunk chunk, double score})> searchExpanded(String query, {int limit = 8, double minScore = 0.0}) {
    final results = search(query, limit: limit, minScore: minScore);
    if (results.isEmpty && RegExp(r'[\u0600-\u06FF]').hasMatch(query)) {
      final translit = transliterateArabic(query);
      if (translit != query) {
        final altResults = search(translit, limit: limit, minScore: minScore);
        if (altResults.isNotEmpty) return altResults;
      }
    } else if (RegExp(r'^[a-zA-Z]').hasMatch(query)) {
      final arQuery = translateKeyTerms(query);
      if (arQuery != query) {
        final altResults = search(arQuery, limit: limit, minScore: minScore);
        if (altResults.length > results.length) return altResults;
      }
    }
    return results;
  }

  @visibleForTesting
  String transliterateArabic(String text) {
    const map = {
      'تغذية': 'nutrition', 'تدريب': 'training', 'سباحة': 'swimming',
      'نوم': 'sleep', 'إصابة': 'injury', 'تعافي': 'recovery',
      'بروتين': 'protein', 'كربوهيدرات': 'carbs', 'دهون': 'fats',
      'عضلات': 'muscles', 'قلب': 'heart', 'أكسجين': 'oxygen',
      'ماء': 'water', 'طاقة': 'energy', 'قوة': 'strength',
      'تحمل': 'endurance', 'سرعة': 'speed', 'مرونة': 'flexibility',
      'تأهيل': 'rehabilitation', 'تمارين': 'exercises',
      'رياضة': 'sports', 'صحة': 'health', 'غذاء': 'food',
      'سعرات': 'calories', 'وزن': 'weight', 'طول': 'height',
      'نفس': 'breathing', 'تركيز': 'focus', 'إحماء': 'warmup',
    };
    var result = text;
    for (final entry in map.entries) {
      result = result.replaceAll(entry.key, entry.value);
    }
    return result;
  }

  @visibleForTesting
  String translateKeyTerms(String text) {
    const map = {
      'nutrition': 'تغذية', 'training': 'تدريب', 'swimming': 'سباحة',
      'sleep': 'نوم', 'injury': 'إصابة', 'recovery': 'تعافي',
      'protein': 'بروتين', 'exercise': 'تمارين', 'sport': 'رياضة',
      'health': 'صحة', 'food': 'غذاء', 'calories': 'سعرات',
      'weight': 'وزن', 'breathing': 'نفس', 'warmup': 'إحماء',
    };
    var result = text.toLowerCase();
    for (final entry in map.entries) {
      if (result.contains(entry.key)) {
        result = '$result ${entry.value}';
      }
    }
    return result;
  }

  Future<void> removeBook(String title) async {
    _chunks.removeWhere((c) => c.bookTitle == title);
    _buildIndex();
    await _saveToDisk();
  }

  List<String> getBookTitles() {
    return _chunks.map((c) => c.bookTitle).toSet().toList();
  }

  Map<String, List<String>> getBookStructure(String bookTitle) {
    final chapters = _chunks
        .where((c) => c.bookTitle == bookTitle)
        .map((c) => c.sourceLabel)
        .toSet()
        .toList();
    return {bookTitle: chapters};
  }

  Future<void> clear() async {
    _chunks.clear();
    _invertedIndex.clear();
    await _saveToDisk();
  }
}
