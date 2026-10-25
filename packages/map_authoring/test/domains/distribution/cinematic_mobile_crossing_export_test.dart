import 'dart:io';
import 'package:map_core/map_core.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:test/test.dart';
import '../../../../map_distribution/test/support/cinematic_mobile_crossing_fixture.dart'
    show mobileCrossingPayload;

void main() {
  test('canonical export preserves crossing option and capability', () async {
    final root =
        await Directory.systemTemp.createTemp('cinematic-crossing-export-');
    addTearDown(() => root.delete(recursive: true));
    final files = mobileCrossingPayload();
    for (final entry in files.entries) {
      final file =
          File('${root.path}/${entry.key.substring('project/'.length)}');
      await file.parent.create(recursive: true);
      await file.writeAsBytes(entry.value);
    }
    final profile = GamePackageExportProfile(
        gameId: 'games.example.crossing',
        gameVersion: '0.1.0',
        title: 'Crossing',
        authorName: 'Fixture',
        defaultLocale: 'fr',
        supportedLocales: ['fr']);
    final result = await const CanonicalGamePackageExportService().build(
        projectRoot: root,
        profile: profile,
        mode: GamePackageExportMode.localTest);
    expect(result.manifest.compatibility.requiredCapabilities,
        contains(CinematicAsset.mobileActorCrossingCapabilityId));
    final projection = await RuntimeProjectProjectionBuilder()
        .build(projectRoot: root, profile: profile);
    expect(
        projection.project.cinematics.single.allowMobileActorCrossing, isTrue);
    expect(await File('${root.path}/project.json').readAsBytes(),
        files['project/project.json']);
  });
}
