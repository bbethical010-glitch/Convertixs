import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/constants/format_constants.dart';
import '../../features/audio_converter/audio_converter_provider.dart';
import '../../features/image_converter/image_converter_provider.dart';
import '../../features/video_converter/video_converter_provider.dart';
import '../../features/video_to_audio/video_to_audio_provider.dart';
import 'new_media_tool_screen.dart';

class NewImageConverterScreen extends ConsumerWidget {
  const NewImageConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(imageConverterProvider);
    final notifier = ref.read(imageConverterProvider.notifier);

    return NewMediaToolScreen(
      title: 'Image Converter',
      toolName: 'image_converter',
      mimeType: 'image/*',
      outputFormats: imageOutputFormats,
      initialFormat: imageOutputFormats.first,
      conversionState: state,
      showQualitySlider: true,
      onConvert: (file, format, quality, bitrate, res, onProgress) =>
          notifier.convert(
        inputFile: file,
        config: ImageConverterConfig(outputFormat: format, quality: quality),
        onProgress: onProgress,
      ),
      onCancel: notifier.cancel,
    );
  }
}

class NewVideoToAudioScreen extends ConsumerWidget {
  const NewVideoToAudioScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoToAudioProvider);
    final notifier = ref.read(videoToAudioProvider.notifier);

    const formats = ['mp3', 'aac', 'wav', 'flac'];

    return NewMediaToolScreen(
      title: 'Video to Audio',
      toolName: 'video_to_audio',
      mimeType: 'video/*',
      outputFormats: formats,
      initialFormat: 'mp3',
      conversionState: state,
      showBitrateDropdown: true,
      onConvert: (file, format, quality, bitrate, res, onProgress) =>
          notifier.convert(
        inputFile: file,
        config: VideoToAudioConfig(outputFormat: format, bitrateKbps: bitrate),
        onProgress: onProgress,
      ),
      onCancel: notifier.cancel,
    );
  }
}

class NewAudioConverterScreen extends ConsumerWidget {
  const NewAudioConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(audioConverterProvider);
    final notifier = ref.read(audioConverterProvider.notifier);

    return NewMediaToolScreen(
      title: 'Audio Converter',
      toolName: 'audio_converter',
      mimeType: 'audio/*',
      outputFormats: audioOutputFormats,
      initialFormat: audioOutputFormats.first,
      conversionState: state,
      showBitrateDropdown: true,
      onConvert: (file, format, quality, bitrate, res, onProgress) =>
          notifier.convert(
        inputFile: file,
        config: AudioConverterConfig(outputFormat: format, bitrateKbps: bitrate),
        onProgress: onProgress,
      ),
      onCancel: notifier.cancel,
    );
  }
}

class NewVideoConverterScreen extends ConsumerWidget {
  const NewVideoConverterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoConverterProvider);
    final notifier = ref.read(videoConverterProvider.notifier);

    return NewMediaToolScreen(
      title: 'Video Converter',
      toolName: 'video_converter',
      mimeType: 'video/*',
      outputFormats: videoOutputFormats,
      initialFormat: videoOutputFormats.first,
      conversionState: state,
      showResolutionGrid: true,
      onConvert: (file, format, quality, bitrate, res, onProgress) =>
          notifier.convert(
        inputFile: file,
        config: VideoConverterConfig(
          outputFormat: format,
          resolution: res,
        ),
        onProgress: onProgress,
      ),
      onCancel: notifier.cancel,
    );
  }
}
