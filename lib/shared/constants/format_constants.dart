const List<String> imageInputFormats = [
  'jpg',
  'jpeg',
  'png',
  'webp',
  'bmp',
  'tiff',
];
const List<String> imageOutputFormats = ['jpg', 'png', 'webp', 'bmp', 'tiff'];

const List<String> videoInputFormats = [
  'mp4',
  'mkv',
  'avi',
  'mov',
  'webm',
  'flv',
  'ts',
  '3gp',
  'm4v',
  'wmv',
];
const List<String> videoOutputFormats = [
  'mp4_h264',
  'mp4_h265',
  'mkv',
  'mov',
  'webm',
  'avi',
  'ts',
  '3gp',
];

const List<String> audioInputFormats = [
  'mp3',
  'aac',
  'm4a',
  'wav',
  'flac',
  'ogg',
  'opus',
  'aiff',
  'wma',
  'amr',
];
const List<String> audioOutputFormats = [
  'mp3',
  'aac',
  'wav',
  'flac',
  'ogg',
  'opus',
  'aiff',
];

const List<String> videoToAudioOutputFormats = [
  'mp3',
  'aac',
  'wav',
  'flac',
  'ogg',
];

const List<String> documentOutputFormats = [
  'pdf',
  'docx',
  'xlsx',
  'pptx',
  'odt',
  'ods',
  'odp',
  'rtf',
  'txt',
  'csv',
];

const List<int> audioBitrateOptions = [64, 128, 192, 320];
const int defaultAudioBitrate = 192;

const List<String> videoResolutionOptions = [
  'original',
  '2160p',
  '1440p',
  '1080p',
  '720p',
  '480p',
];

const Map<String, List<String>> toolAllowedExtensions = {
  'image_converter': ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff'],
  'video_to_audio': [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'flv',
    'ts',
    '3gp',
    'm4v',
  ],
  'audio_converter': [
    'mp3',
    'aac',
    'm4a',
    'wav',
    'flac',
    'ogg',
    'opus',
    'aiff',
    'wma',
    'amr',
  ],
  'video_converter': [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'flv',
    'ts',
    '3gp',
    'm4v',
    'wmv',
  ],
  'video_compression': [
    'mp4',
    'mkv',
    'avi',
    'mov',
    'webm',
    'flv',
    'ts',
    '3gp',
    'm4v',
    'wmv',
  ],
  'image_to_pdf': ['jpg', 'jpeg', 'png', 'webp', 'bmp', 'tiff'],
  'document_convert': [
    'docx',
    'xlsx',
    'pptx',
    'odt',
    'ods',
    'odp',
    'rtf',
    'txt',
    'csv',
  ],
  'greyscale_pdf': ['pdf'],
  'merge_pdf': ['pdf'],
  'split_pdf': ['pdf'],
};

const Map<String, String> toolMimeTypes = {
  'image_converter': 'image/*',
  'video_to_audio': 'video/*',
  'audio_converter': 'audio/*',
  'video_converter': 'video/*',
  'video_compression': 'video/*',
  'image_to_pdf': 'image/*',
  'document_convert': '*/*',
  'greyscale_pdf': 'application/pdf',
  'merge_pdf': 'application/pdf',
  'split_pdf': 'application/pdf',
};

bool isFileCompatible(String fileName, String toolName) {
  final ext = fileName.split('.').last.toLowerCase();
  return toolAllowedExtensions[toolName]?.contains(ext) ?? false;
}
