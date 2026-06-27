import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:aquatrack_pro/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';

part 'dashboard_event.dart';
part 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final DashboardRepository dashboardRepository;

  DashboardBloc({required this.dashboardRepository})
      : super(const DashboardInitial()) {
    on<LoadDashboardEvent>(_onLoad);
    on<SelectAthleteEvent>(_onSelectAthlete);
    on<RefreshDashboardEvent>(_onRefresh);
  }

  Future<void> _subscribe(AthleteEntity athlete, Emitter<DashboardState> emit, {bool showLoading = true}) {
    if (showLoading) emit(const DashboardLoading());
    return emit.forEach(
      dashboardRepository.watchDashboard(athlete),
      onData: (result) => result.fold(
        (failure) => DashboardError(message: failure.message),
        (data) => DashboardLoaded(
          athlete: data.athlete,
          todayLog: data.todayLog,
          stressScore: data.stressScore,
          acwr: data.acwr,
          hasTodayLog: data.hasTodayLog,
          recentLogs: data.recentLogs,
          readinessScore: data.readinessScore,
        ),
      ),
      onError: (e, _) => DashboardError(message: 'خطأ في تحميل البيانات: $e'),
    );
  }

  Future<void> _onLoad(LoadDashboardEvent event, Emitter<DashboardState> emit) {
    return _subscribe(event.athlete, emit);
  }

  Future<void> _onSelectAthlete(SelectAthleteEvent event, Emitter<DashboardState> emit) {
    return _subscribe(event.athlete, emit, showLoading: false);
  }

  Future<void> _onRefresh(RefreshDashboardEvent event, Emitter<DashboardState> emit) {
    if (state is DashboardLoaded) {
      return _subscribe((state as DashboardLoaded).athlete, emit);
    }
    return Future.value();
  }
}
