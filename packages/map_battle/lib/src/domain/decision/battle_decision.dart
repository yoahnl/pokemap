import '../action/battle_action.dart';
import '../battle/battle_context.dart';
import '../move/battle_move_data.dart';
import '../move/battle_struggle.dart';
import '../move/behaviors/z_move_behavior.dart';
import '../../capture_formula.dart';
import '../../psdk/domain/psdk_battle_move.dart';
import '../../psdk/domain/psdk_battle_slots.dart';
import '../../psdk/domain/psdk_battle_state.dart';

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

  const factory BattleDecision.struggle() = BattleFightDecision.struggle;

  const factory BattleDecision.switchPokemon({
    required int partyIndex,
  }) = BattleSwitchDecision;

  const factory BattleDecision.item({
    required String itemId,
    required PsdkBattleSlotRef target,
    int? targetPartyIndex,
    required PsdkBattleItemActionEffect effect,
    bool consumeItem,
    bool highPriority,
  }) = BattleItemDecision;

  const factory BattleDecision.mega({
    required PsdkBattleMegaEvolution form,
  }) = BattleMegaDecision;

  const factory BattleDecision.flee() = BattleFleeDecision;

  const factory BattleDecision.capture({
    required String itemId,
    required int rateNumerator,
    required int rateDenominator,
  }) = BattleCaptureDecision;

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

  const BattleFightDecision.struggle()
      : moveSlot = canonicalStruggleMoveSlot,
        target = null;

  final int moveSlot;
  final PsdkBattleSlotRef? target;

  bool get isStruggle => moveSlot == canonicalStruggleMoveSlot;
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
    this.targetPartyIndex,
    required this.effect,
    this.consumeItem = true,
    this.highPriority = false,
  });

  final String itemId;
  final PsdkBattleSlotRef target;
  final int? targetPartyIndex;
  final PsdkBattleItemActionEffect effect;
  final bool consumeItem;
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

final class BattleCaptureDecision extends BattleDecision {
  const BattleCaptureDecision({
    required this.itemId,
    required this.rateNumerator,
    required this.rateDenominator,
  });

  final String itemId;
  final int rateNumerator;
  final int rateDenominator;
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
  forcedReplacement,
  noLegalChoice,
  finished,
}

/// Raised when a command is not part of the current canonical request.
///
/// The rejected command never reaches the turn runner, so state, RNG and turn
/// number stay unchanged.
final class BattleDecisionRejectedError extends Error {
  BattleDecisionRejectedError({
    required this.requestKind,
    required this.decision,
  });

  final BattleEngineDecisionRequestKind requestKind;
  final BattleDecision decision;

  @override
  String toString() {
    return 'BattleDecisionRejectedError: ${decision.runtimeType} is not '
        'allowed for ${requestKind.name}.';
  }
}

/// One legal fight option in a clean battle request.
final class BattleMoveDecisionOption {
  const BattleMoveDecisionOption({
    required this.moveSlot,
    required this.moveId,
    required this.moveName,
    required this.pp,
    required this.target,
    this.legalTargets = const [],
  });

  final int moveSlot;
  final String moveId;
  final String moveName;
  final int pp;
  final PsdkBattleMoveTarget target;
  final List<PsdkBattleSlotRef> legalTargets;
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
    required this.actorCombatantId,
    required this.requestRevision,
    required List<BattleMoveDecisionOption> fightChoices,
    required List<BattleSwitchDecisionOption> switchChoices,
    required this.partySize,
    required this.canCapture,
    required this.canFlee,
    required this.canStruggle,
  })  : fightChoices =
            List<BattleMoveDecisionOption>.unmodifiable(fightChoices),
        switchChoices =
            List<BattleSwitchDecisionOption>.unmodifiable(switchChoices);

  factory BattleEngineDecisionRequest.fromContext(
    BattleContext context, {
    PsdkBattleSlotRef actor = psdkPlayerSlot,
    int requestRevision = 0,
    Set<int> reservedPartyIndexes = const {},
  }) {
    final actorCombatantId = context.state.battlerAt(actor).id;
    if (!context.canBattleContinue) {
      return BattleEngineDecisionRequest._(
        kind: BattleEngineDecisionRequestKind.finished,
        actor: actor,
        actorCombatantId: actorCombatantId,
        requestRevision: requestRevision,
        fightChoices: const <BattleMoveDecisionOption>[],
        switchChoices: const <BattleSwitchDecisionOption>[],
        partySize: context.state.partyForBank(psdkPlayerSlot.bank).length,
        canCapture: false,
        canFlee: false,
        canStruggle: false,
      );
    }

    final battler = context.state.battlerAt(actor);
    final switchChoices = _switchChoicesFor(context, actor)
        .where((choice) => !reservedPartyIndexes.contains(choice.partyIndex))
        .toList(growable: false);
    if (battler.isFainted) {
      return BattleEngineDecisionRequest._(
        kind: switchChoices.isEmpty
            ? BattleEngineDecisionRequestKind.noLegalChoice
            : BattleEngineDecisionRequestKind.forcedReplacement,
        actor: actor,
        actorCombatantId: actorCombatantId,
        requestRevision: requestRevision,
        fightChoices: const <BattleMoveDecisionOption>[],
        switchChoices: switchChoices,
        partySize: context.state.partyForBank(psdkPlayerSlot.bank).length,
        canCapture: false,
        canFlee: false,
        canStruggle: false,
      );
    }

    final fightChoices = <BattleMoveDecisionOption>[
      for (var i = 0; i < battler.moves.length; i += 1)
        if (battler.moves[i].hasUsablePp &&
            _isSelectableByMovePrevention(
              context: context,
              user: actor,
              move: battler.moves[i],
            ))
          BattleMoveDecisionOption(
            moveSlot: i,
            moveId: battler.moves[i].id,
            moveName: battler.moves[i].name,
            pp: battler.moves[i].currentPp,
            target: battler.moves[i].target,
            legalTargets: List.unmodifiable(_selectionTargetsFor(
              state: context.state,
              user: actor,
              target: battler.moves[i].target,
            )),
          ),
    ];
    final canCapture = context.setup.canCapture;
    final canFlee = context.setup.canFlee;
    final canStruggle = battler.moves.isNotEmpty && fightChoices.isEmpty;
    final hasLegalChoice = fightChoices.isNotEmpty ||
        switchChoices.isNotEmpty ||
        canCapture ||
        canFlee ||
        canStruggle;

    return BattleEngineDecisionRequest._(
      kind: !hasLegalChoice
          ? BattleEngineDecisionRequestKind.noLegalChoice
          : BattleEngineDecisionRequestKind.turnChoice,
      actor: actor,
      actorCombatantId: actorCombatantId,
      requestRevision: requestRevision,
      fightChoices: fightChoices,
      switchChoices: switchChoices,
      partySize: context.state.partyForBank(psdkPlayerSlot.bank).length,
      canCapture: canCapture,
      canFlee: canFlee,
      canStruggle: canStruggle,
    );
  }

  final BattleEngineDecisionRequestKind kind;
  final PsdkBattleSlotRef actor;
  final String actorCombatantId;
  final int requestRevision;
  final List<BattleMoveDecisionOption> fightChoices;
  final List<BattleSwitchDecisionOption> switchChoices;
  final int partySize;
  final bool canCapture;
  final bool canFlee;
  final bool canStruggle;

  List<BattleDecision> get allowedDecisions {
    return List<BattleDecision>.unmodifiable(
      <BattleDecision>[
        for (final choice in fightChoices)
          BattleDecision.fight(moveSlot: choice.moveSlot),
        if (canStruggle) const BattleDecision.struggle(),
        for (final choice in switchChoices)
          BattleDecision.switchPokemon(partyIndex: choice.partyIndex),
        if (canCapture)
          const BattleDecision.capture(
            itemId: canonicalPokeBallItemId,
            rateNumerator: 1,
            rateDenominator: 1,
          ),
        if (canFlee) const BattleDecision.flee(),
      ],
    );
  }

  bool allows(BattleDecision decision) {
    return switch (decision) {
      BattleFightDecision(:final moveSlot, :final target) =>
        moveSlot == canonicalStruggleMoveSlot
            ? canStruggle
            : fightChoices.any((choice) =>
                choice.moveSlot == moveSlot &&
                (target == null || choice.legalTargets.contains(target))),
      BattleSwitchDecision(:final partyIndex) =>
        switchChoices.any((choice) => choice.partyIndex == partyIndex),
      BattleItemDecision(:final target, :final targetPartyIndex) =>
        kind == BattleEngineDecisionRequestKind.turnChoice &&
            target.bank == actor.bank &&
            (targetPartyIndex == null ||
                (targetPartyIndex >= 0 && targetPartyIndex < partySize)),
      BattleMegaDecision() => false,
      BattleFleeDecision() => canFlee,
      BattleCaptureDecision(
        :final itemId,
        :final rateNumerator,
        :final rateDenominator,
      ) =>
        canCapture &&
            itemId.trim().isNotEmpty &&
            rateNumerator > 0 &&
            rateDenominator > 0,
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
  final activeIds = {
    for (final entry in context.state.combatants.entries)
      if (entry.key.bank == user.bank) entry.value.id,
  };
  return <BattleSwitchDecisionOption>[
    for (var index = 0; index < party.length; index += 1)
      if (!party[index].isFainted && !activeIds.contains(party[index].id))
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
  final isKnownSignatureZMove = move.battleEngineMethod == 's_z_move' ||
      signatureZMoveSpecFor(move.dbSymbol) != null;
  if (isKnownSignatureZMove &&
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

List<PsdkBattleSlotRef> _selectionTargetsFor({
  required PsdkBattleState state,
  required PsdkBattleSlotRef user,
  required PsdkBattleMoveTarget target,
}) {
  return switch (target) {
    PsdkBattleMoveTarget.self || PsdkBattleMoveTarget.user => [user],
    PsdkBattleMoveTarget.adjacentFoe => state.adjacentFoesOf(user),
    PsdkBattleMoveTarget.anyFoe ||
    PsdkBattleMoveTarget.allFoes ||
    PsdkBattleMoveTarget.allAdjacentFoes ||
    PsdkBattleMoveTarget.randomFoe =>
      state.foesOf(user),
    PsdkBattleMoveTarget.adjacentAlly => state.adjacentAlliesOf(user),
    PsdkBattleMoveTarget.adjacentAllyOrSelf => [
        user,
        ...state.adjacentAlliesOf(user)
      ],
    PsdkBattleMoveTarget.allAdjacent => state.adjacentSlotsOf(user),
    PsdkBattleMoveTarget.allBattlers => state.aliveSlots(),
    PsdkBattleMoveTarget.allAllies => state.alliesOf(user),
    PsdkBattleMoveTarget.bank ||
    PsdkBattleMoveTarget.userSide ||
    PsdkBattleMoveTarget.foeSide ||
    PsdkBattleMoveTarget.none =>
      const [],
  };
}

PsdkBattleSlotRef? _firstOrNull(List<PsdkBattleSlotRef> slots) {
  return slots.isEmpty ? null : slots.first;
}
