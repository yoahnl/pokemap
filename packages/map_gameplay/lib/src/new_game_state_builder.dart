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

enum NewGameSeedProjectionIssueCode {
  staleProjectRevision,
  starterRequired,
  starterUnknown,
  starterPartyFull,
  variableReserved,
}

final class NewGameSeedProjectionException implements Exception {
  NewGameSeedProjectionException({
    required this.code,
    required this.field,
    Map<String, String> arguments = const <String, String>{},
  }) : arguments = Map<String, String>.unmodifiable(arguments);

  final NewGameSeedProjectionIssueCode code;
  final String field;
  final Map<String, String> arguments;

  String get diagnosticCode => switch (code) {
        NewGameSeedProjectionIssueCode.staleProjectRevision =>
          'new_game.seed_projection_stale_project',
        NewGameSeedProjectionIssueCode.starterRequired =>
          'new_game.seed_projection_starter_required',
        NewGameSeedProjectionIssueCode.starterUnknown =>
          'new_game.seed_projection_starter_unknown',
        NewGameSeedProjectionIssueCode.starterPartyFull =>
          'new_game.seed_projection_starter_party_full',
        NewGameSeedProjectionIssueCode.variableReserved =>
          'new_game.seed_projection_variable_reserved',
      };

  Map<String, dynamic> toJson() => <String, dynamic>{
        'code': code.name,
        'diagnosticCode': diagnosticCode,
        'field': field,
        if (arguments.isNotEmpty) 'arguments': arguments,
      };

  @override
  String toString() =>
      'NewGameSeedProjectionException(code: ${code.name}, field: $field)';
}

GameState createNewGameStateFromSeed({
  required ProjectManifest project,
  required MapData startMap,
  required NewGameSeed seed,
  required String currentProjectRevision,
  String locale = 'en',
  int tileWidthPx = 16,
  int tileHeightPx = 16,
}) {
  final normalizedProjectRevision = currentProjectRevision.trim();
  if (normalizedProjectRevision.isEmpty) {
    throw ArgumentError.value(
      currentProjectRevision,
      'currentProjectRevision',
      'must not be empty or blank',
    );
  }
  if (seed.projectRevision != normalizedProjectRevision) {
    throw NewGameSeedProjectionException(
      code: NewGameSeedProjectionIssueCode.staleProjectRevision,
      field: 'projectRevision',
      arguments: <String, String>{
        'expected': normalizedProjectRevision,
        'actual': seed.projectRevision,
      },
    );
  }

  final state = createNewGameStateFromProject(
    project: project,
    startMap: startMap,
    saveId: seed.slotId,
    playerName: seed.playerName,
    playerAvatarCharacterId: seed.avatarCharacterId,
    playerPronounSet: seed.pronounSet,
    locale: locale,
    tileWidthPx: tileWidthPx,
    tileHeightPx: tileHeightPx,
  );
  final starter = _resolveStarter(project.newGame, seed.starterOptionId);
  if (starter != null && state.party.members.length >= maxPlayerPartySize) {
    throw NewGameSeedProjectionException(
      code: NewGameSeedProjectionIssueCode.starterPartyFull,
      field: 'starterOptionId',
      arguments: <String, String>{
        'capacity': maxPlayerPartySize.toString(),
      },
    );
  }

  final party = starter == null
      ? state.party
      : PlayerParty(
          members: <PlayerPokemon>[...state.party.members, starter],
        ).normalized();
  final scriptVariables = <String, ScriptVariableValue>{
    ...state.scriptVariables.values,
  };
  for (final entry in seed.variables.entries) {
    if (_playerIdentityVariableIds.contains(entry.key)) {
      throw NewGameSeedProjectionException(
        code: NewGameSeedProjectionIssueCode.variableReserved,
        field: 'variables',
        arguments: <String, String>{'variableId': entry.key},
      );
    }
    scriptVariables[entry.key] = _scriptVariableValue(entry.value);
  }
  final facts = <String, NarrativeValue>{
    ...state.narrativeFactRuntimeState.valuesByFactId,
  };
  final existingPartyFactId = project.newGame.existingPartyFactId?.trim();
  if (existingPartyFactId != null && existingPartyFactId.isNotEmpty) {
    facts[existingPartyFactId] =
        NarrativeValue.boolean(party.members.isNotEmpty);
  }

  return normalizeLoadedGameState(
    state.copyWith(
      party: party,
      scriptVariables: ScriptVariables(values: scriptVariables),
      narrativeFactRuntimeState: NarrativeFactRuntimeState.typed(
        valuesByFactId: facts,
      ),
    ),
  );
}

const _playerIdentityVariableIds = <String>{
  playerNameScriptVariable,
  playerAvatarScriptVariable,
  playerPronounSetScriptVariable,
  playerSubjectPronounScriptVariable,
  playerObjectPronounScriptVariable,
  playerPossessivePronounScriptVariable,
  playerReflexivePronounScriptVariable,
};

PlayerPokemon? _resolveStarter(
  ProjectNewGameConfig config,
  String? starterOptionId,
) {
  final normalizedStarterOptionId = starterOptionId?.trim();
  if (normalizedStarterOptionId == null || normalizedStarterOptionId.isEmpty) {
    if (config.starterOptions.isNotEmpty) {
      throw NewGameSeedProjectionException(
        code: NewGameSeedProjectionIssueCode.starterRequired,
        field: 'starterOptionId',
      );
    }
    return null;
  }
  for (final option in config.starterOptions) {
    if (option.id == normalizedStarterOptionId) {
      return option.pokemon;
    }
  }
  throw NewGameSeedProjectionException(
    code: NewGameSeedProjectionIssueCode.starterUnknown,
    field: 'starterOptionId',
    arguments: <String, String>{'starterOptionId': normalizedStarterOptionId},
  );
}

ScriptVariableValue _scriptVariableValue(NarrativeValue value) =>
    switch (value.kind) {
      NarrativeValueKind.boolean => ScriptVariableValue.bool(value.boolValue),
      NarrativeValueKind.integer => ScriptVariableValue.int(value.intValue),
      NarrativeValueKind.string =>
        ScriptVariableValue.string(value.stringValue),
    };

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
  final normalizedParty =
      PlayerParty(members: config.initialParty).normalized();
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
