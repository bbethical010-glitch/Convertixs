import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'document_convert_provider.dart';
import '../../../core/widgets/file_picker_button.dart';
import '../../../core/widgets/conversion_progress.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/success_card.dart';
import '../../../core/widgets/banner_ad_widget.dart';
import '../../../core/providers/shared_preferences_provider.dart';

class DocumentConvertScreen extends ConsumerStatefulWidget {
  const DocumentConvertScreen({super.key});

  @override
  ConsumerState<DocumentConvertScreen> createState() => _DocumentConvertScreenState();
}

class _DocumentConvertScreenState extends ConsumerState<DocumentConvertScreen> {
  String? _inputPath;
  late String _targetFormat;
  double _progress = 0.0;
  String? _stageLabel;

  @override
  void initState() {
    super.initState();
    final prefs = ref.read(sharedPreferencesProvider);
    _targetFormat = prefs.getString('default_format_documentConverter') ?? 'pdf';
  }

  void _onFilePicked(String path) {
    setState(() {
      _inputPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversionState = ref.watch(documentConvertProvider);
    final isConverting = conversionState is AsyncLoading;

    final documentFormats = ['pdf', 'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp', 'rtf', 'txt', 'csv'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Document Convert'),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilePickerButton(
                    label: 'Select Document',
                    icon: LucideIcons.fileText,
                    toolName: 'document_convert',
                    onFilePicked: _onFilePicked,
                  ),
                  if (_inputPath != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Target Format',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _targetFormat,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      items: documentFormats.map((format) {
                        return DropdownMenuItem(
                          value: format,
                          child: Text(format.toUpperCase()),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _targetFormat = value);
                        }
                      },
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isConverting
                          ? null
                          : () {
                              setState(() {
                                _progress = 0.05;
                                _stageLabel = 'Starting...';
                              });
                              ref.read(documentConvertProvider.notifier).convert(
                                    inputPath: _inputPath!,
                                    targetFormat: _targetFormat,
                                    onProgress: (progress, [stageLabel]) {
                                      if (mounted) {
                                        setState(() {
                                          _progress = progress;
                                          if (stageLabel != null) _stageLabel = stageLabel;
                                        });
                                      }
                                    },
                                  );
                            },
                      icon: isConverting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.refreshCcw),
                      label: Text(isConverting ? 'Converting...' : 'Convert Document'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  conversionState.when(
                    data: (result) {
                      if (result == null) return const SizedBox.shrink();
                      return SuccessCard(
                        fileName: result.outputPath.split('/').last,
                        fileSizeBytes: result.fileSizeBytes,
                        outputPath: result.outputPath,
                        contentUri: result.contentUri,
                        displayLocation: result.displayLocation,
                        onConvertAnother: () {
                          setState(() => _inputPath = null);
                          ref.read(documentConvertProvider.notifier).cancel();
                        },
                      );
                    },
                    error: (error, stack) => ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.read(documentConvertProvider.notifier).convert(
                              inputPath: _inputPath!,
                              targetFormat: _targetFormat,
                            );
                      },
                    ),
                    loading: () => ConversionProgress(
                      state: ConversionProgressState.loading,
                      progress: _progress,
                      stageLabel: _stageLabel,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: !isConverting,
            maintainState: true,
            child: const BannerAdWidget(),
          ),
        ],
      ),
    );
  }
}
