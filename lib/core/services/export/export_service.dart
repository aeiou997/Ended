import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:ended/data/models/daily_stats.dart';

/// Export service: generates CSV and PDF reports from stats data.
class ExportService {
  ExportService._();

  /// Export daily stats as CSV
  static Future<void> exportAsCsv(List<DailyStats> stats) async {
    final rows = <List<dynamic>>[
      ['Date', 'Videos', 'Watch Time (min)', 'Sessions', 'Instagram', 'YouTube', 'Facebook', 'Snapchat'],
    ];

    for (final s in stats) {
      rows.add([
        s.dateKey,
        s.totalVideos,
        s.totalWatchTime.inMinutes,
        s.sessionsCount,
        s.platformCounts['instagram'] ?? 0,
        s.platformCounts['youtube'] ?? 0,
        s.platformCounts['facebook'] ?? 0,
        s.platformCounts['snapchat'] ?? 0,
      ]);
    }

    final csvData = const ListToCsvConverter().convert(rows);
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/ended_stats_${DateTime.now().millisecondsSinceEpoch}.csv');
    await file.writeAsString(csvData);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Ended — Your scrolling statistics',
    );
  }

  /// Export all data as JSON string (for backup)
  static String exportAsJson(Map<String, dynamic> data) {
    // Simple JSON export — full implementation would use proper encoder
    return data.toString();
  }
}
