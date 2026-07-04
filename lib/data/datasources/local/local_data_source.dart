import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ended/data/models/video_event.dart';
import 'package:ended/data/models/daily_stats.dart';
import 'package:ended/data/models/app_config.dart';
import 'package:ended/data/models/user_goal.dart';

/// Local data source using SharedPreferences for persistence.
/// In a production build, this would use Hive for better performance,
/// but SharedPreferences works for the MVP and avoids codegen overhead.
class LocalDataSource {
  static const String _videoEventsKey = 'video_events';
  static const String _dailyStatsKey = 'daily_stats';
  static const String _appConfigKey = 'app_config';
  static const String _userGoalKey = 'user_goal';

  final SharedPreferences _prefs;

  LocalDataSource(this._prefs);

  // --- Video Events ---

  List<VideoEvent> getAllVideoEvents() {
    final raw = _prefs.getStringList(_videoEventsKey) ?? [];
    return raw.map((e) => VideoEvent.fromJson(jsonDecode(e) as Map<String, dynamic>)).toList();
  }

  void saveVideoEvent(VideoEvent event) {
    final events = getAllVideoEvents();
    events.add(event);
    final encoded = events.map((e) => jsonEncode(e.toJson())).toList();
    _prefs.setStringList(_videoEventsKey, encoded);
  }

  List<VideoEvent> getVideoEventsForDate(DateTime date) {
    final events = getAllVideoEvents();
    return events.where((e) =>
      e.timestamp.year == date.year &&
      e.timestamp.month == date.month &&
      e.timestamp.day == date.day
    ).toList();
  }

  List<VideoEvent> getVideoEventsForDateRange(DateTime start, DateTime end) {
    final events = getAllVideoEvents();
    return events.where((e) =>
      e.timestamp.isAfter(start.subtract(const Duration(days: 1))) &&
      e.timestamp.isBefore(end.add(const Duration(days: 1)))
    ).toList();
  }

  void clearAllVideoEvents() {
    _prefs.remove(_videoEventsKey);
  }

  // --- Daily Stats ---

  Map<String, DailyStats> getAllDailyStats() {
    final raw = _prefs.getString(_dailyStatsKey);
    if (raw == null) return {};
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return map.map((k, v) => MapEntry(k, DailyStats.fromJson(v as Map<String, dynamic>)));
  }

  DailyStats? getDailyStats(DateTime date) {
    final all = getAllDailyStats();
    final key = _dateKey(date);
    return all[key];
  }

  void saveDailyStats(DailyStats stats) {
    final all = getAllDailyStats();
    all[stats.dateKey] = stats;
    _prefs.setString(_dailyStatsKey, jsonEncode(all.map((k, v) => MapEntry(k, v.toJson()))));
  }

  List<DailyStats> getDailyStatsForRange(DateTime start, DateTime end) {
    final all = getAllDailyStats();
    final result = <DailyStats>[];
    var current = DateTime(start.year, start.month, start.day);
    final endDay = DateTime(end.year, end.month, end.day);
    while (!current.isAfter(endDay)) {
      final key = _dateKey(current);
      if (all.containsKey(key)) {
        result.add(all[key]!);
      }
      current = current.add(const Duration(days: 1));
    }
    return result;
  }

  void clearAllDailyStats() {
    _prefs.remove(_dailyStatsKey);
  }

  // --- App Config ---

  AppConfig getAppConfig() {
    final raw = _prefs.getString(_appConfigKey);
    if (raw == null) return const AppConfig();
    return AppConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void saveAppConfig(AppConfig config) {
    _prefs.setString(_appConfigKey, jsonEncode(config.toJson()));
  }

  // --- User Goal ---

  UserGoal getUserGoal() {
    final raw = _prefs.getString(_userGoalKey);
    if (raw == null) return UserGoal(createdAt: DateTime.now());
    return UserGoal.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void saveUserGoal(UserGoal goal) {
    _prefs.setString(_userGoalKey, jsonEncode(goal.toJson()));
  }

  // --- Export Data ---

  String exportAllDataAsJson() {
    final data = {
      'videoEvents': getAllVideoEvents().map((e) => e.toJson()).toList(),
      'dailyStats': getAllDailyStats().map((k, v) => MapEntry(k, v.toJson())),
      'appConfig': getAppConfig().toJson(),
      'userGoal': getUserGoal().toJson(),
    };
    return jsonEncode(data);
  }

  void importDataFromJson(String json) {
    final data = jsonDecode(json) as Map<String, dynamic>;
    if (data.containsKey('appConfig')) {
      saveAppConfig(AppConfig.fromJson(data['appConfig'] as Map<String, dynamic>));
    }
    if (data.containsKey('userGoal')) {
      saveUserGoal(UserGoal.fromJson(data['userGoal'] as Map<String, dynamic>));
    }
  }

  void clearAllData() {
    _prefs.remove(_videoEventsKey);
    _prefs.remove(_dailyStatsKey);
    _prefs.remove(_appConfigKey);
    _prefs.remove(_userGoalKey);
  }

  String _dateKey(DateTime date) =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}
