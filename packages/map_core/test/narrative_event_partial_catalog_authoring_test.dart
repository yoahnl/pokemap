import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'support/narrative_event_authoring_fixtures.dart';

void main() {
  final remoteSources = [
    NarrativeEventSourceRef.mapEnter('remote'),
    NarrativeEventSourceRef.entityInteract('remote', 'npc'),
    NarrativeEventSourceRef.entityBump('remote', 'npc'),
    NarrativeEventSourceRef.entityAutorun('remote', 'npc'),
    NarrativeEventSourceRef.modelInteract('remote', 'model'),
    NarrativeEventSourceRef.triggerEnter('remote', 'trigger'),
    NarrativeEventSourceRef.triggerBump('remote', 'trigger'),
  ];

  for (final source in remoteSources) {
    test('unloaded ${source.kind.name} does not block an unrelated draft', () {
      final project = _project(
        source,
        dimension: source.kind == NarrativeEventSourceKind.modelInteract
            ? ProjectDimension.threeD
            : ProjectDimension.twoD,
      );
      final catalog = _catalog(project);
      final context = _context(project, catalog);
      final created = createNarrativeEventDraft(
        context: context,
        expectedRevision: catalog.manifestHash,
        name: 'Local draft',
        idGenerator: deterministicGenerator(eventIdB),
      );

      expect(created.status, NarrativeEventAuthoringStatus.applied);
      expect(
        created.nextRegistry!.records.first,
        project.eventRegistry!.records.first,
      );
      expect(created.nextRecord!.draftOrNull!.source, isNull);
      expect(catalog.hasBlockingDiagnostics, isFalse);
      expect(
        _sourceDiagnostic(catalog).severity,
        NarrativeEventProjectDiagnosticSeverity.warning,
      );
      expect(catalog.events.single.contextuallyValid, isFalse);
      expect(
        catalog.resolveSource(source).status,
        isNot(NarrativeEventProjectResolutionStatus.found),
      );

      final withSource = createNarrativeEventDraft(
        context: context,
        expectedRevision: catalog.manifestHash,
        name: 'Remote draft',
        initialSource: source,
        idGenerator: deterministicGenerator(eventIdB),
      );
      expect(withSource.status, NarrativeEventAuthoringStatus.rejected);
      expect(
        withSource.rejectionCode,
        anyOf('sourceMissing', 'sourceUnavailable'),
      );
    });
  }

  test('unloaded modelInteract stays blocking in a 2D project', () {
    final source = NarrativeEventSourceRef.modelInteract('remote', 'model');
    final project = _project(source);
    final catalog = _catalog(project);

    expect(catalog.nativeMaps.map((map) => map.id), isNot(contains('remote')));
    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(catalog.hasBlockingDiagnostics, isTrue);
    expect(catalog.events.single.contextuallyValid, isFalse);
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  test('unloaded triggerBump stays blocking in a 3D project', () {
    final source = NarrativeEventSourceRef.triggerBump('remote', 'trigger');
    final project = _project(source, dimension: ProjectDimension.threeD);
    final catalog = _catalog(project);

    expect(catalog.nativeMaps.map((map) => map.id), isNot(contains('remote')));
    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(catalog.hasBlockingDiagnostics, isTrue);
    expect(catalog.events.single.contextuallyValid, isFalse);
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  for (final source in [
    NarrativeEventSourceRef.entityBump('remote', 'npc'),
    NarrativeEventSourceRef.entityAutorun('remote', 'npc'),
  ]) {
    test('unloaded ${source.kind.name} stays blocking in a 3D project', () {
      final project = _project(source, dimension: ProjectDimension.threeD);
      final catalog = _catalog(project);

      expect(catalog.nativeMaps.map((map) => map.id), isNot(contains('remote')));
      expect(
        _sourceDiagnostic(catalog).severity,
        NarrativeEventProjectDiagnosticSeverity.error,
      );
      expect(catalog.hasBlockingDiagnostics, isTrue);
      expect(catalog.events.single.contextuallyValid, isFalse);
      expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
    });
  }

  test('publication still rejects an unloaded source in a partial catalog', () {
    final source = NarrativeEventSourceRef.mapEnter('remote');
    final draft = draftRecord(
      id: eventIdB,
      source: source,
      sceneId: 'scene_a',
      reusePolicy: NarrativeEventReusePolicy.reusable,
    );
    final project = _project(source, additionalRecords: [draft]);
    final catalog = _catalog(project);
    final publication = publishNarrativeEvent(
      context: _context(project, catalog),
      expectedRevision: catalog.manifestHash,
      eventId: eventIdB,
    );

    expect(publication.status, NarrativeEventAuthoringStatus.rejected);
    expect(publication.rejectionCode, 'sourceUnavailable');
    expect(project.eventRegistry!.records.last, draft);
  });

  test('complete inventory keeps missing map sources blocking', () {
    final project = _project(NarrativeEventSourceRef.mapEnter('remote'));
    final catalog = _catalog(project, complete: true);

    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(catalog.hasBlockingDiagnostics, isTrue);
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  test('partial inventory keeps missing owners on loaded maps blocking', () {
    final project = _project(
      NarrativeEventSourceRef.entityInteract('remote', 'absent'),
    );
    final catalog = _catalog(project, maps: [_map('local'), _map('remote')]);

    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  test('partial inventory keeps loaded unavailable sources blocking', () {
    final source = NarrativeEventSourceRef.entityInteract('remote', 'outside');
    final project = _project(source);
    final remote = _map('remote').copyWith(
      entities: const [
        MapEntity(
          id: 'outside',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 8, y: 8),
        ),
      ],
    );
    final catalog = _catalog(project, maps: [_map('local'), remote]);

    expect(
      catalog.resolveSource(source).status,
      NarrativeEventProjectResolutionStatus.unavailable,
    );
    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  test('simulation never handles an event with an unloaded source', () {
    final base = _project(NarrativeEventSourceRef.mapEnter('remote'));
    final project = base.copyWith(
      eventRegistry: registryWithRecords([
        configuredRecord(
          source: NarrativeEventSourceRef.mapEnter('remote'),
          enabled: true,
        ),
      ], mode: EventSystemMode.v2Only),
    );
    for (final complete in [false, true]) {
      final catalog = _catalog(project, complete: complete);
      final report = simulateNarrativeEventDispatch(
        registryResult: EventRegistryDecodeResult.decoded(
          project.eventRegistry!,
        ),
        projectCatalog: catalog,
        facts: project.facts,
        input: NarrativeEventSimulationInput(targetEventId: eventIdA),
        maps: [_map('local')],
        project: project,
      );

      expect(report.handledEventId, isNull);
      expect(report.status, isNot(NarrativeEventSimulationStatus.handled));
      if (complete) {
        expect(report.status, NarrativeEventSimulationStatus.authorityBlocked);
      }
    }
  });

  test('partial inventory keeps undeclared maps blocking', () {
    final project = _project(NarrativeEventSourceRef.mapEnter('undeclared'));
    final catalog = _catalog(project);

    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  test('partial inventory keeps duplicated manifest identities blocking', () {
    final base = _project(NarrativeEventSourceRef.mapEnter('remote'));
    final project = base.copyWith(maps: [...base.maps, base.maps.last]);
    final catalog = _catalog(project);

    expect(
      _sourceDiagnostic(catalog).severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(_create(project, catalog).rejectionCode, 'catalogBlocked');
  });

  test('proposed records still require a fully resolved source', () {
    final project = _project(NarrativeEventSourceRef.mapEnter('local'));
    final catalog = buildNarrativeEventProjectCatalog(
      project: project,
      maps: [_map('local')],
      mapInventoryComplete: false,
      proposedRecords: [
        configuredRecord(
          id: eventIdB,
          source: NarrativeEventSourceRef.mapEnter('remote'),
        ),
      ],
    );

    expect(
      catalog.diagnostics
          .singleWhere(
            (diagnostic) =>
                diagnostic.path == 'eventRegistry.records.$eventIdB.source',
          )
          .severity,
      NarrativeEventProjectDiagnosticSeverity.error,
    );
    expect(catalog.hasBlockingDiagnostics, isTrue);
  });

  test('loading the source map restores contextual validity', () {
    final source = NarrativeEventSourceRef.mapEnter('remote');
    final project = _project(source);
    final catalog = _catalog(project, maps: [_map('local'), _map('remote')]);

    expect(catalog.diagnostics, isEmpty);
    expect(catalog.events.single.contextuallyValid, isTrue);
    expect(
      catalog.resolveSource(source).status,
      NarrativeEventProjectResolutionStatus.found,
    );
    expect(
      _create(project, catalog).status,
      NarrativeEventAuthoringStatus.applied,
    );
  });
}

ProjectManifest _project(
  NarrativeEventSourceRef source, {
  List<NarrativeEventRecord> additionalRecords = const [],
  ProjectDimension dimension = ProjectDimension.twoD,
}) => ProjectManifest(
  name: 'Partial narrative catalog',
  settings: ProjectSettings(dimension: dimension),
  tilesets: const [],
  maps: const [
    ProjectMapEntry(
      id: 'local',
      name: 'Local',
      relativePath: 'maps/local.json',
    ),
    ProjectMapEntry(
      id: 'remote',
      name: 'Remote',
      relativePath: 'maps/remote.json',
    ),
  ],
  scenes: [sceneEntry().scene],
  eventRegistry: registryWithRecords([
    configuredRecord(source: source),
    ...additionalRecords,
  ]),
);

MapData _map(String id) => MapData(
  id: id,
  name: id,
  size: const GridSize(width: 4, height: 4),
  layers: const [],
);

NarrativeEventProjectCatalog _catalog(
  ProjectManifest project, {
  bool complete = false,
  List<MapData>? maps,
}) => buildNarrativeEventProjectCatalog(
  project: project,
  maps: maps ?? [_map('local')],
  mapInventoryComplete: complete,
);

NarrativeEventAuthoringContext _context(
  ProjectManifest project,
  NarrativeEventProjectCatalog catalog,
) => authoringContext(
  registry: project.eventRegistry,
  catalog: catalog,
  revision: catalog.manifestHash,
  manifestHash: catalog.manifestHash,
  mapHashes: catalog.mapHashes,
);

NarrativeEventProjectDiagnostic _sourceDiagnostic(
  NarrativeEventProjectCatalog catalog,
) => catalog.diagnostics.singleWhere(
  (diagnostic) => diagnostic.path == 'eventRegistry.records.$eventIdA.source',
);

NarrativeEventAuthoringResult _create(
  ProjectManifest project,
  NarrativeEventProjectCatalog catalog,
) => createNarrativeEventDraft(
  context: _context(project, catalog),
  expectedRevision: catalog.manifestHash,
  name: 'Local draft',
  idGenerator: deterministicGenerator(eventIdB),
);
