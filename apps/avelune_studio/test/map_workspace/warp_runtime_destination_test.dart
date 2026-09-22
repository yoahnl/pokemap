import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../support/map_workspace_fixture.dart';

ProjectMapEntry get clearing =>
    workspaceEntries.firstWhere((entry) => entry.id == 'a');
ProjectMapEntry get garden =>
    workspaceEntries.firstWhere((entry) => entry.id == 'b');

/// The engine refuses a map without a player start, and Studio cannot place
/// one yet: the spawn family is still unwired. The fixture supplies it so the
/// warp itself is what this test measures.
const playerStart = MapEntity(
  id: 'player-start',
  name: 'Départ',
  kind: MapEntityKind.spawn,
  pos: GridPos(x: 0, y: 0),
  spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
);

void main() {
  test('a placed warp survives saving and reopening the map', () async {
    final port = WorkspaceMemoryPort();
    final workspace = MapWorkspaceController(workspaceSession, port);
    await workspace.initialize();
    addTearDown(workspace.dispose);
    await workspace.activate(clearing);

    final document = workspace.active!;
    final commands = WarpEditingCommands(document, workspaceProject);
    final warp = commands.place(garden, const GridPos(x: 3, y: 4));
    commands.retarget(warp.id, targetPos: const GridPos(x: 6, y: 2));
    expect(await workspace.save(document), isTrue, reason: workspace.error);
    expect(document.dirty, isFalse);

    final reopened = MapWorkspaceController(workspaceSession, port);
    await reopened.initialize();
    addTearDown(reopened.dispose);
    await reopened.activate(clearing);

    final restored = reopened.active!.current.warps.single;
    expect(restored.id, warp.id);
    expect(restored.pos, const GridPos(x: 3, y: 4));
    expect(restored.targetMapId, 'b');
    expect(restored.targetPos, const GridPos(x: 6, y: 2));
  });

  test('the game engine reads the destination the author chose', () async {
    final port = WorkspaceMemoryPort();
    final workspace = MapWorkspaceController(workspaceSession, port);
    await workspace.initialize();
    addTearDown(workspace.dispose);
    await workspace.activate(clearing);

    final document = workspace.active!;
    final commands = WarpEditingCommands(document, workspaceProject);
    final warp = commands.place(garden, const GridPos(x: 3, y: 4));
    commands.retarget(
      warp.id,
      targetPos: const GridPos(x: 6, y: 2),
      triggerMode: MapWarpTriggerMode.onEnter,
    );
    expect(await workspace.save(document), isTrue, reason: workspace.error);

    final world = GameplayWorldState.fromMap(
      port.saved['a']!.copyWith(entities: [playerStart]),
      project: workspaceProject,
    );
    final reached = world.warpAt(3, 4);
    expect(
      reached,
      isNotNull,
      reason: 'the engine finds a warp on the cell the author clicked',
    );
    expect(reached!.targetMapId, 'b');
    expect(reached.targetPos, const GridPos(x: 6, y: 2));
    expect(
      world.warpAt(3, 5),
      isNull,
      reason: 'the warp stays on its own cell',
    );
    expect(
      workspaceProject.maps.any((entry) => entry.id == reached.targetMapId),
      isTrue,
      reason: 'the destination is a map the project can really open',
    );
    final destination = port.saved['b'] ?? workspaceMap('b');
    expect(
      reached.targetPos.x < destination.size.width &&
          reached.targetPos.y < destination.size.height,
      isTrue,
      reason: 'the arrival cell exists on the destination map',
    );
  });

  test('a warp set to bump does not trigger on simple entry', () async {
    final port = WorkspaceMemoryPort();
    final workspace = MapWorkspaceController(workspaceSession, port);
    await workspace.initialize();
    addTearDown(workspace.dispose);
    await workspace.activate(clearing);

    final document = workspace.active!;
    final commands = WarpEditingCommands(document, workspaceProject);
    final warp = commands.place(garden, const GridPos(x: 2, y: 2));
    commands.retarget(warp.id, triggerMode: MapWarpTriggerMode.onBump);

    final world = GameplayWorldState.fromMap(
      document.current.copyWith(entities: [playerStart]),
      project: workspaceProject,
    );
    expect(
      world.warpOnEnterAt(2, 2, Direction.south),
      isNull,
      reason: 'the mode chosen in the inspector is the one the engine applies',
    );
    expect(world.warpOnBumpAt(2, 2, Direction.south)!.id, warp.id);
  });
}
