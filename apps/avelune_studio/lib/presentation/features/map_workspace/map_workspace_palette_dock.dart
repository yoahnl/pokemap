import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/layout/studio_palette_card.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_category_filter.dart';
import '../resources/resource_category_tree.dart';
import '../resources/resource_preview.dart';
import '../../../features/map_workspace/application/editable_map_document.dart';
import 'map_workspace_view_state.dart';
import 'map_workspace_visuals.dart';
import 'map_workspace_panels.dart';
import 'map_workspace_palette_dock_header.dart';

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
  });

  final ProjectManifest project;
  final EditableMapDocument document;
  final MapWorkspaceVisuals visuals;
  final MapWorkspaceViewState view;
  final TextEditingController search;
  final VoidCallback onChanged;
  final VoidCallback onResources;
  final VoidCallback onOpenFullPalette;

  @override
  State<MapWorkspacePaletteDock> createState() =>
      _MapWorkspacePaletteDockState();
}

class _MapWorkspacePaletteDockState extends State<MapWorkspacePaletteDock> {
  double _height = 218;
  bool _collapsed = false;

  @override
  Widget build(BuildContext context) {
    final kind = widget.view.paletteTab;
    final resourceKind = kind == 'Terrains'
        ? ResourceKind.terrains
        : ResourceKind.decors;
    final items = resourceCatalog(widget.project);
    final tree = ResourceCategoryTree(widget.project, resourceKind, items);
    final selectedCategory = resourceKind == ResourceKind.decors
        ? widget.view.decorCategoryId
        : widget.view.terrainCategoryId;
    final allowed = tree.idsFor(selectedCategory);
    final query = widget.search.text.trim().toLowerCase();
    final visible = items.where((item) {
      if (item.kind != resourceKind) return false;
      if (selectedCategory == uncategorizedResourceCategory) {
        if (item.category.isNotEmpty) return false;
      } else if (selectedCategory.isNotEmpty &&
          !allowed.contains(item.category)) {
        return false;
      }
      return '${item.name} ${item.tags.join(' ')}'.toLowerCase().contains(
        query,
      );
    }).toList();
    final detailed = !{'Décors', 'Terrains'}.contains(kind);
    return Container(
      height: _collapsed ? 48 : _height,
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
              _height = (_height - delta).clamp(178, 330);
            }),
            onOpenFullPalette: widget.onOpenFullPalette,
          ),
          if (!_collapsed) const SizedBox(height: 6),
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
                    ),
                  ),
                  if (kind == 'Personnages' && widget.view.character == null)
                    const Text('Choisissez un personnage à placer.'),
                  if (kind == 'Passages' && widget.view.warpDestination == null)
                    const Text(
                      'Choisissez la carte vers laquelle mène le passage.',
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
              child: Row(
                children: [
                  if (tree.nodes.isNotEmpty || tree.uncategorized > 0) ...[
                    SizedBox(
                      width: 228,
                      child: ResourceCategoryFilter(
                        tree: tree,
                        selected: selectedCategory,
                        compact: true,
                        onChanged: (value) {
                          if (resourceKind == ResourceKind.decors) {
                            widget.view.decorCategoryId = value;
                          } else {
                            widget.view.terrainCategoryId = value;
                          }
                          setState(() {});
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      children: [
                        SizedBox(
                          height: 44,
                          child: StudioSearchField(
                            controller: widget.search,
                            label: kind == 'Décors'
                                ? 'Rechercher un décor'
                                : 'Rechercher un terrain',
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Expanded(
                          child: visible.isEmpty
                              ? Center(
                                  child: Text(
                                    'Aucune ressource dans cette catégorie.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                )
                              : ListView.builder(
                                  key: ValueKey('dock-$kind-$selectedCategory'),
                                  scrollDirection: Axis.horizontal,
                                  itemCount: visible.length,
                                  itemBuilder: (context, index) {
                                    final item = visible[index];
                                    return Padding(
                                      padding: const EdgeInsets.only(right: 8),
                                      child: SizedBox(
                                        width: 122,
                                        child: StudioPaletteCard(
                                          key: ValueKey(
                                            item.element != null
                                                ? 'decor-${item.id}'
                                                : 'terrain-${item.id}',
                                          ),
                                          name: item.name,
                                          maxNameLines: 2,
                                          preview: item.element != null
                                              ? widget.visuals.thumbnail(
                                                  item.element!,
                                                  size: 74,
                                                )
                                              : resourcePreview(
                                                  item,
                                                  widget.project,
                                                  widget.visuals,
                                                  size: 74,
                                                ),
                                          selected: item.element != null
                                              ? widget.view.brush?.id == item.id
                                              : widget.view.terrain?.id ==
                                                    item.id,
                                          onTap: () {
                                            final view = widget.view;
                                            view.brush = item.element;
                                            view.terrain = item.terrain;
                                            view.tile = null;
                                            view.character = null;
                                            view.tool = item.element != null
                                                ? StudioMapTool.place
                                                : StudioMapTool.terrain;
                                            widget.onChanged();
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
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
