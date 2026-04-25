import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _DrainMoveKind {
  absorb,
  dreamEater,
}

/// Ports the PSDK drain family (`s_absorb` and `s_dream_eater`) for the common
/// HP-transfer path.
///
/// Full PSDK parity still depends on future drain-prevention hooks such as
/// Heal Block and item/ability modifiers. This behavior deliberately keeps the
/// local rule small: damage first, heal the user from the damage actually dealt.
final class DrainMoveBehavior implements BattleMoveBehavior {
  const DrainMoveBehavior.absorb()
      : battleEngineMethod = 's_absorb',
        _kind = _DrainMoveKind.absorb;

  const DrainMoveBehavior.dreamEater()
      : battleEngineMethod = 's_dream_eater',
        _kind = _DrainMoveKind.dreamEater;

  @override
  final String battleEngineMethod;
  final _DrainMoveKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final target = prepared.state.battlerAt(targetSlot);
    if (_kind == _DrainMoveKind.dreamEater && !_canDreamEaterAffect(target)) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleImmuneEvent(
            user: context.user,
            target: targetSlot,
            moveId: context.move.id,
          ),
        ],
        successful: false,
      );
    }

    final user = prepared.state.battlerAt(context.user);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final damage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
    );
    final healAmount = _drainHealAmount(
      damage: damage.damage,
      dbSymbol: context.move.dbSymbol,
    );
    final heal = applyDirectHeal(
      state: damage.state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      rng: damage.rng,
      turn: context.turn,
      amount: healAmount,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: heal.state,
      rng: heal.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (damage.event != null) damage.event!,
        if (heal.event != null) heal.event!,
        ...secondary.events,
      ],
    );
  }
}

bool _canDreamEaterAffect(PsdkBattleCombatant target) {
  return target.majorStatus == PsdkBattleMajorStatus.sleep ||
      target.abilityId == 'comatose';
}

int _drainHealAmount({
  required int damage,
  required String dbSymbol,
}) {
  final drainFactor =
      dbSymbol == 'draining_kiss' || dbSymbol == 'oblivion_wing' ? 4 / 3 : 2;
  final healed = (damage / drainFactor).floor();
  return healed < 1 ? 1 : healed;
}
