const currentPokemonDataSchemaVersion = 1;

final class UnsupportedPokemonDataSchema extends FormatException {
  UnsupportedPokemonDataSchema({
    required this.actualVersion,
    required this.path,
  }) : super(
         'Unsupported Pokemon data schema at $path: '
         '$actualVersion (expected $currentPokemonDataSchemaVersion)',
       );

  final Object? actualVersion;
  final String path;
}

class PokemonDataMeta {
  const PokemonDataMeta({
    required this.description,
    this.sourcePriority = const <String>[],
    this.notes = const <String>[],
  });

  final String description;
  final List<String> sourcePriority;
  final List<String> notes;

  factory PokemonDataMeta.fromJson(Map<String, dynamic> json) =>
      PokemonDataMeta(
        description: (json['description'] as String?)?.trim() ?? '',
        sourcePriority: _readStringList(json['sourcePriority']),
        notes: _readStringList(json['notes']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'description': description,
    'sourcePriority': List<String>.from(sourcePriority),
    'notes': List<String>.from(notes),
  };
}

class PokemonDataManifest {
  const PokemonDataManifest({
    required this.schemaVersion,
    required this.kind,
    required this.meta,
    required this.catalogFiles,
    required this.futureDataFolders,
  });

  final int schemaVersion;
  final String kind;
  final PokemonDataMeta meta;
  final Map<String, String> catalogFiles;
  final Map<String, String> futureDataFolders;

  factory PokemonDataManifest.fromJson(Map<String, dynamic> json) =>
      PokemonDataManifest(
        schemaVersion: _readPokemonDataSchemaVersion(json),
        kind: (json['kind'] as String?)?.trim() ?? '',
        meta: PokemonDataMeta.fromJson(
          (json['meta'] as Map?)?.cast<String, dynamic>() ??
              const <String, dynamic>{},
        ),
        catalogFiles: _readStringMap(json['catalogFiles']),
        futureDataFolders: _readStringMap(json['futureDataFolders']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'kind': kind,
    'meta': meta.toJson(),
    'catalogFiles': Map<String, String>.from(catalogFiles),
    'futureDataFolders': Map<String, String>.from(futureDataFolders),
  };
}

class PokemonCatalogFile {
  const PokemonCatalogFile({
    required this.schemaVersion,
    required this.kind,
    required this.catalog,
    required this.meta,
    required this.entries,
  });

  final int schemaVersion;
  final String kind;
  final String catalog;
  final PokemonDataMeta meta;
  final List<Map<String, dynamic>> entries;

  factory PokemonCatalogFile.fromJson(Map<String, dynamic> json) {
    final rawEntries = (json['entries'] as List?) ?? const <Object?>[];
    return PokemonCatalogFile(
      schemaVersion: _readPokemonDataSchemaVersion(json),
      kind: (json['kind'] as String?)?.trim() ?? '',
      catalog: (json['catalog'] as String?)?.trim() ?? '',
      meta: PokemonDataMeta.fromJson(
        (json['meta'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      entries: rawEntries
          .whereType<Map>()
          .map((entry) => entry.cast<String, dynamic>())
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'kind': kind,
    'catalog': catalog,
    'meta': meta.toJson(),
    'entries': entries
        .map((entry) => _deepCopyJsonMap(entry))
        .toList(growable: false),
  };
}

class PokemonSpeciesIndexEntry {
  const PokemonSpeciesIndexEntry({
    required this.id,
    required this.nationalDex,
    required this.primaryName,
    required this.types,
    required this.relativePath,
  });

  final String id;
  final int nationalDex;
  final String primaryName;
  final List<String> types;
  final String relativePath;

  factory PokemonSpeciesIndexEntry.fromJson(
    Map<String, dynamic> json, {
    required String relativePath,
  }) {
    final names = _readStringMap(json['names']);
    return PokemonSpeciesIndexEntry(
      id: (json['id'] as String?)?.trim() ?? '',
      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
      primaryName:
          _pickPrimaryName(names) ?? (json['id'] as String?)?.trim() ?? '',
      types: PokemonSpeciesTyping.fromJson(
        (json['typing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ).types,
      relativePath: relativePath,
    );
  }

  factory PokemonSpeciesIndexEntry.fromSpeciesFile(
    PokemonSpeciesFile species, {
    required String relativePath,
  }) => PokemonSpeciesIndexEntry(
    id: species.id.trim(),
    nationalDex: species.nationalDex,
    primaryName: _pickPrimaryName(species.names) ?? species.id.trim(),
    types: List<String>.from(species.typing.types),
    relativePath: relativePath,
  );
}

class PokemonSpeciesIndex {
  PokemonSpeciesIndex(Iterable<PokemonSpeciesIndexEntry> values) {
    final indexed = <String, PokemonSpeciesIndexEntry>{};
    for (final entry in values) {
      final id = entry.id.trim();
      if (id.isEmpty) {
        throw StateError('Pokemon species index id must not be empty');
      }
      if (indexed.containsKey(id)) {
        throw StateError('Duplicate Pokemon species index id: $id');
      }
      indexed[id] = entry;
    }
    final sorted = indexed.values.toList(growable: false)
      ..sort((left, right) {
        final nationalDex = left.nationalDex.compareTo(right.nationalDex);
        return nationalDex != 0 ? nationalDex : left.id.compareTo(right.id);
      });
    entries = List<PokemonSpeciesIndexEntry>.unmodifiable(sorted);
    _entriesById = Map<String, PokemonSpeciesIndexEntry>.unmodifiable(indexed);
  }

  late final List<PokemonSpeciesIndexEntry> entries;
  late final Map<String, PokemonSpeciesIndexEntry> _entriesById;

  PokemonSpeciesIndexEntry? byId(String id) => _entriesById[id.trim()];
}

class PokemonSpeciesTyping {
  const PokemonSpeciesTyping({this.types = const <String>[]});

  final List<String> types;

  factory PokemonSpeciesTyping.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesTyping(types: _readStringList(json['types']));

  Map<String, Object?> toJson() => <String, Object?>{
    'types': List<String>.from(types),
  };
}

class PokemonSpeciesBaseStats {
  const PokemonSpeciesBaseStats({
    required this.hp,
    required this.atk,
    required this.def,
    required this.spa,
    required this.spd,
    required this.spe,
    required this.bst,
  });

  final int hp;
  final int atk;
  final int def;
  final int spa;
  final int spd;
  final int spe;
  final int bst;

  factory PokemonSpeciesBaseStats.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesBaseStats(
        hp: (json['hp'] as num?)?.toInt() ?? 0,
        atk: (json['atk'] as num?)?.toInt() ?? 0,
        def: (json['def'] as num?)?.toInt() ?? 0,
        spa: (json['spa'] as num?)?.toInt() ?? 0,
        spd: (json['spd'] as num?)?.toInt() ?? 0,
        spe: (json['spe'] as num?)?.toInt() ?? 0,
        bst: (json['bst'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'hp': hp,
    'atk': atk,
    'def': def,
    'spa': spa,
    'spd': spd,
    'spe': spe,
    'bst': bst,
  };
}

class PokemonSpeciesAbilities {
  const PokemonSpeciesAbilities({
    required this.primary,
    this.secondary,
    this.hidden,
  });

  final String primary;
  final String? secondary;
  final String? hidden;

  factory PokemonSpeciesAbilities.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesAbilities(
        primary: (json['primary'] as String?)?.trim() ?? '',
        secondary: _readOptionalTrimmedString(json['secondary']),
        hidden: _readOptionalTrimmedString(json['hidden']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'primary': primary,
    'secondary': secondary,
    'hidden': hidden,
  };
}

class PokemonSpeciesBreeding {
  const PokemonSpeciesBreeding({
    required this.genderRatio,
    this.eggGroups = const <String>[],
    this.hatchCycles = 0,
  });

  final Map<String, double> genderRatio;
  final List<String> eggGroups;
  final int hatchCycles;

  factory PokemonSpeciesBreeding.fromJson(Map<String, dynamic> json) {
    final rawGenderRatio =
        (json['genderRatio'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return PokemonSpeciesBreeding(
      genderRatio: rawGenderRatio.map(
        (key, value) => MapEntry(key, (value as num).toDouble()),
      ),
      eggGroups: _readStringList(json['eggGroups']),
      hatchCycles: (json['hatchCycles'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'genderRatio': Map<String, double>.from(genderRatio),
    'eggGroups': List<String>.from(eggGroups),
    'hatchCycles': hatchCycles,
  };
}

class PokemonSpeciesProgression {
  const PokemonSpeciesProgression({
    required this.growthRateId,
    required this.baseExp,
    required this.catchRate,
    required this.baseFriendship,
  });

  final String growthRateId;
  final int baseExp;
  final int catchRate;
  final int baseFriendship;

  factory PokemonSpeciesProgression.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesProgression(
        growthRateId: (json['growthRateId'] as String?)?.trim() ?? '',
        baseExp: (json['baseExp'] as num?)?.toInt() ?? 0,
        catchRate: (json['catchRate'] as num?)?.toInt() ?? 0,
        baseFriendship: (json['baseFriendship'] as num?)?.toInt() ?? 0,
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'growthRateId': growthRateId,
    'baseExp': baseExp,
    'catchRate': catchRate,
    'baseFriendship': baseFriendship,
  };
}

class PokemonSpeciesRefs {
  const PokemonSpeciesRefs({
    required this.learnset,
    required this.evolution,
    required this.media,
  });

  final String learnset;
  final String evolution;
  final String media;

  factory PokemonSpeciesRefs.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesRefs(
        learnset: (json['learnset'] as String?)?.trim() ?? '',
        evolution: (json['evolution'] as String?)?.trim() ?? '',
        media: (json['media'] as String?)?.trim() ?? '',
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'learnset': learnset,
    'evolution': evolution,
    'media': media,
  };
}

class PokemonSpeciesForms {
  const PokemonSpeciesForms({
    this.baseFormId = '',
    this.isBaseForm = true,
    this.formId = '',
    this.formName,
    this.otherForms = const <String>[],
  });

  final String baseFormId;
  final bool isBaseForm;
  final String formId;
  final String? formName;
  final List<String> otherForms;

  factory PokemonSpeciesForms.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesForms(
        baseFormId: (json['baseFormId'] as String?)?.trim() ?? '',
        isBaseForm: _readBool(json['isBaseForm'], fallback: true),
        formId: (json['formId'] as String?)?.trim() ?? '',
        formName: _readOptionalTrimmedString(json['formName']),
        otherForms: _readStringList(json['otherForms']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'baseFormId': baseFormId,
    'isBaseForm': isBaseForm,
    'formId': formId,
    'formName': formName,
    'otherForms': List<String>.from(otherForms),
  };
}

class PokemonSpeciesClassification {
  const PokemonSpeciesClassification({
    this.isEnabledInProject = true,
    this.isObtainable = true,
    this.isLegendary = false,
    this.isMythical = false,
    this.isBaby = false,
  });

  final bool isEnabledInProject;
  final bool isObtainable;
  final bool isLegendary;
  final bool isMythical;
  final bool isBaby;

  factory PokemonSpeciesClassification.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesClassification(
        isEnabledInProject: _readBool(
          json['isEnabledInProject'],
          fallback: true,
        ),
        isObtainable: _readBool(json['isObtainable'], fallback: true),
        isLegendary: _readBool(json['isLegendary']),
        isMythical: _readBool(json['isMythical']),
        isBaby: _readBool(json['isBaby']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'isEnabledInProject': isEnabledInProject,
    'isObtainable': isObtainable,
    'isLegendary': isLegendary,
    'isMythical': isMythical,
    'isBaby': isBaby,
  };
}

class PokemonSpeciesDexContent {
  const PokemonSpeciesDexContent({
    this.heightM,
    this.weightKg,
    this.color,
    this.flavorText,
  });

  final double? heightM;
  final double? weightKg;
  final String? color;
  final String? flavorText;

  factory PokemonSpeciesDexContent.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesDexContent(
        heightM: _readDouble(json['heightM']),
        weightKg: _readDouble(json['weightKg']),
        color: _readOptionalTrimmedString(json['color']),
        flavorText: _readOptionalTrimmedString(json['flavorText']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'heightM': heightM,
    'weightKg': weightKg,
    'color': color,
    'flavorText': flavorText,
  };
}

class PokemonSpeciesGameplayFlags {
  const PokemonSpeciesGameplayFlags({
    this.starterEligible = false,
    this.giftOnly = false,
    this.tradeOnly = false,
  });

  final bool starterEligible;
  final bool giftOnly;
  final bool tradeOnly;

  factory PokemonSpeciesGameplayFlags.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesGameplayFlags(
        starterEligible: _readBool(json['starterEligible']),
        giftOnly: _readBool(json['giftOnly']),
        tradeOnly: _readBool(json['tradeOnly']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'starterEligible': starterEligible,
    'giftOnly': giftOnly,
    'tradeOnly': tradeOnly,
  };
}

class PokemonSpeciesSourceMeta {
  const PokemonSpeciesSourceMeta({this.seededBy, this.seedVersion});

  final String? seededBy;
  final int? seedVersion;

  factory PokemonSpeciesSourceMeta.fromJson(Map<String, dynamic> json) =>
      PokemonSpeciesSourceMeta(
        seededBy: _readOptionalTrimmedString(json['seededBy']),
        seedVersion: (json['seedVersion'] as num?)?.toInt(),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'seededBy': seededBy,
    'seedVersion': seedVersion,
  };
}

class PokemonSpeciesFile {
  const PokemonSpeciesFile({
    this.schemaVersion = currentPokemonDataSchemaVersion,
    required this.id,
    required this.slug,
    required this.nationalDex,
    required this.names,
    required this.speciesName,
    required this.genIntroduced,
    required this.typing,
    required this.baseStats,
    required this.abilities,
    required this.breeding,
    required this.progression,
    this.forms = const PokemonSpeciesForms(),
    this.classification = const PokemonSpeciesClassification(),
    required this.refs,
    this.dexContent = const PokemonSpeciesDexContent(),
    this.gameplayFlags = const PokemonSpeciesGameplayFlags(),
    this.sourceMeta = const PokemonSpeciesSourceMeta(),
  });

  final int schemaVersion;
  final String id;
  final String slug;
  final int nationalDex;
  final Map<String, String> names;
  final Map<String, String> speciesName;
  final int genIntroduced;
  final PokemonSpeciesTyping typing;
  final PokemonSpeciesBaseStats baseStats;
  final PokemonSpeciesAbilities abilities;
  final PokemonSpeciesBreeding breeding;
  final PokemonSpeciesProgression progression;
  final PokemonSpeciesForms forms;
  final PokemonSpeciesClassification classification;
  final PokemonSpeciesRefs refs;
  final PokemonSpeciesDexContent dexContent;
  final PokemonSpeciesGameplayFlags gameplayFlags;
  final PokemonSpeciesSourceMeta sourceMeta;

  String get learnsetRef => refs.learnset;
  String get evolutionRef => refs.evolution;
  String get mediaRef => refs.media;

  factory PokemonSpeciesFile.fromJson(Map<String, dynamic> json) {
    final refsJson =
        (json['refs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{
          'learnset': (json['learnsetRef'] as String?)?.trim() ?? '',
          'evolution': (json['evolutionRef'] as String?)?.trim() ?? '',
          'media': _readLegacySpeciesMediaRef(json),
        };
    return PokemonSpeciesFile(
      schemaVersion: _readPokemonDataSchemaVersion(json),
      id: (json['id'] as String?)?.trim() ?? '',
      slug: (json['slug'] as String?)?.trim() ?? '',
      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
      names: _readStringMap(json['names']),
      speciesName: _readStringMap(json['speciesName']),
      genIntroduced: (json['genIntroduced'] as num?)?.toInt() ?? 0,
      typing: PokemonSpeciesTyping.fromJson(
        (json['typing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      baseStats: PokemonSpeciesBaseStats.fromJson(
        (json['baseStats'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      abilities: PokemonSpeciesAbilities.fromJson(
        (json['abilities'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      breeding: PokemonSpeciesBreeding.fromJson(
        (json['breeding'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      progression: PokemonSpeciesProgression.fromJson(
        (json['progression'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      forms: PokemonSpeciesForms.fromJson(
        (json['forms'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      classification: PokemonSpeciesClassification.fromJson(
        (json['classification'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      refs: PokemonSpeciesRefs.fromJson(refsJson),
      dexContent: PokemonSpeciesDexContent.fromJson(
        (json['dexContent'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags.fromJson(
        (json['gameplayFlags'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      sourceMeta: PokemonSpeciesSourceMeta.fromJson(
        (json['sourceMeta'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'id': id,
    'slug': slug,
    'nationalDex': nationalDex,
    'names': Map<String, String>.from(names),
    'speciesName': Map<String, String>.from(speciesName),
    'genIntroduced': genIntroduced,
    'typing': typing.toJson(),
    'baseStats': baseStats.toJson(),
    'abilities': abilities.toJson(),
    'breeding': breeding.toJson(),
    'progression': progression.toJson(),
    'forms': forms.toJson(),
    'classification': classification.toJson(),
    'refs': refs.toJson(),
    'dexContent': dexContent.toJson(),
    'gameplayFlags': gameplayFlags.toJson(),
    'sourceMeta': sourceMeta.toJson(),
  };
}

class PokemonMediaAnimationRef {
  const PokemonMediaAnimationRef({
    required this.sheet,
    required this.animationId,
  });

  final String sheet;
  final String animationId;

  factory PokemonMediaAnimationRef.fromJson(Map<String, dynamic> json) =>
      PokemonMediaAnimationRef(
        sheet: (json['sheet'] as String?)?.trim() ?? '',
        animationId: (json['animationId'] as String?)?.trim() ?? '',
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'sheet': sheet,
    'animationId': animationId,
  };
}

class PokemonMediaVariant {
  const PokemonMediaVariant({
    this.frontStatic,
    this.backStatic,
    this.frontShinyStatic,
    this.backShinyStatic,
    this.icon,
    this.party,
    this.overworld,
    this.portrait,
    this.cry,
    this.animations = const <String, PokemonMediaAnimationRef>{},
  });

  final String? frontStatic;
  final String? backStatic;
  final String? frontShinyStatic;
  final String? backShinyStatic;
  final String? icon;
  final String? party;
  final String? overworld;
  final String? portrait;
  final String? cry;
  final Map<String, PokemonMediaAnimationRef> animations;

  factory PokemonMediaVariant.fromJson(Map<String, dynamic> json) {
    final rawAnimations =
        (json['animations'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return PokemonMediaVariant(
      frontStatic: _readOptionalTrimmedString(json['frontStatic']),
      backStatic: _readOptionalTrimmedString(json['backStatic']),
      frontShinyStatic: _readOptionalTrimmedString(json['frontShinyStatic']),
      backShinyStatic: _readOptionalTrimmedString(json['backShinyStatic']),
      icon: _readOptionalTrimmedString(json['icon']),
      party: _readOptionalTrimmedString(json['party']),
      overworld: _readOptionalTrimmedString(json['overworld']),
      portrait: _readOptionalTrimmedString(json['portrait']),
      cry: _readOptionalTrimmedString(json['cry']),
      animations: rawAnimations.map(
        (key, value) => MapEntry(
          key,
          PokemonMediaAnimationRef.fromJson(
            (value as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{},
          ),
        ),
      ),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'frontStatic': frontStatic,
    'backStatic': backStatic,
    'frontShinyStatic': frontShinyStatic,
    'backShinyStatic': backShinyStatic,
    'icon': icon,
    'party': party,
    'overworld': overworld,
    'portrait': portrait,
    'cry': cry,
    'animations': animations.map((key, value) => MapEntry(key, value.toJson())),
  };
}

class PokemonMediaFile {
  const PokemonMediaFile({
    this.schemaVersion = currentPokemonDataSchemaVersion,
    required this.speciesId,
    required this.defaultFormId,
    this.variants = const <String, PokemonMediaVariant>{},
  });

  final int schemaVersion;
  final String speciesId;
  final String defaultFormId;
  final Map<String, PokemonMediaVariant> variants;

  factory PokemonMediaFile.fromJson(Map<String, dynamic> json) {
    final rawVariants =
        (json['variants'] as Map?)?.cast<String, dynamic>() ??
        const <String, dynamic>{};
    return PokemonMediaFile(
      schemaVersion: _readPokemonDataSchemaVersion(json),
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      defaultFormId: (json['defaultFormId'] as String?)?.trim() ?? '',
      variants: rawVariants.map(
        (key, value) => MapEntry(
          key,
          PokemonMediaVariant.fromJson(
            (value as Map?)?.cast<String, dynamic>() ??
                const <String, dynamic>{},
          ),
        ),
      ),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'speciesId': speciesId,
    'defaultFormId': defaultFormId,
    'variants': variants.map((key, value) => MapEntry(key, value.toJson())),
  };
}

class PokemonLearnsetMoveEntry {
  const PokemonLearnsetMoveEntry({
    required this.moveId,
    required this.versionGroup,
  });

  final String moveId;
  final String versionGroup;

  factory PokemonLearnsetMoveEntry.fromJson(Map<String, dynamic> json) =>
      PokemonLearnsetMoveEntry(
        moveId: (json['moveId'] as String?)?.trim() ?? '',
        versionGroup: (json['versionGroup'] as String?)?.trim() ?? '',
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'moveId': moveId,
    'versionGroup': versionGroup,
  };
}

class PokemonLearnsetLevelUpEntry {
  const PokemonLearnsetLevelUpEntry({
    required this.moveId,
    required this.level,
    required this.source,
    required this.versionGroup,
  });

  final String moveId;
  final int level;
  final String source;
  final String versionGroup;

  factory PokemonLearnsetLevelUpEntry.fromJson(Map<String, dynamic> json) =>
      PokemonLearnsetLevelUpEntry(
        moveId: (json['moveId'] as String?)?.trim() ?? '',
        level: (json['level'] as num?)?.toInt() ?? 0,
        source: (json['source'] as String?)?.trim() ?? '',
        versionGroup: (json['versionGroup'] as String?)?.trim() ?? '',
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'moveId': moveId,
    'level': level,
    'source': source,
    'versionGroup': versionGroup,
  };
}

class PokemonLearnsetFile {
  const PokemonLearnsetFile({
    this.schemaVersion = currentPokemonDataSchemaVersion,
    required this.speciesId,
    this.startingMoves = const <String>[],
    this.relearnMoves = const <String>[],
    this.levelUp = const <PokemonLearnsetLevelUpEntry>[],
    this.tm = const <PokemonLearnsetMoveEntry>[],
    this.hm = const <PokemonLearnsetMoveEntry>[],
    this.tutor = const <PokemonLearnsetMoveEntry>[],
    this.egg = const <PokemonLearnsetMoveEntry>[],
    this.event = const <PokemonLearnsetMoveEntry>[],
    this.transfer = const <PokemonLearnsetMoveEntry>[],
  });

  final int schemaVersion;
  final String speciesId;
  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<PokemonLearnsetLevelUpEntry> levelUp;
  final List<PokemonLearnsetMoveEntry> tm;
  final List<PokemonLearnsetMoveEntry> hm;
  final List<PokemonLearnsetMoveEntry> tutor;
  final List<PokemonLearnsetMoveEntry> egg;
  final List<PokemonLearnsetMoveEntry> event;
  final List<PokemonLearnsetMoveEntry> transfer;

  factory PokemonLearnsetFile.fromJson(Map<String, dynamic> json) {
    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    List<PokemonLearnsetMoveEntry> readMoveEntries(String key) {
      final raw = (json[key] as List?) ?? const <Object?>[];
      return raw
          .whereType<Map>()
          .map(
            (entry) => PokemonLearnsetMoveEntry.fromJson(
              entry.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false);
    }

    return PokemonLearnsetFile(
      schemaVersion: _readPokemonDataSchemaVersion(json),
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      startingMoves: _readStringList(json['startingMoves']),
      relearnMoves: _readStringList(json['relearnMoves']),
      levelUp: rawLevelUp
          .whereType<Map>()
          .map(
            (entry) => PokemonLearnsetLevelUpEntry.fromJson(
              entry.cast<String, dynamic>(),
            ),
          )
          .toList(growable: false),
      tm: readMoveEntries('tm'),
      hm: readMoveEntries('hm'),
      tutor: readMoveEntries('tutor'),
      egg: readMoveEntries('egg'),
      event: readMoveEntries('event'),
      transfer: readMoveEntries('transfer'),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'speciesId': speciesId,
    'startingMoves': List<String>.from(startingMoves),
    'relearnMoves': List<String>.from(relearnMoves),
    'levelUp': levelUp.map((entry) => entry.toJson()).toList(growable: false),
    'tm': tm.map((entry) => entry.toJson()).toList(growable: false),
    'hm': hm.map((entry) => entry.toJson()).toList(growable: false),
    'tutor': tutor.map((entry) => entry.toJson()).toList(growable: false),
    'egg': egg.map((entry) => entry.toJson()).toList(growable: false),
    'event': event.map((entry) => entry.toJson()).toList(growable: false),
    'transfer': transfer.map((entry) => entry.toJson()).toList(growable: false),
  };
}

class PokemonEvolutionEntry {
  const PokemonEvolutionEntry({
    required this.targetSpeciesId,
    required this.method,
    this.minLevel,
    this.minFriendship,
    this.itemId,
    this.requiredMoveId,
    this.conditionText = const <String, String>{},
  });

  final String targetSpeciesId;
  final String method;
  final int? minLevel;
  final int? minFriendship;
  final String? itemId;
  final String? requiredMoveId;
  final Map<String, String> conditionText;

  factory PokemonEvolutionEntry.fromJson(Map<String, dynamic> json) =>
      PokemonEvolutionEntry(
        targetSpeciesId: (json['targetSpeciesId'] as String?)?.trim() ?? '',
        method: (json['method'] as String?)?.trim() ?? '',
        minLevel: (json['minLevel'] as num?)?.toInt(),
        minFriendship: (json['minFriendship'] as num?)?.toInt(),
        itemId: _readOptionalTrimmedString(json['itemId']),
        requiredMoveId: _readOptionalTrimmedString(json['requiredMoveId']),
        conditionText: _readStringMap(json['conditionText']),
      );

  Map<String, Object?> toJson() => <String, Object?>{
    'targetSpeciesId': targetSpeciesId,
    'method': method,
    'minLevel': minLevel,
    'minFriendship': minFriendship,
    'itemId': itemId,
    'requiredMoveId': requiredMoveId,
    'conditionText': Map<String, String>.from(conditionText),
  };
}

class PokemonEvolutionFile {
  const PokemonEvolutionFile({
    this.schemaVersion = currentPokemonDataSchemaVersion,
    required this.speciesId,
    this.preEvolution,
    this.evolutions = const <PokemonEvolutionEntry>[],
  });

  final int schemaVersion;
  final String speciesId;
  final String? preEvolution;
  final List<PokemonEvolutionEntry> evolutions;

  factory PokemonEvolutionFile.fromJson(Map<String, dynamic> json) {
    final rawEvolutions = (json['evolutions'] as List?) ?? const <Object?>[];
    return PokemonEvolutionFile(
      schemaVersion: _readPokemonDataSchemaVersion(json),
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      preEvolution: _readOptionalTrimmedString(json['preEvolution']),
      evolutions: rawEvolutions
          .whereType<Map>()
          .map(
            (entry) =>
                PokemonEvolutionEntry.fromJson(entry.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() => <String, Object?>{
    'schemaVersion': schemaVersion,
    'speciesId': speciesId,
    'preEvolution': preEvolution,
    'evolutions': evolutions
        .map((entry) => entry.toJson())
        .toList(growable: false),
  };
}

int _readPokemonDataSchemaVersion(Map<String, dynamic> json) {
  final rawVersion = json['schemaVersion'];
  if (rawVersion == null) {
    return currentPokemonDataSchemaVersion;
  }
  if (rawVersion is! num || rawVersion.toInt() != rawVersion) {
    throw UnsupportedPokemonDataSchema(
      actualVersion: rawVersion,
      path: r'$.schemaVersion',
    );
  }
  final schemaVersion = rawVersion.toInt();
  if (schemaVersion != currentPokemonDataSchemaVersion) {
    throw UnsupportedPokemonDataSchema(
      actualVersion: schemaVersion,
      path: r'$.schemaVersion',
    );
  }
  return schemaVersion;
}

List<String> _readStringList(Object? raw) {
  final values = (raw as List?) ?? const <Object?>[];
  return values
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _readStringMap(Object? raw) {
  final values = raw as Map?;
  if (values == null) return const <String, String>{};
  final result = <String, String>{};
  for (final entry in values.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is String && value is String) {
      final trimmedKey = key.trim();
      if (trimmedKey.isNotEmpty) {
        result[trimmedKey] = value.trim();
      }
    }
  }
  return result;
}

String? _readOptionalTrimmedString(Object? raw) {
  final value = (raw as String?)?.trim();
  return value == null || value.isEmpty ? null : value;
}

String? _pickPrimaryName(Map<String, String> names) {
  for (final preferredKey in const <String>['en', 'fr']) {
    final value = names[preferredKey];
    if (value != null && value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  for (final value in names.values) {
    if (value.trim().isNotEmpty) {
      return value.trim();
    }
  }
  return null;
}

String _readLegacySpeciesMediaRef(Map<String, dynamic> json) {
  final spriteSetRef = (json['spriteSetRef'] as String?)?.trim() ?? '';
  final cryRef = (json['cryRef'] as String?)?.trim() ?? '';
  if (spriteSetRef.isNotEmpty && cryRef.isNotEmpty && spriteSetRef == cryRef) {
    return spriteSetRef;
  }
  if (spriteSetRef.isNotEmpty) {
    return spriteSetRef;
  }
  return cryRef;
}

double? _readDouble(Object? raw) => (raw as num?)?.toDouble();

bool _readBool(Object? raw, {bool fallback = false}) =>
    raw is bool ? raw : fallback;

Map<String, dynamic> _deepCopyJsonMap(Map<String, dynamic> source) =>
    source.map((key, value) => MapEntry(key, _deepCopyJsonValue(value)));

Object? _deepCopyJsonValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return _deepCopyJsonMap(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) =>
          MapEntry(key.toString(), _deepCopyJsonValue(nestedValue)),
    );
  }
  if (value is List) {
    return value.map(_deepCopyJsonValue).toList(growable: false);
  }
  return value;
}
