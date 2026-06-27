import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/athletes_tab.dart';
import 'package:aquatrack_pro/features/athlete/presentation/widgets/athlete_card.dart';
import 'test_helpers.dart';

class MockAthleteBloc extends MockBloc<AthleteEvent, AthleteState> implements AthleteBloc {}

class FakeAthleteEvent extends Fake implements AthleteEvent {}
class FakeAthleteState extends Fake implements AthleteState {}

void main() {
  late MockAthleteBloc mockAthleteBloc;

  setUpAll(() {
    registerFallbackValue(FakeAthleteEvent());
    registerFallbackValue(FakeAthleteState());
  });

  setUp(() {
    mockAthleteBloc = MockAthleteBloc();
  });

  Widget createTestWidget() {
    return wrapWithMaterialApp(
      Scaffold(
        body: BlocProvider<AthleteBloc>.value(
          value: mockAthleteBloc,
          child: const AthletesTab(parentId: 'p1'),
        ),
      ),
    );
  }

  testWidgets('renders loading state initially', (tester) async {
    when(() => mockAthleteBloc.state).thenReturn(AthleteLoading());

    await tester.pumpWidget(createTestWidget());
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('renders empty state when no athletes', (tester) async {
    when(() => mockAthleteBloc.state).thenReturn(const AthletesLoaded(athletes: []));

    await tester.pumpWidget(createTestWidget());
    expect(find.text('🏊'), findsOneWidget);
  });

  testWidgets('renders athletes list', (tester) async {
    final athlete = AthleteEntity(
      id: '1',
      parentId: 'p1',
      name: 'Ahmed',
      birthDate: DateTime(2010, 6, 15),
      gender: Gender.male,
      createdAt: DateTime(2026),
    );

    when(() => mockAthleteBloc.state).thenReturn(AthletesLoaded(athletes: [athlete], selectedAthlete: athlete));

    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();
    
    expect(find.byType(ListView), findsOneWidget);
    expect(find.byType(AthleteCard), findsOneWidget);
    expect(find.text('Ahmed'), findsOneWidget);
  });

  testWidgets('renders error state and retry button', (tester) async {
    when(() => mockAthleteBloc.state).thenReturn(const AthleteError('Error fetching data'));

    await tester.pumpWidget(createTestWidget());
    
    expect(find.text('Error fetching data'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
