import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('portable sessions cannot mutate an optimistic editor draft', () async {
    final port = _Port()
      ..state = MapEditorState(
        lockedElements: {'decor:mist'},
        hiddenElements: {'layer:path'},
      );
    const session = ProjectSession(
      sessionId: 'portable',
      name: 'Lecture seule',
      directoryPath: '/fixture',
      storage: ProjectSessionStorage.portableCatalog,
    );
    final editor = await MapEditorController.open(session, 'a', port);
    addTearDown(editor.dispose);
    final before = editor.current;
    expect(await editor.setHidden('decor', 'tree', true), isFalse);
    expect(await editor.setLocked('decor', 'tree', true), isFalse);
    expect(await editor.showAll(), isFalse);
    expect(await editor.unlockAll(), isFalse);
    expect(await editor.undo(), isFalse);
    expect(await editor.redo(), isFalse);
    expect(await editor.save(), isFalse);
    expect(editor.current, same(before));
    expect(editor.dirty, isFalse);
    expect(port.editorWrites, 0);
  });

  test(
    'visibility persists separately and supports undo and reopening',
    () async {
      final port = _Port();
      final workspace = MapWorkspaceController(workspaceSession, port);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      final editor = document.editor!;
      final map = document.current;

      expect(await editor.setHidden('model', 'mist', true), isTrue);
      expect(editor.current.isHidden('model', 'mist'), isTrue);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      expect(port.writes, 0);
      expect(port.reads, 1);
      expect(port.catalogs, 1);

      final reopened = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(reopened.dispose);
      expect(reopened.current.isHidden('model', 'mist'), isTrue);
      expect(await editor.undo(), isTrue);
      expect(editor.current.isHidden('model', 'mist'), isFalse);
      expect(await editor.redo(), isTrue);
      expect(editor.current.isHidden('model', 'mist'), isTrue);
    },
  );

  test('show all and unlock all preserve the other editor settings', () async {
    final port = _Port();
    final editor = await MapEditorController.open(workspaceSession, 'a', port);
    addTearDown(editor.dispose);
    await editor.setLocked('model', 'mist', true);
    await editor.setGroupHidden([('model', 'mist'), ('layer', 'path')], true);

    expect(await editor.showAll(), isTrue);
    expect(editor.current.isLocked('model', 'mist'), isTrue);
    expect(editor.current.hiddenElements, isEmpty);
    await editor.setHidden('layer', 'path', true);
    expect(await editor.unlockAll(), isTrue);
    expect(editor.current.lockedElements, isEmpty);
    expect(editor.current.isHidden('layer', 'path'), isTrue);
    await editor.undo();
    expect(editor.current.isLocked('model', 'mist'), isTrue);
    expect(editor.current.isHidden('layer', 'path'), isTrue);
  });

  test(
    'mixed in-flight lock and visibility changes persist the latest state',
    () async {
      final port = _Port()..pending = Completer<void>();
      final editor = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(editor.dispose);
      final first = editor.setHidden('decor', 'mist', true);
      await Future<void>.delayed(Duration.zero);
      final second = editor.setLocked('entity', 'npc', true);
      final third = editor.setHidden('decor', 'mist', false);
      port.pending!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(await third, isTrue);
      expect(port.state.isHidden('decor', 'mist'), isFalse);
      expect(port.state.isLocked('entity', 'npc'), isTrue);
      expect(port.editorWrites, 2);
      expect(port.editorLoads, 1);
      expect(editor.dirty, isFalse);
    },
  );

  test(
    'visibility failure retains a retryable draft and explicit family hiding',
    () async {
      final port = _Port()
        ..state = MapEditorState(
          lockedElements: {'model:mist'},
          hiddenFamilies: {'decor'},
        )
        ..failEditorSave = true;
      final editor = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(editor.dispose);
      expect(() => editor.setHidden('decor', 'a', false), throwsStateError);
      expect(await editor.setHidden('layer', 'border', true), isFalse);
      expect(editor.current.isHidden('layer', 'border'), isTrue);
      expect(port.state.isHidden('layer', 'border'), isFalse);
      expect(editor.dirty, isTrue);
      port.failEditorSave = false;
      expect(await editor.save(), isTrue);
      expect(await editor.showAll(), isTrue);
      expect(editor.current.hiddenElements, isEmpty);
      expect(editor.current.hiddenFamilies, isEmpty);
      expect(editor.current.isLocked('model', 'mist'), isTrue);
    },
  );

  test(
    'locks persist independently of map data and survive reopening',
    () async {
      final port = _Port();
      final workspace = MapWorkspaceController(workspaceSession, port);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      final editor = document.editor!;
      final map = document.current;
      expect(await editor.setLocked('decor', 'mist', true), isTrue);
      expect(document.editorState.isLocked('decor', 'mist'), isTrue);
      expect(document.current, same(map));
      expect(document.dirty, isFalse);
      expect(port.writes, 0);
      expect(port.reads, 1);
      expect(port.catalogs, 1);
      final reopened = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(reopened.dispose);
      expect(reopened.current.isLocked('decor', 'mist'), isTrue);
      expect(await editor.undo(), isTrue);
      expect(editor.current.isLocked('decor', 'mist'), isFalse);
      expect(await editor.redo(), isTrue);
      expect(editor.current.isLocked('decor', 'mist'), isTrue);
    },
  );

  test(
    'rapid edits persist the latest draft without losing an in-flight edit',
    () async {
      final port = _Port()..pending = Completer<void>();
      final editor = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(editor.dispose);
      final first = editor.setLocked('decor', 'mist', true);
      expect(editor.current.isLocked('decor', 'mist'), isTrue);
      expect(editor.saving, isTrue);
      final second = editor.setLocked('model', 'glow', true);
      expect(editor.current.isLocked('model', 'glow'), isTrue);
      port.pending!.complete();
      expect(await first, isTrue);
      expect(await second, isTrue);
      expect(editor.dirty, isFalse);
      expect(port.state.isLocked('decor', 'mist'), isTrue);
      expect(port.state.isLocked('model', 'glow'), isTrue);
      expect(port.editorLoads, 1);
    },
  );

  test(
    'failed persistence keeps an honest dirty draft that can be retried',
    () async {
      final port = _Port()..failEditorSave = true;
      final editor = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(editor.dispose);
      expect(await editor.setLocked('decor', 'mist', true), isFalse);
      expect(editor.current.isLocked('decor', 'mist'), isTrue);
      expect(port.state.isLocked('decor', 'mist'), isFalse);
      expect(editor.dirty, isTrue);
      expect(editor.error, contains('conflit'));
      port.failEditorSave = false;
      expect(await editor.save(), isTrue);
      expect(editor.dirty, isFalse);
    },
  );

  test(
    'group locks preserve other families and one batch is one undo',
    () async {
      final port = _Port();
      final editor = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(editor.dispose);
      await editor.setLocked('entity', 'npc', true);
      await editor.setGroupLocked([('decor', 'a'), ('model', 'b')], true);
      expect(editor.current.isLocked('decor', 'a'), isTrue);
      expect(editor.current.isLocked('model', 'b'), isTrue);
      expect(editor.current.isLocked('entity', 'npc'), isTrue);
      await editor.undo();
      expect(editor.current.isLocked('decor', 'a'), isFalse);
      expect(editor.current.isLocked('model', 'b'), isFalse);
      expect(editor.current.isLocked('entity', 'npc'), isTrue);
      expect(port.editorLoads, 1);
    },
  );
}

class _Port extends WorkspaceMemoryPort implements MapEditorPort {
  MapEditorState state = MapEditorState();
  int editorLoads = 0;
  int editorWrites = 0;
  bool failEditorSave = false;
  Completer<void>? pending;

  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async {
    editorLoads++;
    return MapEditorWorkspaceState(state: state, revision: 'e$editorWrites');
  }

  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState next,
    String expectedRevision,
  ) async {
    await pending?.future;
    if (failEditorSave) throw StateError('conflit');
    expect(expectedRevision, 'e$editorWrites');
    state = next;
    return MapEditorWorkspaceState(
      state: state,
      revision: 'e${++editorWrites}',
    );
  }
}
