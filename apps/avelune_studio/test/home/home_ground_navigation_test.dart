import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/shared/widgets/layout/studio_primary_navigation.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'the home ground tool returns to the map with the ground gesture',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      final session = ProjectSessionController(_Sessions());
      final controller = MapWorkspaceController(workspaceSession, _Maps());
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: ProjectSessionScreen(
            session: session,
            recentProjects: MemoryRecentProjectsAdapter(),
            chooseDirectory: () async => '/fixture',
            workspaceBuilder: (_, close) => Builder(
              builder: (context) => MapWorkspaceScreen(
                controller: controller,
                home: StudioHomeScope.of(context),
                loadVisuals: (_, _) async => WorkspaceTestVisuals(),
                runtimeBuilder: (_, _, _) => const SizedBox(),
                onClose: close,
                registerExitGuard: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final ground = find.byKey(const ValueKey('home-tool-terrains'));
      await tester.ensureVisible(ground);
      expect(
        find.descendant(of: ground, matching: find.text('Peindre le sol')),
        findsOneWidget,
      );
      await tester.tap(ground);
      await tester.pumpAndSettle();
      final nav = find.byType(StudioPrimaryNavigation);
      expect(tester.widget<StudioPrimaryNavigation>(nav).active, 'map');
      final view = tester
          .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
          .view!;
      expect(view.paletteTab, 'Terrains');
      expect(
        tester
            .widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout))
            .palette,
        isTrue,
      );
      expect(
        {StudioMapTool.terrain, StudioMapTool.select}.contains(view.tool),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.dispose();
      controller.dispose();
    },
  );
}

class _Maps extends WorkspaceMemoryPort {}

class _Sessions implements ProjectSessionPort {
  @override
  Future<ProjectSession> open(String directoryPath) async => workspaceSession;
  @override
  Future<void> close(ProjectSession session) async {}
}
