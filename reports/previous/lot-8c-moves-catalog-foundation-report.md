# Lot 8c — Moves Catalog Foundation / Local Project Move Catalog

## 1. Résumé exécutif honnête

Le lot 8c est réussi.

`Catalogues Pokémon > Moves` dispose maintenant d’un vrai workspace local dans `map_editor` :

- lecture du catalogue moves du projet courant ;
- recherche locale ;
- liste + détail ;
- diagnostics non bloquants pour les entrées invalides ;
- états `aucun projet`, `catalogue manquant`, `catalogue vide`, `catalogue totalement invalide`, `catalogue chargé`.

Le lot n’introduit aucun fetch réseau, ne touche ni `map_battle` ni `map_runtime`, et ne réouvre pas la navigation `Catalogues Pokémon` corrigée au post-8b.

Point d’architecture important : le prompt recommandait un dossier `data/pokemon/moves/<id>.json`, mais le repo a déjà une convention réelle et active autour de `data/pokemon/catalogs/moves.json`. J’ai suivi la convention existante du repo pour éviter d’ouvrir un second système local concurrent, ce qui aurait rendu le lot 8d plus sale.

## 2. État git initial

Pré-gates réellement exécutés avant modification :

```bash
$ git status --short --untracked-files=all
# no output
```

```bash
$ git diff --stat
# no output
```

```bash
$ git ls-files --others --exclude-standard
# no output
```

## 3. Fichiers lus

### Reports

- `reports/lot-8b-pokemon-catalogs-workspace-shell-report.md`
- `reports/lot-8b-fix-pokemon-catalogs-navigation-correction-report.md`
- `reports/lot-8a-battle-bag-menu-contract-report.md`
- `reports/lot-7-battle-pokemon-menu-end-to-end-report.md`

### Shell `Catalogues Pokémon`

- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/features/editor/application/editor_workspace_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/models/pokemon_catalog_section.dart`

### Pokédex / catalogues existants

- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_list_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`
- `packages/map_editor/lib/src/application/services/pokemon_moves_catalog_lookup_service.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/app/providers/core/repository_providers.dart`
- `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart`

### Tests

- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/shell_chrome_test_harness.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
- `packages/map_editor/test/project_pokemon_config_test.dart`
- `packages/map_editor/test/file_pokemon_read_repository_test.dart`

## 4. Fichiers modifiés / créés

### Modifiés

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

### Créés

- `packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_editor/test/pokemon_moves_catalog_loader_test.dart`
- `packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart`

## 5. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_runtime/**`
- `examples/playable_runtime_host/**`
- `packages/map_core/**`
- `packages/map_editor/lib/src/ui/shared/top_toolbar.dart`
- `packages/map_editor/lib/src/ui/canvas/editor_canvas_host.dart`

Je n’ai pas rouvert la navigation globale du shell ni le parent `Catalogues Pokémon` au-delà du wiring minimal nécessaire pour remplacer le placeholder `Moves` par un vrai workspace.

## 6. Décision d’architecture

### Emplacement des moves

Le repo possède déjà une convention active pour les catalogues Pokémon locaux :

```text
data/pokemon/catalogs/moves.json
```

Cette convention est utilisée ailleurs dans `map_editor`, dans le storage Pokémon et dans les tests de lecture/écriture de catalogues. Je l’ai donc conservée au lieu d’introduire un nouveau dossier `data/pokemon/moves/*.json`.

### Format JSON retenu

Le lot 8c ne crée pas un nouveau format transversal. Il étend la projection du catalogue local existant pour accepter proprement des entrées locales de ce style :

```json
{
  "id": "water-gun",
  "name": "Water Gun",
  "typeId": "water",
  "damageClass": "special",
  "power": 40,
  "accuracy": 100,
  "pp": 25,
  "priority": 0,
  "target": "selected-pokemon",
  "generationId": "generation-i",
  "effectText": "Inflicts regular damage.",
  "shortEffectText": "Inflicts regular damage."
}
```

Le loader accepte aussi les entrées canoniques déjà produites via `PokemonMove.toJson()`, ce qui évite de casser le pipeline existant de sync/local projection.

### Modèle

J’ai volontairement réutilisé et étendu le seam déjà présent au lieu d’introduire un deuxième modèle parallèle :

- `PokemonMoveCatalogEntryView`
- `PokemonMovesCatalogView`
- `PokemonMovesCatalogDiagnostic`
- `PokemonMovesCatalogLoadState`

Cela garde la fondation locale petite, cohérente avec le repo, et compatible avec le futur lot 8d.

### Loader

Le chargement réel vit dans `LoadPokemonMovesCatalogUseCase` :

- lecture du projet courant via `ProjectWorkspace` ;
- résolution honnête du chemin du catalogue en honorant :
  - `project.json -> pokemon.dataRoot`
  - `project.json -> pokemon.catalogFiles['moves']`
  - `pokemon_data_manifest.json` si présent ;
- lecture du catalogue local via le repository Pokémon existant ;
- projection triée par `name` case-insensitive puis `id` ;
- diagnostics non bloquants pour :
  - entrées invalides ;
  - ids dupliqués.

Politique de déduplication retenue :

- première entrée conservée ;
- doublons suivants ignorés avec diagnostic.

### Provider

J’ai ajouté un seam dédié et overrideable pour l’UI :

- `pokemonMovesCatalogWorkspaceLoaderProvider`

Ce choix permet :

- à l’UI réelle de lire le projet courant ;
- aux widget tests de rester déterministes sans dépendre du filesystem.

### UI

Le placeholder `Moves` a été remplacé par un vrai workspace :

- header `Moves`
- sous-texte `Catalogue local des capacités du projet.`
- recherche
- liste
- détail
- diagnostics
- états vides / erreur honnêtes
- responsive desktop/compact

## 7. Comportement utilisateur obtenu

Dans `Catalogues Pokémon > Moves`, l’utilisateur voit maintenant :

- un vrai écran `Moves` ;
- une recherche locale par nom / id / type / catégorie ;
- une liste des moves du projet courant ;
- un panneau détail pour le move sélectionné ;
- un état `Ouvre un projet...` si aucun projet n’est chargé ;
- un état `Aucun move local...` si le catalogue est absent ;
- un état `Le catalogue existe mais il ne contient aucune entrée` si le fichier est présent mais vide ;
- un état `Le catalogue contient uniquement des entrées invalides` si tout est rejeté ;
- un résumé diagnostics si certains fichiers/entrées sont ignorés mais que des moves valides restent visibles.

Le premier move filtré est sélectionné automatiquement. Si la recherche retire la sélection courante, l’UI bascule proprement sur le premier résultat restant.

## 8. Tests ajoutés et ce qu’ils prouvent

### Loader

`packages/map_editor/test/pokemon_moves_catalog_loader_test.dart`

Ce fichier prouve :

- chargement d’un catalogue local valide ;
- état `missingCatalog` si le fichier n’existe pas ;
- conservation des moves valides quand une autre entrée est invalide ;
- robustesse face à des champs mal typés ;
- tri stable ;
- déduplication avec diagnostic ;
- support des champs numériques nullable ;
- état `loadError` si le JSON du catalogue est cassé ;
- résolution honnête du chemin configuré via `pokemon.dataRoot` + `pokemon_data_manifest.json`.

### UI Moves

`packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart`

Ce fichier prouve :

- état `noProject` ;
- état vide si aucun move local n’existe ;
- liste + sélection initiale du premier move ;
- recherche par nom / id / type / catégorie ;
- affichage des diagnostics sans cacher les moves valides ;
- état spécifique quand toutes les entrées sont invalides ;
- rendu des valeurs manquantes en `—`.

### Régression shell / catalogues

- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

Ces tests prouvent qu’on n’a pas cassé :

- le parent `Catalogues Pokémon` ;
- le vrai `Pokédex` ;
- les smokes du shell editor ;
- le pipeline existant de sync/projection moves ;
- la séparation UX `Pokédex / Moves / Items`.

## 9. Validations exécutées avec résultats

Commandes réellement exécutées :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
rm -rf macos/Flutter/ephemeral/Packages/.packages && flutter analyze --no-pub \
  lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart \
  lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart \
  lib/src/ui/canvas/pokemon_catalogs_workspace.dart \
  lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  test/pokemon_moves_catalog_loader_test.dart \
  test/pokemon_moves_catalog_workspace_ui_test.dart \
  test/pokemon_catalogs_workspace_ui_test.dart \
  test/pokemon_catalogs_project_explorer_entry_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/sync_pokemon_moves_catalog_use_case_test.dart
```

Résultat :

- `No issues found!`

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
rm -rf macos/Flutter/ephemeral/Packages/.packages && flutter test \
  test/pokemon_moves_catalog_loader_test.dart \
  test/pokemon_moves_catalog_workspace_ui_test.dart \
  test/pokemon_catalogs_workspace_ui_test.dart \
  test/pokemon_catalogs_project_explorer_entry_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/top_toolbar_test.dart \
  test/pokedex_workspace_ui_test.dart \
  test/sync_pokemon_moves_catalog_use_case_test.dart
```

Résultat :

- `All tests passed!`

Note honnête :

- j’ai dû nettoyer `macos/Flutter/ephemeral/Packages/.packages` avant les runs Flutter à cause d’un problème local de symlink/ephemeral déjà observé dans cet environnement ;
- c’est un souci de tooling local, pas un changement du lot 8c.

## 10. Limites assumées

- `Moves` reste un catalogue local en lecture seule.
- Il n’y a pas encore d’édition/création/suppression via UI.
- Il n’y a pas encore de filtres avancés par type/catégorie.
- Il n’y a pas d’import/sync PokeAPI dans ce lot.
- `Items` reste un shell séparé.
- Le catalogue ne dépend pas de `map_battle` et ne tente pas de “valider battle” un move.

## 11. Ce qui est explicitement reporté au lot 8d

- import PokeAPI des moves ;
- mapping externe plus large ;
- écriture/sync des données locales depuis une source distante ;
- enrichissement massif du catalogue ;
- éventuels workflows batch d’import.

## 12. Retour de review séparée

La review séparée a remonté trois findings réels :

1. le parse “tolérant” pouvait encore casser sur des champs legacy mal typés ;
2. un catalogue 100% invalide était affiché comme “vide” ;
3. le chemin affiché dans les états `missing/empty` ne suivait pas complètement la résolution réelle du projet.

Corrections appliquées :

- sécurisation de la lecture `id` / `name` / `names` avec diagnostics au lieu d’un crash global ;
- nouvel état UI explicite si toutes les entrées sont rejetées ;
- résolution du chemin alignée avec `pokemon.dataRoot` et `pokemon_data_manifest.json`.

Décision :

- tous les findings ont été corrigés avant clôture.

## 13. État git final exact

```bash
$ git status --short --untracked-files=all
 M packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart
?? packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart
?? packages/map_editor/test/pokemon_moves_catalog_loader_test.dart
?? packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart
?? reports/lot-8c-moves-catalog-foundation-report.md
```

```bash
$ git diff --stat
 .../sync_pokemon_moves_catalog_use_case.dart       | 387 +++++++++++++++++++--
 .../src/ui/canvas/pokemon_catalogs_workspace.dart  |  37 +-
 .../lib/src/ui/panels/project_explorer_panel.dart  |   2 +-
 .../test/editor_shell_page_smoke_test.dart         |  21 +-
 .../test/pokemon_catalogs_workspace_ui_test.dart   |  69 +++-
 .../sync_pokemon_moves_catalog_use_case_test.dart  |  32 +-
 6 files changed, 460 insertions(+), 88 deletions(-)
```

```bash
$ git ls-files --others --exclude-standard
packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart
packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart
packages/map_editor/test/pokemon_moves_catalog_loader_test.dart
packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart
reports/lot-8c-moves-catalog-foundation-report.md
```

## 14. Décision finale nette

`Lot 8c réussi : le workspace Catalogues Pokémon > Moves dispose maintenant d’une vraie fondation locale, avec modèle, loader, recherche, liste, détail et diagnostics, sans PokeAPI live et sans toucher au battle/runtime.`

## 15. Note critique sur le prompt

La contrainte la plus discutable du prompt était la recommandation forte d’un stockage par fichiers `data/pokemon/moves/<id>.json`. Dans ce repo, le catalogue moves local existe déjà réellement sous `data/pokemon/catalogs/moves.json`, avec lecture/écriture/tests associés. J’ai donc interprété cette partie comme “suivre la convention existante si elle est déjà canonique”, ce qui évite d’ouvrir un deuxième système de stockage concurrent.

## 16. Annexe — Contenu complet des fichiers modifiés/créés

### `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:path/path.dart' as p;

import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';
import '../services/showdown_move_catalog_converter.dart';

/// Projection légère d'une entrée du catalogue local des attaques.
///
/// Cette vue existe pour deux besoins strictement 11B :
/// - afficher une liste locale lisible dans l'éditeur ;
/// - éviter que l'UI reparte du JSON brut pour interpréter les champs.
///
/// Non-objectifs assumés :
/// - ce n'est pas un nouveau modèle métier transverse ;
/// - ce n'est pas une "Move Library" complète ;
/// - on ne cherche pas à capturer toutes les subtilités battle de Showdown.
class PokemonMoveCatalogEntryView {
  const PokemonMoveCatalogEntryView({
    required this.id,
    required this.name,
    this.type,
    this.category,
    this.power,
    this.accuracy,
    this.accuracyText,
    this.pp,
    this.priority,
    this.target,
    this.shortDesc,
    this.shortEffectText,
    this.effectText,
    this.generation,
    this.generationId,
  });

  final String id;
  final String name;
  final String? type;
  final String? category;
  final int? power;
  final num? accuracy;
  final String? accuracyText;
  final int? pp;
  final int? priority;
  final String? target;
  final String? shortDesc;
  final String? shortEffectText;
  final String? effectText;
  final int? generation;
  final String? generationId;

  String get accuracyLabel {
    if (accuracy != null) {
      return accuracy!.toString();
    }
    if (accuracyText != null && accuracyText!.trim().isNotEmpty) {
      return accuracyText!;
    }
    return '-';
  }
}

enum PokemonMovesCatalogLoadState {
  ready,
  missingCatalog,
  loadError,
  noProject,
}

class PokemonMovesCatalogDiagnostic {
  const PokemonMovesCatalogDiagnostic({
    required this.message,
    this.entryId,
    this.entryIndex,
  });

  final String message;
  final String? entryId;
  final int? entryIndex;
}

/// État lisible du catalogue moves local pour l'éditeur.
///
/// L'UI a besoin d'une réponse honnête sur deux choses distinctes :
/// - le catalogue existe-t-il et a-t-il pu être lu ;
/// - quelles entrées locales sont effectivement disponibles.
///
/// On sépare donc clairement le message de statut des entrées elles-mêmes.
class PokemonMovesCatalogView {
  const PokemonMovesCatalogView({
    required this.entries,
    required this.isAvailable,
    required this.description,
    this.message,
    this.loadState = PokemonMovesCatalogLoadState.ready,
    this.catalogRelativePath = 'data/pokemon/catalogs/moves.json',
    this.diagnostics = const <PokemonMovesCatalogDiagnostic>[],
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
  final PokemonMovesCatalogLoadState loadState;
  final String catalogRelativePath;
  final List<PokemonMovesCatalogDiagnostic> diagnostics;

  int get ignoredEntriesCount => diagnostics.length;
}

/// Résultat d'une preview ou d'une synchronisation réelle du catalogue moves.
///
/// Le use case reste volontairement déterministe :
/// - aucune merge policy "UI-configurable" supplémentaire n'est introduite ;
/// - la stratégie retenue est un merge par id, avec préservation des entrées
///   locales absentes de la source distante et des champs locaux non gérés ;
/// - le résultat expose donc uniquement les compteurs et ids utiles à l'UI.
class PokemonMovesCatalogSyncResult {
  const PokemonMovesCatalogSyncResult({
    required this.dryRun,
    required this.externalEntryCount,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.resultingEntryCount,
    this.warnings = const <String>[],
  });

  final bool dryRun;
  final int externalEntryCount;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final int resultingEntryCount;
  final List<String> warnings;

  int get createdCount => createdIds.length;
  int get updatedCount => updatedIds.length;
  int get unchangedCount => unchangedIds.length;
  int get preservedLocalOnlyCount => preservedLocalOnlyIds.length;
}

/// Charge le catalogue local des attaques pour la surface éditeur minimale.
///
/// Ce use case reste volontairement simple :
/// - il lit exclusivement `catalogs/moves.json` via le repository existant ;
/// - il projette des entrées lisibles ;
/// - il ne tente aucune réparation automatique ni enrichissement externe.
class LoadPokemonMovesCatalogUseCase {
  const LoadPokemonMovesCatalogUseCase({
    required this.readRepository,
  });

  final PokemonReadRepository readRepository;

  Future<PokemonMovesCatalogView> execute(ProjectWorkspace workspace) async {
    final catalogRelativePath = await _resolveCatalogRelativePath(workspace);
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      final projectedCatalog = _projectEntries(catalog);
      return PokemonMovesCatalogView(
        entries: projectedCatalog.entries,
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des attaques.'
            : catalog.meta.description.trim(),
        loadState: PokemonMovesCatalogLoadState.ready,
        catalogRelativePath: catalogRelativePath,
        diagnostics: projectedCatalog.diagnostics,
      );
    } on EditorNotFoundException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message: error.message,
        loadState: PokemonMovesCatalogLoadState.missingCatalog,
        catalogRelativePath: catalogRelativePath,
      );
    } on EditorApplicationException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques illisible.',
        message: error.message,
        loadState: PokemonMovesCatalogLoadState.loadError,
        catalogRelativePath: catalogRelativePath,
      );
    }
  }

  Future<String> _resolveCatalogRelativePath(ProjectWorkspace workspace) async {
    final pokemonConfig = await _readProjectPokemonConfig(workspace);
    final dataRoot = _normalizeConfiguredRelativePath(
      pokemonConfig.dataRoot,
      fallback: 'data/pokemon',
    );

    try {
      final manifestPath = workspace.resolveProjectRelativePath(
        p.normalize(p.join(dataRoot, 'pokemon_data_manifest.json')),
      );
      if (await workspace.fileExists(manifestPath)) {
        final manifestRaw = await workspace.readTextFile(manifestPath);
        final manifest = PokemonDataManifest.fromJson(
          (jsonDecode(manifestRaw) as Map).cast<String, dynamic>(),
        );
        final declaredPath = manifest.catalogFiles['moves']?.trim();
        if (declaredPath != null && declaredPath.isNotEmpty) {
          return _resolvePathWithinPokemonDataRoot(
            pokemonConfig: pokemonConfig,
            rawRelativePath: declaredPath,
          );
        }
      }
    } on Object {
      final configuredPath = pokemonConfig.catalogFiles['moves']?.trim();
      if (configuredPath != null && configuredPath.isNotEmpty) {
        return p.normalize(configuredPath);
      }
      return 'data/pokemon/catalogs/moves.json';
    }

    final configuredPath = pokemonConfig.catalogFiles['moves']?.trim();
    if (configuredPath != null && configuredPath.isNotEmpty) {
      return p.normalize(configuredPath);
    }

    return 'data/pokemon/catalogs/moves.json';
  }

  _ProjectedMovesCatalog _projectEntries(PokemonCatalogFile catalog) {
    final diagnostics = <PokemonMovesCatalogDiagnostic>[];
    final entriesById = <String, PokemonMoveCatalogEntryView>{};

    for (var index = 0; index < catalog.entries.length; index++) {
      final entry = catalog.entries[index];
      try {
        final projectedEntry = _projectEntry(entry);
        if (entriesById.containsKey(projectedEntry.id)) {
          diagnostics.add(
            PokemonMovesCatalogDiagnostic(
              message:
                  'Moves catalog duplicate entry ignored for id "${projectedEntry.id}".',
              entryId: projectedEntry.id,
              entryIndex: index,
            ),
          );
          continue;
        }
        entriesById[projectedEntry.id] = projectedEntry;
      } on EditorApplicationException catch (error) {
        diagnostics.add(
          PokemonMovesCatalogDiagnostic(
            message: error.message,
            entryId: _diagnosticEntryId(entry),
            entryIndex: index,
          ),
        );
      }
    }

    final entries = entriesById.values.toList(growable: false)
      ..sort((left, right) {
        final nameCompare =
            left.name.toLowerCase().compareTo(right.name.toLowerCase());
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });

    return _ProjectedMovesCatalog(
      entries: entries,
      diagnostics: diagnostics,
    );
  }

  PokemonMoveCatalogEntryView _projectEntry(Map<String, dynamic> entry) {
    // M3 introduit des entrées canoniques `PokemonMove.toJson()`, mais le
    // catalogue projet peut encore contenir des entrées legacy locales non
    // resynchronisées.
    //
    // M3-bis durcit volontairement la frontière :
    // - la détection canonique devient large ;
    // - la détection legacy devient étroite ;
    // - si une entrée "sent" le canonique, on la traite comme canonique ;
    // - si le parse canonique échoue, on remonte une erreur explicite ;
    // - le fallback legacy ne sert plus qu'aux vraies formes legacy.
    //
    // Cette asymétrie est voulue :
    // - mieux vaut échouer tôt sur une entrée canonique cassée ;
    // - que la dégrader silencieusement vers la vieille projection legacy.
    if (_looksLikeCanonicalMoveEntry(entry)) {
      try {
        final move = PokemonMove.fromJson(entry);
        final shortEffectText =
            move.shortDescription.trim().isEmpty ? null : move.shortDescription;
        final effectText =
            move.description.trim().isEmpty ? null : move.description;
        return PokemonMoveCatalogEntryView(
          id: move.id,
          name: move.name,
          type: move.type,
          category: move.category.name,
          power: move.usesStandardDamageFlow ? move.basePower : null,
          accuracy: move.accuracy.map(
            percent: (value) => value.value,
            alwaysHits: (_) => null,
          ),
          accuracyText: move.accuracy.maybeMap(
            alwaysHits: (_) => 'always',
            orElse: () => null,
          ),
          pp: move.pp,
          priority: move.priority,
          target: _encodeTarget(move.target),
          shortDesc: shortEffectText,
          shortEffectText: shortEffectText,
          effectText: effectText,
          generation: move.generation,
          generationId: _generationIdFromNumber(move.generation),
        );
      } on Object catch (error) {
        throw EditorPersistenceException(
          'Moves catalog contains an invalid canonical PokemonMove entry: $error',
        );
      }
    }

    if (!_looksLikeLegacyMoveEntry(entry)) {
      throw const EditorPersistenceException(
        'Moves catalog contains an entry with an unknown or unsupported move shape.',
      );
    }

    final id = _readOptionalString(entry, 'id') ?? '';
    if (id.isEmpty) {
      throw const EditorPersistenceException(
        'Moves catalog contains an entry with an empty id.',
      );
    }

    final explicitName = _readOptionalString(entry, 'name');
    final localizedNames = _readOptionalStringMap(entry, 'names');
    final fallbackName = localizedNames?['en']?.trim();
    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;
    if (name == null || name.isEmpty) {
      throw EditorPersistenceException(
        'Moves catalog entry "$id" has an empty name.',
      );
    }

    final type = _readOptionalString(entry, 'typeId') ??
        _readOptionalString(entry, 'type');
    final category = _normalizeDamageClass(
      _readOptionalString(entry, 'damageClass') ??
          _readOptionalString(entry, 'category'),
    );
    final shortEffectText = _readOptionalString(entry, 'shortEffectText') ??
        _readOptionalString(entry, 'shortDesc');
    final effectText = _readOptionalString(entry, 'effectText') ??
        _readOptionalString(entry, 'description');
    final generationId = _readOptionalString(entry, 'generationId');

    return PokemonMoveCatalogEntryView(
      id: id,
      name: name,
      type: type,
      category: category,
      power: _readOptionalInt(entry, 'power', id: id),
      accuracy: _readOptionalNum(entry, 'accuracy', id: id),
      accuracyText: _readOptionalString(entry, 'accuracyText'),
      pp: _readOptionalInt(entry, 'pp', id: id),
      priority: _readOptionalInt(entry, 'priority', id: id),
      target: _readOptionalString(entry, 'target'),
      shortDesc: shortEffectText,
      shortEffectText: shortEffectText,
      effectText: effectText,
      generation: _readOptionalInt(entry, 'generation', id: id),
      generationId: generationId,
    );
  }
}

/// Synchronise le catalogue local `moves.json` depuis la source externe retenue.
///
/// Choix produit et technique de la 11B :
/// - on réutilise le port externe 11A existant, étendu minimalement ;
/// - la source bulk retenue est Showdown `moves.json` ;
/// - l'écriture locale continue de passer par le repository Pokémon existant ;
/// - `project.json` n'est jamais touché ;
/// - aucun pipeline parallèle n'est créé.
class SyncExternalPokemonMovesCatalogUseCase {
  const SyncExternalPokemonMovesCatalogUseCase({
    required this.externalSourceRepository,
    required this.readRepository,
    required this.writeRepository,
    this.converter = const ShowdownMoveCatalogConverter(),
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;
  final ShowdownMoveCatalogConverter converter;

  Future<PokemonMovesCatalogSyncResult> execute(
    ProjectWorkspace workspace, {
    bool dryRun = false,
  }) async {
    final externalCatalog = converter.convert(
      await externalSourceRepository.fetchShowdownMovesSnapshot(),
    );
    final localCatalog = await _readLocalCatalogIfAvailable(workspace);
    final merge = _mergeCatalogs(
      localCatalog: localCatalog,
      externalCatalog: externalCatalog,
    );

    if (!dryRun) {
      await writeRepository.saveCatalogByKey(workspace, 'moves', merge.catalog);
    }

    return PokemonMovesCatalogSyncResult(
      dryRun: dryRun,
      externalEntryCount: externalCatalog.entries.length,
      createdIds: merge.createdIds,
      updatedIds: merge.updatedIds,
      unchangedIds: merge.unchangedIds,
      preservedLocalOnlyIds: merge.preservedLocalOnlyIds,
      resultingEntryCount: merge.catalog.entries.length,
      warnings: merge.warnings,
    );
  }

  Future<PokemonCatalogFile?> _readLocalCatalogIfAvailable(
    ProjectWorkspace workspace,
  ) async {
    try {
      return await readRepository.readCatalogByKey(workspace, 'moves');
    } on EditorNotFoundException {
      // Le storage 11A/11B initialise normalement le fichier, mais on garde ce
      // fallback local pour éviter qu'une absence de catalogue ne bloque
      // complètement un premier sync sur un workspace partiellement initialisé.
      return null;
    }
  }

  _MovesCatalogMerge _mergeCatalogs({
    required PokemonCatalogFile? localCatalog,
    required PokemonCatalogFile externalCatalog,
  }) {
    final localById = <String, Map<String, dynamic>>{
      for (final entry
          in localCatalog?.entries ?? const <Map<String, dynamic>>[])
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');
    final externalById = <String, Map<String, dynamic>>{
      for (final entry in externalCatalog.entries)
        ((entry['id'] as String?)?.trim() ?? ''): _deepCopy(entry),
    }..remove('');

    final createdIds = <String>[];
    final updatedIds = <String>[];
    final unchangedIds = <String>[];
    final mergedEntries = <Map<String, dynamic>>[];

    for (final externalEntry in externalById.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key))) {
      final id = externalEntry.key;
      final localEntry = localById.remove(id);
      if (localEntry == null) {
        createdIds.add(id);
        mergedEntries.add(_deepCopy(externalEntry.value));
        continue;
      }

      final mergedEntry = _mergeEntry(
        localEntry: localEntry,
        externalEntry: externalEntry.value,
      );
      if (_jsonDeepEquals(localEntry, mergedEntry)) {
        unchangedIds.add(id);
      } else {
        updatedIds.add(id);
      }
      mergedEntries.add(mergedEntry);
    }

    final preservedLocalOnlyIds = localById.keys.toList(growable: false)
      ..sort();
    for (final id in preservedLocalOnlyIds) {
      mergedEntries.add(_deepCopy(localById[id]!));
    }

    mergedEntries.sort(
      (left, right) => ((left['id'] as String?) ?? '').compareTo(
        (right['id'] as String?) ?? '',
      ),
    );

    final catalog = PokemonCatalogFile(
      schemaVersion: externalCatalog.schemaVersion,
      kind: externalCatalog.kind,
      catalog: externalCatalog.catalog,
      meta: _buildMergedMeta(
        localMeta: localCatalog?.meta,
        externalMeta: externalCatalog.meta,
      ),
      entries: mergedEntries,
    );

    return _MovesCatalogMerge(
      catalog: catalog,
      createdIds: createdIds,
      updatedIds: updatedIds,
      unchangedIds: unchangedIds,
      preservedLocalOnlyIds: preservedLocalOnlyIds,
      warnings: preservedLocalOnlyIds.isEmpty
          ? const <String>[]
          : <String>[
              'Local move entries absent from the external snapshot were preserved unchanged.',
            ],
    );
  }

  PokemonDataMeta _buildMergedMeta({
    required PokemonDataMeta? localMeta,
    required PokemonDataMeta externalMeta,
  }) {
    final notes = <String>[
      ...externalMeta.notes,
      if (localMeta != null)
        ...localMeta.notes.where(
          (note) => !externalMeta.notes.contains(note),
        ),
    ];

    return PokemonDataMeta(
      description: externalMeta.description,
      sourcePriority: externalMeta.sourcePriority,
      notes: notes,
    );
  }

  Map<String, dynamic> _mergeEntry({
    required Map<String, dynamic> localEntry,
    required Map<String, dynamic> externalEntry,
  }) {
    final merged = <String, dynamic>{};

    for (final externalField in externalEntry.entries) {
      final key = externalField.key;
      final externalValue = externalField.value;
      final localValue = localEntry[key];

      if (key == 'names' &&
          localValue is Map &&
          externalValue is Map<String, dynamic>) {
        merged[key] = _mergeNames(localValue, externalValue);
        continue;
      }

      // Règle de merge locale et volontairement conservative :
      // - l'externe garde la priorité sur les champs qu'on sait produire ;
      // - si la valeur externe vaut `null`, on conserve une valeur locale
      //   existante plutôt que d'effacer une information déjà utile ;
      // - les champs purement locaux non gérés par 11B sont préservés plus bas.
      merged[key] = externalValue ?? _deepCopyValue(localValue);
    }

    for (final localField in localEntry.entries) {
      if (_looksLikeCanonicalMoveEntry(externalEntry) &&
          _obsoleteLegacyMoveFields.contains(localField.key)) {
        // M3 ne doit pas laisser les anciens alias légers (`power`,
        // `accuracyText`, `shortDesc`) se réinjecter sur une entrée maintenant
        // canonique. On continue toutefois de préserver les vrais champs
        // locaux additionnels (`names.fr`, `editorNote`, etc.).
        continue;
      }
      merged.putIfAbsent(
          localField.key, () => _deepCopyValue(localField.value));
    }

    return merged;
  }

  Map<String, dynamic> _mergeNames(
    Map localValue,
    Map<String, dynamic> externalValue,
  ) {
    final merged = <String, dynamic>{
      for (final entry in localValue.entries)
        if (entry.key is String)
          entry.key as String: _deepCopyValue(entry.value),
    };
    for (final entry in externalValue.entries) {
      merged[entry.key] = _deepCopyValue(entry.value);
    }
    return merged;
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return (jsonDecode(jsonEncode(source)) as Map).cast<String, dynamic>();
  }

  Object? _deepCopyValue(Object? value) {
    if (value == null) {
      return null;
    }
    return jsonDecode(jsonEncode(value));
  }

  bool _jsonDeepEquals(Object? left, Object? right) {
    if (left is Map && right is Map) {
      if (left.length != right.length) {
        return false;
      }
      for (final key in left.keys) {
        if (!right.containsKey(key)) {
          return false;
        }
        if (!_jsonDeepEquals(left[key], right[key])) {
          return false;
        }
      }
      return true;
    }
    if (left is List && right is List) {
      if (left.length != right.length) {
        return false;
      }
      for (var index = 0; index < left.length; index++) {
        if (!_jsonDeepEquals(left[index], right[index])) {
          return false;
        }
      }
      return true;
    }
    return left == right;
  }
}

String _encodeTarget(PokemonMoveTarget target) {
  switch (target) {
    case PokemonMoveTarget.adjacentAlly:
      return 'adjacentAlly';
    case PokemonMoveTarget.adjacentAllyOrSelf:
      return 'adjacentAllyOrSelf';
    case PokemonMoveTarget.adjacentFoe:
      return 'adjacentFoe';
    case PokemonMoveTarget.all:
      return 'all';
    case PokemonMoveTarget.allAdjacent:
      return 'allAdjacent';
    case PokemonMoveTarget.allAdjacentFoes:
      return 'allAdjacentFoes';
    case PokemonMoveTarget.allies:
      return 'allies';
    case PokemonMoveTarget.allySide:
      return 'allySide';
    case PokemonMoveTarget.allyTeam:
      return 'allyTeam';
    case PokemonMoveTarget.any:
      return 'any';
    case PokemonMoveTarget.foeSide:
      return 'foeSide';
    case PokemonMoveTarget.normal:
      return 'normal';
    case PokemonMoveTarget.randomNormal:
      return 'randomNormal';
    case PokemonMoveTarget.scripted:
      return 'scripted';
    case PokemonMoveTarget.self:
      return 'self';
  }
}

bool _looksLikeCanonicalMoveEntry(Map<String, dynamic> entry) {
  // Détection volontairement large :
  // - toute présence d'un vrai marqueur canonique doit suffire ;
  // - une entrée partiellement migrée ou partiellement cassée doit être
  //   traitée comme une candidate canonique, puis échouer explicitement ;
  // - on évite ainsi tout downgrade silencieux vers le fallback legacy.
  return entry.containsKey('basePower') ||
      entry.containsKey('effects') ||
      entry.containsKey('sourceRefs') ||
      entry.containsKey('engineSupportLevel') ||
      entry.containsKey('unsupportedReasons') ||
      entry.containsKey('noPpBoosts') ||
      entry.containsKey('critRatio') ||
      entry['accuracy'] is Map;
}

bool _looksLikeLegacyMoveEntry(Map<String, dynamic> entry) {
  // Détection volontairement étroite :
  // - on ne classe legacy que les formes explicitement héritées de l'ancien
  //   catalogue léger ;
  // - la présence d'un signal canonique exclut immédiatement le chemin legacy ;
  // - `accuracy` scalaire seule n'est acceptée en legacy que s'il n'existe
  //   aucun signal canonique concurrent.
  if (_looksLikeCanonicalMoveEntry(entry)) {
    return false;
  }

  return entry.containsKey('id') ||
      entry.containsKey('name') ||
      entry.containsKey('typeId') ||
      entry.containsKey('damageClass') ||
      entry.containsKey('generationId') ||
      entry.containsKey('effectText') ||
      entry.containsKey('shortEffectText') ||
      entry.containsKey('power') ||
      entry.containsKey('accuracyText') ||
      entry.containsKey('shortDesc') ||
      entry['accuracy'] is num;
}

const Set<String> _obsoleteLegacyMoveFields = <String>{
  'power',
  'accuracyText',
  'shortDesc',
};

class _MovesCatalogMerge {
  const _MovesCatalogMerge({
    required this.catalog,
    required this.createdIds,
    required this.updatedIds,
    required this.unchangedIds,
    required this.preservedLocalOnlyIds,
    required this.warnings,
  });

  final PokemonCatalogFile catalog;
  final List<String> createdIds;
  final List<String> updatedIds;
  final List<String> unchangedIds;
  final List<String> preservedLocalOnlyIds;
  final List<String> warnings;
}

class _ProjectedMovesCatalog {
  const _ProjectedMovesCatalog({
    required this.entries,
    required this.diagnostics,
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final List<PokemonMovesCatalogDiagnostic> diagnostics;
}

String? _diagnosticEntryId(Map<String, dynamic> entry) {
  final value = entry['id'];
  if (value is! String) {
    return null;
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String? _readOptionalString(Map<String, dynamic> entry, String key) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! String) {
    throw EditorPersistenceException(
      'Moves catalog field "$key" must be a string when present.',
    );
  }
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

Map<String, String>? _readOptionalStringMap(
  Map<String, dynamic> entry,
  String key,
) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! Map) {
    throw EditorPersistenceException(
      'Moves catalog field "$key" must be a string map when present.',
    );
  }

  final result = <String, String>{};
  for (final mapEntry in value.entries) {
    final mapKey = mapEntry.key;
    final mapValue = mapEntry.value;
    if (mapKey is! String || mapValue is! String) {
      throw EditorPersistenceException(
        'Moves catalog field "$key" must be a string map when present.',
      );
    }
    result[mapKey] = mapValue;
  }
  return result;
}

int? _readOptionalInt(
  Map<String, dynamic> entry,
  String key, {
  required String id,
}) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw EditorPersistenceException(
      'Moves catalog entry "$id" has an invalid "$key" value.',
    );
  }
  return value.toInt();
}

num? _readOptionalNum(
  Map<String, dynamic> entry,
  String key, {
  required String id,
}) {
  final value = entry[key];
  if (value == null) {
    return null;
  }
  if (value is! num) {
    throw EditorPersistenceException(
      'Moves catalog entry "$id" has an invalid "$key" value.',
    );
  }
  return value;
}

String? _normalizeDamageClass(String? value) {
  if (value == null) {
    return null;
  }
  final normalized = value.trim().toLowerCase();
  if (normalized.isEmpty) {
    return null;
  }
  if (normalized == 'physical' ||
      normalized == 'special' ||
      normalized == 'status') {
    return normalized;
  }
  return 'unknown';
}

String? _generationIdFromNumber(int? generation) {
  return switch (generation) {
    1 => 'generation-i',
    2 => 'generation-ii',
    3 => 'generation-iii',
    4 => 'generation-iv',
    5 => 'generation-v',
    6 => 'generation-vi',
    7 => 'generation-vii',
    8 => 'generation-viii',
    9 => 'generation-ix',
    _ => null,
  };
}

Future<ProjectPokemonConfig> _readProjectPokemonConfig(
  ProjectWorkspace workspace,
) async {
  final manifestPath = workspace.projectManifestPath;
  try {
    if (!await workspace.fileExists(manifestPath)) {
      return const ProjectPokemonConfig();
    }

    final raw = await workspace.readTextFile(manifestPath);
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw EditorPersistenceException(
        'Project manifest is not a JSON object: $manifestPath',
      );
    }
    final project = ProjectManifest.fromJson(decoded);
    return project.pokemon;
  } on EditorPersistenceException {
    rethrow;
  } on FormatException catch (error) {
    throw EditorPersistenceException(
      'Invalid JSON in project manifest at $manifestPath: $error',
    );
  } catch (error) {
    throw EditorPersistenceException(
      'Invalid project manifest at $manifestPath: $error',
    );
  }
}

String _normalizeConfiguredRelativePath(
  String rawRelativePath, {
  required String fallback,
}) {
  final trimmed = rawRelativePath.trim();
  return p.normalize(trimmed.isEmpty ? fallback : trimmed);
}

String _resolvePathWithinPokemonDataRoot({
  required ProjectPokemonConfig pokemonConfig,
  required String rawRelativePath,
}) {
  final normalizedPath = p.normalize(rawRelativePath.trim());
  final dataRoot = _normalizeConfiguredRelativePath(
    pokemonConfig.dataRoot,
    fallback: 'data/pokemon',
  );
  if (normalizedPath == dataRoot || normalizedPath.startsWith('$dataRoot/')) {
    return normalizedPath;
  }
  return p.normalize(p.join(dataRoot, normalizedPath));
}
```

### `packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/repository_providers.dart';
import '../pokedex/pokedex_providers.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';

typedef PokemonMovesCatalogWorkspaceLoader =
    Future<PokemonMovesCatalogView> Function(String? projectRootPath);

final pokemonMovesCatalogWorkspaceLoaderProvider =
    Provider<PokemonMovesCatalogWorkspaceLoader>((ref) {
  return (projectRootPath) async {
    if (projectRootPath == null || projectRootPath.trim().isEmpty) {
      return const PokemonMovesCatalogView(
        entries: <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        loadState: PokemonMovesCatalogLoadState.noProject,
      );
    }

    final workspace = ref.read(projectWorkspaceFactoryProvider).create(
          projectRootPath,
        );
    final useCase = ref.read(loadPokemonMovesCatalogUseCaseProvider);
    return useCase.execute(workspace);
  };
});
```

### `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'pokedex_workspace.dart';
import 'pokemon_catalogs_workspace/moves_catalog_workspace.dart';

class PokemonCatalogsWorkspace extends ConsumerWidget {
  const PokemonCatalogsWorkspace({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(editorPokemonCatalogSectionProvider);

    return switch (section) {
      PokemonCatalogSection.pokedex => const Padding(
          padding: EdgeInsets.fromLTRB(4, 4, 4, 0),
          child: PokedexWorkspace(),
        ),
      PokemonCatalogSection.moves => const PokemonMovesCatalogWorkspace(),
      PokemonCatalogSection.items => const Padding(
          padding: EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: _PokemonCatalogShellSection(
            title: 'Items',
            subtitle: 'Le futur catalogue des objets du projet vivra ici.',
            description:
                'Ce shell pose une structure de workspace propre pour les items, séparée du sac battle et des écrans trainer. Le lot actuel prépare la navigation et l’intention produit sans prétendre que le contenu métier existe déjà.',
            readiness:
                'Structure de workspace prête pour un futur catalogue d’objets guidé et éditable.',
          ),
        ),
    };
  }
}

class _PokemonCatalogShellSection extends StatelessWidget {
  const _PokemonCatalogShellSection({
    required this.title,
    required this.subtitle,
    required this.description,
    required this.readiness,
  });

  final String title;
  final String subtitle;
  final String description;
  final String readiness;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemBackground.resolveFrom(context);
    final mutedFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
        decoration: BoxDecoration(
          color: panelFill,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: TextStyle(
                color: subtle,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: mutedFill,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    style: const TextStyle(
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    readiness,
                    style: TextStyle(
                      color: subtle,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

### `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../features/editor/state/editor_selectors.dart';

class PokemonMovesCatalogWorkspace extends ConsumerStatefulWidget {
  const PokemonMovesCatalogWorkspace({super.key});

  @override
  ConsumerState<PokemonMovesCatalogWorkspace> createState() =>
      _PokemonMovesCatalogWorkspaceState();
}

class _PokemonMovesCatalogWorkspaceState
    extends ConsumerState<PokemonMovesCatalogWorkspace> {
  late final TextEditingController _searchController;
  String? _selectedMoveId;
  String? _loadedProjectRootPath;
  Future<PokemonMovesCatalogView>? _catalogFuture;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()
      ..addListener(() {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final projectRootPath = ref.watch(editorProjectRootPathProvider);
    final catalogFuture = _catalogFutureFor(projectRootPath);

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      child: _MovesWorkspaceScaffold(
        child: FutureBuilder<PokemonMovesCatalogView>(
          future: catalogFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(
                child: Text('Chargement du catalogue local des moves…'),
              );
            }
            if (snapshot.hasError) {
              return _MovesWorkspaceNotice(
                title: 'Catalogue illisible',
                message: snapshot.error.toString(),
              );
            }
            return _buildCatalogContent(
              context,
              snapshot.data ??
                  const PokemonMovesCatalogView(
                    entries: <PokemonMoveCatalogEntryView>[],
                    isAvailable: false,
                    description: 'Catalogue local des attaques indisponible.',
                    loadState: PokemonMovesCatalogLoadState.loadError,
                  ),
            );
          },
        ),
      ),
    );
  }

  Future<PokemonMovesCatalogView> _loadCatalog(String? projectRootPath) async {
    final loader = ref.read(pokemonMovesCatalogWorkspaceLoaderProvider);
    return loader(projectRootPath);
  }

  Future<PokemonMovesCatalogView> _catalogFutureFor(String? projectRootPath) {
    if (_catalogFuture == null || _loadedProjectRootPath != projectRootPath) {
      _loadedProjectRootPath = projectRootPath;
      _catalogFuture = _loadCatalog(projectRootPath);
    }
    return _catalogFuture!;
  }

  Widget _buildCatalogContent(
    BuildContext context,
    PokemonMovesCatalogView view,
  ) {
    final query = _searchController.text.trim();
    final filteredEntries = _filterEntries(view.entries, query);
    final selectedEntry = _resolveSelectedEntry(filteredEntries);

    if (view.loadState == PokemonMovesCatalogLoadState.noProject) {
      return const _MovesWorkspaceNotice(
        title: 'Moves',
        message: 'Ouvre un projet pour afficher le catalogue des moves.',
      );
    }

    if (view.loadState == PokemonMovesCatalogLoadState.missingCatalog) {
      return _MovesWorkspaceNotice(
        title: 'Moves',
        message:
            'Aucun move local pour le moment.\nAjoute des entrées dans ${view.catalogRelativePath}. L’import PokeAPI sera traité dans un lot suivant.',
      );
    }

    if (view.loadState == PokemonMovesCatalogLoadState.loadError) {
      return _MovesWorkspaceNotice(
        title: 'Moves',
        message: view.message ?? 'Le catalogue local des moves est illisible.',
      );
    }

    if (view.entries.isEmpty) {
      if (view.diagnostics.isNotEmpty) {
        return _MovesWorkspaceNotice(
          title: 'Moves',
          message:
              'Le catalogue local des moves contient uniquement des entrées invalides.\n${_diagnosticsSummary(view.diagnostics.length)}\nChemin lu : ${view.catalogRelativePath}',
        );
      }
      return _MovesWorkspaceNotice(
        title: 'Moves',
        message:
            'Le catalogue local des moves existe, mais il ne contient aucune entrée.\nChemin lu : ${view.catalogRelativePath}',
      );
    }

    final isCompact = MediaQuery.sizeOf(context).width < 1040;

    final listPanel = _MovesCatalogListPanel(
      searchController: _searchController,
      entries: filteredEntries,
      selectedEntryId: selectedEntry?.id,
      diagnostics: view.diagnostics,
      onEntrySelected: (entry) {
        setState(() {
          _selectedMoveId = entry.id;
        });
      },
    );

    final detailPanel = _MovesCatalogDetailPanel(
      entry: selectedEntry,
      hasSearchQuery: query.isNotEmpty,
    );

    if (isCompact) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: listPanel,
          ),
          const SizedBox(height: 16),
          Expanded(
            flex: 4,
            child: detailPanel,
          ),
        ],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 5,
          child: listPanel,
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: detailPanel,
        ),
      ],
    );
  }

  List<PokemonMoveCatalogEntryView> _filterEntries(
    List<PokemonMoveCatalogEntryView> entries,
    String query,
  ) {
    if (query.isEmpty) {
      return entries;
    }
    final normalizedQuery = query.toLowerCase();
    return entries.where((entry) {
      return entry.name.toLowerCase().contains(normalizedQuery) ||
          entry.id.toLowerCase().contains(normalizedQuery) ||
          (entry.type?.toLowerCase().contains(normalizedQuery) ?? false) ||
          (entry.category?.toLowerCase().contains(normalizedQuery) ?? false);
    }).toList(growable: false);
  }

  PokemonMoveCatalogEntryView? _resolveSelectedEntry(
    List<PokemonMoveCatalogEntryView> entries,
  ) {
    for (final entry in entries) {
      if (entry.id == _selectedMoveId) {
        return entry;
      }
    }
    if (entries.isEmpty) {
      return null;
    }
    return entries.first;
  }
}

class _MovesWorkspaceScaffold extends StatelessWidget {
  const _MovesWorkspaceScaffold({
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemBackground.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 22),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Moves',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Catalogue local des capacités du projet.',
            style: TextStyle(
              color: subtle,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          Expanded(child: child),
        ],
      ),
    );
  }
}

class _MovesWorkspaceNotice extends StatelessWidget {
  const _MovesWorkspaceNotice({
    required this.title,
    required this.message,
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(
              color: subtle,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovesCatalogListPanel extends StatelessWidget {
  const _MovesCatalogListPanel({
    required this.searchController,
    required this.entries,
    required this.selectedEntryId,
    required this.diagnostics,
    required this.onEntrySelected,
  });

  final TextEditingController searchController;
  final List<PokemonMoveCatalogEntryView> entries;
  final String? selectedEntryId;
  final List<PokemonMovesCatalogDiagnostic> diagnostics;
  final ValueChanged<PokemonMoveCatalogEntryView> onEntrySelected;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CupertinoSearchTextField(
            key: const Key('moves-catalog-search-field'),
            controller: searchController,
            placeholder: 'Recherche par nom, id, type ou catégorie',
          ),
          if (diagnostics.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              diagnostics.length == 1
                  ? '1 entrée ignorée dans le catalogue.'
                  : '${diagnostics.length} entrées ignorées dans le catalogue.',
              key: const Key('moves-catalog-diagnostics-summary'),
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Expanded(
            child: entries.isEmpty
                ? Center(
                    child: Text(
                      'Aucun move ne correspond à cette recherche.',
                      style: TextStyle(
                        color: subtle,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                : ListView.separated(
                    key: const Key('moves-catalog-list'),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return _MovesCatalogListTile(
                        entry: entry,
                        selected: entry.id == selectedEntryId,
                        onTap: () => onEntrySelected(entry),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MovesCatalogListTile extends StatelessWidget {
  const _MovesCatalogListTile({
    required this.entry,
    required this.selected,
    required this.onTap,
  });

  final PokemonMoveCatalogEntryView entry;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    final selectedFill = CupertinoColors.systemBlue.withValues(alpha: 0.12);
    final background = selected
        ? selectedFill
        : CupertinoColors.systemBackground.resolveFrom(context);

    return GestureDetector(
      key: Key('moves-catalog-entry-${entry.id}'),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry.name,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${entry.id} · ${_labelOrDash(entry.type)} · ${_labelOrDash(entry.category)}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Power ${_intOrDash(entry.power)} · Accuracy ${entry.accuracyLabel} · PP ${_intOrDash(entry.pp)}',
              style: TextStyle(
                color: subtle,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesCatalogDetailPanel extends StatelessWidget {
  const _MovesCatalogDetailPanel({
    required this.entry,
    required this.hasSearchQuery,
  });

  final PokemonMoveCatalogEntryView? entry;
  final bool hasSearchQuery;

  @override
  Widget build(BuildContext context) {
    final border = CupertinoColors.separator.resolveFrom(context);
    final panelFill = CupertinoColors.systemGrey6.resolveFrom(context);
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);

    if (entry == null) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: panelFill,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border),
        ),
        child: Text(
          hasSearchQuery
              ? 'Aucun move ne correspond à cette recherche.'
              : 'Sélectionne un move pour afficher ses détails.',
          style: TextStyle(
            color: subtle,
            height: 1.45,
          ),
        ),
      );
    }

    return Container(
      key: Key('moves-catalog-detail-${entry!.id}'),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: panelFill,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: border),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              entry!.name,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              entry!.id,
              style: TextStyle(
                color: subtle,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            _MovesCatalogDetailRow(label: 'Type', value: _labelOrDash(entry!.type)),
            _MovesCatalogDetailRow(
              label: 'Damage class',
              value: _labelOrDash(entry!.category),
            ),
            _MovesCatalogDetailRow(label: 'Power', value: _intOrDash(entry!.power)),
            _MovesCatalogDetailRow(
              label: 'Accuracy',
              value: entry!.accuracyLabel == '-' ? '—' : entry!.accuracyLabel,
            ),
            _MovesCatalogDetailRow(label: 'PP', value: _intOrDash(entry!.pp)),
            _MovesCatalogDetailRow(
              label: 'Priority',
              value: _intOrDash(entry!.priority),
            ),
            _MovesCatalogDetailRow(
              label: 'Target',
              value: _labelOrDash(entry!.target),
            ),
            _MovesCatalogDetailRow(
              label: 'Generation',
              value: _generationLabel(entry!),
            ),
            _MovesCatalogDetailRow(
              label: 'Short effect',
              value: _labelOrDash(entry!.shortEffectText ?? entry!.shortDesc),
            ),
            _MovesCatalogDetailRow(
              label: 'Effect text',
              value: _labelOrDash(entry!.effectText),
            ),
          ],
        ),
      ),
    );
  }
}

class _MovesCatalogDetailRow extends StatelessWidget {
  const _MovesCatalogDetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final subtle = CupertinoColors.secondaryLabel.resolveFrom(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: subtle,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

String _labelOrDash(String? value) {
  final trimmed = value?.trim();
  return trimmed == null || trimmed.isEmpty ? '—' : trimmed;
}

String _intOrDash(int? value) {
  return value == null ? '—' : value.toString();
}

String _generationLabel(PokemonMoveCatalogEntryView entry) {
  if (entry.generationId != null && entry.generationId!.trim().isNotEmpty) {
    return entry.generationId!;
  }
  if (entry.generation != null) {
    return 'Gen ${entry.generation}';
  }
  return '—';
}

String _diagnosticsSummary(int count) {
  return count == 1
      ? '1 entrée ignorée dans le catalogue.'
      : '$count entrées ignorées dans le catalogue.';
}
```

### `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';

import '../../features/editor/state/editor_notifier.dart';
import '../../features/editor/state/editor_selectors.dart';
import '../../features/editor/state/editor_state.dart';
import 'project_explorer/dialogs/import_tileset_dialog.dart';
import 'project_explorer/dialogs/tileset_library_dialogs.dart';
import 'project_explorer/dialogs/world_group_dialogs.dart';
import 'project_explorer/widgets/sidebar_header_action.dart';
import 'project_explorer/widgets/tree/tileset_tree_nodes.dart';
import 'project_explorer/widgets/tree/world_tree_nodes.dart';
import 'character_library_panel.dart';
import 'narrative_library_panel.dart';
import 'terrain_editor_panel.dart';
import 'trainer_library_panel.dart';
import '../shared/cupertino_editor_widgets.dart';
import '../shared/inspector_section_card.dart';

class ProjectExplorerPanel extends ConsumerStatefulWidget {
  const ProjectExplorerPanel({super.key});

  @override
  ConsumerState<ProjectExplorerPanel> createState() =>
      _ProjectExplorerPanelState();
}

class _ProjectExplorerPanelState extends ConsumerState<ProjectExplorerPanel> {
  bool _expandTileLib = true;
  bool _expandPokedex = true;
  bool _expandNarrative = true;
  bool _expandWorld = true;
  bool _expandTerrains = true;
  bool _expandPaths = true;
  bool _expandTrainers = false;
  bool _expandCharacters = false;

  @override
  Widget build(BuildContext context) {
    final snapshot = ref.watch(editorProjectExplorerSnapshotProvider);
    final notifier = ref.read(editorNotifierProvider.notifier);
    final project = snapshot.project;

    return SizedBox(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: project == null
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: 2),
                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Text(
                              'Open a project to browse your world, maps and tilesets.',
                              style: TextStyle(
                                color: CupertinoColors.placeholderText
                                    .resolveFrom(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: 10),
                        _buildTree(context, project, snapshot, notifier),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final label = EditorChrome.primaryLabel(context);
    const explorerAccent = EditorChrome.inspectorJoyCyan;
    const explorerDeep = EditorChrome.inspectorJoyPlum;
    return Padding(
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
                  Color.lerp(CupertinoColors.white, explorerAccent, 0.78)!,
                  Color.lerp(explorerDeep, const Color(0xFF140818), 0.35)!,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: explorerAccent.withValues(alpha: 0.88),
                width: 1.15,
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              CupertinoIcons.square_stack_3d_up,
              size: 18,
              color: CupertinoColors.white,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'World Explorer',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: label,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: -0.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Cartes, tilesets, surfaces — dialogues dans Dialogue Studio',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: subtle,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTree(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final rootMaps = project.maps.where((m) => m.groupId == null).toList();
    final rootGroups =
        project.groups.where((g) => g.parentGroupId == null).toList();

    final worldChildren = <Widget>[
      ...rootGroups.map(
        (g) => GroupNode(
          group: g,
          project: project,
          snapshot: snapshot,
          notifier: notifier,
          depth: 0,
        ),
      ),
      if (rootMaps.isNotEmpty) ...[
        const EditorSidebarSectionTitle('UNGROUPED MAPS', leftInset: 6),
        ...rootMaps.map(
          (m) => MapNode(
            map: m,
            snapshot: snapshot,
            notifier: notifier,
            depth: 0,
          ),
        ),
      ],
      if (rootGroups.isEmpty && rootMaps.isEmpty)
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 6, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'World is empty',
                style: TextStyle(
                  color: CupertinoColors.placeholderText.resolveFrom(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              PushButton(
                controlSize: ControlSize.regular,
                onPressed: () => showCreateGroupDialog(context, notifier),
                child: const Text('Add City or Route'),
              ),
            ],
          ),
        ),
    ];

    final screenH = MediaQuery.sizeOf(context).height;
    final hTileset = (screenH * 0.30).clamp(240.0, 400.0);
    final hPokedex = (screenH * 0.22).clamp(180.0, 260.0);
    final hNarrative = (screenH * 0.34).clamp(260.0, 460.0);
    final hWorld = (screenH * 0.30).clamp(240.0, 400.0);
    final hTerrains = (screenH * 0.36).clamp(280.0, 500.0);
    final hPaths = (screenH * 0.36).clamp(280.0, 500.0);
    final hTrainers = (screenH * 0.18).clamp(180.0, 240.0);
    final hCharacters = (screenH * 0.35).clamp(260.0, 480.0);
    const explorerTileRadius = 28.0;
    final actionIcon = CupertinoColors.white.withValues(alpha: 0.92);
    final actionHover = CupertinoColors.white.withValues(alpha: 0.16);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Tileset Library',
          subtitle: 'Folders, imports, and map painting',
          icon: CupertinoIcons.square_grid_2x2,
          accentColor: EditorChrome.inspectorJoyBlue,
          badgeText: '${project.tilesets.length}',
          expanded: _expandTileLib,
          onToggle: () => setState(() => _expandTileLib = !_expandTileLib),
          expandedHeight: hTileset,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.photo_on_rectangle,
                tooltip: 'Import tileset',
                onPressed: () =>
                    showImportTilesetDialog(context, snapshot, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
              const SizedBox(width: 6),
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.plus_circle_fill,
                tooltip: 'New folder',
                onPressed: () => promptNewTilesetLibraryFolder(
                  context,
                  notifier,
                ),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildTilesetsIsland(context, project, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Catalogues Pokémon',
          subtitle: 'Pokédex, Moves et Items dans un espace guidé unique',
          icon: CupertinoIcons.book_fill,
          accentColor: EditorChrome.inspectorJoyAmber,
          expanded: _expandPokedex,
          onToggle: () => setState(() => _expandPokedex = !_expandPokedex),
          expandedHeight: hPokedex,
          child: _buildPokemonCatalogsCard(context, snapshot, notifier),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Narrative Studio',
          subtitle:
              'Global Story, Steps, Cutscenes and outcomes (opens central workspaces)',
          icon: CupertinoIcons.link_circle_fill,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.scenarios.length}',
          expanded: _expandNarrative,
          onToggle: () => setState(() => _expandNarrative = !_expandNarrative),
          expandedHeight: hNarrative,
          child: const NarrativeLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'World Maps',
          subtitle:
              'Maps jouables et contenu monde (events, entités, warps, triggers)',
          icon: CupertinoIcons.map_fill,
          accentColor: EditorChrome.inspectorJoyPlum,
          badgeText: '${project.maps.length}',
          expanded: _expandWorld,
          onToggle: () => setState(() => _expandWorld = !_expandWorld),
          expandedHeight: hWorld,
          headerTrailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SidebarHeaderAction(
                enabled: true,
                icon: CupertinoIcons.folder_badge_plus,
                tooltip: 'New root group',
                onPressed: () => showCreateGroupDialog(context, notifier),
                iconColor: actionIcon,
                hoverFill: actionHover,
              ),
            ],
          ),
          child: _buildWorldIslandBody(context, worldChildren),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Terrain Library',
          subtitle: 'Base ground presets',
          icon: CupertinoIcons.map,
          accentColor: EditorChrome.accentJade,
          badgeText: '${project.terrainPresets.length}',
          expanded: _expandTerrains,
          onToggle: () => setState(() => _expandTerrains = !_expandTerrains),
          expandedHeight: hTerrains,
          child: const TerrainLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Path Library',
          subtitle: 'Surface overlays: roads, water, tall grass...',
          icon: CupertinoIcons.arrow_branch,
          accentColor: EditorChrome.accentWarm,
          badgeText: '${project.pathPresets.length}',
          expanded: _expandPaths,
          onToggle: () => setState(() => _expandPaths = !_expandPaths),
          expandedHeight: hPaths,
          child: const PathLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Trainer Studio',
          subtitle: 'Battle rosters and teams (opens the central workspace)',
          icon: CupertinoIcons.person_2_fill,
          accentColor: EditorChrome.accentCoral,
          badgeText: '${project.trainers.length}',
          expanded: _expandTrainers,
          onToggle: () => setState(() => _expandTrainers = !_expandTrainers),
          expandedHeight: hTrainers,
          child: const TrainerLibraryPanel(embedded: true),
        ),
        InspectorSectionCard(
          borderRadius: explorerTileRadius,
          title: 'Character Library',
          subtitle: 'Overworld sprites for the player and NPCs',
          icon: CupertinoIcons.person_crop_circle,
          accentColor: EditorChrome.inspectorJoyCyan,
          badgeText: '${project.characters.length}',
          expanded: _expandCharacters,
          onToggle: () =>
              setState(() => _expandCharacters = !_expandCharacters),
          expandedHeight: hCharacters,
          child: const CharacterLibraryPanel(embedded: true),
        ),
      ],
    );
  }

  Widget _buildTilesetsIsland(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: _buildTilesetsSection(context, project, snapshot, notifier),
    );
  }

  Widget _buildPokemonCatalogsCard(
    BuildContext context,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final isCatalogsWorkspace =
        snapshot.workspaceMode == EditorWorkspaceMode.pokedex;

    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-pokedex'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.pokedex,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.pokedex,
            ),
            leading: const MacosIcon(CupertinoIcons.book),
            title: const Text('Pokédex'),
            subtitle: const Text(
              'Recherche, import, détail et édition locale des espèces',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-moves'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.moves,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.moves,
            ),
            leading: const MacosIcon(CupertinoIcons.sparkles),
            title: const Text('Moves'),
            subtitle: const Text(
              'Catalogue local des capacités du projet',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          EditorSidebarListRow(
            key: const Key('pokemon-catalog-entry-items'),
            selected: isCatalogsWorkspace &&
                snapshot.pokemonCatalogSection == PokemonCatalogSection.items,
            onTap: () => notifier.selectPokemonCatalogSection(
              PokemonCatalogSection.items,
            ),
            leading: const MacosIcon(CupertinoIcons.cube_box),
            title: const Text('Items'),
            subtitle: const Text(
              'Shell du futur catalogue des objets',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorldIslandBody(
    BuildContext context,
    List<Widget> worldChildren,
  ) {
    return SingleChildScrollView(
      primary: false,
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: worldChildren,
      ),
    );
  }

  Widget _buildTilesetsSection(
    BuildContext context,
    ProjectManifest project,
    EditorProjectExplorerSnapshot snapshot,
    EditorNotifier notifier,
  ) {
    final selectedTilesetId = snapshot.selectedTilesetEntry?.id;
    final tree = buildTilesetLibraryTree(project);

    String scopeLabel(ProjectTilesetEntry t) {
      if (t.scope == TilesetScope.global) return 'Global';
      final gid = t.groupId;
      if (gid == null) return 'Group';
      for (final g in project.groups) {
        if (g.id == gid) return g.name;
      }
      return 'Group';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TilesetLibraryRootDropStrip(project: project, notifier: notifier),
        if (project.tilesets.isEmpty && project.tilesetFolders.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 6, 14, 12),
            child: Text(
              'No tilesets yet. Import an image or create folders to organize your library.',
              style: TextStyle(
                color: CupertinoColors.placeholderText.resolveFrom(context),
                fontSize: 12,
              ),
            ),
          ),
        ...tree.rootFolders.map(
          (branch) => TilesetLibraryFolderNode(
            branch: branch,
            depth: 0,
            project: project,
            notifier: notifier,
            selectedTilesetId: selectedTilesetId,
            scopeLabel: scopeLabel,
          ),
        ),
        ...tree.rootTilesets.map(
          (tileset) => TilesetNode(
            tileset: tileset,
            project: project,
            notifier: notifier,
            selected: selectedTilesetId == tileset.id,
            leftIndent: 14,
            scopeLabel: scopeLabel(tileset),
          ),
        ),
      ],
    );
  }
}
```

### `packages/map_editor/test/pokemon_moves_catalog_loader_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:path/path.dart' as p;

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp('moves_catalog_8c_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    loadUseCase = const LoadPokemonMovesCatalogUseCase(
      readRepository: FilePokemonReadRepository(),
    );

    await CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    ).execute('Moves Catalog Test Project', tempProjectRoot.path);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test('loads local moves from the project moves catalog', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'water-gun',
          'name': 'Water Gun',
          'typeId': 'water',
          'damageClass': 'special',
          'power': 40,
          'accuracy': 100,
          'pp': 25,
          'priority': 0,
          'target': 'selected-pokemon',
          'generationId': 'generation-i',
          'effectText': 'Inflicts regular damage.',
          'shortEffectText': 'Inflicts regular damage.',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final move = result.entries.single;
    expect(move.id, 'water-gun');
    expect(move.name, 'Water Gun');
    expect(move.type, 'water');
    expect(move.category, 'special');
    expect(move.power, 40);
    expect(move.accuracy, 100);
    expect(move.pp, 25);
    expect(move.priority, 0);
    expect(move.target, 'selected-pokemon');
    expect(move.generationId, 'generation-i');
    expect(move.effectText, 'Inflicts regular damage.');
    expect(move.shortEffectText, 'Inflicts regular damage.');
    expect(result.diagnostics, isEmpty);
  });

  test('returns an empty result when the moves catalog is missing', () async {
    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.missingCatalog);
    expect(result.entries, isEmpty);
    expect(result.diagnostics, isEmpty);
    expect(result.catalogRelativePath, 'data/pokemon/catalogs/moves.json');
  });

  test('keeps valid moves when another catalog entry is invalid', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'water-gun',
          'name': 'Water Gun',
          'typeId': 'water',
          'damageClass': 'special',
          'power': 40,
          'accuracy': 100,
          'pp': 25,
        },
        <String, Object?>{
          'id': 'broken-move',
          'name': '',
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries.map((entry) => entry.id), <String>['water-gun']);
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.message, contains('broken-move'));
  });

  test('keeps valid moves when another catalog entry is badly typed', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'water-gun',
          'name': 'Water Gun',
        },
        <String, Object?>{
          'id': 42,
          'name': <String, Object?>{'en': 'Broken Move'},
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries.map((entry) => entry.id), <String>['water-gun']);
    expect(result.diagnostics, hasLength(1));
    expect(
      result.diagnostics.single.message,
      contains('field "id" must be a string'),
    );
  });

  test('sorts moves by display name then id case-insensitively', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{'id': 'zeta-move', 'name': 'Zeta Move'},
        <String, Object?>{'id': 'alpha-late', 'name': 'Alpha Move'},
        <String, Object?>{'id': 'alpha-early', 'name': 'alpha move'},
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(
      result.entries.map((entry) => entry.id).toList(),
      <String>['alpha-early', 'alpha-late', 'zeta-move'],
    );
  });

  test('deduplicates duplicate move ids with a diagnostic', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{'id': 'water-gun', 'name': 'Water Gun'},
        <String, Object?>{'id': 'water-gun', 'name': 'Water Gun Copy'},
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.entries, hasLength(1));
    expect(result.entries.single.name, 'Water Gun');
    expect(result.diagnostics, hasLength(1));
    expect(result.diagnostics.single.message, contains('water-gun'));
  });

  test('parses nullable move numeric fields without crashing', () async {
    await _writeMovesCatalog(
      tempProjectRoot,
      entries: <Map<String, Object?>>[
        <String, Object?>{
          'id': 'growl',
          'name': 'Growl',
          'damageClass': 'status',
          'power': null,
          'accuracy': null,
          'pp': null,
        },
      ],
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.ready);
    expect(result.entries, hasLength(1));
    final move = result.entries.single;
    expect(move.power, isNull);
    expect(move.accuracy, isNull);
    expect(move.pp, isNull);
    expect(result.diagnostics, isEmpty);
  });

  test('returns a load error when moves catalog json is invalid', () async {
    final file = File(
      p.join(tempProjectRoot.path, 'data', 'pokemon', 'catalogs', 'moves.json'),
    );
    await file.create(recursive: true);
    await file.writeAsString('{ invalid json');

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.loadError);
    expect(result.entries, isEmpty);
    expect(result.message, isNotEmpty);
  });

  test('resolves the configured moves catalog path from pokemon data root',
      () async {
    final manifestFile = File(workspace.projectManifestPath);
    final manifest = ProjectManifest.fromJson(
      jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>,
    );
    await manifestFile.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        manifest
            .copyWith(
              pokemon: manifest.pokemon.copyWith(
                dataRoot: 'custom/pokemon',
              ),
            )
            .toJson(),
      ),
    );

    final bootstrapManifest = File(
      p.join(
        tempProjectRoot.path,
        'custom',
        'pokemon',
        'pokemon_data_manifest.json',
      ),
    );
    await bootstrapManifest.create(recursive: true);
    await bootstrapManifest.writeAsString(
      const JsonEncoder.withIndent('  ').convert(
        <String, Object?>{
          'schemaVersion': 1,
          'kind': 'pokemon_data_manifest',
          'meta': <String, Object?>{
            'description': 'Custom bootstrap manifest.',
          },
          'catalogFiles': <String, Object?>{
            'moves': 'catalogs/project-moves.json',
          },
          'futureDataFolders': <String, Object?>{},
        },
      ),
    );

    final result = await loadUseCase.execute(workspace);

    expect(result.loadState, PokemonMovesCatalogLoadState.missingCatalog);
    expect(
      result.catalogRelativePath,
      'custom/pokemon/catalogs/project-moves.json',
    );
  });
}

Future<void> _writeMovesCatalog(
  Directory projectRoot, {
  required List<Map<String, Object?>> entries,
}) async {
  final file = File(
    p.join(projectRoot.path, 'data', 'pokemon', 'catalogs', 'moves.json'),
  );
  await file.create(recursive: true);
  await file.writeAsString(
    const JsonEncoder.withIndent('  ').convert(
      <String, Object?>{
        'schemaVersion': 1,
        'kind': 'pokemon_catalog',
        'catalog': 'moves',
        'meta': <String, Object?>{
          'description': 'Local moves catalog.',
        },
        'entries': entries,
      },
    ),
  );
}
```

### `packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';

void main() {
  const project = ProjectManifest(
    name: 'Moves Catalog UI Project',
    maps: <ProjectMapEntry>[],
    tilesets: <ProjectTilesetEntry>[],
  );

  testWidgets('Moves catalog shows a no project state without crashing',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
    );

    expect(
      find.text('Ouvre un projet pour afficher le catalogue des moves.'),
      findsOneWidget,
    );
  });

  testWidgets('Moves catalog shows empty state when project has no local moves',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[],
            isAvailable: false,
            description: 'Catalogue local des attaques indisponible.',
            loadState: PokemonMovesCatalogLoadState.missingCatalog,
          ),
        ),
      ],
    );

    expect(find.text('Moves'), findsWidgets);
    expect(
      find.textContaining('Aucun move local pour le moment.'),
      findsOneWidget,
    );
    expect(
      find.textContaining('data/pokemon/catalogs/moves.json'),
      findsOneWidget,
    );
  });

  testWidgets('Moves catalog lists local moves and selects the first move',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[
              PokemonMoveCatalogEntryView(
                id: 'water-gun',
                name: 'Water Gun',
                type: 'water',
                category: 'special',
                power: 40,
                accuracy: 100,
                pp: 25,
                shortEffectText: 'Inflicts regular damage.',
                shortDesc: 'Inflicts regular damage.',
              ),
              PokemonMoveCatalogEntryView(
                id: 'thunder-shock',
                name: 'Thunder Shock',
                type: 'electric',
                category: 'special',
                power: 40,
                accuracy: 100,
                pp: 30,
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('moves-catalog-list')), findsOneWidget);
    expect(find.text('Water Gun'), findsWidgets);
    expect(find.text('Thunder Shock'), findsWidgets);
    expect(find.byKey(const Key('moves-catalog-detail-water-gun')), findsOneWidget);
    expect(find.text('Inflicts regular damage.'), findsOneWidget);
  });

  testWidgets('Moves catalog search filters by name id type and damage class',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[
              PokemonMoveCatalogEntryView(
                id: 'water-gun',
                name: 'Water Gun',
                type: 'water',
                category: 'special',
              ),
              PokemonMoveCatalogEntryView(
                id: 'thunder-shock',
                name: 'Thunder Shock',
                type: 'electric',
                category: 'special',
              ),
              PokemonMoveCatalogEntryView(
                id: 'growl',
                name: 'Growl',
                category: 'status',
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    await tester.enterText(
      find.byKey(const Key('moves-catalog-search-field')),
      'water',
    );
    await tester.pumpAndSettle();
    expect(find.text('Water Gun'), findsWidgets);
    expect(find.text('Thunder Shock'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('moves-catalog-search-field')),
      'status',
    );
    await tester.pumpAndSettle();
    expect(find.text('Growl'), findsWidgets);
    expect(find.text('Water Gun'), findsNothing);

    await tester.enterText(
      find.byKey(const Key('moves-catalog-search-field')),
      'thunder',
    );
    await tester.pumpAndSettle();
    expect(find.text('Thunder Shock'), findsWidgets);
    expect(find.text('Growl'), findsNothing);
  });

  testWidgets('Moves catalog keeps valid moves visible when diagnostics exist',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[
              PokemonMoveCatalogEntryView(
                id: 'water-gun',
                name: 'Water Gun',
                type: 'water',
                category: 'special',
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
            diagnostics: <PokemonMovesCatalogDiagnostic>[
              PokemonMovesCatalogDiagnostic(
                message: 'Moves catalog entry "broken-move" has an empty name.',
                entryId: 'broken-move',
                entryIndex: 1,
              ),
            ],
          ),
        ),
      ],
    );

    expect(find.text('Water Gun'), findsWidgets);
    expect(find.textContaining('1 entrée ignorée'), findsOneWidget);
  });

  testWidgets('Moves catalog shows an invalid-catalog state when every entry is ignored',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
            diagnostics: <PokemonMovesCatalogDiagnostic>[
              PokemonMovesCatalogDiagnostic(
                message: 'Moves catalog entry "broken-move" has an empty name.',
                entryId: 'broken-move',
                entryIndex: 0,
              ),
            ],
          ),
        ),
      ],
    );

    expect(
      find.textContaining(
        'Le catalogue local des moves contient uniquement des entrées invalides.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('1 entrée ignorée'), findsOneWidget);
  });

  testWidgets('Moves catalog detail formats missing values as dash',
      (tester) async {
    await _pumpMovesWorkspace(
      tester,
      initialState: const EditorState(
        projectRootPath: '/tmp/moves_catalog_ui_test',
        project: project,
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      ),
      overrides: [
        pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
          (_) async => const PokemonMovesCatalogView(
            entries: <PokemonMoveCatalogEntryView>[
              PokemonMoveCatalogEntryView(
                id: 'growl',
                name: 'Growl',
                category: 'status',
                power: null,
                accuracy: null,
                pp: null,
              ),
            ],
            isAvailable: true,
            description: 'Catalogue local des attaques.',
          ),
        ),
      ],
    );

    expect(find.byKey(const Key('moves-catalog-detail-growl')), findsOneWidget);
    expect(find.text('Power'), findsWidgets);
    expect(find.text('Accuracy'), findsWidgets);
    expect(find.text('PP'), findsWidgets);
    expect(find.text('—'), findsWidgets);
  });
}

Future<ProviderContainer> _pumpMovesWorkspace(
  WidgetTester tester, {
  required EditorState initialState,
  List<Override> overrides = const <Override>[],
}) async {
  final container = ProviderContainer(overrides: overrides);
  addTearDown(container.dispose);

  await tester.binding.setSurfaceSize(const Size(1440, 980));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosApp(
        home: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoPageScaffold(
            child: SizedBox.expand(
              child: PokemonCatalogsWorkspace(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
  return container;
}
```

### `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokemon_catalogs_workspace.dart';

Future<void> _pumpCatalogsWorkspace(
  WidgetTester tester, {
  required ProviderContainer container,
  required EditorState initialState,
}) async {
  await tester.binding.setSurfaceSize(const Size(1440, 980));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  container.read(editorNotifierProvider.notifier).state = initialState;

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MacosApp(
        home: MacosTheme(
          data: MacosThemeData.light(),
          child: const CupertinoPageScaffold(
            child: SizedBox.expand(
              child: PokemonCatalogsWorkspace(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pumpAndSettle(const Duration(milliseconds: 50));
}

Widget _buildCatalogsHost({
  required ProviderContainer container,
  required bool showWorkspace,
}) {
  return UncontrolledProviderScope(
    container: container,
    child: MacosApp(
      home: MacosTheme(
        data: MacosThemeData.light(),
        child: CupertinoPageScaffold(
          child: SizedBox.expand(
            child: showWorkspace
                ? const PokemonCatalogsWorkspace()
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('PokemonCatalogsWorkspace', () {
    testWidgets(
        'renders the real Pokédex workspace when the Pokédex section is active',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des capacités du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
        initialState: const EditorState(
          projectRootPath: '/tmp/pokemon_catalogs_workspace_test',
          project: ProjectManifest(
            name: 'Catalogs Test Project',
            maps: <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'lab',
                name: 'Lab',
                relativePath: 'maps/lab.json',
              ),
            ],
            tilesets: <ProjectTilesetEntry>[],
          ),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.pokedex,
        ),
      );

      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
    });

    testWidgets(
        'renders the Moves workspace when the Moves section is active',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                  power: 40,
                  accuracy: 100,
                  pp: 25,
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des capacités du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
        initialState: const EditorState(
          projectRootPath: '/tmp/pokemon_catalogs_moves_test',
          project: ProjectManifest(
            name: 'Catalogs Test Project',
            maps: <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'lab',
                name: 'Lab',
                relativePath: 'maps/lab.json',
              ),
            ],
            tilesets: <ProjectTilesetEntry>[],
          ),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.moves,
        ),
      );

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders the Items shell when the Items section is active',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des capacités du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      await _pumpCatalogsWorkspace(
        tester,
        container: container,
        initialState: const EditorState(
          projectRootPath: '/tmp/pokemon_catalogs_items_test',
          project: ProjectManifest(
            name: 'Catalogs Test Project',
            maps: <ProjectMapEntry>[
              ProjectMapEntry(
                id: 'lab',
                name: 'Lab',
                relativePath: 'maps/lab.json',
              ),
            ],
            tilesets: <ProjectTilesetEntry>[],
          ),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.items,
        ),
      );

      expect(find.text('Items'), findsWidgets);
      expect(
        find.text('Le futur catalogue des objets du projet vivra ici.'),
        findsOneWidget,
      );
      expect(find.textContaining('structure de workspace'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('keeps the selected section when the workspace remounts',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(editorNotifierProvider.notifier).state = const EditorState(
        projectRootPath: '/tmp/pokemon_catalogs_remount_test',
        project: ProjectManifest(
          name: 'Catalogs Test Project',
          maps: <ProjectMapEntry>[
            ProjectMapEntry(
              id: 'lab',
              name: 'Lab',
              relativePath: 'maps/lab.json',
            ),
          ],
          tilesets: <ProjectTilesetEntry>[],
        ),
        workspaceMode: EditorWorkspaceMode.pokedex,
        pokemonCatalogSection: PokemonCatalogSection.moves,
      );

      await tester.binding.setSurfaceSize(const Size(1440, 980));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          showWorkspace: false,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      await tester.pumpWidget(
        _buildCatalogsHost(
          container: container,
          showWorkspace: true,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle(const Duration(milliseconds: 50));

      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
    });
  });
}
```

### `packages/map_editor/test/editor_shell_page_smoke_test.dart`

```dart
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex/pokedex_providers.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';

import 'shell_chrome_test_harness.dart';

void main() {
  group('EditorShellPage smoke', () {
    testWidgets('renders map workspace chrome and toggles the right panel',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_smoke',
          project: buildShellChromeProject(),
        ),
      );

      expect(find.text('Map Workspace'), findsOneWidget);
      expect(
        find.text('Open a map to start building your world.'),
        findsOneWidget,
      );
      expect(find.text('Ready'), findsOneWidget);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Hide right panel',
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              widget.semanticLabel == 'Show right panel',
        ),
        findsOneWidget,
      );
    });

    testWidgets('updates the workspace header for tileset mode',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_tileset',
          project: buildShellChromeProject(
            tilesets: const <ProjectTilesetEntry>[
              ProjectTilesetEntry(
                id: 'indoor',
                name: 'Indoor',
                relativePath: 'tilesets/indoor.json',
              ),
            ],
          ),
          workspaceMode: EditorWorkspaceMode.tileset,
          selectedTilesetEditorId: 'indoor',
        ),
      );

      expect(find.text('Indoor'), findsAtLeastNWidgets(1));
      expect(
        find.text(
          'Visual library editing for tiles, elements and groups.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('renders the trainer studio workspace chrome', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_trainer',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.trainer,
        ),
      );

      expect(find.text('Trainer Studio'), findsWidgets);
      expect(
        find.textContaining('battle-ready rosters'),
        findsOneWidget,
      );
      expect(
        find.byKey(const Key('trainer-library-new-trainer-button')),
        findsOneWidget,
      );
    });

    testWidgets('renders the Pokémon catalogs workspace shell', (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_catalogs',
          project: buildShellChromeProject(),
          workspaceMode: EditorWorkspaceMode.pokedex,
          pokemonCatalogSection: PokemonCatalogSection.moves,
        ),
        overrides: [
          pokemonMovesCatalogWorkspaceLoaderProvider.overrideWithValue(
            (_) async => const PokemonMovesCatalogView(
              entries: <PokemonMoveCatalogEntryView>[
                PokemonMoveCatalogEntryView(
                  id: 'water-gun',
                  name: 'Water Gun',
                  type: 'water',
                  category: 'special',
                  power: 40,
                  accuracy: 100,
                  pp: 25,
                ),
              ],
              isAvailable: true,
              description: 'Catalogue local des capacités du projet.',
            ),
          ),
          pokedexEntryLoaderProvider.overrideWithValue(
            (_) async => const <PokemonDatabaseIndexEntry>[],
          ),
        ],
      );

      expect(find.text('Catalogues Pokémon'), findsWidgets);
      expect(find.byKey(const Key('pokemon-catalogs-tabs')), findsNothing);
      expect(find.text('Moves'), findsWidgets);
      expect(
        find.text('Catalogue local des capacités du projet.'),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is MacosIconButton &&
              (widget.semanticLabel == 'Hide right panel' ||
                  widget.semanticLabel == 'Show right panel'),
        ),
        findsNothing,
      );
    });

    testWidgets('renders shell chrome with an error state already present',
        (tester) async {
      await pumpEditorShellPage(
        tester,
        initialState: EditorState(
          projectRootPath: '/tmp/editor_shell_error',
          project: buildShellChromeProject(),
          errorMessage: 'Shell render failure',
        ),
      );

      expect(find.text('Shell render failure'), findsOneWidget);
    });
  });
}
```

### `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late _FakePokemonExternalSourceRepository externalRepository;
  late SyncExternalPokemonMovesCatalogUseCase syncUseCase;
  late LoadPokemonMovesCatalogUseCase loadUseCase;

  setUp(() async {
    tempProjectRoot =
        await Directory.systemTemp.createTemp('moves_catalog_sync_');
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    externalRepository = _FakePokemonExternalSourceRepository();
    syncUseCase = SyncExternalPokemonMovesCatalogUseCase(
      externalSourceRepository: externalRepository,
      readRepository: readRepository,
      writeRepository: writeRepository,
    );
    loadUseCase = LoadPokemonMovesCatalogUseCase(
      readRepository: readRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Moves Catalog Sync Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  Future<PokemonMovesCatalogView> loadViewFromCatalog(
    PokemonCatalogFile catalog,
  ) async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      catalog,
    );
    return loadUseCase.execute(workspace);
  }

  test('dry-run previews the sync without writing the local catalog', () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final catalogFile = File(
      workspace.resolveProjectRelativePath('data/pokemon/catalogs/moves.json'),
    );
    final beforeCatalogJson = await catalogFile.readAsString();
    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace, dryRun: true);

    expect(result.dryRun, isTrue);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(await catalogFile.readAsString(), beforeCatalogJson);
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'sync merges Showdown moves into the local catalog and preserves local-only metadata',
      () async {
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _localMovesCatalogBeforeSync,
    );

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    final result = await syncUseCase.execute(workspace);
    final syncedCatalog = await readRepository.readCatalogByKey(
      workspace,
      'moves',
    );
    final loadedView = await loadUseCase.execute(workspace);

    expect(result.dryRun, isFalse);
    expect(result.createdIds, containsAll(<String>['swift', 'thunderbolt']));
    expect(result.updatedIds, contains('vine_whip'));
    expect(result.preservedLocalOnlyIds, contains('custom_move'));
    expect(
      syncedCatalog.entries.map((entry) => entry['id']),
      containsAll(<String>['custom_move', 'swift', 'thunderbolt', 'vine_whip']),
    );

    final vineWhip = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'vine_whip',
    );
    final canonicalVineWhip = PokemonMove.fromJson(vineWhip);
    expect(canonicalVineWhip.name, 'Vine Whip');
    expect(canonicalVineWhip.type, 'grass');
    expect(canonicalVineWhip.basePower, 45);
    expect(canonicalVineWhip.generation, 1);
    expect(canonicalVineWhip.source, 'showdown');
    expect(vineWhip.containsKey('power'), isFalse);
    expect(vineWhip.containsKey('accuracyText'), isFalse);
    expect(vineWhip.containsKey('shortDesc'), isFalse);
    expect(
      ((vineWhip['names'] as Map<String, dynamic>)['fr'] as String),
      'Fouet Lianes',
    );
    expect(vineWhip['editorNote'], 'Keep this local-only field after sync.');

    final swift = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'swift',
    );
    final canonicalSwift = PokemonMove.fromJson(swift);
    expect(
      canonicalSwift.accuracy,
      const PokemonMoveAccuracy.alwaysHits(),
    );

    expect(loadedView.isAvailable, isTrue);
    final thunderboltView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'thunderbolt',
    );
    expect(thunderboltView.power, 90);
    expect(thunderboltView.accuracyLabel, '100');
    expect(thunderboltView.shortDesc, 'May paralyze the target.');

    final swiftView = loadedView.entries.firstWhere(
      (entry) => entry.id == 'swift',
    );
    expect(swiftView.accuracyLabel, 'always');
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'load use case does not silently downgrade an invalid canonical move to legacy projection',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_move',
            'name': 'Broken Move',
            'names': <String, String>{'en': 'Broken Move'},
            'source': 'showdown',
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': <String, dynamic>{'kind': 'percent', 'value': 0},
            'pp': 10,
            'priority': 0,
            'critRatio': 1,
            'flags': <String>[],
            'effects': <Map<String, dynamic>>[],
            'shortDescription': 'Broken canonical payload.',
            'description': 'Broken canonical payload.',
            'engineSupportLevel': 'structured_supported',
            'unsupportedReasons': <String>[],
            'sourceRefs': <String, dynamic>{
              'showdownMoveId': 'brokenmove',
              'showdownHooksPresent': <String>[],
            },
          },
        ],
        description: 'Broken canonical move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, isEmpty);
    expect(loadedView.diagnostics, hasLength(1));
    expect(
      loadedView.diagnostics.single.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test('load use case reads a valid canonical move entry correctly', () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          _canonicalMoveEntry(
            const PokemonMove(
              id: 'thunderbolt',
              name: 'Thunderbolt',
              names: <String, String>{'en': 'Thunderbolt'},
              generation: 1,
              source: 'showdown',
              type: 'electric',
              category: PokemonMoveCategory.special,
              target: PokemonMoveTarget.normal,
              basePower: 90,
              accuracy: PokemonMoveAccuracy.percent(value: 100),
              pp: 15,
              priority: 0,
              critRatio: 1,
              effects: <PokemonMoveEffect>[
                PokemonMoveEffect.applyStatus(
                  chance: 10,
                  statusId: 'par',
                ),
              ],
              shortDescription: 'May paralyze the target.',
              description:
                  'A strong electric blast crashes down on the target.',
              engineSupportLevel:
                  PokemonMoveEngineSupportLevel.structuredSupported,
              sourceRefs: PokemonMoveSourceRefs(
                showdownMoveId: 'thunderbolt',
              ),
            ),
          ),
        ],
        description: 'Valid canonical move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'thunderbolt');
    expect(loadedView.entries.single.power, 90);
    expect(loadedView.entries.single.accuracyLabel, '100');
    expect(loadedView.entries.single.shortDesc, 'May paralyze the target.');
  });

  test(
      'load use case treats basePower plus scalar accuracy as invalid canonical instead of legacy',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_base_power_move',
            'name': 'Broken Base Power Move',
            'names': <String, String>{'en': 'Broken Base Power Move'},
            'type': 'normal',
            'category': 'physical',
            'target': 'normal',
            'basePower': 40,
            'accuracy': 95,
            'pp': 15,
            'priority': 0,
          },
        ],
        description: 'Broken canonical candidate by basePower.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, isEmpty);
    expect(loadedView.diagnostics, hasLength(1));
    expect(
      loadedView.diagnostics.single.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test(
      'load use case treats other canonical markers as invalid canonical instead of legacy',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'broken_effects_move',
            'name': 'Broken Effects Move',
            'names': <String, String>{'en': 'Broken Effects Move'},
            'type': 'psychic',
            'category': 'status',
            'accuracy': <String, dynamic>{'kind': 'always_hits'},
            'effects': <Map<String, dynamic>>[
              <String, dynamic>{
                'kind': 'set_weather',
              },
            ],
          },
        ],
        description: 'Broken canonical candidate by effects.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, isEmpty);
    expect(loadedView.diagnostics, hasLength(1));
    expect(
      loadedView.diagnostics.single.message,
      contains('invalid canonical PokemonMove entry'),
    );
  });

  test('load use case still accepts a true legacy move entry', () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'legacy_move',
            'name': 'Legacy Move',
            'names': <String, String>{'en': 'Legacy Move'},
            'type': 'normal',
            'category': 'physical',
            'power': 50,
            'accuracy': 95,
            'pp': 20,
            'priority': 0,
            'target': 'normal',
            'shortDesc': 'A true legacy move entry.',
            'generation': 3,
          },
        ],
        description: 'Legacy move catalog.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'legacy_move');
    expect(loadedView.entries.single.power, 50);
    expect(loadedView.entries.single.accuracyLabel, '95');
    expect(loadedView.entries.single.shortDesc, 'A true legacy move entry.');
  });

  test('load use case accepts a minimal local move entry shape',
      () async {
    final loadedView = await loadViewFromCatalog(
      _catalogWithEntries(
        const <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 'unknown_shape_move',
            'name': 'Unknown Shape Move',
            'names': <String, String>{'en': 'Unknown Shape Move'},
            'type': 'normal',
            'category': 'status',
            'target': 'normal',
          },
        ],
        description: 'Unknown move catalog shape.',
      ),
    );

    expect(loadedView.isAvailable, isTrue);
    expect(loadedView.diagnostics, isEmpty);
    expect(loadedView.entries, hasLength(1));
    expect(loadedView.entries.single.id, 'unknown_shape_move');
    expect(loadedView.entries.single.name, 'Unknown Shape Move');
    expect(loadedView.entries.single.category, 'status');
  });
}

PokemonCatalogFile _catalogWithEntries(
  List<Map<String, dynamic>> entries, {
  required String description,
}) {
  return PokemonCatalogFile(
    schemaVersion: 1,
    kind: 'pokemon_catalog',
    catalog: 'moves',
    meta: PokemonDataMeta(
      description: description,
    ),
    entries: entries,
  );
}

Map<String, dynamic> _canonicalMoveEntry(PokemonMove move) => move.toJson();

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() async {
    return <String, dynamic>{
      'vinewhip': <String, dynamic>{
        'name': 'Vine Whip',
        'type': 'Grass',
        'category': 'Physical',
        'basePower': 45,
        'accuracy': 100,
        'pp': 25,
        'priority': 0,
        'target': 'normal',
        'shortDesc': 'Strikes the target with slender, whiplike vines.',
        'desc': 'The target is struck with slender, whiplike vines.',
        'gen': 1,
      },
      'thunderbolt': <String, dynamic>{
        'name': 'Thunderbolt',
        'type': 'Electric',
        'category': 'Special',
        'basePower': 90,
        'accuracy': 100,
        'pp': 15,
        'priority': 0,
        'target': 'normal',
        'secondary': <String, dynamic>{
          'chance': 10,
          'status': 'par',
        },
        'shortDesc': 'May paralyze the target.',
        'desc': 'A strong electric blast crashes down on the target.',
        'gen': 1,
      },
      'swift': <String, dynamic>{
        'name': 'Swift',
        'type': 'Normal',
        'category': 'Special',
        'basePower': 60,
        'accuracy': true,
        'pp': 20,
        'priority': 0,
        'target': 'allAdjacentFoes',
        'shortDesc': 'This move does not check accuracy.',
        'desc': 'Star-shaped rays are shot at opposing Pokémon.',
        'gen': 1,
      },
    };
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    throw UnimplementedError();
  }
}

const PokemonCatalogFile _localMovesCatalogBeforeSync = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Local moves catalog before external sync.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{
      'id': 'custom_move',
      'name': 'Custom Move',
      'names': <String, String>{'en': 'Custom Move'},
      'type': 'normal',
      'category': 'status',
      'power': null,
      'accuracy': 100,
      'pp': 5,
      'priority': 0,
      'target': 'self',
      'shortDesc': 'A local-only move that must be preserved.',
      'generation': 9,
    },
    <String, dynamic>{
      'id': 'vine_whip',
      'name': 'Liane',
      'names': <String, String>{
        'en': 'Vine Whip',
        'fr': 'Fouet Lianes',
      },
      'type': 'grass',
      'category': 'physical',
      'power': 40,
      'accuracy': 95,
      'pp': 20,
      'priority': 0,
      'target': 'normal',
      'shortDesc': 'Old local description.',
      'generation': 3,
      'editorNote': 'Keep this local-only field after sync.',
    },
  ],
);
```
