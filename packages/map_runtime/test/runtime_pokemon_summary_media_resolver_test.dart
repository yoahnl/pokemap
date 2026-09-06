import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data.dart';
import 'package:map_runtime/src/player/runtime_player_pause_data_builder.dart';
import 'package:map_runtime/src/player/runtime_pokemon_summary.dart';
import 'package:map_runtime/src/player/runtime_pokemon_summary_media_resolver.dart';

void main() {
  late Directory root;
  late RuntimePokemonSummaryMediaResolver resolver;

  Future<void> write(String path, Object value) async {
    final file = File('${root.path}/$path');
    await file.parent.create(recursive: true);
    await file.writeAsString(value is String ? value : jsonEncode(value));
  }

  Future<void> media(Map<String, Object?> variants) => write(
        'data/pokemon/media/shared.json',
        {
          'schemaVersion': 1,
          'speciesId': 'shared',
          'defaultFormId': 'base',
          'variants': variants,
        },
      );

  setUp(() async {
    root = await Directory.systemTemp.createTemp('runtime-summary-media-');
    resolver = RuntimePokemonSummaryMediaResolver(
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
    );
  });

  tearDown(() => root.delete(recursive: true));

  test('resolves shared media reference and exact form for both roles',
      () async {
    await write('assets/base.png', 'base');
    await write('assets/form-party.png', 'party');
    await write('assets/form-portrait.png', 'portrait');
    await media({
      'base': {'party': 'assets/base.png'},
      'alola': {
        'party': 'assets/form-party.png',
        'portrait': 'assets/form-portrait.png',
      },
    });

    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'raichu',
      mediaRef: 'shared',
      formId: 'alola',
      gender: 'female',
    ));

    expect(result.thumbnail?.absoluteFilePath, endsWith('/form-party.png'));
    expect(
        result.illustration?.absoluteFilePath, endsWith('/form-portrait.png'));
    expect(result.thumbnail?.sampling, ProjectMenuImageSampling.smooth);
    expect(result.illustration?.sampling, ProjectMenuImageSampling.smooth);
  });

  test('missing form never substitutes default media', () async {
    await write('assets/base.png', 'base');
    await media({
      'base': {'party': 'assets/base.png'}
    });
    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'raichu',
      mediaRef: 'shared',
      formId: 'missing',
    ));
    expect(result.thumbnail, isNull);
    expect(result.illustration, isNull);
  });

  test('media document identity must match its reference rather than species',
      () async {
    await write('assets/wrong.png', 'wrong');
    await write('data/pokemon/media/shared.json', {
      'schemaVersion': 1,
      'speciesId': 'raichu',
      'defaultFormId': 'base',
      'variants': {
        'base': {'party': 'assets/wrong.png'},
      },
    });
    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'raichu',
      mediaRef: 'shared',
    ));
    expect(result.thumbnail, isNull);
    expect(result.illustration, isNull);
  });

  test('shiny uses only shiny media and preserves pixel sampling', () async {
    await write('assets/shiny.png', 'shiny');
    await write('assets/normal.png', 'normal');
    await media({
      'base': {
        'party': 'assets/normal.png',
        'portrait': 'assets/normal.png',
        'frontShinyStatic': 'assets/shiny.png',
      },
    });
    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'pikachu',
      mediaRef: 'shared',
      isShiny: true,
    ));
    expect(result.thumbnail?.absoluteFilePath, endsWith('/shiny.png'));
    expect(result.illustration?.absoluteFilePath, endsWith('/shiny.png'));
    expect(result.illustration?.sampling, ProjectMenuImageSampling.pixelArt);
    await File('${root.path}/assets/shiny.png').delete();
    final missing = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'pikachu',
      mediaRef: 'shared',
      isShiny: true,
    ));
    expect(missing.thumbnail, isNull);
    expect(missing.illustration, isNull);
  });

  test('missing preferred files fall back within the same form', () async {
    await write('assets/front.png', 'front');
    await media({
      'base': {
        'party': 'assets/missing.png',
        'portrait': 'assets/missing.png',
        'frontStatic': 'assets/front.png',
      },
    });
    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'pikachu',
      mediaRef: 'shared',
    ));
    expect(result.thumbnail?.absoluteFilePath, endsWith('/front.png'));
    expect(result.illustration?.sampling, ProjectMenuImageSampling.pixelArt);
  });

  test('rejects network paths, traversal and symlink escapes', () async {
    final external = await Directory.systemTemp.createTemp('outside-media-');
    addTearDown(() => external.delete(recursive: true));
    await File('${external.path}/private.png').writeAsString('private');
    await Link('${root.path}/outside').create(external.path);
    await media({
      'base': {
        'party': 'https://example.com/pokemon.png',
        'icon': '../private.png',
        'portrait': 'outside/private.png',
        'frontStatic': '${external.path}/private.png',
      },
    });
    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'pikachu',
      mediaRef: 'shared',
    ));
    expect(result.thumbnail, isNull);
    expect(result.illustration, isNull);
  });

  test('invalid and absent media leave summary usable', () async {
    await write('data/pokemon/media/shared.json', '{broken');
    final result = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'pikachu',
      mediaRef: 'shared',
    ));
    expect(result.thumbnail, isNull);
    expect(result.illustration, isNull);
    final absent = await resolver.resolve(const RuntimePokemonMediaIdentity(
      speciesId: 'absent',
    ));
    expect(absent.thumbnail, isNull);
  });

  test('pause builder attaches local media to live party summaries', () async {
    await write('assets/party.png', 'party');
    await media({
      'base': {'party': 'assets/party.png'}
    });
    await write('data/pokemon/species/pikachu.json', {
      'id': 'pikachu',
      'names': {'fr': 'Pikachu'},
      'forms': {'formId': 'base'},
      'refs': {'media': 'shared'},
    });
    final details = await const RuntimePlayerPauseDataBuilder().build(
      gameState: GameState(
        saveId: 'media-test',
        currentMapId: 'town',
        party: const PlayerParty(members: [
          PlayerPokemon(
            speciesId: 'pikachu',
            natureId: 'hardy',
            abilityId: 'static',
            level: 5,
            currentHp: 20,
            gender: 'female',
          ),
        ]),
      ),
      projectRootDirectory: root.path,
      pokemonConfig: const ProjectPokemonConfig(
        ruleset: PokemonRulesetProfile.pokeMapBetaV1,
      ),
      locale: 'fr',
      itemCatalog: ItemCatalogSnapshot.fromCatalog(mvpItemCatalog),
    );
    final summary = details[RuntimePlayerPauseSection.party]!
        .entries
        .single
        .pokemonSummary!;
    expect(summary.identity?.gender, 'female');
    expect(summary.identity?.mediaRef, 'shared');
    expect(summary.media.thumbnail?.absoluteFilePath, endsWith('/party.png'));
    expect(
        summary.media.illustration?.absoluteFilePath, endsWith('/party.png'));
  });
}
