import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../core/models/conversion_result.dart';
import '../../core/services/file_picker_service.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_progress_card.dart';
import '../widgets/brutalist_success_card.dart';
import '../widgets/brutalist_tag.dart';

class NewMediaToolScreen extends ConsumerStatefulWidget {
  final String title;
  final String toolName;
  final String mimeType;
  final List<String> outputFormats;
  final String initialFormat;
  final AsyncValue<ConversionResult?> conversionState;
  final Future<void> Function(
    File inputFile,
    String outputFormat,
    int quality,
    int bitrateKbps,
    String resolution,
    void Function(double progress, [String? stageLabel]) onProgress,
  ) onConvert;
  final VoidCallback onCancel;
  final bool showQualitySlider;
  final bool showBitrateDropdown;
  final bool showResolutionGrid;

  const NewMediaToolScreen({
    super.key,
    required this.title,
    required this.toolName,
    required this.mimeType,
    required this.outputFormats,
    required this.initialFormat,
    required this.conversionState,
    required this.onConvert,
    required this.onCancel,
    this.showQualitySlider = false,
    this.showBitrateDropdown = false,
    this.showResolutionGrid = false,
  });

  @override
  ConsumerState<NewMediaToolScreen> createState() => _NewMediaToolScreenState();
}

class _NewMediaToolScreenState extends ConsumerState<NewMediaToolScreen> {
  File? _selectedFile;
  int? _selectedFileSize;
  late String _selectedFormat;
  int _quality = 85;
  int _bitrate = 192;
  String _resolution = 'original';

  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  @override
  void initState() {
    super.initState();
    _selectedFormat = widget.initialFormat;
  }

  Future<void> _pickFile() async {
    final picked = await FilePickerService.pickFiles(
      toolName: widget.toolName,
      mimeType: widget.mimeType,
    );
    if (picked == null || picked.isEmpty) return;

    final path = picked.first['path']!;
    final file = File(path);
    final size = await file.length();

    setState(() {
      _selectedFile = file;
      _selectedFileSize = size;
    });
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

  Future<void> _convert() async {
    final file = _selectedFile;
    if (file == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an input file first'),
          backgroundColor: BrutalColors.black,
        ),
      );
      return;
    }

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Processing...';
      _startTime = DateTime.now();
    });

    await widget.onConvert(
      file,
      _selectedFormat,
      _quality,
      _bitrate,
      _resolution,
      (p, [stage]) {
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
    final isLoading = widget.conversionState is AsyncLoading;
    final conversionResult = widget.conversionState.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: widget.title,
        subtitle: 'High Fidelity Local Engine',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(top: 14, bottom: 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Eyebrow
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
                          'LOCAL ENGINE READY',
                          style: BrutalTheme.label(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  const BrutalistTag(label: 'ZERO DATA USAGE', inverted: true),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Live progress or result card
            if (isLoading) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: BrutalistProgressCard(
                  title: 'Converting ${widget.title}...',
                  fileName: _selectedFile != null ? p.basename(_selectedFile!.path) : 'Input file',
                  profileTag: '${_selectedFormat.toUpperCase()} OUTPUT',
                  progress: _progress,
                  elapsed: _startTime != null
                      ? DateTime.now().difference(_startTime!)
                      : const Duration(seconds: 5),
                  stageLabel: _stageLabel,
                  onCancel: widget.onCancel,
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
                              'CONVERSION FAILED',
                              style: BrutalTheme.headline(color: BrutalColors.red, fontSize: 16),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              conversionResult.errorMessage ?? 'Unknown error occurred.',
                              style: BrutalTheme.body(fontSize: 12),
                            ),
                            const SizedBox(height: 14),
                            BrutalistButton(
                              onPressed: _convert,
                              label: 'Retry Conversion',
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 18),
            ],

            // Input File Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildFileInputCard(),
            ),
            const SizedBox(height: 14),

            // Target Format Selector
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _buildTargetFormatCard(),
            ),
            const SizedBox(height: 14),

            // Optional Quality Slider
            if (widget.showQualitySlider) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildQualitySliderCard(),
              ),
              const SizedBox(height: 14),
            ],

            // Optional Bitrate Selector
            if (widget.showBitrateDropdown) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildBitrateSelectorCard(),
              ),
              const SizedBox(height: 14),
            ],

            // Optional Resolution Grid
            if (widget.showResolutionGrid) ...[
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildResolutionGridCard(),
              ),
              const SizedBox(height: 14),
            ],

            // Primary Action Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: BrutalistButton(
                onPressed: isLoading ? null : _convert,
                label: 'Convert Now',
                icon: const Icon(LucideIcons.zap, size: 20, color: BrutalColors.white),
                height: 54,
                isExpanded: true,
              ),
            ),
            const SizedBox(height: 20),

            // Sponsored Ad Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
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
                          style: BrutalTheme.label(fontSize: 10, color: BrutalColors.textMuted),
                        ),
                        const Icon(LucideIcons.info, size: 12, color: BrutalColors.textMuted),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const BannerAdWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileInputCard() {
    if (_selectedFile == null) {
      return BrutalistCard(
        onTap: _pickFile,
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
              child: const Icon(LucideIcons.uploadCloud, size: 28, color: BrutalColors.black),
            ),
            const SizedBox(height: 12),
            Text(
              'SELECT FILE TO CONVERT',
              style: BrutalTheme.headline(fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to browse device files',
              style: BrutalTheme.body(fontSize: 11, color: BrutalColors.textMuted),
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
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: BrutalColors.surfaceContainerHigh,
              border: BrutalTheme.brutalBorder,
            ),
            child: const Icon(LucideIcons.file, size: 24, color: BrutalColors.black),
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
                      onTap: _pickFile,
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
                const SizedBox(height: 6),
                BrutalistTag(label: sizeStr),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetFormatCard() {
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
                  const Icon(LucideIcons.fileOutput, size: 18, color: BrutalColors.black),
                  const SizedBox(width: 6),
                  Text('TARGET FORMAT', style: BrutalTheme.label(fontSize: 11)),
                ],
              ),
              const BrutalistTag(label: 'HIGH FIDELITY'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.outputFormats.map((fmt) {
              final isSelected = _selectedFormat == fmt;
              return GestureDetector(
                onTap: () => setState(() => _selectedFormat = fmt),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? BrutalColors.black : BrutalColors.white,
                    border: BrutalTheme.brutalBorder,
                    boxShadow: isSelected ? BrutalTheme.brutalShadowSm : null,
                  ),
                  child: Text(
                    fmt.toUpperCase(),
                    style: BrutalTheme.label(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? BrutalColors.white : BrutalColors.black,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildQualitySliderCard() {
    return BrutalistCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('IMAGE QUALITY: $_quality%', style: BrutalTheme.label(fontSize: 11)),
              Text('OPTIMAL: 85%', style: BrutalTheme.label(fontSize: 10, color: BrutalColors.textMuted)),
            ],
          ),
          const SizedBox(height: 8),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: BrutalColors.black,
              inactiveTrackColor: BrutalColors.surfaceContainerHigh,
              thumbColor: BrutalColors.black,
              trackHeight: 4,
            ),
            child: Slider(
              min: 10,
              max: 100,
              divisions: 18,
              value: _quality.toDouble(),
              onChanged: (val) => setState(() => _quality = val.round()),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBitrateSelectorCard() {
    return BrutalistCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('AUDIO BITRATE', style: BrutalTheme.label(fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [128, 192, 256, 320].map((b) {
              final isSelected = _bitrate == b;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _bitrate = b),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? BrutalColors.black : BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: isSelected ? BrutalTheme.brutalShadowSm : null,
                    ),
                    child: Center(
                      child: Text(
                        '$b K',
                        style: BrutalTheme.label(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? BrutalColors.white : BrutalColors.black,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResolutionGridCard() {
    return BrutalistCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('RESOLUTION', style: BrutalTheme.label(fontSize: 11)),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildResChip('original', 'Original'),
              const SizedBox(width: 6),
              _buildResChip('1080p', '1080P'),
              const SizedBox(width: 6),
              _buildResChip('720p', '720P'),
              const SizedBox(width: 6),
              _buildResChip('480p', '480P'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildResChip(String id, String label) {
    final isSelected = _resolution == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _resolution = id),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? BrutalColors.black : BrutalColors.white,
            border: BrutalTheme.brutalBorder,
            boxShadow: isSelected ? BrutalTheme.brutalShadowSm : null,
          ),
          child: Center(
            child: Text(
              label,
              style: BrutalTheme.label(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: isSelected ? BrutalColors.white : BrutalColors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
