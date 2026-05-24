import '../action/battle_action.dart';
import '../battle/battle_context.dart';
import '../move/battle_move_data.dart';
import '../move/behaviors/z_move_behavior.dart';
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

  const factory BattleDecision.item({
    required String itemId,
    required PsdkBattleSlotRef target,
    required PsdkBattleItemActionEffect effect,
    bool highPriority,
  }) = BattleItemDecision;

  const factory BattleDecision.mega({
    required PsdkBattleMegaEvolution form,
  }) = BattleMegaDecision;

  const factory BattleDecision.flee() = BattleFleeDecision;

  const factory BattleDecision.shift({
    required PsdkBattleSlotRef target,
  }) = BattleShiftDecision;

  const factory BattleDecision.noAction() = BattleNoActionDecision;
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

final class BattleItemDecision extends BattleDecision {
  const BattleItemDecision({
    required this.itemId,
    required this.target,
    required this.effect,
    this.highPriority = false,
  });

  final String itemId;
  final PsdkBattleSlotRef target;
  final PsdkBattleItemActionEffect effect;
  final bool highPriority;
}

final class BattleMegaDecision extends BattleDecision {
  const BattleMegaDecision({
    required this.form,
  });

  final PsdkBattleMegaEvolution form;
}

final class BattleFleeDecision extends BattleDecision {
  const BattleFleeDecision();
}

final class BattleShiftDecision extends BattleDecision {
  const BattleShiftDecision({
    required this.target,
  });

  final PsdkBattleSlotRef target;
}

final class BattleNoActionDecision extends BattleDecision {
  const BattleNoActionDecision();
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

/// One legal party replacement in a clean battle request.
final class BattleSwitchDecisionOption {
  const BattleSwitchDecisionOption({
    required this.partyIndex,
    required this.speciesId,
    required this.displayName,
    required this.currentHp,
    required this.maxHp,
  });

  final int partyIndex;
  final String speciesId;
  final String displayName;
  final int currentHp;
  final int maxHp;
}

/// Current player-facing request produced by [BattleEngine].
final class BattleEngineDecisionRequest {
  BattleEngineDecisionRequest._({
    required this.kind,
    required this.actor,
    required List<BattleMoveDecisionOption> fightChoices,
    required List<BattleSwitchDecisionOption> switchChoices,
  })  : fightChoices =
            List<BattleMoveDecisionOption>.unmodifiable(fightChoices),
        switchChoices =
            List<BattleSwitchDecisionOption>.unmodifiable(switchChoices);

  factory BattleEngineDecisionRequest.fromContext(BattleContext context) {
    if (!context.canBattleContinue) {
      return BattleEngineDecisionRequest._(
        kind: BattleEngineDecisionRequestKind.finished,
        actor: psdkPlayerSlot,
        fightChoices: const <BattleMoveDecisionOption>[],
        switchChoices: const <BattleSwitchDecisionOption>[],
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
    final switchChoices = _switchChoicesFor(context, psdkPlayerSlot);

    return BattleEngineDecisionRequest._(
      kind: fightChoices.isEmpty && switchChoices.isEmpty
          ? BattleEngineDecisionRequestKind.noLegalChoice
          : BattleEngineDecisionRequestKind.turnChoice,
      actor: psdkPlayerSlot,
      fightChoices: fightChoices,
      switchChoices: switchChoices,
    );
  }

  final BattleEngineDecisionRequestKind kind;
  final PsdkBattleSlotRef actor;
  final List<BattleMoveDecisionOption> fightChoices;
  final List<BattleSwitchDecisionOption> switchChoices;

  List<BattleDecision> get allowedDecisions {
    return List<BattleDecision>.unmodifiable(
      <BattleDecision>[
        for (final choice in fightChoices)
          BattleDecision.fight(moveSlot: choice.moveSlot),
        for (final choice in switchChoices)
          BattleDecision.switchPokemon(partyIndex: choice.partyIndex),
      ],
    );
  }

  bool allows(BattleDecision decision) {
    return switch (decision) {
      BattleFightDecision(:final moveSlot) =>
        fightChoices.any((choice) => choice.moveSlot == moveSlot),
      BattleSwitchDecision(:final partyIndex) =>
        switchChoices.any((choice) => choice.partyIndex == partyIndex),
      BattleItemDecision() => false,
      BattleMegaDecision() => false,
      BattleFleeDecision() => false,
      BattleShiftDecision() => false,
      BattleNoActionDecision() => false,
    };
  }
}

List<BattleSwitchDecisionOption> _switchChoicesFor(
  BattleContext context,
  PsdkBattleSlotRef user,
) {
  final party = context.state.partyForBank(user.bank);
  final active = context.state.battlerAt(user);
  return <BattleSwitchDecisionOption>[
    for (var index = 0; index < party.length; index += 1)
      if (!party[index].isFainted && party[index].id != active.id)
        BattleSwitchDecisionOption(
          partyIndex: index,
          speciesId: party[index].speciesId,
          displayName: party[index].displayName,
          currentHp: party[index].currentHp,
          maxHp: party[index].maxHp,
        ),
  ];
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
  final definition = BattleMoveDefinition.fromPsdk(move);
  if (move.battleEngineMethod == 's_z_move' &&
      !isSignatureZMoveSelectable(
        state: context.state,
        user: user,
        move: definition,
      )) {
    return false;
  }
  return context.state.battlerAt(user).effects.moveSelectionPrevention(
            state: context.state,
            user: user,
            target: target,
            move: definition,
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
