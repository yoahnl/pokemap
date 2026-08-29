import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('dependency index resolves Scene to RailJourney usages', () {
    final index = buildNarrativeDependencyIndex(
      project: _project(railJourneyCatalog: const RailJourneyCatalog(
        journeys: <RailJourneyDefinition>[_journey],
      )),
    );
    const target = NarrativeDependencyKey.railJourney('T1');

    expect(index.definitionsFor(target), hasLength(1));
    expect(index.usagesFor(target), hasLength(1));
    expect(index.usagesFor(target).single.owner,
        const NarrativeDependencyKey.scene('scene.rail'));
    expect(
      index.usagesFor(target).single.path,
      'scenes[scene.rail].graph.nodes[1].payload.interactiveCommand.journeyId',
    );
    expect(
      index.usagesFor(target).single.resolution,
      NarrativeDependencyResolution.resolved,
    );
  });

  test('unknown RailJourney is a Scene and project validation error', () {
    final project = _project();
    final sceneReport = diagnoseSceneAgainstProject(
      project.scenes.single,
      project,
    );
    final narrativeReport = validateNarrativeProject(
      project,
      maps: const <MapData>[],
    );

    expect(
      sceneReport.byCode(SceneDiagnosticCode.commandUnknownRailJourney),
      hasLength(1),
    );
    expect(
      narrativeReport.byCode('commandUnknownRailJourney'),
      hasLength(1),
    );
    expect(narrativeReport.isPlayable, isFalse);
    expect(
      () => ProjectValidator.validate(project),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          'scene_rail_journey_unknown',
        ),
      ),
    );
  });
}

ProjectManifest _project({RailJourneyCatalog? railJourneyCatalog}) =>
    ProjectManifest(
      name: 'Rail references',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      railJourneyCatalog: railJourneyCatalog,
      scenes: <SceneAsset>[_scene],
    );

final _scene = SceneAsset(
  id: 'scene.rail',
  name: 'Rail Scene',
  graph: SceneGraph(
    startNodeId: 'start',
    nodes: <SceneNode>[
      SceneNode(id: 'start', kind: SceneNodeKind.start),
      SceneNode(
        id: 'rail',
        kind: SceneNodeKind.action,
        payload: SceneActionPayload.interactive(
          SceneInteractiveCommand.railJourney(
            commandId: 'scene.rail.begin',
            journeyId: 'T1',
            operation: SceneRailJourneyOperation.begin,
            direction: RailJourneyDirection.outbound,
            doorSide: RailJourneyDoorSide.west,
          ),
        ),
      ),
      SceneNode(id: 'end', kind: SceneNodeKind.end),
    ],
    edges: <SceneEdge>[
      SceneEdge(
        id: 'start-rail',
        fromNodeId: 'start',
        fromPortId: 'completed',
        toNodeId: 'rail',
        kind: SceneEdgeKind.defaultFlow,
      ),
      SceneEdge(
        id: 'rail-completed',
        fromNodeId: 'rail',
        fromPortId: 'completed',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
      SceneEdge(
        id: 'rail-blocked',
        fromNodeId: 'rail',
        fromPortId: 'blocked',
        toNodeId: 'end',
        kind: SceneEdgeKind.actionCompleted,
      ),
    ],
  ),
);

const _journey = RailJourneyDefinition(
  id: 'T1',
  label: 'Journey',
  origin: RailJourneyEndpoint(
    stationMapId: 'map.origin',
    boardingArea: MapRect(
      pos: GridPos(x: 0, y: 0),
      size: GridSize(width: 1, height: 1),
    ),
    trainEntryPos: GridPos(x: 0, y: 0),
    stationArrivalPos: GridPos(x: 0, y: 0),
    doors: <RailJourneyEndpointDoor>[],
  ),
  destination: RailJourneyEndpoint(
    stationMapId: 'map.destination',
    boardingArea: MapRect(
      pos: GridPos(x: 0, y: 0),
      size: GridSize(width: 1, height: 1),
    ),
    trainEntryPos: GridPos(x: 0, y: 0),
    stationArrivalPos: GridPos(x: 0, y: 0),
    doors: <RailJourneyEndpointDoor>[],
  ),
  vehicleMapId: 'map.train',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'day',
  fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
);
