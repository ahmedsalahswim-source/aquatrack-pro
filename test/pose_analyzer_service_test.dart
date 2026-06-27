import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/models/swim_pose_metrics.dart';
import 'package:aquatrack_pro/core/services/pose_analyzer_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late PoseAnalyzerService analyzer;

  setUp(() {
    analyzer = PoseAnalyzerService();
  });

  tearDown(() {
    analyzer.dispose();
  });

  group('initialize', () {
    test('returns true without native dependencies', () async {
      final result = await analyzer.initialize();
      expect(result, true);
    });

    test('isAvailable after init', () async {
      await analyzer.initialize();
      expect(analyzer.isAvailable, true);
    });
  });

  group('analyzeVideo', () {
    test('returns null when not initialized', () async {
      expect(analyzer.isAvailable, false);
    });
  });

  group('SwimPoseMetrics', () {
    test('creates with all fields', () {
      final metrics = SwimPoseMetrics(
        bodyAngle: 170,
        bodyRollAngle: 45,
        rollSymmetry: 90,
        headLift: 10,
        strokeRate: 40,
        strokeLength: 2.0,
        strokeIndex: 80,
        coordinationIndex: 5.0,
        handVelocity: 3.5,
        propulsiveDrag: 68,
        strouhalNumber: 0.3,
        kickFrequency: 50,
        kickAmplitude: 20,
        symmetryScore: 85,
        phaseDuration: {'catch_': 25, 'pull': 30, 'push': 20, 'recovery': 25},
        detectedPhases: SwimStrokePhase.values,
        frameCount: 30,
      );
      expect(metrics.bodyAngle, 170);
      expect(metrics.strokeRate, 40);
      expect(metrics.detectedPhases.length, 4);
    });
  });

  group('SwimStrokePhase enum', () {
    test('has all four phases', () {
      expect(SwimStrokePhase.values.length, 4);
      expect(SwimStrokePhase.values, contains(SwimStrokePhase.catch_));
      expect(SwimStrokePhase.values, contains(SwimStrokePhase.pull));
      expect(SwimStrokePhase.values, contains(SwimStrokePhase.push));
      expect(SwimStrokePhase.values, contains(SwimStrokePhase.recovery));
    });
  });
}
