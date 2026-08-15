import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/save_data.dart';

Map<String, dynamic> strictGameStateSaveJson(GameState state) {
  final normalized = normalizeLoadedGameState(state);
  return <String, dynamic>{
    'itemSystemSchemaVersion': currentItemSystemSaveSchemaVersion,
    ...normalized.toJson(),
  };
}

GameState gameStateFromStrictSaveJson(Map<String, dynamic> json) {
  validateItemSystemSaveSchema(json);
  return normalizeLoadedGameState(GameState.fromJson(json));
}

GameState gameStateFromSaveData(SaveData saveData) {
  final normalizedSaveData = saveData.normalized();
  final normalizedProgression = _normalizePokedexProgression(
    progression: normalizedSaveData.progression,
    party: normalizedSaveData.party,
    pokemonStorage: normalizedSaveData.pokemonStorage,
  );
  final migratedFlags = normalizedSaveData.progression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();

  return GameState(
    saveId: normalizedSaveData.saveId,
    currentMapId: normalizedSaveData.currentMapId,
    playerPosition: normalizedSaveData.playerPosition,
    playerFacing: normalizedSaveData.playerFacing,
    playerMovementMode: MovementMode.walk,
    party: normalizedSaveData.party,
    pokemonStorage: normalizedSaveData.pokemonStorage,
    trainerProfile: normalizedSaveData.trainerProfile,
    bag: normalizedSaveData.bag,
    progression: normalizedProgression,
    storyFlags: StoryFlags(activeFlags: migratedFlags),
    narrativeFactRuntimeState: normalizedSaveData.narrativeFactRuntimeState,
    narrativeEventProgress: normalizedSaveData.narrativeEventProgress,
    completedBattleRequestIds:
        normalizedSaveData.completedBattleRequestIds,
    appliedPokemonGrantOperationIds:
        normalizedSaveData.appliedPokemonGrantOperationIds,
    scriptVariables: const ScriptVariables(),
    consumedEventIds: const {},
    metadata: normalizedSaveData.properties,
  );
}

SaveData saveDataFromGameState(GameState gameState) {
  final normalizedGameState = normalizeLoadedGameState(gameState);
  final mergedProgressionFlags = <String>{
    ...normalizedGameState.progression.storyFlags,
    ...normalizedGameState.storyFlags.activeFlags,
  };
  final normalizedProgression = _normalizePokedexProgression(
    progression: normalizedGameState.progression.copyWith(
      storyFlags: mergedProgressionFlags.toList(growable: false),
    ),
    party: normalizedGameState.party,
    pokemonStorage: normalizedGameState.pokemonStorage,
  );

  return SaveData(
    saveId: normalizedGameState.saveId,
    currentMapId: normalizedGameState.currentMapId,
    playerPosition: normalizedGameState.playerPosition,
    playerFacing: normalizedGameState.playerFacing,
    party: normalizedGameState.party,
    pokemonStorage: normalizedGameState.pokemonStorage,
    trainerProfile: normalizedGameState.trainerProfile,
    bag: normalizedGameState.bag,
    progression: normalizedProgression,
    narrativeFactRuntimeState: normalizedGameState.narrativeFactRuntimeState,
    narrativeEventProgress: normalizedGameState.narrativeEventProgress,
    completedBattleRequestIds: normalizedGameState.completedBattleRequestIds,
    appliedPokemonGrantOperationIds:
        normalizedGameState.appliedPokemonGrantOperationIds,
    properties: normalizedGameState.metadata,
  ).normalized();
}
GameState normalizeLoadedGameState(GameState state) {
  final roster = normalizePlayerPokemonRosterIdentities(
    saveId: state.saveId,
    party: state.party,
    pokemonStorage: state.pokemonStorage,
  );
  final stateWithRoster = state.copyWith(
    party: roster.party,
    pokemonStorage: roster.pokemonStorage,
  );
  final normalizedProgression = _normalizePokedexProgression(
    progression: stateWithRoster.progression,
    party: stateWithRoster.party,
    pokemonStorage: stateWithRoster.pokemonStorage,
  );
  final completedBattleRequestIds = stateWithRoster.completedBattleRequestIds
      .map((requestId) => requestId.trim())
      .where((requestId) => requestId.isNotEmpty)
      .toSet();
  final appliedPokemonGrantOperationIds = stateWithRoster
      .appliedPokemonGrantOperationIds
      .map((operationId) => operationId.trim())
      .where((operationId) => operationId.isNotEmpty)
      .toSet();
  if (stateWithRoster.storyFlags.activeFlags.isNotEmpty ||
      normalizedProgression.storyFlags.isEmpty) {
    return stateWithRoster.copyWith(
      progression: normalizedProgression,
      completedBattleRequestIds: completedBattleRequestIds,
      appliedPokemonGrantOperationIds: appliedPokemonGrantOperationIds,
    );
  }
  final migratedFlags = normalizedProgression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();
  return stateWithRoster.copyWith(
    progression: normalizedProgression,
    storyFlags: stateWithRoster.storyFlags.copyWith(activeFlags: migratedFlags),
    completedBattleRequestIds: completedBattleRequestIds,
    appliedPokemonGrantOperationIds: appliedPokemonGrantOperationIds,
  );
}

/// Marque une espèce comme vue dans l'état runtime.
///
/// Le lot 12 reste volontairement minimal :
/// - "seen" doit pouvoir être écrit dès qu'un ennemi est réellement engagé ;
/// - "caught" ne doit jamais être inventé ici ;
/// - la possession réelle continue d'être déduite de la party du joueur.
///
/// Cet helper reste donc borné à une mutation honnête de `seen`, tout en
/// laissant la normalisation partagée garantir les invariants :
/// - `caught` implique `seen` ;
/// - les espèces déjà présentes dans la party finissent toujours dans
///   `caught`, donc aussi dans `seen`.
GameState markSpeciesSeenInGameState(
  GameState state,
  String speciesId,
) {
  final normalizedSpeciesId = speciesId.trim();
  if (normalizedSpeciesId.isEmpty) {
    return normalizeLoadedGameState(state);
  }

  final nextProgression = _normalizePokedexProgression(
    progression: state.progression.copyWith(
      seenSpeciesIds: <String>[
        ...state.progression.seenSpeciesIds,
        normalizedSpeciesId,
      ],
    ),
    party: state.party,
    pokemonStorage: state.pokemonStorage,
  );

  return state.copyWith(
    progression: nextProgression,
  );
}

PlayerProgression _normalizePokedexProgression({
  required PlayerProgression progression,
  required PlayerParty party,
  required PokemonStorage pokemonStorage,
}) {
  // Invariant métier lot 12 :
  // - une espèce possédée via la vraie party du joueur est "caught" ;
  // - tout "caught" doit aussi être "seen" ;
  // - les saves legacy peuvent ne rien stocker, donc on reconstruit ce socle
  //   minimal à partir de la party quand nécessaire.
  final ownedSpeciesIds = party.members
      .map((member) => member.speciesId.trim())
      .where((speciesId) => speciesId.isNotEmpty)
      .toList(growable: true)
    ..addAll(
      pokemonStorage.storedPokemon
          .map((member) => member.speciesId.trim())
          .where((speciesId) => speciesId.isNotEmpty),
    );

  return progression.copyWith(
    caughtSpeciesIds: <String>[
      ...progression.caughtSpeciesIds,
      ...ownedSpeciesIds,
    ],
    seenSpeciesIds: <String>[
      ...progression.seenSpeciesIds,
      ...progression.caughtSpeciesIds,
      ...ownedSpeciesIds,
    ],
  ).normalized();
}
