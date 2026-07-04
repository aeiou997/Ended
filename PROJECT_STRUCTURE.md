# Ended — Flutter Project Structure

> **Tagline:** Know when enough is enough.
> **Package:** `com.ended.app`
> **Min SDK:** 21 (Android 5.0)
> **Target SDK:** 34 (Android 14)

---

## Directory Tree

```
ended_app/
├── android/                          # Android platform layer
│   ├── app/
│   │   ├── build.gradle
│   │   └── src/main/
│   │       ├── AndroidManifest.xml           # Permissions, services, activities
│   │       ├── java/com/ended/app/
│   │       │   ├── MainActivity.kt           # FlutterActivity host
│   │       │   ├── EndedAccessibilityService.kt  # Accessibility Service
│   │       │   └── UsageStatsMonitor.kt      # UsageStatsManager bridge
│   │       └── res/                          # Launcher icon, splash drawable
│   ├── build.gradle                        # Root Gradle config
│   └── settings.gradle
│
├── assets/
│   ├── images/
│   │   ├── logo.png                         # App icon (adaptive)
│   │   ├── splash.png                       # Splash screen background
│   │   └── empty_state.png                  # Empty history illustration
│   └── fonts/                               # Custom fonts (optional override)
│
├── lib/
│   ├── main.dart                            # 🚀 App entry point
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── app_colors.dart              # Material 3 color palette
│   │   │   └── app_constants.dart           # Platform configs, app metadata
│   │   ├── theme/
│   │   │   └── app_theme.dart               # ThemeData.light / ThemeData.dark
│   │   ├── providers/
│   │   │   └── app_providers.dart           # All Riverpod providers
│   │   └── services/
│   │       ├── monitoring/
│   │       │   └── monitoring_service.dart   # UsageStats polling logic
│   │       ├── notifications/
│   │       │   └── notification_service.dart # Local notification scheduling
│   │       └── permissions/
│   │           └── permission_service.dart   # Android permission requests
│   │
│   ├── data/
│   │   ├── models/
│   │   │   ├── video_event.dart             # Raw video watch event
│   │   │   ├── daily_stats.dart             # Aggregated daily stats
│   │   │   ├── app_config.dart              # User preferences / settings
│   │   │   └── user_goal.dart               # Daily goal, streak, achievements
│   │   ├── repositories/
│   │   │   └── app_repository.dart          # Repository interface
│   │   └── datasources/local/
│   │       └── local_data_source.dart       # SharedPreferences / Hive impl
│   │
│   ├── features/
│   │   ├── onboarding/presentation/screens/
│   │   │   └── onboarding_screen.dart       # 4-page intro flow
│   │   ├── dashboard/presentation/screens/
│   │   │   └── dashboard_screen.dart        # Home: today's count, badge, ring
│   │   ├── statistics/presentation/screens/
│   │   │   └── statistics_screen.dart       # FL Chart: daily/weekly/monthly
│   │   ├── history/presentation/screens/
│   │   │   └── history_screen.dart          # 3-tab: Daily / Weekly / Monthly
│   │   └── settings/presentation/screens/
│   │       └── settings_screen.dart         # All app settings sections
│   │
│   └── shared/widgets/
│       ├── main_shell.dart                  # Bottom nav scaffold (4 tabs)
│       └── platform_badge.dart              # Platform icon + count chip
│
├── test/
│   └── core/
│       └── models_test.dart                 # 17 unit tests
│
├── pubspec.yaml                            # Dependencies + metadata
├── analysis_options.yaml                   # Dart lint rules
├── .gitignore
└── README.md                               # Setup + build instructions
```

---

## Layer Breakdown

### 1. Presentation Layer (`lib/features/`)
Each feature follows the **MVVM-ish** structure:
```
feature/
└── presentation/
    └── screens/
        └── <feature>_screen.dart    # Stateless/Stateful widget
```

- **Dashboard** — total count ring, per-platform badges, streak, weekly/monthly
- **Statistics** — FL Chart `BarChart` (7-day), `LineChart` (weekly trend), summary metrics
- **History** — `DefaultTabController` with Daily / Weekly / Monthly tabs + CSV export
- **Settings** — toggles, sliders, permission button, theme switcher, data management
- **Onboarding** — `PageView` with 4 pages: Welcome → How It Works → Permissions → Ready

### 2. Business Logic Layer (`lib/core/providers/`)
Single file: `app_providers.dart`

| Provider | Type | State |
|---|---|---|
| `appConfigProvider` | `StateNotifierProvider` | `AppConfig` |
| `userGoalProvider` | `StateNotifierProvider` | `UserGoal` |
| `todayStatsProvider` | `FutureProvider` | `DailyStats?` |
| `yesterdayStatsProvider` | `FutureProvider` | `DailyStats?` |
| `weeklyStatsProvider` | `FutureProvider` | `List<DailyStats>` |
| `monthlyStatsProvider` | `FutureProvider` | `List<DailyStats>` |
| `platformStatsProvider` | `FutureProvider.family` | `DailyStats?` |

### 3. Repository Layer (`lib/data/repositories/`)
`AppRepository` — abstract interface with:
- `getTodayStats()`, `getStatsForDate()`, `getRangeStats()`
- `saveVideoEvent()`, `getVideoEvents()`
- `getConfig()`, `saveConfig()`
- `getUserGoal()`, `saveUserGoal()`

### 4. Data Layer (`lib/data/`)
| Model | Fields |
|---|---|
| `VideoEvent` | `id`, `platformId`, `videoIdentifier`, `timestamp`, `watchDuration`, `isUnique` |
| `DailyStats` | `dateKey`, `totalVideos`, `totalWatchTime`, `platformCounts`, `platformWatchTime` |
| `AppConfig` | `monitoringEnabled`, `platformEnabled`, `themeMode`, `notificationsEnabled` |
| `UserGoal` | `maxVideosPerDay`, `maxWatchTimeMinutesPerDay`, `streakDays`, `achievements` |

**Persistence:** SharedPreferences (prototype) → Hive (production). Box names in `AppConstants`.

### 5. Service Layer (`lib/core/services/`)
| Service | Responsibility |
|---|---|
| `MonitoringService` | Polls UsageStatsManager every 15 min; estimates video count from session duration |
| `NotificationService` | Schedules daily reminders, goal alerts, streak celebrations |
| `PermissionService` | Requests Usage Stats + Notification; opens system settings when needed |

### 6. Background Monitoring Layer
- **Primary:** `UsageStatsManager` via platform channel — polls app usage events
- **Fallback (opt-in):** `AccessibilityService` (Android) — detects scrolling within supported apps
- **Deduplication:** `VideoEvent` has a `dedupKey = hash(videoId + timestamp-minute)` to prevent recounting the same reel

---

## Data Flow

```
┌─────────────────────────────────────────────────────────┐
│  Background Monitoring (Platform Channel)                │
│  UsageStatsManager → method channel → Dart               │
└────────────────────────┬────────────────────────────────┘
                         │ VideoEvent
                         ▼
┌─────────────────────────────────────────────────────────┐
│  AppRepository                                           │
│  deduplicate() → nightly rollup → DailyStats             │
└────────────────────────┬────────────────────────────────┘
                         │ DailyStats
                         ▼
┌─────────────────────────────────────────────────────────┐
│  Riverpod Providers                                      │
│  todayStatsProvider, weeklyStatsProvider, etc.           │
└────────────────────────┬────────────────────────────────┘
                         │ Stream / Future
                         ▼
┌─────────────────────────────────────────────────────────┐
│  UI Screens                                              │
│  Dashboard, Statistics, History, Settings                │
└─────────────────────────────────────────────────────────┘
```

---

## Key Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_riverpod: ^2.4.9       # State management
  go_router: ^13.0.0             # Navigation
  fl_chart: ^0.67.0              # Charts
  google_fonts: ^6.1.0           # Inter font
  percent_indicator: ^4.2.3      # Circular progress ring
  shared_preferences: ^2.2.2     # Local persistence
  permission_handler: ^11.3.0    # Runtime permissions
  flutter_local_notifications: ^16.3.0
  intl: ^0.18.1                  # Date formatting
  path_provider: ^2.1.2          # File paths for export
  csv: ^5.1.0                    # CSV export
```

---

## Build Config

| Command | Purpose |
|---|---|
| `flutter pub get` | Install dependencies |
| `flutter test` | Run 17 unit tests |
| `flutter analyze` | Lint + type check |
| `flutter build apk --debug` | Debug APK |
| `flutter build apk --release` | Production APK |
| `flutter run` | Run on connected device |

---

## Limitations & Disclaimers

1. **Exact reel identification** is restricted by Instagram/YouTube/etc. We estimate video count from session duration (~1 video per 30s).
2. **Accessibility Service** requires user opt-in and app restart — not all OEMs allow it.
3. **Foreground service** notification is shown during active monitoring on Android 14+.
4. **No cloud sync** — all data stays on-device by default.

---

*Generated for the Ended project — `/root/ended_app/`*
