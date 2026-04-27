# Lot 5c — Lecture locale Pokémon sans dépendance métier au nom de fichier

## 1. Problème exact corrigé

Le problème du lot précédent était structurel :

- `listSpeciesIndexEntries()` exposait l’identité métier d’une espèce à partir du JSON ;
- mais `readSpeciesById()` continuait à reposer sur une résolution dérivée du nom de fichier ;
- donc il restait possible d’avoir une divergence entre :
  - la liste légère ;
  - la lecture détail.

Exemple problématique :

- fichier : `9999-not-the-display-name.json`
- contenu JSON : `"id": "mystery_mon"`

Dans ce cas, la liste légère pouvait exposer `mystery_mon`, mais la résolution détail pouvait encore dépendre du basename.  
Ce n’était pas acceptable pour une vraie base de données Pokémon locale.

## 2. Pourquoi la version précédente restait bancale

### 2.1 Deux vérités concurrentes

Le lot précédent mélangeait encore :

- la vérité métier portée par le JSON (`species.id`) ;
- une pseudo-vérité déduite du nom de fichier.

Même si le système était déjà mieux qu’au lot 5 initial, il restait conceptuellement incohérent.

### 2.2 Logique de résolution parallèle

`readSpeciesById()` avait encore sa propre logique de résolution.  
La projection légère avait donc une logique, et la lecture détail en avait une autre.

### 2.3 Fallbacks implicites

Le lot précédent avait déjà retiré le fallback de nom depuis le chemin, mais la couche gardait encore une logique implicite de résolution basée sur le stockage physique.

## 3. Stratégie retenue

La stratégie finale est simple :

1. les fichiers espèces sont listés depuis le workspace ;
2. la projection légère canonique est construite en lisant les JSON espèces ;
3. `readSpeciesById()` résout une espèce uniquement à partir de cette projection légère canonique ;
4. le fichier détail est ensuite relu via `relativePath`.

Conséquence directe :

- la vérité métier d’une espèce est le JSON ;
- l’id de référence est `species.id` ;
- aucune résolution métier ne dépend du nom de fichier.

## 4. Politique choisie pour les JSON invalides

Politique retenue : **stricte**.

Concrètement :

- si un JSON espèce est invalide, la construction de la projection légère échoue explicitement ;
- donc `listSpeciesIndexEntries()` échoue ;
- et `readSpeciesById()` échoue aussi, puisqu’il s’appuie sur cette même vérité canonique.

Pourquoi ce choix :

- il évite toute ambiguïté ;
- il n’introduit pas de logique cachée “tolérante” ;
- il garantit qu’on ne masque pas des espèces corrompues ;
- il garde la base saine et honnête.

Conséquence assumée :

- un fichier espèce invalide non lié fait échouer la projection légère globale ;
- ce n’est pas aussi permissif que le lot 5c précédent ;
- mais c’est plus cohérent avec la règle “une seule vérité métier”.

## 5. Invariants finaux

Après ce lot, les invariants sont :

- la vérité métier d’une espèce est `species.id` lu dans le JSON ;
- `readSpeciesById()` ne dépend pas du basename ;
- la projection légère et la lecture détail reposent sur la même vérité métier ;
- `primaryName` vaut :
  - `names['en']`
  - sinon `names['fr']`
  - sinon `id`
- aucun fallback de nom depuis le chemin ;
- aucune lecture ne dépend de `Directory.current` ;
- `project.json` reste inchangé ;
- rien n’est recréé à la racine du monorepo.

## 6. Décisions sur les modèles

### 6.1 Ce qui est gardé typé

J’ai conservé les sous-modèles suivants :

- `PokemonSpeciesDexContent`
- `PokemonSpeciesGameplayFlags`
- `PokemonSpeciesSourceMeta`

Justification :

- ils restent petits ;
- ils sont alignés avec le dataset seedé actuel ;
- ils apportent une vraie valeur de lecture par rapport à un `Map<String, dynamic>` brut ;
- ils ne prétendent pas couvrir plus que le contrat réellement présent aujourd’hui.

### 6.2 Ce qui reste brut

`PokemonCatalogFile.entries` reste en :

- `List<Map<String, dynamic>>`

Justification :

- le typage profond des catalogues globaux n’est pas encore stabilisé ;
- ce lot ne doit pas sur-ingénierer la lecture ;
- ce n’est pas le sujet de la correction actuelle.

## 7. Fichiers modifiés

Fichiers modifiés dans ce lot :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart`

Fichier créé dans ce lot :

- `/Users/karim/Project/pokemonProject/reports/pokemon-local-reader-cleanup-lot-5c-report.md`

Fichiers non suivis préexistants encore présents dans le working tree :

- `/Users/karim/Project/pokemonProject/reports/pokemon-local-reader-cleanup-lot-5b-report.md`
- `/Users/karim/Project/pokemonProject/reports/pokemon-local-readers-lot-5-report.md`

## 8. Tests réellement exécutés

Commande exécutée :

```bash
flutter test test/pokemon_project_data_reader_test.dart
```

Résultat réel :

- succès ;
- 16 tests passés ;
- aucune erreur.

Cas couverts :

1. lecture du manifeste ;
2. lecture d’une espèce ;
3. lecture d’un learnset ;
4. lecture d’une évolution ;
5. lecture d’un catalogue ;
6. listage des fichiers espèces ;
7. projection légère cohérente ;
8. fallback de nom sur `id` et non sur le chemin ;
9. cohérence projection légère / lecture détail ;
10. espèce absente ;
11. catalogue inconnu ;
12. JSON invalide ;
13. politique stricte sur JSON espèce invalide dans la projection ;
14. conflit métier sur `species.id` dupliqué ;
15. indépendance à `Directory.current` ;
16. `project.json` inchangé.

## 9. Analyse réellement exécutée

Commande exécutée :

```bash
flutter analyze --no-pub \
  lib/src/application/models/pokemon_project_data_models.dart \
  lib/src/application/services/pokemon_project_data_reader.dart \
  test/pokemon_project_data_reader_test.dart
```

Résultat réel :

```text
Analyzing 3 items...
No issues found! (ran in 1.4s)
```

## 10. Sorties Git utiles

### `git status --short`

Sortie relevée avant écriture finale du présent rapport :

```text
?? packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
?? packages/map_editor/test/pokemon_project_data_reader_test.dart
?? reports/pokemon-local-reader-cleanup-lot-5b-report.md
?? reports/pokemon-local-reader-cleanup-lot-5c-report.md
?? reports/pokemon-local-readers-lot-5-report.md
```

### État ciblé du lot

```text
?? packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
?? packages/map_editor/test/pokemon_project_data_reader_test.dart
?? reports/pokemon-local-reader-cleanup-lot-5c-report.md
```

### `git diff --stat`

Commande exécutée :

```bash
git diff --stat -- \
  packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart \
  packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart \
  packages/map_editor/test/pokemon_project_data_reader_test.dart \
  reports/pokemon-local-reader-cleanup-lot-5c-report.md
```

Sortie réelle :

```text

```

Explication honnête :

- les fichiers du lot sont non suivis ;
- `git diff --stat` reste donc vide ;
- il faut lire cette sortie avec `git status --short` et le bundle de review.

### Racine du monorepo

Commande exécutée :

```bash
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Résultat réel :

- aucune sortie.

## 11. Bundle de review

Commande exécutée :

```bash
./review_bundle.sh
```

Fichier généré :

- `.review/review-20260408-224119.txt`

Contenu intégral :

```text
# REVIEW BUNDLE

Generated at: 2026-04-08 22:41:19
Repository: pokemonProject
Branch: main
Base ref: HEAD
Head commit: f808d3f994753a0fd443a0b82b338b9cae1ca3ac

## GIT STATUS --SHORT

?? packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
?? packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
?? packages/map_editor/test/pokemon_project_data_reader_test.dart
?? reports/pokemon-local-reader-cleanup-lot-5b-report.md
?? reports/pokemon-local-reader-cleanup-lot-5c-report.md
?? reports/pokemon-local-readers-lot-5-report.md

## GIT DIFF --STAT


## CHANGED FILES


## RECENT COMMITS

f808d3f Seed Pokémon demo data use case with idempotent JSON generation
c4d2983 Enrich Pokémon JSON storage contract with manifest and minimal catalog structures
e266743 Add use case to initialize Pokémon project storage structure
c41fe7e Add data and assets folder structure with .gitkeep placeholders for future Pokémon content
3d81349 Add tests to confirm grid-based collision granularity limitations and document runtime constraints
8675f74 Add migration for broken legacy manual collision profiles
59dce2a Audit runtime collision logic to validate `cells` as the active source of truth
2aa52f4 Fix collision base model to support authored shapes and resolve padding-based overcapture issues
fc7cf31 Enhance polygon rasterization logic and add backend cell preview to collision editor
fe5da3e Add tests for project collision profile persistence and enhance UI behavior in element collision editor
5d65444 Add element collision editor UI and rasterization services
e63e6cf Add element collision authoring services and padding-based workflow
5f714b5 Persist last opened project state and add auto-restore support
7a137dd Remove LOT 50 demo scenario and inject logic; add FPS overlay support
13127d3 Implement runtime completion gating for cutscenes in Step Studio

## FULL DIFF
```

Note honnête :

- le bundle est partiel du point de vue diff, parce que Git ne produit pas ici de diff classique pour les fichiers non suivis ;
- il reflète correctement l’état Git ;
- il a été généré avant l’écriture finale de ce rapport.

## 12. Code intégral du lot

### 12.1 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

```dart
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
    final names = _readStringMap(json['names']);
    return PokemonSpeciesIndexEntry(
      id: (json['id'] as String?)?.trim() ?? '',
      nationalDex: (json['nationalDex'] as num?)?.toInt() ?? 0,
      primaryName: _pickPrimaryName(names) ?? (json['id'] as String?)?.trim() ?? '',
      types: PokemonSpeciesTyping.fromJson(
        (json['typing'] as Map?)?.cast<String, dynamic>() ??
            const <String, dynamic>{},
      ).types,
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
```

### 12.2 `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/project_workspace.dart';

/// Lecteur local des donnees Pokemon stockees dans le workspace projet.
///
/// Invariants de cette couche :
/// - toutes les lectures passent par [ProjectWorkspace.projectRoot]
/// - aucun fallback implicite vers `Directory.current`
/// - aucune lecture depuis la racine du monorepo
/// - les erreurs doivent etre explicites pour que les prochains lots UI
///   puissent les afficher proprement
class PokemonProjectDataReader {
  const PokemonProjectDataReader();

  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) async {
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/pokemon_data_manifest.json',
      label: 'Pokemon data manifest',
    );
    return PokemonDataManifest.fromJson(json);
  }

  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) async {
    final manifest = await readManifest(workspace);
    final relativePath = manifest.catalogFiles[catalogKey];
    if (relativePath == null || relativePath.trim().isEmpty) {
      throw EditorNotFoundException(
        'Pokemon catalog not declared in manifest: $catalogKey',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/$relativePath',
      label: 'Pokemon catalog "$catalogKey"',
    );
    return PokemonCatalogFile.fromJson(json);
  }

  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException('Pokemon species id cannot be empty');
    }

    final speciesPathEntry = await _resolveSpeciesIndexEntryById(workspace, trimmedId);
    final species = await _readSpeciesAtRelativePath(
      workspace,
      speciesPathEntry.relativePath,
    );
    if (species.id != trimmedId) {
      throw EditorPersistenceException(
        'Pokemon species file id mismatch for "$trimmedId": '
        '${speciesPathEntry.relativePath} contains "${species.id}"',
      );
    }
    return species;
  }

  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/learnsets/$trimmedId.json',
      label: 'Pokemon learnset "$trimmedId"',
    );
    return PokemonLearnsetFile.fromJson(json);
  }

  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final trimmedId = speciesId.trim();
    if (trimmedId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon evolution id cannot be empty',
      );
    }
    final json = await _readJsonFile(
      workspace,
      'data/pokemon/evolutions/$trimmedId.json',
      label: 'Pokemon evolution "$trimmedId"',
    );
    return PokemonEvolutionFile.fromJson(json);
  }

  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) async {
    final speciesDir = _speciesDirectory(workspace);
    if (!await speciesDir.exists()) {
      throw const EditorNotFoundException(
        'Pokemon species directory not found in project workspace',
      );
    }

    final relativePaths = <String>[];
    await for (final entity in speciesDir.list(recursive: false)) {
      if (entity is! File) continue;
      if (p.extension(entity.path).toLowerCase() != '.json') continue;
      final relativePath = p.normalize(
        p.relative(entity.path, from: workspace.projectRoot),
      );
      relativePaths.add(relativePath);
    }
    relativePaths.sort();
    return relativePaths;
  }

  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    return _buildSpeciesIndexEntries(workspace);
  }

  Future<List<PokemonSpeciesIndexEntry>> _buildSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = <PokemonSpeciesIndexEntry>[];
    for (final relativePath in await listSpeciesFiles(workspace)) {
      final json = await _readJsonFile(
        workspace,
        relativePath,
        label: 'Pokemon species index file',
      );
      entries.add(
        PokemonSpeciesIndexEntry.fromJson(
          json,
          relativePath: relativePath,
        ),
      );
    }
    entries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) return dexCompare;
      return left.id.compareTo(right.id);
    });
    return entries;
  }

  Future<PokemonSpeciesFile> _readSpeciesAtRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) async {
    final json = await _readJsonFile(
      workspace,
      relativePath,
      label: 'Pokemon species file',
    );
    return PokemonSpeciesFile.fromJson(json);
  }

  Future<PokemonSpeciesIndexEntry> _resolveSpeciesIndexEntryById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final matches = (await _buildSpeciesIndexEntries(workspace))
        .where((entry) => entry.id == speciesId)
        .toList(growable: false);
    if (matches.isEmpty) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    if (matches.length > 1) {
      throw EditorConflictException(
        'Multiple Pokemon species files share the same id "$speciesId": '
        '${matches.map((entry) => entry.relativePath).join(', ')}',
      );
    }
    return matches.single;
  }

  Directory _speciesDirectory(ProjectWorkspace workspace) {
    return Directory(
      workspace.resolveProjectRelativePath('data/pokemon/species'),
    );
  }

  Future<Map<String, dynamic>> _readJsonFile(
    ProjectWorkspace workspace,
    String relativePath, {
    required String label,
  }) async {
    final absolutePath = workspace.resolveProjectRelativePath(relativePath);
    final file = File(absolutePath);
    if (!await file.exists()) {
      throw EditorNotFoundException('$label not found: $relativePath');
    }

    try {
      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        throw EditorPersistenceException(
          '$label is not a JSON object: $relativePath',
        );
      }
      return decoded;
    } on EditorPersistenceException {
      rethrow;
    } on FileSystemException catch (error) {
      throw EditorPersistenceException(
        'Failed to read $label at $relativePath: $error',
      );
    } on FormatException catch (error) {
      throw EditorPersistenceException(
        'Invalid JSON in $label at $relativePath: $error',
      );
    }
  }
}
```

### 12.3 `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_project_data_reader_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokemon_project_data_reader.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/seed_pokemon_demo_data_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late SeedPokemonDemoDataUseCase seedUseCase;
  late PokemonProjectDataReader reader;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('pokemon_readers_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    seedUseCase = const SeedPokemonDemoDataUseCase();
    reader = const PokemonProjectDataReader();
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('PokemonProjectDataReader', () {
    test('reads the manifest from the project workspace', () async {
      await seedUseCase.execute(workspace);

      final manifest = await reader.readManifest(workspace);

      expect(manifest.schemaVersion, 1);
      expect(manifest.kind, 'pokemon_data_manifest');
      expect(
        manifest.catalogFiles['moves'],
        'catalogs/moves.json',
      );
      expect(
        manifest.futureDataFolders['species'],
        'species/',
      );
    });

    test('reads a species file by id', () async {
      await seedUseCase.execute(workspace);

      final species = await reader.readSpeciesById(workspace, 'bulbasaur');

      expect(species.id, 'bulbasaur');
      expect(species.nationalDex, 1);
      expect(species.typing.types, <String>['grass', 'poison']);
      expect(species.learnsetRef, 'bulbasaur');
      expect(species.evolutionRef, 'bulbasaur');
      expect(species.dexContent.heightM, 0.7);
      expect(species.gameplayFlags.starterEligible, isTrue);
      expect(species.sourceMeta.seededBy, 'SeedPokemonDemoDataUseCase');
    });

    test('reads a learnset file with explicit level-up entries', () async {
      await seedUseCase.execute(workspace);

      final learnset = await reader.readLearnsetById(workspace, 'bulbasaur');

      expect(learnset.speciesId, 'bulbasaur');
      expect(learnset.startingMoves, containsAll(<String>['tackle', 'growl']));
      expect(learnset.levelUp, isNotEmpty);
      expect(learnset.levelUp.first.moveId, 'tackle');
      expect(learnset.levelUp.first.level, 1);
      expect(learnset.levelUp.first.source, 'level_up');
      expect(learnset.levelUp.first.versionGroup, 'demo');
    });

    test('reads an evolution file', () async {
      await seedUseCase.execute(workspace);

      final evolution = await reader.readEvolutionById(workspace, 'bulbasaur');

      expect(evolution.speciesId, 'bulbasaur');
      expect(evolution.preEvolution, isNull);
      expect(evolution.evolutions, hasLength(1));
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(evolution.evolutions.single.method, 'level_up');
      expect(evolution.evolutions.single.minLevel, 16);
    });

    test('reads a catalog by logical key', () async {
      await seedUseCase.execute(workspace);

      final movesCatalog = await reader.readCatalogByKey(workspace, 'moves');

      expect(movesCatalog.catalog, 'moves');
      expect(
        movesCatalog.entries.map((entry) => entry['id']).toSet(),
        containsAll(<String>{'tackle', 'growl', 'vine_whip', 'razor_leaf'}),
      );
    });

    test('lists species files from the workspace project only', () async {
      await seedUseCase.execute(workspace);

      final files = await reader.listSpeciesFiles(workspace);

      expect(
        files,
        <String>[
          'data/pokemon/species/0001-bulbasaur.json',
          'data/pokemon/species/0002-ivysaur.json',
        ],
      );
    });

    test('builds a lightweight species index with stable list data', () async {
      await seedUseCase.execute(workspace);

      final entries = await reader.listSpeciesIndexEntries(workspace);

      expect(entries, hasLength(2));

      final bulbasaur = entries.firstWhere((entry) => entry.id == 'bulbasaur');
      expect(bulbasaur.nationalDex, 1);
      expect(bulbasaur.primaryName, 'Bulbasaur');
      expect(bulbasaur.types, <String>['grass', 'poison']);
      expect(
        bulbasaur.relativePath,
        'data/pokemon/species/0001-bulbasaur.json',
      );
    });

    test('uses species id as final primary name fallback instead of filename',
        () async {
      await seedUseCase.execute(workspace);

      final customSpeciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-not-the-display-name.json',
        ),
      );
      await customSpeciesFile.writeAsString('''
{
  "id": "mystery_mon",
  "nationalDex": 9999,
  "names": {},
  "typing": {
    "types": ["grass"]
  }
}
''');

      final entries = await reader.listSpeciesIndexEntries(workspace);
      final mystery = entries.firstWhere((entry) => entry.id == 'mystery_mon');
      final species = await reader.readSpeciesById(workspace, 'mystery_mon');

      expect(mystery.primaryName, 'mystery_mon');
      expect(mystery.relativePath, 'data/pokemon/species/9999-not-the-display-name.json');
      expect(species.id, 'mystery_mon');
      expect(species.slug, isEmpty);
    });

    test('keeps species lookup coherent with the lightweight index', () async {
      await seedUseCase.execute(workspace);

      final entries = await reader.listSpeciesIndexEntries(workspace);
      final bulbasaurEntry = entries.firstWhere(
        (entry) => entry.id == 'bulbasaur',
      );
      final species = await reader.readSpeciesById(workspace, bulbasaurEntry.id);

      expect(species.id, bulbasaurEntry.id);
      expect(species.nationalDex, bulbasaurEntry.nationalDex);
      expect(species.names['en'], bulbasaurEntry.primaryName);
      expect(species.typing.types, bulbasaurEntry.types);
    });

    test('throws explicit error when species is missing', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => reader.readSpeciesById(workspace, 'venusaur'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon species not found'),
          ),
        ),
      );
    });

    test('throws explicit error when catalog key is unknown', () async {
      await seedUseCase.execute(workspace);

      expect(
        () => reader.readCatalogByKey(workspace, 'berries'),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            contains('Pokemon catalog not declared in manifest'),
          ),
        ),
      );
    });

    test('throws explicit error when json is invalid', () async {
      await seedUseCase.execute(workspace);

      final speciesFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      await speciesFile.writeAsString('{ invalid json');

      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('fails explicitly when the species projection encounters invalid json',
        () async {
      await seedUseCase.execute(workspace);

      final unrelatedBrokenFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0000-decoy.json',
        ),
      );
      await unrelatedBrokenFile.writeAsString('{ invalid json');

      expect(
        () => reader.listSpeciesIndexEntries(workspace),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Invalid JSON'),
          ),
        ),
      );
    });

    test('throws explicit error when multiple species files resolve to same id',
        () async {
      await seedUseCase.execute(workspace);

      final duplicateFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await duplicateFile.writeAsString('''
{
  "id": "bulbasaur",
  "nationalDex": 9999,
  "names": {
    "en": "Bulbasaur Duplicate"
  },
  "typing": {
    "types": ["grass"]
  }
}
''');

      expect(
        () => reader.readSpeciesById(workspace, 'bulbasaur'),
        throwsA(
          isA<EditorConflictException>().having(
            (error) => error.message,
            'message',
            contains('Multiple Pokemon species files share the same id "bulbasaur"'),
          ),
        ),
      );
    });

    test('reads from workspace root even if Directory.current points elsewhere',
        () async {
      await seedUseCase.execute(workspace);

      final decoy = await Directory.systemTemp.createTemp('pokemon_reader_decoy_');
      final originalCurrent = Directory.current;
      try {
        await Directory(
          p.join(decoy.path, 'data', 'pokemon', 'species'),
        ).create(recursive: true);
        await File(
          p.join(decoy.path, 'data', 'pokemon', 'species', '9999-decoy.json'),
        ).writeAsString('{"id":"decoy","nationalDex":9999}');

        Directory.current = decoy.path;

        final species = await reader.readSpeciesById(workspace, 'bulbasaur');
        final listed = await reader.listSpeciesFiles(workspace);
        final indexed = await reader.listSpeciesIndexEntries(workspace);

        expect(species.id, 'bulbasaur');
        expect(listed, contains('data/pokemon/species/0001-bulbasaur.json'));
        expect(listed.any((path) => path.contains('9999-decoy')), isFalse);
        expect(indexed.any((entry) => entry.id == 'decoy'), isFalse);
      } finally {
        Directory.current = originalCurrent.path;
        if (await decoy.exists()) {
          await decoy.delete(recursive: true);
        }
      }
    });

    test('leaves project.json strictly unchanged after reads', () async {
      final createProjectUseCase = CreateProjectUseCase(
        FileProjectRepository(),
        const FileProjectWorkspaceFactory(),
      );
      await createProjectUseCase.execute('Pokemon Reader Project', tempProjectRoot.path);
      await seedUseCase.execute(workspace);

      final projectFile = File(workspace.projectManifestPath);
      final before = await projectFile.readAsString();

      await reader.readManifest(workspace);
      await reader.readCatalogByKey(workspace, 'moves');
      await reader.readSpeciesById(workspace, 'bulbasaur');
      await reader.readLearnsetById(workspace, 'bulbasaur');
      await reader.readEvolutionById(workspace, 'bulbasaur');
      await reader.listSpeciesFiles(workspace);
      await reader.listSpeciesIndexEntries(workspace);

      final after = await projectFile.readAsString();
      expect(after, before);
    });
  });
}
```

## 13. Mini conclusion honnête

La base est plus propre qu’avant parce que :

- la vérité métier est maintenant portée exclusivement par le JSON ;
- la projection légère et la lecture détail sont cohérentes entre elles ;
- aucune résolution espèce ne dépend plus du nom de fichier ;
- les erreurs restent explicites.

Ce qui reste volontairement simple :

- pas de cache ;
- pas d’index persistant ;
- pas de typage profond des catalogues ;
- pas d’architecture plus large que nécessaire.

On peut maintenant reprendre la roadmap Pokédex sur une base plus saine :

- une lecture locale cohérente ;
- des invariants clairs ;
- un contrat de lecture lisible ;
- aucune magie liée au stockage physique.
