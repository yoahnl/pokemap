# Environment-30 — TileLayer Environment Attachment Read Model V0

## 1. Résumé

Environment-30 ajoute une brique de lecture pure côté `map_editor` pour répondre à la question : depuis le layer sélectionné, quel est l’état environnement associé ?

Le lot ajoute :

- `TileLayerEnvironmentAttachmentReadModel`, un value object orienté UI.
- `buildTileLayerEnvironmentAttachmentReadModel`, un builder pur sans mutation.
- un test ciblé couvrant les états principaux demandés.

Le modèle existant est conservé : `EnvironmentLayerContent`, `targetTileLayerId`, `EnvironmentArea`, `EnvironmentAreaMask`, `generatedPlacementIds` et `MapPlacedElement`.

## 2. Décision UX retenue

- Environment Studio reste l’atelier de presets et recettes d’environnement.
- Map Editor / TileLayer inspector deviendra le lieu naturel pour peindre, configurer localement, prévisualiser et générer.
- Ce lot prépare cette bascule sans migrer les données et sans cacher les `EnvironmentLayer`.
- L’utilisateur futur devra penser “je sélectionne un TileLayer et j’active l’environnement dessus”, pas “je gère un EnvironmentLayer technique qui cible un TileLayer”.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_core/lib/src/models/environment.dart` : contient `EnvironmentPreset`, `EnvironmentArea`, `EnvironmentAreaMask`, `EnvironmentLayerContent`, `targetTileLayerId` et `generatedPlacementIds`.
- `packages/map_core/lib/src/models/map_layer.dart` : contient l’union `MapLayer`, dont `TileLayer` et `EnvironmentLayer`.
- `packages/map_core/lib/src/models/map_data.dart` : contient `MapData.layers` et `MapData.placedElements`.
- `packages/map_core/lib/src/models/project_manifest.dart` : contient `ProjectManifest.environmentPresets`.
- `packages/map_core/lib/src/validation/validators.dart` : valide déjà les cibles d’`EnvironmentLayer`, notamment target manquant, target introuvable et target non TileLayer.
- `packages/map_core/lib/src/operations/environment_layer_usage_diagnostics.dart` : expose déjà des diagnostics d’usage des layers environnement.
- `packages/map_core/lib/src/operations/environment_authoring_diagnostics.dart` : expose des diagnostics d’auteur pour presets/zones/masques.
- `packages/map_editor/lib/src/application/models/environment_area_generation_readiness.dart` : modèle de readiness existant mais centré génération d’area, pas attachement depuis TileLayer actif.
- `packages/map_editor/lib/src/application/use_cases/environment_generator_use_cases.dart` : génération déterministe depuis area/preset/target.
- `packages/map_editor/lib/src/application/use_cases/environment_generator_apply_use_cases.dart` : application de candidats en `MapPlacedElement` et mise à jour de `generatedPlacementIds`.
- `packages/map_editor/lib/src/application/use_cases/environment_generator_clear_use_cases.dart` : suppression des placements générés référencés.
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart` : opérations pures de peinture/effacement de masque.
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart` : expose la sélection de layer et `selectedEnvironmentAreaId`.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart` : orchestre l’ancien flow et les use cases.
- `packages/map_editor/lib/src/ui/panels/environment_layer_inspector_panel.dart` : UI actuelle encore EnvironmentLayer-centric.
- `packages/map_editor/lib/src/ui/panels/layers_panel.dart` : liste encore explicitement les layers.
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart` et `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart` : canvas déjà capable de dessiner map/overlays, mais hors scope de ce lot.

Conclusions utiles :

- Le contrat persistant nécessaire existe déjà.
- Le manque principal pour la future UX TileLayer-centric était un read model qui part du layer actif.
- Il faut conserver la compatibilité legacy quand l’utilisateur sélectionne encore directement un `EnvironmentLayer`.

## 4. Modèle ajouté

Nom :

- `TileLayerEnvironmentAttachmentReadModel`

Rôle :

- offrir une vue lisible par la future UI du TileLayer inspector ;
- masquer le détail technique `EnvironmentLayer -> targetTileLayerId` dans les messages principaux ;
- exposer quand même les IDs utiles pour câblage ultérieur.

Inputs du builder :

- `ProjectManifest? manifest`
- `MapData? map`
- `String? selectedLayerId`
- `String? selectedEnvironmentAreaId`

Outputs principaux :

- layer sélectionné et type de sélection ;
- TileLayer actif résolu ;
- EnvironmentLayer attaché résolu ;
- zone active ;
- preset actif ;
- compte de cellules actives du masque ;
- compte de placements générés ;
- compte de placements référencés manquants ;
- capacités UI : activer, peindre, générer, effacer, régénérer, mélanger ;
- titres, messages et action primaire en français ;
- warnings/errors.

États couverts :

- projet absent ;
- map absente ;
- aucun layer sélectionné ;
- layer sélectionné introuvable ;
- layer non compatible ;
- TileLayer sans environnement ;
- TileLayer avec environnement ;
- sélection legacy d’un EnvironmentLayer ;
- cible absente, introuvable ou non TileLayer ;
- aucune zone ;
- zone sélectionnée absente ;
- sélection de zone requise ;
- preset manquant ;
- masque vide ;
- prêt à générer ;
- placements déjà générés.

## 5. Règles de résolution

Selected TileLayer :

- le TileLayer sélectionné devient l’objet principal ;
- le builder cherche les `EnvironmentLayer` dont `content.targetTileLayerId == selectedTileLayer.id` ;
- s’il n’en trouve aucun, il retourne “Aucun environnement sur ce layer” avec `canEnableEnvironment = true` ;
- s’il en trouve plusieurs, il choisit le premier selon l’ordre des layers de la map et ajoute un warning.

Selected EnvironmentLayer legacy :

- `isLegacyEnvironmentLayerSelection = true` ;
- le builder résout son `targetTileLayerId` ;
- si la cible est valide, le read model reste utilisable ;
- un warning indique que la prochaine UX pilotera ce comportement depuis le TileLayer cible.

Area active :

- si `selectedEnvironmentAreaId` existe dans l’EnvironmentLayer, elle est utilisée ;
- si aucune sélection n’est fournie et qu’une seule area existe, cette area est utilisée automatiquement ;
- si plusieurs areas existent sans sélection valide, l’état demande une sélection explicite ;
- si l’area sélectionnée est absente, un error bloque génération/peinture.

Preset :

- le preset est résolu via `manifest.environmentPresets` ;
- si le preset manque, `canPaintMask` reste vrai mais `canGenerate` est faux.

Mask :

- `maskActiveCellCount` vient de `EnvironmentAreaMask.activeCellCount` ;
- `hasMask = maskActiveCellCount > 0` ;
- un masque vide bloque la génération.

Generated placements :

- `generatedPlacementCount = generatedPlacementIds.length` ;
- `existingGeneratedPlacementCount` compte les IDs présents dans `map.placedElements` ;
- `missingGeneratedPlacementCount` expose les références orphelines ;
- un warning indique combien de placements générés référencés sont introuvables.

## 6. Tests

Commande lancée :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
00:00 +21: All tests passed!
```

Cas couverts :

- projet null ;
- map null ;
- aucun layer sélectionné ;
- TileLayer sans environnement ;
- TileLayer avec environnement attaché ;
- plusieurs EnvironmentLayers attachés au même TileLayer ;
- EnvironmentLayer sélectionné directement en legacy ;
- `targetTileLayerId` manquant ;
- target layer inexistant ;
- target layer non TileLayer ;
- absence d’area ;
- area sélectionnée valide ;
- area sélectionnée absente ;
- auto-sélection quand une seule area existe ;
- plusieurs areas sans sélection ;
- preset valide ;
- preset manquant ;
- masque vide ;
- masque non vide ;
- compte des generatedPlacementIds ;
- compte des placements générés manquants ;
- layer non TileLayer.

## 7. Analyse ciblée

Commande demandée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models lib/src/application/services
```

Résultat :

```text
51 issues found. (ran in 1.4s)
```

L’échec vient d’une dette préexistante hors lot dans :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
```

Exemples d’erreurs :

- paramètres nommés absents : `dbSymbol`, `battleEngineAimedTarget`, `battleEngineMethod`, `effectChance` ;
- classes absentes : `PokemonMoveAimedTarget`, `PokemonMoveFlags`, `PokemonMoveBattleStageMod`, `PokemonMoveStatus`.

Analyse strictement limitée aux fichiers Environment-30 :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

```text
No issues found! (ran in 1.5s)
```

## 8. Fichiers modifiés

Fichiers créés :

- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `reports/environment_studio/environment_30_tile_layer_environment_attachment_read_model.md`

Fichiers modifiés hors création :

- aucun fichier de production existant ;
- aucun fichier UI ;
- aucun fichier `map_core`.

## 9. Non-objectifs respectés

- Pas de migration modèle.
- Pas de build_runner.
- Pas de generated files modifiés.
- Pas de runtime modifié.
- Pas de gameplay modifié.
- Pas de refonte UI.
- Pas de brush avancée.
- Pas d’auto-création d’EnvironmentLayer.
- Pas de masquage des EnvironmentLayers dans la liste des layers.
- Pas de commit.

## 10. Prochain lot recommandé

Prochain lot recommandé :

```text
Environment-31 — TileLayer Environment Inspector Section Shell V0
```

Objectif :

- afficher une section TileLayer-centric dans l’inspector, alimentée par ce read model ;
- ne pas encore auto-créer l’EnvironmentLayer ;
- ne pas encore déplacer toute l’UI ;
- montrer uniquement l’état, les warnings/errors et les actions désactivées ou routées vers l’ancien flow.

Alternative si l’on veut d’abord une mutation minimale :

```text
Environment-31 — TileLayer Environment Attachment Enable Action V0
```

Mais je recommande d’abord le shell inspector pour valider le vocabulaire UX avant de créer une action de mutation.

## 11. Evidence pack

Git status initial observé pendant le lot :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

Commandes principales :

```bash
git status --short --untracked-files=all
rg -n "EnvironmentLayer|EnvironmentArea|EnvironmentAreaMask|EnvironmentPreset|targetTileLayerId|generatedPlacementIds|selectedEnvironmentAreaId|environmentMaskEditMode|generateEnvironmentAreaPlacements|clearEnvironmentGeneratedPlacements|regenerateEnvironmentAreaPlacements|shuffleEnvironmentAreaPlacements" packages/map_core/lib packages/map_editor/lib packages/map_editor/test
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
dart format lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
flutter analyze lib/src/application/models lib/src/application/services
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Git status final réel après création de ce rapport :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/lib/src/ui/canvas/tileset_editor_canvas.dart
?? packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
?? packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
?? packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
?? packages/map_editor/lib/src/ui/canvas/tileset_grid_metrics.dart
?? packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
?? packages/map_editor/test/tileset_grid_metrics_test.dart
?? reports/environment_studio/environment_30_tile_layer_environment_attachment_read_model.md
?? reports/environment_studio/environment_studio_map_centric_workflow_review.md
```

## 12. Auto-review

- Le read model est-il pur ? Oui. Il ne dépend que des modèles existants et ne fait aucune mutation.
- Le lot modifie-t-il du code UI ? Non.
- Le lot modifie-t-il `map_core` ? Non.
- Le lot modifie-t-il le modèle persistant ? Non.
- Le lot lance-t-il build_runner ? Non.
- Le lot garde-t-il l’ancien flow compatible ? Oui. La sélection directe d’un `EnvironmentLayer` reste supportée avec `isLegacyEnvironmentLayerSelection = true`.
- Le lot prépare-t-il la future UX TileLayer-centric ? Oui. La résolution part d’un TileLayer sélectionné et expose un état consommable par un inspector futur.

## 13. Verdict

```text
Environment-30 livré
Code produit modifié : oui, uniquement map_editor application models/services
Tests ciblés : pass
Analyze ciblé demandé : fail sur dette hors lot
Analyze fichiers du lot : pass
Prochain lot recommandé : Environment-31 — TileLayer Environment Inspector Section Shell V0
```
