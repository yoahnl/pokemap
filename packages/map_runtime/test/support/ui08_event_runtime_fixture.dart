import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

import 'project_manifest_test_support.dart';

const ui08MapId = 'ui08_station';
const ui08EntityId = 'ui08_station_master';
const ui08ProducerScene = 'ui08_station_meeting';
const ui08ProducerEvent = 'evt_019abcde-8000-7000-8000-000000000001';
const ui08ReceiverEvent = 'evt_019abcde-8000-7000-8000-000000000002';
const ui08WrongProducerEvent = 'evt_019abcde-8000-7000-8000-000000000003';
const ui08ReceivedFact = 'ui08.received';

Future<RuntimeMapBundle> createUi08RuntimeFixture(
  Directory root,
  NarrativeEventReusePolicy reusePolicy, {
  NarrativeEventSourceRef? source,
}) async {
  final map = MapData(
    id: ui08MapId,
    name: 'Gare UI08',
    size: const GridSize(width: 4, height: 4),
    layers: const [MapLayer.object(id: 'objects', name: 'Objets')],
    entities: const [
      MapEntity(
        id: 'spawn',
        name: 'Arrivée',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 1),
        blocksMovement: false,
        spawn: MapEntitySpawnData(
          role: EntitySpawnRole.playerStart,
          facing: EntityFacing.south,
        ),
      ),
      MapEntity(
        id: ui08EntityId,
        name: 'Chef de gare',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 1, y: 2),
      ),
    ],
    mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
  );
  final producer = _producerScene(ui08ProducerScene);
  final otherProducer = _producerScene('ui08_other_producer');
  final project = ProjectManifest(
    name: 'UI08 runtime isolé',
    maps: const [
      ProjectMapEntry(
        id: ui08MapId,
        name: 'Gare UI08',
        relativePath: 'maps/station.json',
      ),
    ],
    tilesets: const [],
    dialogues: const [
      ProjectDialogueEntry(
        id: 'ui08_greeting',
        name: 'Accueil en gare',
        relativePath: 'dialogues/greeting.yarn',
      ),
    ],
    facts: [
      NarrativeFactDefinition(id: ui08ReceivedFact, label: 'Résultat reçu'),
    ],
    scenes: [producer, otherProducer, _receiverScene()],
    eventRegistry: NarrativeEventRegistry(
      schemaVersion: 1,
      mode: EventSystemMode.v2Only,
      records: [
        _record(
          ui08ProducerEvent,
          source ??
              NarrativeEventSourceRef.entityInteract(ui08MapId, ui08EntityId),
          ui08ProducerScene,
          reusePolicy,
        ),
        _record(
          ui08ReceiverEvent,
          NarrativeEventSourceRef.outcomeReceived(_outcome(ui08ProducerScene)),
          'ui08_receiver',
          NarrativeEventReusePolicy.oneShot,
        ),
        _record(
          ui08WrongProducerEvent,
          NarrativeEventSourceRef.outcomeReceived(_outcome(otherProducer.id)),
          'ui08_receiver',
          NarrativeEventReusePolicy.oneShot,
        ),
      ],
      legacyClaims: const [],
    ),
  );
  for (final entry in {
    'project.json': jsonEncode(withPokeMapBetaPokemonRuleset(project.toJson())),
    'maps/station.json': jsonEncode(map.toJson()),
    'dialogues/greeting.yarn':
        'title: Start\n---\nChef: Bienvenue en gare UI08.\n===\n',
  }.entries) {
    final file = File('${root.path}/${entry.key}');
    await file.parent.create(recursive: true);
    await file.writeAsString(entry.value);
  }
  return loadRuntimeMapBundle(
    projectFilePath: '${root.path}/project.json',
    mapId: ui08MapId,
  );
}

NarrativeOutcomeRef _outcome(String producerId) => NarrativeOutcomeRef(
      producerKind: NarrativeOutcomeProducerKind.scene,
      producerId: producerId,
      outcomeId: 'meeting.completed',
    );

NarrativeEventRecord _record(
  String id,
  NarrativeEventSourceRef source,
  String sceneId,
  NarrativeEventReusePolicy policy,
) =>
    NarrativeEventRecord.configuredStructurallyUnchecked(
      NarrativeEventDefinition(
        id: id,
        name: id,
        source: source,
        conditions: const [],
        sceneId: sceneId,
        reusePolicy: policy,
        priority: 0,
        order: 0,
      ),
      enabled: true,
    );

SceneAsset _producerScene(String id) => SceneAsset(
      id: id,
      name: 'Rencontre en gare',
      declaredOutcomes: [
        SceneOutcome(id: 'meeting.completed', label: 'Rencontre terminée'),
      ],
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'dialogue',
            kind: SceneNodeKind.yarnDialogue,
            payload: SceneYarnDialoguePayload(
              dialogueId: 'ui08_greeting',
              yarnNodeName: 'Start',
            ),
          ),
          SceneNode(
            id: 'end',
            kind: SceneNodeKind.end,
            payload: SceneEndPayload(sceneOutcomeId: 'meeting.completed'),
          ),
        ],
        edges: [
          _edge('start', 'dialogue'),
          _edge('dialogue', 'end'),
        ],
      ),
    );

SceneAsset _receiverScene() => SceneAsset(
      id: 'ui08_receiver',
      name: 'Réception de la rencontre',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [
          SceneNode(id: 'start', kind: SceneNodeKind.start),
          SceneNode(
            id: 'received',
            kind: SceneNodeKind.action,
            payload: SceneActionPayload.consequence(
              SceneConsequence.setFact(factId: ui08ReceivedFact, value: true),
            ),
          ),
          SceneNode(id: 'end', kind: SceneNodeKind.end),
        ],
        edges: [
          _edge('start', 'received'),
          _edge('received', 'end', SceneEdgeKind.actionCompleted),
        ],
      ),
    );

SceneEdge _edge(
  String from,
  String to, [
  SceneEdgeKind kind = SceneEdgeKind.defaultFlow,
]) =>
    SceneEdge(
      id: '${from}_$to',
      fromNodeId: from,
      fromPortId: 'completed',
      toNodeId: to,
      kind: kind,
    );
