import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/pages/app_hub_page.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';

import 'test_helpers.dart';

// Mock AthleteBloc
class MockAthleteBloc extends Bloc<AthleteEvent, AthleteState> {
  MockAthleteBloc() : super(AthleteInitial()) {
    on<WatchAthletesEvent>((event, emit) {
      emit(AthletesLoaded(const [], null));
    });
  }
}

void main() {
  group('AppHubPage Widget Tests', () {
    late UserEntity user;
    late MockAthleteBloc athleteBloc;

    setUp(() {
      user = const UserEntity(
        uid: 'test_user_id',
        email: 'test@example.com',
        name: 'Test User',
      );
      athleteBloc = MockAthleteBloc();
    });

    testWidgets('Renders BottomNavigationBar with 4 items', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          BlocProvider<AthleteBloc>.value(
            value: athleteBloc,
            child: AppHubPage(user: user),
          ),
        ),
      );

      // Verify BottomNavigationBar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify the 4 tabs exist (we can find the icons)
      expect(find.byIcon(Icons.home_outlined), findsOneWidget);
      expect(find.byIcon(Icons.people_outlined), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Tapping tab changes index', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrapWithMaterialApp(
          BlocProvider<AthleteBloc>.value(
            value: athleteBloc,
            child: AppHubPage(user: user),
          ),
        ),
      );

      // We are initially on the Dashboard tab.
      // We will tap the Athletes tab.
      await tester.tap(find.byIcon(Icons.people_outlined));
      await tester.pumpAndSettle();

      // Ensure the navigation bar reacted.
      // (Testing the inner state of indexed stack is a bit more involved, but
      // tapping without errors is a good first check).
      final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, 1);
    });
  });
}
