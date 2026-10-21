import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../media_tools/media_tool_screen.dart';
import 'video_compression_provider.dart';

class VideoCompressionScreen extends ConsumerWidget {
  const VideoCompressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoCompressionProvider);
    final notifier = ref.read(videoCompressionProvider.notifier);

    return MediaToolScreen(
      title: 'Video Compression',
      inputLabel: 'Select Video',
      
      toolName: 'video_compression',
      outputFormats: const ['mp4'],
      initialOutputFormat: 'mp4',
      conversionState: state,
      showResolution: true,
      showVideoCodec: true,
      showCompressionQuality: true,
      showLogProfile: false,
      onConvert: (inputFile, settings, onProgress) => notifier.convert(
        inputFile: inputFile,
        config: VideoCompressionConfig(
          videoCodec: settings.videoCodec,
          quality: _qualityFromId(settings.compressionQuality),
          resolution: settings.resolution,
          logProfileId: settings.logProfileId,
        ),
        onProgress: onProgress,
      ),
      onCancel: notifier.cancel,
    );
  }

  VideoCompressionQuality _qualityFromId(String id) {
    switch (id) {
      case 'high':
        return VideoCompressionQuality.high;
      case 'small':
        return VideoCompressionQuality.small;
      case 'balanced':
      default:
        return VideoCompressionQuality.balanced;
    }
  }
}
