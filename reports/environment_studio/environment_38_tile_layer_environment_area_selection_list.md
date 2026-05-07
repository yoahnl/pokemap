# Environment-38 — TileLayer Environment Area Selection List V0

## 1. Résumé

Ajout de la visualisation et de la sélection des `EnvironmentArea` depuis la section TileLayer-centric `Environnement du layer`.

Le lot ajoute :
- un modèle `TileLayerEnvironmentAreaSummary` ;
- `areaSummaries` dans `TileLayerEnvironmentAttachmentReadModel` ;
- le remplissage des summaries par le builder read model ;
- une méthode notifier `selectEnvironmentAreaForActiveTileLayer` ;
- une liste compacte `Zones d’environnement` dans `TileLayerEnvironmentInspectorSection` ;
- le wiring depuis `MapInspectorPanel` ;
- un test notifier dédié `tile_layer_environment_area_selection_test.dart` ;
- des tests read model et widget couvrant la liste, les compteurs, les presets manquants et la sélection.

La sélection ne mute pas `MapData`, garde le `TileLayer` actif, met à jour `selectedEnvironmentAreaId`, et remet `environmentMaskEditMode` à `null`.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot ajoute seulement la liste et la sélection des zones.
- Pas de suppression, renommage, duplication, réordonnancement ou génération dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_brush_footprint_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_attachment_use_cases.dart`
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`

Comportement actuel avec une seule area :
- si `selectedEnvironmentAreaId` est absent et qu’une seule area existe, le builder l’utilise comme area effective ;
- l’état peut passer à `emptyMask`, `ready`, `generated` ou `missingPreset` selon son contenu.

Comportement actuel avec plusieurs areas :
- si `selectedEnvironmentAreaId` est absent, le builder retourne `areaSelectionRequired` ;
- si `selectedEnvironmentAreaId` existe, le builder utilise cette area ;
- si `selectedEnvironmentAreaId` pointe vers une area absente, le builder retourne `selectedAreaMissing`.

Décision retenue :
- le widget ne résout pas les zones lui-même ;
- le builder expose une liste de summaries dans l’ordre de `EnvironmentLayerContent.areas` ;
- le notifier sélectionne une area via le même resolver de cible que paint/erase ;
- changer de zone remet le mode masque à `null` pour éviter de peindre immédiatement la mauvaise zone.

## 4. Read model / area summaries

Modèle ajouté :
- `TileLayerEnvironmentAreaSummary`

Champs :
- `id`
- `name`
- `presetId`
- `presetName`
- `isSelected`
- `maskActiveCellCount`
- `generatedPlacementCount`
- `missingGeneratedPlacementCount`
- `hasMissingPreset`

Ordre :
- identique à `EnvironmentLayerContent.areas`.

État sélectionné :
- une seule area sans sélection explicite est marquée active si elle devient l’area effective ;
- plusieurs areas sans sélection : aucune summary sélectionnée ;
- sélection valide : la bonne summary est sélectionnée ;
- sélection absente : aucune summary sélectionnée, mais la liste reste disponible.

Preset resolution :
- `presetName` est renseigné depuis `ProjectManifest.environmentPresets` ;
- `hasMissingPreset` vaut `true` si aucun preset du manifest ne correspond au `presetId`.

Compteurs :
- `maskActiveCellCount` vient de `EnvironmentAreaMask.activeCellCount` ;
- `generatedPlacementCount` est la longueur de `generatedPlacementIds` ;
- `missingGeneratedPlacementCount` compare `generatedPlacementIds` aux `MapData.placedElements`.

## 5. Notifier / sélection

Méthode ajoutée :
- `EditorNotifier.selectEnvironmentAreaForActiveTileLayer(String areaId)`

Conditions :
- une map active doit exister ;
- `activeLayerId` doit désigner un `TileLayer` ;
- `areaId` doit être non vide ;
- un `EnvironmentLayer` attaché au TileLayer doit exister ;
- l’area doit exister dans l’EnvironmentLayer attaché.

Impact état :
- `selectedEnvironmentAreaId` devient l’area choisie ;
- `activeLayerId` reste le TileLayer ;
- `environmentMaskEditMode` devient `null` ;
- `MapData` reste la même référence ;
- aucun `MapPlacedElement` n’est créé.

## 6. Intégration UI

Liste affichée :
- nouvelle section compacte `Zones d’environnement` si `areaSummaries` n’est pas vide ;
- une row par zone.

Zone active :
- badge `Zone active`.

Zone non active :
- bouton `Sélectionner`, actif seulement si `onSelectEnvironmentArea` est fourni.

État sans area :
- reste l’état existant `Aucune zone d’environnement` avec `Ajouter une zone`.

État area sélectionnée absente :
- l’erreur existante reste visible ;
- la liste des zones disponibles reste visible ;
- l’utilisateur peut sélectionner une zone valide si le callback est fourni.

Actions désactivées :
- génération inchangée ;
- suppression des placements générés inchangée ;
- aucune suppression/renommage/duplication de zone ajoutée.

## 7. Tests

Tests RED avant implémentation :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat RED observé :

```text
Error: The getter 'areaSummaries' isn't defined for the type 'TileLayerEnvironmentAttachmentReadModel'.
00:00 +0 -1: Some tests failed.
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart
```

Résultat RED observé :

```text
Error: The method 'selectEnvironmentAreaForActiveTileLayer' isn't defined for the type 'EditorNotifier'.
00:00 +0 -1: Some tests failed.
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat RED observé :

```text
Error: Method not found: 'TileLayerEnvironmentAreaSummary'.
Error: No named parameter with the name 'areaSummaries'.
Error: No named parameter with the name 'onSelectEnvironmentArea'.
00:00 +0 -1: Some tests failed.
```

Échecs intermédiaires de fixture pendant GREEN :

```text
Invalid argument (palette): EnvironmentPreset palette must not be empty.
```

Cause :
- le nouveau test notifier construisait un `EnvironmentPreset` invalide avec une palette vide.

Correction :
- ajout du `ProjectElementEntry tree` et de `EnvironmentPaletteItem(elementId: 'tree', weight: 1)` dans le fixture de test.

Deuxième échec de fixture :

```text
Error: Cannot invoke a non-'const' factory where a const expression is expected.
EnvironmentPaletteItem(elementId: 'tree', weight: 1)
```

Cause :
- `EnvironmentPaletteItem` n’est pas const.

Correction :
- retrait du `const` sur la liste `palette` du fixture.

Commandes GREEN et non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

Résultat :

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
00:00 +18: TileLayerEnvironmentAttachmentReadModel détecte preset manquant
00:00 +19: TileLayerEnvironmentAttachmentReadModel détecte masque vide
00:00 +20: TileLayerEnvironmentAttachmentReadModel détecte masque non vide
00:00 +21: TileLayerEnvironmentAttachmentReadModel compte generatedPlacementIds et placements manquants
00:00 +22: TileLayerEnvironmentAttachmentReadModel retourne un état neutre pour un layer non TileLayer
00:00 +23: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart
00:00 +0: EditorNotifier.selectEnvironmentAreaForActiveTileLayer sélectionne une area et garde le TileLayer actif sans muter MapData
00:00 +1: EditorNotifier.selectEnvironmentAreaForActiveTileLayer refuse si aucun TileLayer actif
00:00 +2: EditorNotifier.selectEnvironmentAreaForActiveTileLayer refuse si aucun EnvironmentLayer attaché
00:00 +3: EditorNotifier.selectEnvironmentAreaForActiveTileLayer refuse areaId vide
00:00 +4: EditorNotifier.selectEnvironmentAreaForActiveTileLayer refuse area introuvable
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

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
00:00 +8: TileLayerEnvironmentInspectorSection affiche le nombre de placements générés
00:00 +9: TileLayerEnvironmentInspectorSection affiche la liste des zones d’environnement
00:00 +10: TileLayerEnvironmentInspectorSection cliquer sur Sélectionner déclenche le callback area
00:00 +11: TileLayerEnvironmentInspectorSection affiche preset et placements manquants dans une summary
00:00 +12: TileLayerEnvironmentInspectorSection affiche un warning si des placements sont manquants
00:00 +13: TileLayerEnvironmentInspectorSection affiche une erreur si le preset est manquant
00:00 +14: TileLayerEnvironmentInspectorSection affiche un message legacy
00:00 +15: TileLayerEnvironmentInspectorSection n’affiche pas d’action active de génération dans ce lot
00:01 +16: TileLayerEnvironmentInspectorSection active Peindre le masque avec callback
00:01 +17: TileLayerEnvironmentInspectorSection affiche Effacer du masque quand le masque est éditable
00:01 +18: TileLayerEnvironmentInspectorSection active Effacer du masque avec callback
00:01 +19: TileLayerEnvironmentInspectorSection affiche Taille du pinceau et les choix 1 3 5 7
00:01 +20: TileLayerEnvironmentInspectorSection cliquer sur 3 change la taille du pinceau
00:01 +21: TileLayerEnvironmentInspectorSection sans callback les tailles de pinceau sont désactivées
00:01 +22: TileLayerEnvironmentInspectorSection affiche Peinture active et stop quand le mode est actif
00:01 +23: TileLayerEnvironmentInspectorSection affiche Effacement actif et garde la taille visible
00:01 +24: TileLayerEnvironmentInspectorSection après création avec masque vide la brush reste désactivée
00:01 +25: TileLayerEnvironmentInspectorSection la suppression des placements générés reste désactivée
00:01 +26: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
00:00 +0: CreateTileLayerEnvironmentAreaUseCase crée une EnvironmentArea dans l’EnvironmentLayer attaché
00:00 +1: CreateTileLayerEnvironmentAreaUseCase génère un id unique et garde un nom lisible
00:00 +2: CreateTileLayerEnvironmentAreaUseCase refuse tileLayerId vide
00:00 +3: CreateTileLayerEnvironmentAreaUseCase refuse TileLayer introuvable
00:00 +4: CreateTileLayerEnvironmentAreaUseCase refuse layer non TileLayer
00:00 +5: CreateTileLayerEnvironmentAreaUseCase refuse absence d’EnvironmentLayer attaché
00:00 +6: CreateTileLayerEnvironmentAreaUseCase refuse presetId vide ou absent du manifest
00:00 +7: CreateTileLayerEnvironmentAreaUseCase préserve les autres layers et les placedElements
00:00 +8: CreateTileLayerEnvironmentAreaUseCase ajoute dans le premier EnvironmentLayer attaché selon l’ordre
00:00 +9: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_area_notifier_test.dart
00:00 +0: EditorNotifier.createEnvironmentAreaForActiveTileLayer crée une area et garde le TileLayer sélectionné
00:00 +1: EditorNotifier.createEnvironmentAreaForActiveTileLayer refuse un preset absent sans créer de zone
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
00:00 +0: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer active le mode paint sans changer le TileLayer sélectionné
00:00 +1: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer stop remet le mode à null et garde la zone active
00:00 +2: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer refuse si aucun TileLayer actif
00:00 +3: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer refuse si aucun EnvironmentLayer attaché
00:00 +4: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer refuse si aucune area est sélectionnée
00:00 +5: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer refuse si area sélectionnée introuvable
00:00 +6: EditorNotifier.startEnvironmentMaskPaintingForActiveTileLayer peint le masque attaché en gardant le TileLayer actif
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart
00:00 +0: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer active le mode erase sans changer le TileLayer sélectionné
00:00 +1: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer stop remet le mode à null et garde la zone active
00:00 +2: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucun TileLayer actif
00:00 +3: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucun EnvironmentLayer attaché
00:00 +4: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si aucune area est sélectionnée
00:00 +5: EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer refuse si area sélectionnée introuvable
00:00 +6: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/environment_mask_brush_size_use_case_test.dart
00:00 +0: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 1 peint exactement la cellule centrale
00:00 +1: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 3 peint un carré 3x3
00:00 +2: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 5 peint un carré 5x5
00:00 +3: PaintEnvironmentAreaMaskBrushStrokeUseCase brush size 7 peint un carré 7x7
00:00 +4: PaintEnvironmentAreaMaskBrushStrokeUseCase brush en bord de map clippe correctement
00:00 +5: PaintEnvironmentAreaMaskBrushStrokeUseCase brush hors map ne crash pas et ne peint rien
00:00 +6: PaintEnvironmentAreaMaskBrushStrokeUseCase erase avec size 3 remet les cellules à false
00:00 +7: PaintEnvironmentAreaMaskBrushStrokeUseCase refuse brush size invalide
00:00 +8: PaintEnvironmentAreaMaskBrushStrokeUseCase préserve les autres areas layers et placedElements
00:00 +9: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
00:00 +0: tap canvas peint le masque attaché quand le TileLayer est actif
00:00 +1: tap canvas peint un carré 3x3 avec brush size 3
00:00 +2: tap canvas efface un carré 3x3 avec brush size 3
00:00 +3: tap canvas erase taille 1 efface exactement la cellule centrale
00:00 +4: All tests passed!
```

Cas couverts :
- summaries vides sans area ;
- summary unique sélectionnée par area effective ;
- plusieurs summaries dans l’ordre ;
- plusieurs areas sans sélection : aucune summary active ;
- sélection valide : summary active correcte ;
- sélection absente : liste visible sans summary active ;
- presetName disponible ;
- preset manquant ;
- compteurs mask / placements / placements manquants ;
- notifier sélectionne une area sans muter `MapData` ;
- notifier refuse les états invalides ;
- widget affiche la liste, la zone active, les boutons sélectionner et les compteurs ;
- actions générer / effacer placements restent désactivées.

## 8. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor
flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_area_selection_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat :

```text
Analyzing 8 items...                                            
No issues found! (ran in 2.1s)
```

Dette préexistante hors lot :
- aucune dette préexistante n’est remontée par l’analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant Environment-38 :
- aucun ; le `git status --short --untracked-files=all` initial était vide.

Fichiers créés par Environment-38 :
- `packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart`
- `reports/environment_studio/environment_38_tile_layer_environment_area_selection_list.md`

Fichiers modifiés par Environment-38 :
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

Fichiers préexistants dans le worktree non touchés :
- aucun fichier préexistant modifié hors lot au démarrage.

Problèmes introduits par ce lot :
- aucun problème détecté par les tests et l’analyse ciblée lancés.

## 10. Non-objectifs respectés

- pas de suppression d’area ;
- pas de renommage ;
- pas de duplication ;
- pas de génération ;
- pas de preview de génération ;
- pas de MapPlacedElement ;
- pas de création automatique d’area hors bouton existant ;
- pas de migration ;
- pas de map_core ;
- pas de runtime ;
- pas de build_runner ;
- pas de generated files.

## 11. Evidence pack

Status initial :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
```

Status final :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
 M packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
 M packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart
?? reports/environment_studio/environment_38_tile_layer_environment_area_selection_list.md
```

Diff stat :

```bash
git diff --stat
```

Résultat :

```text
 ...le_layer_environment_attachment_read_model.dart |  26 +++
 ..._environment_attachment_read_model_builder.dart |  68 +++++++-
 .../src/features/editor/state/editor_notifier.dart |  54 ++++++
 .../lib/src/ui/panels/map_inspector_panel.dart     |   7 +
 .../tile_layer_environment_inspector_section.dart  | 190 +++++++++++++++++++++
 ...yer_environment_attachment_read_model_test.dart |  78 ++++++++-
 ...e_layer_environment_inspector_section_test.dart | 130 ++++++++++++++
 7 files changed, 551 insertions(+), 2 deletions(-)
```

Diff name-only :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart
packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Note :
- `git diff --stat` et `git diff --name-only` listent les fichiers suivis modifiés ;
- les fichiers créés par Environment-38 sont visibles dans le status final avec le préfixe `??`.

Diff check :

```bash
git diff --check
```

Résultat :

```text
```

Commandes principales :
- `git status --short --untracked-files=all`
- `find .. -name AGENTS.md -print`
- `rg -n "EnvironmentArea|selectedEnvironmentAreaId|areaById|areas|canPaintMask|areaSelectionRequired|selectedAreaMissing|TileLayerEnvironmentAttachmentReadModel|TileLayerEnvironmentInspectorSection|createEnvironmentAreaForActiveTileLayer|environmentMaskEditMode" packages/map_editor/lib/src packages/map_editor/test/environment_studio packages/map_core/lib/src`
- `dart format packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart packages/map_editor/lib/src/features/editor/state/editor_notifier.dart packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart packages/map_editor/test/environment_studio/tile_layer_environment_attachment_read_model_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_area_selection_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_area_notifier_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart`
- `flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart`
- `flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`
- `flutter analyze lib/src/application/models/tile_layer_environment_attachment_read_model.dart lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_attachment_read_model_test.dart test/environment_studio/tile_layer_environment_area_selection_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `git diff --check`

Résultats tests :
- tous les tests ciblés et non-régressions listés en section 7 passent.

Résultat analyse :
- `No issues found! (ran in 2.1s)`

## 12. Diff pertinent

### Hunk — `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`

```diff
@@ -40,6 +40,30 @@ final class TileLayerEnvironmentAttachmentIssue {
   final String message;
 }
 
+final class TileLayerEnvironmentAreaSummary {
+  const TileLayerEnvironmentAreaSummary({
+    required this.id,
+    required this.name,
+    required this.presetId,
+    required this.presetName,
+    required this.isSelected,
+    required this.maskActiveCellCount,
+    required this.generatedPlacementCount,
+    required this.missingGeneratedPlacementCount,
+    required this.hasMissingPreset,
+  });
+
+  final String id;
+  final String name;
+  final String presetId;
+  final String? presetName;
+  final bool isSelected;
+  final int maskActiveCellCount;
+  final int generatedPlacementCount;
+  final int missingGeneratedPlacementCount;
+  final bool hasMissingPreset;
+}
+
 final class TileLayerEnvironmentAttachmentReadModel {
   const TileLayerEnvironmentAttachmentReadModel({
     required this.state,
@@ -74,6 +98,7 @@ final class TileLayerEnvironmentAttachmentReadModel {
     this.emptyStateMessage = '',
     this.primaryActionLabel,
     this.issues = const [],
+    this.areaSummaries = const [],
   });
@@ -108,6 +133,7 @@ final class TileLayerEnvironmentAttachmentReadModel {
   final String emptyStateMessage;
   final String? primaryActionLabel;
   final List<TileLayerEnvironmentAttachmentIssue> issues;
+  final List<TileLayerEnvironmentAreaSummary> areaSummaries;
```

### Hunk — `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`

```diff
@@ -269,6 +269,18 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
     );
   }
 
+  final placedElementIds = map.placedElements.map((e) => e.id).toSet();
+  List<TileLayerEnvironmentAreaSummary> areaSummariesFor(
+    String? effectiveSelectedAreaId,
+  ) {
+    return _buildAreaSummaries(
+      manifest: manifest,
+      areas: areas,
+      selectedEnvironmentAreaId: effectiveSelectedAreaId,
+      placedElementIds: placedElementIds,
+    );
+  }
+
   final trimmedAreaId = selectedEnvironmentAreaId?.trim();
   final EnvironmentArea? area;
@@ -294,6 +306,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
         hasValidTargetTileLayer: true,
         hasMultipleAttachments: attachmentCount > 1,
         attachmentCount: attachmentCount,
+        areaSummaries: areaSummariesFor(null),
         emptyStateTitle: 'Zone introuvable',
@@ -316,6 +329,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
       hasValidTargetTileLayer: true,
       hasMultipleAttachments: attachmentCount > 1,
       attachmentCount: attachmentCount,
+      areaSummaries: areaSummariesFor(null),
       emptyStateTitle: 'Sélectionnez une zone d’environnement',
@@ -367,6 +380,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
       generatedPlacementCount: generatedPlacementCount,
       existingGeneratedPlacementCount: existingGeneratedPlacementCount,
       missingGeneratedPlacementCount: missingGeneratedPlacementCount,
+      areaSummaries: areaSummariesFor(area.id),
       canPaintMask: true,
@@ -395,6 +409,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
       generatedPlacementCount: generatedPlacementCount,
       existingGeneratedPlacementCount: existingGeneratedPlacementCount,
       missingGeneratedPlacementCount: missingGeneratedPlacementCount,
+      areaSummaries: areaSummariesFor(area.id),
       canPaintMask: true,
@@ -422,6 +437,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
       generatedPlacementCount: generatedPlacementCount,
       existingGeneratedPlacementCount: existingGeneratedPlacementCount,
       missingGeneratedPlacementCount: missingGeneratedPlacementCount,
+      areaSummaries: areaSummariesFor(area.id),
       canPaintMask: true,
@@ -449,6 +465,7 @@ TileLayerEnvironmentAttachmentReadModel _buildFromResolvedAttachment({
     generatedPlacementCount: 0,
     existingGeneratedPlacementCount: 0,
     missingGeneratedPlacementCount: 0,
+    areaSummaries: areaSummariesFor(area.id),
     canPaintMask: true,
@@ -521,6 +540,53 @@ TileLayerEnvironmentAttachmentReadModel _areaReadModel({
   );
 }
 
+List<TileLayerEnvironmentAreaSummary> _buildAreaSummaries({
+  required ProjectManifest manifest,
+  required List<EnvironmentArea> areas,
+  required String? selectedEnvironmentAreaId,
+  required Set<String> placedElementIds,
+}) {
+  final selectedId = selectedEnvironmentAreaId?.trim();
+  return List.unmodifiable(
+    [
+      for (final area in areas)
+        _areaSummary(
+          manifest: manifest,
+          area: area,
+          isSelected: selectedId != null &&
+              selectedId.isNotEmpty &&
+              area.id == selectedId,
+          placedElementIds: placedElementIds,
+        ),
+    ],
+  );
+}
+
+TileLayerEnvironmentAreaSummary _areaSummary({
+  required ProjectManifest manifest,
+  required EnvironmentArea area,
+  required bool isSelected,
+  required Set<String> placedElementIds,
+}) {
+  final preset = _findEnvironmentPreset(manifest, area.presetId);
+  final generatedPlacementCount = area.generatedPlacementIds.length;
+  final existingGeneratedPlacementCount = area.generatedPlacementIds
+      .where((id) => placedElementIds.contains(id))
+      .length;
+  return TileLayerEnvironmentAreaSummary(
+    id: area.id,
+    name: area.name,
+    presetId: area.presetId,
+    presetName: preset?.name,
+    isSelected: isSelected,
+    maskActiveCellCount: area.mask.activeCellCount,
+    generatedPlacementCount: generatedPlacementCount,
+    missingGeneratedPlacementCount:
+        generatedPlacementCount - existingGeneratedPlacementCount,
+    hasMissingPreset: preset == null,
+  );
+}
```

### Hunk — `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

```diff
@@ -4796,6 +4796,60 @@ class EditorNotifier extends _$EditorNotifier {
     }
   }
 
+  void selectEnvironmentAreaForActiveTileLayer(String areaId) {
+    final map = state.activeMap;
+    if (map == null) return;
+    final layerId = state.activeLayerId?.trim();
+    if (layerId == null || layerId.isEmpty) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour choisir une zone.',
+      );
+      return;
+    }
+    final activeLayer = _findLayerById(map, layerId);
+    if (activeLayer is! TileLayer) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez un TileLayer pour choisir une zone.',
+      );
+      return;
+    }
+
+    final aid = areaId.trim();
+    if (aid.isEmpty) {
+      state = state.copyWith(
+        errorMessage: 'Sélectionnez une zone d’environnement valide.',
+      );
+      return;
+    }
+
+    final target = resolveEnvironmentMaskPaintTarget(
+      map: map,
+      activeLayerId: layerId,
+      selectedAreaId: aid,
+    );
+    if (target == null) {
+      final hasAttachment = map.layers.any(
+        (layer) =>
+            layer is EnvironmentLayer &&
+            layer.content.targetTileLayerId?.trim() == layerId,
+      );
+      state = state.copyWith(
+        errorMessage: hasAttachment
+            ? 'La zone d’environnement sélectionnée est introuvable.'
+            : 'Activez d’abord l’environnement sur ce layer.',
+      );
+      return;
+    }
+
+    state = state.copyWith(
+      activeLayerId: layerId,
+      selectedEnvironmentAreaId: target.areaId,
+      environmentMaskEditMode: null,
+      statusMessage: 'Zone d’environnement sélectionnée.',
+      errorMessage: null,
+    );
+  }
+
   void startEnvironmentMaskPaintingForActiveTileLayer() {
```

### Hunk — `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

```diff
@@ -104,6 +104,10 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
         tileLayerEnvironmentReadModel != null &&
         _canCreateEnvironmentArea(tileLayerEnvironmentReadModel) &&
         selectedPresetIdForNewArea != null;
+    final canSelectTileLayerEnvironmentArea = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        tileLayerEnvironmentReadModel.hasAttachment &&
+        tileLayerEnvironmentReadModel.areaSummaries.isNotEmpty;
@@ -246,6 +250,9 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
                             );
                           }
                         : null,
+                    onSelectEnvironmentArea: canSelectTileLayerEnvironmentArea
+                        ? notifier.selectEnvironmentAreaForActiveTileLayer
+                        : null,
                     isMaskPaintingActive: isTileLayerMaskPaintingActive,
```

### Hunk — `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`

```diff
@@ -14,6 +14,7 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
     this.selectedPresetIdForNewArea,
     this.onSelectPresetForNewArea,
     this.onCreateArea,
+    this.onSelectEnvironmentArea,
@@ -29,6 +30,7 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
   final String? selectedPresetIdForNewArea;
   final ValueChanged<String>? onSelectPresetForNewArea;
   final VoidCallback? onCreateArea;
+  final ValueChanged<String>? onSelectEnvironmentArea;
@@ -83,6 +85,13 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
           ],
           const SizedBox(height: 12),
           _SummaryRows(readModel: readModel),
+          if (readModel.areaSummaries.isNotEmpty) ...[
+            const SizedBox(height: 12),
+            _EnvironmentAreaSummaryList(
+              summaries: readModel.areaSummaries,
+              onSelectEnvironmentArea: onSelectEnvironmentArea,
+            ),
+          ],
```

```diff
@@ -362,6 +371,169 @@ class _BrushSizeButton extends StatelessWidget {
   }
 }
 
+class _EnvironmentAreaSummaryList extends StatelessWidget {
+  const _EnvironmentAreaSummaryList({
+    required this.summaries,
+    required this.onSelectEnvironmentArea,
+  });
+
+  final List<TileLayerEnvironmentAreaSummary> summaries;
+  final ValueChanged<String>? onSelectEnvironmentArea;
+
+  @override
+  Widget build(BuildContext context) {
+    final label = EditorChrome.primaryLabel(context);
+    return Container(
+      padding: const EdgeInsets.all(10),
+      decoration: BoxDecoration(
+        color: EditorChrome.largeIslandSurfaceColor(
+          context,
+          tint: EditorChrome.inspectorJoyMint.withValues(alpha: 0.06),
+        ),
+        borderRadius: BorderRadius.circular(8),
+        border: Border.all(
+          color: EditorChrome.inspectorJoyMint.withValues(alpha: 0.22),
+        ),
+      ),
+      child: Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          Text(
+            'Zones d’environnement',
+            style: TextStyle(
+              color: label,
+              fontSize: 12,
+              fontWeight: FontWeight.w800,
+            ),
+          ),
+          const SizedBox(height: 8),
+          for (final summary in summaries)
+            Padding(
+              padding: EdgeInsets.only(
+                bottom: summary == summaries.last ? 0 : 8,
+              ),
+              child: _EnvironmentAreaSummaryRow(
+                summary: summary,
+                onSelectEnvironmentArea: onSelectEnvironmentArea,
+              ),
+            ),
+        ],
+      ),
+    );
+  }
+}
```

```diff
@@ -730,6 +902,24 @@ String? _presetNameForId(
   return null;
 }
 
+List<String> _areaSummaryDetails(TileLayerEnvironmentAreaSummary summary) {
+  final presetName = summary.presetName?.trim();
+  final presetLabel = summary.hasMissingPreset
+      ? 'Preset introuvable : ${summary.presetId}'
+      : 'Preset : ${presetName == null || presetName.isEmpty ? summary.presetId : presetName}';
+  final details = <String>[
+    presetLabel,
+    'Masque : ${_paintedCellsLabel(summary.maskActiveCellCount)}',
+    'Placements : ${summary.generatedPlacementCount}',
+  ];
+  if (summary.missingGeneratedPlacementCount > 0) {
+    final count = summary.missingGeneratedPlacementCount;
+    details.add(
+        count == 1 ? '1 placement manquant' : '$count placements manquants');
+  }
+  return details;
+}
```

### Nouveau fichier — `packages/map_editor/test/environment_studio/tile_layer_environment_area_selection_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier.selectEnvironmentAreaForActiveTileLayer', () {
    test('sélectionne une area et garde le TileLayer actif sans muter MapData',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
        environmentMaskEditMode: EnvironmentMaskEditMode.paint,
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('area_b');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_b');
      expect(state.environmentMaskEditMode, isNull);
      expect(state.activeMap!.placedElements, isEmpty);
      expect(state.errorMessage, isNull);
    });

    test('refuse si aucun TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('area_b');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'env');
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('TileLayer'));
    });

    test('refuse si aucun EnvironmentLayer attaché', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithoutAttachment();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('area_b');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, isNull);
      expect(state.errorMessage, contains('Activez'));
    });

    test('refuse areaId vide', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('   ');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('zone'));
    });

    test('refuse area introuvable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAreas();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_a',
      );

      notifier.selectEnvironmentAreaForActiveTileLayer('missing');

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.selectedEnvironmentAreaId, 'area_a');
      expect(state.errorMessage, contains('introuvable'));
    });
  });
}

MapData _mapWithAreas() {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 3, height: 3),
    layers: [
      const TileLayer(
        id: 'tiles',
        name: 'Ground',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
      MapLayer.environment(
        id: 'env',
        name: 'Environment',
        content: EnvironmentLayerContent(
          targetTileLayerId: 'tiles',
          areas: [
            _area('area_a'),
            _area('area_b'),
          ],
        ),
      ),
    ],
  );
}

MapData _mapWithoutAttachment() {
  return const MapData(
    id: 'map',
    name: 'Map',
    size: GridSize(width: 3, height: 3),
    layers: [
      TileLayer(
        id: 'tiles',
        name: 'Ground',
        tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0],
      ),
    ],
  );
}

EnvironmentArea _area(String id) {
  return EnvironmentArea(
    id: id,
    name: 'Zone $id',
    presetId: 'forest',
    mask: EnvironmentAreaMask(
      width: 3,
      height: 3,
      cells: List<bool>.filled(9, false),
    ),
    seed: 0,
  );
}

ProjectManifest _manifest() {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: const [
      ProjectElementEntry(
        id: 'tree',
        name: 'Tree',
        tilesetId: 'nature',
        categoryId: 'trees',
        frames: [
          TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
        ],
      ),
    ],
    surfaceCatalog: ProjectSurfaceCatalog(),
    environmentPresets: [
      EnvironmentPreset(
        id: 'forest',
        name: 'Forêt',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
    ],
  );
}
```

Le présent fichier est le rapport Environment-38 ; ses sections constituent son contenu complet.

## 13. Auto-review

- La liste affiche-t-elle toutes les areas dans l’ordre ? Oui, le builder itère `EnvironmentLayerContent.areas`.
- La zone active est-elle clairement visible ? Oui, elle reçoit le badge `Zone active`.
- Peut-on sélectionner une autre zone ? Oui, les rows non actives affichent `Sélectionner` si le callback est fourni.
- La sélection garde-t-elle le TileLayer actif ? Oui, le notifier remet `activeLayerId` au TileLayer.
- La sélection remet-elle environmentMaskEditMode à null ? Oui.
- La sélection ne mute-t-elle pas MapData ? Oui, le test vérifie `same(map)`.
- Les presets manquants sont-ils visibles ? Oui, summary et widget affichent `Preset introuvable : <id>`.
- Les compteurs masque / placements sont-ils corrects ? Oui, couverts par tests read model et widget.
- Aucune génération n’est-elle lancée ? Oui, aucun générateur n’est appelé ou modifié.
- Aucun MapPlacedElement n’est-il créé ? Oui, test notifier et non-régressions le vérifient.
- Le flow legacy reste-t-il intact ? Oui, les tests de brush mode, erase mode et routing restent verts ; le callback de sélection TileLayer n’est passé que pour un TileLayer actif.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :
- le périmètre “sélection uniquement” était net ;
- le comportement des cas multiples sans sélection et sélection absente était explicite ;
- la décision de stopper `environmentMaskEditMode` était proposée et testable.

Ambigu :
- le prompt laissait une option pour legacy : liste lecture seule ou sélection ; j’ai gardé le callback uniquement TileLayer pour préserver l’ancien inspector legacy.
- le niveau visuel exact des rows n’était pas spécifié ; j’ai repris le style compact des blocs existants.

À trancher avant Environment-39 :
- faut-il permettre une sélection d’area depuis la section TileLayer même en mode legacy `EnvironmentLayer` actif ?
- faut-il déplacer la sélection de zone dans un composant réutilisable si Environment-39 ajoute beaucoup de paramètres locaux ?
- faut-il renommer `Arrêter la peinture` en `Arrêter l’édition du masque` avant d’ajouter plus de réglages ?

## 15. Verdict

```text
Environment-38 livré
Code produit modifié : oui
Code UI modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-39 — TileLayer Environment Local Generation Params V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/switch/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié le modèle persistant.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement la liste/sélection d’areas.
- [x] Je n’ai pas ajouté de suppression d’area.
- [x] Je n’ai pas ajouté de renommage d’area.
- [x] Je n’ai pas ajouté de génération.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] La sélection garde le TileLayer actif.
- [x] La sélection ne mute pas MapData.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
