import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/services/global_task_manager.dart';
import '../theme/brutalist_theme.dart';
import '../widgets/brutalist_bottom_nav.dart';

class NewAppShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const NewAppShell({
    super.key,
    required this.navigationShell,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTasks = ref.watch(globalTaskManagerProvider);

    return Scaffold(
      backgroundColor: BrutalColors.background,
      body: navigationShell,
      bottomNavigationBar: BrutalistBottomNav(
        currentIndex: navigationShell.currentIndex,
        hasActiveHistory: activeTasks.isNotEmpty,
        onTabSelected: (index) {
          navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          );
        },
      ),
    );
  }
}
