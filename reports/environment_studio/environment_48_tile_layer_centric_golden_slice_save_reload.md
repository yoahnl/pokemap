# Environment-48 — TileLayer-centric Golden Slice Save / Reload V0

## 1. Résumé

Environment-48 ajoute un test de validation bout-en-bout pour le workflow Environment TileLayer-centric après sauvegarde et rechargement.

Le test créé prépare un projet réel dans un répertoire temporaire, écrit `project.json` et `maps/golden.json` via les repositories fichiers existants, charge le projet avec `EditorNotifier.loadProject` / `loadMap`, effectue une suppression individuelle et un ajout individuel généré, sauvegarde avec `saveActiveMap`, recharge dans un `ProviderContainer` neuf, puis vérifie les invariants de persistence, read model, grouping `LayersPanel` et états transients.

Code produit modifié : non. Le lot est limité à un test et à ce rapport.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector pilote l’environnement.
- `EnvironmentLayer` reste technique dans le modèle.
- Ce lot valide le cycle persistence / reload du Golden Slice TileLayer-centric.
- Aucune migration modèle n’est introduite.
- Aucun nouveau comportement métier n’est ajouté.

## 3. Orchestration sub-agents

Une tentative de création de nouveaux sub-agents a échoué avec la limite de threads de la session : `collab spawn failed: agent thread limit reached`.

Fallback utilisé : réutilisation d’agents existants via `send_input`, en lecture seule.

- Sub-agent A / Persistence : a confirmé la stratégie de vrai round-trip disque avec `FileProjectRepository`, `FileMapRepository`, `EditorNotifier.loadProject`, `EditorNotifier.loadMap` et `EditorNotifier.saveActiveMap`.
- Sub-agent B / Model invariants : a identifié les fixtures utiles dans les tests add/delete existants et les invariants à porter dans le test Golden Slice.
- Sub-agent C / LayersPanel grouping : a confirmé l’API exacte `buildLayerPanelPresentationRows(map, activeLayerId: ...)` et les assertions sur `environmentAttachmentLabel`, `attachedEnvironmentLayerIds` et `isTechnicalEnvironmentSelection`.
- Sub-agent D / Transient state : a confirmé que `environmentMaskEditMode`, `environmentGeneratedPlacementAddElementProvider`, `environmentMaskBrushSizeProvider`, hover et ghost preview sont editor-only / provider-only / painter-only, et non persistés dans `MapData` ou `ProjectManifest`.
- QA / Evidence Pack : exécutée localement dans la session principale.

Mini-plan retenu avant le code :

1. Stratégie save/reload : Option A, vrai disque via repositories fichiers et notifier.
2. Fichiers à modifier : un nouveau test dans `packages/map_editor/test/environment_studio/` et ce rapport.
3. Tests à créer : `tile_layer_environment_golden_slice_save_reload_test.dart`.
4. Sub-agents / passes utilisés : A à D en audit read-only, QA locale.
5. Limite : pas de nouveau test widget complet, car le grouping est prouvé via le presentation helper et les tests widget existants restent en non-régression.

## 4. Audit persistence

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_editor/lib/src/features/editor/application/project_session_controller.dart`
- `packages/map_editor/lib/src/features/editor/application/map_editing_controller.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generation_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_clear_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_regenerate_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_area_settings_use_cases.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel_presentation.dart`
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart`
- `packages/map_editor/lib/src/infrastructure/repositories/file_repositories.dart`
- `packages/map_editor/lib/src/infrastructure/filesystem/project_filesystem.dart`
- `packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart`

Mécanisme identifié :

- `FileProjectRepository.saveProject/loadProject` écrit et relit `project.json`.
- `FileMapRepository.saveMap/loadMap` écrit et relit les maps JSON avec validation et migration JSON.
- `EditorNotifier.loadProject` ouvre la session projet depuis le manifest disque.
- `EditorNotifier.loadMap` résout le chemin via `ProjectFileSystem` et ouvre la map active.
- `EditorNotifier.saveActiveMap` écrit la map active sur le chemin réel `activeMapPath`.

Choix retenu : Option A, vrai round-trip disque.

Limite : le test n’utilise pas un widget complet pour recharger toute l’application graphique. Il utilise les repositories, le notifier, les providers et les modèles de présentation, ce qui couvre la persistence et les projections de manière ciblée et non fragile.

## 5. Scénario testé

Setup :

- `ProjectManifest` avec map `golden`, tileset `nature`, catégorie d’éléments, éléments `tree`, `bush`, `big_tree`, et preset `forest`.
- `MapData` avec `TileLayer` cible `tiles`.
- `EnvironmentLayer` technique `env` attaché à `tiles`.
- `EnvironmentArea` `area` avec preset `forest`, masque non vide, seed `17`, `paramsOverride`, et deux placements générés initiaux.
- Une deuxième area `other` avec son propre placement généré pour prouver l’isolation.
- Un placement manuel `manual_tree` à préserver.

Opérations avant save :

- Chargement projet/map depuis disque via `EditorNotifier`.
- Sélection TileLayer `tiles` + area `area`.
- Démarrage suppression individuelle.
- Suppression du placement généré `generated_delete` par clic dans son footprint.
- Sélection de l’élément palette `bush`.
- Démarrage ajout individuel.
- Ajout du placement généré `env_gen_area_4_0_bush`.
- Mise en place volontaire d’états transients avant save : mode `generatedAdd`, brush size `7`, hover tile.
- Sauvegarde via `saveActiveMap`.

Round-trip :

- Rechargement du même `project.json` et `maps/golden.json` dans un `ProviderContainer` neuf.

Assertions après reload :

- données environnement conservées ;
- placements cohérents ;
- read model TileLayer-centric correct ;
- grouping `LayersPanel` correct ;
- états transients revenus aux valeurs par défaut ;
- modèle rechargé encore opérable via clear TileLayer-centric.

## 6. Invariants validés

Environment data :

- `EnvironmentLayer` existe encore dans `MapData`.
- `EnvironmentLayer.content.targetTileLayerId == 'tiles'`.
- `EnvironmentArea area` existe.
- `presetId == 'forest'`.
- masque conservé.
- `mask.activeCellCount > 0`.
- `seed == 17`.
- `paramsOverride == _params`.
- `generatedPlacementIds == ['generated_keep', 'env_gen_area_4_0_bush']`.

Placements :

- chaque id généré de l’area active existe dans `map.placedElements`.
- chaque placement généré de l’area active a `layerId == 'tiles'`.
- `generated_delete` ne revient pas après reload.
- `env_gen_area_4_0_bush` reste présent après reload.
- `manual_tree` reste présent.
- `manual_tree` n’est pas dans `generatedPlacementIds`.
- `other_generated` et l’area `other` restent inchangés.
- aucun id dupliqué dans les `generatedPlacementIds` de l’area active.

Read model :

- `hasAttachment == true`.
- `activeTileLayerId == 'tiles'`.
- `attachedEnvironmentLayerId == 'env'`.
- `hasMask == true`.
- `generatedPlacementCount == 2`.
- `existingGeneratedPlacementCount == 2`.
- `missingGeneratedPlacementCount == 0`.
- `selectedAreaHasParamsOverride == true`.
- `selectedAreaSeed == 17`.
- `canClearGeneratedPlacements == true`.
- `canRegenerate == true`.
- `canShuffle == true`.
- `canAddGeneratedPlacement == true`.

Layer grouping :

- rows visibles : `['tiles', 'objects']`.
- row `tiles` affiche `Environnement actif`.
- `attachedEnvironmentLayerIds == ['env']`.
- si `activeLayerId == 'env'`, la row TileLayer reste active et indique la sélection technique.
- l’`EnvironmentLayer` valide attaché n’est pas affiché comme row top-level normale.

Transient state :

- `environmentMaskEditMode` est `null` après reload neuf.
- `selectedEnvironmentAreaId` est `null` après reload neuf.
- `hoveredTile` est `null`.
- `environmentGeneratedPlacementAddElementProvider` est `null`.
- `environmentMaskBrushSizeProvider` revient à `kDefaultEnvironmentMaskBrushSize`.
- le JSON sauvegardé ne contient pas `generatedAdd`, `hoveredTile` ni `environmentMaskEditMode`.

Action après reload :

- `ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase` supprime `generated_keep` et `env_gen_area_4_0_bush`.
- le placement manuel `manual_tree` reste présent.
- le placement de l’autre area `other_generated` reste présent.

## 7. Tests

Commande ciblée finale :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
```

Résultat exact :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
00:00 +0: Environment-48 Golden Slice save/reload préserve environnement, placements, grouping et reste clearable après reload
FileProjectRepository: Validating and saving project to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/project.json
FileMapRepository: Validating and saving map to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/maps/golden.json
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/project.json
EditorNotifier: loadMap(maps/golden.json)
FileMapRepository: Loading map from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/maps/golden.json
EditorNotifier: saveActiveMap()
FileMapRepository: Validating and saving map to /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/maps/golden.json
EditorNotifier: loadProject(/var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/project.json)
FileProjectRepository: Loading project from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/project.json
EditorNotifier: loadMap(maps/golden.json)
FileMapRepository: Loading map from /var/folders/b5/7gsfwzyd449_54n8l40h40gc0000gn/T/env48_save_reload_68dDg6/maps/golden.json
00:00 +1: All tests passed!
```

Non-régressions lancées :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_golden_slice_workflow_test.dart
00:00 +0: Golden Slice — workflow notifier complet generate → clear → generate → regenerate → shuffle ; manuel conservé
00:00 +1: Golden Slice — workflow notifier complet shuffle sans placements générés préalables : seed change et placements
00:00 +2: Golden Slice — workflow notifier complet clear sans placements : message statut, carte inchangée
00:00 +3: Golden Slice — inspecteur minimal résumé + Generate activé quand prêt
00:00 +4: Golden Slice — inspecteur minimal Generate désactivé sans cible TileLayer
00:00 +5: Golden Slice — validation finale (Lot 29) generate → clear → generate → regenerate → shuffle : invariants manifest, tuiles, masque, sélection, ids
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart
00:00 +0: TileLayer environment layer grouping presentation TileLayer sans EnvironmentLayer reste une row normale
00:00 +1: TileLayer environment layer grouping presentation EnvironmentLayer attaché valide est groupé sur le TileLayer cible
00:00 +2: TileLayer environment layer grouping presentation EnvironmentLayer target manquant reste visible avec warning
00:00 +3: TileLayer environment layer grouping presentation EnvironmentLayer target non TileLayer reste visible avec warning
00:00 +4: TileLayer environment layer grouping presentation plusieurs EnvironmentLayers attachés au même TileLayer sont comptés
00:00 +5: TileLayer environment layer grouping presentation EnvironmentLayer attaché actif reste compréhensible via le TileLayer
00:00 +6: TileLayer environment layer grouping presentation ordre des autres layers préservé
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
00:00 +0: AddTileLayerEnvironmentGeneratedPlacementAtUseCase ajoute un placement généré à une position valide
00:00 +1: AddTileLayerEnvironmentGeneratedPlacementAtUseCase génère un id suffixé si l’id stable est déjà utilisé
00:00 +2: AddTileLayerEnvironmentGeneratedPlacementAtUseCase refuse les entrées et positions invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart
00:00 +0: DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase supprime un placement généré cliqué dans son footprint
00:00 +1: DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase préserve les placements manuels et les placements d’une autre area
00:00 +2: DeleteTileLayerEnvironmentGeneratedPlacementAtUseCase refuse les entrées invalides sans mutation
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
00:00 +0: TileLayerEnvironmentAttachmentReadModel retourne un empty state quand le projet est null
00:00 +1: TileLayerEnvironmentAttachmentReadModel retourne un état neutre quand la map est null
00:00 +2: TileLayerEnvironmentAttachmentReadModel retourne un état neutre quand aucun layer est sélectionné
00:00 +3: TileLayerEnvironmentAttachmentReadModel détecte un TileLayer sans environnement attaché
00:00 +4: TileLayerEnvironmentAttachmentReadModel détecte un TileLayer avec EnvironmentLayer attaché
00:00 +5: TileLayerEnvironmentAttachmentReadModel détecte plusieurs EnvironmentLayers attachés au même TileLayer
00:00 +6: TileLayerEnvironmentAttachmentReadModel détecte un EnvironmentLayer sélectionné directement en mode legacy
00:00 +7: TileLayerEnvironmentAttachmentReadModel détecte targetTileLayerId manquant
00:00 +8: TileLayerEnvironmentAttachmentReadModel détecte target layer inexistant
00:00 +9: TileLayerEnvironmentAttachmentReadModel détecte target layer non TileLayer
00:00 +10: TileLayerEnvironmentAttachmentReadModel détecte absence d’area
00:00 +11: TileLayerEnvironmentAttachmentReadModel détecte area sélectionnée valide
00:00 +12: TileLayerEnvironmentAttachmentReadModel détecte area sélectionnée absente
00:00 +13: TileLayerEnvironmentAttachmentReadModel utilise la seule area existante quand aucune sélection est fournie
00:00 +14: TileLayerEnvironmentAttachmentReadModel demande une sélection quand plusieurs areas existent sans sélection
00:00 +15: TileLayerEnvironmentAttachmentReadModel expose les summaries de zones dans l’ordre avec compteurs
00:00 +16: TileLayerEnvironmentAttachmentReadModel summary signale un preset manquant
00:00 +17: TileLayerEnvironmentAttachmentReadModel détecte preset valide
00:00 +18: TileLayerEnvironmentAttachmentReadModel expose les paramètres effectifs depuis le preset sans override
00:00 +19: TileLayerEnvironmentAttachmentReadModel expose les paramètres effectifs depuis paramsOverride
00:00 +20: TileLayerEnvironmentAttachmentReadModel désactive les paramètres si le preset est manquant
00:00 +21: TileLayerEnvironmentAttachmentReadModel désactive les paramètres si aucune area effective est sélectionnée
00:00 +22: TileLayerEnvironmentAttachmentReadModel détecte preset manquant
00:00 +23: TileLayerEnvironmentAttachmentReadModel détecte masque vide
00:00 +24: TileLayerEnvironmentAttachmentReadModel détecte masque non vide
00:00 +25: TileLayerEnvironmentAttachmentReadModel compte generatedPlacementIds et placements manquants
00:00 +26: TileLayerEnvironmentAttachmentReadModel expose la palette du preset avec la sélection et les éléments manquants
00:00 +27: TileLayerEnvironmentAttachmentReadModel désactive l’ajout individuel si tous les éléments sont manquants
00:00 +28: TileLayerEnvironmentAttachmentReadModel retourne un état neutre pour un layer non TileLayer
00:00 +29: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
00:00 +0: TileLayerEnvironmentInspectorSection affiche Aucun environnement sur ce layer
00:00 +1: TileLayerEnvironmentInspectorSection affiche Activer l’environnement sans callback de mutation
00:00 +2: TileLayerEnvironmentInspectorSection active Activer l’environnement avec callback
00:00 +3: TileLayerEnvironmentInspectorSection bloque Ajouter une zone si aucun preset existe
00:00 +4: TileLayerEnvironmentInspectorSection active Ajouter une zone avec un preset unique
00:00 +5: TileLayerEnvironmentInspectorSection bloque Ajouter une zone avec plusieurs presets sans sélection
00:00 +6: TileLayerEnvironmentInspectorSection active Ajouter une zone avec plusieurs presets et sélection
00:00 +7: TileLayerEnvironmentInspectorSection affiche un état prêt avec preset zone et masque
00:00 +8: TileLayerEnvironmentInspectorSection affiche le feedback prêt avec seed et densité
00:00 +9: TileLayerEnvironmentInspectorSection affiche le nombre de placements générés
00:00 +10: TileLayerEnvironmentInspectorSection affiche la liste des zones d’environnement
00:00 +11: TileLayerEnvironmentInspectorSection cliquer sur Sélectionner déclenche le callback area
00:00 +12: TileLayerEnvironmentInspectorSection affiche preset et placements manquants dans une summary
00:00 +13: TileLayerEnvironmentInspectorSection affiche un warning si des placements sont manquants
00:00 +14: TileLayerEnvironmentInspectorSection affiche une erreur si le preset est manquant
00:01 +15: TileLayerEnvironmentInspectorSection affiche un message legacy
00:01 +16: TileLayerEnvironmentInspectorSection Générer dans ce layer reste désactivé sans callback
00:01 +17: TileLayerEnvironmentInspectorSection Générer dans ce layer est actif avec callback
00:01 +18: TileLayerEnvironmentInspectorSection Générer dans ce layer reste désactivé si canGenerate false
00:01 +19: TileLayerEnvironmentInspectorSection active Peindre le masque avec callback
00:01 +20: TileLayerEnvironmentInspectorSection affiche Effacer du masque quand le masque est éditable
00:01 +21: TileLayerEnvironmentInspectorSection active Effacer du masque avec callback
00:01 +22: TileLayerEnvironmentInspectorSection affiche Taille du pinceau et les choix 1 3 5 7
00:01 +23: TileLayerEnvironmentInspectorSection cliquer sur 3 change la taille du pinceau
00:01 +24: TileLayerEnvironmentInspectorSection sans callback les tailles de pinceau sont désactivées
00:01 +25: TileLayerEnvironmentInspectorSection affiche Peinture active et stop quand le mode est actif
00:01 +26: TileLayerEnvironmentInspectorSection affiche Effacement actif et garde la taille visible
00:01 +27: TileLayerEnvironmentInspectorSection affiche les paramètres de génération éditables du preset
00:01 +28: TileLayerEnvironmentInspectorSection changer le slider density construit un override complet
00:01 +29: TileLayerEnvironmentInspectorSection changer le slider spacing construit un override entier
00:01 +30: TileLayerEnvironmentInspectorSection sans callback les sliders de génération sont grisés
00:01 +31: TileLayerEnvironmentInspectorSection override local active reset et seed
00:01 +32: TileLayerEnvironmentInspectorSection preset manquant affiche des paramètres non modifiables
00:01 +33: TileLayerEnvironmentInspectorSection après création avec masque vide la brush reste désactivée
00:01 +34: TileLayerEnvironmentInspectorSection Effacer les placements générés reste désactivé sans callback
00:01 +35: TileLayerEnvironmentInspectorSection Effacer les placements générés est actif avec callback
00:01 +36: TileLayerEnvironmentInspectorSection Effacer les placements générés reste désactivé sans placement généré
00:01 +37: TileLayerEnvironmentInspectorSection Régénérer reste désactivé sans callback
00:01 +38: TileLayerEnvironmentInspectorSection Régénérer est actif avec callback
00:01 +39: TileLayerEnvironmentInspectorSection Régénérer reste désactivé sans generatedPlacementIds même avec callback
00:01 +40: TileLayerEnvironmentInspectorSection Shuffle reste désactivé sans callback
00:01 +41: TileLayerEnvironmentInspectorSection Shuffle est actif avec callback
00:01 +42: TileLayerEnvironmentInspectorSection Shuffle reste désactivé sans generatedPlacementIds même avec callback
00:01 +43: TileLayerEnvironmentInspectorSection affiche Palette du preset et les éléments disponibles
00:01 +44: TileLayerEnvironmentInspectorSection sélection d’un élément généré déclenche le callback
00:01 +45: TileLayerEnvironmentInspectorSection Ajouter un élément généré désactivé sans generated placements
00:01 +46: TileLayerEnvironmentInspectorSection Ajouter un élément généré désactivé sans sélection quand plusieurs items
00:01 +47: TileLayerEnvironmentInspectorSection Ajouter un élément généré actif avec élément sélectionné
00:01 +48: TileLayerEnvironmentInspectorSection mode ajout actif affiche stop et aide
00:01 +49: TileLayerEnvironmentInspectorSection Supprimer un élément généré reste désactivé sans generated placements
00:01 +50: TileLayerEnvironmentInspectorSection Supprimer un élément généré reste désactivé sans callback
00:01 +51: TileLayerEnvironmentInspectorSection Supprimer un élément généré est actif avec callback
00:02 +52: TileLayerEnvironmentInspectorSection mode suppression actif affiche stop et aide
00:02 +53: All tests passed!
```

## 8. Analyse ciblée

Première analyse ciblée :

```bash
cd packages/map_editor
flutter analyze test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
```

Résultat exact :

```text
Analyzing tile_layer_environment_golden_slice_save_reload_test.dart...     

   info • Use 'const' with the constructor to improve performance • test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart:290:7 • prefer_const_constructors

1 issue found. (ran in 1.8s)
```

Correctif appliqué : ajout de `const` au `TileLayer` du fixture `_map()`.

Analyse ciblée finale :

```bash
cd packages/map_editor
flutter analyze test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
```

Résultat exact :

```text
Analyzing tile_layer_environment_golden_slice_save_reload_test.dart...     
No issues found! (ran in 1.6s)
```

Dette préexistante hors lot : aucune détectée par l’analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers créés par Environment-48 :

- `packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart`
- `reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md`

Fichiers modifiés par Environment-48 :

- Aucun fichier produit existant.
- Aucun fichier de test existant.

Fichiers préexistants dans le worktree non touchés :

- Aucun au début du lot. Le `git status --short --untracked-files=all` initial ne produisait aucune sortie.

## 10. Non-objectifs respectés

- Pas de nouvelle feature.
- Pas de migration modèle.
- Pas de modification `map_core`.
- Pas de modification `map_runtime`.
- Pas de modification `map_gameplay`.
- Pas de modification `map_battle`.
- Pas de modification des use cases generate / clear / regenerate / shuffle / add / delete.
- Pas de modification de la persistence globale.
- Pas de modification du modèle JSON.
- Pas de modification des codecs générés.
- Pas de build_runner.
- Pas de generated files.
- Pas de refonte inspector.
- Pas de refonte `LayersPanel`.
- Pas de preview de génération.
- Pas de pin / lock placement.
- Pas de rename / delete area.

## 11. Evidence pack

Git status initial :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
```

Git diff stat :

```bash
git diff --stat
```

Résultat exact :

```text
```

Note : les fichiers de ce lot sont non suivis, donc `git diff --stat` ne les liste pas tant qu’ils ne sont pas indexés. Ils sont listés dans le status final.

Git diff name-only :

```bash
git diff --name-only
```

Résultat exact :

```text
```

Git diff check :

```bash
git diff --check
```

Résultat exact :

```text
```

Commandes principales :

- `git status --short --untracked-files=all`
- `find .. -name AGENTS.md -print`
- `rg -n "save|reload|load|ProjectSession|ProjectManifest|MapData|toJson|fromJson|encode|decode|writeAsString|readAsString|projectRoot|activeMap|maps|saveProject|loadProject" packages/map_core/lib/src packages/map_editor/lib/src packages/map_editor/test`
- `flutter test test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart`
- `flutter test test/environment_studio/environment_golden_slice_workflow_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_layer_grouping_presentation_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_individual_delete_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `flutter analyze test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart`
- `git diff --check`

Résultats de tests :

- `tile_layer_environment_golden_slice_save_reload_test.dart` : `00:00 +1: All tests passed!`
- `environment_golden_slice_workflow_test.dart` : `00:00 +6: All tests passed!`
- `tile_layer_environment_layer_grouping_presentation_test.dart` : `00:00 +7: All tests passed!`
- `tile_layer_environment_individual_add_use_case_test.dart` : `00:00 +3: All tests passed!`
- `tile_layer_environment_individual_delete_use_case_test.dart` : `00:00 +3: All tests passed!`
- `tile_layer_environment_attachment_read_model_test.dart` : `00:00 +29: All tests passed!`
- `tile_layer_environment_inspector_section_test.dart` : `00:02 +53: All tests passed!`

Résultat d’analyse :

- Analyse ciblée finale : `No issues found! (ran in 1.6s)`

Git status final :

```bash
git status --short --untracked-files=all
```

Résultat exact :

```text
?? packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart
?? reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md
```

## 12. Diff pertinent

Fichier créé : `packages/map_editor/test/environment_studio/tile_layer_environment_golden_slice_save_reload_test.dart`

Contenu complet :

```dart
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/tile_layer_environment_attachment_read_model_builder.dart';
import 'package:map_editor/src/application/use_cases/tile_layer_environment_clear_use_cases.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/environment_generated_placement_add_element_provider.dart';
import 'package:map_editor/src/features/editor/state/environment_mask_brush_size_provider.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';
import 'package:map_editor/src/infrastructure/repositories/file_repositories.dart';
import 'package:map_editor/src/ui/panels/layers_panel_presentation.dart';
import 'package:path/path.dart' as p;

void main() {
  group('Environment-48 Golden Slice save/reload', () {
    test(
        'préserve environnement, placements, grouping et reste clearable après reload',
        () async {
      final tempDir =
          await Directory.systemTemp.createTemp('env48_save_reload_');
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final manifest = _manifest();
      final initialMap = _map();
      final manifestPath = p.join(tempDir.path, 'project.json');
      final mapPath = p.join(tempDir.path, 'maps', 'golden.json');
      await FileProjectRepository().saveProject(manifest, manifestPath);
      await FileMapRepository().saveMap(
        initialMap,
        mapPath,
        projectDialogueContext: manifest,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      await notifier.loadProject(manifestPath, rememberAsRecent: false);
      await notifier.loadMap('maps/golden.json');
      notifier.state = notifier.state.copyWith(
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
      );

      notifier.startDeletingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedDelete);
      expect(
        notifier.deleteGeneratedEnvironmentPlacementAtForActiveTileLayer(
          const GridPos(x: 3, y: 2),
        ),
        isTrue,
      );

      notifier.selectEnvironmentGeneratedPlacementElementForActiveTileLayer(
        'bush',
      );
      notifier.startAddingGeneratedEnvironmentPlacementForActiveTileLayer();
      expect(notifier.state.environmentMaskEditMode,
          EnvironmentMaskEditMode.generatedAdd);
      expect(
        notifier.addGeneratedEnvironmentPlacementAtForActiveTileLayer(
          const GridPos(x: 4, y: 0),
        ),
        isTrue,
      );
      container.read(environmentMaskBrushSizeProvider.notifier).state = 7;
      notifier.state = notifier.state.copyWith(
        hoveredTile: const GridPos(x: 1, y: 1),
      );

      await notifier.saveActiveMap();
      expect(notifier.state.errorMessage, isNull);
      expect(notifier.state.isDirty, isFalse);

      final savedMapJson = await File(mapPath).readAsString();
      expect(savedMapJson, isNot(contains('generatedAdd')));
      expect(savedMapJson, isNot(contains('hoveredTile')));
      expect(savedMapJson, isNot(contains('environmentMaskEditMode')));

      final reloadedContainer = ProviderContainer();
      addTearDown(reloadedContainer.dispose);
      final reloadedNotifier =
          reloadedContainer.read(editorNotifierProvider.notifier);
      await reloadedNotifier.loadProject(
        manifestPath,
        rememberAsRecent: false,
      );
      await reloadedNotifier.loadMap('maps/golden.json');

      final reloadedState = reloadedNotifier.state;
      final reloadedMap = reloadedState.activeMap!;
      final reloadedArea = _areaById(reloadedMap, 'area');
      final placedIds =
          reloadedMap.placedElements.map((placed) => placed.id).toSet();

      expect(reloadedState.activeLayerId, 'tiles');
      expect(reloadedState.selectedEnvironmentAreaId, isNull);
      expect(reloadedState.environmentMaskEditMode, isNull);
      expect(reloadedState.hoveredTile, isNull);
      expect(
        reloadedContainer.read(environmentGeneratedPlacementAddElementProvider),
        isNull,
      );
      expect(
        reloadedContainer.read(environmentMaskBrushSizeProvider),
        kDefaultEnvironmentMaskBrushSize,
      );

      expect(_tileLayer(reloadedMap).tiles, _tileLayer(initialMap).tiles);
      expect(_environmentLayer(reloadedMap).content.targetTileLayerId, 'tiles');
      expect(reloadedArea.mask, _areaById(initialMap, 'area').mask);
      expect(reloadedArea.seed, 17);
      expect(reloadedArea.paramsOverride, _params);
      expect(reloadedArea.presetId, 'forest');
      expect(reloadedArea.generatedPlacementIds, const [
        'generated_keep',
        'env_gen_area_4_0_bush',
      ]);
      expect(reloadedArea.generatedPlacementIds.toSet().length,
          reloadedArea.generatedPlacementIds.length);
      for (final id in reloadedArea.generatedPlacementIds) {
        expect(placedIds, contains(id));
      }

      expect(placedIds, contains('manual_tree'));
      expect(placedIds, contains('generated_keep'));
      expect(placedIds, contains('env_gen_area_4_0_bush'));
      expect(placedIds, contains('other_generated'));
      expect(placedIds, isNot(contains('generated_delete')));
      expect(
          reloadedArea.generatedPlacementIds, isNot(contains('manual_tree')));
      final added = reloadedMap.placedElements.singleWhere(
        (placed) => placed.id == 'env_gen_area_4_0_bush',
      );
      expect(added.layerId, 'tiles');
      expect(added.elementId, 'bush');
      expect(added.pos, const GridPos(x: 4, y: 0));
      final manual = reloadedMap.placedElements.singleWhere(
        (placed) => placed.id == 'manual_tree',
      );
      expect(manual.layerId, 'tiles');
      expect(manual.elementId, 'tree');
      expect(manual.pos, const GridPos(x: 0, y: 0));
      expect(_areaById(reloadedMap, 'other').generatedPlacementIds,
          const ['other_generated']);

      final model = buildTileLayerEnvironmentAttachmentReadModel(
        manifest: reloadedState.project,
        map: reloadedMap,
        selectedLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area',
        selectedGeneratedPlacementElementId: 'bush',
      );
      expect(model.hasAttachment, isTrue);
      expect(model.activeTileLayerId, 'tiles');
      expect(model.attachedEnvironmentLayerId, 'env');
      expect(model.hasMask, isTrue);
      expect(model.maskActiveCellCount, greaterThan(0));
      expect(model.generatedPlacementCount, 2);
      expect(model.existingGeneratedPlacementCount, 2);
      expect(model.missingGeneratedPlacementCount, 0);
      expect(model.selectedAreaHasParamsOverride, isTrue);
      expect(model.selectedAreaSeed, 17);
      expect(model.canClearGeneratedPlacements, isTrue);
      expect(model.canRegenerate, isTrue);
      expect(model.canShuffle, isTrue);
      expect(model.canAddGeneratedPlacement, isTrue);

      final rows = buildLayerPanelPresentationRows(
        reloadedMap,
        activeLayerId: 'env',
      );
      expect(rows.map((row) => row.layer.id), const ['tiles', 'objects']);
      final tileRow = rows.singleWhere((row) => row.layer.id == 'tiles');
      expect(tileRow.environmentAttachmentLabel, 'Environnement actif');
      expect(tileRow.attachedEnvironmentLayerIds, const ['env']);
      expect(tileRow.isActive, isTrue);
      expect(tileRow.isTechnicalEnvironmentSelection, isTrue);

      final clear =
          ClearTileLayerEnvironmentAreaGeneratedPlacementsUseCase().execute(
        reloadedMap,
        tileLayerId: 'tiles',
        areaId: 'area',
      );
      expect(clear.removedPlacementIds,
          unorderedEquals(['generated_keep', 'env_gen_area_4_0_bush']));
      expect(_areaById(clear.map, 'area').generatedPlacementIds, isEmpty);
      expect(clear.map.placedElements.map((placed) => placed.id),
          contains('manual_tree'));
      expect(clear.map.placedElements.map((placed) => placed.id),
          contains('other_generated'));
    });
  });
}

final _params = EnvironmentGenerationParams(
  density: 0.62,
  variation: 0.18,
  edgeDensity: 0.74,
  minSpacingCells: 1,
);

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Environment 48',
    maps: const [
      ProjectMapEntry(
        id: 'golden',
        name: 'Golden',
        relativePath: 'maps/golden.json',
      ),
    ],
    tilesets: const [
      ProjectTilesetEntry(
        id: 'nature',
        name: 'Nature',
        relativePath: 'tilesets/nature.png',
      ),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'nature', name: 'Nature'),
    ],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
      ProjectElementEntry(
        id: 'bush',
        name: 'Bush',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
        ],
      ),
      ProjectElementEntry(
        id: 'big_tree',
        name: 'Big Tree',
        tilesetId: 'nature',
        categoryId: 'nature',
        frames: [
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 1, width: 2, height: 2),
          ),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forest',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          EnvironmentPaletteItem(elementId: 'bush', weight: 1),
          EnvironmentPaletteItem(elementId: 'big_tree', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams(
          density: 1,
          variation: 0,
          edgeDensity: 1,
          minSpacingCells: 0,
        ),
        sortOrder: 0,
      ),
    ],
  );
}

MapData _map() {
  return MapData(
    id: 'golden',
    name: 'Golden',
    size: const GridSize(width: 5, height: 5),
    tilesetId: 'nature',
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Décor',
        tilesetId: 'nature',
        tiles: [
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment — Décor',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            EnvironmentArea(
              id: 'area',
              name: 'Forêt',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 5,
                height: 5,
                cells: [
                  true,
                  true,
                  false,
                  false,
                  false,
                  true,
                  true,
                  true,
                  false,
                  false,
                  false,
                  true,
                  true,
                  true,
                  false,
                  false,
                  false,
                  true,
                  true,
                  false,
                  false,
                  false,
                  false,
                  false,
                  false,
                ],
              ),
              seed: 17,
              paramsOverride: _params,
              generatedPlacementIds: const [
                'generated_keep',
                'generated_delete',
              ],
            ),
            EnvironmentArea(
              id: 'other',
              name: 'Bosquet',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 5,
                height: 5,
                cells: List<bool>.filled(25, true),
              ),
              seed: 9,
              generatedPlacementIds: const ['other_generated'],
            ),
          ],
        ),
      ),
      const ObjectLayer(id: 'objects', name: 'Objects'),
    ],
    placedElements: const [
      MapPlacedElement(
        id: 'manual_tree',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 0),
      ),
      MapPlacedElement(
        id: 'generated_keep',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 0, y: 3),
      ),
      MapPlacedElement(
        id: 'generated_delete',
        layerId: 'tiles',
        elementId: 'big_tree',
        pos: GridPos(x: 2, y: 1),
      ),
      MapPlacedElement(
        id: 'other_generated',
        layerId: 'tiles',
        elementId: 'tree',
        pos: GridPos(x: 4, y: 4),
      ),
    ],
  );
}

TileLayer _tileLayer(MapData map) {
  return map.layers.whereType<TileLayer>().single;
}

EnvironmentLayer _environmentLayer(MapData map) {
  return map.layers.whereType<EnvironmentLayer>().single;
}

EnvironmentArea _areaById(MapData map, String areaId) {
  return _environmentLayer(map)
      .content
      .areas
      .singleWhere((area) => area.id == areaId);
}
```

Fichier créé : `reports/environment_studio/environment_48_tile_layer_centric_golden_slice_save_reload.md`

Ce document est le rapport Environment-48.

## 13. Auto-review

- Le round-trip utilise-t-il le vrai save/reload ou un fallback clairement justifié ? Oui, vrai disque via `FileProjectRepository`, `FileMapRepository`, `EditorNotifier.loadProject/loadMap/saveActiveMap`.
- `EnvironmentLayer.targetTileLayerId` est-il conservé ? Oui, `targetTileLayerId == 'tiles'`.
- Mask est-il conservé ? Oui, comparaison directe avec le masque initial.
- `paramsOverride` est-il conservé ? Oui, comparaison directe avec `_params`.
- Seed est-il conservé ? Oui, `seed == 17`.
- `generatedPlacementIds` sont-ils cohérents ? Oui, ids exacts, existants dans `placedElements`, sans doublon.
- Ajout individuel est-il persisté ? Oui, `env_gen_area_4_0_bush` existe après reload.
- Suppression individuelle est-elle persistée ? Oui, `generated_delete` ne revient pas.
- Placement manuel est-il préservé ? Oui, `manual_tree` existe après reload et n’est pas dans `generatedPlacementIds`.
- Read model est-il correct après reload ? Oui, flags et compteurs vérifiés.
- `LayersPanel` grouping est-il correct après reload ? Oui, projection `['tiles', 'objects']` et `Environnement actif`.
- États UI transients ne sont-ils pas persistés ? Oui, state/provider defaults vérifiés et absence de clés transientes dans le JSON map.
- Le modèle rechargé reste-t-il opérable ? Oui, clear TileLayer-centric fonctionne après reload.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Ce qui était clair :

- Le lot est bien un lot de validation, pas une feature.
- Les invariants attendus après reload étaient explicites.
- Le prochain lot recommandé était cadré.
- La nécessité de distinguer persistence réelle, serialization fallback et états transients était utile.

Ce qui était ambigu :

- `selectedEnvironmentAreaId` est un état UI transitoire dans `EditorState`, pas une donnée persistée. Le test vérifie donc que l’area existe et peut être reconstruite via read model quand on fournit l’id, mais ne force pas sa persistence dans la session.
- Le prompt liste generate/clear/regenerate/shuffle dans le workflow complet. Le test Environment-48 vérifie l’opérabilité post-reload via clear et relance les non-régressions generate/clear/regenerate/shuffle existantes.

À trancher avant Environment-49 :

- Décider si la sélection d’area doit rester strictement volatile ou si une future UX doit mémoriser une sélection par map/layer hors modèle projet.
- Déterminer si l’inspector doit afficher un résumé plus compact quand l’EnvironmentLayer est groupé et que l’area doit être resélectionnée après reload.

## 15. Verdict

```text
Environment-48 livré
Code produit modifié : non
Tests créés : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-49 — TileLayer Environment Inspector UX Cleanup V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai validé le round-trip save/reload ou documenté précisément le fallback.
- [x] J’ai validé mask / params / seed.
- [x] J’ai validé generatedPlacementIds / placedElements.
- [x] J’ai validé add/delete individuel.
- [x] J’ai validé read model après reload.
- [x] J’ai validé LayersPanel grouping après reload.
- [x] J’ai vérifié les états transients.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
