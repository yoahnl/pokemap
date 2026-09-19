import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_resource_card.dart';
import '../../shared/widgets/layout/studio_resource_grid.dart';
import '../../shared/widgets/feedback/studio_empty_state.dart';
import 'resource_catalog.dart';
import 'resource_preview.dart';

class ResourceCatalogView extends StatelessWidget {
  const ResourceCatalogView({
    super.key,
    required this.items,
    required this.selected,
    required this.project,
    required this.visuals,
    required this.scroll,
    required this.grid,
    required this.onSelect,
    required this.catalogEmpty,
  });
  final List<ResourceItem> items;
  final ResourceItem? selected;
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final ScrollController scroll;
  final bool grid, catalogEmpty;
  final ValueChanged<ResourceItem> onSelect;

  String metadata(ResourceItem item) {
    final categories = {
      for (final c in project.elementCategories) c.id: c.name,
    };
    return switch (item.kind) {
      ResourceKind.decors => categories[item.category] ?? 'Décor',
      ResourceKind.terrains => '${item.terrain!.rules.length} raccords',
      ResourceKind.images =>
        item.tileset!.source is ProjectRegularAtlasTilesetSource
            ? '${(item.tileset!.source as ProjectRegularAtlasTilesetSource).pixelWidth} × ${(item.tileset!.source as ProjectRegularAtlasTilesetSource).pixelHeight} px'
            : 'Image et tuiles',
    };
  }

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return StudioEmptyState(
        title: catalogEmpty
            ? 'Cette famille ne contient aucune ressource.'
            : 'Aucune ressource correspondante.',
        description: catalogEmpty
            ? 'Importez une image pour préparer vos ressources.'
            : 'Changez la recherche ou les catégories.',
      );
    }
    if (grid) {
      return LayoutBuilder(
        builder: (context, bounds) => StudioResourceGrid(
          controller: scroll,
          itemCount: items.length,
          mainAxisExtent:
              (258 + (MediaQuery.textScalerOf(context).scale(14) - 14) * 5)
                  .clamp(
                    180,
                    bounds.maxHeight < 320
                        ? (bounds.maxHeight - 24).clamp(180, 320)
                        : 400,
                  ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Tooltip(
              key: ValueKey('resource-card-${item.identity}'),
              message: item.name,
              child: StudioResourceCard(
                name: item.name,
                maxNameLines: 2,
                preview: resourcePreview(
                  item,
                  project,
                  visuals,
                  size: 190,
                  terrainPattern: true,
                ),
                metadata: metadata(item),
                selected: selected?.identity == item.identity,
                onTap: () => onSelect(item),
              ),
            );
          },
        ),
      );
    }
    return ListView.builder(
      controller: scroll,
      scrollCacheExtent: const ScrollCacheExtent.pixels(0),
      itemCount: items.length,
      padding: const EdgeInsets.all(12),
      itemBuilder: (context, index) {
        final item = items[index];
        return Padding(
          key: ValueKey('resource-card-${item.identity}'),
          padding: const EdgeInsets.only(bottom: 6),
          child: StudioChoice(
            label: item.name,
            subtitle: metadata(item),
            leading: resourcePreview(
              item,
              project,
              visuals,
              size: 60,
              terrainPattern: true,
            ),
            selected: selected?.identity == item.identity,
            onTap: () => onSelect(item),
          ),
        );
      },
    );
  }
}
