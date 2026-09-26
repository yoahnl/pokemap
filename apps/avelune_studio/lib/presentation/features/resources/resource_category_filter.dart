import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_catalog.dart';
import 'resource_category_tree.dart';

class ResourceCategoryFilter extends StatefulWidget {
  const ResourceCategoryFilter({
    super.key,
    required this.tree,
    required this.selected,
    required this.onChanged,
    this.compact = false,
  });
  final ResourceCategoryTree tree;
  final String selected;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<ResourceCategoryFilter> createState() => _ResourceCategoryFilterState();
}

class _ResourceCategoryFilterState extends State<ResourceCategoryFilter> {
  final _collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final nodes = widget.tree.nodes;
    final parents = {for (final node in nodes) node.id: node.parentId};
    final parentIds = nodes.map((node) => node.parentId).toSet();
    bool hidden(ResourceCategoryNode node) {
      var parent = node.parentId;
      while (parent != null) {
        if (_collapsed.contains(parent)) return true;
        parent = parents[parent];
      }
      return false;
    }

    return SingleChildScrollView(
      child: StudioPanel(
        title: 'Catégories',
        compact: true,
        children: [
          StudioChoice(
            key: const ValueKey('resource-category-'),
            label: 'Toutes les catégories',
            subtitle: '${widget.tree.total}',
            dense: widget.compact,
            selected: widget.selected.isEmpty,
            onTap: () => widget.onChanged(''),
          ),
          for (final node in nodes)
            if (!hidden(node))
              Padding(
                padding: EdgeInsets.only(left: node.depth * 12.0, top: 4),
                child: Row(
                  children: [
                    if (parentIds.contains(node.id))
                      StudioTool(
                        label: _collapsed.contains(node.id)
                            ? 'Déplier ${node.name}'
                            : 'Replier ${node.name}',
                        icon: _collapsed.contains(node.id)
                            ? Icons.chevron_right
                            : Icons.expand_more,
                        onPressed: () => setState(() {
                          if (!_collapsed.add(node.id)) {
                            _collapsed.remove(node.id);
                          }
                        }),
                      ),
                    Expanded(
                      child: StudioChoice(
                        key: ValueKey('resource-category-${node.id}'),
                        label: node.name,
                        subtitle: '${node.count}',
                        dense: widget.compact,
                        selected: widget.selected == node.id,
                        onTap: () => widget.onChanged(node.id),
                      ),
                    ),
                  ],
                ),
              ),
          if (widget.tree.uncategorized > 0)
            StudioChoice(
              key: const ValueKey('resource-category-__uncategorized__'),
              label: 'Sans catégorie',
              subtitle: '${widget.tree.uncategorized}',
              dense: widget.compact,
              selected: widget.selected == uncategorizedResourceCategory,
              onTap: () => widget.onChanged(uncategorizedResourceCategory),
            ),
        ],
      ),
    );
  }
}
