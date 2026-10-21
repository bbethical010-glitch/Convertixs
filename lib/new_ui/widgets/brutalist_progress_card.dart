import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/brutalist_theme.dart';
import 'brutalist_button.dart';

class BrutalistProgressCard extends StatelessWidget {
  final String title;
  final String fileName;
  final String? profileTag;
  final double progress; // 0.0 to 1.0 or -1.0 for indeterminate
  final Duration elapsed;
  final Duration? eta;
  final String? stageLabel;
  final VoidCallback? onCancel;

  const BrutalistProgressCard({
    super.key,
    required this.title,
    required this.fileName,
    this.profileTag,
    required this.progress,
    required this.elapsed,
    this.eta,
    this.stageLabel,
    this.onCancel,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final int percent = progress >= 0 ? (progress * 100).clamp(0, 100).toInt() : 0;
    final isIndeterminate = progress < 0;

    return Container(
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: BrutalTheme.brutalBorder,
        boxShadow: BrutalTheme.brutalShadowLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Stark Black Top Accent Bar
          Container(height: 6, color: BrutalColors.black),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header with Hourglass & Filename
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: BrutalColors.white,
                            border: BrutalTheme.brutalBorder,
                            boxShadow: BrutalTheme.brutalShadowSm,
                          ),
                          child: const Icon(LucideIcons.hourglass, size: 22, color: BrutalColors.black),
                        ),
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 8,
                            height: 8,
                            color: BrutalColors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BrutalTheme.headline(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.black,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            fileName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: BrutalTheme.body(
                              fontSize: 12,
                              color: BrutalColors.textMuted,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (profileTag != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: BrutalColors.surfaceContainerLow,
                          border: Border.all(color: BrutalColors.black, width: 1),
                        ),
                        child: Text(
                          profileTag!.toUpperCase(),
                          style: BrutalTheme.label(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.black,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),
                // Live Percentage & Tag
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          isIndeterminate ? '...' : '$percent',
                          style: BrutalTheme.headline(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: BrutalColors.black,
                            letterSpacing: -1.5,
                          ),
                        ),
                        if (!isIndeterminate)
                          Text(
                            '%',
                            style: BrutalTheme.headline(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.black,
                            ),
                          ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: BrutalColors.surfaceContainer,
                        border: Border.all(color: BrutalColors.black, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.zap, size: 13, color: BrutalColors.black),
                          const SizedBox(width: 4),
                          Text(
                            'HARDWARE ENCODE',
                            style: BrutalTheme.label(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: BrutalColors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Linear Meter
                Container(
                  height: 20,
                  decoration: const BoxDecoration(
                    color: BrutalColors.white,
                    border: BrutalTheme.brutalBorder,
                  ),
                  padding: const EdgeInsets.all(2),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: isIndeterminate ? 0.3 : (progress.clamp(0.02, 1.0)),
                    child: Container(
                      color: BrutalColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                // Metrics Row (Elapsed, Stage, ETA)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: BrutalColors.surfaceContainerLow,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'ELAPSED',
                              style: BrutalTheme.label(
                                fontSize: 9,
                                color: BrutalColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDuration(elapsed),
                              style: BrutalTheme.headline(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: BrutalColors.black),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              'STAGE',
                              style: BrutalTheme.label(
                                fontSize: 9,
                                color: BrutalColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              stageLabel ?? 'Processing',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: BrutalTheme.headline(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(width: 1, height: 26, color: BrutalColors.black),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'EST. ETA',
                              style: BrutalTheme.label(
                                fontSize: 9,
                                color: BrutalColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              eta != null ? _formatDuration(eta!) : '--:--',
                              style: BrutalTheme.headline(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (onCancel != null) ...[
                  const SizedBox(height: 14),
                  Align(
                    alignment: Alignment.centerRight,
                    child: BrutalistButton(
                      style: BrutalButtonStyle.secondary,
                      height: 38,
                      onPressed: onCancel,
                      icon: const Icon(LucideIcons.x, size: 15, color: BrutalColors.black),
                      label: 'Cancel Operation',
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
