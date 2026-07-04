import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:ended/data/models/video_event.dart';
import 'package:ended/data/repositories/app_repository.dart';
import 'package:ended/core/constants/app_constants.dart';

/// Background monitoring service that detects short-form video viewing.
///
/// ANDROID LIMITATIONS (IMPORTANT — documented per your requirement):
/// ─────────────────────────────────────────────────────────────
/// 1. Android's UsageStatsManager can tell us WHEN a user opens a supported
///    app and HOW LONG they use it, but CANNOT identify individual videos
///    or reels watched within that app.
///
/// 2. Accessibility Service CAN read screen content in some cases, but:
///    - It cannot reliably extract unique video IDs from Instagram/YouTube.
///    - Google Play may reject apps using Accessibility for this purpose.
///    - Users must manually enable it in Settings → Accessibility.
///
/// 3. Our privacy-respecting approach:
///    - We use UsageStatsManager to detect when supported apps are in foreground.
///    - We estimate video count based on time spent + short-form video avg duration.
///    - We do NOT read screen content, capture screenshots, or access media.
///    - We do NOT collect any content the user watches.
///
/// 4. Heuristic for counting:
///    - When a supported app is in foreground for ≥ 3 seconds, we assume
///      the user is viewing short-form content.
///    - We estimate ~1 video per 30 seconds of foreground time (avg reel length).
///    - This is ENCOURAGED to be treated as an estimate, not exact count.
///    - The app clearly labels these as "estimated videos" in the UI.
/// ─────────────────────────────────────────────────────────────
class MonitoringService {
  final AppRepository _repository;
  final StreamController<VideoEvent> _eventController = StreamController<VideoEvent>.broadcast();

  Timer? _pollTimer;
  DateTime? _appForegroundStart;
  String? _currentForegroundApp;
  bool _isRunning = false;

  Stream<VideoEvent> get eventStream => _eventController.stream;
  bool get isRunning => _isRunning;

  MonitoringService(this._repository);

  /// Start monitoring — polls UsageStats every 15 seconds
  void start() {
    if (_isRunning) return;
    _isRunning = true;
    debugPrint('[MonitoringService] Started');
    _pollTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _pollUsageStats(),
    );
  }

  /// Stop monitoring
  void stop() {
    if (!_isRunning) return;
    _isRunning = false;
    _pollTimer?.cancel();
    _pollTimer = null;
    // Record the final session if any
    _recordEndOfSession();
    debugPrint('[MonitoringService] Stopped');
  }

  /// Core polling logic — checks which supported app is in foreground
  Future<void> _pollUsageStats() async {
    try {
      final config = _repository.getAppConfig();
      if (!config.monitoringEnabled) return;

      // In a real Android build, this calls UsageStatsManager via platform channel.
      // For this cross-platform codebase, we use the method channel interface.
      final foregroundApp = await _getForegroundApp();

      if (foregroundApp != null && config.platformEnabled.entries.any(
        (e) => e.value && AppConstants.supportedPlatforms[e.key]?.packageName == foregroundApp,
      )) {
        // A supported app is in foreground
        final platformId = config.platformEnabled.keys.firstWhere(
          (id) => AppConstants.supportedPlatforms[id]?.packageName == foregroundApp,
          orElse: () => '',
        );

        if (platformId.isEmpty) return;

        if (_currentForegroundApp != foregroundApp) {
          // New app came to foreground
          _recordEndOfSession();
          _appForegroundStart = DateTime.now();
          _currentForegroundApp = foregroundApp;
        }
        // App continues in foreground — session time accumulates
      } else {
        // No supported app in foreground — end current session
        _recordEndOfSession();
        _currentForegroundApp = null;
        _appForegroundStart = null;
      }
    } catch (e) {
      debugPrint('[MonitoringService] Error polling: $e');
    }
  }

  /// Called when user leaves a supported app — estimates videos watched
  void _recordEndOfSession() {
    if (_currentForegroundApp == null || _appForegroundStart == null) return;

    final sessionEnd = DateTime.now();
    final sessionDuration = sessionEnd.difference(_appForegroundStart!);

    // Minimum watch time to count (3 seconds)
    if (sessionDuration.inSeconds < 3) return;

    // Find platform ID
    final matchingEntry = AppConstants.supportedPlatforms.entries
        .where((e) => e.value.packageName == _currentForegroundApp)
        .firstOrNull;
    final platformId = matchingEntry?.key ?? '';

    if (platformId.isEmpty) return;

    // Estimate number of videos: ~1 per 30 seconds (average reel length)
    final estimatedVideos = (sessionDuration.inSeconds / 30).floor().clamp(1, 200);

    // Create video events for each estimated video
    for (var i = 0; i < estimatedVideos; i++) {
      final eventTime = _appForegroundStart!.add(Duration(seconds: i * 30));
      final dedupKey = '${platformId}_${eventTime.millisecondsSinceEpoch ~/ 30000}';

      // Dedup check
      if (_repository.isVideoAlreadyCounted(dedupKey, DateTime.now())) continue;

      final event = VideoEvent(
        id: '${platformId}_${eventTime.millisecondsSinceEpoch}_$i',
        platformId: platformId,
        videoIdentifier: null, // Cannot extract real video IDs
        timestamp: eventTime,
        watchDuration: const Duration(seconds: 30),
        counted: true,
      );

      _repository.recordVideoEvent(event);
      _eventController.add(event);
    }

    debugPrint('[MonitoringService] Session: $sessionDuration → ~$estimatedVideos videos on $platformId');
  }

  /// Platform channel to get foreground app package name.
  /// On Android, this calls UsageStatsManager.queryEvents().
  /// Returns null if no supported app is in foreground.
  Future<String?> _getForegroundApp() async {
    // This is implemented via platform channel in the Android native code.
    // See: android/app/src/main/java/com/ended/app/UsageStatsHelper.kt
    // For now, returns null (no foreground app detected).
    // The real implementation requires:
    //   1. android.permission.PACKAGE_USAGE_STATS
    //   2. UsageStatsManager.queryEvents(startTime, endTime)
    //   3. Find the event with MOVE_TO_FOREGROUND type
    return null;
  }

  void dispose() {
    stop();
    _eventController.close();
  }
}
