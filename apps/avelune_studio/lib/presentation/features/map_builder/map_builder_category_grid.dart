import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_tile_grid.dart';
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

  @override
  Widget build(BuildContext context) => MapBuilderTileGrid(
    tiles: [
      for (final category in ResourceUsageCategory.values)
        MapBuilderTile(
          value: category,
          icon: mapBuilderCategoryIcon(category),
          label: context.l10n.resourceCategory(category),
          key: ValueKey('map-resource-category-${category.name}'),
        ),
    ],
    selected: selected,
    onSelected: onSelected,
  );
}
