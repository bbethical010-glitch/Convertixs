import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';

import 'file_service.dart';

/// The ten Convertix tools, each mapped to a public output location.
enum ConvertixTool {
  imageConverter,
  videoConverter,
  videoCompression,
  audioConverter,
  videoToAudio,
  imageToPdf,
  documentConverter,
  greyscalePdf,
  mergePdf,
  splitPdf,
}

/// Android public media collection a tool's output belongs to.
enum OutputCollection { images, video, audio, documents }

extension OutputCollectionName on OutputCollection {
  /// Wire value understood by `MediaStoreWriter.contentUriFor`.
  String get wireName => switch (this) {
        OutputCollection.images => 'images',
        OutputCollection.video => 'video',
        OutputCollection.audio => 'audio',
        OutputCollection.documents => 'documents',
      };
}

extension ConvertixToolOutput on ConvertixTool {
  OutputCollection get collection => switch (this) {
        ConvertixTool.imageConverter => OutputCollection.images,
        ConvertixTool.videoConverter => OutputCollection.video,
        ConvertixTool.videoCompression => OutputCollection.video,
        ConvertixTool.audioConverter => OutputCollection.audio,
        ConvertixTool.videoToAudio => OutputCollection.audio,
        ConvertixTool.imageToPdf => OutputCollection.documents,
        ConvertixTool.documentConverter => OutputCollection.documents,
        ConvertixTool.greyscalePdf => OutputCollection.documents,
        ConvertixTool.mergePdf => OutputCollection.documents,
        ConvertixTool.splitPdf => OutputCollection.documents,
      };

  /// Public-storage-relative directory. Media tools share one folder per media type;
  /// each document tool gets its own subfolder under `Documents/Convertix/`.
  String get relativeDir => switch (this) {
        ConvertixTool.imageConverter => 'DCIM/Images (Convertix)',
        ConvertixTool.videoConverter => 'Movies/Videos (Convertix)',
        ConvertixTool.videoCompression => 'Movies/Videos (Convertix)',
        ConvertixTool.audioConverter => 'Music/Audio (Convertix)',
        ConvertixTool.videoToAudio => 'Music/Audio (Convertix)',
        ConvertixTool.imageToPdf => 'Documents/Convertix/Image to PDF',
        ConvertixTool.documentConverter => 'Documents/Convertix/Document Converter',
        ConvertixTool.greyscalePdf => 'Documents/Convertix/Greyscale PDF',
        ConvertixTool.mergePdf => 'Documents/Convertix/Merge PDF',
        ConvertixTool.splitPdf => 'Documents/Convertix/Split PDF',
      };
}

/// Where an output actually landed.
class SavedOutput {
  /// `content://` URI on Android. Phase 5D's Open / Show in Folder / Share consume this —
  /// never a raw filesystem path.
  final String uri;

  /// Final on-disk name, which may carry a ` (1)` collision suffix.
  final String displayName;

  /// Public-storage-relative directory, e.g. `DCIM/Images (Convertix)`.
  final String relativeDir;

  /// False when the file went to app-private storage because no public collection was
  /// available (non-Android platforms). Callers should not promise Gallery visibility.
  final bool isPublic;

  const SavedOutput({
    required this.uri,
    required this.displayName,
    required this.relativeDir,
    required this.isPublic,
  });

  /// Human-readable location for UI copy: `DCIM/Images (Convertix)/photo_123.webp`.
  String get displayLocation => '$relativeDir/$displayName';
}

/// Raised when an output could not be published. [code] mirrors the platform-channel
/// error codes: `insufficient_storage`, `permission_denied`, `io_error`,
/// `source_missing`, `mkdir_failed`, `insert_failed`, `no_external_storage`.
class OutputSaveException implements Exception {
  final String code;
  final String message;

  const OutputSaveException(this.code, this.message);

  /// Message suitable for showing to a user.
  String get userMessage => switch (code) {
        'insufficient_storage' =>
          'Not enough free storage to save the converted file.',
        'permission_denied' =>
          'Convertix does not have permission to save to that folder.',
        'source_missing' =>
          'The converted file went missing before it could be saved.',
        'no_external_storage' => 'Device storage is currently unavailable.',
        _ => 'Could not save the converted file. Please try again.',
      };

  @override
  String toString() => 'OutputSaveException($code): $message';
}

/// Publishes finished conversion outputs into Android's public media collections.
///
/// This is the single chokepoint for output placement — tools must not compute
/// destination paths themselves.
///
/// Note on the filename contract: [FileService.buildOutputPath] returns a **bare filename**
/// (`name_timestamp.ext`) with no directory. Pass that value straight through as
/// `bareFileName`; the destination directory is owned by this service. Joining it with a
/// directory yourself re-introduces the read-only-CWD bug fixed in `110bc57`.
class OutputLocationService {
  static const MethodChannel _channel =
      MethodChannel('com.allformat.convertix/media_store');

  /// Moves [sourcePath] into [tool]'s public output folder.
  ///
  /// [subDir] nests the output one level deeper, inside [ConvertixTool.relativeDir] —
  /// used by Split PDF, whose per-job folder holds one PDF per page. It is a single
  /// path segment, not a full path, and the leading/trailing slashes are normalised.
  ///
  /// The folder is created if it does not exist — including after the user deletes it
  /// manually. An existing file with the same name is never overwritten; a ` (1)` suffix
  /// is added instead.
  ///
  /// Throws [OutputSaveException] on failure. The source file is left untouched so a
  /// failed publish never destroys the conversion result.
  Future<SavedOutput> publish({
    required ConvertixTool tool,
    required String sourcePath,
    required String bareFileName,
    String? subDir,
  }) async {
    final relativeDir = _resolveRelativeDir(tool, subDir);

    if (!Platform.isAndroid) {
      return _publishToAppPrivate(
        tool: tool,
        sourcePath: sourcePath,
        bareFileName: bareFileName,
        subDir: subDir,
      );
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final customFolderUri = prefs.getString('output_folder_${tool.name}');

      final result = await _channel.invokeMapMethod<String, dynamic>(
        'saveToCollection',
        <String, String?>{
          'sourcePath': sourcePath,
          'collection': tool.collection.wireName,
          'relativeDir': relativeDir,
          'displayName': bareFileName,
          'customFolderUri': customFolderUri,
        },
      );

      if (result == null) {
        throw const OutputSaveException(
          'io_error',
          'Platform channel returned no result',
        );
      }

      return SavedOutput(
        uri: result['uri'] as String,
        displayName: result['displayName'] as String,
        relativeDir: result['relativeDir'] as String,
        isPublic: true,
      );
    } on PlatformException catch (e) {
      throw OutputSaveException(e.code, e.message ?? 'Platform write failed');
    } on MissingPluginException {
      // Channel unavailable (e.g. a stale engine after hot restart) — do not lose the
      // output; fall back to app-private storage and report it as non-public.
      return _publishToAppPrivate(
        tool: tool,
        sourcePath: sourcePath,
        bareFileName: bareFileName,
        subDir: subDir,
      );
    }
  }

  /// Launch folder picker and take permissions, returning the URI or null.
  Future<String?> pickFolder() async {
    if (!Platform.isAndroid) return null;
    try {
      final result = await _channel.invokeMethod<String>('pickFolder');
      return result;
    } catch (e) {
      debugPrint('Failed to pick folder: $e');
      return null;
    }
  }

  /// Appends [subDir] to the tool's folder, tolerating stray slashes.
  String _resolveRelativeDir(ConvertixTool tool, String? subDir) {
    final base = tool.relativeDir;
    final segment = (subDir ?? '').replaceAll(RegExp(r'^/+|/+$'), '');
    return segment.isEmpty ? base : '$base/$segment';
  }

  /// Best-effort removal of already-published outputs, used to roll back a multi-file
  /// publish that failed part-way through (Split PDF).
  ///
  /// Individual failures are swallowed: a rollback must never mask the original error
  /// that triggered it. Returns the number of entries actually removed.
  Future<int> discard(List<String> uris) async {
    if (uris.isEmpty) return 0;
    if (!Platform.isAndroid) {
      var removed = 0;
      for (final uri in uris) {
        try {
          final file = File.fromUri(Uri.parse(uri));
          if (await file.exists()) {
            await file.delete();
            removed++;
          }
        } catch (_) {
          // Best effort only.
        }
      }
      return removed;
    }

    try {
      final removed = await _channel.invokeMethod<int>(
        'deleteOutputs',
        <String, List<String>>{'uris': uris},
      );
      return removed ?? 0;
    } on PlatformException {
      return 0;
    } on MissingPluginException {
      return 0;
    }
  }

  Future<bool> renameOutput(String uri, String newName) async {
    try {
      final success = await _channel.invokeMethod<bool>('renameOutput', {
        'uri': uri,
        'newName': newName,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('Failed to rename output: $e');
      return false;
    }
  }

  /// Share a file using its MediaStore URI via the native Android share sheet.
  Future<bool> shareOutput(String uri) async {
    try {
      final success = await _channel.invokeMethod<bool>('shareOutput', {
        'uri': uri,
      });
      return success ?? false;
    } catch (e) {
      debugPrint('Failed to share output: $e');
      return false;
    }
  }

  Future<bool> deleteOutput(String uri) async {
    final removed = await discard([uri]);
    return removed > 0;
  }


  /// Opens the public folder where the output was saved using native file explorer.
  Future<void> showInFolder(String relativeDir) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>(
        'showInFolder',
        {'relativeDir': relativeDir},
      );
    } on PlatformException catch (e) {
      throw OutputSaveException(e.code, e.message ?? 'Platform channel failed');
    }
  }

  /// Fallback used on non-Android platforms, where there is no MediaStore.
  /// iOS gets its own implementation in Phase 3.
  Future<SavedOutput> _publishToAppPrivate({
    required ConvertixTool tool,
    required String sourcePath,
    required String bareFileName,
    String? subDir,
  }) async {
    final outputRoot = await fileService.getOutputDir();
    final segment = (subDir ?? '').replaceAll(RegExp(r'^/+|/+$'), '');

    var outputDir = outputRoot;
    if (segment.isNotEmpty) {
      outputDir = path.join(outputRoot, segment);
      await Directory(outputDir).create(recursive: true);
    }

    final target = await _uniqueLocalFile(outputDir, bareFileName);
    await File(sourcePath).copy(target.path);

    return SavedOutput(
      uri: target.uri.toString(),
      displayName: path.basename(target.path),
      relativeDir: outputDir,
      isPublic: false,
    );
  }

  Future<File> _uniqueLocalFile(String dir, String bareFileName) async {
    final stem = path.basenameWithoutExtension(bareFileName);
    final ext = path.extension(bareFileName);

    var candidate = File(path.join(dir, bareFileName));
    var counter = 1;
    while (await candidate.exists()) {
      candidate = File(path.join(dir, '$stem ($counter)$ext'));
      counter++;
    }
    return candidate;
  }
}

final outputLocationService = OutputLocationService();
