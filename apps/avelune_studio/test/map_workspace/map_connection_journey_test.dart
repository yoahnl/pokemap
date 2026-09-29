import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
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
      final original = controller.active!.current;
      final connection = LocalMapConnectionAdapter(adapter);
      await connection.link(
        session: session,
        source: original,
        direction: MapConnectionDirection.east,
        targetMapId: 'clairiere',
        offset: 0,
      );
      await controller.refreshSavedMaps({'jardin', 'clairiere'});
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

      await expectLater(
        LocalMapConnectionAdapter(adapter).link(
          session: session,
          source: source,
          direction: MapConnectionDirection.east,
          targetMapId: 'clairiere',
          offset: 0,
        ),
        throwsA(isA<Object>()),
      );
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
}
