import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui' show PlatformDispatcher;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart' as pv;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:aquatrack_pro/core/localization/app_localizations.dart';
import 'package:aquatrack_pro/core/theme/app_theme.dart';
import 'package:aquatrack_pro/core/services/app_preferences.dart';
import 'package:aquatrack_pro/core/services/monitoring_service.dart';
import 'package:aquatrack_pro/injection_container.dart' show sl, initDependencies;
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_event.dart';
import 'package:aquatrack_pro/features/auth/presentation/bloc/auth_state.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/consent_page.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/splash_page.dart';
import 'package:aquatrack_pro/features/auth/presentation/pages/auth_flow_page.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/pages/app_hub_page.dart';
import 'package:aquatrack_pro/features/dashboard/presentation/bloc/dashboard_bloc.dart';
import 'package:aquatrack_pro/features/daily_log/presentation/bloc/daily_log_bloc.dart';
import 'package:aquatrack_pro/features/athlete/presentation/bloc/athlete_bloc.dart';
import 'package:aquatrack_pro/core/services/hive_cache_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final monitor = MonitoringService();
  await monitor.init();

  _runApp(monitor);
}

void _runApp(MonitoringService monitor) {
  try {
    dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('[main] dotenv load skipped: $e');
  }

  HiveCacheService.init().then((_) async {
    try {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      
      const useEmulator = bool.fromEnvironment('USE_FIREBASE_EMULATOR', defaultValue: false);
      if (useEmulator) {
        try {
          FirebaseFirestore.instance.useFirestoreEmulator('127.0.0.1', 8080);
          await FirebaseAuth.instance.useAuthEmulator('127.0.0.1', 9099);
          debugPrint('Using Firebase Emulators on localhost');
        } catch (e) {
          debugPrint('Failed to use Firebase Emulators: $e');
        }
      }
    } catch (e) {
      monitor.captureException(e, extras: {'phase': 'firebase_init'});
      runApp(AquaTrackApp(firebaseError: e.toString()));
      return;
    }

    await initDependencies();
    await initializeDateFormatting('ar');
    await initializeDateFormatting('en');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      monitor.captureException(
        details.exception,
        stackTrace: details.stack,
        extras: {'phase': 'flutter_onError', 'library': details.library ?? ''},
      );
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      monitor.captureException(error, stackTrace: stack, extras: {'phase': 'platform_error'});
      return true;
    };

    ErrorWidget.builder = (details) => _ErrorScreen(details: details);

    pv.Provider.debugCheckInvalidValueType = null;
    runApp(const AquaTrackApp());
  }).onError((error, stackTrace) {
    monitor.captureException(error!, stackTrace: stackTrace, extras: {'phase': 'init_chain'});
    runApp(AquaTrackApp(firebaseError: error.toString()));
  });
}

class _ErrorScreen extends StatelessWidget {
  final FlutterErrorDetails details;

  const _ErrorScreen({required this.details});

  @override
  Widget build(BuildContext context) {
    MonitoringService().captureException(
      details.exception,
      stackTrace: details.stack,
      extras: {'phase': 'flutter_error_widget', 'library': details.library ?? ''},
    );
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: AppColors.danger),
                const SizedBox(height: 20),
                const Text(
                  'عذراً، حدث خطأ غير متوقع',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'تم تسجيل الخطأ تلقائياً. يرجى إعادة تشغيل التطبيق.',
                  style: TextStyle(fontSize: 14, color: AppColors.textMuted),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => SystemNavigator.pop(),
                  child: const Text('إغلاق التطبيق'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AquaTrackApp extends StatefulWidget {
  final String? firebaseError;

  const AquaTrackApp({super.key, this.firebaseError});

  @override
  State<AquaTrackApp> createState() => _AquaTrackAppState();
}

class _AquaTrackAppState extends State<AquaTrackApp> {
  late final AppPreferences _prefs;
  late final AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _prefs = sl<AppPreferences>();
    _localizations = sl<AppLocalizations>();
    _prefs.addListener(_onPrefsChanged);
  }

  @override
  void dispose() {
    _prefs.removeListener(_onPrefsChanged);
    super.dispose();
  }

  void _onPrefsChanged() {
    setState(() {
      _localizations.locale = _prefs.locale;
    });
  }

  @override
  Widget build(BuildContext context) {
    return pv.Provider<AppLocalizations>.value(
      value: _localizations,
      child: pv.Provider<AppPreferences>.value(
        value: _prefs,
        child: MultiBlocProvider(
          providers: [
            BlocProvider(create: (_) => sl<AuthBloc>()..add(CheckAuthEvent())),
            BlocProvider(create: (_) => sl<AthleteBloc>()),
            BlocProvider(create: (_) => sl<DashboardBloc>()),
            BlocProvider(create: (_) => sl<DailyLogBloc>()),
          ],
          child: MaterialApp(
            title: 'AquaTrack Pro',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: _prefs.themeMode,
            locale: _prefs.locale,
            supportedLocales: const [
              Locale('ar', 'SA'),
              Locale('en', 'US'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            home: widget.firebaseError != null
                ? _FirebaseErrorScreen(message: widget.firebaseError!)
                : const AppRoot(),
          ),
        ),
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  final String message;

  const _FirebaseErrorScreen({required this.message});

  @override
  Widget build(BuildContext context) {
    // Attempt to safely translate using a hardcoded fallback if localization isn't loaded yet
    final errorText = 'تعذر الاتصال بخدمات Firebase';
    final descText = 'يرجى التأكد من إعداد ملفات Firebase (google-services.json / GoogleService-Info.plist)';
    
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64, color: AppColors.danger),
              const SizedBox(height: 20),
              Text(
                errorText,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                descText,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textMuted,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AppRoot extends StatefulWidget {
  const AppRoot({super.key});

  @override
  State<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<AppRoot> {
  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      },
      builder: (context, state) {
        if (state is AuthLoading) {
          return const SplashPage();
        }
        if (state is AuthUnauthenticated) {
          return _buildAuthFlow();
        }
        if (state is AuthConsentRequired) {
          return ConsentPage(user: state.user);
        }
        if (state is AuthAuthenticated) {
          return AppHubPage(
            user: state.user,
          );
        }
        if (state is AuthError) {
          return _buildAuthFlow();
        }
        return const SplashPage();
      },
    );
  }

  Widget _buildAuthFlow() {
    return const AuthFlowPage();
  }
}
