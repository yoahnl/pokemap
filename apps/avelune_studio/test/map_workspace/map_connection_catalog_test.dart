import 'dart:convert';
import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

const _foreign = 40;

ProjectManifest _project() => ProjectManifest(
  name: 'Liaisons',
  maps: [
    const ProjectMapEntry(id: 'a', name: 'A', relativePath: 'maps/a.json'),
    const ProjectMapEntry(id: 'b', name: 'B', relativePath: 'maps/b.json'),
    for (var i = 0; i < _foreign; i++)
      ProjectMapEntry(
        id: 'foreign-$i',
        name: 'Foreign',
        relativePath: 'maps/foreign-$i.json',
      ),
  ],
  tilesets: const [],
);

Future<ProjectSession> _catalogProject() async {
  final temporary = await Directory.systemTemp.createTemp(
    'avelune_connection_catalog_',
  );
  final root = Directory(await temporary.resolveSymbolicLinks());
  addTearDown(() => root.delete(recursive: true));
  final store = await CatalogStorageStore.open(projectRoot: root.path);
  await WorkingProjectCatalog.create(
    store: store,
    projectId: 'liaisons',
    project: _project(),
  );
  await Directory('${root.path}/maps').create(recursive: true);
  for (final id in ['a', 'b']) {
    await File('${root.path}/maps/$id.json').writeAsString(
      jsonEncode(
        MapData(
          id: id,
          name: id.toUpperCase(),
          size: const GridSize(width: 12, height: 10),
        ).toJson(),
      ),
    );
  }
  return ProjectSession(
    sessionId: root.path,
    name: 'Liaisons',
    directoryPath: root.path,
    storage: ProjectSessionStorage.workingCatalog,
  );
}

Future<List<MapConnection>> _saved(ProjectSession session, String id) async {
  final file = File('${session.directoryPath}/maps/$id.json');
  final map = MapData.fromJson(
    Map<String, dynamic>.from(jsonDecode(await file.readAsString()) as Map),
  );
  return map.connections;
}

void main() {
  test('catalog links read only their two maps to create, update and remove a pair', () async {
    final session = await _catalogProject();
    final adapter = LocalMapWorkspaceAdapter();
    final controller = MapWorkspaceController(session, adapter);
    addTearDown(controller.dispose);
    await controller.initialize();
    expect(controller.error, isNull);
    expect(controller.active?.base.mapId, 'a');
    final actions = MapWorkspaceConnectionActions(
      controller: controller,
      port: LocalMapConnectionAdapter(adapter),
      isActive: () => true,
      changed: () {},
    );

    await actions.link(MapConnectionDirection.east, 'b', 0);
    expect(actions.error, isNull);
    await actions.link(MapConnectionDirection.east, 'b', 2);

    expect(actions.error, isNull);
    expect(await _saved(session, 'a'), [
      const MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'b',
        offset: 2,
      ),
    ]);
    expect(await _saved(session, 'b'), [
      const MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'a',
        offset: -2,
      ),
    ]);
    expect(controller.active!.current.connections.single.offset, 2);
    expect(controller.active!.dirty, isFalse);

    await actions.unlink(MapConnectionDirection.east);
    expect(actions.error, isNull);
    expect(await _saved(session, 'a'), isEmpty);
    expect(await _saved(session, 'b'), isEmpty);
    expect(controller.active!.current.connections, isEmpty);
  });
}
