import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_performance/firebase_performance.dart';

class MonitoringService {
  static final MonitoringService _instance = MonitoringService._();
  factory MonitoringService() => _instance;
  MonitoringService._();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    await SentryFlutter.init(
      (options) {
        options.dsn = const String.fromEnvironment(
          'SENTRY_DSN',
          defaultValue: '',
        );
        options.tracesSampleRate = kReleaseMode ? 0.2 : 1.0;
      },
    );
  }

  void captureException(dynamic exception, {StackTrace? stackTrace, Map<String, dynamic>? extras}) {
    Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      withScope: (scope) {
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
      },
    );
  }

  void captureMessage(String message, {Map<String, dynamic>? extras}) {
    Sentry.captureMessage(
      message,
      withScope: (scope) {
        if (extras != null) {
          scope.setContexts('extras', extras);
        }
      },
    );
  }

  void startTrace(String name, String operation) {
    if (!kReleaseMode) return;
    try {
      FirebasePerformance.instance.newTrace('$name/$operation').start();
    } catch (_) {}
  }

  void stopTrace(String name, String operation) {
    if (!kReleaseMode) return;
    try {
      FirebasePerformance.instance.newTrace('$name/$operation').stop();
    } catch (_) {}
  }
}
