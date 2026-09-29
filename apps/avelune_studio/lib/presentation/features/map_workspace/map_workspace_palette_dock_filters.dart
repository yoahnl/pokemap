import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../resources/resource_category_filter.dart';
import '../resources/resource_category_tree.dart';

class MapWorkspacePaletteDockFilters extends StatefulWidget {
  const MapWorkspacePaletteDockFilters({
    super.key,
    required this.tree,
    required this.selected,
    required this.search,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  final ResourceCategoryTree tree;
  final String selected;
  final TextEditingController search;
  final ValueChanged<String> onCategoryChanged;
  final VoidCallback onSearchChanged;

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

  void _toggleSearch() {
    setState(() => _searchOpen = !_searchOpen);
    if (_searchOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    } else {
      widget.search.clear();
      widget.onSearchChanged();
    }
  }

  @override
  Widget build(BuildContext context) {
    final nodes = widget.tree.nodes;
    final parentIds = nodes.map((node) => node.parentId).toSet();
    final quick = nodes.where((node) => !parentIds.contains(node.id)).toList()
      ..sort((left, right) {
        final nested = right.depth.compareTo(left.depth);
        if (nested != 0) return nested;
        final count = right.count.compareTo(left.count);
        return count == 0 ? left.name.compareTo(right.name) : count;
      });
    final choices = quick.take(6).toList();
    final selected = nodes
        .where((node) => node.id == widget.selected)
        .firstOrNull;
    if (selected != null) {
      choices.removeWhere((node) => node.id == selected.id);
      choices.insert(0, selected);
    }
    return SizedBox(
      height: 48,
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: StudioButton(
                    label: 'Toutes',
                    secondary: widget.selected.isNotEmpty,
                    onPressed: () => widget.onCategoryChanged(''),
                  ),
                ),
                for (final node in choices)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Tooltip(
                      message: node.name,
                      child: StudioButton(
                        key: ValueKey('resource-quick-${node.id}'),
                        label: node.name,
                        secondary: widget.selected != node.id,
                        onPressed: () => widget.onCategoryChanged(node.id),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          MenuAnchor(
            controller: _menu,
            menuChildren: [
              SizedBox(
                width: 290,
                height: 300,
                child: PrimaryScrollController.none(
                  child: ResourceCategoryFilter(
                    tree: widget.tree,
                    selected: widget.selected,
                    compact: true,
                    onChanged: (value) {
                      widget.onCategoryChanged(value);
                      _menu.close();
                    },
                  ),
                ),
              ),
            ],
            builder: (context, controller, _) => StudioButton(
              label: 'Catégories',
              icon: Icons.account_tree_outlined,
              secondary: true,
              onPressed: controller.isOpen ? controller.close : controller.open,
            ),
          ),
          const SizedBox(width: 8),
          StudioTool(
            label: _searchOpen
                ? 'Masquer la recherche'
                : 'Rechercher une ressource',
            icon: _searchOpen ? Icons.close : Icons.search,
            selected: _searchOpen,
            onPressed: _toggleSearch,
          ),
          if (_searchOpen) ...[
            const SizedBox(width: 8),
            SizedBox(
              width: 260,
              child: StudioSearchField(
                controller: widget.search,
                focusNode: _searchFocus,
                label: 'Rechercher une ressource',
                onChanged: (_) => widget.onSearchChanged(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
