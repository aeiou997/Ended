import 'package:ended/data/models/video_event.dart';
import 'package:ended/data/models/daily_stats.dart';
import 'package:ended/data/models/app_config.dart';
import 'package:ended/data/models/user_goal.dart';
import 'package:ended/data/datasources/local/local_data_source.dart';

/// Repository layer: mediates between data sources and domain.
/// All app data flows through here.
class AppRepository {
  final LocalDataSource _local;

  AppRepository(this._local);

  // --- Video Events ---

  Future<void> recordVideoEvent(VideoEvent event) async {
    _local.saveVideoEvent(event);
    _rebuildDailyStats(event.timestamp);
  }

  List<VideoEvent> getVideoEventsForDate(DateTime date) =>
      _local.getVideoEventsForDate(date);

  List<VideoEvent> getVideoEventsForRange(DateTime start, DateTime end) =>
      _local.getVideoEventsForDateRange(start, end);

  /// Check if a video has already been counted today (dedup)
  bool isVideoAlreadyCounted(String dedupKey, DateTime date) {
    final events = _local.getVideoEventsForDate(date);
    return events.any((e) => e.dedupKey == dedupKey && e.counted);
  }

  // --- Daily Stats ---

  DailyStats? getDailyStats(DateTime date) => _local.getDailyStats(date);

  List<DailyStats> getWeeklyStats(DateTime referenceDate) {
    final start = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    return _local.getDailyStatsForRange(start, referenceDate);
  }

  List<DailyStats> getMonthlyStats(DateTime referenceDate) {
    final start = DateTime(referenceDate.year, referenceDate.month, 1);
    return _local.getDailyStatsForRange(start, referenceDate);
  }

  List<DailyStats> getStatsForRange(DateTime start, DateTime end) =>
      _local.getDailyStatsForRange(start, end);

  // --- App Config ---

  AppConfig getAppConfig() => _local.getAppConfig();

  Future<void> saveAppConfig(AppConfig config) async =>
      _local.saveAppConfig(config);

  // --- User Goal ---

  UserGoal getUserGoal() => _local.getUserGoal();

  Future<void> saveUserGoal(UserGoal goal) async =>
      _local.saveUserGoal(goal);

  // --- Export / Import ---

  String exportData() => _local.exportAllDataAsJson();

  void importData(String json) => _local.importDataFromJson(json);

  Future<void> clearAllData() async => _local.clearAllData();

  // --- Private: Rebuild daily stats from raw events ---

  void _rebuildDailyStats(DateTime date) {
    final events = _local.getVideoEventsForDate(date);
    final counted = events.where((e) => e.counted).toList();

    // Deduplicate by dedupKey
    final seen = <String>{};
    final unique = <VideoEvent>[];
    for (final e in counted) {
      if (!seen.contains(e.dedupKey)) {
        seen.add(e.dedupKey);
        unique.add(e);
      }
    }

    // Platform counts
    final platformCounts = <String, int>{};
    final platformWatchTime = <String, Duration>{};
    for (final e in unique) {
      platformCounts[e.platformId] = (platformCounts[e.platformId] ?? 0) + 1;
      platformWatchTime[e.platformId] =
          (platformWatchTime[e.platformId] ?? Duration.zero) + e.watchDuration;
    }

    // Total
    final totalWatchTime = unique.fold<Duration>(
      Duration.zero, (acc, e) => acc + e.watchDuration);

    // Detect sessions: gap > 2 min = new session
    final sorted = unique.toList()..sort((a, b) => a.timestamp.compareTo(b.timestamp));
    var sessions = 0;
    var currentSessionStart = 0;
    Duration longestSession = Duration.zero;
    for (var i = 1; i <= sorted.length; i++) {
      final isEnd = i == sorted.length ||
          sorted[i].timestamp.difference(sorted[i - 1].timestamp).inMinutes > 2;
      if (isEnd && i > currentSessionStart) {
        sessions++;
        final sessionDuration = sorted[i - 1].timestamp
            .difference(sorted[currentSessionStart].timestamp) +
            sorted[i - 1].watchDuration;
        if (sessionDuration > longestSession) {
          longestSession = sessionDuration;
        }
        currentSessionStart = i;
      }
    }

    final stats = DailyStats(
      date: DateTime(date.year, date.month, date.day),
      totalVideos: unique.length,
      totalWatchTime: totalWatchTime,
      platformCounts: platformCounts,
      platformWatchTime: platformWatchTime,
      longestSession: longestSession,
      sessionsCount: sessions,
    );

    _local.saveDailyStats(stats);
  }
}
