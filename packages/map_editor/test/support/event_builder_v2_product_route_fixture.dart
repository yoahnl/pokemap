import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/narrative_event_authoring_session.dart';
import 'package:map_editor/src/application/models/narrative_event_spatial_link_journal_models.dart';
import 'package:map_editor/src/application/ports/narrative_event_registry_persistence_gateway.dart';
import 'package:map_editor/src/application/ports/narrative_event_spatial_source_creation_gateway.dart';
import 'package:map_editor/src/app/providers/core/repository_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/presentation/world_map/world_map_target_editor_navigation.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_builder_v2_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_map_bridge_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_event_validation_state.dart';
import 'package:map_editor/src/infrastructure/repositories/narrative_event_spatial_link_journal_repository.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/canvas/editor_canvas_host.dart';
import 'package:path/path.dart' as p;

import '../shell_chrome_test_harness.dart';

const productRoutePortEventId = 'evt_00000000-0000-7000-8000-000000000201';
const productRouteForestEventId = 'evt_00000000-0000-7000-8000-000000000202';
const productRouteDraftEventId = 'evt_00000000-0000-7000-8000-000000000203';
const productRouteMissingEventId = 'evt_00000000-0000-7000-8000-000000000204';
const productRouteOutcomeEventId = 'evt_00000000-0000-7000-8000-000000000205';
const productRouteRivalRematchEventId =
    'evt_00000000-0000-7000-8000-000000000206';

/// Real on-disk project snapshot used by H1/H2 route tests.
///
/// Keeping this fixture on disk is intentional: a synthetic read model would
/// only re-test the Phase K harness and could not prove that the product route
/// reads every map from one attested authoring session.
final class EventBuilderV2ProductRouteFixture {
  EventBuilderV2ProductRouteFixture._({
    required this.root,
    required this.projectPath,
    required this.project,
    required this.portMap,
    required this.forestMap,
    required this.readModel,
  });

  final Directory root;
  final String projectPath;
  final ProjectManifest project;
  final MapData portMap;
  final MapData forestMap;
  final NarrativeEventBuilderProjectReadModel readModel;

  static Future<EventBuilderV2ProductRouteFixture> create({
    required EventSystemMode mode,
  }) async {
    final root = await Directory.systemTemp.createTemp(
      'pokemap_event_v2_product_route_',
    );
    final portMap = _map(
      id: 'map_port',
      name: 'Port Selbrume',
      entityId: 'npc_rival',
      entityName: 'Rival',
      legacyEvent: const MapEventDefinition(
        id: 'legacy_port',
        title: 'Ancienne rumeur au port',
        pages: [
          MapEventPage(
            pageNumber: 0,
            sceneTarget: MapEventSceneTarget(sceneId: 'scene_action'),
          ),
        ],
        position: EventPosition(layerId: 'events', x: 1, y: 1),
      ),
    );
    final forestMap = _map(
      id: 'map_forest',
      name: 'Forêt Brumeuse',
      entityId: 'npc_spirit',
      entityName: 'Esprit de la forêt',
    );
    final project = ProjectManifest(
      name: 'Selbrume Route Test',
      maps: const [
        ProjectMapEntry(
          id: 'map_port',
          name: 'Port Selbrume',
          relativePath: 'maps/port.json',
        ),
        ProjectMapEntry(
          id: 'map_forest',
          name: 'Forêt Brumeuse',
          relativePath: 'maps/forest.json',
        ),
      ],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'fact_port_open',
          label: 'Le port est ouvert',
        ),
        NarrativeFactDefinition(
          id: 'fact_rival_defeated',
          label: 'Rival battu',
        ),
      ],
      scenes: [_scene('scene_action', 'Rencontre'), _rivalScene()],
      worldRules: [
        WorldRuleDefinition(
          id: 'world_rule_rival_leaves_port',
          label: 'Le rival quitte le port',
          source: const WorldRuleSource(
            kind: WorldRuleSourceKind.fact,
            sourceId: 'fact_rival_defeated',
            predicate: WorldRuleSourcePredicate.isTrue,
            label: 'Rival battu',
          ),
          target: const WorldRuleTarget(
            kind: WorldRuleTargetKind.mapEntity,
            mapId: 'map_port',
            entityId: 'npc_rival',
            label: 'Rival',
          ),
          effect: const WorldRuleEffect(
            kind: WorldRuleEffectKind.entityHidden,
            label: 'Masquer le Rival',
          ),
        ),
      ],
      eventRegistry: NarrativeEventRegistry(
        schemaVersion: 1,
        mode: mode,
        records: [
          _configured(
            productRoutePortEventId,
            'Rencontre rival au port',
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_rival'),
            enabled: true,
            sceneId: 'scene_rival',
            priority: 10,
            order: 0,
            conditions: [
              NarrativeEventCondition.fact('fact_port_open', true),
              NarrativeEventCondition.narrativeEventConsumed(
                productRouteForestEventId,
                false,
              ),
            ],
          ),
          _configured(
            productRouteForestEventId,
            'Écho dans la brume',
            NarrativeEventSourceRef.entityInteract('map_forest', 'npc_spirit'),
            enabled: false,
          ),
          _configured(
            productRouteRivalRematchEventId,
            'Revanche du rival',
            NarrativeEventSourceRef.entityInteract('map_port', 'npc_rival'),
            enabled: true,
            priority: 0,
            order: 1,
          ),
          _draft(productRouteDraftEventId, 'Événement à préparer'),
          _draft(
            productRouteMissingEventId,
            'Objet disparu',
            source: NarrativeEventSourceRef.entityInteract(
              'map_port',
              'npc_absent',
            ),
          ),
          _configured(
            productRouteOutcomeEventId,
            'Après la victoire',
            NarrativeEventSourceRef.outcomeReceived(
              NarrativeOutcomeRef(
                producerKind: NarrativeOutcomeProducerKind.scene,
                producerId: 'scene_rival',
                outcomeId: 'victory',
              ),
            ),
            enabled: true,
          ),
        ],
        legacyClaims: const [],
      ),
    );
    final projectPath = p.join(root.path, 'project.json');
    await _writeJson(File(projectPath), project.toJson());
    await _writeJson(
      File(p.join(root.path, 'maps', 'port.json')),
      portMap.toJson(),
    );
    await _writeJson(
      File(p.join(root.path, 'maps', 'forest.json')),
      forestMap.toJson(),
    );
    final session = await NarrativeEventAuthoringSession.prepare(projectPath);
    final readModel = buildNarrativeEventBuilderProjectReadModel(
      project: session.manifest,
      maps: session.maps,
    );
    return EventBuilderV2ProductRouteFixture._(
      root: root,
      projectPath: projectPath,
      project: project,
      portMap: portMap,
      forestMap: forestMap,
      readModel: readModel,
    );
  }

  Future<void> dispose() async {
    if (await root.exists()) await root.delete(recursive: true);
  }
}

Future<EventBuilderV2ProductRouteFixture>
createEventBuilderV2ProductRouteFixture(
  WidgetTester tester, {
  required EventSystemMode mode,
}) async {
  final fixture = await tester.runAsync(
    () => EventBuilderV2ProductRouteFixture.create(mode: mode),
  );
  if (fixture == null) {
    throw TestFailure('The on-disk Event Builder fixture was not created.');
  }
  addTearDown(() => tester.runAsync(fixture.dispose));
  return fixture;
}

Future<ProviderContainer> pumpEventBuilderV2ProductRoute(
  WidgetTester tester, {
  required EventBuilderV2ProductRouteFixture fixture,
  MapData? activeMap,
  Size viewport = const Size(1672, 941),
  String? fontFamily,
  LoadNarrativeEventBuilderV2ReadModel? readModelLoader,
  LoadNarrativeEventValidationSnapshot? validationLoader,
  NarrativeEventRegistryPersistenceGateway? persistenceGateway,
  String? pendingCompatibilityStableKey,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final container = ProviderContainer(
    overrides: [
      // Widget tests run in FakeAsync. The fixture above already passed the
      // production attested-session loader in real async, so the UI receives
      // that exact read model through the replaceable I/O seam.
      narrativeEventBuilderV2ReadModelLoaderProvider.overrideWithValue(
        readModelLoader ?? (_) => Future.value(fixture.readModel),
      ),
      narrativeEventValidationSnapshotLoaderProvider.overrideWithValue(
        validationLoader ??
            (_) => Future.value(
              buildEventBuilderV2ProductRouteValidationSnapshot(fixture),
            ),
      ),
      if (persistenceGateway != null)
        narrativeEventRegistryPersistenceGatewayProvider.overrideWithValue(
          persistenceGateway,
        ),
      narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
        _InitialClearSourceCreationGateway(
          NarrativeEventSpatialLinkJournalRepository(),
        ),
      ),
    ],
  );
  addTearDown(container.dispose);
  final subscription = container.listen(editorNotifierProvider, (_, _) {});
  addTearDown(subscription.close);

  container.read(editorNotifierProvider.notifier).state = EditorState(
    projectRootPath: fixture.root.path,
    project: fixture.project,
    workspaceMode: EditorWorkspaceMode.events,
    activeMap: activeMap ?? fixture.portMap,
    activeLayerId: 'events',
  );
  if (pendingCompatibilityStableKey != null) {
    container
        .read(worldMapTargetEditorNavigationProvider.notifier)
        .enqueue(pendingCompatibilityStableKey);
  }

  final baseTheme = PokeMapTheme.dark();
  final theme = fontFamily == null
      ? baseTheme
      : baseTheme.copyWith(
          textTheme: baseTheme.textTheme.apply(fontFamily: fontFamily),
          primaryTextTheme: baseTheme.primaryTextTheme.apply(
            fontFamily: fontFamily,
          ),
        );
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const Scaffold(body: SizedBox.expand(child: EditorCanvasHost())),
      ),
    ),
  );
  await pumpEventBuilderV2ProductRouteFrames(tester, container: container);
  return container;
}

/// Pumps the same attested on-disk fixture through the complete production
/// shell. The harness collapses the global explorer explicitly before the
/// workspace transition so visual evidence remains deterministic while still
/// exercising the production shell and Narrative Studio route.
Future<ProviderContainer> pumpEventBuilderV2FullProductRoute(
  WidgetTester tester, {
  required EventBuilderV2ProductRouteFixture fixture,
  MapData? activeMap,
  bool includeProjectRootPath = true,
  Size viewport = const Size(1672, 941),
  String? fontFamily,
  LoadNarrativeEventBuilderV2ReadModel? readModelLoader,
  LoadNarrativeEventValidationSnapshot? validationLoader,
  NarrativeEventRegistryPersistenceGateway? persistenceGateway,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = viewport;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);

  final overrides = <Override>[
    narrativeEventBuilderV2ReadModelLoaderProvider.overrideWithValue(
      readModelLoader ?? (_) => Future.value(fixture.readModel),
    ),
    narrativeEventValidationSnapshotLoaderProvider.overrideWithValue(
      validationLoader ??
          (_) => Future.value(
            buildEventBuilderV2ProductRouteValidationSnapshot(fixture),
          ),
    ),
    if (persistenceGateway != null)
      narrativeEventRegistryPersistenceGatewayProvider.overrideWithValue(
        persistenceGateway,
      ),
    narrativeEventSpatialSourceCreationGatewayProvider.overrideWithValue(
      _InitialClearSourceCreationGateway(
        NarrativeEventSpatialLinkJournalRepository(),
      ),
    ),
  ];
  final container = await pumpEditorShellPage(
    tester,
    initialState: EditorState(
      projectRootPath: includeProjectRootPath ? fixture.root.path : null,
      project: fixture.project,
      workspaceMode: EditorWorkspaceMode.map,
      activeMap: activeMap ?? fixture.portMap,
      activeLayerId: 'events',
    ),
    surfaceSize: viewport,
    fontFamily: fontFamily,
    overrides: overrides,
  );

  final collapseExplorer = find.byKey(
    const ValueKey('project-explorer-toggle'),
  );
  if (collapseExplorer.evaluate().isNotEmpty) {
    await tester.tap(collapseExplorer);
    await tester.pump();
  }
  await tester.pump(const Duration(milliseconds: 200));
  container.read(editorNotifierProvider.notifier).selectEventsWorkspace();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
  await pumpEventBuilderV2ProductRouteFrames(
    tester,
    container: container,
    count: 4,
  );
  return container;
}

NarrativeEventValidationSnapshot
buildEventBuilderV2ProductRouteValidationSnapshot(
  EventBuilderV2ProductRouteFixture fixture,
) {
  final registry = fixture.project.eventRegistry!;
  final catalog = buildNarrativeEventProjectCatalog(
    project: fixture.project,
    maps: [fixture.portMap, fixture.forestMap],
  );
  final report = buildNarrativeEventValidationReport(
    registry: registry,
    catalog: catalog,
  );
  return NarrativeEventValidationSnapshot(
    registry: registry,
    catalog: catalog,
    report: report,
    state: NarrativeEventValidationState.fromReport(report),
    recalculatedEventIds: registry.records.map((record) => record.id).toSet(),
  );
}

/// Advances a bounded number of frames instead of waiting on unrelated
/// repeating chrome animations that can keep [pumpAndSettle] alive forever.
Future<void> pumpEventBuilderV2ProductRouteFrames(
  WidgetTester tester, {
  ProviderContainer? container,
  int count = 2,
}) async {
  for (var index = 0; index < count; index++) {
    await tester.pump();
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 5)),
    );
  }
  // The last real-async interval can complete a provider future; one final
  // frame is required to render that AsyncValue.
  await tester.pump();
}

Future<void> waitForEventBuilderV2BridgeIdle(
  WidgetTester tester,
  ProviderContainer container,
) async {
  await tester.runAsync(() async {
    for (var attempt = 0; attempt < 200; attempt++) {
      final bridge = container.read(narrativeEventMapBridgeControllerProvider);
      if (!bridge.isSourceCreationBusy && !bridge.isLinkingSource) return;
      await Future<void>.delayed(const Duration(milliseconds: 5));
    }
    throw TestFailure('The Event/Map bridge did not become idle.');
  });
  await tester.pump();
}

MapData _map({
  required String id,
  required String name,
  required String entityId,
  required String entityName,
  MapEventDefinition? legacyEvent,
}) {
  return MapData(
    id: id,
    name: name,
    size: const GridSize(width: 8, height: 8),
    layers: const [MapLayer.object(id: 'events', name: 'Événements')],
    entities: [
      MapEntity(
        id: entityId,
        name: entityName,
        kind: MapEntityKind.npc,
        pos: const GridPos(x: 1, y: 1),
      ),
    ],
    triggers: [
      MapTrigger(
        id: 'trigger_$id',
        name: 'Zone de $name',
        type: TriggerType.event,
        area: const MapRect(
          pos: GridPos(x: 2, y: 2),
          size: GridSize(width: 2, height: 1),
        ),
      ),
    ],
    events: [?legacyEvent],
  );
}

NarrativeEventRecord _configured(
  String id,
  String name,
  NarrativeEventSourceRef source, {
  required bool enabled,
  String sceneId = 'scene_action',
  List<NarrativeEventCondition> conditions = const [],
  int priority = 0,
  int order = 0,
}) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: name,
      source: source,
      conditions: conditions,
      sceneId: sceneId,
      reusePolicy: NarrativeEventReusePolicy.oneShot,
      priority: priority,
      order: order,
    ),
    enabled: enabled,
  );
}

NarrativeEventRecord _draft(
  String id,
  String name, {
  NarrativeEventSourceRef? source,
}) {
  return NarrativeEventRecord.draft(
    NarrativeEventDraft(
      id: id,
      name: name,
      source: source,
      conditions: const [],
      priority: 0,
      order: 0,
    ),
  );
}

SceneAsset _scene(
  String id,
  String name, {
  String? outcomeId,
  List<SceneOutcome> declaredOutcomes = const [],
  List<SceneConsequence> consequences = const [],
}) {
  final path = [
    'start',
    for (var index = 0; index < consequences.length; index++) 'action_$index',
    'end',
  ];
  return SceneAsset(
    id: id,
    name: name,
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        for (var index = 0; index < consequences.length; index++)
          SceneNode(
            id: 'action_$index',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(consequences[index]),
          ),
        SceneNode(
          id: 'end',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: outcomeId),
        ),
      ],
      edges: [
        for (var index = 0; index < path.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: path[index],
            fromPortId: 'completed',
            toNodeId: path[index + 1],
            kind: SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
    declaredOutcomes: declaredOutcomes.isNotEmpty
        ? declaredOutcomes
        : outcomeId == null
        ? const []
        : [SceneOutcome(id: outcomeId, label: 'Victoire')],
  );
}

SceneAsset _rivalScene() {
  return SceneAsset(
    id: 'scene_rival',
    name: 'Rencontre rival',
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: [
        SceneNode(id: 'start', kind: SceneNodeKind.start),
        SceneNode(
          id: 'condition_port_open',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionLabel: 'Le port est ouvert',
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: 'fact_port_open',
              operator: SceneConditionOperator.isTrue,
              label: 'Le port est ouvert',
            ),
          ),
        ),
        SceneNode(
          id: 'condition_rival_defeated',
          kind: SceneNodeKind.condition,
          payload: SceneConditionPayload(
            conditionLabel: 'Le rival a déjà été battu',
            conditionSource: SceneConditionSource(
              sourceKind: SceneConditionSourceKind.fact,
              sourceId: 'fact_rival_defeated',
              operator: SceneConditionOperator.isTrue,
              label: 'Rival battu',
            ),
          ),
        ),
        SceneNode(
          id: 'action_rival_defeated',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.setFact(
              factId: 'fact_rival_defeated',
              value: true,
              label: 'Rival battu',
            ),
          ),
        ),
        SceneNode(
          id: 'action_mark_encounter',
          kind: SceneNodeKind.action,
          payload: SceneActionPayload.consequence(
            SceneConsequence.markEventConsumed(
              mapId: 'map_port',
              eventId: 'legacy_port',
              label: 'Rencontre du port',
            ),
          ),
        ),
        SceneNode(
          id: 'end_victory',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'victory'),
        ),
        SceneNode(
          id: 'end_defeat',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'defeat'),
        ),
        SceneNode(
          id: 'end_failure',
          kind: SceneNodeKind.end,
          payload: SceneEndPayload(sceneOutcomeId: 'failure'),
        ),
      ],
      edges: [
        SceneEdge(
          id: 'edge_start',
          fromNodeId: 'start',
          fromPortId: 'completed',
          toNodeId: 'condition_port_open',
          kind: SceneEdgeKind.defaultFlow,
        ),
        SceneEdge(
          id: 'edge_port_open_true',
          fromNodeId: 'condition_port_open',
          fromPortId: 'true',
          toNodeId: 'action_rival_defeated',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'edge_port_open_false',
          fromNodeId: 'condition_port_open',
          fromPortId: 'false',
          toNodeId: 'condition_rival_defeated',
          kind: SceneEdgeKind.conditionFalse,
        ),
        SceneEdge(
          id: 'edge_action_fact',
          fromNodeId: 'action_rival_defeated',
          fromPortId: 'completed',
          toNodeId: 'action_mark_encounter',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_action_mark',
          fromNodeId: 'action_mark_encounter',
          fromPortId: 'completed',
          toNodeId: 'end_victory',
          kind: SceneEdgeKind.actionCompleted,
        ),
        SceneEdge(
          id: 'edge_rival_defeated_true',
          fromNodeId: 'condition_rival_defeated',
          fromPortId: 'true',
          toNodeId: 'end_defeat',
          kind: SceneEdgeKind.conditionTrue,
        ),
        SceneEdge(
          id: 'edge_rival_defeated_false',
          fromNodeId: 'condition_rival_defeated',
          fromPortId: 'false',
          toNodeId: 'end_failure',
          kind: SceneEdgeKind.conditionFalse,
        ),
      ],
    ),
    declaredOutcomes: [
      SceneOutcome(id: 'victory', label: 'Victoire'),
      SceneOutcome(id: 'defeat', label: 'Défaite'),
      SceneOutcome(id: 'failure', label: 'Échec'),
    ],
  );
}

Future<void> _writeJson(File file, Map<String, Object?> json) async {
  await file.parent.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(json),
    flush: true,
  );
}

/// Keeps the first recovery probe deterministic under WidgetTest's FakeAsync,
/// then delegates every durable operation to the production journal gateway.
///
/// The product fixture is freshly created and therefore cannot contain a
/// pending spatial-link journal before navigation. Subsequent inspections must
/// remain real because source creation uses them to acknowledge its two-step
/// map/registry commit.
final class _InitialClearSourceCreationGateway
    implements NarrativeEventSpatialSourceCreationGateway {
  _InitialClearSourceCreationGateway(this._delegate);

  final NarrativeEventSpatialSourceCreationGateway _delegate;
  var _firstInspection = true;

  @override
  Future<NarrativeEventSpatialLinkInspection> inspectProject(
    String projectPath,
  ) {
    if (_firstInspection) {
      _firstInspection = false;
      return Future.value(
        NarrativeEventSpatialLinkInspection(
          status: NarrativeEventSpatialLinkInspectionStatus.clear,
        ),
      );
    }
    return _delegate.inspectProject(projectPath);
  }

  @override
  Future<NarrativeEventSpatialLinkOperationResult> commitMap(
    NarrativeEventSpatialLinkMapCommitRequest request,
  ) => _delegate.commitMap(request);

  @override
  Future<NarrativeEventSpatialLinkOperationResult> recoverProject({
    required String projectPath,
    required String expectedOperationId,
    required String expectedEventId,
    required String expectedMapId,
    required NarrativeEventSourceRef expectedSource,
  }) => _delegate.recoverProject(
    projectPath: projectPath,
    expectedOperationId: expectedOperationId,
    expectedEventId: expectedEventId,
    expectedMapId: expectedMapId,
    expectedSource: expectedSource,
  );

  @override
  Future<NarrativeEventSpatialLinkOperationResult> markEventCommitted({
    required String projectPath,
    required String operationId,
  }) => _delegate.markEventCommitted(
    projectPath: projectPath,
    operationId: operationId,
  );

  @override
  Future<NarrativeEventSpatialLinkOperationResult> acknowledgeEventCommitted({
    required String projectPath,
    required String operationId,
  }) => _delegate.acknowledgeEventCommitted(
    projectPath: projectPath,
    operationId: operationId,
  );

  @override
  Future<NarrativeEventSpatialLinkOperationResult> cleanupSource({
    required String projectPath,
    required String operationId,
    required bool confirmed,
  }) => _delegate.cleanupSource(
    projectPath: projectPath,
    operationId: operationId,
    confirmed: confirmed,
  );
}
