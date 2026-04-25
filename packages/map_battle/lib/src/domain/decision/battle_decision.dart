import '../battle/battle_context.dart';
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
  }) = BattleFightDecision;
}

final class BattleFightDecision extends BattleDecision {
  const BattleFightDecision({
    required this.moveSlot,
  });

  final int moveSlot;
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
        if (battler.moves[i].hasUsablePp)
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
    };
  }
}
