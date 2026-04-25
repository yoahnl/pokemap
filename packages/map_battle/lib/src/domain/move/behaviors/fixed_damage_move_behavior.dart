import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

const Map<String, int> _psdkFixedDamageByDbSymbol = <String, int>{
  'sonic_boom': 20,
  'dragon_rage': 40,
};

enum _FixedDamageKind {
  psdkFixedDamage,
  userLevel,
  psywave,
  halfCurrentTargetHp,
}

/// Ports PSDK move classes that override `damages` with a direct HP amount.
///
/// The shared pipeline still handles target resolution, accuracy, Protect and
/// type immunity. This class only replaces the normal formula after that point,
/// mirroring Ruby classes such as `FixedDamages`, `HPEqLevel`, `Psywave` and
/// `SuperFang`.
final class FixedDamageMoveBehavior implements BattleMoveBehavior {
  const FixedDamageMoveBehavior.psdkFixedDamage()
      : battleEngineMethod = 's_fixed_damage',
        _kind = _FixedDamageKind.psdkFixedDamage;

  const FixedDamageMoveBehavior.userLevel()
      : battleEngineMethod = 's_hp_eq_level',
        _kind = _FixedDamageKind.userLevel;

  const FixedDamageMoveBehavior.psywave()
      : battleEngineMethod = 's_psywave',
        _kind = _FixedDamageKind.psywave;

  const FixedDamageMoveBehavior.halfCurrentTargetHp()
      : battleEngineMethod = 's_super_fang',
        _kind = _FixedDamageKind.halfCurrentTargetHp;

  @override
  final String battleEngineMethod;
  final _FixedDamageKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final target = prepared.psdkTargets.single;
    final damage = _resolveDamage(
      context: context,
      prepared: prepared,
      target: target,
    );
    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: target,
      moveId: context.move.id,
      rng: damage.rng,
      turn: context.turn,
      amount: damage.amount,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: target,
      move: context.move,
      turn: context.turn,
    );

    return BattleMoveBehaviorResolution(
      state: secondary.state,
      rng: secondary.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        if (applied.event != null) applied.event!,
        ...secondary.events,
      ],
    );
  }

  _ResolvedFixedDamage _resolveDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
    required PsdkBattleSlotRef target,
  }) {
    return switch (_kind) {
      _FixedDamageKind.psdkFixedDamage => _ResolvedFixedDamage(
          amount: _psdkFixedDamageByDbSymbol[context.move.dbSymbol] ?? 1,
          rng: prepared.rng,
        ),
      _FixedDamageKind.userLevel => _ResolvedFixedDamage(
          amount: prepared.state.battlerAt(context.user).level,
          rng: prepared.rng,
        ),
      _FixedDamageKind.psywave => _resolvePsywaveDamage(
          context: context,
          prepared: prepared,
        ),
      _FixedDamageKind.halfCurrentTargetHp => _ResolvedFixedDamage(
          amount: _halfHpDamage(prepared.state.battlerAt(target).currentHp),
          rng: prepared.rng,
        ),
    };
  }

  _ResolvedFixedDamage _resolvePsywaveDamage({
    required BattleMoveBehaviorContext context,
    required PreparedBattleMove prepared,
  }) {
    final roll = prepared.rng.moveDamage.nextIntInclusive(min: 1, max: 100);
    final user = prepared.state.battlerAt(context.user);
    final amount = ((user.level * (roll.value + 50)) / 100).floor();
    return _ResolvedFixedDamage(
      amount: amount < 1 ? 1 : amount,
      rng: prepared.rng.copyWith(moveDamage: roll.next),
    );
  }

  int _halfHpDamage(int currentHp) {
    final amount = currentHp ~/ 2;
    return amount < 1 ? 1 : amount;
  }
}

final class _ResolvedFixedDamage {
  const _ResolvedFixedDamage({
    required this.amount,
    required this.rng,
  });

  final int amount;
  final BattleRngStreams rng;
}
