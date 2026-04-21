import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

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
  RuntimePokemonLearnsetLoader();

  final Map<String, Future<RuntimePokemonLearnset>> _cache =
      <String, Future<RuntimePokemonLearnset>>{};
  int _actualReadCount = 0;

  @visibleForTesting
  int get debugActualReadCount => _actualReadCount;

  Future<RuntimePokemonLearnset> loadByRef({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesRef,
    required String fallbackSpeciesId,
  }) async {
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

      final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
      return RuntimePokemonLearnset(
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
              (entry) => RuntimePokemonLevelUpMove(
                moveId: (entry['moveId'] as String?)?.trim() ?? '',
                level: (entry['level'] as num?)?.toInt() ?? 0,
              ),
            )
            .where((entry) => entry.moveId.isNotEmpty && entry.level > 0)
            .toList(growable: false),
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
  });

  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<RuntimePokemonLevelUpMove> levelUp;
}

/// Entrée level-up minimale conservée par le runtime.
class RuntimePokemonLevelUpMove {
  const RuntimePokemonLevelUpMove({
    required this.moveId,
    required this.level,
  });

  final String moveId;
  final int level;
}
