import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/login_page.dart';

class MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  late MockAuthBloc mockAuthBloc;

  setUp(() {
    mockAuthBloc = MockAuthBloc();
  });

  setUpAll(() {
    registerFallbackValue(const LoginEvent(email: '', password: ''));
    registerFallbackValue(const ForgotPasswordEvent(email: ''));
  });

  Widget createTestWidget({AuthState? state}) {
    when(() => mockAuthBloc.state).thenReturn(state ?? const AuthInitial());
    when(() => mockAuthBloc.stream).thenAnswer((_) => const Stream.empty());
    return BlocProvider<AuthBloc>.value(
      value: mockAuthBloc,
      child: MaterialApp(
        home: Provider<AppLocalizations>.value(
          value: AppLocalizations(const Locale('en')),
          child: const LoginPage(),
        ),
      ),
    );
  }

  testWidgets('renders email and password fields', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('shows validation errors on empty submit', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('البريد الإلكتروني مطلوب'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
  });

  testWidgets('calls AuthBloc on login button press with valid input', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextFormField).first, 'test@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'password123');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Login'));
    await tester.pumpAndSettle();

    verify(() => mockAuthBloc.add(any<LoginEvent>())).called(1);
  });

  testWidgets('shows forgot password dialog', (tester) async {
    await tester.pumpWidget(createTestWidget());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Forgot Password?'));
    await tester.pumpAndSettle();

    expect(find.text('Send Reset Link'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('shows error message from AuthError state', (tester) async {
    const errorMessage = 'Invalid credentials';
    await tester.pumpWidget(createTestWidget(state: const AuthError(message: errorMessage)));
    await tester.pumpAndSettle();

    expect(find.text(errorMessage), findsOneWidget);
  });
}
