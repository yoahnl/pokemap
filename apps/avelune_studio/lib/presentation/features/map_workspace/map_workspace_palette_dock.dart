import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_family_tree.dart';
import '../resources/resource_filter_button.dart';
import '../resources/resource_preview.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_panels.dart';
import 'map_workspace_palette_dock_header.dart';
import 'map_workspace_palette_dock_filters.dart';

class MapWorkspacePaletteDock extends StatefulWidget {
  const MapWorkspacePaletteDock({
    super.key,
    required this.project,
    required this.document,
    required this.visuals,
    required this.view,
    required this.search,
    required this.onChanged,
    required this.onResources,
    required this.onOpenFullPalette,
    this.maxHeight = 330,
    this.compact = false,
    this.onPickResource,
  });

  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final TextEditingController search;
  final VoidCallback onChanged;
  final VoidCallback onResources;
  final VoidCallback onOpenFullPalette;
  final double maxHeight;
  final bool compact;
  final ValueChanged<ResourceItem>? onPickResource;

  @override
  State<MapWorkspacePaletteDock> createState() =>
      _MapWorkspacePaletteDockState();
}

class _MapWorkspacePaletteDockState extends State<MapWorkspacePaletteDock> {
  double? _height;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final kind = widget.view.paletteTab;
    final map = widget.document.current;
    widget.view.reconcileResources(widget.project, mapId: map.id, map: map);
    widget.view.resourceFilters.query = kind == 'Personnages'
        ? ''
        : widget.search.text;
    final items = widget.view.paletteResources(
      widget.project,
      map.id,
      applyFilters: false,
    );
    final tree = ResourceFamilyTree(
      widget.project,
      items,
      activeMapId: map.id,
      forMapPicker: true,
      filters: kind == 'Personnages'
          ? (widget.view.resourceFilters.copy()
              ..query = widget.view.characterQuery)
          : widget.view.resourceFilters,
    );
    final visible = widget.view.paletteResources(widget.project, map.id);
    final preferredHeight = _height ?? (widget.compact ? 184.0 : 270.0);
    final detailed = !{'Décors', 'Terrains'}.contains(kind);
    return Container(
      height: _collapsed
          ? 72
          : preferredHeight.clamp(160, widget.maxHeight.clamp(160, 330)),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border(
          top: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
        ),
      ),
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MapWorkspacePaletteDockHeader(
            kind: kind,
            compact: widget.compact,
            spatial: map.spatialScene != null,
            collapsed: _collapsed,
            onKindChanged: (value) {
              widget.view.paletteTab = value;
              widget.view.paletteTiles = value == 'Tuiles';
              setState(() => _collapsed = false);
              widget.onChanged();
              if (value == 'Tuiles') widget.onOpenFullPalette();
            },
            onToggle: () => setState(() => _collapsed = !_collapsed),
            onResize: (delta) => setState(() {
              _collapsed = false;
              _height = (preferredHeight - delta).clamp(160, 330);
            }),
            onOpenFullPalette: widget.onResources,
          ),
          if (!_collapsed) const SizedBox(height: 6),
          if (!_collapsed && kind != 'Passages')
            MapWorkspacePaletteDockFilters(
              tree: tree,
              filters: widget.view.resourceFilters,
              search: widget.search,
              activeMapName: map.name,
              showSearch: kind != 'Personnages',
              countResults: (draft, _) => filterResourceCatalog(
                widget.project,
                items,
                kind == 'Personnages'
                    ? (draft.copy()..query = widget.view.characterQuery)
                    : draft,
                activeMapId: map.id,
                forMapPicker: true,
              ).length,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
          if (!_collapsed && kind != 'Passages')
            ResourceFilterTags(
              filters: widget.view.resourceFilters,
              activeMapName: map.name,
              forMapPicker: true,
              familyLabel: tree.nodes
                  .where(
                    (node) => node.id == widget.view.resourceFilters.familyId,
                  )
                  .firstOrNull
                  ?.name,
              onChanged: () {
                setState(() {});
                widget.onChanged();
              },
            ),
          if (!_collapsed && detailed && kind != 'Tuiles')
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: MapWorkspacePalette(
                      compactContent: true,
                      width: 500,
                      project: widget.project,
                      document: widget.document,
                      visuals: widget.visuals,
                      view: widget.view,
                      search: widget.search,
                      onChanged: widget.onChanged,
                      onResources: widget.onResources,
                      onPickResource: widget.onPickResource,
                    ),
                  ),
                  if (kind == 'Personnages' && widget.view.character == null)
                    const Text('Choisissez un personnage à placer.'),
                  if (kind == 'Passages' && widget.view.warpDestination == null)
                    Text(
                      widget.view.tool == StudioMapTool.connection
                          ? 'Choisissez le bord et la carte voisine dans le panneau de droite.'
                          : widget.view.warpPlacementMode ==
                                MapWarpTriggerMode.sceneOnly
                          ? 'Cliquez sur la carte pour poser le point d’arrivée.'
                          : 'Choisissez la carte vers laquelle mène le passage.',
                    ),
                ],
              ),
            )
          else if (!_collapsed && kind == 'Tuiles')
            Expanded(
              child: Center(
                child: StudioButton(
                  label: 'Choisir une tuile dans son atlas',
                  onPressed: widget.onOpenFullPalette,
                ),
              ),
            )
          else if (!_collapsed)
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    child: visible.isEmpty
                        ? Center(
                            child: Text(
                              'Aucune ressource ne correspond aux filtres.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          )
                        : LayoutBuilder(
                            builder: (context, constraints) {
                              final rows = (constraints.maxHeight / 78)
                                  .floor()
                                  .clamp(1, 2);
                              return GridView.builder(
                                key: ValueKey(
                                  'dock-$kind-${widget.view.resourceFilters.familyId}-$rows',
                                ),
                                scrollDirection: Axis.horizontal,
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: rows,
                                      mainAxisExtent: widget.compact ? 92 : 108,
                                      crossAxisSpacing: 8,
                                      mainAxisSpacing: 8,
                                    ),
                                itemCount: visible.length,
                                itemBuilder: (context, index) {
                                  final item = visible[index];
                                  return StudioPaletteCard(
                                    key: ValueKey(
                                      item.kind == ResourceKind.decors
                                          ? 'decor-${item.id}'
                                          : 'terrain-${item.id}',
                                    ),
                                    name: item.name,
                                    showName: !widget.compact,
                                    maxNameLines: 1,
                                    preview: item.element != null
                                        ? widget.visuals.thumbnail(
                                            item.element!,
                                            size: widget.compact ? 48 : 64,
                                          )
                                        : resourcePreview(
                                            item,
                                            widget.project,
                                            widget.visuals,
                                            size: widget.compact ? 48 : 64,
                                          ),
                                    selected: item.model3d != null
                                        ? widget.view.model3d?.id == item.id
                                        : item.element != null
                                        ? widget.view.brush?.id == item.id
                                        : widget.view.terrain?.id == item.id,
                                    onTap: () {
                                      if (widget.onPickResource != null) {
                                        widget.onPickResource!(item);
                                        return;
                                      }
                                      final view = widget.view;
                                      if (item.terrain != null) {
                                        view.prepareTerrainPainting(
                                          item.terrain!,
                                        );
                                        widget.onChanged();
                                        return;
                                      }
                                      view.brush = item.element;
                                      view.model3d = item.model3d;
                                      view.terrain = item.terrain;
                                      view.tile = null;
                                      view.character = null;
                                      view.tool =
                                          item.kind == ResourceKind.decors
                                          ? StudioMapTool.place
                                          : StudioMapTool.terrain;
                                      widget.onChanged();
                                    },
                                  );
                                },
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
