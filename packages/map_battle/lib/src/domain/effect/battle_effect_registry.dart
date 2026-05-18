import 'battle_effect.dart';
import 'battle_effect_scope.dart';
import 'field/pledge_field_effects.dart';
import 'field/wish_effect.dart';
import 'mechanics/mechanics_effects.dart';
import 'move/aqua_ring_effect.dart';
import 'move/attract_effect.dart';
import 'move/baton_pass_effect.dart';
import 'move/bind_effect.dart';
import 'move/cant_switch_effect.dart';
import 'move/confusion_effect.dart';
import 'move/curse_effect.dart';
import 'move/disable_effect.dart';
import 'move/embargo_effect.dart';
import 'move/encore_effect.dart';
import 'move/endure_effect.dart';
import 'move/flinch_effect.dart';
import 'move/force_next_move_base_effect.dart';
import 'move/focus_punch_effect.dart';
import 'move/happy_hour_effect.dart';
import 'move/heal_block_effect.dart';
import 'move/imprison_effect.dart';
import 'move/ingrain_effect.dart';
import 'move/leech_seed_effect.dart';
import 'move/nightmare_effect.dart';
import 'move/perish_song_effect.dart';
import 'move/magic_coat_effect.dart';
import 'move/powder_effect.dart';
import 'move/protect_effect.dart';
import 'move/salt_cure_effect.dart';
import 'move/smack_down_effect.dart';
import 'move/snatch_effect.dart';
import 'move/substitute_effect.dart';
import 'move/syrup_bomb_effect.dart';
import 'move/taunt_effect.dart';
import 'move/tar_shot_effect.dart';
import 'move/throat_chop_effect.dart';
import 'move/torment_effect.dart';
import 'move/two_turn_charge_effect.dart';
import '../../psdk/domain/psdk_battle_slots.dart';

/// Small id-to-effect factory used by compatibility constructors.
///
/// FIGHT-03 only registers Protect because it is the only active migrated
/// effect. Unknown ids intentionally become passive generic effects instead of
/// failing: existing tests and setup fixtures can still carry dependency ids
/// such as `gravity` before their behavior lots are implemented.
final class BattleEffectRegistry {
  const BattleEffectRegistry();

  BattleEffect fromId(String id) {
    return switch (id) {
      'aqua_ring' => const AquaRingEffect(scope: LocalBattleEffectScope()),
      'attract' => const AttractEffect(scope: LocalBattleEffectScope()),
      'baton_pass' => const BatonPassEffect(scope: LocalBattleEffectScope()),
      'bind' => const BindEffect(
          scope: LocalBattleEffectScope(),
          origin: psdkOpponentSlot,
        ),
      'cant_switch' => const CantSwitchEffect(
          scope: LocalBattleEffectScope(),
          origin: psdkOpponentSlot,
        ),
      'confusion' => const ConfusionEffect(scope: LocalBattleEffectScope()),
      'curse' => const CurseEffect(scope: LocalBattleEffectScope()),
      'disable' => const DisableEffect(
          scope: LocalBattleEffectScope(),
          disabledMoveId: '',
        ),
      'embargo' => const EmbargoEffect(scope: LocalBattleEffectScope()),
      'endure' => const EndureEffect(scope: LocalBattleEffectScope()),
      'encore' => const EncoreEffect(
          scope: LocalBattleEffectScope(),
          encoredMoveId: '',
        ),
      'flinch' => const FlinchEffect(scope: LocalBattleEffectScope()),
      'force_next_move_base' =>
        const ForceNextMoveBaseEffect(scope: LocalBattleEffectScope()),
      'focus_punch' => const FocusPunchEffect(scope: LocalBattleEffectScope()),
      'happy_hour' => const HappyHourEffect(scope: LocalBattleEffectScope()),
      'heal_block' => const HealBlockEffect(scope: LocalBattleEffectScope()),
      'imprison' => ImprisonEffect(scope: const LocalBattleEffectScope()),
      'ingrain' => const IngrainEffect(scope: LocalBattleEffectScope()),
      'leech_seed' => const LeechSeedEffect(
          scope: LocalBattleEffectScope(),
          source: psdkOpponentSlot,
        ),
      'nightmare' => const NightmareEffect(scope: LocalBattleEffectScope()),
      'perish_song' => const PerishSongEffect(scope: LocalBattleEffectScope()),
      'magic_coat' => const MagicCoatEffect(scope: LocalBattleEffectScope()),
      'powder' => const PowderEffect(scope: LocalBattleEffectScope()),
      'protect' => const ProtectEffect(scope: LocalBattleEffectScope()),
      'pledge_rainbow' =>
        const RainbowPledgeEffect(scope: LocalBattleEffectScope()),
      'pledge_sea_of_fire' =>
        const SeaOfFirePledgeEffect(scope: LocalBattleEffectScope()),
      'pledge_swamp' =>
        const SwampPledgeEffect(scope: LocalBattleEffectScope()),
      'baneful_bunker' =>
        const BanefulBunkerEffect(scope: LocalBattleEffectScope()),
      'burning_bulwark' =>
        const BurningBulwarkEffect(scope: LocalBattleEffectScope()),
      'king_s_shield' =>
        const KingsShieldEffect(scope: LocalBattleEffectScope()),
      'obstruct' => const ObstructEffect(scope: LocalBattleEffectScope()),
      'silk_trap' => const SilkTrapEffect(scope: LocalBattleEffectScope()),
      'spiky_shield' =>
        const SpikyShieldEffect(scope: LocalBattleEffectScope()),
      'salt_cure' => const SaltCureEffect(scope: LocalBattleEffectScope()),
      'smack_down' => const SmackDownEffect(scope: LocalBattleEffectScope()),
      'snatch' => const SnatchEffect(scope: LocalBattleEffectScope()),
      'snatched' => const SnatchedEffect(scope: LocalBattleEffectScope()),
      'substitute' => const SubstituteEffect(
          scope: LocalBattleEffectScope(),
          remainingHp: 1,
        ),
      'syrup_bomb' => const SyrupBombEffect(scope: LocalBattleEffectScope()),
      'taunt' => const TauntEffect(scope: LocalBattleEffectScope()),
      'tar_shot' => const TarShotEffect(scope: LocalBattleEffectScope()),
      'throat_chop' => const ThroatChopEffect(scope: LocalBattleEffectScope()),
      'torment' => const TormentEffect(scope: LocalBattleEffectScope()),
      'two_turn_charge' => const TwoTurnChargeEffect(
          scope: LocalBattleEffectScope(),
          chargedMoveId: '',
          chargedTarget: psdkOpponentSlot,
        ),
      'wish' => const WishEffect(
          scope: LocalBattleEffectScope(),
          healAmount: 1,
          remainingTurns: 2,
        ),
      'effect_base' => const PsdkEffectBaseEffect(),
      'effects_handler' => const PsdkEffectsHandlerEffect(),
      'pokemon_tied_effect_base' =>
        const PsdkPokemonTiedEffectBaseEffect(scope: LocalBattleEffectScope()),
      'position_tied_effect_base' =>
        const PsdkPositionTiedEffectBaseEffect(scope: LocalBattleEffectScope()),
      final value => GenericBattleEffect(id: value),
    };
  }
}
