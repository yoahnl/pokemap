import 'dart:convert';
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';
import 'runtime_move_catalog_loader.dart';

/// Loader runtime spécialisé des learnsets Pokémon projet.
///
/// M6 extrait cette lecture hors du mapper pour garder une frontière nette :
/// - le loader lit le JSON projet strictement ;
/// - le mapper décide ensuite comment sélectionner les moves utiles pour le
///   combat courant.
///
/// Le contrat reste volontairement borné :
/// - lecture par `learnsetRef` si présent ;
/// - fallback vers `fallbackSpeciesId` si le ref est vide ;
/// - seules les familles déjà utilisées par le mapper sont exposées.
class RuntimePokemonLearnsetLoader {
  RuntimePokemonLearnsetLoader({
    RuntimeMoveCatalogLoader? moveCatalogLoader,
  }) : moveCatalogLoader = moveCatalogLoader ?? RuntimeMoveCatalogLoader();

  final RuntimeMoveCatalogLoader moveCatalogLoader;

  final Map<String, Future<RuntimePokemonLearnset>> _cache =
      <String, Future<RuntimePokemonLearnset>>{};
  int _actualReadCount = 0;

  int get debugActualReadCount => _actualReadCount;

  Future<PokemonMoveMachineCandidate?> loadMoveMachineCandidate({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesRef,
    required String fallbackSpeciesId,
    required String itemId,
    required String moveId,
    required String machineKind,
    required bool consumable,
  }) async {
    final normalizedKind = machineKind.trim();
    if (normalizedKind != 'tm' && normalizedKind != 'hm') {
      throw ArgumentError.value(
        machineKind,
        'machineKind',
        'must be tm or hm',
      );
    }
    final learnset = await loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: speciesRef,
      fallbackSpeciesId: fallbackSpeciesId,
    );
    final compatibleMoves = normalizedKind == 'tm' ? learnset.tm : learnset.hm;
    final normalizedMoveId = moveId.trim();
    if (!compatibleMoves.contains(normalizedMoveId)) return null;

    final moveCatalog = await moveCatalogLoader.load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final move = moveCatalog.lookup(normalizedMoveId);
    if (move == null || move.pp <= 0) {
      throw RuntimeBattleSetupException(
        'La machine référence une attaque absente ou inutilisable.',
        debugDetails:
            'itemId=${itemId.trim()}, moveId=$normalizedMoveId, pp=${move?.pp}',
      );
    }
    return PokemonMoveMachineCandidate(
      itemId: itemId,
      moveId: move.id,
      maxPp: move.pp,
      consumable: consumable,
    ).validated();
  }

  /// Loads every canonical level-up move crossed in `(oldLevel, newLevel]`.
  ///
  /// Ordering is deterministic: ascending learned level, then the stable
  /// learnset catalogue position. Missing moves and unusable max PP fail
  /// closed before gameplay receives the candidates.
  Future<List<PokemonMoveLearningCandidate>> loadLevelUpCandidates({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesRef,
    required String fallbackSpeciesId,
    required int oldLevel,
    required int newLevel,
  }) async {
    RangeError.checkValueInInterval(oldLevel, 1, 100, 'oldLevel');
    RangeError.checkValueInInterval(newLevel, 1, 100, 'newLevel');
    if (newLevel < oldLevel) {
      throw ArgumentError.value(
        newLevel,
        'newLevel',
        'must not be lower than oldLevel=$oldLevel',
      );
    }
    if (newLevel == oldLevel) {
      return const <PokemonMoveLearningCandidate>[];
    }

    final learnsetId = _resolveLearnsetId(
      speciesRef: speciesRef,
      fallbackSpeciesId: fallbackSpeciesId,
    );
    final learnset = await loadByRef(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
      speciesRef: speciesRef,
      fallbackSpeciesId: fallbackSpeciesId,
    );
    final crossedEntries = learnset.levelUp
        .where(
          (entry) => entry.level > oldLevel && entry.level <= newLevel,
        )
        .toList(growable: false)
      ..sort((left, right) {
        final byLevel = left.level.compareTo(right.level);
        if (byLevel != 0) return byLevel;
        return left.catalogOrder.compareTo(right.catalogOrder);
      });
    if (crossedEntries.isEmpty) {
      return const <PokemonMoveLearningCandidate>[];
    }

    final moveCatalog = await moveCatalogLoader.load(
      projectRootDirectory: projectRootDirectory,
      pokemonConfig: pokemonConfig,
    );
    final candidates = <PokemonMoveLearningCandidate>[];
    for (final entry in crossedEntries) {
      final move = moveCatalog.lookup(entry.moveId);
      if (move == null) {
        throw RuntimeBattleSetupException(
          'Le learnset Pokémon référence une attaque absente du catalogue.',
          debugDetails:
              'speciesRef=${speciesRef.trim()}, moveId=${entry.moveId}, level=${entry.level}',
        );
      }
      if (move.pp <= 0) {
        throw RuntimeBattleSetupException(
          'Le learnset Pokémon référence une attaque sans PP utilisables.',
          debugDetails:
              'speciesRef=${speciesRef.trim()}, moveId=${entry.moveId}, pp=${move.pp}',
        );
      }
      candidates.add(
        PokemonMoveLearningCandidate(
          opportunityId:
              '$learnsetId:levelUp:${entry.catalogOrder}:${entry.level}:${entry.moveId}',
          moveId: move.id,
          learnedAtLevel: entry.level,
          maxPp: move.pp,
        ),
      );
    }
    return List<PokemonMoveLearningCandidate>.unmodifiable(candidates);
  }

  Future<RuntimePokemonLearnset> loadByRef({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
    final learnsetId = _resolveLearnsetId(
      speciesRef: speciesRef,
      fallbackSpeciesId: fallbackSpeciesId,
    );

    final learnsetsDirectory = _normalizeConfiguredRelativePath(
      pokemonConfig.learnsetsDir,
      fallback: 'data/pokemon/learnsets',
    );
    final relativePath = p.join(learnsetsDirectory, '$learnsetId.json');
    final cacheKey =
        '${p.normalize(projectRootDirectory)}|${p.normalize(relativePath)}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    Future<RuntimePokemonLearnset> loadLearnset() async {
      _actualReadCount += 1;
      final json = await _readJsonAtProjectRelativePath(
        projectRootDirectory,
        relativePath,
        label: 'Pokemon learnset "$learnsetId"',
      );

      return RuntimePokemonLearnset(
        startingMoves: ((json['startingMoves'] as List?) ?? const <Object?>[])
            .whereType<String>()
            .toList(growable: false),
        relearnMoves: ((json['relearnMoves'] as List?) ?? const <Object?>[])
            .whereType<String>()
            .toList(growable: false),
        levelUp: _parseLevelUpEntries(
          json['levelUp'],
          learnsetId: learnsetId,
        ),
        tm: _parseMachineEntries(
          json['tm'],
          learnsetId: learnsetId,
          field: 'tm',
        ),
        hm: _parseMachineEntries(
          json['hm'],
          learnsetId: learnsetId,
          field: 'hm',
        ),
      );
    }

    final future = loadLearnset();
    _cache[cacheKey] = future;
    try {
      return await future;
    } catch (_) {
      final current = _cache[cacheKey];
      if (identical(current, future)) {
        _cache.remove(cacheKey);
      }
      rethrow;
    }
  }

  String _resolveLearnsetId({
    required String speciesRef,
    required String fallbackSpeciesId,
  }) {
    final normalizedSpeciesRef = speciesRef.trim();
    final normalizedFallbackSpeciesId = fallbackSpeciesId.trim();
    final learnsetId = normalizedSpeciesRef.isEmpty
        ? normalizedFallbackSpeciesId
        : normalizedSpeciesRef;
    if (learnsetId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de déterminer quel learnset Pokémon charger pour le combat.',
      );
    }
    return learnsetId;
  }

  List<RuntimePokemonLevelUpMove> _parseLevelUpEntries(
    Object? rawLevelUp, {
    required String learnsetId,
  }) {
    if (rawLevelUp == null) {
      return const <RuntimePokemonLevelUpMove>[];
    }
    if (rawLevelUp is! List) {
      throw RuntimeBattleSetupException(
        'Le learnset Pokémon contient des entrées level-up invalides.',
        debugDetails:
            'Pokemon learnset "$learnsetId" levelUp must be a JSON list',
      );
    }

    final entries = <RuntimePokemonLevelUpMove>[];
    for (var index = 0; index < rawLevelUp.length; index++) {
      final rawEntry = rawLevelUp[index];
      if (rawEntry is! Map) {
        throw RuntimeBattleSetupException(
          'Le learnset Pokémon contient une entrée level-up invalide.',
          debugDetails:
              'Pokemon learnset "$learnsetId" levelUp[$index] must be a JSON object',
        );
      }
      final rawMoveId = rawEntry['moveId'];
      final moveId = rawMoveId is String ? rawMoveId.trim() : '';
      final rawLevel = rawEntry['level'];
      if (moveId.isEmpty ||
          rawLevel is! int ||
          rawLevel < 1 ||
          rawLevel > 100) {
        throw RuntimeBattleSetupException(
          'Le learnset Pokémon contient une entrée level-up invalide.',
          debugDetails:
              'Pokemon learnset "$learnsetId" levelUp[$index] requires a non-empty moveId and integer level in 1..100',
        );
      }
      entries.add(
        RuntimePokemonLevelUpMove(
          moveId: moveId,
          level: rawLevel,
          catalogOrder: index,
        ),
      );
    }
    return List<RuntimePokemonLevelUpMove>.unmodifiable(entries);
  }

  List<String> _parseMachineEntries(
    Object? rawEntries, {
    required String learnsetId,
    required String field,
  }) {
    if (rawEntries == null) return const <String>[];
    if (rawEntries is! List) {
      throw RuntimeBattleSetupException(
        'Le learnset Pokémon contient des compatibilités machine invalides.',
        debugDetails:
            'Pokemon learnset "$learnsetId" $field must be a JSON list',
      );
    }
    final moveIds = <String>[];
    final seen = <String>{};
    for (var index = 0; index < rawEntries.length; index++) {
      final rawEntry = rawEntries[index];
      final rawMoveId = rawEntry is Map ? rawEntry['moveId'] : rawEntry;
      final moveId = rawMoveId is String ? rawMoveId.trim() : '';
      if (moveId.isEmpty) {
        throw RuntimeBattleSetupException(
          'Le learnset Pokémon contient une compatibilité machine invalide.',
          debugDetails:
              'Pokemon learnset "$learnsetId" $field[$index] requires a non-empty moveId',
        );
      }
      if (seen.add(moveId)) {
        moveIds.add(moveId);
      }
    }
    return List<String>.unmodifiable(moveIds);
  }

  Future<Map<String, dynamic>> _readJsonAtProjectRelativePath(
    String projectRootDirectory,
    String relativePath, {
    required String label,
  }) {
    return _readJsonFile(
      File(_resolveProjectPath(projectRootDirectory, relativePath)),
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
        debugDetails: '$label parse failed: $error (file=${file.path})',
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

  String _resolveProjectPath(
    String projectRootDirectory,
    String relativeOrAbsolutePath,
  ) {
    if (p.isAbsolute(relativeOrAbsolutePath)) {
      return p.normalize(relativeOrAbsolutePath);
    }
    return p.normalize(p.join(projectRootDirectory, relativeOrAbsolutePath));
  }
}

/// Vue runtime minimale d'un learnset réellement consommé par le mapper.
class RuntimePokemonLearnset {
  const RuntimePokemonLearnset({
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
    this.tm = const <String>[],
    this.hm = const <String>[],
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<RuntimePokemonLevelUpMove> levelUp;
  final List<String> tm;
  final List<String> hm;
}

/// Entrée level-up minimale conservée par le runtime.
class RuntimePokemonLevelUpMove {
  const RuntimePokemonLevelUpMove({
    required this.moveId,
    required this.level,
    this.catalogOrder = 0,
  });

  final String moveId;
  final int level;
  final int catalogOrder;
}
