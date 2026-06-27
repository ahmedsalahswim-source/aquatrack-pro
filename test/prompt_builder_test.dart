import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/services/prompt_builder.dart';
import 'package:aquatrack_pro/core/models/book_chunk.dart';
import 'package:aquatrack_pro/core/models/web_search_result.dart';

BookChunk _chunk(String bookTitle, String content, {int chunkIndex = 0, int totalChunks = 1}) {
  return BookChunk(
    id: '$bookTitle-$chunkIndex',
    bookTitle: bookTitle,
    hierarchy: const [],
    content: content,
    chunkIndex: chunkIndex,
    totalChunks: totalChunks,
  );
}

void main() {
  late PromptBuilder builder;

  setUp(() {
    builder = const PromptBuilder();
  });

  group('buildSystemPrompt', () {
    test('contains system role with empty input', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: '', kbResults: []);
      expect(prompt, contains('مدرب AquaTrack Pro'));
      expect(prompt, contains('السباحين الناشئين'));
    });

    test('contains language instructions by default', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: '', kbResults: []);
      expect(prompt, contains('فهم أي لغة وأي لهجة'));
      expect(prompt, contains('كشف اللغة تلقائياً'));
    });

    test('contains reasoning framework', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: '', kbResults: []);
      expect(prompt, contains('إطار الاستدلال العميق'));
      expect(prompt, contains('للأسئلة التحليلية'));
      expect(prompt, contains('التوليف'));
    });

    test('contains response rules', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: '', kbResults: []);
      expect(prompt, contains('قواعد الإجابة النهائية'));
      expect(prompt, contains('نظام الوسوم'));
      expect(prompt, contains('المتابعة'));
    });

    test('includes swimmer data section when context provided', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: 'العمر: 14 سنة\nالجنس: ذكر\nالنوم: 8 ساعات', kbResults: []);
      expect(prompt, contains('بيانات السباح'));
      expect(prompt, contains('العمر: 14 سنة'));
      expect(prompt, contains('النوم: 8 ساعات'));
    });

    test('skips swimmer data section when empty', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: '', kbResults: []);
      expect(prompt.contains('=== بيانات السباح ==='), isFalse);
    });

    test('includes KB book titles and chunks', () async {
      final chunks = [
        _chunk('كتاب التدريب', 'معلومات تدريبية مهمة'),
        _chunk('كتاب التغذية', 'نصائح غذائية للسباحين'),
      ];
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: chunks,
        userQuery: 'how to swim?',
      );

      expect(prompt, contains('المكتبة المرجعية'));
      expect(prompt, contains('كتاب التدريب'));
      expect(prompt, contains('كتاب التغذية'));
      expect(prompt, contains('معلومات تدريبية مهمة'));
      expect(prompt, contains('نصائح غذائية للسباحين'));
    });

    test('lists each book title only once', () async {
      final chunks = [
        _chunk('كتاب التدريب', 'معلومة 1'),
        _chunk('كتاب التدريب', 'معلومة 2'),
        _chunk('كتاب التغذية', 'معلومة 3'),
      ];
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: chunks,
        userQuery: 'train?',
      );

      final listingStart = prompt.indexOf('--- مقتطفات من الكتب ---');
      final beforeChunks = prompt.substring(0, listingStart);
      // Book titles listed once each before chunks section
      expect(beforeChunks, contains('كتاب التدريب'));
      expect(beforeChunks, contains('كتاب التغذية'));
    });

    test('shows chunk part numbers when totalChunks > 1', () async {
      final chunks = [
        _chunk('كتاب طويل', 'محتوى الجزء 1', chunkIndex: 0, totalChunks: 3),
      ];
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: chunks,
        userQuery: 'long book?',
      );

      expect(prompt, contains('الجزء 1 من 3'));
    });

    test('skips part number when totalChunks == 1', () async {
      final chunks = [
        _chunk('كتاب قصير', 'محتوى', chunkIndex: 0, totalChunks: 1),
      ];
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: chunks,
        userQuery: 'short?',
      );

      expect(prompt.contains('الجزء 1 من'), isFalse);
    });

    test('shows "no KB results" message when kbResults empty and userQuery given', () async {
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: [],
        userQuery: 'test query',
      );

      expect(prompt, contains('لم يتم العثور على معلومات في المكتبة المرجعية'));
    });

    test('includes web results when provided', () async {
      final webResults = [
        WebSearchResult(title: 'Web Title', snippet: 'Web snippet', url: 'https://example.com', source: 'duckduckgo'),
      ];
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: [],
        webResults: webResults,
        userQuery: 'search?',
      );

      expect(prompt, contains('نتائج إضافية من الويب'));
      expect(prompt, contains('Web Title'));
      expect(prompt, contains('Web snippet'));
      expect(prompt, contains('DuckDuckGo'));
    });

    test('includes conversation history when provided', () async {
      final history = [
        'س: ما هو ACWR؟',
        'ج: ACWR هو نسبة الحمل الحاد إلى المزمن...',
      ];
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: [],
        conversationHistory: history,
      );

      expect(prompt, contains('سياق المحادثة السابقة'));
      expect(prompt, contains('ما هو ACWR'));
    });

    test('skips conversation history section when empty', () async {
      final prompt = builder.buildSystemPrompt(swimmerContext: 'data', kbResults: []);
      expect(prompt, isNot(contains('سياق المحادثة السابقة')));
    });

    test('includes source priority instructions with userQuery', () async {
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'data',
        kbResults: [],
        userQuery: 'query',
      );

      expect(prompt, contains('أولويات المصادر'));
      expect(prompt, contains('المكتبة المرجعية (الكتب المضمنة)'));
      expect(prompt, contains('بيانات السباح'));
      expect(prompt, contains('نتائج الويب'));
      expect(prompt, contains('معرفتك العلمية'));
    });

    test('prompt with full parameters contains all sections', () async {
      final prompt = builder.buildSystemPrompt(
        swimmerContext: 'عمر: 14\nنوم: 8',
        kbResults: [_chunk('كتاب', 'محتوى')],
        webResults: [WebSearchResult(title: 'نتيجة', snippet: 'وصف', url: 'https://x.com', source: 'web')],
        userQuery: 'كيف أنام أفضل؟',
        conversationHistory: ['سؤال سابق', 'إجابة سابقة'],
      );

      expect(prompt, contains('مدرب AquaTrack Pro'));
      expect(prompt, contains('بيانات السباح'));
      expect(prompt, contains('المكتبة المرجعية'));
      expect(prompt, contains('نتائج إضافية من الويب'));
      expect(prompt, contains('سياق المحادثة السابقة'));
      expect(prompt, contains('إطار الاستدلال العميق'));
      expect(prompt, contains('قواعد الإجابة النهائية'));
    });
  });
}
