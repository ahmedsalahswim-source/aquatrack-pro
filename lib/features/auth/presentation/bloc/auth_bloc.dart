import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/login_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/register_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/update_consent_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final GoogleSignInUseCase googleSignInUseCase;
  final LogoutUseCase logoutUseCase;
  final GetCurrentUserUseCase getCurrentUserUseCase;
  final UpdateConsentUseCase updateConsentUseCase;
  final ForgotPasswordUseCase forgotPasswordUseCase;

  AuthBloc({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.googleSignInUseCase,
    required this.logoutUseCase,
    required this.getCurrentUserUseCase,
    required this.updateConsentUseCase,
    required this.forgotPasswordUseCase,
  }) : super(const AuthInitial()) {
    on<CheckAuthEvent>(_onCheckAuth);
    on<LoginEvent>(_onLogin);
    on<RegisterEvent>(_onRegister);
    on<GoogleSignInEvent>(_onGoogleSignIn);
    on<LogoutEvent>(_onLogout);
    on<UpdateConsentEvent>(_onUpdateConsent);
    on<ForgotPasswordEvent>(_onForgotPassword);
  }

  Future<void> _onCheckAuth(CheckAuthEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await getCurrentUserUseCase.call();
    result.fold(
      (failure) => emit(AuthUnauthenticated()),
      (user) {
        if (!user.hasConsented) {
          emit(AuthConsentRequired(user: user));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      },
    );
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await loginUseCase.call(
      email: event.email,
      password: event.password,
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        if (!user.hasConsented) {
          emit(AuthConsentRequired(user: user));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      },
    );
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await registerUseCase.call(
      email: event.email,
      password: event.password,
      displayName: event.displayName,
    );
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) => emit(AuthConsentRequired(user: user)),
    );
  }

  Future<void> _onGoogleSignIn(GoogleSignInEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await googleSignInUseCase.call();
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (user) {
        if (!user.hasConsented) {
          emit(AuthConsentRequired(user: user));
        } else {
          emit(AuthAuthenticated(user: user));
        }
      },
    );
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    await logoutUseCase.call();
    emit(AuthUnauthenticated());
  }

  Future<void> _onUpdateConsent(UpdateConsentEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    final result = await updateConsentUseCase.call(event.consented);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => add(CheckAuthEvent()),
    );
  }

  Future<void> _onForgotPassword(ForgotPasswordEvent event, Emitter<AuthState> emit) async {
    final result = await forgotPasswordUseCase.call(event.email);
    result.fold(
      (failure) => emit(AuthError(message: failure.message)),
      (_) => emit(const AuthPasswordResetSent()),
    );
  }
}
