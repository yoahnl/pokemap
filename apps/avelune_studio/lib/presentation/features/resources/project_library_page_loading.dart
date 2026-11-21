part of 'project_library_page.dart';

extension _ProjectLibraryPageLoading on _ProjectLibraryPageState {
  void _read({
    ProjectResourceLibrary? library,
    String? revealIdentity,
    int publicationToken = 1,
  }) {
    final maps = widget.maps;
    final manifest = maps.project;
    if (manifest == null) return;
    final port = maps.port;
    final complete = maps.hasCompleteProject;
    final previews = ProjectResourcePreviews(
      (entry) => switch (port) {
        _ when complete => Future.value(maps.project ?? manifest),
        final ProjectResourcePreviewPort reader => reader.readResourcePreview(
          maps.session,
          entry.kind,
          entry.id,
        ),
        _ => Future.error(StateError('Lecteur d’aperçu indisponible.')),
      },
    );
    final result = library == null
        ? _queryLibrary(maps, manifest)
        : Future.value(library);
    late final Future<_ProjectLibraryRead> reading;
    bool isCurrent() => mounted && identical(_reading, reading);
    reading = result.then((library) {
      final revision = library.revision;
      final read = _ProjectLibraryRead(library, previews);
      final item = revealIdentity == null
          ? null
          : read.catalog.item(revealIdentity);
      if (item != null) {
        read.publication = (
          item: item,
          token: publicationToken,
          imported: true,
        );
      }
      if (revision != null && isCurrent()) {
        if (port case final ProjectResourceLibraryDimensionsPort reader) {
          read.withDimensions = _withDimensions(
            reader,
            maps.session,
            read,
            isCurrent,
          );
        }
        if (port case final ProjectResourceLibraryMapUsagesPort reader) {
          read.withUsages = _withUsages(
            reader,
            maps.session,
            library,
            revision,
            read,
          );
        }
      }
      return read;
    });
    _reading = reading;
  }

  void _refresh() {
    if (widget.visuals case final ScopedResourcePreviewVisuals previews) {
      previews.refreshResourcePreviews();
    }
    _updateView(_read);
  }

  Future<void> _refreshIfRevisionChanged() async {
    final reading = _reading;
    final maps = widget.maps;
    final port = maps.port;
    if (reading == null ||
        port is! ProjectResourceLibraryRevisionPort ||
        _workshopBusy ||
        _workshopHasDraft) {
      return;
    }
    final check = Object();
    _revisionCheck = check;
    bool current() =>
        mounted &&
        widget.active &&
        identical(_revisionCheck, check) &&
        identical(widget.maps, maps) &&
        identical(_reading, reading) &&
        !_workshopBusy &&
        !_workshopHasDraft;
    try {
      final read = await reading;
      final knownRevision = read.revision;
      if (!current() || knownRevision == null) return;
      final revision = await (port as ProjectResourceLibraryRevisionPort)
          .readResourceLibraryRevision(maps.session);
      if (current() &&
          knownRevision == read.revision &&
          revision != knownRevision) {
        _updateView(_read);
      }
    } on Object {
      return;
    } finally {
      if (mounted && identical(_revisionCheck, check)) {
        _updateView(() => _revisionCheck = null);
      }
    }
  }

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
