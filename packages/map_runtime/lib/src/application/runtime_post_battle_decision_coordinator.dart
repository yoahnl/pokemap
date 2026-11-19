import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../presentation/runtime_battle_message.dart';
import 'battle_start_request.dart';
import 'runtime_battle_outcome_apply.dart';
import 'runtime_battle_reward_resolver.dart';
import 'runtime_map_bundle.dart';
import 'runtime_pokemon_species_loader.dart';
import 'story_flags_manager.dart';

part 'runtime_post_battle_messages.dart';

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

final class RuntimePostBattleCoordinatorFailure implements Exception {
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

  @override
  String toString() => message;

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
    required String Function(String speciesId) displaySpeciesName,
    required ItemCatalogSnapshot? itemCatalog,
    required BattleProgressionResult? progression,
  }) : _displaySpeciesName = displaySpeciesName,
       _itemCatalog = itemCatalog,
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
  final String Function(String speciesId) _displaySpeciesName;
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
    this.loadPresentationSpecies,
    this.presentationLocale,
    RuntimeBattleMessageRenderer? formatBattleMessage,
  }) : _messages = _PostBattleMessages(formatBattleMessage),
       _resolveReward =
           resolveReward ??
           (rewardResolver ?? RuntimeBattleRewardResolver()).resolve,
       _hydrateOwnedPlayerPokemon =
           hydrateOwnedPlayerPokemon ?? _preserveOwnedPlayerPokemon,
       _mutations = mutations,
       _storyFlagsManager = storyFlagsManager;

  final _PostBattleMessages _messages;
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

  final RuntimePostBattleSpeciesLoader? loadPresentationSpecies;
  final String Function()? presentationLocale;

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
    final speciesName =
        resolveSpeciesDisplayName ?? this.resolveSpeciesDisplayName;
    final requestId = runtimeContext.request.requestId.trim();
    if (requestId.isEmpty) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.invalidOutcome,
          message: _messages.render(
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleMissingTransaction,
              'Le combat ne possède pas d’identifiant de transaction.',
            ),
          ),
          originalState: transactionBaseState,
        ),
      );
    }
    if (transactionBaseState.completedBattleRequestIds.contains(requestId)) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.alreadyApplied,
          message: _messages.render(
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleAlreadyApplied,
              'Cette fin de combat a déjà été appliquée.',
            ),
          ),
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
            messages: _messages,
            resolveSpecies: speciesName,
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
      final displaySpeciesName = await _progressionSpeciesDisplayName(
        bundle: bundle,
        context: resolution.progressionContext,
        fallback: speciesName,
      );
      final messages = _messages.initialVictory(
        resolveSpecies: displaySpeciesName,
        resolveMove: _moveName,
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
        displaySpeciesName: displaySpeciesName,
        progression: resolution.progression,
      );
      return RuntimePostBattleCoordinatorResult.success(
        _advanceOrFinalize(transaction),
      );
    } on BattleRewardApplicationException catch (error) {
      return _rewardFailure(error, transactionBaseState);
    } on RuntimePostBattleResolutionException catch (error) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.rewardResolution,
          message: _messages.render(
            RuntimeBattleMessage(switch (error.code) {
              RuntimePostBattleResolutionErrorCode.missingTrainer =>
                RuntimeBattleMessageId.postBattleRewardMissingTrainer,
              RuntimePostBattleResolutionErrorCode.invalidBattleData =>
                RuntimeBattleMessageId.postBattleRewardInvalidBattle,
              RuntimePostBattleResolutionErrorCode.missingCatalogueData =>
                RuntimeBattleMessageId.postBattleRewardMissingData,
            }, error.message),
          ),
          originalState: transactionBaseState,
          cause: error,
        ),
      );
    } catch (error) {
      return RuntimePostBattleCoordinatorResult.failure(
        failure: RuntimePostBattleCoordinatorFailure(
          code: RuntimePostBattleCoordinatorFailureCode.invalidOutcome,
          message: _messages.render(
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleApplyFailed,
              'La fin du combat ne peut pas être appliquée.',
            ),
          ),
          originalState: transactionBaseState,
          cause: error,
        ),
      );
    }
  }

  Future<String Function(String)> _progressionSpeciesDisplayName({
    required RuntimeMapBundle bundle,
    required BattleProgressionContext context,
    required String Function(String)? fallback,
  }) async {
    final loader = loadPresentationSpecies;
    if (loader == null) return (id) => _speciesDisplayName(id, fallback);
    final targetIds = {
      for (final candidates in context.evolutionCandidatesByPartySlot.values)
        for (final candidate in candidates) candidate.targetSpeciesId,
    };
    Future<MapEntry<String, RuntimePokemonSpecies>?> load(String id) async {
      try {
        final species = await loader(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          speciesId: id,
        );
        return MapEntry(id, species);
      } on Exception {
        return null;
      }
    }

    final species = Map.fromEntries(
      (await Future.wait(targetIds.map(load))).nonNulls,
    );
    return (id) =>
        species[id]?.displayName(presentationLocale?.call() ?? 'fr') ??
        _speciesDisplayName(id, fallback);
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
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleMoveNotPending,
          'Aucune décision d’apprentissage n’est attendue.',
        ),
      );
    }
    try {
      final nextProgression = progression.resolvePendingMoveLearning(decision);
      final newMessages = <RuntimePostBattleMessage>[
        ...transaction.messages,
        ..._messages.moveChanges(
          nextProgression.moveLearningChanges.skip(
            progression.moveLearningChanges.length,
          ),
          _moveName,
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
        displaySpeciesName: transaction._displaySpeciesName,
        progression: nextProgression,
      );
      return RuntimePostBattleCoordinatorResult.success(
        _advanceOrFinalize(next),
      );
    } on BattleRewardApplicationException catch (error) {
      return _rewardFailure(error, transaction.originalState,
          transaction: transaction);
    } catch (error) {
      return _decisionFailure(
        transaction,
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleMoveInvalid,
          'Décision de capacité invalide.',
        ),
        cause: error,
      );
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
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleEvolutionNotPending,
          'Aucune décision d’évolution n’est attendue.',
        ),
      );
    }
    try {
      final nextProgression = progression.resolvePendingEvolution(decision);
      final newMessages = <RuntimePostBattleMessage>[
        ...transaction.messages,
        ..._messages.evolutionChanges(
          nextProgression.evolutionChanges.skip(
            progression.evolutionChanges.length,
          ),
          party: progression.state.party,
          resolveSpecies: transaction._displaySpeciesName,
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
        displaySpeciesName: transaction._displaySpeciesName,
        progression: nextProgression,
      );
      return RuntimePostBattleCoordinatorResult.success(
        _advanceOrFinalize(next),
      );
    } on BattleRewardApplicationException catch (error) {
      return _rewardFailure(error, transaction.originalState,
          transaction: transaction);
    } catch (error) {
      return _decisionFailure(
        transaction,
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleEvolutionInvalid,
          'Décision d’évolution invalide.',
        ),
        cause: error,
      );
    }
  }

  RuntimePostBattleCoordinatorResult _decisionFailure(
    RuntimePostBattleTransaction transaction,
    RuntimeBattleMessage message, {
    Object? cause,
  }) {
    return RuntimePostBattleCoordinatorResult.failure(
      transaction: transaction,
      failure: RuntimePostBattleCoordinatorFailure(
        code: RuntimePostBattleCoordinatorFailureCode.invalidDecision,
        message: _messages.render(message),
        originalState: transaction.originalState,
        cause: cause,
      ),
    );
  }

  RuntimePostBattleCoordinatorResult _rewardFailure(
    BattleRewardApplicationException error,
    GameState originalState, {
    RuntimePostBattleTransaction? transaction,
  }) {
    return RuntimePostBattleCoordinatorResult.failure(
      transaction: transaction,
      failure: RuntimePostBattleCoordinatorFailure(
        code: RuntimePostBattleCoordinatorFailureCode.rewardResolution,
        message: _messages.render(switch (error.failure) {
          BattleRewardApplicationFailure.bagCapacityExceeded =>
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleRewardBagCapacity,
              'Le sac ne peut pas recevoir toutes les récompenses. Le combat est annulé : libérez de la place avant de le recommencer.',
            ),
          BattleRewardApplicationFailure.quantityOverflow =>
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleRewardQuantity,
              'Le sac ne peut pas recevoir cette quantité de récompenses. Le combat est annulé.',
            ),
          BattleRewardApplicationFailure.missingItemCatalog =>
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleRewardMissingItemCatalog,
              'Le catalogue des récompenses est indisponible. Le combat est annulé.',
            ),
          BattleRewardApplicationFailure.unknownItem => RuntimeBattleMessage(
            RuntimeBattleMessageId.postBattleRewardUnknownItem,
            'Récompense objet inconnue : ${error.itemId}.',
            item: error.itemId,
          ),
          BattleRewardApplicationFailure.invalidReward =>
            const RuntimeBattleMessage(
              RuntimeBattleMessageId.postBattleRewardInvalid,
              'La récompense objet est invalide. Le combat est annulé.',
            ),
        }),
        originalState: originalState,
        cause: error,
      ),
    );
  }

  RuntimePostBattleTransaction _advanceOrFinalize(
    RuntimePostBattleTransaction transaction,
  ) {
    final party = transaction._progression?.state.party;
    final pendingMove = transaction.pendingMoveLearning;
    if (pendingMove != null) {
      final awaitingDecision =
          pendingMove.phase == BattleMoveLearningPhase.awaitingDecision;
      final target =
          _partyNickname(party, pendingMove.partySlot) ??
          transaction._displaySpeciesName(
            _partySpecies(transaction, pendingMove.partySlot),
          );
      final move = _moveName(pendingMove.candidate.moveId);
      return _copyWithMessages(transaction, <RuntimePostBattleMessage>[
        ...transaction.messages,
        _messages.line(
          awaitingDecision
              ? RuntimePostBattleMessageKind.moveLearningPrompt
              : RuntimePostBattleMessageKind.moveReplacementPrompt,
          awaitingDecision
              ? RuntimeBattleMessage(
                  RuntimeBattleMessageId.postBattleMoveLearning,
                  '$target peut apprendre $move.',
                  target: target,
                  move: move,
                )
              : RuntimeBattleMessage(
                  RuntimeBattleMessageId.postBattleMoveReplacement,
                  'Choisissez une capacité à remplacer pour apprendre $move.',
                  move: move,
                ),
          partySlot: pendingMove.partySlot,
        ),
      ]);
    }
    final pendingEvolution = transaction.pendingEvolution;
    if (pendingEvolution != null) {
      final target =
          _partyNickname(party, pendingEvolution.partySlot) ??
          transaction._displaySpeciesName(pendingEvolution.sourceSpeciesId);
      final replacement = transaction._displaySpeciesName(
        pendingEvolution.targetSpeciesId,
      );
      return _copyWithMessages(transaction, <RuntimePostBattleMessage>[
        ...transaction.messages,
        _messages.line(
          RuntimePostBattleMessageKind.evolutionPrompt,
          RuntimeBattleMessage(
            RuntimeBattleMessageId.postBattleEvolutionPrompt,
            '$target veut évoluer en $replacement.',
            target: target,
            replacement: replacement,
          ),
          partySlot: pendingEvolution.partySlot,
        ),
      ]);
    }
    final progression = transaction._progression;
    if (progression == null) return transaction;

    var finalState = _mutations.applyBattleRewards(
      progression.state,
      reward: progression.appliedReward,
      itemCatalog: transaction._itemCatalog,
      bagCapacity: transaction.bundle.manifest.bagCapacity,
      battleSavings: transaction.bundle.manifest.battleSavings,
      facts: transaction.bundle.manifest.facts,
    );
    final rewardMessages = _messages.rewards(
      progression.appliedReward,
      itemCatalog: transaction._itemCatalog,
      resolveMove: _moveName,
    );
    final request = transaction.runtimeContext.request;
    final trainerMessages = <RuntimePostBattleMessage>[];
    if (request is TrainerBattleStartRequest) {
      // This mutation intentionally occurs after every authored reward.
      finalState = _storyFlagsManager.markTrainerDefeated(
        finalState,
        request.trainerId,
      );
      final trainer = _trainerDisplayName(
        transaction.bundle,
        request.trainerId,
      );
      trainerMessages.add(
        _messages.line(
          RuntimePostBattleMessageKind.trainerDefeated,
          RuntimeBattleMessage(
            RuntimeBattleMessageId.postBattleTrainerDefeated,
            'Vous avez battu $trainer !',
            actor: trainer,
          ),
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
      displaySpeciesName: transaction._displaySpeciesName,
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
  required _PostBattleMessages messages,
  required String Function(String speciesId)? resolveSpecies,
}) {
  final finalState = _completeBattleRequest(
    writeBack.state,
    runtimeContext.request,
  );
  final destination = _captureDestinationWithState(
    writeBack.captureDestination,
    finalState,
  );
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
    messages: List<RuntimePostBattleMessage>.unmodifiable(
      messages.terminal(outcome, destination?.destination, resolveSpecies),
    ),
    pendingMoveLearning: null,
    pendingEvolution: null,
    pendingPartyMoveIds: const <String>[],
    captureDestination: destination,
    finalState: finalState,
    displaySpeciesName: (id) => _speciesDisplayName(id, resolveSpecies),
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
    displaySpeciesName: transaction._displaySpeciesName,
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
