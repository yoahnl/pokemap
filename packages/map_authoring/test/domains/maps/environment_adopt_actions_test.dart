import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../assets/resource_library_actions_test.dart' show librarySnapshot;
import 'environment_spatial_actions_test.dart' show spatialEnvironmentFixture;

void main() {
  test(
      'adopting existing spatial models preserves exact instances and references',
      () async {
    final fixture = spatialEnvironmentFixture();
    final instance = SpatialModelInstance(
        id: 'old-tree',
        modelId: 'tree',
        position: Model3dVector3(x: 1.25, y: 3, z: 2.125),
        scale: .8,
        rotationDegrees: 25,
        blocksMovement: false,
        castsShadows: false);
    final map = fixture.map.copyWith(properties: {
      'keep': 'value'
    }, spatialScene: fixture.map.spatialScene!.copyWith(instances: [instance]));
    final draft = await _build(fixture.project, map, ['old-tree']);
    final result = MapData.fromJson(
        jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
            as Map<String, dynamic>);
    expect(result.spatialScene!.instances, [instance]);
    expect(result.properties, map.properties);
    final area =
        (result.layers.single as EnvironmentLayer).content.areas.single;
    expect(area.generatedPlacementIds, ['old-tree']);
    expect(area.manualPlacementIds, ['old-tree']);
    expect(area.mask,
        (map.layers.single as EnvironmentLayer).content.areas.single.mask);
    expect(draft.changeSet.changes.single.storageKey, 'maps/map.json');
  });

  for (final ids in <List<String>>[
    [],
    ['missing'],
    ['old-tree', 'old-tree'],
    ['old-tree', 'missing'],
    List.generate(251, (i) => 'tree-$i')
  ]) {
    test(
        'invalid adoption is rejected atomically for ${ids.length} requested IDs',
        () async {
      final fixture = spatialEnvironmentFixture();
      final instance = SpatialModelInstance(
          id: 'old-tree',
          modelId: 'tree',
          position: Model3dVector3(x: 1, y: 1, z: 1));
      final map = fixture.map.copyWith(
          spatialScene:
              fixture.map.spatialScene!.copyWith(instances: [instance]));
      final before = jsonEncode(map.toJson());
      await expectLater(
          _build(fixture.project, map, ids), throwsA(isA<Exception>()));
      expect(jsonEncode(map.toJson()), before);
    });
  }

  test('an existing Environment owner cannot be stolen', () async {
    final fixture = spatialEnvironmentFixture();
    final instance = SpatialModelInstance(
        id: 'owned',
        modelId: 'tree',
        position: Model3dVector3(x: 1, y: 1, z: 1));
    final map = fixture.map.copyWith(
        spatialScene: fixture.map.spatialScene!.copyWith(instances: [instance]),
        layers: [
          MapLayer.environment(
              id: 'env',
              name: 'Forest',
              content:
                  EnvironmentLayerContent(targetsSpatialTerrain: true, areas: [
                EnvironmentArea(
                    id: 'forest',
                    name: 'Forest',
                    presetId: 'forest',
                    seed: 1,
                    mask: EnvironmentAreaMask(
                        width: 6, height: 4, cells: List.filled(24, false)),
                    generatedPlacementIds: ['owned'],
                    manualPlacementIds: ['owned'])
              ]))
        ]);
    await expectLater(
        _build(fixture.project, map, ['owned']), throwsA(isA<Exception>()));
  });

  test(
      'a model outside the target palette is rejected without changing the map',
      () async {
    final fixture = spatialEnvironmentFixture();
    final instance = SpatialModelInstance(
        id: 'foreign-model',
        modelId: 'other',
        position: Model3dVector3(x: 1, y: 1, z: 1));
    final map = fixture.map.copyWith(
        spatialScene:
            fixture.map.spatialScene!.copyWith(instances: [instance]));
    final before = jsonEncode(map.toJson());
    await expectLater(
        _build(fixture.project, map, ['foreign-model']),
        throwsA(isA<MapAuthoringException>().having(
            (e) => e.code, 'code', 'environment.element_not_in_palette')));
    expect(jsonEncode(map.toJson()), before);
  });

  test('the scene boundary already rejects out of bounds existing anchors', () {
    final fixture = spatialEnvironmentFixture();
    final instance = SpatialModelInstance(
        id: 'outside',
        modelId: 'tree',
        position: Model3dVector3(x: 6, y: 1, z: 1));
    expect(() => fixture.map.spatialScene!.copyWith(instances: [instance]),
        throwsFormatException);
  });

  test('NPC movement areas survive the strict authoring result envelope', () {
    final map = MapData(id: 'map', name: 'Map', size: const GridSize(width: 4, height: 4), entities: const [MapEntity(id: 'npc', name: 'NPC', kind: MapEntityKind.npc, pos: GridPos(x: 1, y: 1), size: GridSize(width: 1, height: 1), npc: MapEntityNpcData(displayName: 'NPC', movement: MapEntityNpcMovementConfig(mode: MapEntityNpcMovementMode.idle, movementArea: MapRect(pos: GridPos(x: 0, y: 0), size: GridSize(width: 3, height: 3))))) ]);
    expect(() => AuthoringResult.success(requestId: 'movement-area', data: {'maps': [map.toJson()]}), returnsNormally);
  });

  test('adoption is discoverable through the canonical dispatcher', () {
    expect(MapMutationDispatcher.canonical().descriptors.map((d) => d.id),
        contains('environment.generated_placement_adopt_batch'));
  });
}

Future<AuthoringMutationDraft> _build(
        ProjectManifest project, MapData map, List<String> ids) async =>
    MapMutationDispatcher.canonical().build(AuthoringPlanningContext(
        snapshot: librarySnapshot([map], project: project),
        request: AuthoringRequest(
            requestId: 'adopt',
            actionId: 'environment.generated_placement_adopt_batch',
            actionVersion: 1,
            workspaceHandle: 'workspace',
            parameters: {
              'mapId': map.id,
              'layerId': 'env',
              'areaId': 'forest',
              'placementIds': ids
            },
            idempotencyKey: 'adopt'),
        planId: 'plan-adopt',
        seed: 1));
