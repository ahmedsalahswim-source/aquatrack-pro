import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/services/ai_model_router.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/core/services/swimmer_context_builder.dart';

void main() {
  group('AiModelRouter.classifyQuery', () {
    late AiModelRouter router;

    setUp(() {
      router = AiModelRouter(models: const []);
    });

    group('simple queries', () {
      test('short greeting returns simple', () {
        expect(router.classifyQuery('hi'), QueryComplexity.simple);
        expect(router.classifyQuery('hello'), QueryComplexity.simple);
        expect(router.classifyQuery('hey'), QueryComplexity.simple);
        expect(router.classifyQuery('مرحبا'), QueryComplexity.simple);
        expect(router.classifyQuery('اهلا'), QueryComplexity.simple);
        expect(router.classifyQuery('السلام'), QueryComplexity.simple);
        expect(router.classifyQuery('شلون'), QueryComplexity.simple);
        expect(router.classifyQuery('كيف'), QueryComplexity.simple);
      });

      test('very short query (< 3 words) returns simple', () {
        expect(router.classifyQuery('ok'), QueryComplexity.simple);
        expect(router.classifyQuery('no'), QueryComplexity.simple);
        expect(router.classifyQuery('abc'), QueryComplexity.simple);
      });

      test('greeting with 1-2 extra words still simple', () {
        expect(router.classifyQuery('hello there'), QueryComplexity.simple);
        expect(router.classifyQuery('مرحبا كيفك'), QueryComplexity.simple);
        expect(router.classifyQuery('hi how'), QueryComplexity.simple);
      });
    });

    group('normal queries', () {
      test('medium question without analysis returns normal', () {
        final result = router.classifyQuery('What is the best stroke for beginners?');
        expect(result, QueryComplexity.normal);
      });

      test('question with 6-8 words returns normal', () {
        expect(router.classifyQuery('What warm up do you recommend for swimming'), QueryComplexity.normal);
        expect(router.classifyQuery('Should I rest today before competition'), QueryComplexity.normal);
      });
    });

    group('complex queries', () {
      test('comparison query returns complex', () {
        final result = router.classifyQuery('What is the difference between freestyle and backstroke?');
        expect(result, QueryComplexity.complex);
      });

      test('analysis query without data ref returns complex', () {
        expect(router.classifyQuery('Explain the proper breathing technique for freestyle'), QueryComplexity.complex);
      });

      test('how-question returns complex', () {
        expect(router.classifyQuery('How can I improve my freestyle stroke?'), QueryComplexity.complex);
      });

      test('long question (> 15 words) returns complex', () {
        final result = router.classifyQuery('I want to know how to improve my breathing technique while swimming freestyle laps');
        expect(result, QueryComplexity.complex);
      });

      test('Arabic comparison returns complex', () => switch (router.classifyQuery('مقارنة بين السباحة الحرة والظهر'))
        { QueryComplexity.complex => expect(true, isTrue), _ => fail('expected complex') });
    });

    group('analytical queries', () {
      test('data reference + analysis returns analytical', () {
        final result = router.classifyQuery('حلل معدل نبضات قلبي هذا الأسبوع');
        expect(result, QueryComplexity.analytical);
      });

      test('data ref with question mark returns analytical', () {
        expect(router.classifyQuery('كيف كان نومي خلال الأسبوع الماضي؟'), QueryComplexity.analytical);
        expect(router.classifyQuery('What is my average heart rate this week?'), QueryComplexity.analytical);
      });

      test('stress data query returns analytical', () {
        final result = router.classifyQuery('Why is my stress score high this week?');
        expect(result, QueryComplexity.analytical);
      });
    });
  });

  group('SwimmerContextBuilder', () {
    late SwimmerContextBuilder builder;

    setUp(() {
      builder = const SwimmerContextBuilder();
    });

    final athlete = AthleteEntity(
      id: '1',
      parentId: 'p1',
      name: 'أحمد',
      birthDate: DateTime(2012, 5, 15),
      gender: Gender.male,
      swimLevel: SwimLevel.intermediate,
      weightKg: 45,
      heightCm: 155,
      targetWeeklyHours: 6,
      createdAt: DateTime(2026, 1, 1),
    );

    test('includes athlete profile in context', () async {
      final context = builder.buildFullContext(
        athlete: athlete,
        recentLogs: [],
      );
      expect(context, contains('أحمد'));
      expect(context, contains('14'));
      expect(context, contains('ذكر'));
      expect(context, contains('متوسط'));
      expect(context, contains('45'));
      expect(context, contains('155'));
      expect(context, contains('6'));
    });

    test('includes "no logs" when recentLogs empty', () async {
      final context = builder.buildFullContext(athlete: athlete, recentLogs: []);
      expect(context, contains('لا توجد تسجيلات كافية'));
    });

    test('includes swimmer data when logs provided', () async {
      final log = DailyLogEntity(
        id: 'l1',
        athleteId: '1',
        date: '2026-06-10',
        restingHR: 65,
        sleepHours: 8.5,
        sleepQuality: SleepQuality.good,
        wellnessScore: 4,
        nutrition: const NutritionData(breakfast: true, lunch: true, dinner: true, hydrationLiters: 2.0, proteinSufficient: true),
        training: const TrainingData(trained: true, type: TrainingType.endurance, durationMinutes: 60, rpe: 7, distanceMeters: 2000),
        stressScore: 30,
        acwr: 1.1,
        createdAt: DateTime(2026, 6, 10),
      );

      final context = builder.buildFullContext(
        athlete: athlete,
        recentLogs: [log],
      );

      expect(context, contains('65'));
      expect(context, contains('8.5'));
      expect(context, contains('جيد'));
      expect(context, contains('3'));
      expect(context, contains('7'));
      expect(context, contains('1.10'));
    });

    test('includes todayLog when provided', () async {
      final todayLog = DailyLogEntity(
        id: 'today',
        athleteId: '1',
        date: '2026-06-13',
        restingHR: 68,
        sleepHours: 7,
        stressScore: 40,
        acwr: 0.9,
        createdAt: DateTime(2026, 6, 13),
      );

      final context = builder.buildFullContext(
        athlete: athlete,
        recentLogs: [],
        todayLog: todayLog,
      );

      expect(context, contains('تسجيل اليوم'));
      expect(context, contains('68'));
      expect(context, contains('7'));
      expect(context, contains('40'));
    });

    test('includes ACWR and stress analysis', () async {
      final context = builder.buildFullContext(
        athlete: athlete,
        recentLogs: [],
        acwr: 1.2,
        stressScore: 50,
      );

      expect(context, contains('1.20'));
      expect(context, contains('مثالي'));
      expect(context, contains('50'));
    });

    test('handles female athlete correctly', () async {
      final femaleAthlete = AthleteEntity(
        id: '2',
        parentId: 'p1',
        name: 'سارة',
        birthDate: DateTime(2013, 8, 20),
        gender: Gender.female,
        swimLevel: SwimLevel.beginner,
        targetWeeklyHours: 4,
        createdAt: DateTime(2026, 1, 1),
      );

      final context = builder.buildFullContext(
        athlete: femaleAthlete,
        recentLogs: [],
      );

      expect(context, contains('سارة'));
      expect(context, contains('أنثى'));
      expect(context, contains('مبتدئ'));
    });
  });
}
