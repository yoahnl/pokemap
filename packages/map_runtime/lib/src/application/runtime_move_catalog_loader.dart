import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

/// Loader runtime spécialisé du catalogue canonique des moves.
///
/// M5 ouvre volontairement un seam dédié ici, et pas dans `map_battle`, car :
/// - la source de vérité reste le workspace projet ;
/// - `map_runtime` est la bonne frontière pour lire ce JSON projet ;
/// - `map_battle` ne doit toujours pas connaître le stockage local ;
/// - le runtime doit être strict : aucun fallback legacy ni placeholder.
///
/// Le contrat est volontairement petit et ferme :
/// - lire `catalogFiles['moves']` depuis le manifeste projet ;
/// - parser chaque entrée via `PokemonMove.fromJson(...)` ;
/// - construire un index stable par id ;
/// - échouer explicitement si une entrée est invalide, dupliquée ou absente.
class RuntimeMoveCatalogLoader {
  RuntimeMoveCatalogLoader();

  final Map<String, Future<RuntimeMoveCatalog>> _cache =
      <String, Future<RuntimeMoveCatalog>>{};
  int _actualReadCount = 0;

  @visibleForTesting
  int get debugActualReadCount => _actualReadCount;

  Future<RuntimeMoveCatalog> load({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
  }) async {
    final relativePath = pokemonConfig.catalogFiles['moves']?.trim();
    if (relativePath == null || relativePath.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Impossible de charger le catalogue local des attaques pour démarrer le combat.',
        debugDetails: 'ProjectPokemonConfig.catalogFiles["moves"] is empty',
      );
    }

    final cacheKey =
        '${p.normalize(projectRootDirectory)}|${p.normalize(relativePath)}';
    final cached = _cache[cacheKey];
    if (cached != null) {
      return cached;
    }

    Future<RuntimeMoveCatalog> loadCatalog() async {
      _actualReadCount += 1;

      final json = await _readJsonAtProjectRelativePath(
        projectRootDirectory,
        relativePath,
        label: 'Moves catalog',
      );
      final declaredCatalog = (json['catalog'] as String?)?.trim();
      if (declaredCatalog == null || declaredCatalog.isEmpty) {
        throw const RuntimeBattleSetupException(
          'Le catalogue local des attaques est invalide; combat impossible.',
          debugDetails: 'Moves catalog is missing a non-empty "catalog" field',
        );
      }
      if (declaredCatalog != 'moves') {
        throw RuntimeBattleSetupException(
          'Le catalogue local des attaques a une forme inattendue.',
          debugDetails:
              'expected catalog="moves", actual catalog="$declaredCatalog"',
        );
      }

      final rawEntries = json['entries'];
      if (rawEntries is! List) {
        throw const RuntimeBattleSetupException(
          'Le catalogue local des attaques est invalide; combat impossible.',
          debugDetails: 'Moves catalog "entries" must be a JSON list',
        );
      }

      final entriesById = <String, PokemonMove>{};
      for (var index = 0; index < rawEntries.length; index++) {
        final rawEntry = rawEntries[index];
        if (rawEntry is! Map) {
          throw RuntimeBattleSetupException(
            'Le catalogue local des attaques contient une entrée invalide.',
            debugDetails: 'entryIndex=$index is not a JSON object',
          );
        }

        final entry = rawEntry.cast<String, dynamic>();
        final parsedMove = _parseCanonicalMoveEntry(
          entry,
          entryIndex: index,
        );

        if (entriesById.containsKey(parsedMove.id)) {
          throw RuntimeBattleSetupException(
            'Le catalogue local des attaques contient des ids dupliqués.',
            debugDetails:
                'duplicate move id="${parsedMove.id}" at entryIndex=$index',
          );
        }
        entriesById[parsedMove.id] = parsedMove;
      }

      if (entriesById.isEmpty) {
        throw const RuntimeBattleSetupException(
          'Le catalogue local des attaques est vide; combat impossible.',
        );
      }

      return RuntimeMoveCatalog._(
        Map<String, PokemonMove>.unmodifiable(entriesById),
      );
    }

    final future = loadCatalog();
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

  PokemonMove _parseCanonicalMoveEntry(
    Map<String, dynamic> entry, {
    required int entryIndex,
  }) {
    try {
      return PokemonMove.fromJson(entry);
    } on Object catch (error) {
      final rawId = (entry['id'] as String?)?.trim();
      throw RuntimeBattleSetupException(
        'Le catalogue local des attaques contient une entrée canonique invalide.',
        debugDetails:
            'entryIndex=$entryIndex${rawId == null || rawId.isEmpty ? '' : ', id=$rawId'} error=$error',
      );
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
        debugDetails: '$label parse failed: $error',
      );
    }
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

/// Index runtime en lecture seule des moves canoniques.
///
/// On réutilise directement `PokemonMove` pour éviter un faux DTO runtime
/// cloné à 95%. Ce seam donne au runtime tout ce dont il a besoin aujourd'hui :
/// - lookup strict par id ;
/// - accès aux champs canoniques ;
/// - préservation du niveau de support moteur et des raisons associées.
class RuntimeMoveCatalog {
  RuntimeMoveCatalog._(this.entriesById);

  final Map<String, PokemonMove> entriesById;

  PokemonMove? lookup(String moveId) => entriesById[moveId.trim()];
}
