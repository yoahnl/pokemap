import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:map_core/map_core.dart';
import 'package:map_distribution/map_distribution.dart';
import 'package:test/test.dart';

import 'support/spatial_package_fixture.dart';

void editMap(
    Map<String, List<int>> files, String id, MapData Function(MapData) edit) {
  final path = 'project/maps/$id.json';
  final map = MapData.fromJson(jsonDecode(utf8.decode(files[path]!)));
  files[path] = utf8.encode(jsonEncode(edit(map).toJson()));
}

Map<String, List<int>> connectedFiles(
    MapConnectionDirection direction, int offset) {
  final files = spatialPassagePayload();
  editMap(
      files,
      'map',
      (map) => map.copyWith(warps: [], connections: [
            MapConnection(
                direction: direction, targetMapId: 'room', offset: offset)
          ], spatialScene: map.spatialScene!.copyWith(instances: [])));
  editMap(
      files,
      'room',
      (map) => map.copyWith(warps: [], connections: [
            MapConnection(
                direction: direction.opposite,
                targetMapId: 'map',
                offset: -offset)
          ]));
  return files;
}

void main() {
  for (final direction in MapConnectionDirection.values) {
    test('closed connected border permits different heights ${direction.name}',
        () {
      final files = connectedFiles(direction, 0);
      final source = switch (direction) {
        MapConnectionDirection.north => const GridPos(x: 0, y: 0),
        MapConnectionDirection.south => const GridPos(x: 0, y: 7),
        MapConnectionDirection.east => const GridPos(x: 7, y: 0),
        MapConnectionDirection.west => const GridPos(x: 0, y: 0),
      };
      final target = switch (direction) {
        MapConnectionDirection.north => const GridPos(x: 0, y: 7),
        MapConnectionDirection.south => const GridPos(x: 0, y: 0),
        MapConnectionDirection.east => const GridPos(x: 0, y: 0),
        MapConnectionDirection.west => const GridPos(x: 7, y: 0),
      };
      for (final entry in [('map', source), ('room', target)]) {
        editMap(files, entry.$1, (map) {
          final scene = map.spatialScene!;
          final levels = [...scene.heightLevels];
          if (entry.$1 == 'room') levels[entry.$2.y * 8 + entry.$2.x] = 2;
          return map.copyWith(
              spatialScene: scene.copyWith(
                  heightLevels: levels,
                  navigation: scene.navigation.copyWith(blockedAreas: [
                    ...scene.navigation.blockedAreas,
                    SpatialBlockedArea(
                        x: entry.$2.x.toDouble(),
                        z: entry.$2.y.toDouble(),
                        width: 1,
                        depth: 1)
                  ])));
        });
      }
      final built = const GamePackageBuilder()
          .build(manifest: spatialManifest(), payloadFiles: files);
      expect(const GamePackageInspector().inspect(built.packageBytes).payloadPaths,
          contains('project/maps/room.json'));
    });
  }
  for (final blocking in ['source only', 'target only', 'partial both']) {
    test('unequal connected heights remain rejected with $blocking', () {
      final files = connectedFiles(MapConnectionDirection.east, 0);
      for (final id in ['map', 'room']) {
        editMap(files, id, (map) {
          final scene = map.spatialScene!;
          final levels = [...scene.heightLevels];
          if (id == 'room') levels[0] = 2;
          final block = blocking == 'partial both' ||
              blocking == 'source only' && id == 'map' ||
              blocking == 'target only' && id == 'room';
          return map.copyWith(
              spatialScene: scene.copyWith(
                  heightLevels: levels,
                  navigation: scene.navigation.copyWith(blockedAreas: [
                    ...scene.navigation.blockedAreas,
                    if (block)
                      SpatialBlockedArea(
                          x: id == 'map' ? 7 : 0,
                          z: 0,
                          width: blocking == 'partial both' ? .75 : 1,
                          depth: 1)
                  ])));
        });
      }
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having((error) => error.code,
              'code', 'runtime3d.connection_height_mismatch')));
    });
  }
  for (final direction in MapConnectionDirection.values) {
    for (final offset in [-2, 2]) {
      test(
          '${direction.name} connections offset $offset survive archive roundtrip',
          () {
        final files = connectedFiles(direction, offset);
        final built = const GamePackageBuilder()
            .build(manifest: spatialManifest(), payloadFiles: files);
        final inspected =
            const GamePackageInspector().inspect(built.packageBytes);
        expect(inspected.payloadPaths, contains('project/maps/room.json'));
        final archive = ZipDecoder().decodeBytes(built.packageBytes);
        for (final id in ['map', 'room']) {
          final original = MapData.fromJson(
              jsonDecode(utf8.decode(files['project/maps/$id.json']!)));
          final restored = MapData.fromJson(jsonDecode(
              utf8.decode(archive.findFile('project/maps/$id.json')!.content)));
          expect(restored, original);
          expect(restored.warps, isEmpty);
          expect(restored.connections.single.offset,
              id == 'map' ? offset : -offset);
        }
      });
    }
  }
  for (final failure in ['missing destination', 'no overlap', 'height jump']) {
    test('rejects connection $failure', () {
      final files = connectedFiles(MapConnectionDirection.east, 0);
      if (failure == 'height jump') {
        editMap(
            files,
            'room',
            (map) => map.copyWith(
                spatialScene: map.spatialScene!
                    .copyWith(heightLevels: List.filled(64, 2))));
      } else {
        editMap(
            files,
            'map',
            (map) => map.copyWith(connections: [
                  map.connections.single.copyWith(
                      targetMapId:
                          failure == 'missing destination' ? 'absent' : 'room',
                      offset: failure == 'no overlap' ? 8 : 0)
                ]));
      }
      expect(
          () => const GamePackageBuilder()
              .build(manifest: spatialManifest(), payloadFiles: files),
          throwsA(isA<GamePackageFormatException>().having(
              (error) => error.code,
              'code',
              switch (failure) {
                'missing destination' => 'runtime3d.connection_target_missing',
                'no overlap' => 'runtime3d.connection_no_overlap',
                _ => 'runtime3d.connection_height_mismatch',
              })));
    });
  }
}
