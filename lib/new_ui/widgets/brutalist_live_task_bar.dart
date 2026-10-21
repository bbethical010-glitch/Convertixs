import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../core/services/global_task_manager.dart';
import '../theme/brutalist_theme.dart';

class BrutalistLiveTaskBar extends ConsumerWidget {
  final VoidCallback? onTap;

  const BrutalistLiveTaskBar({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTasks = ref.watch(globalTaskManagerProvider);
    if (activeTasks.isEmpty) return const SizedBox.shrink();

    final task = activeTasks.first;
    final percent = task.progress >= 0 ? (task.progress * 100).toInt() : null;
    final etaText = task.eta != null
        ? '${task.eta!.inSeconds}s'
        : task.stageLabel ?? 'Processing';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: const BoxDecoration(
          color: BrutalColors.white,
          border: BrutalTheme.brutalBorder,
          boxShadow: BrutalTheme.brutalShadow,
        ),
        child: Row(
          children: [
            // Progress Box
            Container(
              width: 38,
              height: 38,
              decoration: const BoxDecoration(
                color: BrutalColors.black,
                border: BrutalTheme.brutalBorder,
              ),
              child: Center(
                child: Text(
                  percent != null ? '$percent%' : '...',
                  style: BrutalTheme.headline(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: BrutalColors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: BrutalColors.black,
                          shape: BoxShape.rectangle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${task.toolName.toUpperCase()}: ${task.inputFileName}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: BrutalTheme.headline(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.black,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'ETA: $etaText • ${task.targetFormat.toUpperCase()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: BrutalTheme.label(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: BrutalColors.textMuted,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Cancel Task Icon Button
            GestureDetector(
              onTap: () {
                // Cancel through task manager
                ref.read(globalTaskManagerProvider.notifier).cancelTask(task.taskId);
              },
              child: Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: BrutalColors.black,
                  border: BrutalTheme.brutalBorder,
                ),
                child: const Icon(LucideIcons.x, size: 16, color: BrutalColors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
