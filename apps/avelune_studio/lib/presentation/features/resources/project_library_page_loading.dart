part of 'project_library_page.dart';

extension _ProjectLibraryPageLoading on _ProjectLibraryPageState {
  Future<ProjectResourceLibrary> _queryLibrary(
    MapWorkspaceController maps,
    ProjectManifest manifest,
  ) => switch (maps.port) {
    final ProjectResourceLibraryDimensionsPort reader =>
      reader.readResourceLibraryIndex(maps.session),
    final ProjectResourceLibraryPort reader => reader.readResourceLibrary(
      maps.session,
    ),
    _ when maps.hasCompleteProject => Future.value(
      ProjectResourceLibrary.fromManifest(manifest),
    ),
    _ => Future.error(StateError('Lecteur de bibliothèque indisponible.')),
  };

  Future<void> _withDimensions(
    ProjectResourceLibraryDimensionsPort reader,
    ProjectSession session,
    _ProjectLibraryRead read,
    bool Function() isCurrent,
  ) async {
    while (isCurrent()) {
      final revision = read.revision;
      if (revision == null) return;
      Map<String, Set<ProjectDimension>>? dimensions;
      try {
        dimensions = await reader.readResourceLibraryDimensions(
          session,
          revision: revision,
        );
      } on Object {
        if (read.revision == revision) return;
      }
      if (!isCurrent()) return;
      if (dimensions != null) {
        read.catalog.applyDimensions(dimensions);
        read.enriched?.applyDimensions(dimensions);
        read.dimensionsReady = true;
        return;
      }
      if (read.revision == revision) return;
    }
  }

  Future<void> _withUsages(
    ProjectResourceLibraryMapUsagesPort reader,
    ProjectSession session,
    ProjectResourceLibrary library,
    String revision,
    _ProjectLibraryRead read,
  ) async {
    try {
      final usages = await reader.readResourceLibraryMapUsages(
        session,
        revision: revision,
        identities: [for (final item in library.items) item.identity],
      );
      if (usages == null) return;
      read.enriched = ProjectLibraryCatalogView(
        ProjectResourceLibrary(read.catalog.metadata, const []),
        mapUsages: usages,
        items: read.catalog.entries.values,
      );
    } catch (_) {}
  }
}

class _ProjectLibraryRead {
  _ProjectLibraryRead(ProjectResourceLibrary library, this.previews)
    : catalog = ProjectLibraryCatalogView(library),
      revision = library.revision;

  final ProjectLibraryCatalogView catalog;
  final ProjectResourcePreviews previews;
  ProjectLibraryCatalogView? enriched;
  Future<void>? withUsages;
  Future<void>? withDimensions;
  bool dimensionsReady = false;
  String? revision;
  ResourceLibraryPublication? publication;

  ResourceLibraryDimensionStatus dimensionStatus(ConnectionState state) =>
      switch ((withDimensions, dimensionsReady, state)) {
        (null, _, _) || (_, true, _) => ResourceLibraryDimensionStatus.ready,
        (_, _, ConnectionState.done) =>
          ResourceLibraryDimensionStatus.unavailable,
        _ => ResourceLibraryDimensionStatus.loading,
      };

  ResourceLibraryItemView publish(
    ProjectLibraryEdit edit, {
    required bool imported,
  }) {
    revision = edit.receipt.revision;
    final base = catalog.upsert(edit.item);
    final item = enriched?.upsert(edit.item) ?? base;
    publication = (
      item: item,
      token: (publication?.token ?? 0) + 1,
      imported: imported,
    );
    return item;
  }
}
