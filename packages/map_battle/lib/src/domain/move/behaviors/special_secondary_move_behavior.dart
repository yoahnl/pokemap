import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../../effect/ability/mental_immunity_ability_effect.dart';
import '../../effect/battle_effect.dart';
import '../../effect/battle_effect_hooks.dart';
import '../../effect/battle_effect_scope.dart';
import '../../effect/move/confusion_effect.dart';
import '../../effect/move/heal_block_effect.dart';
import '../../effect/move/salt_cure_effect.dart';
import '../../effect/move/syrup_bomb_effect.dart';
import '../../effect/move/tar_shot_effect.dart';
import '../../effect/move/throat_chop_effect.dart';
import '../../handler/battle_handler_context.dart';
import '../../handler/battle_status_change_handler.dart';
import '../../rng/battle_rng_streams.dart';
import '../battle_move_behavior.dart';
import '../battle_move_damage_calculator.dart';
import '../battle_move_prevention.dart';
import '../battle_move_secondary_effect_resolver.dart';
import 'battle_move_behavior_support.dart';

enum _SpecialSecondaryMoveKind {
  alluringVoice,
  burnUp,
  burningJealousy,
  incinerate,
  psychicNoise,
  relicSong,
  saltCure,
  syrupBomb,
  tarShot,
  throatChop,
  triAttack,
}

/// Ports PSDK Basic descendants with post-hit secondary behavior.
///
/// This is a local singles slice. Effects that need full sound-move filtering,
/// party form changes or a complete item database intentionally stay `partial`.
final class SpecialSecondaryMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const SpecialSecondaryMoveBehavior.alluringVoice()
      : battleEngineMethod = 's_alluring_voice',
        _kind = _SpecialSecondaryMoveKind.alluringVoice;

  const SpecialSecondaryMoveBehavior.burnUp()
      : battleEngineMethod = 's_burn_up',
        _kind = _SpecialSecondaryMoveKind.burnUp;

  const SpecialSecondaryMoveBehavior.burningJealousy()
      : battleEngineMethod = 's_burning_jealousy',
        _kind = _SpecialSecondaryMoveKind.burningJealousy;

  const SpecialSecondaryMoveBehavior.incinerate()
      : battleEngineMethod = 's_incinerate',
        _kind = _SpecialSecondaryMoveKind.incinerate;

  const SpecialSecondaryMoveBehavior.psychicNoise()
      : battleEngineMethod = 's_psychic_noise',
        _kind = _SpecialSecondaryMoveKind.psychicNoise;

  const SpecialSecondaryMoveBehavior.relicSong()
      : battleEngineMethod = 's_relic_song',
        _kind = _SpecialSecondaryMoveKind.relicSong;

  const SpecialSecondaryMoveBehavior.saltCure()
      : battleEngineMethod = 's_salt_cure',
        _kind = _SpecialSecondaryMoveKind.saltCure;

  const SpecialSecondaryMoveBehavior.syrupBomb()
      : battleEngineMethod = 's_syrup_bomb',
        _kind = _SpecialSecondaryMoveKind.syrupBomb;

  const SpecialSecondaryMoveBehavior.tarShot()
      : battleEngineMethod = 's_tar_shot',
        _kind = _SpecialSecondaryMoveKind.tarShot;

  const SpecialSecondaryMoveBehavior.throatChop()
      : battleEngineMethod = 's_throat_chop',
        _kind = _SpecialSecondaryMoveKind.throatChop;

  const SpecialSecondaryMoveBehavior.triAttack()
      : battleEngineMethod = 's_tri_attack',
        _kind = _SpecialSecondaryMoveKind.triAttack;

  @override
  final String battleEngineMethod;
  final _SpecialSecondaryMoveKind _kind;

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    return switch (_kind) {
      _SpecialSecondaryMoveKind.burnUp =>
        context.state.battlerAt(context.user).hasType(context.move.type)
            ? null
            : const BattleMoveUserPreventionResult(
                reason: BattleMoveFailureReason.unusableByUser,
              ),
      _ => null,
    };
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        successful: false,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.target,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
      );
    }

    final prepared = prepareBattleMove(context);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final targetSlot = prepared.psdkTargets.single;
    if (_kind == _SpecialSecondaryMoveKind.tarShot) {
      return _addTargetEffect(
        state: prepared.state,
        rng: prepared.rng,
        turn: context.turn,
        userSlot: context.user,
        targetSlot: targetSlot,
        moveId: context.move.id,
        effect: TarShotEffect(scope: BattlerBattleEffectScope(targetSlot)),
      ).toResolution(events: prepared.events);
    }
    final user = prepared.state.battlerAt(context.user);
    final target = prepared.state.battlerAt(targetSlot);
    final damageResult = const BattleMoveDamageCalculator().calculate(
      BattleMoveDamageContext(
        user: user,
        target: target,
        move: context.move,
        rng: prepared.rng,
        field: prepared.state.field,
        state: prepared.state,
        userSlot: context.user,
        targetSlot: targetSlot,
      ),
    );
    if (damageResult.damage <= 0) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: damageResult.rng,
        events: prepared.events,
      );
    }

    final applied = applyMoveTargetDamage(
      state: prepared.state,
      user: context.user,
      target: targetSlot,
      moveId: context.move.id,
      rng: damageResult.rng,
      turn: context.turn,
      amount: damageResult.damage,
      move: context.move,
    );
    final secondary = const BattleMoveSecondaryEffectResolver().resolve(
      state: applied.state,
      rng: applied.rng,
      user: context.user,
      target: targetSlot,
      move: context.move,
      turn: context.turn,
    );
    final special = _applySpecialSecondary(
      state: secondary.state,
      rng: secondary.rng,
      turn: context.turn,
      userSlot: context.user,
      targetSlot: targetSlot,
      moveId: context.move.id,
      moveType: context.move.type,
    );

    return BattleMoveBehaviorResolution(
      state: special.state,
      rng: special.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        ...applied.events,
        ...secondary.events,
        ...special.events,
      ],
    );
  }

  _SpecialSecondaryResult _applySpecialSecondary({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
    required String moveType,
  }) {
    return switch (_kind) {
      _SpecialSecondaryMoveKind.alluringVoice => _alluringVoice(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
        ),
      _SpecialSecondaryMoveKind.burnUp => _burnUp(
          state: state,
          rng: rng,
          userSlot: userSlot,
          moveType: moveType,
        ),
      _SpecialSecondaryMoveKind.burningJealousy => _burningJealousy(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
        ),
      _SpecialSecondaryMoveKind.incinerate => _incinerate(
          state: state,
          rng: rng,
          targetSlot: targetSlot,
        ),
      _SpecialSecondaryMoveKind.psychicNoise => _addTargetEffect(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
          effect: battleAromaVeilBlocksEffect(
            state: state,
            user: userSlot,
            target: targetSlot,
          )
              ? null
              : HealBlockEffect(
                  scope: BattlerBattleEffectScope(targetSlot),
                  remainingTurns: 3,
                ),
        ),
      _SpecialSecondaryMoveKind.relicSong =>
        _SpecialSecondaryResult(state: state, rng: rng),
      _SpecialSecondaryMoveKind.saltCure => _addTargetEffect(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
          effect: SaltCureEffect(scope: BattlerBattleEffectScope(targetSlot)),
        ),
      _SpecialSecondaryMoveKind.syrupBomb => _addTargetEffect(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
          effect: SyrupBombEffect(scope: BattlerBattleEffectScope(targetSlot)),
        ),
      _SpecialSecondaryMoveKind.tarShot =>
        _SpecialSecondaryResult(state: state, rng: rng),
      _SpecialSecondaryMoveKind.throatChop => _addTargetEffect(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
          effect: ThroatChopEffect(
            scope: BattlerBattleEffectScope(targetSlot),
          ),
        ),
      _SpecialSecondaryMoveKind.triAttack => _triAttack(
          state: state,
          rng: rng,
          turn: turn,
          userSlot: userSlot,
          targetSlot: targetSlot,
          moveId: moveId,
        ),
    };
  }

  _SpecialSecondaryResult _alluringVoice({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
  }) {
    if (!_wasBoostedThisTurn(state.battlerAt(targetSlot), turn) ||
        state.battlerAt(targetSlot).effects.contains('confusion') ||
        battleMentalAbilityBlocksEffect(
          state: state,
          user: userSlot,
          target: targetSlot,
          effectId: PsdkBattleEffectIds.confusion,
        )) {
      return _SpecialSecondaryResult(state: state, rng: rng);
    }
    final durationRoll = rng.generic.nextIntInclusive(min: 1, max: 4);
    return _SpecialSecondaryResult(
      state: state.updateBattler(
        targetSlot,
        (battler) => battler.copyWith(
          effects: battler.effects.addEffect(
            ConfusionEffect(
              scope: BattlerBattleEffectScope(targetSlot),
              remainingConfusionTurns: durationRoll.value + 1,
            ),
          ),
        ),
      ),
      rng: rng.copyWith(generic: durationRoll.next),
    );
  }

  _SpecialSecondaryResult _burningJealousy({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
  }) {
    if (!_wasBoostedThisTurn(state.battlerAt(targetSlot), turn)) {
      return _SpecialSecondaryResult(state: state, rng: rng);
    }
    final applied = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: state,
        rng: rng,
        turn: turn,
        user: userSlot,
      ),
      target: targetSlot,
      moveId: moveId,
      status: PsdkBattleMajorStatus.burn,
    );
    return _SpecialSecondaryResult(
      state: applied.state,
      rng: applied.rng,
      events: applied.events,
    );
  }

  _SpecialSecondaryResult _triAttack({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
  }) {
    final proc = rng.generic.nextChance(numerator: 20, denominator: 100);
    var nextRng = rng.copyWith(generic: proc.next);
    if (!proc.didOccur) {
      return _SpecialSecondaryResult(state: state, rng: nextRng);
    }

    final statusRoll = nextRng.generic.nextIntInclusive(min: 0, max: 2);
    nextRng = nextRng.copyWith(generic: statusRoll.next);
    final status = const <PsdkBattleMajorStatus>[
      PsdkBattleMajorStatus.paralysis,
      PsdkBattleMajorStatus.burn,
      PsdkBattleMajorStatus.freeze,
    ][statusRoll.value];
    final applied = const BattleStatusChangeHandler().applyMajorStatus(
      context: BattleHandlerContext(
        state: state,
        rng: nextRng,
        turn: turn,
        user: userSlot,
      ),
      target: targetSlot,
      moveId: moveId,
      status: status,
    );
    return _SpecialSecondaryResult(
      state: applied.state,
      rng: applied.rng,
      events: applied.events,
    );
  }

  _SpecialSecondaryResult _burnUp({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef userSlot,
    required String moveType,
  }) {
    return _SpecialSecondaryResult(
      state: state.updateBattler(
        userSlot,
        (battler) => _removeType(battler, moveType).copyWith(
          effects: battler.effects.addEffect(
            GenericBattleEffect(
              id: 'burn_up',
              scope: BattlerBattleEffectScope(userSlot),
            ),
          ),
        ),
      ),
      rng: rng,
    );
  }

  _SpecialSecondaryResult _incinerate({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required PsdkBattleSlotRef targetSlot,
  }) {
    final item = state.battlerAt(targetSlot).heldItemId;
    if (!_isIncineratableItem(item)) {
      return _SpecialSecondaryResult(state: state, rng: rng);
    }
    return _SpecialSecondaryResult(
      state: state.updateBattler(
        targetSlot,
        (battler) => battler
            .copyWith(
              heldItemId: null,
              consumedItemId: item,
              itemConsumed: true,
            )
            .withItemEffect(targetSlot),
      ),
      rng: rng,
    );
  }

  _SpecialSecondaryResult _addTargetEffect({
    required PsdkBattleState state,
    required BattleRngStreams rng,
    required int turn,
    required PsdkBattleSlotRef userSlot,
    required PsdkBattleSlotRef targetSlot,
    required String moveId,
    required BattleEffect? effect,
  }) {
    if (effect == null ||
        state.battlerAt(targetSlot).effects.contains(effect.id)) {
      return _SpecialSecondaryResult(state: state, rng: rng);
    }
    final installed = state.updateBattler(
      targetSlot,
      (battler) => battler.copyWith(
        effects: battler.effects.addEffect(effect),
      ),
    );
    final post = installed
        .battlerAt(targetSlot)
        .effects
        .dispatchPostVolatileStatusChange(
          BattleEffectVolatileStatusChangeContext(
            state: installed,
            rng: rng,
            turn: turn,
            owner: targetSlot,
            user: userSlot,
            target: targetSlot,
            effectId: effect.id,
            cured: false,
            moveId: moveId,
          ),
        );
    return _SpecialSecondaryResult(
      state: post.state,
      rng: post.rng,
      events: post.events,
    );
  }
}

PsdkBattleCombatant _removeType(PsdkBattleCombatant battler, String type) {
  final normalized = type.toLowerCase();
  final primary = battler.types.primary.toLowerCase();
  final secondary = battler.types.secondary?.toLowerCase();
  if (primary == normalized && secondary != null) {
    return battler.copyWith(
      types: PsdkBattleTypes(primary: battler.types.secondary!),
    );
  }
  if (primary == normalized) {
    return battler.copyWith(types: const PsdkBattleTypes(primary: 'normal'));
  }
  if (secondary == normalized) {
    return battler.copyWith(
      types: PsdkBattleTypes(primary: battler.types.primary),
    );
  }
  return battler.copyWith(
    type3: battler.type3?.toLowerCase() == normalized ? null : battler.type3,
    temporaryTypes: battler.temporaryTypes
        .where((value) => value.toLowerCase() != normalized)
        .toList(growable: false),
  );
}

bool _isIncineratableItem(String? itemId) {
  if (itemId == null) {
    return false;
  }
  return itemId.endsWith('_berry') || itemId.endsWith('_gem');
}

final class _SpecialSecondaryResult {
  const _SpecialSecondaryResult({
    required this.state,
    required this.rng,
    this.events = const <PsdkBattleEvent>[],
  });

  final PsdkBattleState state;
  final BattleRngStreams rng;
  final List<PsdkBattleEvent> events;

  BattleMoveBehaviorResolution toResolution({
    List<PsdkBattleEvent> events = const <PsdkBattleEvent>[],
  }) {
    return BattleMoveBehaviorResolution(
      state: state,
      rng: rng,
      events: <PsdkBattleEvent>[...events, ...this.events],
    );
  }
}

bool _wasBoostedThisTurn(PsdkBattleCombatant battler, int turn) {
  return battler.statHistory.entries.any(
    (entry) => entry.turn == turn && entry.delta > 0,
  );
}
