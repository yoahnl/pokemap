part of 'project_library_page.dart';

extension _ProjectLibraryNavigation on _ProjectLibraryPageState {
  ResourceLibraryNavigation _libraryNavigation(_ProjectLibraryRead read) {
    final maps = widget.maps;
    final port = maps.port;
    final revision = read.revision;
    return (
      revision: revision,
      mapUsagesReady: read.withUsages,
      item: (id) => (read.enriched ?? read.catalog).item(id),
      openMap: widget.onOpenMap,
      loadRelations:
          port is ProjectResourceLibraryRelationsPort && revision != null
          ? (identity) => _loadLibraryRelations(
              port as ProjectResourceLibraryRelationsPort,
              read,
              identity,
              revision,
            )
          : null,
    );
  }

  Future<ResourceLibraryRelationsView?> _loadLibraryRelations(
    ProjectResourceLibraryRelationsPort port,
    _ProjectLibraryRead read,
    String identity,
    String revision,
  ) async {
    final library = _reading;
    final item = read.catalog.entries[identity];
    if (item == null || read.revision != revision) return null;
    final relations = await port.readResourceLibraryRelations(
      widget.maps.session,
      item.kind,
      item.id,
      revision: revision,
    );
    if (!mounted ||
        _reading != library ||
        read.revision != revision ||
        relations == null) {
      return null;
    }
    final catalog = read.enriched ?? read.catalog;
    List<ResourceLibraryItemView> resolve(Set<String> ids) =>
        [for (final id in ids) ?catalog.item(id)]
          ..sort((a, b) => a.name.compareTo(b.name));
    return (
      sources: resolve(relations.sources),
      consumers: relations.consumers == null
          ? null
          : resolve(relations.consumers!),
    );
  }
}
