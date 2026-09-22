import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart' show writeExampleProject;

const departure = 'jardin';
const arrival = 'clairiere';

/// Walks the world one step at a time until the engine reports the warp, or
/// until the player stops making progress. Nothing is injected on the way.
({GameplayStepResult result, int steps}) walkUntilWarp(
  GameplayWorldState start,
  Direction direction, {
  int limit = 24,
}) {
  var world = start;
  for (var steps = 1; steps <= limit; steps++) {
    final result = stepGameplayWorld(world, MoveIntent(direction));
    if (result is WarpTriggered) return (result: result, steps: steps);
    if (result.world.player.pos == world.player.pos) {
      return (result: result, steps: steps);
    }
    world = result.world;
  }
  return (
    result: stepGameplayWorld(world, MoveIntent(direction)),
    steps: limit,
  );
}

void main() {
  late Directory directory;
  late ProjectSession session;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_asmap_');
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Parcours de passage',
      directoryPath: directory.path,
    );
  });
  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  Future<MapWorkspaceController> openWorkspace() async {
    final workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    await workspace.initialize();
    return workspace;
  }

  test(
    'a warp saved on disk really carries the player to the other map',
    () async {
      final workspace = await openWorkspace();
      final manifest = workspace.project!;
      await workspace.activate(
        manifest.maps.firstWhere((entry) => entry.id == departure),
      );
      final document = workspace.active!;
      final before = document.current;

      final entities = MapEntityEditingCommands(document, manifest);
      final warps = WarpEditingCommands(document, manifest);
      // The fixture map already owns the player start; an author moves it
      // rather than stacking a second one.
      final spawn = entities.playerStart()!;
      entities.move(spawn.id, const GridPos(x: 4, y: 4));
      final warp = warps.place(
        manifest.maps.firstWhere((entry) => entry.id == arrival),
        const GridPos(x: 4, y: 6),
      );
      warps.retarget(warp.id, targetPos: const GridPos(x: 7, y: 3));

      expect(await workspace.save(document), isTrue, reason: workspace.error);
      expect(document.dirty, isFalse);
      workspace.dispose();

      // Everything below reads the files Studio just wrote, with fresh owners.
      final reopened = await openWorkspace();
      addTearDown(reopened.dispose);
      await reopened.activate(
        reopened.project!.maps.firstWhere((entry) => entry.id == departure),
      );
      final restored = reopened.active!.current;
      expect(restored.warps.single.id, warp.id);
      expect(restored.warps.single.targetMapId, arrival);
      expect(restored.warps.single.targetPos, const GridPos(x: 7, y: 3));
      expect(
        restored.placedElements,
        before.placedElements,
        reason: 'the decors of the fixture survive the round trip',
      );
      expect(restored.layers, before.layers);

      final projectFilePath = p.join(directory.path, 'project.json');
      final bundle = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: departure,
      );
      expect(bundle.map.warps.single.targetMapId, arrival);

      final world = GameplayWorldState.fromMap(
        bundle.map,
        project: bundle.manifest,
      );
      expect(
        world.player.pos,
        const GridPos(x: 4, y: 4),
        reason: 'the engine starts on the spawn Studio saved',
      );
      expect(
        reopened.active!.current.entities
            .where((entity) => entity.id == spawn.id)
            .single
            .pos,
        const GridPos(x: 4, y: 4),
        reason: 'the start the author moved is the one saved and reloaded',
      );

      final walk = walkUntilWarp(world, Direction.south);
      expect(
        walk.result,
        isA<WarpTriggered>(),
        reason: 'walking south from the spawn reaches the warp on disk',
      );
      expect(
        walk.steps,
        greaterThan(1),
        reason: 'the player really crossed ground before reaching the warp',
      );
      final triggered = (walk.result as WarpTriggered).warp;
      expect(triggered.warpId, warp.id);
      expect(triggered.targetMapId, arrival);
      expect(triggered.triggerMode, MapWarpTriggerMode.onEnter);

      // The runtime now loads the destination the saved data asked for.
      final destination = await loadRuntimeMapBundle(
        projectFilePath: projectFilePath,
        mapId: triggered.targetMapId,
        preloadedManifest: bundle.manifest,
      );
      expect(
        destination.map.id,
        arrival,
        reason: 'the active map after the handoff is the one the author chose',
      );
      expect(
        triggered.targetPos.x < destination.map.size.width &&
            triggered.targetPos.y < destination.map.size.height,
        isTrue,
        reason: 'the arrival cell exists on the destination map',
      );

      final arrivalWorld = GameplayWorldState.fromMap(
        destination.map,
        project: destination.manifest,
      );
      final arrived = arrivalWorld.withPlayer(
        GameplayPlayerState.fromGridSpawn(
          cell: triggered.targetPos,
          facing: Direction.south,
          tileWidthPx: destination.manifest.settings.tileWidth,
          tileHeightPx: destination.manifest.settings.tileHeight,
          mapWidthCells: destination.map.size.width,
          mapHeightCells: destination.map.size.height,
        ),
      );
      expect(
        arrived.player.pos,
        const GridPos(x: 7, y: 3),
        reason: 'the player really stands on the saved arrival cell',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );

  test(
    'a warp saved as bump does not fire on a plain step',
    () async {
      final workspace = await openWorkspace();
      addTearDown(workspace.dispose);
      final manifest = workspace.project!;
      await workspace.activate(
        manifest.maps.firstWhere((entry) => entry.id == departure),
      );
      final document = workspace.active!;

      final entities = MapEntityEditingCommands(document, manifest);
      entities.move(entities.playerStart()!.id, const GridPos(x: 4, y: 4));
      final warps = WarpEditingCommands(document, manifest);
      final warp = warps.place(
        manifest.maps.firstWhere((entry) => entry.id == arrival),
        const GridPos(x: 4, y: 6),
      );
      warps.retarget(
        warp.id,
        targetPos: const GridPos(x: 7, y: 3),
        triggerMode: MapWarpTriggerMode.onBump,
      );
      expect(await workspace.save(document), isTrue, reason: workspace.error);

      final bundle = await loadRuntimeMapBundle(
        projectFilePath: p.join(directory.path, 'project.json'),
        mapId: departure,
      );
      expect(bundle.map.warps.single.triggerMode, MapWarpTriggerMode.onBump);

      final walk = walkUntilWarp(
        GameplayWorldState.fromMap(bundle.map, project: bundle.manifest),
        Direction.south,
      );
      expect(
        walk.result,
        isNot(isA<WarpTriggered>()),
        reason:
            'the mode chosen in the inspector is the one the engine applies',
      );
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
