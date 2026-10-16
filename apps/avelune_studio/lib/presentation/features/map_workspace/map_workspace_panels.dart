import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../characters/character_palette.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_family_tree.dart';
import '../resources/resource_filter_button.dart';
import '../resources/resource_preview.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import 'map_palette_grid.dart';
import '../../shared/widgets/inputs/studio_palette_tabs.dart';
import 'map_tile_palette.dart';
import 'map_warp_palette.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_palette_dock_filters.dart';

class MapWorkspacePalette extends StatefulWidget {
  const MapWorkspacePalette({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.onChanged,
    required this.search,
    this.onResources,
    this.onTileset,
    this.onPickResource,
    this.width = 240,
    this.compactContent = false,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final TextEditingController search;
  final VoidCallback? onResources;
  final ValueChanged<ProjectTilesetEntry>? onTileset;
  final ValueChanged<ResourceItem>? onPickResource;
  final double width;
  final bool compactContent;
  @override
  State<MapWorkspacePalette> createState() => _MapWorkspacePaletteState();
}

class _MapWorkspacePaletteState extends State<MapWorkspacePalette> {
  String get kind => widget.view.paletteTab;
  List<ResourceItem> items = [];
  List<ProjectTilesetEntry> sources = [];
  List<TileLayerPaletteEntry> tiles = [];

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void didUpdateWidget(MapWorkspacePalette old) {
    super.didUpdateWidget(old);
    _refresh();
  }

  void _refresh() {
    final project = widget.project;
    final map = widget.document.current;
    widget.view.reconcileResources(project, mapId: map.id, map: map);
    widget.view.resourceFilters.query = kind == 'Personnages'
        ? ''
        : widget.search.text;
    items = widget.view.paletteResources(project, map.id);
    sources = items.map((item) => item.tileset).nonNulls.toList();
    final ids = sources.map((e) => e.id).toSet();
    tiles = map.layers
        .whereType<TileLayer>()
        .expand((l) => l.palette)
        .toSet()
        .where((tile) => ids.contains(tile.tilesetId))
        .toList();
  }

  Widget catalog() {
    final view = widget.view;
    if (kind == 'Personnages') {
      return CharacterPalette(
        project: widget.project.copyWith(
          characters: items.map((item) => item.character).nonNulls.toList(),
        ),
        visuals: widget.visuals,
        compact: widget.compactContent,
        selectedId: view.character?.id,
        query: view.characterQuery,
        scrollOffset: view.characterScrollOffset,
        onScrollChanged: (offset) => view.characterScrollOffset = offset,
        onQueryChanged: (query) => view.characterQuery = query,
        onPick: (character) {
          if (widget.onPickResource != null) {
            widget.onPickResource!(
              items.firstWhere((item) => item.id == character.id),
            );
            return;
          }
          view.character = character;
          view.brush = null;
          view.model3d = null;
          view.tile = null;
          view.terrain = null;
          view.tool = StudioMapTool.character;
          widget.onChanged();
        },
      );
    }
    if (kind == 'Passages') {
      return MapWarpPalette(
        destinations: widget.project.maps
            .where((entry) => entry.id != widget.document.current.id)
            .toList(),
        selectedId: view.warpDestination?.id,
        arrivalSelected: view.warpPlacementMode == MapWarpTriggerMode.sceneOnly,
        onPickArrival: () {
          view.warpPlacementMode = MapWarpTriggerMode.sceneOnly;
          view.warpDestination = null;
          view.prepareWarpPlacement();
          widget.onChanged();
        },
        onPick: (entry) {
          view.warpPlacementMode = MapWarpTriggerMode.onEnter;
          view.warpDestination = entry;
          view.brush = null;
          view.model3d = null;
          view.tile = null;
          view.terrain = null;
          view.character = null;
          view.tool = StudioMapTool.warp;
          widget.onChanged();
        },
      );
    }
    if (kind == 'Tuiles') {
      return MapTilePalette(
        sources: sources,
        knownTiles: tiles,
        visuals: widget.visuals,
        view: view,
        onChanged: widget.onChanged,
        onAtlasChanged: () => setState(() {}),
      );
    }
    final count = items.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '$count ${kind.toLowerCase()}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Expanded(
          child: count == 0
              ? const Text('Aucune ressource ne correspond aux filtres.')
              : MapPaletteGrid(
                  key: ValueKey(switch (kind) {
                    'Décors' => 'decor-palette',
                    'Terrains' => 'terrain-palette',
                    _ => '$kind-palette',
                  }),
                  offset: view.paletteScrollOffsets[kind] ?? 0,
                  onScroll: (offset) =>
                      view.paletteScrollOffsets[kind] = offset,
                  columns: widget.width >= 300 ? 3 : 2,
                  count: count,
                  itemBuilder: (context, i) {
                    final e = items[i];
                    return StudioPaletteCard(
                      key: ValueKey(
                        '${switch (e.canonicalKind) {
                          'smartTilePreset' => 'terrain',
                          'borderBlueprint' => 'border',
                          'environmentPreset' => 'environment',
                          _ => 'decor',
                        }}-${e.id}',
                      ),
                      name: e.name,
                      preview: resourcePreview(
                        e,
                        widget.project,
                        widget.visuals,
                        size: 72,
                      ),
                      selected: switch (e.canonicalKind) {
                        'element' => view.brush?.id == e.id,
                        'model3d' => view.model3d?.id == e.id,
                        'smartTilePreset' => view.terrain?.id == e.id,
                        'borderBlueprint' => view.borderBlueprintId == e.id,
                        _ => false,
                      },
                      onTap: () {
                        if (widget.onPickResource != null) {
                          widget.onPickResource!(e);
                          return;
                        }
                        if (e.border != null || e.environment != null) return;
                        if (e.terrain != null) {
                          view.prepareTerrainPainting(e.terrain!);
                          widget.onChanged();
                          return;
                        }
                        view.brush = e.element;
                        view.model3d = e.model3d;
                        view.tile = null;
                        view.terrain = e.terrain;
                        view.character = null;
                        view.tool = e.terrain == null
                            ? StudioMapTool.place
                            : StudioMapTool.terrain;
                        widget.onChanged();
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    _refresh();
    if (widget.compactContent) return catalog();
    final map = widget.document.current;
    final resources = view.paletteResources(
      widget.project,
      map.id,
      applyFilters: false,
    );
    final tree = ResourceFamilyTree(
      widget.project,
      resources,
      activeMapId: map.id,
      forMapPicker: true,
      filters: kind == 'Personnages'
          ? (view.resourceFilters.copy()..query = view.characterQuery)
          : view.resourceFilters,
    );
    void filtersChanged() {
      setState(() {});
    }

    return StudioSidebar(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Palette', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StudioPaletteTabs(
            items: [
              'Décors',
              'Terrains',
              if (map.spatialScene == null) 'Tuiles',
              'Bordures',
              'Environnements',
              'Personnages',
              'Passages',
            ],
            selected: kind,
            onChanged: (value) => setState(() {
              view.paletteTab = value;
              view.paletteTiles = value == 'Tuiles';
            }),
          ),
          const SizedBox(height: 8),
          if (kind != 'Passages') ...[
            MapWorkspacePaletteDockFilters(
              tree: tree,
              filters: view.resourceFilters,
              search: widget.search,
              activeMapName: map.name,
              showSearch: false,
              countResults: (draft, _) => filterResourceCatalog(
                widget.project,
                resources,
                kind == 'Personnages'
                    ? (draft.copy()..query = view.characterQuery)
                    : draft,
                activeMapId: map.id,
                forMapPicker: true,
              ).length,
              onChanged: filtersChanged,
            ),
            ResourceFilterTags(
              filters: view.resourceFilters,
              activeMapName: map.name,
              forMapPicker: true,
              familyLabel: tree.nodes
                  .where((node) => node.id == view.resourceFilters.familyId)
                  .firstOrNull
                  ?.name,
              onChanged: filtersChanged,
            ),
            const SizedBox(height: 8),
          ],
          if (kind != 'Personnages' && kind != 'Passages') ...[
            StudioSearchField(
              controller: widget.search,
              label: kind == 'Décors'
                  ? 'Rechercher un décor'
                  : 'Rechercher dans la palette',
              hint: 'Nom ou tag',
              onChanged: (_) => setState(_refresh),
            ),
            const SizedBox(height: 8),
          ],
          Expanded(child: catalog()),
          const SizedBox(height: 6),
          Text(
            kind == 'Personnages' && view.character == null
                ? 'Choisissez un personnage à placer.'
                : kind == 'Passages'
                ? view.tool == StudioMapTool.connection
                      ? 'Choisissez le bord et la carte voisine dans le panneau de droite.'
                      : view.warpPlacementMode == MapWarpTriggerMode.sceneOnly
                      ? 'Cliquez sur la carte pour poser le point d’arrivée.'
                      : view.warpDestination == null
                      ? 'Choisissez la carte vers laquelle mène le passage.'
                      : 'Passage vers ${view.warpDestination!.name}'
                : view.terrain != null
                ? '${view.terrain!.name} · raccords automatiques'
                : view.character?.name ??
                      view.brush?.name ??
                      'Choisissez une ressource à placer',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          StudioButton(
            label: 'Gérer les ressources',
            secondary: true,
            onPressed: widget.onResources,
          ),
        ],
      ),
    );
  }
}
