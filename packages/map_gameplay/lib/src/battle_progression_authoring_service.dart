import 'package:map_core/map_core.dart';

import 'battle_progression_result.dart';
import 'battle_progression_service.dart';
import 'battle_reward.dart';
import 'player_storage_operations.dart';

enum BattleProgressionAuthoringDecisionKind {
  moveLearning,
  evolution,
}

enum BattleAuthoringCaptureDestinationKind {
  party,
  storageBox,
  unavailable,
}

final class BattleAuthoringCaptureDestinationPreview {
  const BattleAuthoringCaptureDestinationPreview({
    required this.kind,
    this.partyIndex,
    this.boxId,
    this.boxIndex,
    this.failure,
  });

  final BattleAuthoringCaptureDestinationKind kind;
  final int? partyIndex;
  final String? boxId;
  final int? boxIndex;
  final PlayerStorageFailure? failure;

  bool get isAvailable =>
      kind != BattleAuthoringCaptureDestinationKind.unavailable;

  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'isAvailable': isAvailable,
        if (partyIndex != null) 'partyIndex': partyIndex,
        if (boxId != null) 'boxId': boxId,
        if (boxIndex != null) 'boxIndex': boxIndex,
        if (failure != null) 'failure': failure!.name,
      };
}

sealed class BattleProgressionAuthoringDecision {
  const BattleProgressionAuthoringDecision(this.kind);

  const factory BattleProgressionAuthoringDecision.moveLearning(
    BattleMoveLearningDecision decision,
  ) = BattleProgressionAuthoringMoveLearningDecision;

  const factory BattleProgressionAuthoringDecision.evolution(
    BattleEvolutionDecision decision,
  ) = BattleProgressionAuthoringEvolutionDecision;

  final BattleProgressionAuthoringDecisionKind kind;

  Map<String, Object?> toJson();
}

final class BattleProgressionAuthoringMoveLearningDecision
    extends BattleProgressionAuthoringDecision {
  const BattleProgressionAuthoringMoveLearningDecision(this.decision)
      : super(BattleProgressionAuthoringDecisionKind.moveLearning);

  final BattleMoveLearningDecision decision;

  @override
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'opportunityId': decision.opportunityId,
        'partySlot': decision.partySlot,
        'moveId': decision.moveId,
        'decision': switch (decision) {
          LearnBattleMoveLearningDecision() => 'learn',
          ReplaceBattleMoveLearningDecision() => 'replace',
          DeclineBattleMoveLearningDecision() => 'decline',
        },
        if (decision case ReplaceBattleMoveLearningDecision replacement) ...{
          'replaceMoveIndex': replacement.replaceMoveIndex,
          'expectedReplacedMoveId': replacement.expectedReplacedMoveId,
        },
      };
}

final class BattleProgressionAuthoringEvolutionDecision
    extends BattleProgressionAuthoringDecision {
  const BattleProgressionAuthoringEvolutionDecision(this.decision)
      : super(BattleProgressionAuthoringDecisionKind.evolution);

  final BattleEvolutionDecision decision;

  @override
  Map<String, Object?> toJson() => {
        'kind': kind.name,
        'opportunityId': decision.opportunityId,
        'occurrenceId': decision.occurrenceId,
        'partySlot': decision.partySlot,
        'sourceSpeciesId': decision.sourceSpeciesId,
        'targetSpeciesId': decision.targetSpeciesId,
        'decision': switch (decision) {
          AcceptBattleEvolutionDecision() => 'accept',
          RefuseBattleEvolutionDecision() => 'refuse',
        },
      };
}

final class BattleProgressionAuthoringDecisionTrace {
  const BattleProgressionAuthoringDecisionTrace({
    required this.index,
    required this.kind,
    required this.decision,
    required this.pendingBefore,
    required this.pendingAfter,
  });

  final int index;
  final BattleProgressionAuthoringDecisionKind kind;
  final Map<String, Object?> decision;
  final String pendingBefore;
  final String pendingAfter;

  Map<String, Object?> toJson() => {
        'index': index,
        'kind': kind.name,
        'decision': decision,
        'pendingBefore': pendingBefore,
        'pendingAfter': pendingAfter,
      };
}

final class BattleProgressionAuthoringPolicy {
  const BattleProgressionAuthoringPolicy({
    required this.outcome,
    required this.requiresRuntimeBattleWriteBack,
    required this.requiresCaptureDestination,
    required this.appliesVictoryRewards,
  });

  factory BattleProgressionAuthoringPolicy.forOutcome(
    BattleProgressionOutcomeKind outcome,
  ) {
    return BattleProgressionAuthoringPolicy(
      outcome: outcome,
      requiresRuntimeBattleWriteBack: true,
      requiresCaptureDestination:
          outcome == BattleProgressionOutcomeKind.captured,
      appliesVictoryRewards: outcome == BattleProgressionOutcomeKind.victory,
    );
  }

  final BattleProgressionOutcomeKind outcome;
  final bool requiresRuntimeBattleWriteBack;
  final bool requiresCaptureDestination;
  final bool appliesVictoryRewards;

  Map<String, Object?> toJson() => {
        'outcome': outcome.name,
        'requiresRuntimeBattleWriteBack': requiresRuntimeBattleWriteBack,
        'requiresCaptureDestination': requiresCaptureDestination,
        'appliesVictoryRewards': appliesVictoryRewards,
      };
}

final class BattleProgressionAuthoringPreview {
  BattleProgressionAuthoringPreview({
    required this.sourceState,
    required this.result,
    required Iterable<BattleProgressionAuthoringDecisionTrace> decisionTrace,
    required this.policy,
    required this.captureDestination,
  }) : decisionTrace =
            List<BattleProgressionAuthoringDecisionTrace>.unmodifiable(
          decisionTrace,
        );

  final GameState sourceState;
  final BattleProgressionResult result;
  final List<BattleProgressionAuthoringDecisionTrace> decisionTrace;
  final BattleProgressionAuthoringPolicy policy;
  final BattleAuthoringCaptureDestinationPreview? captureDestination;

  bool get isDecisionComplete =>
      result.pendingMoveLearning == null && result.pendingEvolution == null;

  Map<String, Object?> toJson() => {
        'productionWriteAllowed': false,
        'policy': policy.toJson(),
        if (captureDestination != null)
          'captureDestination': captureDestination!.toJson(),
        'isDecisionComplete': isDecisionComplete,
        'sourceState': sourceState.toJson(),
        'resultState': result.state.toJson(),
        'appliedReward': _rewardToJson(result.appliedReward),
        'progressionChanges': [
          for (final change in result.changes)
            {
              'partySlot': change.partySlot,
              'experienceAwarded': change.experienceAwarded,
              'oldExperience': change.oldExperience,
              'newExperience': change.newExperience,
              'oldLevel': change.oldLevel,
              'newLevel': change.newLevel,
              'newCurrentHp': change.newCurrentHp,
            },
        ],
        'pendingMoveLearning': _pendingMoveLearningToJson(
          result.pendingMoveLearning,
        ),
        'pendingEvolution': _pendingEvolutionToJson(result.pendingEvolution),
        'decisionTrace': [for (final entry in decisionTrace) entry.toJson()],
      };
}

final class BattleProgressionAuthoringDecisionException implements Exception {
  const BattleProgressionAuthoringDecisionException({
    required this.index,
    required this.expected,
    required this.actual,
  });

  final int index;
  final String expected;
  final BattleProgressionAuthoringDecisionKind actual;

  @override
  String toString() =>
      'Battle progression authoring decision $index is ${actual.name}; '
      'expected $expected.';
}

/// Detached preview over the production gameplay progression service.
final class BattleProgressionAuthoringService {
  const BattleProgressionAuthoringService({
    this.progressionService = const BattleProgressionService(),
  });

  final BattleProgressionService progressionService;

  BattleAuthoringCaptureDestinationPreview previewCaptureDestination(
    GameState state,
  ) {
    if (state.party.members.length < maxPlayerPartySize) {
      return BattleAuthoringCaptureDestinationPreview(
        kind: BattleAuthoringCaptureDestinationKind.party,
        partyIndex: state.party.members.length,
      );
    }
    final slot = const PlayerStorageOperations().findFirstAvailableSlot(
      state.pokemonStorage,
    );
    if (slot == null) {
      return const BattleAuthoringCaptureDestinationPreview(
        kind: BattleAuthoringCaptureDestinationKind.unavailable,
        failure: PlayerStorageFailure.storageFull,
      );
    }
    return BattleAuthoringCaptureDestinationPreview(
      kind: BattleAuthoringCaptureDestinationKind.storageBox,
      boxId: slot.boxId,
      boxIndex: slot.boxIndex,
    );
  }

  BattleProgressionAuthoringPreview preview({
    required GameState state,
    required BattleProgressionContext context,
    required BattleReward reward,
    Iterable<BattleProgressionAuthoringDecision> decisions =
        const <BattleProgressionAuthoringDecision>[],
    bool applyAuthoredRewards = true,
  }) {
    final sourceState = _copyState(state);
    var result = progressionService.apply(
      state: _copyState(sourceState),
      context: context,
      reward: reward,
      applyAuthoredRewards: applyAuthoredRewards,
    );
    final trace = <BattleProgressionAuthoringDecisionTrace>[];
    var index = 0;
    for (final authoringDecision in decisions) {
      final before = _pendingKind(result);
      switch (authoringDecision) {
        case BattleProgressionAuthoringMoveLearningDecision():
          if (result.pendingMoveLearning == null) {
            throw BattleProgressionAuthoringDecisionException(
              index: index,
              expected: 'a pending move-learning decision',
              actual: authoringDecision.kind,
            );
          }
          result = result.resolvePendingMoveLearning(
            authoringDecision.decision,
          );
        case BattleProgressionAuthoringEvolutionDecision():
          if (result.pendingEvolution == null) {
            throw BattleProgressionAuthoringDecisionException(
              index: index,
              expected: 'a pending evolution decision',
              actual: authoringDecision.kind,
            );
          }
          result = result.resolvePendingEvolution(authoringDecision.decision);
      }
      trace.add(
        BattleProgressionAuthoringDecisionTrace(
          index: index,
          kind: authoringDecision.kind,
          decision: Map<String, Object?>.unmodifiable(
            authoringDecision.toJson(),
          ),
          pendingBefore: before,
          pendingAfter: _pendingKind(result),
        ),
      );
      index += 1;
    }

    return BattleProgressionAuthoringPreview(
      sourceState: sourceState,
      result: result,
      decisionTrace: trace,
      policy: BattleProgressionAuthoringPolicy.forOutcome(context.outcome),
      captureDestination:
          context.outcome == BattleProgressionOutcomeKind.captured
              ? previewCaptureDestination(sourceState)
              : null,
    );
  }
}

String _pendingKind(BattleProgressionResult result) {
  if (result.pendingMoveLearning != null) return 'moveLearning';
  if (result.pendingEvolution != null) return 'evolution';
  return 'none';
}

Map<String, Object?> _rewardToJson(BattleReward reward) => {
      'sourceKind': reward.sourceKind.name,
      if (reward.trainerId != null) 'trainerId': reward.trainerId,
      'experienceGrants': [
        for (final grant in reward.experienceGrants)
          {
            'partySlot': grant.partySlot,
            'experience': grant.experience,
          },
      ],
      'money': reward.money,
      'itemGrants': [
        for (final grant in reward.itemGrants)
          {
            'itemId': grant.itemId,
            'quantity': grant.quantity,
          },
      ],
      'flagIds': reward.flagIds,
      if (reward.badgeId != null) 'badgeId': reward.badgeId,
      if (reward.fieldAbilityUnlock != null)
        'fieldAbilityUnlock': reward.fieldAbilityUnlock!.name,
    };

Map<String, Object?>? _pendingMoveLearningToJson(
  PendingBattleMoveLearning? pending,
) {
  if (pending == null) return null;
  return {
    'opportunityId': pending.opportunityId,
    'partySlot': pending.partySlot,
    'moveId': pending.candidate.moveId,
    'phase': pending.phase.name,
  };
}

Map<String, Object?>? _pendingEvolutionToJson(
  PendingBattleEvolution? pending,
) {
  if (pending == null) return null;
  return {
    'opportunityId': pending.opportunityId,
    'occurrenceId': pending.occurrenceId,
    'partySlot': pending.partySlot,
    'sourceSpeciesId': pending.sourceSpeciesId,
    'targetSpeciesId': pending.targetSpeciesId,
  };
}

GameState _copyState(GameState state) =>
    GameState.fromJson(Map<String, dynamic>.from(state.toJson()));
