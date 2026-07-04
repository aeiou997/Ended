import 'package:flutter/material.dart';
import 'package:ended/core/constants/app_constants.dart';

/// Platform badge widget — shows icon + count for a supported platform.
class PlatformBadge extends StatelessWidget {
  final String platformId;
  final int count;
  final bool showCount;

  const PlatformBadge({
    super.key,
    required this.platformId,
    this.count = 0,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    final platform = AppConstants.supportedPlatforms[platformId];
    if (platform == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: platform.color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(platform.icon, color: platform.color, size: 16),
          const SizedBox(width: 6),
          Text(
            platform.name,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
              color: platform.color,
            ),
          ),
          if (showCount) ...[
            const SizedBox(width: 8),
            Text(
              '$count',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 14,
                color: platform.color,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
