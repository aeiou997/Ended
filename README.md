# ⏳ Ended — "Know when enough is enough."

A modern Android application that helps users reduce social media addiction by tracking how many short-form videos they watch across supported platforms.

---

## 📱 Features

| Feature | Description |
|---------|-------------|
| **Video Counting** | Automatically detects and counts short-form videos watched |
| **Multi-Platform** | Instagram Reels, YouTube Shorts, Facebook Reels, Snapchat Spotlight |
| **Dashboard** | Today's count, watch time, platform breakdown, progress ring |
| **Statistics** | Daily/weekly/monthly charts, key metrics, trends |
| **History** | Browse past data, search dates, export as CSV/PDF |
| **Daily Goals** | Set video & time limits, track streaks, earn achievements |
| **Notifications** | Smart reminders when over-scrolling |
| **Privacy-First** | All data on-device, no cloud, no ads, no content tracking |
| **Dark Mode** | Full Material Design 3 with light/dark themes |

---

## 🏗️ Architecture

```
lib/
├── core/
│   ├── constants/          # AppConstants, AppColors
│   ├── theme/              # AppTheme (Material 3, light + dark)
│   ├── services/
│   │   ├── monitoring/     # MonitoringService (background detection)
│   │   ├── notifications/  # NotificationService (local reminders)
│   │   └── permissions/    # PermissionService (Android perms)
│   └── providers/          # Riverpod state management
├── data/
│   ├── models/             # VideoEvent, DailyStats, AppConfig, UserGoal
│   ├── datasources/local/  # LocalDataSource (SharedPreferences)
│   └── repositories/       # AppRepository (clean architecture)
├── features/
│   ├── dashboard/          # Home screen with progress ring
│   ├── statistics/         # Charts & metrics (FL Chart)
│   ├── history/            # Daily/weekly/monthly history
│   ├── settings/           # All app settings
│   └── onboarding/         # 4-page onboarding flow
├── shared/widgets/         # MainShell, PlatformBadge
└── main.dart               # App entry point
```

### Layers
1. **Presentation Layer** — Widgets, screens, UI
2. **Business Logic Layer** — Riverpod providers, state management
3. **Repository Layer** — AppRepository mediates data access
4. **Local Database Layer** — SharedPreferences (upgradeable to Hive)
5. **Service Layer** — Monitoring, notifications, permissions
6. **Background Monitoring Layer** — Android UsageStatsManager + Accessibility Service

---

## 🚀 Getting Started

### Prerequisites
- Flutter 3.27+ (Dart 3.2+)
- Android Studio / VS Code
- Android SDK 34+
- An Android device (emulator or physical)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/yourusername/ended.git
cd ended

# 2. Install dependencies
flutter pub get

# 3. Generate code (if using hive generators)
flutter pub run build_runner build

# 4. Run the app
flutter run
```

### First Run
1. Complete the 4-page onboarding
2. Grant **Usage Stats** permission (Settings → Security → Apps with usage access)
3. Grant **Notification** permission
4. Enable the platforms you want to monitor
5. Set your daily video & time goals

---

## ⚠️ Technical Limitations

This is critically important — the app is **honest about its limitations**:

| Limitation | Explanation |
|-----------|-------------|
| **Cannot identify individual videos** | Android doesn't expose video IDs from Instagram/YouTube/Facebook/Snapchat |
| **Counts are estimates** | Video count is estimated based on time in app ÷ average reel length (~30s) |
| **Accessibility Service limitations** | Cannot read reel/video content from supported apps |
| **No cross-app content access** | Each platform uses encrypted/dynamic view hierarchies |
| **Foreground Service required** | Android 12+ restricts background work; foreground notification is shown |
| **Battery impact** | Polling every 15s; uses ~1-2% battery per day |

### How We Estimate Videos

```
estimatedVideos = floor(secondsInForeground / 30)
```

This assumes an average short-form video is ~30 seconds. The app clearly labels these as **"estimated videos"**, not exact counts.

---

## 📊 Tech Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.27 |
| **Language** | Dart 3.2 |
| **State Management** | Riverpod |
| **Local Storage** | SharedPreferences (upgrade to Hive) |
| **Charts** | FL Chart |
| **Notifications** | flutter_local_notifications |
| **Background Work** | WorkManager + Foreground Service |
| **Android Native** | Kotlin |
| **Design** | Material Design 3 |
| **Fonts** | Google Fonts (Inter) |

---

## 🧪 Testing

```bash
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# Run integration tests
flutter test integration_test/
```

### Test Coverage
- ✅ VideoEvent model (dedup, serialization, equality)
- ✅ DailyStats model (dateKey, watch time, JSON round-trip)
- ✅ AppConfig model (defaults, enabledPlatforms, copyWith)
- ✅ UserGoal model (progress, remaining, streak, achievements)

---

## 📂 Project Structure

```
ended/
├── android/                    # Android native code
│   └── app/src/main/
│       ├── AndroidManifest.xml
│       ├── kotlin/com/ended/app/
│       │   ├── MonitoringForegroundService.kt
│       │   └── EndedAccessibilityService.kt
│       └── res/
│           ├── xml/accessibility_service_config.xml
│           └── values/strings.xml
├── assets/
│   ├── icons/
│   └── images/
├── lib/                        # Dart source code
│   ├── core/
│   ├── data/
│   ├── features/
│   ├── shared/
│   └── main.dart
├── test/                       # Unit tests
├── pubspec.yaml                # Dependencies
└── README.md                   # This file
```

---

## 🔒 Privacy Policy

- **All data stays on device** — no cloud, no sync
- **No internet permission** — the app cannot make network requests
- **No content tracking** — we never see what videos you watch
- **No advertisements** — ever
- **No analytics** — no Firebase, no Mixpanel, nothing
- **No accounts** — no sign-up required
- **You own your data** — export or delete anytime
- **Open permissions** — every permission is explained in the app

---

## 🎯 Roadmap (Future Features)

- [ ] AI-powered habit insights
- [ ] Weekly habit analysis & suggestions
- [ ] Cross-device sync (optional, end-to-end encrypted)
- [ ] Home screen widget
- [ ] Wear OS companion app
- [ ] Focus mode (temporarily block supported apps)
- [ ] Friends challenge (compare streaks)
- [ ] Productivity score
- [ ] Digital wellbeing reports
- [ ] Machine learning usage predictions

---

## 📄 License

MIT License — see [LICENSE](LICENSE)

---

## 🙏 Credits

Built with ❤️ by Mohammed Sameer

**Tagline:** *Know when enough is enough.*
