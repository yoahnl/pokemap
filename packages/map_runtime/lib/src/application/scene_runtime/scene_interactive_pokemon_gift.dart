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
    if (generated != generatedPokemon) {
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
  );
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
  var revision = 0;
  Future<SceneInteractionResult> ask(
    PokemonGiftInteractionStage stage,
    String message, {
    bool confirmation = false,
    bool text = false,
  }) async {
    final prompt = SceneInteractionPrompt(
      localizationKey: 'pokemonGift.${stage.name}',
      fallbackText: message,
      arguments: {'speciesId': pokemon.speciesId},
    );
    final id = '$operationId:${stage.name}';
    final SceneInteractionRequest interaction = text
        ? SceneTextInteractionRequest(
            requestId: id,
            revision: revision++,
            prompt: prompt,
            constraints: SceneTextInputConstraints(
              maxGraphemes: command.nicknameMaxGraphemes,
            ),
          )
        : confirmation
        ? SceneConfirmationInteractionRequest(
            requestId: id,
            revision: revision++,
            prompt: prompt,
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
        projectedState: acquisition.state,
      ),
    );
    if (result is SceneCancelledInteractionResult ||
        interaction.validateResult(result).isNotEmpty) {
      throw StateError(
        'The Pokemon gift interaction was dismissed or became stale.',
      );
    }
    if (_giftFingerprint(readProjectedState()) != _giftFingerprint(state)) {
      throw StateError('The Pokemon gift state changed during interaction.');
    }
    return result;
  }

  await ask(PokemonGiftInteractionStage.received, 'Vous recevez un Pokémon !');
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
  if (command.pokedexPresentationPolicy ==
          ScenePokemonGiftPokedexPresentationPolicy.whenNewAndPokedexVisible &&
      dexVisible &&
      !alreadyCaught) {
    await ask(
      PokemonGiftInteractionStage.pokedex,
      'Une nouvelle fiche Pokédex a été ajoutée.',
    );
  }
  if (command.nicknamePolicy == ScenePokemonGiftNicknamePolicy.offer) {
    final answer = await ask(
      PokemonGiftInteractionStage.nicknameConfirmation,
      'Donner un surnom à ce Pokémon ?',
      confirmation: true,
    );
    if ((answer as SceneConfirmedInteractionResult).value) {
      final answer = await ask(
        PokemonGiftInteractionStage.nickname,
        'Choisissez un surnom.',
        text: true,
      );
      pokemon = pokemon
          .copyWith(
            nickname: (answer as SceneTextSubmittedInteractionResult).value,
          )
          .normalized();
    }
  }
  await ask(
    PokemonGiftInteractionStage.destination,
    outputPortId == 'party'
        ? 'Le Pokémon rejoint votre équipe.'
        : 'Le Pokémon est envoyé au PC.',
  );
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
