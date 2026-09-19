import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/platform/rendering/studio_map_resources.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/m2_ui_fixture.dart';
import '../support/capture_m3_widget.dart';

void main() {
  testWidgets(
    'opens disposable on-disk project and captures the real active home',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final fixture = (await tester.runAsync(
        () => M2UiFixture.create(tester),
      ))!;
      final session = ProjectSessionController(LocalProjectSessionAdapter());
      final key = GlobalKey();
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: RepaintBoundary(
            key: key,
            child: ProjectSessionScreen(
              session: session,
              recentProjects: MemoryRecentProjectsAdapter(),
              chooseDirectory: () async => fixture.directory.path,
              workspaceBuilder: (_, close) => Builder(
                builder: (context) => MapWorkspaceScreen(
                  controller: fixture.controller,
                  home: StudioHomeScope.of(context),
                  loadVisuals: (session, manifest) =>
                      StudioMapResources.load(session, manifest),
                  resourcePort: WidgetResourcePort(fixture.resources, tester),
                  runtimeBuilder: (_, _, _) => const SizedBox(),
                  onClose: close,
                  registerExitGuard: (_) {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('open-project-picker')));
      await pumpIo(tester, frames: 60);
      expect(
        session.state.project?.directoryPath,
        fixture.session.directoryPath,
      );
      expect(find.byType(MapWorkspaceLayout), findsOneWidget);
      final document = fixture.controller.active!;
      document.commit(
        document.current.copyWith(
          name: 'Carte de démonstration non enregistrée',
        ),
      );
      tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .onHome!();
      await tester.pumpAndSettle();
      await captureM3Widget(tester, key, 'ui01-active-project');
      expect(fixture.controller.active, same(document));
      expect(document.dirty, isTrue);
      await tester.tap(find.text('Reprendre mon projet'));
      await tester.pumpAndSettle();
      expect(fixture.controller.active, same(document));
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() async {
        await session.dispose();
        await fixture.dispose();
      });
    },
  );
}
