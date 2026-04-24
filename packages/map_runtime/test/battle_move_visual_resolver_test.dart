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
  String? sdkMoveId,
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
    sourceRefs: PokemonMoveSourceRefs(showdownMoveId: sdkMoveId),
  );
}

void _expectExactRmxp(BattleResolvedMoveVisual resolved) {
  expect(
    resolved.recipeId,
    equals(BattleMoveVisualRecipeId.sdkRmxpMoveAnimation),
  );
  expect(resolved.visualSource, equals(BattleMoveVisualSource.exactRmxp));
  expect(resolved.usesFallback, isFalse);
  expect(
    resolved.rmxpUserAnimationId != null ||
        resolved.rmxpTargetAnimationId != null,
    isTrue,
  );
}

void _expectExactRuby(
  BattleResolvedMoveVisual resolved,
  BattleMoveVisualRecipeId recipeId,
) {
  expect(resolved.recipeId, equals(recipeId));
  expect(resolved.visualSource, equals(BattleMoveVisualSource.exactRuby));
  expect(resolved.usesFallback, isFalse);
}

void _expectAdapted(
  BattleResolvedMoveVisual resolved,
  BattleMoveVisualRecipeId recipeId,
) {
  expect(resolved.recipeId, equals(recipeId));
  expect(resolved.visualSource, equals(BattleMoveVisualSource.adapted));
  expect(resolved.usesFallback, isFalse);
  expect(
    resolved.rmxpUserAnimationId != null ||
        resolved.rmxpTargetAnimationId != null,
    isFalse,
  );
}

void main() {
  group('BattleMoveVisualResolver', () {
    test('uses canonical sdkMoveId when available', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'thunderbolt_local': _pokemonMove(
          id: 'thunderbolt_local',
          type: 'electric',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'thunderbolt',
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

      expect(resolved.sdkMoveId, equals('thunderbolt'));
      _expectExactRmxp(resolved);
    });

    test('critical RMXP mapped moves stay exact RMXP instead of SDK family',
        () {
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          for (final moveId in const <String>[
            'swift',
            'thundershock',
            'shockwave',
            'electroball',
            'watergun',
            'megapunch',
          ])
            moveId: _pokemonMove(id: moveId, sdkMoveId: moveId),
        }),
      );

      for (final moveId in const <String>[
        'swift',
        'thundershock',
        'shockwave',
        'electroball',
        'watergun',
        'megapunch',
      ]) {
        final resolved = resolver.resolve(_battleMove(id: moveId));

        _expectExactRmxp(resolved);
      }
    });

    test('water gun and mega punch keep their SDK RMXP animation ids', () {
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          'watergun': _pokemonMove(id: 'watergun', sdkMoveId: 'watergun'),
          'megapunch': _pokemonMove(id: 'megapunch', sdkMoveId: 'megapunch'),
        }),
      );

      final waterGun = resolver.resolve(_battleMove(id: 'watergun'));
      final megaPunch = resolver.resolve(_battleMove(id: 'megapunch'));

      _expectExactRmxp(waterGun);
      expect(waterGun.sdkNumericMoveId, equals(55));
      expect(waterGun.rmxpUserAnimationId, isNull);
      expect(waterGun.rmxpTargetAnimationId, equals(55));

      _expectExactRmxp(megaPunch);
      expect(megaPunch.sdkNumericMoveId, equals(5));
      expect(megaPunch.rmxpUserAnimationId, equals(440));
      expect(megaPunch.rmxpTargetAnimationId, equals(5));
    });

    test('critical Ruby overrides stay exact Ruby before RMXP mappings', () {
      final expectedRecipes = <String, BattleMoveVisualRecipeId>{
        'thunderwave': BattleMoveVisualRecipeId.sdkExactThunderWave,
        'leechseed': BattleMoveVisualRecipeId.sdkExactLeechSeed,
        'recover': BattleMoveVisualRecipeId.sdkExactRecover,
        'poisonpowder': BattleMoveVisualRecipeId.sdkExactPoisonPowder,
        'sleeppowder': BattleMoveVisualRecipeId.sdkExactSleepPowder,
        'stunspore': BattleMoveVisualRecipeId.sdkExactStunSpore,
        'karatechop': BattleMoveVisualRecipeId.sdkExactKarateChop,
      };
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          for (final moveId in expectedRecipes.keys)
            moveId: _pokemonMove(id: moveId, sdkMoveId: moveId),
        }),
      );

      for (final entry in expectedRecipes.entries) {
        final resolved = resolver.resolve(_battleMove(id: entry.key));

        _expectExactRuby(resolved, entry.value);
      }
    });

    test('retuned numeric sdk variants resolve as adapted visuals', () {
      const expectedRecipes = <String, BattleMoveVisualRecipeId>{
        'aciddownpour2': BattleMoveVisualRecipeId.sdkSludgeBomb,
        'alloutpummeling2': BattleMoveVisualRecipeId.sdkCloseCombat,
        'blackholeeclipse2': BattleMoveVisualRecipeId.sdkHex,
        'bloomdoom2': BattleMoveVisualRecipeId.sdkMagicalLeaf,
        'breakneckblitz2': BattleMoveVisualRecipeId.sdkGigaImpact,
        'continentalcrush2': BattleMoveVisualRecipeId.sdkRockSlide,
        'corkscrewcrash2': BattleMoveVisualRecipeId.sdkSmartStrike,
        'devastatingdrake2': BattleMoveVisualRecipeId.sdkDragonPulse,
        'gigavolthavoc2': BattleMoveVisualRecipeId.sdkThunderbolt,
        'hydrovortex2': BattleMoveVisualRecipeId.sdkOriginPulse,
        'infernooverdrive2': BattleMoveVisualRecipeId.sdkFireBlast,
        'neverendingnightmare2': BattleMoveVisualRecipeId.sdkHex,
        'savagespinout2': BattleMoveVisualRecipeId.sdkElectroweb,
        'shatteredpsyche2': BattleMoveVisualRecipeId.sdkPsychic,
        'subzeroslammer2': BattleMoveVisualRecipeId.sdkBlizzard,
        'supersonicskystrike2': BattleMoveVisualRecipeId.sdkHurricane,
        'tectonicrage2': BattleMoveVisualRecipeId.sdkEarthquake,
        'twinkletackle2': BattleMoveVisualRecipeId.sdkPlayRough,
        's10000000voltthunderbolt': BattleMoveVisualRecipeId.sdkThunderbolt,
      };
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          for (final moveId in expectedRecipes.keys)
            moveId: _pokemonMove(id: moveId, sdkMoveId: moveId),
          '10000000voltthunderbolt': _pokemonMove(
            id: '10000000voltthunderbolt',
            sdkMoveId: '10000000voltthunderbolt',
          ),
        }),
      );

      for (final entry in expectedRecipes.entries) {
        final resolved = resolver.resolve(_battleMove(id: entry.key));

        _expectAdapted(resolved, entry.value);
      }

      final legacyAlias = resolver.resolve(
        _battleMove(id: '10000000voltthunderbolt'),
      );
      _expectAdapted(legacyAlias, BattleMoveVisualRecipeId.sdkThunderbolt);
      expect(
        legacyAlias.recipeId,
        isNot(BattleMoveVisualRecipeId.sdkTriAttack),
      );
    });

    test('sdk ids without RMXP mappings resolve as adapted, not exact', () {
      const expectedRecipes = <String, BattleMoveVisualRecipeId>{
        'aciddownpour': BattleMoveVisualRecipeId.sdkSludgeBomb,
        'alloutpummeling': BattleMoveVisualRecipeId.sdkCloseCombat,
        'blackholeeclipse': BattleMoveVisualRecipeId.sdkHex,
        'bloomdoom': BattleMoveVisualRecipeId.sdkMagicalLeaf,
        'breakneckblitz': BattleMoveVisualRecipeId.sdkGigaImpact,
        'catastropika': BattleMoveVisualRecipeId.sdkThunderbolt,
        'clangoroussoulblaze': BattleMoveVisualRecipeId.sdkClangingScales,
        'continentalcrush': BattleMoveVisualRecipeId.sdkRockSlide,
        'corkscrewcrash': BattleMoveVisualRecipeId.sdkSmartStrike,
        'devastatingdrake': BattleMoveVisualRecipeId.sdkDragonPulse,
        'extremeevoboost': BattleMoveVisualRecipeId.sdkQuiverDance,
        'genesissupernova': BattleMoveVisualRecipeId.sdkPsychoBoost,
        'gigavolthavoc': BattleMoveVisualRecipeId.sdkThunderbolt,
        'guardianofalola': BattleMoveVisualRecipeId.sdkMoonBlast,
        'hydrovortex': BattleMoveVisualRecipeId.sdkOriginPulse,
        'infernooverdrive': BattleMoveVisualRecipeId.sdkFireBlast,
        'letssnuggleforever': BattleMoveVisualRecipeId.sdkPlayRough,
        'lightthatburnsthesky': BattleMoveVisualRecipeId.sdkFireBlast,
        'maliciousmoonsault': BattleMoveVisualRecipeId.sdkBodySlam,
        'menacingmoonrazemaelstrom': BattleMoveVisualRecipeId.sdkHex,
        'mindblown': BattleMoveVisualRecipeId.sdkExplosion,
        'neverendingnightmare': BattleMoveVisualRecipeId.sdkHex,
        'oceanicoperetta': BattleMoveVisualRecipeId.sdkOriginPulse,
        'photongeyser': BattleMoveVisualRecipeId.sdkPsychic,
        'plasmafists': BattleMoveVisualRecipeId.sdkThunderPunch,
        'pulverizingpancake': BattleMoveVisualRecipeId.sdkBodySlam,
        'savagespinout': BattleMoveVisualRecipeId.sdkElectroweb,
        'searingsunrazesmash': BattleMoveVisualRecipeId.sdkFlareBlitz,
        'shatteredpsyche': BattleMoveVisualRecipeId.sdkPsychic,
        'sinisterarrowraid': BattleMoveVisualRecipeId.sdkNightSlash,
        'soulstealing7starstrike': BattleMoveVisualRecipeId.sdkHex,
        'splinteredstormshards': BattleMoveVisualRecipeId.sdkRockSlide,
        'stokedsparksurfer': BattleMoveVisualRecipeId.sdkThunderbolt,
        'subzeroslammer': BattleMoveVisualRecipeId.sdkBlizzard,
        'supersonicskystrike': BattleMoveVisualRecipeId.sdkHurricane,
        'tectonicrage': BattleMoveVisualRecipeId.sdkEarthquake,
        'twinkletackle': BattleMoveVisualRecipeId.sdkPlayRough,
      };
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          for (final moveId in expectedRecipes.keys)
            moveId: _pokemonMove(id: moveId, sdkMoveId: moveId),
        }),
      );

      for (final entry in expectedRecipes.entries) {
        final resolved = resolver.resolve(_battleMove(id: entry.key));

        _expectAdapted(resolved, entry.value);
      }
    });

    test('aliases into exact Ruby recipes do not claim exact Ruby', () {
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          for (final moveId in const <String>[
            'branchpoke',
            'electrify',
            'razorwind',
            'synthesis',
          ])
            moveId: _pokemonMove(id: moveId, sdkMoveId: moveId),
        }),
      );

      final branchPoke = resolver.resolve(_battleMove(id: 'branchpoke'));
      expect(
        branchPoke.recipeId,
        equals(BattleMoveVisualRecipeId.sdkExactVineWhip),
      );
      expect(branchPoke.visualSource, equals(BattleMoveVisualSource.sdkFamily));
      expect(branchPoke.usesFallback, isFalse);

      for (final moveId in const <String>[
        'electrify',
        'razorwind',
        'synthesis',
      ]) {
        _expectExactRmxp(resolver.resolve(_battleMove(id: moveId)));
      }
    });

    test('aliases into adapted Z and Max routes inherit adapted source', () {
      final expectedRecipes = <String, BattleMoveVisualRecipeId>{
        'maxlightning': BattleMoveVisualRecipeId.sdkThunderbolt,
        'maxphantasm': BattleMoveVisualRecipeId.sdkHex,
        'gmaxvinelash': BattleMoveVisualRecipeId.sdkMagicalLeaf,
        'gmaxdepletion': BattleMoveVisualRecipeId.sdkDragonPulse,
        'maxstrike': BattleMoveVisualRecipeId.sdkGigaImpact,
        'poltergeist': BattleMoveVisualRecipeId.sdkHex,
      };
      final resolver = BattleMoveVisualResolver(
        RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
          for (final moveId in expectedRecipes.keys)
            moveId: _pokemonMove(id: moveId, sdkMoveId: moveId),
        }),
      );

      for (final entry in expectedRecipes.entries) {
        _expectAdapted(
          resolver.resolve(_battleMove(id: entry.key)),
          entry.value,
        );
      }
    });

    test('direct mapping wins over fallback', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'thunderbolt_local': _pokemonMove(
          id: 'thunderbolt_local',
          type: 'electric',
          category: PokemonMoveCategory.special,
          flags: const <PokemonMoveFlag>[PokemonMoveFlag.slicing],
          sdkMoveId: 'thunderbolt',
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

      _expectExactRmxp(resolved);
    });

    test('alias is resolved transitively', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'tidy_up': _pokemonMove(
          id: 'tidy_up',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.self,
          sdkMoveId: 'tidyup',
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
        equals(BattleMoveVisualRecipeId.sdkBulkUp),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('multi-hop sdk alias chain resolves through max move roots', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'storm_bolt_local': _pokemonMove(
          id: 'storm_bolt_local',
          type: 'electric',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'maxlightning',
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

      expect(resolved.sdkMoveId, equals('maxlightning'));
      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.sdkThunderbolt),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('sdk alias roots can land on adapted elemental recipes', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'mist_ball_local': _pokemonMove(
          id: 'mist_ball_local',
          type: 'ice',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'mistball',
        ),
        'searing_shot_local': _pokemonMove(
          id: 'searing_shot_local',
          type: 'fire',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'searingshot',
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

      _expectExactRmxp(mistBall);
      _expectExactRmxp(searingShot);
    });

    test('direct fidelity-wave dark and sound routings resolve cleanly', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'snarl_local': _pokemonMove(
          id: 'snarl_local',
          type: 'dark',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'snarl',
        ),
        'sing_local': _pokemonMove(
          id: 'sing_local',
          category: PokemonMoveCategory.status,
          sdkMoveId: 'sing',
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

      _expectExactRmxp(snarl);
      _expectExactRmxp(sing);
    });

    test('direct fidelity-wave contact and trap routings resolve cleanly', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'fake_out_local': _pokemonMove(
          id: 'fake_out_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'fakeout',
        ),
        'firespin_local': _pokemonMove(
          id: 'firespin_local',
          type: 'fire',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'firespin',
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

      _expectExactRmxp(fakeOut);
      _expectExactRmxp(fireSpin);
    });

    test('second fidelity-wave setup and signature routings resolve cleanly',
        () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'shell_smash_local': _pokemonMove(
          id: 'shell_smash_local',
          category: PokemonMoveCategory.status,
          target: PokemonMoveTarget.self,
          sdkMoveId: 'shellsmash',
        ),
        'waterspout_local': _pokemonMove(
          id: 'waterspout_local',
          type: 'water',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'waterspout',
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

      _expectExactRmxp(shellSmash);
      _expectExactRmxp(waterSpout);
    });

    test('third fidelity-wave finisher routings resolve cleanly', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'fury_wrath_local': _pokemonMove(
          id: 'fury_wrath_local',
          type: 'dark',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'fierywrath',
        ),
        'torque_local': _pokemonMove(
          id: 'torque_local',
          type: 'fairy',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'magicaltorque',
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
        equals(BattleMoveVisualRecipeId.sdkDarkPulse),
      );
      expect(
        magicalTorque.recipeId,
        equals(BattleMoveVisualRecipeId.sdkPlayRough),
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
          sdkMoveId: 'hiddenpower',
        ),
        'guardian_local': _pokemonMove(
          id: 'guardian_local',
          type: 'fairy',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'guardianofalola',
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

      _expectExactRmxp(hiddenPower);
      expect(
        guardian.recipeId,
        equals(BattleMoveVisualRecipeId.sdkMoonBlast),
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
          sdkMoveId: 'watershuriken',
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

      _expectExactRmxp(resolved);
    });

    test('slash resolves to its dedicated sdk slash recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'slash_local': _pokemonMove(
          id: 'slash_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'slash',
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

      _expectExactRmxp(resolved);
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
          sdkMoveId: 'growl',
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

      _expectExactRmxp(resolved);
    });

    test('direct seeded quick attack recipe wins over generic contact fallback',
        () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'quick_attack_local': _pokemonMove(
          id: 'quick_attack_local',
          category: PokemonMoveCategory.physical,
          target: PokemonMoveTarget.normal,
          sdkMoveId: 'quickattack',
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

      _expectExactRmxp(resolved);
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
        equals(BattleMoveVisualRecipeId.sdkReflect),
      );
      expect(resolved.usesFallback, isTrue);
    });

    test('waterfall alias resolves to aqua jet recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'waterfall_local': _pokemonMove(
          id: 'waterfall_local',
          type: 'water',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'waterfall',
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

      _expectExactRmxp(resolved);
    });

    test('volt tackle alias resolves to wild charge recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'volt_tackle_local': _pokemonMove(
          id: 'volt_tackle_local',
          type: 'electric',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'volttackle',
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

      _expectExactRmxp(resolved);
    });

    test('jaw lock alias resolves to crunch recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'jaw_lock_local': _pokemonMove(
          id: 'jaw_lock_local',
          sdkMoveId: 'jawlock',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(_battleMove(id: 'jaw_lock_local'));

      expect(
        resolved.recipeId,
        equals(BattleMoveVisualRecipeId.sdkCrunch),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('nuzzle alias resolves to spark recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'nuzzle_local': _pokemonMove(
          id: 'nuzzle_local',
          type: 'electric',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'nuzzle',
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

      _expectExactRmxp(resolved);
    });

    test('tera blast psychic alias resolves to psychic recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'tera_blast_psychic_local': _pokemonMove(
          id: 'tera_blast_psychic_local',
          category: PokemonMoveCategory.special,
          type: 'psychic',
          sdkMoveId: 'terablastpsychic',
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
        equals(BattleMoveVisualRecipeId.sdkPsychic),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('ceaseless edge resolves to the night slash family recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'ceaseless_edge_local': _pokemonMove(
          id: 'ceaseless_edge_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'ceaselessedge',
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
        equals(BattleMoveVisualRecipeId.sdkNightSlash),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('behemoth blade alias resolves to smart strike recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'behemoth_blade_local': _pokemonMove(
          id: 'behemoth_blade_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'behemothblade',
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
        equals(BattleMoveVisualRecipeId.sdkSmartStrike),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('horn attack alias resolves to megahorn recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'horn_attack_local': _pokemonMove(
          id: 'horn_attack_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'hornattack',
        ),
      });
      final resolver = BattleMoveVisualResolver(catalog);

      final resolved = resolver.resolve(
        _battleMove(
          id: 'horn_attack_local',
          category: BattleMoveCategory.physical,
        ),
      );

      _expectExactRmxp(resolved);
    });

    test('psyblade alias resolves to psycho cut recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'psy_blade_local': _pokemonMove(
          id: 'psy_blade_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'psyblade',
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
        equals(BattleMoveVisualRecipeId.sdkPsychoCut),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('mountain gale alias resolves to power gem recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'mountain_gale_local': _pokemonMove(
          id: 'mountain_gale_local',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'mountaingale',
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
        equals(BattleMoveVisualRecipeId.sdkPowerGem),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('burning jealousy alias resolves to heat wave recipe', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'burning_jealousy_local': _pokemonMove(
          id: 'burning_jealousy_local',
          category: PokemonMoveCategory.special,
          sdkMoveId: 'burningjealousy',
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
        equals(BattleMoveVisualRecipeId.sdkHeatWave),
      );
      expect(resolved.usesFallback, isFalse);
    });

    test('final bespoke seven resolve without falling back', () {
      final catalog = RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
        'splash_local': _pokemonMove(
          id: 'splash_local',
          category: PokemonMoveCategory.status,
          sdkMoveId: 'splash',
        ),
        'celebrate_local': _pokemonMove(
          id: 'celebrate_local',
          category: PokemonMoveCategory.status,
          sdkMoveId: 'celebrate',
        ),
        'order_up_local': _pokemonMove(
          id: 'order_up_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'orderup',
        ),
        'heart_stamp_local': _pokemonMove(
          id: 'heart_stamp_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'heartstamp',
        ),
        'matcha_gotcha_local': _pokemonMove(
          id: 'matcha_gotcha_local',
          category: PokemonMoveCategory.special,
          type: 'grass',
          sdkMoveId: 'matchagotcha',
        ),
        'present_local': _pokemonMove(
          id: 'present_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'present',
        ),
        'payday_local': _pokemonMove(
          id: 'payday_local',
          category: PokemonMoveCategory.physical,
          sdkMoveId: 'payday',
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
          recipeId: BattleMoveVisualRecipeId.sdkSplash,
        ),
        (
          localId: 'celebrate_local',
          type: 'normal',
          category: BattleMoveCategory.status,
          recipeId: BattleMoveVisualRecipeId.sdkCelebrate,
        ),
        (
          localId: 'order_up_local',
          type: 'dragon',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.sdkOrderUp,
        ),
        (
          localId: 'heart_stamp_local',
          type: 'psychic',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.sdkHeartStamp,
        ),
        (
          localId: 'matcha_gotcha_local',
          type: 'grass',
          category: BattleMoveCategory.special,
          recipeId: BattleMoveVisualRecipeId.sdkMatchaGotcha,
        ),
        (
          localId: 'present_local',
          type: 'normal',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.sdkPresent,
        ),
        (
          localId: 'payday_local',
          type: 'normal',
          category: BattleMoveCategory.physical,
          recipeId: BattleMoveVisualRecipeId.sdkPayDay,
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

        if (resolved.visualSource == BattleMoveVisualSource.exactRmxp) {
          _expectExactRmxp(resolved);
        } else {
          expect(resolved.recipeId, equals(entry.recipeId),
              reason: entry.localId);
          expect(resolved.usesFallback, isFalse, reason: entry.localId);
        }
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
