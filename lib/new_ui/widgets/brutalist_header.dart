import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/brutalist_theme.dart';

class BrutalistHeader extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String subtitle;
  final bool showBackButton;
  final bool showUpgrade;
  final bool showProfile;
  final VoidCallback? onBack;

  const BrutalistHeader({
    super.key,
    this.title = 'Convertix',
    this.subtitle = 'File Converter',
    this.showBackButton = false,
    this.showUpgrade = true,
    this.showProfile = false,
    this.onBack,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BrutalColors.white,
        border: Border(
          bottom: BorderSide(color: BrutalColors.black, width: 2),
        ),
        boxShadow: [
          BoxShadow(
            color: BrutalColors.black,
            offset: Offset(0, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              if (showBackButton) ...[
                GestureDetector(
                  onTap: onBack ?? () => Navigator.of(context).maybePop(),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: const Icon(LucideIcons.arrowLeft, size: 20, color: BrutalColors.black),
                  ),
                ),
                const SizedBox(width: 12),
              ] else ...[
                // App Logo Box
                Container(
                  width: 38,
                  height: 38,
                  decoration: const BoxDecoration(
                    color: BrutalColors.black,
                    border: BrutalTheme.brutalBorder,
                    boxShadow: BrutalTheme.brutalShadowSm,
                  ),
                  child: Center(
                    child: Text(
                      'CX',
                      style: BrutalTheme.headline(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: BrutalColors.white,
                        letterSpacing: 0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BrutalTheme.headline(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: BrutalColors.black,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: BrutalTheme.body(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: BrutalColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              if (showUpgrade) ...[
                GestureDetector(
                  onTap: () => context.push('/store'),
                  child: Container(
                    height: 32,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: const BoxDecoration(
                      color: BrutalColors.black,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.crown, size: 13, color: BrutalColors.white),
                        const SizedBox(width: 4),
                        Text(
                          'PRO',
                          style: BrutalTheme.headline(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: BrutalColors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (showProfile) const SizedBox(width: 8),
              ],
              if (showProfile)
                GestureDetector(
                  onTap: () => context.push('/settings'),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: BrutalColors.white,
                      border: BrutalTheme.brutalBorder,
                      boxShadow: BrutalTheme.brutalShadowSm,
                    ),
                    child: const Icon(LucideIcons.user, size: 18, color: BrutalColors.black),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
