part of 'resource_library_view.dart';

extension _ResourceLibraryResults on _ResourceLibraryViewState {
  Widget _library(
    BuildContext context,
    List<ResourceLibraryItemView> matches, {
    required bool sidebar,
    required bool docked,
    required ResourceLibraryItemView? selected,
  }) {
    const padding = EdgeInsets.all(StudioSpacing.xxl);
    final availableFamilies = {
      if (widget.familyLabels.isNotEmpty)
        for (final item in _roleItems)
          if (_category == null || _category == item.category)
            ...item.familyIds,
    };
    final organization = _organizationControls(context);
    Widget tile(int index) {
      final item = matches[index];
      return ResourceLibraryTile(
        key: ValueKey('library-item-${item.id}'),
        item: item,
        maps: widget.maps,
        selected: _marking
            ? _marked.contains(item.id)
            : selected?.id == item.id,
        grid: _grid,
        preview: widget.tilePreview?.call(item),
        onSelected: () =>
            _marking ? _toggleMark(item.id) : _select(item, docked: docked),
      );
    }

    return CustomScrollView(
      key: const PageStorageKey('resource-library-results'),
      controller: _scroll,
      slivers: [
        SliverPadding(
          padding: padding,
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ResourceLibraryHeading(
                  onImport: widget.onImport == null
                      ? null
                      : () => widget.onImport!(context),
                  onImportPack: widget.onImportPack == null
                      ? null
                      : () => widget.onImportPack!(context),
                  onCreate: widget.workshops == null
                      ? null
                      : () => _setSection(ResourceLibrarySection.workshops),
                  onRefresh: widget.onRefresh,
                  loadingMapUsages: widget.loadingMapUsages,
                ),
                const SizedBox(height: StudioSpacing.xxl),
                if (widget.showMapScopes) ...[
                  ResourceLibraryScopePanel(
                    maps: widget.maps,
                    mapId: _map,
                    onMap: (map) => _updateView(() => _referenceMap = map),
                    scope: _scope,
                    counts: {
                      for (final scope in ResourceLibraryScope.values)
                        scope: widget.items
                            .where((item) => _inScope(item, scope))
                            .length,
                    },
                    onScope: (scope) => _updateView(() => _scope = scope),
                  ),
                  const SizedBox(height: StudioSpacing.xxl),
                ],
                if (widget.showRoles) ...[
                  ResourceLibraryRoles(
                    role: _role,
                    onRole: (role) => _updateView(() {
                      _role = role;
                      _setCategory(null);
                    }),
                    families: {
                      for (final entry in widget.familyLabels.entries)
                        if (availableFamilies.contains(entry.key))
                          entry.key: entry.value,
                    },
                    family: _family,
                    onFamily: (family) => _updateView(() => _family = family),
                  ),
                  const SizedBox(height: StudioSpacing.xl),
                ],
                ResourceLibraryResultsHeading(
                  category: _category,
                  count: matches.length,
                  onCategory: sidebar
                      ? null
                      : (value) => _updateView(() => _setCategory(value)),
                  toolbar: ResourceLibraryToolbar(
                    search: _search,
                    searchFocus: _searchFocus,
                    onSearch: (_) => _updateView(() {}),
                    dimension: _dimension,
                    dimensionStatus: widget.dimensionStatus,
                    onDimension: (value) =>
                        _updateView(() => _dimension = value),
                    sort: _sort,
                    onSort: (value) => _updateView(() => _sort = value),
                    grid: _grid,
                    onGrid: (value) => _updateView(() => _grid = value),
                    detailsVisible:
                        docked && !_marking && _showDetails && selected != null,
                    onDetails: selected == null || _marking
                        ? null
                        : () {
                            if (docked) {
                              _updateView(() => _showDetails = !_showDetails);
                            } else {
                              _select(selected, docked: false);
                            }
                          },
                  ),
                ),
                if (organization != null) ...[
                  const SizedBox(height: StudioSpacing.m),
                  organization,
                ],
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: padding.copyWith(top: 0),
          sliver: matches.isEmpty
              ? const SliverToBoxAdapter(
                  child: StudioEmptyState(
                    title: 'Aucune ressource trouvée',
                    description:
                        'Essaie une autre recherche ou modifie les filtres.',
                  ),
                )
              : _grid
              ? SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 235,
                    mainAxisExtent: 210,
                    crossAxisSpacing: StudioSpacing.l,
                    mainAxisSpacing: StudioSpacing.l,
                  ),
                  itemCount: matches.length,
                  itemBuilder: (context, index) => tile(index),
                )
              : SliverList.separated(
                  itemCount: matches.length,
                  itemBuilder: (context, index) => tile(index),
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: StudioSpacing.m),
                ),
        ),
      ],
    );
  }
}
