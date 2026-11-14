import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';
import 'map_element_order_controller_support.dart';

void main() {
  test(
    'ordinary edits after undo do not reuse a stale stacking receipt',
    () async {
      final root = await Directory.systemTemp.createTemp(
        'studio-order-branch-',
      );
      addTearDown(() => root.delete(recursive: true));
      final project = workspaceProject.copyWith(maps: [workspaceEntries.first]);
      final map = workspaceMap('a').copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'tree',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
          MapPlacedElement(
            id: 'mist',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
            visualOrder: 10,
          ),
        ],
      );
      await File('${root.path}/project.json')
          .writeAsString(jsonEncode(project.toJson()));
      await File('${root.path}/a.json').writeAsString(jsonEncode(map.toJson()));
      final session = ProjectSession(
        sessionId: 'order-branch',
        name: 'Order branch',
        directoryPath: await root.resolveSymbolicLinks(),
      );
      final workspace = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      expect(
        await workspace.reorderElements('decor', ['tree', 'mist'], 'ground'),
        isTrue,
      );
      expect(document.undoToken, isNotNull);
      workspace.restore(redo: false);
      await waitForOrder(workspace);
      expect(document.error, isNull);
      expect(document.undoToken, isNull);
      final original = document.current;
      final branched = original.copyWith(
        placedElements: [
          for (final item in original.placedElements)
            if (item.id == 'tree')
              item.copyWith(pos: const GridPos(x: 0, y: 0))
            else
              item,
        ],
      );
      document.commit(branched);
      expect(document.undoToken, isNotNull);
      expect(await workspace.save(document), isTrue);
      workspace.restore(redo: false);
      await waitForOrder(workspace);
      expect(document.error, isNull);
      expect(document.current, original);
      expect(document.dirty, isTrue);
      expect(await workspace.save(document), isTrue);
      workspace.restore(redo: true);
      await waitForOrder(workspace);
      expect(document.error, isNull);
      expect(document.current, branched);
      expect(document.dirty, isTrue);
    },
  );

  test('stacking undo after ordinary saves restores a dirty draft and survives reopening', () async {
    final root = await Directory.systemTemp.createTemp('studio-order-mixed-');
    addTearDown(() => root.delete(recursive: true));
    final project = workspaceProject.copyWith(maps: [workspaceEntries.first]);
    final map = workspaceMap('a').copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'tree',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 1, y: 1),
        ),
        MapPlacedElement(
          id: 'mist',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 1, y: 1),
          visualOrder: 10,
        ),
      ],
    );
    final projectFile = File('${root.path}/project.json');
    await projectFile.writeAsString(jsonEncode(project.toJson()));
    final projectBytes = await projectFile.readAsBytes();
    final mapFile = File('${root.path}/a.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final session = ProjectSession(
      sessionId: 'order-mixed',
      name: 'Order mixed',
      directoryPath: await root.resolveSymbolicLinks(),
    );
    final workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    expect(
      await workspace.reorderElements('decor', ['tree', 'mist'], 'ground'),
      isTrue,
    );
    final reordered = document.current;
    final reorderedRevision = document.base.revision;
    document.commit(
      reordered.copyWith(
        placedElements: [
          for (final item in reordered.placedElements)
            if (item.id == 'tree')
              item.copyWith(pos: const GridPos(x: 0, y: 0))
            else
              item,
        ],
      ),
    );
    expect(await workspace.save(document), isTrue);
    workspace.restore(redo: false);
    await waitForOrder(workspace);
    expect(document.current, reordered);
    expect(document.error, isNull);
    expect(document.dirty, isTrue);
    expect(await workspace.save(document), isTrue);
    expect(document.base.revision, isNot(reorderedRevision));
    final beforeFinalUndo = await mapFile.readAsBytes();
    workspace.restore(redo: false);
    await waitForOrder(workspace);
    expect(document.error, isNull);
    expect(document.current, map);
    expect(document.dirty, isTrue);
    expect(await mapFile.readAsBytes(), beforeFinalUndo);
    expect(await workspace.save(document), isTrue);
    expect(document.dirty, isFalse);
    expect(
      MapData.fromJson(
        jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
      ),
      map,
    );
    final reopened = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(reopened.dispose);
    await reopened.initialize();
    expect(reopened.error, isNull);
    expect(reopened.active!.current, map);
    expect(await projectFile.readAsBytes(), projectBytes);
  });
}
