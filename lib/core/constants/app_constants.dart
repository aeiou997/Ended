import 'package:flutter/material.dart';

/// App-wide constant definitions for the Ended app
class AppConstants {
  AppConstants._();

  // App Info
  static const String appName = 'Ended';
  static const String tagline = 'Know when enough is enough.';
  static const String version = '1.0.0';

  // Supported Platforms
  static const Map<String, SupportedPlatform> supportedPlatforms = {
    'instagram': SupportedPlatform(
      id: 'instagram',
      name: 'Instagram',
      feature: 'Reels',
      packageName: 'com.instagram.android',
      icon: Icons.camera_alt_rounded,
      color: Color(0xFFE1306C),
    ),
    'youtube': SupportedPlatform(
      id: 'youtube',
      name: 'YouTube',
      feature: 'Shorts',
      packageName: 'com.google.android.youtube',
      icon: Icons.play_circle_rounded,
      color: Color(0xFFFF0000),
    ),
    'facebook': SupportedPlatform(
      id: 'facebook',
      name: 'Facebook',
      feature: 'Reels',
      packageName: 'com.facebook.katana',
      icon: Icons.facebook_rounded,
      color: Color(0xFF1877F2),
    ),
    'snapchat': SupportedPlatform(
      id: 'snapchat',
      name: 'Snapchat',
      feature: 'Spotlight',
      packageName: 'com.snapchat.android',
      icon: Icons.flash_on_rounded,
      color: Color(0xFFFFFC00),
    ),
  };

  // Hive Box Names
  static const String videoEventsBox = 'video_events';
  static const String dailyStatsBox = 'daily_stats';
  static const String appConfigBox = 'app_config';
  static const String userGoalsBox = 'user_goals';

  // Notification Channels
  static const String reminderChannelId = 'ended_reminders';
  static const String reminderChannelName = 'Scroll Reminders';

  // Background Service
  static const String monitoringTaskId = 'ended_monitoring';
  static const int monitoringIntervalMinutes = 15;

  // Defaults
  static const int defaultDailyVideoLimit = 50;
  static const int defaultDailyTimeLimitMinutes = 60;
  static const Duration minWatchTime = Duration(seconds: 3);
}

class SupportedPlatform {
  final String id;
  final String name;
  final String feature;
  final String packageName;
  final IconData icon;
  final Color color;

  const SupportedPlatform({
    required this.id,
    required this.name,
    required this.feature,
    required this.packageName,
    required this.icon,
    required this.color,
  });
}
