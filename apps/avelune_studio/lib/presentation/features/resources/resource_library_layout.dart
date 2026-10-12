part of 'resource_library_screen.dart';

extension _ResourceLibraryLayout on _ResourceLibraryScreenState {
  Widget buildLibrary(BuildContext context) {
    final categoriesTree = ResourceCategoryTree(
      widget.project,
      state.kind,
      items,
    );
    bool atelierIncludes(ResourceItem item) => switch (state.family) {
      ResourceLibraryFamily.decors =>
        item.element != null || item.model3d != null,
      ResourceLibraryFamily.terrains => item.terrain != null,
      ResourceLibraryFamily.images => item.tileset != null,
      _ => true,
    };
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
                atelierIncludes(item) &&
                item.kind == state.kind &&
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
            libraryHeader(context, bounds),
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
            if (state.atelierVisible &&
                state.family == ResourceLibraryFamily.borders)
              Expanded(
                child: ResourceBorderDraftBar(
                  records: widget.project.borderCatalog.records,
                  onResume: widget.onResumeBorder,
                  onManage: widget.onManageBorder,
                  library: true,
                ),
              ),
            if (state.atelierVisible &&
                state.family == ResourceLibraryFamily.environments)
              Expanded(
                child:
                    widget.environmentLibrary ??
                    const Center(child: Text('Aucun environnement préparé.')),
              ),
            if (state.atelierVisible &&
                state.family == ResourceLibraryFamily.models3d)
              Expanded(
                child:
                    widget.modelLibrary ??
                    const Center(child: Text('Bibliothèque 3D indisponible.')),
              ),
            if (regular)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    ResourceCatalogToolbar(
                      search: search,
                      compact: bounds.maxHeight < 550,
                      state: state,
                      count: filtered.length,
                      onSearch: (value) => change(() => state.query = value),
                      onSort: (value) => change(() => state.sort = value),
                      onGrid: (value) => change(() => state.grid = value),
                      filters: ResourceFilterButton(
                        filters: state.filters,
                        activeMapName: widget.targetMapName,
                        categoryTree: state.atelierVisible
                            ? categoriesTree
                            : null,
                        category: state.category,
                        onCategoryChanged: state.atelierVisible
                            ? (value) => state.category = value
                            : null,
                        onChanged: () => change(() {}),
                        countResults: (filters, category) =>
                            matchingResources(filters, category).length,
                      ),
                    ),
                    if (state.filters.familyId.isNotEmpty ||
                        state.filters.showComponents ||
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
                  ],
                ),
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
                              ? !items.any(atelierIncludes)
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
