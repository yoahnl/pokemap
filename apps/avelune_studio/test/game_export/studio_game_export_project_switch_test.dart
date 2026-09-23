import 'dart:io';

import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/game_export/domain/studio_game_export_port.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

import '../support/game_export_fixture.dart';
import '../support/capture_m3_widget.dart';
import '../support/load_desktop_capture_fonts.dart';
import '../support/map_workspace_fixture.dart' show WorkspaceTestVisuals;
import '../support/m2_ui_fixture.dart' show pumpIo;
import '../support/m3_story_fixture.dart';

void main() {
  testWidgets(
    'home opens the export page on its mounted project and exports a package',
    (tester) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.runAsync(loadDesktopCaptureFonts);
      final source = (await tester.runAsync(M3StoryFixture.create))!;
      await tester.runAsync(() => prepareGameExportFixture(source));
      final output = (await tester.runAsync(
        () => Directory.systemTemp.createTemp('as-exp-home-'),
      ))!;
      final destination = File(p.join(output.path, 'home.avelunegame'));
      final session = ProjectSessionController(
        _ExportSessions(source.session, source.session),
      );
      await session.open(source.directory.path);
      final maps = MapWorkspaceController(source.session, source.maps);
      await tester.runAsync(maps.initialize);
      final export = StudioGameExportController(
        projectRoot: source.directory,
        projectName: source.session.name,
      );
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        export.dispose();
        maps.dispose();
        await session.dispose();
        await tester.runAsync(() async {
          await source.directory.delete(recursive: true);
          await output.delete(recursive: true);
        });
      });
      final capture = GlobalKey();
      await tester.pumpWidget(
        RepaintBoundary(
          key: capture,
          child: MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: studioTheme(),
            home: ProjectSessionScreen(
              session: session,
              recentProjects: MemoryRecentProjectsAdapter(),
              chooseDirectory: () async => source.directory.path,
              workspaceBuilder: (_, close) => Builder(
                builder: (context) => MapWorkspaceScreen(
                  controller: maps,
                  home: StudioHomeScope.of(context),
                  gameExport: export,
                  gameExportPicker: (_) async => StudioGameExportDestination(
                    destination.path,
                    exists: await destination.exists(),
                  ),
                  loadVisuals: (_, _) async => WorkspaceTestVisuals(),
                  runtimeBuilder: (_, _, _) => const SizedBox(),
                  onClose: close,
                  registerExitGuard: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await pumpIo(tester, frames: 12);
      final document = maps.active!;
      final workspaceState = tester.state(
        find.byType(MapWorkspaceScreen, skipOffstage: false),
      );
      final layout = tester.widget<MapWorkspaceLayout>(
        find.byType(MapWorkspaceLayout, skipOffstage: false),
      );
      final view = layout.view!;
      view.transform.value = Matrix4.identity()..scaleByDouble(1.5, 1.5, 1, 1);
      final transform = view.transform.value.clone();
      expect(find.byTooltip('Exporter le jeu'), findsNothing);
      await captureM3Widget(tester, capture, 'export-home');
      await tester.tap(find.byKey(const ValueKey('home-export-game')));
      await pumpIo(tester, frames: 12);
      final page = tester.widget<StudioGameExportPage>(
        find.byType(StudioGameExportPage),
      );
      expect(page.controller, same(export));
      expect(
        find.textContaining(
          'Créez un paquet .avelunegame pour Avelune Player.',
        ),
        findsOneWidget,
      );
      expect(find.byTooltip('Exporter le jeu'), findsNothing);
      await captureM3Widget(tester, capture, 'export-home-ready');
      await tester.tap(find.text('Retour à l’accueil'));
      await pumpIo(tester, frames: 16);
      expect(find.byType(StudioGameExportPage), findsNothing);
      expect(maps.active, same(document));
      expect(export.operationActive, isFalse);
      await tester.tap(find.text('Reprendre mon projet'));
      await pumpIo(tester, frames: 4);
      expect(
        tester.state(find.byType(MapWorkspaceScreen)),
        same(workspaceState),
      );
      expect(
        tester.widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout)).view,
        same(view),
      );
      expect(view.transform.value, transform);
      await tester.tap(find.byTooltip('Accueil'));
      await pumpIo(tester, frames: 4);
      await tester.tap(find.byKey(const ValueKey('home-export-game')));
      await pumpIo(tester, frames: 12);
      await tester.enterText(
        find.widgetWithText(TextField, 'Auteur'),
        'Avelune',
      );
      await tester.tap(find.byKey(const ValueKey('start-game-export')));
      await pumpIo(tester, frames: 120);
      expect(export.outputPath, destination.path, reason: export.error);
      expect(await tester.runAsync(destination.exists), isTrue);
      expect(find.text('Paquet produit'), findsOneWidget);
      await captureM3Widget(tester, capture, 'export-home-complete');
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

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
    await tester.tap(find.byKey(const ValueKey('home-export-game')));
    await pumpIo(tester, frames: 20);
    expect(find.textContaining('Profil d’export illisible'), findsOneWidget);
    expect(
      tester
          .widget<StudioButton>(find.byKey(const ValueKey('start-game-export')))
          .onPressed,
      isNull,
    );
    await tester.tap(find.text('Retour à l’accueil'));
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
