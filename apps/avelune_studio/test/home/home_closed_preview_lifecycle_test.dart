import 'package:avelune_studio/features/game_export/data/studio_game_export_controller.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/features/game_export/studio_game_export_page.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/studio_home_map_preview.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/m2_ui_fixture.dart';

void main() {
  for (final opening in ['picker', 'preopened', 'replacement']) {
    testWidgets('home closes after export and reopens, opening=$opening', (
      tester,
    ) async {
      final openedBeforeMount = opening != 'picker';
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => M2UiFixture.create(tester),
      ))!;
      final session = ProjectSessionController(LocalProjectSessionAdapter());
      if (openedBeforeMount) {
        await tester.runAsync(() => session.open(fixture.directory.path));
      }
      final export = StudioGameExportController(
        projectRoot: fixture.directory,
        projectName: fixture.session.name,
      );
      final visuals = <StudioMapResources>[];
      StudioHomeNavigation? home;
      addTearDown(() async {
        await tester.pumpWidget(const SizedBox());
        export.dispose();
        await tester.runAsync(() async {
          await session.dispose();
          await fixture.dispose();
        });
      });
      Widget app(ProjectSessionController owner) => MaterialApp(
        theme: studioTheme(),
        home: ProjectSessionScreen(
          session: owner,
          recentProjects: MemoryRecentProjectsAdapter(),
          chooseDirectory: () async => fixture.directory.path,
          workspaceBuilder: (_, close) => Builder(
            builder: (context) {
              home = StudioHomeScope.of(context);
              return MapWorkspaceScreen(
                controller: fixture.controller,
                home: home,
                gameExport: export,
                gameExportPicker: (_) async => null,
                loadVisuals: (session, manifest) async {
                  final loaded = await StudioMapResources.load(
                    session,
                    manifest,
                  );
                  visuals.add(loaded);
                  return loaded;
                },
                resourcePort: WidgetResourcePort(fixture.resources, tester),
                runtimeBuilder: (_, _, _) => const SizedBox(),
                onClose: close,
                registerExitGuard: (_) {},
              );
            },
          ),
        ),
      );
      if (opening == 'replacement') {
        final previous = ProjectSessionController(LocalProjectSessionAdapter());
        await tester.pumpWidget(app(previous));
        await tester.pumpAndSettle();
        addTearDown(previous.dispose);
      }
      await tester.pumpWidget(app(session));
      await tester.pumpAndSettle();
      if (!openedBeforeMount) {
        await tester.tap(find.byKey(const ValueKey('open-project-picker')));
      }
      await pumpIo(tester, frames: 60);
      if (!openedBeforeMount) await tester.tap(find.byTooltip('Accueil'));
      await pumpIo(tester, frames: 60);
      expect(find.byType(StudioHomeMapPreview), findsNWidgets(2));
      await tester.tap(find.byKey(const ValueKey('home-export-game')));
      await pumpIo(tester, frames: 16);
      expect(find.byType(StudioGameExportPage), findsOneWidget);
      await tester.tap(find.text('Retour à l’accueil'));
      await pumpIo(tester, frames: 16);
      expect(find.byType(StudioHomeMapPreview), findsNWidgets(2));
      await tester.tap(find.text('Fermer le projet'));
      await pumpIo(tester, frames: 16);
      expect(session.state.project, isNull);
      expect(home!.maps, isEmpty);
      expect(home!.mapLibrary, isNull);
      expect(home!.mapPreviewBuilder, isNull);
      expect(
        find.byType(StudioHomeMapPreview, skipOffstage: false),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byKey(const ValueKey('open-project-picker')));
      await pumpIo(tester, frames: 60);
      expect(session.state.project, isNotNull);
      expect(visuals, hasLength(2));
      await tester.tap(find.byTooltip('Accueil'));
      await pumpIo(tester, frames: 16);
      expect(find.byType(StudioHomeMapPreview), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });
  }
}
