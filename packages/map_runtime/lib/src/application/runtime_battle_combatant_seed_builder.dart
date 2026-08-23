import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_move_bridge_diagnostics.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_battle_status_bridge.dart';
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

int _fallbackWildGenerationSeed(WildBattleStartRequest request) {
  final value = <Object>[
    request.requestId,
    request.mapId,
    request.encounterSourceId,
    request.tableId,
    request.speciesId,
    request.level,
  ].join('|');
  var hash = 0x811c9dc5;
  for (final codeUnit in value.codeUnits) {
    hash ^= codeUnit;
    hash = (hash * 0x01000193) & 0xffffffff;
  }
  return hash;
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
  Map<String, int>? currentPpByMoveId,
}) {
  return resolveBattleMovesForSeedWithDiagnostics(
    moveIds: moveIds,
    combatantLabel: combatantLabel,
    lookupMove: lookupMove,
    battleMoveBridge: battleMoveBridge,
    currentPpByMoveId: currentPpByMoveId,
  ).moves;
}

RuntimeBattleMoveProjection resolveBattleMovesForSeedWithDiagnostics({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
  Map<String, int>? currentPpByMoveId,
}) {
  final candidateMoveIds = List<String>.unmodifiable(
    _normalizeUniqueMoveIdsPreserveOrder(moveIds)
        .take(4)
        .toList(growable: false),
  );

  if (candidateMoveIds.isEmpty) {
    return RuntimeBattleMoveProjection(
      moves: const <BattleMoveData>[canonicalLegacyStruggleMoveData],
      diagnostics: const <RuntimeBattleMoveBridgeDiagnostics>[],
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
    final currentPp = _resolveCurrentPpForMove(
      move: move,
      currentPpByMoveId: currentPpByMoveId,
      combatantLabel: combatantLabel,
    );

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
          currentPp: currentPp,
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
          currentPp: currentPp,
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

List<PsdkBattleMoveData> resolvePsdkBattleMovesForSeed({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
  Map<String, int>? currentPpByMoveId,
}) {
  return resolvePsdkBattleMovesForSeedWithDiagnostics(
    moveIds: moveIds,
    combatantLabel: combatantLabel,
    lookupMove: lookupMove,
    battleMoveBridge: battleMoveBridge,
    currentPpByMoveId: currentPpByMoveId,
  ).moves;
}

RuntimePsdkBattleMoveProjection resolvePsdkBattleMovesForSeedWithDiagnostics({
  required List<String> moveIds,
  required String combatantLabel,
  required PokemonMove? Function(String moveId) lookupMove,
  RuntimeBattleMoveBridge battleMoveBridge = const RuntimeBattleMoveBridge(),
  Map<String, int>? currentPpByMoveId,
}) {
  final candidateMoveIds = List<String>.unmodifiable(
    _normalizeUniqueMoveIdsPreserveOrder(moveIds)
        .take(4)
        .toList(growable: false),
  );

  if (candidateMoveIds.isEmpty) {
    return RuntimePsdkBattleMoveProjection(
      moves: <PsdkBattleMoveData>[createCanonicalPsdkStruggleMove()],
      diagnostics: const <RuntimeBattleMoveBridgeDiagnostics>[],
    );
  }

  final moves = <PsdkBattleMoveData>[];
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
    final currentPp = _resolveCurrentPpForMove(
      move: move,
      currentPpByMoveId: currentPpByMoveId,
      combatantLabel: combatantLabel,
    );

    final diagnostic = battleMoveBridge.inspectMove(
      move: move,
      combatantLabel: combatantLabel,
    );
    diagnostics.add(diagnostic);

    if (!diagnostic.psdkBridgeable) {
      rejectedMoves.add(
        _RejectedBridgeMove.fromDiagnostic(
          move: move,
          diagnostic: diagnostic,
        ),
      );
      continue;
    }

    try {
      moves.add(
        battleMoveBridge.toPsdkBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
          currentPp: currentPp,
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
    return RuntimePsdkBattleMoveProjection(
      moves: moves,
      diagnostics: diagnostics,
    );
  }

  throw RuntimeBattleSetupException(
    'Le combat ne peut pas démarrer car "$combatantLabel" n’a aucun move PSDK bridgeable restant après filtrage. '
    'Attribuez-lui au moins une attaque portée par le moteur battle PSDK.',
    debugDetails: 'combatant=$combatantLabel, '
        'candidateMoveIds=${_formatDebugStringList(candidateMoveIds)}, '
        'rejectedMoveIds=${_formatDebugStringList(rejectedMoves.map((move) => move.moveId).toList(growable: false))}, '
        'rejectedMoves=[${rejectedMoves.map((move) => move.toDebugDetails()).join('; ')}], '
        'filterResult=no_psdk_bridgeable_moves_remaining_after_filtering, '
        'resolutionHint=assign_at_least_one_psdk_bridgeable_move',
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

class RuntimePsdkBattleMoveProjection {
  RuntimePsdkBattleMoveProjection({
    required List<PsdkBattleMoveData> moves,
    required List<RuntimeBattleMoveBridgeDiagnostics> diagnostics,
  })  : moves = List<PsdkBattleMoveData>.unmodifiable(moves),
        diagnostics =
            List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(diagnostics);

  final List<PsdkBattleMoveData> moves;
  final List<RuntimeBattleMoveBridgeDiagnostics> diagnostics;

  List<RuntimeBattleMoveBridgeDiagnostics> get filteredDiagnostics {
    return List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(
      diagnostics.where((diagnostic) => !diagnostic.psdkBridgeable),
    );
  }
}

int? _resolveCurrentPpForMove({
  required PokemonMove move,
  required Map<String, int>? currentPpByMoveId,
  required String combatantLabel,
}) {
  if (currentPpByMoveId == null) {
    return null;
  }
  final currentPp = currentPpByMoveId[move.id];
  if (currentPp == null) {
    throw RuntimeBattleSetupException(
      '$combatantLabel n’a aucun PP courant sauvegardé pour "${move.id}".',
      debugDetails: 'combatant=$combatantLabel, moveId=${move.id}',
    );
  }
  if (currentPp < 0 || currentPp > move.pp) {
    throw RuntimeBattleSetupException(
      'Les PP courants sauvegardés de "${move.id}" sont hors limites.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, currentPp=$currentPp, maxPp=${move.pp}',
    );
  }
  return currentPp;
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

enum RuntimeHeldItemSupportStatus {
  invalidDefinition,
  passive,
  supported,
  unsupported,
}

final class RuntimeHeldItemEffectResolution {
  const RuntimeHeldItemEffectResolution({
    required this.itemId,
    required this.heldEffectId,
    required this.status,
  });

  final String itemId;
  final String? heldEffectId;
  final RuntimeHeldItemSupportStatus status;
}

RuntimeHeldItemEffectResolution resolveRuntimeHeldItemEffect({
  required ItemCatalogSnapshot itemCatalog,
  required String itemId,
  ItemEffectRegistry? registry,
}) {
  final normalizedItemId = itemId.trim();
  final definition = itemCatalog.definitionFor(normalizedItemId);
  if (definition == null) {
    return RuntimeHeldItemEffectResolution(
      itemId: normalizedItemId,
      heldEffectId: null,
      status: RuntimeHeldItemSupportStatus.invalidDefinition,
    );
  }
  final heldEffectId =
      definition.heldEffectId?.trim().toLowerCase().replaceAll('-', '_');
  if (heldEffectId == null || heldEffectId.isEmpty) {
    return RuntimeHeldItemEffectResolution(
      itemId: definition.id,
      heldEffectId: null,
      status: RuntimeHeldItemSupportStatus.passive,
    );
  }
  return RuntimeHeldItemEffectResolution(
    itemId: definition.id,
    heldEffectId: heldEffectId,
    status: (registry ?? ItemEffectRegistry()).supportsHeldEffect(heldEffectId)
        ? RuntimeHeldItemSupportStatus.supported
        : RuntimeHeldItemSupportStatus.unsupported,
  );
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
    this.statusBridge = const RuntimeBattleStatusBridge(),
  })  : speciesLoader = speciesLoader ?? RuntimePokemonSpeciesLoader(),
        learnsetLoader = learnsetLoader ?? RuntimePokemonLearnsetLoader();

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;
  final RuntimeBattleStatusBridge statusBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
    String combatantLabel = 'Le Pokémon actif du joueur',
  }) async {
    final currentPpByMoveId = _requireHydratedCurrentPp(playerPokemon);
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
      currentPpByMoveId:
          playerPokemon.knownMoveIds.isEmpty ? null : currentPpByMoveId,
    );

    final calculatedStats = _calculateResolvedStats(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
      natureId: playerPokemon.natureId,
      profileLabel: 'player',
    );

    return RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: calculatedStats.maxHp,
      catchRate: species.catchRate,
      stats: _toBattleStatsSnapshot(calculatedStats),
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(
        playerPokemon.currentHp,
        min: 0,
        max: calculatedStats.maxHp,
      ),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      majorStatus: statusBridge.toLegacyBattleStatus(playerPokemon.statusId),
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  Future<RuntimePsdkBattleCombatantSeed> buildPlayerPsdkCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ItemCatalogSnapshot itemCatalog,
    required PlayerPokemon playerPokemon,
    String combatantLabel = 'Le Pokémon actif du joueur',
  }) async {
    final currentPpByMoveId = _requireHydratedCurrentPp(playerPokemon);
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

    final moveProjection = _resolvePsdkBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: combatantLabel,
      currentPpByMoveId:
          playerPokemon.knownMoveIds.isEmpty ? null : currentPpByMoveId,
    );

    final calculatedStats = _calculateResolvedStats(
      species: species,
      level: playerPokemon.level,
      ivs: playerPokemon.ivs,
      evs: playerPokemon.evs,
      natureId: playerPokemon.natureId,
      profileLabel: 'player',
    );

    return RuntimePsdkBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: calculatedStats.maxHp,
      catchRate: species.catchRate,
      stats: _toBattleStatsSnapshot(calculatedStats),
      typing: _buildBattleTypingSnapshot(species),
      currentHp: _clampInt(
        playerPokemon.currentHp,
        min: 0,
        max: calculatedStats.maxHp,
      ),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      majorStatus: statusBridge.toPsdkBattleStatus(playerPokemon.statusId),
      heldItemId: _resolvePsdkHeldItemId(
        playerPokemon.heldItemId,
        itemCatalog: itemCatalog,
        combatantLabel: combatantLabel,
      ),
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
    final generatedPokemon = request.generatedPokemon ??
        (await generateWildPlayerPokemon(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          movesCatalog: movesCatalog,
          request: request,
        ))
            .pokemon;
    final moveProjection = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: generatedPokemon.knownMoveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
      currentPpByMoveId: generatedPokemon.currentPpByMoveId,
    );
    final calculatedStats = _calculateResolvedStats(
      species: species,
      level: generatedPokemon.level,
      ivs: generatedPokemon.ivs,
      evs: generatedPokemon.evs,
      natureId: generatedPokemon.natureId,
      profileLabel: request.generationProfileId.isEmpty
          ? WildPokemonGenerationProfile.pokeMapBetaV1.profileId
          : request.generationProfileId,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: generatedPokemon.speciesId.trim(),
      level: generatedPokemon.level,
      maxHp: calculatedStats.maxHp,
      catchRate: species.catchRate,
      stats: _toBattleStatsSnapshot(calculatedStats),
      typing: _buildBattleTypingSnapshot(species),
      currentHp: generatedPokemon.currentHp,
      abilityId: generatedPokemon.abilityId,
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  Future<WildPlayerPokemonGenerationResult> generateWildPlayerPokemon({
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
    final learnset = await learnsetLoader.loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: species.learnsetRef,
      fallbackSpeciesId: species.id,
    );
    try {
      return const WildPlayerPokemonGenerator().generate(
        seed: request.generationSeed == 0
            ? _fallbackWildGenerationSeed(request)
            : request.generationSeed,
        species: WildPokemonGenerationSpecies(
          id: species.id,
          formId: species.formId,
          baseStats: PokemonBaseStats(
            hp: species.baseHp,
            attack: species.baseAttack,
            defense: species.baseDefense,
            specialAttack: species.baseSpecialAttack,
            specialDefense: species.baseSpecialDefense,
            speed: species.baseSpeed,
          ),
          primaryAbilityId: species.primaryAbilityId,
          standardAbilityIds: species.standardAbilityIds,
          allowedAbilityIds: species.abilityIds,
          genderRatio: species.genderRatio,
          growthRateId: species.growthRateId,
          baseFriendship: species.baseFriendship,
        ),
        learnset: WildPokemonGenerationLearnset(
          startingMoves: learnset.startingMoves,
          relearnMoves: learnset.relearnMoves,
          levelUp: <WildPokemonLevelUpMove>[
            for (final entry in learnset.levelUp)
              WildPokemonLevelUpMove(
                moveId: entry.moveId,
                level: entry.level,
              ),
          ],
        ),
        maxPpByMoveId: <String, int>{
          for (final entry in movesCatalog.entriesById.entries)
            entry.key: entry.value.pp,
        },
        level: request.level,
        ruleset: pokemonConfig.ruleset,
        context: WildPokemonGenerationContext(
          mapId: request.mapId,
          sourceId: request.tableId,
          individualKey: request.requestId,
        ),
        overrides: request.pokemonOverrides,
      );
    } on FormatException catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de générer un Pokémon sauvage valide.',
        debugDetails:
            'speciesId=${request.speciesId}, seed=${request.generationSeed}, error=${error.message}',
      );
    }
  }

  Future<RuntimePsdkBattleCombatantSeed> buildWildPsdkCombatantSeed({
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
    final generatedPokemon = request.generatedPokemon ??
        (await generateWildPlayerPokemon(
          projectRootDirectory: projectRootDirectory,
          pokemonConfig: pokemonConfig,
          movesCatalog: movesCatalog,
          request: request,
        ))
            .pokemon;
    final moveProjection = _resolvePsdkBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: generatedPokemon.knownMoveIds,
      combatantLabel: 'Le Pokémon sauvage "${request.speciesId}"',
      currentPpByMoveId: generatedPokemon.currentPpByMoveId,
    );
    final calculatedStats = _calculateResolvedStats(
      species: species,
      level: generatedPokemon.level,
      ivs: generatedPokemon.ivs,
      evs: generatedPokemon.evs,
      natureId: generatedPokemon.natureId,
      profileLabel: request.generationProfileId.isEmpty
          ? WildPokemonGenerationProfile.pokeMapBetaV1.profileId
          : request.generationProfileId,
    );

    return RuntimePsdkBattleCombatantSeed(
      speciesId: generatedPokemon.speciesId.trim(),
      level: generatedPokemon.level,
      maxHp: calculatedStats.maxHp,
      catchRate: species.catchRate,
      stats: _toBattleStatsSnapshot(calculatedStats),
      typing: _buildBattleTypingSnapshot(species),
      currentHp: generatedPokemon.currentHp,
      abilityId: generatedPokemon.abilityId,
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
    const opponentProfile = PokemonOpponentStatProfile.trainerV0;
    final calculatedStats = _calculateResolvedStats(
      species: species,
      level: teamMember.level,
      ivs: opponentProfile.ivs,
      evs: opponentProfile.evs,
      natureId: opponentProfile.natureId,
      profileLabel: opponentProfile.profileId,
    );

    return RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: calculatedStats.maxHp,
      catchRate: species.catchRate,
      stats: _toBattleStatsSnapshot(calculatedStats),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: _trainerMemberAbilityId(teamMember, species),
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  /// Override d'ability authoré (BETA-TRN-003), sinon l'ability primaire de
  /// l'espèce — le comportement historique.
  String _trainerMemberAbilityId(
    ProjectTrainerPokemonEntry teamMember,
    RuntimePokemonSpecies species,
  ) {
    final override = teamMember.abilityId?.trim();
    if (override != null && override.isNotEmpty) {
      return override;
    }
    return species.primaryAbilityId.isEmpty
        ? 'unknown'
        : species.primaryAbilityId;
  }

  Future<RuntimePsdkBattleCombatantSeed> buildTrainerPsdkCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ItemCatalogSnapshot itemCatalog,
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

    final moveProjection = _resolvePsdkBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel:
          'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
    );
    const opponentProfile = PokemonOpponentStatProfile.trainerV0;
    final calculatedStats = _calculateResolvedStats(
      species: species,
      level: teamMember.level,
      ivs: opponentProfile.ivs,
      evs: opponentProfile.evs,
      natureId: opponentProfile.natureId,
      profileLabel: opponentProfile.profileId,
    );

    return RuntimePsdkBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: calculatedStats.maxHp,
      catchRate: species.catchRate,
      stats: _toBattleStatsSnapshot(calculatedStats),
      typing: _buildBattleTypingSnapshot(species),
      abilityId: _trainerMemberAbilityId(teamMember, species),
      heldItemId: _resolvePsdkHeldItemId(
        teamMember.heldItemId,
        itemCatalog: itemCatalog,
        combatantLabel:
            'Le Pokémon du dresseur "$trainerName" (${teamMember.speciesId})',
      ),
      moves: moveProjection.moves,
      moveDiagnostics: moveProjection.diagnostics,
    );
  }

  String? _resolvePsdkHeldItemId(
    String? heldItemId, {
    required ItemCatalogSnapshot itemCatalog,
    required String combatantLabel,
  }) {
    final trimmed = heldItemId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    final resolution = resolveRuntimeHeldItemEffect(
      itemCatalog: itemCatalog,
      itemId: trimmed,
    );
    return switch (resolution.status) {
      RuntimeHeldItemSupportStatus.supported => resolution.heldEffectId,
      RuntimeHeldItemSupportStatus.invalidDefinition =>
        throw RuntimeBattleSetupException(
          '$combatantLabel tient un objet absent du catalogue.',
          debugDetails:
              'heldItemId=$trimmed, heldEffectId=null, support=invalid_definition',
        ),
      RuntimeHeldItemSupportStatus.passive => throw RuntimeBattleSetupException(
          '$combatantLabel tient un objet passif sans effet de combat.',
          debugDetails:
              'heldItemId=$trimmed, heldEffectId=null, support=passive_item',
        ),
      RuntimeHeldItemSupportStatus.unsupported =>
        throw RuntimeBattleSetupException(
          '$combatantLabel tient un effet d’objet non supporté en combat.',
          debugDetails: 'heldItemId=$trimmed, '
              'heldEffectId=${resolution.heldEffectId}, '
              'support=held_effect_not_ported',
        ),
    };
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
    Map<String, int>? currentPpByMoveId,
  }) {
    // Le builder garde désormais sa vraie policy de résolution dans une helper
    // partagée, afin que l'outillage Phase B puisse mesurer le même seam sans
    // reconstruire une variante plus permissive.
    return resolveBattleMovesForSeedWithDiagnostics(
      moveIds: moveIds,
      combatantLabel: combatantLabel,
      lookupMove: movesCatalog.lookup,
      battleMoveBridge: battleMoveBridge,
      currentPpByMoveId: currentPpByMoveId,
    );
  }

  RuntimePsdkBattleMoveProjection _resolvePsdkBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
    Map<String, int>? currentPpByMoveId,
  }) {
    return resolvePsdkBattleMovesForSeedWithDiagnostics(
      moveIds: moveIds,
      combatantLabel: combatantLabel,
      lookupMove: movesCatalog.lookup,
      battleMoveBridge: battleMoveBridge,
      currentPpByMoveId: currentPpByMoveId,
    );
  }

  Map<String, int> _requireHydratedCurrentPp(PlayerPokemon playerPokemon) {
    final currentPpByMoveId = playerPokemon.currentPpByMoveId;
    if (currentPpByMoveId == null) {
      throw RuntimeBattleSetupException(
        'Les PP du Pokémon joueur doivent être hydratés avant le combat.',
        debugDetails: 'speciesId=${playerPokemon.speciesId}',
      );
    }
    return currentPpByMoveId;
  }

  PokemonCalculatedStats _calculateResolvedStats({
    required RuntimePokemonSpecies species,
    required int level,
    required PokemonStatSpread ivs,
    required PokemonStatSpread evs,
    required String natureId,
    required String profileLabel,
  }) {
    // The project-aware runtime resolves raw species data once, then delegates
    // every formula and nature rule to the pure gameplay package. This keeps
    // legacy and PSDK seeds byte-for-byte aligned without teaching map_battle
    // how to read project catalogues.
    try {
      return const PokemonStatCalculator().calculate(
        baseStats: PokemonBaseStats(
          hp: species.baseHp,
          attack: species.baseAttack,
          defense: species.baseDefense,
          specialAttack: species.baseSpecialAttack,
          specialDefense: species.baseSpecialDefense,
          speed: species.baseSpeed,
        ),
        ivs: ivs,
        evs: evs,
        level: level,
        naturePolicy: PokemonNatureStatPolicy.canonical,
        natureId: natureId,
      );
    } on ArgumentError catch (error) {
      throw RuntimeBattleSetupException(
        'Les stats du combattant ne respectent pas le contrat battle.',
        debugDetails: 'profile=$profileLabel, speciesId=${species.id}, '
            'natureId=$natureId, ivs=$ivs, evs=$evs, error=$error',
      );
    }
  }

  BattleStatsSnapshot _toBattleStatsSnapshot(
    PokemonCalculatedStats calculated,
  ) {
    return BattleStatsSnapshot(
      attack: calculated.attack,
      defense: calculated.defense,
      specialAttack: calculated.specialAttack,
      specialDefense: calculated.specialDefense,
      speed: calculated.speed,
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
    required this.catchRate,
    required this.stats,
    required this.typing,
    required this.abilityId,
    this.majorStatus,
    required this.moves,
    this.moveDiagnostics = const <RuntimeBattleMoveBridgeDiagnostics>[],
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int catchRate;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final BattleMajorStatusState? majorStatus;
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
      catchRate: catchRate,
      stats: stats,
      typing: typing,
      majorStatus: majorStatus,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}

class RuntimePsdkBattleCombatantSeed {
  const RuntimePsdkBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.catchRate,
    required this.stats,
    required this.typing,
    required this.abilityId,
    this.heldItemId,
    this.majorStatus,
    required this.moves,
    this.moveDiagnostics = const <RuntimeBattleMoveBridgeDiagnostics>[],
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int catchRate;
  final BattleStatsSnapshot stats;
  final BattleTypingSnapshot typing;
  final int? currentHp;
  final String abilityId;
  final String? heldItemId;
  final PsdkBattleMajorStatus? majorStatus;
  final List<PsdkBattleMoveData> moves;
  final List<RuntimeBattleMoveBridgeDiagnostics> moveDiagnostics;

  List<RuntimeBattleMoveBridgeDiagnostics> get filteredMoveDiagnostics {
    return List<RuntimeBattleMoveBridgeDiagnostics>.unmodifiable(
      moveDiagnostics.where((diagnostic) => !diagnostic.psdkBridgeable),
    );
  }

  PsdkBattleCombatantSetup toPsdkBattleCombatantSetup({
    int lineupIndex = 0,
    String idPrefix = 'combatant',
  }) {
    return PsdkBattleCombatantSetup(
      id: '${idPrefix}_$lineupIndex',
      speciesId: speciesId,
      displayName: speciesId,
      level: level,
      maxHp: maxHp,
      catchRate: catchRate,
      currentHp: currentHp ?? maxHp,
      types: PsdkBattleTypes(
        primary: typing.primaryType,
        secondary: typing.secondaryType,
      ),
      stats: PsdkBattleStats(
        attack: stats.attack,
        defense: stats.defense,
        specialAttack: stats.specialAttack,
        specialDefense: stats.specialDefense,
        speed: stats.speed,
      ),
      moves: moves,
      majorStatus: majorStatus,
      abilityId: abilityId,
      heldItemId: heldItemId,
    );
  }
}
