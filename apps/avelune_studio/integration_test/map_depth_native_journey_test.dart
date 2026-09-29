import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/app/studio_bootstrap.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
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

  testWidgets('the real Studio can reorder overlapping decorations', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = await Directory.systemTemp.createTemp('avelune-depth-');
    final root = await directory.resolveSymbolicLinks();
    final session = ProjectSessionController(LocalProjectSessionAdapter());
    try {
      await writeExampleProject(directory);
      await session.open(root);
      await tester.pumpWidget(StudioBootstrap(debugSession: session));
      await _until(tester, find.byKey(const ValueKey('home-tool-map')));
      await tester.tap(find.byKey(const ValueKey('home-tool-map')));
      await _until(tester, find.byKey(const ValueKey('map-canvas')));

      for (final id in ['arbre', 'rocher', 'arbre']) {
        await tester.tap(find.byKey(ValueKey('decor-$id')));
        await tester.pump();
        final bounds = tester.getRect(find.byKey(const ValueKey('map-canvas')));
        await tester.tapAt(
          bounds.topLeft +
              Offset(8.5 * bounds.width / 24, 7.5 * bounds.height / 16),
        );
        await tester.pump();
      }
      expect(find.textContaining('Position 1 / 3'), findsWidgets);
      await tester.tap(find.byKey(const ValueKey('Passer derrière')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await _until(tester, find.text('Enregistré'));
      expect(find.textContaining('Position 1 / 3'), findsWidgets);

      final map = MapData.fromJson(
        jsonDecode(
              await File(p.join(root, 'maps', 'jardin.json')).readAsString(),
            )
            as Map<String, dynamic>,
      );
      final stack = map.placedElements
          .where((element) => element.pos == const GridPos(x: 8, y: 7))
          .toList();
      expect(stack, hasLength(3));
      expect(stack.map((element) => element.layerId), everyElement('decor'));
      expect(stack.last.visualOrder, lessThan(stack.first.visualOrder));
      expect(tester.takeException(), isNull);
    } finally {
      await tester.pumpWidget(const SizedBox.shrink());
      await session.dispose();
      if (await directory.exists()) await directory.delete(recursive: true);
    }
  }, timeout: const Timeout(Duration(minutes: 5)));

  testWidgets('the decor eraser removes one top instance and is undoable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1536, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final directory = await Directory.systemTemp.createTemp('avelune-erase-');
    final root = await directory.resolveSymbolicLinks();
    final session = ProjectSessionController(LocalProjectSessionAdapter());
    try {
      await writeExampleProject(directory);
      await session.open(root);
      await tester.pumpWidget(StudioBootstrap(debugSession: session));
      await _until(tester, find.byKey(const ValueKey('home-tool-map')));
      await tester.tap(find.byKey(const ValueKey('home-tool-map')));
      await _until(tester, find.byKey(const ValueKey('map-canvas')));
      final bounds = tester.getRect(find.byKey(const ValueKey('map-canvas')));
      final cell =
          bounds.topLeft +
          Offset(8.5 * bounds.width / 24, 7.5 * bounds.height / 16);
      for (final id in ['arbre', 'rocher']) {
        await tester.tap(find.byKey(ValueKey('decor-$id')));
        await tester.pump();
        await tester.tapAt(cell);
        await tester.pump();
      }
      expect(
        tester
            .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
            .document
            .current
            .placedElements
            .where((element) => element.pos == const GridPos(x: 8, y: 7)),
        hasLength(2),
      );
      final currentCanvas = tester.widget<MapWorkspaceCanvas>(
        find.byType(MapWorkspaceCanvas),
      );
      final topBefore = MapEditingCommands(
        currentCanvas.document,
        currentCanvas.project,
      ).stack(const GridPos(x: 8, y: 7)).first;

      await tester.tap(find.byTooltip('Autres outils de carte'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gomme de décors'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Gomme de décors'));
      await tester.pump();
      expect(
        tester
            .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
            .view
            .tool,
        StudioMapTool.eraseDecor,
      );
      await tester.tapAt(cell);
      await tester.pump();
      MapData current() => tester
          .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
          .document
          .current;
      Iterable<MapPlacedElement> stack() => current().placedElements.where(
        (element) => element.pos == const GridPos(x: 8, y: 7),
      );
      expect(stack(), hasLength(1));
      expect(stack().single.id, isNot(topBefore.id));
      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pump();
      expect(stack(), hasLength(2));
      await tester.tap(find.byKey(const ValueKey('Rétablir')));
      await tester.pump();
      expect(stack(), hasLength(1));
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await _until(tester, find.text('Enregistré'));

      final reopened = MapData.fromJson(
        jsonDecode(
              await File(p.join(root, 'maps', 'jardin.json')).readAsString(),
            )
            as Map<String, dynamic>,
      );
      final savedStack = reopened.placedElements.where(
        (element) => element.pos == const GridPos(x: 8, y: 7),
      );
      expect(savedStack, hasLength(1));
      expect(savedStack.single.id, isNot(topBefore.id));
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
