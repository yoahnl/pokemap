import '../../move/battle_move_prevention.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../handler/battle_damage_handler.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_stat_change_handler.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../move/battle_move_data.dart';
import '../battle_effect.dart';
import '../battle_effect_hooks.dart';
import '../battle_effect_scope.dart';

/// PSDK Protect effect object.
///
/// PSDK variants share the same target-prevention shape and only differ in
/// status-move passthrough plus contact punishment.
final class ProtectEffect extends BattleEffect {
  const ProtectEffect({
    required BattleEffectScope scope,
    String id = 'protect',
    bool blocksStatusMoves = true,
    _ProtectContactPunishment contactPunishment =
        _ProtectContactPunishment.none,
  })  : _blocksStatusMoves = blocksStatusMoves,
        _contactPunishment = contactPunishment,
        super(
          id: id,
          scope: scope,
          remainingTurns: 0,
        );

  final bool _blocksStatusMoves;
  final _ProtectContactPunishment _contactPunishment;

  @override
  BattleEffect copyWithRemainingTurns(int remainingTurns) {
    return ProtectEffect(
      id: id,
      scope: scope,
      blocksStatusMoves: _blocksStatusMoves,
      contactPunishment: _contactPunishment,
    );
  }

  @override
  BattleMoveFailureReason? onMovePreventionTarget(
    BattleEffectMoveContext context,
  ) {
    if (!_blocks(
      userBank: context.user.bank,
      userPosition: context.user.position,
      targetBank: context.target.bank,
      targetPosition: context.target.position,
      move: context.move,
    )) {
      return null;
    }
    return BattleMoveFailureReason.protected;
  }

  @override
  BattleEffectDamagePreventionResult? onDamagePrevention(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!_blocks(
      userBank: context.user.bank,
      userPosition: context.user.position,
      targetBank: context.target.bank,
      targetPosition: context.target.position,
      move: context.move,
    )) {
      return null;
    }

    final punishment = _applyContactPunishment(context);

    return BattleEffectDamagePreventionResult(
      state: punishment.state,
      rng: punishment.rng,
      prevented: true,
      reason: BattleMoveFailureReason.protected,
      applied: false,
      events: <PsdkBattleEvent>[
        PsdkBattleMoveFailedEvent(
          user: context.user,
          target: context.target,
          moveId: context.move.id,
          reason: BattleMoveFailureReason.protected.jsonName,
        ),
        ...punishment.events,
      ],
    );
  }

  bool _blocks({
    required int userBank,
    required int userPosition,
    required int targetBank,
    required int targetPosition,
    required BattleMoveDefinition move,
  }) {
    if ((userBank == targetBank && userPosition == targetPosition) ||
        !move.flags.protectable) {
      return false;
    }
    if (!_blocksStatusMoves && move.category == PsdkBattleMoveCategory.status) {
      return false;
    }

    final scope = this.scope;
    if (scope is BattlerBattleEffectScope) {
      return scope.slot.bank == targetBank &&
          scope.slot.position == targetPosition;
    }
    return true;
  }

  BattleEffectPostDamageResult _applyContactPunishment(
    BattleEffectDamagePreventionContext context,
  ) {
    if (!context.move.flags.contact ||
        _contactPunishment == _ProtectContactPunishment.none) {
      return BattleEffectPostDamageResult(
        state: context.state,
        rng: context.rng,
      );
    }

    final handlerContext = BattleHandlerContext(
      state: context.state,
      rng: context.rng,
      turn: context.turn,
      user: context.target,
    );
    switch (_contactPunishment) {
      case _ProtectContactPunishment.none:
        return BattleEffectPostDamageResult(
          state: context.state,
          rng: context.rng,
        );
      case _ProtectContactPunishment.spikyDamage:
        final user = context.state.battlerAt(context.user);
        final damage = (user.maxHp / 8).floor().clamp(1, user.maxHp).toInt();
        final result = const BattleDamageHandler().applyDamage(
          context: handlerContext,
          target: context.user,
          moveId: 'effect:$id',
          rawDamage: damage,
        );
        return BattleEffectPostDamageResult(
          state: result.state,
          rng: result.rng,
          events: result.events,
        );
      case _ProtectContactPunishment.attackDown:
        final result = const BattleStatChangeHandler().applyStatChange(
          context: handlerContext,
          target: context.user,
          stat: 'attack',
          stages: -1,
          move: context.move,
        );
        return BattleEffectPostDamageResult(
          state: result.state,
          rng: result.rng,
          events: result.events,
        );
      case _ProtectContactPunishment.defenseDown:
        final result = const BattleStatChangeHandler().applyStatChange(
          context: handlerContext,
          target: context.user,
          stat: 'defense',
          stages: -2,
          move: context.move,
        );
        return BattleEffectPostDamageResult(
          state: result.state,
          rng: result.rng,
          events: result.events,
        );
      case _ProtectContactPunishment.speedDown:
        final result = const BattleStatChangeHandler().applyStatChange(
          context: handlerContext,
          target: context.user,
          stat: 'speed',
          stages: -1,
          move: context.move,
        );
        return BattleEffectPostDamageResult(
          state: result.state,
          rng: result.rng,
          events: result.events,
        );
      case _ProtectContactPunishment.poison:
        final result = const BattleStatusChangeHandler().applyMajorStatus(
          context: handlerContext,
          target: context.user,
          moveId: 'effect:$id',
          status: PsdkBattleMajorStatus.poison,
          move: context.move,
        );
        return BattleEffectPostDamageResult(
          state: result.state,
          rng: result.rng,
          events: result.events,
          applied: result.applied,
        );
      case _ProtectContactPunishment.burn:
        final result = const BattleStatusChangeHandler().applyMajorStatus(
          context: handlerContext,
          target: context.user,
          moveId: 'effect:$id',
          status: PsdkBattleMajorStatus.burn,
          move: context.move,
        );
        return BattleEffectPostDamageResult(
          state: result.state,
          rng: result.rng,
          events: result.events,
          applied: result.applied,
        );
    }
  }
}

final class SpikyShieldEffect extends ProtectEffect {
  const SpikyShieldEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'spiky_shield',
          scope: scope,
          contactPunishment: _ProtectContactPunishment.spikyDamage,
        );
}

final class KingsShieldEffect extends ProtectEffect {
  const KingsShieldEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'king_s_shield',
          scope: scope,
          blocksStatusMoves: false,
          contactPunishment: _ProtectContactPunishment.attackDown,
        );
}

final class SilkTrapEffect extends ProtectEffect {
  const SilkTrapEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'silk_trap',
          scope: scope,
          blocksStatusMoves: false,
          contactPunishment: _ProtectContactPunishment.speedDown,
        );
}

final class ObstructEffect extends ProtectEffect {
  const ObstructEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'obstruct',
          scope: scope,
          blocksStatusMoves: false,
          contactPunishment: _ProtectContactPunishment.defenseDown,
        );
}

final class BanefulBunkerEffect extends ProtectEffect {
  const BanefulBunkerEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'baneful_bunker',
          scope: scope,
          contactPunishment: _ProtectContactPunishment.poison,
        );
}

final class BurningBulwarkEffect extends ProtectEffect {
  const BurningBulwarkEffect({
    required BattleEffectScope scope,
  }) : super(
          id: 'burning_bulwark',
          scope: scope,
          blocksStatusMoves: false,
          contactPunishment: _ProtectContactPunishment.burn,
        );
}

enum _ProtectContactPunishment {
  none,
  spikyDamage,
  attackDown,
  defenseDown,
  speedDown,
  poison,
  burn,
}
