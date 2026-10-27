import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import '../../player/runtime_world_service_models.dart';
import 'runtime_scene_pokemon_catalog.dart';

final class PreparedScenePokemonGift {
  PreparedScenePokemonGift({
    required this.operationId,
    required this.consequence,
    required this.pokemon,
    required this.outputPortId,
    required GameState state,
    required this.generatedPokemon,
  }) : _fingerprint = _giftFingerprint(state);

  final String operationId;
  final SceneGivePokemonFromCatalogConsequence consequence;
  final PlayerPokemon pokemon;
  final String outputPortId;
  final String _fingerprint;
  final PlayerPokemon generatedPokemon;

  GameState commit(
    GameState state, {
    required RuntimeScenePokemonCatalog catalog,
    required ProjectManifest project,
  }) {
    if (state.appliedPokemonGrantOperationIds.contains(operationId)) {
      return state;
    }
    if (_giftFingerprint(state) != _fingerprint) {
      throw StateError('The Pokemon gift state changed before commit.');
    }
    final generated = catalog.generate(
      consequence: consequence,
      state: state,
      operationId: operationId,
      ruleset: project.pokemon.ruleset,
    );
    if (generated.copyWith(isEgg: pokemon.isEgg) != generatedPokemon) {
      throw StateError('The Pokemon gift catalog changed before commit.');
    }
    final acquired = const GameStateMutations().acquirePokemon(
      state,
      pokemon: pokemon,
    );
    if (_port(acquired) != outputPortId) {
      throw StateError('The Pokemon gift destination changed before commit.');
    }
    final granted = const GameStateMutations().givePokemonOnce(
      state,
      grantOperationId: operationId,
      pokemon: pokemon,
    );
    if (!granted.appliedPokemonGrantOperationIds.contains(operationId)) {
      throw StateError('The prepared Pokemon gift was rejected.');
    }
    if (pokemon.isEgg) return granted;
    return granted.copyWith(
      progression: granted.progression
          .copyWith(
            seenSpeciesIds: {
              ...granted.progression.seenSpeciesIds,
              pokemon.speciesId,
            }.toList(),
            caughtSpeciesIds: {
              ...granted.progression.caughtSpeciesIds,
              pokemon.speciesId,
            }.toList(),
          )
          .normalized(),
    );
  }
}

final class ScenePokemonGiftPreparation {
  const ScenePokemonGiftPreparation({
    required this.outputPortId,
    this.prepared,
  });
  final String outputPortId;
  final PreparedScenePokemonGift? prepared;
}

typedef ScenePokemonGiftPresenter = Future<SceneInteractionResult> Function(
  OpenPokemonGiftInteractionService request,
);

Future<ScenePokemonGiftPreparation> receiveScenePokemonFromCatalog({
  required SceneReceivePokemonFromCatalogInteractiveCommand command,
  required String operationId,
  required ProjectManifest project,
  required GameState Function() readProjectedState,
  required RuntimeScenePokemonCatalog catalog,
  required ScenePokemonGiftPresenter present,
}) async {
  if (operationId.trim().isEmpty) {
    throw StateError('The Pokemon gift operation id is missing.');
  }
  final state = readProjectedState();
  final consequence = SceneGivePokemonFromCatalogConsequence(
    speciesId: command.speciesId,
    formId: command.formId,
    level: command.level,
    moveIds: command.moveIds,
  );
  if (state.appliedPokemonGrantOperationIds.contains(operationId)) {
    final owned = [
      ...state.party.members,
      ...state.pokemonStorage.storedPokemon,
    ].where((p) => p.provenance?.sourceId == operationId).toList();
    if (owned.length != 1) {
      throw StateError('The applied Pokemon gift has no unique owned Pokemon.');
    }
    return ScenePokemonGiftPreparation(
      outputPortId: state.party.members.contains(owned.single) ? 'party' : 'pc',
    );
  }
  final generated = catalog.generate(
    consequence: consequence,
    state: state,
    operationId: operationId,
    ruleset: project.pokemon.ruleset,
  ).copyWith(isEgg: command.isEgg);
  if (command.isEgg && state.party.members.length >= maxPlayerPartySize) {
    return const ScenePokemonGiftPreparation(outputPortId: 'noCapacity');
  }
  final acquisition = const GameStateMutations().acquirePokemon(
    state,
    pokemon: generated,
  );
  final outputPortId = _port(acquisition);
  if (outputPortId == 'noCapacity') {
    return const ScenePokemonGiftPreparation(outputPortId: 'noCapacity');
  }
  var pokemon = outputPortId == 'party'
      ? acquisition.state.party.members[acquisition.partyIndex!]
      : acquisition.state.pokemonStorage.storedPokemon[acquisition
            .storageIndex!];
  final defaults =
      project.presentation?.pause?.effectiveActions ??
      defaultProjectPauseActions;
  final dexVisible = state.pauseMenuState.isActionVisible(
    ProjectPauseActionId.pokedex,
    projectDefaultVisibility: defaults.any(
      (action) => action.id == ProjectPauseActionId.pokedex && action.visible,
    ),
  );
  final alreadyCaught =
      state.progression.caughtSpeciesIds.contains(pokemon.speciesId) ||
      state.party.members.any((p) => p.speciesId == pokemon.speciesId) ||
      state.pokemonStorage.storedPokemon.any(
        (p) => p.speciesId == pokemon.speciesId,
      );
  final isNewPokedexEntry =
      command.pokedexPresentationPolicy ==
          ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible &&
      dexVisible &&
      !alreadyCaught;
  final offerNickname =
      command.nicknamePolicy == ScenePokemonGiftNicknamePolicy.offer;
  var revision = 0;
  Future<SceneInteractionResult> ask({required bool nickname}) async {
    final stage = nickname
        ? PokemonGiftInteractionStage.nickname
        : PokemonGiftInteractionStage.received;
    final prompt = SceneInteractionPrompt(
      localizationKey: 'pokemonGift.${stage.name}',
      fallbackText: nickname
          ? 'Choisissez un surnom.'
          : 'Vous recevez un Pokémon !',
      arguments: {'speciesId': pokemon.speciesId},
    );
    final id = '$operationId:${stage.name}';
    final SceneInteractionRequest interaction = nickname
        ? SceneTextInteractionRequest(
            requestId: id,
            revision: revision++,
            prompt: prompt,
            initialValue: pokemon.nickname,
            constraints: SceneTextInputConstraints(
              maxGraphemes: command.nicknameMaxGraphemes,
            ),
          )
        : offerNickname
        ? SceneChoiceInteractionRequest(
            requestId: id,
            revision: revision++,
            prompt: prompt,
            options: [
              SceneInteractionOption(
                id: 'continue',
                label: SceneInteractionPrompt(
                  localizationKey: 'pokemonGift.continue',
                  fallbackText: 'Continuer',
                ),
              ),
              SceneInteractionOption(
                id: 'nickname',
                label: SceneInteractionPrompt(
                  localizationKey: 'pokemonGift.nickname',
                  fallbackText: 'Donner un surnom',
                ),
              ),
            ],
          )
        : SceneMessageInteractionRequest(
            requestId: id,
            revision: revision++,
            prompt: prompt,
          );
    final result = await present(
      OpenPokemonGiftInteractionService(
        interactionId: id,
        interaction: interaction,
        stage: stage,
        pokemon: pokemon,
        projectedState: const GameStateMutations()
            .acquirePokemon(state, pokemon: pokemon)
            .state,
        isNewPokedexEntry: isNewPokedexEntry,
      ),
    );
    if (interaction.validateResult(result).isNotEmpty ||
        result is SceneCancelledInteractionResult &&
            !(nickname &&
                result.reason == SceneInteractionCancellationReason.user)) {
      throw StateError(
        'The Pokemon gift interaction was dismissed or became stale.',
      );
    }
    if (_giftFingerprint(readProjectedState()) != _giftFingerprint(state)) {
      throw StateError('The Pokemon gift state changed during interaction.');
    }
    return result;
  }

  while (true) {
    final receipt = await ask(nickname: false);
    if (receipt is! SceneChoiceSelectedInteractionResult ||
        receipt.selectedOptionId == 'continue') {
      break;
    }
    final answer = await ask(nickname: true);
    if (answer is SceneTextSubmittedInteractionResult) {
      pokemon = pokemon.copyWith(nickname: answer.value).normalized();
    }
  }
  return ScenePokemonGiftPreparation(
    outputPortId: outputPortId,
    prepared: PreparedScenePokemonGift(
      operationId: operationId,
      consequence: consequence,
      pokemon: pokemon,
      generatedPokemon: generated,
      outputPortId: outputPortId,
      state: state,
    ),
  );
}

String _port(CaptureDestinationResult acquisition) =>
    switch (acquisition.destination) {
      CaptureDestinationKind.party => 'party',
      CaptureDestinationKind.storage => 'pc',
      CaptureDestinationKind.none
          when acquisition.failure == CaptureDestinationFailure.storageFull =>
        'noCapacity',
      _ => throw StateError('The catalog Pokemon could not be acquired.'),
    };

String _giftFingerprint(GameState state) => jsonEncode({
  'save': state.saveId,
  'map': state.currentMapId,
  'party': state.party.toJson(),
  'storage': state.pokemonStorage.toJson(),
  'seen': state.progression.seenSpeciesIds,
  'caught': state.progression.caughtSpeciesIds,
  'pause': state.pauseMenuState.toJson(),
  'operations': state.appliedPokemonGrantOperationIds.toList()..sort(),
});
