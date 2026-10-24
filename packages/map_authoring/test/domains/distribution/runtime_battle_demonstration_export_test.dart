import 'dart:io';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/battle_demonstration_fixture.dart';

void main() {
  test('export preserves demonstration and declares current Player support',
      () async {
    final root =
        await Directory.systemTemp.createTemp('battle-demonstration-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = battleDemonstrationPayload();
    for (final entry in files.entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.demonstration',
            gameVersion: '0.1.0',
            title: 'Demo',
            authorName: 'Fixture',
            defaultLocale: 'fr',
            supportedLocales: ['fr']),
        mode: GamePackageExportMode.localTest);
    expect(result.manifest.compatibility.requiredCapabilities,
        contains(SceneBattleDemonstration.capabilityId));
    final projection = await RuntimeProjectProjectionBuilder().build(
        projectRoot: root,
        profile: GamePackageExportProfile(
            gameId: 'games.example.demonstration',
            gameVersion: '0.1.0',
            title: 'Demo',
            authorName: 'Fixture',
            defaultLocale: 'fr',
            supportedLocales: ['fr']));
    final projected = projection.project.scenes.single.graph.nodes[1].payload
        as SceneBattlePayload;
    expect(projected.demonstration?.playerTrainerId, 'guide');
    expect(projected.demonstration?.bagItems.single.quantity, 20);
    expect(await File('${root.path}/project.json').readAsBytes(),
        files['project/project.json']);
  });
}
