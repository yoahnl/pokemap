import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_usage_category.dart';
import 'package:avelune_studio/features/rendering/contracts/map_workspace_visuals.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_category_grid.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_card.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';

class MapBuilderResourceSelection {
  const MapBuilderResourceSelection({
    required this.category,
    required this.scope,
    required this.context,
    required this.query,
  });

  final ResourceUsageCategory category;
  final ResourceCatalogScope scope;
  final ResourceCatalogContext context;
  final String query;

  MapBuilderResourceSelection copyWith({
    ResourceUsageCategory? category,
    ResourceCatalogScope? scope,
    ResourceCatalogContext? context,
    String? query,
  }) => MapBuilderResourceSelection(
    category: category ?? this.category,
    scope: scope ?? this.scope,
    context: context ?? this.context,
    query: query ?? this.query,
  );
}

List<ResourceItem> mapBuilderCandidates(
  ProjectManifest project,
  String mapId,
  ResourceUsageCategory category,
) => [
  for (final item in resourceCatalog(project))
    if (resourceUsageCategory(item, project) == category &&
        item.usableIn(project, activeMapId: mapId))
      item,
];

List<ResourceItem> mapBuilderResources(
  ProjectManifest project,
  String mapId,
  List<ResourceItem> candidates,
  MapBuilderResourceSelection selection, {
  ResourceCatalogScope? scope,
}) => [
  for (final item in filterResourceCatalog(
    project,
    candidates,
    ResourceCatalogFilterState(
      scope: scope ?? selection.scope,
      query: selection.query,
    ),
    activeMapId: mapId,
    forMapPicker: true,
  ))
    if (_fitsContext(
      item.metadata(project)?.placementContext,
      selection.context,
    ))
      item,
];

bool _fitsContext(
  ResourcePlacementContext? placement,
  ResourceCatalogContext wanted,
) => switch (wanted) {
  ResourceCatalogContext.interior =>
    placement != ResourcePlacementContext.exterior,
  ResourceCatalogContext.exterior =>
    placement != ResourcePlacementContext.interior,
  _ => true,
};

class MapBuilderResourcePanel extends StatefulWidget {
  const MapBuilderResourcePanel({
    super.key,
    required this.project,
    required this.mapId,
    required this.visuals,
    required this.selection,
    required this.onSelection,
    required this.loading,
    required this.armed,
    required this.onUse,
  });

  final ProjectManifest? project;
  final String? mapId;
  final MapWorkspaceVisuals? visuals;
  final MapBuilderResourceSelection selection;
  final ValueChanged<MapBuilderResourceSelection> onSelection;
  final bool loading;
  final String? armed;
  final ValueChanged<ResourceItem>? onUse;

  @override
  State<MapBuilderResourcePanel> createState() =>
      _MapBuilderResourcePanelState();
}

class _MapBuilderResourcePanelState extends State<MapBuilderResourcePanel> {
  late final _search = TextEditingController(text: widget.selection.query);

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final project = widget.project;
    final mapId = widget.mapId;
    final selection = widget.selection;
    final candidates = project == null || mapId == null || widget.loading
        ? const <ResourceItem>[]
        : mapBuilderCandidates(project, mapId, selection.category);
    final items = candidates.isEmpty
        ? const <ResourceItem>[]
        : mapBuilderResources(project!, mapId!, candidates, selection);
    int count(ResourceCatalogScope scope) => candidates.isEmpty
        ? 0
        : mapBuilderResources(
            project!,
            mapId!,
            candidates,
            selection,
            scope: scope,
          ).length;
    final caption = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.l,
            StudioSpacing.l,
            StudioSpacing.l,
            0,
          ),
          child: StudioSearchField(
            key: const ValueKey('map-resource-search'),
            controller: _search,
            label: context.l10n.resourceSearch,
            onChanged: (value) =>
                widget.onSelection(selection.copyWith(query: value)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            StudioSpacing.l,
            StudioSpacing.l,
            StudioSpacing.l,
            StudioSpacing.s,
          ),
          child: Text(context.l10n.resourceCategories, style: caption),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          child: MapBuilderCategoryGrid(
            selected: selection.category,
            onSelected: (category) =>
                widget.onSelection(selection.copyWith(category: category)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(StudioSpacing.l),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ResourceCatalogScope>(
                key: const ValueKey('map-resource-scope'),
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                    value: ResourceCatalogScope.map,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.l10n.resourceFilterMap(count(ResourceCatalogScope.map)),
                      ),
                    ),
                  ),
                  ButtonSegment(
                    value: ResourceCatalogScope.all,
                    label: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        context.l10n.resourceFilterProject(
                          count(ResourceCatalogScope.all),
                        ),
                      ),
                    ),
                  ),
                ],
                selected: {selection.scope},
                onSelectionChanged: (value) =>
                    widget.onSelection(selection.copyWith(scope: value.single)),
              ),
              const SizedBox(height: StudioSpacing.s),
              SegmentedButton<ResourceCatalogContext>(
                key: const ValueKey('map-resource-context'),
                showSelectedIcon: false,
                segments: [
                  for (final context in const [
                    ResourceCatalogContext.all,
                    ResourceCatalogContext.interior,
                    ResourceCatalogContext.exterior,
                  ])
                    ButtonSegment(
                      value: context,
                      label: Text(this.context.l10n.resourceContext(context)),
                    ),
                ],
                selected: {selection.context},
                onSelectionChanged: (value) => widget.onSelection(
                  selection.copyWith(context: value.single),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: StudioSpacing.l),
          child: Text(
            context.l10n.resourceListTitle(
              context.l10n.resourceCategory(selection.category),
              items.length,
            ),
            key: const ValueKey('map-resource-count'),
            style: theme.textTheme.labelLarge,
          ),
        ),
        Expanded(child: _results(context, project, items)),
      ],
    );
  }

  Widget _results(
    BuildContext context,
    ProjectManifest? project,
    List<ResourceItem> items,
  ) {
    final visuals = widget.visuals;
    if (widget.loading || project == null || visuals == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(StudioSpacing.xl),
        child: StudioEmptyState(
          icon: Icons.inventory_2_outlined,
          title: context.l10n.resourceEmptyTitle,
          description: context.l10n.resourceEmptyBody,
        ),
      );
    }
    return GridView.builder(
      key: const ValueKey('map-resource-grid'),
      padding: const EdgeInsets.all(StudioSpacing.l),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: StudioSpacing.l,
        crossAxisSpacing: StudioSpacing.l,
        childAspectRatio: .78,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => MapBuilderResourceCard(
        item: items[index],
        project: project,
        mapId: widget.mapId,
        visuals: visuals,
        armed: items[index].identity == widget.armed,
        onUse: widget.onUse,
      ),
    );
  }
}
