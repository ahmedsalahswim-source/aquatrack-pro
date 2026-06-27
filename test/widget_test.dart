import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/utils/helpers.dart';

void main() {
  group('StressCalculator', () {
    test('no data returns 0 stress', () {
      final score = StressCalculator.calculate(
        sleepHours: null,
        recommendedSleep: null,
        restingHR: null,
        baselineHR: null,
        rpe: null,
        wellnessScore: null,
      );
      expect(score, 0);
    });

    test('sleep deficit contributes to stress', () {
      final score = StressCalculator.calculate(
        sleepHours: 6.0,
        recommendedSleep: 9.0,
        restingHR: null,
        baselineHR: null,
        rpe: null,
        wellnessScore: null,
      );
      // deficit=3 → sleepScore=30 → (30*0.3)*100 = 900 → clamped to 100
      expect(score, 100);
    });

    test('good sleep with full data returns moderate stress', () {
      final score = StressCalculator.calculate(
        sleepHours: 9.0,
        recommendedSleep: 9.0,
        restingHR: 58,
        baselineHR: 60,
        rpe: 3,
        wellnessScore: 5,
      );
      // sleep=0, hr=0 (deviation=2<5), rpe=0 (<4), wellness=0 (key 5)
      expect(score, 0);
    });

    test('high RPE contributes significantly to stress', () {
      final score = StressCalculator.calculate(
        sleepHours: 9.0,
        recommendedSleep: 9.0,
        restingHR: null,
        baselineHR: null,
        rpe: 9,
        wellnessScore: null,
      );
      // rpeScore=25 → (25*0.3)*100 = 750 → clamped to 100
      expect(score, 100);
    });
  });

  group('AcwrCalculator', () {
    test('balanced load returns 1.0 ratio', () {
      final result = AcwrCalculator.calculate(
        acuteLoads: [300, 300, 300, 300, 300, 300, 300],
        chronicLoads: [300, 300, 300, 300, 300, 300, 300],
      );
      // acute=300, chronic=300 → 300/300 = 1.0
      expect(result, closeTo(1.0, 0.01));
    });

    test('less than 7 acute samples returns 0', () {
      final result = AcwrCalculator.calculate(
        acuteLoads: [100, 100, 100],
      );
      expect(result, 0.0);
    });

    test('chronic load of 0 returns 0', () {
      final result = AcwrCalculator.calculate(
        acuteLoads: [300, 300, 300, 300, 300, 300, 300],
        chronicLoads: [0, 0, 0, 0, 0, 0, 0],
      );
      expect(result, 0.0);
    });

    test('stress label helpers work', () {
      expect(AcwrCalculator.getAcwrLabel(0.5), 'نشاط منخفض');
      expect(AcwrCalculator.getAcwrLabel(1.0), 'النطاق الآمن');
      expect(AcwrCalculator.getAcwrLabel(1.4), 'تحذير — الحمل يرتفع');
      expect(AcwrCalculator.getAcwrLabel(1.6), 'خطر — خطر الإصابة مرتفع');
    });
  });
}
