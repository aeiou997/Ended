import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ended/core/providers/app_providers.dart';
import 'package:ended/core/constants/app_colors.dart';
import 'package:ended/shared/widgets/platform_badge.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.hourglass_bottom_rounded,
                color: Theme.of(context).colorScheme.primary, size: 24),
            const SizedBox(width: 8),
            Text('Ended',
                style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => RefreshIndicator(
          onRefresh: () async => ref.invalidate(dashboardProvider),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Hero: Big Number + Progress Ring + Watch Time + Remaining ──
                _HeroCard(data: data),
                const SizedBox(height: 16),

                // ── 4 Platform Badges ──
                _PlatformBadgesRow(data: data),
                const SizedBox(height: 16),

                // ── Weekly / Monthly Totals ──
                _WeeklyMonthlyRow(data: data),
                const SizedBox(height: 16),

                // ── Streak Card ──
                _StreakCard(streak: data.streak),
                const SizedBox(height: 16),

                // ── Comparison vs Yesterday ──
                _VsYesterdayCard(percent: data.percentVsYesterday),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Hero Card — big number + progress ring + watch time + remaining
// ═══════════════════════════════════════════════════════════════

class _HeroCard extends StatelessWidget {
  final DashboardData data;
  const _HeroCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final progressCapped = data.progress.clamp(0.0, 1.0);
    final isOverLimit = data.progress > 1.0;
    final ringColor = isOverLimit ? AppColors.error : AppColors.primary;
    final subtleText =
        Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Section label
            Text("Today's Videos",
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  color: subtleText,
                )),
            const SizedBox(height: 20),

            // ── Progress ring with big number ──
            CircularPercentIndicator(
              radius: 90,
              lineWidth: 14,
              percent: progressCapped,
              circularStrokeCap: CircularStrokeCap.round,
              backgroundColor: ringColor.withValues(alpha: 0.12),
              progressColor: ringColor,
              animation: true,
              animationDuration: 800,
              center: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${data.totalVideos}',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.w900,
                        color: isOverLimit ? AppColors.error : null,
                        height: 1,
                      )),
                  const SizedBox(height: 4),
                  Text('/ ${data.goalLimit}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: subtleText,
                      )),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // ── Remaining message ──
            Text(
              isOverLimit
                  ? '⚠️ Over your daily limit!'
                  : '${data.remaining} videos remaining',
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isOverLimit ? AppColors.error : AppColors.accent,
              ),
            ),
            const SizedBox(height: 8),

            // ── Watch time ──
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.schedule_rounded, size: 16, color: subtleText),
                const SizedBox(width: 4),
                Text('Watch time: ${_fmtDuration(data.watchTime)}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: subtleText,
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}

// ═══════════════════════════════════════════════════════════════
// Platform Badges — 4 badges in a wrap row
// ═══════════════════════════════════════════════════════════════

class _PlatformBadgesRow extends StatelessWidget {
  final DashboardData data;
  const _PlatformBadgesRow({required this.data});

  @override
  Widget build(BuildContext context) {
    final badges = [
      MapEntry('instagram', data.instagramCount),
      MapEntry('youtube', data.youtubeCount),
      MapEntry('facebook', data.facebookCount),
      MapEntry('snapchat', data.snapchatCount),
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Platforms',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                )),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: badges
                  .map((e) => PlatformBadge(
                        platformId: e.key,
                        count: e.value,
                      ))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Weekly / Monthly Totals — two stat cards side by side
// ═══════════════════════════════════════════════════════════════

class _WeeklyMonthlyRow extends StatelessWidget {
  final DashboardData data;
  const _WeeklyMonthlyRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CompactStatCard(
            icon: Icons.calendar_today_rounded,
            label: 'Weekly Total',
            value: '${data.weeklyTotal}',
            color: AppColors.info,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _CompactStatCard(
            icon: Icons.calendar_month_rounded,
            label: 'Monthly Total',
            value: '${data.monthlyTotal}',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

class _CompactStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _CompactStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.inter(
                    fontSize: 22, fontWeight: FontWeight.w900)),
            const SizedBox(height: 2),
            Text(label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                )),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Streak Card
// ═══════════════════════════════════════════════════════════════

class _StreakCard extends StatelessWidget {
  final int streak;
  const _StreakCard({required this.streak});

  @override
  Widget build(BuildContext context) {
    final isActive = streak > 0;
    final streakColor = isActive ? AppColors.warning : AppColors.info;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: streakColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.local_fire_department_rounded,
                  color: streakColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$streak Day Streak',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      )),
                  const SizedBox(height: 2),
                  Text(
                    isActive
                        ? "You're on fire! 🔥"
                        : 'Meet your daily goal to start a streak!',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color:
                          Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// Comparison vs Yesterday
// ═══════════════════════════════════════════════════════════════

class _VsYesterdayCard extends StatelessWidget {
  final double percent;
  const _VsYesterdayCard({required this.percent});

  @override
  Widget build(BuildContext context) {
    final isDown = percent < 0;
    final isSame = percent == 0;
    final display = percent.abs().toStringAsFixed(0);
    final color = isSame
        ? Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5)
        : isDown
            ? AppColors.success
            : AppColors.error;
    final icon = isSame
        ? Icons.remove_rounded
        : isDown
            ? Icons.trending_down_rounded
            : Icons.trending_up_rounded;
    final label = isSame
        ? 'Same as yesterday'
        : isDown
            ? 'less than yesterday'
            : 'more than yesterday';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isSame
                        ? 'Same as yesterday'
                        : '${display}% $label',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Compared to your video count yesterday',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
