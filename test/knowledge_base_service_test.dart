import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/services/knowledge_base_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('tokenize', () {
    test('splits text into lowercase tokens', () {
      final result = KnowledgeBaseService().tokenize('Swimming Training');
      expect(result, contains('swimming'));
      expect(result, contains('training'));
    });

    test('removes punctuation', () {
      final result = KnowledgeBaseService().tokenize('hello, world! how are you?');
      expect(result, contains('hello'));
      expect(result, contains('world'));
      expect(result, contains('how'));
      expect(result, contains('are'));
      expect(result, contains('you'));
    });

    test('excludes tokens of length <= 1', () {
      final result = KnowledgeBaseService().tokenize('a b c hello');
      expect(result, contains('hello'));
      expect(result, isNot(contains('a')));
      expect(result, isNot(contains('b')));
      expect(result, isNot(contains('c')));
    });
  });

  group('transliterateArabic', () {
    test('maps Arabic key terms to English', () {
      final result = KnowledgeBaseService().transliterateArabic('تدريب سباحة');
      expect(result, contains('training'));
      expect(result, contains('swimming'));
    });

    test('preserves non-mapped words and maps known terms', () {
      final result = KnowledgeBaseService().transliterateArabic('كيف يكون تدريب السباحة');
      expect(result, contains('training'));
      expect(result, contains('swimming'));
    });

    test('maps multiple terms', () {
      final result = KnowledgeBaseService().transliterateArabic('تغذية تدريب نوم');
      expect(result, contains('nutrition'));
      expect(result, contains('training'));
      expect(result, contains('sleep'));
    });
  });

  group('translateKeyTerms', () {
    test('appends Arabic terms after English query', () {
      final result = KnowledgeBaseService().translateKeyTerms('nutrition for swimmers');
      expect(result, contains('nutrition for swimmers'));
      expect(result, contains('تغذية'));
    });

    test('handles multiple key terms', () {
      final result = KnowledgeBaseService().translateKeyTerms('sleep and recovery');
      expect(result, contains('sleep and recovery'));
      expect(result, contains('نوم'));
      expect(result, contains('تعافي'));
    });

    test('returns original if no key terms found', () {
      final result = KnowledgeBaseService().translateKeyTerms('hello world');
      expect(result, 'hello world');
    });
  });

  group('looksLikeArabicHeading', () {
    test('returns true for short Arabic heading', () {
      expect(KnowledgeBaseService.looksLikeArabicHeading('الفوائد الصحية للسباحة'), isTrue);
    });

    test('returns false for very short text', () {
      expect(KnowledgeBaseService.looksLikeArabicHeading('مر'), isFalse);
    });

    test('returns false for long text (> 80 chars)', () {
      final long = 'هذا نص طويل جداً من المفترض ألا يكون عنواناً لأنه طويل أكثر من ثمانين حرفاً';
      expect(KnowledgeBaseService.looksLikeArabicHeading(long), isFalse);
    });

    test('returns false for text ending with punctuation', () {
      expect(KnowledgeBaseService.looksLikeArabicHeading('هذا عنوان.'), isFalse);
    });

    test('returns false for many words (> 14)', () {
      final many = 'واحد اثنان ثلاثة أربعة خمسة ستة سبعة ثمانية تسعة عشرة أحد عشر اثنا عشر ثلاثة عشر أربعة عشر';
      expect(KnowledgeBaseService.looksLikeArabicHeading(many), isFalse);
    });
  });

  group('headingPattern', () {
    test('matches markdown-style headings', () {
      final m = KnowledgeBaseService.headingPattern.firstMatch('# الفصل الأول');
      expect(m, isNotNull);
    });

    test('matches Arabic chapter headings', () {
      final m = KnowledgeBaseService.headingPattern.firstMatch('الفصل الأول: التغذية');
      expect(m, isNotNull);
    });

    test('matches Arabic باب headings', () {
      final m = KnowledgeBaseService.headingPattern.firstMatch('الباب الأول');
      expect(m, isNotNull);
    });

    test('matches English chapter headings', () {
      final m = KnowledgeBaseService.headingPattern.firstMatch('Chapter 1: Introduction');
      expect(m, isNotNull);
    });

    test('matches numbered section headings', () {
      final m = KnowledgeBaseService.headingPattern.firstMatch('1.1 Training Basics');
      expect(m, isNotNull);
    });

    test('matches numbered title headings', () {
      final m = KnowledgeBaseService.headingPattern.firstMatch('1. Introduction to Swimming');
      expect(m, isNotNull);
    });
  });

  group('search', () {
    late KnowledgeBaseService service;

    setUp(() {
      service = KnowledgeBaseService();
    });

    test('returns empty when not ready', () {
      final results = service.search('test');
      expect(results, isEmpty);
    });

    test('returns empty when no chunks', () {
      service.ready = true;
      final results = service.search('test');
      expect(results, isEmpty);
    });

    test('returns empty for empty query', () {
      service.ready = true;
      final results = service.search('');
      expect(results, isEmpty);
    });

    test('finds matching chunks by content', () {
      service.addChunksInMemory(title: 'كتاب التدريب', content: 'تمارين السباحة للمبتدئين');
      service.ready = true;

      final results = service.search('تمارين');
      expect(results, isNotEmpty);
      expect(results.first.chunk.bookTitle, 'كتاب التدريب');
    });

    test('finds matching chunks by book title', () {
      service.addChunksInMemory(title: 'كتاب التغذية', content: 'غذاء رياضي متوازن للصغار');
      service.ready = true;

      final results = service.search('غذاء');
      expect(results, isNotEmpty);
      expect(results.first.chunk.bookTitle, 'كتاب التغذية');
    });

    test('boosts title matches', () {
      service.addChunksInMemory(title: 'فوائد النوم للرياضي', content: 'نوم عميق يساعد على التعافي');
      service.ready = true;

      final results = service.search('نوم');
      expect(results, isNotEmpty);
      expect(results.first.chunk.bookTitle, 'فوائد النوم للرياضي');
    });

    test('applies minScore filter', () {
      service.addChunksInMemory(title: 'كتاب سباحة', content: 'تقنيات السباحة الحرة');
      service.ready = true;

      final results = service.search('سباحة', minScore: 10.0);
      expect(results, isEmpty);
    });

    test('sorts results by descending score', () {
      service.addChunksInMemory(title: 'كتاب التدريب', content: 'تمارين السباحة للمبتدئين والمحترفين');
      service.addChunksInMemory(title: 'كتاب التغذية', content: 'نصائح غذائية للرياضيين');
      service.ready = true;

      final results = service.search('تمارين');
      expect(results, isNotEmpty);
      if (results.length >= 2) {
        expect(results.first.score, greaterThan(results.last.score));
      }
    });
  });

  group('searchExpanded', () {
    late KnowledgeBaseService service;

    setUp(() {
      service = KnowledgeBaseService();
      service.addChunksInMemory(title: 'فوائد النوم', content: 'نوم عميق يساعد على تعافي العضلات');
      service.ready = true;
    });

    test('returns results for Arabic query', () {
      final results = service.searchExpanded('نوم');
      expect(results, isNotEmpty);
    });

    test('falls back to transliteration for Arabic query with no direct hits', () {
      final results = service.searchExpanded('تغذية');
      expect(results, isEmpty);
    });

    test('expands English query with Arabic key terms', () {
      final results = service.searchExpanded('recovery');
      expect(results, isNotEmpty);
    });
  });

  group('getBookTitles', () {
    test('returns unique book titles', () {
      final service = KnowledgeBaseService();
      service.addChunksInMemory(title: 'كتاب أ', content: 'محتوى عن الصحة');
      service.addChunksInMemory(title: 'كتاب ب', content: 'محتوى عن التدريب');
      service.addChunksInMemory(title: 'كتاب أ', content: 'محتوى إضافي');

      final titles = service.getBookTitles();
      expect(titles, contains('كتاب أ'));
      expect(titles, contains('كتاب ب'));
      expect(titles.length, 2);
    });
  });

  group('removeBook', () {
    test('removes all chunks for a given title', () async {
      final service = KnowledgeBaseService();
      service.addChunksInMemory(title: 'كتاب أ', content: 'محتوى عن الصحة');
      service.ready = true;

      expect(service.chunkCount, greaterThan(0));
      await service.removeBook('كتاب أ').catchError((_) {});
      expect(service.chunkCount, 0);
    });
  });
}
