import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ended/data/datasources/local/local_data_source.dart';
import 'package:ended/data/repositories/app_repository.dart';
import 'package:ended/data/models/app_config.dart';
import 'package:ended/data/models/user_goal.dart';
import 'package:ended/data/models/daily_stats.dart';
import 'package:ended/core/services/monitoring/monitoring_service.dart';
import 'package:ended/core/services/notifications/notification_service.dart';

// ── Base providers ──

final sharedPreferencesProvider = FutureProvider<SharedPreferences>((ref) async {
  return await SharedPreferences.getInstance();
});

final localDataSourceProvider = FutureProvider<LocalDataSource>((ref) async {
  final prefs = await ref.watch(sharedPreferencesProvider.future);
  return LocalDataSource(prefs);
});

final repositoryProvider = FutureProvider<AppRepository>((ref) async {
  final ds = await ref.watch(localDataSourceProvider.future);
  return AppRepository(ds);
});

// ── Config ──

final appConfigProvider = StateNotifierProvider<AppConfigNotifier, AppConfig>((ref) {
  return AppConfigNotifier(ref);
});

class AppConfigNotifier extends StateNotifier<AppConfig> {
  final Ref _ref;
  AppConfigNotifier(this._ref) : super(const AppConfig()) {
    _loadConfig();
  }

  Future<void> _loadConfig() async {
    final repo = await _ref.read(repositoryProvider.future);
    state = repo.getAppConfig();
  }

  Future<void> updateConfig(AppConfig config) async {
    state = config;
    final repo = await _ref.read(repositoryProvider.future);
    await repo.saveAppConfig(config);
  }

  Future<void> togglePlatform(String platformId, bool enabled) async {
    final newPlatformEnabled = Map<String, bool>.from(state.platformEnabled);
    newPlatformEnabled[platformId] = enabled;
    await updateConfig(state.copyWith(platformEnabled: newPlatformEnabled));
  }

  Future<void> setMonitoringEnabled(bool value) async {
    await updateConfig(state.copyWith(monitoringEnabled: value));
  }

  Future<void> setThemeMode(String mode) async {
    await updateConfig(state.copyWith(themeMode: mode));
  }

  Future<void> setNotificationsEnabled(bool value) async {
    await updateConfig(state.copyWith(notificationsEnabled: value));
  }

  Future<void> setOnboardingComplete() async {
    await updateConfig(state.copyWith(onboardingComplete: true));
  }
}

// ── User Goal ──

final userGoalProvider = StateNotifierProvider<UserGoalNotifier, UserGoal>((ref) {
  return UserGoalNotifier(ref);
});

class UserGoalNotifier extends StateNotifier<UserGoal> {
  final Ref _ref;
  UserGoalNotifier(this._ref) : super(const UserGoal()) {
    _loadGoal();
  }

  Future<void> _loadGoal() async {
    final repo = await _ref.read(repositoryProvider.future);
    state = repo.getUserGoal();
  }

  Future<void> updateGoal(UserGoal goal) async {
    state = goal;
    final repo = await _ref.read(repositoryProvider.future);
    await repo.saveUserGoal(goal);
  }

  Future<void> setVideoLimit(int limit) async {
    await updateGoal(state.copyWith(maxVideosPerDay: limit));
  }

  Future<void> setTimeLimit(int minutes) async {
    await updateGoal(state.copyWith(maxWatchTimeMinutesPerDay: minutes));
  }
}

// ── Daily Stats ──

final todayStatsProvider = FutureProvider<DailyStats?>((ref) async {
  final repo = await ref.read(repositoryProvider.future);
  return repo.getDailyStats(DateTime.now());
});

final weeklyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final repo = await ref.read(repositoryProvider.future);
  return repo.getWeeklyStats(DateTime.now());
});

final monthlyStatsProvider = FutureProvider<List<DailyStats>>((ref) async {
  final repo = await ref.read(repositoryProvider.future);
  return repo.getMonthlyStats(DateTime.now());
});

final yesterdayStatsProvider = FutureProvider<DailyStats?>((ref) async {
  final repo = await ref.read(repositoryProvider.future);
  return repo.getDailyStats(DateTime.now().subtract(const Duration(days: 1)));
});

// ── Monitoring ──

final monitoringServiceProvider = FutureProvider<MonitoringService>((ref) async {
  final repo = await ref.read(repositoryProvider.future);
  return MonitoringService(repo);
});

final isMonitoringRunningProvider = StateProvider<bool>((ref) => false);

// ── Notification ──

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

// ── Dashboardcomputed values ──

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) async {
  final todayAsync = ref.watch(todayStatsProvider);
  final yesterdayAsync = ref.watch(yesterdayStatsProvider);
  final goalAsync = ref.watch(userGoalProvider);

  final today = await todayAsync.when(
    data: (d) => d,
    loading: () => null,
    error: (_, __) => null,
  );
  final yesterday = await yesterdayAsync.when(
    data: (d) => d,
    loading: () => null,
    error: (_, __) => null,
  );
  final goal = goalAsync;

  final totalVideos = today?.totalVideos ?? 0;
  final yesterdayVideos = yesterday?.totalVideos ?? 0;
  final watchTime = today?.totalWatchTime ?? Duration.zero;
  final goalLimit = goal.maxVideosPerDay;
  final remaining = goal.remainingVideos(totalVideos);
  final streak = goal.streakDays;
  final progress = goal.videoProgress(totalVideos);
  final percentVsYesterday = yesterdayVideos > 0
      ? ((totalVideos - yesterdayVideos) / yesterdayVideos * 100)
      : 0.0;

  // Per-platform
  final instagram = today?.platformCounts['instagram'] ?? 0;
  final youtube = today?.platformCounts['youtube'] ?? 0;
  final facebook = today?.platformCounts['facebook'] ?? 0;
  final snapchat = today?.platformCounts['snapchat'] ?? 0;

  // Weekly/monthly
  final repo = await ref.read(repositoryProvider.future);
  final weekly = repo.getWeeklyStats(DateTime.now());
  final monthly = repo.getMonthlyStats(DateTime.now());
  final weeklyTotal = weekly.fold<int>(0, (acc, d) => acc + d.totalVideos);
  final monthlyTotal = monthly.fold<int>(0, (acc, d) => acc + d.totalVideos);

  return DashboardData(
    totalVideos: totalVideos,
    watchTime: watchTime,
    instagramCount: instagram,
    youtubeCount: youtube,
    facebookCount: facebook,
    snapchatCount: snapchat,
    weeklyTotal: weeklyTotal,
    monthlyTotal: monthlyTotal,
    goalLimit: goalLimit,
    remaining: remaining,
    streak: streak,
    progress: progress,
    percentVsYesterday: percentVsYesterday,
  );
});

class DashboardData {
  final int totalVideos;
  final Duration watchTime;
  final int instagramCount;
  final int youtubeCount;
  final int facebookCount;
  final int snapchatCount;
  final int weeklyTotal;
  final int monthlyTotal;
  final int goalLimit;
  final int remaining;
  final int streak;
  final double progress;
  final double percentVsYesterday;

  const DashboardData({
    this.totalVideos = 0,
    this.watchTime = Duration.zero,
    this.instagramCount = 0,
    this.youtubeCount = 0,
    this.facebookCount = 0,
    this.snapchatCount = 0,
    this.weeklyTotal = 0,
    this.monthlyTotal = 0,
    this.goalLimit = 50,
    this.remaining = 50,
    this.streak = 0,
    this.progress = 0,
    this.percentVsYesterday = 0,
  });
}
