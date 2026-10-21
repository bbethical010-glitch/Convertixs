import '../../../shared/constants/format_constants.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/models/conversion_result.dart';
import '../../core/providers/shared_preferences_provider.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../core/widgets/conversion_progress.dart';
import '../../core/widgets/file_picker_button.dart';
import '../../core/widgets/format_dropdown.dart';
class LabelledOption<T> {
  final T value;
  final String label;

  const LabelledOption(this.value, this.label);
}

class MediaToolSettings {
  final String outputFormat;
  final int quality;
  final int bitrateKbps;
  final String resolution;
  final String videoCodec;
  final String compressionQuality;
  final String logProfileId;

  const MediaToolSettings({
    required this.outputFormat,
    required this.quality,
    required this.bitrateKbps,
    required this.resolution,
    required this.videoCodec,
    required this.compressionQuality,
    required this.logProfileId,
  });
}

class MediaToolScreen extends ConsumerStatefulWidget {
  final String title;
  final String inputLabel;
  final String toolName;
  final List<String> outputFormats;
  final String initialOutputFormat;
  final AsyncValue<ConversionResult?> conversionState;
  final Future<void> Function(
    File,
    MediaToolSettings,
    void Function(double progress, [String? stageLabel]),
  ) onConvert;
  final VoidCallback onCancel;
  final bool showImageQuality;
  final bool showAudioBitrate;
  final bool hideBitrateForLossless;
  final bool showResolution;
  final bool showVideoCodec;
  final bool showCompressionQuality;
  final bool showLogProfile;
  final List<LabelledOption<String>> logProfileOptions;

  const MediaToolScreen({
    super.key,
    required this.title,
    required this.inputLabel,
    required this.toolName,
    required this.outputFormats,
    required this.initialOutputFormat,
    required this.conversionState,
    required this.onConvert,
    required this.onCancel,
    this.showImageQuality = false,
    this.showAudioBitrate = false,
    this.hideBitrateForLossless = false,
    this.showResolution = false,
    this.showVideoCodec = false,
    this.showCompressionQuality = false,
    this.showLogProfile = false,
    this.logProfileOptions = const [],
  });

  @override
  ConsumerState<MediaToolScreen> createState() => _MediaToolScreenState();
}

class _MediaToolScreenState extends ConsumerState<MediaToolScreen> {
  File? _selectedFile;
  late String _outputFormat;
  late int _quality;
  int _bitrateKbps = defaultAudioBitrate;
  String _resolution = 'original';
  String _videoCodec = 'libx264';
  String _compressionQuality = 'balanced';
  String _logProfileId = 'standard';

  double _progress = 0.0;
  String? _stageLabel;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _outputFormat = prefs.getString('default_format_${widget.toolName}') ?? widget.initialOutputFormat;
    _quality = prefs.getInt('quality_preset_${widget.toolName}') ?? 90;
    
    if (widget.logProfileOptions.isNotEmpty) {
      _logProfileId = widget.logProfileOptions.first.value;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = widget.conversionState.isLoading;
    final result = widget.conversionState.hasValue ? widget.conversionState.value : null;

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  FilePickerButton(
                    toolName: widget.toolName,
                    label: widget.inputLabel,
                    onFilePicked: (path) {
                      setState(() => _selectedFile = File(path));
                    },
                  ),
                  const SizedBox(height: 16),
                  FormatDropdown(
                    formats: widget.outputFormats,
                    selectedFormat: _outputFormat,
                    label: 'Output format',
                    onChanged: (value) => setState(() => _outputFormat = value),
                  ),
                  if (_shouldShowImageQuality) ...[
                    const SizedBox(height: 16),
                    _QualitySlider(
                      value: _quality,
                      onChanged: (value) => setState(() => _quality = value),
                    ),
                  ],
                  if (_shouldShowBitrate) ...[
                    const SizedBox(height: 16),
                    _BitrateDropdown(
                      value: _bitrateKbps,
                      onChanged: (value) => setState(() => _bitrateKbps = value),
                    ),
                  ],
                  if (widget.showResolution) ...[
                    const SizedBox(height: 16),
                    FormatDropdown(
                      formats: videoResolutionOptions,
                      selectedFormat: _resolution,
                      label: 'Resolution',
                      onChanged: (value) => setState(() => _resolution = value),
                    ),
                  ],
                  if (widget.showVideoCodec) ...[
                    const SizedBox(height: 16),
                    _StringOptionsDropdown(
                      label: 'Video codec',
                      value: _videoCodec,
                      options: const [
                        LabelledOption('libx264', 'H.264'),
                        LabelledOption('libx265', 'H.265'),
                      ],
                      onChanged: (value) => setState(() => _videoCodec = value),
                    ),
                  ],
                  if (widget.showCompressionQuality) ...[
                    const SizedBox(height: 16),
                    _StringOptionsDropdown(
                      label: 'Quality preset',
                      value: _compressionQuality,
                      options: const [
                        LabelledOption('high', 'High Quality'),
                        LabelledOption('balanced', 'Balanced (Recommended)'),
                        LabelledOption('small', 'Smallest File (WhatsApp & Email)'),
                      ],
                      onChanged: (value) => setState(() => _compressionQuality = value),
                    ),
                  ],
                  if (widget.showLogProfile && widget.logProfileOptions.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    _StringOptionsDropdown(
                      label: 'LOG/HDR profile',
                      value: _logProfileId,
                      options: widget.logProfileOptions,
                      onChanged: (value) => setState(() => _logProfileId = value),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: _selectedFile == null || isLoading ? null : _convert,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Convert'),
                  ),
                  const SizedBox(height: 24),
                  _buildProgress(result, isLoading),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Visibility(
                visible: !isLoading,
                maintainState: true,
                child: const BannerAdWidget(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _shouldShowImageQuality {
    return widget.showImageQuality && (_outputFormat == 'jpg' || _outputFormat == 'jpeg' || _outputFormat == 'webp');
  }

  bool get _shouldShowBitrate {
    if (!widget.showAudioBitrate) return false;
    if (!widget.hideBitrateForLossless) return true;
    return _outputFormat != 'wav' && _outputFormat != 'flac';
  }

  Future<void> _convert() async {
    final selectedFile = _selectedFile;
    if (selectedFile == null) return;

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Converting...';
    });

    await widget.onConvert(
      selectedFile,
      MediaToolSettings(
        outputFormat: _outputFormat,
        quality: _quality,
        bitrateKbps: _bitrateKbps,
        resolution: _resolution,
        videoCodec: _videoCodec,
        compressionQuality: _compressionQuality,
        logProfileId: _logProfileId,
      ),
      (progress, [stageLabel]) {
        if (mounted) {
          setState(() {
            _progress = progress;
            if (stageLabel != null) _stageLabel = stageLabel;
          });
        }
      },
    );
  }

  Widget _buildProgress(ConversionResult? result, bool isLoading) {
    if (isLoading) {
      return ConversionProgress(
        state: ConversionProgressState.loading,
        progress: _progress,
        stageLabel: _stageLabel,
        onCancel: widget.onCancel,
      );
    }

    if (result == null) {
      return const ConversionProgress(state: ConversionProgressState.idle);
    }

    if (!result.success) {
      return ConversionProgress(
        state: ConversionProgressState.error,
        errorMessage: result.errorMessage,
        onRetry: _selectedFile == null ? null : _convert,
      );
    }

    return ConversionProgress(
      state: ConversionProgressState.success,
      fileName: p.basename(result.outputPath),
      fileSizeBytes: result.fileSizeBytes,
      outputPath: result.outputPath,
      contentUri: result.contentUri,
      displayLocation: result.displayLocation,
      onConvertAnother: () {
        setState(() => _selectedFile = null);
      },
    );
  }
}

class _QualitySlider extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QualitySlider({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quality: $value', style: Theme.of(context).textTheme.titleSmall),
            Slider(
              min: 10,
              max: 100,
              divisions: 90,
              value: value.toDouble(),
              label: '$value',
              onChanged: (next) => onChanged(next.round()),
            ),
          ],
        ),
      ),
    );
  }
}

class _BitrateDropdown extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _BitrateDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Audio bitrate',
        prefixIcon: Icon(Icons.speed),
      ),
      items: audioBitrateOptions
          .map(
            (bitrate) => DropdownMenuItem<int>(
              value: bitrate,
              child: Text('$bitrate kbps'),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}

class _StringOptionsDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<LabelledOption<String>> options;
  final ValueChanged<String> onChanged;

  const _StringOptionsDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      initialValue: options.any((option) => option.value == value) ? value : options.first.value,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(Icons.tune),
      ),
      items: options
          .map(
            (option) => DropdownMenuItem<String>(
              value: option.value,
              child: Text(option.label),
            ),
          )
          .toList(),
      onChanged: (next) {
        if (next != null) onChanged(next);
      },
    );
  }
}
