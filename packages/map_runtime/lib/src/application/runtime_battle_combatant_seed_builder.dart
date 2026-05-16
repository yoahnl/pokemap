import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_move_bridge_diagnostics.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

/// Politique partagée de sélection des moves dérivés d'un learnset.
///
/// Cette extraction reste volontairement petite :
/// - elle ne crée pas un nouveau service ;
/// - elle ne change aucune règle métier ;
/// - elle évite simplement qu'un outil d'audit recopie silencieusement la
///   même logique et dérive ensuite du vrai runtime.
///
/// Règle conservée telle quelle :
/// - startingMoves
/// - relearnMoves
/// - levelUp <= niveau courant
/// - unicité préservant l'ordre
/// - 4 derniers moves maximum
List<String> deriveBattleCandidateMoveIdsFromLearnset({
  required RuntimePokemonLearnset learnset,
  required int level,
}) {
  final ordered = <String>[
    ...learnset.startingMoves,
    ...learnset.relearnMoves,
    ...learnset.levelUp
        .where((entry) => entry.level <= level)
        .map((entry) => entry.moveId),
  ];

  final unique = <String>[];
  final seen = <String>{};
  for (final rawId in ordered) {
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty || !seen.add(normalizedId)) {
      continue;
    }
    unique.add(normalizedId);
  }

  if (unique.length <= 4) {
    return List<String>.unmodifiable(unique);
  }
  return List<String>.unmodifiable(unique.sublist(unique.length - 4));
}

/// Politique partagée de résolution runtime des moves candidats vers battle.
///
/// Cette helper donne à la fois :
/// - le comportement réel de filtrage des moves non bridgeables ;
/// - les hard failures sur moves absents du catalogue ;
/// - les hard failures sur refus bridge non filtrables.
///
/// Elle permet donc à un outil d'audit de mesurer le seam runtime avec la
/// même sévérité que la production, au lieu d'inventer une lecture plus
/// permissive.
List<BattleMoveData> resolveBattleMovesForSeed({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
}) {
  return resolveBattleMovesForSeedWithDiagnostics(
    moveIds: moveIds,
    combatantLabel: combatantLabel,
    lookupMove: lookupMove,
    battleMoveBridge: battleMoveBridge,
  ).moves;
}

RuntimeBattleMoveProjection resolveBattleMovesForSeedWithDiagnostics({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
}) {
  final candidateMoveIds = List<String>.unmodifiable(
    _normalizeUniqueMoveIdsPreserveOrder(moveIds)
        .take(4)
        .toList(growable: false),
  );

  if (candidateMoveIds.isEmpty) {
    throw RuntimeBattleSetupException(
      '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
    );
  }

  final moves = <BattleMoveData>[];
  final diagnostics = <RuntimeBattleMoveBridgeDiagnostics>[];
  final rejectedMoves = <_RejectedBridgeMove>[];

  for (final moveId in candidateMoveIds) {
    final move = lookupMove(moveId);
    if (move == null) {
      throw RuntimeBattleSetupException(
        'Le catalogue local des attaques ne contient pas "$moveId".',
        debugDetails: 'combatant=$combatantLabel',
      );
    }

    final diagnostic = battleMoveBridge.inspectMove(
      move: move,
      combatantLabel: combatantLabel,
    );
    diagnostics.add(diagnostic);

    if (!diagnostic.runtimeBridgeable) {
      final rejectedMove = _RejectedBridgeMove.fromDiagnostic(
        move: move,
        diagnostic: diagnostic,
      );

      if (!rejectedMove.isFilterableDuringSeedAssembly) {
        battleMoveBridge.toBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
        );
      }

      rejectedMoves.add(rejectedMove);
      continue;
    }

    try {
      moves.add(
        battleMoveBridge.toBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
        ),
      );
    } on RuntimeBattleSetupException catch (error) {
      final rejectedMove = _RejectedBridgeMove.fromBridgeRejection(
        move: move,
        debugDetails: error.debugDetails,
      );

      if (!rejectedMove.isFilterableDuringSeedAssembly) {
        rethrow;
      }

      rejectedMoves.add(rejectedMove);
    }
  }

  if (moves.isNotEmpty) {
    return RuntimeBattleMoveProjection(
      moves: moves,
      diagnostics: diagnostics,
    );
  }

  // R1 garde ici un hard-fail volontaire :
  // - on ne réinjecte pas de move "par défaut" qui n'appartient pas au Pokémon ;
  // - on ne maquille pas non plus le trou avec un faux support Struggle runtime ;
  // - on préfère échouer tôt, avec un diagnostic produit/actionnable, tant que
  //   le bridge battle actuel ne sait pas projeter honnêtement aucune attaque
  //   du set candidat.
  throw RuntimeBattleSetupException(
    'Le combat ne peut pas démarrer car "$combatantLabel" n’a aucun move bridgeable restant après filtrage. '
    'Attribuez-lui au moins une attaque réellement supportée par le bridge battle actuel.',
    debugDetails: 'combatant=$combatantLabel, '
        'candidateMoveIds=${_formatDebugStringList(candidateMoveIds)}, '
        'rejectedMoveIds=${_formatDebugStringList(rejectedMoves.map((move) => move.moveId).toList(growable: false))}, '
        'rejectedMoves=[${rejectedMoves.map((move) => move.toDebugDetails()).join('; ')}], '
        'filterResult=no_bridgeable_moves_remaining_after_filtering, '
        'resolutionHint=assign_at_least_one_bridgeable_move',
  );
}

class RuntimeBattleMoveProjection {
  RuntimeBattleMoveProjection({
    required List<BattleMoveData> moves,
    required List<RuntimeBattleMoveBridgeDiagnostics> diagnostics,
  })  : moves = List<BattleMoveData>.unmodifiable(moves),
        diagnostics =
            List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(diagnostics);

  final List<BattleMoveData> moves;
  final List<RuntimeBattleMoveBridgeDiagnostics> diagnostics;

  List<RuntimeBattleMoveBridgeDiagnostics> get filteredDiagnostics {
    return List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(
      diagnostics.where((diagnostic) => !diagnostic.runtimeBridgeable),
    );
  }
}

List<String> _normalizeUniqueMoveIdsPreserveOrder(List<String> rawIds) {
  final out = <String>[];
  final seen = <String>{};
  for (final rawId in rawIds) {
    final normalizedId = rawId.trim();
    if (normalizedId.isEmpty || !seen.add(normalizedId)) {
      continue;
    }
    out.add(normalizedId);
  }
  return List<String>.unmodifiable(out);
}

String _formatDebugStringList(List<String> values) {
  if (values.isEmpty) {
    return '[]';
  }
  return '[${values.join(', ')}]';
}

/// Builder runtime spécialisé des seeds de combattants injectés dans
/// `BattleSetup`.
///
/// M7 extrait ce seam pour éviter que `RuntimeBattleSetupMapper` concentre
/// encore :
/// - la sélection du membre joueur ;
/// - la lecture species/learnsets déjà extraite en M6 ;
/// - la dérivation du move set ;
/// - le gate M5-bis vers `BattleMoveData` ;
/// - le calcul de HP max ;
/// - et la construction finale des seeds de combattants.
///
/// Frontière intentionnelle :
/// - ce builder assemble des données runtime locales vers un seed battle ;
/// - il ne crée pas un framework générique de combat ;
/// - il ne modifie pas le contrat `BattleSetup` ;
/// - il ne rouvre pas M8 et n’essaie pas d’exécuter les `effects`.
class RuntimeBattleCombatantSeedBuilder {
  RuntimeBattleCombatantSeedBuilder({
    RuntimePokemonSpeciesLoader? speciesLoader,
    RuntimePokemonLearnsetLoader? learnsetLoader,
    this.battleMoveBridge = const RuntimeBattleMoveBridge(),
  })  : speciesLoader = speciesLoader ?? RuntimePokemonSpeciesLoader(),
        learnsetLoader = learnsetLoader ?? RuntimePokemonLearnsetLoader();

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
    String combatantLabel = 'Le Pokémon actif du joueur',
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: playerPokemon.speciesId,
    );
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: playerPokemon.level,
          );

    final moveProjection = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: combatantLabel,
    );

    final maxHp = _calculateMaxHp(
      baseHp: species.baseHp,
      level: playerPokemon.level,
      ivHp: playerPokemon.ivs.hp,
      evHp: playerPokemon.evs.hp,
    );
    final stats = _calculateStatsSnapshot(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      stats: stats,
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildWildCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: request.speciesId,
    );
    final moveIds = await _deriveLearnsetMoveIds(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      species: species,
      level: request.level,
    );
    final moveProjection = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: request.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  Future<RuntimeBattleCombatantSeed> buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectTrainerPokemonEntry teamMember,
    required String trainerName,
  }) async {
    final species = await speciesLoader.loadById(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesId: teamMember.speciesId,
    );
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            projectRootDirectory: projectRootDirectory,
            pokemonConfig: pokemonConfig,
            species: species,
            level: teamMember.level,
          );

    final moveProjection = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      stats: _calculateStatsSnapshot(
        species: species,
        level: teamMember.level,
      ),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  Future<List<String>> _deriveLearnsetMoveIds({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );

    return deriveBattleCandidateMoveIdsFromLearnset(
      learnset: learnset,
      level: level,
    );
  }

  RuntimeBattleMoveProjection _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    // Le builder garde désormais sa vraie policy de résolution dans une helper
    // partagée, afin que l'outillage Phase B puisse mesurer le même seam sans
    // reconstruire une variante plus permissive.
    return resolveBattleMovesForSeedWithDiagnostics(
      moveIds: moveIds,
      combatantLabel: combatantLabel,
      lookupMove: movesCatalog.lookup,
      battleMoveBridge: battleMoveBridge,
    );
  }

  int _calculateMaxHp({
    required int baseHp,
    required int level,
    int ivHp = 0,
    int evHp = 0,
  }) {
    final safeBaseHp = _clampInt(baseHp, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(ivHp, min: 0, max: 31);
    final safeEv = _clampInt(evHp, min: 0, max: 252);

    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
  }

  BattleStatsSnapshot _calculateStatsSnapshot({
    required RuntimePokemonSpecies species,
    required int level,
    PokemonStatSpread ivs = const PokemonStatSpread(),
    PokemonStatSpread evs = const PokemonStatSpread(),
  }) {
    // BE2 résout ici les stats battle non-HP pour une raison simple :
    // - `map_runtime` possède encore la donnée projet (species, niveau, IV/EV) ;
    // - `map_battle` ne doit jamais relire le JSON projet brut ;
    // - le handoff battle doit donc déjà recevoir un snapshot typé, prêt à
    //   l'emploi, au lieu d'un bricolage `power + stages`.
    //
    // Politique volontairement bornée :
    // - joueur : on utilise les IV/EV réellement présents dans la sauvegarde ;
    // - sauvage / trainer : IV/EV par défaut à 0, déterministes, documentés ;
    // - nature neutre pour tout le monde dans BE2 ;
    // - `speed` est déjà transportée pour préparer la suite, sans être
    //   consommée pour l'ordre d'action dans ce lot.
    return BattleStatsSnapshot(
      attack: _calculateResolvedNonHpStat(
        baseStat: species.baseAttack,
        level: level,
        iv: ivs.attack,
        ev: evs.attack,
      ),
      defense: _calculateResolvedNonHpStat(
        baseStat: species.baseDefense,
        level: level,
        iv: ivs.defense,
        ev: evs.defense,
      ),
      specialAttack: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialAttack,
        level: level,
        iv: ivs.specialAttack,
        ev: evs.specialAttack,
      ),
      specialDefense: _calculateResolvedNonHpStat(
        baseStat: species.baseSpecialDefense,
        level: level,
        iv: ivs.specialDefense,
        ev: evs.specialDefense,
      ),
      speed: _calculateResolvedNonHpStat(
        baseStat: species.baseSpeed,
        level: level,
        iv: ivs.speed,
        ev: evs.speed,
      ),
    );
  }

  BattleTypingSnapshot _buildBattleTypingSnapshot(
    RuntimePokemonSpecies species,
  ) {
    // BE5 garde la frontière propre :
    // - le loader species lit et valide le typing projet ;
    // - le builder l'adapte vers le petit contrat battle ;
    // - `map_battle` reçoit ensuite une donnée déjà prête à consommer sans
    //   jamais relire le JSON projet brut.
    return BattleTypingSnapshot(
      primaryType: species.typing.first,
      secondaryType: species.typing.length > 1 ? species.typing[1] : null,
    );
  }

  int _calculateResolvedNonHpStat({
    required int baseStat,
    required int level,
    int iv = 0,
    int ev = 0,
  }) {
    final safeBaseStat = _clampInt(baseStat, min: 1, max: 255);
    final safeLevel = _clampInt(level, min: 1, max: 100);
    final safeIv = _clampInt(iv, min: 0, max: 31);
    final safeEv = _clampInt(ev, min: 0, max: 252);

    // Formule volontairement Pokémon-like, mais limitée et déterministe :
    // floor(((2 * base + iv + floor(ev / 4)) * level) / 100) + 5
    //
    // BE2 ne gère pas encore les natures. On garde donc ici un multiplicateur
    // neutre implicite de 1.0 au lieu d'introduire une mécanique partielle.
    final resolved =
        (((2 * safeBaseStat + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) + 5;
    return _clampInt(resolved, min: 1, max: 999);
  }

  int _clampInt(
    int value, {
    required int min,
    required int max,
  }) {
    if (value < min) {
      return min;
    }
    if (value > max) {
      return max;
    }
    return value;
  }
}

/// Snapshot local d'un move candidat rejeté par le bridge runtime -> battle.
///
/// Ce type reste volontairement petit et local au builder :
/// - il évite d'ouvrir un nouveau contrat public juste pour un message
///   d'erreur de handoff ;
/// - il garde tout le contexte nécessaire pour expliquer pourquoi aucun move
///   bridgeable n'est finalement resté après filtrage ;
/// - il permet d'améliorer le message final sans élargir le bridge lui-même.
final class _RejectedBridgeMove {
  const _RejectedBridgeMove({
    required this.moveId,
    required this.moveName,
    required this.engineSupportLevel,
    required this.unsupportedReasons,
    this.battleEngineMethod,
    this.psdkRegistryStatus,
    this.bridgeLimit,
  });

  factory _RejectedBridgeMove.fromDiagnostic({
    required PokemonMove move,
    required RuntimeBattleMoveBridgeDiagnostics diagnostic,
  }) {
    return _RejectedBridgeMove(
      moveId: move.id,
      moveName: move.name,
      engineSupportLevel: move.engineSupportLevel.name,
      unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
      battleEngineMethod: diagnostic.battleEngineMethod,
      psdkRegistryStatus: diagnostic.psdkRegistryStatus,
      bridgeLimit: diagnostic.reason == 'runtime_bridge_rejected'
          ? null
          : diagnostic.reason,
    );
  }

  factory _RejectedBridgeMove.fromBridgeRejection({
    required PokemonMove move,
    required String? debugDetails,
  }) {
    return _RejectedBridgeMove(
      moveId: move.id,
      moveName: move.name,
      engineSupportLevel: move.engineSupportLevel.name,
      unsupportedReasons: List<String>.unmodifiable(move.unsupportedReasons),
      bridgeLimit: _extractBridgeLimit(debugDetails),
    );
  }

  final String moveId;
  final String moveName;
  final String engineSupportLevel;
  final List<String> unsupportedReasons;
  final String? battleEngineMethod;
  final String? psdkRegistryStatus;
  final String? bridgeLimit;

  bool get isFilterableDuringSeedAssembly {
    final limit = bridgeLimit;
    if (limit == null) {
      return false;
    }
    if (limit.startsWith('invalid_')) {
      return false;
    }
    if (limit == 'empty_modify_stats_not_supported') {
      return false;
    }
    return true;
  }

  String toDebugDetails() {
    final reasons = unsupportedReasons.isEmpty
        ? '[]'
        : '[${unsupportedReasons.join(', ')}]';
    final method = battleEngineMethod == null
        ? ''
        : ', battleEngineMethod=$battleEngineMethod';
    final registry = psdkRegistryStatus == null
        ? ''
        : ', psdkRegistryStatus=$psdkRegistryStatus';
    final limit = bridgeLimit == null ? '' : ', bridgeLimit=$bridgeLimit';
    return 'moveId=$moveId, '
        'moveName=$moveName, '
        'engineSupportLevel=$engineSupportLevel, '
        'unsupportedReasons=$reasons$method$registry$limit';
  }

  static String? _extractBridgeLimit(String? debugDetails) {
    if (debugDetails == null || debugDetails.trim().isEmpty) {
      return null;
    }
    final match =
        RegExp(r'bridgeLimit=([^,]+)$').firstMatch(debugDetails.trim());
    return match?.group(1);
  }
}

/// Seed runtime intermédiaire d'un combattant avant projection finale vers
/// `BattleCombatantData`.
///
/// On garde ce type séparé du mapper pour documenter explicitement la frontière
/// M7 :
/// - le builder assemble un seed runtime battle-ready ;
/// - le mapper assemble ensuite le `BattleSetup` global.
class RuntimeBattleCombatantSeed {
  const RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.stats,
    required this.typing,
    required this.abilityId,
    required this.moves,
    this.moveDiagnostics = const <RuntimeBattleMoveBridgeDiagnostics>[],
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;
  final List<RuntimeBattleMoveBridgeDiagnostics> moveDiagnostics;

  List<RuntimeBattleMoveBridgeDiagnostics> get filteredMoveDiagnostics {
    return List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(
      moveDiagnostics.where((diagnostic) => !diagnostic.runtimeBridgeable),
    );
  }

  BattleCombatantData toBattleCombatantData({
    int lineupIndex = 0,
  }) {
    // BE10 garde la frontière propre :
    // - le seed builder ne connaît toujours pas la vraie party runtime ;
    // - mais le mapper peut maintenant lui demander de projeter ce seed vers
    //   un `BattleCombatantData` portant une identité de lineup stable ;
    // - cela évite de dupliquer à la main tout le DTO battle dans le mapper.
    return BattleCombatantData(
      speciesId: speciesId,
      lineupIndex: lineupIndex,
      level: level,
      maxHp: maxHp,
      stats: stats,
      typing: typing,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}
