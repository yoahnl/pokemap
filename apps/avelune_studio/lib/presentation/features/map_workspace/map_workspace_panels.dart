import 'package:flutter/material.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:map_core/map_core_domain.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_sidebar.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_visuals.dart';

class MapWorkspacePalette extends StatefulWidget {
  const MapWorkspacePalette({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.onChanged,
    required this.search,
  });
  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final VoidCallback onChanged;
  final TextEditingController search;
  @override
  State<MapWorkspacePalette> createState() => _MapWorkspacePaletteState();
}

class _MapWorkspacePaletteState extends State<MapWorkspacePalette> {
  ProjectManifest? _project;
  MapData? _map;
  String? _query;
  Map<String, String> _names = {};
  List<ProjectElementEntry> _elements = [];
  List<TileLayerPaletteEntry> _availableTiles = [];
  List<TileLayerPaletteEntry> _tiles = [];
  @override
  void initState() {
    super.initState();
    _refreshLists();
  }

  @override
  void didUpdateWidget(MapWorkspacePalette oldWidget) {
    super.didUpdateWidget(oldWidget);
    _refreshLists();
  }

  void _refreshLists() {
    final projectChanged = !identical(_project, widget.project);
    final mapChanged = !identical(_map, widget.document.current);
    final query = widget.search.text.toLowerCase();
    final queryChanged = query != _query;
    if (projectChanged) {
      _names = {
        for (final entry in widget.project.tilesets) entry.id: entry.name,
      };
    }
    if (projectChanged || queryChanged) {
      _elements = widget.project.elements
          .where((entry) => entry.name.toLowerCase().contains(query))
          .toList();
    }
    if (mapChanged) {
      _availableTiles = widget.document.current.layers
          .whereType<TileLayer>()
          .expand((layer) => layer.palette)
          .toSet()
          .toList();
    }
    if (projectChanged || mapChanged || queryChanged) {
      _tiles = _availableTiles
          .where(
            (tile) =>
                (_names[tile.tilesetId] ?? '').toLowerCase().contains(query),
          )
          .toList();
    }
    _project = widget.project;
    _map = widget.document.current;
    _query = query;
  }

  @override
  Widget build(BuildContext context) {
    final showTiles = widget.view.paletteTiles;
    return StudioSidebar(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Palette', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: widget.search,
            decoration: InputDecoration(
              labelText: 'Rechercher un décor',
              hintText: 'Nom de ressource',
              prefixIcon: const Icon(Icons.search, size: 17),
            ),
            onChanged: (_) => setState(_refreshLists),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: StudioButton(
                  label: 'Décors',
                  secondary: showTiles,
                  onPressed: () =>
                      setState(() => widget.view.paletteTiles = false),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: StudioButton(
                  label: 'Tuiles',
                  secondary: !showTiles,
                  onPressed: () =>
                      setState(() => widget.view.paletteTiles = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            showTiles
                ? 'Tuiles de la carte · ${_tiles.length}'
                : '${_elements.length} décors',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 6),
          Expanded(
            child: (showTiles ? _tiles.isEmpty : _elements.isEmpty)
                ? const Center(child: Text('Aucune ressource correspondante.'))
                : ListView.builder(
                    key: ValueKey(showTiles ? 'tile-palette' : 'decor-palette'),
                    scrollCacheExtent: const ScrollCacheExtent.pixels(0),
                    itemCount: showTiles ? _tiles.length : _elements.length,
                    itemBuilder: (context, index) {
                      if (showTiles) {
                        final tile = _tiles[index];
                        return StudioChoice(
                          label:
                              '${_names[tile.tilesetId] ?? 'Ressource'} · tuile ${tile.localTileId + 1}',
                          leading: widget.visuals.tileThumbnail(tile, size: 40),
                          selected:
                              widget.view.tool == StudioMapTool.paint &&
                              widget.view.tile == tile,
                          onTap: () {
                            widget.view.tile = tile;
                            widget.view.brush = null;
                            widget.view.tool = StudioMapTool.paint;
                            widget.onChanged();
                          },
                        );
                      }
                      final element = _elements[index];
                      return StudioChoice(
                        label: element.name,
                        leading: widget.visuals.thumbnail(element, size: 40),
                        selected:
                            widget.view.tool == StudioMapTool.place &&
                            widget.view.brush?.id == element.id,
                        onTap: () {
                          widget.view.brush = element;
                          widget.view.tile = null;
                          widget.view.tool = StudioMapTool.place;
                          widget.onChanged();
                        },
                      );
                    },
                  ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.view.tool == StudioMapTool.paint
                ? 'Tuile ${(widget.view.tile?.localTileId ?? 0) + 1} · support automatique'
                : widget.view.tool == StudioMapTool.place
                ? '${widget.view.brush?.name ?? 'Décor'} · support automatique'
                : 'Clic pour sélectionner · Échap pour terminer',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
