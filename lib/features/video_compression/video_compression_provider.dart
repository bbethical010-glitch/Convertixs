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
import 'log_profiles.dart';

enum VideoCompressionQuality {
  high,
  balanced,
  small,
}

extension VideoCompressionQualityX on VideoCompressionQuality {
  String get displayName {
    switch (this) {
      case VideoCompressionQuality.high:
        return 'High Quality';
      case VideoCompressionQuality.balanced:
        return 'Balanced';
      case VideoCompressionQuality.small:
        return 'Small File';
    }
  }

  int get crf {
    switch (this) {
      case VideoCompressionQuality.high:
        return 18;
      case VideoCompressionQuality.balanced:
        return 23;
      case VideoCompressionQuality.small:
        return 28;
    }
  }
}

class VideoCompressionConfig {
  final String videoCodec;
  final VideoCompressionQuality quality;
  final String resolution;
  final String logProfileId;

  const VideoCompressionConfig({
    this.videoCodec = 'libx264',
    this.quality = VideoCompressionQuality.balanced,
    this.resolution = 'original',
    this.logProfileId = 'standard',
  });
}

class VideoCompressionNotifier extends AsyncNotifier<ConversionResult?> {
  String? _activeJobId;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required File inputFile,
    required VideoCompressionConfig config,
    void Function(double, [String?])? onProgress,
  }) async {
    state = const AsyncLoading();
    final historyService = ref.read(historyServiceProvider);
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputFile.path.split(RegExp(r'[\\/]')).last,
      toolName: 'Video Compression',
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

  Future<ConversionResult> _run(File inputFile, VideoCompressionConfig config, void Function(double, [String?])? onProgress) async {
    final jobId = uuid.v4();
    _activeJobId = jobId;

    final outputPath = await buildFullOutputPath(inputFile, 'mp4');
    final tempInputPath = await fileService.copyToTemp(inputFile.path, jobId);
    final profile = logProfileById(config.logProfileId);
    final dimensions = dimensionsForResolution(config.resolution);
    final filterChain = profile.filterChain
        .replaceAll('{w}', dimensions.width)
        .replaceAll('{h}', dimensions.height);
    final filterArg = config.resolution == 'original' && profile.id == 'standard'
        ? ''
        : '-vf "$filterChain"';
    final command =
        '-y -i ${quotePath(tempInputPath)} -c:v ${config.videoCodec} -crf ${config.quality.crf} '
        '-preset medium $filterArg -c:a copy ${quotePath(outputPath)}';

    final inputFileName = inputFile.path.split(RegExp(r'[\\/]')).last;
    final task = ActiveTask(
      taskId: jobId,
      toolName: 'Video Compression',
      inputFileName: inputFileName,
      targetFormat: 'mp4',
      progress: 0.0,
      elapsed: Duration.zero,
      startTime: DateTime.now(),
      status: TaskStatus.running,
    );
    ref.read(globalTaskManagerProvider.notifier).registerTask(task);

    try {
      final result = await ffmpegService.execute(
        tool: ConvertixTool.videoCompression,
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

final videoCompressionProvider =
    AsyncNotifierProvider<VideoCompressionNotifier, ConversionResult?>(VideoCompressionNotifier.new);
