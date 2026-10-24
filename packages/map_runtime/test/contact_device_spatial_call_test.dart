import 'dart:async';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/application/map_activation.dart';
import 'package:map_runtime/src/application/narrative_runtime_activity_gate.dart';
import 'package:map_runtime/src/application/narrative_spatial_production_dispatch_bridge.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_runtime_host_callbacks.dart';
import 'package:map_runtime/src/application/scene_runtime/scene_consequence_runtime_writer.dart';
import 'package:map_runtime/src/application/battle_start_request.dart';
import 'package:map_runtime/src/spatial/spatial_gameplay_events.dart';

void main() {
  ProjectManifest deviceProject(MapData map, List<SceneAsset> scenes) =>
      _project(map, scenes: scenes).copyWith(
        facts: [
          for (final id in ['owned', 'known', 'ready'])
            NarrativeFactDefinition(id: id, label: id),
        ],
        contactDevice: ProjectContactDeviceConfig(
          id: 'device',
          label: 'Carnet',
          acquiredFactId: 'owned',
          emptyMessage: 'Personne.',
          contacts: [
            ProjectContactEntryConfig(
              id: 'mentor',
              label: 'Mentor',
              registeredFactId: 'known',
              availableFactId: 'ready',
              sceneId: 'call',
              unavailableSceneId: 'busy',
            ),
          ],
        ),
      );
  GameState state({bool ready = false, bool known = true}) => GameState(
    saveId: 'save',
    currentMapId: 'map',
    playerPosition: const GridPos(x: 2, y: 2),
    playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
    narrativeFactRuntimeState: NarrativeFactRuntimeState(
      overridesByFactId: {'owned': true, 'known': known, 'ready': ready},
    ),
  );

  for (final ready in [false, true]) {
    test(
      'real spatial scene call routes availability=$ready and commits atomically',
      () async {
        final map = _map();
        final host = await _Host.create(
          deviceProject(map, [
            _scene('call', [
              SceneConsequence.giveMoney(amount: 7),
            ], dialogue: true),
            _scene('busy', [
              SceneConsequence.giveMoney(amount: 3),
            ], dialogue: true),
          ]),
          map,
          state: state(ready: ready),
        );
        addTearDown(host.events.dispose);
        expect(await host.events.callContact('mentor'), isTrue);
        expect(host.state.trainerProfile.money, ready ? 7 : 3);
        expect(host.gate.activity, NarrativeRuntimeActivity.idle);
        expect(host.events.isBusy, isFalse);
      },
    );
  }

  test(
    'unregistered call never executes and releases the gameplay gate',
    () async {
      final map = _map();
      final host = await _Host.create(
        deviceProject(map, [_scene('call', []), _scene('busy', [])]),
        map,
        state: state(known: false),
      );
      addTearDown(host.events.dispose);
      final before = host.state;
      await expectLater(host.events.callContact('mentor'), throwsStateError);
      expect(host.state, before);
      expect(host.events.isBusy, isFalse);
      expect(host.gate.activity, NarrativeRuntimeActivity.idle);
    },
  );

  test('invalidated call cannot commit buffered consequences', () async {
    final map = _map();
    final started = Completer<void>();
    final release = Completer<String>();
    final host = await _Host.create(
      deviceProject(map, [
        _scene('call', [SceneConsequence.giveMoney(amount: 7)], dialogue: true),
        _scene('busy', [], dialogue: true),
      ]),
      map,
      state: state(ready: true),
      dialogue: () {
        started.complete();
        return release.future;
      },
    );
    addTearDown(host.events.dispose);
    final before = host.state;
    final pending = host.events.callContact('mentor');
    await started.future;
    expect(host.events.isBusy, isTrue);
    host.events.invalidate();
    release.complete('completed');
    expect(await pending, isFalse);
    expect(host.state, before);
    expect(host.gate.activity, NarrativeRuntimeActivity.idle);
  });
}

final class _Host {
  _Host(this.state);
  GameState state;
  late SpatialGameplayEvents events;
  final gate = NarrativeRuntimeActivityGate();
  final battles = <WildBattleStartRequest>[];
  bool canInput = true;
  int serial = 10;

  static Future<_Host> create(
    ProjectManifest project,
    MapData map, {
    GameState? state,
    Future<String> Function()? dialogue,
    Map<String, MapData>? maps,
    SpatialSceneCallbackFactory? createSceneCallbacks,
    SpatialSceneConsequenceWriterFactory? buildSceneConsequenceWriter,
    Future<void> Function(GameState)? afterStateCommitted,
  }) async {
    final host = _Host(
      state ??
          GameState(
            saveId: 'save',
            currentMapId: map.id,
            playerPosition: const GridPos(x: 2, y: 2),
            playerSpatialPosition: PlayerSpatialPosition(x: 2.5, z: 2.5),
          ),
    );
    host.events = await SpatialGameplayEvents.create(
      project: project,
      mapsById: maps ?? {map.id: map},
      readGameState: () => host.state,
      commitGameState: (state) => host.state = state,
      createSceneCallbacks:
          createSceneCallbacks ??
          (read, commit) => SceneRuntimeHostCallbacks(
            evaluateCondition: (_) => 'true',
            showDialogue: (_) async =>
                dialogue == null ? 'completed' : await dialogue(),
            startBattle: (_) => 'victory',
            playCinematic: (_) => 'completed',
          ),
      showEntityDialogue: (_, __) async {},
      startWildBattle: (request) async => host.battles.add(request),
      activityGate: host.gate,
      isActive: () => true,
      canProcessInput: () => host.canInput,
      runtimeIdFactory: (prefix) => _id(prefix, host.serial++),
      afterStateCommitted: afterStateCommitted,
      buildSceneConsequenceWriter: buildSceneConsequenceWriter,
      random: Random(41),
      now: () => DateTime.fromMillisecondsSinceEpoch(42),
    );
    return host;
  }

  void moveTo(double x, double z) {
    state = state.copyWith(
      playerPosition: GridPos(x: x.floor(), y: z.floor()),
      playerSpatialPosition: PlayerSpatialPosition(x: x, z: z),
    );
  }
}

String _id(String prefix, int value) =>
    '${prefix}_019abcde-0000-7000-8000-${value.toRadixString(16).padLeft(12, '0')}';
MapActivation _activation(
  String id, [
  MapActivationReason reason = MapActivationReason.initialBoot,
]) => MapActivation(activationId: id, mapId: 'map', reason: reason);

MapData _map({
  List<MapEntity> entities = const [],
  List<MapTrigger> triggers = const [],
  List<MapGameplayZone> zones = const [],
}) => MapData(
  id: 'map',
  name: 'Spatial village',
  size: const GridSize(width: 6, height: 6),
  entities: entities,
  triggers: triggers,
  gameplayZones: zones,
  spatialScene: MapSpatialScene(
    width: 6,
    depth: 6,
    navigation: SpatialNavigationProfile(spawn: SpatialSpawn(x: 2.5, z: 2.5)),
  ),
);

ProjectManifest _project(
  MapData map, {
  List<NarrativeEventRecord> records = const [],
  List<SceneAsset> scenes = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) => ProjectManifest(
  name: 'Spatial events',
  tilesets: const [],
  settings: ProjectSettings(
    dimension: ProjectDimension.threeD,
    spatialCamera: SpatialCameraProfile(),
    tileWidth: 32,
    tileHeight: 24,
  ),
  maps: [
    ProjectMapEntry(id: map.id, name: map.name, relativePath: 'maps/map.json'),
  ],
  dialogues: const [
    ProjectDialogueEntry(
      id: 'talk',
      name: 'Talk',
      relativePath: 'dialogues/talk.yarn',
    ),
  ],
  eventRegistry: NarrativeEventRegistry(
    schemaVersion: 1,
    mode: EventSystemMode.v2Only,
    records: records,
    legacyClaims: const [],
  ),
  scenes: scenes,
  worldRules: worldRules,
);

NarrativeEventRecord _event(
  int id,
  NarrativeEventSourceRef source,
  String sceneId, {
  bool oneShot = true,
  List<NarrativeEventCondition> conditions = const [],
}) => NarrativeEventRecord.configuredStructurallyUnchecked(
  NarrativeEventDefinition(
    id: _id('evt', id),
    name: sceneId,
    source: source,
    conditions: conditions,
    sceneId: sceneId,
    reusePolicy: oneShot
        ? NarrativeEventReusePolicy.oneShot
        : NarrativeEventReusePolicy.reusable,
    priority: 0,
    order: id,
    resetPolicy: const NarrativeEventResetPolicy.never(),
  ),
  enabled: true,
);

SceneAsset _scene(
  String id,
  List<SceneConsequence> consequences, {
  bool dialogue = false,
  String? outcome,
}) {
  final nodes = <SceneNode>[
    SceneNode(id: 'start', kind: SceneNodeKind.start),
    for (var index = 0; index < consequences.length; index++)
      SceneNode(
        id: 'action_$index',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(consequences[index]),
      ),
    if (dialogue)
      SceneNode(
        id: 'dialogue',
        kind: SceneNodeKind.yarnDialogue,
        payload: SceneYarnDialoguePayload(dialogueId: 'talk'),
      ),
    SceneNode(
      id: 'end',
      kind: SceneNodeKind.end,
      payload: outcome == null
          ? null
          : SceneEndPayload(sceneOutcomeId: outcome),
    ),
  ];
  return SceneAsset(
    id: id,
    name: id,
    declaredOutcomes: [
      if (outcome != null) SceneOutcome(id: outcome, label: outcome),
    ],
    graph: SceneGraph(
      startNodeId: 'start',
      nodes: nodes,
      edges: [
        for (var index = 0; index < nodes.length - 1; index++)
          SceneEdge(
            id: 'edge_$index',
            fromNodeId: nodes[index].id,
            fromPortId: 'completed',
            toNodeId: nodes[index + 1].id,
            kind: nodes[index].kind == SceneNodeKind.action
                ? SceneEdgeKind.actionCompleted
                : nodes[index].kind == SceneNodeKind.yarnDialogue
                ? SceneEdgeKind.defaultFlow
                : SceneEdgeKind.defaultFlow,
          ),
      ],
    ),
  );
}
