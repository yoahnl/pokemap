import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('spatial counter sides survive export without mutating source',
      () async {
    final root = await Directory.systemTemp.createTemp('counter-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    final map = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!))
            as Map<String, dynamic>);
    files['project/maps/map.json'] =
        utf8.encode(jsonEncode(map.copyWith(entities: [
      MapEntity(
          id: 'guard',
          kind: MapEntityKind.npc,
          pos: const GridPos(x: 4, y: 2),
          npc: const MapEntityNpcData(
              displayName: 'Guard', characterId: 'hero',
              counterInteractionSides: [EntityFacing.south]))
    ]).toJson()));
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
            gameId: 'games.example.counter',
            gameVersion: '0.1.0',
            title: 'Native counter',
            authorName: 'Fixture',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
    final archive = ZipDecoder().decodeBytes(result.packageBytes);
    final exported = MapData.fromJson(jsonDecode(
            utf8.decode(archive.findFile('project/maps/map.json')!.content))
        as Map<String, dynamic>);
    expect(exported.entities.single.npc!.counterInteractionSides,
        [EntityFacing.south]);
    expect(await File('${root.path}/maps/map.json').readAsBytes(), before);
  });
}
