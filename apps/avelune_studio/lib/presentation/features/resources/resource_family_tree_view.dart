import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import 'resource_catalog.dart';
import 'resource_family_tree.dart';

class ResourceFamilyTreeView extends StatefulWidget {
  const ResourceFamilyTreeView({
    super.key,
    required this.tree,
    required this.selectedFamilyId,
    required this.onChanged,
    this.compact = false,
  });
  final ResourceFamilyTree tree;
  final String selectedFamilyId;
  final ValueChanged<String> onChanged;
  final bool compact;

  @override
  State<ResourceFamilyTreeView> createState() => _ResourceFamilyTreeViewState();
}

class _ResourceFamilyTreeViewState extends State<ResourceFamilyTreeView> {
  final collapsed = <String>{};

  @override
  Widget build(BuildContext context) {
    final nodes = widget.tree.nodes;
    final parents = {for (final node in nodes) node.id: node.parentId};
    final parentIds = nodes.map((node) => node.parentId).toSet();
    bool hidden(ResourceFamilyNode node) {
      var parent = node.parentId;
      final visited = <String>{};
      while (parent != null && visited.add(parent)) {
        if (collapsed.contains(parent)) return true;
        parent = parents[parent];
      }
      return false;
    }

    final choices = <Widget>[
      StudioChoice(
        key: const ValueKey('resource-nature-family-'),
        label: 'Toutes les ressources',
        subtitle: '${widget.tree.total}',
        dense: widget.compact,
        selected: widget.selectedFamilyId.isEmpty,
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
                    label: collapsed.contains(node.id)
                        ? 'Déplier ${node.name}'
                        : 'Replier ${node.name}',
                    icon: collapsed.contains(node.id)
                        ? Icons.chevron_right
                        : Icons.expand_more,
                    onPressed: () => setState(() {
                      if (!collapsed.add(node.id)) collapsed.remove(node.id);
                    }),
                  ),
                Expanded(
                  child: StudioChoice(
                    key: ValueKey('resource-nature-family-${node.id}'),
                    label: node.name,
                    subtitle: '${node.count}',
                    dense: widget.compact,
                    selected: widget.selectedFamilyId == node.id,
                    onTap: () => widget.onChanged(node.id),
                  ),
                ),
              ],
            ),
          ),
      StudioChoice(
        key: const ValueKey('resource-nature-family-__unclassified__'),
        label: 'Sans famille',
        subtitle: '${widget.tree.unclassified}',
        dense: widget.compact,
        selected: widget.selectedFamilyId == unclassifiedResourceFamily,
        onTap: () => widget.onChanged(unclassifiedResourceFamily),
      ),
    ];
    return SingleChildScrollView(
      child: widget.compact
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: choices,
            )
          : StudioPanel(title: 'Familles', compact: true, children: choices),
    );
  }
}
