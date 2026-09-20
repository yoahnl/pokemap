import 'dart:io';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:avelune_studio/features/narrative/domain/narrative_port.dart';
import 'package:map_core/map_core.dart';
import 'ui06_scene_fixture.dart';
import 'ui07_story_fixture.dart';
import 'ui08_event_fixture.dart';
import 'ui10_fixture_visuals.dart';

const ui10CinematicId = Ui06SceneFixture.cinematicId;

Future<Ui07StoryFixture> createUi10Fixture({
  bool runtimeEntry = false,
  int tileSize = 32,
}) async {
  final fixture = await createUi08Fixture();
  try {
    await seedUi10Visuals(fixture, tileSize: tileSize);
    final manifest = await fixture.readFresh();
    final base = await fixture.maps.loadMap(
      fixture.session,
      manifest.maps.first,
    );
    final oldEvent = manifest.eventRegistry!.records.singleWhere(
      (e) => e.id == Ui06SceneFixture.eventId,
    );
    final event = runtimeEntry
        ? NarrativeEventRecord.configuredStructurallyUnchecked(
            NarrativeEventDefinition(
              id: oldEvent.id,
              name: 'Arrivée au jardin',
              source: NarrativeEventSourceRef.mapEnter(base.map.id),
              conditions: [],
              sceneId: Ui06SceneFixture.sceneId,
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: 0,
              order: 0,
            ),
            enabled: true,
            activeInLegacyMode: true,
          )
        : oldEvent;
    await LocalNarrativeAdapter(
      session: fixture.session,
      mapAdapter: fixture.maps,
    ).publish(
      NarrativePublication(
        base: base,
        current: base.map,
        expectedScenes: {Ui06SceneFixture.sceneId: manifest.scenes.single},
        expectedCinematics: {ui10CinematicId: manifest.cinematics.single},
        scenes: [ui10Scene()],
        cinematics: [ui10Cinematic()],
        events: [event],
      ),
    );
    return fixture;
  } catch (_) {
    await fixture.dispose();
    rethrow;
  }
}

CinematicAsset ui10Cinematic() => CinematicAsset(
  id: ui10CinematicId,
  title: 'Rencontre au jardin',
  mapId: 'jardin',
  requiredActors: [
    CinematicActorRef(actorId: 'hero', label: 'Voyageur'),
    CinematicActorRef(actorId: 'chief', label: 'Guide du jardin'),
  ],
  movementTargets: [
    CinematicMovementTargetRef(
      targetId: 'destination',
      label: 'Auprès du guide',
    ),
  ],
  stageContext: CinematicStageContext(
    backdropMode: CinematicStageBackdropMode.projectMap,
    actorBindings: [
      CinematicActorBinding(
        actorId: 'hero',
        kind: CinematicActorBindingKind.player,
      ),
      CinematicActorBinding(
        actorId: 'chief',
        kind: CinematicActorBindingKind.mapEntity,
        mapEntityId: 'chief',
      ),
    ],
    initialPlacements: [
      CinematicActorInitialPlacement(
        actorId: 'hero',
        kind: CinematicActorInitialPlacementKind.stagePoint,
        stagePointId: 'start',
      ),
      CinematicActorInitialPlacement(
        actorId: 'chief',
        kind: CinematicActorInitialPlacementKind.fromMapEntity,
      ),
    ],
    stagePoints: [
      CinematicStagePoint(id: 'start', label: 'Départ', x: 8, y: 9),
      CinematicStagePoint(id: 'arrival', label: 'Auprès du guide', x: 13, y: 9),
    ],
    movementTargetBindings: [
      CinematicMovementTargetBinding(
        targetId: 'destination',
        kind: CinematicMovementTargetBindingKind.stagePoint,
        sourceId: 'arrival',
      ),
    ],
  ),
  timeline: CinematicTimeline(
    steps: [
      CinematicTimelineStep(
        id: 'opening',
        kind: CinematicTimelineStepKind.wait,
        durationMs: 400,
        metadata: _ui10Block('wait'),
      ),
      CinematicTimelineStep(
        id: 'walk',
        kind: CinematicTimelineStepKind.actorMove,
        actorId: 'hero',
        targetId: 'destination',
        durationMs: 1200,
        metadata: {
          ..._ui10Block('actorMove'),
          cinematicTimelineActorMovementModeMetadataKey: 'walk',
          cinematicTimelineActorPathModeMetadataKey: 'direct',
        },
      ),
      CinematicTimelineStep(
        id: 'face',
        kind: CinematicTimelineStepKind.actorFace,
        actorId: 'hero',
        metadata: {
          ..._ui10Block('actorFace'),
          cinematicTimelineActorDirectionMetadataKey: 'up',
        },
      ),
      CinematicTimelineStep(
        id: 'camera',
        kind: CinematicTimelineStepKind.camera,
        durationMs: 700,
        metadata: {
          ..._ui10Block('camera'),
          cinematicTimelineCameraModeMetadataKey: 'focus',
          cinematicTimelineCameraTargetKindMetadataKey: 'stagePoint',
          cinematicTimelineCameraTargetStagePointIdMetadataKey: 'arrival',
          cinematicTimelineCameraZoomPresetMetadataKey: 'close',
        },
      ),
      CinematicTimelineStep(
        id: 'fade',
        kind: CinematicTimelineStepKind.fade,
        durationMs: 600,
        metadata: {
          ..._ui10Block('fade'),
          cinematicTimelineFadeModeMetadataKey: 'fadeOut',
        },
      ),
      CinematicTimelineStep(
        id: 'ending',
        kind: CinematicTimelineStepKind.wait,
        durationMs: 250,
        metadata: _ui10Block('wait'),
      ),
    ],
  ),
);

SceneAsset ui10Scene() => SceneAsset(
  id: Ui06SceneFixture.sceneId,
  name: 'Rencontre au jardin',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: [
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'cinematic',
        kind: SceneNodeKind.cinematic,
        payload: SceneCinematicPayload(cinematicId: ui10CinematicId),
      ),
      SceneNode(
        id: 'authorize',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.consequence(
          SceneConsequence.setFact(
            factId: Ui06SceneFixture.departureFactId,
            value: true,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: [
      SceneEdge(
        id: 'begin',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'cinematic',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'played',
        fromNodeId: 'cinematic',
        fromPortId: 'completed',
        toNodeId: 'authorize',
        kind: SceneEdgeKind.cinematicCompleted,
      ),
      SceneEdge(
        id: 'done',
        fromNodeId: 'authorize',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

Future<Map<String, List<int>>> ui10AuthoringBytes(Directory root) async => {
  for (final file
      in await root
          .list(recursive: true)
          .where((e) => e is File)
          .cast<File>()
          .toList())
    if (file.path.endsWith('.json') || file.path.endsWith('.yarn'))
      file.path.substring(root.path.length + 1): await file.readAsBytes(),
};

Map<String, String> _ui10Block(String kind) => {
  cinematicTimelineDraftMetadataKindKey:
      cinematicTimelineBasicBlockMetadataKindValue,
  cinematicTimelineDraftMetadataSourceKey:
      cinematicTimelineDraftMetadataSourceValue,
  cinematicTimelineAuthoringBlockMetadataKey: kind,
};
