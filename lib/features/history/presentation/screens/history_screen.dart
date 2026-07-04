import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ended/core/constants/app_colors.dart';
import 'package:ended/core/providers/app_providers.dart';
import 'package:ended/core/services/export/export_service.dart';
import 'package:ended/data/models/daily_stats.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'History',
            style: GoogleFonts.inter(fontWeight: FontWeight.w700),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.file_download),
              tooltip: 'Export CSV',
              onPressed: () async {
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
          ],
          bottom: TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: isDark ? AppColors.textSecondary : Colors.grey,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Daily'),
              Tab(text: 'Weekly'),
              Tab(text: 'Monthly'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _DailyHistoryTab(),
            _WeeklyHistoryTab(),
            _MonthlyHistoryTab(),
          ],
        ),
      ),
    );
  }
}

class _DailyHistoryTab extends ConsumerWidget {
  const _DailyHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyStatsProvider);

    return weeklyAsync.when(
      data: (stats) => _StatsList(stats: stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _WeeklyHistoryTab extends ConsumerWidget {
  const _WeeklyHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyStatsProvider);

    return monthlyAsync.when(
      data: (stats) => _StatsList(stats: stats),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _MonthlyHistoryTab extends ConsumerWidget {
  const _MonthlyHistoryTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthlyAsync = ref.watch(monthlyStatsProvider);

    return monthlyAsync.when(
      data: (stats) {
        if (stats.isEmpty) {
          return Center(
            child: Text('No data yet',
                style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
          );
        }
        // Aggregate by month
        final byMonth = <String, List<DailyStats>>{};
        for (final s in stats) {
          final key = '${s.date.year}-${s.date.month.toString().padLeft(2, '0')}';
          byMonth.putIfAbsent(key, () => []).add(s);
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: byMonth.length,
          itemBuilder: (context, index) {
            final key = byMonth.keys.elementAt(index);
            final days = byMonth[key]!;
            final totalVideos = days.fold<int>(0, (a, d) => a + d.totalVideos);
            final totalMinutes = days.fold<int>(0, (a, d) => a + d.totalWatchTime.inMinutes);
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                title: Text(key, style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                subtitle: Text('$totalVideos videos • ${totalMinutes}min watched'),
                trailing: Icon(Icons.calendar_month, color: AppColors.primary),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
    );
  }
}

class _StatsList extends StatelessWidget {
  final List<DailyStats> stats;
  const _StatsList({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
        child: Text('No data yet',
            style: GoogleFonts.inter(fontSize: 16, color: Colors.grey)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: stats.length,
      itemBuilder: (context, index) {
        final s = stats[index];
        final platformBreakdown = s.platformCounts.entries
            .where((e) => e.value > 0)
            .map((e) => '${e.key}: ${e.value}')
            .join(' • ');

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      s.dateKey,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${s.totalVideos} vids',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.schedule, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${s.totalWatchTime.inMinutes} min',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.repeat, size: 16, color: Colors.grey.shade500),
                    const SizedBox(width: 4),
                    Text(
                      '${s.sessionsCount} sessions',
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),
                if (platformBreakdown.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    platformBreakdown,
                    style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
