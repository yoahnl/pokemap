import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void changeMap(
    Map<String, List<int>> files, String id, MapData Function(MapData) edit) {
  final path = 'project/maps/$id.json';
  final map = MapData.fromJson(jsonDecode(utf8.decode(files[path]!)));
  files[path] = utf8.encode(jsonEncode(edit(map).toJson()));
}

void main() {
  test('exports and inspects two 3D maps with authored starts and passages',
      () {
    final files = spatialPassagePayload();
    final built = const GamePackageBuilder()
        .build(manifest: spatialManifest(), payloadFiles: files);
    final inspected = const GamePackageInspector().inspect(built.packageBytes);
    expect(inspected.payloadPaths, contains('project/maps/room.json'));
    expect(inspected.manifest.compatibility.requiredCapabilities,
        contains('map3d@1'));
    final archive = ZipDecoder().decodeBytes(built.packageBytes);
    for (final id in ['map', 'room']) {
      final bytes = archive.findFile('project/maps/$id.json')!.content;
      final restored = MapData.fromJson(jsonDecode(utf8.decode(bytes)));
      final original = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/$id.json']!)));
      expect(restored, original);
      expect(restored.entities.single.spawn!.role, EntitySpawnRole.playerStart);
      expect(restored.entities.single.spawn!.facing, EntityFacing.north);
      expect(restored.warps.single.targetMapId, id == 'map' ? 'room' : 'map');
    }
  });

  for (final caseName in [
    'missing destination',
    'outside destination',
    '2D destination'
  ]) {
    test('rejects passage $caseName', () {
      final files = spatialPassagePayload();
      if (caseName == '2D destination') {
        changeMap(
            files,
            'room',
            (map) => map.copyWith(
                  version: ProjectVersion.v8,
                  spatialScene: null,
                ));
      } else {
        changeMap(
            files,
            'map',
            (map) => map.copyWith(warps: [
                  map.warps.single.copyWith(
                    targetMapId:
                        caseName == 'missing destination' ? 'absent' : 'room',
                    targetPos: caseName == 'outside destination'
                        ? const GridPos(x: 8, y: 2)
                        : const GridPos(x: 2, y: 2),
                  ),
                ]));
      }
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
            (error) => error.code,
            'code',
            caseName == 'missing destination'
                ? 'runtime3d.warp_target_missing'
                : caseName == 'outside destination'
                    ? 'runtime3d.warp_arrival_outside'
                    : 'runtime3d.invalid_project',
          )));
    });
  }

  test('rejects a default spawn key that cannot resolve to its entity id', () {
    final files = spatialPassagePayload();
    changeMap(
        files,
        'map',
        (map) => map.copyWith(
              entities: [
                map.entities.single.copyWith(
                  spawn: const MapEntitySpawnData(spawnKey: 'alias'),
                )
              ],
              mapMetadata: const MapMetadata(defaultSpawnId: 'alias'),
            ));
    expect(
      () => const GamePackageBuilder()
          .build(manifest: spatialManifest(), payloadFiles: files),
      throwsA(isA<GamePackageFormatException>().having(
        (error) => error.code,
        'code',
        'runtime3d.spawn_missing',
      )),
    );
  });

  for (final caseName in [
    'event spawn',
    'spawn properties',
    'spawn npc payload',
    'missing default start',
    'events'
  ]) {
    test('rejects unsupported $caseName', () {
      final files = spatialPassagePayload();
      changeMap(
          files,
          'map',
          (map) => switch (caseName) {
                'event spawn' => map.copyWith(entities: [
                    map.entities.single.copyWith(
                        spawn: const MapEntitySpawnData(
                            role: EntitySpawnRole.event)),
                  ]),
                'spawn properties' => map.copyWith(entities: [
                    map.entities.single.copyWith(properties: {'script': 'run'}),
                  ]),
                'spawn npc payload' => map.copyWith(entities: [
                    map.entities.single.copyWith(
                        npc: const MapEntityNpcData(characterId: 'hero')),
                  ]),
                'missing default start' => map.copyWith(
                    mapMetadata: const MapMetadata(defaultSpawnId: 'absent')),
                _ => map.copyWith(events: [
                    const MapEventDefinition(
                      id: 'event',
                      pages: [],
                      position: EventPosition(layerId: 'solid', x: 1, y: 1),
                    )
                  ]),
              });
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>()));
    });
  }
}
