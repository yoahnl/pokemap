import 'dart:async';
import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:path/path.dart' as p;

import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {
  late M3StoryFixture source;
  late MapWorkspaceController maps;
  late StudioGameExportController owner;
  late File profileFile;
  var prompts = 0;

  setUp(() async {
    source = await M3StoryFixture.create();
    await prepareGameExportFixture(source);
    maps = MapWorkspaceController(source.session, source.maps);
    await maps.initialize();
    owner = StudioGameExportController(
      projectRoot: source.directory,
      projectName: source.session.name,
    );
    profileFile = File(p.join(source.directory.path, '.pokemap', 'export-profile-v1.json'));
    prompts = 0;
  });

  tearDown(() async {
    owner.dispose();
    maps.dispose();
    await source.directory.delete(recursive: true);
  });

  WorkspacePublicationWorkflow publication() => WorkspacePublicationWorkflow(
    controller: maps,
    workflow: WorkspaceWorkflow(
      controller: maps,
      isActive: () => !maps.isDisposed,
      changed: () {},
      resources: () => null,
      narrative: () => null,
      confirmClose: () async {
        prompts++;
        return WorkspaceCloseChoice.cancel;
      },
      flushFocus: () {},
      launchMap: (_, _) async {},
    ),
    isActive: () => !maps.isDisposed,
    connectionBusy: () => false,
    exporter: () => owner,
    resources: () => null,
    pokemon: () => null,
  );

  Future<bool> close(WorkspacePublicationWorkflow workflow) =>
    workflow.allowClose(leavePokemon: () async => true);

  Future<void> corruptProfile() async {
    await profileFile.parent.create(recursive: true);
    await profileFile.writeAsString('{invalid', flush: true);
    await owner.load();
    expect(owner.error, contains('Profil d’export illisible'));
    expect(owner.canStart, isFalse);
    expect(owner.operationActive, isFalse);
  }

  test('unreadable profile permits exit without a draft and preserves its bytes', () async {
    await corruptProfile();
    final workflow = publication();
    expect(await close(workflow), isTrue);
    expect(prompts, 0);
    expect(await profileFile.readAsString(), '{invalid');
  });

  test('unreadable profile retains the normal draft confirmation', () async {
    await corruptProfile();
    final document = maps.active!;
    document.commit(document.current.copyWith(name: 'Brouillon conservé'));
    final workflow = publication();
    for (var attempt = 0; attempt < 2; attempt++) {
      expect(await close(workflow), isFalse);
      expect(prompts, attempt + 1);
      expect(document.dirty, isTrue);
      expect(document.current.name, 'Brouillon conservé');
      expect(await profileFile.readAsString(), '{invalid');
    }
  });

  test('cancelled export blocks exit until the real exporter cleanup settles', () async {
    final reading = Completer<void>(), release = Completer<void>();
    var reads = 0;
    final artifact = await const CanonicalGamePackageExportService().build(
      projectRoot: source.directory,
      profile: GamePackageExportProfile(
        gameId: 'games.avelune.exit-test',
        gameVersion: '0.1.0',
        title: 'Exit test',
        authorName: 'Avelune',
        defaultLocale: 'fr',
        supportedLocales: const ['fr'],
      ),
    );
    owner.dispose();
    owner = StudioGameExportController(
      projectRoot: source.directory,
      projectName: source.session.name,
      buildPackage: (_, _, _) async => artifact,
      readFingerprints: (_) async {
        if (++reads == 2) {
          reading.complete();
          await release.future;
        }
        return const {'project.json': 'unchanged'};
      },
    );
    final destination = await Directory.systemTemp.createTemp('as-exp-close-');
    addTearDown(() => destination.delete(recursive: true));
    final target = File(p.join(destination.path, 'demo.avelunegame'));
    await owner.load();
    final workflow = publication();
    final exporting = owner.export(
      metadata: const StudioGameExportMetadata(
        gameId: 'games.avelune.exit-test',
        title: 'Exit test',
        version: '0.1.0',
        author: 'Avelune',
        locale: 'fr',
        locales: 'fr',
      ),
      outputPath: target.path,
      overwriteConfirmed: false,
      publication: true,
      prepare: () async => true,
      hasPendingChanges: () => false,
      isCurrentProject: () => true,
    );
    try {
      await Future.any([
        reading.future,
        exporting.then((_) {
          if (!reading.isCompleted) {
            throw StateError('Export settled before cleanup gate: ${owner.stage} ${owner.error}');
          }
        }),
      ]).timeout(const Duration(seconds: 10));
      owner.cancel();
      expect(owner.stage, StudioExportStage.cancelled);
      expect(owner.operationActive, isTrue);
      expect(await close(workflow), isFalse);
      expect(await close(workflow), isFalse);
      expect(prompts, 0);
    } finally {
      if (!release.isCompleted) release.complete();
    }
    expect(await exporting, isFalse);
    expect(owner.operationActive, isFalse);
    expect(await close(workflow), isTrue);
    expect(await target.exists(), isFalse);
  });
}
