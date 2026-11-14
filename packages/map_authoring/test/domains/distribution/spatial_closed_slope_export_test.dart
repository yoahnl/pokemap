import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final closed in [true, false]) {
    test('export advertises closed slope flanks only when used ($closed)',
        () async {
      final root =
          await Directory.systemTemp.createTemp('closed-slope-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      final slope = SpatialTerrainSurface(
        id: 'slope',
        x: 1,
        z: 1,
        height: 2,
        gradientZ: -.5,
        closedFlanks: closed,
        footprints: [
          BorderGroundFootprint(points: [
            BorderGroundPoint(x: 0, z: 0),
            BorderGroundPoint(x: 1, z: 0),
            BorderGroundPoint(x: 1, z: 2),
            BorderGroundPoint(x: 0, z: 2),
          ])
        ],
      );
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map
          .copyWith(
              spatialScene: map.spatialScene!.copyWith(
                  terrainSurfaces: SpatialTerrainSurfaceSet(surfaces: [slope])))
          .toJson()));
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.slope',
            gameVersion: '0.1.0',
            title: 'Slope',
            authorName: 'Yoahn',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest,
      );
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains('map3d.closed-slope-flanks@1'),
          closed);
      final archive = ZipDecoder().decodeBytes(result.packageBytes);
      final saved = MapData.fromJson(jsonDecode(
              utf8.decode(archive.findFile('project/maps/map.json')!.content))
          as Map<String, dynamic>);
      expect(saved.spatialScene!.terrainSurfaces.surfaces.single.closedFlanks,
          closed);
    });
  }
}
