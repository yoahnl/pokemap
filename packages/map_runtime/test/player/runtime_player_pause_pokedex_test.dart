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
    'dexContent': {'flavorText': 'Une fleur grandit sur son dos.'},
    'forms': {'formId': 'bloom'},
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
    Directory? projectRoot,
  }) async {
    final sections = await const RuntimePlayerPauseDataBuilder().build(
      gameState: gameState,
      projectRootDirectory: (projectRoot ?? root).path,
      pokemonConfig: _config,
      locale: locale,
    );
    return sections[RuntimePlayerPauseSection.pokedex]!;
  }

  test('public media and description follow knowledge and exact form',
      () async {
    final mediaDirectory = Directory('${root.path}/data/pokemon/media');
    await mediaDirectory.create(recursive: true);
    final image = File('${root.path}/portrait.png');
    await image.writeAsBytes([1, 2, 3]);
    await File('${root.path}/wrong.png').writeAsBytes([3, 2, 1]);
    await File('${mediaDirectory.path}/ivysaur.json').writeAsString(jsonEncode(
      PokemonMediaFile(
        speciesId: 'ivysaur',
        defaultFormId: 'default',
        variants: const {
          'default':
              PokemonMediaVariant(party: 'wrong.png', portrait: 'wrong.png'),
          'bloom': PokemonMediaVariant(
              party: 'portrait.png', portrait: 'portrait.png'),
        },
      ).toJson(),
    ));
    final initial = GameState(saveId: 'dex');
    final before = jsonEncode(initial.toJson());
    final unknown = (await buildDex(initial))
        .entries
        .singleWhere((entry) => entry.id == 'ivysaur')
        .pokedexEntry!;
    expect(unknown.identity, isNull);
    expect(unknown.media.thumbnail, isNull);
    expect(unknown.media.illustration, isNull);
    expect(unknown.description, isNull);
    expect(jsonEncode(initial.toJson()), before);
    final seen = (await buildDex(initial.copyWith(
      progression: const PlayerProgression(seenSpeciesIds: ['ivysaur']),
    )))
        .entries
        .singleWhere((entry) => entry.id == 'ivysaur')
        .pokedexEntry!;
    expect(seen.media.thumbnail?.absoluteFilePath,
        await image.resolveSymbolicLinks());
    expect(seen.identity?.formId, 'bloom');
    expect(seen.media.illustration?.absoluteFilePath,
        await image.resolveSymbolicLinks());
    expect(seen.description, 'Une fleur grandit sur son dos.');
  });

  test('unknown projection rejects descriptions and resolved images', () {
    expect(
        () => RuntimePlayerPokedexEntrySnapshot(
              knowledge: RuntimePlayerPokedexKnowledge.unknown,
              description: 'A secret description',
            ),
        throwsArgumentError);
    expect(
        () => RuntimePlayerPokedexEntrySnapshot(
              knowledge: RuntimePlayerPokedexKnowledge.unknown,
              media: const RuntimePokemonSummaryMediaSnapshot(
                illustration: RuntimePokemonLocalImageSnapshot(
                  absoluteFilePath: '/secret.png',
                  sampling: ProjectMenuImageSampling.smooth,
                ),
              ),
            ),
        throwsArgumentError);
  });

  test('invalid catalog is distinct from empty and repairs invalidate cache',
      () async {
    final state = GameState(saveId: 'dex');
    final file = File('${root.path}/data/pokemon/species/0002-ivysaur.json');
    final valid = await file.readAsString();
    await file.writeAsString('{invalid');
    final broken = await buildDex(state);
    expect(broken.entries, isEmpty);
    expect(broken.emptyMessage, contains('ne peut pas être lu'));
    await file.writeAsString(valid);
    expect((await buildDex(state)).entries, hasLength(4));
    final directory = file.parent;
    await for (final entity in directory.list()) {
      await entity.delete();
    }
    final empty = await buildDex(state);
    expect(empty.entries, isEmpty);
    expect(empty.emptyMessage, contains('Aucune espèce'));
    await directory.delete();
    expect(
        (await buildDex(state)).emptyMessage, contains('ne peut pas être lu'));
  });

  test('species cache observes edits additions and removals', () async {
    final state = GameState(
      saveId: 'dex',
      progression: const PlayerProgression(seenSpeciesIds: ['ivysaur']),
    );
    final file = File('${root.path}/data/pokemon/species/0002-ivysaur.json');
    final original = await file.readAsString();
    final originalStat = await file.stat();
    expect(
        (await buildDex(state, locale: 'en'))
            .entries
            .singleWhere((entry) => entry.id == 'ivysaur')
            .title,
        'Ivysaur');
    await file.writeAsString(original.replaceFirst('Ivysaur', 'Renewed'));
    await file
        .setLastModified(originalStat.modified.add(const Duration(seconds: 1)));
    expect(
        (await buildDex(state, locale: 'en'))
            .entries
            .singleWhere((entry) => entry.id == 'ivysaur')
            .title,
        'Renewed');
    final modifiedTime = (await file.stat()).modified;
    await file.writeAsString(original.replaceFirst('Ivysaur', 'Longer name'));
    await file.setLastModified(modifiedTime);
    expect(
        (await buildDex(state, locale: 'en'))
            .entries
            .singleWhere((entry) => entry.id == 'ivysaur')
            .title,
        'Longer name');
    final added = File('${file.parent.path}/0003-venusaur.json');
    await added.writeAsString(jsonEncode({'id': 'venusaur', 'nationalDex': 3}));
    expect((await buildDex(state)).entries.map((entry) => entry.id),
        ['bulbasaur', 'ivysaur', 'venusaur', 'charmander', 'nameless_relic']);
    await file.delete();
    expect((await buildDex(state)).entries.map((entry) => entry.id),
        ['bulbasaur', 'venusaur', 'charmander', 'nameless_relic']);
  });

  test('species cache evicts the least recently used project after four roots',
      () async {
    final state = GameState(
      saveId: 'dex',
      progression: const PlayerProgression(seenSpeciesIds: ['ivysaur']),
    );
    await buildDex(state);
    final projects = <Directory>[];
    for (var index = 0; index < 4; index++) {
      final project = await _projectRoot();
      projects.add(project);
      addTearDown(() => project.delete(recursive: true));
      await File('${project.path}/data/pokemon/species/0002-ivysaur.json')
          .setLastModified(DateTime.utc(2026, 1, 1));
      if (index == 3) await buildDex(state);
      await buildDex(state, projectRoot: project);
    }
    final evicted = projects.first;
    final file = File('${evicted.path}/data/pokemon/species/0002-ivysaur.json');
    final original = await file.readAsString();
    final originalStat = await file.stat();
    await file.writeAsString(original.replaceFirst('Ivysaur', 'Renewed'));
    await file.setLastModified(originalStat.modified);
    expect((await file.stat()).size, originalStat.size);
    expect((await file.stat()).modified, originalStat.modified);

    final rebuilt = await buildDex(state, projectRoot: evicted, locale: 'en');
    expect(rebuilt.entries.singleWhere((entry) => entry.id == 'ivysaur').title,
        'Renewed');
  });

  test('invalid species catalogs are retried even with an unchanged signature',
      () async {
    final state = GameState(saveId: 'dex');
    final file = File('${root.path}/data/pokemon/species/0002-ivysaur.json');
    final valid = await file.readAsString();
    final originalStat = await file.stat();
    await file.writeAsString(valid.replaceFirst('{', '!'));
    await file.setLastModified(originalStat.modified);
    expect(
        (await buildDex(state)).emptyMessage, contains('ne peut pas être lu'));
    await file.writeAsString(valid);
    await file.setLastModified(originalStat.modified);

    expect((await buildDex(state)).entries, hasLength(4));
  });

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
