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
