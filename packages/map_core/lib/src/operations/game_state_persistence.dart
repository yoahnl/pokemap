import '../models/enums.dart';
import '../models/game_state.dart';
import '../models/save_data.dart';

GameState gameStateFromSaveData(SaveData saveData) {
  final migratedFlags = saveData.progression.storyFlags
      .map((flag) => flag.trim())
      .where((flag) => flag.isNotEmpty)
      .toSet();

  return GameState(
    saveId: saveData.saveId,
    currentMapId: saveData.currentMapId,
    playerPosition: saveData.playerPosition,
    playerFacing: saveData.playerFacing,
    playerMovementMode: MovementMode.walk,
    party: saveData.party,
    progression: saveData.progression,
    storyFlags: StoryFlags(activeFlags: migratedFlags),
    scriptVariables: const ScriptVariables(),
    consumedEventIds: const {},
    metadata: saveData.properties,
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
    progression: gameState.progression.copyWith(
      storyFlags: mergedProgressionFlags.toList(growable: false),
    ),
    properties: gameState.metadata,
  );
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
