import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import '../new_ui/shell/new_app_shell.dart';
import '../new_ui/screens/new_home_screen.dart';
import '../new_ui/screens/new_history_screen.dart';
import '../new_ui/screens/new_settings_screen.dart';
import '../new_ui/screens/new_video_compression_screen.dart';
import '../new_ui/screens/new_media_tool_screens.dart';
import '../new_ui/screens/new_document_screens.dart';
import '../new_ui/screens/new_store_screen.dart';
import '../features/settings/licenses_screen.dart';
import '../features/settings/tool_settings_screen.dart';
import '../features/onboarding/onboarding_screen.dart';

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
          return NewAppShell(navigationShell: navigationShell);
        },
        branches: [
          // Tab 1: Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: 'home',
                builder: (context, state) => const NewHomeScreen(),
              ),
            ],
          ),
          // Tab 2: History
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                name: 'history',
                builder: (context, state) => const NewHistoryScreen(),
              ),
            ],
          ),
          // Tab 3: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const NewSettingsScreen(),
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
        builder: (context, state) => const NewImageConverterScreen(),
      ),
      GoRoute(
        path: '/video-to-audio',
        name: 'video-to-audio',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewVideoToAudioScreen(),
      ),
      GoRoute(
        path: '/audio-converter',
        name: 'audio-converter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewAudioConverterScreen(),
      ),
      GoRoute(
        path: '/video-converter',
        name: 'video-converter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewVideoConverterScreen(),
      ),
      GoRoute(
        path: '/video-compression',
        name: 'video-compression',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewVideoCompressionScreen(),
      ),
      GoRoute(
        path: '/image-to-pdf',
        name: 'image-to-pdf',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewImageToPdfScreen(),
      ),
      GoRoute(
        path: '/document-convert',
        name: 'document-convert',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewDocumentConvertScreen(),
      ),
      GoRoute(
        path: '/greyscale-pdf',
        name: 'greyscale-pdf',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewGreyscalePdfScreen(),
      ),
      GoRoute(
        path: '/merge-pdf',
        name: 'merge-pdf',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewMergePdfScreen(),
      ),
      GoRoute(
        path: '/split-pdf',
        name: 'split-pdf',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const NewSplitPdfScreen(),
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
        builder: (context, state) => const NewStoreScreen(),
      ),
    ],
  );
}

