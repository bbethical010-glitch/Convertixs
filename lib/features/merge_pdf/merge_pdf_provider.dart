import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import '../../../core/models/conversion_result.dart';
import '../../../core/services/backend_service.dart';
import '../../../core/services/file_service.dart';
import '../../../core/services/history_service.dart';
import '../../../core/services/output_location_service.dart';
import '../../../core/services/global_task_manager.dart';
import 'package:uuid/uuid.dart';

final mergePdfProvider = AsyncNotifierProvider<MergePdfNotifier, ConversionResult?>(() {
  return MergePdfNotifier();
});

class MergePdfNotifier extends AsyncNotifier<ConversionResult?> {
  CancelToken? _cancelToken;
  String? _activeJobId;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required List<String> inputPaths,
    void Function(double progress, [String? stageLabel])? onProgress,
  }) async {
    state = const AsyncLoading();
    _cancelToken = CancelToken();
    final jobId = const Uuid().v4();
    _activeJobId = jobId;

    final historyService = ref.read(historyServiceProvider);
    
    final inputFilename = inputPaths.map((p) => p.split(RegExp(r'[\\/]')).last).join(', ');
    final taskObj = ActiveTask(
      taskId: jobId,
      toolName: 'Merge PDF',
      inputFileName: inputFilename,
      targetFormat: 'pdf',
      progress: -1.0,
      elapsed: Duration.zero,
      startTime: DateTime.now(),
      status: TaskStatus.running,
      stageLabel: 'Starting...',
    );
    ref.read(globalTaskManagerProvider.notifier).registerTask(taskObj);
    final startTime = DateTime.now();
    state = await AsyncValue.guard(() => historyService.runTaskWithHistory(
      inputFilename: inputFilename,
      toolName: 'Merge PDF',
      task: () async {
        final String outputDir = await fileService.getOutputDir();
        final String outputName = fileService.buildOutputPath(p.basename(inputPaths.first), 'pdf');
        final String outputPath = p.join(outputDir, outputName);

        final result = await backendService.uploadAndConvert(
          tool: ConvertixTool.mergePdf,
          endpoint: '/merge-pdf',
          fields: {},
          filePaths: inputPaths,
          outputPath: outputPath,
          outputFilename: outputName,
          onProgress: (double p, [String? label]) {
            onProgress?.call(p, label);
            final elapsed = DateTime.now().difference(startTime);
            ref.read(globalTaskManagerProvider.notifier).updateProgress(jobId, -1.0, null, elapsed, stageLabel: label);
          },
          cancelToken: _cancelToken,
        );
        
        if (!result.success && !result.isCancelled) {
          ref.read(globalTaskManagerProvider.notifier).failTask(jobId, result.errorMessage ?? 'Merge failed');
          throw Exception(result.errorMessage ?? 'Merge failed');
        }
        
        if (result.isCancelled) {
          ref.read(globalTaskManagerProvider.notifier).cancelTask(jobId);
          return null;
        }
        
        ref.read(globalTaskManagerProvider.notifier).completeTask(jobId);
        return result;
      }
    )).catchError((e) {
      ref.read(globalTaskManagerProvider.notifier).failTask(jobId, e.toString());
      throw e;
    });
    _activeJobId = null;
  }

  void cancel() {
    if (_activeJobId != null) {
      ref.read(globalTaskManagerProvider.notifier).cancelTask(_activeJobId!);
    }
    _cancelToken?.cancel('User cancelled');
    state = const AsyncData(null);
  }
}
