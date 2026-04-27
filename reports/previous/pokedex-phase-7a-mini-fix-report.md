# Pokédex Phase 7A — Mini-fix ciblé

## 1. Résumé exécutif honnête

Ce mini-fix ne refait pas la phase 7A. Il corrige uniquement les défauts internes restants sur les lots 28 à 33 déjà produits.

Ce qui a été corrigé :
- canonicalisation des ids internes "catalog-like" dans les convertisseurs externes ;
- unification de la convention de chemin `portrait` sur une seule vérité ;
- stabilisation déterministe des sorties pour éviter les diffs et tests fragiles ;
- exploitation des champs structurés déjà supportés par `PokemonEvolutionEntry` au lieu de tout perdre dans `conditionText`.

Ce qui n’a pas été fait volontairement :
- aucun lot 34 à 36 ;
- aucune UI ;
- aucune écriture workspace ;
- aucun réseau réel ;
- aucun widening de modèle d’évolution ;
- aucun framework générique d’import.

## 2. Liste exacte des problèmes corrigés

### 2.1 Canonicalisation des ids internes

Après audit du repo, la convention dominante pour les ids internes de référentiels est :
- lowercase ;
- `snake_case` pour les ids de type catalogue.

Cette convention a été confirmée sur les champs et exemples suivants :
- `typing.types` : `grass`, `poison`
- `abilities` : `overgrow`, `chlorophyll`
- `eggGroups` : `monster`, `grass`
- `growthRateId` : `medium_slow`
- `moveId` côté learnset : `vine_whip`, `solar_beam`, `petal_dance`

Le mini-fix réaligne donc les convertisseurs sur cette convention pour les champs réellement "catalog-like", sans toucher arbitrairement aux `speciesId` ou `formId`.

### 2.2 Convention média unifiée

Après audit du repo, la convention dominante et déjà utilisée dans le storage local / seeds / imports internes est :
- `assets/pokemon/portraits/<species>.png`
- et pour les variantes :
- `assets/pokemon/portraits/<species>/<variant>.png`

Le stub generator et ses tests ont été alignés explicitement sur cette convention unique.

### 2.3 Sorties déterministes

Le mini-fix rend déterministes les sorties pertinentes :
- entrées de catalogues triées par `id`
- `otherForms` triées
- sections du learnset triées
- évolutions directes triées
- clés de variantes média ordonnées avec variante par défaut d’abord, puis reste trié

L’objectif est purement la stabilité de sortie. Aucune sémantique métier nouvelle n’a été ajoutée.

### 2.4 Évolutions : ne pas perdre l’info structurée déjà supportée

Après audit du modèle, `PokemonEvolutionEntry` supporte déjà :
- `minLevel`
- `itemId`
- `requiredMoveId`
- `conditionText`

Le mini-fix n’élargit pas ce modèle. Il utilise simplement mieux l’existant :
- `requiredMoveId` est maintenant rempli de manière canonique quand PokeAPI le fournit ;
- les autres informations non supportées structurellement restent dans `conditionText`.

## 3. Justification fichier par fichier

### `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`

Pourquoi touché :
- c’est le convertisseur où la canonicalisation des ids internes était encore trop proche des labels display source.

Ce qui a changé :
- types, abilities, egg groups et `growthRateId` passent maintenant par une canonicalisation `snake_case` cohérente avec le repo ;
- `otherForms` est trié pour une sortie stable ;
- des commentaires expliquent explicitement pourquoi la canonicalisation ne s’applique pas aux `speciesId` / `formId`.

Pourquoi c’est minimal :
- aucune refonte du convertisseur ;
- aucune nouvelle abstraction générique ;
- seulement les champs dont la convention interne est réellement auditée.

### `packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`

Pourquoi touché :
- les catalogues externes pouvaient produire des ids non alignés sur la convention interne du repo ;
- l’ordre des entrées pouvait dépendre de l’ordre source.

Ce qui a changé :
- canonicalisation `snake_case` pour les catalogues explicitement auditables (`types`, `abilities`, `moves`, `growth_rates`, `egg_groups`) ;
- tri stable des `entries` par `id`.

Pourquoi c’est minimal :
- pas de nouvelle hiérarchie de normaliseurs ;
- juste une règle locale et documentée.

### `packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart`

Pourquoi touché :
- le learnset produit encore des `moveId` et un `source` pas totalement alignés sur la convention interne ;
- l’ordre pouvait dépendre du payload source.

Ce qui a changé :
- canonicalisation des `moveId` en `snake_case` ;
- `source` pour le level-up aligné sur `level_up` ;
- tri stable de toutes les sections utiles.

Pourquoi c’est minimal :
- aucune logique métier nouvelle ;
- seulement des règles locales de normalisation et d’ordre.

### `packages/map_editor/lib/src/application/services/pokeapi_pokemon_evolution_converter.dart`

Pourquoi touché :
- le convertisseur utilisait déjà `minLevel` et `itemId`, mais `requiredMoveId` n’était pas encore proprement canonicalisé ;
- l’ordre des évolutions directes pouvait varier.

Ce qui a changé :
- `requiredMoveId` est maintenant normalisé de manière cohérente ;
- les évolutions directes sont triées de façon stable ;
- aucun champ non supporté n’a été ajouté au modèle.

Pourquoi c’est minimal :
- pas de widening de `PokemonEvolutionEntry` ;
- pas de logique supplémentaire hors contrat actuel.

### `packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart`

Pourquoi touché :
- le mini-fix devait figer une convention média unique et stabiliser l’ordre des variantes.

Ce qui a changé :
- variante par défaut toujours en premier ;
- reste des variantes trié ;
- commentaires clarifiant la convention retenue pour `portrait`.

Pourquoi c’est minimal :
- aucune nouvelle stratégie de résolution d’assets ;
- aucune validation disque ;
- aucun changement de schéma.

### `packages/map_editor/test/showdown_pokemon_species_converter_test.dart`

Pourquoi touché :
- pour prouver la canonicalisation correcte des ids internes et le tri stable des formes.

### `packages/map_editor/test/external_pokemon_catalog_normalizer_test.dart`

Pourquoi touché :
- pour prouver la canonicalisation des ids de catalogue et le tri stable.

### `packages/map_editor/test/pokeapi_pokemon_learnset_converter_test.dart`

Pourquoi touché :
- pour prouver la canonicalisation des `moveId`, le `source` normalisé, et la stabilité des sorties malgré un ordre source non trié.

### `packages/map_editor/test/pokeapi_pokemon_evolution_converter_test.dart`

Pourquoi touché :
- pour prouver l’usage de `requiredMoveId` et l’ordre déterministe des évolutions.

### `packages/map_editor/test/pokemon_media_stub_generator_test.dart`

Pourquoi touché :
- pour verrouiller la convention `portrait` retenue ;
- pour prouver l’ordre stable des variantes.

### `reports/pokedex-phase-7a-mini-fix-report.md`

Pourquoi créé :
- pour documenter ce mini-fix de manière reviewable, avec commandes réelles, résultats réels et contenu complet des fichiers touchés.

## 4. Commandes réellement exécutées

### Audit et relecture ciblée des fichiers touchés

```bash
sed -n '1,420p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart
sed -n '1,340p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart
sed -n '1,380p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokeapi_pokemon_evolution_converter.dart
sed -n '1,280p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart
sed -n '1,280p' /Users/karim/Project/pokemonProject/packages/map_editor/test/external_pokemon_catalog_normalizer_test.dart
sed -n '1,280p' /Users/karim/Project/pokemonProject/packages/map_editor/test/showdown_pokemon_species_converter_test.dart
sed -n '1,320p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokeapi_pokemon_learnset_converter_test.dart
sed -n '1,340p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokeapi_pokemon_evolution_converter_test.dart
sed -n '1,300p' /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_media_stub_generator_test.dart
```

### Validation

```bash
dart format /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokeapi_pokemon_evolution_converter.dart /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/external_pokemon_catalog_normalizer_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/showdown_pokemon_species_converter_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokeapi_pokemon_learnset_converter_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokeapi_pokemon_evolution_converter_test.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/pokemon_media_stub_generator_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/external_pokemon_catalog_normalizer_test.dart test/showdown_pokemon_species_converter_test.dart test/pokeapi_pokemon_learnset_converter_test.dart test/pokeapi_pokemon_evolution_converter_test.dart test/pokemon_media_stub_generator_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/services/external_pokemon_catalog_normalizer.dart lib/src/application/services/showdown_pokemon_species_converter.dart lib/src/application/services/pokeapi_pokemon_learnset_converter.dart lib/src/application/services/pokeapi_pokemon_evolution_converter.dart lib/src/application/services/pokemon_media_stub_generator.dart test/external_pokemon_catalog_normalizer_test.dart test/showdown_pokemon_species_converter_test.dart test/pokeapi_pokemon_learnset_converter_test.dart test/pokeapi_pokemon_evolution_converter_test.dart test/pokemon_media_stub_generator_test.dart
```

### État Git utile en lecture seule

```bash
git status --short -- packages/map_editor/lib/src/application/services packages/map_editor/test reports
git diff --stat -- packages/map_editor/lib/src/application/services packages/map_editor/test reports
git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/services packages/map_editor/test reports
```

## 5. Résultats réels

### `dart format ...`

```text
Formatted /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/pokeapi_pokemon_evolution_converter.dart
Formatted 10 files (1 changed) in 0.02 seconds.
```

### `flutter test ...`

```text
00:02 +24: All tests passed!
```

### `flutter analyze --no-pub ...`

```text
No issues found! (ran in 1.8s)
```

## 6. État git utile

### `git status --short -- packages/map_editor/lib/src/application/services packages/map_editor/test reports`

```text
 M packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart
 M packages/map_editor/lib/src/application/services/pokeapi_pokemon_evolution_converter.dart
 M packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart
 M packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart
 M packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart
 M packages/map_editor/test/external_pokemon_catalog_normalizer_test.dart
 M packages/map_editor/test/pokeapi_pokemon_evolution_converter_test.dart
 M packages/map_editor/test/pokeapi_pokemon_learnset_converter_test.dart
 M packages/map_editor/test/pokemon_media_stub_generator_test.dart
 M packages/map_editor/test/showdown_pokemon_species_converter_test.dart
?? reports/pokedex-phase-7a-mini-fix-report.md
```

### `git diff --stat -- packages/map_editor/lib/src/application/services packages/map_editor/test reports`

```text
 .../external_pokemon_catalog_normalizer.dart       | 43 +++++++++++++-
 .../pokeapi_pokemon_evolution_converter.dart       | 45 ++++++++++++++-
 .../pokeapi_pokemon_learnset_converter.dart        | 66 ++++++++++++++++++----
 .../services/pokemon_media_stub_generator.dart     | 16 ++++--
 .../showdown_pokemon_species_converter.dart        | 53 ++++++++++++++---
 .../external_pokemon_catalog_normalizer_test.dart  | 13 +++--
 .../pokeapi_pokemon_evolution_converter_test.dart  | 48 ++++++++++++++++
 .../pokeapi_pokemon_learnset_converter_test.dart   | 25 ++++----
 .../test/pokemon_media_stub_generator_test.dart    | 15 ++++-
 .../showdown_pokemon_species_converter_test.dart   | 17 ++++--
 10 files changed, 288 insertions(+), 53 deletions(-)
```

### `git ls-files --others --exclude-standard -- packages/map_editor/lib/src/application/services packages/map_editor/test reports`

```text
reports/pokedex-phase-7a-mini-fix-report.md
```

Remarque honnête :
- `git diff --stat -- ...` ne liste pas le rapport, parce qu’il est encore non suivi ;
- c’est attendu ici, puisque ce mini-fix interdit toute écriture Git et qu’aucun `git add` n’a été exécuté.

## 7. Incidents rencontrés

- Aucun incident bloquant pendant ce mini-fix.
- L’audit a cependant montré un point honnête à signaler : un test UI hors scope utilise encore une ancienne convention de `portrait` sous `assets/pokemon/sprites/<species>/portrait.png`.
- Ce fichier n’a pas été modifié, parce que la demande encadrait explicitement ce mini-fix sur les fichiers de la phase 7A.
- Après audit, la convention dominante réelle du repo pour `portrait` reste `assets/pokemon/portraits/...`, et c’est cette convention unique qui a été retenue ici.

## 8. Limites restantes

- Le mini-fix ne cherche pas à homogénéiser tout le repo hors périmètre phase 7A.
- `itemId` côté évolution est volontairement laissé dans sa forme source existante tant qu’aucune convention interne de catalogue item clairement dominante n’a été auditée dans ce périmètre.
- Les convertisseurs restent des fondations pures : ils n’écrivent rien dans le workspace et n’orchestrent aucun import final.
- Aucun lot 34 à 36 n’a été entamé.

## 9. Contenu complet de tous les fichiers touchés

### 9.1 `packages/map_editor/lib/src/application/services/showdown_pokemon_species_converter.dart`

```dart
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
```

### 9.2 `packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Normalise des payloads de catalogues externes vers [PokemonCatalogFile].
///
/// Cette classe couvre seulement le besoin de la phase 7A :
/// - convertir des fixtures externes représentatives ;
/// - produire des catalogues internes cohérents ;
/// - rester totalement pure et locale.
///
/// Non-objectifs explicites :
/// - pas de réseau ;
/// - pas d'écriture workspace ;
/// - pas de stratégie multi-source générique ;
/// - pas de validation croisée avec les autres données Pokédex.
class ExternalPokemonCatalogNormalizer {
  const ExternalPokemonCatalogNormalizer();

  /// Convertit un payload de type "dex object" proche de Pokémon Showdown.
  ///
  /// Le contrat minimal assumé ici :
  /// - la racine est déjà un objet JSON ;
  /// - chaque entrée du payload est une map JSON ;
  /// - la clé de l'entrée sert d'identifiant par défaut si l'entrée n'en porte
  ///   pas un explicitement.
  PokemonCatalogFile normalizeShowdownCatalog({
    required String catalogKey,
    required Map<String, dynamic> payload,
  }) {
    final normalizedCatalogKey = catalogKey.trim();
    if (normalizedCatalogKey.isEmpty) {
      throw const EditorValidationException(
        'External catalog key cannot be empty',
      );
    }
    if (payload.isEmpty) {
      throw const EditorValidationException(
        'Showdown catalog payload cannot be empty',
      );
    }

    final entries = <Map<String, dynamic>>[];
    for (final rawEntry in payload.entries) {
      final normalizedId = _normalizeExternalId(rawEntry.key);
      if (normalizedId.isEmpty) {
        throw const EditorValidationException(
          'Showdown catalog entries must have a usable id',
        );
      }

      final rawValue = rawEntry.value;
      if (rawValue is! Map) {
        throw EditorPersistenceException(
          'Showdown catalog entry "$normalizedId" must be an object',
        );
      }

      final entry = _sanitizeJsonMap(
        rawValue.cast<Object?, Object?>(),
        context: 'Showdown catalog entry "$normalizedId"',
      );

      final existingId = (entry['id'] as String?)?.trim();
      entry['id'] = existingId == null || existingId.isEmpty
          ? _canonicalizeCatalogEntryId(normalizedCatalogKey, normalizedId)
          : _canonicalizeCatalogEntryId(normalizedCatalogKey, existingId);

      final existingName = (entry['name'] as String?)?.trim();
      if (existingName == null || existingName.isEmpty) {
        // On complète un nom minimal lisible quand la source n'en fournit pas.
        // Cela évite de fabriquer un catalogue interne rempli d'entrées
        // techniquement valides mais inutilisables en curation humaine.
        entry['name'] = _humanizeIdentifier(entry['id'] as String);
      }

      entries.add(entry);
    }

    entries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: normalizedCatalogKey,
      meta: PokemonDataMeta(
        description:
            'Normalized $normalizedCatalogKey catalog from Pokémon Showdown.',
        sourcePriority: const <String>['showdown', 'internal_normalized'],
        notes: const <String>[
          'Generated by the Phase 7A external catalog normalizer.',
        ],
      ),
      entries: entries,
    );
  }

  /// Convertit une réponse PokeAPI de type "named resource list".
  ///
  /// Cette forme est utile pour les référentiels qui n'ont pas besoin d'être
  /// sur-typés à ce stade : growth rates, habitats, egg groups, version groups,
  /// etc. On conserve donc un contrat volontairement petit :
  /// - `results` doit être une liste ;
  /// - chaque entrée doit fournir au moins un `name` exploitable ;
  /// - `url` est conservé comme méta-référence si disponible.
  PokemonCatalogFile normalizePokeApiNamedResourceCatalog({
    required String catalogKey,
    required Map<String, dynamic> payload,
  }) {
    final normalizedCatalogKey = catalogKey.trim();
    if (normalizedCatalogKey.isEmpty) {
      throw const EditorValidationException(
        'External catalog key cannot be empty',
      );
    }

    final rawResults = payload['results'];
    if (rawResults is! List) {
      throw const EditorPersistenceException(
        'PokeAPI catalog payload must contain a results list',
      );
    }
    if (rawResults.isEmpty) {
      throw const EditorValidationException(
        'PokeAPI catalog results cannot be empty',
      );
    }

    final entries = <Map<String, dynamic>>[];
    for (var index = 0; index < rawResults.length; index++) {
      final rawEntry = rawResults[index];
      if (rawEntry is! Map) {
        throw EditorPersistenceException(
          'PokeAPI catalog result at index $index must be an object',
        );
      }

      final entry = rawEntry.cast<Object?, Object?>();
      final name = (entry['name'] as String?)?.trim() ?? '';
      if (name.isEmpty) {
        throw EditorValidationException(
          'PokeAPI catalog result at index $index must define a name',
        );
      }

      final url = (entry['url'] as String?)?.trim();
      final normalizedId =
          _canonicalizeCatalogEntryId(normalizedCatalogKey, name);
      entries.add(
        <String, dynamic>{
          'id': normalizedId,
          'name': _humanizeIdentifier(name),
          if (url != null && url.isNotEmpty) 'sourceUrl': url,
        },
      );
    }

    entries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: normalizedCatalogKey,
      meta: PokemonDataMeta(
        description:
            'Normalized $normalizedCatalogKey catalog from PokeAPI resources.',
        sourcePriority: const <String>['pokeapi', 'internal_normalized'],
        notes: const <String>[
          'Generated by the Phase 7A external catalog normalizer.',
        ],
      ),
      entries: entries,
    );
  }

  Map<String, dynamic> _sanitizeJsonMap(
    Map<Object?, Object?> raw, {
    required String context,
  }) {
    final sanitized = <String, dynamic>{};
    for (final entry in raw.entries) {
      final key = entry.key;
      if (key is! String) {
        throw EditorPersistenceException('$context contains a non-string key');
      }
      sanitized[key] = _sanitizeJsonValue(
        entry.value,
        context: '$context.$key',
      );
    }
    return sanitized;
  }

  Object? _sanitizeJsonValue(
    Object? value, {
    required String context,
  }) {
    if (value == null || value is String || value is num || value is bool) {
      return value;
    }
    if (value is List) {
      return value
          .map(
            (entry) => _sanitizeJsonValue(
              entry,
              context: '$context[]',
            ),
          )
          .toList(growable: false);
    }
    if (value is Map) {
      return _sanitizeJsonMap(
        value.cast<Object?, Object?>(),
        context: context,
      );
    }

    throw EditorPersistenceException(
      '$context contains a non-JSON value of type ${value.runtimeType}',
    );
  }

  String _normalizeExternalId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    return trimmed.replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
  }

  String _canonicalizeCatalogEntryId(String catalogKey, String raw) {
    final trimmedCatalogKey = catalogKey.trim().toLowerCase();
    if (_snakeCaseCatalogKeys.contains(trimmedCatalogKey)) {
      return _normalizeSnakeCaseId(raw);
    }
    return _normalizeExternalId(raw);
  }

  String _normalizeSnakeCaseId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final separated = trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }

  String _humanizeIdentifier(String identifier) {
    final spaced = identifier.replaceAll(RegExp(r'[_-]+'), ' ').trim();
    if (spaced.isEmpty) return identifier;
    return spaced
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  static const Set<String> _snakeCaseCatalogKeys = <String>{
    'types',
    'abilities',
    'moves',
    'growth_rates',
    'egg_groups',
  };
}
```

### 9.3 `packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit un payload PokeAPI de type `/pokemon/{id}` vers
/// [PokemonLearnsetFile].
///
/// Cette fondation couvre uniquement le lot 31 :
/// - lecture des méthodes d'apprentissage exposées par PokeAPI ;
/// - mapping vers les familles de learnset déjà existantes ;
/// - aucun accès réseau ;
/// - aucune écriture locale.
///
/// Décisions assumées :
/// - `level-up` alimente `levelUp` ;
/// - les moves niveau 1 alimentent aussi `startingMoves` et `relearnMoves` ;
/// - `machine`, `tutor` et `egg` sont mappés directement ;
/// - les méthodes spéciales héritées/spin-off sont repliées vers `event` ;
/// - les méthodes inconnues restantes sont repliées vers `transfer`.
class PokeApiPokemonLearnsetConverter {
  const PokeApiPokemonLearnsetConverter();

  PokemonLearnsetFile convert({
    required String speciesId,
    required Map<String, dynamic> payload,
  }) {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'PokeAPI learnset speciesId cannot be empty',
      );
    }

    final rawMoves = payload['moves'];
    if (rawMoves is! List) {
      throw const EditorPersistenceException(
        'PokeAPI learnset payload must contain a moves list',
      );
    }

    final startingMoves = <String>{};
    final relearnMoves = <String>{};
    final levelUp = <PokemonLearnsetLevelUpEntry>[];
    final tm = <PokemonLearnsetMoveEntry>[];
    final tutor = <PokemonLearnsetMoveEntry>[];
    final egg = <PokemonLearnsetMoveEntry>[];
    final event = <PokemonLearnsetMoveEntry>[];
    final transfer = <PokemonLearnsetMoveEntry>[];

    final moveEntryKeys = <String>{};
    final levelUpKeys = <String>{};

    for (var moveIndex = 0; moveIndex < rawMoves.length; moveIndex++) {
      final rawMoveEntry = rawMoves[moveIndex];
      if (rawMoveEntry is! Map) {
        throw EditorPersistenceException(
          'PokeAPI move entry at index $moveIndex must be an object',
        );
      }

      final moveEntry = rawMoveEntry.cast<String, dynamic>();
      final moveId = _readNamedResourceId(
        moveEntry['move'],
        field: 'moves[$moveIndex].move',
        canonicalizeSnakeCase: true,
      );

      final rawDetails = moveEntry['version_group_details'];
      if (rawDetails is! List) {
        throw EditorPersistenceException(
          'PokeAPI move entry "$moveId" must contain version_group_details',
        );
      }

      for (var detailIndex = 0;
          detailIndex < rawDetails.length;
          detailIndex++) {
        final rawDetail = rawDetails[detailIndex];
        if (rawDetail is! Map) {
          throw EditorPersistenceException(
            'PokeAPI version detail at moves[$moveIndex].version_group_details'
            '[$detailIndex] must be an object',
          );
        }

        final detail = rawDetail.cast<String, dynamic>();
        final method = _readNamedResourceId(
          detail['move_learn_method'],
          field:
              'moves[$moveIndex].version_group_details[$detailIndex].move_learn_method',
        );
        final versionGroup = _readNamedResourceId(
          detail['version_group'],
          field:
              'moves[$moveIndex].version_group_details[$detailIndex].version_group',
        );
        final level = _readOptionalInt(detail['level_learned_at']) ?? 0;

        switch (method) {
          case 'level-up':
            final levelKey = '$moveId|$versionGroup|$level';
            if (levelUpKeys.add(levelKey)) {
              levelUp.add(
                PokemonLearnsetLevelUpEntry(
                  moveId: moveId,
                  level: level <= 0 ? 1 : level,
                  source: 'level_up',
                  versionGroup: versionGroup,
                ),
              );
            }

            if (level <= 1) {
              startingMoves.add(moveId);
              relearnMoves.add(moveId);
            }
            break;
          case 'machine':
            _addMoveEntry(
              target: tm,
              keys: moveEntryKeys,
              bucket: 'tm',
              moveId: moveId,
              versionGroup: versionGroup,
            );
            break;
          case 'tutor':
            _addMoveEntry(
              target: tutor,
              keys: moveEntryKeys,
              bucket: 'tutor',
              moveId: moveId,
              versionGroup: versionGroup,
            );
            break;
          case 'egg':
            _addMoveEntry(
              target: egg,
              keys: moveEntryKeys,
              bucket: 'egg',
              moveId: moveId,
              versionGroup: versionGroup,
            );
            break;
          default:
            if (_isEventLikeMethod(method)) {
              _addMoveEntry(
                target: event,
                keys: moveEntryKeys,
                bucket: 'event',
                moveId: moveId,
                versionGroup: versionGroup,
              );
            } else {
              _addMoveEntry(
                target: transfer,
                keys: moveEntryKeys,
                bucket: 'transfer',
                moveId: moveId,
                versionGroup: versionGroup,
              );
            }
            break;
        }
      }
    }

    final learnset = PokemonLearnsetFile(
      speciesId: normalizedSpeciesId,
      // On stabilise explicitement l'ordre de sortie pour éviter les diffs
      // parasites et les tests fragiles quand l'ordre source varie.
      startingMoves: (startingMoves.toList(growable: false)..sort()),
      relearnMoves: (relearnMoves.toList(growable: false)..sort()),
      levelUp: _sortLevelUp(levelUp),
      tm: _sortMoveEntries(tm),
      tutor: _sortMoveEntries(tutor),
      egg: _sortMoveEntries(egg),
      event: _sortMoveEntries(event),
      transfer: _sortMoveEntries(transfer),
    );

    _validateLearnset(learnset);
    return learnset;
  }

  void _addMoveEntry({
    required List<PokemonLearnsetMoveEntry> target,
    required Set<String> keys,
    required String bucket,
    required String moveId,
    required String versionGroup,
  }) {
    final key = '$bucket|$moveId|$versionGroup';
    if (!keys.add(key)) {
      return;
    }

    target.add(
      PokemonLearnsetMoveEntry(
        moveId: moveId,
        versionGroup: versionGroup,
      ),
    );
  }

  bool _isEventLikeMethod(String method) {
    return method.contains('egg') ||
        method.contains('stadium') ||
        method.contains('colosseum') ||
        method.contains('xd') ||
        method.contains('form-change') ||
        method.contains('zygarde');
  }

  void _validateLearnset(PokemonLearnsetFile learnset) {
    final hasAnySection = learnset.startingMoves.isNotEmpty ||
        learnset.relearnMoves.isNotEmpty ||
        learnset.levelUp.isNotEmpty ||
        learnset.tm.isNotEmpty ||
        learnset.tutor.isNotEmpty ||
        learnset.egg.isNotEmpty ||
        learnset.event.isNotEmpty ||
        learnset.transfer.isNotEmpty;

    if (!hasAnySection) {
      throw const EditorValidationException(
        'PokeAPI learnset payload produced no usable move data',
      );
    }
  }

  List<PokemonLearnsetLevelUpEntry> _sortLevelUp(
    List<PokemonLearnsetLevelUpEntry> entries,
  ) {
    final sorted = List<PokemonLearnsetLevelUpEntry>.from(entries);
    sorted.sort((left, right) {
      final levelCompare = left.level.compareTo(right.level);
      if (levelCompare != 0) return levelCompare;

      final moveCompare = left.moveId.compareTo(right.moveId);
      if (moveCompare != 0) return moveCompare;

      final versionCompare = left.versionGroup.compareTo(right.versionGroup);
      if (versionCompare != 0) return versionCompare;

      return left.source.compareTo(right.source);
    });
    return sorted;
  }

  List<PokemonLearnsetMoveEntry> _sortMoveEntries(
    List<PokemonLearnsetMoveEntry> entries,
  ) {
    final sorted = List<PokemonLearnsetMoveEntry>.from(entries);
    sorted.sort((left, right) {
      final moveCompare = left.moveId.compareTo(right.moveId);
      if (moveCompare != 0) return moveCompare;
      return left.versionGroup.compareTo(right.versionGroup);
    });
    return sorted;
  }

  String _readNamedResourceId(
    Object? raw, {
    required String field,
    bool canonicalizeSnakeCase = false,
  }) {
    if (raw is! Map) {
      throw EditorPersistenceException(
        'PokeAPI field "$field" must be a named resource object',
      );
    }

    final name = (raw['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw EditorValidationException(
        'PokeAPI field "$field" must define a non-empty name',
      );
    }
    if (!canonicalizeSnakeCase) {
      return name;
    }

    return _normalizeSnakeCaseId(name);
  }

  int? _readOptionalInt(Object? raw) {
    return (raw as num?)?.toInt();
  }

  String _normalizeSnakeCaseId(String raw) {
    final trimmed = raw.trim().toLowerCase();
    if (trimmed.isEmpty) return '';
    final separated = trimmed.replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }
}
```

### 9.4 `packages/map_editor/lib/src/application/services/pokeapi_pokemon_evolution_converter.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit une payload PokeAPI de type `/evolution-chain/{id}` vers
/// [PokemonEvolutionFile] pour une espèce donnée.
///
/// Cette fondation couvre seulement le lot 32 :
/// - parcours d'une chaîne d'évolution locale ;
/// - extraction de la pré-évolution et des évolutions directes ;
/// - mapping vers le contrat interne existant.
///
/// Non-objectifs explicites :
/// - pas de réseau ;
/// - pas d'écriture workspace ;
/// - pas de modélisation exhaustive de toutes les conditions PokeAPI.
class PokeApiPokemonEvolutionConverter {
  const PokeApiPokemonEvolutionConverter();

  PokemonEvolutionFile convert({
    required String speciesId,
    required Map<String, dynamic> payload,
  }) {
    final normalizedSpeciesId = speciesId.trim();
    if (normalizedSpeciesId.isEmpty) {
      throw const EditorValidationException(
        'PokeAPI evolution speciesId cannot be empty',
      );
    }

    final rawChain = payload['chain'];
    if (rawChain is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI evolution payload must contain a chain object',
      );
    }

    final located = _findChainNode(
      rawChain.cast<String, dynamic>(),
      targetSpeciesId: normalizedSpeciesId,
      parentSpeciesId: null,
    );

    if (located == null) {
      throw EditorValidationException(
        'PokeAPI evolution chain does not include species "$normalizedSpeciesId"',
      );
    }

    final evolutions = <PokemonEvolutionEntry>[];
    final rawChildren = located.node['evolves_to'];
    if (rawChildren is! List) {
      throw const EditorPersistenceException(
        'PokeAPI evolution chain nodes must contain an evolves_to list',
      );
    }

    for (var childIndex = 0; childIndex < rawChildren.length; childIndex++) {
      final rawChild = rawChildren[childIndex];
      if (rawChild is! Map) {
        throw EditorPersistenceException(
          'PokeAPI evolution child at index $childIndex must be an object',
        );
      }
      final child = rawChild.cast<String, dynamic>();
      final targetSpeciesId = _readNamedResourceId(
        child['species'],
        field: 'chain.evolves_to[$childIndex].species',
      );

      final rawDetails = child['evolution_details'];
      if (rawDetails is! List) {
        throw EditorPersistenceException(
          'PokeAPI evolution child "$targetSpeciesId" must define '
          'evolution_details',
        );
      }

      if (rawDetails.isEmpty) {
        evolutions.add(
          PokemonEvolutionEntry(
            targetSpeciesId: targetSpeciesId,
            method: 'unknown',
            conditionText: const <String, String>{
              'en': 'Evolution condition unspecified in source payload.',
            },
          ),
        );
        continue;
      }

      for (var detailIndex = 0;
          detailIndex < rawDetails.length;
          detailIndex++) {
        final rawDetail = rawDetails[detailIndex];
        if (rawDetail is! Map) {
          throw EditorPersistenceException(
            'PokeAPI evolution detail for "$targetSpeciesId" at index '
            '$detailIndex must be an object',
          );
        }

        final detail = rawDetail.cast<String, dynamic>();
        evolutions.add(
          PokemonEvolutionEntry(
            targetSpeciesId: targetSpeciesId,
            method: _readMethod(detail),
            minLevel: (detail['min_level'] as num?)?.toInt(),
            itemId: _readOptionalNamedResourceId(detail['item']),
            // Le modèle supporte déjà `requiredMoveId`, donc on n'abandonne pas
            // cette information dans `conditionText`.
            requiredMoveId: _readOptionalMoveId(detail['known_move']),
            conditionText: _buildConditionText(detail),
          ),
        );
      }
    }

    final file = PokemonEvolutionFile(
      speciesId: normalizedSpeciesId,
      preEvolution: located.parentSpeciesId,
      evolutions: _sortEvolutions(evolutions),
    );
    _validateEvolution(file);
    return file;
  }

  _LocatedChainNode? _findChainNode(
    Map<String, dynamic> node, {
    required String targetSpeciesId,
    required String? parentSpeciesId,
  }) {
    final currentSpeciesId = _readNamedResourceId(
      node['species'],
      field: 'chain.species',
    );

    if (currentSpeciesId == targetSpeciesId) {
      return _LocatedChainNode(
        node: node,
        parentSpeciesId: parentSpeciesId,
      );
    }

    final rawChildren = node['evolves_to'];
    if (rawChildren is! List) {
      throw const EditorPersistenceException(
        'PokeAPI evolution chain nodes must contain an evolves_to list',
      );
    }

    for (final rawChild in rawChildren) {
      if (rawChild is! Map) {
        throw const EditorPersistenceException(
          'PokeAPI evolution chain child must be an object',
        );
      }

      final located = _findChainNode(
        rawChild.cast<String, dynamic>(),
        targetSpeciesId: targetSpeciesId,
        parentSpeciesId: currentSpeciesId,
      );
      if (located != null) {
        return located;
      }
    }

    return null;
  }

  String _readMethod(Map<String, dynamic> detail) {
    final trigger = _readOptionalNamedResourceId(detail['trigger']);
    if (trigger == null || trigger.isEmpty) {
      return 'unknown';
    }

    return switch (trigger) {
      'level-up' => 'level_up',
      'use-item' => 'use_item',
      _ => trigger.replaceAll('-', '_'),
    };
  }

  Map<String, String> _buildConditionText(Map<String, dynamic> detail) {
    final parts = <String>[];

    final minHappiness = (detail['min_happiness'] as num?)?.toInt();
    if (minHappiness != null) {
      parts.add('Happiness >= $minHappiness');
    }

    final minAffection = (detail['min_affection'] as num?)?.toInt();
    if (minAffection != null) {
      parts.add('Affection >= $minAffection');
    }

    final minBeauty = (detail['min_beauty'] as num?)?.toInt();
    if (minBeauty != null) {
      parts.add('Beauty >= $minBeauty');
    }

    final timeOfDay = (detail['time_of_day'] as String?)?.trim();
    if (timeOfDay != null && timeOfDay.isNotEmpty) {
      parts.add('Time: $timeOfDay');
    }

    final locationId = _readOptionalNamedResourceId(detail['location']);
    if (locationId != null && locationId.isNotEmpty) {
      parts.add('Location: $locationId');
    }

    final heldItemId = _readOptionalNamedResourceId(detail['held_item']);
    if (heldItemId != null && heldItemId.isNotEmpty) {
      parts.add('Hold item: $heldItemId');
    }

    final tradeSpeciesId =
        _readOptionalNamedResourceId(detail['trade_species']);
    if (tradeSpeciesId != null && tradeSpeciesId.isNotEmpty) {
      parts.add('Trade species: $tradeSpeciesId');
    }

    final partySpeciesId =
        _readOptionalNamedResourceId(detail['party_species']);
    if (partySpeciesId != null && partySpeciesId.isNotEmpty) {
      parts.add('Party species: $partySpeciesId');
    }

    final partyTypeId = _readOptionalNamedResourceId(detail['party_type']);
    if (partyTypeId != null && partyTypeId.isNotEmpty) {
      parts.add('Party type: $partyTypeId');
    }

    final knownMoveTypeId =
        _readOptionalNamedResourceId(detail['known_move_type']);
    if (knownMoveTypeId != null && knownMoveTypeId.isNotEmpty) {
      parts.add('Known move type: $knownMoveTypeId');
    }

    final gender = (detail['gender'] as num?)?.toInt();
    if (gender != null) {
      parts.add(
        switch (gender) {
          1 => 'Gender: female',
          2 => 'Gender: male',
          _ => 'Gender: $gender',
        },
      );
    }

    final relativePhysicalStats =
        (detail['relative_physical_stats'] as num?)?.toInt();
    if (relativePhysicalStats != null) {
      parts.add(
        switch (relativePhysicalStats) {
          1 => 'Attack greater than Defense',
          0 => 'Attack equal to Defense',
          -1 => 'Attack lower than Defense',
          _ => 'Relative physical stats: $relativePhysicalStats',
        },
      );
    }

    if (detail['needs_overworld_rain'] == true) {
      parts.add('Needs overworld rain');
    }

    if (detail['turn_upside_down'] == true) {
      parts.add('Turn system upside down');
    }

    if (parts.isEmpty) {
      return const <String, String>{};
    }

    return <String, String>{'en': parts.join('. ')};
  }

  void _validateEvolution(PokemonEvolutionFile evolution) {
    final hasPreEvolution = evolution.preEvolution != null &&
        evolution.preEvolution!.trim().isNotEmpty;
    if (!hasPreEvolution && evolution.evolutions.isEmpty) {
      throw const EditorValidationException(
        'PokeAPI evolution payload produced no usable chain data',
      );
    }
  }

  List<PokemonEvolutionEntry> _sortEvolutions(
    List<PokemonEvolutionEntry> entries,
  ) {
    final sorted = List<PokemonEvolutionEntry>.from(entries);
    sorted.sort((left, right) {
      final targetCompare =
          left.targetSpeciesId.compareTo(right.targetSpeciesId);
      if (targetCompare != 0) return targetCompare;

      final methodCompare = left.method.compareTo(right.method);
      if (methodCompare != 0) return methodCompare;

      final levelCompare =
          (left.minLevel ?? -1).compareTo(right.minLevel ?? -1);
      if (levelCompare != 0) return levelCompare;

      final itemCompare = (left.itemId ?? '').compareTo(right.itemId ?? '');
      if (itemCompare != 0) return itemCompare;

      final moveCompare =
          (left.requiredMoveId ?? '').compareTo(right.requiredMoveId ?? '');
      if (moveCompare != 0) return moveCompare;

      return (left.conditionText['en'] ?? '').compareTo(
        right.conditionText['en'] ?? '',
      );
    });
    return sorted;
  }

  String _readNamedResourceId(
    Object? raw, {
    required String field,
  }) {
    if (raw is! Map) {
      throw EditorPersistenceException(
        'PokeAPI field "$field" must be a named resource object',
      );
    }

    final name = (raw['name'] as String?)?.trim() ?? '';
    if (name.isEmpty) {
      throw EditorValidationException(
        'PokeAPI field "$field" must define a non-empty name',
      );
    }
    return name;
  }

  String? _readOptionalNamedResourceId(Object? raw) {
    if (raw == null) return null;
    if (raw is! Map) {
      throw const EditorPersistenceException(
        'PokeAPI optional named resource field must be an object',
      );
    }

    final name = (raw['name'] as String?)?.trim();
    return name == null || name.isEmpty ? null : name;
  }

  String? _readOptionalMoveId(Object? raw) {
    final name = _readOptionalNamedResourceId(raw);
    if (name == null || name.isEmpty) {
      return null;
    }
    final separated = name.toLowerCase().replaceAll(RegExp(r'[\s-]+'), '_');
    return separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
  }
}

class _LocatedChainNode {
  const _LocatedChainNode({
    required this.node,
    required this.parentSpeciesId,
  });

  final Map<String, dynamic> node;
  final String? parentSpeciesId;
}
```

### 9.5 `packages/map_editor/lib/src/application/services/pokemon_media_stub_generator.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Génère un [PokemonMediaFile] minimal cohérent à partir d'une espèce.
///
/// Ce générateur couvre uniquement le lot 33 :
/// - produire des références locales plausibles ;
/// - rester compatible avec le schéma média actuel ;
/// - ne jamais télécharger ni valider de vrais assets.
///
/// Non-objectifs explicites :
/// - pas de GIF ;
/// - pas de pipeline d'asset import ;
/// - pas de vérification disque ;
/// - pas d'enrichissement UI.
class PokemonMediaStubGenerator {
  const PokemonMediaStubGenerator();

  PokemonMediaFile createStub(PokemonSpeciesFile species) {
    final speciesId = species.id.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon media stub speciesId cannot be empty',
      );
    }

    final assetSlug =
        (species.slug.trim().isNotEmpty ? species.slug : speciesId).trim();
    final explicitFormId = species.forms.formId.trim();
    final defaultFormId = explicitFormId.isEmpty ? 'base' : explicitFormId;

    final remainingVariantIds = <String>{
      ...species.forms.otherForms
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty),
    }..remove(defaultFormId);
    final sortedRemainingVariantIds =
        remainingVariantIds.toList(growable: false)..sort();

    final variants = <String, PokemonMediaVariant>{};
    // Le form par défaut reste toujours premier ; le reste est trié pour
    // garantir une sérialisation stable.
    for (final variantId in <String>[
      defaultFormId,
      ...sortedRemainingVariantIds,
    ]) {
      variants[variantId] = _buildVariant(
        assetSlug: assetSlug,
        variantId: variantId,
        usesRootPaths: variantId == defaultFormId,
      );
    }

    return PokemonMediaFile(
      speciesId: speciesId,
      defaultFormId: defaultFormId,
      variants: variants,
    );
  }

  PokemonMediaVariant _buildVariant({
    required String assetSlug,
    required String variantId,
    required bool usesRootPaths,
  }) {
    // Le stub par défaut pointe vers le dossier racine de l'espèce.
    // Les variantes supplémentaires reçoivent un sous-dossier dédié pour
    // permettre une curation future sans casser le schéma courant.
    final spriteRoot = usesRootPaths
        ? 'assets/pokemon/sprites/$assetSlug'
        : 'assets/pokemon/sprites/$assetSlug/$variantId';
    final portraitPath = usesRootPaths
        ? 'assets/pokemon/portraits/$assetSlug.png'
        : 'assets/pokemon/portraits/$assetSlug/$variantId.png';
    final cryPath = usesRootPaths
        ? 'assets/pokemon/cries/$assetSlug.ogg'
        : 'assets/pokemon/cries/$assetSlug/$variantId.ogg';

    return PokemonMediaVariant(
      frontStatic: '$spriteRoot/front.png',
      backStatic: '$spriteRoot/back.png',
      frontShinyStatic: '$spriteRoot/front_shiny.png',
      backShinyStatic: '$spriteRoot/back_shiny.png',
      icon: '$spriteRoot/icon.png',
      party: '$spriteRoot/party.png',
      overworld: '$spriteRoot/overworld.png',
      portrait: portraitPath,
      cry: cryPath,
      animations: <String, PokemonMediaAnimationRef>{
        'battleFront': PokemonMediaAnimationRef(
          sheet: '$spriteRoot/battle_front_sheet.png',
          animationId: 'battle_front',
        ),
        'battleBack': PokemonMediaAnimationRef(
          sheet: '$spriteRoot/battle_back_sheet.png',
          animationId: 'battle_back',
        ),
      },
    );
  }
}
```

### 9.6 `packages/map_editor/test/showdown_pokemon_species_converter_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';

void main() {
  const converter = ShowdownPokemonSpeciesConverter();

  group('ShowdownPokemonSpeciesConverter', () {
    test('converts a base species core payload', () {
      final payload =
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>;

      final species = converter.convert(payload);

      expect(species.id, 'bulbasaur');
      expect(species.slug, 'bulbasaur');
      expect(species.nationalDex, 1);
      expect(species.names['en'], 'Bulbasaur');
      expect(species.typing.types, <String>['grass', 'poison']);
      expect(species.baseStats.bst, 318);
      expect(species.abilities.primary, 'overgrow');
      expect(species.abilities.hidden, 'chlorophyll');
      expect(species.breeding.eggGroups, <String>['monster', 'grass']);
      expect(species.refs.learnset, 'bulbasaur');
      expect(species.forms.isBaseForm, isTrue);
      expect(
        species.forms.otherForms,
        <String>['bulbasauralpha', 'bulbasaurmega'],
      );
      expect(species.classification.isLegendary, isFalse);
      expect(species.progression.growthRateId, 'medium_slow');
    });

    test('converts a non-base form with classification flags', () {
      final payload =
          jsonDecode(_lycanrocDuskShowdownPayload) as Map<String, dynamic>;

      final species = converter.convert(payload);

      expect(species.id, 'lycanroc-dusk');
      expect(species.forms.isBaseForm, isFalse);
      expect(species.forms.baseFormId, 'lycanroc');
      expect(species.forms.formId, 'dusk');
      expect(species.forms.formName, 'Dusk');
      expect(species.abilities.primary, 'tough_claws');
      expect(species.classification.isLegendary, isTrue);
      expect(species.classification.isMythical, isFalse);
      expect(species.classification.isObtainable, isFalse);
    });

    test('fails clearly when types are missing', () {
      final payload = jsonDecode(_bulbasaurShowdownPayload)
          as Map<String, dynamic>
        ..['types'] = <Object?>[];

      expect(
        () => converter.convert(payload),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Showdown species field "types" cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when baseStats is not an object', () {
      final payload = jsonDecode(_bulbasaurShowdownPayload)
          as Map<String, dynamic>
        ..['baseStats'] = <Object?>['not', 'a', 'map'];

      expect(
        () => converter.convert(payload),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Showdown species field "baseStats" must be an object',
          ),
        ),
      );
    });
  });
}

const String _bulbasaurShowdownPayload = '''
{
  "name": "Bulbasaur",
  "num": 1,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 45,
    "atk": 49,
    "def": 49,
    "spa": 65,
    "spd": 65,
    "spe": 45
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "genderRatio": {
    "M": 0.875,
    "F": 0.125
  },
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "color": "Green",
  "heightm": 0.7,
  "weightkg": 6.9,
  "otherFormes": ["bulbasaurmega", "bulbasauralpha"]
}
''';

const String _lycanrocDuskShowdownPayload = '''
{
  "name": "Lycanroc-Dusk",
  "species": "Lycanroc-Dusk",
  "baseSpecies": "Lycanroc",
  "forme": "Dusk",
  "num": 745,
  "gen": 7,
  "types": ["Rock"],
  "baseStats": {
    "hp": 75,
    "atk": 117,
    "def": 65,
    "spa": 55,
    "spd": 65,
    "spe": 110
  },
  "abilities": {
    "0": "Tough Claws"
  },
  "isNonstandard": "Unobtainable",
  "tags": ["Legendary"]
}
''';
```

### 9.7 `packages/map_editor/test/external_pokemon_catalog_normalizer_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/external_pokemon_catalog_normalizer.dart';

void main() {
  const normalizer = ExternalPokemonCatalogNormalizer();

  group('ExternalPokemonCatalogNormalizer', () {
    test('normalizes a Showdown-style catalog payload', () {
      final payload = jsonDecode(_showdownMovesPayload) as Map<String, dynamic>;

      final catalog = normalizer.normalizeShowdownCatalog(
        catalogKey: 'moves',
        payload: payload,
      );

      expect(catalog.catalog, 'moves');
      expect(catalog.kind, 'pokemon_catalog');
      expect(catalog.meta.sourcePriority, contains('showdown'));
      expect(catalog.entries, hasLength(2));
      expect(catalog.entries.first['id'], 'growl');
      expect(catalog.entries.first['name'], 'Growl');
      expect(catalog.entries.last['id'], 'tackle');
    });

    test('normalizes a PokeAPI named resource list payload', () {
      final payload =
          jsonDecode(_pokeApiGrowthRatesPayload) as Map<String, dynamic>;

      final catalog = normalizer.normalizePokeApiNamedResourceCatalog(
        catalogKey: 'growth_rates',
        payload: payload,
      );

      expect(catalog.catalog, 'growth_rates');
      expect(catalog.kind, 'pokemon_catalog');
      expect(catalog.meta.sourcePriority, contains('pokeapi'));
      expect(catalog.entries, hasLength(2));
      expect(catalog.entries.first, <String, dynamic>{
        'id': 'fast',
        'name': 'Fast',
        'sourceUrl': 'https://pokeapi.co/api/v2/growth-rate/2/',
      });
      expect(catalog.entries.last, <String, dynamic>{
        'id': 'medium_slow',
        'name': 'Medium Slow',
        'sourceUrl': 'https://pokeapi.co/api/v2/growth-rate/4/',
      });
    });

    test('fails clearly when the external catalog key is empty', () {
      final payload = jsonDecode(_showdownMovesPayload) as Map<String, dynamic>;

      expect(
        () => normalizer.normalizeShowdownCatalog(
          catalogKey: '   ',
          payload: payload,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'External catalog key cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when the Showdown payload is empty', () {
      expect(
        () => normalizer.normalizeShowdownCatalog(
          catalogKey: 'moves',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Showdown catalog payload cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when a Showdown entry is not an object', () {
      expect(
        () => normalizer.normalizeShowdownCatalog(
          catalogKey: 'moves',
          payload: const <String, dynamic>{
            'tackle': 'not-an-object',
          },
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'Showdown catalog entry "tackle" must be an object',
          ),
        ),
      );
    });

    test('fails clearly when PokeAPI results are missing', () {
      expect(
        () => normalizer.normalizePokeApiNamedResourceCatalog(
          catalogKey: 'growth_rates',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'PokeAPI catalog payload must contain a results list',
          ),
        ),
      );
    });

    test('fails clearly when a PokeAPI result has no name', () {
      expect(
        () => normalizer.normalizePokeApiNamedResourceCatalog(
          catalogKey: 'growth_rates',
          payload: const <String, dynamic>{
            'results': <Object?>[
              <String, Object?>{'name': ' ', 'url': 'https://pokeapi.co/foo'},
            ],
          },
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI catalog result at index 0 must define a name',
          ),
        ),
      );
    });
  });
}

const String _showdownMovesPayload = '''
{
  "tackle": {
    "name": "Tackle",
    "type": "Normal",
    "category": "Physical",
    "power": 40,
    "accuracy": 100,
    "pp": 35
  },
  "growl": {
    "type": "Normal",
    "category": "Status",
    "power": null,
    "accuracy": 100,
    "pp": 40
  }
}
''';

const String _pokeApiGrowthRatesPayload = '''
{
  "count": 2,
  "results": [
    {
      "name": "medium-slow",
      "url": "https://pokeapi.co/api/v2/growth-rate/4/"
    },
    {
      "name": "fast",
      "url": "https://pokeapi.co/api/v2/growth-rate/2/"
    }
  ]
}
''';
```

### 9.8 `packages/map_editor/test/pokeapi_pokemon_learnset_converter_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';

void main() {
  const converter = PokeApiPokemonLearnsetConverter();

  group('PokeApiPokemonLearnsetConverter', () {
    test('converts a representative PokeAPI learnset payload', () {
      final payload =
          jsonDecode(_bulbasaurLearnsetPayload) as Map<String, dynamic>;

      final learnset = converter.convert(
        speciesId: 'bulbasaur',
        payload: payload,
      );

      expect(learnset.speciesId, 'bulbasaur');
      expect(learnset.startingMoves, <String>['growl', 'tackle']);
      expect(learnset.relearnMoves, <String>['growl', 'tackle']);
      expect(
        learnset.levelUp.map((entry) => entry.moveId).toList(growable: false),
        <String>['growl', 'tackle', 'vine_whip'],
      );
      expect(learnset.levelUp.first.source, 'level_up');
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(learnset.tutor.single.moveId, 'seed_bomb');
      expect(learnset.egg.single.moveId, 'petal_dance');
      expect(learnset.event.single.moveId, 'celebrate');
      expect(learnset.transfer.single.moveId, 'cut');
    });

    test('fails clearly when speciesId is empty', () {
      final payload =
          jsonDecode(_bulbasaurLearnsetPayload) as Map<String, dynamic>;

      expect(
        () => converter.convert(
          speciesId: '   ',
          payload: payload,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI learnset speciesId cannot be empty',
          ),
        ),
      );
    });

    test('fails clearly when moves are missing', () {
      expect(
        () => converter.convert(
          speciesId: 'bulbasaur',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'PokeAPI learnset payload must contain a moves list',
          ),
        ),
      );
    });

    test('fails clearly when no usable move data is produced', () {
      expect(
        () => converter.convert(
          speciesId: 'bulbasaur',
          payload: const <String, dynamic>{'moves': <Object?>[]},
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI learnset payload produced no usable move data',
          ),
        ),
      );
    });
  });
}

const String _bulbasaurLearnsetPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "vine-whip"},
      "version_group_details": [
        {
          "level_learned_at": 7,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "tackle"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "growl"},
      "version_group_details": [
        {
          "level_learned_at": 1,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "solar-beam"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "seed-bomb"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "tutor"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "petal-dance"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "egg"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "celebrate"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "form-change"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    },
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "unknown-method"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';
```

### 9.9 `packages/map_editor/test/pokeapi_pokemon_evolution_converter_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_evolution_converter.dart';

void main() {
  const converter = PokeApiPokemonEvolutionConverter();

  group('PokeApiPokemonEvolutionConverter', () {
    test('converts a direct evolution chain slice for a species', () {
      final payload =
          jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>;

      final evolution = converter.convert(
        speciesId: 'bulbasaur',
        payload: payload,
      );

      expect(evolution.speciesId, 'bulbasaur');
      expect(evolution.preEvolution, isNull);
      expect(evolution.evolutions, hasLength(1));
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(evolution.evolutions.single.method, 'level_up');
      expect(evolution.evolutions.single.minLevel, 16);
    });

    test('captures preEvolution and textual conditions for child species', () {
      final payload =
          jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>;

      final evolution = converter.convert(
        speciesId: 'ivysaur',
        payload: payload,
      );

      expect(evolution.preEvolution, 'bulbasaur');
      expect(evolution.evolutions.single.targetSpeciesId, 'venusaur');
      expect(evolution.evolutions.single.method, 'use_item');
      expect(evolution.evolutions.single.itemId, 'leaf-stone');
      expect(evolution.evolutions.single.requiredMoveId, 'solar_beam');
      expect(
        evolution.evolutions.single.conditionText['en'],
        contains('Location: special-garden'),
      );
    });

    test('sorts direct evolutions deterministically', () {
      final payload =
          jsonDecode(_branchingEvolutionChainPayload) as Map<String, dynamic>;

      final evolution = converter.convert(
        speciesId: 'eevee',
        payload: payload,
      );

      expect(
        evolution.evolutions.map((entry) => entry.targetSpeciesId).toList(),
        <String>['jolteon', 'vaporeon'],
      );
    });

    test('fails clearly when the chain object is missing', () {
      expect(
        () => converter.convert(
          speciesId: 'bulbasaur',
          payload: const <String, dynamic>{},
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            'PokeAPI evolution payload must contain a chain object',
          ),
        ),
      );
    });

    test('fails clearly when the species is absent from the chain', () {
      final payload =
          jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>;

      expect(
        () => converter.convert(
          speciesId: 'charmander',
          payload: payload,
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'PokeAPI evolution chain does not include species "charmander"',
          ),
        ),
      );
    });
  });
}

const String _bulbasaurEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "bulbasaur"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "ivysaur"},
        "evolution_details": [
          {
            "trigger": {"name": "level-up"},
            "min_level": 16
          }
        ],
        "evolves_to": [
          {
            "species": {"name": "venusaur"},
            "evolution_details": [
              {
                "trigger": {"name": "use-item"},
                "item": {"name": "leaf-stone"},
                "known_move": {"name": "solar-beam"},
                "location": {"name": "special-garden"}
              }
            ],
            "evolves_to": []
          }
        ]
      }
    ]
  }
}
''';

const String _branchingEvolutionChainPayload = '''
{
  "chain": {
    "species": {"name": "eevee"},
    "evolution_details": [],
    "evolves_to": [
      {
        "species": {"name": "vaporeon"},
        "evolution_details": [
          {
            "trigger": {"name": "use-item"},
            "item": {"name": "water-stone"}
          }
        ],
        "evolves_to": []
      },
      {
        "species": {"name": "jolteon"},
        "evolution_details": [
          {
            "trigger": {"name": "use-item"},
            "item": {"name": "thunder-stone"}
          }
        ],
        "evolves_to": []
      }
    ]
  }
}
''';
```

### 9.10 `packages/map_editor/test/pokemon_media_stub_generator_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/pokemon_media_stub_generator.dart';

void main() {
  const generator = PokemonMediaStubGenerator();

  group('PokemonMediaStubGenerator', () {
    test('generates a base media stub with default animation refs', () {
      final media = generator.createStub(_baseSpecies);

      expect(media.speciesId, 'bulbasaur');
      expect(media.defaultFormId, 'base');
      expect(media.variants.keys, contains('base'));
      expect(
        media.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(
        media.variants['base']?.animations['battleFront']?.animationId,
        'battle_front',
      );
    });

    test('generates extra variants for declared forms', () {
      final media = generator.createStub(_speciesWithForms);

      expect(media.defaultFormId, 'base');
      expect(
        media.variants.keys.toList(growable: false),
        <String>['base', 'alpha', 'mega'],
      );
      expect(
        media.variants['mega']?.frontStatic,
        'assets/pokemon/sprites/venusaur/mega/front.png',
      );
      expect(
        media.variants['mega']?.portrait,
        'assets/pokemon/portraits/venusaur/mega.png',
      );
    });

    test('uses the species formId as defaultFormId for non-base forms', () {
      final media = generator.createStub(_formSpecies);

      expect(media.defaultFormId, 'dusk');
      expect(
        media.variants['dusk']?.frontStatic,
        'assets/pokemon/sprites/lycanrocdusk/front.png',
      );
    });

    test('fails clearly when species id is empty', () {
      expect(
        () => generator.createStub(
          const PokemonSpeciesFile(
            id: ' ',
            slug: '',
            nationalDex: 0,
            names: <String, String>{},
            speciesName: <String, String>{},
            genIntroduced: 0,
            typing: PokemonSpeciesTyping(),
            baseStats: PokemonSpeciesBaseStats(
              hp: 0,
              atk: 0,
              def: 0,
              spa: 0,
              spd: 0,
              spe: 0,
              bst: 0,
            ),
            abilities: PokemonSpeciesAbilities(primary: ''),
            breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
            progression: PokemonSpeciesProgression(
              growthRateId: '',
              baseExp: 0,
              catchRate: 0,
              baseFriendship: 0,
            ),
            refs: PokemonSpeciesRefs(
              learnset: '',
              evolution: '',
              media: '',
            ),
            dexContent: PokemonSpeciesDexContent(),
            gameplayFlags: PokemonSpeciesGameplayFlags(),
            sourceMeta: PokemonSpeciesSourceMeta(),
          ),
        ),
        throwsA(
          isA<EditorValidationException>().having(
            (error) => error.message,
            'message',
            'Pokemon media stub speciesId cannot be empty',
          ),
        ),
      );
    });
  });
}

const PokemonSpeciesFile _baseSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 45,
    atk: 49,
    def: 49,
    spa: 65,
    spd: 65,
    spe: 45,
    bst: 318,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'overgrow'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: '',
    baseExp: 0,
    catchRate: 0,
    baseFriendship: 0,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur',
    evolution: 'bulbasaur',
    media: 'bulbasaur',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);

const PokemonSpeciesFile _speciesWithForms = PokemonSpeciesFile(
  id: 'venusaur',
  slug: 'venusaur',
  nationalDex: 3,
  names: <String, String>{'en': 'Venusaur'},
  speciesName: <String, String>{},
  genIntroduced: 1,
  typing: PokemonSpeciesTyping(types: <String>['grass', 'poison']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 80,
    atk: 82,
    def: 83,
    spa: 100,
    spd: 100,
    spe: 80,
    bst: 525,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'overgrow'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: '',
    baseExp: 0,
    catchRate: 0,
    baseFriendship: 0,
  ),
  forms: PokemonSpeciesForms(
    baseFormId: '',
    isBaseForm: true,
    otherForms: <String>['mega', 'alpha'],
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'venusaur',
    evolution: 'venusaur',
    media: 'venusaur',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);

const PokemonSpeciesFile _formSpecies = PokemonSpeciesFile(
  id: 'lycanrocdusk',
  slug: 'lycanrocdusk',
  nationalDex: 745,
  names: <String, String>{'en': 'Lycanroc-Dusk'},
  speciesName: <String, String>{},
  genIntroduced: 7,
  typing: PokemonSpeciesTyping(types: <String>['rock']),
  baseStats: PokemonSpeciesBaseStats(
    hp: 75,
    atk: 117,
    def: 65,
    spa: 55,
    spd: 65,
    spe: 110,
    bst: 487,
  ),
  abilities: PokemonSpeciesAbilities(primary: 'tough-claws'),
  breeding: PokemonSpeciesBreeding(genderRatio: <String, double>{}),
  progression: PokemonSpeciesProgression(
    growthRateId: '',
    baseExp: 0,
    catchRate: 0,
    baseFriendship: 0,
  ),
  forms: PokemonSpeciesForms(
    baseFormId: 'lycanroc',
    isBaseForm: false,
    formId: 'dusk',
    formName: 'Dusk',
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'lycanrocdusk',
    evolution: 'lycanrocdusk',
    media: 'lycanrocdusk',
  ),
  dexContent: PokemonSpeciesDexContent(),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(),
);
```

### 9.11 `reports/pokedex-phase-7a-mini-fix-report.md`

Le contenu complet de ce fichier est le document que tu es en train de lire.

## 10. Checklist d’autocontrôle finale

- [x] Je n’ai pas commencé les lots 34 à 36
- [x] Je n’ai ajouté aucune UI
- [x] Je n’ai ajouté aucun provider/notifier/state UI
- [x] Je n’ai pas touché `project.json`
- [x] Je n’ai pas créé de framework générique spéculatif
- [x] J’ai audité la convention d’ids interne réelle avant de modifier
- [x] J’ai audité la convention de chemins média réelle avant de modifier
- [x] J’ai unifié la canonicalisation des ids là où c’était nécessaire
- [x] J’ai unifié la convention média sur une seule vérité
- [x] J’ai rendu les sorties pertinentes déterministes
- [x] J’ai vérifié les champs structurés déjà supportés pour les évolutions
- [x] Je n’ai pas élargi le modèle d’évolution sans nécessité absolue
- [x] J’ai ajouté des tests ciblés utiles
- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Je n’ai exécuté aucune commande Git d’écriture
- [x] Le rapport final contient le contenu complet de tous les fichiers touchés
