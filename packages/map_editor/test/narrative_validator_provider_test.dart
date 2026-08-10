import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/narrative_validator_isolate_executor.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/features/narrative/state/narrative_validator_providers.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:path/path.dart' as p;

void main() {
  test('default loader validates the current unsaved manifest snapshot',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_provider_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    const savedProject = ProjectManifest(
      name: 'Saved project',
      maps: [],
      tilesets: [],
    );
    await File(p.join(projectRoot.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(savedProject.toJson()),
    );
    final inMemoryProject = savedProject.copyWith(
      storylines: [
        StorylineAsset(
          id: 'story_unsaved',
          type: StorylineType.main,
          status: StorylineStatus.active,
          title: 'Unsaved storyline',
        ),
      ],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: inMemoryProject,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = narrativeValidatorReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final report = await container.read(provider.future);

    expect(
      report.byCode('storylineMissingBeginning').single.storylineId,
      'story_unsaved',
    );
    expect(report.isPlayable, isFalse);
    expect(
      report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
      hasLength(1),
    );
    expect(
      report.byCode('runtimePokemonMoveCatalogUnavailable'),
      hasLength(1),
    );
  });

  test('default loader replaces the saved map with the active map snapshot',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_active_map_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    const savedMap = MapData(
      id: 'map_live',
      name: 'Map live',
      size: GridSize(width: 8, height: 8),
      layers: [],
      entities: [
        MapEntity(
          id: 'npc_live',
          name: 'Live NPC',
          kind: MapEntityKind.npc,
          pos: GridPos(x: 2, y: 2),
        ),
      ],
    );
    final scene = SceneAsset(
      id: 'scene_live',
      name: 'Live Scene',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          SceneEdge(
            id: 'start_end',
            fromNodeId: 'start',
            fromPortId: 'completed',
            toNodeId: 'end',
            kind: SceneEdgeKind.defaultFlow,
          ),
        ],
      ),
    );
    const eventId = 'evt_019abcde-4000-7000-8000-000000000079';
    final project = ProjectManifest(
      name: 'Active map project',
      maps: const [
        ProjectMapEntry(
          id: 'map_live',
          name: 'Map live',
          relativePath: 'maps/map_live.json',
        ),
      ],
      tilesets: const [],
      scenes: [scene],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: EventSystemMode.v2Only,
        records: [
          NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: eventId,
              name: 'Live Event',
              source: NarrativeEventSourceRef.entityInteract(
                'map_live',
                'npc_live',
              ),
              conditions: const [],
              sceneId: 'scene_live',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const [],
      ),
    );
    await Directory(p.join(projectRoot.path, 'maps')).create();
    await File(p.join(projectRoot.path, 'project.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(project.toJson()),
    );
    await File(p.join(projectRoot.path, 'maps', 'map_live.json')).writeAsString(
      const JsonEncoder.withIndent('  ').convert(savedMap.toJson()),
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: project,
      activeMap: savedMap.copyWith(entities: const []),
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = narrativeValidatorReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final report = await container.read(provider.future);

    final entry = report.mapEventViews.single.events.single;
    expect(entry.eventId, eventId);
    expect(entry.sourceConnected, isFalse);
    expect(
      report.diagnostics.any(
        (diagnostic) =>
            diagnostic.eventId == eventId &&
            diagnostic.severity == NarrativeProjectDiagnosticSeverity.error,
      ),
      isTrue,
    );
  });

  test('snapshot fingerprint accepts nested trigger geometry', () {
    const project = ProjectManifest(
      name: 'Trigger fingerprint',
      maps: [],
      tilesets: [],
    );
    const activeMap = MapData(
      id: 'map_trigger',
      name: 'Trigger map',
      size: GridSize(width: 8, height: 8),
      layers: [],
      triggers: [
        MapTrigger(
          id: 'trigger_gate',
          type: TriggerType.event,
          area: MapRect(
            pos: GridPos(x: 2, y: 3),
            size: GridSize(width: 2, height: 1),
          ),
        ),
      ],
    );

    final first = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: project,
      activeMap: activeMap,
    );
    final equivalent = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: project,
      activeMap: MapData.fromJson(
        jsonDecode(jsonEncode(activeMap.toJson())) as Map<String, dynamic>,
      ),
    );

    expect(first, equivalent);
    expect(first.snapshotFingerprint, startsWith('sha256:'));
  });

  test('snapshot fingerprint ignores JSON object insertion order', () {
    final first = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: const ProjectManifest(
        name: 'Stable order',
        maps: [],
        tilesets: [],
        globalProperties: {
          'alpha': {
            'first': 1,
            'second': 2,
          },
          'omega': true,
        },
      ),
    );
    final reordered = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project',
      project: const ProjectManifest(
        name: 'Stable order',
        maps: [],
        tilesets: [],
        globalProperties: {
          'omega': true,
          'alpha': {
            'second': 2,
            'first': 1,
          },
        },
      ),
    );

    expect(reordered, first);
  });

  test('default loader validates Scene-only opponents against local catalogs',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_catalogs_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final map = _map();
    final project = _project(
      scenes: [_battleScene('trainer_unknown_catalog')],
      trainers: const [
        ProjectTrainerEntry(
          id: 'trainer_unknown_catalog',
          name: 'Dresseur inconnu',
          trainerClass: 'Trainer',
          team: [
            ProjectTrainerPokemonEntry(
              speciesId: 'missing_species',
              level: 5,
              moves: ['missing_move'],
            ),
          ],
        ),
      ],
    );
    await _writeProject(projectRoot, project, map);
    await const SeedPokemonDemoDataUseCase().execute(
      ProjectFileSystem(projectRoot.path),
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: project,
    );
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final provider = narrativeValidatorReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final report = await container.read(provider.future);

    expect(
      report.byCode('sceneBattleTrainerPokemonSpeciesUnknown'),
      hasLength(1),
    );
    expect(
      report.byCode('sceneBattleTrainerPokemonMoveUnknown'),
      hasLength(1),
    );
    expect(
      report.byCode('runtimePokemonSpeciesCatalogUnavailable'),
      isEmpty,
    );
    expect(report.byCode('runtimePokemonMoveCatalogUnavailable'), isEmpty);
  });

  test(
      'catalog refresh changes the fingerprint and does not reuse a stale report',
      () async {
    final projectRoot = await Directory.systemTemp.createTemp(
      'narrative_validator_catalog_refresh_',
    );
    addTearDown(() => projectRoot.delete(recursive: true));
    final map = _map();
    final project = _project(
      newGame: const ProjectNewGameConfig(
        starterOptions: [
          ProjectStarterOption(
            id: 'starter_refresh',
            label: 'Starter refresh',
            pokemon: PlayerPokemon(
              speciesId: 'bulbasaur',
              natureId: 'hardy',
              abilityId: 'overgrow',
              knownMoveIds: ['catalog_refresh_move'],
              level: 5,
              currentHp: 20,
            ),
          ),
        ],
      ),
    );
    await _writeProject(projectRoot, project, map);
    await const SeedPokemonDemoDataUseCase().execute(
      ProjectFileSystem(projectRoot.path),
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: projectRoot.path,
      project: project,
    );
    final catalogRequest =
        NarrativeValidatorPokemonCatalogRequest.fromValidationRequest(request);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final subscription = container.listen(
      narrativeValidatorReportProvider(request),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final firstReport = await container.read(
      narrativeValidatorReportProvider(request).future,
    );
    final firstSnapshot = await container.read(
      narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
    );
    expect(firstReport.byCode('runtimeMissingPokemonMove'), hasLength(1));

    final movesFile = File(
      p.join(
        projectRoot.path,
        project.pokemon.catalogFiles['moves']!,
      ),
    );
    final movesJson = (jsonDecode(await movesFile.readAsString()) as Map)
        .cast<String, dynamic>();
    (movesJson['entries'] as List).add(
      <String, dynamic>{'id': 'catalog_refresh_move', 'name': 'Refresh Move'},
    );
    await movesFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(movesJson),
    );

    container.invalidate(
      narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest),
    );
    container.invalidate(narrativeValidatorReportProvider(request));

    final secondReport = await container.read(
      narrativeValidatorReportProvider(request).future,
    );
    final secondSnapshot = await container.read(
      narrativeValidatorPokemonCatalogSnapshotProvider(catalogRequest).future,
    );

    expect(secondSnapshot.fingerprint, isNot(firstSnapshot.fingerprint));
    expect(secondReport.byCode('runtimeMissingPokemonMove'), isEmpty);
  });

  test('listener disposal cancels only its own in-flight validation', () async {
    final executor = _RecordingNarrativeValidatorExecutor();
    final container = ProviderContainer(
      overrides: [
        narrativeValidatorExecutorProvider.overrideWithValue(executor),
        narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
          (_) async => NarrativeValidatorPokemonCatalogSnapshot(
            speciesIds: const <String>{},
            moveIds: const <String>{},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectManifest(
      name: 'Lifecycle fixture',
      maps: [],
      tilesets: [],
    );
    final firstRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project-a',
      project: project,
    );
    final secondRequest = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/project-b',
      project: project,
    );

    final firstSubscription = container.listen(
      narrativeValidatorReportProvider(firstRequest),
      (_, _) {},
      fireImmediately: true,
    );
    await executor.waitForExecutions(1);
    final firstValidationId = executor.works.single.validationId;

    final secondSubscription = container.listen(
      narrativeValidatorReportProvider(secondRequest),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(secondSubscription.close);
    await executor.waitForExecutions(2);
    final secondValidationId = executor.works.last.validationId;
    expect(secondValidationId, isNot(firstValidationId));

    firstSubscription.close();
    await container.pump();

    expect(executor.cancelledValidationIds, [firstValidationId]);
    expect(
        executor.cancelledValidationIds, isNot(contains(secondValidationId)));
    executor.complete(
      secondValidationId,
      NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
      ),
    );
    await container.read(
      narrativeValidatorReportProvider(secondRequest).future,
    );
  });

  test('shared listeners coalesce and a same-frame resume stays alive',
      () async {
    final executor = _RecordingNarrativeValidatorExecutor();
    final container = ProviderContainer(
      overrides: [
        narrativeValidatorExecutorProvider.overrideWithValue(executor),
        narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
          (_) async => NarrativeValidatorPokemonCatalogSnapshot(
            speciesIds: const <String>{},
            moveIds: const <String>{},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectManifest(
      name: 'Coalescing fixture',
      maps: [],
      tilesets: [],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/coalescing',
      project: project,
    );
    final provider = narrativeValidatorReportProvider(request);

    final first = container.listen(provider, (_, _) {}, fireImmediately: true);
    final second =
        container.listen(provider, (_, _) {}, fireImmediately: true);
    await executor.waitForExecutions(1);
    expect(executor.works, hasLength(1));

    first.close();
    await container.pump();
    expect(executor.cancelledValidationIds, isEmpty);

    second.close();
    final resumed =
        container.listen(provider, (_, _) {}, fireImmediately: true);
    addTearDown(resumed.close);
    await container.pump();
    expect(executor.works, hasLength(1));
    expect(executor.cancelledValidationIds, isEmpty);

    final validationId = executor.works.single.validationId;
    executor.complete(
      validationId,
      NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
      ),
    );
    await container.read(provider.future);
  });

  test('invalidation cannot launch the disposed pre-refresh validation',
      () async {
    final catalogs = Completer<NarrativeValidatorPokemonCatalogSnapshot>();
    final executor = _RecordingNarrativeValidatorExecutor();
    final container = ProviderContainer(
      overrides: [
        narrativeValidatorExecutorProvider.overrideWithValue(executor),
        narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
          (_) => catalogs.future,
        ),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectManifest(
      name: 'Invalidation fixture',
      maps: [],
      tilesets: [],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/invalidation',
      project: project,
    );
    final provider = narrativeValidatorReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);
    await container.pump();

    container.invalidate(narrativeValidatorExecutionProvider(request));
    await container.pump();
    catalogs.complete(
      NarrativeValidatorPokemonCatalogSnapshot(
        speciesIds: const <String>{},
        moveIds: const <String>{},
      ),
    );

    await executor.waitForExecutions(1);
    await container.pump();
    expect(executor.works, hasLength(1));
    final validationId = executor.works.single.validationId;
    executor.complete(
      validationId,
      NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
      ),
    );
    await container.read(provider.future);
  });

  test('base report does not start the multidimensional phase', () async {
    final executor = _RecordingNarrativeValidatorExecutor();
    final container = ProviderContainer(
      overrides: [
        narrativeValidatorExecutorProvider.overrideWithValue(executor),
        narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
          (_) async => NarrativeValidatorPokemonCatalogSnapshot(
            speciesIds: const <String>{},
            moveIds: const <String>{},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectManifest(
      name: 'Base-only fixture',
      maps: [],
      tilesets: [],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/base-only',
      project: project,
    );

    final provider = narrativeValidatorReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final reportFuture = container.read(provider.future);
    await executor.waitForExecutions(1);
    final validationId = executor.works.single.validationId;
    executor.complete(
      validationId,
      NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
      ),
    );

    await reportFuture;
    expect(executor.works, hasLength(1));
    expect(
      executor.works.single.kind,
      NarrativeValidatorWorkKind.projectReport,
    );
  });

  test('multidimensional report reuses base then starts its own phase',
      () async {
    final executor = _RecordingNarrativeValidatorExecutor();
    final container = ProviderContainer(
      overrides: [
        narrativeValidatorExecutorProvider.overrideWithValue(executor),
        narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
          (_) async => NarrativeValidatorPokemonCatalogSnapshot(
            speciesIds: const <String>{},
            moveIds: const <String>{},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectManifest(
      name: 'Multidimensional fixture',
      maps: [],
      tilesets: [],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/multidimensional',
      project: project,
    );

    final provider = narrativeStudioValidationReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final reportFuture = container.read(provider.future);
    await executor.waitForExecutions(1);
    executor.complete(
      executor.works.first.validationId,
      NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
      ),
    );
    await executor.waitForExecutions(2);
    executor.completeMultidimensional(executor.works.last.validationId);

    expect((await reportFuture).overallStatus, NarrativeValidationStatus.pass);
    expect(
      executor.works.map((work) => work.kind),
      [
        NarrativeValidatorWorkKind.projectReport,
        NarrativeValidatorWorkKind.multidimensionalReport,
      ],
    );
  });

  test('multidimensional failure leaves the completed base report available',
      () async {
    final executor = _RecordingNarrativeValidatorExecutor();
    final container = ProviderContainer(
      overrides: [
        narrativeValidatorExecutorProvider.overrideWithValue(executor),
        narrativeValidatorPokemonCatalogLoaderProvider.overrideWithValue(
          (_) async => NarrativeValidatorPokemonCatalogSnapshot(
            speciesIds: const <String>{},
            moveIds: const <String>{},
          ),
        ),
      ],
    );
    addTearDown(container.dispose);
    const project = ProjectManifest(
      name: 'Partial failure fixture',
      maps: [],
      tilesets: [],
    );
    final request = NarrativeValidatorSnapshotRequest.fromProject(
      projectRootPath: '/virtual/partial-failure',
      project: project,
    );

    final baseProvider = narrativeValidatorReportProvider(request);
    final baseSubscription = container.listen(
      baseProvider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(baseSubscription.close);
    final provider = narrativeStudioValidationReportProvider(request);
    final subscription = container.listen(
      provider,
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final multidimensionalFuture = container.read(provider.future);
    final baseFuture = container.read(baseProvider.future);
    await executor.waitForExecutions(1);
    executor.complete(
      executor.works.first.validationId,
      NarrativeProjectValidationReport(
        diagnostics: const [],
        mapEventViews: const [],
      ),
    );
    final baseReport = await baseFuture;
    await executor.waitForExecutions(2);
    executor.fail(
      executor.works.last.validationId,
      const NarrativeValidatorWorkerException(
        message: 'publication failed',
        workerStackTrace: 'worker stack',
      ),
    );

    expect(baseReport.diagnostics, isEmpty);
    await expectLater(
      multidimensionalFuture,
      throwsA(isA<NarrativeValidatorWorkerException>()),
    );
  });
}

final class _RecordingNarrativeValidatorExecutor
    implements NarrativeValidatorExecutor {
  final List<NarrativeValidatorWork> works = [];
  final List<String> cancelledValidationIds = [];
  final Map<String, Completer<NarrativeValidatorExecutionResult>> _completers =
      {};
  Completer<void> _executionChanged = Completer<void>();

  @override
  Future<NarrativeValidatorExecutionResult> execute(
    NarrativeValidatorWork work,
  ) {
    works.add(work);
    final completer = Completer<NarrativeValidatorExecutionResult>();
    _completers[work.validationId] = completer;
    _executionChanged.complete();
    _executionChanged = Completer<void>();
    return completer.future;
  }

  Future<void> waitForExecutions(int count) async {
    while (works.length < count) {
      await _executionChanged.future;
    }
  }

  void complete(
    String validationId,
    NarrativeProjectValidationReport report,
  ) {
    _completers[validationId]!.complete(
      NarrativeValidatorExecutionResult(
        validationId: validationId,
        report: report,
        workerIsolateDebugName: 'fake-worker',
        workerControlPort: null,
      ),
    );
  }

  void completeMultidimensional(String validationId) {
    _completers[validationId]!.complete(
      NarrativeValidatorExecutionResult(
        validationId: validationId,
        multidimensionalReport: _testMultidimensionalReport(),
        workerIsolateDebugName: 'fake-worker',
        workerControlPort: null,
      ),
    );
  }

  void fail(String validationId, Object error) {
    _completers[validationId]!.completeError(error, StackTrace.current);
  }

  @override
  void cancel(
    String validationId, {
    NarrativeValidatorCancellationReason reason =
        NarrativeValidatorCancellationReason.providerDisposed,
  }) {
    cancelledValidationIds.add(validationId);
  }

  @override
  void dispose() {}
}

NarrativeMultidimensionalValidationReport _testMultidimensionalReport() {
  final pass = NarrativeValidationDimensionResult(
    status: NarrativeValidationStatus.pass,
  );
  return NarrativeMultidimensionalValidationReport(
    validatorVersion: 'test-validator',
    profileId: 'test-profile',
    profileVersion: 1,
    projectFingerprint: 'sha256:test',
    generatedAt: DateTime.utc(2026),
    structurallyValid: pass,
    narrativelySolvable: pass,
    physicallyReachable: pass,
    runtimeSmokeVerified: pass,
  );
}

const _mapId = 'map_catalog_validation';

MapData _map() => const MapData(
      id: _mapId,
      name: 'Catalog validation map',
      size: GridSize(width: 8, height: 8),
      layers: [],
      entities: [
        MapEntity(
          id: 'spawn_player',
          name: 'Player start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 1, y: 1),
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
        ),
      ],
    );

ProjectManifest _project({
  List<SceneAsset> scenes = const [],
  List<ProjectTrainerEntry> trainers = const [],
  ProjectNewGameConfig newGame = const ProjectNewGameConfig(),
}) {
  return ProjectManifest(
    name: 'Catalog validation project',
    maps: const [
      ProjectMapEntry(
        id: _mapId,
        name: 'Catalog validation map',
        relativePath: 'maps/map_catalog_validation.json',
      ),
    ],
    tilesets: const [],
    scenes: scenes,
    trainers: trainers,
    newGame: newGame,
  );
}

SceneAsset _battleScene(String trainerId) {
  return SceneAsset(
    id: 'scene_battle',
    name: 'Catalog battle',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'battle',
          kind: SceneNodeKind.battle,
          payload: SceneBattlePayload(
            battleKind: 'trainer',
            trainerId: trainerId,
          ),
        ),
        SceneNode(id: 'end_victory', kind: SceneNodeKind.end),
        SceneNode(id: 'end_defeat', kind: SceneNodeKind.end),
      ],
      edges: [
        SceneEdge(
          id: 'start_battle',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'battle',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'battle_victory',
          fromNodeId: 'battle',
          fromPortId: 'victory',
          toNodeId: 'end_victory',
          kind: SceneEdgeKind.battleVictory,
        ),
        SceneEdge(
          id: 'battle_defeat',
          fromNodeId: 'battle',
          fromPortId: 'defeat',
          toNodeId: 'end_defeat',
          kind: SceneEdgeKind.battleDefeat,
        ),
      ],
    ),
  );
}

Future<void> _writeProject(
  Directory projectRoot,
  ProjectManifest project,
  MapData map,
) async {
  await Directory(p.join(projectRoot.path, 'maps')).create(recursive: true);
  await File(p.join(projectRoot.path, 'project.json')).writeAsString(
    const JsonEncoder.withIndent('  ').convert(project.toJson()),
  );
  await File(p.join(projectRoot.path, 'maps', 'map_catalog_validation.json'))
      .writeAsString(
    const JsonEncoder.withIndent('  ').convert(map.toJson()),
  );
}
