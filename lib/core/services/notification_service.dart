import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz_data;

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  String? _deviceToken;
  StreamSubscription? _messageSubscription;

  String? get deviceToken => _deviceToken;

  Future<void> init() async {
    tz_data.initializeTimeZones();
    if (!kIsWeb) {
      await _requestPermission();
      await _initLocalNotifications();
      try {
        _deviceToken = await _fcm.getToken();
        _listenToForegroundMessages();
      } catch (e) {
        debugPrint('[Notifications] FCM init error: $e');
      }
    }
  }

  Future<void> _requestPermission() async {
    await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  void _listenToForegroundMessages() {
    _messageSubscription = FirebaseMessaging.onMessage.listen(_showLocalNotification);
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'aquatrack_channel',
      'إشعارات أكواتراك',
      channelDescription: 'إشعارات التذكير والتنبيهات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      notification.title,
      notification.body,
      details,
      payload: message.data['route'],
    );
  }

  void _onNotificationTap(NotificationResponse response) {
    // Navigation handled via payload when app is in background.
    // For foreground, the UI layer should listen and navigate.
    final route = response.payload;
    if (route != null) {
      _pendingNavigation = route;
    }
  }

  String? _pendingNavigation;
  String? consumePendingNavigation() {
    final route = _pendingNavigation;
    _pendingNavigation = null;
    return route;
  }

  Future<void> showLocalNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'aquatrack_channel',
      'إشعارات أكواتراك',
      channelDescription: 'إشعارات التذكير والتنبيهات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(id, title, body, details, payload: payload);
  }

  Future<void> scheduleDailyReminder() async {
    final now = DateTime.now();
    final scheduledDate = DateTime(now.year, now.month, now.day, 19, 0);
    final scheduledTz = tz.TZDateTime.from(
      scheduledDate.isAfter(now) ? scheduledDate : scheduledDate.add(const Duration(days: 1)),
      tz.local,
    );

    const androidDetails = AndroidNotificationDetails(
      'aquatrack_channel',
      'إشعارات أكواتراك',
      channelDescription: 'إشعارات التذكير والتنبيهات',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.zonedSchedule(
      1,
      'تذكير يومي',
      'لم تسجل تدريب اليوم بعد! سجل تدريبك الآن',
      scheduledTz,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      payload: '/daily_log',
    );
  }

  Future<void> cancelDailyReminder() async {
    await _localNotifications.cancel(1);
  }

  Future<void> updateFcmToken(String uid) async {
    final fcmToken = await FirebaseMessaging.instance.getToken();
    if (fcmToken != null) {
      // TODO: The FCM token should be sent to the backend database 
      // to associate it with the user. The backend will use this token 
      // to send targeted push notifications via Firebase Admin SDK.
      debugPrint('FCM Token: $fcmToken');
      _deviceToken = fcmToken;
    }
  }

  Future<void> deleteToken() async {
    await _fcm.deleteToken();
    _deviceToken = null;
  }

  void dispose() {
    _messageSubscription?.cancel();
  }
}
