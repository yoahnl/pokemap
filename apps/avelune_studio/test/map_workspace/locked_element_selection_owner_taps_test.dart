import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_selection_owner_fixture.dart';
import '../support/map_workspace_fixture.dart';
import 'locked_element_selection_owner_support.dart';

void main() {
  late MapSelectionOwnerHarness h;
  late MapEditorController editor;
  setUp(() {
    h = MapSelectionOwnerHarness.of(workspaceProject);
    editor = MapEditorController(
      session: workspaceSession,
      mapId: h.document.current.id,
      port: MemoryEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'initial',
      ),
    );
    h.document.editor = editor;
  });
  tearDown(() {
    h.dispose();
    editor.dispose();
  });

  testWidgets(
    'hidden decor and its hidden layer are excluded from real taps and stale moves',
    (tester) async {
      final commands = MapEditingCommands(h.document, h.project);
      final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
      final front = commands.place(
        workspaceElement,
        const GridPos(x: 4, y: 4),
      )!;
      await h.pump(tester);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      final before = h.document.current;
      await editor.setHidden('decor', front, true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(h.document.selectedId, isNull);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, back);
      commands.move(front, const GridPos(x: 7, y: 7));
      expect(h.document.current, same(before));
      await editor.showAll();
      h.view.clearSelection(h.document);
      h.redraw();
      await tester.pumpAndSettle();
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      final layer = h.document.current.placedElements
          .singleWhere((entry) => entry.id == front)
          .layerId;
      await editor.setHidden('layer', layer, true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(h.document.isElementHidden('decor', front), isTrue);
      expect(h.document.isElementHidden('decor', back), isTrue);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, isNull);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'locked front decor lets real taps and drags reach the decor behind',
    (tester) async {
      final commands = MapEditingCommands(h.document, h.project);
      final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
      final front = commands.place(
        workspaceElement,
        const GridPos(x: 4, y: 4),
      )!;
      await h.pump(tester);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      await editor.setLocked('decor', front, true);
      h.redraw();
      await tester.pumpAndSettle();
      expect(h.document.selectedId, isNull);
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, back);
      await h.dragCells(tester, 4, 4, 5, 4);
      expect(
        h.document.current.placedElements
            .firstWhere((entry) => entry.id == front)
            .pos,
        const GridPos(x: 4, y: 4),
      );
      expect(
        h.document.current.placedElements
            .firstWhere((entry) => entry.id == back)
            .pos,
        const GridPos(x: 5, y: 4),
      );
      await editor.setLocked('decor', front, false);
      h.redraw();
      await tester.pumpAndSettle();
      await h.tapCell(tester, 4, 4);
      expect(h.document.selectedId, front);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('locking an effects layer makes its decor click through', (
    tester,
  ) async {
    final commands = MapEditingCommands(h.document, h.project);
    final back = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    final front = commands.place(workspaceElement, const GridPos(x: 4, y: 4))!;
    final map = h.document.current;
    h.document.commit(
      map.copyWith(
        layers: [
          MapLayer.tile(
            id: 'effects',
            name: 'Effets',
            cells: List.filled(320, 0),
          ),
          ...map.layers,
        ],
        placedElements: [
          for (final entry in map.placedElements)
            entry.id == front ? entry.copyWith(layerId: 'effects') : entry,
        ],
      ),
    );
    await h.pump(tester);
    await h.tapCell(tester, 4, 4);
    expect(h.document.selectedId, front);
    final before = h.document.current;
    await editor.setLocked('layer', 'effects', true);
    h.redraw();
    await tester.pumpAndSettle();
    await h.tapCell(tester, 4, 4);
    expect(h.document.selectedId, back);
    commands.move(front, const GridPos(x: 9, y: 9));
    expect(h.document.current, same(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets('locking a decor during a drag cancels its pending movement', (
    tester,
  ) async {
    final id = MapEditingCommands(
      h.document,
      h.project,
    ).place(workspaceElement, const GridPos(x: 4, y: 4))!;
    await h.pump(tester);
    final gesture = await tester.startGesture(h.cell(tester, 4, 4));
    await gesture.moveTo(h.cell(tester, 6, 4));
    await tester.pump();
    await editor.setLocked('decor', id, true);
    h.redraw();
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(
      h.document.current.placedElements.single.pos,
      const GridPos(x: 4, y: 4),
    );
    expect(h.document.selectedId, isNull);
    expect(
      h.view.selectedFor(h.document.current.id, MapSelectionFamily.decor),
      isNull,
    );
    expect(tester.takeException(), isNull);
  });
}
