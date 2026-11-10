import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_connection_adapter.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart' show writeExampleProject;

void main() {
  late Directory directory;
  late ProjectSession session;
  late LocalMapWorkspaceAdapter adapter;
  late MapWorkspaceController controller;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp(
      'avelune_connection_',
    );
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Liaisons',
      directoryPath: directory.path,
    );
    adapter = LocalMapWorkspaceAdapter();
    controller = MapWorkspaceController(session, adapter);
    await controller.initialize();
    await controller.activate(
      controller.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
    );
  });

  tearDown(() async {
    controller.dispose();
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  test(
    'a paired border link saves both maps and resolves the next cell',
    () async {
      final connection = LocalMapConnectionAdapter(adapter);
      final actions = MapWorkspaceConnectionActions(
        controller: controller,
        port: connection,
        isActive: () => true,
        changed: () {},
      );
      await actions.link(MapConnectionDirection.east, 'clairiere', 0);
      expect(actions.error, isNull);
      expect(actions.busy, isFalse);
      expect(
        controller.active!.current.connections.single.targetMapId,
        'clairiere',
      );
      expect(controller.active!.dirty, isFalse);
      controller.dispose();

      final reopened = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      final garden = reopened.active!.current;
      await reopened.activate(
        reopened.project!.maps.firstWhere((entry) => entry.id == 'clairiere'),
      );
      final clearing = reopened.active!.current;
      expect(garden.connections.single.direction, MapConnectionDirection.east);
      expect(
        clearing.connections.single.direction,
        MapConnectionDirection.west,
      );
      expect(clearing.connections.single.targetMapId, garden.id);
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(directory.path, 'project.json'),
        mapId: garden.id,
      );
      final world = GameplayWorldState.initial(
        map: bundle.map,
        playerPos: GridPos(x: garden.size.width - 1, y: 8),
        project: bundle.manifest,
      );
      final borderResult = stepGameplayWorld(
        world,
        const MoveIntent(Direction.east),
      );
      expect(borderResult, isA<ConnectionTriggered>());
      expect(
        (borderResult as ConnectionTriggered).connection.targetMapId,
        clearing.id,
      );
      expect(
        resolveConnectedMapTargetPos(
          sourcePos: GridPos(x: garden.size.width - 1, y: 8),
          sourceSize: garden.size,
          targetSize: clearing.size,
          direction: MapConnectionDirection.east,
          offset: 0,
        ),
        const GridPos(x: 0, y: 8),
      );

      await connection.unlink(
        session: session,
        source: garden,
        direction: MapConnectionDirection.east,
        expectedTarget: clearing,
      );
      final after = MapWorkspaceController(session, LocalMapWorkspaceAdapter());
      addTearDown(after.dispose);
      await after.initialize();
      expect(after.active!.current.connections, isEmpty);
      await after.activate(
        after.project!.maps.firstWhere((entry) => entry.id == 'clairiere'),
      );
      expect(after.active!.current.connections, isEmpty);
    },
  );

  test(
    'a changed source refuses the link and leaves the target untouched',
    () async {
      final source = controller.active!.current;
      final external = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(external.dispose);
      await external.initialize();
      await external.activate(
        external.project!.maps.firstWhere((entry) => entry.id == 'jardin'),
      );
      external.active!.commit(source.copyWith(name: 'Modifiée ailleurs'));
      expect(await external.save(external.active!), isTrue);

      final actions = MapWorkspaceConnectionActions(
        controller: controller,
        port: LocalMapConnectionAdapter(adapter),
        isActive: () => true,
        changed: () {},
      );
      await actions.link(MapConnectionDirection.east, 'clairiere', 0);
      expect(actions.error, isNotNull);
      expect(actions.busy, isFalse);
      final reopened = MapWorkspaceController(
        session,
        LocalMapWorkspaceAdapter(),
      );
      addTearDown(reopened.dispose);
      await reopened.initialize();
      expect(reopened.active!.current.connections, isEmpty);
      await reopened.activate(
        reopened.project!.maps.firstWhere((entry) => entry.id == 'clairiere'),
      );
      expect(reopened.active!.current.connections, isEmpty);
    },
  );
  test(
    'an unsaved source blocks the transaction and preserves both maps',
    () async {
      final source = controller.active!;
      final saved = source.current;
      source.commit(saved.copyWith(name: 'Brouillon protégé'));
      final actions = MapWorkspaceConnectionActions(
        controller: controller,
        port: LocalMapConnectionAdapter(adapter),
        isActive: () => true,
        changed: () {},
      );

      await actions.link(MapConnectionDirection.east, 'clairiere', 0);

      expect(actions.error, contains('brouillons'));
      expect(source.current.name, 'Brouillon protégé');
      expect(source.dirty, isTrue);
      final persisted = await adapter.loadMap(
        session,
        controller.project!.maps.firstWhere((entry) => entry.id == saved.id),
      );
      final target = await adapter.loadMap(
        session,
        controller.project!.maps.firstWhere((entry) => entry.id == 'clairiere'),
      );
      expect(persisted.map.name, saved.name);
      expect(persisted.map.connections, isEmpty);
      expect(target.map.connections, isEmpty);
    },
  );
}
