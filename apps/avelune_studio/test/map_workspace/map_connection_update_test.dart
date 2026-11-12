import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../../tool/create_example_project.dart' show writeExampleProject;

void main() {
  late Directory directory;
  late ProjectSession session;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp(
      'avelune_connection_update_',
    );
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Liaisons',
      directoryPath: directory.path,
    );
  });

  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Future<MapData> saved(String mapId) async {
    final controller = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(
      controller.project!.maps.firstWhere((entry) => entry.id == mapId),
    );
    return controller.active!.current;
  }

  test('linking an already paired border updates both offsets', () async {
    final adapter = LocalMapWorkspaceAdapter();
    final controller = MapWorkspaceController(session, adapter);
    addTearDown(controller.dispose);
    await controller.initialize();
    await controller.activate(
      controller.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
    );
    final actions = MapWorkspaceConnectionActions(
      controller: controller,
      port: LocalMapConnectionAdapter(adapter),
      isActive: () => true,
      changed: () {},
    );

    await actions.link(MapConnectionDirection.east, 'clairiere', 0);
    expect(actions.error, isNull);
    await actions.link(MapConnectionDirection.east, 'clairiere', 2);

    expect(actions.error, isNull);
    final garden = await saved('jardin');
    final clearing = await saved('clairiere');
    expect(garden.connections, [
      const MapConnection(
        direction: MapConnectionDirection.east,
        targetMapId: 'clairiere',
        offset: 2,
      ),
    ]);
    expect(clearing.connections, [
      const MapConnection(
        direction: MapConnectionDirection.west,
        targetMapId: 'jardin',
        offset: -2,
      ),
    ]);
  });
}
