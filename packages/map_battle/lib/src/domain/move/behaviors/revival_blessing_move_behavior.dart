import '../../../psdk/domain/psdk_battle_combatant.dart';
import '../../../psdk/domain/psdk_battle_move.dart';
import '../../../psdk/domain/psdk_battle_slots.dart';
import '../../../psdk/domain/psdk_battle_state.dart';
import '../../../psdk/domain/psdk_battle_timeline.dart';
import '../battle_move_behavior.dart';
import '../battle_move_data.dart';
import '../battle_move_prevention.dart';
import 'battle_move_behavior_support.dart';

/// Ports Pokemon SDK's `RevivalBlessing` battle method.
///
/// PSDK opens the party UI for player-controlled users and auto-picks the
/// highest-level fainted ally for AI. The pure battle engine has no party-menu
/// choice seam yet, so it uses the same deterministic highest-level selection
/// for every bank until runtime can pass an explicit party choice.
final class RevivalBlessingMoveBehavior
    implements BattleMoveUserPreventionBehavior {
  const RevivalBlessingMoveBehavior();

  @override
  String get battleEngineMethod => 's_revival_blessing';

  @override
  BattleMoveUserPreventionResult? preventUser(
    BattleMoveBehaviorContext context,
  ) {
    if (_revivalTarget(context.state, context.user.bank) != null) {
      return null;
    }
    return const BattleMoveUserPreventionResult(
      reason: BattleMoveFailureReason.unusableByUser,
    );
  }

  @override
  BattleMoveBehaviorResolution resolve(BattleMoveBehaviorContext context) {
    final prevention = preventUser(context);
    if (prevention != null) {
      return BattleMoveBehaviorResolution(
        state: context.state,
        rng: context.rng,
        events: <PsdkBattleEvent>[
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.user,
            moveId: context.move.id,
            reason: prevention.reason.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final procedureContext = _contextWithMove(
      context,
      context.move.copyWith(target: PsdkBattleMoveTarget.self),
    );
    final prepared = prepareBattleMove(procedureContext);
    if (!prepared.shouldExecuteBehavior) {
      return prepared.toResolution();
    }

    final target = _revivalTarget(prepared.state, context.user.bank);
    if (target == null) {
      return BattleMoveBehaviorResolution(
        state: prepared.state,
        rng: prepared.rng,
        events: <PsdkBattleEvent>[
          ...prepared.events,
          PsdkBattleMoveFailedEvent(
            user: context.user,
            target: context.user,
            moveId: context.move.id,
            reason: BattleMoveFailureReason.unusableByUser.jsonName,
          ),
        ],
        successful: false,
      );
    }

    final revivedHp = _revivedHp(target.battler.maxHp);
    final revived = target.battler.copyWith(currentHp: revivedHp);
    final state = _replacePartyMember(
      prepared.state,
      bank: context.user.bank,
      partyIndex: target.partyIndex,
      battler: revived,
    );

    return BattleMoveBehaviorResolution(
      state: state,
      rng: prepared.rng,
      events: <PsdkBattleEvent>[
        ...prepared.events,
        PsdkBattleReviveEvent(
          user: context.user,
          bank: context.user.bank,
          partyIndex: target.partyIndex,
          moveId: context.move.id,
          amount: revivedHp,
          remainingHp: revived.currentHp,
          speciesId: revived.speciesId,
          displayName: revived.displayName,
        ),
      ],
    );
  }
}

BattleMoveBehaviorContext _contextWithMove(
  BattleMoveBehaviorContext context,
  BattleMoveDefinition move,
) {
  return BattleMoveBehaviorContext(
    state: context.state,
    rng: context.rng,
    turn: context.turn,
    user: context.user,
    target: context.user,
    move: move,
    canFlee: context.canFlee,
    moveSlot: context.moveSlot,
    isLastActionOfTurn: context.isLastActionOfTurn,
    moveProcedureHooks: context.moveProcedureHooks,
    announcedMoveFor: context.announcedMoveFor,
  );
}

_RevivalTarget? _revivalTarget(PsdkBattleState state, int bank) {
  final party = state.partyForBank(bank);
  _RevivalTarget? best;
  for (var index = 0; index < party.length; index += 1) {
    final battler = party[index];
    if (!battler.isFainted) {
      continue;
    }
    final current = best;
    if (current == null ||
        battler.level > current.battler.level ||
        (battler.level == current.battler.level &&
            index < current.partyIndex)) {
      best = _RevivalTarget(partyIndex: index, battler: battler);
    }
  }
  return best;
}

int _revivedHp(int maxHp) {
  final half = maxHp ~/ 2;
  if (half < 1) {
    return 1;
  }
  return half;
}

PsdkBattleState _replacePartyMember(
  PsdkBattleState state, {
  required int bank,
  required int partyIndex,
  required PsdkBattleCombatant battler,
}) {
  final parties = state.parties;
  final party = List<PsdkBattleCombatant>.of(state.partyForBank(bank));
  party[partyIndex] = battler;

  final combatants = <PsdkBattleSlotRef, PsdkBattleCombatant>{
    ...state.combatants,
  };
  for (final entry in combatants.entries.toList(growable: false)) {
    if (entry.value.id == battler.id) {
      combatants[entry.key] = battler;
    }
  }

  return state.copyWith(
    combatants: combatants,
    parties: <int, List<PsdkBattleCombatant>>{
      ...parties,
      bank: party,
    },
  );
}

final class _RevivalTarget {
  const _RevivalTarget({
    required this.partyIndex,
    required this.battler,
  });

  final int partyIndex;
  final PsdkBattleCombatant battler;
}
