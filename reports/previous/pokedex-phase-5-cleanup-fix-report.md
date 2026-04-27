# Rapport Mini-Fix Phase 5 Pokédex

## Résumé exécutif

Ce mini-fix corrige trois défauts précis du bloc Pokédex produit trop largement pour les lots 17 à 22 :

- le périmètre du fix était sale, avec deux fichiers hors scope encore présents dans le working tree ;
- `LoadPokedexSpeciesDetailUseCase` n’était pas assez robuste sur les refs annexes vides ou blanches ;
- la sélection UI pouvait rester conceptuellement active alors que l’espèce n’était plus visible après recherche ou filtre.

Ce qui a été corrigé :

- le diff final du mini-fix est recentré sur les seuls fichiers Pokédex autorisés ;
- les refs annexes vides/blanches sont maintenant traitées comme absentes sans tentative de lecture ;
- une sélection devenue invisible après recherche ou filtre est explicitement effacée, le panneau détail revient à l’état vide, et l’onglet revient à `overview`.

Ce qui a été volontairement laissé intact :

- les modèles Pokédex ;
- les providers Pokédex ;
- les vues de détail `pokedex_workspace_views.dart` ;
- la structure générale de la phase 5 ;
- tout ce qui relève des lots suivants ;
- `project.json` et toute logique d’import, d’édition, de runtime ou de sauvegarde.

## Diagnostic précis

### 1. Problème de périmètre

Le working tree contenait encore des traces hors scope dans :

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/ui_panels_smoke_test.dart`

Ces fichiers n’avaient rien à faire dans ce mini-fix Pokédex. Ils ont été restaurés manuellement à `HEAD` pour sortir complètement du diff final.

### 2. Problème use case refs vides

Dans `LoadPokedexSpeciesDetailUseCase`, les fichiers annexes étaient déjà tolérés s’ils étaient absents, mais il restait un angle mort :

- une ref `''`, `'   '` ou `'\n'` pouvait encore être interprétée comme une tentative de lecture ;
- ce comportement n’était pas propre du point de vue métier ;
- il brouillait la frontière entre “annexe absente” et “erreur de lecture”.

Le comportement demandé a été implémenté strictement :

- espèce principale obligatoire ;
- ref vide ou blanche => annexe `null` sans lecture ;
- ref non vide + fichier absent => annexe `null` ;
- toute autre erreur remonte.

### 3. Problème UX sélection vs filtres

Le comportement de sélection pouvait devenir ambigu :

- une espèce sélectionnée restait encore comme sélection logique ;
- la liste filtrée pouvait ne plus afficher cette espèce ;
- la fiche détail pouvait alors devenir conceptuellement incohérente.

La règle UX imposée a été explicitement verrouillée :

- si la sélection n’est plus visible dans la liste filtrée courante, elle est vidée ;
- le détail repasse à l’état vide ;
- l’onglet sélectionné revient à `overview`.

### 4. Problème de fiabilité documentaire précédent

Le rapport précédent n’était pas assez fiable pour une review stricte parce qu’il ne collait pas assez au vrai diff final du mini-fix demandé ici.

Ce rapport corrige ce point :

- il distingue clairement les fichiers réellement modifiés, créés et restaurés ;
- il donne les vraies commandes exécutées ;
- il donne les vrais résultats ;
- il inclut le contenu complet des fichiers touchés dans ce mini-fix.

## Liste exacte des fichiers

### Fichiers modifiés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

### Fichiers créés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart`

### Fichiers restaurés manuellement hors diff final

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/test/ui_panels_smoke_test.dart`

### Fichiers volontairement non touchés

- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokedex_species_detail.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_views.dart`
- `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart`

## Justification fichier par fichier

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart`

Pourquoi touché :

- c’est le point exact où la robustesse sur les refs annexes devait être durcie.

Ce qui a été changé :

- ajout d’un helper local `_readOptionalByRef` ;
- trim de la ref ;
- retour `null` immédiat si ref vide ou blanche ;
- tolérance uniquement de `EditorNotFoundException` ;
- remontée inchangée des autres erreurs.

Pourquoi c’est le plus petit changement raisonnable :

- aucun changement de modèle ;
- aucune nouvelle abstraction de service ;
- aucune propagation de logique dans d’autres couches.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart`

Pourquoi touché :

- il fallait verrouiller exactement le nouveau comportement du use case.

Ce qui a été changé :

- ajout de tests sur refs blanches ;
- ajout de tests sur espèce obligatoire ;
- ajout de tests sur erreurs annexes non `EditorNotFoundException` ;
- extension minimale du fake repository pour injecter ces erreurs.

Pourquoi c’est le plus petit changement raisonnable :

- tests purement ciblés sur le comportement modifié ;
- aucune couverture décorative ;
- aucun bruit sur des comportements non touchés.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

Pourquoi touché :

- c’est le seul endroit cohérent pour verrouiller la décision UX sélection vs liste filtrée.

Ce qui a été changé :

- la sélection visible est maintenant résolue contre la liste filtrée, pas la liste brute ;
- ajout d’une logique locale `_clearSelectionIfInvisible` ;
- si l’entrée sélectionnée n’est plus visible :
  - `_selectedSpeciesId = null`
  - `_detailFuture = null`
  - `_selectedDetailTabId = _overviewTabId`

Pourquoi c’est le plus petit changement raisonnable :

- aucun nouveau provider ;
- aucun nouveau notifier ;
- aucune logique dispersée ;
- aucune modification des vues de détail.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

Pourquoi touché :

- il fallait prouver réellement la décision UX imposée sur recherche et filtres.

Ce qui a été changé :

- ajout d’un test “sélection masquée par la recherche” ;
- ajout d’un test “sélection masquée par un filtre” ;
- vérification du retour à l’état vide ;
- vérification du reset de l’onglet à `overview`.

Pourquoi c’est le plus petit changement raisonnable :

- on reste au niveau widget test ;
- on ne touche pas aux vues internes ;
- on teste strictement le comportement demandé.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`

Pourquoi touché :

- uniquement pour sortir ce fichier du périmètre du mini-fix.

Ce qui a été fait :

- lecture du contenu exact `HEAD` en lecture seule ;
- réécriture manuelle du fichier avec ce contenu exact ;
- vérification qu’il ne figure plus dans le diff final du fix.

Pourquoi c’est le plus petit changement raisonnable :

- aucun refactor ;
- aucune modification fonctionnelle ;
- uniquement nettoyage du périmètre.

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/ui_panels_smoke_test.dart`

Pourquoi touché :

- uniquement pour sortir ce fichier du périmètre du mini-fix.

Ce qui a été fait :

- suppression des traces Pokédex/hors scope précédemment introduites ;
- restauration manuelle du contenu `HEAD` ;
- vérification qu’il ne figure plus dans le diff final du fix.

Pourquoi c’est le plus petit changement raisonnable :

- aucun changement de couverture voulu ici ;
- uniquement nettoyage du working tree.

## Commandes réellement exécutées

```bash
git status --short -- \
  packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart \
  packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart \
  packages/map_editor/test/pokedex_workspace_ui_test.dart \
  packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart \
  packages/map_editor/test/ui_panels_smoke_test.dart

git diff --stat -- \
  packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart \
  packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart \
  packages/map_editor/test/pokedex_workspace_ui_test.dart \
  packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart \
  packages/map_editor/test/ui_panels_smoke_test.dart

git ls-files --others --exclude-standard \
  packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart \
  reports/pokedex-phase-5-cleanup-fix-report.md

git show HEAD:packages/map_editor/test/ui_panels_smoke_test.dart

git show HEAD:packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart

git diff -- \
  packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart \
  packages/map_editor/test/ui_panels_smoke_test.dart

dart format \
  packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart \
  packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart \
  packages/map_editor/test/pokedex_workspace_ui_test.dart

cd packages/map_editor && flutter test \
  test/load_pokedex_species_detail_use_case_test.dart \
  test/pokedex_workspace_ui_test.dart

cd packages/map_editor && flutter analyze --no-pub \
  lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  test/load_pokedex_species_detail_use_case_test.dart \
  lib/src/ui/canvas/pokedex_workspace.dart \
  test/pokedex_workspace_ui_test.dart

cat /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart
cat /Users/karim/Project/pokemonProject/packages/map_editor/test/ui_panels_smoke_test.dart
wc -l /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart /Users/karim/Project/pokemonProject/packages/map_editor/test/ui_panels_smoke_test.dart
sed -n '1,550p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
sed -n '551,1100p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
sed -n '1101,1700p' /Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart
```

## Résultats réels

### `git status --short` sur le périmètre du mini-fix

Avant création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
?? packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
?? packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart
```

Constat utile :

- `terrain_editor_panel.dart` n’apparaît plus ;
- `ui_panels_smoke_test.dart` n’apparaît plus ;
- le périmètre sale a bien été nettoyé.

Après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
?? packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
?? packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart
?? reports/pokedex-phase-5-cleanup-fix-report.md
```

Constat utile :

- le rapport lui-même est bien le seul nouveau fichier hors code ajouté en plus du fix ;
- les deux fichiers hors scope restaurés ne réapparaissent toujours pas.

### `git diff --stat` sur le périmètre du mini-fix

```text
 .../lib/src/ui/canvas/pokedex_workspace.dart       | 171 ++++++---
 .../map_editor/test/pokedex_workspace_ui_test.dart | 394 ++++++++++++++++++++-
 2 files changed, 523 insertions(+), 42 deletions(-)
```

Constat utile :

- les deux fichiers créés n’apparaissent pas dans ce `diff --stat` parce qu’ils sont encore non suivis ;
- les deux fichiers restaurés hors scope n’y apparaissent plus non plus.

### `git ls-files --others --exclude-standard`

Avant création de ce rapport :

```text
packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart
```

Après création de ce rapport :

```text
packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart
packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart
reports/pokedex-phase-5-cleanup-fix-report.md
```

### Vérification des fichiers hors scope restaurés

`git diff -- packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart packages/map_editor/test/ui_panels_smoke_test.dart`

```text
<aucune sortie>
```

Interprétation :

- les deux fichiers ont bien été remis exactement à l’état `HEAD` ;
- ils ne font plus partie du diff final du fix.

### `dart format`

```text
Formatted 4 files (0 changed) in 0.02 seconds.
```

### `flutter test`

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && \
flutter test \
  test/load_pokedex_species_detail_use_case_test.dart \
  test/pokedex_workspace_ui_test.dart
```

Résultat utile :

```text
00:01 +31: All tests passed!
```

### `flutter analyze`

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor && \
flutter analyze --no-pub \
  lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart \
  test/load_pokedex_species_detail_use_case_test.dart \
  lib/src/ui/canvas/pokedex_workspace.dart \
  test/pokedex_workspace_ui_test.dart
```

Résultat utile :

```text
Analyzing 4 items...
No issues found! (ran in 1.0s)
```

## Contenu complet des fichiers modifiés et créés

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/load_pokedex_species_detail_use_case.dart`

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
      // Les annexes sont réellement optionnelles dans cette phase :
      // - une ref vide/blanche signifie "pas de fichier branché" ;
      // - un fichier absent reste toléré ;
      // - toute autre erreur doit continuer à remonter.
      learnset: await _readOptionalByRef(
        species.refs.learnset,
        (ref) => repository.readLearnsetById(workspace, ref),
      ),
      evolution: await _readOptionalByRef(
        species.refs.evolution,
        (ref) => repository.readEvolutionById(workspace, ref),
      ),
      media: await _readOptionalByRef(
        species.refs.media,
        (ref) => repository.readMediaById(workspace, ref),
      ),
    );
  }

  Future<T?> _readOptionalByRef<T>(
    String rawRef,
    Future<T> Function(String ref) loader,
  ) async {
    final ref = rawRef.trim();
    if (ref.isEmpty) {
      return null;
    }

    try {
      return await loader(ref);
    } on EditorNotFoundException {
      return null;
    }
  }
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/load_pokedex_species_detail_use_case_test.dart`

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

    test('treats blank refs as absent ancillary files without reading',
        () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: '   ',
            evolutionRef: '',
            mediaRef: '\n',
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
      expect(repository.readLearnsetIds, isEmpty);
      expect(repository.readEvolutionIds, isEmpty);
      expect(repository.readMediaIds, isEmpty);
    });

    test('keeps species read mandatory', () async {
      final repository = _FakePokemonReadRepository();

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'missingno'),
        throwsA(isA<Exception>()),
      );
    });

    test('rethrows unexpected ancillary read errors', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: 'bulbasaur',
            evolutionRef: 'bulbasaur',
            mediaRef: 'bulbasaur',
          ),
        },
        learnsetErrorById: <String, Object>{
          'bulbasaur': const FormatException('broken learnset'),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'bulbasaur'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows unexpected evolution read errors', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: '',
            evolutionRef: 'bulbasaur',
            mediaRef: '',
          ),
        },
        evolutionErrorById: <String, Object>{
          'bulbasaur': const FormatException('broken evolution'),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'bulbasaur'),
        throwsA(isA<FormatException>()),
      );
    });

    test('rethrows unexpected media read errors', () async {
      final repository = _FakePokemonReadRepository(
        speciesById: <String, PokemonSpeciesFile>{
          'bulbasaur': _buildSpecies(
            id: 'bulbasaur',
            learnsetRef: '',
            evolutionRef: '',
            mediaRef: 'bulbasaur',
          ),
        },
        mediaErrorById: <String, Object>{
          'bulbasaur': const FormatException('broken media'),
        },
      );

      final useCase = LoadPokedexSpeciesDetailUseCase(repository);

      await expectLater(
        () => useCase.execute(const _FakeWorkspace(), 'bulbasaur'),
        throwsA(isA<FormatException>()),
      );
    });
  });
}

class _FakePokemonReadRepository implements PokemonReadRepository {
  _FakePokemonReadRepository({
    this.speciesById = const <String, PokemonSpeciesFile>{},
    this.learnsetsById = const <String, PokemonLearnsetFile>{},
    this.evolutionsById = const <String, PokemonEvolutionFile>{},
    this.mediaById = const <String, PokemonMediaFile>{},
    this.learnsetErrorById = const <String, Object>{},
    this.evolutionErrorById = const <String, Object>{},
    this.mediaErrorById = const <String, Object>{},
  });

  final Map<String, PokemonSpeciesFile> speciesById;
  final Map<String, PokemonLearnsetFile> learnsetsById;
  final Map<String, PokemonEvolutionFile> evolutionsById;
  final Map<String, PokemonMediaFile> mediaById;
  final Map<String, Object> learnsetErrorById;
  final Map<String, Object> evolutionErrorById;
  final Map<String, Object> mediaErrorById;
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
    final error = learnsetErrorById[speciesId];
    if (error != null) {
      throw error;
    }
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
    final error = evolutionErrorById[speciesId];
    if (error != null) {
      throw error;
    }
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
    final error = mediaErrorById[speciesId];
    if (error != null) {
      throw error;
    }
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
  }) =>
      throw UnimplementedError();

  @override
  Future<List<PokemonSpeciesIndexEntry>> listSpeciesIndexEntries(
    ProjectWorkspace workspace,
  ) =>
      throw UnimplementedError();

  @override
  Future<List<String>> listSpeciesFiles(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<PokemonSpeciesFile> readSpeciesByRelativePath(
    ProjectWorkspace workspace,
    String relativePath,
  ) =>
      throw UnimplementedError();

  @override
  Future<PokemonDataManifest> readManifest(ProjectWorkspace workspace) =>
      throw UnimplementedError();

  @override
  Future<PokemonCatalogFile> readCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
  ) =>
      throw UnimplementedError();

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
  String resolveTilesetPath(String relativePath) =>
      '$projectRoot/$relativePath';

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
  Future<void> deleteDirectoryIfEmpty(String path) =>
      throw UnimplementedError();

  @override
  Future<String> importTilesetImage(
    String sourcePath, {
    String? preferredName,
  }) =>
      throw UnimplementedError();

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

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`

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
        final selectedEntry = _resolveSelectedEntry(filteredEntries);

        // Décision UX explicite du mini-fix :
        // si la sélection courante n'est plus visible dans la liste filtrée,
        // on vide la fiche détail au lieu de garder un élément "fantôme".
        // Le reset d'état est planifié hors build pour rester propre côté
        // Flutter, mais le rendu revient tout de suite à l'état vide car
        // `selectedEntry` est déjà résolu sur la liste visible.
        _clearSelectionIfInvisible(filteredEntries);

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

  void _clearSelectionIfInvisible(
    List<PokemonDatabaseIndexEntry> visibleEntries,
  ) {
    final selectedId = _selectedSpeciesId;
    if (selectedId == null || selectedId.isEmpty) {
      return;
    }

    final stillVisible = visibleEntries.any((entry) => entry.id == selectedId);
    if (stillVisible) {
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_selectedSpeciesId != selectedId) return;
      setState(() {
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
    });
  }

  List<PokemonDatabaseIndexEntry> _filterEntries(
    List<PokemonDatabaseIndexEntry> entries,
  ) {
    final normalizedQuery = _searchQuery.trim();
    final normalizedTextQuery = normalizedQuery.toLowerCase();
    final normalizedDexQuery = _normalizeDexQuery(normalizedQuery);
    final hasExactDexQuery = RegExp(r'^\d+$').hasMatch(normalizedDexQuery);

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

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart`

```dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace_loader.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_ui_test',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  Future<void> pumpPokedexWidget(
    WidgetTester tester,
    ProviderContainer container, {
    required Widget child,
  }) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 1280,
                height: 900,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }

  PokemonDatabaseIndexEntry buildEntry({
    required String id,
    required int nationalDex,
    required String primaryName,
    required List<String> types,
    required int genIntroduced,
  }) {
    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: nationalDex,
      primaryName: primaryName,
      genIntroduced: genIntroduced,
      types: types,
      refs: PokemonDatabaseIndexRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
    );
  }

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

  Future<void> selectPopupFilter(
    WidgetTester tester, {
    required Key popupKey,
    required String itemLabel,
  }) async {
    await tester.tap(find.byKey(popupKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel).last);
    await tester.pumpAndSettle();
  }

  testWidgets('ProjectExplorerPanel shows a Pokédex entry tile',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Ce test verrouille seulement la présence de l'entrée UI dans l'éditeur.
    // Il reste volontairement purement en mémoire pour éviter tout bruit
    // filesystem inutile dans un contrôle aussi simple.
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MacosTheme(
          data: MacosThemeData.light(),
          child: const MaterialApp(
            home: CupertinoPageScaffold(
              child: SizedBox(
                width: 420,
                height: 980,
                child: ProjectExplorerPanel(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byKey(const Key('pokedex-explorer-entry')), findsOneWidget);
    expect(find.text('Pokédex'), findsWidgets);
    expect(find.textContaining('Species list only'), findsOneWidget);
  });

  testWidgets(
      'uses the provider-backed loader by default when no explicit loader is injected',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: const PokedexWorkspace(),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('treecko'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
  });

  testWidgets(
      'prefers the explicitly injected loader over the provider-backed default',
      (tester) async {
    final container = ProviderContainer(
      overrides: [
        pokedexEntryLoaderProvider.overrideWithValue(
          (_) async => <PokemonDatabaseIndexEntry>[
            buildEntry(
              id: 'treecko',
              nationalDex: 252,
              primaryName: 'Treecko',
              types: <String>['grass'],
              genIntroduced: 3,
            ),
          ],
        ),
      ],
    );
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
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Torchic'), findsOneWidget);
    expect(find.text('torchic'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);
    expect(find.text('treecko'), findsNothing);
  });

  testWidgets(
      'renders the simple species list with only number name id and types',
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-species-list')), findsOneWidget);
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('poison'), findsWidgets);

    // Le mini-fix ne doit surtout pas transformer l'écran en lot 14 déguisé.
    expect(find.textContaining('Search'), findsNothing);
    expect(find.textContaining('Filter'), findsNothing);
    expect(find.textContaining('Details'), findsNothing);
    expect(find.textContaining('Import'), findsNothing);
    expect(find.textContaining('Generation'), findsNothing);
    expect(find.textContaining('Edit'), findsNothing);
    expect(find.textContaining('Delete'), findsNothing);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
  });

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

  testWidgets(
      'clears the selection and resets the detail pane when search hides it',
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

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-media-tab')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-media-tab')), findsNothing);
  });

  testWidgets(
      'clears the selection and resets the detail pane when filters hide it',
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
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsOneWidget);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-overview-tab')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-learnset-tab')), findsNothing);
  });

  testWidgets(
      'shows the search field and simple filters in the Pokédex workspace',
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(
      find.text('Rechercher par nom, id ou numéro dex'),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);

    // Audit du lot 15 : aucun filtre activé/désactivé n'est exposé tant
    // qu'aucune donnée lecture seule stable ne l'alimente réellement.
    expect(find.textContaining('Activé'), findsNothing);
    expect(find.textContaining('Désactivé'), findsNothing);
    expect(find.textContaining('Enabled'), findsNothing);
    expect(find.textContaining('Disabled'), findsNothing);
  });

  testWidgets('filters instantly by species primary name', (tester) async {
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();

    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by species id', (tester) async {
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'bulb',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('filters instantly by dex number with exact matching only',
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
            nationalDex: 10,
            primaryName: 'Ivysaur',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '#0001',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsNothing);
  });

  testWidgets('empty query restores the full list', (tester) async {
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'ivy',
    );
    await tester.pump();
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      '   ',
    );
    await tester.pump();

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
  });

  testWidgets('shows a dedicated no results state when search matches nothing',
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(
      find.textContaining('Aucun résultat avec les critères actuels.'),
      findsOneWidget,
    );
    expect(find.textContaining('Recherche actuelle : "zzz"'), findsOneWidget);
    // Le champ reste visible pour corriger immédiatement la query.
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
  });

  testWidgets('filters instantly by type', (tester) async {
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
            id: 'charmander',
            nationalDex: 4,
            primaryName: 'Charmander',
            types: <String>['fire'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'fire',
    );

    expect(find.text('Charmander'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('filters instantly by generation', (tester) async {
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
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
  });

  testWidgets('combines text search with simple filters', (tester) async {
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
            id: 'bellsprout',
            nationalDex: 69,
            primaryName: 'Bellsprout',
            types: <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'tree',
    );
    await tester.pump();
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Bellsprout'), findsNothing);
  });

  testWidgets('combines simple filters together', (tester) async {
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
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
          buildEntry(
            id: 'torchic',
            nationalDex: 255,
            primaryName: 'Torchic',
            types: <String>['fire'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'grass',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );

    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Torchic'), findsNothing);
  });

  testWidgets('clearing all filters restores the full list', (tester) async {
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
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 3',
    );
    expect(find.text('Treecko'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Toutes gén.',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets('shows no results when simple filters eliminate the list',
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
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-type-filter'),
      itemLabel: 'poison',
    );
    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-search-field')),
      'zzz',
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-no-results-state')), findsOneWidget);
    expect(find.textContaining('Aucun résultat avec les critères actuels.'),
        findsOneWidget);
    expect(find.textContaining('Recherche actuelle : "zzz".'), findsOneWidget);
    expect(find.textContaining('Type : poison.'), findsOneWidget);
    expect(find.textContaining('Génération : 1.'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-search-field')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
  });

  testWidgets('shows a loading state before the species list resolves',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final completer = Completer<List<PokemonDatabaseIndexEntry>>();

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_loading_test',
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) => completer.future,
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('pokedex-loading-label')), findsOneWidget);

    // On prouve l'existence de l'état loading, puis on résout explicitement le
    // future avant teardown pour éviter de laisser un timer autoDispose Riverpod
    // en attente à la fin du test.
    completer.complete(const <PokemonDatabaseIndexEntry>[]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('shows an empty state when no species files are present',
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
        loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    expect(find.textContaining('Aucune espèce importée'), findsOneWidget);
  });

  testWidgets('shows an error state when species loading fails',
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
        loader: (_) => Future<List<PokemonDatabaseIndexEntry>>.error(
          const EditorPersistenceException(
            'Invalid JSON in Pokemon species file',
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-error-state')), findsOneWidget);
    expect(find.textContaining('Impossible de charger'), findsOneWidget);
    expect(find.textContaining('Invalid JSON'), findsOneWidget);
  });

  test(
    'returns an empty list when the configured species directory does not exist yet',
    () async {
      final tempProjectRoot =
          await Directory.systemTemp.createTemp('pokedex_loader_test_');
      try {
        final workspace = ProjectFileSystem(tempProjectRoot.path);
        final createProjectUseCase = CreateProjectUseCase(
          FileProjectRepository(),
          const FileProjectWorkspaceFactory(),
        );

        await createProjectUseCase.execute(
          'Pokedex Loader Project',
          tempProjectRoot.path,
        );

        final loader = createPokedexEntryLoader(
          projectRepository: FileProjectRepository(),
          databaseIndex: PokemonDatabaseIndex(
            projectRepository: FileProjectRepository(),
            pokemonReadRepository: const FilePokemonReadRepository(),
          ),
        );

        // Ce test verrouille le vrai nettoyage du mini-fix :
        // l'absence du dossier `species/` doit produire une liste vide
        // explicitement, sans dépendre du texte d'une exception remontée.
        final entries = await loader(workspace);
        expect(entries, isEmpty);
      } finally {
        if (await tempProjectRoot.exists()) {
          await tempProjectRoot.delete(recursive: true);
        }
      }
    },
  );
}
```

## Contenu complet des fichiers restaurés manuellement hors scope

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/ui_panels_smoke_test.dart`

Fichier restauré manuellement à `HEAD` pour sortir du diff final du mini-fix.

```dart
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/ui/canvas/cutscene_studio_workspace.dart';
import 'package:map_editor/src/ui/canvas/dialogue_studio_workspace.dart';
import 'package:map_editor/src/ui/panels/project_explorer_panel.dart';
import 'package:map_editor/src/ui/panels/terrain_editor_panel.dart';
import 'package:map_editor/src/ui/panels/tileset_palette_panel.dart';

void main() {
  group('UI smoke/non-regression panels', () {
    late Directory tempProjectRoot;

    setUp(() async {
      tempProjectRoot =
          await Directory.systemTemp.createTemp('map_editor_ui_smoke_');

      // Le Dialogue Studio lit réellement le fichier référencé quand un
      // dialogue est sélectionné. Ce fixture garde le test honnête sans
      // introduire un bootstrap projet plus lourd que nécessaire.
      final yarn = File(
        '${tempProjectRoot.path}/dialogues/pnj/dlg_hi.yarn',
      );
      await yarn.parent.create(recursive: true);
      await yarn.writeAsString('title: Salut\n---\n<<jump End>>\n===\n');
    });

    tearDown(() async {
      if (await tempProjectRoot.exists()) {
        await tempProjectRoot.delete(recursive: true);
      }
    });

    Future<void> pumpEditorSurface(
      WidgetTester tester,
      ProviderContainer container, {
      required Widget child,
      Size surfaceSize = const Size(1600, 1200),
    }) async {
      await tester.binding.setSurfaceSize(surfaceSize);
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MacosTheme(
            data: MacosThemeData.light(),
            child: MaterialApp(
              home: CupertinoPageScaffold(
                child: Center(
                  child: SizedBox(
                    width: surfaceSize.width,
                    height: surfaceSize.height,
                    child: child,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    ProjectManifest buildSampleProject() {
      return const ProjectManifest(
        name: 'ui_smoke_project',
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'route_1',
            name: 'Route 1',
            relativePath: 'maps/route_1.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[
          ProjectTilesetEntry(
            id: 'tileset_world',
            name: 'World Tileset',
            relativePath: 'tilesets/world.png',
            isWorldTileset: true,
          ),
        ],
        dialogueFolders: <ProjectDialogueFolder>[
          ProjectDialogueFolder(id: 'f_npc', name: 'PNJ'),
        ],
        dialogues: <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'dlg_hi',
            name: 'Salut',
            relativePath: 'dialogues/pnj/dlg_hi.yarn',
            folderId: 'f_npc',
          ),
        ],
        scenarios: <ScenarioAsset>[
          ScenarioAsset(
            id: 'cutscene_intro',
            name: 'Intro cutscene',
            scope: ScenarioScope.localEventFlow,
            entryNodeId: 'start',
            nodes: <ScenarioNode>[
              ScenarioNode(
                id: 'start',
                type: ScenarioNodeType.start,
              ),
              ScenarioNode(
                id: 'source',
                type: ScenarioNodeType.reference,
                binding: ScenarioNodeBinding(
                  mapId: 'route_1',
                  entityId: 'npc_1',
                ),
                payload: ScenarioNodePayload(
                  actionKind: kCutsceneStudioSourceEntityInteract,
                ),
              ),
              ScenarioNode(
                id: 'dialogue_1',
                type: ScenarioNodeType.dialogue,
                binding: ScenarioNodeBinding(
                  entityId: 'npc_1',
                  dialogueId: 'dlg_hi',
                ),
              ),
              ScenarioNode(
                id: 'end',
                type: ScenarioNodeType.end,
              ),
            ],
            edges: <ScenarioEdge>[
              ScenarioEdge(
                id: 'edge_start_source',
                fromNodeId: 'start',
                toNodeId: 'source',
              ),
              ScenarioEdge(
                id: 'edge_source_dialogue',
                fromNodeId: 'source',
                toNodeId: 'dialogue_1',
              ),
              ScenarioEdge(
                id: 'edge_dialogue_end',
                fromNodeId: 'dialogue_1',
                toNodeId: 'end',
              ),
            ],
          ),
        ],
      );
    }

    testWidgets('ProjectExplorerPanel renders world and tileset sections',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 420,
          height: 980,
          child: ProjectExplorerPanel(),
        ),
        surfaceSize: const Size(900, 1200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('World Explorer'), findsOneWidget);
      expect(find.text('Route 1'), findsOneWidget);
      expect(find.text('Tileset Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TerrainEditorPanel renders the two preset libraries',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 520,
          height: 980,
          child: TerrainEditorPanel(),
        ),
        surfaceSize: const Size(900, 1200),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Surface Library'), findsOneWidget);
      expect(find.text('Terrains'), findsOneWidget);
      expect(find.text('Paths'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'TilesetPalettePanel renders selected tileset wiring without crashing',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.tileset,
        selectedTilesetEditorId: 'tileset_world',
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 720,
          height: 980,
          child: TilesetPalettePanel(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('World Tileset'), findsOneWidget);
      expect(find.text('Tileset image unavailable'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'DialogueStudioWorkspace renders library and selected dialogue without crashing',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      container.read(editorNotifierProvider.notifier).state = EditorState(
        projectRootPath: tempProjectRoot.path,
        project: project,
        workspaceMode: EditorWorkspaceMode.dialogue,
        selectedProjectDialogueId: 'dlg_hi',
      );

      await pumpEditorSurface(
        tester,
        container,
        child: const SizedBox(
          width: 1280,
          height: 900,
          child: DialogueStudioWorkspace(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Importer .yarn / .txt'), findsOneWidget);
      expect(find.text('PNJ'), findsWidgets);
      expect(find.text('Salut'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'CutsceneStudioWorkspace renders an editable local-event flow scenario',
        (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final project = buildSampleProject();
      final projection = buildNarrativeWorkspaceProjection(project);
      final selectedCutscene = projection.localEventFlows.firstWhere(
        (scenario) => scenario.id == 'cutscene_intro',
      );
      final notifier = container.read(editorNotifierProvider.notifier);

      await pumpEditorSurface(
        tester,
        container,
        child: SizedBox(
          width: 1400,
          height: 900,
          child: CutsceneStudioWorkspace(
            editorNotifier: notifier,
            project: project,
            activeMap: null,
            projection: projection,
            selectedCutscene: selectedCutscene,
            onSelectCutscene: (_) {},
            onSelectOutcome: (_) {},
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Configurer la source'), findsOneWidget);
      expect(find.text('Cutscene'), findsWidgets);
      expect(tester.takeException(), isNull);
    });
  });
}
```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/panels/terrain_editor_panel.dart`

Fichier restauré manuellement à `HEAD` pour sortir du diff final du mini-fix.

```dart
import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/shared/cupertino_editor_widgets.dart';
import 'package:map_editor/src/ui/shared/editor_paint_palette.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';

part 'terrain_editor/dialogs/terrain_preset_dialogs.dart';
part 'terrain_editor/widgets/terrain_mapping_workspace.dart';

class TerrainEditorPanel extends ConsumerWidget {
  const TerrainEditorPanel({
    super.key,

    /// Masque le bandeau « Surface Library » quand l’en-tête est géré par le parent (explorateur).
    this.omitOuterHeader = false,
  });

  final bool omitOuterHeader;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(editorTerrainLibrarySnapshotProvider);
    final project = snapshot.project;
    final settings = snapshot.settings;
    final tilesets = snapshot.tilesets;

    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final subtle = CupertinoColors.placeholderText.resolveFrom(context);
    return Column(
      children: [
        if (!omitOuterHeader) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        EditorChrome.accentWarm.withValues(alpha: 0.22),
                        EditorChrome.accentJade.withValues(alpha: 0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const MacosIcon(
                    CupertinoIcons.square_stack_3d_down_right_fill,
                    size: 18,
                    color: EditorChrome.accentWarm,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Surface Library',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: EditorChrome.primaryLabel(context),
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ground presets and path overlays for your world',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: EditorChrome.chipFill(context),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${(snapshot.selectedTerrainPresetId != null ? 1 : 0) + (snapshot.selectedPathPresetId != null ? 1 : 0)} active',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: secondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
        ],
        Expanded(
          child: project == null
              ? Center(
                  child: Text(
                    'Open a project to manage terrain and surface presets',
                    style: TextStyle(color: subtle),
                  ),
                )
              : SingleChildScrollView(
                  primary: false,
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LibraryRoot(
                        title: 'Terrains',
                        subtitle: 'Base ground presets only',
                        kind: PresetLibraryKind.terrain,
                        color: EditorChrome.accentJade,
                        icon: CupertinoIcons.map,
                        settings: settings,
                        tilesets: tilesets,
                        selectedPresetId: snapshot.selectedTerrainPresetId,
                      ),
                      const SizedBox(height: 12),
                      _LibraryRoot(
                        title: 'Paths',
                        subtitle:
                            'Surface overlays: roads, water, tall grass, ice, lava, rails...',
                        kind: PresetLibraryKind.path,
                        color: EditorChrome.accentWarm,
                        icon: CupertinoIcons.arrow_branch,
                        settings: settings,
                        tilesets: tilesets,
                        selectedPresetId: snapshot.selectedPathPresetId,
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
}

class _LibraryRoot extends ConsumerStatefulWidget {
  const _LibraryRoot({
    required this.title,
    required this.subtitle,
    required this.kind,
    required this.color,
    required this.icon,
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final String title;
  final String subtitle;
  final PresetLibraryKind kind;
  final Color color;
  final IconData icon;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_LibraryRoot> createState() => _LibraryRootState();
}

class _LibraryRootState extends ConsumerState<_LibraryRoot> {
  bool _expanded = true;
  bool _detailsExpanded = true;

  @override
  Widget build(BuildContext context) {
    final title = widget.title;
    final subtitle = widget.subtitle;
    final kind = widget.kind;
    final color = widget.color;
    final icon = widget.icon;
    final settings = widget.settings;
    final tilesets = widget.tilesets;
    final selectedPresetId = widget.selectedPresetId;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories = notifier.getPresetCategories(kind: kind);
    final uncategorizedPresets = _rootPresets(notifier, kind);
    final selectedPreset = kind == PresetLibraryKind.terrain
        ? notifier.getTerrainPresetById(selectedPresetId)
        : notifier.getPathPresetById(selectedPresetId);
    final presetCount = kind == PresetLibraryKind.terrain
        ? notifier.getTerrainPresets().length
        : notifier.getPathPresets().length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              color.withValues(alpha: 0.04),
              EditorChrome.islandFillElevated(context),
            ),
            Color.alphaBlend(
              color.withValues(alpha: 0.015),
              EditorChrome.islandFill(context),
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: color),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemFill.resolveFrom(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$presetCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: kind,
                  ),
                  icon: CupertinoIcons.folder_badge_plus,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: kind,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                  icon: CupertinoIcons.add_circled,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: _expanded ? 'Collapse section' : 'Expand section',
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  iconSize: 18,
                ),
              ],
            ),
          ),
          if (_expanded) const EditorHorizontalDivider(),
          if (_expanded && categories.isEmpty && uncategorizedPresets.isEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                kind == PresetLibraryKind.terrain
                    ? 'No terrain preset or folder yet'
                    : 'No path preset or folder yet',
                style: TextStyle(
                  fontSize: 11,
                  color: CupertinoColors.secondaryLabel.resolveFrom(context),
                ),
              ),
            )
          else if (_expanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ...categories.map(
                    (category) => _CategoryNode(
                      category: category,
                      kind: kind,
                      depth: 0,
                      color: color,
                      settings: settings,
                      tilesets: tilesets,
                      selectedPresetId: selectedPresetId,
                    ),
                  ),
                  ...uncategorizedPresets.map(
                    (preset) => _PresetNode(
                      kind: kind,
                      preset: preset,
                      depth: 0,
                      color: color,
                      settings: settings,
                      tilesets: tilesets,
                      selected: _presetId(preset) == selectedPresetId,
                    ),
                  ),
                ],
              ),
            ),
          if (_expanded && selectedPreset != null) ...[
            const EditorHorizontalDivider(),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _detailsExpanded = !_detailsExpanded;
                      });
                    },
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Selected Preset',
                            style: TextStyle(
                              fontSize: 11,
                              color: color,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Icon(
                          _detailsExpanded
                              ? CupertinoIcons.chevron_up
                              : CupertinoIcons.chevron_down,
                          size: 18,
                          color: CupertinoColors.secondaryLabel
                              .resolveFrom(context),
                        ),
                      ],
                    ),
                  ),
                  if (_detailsExpanded) ...[
                    const SizedBox(height: 8),
                    _PresetDetailsCard(
                      kind: kind,
                      preset: selectedPreset,
                      color: color,
                      settings: settings,
                      tilesets: tilesets,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  List<dynamic> _rootPresets(EditorNotifier notifier, PresetLibraryKind kind) {
    if (kind == PresetLibraryKind.terrain) {
      return notifier
          .getTerrainPresets()
          .where((preset) => preset.categoryId == null)
          .toList(growable: false);
    }
    return notifier
        .getPathPresets()
        .where((preset) => preset.categoryId == null)
        .toList(growable: false);
  }
}

Future<void> _openTerrainCategoryFolderMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset anchorGlobal,
  required ProjectPresetCategory category,
  required PresetLibraryKind kind,
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  final notifier = ref.read(editorNotifierProvider.notifier);
  final action = await showMacosEditorContextMenu<String>(
    context: context,
    globalPosition: anchorGlobal,
    actions: const [
      MacosEditorSheetAction(
        label: 'New Subfolder',
        value: 'new_folder',
      ),
      MacosEditorSheetAction(
        label: 'New Preset',
        value: 'new_preset',
      ),
      MacosEditorSheetAction(
        label: 'Rename Folder',
        value: 'rename',
      ),
      MacosEditorSheetAction(
        label: 'Delete Folder',
        value: 'delete',
        isDestructive: true,
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  switch (action) {
    case 'new_folder':
      await _showCreateCategoryDialog(
        context,
        notifier: notifier,
        kind: kind,
        parentCategoryId: category.id,
      );
    case 'new_preset':
      await _showCreatePresetDialog(
        context,
        notifier: notifier,
        kind: kind,
        settings: settings,
        tilesets: tilesets,
        categoryId: category.id,
      );
    case 'rename':
      await _showRenameCategoryDialog(
        context,
        notifier: notifier,
        kind: kind,
        category: category,
      );
    case 'delete':
      await _showDeleteCategoryDialog(
        context,
        notifier: notifier,
        kind: kind,
        category: category,
      );
  }
}

Future<void> _openTerrainPresetRowMenu({
  required BuildContext context,
  required WidgetRef ref,
  required Offset anchorGlobal,
  required PresetLibraryKind kind,
  required dynamic preset,
  required ProjectSettings settings,
  required List<ProjectTilesetEntry> tilesets,
}) async {
  final notifier = ref.read(editorNotifierProvider.notifier);
  final action = await showMacosEditorContextMenu<String>(
    context: context,
    globalPosition: anchorGlobal,
    actions: const [
      MacosEditorSheetAction(
        label: 'Edit Preset',
        value: 'edit',
      ),
      MacosEditorSheetAction(
        label: 'Delete Preset',
        value: 'delete',
        isDestructive: true,
      ),
    ],
  );
  if (!context.mounted || action == null) return;
  if (action == 'edit') {
    await _showEditPresetDialog(
      context,
      notifier: notifier,
      kind: kind,
      settings: settings,
      preset: preset,
      tilesets: tilesets,
    );
  } else if (action == 'delete') {
    await _showDeletePresetDialog(
      context,
      notifier: notifier,
      kind: kind,
      preset: preset,
    );
  }
}

class _CategoryNode extends ConsumerStatefulWidget {
  const _CategoryNode({
    required this.category,
    required this.kind,
    required this.depth,
    required this.color,
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectPresetCategory category;
  final PresetLibraryKind kind;
  final int depth;
  final Color color;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_CategoryNode> createState() => _CategoryNodeState();
}

class _CategoryNodeState extends ConsumerState<_CategoryNode> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final children =
        notifier.getPresetCategories(kind: widget.kind, parentCategoryId: widget.category.id);
    final presets = widget.kind == PresetLibraryKind.terrain
        ? notifier
            .getTerrainPresets()
            .where((preset) => preset.categoryId == widget.category.id)
            .toList(growable: false)
        : notifier
            .getPathPresets()
            .where((preset) => preset.categoryId == widget.category.id)
            .toList(growable: false);

    final childWidgets = [
      if (_expanded) ...[
        ...children.map(
          (child) => _CategoryNode(
            category: child,
            kind: widget.kind,
            depth: widget.depth + 1,
            color: widget.color,
            settings: widget.settings,
            tilesets: widget.tilesets,
            selectedPresetId: widget.selectedPresetId,
          ),
        ),
        ...presets.map(
          (preset) => _PresetNode(
            kind: widget.kind,
            preset: preset,
            depth: widget.depth + 1,
            color: widget.color,
            settings: widget.settings,
            tilesets: widget.tilesets,
            selected: _presetId(preset) == widget.selectedPresetId,
          ),
        ),
      ],
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoButton(
          padding: EdgeInsets.only(left: 12.0 + widget.depth * 16.0, right: 4),
          onPressed: () {
            setState(() {
              _expanded = !_expanded;
            });
          },
          child: Row(
            children: [
              Icon(
                _expanded ? CupertinoIcons.chevron_down : CupertinoIcons.chevron_right,
                size: 16,
                color: CupertinoColors.secondaryLabel.resolveFrom(context),
              ),
              const SizedBox(width: 6),
              Icon(CupertinoIcons.folder, size: 16, color: widget.color),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.category.name,
                      style: TextStyle(
                        fontSize: 12,
                        color: CupertinoColors.label.resolveFrom(context),
                      ),
                    ),
                    Text(
                      '${children.length} folders • ${presets.length} presets',
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.secondaryLabel.resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              EditorToolbarIconButton(
                icon: CupertinoIcons.ellipsis_vertical,
                tooltip: 'Folder actions',
                onPressed: () => _openTerrainCategoryFolderMenu(
                  context: context,
                  ref: ref,
                  anchorGlobal: editorMenuAnchorBelowWidget(context),
                  category: widget.category,
                  kind: widget.kind,
                  settings: widget.settings,
                  tilesets: widget.tilesets,
                ),
              ),
            ],
          ),
        ),
        ...childWidgets,
      ],
    );
  }
}

class _PresetNode extends ConsumerWidget {
  const _PresetNode({
    required this.kind,
    required this.preset,
    required this.depth,
    required this.color,
    required this.settings,
    required this.tilesets,
    required this.selected,
  });

  final PresetLibraryKind kind;
  final dynamic preset;
  final int depth;
  final Color color;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);

    final label = CupertinoColors.label.resolveFrom(context);
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    return GestureDetector(
      onSecondaryTapDown: (d) => _openTerrainPresetRowMenu(
        context: context,
        ref: ref,
        anchorGlobal: d.globalPosition,
        kind: kind,
        preset: preset,
        settings: settings,
        tilesets: tilesets,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.16) : null,
          border: Border(
            bottom: BorderSide(
              color: CupertinoColors.separator.resolveFrom(context),
            ),
          ),
        ),
        child: CupertinoButton(
          padding: EdgeInsets.only(
              left: 44.0 + depth * 16.0, right: 4, top: 6, bottom: 6),
          minimumSize: Size.zero,
          onPressed: () {
            if (kind == PresetLibraryKind.terrain) {
              notifier.selectTerrainPreset(preset.id);
            } else {
              notifier.selectPathPreset(preset.id);
            }
          },
          child: Row(
            children: [
              Icon(
                kind == PresetLibraryKind.terrain
                    ? CupertinoIcons.square_grid_2x2
                    : CupertinoIcons.arrow_branch,
                size: 16,
                color: selected ? color : secondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      preset.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? label : secondary,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w400,
                      ),
                    ),
                    Text(
                      kind == PresetLibraryKind.terrain
                          ? _terrainLabel(
                              (preset as ProjectTerrainPreset).terrainType,
                            )
                          : _pathTraversalLabel(
                              _pathTraversalTypeFromSurfaceKind(
                                (preset as ProjectPathPreset).surfaceKind,
                              ),
                            ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10,
                        color: CupertinoColors.placeholderText
                            .resolveFrom(context),
                      ),
                    ),
                  ],
                ),
              ),
              Builder(
                builder: (btnContext) => EditorToolbarIconButton(
                  icon: CupertinoIcons.ellipsis_vertical,
                  tooltip: 'Preset actions',
                  onPressed: () => _openTerrainPresetRowMenu(
                    context: context,
                    ref: ref,
                    anchorGlobal: editorMenuAnchorBelowWidget(btnContext),
                    kind: kind,
                    preset: preset,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PresetDetailsCard extends ConsumerWidget {
  const _PresetDetailsCard({
    required this.kind,
    required this.preset,
    required this.color,
    required this.settings,
    required this.tilesets,
  });

  final PresetLibraryKind kind;
  final dynamic preset;
  final Color color;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categoryPath = notifier.resolvePresetCategoryPath(
      kind: kind,
      categoryId: preset.categoryId as String?,
    );
    final tilesetName =
        _resolveTilesetName(tilesets, preset.tilesetId as String);
    final tilesetId = (preset.tilesetId as String).trim();
    final terrainPreset = kind == PresetLibraryKind.terrain
        ? preset as ProjectTerrainPreset
        : null;
    final pathPreset =
        kind == PresetLibraryKind.path ? preset as ProjectPathPreset : null;

    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);
    final label = CupertinoColors.label.resolveFrom(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: CupertinoColors.systemFill.resolveFrom(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preset.name as String,
            style: TextStyle(
              fontSize: 12,
              color: label,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            kind == PresetLibraryKind.terrain
                ? 'Base type: ${_terrainLabel(terrainPreset!.terrainType)}'
                : 'Surface type: ${_pathTraversalLabel(_pathTraversalTypeFromSurfaceKind(pathPreset!.surfaceKind))}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            'Folder: ${categoryPath ?? 'Root'}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            'Tileset: ${tilesetName.isEmpty ? 'None' : tilesetName}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          const SizedBox(height: 2),
          Text(
            kind == PresetLibraryKind.terrain
                ? 'Variants: ${terrainPreset!.variants.length}'
                : 'Autotile mappings: ${pathPreset!.variants.length}/${TerrainPathVariant.values.length}',
            style: TextStyle(fontSize: 11, color: secondary),
          ),
          if (tilesetId.isNotEmpty) ...[
            const SizedBox(height: 10),
            _buildTilesetPreview(
              notifier: notifier,
              tilesetId: tilesetId,
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CupertinoButton(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                onPressed: () => _showEditPresetDialog(
                  context,
                  notifier: notifier,
                  kind: kind,
                  settings: settings,
                  preset: preset,
                  tilesets: tilesets,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.pencil, size: 16),
                    const SizedBox(width: 6),
                    Text('Edit Preset', style: TextStyle(color: label)),
                  ],
                ),
              ),
              if (kind == PresetLibraryKind.terrain)
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: tilesetId.isEmpty
                      ? null
                      : () => _runTerrainMemberAssistant(
                            context,
                            notifier: notifier,
                            settings: settings,
                            preset: terrainPreset!,
                          ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.square_grid_2x2, size: 16),
                      const SizedBox(width: 6),
                      Text('Edit Sprites', style: TextStyle(color: label)),
                    ],
                  ),
                ),
              if (kind == PresetLibraryKind.path)
                CupertinoButton(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  onPressed: tilesetId.isEmpty
                      ? null
                      : () => _runPathMappingAssistant(
                            context,
                            notifier: notifier,
                            settings: settings,
                            preset: pathPreset!,
                          ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(CupertinoIcons.arrow_branch, size: 16),
                      const SizedBox(width: 6),
                      Text('Edit Mapping', style: TextStyle(color: label)),
                    ],
                  ),
                ),
            ],
          ),

        ],
      ),
    );
  }
}

class _PresetCategorySection extends ConsumerWidget {
  const _PresetCategorySection({
    required this.category,
    required this.kind,
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
    required this.notifier,
    required this.onChanged,
  });

  final ProjectPresetCategory? category;
  final PresetLibraryKind kind;
  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;
  final EditorNotifier notifier;
  final VoidCallback onChanged;

  Color get _color => kind == PresetLibraryKind.terrain ? EditorChrome.accentJade : EditorChrome.accentWarm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uncategorizedPresets = category == null
        ? _rootPresets(notifier, kind)
        : kind == PresetLibraryKind.terrain
            ? notifier
                .getTerrainPresets()
                .where((preset) => preset.categoryId == category?.id)
                .toList(growable: false)
            : notifier
                .getPathPresets()
                .where((preset) => preset.categoryId == category?.id)
                .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (category != null)
          _CategoryNode(
            category: category!,
            kind: kind,
            depth: 0,
            color: _color,
            settings: settings,
            tilesets: tilesets,
            selectedPresetId: selectedPresetId,
          ),
        ...uncategorizedPresets.map(
          (preset) => _PresetNode(
            kind: kind,
            preset: preset,
            depth: category == null ? 0 : 1,
            color: _color,
            settings: settings,
            tilesets: tilesets,
            selected: _presetId(preset) == selectedPresetId,
          ),
        ),
      ],
    );
  }

  List<dynamic> _rootPresets(EditorNotifier notifier, PresetLibraryKind kind) {
    if (kind == PresetLibraryKind.terrain) {
      return notifier
          .getTerrainPresets()
          .where((preset) => preset.categoryId == null)
          .toList(growable: false);
    }
    return notifier
        .getPathPresets()
        .where((preset) => preset.categoryId == null)
        .toList(growable: false);
  }

  String _presetId(dynamic preset) {
    return preset.id;
  }
}

class _CategoryOption {
  const _CategoryOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

class TerrainLibraryPanel extends ConsumerWidget {
  const TerrainLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(editorTerrainLibrarySnapshotProvider);
    final project = snapshot.project;

    return project == null
        ? Center(
            child: Text(
              'Open a project to manage terrain presets',
              style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            ),
          )
        : _TerrainLibraryContent(
            settings: snapshot.settings,
            tilesets: snapshot.tilesets,
            selectedPresetId: snapshot.selectedTerrainPresetId,
          );
  }
}

class _TerrainLibraryContent extends ConsumerStatefulWidget {
  const _TerrainLibraryContent({
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_TerrainLibraryContent> createState() => _TerrainLibraryContentState();
}

class _TerrainLibraryContentState extends ConsumerState<_TerrainLibraryContent> {
  bool _expanded = true;

  List<dynamic> _rootPresets(EditorNotifier notifier, PresetLibraryKind kind) {
    if (kind == PresetLibraryKind.terrain) {
      return notifier
          .getTerrainPresets()
          .where((preset) => preset.categoryId == null)
          .toList(growable: false);
    }
    return notifier
        .getPathPresets()
        .where((preset) => preset.categoryId == null)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final tilesets = widget.tilesets;
    final selectedPresetId = widget.selectedPresetId;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories = notifier.getPresetCategories(kind: PresetLibraryKind.terrain);
    final uncategorizedPresets = _rootPresets(notifier, PresetLibraryKind.terrain);
    final selectedPreset = notifier.getTerrainPresetById(selectedPresetId);
    final presetCount = notifier.getTerrainPresets().length;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    final treeColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.map,
                          size: 16,
                          color: EditorChrome.accentJade,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Terrains',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Base ground presets only',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemFill.resolveFrom(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$presetCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.terrain,
                  ),
                  icon: CupertinoIcons.folder_badge_plus,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.terrain,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                  icon: CupertinoIcons.add_circled,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: _expanded ? 'Collapse section' : 'Expand section',
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  iconSize: 18,
                ),
              ],
            ),
          ),
        if (_expanded) const EditorHorizontalDivider(),
        if (_expanded && categories.isEmpty && uncategorizedPresets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No terrain preset or folder yet',
              style: TextStyle(
                fontSize: 11,
                color: secondary,
              ),
            ),
          )
        else if (_expanded)
          Expanded(
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (categories.isNotEmpty) ...[
                    for (final category in categories)
                      _PresetCategorySection(
                        category: category,
                        kind: PresetLibraryKind.terrain,
                        settings: settings,
                        tilesets: tilesets,
                        selectedPresetId: selectedPresetId,
                        notifier: notifier,
                        onChanged: () => setState(() {}),
                      ),
                    const SizedBox(height: 8),
                  ],
                  if (uncategorizedPresets.isNotEmpty) ...[
                    _PresetCategorySection(
                      category: null,
                      kind: PresetLibraryKind.terrain,
                      settings: settings,
                      tilesets: tilesets,
                      selectedPresetId: selectedPresetId,
                      notifier: notifier,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );

    final detailsSection = selectedPreset != null
      ? Column(
          children: [
            const EditorHorizontalDivider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildPresetDetailsContent(
                context: context,
                ref: ref,
                preset: selectedPreset,
                kind: PresetLibraryKind.terrain,
                settings: settings,
                tilesets: tilesets,
              ),
            ),
          ],
        )
      : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        treeColumn,
        if (detailsSection != null) detailsSection,
      ],
    );
  }
}

class PathLibraryPanel extends ConsumerWidget {
  const PathLibraryPanel({
    super.key,
    this.embedded = false,
  });

  final bool embedded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshot = ref.watch(editorTerrainLibrarySnapshotProvider);
    final project = snapshot.project;

    return project == null
        ? Center(
            child: Text(
              'Open a project to manage path presets',
              style: TextStyle(color: CupertinoColors.secondaryLabel.resolveFrom(context)),
            ),
          )
        : _PathLibraryContent(
            settings: snapshot.settings,
            tilesets: snapshot.tilesets,
            selectedPresetId: snapshot.selectedPathPresetId,
          );
  }
}

class _PathLibraryContent extends ConsumerStatefulWidget {
  const _PathLibraryContent({
    required this.settings,
    required this.tilesets,
    required this.selectedPresetId,
  });

  final ProjectSettings settings;
  final List<ProjectTilesetEntry> tilesets;
  final String? selectedPresetId;

  @override
  ConsumerState<_PathLibraryContent> createState() => _PathLibraryContentState();
}

class _PathLibraryContentState extends ConsumerState<_PathLibraryContent> {
  bool _expanded = true;

  List<dynamic> _rootPresets(EditorNotifier notifier, PresetLibraryKind kind) {
    if (kind == PresetLibraryKind.terrain) {
      return notifier
          .getTerrainPresets()
          .where((preset) => preset.categoryId == null)
          .toList(growable: false);
    }
    return notifier
        .getPathPresets()
        .where((preset) => preset.categoryId == null)
        .toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = widget.settings;
    final tilesets = widget.tilesets;
    final selectedPresetId = widget.selectedPresetId;
    final notifier = ref.read(editorNotifierProvider.notifier);
    final categories = notifier.getPresetCategories(kind: PresetLibraryKind.path);
    final uncategorizedPresets = _rootPresets(notifier, PresetLibraryKind.path);
    final selectedPreset = notifier.getPathPresetById(selectedPresetId);
    final presetCount = notifier.getPathPresets().length;
    final secondary = CupertinoColors.secondaryLabel.resolveFrom(context);

    final treeColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_expanded)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 10, 8),
            child: Row(
              children: [
                Expanded(
                  child: CupertinoButton(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    minimumSize: Size.zero,
                    onPressed: () {
                      setState(() {
                        _expanded = !_expanded;
                      });
                    },
                    child: Row(
                      children: [
                        const Icon(
                          CupertinoIcons.arrow_branch,
                          size: 16,
                          color: EditorChrome.accentWarm,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Paths',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: EditorChrome.primaryLabel(context),
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                'Surface overlays: roads, water, tall grass, ice, lava, rails...',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: CupertinoColors.secondaryLabel
                                      .resolveFrom(context),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                CupertinoColors.systemFill.resolveFrom(context),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$presetCount',
                            style: TextStyle(
                              fontSize: 10,
                              color: CupertinoColors.secondaryLabel
                                  .resolveFrom(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                EditorToolbarIconButton(
                  tooltip: 'New folder',
                  onPressed: () => _showCreateCategoryDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.path,
                  ),
                  icon: CupertinoIcons.folder_badge_plus,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: 'New preset',
                  onPressed: () => _showCreatePresetDialog(
                    context,
                    notifier: notifier,
                    kind: PresetLibraryKind.path,
                    settings: settings,
                    tilesets: tilesets,
                  ),
                  icon: CupertinoIcons.add_circled,
                  iconSize: 18,
                ),
                EditorToolbarIconButton(
                  tooltip: _expanded ? 'Collapse section' : 'Expand section',
                  onPressed: () {
                    setState(() {
                      _expanded = !_expanded;
                    });
                  },
                  icon: _expanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  iconSize: 18,
                ),
              ],
            ),
          ),
        if (_expanded) const EditorHorizontalDivider(),
        if (_expanded && categories.isEmpty && uncategorizedPresets.isEmpty)
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'No path preset or folder yet',
              style: TextStyle(
                fontSize: 11,
                color: secondary,
              ),
            ),
          )
        else if (_expanded)
          Expanded(
            child: SingleChildScrollView(
              primary: false,
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (categories.isNotEmpty) ...[
                    for (final category in categories)
                      _PresetCategorySection(
                        category: category,
                        kind: PresetLibraryKind.path,
                        settings: settings,
                        tilesets: tilesets,
                        selectedPresetId: selectedPresetId,
                        notifier: notifier,
                        onChanged: () => setState(() {}),
                      ),
                    const SizedBox(height: 8),
                  ],
                  if (uncategorizedPresets.isNotEmpty) ...[
                    _PresetCategorySection(
                      category: null,
                      kind: PresetLibraryKind.path,
                      settings: settings,
                      tilesets: tilesets,
                      selectedPresetId: selectedPresetId,
                      notifier: notifier,
                      onChanged: () => setState(() {}),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      );

    final detailsSection = selectedPreset != null
      ? Column(
          children: [
            const EditorHorizontalDivider(),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: _buildPresetDetailsContent(
                context: context,
                ref: ref,
                preset: selectedPreset,
                kind: PresetLibraryKind.path,
                settings: settings,
                tilesets: tilesets,
              ),
            ),
          ],
        )
      : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        treeColumn,
        if (detailsSection != null) detailsSection,
      ],
    );
  }
}
```

## Lecture honnête du résultat final

Ce qui est maintenant propre :

- le diff final du fix est bien centré sur Pokédex ;
- les fichiers hors scope ne traînent plus dans le working tree pour ce mini-fix ;
- le use case détail distingue correctement :
  - espèce obligatoire,
  - annexe absente,
  - vraie erreur ;
- la règle UX sélection vs filtres/recherche est maintenant explicite et testée.

Ce qui reste volontairement hors scope :

- refactor plus large de `pokedex_workspace.dart` ;
- providers plus fins ;
- amélioration éventuelle de l’état UI local ;
- tout le reste de la phase 5 qui n’était pas en cause ici ;
- les phases 6+.

Ce qui pourrait être amélioré plus tard mais n’a pas été touché :

- déplacer éventuellement la logique de sélection locale vers un state holder dédié si un futur lot l’exige ;
- factoriser certains builders de tests UI ;
- réduire la taille de `pokedex_workspace_ui_test.dart` si d’autres lots y ajoutent encore de la couverture.

## Checklist d’autocontrôle finale

### Scope

- [x] Je n’ai corrigé que les problèmes demandés
- [x] Je n’ai pas ouvert un nouveau chantier
- [x] Je n’ai pas commencé un lot suivant
- [x] Je n’ai pas ajouté d’édition, d’import, de runtime ou de save
- [x] Je n’ai pas modifié `project.json`

### Périmètre Git

- [x] Je n’ai effectué aucune commande Git d’écriture
- [x] `terrain_editor_panel.dart` ne fait plus partie du diff final du fix
- [x] `ui_panels_smoke_test.dart` ne fait plus partie du diff final du fix
- [x] Le diff final est proprement centré sur le mini-fix Pokédex

### Use case

- [x] Les refs vides sont traitées proprement
- [x] Les fichiers annexes absents restent tolérés
- [x] Les autres erreurs remontent toujours

### UI

- [x] Une sélection invisible après filtre/recherche est bien effacée
- [x] Le panneau détail revient bien à l’état vide
- [x] L’onglet revient bien à `overview`

### Qualité

- [x] Le code est formaté
- [x] Les tests ciblés passent
- [x] L’analyse ciblée passe
- [x] Le rapport Markdown a été créé
- [x] Le rapport contient le contenu complet de tous les fichiers touchés
```
