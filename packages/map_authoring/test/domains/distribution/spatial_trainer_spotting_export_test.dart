import 'dart:convert';
import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/spatial_package_fixture.dart';

void main() {
  test('new exports require trainer spotting only for configured NPC sight', () async {
    for (final sight in [0, 4]) {
      final root = await Directory.systemTemp.createTemp('trainer-spot-export-');
      addTearDown(() => root.delete(recursive: true));
      final files = spatialPayload();
      final project = ProjectManifest.fromJson(jsonDecode(utf8.decode(files['project/project.json']!)));
      files['project/project.json'] = utf8.encode(jsonEncode(project.copyWith(trainers: [
        const ProjectTrainerEntry(id: 'guard', name: 'Guard', trainerClass: 'Scout')
      ]).toJson()));
      final map = MapData.fromJson(jsonDecode(utf8.decode(files['project/maps/map.json']!)));
      files['project/maps/map.json'] = utf8.encode(jsonEncode(map.copyWith(entities: [
        MapEntity(id: 'npc', kind: MapEntityKind.npc, pos: const GridPos(x: 2, y: 2),
          npc: MapEntityNpcData(characterId: 'hero', trainerId: 'guard', lineOfSightRange: sight))
      ]).toJson()));
      for (final entry in files.entries) {
        final file = File('${root.path}/${entry.key.substring(8)}');
        await file.parent.create(recursive: true);
        await file.writeAsBytes(entry.value);
      }
      final artifact = await const CanonicalGamePackageExportService().build(
        projectRoot: root, profile: GamePackageExportProfile(gameId: 'games.example.trainer-spotting',
          gameVersion: '0.1.0', title: 'Spotting', authorName: 'QA', defaultLocale: 'fr', supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest).catchError((Object error) {
          if (error is GamePackageExportException) fail('${error.code} at ${error.path}: ${error.message}');
          throw error;
        });
      expect(artifact.manifest.compatibility.requiredCapabilities.contains(
        SpatialGameplayCapabilities.trainerSpottingCapabilityId), sight > 0);
    }
  });
}
