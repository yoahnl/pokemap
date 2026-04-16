import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_move_bridge.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

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
  const RuntimeBattleCombatantSeedBuilder({
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
    this.battleMoveBridge = const RuntimeBattleMoveBridge(),
  });

  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;
  final RuntimeBattleMoveBridge battleMoveBridge;

  Future<RuntimeBattleCombatantSeed> buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required PlayerPokemon playerPokemon,
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

    final moves = _resolveBattleMoves(
      movesCatalog: movesCatalog,
      moveIds: moveIds,
      combatantLabel: 'Le Pokémon actif du joueur',
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
      moves: moves,
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
    final moves = _resolveBattleMoves(
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
      moves: moves,
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

    final moves = _resolveBattleMoves(
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
      moves: moves,
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

    // On conserve strictement la policy M6 :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    // - unicité préservant l'ordre
    // - 4 derniers moves maximum
    final ordered = <String>[
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp
          .where((entry) => entry.level <= level)
          .map((entry) => entry.moveId),
    ];
    final unique = _normalizeUniqueIdsPreserveOrder(ordered);
    if (unique.length <= 4) {
      return unique;
    }
    return unique.sublist(unique.length - 4);
  }

  List<BattleMoveData> _resolveBattleMoves({
    required RuntimeMoveCatalog movesCatalog,
    required List<String> moveIds,
    required String combatantLabel,
  }) {
    final normalizedMoveIds = _normalizeUniqueIdsPreserveOrder(moveIds);
    if (normalizedMoveIds.isEmpty) {
      throw RuntimeBattleSetupException(
        '$combatantLabel n’a aucune attaque exploitable pour démarrer le combat.',
      );
    }

    final moves = <BattleMoveData>[];
    for (final moveId in normalizedMoveIds.take(4)) {
      final move = movesCatalog.lookup(moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques ne contient pas "$moveId".',
          debugDetails: 'combatant=$combatantLabel',
        );
      }
      // M8 sort enfin la policy de projection du builder brut :
      // - le builder assemble des seeds de combattants ;
      // - le bridge décide ce qui est réellement exécutable par `map_battle` ;
      // - cela rend le refus plus honnête que l'ancien simple gate
      //   `engineSupportLevel == structuredSupported`.
      moves.add(
        battleMoveBridge.toBattleMoveData(
          move: move,
          combatantLabel: combatantLabel,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  List<String> _normalizeUniqueIdsPreserveOrder(List<String> rawIds) {
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

  BattleCombatantData toBattleCombatantData() {
    return BattleCombatantData(
      speciesId: speciesId,
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
