import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/services/swim_physics_engine.dart';
import 'package:aquatrack_pro/core/models/swim_pose_metrics.dart';

void main() {
  late SwimPhysicsEngine engine;

  setUp(() {
    engine = SwimPhysicsEngine();
  });

  group('analyze() with defaults', () {
    test('returns body angle ~170 from defaults', () {
      final result = engine.analyze();
      expect(result.bodyAngle, closeTo(170, 0.5));
      expect(result.bodyAngleScore, 'جيد');
    });

    test('returns drag rating in expected range', () {
      final result = engine.analyze();
      expect(result.dragRating, greaterThan(0));
      expect(result.dragRating, lessThan(200));
    });

    test('returns stroke efficiency in 0-100', () {
      final result = engine.analyze();
      expect(result.strokeEfficiency, greaterThan(0));
      expect(result.strokeEfficiency, lessThanOrEqualTo(100));
    });

    test('returns fatigue index in 0-100', () {
      final result = engine.analyze();
      expect(result.fatigueIndex, greaterThanOrEqualTo(0));
      expect(result.fatigueIndex, lessThanOrEqualTo(100));
    });

    test('returns stability index in 0-1', () {
      final result = engine.analyze();
      expect(result.stabilityIndex, greaterThanOrEqualTo(0));
      expect(result.stabilityIndex, lessThanOrEqualTo(1));
    });
  });

  group('body angle classification', () {
    test('excellent when angle >= 175', () {
      final result = engine.analyze(estimatedBodyAngle: 178);
      expect(result.bodyAngleScore, 'ممتاز');
    });

    test('good when angle >= 170', () {
      final result = engine.analyze(estimatedBodyAngle: 172);
      expect(result.bodyAngleScore, 'جيد');
    });

    test('acceptable when angle >= 160', () {
      final result = engine.analyze(estimatedBodyAngle: 165);
      expect(result.bodyAngleScore, 'مقبول');
    });

    test('weak when angle >= 150', () {
      final result = engine.analyze(estimatedBodyAngle: 155);
      expect(result.bodyAngleScore, 'ضعيف');
    });

    test('needs improvement when angle < 150', () {
      final result = engine.analyze(estimatedBodyAngle: 140);
      expect(result.bodyAngleScore, 'يحتاج تحسين كبير');
    });
  });

  group('drag coefficient', () {
    test('lower drag at better body angle', () {
      final excellent = engine.analyze(estimatedBodyAngle: 178).dragRating;
      final poor = engine.analyze(estimatedBodyAngle: 150).dragRating;
      expect(excellent, lessThan(poor));
    });
  });

  group('pose metrics integration', () {
    test('pose metrics provide real body angle', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 175,
        bodyRollAngle: 42,
        rollSymmetry: 94,
        headLift: 8,
        strokeRate: 45,
        strokeLength: 2.1,
        strokeIndex: 94.5,
        coordinationIndex: 5.2,
        handVelocity: 3.5,
        propulsiveDrag: 68,
        strouhalNumber: 0.32,
        kickFrequency: 48,
        kickAmplitude: 18,
        symmetryScore: 85,
        phaseDuration: {'catch_': 25, 'pull': 30, 'push': 20, 'recovery': 25},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 30,
      );
      final result = engine.analyze(poseMetrics: metrics);
      expect(result.bodyAngle, 175);
      expect(result.strokeRate, 45);
      expect(result.strokeLength, closeTo(2.1, 0.01));
      expect(result.strokeIndex, closeTo(94.5, 0.1));
      expect(result.coordinationIndex, closeTo(5.2, 0.1));
      expect(result.bodyRollAngle, 42);
      expect(result.symmetryScore, 85);
    });

    test('pose metrics calculate stroke index from SR and SL', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 170,
        bodyRollAngle: 45,
        rollSymmetry: 90,
        headLift: 10,
        strokeRate: 60,
        strokeLength: 1.5,
        strokeIndex: 90,
        coordinationIndex: 0,
        handVelocity: 3.0,
        propulsiveDrag: 70,
        strouhalNumber: 0.3,
        kickFrequency: 40,
        kickAmplitude: 20,
        symmetryScore: 80,
        phaseDuration: {},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 10,
      );
      final result = engine.analyze(poseMetrics: metrics);
      expect(result.strokeRate, 60);
      expect(result.strokeLength, 1.5);
    });
  });

  group('scientific references', () {
    test('includes BMS XI reference always', () {
      final result = engine.analyze();
      expect(result.scientificReferences,
          anyElement(contains('Biomechanics and Medicine in Swimming XI')));
    });

    test('includes Taormina reference when SR > 0', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 170,
        bodyRollAngle: 45,
        rollSymmetry: 90,
        headLift: 10,
        strokeRate: 35,
        strokeLength: 2.0,
        strokeIndex: 70,
        coordinationIndex: 0,
        handVelocity: 3.0,
        propulsiveDrag: 70,
        strouhalNumber: 0.3,
        kickFrequency: 40,
        kickAmplitude: 20,
        symmetryScore: 80,
        phaseDuration: {},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 10,
      );
      final result = engine.analyze(poseMetrics: metrics);
      expect(result.scientificReferences,
          anyElement(contains('Swim Speed Strokes')));
    });
  });

  group('warnings', () {
    test('generates body angle warning when low', () {
      final result = engine.analyze(estimatedBodyAngle: 165);
      expect(result.warnings, anyElement(contains('زاوية الجسم')));
    });

    test('generates SR warning when very high', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 170,
        bodyRollAngle: 45,
        rollSymmetry: 90,
        headLift: 10,
        strokeRate: 65,
        strokeLength: 1.5,
        strokeIndex: 97.5,
        coordinationIndex: 0,
        handVelocity: 3.0,
        propulsiveDrag: 70,
        strouhalNumber: 0.3,
        kickFrequency: 50,
        kickAmplitude: 20,
        symmetryScore: 80,
        phaseDuration: {},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 10,
      );
      final result = engine.analyze(poseMetrics: metrics);
      expect(result.warnings, anyElement(contains('تردد الضربات')));
    });

    test('generates SL warning when very short', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 170,
        bodyRollAngle: 45,
        rollSymmetry: 90,
        headLift: 10,
        strokeRate: 30,
        strokeLength: 1.0,
        strokeIndex: 30,
        coordinationIndex: 0,
        handVelocity: 3.0,
        propulsiveDrag: 70,
        strouhalNumber: 0.3,
        kickFrequency: 40,
        kickAmplitude: 20,
        symmetryScore: 80,
        phaseDuration: {},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 10,
      );
      final result = engine.analyze(poseMetrics: metrics);
      expect(result.warnings, anyElement(contains('طول الشدة')));
    });

    test('generates head lift warning when high', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 170,
        bodyRollAngle: 45,
        rollSymmetry: 90,
        headLift: 25,
        strokeRate: 35,
        strokeLength: 2.0,
        strokeIndex: 70,
        coordinationIndex: 0,
        handVelocity: 3.0,
        propulsiveDrag: 70,
        strouhalNumber: 0.3,
        kickFrequency: 40,
        kickAmplitude: 20,
        symmetryScore: 80,
        phaseDuration: {},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 10,
      );
      final result = engine.analyze(poseMetrics: metrics);
      expect(result.warnings, anyElement(contains('ارتفاع الرأس')));
    });
  });
}
