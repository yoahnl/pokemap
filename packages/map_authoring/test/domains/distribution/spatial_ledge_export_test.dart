import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final enabled in [false, true]) {
    test('native ledge capability is projected only when authored: $enabled',
        () async {
      final root = await Directory.systemTemp.createTemp('ledge-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map
          .copyWith(
              spatialScene: map.spatialScene!.copyWith(
                  navigation: map.spatialScene!.navigation.copyWith(ledges: [
            if (enabled)
              SpatialLedge(
                  id: 'jump', x: 4, z: 2, direction: SpatialRampDirection.south)
          ])))
          .toJson()));
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
              gameId: 'games.example.ledges',
              gameVersion: '0.1.0',
              title: 'Native ledges',
              authorName: 'Fixture',
              defaultLocale: 'fr',
              supportedLocales: ['fr']),
          mode: GamePackageExportMode.localTest);
      expect(
          result.manifest.compatibility.requiredCapabilities
              .contains(SpatialLedge.capabilityId),
          enabled);
      final archive = ZipDecoder().decodeBytes(result.packageBytes);
      final exported = MapData.fromJson(jsonDecode(
              utf8.decode(archive.findFile('project/maps/map.json')!.content))
          as Map<String, dynamic>);
      expect(
          exported.spatialScene!.navigation.ledges, hasLength(enabled ? 1 : 0));
      expect(await File('${root.path}/maps/map.json').readAsBytes(), before);
    });
  }
}
