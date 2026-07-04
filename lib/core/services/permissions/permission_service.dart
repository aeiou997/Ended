import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';
import 'package:flutter/foundation.dart';

/// Handles all Android permission requests for the Ended app.
class PermissionService {
  PermissionService._();
  static final PermissionService instance = PermissionService._();

  /// Check and request all required permissions.
  /// Returns true if all granted, false otherwise.
  Future<bool> requestAllPermissions() async {
    // 1. Usage Stats (special — opens system settings)
    final usageStatsGranted = await requestUsageStatsPermission();
    
    // 2. Notifications
    final notificationStatus = await Permission.notification.request();

    final allGranted = usageStatsGranted && notificationStatus.isGranted;

    debugPrint('[PermissionService] Results: usageStats=$usageStatsGranted, '
        'notification=$notificationStatus, all=$allGranted');

    return allGranted;
  }

  /// Usage Stats is a special permission — must be granted via system settings.
  Future<bool> requestUsageStatsPermission() async {
    // On Android, PACKAGE_USAGE_STATS requires the user to go to
    // Settings → Security → Apps with usage access
    // We open that settings page for the user.
    try {
      // UsageStats permission is not in permission_handler —
      // we open system settings manually
      await AppSettings.openAppSettings(type: AppSettingsType.security);
      return true; // User must manually grant — we can't verify here
    } catch (e) {
      debugPrint('[PermissionService] Error requesting usage stats: $e');
      return false;
    }
  }

  /// Check notification permission
  Future<bool> hasNotificationPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  /// Open app settings for manual permission changes
  Future<void> openAppSettings() async {
    await AppSettings.openAppSettings();
  }
}
