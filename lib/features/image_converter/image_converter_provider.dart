import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:image/image.dart' as img;

import '../../core/models/conversion_result.dart';
import '../../core/services/file_service.dart';
import '../../core/services/history_service.dart';
import '../../core/services/output_location_service.dart';
import '../../core/services/global_task_manager.dart';
import '../media_tools/media_conversion_utils.dart';

class ImageConverterConfig {
  final String outputFormat;
  final int quality;

  const ImageConverterConfig({
    required this.outputFormat,
    this.quality = 90,
  });
}

class ImageConverterNotifier extends AsyncNotifier<ConversionResult?> {
  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required ImageConverterConfig config,
    void Function(double, [String?])? onProgress,
  }) async {
    state = const AsyncLoading();
    final jobId = uuid.v4();

    final historyService = ref.read(historyServiceProvider);
    
    final inputFilename = p.basename(inputFile.path);
    final taskObj = ActiveTask(
      taskId: jobId,
      toolName: 'Image Converter',
      inputFileName: inputFilename,
      targetFormat: config.outputFormat.toLowerCase(),
      progress: -1.0,
      elapsed: Duration.zero,
      startTime: DateTime.now(),
      status: TaskStatus.running,
      stageLabel: 'Converting...',
    );
    ref.read(globalTaskManagerProvider.notifier).registerTask(taskObj);

    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputFilename,
      toolName: 'Image Converter',
      task: () => _run(inputFile, config, jobId, onProgress),
    ));
  }

  void cancel() {
    state = const AsyncData(null);
  }

  Future<ConversionResult> _run(File inputFile, ImageConverterConfig config, String jobId, void Function(double, [String?])? onProgress) async {
    onProgress?.call(-1.0, 'Converting...');
    final stopwatch = Stopwatch()..start();
    final targetFormat = config.outputFormat.toLowerCase();
    final outputPath = await buildFullOutputPath(inputFile, targetFormat);

    try {
      final tempInputPath = await fileService.copyToTemp(inputFile.path, jobId);
      final bytes = await File(tempInputPath).readAsBytes();
      final decodedImage = img.decodeImage(bytes);

      if (decodedImage == null) {
        ref.read(globalTaskManagerProvider.notifier).failTask(jobId, 'Could not read this image.');
        return ConversionResult.failure(
          outputPath: outputPath,
          outputFormat: targetFormat,
          errorMessage: 'Could not read this image. Please choose a supported image file.',
          durationMs: stopwatch.elapsedMilliseconds,
        );
      }

      onProgress?.call(-1.0, 'Converting...');
      ref.read(globalTaskManagerProvider.notifier).updateProgress(jobId, -1.0, null, stopwatch.elapsed, stageLabel: 'Converting...');

      final encodedBytes = switch (targetFormat) {
        'jpg' || 'jpeg' => img.encodeJpg(decodedImage, quality: config.quality.clamp(10, 100)),
        'png' => img.encodePng(decodedImage),
        'webp' => throw UnsupportedError('Unsupported format $targetFormat (WebP encoding not available)'),
        'bmp' => img.encodeBmp(decodedImage),
        'tiff' => img.encodeTiff(decodedImage),
        _ => throw UnsupportedError('Unsupported format $targetFormat'),
      };

      onProgress?.call(-1.0, 'Saving...');
      ref.read(globalTaskManagerProvider.notifier).updateProgress(jobId, -1.0, null, stopwatch.elapsed, stageLabel: 'Saving...');

      final outFile = File(outputPath);
      await outFile.writeAsBytes(encodedBytes);
      
      final savedOutput = await outputLocationService.publish(
        tool: ConvertixTool.imageConverter,
        sourcePath: outputPath,
        bareFileName: p.basename(outputPath),
      );
      
      onProgress?.call(1.0);

      stopwatch.stop();
      ref.read(globalTaskManagerProvider.notifier).completeTask(jobId);

      return ConversionResult.success(
        outputPath: outputPath,
        outputFormat: targetFormat,
        fileSizeBytes: await outFile.length(),
        durationMs: stopwatch.elapsedMilliseconds,
        contentUri: savedOutput.uri,
        displayLocation: savedOutput.displayLocation,
        isPublic: savedOutput.isPublic,
      );
    } catch (_) {
      stopwatch.stop();
      ref.read(globalTaskManagerProvider.notifier).failTask(jobId, 'Image conversion failed.');
      return ConversionResult.failure(
        outputPath: outputPath,
        outputFormat: targetFormat,
        errorMessage: 'Image conversion failed. Please try another file or output format.',
        durationMs: stopwatch.elapsedMilliseconds,
      );
    } finally {
      await fileService.cleanTempForJob(jobId);
    }
  }
}

final imageConverterProvider =
    AsyncNotifierProvider<ImageConverterNotifier, ConversionResult?>(ImageConverterNotifier.new);
