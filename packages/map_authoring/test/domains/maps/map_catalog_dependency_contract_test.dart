import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import 'map_catalog_fixture.dart';

void main() {
  test('a global consumed-event condition protects its defining map', () {
    final map = catalogMap('target').copyWith(events: const [
      MapEventDefinition(
          id: 'global_event',
          pages: [],
          position: EventPosition(layerId: 'base', x: 0, y: 0))
    ]);
    final initial = catalogSnapshot([map]);
    final project = initial.manifest.copyWith(scenes: [
      SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'condition',
                kind: SceneNodeKind.condition,
                payload: SceneConditionPayload(
                    conditionSource: SceneConditionSource(
                        sourceKind: SceneConditionSourceKind.consumedEvent,
                        sourceId: 'global_event',
                        operator: SceneConditionOperator.isTrue)))
          ], edges: const []))
    ]);
    final snapshot = catalogSnapshot([MapData.fromJson(map.toJson())],
        project: ProjectManifest.fromJson(project.toJson()));
    final before = snapshot.resourceBytes('map:target');
    final result = const MapLifecycleActions().analyze(
        catalogContext(snapshot, 'map.delete_apply', {'mapId': 'target'}));
    expect(result.errorCode, 'map.references_blocking');
    expect(result.details['edges'].toString(), contains('legacyMapEvent'));
    expect(result.details['edges'].toString(), contains('scene'));
    expect(snapshot.resourceBytes('map:target'), before);
    final unreferenced = const MapLifecycleActions().analyze(
        catalogContext(initial, 'map.delete_apply', {'mapId': 'target'}));
    expect(unreferenced.canApply, isTrue);
  });

  test('scene NPC movement protects the referenced map from deletion', () {
    final map = catalogMap('target');
    final initial = catalogSnapshot([map]);
    final project = initial.manifest.copyWith(scenes: [
      SceneAsset(
          id: 'scene',
          name: 'Scene',
          graph: SceneGraph(startNodeId: 'start', nodes: [
            SceneNode(id: 'start', kind: SceneNodeKind.start),
            SceneNode(
                id: 'move',
                kind: SceneNodeKind.action,
                payload: SceneActionPayload.interactive(
                    SceneInteractiveCommand.moveNpc(
                        mapId: 'target',
                        entityId: 'npc',
                        warpId: 'destination')))
          ], edges: const []))
    ]);
    final result = const MapLifecycleActions().analyze(catalogContext(
        catalogSnapshot([map], project: project),
        'map.delete_apply',
        {'mapId': 'target'}));
    expect(result.errorCode, 'map.references_blocking');
  });

  test('a decor traversal is a real blocking incoming reference', () {
    final target = catalogMap('target');
    final owner = catalogMap('owner').copyWith(placedElements: const [
      MapPlacedElement(
          id: 'door',
          layerId: 'base',
          elementId: 'door_asset',
          pos: GridPos(x: 0, y: 0),
          behaviors: [
            MapPlacedElementBehavior(
                id: 'entry',
                effect: MapPlacedElementEffect(
                    type: MapPlacedElementEffectType.traverseWarp,
                    targetMapId: 'target',
                    targetPos: GridPos(x: 5, y: 0)))
          ]),
    ]);
    final snapshot = catalogSnapshot([target, owner]);
    final deletion = const MapLifecycleActions().analyze(
        catalogContext(snapshot, 'map.delete_apply', {'mapId': 'target'}));
    final resize = const MapLifecycleActions().analyze(catalogContext(snapshot,
        'map.resize_apply', {'mapId': 'target', 'width': 4, 'height': 5}));
    expect(deletion.errorCode, 'map.references_blocking');
    expect(
        deletion.details['edges'].toString(), contains('effect.targetMapId'));
    expect(resize.errorCode, 'map.resize_impacts');
    expect(resize.details['impacts'].toString(), contains('placedElementWarp'));
  });

  test('rail endpoints protect station and vehicle coordinates separately', () {
    final station = catalogMap('station');
    final destination = catalogMap('destination');
    final vehicle = catalogMap('vehicle');
    final initial = catalogSnapshot([station, destination, vehicle]);
    final project = initial.manifest.copyWith(
        railJourneyCatalog: const RailJourneyCatalog(journeys: [
      RailJourneyDefinition(
          id: 'journey',
          label: 'Journey',
          origin: RailJourneyEndpoint(
              stationMapId: 'station',
              boardingArea: MapRect(
                  pos: GridPos(x: 4, y: 0),
                  size: GridSize(width: 2, height: 1)),
              trainEntryPos: GridPos(x: 5, y: 1),
              stationArrivalPos: GridPos(x: 5, y: 0),
              doors: []),
          destination: RailJourneyEndpoint(
              stationMapId: 'destination',
              boardingArea: MapRect(
                  pos: GridPos(x: 0, y: 0),
                  size: GridSize(width: 1, height: 1)),
              trainEntryPos: GridPos(x: 0, y: 0),
              stationArrivalPos: GridPos(x: 0, y: 0),
              doors: []),
          vehicleMapId: 'vehicle',
          vehicleVariant: RailJourneyVehicleVariant.regular,
          shellState: 'normal',
          fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree)),
    ]));
    final snapshot =
        catalogSnapshot([station, destination, vehicle], project: project);
    for (final mapId in ['station', 'vehicle']) {
      final deletion = const MapLifecycleActions().analyze(
          catalogContext(snapshot, 'map.delete_apply', {'mapId': mapId}));
      final resize = const MapLifecycleActions().analyze(catalogContext(
          snapshot,
          'map.resize_apply',
          {'mapId': mapId, 'width': 4, 'height': 5}));
      expect(deletion.errorCode, 'map.references_blocking');
      expect(resize.errorCode, 'map.resize_impacts');
      final impacts = resize.details['impacts'] as List;
      expect(
          impacts.map((impact) => (impact as Map)['kind']),
          mapId == 'station'
              ? containsAll(['railBoardingArea', 'railArrival'])
              : contains('railEntry'));
      if (mapId == 'vehicle') {
        expect(impacts.toString(), isNot(contains('railArrival')));
      }
    }
  });

  test('duplicate rejects a removed destination folder', () {
    final snapshot = catalogSnapshot([catalogMap('source')]);
    final result = const MapLifecycleActions().analyze(catalogContext(snapshot,
        'map.duplicate', {'sourceMapId': 'source', 'groupId': 'removed'}));
    expect(result.errorCode, 'map.group_missing');
  });

  test('duplicate can explicitly leave the source folder', () {
    final source = catalogMap('source');
    final initial = catalogSnapshot([source]);
    final project = initial.manifest.copyWith(groups: const [
      ProjectMapGroup(id: 'folder', name: 'Folder', type: MapGroupType.city)
    ], maps: [
      initial.manifest.maps.single.copyWith(groupId: 'folder')
    ]);
    final result = const MapLifecycleActions().analyze(catalogContext(
        catalogSnapshot([source], project: project),
        'map.duplicate',
        {'sourceMapId': 'source', 'groupId': null}));
    expect(result.canApply, isTrue);
    expect(result.preview['groupId'], isNull);
  });
}
