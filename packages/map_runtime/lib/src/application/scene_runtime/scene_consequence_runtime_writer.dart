import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_consequence_runtime_write_result.dart';
import 'scene_game_completion_metadata.dart';
import 'scene_npc_state_metadata.dart';
import 'runtime_scene_pokemon_catalog.dart';
import 'scene_interactive_pokemon_gift.dart';
import '../runtime_bag_capacity.dart';

String? scenePokemonGrantOperationId({
  required String sceneId,
  required String executionId,
  required String nodeId,
  required SceneConsequence consequence,
}) {
  if (consequence.kind != SceneConsequenceKind.givePokemon &&
      consequence.kind != SceneConsequenceKind.givePokemonFromCatalog &&
      consequence.kind != SceneConsequenceKind.giveConfiguredStarter) {
    return null;
  }
  final normalizedSceneId = sceneId.trim();
  final normalizedExecutionId = executionId.trim();
  final normalizedNodeId = nodeId.trim();
  if (normalizedSceneId.isEmpty ||
      normalizedExecutionId.isEmpty ||
      normalizedNodeId.isEmpty) {
    return null;
  }
  return 'scene:$normalizedSceneId:$normalizedExecutionId:$normalizedNodeId';
}

String? sceneRailProgressionOperationId({
  required String sceneId,
  required String executionId,
  required String nodeId,
  required SceneConsequence consequence,
}) {
  if (consequence.kind != SceneConsequenceKind.grantRailCurrency &&
      consequence.kind != SceneConsequenceKind.grantRailStamp) {
    return null;
  }
  final normalizedSceneId = sceneId.trim();
  final normalizedExecutionId = executionId.trim();
  final normalizedNodeId = nodeId.trim();
  if (normalizedSceneId.isEmpty ||
      normalizedExecutionId.isEmpty ||
      normalizedNodeId.isEmpty) {
    return null;
  }
  return 'scene:$normalizedSceneId:$normalizedExecutionId:$normalizedNodeId';
}

final class SceneConsequenceRuntimeWriter {
  const SceneConsequenceRuntimeWriter({
    required this.project,
    this.mapsById = const <String, NarrativeMapView>{},
    this.maxHpByPartyIndex = const <int, int>{},
    this.maxPpByPartyIndex = const <int, Map<String, int>>{},
    this.mutations = const GameStateMutations(),
    this.mapInstanceScopes = const <String, MapInstanceRef>{},
    this.pokemonCatalog,
    this.partyConditionContext = const ScenePartyConditionContext.unavailable(),
    this.itemCatalog,
  });

  final ProjectManifest project;
  final Map<String, NarrativeMapView> mapsById;
  final Map<int, int> maxHpByPartyIndex;
  final Map<int, Map<String, int>> maxPpByPartyIndex;
  final GameStateMutations mutations;
  final Map<String, MapInstanceRef> mapInstanceScopes;
  final RuntimeScenePokemonCatalog? pokemonCatalog;
  final ScenePartyConditionContext partyConditionContext;
  final ItemCatalogSnapshot? itemCatalog;

  static const int _maxPartySize = 6;

  /// Prevalidates and applies one canonical Action-node consequence.
  ///
  /// The returned state is a new immutable checkpoint. A rejected write
  /// returns the original [gameState] and never exposes a partial mutation.
  SceneConsequenceRuntimeWriteResult applyOne(
    GameState gameState,
    SceneConsequence consequence, {
    String? pokemonGrantOperationId,
    String? railProgressionOperationId,
    int? completionRecordedAtEpochMs,
    Map<String, GameCompletionPartyRecord> preparedCompletionPartyRecords = const {},
  }) {
    return applyAll(
      gameState,
      <SceneConsequence>[consequence],
      pokemonGrantOperationIds: <String?>[pokemonGrantOperationId],
      railProgressionOperationIds: <String?>[railProgressionOperationId],
      completionRecordedAtEpochMs: completionRecordedAtEpochMs,
      preparedCompletionPartyRecords: preparedCompletionPartyRecords,
    );
  }

  SceneConsequenceRuntimeWriteResult applyAll(
    GameState gameState,
    List<SceneConsequence> consequences, {
    List<String?> pokemonGrantOperationIds = const <String?>[],
    List<String?> railProgressionOperationIds = const <String?>[],
    Map<String, PreparedScenePokemonGift> preparedPokemonGifts = const {},
    int? completionRecordedAtEpochMs,
    Map<String, GameCompletionPartyRecord> preparedCompletionPartyRecords = const {},
  }) {
    var nextState = gameState;
    final applied = <SceneConsequence>[];
    SceneFinishGameConsequence? gameCompletion;
    final factWriter = NarrativeFactRuntimeWriter(
      NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    for (var index = 0; index < consequences.length; index += 1) {
      final consequence = consequences[index];
      final grantOperationId = index < pokemonGrantOperationIds.length
          ? pokemonGrantOperationIds[index]
          : null;
      final railOperationId = index < railProgressionOperationIds.length
          ? railProgressionOperationIds[index]
          : null;
      final prepared = preparedPokemonGifts[grantOperationId];
      if (prepared != null) {
        if (consequence != prepared.consequence || pokemonCatalog == null) {
          return SceneConsequenceRuntimeWriteResult.failed(
            gameState: gameState,
            errorCode:
                SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
            message:
                'The prepared Pokemon gift does not match its consequence.',
            failedConsequence: consequence,
            appliedConsequences: const [],
          );
        }
        try {
          nextState = prepared.commit(
            nextState,
            catalog: pokemonCatalog!,
            project: project,
          );
          applied.add(consequence);
          continue;
        } catch (error) {
          return SceneConsequenceRuntimeWriteResult.failed(
            gameState: gameState,
            errorCode:
                SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
            message: 'Prepared Pokemon gift commit failed: $error',
            failedConsequence: consequence,
            appliedConsequences: const [],
          );
        }
      }
      final step = _apply(
        nextState,
        consequence,
        factWriter,
        grantOperationId,
        railOperationId,
        completionRecordedAtEpochMs,
        preparedCompletionPartyRecords,
      );
      if (step.errorCode != null) {
        return SceneConsequenceRuntimeWriteResult.failed(
          gameState: gameState,
          errorCode: step.errorCode!,
          message: step.message!,
          failedConsequence: consequence,
          appliedConsequences: const <SceneConsequence>[],
        );
      }
      nextState = step.gameState!;
      gameCompletion ??= step.gameCompletion;
      applied.add(consequence);
    }
    return SceneConsequenceRuntimeWriteResult.applied(
      gameState: nextState,
      appliedConsequences: applied,
      gameCompletion: gameCompletion,
    );
  }

  _SceneConsequenceRuntimeWriteStep _apply(
    GameState gameState,
    SceneConsequence consequence,
    NarrativeFactRuntimeWriter factWriter,
    String? pokemonGrantOperationId,
    String? railProgressionOperationId,
    int? completionRecordedAtEpochMs,
    Map<String, GameCompletionPartyRecord> preparedCompletionPartyRecords,
  ) {
    return switch (consequence.kind) {
      SceneConsequenceKind.setPlayerAvatar => _applySetPlayerAvatar(
          gameState,
          consequence as SceneSetPlayerAvatarConsequence,
        ),
      SceneConsequenceKind.setMapEventInstanceBoolean =>
        _applyMapEventInstanceBoolean(
          gameState,
          consequence as SceneSetMapEventInstanceBooleanConsequence,
        ),
      SceneConsequenceKind.setFact => _applySetFact(
        gameState,
        consequence as SceneSetFactConsequence,
        factWriter,
      ),
      SceneConsequenceKind.calculateIntegerFacts => _integerWriteResult(
        SceneIntegerOperations(factWriter.resolver).calculate(gameState, consequence as SceneCalculateIntegerFactsConsequence)),
      SceneConsequenceKind.adjustMoney => _integerWriteResult(
        SceneIntegerOperations(factWriter.resolver).adjustMoney(gameState, consequence as SceneAdjustMoneyConsequence)),
      SceneConsequenceKind.adjustIntegerFact => _factWriteResult(
        factWriter.adjustIntegerFact(
          gameState: gameState,
          factId: (consequence as SceneAdjustIntegerFactConsequence).factId,
          delta: consequence.delta,
          minimum: consequence.minimum,
          maximum: consequence.maximum,
        ),
      ),
      SceneConsequenceKind.markEventConsumed => _applyMarkEventConsumed(
          gameState,
          consequence as SceneMarkEventConsumedConsequence,
        ),
      SceneConsequenceKind.completeStoryStep => _applyCompleteStoryStep(
          gameState,
          consequence as SceneCompleteStoryStepConsequence,
        ),
      SceneConsequenceKind.giveItem => _applyGiveItem(
          gameState,
          consequence as SceneGiveItemConsequence,
        ),
      SceneConsequenceKind.takeItem => _applyTakeItem(
          gameState,
          consequence as SceneTakeItemConsequence,
        ),
      SceneConsequenceKind.giveMoney => _applyGiveMoney(
          gameState,
          consequence as SceneGiveMoneyConsequence,
        ),
      SceneConsequenceKind.grantRailCurrency => _applyGrantRailCurrency(
          gameState,
          consequence as SceneGrantRailCurrencyConsequence,
          railProgressionOperationId,
        ),
      SceneConsequenceKind.grantRailStamp => _applyGrantRailStamp(
          gameState,
          consequence as SceneGrantRailStampConsequence,
          railProgressionOperationId,
        ),
      SceneConsequenceKind.givePokemon => _applyGivePokemon(
          gameState,
          consequence as SceneGivePokemonConsequence,
          pokemonGrantOperationId,
        ),
      SceneConsequenceKind.setNpcPose => _applySetNpcPose(gameState, consequence as SceneSetNpcPoseConsequence),
      SceneConsequenceKind.markPokemonSeen => _applyMarkPokemonSeen(gameState, consequence as SceneMarkPokemonSeenConsequence),
      SceneConsequenceKind.givePokemonFromCatalog => _applyCatalogPokemon(
          gameState,
          consequence as SceneGivePokemonFromCatalogConsequence,
          pokemonGrantOperationId,
        ),
      SceneConsequenceKind.giveConfiguredStarter => _applyConfiguredStarter(
          gameState,
          consequence as SceneGiveConfiguredStarterConsequence,
          pokemonGrantOperationId,
        ),
      SceneConsequenceKind.healParty => _applyHealParty(gameState),
      SceneConsequenceKind.awardBadge => _applyAwardBadge(
          gameState,
          consequence as SceneAwardBadgeConsequence,
        ),
      SceneConsequenceKind.unlockFieldAbility => _applyUnlockFieldAbility(
          gameState,
          consequence as SceneUnlockFieldAbilityConsequence,
        ),
      SceneConsequenceKind.setNpcPresence => _applySetNpcPresence(
          gameState,
          consequence as SceneSetNpcPresenceConsequence,
        ),
      SceneConsequenceKind.setPauseMenuEntryVisibility =>
        _applySetPauseMenuEntryVisibility(
          gameState,
          consequence as SceneSetPauseMenuEntryVisibilityConsequence,
        ),
      SceneConsequenceKind.finishGame => _applyFinishGame(
          gameState,
          consequence as SceneFinishGameConsequence,
          completionRecordedAtEpochMs,
          preparedCompletionPartyRecords,
        ),
    };
  }

  _SceneConsequenceRuntimeWriteStep _applySetPlayerAvatar(
    GameState gameState,
    SceneSetPlayerAvatarConsequence consequence,
  ) {
    try {
      final character = resolveScenePlayerAvatarCharacter(project, consequence.characterId);
      return _SceneConsequenceRuntimeWriteStep.applied(gameState.copyWith(
        trainerProfile: gameState.trainerProfile.copyWith(avatarCharacterId: character.id),
      ));
    } on FormatException catch (error) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPlayerAvatar,
        error.message,
      );
    }
  }

  _SceneConsequenceRuntimeWriteStep _applyMapEventInstanceBoolean(
    GameState gameState,
    SceneSetMapEventInstanceBooleanConsequence consequence,
  ) {
    final map = mapsById[consequence.mapId];
    if (map == null ||
        map.id != consequence.mapId ||
        project.maps.where((entry) => entry.id == consequence.mapId).length !=
            1) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
        'The map event instance owner map is unavailable.',
      );
    }
    if (map.entities
            .where((entity) => entity.id == consequence.eventId)
            .length !=
        1) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
        'The map event instance owner must be declared exactly once.',
      );
    }
    final scope = mapInstanceScopes[consequence.mapId];
    if (scope == null) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingMapInstanceScope,
        'The Scene has no captured map event instance scope.',
      );
    }
    try {
      return _SceneConsequenceRuntimeWriteStep.applied(
        applySceneMapEventInstanceBoolean(
          gameState: gameState,
          consequence: consequence,
          map: map,
          expectedInstance: scope,
        ),
      );
    } on StateError catch (error) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.staleMapInstanceScope,
        error.message,
      );
    }
  }

  _SceneConsequenceRuntimeWriteStep _applySetFact(
    GameState gameState,
    SceneSetFactConsequence consequence,
    NarrativeFactRuntimeWriter factWriter,
  ) {
    final result = factWriter.setFactValue(
      gameState: gameState,
      factId: consequence.factId,
      value: consequence.narrativeValue,
    );
    return _factWriteResult(result);
  }

  _SceneConsequenceRuntimeWriteStep _factWriteResult(
    NarrativeFactRuntimeWriteResult result,
  ) {
    if (result is NarrativeFactRuntimeWriteRejected) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        switch (result.errorCode) {
          NarrativeFactRuntimeWriteErrorCode.unknownFact =>
            SceneConsequenceRuntimeWriteErrorCode.unknownFact,
          NarrativeFactRuntimeWriteErrorCode.ambiguousFact =>
            SceneConsequenceRuntimeWriteErrorCode.ambiguousFact,
          NarrativeFactRuntimeWriteErrorCode.invalidRuntimeKey =>
            SceneConsequenceRuntimeWriteErrorCode.invalidFactRuntimeKey,
          NarrativeFactRuntimeWriteErrorCode.typeMismatch =>
            SceneConsequenceRuntimeWriteErrorCode.factTypeMismatch,
        },
        result.message,
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(result.gameState);
  }

  _SceneConsequenceRuntimeWriteStep _applyMarkEventConsumed(
    GameState gameState,
    SceneMarkEventConsumedConsequence consequence,
  ) {
    final projectHasMap =
        project.maps.any((map) => map.id == consequence.mapId,
    );
    final mapData = mapsById[consequence.mapId];
    if (!projectHasMap || mapData == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
        'Scene consequence markEventConsumed references unknown map '
        '"${consequence.mapId}".',
      );
    }
    final hasEvent =
        mapData.events.any((event) => event.id == consequence.eventId,
    );
    if (!hasEvent) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownEvent,
        'Scene consequence markEventConsumed references unknown event '
        '"${consequence.eventId}" on map "${consequence.mapId}".',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.markEventConsumed(gameState, consequence.eventId),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyCompleteStoryStep(
    GameState gameState,
    SceneCompleteStoryStepConsequence consequence,
  ) {
    final matches = <StorylineStep>[
      for (final storyline in project.storylines)
        for (final chapter in storyline.chapters)
          for (final step in chapter.steps)
            if (step.id == consequence.stepId) step,
    ];
    if (matches.isEmpty) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownStoryStep,
        'Scene consequence completeStoryStep references unknown Story Step '
        '"${consequence.stepId}".',
      );
    }
    if (matches.length > 1) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.ambiguousStoryStep,
        'Scene consequence completeStoryStep references ambiguous Story Step '
        '"${consequence.stepId}".',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.completeStep(gameState, consequence.stepId),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyGiveItem(
    GameState gameState,
    SceneGiveItemConsequence consequence,
  ) {
    final validation = _validateItemReferenceAndQuantity(
      itemId: consequence.itemId,
      quantity: consequence.quantity,
      kind: 'giveItem',
    );
    if (validation != null) {
      return validation;
    }
    final given = const BagOperations().give(BagGiveRequest(
      bag: gameState.bag,
      itemId: consequence.itemId,
      quantity: consequence.quantity,
      capacity: project.bagCapacity,
      itemCatalog: itemCatalog,
    ));
    if (!given.isSuccess) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.itemGrantRejected,
        runtimeBagGrantFailureMessage(given.failure!),
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      gameState.copyWith(bag: given.bag),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyTakeItem(
    GameState gameState,
    SceneTakeItemConsequence consequence,
  ) {
    final validation = _validateItemReferenceAndQuantity(
      itemId: consequence.itemId,
      quantity: consequence.quantity,
      kind: 'takeItem',
    );
    if (validation != null) {
      return validation;
    }
    final availableQuantity = mutations.itemQuantity(
      gameState,
      consequence.itemId,
    );
    if (availableQuantity < consequence.quantity) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.insufficientItemQuantity,
        'Scene consequence takeItem requires ${consequence.quantity} of '
        '"${consequence.itemId}", but only $availableQuantity is available.',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.removeItemForNarrativeConsequence(
        gameState,
        itemId: consequence.itemId,
        quantity: consequence.quantity,
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep? _validateItemReferenceAndQuantity({
    required String itemId,
    required int quantity,
    required String kind,
  }) {
    if (itemId.trim().isEmpty) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingItemReference,
        'Scene consequence $kind requires a non-empty item reference.',
      );
    }
    if (quantity <= 0) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidQuantity,
        'Scene consequence $kind requires a positive quantity.',
      );
    }
    return null;
  }

  _SceneConsequenceRuntimeWriteStep _applyGiveMoney(
    GameState gameState,
    SceneGiveMoneyConsequence consequence,
  ) {
    if (consequence.amount <= 0) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidMoneyAmount,
        'Scene consequence giveMoney requires a positive amount.',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.addMoney(gameState, consequence.amount),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyGrantRailCurrency(
    GameState gameState,
    SceneGrantRailCurrencyConsequence consequence,
    String? progressionOperationId,
  ) {
    final operationId = progressionOperationId?.trim() ?? '';
    if (operationId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingRailProgressionOperationId,
        'Scene consequence grantRailCurrency requires a runtime operation id.',
      );
    }
    late final RailProgressionOperationBinding binding;
    try {
      binding = RailProgressionOperationBinding(
        kind: RailProgressionOperationKind.grantCurrency,
        semanticId: consequence.semanticCurrencyId,
        amount: consequence.amount,
      ).validated();
    } on StateError {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidRailProgressionGrant,
        'Scene consequence grantRailCurrency requires a currency id and '
        'positive amount.',
      );
    }
    final progress = gameState.railJourneyProgress;
    final existing = progress.appliedProgressionOperations[operationId];
    if (existing != null) {
      return existing == binding
          ? _SceneConsequenceRuntimeWriteStep.applied(gameState)
          : const _SceneConsequenceRuntimeWriteStep.failed(
              SceneConsequenceRuntimeWriteErrorCode
                  .railProgressionIdempotencyConflict,
              'Rail progression operation id was reused with another payload.',
            );
    }
    final balances = Map<String, int>.of(progress.semanticCurrencyBalances);
    balances[binding.semanticId] =
        (balances[binding.semanticId] ?? 0) + binding.amount;
    return _SceneConsequenceRuntimeWriteStep.applied(
      gameState.copyWith(
        railJourneyProgress: progress.copyWith(
          semanticCurrencyBalances: balances,
          appliedProgressionOperations: <String,
              RailProgressionOperationBinding>{
            ...progress.appliedProgressionOperations,
            operationId: binding,
          },
        ).validated(),
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyGrantRailStamp(
    GameState gameState,
    SceneGrantRailStampConsequence consequence,
    String? progressionOperationId,
  ) {
    final operationId = progressionOperationId?.trim() ?? '';
    if (operationId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingRailProgressionOperationId,
        'Scene consequence grantRailStamp requires a runtime operation id.',
      );
    }
    late final RailProgressionOperationBinding binding;
    try {
      binding = RailProgressionOperationBinding(
        kind: RailProgressionOperationKind.grantStamp,
        semanticId: consequence.stampId,
      ).validated();
    } on StateError {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidRailProgressionGrant,
        'Scene consequence grantRailStamp requires a stamp id.',
      );
    }
    final progress = gameState.railJourneyProgress;
    final existing = progress.appliedProgressionOperations[operationId];
    if (existing != null) {
      return existing == binding
          ? _SceneConsequenceRuntimeWriteStep.applied(gameState)
          : const _SceneConsequenceRuntimeWriteStep.failed(
              SceneConsequenceRuntimeWriteErrorCode
                  .railProgressionIdempotencyConflict,
              'Rail progression operation id was reused with another payload.',
            );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      gameState.copyWith(
        railJourneyProgress: progress.copyWith(
          earnedStampIds: <String>{
            ...progress.earnedStampIds,
            binding.semanticId,
          },
          appliedProgressionOperations: <String,
              RailProgressionOperationBinding>{
            ...progress.appliedProgressionOperations,
            operationId: binding,
          },
        ).validated(),
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyGivePokemon(
    GameState gameState,
    SceneGivePokemonConsequence consequence,
    String? grantOperationId,
  ) {
    final operationId = grantOperationId?.trim() ?? '';
    if (operationId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPokemonGrantOperationId,
        'Scene consequence givePokemon requires a grant operation id.',
      );
    }
    if (gameState.appliedPokemonGrantOperationIds.contains(operationId)) {
      return _SceneConsequenceRuntimeWriteStep.applied(gameState);
    }
    if (consequence.speciesId.trim().isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPokemonSpeciesReference,
        'Scene consequence givePokemon requires a non-empty species reference.',
      );
    }
    if (consequence.formId.trim().isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPokemonFormReference,
        'Scene consequence givePokemon requires a non-empty form reference.',
      );
    }
    if (consequence.level < 1 || consequence.level > 100) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPokemonLevel,
        'Scene consequence givePokemon level must be between 1 and 100.',
      );
    }
    if (consequence.currentHp <= 0) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPokemonCurrentHp,
        'Scene consequence givePokemon requires positive authored current HP.',
      );
    }
    if (consequence.natureId.trim().isEmpty ||
        consequence.abilityId.trim().isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        'Scene consequence givePokemon requires non-empty nature and ability '
        'references.',
      );
    }
    if (consequence.friendship < 0 || consequence.friendship > 255) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        'Scene consequence givePokemon friendship must be between 0 and 255.',
      );
    }
    if (gameState.party.members.length >= _maxPartySize) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.partyFull,
        'Scene consequence givePokemon cannot add "${consequence.speciesId}": '
        'the party is full.',
      );
    }

    final unresolvedPokemon = PlayerPokemon(
      speciesId: consequence.speciesId,
      formId: consequence.formId,
      natureId: consequence.natureId,
      abilityId: consequence.abilityId,
      level: consequence.level,
      currentHp: consequence.currentHp,
      nickname: consequence.nickname,
      friendship: consequence.friendship,
      provenance: PlayerPokemonProvenance(
        kind: PlayerPokemonOriginKind.gift,
        mapId: gameState.currentMapId,
        sourceId: consequence.label ?? '',
        metLevel: consequence.level,
      ),
    );
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.givePokemonOnce(
        gameState,
        grantOperationId: operationId,
        pokemon: unresolvedPokemon,
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep _integerWriteResult(SceneIntegerOperationResult result) =>
    result.success ? _SceneConsequenceRuntimeWriteStep.applied(result.gameState) :
      _SceneConsequenceRuntimeWriteStep.failed(switch (result.error!) {
        SceneIntegerOperationError.unknownFact => SceneConsequenceRuntimeWriteErrorCode.unknownFact,
        SceneIntegerOperationError.ambiguousFact => SceneConsequenceRuntimeWriteErrorCode.ambiguousFact,
        SceneIntegerOperationError.invalidRuntimeKey => SceneConsequenceRuntimeWriteErrorCode.invalidFactRuntimeKey,
        SceneIntegerOperationError.typeMismatch => SceneConsequenceRuntimeWriteErrorCode.factTypeMismatch,
        _ => SceneConsequenceRuntimeWriteErrorCode.integerOperationRejected,
      }, 'Integer operation rejected: ${result.error!.name}.');

  _SceneConsequenceRuntimeWriteStep _applySetNpcPose(GameState gameState, SceneSetNpcPoseConsequence consequence) {
    final map = mapsById[consequence.mapId];
    final owner = map?.entities.where((e) => e.id == consequence.entityId).singleOrNull;
    final scope = mapInstanceScopes[consequence.mapId];
    final savedPose = gameState.mapInstanceWorldState.instancesByMapId[consequence.mapId]?.npcPoses[consequence.entityId];
    final position = consequence.x == null
        ? savedPose?.position ?? owner?.pos
        : GridPos(x: consequence.x!, y: consequence.y!);
    if (map == null || map.version == ProjectVersion.v9 || map.spatialScene != null || owner == null ||
        project.maps.where((m) => m.id == map.id).length != 1 || owner.presentation == null ||
        !owner.presentation!.variants.any((v) => v.characterId != null) ||
        validateMapEntityPresentation(project: project, map: map, entity: owner).isNotEmpty ||
        position == null || position.x < 0 || position.y < 0 ||
        position.x + owner.size.width > map.size.width || position.y + owner.size.height > map.size.height ||
        owner.presentation!.variants.any((v) => position.x + v.size.width > map.size.width || position.y + v.size.height > map.size.height)) {
      return const _SceneConsequenceRuntimeWriteStep.failed(SceneConsequenceRuntimeWriteErrorCode.unknownNpc, 'NPC placement requires a declared two-dimensional presentation owner and bounded cell.');
    }
    var presentationUnavailable = false;
    final variant = resolveMapEntityPresentation(
      project: project,
      gameState: gameState,
      map: map,
      entity: owner,
      onUnavailable: () => presentationUnavailable = true,
    );
    if (presentationUnavailable || (consequence.x != null && variant?.characterId != null)) {
      return const _SceneConsequenceRuntimeWriteStep.failed(SceneConsequenceRuntimeWriteErrorCode.unknownNpc, 'Logical NPC placement requires its current presentation to be hidden.');
    }
    if (scope == null || gameState.mapInstanceWorldState.instanceRef(map.id) != scope) {
      return const _SceneConsequenceRuntimeWriteStep.failed(SceneConsequenceRuntimeWriteErrorCode.staleMapInstanceScope, 'NPC placement requires the captured current map instance.');
    }
    final poses = gameState.mapInstanceWorldState.instancesByMapId[map.id]!.npcPoses;
    final facing = consequence.facing ?? poses[owner.id]?.facing ?? owner.npc?.facing ??
        owner.presentation!.variants.firstWhere((v) => v.characterId != null).facing;
    final next = gameState.mapInstanceWorldState.setNpcPoses(scope, {...poses,
      owner.id: MapInstanceNpcPose(position: position, facing: facing)});
    return _SceneConsequenceRuntimeWriteStep.applied(gameState.copyWith(mapInstanceWorldState: next));
  }

  _SceneConsequenceRuntimeWriteStep _applyMarkPokemonSeen(GameState gameState, SceneMarkPokemonSeenConsequence consequence) {
    if (!project.pokemon.enabled || pokemonCatalog?.entries.containsKey(consequence.speciesId) != true) {
      return const _SceneConsequenceRuntimeWriteStep.failed(SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition, 'Seen species requires an available active native Pokemon catalog entry.');
    }
    return _SceneConsequenceRuntimeWriteStep.applied(markSpeciesSeenInGameState(gameState, consequence.speciesId));
  }

  _SceneConsequenceRuntimeWriteStep _applyCatalogPokemon(
    GameState gameState,
    SceneGivePokemonFromCatalogConsequence consequence,
    String? grantOperationId,
  ) {
    final operationId = grantOperationId?.trim() ?? '';
    if (operationId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPokemonGrantOperationId,
        'Catalog gift requires a grant operation id.',
      );
    }
    if (gameState.appliedPokemonGrantOperationIds.contains(operationId)) {
      return _SceneConsequenceRuntimeWriteStep.applied(gameState);
    }
    final catalog = pokemonCatalog;
    if (catalog == null) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        'Catalog gift requires a preloaded active project Pokemon catalog.',
      );
    }
    final PlayerPokemon pokemon;
    try {
      pokemon = catalog.generate(consequence: consequence, state: gameState,
          operationId: operationId, ruleset: project.pokemon.ruleset);
    } on FormatException catch (error) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.invalidPokemonDefinition,
        error.message,
      );
    }
    final granted = mutations.givePokemonOnce(gameState,
        grantOperationId: operationId, pokemon: pokemon);
    if (!granted.appliedPokemonGrantOperationIds.contains(operationId)) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.pokemonGrantRejected,
        'Catalog gift could not be acquired by party or PC.',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(granted.copyWith(
      progression: granted.progression.copyWith(
        caughtSpeciesIds: {...granted.progression.caughtSpeciesIds, pokemon.speciesId}.toList(),
        seenSpeciesIds: {...granted.progression.seenSpeciesIds, pokemon.speciesId}.toList(),
      ).normalized(),
    ));
  }

  _SceneConsequenceRuntimeWriteStep _applyConfiguredStarter(
    GameState gameState,
    SceneGiveConfiguredStarterConsequence consequence,
    String? grantOperationId,
  ) {
    final operationId = grantOperationId?.trim() ?? '';
    if (operationId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPokemonGrantOperationId,
        'Scene consequence giveConfiguredStarter requires a grant operation id.',
      );
    }
    if (gameState.appliedPokemonGrantOperationIds.contains(operationId)) {
      return _SceneConsequenceRuntimeWriteStep.applied(gameState);
    }
    final optionId = consequence.starterOptionId.trim();
    if (optionId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingStarterOptionReference,
        'Scene consequence giveConfiguredStarter requires a configured New Game option.',
      );
    }
    final matches = project.newGame.starterOptions
        .where((option) => option.id == optionId)
        .toList(growable: false);
    if (matches.isEmpty) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownStarterOption,
        'Scene consequence giveConfiguredStarter references unknown New Game option "$optionId".',
      );
    }
    if (matches.length > 1) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.ambiguousStarterOption,
        'Scene consequence giveConfiguredStarter references ambiguous New Game option "$optionId".',
      );
    }
    if (gameState.party.members.length >= _maxPartySize) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.partyFull,
        'Scene consequence giveConfiguredStarter cannot add "$optionId": the party is full.',
      );
    }

    final authoredPokemon = matches.single.pokemon.copyWith(individualId: '');
    final starterWithProvenance = authoredPokemon.provenance == null
        ? authoredPokemon.copyWith(
            provenance: PlayerPokemonProvenance(
              kind: PlayerPokemonOriginKind.starter,
              mapId: gameState.currentMapId,
              sourceId: optionId,
              metLevel: authoredPokemon.level,
            ),
          )
        : authoredPokemon;
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.givePokemonOnce(
        gameState,
        grantOperationId: operationId,
        pokemon: starterWithProvenance,
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyHealParty(GameState gameState) {
    if (gameState.party.members.isEmpty) {
      return _SceneConsequenceRuntimeWriteStep.applied(gameState);
    }
    final hasAllHpCaps = List<int>.generate(
      gameState.party.members.length,
      (index) => index,
    ).every((index) => (maxHpByPartyIndex[index] ?? 0) > 0);
    if (!hasAllHpCaps) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPartyRecoveryCaps,
        'Scene consequence healParty requires runtime HP caps for every '
        'party member.',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.recoverParty(
        gameState,
        maxHpByPartyIndex: maxHpByPartyIndex,
        maxPpByPartyIndex: maxPpByPartyIndex,
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyAwardBadge(
    GameState gameState,
    SceneAwardBadgeConsequence consequence,
  ) {
    final badgeId = consequence.badgeId.trim();
    if (badgeId.isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingBadgeReference,
        'Scene consequence awardBadge requires a badge reference.',
      );
    }
    final matches = project.badges
        .where((badge) => badge.id == badgeId)
        .toList(growable: false);
    if (matches.isEmpty) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownBadge,
        'Scene consequence awardBadge references unknown badge "$badgeId".',
      );
    }
    if (matches.length > 1) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.ambiguousBadge,
        'Scene consequence awardBadge references ambiguous badge "$badgeId".',
      );
    }

    var nextState = gameState;
    if (!nextState.trainerProfile.badgeIds.contains(badgeId)) {
      nextState = nextState.copyWith(
        trainerProfile: nextState.trainerProfile.copyWith(
          badgeIds: <String>[
            ...nextState.trainerProfile.badgeIds,
            badgeId],
        ),
      );
    }
    final ability = matches.single.fieldAbilityUnlock;
    if (ability != null) {
      nextState = mutations.unlockFieldAbility(nextState, ability);
    }
    return _SceneConsequenceRuntimeWriteStep.applied(nextState);
  }

  _SceneConsequenceRuntimeWriteStep _applyUnlockFieldAbility(
    GameState gameState,
    SceneUnlockFieldAbilityConsequence consequence,
  ) {
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.unlockFieldAbility(gameState, consequence.ability),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applySetPauseMenuEntryVisibility(
    GameState gameState,
    SceneSetPauseMenuEntryVisibilityConsequence consequence,
  ) {
    return _SceneConsequenceRuntimeWriteStep.applied(
      gameState.copyWith(
        pauseMenuState: gameState.pauseMenuState.setActionVisibility(
          consequence.actionId,
          visible: consequence.visible,
        ),
      ),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyFinishGame(
    GameState gameState,
    SceneFinishGameConsequence consequence,
    int? completionRecordedAtEpochMs,
    Map<String, GameCompletionPartyRecord> preparedCompletionPartyRecords,
  ) {
    final completedEndingId =
        gameState.metadata[sceneGameCompletionEndingMetadataKey];
    if (completedEndingId != null) {
      if (completedEndingId == consequence.endingId) {
        return _SceneConsequenceRuntimeWriteStep.applied(gameState);
      }
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.gameAlreadyCompleted,
        'Scene consequence finishGame cannot replace completed ending '
        '"$completedEndingId" with "${consequence.endingId}".',
      );
    }
    var nextState = gameState;
    if (consequence.recordParty) {
      if (completionRecordedAtEpochMs == null) {
        return _SceneConsequenceRuntimeWriteStep.failed(
          SceneConsequenceRuntimeWriteErrorCode.invalidCompletionPartyRecord,
          'Party recording requires a frozen completion timestamp.',
        );
      }
      try {
        nextState = recordGameCompletionParty(
          gameState: gameState,
          endingId: consequence.endingId,
          completedAtEpochMs: completionRecordedAtEpochMs,
          preparedRecord: preparedCompletionPartyRecords[consequence.endingId],
        );
      } on FormatException catch (error) {
        return _SceneConsequenceRuntimeWriteStep.failed(
          SceneConsequenceRuntimeWriteErrorCode.invalidCompletionPartyRecord,
          'Party recording failed: $error',
        );
      }
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      nextState.copyWith(
        metadata: <String, String>{
          ...gameState.metadata,
          sceneGameCompletionEndingMetadataKey: consequence.endingId,
          sceneGameCompletionPostGamePolicyMetadataKey:
              consequence.postGamePolicy.name,
        },
      ),
      gameCompletion: consequence,
    );
  }

  _SceneConsequenceRuntimeWriteStep _applySetNpcPresence(
    GameState gameState,
    SceneSetNpcPresenceConsequence consequence,
  ) {
    final map = mapsById[consequence.mapId];
    MapEntity? npc;
    if (map != null) {
      for (final entity in map.entities) {
        if (entity.id == consequence.entityId &&
            entity.kind == MapEntityKind.npc) {
          npc = entity;
          break;
        }
      }
    }
    if (npc == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownNpc,
        'Scene consequence setNpcPresence references unknown NPC '
        '"${consequence.mapId}:${consequence.entityId}".',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      gameState.copyWith(
        metadata: <String, String>{
          ...gameState.metadata,
          sceneNpcPresenceMetadataKey(
            mapId: consequence.mapId,
            entityId: consequence.entityId,
          ): consequence.present ? 'present' : 'hidden',
        },
      ),
    );
  }
}

final class _SceneConsequenceRuntimeWriteStep {
  const _SceneConsequenceRuntimeWriteStep._({
    this.gameState,
    this.errorCode,
    this.message,
    this.gameCompletion,
  });

  const _SceneConsequenceRuntimeWriteStep.applied(
    GameState gameState, {
    SceneFinishGameConsequence? gameCompletion,
  }) : this._(
          gameState: gameState,
          gameCompletion: gameCompletion);

  const _SceneConsequenceRuntimeWriteStep.failed(
    SceneConsequenceRuntimeWriteErrorCode errorCode,
    String message,
  ) : this._(
          errorCode: errorCode,
          message: message);

  final GameState? gameState;
  final SceneConsequenceRuntimeWriteErrorCode? errorCode;
  final String? message;
  final SceneFinishGameConsequence? gameCompletion;
}
