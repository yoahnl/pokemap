# Phase R1 — Lot 3 — Sélection batch + dry-run batch

## 1. Résumé exécutif honnête

Le lot 3 est livré dans le périmètre demandé.

Ce qui a été ajouté :
- un vrai mode `Batch dry-run` dans la branche `API externe` du wizard Pokédex ;
- une résolution batch applicative réutilisant le résolveur du lot 1 ;
- une liste finale de cibles résolues, dédupliquées et ordonnées de façon stable ;
- un branchement au batch applicatif existant en `dryRun: true` ;
- une preview batch lisible, sans aucune écriture réelle ;
- des tests application, wiring, UI batch et non-régression mono-espèce.

Ce qui n’a **pas** été fait volontairement :
- aucune exécution batch réelle ;
- aucune progression détaillée d’import final ;
- aucun retry ;
- aucun rapport final d’exécution lot 4 ;
- aucun nouveau pipeline parallèle.

## 2. État initial audité

Avant modification, le repo possédait déjà :
- le pipeline d’import externe Pokédex hérité de la phase 11A ;
- le résolveur de requête du lot 1 ;
- l’auto-complétion mono-espèce du lot 2 ;
- un `BatchImportExternalPokemonSpeciesUseCase` déjà capable de fonctionner en `dryRun` ;
- un wizard Pokédex unique pour `Fichier JSON` et `API externe`.

Le manque produit réel était donc bien celui du lot 3 :
- rendre la sélection batch visible et compréhensible dans le wizard ;
- exposer un dry-run batch honnête ;
- sans anticiper l’exécution batch réelle du lot 4.

## 3. Périmètre inclus / exclu

### Inclus
- modèle applicatif de sélection batch ;
- use case de résolution batch ;
- wiring provider pour résolution batch et preview batch dry-run ;
- mode batch explicite dans le wizard `API externe` ;
- liste résolue visible avant dry-run ;
- preview batch non destructive ;
- tests application, wiring, UI batch et non-régression mono-espèce ;
- report complet du lot.

### Exclu
- exécution batch réelle ;
- progression d’import réel ;
- retry ;
- rapport final d’exécution lot 4 ;
- auto-complétion batch avancée ;
- refonte du wizard complet ;
- tout chantier runtime / battle / save.

## 4. Décisions d’architecture

1. Le résolveur du lot 1 n’a pas été réécrit.
Il reste la couche qui comprend la requête brute.

2. Un use case dédié de résolution batch a été ajouté.
Ce choix est justifié parce que le lot 3 orchestre plus qu’un simple parsing :
- réutilisation du résolveur du lot 1 ;
- chargement d’une source snapshot existante ;
- résolution en cibles finales ;
- déduplication après mapping ;
- blocage propre des cas invalides / hors-scope.

3. Le dry-run batch réutilise strictement le batch applicatif existant.
Aucun second format de preview batch n’a été créé.
L’UI appelle `BatchImportExternalPokemonSpeciesUseCase` avec `dryRun: true` via provider.

4. Les requêtes par dex / plage / génération ne résolvent que des espèces de base.
Cette décision évite qu’une plage comme `1-151` fasse exploser la sélection avec les nombreuses formes Showdown partageant le même numéro dex.
En revanche, une liste explicite peut encore cibler une forme précise si l’auteur la demande explicitement.

5. Le wizard garde une seule surface produit `API externe`.
Le choix entre mono-espèce et batch est un simple mode UI explicite, sans créer de workflow parallèle.

## 5. Liste exacte des fichiers modifiés / créés / supprimés

### Créés
- `packages/map_editor/lib/src/application/models/pokemon_external_batch_selection.dart`
- `packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart`
- `packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart`
- `packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart`
- `reports/phase-r1-lot-3-batch-selection-dry-run-report.md`

### Modifiés
- `packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`
- `packages/map_editor/lib/src/application/use_cases/use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`
- `packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart`
- `packages/map_editor/test/provider_wiring_test.dart`
- `packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

### Supprimés
- aucun

## 6. Justification fichier par fichier

- `pokemon_external_batch_selection.dart`
  Nouveau modèle de contrat pour représenter une sélection batch comprise par l’application, indépendamment du dry-run lui-même.

- `resolve_external_pokemon_batch_selection_use_case.dart`
  Nouvelle orchestration applicative du lot 3 : conversion d’une requête batch en cibles stables, dédupliquées et exploitables.

- `pokedex_providers.dart`
  Wiring DI minimal du nouveau use case et d’un previewer batch qui réutilise le batch dry-run existant.

- `use_cases.dart`
  Export du nouveau use case pour rester cohérent avec l’architecture applicative existante.

- `pokedex_workspace_loader.dart`
  Ajout des typedefs batch nécessaires aux injections UI/tests, sans déplacer de logique métier.

- `pokedex_workspace_page.dart`
  Injection optionnelle des callbacks batch dans le workspace pour tests ciblés et wiring propre.

- `pokedex_workspace_body.dart`
  Propagation des callbacks batch vers le flow modal existant.

- `pokedex_import_flow.dart`
  Extension locale du wizard : mode mono-espèce vs batch dry-run, résolution batch, chargement du dry-run, blocage explicite de tout import batch réel.

- `pokedex_import_flow_steps.dart`
  UI de sélection de mode, écran batch, verrouillage du bouton, preview batch détaillée.

- `pokedex_external_batch_field.dart`
  Nouveau sous-widget purement présentation pour la saisie batch, les messages d’état et la liste résolue.

- `pokedex_external_search_field.dart`
  Ajustement mineur non fonctionnel pour garder le wording aligné avec la nouvelle réalité du flow.

- `resolve_external_pokemon_batch_selection_use_case_test.dart`
  Couverture applicative du nouveau lot.

- `provider_wiring_test.dart`
  Vérification que le wiring DI du batch est bien résolu.

- `import_external_pokemon_use_cases_test.dart`
  Test explicite du `dryRun` batch sans écriture, pour prouver le contrat central du lot.

- `pokedex_external_batch_dry_run_ui_test.dart`
  Couverture UI du mode batch : switch explicite, verrouillage du dry-run, preview batch et transmission des espèces résolues.

## 7. Sub-agents utilisés, conclusions, retenu / rejeté

J’ai réutilisé les threads existants fournis dans l’environnement, au lieu d’ouvrir de nouveaux threads artificiels.

### Boyle — Architecture / scope reviewer
Conclusion :
- réutiliser le batch applicatif existant en `dryRun: true` ;
- ne pas créer de nouveau port ;
- ajouter une petite couche de résolution batch dédiée si nécessaire.

Retenu : oui.
Rejeté : toute tentative de nouveau pipeline batch parallèle.

### Avicenna — UX / wizard reviewer
Conclusion :
- garder un choix explicite `Mono-espèce` / `Batch dry-run` ;
- ne pas auto-basculer de mode selon la saisie ;
- exposer des états clairs : vide, résolution, invalide, hors-scope, liste résolue, dry-run.

Retenu : oui.
Rejeté : toute UX “magique” qui changerait de mode implicitement.

### Mendel — Test matrix reviewer
Conclusion :
- couvrir application, wiring, widget et non-régression mono ;
- vérifier la déduplication après mapping ;
- vérifier qu’aucun dry-run n’est déclenché sur une requête invalide.

Retenu : oui.
Rejeté : les tests purement décoratifs.

### Banach — Contradictor
Conclusion :
- ne pas faire de dry-run à chaque frappe ;
- ne pas laisser la logique batch dans le widget ;
- ne pas glisser vers le lot 4.

Retenu : oui.
Rejeté : la dérive de scope vers exécution batch réelle, progression ou retry.

## 8. Commandes réellement exécutées

### Audit repo / code

Toutes les commandes ci-dessous ont été exécutées réellement pendant l’audit du lot :

```text
find . -name AGENTS.md -print
sed -n '1,260p' packages/map_editor/lib/src/application/models/pokemon_external_query_resolution.dart
sed -n '1,260p' packages/map_editor/lib/src/application/models/pokemon_external_species_search_result.dart
sed -n '1,320p' packages/map_editor/lib/src/application/services/pokemon_external_query_resolver.dart
sed -n '1,340p' packages/map_editor/lib/src/application/use_cases/search_external_pokemon_species_use_case.dart
sed -n '1,360p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '360,760p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '1390,1475p' packages/map_editor/lib/src/application/use_cases/import_external_pokemon_use_cases.dart
sed -n '1,260p' packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '260,520p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
sed -n '1,280p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
sed -n '280,520p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
sed -n '1,260p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart
sed -n '260,460p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
sed -n '200,300p' packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
sed -n '1,220p' packages/map_editor/lib/src/application/ports/pokemon_external_source_repository.dart
sed -n '1,220p' packages/map_editor/lib/src/infrastructure/repositories/http_pokemon_external_source_repository.dart
sed -n '1,220p' packages/map_editor/lib/src/infrastructure/external/showdown_snapshot_source.dart
sed -n '1,220p' packages/map_editor/lib/src/infrastructure/external/pokeapi_live_source.dart
sed -n '1,220p' packages/map_editor/test/search_external_pokemon_species_use_case_test.dart
sed -n '1,260p' packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart
sed -n '2230,2325p' packages/map_editor/test/pokedex_workspace_ui_test.dart
sed -n '1,220p' packages/map_editor/test/provider_wiring_test.dart
sed -n '1,220p' packages/map_editor/test/http_pokemon_external_source_repository_test.dart
rg -n "class BatchImportExternalPokemonSpeciesUseCase|BatchImportExternalPokemonSpeciesUseCase|PokemonExternalBatchImportResult|dryRun" packages/map_editor/lib packages/map_editor/test
rg -n "external.*batch|batch.*external|gen 1|1-151|pikachu,eevee|suggestion-pikachu|selected-suggestion|preview-button" packages/map_editor/lib packages/map_editor/test
```

### Audit snapshot live ponctuel

```text
python - <<'PY'
import json, urllib.request
...
PY
```

Utilité : confirmer honnêtement que les snapshots Showdown contiennent de nombreuses formes partageant le même numéro dex, ce qui justifie la résolution “base species only” pour les plages/générations.

### Format

```text
dart format packages/map_editor/lib/src/application/models/pokemon_external_batch_selection.dart packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart packages/map_editor/lib/src/application/use_cases/use_cases.dart packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart packages/map_editor/test/provider_wiring_test.dart packages/map_editor/test/import_external_pokemon_use_cases_test.dart packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart
```

### Analyze

```text
flutter analyze --no-pub lib/src/application/models/pokemon_external_batch_selection.dart lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart lib/src/application/use_cases/use_cases.dart lib/src/app/providers/pokedex/pokedex_providers.dart lib/src/ui/canvas/pokedex_workspace_loader.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart test/resolve_external_pokemon_batch_selection_use_case_test.dart test/provider_wiring_test.dart test/import_external_pokemon_use_cases_test.dart test/pokedex_external_batch_dry_run_ui_test.dart
```

### Tests

```text
flutter test test/resolve_external_pokemon_batch_selection_use_case_test.dart
flutter test test/provider_wiring_test.dart
flutter test test/import_external_pokemon_use_cases_test.dart --plain-name "dry-run resolves a batch but writes nothing"
flutter test test/pokedex_external_batch_dry_run_ui_test.dart
flutter test test/pokedex_external_autocomplete_ui_test.dart
flutter test test/pokedex_workspace_ui_test.dart --plain-name "imports a pokemon from API externe and refreshes the workspace"
```

### Git inspection

```text
git status --short
git diff --stat
git ls-files --others --exclude-standard
```

## 9. Résultats réels

### Analyze

```text
Analyzing 15 items...                                           
No issues found! (ran in 1.1s)
```

### Tests applicatifs

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart                                                             
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart                                                             
00:01 +0: ResolveExternalPokemonBatchSelectionUseCase returns empty without hitting the external repository                                                                                            
00:01 +1: ResolveExternalPokemonBatchSelectionUseCase returns empty without hitting the external repository                                                                                            
00:01 +1: ResolveExternalPokemonBatchSelectionUseCase returns out of scope for a mono-species query                                                                                                    
00:01 +2: ResolveExternalPokemonBatchSelectionUseCase returns out of scope for a mono-species query                                                                                                    
00:01 +2: ResolveExternalPokemonBatchSelectionUseCase resolves an explicit list with stable deduplication after mapping                                                                                
00:01 +3: ResolveExternalPokemonBatchSelectionUseCase resolves an explicit list with stable deduplication after mapping                                                                                
00:01 +3: ResolveExternalPokemonBatchSelectionUseCase resolves a dex range with base species only                                                                                                      
00:01 +4: ResolveExternalPokemonBatchSelectionUseCase resolves a dex range with base species only                                                                                                      
00:01 +4: ResolveExternalPokemonBatchSelectionUseCase resolves a generation with base species only and stable ordering                                                                                 
00:01 +5: ResolveExternalPokemonBatchSelectionUseCase resolves a generation with base species only and stable ordering                                                                                 
00:01 +5: ResolveExternalPokemonBatchSelectionUseCase reports unresolved explicit entries without dropping resolved ones                                                                               
00:01 +6: ResolveExternalPokemonBatchSelectionUseCase reports unresolved explicit entries without dropping resolved ones                                                                               
00:01 +6: ResolveExternalPokemonBatchSelectionUseCase returns no results for an unknown generation                                                                                                     
00:01 +7: ResolveExternalPokemonBatchSelectionUseCase returns no results for an unknown generation                                                                                                     
00:01 +7: ResolveExternalPokemonBatchSelectionUseCase maps repository failures to an error result                                                                                                      
00:01 +8: ResolveExternalPokemonBatchSelectionUseCase maps repository failures to an error result                                                                                                      
00:01 +8: All tests passed!                                                                                                                                                                            
```

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/provider_wiring_test.dart                                                                                               
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/provider_wiring_test.dart                                                                                               
00:01 +0: provider wiring resolves thematic controllers from a ProviderContainer                                                                                                                       
00:01 +1: provider wiring resolves thematic controllers from a ProviderContainer                                                                                                                       
00:01 +1: provider wiring derives selected narrative summaries from controller + projection                                                                                                            
00:01 +2: provider wiring derives selected narrative summaries from controller + projection                                                                                                            
00:01 +2: All tests passed!                                                                                                                                                                            
```

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart                                                                             
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart                                                                             
00:01 +0: BatchImportExternalPokemonSpeciesUseCase dry-run resolves a batch but writes nothing                                                                                                         
00:01 +0: BatchImportExternalPokemonSpeciesUseCase dry-run resolves a batch but writes nothing                                                                                                         
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/pokemon_external_import_project_dkmhtx/project.json

00:01 +1: BatchImportExternalPokemonSpeciesUseCase dry-run resolves a batch but writes nothing                                                                                                         
00:01 +1: All tests passed!                                                                                                                                                                            
```

### Tests UI

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart                                                                             
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart                                                                             
00:02 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart                                                                             
00:02 +0: switches to batch mode, resolves targets and unlocks dry-run                                                                                                                                 
00:03 +0: switches to batch mode, resolves targets and unlocks dry-run                                                                                                                                 
00:03 +1: switches to batch mode, resolves targets and unlocks dry-run                                                                                                                                 
00:03 +1: keeps dry-run blocked for out-of-scope mono queries                                                                                                                                          
00:03 +2: keeps dry-run blocked for out-of-scope mono queries                                                                                                                                          
00:03 +2: shows a dry-run preview and passes resolved species ids                                                                                                                                      
00:04 +2: shows a dry-run preview and passes resolved species ids                                                                                                                                      
00:04 +3: shows a dry-run preview and passes resolved species ids                                                                                                                                      
00:04 +3: All tests passed!                                                                                                                                                                            
```

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart                                                                              
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_autocomplete_ui_test.dart                                                                              
00:01 +0: shows loading then allows keyboard selection of a suggestion                                                                                                                                 
00:02 +0: shows loading then allows keyboard selection of a suggestion                                                                                                                                 
00:02 +1: shows loading then allows keyboard selection of a suggestion                                                                                                                                 
00:02 +1: shows a clean no-result state                                                                                                                                                                
00:02 +2: shows a clean no-result state                                                                                                                                                                
00:02 +2: shows a clean out-of-scope message for generation queries                                                                                                                                    
00:02 +3: shows a clean out-of-scope message for generation queries                                                                                                                                    
00:02 +3: shows a clean invalid message for ambiguous queries                                                                                                                                          
00:02 +4: shows a clean invalid message for ambiguous queries                                                                                                                                          
00:02 +4: All tests passed!                                                                                                                                                                            
```

```text

00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart                                                                                          
00:01 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_workspace_ui_test.dart                                                                                          
00:01 +0: imports a pokemon from API externe and refreshes the workspace                                                                                                                               
00:02 +0: imports a pokemon from API externe and refreshes the workspace                                                                                                                               
00:02 +1: imports a pokemon from API externe and refreshes the workspace                                                                                                                               
00:02 +1: All tests passed!                                                                                                                                                                            
```

## 10. Incidents rencontrés

### Incident 1 — commandes `flutter test` lancées en parallèle

Pendant une première tentative de validation, plusieurs commandes `flutter test` ont été lancées en parallèle. Flutter a pris le startup lock puis a rencontré des erreurs sur `macos/Flutter/ephemeral/Packages/.packages`.

Sorties réelles observées :

```text
Waiting for another flutter command to release the startup lock...
```

```text
Oops; flutter has exited unexpectedly: "PathExistsException: Cannot create link, path = '/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages/macos_window_utils' (OS Error: File exists, errno = 17)".
```

```text
Unable to delete file or directory at "/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages". This may be due to the project being in a read-only volume. Consider relocating the project and trying again.
```

Résolution :
- arrêt de la validation parallèle Flutter ;
- relance séquentielle de tous les tests ciblés ;
- validation finale obtenue proprement.

## 11. État git utile

### git status --short

```text
 M packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart
 M packages/map_editor/lib/src/application/use_cases/use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_body.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart
 M packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart
 M packages/map_editor/test/import_external_pokemon_use_cases_test.dart
 M packages/map_editor/test/provider_wiring_test.dart
?? packages/map_editor/lib/src/application/models/pokemon_external_batch_selection.dart
?? packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart
?? packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart
?? packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart
?? packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart
?? reports/phase-r1-lot-3-batch-selection-dry-run-report.md
```

### git diff --stat

```text
 .../app/providers/pokedex/pokedex_providers.dart   |  33 ++
 .../lib/src/application/use_cases/use_cases.dart   |   1 +
 .../pokedex_external_search_field.dart             |  12 +-
 .../pokedex_workspace/pokedex_import_flow.dart     | 279 +++++++++----
 .../pokedex_import_flow_steps.dart                 | 445 ++++++++++++++++++++-
 .../pokedex_workspace/pokedex_workspace_body.dart  |   2 +
 .../pokedex_workspace/pokedex_workspace_page.dart  |  19 +
 .../src/ui/canvas/pokedex_workspace_loader.dart    |  12 +
 .../import_external_pokemon_use_cases_test.dart    |  45 +++
 packages/map_editor/test/provider_wiring_test.dart |  13 +
 10 files changed, 766 insertions(+), 95 deletions(-)
```

### git ls-files --others --exclude-standard

```text
packages/map_editor/lib/src/application/models/pokemon_external_batch_selection.dart
packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart
packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart
packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart
packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart
reports/phase-r1-lot-3-batch-selection-dry-run-report.md
```

## 12. Checklist finale

- [x] mode `API externe` conserve un choix explicite mono / batch
- [x] le mode batch comprend liste explicite, plage dex et génération
- [x] la liste finale ciblée est visible avant le dry-run
- [x] le dry-run batch réutilise le batch applicatif existant
- [x] aucune écriture réelle n’a lieu pendant le dry-run
- [x] aucun import batch réel n’est proposé
- [x] le mono-espèce du lot 2 n’est pas cassé
- [x] aucun lot 4 n’a été anticipé
- [x] `dart format` exécuté
- [x] `flutter analyze --no-pub` exécuté et vert
- [x] `flutter test` ciblé exécuté et vert
- [x] aucun commit git n’a été fait

## 13. Annexe — contenu complet des fichiers texte modifiés / créés

Note explicite : le présent report n’est pas recopié intégralement dans sa propre annexe afin d’éviter une récursion infinie.

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/models/pokemon_external_batch_selection.dart`

```dart
import 'pokemon_external_query_resolution.dart';

/// Résultat structuré de la sélection batch externe.
///
/// Ce modèle existe pour un besoin produit précis du lot 3 :
/// - l'auteur peut saisir une requête batch ;
/// - l'application doit la comprendre et la résoudre en vraies cibles ;
/// - l'UI doit afficher cette résolution sans réinterpréter la requête.
///
/// Important :
/// - ce modèle ne représente pas encore un import réel ;
/// - ce modèle ne représente pas non plus le résultat du dry-run ;
/// - il ne fait qu'exprimer la sélection batch comprise par l'application.
enum PokemonExternalBatchSelectionResultKind {
  empty,
  resolved,
  invalidQuery,
  outOfScopeQuery,
  noResults,
  error,
}

/// Cible finale résolue pour une requête batch.
///
/// Une cible regroupe :
/// - l'espèce réellement ciblée ;
/// - ses informations utiles pour l'UI ;
/// - les entrées utilisateur qui ont conduit à cette cible.
///
/// Ce dernier point est important pour garder un dry-run honnête :
/// si `25, pikachu` résolvent tous deux vers `pikachu`, l'UI doit pouvoir le
/// montrer explicitement au lieu de faire disparaître le doublon sans trace.
class PokemonExternalBatchSelectionTarget {
  PokemonExternalBatchSelectionTarget({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    required List<String> requestedInputs,
    this.generation,
  }) : requestedInputs = List<String>.unmodifiable(requestedInputs);

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
  final List<String> requestedInputs;
}

/// Sélection batch structurée et déjà résolue autant que possible.
///
/// Le contrat reste volontairement explicite :
/// - `empty` : rien à interpréter ;
/// - `resolved` : la liste finale de cibles est exploitable ;
/// - `invalidQuery` : la requête est syntaxiquement ou sémantiquement refusée ;
/// - `outOfScopeQuery` : la requête relève d'un autre mode (mono-espèce) ;
/// - `noResults` : la forme est valide, mais aucune espèce cible n'est sortie ;
/// - `error` : l'infrastructure de résolution n'a pas pu répondre.
class PokemonExternalBatchSelectionResult {
  PokemonExternalBatchSelectionResult._({
    required this.kind,
    required this.rawQuery,
    required this.normalizedQuery,
    this.resolution,
    List<PokemonExternalBatchSelectionTarget> targets =
        const <PokemonExternalBatchSelectionTarget>[],
    this.message,
  }) : targets =
            List<PokemonExternalBatchSelectionTarget>.unmodifiable(targets);

  factory PokemonExternalBatchSelectionResult.empty({
    required String rawQuery,
    required String normalizedQuery,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.empty,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
    );
  }

  factory PokemonExternalBatchSelectionResult.resolved({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required List<PokemonExternalBatchSelectionTarget> targets,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.resolved,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }

  factory PokemonExternalBatchSelectionResult.invalidQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
    List<PokemonExternalBatchSelectionTarget> targets =
        const <PokemonExternalBatchSelectionTarget>[],
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.invalidQuery,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      targets: targets,
      message: message,
    );
  }

  factory PokemonExternalBatchSelectionResult.outOfScopeQuery({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.outOfScopeQuery,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      message: message,
    );
  }

  factory PokemonExternalBatchSelectionResult.noResults({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.noResults,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      message: message,
    );
  }

  factory PokemonExternalBatchSelectionResult.error({
    required String rawQuery,
    required String normalizedQuery,
    required PokemonExternalQueryResolution resolution,
    required String message,
  }) {
    return PokemonExternalBatchSelectionResult._(
      kind: PokemonExternalBatchSelectionResultKind.error,
      rawQuery: rawQuery,
      normalizedQuery: normalizedQuery,
      resolution: resolution,
      message: message,
    );
  }

  final PokemonExternalBatchSelectionResultKind kind;
  final String rawQuery;
  final String normalizedQuery;
  final PokemonExternalQueryResolution? resolution;
  final List<PokemonExternalBatchSelectionTarget> targets;
  final String? message;

  /// Le dry-run ne doit être déclenché que sur une sélection réellement
  /// exploitable : type `resolved` + au moins une cible.
  bool get canDryRun =>
      kind == PokemonExternalBatchSelectionResultKind.resolved &&
      targets.isNotEmpty;

  bool get hasTargets => targets.isNotEmpty;

  /// Liste stable des espèces réellement ciblées.
  ///
  /// Cette liste sert ensuite directement au batch applicatif existant,
  /// toujours sans réinterprétation UI de la requête.
  List<String> get resolvedSpeciesIds =>
      targets.map((target) => target.speciesId).toList(growable: false);

  /// Nombre total d'entrées utilisateur agrégées dans les cibles finales.
  int get requestedInputCount => targets.fold<int>(
        0,
        (count, target) => count + target.requestedInputs.length,
      );
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart`

```dart
import '../errors/application_errors.dart';
import '../models/pokemon_external_batch_selection.dart';
import '../models/pokemon_external_query_resolution.dart';
import '../ports/pokemon_external_source_repository.dart';
import '../services/pokemon_external_query_resolver.dart';

/// Résout une requête batch externe en vraies cibles Pokédex.
///
/// Ce use case répond exactement au besoin du lot 3 :
/// - réutiliser le résolveur du lot 1 ;
/// - accepter explicitement les formes batch prévues par la roadmap ;
/// - charger une source snapshot déjà branchée dans l'infrastructure ;
/// - produire une liste finale stable, dédupliquée et lisible.
///
/// Non-objectifs explicites :
/// - aucune écriture ;
/// - aucun dry-run d'import ici ;
/// - aucune logique UI ;
/// - aucun nouveau pipeline externe parallèle.
class ResolveExternalPokemonBatchSelectionUseCase {
  ResolveExternalPokemonBatchSelectionUseCase({
    required this.externalSourceRepository,
    required this.queryResolver,
  });

  final PokemonExternalSourceRepository externalSourceRepository;
  final PokemonExternalQueryResolver queryResolver;

  Future<_IndexedExternalBatchSpeciesSnapshot>? _cachedSnapshotFuture;

  Future<PokemonExternalBatchSelectionResult> execute(String rawQuery) async {
    final resolution = queryResolver.resolve(rawQuery);

    if (resolution is PokemonExternalInvalidQueryResolution) {
      if (resolution.code == PokemonExternalInvalidQueryCode.emptyQuery) {
        return PokemonExternalBatchSelectionResult.empty(
          rawQuery: resolution.rawQuery,
          normalizedQuery: resolution.normalizedQuery,
        );
      }
      return PokemonExternalBatchSelectionResult.invalidQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: resolution.message,
      );
    }

    if (resolution is PokemonExternalSingleQueryResolution) {
      return PokemonExternalBatchSelectionResult.outOfScopeQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Le mode batch attend une liste explicite, une plage Pokédex '
            'ou une génération.',
      );
    }

    try {
      final snapshotIndex = await _loadIndexedSnapshot();
      return switch (resolution) {
        PokemonExternalExplicitListQueryResolution explicitList =>
          _resolveExplicitList(snapshotIndex, explicitList),
        PokemonExternalNationalDexRangeQueryResolution range =>
          _resolveNationalDexRange(snapshotIndex, range),
        PokemonExternalGenerationQueryResolution generation =>
          _resolveGeneration(snapshotIndex, generation),
        PokemonExternalInvalidQueryResolution() ||
        PokemonExternalSingleQueryResolution() =>
          throw StateError('Unexpected resolution kind in batch resolver'),
      };
    } on EditorApplicationException catch (error) {
      return PokemonExternalBatchSelectionResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: error.message,
      );
    } catch (error) {
      return PokemonExternalBatchSelectionResult.error(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Résolution batch externe indisponible : $error',
      );
    }
  }

  Future<_IndexedExternalBatchSpeciesSnapshot> _loadIndexedSnapshot() {
    final cached = _cachedSnapshotFuture;
    if (cached != null) {
      return cached;
    }

    final future = () async {
      final snapshot =
          await externalSourceRepository.fetchShowdownPokedexSnapshot();
      return _IndexedExternalBatchSpeciesSnapshot.fromSnapshot(snapshot);
    }();

    _cachedSnapshotFuture = future;
    return future;
  }

  PokemonExternalBatchSelectionResult _resolveExplicitList(
    _IndexedExternalBatchSpeciesSnapshot snapshotIndex,
    PokemonExternalExplicitListQueryResolution resolution,
  ) {
    final unresolvedInputs = <String>[];
    final targetBuilders = <String, _BatchSelectionTargetBuilder>{};

    for (final query in resolution.queries) {
      final requestedInput = query.rawValue.trim();
      final resolvedSpecies = snapshotIndex.resolveExplicitQuery(query);
      if (resolvedSpecies == null) {
        unresolvedInputs.add(requestedInput);
        continue;
      }

      final builder = targetBuilders.putIfAbsent(
        resolvedSpecies.speciesId,
        () => _BatchSelectionTargetBuilder(
          speciesId: resolvedSpecies.speciesId,
          primaryName: resolvedSpecies.primaryName,
          nationalDex: resolvedSpecies.nationalDex,
          generation: resolvedSpecies.generation,
        ),
      );
      builder.addRequestedInput(requestedInput);
    }

    final targets = targetBuilders.values
        .map((builder) => builder.build())
        .toList(growable: false);

    if (targets.isEmpty) {
      return PokemonExternalBatchSelectionResult.noResults(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message:
            'Aucune espèce externe exploitable n’a été résolue pour cette liste.',
      );
    }

    if (unresolvedInputs.isNotEmpty) {
      final joinedInputs = unresolvedInputs.join(', ');
      return PokemonExternalBatchSelectionResult.invalidQuery(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        targets: targets,
        message: unresolvedInputs.length == 1
            ? 'Impossible de résoudre la cible batch `$joinedInputs`.'
            : 'Impossible de résoudre les cibles batch suivantes : '
                '$joinedInputs.',
      );
    }

    return PokemonExternalBatchSelectionResult.resolved(
      rawQuery: resolution.rawQuery,
      normalizedQuery: resolution.normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }

  PokemonExternalBatchSelectionResult _resolveNationalDexRange(
    _IndexedExternalBatchSpeciesSnapshot snapshotIndex,
    PokemonExternalNationalDexRangeQueryResolution resolution,
  ) {
    final targets = snapshotIndex
        .resolveNationalDexRange(
          startNationalDex: resolution.startNationalDex,
          endNationalDex: resolution.endNationalDex,
          requestedInput: resolution.normalizedQuery,
        )
        .toList(growable: false);

    if (targets.isEmpty) {
      return PokemonExternalBatchSelectionResult.noResults(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Aucune espèce de base n’a été trouvée pour cette plage '
            'Pokédex.',
      );
    }

    return PokemonExternalBatchSelectionResult.resolved(
      rawQuery: resolution.rawQuery,
      normalizedQuery: resolution.normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }

  PokemonExternalBatchSelectionResult _resolveGeneration(
    _IndexedExternalBatchSpeciesSnapshot snapshotIndex,
    PokemonExternalGenerationQueryResolution resolution,
  ) {
    final targets = snapshotIndex
        .resolveGeneration(
          generation: resolution.generation,
          requestedInput: resolution.normalizedQuery,
        )
        .toList(growable: false);

    if (targets.isEmpty) {
      return PokemonExternalBatchSelectionResult.noResults(
        rawQuery: resolution.rawQuery,
        normalizedQuery: resolution.normalizedQuery,
        resolution: resolution,
        message: 'Aucune espèce de base n’a été trouvée pour cette génération.',
      );
    }

    return PokemonExternalBatchSelectionResult.resolved(
      rawQuery: resolution.rawQuery,
      normalizedQuery: resolution.normalizedQuery,
      resolution: resolution,
      targets: targets,
    );
  }
}

class _IndexedExternalBatchSpeciesSnapshot {
  _IndexedExternalBatchSpeciesSnapshot({
    required this.baseEntries,
    required this.entriesBySpeciesId,
    required this.entriesByPrimaryName,
    required this.baseEntriesByNationalDex,
  });

  factory _IndexedExternalBatchSpeciesSnapshot.fromSnapshot(
    Map<String, dynamic> snapshot,
  ) {
    final baseEntries = <_IndexedExternalBatchSpeciesEntry>[];
    final entriesBySpeciesId = <String, _IndexedExternalBatchSpeciesEntry>{};
    final entriesByPrimaryName =
        <String, List<_IndexedExternalBatchSpeciesEntry>>{};
    final baseEntriesByNationalDex = <int, _IndexedExternalBatchSpeciesEntry>{};

    for (final entry in snapshot.entries) {
      final rawPayload = entry.value;
      if (rawPayload is! Map) {
        continue;
      }

      final speciesId = entry.key.trim().toLowerCase();
      if (speciesId.isEmpty) {
        continue;
      }

      final payload = rawPayload.cast<String, dynamic>();
      final nationalDex = (payload['num'] as num?)?.toInt() ?? 0;
      if (nationalDex <= 0) {
        continue;
      }

      final primaryName = (payload['name'] as String?)?.trim();
      if (primaryName == null || primaryName.isEmpty) {
        continue;
      }

      final generation = (payload['gen'] as num?)?.toInt();
      final baseSpecies = (payload['baseSpecies'] as String?)?.trim();
      final normalizedSpeciesId = _normalizeLookupToken(speciesId);
      final normalizedPrimaryName = _normalizeLookupToken(primaryName);
      final normalizedBaseSpecies = baseSpecies == null || baseSpecies.isEmpty
          ? null
          : _normalizeLookupToken(baseSpecies);
      final isBaseSpecies =
          normalizedBaseSpecies == null || normalizedBaseSpecies.isEmpty;

      final indexedEntry = _IndexedExternalBatchSpeciesEntry(
        speciesId: speciesId,
        primaryName: primaryName,
        nationalDex: nationalDex,
        generation: generation,
        normalizedSpeciesId: normalizedSpeciesId,
        normalizedPrimaryName: normalizedPrimaryName,
        isBaseSpecies: isBaseSpecies,
      );

      entriesBySpeciesId[normalizedSpeciesId] = indexedEntry;
      entriesByPrimaryName
          .putIfAbsent(
            normalizedPrimaryName,
            () => <_IndexedExternalBatchSpeciesEntry>[],
          )
          .add(indexedEntry);

      if (isBaseSpecies) {
        // Les requêtes batch par génération/plage/dex doivent rester lisibles
        // et stables. On n'y injecte donc pas les formes Showdown qui partagent
        // le même numéro Pokédex que leur espèce de base.
        baseEntries.add(indexedEntry);
        baseEntriesByNationalDex[nationalDex] = indexedEntry;
      }
    }

    baseEntries.sort((left, right) {
      final dexCompare = left.nationalDex.compareTo(right.nationalDex);
      if (dexCompare != 0) {
        return dexCompare;
      }
      return left.speciesId.compareTo(right.speciesId);
    });

    return _IndexedExternalBatchSpeciesSnapshot(
      baseEntries: List<_IndexedExternalBatchSpeciesEntry>.unmodifiable(
        baseEntries,
      ),
      entriesBySpeciesId:
          Map<String, _IndexedExternalBatchSpeciesEntry>.unmodifiable(
        entriesBySpeciesId,
      ),
      entriesByPrimaryName:
          Map<String, List<_IndexedExternalBatchSpeciesEntry>>.unmodifiable(
        entriesByPrimaryName.map(
          (key, value) =>
              MapEntry<String, List<_IndexedExternalBatchSpeciesEntry>>(
            key,
            List<_IndexedExternalBatchSpeciesEntry>.unmodifiable(value),
          ),
        ),
      ),
      baseEntriesByNationalDex:
          Map<int, _IndexedExternalBatchSpeciesEntry>.unmodifiable(
        baseEntriesByNationalDex,
      ),
    );
  }

  final List<_IndexedExternalBatchSpeciesEntry> baseEntries;
  final Map<String, _IndexedExternalBatchSpeciesEntry> entriesBySpeciesId;
  final Map<String, List<_IndexedExternalBatchSpeciesEntry>>
      entriesByPrimaryName;
  final Map<int, _IndexedExternalBatchSpeciesEntry> baseEntriesByNationalDex;

  _IndexedExternalBatchSpeciesEntry? resolveExplicitQuery(
    PokemonExternalSingleQuery query,
  ) {
    return switch (query.kind) {
      PokemonExternalSingleQueryKind.nationalDex =>
        baseEntriesByNationalDex[query.nationalDex],
      PokemonExternalSingleQueryKind.species =>
        _resolveExplicitSpeciesQuery(query.normalizedValue!),
    };
  }

  Iterable<PokemonExternalBatchSelectionTarget> resolveNationalDexRange({
    required int startNationalDex,
    required int endNationalDex,
    required String requestedInput,
  }) sync* {
    for (final entry in baseEntries) {
      if (entry.nationalDex < startNationalDex ||
          entry.nationalDex > endNationalDex) {
        continue;
      }
      yield entry.toSelectionTarget(
        requestedInputs: <String>[requestedInput],
      );
    }
  }

  Iterable<PokemonExternalBatchSelectionTarget> resolveGeneration({
    required int generation,
    required String requestedInput,
  }) sync* {
    for (final entry in baseEntries) {
      if (entry.generation != generation) {
        continue;
      }
      yield entry.toSelectionTarget(
        requestedInputs: <String>[requestedInput],
      );
    }
  }

  _IndexedExternalBatchSpeciesEntry? _resolveExplicitSpeciesQuery(
    String normalizedValue,
  ) {
    final exactSpeciesIdMatch = entriesBySpeciesId[normalizedValue];
    if (exactSpeciesIdMatch != null) {
      return exactSpeciesIdMatch;
    }

    final exactNameMatches = entriesByPrimaryName[normalizedValue];
    if (exactNameMatches == null || exactNameMatches.isEmpty) {
      return null;
    }
    if (exactNameMatches.length == 1) {
      return exactNameMatches.single;
    }

    final baseMatch = exactNameMatches.where((entry) => entry.isBaseSpecies);
    if (baseMatch.length == 1) {
      return baseMatch.single;
    }

    return null;
  }

  static String _normalizeLookupToken(String rawValue) {
    final lowered = rawValue.trim().toLowerCase();
    return lowered.replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }
}

class _IndexedExternalBatchSpeciesEntry {
  const _IndexedExternalBatchSpeciesEntry({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    required this.generation,
    required this.normalizedSpeciesId,
    required this.normalizedPrimaryName,
    required this.isBaseSpecies,
  });

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
  final String normalizedSpeciesId;
  final String normalizedPrimaryName;
  final bool isBaseSpecies;

  PokemonExternalBatchSelectionTarget toSelectionTarget({
    required List<String> requestedInputs,
  }) {
    return PokemonExternalBatchSelectionTarget(
      speciesId: speciesId,
      primaryName: primaryName,
      nationalDex: nationalDex,
      generation: generation,
      requestedInputs: requestedInputs,
    );
  }
}

class _BatchSelectionTargetBuilder {
  _BatchSelectionTargetBuilder({
    required this.speciesId,
    required this.primaryName,
    required this.nationalDex,
    required this.generation,
  });

  final String speciesId;
  final String primaryName;
  final int nationalDex;
  final int? generation;
  final List<String> _requestedInputs = <String>[];

  void addRequestedInput(String input) {
    if (input.isEmpty || _requestedInputs.contains(input)) {
      return;
    }
    _requestedInputs.add(input);
  }

  PokemonExternalBatchSelectionTarget build() {
    return PokemonExternalBatchSelectionTarget(
      speciesId: speciesId,
      primaryName: primaryName,
      nationalDex: nationalDex,
      generation: generation,
      requestedInputs: _requestedInputs,
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/app/providers/pokedex/pokedex_providers.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

import '../../../application/ports/pokemon_read_repository.dart';
import '../../../application/ports/pokemon_external_source_repository.dart';
import '../../../application/ports/pokemon_write_repository.dart';
import '../../../application/services/pokemon_database_index.dart';
import '../../../application/services/pokemon_external_query_resolver.dart';
import '../../../application/use_cases/import_external_pokemon_use_cases.dart';
import '../../../application/use_cases/import_pokemon_evolution_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_json_bundle_use_case.dart';
import '../../../application/use_cases/import_pokemon_learnset_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_media_json_use_case.dart';
import '../../../application/use_cases/import_pokemon_species_json_use_case.dart';
import '../../../application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart';
import '../../../application/use_cases/search_external_pokemon_species_use_case.dart';
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

/// Résolveur de requête brute -> intention structurée pour l'import externe.
///
/// Ce provider est volontairement minimal pour le lot 1 :
/// - il expose une logique pure ;
/// - il n'ajoute ni réseau, ni preview, ni import ;
/// - il prépare simplement le wiring propre des lots UI suivants.
final pokemonExternalQueryResolverProvider =
    Provider<PokemonExternalQueryResolver>((ref) {
  return const PokemonExternalQueryResolver();
});

/// Recherche mono-espèce appliquée au wizard Pokédex.
///
/// On garde cette couche très petite :
/// - elle réutilise le résolveur du lot 1 ;
/// - elle réutilise le port externe déjà en place ;
/// - elle ne crée pas de pipeline de recherche parallèle.
final searchExternalPokemonSpeciesUseCaseProvider =
    Provider<SearchExternalPokemonSpeciesUseCase>((ref) {
  return SearchExternalPokemonSpeciesUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    queryResolver: ref.watch(pokemonExternalQueryResolverProvider),
  );
});

final pokedexExternalSpeciesSearcherProvider =
    Provider<PokedexExternalSpeciesSearcher>((ref) {
  final useCase = ref.watch(searchExternalPokemonSpeciesUseCaseProvider);
  return useCase.execute;
});

/// Résolution batch structurée pour le wizard `API externe`.
///
/// On reste sur le même pattern que le lot 2 :
/// - résolveur lot 1 réutilisé ;
/// - snapshot externe déjà branché ;
/// - aucune pile batch concurrente dans l'UI.
final resolveExternalPokemonBatchSelectionUseCaseProvider =
    Provider<ResolveExternalPokemonBatchSelectionUseCase>((ref) {
  return ResolveExternalPokemonBatchSelectionUseCase(
    externalSourceRepository:
        ref.watch(pokemonExternalSourceRepositoryProvider),
    queryResolver: ref.watch(pokemonExternalQueryResolverProvider),
  );
});

final pokedexExternalBatchSelectionResolverProvider =
    Provider<PokedexExternalBatchSelectionResolver>((ref) {
  final useCase =
      ref.watch(resolveExternalPokemonBatchSelectionUseCaseProvider);
  return useCase.execute;
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

final pokedexExternalBatchPreviewerProvider =
    Provider<PokedexExternalBatchPreviewer>((ref) {
  final useCase = ref.watch(batchImportExternalPokemonSpeciesUseCaseProvider);
  return (workspace, speciesIds) => useCase.execute(
        workspace,
        speciesIds: speciesIds,
        dryRun: true,
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
export 'resolve_external_pokemon_batch_selection_use_case.dart';
export 'seed_pokemon_demo_data_use_case.dart';
export 'search_external_pokemon_species_use_case.dart';
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace_loader.dart`

```dart
import 'dart:io';

import '../../application/models/pokemon_database_index.dart';
import '../../application/models/pokemon_external_batch_selection.dart';
import '../../application/models/pokemon_external_species_search_result.dart';
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

typedef PokedexExternalSpeciesSearcher
    = Future<PokemonExternalSpeciesSearchResult> Function(
  String rawQuery,
);

typedef PokedexExternalBatchSelectionResolver
    = Future<PokemonExternalBatchSelectionResult> Function(
  String rawQuery,
);

typedef PokedexExternalBatchPreviewer = Future<PokemonExternalBatchImportResult>
    Function(
  ProjectWorkspace workspace,
  List<String> speciesIds,
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
import '../../../application/models/pokemon_external_batch_selection.dart';
import '../../../application/models/pokemon_external_species_search_result.dart';
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
part 'pokedex_external_batch_field.dart';
part 'pokedex_external_search_field.dart';
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
    this.externalSpeciesSearcher,
    this.externalBatchSelectionResolver,
    this.externalBatchPreviewer,
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
  final PokedexExternalSpeciesSearcher? externalSpeciesSearcher;
  final PokedexExternalBatchSelectionResolver? externalBatchSelectionResolver;
  final PokedexExternalBatchPreviewer? externalBatchPreviewer;
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
    final PokedexExternalSpeciesSearcher resolvedExternalSpeciesSearcher =
        externalSpeciesSearcher ??
            ref.watch(pokedexExternalSpeciesSearcherProvider);
    final PokedexExternalBatchSelectionResolver
        resolvedExternalBatchSelectionResolver =
        externalBatchSelectionResolver ??
            ref.watch(pokedexExternalBatchSelectionResolverProvider);
    final PokedexExternalBatchPreviewer resolvedExternalBatchPreviewer =
        externalBatchPreviewer ??
            ref.watch(pokedexExternalBatchPreviewerProvider);
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
      externalSpeciesSearcher: resolvedExternalSpeciesSearcher,
      externalBatchSelectionResolver: resolvedExternalBatchSelectionResolver,
      externalBatchPreviewer: resolvedExternalBatchPreviewer,
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
    required this.externalSpeciesSearcher,
    required this.externalBatchSelectionResolver,
    required this.externalBatchPreviewer,
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
  final PokedexExternalSpeciesSearcher externalSpeciesSearcher;
  final PokedexExternalBatchSelectionResolver externalBatchSelectionResolver;
  final PokedexExternalBatchPreviewer externalBatchPreviewer;
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
      searchExternalSpecies: widget.externalSpeciesSearcher,
      resolveExternalBatchSelection: widget.externalBatchSelectionResolver,
      previewExternalImport: widget.externalImportPreviewer,
      previewExternalBatchImport: widget.externalBatchPreviewer,
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Orchestration unique du flow d'import Pokédex.
//
// Cette feuille modale reste volontairement la seule porte d'entrée UI pour
// les imports Pokédex :
// - source locale JSON ;
// - source produit `API externe` ;
// - aperçu avant write ;
// - confirmation finale.
//
// Toute la logique métier reste hors des widgets :
// - l'UI choisit une source et affiche un résumé ;
// - les providers injectés appellent les use cases existants ;
// - aucun parsing JSON ou HTTP ne vit ici.

Future<_CompletedPokedexImportFlowResult?> _showPokedexImportFlowSheet({
  required BuildContext context,
  required ProjectWorkspace workspace,
  required PokedexImportPreviewer previewImport,
  required PokedexImporter importPokemon,
  required PokedexExternalSpeciesSearcher searchExternalSpecies,
  required PokedexExternalBatchSelectionResolver resolveExternalBatchSelection,
  required PokedexExternalImportPreviewer previewExternalImport,
  required PokedexExternalBatchPreviewer previewExternalBatchImport,
  required PokedexExternalImporter importExternalPokemon,
  Future<String?> Function()? pickJsonSourceFile,
}) {
  return showMacosEditorTallSheet<_CompletedPokedexImportFlowResult>(
    context: context,
    maxWidth: 760,
    builder: (sheetContext) => _PokedexImportFlowSheet(
      workspace: workspace,
      previewImport: previewImport,
      importPokemon: importPokemon,
      searchExternalSpecies: searchExternalSpecies,
      resolveExternalBatchSelection: resolveExternalBatchSelection,
      previewExternalImport: previewExternalImport,
      previewExternalBatchImport: previewExternalBatchImport,
      importExternalPokemon: importExternalPokemon,
      pickJsonSourceFile: pickJsonSourceFile ?? _pickPokedexJsonSourceFile,
    ),
  );
}

Future<String?> _pickPokedexJsonSourceFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['json'],
    withData: false,
  );
  final pickedPath = result?.files.single.path;
  if (pickedPath == null) {
    return null;
  }
  await _beginPokedexImportBundleAccessIfNeeded(pickedPath);
  return pickedPath;
}

Future<void> _beginPokedexImportBundleAccessIfNeeded(
    String selectedPath) async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'beginImportBundleAccess',
      <String, String>{'selectedPath': selectedPath},
    );
  } catch (_) {
    // Best effort only.
  }
}

Future<void> _endPokedexImportBundleAccessIfNeeded() async {
  if (defaultTargetPlatform != TargetPlatform.macOS) {
    return;
  }
  try {
    await _macOsImportFileAccessChannel.invokeMethod<void>(
      'endImportBundleAccess',
    );
  } catch (_) {
    // Best effort only.
  }
}

enum _PokedexImportSourceKind {
  jsonLocal,
  externalApi,
}

enum _PokedexExternalImportMode {
  singleSpecies,
  batchDryRun,
}

enum _PokedexImportWizardStep {
  source,
  jsonFile,
  externalQuery,
  preview,
}

class _CompletedPokedexImportFlowResult {
  const _CompletedPokedexImportFlowResult({
    required this.speciesId,
    required this.primaryName,
    required this.importedLearnset,
    required this.importedEvolution,
    required this.importedMedia,
    this.downloadedAssetCount = 0,
  });

  final String speciesId;
  final String primaryName;
  final bool importedLearnset;
  final bool importedEvolution;
  final bool importedMedia;
  final int downloadedAssetCount;
}

// Le wizard reste séquentiel et local à la présentation.
//
// On ne crée pas de route dédiée ni de state container global :
// - un petit état d'écran pour la progression du modal ;
// - des callbacks injectés pour les use cases ;
// - une seule source de vérité métier dans les résultats applicatifs.
class _PokedexImportFlowSheet extends StatefulWidget {
  const _PokedexImportFlowSheet({
    required this.workspace,
    required this.previewImport,
    required this.importPokemon,
    required this.searchExternalSpecies,
    required this.resolveExternalBatchSelection,
    required this.previewExternalImport,
    required this.previewExternalBatchImport,
    required this.importExternalPokemon,
    required this.pickJsonSourceFile,
  });

  final ProjectWorkspace workspace;
  final PokedexImportPreviewer previewImport;
  final PokedexImporter importPokemon;
  final PokedexExternalSpeciesSearcher searchExternalSpecies;
  final PokedexExternalBatchSelectionResolver resolveExternalBatchSelection;
  final PokedexExternalImportPreviewer previewExternalImport;
  final PokedexExternalBatchPreviewer previewExternalBatchImport;
  final PokedexExternalImporter importExternalPokemon;
  final Future<String?> Function() pickJsonSourceFile;

  @override
  State<_PokedexImportFlowSheet> createState() =>
      _PokedexImportFlowSheetState();
}

class _PokedexImportFlowSheetState extends State<_PokedexImportFlowSheet> {
  _PokedexImportWizardStep _step = _PokedexImportWizardStep.source;
  _PokedexImportSourceKind _selectedSource = _PokedexImportSourceKind.jsonLocal;
  _PokedexExternalImportMode _externalImportMode =
      _PokedexExternalImportMode.singleSpecies;
  String? _selectedJsonSourcePath;
  PokemonJsonImportPreview? _jsonPreview;
  PokemonExternalImportResult? _externalPreview;
  PokemonExternalBatchImportResult? _externalBatchPreview;
  bool _isBusy = false;
  bool _isSearchingExternalSpecies = false;
  bool _isResolvingExternalBatch = false;
  String? _errorMessage;
  late final TextEditingController _externalQueryController;
  late final FocusNode _externalQueryFocusNode;
  Timer? _externalQueryDebounceTimer;
  int _externalQuerySearchRequestId = 0;
  PokemonExternalSpeciesSearchResult _externalSpeciesSearchResult =
      const PokemonExternalSpeciesSearchResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalBatchSelectionResult _externalBatchSelectionResult =
      PokemonExternalBatchSelectionResult.empty(
    rawQuery: '',
    normalizedQuery: '',
  );
  PokemonExternalSpeciesSuggestion? _selectedExternalSuggestion;

  @override
  void initState() {
    super.initState();
    _externalQueryController = TextEditingController();
    _externalQueryFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _externalQueryDebounceTimer?.cancel();
    _externalQueryController.dispose();
    _externalQueryFocusNode.dispose();
    unawaited(_endPokedexImportBundleAccessIfNeeded());
    super.dispose();
  }

  Future<void> _pickJsonSource() async {
    final pickedPath = await widget.pickJsonSourceFile();
    if (!mounted || pickedPath == null) {
      return;
    }
    setState(() {
      _selectedJsonSourcePath = pickedPath;
      _errorMessage = null;
    });
  }

  void _handleExternalModeChanged(_PokedexExternalImportMode mode) {
    if (_externalImportMode == mode) {
      return;
    }

    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _externalImportMode = mode;
      _selectedExternalSuggestion = null;
      _externalPreview = null;
      _externalBatchPreview = null;
      _errorMessage = null;
      _isSearchingExternalSpecies = false;
      _isResolvingExternalBatch = false;
      if (mode == _PokedexExternalImportMode.singleSpecies) {
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: _externalQueryController.text,
          normalizedQuery: _externalQueryController.text.trim(),
        );
      } else {
        _externalSpeciesSearchResult =
            const PokemonExternalSpeciesSearchResult.empty(
          rawQuery: '',
          normalizedQuery: '',
        );
      }
    });

    _handleExternalQueryChanged(_externalQueryController.text);
  }

  void _handleExternalQueryChanged(String rawQuery) {
    _externalQueryDebounceTimer?.cancel();
    final normalizedQuery = rawQuery.trim();

    if (normalizedQuery.isEmpty) {
      setState(() {
        _selectedExternalSuggestion = null;
        _isSearchingExternalSpecies = false;
        _isResolvingExternalBatch = false;
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
        _externalPreview = null;
        _externalBatchPreview = null;
        _errorMessage = null;
      });
      return;
    }

    final requestId = ++_externalQuerySearchRequestId;
    setState(() {
      _selectedExternalSuggestion = null;
      _externalPreview = null;
      _externalBatchPreview = null;
      _isSearchingExternalSpecies =
          _externalImportMode == _PokedexExternalImportMode.singleSpecies;
      _isResolvingExternalBatch =
          _externalImportMode == _PokedexExternalImportMode.batchDryRun;
      if (_externalImportMode == _PokedexExternalImportMode.singleSpecies) {
        _externalSpeciesSearchResult = PokemonExternalSpeciesSearchResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
      } else {
        _externalBatchSelectionResult =
            PokemonExternalBatchSelectionResult.empty(
          rawQuery: rawQuery,
          normalizedQuery: normalizedQuery,
        );
      }
      _errorMessage = null;
    });

    final requestedMode = _externalImportMode;

    // Un petit debounce UI suffit ici :
    // - il évite de re-solliciter la résolution à chaque caractère ;
    // - il ne déplace aucune logique métier dans l'UI ;
    // - le vrai contrat reste porté par les use cases injectés.
    _externalQueryDebounceTimer =
        Timer(const Duration(milliseconds: 180), () async {
      if (requestedMode == _PokedexExternalImportMode.singleSpecies) {
        final result = await widget.searchExternalSpecies(rawQuery);
        if (!mounted || requestId != _externalQuerySearchRequestId) {
          return;
        }
        setState(() {
          _isSearchingExternalSpecies = false;
          _externalSpeciesSearchResult = result;
        });
        return;
      }

      final result = await widget.resolveExternalBatchSelection(rawQuery);
      if (!mounted || requestId != _externalQuerySearchRequestId) {
        return;
      }
      setState(() {
        _isResolvingExternalBatch = false;
        _externalBatchSelectionResult = result;
      });
    });
  }

  void _handleExternalSuggestionSelected(
    PokemonExternalSpeciesSuggestion suggestion,
  ) {
    _externalQueryDebounceTimer?.cancel();
    _externalQuerySearchRequestId += 1;
    setState(() {
      _selectedExternalSuggestion = suggestion;
      _isSearchingExternalSpecies = false;
      _errorMessage = null;
    });
  }

  Future<void> _loadPreview() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final preview = await widget.previewImport(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          setState(() {
            _jsonPreview = preview;
            _externalPreview = null;
            _step = _PokedexImportWizardStep.preview;
            _isBusy = false;
          });
          break;
        case _PokedexImportSourceKind.externalApi:
          switch (_externalImportMode) {
            case _PokedexExternalImportMode.singleSpecies:
              final selectedSuggestion = _selectedExternalSuggestion;
              if (selectedSuggestion == null) {
                throw const EditorValidationException(
                  'Sélectionnez explicitement une espèce externe avant de prévisualiser.',
                );
              }
              final preview = await widget.previewExternalImport(
                widget.workspace,
                selectedSuggestion.speciesId,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _externalPreview = preview;
                _externalBatchPreview = null;
                _jsonPreview = null;
                _step = _PokedexImportWizardStep.preview;
                _isBusy = false;
              });
              break;
            case _PokedexExternalImportMode.batchDryRun:
              final selection = _externalBatchSelectionResult;
              if (!selection.canDryRun) {
                throw const EditorValidationException(
                  'Résolvez d’abord une sélection batch valide avant de lancer le dry-run.',
                );
              }
              final preview = await widget.previewExternalBatchImport(
                widget.workspace,
                selection.resolvedSpeciesIds,
              );
              if (!mounted) {
                return;
              }
              setState(() {
                _externalBatchPreview = preview;
                _externalPreview = null;
                _jsonPreview = null;
                _step = _PokedexImportWizardStep.preview;
                _isBusy = false;
              });
              break;
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  Future<void> _confirmImport() async {
    setState(() {
      _isBusy = true;
      _errorMessage = null;
    });

    try {
      switch (_selectedSource) {
        case _PokedexImportSourceKind.jsonLocal:
          final sourcePath = _selectedJsonSourcePath?.trim();
          if (sourcePath == null || sourcePath.isEmpty) {
            throw const EditorValidationException(
              'Sélectionnez un fichier JSON à importer.',
            );
          }
          final result = await widget.importPokemon(
            widget.workspace,
            sourcePath,
          );
          if (!mounted) {
            return;
          }
          Navigator.of(context).pop(
            _CompletedPokedexImportFlowResult(
              speciesId: result.preview.speciesId,
              primaryName: result.preview.primaryName,
              importedLearnset: result.importedLearnset,
              importedEvolution: result.importedEvolution,
              importedMedia: result.importedMedia,
            ),
          );
          break;
        case _PokedexImportSourceKind.externalApi:
          switch (_externalImportMode) {
            case _PokedexExternalImportMode.singleSpecies:
              final selectedSuggestion = _selectedExternalSuggestion;
              if (selectedSuggestion == null) {
                throw const EditorValidationException(
                  'Sélectionnez explicitement une espèce externe avant d’importer.',
                );
              }
              final result = await widget.importExternalPokemon(
                widget.workspace,
                selectedSuggestion.speciesId,
              );
              if (!mounted) {
                return;
              }
              if (result.hasConflicts) {
                setState(() {
                  _isBusy = false;
                  _externalPreview = result;
                  _errorMessage =
                      'Des fichiers existent déjà pour cette espèce. L’import externe reste volontairement prudent et ne remplace rien dans cette phase.';
                });
                return;
              }
              Navigator.of(context).pop(
                _CompletedPokedexImportFlowResult(
                  speciesId: result.preview.speciesId,
                  primaryName: result.preview.primaryName,
                  importedLearnset: result.importedLearnset,
                  importedEvolution: result.importedEvolution,
                  importedMedia: result.importedMedia,
                  downloadedAssetCount: result.downloadedAssetCount,
                ),
              );
              break;
            case _PokedexExternalImportMode.batchDryRun:
              throw const EditorValidationException(
                'Le lot 3 ne permet pas encore l’import batch réel. Seul le dry-run batch est disponible dans cette étape.',
              );
          }
          break;
      }
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBusy = false;
        _errorMessage = _resolveApplicationMessage(error);
      });
    }
  }

  String _resolveApplicationMessage(Object error) {
    return switch (error) {
      final EditorApplicationException applicationError =>
        applicationError.message,
      _ => error.toString(),
    };
  }

  void _continueFromSource() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  void _goBackFromPreview() {
    setState(() {
      _errorMessage = null;
      _step = switch (_selectedSource) {
        _PokedexImportSourceKind.jsonLocal => _PokedexImportWizardStep.jsonFile,
        _PokedexImportSourceKind.externalApi =>
          _PokedexImportWizardStep.externalQuery,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    // Le sheet macOS fournit le cadre général, mais pas de marge interne forte.
    // On ajoute donc ici un padding commun à tout le wizard :
    // - même respiration sur chaque étape ;
    // - aucun besoin de répéter des `Padding` différents dans chaque widget ;
    // - correction purement visuelle, sans toucher à la logique du flow.
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
      child: switch (_step) {
        _PokedexImportWizardStep.source => _PokedexImportSourceStep(
            selectedSource: _selectedSource,
            onSourceSelected: (value) {
              setState(() {
                _selectedSource = value;
                _errorMessage = null;
              });
            },
            onContinue: _continueFromSource,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.jsonFile => _PokedexImportJsonFileStep(
            selectedJsonSourcePath: _selectedJsonSourcePath,
            isBusy: _isBusy,
            errorMessage: _errorMessage,
            onPickJsonSource: _pickJsonSource,
            onContinue: _loadPreview,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.externalQuery =>
          _PokedexImportExternalQueryStep(
            externalImportMode: _externalImportMode,
            controller: _externalQueryController,
            focusNode: _externalQueryFocusNode,
            isBusy: _isBusy,
            isSearching: _isSearchingExternalSpecies,
            isResolvingBatch: _isResolvingExternalBatch,
            errorMessage: _errorMessage,
            searchResult: _externalSpeciesSearchResult,
            batchSelectionResult: _externalBatchSelectionResult,
            selectedSuggestion: _selectedExternalSuggestion,
            onModeChanged: _handleExternalModeChanged,
            onQueryChanged: _handleExternalQueryChanged,
            onSuggestionSelected: _handleExternalSuggestionSelected,
            onContinue: _loadPreview,
            onCancel: () => Navigator.of(context).pop(),
          ),
        _PokedexImportWizardStep.preview => switch (_selectedSource) {
            _PokedexImportSourceKind.jsonLocal => _PokedexImportPreviewStep(
                preview: _jsonPreview!,
                isBusy: _isBusy,
                errorMessage: _errorMessage,
                onBack: _goBackFromPreview,
                onImport: _confirmImport,
              ),
            _PokedexImportSourceKind.externalApi => switch (
                  _externalImportMode) {
                _PokedexExternalImportMode.singleSpecies =>
                  _PokedexExternalImportPreviewStep(
                    preview: _externalPreview!,
                    isBusy: _isBusy,
                    errorMessage: _errorMessage,
                    onBack: _goBackFromPreview,
                    onImport: _confirmImport,
                  ),
                _PokedexExternalImportMode.batchDryRun =>
                  _PokedexExternalBatchPreviewStep(
                    selection: _externalBatchSelectionResult,
                    preview: _externalBatchPreview!,
                    errorMessage: _errorMessage,
                    onBack: _goBackFromPreview,
                    onClose: () => Navigator.of(context).pop(),
                  ),
              },
          },
      },
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_import_flow_steps.dart`

```dart
part of 'pokedex_workspace_page.dart';

// Étapes visuelles du wizard d'import.
//
// Chaque widget ici reste strictement présentation :
// - aucun accès disque ;
// - aucun accès HTTP ;
// - aucune validation métier ;
// - seulement du wording, de la hiérarchie visuelle et des callbacks.

class _PokedexImportSourceStep extends StatelessWidget {
  const _PokedexImportSourceStep({
    required this.selectedSource,
    required this.onSourceSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexImportSourceKind selectedSource;
  final ValueChanged<_PokedexImportSourceKind> onSourceSelected;
  final VoidCallback onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-source-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Importer des Pokémon',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Choisissez la source qui vous convient. Le parcours reste volontairement simple : une source, un aperçu honnête, puis un import dans le projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir une source',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-json-source-card'),
          title: 'Fichier JSON',
          icon: CupertinoIcons.doc_text_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.jsonLocal,
          onPressed: () => onSourceSelected(_PokedexImportSourceKind.jsonLocal),
        ),
        const SizedBox(height: 10),
        _PokedexImportSourceCard(
          cardKey: const Key('pokedex-import-external-api-source-card'),
          title: 'API externe',
          icon: CupertinoIcons.cloud_fill,
          isSelected: selectedSource == _PokedexImportSourceKind.externalApi,
          trailingLabel: 'Live',
          onPressed: () =>
              onSourceSelected(_PokedexImportSourceKind.externalApi),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-source-continue-button'),
              controlSize: ControlSize.large,
              onPressed: onContinue,
              child: const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportJsonFileStep extends StatelessWidget {
  const _PokedexImportJsonFileStep({
    required this.selectedJsonSourcePath,
    required this.isBusy,
    required this.errorMessage,
    required this.onPickJsonSource,
    required this.onContinue,
    required this.onCancel,
  });

  final String? selectedJsonSourcePath;
  final bool isBusy;
  final String? errorMessage;
  final Future<void> Function() onPickJsonSource;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final subtle = EditorChrome.subtleLabel(context);
    final hasFile = selectedJsonSourcePath?.trim().isNotEmpty == true;
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: subtle,
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-json-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis fichier JSON',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Sélectionnez le fichier espèce à importer. L’aperçu vous montrera ensuite ce qui sera ajouté au projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Choisir un fichier',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        CupertinoButton(
          key: const Key('pokedex-import-pick-json-file-button'),
          color: EditorChrome.accentJade.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          onPressed: isBusy ? null : onPickJsonSource,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.folder_open, size: 18),
              SizedBox(width: 8),
              Text('Choisir un fichier'),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          key: const Key('pokedex-import-selected-file'),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Text(
            hasFile
                ? p.basename(selectedJsonSourcePath!)
                : 'Aucun fichier sélectionné',
            style: TextStyle(
              color: hasFile ? CupertinoColors.white : subtle,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-json-continue-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onContinue,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Continuer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexImportExternalQueryStep extends StatelessWidget {
  const _PokedexImportExternalQueryStep({
    required this.externalImportMode,
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.isResolvingBatch,
    required this.errorMessage,
    required this.searchResult,
    required this.batchSelectionResult,
    required this.selectedSuggestion,
    required this.onModeChanged,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
    required this.onContinue,
    required this.onCancel,
  });

  final _PokedexExternalImportMode externalImportMode;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final bool isResolvingBatch;
  final String? errorMessage;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalBatchSelectionResult batchSelectionResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<_PokedexExternalImportMode> onModeChanged;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;
  final Future<void> Function() onContinue;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-external-query-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Import depuis API externe',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'La source produit reste “API externe”. Choisissez ensuite explicitement un mode mono-espèce ou batch dry-run selon le besoin.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        Text(
          'Mode de requête',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        _PokedexExternalImportModeSegmentedControl(
          selectedMode: externalImportMode,
          onModeChanged: isBusy ? null : onModeChanged,
        ),
        const SizedBox(height: 20),
        Text(
          externalImportMode == _PokedexExternalImportMode.singleSpecies
              ? 'Pokémon à importer'
              : 'Sélection batch à prévisualiser',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 12),
        if (externalImportMode == _PokedexExternalImportMode.singleSpecies)
          _PokedexExternalSpeciesAutocompleteField(
            controller: controller,
            focusNode: focusNode,
            isBusy: isBusy,
            isSearching: isSearching,
            searchResult: searchResult,
            selectedSuggestion: selectedSuggestion,
            onQueryChanged: onQueryChanged,
            onSuggestionSelected: onSuggestionSelected,
          )
        else
          _PokedexExternalBatchSelectionField(
            controller: controller,
            focusNode: focusNode,
            isBusy: isBusy,
            isResolving: isResolvingBatch,
            selectionResult: batchSelectionResult,
            onQueryChanged: onQueryChanged,
          ),
        const SizedBox(height: 10),
        Text(
          externalImportMode == _PokedexExternalImportMode.singleSpecies
              ? 'Les détails techniques PokeAPI / Showdown restent internes au pipeline. La prévisualisation reste bloquée tant qu’une suggestion n’a pas été sélectionnée explicitement.'
              : 'Le dry-run batch reste strictement non destructif dans ce lot. La liste finale résolue doit être lisible avant toute prévisualisation, et aucun import batch réel n’est encore proposé.',
          style: helperStyle,
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onCancel,
              child: const Text('Annuler'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: Key(
                externalImportMode == _PokedexExternalImportMode.singleSpecies
                    ? 'pokedex-import-external-preview-button'
                    : 'pokedex-import-external-batch-preview-button',
              ),
              controlSize: ControlSize.large,
              onPressed: _resolveContinueState(),
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : Text(
                      externalImportMode ==
                              _PokedexExternalImportMode.singleSpecies
                          ? 'Prévisualiser'
                          : 'Dry-run batch',
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> Function()? _resolveContinueState() {
    if (isBusy) {
      return null;
    }

    return switch (externalImportMode) {
      _PokedexExternalImportMode.singleSpecies =>
        isSearching || selectedSuggestion == null ? null : onContinue,
      _PokedexExternalImportMode.batchDryRun =>
        isResolvingBatch || !batchSelectionResult.canDryRun ? null : onContinue,
    };
  }
}

class _PokedexExternalImportModeSegmentedControl extends StatelessWidget {
  const _PokedexExternalImportModeSegmentedControl({
    required this.selectedMode,
    required this.onModeChanged,
  });

  final _PokedexExternalImportMode selectedMode;
  final ValueChanged<_PokedexExternalImportMode>? onModeChanged;

  @override
  Widget build(BuildContext context) {
    return CupertinoSlidingSegmentedControl<_PokedexExternalImportMode>(
      key: const Key('pokedex-import-external-mode-segmented-control'),
      groupValue: selectedMode,
      onValueChanged: (value) {
        if (value != null && onModeChanged != null) {
          onModeChanged!(value);
        }
      },
      thumbColor: EditorChrome.accentJade.withValues(alpha: 0.28),
      backgroundColor: EditorChrome.islandFillElevated(context),
      children: const <_PokedexExternalImportMode, Widget>{
        _PokedexExternalImportMode.singleSpecies: Padding(
          key: Key('pokedex-import-external-mode-mono-option'),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Mono-espèce',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
        _PokedexExternalImportMode.batchDryRun: Padding(
          key: Key('pokedex-import-external-mode-batch-option'),
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Text(
            'Batch dry-run',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      },
    );
  }
}

class _PokedexImportPreviewStep extends StatelessWidget {
  const _PokedexImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonJsonImportPreview preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );

    return Column(
      key: const Key('pokedex-import-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez rapidement l’espèce et les fichiers trouvés avant de lancer l’import.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${preview.nationalDex.toString().padLeft(3, '0')} ${preview.primaryName}',
                  key: const Key('pokedex-import-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${preview.types.join(' / ')}',
                  key: const Key('pokedex-import-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-learnset-status'),
                  label: preview.learnset.label,
                  isFound: preview.learnset.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-evolution-status'),
                  label: preview.evolution.label,
                  isFound: preview.evolution.isFound,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key('pokedex-import-preview-media-status'),
                  label: preview.media.label,
                  isFound: preview.media.isFound,
                ),
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalImportPreviewStep extends StatelessWidget {
  const _PokedexExternalImportPreviewStep({
    required this.preview,
    required this.isBusy,
    required this.errorMessage,
    required this.onBack,
    required this.onImport,
  });

  final PokemonExternalImportResult preview;
  final bool isBusy;
  final String? errorMessage;
  final VoidCallback onBack;
  final Future<void> Function() onImport;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final previewData = preview.preview;

    return Column(
      key: const Key('pokedex-import-external-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Aperçu de l\'import API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Vérifiez l’espèce, les données trouvées et les warnings avant d’ajouter ce Pokémon au projet local.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: preview.hasConflicts
                  ? EditorChrome.inspectorJoyCoral
                  : EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${previewData.nationalDex.toString().padLeft(3, '0')} ${previewData.primaryName}',
                  key: const Key('pokedex-import-external-preview-title'),
                  style: const TextStyle(
                    color: CupertinoColors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Type : ${previewData.types.join(' / ')}',
                  key: const Key('pokedex-import-external-preview-types'),
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 18),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-learnset-status'),
                  label: previewData.learnset.label,
                  isFound: previewData.learnset.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key: const Key(
                      'pokedex-import-external-preview-evolution-status'),
                  label: previewData.evolution.label,
                  isFound: previewData.evolution.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-media-status'),
                  label: previewData.media.label,
                  isFound: previewData.media.isAvailable,
                ),
                const SizedBox(height: 10),
                _PokedexImportArtifactLine(
                  key:
                      const Key('pokedex-import-external-preview-cries-status'),
                  label: previewData.cries.label,
                  isFound: previewData.cries.isAvailable,
                ),
                const SizedBox(height: 16),
                Text(
                  preview.hasConflicts
                      ? 'Politique actuelle : bloquer en cas de conflit'
                      : 'Politique actuelle : import local prudent',
                  style: helperStyle,
                ),
                if (preview.warnings.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  for (final warning in preview.warnings)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        '• $warning',
                        key: Key(
                          'pokedex-import-external-warning-${warning.hashCode}',
                        ),
                        style: const TextStyle(
                          color: EditorChrome.inspectorJoyCoral,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key('pokedex-import-external-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: isBusy ? null : onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key('pokedex-import-confirm-button'),
              controlSize: ControlSize.large,
              onPressed: isBusy || preview.hasConflicts ? null : onImport,
              child: isBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: ProgressCircle(),
                    )
                  : const Text('Importer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexExternalBatchPreviewStep extends StatelessWidget {
  const _PokedexExternalBatchPreviewStep({
    required this.selection,
    required this.preview,
    required this.errorMessage,
    required this.onBack,
    required this.onClose,
  });

  final PokemonExternalBatchSelectionResult selection;
  final PokemonExternalBatchImportResult preview;
  final String? errorMessage;
  final VoidCallback onBack;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final helperStyle = editorMacosFormLabelStyle(
      context,
    ).copyWith(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: EditorChrome.subtleLabel(context),
      height: 1.4,
    );
    final entriesBySpeciesId = <String, PokemonExternalBatchImportEntryResult>{
      for (final entry in preview.entries) entry.speciesId: entry,
    };

    return Column(
      key: const Key('pokedex-import-external-batch-preview-step'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dry-run batch API',
          style: editorMacosSheetTitleStyle(context),
        ),
        const SizedBox(height: 8),
        Text(
          'Ce lot reste volontairement non destructif : ce dry-run montre uniquement ce qui serait ciblé et les conflits éventuels, sans rien écrire dans le projet.',
          style: helperStyle,
        ),
        const SizedBox(height: 20),
        DecoratedBox(
          decoration: BoxDecoration(
            color: EditorChrome.islandFillElevated(context),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: EditorChrome.accentWarm.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Wrap(
              spacing: 18,
              runSpacing: 10,
              children: [
                _PokedexBatchSummaryMetric(
                  key: const Key(
                      'pokedex-import-external-batch-summary-targets'),
                  label: 'Cibles',
                  value: selection.targets.length.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key: const Key('pokedex-import-external-batch-summary-ready'),
                  label: 'Prêtes',
                  value: preview.successfulCount.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key: const Key(
                      'pokedex-import-external-batch-summary-conflicts'),
                  label: 'Conflits',
                  value: preview.conflictCount.toString(),
                ),
                _PokedexBatchSummaryMetric(
                  key:
                      const Key('pokedex-import-external-batch-summary-failed'),
                  label: 'Erreurs',
                  value: preview.failedCount.toString(),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Résultat détaillé du dry-run',
          style: editorMacosFormLabelStyle(context),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: Container(
            key: const Key('pokedex-import-external-batch-preview-list'),
            decoration: BoxDecoration(
              color: EditorChrome.islandFillElevated(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: EditorChrome.accentJade.withValues(alpha: 0.25),
              ),
            ),
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: selection.targets.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final target = selection.targets[index];
                final entry = entriesBySpeciesId[target.speciesId];
                return _PokedexExternalBatchPreviewEntryCard(
                  target: target,
                  entry: entry,
                );
              },
            ),
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 12),
          Text(
            errorMessage!,
            key: const Key('pokedex-import-error-message'),
            style: const TextStyle(
              color: EditorChrome.inspectorJoyCoral,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            PushButton(
              key: const Key(
                  'pokedex-import-external-batch-preview-back-button'),
              controlSize: ControlSize.large,
              secondary: true,
              onPressed: onBack,
              child: const Text('Retour'),
            ),
            const SizedBox(width: 12),
            PushButton(
              key: const Key(
                'pokedex-import-external-batch-preview-close-button',
              ),
              controlSize: ControlSize.large,
              onPressed: onClose,
              child: const Text('Fermer'),
            ),
          ],
        ),
      ],
    );
  }
}

class _PokedexBatchSummaryMetric extends StatelessWidget {
  const _PokedexBatchSummaryMetric({
    super.key,
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: EditorChrome.subtleLabel(context),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: EditorChrome.primaryLabel(context),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _PokedexExternalBatchPreviewEntryCard extends StatelessWidget {
  const _PokedexExternalBatchPreviewEntryCard({
    required this.target,
    required this.entry,
  });

  final PokemonExternalBatchSelectionTarget target;
  final PokemonExternalBatchImportEntryResult? entry;

  @override
  Widget build(BuildContext context) {
    final batchEntry = entry;
    final isFailed = batchEntry?.isFailed ?? true;
    final isConflict = batchEntry?.isConflict ?? false;
    final isSkipped = batchEntry?.isSkipped ?? false;
    final hasPreview = batchEntry?.result != null;
    final statusLabel = switch ((isFailed, isConflict, isSkipped)) {
      (true, _, _) => 'Erreur dry-run',
      (_, true, _) => 'Conflit détecté',
      (_, _, true) => 'Espèce skippée',
      _ => hasPreview ? 'Aperçu disponible' : 'Aucun aperçu',
    };
    final accent = switch ((isFailed, isConflict, isSkipped)) {
      (true, _, _) => EditorChrome.inspectorJoyCoral,
      (_, true, _) => EditorChrome.accentWarm,
      (_, _, true) => EditorChrome.accentWarm,
      _ => EditorChrome.accentJade,
    };
    final warnings = batchEntry?.result?.warnings ?? const <String>[];

    return Container(
      key: Key(
          'pokedex-import-external-batch-preview-entry-${target.speciesId}'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '#${target.nationalDex.toString().padLeft(4, '0')} ${target.primaryName} · ${target.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Demandé par : ${target.requestedInputs.join(', ')}',
                      style: TextStyle(
                        color: EditorChrome.subtleLabel(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (batchEntry?.result != null) ...[
            const SizedBox(height: 10),
            Text(
              'Prévisualisation disponible : ${batchEntry!.result!.preview.primaryName} · ${batchEntry.result!.preview.speciesId}',
              style: TextStyle(
                color: EditorChrome.primaryLabel(context),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (batchEntry?.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              batchEntry!.errorMessage!,
              style: const TextStyle(
                color: EditorChrome.inspectorJoyCoral,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: 10),
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  '• $warning',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_batch_field.dart`

```dart
part of 'pokedex_workspace_page.dart';

/// Champ batch du wizard externe.
///
/// Contrairement au mono-espèce :
/// - il ne propose pas d'auto-complétion par suggestion ;
/// - il n'accepte que trois formes batch explicites : liste, plage, génération ;
/// - il montre la liste finale résolue avant tout dry-run.
///
/// Toute la compréhension métier reste hors de ce widget :
/// - le résolveur lot 1 comprend la requête ;
/// - le use case batch la transforme en cibles réelles ;
/// - ce widget se contente d'afficher l'état courant.
class _PokedexExternalBatchSelectionField extends StatelessWidget {
  const _PokedexExternalBatchSelectionField({
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isResolving,
    required this.selectionResult,
    required this.onQueryChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isResolving;
  final PokemonExternalBatchSelectionResult selectionResult;
  final ValueChanged<String> onQueryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CupertinoTextField(
          key: const Key('pokedex-import-external-batch-query-field'),
          controller: controller,
          focusNode: focusNode,
          enabled: !isBusy,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          placeholder: 'Ex. pikachu, eevee, abra · 1-151 · gen 1',
          onChanged: onQueryChanged,
        ),
        const SizedBox(height: 10),
        if (isResolving)
          const Row(
            key: Key('pokedex-import-external-batch-selection-loading'),
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: ProgressCircle(),
              ),
              SizedBox(width: 10),
              Text(
                'Résolution de la sélection batch…',
                style: TextStyle(
                  color: CupertinoColors.systemGrey,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          )
        else
          _PokedexExternalBatchSelectionMessage(
            selectionResult: selectionResult,
          ),
        if (selectionResult.hasTargets) ...[
          const SizedBox(height: 12),
          _PokedexExternalBatchResolvedTargetsList(
            selectionResult: selectionResult,
          ),
        ],
      ],
    );
  }
}

class _PokedexExternalBatchSelectionMessage extends StatelessWidget {
  const _PokedexExternalBatchSelectionMessage({
    required this.selectionResult,
  });

  final PokemonExternalBatchSelectionResult selectionResult;

  @override
  Widget build(BuildContext context) {
    if (selectionResult.kind == PokemonExternalBatchSelectionResultKind.empty) {
      return Text(
        'Saisissez une liste explicite, une plage dex ou une génération. Exemples : `pikachu, eevee, abra`, `1-151`, `gen 1`.',
        key: const Key('pokedex-import-external-batch-idle-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (selectionResult.kind ==
        PokemonExternalBatchSelectionResultKind.resolved) {
      final deduplicatedCount =
          selectionResult.requestedInputCount - selectionResult.targets.length;
      final summary = deduplicatedCount > 0
          ? '${selectionResult.targets.length} cibles résolues · $deduplicatedCount doublon(s) éliminé(s).'
          : '${selectionResult.targets.length} cibles résolues et prêtes pour le dry-run.';
      return Text(
        summary,
        key: const Key('pokedex-import-external-batch-resolved-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      );
    }

    final isError = selectionResult.kind ==
            PokemonExternalBatchSelectionResultKind.invalidQuery ||
        selectionResult.kind == PokemonExternalBatchSelectionResultKind.error;
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;

    return Container(
      key: const Key('pokedex-import-external-batch-selection-message'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        selectionResult.message ?? 'Aucune cible batch exploitable.',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

class _PokedexExternalBatchResolvedTargetsList extends StatelessWidget {
  const _PokedexExternalBatchResolvedTargetsList({
    required this.selectionResult,
  });

  final PokemonExternalBatchSelectionResult selectionResult;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('pokedex-import-external-batch-resolved-list'),
      constraints: const BoxConstraints(maxHeight: 250),
      decoration: BoxDecoration(
        color: EditorChrome.islandFillElevated(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: EditorChrome.accentJade.withValues(alpha: 0.35),
        ),
      ),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 8),
        shrinkWrap: true,
        itemCount: selectionResult.targets.length,
        separatorBuilder: (_, __) => Container(
          height: 1,
          color: EditorChrome.subtleSeparator(context),
        ),
        itemBuilder: (context, index) {
          final target = selectionResult.targets[index];
          final requestedInputs = target.requestedInputs.join(', ');
          return Container(
            key: Key(
              'pokedex-import-external-batch-target-${target.speciesId}',
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '#${target.nationalDex.toString().padLeft(4, '0')}',
                  style: TextStyle(
                    color: EditorChrome.subtleLabel(context),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${target.primaryName} · ${target.speciesId}',
                        style: TextStyle(
                          color: EditorChrome.primaryLabel(context),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Demandé par : $requestedInputs',
                        style: TextStyle(
                          color: EditorChrome.subtleLabel(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (target.generation != null)
                  Text(
                    'Gen ${target.generation}',
                    style: TextStyle(
                      color: EditorChrome.subtleLabel(context),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/pokedex_workspace/pokedex_external_search_field.dart`

```dart
part of 'pokedex_workspace_page.dart';

/// Champ d'auto-complétion mono-espèce du wizard externe.
///
/// Ce widget reste volontairement présentation + interaction locale :
/// - il n'analyse pas la requête ;
/// - il ne parle pas au réseau ;
/// - il n'importe rien ;
/// - il reflète simplement le résultat applicatif reçu du use case.
///
/// Le lot 2 reste volontairement sur une implémentation locale contrôlée :
/// - navigation clavier honnête sans dépendre d'un overlay implicite ;
/// - sélection souris explicite ;
/// - aucune sélection implicite tant que l'utilisateur n'agit pas.
class _PokedexExternalSpeciesAutocompleteField extends StatefulWidget {
  const _PokedexExternalSpeciesAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.isBusy,
    required this.isSearching,
    required this.searchResult,
    required this.selectedSuggestion,
    required this.onQueryChanged,
    required this.onSuggestionSelected,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isBusy;
  final bool isSearching;
  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<PokemonExternalSpeciesSuggestion> onSuggestionSelected;

  @override
  State<_PokedexExternalSpeciesAutocompleteField> createState() =>
      _PokedexExternalSpeciesAutocompleteFieldState();
}

class _PokedexExternalSpeciesAutocompleteFieldState
    extends State<_PokedexExternalSpeciesAutocompleteField> {
  int? _highlightedSuggestionIndex;

  List<PokemonExternalSpeciesSuggestion> get _visibleSuggestions =>
      widget.searchResult.hasSuggestions && widget.selectedSuggestion == null
          ? widget.searchResult.suggestions
          : const <PokemonExternalSpeciesSuggestion>[];

  @override
  void initState() {
    super.initState();
    _syncHighlightedSuggestion();
  }

  @override
  void didUpdateWidget(_PokedexExternalSpeciesAutocompleteField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.searchResult.kind != widget.searchResult.kind ||
        !listEquals(
          oldWidget.searchResult.suggestions,
          widget.searchResult.suggestions,
        ) ||
        oldWidget.selectedSuggestion != widget.selectedSuggestion) {
      _syncHighlightedSuggestion();
    }
  }

  void _syncHighlightedSuggestion() {
    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty) {
      _highlightedSuggestionIndex = null;
      return;
    }
    if (_highlightedSuggestionIndex == null ||
        _highlightedSuggestionIndex! >= suggestions.length) {
      _highlightedSuggestionIndex = 0;
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) {
      return KeyEventResult.ignored;
    }

    final suggestions = _visibleSuggestions;
    if (suggestions.isEmpty || widget.selectedSuggestion != null) {
      return KeyEventResult.ignored;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        final currentIndex = _highlightedSuggestionIndex ?? -1;
        _highlightedSuggestionIndex =
            (currentIndex + 1).clamp(0, suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        final currentIndex = _highlightedSuggestionIndex ?? 0;
        _highlightedSuggestionIndex =
            (currentIndex - 1).clamp(0, suggestions.length - 1);
      });
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      final selectedIndex = _highlightedSuggestionIndex ?? 0;
      widget.onSuggestionSelected(suggestions[selectedIndex]);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _visibleSuggestions;

    return Focus(
      onKeyEvent: _handleKeyEvent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CupertinoTextField(
            key: const Key('pokedex-import-external-query-field'),
            controller: widget.controller,
            focusNode: widget.focusNode,
            placeholder: 'Ex. pikachu, bulbasaur ou 25',
            enabled: !widget.isBusy,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            onChanged: widget.onQueryChanged,
            onSubmitted: (_) {
              final selectedIndex = _highlightedSuggestionIndex;
              if (selectedIndex == null ||
                  selectedIndex < 0 ||
                  selectedIndex >= suggestions.length) {
                return;
              }
              widget.onSuggestionSelected(suggestions[selectedIndex]);
            },
          ),
          if (suggestions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              key: const Key('pokedex-import-external-suggestions-list'),
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 260),
              decoration: BoxDecoration(
                color: EditorChrome.islandFillElevated(context),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: EditorChrome.accentJade.withValues(alpha: 0.45),
                  width: 1,
                ),
              ),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shrinkWrap: true,
                itemCount: suggestions.length,
                separatorBuilder: (_, __) => Container(
                  height: 1,
                  color: EditorChrome.subtleSeparator(context),
                ),
                itemBuilder: (context, index) {
                  final option = suggestions[index];
                  final isHighlighted = _highlightedSuggestionIndex == index;
                  return MouseRegion(
                    onEnter: (_) {
                      if (_highlightedSuggestionIndex == index) {
                        return;
                      }
                      setState(() {
                        _highlightedSuggestionIndex = index;
                      });
                    },
                    child: GestureDetector(
                      key: Key(
                        'pokedex-import-external-suggestion-${option.speciesId}',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTap: () => widget.onSuggestionSelected(option),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: isHighlighted
                              ? EditorChrome.accentJade.withValues(alpha: 0.16)
                              : CupertinoColors.transparent,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 12,
                          ),
                          child: Row(
                            children: [
                              Text(
                                '#${option.nationalDex.toString().padLeft(4, '0')}',
                                style: TextStyle(
                                  color: EditorChrome.subtleLabel(context),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      option.primaryName,
                                      style: TextStyle(
                                        color: EditorChrome.primaryLabel(
                                          context,
                                        ),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      option.speciesId,
                                      style: TextStyle(
                                        color: EditorChrome.subtleLabel(
                                          context,
                                        ),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (option.generation != null)
                                Text(
                                  'Gen ${option.generation}',
                                  style: TextStyle(
                                    color: EditorChrome.subtleLabel(context),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 10),
          if (widget.selectedSuggestion != null) ...[
            Container(
              key: const Key('pokedex-import-external-selected-suggestion'),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: EditorChrome.accentJade.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: EditorChrome.accentJade.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    CupertinoIcons.check_mark_circled_solid,
                    size: 18,
                    color: EditorChrome.accentJade,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Sélection retenue : #${widget.selectedSuggestion!.nationalDex.toString().padLeft(4, '0')} ${widget.selectedSuggestion!.primaryName} · ${widget.selectedSuggestion!.speciesId}',
                      style: TextStyle(
                        color: EditorChrome.primaryLabel(context),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (widget.isSearching)
            const Row(
              key: Key('pokedex-import-external-search-loading'),
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: ProgressCircle(),
                ),
                SizedBox(width: 10),
                Text(
                  'Recherche des suggestions externes…',
                  style: TextStyle(
                    color: CupertinoColors.systemGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            )
          else
            _PokedexExternalSpeciesSearchMessage(
              searchResult: widget.searchResult,
              selectedSuggestion: widget.selectedSuggestion,
            ),
        ],
      ),
    );
  }
}

class _PokedexExternalSpeciesSearchMessage extends StatelessWidget {
  const _PokedexExternalSpeciesSearchMessage({
    required this.searchResult,
    required this.selectedSuggestion,
  });

  final PokemonExternalSpeciesSearchResult searchResult;
  final PokemonExternalSpeciesSuggestion? selectedSuggestion;

  @override
  Widget build(BuildContext context) {
    if (selectedSuggestion != null) {
      return Text(
        'La prévisualisation utilisera uniquement l’espèce explicitement sélectionnée ci-dessus.',
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (searchResult.kind == PokemonExternalSpeciesSearchResultKind.empty) {
      return Text(
        'Tapez un nom, un slug ou un numéro dex, puis sélectionnez explicitement une suggestion.',
        key: const Key('pokedex-import-external-search-idle-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    if (searchResult.kind ==
        PokemonExternalSpeciesSearchResultKind.suggestions) {
      return Text(
        'Choisissez explicitement une suggestion pour débloquer la prévisualisation.',
        key: const Key(
            'pokedex-import-external-search-pending-selection-message'),
        style: TextStyle(
          color: EditorChrome.subtleLabel(context),
          fontSize: 12,
          fontWeight: FontWeight.w600,
          height: 1.4,
        ),
      );
    }

    final isError = searchResult.kind ==
            PokemonExternalSpeciesSearchResultKind.invalidQuery ||
        searchResult.kind == PokemonExternalSpeciesSearchResultKind.error;
    final accent =
        isError ? EditorChrome.inspectorJoyCoral : EditorChrome.accentWarm;

    return Container(
      key: const Key('pokedex-import-external-search-message'),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.35)),
      ),
      child: Text(
        searchResult.message ?? 'Aucune suggestion disponible.',
        style: const TextStyle(
          color: CupertinoColors.white,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          height: 1.35,
        ),
      ),
    );
  }
}

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/resolve_external_pokemon_batch_selection_use_case_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_external_batch_selection.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/services/pokemon_external_query_resolver.dart';
import 'package:map_editor/src/application/use_cases/resolve_external_pokemon_batch_selection_use_case.dart';

void main() {
  group('ResolveExternalPokemonBatchSelectionUseCase', () {
    test('returns empty without hitting the external repository', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('   ');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.empty);
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('returns out of scope for a mono-species query', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: const <String, dynamic>{},
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('pikachu');

      expect(
          result.kind, PokemonExternalBatchSelectionResultKind.outOfScopeQuery);
      expect(result.message, contains('liste explicite'));
      expect(repository.fetchShowdownPokedexSnapshotCallCount, 0);
    });

    test('resolves an explicit list with stable deduplication after mapping',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('25, pikachu, bulbasaur');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.resolved);
      expect(
        result.targets.map((target) => target.speciesId).toList(),
        <String>['pikachu', 'bulbasaur'],
      );
      expect(
        result.targets.first.requestedInputs,
        <String>['25', 'pikachu'],
      );
    });

    test('resolves a dex range with base species only', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('25-26');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.resolved);
      expect(
        result.targets.map((target) => target.speciesId).toList(),
        <String>['pikachu', 'raichu'],
      );
    });

    test('resolves a generation with base species only and stable ordering',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('gen 2');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.resolved);
      expect(
        result.targets.map((target) => target.speciesId).toList(),
        <String>['chikorita'],
      );
    });

    test('reports unresolved explicit entries without dropping resolved ones',
        () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('bulbasaur, missingno');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.invalidQuery);
      expect(
          result.targets.map((target) => target.speciesId).toList(), <String>[
        'bulbasaur',
      ]);
      expect(result.message, contains('missingno'));
    });

    test('returns no results for an unknown generation', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshot: _sampleSnapshot,
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('generation 42');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.noResults);
      expect(result.message, contains('génération'));
    });

    test('maps repository failures to an error result', () async {
      final repository = _FakePokemonExternalSourceRepository(
        showdownPokedexSnapshotError: const EditorPersistenceException(
          'Snapshot batch indisponible',
        ),
      );
      final useCase = ResolveExternalPokemonBatchSelectionUseCase(
        externalSourceRepository: repository,
        queryResolver: const PokemonExternalQueryResolver(),
      );

      final result = await useCase.execute('gen 1');

      expect(result.kind, PokemonExternalBatchSelectionResultKind.error);
      expect(result.message, 'Snapshot batch indisponible');
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    this.showdownPokedexSnapshot = const <String, dynamic>{},
    this.showdownPokedexSnapshotError,
  });

  final Map<String, dynamic> showdownPokedexSnapshot;
  final EditorApplicationException? showdownPokedexSnapshotError;
  int fetchShowdownPokedexSnapshotCallCount = 0;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    fetchShowdownPokedexSnapshotCallCount += 1;
    final error = showdownPokedexSnapshotError;
    if (error != null) {
      throw error;
    }
    return showdownPokedexSnapshot;
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(String speciesId) {
    throw UnimplementedError();
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
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

const Map<String, dynamic> _sampleSnapshot = <String, dynamic>{
  'bulbasaur': <String, dynamic>{
    'name': 'Bulbasaur',
    'num': 1,
    'gen': 1,
  },
  'pikachu': <String, dynamic>{
    'name': 'Pikachu',
    'num': 25,
    'gen': 1,
  },
  'pikachugmax': <String, dynamic>{
    'name': 'Pikachu-Gmax',
    'num': 25,
    'gen': 8,
    'baseSpecies': 'Pikachu',
    'forme': 'Gmax',
  },
  'raichu': <String, dynamic>{
    'name': 'Raichu',
    'num': 26,
    'gen': 1,
  },
  'chikorita': <String, dynamic>{
    'name': 'Chikorita',
    'num': 152,
    'gen': 2,
  },
};

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
      expect(container.read(pokemonExternalQueryResolverProvider), isNotNull);
      expect(
        container.read(searchExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexExternalSpeciesSearcherProvider), isNotNull);
      expect(
        container.read(resolveExternalPokemonBatchSelectionUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(pokedexExternalBatchSelectionResolverProvider),
        isNotNull,
      );
      expect(
        container.read(importExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(
        container.read(batchImportExternalPokemonSpeciesUseCaseProvider),
        isNotNull,
      );
      expect(container.read(pokedexExternalBatchPreviewerProvider), isNotNull);
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

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/import_external_pokemon_use_cases_test.dart`

```dart
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/errors/application_errors.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/pokemon_external_source_repository.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/ports/pokemon_write_repository.dart';
import 'package:map_editor/src/application/services/pokeapi_pokemon_learnset_converter.dart';
import 'package:map_editor/src/application/services/showdown_pokemon_species_converter.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/application/use_cases/initialize_pokemon_project_storage_use_case.dart';
import 'package:map_editor/src/application/use_cases/project_management_use_cases.dart';
import 'package:map_editor/src/infrastructure/filesystem/project_filesystem.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';

void main() {
  late Directory tempProjectRoot;
  late ProjectFileSystem workspace;
  late ImportExternalPokemonSpeciesUseCase singleUseCase;
  late BatchImportExternalPokemonSpeciesUseCase batchUseCase;
  late _FakePokemonExternalSourceRepository externalSourceRepository;
  late FilePokemonReadRepository readRepository;
  late FilePokemonWriteRepository writeRepository;
  late File projectFile;

  setUp(() async {
    tempProjectRoot = await Directory.systemTemp.createTemp(
      'pokemon_external_import_project_',
    );
    workspace = ProjectFileSystem(tempProjectRoot.path);
    externalSourceRepository = _FakePokemonExternalSourceRepository(
      showdownSpeciesPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurShowdownPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonSpeciesPayloads: <String, Map<String, dynamic>>{
        '1':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonSpeciesPayload) as Map<String, dynamic>,
        '2': jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_ivysaurPokemonSpeciesPayload) as Map<String, dynamic>,
      },
      pokeApiPokemonPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>,
        'ivysaur': jsonDecode(_ivysaurPokemonPayload) as Map<String, dynamic>,
      },
      pokeApiEvolutionChainPayloads: <String, Map<String, dynamic>>{
        'bulbasaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
        'ivysaur':
            jsonDecode(_bulbasaurEvolutionChainPayload) as Map<String, dynamic>,
      },
      binaryAssets: <String, PokemonExternalBinaryAsset>{
        'https://assets.example.test/bulbasaur/portrait.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
          bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front.png',
          bytes: Uint8List.fromList(<int>[5, 6, 7, 8]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back.png',
          bytes: Uint8List.fromList(<int>[9, 10, 11, 12]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/front_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/front_shiny.png',
          bytes: Uint8List.fromList(<int>[13, 14, 15, 16]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/back_shiny.png':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/back_shiny.png',
          bytes: Uint8List.fromList(<int>[17, 18, 19, 20]),
          contentType: 'image/png',
        ),
        'https://assets.example.test/bulbasaur/cry.ogg':
            PokemonExternalBinaryAsset(
          sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
          bytes: Uint8List.fromList(<int>[21, 22, 23, 24]),
          contentType: 'audio/ogg',
        ),
      },
    );
    writeRepository = const FilePokemonWriteRepository();
    readRepository = const FilePokemonReadRepository();
    singleUseCase = ImportExternalPokemonSpeciesUseCase(
      externalSourceRepository: externalSourceRepository,
      writeRepository: writeRepository,
    );
    batchUseCase = BatchImportExternalPokemonSpeciesUseCase(singleUseCase);

    final createProjectUseCase = CreateProjectUseCase(
      FileProjectRepository(),
      const FileProjectWorkspaceFactory(),
    );
    await createProjectUseCase.execute(
      'Pokemon External Import Project',
      tempProjectRoot.path,
    );
    await const InitializePokemonProjectStorageUseCase().execute(workspace);
    projectFile = File(workspace.projectManifestPath);
  });

  tearDown(() async {
    if (await tempProjectRoot.exists()) {
      await tempProjectRoot.delete(recursive: true);
    }
  });

  group('ImportExternalPokemonSpeciesUseCase', () {
    test('imports one species from external payloads into local storage',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(workspace, speciesId: '1');

      expect(result.importedSpeciesId, 'bulbasaur');
      expect(result.dryRun, isFalse);
      expect(result.hasConflicts, isFalse);
      expect(result.preview.primaryName, 'Bulbasaur');
      expect(result.preview.cries.isAvailable, isTrue);
      expect(result.downloadedAssetCount, 6);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );

      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');
      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');
      final evolution =
          await readRepository.readEvolutionById(workspace, 'bulbasaur');
      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(species.typing.types, <String>['grass', 'poison']);
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(evolution.evolutions.single.targetSpeciesId, 'ivysaur');
      expect(
        media.variants['base']?.portrait,
        'assets/pokemon/portraits/bulbasaur.png',
      );
      expect(species.names['fr'], 'Bulbizarre');
      expect(species.progression.growthRateId, 'medium_slow');
      expect(species.progression.baseFriendship, 50);
      expect(species.dexContent.color, 'green');
      expect(species.dexContent.flavorText,
          'A strange seed was planted on its back at birth.');
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isTrue,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves everything but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(result.downloadedAssetCount, 0);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );

      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('fail_on_conflict reports conflicts and writes nothing', () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
          PokemonExternalImportArtifactAction.conflict,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'fail_on_conflict stays atomic even when only one artefact already exists',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // On provoque ici le cas le plus intéressant du point de vue produit :
      // un conflit partiel. Si l'atomicité promise par le use case casse,
      // l'import pourrait écrire learnset/evolution/media alors que l'espèce
      // principale est en conflit, ce qui rendrait le résultat trompeur.
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
      );

      expect(result.hasConflicts, isTrue);
      expect(result.hasWritesApplied, isFalse);
      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.species,
            )
            .action,
        PokemonExternalImportArtifactAction.conflict,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/evolutions/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/media/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing skips files already present and still writes missing ones',
        () async {
      await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        dryRun: true,
      );
      await writeRepository.saveSpecies(
        workspace,
        const ShowdownPokemonSpeciesConverter().convert(
          jsonDecode(_bulbasaurShowdownPayload) as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      expect(
        result.artifacts.map((artifact) => artifact.action).toList(),
        <PokemonExternalImportArtifactAction>[
          PokemonExternalImportArtifactAction.skip,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
          PokemonExternalImportArtifactAction.create,
        ],
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('overwrite_existing replaces an existing artefact', () async {
      await writeRepository.saveLearnset(
        workspace,
        const PokeApiPokemonLearnsetConverter().convert(
          speciesId: 'bulbasaur',
          payload: jsonDecode(_legacyBulbasaurPokemonPayload)
              as Map<String, dynamic>,
        ),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final learnset =
          await readRepository.readLearnsetById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.learnset,
            )
            .action,
        PokemonExternalImportArtifactAction.overwrite,
      );
      expect(learnset.tm.single.moveId, 'solar_beam');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing reuses an existing non-canonical species path '
        'without creating a duplicate canonical file', () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing ignores a misleading basename with another json id',
        () async {
      await writeRepository.saveSpecies(
        workspace,
        _customSlugBulbasaurSpecies,
      );

      final misleadingFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/9999-bulbasaur.json',
        ),
      );
      await misleadingFile.parent.create(recursive: true);
      final misleadingJson = _customSlugBulbasaurSpecies.toJson()
        ..['id'] = 'something_else'
        ..['slug'] = 'something-else';
      await misleadingFile.writeAsString(
        const JsonEncoder.withIndent('  ').convert(misleadingJson),
      );
      final beforeProjectJson = await projectFile.readAsString();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final speciesArtifact = result.artifacts.firstWhere(
        (artifact) =>
            artifact.kind == PokemonExternalImportArtifactKind.species,
      );
      final customFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbizarre-custom.json',
        ),
      );
      final canonicalFile = File(
        workspace.resolveProjectRelativePath(
          'data/pokemon/species/0001-bulbasaur.json',
        ),
      );
      final species =
          await readRepository.readSpeciesById(workspace, 'bulbasaur');

      expect(speciesArtifact.action,
          PokemonExternalImportArtifactAction.overwrite);
      expect(
        speciesArtifact.relativePath,
        'data/pokemon/species/0001-bulbizarre-custom.json',
      );
      expect(await customFile.exists(), isTrue);
      expect(await canonicalFile.exists(), isFalse);
      expect(await misleadingFile.exists(), isTrue);
      expect(species.slug, 'bulbasaur');
      expect(species.names['en'], 'Bulbasaur');
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('surfaces external source errors clearly', () async {
      externalSourceRepository.pokeApiPokemonSpeciesPayloads
          .remove('bulbasaur');

      await expectLater(
        () => singleUseCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorNotFoundException>().having(
            (error) => error.message,
            'message',
            'External PokeAPI pokemon-species payload not found for species "bulbasaur"',
          ),
        ),
      );
    });

    test('continues when optional pokemon payload is unavailable', () async {
      externalSourceRepository.pokeApiPokemonPayloads.remove('bulbasaur');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      expect(result.hasConflicts, isFalse);
      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isFalse);
      expect(result.importedEvolution, isTrue);
      expect(result.importedMedia, isTrue);
      expect(result.preview.learnset.isAvailable, isFalse);
      expect(result.preview.media.isAvailable, isFalse);
      expect(result.preview.cries.isAvailable, isFalse);
      expect(
        result.warnings.join('\n'),
        contains('Learnset and media payload unavailable for "bulbasaur"'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/learnsets/bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
    });

    test(
        'omits a missing media asset ref from media.json while keeping the rest coherent',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic,
          'assets/pokemon/sprites/bulbasaur/front.png');
      expect(baseVariant.cry, 'assets/pokemon/cries/bulbasaur.ogg');
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('Portrait download failed'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'keeps species learnset and evolution when all media downloads fail and writes no ghost refs',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets.clear();

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final baseVariant = media.variants['base']!;

      expect(result.importedSpecies, isTrue);
      expect(result.importedLearnset, isTrue);
      expect(result.importedEvolution, isTrue);
      expect(result.downloadedAssetCount, 0);
      expect(baseVariant.portrait, isNull);
      expect(baseVariant.frontStatic, isNull);
      expect(baseVariant.backStatic, isNull);
      expect(baseVariant.frontShinyStatic, isNull);
      expect(baseVariant.backShinyStatic, isNull);
      expect(baseVariant.icon, isNull);
      expect(baseVariant.party, isNull);
      expect(baseVariant.overworld, isNull);
      expect(baseVariant.cry, isNull);
      expect(baseVariant.animations, isEmpty);
      expect(result.warnings.join('\n'), contains('download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing does not download new assets when media.json is already skipped',
        () async {
      final beforeProjectJson = await projectFile.readAsString();

      // Ce cas verrouille précisément le coin restant du mini-fix 2 :
      // - `media.json` existe déjà, donc l'artefact media doit être `skip` ;
      // - aucun asset local n'existe encore ;
      // - si le pipeline continue malgré tout à télécharger les binaires,
      //   ils deviennent orphelins parce que le `media.json` conservé ne sera
      //   jamais réécrit dans ce run.
      //
      // On prépare donc volontairement un `media.json` minimal qui ne référence
      // aucun asset. Si l'import écrit ensuite des portraits/sprites/cries alors
      // que le JSON média est skippé, le bug est réel et reproductible.
      await writeRepository.saveMedia(
        workspace,
        const PokemonMediaFile(
          speciesId: 'bulbasaur',
          defaultFormId: 'base',
          variants: <String, PokemonMediaVariant>{
            'base': PokemonMediaVariant(),
          },
        ),
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(
        result.artifacts
            .firstWhere(
              (artifact) =>
                  artifact.kind == PokemonExternalImportArtifactKind.media,
            )
            .action,
        PokemonExternalImportArtifactAction.skip,
      );
      expect(result.downloadedAssetCount, 0);
      expect(result.downloadedAssets, isEmpty);
      expect(media.variants['base']?.portrait, isNull);
      expect(media.variants['base']?.frontStatic, isNull);
      expect(media.variants['base']?.backStatic, isNull);
      expect(media.variants['base']?.cry, isNull);
      expect(
        result.warnings.join('\n'),
        contains('media.json'),
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'skip_existing keeps a pre-existing local asset ref without re-downloading it',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[200, 201, 202]);

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.skipExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');
      final portraitResult = result.downloadedAssets.firstWhere(
        (asset) => asset.label == 'Portrait',
      );

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[200, 201, 202]);
      expect(portraitResult.wasWritten, isFalse);
      expect(portraitResult.existedBefore, isTrue);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps an existing local asset ref when redownload fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[77, 88, 99]);
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/portrait.png');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[77, 88, 99]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible image content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[9, 9, 9, 9]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'overwrite_existing keeps a local image when redownload content-type is incompatible',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final portraitFile = File(
        workspace.resolveProjectRelativePath(
          'assets/pokemon/portraits/bulbasaur.png',
        ),
      );
      await portraitFile.parent.create(recursive: true);
      await portraitFile.writeAsBytes(const <int>[17, 18, 19]);
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
        contentType: 'image/jpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
        mergePolicy: PokemonExternalImportMergePolicy.overwriteExisting,
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait,
          'assets/pokemon/portraits/bulbasaur.png');
      expect(await portraitFile.readAsBytes(), const <int>[17, 18, 19]);
      expect(
        result.warnings.join('\n'),
        contains('existing local asset was kept'),
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (image/jpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('rejects incompatible cry content-types without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository
              .binaryAssets['https://assets.example.test/bulbasaur/cry.ogg'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/cry.ogg',
        bytes: Uint8List.fromList(<int>[4, 4, 4, 4]),
        contentType: 'audio/mpeg',
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('incompatible content-type (audio/mpeg)'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('refuses GIF assets without persisting a ghost media ref', () async {
      final beforeProjectJson = await projectFile.readAsString();
      final payload =
          jsonDecode(_bulbasaurPokemonPayload) as Map<String, dynamic>;
      final sprites = payload['sprites'] as Map<String, dynamic>;
      final other = sprites['other'] as Map<String, dynamic>;
      final officialArtwork = other['official-artwork'] as Map<String, dynamic>;
      officialArtwork['front_default'] =
          'https://assets.example.test/bulbasaur/portrait.gif';
      externalSourceRepository.pokeApiPokemonPayloads['bulbasaur'] = payload;

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('GIF assets are explicitly excluded'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('applies the same no-ghost rule to cries', () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets
          .remove('https://assets.example.test/bulbasaur/cry.ogg');

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.cry, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );
      expect(result.warnings.join('\n'), contains('Cri download failed'));
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('cleans up newly written media assets if media.json persistence fails',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      final useCase = ImportExternalPokemonSpeciesUseCase(
        externalSourceRepository: externalSourceRepository,
        writeRepository: _ThrowingMediaWriteRepository(
          delegate: writeRepository,
        ),
      );

      await expectLater(
        () => useCase.execute(
          workspace,
          speciesId: 'bulbasaur',
        ),
        throwsA(
          isA<EditorPersistenceException>().having(
            (error) => error.message,
            'message',
            contains('Simulated media write failure'),
          ),
        ),
      );

      // Ce test verrouille un invariant subtil de clôture 11A :
      // si le `media.json` final ne peut pas être écrit, on ne doit pas laisser
      // derrière nous des assets binaires fraîchement créés qui ne seront
      // référencés par aucun JSON local.
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/sprites/bulbasaur/front.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/cries/bulbasaur.ogg',
          ),
        ).exists(),
        isFalse,
      );

      // Le mini-fix ne touche pas à `project.json`. On le reverrouille ici
      // même sur un échec tardif du pipeline.
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test(
        'rejects a headerless incompatible image payload without persisting a ref',
        () async {
      final beforeProjectJson = await projectFile.readAsString();
      externalSourceRepository.binaryAssets[
              'https://assets.example.test/bulbasaur/portrait.png'] =
          PokemonExternalBinaryAsset(
        sourceUrl: 'https://assets.example.test/bulbasaur/portrait.png',
        // Signature JPEG volontairement incompatible.
        bytes: Uint8List.fromList(
          <int>[0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46],
        ),
        contentType: null,
      );

      final result = await singleUseCase.execute(
        workspace,
        speciesId: 'bulbasaur',
      );

      final media = await readRepository.readMediaById(workspace, 'bulbasaur');

      expect(media.variants['base']?.portrait, isNull);
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        result.warnings.join('\n'),
        contains('missing or incompatible content-type'),
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });
  });

  group('BatchImportExternalPokemonSpeciesUseCase', () {
    test('imports a batch successfully with deterministic ordering', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur', 'ivysaur'],
      );

      expect(
        result.entries.map((entry) => entry.speciesId).toList(),
        <String>['bulbasaur', 'ivysaur'],
      );
      expect(result.successfulCount, 2);
      expect(result.failedCount, 0);
      expect(result.conflictCount, 0);
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('dry-run resolves a batch but writes nothing', () async {
      final beforeProjectJson = await projectFile.readAsString();

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['ivysaur', 'bulbasaur'],
        dryRun: true,
      );

      expect(result.dryRun, isTrue);
      expect(result.successfulCount, 2);
      expect(
        result.entries.every(
          (entry) =>
              entry.result != null && entry.result!.hasWritesApplied == false,
        ),
        isTrue,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0002-ivysaur.json',
          ),
        ).exists(),
        isFalse,
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'assets/pokemon/portraits/bulbasaur.png',
          ),
        ).exists(),
        isFalse,
      );
      expect(await projectFile.readAsString(), beforeProjectJson);
    });

    test('continues on partial failures and reports them by species', () async {
      externalSourceRepository.showdownSpeciesPayloads.remove('ivysaur');

      final result = await batchUseCase.execute(
        workspace,
        speciesIds: <String>['bulbasaur', 'ivysaur'],
      );

      expect(result.successfulCount, 1);
      expect(result.failedCount, 1);
      expect(
        result.entries
            .firstWhere((entry) => entry.speciesId == 'ivysaur')
            .errorMessage,
        'External Showdown species payload not found for species "ivysaur"',
      );
      expect(
        await File(
          workspace.resolveProjectRelativePath(
            'data/pokemon/species/0001-bulbasaur.json',
          ),
        ).exists(),
        isTrue,
      );
    });
  });
}

class _FakePokemonExternalSourceRepository
    implements PokemonExternalSourceRepository {
  _FakePokemonExternalSourceRepository({
    required this.showdownSpeciesPayloads,
    required this.pokeApiPokemonSpeciesPayloads,
    required this.pokeApiPokemonPayloads,
    required this.pokeApiEvolutionChainPayloads,
    required this.binaryAssets,
  });

  final Map<String, Map<String, dynamic>> showdownSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonSpeciesPayloads;
  final Map<String, Map<String, dynamic>> pokeApiPokemonPayloads;
  final Map<String, Map<String, dynamic>> pokeApiEvolutionChainPayloads;
  final Map<String, PokemonExternalBinaryAsset> binaryAssets;

  @override
  Future<Map<String, dynamic>> fetchShowdownPokedexSnapshot() async {
    return showdownSpeciesPayloads.map(
      (key, value) => MapEntry<String, dynamic>(key, _deepCopy(value)),
    );
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiEvolutionChainPayload(
    String speciesId,
  ) async {
    final payload = pokeApiEvolutionChainPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI evolution chain payload not found for species '
        '"$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchPokeApiPokemonSpeciesPayload(
    String speciesId,
  ) async {
    final payload = pokeApiPokemonSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External PokeAPI pokemon-species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownSpeciesPayload(
    String speciesId,
  ) async {
    final payload = showdownSpeciesPayloads[speciesId];
    if (payload == null) {
      throw EditorNotFoundException(
        'External Showdown species payload not found for species "$speciesId"',
      );
    }
    return _deepCopy(payload);
  }

  @override
  Future<Map<String, dynamic>> fetchShowdownMovesSnapshot() {
    throw UnimplementedError();
  }

  @override
  Future<PokemonExternalBinaryAsset> fetchBinaryAsset(String sourceUrl) async {
    final asset = binaryAssets[sourceUrl];
    if (asset == null) {
      throw EditorNotFoundException('External asset not found: $sourceUrl');
    }
    return PokemonExternalBinaryAsset(
      sourceUrl: asset.sourceUrl,
      bytes: Uint8List.fromList(asset.bytes),
      contentType: asset.contentType,
    );
  }

  Map<String, dynamic> _deepCopy(Map<String, dynamic> source) {
    return jsonDecode(jsonEncode(source)) as Map<String, dynamic>;
  }
}

/// Repository décorateur volontairement minuscule pour reproduire un échec
/// tardif sur `saveMedia`.
///
/// Ce fake sert uniquement à prouver un invariant de clôture 11A :
/// si l'écriture finale du `media.json` casse, le pipeline ne doit pas laisser
/// d'assets binaires nouvellement créés sans référence locale persistée.
///
/// Non-objectifs explicites :
/// - ne pas changer la sémantique des autres écritures ;
/// - ne pas simuler un filesystem complet ;
/// - ne pas introduire une nouvelle abstraction de prod.
class _ThrowingMediaWriteRepository implements PokemonWriteRepository {
  const _ThrowingMediaWriteRepository({
    required this.delegate,
  });

  final PokemonWriteRepository delegate;

  @override
  Future<void> saveBinaryAsset(
    ProjectWorkspace workspace, {
    required String relativePath,
    required List<int> bytes,
  }) {
    return delegate.saveBinaryAsset(
      workspace,
      relativePath: relativePath,
      bytes: bytes,
    );
  }

  @override
  Future<void> saveCatalogByKey(
    ProjectWorkspace workspace,
    String catalogKey,
    PokemonCatalogFile catalog,
  ) {
    return delegate.saveCatalogByKey(workspace, catalogKey, catalog);
  }

  @override
  Future<void> saveEvolution(
    ProjectWorkspace workspace,
    PokemonEvolutionFile evolution,
  ) {
    return delegate.saveEvolution(workspace, evolution);
  }

  @override
  Future<void> saveLearnset(
    ProjectWorkspace workspace,
    PokemonLearnsetFile learnset,
  ) {
    return delegate.saveLearnset(workspace, learnset);
  }

  @override
  Future<void> saveMedia(
    ProjectWorkspace workspace,
    PokemonMediaFile media,
  ) {
    throw const EditorPersistenceException(
      'Simulated media write failure',
    );
  }

  @override
  Future<void> saveSpecies(
    ProjectWorkspace workspace,
    PokemonSpeciesFile species,
  ) {
    return delegate.saveSpecies(workspace, species);
  }
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
  "expType": "Medium Slow",
  "baseExp": 64,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 0.7,
  "weightkg": 6.9
}
''';

const String _bulbasaurPokemonSpeciesPayload = '''
{
  "name": "bulbasaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Bulbasaur"},
    {"language": {"name": "fr"}, "name": "Bulbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "A strange seed was planted on its back at birth."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurPokemonSpeciesPayload = '''
{
  "name": "ivysaur",
  "generation": {"name": "generation-i"},
  "capture_rate": 45,
  "base_happiness": 50,
  "is_baby": false,
  "is_legendary": false,
  "is_mythical": false,
  "growth_rate": {"name": "medium-slow"},
  "egg_groups": [
    {"name": "monster"},
    {"name": "grass"}
  ],
  "color": {"name": "green"},
  "names": [
    {"language": {"name": "en"}, "name": "Ivysaur"},
    {"language": {"name": "fr"}, "name": "Herbizarre"}
  ],
  "genera": [
    {"language": {"name": "en"}, "genus": "Seed Pokémon"},
    {"language": {"name": "fr"}, "genus": "Pokémon Graine"}
  ],
  "flavor_text_entries": [
    {
      "language": {"name": "en"},
      "flavor_text": "When the bulb on its back grows large, it appears to lose the ability to stand."
    }
  ],
  "evolution_chain": {
    "url": "https://pokeapi.example.test/api/v2/evolution-chain/1/"
  }
}
''';

const String _ivysaurShowdownPayload = '''
{
  "name": "Ivysaur",
  "num": 2,
  "gen": 1,
  "types": ["Grass", "Poison"],
  "baseStats": {
    "hp": 60,
    "atk": 62,
    "def": 63,
    "spa": 80,
    "spd": 80,
    "spe": 60
  },
  "abilities": {
    "0": "Overgrow",
    "H": "Chlorophyll"
  },
  "eggGroups": ["Monster", "Grass"],
  "expType": "Medium Slow",
  "baseExp": 142,
  "catchRate": 45,
  "baseFriendship": 50,
  "heightm": 1.0,
  "weightkg": 13.0
}
''';

const PokemonSpeciesFile _customSlugBulbasaurSpecies = PokemonSpeciesFile(
  id: 'bulbasaur',
  slug: 'bulbizarre-custom',
  nationalDex: 1,
  names: <String, String>{'en': 'Bulbasaur Custom'},
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
  refs: PokemonSpeciesRefs(
    learnset: 'bulbasaur',
    evolution: 'bulbasaur',
    media: 'bulbasaur',
  ),
  dexContent: PokemonSpeciesDexContent(
    heightM: 0.7,
    weightKg: 6.9,
    color: 'green',
    flavorText: 'Custom slug seed for overwrite proof.',
  ),
  gameplayFlags: PokemonSpeciesGameplayFlags(),
  sourceMeta: PokemonSpeciesSourceMeta(
    seededBy: 'test',
    seedVersion: 1,
  ),
);

const String _bulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "base_experience": 64,
  "height": 7,
  "weight": 69,
  "sprites": {
    "front_default": "https://assets.example.test/bulbasaur/front.png",
    "back_default": "https://assets.example.test/bulbasaur/back.png",
    "front_shiny": "https://assets.example.test/bulbasaur/front_shiny.png",
    "back_shiny": "https://assets.example.test/bulbasaur/back_shiny.png",
    "other": {
      "official-artwork": {
        "front_default": "https://assets.example.test/bulbasaur/portrait.png"
      }
    }
  },
  "cries": {
    "latest": "https://assets.example.test/bulbasaur/cry.ogg"
  },
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
    }
  ]
}
''';

const String _legacyBulbasaurPokemonPayload = '''
{
  "name": "bulbasaur",
  "moves": [
    {
      "move": {"name": "cut"},
      "version_group_details": [
        {
          "level_learned_at": 0,
          "move_learn_method": {"name": "machine"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

const String _ivysaurPokemonPayload = '''
{
  "name": "ivysaur",
  "base_experience": 142,
  "height": 10,
  "weight": 130,
  "sprites": {
    "front_default": null,
    "back_default": null,
    "front_shiny": null,
    "back_shiny": null,
    "other": {
      "official-artwork": {
        "front_default": null
      }
    }
  },
  "cries": {
    "latest": null
  },
  "moves": [
    {
      "move": {"name": "razor-leaf"},
      "version_group_details": [
        {
          "level_learned_at": 20,
          "move_learn_method": {"name": "level-up"},
          "version_group": {"name": "scarlet-violet"}
        }
      ]
    }
  ]
}
''';

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

```

### `/Users/karim/Project/pokemonProject/packages/map_editor/test/pokedex_external_batch_dry_run_ui_test.dart`

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/models/pokemon_database_index.dart';
import 'package:map_editor/src/application/models/pokedex_species_detail.dart';
import 'package:map_editor/src/application/models/pokemon_external_batch_selection.dart';
import 'package:map_editor/src/application/models/pokemon_external_query_resolution.dart';
import 'package:map_editor/src/application/models/pokemon_external_species_search_result.dart';
import 'package:map_editor/src/application/models/pokemon_project_data_models.dart';
import 'package:map_editor/src/application/ports/project_workspace.dart';
import 'package:map_editor/src/application/use_cases/import_external_pokemon_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/ui/canvas/pokedex_workspace.dart';

void main() {
  const sampleProject = ProjectManifest(
    name: 'pokedex_external_batch_dry_run_test',
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
          child: MacosApp(
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

  Future<void> openExternalImportStep(WidgetTester tester) async {
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
  }

  Future<void> switchToBatchMode(WidgetTester tester) async {
    await tester.tap(
      find.byKey(const Key('pokedex-import-external-mode-batch-option')),
    );
    await tester.pumpAndSettle();
  }

  PokedexWorkspace buildWorkspace({
    required Future<PokemonExternalBatchSelectionResult> Function(
            String rawQuery)
        externalBatchSelectionResolver,
    required Future<PokemonExternalBatchImportResult> Function(
      ProjectWorkspace workspace,
      List<String> speciesIds,
    ) externalBatchPreviewer,
  }) {
    return PokedexWorkspace(
      loader: (_) async => const <PokemonDatabaseIndexEntry>[],
      detailLoader: (_, __) async => _unusedDetail(),
      importPreviewer: (_, __) async => throw UnimplementedError(),
      importer: (_, __) async => throw UnimplementedError(),
      externalSpeciesSearcher: (rawQuery) async =>
          const PokemonExternalSpeciesSearchResult.empty(
        rawQuery: '',
        normalizedQuery: '',
      ),
      externalBatchSelectionResolver: externalBatchSelectionResolver,
      externalBatchPreviewer: externalBatchPreviewer,
      externalImportPreviewer: (_, __) async => throw UnimplementedError(),
      externalImporter: (_, __) async => throw UnimplementedError(),
    );
  }

  testWidgets('switches to batch mode, resolves targets and unlocks dry-run',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_dry_run_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalBatchSelectionResolver: (rawQuery) async {
          if (rawQuery.trim() == 'pikachu, 25, bulbasaur') {
            return _resolvedBatchSelection();
          }
          return PokemonExternalBatchSelectionResult.empty(
            rawQuery: rawQuery,
            normalizedQuery: rawQuery.trim(),
          );
        },
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);
    await switchToBatchMode(tester);

    final previewButtonFinder = find.byKey(
      const Key('pokedex-import-external-batch-preview-button'),
    );

    expect(
      tester.widget<PushButton>(previewButtonFinder).onPressed,
      isNull,
    );

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      'pikachu, 25, bulbasaur',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.byKey(const Key('pokedex-import-external-batch-resolved-message')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pokedex-import-external-batch-target-pikachu')),
      findsOneWidget,
    );
    expect(
      find.byKey(const Key('pokedex-import-external-batch-target-bulbasaur')),
      findsOneWidget,
    );
    expect(
      find.textContaining('1 doublon(s) éliminé(s)'),
      findsOneWidget,
    );
    expect(
      tester.widget<PushButton>(previewButtonFinder).onPressed,
      isNotNull,
    );
  });

  testWidgets('keeps dry-run blocked for out-of-scope mono queries',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_dry_run_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalBatchSelectionResolver: (rawQuery) async =>
            PokemonExternalBatchSelectionResult.outOfScopeQuery(
          rawQuery: rawQuery,
          normalizedQuery: rawQuery.trim(),
          resolution: const PokemonExternalSingleQueryResolution(
            rawQuery: 'pikachu',
            normalizedQuery: 'pikachu',
            query: PokemonExternalSingleQuery.species(
              rawValue: 'pikachu',
              normalizedValue: 'pikachu',
            ),
          ),
          message:
              'Le mode batch attend une liste explicite, une plage Pokédex '
              'ou une génération.',
        ),
        externalBatchPreviewer: (_, __) async => _sampleBatchDryRunPreview(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);
    await switchToBatchMode(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      'pikachu',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      find.textContaining('liste explicite'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<PushButton>(
            find.byKey(
              const Key('pokedex-import-external-batch-preview-button'),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('shows a dry-run preview and passes resolved species ids',
      (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final previewedSpeciesIds = <List<String>>[];

    container.read(editorNotifierProvider.notifier).state = const EditorState(
      projectRootPath: '/tmp/pokedex_external_batch_dry_run_ui_test',
      project: sampleProject,
      workspaceMode: EditorWorkspaceMode.pokedex,
    );

    await pumpPokedexWidget(
      tester,
      container,
      child: buildWorkspace(
        externalBatchSelectionResolver: (rawQuery) async =>
            _resolvedBatchSelection(),
        externalBatchPreviewer: (_, speciesIds) async {
          previewedSpeciesIds.add(List<String>.from(speciesIds));
          return _sampleBatchDryRunPreview();
        },
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await openExternalImportStep(tester);
    await switchToBatchMode(tester);

    await tester.enterText(
      find.byKey(const Key('pokedex-import-external-batch-query-field')),
      'pikachu, 25, bulbasaur',
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    await tester.tap(
      find.byKey(const Key('pokedex-import-external-batch-preview-button')),
    );
    await tester.pumpAndSettle();

    expect(
      previewedSpeciesIds,
      <List<String>>[
        <String>['pikachu', 'bulbasaur'],
      ],
    );
    expect(
      find.byKey(const Key('pokedex-import-external-batch-preview-step')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-preview-entry-pikachu'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const Key('pokedex-import-external-batch-preview-entry-bulbasaur'),
      ),
      findsOneWidget,
    );
    expect(find.text('Dry-run batch API'), findsOneWidget);
    expect(find.text('Conflit détecté'), findsOneWidget);
    expect(find.text('Aperçu disponible'), findsOneWidget);
    expect(
      find.byKey(const Key('pokedex-import-confirm-button')),
      findsNothing,
    );
  });
}

PokemonExternalBatchSelectionResult _resolvedBatchSelection() {
  return PokemonExternalBatchSelectionResult.resolved(
    rawQuery: 'pikachu, 25, bulbasaur',
    normalizedQuery: 'pikachu, 25, bulbasaur',
    resolution: PokemonExternalExplicitListQueryResolution(
      rawQuery: 'pikachu, 25, bulbasaur',
      normalizedQuery: 'pikachu, 25, bulbasaur',
      queries: const <PokemonExternalSingleQuery>[
        PokemonExternalSingleQuery.species(
          rawValue: 'pikachu',
          normalizedValue: 'pikachu',
        ),
        PokemonExternalSingleQuery.nationalDex(
          rawValue: '25',
          nationalDex: 25,
        ),
        PokemonExternalSingleQuery.species(
          rawValue: 'bulbasaur',
          normalizedValue: 'bulbasaur',
        ),
      ],
    ),
    targets: <PokemonExternalBatchSelectionTarget>[
      PokemonExternalBatchSelectionTarget(
        speciesId: 'pikachu',
        primaryName: 'Pikachu',
        nationalDex: 25,
        generation: 1,
        requestedInputs: const <String>['pikachu', '25'],
      ),
      PokemonExternalBatchSelectionTarget(
        speciesId: 'bulbasaur',
        primaryName: 'Bulbasaur',
        nationalDex: 1,
        generation: 1,
        requestedInputs: const <String>['bulbasaur'],
      ),
    ],
  );
}

PokemonExternalBatchImportResult _sampleBatchDryRunPreview() {
  return PokemonExternalBatchImportResult(
    dryRun: true,
    mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
    entries: <PokemonExternalBatchImportEntryResult>[
      PokemonExternalBatchImportEntryResult(
        speciesId: 'pikachu',
        result: PokemonExternalImportResult(
          requestedSpeciesId: 'pikachu',
          importedSpeciesId: 'pikachu',
          preview: _previewFor(
            speciesId: 'pikachu',
            nationalDex: 25,
            primaryName: 'Pikachu',
            types: const <String>['electric'],
          ),
          dryRun: true,
          mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
          artifacts: const <PokemonExternalImportArtifactResult>[
            PokemonExternalImportArtifactResult(
              kind: PokemonExternalImportArtifactKind.species,
              relativePath: 'data/pokemon/species/0025-pikachu.json',
              action: PokemonExternalImportArtifactAction.create,
              existedBefore: false,
            ),
          ],
          warnings: const <String>[
            'Learnset payload partiel, import best-effort.',
          ],
        ),
      ),
      const PokemonExternalBatchImportEntryResult(
        speciesId: 'bulbasaur',
        result: PokemonExternalImportResult(
          requestedSpeciesId: 'bulbasaur',
          importedSpeciesId: 'bulbasaur',
          preview: PokemonExternalImportPreview(
            speciesId: 'bulbasaur',
            nationalDex: 1,
            primaryName: 'Bulbasaur',
            types: <String>['grass', 'poison'],
            learnset: PokemonExternalImportPreviewArtifact(
              label: 'Learnset',
              isAvailable: true,
            ),
            evolution: PokemonExternalImportPreviewArtifact(
              label: 'Evolution',
              isAvailable: true,
            ),
            media: PokemonExternalImportPreviewArtifact(
              label: 'Media',
              isAvailable: true,
            ),
            cries: PokemonExternalImportPreviewArtifact(
              label: 'Cries',
              isAvailable: false,
            ),
          ),
          dryRun: true,
          mergePolicy: PokemonExternalImportMergePolicy.failOnConflict,
          artifacts: <PokemonExternalImportArtifactResult>[
            PokemonExternalImportArtifactResult(
              kind: PokemonExternalImportArtifactKind.species,
              relativePath: 'data/pokemon/species/0001-bulbasaur.json',
              action: PokemonExternalImportArtifactAction.conflict,
              existedBefore: true,
            ),
          ],
        ),
      ),
    ],
  );
}

PokemonExternalImportPreview _previewFor({
  required String speciesId,
  required int nationalDex,
  required String primaryName,
  required List<String> types,
}) {
  return PokemonExternalImportPreview(
    speciesId: speciesId,
    nationalDex: nationalDex,
    primaryName: primaryName,
    types: types,
    learnset: const PokemonExternalImportPreviewArtifact(
      label: 'Learnset',
      isAvailable: true,
    ),
    evolution: const PokemonExternalImportPreviewArtifact(
      label: 'Evolution',
      isAvailable: true,
    ),
    media: const PokemonExternalImportPreviewArtifact(
      label: 'Media',
      isAvailable: true,
    ),
    cries: const PokemonExternalImportPreviewArtifact(
      label: 'Cries',
      isAvailable: true,
    ),
  );
}

PokedexSpeciesDetail _unusedDetail() {
  return const PokedexSpeciesDetail(
    species: PokemonSpeciesFile(
      id: 'bulbasaur',
      slug: 'bulbasaur',
      nationalDex: 1,
      names: <String, String>{
        'fr': 'Bulbizarre',
        'en': 'Bulbasaur',
      },
      speciesName: <String, String>{
        'fr': 'Pokémon Graine',
        'en': 'Seed Pokemon',
      },
      genIntroduced: 1,
      typing: PokemonSpeciesTyping(types: <String>['grass']),
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
      breeding: PokemonSpeciesBreeding(
        genderRatio: <String, double>{'male': 0.875, 'female': 0.125},
        eggGroups: <String>['monster'],
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
        otherForms: <String>[],
      ),
      classification: PokemonSpeciesClassification(
        isEnabledInProject: true,
        isObtainable: true,
      ),
      refs: PokemonSpeciesRefs(
        learnset: 'bulbasaur',
        evolution: 'bulbasaur',
        media: 'bulbasaur',
      ),
      dexContent: PokemonSpeciesDexContent(
        heightM: 0.7,
        weightKg: 6.9,
        color: 'green',
      ),
      gameplayFlags: PokemonSpeciesGameplayFlags(),
      sourceMeta: PokemonSpeciesSourceMeta(
        seededBy: 'test',
        seedVersion: 1,
      ),
    ),
    learnset: PokemonLearnsetFile(
      speciesId: 'bulbasaur',
      startingMoves: <String>['tackle'],
    ),
    evolution: PokemonEvolutionFile(
      speciesId: 'bulbasaur',
      preEvolution: null,
      evolutions: <PokemonEvolutionEntry>[],
    ),
    media: PokemonMediaFile(
      speciesId: 'bulbasaur',
      defaultFormId: 'base',
      variants: <String, PokemonMediaVariant>{},
    ),
  );
}

```

## 14. Note git

Aucun commit git, amend, rebase, merge, push, tag, stash ou reset n’a été effectué pendant ce lot.
