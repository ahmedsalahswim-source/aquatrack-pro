import 'package:flutter_test/flutter_test.dart';
import 'package:aquatrack_pro/features/competition_intelligence/domain/usecases/performance_analyzer.dart';
import 'package:aquatrack_pro/features/competition_intelligence/domain/entities/race_result.dart';
import 'package:aquatrack_pro/features/competition_intelligence/data/repositories/world_records_repository.dart';
import 'package:aquatrack_pro/features/competition_intelligence/data/repositories/championship_repository.dart';
import 'package:aquatrack_pro/features/fitness_intelligence/domain/entities/digital_twin.dart';

void main() {
  group('PerformanceAnalyzer Tests', () {
    late WorldRecordsRepository mockRepo;
    late ChampionshipRepository champRepo;
    late PerformanceAnalyzer analyzer;

    setUp(() {
      mockRepo = WorldRecordsRepository();
      champRepo = ChampionshipRepository();
      analyzer = PerformanceAnalyzer(
        worldRecordsRepository: mockRepo,
        championshipRepository: champRepo,
      );
    });

    test('analyzePerformance returns improvement correctly', () {
      final currentRace = RaceResult(
        id: '1',
        competitionId: 'c1',
        athleteId: 'a1',
        eventName: '50m Freestyle',
        time: const Duration(seconds: 25, milliseconds: 500),
        position: 1,
        totalParticipants: 10,
      );

      final previousRace = RaceResult(
        id: '2',
        competitionId: 'c2',
        athleteId: 'a1',
        eventName: '50m Freestyle',
        time: const Duration(seconds: 26, milliseconds: 500),
        position: 2,
        totalParticipants: 10,
      );

      final twins = [
        AthleteDigitalTwin(
          athleteId: 'a1',
          lastUpdated: DateTime.now(),
          recoveryScore: 85.0,
          fitnessScore: 80.0,
          injuryRiskScore: 5.0,
          techniqueScore: 80.0,
          readinessScore: 90.0,
          nutritionScore: 80.0,
          overallScore: 85.0,
          currentWeaknesses: const [],
          activePainAreas: const [],
        )
      ];

      final report = analyzer.analyzePerformance(
        currentRace: currentRace,
        previousRace: previousRace,
        historicalTwins: twins,
        gender: 'male',
        poolType: '50m',
      );

      expect(report.timeDifference, -1.0); // Improved by 1 second
      expect(report.reasons.any((r) => r.contains('تحسن الأداء')), true);
    });
  });
}
