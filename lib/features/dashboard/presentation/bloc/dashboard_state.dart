part of 'dashboard_bloc.dart';

abstract class DashboardState extends Equatable {
  const DashboardState();
  @override
  List<Object?> get props => [];
}

class DashboardInitial extends DashboardState {
  const DashboardInitial();
}

class DashboardLoading extends DashboardState {
  const DashboardLoading();
}

class DashboardLoaded extends DashboardState {
  final AthleteEntity athlete;
  final DailyLogEntity? todayLog;
  final int stressScore;
  final double? acwr;
  final bool hasTodayLog;
  final List<DailyLogEntity> recentLogs;
  final int readinessScore;

  const DashboardLoaded({
    required this.athlete,
    this.todayLog,
    this.stressScore = 0,
    this.acwr,
    this.hasTodayLog = false,
    this.recentLogs = const [],
    this.readinessScore = 0,
  });

  @override
  List<Object?> get props => [athlete.id, stressScore, hasTodayLog, readinessScore];
}

class DashboardError extends DashboardState {
  final String message;
  const DashboardError({required this.message});
  @override
  List<Object?> get props => [message];
}
