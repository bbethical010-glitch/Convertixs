import 'package:flutter/services.dart';

class MediaInfoService {
  static const MethodChannel _channel = MethodChannel('com.allformat.convertix/media');

  Future<int> getMediaDurationMs(String path) async {
    try {
      final result = await _channel.invokeMethod<int>('getMediaDuration', {'path': path});
      return result ?? 0;
    } catch (e) {
      return 0;
    }
  }
}

final mediaInfoService = MediaInfoService();
