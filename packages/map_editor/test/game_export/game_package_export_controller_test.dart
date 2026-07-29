import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_distribution/map_distribution.dart';
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

  test('exposes creator gameplay diagnostics when publication is blocked',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final projectFile = File(p.join(root.path, 'project.json'));
    final project =
        jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>;
    (project['newGame'] as Map<String, dynamic>)['enabled'] = false;
    await projectFile.writeAsString(jsonEncode(project), flush: true);
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    final output = File(p.join(root.parent.path, 'unplayable.pokemapgame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });

    await controller.export(
      profile: neutralExportProfile(),
      outputFile: output,
    );

    expect(controller.snapshot.status, GamePackageExportStatus.error);
    expect(controller.snapshot.errorCode, 'gameplayReadinessFailed');
    expect(
      controller.snapshot.gameplayReadinessReport?.byCode(
        'exportNewGameDisabled',
      ),
      isNotEmpty,
    );
    expect(controller.snapshot.safeErrorMessage, contains('jouable'));
    expect(await output.exists(), isFalse);
  });

  test('builds a stable minimal profile for a local test export', () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      localGameIdGenerator: () => 'games.local.test1234',
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final first = controller.quickProfile();
    final second = controller.quickProfile();

    expect(first.gameId, 'games.local.test1234');
    expect(second.gameId, first.gameId);
    expect(first.title, 'Neutral Adventure');
    expect(first.authorName, 'Projet local');
    expect(first.gameVersion, '0.1.0');
    expect(first.defaultLocale, 'fr');
    expect(first.supportedLocales, <String>['fr']);
    expect(first.iconPath, isNull);
    expect(first.licensePath, isNull);
  });

  test('names the missing project file and explains how to fix it', () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final output = File(p.join(root.parent.path, 'missing-file.pokemapgame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    await controller.export(
      profile: neutralExportProfile().copyWith(
        iconPath: 'assets/missing-icon.png',
      ),
      outputFile: output,
    );

    expect(controller.snapshot.status, GamePackageExportStatus.error);
    expect(
      controller.snapshot.safeErrorMessage,
      contains('assets/missing-icon.png'),
    );
    expect(
      controller.snapshot.safeErrorMessage,
      contains('dossier du projet'),
    );
    expect(
      controller.snapshot.safeErrorMessage,
      contains('laissez ce champ vide'),
    );
    expect(await output.exists(), isFalse);
  });

  test('translates the manifest quota into an actionable player message',
      () async {
    final root = await createAuthorProject();
    addTearDown(() => root.delete(recursive: true));
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      exportService: const GamePackageExportService(
        packageBuilder: GamePackageBuilder(
          securityPolicy: GamePackageSecurityPolicy(maxManifestBytes: 1),
        ),
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    final output = File(p.join(root.parent.path, 'oversized.pokemapgame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });
    await controller.export(
      profile: neutralExportProfile(),
      outputFile: output,
    );

    expect(controller.snapshot.status, GamePackageExportStatus.error);
    expect(
      controller.snapshot.safeErrorMessage,
      contains('inventaire des fichiers'),
    );
    expect(
      controller.snapshot.safeErrorMessage,
      contains('4 Mio'),
    );
    expect(
      controller.snapshot.safeErrorMessage,
      isNot(contains('builder policy')),
    );
  });

  test('names the JSON file containing a reference outside the package',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    addTearDown(() => root.delete(recursive: true));
    await File(p.join(root.path, 'data', 'escaping-reference.json'))
        .writeAsString(
      '{"assetPath":"../../outside.png"}',
      flush: true,
    );
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    final output = File(p.join(root.parent.path, 'escaping.pokemapgame'));
    addTearDown(() async {
      if (await output.exists()) await output.delete();
    });

    await controller.export(
      profile: neutralExportProfile(),
      outputFile: output,
    );

    expect(controller.snapshot.status, GamePackageExportStatus.error);
    expect(
      controller.snapshot.safeErrorMessage,
      contains('project/data/escaping-reference.json'),
    );
    expect(controller.snapshot.safeErrorMessage, contains('chemin relatif'));
    expect(controller.snapshot.safeErrorMessage, contains('« .. »'));
    expect(await output.exists(), isFalse);
  });

  test('persists and exposes the exact filesystem failure diagnostic',
      () async {
    final root = await createAuthorProject(withDialogue: false);
    final outputDirectory = Directory(
      p.join(root.parent.path, 'blocked-output.pokemapgame'),
    );
    final diagnosticLog = File(
      p.join(root.parent.path, 'logs', 'game-export.log'),
    );
    await outputDirectory.create();
    addTearDown(() async {
      await root.delete(recursive: true);
      if (await outputDirectory.exists()) {
        await outputDirectory.delete(recursive: true);
      }
      if (await diagnosticLog.parent.exists()) {
        await diagnosticLog.parent.delete(recursive: true);
      }
    });
    final controller = GamePackageExportController(
      projectRoot: root,
      projectName: 'Neutral Adventure',
      profileStore: GamePackageExportProfileStore(projectRoot: root),
      diagnosticLogFile: diagnosticLog,
      exportService: GamePackageExportService(
        atomicFileWriter: ({
          required outputFile,
          required packageBytes,
          required packageSha256,
        }) async {
          throw FileSystemException(
            'Operation not permitted',
            '${outputFile.path}.sandbox-stage.tmp',
            const OSError('Operation not permitted', 1),
          );
        },
      ),
    );
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.export(
      profile: controller.quickProfile(),
      outputFile: File(outputDirectory.path),
    );

    expect(controller.snapshot.status, GamePackageExportStatus.error);
    expect(
      controller.snapshot.safeErrorMessage,
      contains('blocked-output.pokemapgame'),
    );
    expect(
      controller.snapshot.technicalErrorDetails,
      allOf(
        contains('exportWriteFailed'),
        contains('Operation not permitted'),
        contains('blocked-output.pokemapgame'),
      ),
    );
    expect(controller.snapshot.diagnosticLogPath, diagnosticLog.path);
    expect(await diagnosticLog.exists(), isTrue);
    final persistedDiagnostic = await diagnosticLog.readAsString();
    expect(persistedDiagnostic, contains('exportWriteFailed'));
    expect(persistedDiagnostic, contains('Operation not permitted'));
    expect(persistedDiagnostic, contains('blocked-output.pokemapgame'));
  });
}
