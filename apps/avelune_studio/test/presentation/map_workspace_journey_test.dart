import 'dart:async';

import 'package:avelune_studio/src/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/src/features/map_workspace/presentation/map_workspace_screen.dart';
import 'package:avelune_studio/src/shared/design_system/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late WorkspaceMemoryPort port;
  late MapWorkspaceController controller;
  late WorkspaceTestVisuals visuals;
  late Future<bool> Function()? exitGuard;
  var closed = false;
  var runtimeStarts = 0;

  Future<void> open(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1500, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    port = WorkspaceMemoryPort();
    controller = MapWorkspaceController(workspaceSession, port);
    visuals = WorkspaceTestVisuals();
    closed = false;
    runtimeStarts = 0;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: MapWorkspaceScreen(
          controller: controller,
          loadVisuals: (_, _) async => visuals,
          runtimeBuilder: (entry, revision, close) {
            runtimeStarts++;
            return Scaffold(
              body: TextButton(
                onPressed: close,
                child: Text('Retour $revision'),
              ),
            );
          },
          onClose: () async {
            closed = true;
          },
          registerExitGuard: (guard) => exitGuard = guard,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Offset cell(WidgetTester tester, int x, int y) =>
      tester.getTopLeft(find.byKey(const ValueKey('map-canvas'))) +
      Offset(x * 32 + 8, y * 32 + 8);

  Future<void> place(WidgetTester tester, int x, int y) async {
    await tester.tap(find.text('Arbre').first);
    await tester.tapAt(cell(tester, x, y));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'preparing runtime blocks input and refuses a changed active document',
    (tester) async {
      await open(tester);
      await place(tester, 2, 2);
      port.saveGate = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('Enregistrer et tester')));
      await tester.pump();
      expect(
        tester
            .widget<AbsorbPointer>(
              find.byKey(const ValueKey('workspace-preparing')),
            )
            .absorbing,
        true,
      );
      await controller.activate(workspaceEntries.last);
      port.saveGate!.complete();
      await tester.pumpAndSettle();
      expect(runtimeStarts, 0);
      expect(controller.active!.base.mapId, 'b');
      expect(port.saved['a']!.placedElements.length, 1);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'place move stack undo redo save and runtime return preserve document',
    (tester) async {
      await open(tester);
      await place(tester, 3, 3);
      await tester.tapAt(cell(tester, 3, 3));
      await tester.pumpAndSettle();
      final document = controller.active!;
      expect(document.current.placedElements.length, 2);
      expect(document.undoCount, 2);
      final first = document.current.placedElements.first.id;
      final second = document.current.placedElements.last.id;
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.tapAt(cell(tester, 3, 3));
      await tester.pumpAndSettle();
      expect(document.selectedId, second);
      final stackChoices = find.text('Arbre');
      await tester.tap(stackChoices.last);
      await tester.pumpAndSettle();
      expect(document.selectedId, first);
      await tester.tap(find.byKey(const ValueKey('Passer devant')));
      await tester.pumpAndSettle();
      expect(
        document.current.placedElements.first.visualOrder,
        greaterThan(document.current.placedElements.last.visualOrder),
      );
      final start = cell(tester, 3, 3);
      final gesture = await tester.startGesture(start);
      await gesture.moveTo(start + const Offset(64, 32));
      await tester.pump();
      expect(document.current.placedElements.first.pos.x, 3);
      await gesture.up();
      await tester.pumpAndSettle();
      expect(document.current.placedElements.first.pos.x, 5);
      expect(document.undoCount, 4);
      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pumpAndSettle();
      expect(document.current.placedElements.first.pos.x, 3);
      await tester.tap(find.byKey(const ValueKey('Rétablir')));
      await tester.pumpAndSettle();
      expect(document.current.placedElements.first.pos.x, 5);
      await tester.tap(find.byKey(const ValueKey('Enregistrer')));
      await tester.pumpAndSettle();
      expect(document.dirty, false);
      expect(port.saved['a'], document.current);
      await tester.tap(find.byKey(const ValueKey('Enregistrer et tester')));
      await tester.pumpAndSettle();
      expect(runtimeStarts, 1);
      await tester.tap(find.text('Retour r1'));
      await tester.pumpAndSettle();
      expect(identical(controller.active, document), true);
      expect(port.catalogs, 1);
      expect(port.reads, 1);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
      expect(visuals.disposed, true);
    },
  );

  testWidgets(
    'dirty close offers cancel discard save and save conflict prevents runtime',
    (tester) async {
      await open(tester);
      await place(tester, 2, 2);
      await tester.tap(find.byKey(const ValueKey('Fermer le projet')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Annuler').last);
      await tester.pumpAndSettle();
      expect(closed, false);
      expect(controller.dirty, true);
      port.failSave = true;
      await tester.tap(find.byKey(const ValueKey('Enregistrer et tester')));
      await tester.pumpAndSettle();
      expect(runtimeStarts, 0);
      expect(find.text('Conflit détecté'), findsOneWidget);
      expect(controller.dirty, true);
      final exiting = exitGuard!();
      await tester.pumpAndSettle();
      await tester.tap(find.text('Abandonner'));
      await tester.pumpAndSettle();
      expect(await exiting, true);
      expect(port.writes, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'paint gesture is one history step and text input does not delete selection',
    (tester) async {
      await open(tester);
      await place(tester, 2, 2);
      final document = controller.active!;
      await tester.tap(find.textContaining('tuile 1'));
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(cell(tester, 6, 6));
      await gesture.moveTo(cell(tester, 9, 6));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(document.undoCount, 2);
      await tester.tap(find.byKey(const ValueKey('Annuler')));
      await tester.pumpAndSettle();
      expect(document.undoCount, 1);
      await tester.tap(find.byType(TextField).first);
      await tester.enterText(find.byType(TextField).first, 'arbres');
      await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
      await tester.pumpAndSettle();
      expect(document.current.placedElements.length, 1);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets(
    'failed navigation keeps visible and saved target; warm navigation preserves zoom',
    (tester) async {
      await open(tester);
      await tester.tap(find.byKey(const ValueKey('Zoom avant')));
      await tester.pumpAndSettle();
      final zoom = tester
          .widget<InteractiveViewer>(find.byType(InteractiveViewer))
          .transformationController!
          .value
          .clone();
      expect(controller.dirty, false);
      port.failedMap = 'b';
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Jardin').last);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButton<String>>(find.byType(DropdownButton<String>))
            .value,
        'a',
      );
      expect(find.text('Carte indisponible'), findsOneWidget);
      port.failedMap = null;
      await controller.activate(workspaceEntries.last);
      await tester.pumpAndSettle();
      await controller.activate(workspaceEntries.first);
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<InteractiveViewer>(find.byType(InteractiveViewer))
            .transformationController!
            .value,
        zoom,
      );
      expect(port.catalogs, 1);
      expect(port.reads, 3);
      expect(tester.takeException(), null);
      await tester.pumpWidget(const SizedBox());
    },
  );

  testWidgets('eraser reaches visible ground beneath an empty decor support', (
    tester,
  ) async {
    await open(tester);
    final document = controller.active!;
    final ground = (document.current.layers.single as TileLayer).copyWith(
      cells: List.filled(320, 1),
    );
    document.commit(
      document.current.copyWith(
        layers: [
          MapLayer.tile(
            id: 'decor',
            name: 'Décors',
            cells: List.filled(320, 0),
          ),
          ground,
        ],
      ),
    );
    controller.notify();
    await tester.pumpAndSettle();
    final history = document.undoCount;
    await tester.tap(find.byKey(const ValueKey('Gomme de tuiles')));
    await tester.tapAt(cell(tester, 4, 4));
    await tester.pumpAndSettle();
    final erased = document.current.layers.whereType<TileLayer>().firstWhere(
      (l) => l.id == 'ground',
    );
    expect(resolveTileLayerCell(erased, 4 * 20 + 4), null);
    expect(document.undoCount, history + 1);
    await tester.tap(find.byKey(const ValueKey('Annuler')));
    await tester.pumpAndSettle();
    expect(document.current.layers.last, ground);
    expect(tester.takeException(), null);
    await tester.pumpWidget(const SizedBox());
  });
}
