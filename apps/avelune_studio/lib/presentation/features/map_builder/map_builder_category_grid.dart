import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

IconData mapBuilderCategoryIcon(ResourceUsageCategory category) =>
    switch (category) {
      ResourceUsageCategory.vegetation => Icons.park_outlined,
      ResourceUsageCategory.ground => Icons.grass,
      ResourceUsageCategory.path => Icons.route_outlined,
      ResourceUsageCategory.water => Icons.water_drop_outlined,
      ResourceUsageCategory.relief => Icons.terrain_outlined,
      ResourceUsageCategory.building => Icons.home_work_outlined,
      ResourceUsageCategory.structure => Icons.foundation_outlined,
      ResourceUsageCategory.furniture => Icons.chair_outlined,
      ResourceUsageCategory.object => Icons.category_outlined,
    };

class MapBuilderCategoryGrid extends StatelessWidget {
  const MapBuilderCategoryGrid({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final ResourceUsageCategory selected;
  final ValueChanged<ResourceUsageCategory> onSelected;

  static const columns = 3;

  @override
  Widget build(BuildContext context) {
    const categories = ResourceUsageCategory.values;
    return Column(
      children: [
        for (var start = 0; start < categories.length; start += columns)
          Padding(
            padding: EdgeInsets.only(
              top: start == 0 ? 0 : StudioSpacing.xs,
            ),
            child: Row(
              children: [
                for (var index = start; index < start + columns; index++) ...[
                  if (index > start) const SizedBox(width: StudioSpacing.xs),
                  Expanded(
                    child: index < categories.length
                        ? _CategoryTile(
                            category: categories[index],
                            selected: categories[index] == selected,
                            onTap: () => onSelected(categories[index]),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.category,
    required this.selected,
    required this.onTap,
  });

  final ResourceUsageCategory category;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final foreground = selected ? scheme.primary : scheme.onSurfaceVariant;
    final label = context.l10n.resourceCategory(category);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          key: ValueKey('map-resource-category-${category.name}'),
          borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
          onTap: onTap,
          child: Ink(
            height: 64,
            decoration: BoxDecoration(
              color: selected
                  ? scheme.primaryContainer
                  : scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  mapBuilderCategoryIcon(category),
                  size: 20,
                  color: foreground,
                ),
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: StudioSpacing.xs,
                  ),
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: selected ? scheme.onPrimaryContainer : null,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
