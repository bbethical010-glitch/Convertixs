import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../core/services/file_picker_service.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../features/video_compression/video_compression_provider.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_progress_card.dart';
import '../widgets/brutalist_success_card.dart';
import '../widgets/brutalist_tag.dart';

class NewVideoCompressionScreen extends ConsumerStatefulWidget {
  const NewVideoCompressionScreen({super.key});

  @override
  ConsumerState<NewVideoCompressionScreen> createState() =>
      _NewVideoCompressionScreenState();
}

class _NewVideoCompressionScreenState
    extends ConsumerState<NewVideoCompressionScreen> {
  File? _selectedFile;
  int? _selectedFileSize;
  String _selectedPreset = 'balanced'; // balanced, high, small
  String _selectedCodec = 'libx265'; // libx265, libx264
  String _selectedRes = '1080p'; // 1080p, 720p, 480p, original

  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickVideo() async {
    final picked = await FilePickerService.pickFiles(
      toolName: 'video_compression',
      mimeType: 'video/*',
    );
    if (picked == null || picked.isEmpty) return;

    final filePath = picked.first['path']!;
    final file = File(filePath);
    final size = await file.length();

    setState(() {
      _selectedFile = file;
      _selectedFileSize = size;
    });
  }

  VideoCompressionQuality _getQuality() {
    switch (_selectedPreset) {
      case 'high':
        return VideoCompressionQuality.high;
      case 'small':
        return VideoCompressionQuality.small;
      case 'balanced':
      default:
        return VideoCompressionQuality.balanced;
    }
  }

  String _formatBytes(int? bytes) {
    if (bytes == null || bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  String _estimateSize() {
    if (_selectedFileSize == null) return '~380 MB';
    double ratio = 0.35;
    if (_selectedPreset == 'high') ratio = 0.65;
    if (_selectedPreset == 'small') ratio = 0.18;
    if (_selectedCodec == 'libx265') ratio *= 0.75;
    final est = (_selectedFileSize! * ratio).toInt();
    return _formatBytes(est);
  }

  String _estimateReduction() {
    if (_selectedPreset == 'high') return '35% REDUCTION';
    if (_selectedPreset == 'small') return '82% REDUCTION';
    return '73% REDUCTION';
  }

  Future<void> _startCompression() async {
    final file = _selectedFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a video file first'),
          backgroundColor: BrutalColors.black,
        ),
      );
      return;
    }

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Encoding...';
      _startTime = DateTime.now();
    });

    final notifier = ref.read(videoCompressionProvider.notifier);
    await notifier.convert(
      inputFile: file,
      config: VideoCompressionConfig(
        videoCodec: _selectedCodec,
        quality: _getQuality(),
        resolution: _selectedRes,
        logProfileId: 'standard',
      ),
      onProgress: (p, [stage]) {
        if (mounted) {
          setState(() {
            _progress = p;
            if (stage != null) _stageLabel = stage;
          });
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(videoCompressionProvider);
    final isLoading = state is AsyncLoading;
    final conversionResult = state.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Compress Video',
        subtitle: 'Reduce File Size',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Status Eyebrow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: Row(
                      children: [
                        Container(width: 8, height: 8, color: BrutalColors.black),
                        const SizedBox(width: 6),
                        Text(
                          'HARDWARE ENGINE READY',
                          style: BrutalTheme.label(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: const BoxDecoration(
                      color: BrutalColors.black,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: Row(
                      children: [
                        const Icon(LucideIcons.sparkles, size: 12, color: BrutalColors.white),
                        const SizedBox(width: 5),
                        Text(
                          'FAST COMPRESS',
                          style: BrutalTheme.label(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Live progress or result view if active
            if (isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BrutalistProgressCard(
                  title: 'Compressing Video...',
                  fileName: _selectedFile != null ? p.basename(_selectedFile!.path) : 'Video file',
                  profileTag: 'Compressing Video...',
                  progress: _progress,
                  elapsed: _startTime != null
                      ? DateTime.now().difference(_startTime!)
                      : const Duration(seconds: 12),
                  stageLabel: _stageLabel,
                  onCancel: () {
                    ref.read(videoCompressionProvider.notifier).cancel();
                  },
                ),
              ),
              const SizedBox(height: 18),
            ] else if (conversionResult != null) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: conversionResult.success
                    ? BrutalistSuccessCard(
                        fileName: p.basename(conversionResult.outputPath),
                        fileSizeBytes: conversionResult.fileSizeBytes,
                        outputPath: conversionResult.outputPath,
                        displayLocation: conversionResult.displayLocation,
                        onConvertAnother: () {
                          setState(() {
                            _selectedFile = null;
                            _selectedFileSize = null;
                          });
                        },
                      )
                    : Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: BrutalColors.white,
                          border: BrutalTheme.brutalBorderLg,
                          boxShadow: BrutalTheme.brutalShadowLg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(height: 6, color: BrutalColors.red),
                            const SizedBox(height: 12),
                            Text(
                              'COMPRESSION FAILED',
                              style: BrutalTheme.headline(
                                color: BrutalColors.red,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              conversionResult.errorMessage ?? 'Unknown error occurred.',
                              style: BrutalTheme.body(fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            BrutalistButton(
                              onPressed: _startCompression,
                              label: 'Retry Compression',
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 18),
            ],

            // Selected File Inspection Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFileInspectionCard(),
            ),
            const SizedBox(height: 14),

            // Compression Quality Presets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildQualitySection(),
            ),
            const SizedBox(height: 14),

            // Output Video Codec Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildCodecSection(),
            ),
            const SizedBox(height: 14),

            // Target Resolution Grid
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildResolutionSection(),
            ),
            const SizedBox(height: 14),

            // Real-time Compression Metric Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildMetricCard(),
            ),
            const SizedBox(height: 16),

            // Primary Action CTA Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BrutalistButton(
                onPressed: isLoading ? null : _startCompression,
                label: 'Compress Video Now',
                icon: const Icon(LucideIcons.zap, size: 20, color: BrutalColors.white),
                height: 56,
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 20),

            // AdMob Banner Container
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildAdBannerContainer(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInspectionCard() {
    if (_selectedFile == null) {
      return BrutalistCard(
        onTap: _pickVideo,
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                color: BrutalColors.surfaceContainerLow,
                border: BrutalTheme.brutalBorder,
              ),
              child: const Icon(LucideIcons.video, size: 28, color: BrutalColors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'SELECT VIDEO TO COMPRESS',
              style: BrutalTheme.headline(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Supports MP4, MOV, MKV, WebM, AVI, FLV & Pro Camera Formats',
              textAlign: TextAlign.center,
              style: BrutalTheme.body(
                fontSize: 11,
                color: BrutalColors.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    final fileName = p.basename(_selectedFile!.path);
    final sizeStr = _formatBytes(_selectedFileSize);

    return BrutalistCard(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: BrutalColors.surfaceContainerHigh,
              border: BrutalTheme.brutalBorder,
            ),
            child: const Center(
              child: Icon(LucideIcons.playCircle, size: 28, color: BrutalColors.black),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: BrutalTheme.headline(fontSize: 13),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: _pickVideo,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: const BoxDecoration(
                          color: BrutalColors.black,
                          border: BrutalTheme.brutalBorder,
                          boxShadow: BrutalTheme.brutalShadowSm,
                        ),
                        child: Text(
                          'CHANGE',
                          style: BrutalTheme.label(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    BrutalistTag(label: sizeStr),
                    const BrutalistTag(label: 'Auto Detect'),
                    const BrutalistTag(label: 'Hardware Source', inverted: true),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(LucideIcons.slidersHorizontal, size: 16, color: BrutalColors.black),
                const SizedBox(width: 6),
                Text('COMPRESSION LEVEL', style: BrutalTheme.label(fontSize: 11)),
              ],
            ),
            Text(
              'CHOOSE COMPRESSION',
              style: BrutalTheme.label(
                fontSize: 10,
                color: BrutalColors.textMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildQualityCard(
          id: 'balanced',
          title: 'Balanced',
          badge: 'Recommended',
          description: 'Great quality, 50% smaller file size (Best for sharing)',
        ),
        const SizedBox(height: 8),
        _buildQualityCard(
          id: 'high',
          title: 'High Quality',
          badge: 'Maximum Clarity',
          description: 'Preserves sharp video details with moderate compression',
        ),
        const SizedBox(height: 8),
        _buildQualityCard(
          id: 'small',
          title: 'Smallest File',
          badge: 'Compact',
          description: 'Maximum compression to easily send via WhatsApp & Email',
        ),
      ],
    );
  }

  Widget _buildQualityCard({
    required String id,
    required String title,
    required String badge,
    required String description,
  }) {
    final isSelected = _selectedPreset == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedPreset = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? BrutalColors.black : BrutalColors.white,
          border: BrutalTheme.brutalBorder,
          boxShadow: BrutalTheme.brutalShadowSm,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title.toUpperCase(),
                        style: BrutalTheme.headline(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? BrutalColors.white : BrutalColors.black,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isSelected ? BrutalColors.white : BrutalColors.black,
                        ),
                        child: Text(
                          badge.toUpperCase(),
                          style: BrutalTheme.label(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? BrutalColors.black : BrutalColors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: BrutalTheme.body(
                      fontSize: 11,
                      color: isSelected ? Colors.white70 : BrutalColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? BrutalColors.white : Colors.transparent,
                border: Border.all(
                  color: isSelected ? BrutalColors.white : BrutalColors.black,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Center(
                      child: Icon(LucideIcons.check, size: 16, color: BrutalColors.black),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodecSection() {
    return BrutalistCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.sparkles, size: 18, color: BrutalColors.black),
                  const SizedBox(width: 6),
                  Text('VIDEO FORMAT OPTIMIZATION', style: BrutalTheme.label(fontSize: 11)),
                ],
              ),
              const BrutalistTag(label: 'AUTO', inverted: true),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildCodecOption(
                  id: 'libx265',
                  label: 'Modern Video',
                  subtext: 'Smallest file size',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildCodecOption(
                  id: 'libx264',
                  label: 'Standard Video',
                  subtext: 'Plays on all devices',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCodecOption({
    required String id,
    required String label,
    required String subtext,
  }) {
    final isSelected = _selectedCodec == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedCodec = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? BrutalColors.black : BrutalColors.white,
          border: BrutalTheme.brutalBorder,
          boxShadow: isSelected ? BrutalTheme.brutalShadowSm : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: BrutalTheme.headline(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isSelected ? BrutalColors.white : BrutalColors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtext,
              style: BrutalTheme.label(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : BrutalColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResolutionSection() {
    return BrutalistCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.monitor, size: 18, color: BrutalColors.black),
                  const SizedBox(width: 6),
                  Text('VIDEO RESOLUTION', style: BrutalTheme.label(fontSize: 11)),
                ],
              ),
              Text(
                'SIZE FIT',
                style: BrutalTheme.label(
                  fontSize: 10,
                  color: BrutalColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildResolutionChip('1080p', '1080P', 'Full HD')),
              const SizedBox(width: 6),
              Expanded(child: _buildResolutionChip('720p', '720P', 'HD (Ideal)')),
              const SizedBox(width: 6),
              Expanded(child: _buildResolutionChip('480p', '480P', 'Smallest')),
              const SizedBox(width: 6),
              Expanded(child: _buildResolutionChip('original', 'SAME', 'Original')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionChip(String id, String label, String sub) {
    final isSelected = _selectedRes == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedRes = id),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? BrutalColors.black : BrutalColors.white,
          border: BrutalTheme.brutalBorder,
          boxShadow: isSelected ? BrutalTheme.brutalShadowSm : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: BrutalTheme.headline(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isSelected ? BrutalColors.white : BrutalColors.black,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              sub,
              style: BrutalTheme.label(
                fontSize: 8,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white70 : BrutalColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard() {
    return BrutalistCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: BrutalColors.black,
                  border: BrutalTheme.brutalBorder,
                ),
                child: const Icon(LucideIcons.hardDrive, size: 20, color: BrutalColors.white),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ESTIMATED OUTPUT',
                    style: BrutalTheme.label(
                      fontSize: 10,
                      color: BrutalColors.textMuted,
                    ),
                  ),
                  Text(
                    _estimateSize(),
                    style: BrutalTheme.headline(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: const BoxDecoration(
              color: BrutalColors.black,
              border: BrutalTheme.brutalBorder,
              boxShadow: BrutalTheme.brutalShadowSm,
            ),
            child: Row(
              children: [
                const Icon(LucideIcons.trendingDown, size: 14, color: BrutalColors.white),
                const SizedBox(width: 4),
                Text(
                  _estimateReduction(),
                  style: BrutalTheme.label(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: BrutalColors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdBannerContainer() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: BrutalTheme.brutalBorder,
        boxShadow: BrutalTheme.brutalShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SPONSORED PARTNER',
                style: BrutalTheme.label(
                  fontSize: 10,
                  color: BrutalColors.textMuted,
                  letterSpacing: 1.0,
                ),
              ),
              const Icon(LucideIcons.info, size: 12, color: BrutalColors.textMuted),
            ],
          ),
          const SizedBox(height: 6),
          const BannerAdWidget(),
        ],
      ),
    );
  }
}
