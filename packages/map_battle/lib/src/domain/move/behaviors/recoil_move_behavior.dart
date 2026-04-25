import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const Map<String, int> _psdkRecoilFactors = <String, int>{
  'brave_bird': 3,
  'double_edge': 3,
  'chloroblast': 2,
  'flare_blitz': 3,
  'head_charge': 4,
  'head_smash': 2,
  'light_of_ruin': 2,
  'shadow_end': 2,
  'shadow_rush': 16,
  'struggle': 4,
  'submission': 4,
  'take_down': 4,
  'volt_tackle': 3,
  'wave_crash': 3,
  'wild_charge': 4,
  'wood_hammer': 3,
};

const Set<String> _recoilFromUserMaxHp = <String>{
  'struggle',
  'shadow_rush',
};

const Set<String> _recoilFromUserCurrentHp = <String>{
  'shadow_end',
};

/// Ports the base PSDK `RecoilMove` family.
///
/// The target hit still uses the normal damage formula and shared move
/// procedure. Recoil is represented as a second damage event targeting the
/// user. This is intentionally partial: abilities such as Rock Head and
/// Parental Bond, item callbacks, dedicated recoil messages and Basculin
/// evolution bookkeeping are not available in the current PSDK lane.
final class RecoilMoveBehavior implements BattleMoveBehavior {
  const RecoilMoveBehavior.psdkRecoil() : battleEngineMethod = 's_recoil';

  @override
  final String battleEngineMethod;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
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

    final targetDamage = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      amount: damageResult.damage,
    );
    var state = targetDamage.state;
    final events = <PsdkBattleEvent>[
      ...prepared.events,
      if (targetDamage.event != null) targetDamage.event!,
    ];
    if (targetDamage.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: state,
        rng: damageResult.rng,
        events: events,
      );
    }

    final recoilBase = _recoilBaseDamage(
      dbSymbol: context.move.dbSymbol,
      user: user,
      targetDamage: targetDamage.damage,
    );
    final recoilDamage = _recoilDamage(
      baseDamage: recoilBase,
      factor: _recoilFactor(context.move.dbSymbol),
    );
    final recoil = applyDirectDamage(
      state: state,
      user: context.user,
      target: context.user,
      moveId: context.move.id,
      amount: recoilDamage,
    );
    state = recoil.state;
    if (recoil.event != null) {
      events.add(recoil.event!);
    }

    // PSDK Basic applies recoil immediately after target damage and before
    // status/stat/effect riders. Keeping secondary effects after the self-hit
    // preserves that order for animation consumers and tests.
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
    );
    state = secondary.state;
    events.addAll(secondary.events);

    return BattleMoveBehaviorResolution(
      state: state,
      rng: secondary.rng,
      events: events,
    );
  }

  int _recoilFactor(String dbSymbol) {
    return _psdkRecoilFactors[dbSymbol] ?? 4;
  }

  int _recoilBaseDamage({
    required String dbSymbol,
    required PsdkBattleCombatant user,
    required int targetDamage,
  }) {
    if (_recoilFromUserMaxHp.contains(dbSymbol)) {
      return user.maxHp;
    }
    if (_recoilFromUserCurrentHp.contains(dbSymbol)) {
      return user.currentHp;
    }
    // PSDK `damages` clamps normal move damage to the target's current HP
    // before `recoil(hp, user)` receives it. `applyDirectDamage.damage` is the
    // same clamped amount in this Dart lane.
    return targetDamage;
  }

  int _recoilDamage({
    required int baseDamage,
    required int factor,
  }) {
    final damage = baseDamage ~/ factor;
    return damage < 1 ? 1 : damage;
  }
}
