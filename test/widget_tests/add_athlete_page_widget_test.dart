import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/athlete/domain/entities/athlete_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/features/athlete/presentation/pages/add_athlete_page.dart';
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
    when(() => mockAthleteBloc.state).thenReturn(const AthletesLoaded(athletes: []));
  });

  Widget createTestWidget({AthleteEntity? existingAthlete}) {
    return wrapWithMaterialApp(
      BlocProvider<AthleteBloc>.value(
        value: mockAthleteBloc,
        child: AddAthletePage(parentId: 'p1', existingAthlete: existingAthlete),
      ),
    );
  }

  testWidgets('renders add athlete form', (tester) async {
    await tester.pumpWidget(createTestWidget());
    
    // Check form fields
    expect(find.byType(TextFormField), findsWidgets);
    expect(find.text('👤'), findsOneWidget);
    expect(find.text('🏊'), findsOneWidget);
  });
  
  testWidgets('renders edit athlete form with data', (tester) async {
    final athlete = AthleteEntity(
      id: '1',
      parentId: 'p1',
      name: 'Ahmed',
      birthDate: DateTime(2010, 6, 15),
      gender: Gender.male,
      createdAt: DateTime(2026),
      weightKg: 65,
    );
    
    await tester.pumpWidget(createTestWidget(existingAthlete: athlete));
    
    expect(find.text('Ahmed'), findsOneWidget);
    expect(find.text('65.0'), findsOneWidget);
  });
}
