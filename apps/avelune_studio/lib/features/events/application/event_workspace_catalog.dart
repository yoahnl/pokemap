part of 'event_workspace_controller.dart';

extension EventWorkspaceCatalog on EventWorkspaceController {
  bool get prepared => _preparedManifest == narrative.project;
  List<MapData> get maps => [
    for (final entry in narrative.project.maps)
      if (workspace.documents[entry.id]?.current ?? _maps[entry.id]
          case final MapData map)
        map,
  ];
  bool get mapsComplete {
    final loaded = maps.map((map) => map.id).toSet();
    return project.maps.every((entry) => loaded.contains(entry.id));
  }

  void acceptMap(MapData map) {
    if (_closed) return;
    _maps[map.id] = map;
    _cachedContext = null;
  }

  Future<MapData> loadMap(String id) async {
    final open = workspace.documents[id]?.current;
    if (open != null) return open;
    final cached = _maps[id];
    if (cached != null) return cached;
    return _mapLoads.putIfAbsent(id, () async {
      try {
        final entries = project.maps.where((entry) => entry.id == id).toList();
        if (entries.length != 1) {
          throw const EventFailure('Cette carte est absente ou ambiguë.');
        }
        final loaded = await workspace.port.loadMap(
          workspace.session,
          entries.single,
        );
        if (!_closed) acceptMap(loaded.map);
        return loaded.map;
      } finally {
        _mapLoads.remove(id);
      }
    });
  }

  Future<bool> prepare({Iterable<String> mapIds = const []}) {
    final source = active?.source;
    final sourceMapId = source?.when<String?>(
      entityInteract: (map, _) => map,
      entityBump: (map, _) => map,
      entityAutorun: (map, _) => map,
      modelInteract: (map, _) => map,
      triggerBump: (map, _) => map,
      triggerEnter: (map, _) => map,
      mapEnter: (map) => map,
      outcomeReceived: (_) => null,
    );
    final requested = {...mapIds, ?sourceMapId};
    final previous = _preparing;
    late final Future<bool> operation;
    operation = (previous ?? Future.value(true))
        .then((_) => _prepare(requested))
        .whenComplete(() {
          if (identical(_preparing, operation)) _preparing = null;
        });
    _preparing = operation;
    return operation;
  }

  Future<bool> prepareAllMaps() =>
      prepare(mapIds: project.maps.map((entry) => entry.id));

  Future<bool> _prepare(Set<String> mapIds) async {
    if (_closed) return false;
    try {
      await workspace.ensureWorkshop(MapWorkspaceWorkshop.events);
      if (_closed) return false;
      final manifest = narrative.project;
      final gateway = port;
      final mediaCatalog = _preparedManifest == manifest
          ? _presentationMediaCatalog
          : gateway is EventPresentationCatalogPort
          ? await (gateway as EventPresentationCatalogPort)
                .loadPresentationMediaCatalog(manifest)
          : null;
      if (_closed) {
        return false;
      }
      if (manifest != narrative.project) {
        return _fail(
          'Le projet a changé pendant le chargement de la médiathèque. Réessayez.',
        );
      }
      _presentationMediaCatalog = mediaCatalog;
      for (final id in mapIds) {
        if (_closed) return false;
        await loadMap(id);
      }
      if (_closed) return false;
      if (manifest != narrative.project) {
        return _fail(
          'Le projet a changé pendant le chargement du catalogue. Réessayez.',
        );
      }
      _preparedManifest = manifest;
      error = null;
      changed();
      return true;
    } catch (failure) {
      _presentationMediaCatalog = null;
      _preparedManifest = null;
      _cachedContext = null;
      if (!_closed) _fail(failure.toString());
      return false;
    }
  }

  NarrativeEventAuthoringContext get context {
    final signature = <Object?>[
      narrative.project,
      _presentationMediaCatalog,
      ..._pending.entries.map((e) => (e.key, e.value)),
      ...narrative.facts,
      ...narrative.stories,
      ...?sceneDrafts?.call(),
      ...maps,
    ];
    if (_cachedContext != null &&
        signature.length == _catalogSignature.length &&
        Iterable<int>.generate(signature.length)
            .every((i) => signature[i] == _catalogSignature[i])) {
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
      mapInventoryComplete: mapsComplete,
      presentationMediaCatalog: _presentationMediaCatalog,
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
    if (!prepared || !mapsComplete) {
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
      maps: maps,
      project: project,
      legacyClaimIndex: registry?.mode == EventSystemMode.dualRead
          ? buildValidatedLegacyClaimIndex(registry!)
          : null,
    );
  }
}
