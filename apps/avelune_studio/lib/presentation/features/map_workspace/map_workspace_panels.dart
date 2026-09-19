import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_sidebar.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import '../characters/character_palette.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';

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
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final TextEditingController search;
  final VoidCallback? onResources;
  final ValueChanged<ProjectTilesetEntry>? onTileset;
  @override
  State<MapWorkspacePalette> createState() => _MapWorkspacePaletteState();
}

class _MapWorkspacePaletteState extends State<MapWorkspacePalette> {
  String get kind => widget.view.paletteTab;
  set kind(String value) => widget.view.paletteTab = value;
  ProjectManifest? _project;
  MapData? _map;
  String? _query;
  List<ProjectElementEntry> elements = [];
  List<ProjectSmartTilePreset> terrains = [];
  List<ProjectTilesetEntry> sources = [];
  List<TileLayerPaletteEntry> tiles = [];
  Map<String, String> names = {};
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
    names = {for (final source in project.tilesets) source.id: source.name};
    _project = project;
    _map = map;
    _query = query;
  }

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    return StudioSidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palette', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (kind != 'Personnages')
            StudioSearchField(
              controller: widget.search,
              label: 'Rechercher un décor',
              hint: 'Nom ou tag',
              onChanged: (_) => setState(_refresh),
            ),
          const SizedBox(height: 8),
          StudioTabs<String>(
            items: const {
              'Décors': 'Décors',
              'Terrains': 'Terrains',
              'Tuiles': 'Tuiles',
              'Personnages': 'Personnages',
            },
            selected: kind,
            onChanged: (value) => setState(() {
              kind = value;
              view.paletteTiles = value == 'Tuiles';
            }),
          ),
          const SizedBox(height: 8),
          if (kind != 'Personnages')
            StudioButton(
              label: 'Gérer les ressources',
              secondary: true,
              onPressed: widget.onResources,
            ),
          const SizedBox(height: 8),
          Expanded(
            child: kind == 'Personnages'
                ? CharacterPalette(
                    project: widget.project,
                    visuals: widget.visuals,
                    selectedId: view.character?.id,
                    query: view.characterQuery,
                    scrollOffset: view.characterScrollOffset,
                    onScrollChanged: (offset) =>
                        view.characterScrollOffset = offset,
                    onQueryChanged: (query) => view.characterQuery = query,
                    onPick: (character) {
                      view.character = character;
                      view.brush = null;
                      view.tile = null;
                      view.terrain = null;
                      view.tool = StudioMapTool.character;
                      widget.onChanged();
                    },
                  )
                : ListView.builder(
                    key: ValueKey(
                      kind == 'Tuiles'
                          ? 'tile-palette'
                          : kind == 'Terrains'
                          ? 'terrain-palette'
                          : 'decor-palette',
                    ),
                    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                    itemCount: kind == 'Décors'
                        ? elements.length
                        : kind == 'Terrains'
                        ? terrains.length
                        : sources.length + tiles.length,
                    itemBuilder: (context, i) {
                      if (kind == 'Décors') {
                        final e = elements[i];
                        return StudioChoice(
                          label: e.name,
                          leading: widget.visuals.thumbnail(e, size: 48),
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
                      if (kind == 'Terrains') {
                        final t = terrains[i];
                        return StudioChoice(
                          label: t.name,
                          leading: const Icon(Icons.terrain_outlined),
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
                      }
                      if (i < sources.length) {
                        final t = sources[i];
                        return StudioChoice(
                          label: t.name,
                          subtitle: 'Choisir une tuile du projet',
                          leading: widget.visuals.tileThumbnail(
                            TileLayerPaletteEntry(
                              tilesetId: t.id,
                              localTileId: 0,
                            ),
                            size: 48,
                          ),
                          onTap: () => widget.onTileset?.call(t),
                        );
                      }
                      final tile = tiles[i - sources.length];
                      final name = names[tile.tilesetId] ?? 'Ressource';
                      return StudioChoice(
                        label: '$name · tuile ${tile.localTileId + 1}',
                        leading: widget.visuals.tileThumbnail(tile, size: 40),
                        selected: view.tile == tile,
                        onTap: () {
                          view.tile = tile;
                          view.brush = null;
                          view.terrain = null;
                          view.character = null;
                          view.tool = StudioMapTool.paint;
                          widget.onChanged();
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            view.terrain != null
                ? '${view.terrain!.name} · raccords automatiques'
                : view.character?.name ??
                      view.brush?.name ??
                      'Clic pour sélectionner · Échap pour terminer',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
