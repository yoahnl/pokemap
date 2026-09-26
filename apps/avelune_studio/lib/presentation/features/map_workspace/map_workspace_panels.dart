import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_sidebar.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../characters/character_palette.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_preview.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import 'map_palette_grid.dart';
import '../../shared/widgets/inputs/studio_palette_tabs.dart';
import 'map_tile_palette.dart';
import 'map_warp_palette.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';

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
  final double width;
  final bool compactContent;
  @override
  State<MapWorkspacePalette> createState() => _MapWorkspacePaletteState();
}

class _MapWorkspacePaletteState extends State<MapWorkspacePalette> {
  String get kind => widget.view.paletteTab;
  ProjectManifest? _project;
  MapData? _map;
  String? _query;
  List<ProjectElementEntry> elements = [];
  List<ProjectSmartTilePreset> terrains = [];
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
    final query = widget.search.text.toLowerCase();
    if (identical(project, _project) &&
        identical(map, _map) &&
        query == _query) {
      return;
    }
    bool matches(String name) => name.toLowerCase().contains(query);
    elements = project.elements
        .where((e) => matches('${e.name} ${e.tags.join(' ')}'))
        .toList();
    terrains = project.smartTileCatalog.presets
        .where((e) => matches(e.name))
        .toList();
    sources = project.tilesets.where((e) => matches(e.name)).toList();
    final ids = sources.map((e) => e.id).toSet();
    tiles = map.layers
        .whereType<TileLayer>()
        .expand((l) => l.palette)
        .toSet()
        .where((tile) => ids.contains(tile.tilesetId))
        .toList();
    _project = project;
    _map = map;
    _query = query;
  }

  Widget catalog() {
    final view = widget.view;
    if (kind == 'Personnages') {
      return CharacterPalette(
        project: widget.project,
        visuals: widget.visuals,
        selectedId: view.character?.id,
        query: view.characterQuery,
        scrollOffset: view.characterScrollOffset,
        onScrollChanged: (offset) => view.characterScrollOffset = offset,
        onQueryChanged: (query) => view.characterQuery = query,
        onPick: (character) {
          view.character = character;
          view.brush = null;
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
        onPick: (entry) {
          view.warpDestination = entry;
          view.brush = null;
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
    final count = kind == 'Décors' ? elements.length : terrains.length;
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
              ? const Text('Aucune ressource ne correspond à la recherche.')
              : MapPaletteGrid(
                  key: ValueKey(
                    kind == 'Décors' ? 'decor-palette' : 'terrain-palette',
                  ),
                  offset: view.paletteScrollOffsets[kind] ?? 0,
                  onScroll: (offset) =>
                      view.paletteScrollOffsets[kind] = offset,
                  columns: widget.width >= 300 ? 3 : 2,
                  count: count,
                  itemBuilder: (context, i) {
                    if (kind == 'Décors') {
                      final e = elements[i];
                      return StudioPaletteCard(
                        key: ValueKey('decor-${e.id}'),
                        name: e.name,
                        preview: widget.visuals.thumbnail(e, size: 72),
                        selected:
                            view.tool == StudioMapTool.place &&
                            view.brush?.id == e.id,
                        onTap: () {
                          view.brush = e;
                          view.tile = null;
                          view.terrain = null;
                          view.character = null;
                          view.tool = StudioMapTool.place;
                          widget.onChanged();
                        },
                      );
                    }
                    final t = terrains[i];
                    return StudioPaletteCard(
                      key: ValueKey('terrain-${t.id}'),
                      name: t.name,
                      preview: resourcePreview(
                        ResourceItem(
                          id: t.id,
                          name: t.name,
                          kind: ResourceKind.terrains,
                          terrain: t,
                        ),
                        widget.project,
                        widget.visuals,
                        size: 72,
                      ),
                      selected: view.terrain?.id == t.id,
                      onTap: () {
                        view.terrain = t;
                        view.brush = null;
                        view.tile = null;
                        view.character = null;
                        view.tool = StudioMapTool.terrain;
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
    if (widget.compactContent) return catalog();
    return StudioSidebar(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Palette', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          StudioPaletteTabs(
            items: const [
              'Décors',
              'Terrains',
              'Tuiles',
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
                ? view.warpDestination == null
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
