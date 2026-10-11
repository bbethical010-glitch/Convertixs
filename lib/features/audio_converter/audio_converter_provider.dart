import 'dart:io';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/conversion_result.dart';
import '../../../core/services/ffmpeg_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/global_task_manager.dart';
import '../../../core/services/output_location_service.dart';
import '../media_tools/media_conversion_utils.dart';

class AudioConverterConfig {
  final String outputFormat;
  final int bitrateKbps;

  const AudioConverterConfig({
    required this.outputFormat,
    this.bitrateKbps = 192,
  });

  bool get showBitrateSelector => !isLosslessAudioFormat(outputFormat);
}

class AudioConverterNotifier extends AsyncNotifier<ConversionResult?> {
  String? _activeJobId;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required AudioConverterConfig config,
    void Function(double, [String?])? onProgress,
  }) async {
    state = const AsyncLoading();
    final historyService = ref.read(historyServiceProvider);
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputFile.path.split(RegExp(r'[\\/]')).last,
      toolName: 'Audio Converter',
      task: () => _run(inputFile, config, onProgress),
    ));
  }

  void cancel() {
    final jobId = _activeJobId;
    if (jobId != null) {
      ref.read(globalTaskManagerProvider.notifier).cancelTask(jobId);
      unawaited(ffmpegService.cancelSession(jobId));
    }
    state = const AsyncData(null);
  }

  Future<ConversionResult> _run(File inputFile, AudioConverterConfig config, void Function(double, [String?])? onProgress) async {
    final jobId = uuid.v4();
    _activeJobId = jobId;

    final outputFormat = config.outputFormat.toLowerCase();
    final outputPath = await buildFullOutputPath(inputFile, outputFormat);
    final tempInputPath = await fileService.copyToTemp(inputFile.path, jobId);
    final codec = audioCodecForFormat(outputFormat);
    final bitrateArg = isLosslessAudioFormat(outputFormat) ? '' : '-b:a ${config.bitrateKbps}k';
    final command = '-y -i ${quotePath(tempInputPath)} -c:a $codec $bitrateArg ${quotePath(outputPath)}';

    final inputFileName = inputFile.path.split(RegExp(r'[\\/]')).last;
    final task = ActiveTask(
      taskId: jobId,
      toolName: 'Audio Converter',
      inputFileName: inputFileName,
      targetFormat: outputFormat,
      progress: 0.0,
      elapsed: Duration.zero,
      startTime: DateTime.now(),
      status: TaskStatus.running,
    );
    ref.read(globalTaskManagerProvider.notifier).registerTask(task);

    try {
      final result = await ffmpegService.execute(
        tool: ConvertixTool.audioConverter,
        sourcePath: inputFile.path,
        command: command,
        jobId: jobId,
        outputPath: outputPath,
        onProgress: (p, eta, elapsed) {
          onProgress?.call(p, eta?.toString());
          ref.read(globalTaskManagerProvider.notifier).updateProgress(jobId, p, eta, elapsed);
        },
      );

      if (result.success) {
        ref.read(globalTaskManagerProvider.notifier).completeTask(jobId);
      } else if (result.isCancelled) {
        ref.read(globalTaskManagerProvider.notifier).cancelTask(jobId);
      } else {
        ref.read(globalTaskManagerProvider.notifier).failTask(jobId, result.errorMessage ?? 'Failed');
      }
      return result;
    } catch (e) {
      ref.read(globalTaskManagerProvider.notifier).failTask(jobId, e.toString());
      rethrow;
    } finally {
      if (_activeJobId == jobId) {
        _activeJobId = null;
      }
    }
  }
}

final audioConverterProvider =
    AsyncNotifierProvider<AudioConverterNotifier, ConversionResult?>(AudioConverterNotifier.new);
