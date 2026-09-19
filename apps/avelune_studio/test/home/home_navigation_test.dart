import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:avelune_studio/features/home/data/memory_recent_projects_adapter.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/project_session/project_session_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_layout.dart';
import 'package:avelune_studio/presentation/shell/studio_home_navigation.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets(
    'home keeps mounted workspace, document, zoom and undo; cancelled switch preserves it',
    (tester) async {
      tester.view.physicalSize = const Size(1536, 1024);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final port = _Sessions();
      final session = ProjectSessionController(port);
      final maps = WorkspaceMemoryPort();
      final controller = MapWorkspaceController(workspaceSession, maps);
      final visuals = WorkspaceTestVisuals();
      final recent = MemoryRecentProjectsAdapter();
      var chosen = '/fixture';
      await tester.pumpWidget(
        MaterialApp(
          theme: studioTheme(),
          home: ProjectSessionScreen(
            session: session,
            recentProjects: recent,
            chooseDirectory: () async => chosen,
            workspaceBuilder: (_, close) => Builder(
              builder: (context) => MapWorkspaceScreen(
                controller: controller,
                home: StudioHomeScope.of(context),
                loadVisuals: (_, _) async => visuals,
                runtimeBuilder: (_, _, _) => const SizedBox(),
                onClose: close,
                registerExitGuard: (_) {},
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(maps.reads, 0);
      await tester.tap(find.byKey(const ValueKey('open-project-picker')));
      await tester.pumpAndSettle();
      final document = controller.active!;
      document.commit(
        document.current.copyWith(name: 'Modification conservée'),
      );
      final originalState = tester.state(find.byType(MapWorkspaceScreen));
      final layout = tester.widget<MapWorkspaceLayout>(
        find.byType(MapWorkspaceLayout),
      );
      final view = layout.view!;
      view.transform.value = Matrix4.identity()
        ..scaleByDouble(1.75, 1.75, 1, 1);
      final transform = view.transform.value.clone();
      final reads = maps.reads;
      layout.onHome!();
      await tester.pumpAndSettle();
      expect(find.text('Reprendre mon projet'), findsOneWidget);
      expect(controller.active, same(document));
      expect(document.dirty, isTrue);
      expect(maps.reads, reads);
      chosen = '/other';
      await tester.tap(find.text('Ouvrir un autre projet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(port.opens, ['/fixture']);
      expect(port.closed, isEmpty);
      expect(controller.active, same(document));
      await tester.tap(find.text('Reprendre mon projet'));
      await tester.pumpAndSettle();
      expect(
        tester.state(find.byType(MapWorkspaceScreen)),
        same(originalState),
      );
      expect(
        tester.widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout)).view,
        same(view),
      );
      expect(view.transform.value, transform);
      expect(document.current.name, 'Modification conservée');
      controller.restore(redo: false);
      await tester.pumpAndSettle();
      expect(document.current.name, 'a');
      expect(maps.reads, reads);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await session.dispose();
      controller.dispose();
    },
  );
}

class _Sessions implements ProjectSessionPort {
  final opens = <String>[];
  final closed = <ProjectSession>[];
  @override
  Future<ProjectSession> open(String directoryPath) async {
    opens.add(directoryPath);
    return workspaceSession;
  }

  @override
  Future<void> close(ProjectSession session) async => closed.add(session);
}
