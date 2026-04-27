# Phase 11B — Moves catalog externe + surface editor minimale

## 1. Résumé exécutif honnête

La phase 11B a été implémentée en restant dans le scope demandé : import/sync local du catalogue moves, surface editor minimale dans l’onglet Learnset, et intégration utile du catalogue local côté édition de learnset.

Le choix retenu après audit est volontairement petit et défendable :
- source principale d’import bulk des moves : le snapshot Showdown `moves.json` ;
- aucune réouverture du pipeline 11A Pokémon ;
- aucune nouvelle stack parallèle ;
- aucune modification de `project.json`.

Le catalogue local `moves.json` peut maintenant être synchronisé depuis l’éditeur, consulté localement, et utilisé comme garde-fou lorsque le learnset editor enregistre des move ids.

## 2. Verdict

**Phase 11B livrable et stable dans son scope.**

## 3. État initial audité

Avant ce passage, le repo exposait déjà :
- un stockage local générique des catalogues Pokémon via `PokemonCatalogFile` ;
- un chemin stable `data/pokemon/catalogs/moves.json` ;
- un validateur projet qui savait déjà signaler `learnset.move_missing_in_catalog` ;
- un pipeline 11A d’import externe Pokémon branché sur Showdown + PokeAPI ;
- une surface Pokédex/learnset existante, mais sans sync local du catalogue moves ni consommation utile du catalogue côté learnset editor.

Constat réel après audit :
- les learnsets externes savent déjà produire des `moveId` normalisés ;
- aucune surface minimale n’existait encore pour importer ou consulter le catalogue local `moves` ;
- `UpdatePokedexSpeciesLearnsetUseCase` ne validait pas les `moveId` contre le catalogue local.

## 4. Audit fichier par fichier

Fichiers audités localement avant implémentation :
- `packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart`
  - confirmé : le catalogue moves utilise déjà `PokemonCatalogFile` générique.
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
  - confirmé : le port externe 11A existe déjà ; extension minimale possible.
- `packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart`
  - confirmé : lecture des catalogues déjà supportée.
- `packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart`
  - confirmé : écriture des catalogues déjà supportée.
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
  - confirmé : `moves.json` est déjà mappé vers `data/pokemon/catalogs/moves.json`.
- `packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart`
  - confirmé : `fetchMovesSnapshot()` existe déjà.
- `packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart`
  - audité pour vérifier les payloads `move/*`, mais non retenu en bulk sync 11B.
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
  - confirmé : façade externe mince, adaptée à une extension minimale.
- `packages/map_editor/lib/src/application/services/pokemon_project_validator.dart`
  - confirmé : validation projet existe déjà pour les moves absents du catalogue.
- `packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart`
  - confirmé : import JSON local simple déjà présent, mais pas de sync externe.
- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart`
  - confirmé : édition learnset locale existante, sans garde-fou catalogue.
- `packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart`
  - confirmé : les `moveId` produits sont déjà normalisés en `snake_case`.
- `packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart`
  - confirmé : la convention `moves -> snake_case` existe déjà côté normalisation.
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
  - confirmé : point de wiring naturel pour réutiliser le pipeline existant.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
  - confirmé : point d’injection honnête pour ajouter les callbacks UI minimaux.
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart`
  - confirmé : l’onglet Learnset est le point d’entrée UI minimal le plus honnête.

## 5. Audit réel des sources externes moves

### PokeAPI

Audit réel exécuté via `curl` et `jq` :
- `https://pokeapi.co/api/v2/move?limit=3`
- `https://pokeapi.co/api/v2/move/thunderbolt`
- `https://pokeapi.co/api/v2/move/vine-whip`

Faits vérifiés :
- PokeAPI expose bien `pp`, `power`, `accuracy`, `priority`, `type`, `damage_class`, `target`, `generation`, `names`, `effect_entries`.
- Le payload est riche, mais il faut une requête par move pour un bulk sync réaliste.

Décision : **auditée mais non retenue comme source primaire de sync bulk 11B**.

### Showdown

Audit réel exécuté via `curl` et `jq` :
- `https://play.pokemonshowdown.com/data/moves.json`
- vérifications ciblées sur `thunderbolt`, `vinewhip`, `willowisp`, `xscissor`.

Faits vérifiés :
- le snapshot `moves.json` existe ;
- il expose déjà `name`, `pp`, `basePower`, `accuracy`, `priority`, `type`, `category`, `target`, `shortDesc`, `desc`, `gen` ;
- `ShowdownSnapshotSource.fetchMovesSnapshot()` existait déjà dans le repo.

Décision : **source primaire retenue pour le sync local du catalogue moves**.

## 6. Décisions d’architecture retenues / rejetées

Décisions retenues :
- étendre minimalement le port externe 11A avec `fetchShowdownMovesSnapshot()` ;
- convertir `moves.json` Showdown vers le schéma local `PokemonCatalogFile` ;
- garder les ids locaux en `snake_case` ;
- effectuer un merge déterministe par id :
  - les entrées externes créent ou mettent à jour ;
  - les entrées locales absentes du snapshot sont conservées ;
  - les champs locaux non gérés par 11B sont préservés ;
  - `names.fr` et autres enrichissements locaux restent conservés ;
- ajouter une surface minimale dans l’onglet Learnset ;
- ajouter une validation learnset contre le catalogue local uniquement quand ce catalogue est réellement lisible et non vide.

Décisions rejetées :
- nouveau port externe parallèle dédié aux moves ;
- nouveau repository externe ou nouvelle stack HTTP ;
- refonte du wizard 11A ;
- PokeAPI comme source bulk principale de sync ;
- nouvelle Move Library autonome ;
- refonte des providers ;
- import global des moves dans le runtime ou hors `map_editor`.

## 7. Sub-agents utilisés et synthèse de leurs conclusions

Sub-agents réutilisés intelligemment :
- `Boyle` : audit schéma local / conventions d’IDs.
  - conclusion retenue : le stockage local moves existe déjà et les ids doivent rester `snake_case`.
- `Hypatia` : audit API moves.
  - conclusion retenue : Showdown `moves.json` est la meilleure source bulk 11B ; PokeAPI reste une source auditée mais non retenue comme bulk.
- `Mendel` : revue architecture / wiring.
  - conclusion retenue : étendre minimalement le port externe existant et réutiliser `pokedex_providers.dart` + le workspace Pokédex.
- `Avicenna` : revue UI minimale.
  - conclusion retenue : la plus petite surface utile est dans l’onglet Learnset, pas un nouveau workspace.
- `Banach` : revue matrice de tests.
  - conclusion retenue : tests use case, wiring, learnset validation et widget flow suffisent pour ce scope.

## 8. Liste exacte des fichiers modifiés / créés / supprimés

Modifiés :
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/test/http_pokemon_external_source_repository_test.dart`
- `packages/map_editor/test/pokedex_workspace_ui_test.dart`
- `packages/map_editor/test/provider_wiring_test.dart`
- `packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart`

Créés :
- `packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`
- `packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`
- `packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`
- `reports/phase-11b-moves-catalog-report.md`

Supprimés :
- aucun.

## 9. Justification fichier par fichier

- `pokedex_providers.dart`
  - ajout du wiring minimal des nouveaux use cases et callbacks moves catalog.
- `pokemon_external_source_repository.dart`
  - extension minimale du port 11A existant ; aucun port concurrent.
- `showdown_move_catalog_converter.dart`
  - conversion explicite et documentée de `moves.json` vers le schéma local.
- `sync_pokemon_moves_catalog_use_case.dart`
  - cœur 11B : sync/preview + chargement local du catalogue.
- `update_pokedex_species_learnset_use_case.dart`
  - intégration learnset minimale utile via validation contre le catalogue local.
- `use_cases.dart`
  - export du nouveau use case sans refonte.
- `http_pokemon_external_source_repository.dart`
  - délégation minimale vers `fetchMovesSnapshot()`.
- `pokedex_workspace_loader.dart`
  - ajout des typedefs d’injection pour la surface UI minimale.
- `pokedex_workspace_page.dart`
  - injection des nouveaux callbacks depuis les providers existants.
- `pokedex_workspace_body.dart`
  - binding local des callbacks workspace -> UI Learnset.
- `pokedex_detail_panel.dart`
  - propagation du wiring vers l’onglet Learnset uniquement.
- `pokedex_learnset_panel.dart`
  - insertion du bloc catalogue moves dans la surface existante.
- `pokedex_moves_catalog_section.dart`
  - nouvelle surface minimale, locale et consultable pour la 11B.
- `pokedex_common_widgets.dart`
  - support de clé de widget pour les tests du nouveau bloc.
- `http_pokemon_external_source_repository_test.dart`
  - verrouille la nouvelle extension de façade externe.
- `sync_pokemon_moves_catalog_use_case_test.dart`
  - verrouille preview/dry-run, merge local, ids, préservation des champs locaux, `project.json` inchangé.
- `provider_wiring_test.dart`
  - verrouille la résolution des nouveaux providers.
- `update_pokedex_species_learnset_use_case_test.dart`
  - verrouille la validation learnset contre le catalogue local.
- `pokedex_workspace_ui_test.dart`
  - verrouille la surface UI minimale réellement utilisable dans l’onglet Learnset.

## 10. Commandes réellement exécutées

```bash
find . -name AGENTS.md -print
rg -n "move|moves|learnset|catalog" packages/map_editor/lib packages/map_editor/test -g '*.dart'
sed -n '1,260p' packages/map_editor/lib/src/application/models/pokemon_project_data_models.dart
sed -n '1,260p' packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
sed -n '1,260p' packages/map_editor/lib/src/application/ports/pokemon_read_repository.dart
sed -n '1,280p' packages/map_editor/lib/src/application/ports/pokemon_write_repository.dart
sed -n '1,320p' packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart
sed -n '1,240p' packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart
sed -n '1,260p' packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
sed -n '1,280p' packages/map_editor/lib/src/application/services/external_pokemon_catalog_normalizer.dart
sed -n '1,260p' packages/map_editor/lib/src/application/services/pokeapi_pokemon_learnset_converter.dart
sed -n '1,260p' packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart
sed -n '1,220p' packages/map_editor/lib/src/application/use_cases/import_pokemon_catalog_json_use_case.dart
sed -n '1,280p' packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
sed -n '280,520p' packages/map_editor/lib/src/application/services/pokemon_project_validator.dart
sed -n '1,260p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '261,520p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
sed -n '1,320p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
sed -n '1,280p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '280,520p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart
sed -n '1,340p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_sections.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart
sed -n '240,380p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart
sed -n '1,260p' packages/map_editor/lib/src/application/services/pokemon_project_data_reader.dart
sed -n '1,240p' packages/map_editor/lib/src/application/use_cases/use_cases.dart
sed -n '1,260p' packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart
sed -n '1,260p' packages/map_editor/test/showdown_snapshot_source_test.dart
sed -n '1,280p' packages/map_editor/test/http_pokemon_external_source_repository_test.dart
sed -n '1,240p' packages/map_editor/test/provider_wiring_test.dart
sed -n '1,320p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '321,760p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '760,1260p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1261,1720p' packages/map_editor/test/pokedex_workspace_ui_test.dart
command -v jq || true
curl -s 'https://pokeapi.co/api/v2/move?limit=3' | head -c 1200
curl -s https://pokeapi.co/api/v2/move/thunderbolt | head -c 4000
curl -I -s https://pokeapi.co/api/v2/move/thunderbolt
curl -s https://pokeapi.co/api/v2/move/thunderbolt | jq '{name, id, pp, power, accuracy, priority, type: .type.name, damage_class: .damage_class.name, target: .target.name, generation: .generation.name, short_effect: (.effect_entries[] | select(.language.name=="en") | .short_effect), english_name: (.names[] | select(.language.name=="en") | .name), french_name: (.names[] | select(.language.name=="fr") | .name)}'
curl -s https://pokeapi.co/api/v2/move/vine-whip | jq '{name, english_name: (.names[] | select(.language.name=="en") | .name), french_name: (.names[] | select(.language.name=="fr") | .name)}'
curl -s https://play.pokemonshowdown.com/data/moves.json | head -c 4000
curl -s https://play.pokemonshowdown.com/data/moves.json | rg -o '"vinewhip"|"thunderbolt"|"willowisp"|"xscissor"' -n
curl -s https://play.pokemonshowdown.com/data/moves.json | jq '.thunderbolt | {name, num, pp, basePower, accuracy, priority, type, category, target, shortDesc, desc, isNonstandard}'
curl -s https://play.pokemonshowdown.com/data/moves.json | jq '.vinewhip | {name, type, category, target, shortDesc}'
curl -s https://play.pokemonshowdown.com/data/moves.json | jq '.thunderbolt | {name, gen, num, type, category, target}'
dart format packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart packages/map_editor/test/http_pokemon_external_source_repository_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart
dart format packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter analyze --no-pub lib/src/application/ports/pokemon_external_source_repository.dart lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart lib/src/application/services/showdown_move_catalog_converter.dart lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart lib/src/application/use_cases/use_cases.dart lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/ui/canvas/pokedex_workspace_loader.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart test/sync_pokemon_moves_catalog_use_case_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/update_pokedex_species_learnset_use_case_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/sync_pokemon_moves_catalog_use_case_test.dart test/update_pokedex_species_learnset_use_case_test.dart test/http_pokemon_external_source_repository_test.dart test/provider_wiring_test.dart test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/pokedex_workspace_ui_test.dart
cd /Users/karim/Project/pokemonProject/packages/map_editor && flutter test test/showdown_snapshot_source_test.dart
git status --short -- packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart packages/map_editor/test/http_pokemon_external_source_repository_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports/phase-11b-moves-catalog-report.md
git diff --stat -- packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart packages/map_editor/test/http_pokemon_external_source_repository_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart packages/map_editor/test/pokedex_workspace_ui_test.dart reports/phase-11b-moves-catalog-report.md
git ls-files --others --exclude-standard -- reports/phase-11b-moves-catalog-report.md
```

## 11. Résultats réels

- `find . -name AGENTS.md -print`
  - a confirmé qu’il n’y avait pas d’instructions plus profondes dans `packages/map_editor`.
- audit local
  - a confirmé que le stockage `moves.json`, le reader/writer et la validation projet existaient déjà.
- audit API
  - a confirmé que Showdown `moves.json` est exploitable directement comme source bulk ;
  - a confirmé que PokeAPI `move/*` est riche mais pas adaptée au bulk sync minimal.
- `dart format ...`
  - `Formatted 19 files (5 changed) in 0.05 seconds.`
  - puis `Formatted 1 file (0 changed) in 0.01 seconds.`
- `flutter analyze --no-pub ...`
  - `No issues found! (ran in 2.0s)`
- premier `flutter test ...` ciblé
  - a révélé une vraie régression UI : overflow horizontal du nouveau bloc moves.
- correctif local sur le bloc moves
  - actions rendues responsives via `Wrap`.
- `flutter test test/pokedex_workspace_ui_test.dart`
  - `All tests passed!`
- `flutter test` ciblé final
  - `All tests passed!`
- `flutter test test/showdown_snapshot_source_test.dart`
  - `All tests passed!`

## 12. Incidents rencontrés

- Le premier run de widget tests a révélé un overflow horizontal du nouveau bloc "catalogue local des attaques" dans la colonne Learnset.
- Le bug était réel et local au rendu des boutons du bloc.
- Correction minimale appliquée : passage de `Row` à `Wrap` pour garder la surface utilisable sans refonte UI.
- Aucun autre incident bloquant.

## 13. État git utile

### `git status --short`
```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
 M packages/map_editor/test/http_pokemon_external_source_repository_test.dart
 M packages/map_editor/test/pokedex_workspace_ui_test.dart
 M packages/map_editor/test/provider_wiring_test.dart
 M packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart
?? packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart
?? packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart
?? packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart
?? reports/phase-11b-moves-catalog-report.md
```

### `git diff --stat`
```text
 .../app/providers/pokedex/pokedex_providers.dart   |  36 ++++++
 .../ports/pokemon_external_source_repository.dart  |  14 +++
 .../update_pokedex_species_learnset_use_case.dart  |  67 +++++++++++
 .../lib/src/application/use_cases/use_cases.dart   |   1 +
 .../http_pokemon_external_source_repository.dart   |   5 +
 .../pokedex_workspace/pokedex_common_widgets.dart  |   1 +
 .../pokedex_workspace/pokedex_detail_panel.dart    |  30 +++++
 .../pokedex_workspace/pokedex_learnset_panel.dart  |  13 +++
 .../pokedex_workspace/pokedex_workspace_body.dart  |  36 ++++++
 .../pokedex_workspace/pokedex_workspace_page.dart  |  24 ++++
 .../src/ui/canvas/pokedex_workspace_loader.dart    |  15 +++
 ...tp_pokemon_external_source_repository_test.dart |  13 +++
 .../map_editor/test/pokedex_workspace_ui_test.dart | 124 +++++++++++++++++++++
 packages/map_editor/test/provider_wiring_test.dart |  11 ++
 ...ate_pokedex_species_learnset_use_case_test.dart |  97 ++++++++++++++++
 15 files changed, 487 insertions(+)
```

### `git ls-files --others --exclude-standard -- reports/phase-11b-moves-catalog-report.md`
```text
reports/phase-11b-moves-catalog-report.md
```

## 14. Limites restantes

Limites réelles, laissées volontairement hors scope :
- pas de Move Library complète ni de fiche move détaillée autonome ;
- pas d’import abilities/items/types dans cette phase ;
- pas de batch Pokémon produit supplémentaire ;
- pas de cache disque ;
- pas de refonte globale du wizard 11A ;
- pas d’enrichissement bulk via PokeAPI move-by-move.

## 15. Checklist finale

- [x] audit réel du modèle moves local
- [x] audit réel des payloads externes utiles
- [x] stratégie source moves documentée et prouvée
- [x] sync local du catalogue moves implémenté
- [x] preview/dry-run moves disponible
- [x] wiring providers minimal branché
- [x] surface editor minimale réelle dans l’onglet Learnset
- [x] intégration learnset minimale utile via validation catalogue
- [x] `project.json` inchangé
- [x] tests ciblés passent
- [x] analyse ciblée passe
- [x] report final créé
- [x] preuves git incluses
- [x] annexe complète des fichiers texte modifiés/créés incluse

## 16. Annexe avec l’entièreté de TOUS les fichiers texte modifiés ou créés

Note explicite : le report n’est pas recopié intégralement dans lui-même pour éviter une récursion infinie. Tous les autres fichiers texte modifiés/créés dans ce scope 11B sont reproduits ci-dessous en entier.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/load_pokedex_species_detail_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../infrastructure/external/pokeapi_live_source.dart';
import '../../../infrastructure/external/showdown_snapshot_source.dart';
import '../../../infrastructure/repositories/http_pokemon_external_source_repository.dart';
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

final pokemonWriteRepositoryProvider = Provider<PokemonWriteRepository>((ref) {
  return const FilePokemonWriteRepository();
});

final pokemonExternalHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final pokeApiLiveSourceProvider = Provider<PokeApiLiveSource>((ref) {
  return PokeApiLiveSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final showdownSnapshotSourceProvider = Provider<ShowdownSnapshotSource>((ref) {
  return ShowdownSnapshotSource(
    client: ref.watch(pokemonExternalHttpClientProvider),
  );
});

final pokemonExternalSourceRepositoryProvider =
    Provider<PokemonExternalSourceRepository>((ref) {
  return HttpPokemonExternalSourceRepository(
    pokeApiSource: ref.watch(pokeApiLiveSourceProvider),
    showdownSource: ref.watch(showdownSnapshotSourceProvider),
  );
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

final pokedexListProvider = Provider<PokedexEntryLoader>((ref) {
  return ref.watch(pokedexEntryLoaderProvider);
});

final loadPokedexSpeciesDetailUseCaseProvider =
    Provider<LoadPokedexSpeciesDetailUseCase>((ref) {
  return LoadPokedexSpeciesDetailUseCase(
    ref.watch(pokemonReadRepositoryProvider),
  );
});

final deletePokedexSpeciesUseCaseProvider =
    Provider<DeletePokedexSpeciesUseCase>((ref) {
  return DeletePokedexSpeciesUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final pokedexSpeciesDeleterProvider = Provider<PokedexSpeciesDeleter>((ref) {
  final useCase = ref.watch(deletePokedexSpeciesUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final pokedexSpeciesDetailLoaderProvider =
    Provider<PokedexSpeciesDetailLoader>((ref) {
  final useCase = ref.watch(loadPokedexSpeciesDetailUseCaseProvider);
  return (workspace, speciesId) => useCase.execute(workspace, speciesId);
});

final importPokemonSpeciesJsonUseCaseProvider =
    Provider<ImportPokemonSpeciesJsonUseCase>((ref) {
  return ImportPokemonSpeciesJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonLearnsetJsonUseCaseProvider =
    Provider<ImportPokemonLearnsetJsonUseCase>((ref) {
  return ImportPokemonLearnsetJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonEvolutionJsonUseCaseProvider =
    Provider<ImportPokemonEvolutionJsonUseCase>((ref) {
  return ImportPokemonEvolutionJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonMediaJsonUseCaseProvider =
    Provider<ImportPokemonMediaJsonUseCase>((ref) {
  return ImportPokemonMediaJsonUseCase(
    ref.watch(pokemonWriteRepositoryProvider),
  );
});

final importPokemonJsonBundleUseCaseProvider =
    Provider<ImportPokemonJsonBundleUseCase>((ref) {
  return ImportPokemonJsonBundleUseCase(
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
    speciesImportUseCase: ref.watch(importPokemonSpeciesJsonUseCaseProvider),
    learnsetImportUseCase: ref.watch(importPokemonLearnsetJsonUseCaseProvider),
    evolutionImportUseCase:
        ref.watch(importPokemonEvolutionJsonUseCaseProvider),
    mediaImportUseCase: ref.watch(importPokemonMediaJsonUseCaseProvider),
  );
});

final pokedexImportPreviewerProvider = Provider<PokedexImportPreviewer>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.preview(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final pokedexImporterProvider = Provider<PokedexImporter>((ref) {
  final useCase = ref.watch(importPokemonJsonBundleUseCaseProvider);
  return (workspace, absoluteSpeciesSourcePath) => useCase.execute(
        workspace,
        absoluteSpeciesSourcePath: absoluteSpeciesSourcePath,
      );
});

final importExternalPokemonSpeciesUseCaseProvider =
    Provider<ImportExternalPokemonSpeciesUseCase>((ref) {
  return ImportExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final batchImportExternalPokemonSpeciesUseCaseProvider =
    Provider<BatchImportExternalPokemonSpeciesUseCase>((ref) {
  return BatchImportExternalPokemonSpeciesUseCase(
    ref.watch(importExternalPokemonSpeciesUseCaseProvider),
  );
});

final pokedexExternalImportPreviewerProvider =
    Provider<PokedexExternalImportPreviewer>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
        dryRun: true,
      );
});

final pokedexExternalImporterProvider =
    Provider<PokedexExternalImporter>((ref) {
  final useCase = ref.watch(importExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesQuery) => useCase.execute(
        workspace,
        speciesId: speciesQuery,
      );
});

final loadPokemonMovesCatalogUseCaseProvider =
    Provider<LoadPokemonMovesCatalogUseCase>((ref) {
  return LoadPokemonMovesCatalogUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
  );
});

final syncExternalPokemonMovesCatalogUseCaseProvider =
    Provider<SyncExternalPokemonMovesCatalogUseCase>((ref) {
  return SyncExternalPokemonMovesCatalogUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexMovesCatalogLoaderProvider =
    Provider<PokedexMovesCatalogLoader>((ref) {
  final useCase = ref.watch(loadPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
});

final pokedexMovesCatalogPreviewerProvider =
    Provider<PokedexMovesCatalogPreviewer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace, dryRun: true);
});

final pokedexMovesCatalogSyncerProvider =
    Provider<PokedexMovesCatalogSyncer>((ref) {
  final useCase = ref.watch(syncExternalPokemonMovesCatalogUseCaseProvider);
  return (workspace) => useCase.execute(workspace);
});

final updatePokedexSpeciesMetadataUseCaseProvider =
    Provider<UpdatePokedexSpeciesMetadataUseCase>((ref) {
  return UpdatePokedexSpeciesMetadataUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMetadataSaverProvider =
    Provider<PokedexSpeciesMetadataSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMetadataUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesFormsClassificationUseCaseProvider =
    Provider<UpdatePokedexSpeciesFormsClassificationUseCase>((ref) {
  return UpdatePokedexSpeciesFormsClassificationUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesFormsClassificationSaverProvider =
    Provider<PokedexSpeciesFormsClassificationSaver>((ref) {
  final useCase = ref.watch(
    updatePokedexSpeciesFormsClassificationUseCaseProvider,
  );
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesLearnsetUseCaseProvider =
    Provider<UpdatePokedexSpeciesLearnsetUseCase>((ref) {
  return UpdatePokedexSpeciesLearnsetUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesLearnsetSaverProvider =
    Provider<PokedexSpeciesLearnsetSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesLearnsetUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesEvolutionUseCaseProvider =
    Provider<UpdatePokedexSpeciesEvolutionUseCase>((ref) {
  return UpdatePokedexSpeciesEvolutionUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesEvolutionSaverProvider =
    Provider<PokedexSpeciesEvolutionSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesEvolutionUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

final updatePokedexSpeciesMediaUseCaseProvider =
    Provider<UpdatePokedexSpeciesMediaUseCase>((ref) {
  return UpdatePokedexSpeciesMediaUseCase(
    readRepository: ref.watch(pokemonReadRepositoryProvider),
    writeRepository: ref.watch(pokemonWriteRepositoryProvider),
  );
});

final pokedexSpeciesMediaSaverProvider =
    Provider<PokedexSpeciesMediaSaver>((ref) {
  final useCase = ref.watch(updatePokedexSpeciesMediaUseCaseProvider);
  return (workspace, request) => useCase.execute(workspace, request);
});

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart`

```dart
import 'dart:typed_data';

/// Frontière applicative unique pour lire les données Pokémon externes.
///
/// Cette abstraction reste volontairement concentrée sur le pipeline déjà en
/// place dans l'application :
/// - Showdown reste la source structurée complémentaire pour le core species ;
/// - PokeAPI reste la source live principale pour `pokemon`, `pokemon-species`
///   et `evolution-chain` ;
/// - les médias et cries sont aussi lus via cette même frontière pour éviter
///   de créer un second sous-système réseau à côté de l'import existant.
///
/// Important :
/// - on étend minimalement le port historique au lieu d'en créer un nouveau ;
/// - le use case garde ainsi une seule dépendance externe injectable ;
/// - l'UI ne voit jamais de client HTTP concret ni d'URL brutes.
abstract class PokemonExternalSourceRepository {
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId);

  /// Charge le snapshot global des moves depuis la source structurée
  /// complémentaire déjà utilisée par la 11A.
  ///
  /// Cette extension est volontairement minimale :
  /// - on n'introduit pas un second port "catalogue moves" parallèle ;
  /// - on réutilise la même frontière externe que l'import Pokémon 11A ;
  /// - l'orchestration 11B reste ainsi branchée sur le pipeline existant.
  ///
  /// Non-objectifs explicites :
  /// - aucun parsing dans l'UI ;
  /// - aucune logique de merge ici ;
  /// - aucune dépendance directe de l'application à l'URL Showdown.
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot();

  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(String speciesId);

  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  );

  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  );

  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl);
}

/// Payload binaire téléchargé depuis une source externe.
///
/// On garde ici juste le strict nécessaire pour réécrire l'asset localement :
/// - l'URL source réellement utilisée ;
/// - les bytes ;
/// - le content-type quand la réponse HTTP en expose un.
class PokemonExternalBinaryAsset {
  const PokemonExternalBinaryAsset({
    required this.sourceUrl,
    required this.bytes,
    this.contentType,
  });

  final String sourceUrl;
  final Uint8List bytes;
  final String? contentType;
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/services/showdown_move_catalog_converter.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';

/// Convertit `moves.json` de Pokémon Showdown vers le catalogue local `moves`.
///
/// Décision de phase 11B :
/// - Showdown est la source primaire retenue pour le bulk sync du catalogue,
///   car le snapshot expose déjà toutes les métadonnées structurées utiles ;
/// - PokeAPI a bien été auditée, mais n'est pas utilisée ici comme source
///   principale parce qu'elle imposerait une fan-out HTTP par move, hors du
///   scope minimal et raisonnable de cette phase ;
/// - on garde donc un import déterministe, compact et testable.
///
/// Invariants assumés :
/// - les ids locaux restent en `snake_case` pour rester cohérents avec les
///   learnsets déjà normalisés par le pipeline 11A ;
/// - seules les clés réellement utiles au catalogue local minimal sont mappées ;
/// - les champs non supportés localement sont ignorés au lieu d'être recopiés
///   aveuglément depuis la source externe.
class ShowdownMoveCatalogConverter {
  const ShowdownMoveCatalogConverter();

  /// Produit un [PokemonCatalogFile] local complet à partir du snapshot brut.
  ///
  /// Le catalogue de sortie reste volontairement simple :
  /// - `kind` et `catalog` suivent le contrat déjà stabilisé du repo ;
  /// - les entrées sont triées par `id` pour éviter les diffs parasites ;
  /// - la méta décrit explicitement la stratégie source retenue pour 11B.
  PokemonCatalogFile convert(Map<String, dynamic> snapshot) {
    if (snapshot.isEmpty) {
      throw const EditorValidationException(
        'Showdown moves snapshot cannot be empty',
      );
    }

    final entries = snapshot.entries
        .map(
          (snapshotEntry) => _convertEntry(
            rawId: snapshotEntry.key,
            rawEntry: snapshotEntry.value,
          ),
        )
        .toList(growable: false)
      ..sort(
        (left, right) => ((left['id'] as String?) ?? '').compareTo(
          (right['id'] as String?) ?? '',
        ),
      );

    return PokemonCatalogFile(
      schemaVersion: 1,
      kind: 'pokemon_catalog',
      catalog: 'moves',
      meta: const PokemonDataMeta(
        description:
            'Moves catalog synchronized from the Pokémon Showdown moves snapshot.',
        sourcePriority: <String>['showdown', 'local_merge'],
        notes: <String>[
          'Phase 11B keeps Showdown as the primary bulk source for local moves.',
          'PokeAPI move payloads were audited but not selected for bulk sync.',
          'Move ids are normalized to snake_case to stay consistent with learnsets.',
        ],
      ),
      entries: entries,
    );
  }

  Map<String, dynamic> _convertEntry({
    required String rawId,
    required Object? rawEntry,
  }) {
    if (rawEntry is! Map) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" must be an object',
      );
    }

    final entry = rawEntry.cast<String, dynamic>();
    final displayName = _readDisplayName(rawId, entry);
    final localId = _normalizeSnakeCaseId(displayName);
    if (localId.isEmpty) {
      throw EditorPersistenceException(
        'Showdown move entry "$rawId" does not expose a usable local id',
      );
    }

    final type = _readLowerCaseString(entry['type']);
    final category = _readLowerCaseString(entry['category']);
    final target = _readLowerCaseString(entry['target']);
    final generation = _readOptionalInt(entry['gen']);
    final pp = _readOptionalInt(entry['pp']);
    final priority = _readOptionalInt(entry['priority']) ?? 0;
    final power = _readOptionalPower(entry['basePower']);
    final accuracy = _readOptionalNumericAccuracy(entry['accuracy']);
    final accuracyText = _readAccuracyText(entry['accuracy']);
    final shortDesc = _readTrimmedString(entry['shortDesc']);
    final description = _readTrimmedString(entry['desc']);

    return <String, dynamic>{
      'id': localId,
      'name': displayName,
      'names': <String, String>{'en': displayName},
      if (type != null) 'type': type,
      if (category != null) 'category': category,
      'power': power,
      'accuracy': accuracy,
      if (accuracyText != null) 'accuracyText': accuracyText,
      if (pp != null) 'pp': pp,
      'priority': priority,
      if (target != null) 'target': target,
      if (shortDesc != null) 'shortDesc': shortDesc,
      if (description != null) 'description': description,
      if (generation != null) 'generation': generation,
    };
  }

  String _readDisplayName(String rawId, Map<String, dynamic> entry) {
    final explicitName = _readTrimmedString(entry['name']);
    if (explicitName != null && explicitName.isNotEmpty) {
      return explicitName;
    }
    return _humanizeIdentifier(rawId);
  }

  String? _readLowerCaseString(Object? rawValue) {
    final value = _readTrimmedString(rawValue);
    if (value == null || value.isEmpty) {
      return null;
    }
    return value.toLowerCase();
  }

  String? _readTrimmedString(Object? rawValue) {
    final value = rawValue as String?;
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  int? _readOptionalInt(Object? rawValue) {
    return (rawValue as num?)?.toInt();
  }

  int? _readOptionalPower(Object? rawValue) {
    final value = (rawValue as num?)?.toInt();
    if (value == null || value <= 0) {
      return null;
    }
    return value;
  }

  num? _readOptionalNumericAccuracy(Object? rawValue) {
    // Showdown encode certains moves "always hit" avec `true`. Le modèle local
    // minimal de 11B ne cherche pas à sur-typer tous les cas spéciaux : on
    // garde alors la valeur numérique quand elle existe, sinon on laisse
    // `accuracy` à null et on expose éventuellement un `accuracyText`.
    if (rawValue is num) {
      return rawValue;
    }
    return null;
  }

  String? _readAccuracyText(Object? rawValue) {
    if (rawValue == true) {
      return 'always';
    }
    if (rawValue is String && rawValue.trim().isNotEmpty) {
      return rawValue.trim().toLowerCase();
    }
    return null;
  }

  String _normalizeSnakeCaseId(String rawValue) {
    final lowerCase = rawValue.trim().toLowerCase();
    if (lowerCase.isEmpty) {
      return '';
    }

    final separated = lowerCase.replaceAll(RegExp(r'[\s-]+'), '_');
    final asciiSafe = separated.replaceAll(RegExp(r'[^a-z0-9_]+'), '');
    final collapsed = asciiSafe.replaceAll(RegExp(r'_+'), '_');
    return collapsed.replaceAll(RegExp(r'^_|_$'), '');
  }

  String _humanizeIdentifier(String rawId) {
    final prepared = rawId
        .trim()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAllMapped(
          RegExp(r'([a-z0-9])([A-Z])'),
          (match) => '${match.group(1)} ${match.group(2)}',
        )
        .trim();

    if (prepared.isEmpty) {
      return rawId;
    }

    return prepared
        .split(RegExp(r'\s+'))
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1).toLowerCase()}',
        )
        .join(' ');
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart`

```dart
import 'dart:convert';

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
    this.generation,
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
  final int? generation;

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
  });

  final List<PokemonMoveCatalogEntryView> entries;
  final bool isAvailable;
  final String description;
  final String? message;
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
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      return PokemonMovesCatalogView(
        entries: _projectEntries(catalog),
        isAvailable: true,
        description: catalog.meta.description.trim().isEmpty
            ? 'Catalogue local des attaques.'
            : catalog.meta.description.trim(),
      );
    } on EditorNotFoundException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques indisponible.',
        message: error.message,
      );
    } on EditorApplicationException catch (error) {
      return PokemonMovesCatalogView(
        entries: const <PokemonMoveCatalogEntryView>[],
        isAvailable: false,
        description: 'Catalogue local des attaques illisible.',
        message: error.message,
      );
    }
  }

  List<PokemonMoveCatalogEntryView> _projectEntries(
      PokemonCatalogFile catalog) {
    final entries = catalog.entries
        .map(_projectEntry)
        .whereType<PokemonMoveCatalogEntryView>()
        .toList(growable: false)
      ..sort((left, right) {
        final nameCompare = left.name.compareTo(right.name);
        if (nameCompare != 0) {
          return nameCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  PokemonMoveCatalogEntryView? _projectEntry(Map<String, dynamic> entry) {
    final id = (entry['id'] as String?)?.trim() ?? '';
    if (id.isEmpty) {
      return null;
    }

    final explicitName = (entry['name'] as String?)?.trim();
    final localizedNames = (entry['names'] as Map?)?.cast<String, dynamic>();
    final fallbackName = (localizedNames?['en'] as String?)?.trim();
    final name =
        explicitName?.isNotEmpty == true ? explicitName! : fallbackName;

    return PokemonMoveCatalogEntryView(
      id: id,
      name: name?.isNotEmpty == true ? name! : id,
      type: (entry['type'] as String?)?.trim(),
      category: (entry['category'] as String?)?.trim(),
      power: (entry['power'] as num?)?.toInt(),
      accuracy: entry['accuracy'] as num?,
      accuracyText: (entry['accuracyText'] as String?)?.trim(),
      pp: (entry['pp'] as num?)?.toInt(),
      priority: (entry['priority'] as num?)?.toInt(),
      target: (entry['target'] as String?)?.trim(),
      shortDesc: (entry['shortDesc'] as String?)?.trim(),
      generation: (entry['generation'] as num?)?.toInt(),
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

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/update_pokedex_species_learnset_use_case.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_project_data_models.dart';
import '../ports/pokemon_read_repository.dart';
import '../ports/pokemon_write_repository.dart';
import '../ports/project_workspace.dart';

/// Surface d'édition locale du lot 41.
///
/// Le but est d'éditer le learnset déjà modélisé par le projet, pas d'inventer
/// une nouvelle notion "d'autorisation" parallèle.
class UpdatePokedexSpeciesLearnsetRequest {
  const UpdatePokedexSpeciesLearnsetRequest({
    required this.speciesId,
    required this.startingMoves,
    required this.relearnMoves,
    required this.levelUp,
    required this.tm,
    required this.tutor,
    required this.egg,
    required this.event,
    required this.transfer,
  });

  final String speciesId;
  final List<String> startingMoves;
  final List<String> relearnMoves;
  final List<PokemonLearnsetLevelUpEntry> levelUp;
  final List<PokemonLearnsetMoveEntry> tm;
  final List<PokemonLearnsetMoveEntry> tutor;
  final List<PokemonLearnsetMoveEntry> egg;
  final List<PokemonLearnsetMoveEntry> event;
  final List<PokemonLearnsetMoveEntry> transfer;
}

typedef PokedexSpeciesLearnsetSaver = Future<PokemonLearnsetFile> Function(
  ProjectWorkspace workspace,
  UpdatePokedexSpeciesLearnsetRequest request,
);

/// Réécrit le learnset local d'une espèce via le repository existant.
///
/// Le use case :
/// - relit l'espèce pour respecter sa ref learnset existante ;
/// - autorise la création du fichier learnset s'il n'existe pas encore ;
/// - applique une validation structurelle locale symétrique au lot 24 ;
/// - s'appuie sur le catalogue local `moves` quand il existe réellement ;
/// - n'écrit jamais ailleurs qu'au chemin déjà contractuel du repository.
class UpdatePokedexSpeciesLearnsetUseCase {
  const UpdatePokedexSpeciesLearnsetUseCase({
    required this.readRepository,
    required this.writeRepository,
  });

  final PokemonReadRepository readRepository;
  final PokemonWriteRepository writeRepository;

  Future<PokemonLearnsetFile> execute(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    final speciesId = request.speciesId.trim();
    if (speciesId.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species id cannot be empty',
      );
    }

    final currentSpecies = await readRepository.readSpeciesById(
      workspace,
      speciesId,
    );
    final learnsetRef = currentSpecies.refs.learnset.trim();
    if (learnsetRef.isEmpty) {
      throw const EditorValidationException(
        'Pokemon species learnset ref cannot be empty',
      );
    }

    final learnset = PokemonLearnsetFile(
      speciesId: learnsetRef,
      startingMoves: _normalizeMoveIds(request.startingMoves),
      relearnMoves: _normalizeMoveIds(request.relearnMoves),
      levelUp: _normalizeLevelUpEntries(request.levelUp),
      tm: _normalizeMoveEntries(request.tm),
      tutor: _normalizeMoveEntries(request.tutor),
      egg: _normalizeMoveEntries(request.egg),
      event: _normalizeMoveEntries(request.event),
      transfer: _normalizeMoveEntries(request.transfer),
    );

    _validateLearnset(learnset);
    await _validateAgainstLocalMovesCatalogIfAvailable(workspace, learnset);
    await writeRepository.saveLearnset(workspace, learnset);
    return learnset;
  }

  Future<void> _validateAgainstLocalMovesCatalogIfAvailable(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) async {
    // Intégration minimale utile de la 11B :
    // - si un vrai catalogue local des attaques est disponible, on l'utilise
    //   comme garde-fou avant d'écrire le learnset ;
    // - si le catalogue est absent ou illisible, on n'empêche pas l'édition,
    //   car la 11B ne doit pas transformer un problème de stockage global en
    //   blocage absolu de l'onglet Learnset.
    //
    // Cette règle garde l'éditeur utile dans un workspace partiellement
    // préparé, tout en apportant enfin une validation réellement exploitable
    // dès que le catalogue local existe.
    final availableMoveIds = await _readAvailableMoveIdsIfPossible(workspace);
    if (availableMoveIds == null || availableMoveIds.isEmpty) {
      return;
    }

    final missingMoveIds = _collectUsedMoveIds(learnset)
        .where((moveId) => !availableMoveIds.contains(moveId))
        .toList(growable: false)
      ..sort();
    if (missingMoveIds.isEmpty) {
      return;
    }

    throw EditorValidationException(
      'Pokemon learnset references moves absent from the local moves catalog: '
      '${missingMoveIds.join(', ')}. Synchronisez le catalogue local des '
      'attaques ou corrigez les move ids.',
    );
  }

  Future<Set<String>?> _readAvailableMoveIdsIfPossible(
    ProjectWorkspace workspace,
  ) async {
    try {
      final catalog = await readRepository.readCatalogByKey(workspace, 'moves');
      return catalog.entries
          .map((entry) => (entry['id'] as String?)?.trim() ?? '')
          .where((value) => value.isNotEmpty)
          .toSet();
    } on EditorApplicationException {
      // Non-objectif explicite :
      // on ne convertit pas ce use case local en validateur global de
      // catalogue. Les erreurs de lecture du catalogue restent traitées par
      // le validateur projet et par la surface 11B dédiée au sync.
      return null;
    }
  }

  Set<String> _collectUsedMoveIds(PokemonLearnsetFile learnset) {
    return <String>{
      ...learnset.startingMoves,
      ...learnset.relearnMoves,
      ...learnset.levelUp.map((entry) => entry.moveId),
      ...learnset.tm.map((entry) => entry.moveId),
      ...learnset.tutor.map((entry) => entry.moveId),
      ...learnset.egg.map((entry) => entry.moveId),
      ...learnset.event.map((entry) => entry.moveId),
      ...learnset.transfer.map((entry) => entry.moveId),
    }.map((value) => value.trim()).where((value) => value.isNotEmpty).toSet();
  }

  List<String> _normalizeMoveIds(List<String> values) {
    final normalized = <String>[];
    final seen = <String>{};
    for (final rawValue in values) {
      final value = rawValue.trim();
      if (value.isEmpty || !seen.add(value)) {
        continue;
      }
      normalized.add(value);
    }
    return normalized;
  }

  List<PokemonLearnsetLevelUpEntry> _normalizeLevelUpEntries(
    List<PokemonLearnsetLevelUpEntry> values,
  ) {
    return values
        .map(
          (entry) => PokemonLearnsetLevelUpEntry(
            moveId: entry.moveId.trim(),
            level: entry.level,
            source: entry.source.trim(),
            versionGroup: entry.versionGroup.trim(),
          ),
        )
        .toList(growable: false);
  }

  List<PokemonLearnsetMoveEntry> _normalizeMoveEntries(
    List<PokemonLearnsetMoveEntry> values,
  ) {
    return values
        .map(
          (entry) => PokemonLearnsetMoveEntry(
            moveId: entry.moveId.trim(),
            versionGroup: entry.versionGroup.trim(),
          ),
        )
        .toList(growable: false);
  }

  void _validateLearnset(PokemonLearnsetFile learnset) {
    if (learnset.speciesId.trim().isEmpty) {
      throw const EditorValidationException(
        'Pokemon learnset speciesId cannot be empty',
      );
    }

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
        'Pokemon learnset must contain at least one move section',
      );
    }

    for (final moveId in learnset.startingMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset startingMoves cannot contain empty move ids',
        );
      }
    }

    for (final moveId in learnset.relearnMoves) {
      if (moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset relearnMoves cannot contain empty move ids',
        );
      }
    }

    for (final entry in learnset.levelUp) {
      if (entry.moveId.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp moveId cannot be empty',
        );
      }
      if (entry.level <= 0) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp level must be positive',
        );
      }
      if (entry.source.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp source cannot be empty',
        );
      }
      if (entry.versionGroup.trim().isEmpty) {
        throw const EditorValidationException(
          'Pokemon learnset levelUp versionGroup cannot be empty',
        );
      }
    }

    void validateMoveEntries(
      List<PokemonLearnsetMoveEntry> entries,
      String label,
    ) {
      for (final entry in entries) {
        if (entry.moveId.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label moveId cannot be empty',
          );
        }
        if (entry.versionGroup.trim().isEmpty) {
          throw EditorValidationException(
            'Pokemon learnset $label versionGroup cannot be empty',
          );
        }
      }
    }

    validateMoveEntries(learnset.tm, 'tm');
    validateMoveEntries(learnset.tutor, 'tutor');
    validateMoveEntries(learnset.egg, 'egg');
    validateMoveEntries(learnset.event, 'event');
    validateMoveEntries(learnset.transfer, 'transfer');
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/use_cases.dart`

```dart
export 'character_use_cases.dart';
export 'collision_use_cases.dart';
export 'delete_pokedex_species_use_case.dart';
export 'encounter_table_use_cases.dart';
export 'trainer_use_cases.dart';
export 'gameplay_zone_use_cases.dart';
export 'initialize_pokemon_project_storage_use_case.dart';
export 'import_pokemon_catalog_json_use_case.dart';
export 'import_pokemon_evolution_json_use_case.dart';
export 'import_pokemon_json_bundle_use_case.dart';
export 'import_external_pokemon_use_cases.dart';
export 'import_pokemon_learnset_json_use_case.dart';
export 'import_pokemon_media_json_use_case.dart';
export 'import_pokemon_species_json_use_case.dart';
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
export 'sync_pokemon_moves_catalog_use_case.dart';
export 'terrain_preset_use_cases.dart';
export 'terrain_use_cases.dart';
export 'update_pokedex_species_evolution_use_case.dart';
export 'update_pokedex_species_forms_classification_use_case.dart';
export 'update_pokedex_species_learnset_use_case.dart';
export 'update_pokedex_species_metadata_use_case.dart';
export 'update_pokedex_species_media_use_case.dart';
export 'validate_pokemon_project_data_use_case.dart';
export 'warp_use_cases.dart';

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart`

```dart
import '../../application/ports/pokemon_external_source_repository.dart';
import '../external/pokeapi_live_source.dart';
import '../external/showdown_snapshot_source.dart';

/// Implémentation concrète du port externe déjà existant.
///
/// Cette classe est volontairement mince :
/// - elle compose l'adaptateur PokeAPI live et l'adaptateur Showdown snapshot ;
/// - elle ne convertit aucun payload ;
/// - elle expose au use case une façade unique pour éviter toute stack
///   d'import parallèle dans l'application.
class HttpPokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  const HttpPokemonExternalSourceRepository({
    required this.pokeApiSource,
    required this.showdownSource,
  });

  final PokeApiLiveSource pokeApiSource;
  final ShowdownSnapshotSource showdownSource;

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) {
    return showdownSource.fetchSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    return showdownSource.fetchMovesSnapshot();
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchPokemon(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchPokemonSpecies(speciesId);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) {
    return pokeApiSource.fetchEvolutionChainForSpecies(speciesId);
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) {
    return pokeApiSource.fetchBinaryAsset(sourceUrl);
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_common_widgets.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Widgets de présentation transverses à plusieurs onglets.
//
// On mutualise uniquement la couche visuelle commune : cartes de section,
// lignes propriété/valeur, chips simples et messages d'absence de données.

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
    super.key,
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

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_detail_panel.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Colonne droite du workspace Pokédex.
//
// Cette zone reste en lecture ou édition locale selon l'onglet actif. Elle ne
// décide jamais du contenu métier ; elle reflète uniquement la sélection et les
// loaders déjà résolus par le workspace principal.

class PokedexWorkspaceDetailPane extends StatelessWidget {
  const PokedexWorkspaceDetailPane({
    super.key,
    required this.selectedEntry,
    required this.selectedTabId,
    required this.onTabChanged,
    required this.detailFuture,
    required this.onDeleteSpecies,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
    required this.onLoadMovesCatalog,
    required this.onPreviewMovesCatalogSync,
    required this.onSyncMovesCatalog,
  });

  final PokemonDatabaseIndexEntry? selectedEntry;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<PokedexSpeciesDetail>? detailFuture;
  final Future<void> Function(PokemonDatabaseIndexEntry entry) onDeleteSpecies;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;
  final Future<PokemonMovesCatalogView> Function() onLoadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      onPreviewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() onSyncMovesCatalog;

  @override
  Widget build(BuildContext context) {
    final entry = selectedEntry;
    if (entry == null || detailFuture == null) {
      return const PokedexWorkspaceStateCard(
        key: Key('pokedex-detail-empty-state'),
        title: 'Fiche espèce',
        message:
            'Sélectionnez une espèce dans la liste pour voir sa fiche, ses formes, son learnset, ses évolutions et ses médias.',
      );
    }

    return FutureBuilder<PokedexSpeciesDetail>(
      future: detailFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const PokedexWorkspaceStateCard(
            key: Key('pokedex-detail-loading-state'),
            title: 'Fiche espèce',
            message: 'Chargement de la fiche Pokédex…',
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
            message: 'Impossible de charger la fiche de ${entry.id}.\n$message',
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
          onDeleteSpecies: onDeleteSpecies,
          onSaveMetadata: onSaveMetadata,
          onSaveFormsClassification: onSaveFormsClassification,
          onSaveLearnset: onSaveLearnset,
          onSaveEvolution: onSaveEvolution,
          onSaveMedia: onSaveMedia,
          onLoadMovesCatalog: onLoadMovesCatalog,
          onPreviewMovesCatalogSync: onPreviewMovesCatalogSync,
          onSyncMovesCatalog: onSyncMovesCatalog,
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
    required this.onDeleteSpecies,
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
    required this.onLoadMovesCatalog,
    required this.onPreviewMovesCatalogSync,
    required this.onSyncMovesCatalog,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final ValueChanged<String> onTabChanged;
  final Future<void> Function(PokemonDatabaseIndexEntry entry) onDeleteSpecies;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;
  final Future<PokemonMovesCatalogView> Function() onLoadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      onPreviewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() onSyncMovesCatalog;

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                // Le bouton de suppression vit dans l'en-tête de la fiche
                // parce que l'action s'applique à l'espèce sélectionnée entière,
                // pas seulement à un onglet particulier.
                //
                // On le garde volontairement simple :
                // - pas de menu contextuel ;
                // - pas de second flux de suppression dans la liste ;
                // - confirmation obligatoire gérée au niveau du workspace.
                PushButton(
                  key: const Key('pokedex-delete-species-button'),
                  controlSize: ControlSize.large,
                  color: CupertinoColors.systemRed.resolveFrom(context),
                  onPressed: () => onDeleteSpecies(entry),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _PokedexStatusChip(
                  label: entry.isEnabledInProject ? 'Activée' : 'Désactivée',
                  isEnabled: entry.isEnabledInProject,
                ),
                ...entry.types.map((type) => _PokedexTypeChip(label: type)),
              ],
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
                  child: Text('Fiche'),
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
                onSaveMetadata: onSaveMetadata,
                onSaveFormsClassification: onSaveFormsClassification,
                onSaveLearnset: onSaveLearnset,
                onSaveEvolution: onSaveEvolution,
                onSaveMedia: onSaveMedia,
                onLoadMovesCatalog: onLoadMovesCatalog,
                onPreviewMovesCatalogSync: onPreviewMovesCatalogSync,
                onSyncMovesCatalog: onSyncMovesCatalog,
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
    required this.onSaveMetadata,
    required this.onSaveFormsClassification,
    required this.onSaveLearnset,
    required this.onSaveEvolution,
    required this.onSaveMedia,
    required this.onLoadMovesCatalog,
    required this.onPreviewMovesCatalogSync,
    required this.onSyncMovesCatalog,
  });

  final PokemonDatabaseIndexEntry entry;
  final PokedexSpeciesDetail detail;
  final String selectedTabId;
  final Future<void> Function(UpdatePokedexSpeciesMetadataRequest request)
      onSaveMetadata;
  final Future<void> Function(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) onSaveFormsClassification;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSaveLearnset;
  final Future<void> Function(UpdatePokedexSpeciesEvolutionRequest request)
      onSaveEvolution;
  final Future<void> Function(UpdatePokedexSpeciesMediaRequest request)
      onSaveMedia;
  final Future<PokemonMovesCatalogView> Function() onLoadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      onPreviewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() onSyncMovesCatalog;

  @override
  Widget build(BuildContext context) {
    return switch (selectedTabId) {
      'forms' => _PokedexFormsTab(
          detail: detail,
          onSave: onSaveFormsClassification,
        ),
      'learnset' => _PokedexLearnsetTab(
          detail: detail,
          onSave: onSaveLearnset,
          loadMovesCatalog: onLoadMovesCatalog,
          previewMovesCatalogSync: onPreviewMovesCatalogSync,
          syncMovesCatalog: onSyncMovesCatalog,
        ),
      'evolutions' => _PokedexEvolutionTab(
          detail: detail,
          onSave: onSaveEvolution,
        ),
      'media' => _PokedexMediaTab(
          detail: detail,
          onSave: onSaveMedia,
        ),
      _ => _PokedexOverviewTab(
          entry: entry,
          detail: detail,
          onSaveMetadata: onSaveMetadata,
        ),
    };
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_learnset_panel.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Onglet Learnset.
//
// Cette vue expose les sections déjà supportées par l'application sans modifier
// le contrat métier. L'objectif de ce réalignement est de rendre l'écran plus
// facile à relire et à maintenir, pas de changer la logique d'édition.

class _PokedexLearnsetTab extends StatefulWidget {
  const _PokedexLearnsetTab({
    required this.detail,
    required this.onSave,
    required this.loadMovesCatalog,
    required this.previewMovesCatalogSync,
    required this.syncMovesCatalog,
  });

  final PokedexSpeciesDetail detail;
  final Future<void> Function(UpdatePokedexSpeciesLearnsetRequest request)
      onSave;
  final Future<PokemonMovesCatalogView> Function() loadMovesCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function()
      previewMovesCatalogSync;
  final Future<PokemonMovesCatalogSyncResult> Function() syncMovesCatalog;

  @override
  State<_PokedexLearnsetTab> createState() => _PokedexLearnsetTabState();
}

class _PokedexLearnsetTabState extends State<_PokedexLearnsetTab> {
  late final TextEditingController _startingMovesController;
  late final TextEditingController _relearnMovesController;
  late final TextEditingController _levelUpController;
  late final TextEditingController _tmController;
  late final TextEditingController _tutorController;
  late final TextEditingController _eggController;
  late final TextEditingController _eventController;
  late final TextEditingController _transferController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _saveErrorMessage;

  @override
  void initState() {
    super.initState();
    _startingMovesController = TextEditingController();
    _relearnMovesController = TextEditingController();
    _levelUpController = TextEditingController();
    _tmController = TextEditingController();
    _tutorController = TextEditingController();
    _eggController = TextEditingController();
    _eventController = TextEditingController();
    _transferController = TextEditingController();
    _replaceDraftFromDetail(widget.detail);
  }

  @override
  void didUpdateWidget(covariant _PokedexLearnsetTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.detail != widget.detail) {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    }
  }

  @override
  void dispose() {
    _startingMovesController.dispose();
    _relearnMovesController.dispose();
    _levelUpController.dispose();
    _tmController.dispose();
    _tutorController.dispose();
    _eggController.dispose();
    _eventController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  void _replaceDraftFromDetail(PokedexSpeciesDetail detail) {
    final learnset = detail.learnset;
    _startingMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.startingMoves);
    _relearnMovesController.text =
        learnset == null ? '' : _formatLineList(learnset.relearnMoves);
    _levelUpController.text =
        learnset == null ? '' : _formatLearnsetLevelUpEntries(learnset.levelUp);
    _tmController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tm);
    _tutorController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.tutor);
    _eggController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.egg);
    _eventController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.event);
    _transferController.text =
        learnset == null ? '' : _formatLearnsetMoveEntries(learnset.transfer);
  }

  Future<void> _saveDraft() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
      _saveErrorMessage = null;
    });

    try {
      await widget.onSave(
        UpdatePokedexSpeciesLearnsetRequest(
          speciesId: widget.detail.species.id,
          startingMoves: _splitNonEmptyLines(_startingMovesController.text),
          relearnMoves: _splitNonEmptyLines(_relearnMovesController.text),
          levelUp: _parseLearnsetLevelUpEntries(_levelUpController.text),
          tm: _parseLearnsetMoveEntries(_tmController.text, label: 'tm'),
          tutor: _parseLearnsetMoveEntries(
            _tutorController.text,
            label: 'tutor',
          ),
          egg: _parseLearnsetMoveEntries(_eggController.text, label: 'egg'),
          event: _parseLearnsetMoveEntries(
            _eventController.text,
            label: 'event',
          ),
          transfer: _parseLearnsetMoveEntries(
            _transferController.text,
            label: 'transfer',
          ),
        ),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _isEditing = false;
        _isSaving = false;
        _saveErrorMessage = null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      final message = switch (error) {
        final EditorApplicationException applicationError =>
          applicationError.message,
        _ => error.toString(),
      };
      setState(() {
        _isSaving = false;
        _saveErrorMessage = message;
      });
    }
  }

  void _cancelEditing() {
    setState(() {
      _replaceDraftFromDetail(widget.detail);
      _isEditing = false;
      _isSaving = false;
      _saveErrorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final learnset = widget.detail.learnset;
    final learnsetRef = widget.detail.species.refs.learnset.trim();

    return SingleChildScrollView(
      key: const Key('pokedex-learnset-tab'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PokedexMovesCatalogSection(
            loadCatalog: widget.loadMovesCatalog,
            previewSync: widget.previewMovesCatalogSync,
            syncCatalog: widget.syncMovesCatalog,
          ),
          const SizedBox(height: 12),
          if (_isEditing) ...[
            _PokedexLearnsetEditSection(
              learnsetRef: learnsetRef,
              isSaving: _isSaving,
              saveErrorMessage: _saveErrorMessage,
              startingMovesController: _startingMovesController,
              relearnMovesController: _relearnMovesController,
              levelUpController: _levelUpController,
              tmController: _tmController,
              tutorController: _tutorController,
              eggController: _eggController,
              eventController: _eventController,
              transferController: _transferController,
              onSave: _saveDraft,
              onCancel: _cancelEditing,
            ),
          ] else ...[
            _PokedexLearnsetReadOnlySection(
              learnset: learnset,
              learnsetRef: learnsetRef,
              onEditRequested: learnsetRef.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _replaceDraftFromDetail(widget.detail);
                        _isEditing = true;
                        _saveErrorMessage = null;
                      });
                    },
            ),
          ],
        ],
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_moves_catalog_section.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Bloc minimal "catalogue local des attaques" pour l'onglet Learnset.
//
// Décision UI de la 11B :
// - on n'ouvre pas un nouveau workspace "Move Library" autonome ;
// - on ajoute la plus petite surface honnête là où le besoin produit existe
//   déjà : l'édition et la lecture du learnset ;
// - le bloc reste purement consommateur d'état applicatif injecté.
//
// Ce composant permet donc :
// - de voir si le catalogue local existe et combien d'entrées il contient ;
// - de prévisualiser un sync externe avant écriture ;
// - de lancer réellement le sync ;
// - de rechercher rapidement des ids/noms/types déjà importés.
class _PokedexMovesCatalogSection extends StatefulWidget {
  const _PokedexMovesCatalogSection({
    required this.loadCatalog,
    required this.previewSync,
    required this.syncCatalog,
  });

  final Future<PokemonMovesCatalogView> Function() loadCatalog;
  final Future<PokemonMovesCatalogSyncResult> Function() previewSync;
  final Future<PokemonMovesCatalogSyncResult> Function() syncCatalog;

  @override
  State<_PokedexMovesCatalogSection> createState() =>
      _PokedexMovesCatalogSectionState();
}

class _PokedexMovesCatalogSectionState
    extends State<_PokedexMovesCatalogSection> {
  late final TextEditingController _searchController;
  late Future<PokemonMovesCatalogView> _catalogFuture;
  PokemonMovesCatalogSyncResult? _lastSyncReport;
  String? _operationError;
  bool _isPreviewing = false;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController()..addListener(_onSearchChanged);
    _catalogFuture = widget.loadCatalog();
  }

  @override
  void didUpdateWidget(covariant _PokedexMovesCatalogSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.loadCatalog != widget.loadCatalog ||
        oldWidget.previewSync != widget.previewSync ||
        oldWidget.syncCatalog != widget.syncCatalog) {
      _catalogFuture = widget.loadCatalog();
      _lastSyncReport = null;
      _operationError = null;
    }
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_onSearchChanged)
      ..dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
  }

  Future<void> _runPreview() async {
    if (_isPreviewing || _isSyncing) {
      return;
    }

    setState(() {
      _isPreviewing = true;
      _operationError = null;
    });

    try {
      final report = await widget.previewSync();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSyncReport = report;
        _isPreviewing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPreviewing = false;
        _operationError = _formatOperationError(error);
      });
    }
  }

  Future<void> _runSync() async {
    if (_isPreviewing || _isSyncing) {
      return;
    }

    setState(() {
      _isSyncing = true;
      _operationError = null;
    });

    try {
      final report = await widget.syncCatalog();
      if (!mounted) {
        return;
      }
      setState(() {
        _lastSyncReport = report;
        _catalogFuture = widget.loadCatalog();
        _isSyncing = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isSyncing = false;
        _operationError = _formatOperationError(error);
      });
    }
  }

  String _formatOperationError(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return _PokedexDetailSectionCard(
      title: 'Catalogue local des attaques',
      key: const Key('pokedex-moves-catalog-section'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cette surface 11B reste volontairement minimale : elle synchronise '
            'le catalogue local des moves, le rend consultable, puis laisse '
            'le learnset consommer cette source de vérité locale.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              CupertinoButton.filled(
                key: const Key('pokedex-moves-catalog-preview-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: (_isPreviewing || _isSyncing) ? null : _runPreview,
                child: Text(
                  _isPreviewing ? 'Prévisualisation…' : 'Prévisualiser sync',
                ),
              ),
              CupertinoButton(
                key: const Key('pokedex-moves-catalog-sync-button'),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                onPressed: (_isPreviewing || _isSyncing) ? null : _runSync,
                child: Text(_isSyncing ? 'Synchronisation…' : 'Synchroniser'),
              ),
            ],
          ),
          if (_lastSyncReport != null) ...[
            const SizedBox(height: 12),
            _PokedexMoveCatalogSyncSummary(report: _lastSyncReport!),
          ],
          if (_operationError != null) ...[
            const SizedBox(height: 12),
            Text(
              _operationError!,
              key: const Key('pokedex-moves-catalog-error'),
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 12),
          FutureBuilder<PokemonMovesCatalogView>(
            future: _catalogFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Text(
                    'Chargement du catalogue local des attaques…');
              }

              if (snapshot.hasError) {
                final message = _formatOperationError(
                  snapshot.error ?? 'Erreur inconnue',
                );
                return Text(
                  message,
                  key: const Key('pokedex-moves-catalog-load-error'),
                  style: const TextStyle(
                    color: EditorChrome.inspectorJoyCoral,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                );
              }

              final view = snapshot.data ??
                  const PokemonMovesCatalogView(
                    entries: <PokemonMoveCatalogEntryView>[],
                    isAvailable: false,
                    description: 'Catalogue local indisponible.',
                  );
              final filteredEntries = _filterEntries(view.entries);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    view.description,
                    key: const Key('pokedex-moves-catalog-description'),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    view.isAvailable
                        ? 'Attaques locales : ${view.entries.length}'
                        : 'Catalogue indisponible',
                    key: const Key('pokedex-moves-catalog-count'),
                    style: TextStyle(
                      color: EditorChrome.primaryLabel(context),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (view.message != null) ...[
                    const SizedBox(height: 6),
                    Text(view.message!),
                  ],
                  const SizedBox(height: 10),
                  CupertinoTextField(
                    key: const Key('pokedex-moves-catalog-search-field'),
                    controller: _searchController,
                    placeholder: 'Rechercher une attaque locale',
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (view.entries.isEmpty)
                    const Text(
                      'Aucune attaque locale importée pour le moment. '
                      'Utilisez la synchronisation externe pour alimenter le catalogue.',
                    )
                  else if (filteredEntries.isEmpty)
                    const Text(
                      'Aucune attaque ne correspond à la recherche actuelle.',
                    )
                  else
                    Container(
                      key: const Key('pokedex-moves-catalog-list'),
                      constraints: const BoxConstraints(maxHeight: 220),
                      child: ListView.separated(
                        shrinkWrap: true,
                        itemCount: filteredEntries.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final entry = filteredEntries[index];
                          return _PokedexMoveCatalogRow(entry: entry);
                        },
                      ),
                    ),
                  if (view.entries.length > filteredEntries.length &&
                      filteredEntries.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Affichage limité à ${filteredEntries.length} résultats pour garder l’onglet lisible.',
                    ),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  List<PokemonMoveCatalogEntryView> _filterEntries(
    List<PokemonMoveCatalogEntryView> entries,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final filtered = query.isEmpty
        ? entries
        : entries.where((entry) {
            final haystack = <String>[
              entry.id,
              entry.name,
              entry.type ?? '',
              entry.category ?? '',
              entry.shortDesc ?? '',
            ].join(' ').toLowerCase();
            return haystack.contains(query);
          }).toList(growable: false);
    return filtered.take(12).toList(growable: false);
  }
}

class _PokedexMoveCatalogSyncSummary extends StatelessWidget {
  const _PokedexMoveCatalogSyncSummary({
    required this.report,
  });

  final PokemonMovesCatalogSyncResult report;

  @override
  Widget build(BuildContext context) {
    final label =
        report.dryRun ? 'Prévisualisation' : 'Dernière synchronisation';
    final lines = <String>[
      '$label : ${report.externalEntryCount} moves externes analysés.',
      'Créées : ${report.createdCount}.',
      'Mises à jour : ${report.updatedCount}.',
      'Inchangées : ${report.unchangedCount}.',
      'Locales conservées : ${report.preservedLocalOnlyCount}.',
      'Catalogue résultant : ${report.resultingEntryCount}.',
      if (report.createdIds.isNotEmpty)
        'Exemples créés : ${report.createdIds.take(5).join(', ')}.',
      if (report.updatedIds.isNotEmpty)
        'Exemples mis à jour : ${report.updatedIds.take(5).join(', ')}.',
      ...report.warnings,
    ];

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.chipFill(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Text(
          lines.join('\n'),
          key: const Key('pokedex-moves-catalog-preview-summary'),
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.45,
          ),
        ),
      ),
    );
  }
}

class _PokedexMoveCatalogRow extends StatelessWidget {
  const _PokedexMoveCatalogRow({
    required this.entry,
  });

  final PokemonMoveCatalogEntryView entry;

  @override
  Widget build(BuildContext context) {
    final label = EditorChrome.primaryLabel(context);
    final subtle = EditorChrome.subtleLabel(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: EditorChrome.accentWarm.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${entry.name} • ${entry.id}',
              style: TextStyle(
                color: label,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (entry.type != null) entry.type!,
                if (entry.category != null) entry.category!,
                if (entry.pp != null) 'PP ${entry.pp}',
                if (entry.power != null) 'Puissance ${entry.power}',
                'Précision ${entry.accuracyLabel}',
              ].join(' • '),
              style: TextStyle(
                color: subtle,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entry.shortDesc != null && entry.shortDesc!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                entry.shortDesc!,
                style: TextStyle(
                  color: subtle,
                  fontSize: 11,
                  height: 1.35,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`

```dart
part of 'pokedex_workspace_page.dart';

// État principal du workspace.
//
// Cette partie porte seulement l'état d'écran local : recherche, filtres,
// sélection, feedback et chargement de la fiche détail. Elle ne remplace
// aucun provider métier et ne maintient aucun cache parallèle.

class _PokedexWorkspaceBodyState extends State<_PokedexWorkspaceBody> {
  late Future<List<PokemonDatabaseIndexEntry>> _entriesFuture;
  String _searchQuery = '';
  bool _filtersExpanded = false;
  String _selectedType = _allTypesFilterValue;
  String _selectedGeneration = _allGenerationsFilterValue;
  String _selectedStatus = _allStatusesFilterValue;
  String? _selectedSpeciesId;
  Future<PokedexSpeciesDetail>? _detailFuture;
  String _selectedDetailTabId = _overviewTabId;
  String? _feedbackMessage;
  bool _feedbackIsError = false;
  Timer? _feedbackTimer;

  @override
  void initState() {
    super.initState();
    _entriesFuture = _buildEntriesFuture();
  }

  @override
  void dispose() {
    _feedbackTimer?.cancel();
    super.dispose();
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
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
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
                projectRootPath: projectRootPath,
                entries: filteredEntries,
                selectedSpeciesId: _selectedSpeciesId,
                onEntrySelected: (entry) => _selectEntry(
                  workspace: workspace,
                  entry: entry,
                ),
                onImportRequested: () => _openImportFlow(workspace),
                query: _searchQuery,
                onQueryChanged: _updateSearchQuery,
                filtersExpanded: _filtersExpanded,
                onToggleFiltersExpanded: _toggleFiltersExpanded,
                availableTypes: availableTypes,
                selectedType: _selectedType,
                onTypeChanged: _updateSelectedType,
                availableGenerations: availableGenerations,
                selectedGeneration: _selectedGeneration,
                onGenerationChanged: _updateSelectedGeneration,
                selectedStatus: _selectedStatus,
                onStatusChanged: _updateSelectedStatus,
                feedbackMessage: _feedbackMessage,
                feedbackIsError: _feedbackIsError,
                emptyStateChild: entries.isEmpty
                    ? PokedexWorkspaceImportEmptyState(
                        onImportRequested: () => _openImportFlow(workspace),
                      )
                    : null,
                emptyResultsChild: entries.isNotEmpty && filteredEntries.isEmpty
                    ? PokedexWorkspaceNoResultsState(
                        query: _searchQuery,
                        selectedType: _selectedType == _allTypesFilterValue
                            ? null
                            : _selectedType,
                        selectedGeneration:
                            _selectedGeneration == _allGenerationsFilterValue
                                ? null
                                : _selectedGeneration,
                        selectedStatus:
                            _selectedStatus == _allStatusesFilterValue
                                ? null
                                : _selectedStatus,
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
                onDeleteSpecies: _deleteSpecies,
                onSaveMetadata: _saveMetadata,
                onSaveFormsClassification: _saveFormsClassification,
                onSaveLearnset: _saveLearnset,
                onSaveEvolution: _saveEvolution,
                onSaveMedia: _saveMedia,
                onLoadMovesCatalog: _loadMovesCatalog,
                onPreviewMovesCatalogSync: _previewMovesCatalogSync,
                onSyncMovesCatalog: _syncMovesCatalog,
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

  void _toggleFiltersExpanded() {
    setState(() => _filtersExpanded = !_filtersExpanded);
  }

  void _updateSelectedType(String value) {
    if (value == _selectedType) return;
    setState(() => _selectedType = value);
  }

  void _updateSelectedGeneration(String value) {
    if (value == _selectedGeneration) return;
    setState(() => _selectedGeneration = value);
  }

  void _updateSelectedStatus(String value) {
    if (value == _selectedStatus) return;
    setState(() => _selectedStatus = value);
  }

  void _updateSelectedDetailTab(String value) {
    if (value == _selectedDetailTabId) return;
    setState(() => _selectedDetailTabId = value);
  }

  void _showFeedback(String message, {required bool isError}) {
    _feedbackTimer?.cancel();
    setState(() {
      _feedbackMessage = message;
      _feedbackIsError = isError;
    });
    _feedbackTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted) {
        return;
      }
      setState(() => _feedbackMessage = null);
    });
  }

  Future<void> _openImportFlow(ProjectFileSystem workspace) async {
    final result = await _showPokedexImportFlowSheet(
      context: context,
      workspace: workspace,
      previewImport: widget.importPreviewer,
      importPokemon: widget.importer,
      previewExternalImport: widget.externalImportPreviewer,
      importExternalPokemon: widget.externalImporter,
      pickJsonSourceFile: widget.pickJsonImportFile,
    );
    if (!mounted || result == null) {
      return;
    }

    final importedSpeciesId = result.speciesId.trim();
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      _searchQuery = '';
      _filtersExpanded = false;
      _selectedType = _allTypesFilterValue;
      _selectedGeneration = _allGenerationsFilterValue;
      _selectedStatus = _allStatusesFilterValue;
      _selectedSpeciesId = importedSpeciesId;
      _selectedDetailTabId = _overviewTabId;
      _detailFuture = widget.detailLoader(workspace, importedSpeciesId);
    });

    final importedArtifacts = <String>[
      'espèce',
      if (result.importedLearnset) 'learnset',
      if (result.importedEvolution) 'évolutions',
      if (result.importedMedia) 'médias',
    ];
    if (result.downloadedAssetCount > 0) {
      importedArtifacts.add('${result.downloadedAssetCount} assets');
    }
    _showFeedback(
      'Import terminé pour ${result.primaryName} · ${importedArtifacts.join(', ')}',
      isError: false,
    );
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

  Future<void> _saveMetadata(
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.metadataSaver(workspace, request),
    );
  }

  Future<void> _saveFormsClassification(
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) =>
          widget.formsClassificationSaver(workspace, request),
    );
  }

  Future<void> _saveLearnset(
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.learnsetSaver(workspace, request),
    );
  }

  Future<void> _saveEvolution(
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.evolutionSaver(workspace, request),
    );
  }

  Future<void> _saveMedia(
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    await _runLocalPokemonSave(
      speciesId: request.speciesId,
      saveOperation: (workspace) => widget.mediaSaver(workspace, request),
    );
  }

  Future<PokemonMovesCatalogView> _loadMovesCatalog() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot load the local moves catalog without a loaded project',
      );
    }

    return widget.movesCatalogLoader(ProjectFileSystem(projectRootPath));
  }

  Future<PokemonMovesCatalogSyncResult> _previewMovesCatalogSync() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot preview the moves catalog sync without a loaded project',
      );
    }

    return widget.movesCatalogPreviewer(ProjectFileSystem(projectRootPath));
  }

  Future<PokemonMovesCatalogSyncResult> _syncMovesCatalog() async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot sync the moves catalog without a loaded project',
      );
    }

    return widget.movesCatalogSyncer(ProjectFileSystem(projectRootPath));
  }

  Future<void> _deleteSpecies(PokemonDatabaseIndexEntry entry) async {
    final confirmed = await showMacosEditorTwoChoiceAlert(
      context,
      title: 'Supprimer cette espèce ?',
      message:
          'Supprimer ${entry.primaryName} effacera l’espèce locale et ses fichiers Pokédex associés (learnset, évolutions, médias référencés). Cette action ne touche pas au runtime ni à project.json.',
      primaryLabel: 'Supprimer',
      secondaryLabel: 'Annuler',
      primaryIsDestructive: true,
      icon: CupertinoIcons.delete_solid,
    );
    if (!confirmed || !mounted) {
      return;
    }

    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot delete local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    try {
      final result = await widget.deleteSpecies(workspace, entry.id);
      if (!mounted) {
        return;
      }

      // La suppression doit recharger la liste depuis la même source de vérité
      // disque que le reste du workspace.
      //
      // On ne tente pas d'enlever la ligne "à la main" dans l'état local,
      // parce que cela créerait immédiatement un cache parallèle fragile.
      setState(() {
        _entriesFuture = _buildEntriesFuture();
        _selectedSpeciesId = null;
        _detailFuture = null;
        _selectedDetailTabId = _overviewTabId;
      });
      _showFeedback(
        '${result.primaryName} a été supprimé du Pokédex local.',
        isError: false,
      );
    } on EditorApplicationException catch (error) {
      if (!mounted) {
        return;
      }
      _showFeedback(error.message, isError: true);
    }
  }

  Future<void> _runLocalPokemonSave({
    required String speciesId,
    required Future<void> Function(ProjectFileSystem workspace) saveOperation,
  }) async {
    final projectRootPath = widget.projectRootPath?.trim();
    if (projectRootPath == null || projectRootPath.isEmpty) {
      throw StateError(
        'Cannot save local Pokemon data without a loaded project',
      );
    }

    final workspace = ProjectFileSystem(projectRootPath);
    await saveOperation(workspace);
    if (!mounted) {
      return;
    }

    // Après une sauvegarde locale, on relit la même source de vérité que le
    // reste du workspace :
    // - l'index léger pour la liste et les filtres ;
    // - la fiche détail complète pour l'espèce sélectionnée.
    //
    // On évite ainsi tout cache parallèle "enabled" ou "draft saved" qui
    // pourrait diverger du JSON réellement persisté.
    setState(() {
      _entriesFuture = _buildEntriesFuture();
      if (_selectedSpeciesId == speciesId.trim()) {
        _detailFuture = widget.detailLoader(workspace, speciesId);
      }
    });
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`

```dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart'
    show
        ControlSize,
        MacosIcon,
        MacosPopupButton,
        MacosPopupMenuItem,
        ProgressCircle,
        PushButton;
import 'package:path/path.dart' as p;

import '../../../app/providers/pokedex_providers.dart';
import '../../../application/errors/application_errors.dart';
import '../../../application/models/pokedex_species_detail.dart';
import '../../../application/models/pokemon_database_index.dart';
import '../../../application/models/pokemon_project_data_models.dart';
import '../../../application/ports/project_workspace.dart';
import '../../../application/use_cases/delete_pokedex_species_use_case.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_evolution_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_learnset_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_media_use_case.dart';
import '../../../application/use_cases/update_pokedex_species_metadata_use_case.dart';
import '../../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../../features/editor/state/editor_notifier.dart';
import '../../../infrastructure/filesystem/project_filesystem.dart';
import '../pokedex_workspace_loader.dart';
import '../../shared/cupertino_editor_widgets.dart';

part 'pokedex_workspace_body.dart';
part 'pokedex_workspace_logic.dart';
part 'pokedex_empty_state.dart';
part 'pokedex_feedback_banner.dart';
part 'pokedex_list_panel.dart';
part 'pokedex_toolbar.dart';
part 'pokedex_filters_panel.dart';
part 'pokedex_list_row.dart';
part 'pokedex_import_flow.dart';
part 'pokedex_import_flow_steps.dart';
part 'pokedex_import_flow_support.dart';
part 'pokedex_detail_panel.dart';
part 'pokedex_overview_panel.dart';
part 'pokedex_metadata_editor.dart';
part 'pokedex_metadata_editor_fields.dart';
part 'pokedex_forms_panel.dart';
part 'pokedex_learnset_panel.dart';
part 'pokedex_learnset_sections.dart';
part 'pokedex_moves_catalog_section.dart';
part 'pokedex_evolution_panel.dart';
part 'pokedex_media_panel.dart';
part 'pokedex_common_widgets.dart';
part 'pokedex_formatters.dart';

const String _allTypesFilterValue = '__all_types__';
const String _allGenerationsFilterValue = '__all_generations__';
const String _allStatusesFilterValue = '__all_statuses__';
const String _enabledStatusFilterValue = '__enabled_only__';
const String _overviewTabId = 'overview';
const MethodChannel _macOsImportFileAccessChannel =
    MethodChannel('map_editor/file_access');

// Bibliothèque racine du workspace Pokédex.
//
// Toute la logique métier reste hors de l'UI :
// - les use cases et loaders sont injectés depuis les providers existants ;
// - cette couche orchestre uniquement l'affichage, la sélection locale et les
//   transitions utilisateur du workspace ;
// - le découpage en `part` garde les widgets privés déjà en place tout en
//   rendant l'écran maintenable et lisible pour l'équipe.
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
    this.importPreviewer,
    this.importer,
    this.externalImportPreviewer,
    this.externalImporter,
    this.pickJsonImportFile,
    this.deleteSpecies,
    this.metadataSaver,
    this.formsClassificationSaver,
    this.learnsetSaver,
    this.evolutionSaver,
    this.mediaSaver,
    this.movesCatalogLoader,
    this.movesCatalogPreviewer,
    this.movesCatalogSyncer,
  });

  /// Injection locale utile aux tests ciblés du lot 13.
  ///
  /// On garde cette extension volontairement minimale : elle permet de tester
  /// le rendu des états UI sans introduire de notifier dédié supplémentaire.
  final PokedexEntryLoader? loader;
  final PokedexSpeciesDetailLoader? detailLoader;
  final PokedexImportPreviewer? importPreviewer;
  final PokedexImporter? importer;
  final PokedexExternalImportPreviewer? externalImportPreviewer;
  final PokedexExternalImporter? externalImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter? deleteSpecies;
  final PokedexSpeciesMetadataSaver? metadataSaver;
  final PokedexSpeciesFormsClassificationSaver? formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver? learnsetSaver;
  final PokedexSpeciesEvolutionSaver? evolutionSaver;
  final PokedexSpeciesMediaSaver? mediaSaver;
  final PokedexMovesCatalogLoader? movesCatalogLoader;
  final PokedexMovesCatalogPreviewer? movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer? movesCatalogSyncer;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectRootPath =
        ref.watch(editorNotifierProvider.select((s) => s.projectRootPath));
    final PokedexEntryLoader resolvedLoader =
        loader ?? ref.watch(pokedexEntryLoaderProvider);
    final PokedexSpeciesDetailLoader resolvedDetailLoader =
        detailLoader ?? ref.watch(pokedexSpeciesDetailLoaderProvider);
    final PokedexImportPreviewer resolvedImportPreviewer =
        importPreviewer ?? ref.watch(pokedexImportPreviewerProvider);
    final PokedexImporter resolvedImporter =
        importer ?? ref.watch(pokedexImporterProvider);
    final PokedexExternalImportPreviewer resolvedExternalImportPreviewer =
        externalImportPreviewer ??
            ref.watch(pokedexExternalImportPreviewerProvider);
    final PokedexExternalImporter resolvedExternalImporter =
        externalImporter ?? ref.watch(pokedexExternalImporterProvider);
    final PokedexSpeciesDeleter resolvedDeleteSpecies =
        deleteSpecies ?? ref.watch(pokedexSpeciesDeleterProvider);
    final PokedexSpeciesMetadataSaver resolvedMetadataSaver =
        metadataSaver ?? ref.watch(pokedexSpeciesMetadataSaverProvider);
    final PokedexSpeciesFormsClassificationSaver
        resolvedFormsClassificationSaver = formsClassificationSaver ??
            ref.watch(pokedexSpeciesFormsClassificationSaverProvider);
    final PokedexSpeciesLearnsetSaver resolvedLearnsetSaver =
        learnsetSaver ?? ref.watch(pokedexSpeciesLearnsetSaverProvider);
    final PokedexSpeciesEvolutionSaver resolvedEvolutionSaver =
        evolutionSaver ?? ref.watch(pokedexSpeciesEvolutionSaverProvider);
    final PokedexSpeciesMediaSaver resolvedMediaSaver =
        mediaSaver ?? ref.watch(pokedexSpeciesMediaSaverProvider);
    final PokedexMovesCatalogLoader resolvedMovesCatalogLoader =
        movesCatalogLoader ?? ref.watch(pokedexMovesCatalogLoaderProvider);
    final PokedexMovesCatalogPreviewer resolvedMovesCatalogPreviewer =
        movesCatalogPreviewer ??
            ref.watch(pokedexMovesCatalogPreviewerProvider);
    final PokedexMovesCatalogSyncer resolvedMovesCatalogSyncer =
        movesCatalogSyncer ?? ref.watch(pokedexMovesCatalogSyncerProvider);

    return _PokedexWorkspaceBody(
      projectRootPath: projectRootPath,
      loader: resolvedLoader,
      detailLoader: resolvedDetailLoader,
      importPreviewer: resolvedImportPreviewer,
      importer: resolvedImporter,
      externalImportPreviewer: resolvedExternalImportPreviewer,
      externalImporter: resolvedExternalImporter,
      pickJsonImportFile: pickJsonImportFile,
      deleteSpecies: resolvedDeleteSpecies,
      metadataSaver: resolvedMetadataSaver,
      formsClassificationSaver: resolvedFormsClassificationSaver,
      learnsetSaver: resolvedLearnsetSaver,
      evolutionSaver: resolvedEvolutionSaver,
      mediaSaver: resolvedMediaSaver,
      movesCatalogLoader: resolvedMovesCatalogLoader,
      movesCatalogPreviewer: resolvedMovesCatalogPreviewer,
      movesCatalogSyncer: resolvedMovesCatalogSyncer,
    );
  }
}

class _PokedexWorkspaceBody extends StatefulWidget {
  const _PokedexWorkspaceBody({
    required this.projectRootPath,
    required this.loader,
    required this.detailLoader,
    required this.importPreviewer,
    required this.importer,
    required this.externalImportPreviewer,
    required this.externalImporter,
    required this.pickJsonImportFile,
    required this.deleteSpecies,
    required this.metadataSaver,
    required this.formsClassificationSaver,
    required this.learnsetSaver,
    required this.evolutionSaver,
    required this.mediaSaver,
    required this.movesCatalogLoader,
    required this.movesCatalogPreviewer,
    required this.movesCatalogSyncer,
  });

  final String? projectRootPath;
  final PokedexEntryLoader loader;
  final PokedexSpeciesDetailLoader detailLoader;
  final PokedexImportPreviewer importPreviewer;
  final PokedexImporter importer;
  final PokedexExternalImportPreviewer externalImportPreviewer;
  final PokedexExternalImporter externalImporter;
  final Future<String?> Function()? pickJsonImportFile;
  final PokedexSpeciesDeleter deleteSpecies;
  final PokedexSpeciesMetadataSaver metadataSaver;
  final PokedexSpeciesFormsClassificationSaver formsClassificationSaver;
  final PokedexSpeciesLearnsetSaver learnsetSaver;
  final PokedexSpeciesEvolutionSaver evolutionSaver;
  final PokedexSpeciesMediaSaver mediaSaver;
  final PokedexMovesCatalogLoader movesCatalogLoader;
  final PokedexMovesCatalogPreviewer movesCatalogPreviewer;
  final PokedexMovesCatalogSyncer movesCatalogSyncer;

  @override
  State<_PokedexWorkspaceBody> createState() => _PokedexWorkspaceBodyState();
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

```dart
import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokedex_species_detail.dart';
import '../../application/ports/project_workspace.dart';
import '../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import '../../application/services/pokemon_database_index.dart';
import '../../domain/repositories/repositories.dart';

typedef PokedexEntryLoader = Future<List<PokemonDatabaseIndexEntry>> Function(
  ProjectWorkspace workspace,
);

typedef PokedexSpeciesDetailLoader = Future<PokedexSpeciesDetail> Function(
  ProjectWorkspace workspace,
  String speciesId,
);

typedef PokedexImportPreviewer = Future<PokemonJsonImportPreview> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexImporter = Future<PokemonJsonImportResult> Function(
  ProjectWorkspace workspace,
  String absoluteSpeciesSourcePath,
);

typedef PokedexExternalImportPreviewer = Future<PokemonExternalImportResult>
    Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexExternalImporter = Future<PokemonExternalImportResult> Function(
  ProjectWorkspace workspace,
  String speciesQuery,
);

typedef PokedexMovesCatalogLoader = Future<PokemonMovesCatalogView> Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogPreviewer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
);

typedef PokedexMovesCatalogSyncer = Future<PokemonMovesCatalogSyncResult>
    Function(
  ProjectWorkspace workspace,
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/http_pokemon_external_source_repository_test.dart`

```dart
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:map_editor/src/infrastructure/external/pokeapi_live_source.dart';
import 'package:map_editor/src/infrastructure/external/showdown_snapshot_source.dart';
import 'package:map_editor/src/infrastructure/repositories/http_pokemon_external_source_repository.dart';

void main() {
  test('HttpPokemonExternalSourceRepository composes Showdown and PokeAPI',
      () async {
    final client = MockClient((request) async {
      if (request.url.toString() == 'https://showdown.test/data/pokedex.json') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'bulbasaur': <String, Object?>{
              'name': 'Bulbasaur',
              'num': 1,
              'types': <String>['Grass', 'Poison'],
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() == 'https://showdown.test/data/moves.json') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'thunderbolt': <String, Object?>{'name': 'Thunderbolt'},
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/pokemon-species/bulbasaur') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'name': 'bulbasaur',
            'evolution_chain': <String, Object?>{
              'url': 'https://pokeapi.test/api/v2/evolution-chain/1/',
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/pokemon/bulbasaur') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'name': 'bulbasaur',
            'moves': <Object?>[],
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() ==
          'https://pokeapi.test/api/v2/evolution-chain/1/') {
        return http.Response(
          jsonEncode(<String, Object?>{
            'chain': <String, Object?>{
              'species': <String, Object?>{'name': 'bulbasaur'},
              'evolves_to': <Object?>[],
            },
          }),
          200,
          headers: const <String, String>{
            'content-type': 'application/json',
          },
        );
      }
      if (request.url.toString() == 'https://assets.test/front.png') {
        return http.Response.bytes(
          <int>[1, 2, 3, 4],
          200,
          headers: const <String, String>{
            'content-type': 'image/png',
          },
        );
      }
      return http.Response('not found', 404);
    });

    final repository = HttpPokemonExternalSourceRepository(
      pokeApiSource: PokeApiLiveSource(
        client: client,
        baseUri: 'https://pokeapi.test/api/v2',
      ),
      showdownSource: ShowdownSnapshotSource(
        client: client,
        baseUri: 'https://showdown.test/data',
      ),
    );

    final showdown = await repository.fetchShowdownSpeciesPayload('bulbasaur');
    final movesSnapshot = await repository.fetchShowdownMovesSnapshot();
    final pokemon = await repository.fetchPokeApiPokemonPayload('bulbasaur');
    final pokemonSpecies =
        await repository.fetchPokeApiPokemonSpeciesPayload('bulbasaur');
    final evolution =
        await repository.fetchPokeApiEvolutionChainPayload('bulbasaur');
    final asset = await repository.fetchBinaryAsset(
      'https://assets.test/front.png',
    );

    expect(showdown['name'], 'Bulbasaur');
    expect(movesSnapshot.containsKey('thunderbolt'), isTrue);
    expect(pokemon['name'], 'bulbasaur');
    expect(pokemonSpecies['name'], 'bulbasaur');
    expect(
      ((evolution['chain'] as Map<String, dynamic>)['species']
          as Map<String, dynamic>)['name'],
      'bulbasaur',
    );
    expect(asset.contentType, 'image/png');
  });
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
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/services/pokemon_database_index.dart';
import 'package:map_editor/src/application/use_cases/delete_pokedex_species_use_case.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/import_pokemon_json_bundle_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_evolution_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_forms_classification_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/sync_pokemon_moves_catalog_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_metadata_use_case.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_media_use_case.dart';
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
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1440, 980);
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
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
    bool isEnabledInProject = true,
    String? portraitRelativePath,
  }) {
    return PokemonDatabaseIndexEntry(
      id: id,
      nationalDex: nationalDex,
      primaryName: primaryName,
      genIntroduced: genIntroduced,
      types: types,
      isEnabledInProject: isEnabledInProject,
      refs: PokemonDatabaseIndexRefs(
        learnset: id,
        evolution: id,
        media: id,
      ),
      portraitRelativePath: portraitRelativePath,
    );
  }

  PokedexSpeciesDetail buildDetail({
    required String id,
    int nationalDex = 1,
    int genIntroduced = 1,
    List<String> types = const <String>['grass', 'poison'],
    String primaryAbility = 'overgrow',
    String? secondaryAbility,
    String? hiddenAbility = 'chlorophyll',
    List<String> otherForms = const <String>[],
    bool isEnabledInProject = true,
    Map<String, String> names = const <String, String>{
      'fr': 'Bulbizarre',
      'en': 'Bulbasaur',
    },
    String? flavorText =
        'Une étrange graine a été plantée sur son dos à la naissance.',
    bool starterEligible = true,
    bool giftOnly = false,
    bool tradeOnly = false,
    PokemonLearnsetFile? learnset,
    PokemonEvolutionFile? evolution,
    PokemonMediaFile? media,
  }) {
    return PokedexSpeciesDetail(
      species: PokemonSpeciesFile(
        id: id,
        slug: id,
        nationalDex: nationalDex,
        names: names,
        speciesName: const <String, String>{
          'fr': 'Pokémon Graine',
          'en': 'Seed Pokemon',
        },
        genIntroduced: genIntroduced,
        typing: PokemonSpeciesTyping(
          types: types,
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
        classification: PokemonSpeciesClassification(
          isEnabledInProject: isEnabledInProject,
          isObtainable: true,
        ),
        refs: PokemonSpeciesRefs(
          learnset: id,
          evolution: id,
          media: id,
        ),
        dexContent: PokemonSpeciesDexContent(
          heightM: 0.7,
          weightKg: 6.9,
          color: 'green',
          flavorText: flavorText,
        ),
        gameplayFlags: PokemonSpeciesGameplayFlags(
          starterEligible: starterEligible,
          giftOnly: giftOnly,
          tradeOnly: tradeOnly,
        ),
        sourceMeta: const PokemonSpeciesSourceMeta(
          seededBy: 'ui-test',
          seedVersion: 1,
        ),
      ),
      learnset: learnset ??
          PokemonLearnsetFile(
            speciesId: id,
            startingMoves: const <String>['tackle', 'growl'],
            relearnMoves: const <String>['vine_whip'],
            levelUp: const <PokemonLearnsetLevelUpEntry>[
              PokemonLearnsetLevelUpEntry(
                moveId: 'vine_whip',
                level: 7,
                source: 'level_up',
                versionGroup: 'scarlet-violet',
              ),
            ],
            tm: const <PokemonLearnsetMoveEntry>[
              PokemonLearnsetMoveEntry(
                moveId: 'protect',
                versionGroup: 'scarlet-violet',
              ),
            ],
          ),
      evolution: evolution ??
          const PokemonEvolutionFile(
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
      media: media ??
          PokemonMediaFile(
            speciesId: id,
            defaultFormId: 'base',
            variants: <String, PokemonMediaVariant>{
              'base': PokemonMediaVariant(
                frontStatic: 'assets/pokemon/sprites/$id/front.png',
                backStatic: 'assets/pokemon/sprites/$id/back.png',
                frontShinyStatic: 'assets/pokemon/sprites/$id/front_shiny.png',
                backShinyStatic: 'assets/pokemon/sprites/$id/back_shiny.png',
                icon: 'assets/pokemon/sprites/$id/icon.png',
                party: 'assets/pokemon/sprites/$id/party.png',
                portrait: 'assets/pokemon/portraits/$id.png',
                cry: 'assets/pokemon/cries/$id.ogg',
                animations: <String, PokemonMediaAnimationRef>{
                  'battleFront': PokemonMediaAnimationRef(
                    sheet: 'assets/pokemon/sprites/$id/battle_front_sheet.png',
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
    if (find.byKey(popupKey).evaluate().isEmpty) {
      final toggleFinder =
          find.byKey(const Key('pokedex-toggle-filters-button'));
      if (toggleFinder.evaluate().isNotEmpty) {
        await tester.tap(toggleFinder);
        await tester.pumpAndSettle();
      }
    }
    await tester.ensureVisible(find.byKey(popupKey));
    await tester.tap(find.byKey(popupKey));
    await tester.pumpAndSettle();
    await tester.tap(find.text(itemLabel).last);
    await tester.pumpAndSettle();
  }

  PokemonDatabaseIndexEntry buildEntryFromSpecies(PokemonSpeciesFile species) {
    final speciesIndexEntry = PokemonSpeciesIndexEntry.fromSpeciesFile(
      species,
      relativePath:
          'data/pokemon/species/${species.nationalDex.toString().padLeft(4, '0')}-${species.slug}.json',
    );
    return PokemonDatabaseIndexEntry.fromSpeciesEntry(
      speciesIndexEntry: speciesIndexEntry,
      species: species,
    );
  }

  PokemonSpeciesFile applyMetadataUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) {
    final normalizedTypes = request.types
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .toSet()
        .toList(growable: false);
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: Map<String, String>.from(request.names),
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: PokemonSpeciesTyping(
        types: normalizedTypes,
      ),
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: species.forms,
      classification: PokemonSpeciesClassification(
        isEnabledInProject: request.isEnabledInProject,
        isObtainable: species.classification.isObtainable,
        isLegendary: species.classification.isLegendary,
        isMythical: species.classification.isMythical,
        isBaby: species.classification.isBaby,
      ),
      refs: species.refs,
      dexContent: PokemonSpeciesDexContent(
        heightM: species.dexContent.heightM,
        weightKg: species.dexContent.weightKg,
        color: species.dexContent.color,
        flavorText: request.flavorText?.trim().isEmpty ?? true
            ? null
            : request.flavorText?.trim(),
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(
        starterEligible: request.starterEligible,
        giftOnly: request.giftOnly,
        tradeOnly: request.tradeOnly,
      ),
      sourceMeta: species.sourceMeta,
    );
  }

  PokemonSpeciesFile applyFormsClassificationUpdate(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) {
    return PokemonSpeciesFile(
      id: species.id,
      slug: species.slug,
      nationalDex: species.nationalDex,
      names: species.names,
      speciesName: species.speciesName,
      genIntroduced: species.genIntroduced,
      typing: species.typing,
      baseStats: species.baseStats,
      abilities: species.abilities,
      breeding: species.breeding,
      progression: species.progression,
      forms: PokemonSpeciesForms(
        baseFormId: request.isBaseForm ? species.id : request.baseFormId.trim(),
        isBaseForm: request.isBaseForm,
        formId: request.formId.trim(),
        formName: request.formName?.trim().isEmpty ?? true
            ? null
            : request.formName?.trim(),
        otherForms: request.otherForms
            .map((value) => value.trim())
            .where(
              (value) => value.isNotEmpty && value != request.formId.trim(),
            )
            .toSet()
            .toList(growable: false),
      ),
      classification: PokemonSpeciesClassification(
        isEnabledInProject: species.classification.isEnabledInProject,
        isObtainable: request.isObtainable,
        isLegendary: request.isLegendary,
        isMythical: request.isMythical,
        isBaby: request.isBaby,
      ),
      refs: species.refs,
      dexContent: species.dexContent,
      gameplayFlags: species.gameplayFlags,
      sourceMeta: species.sourceMeta,
    );
  }

  PokemonLearnsetFile applyLearnsetUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) {
    final learnsetRef = detail.species.refs.learnset.trim();
    return PokemonLearnsetFile(
      speciesId: learnsetRef.isEmpty ? detail.species.id : learnsetRef,
      startingMoves: request.startingMoves
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      relearnMoves: request.relearnMoves
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList(growable: false),
      levelUp: request.levelUp,
      tm: request.tm,
      tutor: request.tutor,
      egg: request.egg,
      event: request.event,
      transfer: request.transfer,
    );
  }

  PokemonEvolutionFile applyEvolutionUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) {
    final evolutionRef = detail.species.refs.evolution.trim();
    return PokemonEvolutionFile(
      speciesId: evolutionRef.isEmpty ? detail.species.id : evolutionRef,
      preEvolution: request.preEvolution?.trim().isEmpty ?? true
          ? null
          : request.preEvolution?.trim(),
      evolutions: request.evolutions,
    );
  }

  PokemonMediaFile applyMediaUpdate(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesMediaRequest request,
  ) {
    final mediaRef = detail.species.refs.media.trim();
    return PokemonMediaFile(
      speciesId: mediaRef.isEmpty ? detail.species.id : mediaRef,
      defaultFormId: request.defaultFormId.trim(),
      variants: request.variants,
    );
  }

  _FakePokedexWorkspaceStore buildStore({
    required List<PokedexSpeciesDetail> details,
  }) {
    return _FakePokedexWorkspaceStore(
      detailsById: <String, PokedexSpeciesDetail>{
        for (final detail in details) detail.species.id: detail,
      },
      entryBuilder: buildEntryFromSpecies,
      metadataUpdater: applyMetadataUpdate,
      formsClassificationUpdater: applyFormsClassificationUpdate,
      learnsetUpdater: applyLearnsetUpdate,
      evolutionUpdater: applyEvolutionUpdate,
      mediaUpdater: applyMediaUpdate,
    );
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
    expect(
      find.textContaining('Recherche, import, détail et édition locale'),
      findsOneWidget,
    );
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
      'renders the editor list shell with import and collapsible filters',
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
    expect(find.text('Portrait'), findsOneWidget);
    expect(find.text('Numéro'), findsOneWidget);
    expect(find.text('Nom'), findsOneWidget);
    expect(find.text('ID'), findsOneWidget);
    expect(find.text('Types'), findsOneWidget);
    expect(find.text('#0001'), findsOneWidget);
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('bulbasaur'), findsOneWidget);
    expect(find.text('grass'), findsWidgets);
    expect(find.text('poison'), findsWidgets);
    expect(find.byKey(const Key('pokedex-import-button')), findsOneWidget);
    expect(
      find.byKey(const Key('pokedex-toggle-filters-button')),
      findsOneWidget,
    );
    expect(find.byKey(const Key('pokedex-filters-panel')), findsNothing);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
  });

  testWidgets(
      'renders a portrait thumbnail in the list when the entry exposes a portrait path',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Ce test UI reste volontairement léger :
    // - le service `PokemonProjectDataReader` prouve déjà qu'on ne projette un
    //   portrait que si le fichier existe réellement sur disque ;
    // - ici, on veut seulement verrouiller le rendu du workspace quand un
    //   chemin portrait a déjà été résolu par la couche applicative.
    //
    // On évite donc un vrai décodage image dans le test widget, qui n'apporte
    // aucune valeur supplémentaire au contrat UI et peut rendre le runner
    // desktop inutilement fragile.
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
            id: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
            genIntroduced: 1,
            portraitRelativePath: 'assets/pokemon/portraits/pikachu.png',
          ),
          buildEntry(
            id: 'eevee',
            nationalDex: 133,
            primaryName: 'Eevee',
            types: const <String>['normal'],
            genIntroduced: 1,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(
      find.byKey(const Key('pokedex-row-portrait-pikachu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pokedex-row-portrait-placeholder-pikachu')),
      findsNothing,
    );
    expect(
      find.byKey(const Key('pokedex-row-portrait-placeholder-eevee')),
      findsOneWidget,
    );
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
    expect(find.text('Formes et classification'), findsOneWidget);

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
    expect(
      find.text('assets/pokemon/portraits/bulbasaur.png'),
      findsOneWidget,
    );
    expect(find.textContaining('battleFront: battle_front'), findsOneWidget);
  });

  testWidgets(
      'shows the local moves catalog section in the learnset tab and allows preview + sync',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    var previewCallCount = 0;
    var syncCallCount = 0;
    var catalogEntries = <PokemonMoveCatalogEntryView>[
      const PokemonMoveCatalogEntryView(
        id: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: 'physical',
        power: 40,
        accuracy: 100,
        pp: 35,
      ),
    ];

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => <PokemonDatabaseIndexEntry>[
          buildEntry(
            id: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: const <String>['grass', 'poison'],
            genIntroduced: 1,
          ),
        ],
        detailLoader: (_, speciesId) async => buildDetail(id: speciesId),
        movesCatalogLoader: (_) async => PokemonMovesCatalogView(
          entries: List<PokemonMoveCatalogEntryView>.from(catalogEntries),
          isAvailable: true,
          description: 'Catalogue local des attaques pour le learnset.',
        ),
        movesCatalogPreviewer: (_) async {
          previewCallCount += 1;
          return const PokemonMovesCatalogSyncResult(
            dryRun: true,
            externalEntryCount: 2,
            createdIds: <String>['thunderbolt'],
            updatedIds: <String>['tackle'],
            unchangedIds: <String>[],
            preservedLocalOnlyIds: <String>[],
            resultingEntryCount: 2,
          );
        },
        movesCatalogSyncer: (_) async {
          syncCallCount += 1;
          catalogEntries = <PokemonMoveCatalogEntryView>[
            ...catalogEntries,
            const PokemonMoveCatalogEntryView(
              id: 'thunderbolt',
              name: 'Thunderbolt',
              type: 'electric',
              category: 'special',
              power: 90,
              accuracy: 100,
              pp: 15,
            ),
          ];
          return const PokemonMovesCatalogSyncResult(
            dryRun: false,
            externalEntryCount: 2,
            createdIds: <String>['thunderbolt'],
            updatedIds: <String>['tackle'],
            unchangedIds: <String>[],
            preservedLocalOnlyIds: <String>[],
            resultingEntryCount: 2,
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-moves-catalog-section')),
      findsOneWidget,
    );
    expect(find.text('Attaques locales : 1'), findsOneWidget);
    expect(find.text('Tackle • tackle'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pokedex-moves-catalog-preview-button')),
    );
    await tester.pumpAndSettle();
    expect(previewCallCount, 1);
    expect(
      find.byKey(const Key('pokedex-moves-catalog-preview-summary')),
      findsOneWidget,
    );
    expect(find.textContaining('Prévisualisation : 2 moves externes analysés.'),
        findsOneWidget);

    await tester
        .tap(find.byKey(const Key('pokedex-moves-catalog-sync-button')));
    await tester.pumpAndSettle();
    expect(syncCallCount, 1);
    expect(find.text('Attaques locales : 2'), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('pokedex-moves-catalog-search-field')),
      'thunder',
    );
    await tester.pumpAndSettle();
    expect(find.text('Thunderbolt • thunderbolt'), findsOneWidget);
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
    expect(find.byKey(const Key('pokedex-filters-panel')), findsNothing);
    await tester.tap(find.byKey(const Key('pokedex-toggle-filters-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-filters-panel')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-type-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-generation-filter')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-status-filter')), findsOneWidget);
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

  testWidgets('filters instantly by enabled status', (tester) async {
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
            isEnabledInProject: true,
          ),
          buildEntry(
            id: 'treecko',
            nationalDex: 252,
            primaryName: 'Treecko',
            types: <String>['grass'],
            genIntroduced: 3,
            isEnabledInProject: false,
          ),
        ],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );

    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Désactivées',
    );

    expect(find.text('Bulbasaur'), findsNothing);
    expect(find.text('Treecko'), findsOneWidget);
  });

  testWidgets(
      'enters edit mode saves simple metadata and keeps generation filtering stable',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
          starterEligible: true,
        ),
        buildDetail(
          id: 'treecko',
          nationalDex: 252,
          genIntroduced: 3,
          types: const <String>['grass'],
          names: const <String, String>{
            'fr': 'Arcko',
            'en': 'Treecko',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        deleteSpecies: store.deleteSpecies,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-generation-filter'),
      itemLabel: 'Génération 1',
    );
    expect(find.text('Bulbasaur'), findsOneWidget);
    expect(find.text('Treecko'), findsNothing);

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Projet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      'Bulbasaur Project',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-type-field-0')),
      'electric',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-type-field-1')),
      'fairy',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Texte édité depuis la fiche locale.',
    );
    await tester.tap(find.byKey(const Key('pokedex-gift-only-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(store.saveCallCount, 1);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre Projet');
    expect(store.speciesById('bulbasaur').names['en'], 'Bulbasaur Project');
    expect(
      store.speciesById('bulbasaur').typing.types,
      <String>['electric', 'fairy'],
    );
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Texte édité depuis la fiche locale.',
    );
    expect(store.speciesById('bulbasaur').gameplayFlags.giftOnly, isTrue);

    expect(find.text('Bulbasaur Project'), findsWidgets);
    expect(find.text('electric'), findsWidgets);
    expect(find.text('fairy'), findsWidgets);
    expect(find.text('Treecko'), findsNothing);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsNothing);
  });

  testWidgets(
      'deletes the selected species from the detail pane after confirmation',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        deleteSpecies: store.deleteSpecies,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-delete-species-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-delete-species-button')));
    await tester.pumpAndSettle();

    expect(find.text('Supprimer cette espèce ?'), findsOneWidget);
    expect(find.textContaining('Bulbizarre'), findsWidgets);

    await tester.tap(find.text('Supprimer').last);
    await tester.pumpAndSettle();

    expect(store.deleteCallCount, 1);
    expect(find.byKey(const Key('pokedex-row-bulbasaur')), findsNothing);
    expect(find.byKey(const Key('pokedex-row-ivysaur')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Bulbizarre a été supprimé'), findsOneWidget);
  });

  testWidgets('imports a pokemon from the wizard and refreshes the workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    var entries = <PokemonDatabaseIndexEntry>[];
    var previewCallCount = 0;
    var importCallCount = 0;
    String? selectedPathSeenByPreview;
    String? selectedPathSeenByImport;

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_import_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async => importedDetailsById[speciesId]!,
        pickJsonImportFile: () async => '/tmp/source/species/pikachu.json',
        importPreviewer: (_, absoluteSpeciesSourcePath) async {
          previewCallCount += 1;
          selectedPathSeenByPreview = absoluteSpeciesSourcePath;
          return const PokemonJsonImportPreview(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: <String>['electric'],
            learnset: PokemonImportArtifactPreview(
              label: 'Learnset',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.found,
              absoluteSourcePath: '/tmp/source/learnsets/pikachu.json',
            ),
            evolution: PokemonImportArtifactPreview(
              label: 'Évolutions',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.found,
              absoluteSourcePath: '/tmp/source/evolutions/pikachu.json',
            ),
            media: PokemonImportArtifactPreview(
              label: 'Médias',
              refId: 'pikachu',
              status: PokemonImportPreviewStatus.missing,
            ),
          );
        },
        importer: (_, absoluteSpeciesSourcePath) async {
          importCallCount += 1;
          selectedPathSeenByImport = absoluteSpeciesSourcePath;
          final detail = buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            types: const <String>['electric'],
            primaryAbility: 'static',
            hiddenAbility: 'lightning_rod',
            names: const <String, String>{
              'fr': 'Pikachu',
              'en': 'Pikachu',
            },
            flavorText: 'Il emmagasine l’électricité dans ses joues.',
          );
          importedDetailsById['pikachu'] = detail;
          entries = <PokemonDatabaseIndexEntry>[
            buildEntryFromSpecies(detail.species),
          ];
          return const PokemonJsonImportResult(
            preview: PokemonJsonImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonImportArtifactPreview(
                label: 'Learnset',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.found,
              ),
              evolution: PokemonImportArtifactPreview(
                label: 'Évolutions',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.found,
              ),
              media: PokemonImportArtifactPreview(
                label: 'Médias',
                refId: 'pikachu',
                status: PokemonImportPreviewStatus.missing,
              ),
            ),
            importedSpecies: true,
            importedLearnset: true,
            importedEvolution: true,
            importedMedia: false,
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byKey(const Key('pokedex-empty-state')), findsOneWidget);
    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-import-source-step')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pokedex-import-json-step')), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('pokedex-import-pick-json-file-button')),
    );
    await tester.pumpAndSettle();
    expect(find.text('pikachu.json'), findsOneWidget);

    await tester.tap(
      find.byKey(const Key('pokedex-import-json-continue-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(previewCallCount, 1);
    expect(selectedPathSeenByPreview, '/tmp/source/species/pikachu.json');
    expect(
        find.byKey(const Key('pokedex-import-preview-step')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-import-preview-title')), findsOneWidget);
    expect(find.text('#025 Pikachu'), findsOneWidget);
    expect(find.text('Type : electric'), findsOneWidget);
    expect(find.text('Learnset trouvé'), findsOneWidget);
    expect(find.text('Évolutions trouvées'), findsOneWidget);
    expect(find.text('Médias manquants'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-import-confirm-button')));
    await tester.pumpAndSettle();

    expect(importCallCount, 1);
    expect(selectedPathSeenByImport, '/tmp/source/species/pikachu.json');
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Pikachu'), findsWidgets);
    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
    expect(find.text('electric'), findsWidgets);
  });

  testWidgets('imports a pokemon from API externe and refreshes the workspace',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final importedDetailsById = <String, PokedexSpeciesDetail>{};
    var entries = <PokemonDatabaseIndexEntry>[];
    var previewCallCount = 0;
    var importCallCount = 0;
    String? querySeenByPreview;
    String? querySeenByImport;

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_import_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: (_) async => entries,
        detailLoader: (_, speciesId) async => importedDetailsById[speciesId]!,
        externalImportPreviewer: (_, speciesQuery) async {
          previewCallCount += 1;
          querySeenByPreview = speciesQuery;
          return const PokemonExternalImportResult(
            requestedSpeciesId: '25',
            importedSpeciesId: 'pikachu',
            preview: PokemonExternalImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonExternalImportPreviewArtifact(
                label: 'Learnset',
                isAvailable: true,
              ),
              evolution: PokemonExternalImportPreviewArtifact(
                label: 'Évolutions',
                isAvailable: true,
              ),
              media: PokemonExternalImportPreviewArtifact(
                label: 'Médias',
                isAvailable: true,
              ),
              cries: PokemonExternalImportPreviewArtifact(
                label: 'Cri',
                isAvailable: true,
              ),
            ),
            dryRun: true,
            mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
            artifacts: <PokemonExternalImportArtifactResult>[
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.species,
                relativePath: 'data/pokemon/species/0025-pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.learnset,
                relativePath: 'data/pokemon/learnsets/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.evolution,
                relativePath: 'data/pokemon/evolutions/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.media,
                relativePath: 'data/pokemon/media/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
            ],
          );
        },
        externalImporter: (_, speciesQuery) async {
          importCallCount += 1;
          querySeenByImport = speciesQuery;
          final detail = buildDetail(
            id: 'pikachu',
            nationalDex: 25,
            types: const <String>['electric'],
            primaryAbility: 'static',
            hiddenAbility: 'lightning_rod',
            names: const <String, String>{
              'fr': 'Pikachu',
              'en': 'Pikachu',
            },
            flavorText: 'Il emmagasine l’électricité dans ses joues.',
          );
          importedDetailsById['pikachu'] = detail;
          entries = <PokemonDatabaseIndexEntry>[
            buildEntryFromSpecies(detail.species),
          ];
          return const PokemonExternalImportResult(
            requestedSpeciesId: '25',
            importedSpeciesId: 'pikachu',
            preview: PokemonExternalImportPreview(
              speciesId: 'pikachu',
              nationalDex: 25,
              primaryName: 'Pikachu',
              types: <String>['electric'],
              learnset: PokemonExternalImportPreviewArtifact(
                label: 'Learnset',
                isAvailable: true,
              ),
              evolution: PokemonExternalImportPreviewArtifact(
                label: 'Évolutions',
                isAvailable: true,
              ),
              media: PokemonExternalImportPreviewArtifact(
                label: 'Médias',
                isAvailable: true,
              ),
              cries: PokemonExternalImportPreviewArtifact(
                label: 'Cri',
                isAvailable: true,
              ),
            ),
            dryRun: false,
            mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
            artifacts: <PokemonExternalImportArtifactResult>[
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.species,
                relativePath: 'data/pokemon/species/0025-pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.learnset,
                relativePath: 'data/pokemon/learnsets/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.evolution,
                relativePath: 'data/pokemon/evolutions/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
              PokemonExternalImportArtifactResult(
                kind: PokemonExternalImportArtifactKind.media,
                relativePath: 'data/pokemon/media/pikachu.json',
                action: PokemonExternalImportArtifactAction.create,
                existedBefore: false,
              ),
            ],
            downloadedAssets: <PokemonExternalAssetDownloadResult>[
              PokemonExternalAssetDownloadResult(
                label: 'Portrait',
                relativePath: 'assets/pokemon/portraits/pikachu.png',
                sourceUrl: 'https://assets.example.test/pikachu/portrait.png',
                wasWritten: true,
              ),
            ],
          );
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester
        .tap(find.byKey(const Key('pokedex-empty-state-import-button')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-api-source-card')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const Key('pokedex-import-source-continue-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const Key('pokedex-import-external-query-step')),
      findsOneWidget,
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-query-field')),
      '25',
    );
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-preview-button')),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(previewCallCount, 1);
    expect(querySeenByPreview, '25');
    expect(
      find.byKey(const Key('pokedex-import-external-preview-step')),
      findsOneWidget,
    );
    expect(find.text('#025 Pikachu'), findsOneWidget);
    expect(find.text('Type : electric'), findsOneWidget);
    expect(find.text('Learnset trouvé'), findsOneWidget);
    expect(find.text('Évolutions trouvées'), findsOneWidget);
    expect(find.text('Médias trouvés'), findsOneWidget);
    expect(find.text('Cri trouvé'), findsOneWidget);

    await tester.tap(find.byKey(const Key('pokedex-import-confirm-button')));
    await tester.pumpAndSettle();

    expect(importCallCount, 1);
    expect(querySeenByImport, '25');
    expect(find.byKey(const Key('pokedex-feedback-banner')), findsOneWidget);
    expect(find.textContaining('Pikachu'), findsWidgets);
    expect(find.byKey(const Key('pokedex-row-pikachu')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);
  });

  testWidgets('cancel discards metadata changes without writing',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      'Bulbizarre Temporaire',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Changement non enregistré.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-cancel-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.saveCallCount, 0);
    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isTrue);
    expect(store.speciesById('bulbasaur').names['fr'], 'Bulbizarre');
    expect(
      store.speciesById('bulbasaur').dexContent.flavorText,
      'Une étrange graine a été plantée sur son dos à la naissance.',
    );
    expect(find.text('Bulbizarre Temporaire'), findsNothing);
    expect(
        find.byKey(const Key('pokedex-edit-metadata-button')), findsOneWidget);
  });

  testWidgets(
      'keeps edit mode and shows a save error when all editable names are cleared without persisting anything',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );
    var attemptedSaves = 0;

    Future<PokemonSpeciesFile> saveWithValidation(
      ProjectWorkspace workspace,
      UpdatePokedexSpeciesMetadataRequest request,
    ) async {
      attemptedSaves += 1;

      // Le use case applicatif couvre déjà le non-write disque réel.
      // Ici, le test UI verrouille le contrat d'interaction :
      // - l'erreur remonte lisiblement ;
      // - le formulaire reste ouvert ;
      // - la backing store locale n'est pas mutée.
      final normalizedNames = <String, String>{
        for (final entry in request.names.entries)
          if (entry.key.trim().isNotEmpty) entry.key.trim(): entry.value.trim(),
      };
      final hasUsableName = normalizedNames.values.any(
        (value) => value.isNotEmpty,
      );
      if (!hasUsableName) {
        throw const EditorValidationException(
          'Pokemon species names must contain at least one non-empty value',
        );
      }

      return store.save(workspace, request);
    }

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    final persistedBefore = buildDetail(
      id: 'bulbasaur',
      names: const <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      isEnabledInProject: true,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: saveWithValidation,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-fr')),
      '   ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-name-field-en')),
      ' \n ',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-flavor-text-field')),
      'Tentative refusée localement.',
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(attemptedSaves, 1);
    expect(find.byKey(const Key('pokedex-name-field-fr')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-name-field-en')), findsOneWidget);
    expect(
        find.byKey(const Key('pokedex-save-metadata-button')), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-metadata-button')), findsNothing);
    expect(
        find.byKey(const Key('pokedex-metadata-save-error')), findsOneWidget);
    expect(
      find.text(
          'Pokemon species names must contain at least one non-empty value'),
      findsOneWidget,
    );

    final readBack = store.speciesById('bulbasaur');
    expect(readBack.names, persistedBefore.species.names);
    expect(
      readBack.dexContent.flavorText,
      persistedBefore.species.dexContent.flavorText,
    );
    expect(
      readBack.classification.isEnabledInProject,
      persistedBefore.species.classification.isEnabledInProject,
    );
    expect(store.saveCallCount, 0);
  });

  testWidgets(
      'saving a disable under the enabled filter clears the current selection cleanly',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          nationalDex: 1,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
          isEnabledInProject: true,
        ),
        buildDetail(
          id: 'ivysaur',
          nationalDex: 2,
          genIntroduced: 1,
          names: const <String, String>{
            'fr': 'Herbizarre',
            'en': 'Ivysaur',
          },
          isEnabledInProject: true,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await selectPopupFilter(
      tester,
      popupKey: const Key('pokedex-status-filter'),
      itemLabel: 'Activées',
    );
    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pokedex-detail-pane')), findsOneWidget);

    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-metadata-button')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.tap(find.byKey(const Key('pokedex-enabled-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-metadata-button')));
    await tester.pumpAndSettle();

    expect(store.speciesById('bulbasaur').classification.isEnabledInProject,
        isFalse);
    expect(find.byKey(const Key('pokedex-detail-empty-state')), findsOneWidget);
    expect(find.text('Ivysaur'), findsOneWidget);
    expect(find.text('Bulbizarre'), findsNothing);
  });

  testWidgets('edits forms and classification from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          names: const <String, String>{
            'fr': 'Bulbizarre',
            'en': 'Bulbasaur',
          },
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-forms')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-forms-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-forms-button')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('pokedex-is-base-form-switch')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const Key('pokedex-form-id-field')),
      'mega',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-form-name-field')),
      'Méga',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-other-forms-field')),
      'base\ngmax',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-is-legendary-switch')),
    );
    await tester.tap(find.byKey(const Key('pokedex-is-legendary-switch')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-forms-button')));
    await tester.tap(find.byKey(const Key('pokedex-save-forms-button')));
    await tester.pumpAndSettle();

    expect(store.formsSaveCallCount, 1);
    expect(store.speciesById('bulbasaur').forms.formId, 'mega');
    expect(store.speciesById('bulbasaur').forms.formName, 'Méga');
    expect(store.speciesById('bulbasaur').classification.isLegendary, isTrue);
    expect(find.text('Méga (mega)'), findsOneWidget);
    expect(find.byKey(const Key('pokedex-edit-forms-button')), findsOneWidget);
  });

  testWidgets('creates a learnset locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          learnset: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-learnset')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-learnset-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-starting-field')),
      'tackle\ngrowl',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-level-up-field')),
      'vine_whip|7|level_up|scarlet-violet',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-learnset-tm-field')),
      'protect|scarlet-violet',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-learnset-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-learnset-button')));
    await tester.pumpAndSettle();

    expect(store.learnsetSaveCallCount, 1);
    expect(store.learnsetById('bulbasaur')?.startingMoves, <String>[
      'tackle',
      'growl',
    ]);
    expect(
      store.learnsetById('bulbasaur')?.levelUp.single.moveId,
      'vine_whip',
    );
    expect(find.text('tackle, growl'), findsOneWidget);
  });

  testWidgets('creates an evolution locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          evolution: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-evolutions')));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-edit-evolution-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-edit-evolution-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-evolution-entries-field')),
      'ivysaur|level_up|16|||Évolue au niveau 16|Evolves at level 16',
    );
    await tester.ensureVisible(
      find.byKey(const Key('pokedex-save-evolution-button')),
    );
    await tester.tap(find.byKey(const Key('pokedex-save-evolution-button')));
    await tester.pumpAndSettle();

    expect(store.evolutionSaveCallCount, 1);
    expect(
      store.evolutionById('bulbasaur')?.evolutions.single.targetSpeciesId,
      'ivysaur',
    );
    expect(find.textContaining('Évolue au niveau 16'), findsOneWidget);
  });

  testWidgets('creates media references locally from the dedicated tab',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final store = buildStore(
      details: <PokedexSpeciesDetail>[
        buildDetail(
          id: 'bulbasaur',
          media: null,
        ),
      ],
    );

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: PokedexWorkspace(
        loader: store.loadEntries,
        detailLoader: store.loadDetail,
        metadataSaver: store.save,
        formsClassificationSaver: store.saveFormsClassification,
        learnsetSaver: store.saveLearnset,
        evolutionSaver: store.saveEvolution,
        mediaSaver: store.saveMedia,
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.byKey(const Key('pokedex-row-bulbasaur')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('pokedex-tab-media')));
    await tester.pumpAndSettle();
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-edit-media-button')));
    await tester.tap(find.byKey(const Key('pokedex-edit-media-button')));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const Key('pokedex-media-default-form-field')),
      'base',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-media-variants-field')),
      'base|assets/pokemon/sprites/bulbasaur/front.png|assets/pokemon/sprites/bulbasaur/back.png|||assets/pokemon/sprites/bulbasaur/icon.png|assets/pokemon/sprites/bulbasaur/party.png||assets/pokemon/portraits/bulbasaur.png|assets/pokemon/cries/bulbasaur.ogg',
    );
    await tester.enterText(
      find.byKey(const Key('pokedex-media-animations-field')),
      'base|battleFront|assets/pokemon/sprites/bulbasaur/battle_front_sheet.png|battle_front',
    );
    await tester.scrollUntilVisible(
      find.byKey(const Key('pokedex-save-media-button')),
      160,
      scrollable: find.byType(Scrollable).last,
    );
    await tester
        .ensureVisible(find.byKey(const Key('pokedex-save-media-button')));
    final saveMediaButton = tester.widget<CupertinoButton>(
      find.byKey(const Key('pokedex-save-media-button')),
    );
    saveMediaButton.onPressed!.call();
    await tester.pumpAndSettle();

    expect(store.mediaSaveCallCount, 1);
    expect(store.mediaById('bulbasaur')?.defaultFormId, 'base');
    expect(
      store.mediaById('bulbasaur')?.variants['base']?.portrait,
      'assets/pokemon/portraits/bulbasaur.png',
    );
    expect(find.text('assets/pokemon/portraits/bulbasaur.png'), findsOneWidget);
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
    expect(find.textContaining('Pokédex est encore vide'), findsOneWidget);
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

class _FakePokedexWorkspaceStore {
  _FakePokedexWorkspaceStore({
    required Map<String, PokedexSpeciesDetail> detailsById,
    required this.entryBuilder,
    required this.metadataUpdater,
    required this.formsClassificationUpdater,
    required this.learnsetUpdater,
    required this.evolutionUpdater,
    required this.mediaUpdater,
  }) : _detailsById = Map<String, PokedexSpeciesDetail>.from(detailsById);

  final Map<String, PokedexSpeciesDetail> _detailsById;
  final PokemonDatabaseIndexEntry Function(PokemonSpeciesFile species)
      entryBuilder;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesMetadataRequest request,
  ) metadataUpdater;
  final PokemonSpeciesFile Function(
    PokemonSpeciesFile species,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) formsClassificationUpdater;
  final PokemonLearnsetFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) learnsetUpdater;
  final PokemonEvolutionFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) evolutionUpdater;
  final PokemonMediaFile Function(
    PokedexSpeciesDetail detail,
    UpdatePokedexSpeciesMediaRequest request,
  ) mediaUpdater;

  int saveCallCount = 0;
  int formsSaveCallCount = 0;
  int learnsetSaveCallCount = 0;
  int evolutionSaveCallCount = 0;
  int mediaSaveCallCount = 0;
  int deleteCallCount = 0;

  Future<List<PokemonDatabaseIndexEntry>> loadEntries(
    ProjectWorkspace workspace,
  ) async {
    final entries = _detailsById.values
        .map((detail) => entryBuilder(detail.species))
        .toList(growable: false)
      ..sort((left, right) {
        final dexCompare = left.nationalDex.compareTo(right.nationalDex);
        if (dexCompare != 0) {
          return dexCompare;
        }
        return left.id.compareTo(right.id);
      });
    return entries;
  }

  Future<PokedexSpeciesDetail> loadDetail(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    return _detailsById[speciesId]!;
  }

  Future<PokemonSpeciesFile> save(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMetadataRequest request,
  ) async {
    saveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = metadataUpdater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  PokemonSpeciesFile speciesById(String speciesId) {
    return _detailsById[speciesId]!.species;
  }

  Future<PokemonSpeciesFile> saveFormsClassification(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesFormsClassificationRequest request,
  ) async {
    formsSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedSpecies = formsClassificationUpdater(current.species, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: updatedSpecies,
      learnset: current.learnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedSpecies;
  }

  Future<PokemonLearnsetFile> saveLearnset(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesLearnsetRequest request,
  ) async {
    learnsetSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedLearnset = learnsetUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: updatedLearnset,
      evolution: current.evolution,
      media: current.media,
    );
    return updatedLearnset;
  }

  Future<PokemonEvolutionFile> saveEvolution(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesEvolutionRequest request,
  ) async {
    evolutionSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedEvolution = evolutionUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: current.learnset,
      evolution: updatedEvolution,
      media: current.media,
    );
    return updatedEvolution;
  }

  Future<PokemonMediaFile> saveMedia(
    ProjectWorkspace workspace,
    UpdatePokedexSpeciesMediaRequest request,
  ) async {
    mediaSaveCallCount += 1;
    final current = _detailsById[request.speciesId]!;
    final updatedMedia = mediaUpdater(current, request);
    _detailsById[request.speciesId] = PokedexSpeciesDetail(
      species: current.species,
      learnset: current.learnset,
      evolution: current.evolution,
      media: updatedMedia,
    );
    return updatedMedia;
  }

  Future<DeletedPokedexSpeciesResult> deleteSpecies(
    ProjectWorkspace workspace,
    String speciesId,
  ) async {
    deleteCallCount += 1;
    final removed = _detailsById.remove(speciesId);
    if (removed == null) {
      throw EditorNotFoundException('Pokemon species not found: $speciesId');
    }
    final primaryName =
        removed.species.names['fr'] ?? removed.species.names['en'] ?? speciesId;
    return DeletedPokedexSpeciesResult(
      speciesId: speciesId,
      primaryName: primaryName,
      deletedRelativePaths: const <String>[],
    );
  }

  PokemonLearnsetFile? learnsetById(String speciesId) {
    return _detailsById[speciesId]!.learnset;
  }

  PokemonEvolutionFile? evolutionById(String speciesId) {
    return _detailsById[speciesId]!.evolution;
  }

  PokemonMediaFile? mediaById(String speciesId) {
    return _detailsById[speciesId]!.media;
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/provider_wiring_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/app/providers/content_studio_providers.dart';
import 'package:map_editor/src/app/providers/core_providers.dart';
import 'package:map_editor/src/app/providers/editor_workspace_providers.dart';
import 'package:map_editor/src/app/providers/pokedex_providers.dart';
import 'package:map_editor/src/app/providers/use_case_providers.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_providers.dart';
import 'package:map_editor/src/features/narrative/state/narrative_workspace_state.dart';

void main() {
  group('provider wiring', () {
    test('resolves thematic controllers from a ProviderContainer', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(projectRepositoryProvider), isNotNull);
      expect(container.read(terrainPresetResolverProvider), isNotNull);
      expect(container.read(createProjectDialogueUseCaseProvider), isNotNull);
      expect(container.read(pokemonDatabaseIndexProvider), isNotNull);
      expect(container.read(pokeApiLiveSourceProvider), isNotNull);
      expect(container.read(showdownSnapshotSourceProvider), isNotNull);
      expect(
          container.read(pokemonExternalSourceRepositoryProvider), isNotNull);
      expect(
        container.read(importExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(loadPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(syncExternalPokemonMovesCatalogUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexMovesCatalogLoaderProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogPreviewerProvider), isNotNull);
      expect(container.read(pokedexMovesCatalogSyncerProvider), isNotNull);
      expect(container.read(deletePokedexSpeciesUseCaseProvider), isNotNull);
      expect(container.read(pokedexSpeciesDeleterProvider), isNotNull);
      expect(container.read(pokedexExternalImportPreviewerProvider), isNotNull);
      expect(container.read(pokedexExternalImporterProvider), isNotNull);
      expect(container.read(editorWorkspaceControllerProvider), isNotNull);
      expect(container.read(projectContentControllerProvider), isNotNull);
    });

    test('derives selected narrative summaries from controller + projection',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(editorNotifierProvider.notifier).state = const EditorState(
        project: ProjectManifest(
          name: 'demo',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[
            ScenarioAsset(
              id: 'global_intro',
              name: 'Global Intro',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
              metadata: <String, String>{
                'step.id': 'step.professor_intro',
                'step.name': 'Rencontrer le professeur',
              },
            ),
            ScenarioAsset(
              id: 'local_intro',
              name: 'Local Intro',
              scope: ScenarioScope.localEventFlow,
              entryNodeId: 'start',
              declaredOutcomes: <String>['story.started'],
            ),
          ],
        ),
      );

      final narrativeNotifier =
          container.read(narrativeWorkspaceControllerProvider.notifier);
      narrativeNotifier.openGlobalStory(scenarioId: 'global_intro');
      narrativeNotifier.openStep(
        stepId: 'step.professor_intro',
        globalScenarioId: 'global_intro',
      );
      narrativeNotifier.openCutscene(cutsceneScenarioId: 'local_intro');
      narrativeNotifier.selectOutcome('story.started');

      expect(
        container.read(selectedGlobalStorySummaryProvider)?.id,
        'global_intro',
      );
      expect(
        container.read(selectedCutsceneSummaryProvider)?.id,
        'local_intro',
      );
      expect(
        container.read(selectedNarrativeStepSummaryProvider)?.id,
        'step.professor_intro',
      );
      expect(
        container.read(selectedNarrativeOutcomeSummaryProvider)?.id,
        'story.started',
      );
    });
  });
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/sync_pokemon_moves_catalog_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
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
    expect(vineWhip['name'], 'Vine Whip');
    expect(vineWhip['type'], 'grass');
    expect(vineWhip['power'], 45);
    expect(vineWhip['generation'], 1);
    expect(
      ((vineWhip['names'] as Map<String, dynamic>)['fr'] as String),
      'Fouet Lianes',
    );

    final swift = syncedCatalog.entries.firstWhere(
      (entry) => entry['id'] == 'swift',
    );
    expect(swift['accuracy'], isNull);
    expect(swift['accuracyText'], 'always');

    expect(loadedView.isAvailable, isTrue);
    expect(
        loadedView.entries.map((entry) => entry.id), contains('thunderbolt'));
    expect(await projectFile.readAsString(), beforeProjectJson);
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/update_pokedex_species_learnset_use_case_test.dart`

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/application/use_cases/update_pokedex_species_learnset_use_case.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late UpdatePokedexSpeciesLearnsetUseCase useCase;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokedex_species_learnset_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    readRepository = const FilePokemonReadRepository();
    writeRepository = const FilePokemonWriteRepository();
    useCase = UpdatePokedexSpeciesLearnsetUseCase(
      readRepository: readRepository,
      writeRepository: writeRepository,
    );

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokedex Species Learnset Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  test(
      'creates or updates the learnset JSON through the existing ref without touching project manifest',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await useCase.execute(
      workspace,
      const UpdatePokedexSpeciesLearnsetRequest(
        speciesId: 'bulbasaur',
        startingMoves: <String>['tackle', 'growl', 'tackle'],
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
        tutor: <PokemonLearnsetMoveEntry>[],
        egg: <PokemonLearnsetMoveEntry>[],
        event: <PokemonLearnsetMoveEntry>[],
        transfer: <PokemonLearnsetMoveEntry>[],
      ),
    );

    final readBack =
        await readRepository.readLearnsetById(workspace, 'bulbasaur-local');
    expect(readBack.speciesId, 'bulbasaur-local');
    expect(readBack.startingMoves, <String>['tackle', 'growl']);
    expect(readBack.relearnMoves, <String>['vine_whip']);
    expect(readBack.levelUp.single.moveId, 'vine_whip');
    expect(readBack.tm.single.moveId, 'protect');
    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur-local.json',
        ),
      ).exists(),
      isTrue,
    );
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test('rejects an empty learnset and leaves project manifest untouched',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);

    final projectFile = File(workspace.projectManifestPath);
    final beforeProjectJson = await projectFile.readAsString();

    await expectLater(
      () => useCase.execute(
        workspace,
        const UpdatePokedexSpeciesLearnsetRequest(
          speciesId: 'bulbasaur',
          startingMoves: <String>[],
          relearnMoves: <String>[],
          levelUp: <PokemonLearnsetLevelUpEntry>[],
          tm: <PokemonLearnsetMoveEntry>[],
          tutor: <PokemonLearnsetMoveEntry>[],
          egg: <PokemonLearnsetMoveEntry>[],
          event: <PokemonLearnsetMoveEntry>[],
          transfer: <PokemonLearnsetMoveEntry>[],
        ),
      ),
      throwsA(
        isA<EditorValidationException>().having(
          (error) => error.message,
          'message',
          'Pokemon learnset must contain at least one move section',
        ),
      ),
    );

    expect(
      await File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/learnsets/bulbasaur-local.json',
        ),
      ).exists(),
      isFalse,
    );
    expect(await projectFile.readAsString(), beforeProjectJson);
  });

  test(
      'rejects move ids absent from the local moves catalog when the catalog is populated',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _movesCatalogForValidation,
    );

    await expectLater(
      () => useCase.execute(
        workspace,
        const UpdatePokedexSpeciesLearnsetRequest(
          speciesId: 'bulbasaur',
          startingMoves: <String>['tackle'],
          relearnMoves: <String>[],
          levelUp: <PokemonLearnsetLevelUpEntry>[
            PokemonLearnsetLevelUpEntry(
              moveId: 'missing_move',
              level: 7,
              source: 'level_up',
              versionGroup: 'scarlet-violet',
            ),
          ],
          tm: <PokemonLearnsetMoveEntry>[],
          tutor: <PokemonLearnsetMoveEntry>[],
          egg: <PokemonLearnsetMoveEntry>[],
          event: <PokemonLearnsetMoveEntry>[],
          transfer: <PokemonLearnsetMoveEntry>[],
        ),
      ),
      throwsA(
        isA<EditorValidationException>().having(
          (error) => error.message,
          'message',
          contains('missing_move'),
        ),
      ),
    );
  });

  test('accepts valid move ids when the local moves catalog is populated',
      () async {
    await writeRepository.saveSpecies(workspace, _speciesWithCustomRefs);
    await writeRepository.saveCatalogByKey(
      workspace,
      'moves',
      _movesCatalogForValidation,
    );

    final saved = await useCase.execute(
      workspace,
      const UpdatePokedexSpeciesLearnsetRequest(
        speciesId: 'bulbasaur',
        startingMoves: <String>['tackle'],
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
        tutor: <PokemonLearnsetMoveEntry>[],
        egg: <PokemonLearnsetMoveEntry>[],
        event: <PokemonLearnsetMoveEntry>[],
        transfer: <PokemonLearnsetMoveEntry>[],
      ),
    );

    expect(saved.startingMoves, <String>['tackle']);
    expect(saved.relearnMoves, <String>['vine_whip']);
    expect(saved.tm.single.moveId, 'protect');
  });
}

const PokemonSpeciesFile _speciesWithCustomRefs = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbasaur',
  nationalDex: 1,
  names: <String, String>{'fr': 'Bulbizarre', 'en': 'Bulbasaur'},
  speciesName: <String, String>{'fr': 'Pokémon Graine', 'en': 'Seed Pokemon'},
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
  abilities: PokemonSpeciesAbilities(
    primary: 'overgrow',
    hidden: 'chlorophyll',
  ),
  breeding: PokemonSpeciesBreeding(
    genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
    eggGroups: <String>['monster', 'grass'],
    hatchCycles: 20,
  ),
  progression: PokemonSpeciesProgression(
    growthRateId: 'medium_slow',
    baseExp: 64,
    catchRate: 45,
    baseFriendship: 50,
  ),
  forms: PokemonSpeciesForms(
    baseFormId: 'bulbasaur',
    isBaseForm: true,
    formId: 'base',
  ),
  classification: PokemonSpeciesClassification(
    isEnabledInProject: true,
    isObtainable: true,
  ),
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur-local',
    evolution: 'bulbasaur-chain',
    media: 'bulbasaur-media',
  ),
  dexContent: PokemonSpeciesDexContent(
    heightM: 0.7,
    weightKg: 6.9,
    color: 'green',
    flavorText: 'Une étrange graine a été plantée sur son dos à la naissance.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(
    starterEligible: true,
    giftOnly: false,
    tradeOnly: false,
  ),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

const PokemonCatalogFile _movesCatalogForValidation = PokemonCatalogFile(
  schemaVersion: 1,
  kind: 'pokemon_catalog',
  catalog: 'moves',
  meta: PokemonDataMeta(
    description: 'Validation moves catalog for learnset editor tests.',
  ),
  entries: <Map<String, dynamic>>[
    <String, dynamic>{'id': 'tackle', 'name': 'Tackle'},
    <String, dynamic>{'id': 'vine_whip', 'name': 'Vine Whip'},
    <String, dynamic>{'id': 'protect', 'name': 'Protect'},
  ],
);

```

## 17. Manifest des assets binaires si applicable

Aucun asset binaire n’a été ajouté au repo dans ce scope 11B.
Les tests ont utilisé uniquement des workspaces temporaires système.
