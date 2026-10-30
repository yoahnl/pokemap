import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('exports water zones without enabling Surf in project settings',
      () async {
    final owner =
        Directory('/Users/karim/Library/Caches/AveluneQA/hgss-export-0111');
    await owner.create(recursive: true);
    final root = await owner.createTemp('water-');
    addTearDown(() => root.delete(recursive: true));
    final files = spatialPayload();
    final project = ProjectManifest.fromJson(
        jsonDecode(utf8.decode(files['project/project.json']!)));
    expect(project.settings.surf, isNull);
    final original = MapData.fromJson(
        jsonDecode(utf8.decode(files['project/maps/map.json']!)));
    final map = original.copyWith(gameplayZones: [
      const MapGameplayZone(
        id: 'water',
        kind: GameplayZoneKind.movement,
        area: MapRect(
            pos: GridPos(x: 1, y: 1), size: GridSize(width: 2, height: 2)),
        movement: MovementZonePayload(requiredMode: MovementMode.surf),
      ),
    ]);
    files['project/maps/map.json'] = utf8.encode(jsonEncode(map.toJson()));
    for (final entry in files.entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final result = await const CanonicalGamePackageExportService().build(
      projectRoot: root,
      profile: GamePackageExportProfile(
        gameId: 'games.example.water',
        gameVersion: '0.1.0',
        title: 'Water',
        authorName: 'Yoahn',
        defaultLocale: 'fr',
        supportedLocales: ['fr'],
      ),
      mode: GamePackageExportMode.localTest,
    );
    expect(result.manifest.compatibility.requiredCapabilities,
        contains(SurfGameplayCapabilities.capabilityId));
    final archive = ZipDecoder().decodeBytes(result.packageBytes, verify: true);
    final exportedMap = MapData.fromJson(jsonDecode(
        utf8.decode(archive.findFile('project/maps/map.json')!.content)));
    expect(exportedMap.gameplayZones.single.toJson(),
        map.gameplayZones.single.toJson());
    expect(await File('${root.path}/project.json').readAsBytes(),
        files['project/project.json']);
  });
}
