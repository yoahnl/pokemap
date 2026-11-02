import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_battle_presentation.dart';
import 'package:map_runtime/src/presentation/flame/battle_pokemon_sprite_resolver.dart';

void main() {
  late Directory project;
  late Gen5BattleSourceBundle bundle;
  late List<(String, int)> requests;

  setUp(() async {
    project = await Directory.systemTemp.createTemp('gen5-sprite-selection-');
    requests = [];
    final species = File('${project.path}/data/pokemon/species/localmon.json');
    await species.parent.create(recursive: true);
    await species.writeAsString(jsonEncode({
      'schemaVersion': currentPokemonDataSchemaVersion,
      'id': 'localmon',
      'nationalDex': 506,
      'typing': {'types': ['normal']},
      'baseStats': {'hp': 45, 'atk': 60, 'def': 45, 'spa': 25, 'spd': 45, 'spe': 55},
      'abilities': {'primary': 'vital-spirit'},
      'refs': {'learnset': 'localmon'},
      'progression': {'growthRateId': 'medium_fast', 'baseExp': 55, 'catchRate': 255},
    }));
    final media = File('${project.path}/data/pokemon/media/localmon.json');
    await media.parent.create(recursive: true);
    await media.writeAsString(jsonEncode({
      'schemaVersion': 2,
      'defaultFormId': 'base',
      'variants': {
        'base': {'frontStatic': 'assets/front.png', 'frontAnimated': 'assets/front.gif',
          'backStatic': 'assets/back.png', 'backAnimated': 'assets/back.gif'},
        'other': {'frontStatic': 'assets/other.png', 'frontAnimated': 'assets/other.gif'},
      },
    }));
    for (final name in ['front.png', 'front.gif', 'back.png', 'back.gif', 'other.png', 'other.gif']) {
      final file = File('${project.path}/assets/$name');
      await file.parent.create(recursive: true);
      await file.writeAsBytes([1]);
    }
    bundle = Gen5BattleSourceBundle(
      species: 'lillipup',
      nationalDex: 506,
      release: 'test-release',
      sourceRepository: 'fuddlesworth/pokebw2',
      sourceRevision: 'a' * 40,
      sourceDirectory: 'res/pokemon/lillipup',
      reconstruction: 'test',
      redistributionStatus: 'test',
      assets: {for (final name in gen5BattleBundleAssetNames) name: Uint8List.fromList([1])},
    );
  });

  tearDown(() async {
    if (await project.exists()) await project.delete(recursive: true);
  });

  Future<Gen5BattleSourceBundle?> load({
    required String projectSpeciesId,
    required int projectNationalDex,
    bool Function()? isCurrent,
  }) async {
    requests.add((projectSpeciesId, projectNationalDex));
    return bundle;
  }

  BattlePokemonSpriteResolver resolver() => BattlePokemonSpriteResolver(
    manifest: const ProjectManifest(
      name: 'gen5-selection',
      maps: [],
      tilesets: [],
      pokemon: ProjectPokemonConfig(ruleset: PokemonRulesetProfile.pokeMapBetaV1),
    ),
    projectRootDirectory: project.path,
    gen5SourceLoader: load,
  );

  test('uses the verified project species and dex for a shiny back sprite', () async {
    final sprite = await resolver().resolve(
      speciesId: 'localmon',
      isPlayerSide: true,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'base', genderId: 'male', isShiny: true,
      ),
    );
    final nativeSource = sprite.gen5Source;
    expect(nativeSource, isNotNull);
    expect(nativeSource!.shiny, isTrue);
    expect(sprite.facing, BattleCombatantSpriteFacing.back);
    expect(sprite.explicitAnimatedImageAbsolutePath, endsWith('/back.gif'));
    expect(requests, isEmpty);
    expect(await nativeSource.load(), same(bundle));
    expect(requests, [('localmon', 506)]);
  });

  test('uses the native source when the media document is missing', () async {
    await File('${project.path}/data/pokemon/media/localmon.json').delete();
    final sprite = await resolver().resolve(
      speciesId: 'localmon',
      isPlayerSide: true,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'base', genderId: 'male', isShiny: false,
      ),
    );
    expect(sprite.explicitImageAbsolutePath, isNull);
    expect(sprite.explicitAnimatedImageAbsolutePath, isNull);
    expect(sprite.gen5Source, isNotNull);
    expect(await sprite.gen5Source!.load(), same(bundle));
    expect(requests, [('localmon', 506)]);
  });

  test('uses the native source when the media has no variant', () async {
    await File('${project.path}/data/pokemon/media/localmon.json').writeAsString(
      jsonEncode({'schemaVersion': 2, 'defaultFormId': 'base', 'variants': {}}),
    );
    final sprite = await resolver().resolve(
      speciesId: 'localmon',
      isPlayerSide: false,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'base', genderId: 'male', isShiny: false,
      ),
    );
    expect(sprite.gen5Source, isNotNull);
    expect(await sprite.gen5Source!.load(), same(bundle));
    expect(requests, [('localmon', 506)]);
  });

  test('does not assume an alternate form when media is missing', () async {
    await File('${project.path}/data/pokemon/media/localmon.json').delete();
    final sprite = await resolver().resolve(
      speciesId: 'localmon',
      isPlayerSide: false,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'other', genderId: 'male', isShiny: false,
      ),
    );
    expect(sprite.gen5Source, isNull);
    expect(requests, isEmpty);
  });

  test('keeps an authored alternate form on its existing image fallback', () async {
    final sprite = await resolver().resolve(
      speciesId: 'localmon',
      isPlayerSide: false,
      visualIdentity: const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'other', genderId: 'male', isShiny: false,
      ),
    );
    expect(sprite.gen5Source, isNull);
    expect(sprite.explicitAnimatedImageAbsolutePath, endsWith('/other.gif'));
    expect(requests, isEmpty);
  });

  test('keeps an unknown or female visual identity on the existing fallback', () async {
    final subject = resolver();
    for (final identity in <RuntimeBattleVisualIdentity?>[
      null,
      const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'base', genderId: 'female', isShiny: false,
      ),
      const RuntimeBattleVisualIdentity(
        speciesId: 'localmon', formId: 'base', genderId: 'male', isShiny: null,
      ),
    ]) {
      final sprite = await subject.resolve(
        speciesId: 'localmon', isPlayerSide: false, visualIdentity: identity,
      );
      expect(sprite.gen5Source, isNull);
      expect(sprite.explicitAnimatedImageAbsolutePath, endsWith('/front.gif'));
    }
    expect(requests, isEmpty);
  });
}
