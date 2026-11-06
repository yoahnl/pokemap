import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_decor_group_editing.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_elements_panel.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_multi_selection_inspector.dart';
import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_view_state.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

MapData _map() => workspaceMap('a').copyWith(
  placedElements: const [
    MapPlacedElement(
      id: 'bed',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 2, y: 2),
    ),
    MapPlacedElement(
      id: 'desk',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 5, y: 2),
    ),
    MapPlacedElement(
      id: 'lamp',
      layerId: 'ground',
      elementId: 'tree',
      pos: GridPos(x: 8, y: 2),
    ),
  ],
);

GridPos _pos(EditableMapDocument document, String id) =>
    document.current.placedElements.singleWhere((item) => item.id == id).pos;

void main() {
  late EditableMapDocument document;
  late MapEditorController editor;
  late MapWorkspaceViewState view;

  setUp(() async {
    document = EditableMapDocument(
      MapWorkspaceDocument(map: _map(), revision: 'base', mapId: 'a'),
    );
    editor = MapEditorController(
      session: workspaceSession,
      mapId: 'a',
      port: _MemoryEditorPort(),
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'initial',
      ),
    );
    document.editor = editor;
    await editor.setLocked('decor', 'lamp', true);
    view = MapWorkspaceViewState();
  });
  tearDown(() {
    editor.dispose();
    view.dispose();
  });

  test('different X values make the field mixed, not arbitrary', () {
    final summary = MapDecorGroupEditing(
      document,
      workspaceProject,
    ).summarize(['bed', 'desk', 'lamp']);
    expect(summary.mixedX, isTrue);
    expect(summary.x, isNull);
    expect(summary.mixedY, isFalse);
    expect(summary.y, 2);
    expect(summary.editableIds, ['bed', 'desk']);
    expect(summary.lockedIds, ['lamp']);
  });

  test('a group move skips locked items and is one undo unit', () {
    final editing = MapDecorGroupEditing(document, workspaceProject);
    final before = document.undoCount;
    expect(editing.move(['bed', 'desk', 'lamp'], x: 9), isTrue);
    expect(_pos(document, 'bed'), const GridPos(x: 9, y: 2));
    expect(_pos(document, 'desk'), const GridPos(x: 9, y: 2));
    expect(_pos(document, 'lamp'), const GridPos(x: 8, y: 2));
    expect(document.undoCount, before + 1);
    document.restore(redo: false);
    expect(_pos(document, 'bed'), const GridPos(x: 2, y: 2));
    expect(_pos(document, 'desk'), const GridPos(x: 5, y: 2));
    expect(document.canRedo, isTrue);
    expect(editing.move(['bed'], y: 4), isTrue);
    expect(document.canRedo, isFalse);
  });

  test('a refused group move changes nothing and keeps history', () {
    final editing = MapDecorGroupEditing(document, workspaceProject);
    final before = document.current;
    final undo = document.undoCount;
    expect(editing.move(['bed', 'desk'], x: 500), isFalse);
    expect(document.current, same(before));
    expect(document.undoCount, undo);
    expect(document.error, isNotNull);
  });

  test('a group removal keeps locked items and undoes at once', () {
    final editing = MapDecorGroupEditing(document, workspaceProject);
    expect(editing.remove(['bed', 'lamp']), isTrue);
    expect(document.current.placedElements.map((item) => item.id), [
      'desk',
      'lamp',
    ]);
    document.restore(redo: false);
    expect(document.current.placedElements, hasLength(3));
  });

  test('changing map drops a stale multiple selection', () {
    view.select(document, MapSelectionFamily.decor, 'bed');
    view.toggleDecorInSelection(document, 'desk');
    expect(view.selectedDecorIds('a'), {'bed', 'desk'});
    final other = EditableMapDocument(
      MapWorkspaceDocument(map: workspaceMap('b'), revision: 'r', mapId: 'b'),
    );
    view.select(other, MapSelectionFamily.decor, 'tree-b');
    expect(view.selectedDecorIds('a'), isEmpty);
    expect(view.selectedDecorIds('b'), {'tree-b'});
  });

  testWidgets('shift-click builds a selection that the inspector edits', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => Row(
              children: [
                SizedBox(
                  width: 360,
                  child: MapElementsPanel(
                    document: document,
                    project: workspaceProject,
                    view: view,
                    onChanged: () => setState(() {}),
                  ),
                ),
                if (view.selectedDecorIds('a').length > 1)
                  SizedBox(
                    width: 320,
                    child: MapMultiSelectionInspector(
                      document: document,
                      project: workspaceProject,
                      view: view,
                      onChanged: () => setState(() {}),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-element-decor-bed')));
    await tester.pumpAndSettle();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const ValueKey('map-element-decor-desk')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pumpAndSettle();
    expect(view.selectedDecorIds('a'), {'bed', 'desk'});
    expect(find.text('2 décors sélectionnés'), findsOneWidget);
    final x = find.byKey(const ValueKey('map-multi-selection-x'));
    expect(
      tester
          .widget<TextField>(
            find.descendant(of: x, matching: find.byType(TextField)),
          )
          .controller!
          .text,
      isEmpty,
    );
    expect(find.text('Valeurs différentes'), findsWidgets);
    await tester.enterText(
      find.descendant(of: x, matching: find.byType(TextField)),
      '7',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(_pos(document, 'bed').x, 7);
    expect(_pos(document, 'desk').x, 7);
    expect(_pos(document, 'lamp').x, 8);
  });
}

final class _MemoryEditorPort implements MapEditorPort {
  var state = MapEditorState();
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'initial');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState state,
    String expectedRevision,
  ) async {
    this.state = state;
    return MapEditorWorkspaceState(state: state, revision: 'saved');
  }
}
