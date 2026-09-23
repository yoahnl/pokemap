import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/game_export_fixture.dart';
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';

void main() {
  testWidgets('home switches a real workspace despite its unreadable profile', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final first = (await tester.runAsync(M3StoryFixture.create))!;
    final second = (await tester.runAsync(M3StoryFixture.create))!;
    final invalid = File(
      p.join(first.directory.path, '.pokemap', 'export-profile-v1.json'),
    );
    await tester.runAsync(() async {
      await prepareGameExportFixture(first);
      await invalid.parent.create(recursive: true);
      await invalid.writeAsString('{invalid', flush: true);
    });
    final sessions = ProjectSessionController(
      _ExportSessions(first.session, second.session),
    );
    await sessions.open(first.directory.path);
    final maps = MapWorkspaceController(first.session, first.maps);
    await tester.runAsync(maps.initialize);
    final export = StudioGameExportController(
      projectRoot: first.directory,
      projectName: first.session.name,
    );
    addTearDown(() async {
      await tester.pumpWidget(const SizedBox());
      export.dispose();
      maps.dispose();
      await sessions.dispose();
      await tester.runAsync(() async {
        await first.directory.delete(recursive: true);
        await second.directory.delete(recursive: true);
      });
    });
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: ProjectSessionScreen(
          session: sessions,
          recentProjects: MemoryRecentProjectsAdapter(),
          chooseDirectory: () async => second.directory.path,
          workspaceBuilder: (session, close) =>
              session.sessionId == first.session.sessionId
              ? Builder(
                  builder: (context) => MapWorkspaceScreen(
                    controller: maps,
                    home: StudioHomeScope.of(context),
                    gameExport: export,
                    gameExportPicker: (_) async => null,
                    loadVisuals: (_, _) async => WorkspaceTestVisuals(),
                    runtimeBuilder: (_, _, _) => const SizedBox(),
                    onClose: close,
                    registerExitGuard: (_) {},
                  ),
                )
              : const Center(child: Text('Second projet ouvert')),
        ),
      ),
    );
    await pumpIo(tester);
    await tester.tap(find.text('Reprendre mon projet'));
    await pumpIo(tester, frames: 5);
    await tester.tap(find.byTooltip('Exporter le jeu'));
    await pumpIo(tester, frames: 20);
    expect(find.textContaining('Profil d’export illisible'), findsOneWidget);
    expect(
      tester
          .widget<StudioButton>(
            find.widgetWithText(StudioButton, 'Choisir le fichier et exporter'),
          )
          .onPressed,
      isNull,
    );
    await tester.tap(find.byTooltip('Accueil'));
    await pumpIo(tester, frames: 5);
    await tester.tap(find.text('Ouvrir un autre projet'));
    await pumpIo(tester, frames: 12);
    expect(sessions.state.project?.sessionId, second.session.sessionId);
    expect(find.text('Second projet ouvert'), findsOneWidget);
    expect(await tester.runAsync(invalid.readAsString), '{invalid');
  });
}

class _ExportSessions implements ProjectSessionPort {
  _ExportSessions(this.first, this.second);
  final ProjectSession first;
  final ProjectSession second;

  @override
  Future<ProjectSession> open(String directoryPath) async =>
      directoryPath == first.directoryPath ? first : second;

  @override
  Future<void> close(ProjectSession session) async {}
}
