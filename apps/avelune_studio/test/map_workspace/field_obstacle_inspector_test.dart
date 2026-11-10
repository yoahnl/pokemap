import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/domain/map_workspace_port.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

const _tree = MapEntity(
  id: 'cut-tree',
  name: 'Arbre',
  kind: MapEntityKind.custom,
  pos: GridPos(x: 2, y: 2),
  editorVisual: MapEntityEditorVisual(elementId: 'tree'),
  properties: {'source': 'preserved'},
);
void main() {
  for (final kind in FieldObstacleKind.values) {
    test('custom object toggles ${kind.name} with undo and redo', () {
      final original = workspaceMap('a').copyWith(entities: [_tree]);
      final document = EditableMapDocument(
        MapWorkspaceDocument(map: original, revision: 'base', mapId: 'a'),
      );
      final commands = MapEntityEditingCommands(document, workspaceProject);
      expect(commands.canConfigureFieldObstacle(_tree), isTrue);
      commands.setFieldObstacle(
        _tree.id,
        MapEntityFieldObstacleData(kind: kind),
      );
      expect(
        document.current.entities.single.fieldObstacle,
        MapEntityFieldObstacleData(kind: kind),
      );
      expect(
        document.current.entities.single.fieldObstacle!.resetPolicy,
        FieldObstacleResetPolicy.mapInstance,
      );
      expect(
        document.current.entities.single.copyWith(fieldObstacle: null),
        _tree,
      );
      document.restore(redo: false);
      expect(document.current, original);
      document.restore(redo: true);
      expect(document.current.entities.single.fieldObstacle!.kind, kind);
      commands.setFieldObstacle(_tree.id, null);
      expect(document.current, original);
    });
  }
  for (final mode in [
    'wide',
    'nonblocking',
    'missingVisual',
    'unknownVisual',
    'spatial',
  ]) {
    test(
      'obstacle eligibility refuses $mode objects without changing them',
      () {
        var entity = _tree;
        var map = workspaceMap('a');
        if (mode == 'wide') {
          entity = entity.copyWith(size: const GridSize(width: 2, height: 1));
        }
        if (mode == 'nonblocking') {
          entity = entity.copyWith(blocksMovement: false);
        }
        if (mode == 'missingVisual') {
          entity = entity.copyWith(editorVisual: null);
        }
        if (mode == 'unknownVisual') {
          entity = entity.copyWith(
            editorVisual: const MapEntityEditorVisual(elementId: 'missing'),
          );
        }
        if (mode == 'spatial') {
          map = map.copyWith(
            version: ProjectVersion.v9,
            spatialScene: MapSpatialScene(
              width: map.size.width,
              depth: map.size.height,
            ),
          );
        }
        map = map.copyWith(entities: [entity]);
        final document = EditableMapDocument(
          MapWorkspaceDocument(map: map, revision: 'base', mapId: 'a'),
        );
        final commands = MapEntityEditingCommands(document, workspaceProject);
        expect(commands.canConfigureFieldObstacle(entity), isFalse);
        expect(document.current, same(map));
        expect(document.dirty, isFalse);
      },
    );
  }
}
