import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('MapLifecycleActions', () {
    test('advertises the complete canonical lifecycle mutation set', () {
      expect(
        MapLifecycleActions.descriptors.map((action) => action.id),
        [
          'map.create',
          'map.delete_apply',
          'map.duplicate',
          'map.rename',
          'map.resize_apply',
          'map.save',
        ],
      );
      for (final descriptor in MapLifecycleActions.descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
        expect(
          descriptor.guarantees,
          contains(AuthoringGuarantee.revisionChecked),
        );
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      }
    });

    test('creates an editor-compatible map and manifest in one draft', () {
      final snapshot = _snapshot();
      final request = _request(
        snapshot,
        actionId: 'map.create',
        parameters: const {
          'mapId': 'route_01',
          'name': 'Route 01',
          'width': 4,
          'height': 3,
          'role': 'exterior',
        },
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      expect(
        draft.changeSet.changes.map((change) => change.resource.toJson()),
        [
          {'kind': 'map', 'id': 'route_01'},
          {
            'kind': 'project',
            'id': 'project',
            'revision': snapshot.resourceFingerprints['project'],
          },
        ],
      );
      final mapChange = draft.changeSet.changes.first;
      final created = MapData.fromJson(
        jsonDecode(utf8.decode(mapChange.afterBytes!)) as Map<String, dynamic>,
      );
      expect(created.id, 'route_01');
      expect(created.name, 'Route 01');
      expect(created.size, const GridSize(width: 4, height: 3));
      expect(
        created.layers.map((layer) => layer.id),
        ['l_base', 'l_terrain', 'l_collisions'],
      );
      expect((created.layers[0] as TileLayer).tiles, hasLength(12));
      expect((created.layers[1] as TerrainLayer).terrains, hasLength(12));
      expect(
        (created.layers[2] as CollisionLayer).collisions,
        hasLength(12),
      );
      expect(
        utf8.decode(mapChange.afterBytes!),
        const JsonEncoder.withIndent('  ').convert(created.toJson()),
      );
      expect(draft.preview, containsPair('mapId', 'route_01'));
      expect(draft.preview, containsPair('operation', 'create'));
    });

    test('saves a validated full map against its exact disk pre-image', () {
      final original = _map('town', width: 3, height: 2);
      final snapshot = _snapshot(maps: [original]);
      final updated = original.copyWith(name: 'Town Updated');
      final request = _request(
        snapshot,
        actionId: 'map.save',
        parameters: {'map': updated.toJson()},
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      expect(draft.changeSet.changes, hasLength(1));
      final change = draft.changeSet.changes.single;
      expect(change.storageKey, 'maps/town.json');
      expect(change.beforeBytes, snapshot.resourceBytes('map:town'));
      expect(
        MapData.fromJson(
          jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
        ).name,
        'Town Updated',
      );
    });

    test('duplicates a map without changing the source document', () {
      final source = _map('town', width: 2, height: 2);
      final snapshot = _snapshot(maps: [source]);
      final request = _request(
        snapshot,
        actionId: 'map.duplicate',
        parameters: const {'sourceMapId': 'town'},
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      final mapChange = draft.changeSet.changes
          .singleWhere((change) => change.resource.kind == 'map');
      expect(mapChange.resource.id, 'town_copy');
      expect(mapChange.beforeBytes, isNull);
      expect(mapChange.storageKey, 'maps/town_copy.json');
      expect(
        MapData.fromJson(
          jsonDecode(utf8.decode(mapChange.afterBytes!))
              as Map<String, dynamic>,
        ).id,
        'town_copy',
      );
    });

    test('refuses rename and delete while another map references the target',
        () {
      final target = _map('target');
      final owner = _map('owner').copyWith(
        warps: const [
          MapWarp(
            id: 'warp_to_target',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'target',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final snapshot = _snapshot(maps: [owner, target]);

      for (final request in [
        _request(
          snapshot,
          actionId: 'map.rename',
          parameters: const {'mapId': 'target', 'newMapId': 'target_new'},
        ),
        _request(
          snapshot,
          actionId: 'map.delete_apply',
          parameters: const {'mapId': 'target'},
        ),
      ]) {
        expect(
          () => const MapLifecycleActions().build(
            _context(snapshot, request),
          ),
          throwsA(
            isA<MapAuthoringException>()
                .having(
                  (error) => error.code,
                  'code',
                  'map.references_blocking',
                )
                .having(
                  (error) => error.details['dependentCount'],
                  'dependentCount',
                  1,
                ),
          ),
        );
      }
    });

    test('previews resize impacts and refuses lossy shrinking', () {
      final original = _map('field', width: 3, height: 2).copyWith(
        layers: [
          MapLayer.tile(
            id: 'l_base',
            name: 'Base',
            tiles: const [0, 0, 7, 0, 0, 0],
          ),
          MapLayer.terrain(
            id: 'l_terrain',
            name: 'Terrain',
            terrains: List<TerrainType>.filled(6, TerrainType.none),
          ),
          MapLayer.collision(
            id: 'l_collisions',
            name: 'Collisions',
            collisions: List<bool>.filled(6, false),
          ),
        ],
      );
      final snapshot = _snapshot(maps: [original]);
      final request = _request(
        snapshot,
        actionId: 'map.resize_apply',
        parameters: const {'mapId': 'field', 'width': 2, 'height': 2},
      );

      expect(
        () => const MapLifecycleActions().build(
          _context(snapshot, request),
        ),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'map.resize_impacts',
              )
              .having(
                (error) => error.details['impactCount'],
                'impactCount',
                1,
              ),
        ),
      );
    });

    test('renames a reference-free map with one recoverable three-file set',
        () {
      final original = _map('legacy_name');
      final snapshot = _snapshot(maps: [original]);
      final request = _request(
        snapshot,
        actionId: 'map.rename',
        parameters: const {
          'mapId': 'legacy_name',
          'newMapId': 'better_name',
          'name': 'Better Name',
        },
      );

      final draft = const MapLifecycleActions().build(
        _context(snapshot, request),
      );

      expect(draft.changeSet.changes, hasLength(3));
      expect(
        draft.changeSet.changes.map((change) => change.storageKey),
        ['maps/better_name.json', 'maps/legacy_name.json', 'project.json'],
      );
      expect(
        draft.changeSet.changes
            .singleWhere(
                (change) => change.storageKey == 'maps/legacy_name.json')
            .afterBytes,
        isNull,
      );
      expect(draft.referenceImpact['dependentCount'], 0);
    });
  });
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) {
  return AuthoringPlanningContext(
    snapshot: snapshot,
    request: request,
    planId: 'plan_test',
    seed: 42,
  );
}

AuthoringRequest _request(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) {
  return AuthoringRequest(
    requestId: 'request_test',
    actionId: actionId,
    actionVersion: 1,
    workspaceHandle: 'ws_test',
    parameters: parameters,
    expectedRevision: snapshot.revision,
    idempotencyKey: 'idem_test',
    dryRun: true,
  );
}

ProjectSnapshot _snapshot({List<MapData> maps = const []}) {
  final entries = [
    for (final map in maps)
      ProjectMapEntry(
        id: map.id,
        name: map.name,
        relativePath: 'maps/${map.id}.json',
      ),
  ];
  final manifest = ProjectManifest(
    name: 'Lifecycle Fixture',
    version: ProjectVersion.v3,
    maps: entries,
    tilesets: const [],
  );
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = {
    for (final map in maps) 'map:${map.id}': _encode(map.toJson()),
  };
  final revision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
    for (final map in maps)
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/${map.id}.json',
        bytes: mapBytes['map:${map.id}']!,
      ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_test'),
    revision: revision,
    manifest: manifest,
    maps: maps,
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
      ]),
      for (final map in maps)
        'map:${map.id}': computeNarrativeProjectFingerprint([
          NarrativeProjectFingerprintEntry(
            relativePath: 'maps/${map.id}.json',
            bytes: mapBytes['map:${map.id}']!,
          ),
        ]),
    },
    resourceBytes: {'project': manifestBytes, ...mapBytes},
  );
}

MapData _map(String id, {int width = 2, int height = 2}) {
  final count = width * height;
  return MapData(
    id: id,
    name: id,
    size: GridSize(width: width, height: height),
    version: ProjectVersion.v3,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.tile(
        id: 'l_base',
        name: 'Base',
        tiles: List<int>.filled(count, 0),
      ),
      MapLayer.terrain(
        id: 'l_terrain',
        name: 'Terrain',
        terrains: List<TerrainType>.filled(count, TerrainType.none),
      ),
      MapLayer.collision(
        id: 'l_collisions',
        name: 'Collisions',
        collisions: List<bool>.filled(count, false),
      ),
    ],
  );
}

List<int> _encode(Object? value) => utf8.encode(
      const JsonEncoder.withIndent('  ').convert(value),
    );
