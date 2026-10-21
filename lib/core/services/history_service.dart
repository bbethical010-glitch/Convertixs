import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';

import '../models/history_entry.dart';
import '../models/conversion_result.dart';
import 'ad_service.dart';

final historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService();
});

class HistoryService {
  static const String _boxName = 'conversion_history';
  late Box<HistoryEntry> _box;

  Future<void> init() async {
    _box = await Hive.openBox<HistoryEntry>(_boxName);
  }

  Box<HistoryEntry> get box => _box;
  
  ValueListenable<Box<HistoryEntry>> listenable() => _box.listenable();

  List<HistoryEntry> getAllEntries() {
    final entries = _box.values.toList();
    // Sort by timestamp descending (newest first)
    entries.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return entries;
  }
  
  List<HistoryEntry> getActiveEntries() {
    final entries = _box.values.where((e) => e.status == HistoryEntryStatus.active).toList();
    entries.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return entries;
  }

  List<HistoryEntry> getCompletedEntries() {
    final entries = _box.values.where((e) => e.status != HistoryEntryStatus.active).toList();
    entries.sort((a, b) => b.timestampMs.compareTo(a.timestampMs));
    return entries;
  }

  /// Called before a tool starts converting to register an active task.
  Future<String> addActiveEntry({
    required String inputFilename,
    required String toolName,
  }) async {
    final id = const Uuid().v4();
    final entry = HistoryEntry(
      id: id,
      inputFilename: inputFilename,
      outputFilename: '', // Will be updated when complete
      toolName: toolName,
      timestampMs: DateTime.now().millisecondsSinceEpoch,
      status: HistoryEntryStatus.active,
    );
    await _box.put(id, entry);
    return id;
  }

  /// Called when a tool finishes successfully.
  Future<void> markCompleted({
    required String id,
    required String outputFilename,
    required int fileSizeBytes,
    String? contentUri,
    String? displayLocation,
  }) async {
    final entry = _box.get(id);
    if (entry != null) {
      final updated = entry.copyWith(
        outputFilename: outputFilename,
        fileSizeBytes: fileSizeBytes,
        contentUri: contentUri,
        displayLocation: displayLocation,
        status: HistoryEntryStatus.completed,
      );
      await _box.put(id, updated);
    }
  }

  /// Called when a tool fails or is cancelled.
  Future<void> markFailed({
    required String id,
    required HistoryEntryStatus status,
    String? errorMessage,
  }) async {
    final entry = _box.get(id);
    if (entry != null) {
      final updated = entry.copyWith(
        status: status,
        errorMessage: errorMessage,
      );
      await _box.put(id, updated);
    }
  }
  
  /// Called to rename a file's display name and location in history
  Future<void> updateOutputName({
    required String id,
    required String newOutputFilename,
    required String newDisplayLocation,
  }) async {
    final entry = _box.get(id);
    if (entry != null) {
      final updated = entry.copyWith(
        outputFilename: newOutputFilename,
        displayLocation: newDisplayLocation,
      );
      await _box.put(id, updated);
    }
  }

  /// Called to delete an entry from history (and optionally storage).
  Future<void> deleteEntry(String id) async {
    await _box.delete(id);
  }

  /// Clear all history.
  Future<void> clearAll() async {
    await _box.clear();
  }

  /// Wrapper to run a conversion task and automatically log its history.
  Future<ConversionResult?> runTaskWithHistory({
    required String inputFilename,
    required String toolName,
    required Future<ConversionResult?> Function() task,
  }) async {
    final id = await addActiveEntry(
      inputFilename: inputFilename,
      toolName: toolName,
    );

    // Warm up/preload interstitial ad while conversion runs
    AdService.preloadInterstitialAd();

    try {
      final result = await task();
      if (result != null) {
        if (result.success) {
          await markCompleted(
            id: id,
            outputFilename: result.outputPath.split(RegExp(r'[\\/]')).last,
            fileSizeBytes: result.fileSizeBytes,
            contentUri: result.contentUri,
            displayLocation: result.displayLocation,
          );

          // Pop up interstitial ad after every successful conversion
          Future.delayed(const Duration(milliseconds: 300), () {
            AdService.showInterstitialAdIfAvailable();
          });
        } else if (result.isCancelled) {
          await markFailed(id: id, status: HistoryEntryStatus.cancelled);
        } else {
          await markFailed(
            id: id,
            status: HistoryEntryStatus.failed,
            errorMessage: result.errorMessage,
          );
        }
      } else {
        await markFailed(id: id, status: HistoryEntryStatus.cancelled);
      }
      return result;
    } catch (e) {
      await markFailed(
        id: id,
        status: HistoryEntryStatus.failed,
        errorMessage: e.toString(),
      );
      rethrow;
    }
  }
}
