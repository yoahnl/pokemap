import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('canonical export advertises and preserves continuous native terrain',
      () async {
    final root =
        await Directory.systemTemp.createTemp('terrain-surface-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    final before = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!))
            as Map<String, dynamic>);
    final surface = SpatialTerrainSurface(
        id: 'hill',
        x: 1,
        z: 1,
        height: 2,
        gradientX: .25,
        footprints: [
          BorderGroundFootprint(points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: 1, z: 0),
            BorderGroundPoint(x: 1, z: 1),
            BorderGroundPoint(x: 0, z: 1),
          ])
        ]);
    final changed =
        const SpatialMapOperations().upsertTerrainSurfaces(before, [surface]);
    files['project/maps/map.json'] = utf8.encode(jsonEncode(changed.toJson()));
    for (final entry in files.entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final originalMap = await File('${root.path}/maps/map.json').readAsBytes();
    final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.terrain',
            gameVersion: '0.1.0',
            title: 'Terrain',
            authorName: 'Yoahn',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
    expect(artifact.manifest.compatibility.requiredCapabilities,
        contains('map3d.terrain-surfaces@1'));
    final archive = ZipDecoder().decodeBytes(artifact.packageBytes);
    final saved = MapData.fromJson(jsonDecode(
            utf8.decode(archive.findFile('project/maps/map.json')!.content))
        as Map<String, dynamic>);
    expect(saved.spatialScene!.terrainSurfaces,
        changed.spatialScene!.terrainSurfaces);
    expect(saved.spatialScene!.worldHeightAt(1.5, 1.5), 2.125);
    expect(await File('${root.path}/maps/map.json').readAsBytes(), originalMap);
  });
}
