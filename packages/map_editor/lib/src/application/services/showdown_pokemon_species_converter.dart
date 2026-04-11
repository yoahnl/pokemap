import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit un payload Showdown représentatif vers [PokemonSpeciesFile].
///
/// Cette fondation couvre uniquement les lots 29 et 30 :
/// - espèce core ;
/// - formes simples ;
/// - classification simple ;
/// - refs internes minimales cohérentes avec le storage local actuel.
///
/// Non-objectifs assumés :
/// - pas de réseau ;
/// - pas d'écriture locale ;
/// - pas de validation croisée riche ;
/// - pas de modélisation exhaustive de toutes les subtilités Showdown.
class ShowdownPokemonSpeciesConverter {
  const ShowdownPokemonSpeciesConverter();

  PokemonSpeciesFile convert(Map<String, dynamic> payload) {
    final id = _resolveSpeciesId(payload);
    if (id.isEmpty) {
      throw const EditorValidationException(
        'Showdown species id cannot be empty',
      );
    }

    final displayName = _readPrimaryDisplayName(payload);
    if (displayName.isEmpty) {
      throw const EditorValidationException(
        'Showdown species name cannot be empty',
      );
    }

    final nationalDex = _readRequiredInt(payload['num'], field: 'num');
    final genIntroduced = _readRequiredInt(payload['gen'], field: 'gen');
    final types = _readRequiredStringList(payload['types'], field: 'types')
        .map(_normalizeCatalogId)
        .toList(growable: false);
    final stats = _readRequiredMap(payload['baseStats'], field: 'baseStats');
    final abilities =
        _readRequiredMap(payload['abilities'], field: 'abilities');

    final hp = _readRequiredInt(stats['hp'], field: 'baseStats.hp');
    final atk = _readRequiredInt(stats['atk'], field: 'baseStats.atk');
    final def = _readRequiredInt(stats['def'], field: 'baseStats.def');
    final spa = _readRequiredInt(stats['spa'], field: 'baseStats.spa');
    final spd = _readRequiredInt(stats['spd'], field: 'baseStats.spd');
    final spe = _readRequiredInt(stats['spe'], field: 'baseStats.spe');

    final primaryAbility = _normalizeCatalogId(
      _readRequiredTrimmedString(abilities['0'], field: 'abilities.0'),
    );
    final secondaryAbility = _normalizeOptionalCatalogId(abilities['1']);
    final hiddenAbility = _normalizeOptionalCatalogId(abilities['H']);

    final names = _readStringMap(payload['names']);
    final resolvedNames =
        names.isEmpty ? <String, String>{'en': displayName} : names;

    final speciesName = _readSpeciesNameMap(payload);
    final genderRatio = _readGenderRatio(payload);
    final eggGroups = _readOptionalStringList(payload['eggGroups'])
        .map(_normalizeCatalogId)
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    final growthRateId = _normalizeCatalogId(
      _readOptionalTrimmedString(payload['expType']) ?? '',
    );

    final forms = _readForms(payload, currentId: id);
    final classification = _readClassification(payload);

    return PokemonSpeciesFile(
      id: id,
      slug: id,
      nationalDex: nationalDex,
      names: resolvedNames,
      // Showdown n'expose pas toujours la "species category" au sens Pokédex.
      // On ne l'invente donc pas : on remplit seulement si une valeur explicite
      // est déjà présente dans le payload de test.
      speciesName: speciesName,
      genIntroduced: genIntroduced,
      typing: PokemonSpeciesTyping(types: types),
      baseStats: PokemonSpeciesBaseStats(
        hp: hp,
        atk: atk,
        def: def,
        spa: spa,
        spd: spd,
        spe: spe,
        bst: hp + atk + def + spa + spd + spe,
      ),
      abilities: PokemonSpeciesAbilities(
        primary: primaryAbility,
        secondary: secondaryAbility,
        hidden: hiddenAbility,
      ),
      breeding: PokemonSpeciesBreeding(
        genderRatio: genderRatio,
        eggGroups: eggGroups,
        hatchCycles: _readOptionalInt(payload['hatchTime']) ?? 0,
      ),
      progression: PokemonSpeciesProgression(
        growthRateId: growthRateId,
        baseExp: _readOptionalInt(payload['baseExp']) ?? 0,
        catchRate: _readOptionalInt(payload['catchRate']) ?? 0,
        baseFriendship: _readOptionalInt(payload['baseFriendship']) ?? 0,
      ),
      forms: forms,
      classification: classification,
      refs: PokemonSpeciesRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      dexContent: PokemonSpeciesDexContent(
        heightM: _readOptionalDouble(payload['heightm']),
        weightKg: _readOptionalDouble(payload['weightkg']),
        color: _readOptionalTrimmedString(payload['color']),
        flavorText: _readOptionalTrimmedString(payload['flavorText']),
      ),
      gameplayFlags: const PokemonSpeciesGameplayFlags(),
      sourceMeta: const PokemonSpeciesSourceMeta(
        seededBy: 'showdown',
      ),
    );
  }

  String _resolveSpeciesId(Map<String, dynamic> payload) {
    final directId = _readOptionalTrimmedString(payload['id']);
    if (directId != null && directId.isNotEmpty) {
      return _normalizeIdentifier(directId);
    }

    final name = _readOptionalTrimmedString(payload['name']);
    if (name != null && name.isNotEmpty) {
      return _normalizeIdentifier(name);
    }

    final species = _readOptionalTrimmedString(payload['species']);
    if (species != null && species.isNotEmpty) {
      return _normalizeIdentifier(species);
    }

    return '';
  }

  String _readPrimaryDisplayName(Map<String, dynamic> payload) {
    return _readOptionalTrimmedString(payload['name']) ??
        _readOptionalTrimmedString(payload['species']) ??
        _readOptionalTrimmedString(payload['baseSpecies']) ??
        '';
  }

  Map<String, String> _readSpeciesNameMap(Map<String, dynamic> payload) {
    final names = _readStringMap(payload['speciesName']);
    if (names.isNotEmpty) {
      return names;
    }

    final category = _readOptionalTrimmedString(payload['category']);
    if (category == null || category.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{'en': category};
  }

  Map<String, double> _readGenderRatio(Map<String, dynamic> payload) {
    final rawRatio = payload['genderRatio'];
    if (rawRatio is Map) {
      final ratio = <String, double>{};
      for (final entry in rawRatio.entries) {
        final key = entry.key;
        final value = entry.value;
        if (key is! String || value is! num) {
          throw const EditorPersistenceException(
            'Showdown genderRatio entries must be string-number pairs',
          );
        }
        final mappedKey = switch (key.trim()) {
          'M' => 'male',
          'F' => 'female',
          'N' => 'genderless',
          _ => key.trim().toLowerCase(),
        };
        if (mappedKey.isNotEmpty) {
          ratio[mappedKey] = value.toDouble();
        }
      }
      return ratio;
    }

    final gender = _readOptionalTrimmedString(payload['gender']);
    if (gender == 'N') {
      return const <String, double>{'genderless': 1.0};
    }

    return const <String, double>{};
  }

  PokemonSpeciesForms _readForms(
    Map<String, dynamic> payload, {
    required String currentId,
  }) {
    final baseSpecies = _readOptionalTrimmedString(payload['baseSpecies']);
    final forme = _readOptionalTrimmedString(payload['forme']);
    final baseSpeciesId =
        baseSpecies == null ? '' : _normalizeIdentifier(baseSpecies);
    final isBaseForm =
        baseSpeciesId.isEmpty || baseSpeciesId == currentId || forme == null;

    // Les autres formes n'ont pas d'ordre métier exploité dans le projet.
    // On les trie donc pour garantir une sortie stable, sans dépendre de
    // l'ordre exact du payload Showdown.
    final otherForms = <String>[
      ..._readOptionalStringList(payload['otherFormes']),
      ..._readOptionalStringList(payload['cosmeticFormes']),
    ].map(_normalizeIdentifier).where((value) => value.isNotEmpty).toSet()
      ..remove('');
    final sortedOtherForms = otherForms.toList(growable: false)..sort();

    return PokemonSpeciesForms(
      baseFormId: isBaseForm ? '' : baseSpeciesId,
      isBaseForm: isBaseForm,
      formId: isBaseForm ? '' : _normalizeIdentifier(forme),
      formName: isBaseForm ? null : forme,
      otherForms: sortedOtherForms,
    );
  }

  PokemonSpeciesClassification _readClassification(
    Map<String, dynamic> payload,
  ) {
    final tags = _readOptionalStringList(payload['tags'])
        .map((value) => value.trim().toLowerCase())
        .toSet();
    final isNonstandard = _readOptionalTrimmedString(payload['isNonstandard']);

    return PokemonSpeciesClassification(
      isEnabledInProject: true,
      isObtainable: isNonstandard != 'Unobtainable',
      isLegendary: _readOptionalBool(payload['isLegendary']) ||
          tags.contains('legendary'),
      isMythical:
          _readOptionalBool(payload['isMythical']) || tags.contains('mythical'),
      isBaby: _readOptionalBool(payload['isBaby']) || tags.contains('baby'),
    );
  }

  Map<String, dynamic> _readRequiredMap(
    Object? raw, {
    required String field,
  }) {
    if (raw is! Map) {
      throw EditorPersistenceException(
        'Showdown species field "$field" must be an object',
      );
    }
    return raw.cast<String, dynamic>();
  }

  List<String> _readRequiredStringList(
    Object? raw, {
    required String field,
  }) {
    final values = _readOptionalStringList(raw);
    if (values.isEmpty) {
      throw EditorValidationException(
        'Showdown species field "$field" cannot be empty',
      );
    }
    return values;
  }

  List<String> _readOptionalStringList(Object? raw) {
    if (raw == null) return const <String>[];
    if (raw is! List) {
      throw const EditorPersistenceException(
        'Showdown species expected a string list field',
      );
    }

    return raw
        .map((value) => _readOptionalTrimmedString(value) ?? '')
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
  }

  Map<String, String> _readStringMap(Object? raw) {
    if (raw == null) return const <String, String>{};
    if (raw is! Map) {
      throw const EditorPersistenceException(
        'Showdown species expected a string map field',
      );
    }

    final result = <String, String>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      final value = entry.value;
      if (key is String && value is String) {
        final trimmedKey = key.trim();
        final trimmedValue = value.trim();
        if (trimmedKey.isNotEmpty && trimmedValue.isNotEmpty) {
          result[trimmedKey] = trimmedValue;
        }
      }
    }
    return result;
  }

  int _readRequiredInt(
    Object? raw, {
    required String field,
  }) {
    final value = _readOptionalInt(raw);
    if (value == null) {
      throw EditorPersistenceException(
        'Showdown species field "$field" must be an integer',
      );
    }
    return value;
  }

  int? _readOptionalInt(Object? raw) {
    return (raw as num?)?.toInt();
  }

  double? _readOptionalDouble(Object? raw) {
    return (raw as num?)?.toDouble();
  }

  bool _readOptionalBool(Object? raw) {
    return raw == true;
  }

  String _readRequiredTrimmedString(
    Object? raw, {
    required String field,
  }) {
    final value = _readOptionalTrimmedString(raw);
    if (value == null || value.isEmpty) {
      throw EditorValidationException(
        'Showdown species field "$field" cannot be empty',
      );
    }
    return value;
  }

  String? _readOptionalTrimmedString(Object? raw) {
    final value = raw as String?;
    if (value == null) return null;
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String _normalizeIdentifier(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]+'), '');
  }

  // Les ids de référentiels internes du projet suivent majoritairement une
  // convention canonique lowercase + snake_case :
  // - types: grass
  // - abilities: overgrow
  // - egg groups: monster, water_1
  // - growth rates: medium_slow
  // On l'applique ici uniquement aux champs clairement "catalog-like",
  // sans toucher arbitrairement aux species ids ni aux form ids.
  String _normalizeCatalogId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final separated = trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }

  String? _normalizeOptionalCatalogId(Object? raw) {
    final value = _readOptionalTrimmedString(raw);
    if (value == null || value.isEmpty) {
      return null;
    }
    final normalized = _normalizeCatalogId(value);
    return normalized.isEmpty ? null : normalized;
  }
}
