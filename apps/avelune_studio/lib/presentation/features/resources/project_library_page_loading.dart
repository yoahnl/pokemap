part of 'project_library_page.dart';

extension _ProjectLibraryPageLoading on _ProjectLibraryPageState {
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
