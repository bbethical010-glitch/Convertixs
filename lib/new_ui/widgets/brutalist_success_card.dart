import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:open_file/open_file.dart';
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import '../../core/services/ad_service.dart';
import '../../core/services/output_location_service.dart';
import '../theme/brutalist_theme.dart';
import 'brutalist_button.dart';

class BrutalistSuccessCard extends StatefulWidget {
  final String fileName;
  final int? fileSizeBytes;
  final String? outputPath;
  final String? displayLocation;
  final String? originalSizeBytes;
  final VoidCallback? onConvertAnother;

  const BrutalistSuccessCard({
    super.key,
    required this.fileName,
    this.fileSizeBytes,
    this.outputPath,
    this.displayLocation,
    this.originalSizeBytes,
    this.onConvertAnother,
  });

  @override
  State<BrutalistSuccessCard> createState() => _BrutalistSuccessCardState();
}

class _BrutalistSuccessCardState extends State<BrutalistSuccessCard> {
  @override
  void initState() {
    super.initState();
    // Guarantee interstitial ad popup when the success card is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AdService.showInterstitialAdIfAvailable();
    });
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return 'Saved';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  void _openFile(BuildContext context) async {
    final path = widget.outputPath;
    if (path == null) return;
    try {
      final res = await OpenFile.open(path);
      if (res.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open file: ${res.message}'),
            backgroundColor: BrutalColors.black,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: BrutalColors.black,
          ),
        );
      }
    }
  }

  void _shareFile() {
    final path = widget.outputPath;
    if (path == null) return;
    Share.shareXFiles([XFile(path)]);
  }

  void _showFolder(BuildContext context) async {
    final loc = widget.displayLocation ?? widget.outputPath;
    if (loc == null) return;
    try {
      final lastSlash = loc.lastIndexOf('/');
      final rel = lastSlash == -1 ? loc : loc.substring(0, lastSlash);
      await outputLocationService.showInFolder(rel);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to: $loc'),
            backgroundColor: BrutalColors.black,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ext = p.extension(widget.fileName).replaceAll('.', '').toUpperCase();

    return Container(
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: BrutalTheme.brutalBorderLg,
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
                // Success Indicator Header
                Center(
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: const BoxDecoration(
                      color: BrutalColors.black,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: const Icon(LucideIcons.check, size: 30, color: BrutalColors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'CONVERSION COMPLETE!',
                    textAlign: TextAlign.center,
                    style: BrutalTheme.headline(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: BrutalColors.black,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    'Saved with high visual fidelity directly on device',
                    textAlign: TextAlign.center,
                    style: BrutalTheme.body(
                      fontSize: 12,
                      color: BrutalColors.textMuted,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // File Details Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: BrutalColors.surfaceContainerLow,
                    border: BrutalTheme.brutalBorder,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: const BoxDecoration(
                              color: BrutalColors.surfaceContainerHigh,
                              border: BrutalTheme.brutalBorder,
                            ),
                            child: Stack(
                              children: [
                                const Center(
                                  child: Icon(LucideIcons.file, size: 24, color: BrutalColors.black),
                                ),
                                if (ext.isNotEmpty)
                                  Positioned(
                                    bottom: 0,
                                    right: 0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                                      color: BrutalColors.black,
                                      child: Text(
                                        ext,
                                        style: BrutalTheme.label(
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          color: BrutalColors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.fileName,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: BrutalTheme.headline(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      _formatBytes(widget.fileSizeBytes),
                                      style: BrutalTheme.headline(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: BrutalColors.surfaceContainer,
                                        border: Border.all(color: BrutalColors.black, width: 1),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(LucideIcons.arrowDown, size: 10, color: BrutalColors.black),
                                          const SizedBox(width: 2),
                                          Text(
                                            'OPTIMIZED',
                                            style: BrutalTheme.label(
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Directory Badge
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        decoration: BoxDecoration(
                          color: BrutalColors.white,
                          border: Border.all(color: BrutalColors.black, width: 1),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.folder, size: 14, color: BrutalColors.black),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                widget.displayLocation ?? widget.outputPath ?? 'Downloads/Convertix',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: BrutalTheme.body(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Action Buttons Grid
                BrutalistButton(
                  onPressed: () => _openFile(context),
                  label: 'Open File',
                  icon: const Icon(LucideIcons.playCircle, size: 18, color: BrutalColors.white),
                  isExpanded: true,
                  height: 48,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: BrutalistButton(
                        style: BrutalButtonStyle.secondary,
                        onPressed: () => _showFolder(context),
                        label: 'Show Folder',
                        icon: const Icon(LucideIcons.folder, size: 16, color: BrutalColors.black),
                        height: 44,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: BrutalistButton(
                        style: BrutalButtonStyle.secondary,
                        onPressed: _shareFile,
                        label: 'Share',
                        icon: const Icon(LucideIcons.share2, size: 16, color: BrutalColors.black),
                        height: 44,
                      ),
                    ),
                  ],
                ),
                if (widget.onConvertAnother != null) ...[
                  const SizedBox(height: 8),
                  BrutalistButton(
                    style: BrutalButtonStyle.dashed,
                    onPressed: widget.onConvertAnother,
                    label: 'Convert Another File',
                    icon: const Icon(LucideIcons.plusCircle, size: 16, color: BrutalColors.black),
                    isExpanded: true,
                    height: 44,
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
