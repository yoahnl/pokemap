import 'package:flutter/material.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/buttons/studio_tool.dart';
import '../../shared/widgets/inputs/studio_search_field.dart';
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
  });
  final TextEditingController search;
  final ResourceLibraryState state;
  final int count;
  final ValueChanged<String> onSearch;
  final ValueChanged<ResourceSort> onSort;
  final ValueChanged<bool> onGrid;
  final VoidCallback? onFilters;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) => Wrap(
      spacing: 12,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: (bounds.maxWidth - 390).clamp(230, 440),
          child: StudioSearchField(
            controller: search,
            label: 'Rechercher dans les ressources',
            onChanged: onSearch,
          ),
        ),
        Text('$count résultat${count == 1 ? '' : 's'}'),
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
