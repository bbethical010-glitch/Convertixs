import 'dart:io';
import 'package:archive/archive.dart';
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

final splitPdfProvider = AsyncNotifierProvider<SplitPdfNotifier, ConversionResult?>(() {
  return SplitPdfNotifier();
});

class SplitPdfNotifier extends AsyncNotifier<ConversionResult?> {
  CancelToken? _cancelToken;
  String? _activeJobId;

  @override
  Future<ConversionResult?> build() async => null;

  Future<void> convert({
    required String inputPath,
    required int splitBy,
    void Function(double progress, [String? stageLabel])? onProgress,
  }) async {
    state = const AsyncLoading();
    _cancelToken = CancelToken();
    final jobId = const Uuid().v4();
    _activeJobId = jobId;

    final historyService = ref.read(historyServiceProvider);

    final inputFilename = inputPath.split(RegExp(r'[\\/]')).last;
    final taskObj = ActiveTask(
      taskId: jobId,
      toolName: 'Split PDF',
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
      toolName: 'Split PDF',
      task: () async {
        final String outputDir = await fileService.getOutputDir();
        final String outputName = fileService.buildOutputPath(p.basename(inputPath), 'zip');
        final String outputPath = p.join(outputDir, outputName);

        final result = await backendService.uploadAndConvert(
          tool: ConvertixTool.splitPdf,
          endpoint: '/split-pdf',
          fields: {
            'split_by': splitBy,
          },
          filePaths: [inputPath],
          outputPath: outputPath,
          outputFilename: outputName,
          onProgress: (double p, [String? label]) {
            onProgress?.call(p, label);
            final elapsed = DateTime.now().difference(startTime);
            ref.read(globalTaskManagerProvider.notifier).updateProgress(jobId, -1.0, null, elapsed, stageLabel: label);
          },
          cancelToken: _cancelToken,
          skipPublish: true, // We will extract and publish the PDFs ourselves
        );
        
        if (!result.success && !result.isCancelled) {
          ref.read(globalTaskManagerProvider.notifier).failTask(jobId, result.errorMessage ?? 'Split failed');
          throw Exception(result.errorMessage ?? 'Split failed');
        }
        
        if (result.isCancelled) {
          ref.read(globalTaskManagerProvider.notifier).cancelTask(jobId);
          return null;
        }
        
        onProgress?.call(0.96, 'Extracting PDF pages...');
        final postElapsed = DateTime.now().difference(startTime);
        ref.read(globalTaskManagerProvider.notifier).updateProgress(jobId, -1.0, null, postElapsed, stageLabel: 'Extracting PDF pages...');
        
        // Decode the ZIP file
        final bytes = await File(result.outputPath).readAsBytes();
        final archive = ZipDecoder().decodeBytes(bytes);
        
        if (archive.isEmpty) {
          throw Exception('No pages were returned from the server');
        }

        final stem = p.basenameWithoutExtension(inputPath);
        
        if (archive.length == 1) {
          // Single PDF in archive -> save directly as a file, not a subfolder
          final pdfFile = archive.first;
          final tempPdfPath = p.join(outputDir, 'temp_${pdfFile.name}');
          await File(tempPdfPath).writeAsBytes(pdfFile.content as List<int>);
          
          final savedOutput = await outputLocationService.publish(
            tool: ConvertixTool.splitPdf,
            sourcePath: tempPdfPath,
            bareFileName: '${stem}_page_1.pdf',
          );
          
          // Clean up temp file
          await File(tempPdfPath).delete();
          
          ref.read(globalTaskManagerProvider.notifier).completeTask(jobId);

          return ConversionResult.success(
            outputPath: result.outputPath, // Keep the ZIP path in outputPath for Share
            outputFormat: 'pdf',
            fileSizeBytes: pdfFile.size,
            durationMs: result.durationMs,
            contentUri: savedOutput.uri,
            displayLocation: savedOutput.displayLocation,
            isPublic: savedOutput.isPublic,
          );
        }
        
        // Multiple PDFs in archive -> save into a subfolder
        final subDirName = '${stem}_split';
        final savedUris = <String>[];
        String? displayLocation;
        bool isPublic = false;
        
        try {
          for (final file in archive) {
            if (file.isFile) {
              final tempPdfPath = p.join(outputDir, 'temp_${file.name}');
              await File(tempPdfPath).writeAsBytes(file.content as List<int>);
              
              final savedOutput = await outputLocationService.publish(
                tool: ConvertixTool.splitPdf,
                sourcePath: tempPdfPath,
                bareFileName: file.name,
                subDir: subDirName,
              );
              
              savedUris.add(savedOutput.uri);
              displayLocation = savedOutput.displayLocation;
              isPublic = savedOutput.isPublic;
              
              // Clean up temp file
              await File(tempPdfPath).delete();
            }
          }
        } catch (e) {
          // Rollback all written files
          await outputLocationService.discard(savedUris);
          throw Exception('Failed to save extracted PDFs: $e');
        }
        
        // The parent folder location
        final folderDisplayLocation = displayLocation != null ? p.dirname(displayLocation) : null;
        
        ref.read(globalTaskManagerProvider.notifier).completeTask(jobId);
        return ConversionResult.success(
          outputPath: result.outputPath, // Keep the ZIP path in outputPath for Share
          outputFormat: 'pdf',
          fileSizeBytes: bytes.length, // Size of original ZIP
          durationMs: result.durationMs,
          contentUri: null, // Since we saved multiple files, there's no single contentUri for the folder
          displayLocation: folderDisplayLocation,
          isPublic: isPublic,
        );
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
