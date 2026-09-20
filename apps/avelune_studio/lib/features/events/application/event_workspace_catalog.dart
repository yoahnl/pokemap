part of 'event_workspace_controller.dart';

extension EventWorkspaceCatalog on EventWorkspaceController {
  bool get prepared => _preparedManifest == narrative.project;
  List<MapData> get maps => [
    for (final entry in narrative.project.maps)
      if (workspace.documents[entry.id]?.current ?? _maps[entry.id]
          case final MapData map)
        map,
  ];
  Future<bool> prepare() =>
      _preparing ??= _prepare().whenComplete(() => _preparing = null);
  Future<bool> _prepare() async {
    if (_closed) return false;
    final manifest = narrative.project;
    if (_preparedManifest == manifest) return true;
    try {
      final loaded = <String, MapData>{};
      for (final entry in manifest.maps) {
        if (_closed) return false;
        final open = workspace.documents[entry.id];
        loaded[entry.id] =
            open?.current ??
            (await workspace.port.loadMap(workspace.session, entry)).map;
      }
      if (_closed) return false;
      if (manifest != narrative.project) {
        return _fail(
          'Le projet a changé pendant le chargement du catalogue. Réessayez.',
        );
      }
      _maps
        ..clear()
        ..addAll(loaded);
      _preparedManifest = manifest;
      error = null;
      changed();
      return true;
    } catch (failure) {
      if (!_closed) _fail(failure.toString());
      return false;
    }
  }

  NarrativeEventAuthoringContext get context {
    final signature = <Object?>[
      narrative.project,
      ..._pending.entries.map((e) => (e.key, e.value)),
      ...narrative.facts,
      ...narrative.stories,
      ...?sceneDrafts?.call(),
      ...maps,
    ];
    if (_cachedContext != null &&
        signature.length == _catalogSignature.length &&
        Iterable<int>.generate(
          signature.length,
        ).every((i) => signature[i] == _catalogSignature[i])) {
      return _cachedContext!;
    }
    _catalogSignature = signature;
    return _cachedContext = _context(project);
  }

  NarrativeEventProjectCatalog get catalog => context.catalog;
  NarrativeEventAuthoringContext _context(ProjectManifest value) {
    final registry = value.eventRegistry;
    final catalog = buildNarrativeEventProjectCatalog(
      project: value,
      maps: maps,
    );
    return NarrativeEventAuthoringContext(
      registryState: registry == null
          ? EventRegistryDecodeResult.absent()
          : EventRegistryDecodeResult.decoded(registry),
      revision: catalog.manifestHash,
      catalog: catalog,
      sourceIndex: buildNarrativeEventSourceIndex(
        registry?.records ?? const [],
      ),
      manifestHash: catalog.manifestHash,
      mapHashes: catalog.mapHashes,
    );
  }

  NarrativeEventSimulationReport simulation(
    NarrativeEventSimulationInput input,
  ) {
    if (!prepared) {
      throw const EventFailure(
        'Chargez le catalogue complet avant la simulation.',
      );
    }
    final snapshot = context;
    final registry = snapshot.registryOrNull;
    return simulateNarrativeEventDispatch(
      registryResult: snapshot.registryState,
      projectCatalog: snapshot.catalog,
      facts: project.facts,
      input: input,
      legacyClaimIndex: registry?.mode == EventSystemMode.dualRead
          ? buildValidatedLegacyClaimIndex(registry!)
          : null,
    );
  }
}
