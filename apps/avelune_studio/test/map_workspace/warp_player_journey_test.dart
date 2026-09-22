import 'dart:io';

import 'package:avelune_studio/features/map_workspace/application/map_entity_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/map_workspace/application/warp_editing_commands.dart';
import 'package:avelune_studio/features/map_workspace/data/local_map_workspace_adapter.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:path/path.dart' as p;

import '../../tool/create_example_project.dart' show writeExampleProject;

const departure = 'jardin';
const arrival = 'clairiere';
const arrivalCell = GridPos(x: 7, y: 3);

/// The runtime tests' own harness: a bare game instance is never mounted by a
/// GameWidget, so the loaded flag is provided the same way they do.
class _LoadedPlayableMapGame extends PlayableMapGame {
  _LoadedPlayableMapGame({
    required super.bundle,
    required super.projectFilePath,
    required super.saveRepository,
  });

  @override
  bool get isLoaded => true;
}

final class _MemorySaveRepository implements GameSaveRepository {
  GameState? _state;
  @override
  Future<void> save(GameState state) async => _state = state;
  @override
  Future<GameState?> load() async => _state;
  @override
  Future<bool> exists() async => _state != null;
  @override
  Future<void> delete() async => _state = null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory directory;
  late ProjectSession session;

  setUp(() async {
    final temporary = await Directory.systemTemp.createTemp('avelune_player_');
    directory = Directory(await temporary.resolveSymbolicLinks());
    await writeExampleProject(directory);
    session = ProjectSession(
      sessionId: directory.path,
      name: 'Passage dans le Player',
      directoryPath: directory.path,
    );
  });
  tearDown(() async {
    if (directory.existsSync()) await directory.delete(recursive: true);
  });

  /// Authors the departure map with Studio commands and writes it to disk.
  Future<String> authorWarp({
    required GridPos start,
    required GridPos warpCell,
    MapWarpTriggerMode mode = MapWarpTriggerMode.onEnter,
  }) async {
    final workspace = MapWorkspaceController(
      session,
      LocalMapWorkspaceAdapter(),
    );
    await workspace.initialize();
    await workspace.activate(
      workspace.project!.maps.firstWhere((entry) => entry.id == departure),
    );
    final document = workspace.active!;
    final entities = MapEntityEditingCommands(document, workspace.project!);
    entities.move(entities.playerStart()!.id, start);
    final warps = WarpEditingCommands(document, workspace.project!);
    final warp = warps.place(
      workspace.project!.maps.firstWhere((entry) => entry.id == arrival),
      warpCell,
    );
    warps.retarget(warp.id, targetPos: arrivalCell, triggerMode: mode);
    expect(await workspace.save(document), isTrue, reason: workspace.error);
    workspace.dispose();
    return warp.id;
  }

  Future<PlayableMapGame> bootPlayer() async {
    final projectFilePath = p.join(directory.path, 'project.json');
    final bundle = await loadRuntimeMapBundle(
      projectFilePath: projectFilePath,
      mapId: departure,
    );
    final game = _LoadedPlayableMapGame(
      bundle: bundle,
      projectFilePath: projectFilePath,
      saveRepository: _MemorySaveRepository(),
    );
    game.onGameResize(Vector2(320, 240));
    await game.onLoad();
    for (var i = 0; i < 240; i++) {
      if (game.debugCompletedMapActivationDispatchCount > 0) break;
      game.update(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    expect(
      game.debugCompletedMapActivationDispatchCount,
      greaterThan(0),
      reason: 'the Player finished booting before receiving any input',
    );
    return game;
  }

  /// Holds a direction the way the host does, then lets the game run.
  Future<void> walk(
    PlayableMapGame game,
    RuntimeInputControl control, {
    required bool Function() until,
    int frames = 600,
  }) async {
    expect(
      game.handleRuntimeInputEvent(RuntimeInputEvent.press(control)),
      isTrue,
      reason: 'the Player accepted the movement command',
    );
    for (var i = 0; i < frames && !until(); i++) {
      game.update(1 / 60);
      await Future<void>.delayed(Duration.zero);
    }
    game.handleRuntimeInputEvent(RuntimeInputEvent.release(control));
  }

  test(
    'a warp authored in Studio moves the player to the other map',
    () async {
      final warpId = await authorWarp(
        start: const GridPos(x: 4, y: 4),
        warpCell: const GridPos(x: 4, y: 6),
      );
      final game = await bootPlayer();
      expect(game.debugPlayerGridPosition, const GridPos(x: 4, y: 4));

      await walk(
        game,
        RuntimeInputControl.down,
        until: () => game.debugLastCompletedMapActivation?.mapId == arrival,
      );

      expect(
        game.debugLastCompletedMapActivation?.mapId,
        arrival,
        reason: 'the Player itself loaded and activated the destination map',
      );
      expect(
        game.debugPlayerGridPosition,
        arrivalCell,
        reason: 'the player stands where the author set the arrival cell',
      );
      expect(warpId, isNotEmpty);
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );

  test(
    'a warp saved as bump keeps the player on the departure map',
    () async {
      await authorWarp(
        start: const GridPos(x: 4, y: 4),
        warpCell: const GridPos(x: 4, y: 6),
        mode: MapWarpTriggerMode.onBump,
      );
      final game = await bootPlayer();

      await walk(
        game,
        RuntimeInputControl.down,
        until: () => game.debugLastCompletedMapActivation?.mapId == arrival,
        frames: 240,
      );

      expect(
        game.debugLastCompletedMapActivation?.mapId,
        isNot(arrival),
        reason: 'walking onto a bump warp never hands the player over',
      );
    },
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
