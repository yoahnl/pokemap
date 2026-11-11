part of 'resource_library_screen.dart';

extension _ResourceLibraryLayout on _ResourceLibraryScreenState {
  Widget markedBar(List<ResourceItem> visible) {
    final marked = state.markedItems(items);
    final shown = visible
        .where((item) => state.marked.contains(item.identity))
        .length;
    final hidden = marked.length - shown;
    final count = marked.length;
    return StudioPanel(
      key: const ValueKey('resource-marked-bar'),
      compact: true,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              count == 0
                  ? 'Aucune ressource sélectionnée'
                  : '$count ressource${count == 1 ? '' : 's'} sélectionnée${count == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            if (hidden > 0)
              Text(
                'dont $hidden hors des résultats affichés',
                key: const ValueKey('resource-marked-hidden'),
              ),
            if (widget.onClassifyMarked != null)
              StudioButton(
                key: const ValueKey('resource-marked-classify'),
                label: 'Ranger la sélection…',
                icon: Icons.drive_file_move_outlined,
                secondary: true,
                onPressed: count == 0
                    ? null
                    : () => widget.onClassifyMarked!(marked),
              ),
            StudioButton(
              key: const ValueKey('resource-marked-all'),
              label: 'Sélectionner les ${visible.length} résultats',
              secondary: true,
              onPressed: visible.isEmpty
                  ? null
                  : () => updateMarks(() => state.markAll(visible)),
            ),
            StudioButton(
              key: const ValueKey('resource-marked-clear'),
              label: 'Tout désélectionner',
              secondary: true,
              onPressed: count == 0
                  ? null
                  : () => updateMarks(() => state.clearMarks()),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildLibrary(BuildContext context) {
    final categoriesTree = ResourceCategoryTree(
      widget.project,
      state.kind,
      items,
    );
    List<ResourceItem> matchingResources(
      ResourceCatalogFilterState filters,
      String category,
    ) {
      final candidates = filterResourceCatalog(
        widget.project,
        items,
        filters,
        activeMapId: widget.activeMapId,
      );
      if (!state.atelierVisible) return candidates;
      final acceptedCategories = categoriesTree.idsFor(category);
      return candidates
          .where(
            (item) =>
                state.includesFamily(item) &&
                (category.isEmpty ||
                    (category == uncategorizedResourceCategory
                        ? item.category.isEmpty
                        : acceptedCategories.contains(item.category))),
          )
          .toList();
    }

    final filtered = matchingResources(state.filters, state.category);
    filtered.sort((a, b) {
      final names = a.name.toLowerCase().compareTo(b.name.toLowerCase());
      if (names == 0) return a.identity.compareTo(b.identity);
      return state.sort == ResourceSort.nameAscending ? names : -names;
    });
    final selected = state.reconcileSelection(filtered);
    final regular =
        !state.atelierVisible ||
        (state.family != ResourceLibraryFamily.borders &&
            state.family != ResourceLibraryFamily.models3d &&
            state.family != ResourceLibraryFamily.environments);
    final treeFilters = state.filters.copy()..familyId = '';
    final tree = ResourceFamilyTree(
      widget.project,
      filterResourceCatalog(widget.project, items, treeFilters),
      showComponents: state.filters.showComponents,
    );
    final familyName = state.filters.familyId == unclassifiedResourceFamily
        ? 'Sans famille'
        : widget.project.resourceLibraryCatalog.effectiveFamilies
              .where((family) => family.id == state.filters.familyId)
              .firstOrNull
              ?.name;
    final categoryName = !state.atelierVisible || state.category.isEmpty
        ? null
        : state.category == uncategorizedResourceCategory
        ? 'Sans catégorie'
        : categoriesTree.nodes
              .where((node) => node.id == state.category)
              .firstOrNull
              ?.name;
    return LayoutBuilder(
      builder: (context, bounds) {
        final inlineDetail =
            bounds.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final inlineFamilies = bounds.maxWidth >= 1200;
        if (state.revealPending) {
          state.revealPending = false;
          if (!inlineDetail && selected != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showDetail(selected);
            });
          }
        }
        final content = Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (!inlineFamilies)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: StudioButton(
                  key: const ValueKey('resource-nature-family-chooser'),
                  label: familyName ?? 'Familles',
                  icon: Icons.folder_outlined,
                  secondary: true,
                  onPressed: () => showWorkspaceCompactPanel(
                    context,
                    title: 'Familles de ressources',
                    closeLabel: 'Retour aux ressources',
                    builder: (context, refresh, close) =>
                        natureFamilies(tree, close: close),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'L’import et l’export de packs sont temporairement indisponibles. Votre sélection est conservée.',
                    key: ValueKey('resource-pack-transfer-unavailable'),
                  ),
                  if (state.filters.familyId.isNotEmpty ||
                      state.filters.showComponents ||
                      state.filters.typeKind.isNotEmpty ||
                      state.filters.usableOnly ||
                      state.filters.context != ResourceCatalogContext.all ||
                      state.filters.scope != ResourceCatalogScope.all ||
                      state.filters.usage != ResourceCatalogUsage.all ||
                      categoryName != null) ...[
                    const SizedBox(height: 8),
                    ResourceFilterTags(
                      filters: state.filters,
                      familyLabel: familyName,
                      categoryLabel: categoryName,
                      onClearCategory: () => state.category = '',
                      onChanged: () => change(() {}),
                    ),
                  ],
                  if (regular &&
                      (state.marking || state.marked.isNotEmpty)) ...[
                    const SizedBox(height: 8),
                    markedBar(filtered),
                  ],
                ],
              ),
            ),
            if (state.atelierVisible &&
                state.family == ResourceLibraryFamily.borders)
              Expanded(
                child: StudioEmptyState(
                  key: const ValueKey(
                    'resource-border-workshop-unavailable-state',
                  ),
                  title: 'Atelier des bordures indisponible',
                  description: 'L’atelier est temporairement indisponible. Les bordures publiées restent accessibles dans le catalogue général.',
                  icon: Icons.edit_off_outlined,
                  action: StudioButton(
                    key: const ValueKey('resource-border-return-to-catalog'),
                    label: 'Retour au catalogue',
                    secondary: true,
                    onPressed: () => change(() => state.atelierVisible = false),
                  ),
                ),
              ),
            if (state.atelierVisible &&
                state.family == ResourceLibraryFamily.environments)
              Expanded(
                child: StudioEmptyState(
                  key: const ValueKey(
                    'resource-environment-library-unavailable-state',
                  ),
                  title: 'Atelier des environnements indisponible',
                  description: 'L’édition, la duplication et la suppression des environnements sont temporairement indisponibles. Les environnements publiés restent accessibles dans le catalogue général.',
                  icon: Icons.edit_off_outlined,
                  action: StudioButton(
                    key: const ValueKey(
                      'resource-environment-library-return-to-catalog',
                    ),
                    label: 'Retour au catalogue',
                    secondary: true,
                    onPressed: () => change(() => state.atelierVisible = false),
                  ),
                ),
              ),
            if (state.atelierVisible &&
                state.family == ResourceLibraryFamily.models3d)
              Expanded(
                child:
                    widget.modelLibrary?.call(filtered) ??
                    const Center(child: Text('Bibliothèque 3D indisponible.')),
              ),
            if (regular &&
                state.atelierVisible &&
                state.kind == ResourceKind.terrains &&
                widget.terrainDrafts.isNotEmpty &&
                widget.onResumeTerrain != null)
              ResourceTerrainDraftList(
                drafts: widget.terrainDrafts,
                compact:
                    bounds.maxHeight < 650 ||
                    MediaQuery.textScalerOf(context).scale(14) > 20,
                onResume: widget.onResumeTerrain!,
                onManage: widget.onManageTerrainDraft,
                status: widget.terrainDraftStatus,
                canResume: widget.canResumeTerrain,
              ),
            if (regular)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: ResourceCatalogView(
                          items: filtered,
                          selected: selected,
                          project: widget.project,
                          visuals: widget.visuals,
                          scroll: scroll,
                          grid: state.grid,
                          catalogEmpty: state.atelierVisible
                              ? !items.any(state.includesFamily)
                              : items.isEmpty,
                          onSelect: (item) {
                            select(item);
                            if (!inlineDetail) showDetail(item);
                          },
                          onInformation: widget.onInformation,
                          onMove: widget.onMove,
                          onUsages: widget.onUsages,
                          onReplace: widget.onReplace,
                          onRemove: widget.onRemove,
                          onDuplicate: widget.onDuplicate,
                          canEditTerrain: widget.canEditTerrain,
                          marking: state.marking,
                          marked: state.marked,
                          onMark: (item) =>
                              updateMarks(() => state.toggleMark(item)),
                          onTerrainEdit: (item) {
                            if (widget.canEditTerrain?.call(item) ?? false) {
                              widget.onTerrain(item);
                            }
                          },
                        ),
                      ),
                      if (inlineDetail) ...[
                        const SizedBox(width: 14),
                        SizedBox(width: 280, child: detail(selected)),
                      ],
                    ],
                  ),
                ),
              ),
          ],
        );
        if (!inlineFamilies) return content;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              key: const ValueKey('resource-family-navigation'),
              width: 230,
              child: natureFamilies(tree),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
