import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/editable_map_document.dart';
import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  test('Studio Cut commands survive real map save, cold reopen, explicit clear and undo', () async {
    final temporary = await Directory.systemTemp.createTemp(
      'studio-cut-editing-',
    );
    final root = Directory(await temporary.resolveSymbolicLinks());
    addTearDown(() => root.delete(recursive: true));
    final project = workspaceProject.copyWith(
      maps: [workspaceEntries.first],
      elementCategories: const [
        ProjectElementCategory(id: 'decor', name: 'Décors'),
      ],
    );
    final original = workspaceMap('a').copyWith(
      entities: const [
        MapEntity(
          id: 'cut-tree',
          kind: MapEntityKind.custom,
          pos: GridPos(x: 2, y: 2),
          editorVisual: MapEntityEditorVisual(elementId: 'tree'),
          properties: {'preserved': 'yes'},
        ),
      ],
    );
    final projectFile = File('${root.path}/project.json');
    await projectFile.writeAsString(jsonEncode(project.toJson()));
    final beforeProject = await projectFile.readAsBytes();
    await File('${root.path}/a.json')
        .writeAsString(jsonEncode(original.toJson()));
    final session = ProjectSession(
      sessionId: root.path,
      name: 'Cut',
      directoryPath: root.path,
    );
    final adapter = LocalMapWorkspaceAdapter();
    final loadedProject = await adapter.loadProject(session);
    final base = await adapter.loadMap(session, loadedProject.maps.single);
    final document = EditableMapDocument(base);
    final commands = MapEntityEditingCommands(document, loadedProject);
    commands.setFieldObstacle('cut-tree', const MapEntityFieldObstacleData());
    expect(document.dirty, isTrue);
    final set = document.current;
    document.restore(redo: false);
    expect(document.current, original);
    document.restore(redo: true);
    expect(document.current, set);
    final revision = await adapter.saveMap(session, base, document.current);
    document.acceptSave(document.current, revision);
    expect(document.dirty, isFalse);
    final reopenedAdapter = LocalMapWorkspaceAdapter();
    final reopenedProject = await reopenedAdapter.loadProject(session);
    final reopened = await reopenedAdapter.loadMap(
      session,
      reopenedProject.maps.single,
    );
    expect(reopened.map, set);
    expect(
      reopened.map.entities.single.fieldObstacle,
      const MapEntityFieldObstacleData(),
    );
    final secondDocument = EditableMapDocument(reopened);
    MapEntityEditingCommands(
      secondDocument,
      reopenedProject,
    ).setFieldObstacle('cut-tree', null);
    expect(secondDocument.current, original);
    await reopenedAdapter.saveMap(session, reopened, secondDocument.current);
    final cold = LocalMapWorkspaceAdapter();
    final coldProject = await cold.loadProject(session);
    expect(
      (await cold.loadMap(session, coldProject.maps.single)).map,
      original,
    );
    expect(await projectFile.readAsBytes(), beforeProject);
  });
}
