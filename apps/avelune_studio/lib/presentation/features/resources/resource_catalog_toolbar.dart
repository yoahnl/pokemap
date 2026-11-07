import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
import '../../shared/widgets/inputs/studio_tabs.dart';
import 'resource_catalog.dart';

class ResourceCatalogToolbar extends StatelessWidget {
  const ResourceCatalogToolbar({
    super.key,
    required this.search,
    required this.state,
    required this.count,
    required this.onSearch,
    required this.onSort,
    required this.onGrid,
    this.onFilters,
    this.filters,
    this.compact = false,
    this.onUsableOnly,
    this.onMarking,
  });
  final TextEditingController search;
  final ResourceLibraryState state;
  final int count;
  final ValueChanged<String> onSearch;
  final ValueChanged<ResourceSort> onSort;
  final ValueChanged<bool> onGrid;
  final VoidCallback? onFilters;
  final Widget? filters;
  final bool compact;
  final ValueChanged<bool>? onUsableOnly;
  final ValueChanged<bool>? onMarking;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!compact && onUsableOnly != null)
          Semantics(
            label: 'Étendue de la bibliothèque',
            child: StudioTabs<bool>(
              items: const {
                false: 'Bibliothèque complète',
                true: 'Ressources utilisables',
              },
              selected: state.filters.usableOnly,
              onChanged: onUsableOnly!,
            ),
          ),
        SizedBox(
          width: (bounds.maxWidth - 390).clamp(230, 440),
          child: StudioSearchField(
            controller: search,
            label: 'Rechercher dans les ressources',
            onChanged: onSearch,
          ),
        ),
        ?filters,
        Text('$count résultat${count == 1 ? '' : 's'}'),
        if (!compact)
          SizedBox(
            width: MediaQuery.textScalerOf(context).scale(170),
            child: DropdownButtonFormField<ResourceSort>(
              key: ValueKey(state.sort),
              initialValue: state.sort,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Trier'),
              items: const [
                DropdownMenuItem(
                  value: ResourceSort.nameAscending,
                  child: Text('Nom A à Z'),
                ),
                DropdownMenuItem(
                  value: ResourceSort.nameDescending,
                  child: Text('Nom Z à A'),
                ),
              ],
              onChanged: (value) {
                if (value != null) onSort(value);
              },
            ),
          ),
        if (!compact)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StudioTool(
                label: 'Mode grille',
                icon: Icons.grid_view,
                selected: state.grid,
                onPressed: () => onGrid(true),
              ),
              const SizedBox(width: 4),
              StudioTool(
                label: 'Mode liste',
                icon: Icons.view_list_outlined,
                selected: !state.grid,
                onPressed: () => onGrid(false),
              ),
            ],
          ),
        if (!compact && onMarking != null)
          StudioButton(
            key: const ValueKey('resource-multi-select'),
            label: state.marking
                ? 'Terminer la sélection'
                : 'Sélection multiple',
            icon: state.marking ? Icons.check : Icons.checklist,
            secondary: !state.marking,
            onPressed: () => onMarking!(!state.marking),
          ),
        if (onFilters != null)
          StudioButton(
            label: 'Filtres',
            icon: Icons.filter_list,
            secondary: true,
            onPressed: onFilters,
          ),
      ],
    ),
  );
}
