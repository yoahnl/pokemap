import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';
import 'runtime_battle_outcome_apply.dart';
import 'runtime_battle_reward_resolver.dart';
import 'runtime_map_bundle.dart';
import 'story_flags_manager.dart';

typedef RuntimePostBattleRewardResolutionLoader
    = Future<RuntimeBattleRewardResolution> Function({
  required RuntimeMapBundle bundle,
  required GameState postWriteBackState,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
});

typedef RuntimePostBattlePlayerPokemonHydrator = Future<GameState> Function({
  required GameState gameState,
  required RuntimeMapBundle bundle,
});

enum RuntimePostBattleMessageKind {
  victory,
  defeat,
  fled,
  captured,
  experience,
  levelUp,
  moveAutomaticallyLearned,
  moveLearningPrompt,
  moveReplacementPrompt,
  moveLearned,
  moveReplaced,
  moveDeclined,
  evolutionPrompt,
  evolutionAccepted,
  evolutionRefused,
  money,
  item,
  flag,
  badge,
  fieldAbility,
  trainerDefeated,
  captureDestination,
  error,
}

/// Ordered presentation fact derived from one committed-or-pending change.
final class RuntimePostBattleMessage {
  const RuntimePostBattleMessage({
    required this.kind,
    required this.text,
    this.partySlot,
  });

  final RuntimePostBattleMessageKind kind;
  final String text;
  final int? partySlot;
}

enum RuntimePostBattleCoordinatorFailureCode {
  alreadyApplied,
  rewardResolution,
  invalidDecision,
  invalidOutcome,
}

final class RuntimePostBattleCoordinatorFailure {
  const RuntimePostBattleCoordinatorFailure({
    required this.code,
    required this.message,
    required this.originalState,
    this.cause,
  });

  final RuntimePostBattleCoordinatorFailureCode code;
  final String message;
  final GameState originalState;
  final Object? cause;

  RuntimePostBattleMessage get presentationMessage => RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.error,
        text: message,
      );
}

/// Result of starting or advancing one immutable post-battle transaction.
final class RuntimePostBattleCoordinatorResult {
  const RuntimePostBattleCoordinatorResult.success(this.transaction)
      : failure = null;

  const RuntimePostBattleCoordinatorResult.failure({
    required this.failure,
    this.transaction,
  });

  final RuntimePostBattleTransaction? transaction;
  final RuntimePostBattleCoordinatorFailure? failure;

  bool get isSuccess => failure == null && transaction != null;
}

/// Immutable transaction snapshot. Intermediate gameplay state stays private.
final class RuntimePostBattleTransaction {
  const RuntimePostBattleTransaction._({
    required this.originalState,
    required this.runtimeContext,
    required this.outcome,
    required this.bundle,
    required this.reward,
    required this.messages,
    required this.pendingMoveLearning,
    required this.pendingEvolution,
    required this.pendingPartyMoveIds,
    required this.captureDestination,
    required this.finalState,
    required ItemCatalogSnapshot? itemCatalog,
    required BattleProgressionResult? progression,
  })  : _itemCatalog = itemCatalog,
        _progression = progression;

  final GameState originalState;
  final RuntimeActiveBattleContext runtimeContext;
  final BattleOutcome outcome;
  final RuntimeMapBundle bundle;
  final BattleReward reward;
  final List<RuntimePostBattleMessage> messages;
  final PendingBattleMoveLearning? pendingMoveLearning;
  final PendingBattleEvolution? pendingEvolution;
  final List<String> pendingPartyMoveIds;
  final CaptureDestinationResult? captureDestination;

  /// Null until every exact decision has been resolved and rewards finalized.
  final GameState? finalState;
  final ItemCatalogSnapshot? _itemCatalog;
  final BattleProgressionResult? _progression;

  bool get isReadyToCommit => finalState != null;

  /// L'état de progression courant, pour la PRÉSENTATION uniquement.
  ///
  /// BETA-BAT-017 : la barre d'XP de la scène a besoin du reliquat exact
  /// pendant que des décisions restent en attente — les gains y sont déjà
  /// appliqués bien avant la publication de [finalState]. Jamais un état à
  /// committer : seul [finalState] engage la transaction.
  GameState? get presentationProgressState => _progression?.state;
}

/// Builds one all-or-nothing post-battle transaction.
///
/// The caller publishes [RuntimePostBattleTransaction.finalState] only after
/// the presentation component has acknowledged every message. Until then,
/// HP/PP/status, XP, decisions and authored rewards remain private snapshots.
final class RuntimePostBattleDecisionCoordinator {
  RuntimePostBattleDecisionCoordinator({
    RuntimePostBattleRewardResolutionLoader? resolveReward,
    RuntimeBattleRewardResolver? rewardResolver,
    RuntimePostBattlePlayerPokemonHydrator? hydrateOwnedPlayerPokemon,
    GameStateMutations mutations = const GameStateMutations(),
    StoryFlagsManager storyFlagsManager = const StoryFlagsManager(),
    this.resolveSpeciesDisplayName,
    this.resolveMoveDisplayName,
  })  : _resolveReward = resolveReward ??
            (rewardResolver ?? RuntimeBattleRewardResolver()).resolve,
        _hydrateOwnedPlayerPokemon =
            hydrateOwnedPlayerPokemon ?? _preserveOwnedPlayerPokemon,
        _mutations = mutations,
        _storyFlagsManager = storyFlagsManager;

  final RuntimePostBattleRewardResolutionLoader _resolveReward;
  final RuntimePostBattlePlayerPokemonHydrator _hydrateOwnedPlayerPokemon;
  final GameStateMutations _mutations;
  final StoryFlagsManager _storyFlagsManager;

  /// Recette du 2026-08-24 : « Pikachu peut apprendre Quick attack. » — les
  /// prompts parlaient l'identifiant. Ces résolveurs sont des closures de
  /// l'hôte qui lisent ses catalogues courants ; sans eux, l'identifiant
  /// reformaté reste le repli.
  final String Function(String speciesId)? resolveSpeciesDisplayName;
  final String Function(String moveId)? resolveMoveDisplayName;

  String _speciesName(String speciesId) =>
      resolveSpeciesDisplayName?.call(speciesId) ?? _displayId(speciesId);

  String _moveName(String moveId) =>
      resolveMoveDisplayName?.call(moveId) ?? _displayId(moveId);

  Future<RuntimePostBattleCoordinatorResult> begin({
    required GameState transactionBaseState,
    required RuntimeMapBundle bundle,
    required RuntimeActiveBattleContext runtimeContext,
    required BattleOutcome outcome,
    required ItemCatalogSnapshot itemCatalog,
    RuntimeBattleCaptureAttemptReceipt? captureAttemptReceipt,
    String Function(String speciesId)? resolveSpeciesDisplayName,
  }) async {
    final requestId = runtimeContext.request.requestId.trim();
    if (requestId.isEmpty) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.invalidOutcome,
          message: 'Le combat ne possède pas d’identifiant de transaction.',
          originalState: transactionBaseState,
        ),
      );
    }
    if (transactionBaseState.completedBattleRequestIds.contains(requestId)) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.alreadyApplied,
          message: 'Cette fin de combat a déjà été appliquée.',
          originalState: transactionBaseState,
        ),
      );
    }
    try {
      var writeBack = applyRuntimeBattleOutcomeTransactionBase(
        gameState: transactionBaseState,
        context: runtimeContext,
        outcome: outcome,
        captureAttemptReceipt: captureAttemptReceipt,
      );
      if (outcome.isCaptured) {
        final hydratedState = await _hydrateOwnedPlayerPokemon(
          gameState: writeBack.state,
          bundle: bundle,
        );
        writeBack = RuntimeBattleOutcomeTransactionBase(
          state: hydratedState,
          captureDestination: _captureDestinationWithState(
            writeBack.captureDestination,
            hydratedState,
          ),
        );
      }
      if (!outcome.isVictory) {
        return RuntimePostBattleCoordinatorResult.success(
          _nonVictoryTransaction(
            originalState: transactionBaseState,
            writeBack: writeBack,
            runtimeContext: runtimeContext,
            outcome: outcome,
            bundle: bundle,
            itemCatalog: itemCatalog,
          ),
        );
      }

      final resolution = await _resolveReward(
        bundle: bundle,
        postWriteBackState: writeBack.state,
        runtimeContext: runtimeContext,
        outcome: outcome,
      );
      _mutations.validateBattleRewardItems(
        reward: resolution.progression.appliedReward,
        itemCatalog: itemCatalog,
      );
      final messages = _initialVictoryMessages(
        resolveSpeciesDisplayName:
            resolveSpeciesDisplayName ?? this.resolveSpeciesDisplayName,
        resolveMoveDisplayName: resolveMoveDisplayName,
        resolution: resolution,
      );
      final transaction = RuntimePostBattleTransaction._(
        originalState: transactionBaseState,
        runtimeContext: runtimeContext,
        outcome: outcome,
        bundle: bundle,
        itemCatalog: itemCatalog,
        reward: resolution.reward,
        messages: messages,
        pendingMoveLearning: resolution.progression.pendingMoveLearning,
        pendingEvolution: resolution.progression.pendingEvolution,
        pendingPartyMoveIds: _pendingPartyMoveIds(resolution.progression),
        captureDestination: null,
        finalState: null,
        progression: resolution.progression,
      );
      return RuntimePostBattleCoordinatorResult.success(
        _advanceOrFinalize(transaction),
      );
    } on BattleRewardApplicationException catch (error) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.rewardResolution,
          message: 'Récompense objet inconnue : ${error.itemId}.',
          originalState: transactionBaseState,
          cause: error,
        ),
      );
    } on RuntimePostBattleResolutionException catch (error) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.rewardResolution,
          message: error.message,
          originalState: transactionBaseState,
          cause: error,
        ),
      );
    } catch (error) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.invalidOutcome,
          message: 'La fin du combat ne peut pas être appliquée.',
          originalState: transactionBaseState,
          cause: error,
        ),
      );
    }
  }

  RuntimePostBattleCoordinatorResult resolveMoveLearning({
    required RuntimePostBattleTransaction transaction,
    required BattleMoveLearningDecision decision,
  }) {
    final progression = transaction._progression;
    if (transaction.isReadyToCommit ||
        progression == null ||
        transaction.pendingMoveLearning == null) {
      return _decisionFailure(
        transaction,
        'Aucune décision d’apprentissage n’est attendue.',
      );
    }
    try {
      final nextProgression = progression.resolvePendingMoveLearning(decision);
      final newMessages = <RuntimePostBattleMessage>[
        ...transaction.messages,
        ..._moveChangeMessages(
          nextProgression.moveLearningChanges
              .skip(progression.moveLearningChanges.length),
          resolveMoveDisplayName: resolveMoveDisplayName,
        ),
      ];
      final next = RuntimePostBattleTransaction._(
        originalState: transaction.originalState,
        runtimeContext: transaction.runtimeContext,
        outcome: transaction.outcome,
        bundle: transaction.bundle,
        itemCatalog: transaction._itemCatalog,
        reward: transaction.reward,
        messages: newMessages,
        pendingMoveLearning: nextProgression.pendingMoveLearning,
        pendingEvolution: nextProgression.pendingEvolution,
        pendingPartyMoveIds: _pendingPartyMoveIds(nextProgression),
        captureDestination: transaction.captureDestination,
        finalState: null,
        progression: nextProgression,
      );
      return RuntimePostBattleCoordinatorResult.success(
        _advanceOrFinalize(next),
      );
    } catch (error) {
      return _decisionFailure(transaction, 'Décision de capacité invalide.',
          cause: error);
    }
  }

  RuntimePostBattleCoordinatorResult resolveEvolution({
    required RuntimePostBattleTransaction transaction,
    required BattleEvolutionDecision decision,
  }) {
    final progression = transaction._progression;
    if (transaction.isReadyToCommit ||
        progression == null ||
        transaction.pendingEvolution == null) {
      return _decisionFailure(
        transaction,
        'Aucune décision d’évolution n’est attendue.',
      );
    }
    try {
      final nextProgression = progression.resolvePendingEvolution(decision);
      final newMessages = <RuntimePostBattleMessage>[
        ...transaction.messages,
        ..._evolutionChangeMessages(
          nextProgression.evolutionChanges
              .skip(progression.evolutionChanges.length),
        ),
      ];
      final next = RuntimePostBattleTransaction._(
        originalState: transaction.originalState,
        runtimeContext: transaction.runtimeContext,
        outcome: transaction.outcome,
        bundle: transaction.bundle,
        itemCatalog: transaction._itemCatalog,
        reward: transaction.reward,
        messages: newMessages,
        pendingMoveLearning: nextProgression.pendingMoveLearning,
        pendingEvolution: nextProgression.pendingEvolution,
        pendingPartyMoveIds: _pendingPartyMoveIds(nextProgression),
        captureDestination: transaction.captureDestination,
        finalState: null,
        progression: nextProgression,
      );
      return RuntimePostBattleCoordinatorResult.success(
        _advanceOrFinalize(next),
      );
    } catch (error) {
      return _decisionFailure(transaction, 'Décision d’évolution invalide.',
          cause: error);
    }
  }

  RuntimePostBattleCoordinatorResult _decisionFailure(
    RuntimePostBattleTransaction transaction,
    String message, {
    Object? cause,
  }) {
    return RuntimePostBattleCoordinatorResult.failure(
      transaction: transaction,
      failure: RuntimePostBattleCoordinatorFailure(
        code: RuntimePostBattleCoordinatorFailureCode.invalidDecision,
        message: message,
        originalState: transaction.originalState,
        cause: cause,
      ),
    );
  }

  RuntimePostBattleTransaction _advanceOrFinalize(
    RuntimePostBattleTransaction transaction,
  ) {
    final pendingMove = transaction.pendingMoveLearning;
    if (pendingMove != null) {
      return _copyWithMessages(
        transaction,
        <RuntimePostBattleMessage>[
          ...transaction.messages,
          RuntimePostBattleMessage(
            kind: pendingMove.phase == BattleMoveLearningPhase.awaitingDecision
                ? RuntimePostBattleMessageKind.moveLearningPrompt
                : RuntimePostBattleMessageKind.moveReplacementPrompt,
            text: pendingMove.phase == BattleMoveLearningPhase.awaitingDecision
                ? '${_speciesName(_partySpecies(transaction, pendingMove.partySlot))} peut apprendre ${_moveName(pendingMove.candidate.moveId)}.'
                : 'Choisissez une capacité à remplacer pour apprendre ${_moveName(pendingMove.candidate.moveId)}.',
            partySlot: pendingMove.partySlot,
          ),
        ],
      );
    }
    final pendingEvolution = transaction.pendingEvolution;
    if (pendingEvolution != null) {
      return _copyWithMessages(
        transaction,
        <RuntimePostBattleMessage>[
          ...transaction.messages,
          RuntimePostBattleMessage(
            kind: RuntimePostBattleMessageKind.evolutionPrompt,
            text:
                '${_speciesName(pendingEvolution.sourceSpeciesId)} veut évoluer en ${_speciesName(pendingEvolution.targetSpeciesId)}.',
            partySlot: pendingEvolution.partySlot,
          ),
        ],
      );
    }
    final progression = transaction._progression;
    if (progression == null) return transaction;

    var finalState = _mutations.applyBattleRewards(
      progression.state,
      reward: progression.appliedReward,
      itemCatalog: transaction._itemCatalog,
    );
    final rewardMessages = _rewardMessages(progression.appliedReward);
    final request = transaction.runtimeContext.request;
    final trainerMessages = <RuntimePostBattleMessage>[];
    if (request is TrainerBattleStartRequest) {
      // This mutation intentionally occurs after every authored reward.
      finalState = _storyFlagsManager.markTrainerDefeated(
        finalState,
        request.trainerId,
      );
      trainerMessages.add(
        RuntimePostBattleMessage(
          kind: RuntimePostBattleMessageKind.trainerDefeated,
          text: 'Vous avez battu '
              '${_trainerDisplayName(transaction.bundle, request.trainerId)} !',
        ),
      );
    }
    finalState = _completeBattleRequest(finalState, request);
    return RuntimePostBattleTransaction._(
      originalState: transaction.originalState,
      runtimeContext: transaction.runtimeContext,
      outcome: transaction.outcome,
      bundle: transaction.bundle,
      itemCatalog: transaction._itemCatalog,
      reward: transaction.reward,
      messages: List<RuntimePostBattleMessage>.unmodifiable(
        <RuntimePostBattleMessage>[
          ...transaction.messages,
          // Parité référence : « Vous avez battu X ! » (le sprite du dresseur
          // vaincu s'y ancre) PUIS le gain d'argent.
          ...trainerMessages,
          ...rewardMessages,
        ],
      ),
      pendingMoveLearning: null,
      pendingEvolution: null,
      pendingPartyMoveIds: const <String>[],
      captureDestination: transaction.captureDestination,
      finalState: finalState,
      progression: progression,
    );
  }
}

RuntimePostBattleTransaction _nonVictoryTransaction({
  required GameState originalState,
  required RuntimeBattleOutcomeTransactionBase writeBack,
  required RuntimeActiveBattleContext runtimeContext,
  required BattleOutcome outcome,
  required RuntimeMapBundle bundle,
  required ItemCatalogSnapshot itemCatalog,
}) {
  final finalState = _completeBattleRequest(
    writeBack.state,
    runtimeContext.request,
  );
  final messages = <RuntimePostBattleMessage>[
    switch (outcome.type) {
      BattleOutcomeType.defeat => const RuntimePostBattleMessage(
          kind: RuntimePostBattleMessageKind.defeat,
          text: 'Tous vos Pokémon sont hors combat.',
        ),
      BattleOutcomeType.runaway => const RuntimePostBattleMessage(
          kind: RuntimePostBattleMessageKind.fled,
          // Texte exact de la référence (Data/Text/Dialogs 100018,
          // « You got away safely! ») — BETA-BAT-030.
          text: 'Vous prenez la fuite !',
        ),
      BattleOutcomeType.captured => RuntimePostBattleMessage(
          kind: RuntimePostBattleMessageKind.captured,
          text:
              '${_displayId(outcome.finalState.enemy.writeBackSpeciesId)} est capturé.',
        ),
      BattleOutcomeType.victory => throw StateError(
          'Victory must use the reward progression transaction.',
        ),
    },
  ];
  final destination = _captureDestinationWithState(
    writeBack.captureDestination,
    finalState,
  );
  if (destination != null) {
    messages.add(
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.captureDestination,
        text: switch (destination.destination) {
          CaptureDestinationKind.party =>
            '${_displayId(outcome.finalState.enemy.writeBackSpeciesId)} rejoint votre équipe.',
          CaptureDestinationKind.storage =>
            '${_displayId(outcome.finalState.enemy.writeBackSpeciesId)} est envoyé au stockage.',
          CaptureDestinationKind.none =>
            'La destination de capture est indisponible.',
        },
      ),
    );
  }
  return RuntimePostBattleTransaction._(
    originalState: originalState,
    runtimeContext: runtimeContext,
    outcome: outcome,
    bundle: bundle,
    itemCatalog: itemCatalog,
    reward: BattleReward(
      sourceKind: runtimeContext.request is TrainerBattleStartRequest
          ? BattleRewardSourceKind.trainer
          : BattleRewardSourceKind.wild,
      trainerId: runtimeContext.request is TrainerBattleStartRequest
          ? (runtimeContext.request as TrainerBattleStartRequest).trainerId
          : null,
    ),
    messages: List<RuntimePostBattleMessage>.unmodifiable(messages),
    pendingMoveLearning: null,
    pendingEvolution: null,
    pendingPartyMoveIds: const <String>[],
    captureDestination: destination,
    finalState: finalState,
    progression: null,
  );
}

Future<GameState> _preserveOwnedPlayerPokemon({
  required GameState gameState,
  required RuntimeMapBundle bundle,
}) async {
  return gameState;
}

CaptureDestinationResult? _captureDestinationWithState(
  CaptureDestinationResult? destination,
  GameState state,
) {
  if (destination == null) return null;
  return CaptureDestinationResult(
    state: state,
    destination: destination.destination,
    partyIndex: destination.partyIndex,
    storageIndex: destination.storageIndex,
    boxId: destination.boxId,
    boxIndex: destination.boxIndex,
    failure: destination.failure,
  );
}

GameState _completeBattleRequest(
  GameState state,
  BattleStartRequest request,
) {
  return state.copyWith(
    completedBattleRequestIds: <String>{
      ...state.completedBattleRequestIds,
      request.requestId.trim(),
    },
  );
}

List<RuntimePostBattleMessage> _initialVictoryMessages({
  required RuntimeBattleRewardResolution resolution,
  String Function(String speciesId)? resolveSpeciesDisplayName,
  String Function(String moveId)? resolveMoveDisplayName,
}) {
  final messages = <RuntimePostBattleMessage>[
    const RuntimePostBattleMessage(
      kind: RuntimePostBattleMessageKind.victory,
      text: 'Victoire !',
    ),
  ];
  for (final change in resolution.progression.changes) {
    final name = _speciesDisplayName(
      resolution.baseState.party.members[change.partySlot].speciesId,
      resolveSpeciesDisplayName,
    );
    messages.add(
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.experience,
        text: '$name a gagné ${change.experienceAwarded} points Exp. !',
        partySlot: change.partySlot,
      ),
    );
  }
  for (final change in resolution.progression.changes) {
    final name = _speciesDisplayName(
      resolution.baseState.party.members[change.partySlot].speciesId,
      resolveSpeciesDisplayName,
    );
    for (var level = change.oldLevel + 1; level <= change.newLevel; level++) {
      messages.add(
        RuntimePostBattleMessage(
          kind: RuntimePostBattleMessageKind.levelUp,
          text: '$name monte au N. $level !',
          partySlot: change.partySlot,
        ),
      );
    }
  }
  messages.addAll(
    _moveChangeMessages(
      resolution.progression.moveLearningChanges,
      resolveMoveDisplayName: resolveMoveDisplayName,
    ),
  );
  messages.addAll(
    _evolutionChangeMessages(resolution.progression.evolutionChanges),
  );
  return List<RuntimePostBattleMessage>.unmodifiable(messages);
}

List<RuntimePostBattleMessage> _moveChangeMessages(
  Iterable<BattleMoveLearningChange> changes, {
  String Function(String moveId)? resolveMoveDisplayName,
}) {
  String moveName(String moveId) =>
      resolveMoveDisplayName?.call(moveId) ?? _displayId(moveId);
  return <RuntimePostBattleMessage>[
    for (final change in changes)
      if (change.kind != BattleMoveLearningChangeKind.replacementRequested)
        RuntimePostBattleMessage(
          kind: switch (change.kind) {
            BattleMoveLearningChangeKind.automaticallyLearned =>
              RuntimePostBattleMessageKind.moveAutomaticallyLearned,
            BattleMoveLearningChangeKind.learned =>
              RuntimePostBattleMessageKind.moveLearned,
            BattleMoveLearningChangeKind.replaced =>
              RuntimePostBattleMessageKind.moveReplaced,
            BattleMoveLearningChangeKind.declined =>
              RuntimePostBattleMessageKind.moveDeclined,
            BattleMoveLearningChangeKind.replacementRequested =>
              throw StateError('Replacement requests are rendered as prompts.'),
          },
          text: switch (change.kind) {
            BattleMoveLearningChangeKind.automaticallyLearned ||
            BattleMoveLearningChangeKind.learned =>
              '${moveName(change.candidate.moveId)} est apprise.',
            BattleMoveLearningChangeKind.replaced =>
              '${moveName(change.replacedMoveId ?? '')} est remplacée par ${moveName(change.candidate.moveId)}.',
            BattleMoveLearningChangeKind.declined =>
              '${moveName(change.candidate.moveId)} n’est pas apprise.',
            BattleMoveLearningChangeKind.replacementRequested => '',
          },
          partySlot: change.partySlot,
        ),
  ];
}

List<RuntimePostBattleMessage> _evolutionChangeMessages(
  Iterable<BattleEvolutionChange> changes,
) {
  return <RuntimePostBattleMessage>[
    for (final change in changes)
      RuntimePostBattleMessage(
        kind: change.kind == BattleEvolutionChangeKind.evolved
            ? RuntimePostBattleMessageKind.evolutionAccepted
            : RuntimePostBattleMessageKind.evolutionRefused,
        text: change.kind == BattleEvolutionChangeKind.evolved
            ? '${_displayId(change.candidate.sourceSpeciesId)} évolue en ${_displayId(change.candidate.targetSpeciesId)}.'
            : '${_displayId(change.candidate.sourceSpeciesId)} n’évolue pas.',
        partySlot: change.partySlot,
      ),
  ];
}

List<RuntimePostBattleMessage> _rewardMessages(BattleReward reward) {
  return <RuntimePostBattleMessage>[
    if (reward.money > 0)
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.money,
        text: 'Vous remportez ${reward.money} ₽ !',
      ),
    for (final grant in reward.itemGrants)
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.item,
        text: '${_displayId(grant.itemId)} ×${grant.quantity} obtenu.',
      ),
    for (final flagId in reward.flagIds)
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.flag,
        text: '${_displayId(flagId)} est débloqué.',
      ),
    if (reward.badgeId case final badgeId?)
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.badge,
        text: 'Badge ${_displayId(badgeId)} obtenu.',
      ),
    if (reward.fieldAbilityUnlock case final ability?)
      RuntimePostBattleMessage(
        kind: RuntimePostBattleMessageKind.fieldAbility,
        text: '${_displayId(ability.name)} est maintenant utilisable.',
      ),
  ];
}

RuntimePostBattleTransaction _copyWithMessages(
  RuntimePostBattleTransaction transaction,
  List<RuntimePostBattleMessage> messages,
) {
  return RuntimePostBattleTransaction._(
    originalState: transaction.originalState,
    runtimeContext: transaction.runtimeContext,
    outcome: transaction.outcome,
    bundle: transaction.bundle,
    itemCatalog: transaction._itemCatalog,
    reward: transaction.reward,
    messages: List<RuntimePostBattleMessage>.unmodifiable(messages),
    pendingMoveLearning: transaction.pendingMoveLearning,
    pendingEvolution: transaction.pendingEvolution,
    pendingPartyMoveIds: transaction.pendingPartyMoveIds,
    captureDestination: transaction.captureDestination,
    finalState: transaction.finalState,
    progression: transaction._progression,
  );
}

List<String> _pendingPartyMoveIds(BattleProgressionResult progression) {
  final pending = progression.pendingMoveLearning;
  if (pending == null) return const <String>[];
  return List<String>.unmodifiable(
    progression.state.party.members[pending.partySlot].knownMoveIds,
  );
}

String _partySpecies(RuntimePostBattleTransaction transaction, int slot) {
  final progression = transaction._progression;
  if (progression == null || slot >= progression.state.party.members.length) {
    return 'Pokémon';
  }
  return progression.state.party.members[slot].speciesId;
}

String _trainerDisplayName(RuntimeMapBundle bundle, String trainerId) {
  final matches = bundle.manifest.trainers
      .where((trainer) => trainer.id == trainerId)
      .toList(growable: false);
  if (matches.length == 1 && matches.single.name.trim().isNotEmpty) {
    return matches.single.name.trim();
  }
  return _displayId(trainerId);
}

String _speciesDisplayName(
  String speciesId,
  String Function(String speciesId)? resolve,
) {
  final resolved = resolve?.call(speciesId).trim();
  if (resolved != null && resolved.isNotEmpty) return resolved;
  return _displayId(speciesId);
}

String _displayId(String id) {
  final words = id
      .trim()
      .split(RegExp(r'[-_:]+'))
      .where((word) => word.isNotEmpty)
      .toList(growable: false);
  if (words.isEmpty) return 'Pokémon';
  final text = words.join(' ');
  return '${text[0].toUpperCase()}${text.substring(1)}';
}
