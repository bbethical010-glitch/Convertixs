import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'shell.dart';
import '../features/home/home_screen.dart';
import '../features/history/history_screen.dart';
import '../features/image_converter/image_converter_screen.dart';
import '../features/video_to_audio/video_to_audio_screen.dart';
import '../features/audio_converter/audio_converter_screen.dart';
import '../features/video_converter/video_converter_screen.dart';
import '../features/video_compression/video_compression_screen.dart';
import '../features/image_to_pdf/image_to_pdf_screen.dart';
import '../features/document_convert/document_convert_screen.dart';
import '../features/greyscale_pdf/greyscale_pdf_screen.dart';
import '../features/merge_pdf/merge_pdf_screen.dart';
import '../features/split_pdf/split_pdf_screen.dart';
import '../features/settings/licenses_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/tool_settings_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/store/store_screen.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter buildAppRouter(bool hasSeenOnboarding) {
  return GoRouter(
    initialLocation: hasSeenOnboarding ? '/' : '/onboarding',
    navigatorKey: _rootNavigatorKey,
    routes: [
      GoRoute(
        path: '/onboarding',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const PermissionsOnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return AppShell(navigationShell: navigationShell);
      },
      branches: [
        // Tab 1: Home
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        // Tab 2: History
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/history',
              name: 'history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ],
        ),
        // Tab 3: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
    // Tool screens (pushed outside the shell, covering the bottom bar)
    GoRoute(
      path: '/image-converter',
      name: 'image-converter',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ImageConverterScreen(),
    ),
    GoRoute(
      path: '/video-to-audio',
      name: 'video-to-audio',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VideoToAudioScreen(),
    ),
    GoRoute(
      path: '/audio-converter',
      name: 'audio-converter',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const AudioConverterScreen(),
    ),
    GoRoute(
      path: '/video-converter',
      name: 'video-converter',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VideoConverterScreen(),
    ),
    GoRoute(
      path: '/video-compression',
      name: 'video-compression',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const VideoCompressionScreen(),
    ),
    GoRoute(
      path: '/image-to-pdf',
      name: 'image-to-pdf',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ImageToPdfScreen(),
    ),
    GoRoute(
      path: '/document-convert',
      name: 'document-convert',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const DocumentConvertScreen(),
    ),
    GoRoute(
      path: '/greyscale-pdf',
      name: 'greyscale-pdf',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const GreyscalePdfScreen(),
    ),
    GoRoute(
      path: '/merge-pdf',
      name: 'merge-pdf',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MergePdfScreen(),
    ),
    GoRoute(
      path: '/split-pdf',
      name: 'split-pdf',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const SplitPdfScreen(),
    ),
    GoRoute(
      path: '/licenses',
      name: 'licenses',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const LicensesScreen(),
    ),
    GoRoute(
      path: '/tool-settings',
      name: 'tool-settings',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const ToolSettingsScreen(),
    ),
    GoRoute(
      path: '/store',
      name: 'store',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const StoreScreen(),
    ),
  ],
  );
}
