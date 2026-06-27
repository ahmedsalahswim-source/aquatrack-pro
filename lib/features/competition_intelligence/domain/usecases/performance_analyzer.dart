import '../entities/race_result.dart';
import '../../../fitness_intelligence/domain/entities/digital_twin.dart';
import '../../data/repositories/world_records_repository.dart';
import '../../data/repositories/championship_repository.dart';

class PerformanceAnalysisReport {
  final RaceResult result;
  final double timeDifference; // Negative means improvement
  final List<String> reasons;
  final List<String> nextSteps;
  final WorldRecord? globalBenchmark;
  final String standardLevel;
  final LocalRecord? localBenchmark;
  final double? timeDiffToLocal;

  const PerformanceAnalysisReport({
    required this.result,
    required this.timeDifference,
    required this.reasons,
    required this.nextSteps,
    this.globalBenchmark,
    this.standardLevel = 'Unknown',
    this.localBenchmark,
    this.timeDiffToLocal,
  });
}

class PerformanceAnalyzer {
  final WorldRecordsRepository worldRecordsRepository;
  final ChampionshipRepository championshipRepository;

  PerformanceAnalyzer({
    required this.worldRecordsRepository,
    required this.championshipRepository,
  });

  /// Analyzes how the athlete's Readiness and Daily Logs affected their race result.
  PerformanceAnalysisReport analyzePerformance({
    required RaceResult currentRace,
    required RaceResult previousRace,
    required List<AthleteDigitalTwin> historicalTwins, // Represents past 8 weeks
    required String gender,
    required String poolType,
  }) {
    double timeDiff = currentRace.time.inMilliseconds - previousRace.time.inMilliseconds.toDouble();
    timeDiff = timeDiff / 1000.0; // convert to seconds
    
    List<String> reasons = [];
    List<String> nextSteps = [];

    // Analyze the trend over the historical twins
    if (historicalTwins.isNotEmpty) {
      double avgReadiness = historicalTwins.map((t) => t.readinessScore).reduce((a, b) => a + b) / historicalTwins.length;
      double avgRecovery = historicalTwins.map((t) => t.recoveryScore).reduce((a, b) => a + b) / historicalTwins.length;
      
      if (timeDiff < 0) {
        // Improvement
        reasons.add('تحسن الأداء بمقدار ${timeDiff.abs().toStringAsFixed(2)} ثانية.');
        if (avgRecovery > 80) {
          reasons.add('ارتبط ذلك بتحسن ملحوظ في جودة النوم والاستشفاء (Recovery Score > 80).');
          nextSteps.add('استمر في نفس روتين النوم والتغذية الحالي.');
        }
        if (avgReadiness > 85) {
          reasons.add('الجاهزية البدنية (Readiness) كانت ممتازة ومستقرة.');
          nextSteps.add('يمكن زيادة الحمل التدريبي بنسبة 10% للموسم القادم بثقة.');
        }
      } else if (timeDiff > 0) {
        // Decline
        reasons.add('تراجع الأداء بمقدار ${timeDiff.toStringAsFixed(2)} ثانية.');
        if (avgRecovery < 60) {
          reasons.add('يعود ذلك بشكل أساسي إلى ضعف الاستشفاء وقلة النوم في الأسابيع الماضية.');
          nextSteps.add('يجب إعطاء الأولوية للنوم وتخفيض حمل التدريب فوراً.');
        }
      } else {
        reasons.add('مستوى الأداء ثابت.');
      }
    }
    
    // Evaluate against Global Standards
    final wr = worldRecordsRepository.getRecordForEvent(currentRace.eventName, poolType, gender);
    String standard = 'Unknown';
    if (wr != null) {
      standard = worldRecordsRepository.evaluateTimeStandard(currentRace.time.inMilliseconds / 1000.0, wr);
    }
    
    // Evaluate against Local Championship Records
    final localRecord = championshipRepository.getLocalRecord(currentRace.eventName, gender);
    double? diffToLocal;
    if (localRecord != null) {
      diffToLocal = (currentRace.time.inMilliseconds / 1000.0) - localRecord.timeSeconds;
    }

    return PerformanceAnalysisReport(
      result: currentRace,
      timeDifference: timeDiff,
      reasons: reasons,
      nextSteps: nextSteps,
      globalBenchmark: wr,
      standardLevel: standard,
      localBenchmark: localRecord,
      timeDiffToLocal: diffToLocal,
    );
  }
}
