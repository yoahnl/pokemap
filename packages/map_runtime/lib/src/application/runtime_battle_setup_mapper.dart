import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';

import 'battle_start_request.dart';
import 'runtime_battle_setup_exception.dart';
import 'runtime_map_bundle.dart';
import 'runtime_move_catalog_loader.dart';
import 'runtime_pokemon_learnset_loader.dart';
import 'runtime_pokemon_species_loader.dart';

export 'runtime_battle_setup_exception.dart' show RuntimeBattleSetupException;

const _runtimeCapturePokeBallItemId = 'poke-ball';
const _runtimeCapturePokeBallCategoryId = 'items';

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// M5 introduit un seam runtime spécialisé pour les moves parce que :
/// - le catalogue moves est maintenant canonique et beaucoup plus riche ;
/// - `runtime_battle_setup_mapper.dart` ne doit plus relire `moves.json`
///   comme un tuple pauvre `id/name/power` ;
/// - `map_battle` ne doit toujours pas lire le JSON projet brut.
///
/// M6 poursuit cette extraction pour les espèces et learnsets :
/// - le mapper ne relit plus lui-même ces JSON projet ;
/// - il délègue à de petits loaders runtime spécialisés ;
/// - il reste centré sur la composition combat, pas sur la plomberie locale.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper({
    this.moveCatalogLoader = const RuntimeMoveCatalogLoader(),
    this.speciesLoader = const RuntimePokemonSpeciesLoader(),
    this.learnsetLoader = const RuntimePokemonLearnsetLoader(),
  });

  final RuntimeMoveCatalogLoader moveCatalogLoader;
  final RuntimePokemonSpeciesLoader speciesLoader;
  final RuntimePokemonLearnsetLoader learnsetLoader;

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final movesCatalog = await moveCatalogLoader.load(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );

    final playerSeed = await _buildPlayerCombatantSeed(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
      movesCatalog: movesCatalog,
      gameState: gameState,
      playerPartyIndex: playerPartyIndex,
    );

    final enemySeed = switch (request) {
      WildBattleStartRequest() => await _buildWildCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          request: request,
        ),
      TrainerBattleStartRequest() => await _buildTrainerCombatantSeed(
          projectRootDirectory: bundle.projectRootDirectory,
          pokemonConfig: bundle.manifest.pokemon,
          movesCatalog: movesCatalog,
          manifest: bundle.manifest,
          request: request,
        ),
    };

    return BattleSetup(
      playerPokemon: playerSeed.toBattleCombatantData(),
      enemyPokemon: enemySeed.toBattleCombatantData(),
      isTrainerBattle: request is TrainerBattleStartRequest,
      trainerId:
          request is TrainerBattleStartRequest ? request.trainerId : null,
      // Le moteur battle ne connaît ni le bag runtime, ni les limites de party.
      // On garde donc la décision de "peut-on capturer ?" ici, au point où le
      // runtime possède encore les vraies données save/projet nécessaires.
      //
      // Lot 14 reste volontairement borné :
      // - combat sauvage uniquement ;
      // - aucune capture si la party est pleine (pas de PC/boxes ici) ;
      // - aucune capture sans Poké Ball réelle dans le bag du joueur.
      allowCapture: request is WildBattleStartRequest &&
          gameState.party.members.length < 6 &&
          _playerHasAtLeastOnePokeBall(gameState.bag),
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildPlayerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required GameState gameState,
    int? playerPartyIndex,
  }) async {
    final playerPokemon = _selectPlayerPartyMember(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
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

    return _RuntimeBattleCombatantSeed(
      speciesId: playerPokemon.speciesId.trim(),
      level: playerPokemon.level,
      maxHp: maxHp,
      currentHp: _clampInt(playerPokemon.currentHp, min: 0, max: maxHp),
      abilityId: playerPokemon.abilityId.trim().isEmpty
          ? 'unknown'
          : playerPokemon.abilityId.trim(),
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildWildCombatantSeed({
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

    return _RuntimeBattleCombatantSeed(
      speciesId: request.speciesId.trim(),
      level: request.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: request.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildTrainerCombatantSeed({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required RuntimeMoveCatalog movesCatalog,
    required ProjectManifest manifest,
    required TrainerBattleStartRequest request,
  }) async {
    final trainer = _findTrainer(manifest, request.trainerId);
    if (trainer.team.isEmpty) {
      throw RuntimeBattleSetupException(
        'Le dresseur "${trainer.name}" n’a aucun Pokémon dans son équipe.',
        debugDetails: 'trainerId=${trainer.id}',
      );
    }

    // Le moteur battle MVP reste mono-combattant : on prend donc le premier
    // Pokémon authoré de l’équipe, sans inventer une seconde logique de party.
    final teamMember = trainer.team.first;
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
          'Le Pokémon du dresseur "${trainer.name}" (${teamMember.speciesId})',
    );

    return _RuntimeBattleCombatantSeed(
      speciesId: teamMember.speciesId.trim(),
      level: teamMember.level,
      maxHp: _calculateMaxHp(
        baseHp: species.baseHp,
        level: teamMember.level,
      ),
      abilityId: species.primaryAbilityId.isEmpty
          ? 'unknown'
          : species.primaryAbilityId,
      moves: moves,
    );
  }

  /// Retourne l'index du slot réellement utilisé pour le handoff combat.
  ///
  /// Le runtime lot 10 doit mémoriser cet index exact pour réécrire les PV du
  /// bon membre après le combat. On expose donc explicitement cette sélection
  /// au lieu de forcer [PlayableMapGame] à dupliquer la logique.
  int selectUsablePartyMemberIndex(PlayerParty party) {
    for (var i = 0; i < party.members.length; i++) {
      if (!party.members[i].isFainted) {
        return i;
      }
    }

    if (party.members.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de lancer un combat sans Pokémon dans l’équipe du joueur.',
      );
    }

    throw const RuntimeBattleSetupException(
      'Tous les Pokémon de l’équipe du joueur sont K.O.; combat impossible.',
    );
  }

  /// Retourne le Pokémon joueur qui doit être injecté dans [BattleSetup].
  ///
  /// Deux cas :
  /// - lot 9 seul : on prend le premier membre jouable ;
  /// - lot 10 : le runtime fournit [playerPartyIndex] pour garantir que le
  ///   combat et le write-back visent exactement le même slot.
  ///
  /// On refuse explicitement un index invalide ou un slot déjà K.O. pour éviter
  /// tout glissement silencieux vers un autre membre de la party.
  PlayerPokemon _selectPlayerPartyMember(
    PlayerParty party, {
    int? playerPartyIndex,
  }) {
    final resolvedIndex =
        playerPartyIndex ?? selectUsablePartyMemberIndex(party);
    if (resolvedIndex < 0 || resolvedIndex >= party.members.length) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est invalide.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, partyLength=${party.members.length}',
      );
    }

    final member = party.members[resolvedIndex];
    if (member.isFainted) {
      throw RuntimeBattleSetupException(
        'Le slot de party joueur demandé pour le combat est déjà K.O.',
        debugDetails:
            'playerPartyIndex=$resolvedIndex, speciesId=${member.speciesId}',
      );
    }

    return member;
  }

  ProjectTrainerEntry _findTrainer(ProjectManifest manifest, String trainerId) {
    final normalizedTrainerId = trainerId.trim();
    for (final trainer in manifest.trainers) {
      if (trainer.id == normalizedTrainerId) {
        return trainer;
      }
    }

    throw RuntimeBattleSetupException(
      'Dresseur introuvable pour démarrer le combat.',
      debugDetails: 'trainerId=$trainerId',
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

    // On construit la liste de moves disponibles en respectant uniquement les
    // familles déjà exploitées ailleurs dans le projet :
    // - startingMoves
    // - relearnMoves
    // - levelUp <= niveau courant
    //
    // Ensuite on garde les 4 derniers IDs uniques. Cela reste simple, lisible
    // et suffisamment proche d’un move set plausible sans inventer un nouveau
    // moteur de sélection.
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
      _ensureMoveCanBeProjectedToBattle(
        move: move,
        combatantLabel: combatantLabel,
      );
      moves.add(
        BattleMoveData(
          id: move.id,
          name: move.name,
          // Le moteur battle MVP reste borné :
          // - il ne connaît encore ni accuracy, ni effets structurés, ni
          //   support level ;
          // - il consomme uniquement une puissance de base simplifiée.
          //
          // M5-bis change volontairement la frontière :
          // - seuls les moves déjà marqués `structuredSupported` arrivent
          //   jusqu'ici ;
          // - `catalogOnly` et `structuredPartial` échouent explicitement un
          //   peu plus haut, avant toute projection vers `BattleMoveData`.
          //
          // Ce `power: 0` restant n'est donc plus un downgrade silencieux
          // d'un move partiellement supporté. Il ne sert plus qu'aux moves
          // réellement autorisés par le gate runtime, mais qui suivent un flow
          // de dégâts non standard ou purement status dans le bridge MVP.
          //
          // Conséquence assumée pour ce lot :
          // - si le move suit le flow de dégâts standard, on transmet
          //   `basePower` ;
          // - sinon on garde `0`, exactement comme les vieux status moves du
          //   MVP battle.
          //
          // On documente explicitement cette limite au lieu de l'étendre ici :
          // décider quels `effects`/support levels deviennent réellement
          // exécutables appartient au futur pont runtime -> battle (M8), pas
          // à ce seam de chargement M5.
          power: move.usesStandardDamageFlow ? move.basePower : 0,
        ),
      );
    }
    return List<BattleMoveData>.unmodifiable(moves);
  }

  /// Refuse explicitement les moves déjà marqués comme non projetables vers le
  /// handoff battle actuel.
  ///
  /// Pourquoi le gate vit ici, et pas dans le loader :
  /// - le loader runtime doit rester un transport strict du canonique ;
  /// - il doit continuer à charger honnêtement `catalogOnly` et
  ///   `structuredPartial` pour le runtime au sens large ;
  /// - c'est seulement ici, au moment précis où l'on s'apprête à écraser le
  ///   move canonique riche vers le pont MVP `BattleMoveData(id, name, power)`,
  ///   que l'on sait si cette projection est honnête ou trompeuse.
  ///
  /// Conséquence assumée de M5-bis :
  /// - `structuredSupported` passe ;
  /// - `structuredPartial` et `catalogOnly` échouent immédiatement ;
  /// - aucun filtrage silencieux, aucun downgrade vers `power: 0`.
  void _ensureMoveCanBeProjectedToBattle({
    required PokemonMove move,
    required String combatantLabel,
  }) {
    if (move.engineSupportLevel ==
        PokemonMoveEngineSupportLevel.structuredSupported) {
      return;
    }

    final unsupportedReasons = move.unsupportedReasons.isEmpty
        ? '[]'
        : '[${move.unsupportedReasons.join(', ')}]';
    throw RuntimeBattleSetupException(
      'Le combat ne peut pas démarrer car "$combatantLabel" utilise une attaque que le handoff battle actuel ne sait pas projeter honnêtement.',
      debugDetails:
          'combatant=$combatantLabel, moveId=${move.id}, moveName=${move.name}, engineSupportLevel=${move.engineSupportLevel.name}, unsupportedReasons=$unsupportedReasons',
    );
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

    // Formule Pokémon simplifiée mais vraie dans son intention :
    // elle part bien des stats projet/save au lieu d’une constante hardcodée.
    final hp =
        (((2 * safeBaseHp + safeIv + (safeEv ~/ 4)) * safeLevel) ~/ 100) +
            safeLevel +
            10;
    return _clampInt(hp, min: 1, max: 999);
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

/// Retourne `true` si le bag runtime contient au moins une Poké Ball exploitable.
///
/// Le guard vit ici plutôt que dans `map_battle` car :
/// - le moteur battle ne doit pas dépendre du système de bag ;
/// - le runtime est déjà la frontière qui décide si `allowCapture` peut être
///   activé pour une rencontre donnée ;
/// - le lot 14 n'ouvre pas un inventaire global ni une politique de capture.
///
/// On tolère des IDs non normalisés en mémoire (`" poke-ball "`) pour rester
/// robuste face à un état runtime pas encore passé par le pipeline save/load.
bool _playerHasAtLeastOnePokeBall(Bag bag) {
  for (final entry in bag.entries) {
    if (entry.itemId.trim() == _runtimeCapturePokeBallItemId &&
        entry.categoryId.trim() == _runtimeCapturePokeBallCategoryId &&
        entry.quantity > 0) {
      return true;
    }
  }
  return false;
}

class _RuntimeBattleCombatantSeed {
  const _RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.abilityId,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int? currentHp;
  final String abilityId;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData() {
    return BattleCombatantData(
      speciesId: speciesId,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp,
      abilityId: abilityId,
      moves: moves,
    );
  }
}
