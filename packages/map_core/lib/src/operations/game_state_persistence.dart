import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/save_data.dart';

GameState gameStateFromSaveData(SaveData saveData) {
  final normalizedSaveData = saveData.normalized();
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
    progression: normalizedSaveData.progression,
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

  return SaveData(
    saveId: gameState.saveId,
    currentMapId: gameState.currentMapId,
    playerPosition: gameState.playerPosition,
    playerFacing: gameState.playerFacing,
    party: gameState.party,
    trainerProfile: gameState.trainerProfile,
    bag: gameState.bag,
    progression: gameState.progression.copyWith(
      storyFlags: mergedProgressionFlags.toList(growable: false),
    ),
    properties: gameState.metadata,
  ).normalized();
}

GameState normalizeLoadedGameState(GameState state) {
  if (state.storyFlags.activeFlags.isNotEmpty ||
      state.progression.storyFlags.isEmpty) {
    return state;
  }
  final migratedFlags = state.progression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();
  return state.copyWith(
    storyFlags: state.storyFlags.copyWith(activeFlags: migratedFlags),
  );
}
