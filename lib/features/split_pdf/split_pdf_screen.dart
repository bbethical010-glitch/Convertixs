import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'split_pdf_provider.dart';
import '../../../core/widgets/file_picker_button.dart';
import '../../../core/widgets/conversion_progress.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/success_card.dart';
import '../../../core/widgets/banner_ad_widget.dart';

class SplitPdfScreen extends ConsumerStatefulWidget {
  const SplitPdfScreen({super.key});

  @override
  ConsumerState<SplitPdfScreen> createState() => _SplitPdfScreenState();
}

class _SplitPdfScreenState extends ConsumerState<SplitPdfScreen> {
  String? _inputPath;
  int _splitBy = 1;
  double _progress = 0.0;
  String? _stageLabel;

  void _onFilePicked(String path) {
    setState(() {
      _inputPath = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversionState = ref.watch(splitPdfProvider);
    final isConverting = conversionState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Split PDF'),
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
                    label: 'Select PDF',
                    icon: LucideIcons.fileText,
                    
                    toolName: 'split_pdf',
                    onFilePicked: _onFilePicked,
                  ),
                  if (_inputPath != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Split every N pages',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      initialValue: _splitBy.toString(),
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        hintText: 'e.g. 1',
                      ),
                      onChanged: (value) {
                        setState(() {
                          _splitBy = int.tryParse(value) ?? 1;
                          if (_splitBy < 1) _splitBy = 1;
                        });
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
                              ref.read(splitPdfProvider.notifier).convert(
                                    inputPath: _inputPath!,
                                    splitBy: _splitBy,
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
                          : const Icon(LucideIcons.scissors),
                      label: Text(isConverting ? 'Splitting...' : 'Split PDF'),
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
                        isFolderOutput: result.isFolderOutput,
                        onConvertAnother: () {
                          setState(() => _inputPath = null);
                          ref.read(splitPdfProvider.notifier).cancel();
                        },
                      );
                    },
                    error: (error, stack) => ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.read(splitPdfProvider.notifier).convert(
                              inputPath: _inputPath!,
                              splitBy: _splitBy,
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
