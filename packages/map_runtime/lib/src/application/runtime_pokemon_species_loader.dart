import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

/// Loader runtime spécialisé des espèces Pokémon projet.
///
/// M6 extrait ce seam du mapper battle pour deux raisons simples :
/// - la lecture JSON projet ne doit plus vivre cachée dans le mapper ;
/// - le runtime a besoin d'un point de lecture testable, strict et borné pour
///   les espèces, exactement comme il en a désormais un pour les moves.
///
/// Important :
/// - ce loader reste volontairement petit ;
/// - il ne devient pas un repository Pokémon générique ;
/// - il lit uniquement les champs dont le runtime battle actuel a besoin.
class RuntimePokemonSpeciesLoader {
  const RuntimePokemonSpeciesLoader();

  Future<RuntimePokemonSpecies> loadById({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesId,
  }) async {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const RuntimeBattleSetupException(
        'Une espèce Pokémon vide ne peut pas être mappée vers le combat.',
      );
    }

    final speciesDirectory = Directory(
      _resolveProjectPath(
        projectRootDirectory,
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

    RuntimePokemonSpecies? matchedSpecies;
    String? matchedFilePath;

    // Invariant important préservé depuis le mapper historique :
    // la résolution se fait par l'id déclaré dans le JSON, pas par le nom
    // de fichier. On scanne donc les fichiers JSON top-level et on lit leur
    // `id` réel avant de conclure.
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

      if (matchedSpecies != null) {
        throw RuntimeBattleSetupException(
          'Plusieurs espèces Pokémon locales déclarent le même id; combat impossible.',
          debugDetails:
              'speciesId=$normalizedSpeciesId, firstFile=$matchedFilePath, duplicateFile=${entity.path}',
        );
      }

      matchedSpecies = _parseRuntimeSpecies(
        rawJson,
        expectedSpeciesId: normalizedSpeciesId,
        filePath: entity.path,
      );
      matchedFilePath = entity.path;
    }

    if (matchedSpecies == null) {
      throw RuntimeBattleSetupException(
        'Espèce Pokémon introuvable pour démarrer le combat.',
        debugDetails: 'speciesId=$speciesId',
      );
    }

    return matchedSpecies;
  }

  RuntimePokemonSpecies _parseRuntimeSpecies(
    Map<String, dynamic> rawJson, {
    required String expectedSpeciesId,
    required String filePath,
  }) {
    final baseStats = (rawJson['baseStats'] as Map?)?.cast<String, dynamic>();
    final baseHp = _readRequiredBaseStat(
      baseStats,
      statKey: 'hp',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseAttack = _readRequiredBaseStat(
      baseStats,
      statKey: 'atk',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseDefense = _readRequiredBaseStat(
      baseStats,
      statKey: 'def',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseSpecialAttack = _readRequiredBaseStat(
      baseStats,
      statKey: 'spa',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseSpecialDefense = _readRequiredBaseStat(
      baseStats,
      statKey: 'spd',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final baseSpeed = _readRequiredBaseStat(
      baseStats,
      statKey: 'spe',
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );

    final refs = (rawJson['refs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{
          'learnset': (rawJson['learnsetRef'] as String?)?.trim() ?? '',
        };
    final abilities = (rawJson['abilities'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    final typing = _readRequiredTyping(
      rawJson,
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );

    return RuntimePokemonSpecies(
      id: expectedSpeciesId,
      typing: typing,
      baseHp: baseHp,
      baseAttack: baseAttack,
      baseDefense: baseDefense,
      baseSpecialAttack: baseSpecialAttack,
      baseSpecialDefense: baseSpecialDefense,
      baseSpeed: baseSpeed,
      maleGenderRatio: _readOptionalGenderRatio(
        rawJson['breeding'],
        ratioKey: 'male',
      ),
      femaleGenderRatio: _readOptionalGenderRatio(
        rawJson['breeding'],
        ratioKey: 'female',
      ),
      primaryAbilityId: (abilities['primary'] as String?)?.trim() ?? '',
      // `learnsetRef` peut rester vide : le loader learnset conservera le
      // fallback historique vers l'id de l'espèce.
      learnsetRef: (refs['learnset'] as String?)?.trim() ?? '',
    );
  }

  List<String> _readRequiredTyping(
    Map<String, dynamic> rawJson, {
    required String expectedSpeciesId,
    required String filePath,
  }) {
    // BE5 ouvre enfin la consommation réelle du type dans `map_battle`.
    //
    // Le runtime doit donc arrêter de traiter le typing espèce comme une
    // donnée "nice to have" :
    // - le vrai chemin runtime -> battle a besoin d'un typing explicite ;
    // - l'absence ou la corruption de ce champ doit donc faire échouer le
    //   handoff tôt, avec une erreur actionnable ;
    // - on garde cette validation ici, côté lecture projet, et non dans le
    //   moteur battle qui ne doit jamais relire le JSON brut.
    final rawTyping = (rawJson['typing'] as Map?)?.cast<String, dynamic>();
    final rawTypes = (rawTyping?['types'] as List?)?.cast<Object?>();
    if (rawTypes == null || rawTypes.isEmpty || rawTypes.length > 2) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, typing.types must contain 1 or 2 entries',
      );
    }

    final normalizedTypes = <String>[];
    for (final rawType in rawTypes) {
      final normalizedType = (rawType as String?)?.trim().toLowerCase() ?? '';
      if (normalizedType.isEmpty || normalizedTypes.contains(normalizedType)) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'speciesId=$expectedSpeciesId, file=$filePath, typing.types contains an empty or duplicate entry',
        );
      }

      // Source de vérité volontairement unique :
      // - BE5 a placé la liste canonique des types battle supportés dans
      //   `BattleTypeChart.supportedTypes` ;
      // - ce loader runtime ne doit ni recopier cette liste, ni inventer sa
      //   propre validation divergente ;
      // - on réutilise donc directement le contrat battle pour échouer tôt,
      //   avant qu'un `StateError` tardif n'émerge pendant le calcul des
      //   dégâts.
      if (!BattleTypeChart.supportedTypes.contains(normalizedType)) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'speciesId=$expectedSpeciesId, file=$filePath, unsupported typing.types entry=$normalizedType',
        );
      }

      normalizedTypes.add(normalizedType);
    }

    return List<String>.unmodifiable(normalizedTypes);
  }

  int _readRequiredBaseStat(
    Map<String, dynamic>? baseStats, {
    required String statKey,
    required String expectedSpeciesId,
    required String filePath,
  }) {
    // BE2 garde le loader species volontairement petit, mais il ne peut plus
    // se contenter de `hp` seulement : le runtime doit maintenant construire
    // un vrai snapshot de stats combat, donc chaque base stat non-HP requise
    // doit être présente ou provoquer une erreur actionnable.
    final value = (baseStats?[statKey] as num?)?.toInt();
    if (value == null || value <= 0) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, missing or invalid baseStats.$statKey',
      );
    }
    return value;
  }

  double? _readOptionalGenderRatio(
    Object? rawBreeding, {
    required String ratioKey,
  }) {
    final breeding = (rawBreeding as Map?)?.cast<String, dynamic>();
    final genderRatio =
        (breeding?['genderRatio'] as Map?)?.cast<String, dynamic>();
    final rawValue = genderRatio?[ratioKey];
    if (rawValue is num) {
      return rawValue.toDouble();
    }
    return null;
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

/// Vue runtime minimale d'une espèce réellement consommée par le mapper.
///
/// On ne clone pas le JSON espèce au complet :
/// - le runtime battle n'a besoin que de peu de champs ici ;
/// - un DTO minimal typed est plus sûr qu'un `Map<String, dynamic>`;
/// - cela évite de laisser de la logique métier dépendre de clés JSON libres.
class RuntimePokemonSpecies {
  const RuntimePokemonSpecies({
    required this.id,
    required this.typing,
    required this.baseHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseSpecialAttack,
    required this.baseSpecialDefense,
    required this.baseSpeed,
    this.maleGenderRatio,
    this.femaleGenderRatio,
    required this.primaryAbilityId,
    required this.learnsetRef,
  });

  final String id;

  /// Typing défensif minimal réellement nécessaire à partir de BE5.
  ///
  /// Le loader le garde encore côté runtime, pas côté battle :
  /// - il fait partie de la donnée projet résolue par l'application ;
  /// - le seed builder décidera ensuite du contrat battle précis à produire ;
  /// - `map_battle` reste ainsi libre de sa propre représentation locale.
  final List<String> typing;
  final int baseHp;
  final int baseAttack;
  final int baseDefense;
  final int baseSpecialAttack;
  final int baseSpecialDefense;
  final int baseSpeed;
  final double? maleGenderRatio;
  final double? femaleGenderRatio;
  final String primaryAbilityId;
  final String learnsetRef;
}
