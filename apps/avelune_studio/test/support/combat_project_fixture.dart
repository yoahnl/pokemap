import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';

import 'm3_story_fixture.dart';

Future<void> seedCombatProject(M3StoryFixture source) async {
  final projectFile = File('${source.directory.path}/project.json');
  final original = ProjectManifest.fromJson(
    jsonDecode(await projectFile.readAsString()) as Map<String, dynamic>,
  );
  await projectFile.writeAsString(
    jsonEncode(
      original
          .copyWith(
            pokemon: const ProjectPokemonConfig(
              ruleset: PokemonRulesetProfile.pokeMapBetaV1,
            ),
            newGame: ProjectNewGameConfig(
              enabled: true,
              startMapId: original.maps.first.id,
              startSpawnId: 'depart',
              initialParty: const [
                PlayerPokemon(
                  speciesId: 'bulbasaur',
                  natureId: 'bold',
                  abilityId: 'overgrow',
                  level: 10,
                  knownMoveIds: ['tackle'],
                ),
              ],
            ),
          )
          .toJson(),
    ),
  );
  final mapFile = File(
    '${source.directory.path}/${original.maps.first.relativePath}',
  );
  final map = MapData.fromJson(
    jsonDecode(await mapFile.readAsString()) as Map<String, dynamic>,
  );
  await mapFile.writeAsString(
    jsonEncode(
      map
          .copyWith(
            entities: [
              ...map.entities,
              const MapEntity(
                id: 'combat-guide',
                name: 'Guide de combat',
                kind: MapEntityKind.npc,
                pos: GridPos(x: 7, y: 9),
                npc: MapEntityNpcData(characterId: 'guide'),
              ),
            ],
          )
          .toJson(),
    ),
  );
  const fixtureRoot =
      '../../packages/map_editor/test/fixtures/manual_pokemon_import_pack_10';
  for (final (folder, name) in [
    ('species', '0001-bulbasaur.json'),
    ('learnsets', 'bulbasaur.json'),
    ('evolutions', 'bulbasaur.json'),
    ('media', 'bulbasaur.json'),
  ]) {
    final sourceFile = File('$fixtureRoot/$folder/$name');
    final target = File('${source.directory.path}/data/pokemon/$folder/$name');
    await target.parent.create(recursive: true);
    final document =
        jsonDecode(await sourceFile.readAsString()) as Map<String, dynamic>;
    document['schemaVersion'] = 1;
    await target.writeAsString(jsonEncode(document));
  }
  for (final name in ['moves', 'items']) {
    final target = File(
      '${source.directory.path}/data/pokemon/catalogs/$name.json',
    );
    await target.parent.create(recursive: true);
    await File(
      '../../examples/playable_runtime_host/golden_item_system/data/pokemon/catalogs/$name.json',
    ).copy(target.path);
    if (name == 'moves') {
      final catalog =
          jsonDecode(await target.readAsString()) as Map<String, dynamic>;
      final entries = catalog['entries'] as List<dynamic>;
      final tackle = entries.first as Map<String, dynamic>;
      entries.addAll([
        {...tackle, 'id': 'vine_whip', 'type': 'grass', 'pp': 25},
        {...tackle, 'id': 'razor_leaf', 'type': 'grass', 'pp': 25},
      ]);
      await target.writeAsString(jsonEncode(catalog));
    }
  }
}
