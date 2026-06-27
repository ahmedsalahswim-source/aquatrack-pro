import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:aquatrack_pro/features/daily_log/domain/entities/daily_log_entity.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/widgets/step_training.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class MockDailyLogBloc extends MockBloc<DailyLogEvent, DailyLogState> implements DailyLogBloc {}
class FakeUpdateTrainingStep extends Fake implements UpdateTrainingStep {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeUpdateTrainingStep());
  });
  late MockDailyLogBloc mockDailyLogBloc;

  setUp(() {
    mockDailyLogBloc = MockDailyLogBloc();
  });

  Widget createTestWidget({DailyLogState? state}) {
    when(() => mockDailyLogBloc.state).thenReturn(state ?? const DailyLogState(currentStep: 0, athleteId: 'a1', athleteName: 'John Doe'));
    when(() => mockDailyLogBloc.stream).thenAnswer((_) => const Stream.empty());

    return MultiProvider(
      providers: [
        Provider<AppLocalizations>.value(value: AppLocalizations(const Locale('en'))),
      ],
      child: BlocProvider<DailyLogBloc>.value(
        value: mockDailyLogBloc,
        child: const MaterialApp(
          home: Scaffold(body: StepTraining(athleteName: 'John Doe')),
        ),
      ),
    );
  }

  testWidgets('renders training toggle buttons', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text("Did John Doe train today?"), findsOneWidget);
    expect(find.text('Trained'), findsOneWidget);
    expect(find.text('Did not train'), findsOneWidget);
  });

  testWidgets('renders training details when trained is true', (tester) async {
    await tester.pumpWidget(createTestWidget(
      state: const DailyLogState(
        currentStep: 0,
        athleteId: 'a1',
        athleteName: 'John Doe',
        training: TrainingData(
          trained: true,
          type: TrainingType.technique,
          durationMinutes: 60,
          distanceMeters: 2000,
          rpe: 6,
        ),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Training Type'), findsOneWidget);
    expect(find.text('Technique'), findsOneWidget);
    expect(find.text('Endurance'), findsOneWidget);
    expect(find.text('Sprint'), findsOneWidget);
    expect(find.text('Dryland'), findsOneWidget);

    expect(find.text('Training Duration'), findsOneWidget);
    expect(find.text('60 min'), findsOneWidget);

    expect(find.text('Rate of Perceived Exertion'), findsOneWidget);
    expect(find.text('Moderate'), findsOneWidget);
    expect(find.text('6'), findsOneWidget);
  });

  testWidgets('triggers UpdateTrainingStep event on toggle', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Trained'));
    await tester.pumpAndSettle();

    verify(() => mockDailyLogBloc.add(any<UpdateTrainingStep>())).called(1);
  });
}
