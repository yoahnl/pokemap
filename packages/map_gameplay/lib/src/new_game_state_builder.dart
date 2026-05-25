import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'player_spawn_resolver.dart';

/// Crée un [GameState] initial pour une nouvelle partie.
///
/// Le state produit est propre : party vide, bag vide, flags vides,
/// progression vide, aucun événement consommé.
///
/// [startMapId] : identifiant de la map de départ du projet.
/// [startPosition] : position initiale du joueur (par défaut (0, 0)).
/// [startFacing] : orientation initiale du joueur (par défaut south).
/// [saveId] : identifiant de la sauvegarde (par défaut 'new_game').
/// [playerName] : nom du joueur (par défaut 'Player').
///
/// Lève [ArgumentError] si [startMapId] est vide ou blank.
///
/// Usage :
/// ```dart
/// final state = createNewGameState(startMapId: 'my_start_map');
/// ```
GameState createNewGameState({
  required String startMapId,
  GridPos startPosition = const GridPos(x: 0, y: 0),
  EntityFacing startFacing = EntityFacing.south,
  String saveId = 'new_game',
  String playerName = 'Player',
}) {
  final normalizedMapId = startMapId.trim();
  if (normalizedMapId.isEmpty) {
    throw ArgumentError.value(
      startMapId,
      'startMapId',
      'startMapId must not be empty or blank',
    );
  }

  final normalizedSaveId = saveId.trim().isEmpty ? 'new_game' : saveId.trim();
  final normalizedPlayerName =
      playerName.trim().isEmpty ? 'Player' : playerName.trim();

  return GameState(
    saveId: normalizedSaveId,
    currentMapId: normalizedMapId,
    playerPosition: startPosition,
    playerFacing: startFacing,
    playerMovementMode: MovementMode.walk,
    party: const PlayerParty(),
    trainerProfile: TrainerProfile(name: normalizedPlayerName),
    bag: const Bag(),
    progression: const PlayerProgression(),
    scriptVariables: const ScriptVariables(),
    storyFlags: const StoryFlags(),
    consumedEventIds: const {},
    metadata: const {},
  );
}

/// Crée un [GameState] initial depuis une map de départ authorée.
///
/// Ce helper garde P5-02 au niveau New Game minimal : il résout uniquement la
/// position/facing via le spawn de la map, puis délègue l'initialisation du
/// state à [createNewGameState].
GameState createNewGameStateFromMap({
  required MapData startMap,
  String saveId = 'new_game',
  String playerName = 'Player',
  int tileWidthPx = 16,
  int tileHeightPx = 16,
}) {
  final spawn = resolveInitialPlayerSpawn(
    startMap,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );

  return createNewGameState(
    startMapId: startMap.id,
    startPosition: spawn.pos,
    startFacing: spawn.facing.asFacing,
    saveId: saveId,
    playerName: playerName,
  );
}
