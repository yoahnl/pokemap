import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/save_data.dart';

GameState gameStateFromSaveData(SaveData saveData) {
  final normalizedSaveData = saveData.normalized();
  final normalizedProgression = _normalizePokedexProgression(
    progression: normalizedSaveData.progression,
    party: normalizedSaveData.party,
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
    trainerProfile: normalizedSaveData.trainerProfile,
    bag: normalizedSaveData.bag,
    progression: normalizedProgression,
    storyFlags: StoryFlags(activeFlags: migratedFlags),
    scriptVariables: const ScriptVariables(),
    consumedEventIds: const {},
    metadata: normalizedSaveData.properties,
  );
}

SaveData saveDataFromGameState(GameState gameState) {
  final mergedProgressionFlags = <String>{
    ...gameState.progression.storyFlags,
    ...gameState.storyFlags.activeFlags,
  };
  final normalizedProgression = _normalizePokedexProgression(
    progression: gameState.progression.copyWith(
      storyFlags: mergedProgressionFlags.toList(growable: false),
    ),
    party: gameState.party,
  );

  return SaveData(
    saveId: gameState.saveId,
    currentMapId: gameState.currentMapId,
    playerPosition: gameState.playerPosition,
    playerFacing: gameState.playerFacing,
    party: gameState.party,
    trainerProfile: gameState.trainerProfile,
    bag: gameState.bag,
    progression: normalizedProgression,
    properties: gameState.metadata,
  ).normalized();
}

GameState normalizeLoadedGameState(GameState state) {
  final normalizedProgression = _normalizePokedexProgression(
    progression: state.progression,
    party: state.party,
  );
  if (state.storyFlags.activeFlags.isNotEmpty ||
      normalizedProgression.storyFlags.isEmpty) {
    return state.copyWith(
      progression: normalizedProgression,
    );
  }
  final migratedFlags = normalizedProgression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();
  return state.copyWith(
    progression: normalizedProgression,
    storyFlags: state.storyFlags.copyWith(activeFlags: migratedFlags),
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
  );

  return state.copyWith(
    progression: nextProgression,
  );
}

PlayerProgression _normalizePokedexProgression({
  required PlayerProgression progression,
  required PlayerParty party,
}) {
  // Invariant métier lot 12 :
  // - une espèce possédée via la vraie party du joueur est "caught" ;
  // - tout "caught" doit aussi être "seen" ;
  // - les saves legacy peuvent ne rien stocker, donc on reconstruit ce socle
  //   minimal à partir de la party quand nécessaire.
  final ownedSpeciesIds = party.members
      .map((member) => member.speciesId.trim())
      .where((speciesId) => speciesId.isNotEmpty)
      .toList(growable: false);

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
