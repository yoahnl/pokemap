import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/map_runtime.dart';

/// Projection Pokédex du menu pause — BETA-SYS-001.
///
/// La section existait sans preuve dédiée : rien ne cassait si « Inconnu »
/// affichait le nom d'une espèce jamais vue, si la dominance de capture
/// (party/PC ⇒ Capturé, même sans trace dans la progression) régressait, ou
/// si le tri par numéro se perdait. Ces cas figent la projection.
Future<Directory> _projectRoot() async {
  final root = await Directory.systemTemp.createTemp('pokedex-pause-');
  final species = Directory('${root.path}/data/pokemon/species');
  await species.create(recursive: true);
  Future<void> write(
    String fileName,
    Map<String, Object?> json,
  ) =>
      File('${species.path}/$fileName').writeAsString(jsonEncode(json));
  await write('0002-ivysaur.json', <String, Object?>{
    'id': 'ivysaur',
    'nationalDex': 2,
    'names': <String, String>{'fr': 'Herbizarre', 'en': 'Ivysaur'},
    'typing': <String, Object?>{
      'types': <String>['grass', 'poison'],
    },
  });
  await write('0001-bulbasaur.json', <String, Object?>{
    'id': 'bulbasaur',
    'nationalDex': 1,
    'names': <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
    'typing': <String, Object?>{
      'types': <String>['grass', 'poison'],
    },
  });
  await write('0004-charmander.json', <String, Object?>{
    'id': 'charmander',
    'nationalDex': 4,
    'names': <String, String>{'fr': 'Salamèche', 'en': 'Charmander'},
    'typing': <String, Object?>{
      'types': <String>['fire'],
    },
  });
  await write('9999-nameless.json', <String, Object?>{
    'id': 'nameless_relic',
    'nationalDex': 9999,
  });
  return root;
}

ProjectPokemonConfig get _config => const ProjectPokemonConfig(
      enabled: true,
      ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      dataRoot: 'data/pokemon',
      speciesDir: 'data/pokemon/species',
      learnsetsDir: 'data/pokemon/learnsets',
      evolutionsDir: 'data/pokemon/evolutions',
      mediaDir: 'data/pokemon/media',
      catalogFiles: <String, String>{},
    );

PlayerPokemon _member(String speciesId) => PlayerPokemon(
      speciesId: speciesId,
      natureId: 'hardy',
      abilityId: 'overgrow',
      level: 5,
      currentHp: 10,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory root;

  setUp(() async {
    root = await _projectRoot();
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  Future<RuntimePlayerPauseDetailSnapshot> buildDex(
    GameState gameState, {
    String locale = 'fr',
  }) async {
    final sections = await const RuntimePlayerPauseDataBuilder().build(
      gameState: gameState,
      projectRootDirectory: root.path,
      pokemonConfig: _config,
      locale: locale,
    );
    return sections[RuntimePlayerPauseSection.pokedex]!;
  }

  group('BETA-SYS-001 the pokedex projection answers to the game state', () {
    test('an unknown species hides its name and shows Inconnu', () async {
      final dex = await buildDex(GameState(saveId: 'dex'));

      final charmander =
          dex.entries.singleWhere((entry) => entry.id == 'charmander');
      expect(charmander.title, '???');
      expect(charmander.subtitle, contains('Inconnu'));
      expect(
        charmander.subtitle,
        isNot(contains('fire')),
        reason: 'the types of a never-seen species must stay hidden',
      );
      expect(charmander.trailingLabel, isNull);
    });

    test('a seen species shows its localized name, state and types', () async {
      final dex = await buildDex(
        GameState(
          saveId: 'dex',
          progression: const PlayerProgression(
            seenSpeciesIds: <String>['ivysaur'],
          ),
        ),
      );

      final ivysaur = dex.entries.singleWhere((entry) => entry.id == 'ivysaur');
      expect(ivysaur.title, 'Herbizarre');
      expect(ivysaur.subtitle, contains('Vu'));
      expect(ivysaur.subtitle, contains('#002'));
      expect(ivysaur.subtitle, contains('Grass / Poison'));
      expect(ivysaur.trailingLabel, '○');
    });

    test('owning a species dominates: party and PC both mean Capturé',
        () async {
      // La dominance : aucune trace dans progression.caughtSpeciesIds, mais
      // l'individu est possédé — le Pokédex doit dire Capturé quand même.
      final dex = await buildDex(
        GameState(
          saveId: 'dex',
          party: PlayerParty(members: <PlayerPokemon>[_member('bulbasaur')]),
          pokemonStorage: PokemonStorage(
            boxes: <PokemonBox>[
              PokemonBox(
                id: 'box-1',
                label: 'Box 1',
                capacity: 30,
                pokemon: <PlayerPokemon>[_member('charmander')],
              ),
            ],
          ),
        ),
      );

      expect(
        dex.entries.singleWhere((entry) => entry.id == 'bulbasaur').subtitle,
        contains('Capturé'),
      );
      final charmander =
          dex.entries.singleWhere((entry) => entry.id == 'charmander');
      expect(charmander.subtitle, contains('Capturé'));
      expect(charmander.trailingLabel, '●');
      expect(charmander.title, 'Salamèche');
    });

    test('entries are ordered by national dex number', () async {
      final dex = await buildDex(GameState(saveId: 'dex'));

      expect(
        dex.entries.map((entry) => entry.id).toList(growable: false),
        <String>['bulbasaur', 'ivysaur', 'charmander', 'nameless_relic'],
      );
    });

    test('a species without names falls back to a humanized id once seen',
        () async {
      final dex = await buildDex(
        GameState(
          saveId: 'dex',
          progression: const PlayerProgression(
            seenSpeciesIds: <String>['nameless_relic'],
          ),
        ),
      );

      final nameless =
          dex.entries.singleWhere((entry) => entry.id == 'nameless_relic');
      expect(nameless.title, isNot('???'));
      expect(nameless.title.toLowerCase(), contains('nameless'));
    });

    test('the english locale localizes the knowledge states', () async {
      final dex = await buildDex(
        GameState(
          saveId: 'dex',
          progression: const PlayerProgression(
            seenSpeciesIds: <String>['ivysaur'],
          ),
        ),
        locale: 'en',
      );

      expect(
        dex.entries.singleWhere((entry) => entry.id == 'ivysaur').subtitle,
        contains('Seen'),
      );
      expect(
        dex.entries.singleWhere((entry) => entry.id == 'charmander').subtitle,
        contains('Unknown'),
      );
    });
  });
}
