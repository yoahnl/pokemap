import 'package:flutter/material.dart';

import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_filter_tag.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../map_workspace/workspace_compact_panel.dart';
import 'resource_catalog.dart';
import 'resource_category_filter.dart';
import 'resource_category_tree.dart';

extension ResourceCatalogUsageLabels on ResourceCatalogUsage {
  String get label => switch (this) {
    ResourceCatalogUsage.all => 'Tous les usages',
    ResourceCatalogUsage.place => 'Poser',
    ResourceCatalogUsage.paint => 'Peindre',
    ResourceCatalogUsage.trace => 'Tracer',
    ResourceCatalogUsage.scatter => 'Répartir',
  };
}

String resourceScopeFilterLabel(ResourceCatalogScope scope, String? mapName) =>
    switch (scope) {
      ResourceCatalogScope.all => 'Toutes les ressources',
      ResourceCatalogScope.project => 'Partagées dans le projet',
      ResourceCatalogScope.map =>
        mapName == null ? 'Propres à une carte' : 'Propres à « $mapName »',
    };

class ResourceFilterButton extends StatelessWidget {
  const ResourceFilterButton({
    super.key,
    required this.filters,
    required this.onChanged,
    this.activeMapName,
    this.forMapPicker = false,
    this.categoryTree,
    this.category = '',
    this.onCategoryChanged,
    this.countResults,
  });
  final ResourceCatalogFilterState filters;
  final VoidCallback onChanged;
  final String? activeMapName;
  final bool forMapPicker;
  final ResourceCategoryTree? categoryTree;
  final String category;
  final ValueChanged<String>? onCategoryChanged;
  final int Function(ResourceCatalogFilterState filters, String category)?
  countResults;

  @override
  Widget build(BuildContext context) {
    final count =
        (filters.scope == ResourceCatalogScope.all ? 0 : 1) +
        (!forMapPicker && filters.usage != ResourceCatalogUsage.all ? 1 : 0) +
        (filters.showComponents ? 1 : 0) +
        (categoryTree != null && category.isNotEmpty ? 1 : 0);
    return StudioButton(
      key: const ValueKey('resource-filter-button'),
      label: count == 0 ? 'Filtres' : 'Filtres ($count)',
      icon: Icons.filter_list,
      secondary: true,
      onPressed: () {
        final draft = filters.copy();
        var draftCategory = category;
        showWorkspaceCompactPanel(
          context,
          title: 'Filtres des ressources',
          closeLabel: 'Annuler les filtres',
          builder: (context, refresh, close) {
            final resultCount = countResults?.call(draft, draftCategory);
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(12),
                    child: StudioPanel(
                      compact: true,
                      children: [
                        StudioSelect(
                          key: const ValueKey('resource-filter-scope'),
                          label: 'Disponibilité',
                          value: draft.scope.name,
                          options: {
                            for (final scope in ResourceCatalogScope.values)
                              scope.name: resourceScopeFilterLabel(
                                scope,
                                forMapPicker ? activeMapName : null,
                              ),
                          },
                          onChanged: (value) {
                            draft.scope = ResourceCatalogScope.values.byName(
                              value,
                            );
                            refresh();
                          },
                        ),
                        if (!forMapPicker) ...[
                          const SizedBox(height: 16),
                          StudioSelect(
                            key: const ValueKey('resource-filter-usage'),
                            label: 'Usage',
                            value: draft.usage.name,
                            options: {
                              for (final usage in ResourceCatalogUsage.values)
                                usage.name: usage.label,
                            },
                            onChanged: (value) {
                              draft.usage = ResourceCatalogUsage.values.byName(
                                value,
                              );
                              refresh();
                            },
                          ),
                        ],
                        const SizedBox(height: 16),
                        StudioToggleRow(
                          key: const ValueKey('resource-filter-components'),
                          label: 'Afficher les composants',
                          description: 'Pièces utilisées pour composer les terrains, chemins, bordures et environnements.',
                          value: draft.showComponents,
                          onChanged: (value) {
                            draft.showComponents = value;
                            refresh();
                          },
                        ),
                        const SizedBox(height: 16),
                        Text(
                          !forMapPicker || activeMapName == null
                              ? 'Les ressources propres à une carte ne sont proposées que dans leur carte.'
                              : 'La palette de « $activeMapName » propose les ressources du projet et celles de cette carte.',
                        ),
                        if (categoryTree != null &&
                            onCategoryChanged != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Organisation existante',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 320,
                            child: ResourceCategoryFilter(
                              tree: categoryTree!,
                              selected: draftCategory,
                              compact: true,
                              onChanged: (value) {
                                draftCategory = value;
                                refresh();
                              },
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (resultCount != null) ...[
                        Text(
                          '$resultCount résultat${resultCount == 1 ? '' : 's'}',
                          key: const ValueKey('resource-filter-result-count'),
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 12),
                      ],
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          StudioButton(
                            key: const ValueKey('resource-filter-reset'),
                            label: 'Réinitialiser',
                            secondary: true,
                            onPressed: () {
                              draft.scope = ResourceCatalogScope.all;
                              draft.usage = ResourceCatalogUsage.all;
                              draft.showComponents = false;
                              draftCategory = '';
                              refresh();
                            },
                          ),
                          StudioButton(
                            key: const ValueKey('resource-filter-cancel'),
                            label: 'Annuler',
                            secondary: true,
                            onPressed: close,
                          ),
                          StudioButton(
                            key: const ValueKey('resource-filter-apply'),
                            label: 'Appliquer',
                            onPressed: () {
                              filters.scope = draft.scope;
                              filters.usage = draft.usage;
                              filters.showComponents = draft.showComponents;
                              close();
                              onCategoryChanged?.call(draftCategory);
                              onChanged();
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class ResourceFilterTags extends StatelessWidget {
  const ResourceFilterTags({
    super.key,
    required this.filters,
    required this.onChanged,
    this.activeMapName,
    this.familyLabel,
    this.forMapPicker = false,
    this.categoryLabel,
    this.onClearCategory,
  });
  final ResourceCatalogFilterState filters;
  final VoidCallback onChanged;
  final String? activeMapName, familyLabel;
  final bool forMapPicker;
  final String? categoryLabel;
  final VoidCallback? onClearCategory;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      if (filters.showComponents)
        StudioFilterTag(
          key: const ValueKey('resource-filter-tag-components'),
          label: 'Composants affichés',
          onRemove: () {
            filters.showComponents = false;
            onChanged();
          },
        ),
      if (filters.familyId.isNotEmpty && familyLabel != null)
        StudioFilterTag(
          key: const ValueKey('resource-filter-tag-family'),
          label: familyLabel!,
          onRemove: () {
            filters.familyId = '';
            onChanged();
          },
        ),
      if (filters.scope != ResourceCatalogScope.all)
        StudioFilterTag(
          key: const ValueKey('resource-filter-tag-scope'),
          label: resourceScopeFilterLabel(
            filters.scope,
            forMapPicker ? activeMapName : null,
          ),
          onRemove: () {
            filters.scope = ResourceCatalogScope.all;
            onChanged();
          },
        ),
      if (!forMapPicker && filters.usage != ResourceCatalogUsage.all)
        StudioFilterTag(
          key: const ValueKey('resource-filter-tag-usage'),
          label: filters.usage.label,
          onRemove: () {
            filters.usage = ResourceCatalogUsage.all;
            onChanged();
          },
        ),
      if (categoryLabel != null && onClearCategory != null)
        StudioFilterTag(
          key: const ValueKey('resource-filter-tag-category'),
          label: categoryLabel!,
          onRemove: () {
            onClearCategory!();
            onChanged();
          },
        ),
    ],
  );
}
