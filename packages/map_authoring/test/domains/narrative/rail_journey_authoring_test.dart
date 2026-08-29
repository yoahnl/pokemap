import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('RailJourney authoring', () {
    test('publishes typed upsert and delete contracts', () {
      final descriptors = RailJourneyActions.descriptors;

      expect(
        descriptors.map((descriptor) => descriptor.id),
        <String>['rail_journey.upsert', 'rail_journey.delete'],
      );
      for (final descriptor in descriptors) {
        expect(descriptor.version, 1);
        expect(descriptor.resourceKinds,
            containsAll(<String>['project', 'railJourney']));
        expect(
          descriptor.capabilityIds,
          <String>['authoring.narrative.modern'],
        );
        expect(
          descriptor.guarantees,
          containsAll(<AuthoringGuarantee>{
            AuthoringGuarantee.dryRun,
            AuthoringGuarantee.idempotent,
            AuthoringGuarantee.atomic,
            AuthoringGuarantee.revisionChecked,
            AuthoringGuarantee.undoable,
          }),
        );
      }
    });

    test('upserts and deletes one definition without a generic project save',
        () {
      const actions = RailJourneyActions();
      const initial = ProjectManifest(
        name: 'Rail authoring fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
      );

      final created = actions.upsert(initial, journey: _journey);
      final updated = actions.upsert(
        created,
        journey: _journey.copyWith(label: 'Updated journey'),
      );
      final deleted = actions.delete(updated, journeyId: _journey.id);

      expect(created.railJourneyCatalog?.journeys,
          <RailJourneyDefinition>[_journey]);
      expect(
          updated.railJourneyCatalog?.journeys.single.label, 'Updated journey');
      expect(deleted.railJourneyCatalog, isNull);
    });

    test('deletion is blocked while a Scene references the journey', () {
      const actions = RailJourneyActions();
      final project = ProjectManifest(
        name: 'Rail deletion fixture',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        railJourneyCatalog: const RailJourneyCatalog(
          journeys: <RailJourneyDefinition>[_journey],
        ),
        scenes: <SceneAsset>[_railScene],
      );

      expect(
        () => actions.delete(project, journeyId: _journey.id),
        throwsA(
          isA<RailJourneyAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'rail_journey.referenced',
              )
              .having(
                (error) => error.details['consumerPaths'],
                'consumerPaths',
                <String>[
                  'scenes[scene.rail].graph.nodes[1].payload.interactiveCommand.journeyId',
                ],
              ),
        ),
      );
      expect(project.railJourneyCatalog?.journeys, <RailJourneyDefinition>[
        _journey,
      ]);
    });

    test('queries each journey as a first-class resource', () {
      final manifest = const ProjectManifest(
        name: 'Rail query fixture',
        maps: <ProjectMapEntry>[],
        tilesets: <ProjectTilesetEntry>[],
        railJourneyCatalog: RailJourneyCatalog(
          journeys: <RailJourneyDefinition>[_journey],
        ),
      );
      final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('project-rail'),
        revision: 'sha256:${'1' * 64}',
        manifest: manifest,
        maps: const <MapData>[],
        resourceFingerprints: const <String, String>{},
      );

      final page = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'railJourney',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['T1'],
          view: AuthoringQueryView.detail,
        ),
      );

      expect(page.totalAvailable, 1);
      expect(
        page.items.single,
        containsPair('resourceKind', 'railJourney'),
      );
      expect(page.items.single['id'], 'T1');
      expect(page.items.single['fare'], _journey.fare.toJson());
    });
  });
}

const _originDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.west,
  stationPlacedElementId: 'door_origin_west',
  vehiclePlacedElementId: 'door_vehicle_west',
);

const _destinationDoor = RailJourneyEndpointDoor(
  side: RailJourneyDoorSide.east,
  stationPlacedElementId: 'door_destination_east',
  vehiclePlacedElementId: 'door_vehicle_east',
);

const _journey = RailJourneyDefinition(
  id: 'T1',
  label: 'Origin to destination',
  origin: RailJourneyEndpoint(
    stationMapId: 'map_origin_station',
    boardingArea: MapRect(
      pos: GridPos(x: 2, y: 3),
      size: GridSize(width: 3, height: 2),
    ),
    trainEntryPos: GridPos(x: 1, y: 4),
    stationArrivalPos: GridPos(x: 3, y: 6),
    doors: <RailJourneyEndpointDoor>[_originDoor],
  ),
  destination: RailJourneyEndpoint(
    stationMapId: 'map_destination_station',
    boardingArea: MapRect(
      pos: GridPos(x: 4, y: 2),
      size: GridSize(width: 2, height: 3),
    ),
    trainEntryPos: GridPos(x: 6, y: 4),
    stationArrivalPos: GridPos(x: 7, y: 6),
    doors: <RailJourneyEndpointDoor>[_destinationDoor],
  ),
  vehicleMapId: 'map_train_car',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'day',
  fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
);

final _railScene = SceneAsset(
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
