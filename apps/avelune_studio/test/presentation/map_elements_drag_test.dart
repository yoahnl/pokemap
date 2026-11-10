import 'dart:async';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_editor_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_catalog.dart';
import 'package:avelune_studio/features/map_workspace/application/map_element_list_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  late EditableMapDocument document;
  late _Port port;
  late MapElementReorderSession session;
  late List<MapElementListEntry> entries;
  late List<(String, List<String>, String?)> reorders;

  setUp(() async {
    document = EditableMapDocument(
      MapWorkspaceDocument(
        map: workspaceMap('a').copyWith(
          placedElements: const [
            MapPlacedElement(
              id: 'tree',
              layerId: 'ground',
              elementId: 'tree',
              pos: GridPos(x: 4, y: 4),
            ),
            MapPlacedElement(
              id: 'mist',
              layerId: 'ground',
              elementId: 'mist',
              pos: GridPos(x: 4, y: 4),
              visualOrder: 10,
            ),
          ],
        ),
        revision: 'base',
        mapId: 'a',
      ),
    );
    port = _Port(MapEditorState());
    document.editor = await MapEditorController.open(
      workspaceSession,
      'a',
      port,
    );
    addTearDown(document.editor!.dispose);
    entries = MapElementCatalog(document.current, workspaceProject)
        .stacking
        .values
        .singleWhere(
          (entries) => entries.any((entry) => entry.kind == 'decor'),
        );
    reorders = [];
    session = MapElementReorderSession();
  });

  Future<bool> apply(String kind, List<String> ids, String? layer) async {
    reorders.add((kind, ids, layer));
    return true;
  }

  test('moving lower content upward sends front-first IDs once and blocks concurrent reorder', () async {
    final completion = Completer<bool>();
    final pending = session.reorder(
      document: document,
      entries: entries,
      from: 1,
      to: 0,
      apply: (kind, ids, layer) async {
        reorders.add((kind, ids, layer));
        return completion.future;
      },
    );
    expect(reorders, hasLength(1));
    expect(reorders.single.$1, 'decor');
    expect(reorders.single.$2, ['tree', 'mist']);
    expect(reorders.single.$3, 'ground');
    expect(session.busy, isTrue);
    expect(document.dirty, isFalse);
    expect(
      await session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 0,
        apply: apply,
      ),
      isFalse,
    );
    completion.complete(true);
    expect(await pending, isTrue);
    expect(session.busy, isFalse);
    expect(reorders, hasLength(1));
  });

  test(
    'moving front content down applies the resolved destination once',
    () async {
      expect(
        await session.reorder(
          document: document,
          entries: entries,
          from: 0,
          to: 1,
          apply: apply,
        ),
        isTrue,
      );
      expect(reorders, hasLength(1));
      expect(reorders.single.$1, 'decor');
      expect(reorders.single.$2, ['tree', 'mist']);
      expect(reorders.single.$3, 'ground');
      expect(session.busy, isFalse);
    },
  );

  test('locked, filtered and searched content cannot reorder', () async {
    await document.editor!.setLocked('decor', 'tree', true);
    expect(
      await session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 0,
        apply: apply,
      ),
      isFalse,
    );
    await document.editor!.unlockAll();
    expect(
      await session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 0,
        filter: MapContentFilter.hidden,
        apply: apply,
      ),
      isFalse,
    );
    expect(
      await session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 0,
        query: 'mist',
        apply: apply,
      ),
      isFalse,
    );
    expect(
      await session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 1,
        apply: apply,
      ),
      isFalse,
    );
    expect(reorders, isEmpty);
  });

  test(
    'inherited layer locks block selection and unlock all survives reopening',
    () async {
      await document.editor!.setLocked('layer', 'ground', true);
      final view = MapWorkspaceEditingState();
      final selection = MapElementSelectionCommands(document, view);
      expect(selection.select(entries.first), isFalse);
      final before = document.current;
      final writes = port.writes;
      await document.editor!.unlockAll();
      expect(port.writes, writes + 1);
      expect(document.current, same(before));
      final reopened = await MapEditorController.open(
        workspaceSession,
        'a',
        port,
      );
      addTearDown(reopened.dispose);
      expect(reopened.current.lockedElements, isEmpty);
      expect(selection.select(entries.first), isTrue);
      expect(document.selectedId, 'mist');
    },
  );

  test('failed reorder releases the single-flight guard', () async {
    await expectLater(
      session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 0,
        apply: (_, _, _) async => throw StateError('refused'),
      ),
      throwsStateError,
    );
    expect(session.busy, isFalse);
    expect(
      await session.reorder(
        document: document,
        entries: entries,
        from: 1,
        to: 0,
        apply: apply,
      ),
      isTrue,
    );
  });
}

final class _Port implements MapEditorPort {
  _Port(this.state);
  MapEditorState state;
  var writes = 0;
  @override
  Future<MapEditorWorkspaceState> loadEditorState(
    ProjectSession session,
    String mapId,
  ) async => MapEditorWorkspaceState(state: state, revision: 'e$writes');
  @override
  Future<MapEditorWorkspaceState> saveEditorState(
    ProjectSession session,
    String mapId,
    MapEditorState next,
    String expectedRevision,
  ) async {
    writes++;
    state = next;
    return MapEditorWorkspaceState(state: state, revision: 'e$writes');
  }
}
