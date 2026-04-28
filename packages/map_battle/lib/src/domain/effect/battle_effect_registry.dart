import 'battle_effect.dart';
import 'battle_effect_scope.dart';
import 'move/aqua_ring_effect.dart';
import 'move/attract_effect.dart';
import 'move/baton_pass_effect.dart';
import 'move/bind_effect.dart';
import 'move/cant_switch_effect.dart';
import 'move/confusion_effect.dart';
import 'move/curse_effect.dart';
import 'move/disable_effect.dart';
import 'move/encore_effect.dart';
import 'move/force_next_move_base_effect.dart';
import 'move/heal_block_effect.dart';
import 'move/imprison_effect.dart';
import 'move/ingrain_effect.dart';
import 'move/protect_effect.dart';
import 'move/salt_cure_effect.dart';
import 'move/smack_down_effect.dart';
import 'move/syrup_bomb_effect.dart';
import 'move/taunt_effect.dart';
import 'move/tar_shot_effect.dart';
import 'move/throat_chop_effect.dart';
import 'move/torment_effect.dart';
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
      'encore' => const EncoreEffect(
          scope: LocalBattleEffectScope(),
          encoredMoveId: '',
        ),
      'force_next_move_base' =>
        const ForceNextMoveBaseEffect(scope: LocalBattleEffectScope()),
      'heal_block' => const HealBlockEffect(scope: LocalBattleEffectScope()),
      'imprison' => ImprisonEffect(scope: const LocalBattleEffectScope()),
      'ingrain' => const IngrainEffect(scope: LocalBattleEffectScope()),
      'protect' => const ProtectEffect(scope: LocalBattleEffectScope()),
      'salt_cure' => const SaltCureEffect(scope: LocalBattleEffectScope()),
      'smack_down' => const SmackDownEffect(scope: LocalBattleEffectScope()),
      'syrup_bomb' => const SyrupBombEffect(scope: LocalBattleEffectScope()),
      'taunt' => const TauntEffect(scope: LocalBattleEffectScope()),
      'tar_shot' => const TarShotEffect(scope: LocalBattleEffectScope()),
      'throat_chop' => const ThroatChopEffect(scope: LocalBattleEffectScope()),
      'torment' => const TormentEffect(scope: LocalBattleEffectScope()),
      final value => GenericBattleEffect(id: value),
    };
  }
}
