import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
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

void main() {
  late EditableMapDocument document;
  late MapEditorController editor;
  late MapWorkspaceEditingState view;

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
    view = MapWorkspaceEditingState();
  });
  tearDown(() {
    editor.dispose();
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

  test('undo follows the active map and each map keeps its history', () async {
    final controller = MapWorkspaceController(
      workspaceSession,
      WorkspaceMemoryPort(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(workspaceEntries.first);
    final first = controller.active!;
    MapEditingCommands(
      first,
      workspaceProject,
    ).place(workspaceElement, const GridPos(x: 1, y: 1));
    await controller.activate(workspaceEntries.last);
    final second = controller.active!;
    expect(second.canUndo, isFalse);
    MapEditingCommands(
      second,
      workspaceProject,
    ).place(workspaceElement, const GridPos(x: 4, y: 4));
    second.restore(redo: false);
    expect(second.current.placedElements, isEmpty);
    expect(first.current.placedElements, hasLength(1));
    await controller.activate(workspaceEntries.first);
    expect(controller.active, same(first));
    expect(first.canUndo, isTrue);
    first.restore(redo: false);
    expect(first.current.placedElements, isEmpty);
    expect(second.canRedo, isTrue);
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
