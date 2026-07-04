/// App configuration: which platforms are monitored, user preferences.
class AppConfig {
  final bool monitoringEnabled;
  final Map<String, bool> platformEnabled; // platformId -> enabled
  final bool darkMode;
  final bool notificationsEnabled;
  final int reminderVideoThreshold; // e.g., 50 videos
  final int reminderTimeThresholdMinutes; // e.g., 30 minutes
  final bool onboardingComplete;
  final String themeMode; // 'system', 'light', 'dark'

  const AppConfig({
    this.monitoringEnabled = true,
    this.platformEnabled = const {
      'instagram': true,
      'youtube': true,
      'facebook': false,
      'snapchat': false,
    },
    this.darkMode = false,
    this.notificationsEnabled = true,
    this.reminderVideoThreshold = 50,
    this.reminderTimeThresholdMinutes = 30,
    this.onboardingComplete = false,
    this.themeMode = 'system',
  });

  AppConfig copyWith({
    bool? monitoringEnabled,
    Map<String, bool>? platformEnabled,
    bool? darkMode,
    bool? notificationsEnabled,
    int? reminderVideoThreshold,
    int? reminderTimeThresholdMinutes,
    bool? onboardingComplete,
    String? themeMode,
  }) {
    return AppConfig(
      monitoringEnabled: monitoringEnabled ?? this.monitoringEnabled,
      platformEnabled: platformEnabled ?? this.platformEnabled,
      darkMode: darkMode ?? this.darkMode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      reminderVideoThreshold: reminderVideoThreshold ?? this.reminderVideoThreshold,
      reminderTimeThresholdMinutes: reminderTimeThresholdMinutes ?? this.reminderTimeThresholdMinutes,
      onboardingComplete: onboardingComplete ?? this.onboardingComplete,
      themeMode: themeMode ?? this.themeMode,
    );
  }

  List<String> get enabledPlatformIds =>
      platformEnabled.entries.where((e) => e.value).map((e) => e.key).toList();

  Map<String, dynamic> toJson() => {
    'monitoringEnabled': monitoringEnabled,
    'platformEnabled': platformEnabled,
    'darkMode': darkMode,
    'notificationsEnabled': notificationsEnabled,
    'reminderVideoThreshold': reminderVideoThreshold,
    'reminderTimeThresholdMinutes': reminderTimeThresholdMinutes,
    'onboardingComplete': onboardingComplete,
    'themeMode': themeMode,
  };

  factory AppConfig.fromJson(Map<String, dynamic> json) => AppConfig(
    monitoringEnabled: json['monitoringEnabled'] as bool? ?? true,
    platformEnabled: Map<String, bool>.from(json['platformEnabled'] as Map? ??
        const {'instagram': true, 'youtube': true, 'facebook': false, 'snapchat': false}),
    darkMode: json['darkMode'] as bool? ?? false,
    notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
    reminderVideoThreshold: json['reminderVideoThreshold'] as int? ?? 50,
    reminderTimeThresholdMinutes: json['reminderTimeThresholdMinutes'] as int? ?? 30,
    onboardingComplete: json['onboardingComplete'] as bool? ?? false,
    themeMode: json['themeMode'] as String? ?? 'system',
  );
}
