import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/project_session/application/project_session_controller.dart';
import 'package:avelune_studio/features/project_session/data/local_project_session_adapter.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../tool/create_example_project.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the real Studio paints, erases, and saves collision strokes', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = await Directory.systemTemp.createTemp(
      'avelune-collision-',
    );
    final root = await directory.resolveSymbolicLinks();
    final session = ProjectSessionController(LocalProjectSessionAdapter());
    try {
      await writeExampleProject(directory);
      await session.open(root);
      await tester.pumpWidget(StudioBootstrap(debugSession: session));
      await _until(tester, find.byKey(const ValueKey('home-tool-map')));
      await tester.tap(find.byKey(const ValueKey('home-tool-map')));
      await _until(tester, find.byKey(const ValueKey('map-canvas')));

      await tester.tap(find.text('Collisions'));
      await tester.pump();
      expect(find.text('Bloquer les cases'), findsOneWidget);
      expect(find.text('Libérer les cases'), findsOneWidget);
      final canvas = tester.widget<MapWorkspaceCanvas>(
        find.byType(MapWorkspaceCanvas),
      );
      expect(canvas.view.tool, StudioMapTool.collisionPaint);
      final bounds = tester.getRect(find.byKey(const ValueKey('map-canvas')));
      Offset cell(int x, int y) =>
          bounds.topLeft +
          Offset((x + .5) * bounds.width / 24, (y + .5) * bounds.height / 16);
      await tester.dragFrom(cell(8, 2), cell(11, 2) - cell(8, 2));
      await tester.pump();
      final activeCanvas = tester.widget<MapWorkspaceCanvas>(
        find.byType(MapWorkspaceCanvas),
      );
      expect(
        activeCanvas.document.current.layers
            .whereType<CollisionLayer>()
            .single
            .collisions[2 * 24 + 8],
        isTrue,
        reason: activeCanvas.document.error,
      );
      await tester.tap(find.text('Libérer les cases'));
      await tester.pump();
      await tester.tapAt(cell(9, 2));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('Rétablir')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await _until(tester, find.text('Enregistré'));

      final map = MapData.fromJson(
        jsonDecode(
              await File(p.join(root, 'maps', 'jardin.json')).readAsString(),
            )
            as Map<String, dynamic>,
      );
      final cells = map.layers.whereType<CollisionLayer>().single.collisions;
      for (final x in [8, 10, 11]) {
        expect(cells[2 * 24 + x], isTrue);
      }
      expect(cells[2 * 24 + 9], isFalse);
      expect(cells[3 * 24 + 9], isFalse);
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await session.dispose();
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));
}

Future<void> _until(WidgetTester tester, Finder finder) async {
  for (var attempt = 0; attempt < 250; attempt++) {
    await tester.pump(const Duration(milliseconds: 50));
    if (finder.evaluate().isNotEmpty) return;
    await Future<void>.delayed(const Duration(milliseconds: 20));
  }
  throw TestFailure('Studio did not reach the expected state');
}
