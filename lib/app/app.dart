import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'router.dart';
import '../new_ui/theme/brutalist_theme.dart';
import '../core/providers/theme_provider.dart';

class ConvertixApp extends ConsumerWidget {
  final bool hasSeenOnboarding;

  const ConvertixApp({super.key, required this.hasSeenOnboarding});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    
    return MaterialApp.router(
      title: 'Convertix',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: BrutalTheme.themeData,
      darkTheme: BrutalTheme.themeData,
      routerConfig: buildAppRouter(hasSeenOnboarding),
    );
  }
}

