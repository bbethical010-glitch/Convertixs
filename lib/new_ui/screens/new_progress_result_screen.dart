import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/models/conversion_result.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_header.dart';
import '../widgets/brutalist_progress_card.dart';
import '../widgets/brutalist_success_card.dart';

class NewProgressResultScreen extends ConsumerWidget {
  final String title;
  final String fileName;
  final bool isCompleted;
  final double progress;
  final Duration elapsed;
  final Duration? eta;
  final String? stageLabel;
  final ConversionResult? result;
  final VoidCallback? onCancel;
  final VoidCallback? onConvertAnother;

  const NewProgressResultScreen({
    super.key,
    this.title = 'Compressing Video...',
    this.fileName = 'My_Video_File.mp4',
    this.isCompleted = false,
    this.progress = 0.69,
    this.elapsed = const Duration(seconds: 24),
    this.eta = const Duration(seconds: 11),
    this.stageLabel = 'Converting...',
    this.result,
    this.onCancel,
    this.onConvertAnother,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: BrutalColors.background,
      appBar: BrutalistHeader(
        title: 'File Progress',
        subtitle: isCompleted ? 'Completed' : 'Processing',
        showBackButton: true,
        onBack: () => Navigator.of(context).maybePop(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!isCompleted) ...[
              // Live Status Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8, color: BrutalColors.black),
                      const SizedBox(width: 6),
                      Text('CONVERSION STATUS', style: BrutalTheme.label(fontSize: 11)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: BrutalColors.surfaceContainerHigh,
                      border: Border.all(color: BrutalColors.black, width: 1),
                    ),
                    child: Text('ACTIVE TASK', style: BrutalTheme.label(fontSize: 10)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              BrutalistProgressCard(
                title: title,
                fileName: fileName,
                profileTag: 'FAST COMPRESS',
                progress: progress,
                elapsed: elapsed,
                eta: eta,
                stageLabel: stageLabel,
                onCancel: onCancel,
              ),
            ] else ...[
              // Completed State
              BrutalistSuccessCard(
                fileName: result?.outputPath.split(RegExp(r'[/\\]')).last ?? fileName,
                fileSizeBytes: result?.fileSizeBytes ?? 384 * 1024 * 1024,
                outputPath: result?.outputPath ?? 'Movies/Videos (Convertix)/output.mp4',
                displayLocation: result?.displayLocation ?? 'Movies/Videos (Convertix)/',
                onConvertAnother: onConvertAnother,
              ),
            ],
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
