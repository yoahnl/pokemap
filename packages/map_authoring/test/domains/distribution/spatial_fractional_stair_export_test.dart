import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/fractional_stair_fixture.dart';

void main() {
  for (final high in [1.5, 2.625, 18439 / 16384, 2.0]) {
    test(
        'canonical export preserves endpoint $high and advertises exactly its capability',
        () async {
      final root =
          await Directory.systemTemp.createTemp('fractional-stair-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = fractionalStairPayload(highLevel: high);
      for (final entry in files.entries) {
        final file =
            File('${root.path}/${entry.key.substring('project/'.length)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final before = await File('${root.path}/maps/map.json').readAsBytes();
      final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.fractional',
            gameVersion: '0.1.0',
            title: 'Stairs',
            authorName: 'Yoahn',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest,
      );
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains('map3d.fractional-ramps@1'),
          high != high.truncateToDouble());
      final archive = ZipDecoder().decodeBytes(result.packageBytes);
      final saved = MapData.fromJson(jsonDecode(
              utf8.decode(archive.findFile('project/maps/map.json')!.content))
          as Map<String, dynamic>);
      final scene = saved.spatialScene!;
      expect(scene.navigation.ramps.single.highLevel, high);
      expect(scene.worldHeightAt(2.5, 3), high / 2);
      expect(
          scene.rampHasTerrainContacts(scene.navigation.ramps.single), isTrue);
      expect(await File('${root.path}/maps/map.json').readAsBytes(), before);
    });
  }
}
