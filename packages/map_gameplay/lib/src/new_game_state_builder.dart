import 'package:map_core/map_core.dart';

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
