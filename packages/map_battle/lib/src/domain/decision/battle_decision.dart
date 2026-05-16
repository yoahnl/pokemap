import '../battle/battle_context.dart';
import '../move/battle_move_data.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';

/// Player-facing decisions accepted by the clean battle engine.
///
/// The legacy package already exposes many `PlayerBattleChoice*` classes. Lot 4
/// starts a separate PSDK-shaped command model so later lots can add target,
/// item and switch commands without inheriting the old Showdown-inspired names.
sealed class BattleDecision {
  const BattleDecision();

  const factory BattleDecision.fight({
    required int moveSlot,
    PsdkBattleSlotRef? target,
  }) = BattleFightDecision;

  const factory BattleDecision.switchPokemon({
    required int partyIndex,
  }) = BattleSwitchDecision;
}

final class BattleFightDecision extends BattleDecision {
  const BattleFightDecision({
    required this.moveSlot,
    this.target,
  });

  final int moveSlot;
  final PsdkBattleSlotRef? target;
}

final class BattleSwitchDecision extends BattleDecision {
  const BattleSwitchDecision({
    required this.partyIndex,
  });

  final int partyIndex;
}

enum BattleEngineDecisionRequestKind {
  turnChoice,
  noLegalChoice,
  finished,
}

/// One legal fight option in a clean battle request.
final class BattleMoveDecisionOption {
  const BattleMoveDecisionOption({
    required this.moveSlot,
    required this.moveId,
    required this.moveName,
    required this.pp,
    required this.target,
  });

  final int moveSlot;
  final String moveId;
  final String moveName;
  final int pp;
  final PsdkBattleMoveTarget target;
}

/// Current player-facing request produced by [BattleEngine].
final class BattleEngineDecisionRequest {
  BattleEngineDecisionRequest._({
    required this.kind,
    required this.actor,
    required List<BattleMoveDecisionOption> fightChoices,
  }) : fightChoices = List<BattleMoveDecisionOption>.unmodifiable(fightChoices);

  factory BattleEngineDecisionRequest.fromContext(BattleContext context) {
    if (!context.canBattleContinue) {
      return BattleEngineDecisionRequest._(
        kind: BattleEngineDecisionRequestKind.finished,
        actor: psdkPlayerSlot,
        fightChoices: const <BattleMoveDecisionOption>[],
      );
    }

    final battler = context.state.battlerAt(psdkPlayerSlot);
    final fightChoices = <BattleMoveDecisionOption>[
      for (var i = 0; i < battler.moves.length; i += 1)
        if (battler.moves[i].hasUsablePp &&
            _isSelectableByMovePrevention(
              context: context,
              user: psdkPlayerSlot,
              move: battler.moves[i],
            ))
          BattleMoveDecisionOption(
            moveSlot: i,
            moveId: battler.moves[i].id,
            moveName: battler.moves[i].name,
            pp: battler.moves[i].currentPp,
            target: battler.moves[i].target,
          ),
    ];

    return BattleEngineDecisionRequest._(
      kind: fightChoices.isEmpty
          ? BattleEngineDecisionRequestKind.noLegalChoice
          : BattleEngineDecisionRequestKind.turnChoice,
      actor: psdkPlayerSlot,
      fightChoices: fightChoices,
    );
  }

  final BattleEngineDecisionRequestKind kind;
  final PsdkBattleSlotRef actor;
  final List<BattleMoveDecisionOption> fightChoices;

  List<BattleDecision> get allowedDecisions {
    return List<BattleDecision>.unmodifiable(
      <BattleDecision>[
        for (final choice in fightChoices)
          BattleDecision.fight(moveSlot: choice.moveSlot),
      ],
    );
  }

  bool allows(BattleDecision decision) {
    return switch (decision) {
      BattleFightDecision(:final moveSlot) =>
        fightChoices.any((choice) => choice.moveSlot == moveSlot),
      BattleSwitchDecision() => false,
    };
  }
}

bool _isSelectableByMovePrevention({
  required BattleContext context,
  required PsdkBattleSlotRef user,
  required PsdkBattleMoveData move,
}) {
  final target = _defaultSelectionTarget(
    context: context,
    user: user,
    target: move.target,
  );
  return context.state.battlerAt(user).effects.moveSelectionPrevention(
            state: context.state,
            user: user,
            target: target,
            move: BattleMoveDefinition.fromPsdk(move),
          ) ==
      null;
}

PsdkBattleSlotRef _defaultSelectionTarget({
  required BattleContext context,
  required PsdkBattleSlotRef user,
  required PsdkBattleMoveTarget target,
}) {
  return switch (target) {
    PsdkBattleMoveTarget.self ||
    PsdkBattleMoveTarget.user ||
    PsdkBattleMoveTarget.userSide ||
    PsdkBattleMoveTarget.allAllies ||
    PsdkBattleMoveTarget.adjacentAllyOrSelf ||
    PsdkBattleMoveTarget.none =>
      user,
    PsdkBattleMoveTarget.adjacentAlly =>
      _firstOrNull(context.state.alliesOf(user)) ?? user,
    PsdkBattleMoveTarget.adjacentFoe ||
    PsdkBattleMoveTarget.allAdjacent ||
    PsdkBattleMoveTarget.allAdjacentFoes ||
    PsdkBattleMoveTarget.allBattlers ||
    PsdkBattleMoveTarget.allFoes ||
    PsdkBattleMoveTarget.anyFoe ||
    PsdkBattleMoveTarget.bank ||
    PsdkBattleMoveTarget.foeSide ||
    PsdkBattleMoveTarget.randomFoe =>
      _firstOrNull(context.state.foesOf(user)) ?? user,
  };
}

PsdkBattleSlotRef? _firstOrNull(List<PsdkBattleSlotRef> slots) {
  return slots.isEmpty ? null : slots.first;
}
