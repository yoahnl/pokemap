import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/domains/maps/spatial_map_actions.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../support/glb_fixture.dart';

void main() {
  test('discovers the bounded one-map instance batch contract', () {
    final descriptor = SpatialMapActions.descriptors
        .singleWhere((action) => action.id == 'map3d.instance.upsert_batch');
    expect(descriptor.version, 1);
    expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
    expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
    final schema = descriptor.extensions['inputSchema'] as Map;
    expect(schema['required'], ['mapId', 'instances']);
    final instances = (schema['properties'] as Map)['instances'] as Map;
    expect(instances['minItems'], 1);
    expect(instances['maxItems'], 50);
  });

  test('upserts a bounded set once while preserving other authored state', () {
    final fixture =
        _fixture(instances: [_instance('existing'), _instance('keep')]);
    final moved = _instance('existing', x: 2.5, z: 1.5).toJson();
    final added = _instance('new', x: 1.25, z: 2.75).toJson();
    final draft = _build(fixture.snapshot, [moved, added]);
    final after = _map(draft);
    expect(after.spatialScene!.instances.map((item) => item.id),
        ['existing', 'keep', 'new']);
    expect(after.spatialScene!.instances.first.position,
        Model3dVector3(x: 2.5, y: 2.25, z: 1.5));
    expect(after.spatialScene!.instances[1],
        fixture.map.spatialScene!.instances[1]);
    expect(after.spatialScene!.heightLevels,
        fixture.map.spatialScene!.heightLevels);
    expect(
        after.spatialScene!.navigation, fixture.map.spatialScene!.navigation);
    expect(after.spatialScene!.camera, fixture.map.spatialScene!.camera);
    expect(after.entities, fixture.map.entities);
    expect(after.layers, fixture.map.layers);
    expect(after.properties, fixture.map.properties);
    expect(draft.changeSet.changes, hasLength(1));
    expect(draft.changeSet.changes.single.resource.id, 'map');
    expect(draft.preview['changedInstanceCount'], 2);
    expect(draft.preview['batchAtomicity'], 'all_or_nothing');
  });

  test('counts unchanged placements only once and preserves animation settings',
      () {
    final fixture = _fixture(instances: [_instance('keep')]);
    final draft = _build(fixture.snapshot,
        [_instance('keep').toJson(), _instance('animated').toJson()]);
    final added = _map(draft).spatialScene!.instances.last;
    expect(draft.preview['changedInstanceCount'], 1);
    expect(added.animationIndex, 0);
    expect(added.animationLoop, isFalse);
    expect(added.animationSpeed, .5);
    expect(added.rotationDegrees, 90);
    expect(added.scale, 1.5);
    expect(added.blocksMovement, isFalse);
  });

  test('accepts fifty valid distinct instances in one resource change', () {
    final draft = _build(_fixture().snapshot,
        [for (var i = 0; i < 50; i++) _instance('placed-$i').toJson()]);
    expect(_map(draft).spatialScene!.instances, hasLength(50));
    expect(draft.changeSet.changes, hasLength(1));
  });

  test('rejects duplicate instance IDs even when placements are identical', () {
    expect(
        () => _build(_fixture().snapshot,
            [_instance('duplicate').toJson(), _instance('duplicate').toJson()]),
        _throwsCode('map3d.instance.batch_duplicate'));
  });

  test('requires a non-empty batch with no more than fifty instances', () {
    expect(() => _build(_fixture().snapshot, []),
        _throwsCode('map3d.parameters_invalid'));
    expect(
        () => _build(_fixture().snapshot,
            [for (var i = 0; i < 51; i++) _instance('placed-$i').toJson()]),
        _throwsCode('map3d.instance.batch_too_large'));
  });

  final invalid = <String, Object?>{
    'non-object': 'placed',
    'missing ID': {..._instance('bad').toJson()}..remove('id'),
    'invalid ID': {..._instance('bad').toJson(), 'id': 'bad id'},
    'missing position': {..._instance('bad').toJson()}..remove('position'),
    'unknown instance field': {
      ..._instance('bad').toJson(),
      'mapId': 'another'
    },
    'unknown position field': {
      ..._instance('bad').toJson(),
      'position': {'x': 0, 'y': 1, 'z': 0, 'extra': true}
    },
    'out of map': {
      ..._instance('bad').toJson(),
      'position': {'x': 4, 'y': 1, 'z': 0}
    },
    'non-finite position': {
      ..._instance('bad').toJson(),
      'position': {'x': double.nan, 'y': 1, 'z': 0}
    },
    'invalid scale': {..._instance('bad').toJson(), 'scale': 0},
    'invalid animation speed': {
      ..._instance('bad').toJson(),
      'animationSpeed': 17
    },
  };
  for (final entry in invalid.entries) {
    test('rejects a trailing ${entry.key} without any write', () {
      final fixture = _fixture();
      final before = fixture.snapshot.resourceBytes('map:map').toList();
      expect(
          () => _build(
              fixture.snapshot, [_instance('valid').toJson(), entry.value]),
          entry.key == 'non-finite position'
              ? throwsArgumentError
              : _throwsCode('map3d.parameters_invalid'));
      expect(fixture.snapshot.resourceBytes('map:map'), before);
      expect(fixture.map.spatialScene!.instances, isEmpty);
    });
  }

  test('rejects a missing source model before planning any placement', () {
    expect(
        () => _build(_fixture().snapshot, [
              _instance('valid').toJson(),
              {..._instance('bad').toJson(), 'modelId': 'missing'},
            ]),
        _throwsCode('map3d.instance.model_not_found'));
  });

  test('rejects an animation outside the inspected model clips', () {
    expect(
        () => _build(_fixture().snapshot, [
              _instance('valid').toJson(),
              {..._instance('bad').toJson(), 'animationIndex': 99},
            ]),
        _throwsCode('map3d.instance.animation_invalid'));
  });

  test('rejects dimension mixing', () {
    expect(
        () => _build(
            _fixture(spatial: false).snapshot, [_instance('valid').toJson()]),
        _throwsCode('map3d.dimension_required'));
  });
}

Matcher _throwsCode(String code) => throwsA(
    isA<MapAuthoringException>().having((error) => error.code, 'code', code));

SpatialModelInstance _instance(String id, {num x = .5, num z = .5}) =>
    SpatialModelInstance(
      id: id,
      modelId: 'house',
      position: Model3dVector3(x: x, y: 2.25, z: z),
      animationIndex: 0,
      animationLoop: false,
      animationSpeed: .5,
      rotationDegrees: 90,
      scale: 1.5,
      blocksMovement: false,
    );

AuthoringMutationDraft _build(
        ProjectSnapshot snapshot, List<Object?> instances) =>
    const SpatialMapActions().build(AuthoringPlanningContext(
      snapshot: snapshot,
      planId: 'batch-plan',
      seed: 17,
      request: AuthoringRequest(
          requestId: 'instance-batch',
          actionId: 'map3d.instance.upsert_batch',
          actionVersion: 1,
          workspaceHandle: 'workspace:batch',
          expectedRevision: snapshot.revision,
          idempotencyKey: 'instance-batch',
          parameters: {'mapId': 'map', 'instances': instances}),
    ));

MapData _map(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);

({ProjectSnapshot snapshot, MapData map}) _fixture({
  List<SpatialModelInstance> instances = const [],
  bool spatial = true,
}) {
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    size: const GridSize(width: 4, height: 4),
    spatialScene: spatial
        ? MapSpatialScene(
            width: 4,
            depth: 4,
            heightLevels: List.filled(16, 2),
            levelHeight: 1,
            navigation:
                SpatialNavigationProfile(spawn: SpatialSpawn(x: 2, z: 2)),
            instances: instances)
        : null,
    properties: const {'custom': 'preserved'},
    layers: [
      CollisionLayer(
          id: 'blocked', name: 'Collisions', collisions: List.filled(16, false))
    ],
    entities: const [
      MapEntity(
          id: 'start',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 2, y: 2),
          blocksMovement: false,
          spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart))
    ],
  );
  final manifest = ProjectManifest(
    name: 'Instance batch',
    tilesets: const [],
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    settings: spatial
        ? ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile())
        : const ProjectSettings(),
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
    ],
    models3d: [
      ProjectModel3dEntry(
          id: 'house',
          name: 'House',
          sourceAssetId: 'model3d_house',
          relativePath: 'assets/models3d/house.glb',
          inspection: const GlbModel3dInspector().inspect(animatedGlb()))
    ],
  );
  final projectBytes = utf8.encode(jsonEncode(manifest.toJson()));
  final mapBytes = utf8.encode(jsonEncode(map.toJson()));
  return (
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project:batch'),
      revision:
          computeAuthoringBytesFingerprint(mapBytes, logicalName: 'snapshot'),
      manifest: manifest,
      maps: [map],
      resourceBytes: {'project': projectBytes, 'map:map': mapBytes},
      resourceFingerprints: {
        'project': computeAuthoringBytesFingerprint(projectBytes,
            logicalName: 'project.json'),
        'map:map': computeAuthoringBytesFingerprint(mapBytes,
            logicalName: 'maps/map.json'),
      },
      resourceStorageKeys: const {
        'project': 'project.json',
        'map:map': 'maps/map.json'
      },
    )
  );
}
