import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/date_helpers.dart';
import 'package:aquatrack_pro/core/utils/helpers.dart';
import 'package:aquatrack_pro/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:aquatrack_pro/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  final DailyLogRepository dailyLogRepository;

  DashboardRepositoryImpl({required this.dailyLogRepository});

  @override
  Stream<Either<Failure, DashboardData>> watchDashboard(AthleteEntity athlete) {
    return dailyLogRepository.watchLogs(athlete.id).map((result) {
      return result.fold(
        (failure) => Left(failure),
        (logs) => Right(_buildDashboardData(athlete, logs)),
      );
    });
  }

  DashboardData _buildDashboardData(
    AthleteEntity athlete,
    List<DailyLogEntity> logs,
  ) {
    final today = DateHelpers.formatDate(DateTime.now());
    final todayLog = logs.where((l) => l.date == today).firstOrNull;
    final recentLogs = logs.take(30).toList();

    final stressScore = StressCalculator.calculate(
      sleepHours: todayLog?.sleepHours,
      recommendedSleep: DateHelpers.sleepRecommendationByAge(athlete.age).$1,
      restingHR: todayLog?.restingHR,
      baselineHR: athlete.restingHRBaseline,
      rpe: todayLog?.training?.rpe,
      wellnessScore: todayLog?.wellnessScore,
    );

    final acuteLoads = recentLogs
        .map((l) => (l.training?.trainingLoad ?? 0).toDouble())
        .where((v) => v > 0)
        .toList();
    List<double>? chronicLoads;
    if (logs.length > 7) {
      chronicLoads = logs
          .skip(7)
          .take(21)
          .map((l) => (l.training?.trainingLoad ?? 0).toDouble())
          .where((v) => v > 0)
          .toList();
    }
    final acwr = AcwrCalculator.calculate(
      acuteLoads: acuteLoads,
      chronicLoads: chronicLoads,
    );

    // Readiness Score (0 - 100)
    int readiness = 100;
    // Penalty for high stress
    readiness -= (stressScore * 0.5).toInt();
    // Penalty for low sleep
    final recSleep = DateHelpers.sleepRecommendationByAge(athlete.age).$1;
    final sleepH = todayLog?.sleepHours ?? recSleep;
    if (sleepH < recSleep) {
      readiness -= ((recSleep - sleepH) * 10).toInt();
    }
    // Penalty for bad ACWR
    if (acwr > 1.5) {
      readiness -= 20;
    } else if (acwr > 1.3) {
      readiness -= 10;
    } else if (acwr < 0.8 && acwr > 0) {
      readiness -= 5;
    }
    readiness = readiness.clamp(0, 100);

    return DashboardData(
      athlete: athlete,
      todayLog: todayLog,
      stressScore: stressScore,
      acwr: acwr,
      hasTodayLog: todayLog != null,
      recentLogs: recentLogs,
      readinessScore: readiness,
    );
  }
}
