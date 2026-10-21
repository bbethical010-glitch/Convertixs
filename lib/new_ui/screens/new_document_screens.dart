import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path/path.dart' as p;

import '../../core/services/file_picker_service.dart';
import '../../core/widgets/banner_ad_widget.dart';
import '../../features/document_convert/document_convert_provider.dart';
import '../../features/greyscale_pdf/greyscale_pdf_provider.dart';
import '../../features/image_to_pdf/image_to_pdf_provider.dart';
import '../../features/merge_pdf/merge_pdf_provider.dart';
import '../../features/split_pdf/split_pdf_provider.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_button.dart';
import '../widgets/brutalist_card.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_progress_card.dart';
import '../widgets/brutalist_success_card.dart';
import '../widgets/brutalist_tag.dart';

// ----------------------------------------------------
// 1. Document Convert (DOCX, PPTX, XLSX to PDF etc.)
// ----------------------------------------------------
class NewDocumentConvertScreen extends ConsumerStatefulWidget {
  const NewDocumentConvertScreen({super.key});

  @override
  ConsumerState<NewDocumentConvertScreen> createState() =>
      _NewDocumentConvertScreenState();
}

class _NewDocumentConvertScreenState
    extends ConsumerState<NewDocumentConvertScreen> {
  String? _inputPath;
  String _targetFormat = 'pdf';
  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  static const _formats = [
    'pdf', 'docx', 'xlsx', 'pptx', 'odt', 'ods', 'odp', 'rtf', 'txt', 'csv'
  ];

  Future<void> _pickDocument() async {
    final picked = await FilePickerService.pickFiles(
      toolName: 'document_convert',
      mimeType: '*/*',
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _inputPath = picked.first['path']);
    }
  }

  Future<void> _convert() async {
    final path = _inputPath;
    if (path == null) return;

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Uploading & Converting...';
      _startTime = DateTime.now();
    });

    await ref.read(documentConvertProvider.notifier).convert(
      inputPath: path,
      targetFormat: _targetFormat,
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
    final state = ref.watch(documentConvertProvider);
    final isLoading = state is AsyncLoading;
    final result = state.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Document Convert',
        subtitle: 'High Fidelity Cloud Engine',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrutalistTag(label: 'CLOUD SYNC • DELETED IN 30S', inverted: true),
                const BrutalistTag(label: 'OFFICE SUITE'),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              BrutalistProgressCard(
                title: 'Converting Document...',
                fileName: _inputPath != null ? p.basename(_inputPath!) : 'Document',
                profileTag: '${_targetFormat.toUpperCase()} OUTPUT',
                progress: _progress,
                elapsed: _startTime != null
                    ? DateTime.now().difference(_startTime!)
                    : const Duration(seconds: 4),
                stageLabel: _stageLabel,
                onCancel: () => ref.read(documentConvertProvider.notifier).cancel(),
              ),
              const SizedBox(height: 16),
            ] else if (result != null) ...[
              result.success
                  ? BrutalistSuccessCard(
                      fileName: p.basename(result.outputPath),
                      fileSizeBytes: result.fileSizeBytes,
                      outputPath: result.outputPath,
                      displayLocation: result.displayLocation,
                      onConvertAnother: () => setState(() => _inputPath = null),
                    )
                  : _buildErrorCard(result.errorMessage ?? 'Conversion failed', _convert),
              const SizedBox(height: 16),
            ],

            _buildPickerCard(
              title: _inputPath == null
                  ? 'SELECT DOCUMENT'
                  : p.basename(_inputPath!),
              subtitle: _inputPath == null
                  ? 'DOCX, PPTX, XLSX, ODT, RTF, PDF'
                  : 'Selected document ready for conversion',
              icon: LucideIcons.fileText,
              onTap: _pickDocument,
            ),
            const SizedBox(height: 14),

            BrutalistCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('TARGET FORMAT', style: BrutalTheme.label(fontSize: 11)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _formats.map((fmt) {
                      final isSelected = _targetFormat == fmt;
                      return GestureDetector(
                        onTap: () => setState(() => _targetFormat = fmt),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            ),
            const SizedBox(height: 16),

            BrutalistButton(
              onPressed: isLoading ? null : _convert,
              label: 'Convert Document Now',
              icon: const Icon(LucideIcons.refreshCw, size: 18, color: BrutalColors.white),
              height: 54,
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 2. Image to PDF
// ----------------------------------------------------
class NewImageToPdfScreen extends ConsumerStatefulWidget {
  const NewImageToPdfScreen({super.key});

  @override
  ConsumerState<NewImageToPdfScreen> createState() => _NewImageToPdfScreenState();
}

class _NewImageToPdfScreenState extends ConsumerState<NewImageToPdfScreen> {
  List<String> _inputPaths = [];
  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  Future<void> _pickImages() async {
    final picked = await FilePickerService.pickFiles(
      toolName: 'image_to_pdf',
      mimeType: 'image/*',
      allowMultiple: true,
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _inputPaths = picked.map((e) => e['path']!).toList();
      });
    }
  }

  Future<void> _convert() async {
    if (_inputPaths.isEmpty) return;

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Merging images to PDF...';
      _startTime = DateTime.now();
    });

    await ref.read(imageToPdfProvider.notifier).convert(
      inputPaths: _inputPaths,
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
    final state = ref.watch(imageToPdfProvider);
    final isLoading = state is AsyncLoading;
    final result = state.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Image to PDF',
        subtitle: 'Combine Clean A4/LTR',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrutalistTag(label: 'MULTI-IMAGE MERGE', inverted: true),
                BrutalistTag(label: '${_inputPaths.length} SELECTED'),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              BrutalistProgressCard(
                title: 'Building PDF...',
                fileName: '${_inputPaths.length} Images',
                profileTag: 'A4 / LTR PDF',
                progress: _progress,
                elapsed: _startTime != null
                    ? DateTime.now().difference(_startTime!)
                    : const Duration(seconds: 4),
                stageLabel: _stageLabel,
                onCancel: () => ref.read(imageToPdfProvider.notifier).cancel(),
              ),
              const SizedBox(height: 16),
            ] else if (result != null) ...[
              result.success
                  ? BrutalistSuccessCard(
                      fileName: p.basename(result.outputPath),
                      fileSizeBytes: result.fileSizeBytes,
                      outputPath: result.outputPath,
                      displayLocation: result.displayLocation,
                      onConvertAnother: () => setState(() => _inputPaths = []),
                    )
                  : _buildErrorCard(result.errorMessage ?? 'Conversion failed', _convert),
              const SizedBox(height: 16),
            ],

            _buildPickerCard(
              title: _inputPaths.isEmpty
                  ? 'SELECT IMAGES'
                  : '${_inputPaths.length} IMAGES SELECTED',
              subtitle: _inputPaths.isEmpty
                  ? 'Tap to select one or multiple images'
                  : 'Tap to change image selection',
              icon: LucideIcons.fileImage,
              onTap: _pickImages,
            ),
            const SizedBox(height: 16),

            BrutalistButton(
              onPressed: isLoading || _inputPaths.isEmpty ? null : _convert,
              label: 'Combine Into PDF',
              icon: const Icon(LucideIcons.fileText, size: 18, color: BrutalColors.white),
              height: 54,
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 3. Greyscale PDF
// ----------------------------------------------------
class NewGreyscalePdfScreen extends ConsumerStatefulWidget {
  const NewGreyscalePdfScreen({super.key});

  @override
  ConsumerState<NewGreyscalePdfScreen> createState() =>
      _NewGreyscalePdfScreenState();
}

class _NewGreyscalePdfScreenState extends ConsumerState<NewGreyscalePdfScreen> {
  String? _inputPath;
  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  Future<void> _pickPdf() async {
    final picked = await FilePickerService.pickFiles(
      toolName: 'greyscale_pdf',
      mimeType: 'application/pdf',
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _inputPath = picked.first['path']);
    }
  }

  Future<void> _convert() async {
    final path = _inputPath;
    if (path == null) return;

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Desaturating pages...';
      _startTime = DateTime.now();
    });

    await ref.read(greyscalePdfProvider.notifier).convert(
      inputPath: path,
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
    final state = ref.watch(greyscalePdfProvider);
    final isLoading = state is AsyncLoading;
    final result = state.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Greyscale PDF',
        subtitle: 'Eco Printing Toner Save',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrutalistTag(label: 'ECO MODE • SAVE TONER', inverted: true),
                const BrutalistTag(label: 'DESATURATE'),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              BrutalistProgressCard(
                title: 'Desaturating PDF...',
                fileName: _inputPath != null ? p.basename(_inputPath!) : 'PDF file',
                profileTag: 'B&W MONOCHROME',
                progress: _progress,
                elapsed: _startTime != null
                    ? DateTime.now().difference(_startTime!)
                    : const Duration(seconds: 4),
                stageLabel: _stageLabel,
                onCancel: () => ref.read(greyscalePdfProvider.notifier).cancel(),
              ),
              const SizedBox(height: 16),
            ] else if (result != null) ...[
              result.success
                  ? BrutalistSuccessCard(
                      fileName: p.basename(result.outputPath),
                      fileSizeBytes: result.fileSizeBytes,
                      outputPath: result.outputPath,
                      displayLocation: result.displayLocation,
                      onConvertAnother: () => setState(() => _inputPath = null),
                    )
                  : _buildErrorCard(result.errorMessage ?? 'Conversion failed', _convert),
              const SizedBox(height: 16),
            ],

            _buildPickerCard(
              title: _inputPath == null
                  ? 'SELECT PDF FILE'
                  : p.basename(_inputPath!),
              subtitle: _inputPath == null
                  ? 'Convert colorful PDF to crisp black and white'
                  : 'Tap to pick a different PDF file',
              icon: LucideIcons.palette,
              onTap: _pickPdf,
            ),
            const SizedBox(height: 16),

            BrutalistButton(
              onPressed: isLoading || _inputPath == null ? null : _convert,
              label: 'Make Greyscale Now',
              icon: const Icon(LucideIcons.droplets, size: 18, color: BrutalColors.white),
              height: 54,
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 4. Merge PDF
// ----------------------------------------------------
class NewMergePdfScreen extends ConsumerStatefulWidget {
  const NewMergePdfScreen({super.key});

  @override
  ConsumerState<NewMergePdfScreen> createState() => _NewMergePdfScreenState();
}

class _NewMergePdfScreenState extends ConsumerState<NewMergePdfScreen> {
  List<String> _inputPaths = [];
  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  Future<void> _pickPdfs() async {
    final picked = await FilePickerService.pickFiles(
      toolName: 'merge_pdf',
      mimeType: 'application/pdf',
      allowMultiple: true,
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() {
        _inputPaths = picked.map((e) => e['path']!).toList();
      });
    }
  }

  Future<void> _convert() async {
    if (_inputPaths.length < 2) return;

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Merging PDFs...';
      _startTime = DateTime.now();
    });

    await ref.read(mergePdfProvider.notifier).convert(
      inputPaths: _inputPaths,
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
    final state = ref.watch(mergePdfProvider);
    final isLoading = state is AsyncLoading;
    final result = state.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Merge PDFs',
        subtitle: 'Combine 2+ Files in Order',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrutalistTag(label: 'ORDER PRESERVED', inverted: true),
                BrutalistTag(label: '${_inputPaths.length} FILES SELECTED'),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              BrutalistProgressCard(
                title: 'Merging PDFs...',
                fileName: '${_inputPaths.length} PDF Documents',
                profileTag: 'COMBINED PDF',
                progress: _progress,
                elapsed: _startTime != null
                    ? DateTime.now().difference(_startTime!)
                    : const Duration(seconds: 4),
                stageLabel: _stageLabel,
                onCancel: () => ref.read(mergePdfProvider.notifier).cancel(),
              ),
              const SizedBox(height: 16),
            ] else if (result != null) ...[
              result.success
                  ? BrutalistSuccessCard(
                      fileName: p.basename(result.outputPath),
                      fileSizeBytes: result.fileSizeBytes,
                      outputPath: result.outputPath,
                      displayLocation: result.displayLocation,
                      onConvertAnother: () => setState(() => _inputPaths = []),
                    )
                  : _buildErrorCard(result.errorMessage ?? 'Merge failed', _convert),
              const SizedBox(height: 16),
            ],

            _buildPickerCard(
              title: _inputPaths.isEmpty
                  ? 'SELECT MULTIPLE PDFS'
                  : '${_inputPaths.length} PDFS READY',
              subtitle: _inputPaths.isEmpty
                  ? 'Pick 2 or more PDF files to combine'
                  : 'Tap to change selected PDF files',
              icon: LucideIcons.layers,
              onTap: _pickPdfs,
            ),
            const SizedBox(height: 16),

            BrutalistButton(
              onPressed: isLoading || _inputPaths.length < 2 ? null : _convert,
              label: 'Merge PDFs Now',
              icon: const Icon(LucideIcons.combine, size: 18, color: BrutalColors.white),
              height: 54,
              isExpanded: true,
            ),
            if (_inputPaths.isNotEmpty && _inputPaths.length < 2) ...[
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'Please select at least 2 PDF files to merge',
                  style: BrutalTheme.label(color: BrutalColors.red, fontSize: 11),
                ),
              ),
            ],
            const SizedBox(height: 20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// 5. Split PDF
// ----------------------------------------------------
class NewSplitPdfScreen extends ConsumerStatefulWidget {
  const NewSplitPdfScreen({super.key});

  @override
  ConsumerState<NewSplitPdfScreen> createState() => _NewSplitPdfScreenState();
}

class _NewSplitPdfScreenState extends ConsumerState<NewSplitPdfScreen> {
  String? _inputPath;
  int _splitBy = 1;
  double _progress = 0.0;
  String? _stageLabel;
  DateTime? _startTime;

  Future<void> _pickPdf() async {
    final picked = await FilePickerService.pickFiles(
      toolName: 'split_pdf',
      mimeType: 'application/pdf',
    );
    if (picked != null && picked.isNotEmpty) {
      setState(() => _inputPath = picked.first['path']);
    }
  }

  Future<void> _convert() async {
    final path = _inputPath;
    if (path == null) return;

    setState(() {
      _progress = 0.05;
      _stageLabel = 'Splitting pages...';
      _startTime = DateTime.now();
    });

    await ref.read(splitPdfProvider.notifier).convert(
      inputPath: path,
      splitBy: _splitBy,
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
    final state = ref.watch(splitPdfProvider);
    final isLoading = state is AsyncLoading;
    final result = state.value;

    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'Split PDF',
        subtitle: 'Extract Pages & Intervals',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const BrutalistTag(label: 'PAGE EXTRACTION', inverted: true),
                const BrutalistTag(label: 'CLEAN ARCHIVE'),
              ],
            ),
            const SizedBox(height: 14),

            if (isLoading) ...[
              BrutalistProgressCard(
                title: 'Splitting PDF...',
                fileName: _inputPath != null ? p.basename(_inputPath!) : 'PDF file',
                profileTag: 'EVERY $_splitBy PAGES',
                progress: _progress,
                elapsed: _startTime != null
                    ? DateTime.now().difference(_startTime!)
                    : const Duration(seconds: 4),
                stageLabel: _stageLabel,
                onCancel: () => ref.read(splitPdfProvider.notifier).cancel(),
              ),
              const SizedBox(height: 16),
            ] else if (result != null) ...[
              result.success
                  ? BrutalistSuccessCard(
                      fileName: p.basename(result.outputPath),
                      fileSizeBytes: result.fileSizeBytes,
                      outputPath: result.outputPath,
                      displayLocation: result.displayLocation,
                      onConvertAnother: () => setState(() => _inputPath = null),
                    )
                  : _buildErrorCard(result.errorMessage ?? 'Split failed', _convert),
              const SizedBox(height: 16),
            ],

            _buildPickerCard(
              title: _inputPath == null
                  ? 'SELECT PDF TO SPLIT'
                  : p.basename(_inputPath!),
              subtitle: _inputPath == null
                  ? 'Extract custom ranges, odd/even or every N pages'
                  : 'Tap to pick another PDF',
              icon: LucideIcons.scissors,
              onTap: _pickPdf,
            ),
            const SizedBox(height: 14),

            BrutalistCard(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('SPLIT INTERVAL (EVERY N PAGES)', style: BrutalTheme.label(fontSize: 11)),
                  const SizedBox(height: 10),
                  Row(
                    children: [1, 2, 5, 10].map((n) {
                      final isSelected = _splitBy == n;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _splitBy = n),
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
                                '$n ${n == 1 ? "PAGE" : "PAGES"}',
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
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            BrutalistButton(
              onPressed: isLoading || _inputPath == null ? null : _convert,
              label: 'Split PDF Now',
              icon: const Icon(LucideIcons.scissors, size: 18, color: BrutalColors.white),
              height: 54,
              isExpanded: true,
            ),
            const SizedBox(height: 20),
            const BannerAdWidget(),
          ],
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// Reusable Helpers
// ----------------------------------------------------
Widget _buildPickerCard({
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return BrutalistCard(
    onTap: onTap,
    padding: const EdgeInsets.all(16),
    child: Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: const BoxDecoration(
            color: BrutalColors.surfaceContainerLow,
            border: BrutalTheme.brutalBorder,
          ),
          child: Icon(icon, size: 24, color: BrutalColors.black),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrutalTheme.headline(fontSize: 13),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: BrutalTheme.body(fontSize: 11, color: BrutalColors.textMuted),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: const BoxDecoration(
            color: BrutalColors.black,
            border: BrutalTheme.brutalBorder,
            boxShadow: BrutalTheme.brutalShadowSm,
          ),
          child: Text(
            'BROWSE',
            style: BrutalTheme.label(fontSize: 10, color: BrutalColors.white),
          ),
        ),
      ],
    ),
  );
}

Widget _buildErrorCard(String message, VoidCallback onRetry) {
  return Container(
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
          'OPERATION FAILED',
          style: BrutalTheme.headline(color: BrutalColors.red, fontSize: 16),
        ),
        const SizedBox(height: 6),
        Text(message, style: BrutalTheme.body(fontSize: 12)),
        const SizedBox(height: 14),
        BrutalistButton(
          onPressed: onRetry,
          label: 'Retry Operation',
        ),
      ],
    ),
  );
}
