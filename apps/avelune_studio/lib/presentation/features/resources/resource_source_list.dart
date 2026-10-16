import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../map_workspace/map_workspace_visuals.dart';
import '../map_workspace/workspace_compact_panel.dart';
import 'resource_catalog.dart';
import 'resource_family_tree.dart';
import 'resource_family_tree_view.dart';
import 'resource_filter_button.dart';
import 'resource_preview.dart';

class ResourceSourceList extends StatefulWidget {
  const ResourceSourceList({
    super.key,
    required this.project,
    required this.visuals,
    required this.items,
    required this.onPick,
    this.activeMapId,
    this.selectedIdentity,
    this.forMapPicker = true,
    this.keyPrefix = 'path-source',
    this.draggableElements = false,
  });
  final ProjectManifest project;
  final MapWorkspaceVisuals visuals;
  final List<ResourceItem> items;
  final ValueChanged<ResourceItem> onPick;
  final String? activeMapId, selectedIdentity;
  final bool forMapPicker;
  final String keyPrefix;
  final bool draggableElements;
  @override
  State<ResourceSourceList> createState() => _ResourceSourceListState();
}

class _ResourceSourceListState extends State<ResourceSourceList> {
  final search = TextEditingController();
  final filters = ResourceCatalogFilterState(showComponents: true);
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  List<ResourceItem> visible(ResourceCatalogFilterState state) =>
      filterResourceCatalog(
        widget.project,
        widget.items,
        state,
        activeMapId: widget.activeMapId,
        forMapPicker: widget.forMapPicker,
      );
  @override
  Widget build(BuildContext context) {
    final items = visible(filters);
    final tree = ResourceFamilyTree(
      widget.project,
      widget.items,
      activeMapId: widget.activeMapId,
      forMapPicker: widget.forMapPicker,
      filters: filters,
    );
    final label =
        tree.nodes
            .where((node) => node.id == filters.familyId)
            .firstOrNull
            ?.name ??
        (filters.familyId == unclassifiedResourceFamily
            ? 'Sans famille'
            : null);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSearchField(
          controller: search,
          onChanged: (value) => setState(() => filters.query = value),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            StudioButton(
              key: const ValueKey('resource-source-families'),
              label: label ?? 'Familles',
              icon: Icons.folder_outlined,
              secondary: true,
              onPressed: () => showWorkspaceCompactPanel(
                context,
                title: 'Familles',
                builder: (context, refresh, close) => Padding(
                  padding: const EdgeInsets.all(12),
                  child: ResourceFamilyTreeView(
                    tree: tree,
                    selectedFamilyId: filters.familyId,
                    compact: true,
                    onChanged: (value) {
                      close();
                      setState(() => filters.familyId = value);
                    },
                  ),
                ),
              ),
            ),
            ResourceFilterButton(
              filters: filters,
              forMapPicker: widget.forMapPicker,
              onChanged: () => setState(() {}),
              countResults: (draft, _) => visible(draft).length,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ResourceFilterTags(
          filters: filters,
          familyLabel: label,
          forMapPicker: widget.forMapPicker,
          onChanged: () => setState(() {}),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: items.isEmpty
              ? const Center(child: Text('Aucune ressource disponible.'))
              : ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    final choice = StudioChoice(
                      key: ValueKey('${widget.keyPrefix}-${item.id}'),
                      label: item.name,
                      subtitle: resourceCatalogScopeLabel(widget.project, item),
                      selected: item.identity == widget.selectedIdentity,
                      leading: resourcePreview(
                        item,
                        widget.project,
                        widget.visuals,
                        size: 64,
                      ),
                      onTap: () => widget.onPick(item),
                    );
                    return !widget.draggableElements || item.element == null
                        ? choice
                        : Draggable<ProjectElementEntry>(
                            data: item.element!,
                            feedback: Material(
                              elevation: 6,
                              child: widget.visuals.thumbnail(
                                item.element!,
                                size: 56,
                              ),
                            ),
                            child: choice,
                          );
                  },
                ),
        ),
      ],
    );
  }
}
