import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TaskStatus { running, cancelled, completed, failed }

class ActiveTask {
  final String taskId;
  final String toolName;
  final String inputFileName;
  final String targetFormat;
  final double progress; // 0.0 to 1.0, or -1 for indeterminate
  final Duration? eta;
  final Duration elapsed;
  final DateTime startTime;
  final TaskStatus status;
  final String? errorMessage;
  final String? stageLabel; // Added for indeterminate tasks

  ActiveTask({
    required this.taskId,
    required this.toolName,
    required this.inputFileName,
    required this.targetFormat,
    required this.progress,
    this.eta,
    required this.elapsed,
    required this.startTime,
    required this.status,
    this.errorMessage,
    this.stageLabel,
  });

  ActiveTask copyWith({
    String? taskId,
    String? toolName,
    String? inputFileName,
    String? targetFormat,
    double? progress,
    Duration? eta,
    Duration? elapsed,
    DateTime? startTime,
    TaskStatus? status,
    String? errorMessage,
    String? stageLabel,
  }) {
    // For eta to be nullable and overrideable to null, we check carefully
    // But since Dart lacks explicit absent arguments, in our design:
    // If we update progress we pass eta (which might be null).
    return ActiveTask(
      taskId: taskId ?? this.taskId,
      toolName: toolName ?? this.toolName,
      inputFileName: inputFileName ?? this.inputFileName,
      targetFormat: targetFormat ?? this.targetFormat,
      progress: progress ?? this.progress,
      eta: eta, // use the passed eta, allowing it to be null
      elapsed: elapsed ?? this.elapsed,
      startTime: startTime ?? this.startTime,
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      stageLabel: stageLabel ?? this.stageLabel,
    );
  }
}

class GlobalTaskManagerNotifier extends Notifier<List<ActiveTask>> {
  @override
  List<ActiveTask> build() => [];

  void registerTask(ActiveTask task) {
    state = [...state, task];
  }

  void updateProgress(
    String taskId,
    double progress,
    Duration? eta,
    Duration elapsed, {
    String? stageLabel,
  }) {
    state = state.map((t) {
      if (t.taskId != taskId) return t;
      return t.copyWith(
        progress: progress,
        eta: eta,
        elapsed: elapsed,
        stageLabel: stageLabel ?? t.stageLabel,
      );
    }).toList();
  }

  void completeTask(String taskId) {
    state = state.map((t) {
      if (t.taskId != taskId) return t;
      return t.copyWith(status: TaskStatus.completed, progress: 1.0);
    }).toList();

    // Remove from active list after 2 seconds (let UI show completion)
    Future.delayed(const Duration(seconds: 2), () {
      _removeTask(taskId);
    });
  }

  void cancelTask(String taskId) {
    state = state.map((t) {
      if (t.taskId != taskId) return t;
      return t.copyWith(status: TaskStatus.cancelled);
    }).toList();

    Future.delayed(const Duration(seconds: 1), () {
      _removeTask(taskId);
    });
  }

  void failTask(String taskId, String errorMessage) {
    state = state.map((t) {
      if (t.taskId != taskId) return t;
      return t.copyWith(status: TaskStatus.failed, errorMessage: errorMessage);
    }).toList();
  }

  void _removeTask(String taskId) {
    // Only remove if it hasn't been disposed or recreated
    try {
      state = state.where((t) => t.taskId != taskId).toList();
    } catch (_) {}
  }
}

final globalTaskManagerProvider =
    NotifierProvider<GlobalTaskManagerNotifier, List<ActiveTask>>(
  GlobalTaskManagerNotifier.new,
);
