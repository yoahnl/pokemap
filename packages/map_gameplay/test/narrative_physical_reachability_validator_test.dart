import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

const _eventA = 'evt_019abcde-0000-7000-8000-000000000101';
const _eventB = 'evt_019abcde-0000-7000-8000-000000000102';

void main() {
  group('narrative physical reachability', () {
    test('proves mapEnter and trigger cells from the authored spawn', () {
      final map = _map(
        id: 'start',
        width: 5,
        height: 3,
        triggers: [
          const MapTrigger(
            id: 'gate_zone',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 1),
              size: GridSize(width: 2, height: 1),
            ),
          ),
        ],
      );
      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(_eventA, NarrativeEventSourceRef.mapEnter('start')),
          _event(
            _eventB,
            NarrativeEventSourceRef.triggerEnter('start', 'gate_zone'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(),
      );

      expect(report.verdict, NarrativePhysicalReachabilityVerdict.pass);
      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
      expect(
        report.resultForEvent(_eventB)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
      expect(
          report.resultForEvent(_eventB)?.path.last, const GridPos(x: 3, y: 1));
    });

    test('reports a permanent blocker instead of crossing a wall', () {
      final collisions = List<bool>.filled(15, false);
      for (final y in [0, 1, 2]) {
        collisions[y * 5 + 2] = true;
      }
      final map = _map(
        id: 'start',
        width: 5,
        height: 3,
        collisions: collisions,
        triggers: [
          const MapTrigger(
            id: 'sealed_zone',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 4, y: 1),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(
            _eventA,
            NarrativeEventSourceRef.triggerEnter('start', 'sealed_zone'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(),
      );

      expect(report.verdict, NarrativePhysicalReachabilityVerdict.fail);
      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.permanentlyBlocked,
      );
    });

    test('interacts with a blocking entity from a cardinal adjacent cell', () {
      final map = _map(
        id: 'start',
        width: 5,
        height: 3,
        entities: [
          _spawn(),
          const MapEntity(
            id: 'npc_guard',
            name: 'Garde',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 3, y: 1),
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(
            _eventA,
            NarrativeEventSourceRef.entityInteract('start', 'npc_guard'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(),
      );

      final result = report.resultForEvent(_eventA)!;
      expect(result.status, NarrativePhysicalSourceStatus.reachable);
      expect(result.path.last, const GridPos(x: 3, y: 0));
      expect(result.path, isNot(contains(const GridPos(x: 3, y: 1))));
    });

    test('follows authored on-enter warps between maps', () {
      final start = _map(
        id: 'start',
        width: 3,
        height: 1,
        warps: [
          const MapWarp(
            id: 'to_cave',
            pos: GridPos(x: 2, y: 0),
            targetMapId: 'cave',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final cave = _map(id: 'cave', width: 3, height: 1, withSpawn: false);

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(_eventA, NarrativeEventSourceRef.mapEnter('cave')),
        ]),
        maps: [start, cave],
        narrativeReport: _symbolicReport(),
      );

      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
      expect(report.reachableMapIds, containsAll(<String>{'start', 'cave'}));
    });

    test('follows authored map connections with the gameplay resolver', () {
      final start = _map(
        id: 'start',
        width: 3,
        height: 1,
        connections: [
          const MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'route',
          ),
        ],
      );
      final route = _map(id: 'route', width: 3, height: 1, withSpawn: false);

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(_eventA, NarrativeEventSourceRef.mapEnter('route')),
        ]),
        maps: [start, route],
        narrativeReport: _symbolicReport(),
      );

      expect(
        report.resultForEvent(_eventA)?.status,
        NarrativePhysicalSourceStatus.reachable,
      );
    });

    test('qualifies a World Rule barrier as releasable by proven progression',
        () {
      final map = _map(
        id: 'start',
        width: 5,
        height: 1,
        entities: [
          _spawn(y: 0),
          const MapEntity(
            id: 'barrier',
            name: 'Barrière',
            kind: MapEntityKind.sign,
            pos: GridPos(x: 2, y: 0),
          ),
          const MapEntity(
            id: 'goal',
            name: 'But',
            kind: MapEntityKind.npc,
            pos: GridPos(x: 4, y: 0),
          ),
        ],
      );
      final project = _project(
        [
          _event(
            _eventA,
            NarrativeEventSourceRef.entityInteract('start', 'goal'),
          ),
        ],
        storylines: [
          StorylineAsset(
            id: 'story',
            type: StorylineType.main,
            status: StorylineStatus.active,
            title: 'Story',
            chapters: [
              StorylineChapter(
                id: 'chapter',
                title: 'Chapter',
                order: 0,
                steps: [
                  StorylineStep(id: 'open_gate', title: 'Open', order: 0),
                ],
              ),
            ],
          ),
        ],
        worldRules: [
          WorldRuleDefinition(
            id: 'hide_barrier',
            label: 'Ouvrir le passage',
            source: const WorldRuleSource(
              kind: WorldRuleSourceKind.storyStepCompletion,
              sourceId: 'open_gate',
              predicate: WorldRuleSourcePredicate.completed,
            ),
            target: const WorldRuleTarget(
              kind: WorldRuleTargetKind.mapEntity,
              mapId: 'start',
              entityId: 'barrier',
            ),
            effect: const WorldRuleEffect(
              kind: WorldRuleEffectKind.entityHidden,
            ),
          ),
        ],
      );
      final progressed = NarrativeSymbolicState(
        completedStepIds: const {'open_gate'},
        provenance: const [
          NarrativeSymbolicProvenance(
            sceneId: 'scene_open',
            nodeId: 'complete_gate',
            description: 'Étape open_gate terminée.',
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: project,
        maps: [map],
        narrativeReport: _symbolicReport(extraStates: [progressed]),
      );

      final result = report.resultForEvent(_eventA)!;
      expect(result.status, NarrativePhysicalSourceStatus.progressionRequired);
      expect(result.provenance.single.nodeId, 'complete_gate');
    });

    test('keeps exhausted exploration and unknown progression indeterminate',
        () {
      final map = _map(
        id: 'start',
        width: 4,
        height: 1,
        triggers: [
          const MapTrigger(
            id: 'first',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 2, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
          const MapTrigger(
            id: 'second',
            type: TriggerType.event,
            area: MapRect(
              pos: GridPos(x: 3, y: 0),
              size: GridSize(width: 1, height: 1),
            ),
          ),
        ],
      );

      final report = validateNarrativePhysicalReachability(
        project: _project([
          _event(
            _eventA,
            NarrativeEventSourceRef.triggerEnter('start', 'first'),
          ),
          _event(
            _eventB,
            NarrativeEventSourceRef.triggerEnter('start', 'second'),
          ),
        ]),
        maps: [map],
        narrativeReport: _symbolicReport(
          verdict: NarrativeSymbolicVerdict.indeterminate,
        ),
        explorationBudget: 1,
      );

      expect(
          report.verdict, NarrativePhysicalReachabilityVerdict.indeterminate);
      expect(report.issues, isNotEmpty);
      expect(
        report.results.any(
          (result) =>
              result.status == NarrativePhysicalSourceStatus.indeterminate,
        ),
        isTrue,
      );
    });
  });
}

MapData _map({
  required String id,
  required int width,
  required int height,
  bool withSpawn = true,
  List<bool>? collisions,
  List<MapEntity>? entities,
  List<MapTrigger> triggers = const [],
  List<MapWarp> warps = const [],
  List<MapConnection> connections = const [],
}) {
  return MapData(
    id: id,
    name: id,
    size: GridSize(width: width, height: height),
    layers: [
      MapLayer.collision(
        id: 'collision',
        name: 'Collision',
        collisions: collisions ?? List<bool>.filled(width * height, false),
      ),
    ],
    entities:
        entities ?? (withSpawn ? [_spawn(y: height > 1 ? 1 : 0)] : const []),
    triggers: triggers,
    warps: warps,
    connections: connections,
  );
}

MapEntity _spawn({int y = 1}) => MapEntity(
      id: 'spawn',
      name: 'Spawn',
      kind: MapEntityKind.spawn,
      pos: GridPos(x: 0, y: y),
      spawn: const MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      blocksMovement: false,
    );

NarrativeEventRecord _event(String id, NarrativeEventSourceRef source) {
  return NarrativeEventRecord.configuredStructurallyUnchecked(
    NarrativeEventDefinition(
      id: id,
      name: id,
      source: source,
      conditions: const [],
      sceneId: 'scene',
      reusePolicy: NarrativeEventReusePolicy.reusable,
      priority: 0,
      order: int.parse(id.substring(id.length - 3)),
    ),
    enabled: true,
  );
}

ProjectManifest _project(
  List<NarrativeEventRecord> records, {
  List<StorylineAsset> storylines = const [],
  List<WorldRuleDefinition> worldRules = const [],
}) {
  return ProjectManifest(
    name: 'Physical reachability',
    maps: const [],
    tilesets: const [],
    newGame: const ProjectNewGameConfig(
      enabled: true,
      startMapId: 'start',
      startSpawnId: 'spawn',
    ),
    storylines: storylines,
    worldRules: worldRules,
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: records,
      legacyClaims: const [],
    ),
  );
}

NarrativeSymbolicReachabilityReport _symbolicReport({
  NarrativeSymbolicVerdict verdict = NarrativeSymbolicVerdict.pass,
  List<NarrativeSymbolicState> extraStates = const [],
}) {
  final initial = NarrativeSymbolicState();
  return NarrativeSymbolicReachabilityReport(
    verdict: verdict,
    terminalStates: [initial, ...extraStates],
    exploredStates: [initial, ...extraStates],
    issues: const [],
    reachableSceneIds: const {'scene'},
    exploredStateCount: 1 + extraStates.length,
  );
}
