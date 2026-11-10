import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_visibility_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late MapWorkspaceEditingState view;
  late MapEditorController editor;
  late _EditorPort port;
  late MapElementVisibilityCommands commands;
  late MapElementListEntry entry;

  setUp(() {
    final map = workspaceMap('a').copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 2, y: 2),
        ),
      ],
    );
    document = EditableMapDocument(
      MapWorkspaceDocument(map: map, revision: 'map0', mapId: 'a'),
    );
    view = MapWorkspaceEditingState();
    port = _EditorPort();
    editor = MapEditorController(
      session: workspaceSession,
      mapId: 'a',
      port: port,
      state: MapEditorWorkspaceState(
        state: MapEditorState(),
        revision: 'editor0',
      ),
    );
    document.editor = editor;
    final catalog = MapElementCatalog(map, workspaceProject);
    entry = catalog.entries.singleWhere((entry) => entry.kind == 'decor');
    commands = MapElementVisibilityCommands(
      document,
      view,
      catalog: () => catalog,
    );
  });

  tearDown(() => editor.dispose());

  test(
    'locking selected content clears selection and writes only editor state',
    () async {
      final map = document.current;
      view.select(document, MapSelectionFamily.decor, 'tree');
      await commands.setLocked([entry], true);
      expect(view.target, isNull);
      expect(editor.current.isLocked('decor', 'tree'), isTrue);
      expect(port.state.isLocked('decor', 'tree'), isTrue);
      expect(port.writes, 1);
      expect(port.mapIds, ['a']);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      expect(document.canUndo, isFalse);
      await editor.undo();
      expect(editor.current.isLocked('decor', 'tree'), isFalse);
    },
  );

  test(
    'hiding selected content clears selection without editing the map',
    () async {
      final map = document.current;
      view.select(document, MapSelectionFamily.decor, 'tree');
      await commands.setHidden([entry], true);
      expect(view.target, isNull);
      expect(port.state.isHidden('decor', 'tree'), isTrue);
      expect(document.current, same(map));
      await commands.setHidden([entry], false);
      expect(port.state.isHidden('decor', 'tree'), isFalse);
    },
  );

  test('inherited layer lock refuses individual unlocking', () async {
    await editor.setLocked('layer', 'ground', true);
    final writes = port.writes;
    await commands.setLocked([entry], false);
    expect(document.error, contains('verrouillés par leur calque'));
    expect(document.isElementLocked('decor', 'tree'), isTrue);
    expect(port.writes, writes);
  });

  test('inherited layer visibility refuses individual showing', () async {
    await editor.setHidden('layer', 'ground', true);
    final writes = port.writes;
    await commands.setHidden([entry], false);
    expect(document.error, contains('masqués par leur calque'));
    expect(document.isElementHidden('decor', 'tree'), isTrue);
    expect(port.writes, writes);
  });

  test('save failures preserve the editor draft and map content', () async {
    final map = document.current;
    port.fail = true;
    await commands.setLocked([entry], true);
    expect(editor.error, contains('save refused'));
    expect(editor.dirty, isTrue);
    expect(editor.current.isLocked('decor', 'tree'), isTrue);
    expect(port.state.isLocked('decor', 'tree'), isFalse);
    expect(document.current, same(map));
  });
}

class _EditorPort implements MapEditorPort {
  MapEditorState state = MapEditorState();
  final mapIds = <String>[];
  int writes = 0;
  bool fail = false;

  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'editor$writes');

  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState next,
    String expectedRevision,
  ) async {
    writes++;
    mapIds.add(mapId);
    if (fail) throw StateError('save refused');
    state = next;
    return MapEditorWorkspaceState(state: state, revision: 'editor$writes');
  }
}
