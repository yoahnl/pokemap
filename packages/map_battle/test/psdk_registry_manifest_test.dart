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
      expect(byMethod['s_2turns']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_sacred_sword']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_sacred_sword']!.dartBehavior,
        'CustomStatSourceMoveBehavior.sacredSword',
      );
    });

    test('tracks the Lot 18 basic damage specialization slice', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      expect(byMethod['s_a_fang']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_a_fang']!.dartBehavior,
        'BasicDamageSpecializationMoveBehavior.fangs',
      );
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
      expect(byMethod['s_gigaton_hammer']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_gigaton_hammer']!.dartBehavior,
        'ForcedActionMoveBehavior.gigatonHammer',
      );
      expect(byMethod['s_outrage']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_outrage']!.dartBehavior,
        'ForcedActionMoveBehavior.outrage',
      );
      expect(byMethod['s_thrash']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_thrash']!.dartBehavior,
        'ForcedActionMoveBehavior.thrash',
      );
      expect(byMethod['s_uproar']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_uproar']!.dartBehavior,
        'ForcedActionMoveBehavior.uproar',
      );
      expect(byMethod['s_camouflage']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_camouflage']!.dartBehavior,
        'FieldLocationMoveBehavior.camouflage',
      );
      expect(byMethod['s_nature_power']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_nature_power']!.dartBehavior,
        'FieldLocationMoveBehavior.naturePower',
      );
      expect(byMethod['s_pledge']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_pledge']!.dartBehavior,
        'FieldLocationMoveBehavior.pledge',
      );
      expect(byMethod['s_secret_power']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_secret_power']!.dartBehavior,
        'FieldLocationMoveBehavior.secretPower',
      );
      expect(byMethod['s_synchronoise']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_synchronoise']!.dartBehavior,
        'FieldLocationMoveBehavior.synchronoise',
      );
      expect(byMethod['s_smack_down']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_smack_down']!.dartBehavior,
        'GroundingMoveBehavior.smackDown',
      );
      expect(byMethod['s_burn_up']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_burn_up']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.burnUp',
      );
      expect(byMethod['s_alluring_voice']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_alluring_voice']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.alluringVoice',
      );
      expect(byMethod['s_burning_jealousy']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_burning_jealousy']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.burningJealousy',
      );
      expect(byMethod['s_incinerate']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_incinerate']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.incinerate',
      );
      expect(byMethod['s_psychic_noise']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_psychic_noise']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.psychicNoise',
      );
      expect(byMethod['s_relic_song']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_relic_song']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.relicSong',
      );
      expect(byMethod['s_salt_cure']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_salt_cure']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.saltCure',
      );
      expect(byMethod['s_syrup_bomb']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_syrup_bomb']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.syrupBomb',
      );
      expect(byMethod['s_tar_shot']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_tar_shot']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.tarShot',
      );
      expect(byMethod['s_throat_chop']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_throat_chop']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.throatChop',
      );
      expect(byMethod['s_tri_attack']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_tri_attack']!.dartBehavior,
        'SpecialSecondaryMoveBehavior.triAttack',
      );
    });

    test('tracks the partial Basic-descendant move wave', () {
      final byMethod = {
        for (final entry in psdkMoveRegistryManifest)
          entry.battleEngineMethod: entry,
      };

      for (final method in <String>[
        's_beak_blast',
        's_core_enforcer',
        's_fake_out',
        's_feint',
        's_fell_stinger',
        's_flame_burst',
        's_flying_press',
        's_focus_punch',
        's_fusion_bolt',
        's_fusion_flare',
        's_hidden_power',
        's_jump_kick',
        's_last_resort',
        's_payday',
        's_photon_geyser',
        's_pollen_puff',
        's_pursuit',
        's_rage',
        's_round',
        's_shell_trap',
        's_spectral_thief',
        's_stomp',
        's_u_turn',
      ]) {
        expect(byMethod[method]!.status, PsdkPortStatus.partial);
        expect(
          byMethod[method]!.dartBehavior,
          'StaticBasicMoveRegistry.partialBasic($method)',
        );
      }
      expect(byMethod['s_sky_drop']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_sky_drop']!.dartBehavior,
        'StaticBasicMoveRegistry.s_sky_drop',
      );
      expect(byMethod['s_rapid_spin']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_rapid_spin']!.dartBehavior,
        'StaticBasicMoveRegistry.s_rapid_spin',
      );
      expect(byMethod['s_brick_break']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_brick_break']!.dartBehavior,
        'StaticBasicMoveRegistry.s_brick_break',
      );
      expect(byMethod['s_ceaseless_edge']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_ceaseless_edge']!.dartBehavior,
        'StaticBasicMoveRegistry.s_ceaseless_edge',
      );
      expect(byMethod['s_stone_axe']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_stone_axe']!.dartBehavior,
        'StaticBasicMoveRegistry.s_stone_axe',
      );
      expect(byMethod['s_cantflee']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_cantflee']!.dartBehavior,
        'StaticBasicMoveRegistry.s_cantflee',
      );
      expect(byMethod['s_snore']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_snore']!.dartBehavior,
        'ActionGatedMoveBehavior.snore',
      );
      expect(byMethod['s_sucker_punch']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_sucker_punch']!.dartBehavior,
        'ActionGatedMoveBehavior.suckerPunch',
      );
      expect(byMethod['s_hurricane']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_hurricane']!.dartBehavior,
        'WeatherPowerMoveBehavior.hurricane',
      );
      expect(byMethod['s_solar_beam']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_solar_beam']!.dartBehavior,
        'WeatherPowerMoveBehavior.solarBeam',
      );
      expect(byMethod['s_thunder']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_thunder']!.dartBehavior,
        'WeatherPowerMoveBehavior.thunder',
      );
      expect(byMethod['s_echo']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_echo']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.echoedVoice',
      );
      expect(byMethod['s_fury_cutter']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_fury_cutter']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.furyCutter',
      );
      expect(byMethod['s_ice_ball']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_ice_ball']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.iceBall',
      );
      expect(byMethod['s_rollout']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_rollout']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.rollout',
      );
      expect(byMethod['s_trump_card']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_trump_card']!.dartBehavior,
        'ConsecutivePowerMoveBehavior.trumpCard',
      );
      expect(byMethod['s_bide']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_bide']!.dartBehavior,
        'CounterDamageMoveBehavior.bide',
      );
      expect(byMethod['s_counter']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_counter']!.dartBehavior,
        'CounterDamageMoveBehavior.counter',
      );
      expect(byMethod['s_metal_burst']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_metal_burst']!.dartBehavior,
        'CounterDamageMoveBehavior.metalBurst',
      );
      expect(byMethod['s_mirror_coat']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_mirror_coat']!.dartBehavior,
        'CounterDamageMoveBehavior.mirrorCoat',
      );

      expect(byMethod['s_avalanche']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_avalanche']!.dartBehavior,
        'HistoryPowerMoveBehavior.avalanche',
      );
      expect(byMethod['s_assurance']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_assurance']!.dartBehavior,
        'HistoryPowerMoveBehavior.assurance',
      );
      expect(byMethod['s_fishious_rend']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_fishious_rend']!.dartBehavior,
        'HistoryPowerMoveBehavior.fishiousRend',
      );
      expect(byMethod['s_lash_out']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_lash_out']!.dartBehavior,
        'HistoryPowerMoveBehavior.lashOut',
      );
      expect(byMethod['s_payback']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_payback']!.dartBehavior,
        'HistoryPowerMoveBehavior.payback',
      );
      expect(byMethod['s_rage_fist']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_rage_fist']!.dartBehavior,
        'HistoryPowerMoveBehavior.rageFist',
      );
      expect(byMethod['s_retaliate']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_retaliate']!.dartBehavior,
        'HistoryPowerMoveBehavior.retaliate',
      );
      expect(byMethod['s_revenge']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_revenge']!.dartBehavior,
        'HistoryPowerMoveBehavior.revenge',
      );
      expect(byMethod['s_stomping_tantrum']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_stomping_tantrum']!.dartBehavior,
        'HistoryPowerMoveBehavior.stompingTantrum',
      );
      expect(byMethod['s_ivy_cudgel']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_ivy_cudgel']!.dartBehavior,
        'TypeBasedMoveBehavior.ivyCudgel',
      );
      expect(byMethod['s_judgment']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_judgment']!.dartBehavior,
        'TypeBasedMoveBehavior.judgment',
      );
      expect(byMethod['s_multi_attack']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_multi_attack']!.dartBehavior,
        'TypeBasedMoveBehavior.multiAttack',
      );
      expect(byMethod['s_revelation_dance']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_revelation_dance']!.dartBehavior,
        'TypeBasedMoveBehavior.revelationDance',
      );
      expect(byMethod['s_bind']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_bind']!.dartBehavior,
        'StaticBasicMoveRegistry.s_bind',
      );
      expect(byMethod['s_dragon_tail']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_dragon_tail']!.dartBehavior,
        'StaticBasicMoveRegistry.forceSwitch(s_dragon_tail)',
      );
      expect(byMethod['s_roar']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_roar']!.dartBehavior,
        'StaticBasicMoveRegistry.forceSwitch(s_roar)',
      );
      expect(byMethod['s_substitute']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_substitute']!.dartBehavior,
        'StaticBasicMoveRegistry.s_substitute',
      );
      expect(byMethod['s_follow_me']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_follow_me']!.dartBehavior,
        'StaticBasicMoveRegistry.s_follow_me',
      );
      expect(byMethod['s_add_type']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_add_type']!.dartBehavior,
        'StaticBasicMoveRegistry.s_add_type',
      );
      expect(byMethod['s_foresight']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_foresight']!.dartBehavior,
        'StaticBasicMoveRegistry.s_foresight',
      );
      expect(byMethod['s_thing_sport']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_thing_sport']!.dartBehavior,
        'StaticBasicMoveRegistry.s_thing_sport',
      );
      expect(byMethod['s_trick']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_trick']!.dartBehavior,
        'StaticBasicMoveRegistry.s_trick',
      );
      for (final entry in <({String method, String behavior})>[
        (method: 's_belch', behavior: 'ItemDependentMoveBehavior.belch'),
        (method: 's_bestow', behavior: 'ItemDependentMoveBehavior.bestow'),
        (method: 's_fling', behavior: 'ItemDependentMoveBehavior.fling'),
        (method: 's_knock_off', behavior: 'ItemDependentMoveBehavior.knockOff'),
        (
          method: 's_natural_gift',
          behavior: 'ItemDependentMoveBehavior.naturalGift',
        ),
        (method: 's_pluck', behavior: 'ItemDependentMoveBehavior.pluck'),
        (method: 's_recycle', behavior: 'ItemDependentMoveBehavior.recycle'),
        (
          method: 's_techno_blast',
          behavior: 'ItemDependentMoveBehavior.technoBlast',
        ),
        (method: 's_thief', behavior: 'ItemDependentMoveBehavior.thief'),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.partial);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      for (final entry in <({String method, String behavior})>[
        (
          method: 's_attract',
          behavior: 'StaticBasicMoveRegistry.attract',
        ),
        (
          method: 's_after_you',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_after_you)',
        ),
        (
          method: 's_ally_switch',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_ally_switch)',
        ),
        (
          method: 's_autotomize',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_autotomize)',
        ),
        (
          method: 's_captivate',
          behavior: 'StaticBasicMoveRegistry.secondaryOnly(s_captivate)',
        ),
        (
          method: 's_ceaseless_edge',
          behavior: 'StaticBasicMoveRegistry.s_ceaseless_edge',
        ),
        (
          method: 's_charge',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_charge)',
        ),
        (
          method: 's_change_type',
          behavior: 'StaticBasicMoveRegistry.s_change_type',
        ),
        (
          method: 's_crafty_shield',
          behavior:
              'StaticBasicMoveRegistry.partialUserBankMarker(s_crafty_shield)',
        ),
        (
          method: 's_defog',
          behavior: 'StaticBasicMoveRegistry.s_defog',
        ),
        (
          method: 's_destiny_bond',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_destiny_bond)',
        ),
        (
          method: 's_disable',
          behavior: 'StaticBasicMoveRegistry.disable',
        ),
        (
          method: 's_electrify',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_electrify)',
        ),
        (
          method: 's_embargo',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_embargo)',
        ),
        (
          method: 's_encore',
          behavior: 'StaticBasicMoveRegistry.encore',
        ),
        (
          method: 's_entrainment',
          behavior:
              'StaticBasicMoveRegistry.partialAbilityChanging(s_entrainment)',
        ),
        (
          method: 's_focus_energy',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_focus_energy)',
        ),
        (
          method: 's_future_sight',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_future_sight)',
        ),
        (
          method: 's_gastro_acid',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_gastro_acid)',
        ),
        (
          method: 's_gravity',
          behavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_gravity)',
        ),
        (
          method: 's_grudge',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_grudge)',
        ),
        (
          method: 's_happy_hour',
          behavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_happy_hour)',
        ),
        (
          method: 's_heal_block',
          behavior: 'StaticBasicMoveRegistry.healBlock',
        ),
        (
          method: 's_imprison',
          behavior: 'StaticBasicMoveRegistry.imprison',
        ),
        (
          method: 's_ion_deluge',
          behavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_ion_deluge)',
        ),
        (
          method: 's_lucky_chant',
          behavior:
              'StaticBasicMoveRegistry.partialUserBankMarker(s_lucky_chant)',
        ),
        (
          method: 's_laser_focus',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_laser_focus)',
        ),
        (
          method: 's_lock_on',
          behavior: 'StaticBasicMoveRegistry.s_lock_on',
        ),
        (
          method: 's_magic_coat',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_magic_coat)',
        ),
        (
          method: 's_magic_room',
          behavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_magic_room)',
        ),
        (
          method: 's_magnet_rise',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_magnet_rise)',
        ),
        (
          method: 's_memento',
          behavior: 'StaticBasicMoveRegistry.s_memento',
        ),
        (
          method: 's_minimize',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_minimize)',
        ),
        (
          method: 's_mind_reader',
          behavior: 'StaticBasicMoveRegistry.s_mind_reader',
        ),
        (
          method: 's_miracle_eye',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_miracle_eye)',
        ),
        (
          method: 's_mist',
          behavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_mist)',
        ),
        (
          method: 's_nightmare',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_nightmare)',
        ),
        (
          method: 's_perish_song',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_perish_song)',
        ),
        (
          method: 's_parting_shot',
          behavior: 'StaticBasicMoveRegistry.secondaryOnly(s_parting_shot)',
        ),
        (
          method: 's_powder',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_powder)',
        ),
        (
          method: 's_plasma_fists',
          behavior: 'StaticBasicMoveRegistry.s_plasma_fists',
        ),
        (
          method: 's_quash',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_quash)',
        ),
        (
          method: 's_safe_guard',
          behavior:
              'StaticBasicMoveRegistry.partialUserBankMarker(s_safe_guard)',
        ),
        (
          method: 's_simple_beam',
          behavior:
              'StaticBasicMoveRegistry.partialAbilityChanging(s_simple_beam)',
        ),
        (
          method: 's_snatch',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_snatch)',
        ),
        (
          method: 's_spike',
          behavior: 'StaticBasicMoveRegistry.partialFoeBankMarker(s_spike)',
        ),
        (
          method: 's_stealth_rock',
          behavior:
              'StaticBasicMoveRegistry.partialFoeBankMarker(s_stealth_rock)',
        ),
        (
          method: 's_sticky_web',
          behavior:
              'StaticBasicMoveRegistry.partialFoeBankMarker(s_sticky_web)',
        ),
        (
          method: 's_stockpile',
          behavior: 'StaticBasicMoveRegistry.s_stockpile',
        ),
        (
          method: 's_stone_axe',
          behavior: 'StaticBasicMoveRegistry.s_stone_axe',
        ),
        (
          method: 's_tailwind',
          behavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_tailwind)',
        ),
        (
          method: 's_taunt',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_taunt)',
        ),
        (
          method: 's_telekinesis',
          behavior:
              'StaticBasicMoveRegistry.partialTargetMarker(s_telekinesis)',
        ),
        (
          method: 's_reflect_type',
          behavior: 'StaticBasicMoveRegistry.s_reflect_type',
        ),
        (
          method: 's_role_play',
          behavior:
              'StaticBasicMoveRegistry.partialAbilityChanging(s_role_play)',
        ),
        (
          method: 's_skill_swap',
          behavior:
              'StaticBasicMoveRegistry.partialAbilityChanging(s_skill_swap)',
        ),
        (
          method: 's_torment',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_torment)',
        ),
        (
          method: 's_toxic_thread',
          behavior: 'StaticBasicMoveRegistry.secondaryOnly(s_toxic_thread)',
        ),
        (
          method: 's_toxic_spike',
          behavior:
              'StaticBasicMoveRegistry.partialFoeBankMarker(s_toxic_spike)',
        ),
        (
          method: 's_trick_room',
          behavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_trick_room)',
        ),
        (
          method: 's_wish',
          behavior: 'StaticBasicMoveRegistry.partialUserBankMarker(s_wish)',
        ),
        (
          method: 's_wonder_room',
          behavior: 'StaticBasicMoveRegistry.partialFieldMarker(s_wonder_room)',
        ),
        (
          method: 's_worry_seed',
          behavior:
              'StaticBasicMoveRegistry.partialAbilityChanging(s_worry_seed)',
        ),
        (
          method: 's_yawn',
          behavior: 'StaticBasicMoveRegistry.partialTargetMarker(s_yawn)',
        ),
      ]) {
        expect(byMethod[entry.method]!.status, PsdkPortStatus.partial);
        expect(byMethod[entry.method]!.dartBehavior, entry.behavior);
      }
      expect(byMethod['s_reflect']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_reflect']!.dartBehavior,
        'StaticBasicMoveRegistry.s_reflect',
      );
      expect(byMethod['s_reload']!.status, PsdkPortStatus.partial);
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
        byMethod['s_stomp']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.accuracy,
        ]),
      );
      expect(
        byMethod['s_follow_me']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.actionOrder,
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
      expect(
        byMethod['s_jump_kick']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerDamage,
          PsdkMoveDependency.accuracy,
          PsdkMoveDependency.effects,
        ]),
      );
      expect(
        byMethod['s_reflect']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.effects,
          PsdkMoveDependency.item,
          PsdkMoveDependency.weather,
        ]),
      );
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
      expect(byMethod['s_splash']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_splash']!.dartBehavior,
        'NoEffectMoveBehavior.splash',
      );
      expect(byMethod['s_ohko']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_ohko']!.dartBehavior, 'OhkoMoveBehavior');
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
      expect(byMethod['s_pain_split']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_recoil']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_recoil']!.dartBehavior,
        'RecoilMoveBehavior.psdkRecoil',
      );
      expect(byMethod['s_struggle']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_expanding_force']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_expanding_force']!.dartBehavior,
        'TerrainPowerMoveBehavior.expandingForce',
      );
      expect(byMethod['s_grassy_glide']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_grassy_glide']!.dartBehavior,
        'TerrainPowerMoveBehavior.grassyGlide',
      );
      expect(byMethod['s_rising_voltage']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_rising_voltage']!.dartBehavior,
        'TerrainPowerMoveBehavior.risingVoltage',
      );
      expect(byMethod['s_terrain']!.status, PsdkPortStatus.partial);
      expect(byMethod['s_terrain']!.dartBehavior, 'TerrainMoveBehavior');
      expect(byMethod['s_terrain_pulse']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_terrain_pulse']!.dartBehavior,
        'TerrainPowerMoveBehavior.terrainPulse',
      );
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
      expect(byMethod['s_aqua_ring']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_psycho_shift']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_purify']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_heal_bell']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_take_heart']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_take_heart']!.dartBehavior,
        'StatusCureMoveBehavior.takeHeart',
      );
      expect(byMethod['s_sparkly_swirl']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_sparkly_swirl']!.dartBehavior,
        'StatusCureMoveBehavior.sparklySwirl',
      );
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

      expect(byMethod['s_acupressure']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_acupressure']!.dartBehavior,
        'AdvancedStatMoveBehavior.acupressure',
      );
      expect(byMethod['s_clangorous_soul']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_clangorous_soul']!.dartBehavior,
        'AdvancedStatMoveBehavior.clangorousSoul',
      );
      expect(byMethod['s_curse']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_curse']!.dartBehavior,
        'AdvancedStatMoveBehavior.curse',
      );
      expect(byMethod['s_growth']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_growth']!.dartBehavior,
        'AdvancedStatMoveBehavior.growth',
      );
      expect(byMethod['s_guard_swap']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_guard_swap']!.dartBehavior,
        'AdvancedStatMoveBehavior.guardSwap',
      );
      expect(byMethod['s_haze']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_haze']!.dartBehavior,
        'AdvancedStatMoveBehavior.haze',
      );
      expect(byMethod['s_heart_swap']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_heart_swap']!.dartBehavior,
        'AdvancedStatMoveBehavior.heartSwap',
      );
      expect(byMethod['s_power_swap']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_power_swap']!.dartBehavior,
        'AdvancedStatMoveBehavior.powerSwap',
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

      expect(byMethod['s_aqua_ring']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_aqua_ring']!.dartBehavior,
        'PersistentEffectMoveBehavior.aquaRing',
      );
      expect(byMethod['s_ingrain']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_ingrain']!.dartBehavior,
        'PersistentEffectMoveBehavior.ingrain',
      );
      expect(byMethod['s_leech_seed']!.status, PsdkPortStatus.partial);
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

      expect(byMethod['s_baton_pass']!.status, PsdkPortStatus.partial);
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
      expect(byMethod['s_transform']!.status, PsdkPortStatus.partial);
      expect(
        byMethod['s_transform']!.dartBehavior,
        'TransformMoveBehavior',
      );
      expect(
        byMethod['s_transform']!.dependencies,
        containsAll(<PsdkMoveDependency>[
          PsdkMoveDependency.handlerSwitch,
          PsdkMoveDependency.effects,
          PsdkMoveDependency.ability,
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
