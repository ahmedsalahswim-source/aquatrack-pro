
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';

// Core
import 'package:aquatrack_pro/core/network/network_info.dart';
import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/services/notification_service.dart';
import 'package:aquatrack_pro/core/services/app_preferences.dart';
import 'package:aquatrack_pro/core/services/ai_model_router.dart';
import 'package:aquatrack_pro/core/services/swimmer_context_builder.dart';
import 'package:aquatrack_pro/core/services/knowledge_base_service.dart';
import 'package:aquatrack_pro/core/services/web_search_service.dart';
import 'package:aquatrack_pro/core/services/prompt_builder.dart';

// Auth
import 'package:aquatrack_pro/features/auth/data/datasources/auth_remote_datasource.dart';
import 'package:aquatrack_pro/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:aquatrack_pro/features/auth/domain/repositories/auth_repository.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/login_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/register_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/google_sign_in_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/logout_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/get_current_user_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/update_consent_usecase.dart';
import 'package:aquatrack_pro/features/auth/domain/usecases/forgot_password_usecase.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';

// Athlete
import 'package:aquatrack_pro/features/athlete/data/datasources/athlete_remote_datasource.dart';
import 'package:aquatrack_pro/features/athlete/data/repositories/athlete_repository_impl.dart';
import 'package:aquatrack_pro/features/athlete/domain/repositories/athlete_repository.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/add_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/update_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/delete_athlete_usecase.dart';
import 'package:aquatrack_pro/features/athlete/domain/usecases/watch_athletes_usecase.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';

// Daily Log
import 'package:aquatrack_pro/features/daily_log/data/datasources/daily_log_remote_datasource.dart';
import 'package:aquatrack_pro/features/daily_log/data/repositories/daily_log_repository_impl.dart';
import 'package:aquatrack_pro/features/daily_log/domain/repositories/daily_log_repository.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';

// Dashboard
import 'package:aquatrack_pro/features/dashboard/domain/repositories/dashboard_repository.dart';
import 'package:aquatrack_pro/features/dashboard/data/repositories/dashboard_repository_impl.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';

// AI Assistant
import 'package:aquatrack_pro/features/ai_assistant/data/datasources/ai_remote_datasource.dart';
import 'package:aquatrack_pro/features/ai_assistant/data/repositories/ai_repository_impl.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/repositories/ai_repository.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/send_message_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/get_ai_history_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/domain/usecases/get_messages_used_today_usecase.dart';
import 'package:aquatrack_pro/features/ai_assistant/presentation/bloc/ai_bloc.dart';

// Nutrition
import 'package:aquatrack_pro/features/nutrition/domain/repositories/nutrition_repository.dart';
import 'package:aquatrack_pro/features/nutrition/presentation/bloc/nutrition_bloc.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  // Core
  sl.registerLazySingleton<NetworkInfo>(() => NetworkInfoImpl(connectivity: Connectivity()));
  sl.registerLazySingleton<AppPreferences>(() => AppPreferences());
  sl.registerLazySingleton<AppLocalizations>(() => AppLocalizations(sl<AppPreferences>().locale));

  final notificationService = NotificationService();
  await notificationService.init();
  sl.registerLazySingleton<NotificationService>(() => notificationService);

  // Firebase
  final firebaseAuth = fb_auth.FirebaseAuth.instance;
  final firestore = FirebaseFirestore.instance;
  final GoogleSignIn? googleSignIn = kIsWeb ? null : GoogleSignIn();

  // Auth
  sl.registerLazySingleton<AuthRemoteDataSource>(() => AuthRemoteDataSourceImpl(
        auth: firebaseAuth,
        firestore: firestore,
        googleSignIn: googleSignIn,
      ));
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImpl(
        remoteDataSource: sl<AuthRemoteDataSource>(),
      ));
  sl.registerLazySingleton(() => LoginUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => RegisterUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => GoogleSignInUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => LogoutUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => UpdateConsentUseCase(repository: sl<AuthRepository>()));
  sl.registerLazySingleton(() => ForgotPasswordUseCase(repository: sl<AuthRepository>()));
  sl.registerFactory(() => AuthBloc(
        loginUseCase: sl(),
        registerUseCase: sl(),
        googleSignInUseCase: sl(),
        logoutUseCase: sl(),
        getCurrentUserUseCase: sl(),
        updateConsentUseCase: sl(),
        forgotPasswordUseCase: sl(),
      ));

  // Athlete
  sl.registerLazySingleton<AthleteRemoteDataSource>(() => AthleteRemoteDataSourceImpl(
        firestore: firestore,
      ));
  sl.registerLazySingleton<AthleteRepository>(() => AthleteRepositoryImpl(
        remoteDataSource: sl<AthleteRemoteDataSource>(),
      ));
  sl.registerLazySingleton(() => AddAthleteUseCase(repository: sl<AthleteRepository>()));
  sl.registerLazySingleton(() => UpdateAthleteUseCase(repository: sl<AthleteRepository>()));
  sl.registerLazySingleton(() => DeleteAthleteUseCase(repository: sl<AthleteRepository>()));
  sl.registerLazySingleton(() => WatchAthletesUseCase(repository: sl<AthleteRepository>()));
  sl.registerFactory(() => AthleteBloc(
        addAthleteUseCase: sl(),
        updateAthleteUseCase: sl(),
        deleteAthleteUseCase: sl(),
        watchAthletesUseCase: sl(),
      ));

  // Daily Log
  sl.registerLazySingleton<DailyLogRemoteDataSource>(() => DailyLogRemoteDataSourceImpl(
        firestore: firestore,
      ));
  sl.registerLazySingleton<DailyLogRepository>(() => DailyLogRepositoryImpl(
        remoteDataSource: sl<DailyLogRemoteDataSource>(),
      ));
  sl.registerFactory(() => DailyLogBloc(repository: sl<DailyLogRepository>()));

  // Dashboard
  sl.registerLazySingleton<DashboardRepository>(() => DashboardRepositoryImpl(
        dailyLogRepository: sl<DailyLogRepository>(),
      ));
  sl.registerFactory(() => DashboardBloc(dashboardRepository: sl<DashboardRepository>()));

  // Nutrition
  final nutritionRepo = NutritionRepositoryImpl();
  await nutritionRepo.init();
  sl.registerLazySingleton<NutritionRepository>(() => nutritionRepo);
  sl.registerFactory(() => NutritionBloc(
        repository: sl<NutritionRepository>(),
        dailyLogRepository: sl<DailyLogRepository>(),
      ));

  // AI Services
  sl.registerLazySingleton<AiModelRouter>(() => AiModelRouter());
  sl.registerLazySingleton<SwimmerContextBuilder>(() => const SwimmerContextBuilder());
  sl.registerLazySingleton<KnowledgeBaseService>(() => KnowledgeBaseService()..init());
  sl.registerLazySingleton<WebSearchService>(() => WebSearchService());
  sl.registerLazySingleton<PromptBuilder>(() => const PromptBuilder());

  // AI Assistant
  sl.registerLazySingleton<AiRemoteDataSource>(() => AiRemoteDataSourceImpl(
        firestore: firestore,
        router: sl<AiModelRouter>(),
        webSearch: sl<WebSearchService>(),
      ));
  sl.registerLazySingleton<AiRepository>(() => AiRepositoryImpl(
        remoteDataSource: sl<AiRemoteDataSource>(),
        knowledgeBase: sl<KnowledgeBaseService>(),
        webSearch: sl<WebSearchService>(),
        promptBuilder: sl<PromptBuilder>(),
      ));
  sl.registerLazySingleton(() => SendMessageUseCase(repository: sl<AiRepository>()));
  sl.registerLazySingleton(() => GetAiHistoryUseCase(repository: sl<AiRepository>()));
  sl.registerLazySingleton(() => GetMessagesUsedTodayUseCase(repository: sl<AiRepository>()));
  sl.registerFactory(() => AiBloc(
        sendMessageUseCase: sl(),
        getAiHistoryUseCase: sl(),
        getMessagesUsedTodayUseCase: sl(),
        aiRepository: sl<AiRepository>(),
        contextBuilder: sl<SwimmerContextBuilder>(),
        logRepository: sl<DailyLogRepository>(),
      ));
}
