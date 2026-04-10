# Récapitulatif Complet Phase 5 Pokédex

## Résumé exécutif

Cette phase 5 couvre les lots **17 à 22** du chantier Pokédex côté éditeur.

Le but atteint est le suivant :

- on peut sélectionner une espèce depuis la liste ;
- on peut afficher une fiche détail en lecture seule ;
- cette fiche est découpée en cinq vues :
  - `Overview`
  - `Formes`
  - `Learnset`
  - `Évolutions`
  - `Médias`
- on reste strictement en lecture locale ;
- on ne touche ni à `project.json`, ni à l’import, ni aux overrides, ni au runtime.

Point important :

- ce rapport inclut **tout le code réellement produit pour la phase 5** ;
- pour les **nouveaux fichiers**, le contenu est inclus **en entier** ;
- pour les **gros fichiers déjà existants**, le rapport inclut **les sections de code effectivement ajoutées ou modifiées par la phase 5**, pas les milliers de lignes préexistantes restées intactes.

## Convention d’inclusion du code

Ce point est important, donc je le rends explicite.

Quand je dis que le rapport inclut **tout le code de la phase 5**, cela veut dire :

- tous les **nouveaux fichiers** créés pendant la phase 5 sont inclus **intégralement** ;
- dans les **fichiers déjà existants avant la phase 5**, le rapport inclut **toutes les lignes réellement écrites ou modifiées** pour cette phase ;
- aucune logique phase 5 n’est omise ;
- en revanche, je ne redéverse pas dans le rapport les longues portions de fichiers préexistantes qui n’ont pas été touchées par cette phase, car ce ne serait pas “du code de la phase 5”, mais du bruit documentaire.

Autrement dit :

- **nouveau fichier créé pendant la phase 5** = contenu complet ;
- **fichier partagé avec du code plus ancien** = toutes les sections produites par la phase 5, et uniquement elles.

Cette convention est volontaire :

- elle garde le rapport fidèle à ce qui a réellement été produit ;
- elle évite de faire croire que des milliers de lignes historiques non modifiées ont été “faites” pendant cette phase ;
- elle rend le document beaucoup plus utile pour review, reprise et audit.

## Périmètre de la phase 5

### Inclus

- lot 17 : sélection locale d’une espèce
- lot 18 : vue détail overview
- lot 19 : vue formes / classification
- lot 20 : vue learnset
- lot 21 : vue évolutions
- lot 22 : vue médias

### Exclu volontairement

- import interne
- import externe
- overrides / curation locale
- édition des données
- runtime gameplay
- save / owned pokemon
- logique de combat

## Lots couverts

### Lot 17 — Sélectionner une espèce depuis la liste

Ce qui a été fait :

- ajout d’un état local de sélection dans le workspace ;
- ajout d’une ligne sélectionnable avec clé stable `pokedex-row-<id>` ;
- ajout d’un panneau détail vide tant qu’aucune espèce n’est sélectionnée.

Résultat :

- la liste Pokédex n’est plus seulement passive ;
- la notion d’“espèce courante” existe maintenant côté UI locale ;
- aucune édition n’est introduite.

### Lot 18 — Vue détail overview

Ce qui a été fait :

- création d’un agrégat `PokedexSpeciesDetail` ;
- création d’un use case `LoadPokedexSpeciesDetailUseCase` ;
- ajout d’un panneau `Overview` qui affiche :
  - identité
  - types
  - stats
  - talents
  - refs locales

Résultat :

- la fiche détail charge réellement les fichiers locaux ;
- elle ne duplique pas un format de stockage ;
- elle reste en lecture seule.

### Lot 19 — Vue formes / classification

Ce qui a été fait :

- extension légère du modèle espèce avec :
  - `PokemonSpeciesForms`
  - `PokemonSpeciesClassification`
- affichage des formes et des flags simples de classification.

Résultat :

- la fiche devient cohérente avec une espèce un peu plus riche ;
- on ne lance pas encore d’outil de curation.

### Lot 20 — Onglet Learnset

Ce qui a été fait :

- affichage des sections :
  - `startingMoves`
  - `relearnMoves`
  - `levelUp`
  - `tm`
  - `tutor`
  - `egg`
  - `event`
  - `transfer`

Résultat :

- le learnset local devient visible ;
- les niveaux et `versionGroup` sont rendus explicitement.

### Lot 21 — Onglet Évolutions

Ce qui a été fait :

- affichage de la pré-évolution ;
- affichage des évolutions suivantes ;
- affichage lisible des conditions d’évolution avec fallback sobre.

Résultat :

- la chaîne locale d’évolution est maintenant consultable ;
- aucune logique d’édition n’est introduite.

### Lot 22 — Onglet Médias

Ce qui a été fait :

- affichage des références média locales :
  - front
  - back
  - shiny
  - icon
  - party
  - portrait
  - cry
  - animations
- rappel explicite du contrat : **jamais de GIF**.

Résultat :

- la fiche Pokédex montre maintenant le contrat média réel du projet ;
- on reste sur des références locales vers `assets/pokemon/...`.

## Fichiers touchés

### Nouveaux fichiers

- `packages/map_editor/lib/src/application/models/pokedex_species_detail.dart`
- `packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart`
- `packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart`

### Fichiers modifiés

- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`

## Validations réellement exécutées

### Tests

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && \
flutter test \
  test/load_pokedex_species_detail_use_case_test.dart \
  test/pokedex_workspace_ui_test.dart \
  test/list_pokedex_entries_use_case_test.dart \
  test/pokemon_database_index_test.dart
```

Résultat :

- `All tests passed!`

### Analyse ciblée

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && \
flutter analyze --no-pub \
  lib/src/application/models/pokemon_project_data_models.dart \
  lib/src/application/models/pokedex_species_detail.dart \
  lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  lib/src/application/use_cases/use_cases.dart \
  lib/src/app/providers/pokedex/pokedex_providers.dart \
  lib/src/ui/canvas/pokedex_workspace_loader.dart \
  lib/src/ui/canvas/pokedex_workspace.dart \
  lib/src/ui/canvas/pokedex_workspace_views.dart \
  test/load_pokedex_species_detail_use_case_test.dart \
  test/pokedex_workspace_ui_test.dart \
  test/list_pokedex_entries_use_case_test.dart \
  test/pokemon_database_index_test.dart
```

Résultat :

- `No issues found!`

### Vérification racine monorepo

```bash
cd /Users/karim/Project/pokemonProject && \
find . -maxdepth 2 \( -path './data' -o -path './assets' \) -print
```

Résultat :

- aucune sortie ;
- rien n’a été recréé à la racine du monorepo.

## État Git utile

### `git status --short` sur le périmètre phase 5

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
?? packages/map_editor/lib/src/application/models/pokedex_species_detail.dart
?? packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
?? packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart
```

### `git diff --stat --` sur les fichiers suivis du périmètre

```text
 .../app/providers/pokedex/pokedex_providers.dart   |   14 +
 .../models/pokemon_project_data_models.dart        |  112 ++-
 .../lib/src/application/use_cases/use_cases.dart   |    1 +
 .../lib/src/ui/canvas/pokedex_workspace.dart       |  139 ++-
 .../src/ui/canvas/pokedex_workspace_loader.dart    |    6 +
 .../lib/src/ui/canvas/pokedex_workspace_views.dart | 1044 ++++++++++++++++++--
 .../map_editor/test/pokedex_workspace_ui_test.dart |  263 ++++-
 7 files changed, 1477 insertions(+), 102 deletions(-)
```

Note honnête :

- les trois nouveaux fichiers de la phase 5 sont **non suivis** ;
- ils n’apparaissent donc pas dans ce `diff --stat`.

## Explication fichier par fichier

### `pokedex_species_detail.dart`

Rôle :

- fournir un agrégat de lecture seule pour la fiche détail ;
- éviter que la UI reconstruise elle-même une pseudo-structure métier ;
- rester découplé du format de stockage réel.

### `load_pokedex_species_detail_use_case.dart`

Rôle :

- charger une espèce locale ;
- lire en option son learnset, son évolution et son média ;
- tolérer l’absence de fichiers annexes sans masquer les autres erreurs.

### `pokemon_project_data_models.dart`

Rôle dans cette phase :

- enrichir le contrat espèce juste assez pour les onglets détail ;
- ajouter `forms` et `classification` ;
- garder un parsing robuste avec fallback simple sur les booléens.

### `use_cases.dart`

Rôle :

- exporter le nouveau use case dans le barrel applicatif.

### `pokedex_providers.dart`

Rôle :

- brancher le nouveau use case dans Riverpod ;
- fournir un loader détail injecté proprement au workspace ;
- éviter que la UI instancie l’infrastructure directement.

### `pokedex_workspace_loader.dart`

Rôle :

- définir le type de loader détail ;
- garder le loader liste existant ;
- éviter que l’écran devienne un point d’instanciation infra.

### `pokedex_workspace.dart`

Rôle :

- orchestrer l’état local de recherche, filtres, sélection et onglet actif ;
- composer la liste et la fiche détail ;
- rester sur un état UI local simple, sans notifier dédié de plus.

### `pokedex_workspace_views.dart`

Rôle :

- rendre la liste ;
- rendre la ligne sélectionnable ;
- rendre la fiche détail complète ;
- contenir les onglets `Overview`, `Formes`, `Learnset`, `Évolutions`, `Médias`.

### `load_pokedex_species_detail_use_case_test.dart`

Rôle :

- prouver que le use case charge bien les fichiers liés via `refs` ;
- prouver que learnset/évolution/média sont optionnels si absents ;
- garder l’espèce elle-même obligatoire.

### `pokedex_workspace_ui_test.dart`

Rôle :

- verrouiller la sélection locale ;
- verrouiller l’apparition du panneau détail ;
- verrouiller la navigation entre les onglets ;
- garder les tests existants sur la liste, la recherche et les filtres.

## Code produit

Le bloc ci-dessous constitue l’intégralité du code produit pour la phase 5 selon la convention définie plus haut.

Il faut donc le lire comme suit :

- les nouveaux fichiers sont fournis en entier ;
- les fichiers déjà existants montrent toutes les zones de code effectivement introduites ou modifiées pendant la phase 5.

## 1. Nouveau fichier — `packages/map_editor/lib/src/application/models/pokedex_species_detail.dart`

```dart
import 'pokemon_project_data_models.dart';

/// Agrégat de détail Pokédex en lecture seule.
///
/// Ce modèle n'est pas un nouveau format de stockage. Il sert seulement à
/// rassembler, pour une espèce sélectionnée, les fichiers locaux déjà existants
/// afin que la UI affiche une fiche détail sans réinventer son propre contrat.
class PokedexSpeciesDetail {
  const PokedexSpeciesDetail({
    required this.species,
    this.learnset,
    this.evolution,
    this.media,
  });

  final PokemonSpeciesFile species;
  final PokemonLearnsetFile? learnset;
  final PokemonEvolutionFile? evolution;
  final PokemonMediaFile? media;
}
```

## 2. Nouveau fichier — `packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokedex_species_detail.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/project_workspace.dart';

/// Charge la fiche détail locale d'une espèce Pokédex.
///
/// On reste volontairement sobre :
/// - l'espèce elle-même est obligatoire ;
/// - learnset, évolution et média restent optionnels si leurs fichiers ne sont
///   pas encore présents dans le projet ;
/// - toute autre erreur remonte telle quelle pour ne pas masquer un vrai souci
///   de lecture JSON.
class LoadPokedexSpeciesDetailUseCase {
  const LoadPokedexSpeciesDetailUseCase(this.repository);

  final PokemonReadRepository repository;

  Future<PokedexSpeciesDetail> execute(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final species = await repository.readSpeciesById(workspace, speciesId);

    return PokedexSpeciesDetail(
      species: species,
      learnset: await _readOptional(
        () => repository.readLearnsetById(
          workspace,
          species.refs.learnset,
        ),
      ),
      evolution: await _readOptional(
        () => repository.readEvolutionById(
          workspace,
          species.refs.evolution,
        ),
      ),
      media: await _readOptional(
        () => repository.readMediaById(
          workspace,
          species.refs.media,
        ),
      ),
    );
  }

  Future<T?> _readOptional<T>(Future<T> Function() loader) async {
    try {
      return await loader();
    } on EditorNotFoundException {
      return null;
    }
  }
}
```

## 3. Nouveau fichier — `packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_read_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/load_pokedex_species_detail_use_case.dart';

void main() {
  group('LoadPokedexSpeciesDetailUseCase', () {
    test('loads species and linked files via refs', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: 'bulbasaur-learnset',
            evolutionRef: 'bulbasaur-evolution',
            mediaRef: 'bulbasaur-media',
          ),
        },
        learnsetsById: <String, PokemonLearnsetFile>{
          'bulbasaur-learnset': const PokemonLearnsetFile(
            speciesId: 'bulbasaur',
            levelUp: <PokemonLearnsetLevelUpEntry>[
              PokemonLearnsetLevelUpEntry(
                moveId: 'vine_whip',
                level: 7,
                source: 'level_up',
                versionGroup: 'scarlet-violet',
              ),
            ],
          ),
        },
        evolutionsById: <String, PokemonEvolutionFile>{
          'bulbasaur-evolution': const PokemonEvolutionFile(
            speciesId: 'bulbasaur',
            evolutions: <PokemonEvolutionEntry>[
              PokemonEvolutionEntry(
                targetSpeciesId: 'ivysaur',
                method: 'level_up',
                minLevel: 16,
              ),
            ],
          ),
        },
        mediaById: <String, PokemonMediaFile>{
          'bulbasaur-media': const PokemonMediaFile(
            speciesId: 'bulbasaur',
            defaultFormId: 'base',
            variants: <String, PokemonMediaVariant>{
              'base': PokemonMediaVariant(
                frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
              ),
            },
          ),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);
      const workspace = _FakeWorkspace();

      final PokedexSpeciesDetail detail = await useCase.execute(
        workspace,
        'bulbasaur',
      );

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset?.speciesId, 'bulbasaur');
      expect(detail.evolution?.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        detail.media?.variants['base']?.frontStatic,
        'assets/pokemon/sprites/bulbasaur/front.png',
      );
      expect(repository.readLearnsetIds, <String>['bulbasaur-learnset']);
      expect(repository.readEvolutionIds, <String>['bulbasaur-evolution']);
      expect(repository.readMediaIds, <String>['bulbasaur-media']);
    });

    test('keeps species mandatory but tolerates missing ancillary files',
        () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: 'bulbasaur',
            evolutionRef: 'bulbasaur',
            mediaRef: 'bulbasaur',
          ),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);
      const workspace = _FakeWorkspace();

      final detail = await useCase.execute(workspace, 'bulbasaur');

      expect(detail.species.id, 'bulbasaur');
      expect(detail.learnset, isNull);
      expect(detail.evolution, isNull);
      expect(detail.media, isNull);
    });
  });
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.speciesById = const <String, PokemonSpeciesFile>{},
    this.learnsetsById = const <String, PokemonLearnsetFile>{},
    this.evolutionsById = const <String, PokemonEvolutionFile>{},
    this.mediaById = const <String, PokemonMediaFile>{},
  });

  final Map<String, PokemonSpeciesFile> speciesById;
  final Map<String, PokemonLearnsetFile> learnsetsById;
  final Map<String, PokemonEvolutionFile> evolutionsById;
  final Map<String, PokemonMediaFile> mediaById;
  final List<String> readLearnsetIds = <String>[];
  final List<String> readEvolutionIds = <String>[];
  final List<String> readMediaIds = <String>[];

  @override
  Future<PokemonSpeciesFile> readSpeciesById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    final species = speciesById[speciesId];
    if (species == null) {
      throw Exception('missing species');
    }
    return species;
  }

  @override
  Future<PokemonLearnsetFile> readLearnsetById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    readLearnsetIds.add(speciesId);
    final learnset = learnsetsById[speciesId];
    if (learnset == null) {
      throw const EditorNotFoundException('missing learnset');
    }
    return learnset;
  }

  @override
  Future<PokemonEvolutionFile> readEvolutionById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    readEvolutionIds.add(speciesId);
    final evolution = evolutionsById[speciesId];
    if (evolution == null) {
      throw const EditorNotFoundException('missing evolution');
    }
    return evolution;
  }

  @override
  Future<PokemonMediaFile> readMediaById(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    readMediaIds.add(speciesId);
    final media = mediaById[speciesId];
    if (media == null) {
      throw const EditorNotFoundException('missing media');
    }
    return media;
  }

  @override
  Future<List<PokemonDatabaseIndexEntry>> listDatabaseIndexEntries(
    ProjectWorkspace workspace, {
    required String speciesDirectoryRelativePath,
  }) => throw UnimplementedError();

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) => throw UnimplementedError();

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) => throw UnimplementedError();

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) => throw UnimplementedError();

  @override
  Future<List<String>> listLearnsetIds(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listEvolutionIds(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listMediaIds(ProjectWorkspace workspace) =>
      throw UnimplementedError();
}

class _FakeWorkspace implements ProjectWorkspace {
  const _FakeWorkspace();

  @override
  String get projectRoot => '/tmp/pokedex';

  @override
  String get projectManifestPath => '/tmp/pokedex/project.json';

  @override
  String resolveMapPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String getMapPath(String mapId) => '$projectRoot/maps/$mapId.json';

  @override
  String getMapRelativePath(String mapId) => 'maps/$mapId.json';

  @override
  String resolveTilesetPath(String relativePath) => '$projectRoot/$relativePath';

  @override
  String resolveProjectRelativePath(String relativePath) =>
      '$projectRoot/$relativePath';

  @override
  Future<void> ensureDirectoryExists(String path) => throw UnimplementedError();

  @override
  Future<bool> fileExists(String path) => throw UnimplementedError();

  @override
  Future<bool> directoryExists(String path) => throw UnimplementedError();

  @override
  Future<String> readTextFile(String path) => throw UnimplementedError();

  @override
  Future<void> writeTextFile(String path, String contents) =>
      throw UnimplementedError();

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> moveFile(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> moveDirectory(String sourcePath, String destinationPath) =>
      throw UnimplementedError();

  @override
  Future<void> deleteDirectoryIfEmpty(String path) => throw UnimplementedError();

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteRelativeFile(String relativePath) =>
      throw UnimplementedError();
}

PokemonSpeciesFile _buildSpecies({
  required String id,
  required String learnsetRef,
  required String evolutionRef,
  required String mediaRef,
}) {
  return PokemonSpeciesFile(
    id: id,
    slug: id,
    nationalDex: 1,
    names: const <String, String>{'en': 'Bulbasaur'},
    speciesName: const <String, String>{'en': 'Seed Pokemon'},
    genIntroduced: 1,
    typing: const PokemonSpeciesTyping(types: <String>['grass', 'poison']),
    baseStats: const PokemonSpeciesBaseStats(
      hp: 45,
      atk: 49,
      def: 49,
      spa: 65,
      spd: 65,
      spe: 45,
      bst: 318,
    ),
    abilities: const PokemonSpeciesAbilities(
      primary: 'overgrow',
      hidden: 'chlorophyll',
    ),
    breeding: const PokemonSpeciesBreeding(
      genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
      eggGroups: <String>['monster', 'grass'],
      hatchCycles: 20,
    ),
    progression: const PokemonSpeciesProgression(
      growthRateId: 'medium_slow',
      baseExp: 64,
      catchRate: 45,
      baseFriendship: 50,
    ),
    forms: const PokemonSpeciesForms(
      baseFormId: 'bulbasaur',
      isBaseForm: true,
      formId: 'base',
    ),
    classification: const PokemonSpeciesClassification(),
    refs: PokemonSpeciesRefs(
      learnset: learnsetRef,
      evolution: evolutionRef,
      media: mediaRef,
    ),
    dexContent: const PokemonSpeciesDexContent(
      heightM: 0.7,
      weightKg: 6.9,
      color: 'green',
      flavorText: 'A strange seed was planted on its back at birth.',
    ),
    gameplayFlags: const PokemonSpeciesGameplayFlags(
      starterEligible: true,
    ),
    sourceMeta: const PokemonSpeciesSourceMeta(
      seededBy: 'test',
      seedVersion: 1,
    ),
  );
}
```

## 4. Fichier modifié — `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`

### Sections ajoutées / modifiées en phase 5

```dart
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

  factory PokemonSpeciesForms.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesForms(
      baseFormId: (json['baseFormId'] as String?)?.trim() ?? '',
      isBaseForm: _readBool(json['isBaseForm'], fallback: true),
      formId: (json['formId'] as String?)?.trim() ?? '',
      formName: _readOptionalTrimmedString(json['formName']),
      otherForms: _readStringList(json['otherForms']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'baseFormId': baseFormId,
      'isBaseForm': isBaseForm,
      'formId': formId,
      'formName': formName,
      'otherForms': List<String>.from(otherForms),
    };
  }
}

/// Classification Pokédex locale simple.
///
/// Cette structure sert uniquement à afficher des drapeaux métier lisibles dans
/// la fiche détail. Elle reste volontairement petite pour éviter de devancer
/// les futurs lots d'override/curation.
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

  factory PokemonSpeciesClassification.fromJson(Map<String, dynamic> json) {
    return PokemonSpeciesClassification(
      isEnabledInProject: _readBool(
        json['isEnabledInProject'],
        fallback: true,
      ),
      isObtainable: _readBool(json['isObtainable'], fallback: true),
      isLegendary: _readBool(json['isLegendary']),
      isMythical: _readBool(json['isMythical']),
      isBaby: _readBool(json['isBaby']),
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'isEnabledInProject': isEnabledInProject,
      'isObtainable': isObtainable,
      'isLegendary': isLegendary,
      'isMythical': isMythical,
      'isBaby': isBaby,
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
    this.forms = const PokemonSpeciesForms(),
    this.classification = const PokemonSpeciesClassification(),
    required this.refs,
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
  final PokemonSpeciesForms forms;
  final PokemonSpeciesClassification classification;
  final PokemonSpeciesRefs refs;
  final PokemonSpeciesDexContent dexContent;
  final PokemonSpeciesGameplayFlags gameplayFlags;
  final PokemonSpeciesSourceMeta sourceMeta;

  /// Compatibilité de lecture pour le code existant tant que tous les call sites
  /// ne sont pas encore repassés explicitement par `refs`.
  String get learnsetRef => refs.learnset;
  String get evolutionRef => refs.evolution;
  String get mediaRef => refs.media;

  factory PokemonSpeciesFile.fromJson(Map<String, dynamic> json) {
    final refsJson = (json['refs'] as Map?)?.cast<String, dynamic>() ??
        <String, dynamic>{
          'learnset': (json['learnsetRef'] as String?)?.trim() ?? '',
          'evolution': (json['evolutionRef'] as String?)?.trim() ?? '',
          'media': _readLegacySpeciesMediaRef(json),
        };
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
      'forms': forms.toJson(),
      'classification': classification.toJson(),
      'refs': refs.toJson(),
      'dexContent': dexContent.toJson(),
      'gameplayFlags': gameplayFlags.toJson(),
      'sourceMeta': sourceMeta.toJson(),
    };
  }
}

bool _readBool(
  Object? raw, {
  bool fallback = false,
}) {
  if (raw is bool) {
    return raw;
  }
  return fallback;
}
```

## 5. Fichier modifié — `packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'layer_use_cases.dart';
export 'list_pokedex_entries_use_case.dart';
export 'load_pokedex_species_detail_use_case.dart';
export 'map_use_cases.dart';
export 'paint_use_cases.dart';
export 'path_layer_use_cases.dart';
export 'project_element_use_cases.dart';
export 'project_group_use_cases.dart';
export 'project_management_use_cases.dart';
export 'project_scenario_use_cases.dart';
export 'project_tileset_use_cases.dart';
export 'seed_pokemon_demo_data_use_case.dart';
export 'terrain_preset_use_cases.dart';
export 'terrain_use_cases.dart';
export 'validate_pokemon_project_data_use_case.dart';
export 'warp_use_cases.dart';
```

## 6. Fichier modifié — `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../infrastructure/repositories/file_repositories.dart';
import '../../../ui/canvas/pokedex_workspace_loader.dart';
import '../core/repository_providers.dart';

/// Wiring Pokédex local minimal.
///
/// Ce fichier reste volontairement petit et thématique :
/// - le workspace Pokédex n'instancie plus l'infrastructure directement ;
/// - on réutilise les repositories/services existants ;
/// - on ne crée pas un nouveau notifier ni une couche "future-proof" inutile.
final pokemonReadRepositoryProvider = Provider<PokemonReadRepository>((ref) {
  return const FilePokemonReadRepository();
});

final pokemonDatabaseIndexProvider = Provider<PokemonDatabaseIndex>((ref) {
  return PokemonDatabaseIndex(
    projectRepository: ref.watch(projectRepositoryProvider),
    pokemonReadRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexEntryLoaderProvider = Provider<PokedexEntryLoader>((ref) {
  return createPokedexEntryLoader(
    projectRepository: ref.watch(projectRepositoryProvider),
    databaseIndex: ref.watch(pokemonDatabaseIndexProvider),
  );
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});
```

## 7. Fichier modifié — `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

```dart
import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../domain/repositories/repositories.dart';

typedef PokedexEntryLoader = Future<List<PokemonDatabaseIndexEntry>> Function(
  ProjectWorkspace workspace,
);

typedef PokedexSpeciesDetailLoader = Future<PokedexSpeciesDetail> Function(
  ProjectWorkspace workspace,
  String speciesId,
);

/// Construit un chargeur d'entrées Pokédex à partir de dépendances injectées.
///
/// Ce helper reste volontairement petit :
/// - l'UI ne compose plus directement l'infrastructure ;
/// - la logique produit locale du workspace Pokédex reste centralisée ;
/// - les tests peuvent injecter des dépendances concrètes ou fake sans devoir
///   reconstruire tout le wiring applicatif.
///
/// Important :
/// - la logique "species absent => liste vide" est traitée ici de façon
///   explicite, avant l'appel au service ;
/// - on ne dépend donc plus d'un `contains(...)` sur le message d'une
///   exception ;
/// - le service applicatif d'indexation garde sa responsabilité actuelle ;
/// - ce helper ne fait que l'adapter au besoin UI local.
PokedexEntryLoader createPokedexEntryLoader({
  required ProjectRepository projectRepository,
  required PokemonDatabaseIndex databaseIndex,
}) {
  return (ProjectWorkspace workspace) async {
    final project =
        await projectRepository.loadProject(workspace.projectManifestPath);
    final speciesDirectoryRelativePath = project.pokemon.speciesDir.trim();

    // On garde volontairement la validation "speciesDir vide" au niveau du
    // service du lot 11. Ici, on ne pré-traite qu'un seul cas produit très
    // précis du lot 13 : un dossier `species/` simplement absent dans un
    // projet encore vide doit rendre un état vide honnête, pas une erreur
    // technique.
    if (speciesDirectoryRelativePath.isNotEmpty) {
      final speciesDirectoryPath = workspace.resolveProjectRelativePath(
        speciesDirectoryRelativePath,
      );
      if (!await Directory(speciesDirectoryPath).exists()) {
        return const <PokemonDatabaseIndexEntry>[];
      }
    }

    return databaseIndex.build(workspace);
  };
}
```

## 8. Fichier modifié — `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers/pokedex_providers.dart';
import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../features/editor/state/editor_notifier.dart';
import '../../infrastructure/filesystem/project_filesystem.dart';
import 'pokedex_workspace_loader.dart';
import 'pokedex_workspace_views.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _overviewTabId = 'overview';

/// Workspace central Pokédex du lot 13.
///
/// Le widget public reste volontairement lisible :
/// - il lit le contexte éditeur existant ;
/// - il délègue le chargement par défaut à un helper local dédié ;
/// - il compose les quatre états UI strictement nécessaires.
///
/// On évite ainsi deux extrêmes :
/// - un gros widget fourre-tout mêlant UI et instanciation infra ;
/// - une nouvelle architecture Pokédex "future-ready" disproportionnée.
class PokedexWorkspace extends ConsumerWidget {
  const PokedexWorkspace({
    super.key,
    this.loader,
    this.detailLoader,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void didUpdateWidget(covariant _PokedexWorkspaceBody oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.projectRootPath != widget.projectRootPath ||
        oldWidget.loader != widget.loader ||
        oldWidget.detailLoader != widget.detailLoader) {
      _entriesFuture = _buildEntriesFuture();
      // Les raffinements UI des lots 14 et 15 restent purement locaux :
      // quand on change de workspace projet ou de source de chargement, on
      // réinitialise la query et les filtres pour éviter de conserver des
      // critères devenus trompeurs sur une autre liste déjà chargée.
      _searchQuery = '';
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedSpeciesId = null;
      _detailFuture = null;
      _selectedDetailTabId = _overviewTabId;
    }
  }

  Future<List<PokemonDatabaseIndexEntry>> _buildEntriesFuture() {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return Future<List<PokemonDatabaseIndexEntry>>.value(
        const <PokemonDatabaseIndexEntry>[],
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    return widget.loader(workspace);
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      return const PokedexWorkspaceStateCard(
        title: 'Pokédex',
        message:
            'Chargez un projet pour afficher la liste locale des espèces importées.',
      );
    }

    return FutureBuilder<List<PokemonDatabaseIndexEntry>>(
      future: _entriesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceLoadingState();
        }

        if (snapshot.hasError) {
          return PokedexWorkspaceErrorState(error: snapshot.error);
        }

        final entries = snapshot.data ?? const <PokemonDatabaseIndexEntry>[];
        if (entries.isEmpty) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-empty-state'),
            title: 'Pokédex',
            message:
                'Aucune espèce importée pour le moment. Les prochains imports ou seeds rempliront cette liste.',
          );
        }

        final availableTypes = _buildAvailableTypes(entries);
        final availableGenerations = _buildAvailableGenerations(entries);
        final workspace = ProjectFileSystem(projectRootPath);

        // Les lots 14 et 15 restent volontairement locaux à la UI :
        // - on ne recharge pas le disque à chaque frappe ou changement de filtre ;
        // - on ne crée pas de provider/notifier Pokédex dédié ;
        // - on filtre simplement la liste déjà chargée en mémoire ;
        // - on conserve l'ordre fourni par l'index local existant.
        final filteredEntries = _filterEntries(entries);
        final selectedEntry = _resolveSelectedEntry(entries);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 5,
              child: PokedexWorkspaceSpeciesList(
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                emptyResultsChild: filteredEntries.isEmpty
                    ? PokedexWorkspaceNoResultsState(
                        query: _searchQuery,
                        selectedType: _selectedType == _allTypesFilterValue
                            ? null
                            : _selectedType,
                        selectedGeneration:
                            _selectedGeneration == _allGenerationsFilterValue
                                ? null
                                : _selectedGeneration,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 18),
            SizedBox(
              width: 480,
              child: PokedexWorkspaceDetailPane(
                selectedEntry: selectedEntry,
                selectedTabId: _selectedDetailTabId,
                onTabChanged: _updateSelectedDetailTab,
                detailFuture: _detailFuture,
              ),
            ),
          ],
        );
      },
    );
  }

  void _updateSearchQuery(String value) {
    if (value == _searchQuery) return;
    setState(() => _searchQuery = value);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

  void _updateSelectedDetailTab(String value) {
    if (value == _selectedDetailTabId) return;
    setState(() => _selectedDetailTabId = value);
  }

  void _selectEntry({
    required ProjectFileSystem workspace,
    required PokemonDatabaseIndexEntry entry,
  }) {
    if (_selectedSpeciesId == entry.id && _detailFuture != null) {
      return;
    }
    setState(() {
      _selectedSpeciesId = entry.id;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, entry.id);
    });
  }

  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final normalizedQuery = _searchQuery.trim();
    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\\d+$').hasMatch(normalizedDexQuery);

    // Le lot 15 demande des filtres simples, pas un moteur de règles :
    // chaque critère local vaut soit "tout", soit une valeur unique exacte.
    final typeFilter = _selectedType.toLowerCase();
    final hasTypeFilter = _selectedType != _allTypesFilterValue;
    final hasGenerationFilter =
        _selectedGeneration != _allGenerationsFilterValue;

    return entries.where((entry) {
      final matchesSearch = _matchesSearchQuery(
        entry: entry,
        normalizedQuery: normalizedQuery,
        normalizedTextQuery: normalizedTextQuery,
        normalizedDexQuery: normalizedDexQuery,
        hasExactDexQuery: hasExactDexQuery,
      );

      final matchesType = !hasTypeFilter ||
          entry.types.any((type) => type.toLowerCase() == typeFilter);
      final matchesGeneration = !hasGenerationFilter ||
          entry.genIntroduced.toString() == _selectedGeneration;

      return matchesSearch && matchesType && matchesGeneration;
    }).toList(growable: false);
  }

  bool _matchesSearchQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedQuery,
    required String normalizedTextQuery,
    required String normalizedDexQuery,
    required bool hasExactDexQuery,
  }) {
    if (normalizedQuery.isEmpty) {
      return true;
    }

    final matchesName =
        entry.primaryName.toLowerCase().contains(normalizedTextQuery);
    final matchesId = entry.id.toLowerCase().contains(normalizedTextQuery);

    // Règle produit explicite du lot 14 :
    // - si la query ressemble à un numéro dex, on ne fait pas un `contains`
    //   numérique ;
    // - on compare exactement `1`, `0001`, `#1`, `#0001` au dex courant ;
    // - cela évite qu'une recherche "1" remonte 10, 11, 21, etc.
    final matchesDex = hasExactDexQuery &&
        _matchesExactDexQuery(
          entry: entry,
          normalizedDexQuery: normalizedDexQuery,
        );

    return matchesName || matchesId || matchesDex;
  }

  List<String> _buildAvailableTypes(List<PokemonDatabaseIndexEntry> entries) {
    final uniqueTypes = entries
        .expand((entry) => entry.types)
        .map((type) => type.trim())
        .where((type) => type.isNotEmpty)
        .toSet()
        .toList(growable: false)
      ..sort(
          (left, right) => left.toLowerCase().compareTo(right.toLowerCase()));

    return uniqueTypes;
  }

  List<String> _buildAvailableGenerations(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final uniqueGenerations = entries
        .map((entry) => entry.genIntroduced)
        .toSet()
        .toList(growable: false)
      ..sort();

    return uniqueGenerations
        .map((generation) => generation.toString())
        .toList(growable: false);
  }

  PokemonDatabaseIndexEntry? _resolveSelectedEntry(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return null;
    }
    for (final entry in entries) {
      if (entry.id == selectedId) {
        return entry;
      }
    }
    return null;
  }

  String _normalizeDexQuery(String query) {
    final trimmed = query.trim();
    if (!trimmed.startsWith('#')) {
      return trimmed;
    }
    return trimmed.substring(1).trim();
  }

  bool _matchesExactDexQuery({
    required PokemonDatabaseIndexEntry entry,
    required String normalizedDexQuery,
  }) {
    final rawDex = entry.nationalDex.toString();
    final paddedDex = entry.nationalDex.toString().padLeft(4, '0');
    return normalizedDexQuery == rawDex || normalizedDexQuery == paddedDex;
  }
}
```

## 9. Fichier modifié — `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`

### Sections phase 5 ajoutées / enrichies

```dart
class _PokedexListRow extends StatelessWidget {
  const _PokedexListRow({
    required this.entry,
    required this.isSelected,
    required this.onPressed,
  });

  final PokemonDatabaseIndexEntry entry;
  final bool isSelected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final surface = isSelected
        ? Color.lerp(
            EditorChrome.islandFillElevated(context),
            EditorChrome.accentJade,
            0.12,
          )!
        : EditorChrome.islandFillElevated(context);
    final border = isSelected
        ? EditorChrome.accentJade.withValues(alpha: 0.65)
        : EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return CupertinoButton(
      key: Key('pokedex-row-${entry.id}'),
      padding: EdgeInsets.zero,
      onPressed: onPressed,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border, width: isSelected ? 1.4 : 1),
          boxShadow: EditorChrome.sectionCardShadows(context),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 88,
                child: Text(
                  '#${entry.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Text(
                  entry.primaryName,
                  style: TextStyle(
                    color: label,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Text(
                  entry.id,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: entry.types
                      .map((type) => _PokedexTypeChip(label: type))
                      .toList(growable: false),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour afficher son overview, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex locale…',
          );
        }

        if (snapshot.hasError) {
          final message = switch (snapshot.error) {
            final EditorApplicationException applicationError =>
              applicationError.message,
            _ => snapshot.error?.toString() ?? 'Erreur inconnue',
          };
          return PokedexWorkspaceStateCard(
            key: const Key('pokedex-detail-error-state'),
            title: 'Fiche espèce',
            accent: EditorChrome.inspectorJoyCoral,
            message: 'Impossible de charger la fiche de ${entry.id}.\\n$message',
          );
        }

        final detail = snapshot.data;
        if (detail == null) {
          return const PokedexWorkspaceStateCard(
            title: 'Fiche espèce',
            message: 'Aucune donnée Pokédex détaillée disponible.',
          );
        }

        return _PokedexSpeciesDetailView(
          entry: entry,
          detail: detail,
          selectedTabId: selectedTabId,
          onTabChanged: onTabChanged,
        );
      },
    );
  }
}

class _PokedexSpeciesDetailView extends StatelessWidget {
  const _PokedexSpeciesDetailView({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
    required this.onTabChanged,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    final surface = EditorChrome.islandFillElevated(context);
    final border = EditorChrome.accentWarm.withValues(alpha: 0.35);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      key: const Key('pokedex-detail-pane'),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: border, width: 1),
        boxShadow: EditorChrome.sectionCardShadows(context),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              entry.primaryName,
              style: TextStyle(
                color: label,
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '#${entry.nationalDex.toString().padLeft(4, '0')} • ${entry.id}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: entry.types
                  .map((type) => _PokedexTypeChip(label: type))
                  .toList(growable: false),
            ),
            const SizedBox(height: 16),
            CupertinoSlidingSegmentedControl<String>(
              key: const Key('pokedex-detail-tabs'),
              groupValue: selectedTabId,
              onValueChanged: (value) {
                if (value != null) {
                  onTabChanged(value);
                }
              },
              children: const <String, Widget>{
                'overview': Padding(
                  key: Key('pokedex-tab-overview'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Overview'),
                ),
                'forms': Padding(
                  key: Key('pokedex-tab-forms'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Formes'),
                ),
                'learnset': Padding(
                  key: Key('pokedex-tab-learnset'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Learnset'),
                ),
                'evolutions': Padding(
                  key: Key('pokedex-tab-evolutions'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Évolutions'),
                ),
                'media': Padding(
                  key: Key('pokedex-tab-media'),
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text('Médias'),
                ),
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: _PokedexDetailTabBody(
                entry: entry,
                detail: detail,
                selectedTabId: selectedTabId,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PokedexDetailTabBody extends StatelessWidget {
  const _PokedexDetailTabBody({
    required this.entry,
    required this.detail,
    required this.selectedTabId,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(detail: detail),
      'learnset' => _PokedexLearnsetTab(detail: detail),
      'evolutions' => _PokedexEvolutionTab(detail: detail),
      'media' => _PokedexMediaTab(detail: detail),
      _ => _PokedexOverviewTab(entry: entry, detail: detail),
    };
  }
}

class _PokedexOverviewTab extends StatelessWidget {
  const _PokedexOverviewTab({
    required this.entry,
    required this.detail,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;

    return SingleChildScrollView(
      key: const Key('pokedex-overview-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Identité',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Nom principal',
                  value: entry.primaryName,
                ),
                _PokedexPropertyLine(label: 'ID', value: species.id),
                _PokedexPropertyLine(
                  label: 'Numéro national',
                  value: species.nationalDex.toString(),
                ),
                _PokedexPropertyLine(
                  label: 'Nom espèce',
                  value: _localizedValue(species.speciesName),
                ),
                _PokedexPropertyLine(
                  label: 'Génération',
                  value: species.genIntroduced.toString(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Stats',
            child: Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _StatChip(label: 'HP', value: species.baseStats.hp),
                _StatChip(label: 'ATK', value: species.baseStats.atk),
                _StatChip(label: 'DEF', value: species.baseStats.def),
                _StatChip(label: 'SPA', value: species.baseStats.spa),
                _StatChip(label: 'SPD', value: species.baseStats.spd),
                _StatChip(label: 'SPE', value: species.baseStats.spe),
                _StatChip(label: 'BST', value: species.baseStats.bst),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Talents',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Talent principal',
                  value: species.abilities.primary,
                ),
                _PokedexPropertyLine(
                  label: 'Talent secondaire',
                  value: species.abilities.secondary ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'Talent caché',
                  value: species.abilities.hidden ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Références locales',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Learnset',
                  value: species.refs.learnset,
                ),
                _PokedexPropertyLine(
                  label: 'Évolution',
                  value: species.refs.evolution,
                ),
                _PokedexPropertyLine(
                  label: 'Média',
                  value: species.refs.media,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexFormsTab extends StatelessWidget {
  const _PokedexFormsTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final species = detail.species;
    final forms = species.forms;
    final classification = species.classification;
    final currentFormId = forms.formId.isEmpty ? 'base' : forms.formId;
    final baseFormId = forms.baseFormId.isEmpty ? species.id : forms.baseFormId;

    return SingleChildScrollView(
      key: const Key('pokedex-forms-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Formes',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Forme courante',
                  value: forms.formName == null || forms.formName!.isEmpty
                      ? currentFormId
                      : '${forms.formName} ($currentFormId)',
                ),
                _PokedexPropertyLine(
                  label: 'Forme de base',
                  value: baseFormId,
                ),
                _PokedexPropertyLine(
                  label: 'Est la forme de base',
                  value: forms.isBaseForm ? 'Oui' : 'Non',
                ),
                _PokedexPropertyLine(
                  label: 'Autres formes',
                  value: forms.otherForms.isEmpty
                      ? 'Aucune autre forme locale'
                      : forms.otherForms.join(', '),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Classification',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FlagChip(
                  label: classification.isEnabledInProject
                      ? 'Activée dans le projet'
                      : 'Désactivée dans le projet',
                ),
                _FlagChip(
                  label: classification.isObtainable
                      ? 'Obtenable'
                      : 'Non obtenable',
                ),
                if (classification.isLegendary)
                  const _FlagChip(label: 'Légendaire'),
                if (classification.isMythical)
                  const _FlagChip(label: 'Mythique'),
                if (classification.isBaby) const _FlagChip(label: 'Bébé'),
                if (!classification.isLegendary &&
                    !classification.isMythical &&
                    !classification.isBaby)
                  const _FlagChip(label: 'Aucun flag rare'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Flags gameplay simples',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (species.gameplayFlags.starterEligible)
                  const _FlagChip(label: 'Starter éligible'),
                if (species.gameplayFlags.giftOnly)
                  const _FlagChip(label: 'Obtenu par cadeau'),
                if (species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Échange uniquement'),
                if (!species.gameplayFlags.starterEligible &&
                    !species.gameplayFlags.giftOnly &&
                    !species.gameplayFlags.tradeOnly)
                  const _FlagChip(label: 'Aucun flag gameplay'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokedexLearnsetTab extends StatelessWidget {
  const _PokedexLearnsetTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final learnset = detail.learnset;
    if (learnset == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-learnset-missing'),
        title: 'Learnset',
        message: 'Aucun learnset local trouvé pour cette espèce.',
      );
    }

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Moves de départ',
            child: Text(
              learnset.startingMoves.isEmpty
                  ? 'Aucun move de départ déclaré.'
                  : learnset.startingMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Moves à réapprendre',
            child: Text(
              learnset.relearnMoves.isEmpty
                  ? 'Aucun move à réapprendre déclaré.'
                  : learnset.relearnMoves.join(', '),
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Level-up',
            child: learnset.levelUp.isEmpty
                ? const Text('Aucune entrée level-up.')
                : Column(
                    children: learnset.levelUp
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: '${entry.moveId} • niveau ${entry.level}',
                            value:
                                '${entry.versionGroup} • source ${entry.source}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'TM', entries: learnset.tm),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Tutor', entries: learnset.tutor),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Egg', entries: learnset.egg),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Event', entries: learnset.event),
          const SizedBox(height: 12),
          _LearnsetMoveSection(title: 'Transfer', entries: learnset.transfer),
        ],
      ),
    );
  }
}

class _PokedexEvolutionTab extends StatelessWidget {
  const _PokedexEvolutionTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final evolution = detail.evolution;
    if (evolution == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-evolutions-missing'),
        title: 'Évolutions',
        message: 'Aucune donnée d’évolution locale trouvée pour cette espèce.',
      );
    }

    return SingleChildScrollView(
      key: const Key('pokedex-evolutions-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Pré-évolution',
            child: Text(evolution.preEvolution?.trim().isNotEmpty == true
                ? evolution.preEvolution!
                : 'Aucune'),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Évolutions suivantes',
            child: evolution.evolutions.isEmpty
                ? const Text('Aucune évolution déclarée.')
                : Column(
                    children: evolution.evolutions
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: entry.targetSpeciesId,
                            value: _describeEvolution(entry),
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
        ],
      ),
    );
  }
}

class _PokedexMediaTab extends StatelessWidget {
  const _PokedexMediaTab({required this.detail});

  final PokedexSpeciesDetail detail;

  @override
  Widget build(BuildContext context) {
    final media = detail.media;
    if (media == null) {
      return const _PokedexMissingSection(
        key: Key('pokedex-media-missing'),
        title: 'Médias',
        message: 'Aucune donnée média locale trouvée pour cette espèce.',
      );
    }

    final defaultVariant = media.variants[media.defaultFormId];

    return SingleChildScrollView(
      key: const Key('pokedex-media-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexDetailSectionCard(
            title: 'Variant par défaut',
            child: Column(
              children: [
                _PokedexPropertyLine(
                  label: 'Forme par défaut',
                  value: media.defaultFormId,
                ),
                _PokedexPropertyLine(
                  label: 'front',
                  value: defaultVariant?.frontStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'back',
                  value: defaultVariant?.backStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'front shiny',
                  value: defaultVariant?.frontShinyStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'back shiny',
                  value: defaultVariant?.backShinyStatic ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'icon',
                  value: defaultVariant?.icon ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'party',
                  value: defaultVariant?.party ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'portrait',
                  value: defaultVariant?.portrait ?? 'Aucun',
                ),
                _PokedexPropertyLine(
                  label: 'cry',
                  value: defaultVariant?.cry ?? 'Aucun',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _PokedexDetailSectionCard(
            title: 'Animations',
            child: defaultVariant == null || defaultVariant.animations.isEmpty
                ? const Text('Aucune animation locale déclarée.')
                : Column(
                    children: defaultVariant.animations.entries
                        .map(
                          (entry) => _PokedexPropertyLine(
                            label: entry.key,
                            value:
                                '${entry.value.animationId} • ${entry.value.sheet}',
                          ),
                        )
                        .toList(growable: false),
                  ),
          ),
          const SizedBox(height: 12),
          const _PokedexDetailSectionCard(
            title: 'Contrat média',
            child: Text(
              'Les médias Pokémon restent de simples références locales vers assets/pokemon/... et n’utilisent jamais de GIF.',
            ),
          ),
        ],
      ),
    );
  }
}

class _LearnsetMoveSection extends StatelessWidget {
  const _LearnsetMoveSection({
    required this.title,
    required this.entries,
  });

  final String title;
  final List<PokemonLearnsetMoveEntry> entries;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: entries.isEmpty
          ? Text('Aucune entrée $title.')
          : Column(
              children: entries
                  .map(
                    (entry) => _PokedexPropertyLine(
                      label: entry.moveId,
                      value: entry.versionGroup,
                    ),
                  )
                  .toList(growable: false),
            ),
    );
  }
}

class _PokedexMissingSection extends StatelessWidget {
  const _PokedexMissingSection({
    super.key,
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: title,
      child: Text(message),
    );
  }
}

class _PokedexDetailSectionCard extends StatelessWidget {
  const _PokedexDetailSectionCard({
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final surface = Color.lerp(
      EditorChrome.islandFillElevated(context),
      CupertinoColors.black,
      0.06,
    )!;
    final border = EditorChrome.accentWarm.withValues(alpha: 0.24);
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
        child: DefaultTextStyle(
          style: TextStyle(
            color: subtle,
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.4,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: label,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _PokedexPropertyLine extends StatelessWidget {
  const _PokedexPropertyLine({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              label,
              style: TextStyle(
                color: labelColor,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final fill = EditorChrome.islandFillElevated(context);
    final labelColor = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: TextStyle(
                color: subtle,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value.toString(),
              style: TextStyle(
                color: labelColor,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlagChip extends StatelessWidget {
  const _FlagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final text = EditorChrome.primaryLabel(context);
    final fill = Color.lerp(
      EditorChrome.chipFill(context),
      EditorChrome.accentWarm,
      0.18,
    )!;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: TextStyle(
            color: text,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

String _localizedValue(Map<String, String> values) {
  for (final key in const <String>['fr', 'en']) {
    final value = values[key]?.trim();
    if (value != null && value.isNotEmpty) {
      return value;
    }
  }
  return values.values.firstWhere(
    (value) => value.trim().isNotEmpty,
    orElse: () => 'Aucune valeur locale',
  );
}

String _describeEvolution(PokemonEvolutionEntry entry) {
  final explicit = _localizedValue(entry.conditionText);
  if (explicit != 'Aucune valeur locale') {
    return explicit;
  }
  if (entry.minLevel != null) {
    return 'Évolue au niveau ${entry.minLevel}';
  }
  if (entry.itemId != null && entry.itemId!.trim().isNotEmpty) {
    return 'Évolue avec ${entry.itemId}';
  }
  if (entry.requiredMoveId != null && entry.requiredMoveId!.trim().isNotEmpty) {
    return 'Évolue avec le move ${entry.requiredMoveId}';
  }
  if (entry.method.trim().isNotEmpty) {
    return 'Méthode : ${entry.method}';
  }
  return 'Condition non précisée';
}
```

## 10. Fichier modifié — `packages/map_editor/test/pokedex_workspace_ui_test.dart`

### Sections phase 5 ajoutées / modifiées

```dart
  PokedexSpeciesDetail buildDetail({
    required String id,
    String primaryAbility = 'overgrow',
    String? secondaryAbility,
    String? hiddenAbility = 'chlorophyll',
    List<String> otherForms = const <String>[],
  }) {
    return PokedexSpeciesDetail(
      species: PokemonSpeciesFile(
        id: id,
        slug: id,
        nationalDex: 1,
        names: const <String, String>{
          'fr': 'Bulbizarre',
          'en': 'Bulbasaur',
        },
        speciesName: const <String, String>{
          'fr': 'Pokémon Graine',
          'en': 'Seed Pokemon',
        },
        genIntroduced: 1,
        typing: const PokemonSpeciesTyping(
          types: <String>['grass', 'poison'],
        ),
        baseStats: const PokemonSpeciesBaseStats(
          hp: 45,
          atk: 49,
          def: 49,
          spa: 65,
          spd: 65,
          spe: 45,
          bst: 318,
        ),
        abilities: PokemonSpeciesAbilities(
          primary: primaryAbility,
          secondary: secondaryAbility,
          hidden: hiddenAbility,
        ),
        breeding: const PokemonSpeciesBreeding(
          genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
          eggGroups: <String>['monster', 'grass'],
          hatchCycles: 20,
        ),
        progression: const PokemonSpeciesProgression(
          growthRateId: 'medium_slow',
          baseExp: 64,
          catchRate: 45,
          baseFriendship: 50,
        ),
        forms: PokemonSpeciesForms(
          baseFormId: id,
          isBaseForm: true,
          formId: 'base',
          otherForms: otherForms,
        ),
        classification: const PokemonSpeciesClassification(
          isEnabledInProject: true,
          isObtainable: true,
        ),
        refs: PokemonSpeciesRefs(
          learnset: id,
          evolution: id,
          media: id,
        ),
        dexContent: const PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText:
              'Une étrange graine a été plantée sur son dos à la naissance.',
        ),
        gameplayFlags: const PokemonSpeciesGameplayFlags(
          starterEligible: true,
        ),
        sourceMeta: const PokemonSpeciesSourceMeta(
          seededBy: 'ui-test',
          seedVersion: 1,
        ),
      ),
      learnset: const PokemonLearnsetFile(
        speciesId: 'bulbasaur',
        startingMoves: <String>['tackle', 'growl'],
        relearnMoves: <String>['vine_whip'],
        levelUp: <PokemonLearnsetLevelUpEntry>[
          PokemonLearnsetLevelUpEntry(
            moveId: 'vine_whip',
            level: 7,
            source: 'level_up',
            versionGroup: 'scarlet-violet',
          ),
        ],
        tm: <PokemonLearnsetMoveEntry>[
          PokemonLearnsetMoveEntry(
            moveId: 'protect',
            versionGroup: 'scarlet-violet',
          ),
        ],
      ),
      evolution: const PokemonEvolutionFile(
        speciesId: 'bulbasaur',
        preEvolution: null,
        evolutions: <PokemonEvolutionEntry>[
          PokemonEvolutionEntry(
            targetSpeciesId: 'ivysaur',
            method: 'level_up',
            minLevel: 16,
            conditionText: <String, String>{
              'fr': 'Évolue au niveau 16',
              'en': 'Evolves at level 16',
            },
          ),
        ],
      ),
      media: const PokemonMediaFile(
        speciesId: 'bulbasaur',
        defaultFormId: 'base',
        variants: <String, PokemonMediaVariant>{
          'base': PokemonMediaVariant(
            frontStatic: 'assets/pokemon/sprites/bulbasaur/front.png',
            backStatic: 'assets/pokemon/sprites/bulbasaur/back.png',
            frontShinyStatic:
                'assets/pokemon/sprites/bulbasaur/front_shiny.png',
            backShinyStatic: 'assets/pokemon/sprites/bulbasaur/back_shiny.png',
            icon: 'assets/pokemon/sprites/bulbasaur/icon.png',
            party: 'assets/pokemon/sprites/bulbasaur/party.png',
            portrait: 'assets/pokemon/sprites/bulbasaur/portrait.png',
            cry: 'assets/pokemon/cries/bulbasaur.ogg',
            animations: <String, PokemonMediaAnimationRef>{
              'battleFront': PokemonMediaAnimationRef(
                sheet:
                    'assets/pokemon/sprites/bulbasaur/battle_front_sheet.png',
                animationId: 'battle_front',
              ),
            },
          ),
        },
      ),
    );
  }
```

```dart
  testWidgets('selects a species row and shows the overview detail pane',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'ivysaur',
            nationalDex: 2,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.text('Nom principal'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsWidgets);
    expect(find.text('Talent principal'), findsOneWidget);
    expect(find.text('overgrow'), findsOneWidget);
    expect(find.text('Références locales'), findsOneWidget);
    expect(find.text('bulbasaur'), findsWidgets);
  });
```

```dart
  testWidgets('switches to forms learnset evolutions and media tabs',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(
          id: speciesId,
          otherForms: const <String>['mega'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-forms-tab')), findsOneWidget);
    expect(find.text('Forme courante'), findsOneWidget);
    expect(find.textContaining('mega'), findsOneWidget);
    expect(find.text('Classification'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);
    expect(find.text('vine_whip • niveau 7'), findsOneWidget);
    expect(find.text('scarlet-violet • source level_up'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-evolutions-tab')), findsOneWidget);
    expect(find.text('Pré-évolution'), findsOneWidget);
    expect(find.text('Évolue au niveau 16'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);
    expect(
      find.text('assets/pokemon/sprites/bulbasaur/front.png'),
      findsOneWidget,
    );
    expect(find.textContaining('battle_front'), findsWidgets);
    expect(find.textContaining('battle_front_sheet.png'), findsWidgets);
  });
```

```dart
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );
```

## Conclusion honnête

La phase 5 est bien matérialisée et cohérente :

- la liste Pokédex permet maintenant une vraie sélection ;
- la fiche détail lecture seule existe réellement ;
- les vues `Overview`, `Formes`, `Learnset`, `Évolutions`, `Médias` sont branchées sur les données locales ;
- les tests ciblés et l’analyse ciblée ont été exécutés et sont verts ;
- aucun débordement n’a été introduit vers l’import, l’édition, le runtime ou `project.json`.

Point honnête de structure :

- le fichier `pokedex_workspace_views.dart` concentre encore beaucoup de rendu ;
- fonctionnellement c’est bon pour la phase 5 ;
- architecturalement, si on continue le chantier Pokédex, ce sera un bon candidat à découper plus tard.

Point de discipline :

- aucune opération Git d’écriture n’a été faite pour produire cette phase ;
- ce rapport est un récapitulatif documentaire, pas une nouvelle passe de code.
