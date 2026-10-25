import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_editor_port.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test(
    'portable sessions cannot preview or publish a stacking mutation',
    () async {
      final port = _OrderPort();
      const session = ProjectSession(
        sessionId: 'portable',
        name: 'Lecture seule',
        directoryPath: '/fixture',
        storage: ProjectSessionStorage.portableCatalog,
      );
      final workspace = MapWorkspaceController(session, port);
      addTearDown(workspace.dispose);
      await workspace.initialize();
      final document = workspace.active!;
      final before = document.current;
      expect(workspace.canReorderElements, isFalse);
      expect(
        await workspace.reorderElements('layers', ['back', 'ground'], null),
        isFalse,
      );
      expect(document.current, same(before));
      expect(document.dirty, isFalse);
      expect(document.canUndo, isFalse);
      expect(port.calls, 0);
    },
  );

  test('targeted native reorder persists front-first and undo/redo without saving the project', () async {
    final root = await Directory.systemTemp.createTemp('studio-order-');
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
    final mapFile = File('${root.path}/a.json');
    await mapFile.writeAsString(jsonEncode(map.toJson()));
    final projectBytes = await projectFile.readAsBytes();
    final session = ProjectSession(
      sessionId: 'order',
      name: 'Order',
      directoryPath: await root.resolveSymbolicLinks(),
    );
    final workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(workspace.dispose);
    await workspace.initialize();
    expect(workspace.error, isNull);
    expect(workspace.active, isNotNull);
    expect(
      await workspace.reorderElements('decor', ['tree', 'mist'], 'ground'),
      isTrue,
    );
    expect(workspace.active!.dirty, isFalse);
    expect(_ids(workspace.active!.current), ['tree', 'mist']);
    expect(
      _ids(
        MapData.fromJson(
          jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
        ),
      ),
      ['tree', 'mist'],
    );
    workspace.restore(redo: false);
    await _wait(workspace);
    expect(workspace.active!.error, isNull);
    expect(workspace.active!.dirty, isFalse);
    expect(_ids(workspace.active!.current), ['mist', 'tree']);
    workspace.restore(redo: true);
    await _wait(workspace);
    expect(workspace.active!.dirty, isFalse);
    expect(_ids(workspace.active!.current), ['tree', 'mist']);
    expect(await projectFile.readAsBytes(), projectBytes);
    final reopened = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(reopened.dispose);
    await reopened.initialize();
    expect(_ids(reopened.active!.current), ['tree', 'mist']);
  });

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
      await _wait(workspace);
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
      await _wait(workspace);
      expect(document.error, isNull);
      expect(document.current, original);
      expect(document.dirty, isTrue);
      expect(await workspace.save(document), isTrue);
      workspace.restore(redo: true);
      await _wait(workspace);
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
    await _wait(workspace);
    expect(document.current, reordered);
    expect(document.error, isNull);
    expect(document.dirty, isTrue);
    expect(await workspace.save(document), isTrue);
    expect(document.base.revision, isNot(reorderedRevision));
    final beforeFinalUndo = await mapFile.readAsBytes();
    workspace.restore(redo: false);
    await _wait(workspace);
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

  test('order preview is immediate and a failed publication rolls back only its edit', () async {
    final port = _OrderPort();
    final workspace = MapWorkspaceController(workspaceSession, port);
    addTearDown(workspace.dispose);
    await workspace.initialize();
    final document = workspace.active!;
    final before = document.current;
    final pending = workspace.reorderElements('layers', [
      'back',
      'ground',
    ], null);
    expect(document.current.layers.first.id, 'back');
    expect(document.saving, isTrue);
    port.gate.completeError(
      const MapWorkspaceFailure(MapWorkspaceProblem.conflict, 'conflit'),
    );
    expect(await pending, isFalse);
    expect(document.current, same(before));
    expect(document.dirty, isFalse);
    expect(document.canUndo, isFalse);
    expect(document.error, contains('conflit'));
    expect(port.writes, 0);
  });
}

List<String> _ids(MapData map) =>
    sortMapPlacedElementsForPainting(map.placedElements).reversed
        .map((item) => item.id)
        .toList();

Future<void> _wait(MapWorkspaceController workspace) async {
  final deadline = DateTime.now().add(const Duration(seconds: 10));
  while (workspace.active!.saving && DateTime.now().isBefore(deadline)) {
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  expect(workspace.active!.saving, isFalse);
}

class _OrderPort extends WorkspaceMemoryPort implements MapElementOrderPort {
  final gate = Completer<MapElementOrderWorkspaceReceipt>();
  int calls = 0;
  @override
  Future<MapWorkspaceDocument> loadMap(
    ProjectSession session,
    ProjectMapEntry entry,
  ) async {
    final source = await super.loadMap(session, entry);
    return MapWorkspaceDocument(
      map: source.map.copyWith(
        layers: [
          ...source.map.layers,
          const MapLayer.tile(id: 'back', name: 'Fond'),
        ],
      ),
      revision: source.revision,
      mapId: source.mapId,
    );
  }

  @override
  Future<MapElementOrderWorkspaceReceipt> reorderMapElements(
    ProjectSession session,
    MapWorkspaceDocument base,
    String kind,
    List<String> frontFirstIds,
    String? layerId,
  ) {
    calls++;
    return gate.future;
  }

  @override
  Future<MapElementOrderWorkspaceReceipt> undoMapElementOrder(
    ProjectSession session,
    MapWorkspaceDocument base,
    MapElementOrderWorkspaceReceipt receipt,
  ) => gate.future;
}
