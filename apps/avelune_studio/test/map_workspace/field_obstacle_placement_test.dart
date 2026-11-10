import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';

import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/map_workspace/application/map_character_gesture.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  for (final (kind, label) in [
    (FieldObstacleKind.cutTree, 'Placer un arbre à couper'),
    (FieldObstacleKind.strengthBoulder, 'Placer un rocher à pousser'),
    (FieldObstacleKind.rockSmashRock, 'Placer un rocher à briser'),
    (FieldObstacleKind.iceBlock, 'Placer un bloc de glace'),
  ]) {
    testWidgets('$label creates one undoable native object and cold reopens', (
      tester,
    ) async {
      final project = workspaceProject.copyWith(
        maps: [workspaceEntries.first],
        elementCategories: const [
          ProjectElementCategory(id: 'decor', name: 'Décors'),
        ],
      );
      final source = workspaceMap('a');
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: source, mapId: 'a', revision: 'initial'),
      );
      final view = MapWorkspaceEditingState()..brush = workspaceElement;
      view.prepareFieldObstaclePlacement(kind);
      expect(view.tool.name, 'fieldObstacle');
      expect(
        MapCharacterGesture.start(
          document: document,
          project: project,
          view: view,
          origin: const GridPos(x: 3, y: 4),
        ),
        isNotNull,
      );
      final placed = document.current.entities.single;
      expect(placed.kind, MapEntityKind.custom);
      expect(placed.pos, const GridPos(x: 3, y: 4));
      expect(placed.size, const GridSize(width: 1, height: 1));
      expect(placed.editorVisual?.elementId, workspaceElement.id);
      expect(placed.blocksMovement, isTrue);
      expect(placed.fieldObstacle, MapEntityFieldObstacleData(kind: kind));
      expect(document.current.placedElements, isEmpty);
      expect(view.target?.id, placed.id);
      final changed = document.current;
      document.restore(redo: false);
      expect(document.current, source);
      expect(document.canUndo, isFalse);
      document.restore(redo: true);
      expect(document.current, changed);
      await tester.runAsync(() async {
        final parent = Directory(
          '/Users/karim/Library/Caches/AveluneQA/studio-t01-retirement-20261109/t01-map-retirement',
        );
        await parent.create(recursive: true);
        final temporary = await parent.createTemp(
          'studio-native-obstacle-placement-',
        );
        final root = Directory(await temporary.resolveSymbolicLinks());
        try {
          await File('${root.path}/project.json')
              .writeAsString(jsonEncode(project.toJson()));
          await File('${root.path}/a.json')
              .writeAsString(jsonEncode(source.toJson()));
          final session = ProjectSession(
            sessionId: root.path,
            name: 'Obstacles natifs',
            directoryPath: root.path,
          );
          final adapter = LocalMapWorkspaceAdapter();
          final openedProject = await adapter.loadProject(session);
          final base = await adapter.loadMap(
            session,
            openedProject.maps.single,
          );
          await adapter.saveMap(session, base, changed);
          final cold = LocalMapWorkspaceAdapter();
          final reloadedProject = await cold.loadProject(session);
          final reopened = await cold.loadMap(
            session,
            reloadedProject.maps.single,
          );
          expect(reopened.map, changed);
          expect(reopened.map.entities.single.fieldObstacle?.kind, kind);
        } finally {
          await root.delete(recursive: true);
        }
      });
      expect(tester.takeException(), isNull);
    });
  }

  test('a Force obstacle requires its visual before native placement', () {
    final view = MapWorkspaceEditingState();
    final source = workspaceMap('a');
    final document = EditableMapDocument(
      MapWorkspaceDocument(map: source, mapId: 'a', revision: 'initial'),
    );
    view.prepareFieldObstaclePlacement(FieldObstacleKind.strengthBoulder);
    expect(view.fieldObstacleKind, FieldObstacleKind.strengthBoulder);
    expect(view.brush, isNull);
    MapCharacterGesture.start(
      document: document,
      project: workspaceProject,
      view: view,
      origin: const GridPos(x: 3, y: 4),
    );
    expect(document.current, source);
    expect(document.canUndo, isFalse);
    expect(document.error, contains('Choisissez le visuel'));
    view.brush = workspaceElement;
    expect(view.tool, StudioMapTool.fieldObstacle);
    MapCharacterGesture.start(
      document: document,
      project: workspaceProject,
      view: view,
      origin: const GridPos(x: 3, y: 4),
    );
    expect(
      document.current.entities.single.fieldObstacle!.kind,
      FieldObstacleKind.strengthBoulder,
    );
    expect(document.current.entities.single.editorVisual!.elementId, 'tree');
    expect(document.error, isNull);
  });
}
