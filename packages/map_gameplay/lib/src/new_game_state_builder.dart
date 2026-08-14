import 'package:map_core/map_core.dart';

import 'direction.dart';
import 'player_spawn_resolver.dart';

const playerNameScriptVariable = 'player_name';
const playerAvatarScriptVariable = 'player_avatar';
const playerPronounSetScriptVariable = 'player_pronoun_set';
const playerSubjectPronounScriptVariable = 'player_pronoun_subject';
const playerObjectPronounScriptVariable = 'player_pronoun_object';
const playerPossessivePronounScriptVariable = 'player_pronoun_possessive';
const playerReflexivePronounScriptVariable = 'player_pronoun_reflexive';

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
  String? playerAvatarCharacterId,
  PlayerPronounSet playerPronounSet = PlayerPronounSet.neutral,
  String locale = 'en',
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
  final normalizedAvatarCharacterId = playerAvatarCharacterId?.trim();

  return GameState(
    saveId: normalizedSaveId,
    currentMapId: normalizedMapId,
    playerPosition: startPosition,
    playerFacing: startFacing,
    playerMovementMode: MovementMode.walk,
    party: const PlayerParty(),
    trainerProfile: TrainerProfile(
      name: normalizedPlayerName,
      avatarCharacterId: normalizedAvatarCharacterId == null ||
              normalizedAvatarCharacterId.isEmpty
          ? null
          : normalizedAvatarCharacterId,
      pronounSet: playerPronounSet,
    ),
    bag: const Bag(),
    progression: const PlayerProgression(),
    scriptVariables: _playerIdentityScriptVariables(
      name: normalizedPlayerName,
      avatarCharacterId: normalizedAvatarCharacterId,
      pronounSet: playerPronounSet,
      locale: locale,
    ),
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
  String? playerAvatarCharacterId,
  PlayerPronounSet playerPronounSet = PlayerPronounSet.neutral,
  String locale = 'en',
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
    playerAvatarCharacterId: playerAvatarCharacterId,
    playerPronounSet: playerPronounSet,
    locale: locale,
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
  String? playerName,
  String? playerAvatarCharacterId,
  PlayerPronounSet? playerPronounSet,
  String locale = 'en',
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
  final normalizedParty = PlayerParty(
    members: <PlayerPokemon>[
      for (final pokemon in config.initialParty)
        pokemon.copyWith(individualId: ''),
    ],
  ).normalized();
  final initialFacts = <String, NarrativeValue>{
    ...config.resolvedInitialFactValues,
  };
  final existingPartyFactId = config.existingPartyFactId?.trim();
  if (existingPartyFactId != null && existingPartyFactId.isNotEmpty) {
    initialFacts[existingPartyFactId] =
        NarrativeValue.boolean(normalizedParty.members.isNotEmpty);
  }
  final normalizedPlayerName = playerName?.trim();
  final resolvedPlayerName =
      normalizedPlayerName == null || normalizedPlayerName.isEmpty
          ? config.playerName
          : normalizedPlayerName;
  final authoredAvatarIds = config.playerAvatarCharacterIds.toSet();
  final requestedAvatarId = playerAvatarCharacterId?.trim();
  if (requestedAvatarId != null &&
      requestedAvatarId.isNotEmpty &&
      authoredAvatarIds.isNotEmpty &&
      !authoredAvatarIds.contains(requestedAvatarId)) {
    throw ArgumentError.value(
      playerAvatarCharacterId,
      'playerAvatarCharacterId',
      'must reference an authored player avatar choice',
    );
  }
  final defaultAvatarId = project.settings.defaultPlayerCharacterId?.trim();
  final resolvedAvatarId =
      requestedAvatarId != null && requestedAvatarId.isNotEmpty
          ? requestedAvatarId
          : defaultAvatarId != null &&
                  defaultAvatarId.isNotEmpty &&
                  (authoredAvatarIds.isEmpty ||
                      authoredAvatarIds.contains(defaultAvatarId))
              ? defaultAvatarId
              : config.playerAvatarCharacterIds.firstOrNull;
  final resolvedPronounSet = playerPronounSet ?? config.playerPronounSet;

  return normalizeLoadedGameState(
    GameState(
      saveId: saveId.trim().isEmpty ? 'new_game' : saveId.trim(),
      currentMapId: configuredMapId,
      playerPosition: spawn.pos,
      playerFacing: spawn.facing.asFacing,
      playerMovementMode: MovementMode.walk,
      party: normalizedParty,
      trainerProfile: TrainerProfile(
        name: resolvedPlayerName,
        avatarCharacterId: resolvedAvatarId,
        pronounSet: resolvedPronounSet,
        money: config.startingMoney,
      ).normalized(),
      bag: Bag(entries: config.initialBag).normalized(),
      progression: const PlayerProgression(),
      scriptVariables: _playerIdentityScriptVariables(
        name: resolvedPlayerName,
        avatarCharacterId: resolvedAvatarId,
        pronounSet: resolvedPronounSet,
        locale: locale,
      ),
      storyFlags: const StoryFlags(),
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: initialFacts,
      ),
      consumedEventIds: const <String>{},
      metadata: const <String, String>{},
    ),
  );
}

ScriptVariables _playerIdentityScriptVariables({
  required String name,
  required String? avatarCharacterId,
  required PlayerPronounSet pronounSet,
  required String locale,
}) {
  final pronouns = _localizedPronouns(pronounSet, locale);
  return ScriptVariables(
    values: <String, ScriptVariableValue>{
      playerNameScriptVariable: ScriptVariableValue.string(name),
      if (avatarCharacterId != null && avatarCharacterId.trim().isNotEmpty)
        playerAvatarScriptVariable:
            ScriptVariableValue.string(avatarCharacterId.trim()),
      playerPronounSetScriptVariable:
          ScriptVariableValue.string(pronounSet.name),
      playerSubjectPronounScriptVariable:
          ScriptVariableValue.string(pronouns.subject),
      playerObjectPronounScriptVariable:
          ScriptVariableValue.string(pronouns.object),
      playerPossessivePronounScriptVariable:
          ScriptVariableValue.string(pronouns.possessive),
      playerReflexivePronounScriptVariable:
          ScriptVariableValue.string(pronouns.reflexive),
    },
  );
}

/// Rebuilds locale-specific identity variables from the persisted profile.
///
/// Save data stores the semantic pronoun set, so changing locale between
/// sessions safely refreshes dialogue labels without mutating other variables.
GameState applyPlayerIdentityDialogueVariables(
  GameState state, {
  required String locale,
}) {
  final identityVariables = _playerIdentityScriptVariables(
    name: state.trainerProfile.name,
    avatarCharacterId: state.trainerProfile.avatarCharacterId,
    pronounSet: state.trainerProfile.pronounSet,
    locale: locale,
  );
  return state.copyWith(
    scriptVariables: ScriptVariables(
      values: <String, ScriptVariableValue>{
        ...state.scriptVariables.values,
        ...identityVariables.values,
      },
    ),
  );
}

({String subject, String object, String possessive, String reflexive})
    _localizedPronouns(
  PlayerPronounSet set,
  String locale,
) {
  final isFrench =
      locale.trim().toLowerCase().split(RegExp('[-_]')).first == 'fr';
  if (isFrench) {
    return switch (set) {
      PlayerPronounSet.neutral => (
          subject: 'iel',
          object: 'ellui',
          possessive: 'son',
          reflexive: 'ellui-même',
        ),
      PlayerPronounSet.feminine => (
          subject: 'elle',
          object: 'elle',
          possessive: 'sa',
          reflexive: 'elle-même',
        ),
      PlayerPronounSet.masculine => (
          subject: 'il',
          object: 'lui',
          possessive: 'son',
          reflexive: 'lui-même',
        ),
    };
  }
  return switch (set) {
    PlayerPronounSet.neutral => (
        subject: 'they',
        object: 'them',
        possessive: 'their',
        reflexive: 'themself',
      ),
    PlayerPronounSet.feminine => (
        subject: 'she',
        object: 'her',
        possessive: 'her',
        reflexive: 'herself',
      ),
    PlayerPronounSet.masculine => (
        subject: 'he',
        object: 'him',
        possessive: 'his',
        reflexive: 'himself',
      ),
  };
}
