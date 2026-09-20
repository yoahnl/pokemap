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
import 'package:map_core/map_core_domain.dart';

import '../characters/character_editing_test.dart' show guide;
import '../support/map_workspace_fixture.dart';

void main() {
  for (final compact in [false, true]) {
    testWidgets(
      'home character placement preserves map and opens palette: compact=$compact',
      (tester) async {
        tester.view.physicalSize = compact
            ? const Size(1024, 640)
            : const Size(1536, 1024);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final session = ProjectSessionController(_Sessions());
        final port = _Maps();
        final controller = MapWorkspaceController(workspaceSession, port);
        var openings = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: studioTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(compact ? 1.5 : 1)),
              child: child!,
            ),
            home: ProjectSessionScreen(
              session: session,
              recentProjects: MemoryRecentProjectsAdapter(),
              chooseDirectory: () async {
                openings++;
                return '/fixture';
              },
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
        final shortcut = find.byKey(const ValueKey('home-tool-characters'));
        await tester.ensureVisible(shortcut);
        expect(find.text('Placer un personnage'), findsOneWidget);
        await tester.tap(shortcut);
        await tester.pumpAndSettle();
        expect(openings, 1);
        expect(
          find.byKey(const ValueKey('character-guide')).hitTestable(),
          findsOneWidget,
        );
        if (compact) {
          await tester.tap(find.byTooltip('Retour à la carte'));
          await tester.pumpAndSettle();
        }
        MapWorkspaceLayout layout() =>
            tester.widget<MapWorkspaceLayout>(find.byType(MapWorkspaceLayout));
        final document = controller.active!;
        document.commit(document.current.copyWith(name: 'Travail conservé'));
        final before = document.current;
        final view = layout().view!;
        final transform = view.transform.value.clone();
        view.brush = workspaceElement;
        view.tool = StudioMapTool.place;
        if (!compact) layout().onPalette();
        layout().onHome!();
        await tester.pumpAndSettle();
        await tester.ensureVisible(shortcut);
        await tester.tap(shortcut);
        await tester.pumpAndSettle();
        expect(view.tool, StudioMapTool.select);
        expect(view.brush, isNull);
        expect(view.tile, isNull);
        expect(view.terrain, isNull);
        expect(view.paletteTab, 'Personnages');
        expect(find.text('Choisissez un personnage à placer.'), findsOneWidget);
        final nav = find.byType(StudioPrimaryNavigation);
        expect(tester.widget<StudioPrimaryNavigation>(nav).active, 'map');
        expect(
          find.descendant(of: nav, matching: find.byTooltip('Personnages')),
          findsNothing,
        );
        expect(controller.active, same(document));
        expect(document.current, same(before));
        expect(view.transform.value, transform);
        expect(document.canUndo, isTrue);
        if (compact) {
          await tester.tap(find.byTooltip('Retour à la carte'));
          await tester.pumpAndSettle();
        }
        Future<void> clickMap() async {
          final scale = view.transform.value.getMaxScaleOnAxis();
          final settings = controller.project!.settings;
          await tester.tapAt(
            tester.getTopLeft(find.byKey(const ValueKey('map-canvas'))) +
                Offset(
                  3.4 * settings.tileWidth * settings.displayScale * scale,
                  3.4 * settings.tileHeight * settings.displayScale * scale,
                ),
          );
          await tester.pumpAndSettle();
        }

        await clickMap();
        expect(document.current, same(before));
        if (compact) {
          await tester.tap(find.byTooltip('Palette'));
          await tester.pumpAndSettle();
        }
        await tester.tap(find.byKey(const ValueKey('character-guide')));
        await tester.pumpAndSettle();
        expect(view.tool, StudioMapTool.character);
        await clickMap();
        expect(document.current.entities.single.npc!.characterId, guide.id);
        expect(document.current.placedElements, before.placedElements);
        controller.restore(redo: false);
        expect(document.current, before);
        expect(openings, 1);
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox());
        await session.dispose();
        controller.dispose();
      },
    );
  }
}

class _Maps extends WorkspaceMemoryPort {
  @override
  Future<ProjectManifest> loadProject(ProjectSession session) async =>
      workspaceProject.copyWith(characters: [guide]);
}

class _Sessions implements ProjectSessionPort {
  @override
  Future<ProjectSession> open(String directoryPath) async => workspaceSession;
  @override
  Future<void> close(ProjectSession session) async {}
}
