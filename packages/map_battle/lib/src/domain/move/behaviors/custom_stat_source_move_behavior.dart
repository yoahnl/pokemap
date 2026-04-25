import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _CustomStatSourceKind {
  bodyPress,
  foulPlay,
  psyshock,
  customStatsBased,
}

/// Ports PSDK moves that keep the normal damage formula but swap stat sources.
///
/// Ruby PSDK implements these as subclasses overriding `calc_sp_atk_basis` and
/// `calc_atk_stat_modifier`, not as dynamic-power moves. This behavior keeps
/// that boundary: it resolves the exact offensive/defensive stats for one hit,
/// then delegates the rest of damage, RNG, STAB, type and secondary effects to
/// the shared calculator/pipeline.
final class CustomStatSourceMoveBehavior implements BattleMoveBehavior {
  const CustomStatSourceMoveBehavior.bodyPress()
      : battleEngineMethod = 's_body_press',
        _kind = _CustomStatSourceKind.bodyPress;

  const CustomStatSourceMoveBehavior.foulPlay()
      : battleEngineMethod = 's_foul_play',
        _kind = _CustomStatSourceKind.foulPlay;

  const CustomStatSourceMoveBehavior.psyshock()
      : battleEngineMethod = 's_psyshock',
        _kind = _CustomStatSourceKind.psyshock;

  const CustomStatSourceMoveBehavior.customStatsBased()
      : battleEngineMethod = 's_custom_stats_based',
        _kind = _CustomStatSourceKind.customStatsBased;

  @override
  final String battleEngineMethod;
  final _CustomStatSourceKind _kind;

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    _guardSupportedCustomStatsDbSymbol(context);

    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        overrides: BattleMoveDamageOverrides(
          offensiveStatResolver: (isCritical) => _offensiveStat(
            user: user,
            target: target,
            isCritical: isCritical,
          ),
          defensiveStatResolver: (isCritical) => _defensiveStat(
            target: target,
            isCritical: isCritical,
          ),
        ),
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyDirectDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      amount: damageResult.damage,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: damageResult.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
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

  int _offensiveStat({
    required PsdkBattleCombatant user,
    required PsdkBattleCombatant target,
    required bool isCritical,
  }) {
    return switch (_kind) {
      _CustomStatSourceKind.bodyPress => user.effectiveStat(
          'defense',
          // PSDK BodyPress returns stage modifier 1 on critical hit, ignoring
          // both positive Defense boosts and negative Defense drops.
          ignoreAllStages: isCritical,
        ),
      _CustomStatSourceKind.foulPlay => target.effectiveStat(
          'attack',
          // PSDK FoulPlay also returns stage modifier 1 on critical hit, using
          // the target's raw Attack instead of any target Attack stage.
          ignoreAllStages: isCritical,
        ),
      _CustomStatSourceKind.psyshock ||
      _CustomStatSourceKind.customStatsBased =>
        user.effectiveStat(
          'specialAttack',
          // PSDK CustomStatsBased follows the base offensive critical rule:
          // negative drops are ignored, positive boosts are kept.
          ignoreNegativeStage: isCritical,
        ),
    };
  }

  int _defensiveStat({
    required PsdkBattleCombatant target,
    required bool isCritical,
  }) {
    // The three supported families route defense like a physical PSDK move:
    // target Defense is used, positive defensive boosts are ignored on crit,
    // and negative defensive drops still make the hit stronger.
    return target.effectiveStat(
      'defense',
      ignorePositiveStage: isCritical,
    );
  }

  void _guardSupportedCustomStatsDbSymbol(BattleMoveBehaviorContext context) {
    if (_kind != _CustomStatSourceKind.customStatsBased) {
      return;
    }
    final dbSymbol = context.move.dbSymbol.trim().toLowerCase();
    if (dbSymbol == 'psyshock' || dbSymbol == 'secret_sword') {
      return;
    }
    throw UnsupportedError(
      'Unsupported s_custom_stats_based dbSymbol "${context.move.dbSymbol}".',
    );
  }
}
