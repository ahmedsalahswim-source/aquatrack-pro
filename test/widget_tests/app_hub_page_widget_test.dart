import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:provider/provider.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/pages/app_hub_page.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aquatrack_pro/core/services/app_preferences.dart';
import 'package:aquatrack_pro/injection_container.dart' show sl;
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_bloc.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_event.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_state.dart';

import 'test_helpers.dart';

class MockAthleteBloc extends MockBloc<AthleteEvent, AthleteState> implements AthleteBloc {}
class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}
class MockDashboardBloc extends MockBloc<DashboardEvent, DashboardState> implements DashboardBloc {}
class MockAiBloc extends MockBloc<AiEvent, AiState> implements AiBloc {}

class MockAppPreferences extends Mock implements AppPreferences {
  @override
  bool get isDark => false;
  @override
  bool get isArabic => false;
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}

class FakeAthleteEvent extends Fake implements AthleteEvent {}
class FakeAthleteState extends Fake implements AthleteState {}
class FakeAuthEvent extends Fake implements AuthEvent {}
class FakeAuthState extends Fake implements AuthState {}
class FakeDashboardEvent extends Fake implements DashboardEvent {}
class FakeDashboardState extends Fake implements DashboardState {}

void main() {
  group('AppHubPage Widget Tests', () {
    late UserEntity user;
    late MockAthleteBloc athleteBloc;
    late MockAuthBloc authBloc;
    late MockDashboardBloc dashboardBloc;
    late MockAiBloc aiBloc;
    late MockAppPreferences appPreferences;

    setUpAll(() {
      registerFallbackValue(FakeAthleteEvent());
      registerFallbackValue(FakeAthleteState());
      registerFallbackValue(FakeAuthEvent());
      registerFallbackValue(FakeAuthState());
      registerFallbackValue(FakeDashboardEvent());
      registerFallbackValue(FakeDashboardState());
    });

    setUp(() {
      user = UserEntity(
        uid: 'test_user_id',
        email: 'test@example.com',
        displayName: 'Test User',
        createdAt: DateTime(2023),
      );
      athleteBloc = MockAthleteBloc();
      authBloc = MockAuthBloc();
      dashboardBloc = MockDashboardBloc();
      aiBloc = MockAiBloc();
      appPreferences = MockAppPreferences();
      
      when(() => athleteBloc.state).thenReturn(const AthletesLoaded(athletes: [], selectedAthlete: null));
      when(() => authBloc.state).thenReturn(const AuthInitial());
      when(() => authBloc.stream).thenAnswer((_) => const Stream.empty());
      when(() => dashboardBloc.state).thenReturn(const DashboardInitial());

      sl.allowReassignment = true;
      if (sl.isRegistered<AiBloc>()) {
        sl.unregister<AiBloc>();
      }
      sl.registerFactory<AiBloc>(() => aiBloc);
    });

    Widget createTestWidget() {
      return wrapWithMaterialApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AppPreferences>.value(value: appPreferences),
          ],
          child: MultiBlocProvider(
            providers: [
              BlocProvider<AthleteBloc>.value(value: athleteBloc),
              BlocProvider<AuthBloc>.value(value: authBloc),
              BlocProvider<DashboardBloc>.value(value: dashboardBloc),
            ],
            child: AppHubPage(user: user),
          ),
        ),
      );
    }

    testWidgets('Renders BottomNavigationBar with 4 items', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // Verify BottomNavigationBar exists
      expect(find.byType(BottomNavigationBar), findsOneWidget);

      // Verify the 4 tabs exist (we can find the icons)
      expect(find.byIcon(Icons.home), findsOneWidget);
      expect(find.byIcon(Icons.people_outlined), findsOneWidget);
      expect(find.byIcon(Icons.smart_toy_outlined), findsOneWidget);
      expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    });

    testWidgets('Tapping tab changes index', (WidgetTester tester) async {
      await tester.pumpWidget(createTestWidget());

      // We are initially on the Dashboard tab.
      // We will tap the Athletes tab.
      await tester.tap(find.byIcon(Icons.people_outlined));
      await tester.pumpAndSettle();

      // Ensure the navigation bar reacted.
      final navBar = tester.widget<BottomNavigationBar>(find.byType(BottomNavigationBar));
      expect(navBar.currentIndex, 1);
    });
  });
}
