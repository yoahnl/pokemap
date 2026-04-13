import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'battle_start_request.dart';
import 'runtime_map_bundle.dart';

/// Exception levée quand le runtime ne peut pas construire un [BattleSetup]
/// honnête à partir des vraies données projet/save.
///
/// Le lot 9 supprime volontairement les placeholders hardcodés. Quand une
/// donnée réelle manque (catalogue moves absent, espèce introuvable, équipe
/// trainer vide, etc.), on préfère donc échouer explicitement plutôt que de
/// relancer un combat avec un Pokémon inventé.
class RuntimeBattleSetupException implements Exception {
  const RuntimeBattleSetupException(
    this.message, {
    this.debugDetails,
  });

  final String message;
  final String? debugDetails;

  @override
  String toString() {
    final details = debugDetails?.trim();
    if (details == null || details.isEmpty) {
      return message;
    }
    return '$message ($details)';
  }
}

/// Mapper runtime unique vers [BattleSetup].
///
/// Important :
/// - cette classe reste locale à `map_runtime` ;
/// - elle ne réintroduit pas de dépendance vers `map_editor` ;
/// - elle relit uniquement le strict nécessaire des données Pokémon projet
///   pour construire le setup de combat réel.
///
/// On garde ici un reader JSON minimal parce que :
/// - la source de vérité des données Pokémon de runtime est le workspace projet ;
/// - `map_runtime` ne doit pas dépendre des modèles internes de `map_editor` ;
/// - le lot 9 ne justifie pas une nouvelle architecture partagée.
class RuntimeBattleSetupMapper {
  const RuntimeBattleSetupMapper();

  Future<BattleSetup> map({
    required RuntimeMapBundle bundle,
    required GameState gameState,
    required BattleStartRequest request,
    int? playerPartyIndex,
  }) async {
    final reader = _RuntimePokemonProjectReader(
      projectRootDirectory: bundle.projectRootDirectory,
      pokemonConfig: bundle.manifest.pokemon,
    );
    final movesCatalog = await reader.readMovesCatalog();

    final playerSeed = await _buildPlayerCombatantSeed(
      reader: reader,
      movesCatalog: movesCatalog,
      gameState: gameState,
      playerPartyIndex: playerPartyIndex,
    );

    final enemySeed = switch (request) {
      WildBattleStartRequest() => await _buildWildCombatantSeed(
          reader: reader,
          movesCatalog: movesCatalog,
          request: request,
        ),
      TrainerBattleStartRequest() => await _buildTrainerCombatantSeed(
          reader: reader,
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
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildPlayerCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required _RuntimeMovesCatalog movesCatalog,
    required GameState gameState,
    int? playerPartyIndex,
  }) async {
    final playerPokemon = _selectPlayerPartyMember(
      gameState.party,
      playerPartyIndex: playerPartyIndex,
    );
    final species = await reader.readSpeciesById(playerPokemon.speciesId);
    final moveIds = playerPokemon.knownMoveIds.isNotEmpty
        ? playerPokemon.knownMoveIds
        : await _deriveLearnsetMoveIds(
            reader: reader,
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
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildWildCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required _RuntimeMovesCatalog movesCatalog,
    required WildBattleStartRequest request,
  }) async {
    final species = await reader.readSpeciesById(request.speciesId);
    final moveIds = await _deriveLearnsetMoveIds(
      reader: reader,
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
      moves: moves,
    );
  }

  Future<_RuntimeBattleCombatantSeed> _buildTrainerCombatantSeed({
    required _RuntimePokemonProjectReader reader,
    required _RuntimeMovesCatalog movesCatalog,
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
    final species = await reader.readSpeciesById(teamMember.speciesId);
    final moveIds = teamMember.moves.isNotEmpty
        ? teamMember.moves
        : await _deriveLearnsetMoveIds(
            reader: reader,
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
    required _RuntimePokemonProjectReader reader,
    required _RuntimePokemonSpecies species,
    required int level,
  }) async {
    final learnset = await reader.readLearnsetByRef(
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
    required _RuntimeMovesCatalog movesCatalog,
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
      moves.add(
        BattleMoveData(
          id: move.id,
          name: move.displayName,
          power: move.power,
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

class _RuntimeBattleCombatantSeed {
  const _RuntimeBattleCombatantSeed({
    required this.speciesId,
    required this.level,
    required this.maxHp,
    required this.moves,
    this.currentHp,
  });

  final String speciesId;
  final int level;
  final int maxHp;
  final int? currentHp;
  final List<BattleMoveData> moves;

  BattleCombatantData toBattleCombatantData() {
    return BattleCombatantData(
      speciesId: speciesId,
      level: level,
      maxHp: maxHp,
      currentHp: currentHp,
      moves: moves,
    );
  }
}

/// Reader JSON ultra-ciblé pour le runtime battle handoff.
///
/// Il relit uniquement ce que le lot 9 doit mapper :
/// - espèces (id, base HP, ref learnset)
/// - learnsets
/// - catalogue moves
///
/// Il n’essaie pas de devenir une nouvelle couche Pokémon partagée.
class _RuntimePokemonProjectReader {
  const _RuntimePokemonProjectReader({
    required this.projectRootDirectory,
    required this.pokemonConfig,
  });

  final String projectRootDirectory;
  final ProjectPokemonConfig pokemonConfig;

  Future<_RuntimeMovesCatalog> readMovesCatalog() async {
    final relativePath = pokemonConfig.catalogFiles['moves']?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de charger le catalogue local des attaques pour démarrer le combat.',
        debugDetails: 'ProjectPokemonConfig.catalogFiles["moves"] is empty',
      );
    }

    final json = await _readJsonAtProjectRelativePath(
      relativePath,
      label: 'Moves catalog',
    );
    final rawEntries = (json['entries'] as List?) ?? const <Object?>[];
    final entries = <String, _RuntimeMoveCatalogEntry>{};
    for (final rawEntry in rawEntries.whereType<Map>()) {
      final entry = rawEntry.cast<String, dynamic>();
      final id = (entry['id'] as String?)?.trim() ?? '';
      if (id.isEmpty) {
        continue;
      }
      entries[id] = _RuntimeMoveCatalogEntry(
        id: id,
        displayName: ((entry['name'] as String?)?.trim().isNotEmpty ?? false)
            ? (entry['name'] as String).trim()
            : id,
        power: (entry['power'] as num?)?.toInt() ?? 0,
      );
    }

    if (entries.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Le catalogue local des attaques est vide; combat impossible.',
      );
    }

    return _RuntimeMovesCatalog(entries);
  }

  Future<_RuntimePokemonSpecies> readSpeciesById(String speciesId) async {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Une espèce Pokémon vide ne peut pas être mappée vers le combat.',
      );
    }

    final speciesDirectory = Directory(
      _resolveProjectPath(
        _normalizeConfiguredRelativePath(
          pokemonConfig.speciesDir,
          fallback: 'data/pokemon/species',
        ),
      ),
    );
    if (!await speciesDirectory.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les espèces Pokémon locales pour démarrer le combat.',
        debugDetails: 'Missing species directory: ${speciesDirectory.path}',
      );
    }

    await for (final entity in speciesDirectory.list(recursive: false)) {
      if (entity is! File ||
          p.extension(entity.path).toLowerCase() != '.json') {
        continue;
      }
      final rawJson = await _readJsonFile(
        entity,
        label: 'Pokemon species file',
      );
      final declaredId = (rawJson['id'] as String?)?.trim() ?? '';
      if (declaredId != normalizedSpeciesId) {
        continue;
      }

      final baseStats =
          (rawJson['baseStats'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{};
      final refs = (rawJson['refs'] as Map?)?.cast<String, dynamic>() ??
          <String, dynamic>{
            'learnset': (rawJson['learnsetRef'] as String?)?.trim() ?? '',
          };
      return _RuntimePokemonSpecies(
        id: declaredId,
        baseHp: (baseStats['hp'] as num?)?.toInt() ?? 1,
        learnsetRef: (refs['learnset'] as String?)?.trim() ?? '',
      );
    }

    throw RuntimeBattleSetupException(
      'Espèce Pokémon introuvable pour démarrer le combat.',
      debugDetails: 'speciesId=$speciesId',
    );
  }

  Future<_RuntimePokemonLearnset> readLearnsetByRef({
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
    final learnsetId =
        speciesRef.trim().isEmpty ? fallbackSpeciesId : speciesRef;
    final learnsetsDirectory = _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
    final relativePath = p.join(learnsetsDirectory, '$learnsetId.json');
    final json = await _readJsonAtProjectRelativePath(
      relativePath,
      label: 'Pokemon learnset "$learnsetId"',
    );

    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    return _RuntimePokemonLearnset(
      startingMoves: ((json['startingMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      relearnMoves: ((json['relearnMoves'] as List?) ?? const <Object?>[])
          .whereType<String>()
          .toList(growable: false),
      levelUp: rawLevelUp
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .map(
            (entry) => _RuntimePokemonLevelUpMove(
              moveId: (entry['moveId'] as String?)?.trim() ?? '',
              level: (entry['level'] as num?)?.toInt() ?? 0,
            ),
          )
          .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
          .toList(growable: false),
    );
  }

  Future<Map<String, dynamic>> _readJsonAtProjectRelativePath(
    String relativePath, {
    required String label,
  }) {
    return _readJsonFile(
      File(_resolveProjectPath(relativePath)),
      label: label,
    );
  }

  Future<Map<String, dynamic>> _readJsonFile(
    File file, {
    required String label,
  }) async {
    if (!await file.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label file not found: ${file.path}',
      );
    }

    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException('Root JSON object expected');
      }
      return decoded;
    } on RuntimeBattleSetupException {
      rethrow;
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Impossible de lire les données Pokémon locales nécessaires au combat.',
        debugDetails: '$label parse failed: $error',
      );
    }
  }

  String _normalizeConfiguredRelativePath(
    String rawPath, {
    required String fallback,
  }) {
    final trimmed = rawPath.trim();
    return p.normalize(trimmed.isEmpty ? fallback : trimmed);
  }

  String _resolveProjectPath(String relativeOrAbsolutePath) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }
}

class _RuntimePokemonSpecies {
  const _RuntimePokemonSpecies({
    required this.id,
    required this.baseHp,
    required this.learnsetRef,
  });

  final String id;
  final int baseHp;
  final String learnsetRef;
}

class _RuntimePokemonLearnset {
  const _RuntimePokemonLearnset({
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<_RuntimePokemonLevelUpMove> levelUp;
}

class _RuntimePokemonLevelUpMove {
  const _RuntimePokemonLevelUpMove({
    required this.moveId,
    required this.level,
  });

  final String moveId;
  final int level;
}

class _RuntimeMovesCatalog {
  const _RuntimeMovesCatalog(this.entriesById);

  final Map<String, _RuntimeMoveCatalogEntry> entriesById;

  _RuntimeMoveCatalogEntry? lookup(String moveId) => entriesById[moveId.trim()];
}

class _RuntimeMoveCatalogEntry {
  const _RuntimeMoveCatalogEntry({
    required this.id,
    required this.displayName,
    required this.power,
  });

  final String id;
  final String displayName;
  final int power;
}
