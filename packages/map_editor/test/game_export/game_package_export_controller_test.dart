import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/game_export.dart';
import 'package:path/path.dart' as p;

import 'game_export_test_fixture.dart';

void main() {
  test('loads a draft, exports and queues the same certified package',
      () async {
    final root = await createAuthorProject();
    final inbox = await Directory.systemTemp.createTemp(
      'pokemap_controller_inbox_',
    );
    addTearDown(() async {
      await root.delete(recursive: true);
      await inbox.delete(recursive: true);
    });
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      installRequestPublisher: HubInstallRequestPublisher(
        inbox: inbox,
        requestIdGenerator: () => 'export-20260725-controller',
        now: () => DateTime.utc(2026, 7, 25),
      ),
    );
    addTearDown(controller.dispose);

    await controller.initialize();
    expect(controller.snapshot.status, GamePackageExportStatus.ready);
    expect(controller.snapshot.draft.title, 'Neutral Adventure');
    expect(controller.snapshot.draft.gameId, isEmpty);

    final profile = neutralExportProfile();
    final output = File(p.join(root.parent.path, 'controller.pokemapgame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    await controller.export(profile: profile, outputFile: output);
    expect(controller.snapshot.status, GamePackageExportStatus.succeeded);
    expect(controller.snapshot.artifact?.manifest.gameId, profile.gameId);
    expect(await output.exists(), isTrue);

    await controller.installInHub(profile);
    expect(controller.snapshot.status, GamePackageExportStatus.succeeded);
    expect(controller.snapshot.installRequest?.requestId,
        'export-20260725-controller');
    expect(
      await File(
        p.join(inbox.path, 'export-20260725-controller.request.json'),
      ).exists(),
      isTrue,
    );
  });

  test('reports safe validation errors and returns to an editable state',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.exportDraft(
      controller.snapshot.draft,
      File(p.join(root.path, 'invalid.pokemapgame')),
    );

    expect(controller.snapshot.status, GamePackageExportStatus.error);
    expect(controller.snapshot.safeErrorMessage, contains('identifiant'));
    controller.clearError();
    expect(controller.snapshot.status, GamePackageExportStatus.ready);
  });
}
