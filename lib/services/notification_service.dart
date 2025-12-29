import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'scam_channel';
  static const String _channelName = 'Scam Alerts';
  static const String _channelDescription = 'Real-time scam detection alerts';

  static Future<void> initialize() async {
    // Request notification permission
    await _requestNotificationPermission();

    // Create notification channel for Android 8.0+
    await _createNotificationChannel();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );
  }

  static Future<void> _requestNotificationPermission() async {
    final status = await Permission.notification.request();
    if (!status.isGranted) {
      throw Exception('Notification permission denied');
    }
  }

  static Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: _channelDescription,
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      showBadge: true,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showScamAlert({
    required String title,
    required String body,
    required String payload,
  }) async {
    try {
      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.max,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
        playSound: true,
        enableVibration: true,
        enableLights: true,
        styleInformation: BigTextStyleInformation(
          body,
          contentTitle: title,
          summaryText: 'Scam Detection Alert',
        ),
      );

      final NotificationDetails platformDetails =
          NotificationDetails(android: androidDetails);

      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        platformDetails,
        payload: payload,
      );
    } catch (e) {
      // Log error but don't crash the app
      // Use a proper logger in production
      // ignore: avoid_print
      print('Failed to show notification: $e');
    }
  }

  static void _onNotificationTap(NotificationResponse response) {
    // Handle notification tap
    // You can navigate to a specific screen or perform an action
    // Use a proper logger in production
    // ignore: avoid_print
    print('Notification tapped: ${response.payload}');
  }

  static Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  static Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  /// Test notification functionality
  static Future<void> testNotification({
    required String title,
    required String body,
    String payload = 'test_notification',
  }) async {
    try {
      // Show a test notification
      await showScamAlert(
        title: '🧪 $title',
        body: '$body\n\nThis is a test notification.',
        payload: payload,
      );
      // ignore: avoid_print
      print('Test notification sent successfully');
    } catch (e) {
      // ignore: avoid_print
      print('Failed to send test notification: $e');
      rethrow;
    }
  }

  /// Test different types of notifications
  static Future<void> testScamNotification() async {
    await testNotification(
      title: 'HIGH RISK SCAM DETECTED',
      body: 'M-Pesa reversal scam detected with 95% confidence. Never share your PIN with unknown parties.',
      payload: 'scam_test',
    );
  }

  static Future<void> testSuspiciousNotification() async {
    await testNotification(
      title: 'SUSPICIOUS MESSAGE',
      body: 'Potential cryptocurrency investment scam detected. Verify before taking any action.',
      payload: 'suspicious_test',
    );
  }

  static Future<void> testLegitimateNotification() async {
    await testNotification(
      title: 'MESSAGE ANALYZED',
      body: 'This message appears to be legitimate. No scam patterns detected.',
      payload: 'legitimate_test',
    );
  }

  /// Test scheduled notification (for future enhancement)
  static Future<void> testScheduledNotification() async {
    final scheduleTime = DateTime.now().add(Duration(seconds: 5));
    
    final androidDetails = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: _channelDescription,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    
    final platformDetails = NotificationDetails(android: androidDetails);
    
    await _notifications.zonedSchedule(
      0,
      '🧪 Scheduled Test Notification',
      'This notification was scheduled to appear in 5 seconds.',
      tz.TZDateTime.from(scheduleTime, tz.local),
      platformDetails,
      payload: 'scheduled_test',
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }
}
