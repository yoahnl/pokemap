import 'dart:io';

import 'package:avelune_studio/features/game_export/application/studio_game_export_workflow.dart';
import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/project_settings/application/project_identity_controller.dart';
import 'package:flutter_test/flutter_test.dart';

import 'm3_story_fixture.dart';
import 'real_test_io.dart';

class MapHostOwnerFixture {
  MapHostOwnerFixture._(this.tester, this.source, this.maps, this.gameExport);

  final WidgetTester tester;
  final M3StoryFixture source;
  final MapWorkspaceController maps;
  final StudioGameExportController gameExport;

  EditableMapDocument get document => maps.active!;

  static Future<MapHostOwnerFixture> open(
    WidgetTester tester, {
    Future<void> Function(M3StoryFixture source)? prepareSource,
  }) async {
    final (source, maps) = (await RealTestIo.run(tester, () async {
      final source = await M3StoryFixture.create();
      if (prepareSource != null) await prepareSource(source);
      final maps = MapWorkspaceController(source.session, source.maps);
      await maps.initialize();
      return (source, maps);
    }))!;
    final gameExport = StudioGameExportController(
      projectRoot: source.directory,
      projectName: source.session.name,
    );
    addTearDown(() async {
      gameExport.dispose();
      maps.dispose();
      await RealTestIo.run(tester, () async {
        if (await source.directory.exists()) {
          await source.directory.delete(recursive: true);
        }
      });
    });
    return MapHostOwnerFixture._(tester, source, maps, gameExport);
  }

  Future<bool> save() async =>
      await RealTestIo.run(tester, () => maps.save(document)) ?? false;

  Future<bool> exportGame(File package, {required String author}) async {
    final identity = ProjectIdentityController(port: gameExport);
    final guard = WorkspaceWorkflow(
      controller: maps,
      isActive: () => !maps.isDisposed,
      changed: maps.notify,
      resources: () => null,
      narrative: () => null,
      confirmClose: () async => WorkspaceCloseChoice.cancel,
      flushFocus: () {},
      launchMap: (_, _) async =>
          throw StateError('No playtest launch requested by an export'),
    );
    final workflow = StudioGameExportWorkflow(
      controller: gameExport,
      pickFile: (_) async =>
          StudioGameExportDestination(package.path, exists: await package.exists()),
      prepare: guard.saveForExport,
      preparationFailure: () => guard.exportPreparationFailure,
      hasPendingChanges: () => guard.hasPendingChanges,
      isCurrentProject: () => !maps.isDisposed,
      isActive: () => true,
    );
    try {
      return await RealTestIo.run(tester, () async {
            await gameExport.load();
            await identity.open();
            return workflow.run(
              metadata: identity.exportMetadata.copyWith(author: author),
              publication: false,
              confirmOverwrite: (_) async => false,
            );
          }) ??
          false;
    } finally {
      workflow.dispose();
      identity.dispose();
    }
  }

  Future<Map<String, List<int>>> disk() async =>
      (await RealTestIo.run(
        tester,
        () async => {
          for (final file
              in await source.directory
                  .list(recursive: true)
                  .where(
                    (file) => file is File && !file.path.contains('/.pokemap/'),
                  )
                  .cast<File>()
                  .toList())
            file.path.substring(source.directory.path.length): await file
                .readAsBytes(),
        },
      ))!;
}
