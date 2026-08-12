# Character Studio — Clôture finale S12

Date : 12 août 2026

Session : S12

Lots : CHS-060 et CHS-061

Périmètre consolidé : CHS-001 à CHS-061

Branche : `main`

## Verdict exécutif

S12 est `DONE`.

CHS-060 supprime l’assertion Riverpod de démarrage sans rendre asynchrones les réconciliations Border suivantes. CHS-061 recertifie la verticale Character Studio depuis les modèles jusqu’au desktop réel, publie la roadmap CHS-001…CHS-061 et ferme le chantier par un dossier unique.

| Lot | Verdict | Preuve principale |
|---|---|---|
| CHS-060 | `DONE` | reproduction de l’assertion, test widget dédié, gate finale 59/59 et analyse éditeur propre |
| CHS-061 | `DONE_WITH_NON_BLOCKING_RESERVATIONS` | 217 tests verticaux, MCP 46/46, host 10/10, build macOS et captures inspectées |
| Character Studio CHS-001…CHS-061 | `DONE` | données, authoring, UI no-code, persistance, export, runtime, UI joueur, transports et desktop couverts |

Les réserves ne masquent pas un défaut Character Studio : trois analyses globales contiennent des informations historiques, et le connecteur Marionette générique chargé dans cette session est encore en version 0.5.0 alors que l’application utilise 0.6.0. Les preuves produit ont été obtenues autrement et sont détaillées ci-dessous.

## Scope et non-goals

Le scope S12 est strictement limité à :

- différer la première réconciliation de sélection Border déclenchée par `EditorNotifier.build()` ;
- conserver les réconciliations synchrones après le démarrage ;
- ajouter la non-régression widget ;
- rejouer les gates Character Studio applicables ;
- vérifier le serveur MCP packagé et son cycle live ;
- construire et ouvrir l’application macOS sur une copie de fixture ;
- synchroniser la roadmap et cette clôture.

Restent hors scope : les informations d’analyse historiques de `map_core`, `map_runtime` et du host, le remplacement du connecteur Marionette externe 0.5.0, une refonte UI supplémentaire et toute mutation du projet utilisateur `le_train_de_17h42`.

## Audit initial

### Passe Audit / architecture — `PASS`

L’audit a relié :

- `EditorNotifier.build()` et son `listenSelf` ;
- `ActiveBorderFeatureController.reconcile()` et `BorderPreviewController.reconcileContext()` ;
- les tests Border, activation de map et harness desktop ;
- les suites Character Studio de `map_core`, `map_authoring`, `map_editor`, `map_runtime` et `map_player_ui` ;
- les rapports S9, la roadmap canonique, le registre de parité et le serveur MCP packagé.

La cause racine observée était précise : lors de la création du provider éditeur, Riverpod appelait immédiatement le listener avec `previous == null`. Celui-ci mutait le provider de sélection Border pendant le build Flutter et déclenchait `Tried to modify a provider while the widget tree was building`.

Le cache, le Character Studio et le contrôleur Border n’étaient pas individuellement défectueux. Le problème était le moment de la première réconciliation.

La règle de rapport locale demande des sub-agents ou, à défaut, des passes séparées. L’instruction d’environnement de cette tâche interdisait de créer des sub-agents sans demande explicite de l’utilisateur ; les cinq passes Audit/Architecture, Implémentation, Tests, Build/Validation et Critique finale ont donc été exécutées séparément par l’agent principal. De même, aucun commentaire de code n’a été ajouté : la règle racine `AGENTS.md`, plus prioritaire, demande du code auto-explicatif sans commentaires sauf requête explicite.

### État Git initial

```text
## main...origin/main [ahead 5]
```

Le worktree était propre. Les cinq commits locaux correspondaient aux lots S10/S11 déjà isolés. Aucun stash, reset, restore, rebase, merge ou push n’a été utilisé dans S12.

## CHS-060 — Réconciliation sûre au démarrage

### Passe Implémentation — `PASS`

#### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

Zone : `EditorNotifier.build()`.

Modification :

- extraction de `reconcileBorderState(EditorState next)` ;
- première notification `listenSelf` différée par `Future<void>.microtask` ;
- garde `ref.mounted` avant la réconciliation différée ;
- lecture de `state` au moment de la microtask afin de ne pas réappliquer un snapshot initial devenu obsolète ;
- chemin synchrone conservé pour toutes les notifications possédant un état précédent.

Impact : le montage ne modifie plus un provider pendant la construction de l’arbre, tandis que sélection, suppression, changement de map et preview continuent à se réconcilier immédiatement après le démarrage.

#### `packages/map_editor/test/features/editor/state/editor_notifier_startup_reconciliation_test.dart`

Nouveau test widget :

- prépare une sélection Border réelle dans un `ProviderContainer` ;
- monte `activeBorderFeatureControllerProvider` et `editorNotifierProvider` dans le même build ;
- prouve l’absence d’exception Flutter/Riverpod ;
- prouve que la sélection initiale est bien réconciliée après la microtask.

Le test a d’abord échoué avec l’assertion Riverpod et la pile passant par `ActiveBorderFeatureController.reconcile` puis `EditorNotifier.build`. Il passe après le correctif.

### Commit du lot

```text
c0d6fa36a fix(editor): defer startup selection reconciliation
```

Le commit contient exactement deux fichiers : 81 insertions et 1 suppression.

## CHS-061 — Certification finale

### Passe Tests — `PASS` pour le périmètre

| Périmètre | Commande | Résultat frais |
|---|---|---:|
| CHS-060 et régressions Border | `cd packages/map_editor && flutter test test/dev/marionette_main_test.dart test/features/editor/state/editor_notifier_startup_reconciliation_test.dart test/border_map_editing/active_border_feature_controller_test.dart test/border_map_editing/border_feature_editor_integration_test.dart test/features/editor/state/editor_notifier_map_activation_test.dart` | 59/59 |
| Modèles et contrats | `cd packages/map_core && dart test test/project_character_studio_model_test.dart test/project_character_studio_migration_test.dart test/project_character_studio_validation_test.dart test/character_studio_reference_index_test.dart test/runtime_dialogue_portrait_metadata_test.dart test/character_custom_animation_runtime_contract_test.dart test/cinematic_character_custom_animation_contract_test.dart` | 43/43 |
| Authoring et parité | `cd packages/map_authoring && dart test test/domains/gameplay/character_studio_resource_test.dart test/domains/gameplay/character_studio_portrait_state_actions_test.dart test/domains/gameplay/character_studio_animation_definition_actions_test.dart test/domains/gameplay/character_studio_character_actions_test.dart test/domains/gameplay/character_studio_animation_clip_actions_test.dart test/domains/assets/character_studio_asset_actions_test.dart test/parity/character_studio_full_parity_test.dart` | 53/53 |
| Éditeur Character Studio | `cd packages/map_editor && flutter test -r compact test/features/character_studio test/character_studio_export_asset_closure_test.dart test/character_studio_golden_slice_e2e_test.dart test/character_studio_workspace_routing_test.dart` | 90/90 |
| Runtime Character Studio | `cd packages/map_runtime && flutter test -r compact test/character_animation_source_resolver_test.dart test/character_custom_animation_runtime_test.dart test/character_studio_golden_slice_runtime_test.dart test/cinematic_custom_character_animation_test.dart test/dialogue_portrait_resolver_test.dart` | 20/20 |
| UI joueur | `cd packages/map_player_ui && flutter test -r compact test/player_dialogue_overlay_test.dart test/player_dialogue_portrait_overlay_test.dart` | 11/11 |
| Host jouable | `cd examples/playable_runtime_host && flutter test -r compact test/phase_a_golden_slice_launch_test.dart` | 10/10 |
| MCP packagé | `cd tools/pokemap_mcp && npm run check && npm test` | check vert, 46/46 tests |

Les cinq packages de la verticale Character Studio totalisent 217 tests réussis. Avec le smoke host, le total produit atteint 227 ; avec les 46 tests du serveur MCP, 273 ; puis 332 en incluant la gate CHS-060 de 59 tests, volontairement conservée à part car elle recouvre aussi des régressions Border et d’activation de map.

Une exploration plus large de `test/border_map_editing` a aussi été lancée pendant CHS-060. Elle a exposé huit échecs de fixtures historiques, notamment des manifestes v2 rejetés par le preflight v6 et des attentes de sauvegarde antérieures. Les tests Border CRUD, activation et la nouvelle non-régression passent dans la gate focalisée ; ces huit échecs ne sont pas attribués au diff S12 et n’ont pas été réparés hors scope.

### Analyses

| Package | Commande | Résultat frais |
|---|---|---|
| `map_core` | `dart analyze` | exit 0, 121 informations historiques |
| `map_authoring` | `dart analyze` | exit 0, aucun diagnostic |
| `map_editor` | `flutter analyze` | exit 0, aucun diagnostic, 30,1 s après CHS-060 puis 11,8 s lors de la gate finale |
| `map_runtime` | `flutter analyze` | exit 1, 7 informations historiques |
| `map_player_ui` | `flutter analyze` | exit 0, aucun diagnostic |
| host jouable | `flutter analyze` | exit 1, 27 informations historiques |

Les exits 1 de `map_runtime` et du host sont dus à des règles configurées pour faire échouer l’analyse sur des informations. Les diagnostics concernent des noms de bibliothèque, imports redondants, underscores multiples et un commentaire interprété comme HTML. Aucun ne touche les fichiers S12.

### MCP direct, JSONL/CLI, éditeur et serveur live

Le serveur reconstruit par `npm test` passe 46/46, y compris le test CHS-059 qui publie la preuve des 25 actions Character Studio.

Le connecteur PokeMap live de la session a ensuite exécuté :

1. `pokemap_describe` : 25 actions Character Studio et quatre ressources (`characterStudioCatalog`, `characterStudioCharacter`, `characterStudioDependency`, `characterStudioReadiness`) découvertes ;
2. `pokemap_workspace(open)` sur `examples/playable_runtime_host/golden_fangame_slice` ;
3. `pokemap_query(summary)` sur `characterStudioCatalog` à la révision `sha256:4bfb16c58403d8640a6be7c8be9915264a2dab14f3b0fd36d1fead51f1b53979` ;
4. `pokemap_validate` : projet valide à la même révision ;
5. `pokemap_workspace(close)` : workspace fermé.

Réserve d’hôte : le processus MCP connecté à cette tâche avait été chargé avant le commit CHS-059. Son `fullParity` en mémoire expose encore des tableaux de preuves vides, alors que le serveur fraîchement construit et lancé par la suite packagée certifie ces preuves. La surface d’actions et le cycle live sont corrects ; redémarrer le connecteur rafraîchira seulement les métadonnées en mémoire.

### Passe Build / validation desktop — `PASS_WITH_TOOLING_RESERVATION`

Commande :

```bash
cd packages/map_editor
flutter build macos --debug
```

Résultat :

```text
✓ Built build/macos/Build/Products/Debug/PokeMap.app
```

Validation réelle :

- copie jetable de `examples/playable_runtime_host/golden_fangame_slice` créée sous `/private/tmp` ;
- hash SHA-256 normalisé avant/après identique : `3455b4d58d9dec75e0f1938a3aadadde318212d18b451beafb91d029a3b37114` ;
- bundle de build jetable signé ad hoc sans entitlements afin que le projet `/private/tmp` soit lisible, sans modifier le projet Xcode ni l’application installée ;
- contexte projet, path actif et ouverture du Character Studio confirmés par les extensions VM Service du harness ;
- capture 1920 × 1080 : `/private/tmp/pokemap-s12-character-studio.png` ;
- aucune assertion Riverpod ni exception dans les logs après ouverture ;
- répertoires QA exacts supprimés après vérification ;
- processus `/Applications/PokeMap.app` préexistant laissé intact.

Le connecteur Marionette générique disponible dans la tâche utilise `marionette_mcp 0.5.0` tandis que le package dépend de `marionette_flutter 0.6.0`. Sa connexion a échoué explicitement sur ce mismatch. Les mêmes extensions ont donc été appelées directement via le VM Service du build jetable ; cette réserve porte sur l’outil externe, pas sur l’application.

### Preuves visuelles inspectées

- capture desktop réelle : shell complet, projet `Golden Fangame Slice`, Character Studio ouvert, état vide cohérent et aucun crash ;
- golden suivi `packages/map_editor/test/goldens/character_studio/character_studio_real-sprite-previews_1920x1080.png` : personnage réel visible dans la bibliothèque, les huit cartes Base/Marche et l’aperçu live ;
- test golden rejoué dans la suite éditeur 90/90, sans mise à jour opportuniste des images.

## Synchronisation roadmap

`documentation/reports/roadmap/editor/character_studio_roadmap.md` est devenu l’état canonique :

- statut global `DONE` ;
- CHS-001 à CHS-054 cochés d’après les lots et la clôture S9 ;
- phase 6 ajoutée avec CHS-055 à CHS-061 ;
- sessions S10, S11 et S12 ajoutées ;
- 42 lots, 7 phases et 12 sessions explicités ;
- liens vers les commits CHS-055 à CHS-060 et vers cette clôture.

## Inventaire des fichiers modifiés dans S12

| Fichier | Zone | Raison | Impact |
|---|---|---|---|
| `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` | `EditorNotifier.build()` | différer la seule notification initiale | supprime l’assertion sans affaiblir les réconciliations suivantes |
| `packages/map_editor/test/features/editor/state/editor_notifier_startup_reconciliation_test.dart` | nouveau test widget | reproduire et verrouiller le montage multi-provider | non-régression précise et durable |
| `documentation/reports/roadmap/editor/character_studio_roadmap.md` | statut, phase 6, sessions, DoD | synchroniser CHS-001…CHS-061 | roadmap cohérente avec les commits exécutés |
| `documentation/reports/editor/character_studio_final_closure_2026-08-12.md` | document complet | regrouper preuves, limites et décision | une seule source de clôture finale |

Aucun modèle, codec, payload MCP, runtime ou écran Character Studio n’est modifié par CHS-061.

## Hygiène et état Git final

Commandes de clôture :

```bash
POKEMAP_MARKDOWN_MAX_NEW=1 bash tools/scripts/check_markdown_hygiene.sh
git diff --check
git status --short --branch
```

Résultats :

- hygiène Markdown : succès, exactement un nouveau fichier Markdown dans un emplacement canonique ; l’override borné à 1 correspond à cette clôture unique explicitement prévue par CHS-061 ;
- `git diff --check` : succès, aucune erreur d’espace ;
- état avant commit CHS-061 : `main...origin/main [ahead 6]`, uniquement la roadmap modifiée et cette clôture non suivie ;
- commit du lot : `docs(character-studio): certify final closure` ;
- état final vérifié immédiatement après commit : `main...origin/main [ahead 7]`, worktree propre ;
- aucun push effectué.

## Passe Critique finale

### Verdict — `PASS_WITH_RISKS`

Points activement recherchés :

- aucune modification Riverpod inutile hors `build()` ;
- aucun snapshot initial capturé dans la microtask ;
- aucune réconciliation post-démarrage rendue asynchrone ;
- aucune reformatation massive conservée dans le diff ;
- aucune mutation du projet utilisateur ou du golden fixture source ;
- aucune capture présentée comme preuve de sprites quand elle ne contient qu’un état vide ;
- aucune analyse globale en échec présentée comme verte ;
- aucune action Character Studio supposée disponible sans découverte MCP.

Risques résiduels non bloquants :

1. le connecteur Marionette générique doit être aligné sur 0.6.0 pour restaurer le parcours visuel standard ;
2. le processus MCP de la tâche doit être redémarré pour recharger les métadonnées `fullParity` du commit CHS-059 ;
3. les 121/7/27 informations des analyses globales restent une dette séparée ;
4. les huit fixtures Border historiques méritent un lot autonome si leur compatibilité v2 est encore contractuelle ;
5. le golden prouve fidèlement la composition et les sprites, mais n’est pas un test perceptuel humain de chaque frame animée.

Décision : aucun de ces risques ne justifie de rouvrir un lot Character Studio. Les corrections futures doivent rester isolées de CHS-001…CHS-061.
