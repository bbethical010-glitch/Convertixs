import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/models/history_entry.dart';
import '../../core/services/global_task_manager.dart';
import '../../core/services/history_service.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_tag.dart';

class NewHistoryScreen extends ConsumerWidget {
  const NewHistoryScreen({super.key});

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Saved';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _confirmClearAll(BuildContext context, HistoryService historyService) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrutalColors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: BrutalColors.black, width: 2),
        ),
        title: Text(
          'CLEAR HISTORY?',
          style: BrutalTheme.headline(fontSize: 16),
        ),
        content: Text(
          'This will remove all records from history. Converted files on your device will NOT be deleted.',
          style: BrutalTheme.body(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: BrutalTheme.label(color: BrutalColors.textMuted),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: BrutalColors.black,
              foregroundColor: BrutalColors.white,
              shape: const RoundedRectangleBorder(
                side: BorderSide(color: BrutalColors.black, width: 2),
              ),
            ),
            onPressed: () {
              historyService.clearAll();
              Navigator.pop(ctx);
            },
            child: Text('CLEAR ALL', style: BrutalTheme.label(color: BrutalColors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyService = ref.watch(historyServiceProvider);
    final activeTasks = ref.watch(globalTaskManagerProvider);

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Task History',
        subtitle: 'Log & Archives',
        showBackButton: false,
        showUpgrade: false,
        showProfile: true,
      ),
      body: ValueListenableBuilder<Box<HistoryEntry>>(
        valueListenable: historyService.listenable(),
        builder: (context, box, _) {
          final entries = historyService
              .getAllEntries()
              .where((e) => e.status != HistoryEntryStatus.active)
              .toList();

          if (entries.isEmpty && activeTasks.isEmpty) {
            return _buildEmptyState();
          }

          final today = <HistoryEntry>[];
          final yesterday = <HistoryEntry>[];
          final earlier = <HistoryEntry>[];

          final now = DateTime.now();
          final todayStart = DateTime(now.year, now.month, now.day);
          final yesterdayStart = todayStart.subtract(const Duration(days: 1));

          for (final entry in entries) {
            final date = DateTime.fromMillisecondsSinceEpoch(entry.timestampMs);
            if (date.isAfter(todayStart)) {
              today.add(entry);
            } else if (date.isAfter(yesterdayStart)) {
              yesterday.add(entry);
            } else {
              earlier.add(entry);
            }
          }

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            children: [
              // Top Action Bar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: BrutalColors.black),
                      const SizedBox(width: 6),
                      Text(
                        '${entries.length} ARCHIVED TASKS',
                        style: BrutalTheme.label(fontSize: 11),
                      ),
                    ],
                  ),
                  if (entries.isNotEmpty)
                    GestureDetector(
                      onTap: () => _confirmClearAll(context, historyService),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: const BoxDecoration(
                          color: BrutalColors.white,
                          border: BrutalTheme.brutalBorder,
                          boxShadow: BrutalTheme.brutalShadowSm,
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.trash2, size: 12, color: BrutalColors.black),
                            const SizedBox(width: 4),
                            Text('CLEAR ALL', style: BrutalTheme.label(fontSize: 10)),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Active Tasks Section
              if (activeTasks.isNotEmpty) ...[
                _buildSectionLabel('Active Encoders (${activeTasks.length})'),
                const SizedBox(height: 8),
                ...activeTasks.map((t) => _buildActiveTaskItem(context, ref, t)),
                const SizedBox(height: 16),
              ],

              // Today Section
              if (today.isNotEmpty) ...[
                _buildSectionLabel('Today'),
                const SizedBox(height: 8),
                ...today.map((e) => _buildHistoryItem(context, historyService, e)),
                const SizedBox(height: 16),
              ],

              // Yesterday Section
              if (yesterday.isNotEmpty) ...[
                _buildSectionLabel('Yesterday'),
                const SizedBox(height: 8),
                ...yesterday.map((e) => _buildHistoryItem(context, historyService, e)),
                const SizedBox(height: 16),
              ],

              // Earlier Section
              if (earlier.isNotEmpty) ...[
                _buildSectionLabel('Earlier'),
                const SizedBox(height: 8),
                ...earlier.map((e) => _buildHistoryItem(context, historyService, e)),
                const SizedBox(height: 16),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: BrutalColors.surfaceContainerLow,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadow,
              ),
              child: const Icon(LucideIcons.history, size: 32, color: BrutalColors.black),
            ),
            const SizedBox(height: 16),
            Text(
              'NO CONVERSIONS YET',
              style: BrutalTheme.headline(fontSize: 16),
            ),
            const SizedBox(height: 4),
            Text(
              'Your converted videos, photos and documents will appear here.',
              textAlign: TextAlign.center,
              style: BrutalTheme.body(color: BrutalColors.textMuted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label) {
    return Container(
      padding: const EdgeInsets.only(bottom: 4),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: BrutalColors.black, width: 2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: BrutalTheme.label(fontSize: 11, letterSpacing: 0.8),
      ),
    );
  }

  Widget _buildActiveTaskItem(BuildContext context, WidgetRef ref, ActiveTask task) {
    final percent = task.progress >= 0 ? (task.progress * 100).toInt() : null;

    return BrutalistCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: BrutalColors.black,
              border: BrutalTheme.brutalBorder,
            ),
            child: Center(
              child: Text(
                percent != null ? '$percent%' : '...',
                style: BrutalTheme.headline(fontSize: 11, color: BrutalColors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.inputFileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrutalTheme.headline(fontSize: 13),
                ),
                const SizedBox(height: 2),
                Text(
                  '${task.toolName.toUpperCase()} • ${task.targetFormat.toUpperCase()}',
                  style: BrutalTheme.body(fontSize: 11, color: BrutalColors.textMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => ref.read(globalTaskManagerProvider.notifier).cancelTask(task.taskId),
            child: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: BrutalColors.black,
                border: BrutalTheme.brutalBorder,
              ),
              child: const Icon(LucideIcons.x, size: 16, color: BrutalColors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    HistoryService historyService,
    HistoryEntry entry,
  ) {
    final ext = entry.outputFilename.contains('.')
        ? entry.outputFilename.split('.').last.toUpperCase()
        : 'FILE';
    final isSuccess = entry.status == HistoryEntryStatus.completed;
    final pathOrUri = entry.contentUri ?? entry.displayLocation;

    return BrutalistCard(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSuccess ? BrutalColors.surfaceContainerLow : BrutalColors.surfaceContainerHigh,
              border: BrutalTheme.brutalBorder,
            ),
            child: Center(
              child: Icon(
                isSuccess ? LucideIcons.fileCheck : LucideIcons.fileX,
                size: 22,
                color: isSuccess ? BrutalColors.black : BrutalColors.red,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.outputFilename.isNotEmpty ? entry.outputFilename : entry.inputFilename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: BrutalTheme.headline(fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    BrutalistTag(label: ext),
                    const SizedBox(width: 6),
                    Text(
                      _formatBytes(entry.fileSizeBytes),
                      style: BrutalTheme.label(fontSize: 10, color: BrutalColors.textMuted),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${entry.toolName}',
                      style: BrutalTheme.body(fontSize: 10, color: BrutalColors.textMuted),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSuccess && pathOrUri != null) ...[
                GestureDetector(
                  onTap: () => OpenFile.open(pathOrUri),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: BrutalColors.black,
                      border: BrutalTheme.brutalBorder,
                    ),
                    child: const Icon(LucideIcons.play, size: 14, color: BrutalColors.white),
                  ),
                ),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => Share.shareXFiles([XFile(pathOrUri)]),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                    ),
                    child: const Icon(LucideIcons.share2, size: 14, color: BrutalColors.black),
                  ),
                ),
                const SizedBox(width: 6),
              ],
              GestureDetector(
                onTap: () => historyService.deleteEntry(entry.id),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: const BoxDecoration(
                    color: BrutalColors.white,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: const Icon(LucideIcons.trash2, size: 14, color: BrutalColors.black),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
