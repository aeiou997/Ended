import 'package:flutter_test/flutter_test.dart';
import 'package:ended/data/models/video_event.dart';
import 'package:ended/data/models/daily_stats.dart';
import 'package:ended/data/models/app_config.dart';
import 'package:ended/data/models/user_goal.dart';

void main() {
  group('VideoEvent', () {
    test('dedup key uses videoIdentifier when available', () {
      final event = VideoEvent(
        id: '1',
        platformId: 'instagram',
        videoIdentifier: 'reel_abc123',
        timestamp: DateTime(2025, 7, 2, 10, 30),
      );
      expect(event.dedupKey, 'instagram_reel_abc123');
    });

    test('dedup key uses minute-level timestamp when no videoIdentifier', () {
      final event = VideoEvent(
        id: '2',
        platformId: 'youtube',
        timestamp: DateTime(2025, 7, 2, 14, 25, 0),
      );
      // Should be youtube_minuteKey
      expect(event.dedupKey, startsWith('youtube_'));
    });

    test('toJson/fromJson round-trip preserves data', () {
      final event = VideoEvent(
        id: '3',
        platformId: 'facebook',
        videoIdentifier: 'vid_xyz',
        timestamp: DateTime(2025, 7, 2),
        watchDuration: const Duration(seconds: 45),
        counted: true,
      );
      final json = event.toJson();
      final restored = VideoEvent.fromJson(json);
      expect(restored.id, event.id);
      expect(restored.platformId, event.platformId);
      expect(restored.videoIdentifier, event.videoIdentifier);
      expect(restored.counted, event.counted);
      expect(restored.watchDuration, event.watchDuration);
    });

    test('two events with same dedupKey should be detectable', () {
      final t = DateTime(2025, 7, 2, 10, 30);
      final e1 = VideoEvent(id: 'a', platformId: 'instagram', videoIdentifier: 'x', timestamp: t);
      final e2 = VideoEvent(id: 'b', platformId: 'instagram', videoIdentifier: 'x', timestamp: t);
      expect(e1.dedupKey, e2.dedupKey);
    });

    test('different platform same identifier produces different dedupKey', () {
      final t = DateTime(2025, 7, 2, 10, 30);
      final e1 = VideoEvent(id: 'a', platformId: 'instagram', videoIdentifier: 'x', timestamp: t);
      final e2 = VideoEvent(id: 'b', platformId: 'youtube', videoIdentifier: 'x', timestamp: t);
      expect(e1.dedupKey, isNot(equals(e2.dedupKey)));
    });
  });

  group('DailyStats', () {
    test('dateKey formats correctly', () {
      final stats = DailyStats(date: DateTime(2025, 7, 2));
      expect(stats.dateKey, '2025-07-02');
    });

    test('totalWatchTimeHours calculates correctly', () {
      final stats = DailyStats(
        date: DateTime(2025, 7, 2),
        totalWatchTime: const Duration(hours: 1, minutes: 30),
      );
      expect(stats.totalWatchTimeHours, closeTo(1.5, 0.01));
    });

    test('toJson/fromJson round-trip', () {
      final stats = DailyStats(
        date: DateTime(2025, 7, 2),
        totalVideos: 42,
        totalWatchTime: const Duration(minutes: 90),
        platformCounts: {'instagram': 20, 'youtube': 22},
        sessionsCount: 5,
      );
      final json = stats.toJson();
      final restored = DailyStats.fromJson(json);
      expect(restored.totalVideos, 42);
      expect(restored.platformCounts['instagram'], 20);
      expect(restored.sessionsCount, 5);
    });
  });

  group('AppConfig', () {
    test('default values are correct', () {
      const config = AppConfig();
      expect(config.monitoringEnabled, true);
      expect(config.platformEnabled['instagram'], true);
      expect(config.platformEnabled['youtube'], true);
      expect(config.platformEnabled['facebook'], false);
      expect(config.onboardingComplete, false);
    });

    test('enabledPlatformIds returns correct list', () {
      const config = AppConfig(platformEnabled: {
        'instagram': true, 'youtube': true, 'facebook': false, 'snapchat': false,
      });
      expect(config.enabledPlatformIds, ['instagram', 'youtube']);
    });

    test('copyWith works correctly', () {
      const config = AppConfig();
      final updated = config.copyWith(monitoringEnabled: false, themeMode: 'dark');
      expect(updated.monitoringEnabled, false);
      expect(updated.themeMode, 'dark');
      expect(updated.platformEnabled, config.platformEnabled); // unchanged
    });
  });

  group('UserGoal', () {
    test('videoProgress calculates correctly', () {
      const goal = UserGoal(maxVideosPerDay: 50);
      expect(goal.videoProgress(25), 0.5);
      expect(goal.videoProgress(50), 1.0);
      expect(goal.videoProgress(75), 1.5);
    });

    test('remainingVideos clamps to 0', () {
      const goal = UserGoal(maxVideosPerDay: 50);
      expect(goal.remainingVideos(30), 20);
      expect(goal.remainingVideos(50), 0);
      expect(goal.remainingVideos(60), 0); // can't go negative
    });

    test('isGoalMet checks both video and time limits', () {
      const goal = UserGoal(maxVideosPerDay: 50, maxWatchTimeMinutesPerDay: 60);
      expect(goal.isGoalMet(30, 30), true);
      expect(goal.isGoalMet(60, 30), false); // over video limit
      expect(goal.isGoalMet(30, 70), false); // over time limit
    });

    test('updateStreak increments on goal met', () {
      const goal = UserGoal(streakDays: 2);
      final updated = goal.updateStreak(true);
      expect(updated.streakDays, 3);
    });

    test('updateStreak resets on goal not met', () {
      const goal = UserGoal(streakDays: 5);
      final updated = goal.updateStreak(false);
      expect(updated.streakDays, 0);
    });

    test('achievement at 3-day streak', () {
      const goal = UserGoal(streakDays: 2);
      final updated = goal.updateStreak(true);
      expect(updated.achievements.contains('streak_3'), true);
    });
  });
}
