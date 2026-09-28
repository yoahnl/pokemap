import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/map_runtime.dart';

Future<GameState?> prepareStudioPlaytestStart(
  RuntimeMapBundle bundle,
  String projectFilePath,
) async {
  final project = bundle.manifest;
  final map = bundle.map;
  final newGame = project.newGame;
  if (!newGame.enabled || map.id == newGame.startMapId) return null;

  final spawn = _playtestSpawn(map, project);

  final authoredStart = await loadRuntimeMapBundle(
    projectFilePath: projectFilePath,
    mapId: newGame.startMapId,
  );
  final initial = createNewGameStateFromProject(
    project: project,
    startMap: authoredStart.map,
    locale: 'fr-FR',
    tileWidthPx: project.settings.tileWidth,
    tileHeightPx: project.settings.tileHeight,
  );
  return initial.copyWith(
    currentMapId: map.id,
    playerPosition: spawn.pos,
    playerFacing: spawn.facing,
  );
}

({GridPos pos, EntityFacing facing}) _playtestSpawn(
  MapData map,
  ProjectManifest project,
) {
  final defaultSpawnId = map.mapMetadata.defaultSpawnId?.trim();
  final hasPlayerSpawn = map.entities.any(
    (entity) =>
        entity.kind == MapEntityKind.spawn &&
        entity.spawn?.role == EntitySpawnRole.playerStart,
  );
  if ((defaultSpawnId != null && defaultSpawnId.isNotEmpty) || hasPlayerSpawn) {
    final authored = resolveInitialPlayerSpawn(
      map,
      tileWidthPx: project.settings.tileWidth,
      tileHeightPx: project.settings.tileHeight,
    );
    return (pos: authored.pos, facing: authored.facing.asFacing);
  }
  final centerX = map.size.width ~/ 2;
  final centerY = map.size.height ~/ 2;
  final world = GameplayWorldState.initial(
    map: map,
    playerPos: GridPos(x: centerX, y: centerY),
    project: project,
    tileWidth: project.settings.tileWidth,
    tileHeight: project.settings.tileHeight,
  );
  final candidates =
      <GridPos>[
        for (var y = 0; y < map.size.height; y++)
          for (var x = 0; x < map.size.width; x++) GridPos(x: x, y: y),
      ]..sort((a, b) {
        final aDistance = (a.x - centerX).abs() + (a.y - centerY).abs();
        final bDistance = (b.x - centerX).abs() + (b.y - centerY).abs();
        return aDistance.compareTo(bDistance);
      });
  for (final cell in candidates) {
    if (!world.isBlocked(cell.x, cell.y) &&
        !map.warps.any((warp) => warp.pos == cell)) {
      return (pos: cell, facing: EntityFacing.south);
    }
  }
  throw StateError(
    'Aucune case praticable pour démarrer le test de cette carte.',
  );
}
