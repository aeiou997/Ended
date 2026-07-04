/// Aggregate statistics for a single day, stored per day.
class DailyStats {
  final DateTime date;
  final int totalVideos;
  final Duration totalWatchTime;
  final Map<String, int> platformCounts; // platformId -> count
  final Map<String, Duration> platformWatchTime; // platformId -> duration
  final Duration longestSession;
  final int sessionsCount;

  const DailyStats({
    required this.date,
    this.totalVideos = 0,
    this.totalWatchTime = Duration.zero,
    this.platformCounts = const {},
    this.platformWatchTime = const {},
    this.longestSession = Duration.zero,
    this.sessionsCount = 0,
  });

  DailyStats copyWith({
    DateTime? date,
    int? totalVideos,
    Duration? totalWatchTime,
    Map<String, int>? platformCounts,
    Map<String, Duration>? platformWatchTime,
    Duration? longestSession,
    int? sessionsCount,
  }) {
    return DailyStats(
      date: date ?? this.date,
      totalVideos: totalVideos ?? this.totalVideos,
      totalWatchTime: totalWatchTime ?? this.totalWatchTime,
      platformCounts: platformCounts ?? this.platformCounts,
      platformWatchTime: platformWatchTime ?? this.platformWatchTime,
      longestSession: longestSession ?? this.longestSession,
      sessionsCount: sessionsCount ?? this.sessionsCount,
    );
  }

  /// Date key in YYYY-MM-DD format for lookups
  String get dateKey => '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  double get totalWatchTimeHours => totalWatchTime.inSeconds / 3600;

  double get averageSessionMinutes =>
      sessionsCount > 0 ? totalWatchTime.inMinutes / sessionsCount : 0;

  Map<String, dynamic> toJson() => {
    'date': date.millisecondsSinceEpoch,
    'totalVideos': totalVideos,
    'totalWatchTimeMs': totalWatchTime.inMilliseconds,
    'platformCounts': platformCounts,
    'platformWatchTimeMs': platformWatchTime.map((k, v) => MapEntry(k, v.inMilliseconds)),
    'longestSessionMs': longestSession.inMilliseconds,
    'sessionsCount': sessionsCount,
  };

  factory DailyStats.fromJson(Map<String, dynamic> json) => DailyStats(
    date: DateTime.fromMillisecondsSinceEpoch(json['date'] as int),
    totalVideos: json['totalVideos'] as int? ?? 0,
    totalWatchTime: Duration(milliseconds: json['totalWatchTimeMs'] as int? ?? 0),
    platformCounts: Map<String, int>.from(json['platformCounts'] as Map? ?? {}),
    platformWatchTime: (json['platformWatchTimeMs'] as Map?)?.map(
      (k, v) => MapEntry(k as String, Duration(milliseconds: v as int)),
    ) ?? {},
    longestSession: Duration(milliseconds: json['longestSessionMs'] as int? ?? 0),
    sessionsCount: json['sessionsCount'] as int? ?? 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyStats && runtimeType == other.runtimeType && dateKey == other.dateKey;

  @override
  int get hashCode => dateKey.hashCode;
}
