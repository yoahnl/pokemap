import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_screen.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  testWidgets('compact palette paints and erases the exact collision cell', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1024, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final port = WorkspaceMemoryPort();
    final controller = MapWorkspaceController(workspaceSession, port);
    final visuals = WorkspaceTestVisuals();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          loadVisuals: (_, _) async => visuals,
          runtimeBuilder: (_, _, _) => const SizedBox(),
          onClose: () async {},
          registerExitGuard: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Masquer les cartes'));
    await tester.pumpAndSettle();
    final ground = controller.active!.current.layers.single;

    Future<void> choose(String label) async {
      await tester.tap(find.byTooltip('Palette'));
      await tester.pumpAndSettle();
      final tool = find.byTooltip(label);
      expect(tool, findsOneWidget);
      await tester.ensureVisible(tool);
      await tester.tap(tool);
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Retour à la carte'));
      await tester.pumpAndSettle();
    }

    Future<void> paint() async {
      final canvas = tester.widget<MapWorkspaceCanvas>(
        find.byType(MapWorkspaceCanvas),
      );
      final surface = tester.renderObject<RenderBox>(
        find.byKey(const ValueKey('map-canvas')),
      );
      final settings = canvas.project.settings;
      final point = surface.localToGlobal(
        Offset(
          2.5 * settings.tileWidth * settings.displayScale,
          2.5 * settings.tileHeight * settings.displayScale,
        ),
      );
      await tester.tapAt(point);
      await tester.pumpAndSettle();
    }

    await choose('Dessiner les collisions');
    expect(
      tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .view
          .tool,
      StudioMapTool.collisionPaint,
    );
    await paint();
    final document = controller.active!;
    final index = 2 * document.current.size.width + 2;
    final painted = document.current.layers.whereType<CollisionLayer>().single;
    expect(painted.collisions[index], isTrue);
    expect(painted.collisions.where((cell) => cell), hasLength(1));
    expect(document.current.layers.first, ground);
    expect(document.dirty, isTrue);

    await choose('Effacer les collisions');
    expect(
      tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .view
          .tool,
      StudioMapTool.collisionErase,
    );
    await paint();
    final erased = document.current.layers.whereType<CollisionLayer>().single;
    expect(erased.collisions[index], isFalse);
    expect(erased.collisions.where((cell) => cell), isEmpty);
    expect(document.current.layers.first, ground);
    await tester.pumpWidget(const SizedBox());
  });
}
