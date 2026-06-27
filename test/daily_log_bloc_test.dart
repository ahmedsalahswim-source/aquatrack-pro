import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

class MockDailyLogRepository extends Mock implements DailyLogRepository {}

final testLog = DailyLogEntity(
  id: 'log_1',
  athleteId: 'athlete_1',
  date: '2026-06-12',
  sleepHours: 8.0,
  sleepQuality: SleepQuality.good,
  restingHR: 60,
  wellnessScore: 7,
  nutrition: const NutritionData(
    breakfast: true,
    lunch: true,
    hydrationLiters: 1.5,
    proteinSufficient: true,
  ),
  training: const TrainingData(
    trained: true,
    durationMinutes: 60,
    type: TrainingType.technique,
    rpe: 6,
    distanceMeters: 1500,
  ),
  createdAt: DateTime(2026, 6, 12),
);

void main() {
  late DailyLogRepository repository;

  setUpAll(() {
    registerFallbackValue(DailyLogEntity(
      id: 'fallback',
      athleteId: 'fallback',
      date: '2026-01-01',
      createdAt: DateTime(2026),
    ));
  });

  setUp(() {
    repository = MockDailyLogRepository();
    when(() => repository.watchLogs(any())).thenAnswer(
      (_) => Stream.value(Right([testLog])),
    );
    when(() => repository.getLogByDate(any(), any())).thenAnswer(
      (_) async => Right(testLog),
    );
    when(() => repository.getLogsInRange(any(), any())).thenAnswer(
      (_) async => const Right([]),
    );
    when(() => repository.saveLog(any())).thenAnswer(
      (_) async => Right(testLog),
    );
  });

  group('DailyLogBloc', () {
    blocTest<DailyLogBloc, DailyLogState>(
      'emits initialized state on InitLogEvent',
      build: () => DailyLogBloc(repository: repository),
      act: (bloc) => bloc.add(const InitLogEvent(
        athleteId: 'athlete_1',
        athleteName: 'Test Athlete',
        athleteAge: 16,
      )),
      expect: () => [
        isA<DailyLogState>().having(
          (s) => s.athleteName, 'athleteName', 'Test Athlete'),
      ],
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'loads existing log on CheckExistingLogEvent',
      build: () => DailyLogBloc(repository: repository),
      act: (bloc) {
        bloc.add(const InitLogEvent(
          athleteId: 'athlete_1', athleteName: 'Test Athlete', athleteAge: 16,
        ));
        bloc.add(const CheckExistingLogEvent(athleteId: 'athlete_1'));
      },
      expect: () => [
        isA<DailyLogState>().having((s) => s.athleteName, 'name', 'Test Athlete'),
        isA<DailyLogState>().having((s) => s.sleepHours, 'sleep', 8.0),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'saves log successfully and sets isSaved true',
      build: () => DailyLogBloc(repository: repository),
      act: (bloc) {
        bloc.add(const InitLogEvent(
          athleteId: 'athlete_1', athleteName: 'Test Athlete', athleteAge: 16,
        ));
        bloc.add(const SaveLogEvent());
      },
      expect: () => [
        isA<DailyLogState>().having((s) => s.athleteName, 'name', 'Test Athlete'),
        isA<DailyLogState>().having((s) => s.isSaving, 'saving', true),
        isA<DailyLogState>().having((s) => s.isSaved, 'saved', true),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<DailyLogBloc, DailyLogState>(
      'sets error when save fails',
      build: () {
        when(() => repository.saveLog(any())).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Save failed')),
        );
        return DailyLogBloc(repository: repository);
      },
      act: (bloc) {
        bloc.add(const InitLogEvent(
          athleteId: 'athlete_1', athleteName: 'Test Athlete', athleteAge: 16,
        ));
        bloc.add(const SaveLogEvent());
      },
      expect: () => [
        isA<DailyLogState>().having((s) => s.athleteName, 'name', 'Test Athlete'),
        isA<DailyLogState>().having((s) => s.isSaving, 'saving', true),
        isA<DailyLogState>().having((s) => s.error, 'error', isNotNull),
      ],
      wait: const Duration(milliseconds: 100),
    );
  });
}
