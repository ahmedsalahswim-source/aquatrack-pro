import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/services/app_preferences.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/settings_tab.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

class MockAppPreferences extends Mock implements AppPreferences {
  bool _isDark = false;
  bool _isArabic = true;

  @override
  bool get isDark => _isDark;

  @override
  bool get isArabic => _isArabic;

  @override
  Future<void> toggleTheme() async {
    _isDark = !_isDark;
  }

  @override
  Future<void> toggleLocale() async {
    _isArabic = !_isArabic;
  }

  @override
  void addListener(VoidCallback listener) {}
  
  @override
  void removeListener(VoidCallback listener) {}
}

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockAppPreferences mockAppPreferences;

  final testUser = UserEntity(
    uid: 'user123',
    email: 'test@test.com',
    displayName: 'Test User',
    createdAt: DateTime.now(),
    role: UserRole.coach,
    subscriptionPlan: SubscriptionPlan.pro,
    athleteIds: const ['a1', 'a2'],
  );

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockAppPreferences = MockAppPreferences();
    when(() => mockAuthBloc.state).thenReturn(const AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
  });

  Widget createTestWidget() {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AppPreferences>.value(value: mockAppPreferences),
        Provider<AppLocalizations>.value(value: AppLocalizations(const Locale('en'))),
      ],
      child: BlocProvider<AuthBloc>.value(
        value: mockAuthBloc,
        child: MaterialApp(
          home: Scaffold(body: SettingsTab(user: testUser)),
        ),
      ),
    );
  }

  testWidgets('renders user info correctly', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Test User'), findsOneWidget);
    expect(find.text('test@test.com'), findsOneWidget);
    expect(find.text('T'), findsOneWidget); // First letter of display name
    expect(find.text('Pro'), findsNWidgets(2)); // Pro account label & badge
  });

  testWidgets('renders setting sections', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Account Type'), findsOneWidget);
    expect(find.text('Athlete Count'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    
    // Scroll to see bottom sections
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    expect(find.text('Version'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
  });

  testWidgets('shows logout confirmation dialog', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Logout'));
    await tester.pumpAndSettle();

    expect(find.text('Are you sure you want to logout?'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    
    await tester.tap(find.descendant(
      of: find.byType(TextButton),
      matching: find.text('Logout'),
    ));
    await tester.pumpAndSettle();

    verify(() => mockAuthBloc.add(const LogoutEvent())).called(1);
  });
}
