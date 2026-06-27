import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/core/services/universal_speed_dynamics_module.dart';

void main() {
  late UniversalSpeedDynamicsModule module;

  setUp(() {
    module = UniversalSpeedDynamicsModule();
  });

  group('UniversalSpeedDynamicsModule', () {
    test('returns insufficient_data for empty splits', () {
      final result = module.analyzeRace(totalDistance: 50.0, cumulativeSplits: []);
      expect(result.classification, 'insufficient_data');
      expect(result.metrics.maxSpeed, 0.0);
      expect(result.segments.isEmpty, true);
    });

    test('analyzes 50m stable pacer race correctly', () {
      // 5 segments of 10m
      // times: 10m: 6.0, 20m: 12.0, 30m: 18.0, 40m: 24.0, 50m: 30.0
      // speeds: 10/6=1.66, 10/6=1.66, etc.
      final result = module.analyzeRace(
        totalDistance: 50.0,
        cumulativeSplits: [6.0, 12.0, 18.0, 24.0, 30.0],
      );

      expect(result.segmentSizeM, 10.0);
      expect(result.segments.length, 5);
      expect(result.segments.first.range, '0-10m');
      expect(result.segments.first.time, 6.0);
      expect(result.segments.first.speed, closeTo(1.67, 0.01));
      
      expect(result.classification, 'stable_pacer');
      expect(result.insights.first, contains('مستقر'));
    });

    test('analyzes positive split correctly', () {
      // speeds up towards the end
      // segment times: 8.0, 7.0, 6.0, 5.0, 4.0
      // cumulative: 8.0, 15.0, 21.0, 26.0, 30.0
      final result = module.analyzeRace(
        totalDistance: 50.0,
        cumulativeSplits: [8.0, 15.0, 21.0, 26.0, 30.0],
      );

      expect(result.classification, 'positive_split');
    });

    test('analyzes sprint drop correctly', () {
      // Fast start, sharp drop
      // times: 4.0, 7.0, 8.0, 8.5, 9.0
      // cumulative: 4.0, 11.0, 19.0, 27.5, 36.5
      // speed: 2.5, 1.42, 1.25, 1.17, 1.11
      final result = module.analyzeRace(
        totalDistance: 50.0,
        cumulativeSplits: [4.0, 11.0, 19.0, 27.5, 36.5],
      );

      expect(result.classification, 'sprint_drop');
    });

    test('analyzes negative split fatigue correctly', () {
      // Steady start, then gradual drop
      // times: 6.0, 6.0, 6.5, 7.5, 9.0
      // cumulative: 6.0, 12.0, 18.5, 26.0, 35.0
      final result = module.analyzeRace(
        totalDistance: 50.0,
        cumulativeSplits: [6.0, 12.0, 18.5, 26.0, 35.0],
      );

      expect(result.classification, 'negative_split_fatigue');
    });

    test('outputs STRICT JSON format', () {
      final result = module.analyzeRace(
        totalDistance: 50.0,
        cumulativeSplits: [6.0, 12.0, 18.0, 24.0, 30.0],
      );

      final json = result.toJson();
      expect(json, contains('universal_speed_analysis'));
      final u = json['universal_speed_analysis'];
      expect(u['segment_size_m'], 10.0);
      expect(u['segments'], isA<List>());
      expect(u['metrics'], isA<Map>());
      expect(u['classification'], 'stable_pacer');
      expect(u['insights'], isA<List<String>>());
      
      final firstSegment = u['segments'][0];
      expect(firstSegment['range'], '0-10m');
      expect(firstSegment['time'], 6.0);
      expect(firstSegment['speed_change_percent'], 0.0);
    });
  });
}
