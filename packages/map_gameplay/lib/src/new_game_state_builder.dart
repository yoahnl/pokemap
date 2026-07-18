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
    narrativeFactRuntimeState: const NarrativeFactRuntimeState.empty(),
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

/// Crée l'état initial depuis le contrat de nouvelle partie du projet.
///
/// Contrairement à [createNewGameStateFromMap], cette variante applique le
/// contenu authoré : spawn explicite, équipe, sac, argent et Facts initiaux.
/// Le runtime peut ainsi démarrer un projet réel sans fixture côté hôte.
GameState createNewGameStateFromProject({
  required ProjectManifest project,
  required MapData startMap,
  String saveId = 'new_game',
  int tileWidthPx = 16,
  int tileHeightPx = 16,
}) {
  final config = project.newGame;
  if (!config.enabled) {
    throw StateError('Project newGame config must be enabled.');
  }

  ProjectValidator.validate(project);

  final configuredMapId = config.startMapId.trim();
  final actualMapId = startMap.id.trim();
  if (actualMapId != configuredMapId) {
    throw ArgumentError.value(
      startMap.id,
      'startMap',
      'Expected authored start map "$configuredMapId".',
    );
  }

  final spawn = resolveInitialPlayerSpawn(
    startMap,
    preferredSpawnId: config.startSpawnId,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );
  final normalizedParty =
      PlayerParty(members: config.initialParty).normalized();
  final initialFacts = <String, bool>{...config.initialFacts};
  final existingPartyFactId = config.existingPartyFactId?.trim();
  if (existingPartyFactId != null && existingPartyFactId.isNotEmpty) {
    initialFacts[existingPartyFactId] = normalizedParty.members.isNotEmpty;
  }

  return normalizeLoadedGameState(
    GameState(
      saveId: saveId.trim().isEmpty ? 'new_game' : saveId.trim(),
      currentMapId: configuredMapId,
      playerPosition: spawn.pos,
      playerFacing: spawn.facing.asFacing,
      playerMovementMode: MovementMode.walk,
      party: normalizedParty,
      trainerProfile: TrainerProfile(
        name: config.playerName,
        money: config.startingMoney,
      ).normalized(),
      bag: Bag(entries: config.initialBag).normalized(),
      progression: const PlayerProgression(),
      scriptVariables: const ScriptVariables(),
      storyFlags: const StoryFlags(),
      narrativeFactRuntimeState: NarrativeFactRuntimeState(
        overridesByFactId: initialFacts,
      ),
      consumedEventIds: const <String>{},
      metadata: const <String, String>{},
    ),
  );
}
