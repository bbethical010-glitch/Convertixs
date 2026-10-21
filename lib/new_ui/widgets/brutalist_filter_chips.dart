import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../theme/brutalist_theme.dart';

class FilterCategory {
  final String id;
  final String label;
  final IconData icon;

  const FilterCategory({
    required this.id,
    required this.label,
    required this.icon,
  });
}

class BrutalistFilterChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onSelected;

  const BrutalistFilterChips({
    super.key,
    required this.selectedCategory,
    required this.onSelected,
  });

  static const List<FilterCategory> categories = [
    FilterCategory(id: 'all', label: 'All', icon: LucideIcons.layoutGrid),
    FilterCategory(id: 'video', label: 'Video', icon: LucideIcons.video),
    FilterCategory(id: 'audio', label: 'Audio', icon: LucideIcons.audioLines),
    FilterCategory(id: 'image', label: 'Photos', icon: LucideIcons.image),
    FilterCategory(id: 'document', label: 'PDF & Docs', icon: LucideIcons.fileText),
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedCategory;

          return GestureDetector(
            onTap: () => onSelected(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? BrutalColors.black : BrutalColors.white,
                border: BrutalTheme.brutalBorder,
                boxShadow: BrutalTheme.brutalShadowSm,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    cat.icon,
                    size: 15,
                    color: isSelected ? BrutalColors.white : BrutalColors.black,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    cat.label,
                    style: BrutalTheme.headline(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? BrutalColors.white : BrutalColors.black,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
