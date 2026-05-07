# Environment-36 — TileLayer Environment Erase Mode V0

## 1. Résumé

Environment-36 ajoute l’entrée `Effacer du masque` dans la section TileLayer-centric `Environnement du layer`.

Le lot ajoute :

- `EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer()`;
- une factorisation minimale du start paint/erase TileLayer-centric ;
- le wiring `MapInspectorPanel` vers le callback erase ;
- l’état UI `Effacement actif` dans `TileLayerEnvironmentInspectorSection` ;
- deux tests canvas erase avec brush size `3` et `1` ;
- un test notifier ciblé pour le mode erase.

Le canvas n’a pas été modifié : il supportait déjà `EnvironmentMaskEditMode.erase` via `paintEnvironmentAreaMaskAt`, qui passe `isActive=false` au use case de brush.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets / recettes.
- Map Editor / TileLayer inspector devient le lieu de peinture/génération.
- Ce lot ajoute seulement le mode effacement du masque.
- Le mode erase utilise la même taille de brush que la peinture.
- Pas de génération ni preview dans ce lot.

## 3. Audit de l’existant

Fichiers inspectés :

- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
  - Résout déjà une cible de peinture depuis un `EnvironmentLayer` legacy ou depuis un `TileLayer` attaché.
- `packages/map_editor/lib/src/application/use_cases/environment_mask_use_cases.dart`
  - `PaintEnvironmentAreaMaskBrushStrokeUseCase` accepte déjà `isActive=false`, donc erase existe côté opération pure.
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
  - `environmentMaskEditMode` existe déjà dans `EditorState`.
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
  - Le flow legacy expose déjà `startEnvironmentAreaMaskErase`.
  - Le flow TileLayer-centric exposait seulement `startEnvironmentMaskPaintingForActiveTileLayer`.
  - `paintEnvironmentAreaMaskAt` utilise déjà `mode == paint` pour `isActive=true`, sinon `erase` pour `isActive=false`.
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
  - `_isEnvironmentMaskEditing` accepte déjà `paint` et `erase`.
  - `applyToolAt` route déjà vers `notifier.paintEnvironmentAreaMaskAt`.
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
  - Passait seulement `onStartMaskPainting`.
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
  - Affichait seulement `Peindre le masque` et `Peinture active`.
- Tests Env-34/35 inspectés :
  - `tile_layer_environment_brush_mode_entry_test.dart`
  - `environment_mask_brush_size_use_case_test.dart`
  - `tile_layer_environment_brush_size_state_test.dart`
  - `tile_layer_environment_mask_paint_routing_test.dart`
  - `tile_layer_environment_inspector_section_test.dart`
  - `environment_layer_mask_brush_tool_test.dart`

Décision retenue :

- Ne pas toucher au canvas.
- Ne pas créer de nouveau read model.
- Réutiliser `canPaintMask` comme capacité commune d’édition du masque.
- Ajouter `isMaskErasingActive` et `onStartMaskErasing` dans le widget.
- Garder `stopEnvironmentMaskPainting()` comme stop commun V0.

## 4. Notifier / état

Méthode ajoutée :

```dart
void startEnvironmentMaskErasingForActiveTileLayer()
```

La méthode appelle le même helper privé que paint :

```dart
void _startEnvironmentMaskEditingForActiveTileLayer({
  required EnvironmentMaskEditMode mode,
})
```

Conditions start erase :

- `activeMap` présente ;
- `activeLayerId` non vide ;
- layer actif = `TileLayer` ;
- `selectedEnvironmentAreaId` non vide ;
- `resolveEnvironmentMaskPaintTarget(...)` trouve l’`EnvironmentLayer` attaché et l’area.

Effets :

- `activeLayerId` reste le `TileLayer` ;
- `selectedEnvironmentAreaId` reste l’area ;
- `environmentMaskEditMode = EnvironmentMaskEditMode.erase` ;
- `MapData` n’est pas mutée au start/stop ;
- aucun placement n’est créé.

Stop :

- `stopEnvironmentMaskPainting()` reste utilisé ;
- il remet `environmentMaskEditMode` à `null` ;
- il garde `activeLayerId` et `selectedEnvironmentAreaId`.

## 5. Canvas / routing

`map_canvas.dart` n’a pas été modifié.

Raison :

- `_isEnvironmentMaskEditing` acceptait déjà `paint` et `erase`.
- `MapCanvas` routait déjà les taps vers `notifier.paintEnvironmentAreaMaskAt(...)`.
- `EditorNotifier.paintEnvironmentAreaMaskAt` calcule déjà :

```dart
final isActive = mode == EnvironmentMaskEditMode.paint;
```

Donc :

- `paint` → `isActive=true` ;
- `erase` → `isActive=false` ;
- brush size lue depuis `environmentMaskBrushSizeProvider` ;
- le resolver TileLayer-centric reste le même.

## 6. Intégration UI

Ajouts UI :

- callback optionnel `onStartMaskErasing`;
- booléen `isMaskErasingActive`;
- bouton `Effacer du masque`;
- état actif `Effacement actif`;
- message :

```text
Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.
```

Règles :

- `Peindre le masque` et `Effacer du masque` sont visibles quand `readModel.canPaintMask == true` et aucun mode n’est actif.
- `Effacer du masque` est actif seulement si le callback est fourni et qu’il n’y a pas d’erreur.
- Quand paint ou erase est actif, la section affiche l’état actif + `Arrêter la peinture`.
- `Taille du pinceau` reste visible en mode erase.
- `Générer dans ce layer` et `Effacer les placements générés` restent désactivés.

## 7. Tests

TDD RED :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

Résultat rouge attendu :

```text
Error: No named parameter with the name 'isMaskErasingActive'.
Some tests failed.
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart
```

Résultat rouge attendu :

```text
Error: The method 'startEnvironmentMaskErasingForActiveTileLayer' isn't defined for the type 'EditorNotifier'.
Some tests failed.
```

Commande parallèle initiale à ne pas retenir comme résultat métier :

```text
Unable to delete file or directory at "/Users/karim/Project/pokemonProject/packages/map_editor/macos/Flutter/ephemeral/Packages/.packages".
Waiting for another flutter command to release the startup lock...
```

Cause : deux commandes `flutter test` lancées en parallèle. Les vérifications suivantes ont été relancées séquentiellement.

Tests verts :

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_erase_mode_test.dart
```

```text
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
flutter test test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

```text
00:00 +0: tap canvas peint le masque attaché quand le TileLayer est actif
00:00 +1: tap canvas peint un carré 3x3 avec brush size 3
00:00 +2: tap canvas efface un carré 3x3 avec brush size 3
00:00 +3: tap canvas erase taille 1 efface exactement la cellule centrale
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:00 +0: TileLayerEnvironmentInspectorSection affiche Aucun environnement sur ce layer
00:00 +1: TileLayerEnvironmentInspectorSection affiche Activer l’environnement sans callback de mutation
00:00 +2: TileLayerEnvironmentInspectorSection active Activer l’environnement avec callback
00:00 +3: TileLayerEnvironmentInspectorSection bloque Ajouter une zone si aucun preset existe
00:00 +4: TileLayerEnvironmentInspectorSection active Ajouter une zone avec un preset unique
00:00 +5: TileLayerEnvironmentInspectorSection bloque Ajouter une zone avec plusieurs presets sans sélection
00:00 +6: TileLayerEnvironmentInspectorSection active Ajouter une zone avec plusieurs presets et sélection
00:00 +7: TileLayerEnvironmentInspectorSection affiche un état prêt avec preset zone et masque
00:00 +8: TileLayerEnvironmentInspectorSection affiche le nombre de placements générés
00:00 +9: TileLayerEnvironmentInspectorSection affiche un warning si des placements sont manquants
00:00 +10: TileLayerEnvironmentInspectorSection affiche une erreur si le preset est manquant
00:00 +11: TileLayerEnvironmentInspectorSection affiche un message legacy
00:00 +12: TileLayerEnvironmentInspectorSection n’affiche pas d’action active de génération dans ce lot
00:00 +13: TileLayerEnvironmentInspectorSection active Peindre le masque avec callback
00:00 +14: TileLayerEnvironmentInspectorSection affiche Effacer du masque quand le masque est éditable
00:00 +15: TileLayerEnvironmentInspectorSection active Effacer du masque avec callback
00:00 +16: TileLayerEnvironmentInspectorSection affiche Taille du pinceau et les choix 1 3 5 7
00:00 +17: TileLayerEnvironmentInspectorSection cliquer sur 3 change la taille du pinceau
00:00 +18: TileLayerEnvironmentInspectorSection sans callback les tailles de pinceau sont désactivées
00:01 +19: TileLayerEnvironmentInspectorSection affiche Peinture active et stop quand le mode est actif
00:01 +20: TileLayerEnvironmentInspectorSection affiche Effacement actif et garde la taille visible
00:01 +21: TileLayerEnvironmentInspectorSection après création avec masque vide la brush reste désactivée
00:01 +22: TileLayerEnvironmentInspectorSection la suppression des placements générés reste désactivée
00:01 +23: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor
flutter test test/environment_studio/environment_mask_brush_size_use_case_test.dart
```

```text
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
flutter test test/environment_studio/tile_layer_environment_brush_size_state_test.dart
```

```text
00:00 +0: Environment mask brush size state taille par défaut = 1
00:00 +1: Environment mask brush size state setEnvironmentMaskBrushSize change la taille
00:00 +2: Environment mask brush size state taille invalide ne change pas l’état et affiche une erreur
00:00 +3: Environment mask brush size state changer la taille ne mute pas MapData ni les sélections
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
```

```text
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
flutter test test/environment_studio/environment_layer_mask_brush_tool_test.dart
```

```text
00:00 +0: Lot 22 — PaintEnvironmentAreaMaskCellUseCase paint (1,1) : une cellule active, preset et placements préservés
00:00 +1: Lot 22 — PaintEnvironmentAreaMaskCellUseCase erase : cellule repasse false, compteur diminue
00:00 +2: Lot 22 — PaintEnvironmentAreaMaskCellUseCase no-op paint true sur true → même référence MapData
00:00 +3: Lot 22 — PaintEnvironmentAreaMaskCellUseCase no-op erase false sur false → même référence MapData
00:00 +4: Lot 22 — PaintEnvironmentAreaMaskCellUseCase erreurs use case
00:00 +5: Lot 22 — EditorNotifier masque start paint / erase / stop + paint met dirty et préserve chemins
00:00 +6: Lot 22 — EditorNotifier masque changer de layer actif hors Environment → mode masque désactivé
00:00 +7: Lot 22 — EditorNotifier masque removeEnvironmentArea nettoie la sélection masque
00:00 +8: Lot 22 — inspecteur masque boutons masque + libellé édition active
00:00 +9: Lot 22 — MapCanvas tap masque tap peint une cellule du masque
00:00 +10: Lot 22 — MapCanvas tap masque mode erase + tap efface la cellule
00:00 +11: Lot 22 — MapCanvas tap masque tap sans mode placement ne supprime pas un arbre généré
00:00 +12: Lot 22 — MapCanvas tap masque mode suppression + tap retire un arbre généré
[editor][environment] deleted generated placement by click id=tree_a elementId=tree pos=(0,0)
00:00 +13: Lot 22 — MapGridPainter overlay masque environmentMaskOverlay actif ne lève pas
00:00 +14: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_read_model_test.dart
```

```text
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
00:00 +15: TileLayerEnvironmentAttachmentReadModel détecte preset valide
00:00 +16: TileLayerEnvironmentAttachmentReadModel détecte preset manquant
00:00 +17: TileLayerEnvironmentAttachmentReadModel détecte masque vide
00:00 +18: TileLayerEnvironmentAttachmentReadModel détecte masque non vide
00:00 +19: TileLayerEnvironmentAttachmentReadModel compte generatedPlacementIds et placements manquants
00:00 +20: TileLayerEnvironmentAttachmentReadModel retourne un état neutre pour un layer non TileLayer
00:00 +21: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_attachment_enable_use_case_test.dart
```

```text
00:00 +0: EnableTileLayerEnvironmentAttachmentUseCase crée un EnvironmentLayer attaché à un TileLayer sans environnement
00:00 +1: EnableTileLayerEnvironmentAttachmentUseCase insère le nouvel EnvironmentLayer juste après le TileLayer ciblé
00:00 +2: EnableTileLayerEnvironmentAttachmentUseCase ne recrée rien si un EnvironmentLayer cible déjà le TileLayer
00:00 +3: EnableTileLayerEnvironmentAttachmentUseCase refuse un layer introuvable
00:00 +4: EnableTileLayerEnvironmentAttachmentUseCase refuse un layer non TileLayer
00:00 +5: EnableTileLayerEnvironmentAttachmentUseCase préserve les autres layers et les placedElements
00:00 +6: EnableTileLayerEnvironmentAttachmentUseCase génère un id unique si un layer environnement porte déjà le base id
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor
flutter test test/environment_studio/tile_layer_environment_area_create_use_case_test.dart
```

```text
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

```text
00:00 +0: EditorNotifier.createEnvironmentAreaForActiveTileLayer crée une area et garde le TileLayer sélectionné
00:00 +1: EditorNotifier.createEnvironmentAreaForActiveTileLayer refuse un preset absent sans créer de zone
00:00 +2: All tests passed!
```

## 8. Analyse ciblée

Commande :

```bash
cd packages/map_editor
flutter analyze lib/src/features/editor/state/editor_notifier.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_erase_mode_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart test/environment_studio/environment_mask_brush_size_use_case_test.dart test/environment_studio/tile_layer_environment_brush_size_state_test.dart test/environment_studio/tile_layer_environment_brush_mode_entry_test.dart
```

Résultat :

```text
Analyzing 10 items...
No issues found! (ran in 2.5s)
```

Dette préexistante hors lot : aucune détectée par l’analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers déjà présents/modifiés avant Environment-36 :

```text
aucun — git status initial vide
```

Fichiers créés par Environment-36 :

- `packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart`
- `reports/environment_studio/environment_36_tile_layer_environment_erase_mode.md`

Fichiers modifiés par Environment-36 :

- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`

Fichiers préexistants dans le worktree non touchés :

```text
aucun
```

## 10. Non-objectifs respectés

- Pas de brush circulaire.
- Pas de shape.
- Pas de preview cursor.
- Pas de slider complexe.
- Pas de generate.
- Pas de preview de génération.
- Pas de clear/regenerate/shuffle.
- Pas de `MapPlacedElement`.
- Pas de création d’area.
- Pas de création de preset.
- Pas de migration.
- Pas de `map_core`.
- Pas de runtime.
- Pas de build_runner.
- Pas de generated files.

## 11. Evidence pack

Git status initial :

```bash
git status --short --untracked-files=all
```

```text
sortie vide
```

Diff stat avant création du rapport :

```bash
git diff --stat
```

```text
 .../src/features/editor/state/editor_notifier.dart |  25 +++-
 .../lib/src/ui/panels/map_inspector_panel.dart     |  18 ++-
 .../tile_layer_environment_inspector_section.dart  |  42 +++++-
 ...e_layer_environment_inspector_section_test.dart |  95 ++++++++++++
 ..._layer_environment_mask_paint_routing_test.dart | 166 +++++++++++++++++++++
 5 files changed, 329 insertions(+), 17 deletions(-)
```

Diff name-only avant création du rapport :

```bash
git diff --name-only
```

```text
packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
```

Untracked avant création du rapport :

```text
?? packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart
```

Git diff check :

```bash
git diff --check
```

```text
sortie vide
```

Git status final exact après création du rapport :

```bash
git status --short --untracked-files=all
```

```text
 M packages/map_editor/lib/src/features/editor/state/editor_notifier.dart
 M packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart
 M packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart
 M packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart
?? reports/environment_studio/environment_36_tile_layer_environment_erase_mode.md
```

Commandes principales :

- `git status --short --untracked-files=all`
- `rg -n "EnvironmentMaskEditMode|environmentMaskEditMode|erase|paintEnvironmentAreaMaskAt|setEnvironmentMaskBrushSize|environmentMaskBrushSize|PaintEnvironmentAreaMaskBrushStrokeUseCase|resolveEnvironmentMaskPaintTarget|Peindre le masque|Arrêter la peinture|Taille du pinceau" packages/map_editor/lib/src packages/map_editor/test/environment_studio`
- `dart format lib/src/features/editor/state/editor_notifier.dart lib/src/ui/panels/map_inspector_panel.dart lib/src/ui/panels/tile_layer_environment_inspector_section.dart test/environment_studio/tile_layer_environment_erase_mode_test.dart test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart test/environment_studio/tile_layer_environment_inspector_section_test.dart`
- les commandes `flutter test` listées en section 7 ;
- la commande `flutter analyze` listée en section 8 ;
- `git diff --check`.

## 12. Diff pertinent

### `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`

```diff
@@ -4797,19 +4797,33 @@ class EditorNotifier extends _$EditorNotifier {
   }
 
   void startEnvironmentMaskPaintingForActiveTileLayer() {
+    _startEnvironmentMaskEditingForActiveTileLayer(
+      mode: EnvironmentMaskEditMode.paint,
+    );
+  }
+
+  void startEnvironmentMaskErasingForActiveTileLayer() {
+    _startEnvironmentMaskEditingForActiveTileLayer(
+      mode: EnvironmentMaskEditMode.erase,
+    );
+  }
+
+  void _startEnvironmentMaskEditingForActiveTileLayer({
+    required EnvironmentMaskEditMode mode,
+  }) {
     final map = state.activeMap;
     if (map == null) return;
     final layerId = state.activeLayerId?.trim();
     if (layerId == null || layerId.isEmpty) {
       state = state.copyWith(
-        errorMessage: 'Sélectionnez un TileLayer pour peindre le masque.',
+        errorMessage: 'Sélectionnez un TileLayer pour éditer le masque.',
       );
       return;
     }
     final activeLayer = _findLayerById(map, layerId);
     if (activeLayer is! TileLayer) {
       state = state.copyWith(
-        errorMessage: 'Sélectionnez un TileLayer pour peindre le masque.',
+        errorMessage: 'Sélectionnez un TileLayer pour éditer le masque.',
       );
       return;
     }
@@ -4842,9 +4856,10 @@ class EditorNotifier extends _$EditorNotifier {
     state = state.copyWith(
       activeLayerId: layerId,
       selectedEnvironmentAreaId: target.areaId,
-      environmentMaskEditMode: EnvironmentMaskEditMode.paint,
-      statusMessage:
-          'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
+      environmentMaskEditMode: mode,
+      statusMessage: mode == EnvironmentMaskEditMode.erase
+          ? 'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.'
+          : 'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
       errorMessage: null,
     );
   }
```

### `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`

```diff
@@ -108,12 +108,18 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
         tileLayerEnvironmentReadModel != null &&
         state.environmentMaskEditMode == EnvironmentMaskEditMode.paint &&
         state.selectedEnvironmentAreaId != null;
-    final canStartTileLayerMaskPainting = activeLayer is TileLayer &&
+    final isTileLayerMaskErasingActive = activeLayer is TileLayer &&
+        tileLayerEnvironmentReadModel != null &&
+        state.environmentMaskEditMode == EnvironmentMaskEditMode.erase &&
+        state.selectedEnvironmentAreaId != null;
+    final isTileLayerMaskEditingActive =
+        isTileLayerMaskPaintingActive || isTileLayerMaskErasingActive;
+    final canStartTileLayerMaskEditing = activeLayer is TileLayer &&
         tileLayerEnvironmentReadModel != null &&
         tileLayerEnvironmentReadModel.canPaintMask &&
         !tileLayerEnvironmentReadModel.hasErrors &&
         state.selectedEnvironmentAreaId != null &&
-        !isTileLayerMaskPaintingActive;
+        !isTileLayerMaskEditingActive;
@@ -241,11 +247,15 @@ class _MapInspectorPanelState extends ConsumerState<MapInspectorPanel> {
                     isMaskPaintingActive: isTileLayerMaskPaintingActive,
-                    onStartMaskPainting: canStartTileLayerMaskPainting
+                    isMaskErasingActive: isTileLayerMaskErasingActive,
+                    onStartMaskPainting: canStartTileLayerMaskEditing
                         ? notifier
                             .startEnvironmentMaskPaintingForActiveTileLayer
                         : null,
-                    onStopMaskPainting: isTileLayerMaskPaintingActive
+                    onStartMaskErasing: canStartTileLayerMaskEditing
+                        ? notifier.startEnvironmentMaskErasingForActiveTileLayer
+                        : null,
+                    onStopMaskPainting: isTileLayerMaskEditingActive
                         ? notifier.stopEnvironmentMaskPainting
                         : null,
```

### `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`

```diff
@@ -15,7 +15,9 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
     this.onSelectPresetForNewArea,
     this.onCreateArea,
     this.isMaskPaintingActive = false,
+    this.isMaskErasingActive = false,
     this.onStartMaskPainting,
+    this.onStartMaskErasing,
@@ -28,7 +30,9 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
   final ValueChanged<String>? onSelectPresetForNewArea;
   final VoidCallback? onCreateArea;
   final bool isMaskPaintingActive;
+  final bool isMaskErasingActive;
   final VoidCallback? onStartMaskPainting;
+  final VoidCallback? onStartMaskErasing;
@@ -38,6 +42,7 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
     const accent = EditorChrome.inspectorJoyMint;
     final label = EditorChrome.primaryLabel(context);
     final subtle = EditorChrome.subtleLabel(context);
+    final isMaskEditingActive = isMaskPaintingActive || isMaskErasingActive;
@@ -87,11 +92,11 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
-          if (isMaskPaintingActive) ...[
+          if (isMaskEditingActive) ...[
             const SizedBox(height: 12),
-            const _ActivePaintingBanner(),
+            _ActiveMaskEditingBanner(isErasing: isMaskErasingActive),
           ],
-          if (readModel.canPaintMask || isMaskPaintingActive) ...[
+          if (readModel.canPaintMask || isMaskEditingActive) ...[
@@ -114,7 +119,9 @@ class TileLayerEnvironmentInspectorSection extends StatelessWidget {
             selectedPresetIdForNewArea: selectedPresetIdForNewArea,
             onCreateArea: onCreateArea,
             isMaskPaintingActive: isMaskPaintingActive,
+            isMaskErasingActive: isMaskErasingActive,
             onStartMaskPainting: onStartMaskPainting,
+            onStartMaskErasing: onStartMaskErasing,
@@ -139,11 +146,17 @@ final class TileLayerEnvironmentPresetOption {
-class _ActivePaintingBanner extends StatelessWidget {
-  const _ActivePaintingBanner();
+class _ActiveMaskEditingBanner extends StatelessWidget {
+  const _ActiveMaskEditingBanner({required this.isErasing});
+
+  final bool isErasing;
 
   @override
   Widget build(BuildContext context) {
+    final title = isErasing ? 'Effacement actif' : 'Peinture active';
+    final message = isErasing
+        ? 'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.'
+        : 'Mode peinture actif : cliquez sur la carte pour peindre le masque.';
@@ -160,7 +173,7 @@ class _ActivePaintingBanner extends StatelessWidget {
-            'Peinture active',
+            title,
@@ -169,7 +182,7 @@ class _ActivePaintingBanner extends StatelessWidget {
-            'Mode peinture actif : cliquez sur la carte pour peindre le masque.',
+            message,
@@ -507,7 +520,9 @@ class _FutureActions extends StatelessWidget {
     required this.selectedPresetIdForNewArea,
     required this.onCreateArea,
     required this.isMaskPaintingActive,
+    required this.isMaskErasingActive,
     required this.onStartMaskPainting,
+    required this.onStartMaskErasing,
@@ -517,12 +532,15 @@ class _FutureActions extends StatelessWidget {
   final String? selectedPresetIdForNewArea;
   final VoidCallback? onCreateArea;
   final bool isMaskPaintingActive;
+  final bool isMaskErasingActive;
   final VoidCallback? onStartMaskPainting;
+  final VoidCallback? onStartMaskErasing;
@@ -547,7 +565,7 @@ class _FutureActions extends StatelessWidget {
-    if (isMaskPaintingActive) {
+    if (isMaskEditingActive) {
@@ -565,6 +583,14 @@ class _FutureActions extends StatelessWidget {
           onPressed: onStartMaskPainting,
         ),
       );
+      actions.add(
+        _ActionData(
+          icon: CupertinoIcons.delete_left,
+          label: 'Effacer du masque',
+          enabled: !readModel.hasErrors && onStartMaskErasing != null,
+          onPressed: onStartMaskErasing,
+        ),
+      );
```

### `packages/map_editor/test/environment_studio/tile_layer_environment_erase_mode_test.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/editor/state/editor_state.dart';
import 'package:map_editor/src/features/editor/tools/editor_tool.dart';

void main() {
  group('EditorNotifier.startEnvironmentMaskErasingForActiveTileLayer', () {
    test('active le mode erase sans changer le TileLayer sélectionné', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedArea();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, EnvironmentMaskEditMode.erase);
      expect(state.activeMap!.placedElements, isEmpty);
    });

    test('stop remet le mode à null et garde la zone active', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      final map = _mapWithAttachedArea();
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: map,
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
        environmentMaskEditMode: EnvironmentMaskEditMode.erase,
      );

      notifier.stopEnvironmentMaskPainting();

      final state = notifier.state;
      expect(state.activeMap, same(map));
      expect(state.activeLayerId, 'tiles');
      expect(state.selectedEnvironmentAreaId, 'area_forest');
      expect(state.environmentMaskEditMode, isNull);
    });

    test('refuse si aucun TileLayer actif', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachedArea(),
        activeLayerId: 'env',
        selectedEnvironmentAreaId: 'area_forest',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.activeLayerId, 'env');
      expect(state.errorMessage, contains('TileLayer'));
    });

    test('refuse si aucun EnvironmentLayer attaché', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithoutAttachment(),
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'area_forest',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('Activez'));
    });

    test('refuse si aucune area est sélectionnée', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachedArea(),
        activeLayerId: 'tiles',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('zone'));
    });

    test('refuse si area sélectionnée introuvable', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(editorNotifierProvider.notifier);
      notifier.state = EditorState(
        project: _manifest(),
        activeMap: _mapWithAttachedArea(),
        activeLayerId: 'tiles',
        selectedEnvironmentAreaId: 'missing',
      );

      notifier.startEnvironmentMaskErasingForActiveTileLayer();

      final state = notifier.state;
      expect(state.environmentMaskEditMode, isNull);
      expect(state.errorMessage, contains('introuvable'));
    });
  });
}

MapData _mapWithAttachedArea() {
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
            EnvironmentArea(
              id: 'area_forest',
              name: 'Forêt',
              presetId: 'forest',
              mask: EnvironmentAreaMask(
                width: 3,
                height: 3,
                cells: List<bool>.filled(9, true),
              ),
              seed: 0,
            ),
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

### `packages/map_editor/test/environment_studio/tile_layer_environment_inspector_section_test.dart`

```diff
@@ -439,6 +439,57 @@ void main() {
+    testWidgets('affiche Effacer du masque quand le masque est éditable',
+        (tester) async {
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.emptyMask,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaId: 'area',
+          selectedEnvironmentAreaName: 'Forêt',
+          selectedPresetName: 'Forêt',
+          canPaintMask: true,
+          emptyStateTitle: 'Masque vide',
+          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
+        ),
+      );
+
+      expect(find.text('Effacer du masque'), findsOneWidget);
+      expect(_buttonFor(tester, 'Effacer du masque').onPressed, isNull);
+    });
+
+    testWidgets('active Effacer du masque avec callback', (tester) async {
+      var pressed = 0;
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.emptyMask,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaId: 'area',
+          selectedEnvironmentAreaName: 'Forêt',
+          selectedPresetName: 'Forêt',
+          canPaintMask: true,
+          emptyStateTitle: 'Masque vide',
+          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
+        ),
+        onStartMaskErasing: () {
+          pressed++;
+        },
+      );
+
+      expect(_buttonFor(tester, 'Effacer du masque').onPressed, isNotNull);
+
+      await tester.tap(find.text('Effacer du masque'));
+      await tester.pump();
+
+      expect(pressed, 1);
+    });
@@ -556,6 +607,46 @@ void main() {
+    testWidgets('affiche Effacement actif et garde la taille visible',
+        (tester) async {
+      var stopped = 0;
+      await _pump(
+        tester,
+        const TileLayerEnvironmentAttachmentReadModel(
+          state: TileLayerEnvironmentAttachmentState.emptyMask,
+          selectedLayerKind: TileLayerEnvironmentSelectedLayerKind.tile,
+          hasAttachment: true,
+          hasValidTargetTileLayer: true,
+          selectedEnvironmentAreaId: 'area',
+          selectedEnvironmentAreaName: 'Forêt',
+          selectedPresetName: 'Forêt',
+          canPaintMask: true,
+          emptyStateTitle: 'Masque vide',
+          emptyStateMessage: 'Peignez une zone sur la carte avant de générer.',
+        ),
+        isMaskErasingActive: true,
+        onStopMaskPainting: () {
+          stopped++;
+        },
+      );
+
+      expect(find.text('Effacement actif'), findsOneWidget);
+      expect(
+        find.text(
+          'Mode effacement actif : cliquez sur la carte pour retirer des cellules du masque.',
+        ),
+        findsOneWidget,
+      );
+      expect(find.text('Taille du pinceau'), findsOneWidget);
+      expect(find.text('Arrêter la peinture'), findsOneWidget);
+      expect(_buttonFor(tester, 'Arrêter la peinture').onPressed, isNotNull);
+
+      await tester.tap(find.text('Arrêter la peinture'));
+      await tester.pump();
+
+      expect(stopped, 1);
+    });
@@ -619,7 +710,9 @@ Future<void> _pump(
   VoidCallback? onCreateArea,
   bool isMaskPaintingActive = false,
+  bool isMaskErasingActive = false,
   VoidCallback? onStartMaskPainting,
+  VoidCallback? onStartMaskErasing,
@@ -638,7 +731,9 @@ Future<void> _pump(
             onCreateArea: onCreateArea,
             isMaskPaintingActive: isMaskPaintingActive,
+            isMaskErasingActive: isMaskErasingActive,
             onStartMaskPainting: onStartMaskPainting,
+            onStartMaskErasing: onStartMaskErasing,
```

### `packages/map_editor/test/environment_studio/tile_layer_environment_mask_paint_routing_test.dart`

```diff
@@ -159,6 +159,158 @@ void main() {
+  testWidgets('tap canvas efface un carré 3x3 avec brush size 3',
+      (tester) async {
+    final area = _areaWithActiveMask();
+    final map = MapData(
+      id: 'route_1',
+      name: 'Route 1',
+      size: const GridSize(width: 4, height: 4),
+      layers: <MapLayer>[
+        const TileLayer(
+          id: 'tiles',
+          name: 'Sol',
+          tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
+        ),
+        MapLayer.environment(
+          id: 'env',
+          name: 'Environment',
+          content: EnvironmentLayerContent(
+            targetTileLayerId: 'tiles',
+            areas: [area],
+          ),
+        ),
+      ],
+    );
+    final container = ProviderContainer();
+    addTearDown(container.dispose);
+    container.read(environmentMaskBrushSizeProvider.notifier).state = 3;
+    container.read(editorNotifierProvider.notifier).state = EditorState(
+      projectRootPath: '/tmp/map_editor_env36',
+      project: _manifest(),
+      activeMap: map,
+      activeLayerId: 'tiles',
+      selectedEnvironmentAreaId: area.id,
+      environmentMaskEditMode: EnvironmentMaskEditMode.erase,
+    );
+
+    await tester.binding.setSurfaceSize(const Size(900, 700));
+    addTearDown(() => tester.binding.setSurfaceSize(null));
+    await tester.pumpWidget(
+      UncontrolledProviderScope(
+        container: container,
+        child: MacosTheme(
+          data: MacosThemeData.light(),
+          child: const MaterialApp(
+            home: CupertinoPageScaffold(
+              child: Center(
+                child: SizedBox(
+                  width: 900,
+                  height: 700,
+                  child: MapCanvas(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      ),
+    );
+    await tester.pump();
+    await tester.pump(const Duration(milliseconds: 100));
+
+    final mapBox = tester.getRect(find.byType(MapCanvas));
+    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
+    await tester.pump();
+
+    final state = container.read(editorNotifierProvider);
+    final envLayer =
+        state.activeMap!.layers.whereType<EnvironmentLayer>().single;
+    final erased = envLayer.content.areas.single;
+    expect(state.activeLayerId, 'tiles');
+    expect(state.selectedEnvironmentAreaId, area.id);
+    expect(erased.mask.activeCellCount, 7);
+    expect(erased.mask.isActiveAt(0, 0), isFalse);
+    expect(erased.mask.isActiveAt(1, 1), isFalse);
+    expect(erased.mask.isActiveAt(2, 2), isFalse);
+    expect(erased.mask.isActiveAt(3, 3), isTrue);
+    expect(state.activeMap!.placedElements, isEmpty);
+  });
+
+  testWidgets('tap canvas erase taille 1 efface exactement la cellule centrale',
+      (tester) async {
+    final area = _areaWithActiveMask();
+    final map = MapData(
+      id: 'route_1',
+      name: 'Route 1',
+      size: const GridSize(width: 4, height: 4),
+      layers: <MapLayer>[
+        const TileLayer(
+          id: 'tiles',
+          name: 'Sol',
+          tiles: [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
+        ),
+        MapLayer.environment(
+          id: 'env',
+          name: 'Environment',
+          content: EnvironmentLayerContent(
+            targetTileLayerId: 'tiles',
+            areas: [area],
+          ),
+        ),
+      ],
+    );
+    final container = ProviderContainer();
+    addTearDown(container.dispose);
+    container.read(editorNotifierProvider.notifier).state = EditorState(
+      projectRootPath: '/tmp/map_editor_env36',
+      project: _manifest(),
+      activeMap: map,
+      activeLayerId: 'tiles',
+      selectedEnvironmentAreaId: area.id,
+      environmentMaskEditMode: EnvironmentMaskEditMode.erase,
+    );
+
+    await tester.binding.setSurfaceSize(const Size(900, 700));
+    addTearDown(() => tester.binding.setSurfaceSize(null));
+    await tester.pumpWidget(
+      UncontrolledProviderScope(
+        container: container,
+        child: MacosTheme(
+          data: MacosThemeData.light(),
+          child: const MaterialApp(
+            home: CupertinoPageScaffold(
+              child: Center(
+                child: SizedBox(
+                  width: 900,
+                  height: 700,
+                  child: MapCanvas(),
+                ),
+              ),
+            ),
+          ),
+        ),
+      ),
+    );
+    await tester.pump();
+    await tester.pump(const Duration(milliseconds: 100));
+
+    final mapBox = tester.getRect(find.byType(MapCanvas));
+    await tester.tapAt(mapBox.topLeft + const Offset(48, 48));
+    await tester.pump();
+
+    final state = container.read(editorNotifierProvider);
+    final envLayer =
+        state.activeMap!.layers.whereType<EnvironmentLayer>().single;
+    final erased = envLayer.content.areas.single;
+    expect(state.activeLayerId, 'tiles');
+    expect(state.selectedEnvironmentAreaId, area.id);
+    expect(erased.mask.activeCellCount, 15);
+    expect(erased.mask.isActiveAt(1, 1), isFalse);
+    expect(erased.mask.isActiveAt(1, 0), isTrue);
+    expect(erased.mask.isActiveAt(0, 1), isTrue);
+    expect(state.activeMap!.placedElements, isEmpty);
+  });
@@ -175,6 +327,20 @@ EnvironmentArea _area() {
+EnvironmentArea _areaWithActiveMask() {
+  return EnvironmentArea(
+    id: 'area_forest',
+    name: 'Forêt',
+    presetId: 'forest',
+    mask: EnvironmentAreaMask(
+      width: 4,
+      height: 4,
+      cells: List<bool>.filled(16, true),
+    ),
+    seed: 0,
+  );
+}
```

Le rapport courant n’est pas reproduit dans lui-même : son contenu complet est ce fichier.

## 13. Auto-review

- Le bouton “Effacer du masque” est-il actif seulement quand une area valide existe ? Oui, il dépend de `readModel.canPaintMask`, absence d’erreur, callback fourni, et MapInspectorPanel ne fournit le callback que pour un `TileLayer` actif avec area sélectionnée.
- Le mode erase garde-t-il le TileLayer sélectionné ? Oui, testé dans `tile_layer_environment_erase_mode_test.dart`.
- `selectedEnvironmentAreaId` reste-t-il stable ? Oui, testé au start/stop et dans le routing canvas.
- `environmentMaskEditMode` passe-t-il bien en erase ? Oui.
- Stop remet-il `environmentMaskEditMode` à null ? Oui.
- Erase utilise-t-il la même taille de brush que paint ? Oui, via `environmentMaskBrushSizeProvider`.
- Un erase 3×3 efface-t-il bien un carré 3×3 ? Oui, testé par canvas routing.
- Le clipping bord de map reste-t-il correct ? Oui, couvert par le use case Env-35 en non-régression ; Env-36 ne modifie pas ce use case.
- Aucun `MapPlacedElement` n’est-il créé ? Oui, testé.
- Aucune génération n’est-elle lancée ? Oui, aucun use case generate n’est appelé.
- Le flow legacy reste-t-il intact ? Oui, `environment_layer_mask_brush_tool_test.dart` repasse.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui.

## 14. Critique du prompt et du lot

Clair :

- Le scope erase est petit et bien borné.
- La réutilisation de la brush size Env-35 est explicite.
- La distinction `Effacer du masque` vs `Effacer les placements générés` est utile.

Ambigu :

- Le nom `stopEnvironmentMaskPainting()` devient moins clair avec erase. J’ai conservé le nom pour compatibilité V0.
- Le mode legacy affiche encore la section TileLayer-centric et peut rester confus UX ; ce n’est pas corrigé dans ce lot.

À trancher avant Environment-37 :

- Faut-il renommer progressivement le stop en `stopEnvironmentMaskEditing()` tout en gardant l’alias ?
- Le curseur overlay doit-il refléter paint et erase avec des couleurs différentes ?
- Faut-il masquer ou reformuler les actions TileLayer-centric quand l’`EnvironmentLayer` legacy est sélectionné ?

## 15. Verdict

```text
Environment-36 livré
Code produit modifié : oui
Code UI modifié : oui
Canvas modifié : non
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-37 — TileLayer Environment Brush Cursor Overlay V0
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
- [x] J’ai ajouté uniquement le mode effacement.
- [x] Je n’ai pas ajouté de brush circulaire.
- [x] Je n’ai pas ajouté de preview cursor avancé.
- [x] Je n’ai pas ajouté de génération.
- [x] Je n’ai pas créé d’EnvironmentArea.
- [x] Je n’ai pas créé de MapPlacedElement.
- [x] Le TileLayer reste sélectionné.
- [x] selectedEnvironmentAreaId reste stable.
- [x] Le mode erase utilise la même taille de brush que paint.
- [x] Le flow legacy EnvironmentLayer reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
