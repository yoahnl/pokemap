import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

Future<Directory> createMinimalEvaluationProject({Directory? parent}) async {
  final root = await (parent ?? Directory.systemTemp).createTemp(
    'minimal-evaluation-',
  );
  final map = MapData(
    id: 'start',
    name: 'Start',
    size: const GridSize(width: 4, height: 4),
    entities: const [
      MapEntity(
        id: 'spawn',
        name: 'Start',
        kind: MapEntityKind.spawn,
        pos: GridPos(x: 1, y: 2),
        blocksMovement: false,
        spawn: MapEntitySpawnData(role: EntitySpawnRole.playerStart),
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'Synthetic evaluation',
    tilesets: [],
    maps: [
      const ProjectMapEntry(
        id: 'start',
        name: 'Start',
        relativePath: 'start.json',
      ),
    ],
    pokemon: const ProjectPokemonConfig(
      enabled: false,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
    ),
    newGame: const ProjectNewGameConfig(
      enabled: true,
      startMapId: 'start',
      startSpawnId: 'spawn',
      startingMoney: 17,
    ),
  );
  await File('${root.path}/project.json')
      .writeAsString(jsonEncode(project.toJson()));
  await File('${root.path}/start.json').writeAsString(jsonEncode(map.toJson()));
  return root;
}
