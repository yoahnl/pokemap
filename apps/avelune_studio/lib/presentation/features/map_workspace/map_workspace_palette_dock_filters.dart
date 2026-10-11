import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../resources/resource_catalog.dart';
import '../resources/resource_family_tree.dart';
import '../resources/resource_family_tree_view.dart';
import '../resources/resource_filter_button.dart';

class MapWorkspacePaletteDockFilters extends StatefulWidget {
  const MapWorkspacePaletteDockFilters({
    super.key,
    required this.tree,
    required this.filters,
    required this.search,
    required this.onChanged,
    this.activeMapName,
    this.showSearch = true,
    this.countResults,
  });

  final ResourceFamilyTree tree;
  final ResourceCatalogFilterState filters;
  final TextEditingController search;
  final VoidCallback onChanged;
  final String? activeMapName;
  final bool showSearch;
  final int Function(ResourceCatalogFilterState filters, String category)?
  countResults;

  @override
  State<MapWorkspacePaletteDockFilters> createState() =>
      _MapWorkspacePaletteDockFiltersState();
}

class _MapWorkspacePaletteDockFiltersState
    extends State<MapWorkspacePaletteDockFilters> {
  final _menu = MenuController();
  final _searchFocus = FocusNode();
  late bool _searchOpen = widget.search.text.isNotEmpty;

  @override
  void dispose() {
    _searchFocus.dispose();
    super.dispose();
  }

  void _selectFamily(String id) {
    widget.filters.familyId = id;
    widget.onChanged();
  }

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      widget.search.clear();
      widget.filters.query = '';
      widget.onChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.tree.nodes;
    final parentIds = nodes.map((node) => node.parentId).toSet();
    final quick =
        nodes
            .where((node) => node.count > 0 && !parentIds.contains(node.id))
            .toList()
          ..sort((left, right) {
            final nested = right.depth.compareTo(left.depth);
            if (nested != 0) return nested;
            final count = right.count.compareTo(left.count);
            return count == 0 ? left.name.compareTo(right.name) : count;
          });
    final choices = quick.take(6).toList();
    final selected = nodes
        .where((node) => node.id == widget.filters.familyId)
        .firstOrNull;
    if (selected != null) {
      choices.removeWhere((node) => node.id == selected.id);
      choices.insert(0, selected);
    }
    return SizedBox(
      height: 48,
      child: LayoutBuilder(
        builder: (context, bounds) => Row(
          children: [
            if (bounds.maxWidth >= 420)
              Expanded(
                child: _searchOpen && widget.showSearch
                    ? StudioSearchField(
                        controller: widget.search,
                        focusNode: _searchFocus,
                        label: 'Rechercher une ressource',
                        onChanged: (value) {
                          widget.filters.query = value;
                          widget.onChanged();
                        },
                      )
                    : ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: StudioButton(
                              label: 'Toutes',
                              secondary: widget.filters.familyId.isNotEmpty,
                              onPressed: () => _selectFamily(''),
                            ),
                          ),
                          for (final node in choices)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: StudioButton(
                                key: ValueKey('resource-quick-${node.id}'),
                                label: node.name,
                                secondary: widget.filters.familyId != node.id,
                                onPressed: () => _selectFamily(node.id),
                              ),
                            ),
                        ],
                      ),
              ),
            Flexible(
              flex: bounds.maxWidth >= 420 ? 0 : 1,
              child: MenuAnchor(
                controller: _menu,
                menuChildren: [
                  SizedBox(
                    width: 290,
                    height: 300,
                    child: PrimaryScrollController.none(
                      child: ResourceFamilyTreeView(
                        tree: widget.tree,
                        selectedFamilyId: widget.filters.familyId,
                        compact: true,
                        onChanged: (value) {
                          _selectFamily(value);
                          _menu.close();
                        },
                      ),
                    ),
                  ),
                ],
                builder: (context, controller, _) => StudioButton(
                  label: 'Familles',
                  icon: Icons.account_tree_outlined,
                  secondary: true,
                  onPressed: controller.isOpen
                      ? controller.close
                      : controller.open,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              flex: bounds.maxWidth >= 420 ? 0 : 1,
              child: ResourceFilterButton(
                filters: widget.filters,
                activeMapName: widget.activeMapName,
                forMapPicker: true,
                onChanged: widget.onChanged,
                countResults: widget.countResults,
              ),
            ),
            if (widget.showSearch && bounds.maxWidth >= 420) ...[
              const SizedBox(width: 8),
              StudioTool(
                label: _searchOpen
                    ? 'Masquer la recherche'
                    : 'Rechercher une ressource',
                icon: _searchOpen ? Icons.close : Icons.search,
                selected: _searchOpen,
                onPressed: _toggleSearch,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
