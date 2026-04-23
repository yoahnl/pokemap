import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_catalog.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';

BattleMove _battleMove({
  required String id,
  String type = 'normal',
  BattleMoveCategory category = BattleMoveCategory.physical,
  BattleMoveTarget target = BattleMoveTarget.opponent,
  bool requiresRecharge = false,
  bool setsStealthRock = false,
  bool setsSpikes = false,
  BattleWeatherId? weatherEffect,
  BattlePseudoWeatherId? pseudoWeatherEffect,
}) {
  return BattleMove(
    id: id,
    name: id,
    power: category == BattleMoveCategory.status ? 0 : 80,
    type: type,
    category: category,
    target: target,
    requiresRecharge: requiresRecharge,
    setsStealthRock: setsStealthRock,
    setsSpikes: setsSpikes,
    weatherEffect: weatherEffect,
    pseudoWeatherEffect: pseudoWeatherEffect,
  );
}

PokemonMove _pokemonMove({
  required String id,
  String type = 'normal',
  PokemonMoveCategory category = PokemonMoveCategory.physical,
  PokemonMoveTarget target = PokemonMoveTarget.normal,
  List<PokemonMoveFlag> flags = const <PokemonMoveFlag>[],
  List<PokemonMoveEffect> effects = const <PokemonMoveEffect>[],
  PokemonMoveEngineSupportLevel engineSupportLevel =
      PokemonMoveEngineSupportLevel.structuredSupported,
  String? showdownMoveId,
}) {
  return PokemonMove(
    id: id,
    name: id,
    type: type,
    category: category,
    target: target,
    accuracy: const PokemonMoveAccuracy.percent(value: 100),
    flags: flags,
    effects: effects,
    engineSupportLevel: engineSupportLevel,
    sourceRefs: PokemonMoveSourceRefs(showdownMoveId: showdownMoveId),
  );
}

void main() {
  group('BattleMoveVisualResolver', () {
    test('uses canonical showdownMoveId when available', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'thunderbolt_local': _pokemonMove(
          id: 'thunderbolt_local',
          type: 'electric',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'thunderbolt',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'thunderbolt_local',
          type: 'electric',
          category: BattleMoveCategory.special,
        ),
      );

      expect(resolved.showdownMoveId, equals('thunderbolt'));
      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownThunderbolt),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('direct mapping wins over fallback', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'thunderbolt_local': _pokemonMove(
          id: 'thunderbolt_local',
          type: 'electric',
          category: PokemonMoveCategory.special,
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.slicing],
          showdownMoveId: 'thunderbolt',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'thunderbolt_local',
          type: 'electric',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownThunderbolt),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('alias is resolved transitively', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'tidy_up': _pokemonMove(
          id: 'tidy_up',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.self,
          showdownMoveId: 'tidyup',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'tidy_up',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownBulkUp),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('multi-hop showdown alias chain resolves through max move roots', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'storm_bolt_local': _pokemonMove(
          id: 'storm_bolt_local',
          type: 'electric',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'maxlightning',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'storm_bolt_local',
          type: 'electric',
          category: BattleMoveCategory.special,
        ),
      );

      expect(resolved.showdownMoveId, equals('maxlightning'));
      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownThunderbolt),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('showdown alias roots can land on adapted elemental recipes', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'mist_ball_local': _pokemonMove(
          id: 'mist_ball_local',
          type: 'ice',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'mistball',
        ),
        'searing_shot_local': _pokemonMove(
          id: 'searing_shot_local',
          type: 'fire',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'searingshot',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final mistBall = resolver.resolve(
        _battleMove(
          id: 'mist_ball_local',
          type: 'ice',
          category: BattleMoveCategory.special,
        ),
      );
      final searingShot = resolver.resolve(
        _battleMove(
          id: 'searing_shot_local',
          type: 'fire',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        mistBall.recipeId,
        equals(BattleMoveVisualRecipeId.showdownFreezeDry),
      );
      expect(
        searingShot.recipeId,
        equals(BattleMoveVisualRecipeId.showdownMagmaStorm),
      );
      expect(mistBall.usesFallback, isFalse);
      expect(searingShot.usesFallback, isFalse);
    });

    test('direct fidelity-wave dark and sound routings resolve cleanly', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'snarl_local': _pokemonMove(
          id: 'snarl_local',
          type: 'dark',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'snarl',
        ),
        'sing_local': _pokemonMove(
          id: 'sing_local',
          category: PokemonMoveCategory.status,
          showdownMoveId: 'sing',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final snarl = resolver.resolve(
        _battleMove(
          id: 'snarl_local',
          type: 'dark',
          category: BattleMoveCategory.special,
        ),
      );
      final sing = resolver.resolve(
        _battleMove(
          id: 'sing_local',
          category: BattleMoveCategory.status,
        ),
      );

      expect(
        snarl.recipeId,
        equals(BattleMoveVisualRecipeId.showdownDarkPulse),
      );
      expect(
        sing.recipeId,
        equals(BattleMoveVisualRecipeId.showdownHyperVoice),
      );
      expect(snarl.usesFallback, isFalse);
      expect(sing.usesFallback, isFalse);
    });

    test('direct fidelity-wave contact and trap routings resolve cleanly', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'fake_out_local': _pokemonMove(
          id: 'fake_out_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'fakeout',
        ),
        'firespin_local': _pokemonMove(
          id: 'firespin_local',
          type: 'fire',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'firespin',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final fakeOut = resolver.resolve(_battleMove(id: 'fake_out_local'));
      final fireSpin = resolver.resolve(
        _battleMove(
          id: 'firespin_local',
          type: 'fire',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        fakeOut.recipeId,
        equals(BattleMoveVisualRecipeId.showdownQuickAttack),
      );
      expect(
        fireSpin.recipeId,
        equals(BattleMoveVisualRecipeId.showdownMagmaStorm),
      );
      expect(fakeOut.usesFallback, isFalse);
      expect(fireSpin.usesFallback, isFalse);
    });

    test('second fidelity-wave setup and signature routings resolve cleanly',
        () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'shell_smash_local': _pokemonMove(
          id: 'shell_smash_local',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.self,
          showdownMoveId: 'shellsmash',
        ),
        'waterspout_local': _pokemonMove(
          id: 'waterspout_local',
          type: 'water',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'waterspout',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final shellSmash = resolver.resolve(
        _battleMove(
          id: 'shell_smash_local',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
        ),
      );
      final waterSpout = resolver.resolve(
        _battleMove(
          id: 'waterspout_local',
          type: 'water',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        shellSmash.recipeId,
        equals(BattleMoveVisualRecipeId.showdownQuiverDance),
      );
      expect(
        waterSpout.recipeId,
        equals(BattleMoveVisualRecipeId.showdownOriginPulse),
      );
      expect(shellSmash.usesFallback, isFalse);
      expect(waterSpout.usesFallback, isFalse);
    });

    test('third fidelity-wave finisher routings resolve cleanly', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'fury_wrath_local': _pokemonMove(
          id: 'fury_wrath_local',
          type: 'dark',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'fierywrath',
        ),
        'torque_local': _pokemonMove(
          id: 'torque_local',
          type: 'fairy',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'magicaltorque',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final fieryWrath = resolver.resolve(
        _battleMove(
          id: 'fury_wrath_local',
          type: 'dark',
          category: BattleMoveCategory.special,
        ),
      );
      final magicalTorque = resolver.resolve(
        _battleMove(
          id: 'torque_local',
          type: 'fairy',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        fieryWrath.recipeId,
        equals(BattleMoveVisualRecipeId.showdownDarkPulse),
      );
      expect(
        magicalTorque.recipeId,
        equals(BattleMoveVisualRecipeId.showdownPlayRough),
      );
      expect(fieryWrath.usesFallback, isFalse);
      expect(magicalTorque.usesFallback, isFalse);
    });

    test('final catch-up wave mixes generic and custom routes safely', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'hidden_power_local': _pokemonMove(
          id: 'hidden_power_local',
          type: 'normal',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'hiddenpower',
        ),
        'guardian_local': _pokemonMove(
          id: 'guardian_local',
          type: 'fairy',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'guardianofalola',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final hiddenPower = resolver.resolve(
        _battleMove(
          id: 'hidden_power_local',
          type: 'normal',
          category: BattleMoveCategory.special,
        ),
      );
      final guardian = resolver.resolve(
        _battleMove(
          id: 'guardian_local',
          type: 'fairy',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        hiddenPower.recipeId,
        equals(BattleMoveVisualRecipeId.showdownHiddenPower),
      );
      expect(
        guardian.recipeId,
        equals(BattleMoveVisualRecipeId.showdownMoonBlast),
      );
      expect(hiddenPower.usesFallback, isFalse);
      expect(guardian.usesFallback, isFalse);
    });

    test('watershuriken resolves to its dedicated water volley recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'water_shuriken_local': _pokemonMove(
          id: 'water_shuriken_local',
          type: 'water',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'watershuriken',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'water_shuriken_local',
          type: 'water',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownWaterShuriken),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('slash resolves to its dedicated showdown slash recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'slash_local': _pokemonMove(
          id: 'slash_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'slash',
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.slicing],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'slash_local',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownSlash),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('slicing flag falls back to slash recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'custom_slash': _pokemonMove(
          id: 'custom_slash',
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.slicing],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(_battleMove(id: 'custom_slash'));

      expect(resolved.recipeId, equals(BattleMoveVisualRecipeId.genericSlash));
      expect(resolved.usesFallback, isTrue);
    });

    test('sound flag falls back to sound/status recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'growly_noise': _pokemonMove(
          id: 'growly_noise',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.normal,
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.sound],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'growly_noise',
          category: BattleMoveCategory.status,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.genericStatusPulse),
      );
      expect(resolved.usesFallback, isTrue);
    });

    test('bite flag falls back to the generic bite recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'custom_bite': _pokemonMove(
          id: 'custom_bite',
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.bite],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(_battleMove(id: 'custom_bite'));

      expect(resolved.recipeId, equals(BattleMoveVisualRecipeId.genericBite));
      expect(resolved.usesFallback, isTrue);
    });

    test('punch flag falls back to the generic punch recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'custom_punch': _pokemonMove(
          id: 'custom_punch',
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.punch],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(_battleMove(id: 'custom_punch'));

      expect(resolved.recipeId, equals(BattleMoveVisualRecipeId.genericPunch));
      expect(resolved.usesFallback, isTrue);
    });

    test('direct seeded status recipe wins for growl', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'growl_local': _pokemonMove(
          id: 'growl_local',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.normal,
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.sound],
          showdownMoveId: 'growl',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'growl_local',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.opponent,
        ),
      );

      expect(resolved.recipeId, equals(BattleMoveVisualRecipeId.showdownGrowl));
      expect(resolved.usesFallback, isFalse);
    });

    test('direct seeded quick attack recipe wins over generic contact fallback',
        () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'quick_attack_local': _pokemonMove(
          id: 'quick_attack_local',
          category: PokemonMoveCategory.physical,
          target: PokemonMoveTarget.normal,
          showdownMoveId: 'quickattack',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'quick_attack_local',
          category: BattleMoveCategory.physical,
          target: BattleMoveTarget.opponent,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownQuickAttack),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('weather effect maps to weather recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'rain_song': _pokemonMove(
          id: 'rain_song',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.self,
          effects: const <PokemonMoveEffect>[
            PokemonMoveEffect.setWeather(weatherId: 'rain'),
          ],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'rain_song',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.field,
        ),
      );

      expect(resolved.recipeId, equals(BattleMoveVisualRecipeId.weatherRain));
      expect(resolved.usesFallback, isTrue);
    });

    test('set side condition effect maps to reflect recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'mirror_wall': _pokemonMove(
          id: 'mirror_wall',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.allySide,
          effects: const <PokemonMoveEffect>[
            PokemonMoveEffect.setSideCondition(
              targetScope: PokemonMoveEffectTargetScope.allySide,
              conditionId: 'reflect',
            ),
          ],
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'mirror_wall',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.self,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownReflect),
      );
      expect(resolved.usesFallback, isTrue);
    });

    test('waterfall alias resolves to aqua jet recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'waterfall_local': _pokemonMove(
          id: 'waterfall_local',
          type: 'water',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'waterfall',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'waterfall_local',
          type: 'water',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownAquaJet),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('volt tackle alias resolves to wild charge recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'volt_tackle_local': _pokemonMove(
          id: 'volt_tackle_local',
          type: 'electric',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'volttackle',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'volt_tackle_local',
          type: 'electric',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownWildCharge),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('jaw lock alias resolves to crunch recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'jaw_lock_local': _pokemonMove(
          id: 'jaw_lock_local',
          showdownMoveId: 'jawlock',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(_battleMove(id: 'jaw_lock_local'));

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownCrunch),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('nuzzle alias resolves to spark recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'nuzzle_local': _pokemonMove(
          id: 'nuzzle_local',
          type: 'electric',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'nuzzle',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'nuzzle_local',
          type: 'electric',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownSpark),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('tera blast psychic alias resolves to psychic recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'tera_blast_psychic_local': _pokemonMove(
          id: 'tera_blast_psychic_local',
          category: PokemonMoveCategory.special,
          type: 'psychic',
          showdownMoveId: 'terablastpsychic',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'tera_blast_psychic_local',
          type: 'psychic',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownPsychic),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('ceaseless edge resolves to the night slash family recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'ceaseless_edge_local': _pokemonMove(
          id: 'ceaseless_edge_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'ceaselessedge',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'ceaseless_edge_local',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownNightSlash),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('behemoth blade alias resolves to smart strike recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'behemoth_blade_local': _pokemonMove(
          id: 'behemoth_blade_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'behemothblade',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'behemoth_blade_local',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownSmartStrike),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('horn attack alias resolves to megahorn recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'horn_attack_local': _pokemonMove(
          id: 'horn_attack_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'hornattack',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'horn_attack_local',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownMegaHorn),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('psyblade alias resolves to psycho cut recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'psy_blade_local': _pokemonMove(
          id: 'psy_blade_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'psyblade',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'psy_blade_local',
          category: BattleMoveCategory.physical,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownPsychoCut),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('mountain gale alias resolves to power gem recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'mountain_gale_local': _pokemonMove(
          id: 'mountain_gale_local',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'mountaingale',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'mountain_gale_local',
          category: BattleMoveCategory.special,
          type: 'rock',
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownPowerGem),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('burning jealousy alias resolves to heat wave recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'burning_jealousy_local': _pokemonMove(
          id: 'burning_jealousy_local',
          category: PokemonMoveCategory.special,
          showdownMoveId: 'burningjealousy',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'burning_jealousy_local',
          category: BattleMoveCategory.special,
          type: 'fire',
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.showdownHeatWave),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('final bespoke seven resolve without falling back', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'splash_local': _pokemonMove(
          id: 'splash_local',
          category: PokemonMoveCategory.status,
          showdownMoveId: 'splash',
        ),
        'celebrate_local': _pokemonMove(
          id: 'celebrate_local',
          category: PokemonMoveCategory.status,
          showdownMoveId: 'celebrate',
        ),
        'order_up_local': _pokemonMove(
          id: 'order_up_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'orderup',
        ),
        'heart_stamp_local': _pokemonMove(
          id: 'heart_stamp_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'heartstamp',
        ),
        'matcha_gotcha_local': _pokemonMove(
          id: 'matcha_gotcha_local',
          category: PokemonMoveCategory.special,
          type: 'grass',
          showdownMoveId: 'matchagotcha',
        ),
        'present_local': _pokemonMove(
          id: 'present_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'present',
        ),
        'payday_local': _pokemonMove(
          id: 'payday_local',
          category: PokemonMoveCategory.physical,
          showdownMoveId: 'payday',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      const expectations = <({
        String localId,
        String type,
        BattleMoveCategory category,
        BattleMoveVisualRecipeId recipeId,
      })>[
        (
          localId: 'splash_local',
          type: 'water',
          category: BattleMoveCategory.status,
          recipeId: BattleMoveVisualRecipeId.showdownSplash,
        ),
        (
          localId: 'celebrate_local',
          type: 'normal',
          category: BattleMoveCategory.status,
          recipeId: BattleMoveVisualRecipeId.showdownCelebrate,
        ),
        (
          localId: 'order_up_local',
          type: 'dragon',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.showdownOrderUp,
        ),
        (
          localId: 'heart_stamp_local',
          type: 'psychic',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.showdownHeartStamp,
        ),
        (
          localId: 'matcha_gotcha_local',
          type: 'grass',
          category: BattleMoveCategory.special,
          recipeId: BattleMoveVisualRecipeId.showdownMatchaGotcha,
        ),
        (
          localId: 'present_local',
          type: 'normal',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.showdownPresent,
        ),
        (
          localId: 'payday_local',
          type: 'normal',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.showdownPayDay,
        ),
      ];

      for (final entry in expectations) {
        final resolved = resolver.resolve(
          _battleMove(
            id: entry.localId,
            type: entry.type,
            category: entry.category,
          ),
        );

        expect(resolved.recipeId, equals(entry.recipeId),
            reason: entry.localId);
        expect(resolved.usesFallback, isFalse, reason: entry.localId);
      }
    });

    test('unsupported move still resolves to a safe fallback', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'mystic_fire_orb': _pokemonMove(
          id: 'mystic_fire_orb',
          type: 'fire',
          category: PokemonMoveCategory.special,
          engineSupportLevel: PokemonMoveEngineSupportLevel.catalogOnly,
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'mystic_fire_orb',
          type: 'fire',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.genericProjectileFire),
      );
      expect(resolved.usesFallback, isTrue);
    });

    test('missing move catalog entry does not crash', () {
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
      );

      final resolved = resolver.resolve(
        _battleMove(
          id: 'raw_battle_move',
          type: 'water',
          category: BattleMoveCategory.special,
        ),
      );

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.genericProjectileWater),
      );
      expect(resolved.canonicalMove, isNull);
      expect(resolved.usesFallback, isTrue);
    });

    test('unknown move becomes noAnimation or generic fallback', () {
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
      );

      final resolved = resolver.resolve(
        _battleMove(
          id: 'mystery_status',
          type: 'unknown',
          category: BattleMoveCategory.status,
          target: BattleMoveTarget.field,
        ),
      );

      expect(resolved.recipeId, equals(BattleMoveVisualRecipeId.noAnimation));
      expect(resolved.usesFallback, isTrue);
    });
  });
}
