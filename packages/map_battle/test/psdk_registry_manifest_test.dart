import 'dart:io';

import 'package:map_battle/src/data/generated/psdk_ability_effect_manifest.dart';
import 'package:map_battle/src/data/generated/psdk_item_effect_manifest.dart';
import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
import 'package:map_battle/src/data/psdk_fight_parity_audit.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move registry manifest', () {
    test('tracks the currently wired Dart move behaviors honestly', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(
          byMethod.keys,
          containsAll(<String>[
            's_basic',
            's_status',
            's_protect',
          ]));
      expect(byMethod['s_basic']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_2turns']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_2turns']!.dartBehavior,
        'StaticBasicMoveRegistry.s_2turns',
      );
      expect(
        byMethod['s_2turns']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.actionOrder,
          PsdkMoveDependency.weather,
          PsdkMoveDependency.item,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_status']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_protect']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_stat']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_self_stat']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_self_status']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_protect']!.rubyClass, 'Protect');
      expect(byMethod['s_protect']!.dartBehavior, contains('s_protect'));
      expect(
        byMethod['s_status']!.dartBehavior,
        'StatusStatMoveBehavior.status',
      );
      expect(byMethod['s_status']!.dependencies, isEmpty);
      expect(
        byMethod['s_stat']!.dartBehavior,
        'StatusStatMoveBehavior.stat',
      );
      expect(byMethod['s_stat']!.dependencies, isEmpty);
      expect(
        byMethod['s_self_stat']!.dartBehavior,
        'StatusStatMoveBehavior.selfStat',
      );
      expect(byMethod['s_self_stat']!.dependencies, isEmpty);
      expect(
        byMethod['s_self_status']!.dartBehavior,
        'StatusStatMoveBehavior.selfStatus',
      );
      expect(byMethod['s_self_status']!.dependencies, isEmpty);
    });

    test('ported methods require source, behavior, and test evidence', () {
      final psdkBattleRoot =
          Directory('../../pokemonsdk-development/scripts/5 Battle');
      final testCorpus = _readTestCorpus(Directory('test'));

      for (final entry in psdkMoveRegistryManifest
          .where((entry) => entry.status == PsdkPortStatus.ported)) {
        expect(entry.rubyPath, isNotEmpty, reason: entry.battleEngineMethod);
        expect(entry.dartBehavior, isNotEmpty,
            reason: entry.battleEngineMethod);
        expect(
          entry.dartBehavior,
          isNot(contains('partial')),
          reason: entry.battleEngineMethod,
        );
        expect(
          File('${psdkBattleRoot.path}/${entry.rubyPath}').existsSync(),
          isTrue,
          reason: '${entry.battleEngineMethod} -> ${entry.rubyPath}',
        );
        expect(
          _hasMoveEvidence(entry, testCorpus),
          isTrue,
          reason: entry.battleEngineMethod,
        );
      }
    });

    test('effect manifests can distinguish ported from partial entries', () {
      expect(
        PsdkAbilityPortStatus.values.map((status) => status.name),
        contains('ported'),
      );
      expect(
        PsdkItemPortStatus.values.map((status) => status.name),
        contains('ported'),
      );

      for (final entry in psdkAbilityEffectManifest.where(
        (entry) => entry.status == PsdkAbilityPortStatus.ported,
      )) {
        expect(entry.rubyPath, isNotEmpty, reason: entry.abilityId);
        expect(_psdkSourceExists(entry.rubyPath), isTrue,
            reason: entry.abilityId);
        expect(entry.dartEffect, isNotNull, reason: entry.abilityId);
      }
      for (final entry in psdkItemEffectManifest.where(
        (entry) => entry.status == PsdkItemPortStatus.ported,
      )) {
        expect(entry.rubyPath, isNotEmpty, reason: entry.itemId);
        expect(_psdkSourceExists(entry.rubyPath), isTrue, reason: entry.itemId);
        expect(entry.dartEffect, isNotNull, reason: entry.itemId);
      }
    });

    test('ported PSDK effects require source, Dart effect, and evidence',
        () async {
      final testCorpus = _readTestCorpus(Directory('test'));
      final fixtureCorpus = _readFixtureCorpus(
        Directory('test/fixtures/psdk_golden'),
      );
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final families = effectEntries.map((entry) => entry.family).toSet();

      expect(
        families,
        containsAll(<String>[
          'ability',
          'item',
          'move',
          'status',
          'field',
          'mechanics',
        ]),
      );

      for (final entry in effectEntries
          .where((entry) => entry.status == PsdkPortStatus.ported)) {
        expect(entry.rubyPath, isNotEmpty, reason: entry.effectName);
        expect(_psdkSourceExists(entry.rubyPath), isTrue,
            reason: entry.effectName);
        expect(
          _hasEffectEvidence(entry, testCorpus, fixtureCorpus),
          isTrue,
          reason: entry.effectName,
        );
      }
    });

    test('effect parity mirrors ported ability and item manifests', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      expect(
        [
          for (final effectName in <String>[
            'ArenaTrap',
            'Imposter',
            'MagnetPull',
            'ShadowTag',
          ])
            byFamilyAndName['ability:$effectName']?.status,
        ],
        everyElement(PsdkPortStatus.ported),
      );
      expect(
        byFamilyAndName['item:Leftovers']?.status,
        PsdkPortStatus.ported,
      );
      expect(
        byFamilyAndName['item:BlackSludge']?.status,
        PsdkPortStatus.ported,
      );
      expect(
        byFamilyAndName['item:AirBalloon']?.status,
        PsdkPortStatus.ported,
      );
    });

    test('effect parity promotes Lot 98 ability damage type accuracy batch',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'BoostingMoveType',
        'EarthEater',
        'FlashFire',
        'IronFist',
        'LightningRod',
        'MotorDrive',
        'PunkRock',
        'Reckless',
        'RoughSkin',
        'SapSipper',
        'Sharpness',
        'StormDrain',
        'Technician',
        'ToughClaws',
        'VoltAbsorb',
        'WaterAbsorb',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 99 ability status selection batch',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Immunity',
        'Insomnia',
        'Limber',
        'MagmaArmor',
        'NonVolatileStatusImmunityBase',
        'Soundproof',
        'WaterVeil',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 100 ability switch residual batch',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Drizzle',
        'Drought',
        'DrySkin',
        'ElectricSurge',
        'GrassySurge',
        'Intimidate',
        'MistySurge',
        'PsychicSurge',
        'RainDish',
        'SandStream',
        'SnowWarning',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 102 passive item modifier batch',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'AssaultVest',
        'AttackMultiplier',
        'ChoiceBand',
        'ChoiceItemMultiplier',
        'ChoiceScarf',
        'ChoiceSpecs',
        'DeepSeaScale',
        'DeepSeaTooth',
        'DefenseMultiplier',
        'ExpertBelt',
        'LightBall',
        'MetalPowder',
        'QuickPowder',
        'ThickClub',
      ]) {
        expect(
          byFamilyAndName['item:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 103 active item trigger batch', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'AirBalloon',
        'Apicot',
        'BerryJuice',
        'Cheri',
        'Chesto',
        'Ganlon',
        'HpTriggeredStatBerries',
        'LifeOrb',
        'LumBerry',
        'Pecha',
        'PersimBerry',
        'Petaya',
        'Rawst',
        'Salac',
        'Starf',
        'StatusBerry',
        'MentalHerb',
      ]) {
        expect(
          byFamilyAndName['item:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
      expect(
        byFamilyAndName['item:ConfusingBerries']?.status,
        PsdkPortStatus.ported,
      );
    });

    test('effect parity promotes Lot 249 existing item modifier families',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'BasePowerMultiplier',
        'BigRoot',
        'Gems',
        'HalfSpeed',
        'ShedShell',
      ]) {
        expect(
          byFamilyAndName['item:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 250 reactive held item effects', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'AbsorbBulb',
        'CellBattery',
        'LuminousMoss',
        'MirrorHerb',
        'RockyHelmet',
        'ShellBell',
        'Snowball',
        'ThroatSpray',
        'WeaknessPolicy',
      ]) {
        expect(
          byFamilyAndName['item:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 253 passive ability effects', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'AngerPoint',
        'SuctionCups',
        'TangledFeet',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 254 switch and flinch ability effects',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Anticipation',
        'Pressure',
        'ScreenCleaner',
        'Stench',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 255 Truant and Unnerve ability effects',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Truant',
        'Unnerve',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
      expect(
        byFamilyAndName['ability:Electromorphosis']?.status,
        PsdkPortStatus.ported,
      );
      expect(
        byFamilyAndName['ability:WindPower']?.status,
        PsdkPortStatus.ported,
      );
    });

    test('effect parity promotes Lot 261 quick closure ability effects',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'BallFetch',
        'ColorChange',
        'Dancer',
        'WindRider',
      ]) {
        expect(
          byFamilyAndName['ability:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test(
        'effect parity promotes Cotton Down and scopes Mirror Armor reflection',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      expect(
        byFamilyAndName['ability:CottonDown']?.status,
        PsdkPortStatus.ported,
      );
      expect(
        byFamilyAndName['ability:MirrorArmor']?.status,
        PsdkPortStatus.partial,
      );
    });

    test('effect parity promotes exact major status lifecycle effects',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Asleep',
        'Burn',
        'Frozen',
        'Paralysis',
        'Poison',
        'Toxic',
      ]) {
        expect(
          byFamilyAndName['status:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
      expect(byFamilyAndName['status:Status']?.status, PsdkPortStatus.ported);
    });

    test('effect parity promotes selection lock move effects', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Disable',
        'Embargo',
        'Encore',
        'HealBlock',
        'Imprison',
        'Taunt',
        'ThroatChop',
        'Torment',
      ]) {
        expect(
          byFamilyAndName['move:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 94 protection and redirection effects',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'BanefulBunker',
        'BurningBulwark',
        'CenterOfAttention',
        'Endure',
        'KingsShield',
        'MagicCoat',
        'Obstruct',
        'Protect',
        'SilkTrap',
        'Snatch',
        'Snatched',
        'SpikyShield',
      ]) {
        expect(
          byFamilyAndName['move:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes pre-attack preparation effects', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      expect(
        byFamilyAndName['move:BeakBlast']?.status,
        PsdkPortStatus.ported,
      );
      expect(
        byFamilyAndName['move:ShellTrap']?.status,
        PsdkPortStatus.ported,
      );
    });

    test('effect parity reconciles implemented move effect hooks', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'BatonPass',
        'CantSwitch',
        'ChangeType',
        'Confusion',
        'DestinyBond',
        'FutureSight',
        'FuryCutter',
        'Grudge',
        'HealingWish',
        'Instruct',
        'IonDeluge',
        'LunarDance',
        'Mark',
        'Rainbow',
        'ShedTail',
        'SleepPrevention',
        'SmackDown',
        'WonderRoom',
      ]) {
        expect(
          byFamilyAndName['move:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }

      for (final effectName in <String>[
        'Bestow',
        'Bide',
        'EchoedVoice',
        'Rollout',
        'Roost',
      ]) {
        expect(
          byFamilyAndName['move:$effectName']?.status,
          PsdkPortStatus.partial,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 95 field weather terrain and side effects',
        () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'Electric',
        'FieldTerrain',
        'Fog',
        'Grassy',
        'Hail',
        'Hardrain',
        'Hardsun',
        'Misty',
        'Psychic',
        'Rain',
        'Sandstorm',
        'Snow',
        'StrongWinds',
        'Sunny',
        'Weather',
      ]) {
        expect(
          byFamilyAndName['field:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('effect parity promotes Lot 104 generic mechanics classes', () async {
      final effectEntries = await loadPsdkEffectParityEntries(
        Directory('../../pokemonsdk-development/scripts/5 Battle'),
      );
      final byFamilyAndName = {
        for (final entry in effectEntries)
          '${entry.family}:${entry.effectName}': entry,
      };

      for (final effectName in <String>[
        'EffectBase',
        'EffectsHandler',
        'PokemonTiedEffectBase',
        'PositionTiedEffectBase',
      ]) {
        expect(
          byFamilyAndName['mechanics:$effectName']?.status,
          PsdkPortStatus.ported,
          reason: effectName,
        );
      }
    });

    test('tracks the fixed-damage and multi-hit slices', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_fixed_damage']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_hp_eq_level']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_psywave']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_super_fang']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_2hits']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_3hits']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_multi_hit']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_multi_hit']!.dependencies, isEmpty);
      expect(byMethod['s_double_iron_bash']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_double_iron_bash']!.dartBehavior,
        'MultiHitMoveBehavior.doubleIronBash',
      );
      expect(byMethod['s_triple_kick']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_triple_kick']!.dartBehavior,
        'MultiHitMoveBehavior.tripleKick',
      );
      expect(
        byMethod['s_triple_kick']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.ability,
          PsdkMoveDependency.item,
          PsdkMoveDependency.history,
        ]),
      );
      expect(byMethod['s_population_bomb']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_population_bomb']!.dartBehavior,
        'MultiHitMoveBehavior.populationBomb',
      );
      expect(
        byMethod['s_population_bomb']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.ability,
          PsdkMoveDependency.item,
        ]),
      );
      expect(byMethod['s_water_shuriken']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_water_shuriken']!.dartBehavior,
        'MultiHitMoveBehavior.waterShuriken',
      );
      expect(byMethod['s_water_shuriken']!.dependencies, isEmpty);
      expect(byMethod['s_scale_shot']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_scale_shot']!.dartBehavior,
        'MultiHitMoveBehavior.scaleShot',
      );
      expect(byMethod['s_beat_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_beat_up']!.dartBehavior,
        'StaticBasicMoveRegistry.s_beat_up',
      );
    });

    test('tracks the Lot 16 variable-power and status-damage slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_brine']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_eruption']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_flail']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_wring_out']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_hard_press']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_electro_ball']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_gyro_ball']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_facade']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_infernal_parade']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_bitter_malice']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_return']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_return']!.dartBehavior,
        'VariablePowerMoveBehavior.returnMove',
      );
      expect(byMethod['s_frustration']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_frustration']!.dartBehavior,
        'VariablePowerMoveBehavior.frustration',
      );
      expect(byMethod['s_venoshock']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_hex']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_low_kick']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_low_kick']!.dartBehavior,
        'WeightPowerMoveBehavior.lowKick',
      );
      expect(byMethod['s_heavy_slam']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_heavy_slam']!.dartBehavior,
        'WeightPowerMoveBehavior.heavySlam',
      );
    });

    test('tracks the Lot 16 custom stat-source slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      for (final entry in <({
        String method,
        String behavior,
        List<PsdkMoveDependency> dependencies,
      })>[
        (
          method: 's_body_press',
          behavior: 'CustomStatSourceMoveBehavior.bodyPress',
          dependencies: <PsdkMoveDependency>[
            PsdkMoveDependency.handlerDamage,
            PsdkMoveDependency.ability,
            PsdkMoveDependency.item,
          ],
        ),
        (
          method: 's_foul_play',
          behavior: 'CustomStatSourceMoveBehavior.foulPlay',
          dependencies: <PsdkMoveDependency>[
            PsdkMoveDependency.handlerDamage,
            PsdkMoveDependency.ability,
            PsdkMoveDependency.item,
          ],
        ),
        (
          method: 's_psyshock',
          behavior: 'CustomStatSourceMoveBehavior.psyshock',
          dependencies: <PsdkMoveDependency>[
            PsdkMoveDependency.handlerDamage,
            PsdkMoveDependency.ability,
            PsdkMoveDependency.item,
          ],
        ),
        (
          method: 's_custom_stats_based',
          behavior: 'CustomStatSourceMoveBehavior.customStatsBased',
          dependencies: <PsdkMoveDependency>[
            PsdkMoveDependency.handlerDamage,
            PsdkMoveDependency.ability,
            PsdkMoveDependency.item,
          ],
        ),
        (
          method: 's_sacred_sword',
          behavior: 'CustomStatSourceMoveBehavior.sacredSword',
          dependencies: <PsdkMoveDependency>[
            PsdkMoveDependency.handlerDamage,
            PsdkMoveDependency.effects,
          ],
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
        expect(
          byMethod[entry.method]!.dependencies,
          containsAll(entry.dependencies),
        );
      }
    });

    test('tracks the Lot 18 basic damage specialization slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_a_fang']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_a_fang']!.dartBehavior,
        'BasicDamageSpecializationMoveBehavior.fangs',
      );
      expect(byMethod['s_false_swipe']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_false_swipe']!.dartBehavior,
        'BasicDamageSpecializationMoveBehavior.falseSwipe',
      );
      expect(byMethod['s_full_crit']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_full_crit']!.dartBehavior,
        'BasicDamageSpecializationMoveBehavior.fullCrit',
      );
      expect(byMethod['s_gigaton_hammer']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_gigaton_hammer']!.dartBehavior,
        'ForcedActionMoveBehavior.gigatonHammer',
      );
      expect(byMethod['s_outrage']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_outrage']!.dartBehavior,
        'ForcedActionMoveBehavior.outrage',
      );
      expect(byMethod['s_thrash']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_thrash']!.dartBehavior,
        'ForcedActionMoveBehavior.thrash',
      );
      expect(byMethod['s_uproar']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_uproar']!.dartBehavior,
        'ForcedActionMoveBehavior.uproar',
      );
      expect(byMethod['s_camouflage']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_camouflage']!.dartBehavior,
        'FieldLocationMoveBehavior.camouflage',
      );
      expect(byMethod['s_nature_power']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_nature_power']!.dartBehavior,
        'FieldLocationMoveBehavior.naturePower',
      );
      expect(byMethod['s_pledge']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_pledge']!.dartBehavior,
        'FieldLocationMoveBehavior.pledge',
      );
      expect(byMethod['s_secret_power']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_secret_power']!.dartBehavior,
        'FieldLocationMoveBehavior.secretPower',
      );
      expect(byMethod['s_synchronoise']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_synchronoise']!.dartBehavior,
        'FieldLocationMoveBehavior.synchronoise',
      );
      expect(
        byMethod['s_synchronoise']!.dependencies,
        contains(PsdkMoveDependency.targetingMulti),
      );
      expect(byMethod['s_smack_down']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_smack_down']!.dartBehavior,
        'GroundingMoveBehavior.smackDown',
      );
      expect(byMethod['s_burn_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_burn_up']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.burnUp',
      );
      expect(byMethod['s_alluring_voice']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_alluring_voice']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.alluringVoice',
      );
      expect(byMethod['s_burning_jealousy']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_burning_jealousy']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.burningJealousy',
      );
      expect(byMethod['s_incinerate']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_incinerate']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.incinerate',
      );
      expect(byMethod['s_psychic_noise']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_psychic_noise']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.psychicNoise',
      );
      expect(byMethod['s_relic_song']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_relic_song']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.relicSong',
      );
      expect(byMethod['s_salt_cure']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_salt_cure']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.saltCure',
      );
      expect(byMethod['s_syrup_bomb']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_syrup_bomb']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.syrupBomb',
      );
      expect(byMethod['s_tar_shot']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_tar_shot']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.tarShot',
      );
      expect(byMethod['s_throat_chop']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_throat_chop']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.throatChop',
      );
      expect(byMethod['s_tri_attack']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_tri_attack']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.triAttack',
      );
    });

    test('tracks the pre-attack move wave', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_beak_blast']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_beak_blast']!.dartBehavior,
        'PreAttackMoveBehavior.beakBlast',
      );
      expect(byMethod['s_pre_attack_base']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_pre_attack_base']!.dartBehavior,
        'PreAttackMoveBehavior.base',
      );
      expect(byMethod['s_shell_trap']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_shell_trap']!.dartBehavior,
        'PreAttackMoveBehavior.shellTrap',
      );
      expect(byMethod['s_payday']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_payday']!.dartBehavior,
        'StaticBasicMoveRegistry.s_payday',
      );
      expect(byMethod['s_core_enforcer']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_core_enforcer']!.dartBehavior,
        'StaticBasicMoveRegistry.s_core_enforcer',
      );
      expect(byMethod['s_dragon_darts']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_dragon_darts']!.dartBehavior,
        'DragonDartsMoveBehavior',
      );
      expect(byMethod['s_order_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_order_up']!.dartBehavior,
        'StaticBasicMoveRegistry.s_order_up',
      );
      expect(byMethod['s_split_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_split_up']!.dartBehavior,
        'StaticBasicMoveRegistry.s_split_up',
      );
      expect(byMethod['s_flame_burst']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_flame_burst']!.dartBehavior,
        'StaticBasicMoveRegistry.s_flame_burst',
      );
      expect(byMethod['s_fusion_bolt']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_fusion_bolt']!.dartBehavior,
        'StaticBasicMoveRegistry.s_fusion_bolt',
      );
      expect(byMethod['s_fusion_flare']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_fusion_flare']!.dartBehavior,
        'StaticBasicMoveRegistry.s_fusion_flare',
      );
      expect(byMethod['s_flying_press']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_flying_press']!.dartBehavior,
        'StaticBasicMoveRegistry.s_flying_press',
      );
      expect(byMethod['s_aura_wheel']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_aura_wheel']!.dartBehavior,
        'TypeBasedMoveBehavior.auraWheel',
      );
      expect(byMethod['s_hidden_power']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_hidden_power']!.dartBehavior,
        'TypeBasedMoveBehavior.hiddenPower',
      );
      expect(byMethod['s_round']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_round']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.round',
      );
      expect(
        byMethod['s_round']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.actionOrder,
          PsdkMoveDependency.history,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_last_resort']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_last_resort']!.dartBehavior,
        'StaticBasicMoveRegistry.s_last_resort',
      );
      expect(byMethod['s_photon_geyser']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_photon_geyser']!.dartBehavior,
        'StaticBasicMoveRegistry.s_photon_geyser',
      );
      expect(byMethod['s_pollen_puff']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_pollen_puff']!.dartBehavior,
        'StaticBasicMoveRegistry.s_pollen_puff',
      );
      expect(byMethod['s_pursuit']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_pursuit']!.dartBehavior,
        'StaticBasicMoveRegistry.s_pursuit',
      );
      expect(byMethod['s_u_turn']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_u_turn']!.dartBehavior,
        'StaticBasicMoveRegistry.s_u_turn',
      );
      expect(byMethod['s_rage']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_rage']!.dartBehavior,
        'StaticBasicMoveRegistry.s_rage',
      );
      expect(
        byMethod['s_ice_spinner']!.dartBehavior,
        'StaticBasicMoveRegistry.s_ice_spinner',
      );
      expect(byMethod['s_ice_spinner']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_steel_roller']!.dartBehavior,
        'StaticBasicMoveRegistry.s_steel_roller',
      );
      expect(byMethod['s_steel_roller']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_sky_drop']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_jump_kick']!.dartBehavior,
        'StaticBasicMoveRegistry.s_jump_kick',
      );
      expect(byMethod['s_jump_kick']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_sky_drop']!.dartBehavior,
        'StaticBasicMoveRegistry.s_sky_drop',
      );
      expect(byMethod['s_rapid_spin']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_rapid_spin']!.dartBehavior,
        'StaticBasicMoveRegistry.s_rapid_spin',
      );
      expect(byMethod['s_spectral_thief']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_spectral_thief']!.dartBehavior,
        'StaticBasicMoveRegistry.s_spectral_thief',
      );
      expect(byMethod['s_make_it_rain']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_make_it_rain']!.dartBehavior,
        'StaticBasicMoveRegistry.s_make_it_rain',
      );
      expect(byMethod['s_eerie_spell']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_eerie_spell']!.dartBehavior,
        'StaticBasicMoveRegistry.s_eerie_spell',
      );
      expect(byMethod['s_electro_shot']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_electro_shot']!.dartBehavior,
        'StaticBasicMoveRegistry.s_electro_shot',
      );
      expect(byMethod['s_fickle_beam']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_fickle_beam']!.dartBehavior,
        'StaticBasicMoveRegistry.s_fickle_beam',
      );
      expect(byMethod['s_magnitude']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_magnitude']!.dartBehavior,
        'StaticBasicMoveRegistry.s_magnitude',
      );
      expect(byMethod['s_present']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_present']!.dartBehavior,
        'StaticBasicMoveRegistry.s_present',
      );
      expect(byMethod['s_memento']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_memento']!.dartBehavior,
        'StaticBasicMoveRegistry.s_memento',
      );
      expect(byMethod['s_glaive_rush']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_glaive_rush']!.dartBehavior,
        'StaticBasicMoveRegistry.s_glaive_rush',
      );
      expect(byMethod['s_last_respects']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_last_respects']!.dartBehavior,
        'StaticBasicMoveRegistry.s_last_respects',
      );
      expect(byMethod['s_shell_side_arm']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_shell_side_arm']!.dartBehavior,
        'StaticBasicMoveRegistry.s_shell_side_arm',
      );
      expect(byMethod['s_triple_arrows']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_triple_arrows']!.dartBehavior,
        'StaticBasicMoveRegistry.s_triple_arrows',
      );
      expect(
        byMethod['s_super_duper_effective']!.status,
        PsdkPortStatus.ported,
      );
      expect(
        byMethod['s_super_duper_effective']!.dartBehavior,
        'StaticBasicMoveRegistry.s_super_duper_effective',
      );
      expect(byMethod['s_brick_break']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_brick_break']!.dartBehavior,
        'StaticBasicMoveRegistry.s_brick_break',
      );
      expect(byMethod['s_raging_bull']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_raging_bull']!.dartBehavior,
        'StaticBasicMoveRegistry.s_raging_bull',
      );
      expect(byMethod['s_feint']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_feint']!.dartBehavior,
        'StaticBasicMoveRegistry.s_feint',
      );
      expect(byMethod['s_fell_stinger']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_fell_stinger']!.dartBehavior,
        'StaticBasicMoveRegistry.s_fell_stinger',
      );
      expect(byMethod['s_poltergeist']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_poltergeist']!.dartBehavior,
        'StaticBasicMoveRegistry.s_poltergeist',
      );
      expect(byMethod['s_stomp']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_stomp']!.dartBehavior,
        'StaticBasicMoveRegistry.s_stomp',
      );
      expect(byMethod['s_jaw_lock']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_jaw_lock']!.dartBehavior,
        'StaticBasicMoveRegistry.s_jaw_lock',
      );
      expect(byMethod['s_sappy_seed']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_sappy_seed']!.dartBehavior,
        'StaticBasicMoveRegistry.s_sappy_seed',
      );
      expect(byMethod['s_baddy_bad']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_baddy_bad']!.dartBehavior,
        'StaticBasicMoveRegistry.s_baddy_bad',
      );
      expect(byMethod['s_glitzy_glow']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_glitzy_glow']!.dartBehavior,
        'StaticBasicMoveRegistry.s_glitzy_glow',
      );
      expect(byMethod['s_grav_apple']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_grav_apple']!.dartBehavior,
        'StaticBasicMoveRegistry.s_grav_apple',
      );
      expect(byMethod['s_freezy_frost']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_freezy_frost']!.dartBehavior,
        'StaticBasicMoveRegistry.s_freezy_frost',
      );
      expect(byMethod['s_ceaseless_edge']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_ceaseless_edge']!.dartBehavior,
        'StaticBasicMoveRegistry.s_ceaseless_edge',
      );
      expect(byMethod['s_stone_axe']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_stone_axe']!.dartBehavior,
        'StaticBasicMoveRegistry.s_stone_axe',
      );
      expect(byMethod['s_cantflee']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_cantflee']!.dartBehavior,
        'StaticBasicMoveRegistry.s_cantflee',
      );
      expect(byMethod['s_defog']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_spike']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_spike']!.dartBehavior,
        'StaticBasicMoveRegistry.s_spike',
      );
      expect(byMethod['s_stealth_rock']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_stealth_rock']!.dartBehavior,
        'StaticBasicMoveRegistry.s_stealth_rock',
      );
      expect(byMethod['s_sticky_web']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_sticky_web']!.dartBehavior,
        'StaticBasicMoveRegistry.s_sticky_web',
      );
      expect(byMethod['s_tidy_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_tidy_up']!.dartBehavior,
        'StaticBasicMoveRegistry.s_tidy_up',
      );
      expect(byMethod['s_toxic_spike']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_toxic_spike']!.dartBehavior,
        'StaticBasicMoveRegistry.s_toxic_spike',
      );
      expect(byMethod['s_snore']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_snore']!.dartBehavior,
        'ActionGatedMoveBehavior.snore',
      );
      expect(byMethod['s_sucker_punch']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_sucker_punch']!.dartBehavior,
        'ActionGatedMoveBehavior.suckerPunch',
      );
      expect(byMethod['s_upper_hand']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_upper_hand']!.dartBehavior,
        'ActionGatedMoveBehavior.upperHand',
      );
      expect(byMethod['s_fake_out']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_fake_out']!.dartBehavior,
        'ActionGatedMoveBehavior.fakeOut',
      );
      expect(byMethod['s_focus_punch']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_focus_punch']!.dartBehavior,
        'ActionGatedMoveBehavior.focusPunch',
      );
      expect(byMethod['s_hurricane']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_hurricane']!.dartBehavior,
        'WeatherPowerMoveBehavior.hurricane',
      );
      expect(byMethod['s_solar_beam']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_solar_beam']!.dartBehavior,
        'WeatherPowerMoveBehavior.solarBeam',
      );
      expect(byMethod['s_thunder']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_thunder']!.dartBehavior,
        'WeatherPowerMoveBehavior.thunder',
      );
      expect(byMethod['s_echo']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_echo']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.echoedVoice',
      );
      expect(byMethod['s_ice_ball']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_ice_ball']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.iceBall',
      );
      expect(byMethod['s_rollout']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_rollout']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.rollout',
      );
      expect(byMethod['s_trump_card']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_trump_card']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.trumpCard',
      );
      expect(byMethod['s_bide']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_bide']!.dartBehavior,
        'CounterDamageMoveBehavior.bide',
      );
      expect(byMethod['s_fishious_rend']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_fishious_rend']!.dartBehavior,
        'HistoryPowerMoveBehavior.fishiousRend',
      );
      expect(byMethod['s_retaliate']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_retaliate']!.dartBehavior,
        'HistoryPowerMoveBehavior.retaliate',
      );
      expect(byMethod['s_revenge']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_revenge']!.dartBehavior,
        'HistoryPowerMoveBehavior.revenge',
      );
      for (final entry in <({String method, String behavior})>[
        (
          method: 's_genies_storm',
          behavior: 'WeatherPowerMoveBehavior.geniesStorm',
        ),
        (
          method: 's_fury_cutter',
          behavior: 'ConsecutivePowerMoveBehavior.furyCutter',
        ),
        (
          method: 's_counter',
          behavior: 'CounterDamageMoveBehavior.counter',
        ),
        (
          method: 's_metal_burst',
          behavior: 'CounterDamageMoveBehavior.metalBurst',
        ),
        (
          method: 's_mirror_coat',
          behavior: 'CounterDamageMoveBehavior.mirrorCoat',
        ),
        (
          method: 's_avalanche',
          behavior: 'HistoryPowerMoveBehavior.avalanche',
        ),
        (
          method: 's_assurance',
          behavior: 'HistoryPowerMoveBehavior.assurance',
        ),
        (
          method: 's_lash_out',
          behavior: 'HistoryPowerMoveBehavior.lashOut',
        ),
        (
          method: 's_payback',
          behavior: 'HistoryPowerMoveBehavior.payback',
        ),
        (
          method: 's_rage_fist',
          behavior: 'HistoryPowerMoveBehavior.rageFist',
        ),
        (
          method: 's_stomping_tantrum',
          behavior: 'HistoryPowerMoveBehavior.stompingTantrum',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      expect(byMethod['s_ivy_cudgel']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_ivy_cudgel']!.dartBehavior,
        'TypeBasedMoveBehavior.ivyCudgel',
      );
      expect(byMethod['s_judgment']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_judgment']!.dartBehavior,
        'TypeBasedMoveBehavior.judgment',
      );
      expect(byMethod['s_multi_attack']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_multi_attack']!.dartBehavior,
        'TypeBasedMoveBehavior.multiAttack',
      );
      expect(byMethod['s_revelation_dance']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_revelation_dance']!.dartBehavior,
        'TypeBasedMoveBehavior.revelationDance',
      );
      expect(byMethod['s_bind']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_bind']!.dartBehavior,
        'StaticBasicMoveRegistry.s_bind',
      );
      expect(byMethod['s_dragon_tail']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_dragon_tail']!.dartBehavior,
        'StaticBasicMoveRegistry.forceSwitch(s_dragon_tail)',
      );
      expect(byMethod['s_roar']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_roar']!.dartBehavior,
        'StaticBasicMoveRegistry.forceSwitch(s_roar)',
      );
      expect(byMethod['s_substitute']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_substitute']!.dartBehavior,
        'StaticBasicMoveRegistry.s_substitute',
      );
      expect(byMethod['s_follow_me']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_follow_me']!.dartBehavior,
        'StaticBasicMoveRegistry.s_follow_me',
      );
      expect(byMethod['s_add_type']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_add_type']!.dartBehavior,
        'StaticBasicMoveRegistry.s_add_type',
      );
      expect(byMethod['s_foresight']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_foresight']!.dartBehavior,
        'StaticBasicMoveRegistry.s_foresight',
      );
      expect(byMethod['s_thing_sport']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_thing_sport']!.dartBehavior,
        'StaticBasicMoveRegistry.s_thing_sport',
      );
      expect(byMethod['s_trick']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_trick']!.dartBehavior,
        'StaticBasicMoveRegistry.s_trick',
      );
      for (final entry in <({String method, String behavior})>[
        (method: 's_belch', behavior: 'ItemDependentMoveBehavior.belch'),
        (
          method: 's_natural_gift',
          behavior: 'ItemDependentMoveBehavior.naturalGift',
        ),
        (method: 's_recycle', behavior: 'ItemDependentMoveBehavior.recycle'),
        (method: 's_taunt', behavior: 'StaticBasicMoveRegistry.s_taunt'),
        (
          method: 's_techno_blast',
          behavior: 'ItemDependentMoveBehavior.technoBlast',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      for (final entry in <({String method, String behavior})>[
        (method: 's_bestow', behavior: 'ItemDependentMoveBehavior.bestow'),
        (method: 's_fling', behavior: 'ItemDependentMoveBehavior.fling'),
        (method: 's_knock_off', behavior: 'ItemDependentMoveBehavior.knockOff'),
        (method: 's_pluck', behavior: 'ItemDependentMoveBehavior.pluck'),
        (method: 's_thief', behavior: 'ItemDependentMoveBehavior.thief'),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      for (final entry in <({String method, String behavior})>[
        (method: 's_after_you', behavior: 'StaticBasicMoveRegistry.afterYou'),
        (method: 's_add_type', behavior: 'StaticBasicMoveRegistry.s_add_type'),
        (method: 's_assist', behavior: 'CopyCallMoveBehavior.assist'),
        (
          method: 's_change_type',
          behavior: 'StaticBasicMoveRegistry.s_change_type',
        ),
        (
          method: 's_corrosive_gas',
          behavior: 'StaticBasicMoveRegistry.s_corrosive_gas',
        ),
        (method: 's_disable', behavior: 'StaticBasicMoveRegistry.disable'),
        (
          method: 's_embargo',
          behavior: 'StaticBasicMoveRegistry.targetMarker(s_embargo)',
        ),
        (method: 's_encore', behavior: 'StaticBasicMoveRegistry.encore'),
        (method: 's_heal_block', behavior: 'StaticBasicMoveRegistry.healBlock'),
        (
          method: 's_happy_hour',
          behavior: 'StaticBasicMoveRegistry.fieldMarker(s_happy_hour)',
        ),
        (
          method: 's_healing_wish',
          behavior: 'StaticBasicMoveRegistry.s_healing_wish',
        ),
        (method: 's_imprison', behavior: 'StaticBasicMoveRegistry.imprison'),
        (method: 's_instruct', behavior: 'CopyCallMoveBehavior.instruct'),
        (
          method: 's_ion_deluge',
          behavior: 'StaticBasicMoveRegistry.fieldMarker(s_ion_deluge)',
        ),
        (
          method: 's_lunar_dance',
          behavior: 'StaticBasicMoveRegistry.s_lunar_dance',
        ),
        (
          method: 's_magic_powder',
          behavior: 'StaticBasicMoveRegistry.s_magic_powder',
        ),
        (method: 's_metronome', behavior: 'CopyCallMoveBehavior.metronome'),
        (method: 's_mimic', behavior: 'CopyCallMoveBehavior.mimic'),
        (method: 's_mirror_move', behavior: 'CopyCallMoveBehavior.mirrorMove'),
        (method: 's_me_first', behavior: 'CopyCallMoveBehavior.meFirst'),
        (
          method: 's_plasma_fists',
          behavior: 'StaticBasicMoveRegistry.s_plasma_fists',
        ),
        (
          method: 's_powder',
          behavior: 'StaticBasicMoveRegistry.targetMarker(s_powder)',
        ),
        (method: 's_quash', behavior: 'StaticBasicMoveRegistry.quash'),
        (
          method: 's_reflect_type',
          behavior: 'StaticBasicMoveRegistry.s_reflect_type',
        ),
        (method: 's_sketch', behavior: 'CopyCallMoveBehavior.sketch'),
        (method: 's_sleep_talk', behavior: 'CopyCallMoveBehavior.sleepTalk'),
        (
          method: 's_stockpile',
          behavior: 'StaticBasicMoveRegistry.s_stockpile'
        ),
        (method: 's_torment', behavior: 'StaticBasicMoveRegistry.s_torment'),
        (
          method: 's_autotomize',
          behavior: 'StaticBasicMoveRegistry.s_autotomize'
        ),
        (
          method: 's_attract',
          behavior: 'StaticBasicMoveRegistry.attract',
        ),
        (
          method: 's_captivate',
          behavior: 'StaticBasicMoveRegistry.secondaryOnly(s_captivate)',
        ),
        (
          method: 's_future_sight',
          behavior: 'StaticBasicMoveRegistry.delayedMove(s_future_sight)',
        ),
        (
          method: 's_chilly_reception',
          behavior: 'StaticBasicMoveRegistry.s_chilly_reception',
        ),
        (
          method: 's_doodle',
          behavior: 'StaticBasicMoveRegistry.s_doodle',
        ),
        (
          method: 's_magic_room',
          behavior: 'StaticBasicMoveRegistry.fieldMarker(s_magic_room)',
        ),
        (
          method: 's_entrainment',
          behavior: 'StaticBasicMoveRegistry.abilityChanging(s_entrainment)',
        ),
        (
          method: 's_role_play',
          behavior: 'StaticBasicMoveRegistry.abilityChanging(s_role_play)',
        ),
        (
          method: 's_simple_beam',
          behavior: 'StaticBasicMoveRegistry.abilityChanging(s_simple_beam)',
        ),
        (
          method: 's_skill_swap',
          behavior: 'StaticBasicMoveRegistry.abilityChanging(s_skill_swap)',
        ),
        (
          method: 's_nightmare',
          behavior: 'StaticBasicMoveRegistry.targetMarker(s_nightmare)',
        ),
        (
          method: 's_perish_song',
          behavior: 'StaticBasicMoveRegistry.targetMarker(s_perish_song)',
        ),
        (
          method: 's_spite',
          behavior: 'StaticBasicMoveRegistry.s_spite',
        ),
        (
          method: 's_wonder_room',
          behavior: 'StaticBasicMoveRegistry.fieldMarker(s_wonder_room)',
        ),
        (
          method: 's_worry_seed',
          behavior: 'StaticBasicMoveRegistry.abilityChanging(s_worry_seed)',
        ),
        (
          method: 's_teleport',
          behavior: 'StaticBasicMoveRegistry.s_teleport',
        ),
        (
          method: 's_magic_coat',
          behavior: 'StaticBasicMoveRegistry.s_magic_coat',
        ),
        (
          method: 's_snatch',
          behavior: 'StaticBasicMoveRegistry.s_snatch',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      for (final entry in <({String method, String behavior})>[
        (
          method: 's_destiny_bond',
          behavior: 'StaticBasicMoveRegistry.s_destiny_bond',
        ),
        (
          method: 's_grudge',
          behavior: 'StaticBasicMoveRegistry.s_grudge',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      expect(byMethod['s_electrify']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_electrify']!.dartBehavior,
        'StaticBasicMoveRegistry.s_electrify',
      );
      expect(byMethod['s_wish']!.status, PsdkPortStatus.ported);
      expect(
          byMethod['s_wish']!.dartBehavior, 'StaticBasicMoveRegistry.s_wish');
      expect(byMethod['s_dragon_cheer']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_dragon_cheer']!.dartBehavior,
        'StaticBasicMoveRegistry.s_dragon_cheer',
      );
      expect(byMethod['s_gravity']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_gravity']!.dartBehavior,
        'StaticBasicMoveRegistry.s_gravity',
      );
      expect(byMethod['s_no_retreat']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_no_retreat']!.dartBehavior,
        'StaticBasicMoveRegistry.s_no_retreat',
      );
      for (final entry in <({String method, String behavior})>[
        (
          method: 's_fairy_lock',
          behavior: 'StaticBasicMoveRegistry.fairyLock',
        ),
        (
          method: 's_octolock',
          behavior: 'StaticBasicMoveRegistry.octolock',
        ),
        (
          method: 's_yawn',
          behavior: 'StaticBasicMoveRegistry.drowsiness',
        ),
        (
          method: 's_lock_on',
          behavior: 'StaticBasicMoveRegistry.s_lock_on',
        ),
        (
          method: 's_mind_reader',
          behavior: 'StaticBasicMoveRegistry.s_mind_reader',
        ),
        (
          method: 's_parting_shot',
          behavior: 'StaticBasicMoveRegistry.secondaryOnly(s_parting_shot)',
        ),
        (
          method: 's_toxic_thread',
          behavior: 'StaticBasicMoveRegistry.secondaryOnly(s_toxic_thread)',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      expect(byMethod['s_ally_switch']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_ally_switch']!.dartBehavior,
        'StaticBasicMoveRegistry.s_ally_switch',
      );
      expect(byMethod['s_crafty_shield']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_crafty_shield']!.dartBehavior,
        'StaticBasicMoveRegistry.s_crafty_shield',
      );
      for (final entry in <({String method, String behavior})>[
        (
          method: 's_charge',
          behavior: 'StaticBasicMoveRegistry.s_charge',
        ),
        (
          method: 's_focus_energy',
          behavior: 'StaticBasicMoveRegistry.s_focus_energy',
        ),
        (
          method: 's_gastro_acid',
          behavior: 'StaticBasicMoveRegistry.s_gastro_acid',
        ),
        (
          method: 's_laser_focus',
          behavior: 'StaticBasicMoveRegistry.s_laser_focus',
        ),
        (
          method: 's_magnet_rise',
          behavior: 'StaticBasicMoveRegistry.s_magnet_rise',
        ),
        (
          method: 's_minimize',
          behavior: 'StaticBasicMoveRegistry.s_minimize',
        ),
        (
          method: 's_miracle_eye',
          behavior: 'StaticBasicMoveRegistry.s_miracle_eye',
        ),
        (
          method: 's_telekinesis',
          behavior: 'StaticBasicMoveRegistry.s_telekinesis',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.ported);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      expect(byMethod['s_lucky_chant']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_lucky_chant']!.dartBehavior,
        'StaticBasicMoveRegistry.s_lucky_chant',
      );
      expect(byMethod['s_mist']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_mist']!.dartBehavior,
        'StaticBasicMoveRegistry.s_mist',
      );
      expect(byMethod['s_reflect']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_reflect']!.dartBehavior,
        'StaticBasicMoveRegistry.s_reflect',
      );
      expect(byMethod['s_safe_guard']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_safe_guard']!.dartBehavior,
        'StaticBasicMoveRegistry.s_safe_guard',
      );
      expect(byMethod['s_tailwind']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_tailwind']!.dartBehavior,
        'StaticBasicMoveRegistry.s_tailwind',
      );
      expect(byMethod['s_trick_room']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_trick_room']!.dartBehavior,
        'StaticBasicMoveRegistry.s_trick_room',
      );
      expect(byMethod['s_reload']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_reload']!.dartBehavior,
        'StaticBasicMoveRegistry.s_reload',
      );
      expect(
        byMethod['s_u_turn']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerSwitch,
          PsdkMoveDependency.item,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(
        byMethod['s_follow_me']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(
        byMethod['s_add_type']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(
        byMethod['s_foresight']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_thing_sport']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.field,
        ]),
      );
      expect(
        byMethod['s_trick']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerItem,
          PsdkMoveDependency.item,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(
        byMethod['s_yawn']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.terrain,
        ]),
      );
      expect(
        byMethod['s_future_sight']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.endTurn,
          PsdkMoveDependency.handlerDamage,
        ]),
      );
      expect(
        byMethod['s_spike']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.handlerSwitch,
          PsdkMoveDependency.grounded,
        ]),
      );
      expect(
        byMethod['s_trick_room']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.actionOrder,
          PsdkMoveDependency.field,
        ]),
      );
      expect(
        byMethod['s_helping_hand']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(
        byMethod['s_electrify']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_ion_deluge']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_simple_beam']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.ability,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_skill_swap']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.ability,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_reflect_type']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(
        byMethod['s_dragon_tail']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerSwitch,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(byMethod['s_lucky_chant']!.dependencies, isEmpty);
      expect(byMethod['s_mist']!.dependencies, isEmpty);
      expect(byMethod['s_reflect']!.dependencies, isEmpty);
      expect(byMethod['s_safe_guard']!.dependencies, isEmpty);
      expect(
        byMethod['s_reload']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.history,
          PsdkMoveDependency.actionOrder,
        ]),
      );
      expect(
        byMethod['s_retaliate']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.history,
          PsdkMoveDependency.faintProcess,
        ]),
      );
      expect(
        byMethod['s_rollout']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.history,
          PsdkMoveDependency.accuracy,
        ]),
      );
      expect(
        byMethod['s_round']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.actionOrder,
          PsdkMoveDependency.history,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(
        byMethod['s_secret_power']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.field,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.handlerStat,
        ]),
      );
      expect(
        byMethod['s_snore']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(
        byMethod['s_pledge']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.field,
          PsdkMoveDependency.targetingMulti,
          PsdkMoveDependency.actionOrder,
        ]),
      );
      expect(
        byMethod['s_smack_down']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.grounded,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(
        byMethod['s_thunder']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.weather,
          PsdkMoveDependency.accuracy,
        ]),
      );
      expect(
        byMethod['s_uproar']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.history,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
    });

    test('tracks the Lot 19/20 no-effect and direct-HP slices', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_do_nothing']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_do_nothing']!.dartBehavior,
        'NoEffectMoveBehavior.doNothing',
      );
      expect(byMethod['s_splash']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_splash']!.dartBehavior,
        'NoEffectMoveBehavior.splash',
      );
      expect(byMethod['s_ohko']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_ohko']!.dartBehavior, 'OhkoMoveBehavior');
      expect(byMethod['s_endeavor']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_endeavor']!.dartBehavior,
        'DirectHpMoveBehavior.endeavor',
      );
      expect(byMethod['s_final_gambit']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_final_gambit']!.dartBehavior,
        'DirectHpMoveBehavior.finalGambit',
      );
      expect(byMethod['s_pain_split']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_pain_split']!.dartBehavior,
        'DirectHpMoveBehavior.painSplit',
      );
      expect(
        byMethod['s_pain_split']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.effects,
        ]),
      );
    });

    test('tracks the Lot 21 recoil slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_recoil']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_recoil']!.dartBehavior,
        'RecoilMoveBehavior.psdkRecoil',
      );
      expect(byMethod['s_struggle']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_struggle']!.dartBehavior,
        'RecoilMoveBehavior.struggle',
      );
    });

    test('tracks the Lot 22 MindBlown self-crash slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_chloroblast']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_chloroblast']!.dartBehavior,
        'MindBlownMoveBehavior.chloroblast',
      );
      expect(byMethod['s_mind_blown']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_mind_blown']!.dartBehavior,
        'MindBlownMoveBehavior.mindBlown',
      );
      expect(byMethod['s_steel_beam']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_steel_beam']!.dartBehavior,
        'MindBlownMoveBehavior.steelBeam',
      );
    });

    test('tracks the Lot 23 SelfDestruct slice and adjacent gaps honestly', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_explosion']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_explosion']!.dartBehavior,
        'SelfDestructMoveBehavior.explosion',
      );
      expect(byMethod['s_explosion']!.rubyClass, 'SelfDestruct');

      expect(byMethod['s_misty_explosion']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_misty_explosion']!.dartBehavior,
        'SelfDestructMoveBehavior.mistyExplosion',
      );
      expect(byMethod['s_misty_explosion']!.rubyClass, 'MistyExplosion');
    });

    test('tracks the Lot 24 field terrain/weather slice honestly', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_terrain_boosting']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_terrain_boosting']!.dartBehavior,
        'TerrainPowerMoveBehavior.terrainBoosting',
      );

      expect(byMethod['s_expanding_force']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_expanding_force']!.dartBehavior,
        'TerrainPowerMoveBehavior.expandingForce',
      );
      expect(byMethod['s_grassy_glide']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_grassy_glide']!.dartBehavior,
        'TerrainPowerMoveBehavior.grassyGlide',
      );
      expect(byMethod['s_rising_voltage']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_rising_voltage']!.dartBehavior,
        'TerrainPowerMoveBehavior.risingVoltage',
      );
      expect(byMethod['s_terrain']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_terrain']!.dartBehavior, 'TerrainMoveBehavior');
      expect(byMethod['s_terrain_pulse']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_terrain_pulse']!.dartBehavior,
        'TerrainPowerMoveBehavior.terrainPulse',
      );
      expect(byMethod['s_weather']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_weather']!.dartBehavior, 'WeatherMoveBehavior');
      expect(byMethod['s_weather_ball']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_weather_ball']!.dartBehavior,
        'WeatherPowerMoveBehavior.weatherBall',
      );
    });

    test('tracks the drain heal and local power slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_absorb']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_absorb']!.dartBehavior,
        'DrainMoveBehavior.absorb',
      );
      expect(
        byMethod['s_absorb']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.item,
          PsdkMoveDependency.ability,
        ]),
      );

      expect(byMethod['s_dream_eater']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_dream_eater']!.dartBehavior,
        'DrainMoveBehavior.dreamEater',
      );
      expect(
        byMethod['s_dream_eater']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.item,
          PsdkMoveDependency.ability,
        ]),
      );

      expect(byMethod['s_heal']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_heal']!.dartBehavior, 'HealMoveBehavior');
      expect(
        byMethod['s_heal_weather']!.dartBehavior,
        'HealMoveBehavior.weather',
      );
      expect(byMethod['s_heal_weather']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_heal_weather']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.weather,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
        ]),
      );
      expect(
        byMethod['s_floral_healing']!.dartBehavior,
        'HealMoveBehavior.floralHealing',
      );
      expect(byMethod['s_floral_healing']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_roost']!.dartBehavior,
        'HealMoveBehavior.roost',
      );
      expect(
        byMethod['s_shore_up']!.dartBehavior,
        'HealMoveBehavior.shoreUp',
      );
      expect(byMethod['s_shore_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_life_dew']!.dartBehavior,
        'HealMoveBehavior.lifeDew',
      );
      expect(byMethod['s_life_dew']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_jungle_healing']!.dartBehavior,
        'HealMoveBehavior.jungleHealing',
      );
      expect(byMethod['s_jungle_healing']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_jungle_healing']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_aqua_ring']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_aqua_ring']!.dartBehavior,
        'PersistentEffectMoveBehavior.aquaRing',
      );
      expect(
        byMethod['s_aqua_ring']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.endTurn,
          PsdkMoveDependency.item,
        ]),
      );
      expect(byMethod['s_rest']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_rest']!.dartBehavior,
        'RecoveryStatMoveBehavior.rest',
      );
      expect(
        byMethod['s_rest']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.terrain,
          PsdkMoveDependency.item,
        ]),
      );
      expect(byMethod['s_bellydrum']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_bellydrum']!.dartBehavior,
        'RecoveryStatMoveBehavior.bellyDrum',
      );
      expect(
        byMethod['s_bellydrum']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStat,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(byMethod['s_strength_sap']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_strength_sap']!.dartBehavior,
        'RecoveryStatMoveBehavior.strengthSap',
      );
      expect(
        byMethod['s_strength_sap']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStat,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.item,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_fillet_away']!.dartBehavior,
        'RecoveryStatMoveBehavior.filletAway',
      );
      expect(byMethod['s_fillet_away']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_smelling_salt']!.dartBehavior,
        'HitThenCureStatusMoveBehavior.smellingSalt',
      );
      expect(byMethod['s_smelling_salt']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_smelling_salt']!.dependencies, isEmpty);
      expect(
        byMethod['s_wakeup_slap']!.dartBehavior,
        'HitThenCureStatusMoveBehavior.wakeUpSlap',
      );
      expect(byMethod['s_wakeup_slap']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_wakeup_slap']!.dependencies, isEmpty);
      expect(
        byMethod['s_sparkling_aria']!.dartBehavior,
        'HitThenCureStatusMoveBehavior.sparklingAria',
      );
      expect(byMethod['s_sparkling_aria']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_sparkling_aria']!.dependencies, isEmpty);
      expect(byMethod['s_psycho_shift']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_psycho_shift']!.dartBehavior,
        'PsychoShiftMoveBehavior',
      );
      expect(
        byMethod['s_psycho_shift']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_purify']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_purify']!.dartBehavior, 'PurifyMoveBehavior');
      expect(
        byMethod['s_purify']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_heal_bell']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_heal_bell']!.dartBehavior,
        'StatusCureMoveBehavior.healBell',
      );
      expect(
        byMethod['s_heal_bell']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_take_heart']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_take_heart']!.dartBehavior,
        'StatusCureMoveBehavior.takeHeart',
      );
      expect(byMethod['s_sparkly_swirl']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_sparkly_swirl']!.dartBehavior,
        'StatusCureMoveBehavior.sparklySwirl',
      );
      expect(byMethod['s_acrobatics']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_acrobatics']!.dartBehavior,
        'SpecialPowerMoveBehavior.acrobatics',
      );
      expect(byMethod['s_stored_power']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_stored_power']!.dartBehavior,
        'SpecialPowerMoveBehavior.storedPower',
      );
    });

    test('tracks the advanced stat-stage move slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_acupressure']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_acupressure']!.dartBehavior,
        'AdvancedStatMoveBehavior.acupressure',
      );
      expect(byMethod['s_clangorous_soul']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_clangorous_soul']!.dartBehavior,
        'AdvancedStatMoveBehavior.clangorousSoul',
      );
      expect(byMethod['s_curse']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_curse']!.dartBehavior,
        'AdvancedStatMoveBehavior.curse',
      );
      expect(byMethod['s_growth']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_growth']!.dartBehavior,
        'AdvancedStatMoveBehavior.growth',
      );
      expect(byMethod['s_guard_swap']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_guard_swap']!.dartBehavior,
        'AdvancedStatMoveBehavior.guardSwap',
      );
      expect(byMethod['s_haze']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_haze']!.dartBehavior,
        'AdvancedStatMoveBehavior.haze',
      );
      expect(byMethod['s_heart_swap']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_heart_swap']!.dartBehavior,
        'AdvancedStatMoveBehavior.heartSwap',
      );
      expect(byMethod['s_power_swap']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_power_swap']!.dartBehavior,
        'AdvancedStatMoveBehavior.powerSwap',
      );
      expect(byMethod['s_psych_up']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_psych_up']!.dartBehavior,
        'AdvancedStatMoveBehavior.psychUp',
      );
      expect(byMethod['s_topsy_turvy']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_topsy_turvy']!.dartBehavior,
        'AdvancedStatMoveBehavior.topsyTurvy',
      );
      expect(byMethod['s_power_split']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_power_split']!.dartBehavior,
        'StatSplitMoveBehavior.power',
      );
      expect(byMethod['s_guard_split']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_guard_split']!.dartBehavior,
        'StatSplitMoveBehavior.guard',
      );
      expect(byMethod['s_power_trick']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_power_trick']!.dartBehavior,
        'PowerTrickMoveBehavior',
      );
      expect(byMethod['s_speed_swap']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_speed_swap']!.dartBehavior,
        'SpeedSwapMoveBehavior',
      );
      expect(
        byMethod['s_haze']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerStat,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
    });

    test('tracks the persistent effect move slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_aqua_ring']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_aqua_ring']!.dartBehavior,
        'PersistentEffectMoveBehavior.aquaRing',
      );
      expect(byMethod['s_ingrain']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_ingrain']!.dartBehavior,
        'PersistentEffectMoveBehavior.ingrain',
      );
      expect(byMethod['s_leech_seed']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_leech_seed']!.dartBehavior,
        'PersistentEffectMoveBehavior.leechSeed',
      );
      expect(
        byMethod['s_ingrain']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerSwitch,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.endTurn,
          PsdkMoveDependency.item,
        ]),
      );
      expect(
        byMethod['s_leech_seed']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.endTurn,
          PsdkMoveDependency.ability,
        ]),
      );
    });

    test('tracks the switch-effect move slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_baton_pass']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_baton_pass']!.dartBehavior,
        'SwitchEffectMoveBehavior.batonPass',
      );
      expect(
        byMethod['s_baton_pass']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerSwitch,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(byMethod['s_transform']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_transform']!.dartBehavior,
        'TransformMoveBehavior',
      );
      expect(byMethod['s_transform']!.dependencies, isEmpty);
    });

    test('records PSDK dependencies that block partial move promotion', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(
        byMethod['s_weather']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerWeather,
          PsdkMoveDependency.weather,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.item,
        ]),
      );
      expect(
        byMethod['s_expanding_force']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.terrain,
          PsdkMoveDependency.grounded,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(
        byMethod['s_recoil']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.ability,
          PsdkMoveDependency.item,
          PsdkMoveDependency.history,
        ]),
      );
      expect(byMethod['s_basic']!.dependencies, isEmpty);
    });

    test('partial move methods have explicit remaining blockers', () {
      final partialWithoutBlockers = psdkMoveRegistryManifest
          .where((entry) => entry.status == PsdkPortStatus.partial)
          .where((entry) => entry.dependencies.isEmpty)
          .map((entry) => entry.battleEngineMethod)
          .toList(growable: false);

      expect(partialWithoutBlockers, isEmpty);
    });

    test('does not contain duplicate battleEngineMethod entries', () {
      final methods = psdkMoveRegistryManifest
          .map((entry) => entry.battleEngineMethod)
          .toList(growable: false);

      expect(methods.toSet(), hasLength(methods.length));
      expect(methods, orderedEquals([...methods]..sort()));
    });

    test('tracks Lot 35 special and gimmick scope decisions', () {
      final decisions = {
        for (final decision in psdkSpecialMoveScopeDecisions)
          decision.battleEngineMethod: decision,
      };
      const expectedScopes = <String, PsdkSpecialMoveScope>{
        's_genesis_supernova': PsdkSpecialMoveScope.combatScope,
        's_guardian_of_alola': PsdkSpecialMoveScope.combatScope,
        's_hyperspace_hole': PsdkSpecialMoveScope.combatScope,
        's_light_that_burns_the_sky': PsdkSpecialMoveScope.combatScope,
        's_malicious_moonsault': PsdkSpecialMoveScope.combatScope,
        's_self_stat_z_move': PsdkSpecialMoveScope.combatScope,
        's_splintered_stormshards': PsdkSpecialMoveScope.combatScope,
        's_z_move': PsdkSpecialMoveScope.combatScope,
      };

      expect(decisions.keys, unorderedEquals(expectedScopes.keys));
      for (final expected in expectedScopes.entries) {
        expect(decisions[expected.key]!.scope, expected.value);
      }
      expect(decisions['s_z_move']!.family, PsdkSpecialMoveFamily.zMove);
      expect(
        decisions['s_hyperspace_hole']!.family,
        PsdkSpecialMoveFamily.studioOnlySpecialCase,
      );
      expect(
        psdkSpecialActionScopeDecisions
            .map((decision) => decision.actionId)
            .toSet(),
        containsAll(<String>{
          'mega_evolution',
          'primal_reversion',
          'tera_shift',
          'max_move_family',
        }),
      );
    });
  });

  group('PSDK extraction tools', () {
    test('move extractor writes a sorted matrix and optional Dart manifest',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_move_extractor_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final moveDir = Directory('${temp.path}/10 Move/1 Mechanics')
        ..createSync(recursive: true);
      File('${moveDir.path}/100 Basic.rb').writeAsStringSync('''
module Battle
  class Move
    class Basic < Move
    end
    Move.register(:s_basic, Basic)
  end
end
''');
      File('${moveDir.path}/300 Custom.rb').writeAsStringSync('''
module Battle
  class Move
    class CustomMove < Move
    end
    Move.register(:s_custom_move, CustomMove)
  end
end
''');

      final output = File('${temp.path}/move-matrix.md');
      final manifest = File('${temp.path}/manifest.dart');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_move_registry.dart',
          temp.path,
          output.path,
          '--manifest',
          manifest.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final markdown = output.readAsStringSync();
      expect(markdown, contains('| `s_basic` | `Basic` |'));
      expect(markdown, contains('| `s_custom_move` | `CustomMove` |'));
      expect(markdown.indexOf('`s_basic`'),
          lessThan(markdown.indexOf('`s_custom_move`')));
      expect(
          markdown,
          contains(
              '| `s_basic` | `Basic` | `10 Move/1 Mechanics/100 Basic.rb` | `StaticBasicMoveRegistry.s_basic` | `ported` | `-` |'));
      expect(
          markdown,
          contains(
              '| `s_custom_move` | `CustomMove` | `10 Move/1 Mechanics/300 Custom.rb` | `TODO` | `missing` | `-` |'));

      final dart = manifest.readAsStringSync();
      expect(dart, contains('const psdkMoveRegistryManifest'));
      expect(dart, contains("battleEngineMethod: 's_basic'"));
      expect(dart, contains('PsdkPortStatus.ported'));
      expect(dart, contains('dependencies: const <PsdkMoveDependency>[]'));
      expect(dart, contains("battleEngineMethod: 's_custom_move'"));
      expect(dart, contains('PsdkPortStatus.missing'));
    });

    test('move extractor includes unprefixed s_ registers only', () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_move_unprefixed_register_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final moveDir = Directory('${temp.path}/10 Move/2 Definitions')
        ..createSync(recursive: true);
      File('${moveDir.path}/300 SelfDestruct.rb').writeAsStringSync('''
module Battle
  class Move
    class SelfDestruct < BasicWithSuccessfulEffect
    end
    register(:s_explosion, SelfDestruct)
    register(:regular_ground, :body_slam, :sp_status, :paralysis)
  end
end
''');

      final output = File('${temp.path}/move-matrix.md');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_move_registry.dart',
          temp.path,
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final markdown = output.readAsStringSync();
      expect(markdown, contains('| `s_explosion` | `SelfDestruct` |'));
      expect(markdown, isNot(contains('regular_ground')));
    });

    test('effect extractor writes hooks and target Dart paths by family',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_effect_extractor_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final effectDir = Directory('${temp.path}/06 Effects/02 Move Effects')
        ..createSync(recursive: true);
      File('${effectDir.path}/100 Protect.rb').writeAsStringSync('''
module Battle
  module Effects
    class Protect < EffectBase
      def on_move_prevention_target(user, target, move)
      end

      def on_end_turn_event(logic, scene, battlers)
      end
    end
  end
end
''');
      File('${effectDir.path}/101 AquaRing.rb').writeAsStringSync('''
module Battle
  module Effects
    class AquaRing < PokemonTiedEffectBase
      def on_end_turn_event(logic, scene, battlers)
      end
    end
  end
end
''');

      final output = File('${temp.path}/effect-matrix.md');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_effect_matrix.dart',
          temp.path,
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final markdown = output.readAsStringSync();
      expect(
        markdown,
        contains(
          '| Effect | Ruby base | Family | Hooks | Hook families | Ruby path | Dart target | Status | Notes |',
        ),
      );
      expect(markdown, contains('| `Protect` | `EffectBase` |'));
      expect(
        markdown,
        contains('`on_end_turn_event`, `on_move_prevention_target`'),
      );
      expect(
        markdown,
        contains('`end_turn`, `move_prevention`'),
      );
      expect(
        markdown,
        contains('`lib/src/domain/effect/move/protect_effect.dart`'),
      );
      expect(markdown, contains('| `AquaRing` | `PokemonTiedEffectBase` |'));
      expect(
        markdown,
        contains('`lib/src/domain/effect/move/aqua_ring_effect.dart`'),
      );
      expect(markdown, contains('Object-backed AquaRingEffect'));
      expect(markdown, contains('Object-backed ProtectEffect'));
      expect(markdown, contains('| `partial` |'));
    });

    test(
        'effect extractor skips generic container classes when nested effects exist',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_effect_container_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final effectDir = Directory('${temp.path}/06 Effects/05 Item Effects')
        ..createSync(recursive: true);
      File('${effectDir.path}/100 Focus Sash.rb').writeAsStringSync('''
module Battle
  module Effects
    class Item
      class FocusSash < Item
        def on_damage_prevention(handler, hp, target, launcher, skill)
        end
      end
    end
  end
end
''');

      final output = File('${temp.path}/effect-matrix.md');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_effect_matrix.dart',
          temp.path,
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final markdown = output.readAsStringSync();
      expect(markdown, contains('| `FocusSash` | `Item` |'));
      expect(
        markdown.split('\n'),
        isNot(contains(startsWith('| `Item` |'))),
      );
    });

    test('effect extractor skips status weather and terrain containers',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_effect_more_containers_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final statusDir = Directory('${temp.path}/06 Effects/03 Status Effects')
        ..createSync(recursive: true);
      final weatherDir = Directory('${temp.path}/06 Effects/06 Weather Effects')
        ..createSync(recursive: true);
      final terrainDir =
          Directory('${temp.path}/06 Effects/07 Field Terrain Effects')
            ..createSync(recursive: true);
      File('${statusDir.path}/104 Asleep.rb').writeAsStringSync('''
module Battle
  module Effects
    class Status
      class Asleep < Status
        def on_move_prevention_user(user, targets, move)
        end
      end
    end
  end
end
''');
      File('${weatherDir.path}/100 Rain.rb').writeAsStringSync('''
module Battle
  module Effects
    class Weather
      class Rain < Weather
        def on_end_turn_event(logic, scene, battlers)
        end
      end
    end
  end
end
''');
      File('${terrainDir.path}/100 Grassy.rb').writeAsStringSync('''
module Battle
  module Effects
    class FieldTerrain
      class Grassy < FieldTerrain
        def on_post_damage(handler, hp, target, launcher, skill)
        end
      end
    end
  end
end
''');

      final output = File('${temp.path}/effect-matrix.md');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_effect_matrix.dart',
          temp.path,
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final rows = output.readAsLinesSync();
      expect(rows, contains(startsWith('| `Asleep` | `Status` |')));
      expect(rows, contains(startsWith('| `Rain` | `Weather` |')));
      expect(rows, contains(startsWith('| `Grassy` | `FieldTerrain` |')));
      expect(rows, isNot(contains(startsWith('| `Status` |'))));
      expect(rows, isNot(contains(startsWith('| `Weather` |'))));
      expect(rows, isNot(contains(startsWith('| `FieldTerrain` |'))));
    });

    test('effect extractor keeps standalone base container declarations',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_effect_standalone_container_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final roots = <String, String>{
        '04 Ability Effects/001 AbilityBase.rb': 'Ability',
        '05 Item Effects/001 ItemBase.rb': 'Item',
        '03 Status Effects/001 StatusBase.rb': 'Status',
        '06 Weather Effects/001 WeatherBase.rb': 'Weather',
        '07 Field Terrain Effects/001 FieldTerrainBase.rb': 'FieldTerrain',
      };
      for (final entry in roots.entries) {
        final file = File('${temp.path}/06 Effects/${entry.key}');
        file.parent.createSync(recursive: true);
        file.writeAsStringSync('''
module Battle
  module Effects
    class ${entry.value} < EffectBase
    end
  end
end
''');
      }

      final output = File('${temp.path}/effect-matrix.md');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_effect_matrix.dart',
          temp.path,
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final rows = output.readAsLinesSync();
      expect(rows, contains(startsWith('| `Ability` | `EffectBase` |')));
      expect(rows, contains(startsWith('| `Item` | `EffectBase` |')));
      expect(rows, contains(startsWith('| `Status` | `EffectBase` |')));
      expect(rows, contains(startsWith('| `Weather` | `EffectBase` |')));
      expect(rows, contains(startsWith('| `FieldTerrain` | `EffectBase` |')));
    });

    test('effect extractor assigns hooks to the class that defines them',
        () async {
      final temp = await Directory.systemTemp.createTemp(
        'psdk_effect_hook_scope_test_',
      );
      addTearDown(() => temp.delete(recursive: true));
      final effectDir = Directory('${temp.path}/06 Effects/02 Move Effects')
        ..createSync(recursive: true);
      File('${effectDir.path}/001 Protect.rb').writeAsStringSync('''
module Battle
  module Effects
    class Protect < PokemonTiedEffectBase
      def on_move_prevention_target(user, target, move)
        return nil
      end
    end

    class SpikyShield < Protect
      def on_post_damage(handler, hp, target, launcher, skill)
        return nil
      end
    end
  end
end
''');

      final output = File('${temp.path}/effect-matrix.md');
      final result = await Process.run(
        Platform.resolvedExecutable,
        <String>[
          'run',
          'tool/extract_psdk_effect_matrix.dart',
          temp.path,
          output.path,
        ],
        workingDirectory: Directory.current.path,
      );

      expect(result.exitCode, 0, reason: result.stderr.toString());
      final rows = output.readAsLinesSync();
      final protectRow =
          rows.singleWhere((line) => line.startsWith('| `Protect` |'));
      final spikyShieldRow =
          rows.singleWhere((line) => line.startsWith('| `SpikyShield` |'));

      expect(protectRow, contains('`on_move_prevention_target`'));
      expect(protectRow, contains('`move_prevention`'));
      expect(protectRow, isNot(contains('`on_post_damage`')));
      expect(spikyShieldRow, contains('`on_post_damage`'));
      expect(spikyShieldRow, contains('`post_damage`'));
      expect(spikyShieldRow, isNot(contains('`on_move_prevention_target`')));
    });
  });
}

String _readTestCorpus(Directory directory) {
  final buffer = StringBuffer();
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      buffer.writeln(entity.readAsStringSync());
    }
  }
  return buffer.toString();
}

String _readFixtureCorpus(Directory directory) {
  final buffer = StringBuffer();
  for (final entity in directory.listSync(recursive: true)) {
    if (entity is File &&
        (entity.path.endsWith('.json') || entity.path.endsWith('.md'))) {
      buffer.writeln(entity.readAsStringSync());
    }
  }
  return buffer.toString();
}

bool _hasMoveEvidence(
  PsdkMoveRegistryManifestEntry entry,
  String testCorpus,
) {
  if (testCorpus.contains(entry.battleEngineMethod)) {
    return true;
  }
  final behaviorOwner = entry.dartBehavior.split('.').first;
  if (behaviorOwner.isNotEmpty && testCorpus.contains(behaviorOwner)) {
    return true;
  }
  return testCorpus.contains(entry.rubyClass);
}

bool _hasEffectEvidence(
  PsdkEffectParityEntry entry,
  String testCorpus,
  String fixtureCorpus,
) {
  if (testCorpus.contains(entry.effectName)) {
    return true;
  }
  final snakeName = _snakeCase(entry.effectName);
  if (snakeName.isNotEmpty &&
      (testCorpus.contains(snakeName) || fixtureCorpus.contains(snakeName))) {
    return true;
  }
  final familyTag = entry.family == 'move' ? 'effect_family' : entry.family;
  return fixtureCorpus.contains(familyTag);
}

bool _psdkSourceExists(String rubyPath) {
  final repoRoot = Directory('../..');
  if (File('${repoRoot.path}/$rubyPath').existsSync()) {
    return true;
  }
  final psdkBattleRoot =
      Directory('../../pokemonsdk-development/scripts/5 Battle');
  return File('${psdkBattleRoot.path}/$rubyPath').existsSync();
}

String _snakeCase(String value) {
  return value
      .replaceAllMapped(
        RegExp(r'([a-z0-9])([A-Z])'),
        (match) => '${match.group(1)}_${match.group(2)}',
      )
      .replaceAll('-', '_')
      .replaceAll(' ', '_')
      .toLowerCase();
}
