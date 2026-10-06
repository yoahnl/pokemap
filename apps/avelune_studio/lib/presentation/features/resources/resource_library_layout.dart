part of 'resource_library_screen.dart';

extension _ResourceLibraryLayout on _ResourceLibraryScreenState {
  Widget buildLibrary(BuildContext context) {
    final tree = ResourceCategoryTree(widget.project, state.kind, items);
    final filtered = state.visibleItems(
      items,
      acceptedCategories: tree.idsFor(state.category),
    );
    final selected = state.reconcileSelection(filtered);
    final regular =
        state.family != ResourceLibraryFamily.borders &&
        state.family != ResourceLibraryFamily.environments;
    final hasCategories =
        regular && (tree.nodes.isNotEmpty || tree.uncategorized > 0);
    return LayoutBuilder(
      builder: (context, bounds) {
        final inlineDetail =
            bounds.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final inlineFamilies = bounds.maxWidth >= 1200;
        final inlineCategories = bounds.maxWidth >= 1500 && hasCategories;
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
                  key: const ValueKey('resource-family-chooser'),
                  label: '${state.family.label} · ${state.family.purpose}',
                  icon: state.family.icon,
                  secondary: true,
                  onPressed: () => showWorkspaceCompactPanel(
                    context,
                    title: 'Bibliothèque de ressources',
                    closeLabel: 'Retour aux ressources',
                    builder: (context, refresh, close) =>
                        families(close: close),
                  ),
                ),
              ),
            if (state.family == ResourceLibraryFamily.borders)
              Expanded(
                child: ResourceBorderDraftBar(
                  records: widget.project.borderCatalog.records,
                  onResume: widget.onResumeBorder,
                  onManage: widget.onManageBorder,
                  library: true,
                ),
              ),
            if (state.family == ResourceLibraryFamily.environments)
              Expanded(
                child:
                    widget.environmentLibrary ??
                    const Center(child: Text('Aucun environnement préparé.')),
              ),
            if (regular)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: ResourceCatalogToolbar(
                  search: search,
                  state: state,
                  count: filtered.length,
                  onSearch: (value) => change(() => state.query = value),
                  onSort: (value) => change(() => state.sort = value),
                  onGrid: (value) => change(() => state.grid = value),
                  onFilters: hasCategories && !inlineCategories
                      ? () => showWorkspaceCompactPanel(
                          context,
                          title: 'Catégories',
                          closeLabel: 'Retour aux ressources',
                          builder: (context, refresh, close) =>
                              categories(tree, close: close),
                        )
                      : null,
                ),
              ),
            if (regular &&
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
                      if (inlineCategories) ...[
                        SizedBox(width: 220, child: categories(tree)),
                        const SizedBox(width: 14),
                      ],
                      Expanded(
                        child: ResourceCatalogView(
                          items: filtered,
                          selected: selected,
                          project: widget.project,
                          visuals: widget.visuals,
                          scroll: scroll,
                          grid: state.grid,
                          catalogEmpty: !items.any(
                            (item) => item.kind == state.kind,
                          ),
                          onSelect: (item) {
                            select(item);
                            if (!inlineDetail) {
                              showDetail(item);
                            }
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
                        SizedBox(
                          width: bounds.maxWidth >= 1250 ? 340 : 320,
                          child: detail(selected),
                        ),
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
              width: 220,
              child: families(),
            ),
            const VerticalDivider(width: 1),
            Expanded(child: content),
          ],
        );
      },
    );
  }
}
