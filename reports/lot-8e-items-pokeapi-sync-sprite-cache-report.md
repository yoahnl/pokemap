# Lot 8e — Items PokeAPI Sync + Sprite Cache

## 1. Résumé exécutif honnête

Le lot 8e est fermé dans `packages/map_editor` uniquement.

Ce qui a été ajouté :
- un vrai use case de synchronisation PokéAPI pour `Catalogues Pokémon > Items` ;
- un merge local/externe qui préserve les entrées locales absentes de PokéAPI et les champs locaux custom non gérés ;
- un pipeline de cache sprite local sous le projet ;
- une UI Items capable de lancer une preview/sync minimale, d’afficher un résumé de sync, et d’exploiter les métadonnées de sprite sans aucun fetch live dans le widget ;
- des tests de sync, de merge, de sprite cache, de custom `pokemon.dataRoot`, et de régression editor.

Ce qui n’a pas été fait :
- aucun BAG battle ;
- aucune consommation d’item ;
- aucune logique de capture/soin/inventaire runtime ;
- aucun fetch live dans l’UI ;
- aucun téléchargement d’image au render ;
- aucune sync Moves PokeAPI ;
- aucune édition CRUD Items ;
- aucun rendu `Image.network`.

Le lot reste volontairement borné : sync locale testable, cache projet, UI read-only enrichie.

## 2. État git initial

### `git status --short --untracked-files=all`

```text
```

### `git diff --stat`

```text
```

### `git ls-files --others --exclude-standard`

```text
```

Classification honnête de la dirtiness initiale :
- `preexisting_in_scope`: aucune
- `preexisting_out_of_scope`: aucune
- `created_by_this_lot`: tous les changements actuels

## 3. Fichiers lus

- `reports/lot-8d-items-catalog-foundation-report.md`
- `reports/lot-8c-moves-catalog-foundation-report.md`
- `reports/lot-8b-fix-pokemon-catalogs-navigation-correction-report.md`
- `packages/map_editor/lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart`
- `packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart`
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart`
- `packages/map_editor/test/pokemon_items_catalog_loader_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart`
- `packages/map_editor/test/load_pokemon_items_catalog_use_case_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_lookup_service_test.dart`
- `packages/map_editor/test/pokemon_catalogs_workspace_ui_test.dart`
- `packages/map_editor/test/pokemon_catalogs_project_explorer_entry_test.dart`
- `packages/map_editor/test/editor_shell_page_smoke_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `packages/map_editor/test/search_external_pokemon_species_use_case_test.dart`
- `packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart`

## 4. Fichiers modifiés/créés

### Modifiés

- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`
- `packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart`
- `packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart`
- `packages/map_editor/test/search_external_pokemon_species_use_case_test.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

### Créés

- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart`
- `packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart`

## 5. Fichiers volontairement non touchés

- `packages/map_battle/**`
- `packages/map_runtime/**`
- `packages/map_core/**`
- `examples/playable_runtime_host/**`
- la navigation globale `Catalogues Pokémon` hors surface Items déjà existante
- `project.json` des projets utilisateur

## 6. Décision d’architecture

### Port externe

Le lot étend minimalement le port existant `PokemonExternalSourceRepository` avec :
- `fetchPokeApiItemsResourceList({limit, offset})`
- `fetchPokeApiItemPayload(itemIdOrName)`

Je n’ai pas créé de client HTTP parallèle, ni branché PokéAPI depuis l’UI.

### Use case

Le nouveau centre de gravité est :
- `SyncExternalPokemonItemsCatalogUseCase`

Il orchestre :
- lecture du catalogue local si présent ;
- lecture paginée de la liste d’items PokeAPI ;
- fetch du détail item ;
- conversion vers le format local ;
- merge avec le catalogue existant ;
- téléchargement/cache des sprites si demandé ;
- écriture du catalogue seulement hors dry-run.

### Écriture catalogue

Le catalogue Items n’est pas écrit via `saveCatalogByKey()` parce que ce seam existant force le chemin par défaut `data/pokemon/catalogs/items.json`.

Comme le lot devait respecter :
- `pokemon.dataRoot`
- `pokemon.catalogFiles['items']`
- `pokemon_data_manifest.json -> catalogFiles['items']`

j’ai utilisé le plus petit seam honnête déjà disponible dans `map_editor` :
- résolution du chemin relatif côté use case ;
- écriture JSON via `ProjectWorkspace.writeTextFile(...)` sur le chemin résolu.

Je n’ai pas ouvert de nouveau port d’écriture global juste pour ça.

### Écriture binaire

Pour les sprites, j’ai réutilisé la plomberie existante :
- `PokemonExternalSourceRepository.fetchBinaryAsset(...)`
- `PokemonWriteRepository.saveBinaryAsset(...)`

Il n’a pas fallu rouvrir `ProjectWorkspace` ni `map_core`.

### UI

Le workspace Items reste le propriétaire de sa sync minimale.

J’ai ajouté :
- `Preview sync`
- `Sync depuis PokéAPI`

via un provider overrideable, pas via un client HTTP dans le widget.

## 7. Format local items retenu

Le lot écrit toujours dans le catalogue local unique du projet :
- par défaut `data/pokemon/catalogs/items.json`
- ou le chemin résolu par config/manifest quand il est customisé

Forme locale écrite pour les entrées synchronisées :
- `id`
- `pokeApiId`
- `name`
- `names`
- `categoryId`
- `pocketId`
- `cost`
- `flingPower`
- `flingEffectId`
- `shortEffectText`
- `effectText`
- `flavorText`
- `spriteUrl`
- `localSpritePath` seulement si le fichier local existe réellement
- `source = "pokeapi"`
- `sourceRefs`

Le lot préserve aussi les champs locaux additionnels non gérés par la sync.

## 8. Stratégie de merge

Règle retenue :
- merge par `id`
- priorité externe sur les champs PokéAPI connus
- si la valeur externe connue vaut `null`, on préserve la valeur locale utile existante
- les maps `names` et `sourceRefs` sont fusionnées
- les champs purement locaux non gérés sont conservés
- les entrées locales absentes du snapshot externe sont préservées inchangées
- tri final stable par `id`

Cas spécifique `localSpritePath` :
- il est nettoyé avant merge si le fichier local n’existe pas ;
- il n’est écrit qu’après download réel réussi, ou s’il pointe déjà vers un asset local existant ;
- il n’est jamais laissé vers un fichier absent.

## 9. Pipeline sprite local

Chemin cible :
- par défaut `data/pokemon/assets/items/<item-id>.png`
- ou `<pokemon.dataRoot>/assets/items/<item-id>.png` si le projet redéfinit `dataRoot`

Règles appliquées :
- aucun download en dry-run
- aucun download si `downloadSprites == false`
- aucun re-download si le fichier cible existe déjà et `overwriteSprites == false`
- aucun crash global si un sprite échoue
- warnings explicites par item en cas d’échec
- `spriteUrl` reste renseigné même si le download échoue
- `localSpritePath` n’est renseigné que si l’asset local existe

## 10. Comportement UI obtenu

Dans `Catalogues Pokémon > Items` :
- le workspace reste local/read-only ;
- il expose maintenant une action de preview et une vraie sync ;
- il affiche un petit résumé :
  - prévisualisation
  - ou synchronisation
  - ou message d’échec

Pour les sprites :
- aucun `Image.network`
- si un sprite local existe, l’UI l’exploite via un preview local/fallback local stable
- si seul `spriteUrl` existe, l’UI reste textuelle :
  - `Sprite metadata available`
  - `Sprite disponible après sync assets.`
- si rien n’existe :
  - `No sprite metadata`

## 11. Tests ajoutés et ce qu’ils prouvent

### `packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart`

Prouve :
- le dry-run ne modifie ni `items.json`, ni `project.json`, ni les sprites ;
- la vraie sync écrit le catalogue local ;
- les entrées local-only sont préservées ;
- les champs locaux custom sont préservés ;
- les champs PokéAPI connus sont mis à jour ;
- les sprites sont téléchargés au bon endroit ;
- les sprites sont skip si déjà présents ou sans metadata ;
- les échecs de téléchargement n’annulent pas la sync ;
- la conversion du payload item PokeAPI est correcte ;
- les doublons et payloads malformés produisent des warnings sans crash global ;
- le loader lit correctement le catalogue généré après sync ;
- le custom `pokemon.dataRoot` s’applique aussi aux chemins sprite.

### `packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart`

Renforcé pour prouver :
- l’état `metadata only` reste textuel quand seul `spriteUrl` existe ;
- le helper public de sprite local détecte correctement un asset local existant ;
- le bouton `Preview sync` appelle bien le syncer overrideable avec les bons flags ;
- l’UI expose un résumé de preview/sync.

### Régressions

Relancées sur :
- loader Items
- workspace Items
- lookup service Items
- shell `Catalogues Pokémon`
- shell editor
- Pokédex
- Moves catalog
- use cases externes Pokémon
- sync Moves existante

## 12. Validations exécutées avec résultats

### Analyse ciblée

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter analyze --no-pub \
  lib/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart \
  lib/src/application/use_cases/load_pokemon_items_catalog_use_case.dart \
  lib/src/application/ports/pokemon_external_source_repository.dart \
  lib/src/infrastructure/external/pokeapi_live_source.dart \
  lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart \
  lib/src/app/providers/pokedex/pokedex_providers.dart \
  lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart \
  lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart \
  test/sync_pokemon_items_catalog_use_case_test.dart \
  test/pokemon_items_catalog_workspace_ui_test.dart \
  test/pokemon_items_catalog_loader_test.dart \
  test/load_pokemon_items_catalog_use_case_test.dart \
  test/pokemon_items_catalog_lookup_service_test.dart \
  test/pokemon_catalogs_workspace_ui_test.dart \
  test/pokemon_catalogs_project_explorer_entry_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/top_toolbar_test.dart \
  test/pokedex_workspace_ui_test.dart \
  test/pokemon_moves_catalog_workspace_ui_test.dart \
  test/pokemon_moves_catalog_loader_test.dart \
  test/search_external_pokemon_species_use_case_test.dart \
  test/import_external_pokemon_use_cases_test.dart \
  test/sync_pokemon_moves_catalog_use_case_test.dart \
  test/resolve_external_pokemon_batch_selection_use_case_test.dart
```

Résultat :
- vert

### Tests ciblés sync + UI

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test \
  test/sync_pokemon_items_catalog_use_case_test.dart \
  test/pokemon_items_catalog_workspace_ui_test.dart
```

Résultat :
- vert

### Régressions demandées

```bash
cd /Users/karim/Project/pokemonProject/packages/map_editor
flutter test \
  test/sync_pokemon_items_catalog_use_case_test.dart \
  test/pokemon_items_catalog_loader_test.dart \
  test/pokemon_items_catalog_workspace_ui_test.dart \
  test/load_pokemon_items_catalog_use_case_test.dart \
  test/pokemon_items_catalog_lookup_service_test.dart \
  test/pokemon_catalogs_workspace_ui_test.dart \
  test/pokemon_catalogs_project_explorer_entry_test.dart \
  test/editor_shell_page_smoke_test.dart \
  test/top_toolbar_test.dart \
  test/pokedex_workspace_ui_test.dart \
  test/pokemon_moves_catalog_workspace_ui_test.dart \
  test/pokemon_moves_catalog_loader_test.dart \
  test/search_external_pokemon_species_use_case_test.dart \
  test/import_external_pokemon_use_cases_test.dart \
  test/sync_pokemon_moves_catalog_use_case_test.dart \
  test/resolve_external_pokemon_batch_selection_use_case_test.dart
```

Résultat :
- vert

### Workaround tooling

Aucun `rm -rf macos/Flutter/ephemeral/Packages/.packages` n’a été nécessaire dans cette session.

## 13. Limites assumées

- la sync Items reste volontairement snapshot locale et manuelle, pas live ;
- aucun fetch live au render UI ;
- aucun téléchargement batch concurrent agressif ;
- `pocketId` n’est renseigné que si le payload item local/PokeAPI-like l’expose déjà dans une forme supportée ;
- le preview local sprite reste volontairement sobre ;
- le lot ne branche pas encore les items vers BAG battle, runtime, soin, capture ou inventaire.

## 14. Ce qui est reporté au lot suivant

Pour `lot 8f` ou l’étape suivante côté Items :
- sync plus riche des catégories/pockets si besoin via endpoints complémentaires ;
- vrai rendu sprite local plus ambitieux si souhaité ;
- enrichissement de la fiche item ;
- éventuelle édition locale manuelle ;
- bridge futur avec BAG battle, mais hors de ce lot ;
- éventuelle stratégie d’overwrite sprite configurable plus fine.

## 15. Retour de review séparée

Une review séparée a été demandée via sub-agent sur les points sensibles :
- dry-run
- merge local custom
- chemins custom `pokemon.dataRoot`
- sprite cache
- absence de fetch UI
- navigation `Catalogues Pokémon`

Résultat honnête :
- le reviewer n’a pas rendu de findings exploitables avant timeout ;
- aucune finding inventée ;
- la clôture du lot s’appuie donc sur les validations locales exécutées et les régressions vertes.

## 16. État git final exact

### `git status --short --untracked-files=all`

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/app/providers/pokemon_items/pokemon_items_workspace_providers.dart
 M packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart
 M packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/ui/canvas/pokemon_catalogs_workspace/items_catalog_workspace.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
 M packages/map_editor/test/pokemon_items_catalog_workspace_ui_test.dart
 M packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart
 M packages/map_editor/test/search_external_pokemon_species_use_case_test.dart
 M packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? packages/map_editor/lib/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart
?? packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart
?? reports/lot-8e-items-pokeapi-sync-sprite-cache-report.md
```

### `git diff --stat`

```text
 .../app/providers/pokedex/pokedex_providers.dart   |  11 +
 .../pokemon_items_workspace_providers.dart         |  37 ++
 .../ports/pokemon_external_source_repository.dart  |   7 +
 .../external/pokeapi_live_source.dart              |  47 +++
 .../http_pokemon_external_source_repository.dart   |  18 +
 .../items_catalog_workspace.dart                   | 383 +++++++++++++++++++--
 .../import_external_pokemon_use_cases_test.dart    |  13 +
 .../pokemon_items_catalog_workspace_ui_test.dart   | 173 +++++++++-
 ...rnal_pokemon_batch_selection_use_case_test.dart |  13 +
 ...rch_external_pokemon_species_use_case_test.dart |  13 +
 .../sync_pokemon_moves_catalog_use_case_test.dart  |  13 +
 11 files changed, 699 insertions(+), 29 deletions(-)
```

### `git ls-files --others --exclude-standard`

```text
packages/map_editor/lib/src/application/use_cases/sync_pokemon_items_catalog_use_case.dart
packages/map_editor/test/sync_pokemon_items_catalog_use_case_test.dart
reports/lot-8e-items-pokeapi-sync-sprite-cache-report.md
```

## 17. Décision finale

**Lot 8e réussi.**

Le lot apporte bien :
- une sync PokéAPI Items testée sans réseau réel ;
- une écriture locale correcte de `items.json` ;
- la préservation des champs locaux custom ;
- un dry-run honnête ;
- un cache sprite local testable ;
- une UI Items enrichie sans `Image.network` ;
- aucune modification de `map_battle` ou `map_runtime` ;
- aucune régression visible de navigation `Catalogues Pokémon`.
