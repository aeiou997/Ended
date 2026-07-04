/// Represents a single video watch event detected by the monitoring service.
class VideoEvent {
  final String id;
  final String platformId; // 'instagram', 'youtube', 'facebook', 'snapchat'
  final String? videoIdentifier; // Unique ID from the platform if available
  final DateTime timestamp;
  final Duration watchDuration;
  final bool counted; // Whether this event was counted toward daily total

  const VideoEvent({
    required this.id,
    required this.platformId,
    this.videoIdentifier,
    required this.timestamp,
    this.watchDuration = Duration.zero,
    this.counted = true,
  });

  /// Creates a dedup key: platformId + videoIdentifier or timestamp minute
  /// Used to prevent counting the same video twice
  String get dedupKey {
    if (videoIdentifier != null && videoIdentifier!.isNotEmpty) {
      return '${platformId}_$videoIdentifier';
    }
    // Fallback: use platform + minute-level timestamp as heuristic
    final minuteKey = timestamp.millisecondsSinceEpoch ~/ 60000;
    return '${platformId}_$minuteKey';
  }

  VideoEvent copyWith({
    String? id,
    String? platformId,
    String? videoIdentifier,
    DateTime? timestamp,
    Duration? watchDuration,
    bool? counted,
  }) {
    return VideoEvent(
      id: id ?? this.id,
      platformId: platformId ?? this.platformId,
      videoIdentifier: videoIdentifier ?? this.videoIdentifier,
      timestamp: timestamp ?? this.timestamp,
      watchDuration: watchDuration ?? this.watchDuration,
      counted: counted ?? this.counted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'platformId': platformId,
    'videoIdentifier': videoIdentifier,
    'timestamp': timestamp.millisecondsSinceEpoch,
    'watchDurationMs': watchDuration.inMilliseconds,
    'counted': counted,
  };

  factory VideoEvent.fromJson(Map<String, dynamic> json) => VideoEvent(
    id: json['id'] as String,
    platformId: json['platformId'] as String,
    videoIdentifier: json['videoIdentifier'] as String?,
    timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    watchDuration: Duration(milliseconds: json['watchDurationMs'] as int),
    counted: json['counted'] as bool? ?? true,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VideoEvent && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
