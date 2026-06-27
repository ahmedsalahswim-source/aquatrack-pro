import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/dashboard/domain/entities/dashboard_data.dart';
import 'package:aquatrack_pro/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

final testAthlete = AthleteEntity(
  id: 'athlete_1',
  parentId: 'parent_1',
  name: 'Test Athlete',
  birthDate: DateTime(2010, 1, 1),
  gender: Gender.male,
  swimLevel: SwimLevel.competitive,
  restingHRBaseline: 60,
  createdAt: DateTime(2026, 1, 1),
);

final testLog = DailyLogEntity(
  id: 'log_1',
  athleteId: 'athlete_1',
  date: '2026-06-12',
  sleepHours: 8.0,
  restingHR: 60,
  wellnessScore: 7,
  createdAt: DateTime(2026, 6, 12),
);

final testDashboardData = DashboardData(
  athlete: testAthlete,
  todayLog: testLog,
  stressScore: 25,
  acwr: 1.0,
  hasTodayLog: true,
  recentLogs: [testLog],
);

void main() {
  late DashboardRepository repository;

  setUpAll(() {
    registerFallbackValue(AthleteEntity(
      id: '', parentId: '', name: '',
      birthDate: DateTime(2000), gender: Gender.male,
      createdAt: DateTime(2026),
    ));
  });

  setUp(() {
    repository = MockDashboardRepository();
    when(() => repository.watchDashboard(any())).thenAnswer(
      (_) => Stream.value(Right(testDashboardData)),
    );
  });

  group('DashboardBloc', () {
    blocTest<DashboardBloc, DashboardState>(
      'emits loading then loaded on LoadDashboardEvent',
      build: () => DashboardBloc(dashboardRepository: repository),
      act: (bloc) => bloc.add(LoadDashboardEvent(athlete: testAthlete)),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>().having((s) => s.stressScore, 'stress', 25),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<DashboardBloc, DashboardState>(
      'emits error on repository failure',
      build: () {
        when(() => repository.watchDashboard(any())).thenAnswer(
          (_) => Stream.value(const Left(ServerFailure(message: 'Fail'))),
        );
        return DashboardBloc(dashboardRepository: repository);
      },
      act: (bloc) => bloc.add(LoadDashboardEvent(athlete: testAthlete)),
      expect: () => [
        const DashboardLoading(),
        isA<DashboardError>().having((s) => s.message, 'msg', 'Fail'),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<DashboardBloc, DashboardState>(
      'refreshes on RefreshDashboardEvent',
      build: () => DashboardBloc(dashboardRepository: repository),
      act: (bloc) {
        bloc.add(LoadDashboardEvent(athlete: testAthlete));
        bloc.add(const RefreshDashboardEvent());
      },
      expect: () => [
        const DashboardLoading(),
        isA<DashboardLoaded>().having((s) => s.athlete.id, 'id', 'athlete_1'),
        const DashboardLoading(),
        isA<DashboardLoaded>().having((s) => s.athlete.id, 'id', 'athlete_1'),
      ],
      wait: const Duration(milliseconds: 200),
    );

    blocTest<DashboardBloc, DashboardState>(
      'switches athlete on SelectAthleteEvent',
      build: () => DashboardBloc(dashboardRepository: repository),
      act: (bloc) => bloc.add(SelectAthleteEvent(athlete: testAthlete)),
      expect: () => [
        isA<DashboardLoaded>().having((s) => s.athlete.id, 'id', 'athlete_1'),
      ],
      wait: const Duration(milliseconds: 100),
    );
  });
}
