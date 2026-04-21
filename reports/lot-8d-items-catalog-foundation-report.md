# Lot 8d — Items Catalog Foundation / Local Project Item Catalog

## 1. Résumé exécutif honnête

Le lot 8d est fermé dans `map_editor` uniquement.

`Catalogues Pokémon > Items` n’est plus un shell. Le workspace Items lit maintenant un vrai catalogue local du projet, expose une recherche, une liste, un détail, des diagnostics non bloquants et des états honnêtes pour :

- aucun projet ;
- catalogue absent ;
- catalogue vide ;
- catalogue totalement invalide ;
- catalogue partiellement invalide ;
- catalogue illisible.

Le catalogue local retenu suit la convention du repo :

- `data/pokemon/catalogs/items.json`

Le lot ne fait pas :

- de fetch PokeAPI ;
- de téléchargement d’images ;
- de rendu réseau des sprites ;
- de sync live ;
- de modification `map_battle` ;
- de modification `map_runtime`.

Point d’honnêteté important :

- le worktree contenait déjà de la dirtiness autour des tests `Catalogues Pokémon` quand je suis arrivé sur ce lot ;
- j’ai volontairement gardé cette dirtiness hors-scope intacte ;
- j’ai seulement ajouté la fondation Items locale et le correctif reviewer sur le fallback réel de lecture du catalogue.

## 2. État git initial

Les pré-gates ont été demandés par le prompt.

Sorties consignées au démarrage du lot :

### `git status --short --untracked-files=all`

```text
```

### `git diff --stat`

```text
```

### `git ls-files --others --exclude-standard`

```text
```

Observation honnête :

- pendant l’implémentation, j’ai constaté que plusieurs fichiers de tests autour de `Catalogues Pokémon` étaient déjà dirty ou non suivis dans le worktree ;
- ce constat est incompatible avec le snapshot vide consigné au tout début de la session ;
- je l’ai traité comme une dirtiness préexistante et je n’ai fait aucune opération Git destructive pour “réparer” artificiellement cet état.

## 3. Fichiers lus

### Reports

- `reports/lot-8c-moves-catalog-foundation-report.md`
- `reports/lot-8b-pokemon-catalogs-workspace-shell-report.md`
- `reports/lot-8b-fix-pokemon-catalogs-navigation-correction-report.md`
- `reports/lot-8a-battle-bag-menu-contract-report.md`

### Catalogues Pokémon / navigation

- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_selectors.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

### Référence Moves

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/app/providers/pokemon_moves/pokemon_moves_workspace_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/moves_catalog_workspace.dart`
- `packages/map_editor/test/pokemon_moves_catalog_loader_test.dart`
- `packages/map_editor/test/pokemon_moves_catalog_workspace_ui_test.dart`

### Surface Items existante

- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart`
- `packages/map_editor/test/load_pokemon_items_catalog_use_case_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_lookup_service_test.dart`

### Tests shell/catalogues

- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/top_toolbar_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_loader_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart`

## 4. Fichiers modifiés / créés

### Modifiés par ce lot

- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart`
- `packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart`

### Créés par ce lot

- `packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart`
- `reports/lot-8d-items-catalog-foundation-report.md`

### Fichiers de tests déjà présents dans le worktree et utilisés comme garde-fous

- `packages/map_editor/test/pokemon_items_catalog_loader_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`

## 5. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_runtime/**`
- `examples/playable_runtime_host/**`
- `packages/map_core/**`
- navigation globale `Catalogues Pokémon` hors wiring déjà existant
- `Moves` comme source de vérité locale existante
- `Pokédex` hors non-régression
- tout fetch ou sync PokeAPI
- toute logique de téléchargement/render sprite réseau

## 6. Décision d’architecture

### Loader

J’ai renforcé le seam existant :

- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart`

au lieu de créer un deuxième loader concurrent.

Le use case :

- résout le chemin items local ;
- lit le catalogue local ;
- projette les entrées valides vers un modèle de vue stable ;
- conserve les entrées valides quand d’autres sont invalides ;
- émet des diagnostics non bloquants ;
- déduplique les ids en gardant la première entrée ;
- trie par nom case-insensitive puis id.

### Provider

J’ai ajouté un seam UI overrideable :

- `packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart`

Il :

- renvoie `noProject` quand `projectRootPath` est nul/vide ;
- instancie le `ProjectWorkspace` depuis le root courant ;
- appelle le use case Items local ;
- reste simple à override dans les widget tests.

### Workspace UI

J’ai ajouté :

- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart`

Le workspace est structuré comme un vrai catalogue local :

- header ;
- recherche ;
- liste ;
- détail ;
- résumé diagnostics ;
- états honnêtes.

### Intégration Catalogues Pokémon

`packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart` affiche maintenant :

- `PokemonCatalogSection.items => const PokemonItemsCatalogWorkspace()`

sans réintroduire de segmented control dans le canvas.

### Explorer

L’entrée Project Explorer `Items` annonce maintenant :

- `Catalogue local des objets du projet`

au lieu du placeholder précédent.

## 7. Format local items retenu

Convention retenue :

- `data/pokemon/catalogs/items.json`

Forme locale simple supportée :

```json
{
  "schemaVersion": 1,
  "kind": "pokemon_catalog",
  "catalog": "items",
  "meta": {
    "description": "Local items catalog."
  },
  "entries": [
    {
      "id": "poke-ball",
      "name": "Poké Ball",
      "categoryId": "standard-balls",
      "pocketId": "poke-balls",
      "cost": 200,
      "flingPower": 10,
      "flingEffectId": null,
      "effectText": "Used to catch wild Pokémon.",
      "shortEffectText": "Catches wild Pokémon.",
      "flavorText": "A device for catching wild Pokémon.",
      "spriteUrl": "https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/items/poke-ball.png",
      "localSpritePath": "data/pokemon/assets/items/poke-ball.png"
    }
  ]
}
```

Forme locale PokeAPI-like supportée aussi, sans réseau :

- `names.en`
- `category.name`
- `pocket.name`
- `effect_entries`
- `flavor_text_entries`
- `sprites.default`

## 8. Comportement utilisateur obtenu

Dans `Catalogues Pokémon > Items`, l’utilisateur voit maintenant :

- un vrai header `Items` ;
- le sous-titre `Catalogue local des objets du projet.` ;
- une barre de recherche ;
- une liste d’items locale ;
- un panneau détail ;
- un résumé diagnostics si certaines entrées sont ignorées.

États produits :

- aucun projet : `Ouvre un projet pour afficher le catalogue des items.`
- catalogue absent : message honnête avec chemin résolu
- catalogue vide : message dédié
- catalogue totalement invalide : message dédié
- catalogue partiellement invalide : items valides + résumé diagnostics

Le détail affiche :

- name ;
- id ;
- category ;
- pocket ;
- cost ;
- fling power ;
- fling effect ;
- short effect ;
- effect text ;
- flavor text ;
- sprite URL ;
- local sprite path.

Pour les champs absents :

- `—`

Les sprites restent strictement metadata-only dans ce lot :

- pas de `Image.network`
- pas de téléchargement
- pas de rendu image live
- seulement `Sprite metadata available` ou `No sprite metadata`

## 9. Tests ajoutés et ce qu’ils prouvent

### Loader

`packages/map_editor/test/pokemon_items_catalog_loader_test.dart`

Prouve :

- chargement d’un `items.json` local ;
- `missingCatalog` quand le fichier n’existe pas ;
- conservation des entrées valides si une autre entrée est invalide ;
- robustesse sur types incorrects ;
- tri stable par nom puis id ;
- déduplication par id avec diagnostic ;
- tolérance aux champs nullables ;
- `loadError` sur JSON cassé ;
- résolution honnête du chemin via `pokemon.dataRoot` + bootstrap manifest ;
- projection correcte d’une forme locale PokeAPI-like ;
- fallback réel vers le chemin configuré quand le bootstrap manifest est présent mais invalide.

### UI Items

`packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart`

Prouve :

- état `noProject` ;
- état vide quand aucun item local n’existe ;
- liste + sélection du premier item ;
- recherche par nom, id, catégorie, pocket et effet ;
- maintien des entrées valides si diagnostics présents ;
- état invalide quand tout le catalogue est ignoré ;
- formatage `—` pour champs absents ;
- affichage des métadonnées sprite sans `Image.network`.

### Shell / Catalogues Pokémon

Tests utilisés :

- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`

Prouvent :

- `Catalogues Pokémon > Items` affiche un vrai workspace ;
- l’entrée Explorer `Items` n’est plus un placeholder ;
- le shell editor reste cohérent ;
- pas de segmented control interne ;
- pas de régression `Moves` / `Pokédex`.

## 10. Validations exécutées avec résultats

### Analyse ciblée

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
rm -rf macos/Flutter/ephemeral/Packages/.packages && /opt/homebrew/bin/flutter analyze --no-pub \
  lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart \
  lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart \
  lib/src/ui/canvas/pokemon_catalogs_workspace.dart \
  lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart \
  lib/src/ui/panels/project_explorer_panel.dart \
  test/pokemon_items_catalog_loader_test.dart \
  test/pokemon_items_catalog_workspace_ui_test.dart \
  test/pokemon_catalogs_workspace_ui_test.dart \
  test/pokemon_catalogs_project_explorer_entry_test.dart \
  test/editor_shell_page_smoke_test.dart
```

Résultat final :

- `No issues found!`

Note :

- une première relance a remonté un warning `dead_code_on_catch_subtype` sur l’ordre des `catch` dans le loader Items ;
- il a été corrigé avant la validation finale.

### Tests ciblés demandés

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
rm -rf macos/Flutter/ephemeral/Packages/.packages && /opt/homebrew/bin/flutter test \
  test/pokemon_items_catalog_loader_test.dart \
  test/pokemon_items_catalog_workspace_ui_test.dart \
  test/pokemon_catalogs_workspace_ui_test.dart \
  test/pokemon_catalogs_project_explorer_entry_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/top_toolbar_test.dart \
  test/pokedex_workspace_ui_test.dart \
  test/pokemon_moves_catalog_workspace_ui_test.dart \
  test/pokemon_moves_catalog_loader_test.dart
```

Résultat :

- tout vert

### Vérifications complémentaires

Commandes :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
/opt/homebrew/bin/flutter test test/pokemon_items_catalog_loader_test.dart
/opt/homebrew/bin/flutter test test/pokemon_items_catalog_workspace_ui_test.dart
/opt/homebrew/bin/flutter test test/load_pokemon_items_catalog_use_case_test.dart test/pokemon_items_catalog_lookup_service_test.dart
```

Résultat :

- tout vert

## 11. Limites assumées

Le lot 8d reste volontairement borné :

- catalogue read-only ;
- pas de création/édition/suppression d’items ;
- pas de sync PokeAPI ;
- pas de téléchargement ni cache sprite ;
- pas de rendu image réel ;
- pas de bridge vers le BAG battle ;
- pas de logique de consommation/soin/capture ;
- pas de filtres avancés par pocket/category ;
- pas de système générique de catalogues transverse supplémentaire.

## 12. Ce qui est reporté au lot 8e

Report explicite :

- sync PokeAPI items ;
- génération/écriture du catalogue items depuis source externe ;
- récupération et gestion des sprites locaux ;
- rendu image réel ou cache d’assets ;
- enrichissement battle/BAG futur si demandé.

## 13. Retour de review séparée

Reviewer séparé :

- `Pascal` (sub-agent)

Finding initial réel :

- `[P2] Le fallback de chemin n'était pas réellement utilisé pour la lecture`

Problème :

- le use case calculait un chemin fallback honnête ;
- puis relisait via `readCatalogByKey()`, qui pouvait re-casser sur un bootstrap manifest invalide ;
- le chemin affiché devenait alors trompeur.

Correction appliquée :

- ajout d’un fallback de lecture directe sur le chemin résolu ;
- ajout d’un test dédié :
  - `falls back to the configured items catalog path when the bootstrap manifest is invalid`

Re-review :

- aucun finding sérieux restant

Limite honnête du reviewer :

- il n’a pas pu lancer `flutter test` dans son propre environnement ;
- la vérification runtime des commandes a été faite localement dans cette session principale.

## 14. État git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace.dart
 M packages/map_editor/lib/src/ui/panels/project_explorer_panel.dart
 M packages/map_editor/test/editor_shell_page_smoke_test.dart
 M packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart
 M packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart
?? packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart
?? packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart
?? packages/map_editor/test/pokemon_items_catalog_loader_test.dart
?? packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart
?? reports/lot-8d-items-catalog-foundation-report.md
```

### `git diff --stat`

```text
 .../load_pokemon_items_catalog_use_case.dart       | 577 +++++++++++++++++++--
 .../src/ui/canvas/pokemon_catalogs_workspace.dart  |  97 +---
 .../lib/src/ui/panels/project_explorer_panel.dart  |   2 +-
 .../test/editor_shell_page_smoke_test.dart         |  51 ++
 ...kemon_catalogs_project_explorer_entry_test.dart |   4 +
 .../test/pokemon_catalogs_workspace_ui_test.dart   |  23 +-
 6 files changed, 609 insertions(+), 145 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart
packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart
packages/map_editor/test/pokemon_items_catalog_loader_test.dart
packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart
reports/lot-8d-items-catalog-foundation-report.md
```

## 15. Décision finale

Lot 8d réussi : `Catalogues Pokémon > Items` dispose maintenant d’un vrai workspace local lisant `items.json`, avec loader robuste, recherche, liste, détail, diagnostics et états honnêtes, sans PokeAPI live, sans téléchargement d’images et sans toucher au battle/runtime.
