import 'dart:convert';
import 'dart:io';

import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:path/path.dart' as p;

import 'runtime_battle_setup_exception.dart';

final class RuntimePokemonSpeciesNotFoundException
    extends RuntimeBattleSetupException {
  const RuntimePokemonSpeciesNotFoundException(this.speciesId)
      : super(
          'Espèce Pokémon introuvable pour démarrer le combat.',
          debugDetails: 'speciesId=$speciesId',
        );

  final String speciesId;
}

final class RuntimePokemonSpeciesDisabledException
    extends RuntimeBattleSetupException {
  const RuntimePokemonSpeciesDisabledException(String speciesId)
      : super(
          'Cette espèce Pokémon est désactivée dans le projet.',
          debugDetails: 'speciesId=$speciesId',
        );
}

/// Projection progression validée d'une fiche espèce projet.
final class RuntimePokemonSpeciesProgression {
  const RuntimePokemonSpeciesProgression({
    required this.growthRateId,
    required this.baseExp,
    required this.catchRate,
  });

  final String growthRateId;
  final int baseExp;
  final int catchRate;
}

class RuntimePokemonSpeciesSnapshotMetrics {
  const RuntimePokemonSpeciesSnapshotMetrics();

  void onSnapshotBuildStarted(String projectRoot, String speciesDirectory) {}

  void onSpeciesDirectoryListed(String projectRoot, String speciesDirectory) {}

  void onSpeciesJsonRead(String projectRoot, String speciesPath) {}
}

/// Valide et projette les champs de progression consommés par le runtime.
///
/// Ce seam pur est partagé avec l'audit du catalogue Selbrume : le test de
/// masse et le vrai loader ne peuvent donc pas dériver sur leurs invariants.
RuntimePokemonSpeciesProgression parseRuntimePokemonSpeciesProgression(
  Map<String, dynamic> rawJson, {
  required String expectedSpeciesId,
  required String filePath,
}) {
  final rawDeclaredSpeciesId = rawJson['id'];
  final declaredSpeciesId =
      rawDeclaredSpeciesId is String ? rawDeclaredSpeciesId.trim() : '';
  if (declaredSpeciesId != expectedSpeciesId) {
    throw RuntimeBattleSetupException(
      'Les données de progression Pokémon locales sont invalides; combat impossible.',
      debugDetails:
          'speciesId=$expectedSpeciesId, file=$filePath, declaredId=$declaredSpeciesId',
    );
  }

  final rawProgression = rawJson['progression'];
  final progression =
      rawProgression is Map ? rawProgression.cast<String, dynamic>() : null;
  if (progression == null) {
    throw RuntimeBattleSetupException(
      'Les données de progression Pokémon locales sont invalides; combat impossible.',
      debugDetails:
          'speciesId=$expectedSpeciesId, file=$filePath, missing progression',
    );
  }
  final rawGrowthRateId = progression['growthRateId'];
  final growthRateId =
      rawGrowthRateId is String ? rawGrowthRateId.trim().toLowerCase() : '';
  final rawBaseExp = progression['baseExp'];
  final rawCatchRate = progression['catchRate'];
  final baseExp = rawBaseExp is int ? rawBaseExp : null;
  final catchRate = rawCatchRate is int ? rawCatchRate : null;
  if (!PokemonExperienceCurve.supportedIds.contains(growthRateId) ||
      baseExp == null ||
      baseExp <= 0 ||
      catchRate == null ||
      catchRate < 1 ||
      catchRate > 255) {
    throw RuntimeBattleSetupException(
      'Les données de progression Pokémon locales sont invalides; combat impossible.',
      debugDetails:
          'speciesId=$expectedSpeciesId, file=$filePath, progression requires a supported growthRateId, baseExp > 0 and catchRate within 1..255',
    );
  }

  return RuntimePokemonSpeciesProgression(
    growthRateId: growthRateId,
    baseExp: baseExp,
    catchRate: catchRate,
  );
}

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
  RuntimePokemonSpeciesLoader({
    this.snapshotMetrics = const RuntimePokemonSpeciesSnapshotMetrics(),
  });

  final RuntimePokemonSpeciesSnapshotMetrics snapshotMetrics;
  final Map<String, Future<_RuntimePokemonSpeciesSnapshot>> _cache =
      <String, Future<_RuntimePokemonSpeciesSnapshot>>{};
  int _actualReadCount = 0;

  int get debugActualReadCount => _actualReadCount;

  void invalidateProject(String projectRootDirectory) {
    final normalizedRoot = _normalizedProjectRoot(projectRootDirectory);
    _cache.removeWhere((key, _) => key.startsWith('$normalizedRoot|'));
  }

  Future<RuntimePokemonSpecies> loadById({
    required String projectRootDirectory,
    required ProjectPokemonConfig pokemonConfig,
    required String speciesId,
  }) async {
    if (!_isSafeSpeciesId(speciesId)) {
      throw RuntimeBattleSetupException(
        'Une espèce Pokémon invalide ne peut pas être mappée vers le combat.',
        debugDetails: 'Unsafe speciesId=$speciesId',
      );
    }
    final normalizedSpeciesId = speciesId;

    final speciesDirectoryPath = _resolveBoundedProjectDirectory(
      projectRootDirectory,
      _normalizeConfiguredRelativePath(
        pokemonConfig.speciesDir,
        fallback: 'data/pokemon/species',
      ),
    );
    final projectRoot = _normalizedProjectRoot(projectRootDirectory);
    final cacheKey = '$projectRoot|${p.normalize(speciesDirectoryPath)}';
    final snapshot = await _snapshot(
      cacheKey: cacheKey,
      projectRoot: projectRoot,
      speciesDirectoryPath: speciesDirectoryPath,
    );
    final indexed = snapshot.index.byId(normalizedSpeciesId);
    if (indexed == null) {
      throw RuntimePokemonSpeciesNotFoundException(speciesId);
    }
    if (snapshot.disabledSpeciesIds.contains(speciesId)) {
      throw RuntimePokemonSpeciesDisabledException(speciesId);
    }
    final species = snapshot.speciesById[indexed.id];
    final relativePath = snapshot.relativePathById[indexed.id];
    if (species == null || relativePath != indexed.relativePath) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails: 'Inconsistent species snapshot for id=${indexed.id}',
      );
    }
    return species;
  }

  Future<_RuntimePokemonSpeciesSnapshot> _snapshot({
    required String cacheKey,
    required String projectRoot,
    required String speciesDirectoryPath,
  }) async {
    final existing = _cache[cacheKey];
    if (existing != null) return existing;
    final pending = _buildSnapshot(
      projectRoot: projectRoot,
      speciesDirectoryPath: speciesDirectoryPath,
    );
    _cache[cacheKey] = pending;
    try {
      return await pending;
    } catch (_) {
      if (identical(_cache[cacheKey], pending)) {
        _cache.remove(cacheKey);
      }
      rethrow;
    }
  }

  Future<_RuntimePokemonSpeciesSnapshot> _buildSnapshot({
    required String projectRoot,
    required String speciesDirectoryPath,
  }) async {
    snapshotMetrics.onSnapshotBuildStarted(projectRoot, speciesDirectoryPath);
    final speciesDirectory = Directory(speciesDirectoryPath);
    if (!await speciesDirectory.exists()) {
      throw RuntimeBattleSetupException(
        'Impossible de charger les espèces Pokémon locales pour démarrer le combat.',
        debugDetails: 'Missing species directory: ${speciesDirectory.path}',
      );
    }
    snapshotMetrics.onSpeciesDirectoryListed(projectRoot, speciesDirectoryPath);
    final files = <File>[];
    await for (final entity in speciesDirectory.list(recursive: false)) {
      if (entity is File && p.extension(entity.path).toLowerCase() == '.json') {
        files.add(entity);
      }
    }
    files.sort((left, right) => left.path.compareTo(right.path));

    final entries = <PokemonSpeciesIndexEntry>[];
    final speciesById = <String, RuntimePokemonSpecies>{};
    final relativePathById = <String, String>{};
    final disabledSpeciesIds = <String>{};
    for (final file in files) {
      snapshotMetrics.onSpeciesJsonRead(projectRoot, file.path);
      _actualReadCount += 1;
      final rawJson = await _readJsonFile(
        file,
        label: 'Pokemon species file',
      );
      final rawSpeciesId = rawJson['id'];
      final speciesId = rawSpeciesId is String ? rawSpeciesId.trim() : '';
      if (!_isSafeSpeciesId(speciesId)) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'Unsafe declared speciesId=$speciesId, file=${file.path}',
        );
      }
      final relativePath =
          p.normalize(p.relative(file.path, from: projectRoot));
      final previousPath = relativePathById[speciesId];
      if (previousPath != null) {
        throw RuntimeBattleSetupException(
          'Plusieurs espèces Pokémon locales déclarent le même id; combat impossible.',
          debugDetails:
              'speciesId=$speciesId, firstFile=$previousPath, duplicateFile=$relativePath',
        );
      }
      final parsed = _parseRuntimeSpecies(
        rawJson,
        expectedSpeciesId: speciesId,
        filePath: file.path,
      );
      entries.add(
        PokemonSpeciesIndexEntry.fromSpeciesFile(
          parsed.speciesFile,
          relativePath: relativePath,
        ),
      );
      speciesById[speciesId] = parsed.runtimeSpecies;
      if (!parsed.speciesFile.classification.isEnabledInProject) {
        disabledSpeciesIds.add(speciesId);
      }
      relativePathById[speciesId] = relativePath;
    }

    try {
      return _RuntimePokemonSpeciesSnapshot(
        index: PokemonSpeciesIndex(entries),
        speciesById: speciesById,
        relativePathById: relativePathById,
        disabledSpeciesIds: disabledSpeciesIds,
      );
    } on StateError catch (error) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails: 'Invalid species index: $error',
      );
    }
  }

  PokemonSpeciesFile _parseSharedSpeciesFile(
    Map<String, dynamic> rawJson, {
    required String filePath,
  }) {
    try {
      return PokemonSpeciesFile.fromJson(rawJson);
    } on UnsupportedPokemonDataSchema catch (error) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont incompatibles; combat impossible.',
        debugDetails:
            'file=$filePath, schemaVersion=${error.actualVersion}, expected=$currentPokemonDataSchemaVersion',
      );
    } catch (error) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails: 'file=$filePath, shared species codec failed: $error',
      );
    }
  }

  ({
    PokemonSpeciesFile speciesFile,
    RuntimePokemonSpecies runtimeSpecies,
  }) _parseRuntimeSpecies(
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

    final abilities = _readRequiredAbilities(
      rawJson['abilities'],
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final typing = _readRequiredTyping(
      rawJson,
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final progression = parseRuntimePokemonSpeciesProgression(
      rawJson,
      expectedSpeciesId: expectedSpeciesId,
      filePath: filePath,
    );
    final speciesFile = _parseSharedSpeciesFile(rawJson, filePath: filePath);
    final runtimeSpecies = RuntimePokemonSpecies(
      id: expectedSpeciesId,
      names: Map<String, String>.unmodifiable(speciesFile.names),
      formId: speciesFile.forms.formId,
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
      genderRatio: Map<String, double>.unmodifiable(
        speciesFile.breeding.genderRatio,
      ),
      primaryAbilityId: abilities.primary,
      standardAbilityIds: List<String>.unmodifiable(<String>[
        speciesFile.abilities.primary,
        if (speciesFile.abilities.secondary case final secondary?) secondary,
      ]),
      abilityIds: abilities.all,
      // `learnsetRef` peut rester vide : le loader learnset conservera le
      // fallback historique vers l'id de l'espèce.
      learnsetRef: speciesFile.learnsetRef,
      growthRateId: progression.growthRateId,
      baseExp: progression.baseExp,
      catchRate: progression.catchRate,
      baseFriendship: speciesFile.progression.baseFriendship,
    );
    return (speciesFile: speciesFile, runtimeSpecies: runtimeSpecies);
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

  ({String primary, List<String> all}) _readRequiredAbilities(
    Object? rawAbilities, {
    required String expectedSpeciesId,
    required String filePath,
  }) {
    if (rawAbilities is! Map) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, abilities must be a JSON object',
      );
    }
    final abilities = rawAbilities.cast<String, dynamic>();
    final rawPrimary = abilities['primary'];
    final primary = rawPrimary is String ? rawPrimary.trim() : '';
    if (primary.isEmpty) {
      throw RuntimeBattleSetupException(
        'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
        debugDetails:
            'speciesId=$expectedSpeciesId, file=$filePath, abilities.primary must be a non-empty string',
      );
    }

    final all = <String>[primary];
    for (final key in const <String>['secondary', 'hidden']) {
      final rawAbilityId = abilities[key];
      if (rawAbilityId == null) continue;
      if (rawAbilityId is! String || rawAbilityId.trim().isEmpty) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'speciesId=$expectedSpeciesId, file=$filePath, abilities.$key must be null or a non-empty string',
        );
      }
      final abilityId = rawAbilityId.trim();
      if (all.contains(abilityId)) {
        throw RuntimeBattleSetupException(
          'Les données d’espèce Pokémon locales sont invalides; combat impossible.',
          debugDetails:
              'speciesId=$expectedSpeciesId, file=$filePath, abilities contains duplicate id=$abilityId',
        );
      }
      all.add(abilityId);
    }
    return (primary: primary, all: List<String>.unmodifiable(all));
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

  String _resolveBoundedProjectDirectory(
    String projectRootDirectory,
    String relativePath,
  ) {
    final root = p.normalize(p.absolute(projectRootDirectory));
    if (p.isAbsolute(relativePath)) {
      throw RuntimeBattleSetupException(
        'Le dossier des espèces Pokémon doit appartenir au projet.',
        debugDetails: 'Absolute speciesDir is forbidden: $relativePath',
      );
    }
    final directory = p.normalize(p.join(root, relativePath));
    if (directory != root && !p.isWithin(root, directory)) {
      throw RuntimeBattleSetupException(
        'Le dossier des espèces Pokémon doit appartenir au projet.',
        debugDetails: 'speciesDir escapes project root: $relativePath',
      );
    }
    return directory;
  }

  String _normalizedProjectRoot(String projectRootDirectory) {
    final normalized = p.normalize(p.absolute(projectRootDirectory));
    try {
      return p.normalize(Directory(normalized).resolveSymbolicLinksSync());
    } on FileSystemException {
      return normalized;
    }
  }

  bool _isSafeSpeciesId(String speciesId) {
    return speciesId.isNotEmpty &&
        speciesId == speciesId.trim() &&
        speciesId != '.' &&
        speciesId != '..' &&
        !p.isAbsolute(speciesId) &&
        p.basename(speciesId) == speciesId &&
        !speciesId.contains('/') &&
        !speciesId.contains(r'\');
  }
}

final class _RuntimePokemonSpeciesSnapshot {
  _RuntimePokemonSpeciesSnapshot({
    required this.index,
    required Map<String, RuntimePokemonSpecies> speciesById,
    required Map<String, String> relativePathById,
    required Set<String> disabledSpeciesIds,
  })  : speciesById = Map<String, RuntimePokemonSpecies>.unmodifiable(
          speciesById,
        ),
        relativePathById = Map<String, String>.unmodifiable(relativePathById),
        disabledSpeciesIds = Set.unmodifiable(disabledSpeciesIds);

  final PokemonSpeciesIndex index;
  final Map<String, RuntimePokemonSpecies> speciesById;
  final Map<String, String> relativePathById;
  final Set<String> disabledSpeciesIds;
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
    this.names = const <String, String>{},
    this.formId = '',
    required this.typing,
    required this.baseHp,
    required this.baseAttack,
    required this.baseDefense,
    required this.baseSpecialAttack,
    required this.baseSpecialDefense,
    required this.baseSpeed,
    this.maleGenderRatio,
    this.femaleGenderRatio,
    this.genderRatio = const <String, double>{},
    required this.primaryAbilityId,
    this.standardAbilityIds = const <String>[],
    required this.abilityIds,
    required this.learnsetRef,
    required this.growthRateId,
    required this.baseExp,
    required this.catchRate,
    this.baseFriendship = 0,
  });

  final String id;
  final Map<String, String> names;
  final String formId;

  String displayName(String locale) => resolveLocalizedName(
        names: names,
        locale: locale,
        fallback: id,
      );

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
  final Map<String, double> genderRatio;
  final String primaryAbilityId;
  final List<String> standardAbilityIds;
  final List<String> abilityIds;
  final String learnsetRef;
  final String growthRateId;
  final int baseExp;
  final int catchRate;
  final int baseFriendship;
}
