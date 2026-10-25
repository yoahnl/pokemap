import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
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
