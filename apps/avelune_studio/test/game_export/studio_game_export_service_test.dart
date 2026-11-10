import 'dart:io';

import 'package:avelune_studio/features/game_export/application/studio_game_export_workflow.dart';
import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_publication_workflow.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/narrative/application/narrative_interaction.dart';
import 'package:avelune_studio/features/narrative/application/narrative_workspace_controller.dart';
import 'package:avelune_studio/features/narrative/data/local_narrative_adapter.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/game_export_fixture.dart';
import '../support/m3_story_fixture.dart';

void main() {
  test('a rejected native interaction save preserves the draft and blocks package publication', () async {
    final fixture = await M3StoryFixture.create();
    final output = await Directory.systemTemp.createTemp('as-exp-invalid-save-');
    addTearDown(() async {
      await fixture.directory.delete(recursive: true);
      await output.delete(recursive: true);
    });
    await prepareGameExportFixture(fixture);
    final target = File('${output.path}/blocked.avelunegame');
    final maps = MapWorkspaceController(fixture.session, fixture.maps);
    addTearDown(maps.dispose);
    await maps.initialize();
    final narrative = NarrativeWorkspaceController(
      maps,
      LocalNarrativeAdapter(session: fixture.session, mapAdapter: fixture.maps),
      () {},
      (_, _) async {},
    );
    addTearDown(narrative.dispose);
    final document = maps.active!;
    await narrative.openSource(
      document,
      NarrativeEventSourceRef.entityInteract(document.current.id, 'missing-source'),
      'Brouillon invalide',
    );
    final edit = narrative.active!;
    final before = edit.current.interaction;
    edit.change(interaction: NarrativeInteractionDraft(
      id: before.id,
      name: 'Brouillon à conserver',
      mapId: before.mapId,
      source: before.source,
      dialogueId: before.dialogueId,
      steps: before.steps,
    ));
    final sourceFiles = [
      File('${fixture.directory.path}/project.json'),
      File('${fixture.directory.path}/${maps.project!.maps.firstWhere((entry) => entry.id == document.base.mapId).relativePath}'),
    ];
    final bytes = [for (final file in sourceFiles) await file.readAsBytes()];
    final exporter = StudioGameExportController(
      projectRoot: fixture.directory,
      projectName: fixture.session.name,
    );
    addTearDown(exporter.dispose);
    await exporter.load();
    final workflow = WorkspaceWorkflow(
      controller: maps,
      isActive: () => true,
      changed: () {},
      resources: () => null,
      narrative: () => narrative,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (_, _) async {},
    );
    final publication = WorkspacePublicationWorkflow(
      controller: maps,
      workflow: workflow,
      isActive: () => true,
      connectionBusy: () => false,
      exporter: () => exporter,
      resources: () => null,
      pokemon: () => null,
    );
    final export = StudioGameExportWorkflow(
      controller: exporter,
      pickFile: (_) async => StudioGameExportDestination(target.path, exists: false),
      prepare: () => publication.prepareExport(
        confirmPokemonSave: () async => true,
        confirmSave: () async => true,
      ),
      preparationFailure: () => workflow.exportPreparationFailure,
      hasPendingChanges: () => workflow.hasPendingChanges,
      isCurrentProject: () => true,
      isActive: () => true,
    );
    addTearDown(export.dispose);
    expect(await export.run(
      metadata: const StudioGameExportMetadata(
        gameId: 'games.avelune.invalid-interaction',
        title: 'Export bloqué',
        version: '1.0.0',
        author: 'Avelune',
        locale: 'fr',
        locales: 'fr',
      ),
      confirmOverwrite: (_) async => true,
    ), isFalse);
    expect(exporter.error, contains('Enregistrement préalable refusé'));
    expect(narrative.publicationError, isNotNull);
    expect(edit.dirty, isTrue);
    expect(edit.current.interaction.name, 'Brouillon à conserver');
    expect(await target.exists(), isFalse);
    for (var i = 0; i < sourceFiles.length; i++) {
      expect(await sourceFiles[i].readAsBytes(), bytes[i]);
    }
  });

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
