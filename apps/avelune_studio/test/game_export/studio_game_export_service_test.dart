import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {

  test('the two-map story fixture exports with the canonical service', () async {
    final fixture = await M3StoryFixture.create();
    final output = await Directory.systemTemp.createTemp('as-exp-output-');
    addTearDown(() async {
      await fixture.directory.delete(recursive: true);
      await output.delete(recursive: true);
    });
    await prepareGameExportFixture(fixture);
    final artifact = await const CanonicalGamePackageExportService().exportToFile(
      projectRoot: fixture.directory,
      profile: GamePackageExportProfile(
        gameId: 'games.avelune.export-demo',
        gameVersion: '0.1.0',
        title: 'Départ Avelune',
        authorName: 'Avelune',
        defaultLocale: 'fr',
        supportedLocales: const ['fr'],
      ),
      outputFile: File('${output.path}/demo.avelunegame'),
      mode: GamePackageExportMode.publication,
    );
    expect(artifact.certification.isExportable, isTrue);
  });
}
