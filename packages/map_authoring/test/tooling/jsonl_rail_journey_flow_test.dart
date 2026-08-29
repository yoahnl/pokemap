import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('direct API and JSONL upsert, query and delete RailJourneys', () async {
    final setup = await _RailJourneySetup.create();
    addTearDown(setup.dispose);

    final opened = await setup.readApi.openProject(setup.root.path);
    await setup.mutations.attachProject(
      projectRootPath: setup.root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    final before = await setup.snapshots.load(opened.projectHandle);
    final createPlan = await setup.mutations.planMutation(
      opened.projectHandle,
      AuthoringRequest(
        requestId: 'direct-rail-create',
        actionId: 'rail_journey.upsert',
        actionVersion: 1,
        workspaceHandle: opened.workspaceHandle.value,
        parameters: <String, Object?>{'journey': _journey.toJson()},
        expectedRevision: before.revision,
        idempotencyKey: 'direct-rail-create-v1',
      ),
    );

    expect(
        createPlan.plan.preview, containsPair('resourceKind', 'railJourney'));
    final createApply = await setup.mutations.applyMutation(
      opened.projectHandle,
      planId: createPlan.plan.planId,
      operationId: 'direct-rail-create-operation',
    );
    expect(createApply.receipt.status, AuthoringReceiptStatus.applied);

    final queried = await setup.request(
      'query',
      args: <String, Object?>{
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringQueryRequest(
          resourceKind: 'railJourney',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['T1'],
          view: AuthoringQueryView.detail,
        ).toJson(),
      },
    );
    expect(queried.status, AuthoringResultStatus.success);
    final queriedItems = (queried.data['items']! as List).cast<Map>();
    expect(queriedItems.single['id'], 'T1');
    expect(queriedItems.single['resourceKind'], 'railJourney');

    final created = await setup.snapshots.load(opened.projectHandle);
    final deletePlan = await setup.request(
      'plan',
      args: <String, Object?>{
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'jsonl-rail-delete',
          actionId: 'rail_journey.delete',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: const <String, Object?>{'journeyId': 'T1'},
          expectedRevision: created.revision,
          idempotencyKey: 'jsonl-rail-delete-v1',
        ).toJson(),
      },
    );
    expect(deletePlan.status, AuthoringResultStatus.success);
    final confirmation = await setup.request(
      'confirm',
      args: <String, Object?>{
        'projectHandle': opened.projectHandle.value,
        'planId': deletePlan.data['planId'],
      },
    );
    expect(confirmation.status, AuthoringResultStatus.success);

    final deleteApply = await setup.request(
      'apply',
      args: <String, Object?>{
        'projectHandle': opened.projectHandle.value,
        'planId': deletePlan.data['planId'],
        'operationId': 'jsonl-rail-delete-operation',
        'confirmationToken': confirmation.data['confirmationToken'],
      },
    );
    expect(deleteApply.status, AuthoringResultStatus.success);
    expect(
      (await setup.snapshots.load(opened.projectHandle))
          .manifest
          .railJourneyCatalog,
      isNull,
    );

    final afterDelete = await setup.snapshots.load(opened.projectHandle);
    final invalid = await setup.request(
      'plan',
      args: <String, Object?>{
        'projectHandle': opened.projectHandle.value,
        'request': AuthoringRequest(
          requestId: 'jsonl-rail-invalid',
          actionId: 'rail_journey.upsert',
          actionVersion: 1,
          workspaceHandle: opened.workspaceHandle.value,
          parameters: <String, Object?>{
            'journey': _journey
                .copyWith(
                  origin: _journey.origin.copyWith(
                    stationMapId: 'map_unknown_station',
                  ),
                )
                .toJson(),
          },
          expectedRevision: afterDelete.revision,
          idempotencyKey: 'jsonl-rail-invalid-v1',
        ).toJson(),
      },
    );
    expect(invalid.status, AuthoringResultStatus.failure);
    expect(invalid.error?.code, AuthoringErrorCode.validationFailed);
    expect(
      invalid.error?.details['domainCode'],
      'rail_journey.map_unknown',
    );
  });
}

final class _RailJourneySetup {
  const _RailJourneySetup({
    required this.root,
    required this.readApi,
    required this.mutations,
    required this.snapshots,
    required this.worker,
  });

  final Directory root;
  final AuthoringReadApi readApi;
  final LocalMapAuthoringMutationApi mutations;
  final ProjectSnapshotLoader snapshots;
  final JsonlWorker worker;

  static Future<_RailJourneySetup> create() async {
    final root = await Directory.systemTemp.createTemp('jsonl-rail-journey-');
    await Directory('${root.path}/maps').create(recursive: true);
    await File('${root.path}/project.json').writeAsString(
      const JsonEncoder.withIndent('  ').convert(_manifest.toJson()),
      flush: true,
    );
    for (final map in _maps) {
      await File('${root.path}/maps/${map.id}.json').writeAsBytes(
        encodeMapAuthoringDocument(map),
        flush: true,
      );
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: <String>[root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final readApi = AuthoringReadApi(
      openService: ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
      ),
      snapshotLoader: snapshots,
    );
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    return _RailJourneySetup(
      root: root,
      readApi: readApi,
      mutations: mutations,
      snapshots: snapshots,
      worker: JsonlWorker(api: readApi, mutations: mutations),
    );
  }

  Future<AuthoringResult> request(
    String command, {
    Map<String, Object?> args = const <String, Object?>{},
  }) async {
    final decoded = jsonDecode(
      await worker.processLine(
        jsonEncode(<String, Object?>{
          'id': 'jsonl-rail-$command',
          'command': command,
          'args': args,
        }),
      ),
    ) as Map<String, dynamic>;
    return AuthoringResult.fromJson(decoded);
  }

  Future<void> dispose() async {
    if (await root.exists()) {
      await root.delete(recursive: true);
    }
  }
}

const _doorFrames = <TilesetVisualFrame>[
  TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0), durationMs: 120),
  TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0), durationMs: 120),
];

const _manifest = ProjectManifest(
  name: 'Rail authoring transport fixture',
  maps: <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'map_origin_station',
      name: 'Origin station',
      relativePath: 'maps/map_origin_station.json',
    ),
    ProjectMapEntry(
      id: 'map_destination_station',
      name: 'Destination station',
      relativePath: 'maps/map_destination_station.json',
    ),
    ProjectMapEntry(
      id: 'map_train_car',
      name: 'Train car',
      relativePath: 'maps/map_train_car.json',
      role: MapRole.interior,
    ),
  ],
  tilesets: <ProjectTilesetEntry>[
    ProjectTilesetEntry(
      id: 'doors',
      name: 'Doors',
      relativePath: 'tilesets/doors.png',
    ),
  ],
  elementCategories: <ProjectElementCategory>[
    ProjectElementCategory(id: 'doors', name: 'Doors'),
  ],
  elements: <ProjectElementEntry>[
    ProjectElementEntry(
      id: 'element_station_west',
      name: 'Station west door',
      tilesetId: 'doors',
      categoryId: 'doors',
      frames: _doorFrames,
    ),
    ProjectElementEntry(
      id: 'element_station_east',
      name: 'Station east door',
      tilesetId: 'doors',
      categoryId: 'doors',
      frames: _doorFrames,
    ),
    ProjectElementEntry(
      id: 'element_vehicle_west',
      name: 'Vehicle west door',
      tilesetId: 'doors',
      categoryId: 'doors',
      frames: _doorFrames,
    ),
    ProjectElementEntry(
      id: 'element_vehicle_east',
      name: 'Vehicle east door',
      tilesetId: 'doors',
      categoryId: 'doors',
      frames: _doorFrames,
    ),
  ],
);

const _maps = <MapData>[
  MapData(
    id: 'map_origin_station',
    name: 'Origin station',
    size: GridSize(width: 10, height: 10),
    layers: <MapLayer>[MapLayer.object(id: 'doors', name: 'Doors')],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_origin_west',
        layerId: 'doors',
        elementId: 'element_station_west',
        pos: GridPos(x: 2, y: 3),
      ),
    ],
  ),
  MapData(
    id: 'map_destination_station',
    name: 'Destination station',
    size: GridSize(width: 10, height: 10),
    layers: <MapLayer>[MapLayer.object(id: 'doors', name: 'Doors')],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_destination_east',
        layerId: 'doors',
        elementId: 'element_station_east',
        pos: GridPos(x: 4, y: 2),
      ),
    ],
  ),
  MapData(
    id: 'map_train_car',
    name: 'Train car',
    size: GridSize(width: 10, height: 10),
    layers: <MapLayer>[MapLayer.object(id: 'doors', name: 'Doors')],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'door_vehicle_west',
        layerId: 'doors',
        elementId: 'element_vehicle_west',
        pos: GridPos(x: 1, y: 4),
      ),
      MapPlacedElement(
        id: 'door_vehicle_east',
        layerId: 'doors',
        elementId: 'element_vehicle_east',
        pos: GridPos(x: 6, y: 4),
      ),
    ],
  ),
];

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
    doors: <RailJourneyEndpointDoor>[
      RailJourneyEndpointDoor(
        side: RailJourneyDoorSide.west,
        stationPlacedElementId: 'door_origin_west',
        vehiclePlacedElementId: 'door_vehicle_west',
      ),
    ],
  ),
  destination: RailJourneyEndpoint(
    stationMapId: 'map_destination_station',
    boardingArea: MapRect(
      pos: GridPos(x: 4, y: 2),
      size: GridSize(width: 2, height: 3),
    ),
    trainEntryPos: GridPos(x: 6, y: 4),
    stationArrivalPos: GridPos(x: 7, y: 6),
    doors: <RailJourneyEndpointDoor>[
      RailJourneyEndpointDoor(
        side: RailJourneyDoorSide.east,
        stationPlacedElementId: 'door_destination_east',
        vehiclePlacedElementId: 'door_vehicle_east',
      ),
    ],
  ),
  vehicleMapId: 'map_train_car',
  vehicleVariant: RailJourneyVehicleVariant.regular,
  shellState: 'day',
  fare: RailJourneyFare(policy: RailJourneyFarePolicy.storyFree),
);
