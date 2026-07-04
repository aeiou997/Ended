import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ended/core/constants/app_constants.dart';
import 'package:ended/core/constants/app_colors.dart';
import 'package:ended/core/providers/app_providers.dart';
import 'package:ended/core/services/export/export_service.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigProvider);
    final goal = ref.watch(userGoalProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Monitoring ──
          _SectionHeader(title: 'Monitoring'),
          SwitchListTile(
            title: Text('Enable Tracking', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Monitor short-form video apps in background'),
            value: config.monitoringEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => ref.read(appConfigProvider.notifier).setMonitoringEnabled(v),
          ),

          const SizedBox(height: 8),

          // ── Platforms ──
          _SectionHeader(title: 'Platforms'),
          ...AppConstants.supportedPlatforms.entries.map((entry) {
            final enabled = config.platformEnabled[entry.key] ?? false;
            return SwitchListTile(
              secondary: Icon(entry.value.icon, color: entry.value.color, size: 22),
              title: Text(entry.value.name, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              value: enabled,
              activeTrackColor: entry.value.color,
              onChanged: (v) => ref.read(appConfigProvider.notifier).togglePlatform(entry.key, v),
            );
          }),

          const SizedBox(height: 8),

          // ── Daily Goals ──
          _SectionHeader(title: 'Daily Goals'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Max Videos per Day: ${goal.maxVideosPerDay}',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Slider(
                    value: goal.maxVideosPerDay.toDouble(),
                    min: 10,
                    max: 200,
                    divisions: 19,
                    activeColor: AppColors.primary,
                    label: '${goal.maxVideosPerDay}',
                    onChanged: (v) => ref.read(userGoalProvider.notifier).setVideoLimit(v.round()),
                  ),
                  const SizedBox(height: 8),
                  Text('Max Watch Time: ${goal.maxWatchTimeMinutesPerDay} min',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  Slider(
                    value: goal.maxWatchTimeMinutesPerDay.toDouble(),
                    min: 10,
                    max: 300,
                    divisions: 29,
                    activeColor: AppColors.warning,
                    label: '${goal.maxWatchTimeMinutesPerDay} min',
                    onChanged: (v) => ref.read(userGoalProvider.notifier).setTimeLimit(v.round()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Notifications ──
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: Text('Enable Notifications', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
            subtitle: Text('Reminders when you over-scroll'),
            value: config.notificationsEnabled,
            activeTrackColor: AppColors.primary,
            onChanged: (v) => ref.read(appConfigProvider.notifier).setNotificationsEnabled(v),
          ),

          const SizedBox(height: 8),

          // ── Theme ──
          _SectionHeader(title: 'Appearance'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              title: Text('Theme', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              trailing: DropdownButton<String>(
                value: config.themeMode,
                underline: const SizedBox(),
                items: const [
                  DropdownMenuItem(value: 'system', child: Text('System')),
                  DropdownMenuItem(value: 'light', child: Text('Light')),
                  DropdownMenuItem(value: 'dark', child: Text('Dark')),
                ],
                onChanged: (v) {
                  if (v != null) ref.read(appConfigProvider.notifier).setThemeMode(v);
                },
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── Data Management ──
          _SectionHeader(title: 'Data'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(Icons.file_download, color: AppColors.primary),
                  title: Text('Export CSV', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () async {
                    try {
                      final weekly = await ref.read(weeklyStatsProvider.future);
                      await ExportService.exportAsCsv(weekly);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Export failed')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.restart_alt, color: AppColors.warning),
                  title: Text('Reset Statistics', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () => _showResetDialog(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(Icons.delete_forever, color: AppColors.danger),
                  title: Text('Delete All Data', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                  onTap: () => _showDeleteDialog(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── Privacy ──
          _SectionHeader(title: 'Privacy'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PrivacyRow(icon: Icons.cloud_off, text: 'No cloud storage — all data on device'),
                  const SizedBox(height: 8),
                  _PrivacyRow(icon: Icons.visibility_off, text: 'No content tracking — no video data read'),
                  const SizedBox(height: 8),
                  _PrivacyRow(icon: Icons.block, text: 'No advertisements — ever'),
                  const SizedBox(height: 8),
                  _PrivacyRow(icon: Icons.wifi_off, text: 'No internet permission — fully offline'),
                  const SizedBox(height: 8),
                  _PrivacyRow(icon: Icons.lock, text: 'No account required — no sign-up'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // App info
          Center(
            child: Column(
              children: [
                Text(
                  AppConstants.appName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  AppConstants.tagline,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'v1.0.0',
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  void _showResetDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Statistics?'),
        content: const Text('This will clear all your video tracking data. This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: implement reset via repository
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Statistics reset')),
              );
            },
            child: Text('Reset', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete All Data?'),
        content: const Text('This will permanently delete all your data including goals, streaks, and statistics.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              // TODO: implement delete via repository
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All data deleted')),
              );
            },
            child: Text('Delete', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          color: AppColors.primary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _PrivacyRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.success),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: GoogleFonts.inter(fontSize: 13))),
      ],
    );
  }
}
