import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart' show ResourceLibraryRole;

import '../../../shared/localization/studio_locale.dart';
import 'resource_library_view_data.dart';

class ResourceLibraryToolbar extends StatelessWidget {
  const ResourceLibraryToolbar({
    super.key,
    required this.search,
    required this.searchFocus,
    required this.onSearch,
    required this.dimension,
    required this.onDimension,
    required this.sort,
    required this.onSort,
    required this.grid,
    required this.onGrid,
    required this.detailsVisible,
    required this.onDetails,
  });

  final TextEditingController search;
  final FocusNode searchFocus;
  final ValueChanged<String> onSearch;
  final ResourceLibraryDimension? dimension;
  final ValueChanged<ResourceLibraryDimension?> onDimension;
  final ResourceLibrarySort sort;
  final ValueChanged<ResourceLibrarySort> onSort;
  final bool grid;
  final ValueChanged<bool> onGrid;
  final bool detailsVisible;
  final VoidCallback? onDetails;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: StudioSpacing.m,
    runSpacing: StudioSpacing.m,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      SizedBox(
        width: 268,
        child: StudioSearchField(
          key: const ValueKey('library-search'),
          controller: search,
          focusNode: searchFocus,
          label: context.l10n.resourceSearch,
          onChanged: onSearch,
        ),
      ),
      SizedBox(
        width: 100,
        child: StudioSelect(
          label: 'Dimension',
          value: dimension?.name ?? '',
          options: {
            '': 'Tout',
            for (final item in ResourceLibraryDimension.values)
              item.name: item.label,
          },
          onChanged: (value) => onDimension(
            value.isEmpty
                ? null
                : ResourceLibraryDimension.values.byName(value),
          ),
        ),
      ),
      PopupMenuButton<ResourceLibrarySort>(
        tooltip: 'Changer le tri · ${sort.label}',
        icon: const Icon(Icons.swap_vert),
        initialValue: sort,
        onSelected: onSort,
        itemBuilder: (context) => [
          for (final option in ResourceLibrarySort.values)
            PopupMenuItem(value: option, child: Text(option.label)),
        ],
      ),
      StudioTool(
        label: 'Vue en grille',
        icon: Icons.grid_view_outlined,
        selected: grid,
        onPressed: () => onGrid(true),
      ),
      StudioTool(
        label: 'Vue en liste',
        icon: Icons.view_list_outlined,
        selected: !grid,
        onPressed: () => onGrid(false),
      ),
      StudioTool(
        label: 'Afficher ou masquer les détails',
        icon: Icons.view_sidebar_outlined,
        selected: detailsVisible,
        onPressed: onDetails,
      ),
    ],
  );
}

class ResourceLibraryRoles extends StatelessWidget {
  const ResourceLibraryRoles({
    super.key,
    required this.role,
    required this.onRole,
    required this.families,
    required this.family,
    required this.onFamily,
  });

  final ResourceLibraryRole role;
  final ValueChanged<ResourceLibraryRole> onRole;
  final Map<String, String> families;
  final String? family;
  final ValueChanged<String?> onFamily;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: StudioSpacing.m,
    runSpacing: StudioSpacing.m,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: [
      for (final option in ResourceLibraryRole.values)
        StudioFilterChip(
          key: ValueKey('library-role-${option.name}'),
          label: option == ResourceLibraryRole.standard
              ? context.l10n.libraryAuthorResources
              : context.l10n.libraryComponents,
          selected: option == role,
          onSelected: (_) => onRole(option),
        ),
      if (families.isNotEmpty)
        SizedBox(
          width: 275,
          child: StudioSelect(
            label: 'Famille',
            value: families.containsKey(family) ? family : '',
            options: {'': context.l10n.libraryAllFamilies, ...families},
            onChanged: (value) => onFamily(value.isEmpty ? null : value),
          ),
        ),
    ],
  );
}
