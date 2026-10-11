import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../core/models/history_entry.dart';
import '../../core/services/history_service.dart';
import '../../core/services/output_location_service.dart';
import 'package:open_file/open_file.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../video_converter/video_converter_provider.dart';
import '../video_compression/video_compression_provider.dart';
import '../audio_converter/audio_converter_provider.dart';
import '../video_to_audio/video_to_audio_provider.dart';
import '../image_converter/image_converter_provider.dart';
import '../image_to_pdf/image_to_pdf_provider.dart';
import '../document_convert/document_convert_provider.dart';
import '../greyscale_pdf/greyscale_pdf_provider.dart';
import '../merge_pdf/merge_pdf_provider.dart';
import '../split_pdf/split_pdf_provider.dart';
import '../../core/services/global_task_manager.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyService = ref.watch(historyServiceProvider);
    final activeTasks = ref.watch(globalTaskManagerProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.trash2),
            onPressed: () => _confirmClearAll(context, historyService),
            tooltip: 'Clear history',
          ),
        ],
      ),
      body: ValueListenableBuilder<Box<HistoryEntry>>(
        valueListenable: historyService.listenable(),
        builder: (context, box, _) {
          final entries = historyService.getAllEntries().where((e) => e.status != HistoryEntryStatus.active).toList();

          if (entries.isEmpty && activeTasks.isEmpty) {
            return _buildEmptyState(theme);
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

          return CustomScrollView(
            slivers: [
              if (activeTasks.isNotEmpty) ...[
                _buildHeader('Active Tasks', theme),
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _ActiveTaskCard(task: activeTasks[index]);
                    },
                    childCount: activeTasks.length,
                  ),
                ),
              ],
              if (today.isNotEmpty) ...[
                _buildHeader('Today', theme),
                _buildList(today),
              ],
              if (yesterday.isNotEmpty) ...[
                _buildHeader('Yesterday', theme),
                _buildList(yesterday),
              ],
              if (earlier.isNotEmpty) ...[
                _buildHeader('Earlier', theme),
                _buildList(earlier),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.history,
            size: 64,
            color: theme.colorScheme.primary.withAlpha(128),
          ),
          const SizedBox(height: 16),
          Text(
            'No conversions yet',
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your recently converted files will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(String title, ThemeData theme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
        child: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildList(List<HistoryEntry> items) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          return _HistoryCard(entry: items[index]);
        },
        childCount: items.length,
      ),
    );
  }

  Future<void> _confirmClearAll(
    BuildContext context,
    HistoryService historyService,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text(
          'This will clear all your conversion history. '
          'The converted files will not be deleted from your device.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (result == true) {
      await historyService.clearAll();
    }
  }
}

class _HistoryCard extends ConsumerWidget {
  final HistoryEntry entry;

  const _HistoryCard({required this.entry});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isCompleted = entry.status == HistoryEntryStatus.completed;
    final isActive = entry.status == HistoryEntryStatus.active;
    final isFailed = entry.status == HistoryEntryStatus.failed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: isCompleted ? () => _handleOpen() : null,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildIcon(theme, isActive, isFailed),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isCompleted ? entry.outputFilename : entry.inputFilename,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${entry.toolName} • ${_formatStatus(isActive, isFailed)}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (isActive)
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: const Icon(LucideIcons.x, size: 20),
                        onPressed: () => _cancelTask(ref),
                        tooltip: 'Cancel',
                      ),
                    ],
                  ),
                )
              else
                _buildMenu(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, bool isActive, bool isFailed) {
    IconData iconData = LucideIcons.file;
    Color iconColor = theme.colorScheme.primary;

    if (isActive) {
      iconData = LucideIcons.loader2;
      iconColor = theme.colorScheme.secondary;
    } else if (isFailed) {
      iconData = LucideIcons.alertCircle;
      iconColor = theme.colorScheme.error;
    } else {
      final ext = p.extension(entry.outputFilename).toLowerCase();
      if (['.jpg', '.png', '.webp'].contains(ext)) {
        iconData = LucideIcons.image;
      } else if (['.mp4', '.mov'].contains(ext)) {
        iconData = LucideIcons.video;
      } else if (['.mp3', '.m4a', '.wav'].contains(ext)) {
        iconData = LucideIcons.music;
      } else if (ext == '.pdf') {
        iconData = LucideIcons.fileText;
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  String _formatStatus(bool isActive, bool isFailed) {
    if (isActive) return 'Converting...';
    if (isFailed) return 'Failed';
    
    final size = entry.fileSizeBytes;
    if (size == null) return 'Completed';
    
    if (size < 1024 * 1024) {
      return '${(size / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  Widget _buildMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: Icon(
        LucideIcons.moreVertical,
        size: 20,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onSelected: (value) => _handleMenuAction(context, ref, value),
      itemBuilder: (context) {
        final isCompleted = entry.status == HistoryEntryStatus.completed;
        return [
          if (isCompleted) ...[
            const PopupMenuItem(
              value: 'open',
              child: Row(
                children: [
                  Icon(LucideIcons.externalLink, size: 18),
                  SizedBox(width: 12),
                  Text('Open'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'show',
              child: Row(
                children: [
                  Icon(LucideIcons.folder, size: 18),
                  SizedBox(width: 12),
                  Text('Show in Folder'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: Row(
                children: [
                  Icon(LucideIcons.share2, size: 18),
                  SizedBox(width: 12),
                  Text('Share'),
                ],
              ),
            ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: 'rename',
              child: Row(
                children: [
                  Icon(LucideIcons.edit2, size: 18),
                  SizedBox(width: 12),
                  Text('Rename'),
                ],
              ),
            ),
          ],
          PopupMenuItem(
            value: 'delete',
            child: Row(
              children: [
                Icon(
                  LucideIcons.trash2,
                  size: 18,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 12),
                Text(
                  'Remove from History',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ),
          ),
        ];
      },
    );
  }

  void _handleOpen() {
    final pathOrUri = entry.contentUri ?? entry.displayLocation;
    if (pathOrUri != null) {
      OpenFile.open(pathOrUri);
    }
  }

  void _handleMenuAction(BuildContext context, WidgetRef ref, String action) async {
    final historyService = ref.read(historyServiceProvider);
    
    switch (action) {
      case 'open':
        final pathOrUri = entry.contentUri ?? entry.displayLocation;
        if (pathOrUri != null) {
          await OpenFile.open(pathOrUri);
        }
        break;
      case 'show':
        if (entry.displayLocation != null) {
          try {
            final p = entry.displayLocation!;
            final lastSlash = p.lastIndexOf('/');
            final relativeDir = lastSlash == -1
                ? p 
                : p.substring(0, lastSlash);
            await outputLocationService.showInFolder(relativeDir);
          } catch (e) {
            final textToCopy = entry.displayLocation ?? entry.contentUri ?? '';
            Clipboard.setData(ClipboardData(text: textToCopy));
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Saved location copied to clipboard:\n$textToCopy')),
              );
            }
          }
        }
        break;
      case 'share':
        if (entry.contentUri != null) {
          await outputLocationService.shareOutput(entry.contentUri!);
        } else if (entry.displayLocation != null) {
          // Fallback if not published to MediaStore
          await Share.shareXFiles(
            [XFile(entry.displayLocation!)],
            text: 'Converted with Convertix',
          );
        }
        break;
      case 'rename':
        if (entry.contentUri != null) {
          final newName = await _showRenameDialog(context, entry.outputFilename);
          if (newName != null && newName.isNotEmpty && newName != entry.outputFilename) {
            final success = await outputLocationService.renameOutput(entry.contentUri!, newName);
            if (success) {
              final newLocation = entry.displayLocation != null 
                  ? p.join(p.dirname(entry.displayLocation!), newName) 
                  : null;
              await historyService.updateOutputName(
                id: entry.id,
                newOutputFilename: newName,
                newDisplayLocation: newLocation ?? '',
              );
            } else if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permission denied. Please grant Media Management permission in Settings to modify files.')),
              );
            }
          }
        }
        break;
      case 'delete':
        bool deleted = true;
        if (entry.contentUri != null) {
          deleted = await outputLocationService.deleteOutput(entry.contentUri!);
        }
        if (deleted) {
          await historyService.deleteEntry(entry.id);
        } else if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission denied. Please grant Media Management permission in Settings to delete files.')),
          );
        }
        break;
    }
  }

  Future<String?> _showRenameDialog(BuildContext context, String currentName) {
    final controller = TextEditingController(text: currentName);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename File'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'New name',
            border: OutlineInputBorder(),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _cancelTask(WidgetRef ref) {
    switch (entry.toolName) {
      case 'Video Converter':
        ref.read(videoConverterProvider.notifier).cancel();
        break;
      case 'Video Compression':
        ref.read(videoCompressionProvider.notifier).cancel();
        break;
      case 'Audio Converter':
        ref.read(audioConverterProvider.notifier).cancel();
        break;
      case 'Video to Audio':
        ref.read(videoToAudioProvider.notifier).cancel();
        break;
      case 'Image Converter':
        ref.read(imageConverterProvider.notifier).cancel();
        break;
      case 'Image to PDF':
        ref.read(imageToPdfProvider.notifier).cancel();
        break;
      case 'Document Converter':
        ref.read(documentConvertProvider.notifier).cancel();
        break;
      case 'Greyscale PDF':
        ref.read(greyscalePdfProvider.notifier).cancel();
        break;
      case 'Merge PDF':
        ref.read(mergePdfProvider.notifier).cancel();
        break;
      case 'Split PDF':
        ref.read(splitPdfProvider.notifier).cancel();
        break;
    }
  }
}

class _ActiveTaskCard extends ConsumerWidget {
  final ActiveTask task;

  const _ActiveTaskCard({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isFailed = task.status == TaskStatus.failed;
    final isCancelling = task.status == TaskStatus.cancelled;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: theme.colorScheme.outlineVariant.withAlpha(100),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIcon(theme, !isFailed && !isCancelling, isFailed, task.inputFileName),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.inputFileName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (isFailed)
                    Text(
                      '${task.toolName} • Failed: ${task.errorMessage ?? "Unknown error"}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    )
                  else if (isCancelling)
                    Text(
                      '${task.toolName} • Cancelling...',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${task.toolName} • ${task.stageLabel ?? "Processing..."}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (task.progress >= 0.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: LinearProgressIndicator(
                                    value: task.progress,
                                    borderRadius: BorderRadius.circular(4),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  '${(task.progress * 100).toStringAsFixed(0)}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (task.progress < 0.0)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Row(
                              children: [
                                const Expanded(
                                  child: LinearProgressIndicator(
                                    borderRadius: BorderRadius.all(Radius.circular(4)),
                                    minHeight: 6,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                _buildElapsedText(theme, task.elapsed),
                              ],
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
            if (!isFailed && !isCancelling && task.toolName != 'Image Converter')
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: IconButton(
                  icon: const Icon(LucideIcons.x, size: 20),
                  onPressed: () => _cancelTask(ref, task.toolName),
                  tooltip: 'Cancel',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildElapsedText(ThemeData theme, Duration elapsed) {
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;
    final timeStr = '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    
    return Text(
      timeStr,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, bool isActive, bool isFailed, String filename) {
    IconData iconData = LucideIcons.file;
    Color iconColor = theme.colorScheme.primary;

    if (isActive) {
      iconData = LucideIcons.loader2;
      iconColor = theme.colorScheme.secondary;
    } else if (isFailed) {
      iconData = LucideIcons.alertCircle;
      iconColor = theme.colorScheme.error;
    } else {
      final ext = p.extension(filename).toLowerCase();
      if (['.jpg', '.png', '.webp'].contains(ext)) {
        iconData = LucideIcons.image;
      } else if (['.mp4', '.mov'].contains(ext)) {
        iconData = LucideIcons.video;
      } else if (['.mp3', '.m4a', '.wav'].contains(ext)) {
        iconData = LucideIcons.music;
      } else if (ext == '.pdf') {
        iconData = LucideIcons.fileText;
      }
    }

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: iconColor.withAlpha(30),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(iconData, color: iconColor, size: 20),
    );
  }

  void _cancelTask(WidgetRef ref, String toolName) {
    switch (toolName) {
      case 'Video Converter':
        ref.read(videoConverterProvider.notifier).cancel();
        break;
      case 'Video Compression':
        ref.read(videoCompressionProvider.notifier).cancel();
        break;
      case 'Audio Converter':
        ref.read(audioConverterProvider.notifier).cancel();
        break;
      case 'Video to Audio':
        ref.read(videoToAudioProvider.notifier).cancel();
        break;
      case 'Image Converter':
        ref.read(imageConverterProvider.notifier).cancel();
        break;
      case 'Image to PDF':
        ref.read(imageToPdfProvider.notifier).cancel();
        break;
      case 'Document Converter':
        ref.read(documentConvertProvider.notifier).cancel();
        break;
      case 'Greyscale PDF':
        ref.read(greyscalePdfProvider.notifier).cancel();
        break;
      case 'Merge PDF':
        ref.read(mergePdfProvider.notifier).cancel();
        break;
      case 'Split PDF':
        ref.read(splitPdfProvider.notifier).cancel();
        break;
    }
  }
}
