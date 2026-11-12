import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/coordination/workspace_workflow.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_open_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/game_export_fixture.dart';
import '../support/neutral_map_host_fixture.dart';
import '../support/real_test_io.dart';
import '../support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'mounted project exports a real package and retains the native map and viewport',
    (tester) async {
      final source = (await RealTestIo.run(tester, M3StoryFixture.create))!;
      await RealTestIo.run(tester, () => prepareGameExportFixture(source));
      final output = (await RealTestIo.run(
        tester,
        () => Directory.systemTemp.createTemp('as-exp-session-'),
      ))!;
      final destination = File(p.join(output.path, 'session.avelunegame'));
      final session = ProjectSessionController(
        _ExportSessions(source.session, source.session),
      );
      await session.open(source.directory.path);
      final maps = MapWorkspaceController(source.session, source.maps);
      await RealTestIo.run(tester, maps.initialize);
      final export = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
      );
      final host = await NeutralMapHostFixture.fromController(
        tester,
        maps,
        mapAdapter: source.maps,
      );
      addTearDown(() async {
        await host.dispose();
        export.dispose();
        maps.dispose();
        await session.dispose();
        await RealTestIo.run(tester, () async {
          await source.directory.delete(recursive: true);
          await output.delete(recursive: true);
        });
      });
      final document = maps.active!;
      final view = host.nativeView;
      view.transform.value = Matrix4.identity()..scaleByDouble(1.5, 1.5, 1, 1);
      final transform = view.transform.value.clone();
      final workflow = WorkspaceWorkflow(
        controller: maps,
        isActive: () => !maps.isDisposed,
        changed: maps.notify,
        resources: () => null,
        narrative: () => null,
        confirmClose: () async => WorkspaceCloseChoice.cancel,
        flushFocus: () {},
        launchMap: (_, _) async {},
      );
      await RealTestIo.run(tester, export.load);
      expect(export.operationActive, isFalse);
      expect(export.canStart, isTrue);
      final result = await RealTestIo.run(
        tester,
        () => export.export(
          metadata: const StudioGameExportMetadata(
            gameId: 'games.avelune.session-export',
            title: 'Départ Avelune',
            version: '0.1.0',
            author: 'Avelune',
            locale: 'fr',
            locales: 'fr',
          ),
          outputPath: destination.path,
          overwriteConfirmed: false,
          publication: true,
          prepare: workflow.saveForExport,
          preparationFailure: () => workflow.exportPreparationFailure,
          hasPendingChanges: () => workflow.hasPendingChanges,
          isCurrentProject: () =>
              identical(session.state.project, source.session),
        ),
      );
      expect(result, isTrue, reason: export.error);
      expect(export.outputPath, destination.path);
      expect(await RealTestIo.run(tester, destination.exists), isTrue);
      expect(export.packageSha256, isNotEmpty);
      expect(export.stage, StudioExportStage.completed);
      expect(export.operationActive, isFalse);
      expect(maps.active, same(document));
      expect(host.nativeView, same(view));
      expect(view.transform.value, transform);
      expect(session.state.project, same(source.session));
      expect(tester.takeException(), isNull);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'unreadable export profile does not prevent switching the current project',
    () async {
      final first = await M3StoryFixture.create();
      final second = await M3StoryFixture.create();
      final invalid = File(
        p.join(first.directory.path, '.pokemap', 'export-profile-v1.json'),
      );
      await prepareGameExportFixture(first);
      await invalid.parent.create(recursive: true);
      await invalid.writeAsString('{invalid', flush: true);
      final sessions = ProjectSessionController(
        _ExportSessions(first.session, second.session),
      );
      await sessions.open(first.directory.path);
      final maps = MapWorkspaceController(first.session, first.maps);
      await maps.initialize();
      final export = StudioGameExportController(
        projectRoot: first.directory,
        projectName: first.session.name,
      );
      final workflow = WorkspaceWorkflow(
        controller: maps,
        isActive: () => !maps.isDisposed,
        changed: maps.notify,
        resources: () => null,
        narrative: () => null,
        confirmClose: () async => WorkspaceCloseChoice.cancel,
        flushFocus: () {},
        launchMap: (_, _) async {},
      );
      final opening = ProjectSessionOpenController(
        session: sessions,
        chooseDirectory: () async => second.directory.path,
        allowSwitch: workflow.allowClose,
      );
      addTearDown(() async {
        opening.dispose();
        export.dispose();
        maps.dispose();
        await sessions.dispose();
        await first.directory.delete(recursive: true);
        await second.directory.delete(recursive: true);
      });
      await export.load();
      expect(export.error, contains('Profil d’export illisible'));
      expect(export.canStart, isFalse);
      expect(await opening.open(browse: true), isTrue);
      expect(sessions.state.project, same(second.session));
      expect(await invalid.readAsString(), '{invalid');
    },
  );
}

class _ExportSessions implements ProjectSessionPort {
  _ExportSessions(this.first, this.second);
  final ProjectSession first;
  final ProjectSession second;

  @override
  Future<ProjectSession> open(
    String directoryPath, {
    void Function(ProjectOpeningPhase phase)? onPhase,
  }) async => directoryPath == first.directoryPath ? first : second;

  @override
  Future<void> close(ProjectSession session) async {}
}
