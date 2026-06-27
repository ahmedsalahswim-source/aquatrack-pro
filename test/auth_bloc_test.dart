import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:dartz/dartz.dart';
import 'package:aquatrack_pro/core/errors/failures.dart';
import 'package:aquatrack_pro/core/utils/enums.dart';
import 'package:aquatrack_pro/features/auth/domain/entities/user_entity.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/login_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/register_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/update_consent_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockGoogleSignInUseCase extends Mock implements GoogleSignInUseCase {}
class MockLogoutUseCase extends Mock implements LogoutUseCase {}
class MockGetCurrentUserUseCase extends Mock implements GetCurrentUserUseCase {}
class MockUpdateConsentUseCase extends Mock implements UpdateConsentUseCase {}
class MockForgotPasswordUseCase extends Mock implements ForgotPasswordUseCase {}

final consentedUser = UserEntity(
  uid: 'u1', email: 'a@b.com', displayName: 'A',
  role: UserRole.parent, hasConsented: true,
  createdAt: DateTime(2026),
);

final unconsentedUser = UserEntity(
  uid: 'u2', email: 'b@c.com', displayName: 'B',
  role: UserRole.parent, hasConsented: false,
  createdAt: DateTime(2026),
);

void main() {
  late LoginUseCase loginUseCase;
  late RegisterUseCase registerUseCase;
  late GoogleSignInUseCase googleSignInUseCase;
  late LogoutUseCase logoutUseCase;
  late GetCurrentUserUseCase getCurrentUserUseCase;
  late UpdateConsentUseCase updateConsentUseCase;
  late ForgotPasswordUseCase forgotPasswordUseCase;

  setUp(() {
    loginUseCase = MockLoginUseCase();
    registerUseCase = MockRegisterUseCase();
    googleSignInUseCase = MockGoogleSignInUseCase();
    logoutUseCase = MockLogoutUseCase();
    getCurrentUserUseCase = MockGetCurrentUserUseCase();
    updateConsentUseCase = MockUpdateConsentUseCase();
    forgotPasswordUseCase = MockForgotPasswordUseCase();
  });

  group('AuthBloc', () {
    blocTest<AuthBloc, AuthState>(
      'emits authenticated when user has consented',
      build: () {
        when(() => getCurrentUserUseCase.call()).thenAnswer(
          (_) async => Right(consentedUser),
        );
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const CheckAuthEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'emits consent required for new user',
      build: () {
        when(() => getCurrentUserUseCase.call()).thenAnswer(
          (_) async => Right(unconsentedUser),
        );
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const CheckAuthEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthConsentRequired>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'emits unauthenticated when check fails',
      build: () {
        when(() => getCurrentUserUseCase.call()).thenAnswer(
          (_) async => const Left(ServerFailure(message: 'Not logged in')),
        );
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const CheckAuthEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'login with valid credentials emits authenticated',
      build: () {
        when(() => loginUseCase.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => Right(consentedUser));
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoginEvent(email: 'a@b.com', password: '123')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'login error emits AuthError',
      build: () {
        when(() => loginUseCase.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => const Left(ServerFailure(message: 'Invalid')));
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const LoginEvent(email: 'a@b.com', password: '123')),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthError>().having((s) => s.message, 'msg', 'Invalid'),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'register emits consent required',
      build: () {
        when(() => registerUseCase.call(
          email: any(named: 'email'),
          password: any(named: 'password'),
          displayName: any(named: 'displayName'),
        )).thenAnswer((_) async => Right(unconsentedUser));
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const RegisterEvent(
        email: 'a@b.com', password: '123', displayName: 'A',
      )),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthConsentRequired>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'logout emits unauthenticated',
      build: () {
        when(() => logoutUseCase.call()).thenAnswer((_) async => const Right(null));
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const LogoutEvent()),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthUnauthenticated>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'forgot password emits AuthPasswordResetSent',
      build: () {
        when(() => forgotPasswordUseCase.call(any())).thenAnswer(
          (_) async => const Right(null),
        );
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const ForgotPasswordEvent(email: 'a@b.com')),
      expect: () => [
        isA<AuthPasswordResetSent>(),
      ],
      wait: const Duration(milliseconds: 100),
    );

    blocTest<AuthBloc, AuthState>(
      'update consent triggers check auth',
      build: () {
        when(() => updateConsentUseCase.call(any())).thenAnswer(
          (_) async => const Right(null),
        );
        when(() => getCurrentUserUseCase.call()).thenAnswer(
          (_) async => Right(consentedUser),
        );
        return AuthBloc(
          loginUseCase: loginUseCase,
          registerUseCase: registerUseCase,
          googleSignInUseCase: googleSignInUseCase,
          logoutUseCase: logoutUseCase,
          getCurrentUserUseCase: getCurrentUserUseCase,
          updateConsentUseCase: updateConsentUseCase,
          forgotPasswordUseCase: forgotPasswordUseCase,
        );
      },
      act: (bloc) => bloc.add(const UpdateConsentEvent(consented: true)),
      expect: () => [
        isA<AuthLoading>(),
        isA<AuthAuthenticated>(),
      ],
      wait: const Duration(milliseconds: 200),
    );
  });
}
