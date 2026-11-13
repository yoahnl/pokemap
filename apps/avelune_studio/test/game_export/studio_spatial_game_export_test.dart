import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';

import '../support/m3_story_fixture.dart';

void main() {

  test('canonical 3D publication refusal is explained in French', () async {
    final source = await M3StoryFixture.create();
    final output = await Directory.systemTemp.createTemp('as-spatial-export-');
    addTearDown(() async {
      await source.directory.delete(recursive: true);
      await output.delete(recursive: true);
    });
    final controller = StudioGameExportController(
      projectRoot: source.directory,
      projectName: source.session.name,
      buildPackage: (_, _, _) async => throw const GamePackageExportException(
        code: 'runtime3d.publication_unsupported',
        path: 'project.json',
        message:
            '3D exploration packages can only be exported for local testing.',
      ),
    );
    addTearDown(controller.dispose);
    final file = File('${output.path}/test.avelunegame');
    expect(
      await controller.export(
        metadata: const StudioGameExportMetadata(
          gameId: 'games.avelune.test',
          title: 'Test',
          version: '0.1.0',
          author: 'Avelune',
          locale: 'fr',
          locales: 'fr',
        ),
        outputPath: file.path,
        overwriteConfirmed: false,
        publication: true,
        prepare: () async => true,
        hasPendingChanges: () => false,
        isCurrentProject: () => true,
      ),
      isFalse,
    );
    expect(
      controller.error,
      contains('export 3D est disponible en mode Test local'),
    );
    expect(await file.exists(), isFalse);
  });
}
