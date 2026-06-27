import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';

class DashboardData extends Equatable {
  final AthleteEntity athlete;
  final DailyLogEntity? todayLog;
  final int stressScore;
  final double? acwr;
  final bool hasTodayLog;
  final List<DailyLogEntity> recentLogs;
  final int readinessScore;

  const DashboardData({
    required this.athlete,
    this.todayLog,
    this.stressScore = 0,
    this.acwr,
    this.hasTodayLog = false,
    this.recentLogs = const [],
    this.readinessScore = 0,
  });

  @override
  List<Object?> get props => [athlete, todayLog, stressScore, acwr, hasTodayLog, recentLogs, readinessScore];
}
