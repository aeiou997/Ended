/// User daily goals for reducing scroll time.
class UserGoal {
  final int maxVideosPerDay;
  final int maxWatchTimeMinutesPerDay;
  final int streakDays;
  final DateTime? streakStartDate;
  final DateTime? lastGoalMetDate;
  final List<String> achievements;
  final DateTime? createdAt;

  const UserGoal({
    this.maxVideosPerDay = 50,
    this.maxWatchTimeMinutesPerDay = 60,
    this.streakDays = 0,
    this.streakStartDate,
    this.lastGoalMetDate,
    this.achievements = const [],
    this.createdAt,
  });

  UserGoal copyWith({
    int? maxVideosPerDay,
    int? maxWatchTimeMinutesPerDay,
    int? streakDays,
    DateTime? streakStartDate,
    DateTime? lastGoalMetDate,
    List<String>? achievements,
  }) {
    return UserGoal(
      maxVideosPerDay: maxVideosPerDay ?? this.maxVideosPerDay,
      maxWatchTimeMinutesPerDay: maxWatchTimeMinutesPerDay ?? this.maxWatchTimeMinutesPerDay,
      streakDays: streakDays ?? this.streakDays,
      streakStartDate: streakStartDate ?? this.streakStartDate,
      lastGoalMetDate: lastGoalMetDate ?? this.lastGoalMetDate,
      achievements: achievements ?? this.achievements,
    );
  }

  /// Calculate progress toward video goal (0.0 to 1.0+)
  double videoProgress(int videosWatched) {
    if (maxVideosPerDay <= 0) return 0;
    return videosWatched / maxVideosPerDay;
  }

  /// Calculate progress toward time goal (0.0 to 1.0+)
  double timeProgress(int minutesWatched) {
    if (maxWatchTimeMinutesPerDay <= 0) return 0;
    return minutesWatched / maxWatchTimeMinutesPerDay;
  }

  /// Remaining videos before goal limit
  int remainingVideos(int videosWatched) {
    return (maxVideosPerDay - videosWatched).clamp(0, maxVideosPerDay);
  }

  /// Remaining time before goal limit
  int remainingMinutes(int minutesWatched) {
    return (maxWatchTimeMinutesPerDay - minutesWatched).clamp(0, maxWatchTimeMinutesPerDay);
  }

  /// Whether the user met their goal today
  bool isGoalMet(int videosWatched, int minutesWatched) {
    return videosWatched <= maxVideosPerDay && minutesWatched <= maxWatchTimeMinutesPerDay;
  }

  /// Update streak — call once per day at end of day
  UserGoal updateStreak(bool metGoalToday) {
    if (metGoalToday) {
      final now = DateTime.now();
      final newStreak = streakDays + 1;
      final newAchievements = List<String>.from(achievements);
      // Achievement milestones
      if (newStreak == 3 && !newAchievements.contains('streak_3')) {
        newAchievements.add('streak_3');
      }
      if (newStreak == 7 && !newAchievements.contains('streak_7')) {
        newAchievements.add('streak_7');
      }
      if (newStreak == 14 && !newAchievements.contains('streak_14')) {
        newAchievements.add('streak_14');
      }
      if (newStreak == 30 && !newAchievements.contains('streak_30')) {
        newAchievements.add('streak_30');
      }
      return copyWith(
        streakDays: newStreak,
        lastGoalMetDate: now,
        achievements: newAchievements,
      );
    } else {
      // Streak broken
      return copyWith(streakDays: 0);
    }
  }

  Map<String, dynamic> toJson() => {
    'maxVideosPerDay': maxVideosPerDay,
    'maxWatchTimeMinutesPerDay': maxWatchTimeMinutesPerDay,
    'streakDays': streakDays,
    'streakStartDate': streakStartDate?.millisecondsSinceEpoch,
    'lastGoalMetDate': lastGoalMetDate?.millisecondsSinceEpoch,
    'achievements': achievements,
  };

  factory UserGoal.fromJson(Map<String, dynamic> json) => UserGoal(
    maxVideosPerDay: json['maxVideosPerDay'] as int? ?? 50,
    maxWatchTimeMinutesPerDay: json['maxWatchTimeMinutesPerDay'] as int? ?? 60,
    streakDays: json['streakDays'] as int? ?? 0,
    streakStartDate: json['streakStartDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['streakStartDate'] as int)
        : null,
    lastGoalMetDate: json['lastGoalMetDate'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['lastGoalMetDate'] as int)
        : null,
    achievements: List<String>.from(json['achievements'] as List? ?? []),
  );
}
