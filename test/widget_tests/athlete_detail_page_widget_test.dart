import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/athlete_detail_page.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/injection_container.dart' show sl;

import 'test_helpers.dart';

class MockDailyLogBloc extends MockBloc<DailyLogEvent, DailyLogState> implements DailyLogBloc {}
class MockDailyLogRepository extends Mock implements DailyLogRepository {}

class FakeDailyLogEvent extends Fake implements DailyLogEvent {}
class FakeDailyLogState extends Fake implements DailyLogState {}

void main() {
  group('AthleteDetailPage Widget Tests', () {
    late AthleteEntity athlete;
    late MockDailyLogBloc dailyLogBloc;
    late MockDailyLogRepository dailyLogRepository;

    setUpAll(() {
      registerFallbackValue(FakeDailyLogEvent());
      registerFallbackValue(FakeDailyLogState());
    });

    setUp(() {
      athlete = AthleteEntity(
        id: 'a1',
        parentId: 'p1',
        name: 'John Doe',
        birthDate: DateTime(2010, 1, 1),
        gender: Gender.male,
        swimLevel: SwimLevel.intermediate,
        targetWeeklyHours: 10,
        createdAt: DateTime.now(),
      );
      dailyLogBloc = MockDailyLogBloc();
      dailyLogRepository = MockDailyLogRepository();

      when(() => dailyLogBloc.state).thenReturn(const DailyLogState(
        currentStep: 0,
        athleteId: 'a1',
        athleteName: 'John Doe',
        athleteAge: 16,
      ));

      when(() => dailyLogRepository.getLogsInRange(any(), any()))
          .thenAnswer((_) async => const Right([]));

      sl.allowReassignment = true;
      if (sl.isRegistered<DailyLogRepository>()) {
        sl.unregister<DailyLogRepository>();
      }
      sl.registerFactory<DailyLogRepository>(() => dailyLogRepository);
    });

    testWidgets('Renders athlete details correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          BlocProvider<DailyLogBloc>.value(
            value: dailyLogBloc,
            child: AthleteDetailPage(athlete: athlete),
          ),
        ),
      );

      // Verify AppBar has athlete name
      expect(find.descendant(of: find.byType(AppBar), matching: find.text('John Doe')), findsOneWidget);

      // We might see a CircularProgressIndicator initially because of _loadRecentLogs
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
