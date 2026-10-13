import 'dart:io';
import 'package:flutter/services.dart';

class FilePickerService {
  static const _channel = MethodChannel('com.allformat.convertix/file_picker');

  /// Launches the native Android file picker for [toolName].
  /// Returns picked files as a list of maps with 'path' and 'name',
  /// or null if the user cancelled.
  static Future<List<Map<String, String>>?> pickFiles({
    required String toolName,
    required String mimeType,
    bool allowMultiple = false,
  }) async {
    try {
      final result = await _channel.invokeMethod<List<dynamic>>('launchPicker', {
        'toolName': toolName,
        'mimeType': mimeType,
        'allowMultiple': allowMultiple,
      });
      if (result == null) return null;
      return result
          .cast<Map<dynamic, dynamic>>()
          .map(
            (e) => {
              'path': (e['path'] ?? '') as String,
              'name': (e['name'] ?? '') as String,
            },
          )
          .toList();
    } on PlatformException catch (e) {
      throw Exception('File pick failed: ${e.message}');
    }
  }

  /// Returns a map of toolName -> remembered app label (e.g. 'image_converter' -> 'Files by Google')
  static Future<Map<String, String>> getPreferences() async {
    if (!Platform.isAndroid) return {};
    try {
      final result = await _channel.invokeMapMethod<String, String>('getPreferences');
      return result ?? {};
    } on PlatformException {
      return {};
    }
  }

  /// Clears the remembered source app preference for [toolName].
  static Future<void> resetPreference(String toolName) async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('resetPreference', {
        'toolName': toolName,
      });
    } on PlatformException {
      // Ignore
    }
  }

  /// Clears all remembered source app preferences.
  static Future<void> resetAllPreferences() async {
    if (!Platform.isAndroid) return;
    try {
      await _channel.invokeMethod<void>('resetAllPreferences');
    } on PlatformException {
      // Ignore
    }
  }
}
