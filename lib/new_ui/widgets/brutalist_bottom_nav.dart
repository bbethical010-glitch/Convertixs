import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/brutalist_theme.dart';

class BrutalistBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool hasActiveHistory;

  const BrutalistBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.hasActiveHistory = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: Border(
          top: BorderSide(color: BrutalColors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: BrutalColors.black,
            offset: Offset(0, -2),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                icon: LucideIcons.layoutGrid,
              ),
              _buildNavItem(
                index: 1,
                label: 'History',
                icon: LucideIcons.history,
                badge: hasActiveHistory,
              ),
              _buildNavItem(
                index: 2,
                label: 'Settings',
                icon: LucideIcons.slidersHorizontal,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    bool badge = false,
  }) {
    final isSelected = index == currentIndex;

    return GestureDetector(
      onTap: () => onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: isSelected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: const BoxDecoration(
                color: BrutalColors.black,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadowSm,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 20, color: BrutalColors.white),
                  const SizedBox(height: 2),
                  Text(
                    label.toUpperCase(),
                    style: BrutalTheme.label(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: BrutalColors.white,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(icon, size: 20, color: BrutalColors.textMuted),
                      if (badge)
                        Positioned(
                          right: -3,
                          top: -3,
                          child: Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: BrutalColors.black,
                              shape: BoxShape.rectangle,
                              border: Border.fromBorderSide(
                                BorderSide(color: BrutalColors.black, width: 1),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    label.toUpperCase(),
                    style: BrutalTheme.label(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: BrutalColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
