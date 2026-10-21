import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'merge_pdf_provider.dart';
import '../../../core/widgets/file_picker_button.dart';
import '../../../core/widgets/conversion_progress.dart';
import '../../../core/widgets/error_card.dart';
import '../../../core/widgets/success_card.dart';
import '../../../core/widgets/banner_ad_widget.dart';

class MergePdfScreen extends ConsumerStatefulWidget {
  const MergePdfScreen({super.key});

  @override
  ConsumerState<MergePdfScreen> createState() => _MergePdfScreenState();
}

class _MergePdfScreenState extends ConsumerState<MergePdfScreen> {
  List<String> _inputPaths = [];
  double _progress = 0.0;
  String? _stageLabel;

  void _onFilesPicked(List<String> paths) {
    setState(() {
      _inputPaths = paths;
    });
  }

  @override
  Widget build(BuildContext context) {
    final conversionState = ref.watch(mergePdfProvider);
    final isConverting = conversionState is AsyncLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Merge PDFs'),
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
                    label: 'Select PDFs',
                    icon: LucideIcons.files,
                    
                    toolName: 'merge_pdf',
                    allowMultiple: true,
                    onFilesPicked: _onFilesPicked,
                  ),
                  if (_inputPaths.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${_inputPaths.length} PDFs selected',
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: isConverting || _inputPaths.length < 2
                          ? null
                          : () {
                              setState(() {
                                _progress = 0.05;
                                _stageLabel = 'Starting...';
                              });
                              ref.read(mergePdfProvider.notifier).convert(
                                    inputPaths: _inputPaths,
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
                          : const Icon(LucideIcons.combine),
                      label: Text(isConverting ? 'Merging...' : 'Merge PDFs'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                    if (_inputPaths.length < 2)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Please select at least 2 PDFs to merge',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                          ),
                          textAlign: TextAlign.center,
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
                          setState(() => _inputPaths = []);
                          ref.read(mergePdfProvider.notifier).cancel();
                        },
                      );
                    },
                    error: (error, stack) => ErrorCard(
                      message: error.toString(),
                      onRetry: () {
                        ref.read(mergePdfProvider.notifier).convert(
                              inputPaths: _inputPaths,
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
