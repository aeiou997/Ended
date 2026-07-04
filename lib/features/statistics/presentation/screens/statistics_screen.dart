import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:ended/core/constants/app_colors.dart';
import 'package:ended/core/providers/app_providers.dart';
import 'package:ended/data/models/daily_stats.dart';

/// Main statistics screen showing daily/weekly/monthly charts and key metrics.
class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyStatsProvider);
    final monthlyAsync = ref.watch(monthlyStatsProvider);
        final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Statistics',
          style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: textColor),
        ),
        elevation: 0,
        scrolledUnderElevation: 2,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Period Selector ──
            const _PeriodSelector(),
            const SizedBox(height: 20),

            // ── Daily Bar Chart (7 days) ──
            _SectionCard(
              title: 'Daily Usage (7 Days)',
              icon: Icons.bar_chart_rounded,
              accent: AppColors.primary,
              child: SizedBox(
                height: 220,
                child: weeklyAsync.when(
                  loading: () => const _LoadingIndicator(),
                  error: (e, _) => _ErrorBox(message: '$e'),
                  data: (stats) => _DailyBarChart(stats: stats),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Weekly Line Chart ──
            _SectionCard(
              title: 'Weekly Trend',
              icon: Icons.show_chart_rounded,
              accent: AppColors.accent,
              child: SizedBox(
                height: 220,
                child: weeklyAsync.when(
                  loading: () => const _LoadingIndicator(),
                  error: (e, _) => _ErrorBox(message: '$e'),
                  data: (stats) => _WeeklyLineChart(stats: stats),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Monthly Summary ──
            _SectionCard(
              title: 'Monthly Summary',
              icon: Icons.calendar_month_rounded,
              accent: AppColors.warning,
              child: SizedBox(
                height: 220,
                child: monthlyAsync.when(
                  loading: () => const _LoadingIndicator(),
                  error: (e, _) => _ErrorBox(message: '$e'),
                  data: (stats) => _MonthlyLineChart(stats: stats),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Key Metrics ──
            monthlyAsync.when(
              loading: () => const _LoadingIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _MetricsGrid(stats: stats),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Period selector chips
// ────────────────────────────────────────────────────────────

class _PeriodSelector extends StatefulWidget {
  const _PeriodSelector();

  @override
  State<_PeriodSelector> createState() => _PeriodSelectorState();
}

class _PeriodSelectorState extends State<_PeriodSelector> {
  int _selected = 0; // 0=week, 1=month, 2=all
  static const _labels = ['Week', 'Month', 'All Time'];
  static const _icons = [
    Icons.view_week_rounded,
    Icons.calendar_month_rounded,
    Icons.all_inclusive_rounded,
  ];

  @override
  Widget build(BuildContext context) {
        return Row(
      children: List.generate(_labels.length, (i) {
        final selected = _selected == i;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            avatar: Icon(_icons[i], size: 16,
                color: selected ? Colors.white : AppColors.primary),
            label: Text(
              _labels[i],
              style: GoogleFonts.inter(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? Colors.white : null,
              ),
            ),
            selected: selected,
            selectedColor: AppColors.primary,
            onSelected: (_) => setState(() => _selected = i),
          ),
        );
      }),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Reusable section card
// ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;

  const _SectionCard({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
        return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 18, color: accent),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Loading / error helpers
// ────────────────────────────────────────────────────────────

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator(strokeWidth: 2));
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(message,
          style: GoogleFonts.inter(color: AppColors.error, fontSize: 13)),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Daily Bar Chart — last 7 days
// ────────────────────────────────────────────────────────────

class _DailyBarChart extends StatelessWidget {
  final List<DailyStats> stats;
  const _DailyBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
          child: Text('No data yet',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)));
    }

    final maxVal = stats
        .map((s) => s.totalVideos)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();
    final ceiling = (maxVal + 5).clamp(10.0, double.infinity);

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: ceiling,
        barGroups: stats.asMap().entries.map((entry) {
          final idx = entry.key;
          final s = entry.value;
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: s.totalVideos.toDouble(),
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                ),
                width: 22,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: ceiling,
                  color: AppColors.primary.withValues(alpha: 0.06),
                ),
              ),
            ],
            showingTooltipIndicators: [],
          );
        }).toList(),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= stats.length) {
                  return const SizedBox.shrink();
                }
                final d = stats[idx].date;
                final now = DateTime.now();
                final label = d.day == now.day && d.month == now.month
                    ? 'Today'
                    : _shortWeekday(d);
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(label,
                      style: GoogleFonts.inter(
                          fontSize: 10, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          horizontalInterval: ceiling / 5,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.grey.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            tooltipPadding: const EdgeInsets.all(8),
            tooltipRoundedRadius: 8,
            getTooltipItem: (group, groupIdx, rod, rodIdx) {
              if (groupIdx >= stats.length) return null;
              final s = stats[groupIdx];
              final hours = s.totalWatchTimeHours.toStringAsFixed(1);
              return BarTooltipItem(
                '${s.totalVideos} videos\n$hours hrs watched',
                GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  String _shortWeekday(DateTime d) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[d.weekday - 1];
  }
}

// ────────────────────────────────────────────────────────────
// Weekly Line Chart
// ────────────────────────────────────────────────────────────

class _WeeklyLineChart extends StatelessWidget {
  final List<DailyStats> stats;
  const _WeeklyLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
          child: Text('No data yet',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)));
    }

    final spots = stats
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalVideos.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.35,
            color: AppColors.accent,
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (_, __, ___, ____ ) => FlDotCirclePainter(
                color: AppColors.accent,
                radius: 4,
                strokeColor: Colors.white,
                strokeWidth: 2,
              ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.accent.withValues(alpha: 0.25),
                  AppColors.accent.withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= stats.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${stats[idx].date.day}/${stats[idx].date.month}',
                      style: GoogleFonts.inter(fontSize: 10)),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.grey.withValues(alpha: 0.12),
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((spot) => LineTooltipItem(
                      '${spot.y.toInt()} videos',
                      GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Monthly Summary Line Chart
// ────────────────────────────────────────────────────────────

class _MonthlyLineChart extends StatelessWidget {
  final List<DailyStats> stats;
  const _MonthlyLineChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return Center(
          child: Text('No data yet',
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)));
    }

    final spots = stats
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.totalVideos.toDouble()))
        .toList();

    return LineChart(
      LineChartData(
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            curveSmoothness: 0.3,
            color: AppColors.warning,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.warning.withValues(alpha: 0.18),
                  AppColors.warning.withValues(alpha: 0.01),
                ],
              ),
            ),
          ),
        ],
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (val, _) => Text(
                val.toInt().toString(),
                style: GoogleFonts.inter(fontSize: 10, color: Colors.grey),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: stats.length > 14 ? 5 : 1,
              getTitlesWidget: (val, _) {
                final idx = val.toInt();
                if (idx < 0 || idx >= stats.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text('${stats[idx].date.day}',
                      style: GoogleFonts.inter(fontSize: 10)),
                );
              },
            ),
          ),
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (val) => FlLine(
            color: Colors.grey.withValues(alpha: 0.12),
            strokeWidth: 1,
          ),
        ),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            tooltipRoundedRadius: 8,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map((spot) {
                  final idx = spot.x.toInt();
                  String dateLabel = '';
                  if (idx >= 0 && idx < stats.length) {
                    final d = stats[idx].date;
                    dateLabel = '${d.day}/${d.month}: ';
                  }
                  return LineTooltipItem(
                    '$dateLabel${spot.y.toInt()} videos',
                    GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  );
                })
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
// Key Metrics Grid — avg/day, most used platform, best/worst day, total hours
// ────────────────────────────────────────────────────────────

class _MetricsGrid extends StatelessWidget {
  final List<DailyStats> stats;
  const _MetricsGrid({required this.stats});

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) return const SizedBox.shrink();

    // ── Compute metrics ──
    final totalVideos =
        stats.fold<int>(0, (sum, s) => sum + s.totalVideos);
    final avgPerDay = totalVideos / stats.length;

    final bestDay = stats.reduce(
        (a, b) => a.totalVideos >= b.totalVideos ? a : b);
    final worstDay = stats.reduce(
        (a, b) => a.totalVideos <= b.totalVideos ? a : b);

    final totalWatchTime = stats.fold<Duration>(
        Duration.zero, (acc, s) => acc + s.totalWatchTime);
    final totalHours = totalWatchTime.inSeconds / 3600;

    final mostUsedPlatform = _getMostUsedPlatform(stats);

    final metrics = <_MetricData>[
      _MetricData(
        icon: Icons.access_time_rounded,
        label: 'Avg Videos / Day',
        value: avgPerDay.toStringAsFixed(1),
        color: AppColors.info,
      ),
      _MetricData(
        icon: Icons.phone_android_rounded,
        label: 'Most Used Platform',
        value: mostUsedPlatform,
        color: AppColors.warning,
      ),
      _MetricData(
        icon: Icons.thumb_up_alt_rounded,
        label: 'Best Day',
        value: '${_fmtDate(bestDay.date)} — ${bestDay.totalVideos} videos',
        color: AppColors.success,
      ),
      _MetricData(
        icon: Icons.thumb_down_alt_rounded,
        label: 'Worst Day',
        value: '${_fmtDate(worstDay.date)} — ${worstDay.totalVideos} videos',
        color: AppColors.error,
      ),
      _MetricData(
        icon: Icons.schedule_rounded,
        label: 'Total Hours',
        value: '${totalHours.toStringAsFixed(1)} hrs',
        color: AppColors.primary,
      ),
    ];

    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights_rounded,
                      size: 18, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text('Key Metrics',
                    style: GoogleFonts.inter(
                        fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            ...metrics.map((m) => _MetricRow(data: m)),
          ],
        ),
      ),
    );
  }

  String _getMostUsedPlatform(List<DailyStats> stats) {
    final totals = <String, int>{};
    for (final s in stats) {
      for (final e in s.platformCounts.entries) {
        totals[e.key] = (totals[e.key] ?? 0) + e.value;
      }
    }
    if (totals.isEmpty) return 'N/A';
    final sorted = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return sorted.first.key.toUpperCase();
  }

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2)}';
}

// ────────────────────────────────────────────────────────────
// Metric row data model & widget
// ────────────────────────────────────────────────────────────

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
}

class _MetricRow extends StatelessWidget {
  final _MetricData data;
  const _MetricRow({required this.data});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: data.color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(data.icon, color: data.color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(data.label,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w500)),
          ),
          Flexible(
            child: Text(data.value,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                    fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
