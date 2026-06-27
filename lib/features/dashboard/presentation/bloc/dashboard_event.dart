part of 'dashboard_bloc.dart';

abstract class DashboardEvent extends Equatable {
  const DashboardEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardEvent extends DashboardEvent {
  final AthleteEntity athlete;
  const LoadDashboardEvent({required this.athlete});
  @override
  List<Object?> get props => [athlete];
}

class SelectAthleteEvent extends DashboardEvent {
  final AthleteEntity athlete;
  const SelectAthleteEvent({required this.athlete});
  @override
  List<Object?> get props => [athlete];
}

class RefreshDashboardEvent extends DashboardEvent {
  const RefreshDashboardEvent();
}
