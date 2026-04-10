/// Metadonnees communes des JSON Pokemon locaux.
///
/// On garde ce modele volontairement petit : il capture seulement les champs
/// reels deja presents dans le manifeste et les catalogues seeds jusqu'ici.
class PokemonDataMeta {
  const PokemonDataMeta({
    required this.description,
    this.sourcePriority = const <String>[],
    this.notes = const <String>[],
  });

  final String description;
  final List<String> sourcePriority;
  final List<String> notes;

  factory PokemonDataMeta.fromJson(Map<String, dynamic> json) {
    return PokemonDataMeta(
      description: (json['description'] as String?)?.trim() ?? '',
      sourcePriority: _readStringList(json['sourcePriority']),
      notes: _readStringList(json['notes']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'description': description,
      'sourcePriority': List<String>.from(sourcePriority),
      'notes': List<String>.from(notes),
    };
  }
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

  factory PokemonDataManifest.fromJson(Map<String, dynamic> json) {
    return PokemonDataManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
      kind: (json['kind'] as String?)?.trim() ?? '',
      meta: PokemonDataMeta.fromJson(
        (json['meta'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ),
      catalogFiles: _readStringMap(json['catalogFiles']),
      futureDataFolders: _readStringMap(json['futureDataFolders']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'kind': kind,
      'meta': meta.toJson(),
      'catalogFiles': Map<String, String>.from(catalogFiles),
      'futureDataFolders': Map<String, String>.from(futureDataFolders),
    };
  }
}

/// Catalogue Pokemon generique.
///
/// On garde `entries` en JSON brut pour ce lot afin d'eviter de sur-typer
/// prematurement tous les referentiels globaux. Les lots suivants pourront
/// specialiser certains catalogues si cela apporte une vraie valeur.
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
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 0,
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'schemaVersion': schemaVersion,
      'kind': kind,
      'catalog': catalog,
      'meta': meta.toJson(),
      'entries': entries
          .map((entry) => _deepCopyJsonMap(entry))
          .toList(growable: false),
    };
  }
}

/// Projection legere d'une espece pour les futurs usages liste/index.
///
/// Cette entree est volontairement beaucoup plus petite que [PokemonSpeciesFile].
/// Elle suffit pour :
/// - lister les Pokemon disponibles ;
/// - afficher un nom et des types ;
/// - resoudre ensuite le chemin detail sans reparcourir naivement tout le
///   dossier pour chaque lecture.
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
    // Cette factory legacy reste disponible pour les call sites qui ont
    // encore du JSON brut, mais elle délègue désormais au vrai modèle espèce.
    //
    // On évite ainsi d'entretenir deux projections concurrentes du même JSON :
    // la version détaillée `PokemonSpeciesFile` reste la source de vérité.
    return PokemonSpeciesIndexEntry.fromSpeciesFile(
      PokemonSpeciesFile.fromJson(json),
      relativePath: relativePath,
    );
  }

  /// Construit la projection légère à partir d'une espèce déjà parsée.
  ///
  /// Le but est de centraliser la logique de projection liste sur une source
  /// de vérité unique, plutôt que de reparser le JSON dans plusieurs modèles.
  factory PokemonSpeciesIndexEntry.fromSpeciesFile(
    PokemonSpeciesFile species, {
    required String relativePath,
  }) {
    return PokemonSpeciesIndexEntry(
      id: species.id.trim(),
      nationalDex: species.nationalDex,
      primaryName:
          _pickPrimaryName(species.names) ?? species.id.trim(),
      types: List<String>.from(species.typing.types),
      relativePath: relativePath,
    );
  }
}

class PokemonSpeciesTyping {
  const PokemonSpeciesTyping({
    this.types = const <String>[],
  });

  final List<String> types;

  factory PokemonSpeciesTyping.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesTyping(types: _readStringList(json['types']));
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'types': List<String>.from(types),
    };
  }
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

  factory PokemonSpeciesBaseStats.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesBaseStats(
      hp: (json['hp'] as num?)?.toInt() ?? 0,
      atk: (json['atk'] as num?)?.toInt() ?? 0,
      def: (json['def'] as num?)?.toInt() ?? 0,
      spa: (json['spa'] as num?)?.toInt() ?? 0,
      spd: (json['spd'] as num?)?.toInt() ?? 0,
      spe: (json['spe'] as num?)?.toInt() ?? 0,
      bst: (json['bst'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'hp': hp,
      'atk': atk,
      'def': def,
      'spa': spa,
      'spd': spd,
      'spe': spe,
      'bst': bst,
    };
  }
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

  factory PokemonSpeciesAbilities.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesAbilities(
      primary: (json['primary'] as String?)?.trim() ?? '',
      secondary: (json['secondary'] as String?)?.trim(),
      hidden: (json['hidden'] as String?)?.trim(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'primary': primary,
      'secondary': secondary,
      'hidden': hidden,
    };
  }
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'genderRatio': genderRatio.map(
        (key, value) => MapEntry(key, value),
      ),
      'eggGroups': List<String>.from(eggGroups),
      'hatchCycles': hatchCycles,
    };
  }
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

  factory PokemonSpeciesProgression.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesProgression(
      growthRateId: (json['growthRateId'] as String?)?.trim() ?? '',
      baseExp: (json['baseExp'] as num?)?.toInt() ?? 0,
      catchRate: (json['catchRate'] as num?)?.toInt() ?? 0,
      baseFriendship: (json['baseFriendship'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'growthRateId': growthRateId,
      'baseExp': baseExp,
      'catchRate': catchRate,
      'baseFriendship': baseFriendship,
    };
  }
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

  factory PokemonSpeciesDexContent.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesDexContent(
      heightM: _readDouble(json['heightM']),
      weightKg: _readDouble(json['weightKg']),
      color: _readOptionalTrimmedString(json['color']),
      flavorText: _readOptionalTrimmedString(json['flavorText']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'heightM': heightM,
      'weightKg': weightKg,
      'color': color,
      'flavorText': flavorText,
    };
  }
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

  factory PokemonSpeciesGameplayFlags.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesGameplayFlags(
      starterEligible: _readBool(json['starterEligible']),
      giftOnly: _readBool(json['giftOnly']),
      tradeOnly: _readBool(json['tradeOnly']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'starterEligible': starterEligible,
      'giftOnly': giftOnly,
      'tradeOnly': tradeOnly,
    };
  }
}

class PokemonSpeciesSourceMeta {
  const PokemonSpeciesSourceMeta({
    this.seededBy,
    this.seedVersion,
  });

  final String? seededBy;
  final int? seedVersion;

  factory PokemonSpeciesSourceMeta.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesSourceMeta(
      seededBy: _readOptionalTrimmedString(json['seededBy']),
      seedVersion: (json['seedVersion'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'seededBy': seededBy,
      'seedVersion': seedVersion,
    };
  }
}

class PokemonSpeciesFile {
  const PokemonSpeciesFile({
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
    required this.evolutionRef,
    required this.learnsetRef,
    required this.spriteSetRef,
    required this.cryRef,
    required this.dexContent,
    required this.gameplayFlags,
    required this.sourceMeta,
  });

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
  final String evolutionRef;
  final String learnsetRef;
  final String spriteSetRef;
  final String cryRef;
  final PokemonSpeciesDexContent dexContent;
  final PokemonSpeciesGameplayFlags gameplayFlags;
  final PokemonSpeciesSourceMeta sourceMeta;

  factory PokemonSpeciesFile.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesFile(
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
      evolutionRef: (json['evolutionRef'] as String?)?.trim() ?? '',
      learnsetRef: (json['learnsetRef'] as String?)?.trim() ?? '',
      spriteSetRef: (json['spriteSetRef'] as String?)?.trim() ?? '',
      cryRef: (json['cryRef'] as String?)?.trim() ?? '',
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

  Map<String, Object?> toJson() {
    return <String, Object?>{
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
      'evolutionRef': evolutionRef,
      'learnsetRef': learnsetRef,
      'spriteSetRef': spriteSetRef,
      'cryRef': cryRef,
      'dexContent': dexContent.toJson(),
      'gameplayFlags': gameplayFlags.toJson(),
      'sourceMeta': sourceMeta.toJson(),
    };
  }
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

  factory PokemonLearnsetLevelUpEntry.fromJson(Map<String, dynamic> json) {
    return PokemonLearnsetLevelUpEntry(
      moveId: (json['moveId'] as String?)?.trim() ?? '',
      level: (json['level'] as num?)?.toInt() ?? 0,
      source: (json['source'] as String?)?.trim() ?? '',
      versionGroup: (json['versionGroup'] as String?)?.trim() ?? '',
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'moveId': moveId,
      'level': level,
      'source': source,
      'versionGroup': versionGroup,
    };
  }
}

class PokemonLearnsetFile {
  const PokemonLearnsetFile({
    required this.speciesId,
    this.startingMoves = const <String>[],
    this.relearnMoves = const <String>[],
    this.levelUp = const <PokemonLearnsetLevelUpEntry>[],
  });

  final String speciesId;
  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<PokemonLearnsetLevelUpEntry> levelUp;

  factory PokemonLearnsetFile.fromJson(Map<String, dynamic> json) {
    final rawLevelUp = (json['levelUp'] as List?) ?? const <Object?>[];
    return PokemonLearnsetFile(
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      startingMoves: _readStringList(json['startingMoves']),
      relearnMoves: _readStringList(json['relearnMoves']),
      levelUp: rawLevelUp
          .whereType<Map>()
          .map(
            (entry) =>
                PokemonLearnsetLevelUpEntry.fromJson(
                  entry.cast<String, dynamic>(),
                ),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'speciesId': speciesId,
      'startingMoves': List<String>.from(startingMoves),
      'relearnMoves': List<String>.from(relearnMoves),
      'levelUp': levelUp.map((entry) => entry.toJson()).toList(growable: false),
    };
  }
}

class PokemonEvolutionEntry {
  const PokemonEvolutionEntry({
    required this.targetSpeciesId,
    required this.method,
    this.minLevel,
  });

  final String targetSpeciesId;
  final String method;
  final int? minLevel;

  factory PokemonEvolutionEntry.fromJson(Map<String, dynamic> json) {
    return PokemonEvolutionEntry(
      targetSpeciesId: (json['targetSpeciesId'] as String?)?.trim() ?? '',
      method: (json['method'] as String?)?.trim() ?? '',
      minLevel: (json['minLevel'] as num?)?.toInt(),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'targetSpeciesId': targetSpeciesId,
      'method': method,
      'minLevel': minLevel,
    };
  }
}

class PokemonEvolutionFile {
  const PokemonEvolutionFile({
    required this.speciesId,
    this.preEvolution,
    this.evolutions = const <PokemonEvolutionEntry>[],
  });

  final String speciesId;
  final String? preEvolution;
  final List<PokemonEvolutionEntry> evolutions;

  factory PokemonEvolutionFile.fromJson(Map<String, dynamic> json) {
    final rawEvolutions = (json['evolutions'] as List?) ?? const <Object?>[];
    return PokemonEvolutionFile(
      speciesId: (json['speciesId'] as String?)?.trim() ?? '',
      preEvolution: (json['preEvolution'] as String?)?.trim(),
      evolutions: rawEvolutions
          .whereType<Map>()
          .map(
            (entry) =>
                PokemonEvolutionEntry.fromJson(entry.cast<String, dynamic>()),
          )
          .toList(growable: false),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'speciesId': speciesId,
      'preEvolution': preEvolution,
      'evolutions': evolutions
          .map((entry) => entry.toJson())
          .toList(growable: false),
    };
  }
}

List<String> _readStringList(Object? raw) {
  final list = raw as List?;
  if (list == null) return const <String>[];
  return list
      .whereType<String>()
      .map((value) => value.trim())
      .where((value) => value.isNotEmpty)
      .toList(growable: false);
}

Map<String, String> _readStringMap(Object? raw) {
  final map = raw as Map?;
  if (map == null) return const <String, String>{};
  final result = <String, String>{};
  for (final entry in map.entries) {
    final key = entry.key;
    final value = entry.value;
    if (key is String && value is String) {
      final trimmedKey = key.trim();
      final trimmedValue = value.trim();
      if (trimmedKey.isNotEmpty) {
        result[trimmedKey] = trimmedValue;
      }
    }
  }
  return result;
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

String? _readOptionalTrimmedString(Object? raw) {
  final value = raw as String?;
  if (value == null) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

double? _readDouble(Object? raw) {
  final value = raw as num?;
  return value?.toDouble();
}

bool _readBool(Object? raw) {
  return raw == true;
}

Map<String, dynamic> _deepCopyJsonMap(Map<String, dynamic> source) {
  return source.map(
    (key, value) => MapEntry(key, _deepCopyJsonValue(value)),
  );
}

Object? _deepCopyJsonValue(Object? value) {
  if (value is Map<String, dynamic>) {
    return _deepCopyJsonMap(value);
  }
  if (value is Map) {
    return value.map(
      (key, nestedValue) => MapEntry(key.toString(), _deepCopyJsonValue(nestedValue)),
    );
  }
  if (value is List) {
    return value.map(_deepCopyJsonValue).toList(growable: false);
  }
  return value;
}
