import 'dart:io';

import 'package:map_battle/src/data/generated/psdk_move_registry_manifest.dart';
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
      expect(byMethod['s_basic']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_status']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_protect']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_stat']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_self_stat']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_self_status']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_protect']!.rubyClass, 'Protect');
      expect(byMethod['s_protect']!.dartBehavior, contains('s_protect'));
      expect(
        byMethod['s_status']!.dartBehavior,
        'StatusStatMoveBehavior.status',
      );
      expect(
        byMethod['s_stat']!.dartBehavior,
        'StatusStatMoveBehavior.stat',
      );
      expect(
        byMethod['s_self_stat']!.dartBehavior,
        'StatusStatMoveBehavior.selfStat',
      );
      expect(
        byMethod['s_self_status']!.dartBehavior,
        'StatusStatMoveBehavior.selfStatus',
      );
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
      expect(byMethod['s_multi_hit']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_triple_kick']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_triple_kick']!.dartBehavior,
        'MultiHitMoveBehavior.tripleKick',
      );
      expect(byMethod['s_population_bomb']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_population_bomb']!.dartBehavior,
        'MultiHitMoveBehavior.populationBomb',
      );
      expect(byMethod['s_water_shuriken']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_water_shuriken']!.dartBehavior,
        'MultiHitMoveBehavior.waterShuriken',
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
      expect(byMethod['s_gyro_ball']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_facade']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_infernal_parade']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_bitter_malice']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_venoshock']!.status, PsdkPortStatus.ported);
      expect(byMethod['s_hex']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_low_kick']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_low_kick']!.dartBehavior,
        'WeightPowerMoveBehavior.lowKick',
      );
      expect(byMethod['s_heavy_slam']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_body_press']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_body_press']!.dartBehavior,
        'CustomStatSourceMoveBehavior.bodyPress',
      );
      expect(byMethod['s_foul_play']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_foul_play']!.dartBehavior,
        'CustomStatSourceMoveBehavior.foulPlay',
      );
      expect(byMethod['s_psyshock']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_psyshock']!.dartBehavior,
        'CustomStatSourceMoveBehavior.psyshock',
      );
      expect(byMethod['s_custom_stats_based']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_custom_stats_based']!.dartBehavior,
        'CustomStatSourceMoveBehavior.customStatsBased',
      );
    });

    test('tracks the Lot 18 basic damage specialization slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_false_swipe']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_false_swipe']!.dartBehavior,
        'BasicDamageSpecializationMoveBehavior.falseSwipe',
      );
      expect(byMethod['s_full_crit']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_full_crit']!.dartBehavior,
        'BasicDamageSpecializationMoveBehavior.fullCrit',
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
      expect(byMethod['s_splash']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_splash']!.dartBehavior,
        'NoEffectMoveBehavior.splash',
      );
      expect(byMethod['s_endeavor']!.status, PsdkPortStatus.ported);
      expect(
        byMethod['s_endeavor']!.dartBehavior,
        'DirectHpMoveBehavior.endeavor',
      );
      expect(byMethod['s_final_gambit']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_final_gambit']!.dartBehavior,
        'DirectHpMoveBehavior.finalGambit',
      );
    });

    test('tracks the Lot 21 recoil slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_recoil']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_recoil']!.dartBehavior,
        'RecoilMoveBehavior.psdkRecoil',
      );
      expect(byMethod['s_struggle']!.status, PsdkPortStatus.missing);
      expect(byMethod['s_struggle']!.dartBehavior, 'TODO');
    });

    test('tracks the Lot 22 MindBlown self-crash slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_chloroblast']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_chloroblast']!.dartBehavior,
        'MindBlownMoveBehavior.chloroblast',
      );
      expect(byMethod['s_mind_blown']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_mind_blown']!.dartBehavior,
        'MindBlownMoveBehavior.mindBlown',
      );
      expect(byMethod['s_steel_beam']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_explosion']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_explosion']!.dartBehavior,
        'SelfDestructMoveBehavior.explosion',
      );
      expect(byMethod['s_explosion']!.rubyClass, 'SelfDestruct');

      expect(byMethod['s_misty_explosion']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_expanding_force']!.status, PsdkPortStatus.missing);
      expect(byMethod['s_grassy_glide']!.status, PsdkPortStatus.missing);
      expect(byMethod['s_rising_voltage']!.status, PsdkPortStatus.missing);
      expect(byMethod['s_terrain']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_terrain']!.dartBehavior, 'TerrainMoveBehavior');
      expect(byMethod['s_terrain_pulse']!.status, PsdkPortStatus.missing);
      expect(byMethod['s_weather']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_weather']!.dartBehavior, 'WeatherMoveBehavior');
      expect(byMethod['s_weather_ball']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_absorb']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_dream_eater']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_heal']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_heal']!.dartBehavior, 'HealMoveBehavior');
      expect(
        byMethod['s_heal_weather']!.dartBehavior,
        'HealMoveBehavior.weather',
      );
      expect(byMethod['s_heal_weather']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_floral_healing']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_roost']!.dartBehavior,
        'HealMoveBehavior.roost',
      );
      expect(
        byMethod['s_shore_up']!.dartBehavior,
        'HealMoveBehavior.shoreUp',
      );
      expect(
        byMethod['s_life_dew']!.dartBehavior,
        'HealMoveBehavior.lifeDew',
      );
      expect(
        byMethod['s_jungle_healing']!.dartBehavior,
        'HealMoveBehavior.jungleHealing',
      );
      expect(
        byMethod['s_jungle_healing']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.targetingMulti,
        ]),
      );
      expect(byMethod['s_rest']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_bellydrum']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_strength_sap']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_fillet_away']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_smelling_salt']!.dartBehavior,
        'HitThenCureStatusMoveBehavior.smellingSalt',
      );
      expect(byMethod['s_smelling_salt']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_smelling_salt']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.handlerStatus,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_wakeup_slap']!.dartBehavior,
        'HitThenCureStatusMoveBehavior.wakeUpSlap',
      );
      expect(byMethod['s_wakeup_slap']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_wakeup_slap']!.dependencies,
        contains(PsdkMoveDependency.ability),
      );
      expect(
        byMethod['s_sparkling_aria']!.dartBehavior,
        'HitThenCureStatusMoveBehavior.sparklingAria',
      );
      expect(byMethod['s_sparkling_aria']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_acrobatics']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_growth']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_growth']!.dartBehavior,
        'AdvancedStatMoveBehavior.growth',
      );
      expect(byMethod['s_haze']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_haze']!.dartBehavior,
        'AdvancedStatMoveBehavior.haze',
      );
      expect(byMethod['s_psych_up']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_psych_up']!.dartBehavior,
        'AdvancedStatMoveBehavior.psychUp',
      );
      expect(byMethod['s_topsy_turvy']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_topsy_turvy']!.dartBehavior,
        'AdvancedStatMoveBehavior.topsyTurvy',
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

    test('does not contain duplicate battleEngineMethod entries', () {
      final methods = psdkMoveRegistryManifest
          .map((entry) => entry.battleEngineMethod)
          .toList(growable: false);

      expect(methods.toSet(), hasLength(methods.length));
      expect(methods, orderedEquals([...methods]..sort()));
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
              '| `s_basic` | `Basic` | `10 Move/1 Mechanics/100 Basic.rb` | `StaticBasicMoveRegistry.s_basic` | `partial` | `-` |'));
      expect(
          markdown,
          contains(
              '| `s_custom_move` | `CustomMove` | `10 Move/1 Mechanics/300 Custom.rb` | `TODO` | `missing` | `-` |'));

      final dart = manifest.readAsStringSync();
      expect(dart, contains('const psdkMoveRegistryManifest'));
      expect(dart, contains("battleEngineMethod: 's_basic'"));
      expect(dart, contains('PsdkPortStatus.partial'));
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
