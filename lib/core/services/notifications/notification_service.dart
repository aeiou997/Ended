import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Notification service for scroll reminders and goal alerts.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Initialize notification plugin
  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create Android notification channels
    const reminderChannel = AndroidNotificationChannel(
      'ended_reminders',
      'Scroll Reminders',
      description: 'Reminders about your scrolling habits',
      importance: Importance.defaultImportance,
      enableVibration: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(reminderChannel);

    _initialized = true;
    debugPrint('[NotificationService] Initialized');
  }

  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('[NotificationService] Tapped: ${response.payload}');
    // Navigate to home/dashboard — handled by router
  }

  /// "You have already watched X reels today."
  Future<void> showVideoCountReminder(int videoCount) async {
    await _show(
      id: 1,
      title: '📈 Daily Reel Count',
      body: 'You have already watched $videoCount reels today.',
      payload: 'video_count',
    );
  }

  /// "You reached today's limit."
  Future<void> showLimitReached() async {
    await _show(
      id: 2,
      title: '🛑 Daily Limit Reached',
      body: "You reached today's limit. Take a break and do something you love!",
      payload: 'limit_reached',
    );
  }

  /// "Take a short break."
  Future<void> showBreakReminder() async {
    await _show(
      id: 3,
      title: '☕ Take a Break',
      body: 'You\'ve been scrolling for a while. Take a short break.',
      payload: 'break_reminder',
    );
  }

  /// "You have been scrolling for 30 minutes."
  Future<void> showScrollTimeReminder(int minutes) async {
    await _show(
      id: 4,
      title: '⏰ Scrolling Alert',
      body: 'You have been scrolling for $minutes minutes.',
      payload: 'scroll_time',
    );
  }

  /// "You reduced your scrolling by 40% this week. Great job!"
  Future<void> showImprovementReminder(double percentReduction) async {
    await _show(
      id: 5,
      title: '🎉 Great Progress!',
      body: 'You reduced your scrolling by ${percentReduction.toStringAsFixed(0)}% this week. Keep it up!',
      payload: 'improvement',
    );
  }

  /// Schedule a daily summary notification
  Future<void> scheduleDailySummary(int videoCount, int minutes) async {
    await _show(
      id: 100,
      title: '📊 Today\'s Summary',
      body: '$videoCount videos watched · $minutes minutes',
      payload: 'daily_summary',
    );
  }

  /// Cancel all notifications
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  /// Cancel a specific notification
  Future<void> cancel(int id) async {
    await _plugin.cancel(id);
  }

  Future<void> _show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'ended_reminders',
      'Scroll Reminders',
      channelDescription: 'Reminders about your scrolling habits',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      showWhen: true,
      styleInformation: BigTextStyleInformation(''),
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(id, title, body, details, payload: payload);
  }
}
