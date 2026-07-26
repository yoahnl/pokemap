import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'scene_consequence_runtime_write_result.dart';
import 'scene_game_completion_metadata.dart';

final class SceneConsequenceRuntimeWriter {
  const SceneConsequenceRuntimeWriter({
    required this.project,
    this.mapsById = const <String, MapData>{},
    this.maxHpByPartyIndex = const <int, int>{},
    this.maxPpByPartyIndex = const <int, Map<String, int>>{},
    this.mutations = const GameStateMutations(),
  });

  final ProjectManifest project;
  final Map<String, MapData> mapsById;
  final Map<int, int> maxHpByPartyIndex;
  final Map<int, Map<String, int>> maxPpByPartyIndex;
  final GameStateMutations mutations;

  static const int _maxPartySize = 6;

  /// Prevalidates and applies one canonical Action-node consequence.
  ///
  /// The returned state is a new immutable checkpoint. A rejected write
  /// returns the original [gameState] and never exposes a partial mutation.
  SceneConsequenceRuntimeWriteResult applyOne(
    GameState gameState,
    SceneConsequence consequence,
  ) {
    return applyAll(gameState, <SceneConsequence>[consequence]);
  }

  SceneConsequenceRuntimeWriteResult applyAll(
    GameState gameState,
    List<SceneConsequence> consequences,
  ) {
    var nextState = gameState;
    final applied = <SceneConsequence>[];
    SceneFinishGameConsequence? gameCompletion;
    final factWriter = NarrativeFactRuntimeWriter(
      NarrativeFactRuntimeResolver.fromFacts(project.facts),
    );
    for (final consequence in consequences) {
      final step = _apply(nextState, consequence, factWriter);
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
  ) {
    return switch (consequence.kind) {
      SceneConsequenceKind.setFact => _applySetFact(
          gameState,
          consequence as SceneSetFactConsequence,
          factWriter,
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
      SceneConsequenceKind.givePokemon => _applyGivePokemon(
          gameState,
          consequence as SceneGivePokemonConsequence,
        ),
      SceneConsequenceKind.giveConfiguredStarter => _applyConfiguredStarter(
          gameState,
          consequence as SceneGiveConfiguredStarterConsequence,
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
      SceneConsequenceKind.finishGame => _applyFinishGame(
          gameState,
          consequence as SceneFinishGameConsequence,
        ),
    };
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
        project.maps.any((map) => map.id == consequence.mapId);
    final mapData = mapsById[consequence.mapId];
    if (!projectHasMap || mapData == null) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.unknownMap,
        'Scene consequence markEventConsumed references unknown map '
        '"${consequence.mapId}".',
      );
    }
    final hasEvent =
        mapData.events.any((event) => event.id == consequence.eventId);
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
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.giveItem(gameState, consequence.itemId, consequence.quantity),
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
    final availableQuantity = gameState.bag
        .normalized()
        .entries
        .where((entry) => entry.itemId.trim() == consequence.itemId)
        .fold<int>(0, (total, entry) => total + entry.quantity);
    if (availableQuantity < consequence.quantity) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.insufficientItemQuantity,
        'Scene consequence takeItem requires ${consequence.quantity} of '
        '"${consequence.itemId}", but only $availableQuantity is available.',
      );
    }
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.consumeItem(
        gameState,
        consequence.itemId,
        consequence.quantity,
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

  _SceneConsequenceRuntimeWriteStep _applyGivePokemon(
    GameState gameState,
    SceneGivePokemonConsequence consequence,
  ) {
    if (consequence.speciesId.trim().isEmpty) {
      return const _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.missingPokemonSpeciesReference,
        'Scene consequence givePokemon requires a non-empty species reference.',
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
    if (gameState.party.members.length >= _maxPartySize) {
      return _SceneConsequenceRuntimeWriteStep.failed(
        SceneConsequenceRuntimeWriteErrorCode.partyFull,
        'Scene consequence givePokemon cannot add "${consequence.speciesId}": '
        'the party is full.',
      );
    }

    final pokemon = PlayerPokemon(
      speciesId: consequence.speciesId,
      natureId: consequence.natureId,
      abilityId: consequence.abilityId,
      level: consequence.level,
      currentHp: consequence.currentHp,
    );
    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.givePokemon(gameState, pokemon: pokemon),
    );
  }

  _SceneConsequenceRuntimeWriteStep _applyConfiguredStarter(
    GameState gameState,
    SceneGiveConfiguredStarterConsequence consequence,
  ) {
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

    return _SceneConsequenceRuntimeWriteStep.applied(
      mutations.givePokemon(gameState, pokemon: matches.single.pokemon),
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
            badgeId,
          ],
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

  _SceneConsequenceRuntimeWriteStep _applyFinishGame(
    GameState gameState,
    SceneFinishGameConsequence consequence,
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
    return _SceneConsequenceRuntimeWriteStep.applied(
      gameState.copyWith(
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
          gameCompletion: gameCompletion,
        );

  const _SceneConsequenceRuntimeWriteStep.failed(
    SceneConsequenceRuntimeWriteErrorCode errorCode,
    String message,
  ) : this._(
          errorCode: errorCode,
          message: message,
        );

  final GameState? gameState;
  final SceneConsequenceRuntimeWriteErrorCode? errorCode;
  final String? message;
  final SceneFinishGameConsequence? gameCompletion;
}
