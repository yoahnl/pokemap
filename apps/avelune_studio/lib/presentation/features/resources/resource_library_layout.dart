part of 'resource_library_screen.dart';

extension _ResourceLibraryLayout on _ResourceLibraryScreenState {
  Widget buildLibrary(BuildContext context) {
    final tree = ResourceCategoryTree(widget.project, state.kind, items);
    final filtered = state.visibleItems(
      items,
      acceptedCategories: tree.idsFor(state.category),
    );
    final selected = state.reconcileSelection(filtered);
    final hasCategories = tree.nodes.isNotEmpty || tree.uncategorized > 0;
    return LayoutBuilder(
      builder: (context, bounds) {
        final inlineDetail =
            bounds.maxWidth >= 1000 &&
            MediaQuery.textScalerOf(context).scale(14) <= 20;
        final inlineCategories = bounds.maxWidth >= 1200 && hasCategories;
        if (state.revealPending) {
          state.revealPending = false;
          if (!inlineDetail && selected != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) showDetail(selected);
            });
          }
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            StudioPageHeader(
              title: 'Ressources',
              alignActionsToEnd: true,
              description: bounds.maxHeight < 650
                  ? null
                  : 'Vos décors, terrains et images, prêts à donner vie à la carte.',
              actions: [
                if (widget.onManageContainers != null)
                  StudioButton(
                    key: const ValueKey('resource-manage-containers'),
                    label: state.kind == ResourceKind.images
                        ? 'Gérer les dossiers'
                        : 'Gérer les catégories',
                    icon: Icons.folder_outlined,
                    secondary: true,
                    onPressed: () => widget.onManageContainers!(state.kind),
                  ),
                ...resourceCreationButtons(
                  context: context,
                  project: widget.project,
                  visuals: widget.visuals,
                  onCreateBorder: widget.onCreateBorder,
                  onCreatePath: widget.onTerrain,
                  onImport: widget.onImport,
                  onCharacters: widget.onCharacters,
                ),
                StudioButton(
                  label: widget.targetMapName == null
                      ? 'Retour à la carte'
                      : 'Carte : ${widget.targetMapName}',
                  icon: Icons.arrow_back,
                  secondary: true,
                  onPressed: widget.onBack,
                ),
                StudioButton(
                  label: 'Importer une image',
                  icon: Icons.add_photo_alternate_outlined,
                  onPressed: widget.onImport,
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StudioTabs<ResourceKind>(
                items: const {
                  ResourceKind.decors: 'Décors',
                  ResourceKind.terrains: 'Terrains',
                  ResourceKind.images: 'Images et tuiles',
                },
                selected: state.kind,
                onChanged: (kind) => change(() {
                  state.kind = kind;
                  state.category = '';
                }),
              ),
            ),
            if (widget.project.borderCatalog.records.isNotEmpty)
              ResourceBorderDraftBar(
                records: widget.project.borderCatalog.records,
                onResume: widget.onResumeBorder,
              ),
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
            if (state.kind == ResourceKind.terrains &&
                widget.terrainDrafts.isNotEmpty &&
                widget.onResumeTerrain != null)
              ResourceTerrainDraftList(
                drafts: widget.terrainDrafts,
                onResume: widget.onResumeTerrain!,
              ),
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
      },
    );
  }
}
