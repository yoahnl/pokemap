import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  for (final enabled in [false, true]) {
    test('entity model capability is projected only when authored: $enabled',
        () async {
      final root = await Directory.systemTemp.createTemp('entity-model-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final map = MapData.fromJson(
          jsonDecode(utf8.decode(files['project/maps/map.json']!))
              as Map<String, dynamic>);
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(
        entities: [MapEntity(id: 'object', kind: enabled ? MapEntityKind.item : MapEntityKind.custom, pos: const GridPos(x: 0, y: 0), item: enabled ? const MapEntityItemData(gameItemId: 'resource') : null)],
        spatialScene: map.spatialScene!.copyWith(instances: [map.spatialScene!.instances.single.copyWith(entityId: enabled ? 'object' : null)])).toJson()));
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
              .contains(SpatialModelInstance.entityBindingCapabilityId),
          enabled);
      final archive = ZipDecoder().decodeBytes(result.packageBytes);
      final exported = MapData.fromJson(jsonDecode(
              utf8.decode(archive.findFile('project/maps/map.json')!.content))
          as Map<String, dynamic>);
      expect(
          exported.spatialScene!.instances.single.entityId, enabled ? 'object' : null);
      expect(await File('${root.path}/maps/map.json').readAsBytes(), before);
    });
  }
}
