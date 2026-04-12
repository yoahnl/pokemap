import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Enrichit une espèce locale à partir du payload PokeAPI `pokemon-species`.
///
/// Le converter Showdown reste la source structurée pour le core species :
/// stats, abilities, formes, types et ids robustes.
/// Cet enricher complète ensuite ce socle avec les informations encyclopédiques
/// et localisées venant de PokeAPI :
/// - noms localisés ;
/// - génération ;
/// - flavor text ;
/// - egg groups ;
/// - growth rate ;
/// - catch rate ;
/// - base friendship ;
/// - flags baby / legendary / mythical ;
/// - couleur Pokédex.
///
/// Important :
/// - on n'introduit pas un nouveau modèle métier ;
/// - on ne remplace pas Showdown comme source complémentaire ;
/// - on se contente de produire une version enrichie du `PokemonSpeciesFile`
///   déjà existant.
class PokeApiPokemonSpeciesEnricher {
  const PokeApiPokemonSpeciesEnricher();

  PokemonSpeciesFile enrich({
    required PokemonSpeciesFile species,
    required Map<String, dynamic> pokemonSpeciesPayload,
    Map<String, dynamic>? pokemonPayload,
  }) {
    final canonicalId =
        _readOptionalTrimmedString(pokemonSpeciesPayload['name']);
    if (canonicalId == null || canonicalId.isEmpty) {
      throw const EditorPersistenceException(
        'PokeAPI pokemon-species payload must contain a non-empty name',
      );
    }

    final normalizedCanonicalId = _normalizeCatalogId(canonicalId);
    if (normalizedCanonicalId != species.id) {
      throw EditorValidationException(
        'PokeAPI pokemon-species payload resolved to "$normalizedCanonicalId" '
        'but Showdown species resolved to "${species.id}"',
      );
    }

    final localizedNames = _readLocalizedValues(
      pokemonSpeciesPayload['names'],
      field: 'pokemon-species.names',
    );
    final localizedSpeciesNames = _readLocalizedValues(
      pokemonSpeciesPayload['genera'],
      field: 'pokemon-species.genera',
      valueField: 'genus',
    );

    final generationId = _readNamedResourceId(
      pokemonSpeciesPayload['generation'],
      field: 'pokemon-species.generation',
    );
    final generationNumber = _parseGenerationNumber(generationId);

    final eggGroups = _readNamedResourceIdList(
      pokemonSpeciesPayload['egg_groups'],
      field: 'pokemon-species.egg_groups',
    );
    final growthRateId = _readNamedResourceId(
      pokemonSpeciesPayload['growth_rate'],
      field: 'pokemon-species.growth_rate',
    );
    final colorId = _readNamedResourceId(
      pokemonSpeciesPayload['color'],
      field: 'pokemon-species.color',
    );
    final flavorText =
        _readFlavorText(pokemonSpeciesPayload['flavor_text_entries']);

    final baseExp = _readOptionalInt(pokemonPayload?['base_experience']) ??
        species.progression.baseExp;
    final heightM =
        _readOptionalMetricValue(pokemonPayload?['height'], factor: 10) ??
            species.dexContent.heightM;
    final weightKg =
        _readOptionalMetricValue(pokemonPayload?['weight'], factor: 10) ??
            species.dexContent.weightKg;

    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: localizedNames.isEmpty ? species.names : localizedNames,
      speciesName: localizedSpeciesNames.isEmpty
          ? species.speciesName
          : localizedSpeciesNames,
      genIntroduced: generationNumber ?? species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: PokemonSpeciesBreeding(
        genderRatio: species.breeding.genderRatio,
        eggGroups: eggGroups.isEmpty ? species.breeding.eggGroups : eggGroups,
        hatchCycles: species.breeding.hatchCycles,
      ),
      progression: PokemonSpeciesProgression(
        growthRateId: growthRateId.isEmpty
            ? species.progression.growthRateId
            : growthRateId,
        baseExp: baseExp,
        catchRate: _readOptionalInt(pokemonSpeciesPayload['capture_rate']) ??
            species.progression.catchRate,
        baseFriendship:
            _readOptionalInt(pokemonSpeciesPayload['base_happiness']) ??
                species.progression.baseFriendship,
      ),
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: species.classification.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: _readBool(pokemonSpeciesPayload['is_legendary']) ||
            species.classification.isLegendary,
        isMythical: _readBool(pokemonSpeciesPayload['is_mythical']) ||
            species.classification.isMythical,
        isBaby: _readBool(pokemonSpeciesPayload['is_baby']) ||
            species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: heightM,
        weightKg: weightKg,
        color: colorId.isEmpty ? species.dexContent.color : colorId,
        flavorText: flavorText ?? species.dexContent.flavorText,
      ),
      gameplayFlags: species.gameplayFlags,
      sourceMeta: PokemonSpeciesSourceMeta(
        seededBy: 'external_api',
        seedVersion: species.sourceMeta.seedVersion,
      ),
    );
  }

  Map<String, String> _readLocalizedValues(
    Object? raw, {
    required String field,
    String valueField = 'name',
  }) {
    if (raw == null) {
      return const <String, String>{};
    }
    if (raw is! List) {
      throw EditorPersistenceException('$field must be a list');
    }

    final values = <String, String>{};
    for (var index = 0; index < raw.length; index++) {
      final entry = raw[index];
      if (entry is! Map) {
        throw EditorPersistenceException('$field[$index] must be an object');
      }

      final normalizedEntry = entry.cast<String, dynamic>();
      final value = _readOptionalTrimmedString(normalizedEntry[valueField]);
      if (value == null || value.isEmpty) {
        continue;
      }
      final languageId = _readNamedResourceId(
        normalizedEntry['language'],
        field: '$field[$index].language',
      );
      if (languageId.isEmpty) {
        continue;
      }
      values[languageId] = _normalizeWhitespace(value);
    }

    return values;
  }

  String? _readFlavorText(Object? raw) {
    if (raw == null) {
      return null;
    }
    if (raw is! List) {
      throw const EditorPersistenceException(
        'pokemon-species.flavor_text_entries must be a list',
      );
    }

    String? fallback;
    for (final preferredLanguage in const <String>['en', 'fr']) {
      for (var index = 0; index < raw.length; index++) {
        final entry = raw[index];
        if (entry is! Map) {
          throw EditorPersistenceException(
            'pokemon-species.flavor_text_entries[$index] must be an object',
          );
        }
        final normalizedEntry = entry.cast<String, dynamic>();
        final languageId = _readNamedResourceId(
          normalizedEntry['language'],
          field: 'pokemon-species.flavor_text_entries[$index].language',
        );
        final flavorText =
            _readOptionalTrimmedString(normalizedEntry['flavor_text']);
        if (flavorText == null || flavorText.isEmpty) {
          continue;
        }
        fallback ??= _normalizeWhitespace(flavorText);
        if (languageId == preferredLanguage) {
          return _normalizeWhitespace(flavorText);
        }
      }
    }

    return fallback;
  }

  List<String> _readNamedResourceIdList(
    Object? raw, {
    required String field,
  }) {
    if (raw == null) {
      return const <String>[];
    }
    if (raw is! List) {
      throw EditorPersistenceException('$field must be a list');
    }

    final values = <String>{};
    for (var index = 0; index < raw.length; index++) {
      values.add(
        _readNamedResourceId(
          raw[index],
          field: '$field[$index]',
        ),
      );
    }
    return values.where((value) => value.isNotEmpty).toList(growable: false);
  }

  String _readNamedResourceId(
    Object? raw, {
    required String field,
  }) {
    if (raw is! Map) {
      throw EditorPersistenceException('$field must be an object');
    }
    final name = _readOptionalTrimmedString(raw['name']);
    if (name == null || name.isEmpty) {
      throw EditorPersistenceException('$field.name cannot be empty');
    }
    return _normalizeCatalogId(name);
  }

  int? _parseGenerationNumber(String generationId) {
    const generationMap = <String, int>{
      'generation-i': 1,
      'generation-ii': 2,
      'generation-iii': 3,
      'generation-iv': 4,
      'generation-v': 5,
      'generation-vi': 6,
      'generation-vii': 7,
      'generation-viii': 8,
      'generation-ix': 9,
    };
    return generationMap[generationId];
  }

  double? _readOptionalMetricValue(
    Object? raw, {
    required double factor,
  }) {
    final value = _readOptionalInt(raw);
    if (value == null) {
      return null;
    }
    return value / factor;
  }

  int? _readOptionalInt(Object? raw) {
    return (raw as num?)?.toInt();
  }

  bool _readBool(Object? raw) {
    return raw == true;
  }

  String _normalizeCatalogId(String raw) {
    return raw.trim().toLowerCase().replaceAll(' ', '_').replaceAll('-', '_');
  }

  String? _readOptionalTrimmedString(Object? raw) {
    final value = raw as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  String _normalizeWhitespace(String value) {
    return value
        .replaceAll('\n', ' ')
        .replaceAll('\f', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
