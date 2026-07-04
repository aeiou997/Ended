import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/app_providers.dart';
import 'core/services/notifications/notification_service.dart';
import 'features/onboarding/presentation/screens/onboarding_screen.dart';
import 'shared/widgets/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock portrait orientation
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Set status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // Initialize notifications
  await NotificationService().init();

  runApp(const ProviderScope(child: EndedApp()));
}

class EndedApp extends ConsumerWidget {
  const EndedApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configAsync = ref.watch(appConfigProvider);

    // Determine theme mode
    final themeMode = configAsync.themeMode == 'dark'
        ? ThemeMode.dark
        : configAsync.themeMode == 'light'
            ? ThemeMode.light
            : ThemeMode.system;

    return MaterialApp(
      title: 'Ended',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: configAsync.onboardingComplete
          ? const MainShell()
          : OnboardingScreen(
              onComplete: () {
                ref.read(appConfigProvider.notifier).setOnboardingComplete();
              },
            ),
    );
  }
}
