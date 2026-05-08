# Environment-46 — TileLayer Individual Generated Placement Ghost Preview V0

## 1. Résumé

Environment-46 ajoute un ghost preview transparent pour le mode TileLayer-centric `Ajouter un élément généré`.

Le preview part maintenant du TileLayer actif, de l’EnvironmentLayer attaché, de l’area sélectionnée et de l’élément de palette sélectionné. Il affiche l’élément réel en transparence quand l’image est disponible, garde un fallback de footprint, distingue un placement valide d’un placement impossible, et ne mute jamais `MapData` au hover.

Deux subagents read-only ont été utilisés comme demandé par Karim pour les lots :
- `Lagrange` : audit canvas / painter / mode / hover.
- `Gibbs` : audit use case d’ajout / validations / helpers partagés.

## 2. Rappel de la décision UX

- Environment Studio reste l’atelier de presets.
- Map Editor / TileLayer inspector reste le lieu de peinture, génération et affinage.
- Ce lot ajoute seulement le ghost preview transparent de l’élément à ajouter.
- Aucun ajout réel supplémentaire n’est ajouté.
- Le clic réel reste géré par le Lot 45.

## 3. Audit de l’existant

Fichiers inspectés :
- `packages/map_core/lib/src/models/environment.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_core/lib/src/models/map_layer.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_editor/lib/src/application/models/tile_layer_environment_attachment_read_model.dart`
- `packages/map_editor/lib/src/application/services/tile_layer_environment_attachment_read_model_builder.dart`
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/application/services/environment_mask_paint_target_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/lib/src/features/editor/state/environment_generated_placement_add_element_provider.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_state.dart`
- `packages/map_editor/lib/src/features/editor/state/editor_notifier.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/panels/map_inspector_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tile_layer_environment_inspector_section.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart`

Constats :
- Un resolver legacy `resolveEnvironmentGeneratedPlacementAddPreview` existait déjà, mais il partait seulement d’un `EnvironmentLayer` actif.
- Ce resolver choisissait le premier item compatible de palette au lieu d’utiliser l’élément sélectionné par `environmentGeneratedPlacementAddElementProvider`.
- Le canvas routait déjà `generatedAdd` au clic vers l’ajout réel, mais le hover preview TileLayer-centric ne pouvait pas être cohérent avec cette sélection.
- `MapGridPainter` savait déjà dessiner un `MapPlacedElement` preview en opacité `0.48` avec footprint cyan.
- Le painter ne portait pas de notion `valid / invalid`.
- Le helper footprint / bounds était dupliqué entre le resolver de hover et le use case d’ajout.
- Le use case d’ajout réel suffixait les ids en cas de collision, mais le resolver preview retournait `null` si l’id stable existait déjà.

## 4. Resolver de preview

Nom modifié :

```dart
resolveEnvironmentGeneratedPlacementAddPreview
```

Entrées ajoutées :
- `selectedElementId`

Sortie enrichie :

```dart
EnvironmentGeneratedPlacementAddPreview
- placed
- element
- footprint
- isValid
- invalidReason
```

Validations :
- résout `activeLayerId` comme EnvironmentLayer actif ou TileLayer avec EnvironmentLayer attaché ;
- exige une area sélectionnée ;
- exige `area.generatedPlacementIds.isNotEmpty` pour rester dans le fine-tuning post-génération ;
- résout le preset ;
- utilise l’élément sélectionné si fourni ;
- autorise la sélection implicite seulement s’il reste un seul item palette valide ;
- retourne `null` si plusieurs items valides existent sans sélection ;
- retourne `null` si l’élément sélectionné est absent de la palette ou du manifest ;
- calcule le footprint depuis `ProjectElementEntry.frames.primarySource` ;
- retourne un preview invalide avec `invalidReason: Position hors carte` si le footprint sort de la map ;
- utilise le helper d’id unique pour rester cohérent avec l’ajout réel ;
- ne fait aucun `map.copyWith`.

Helpers extraits / partagés :
- `environmentGeneratedPlacementElementFootprint`
- `isEnvironmentGeneratedPlacementFootprintInBounds`
- `uniqueGeneratedEnvironmentPlacementId`

`AddTileLayerEnvironmentGeneratedPlacementAtUseCase` réutilise maintenant ces helpers. Sa sémantique d’ajout n’a pas changé.

## 5. Canvas / hover

`MapCanvas` lit maintenant :

```dart
environmentGeneratedPlacementAddElementProvider
```

Quand :

```text
environmentMaskEditMode == EnvironmentMaskEditMode.generatedAdd
_hoveredTile != null
state.project != null
```

il construit un `EnvironmentGeneratedPlacementAddPreview` avec :
- la map active ;
- le manifest ;
- le TileLayer actif ;
- l’area sélectionnée ;
- l’élément sélectionné ;
- la cellule hover.

Le hover génère seulement un DTO de preview. Il ne modifie pas :
- `MapData` ;
- `activeLayerId` ;
- `selectedEnvironmentAreaId` ;
- `environmentMaskEditMode` ;
- `generatedPlacementIds`.

Quand le pointeur sort du canvas, `_hoveredTile` repasse à `null` et le preview disparaît.

Le hover tile générique est masqué pendant `generatedAdd` pour éviter deux previews superposées.

## 6. Painter / rendu

`MapGridPainter.environmentGeneratedAddPreview` reçoit maintenant le modèle complet `EnvironmentGeneratedPlacementAddPreview`.

Rendu :
- placement valide : sprite réel en opacité `0.52`, footprint cyan discret ;
- placement invalide : sprite en opacité `0.34`, footprint orange ;
- image tileset absente : `_paintPlacedElement` ne dessine pas de sprite, mais le footprint reste visible ;
- `shouldRepaint` reste déclenché quand le ghost preview change.

Le rendu existant des placements générés, du delete hover et du clic réel n’est pas modifié.

## 7. Tests

RED vérifié :

```bash
cd packages/map_editor && dart format test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart && flutter test test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart
```

Résultat RED attendu :

```text
Error: No named parameter with the name 'selectedElementId'.
00:00 +0 -1: Some tests failed.
```

Échec intermédiaire documenté :

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_preview_canvas_test.dart
```

Résultat avant création du fichier dédié :

```text
Failed to load ".../tile_layer_environment_individual_add_preview_canvas_test.dart": Does not exist.
00:00 +0 -1: Some tests failed.
```

Commandes finales lancées :

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart
```

```text
00:00 +7: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_preview_painter_test.dart
```

```text
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_preview_canvas_test.dart
```

```text
00:00 +1: All tests passed!
```

Non-régressions :

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_use_case_test.dart
```

```text
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_notifier_test.dart
```

```text
00:00 +5: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart
```

```text
00:00 +2: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_individual_delete_canvas_test.dart
```

```text
00:00 +3: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/environment_generated_placement_hover_preview_test.dart
```

```text
00:00 +4: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/tile_layer_environment_inspector_section_test.dart
```

```text
00:01 +53: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/environment_studio/environment_golden_slice_workflow_test.dart
```

```text
00:00 +6: All tests passed!
```

Cas couverts :
- preview valide depuis TileLayer actif ;
- élément sélectionné respecté ;
- élément implicite si un seul item valide ;
- absence de preview si sélection implicite ambiguë ;
- élément absent de palette ;
- élément absent du manifest ;
- footprint 1x1 ;
- footprint 2x2 ;
- footprint hors bounds rendu comme preview invalide ;
- hover canvas sans mutation `MapData` ;
- disparition du preview hors canvas ;
- painter valide / invalide / image absente / null ;
- `shouldRepaint` sur changement de ghost.

## 8. Analyse ciblée

Commande lancée :

```bash
cd packages/map_editor && flutter analyze lib/src/application/services/environment_generated_placement_hover_resolver.dart lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart test/environment_studio/tile_layer_environment_individual_add_preview_painter_test.dart test/environment_studio/tile_layer_environment_individual_add_preview_canvas_test.dart test/environment_studio/tile_layer_environment_individual_add_canvas_test.dart test/environment_studio/environment_generated_placement_hover_preview_test.dart
```

Résultat :

```text
Analyzing 9 items...
No issues found! (ran in 1.7s)
```

Aucune dette préexistante hors lot n’a bloqué l’analyse ciblée.

## 9. Fichiers créés/modifiés

Fichiers créés par Environment-46 :
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_painter_test.dart`
- `packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_canvas_test.dart`
- `reports/environment_studio/environment_46_tile_layer_individual_generated_placement_ghost_preview.md`

Fichiers modifiés par Environment-46 :
- `packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart`
- `packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart`

Fichiers préexistants dans le worktree non touchés :
- Aucun au `git status` initial.

## 10. Non-objectifs respectés

- Pas d’ajout réel supplémentaire.
- Pas de génération complète.
- Pas de clear global.
- Pas de regenerate.
- Pas de shuffle.
- Pas de preview de génération complète.
- Pas de modification du mask.
- Pas de modification des params.
- Pas de modification du preset global.
- Pas de création/suppression/renommage d’area.
- Pas de modification de `map_core`.
- Pas de modification runtime.
- Pas de modification gameplay.
- Pas de modification battle.
- Pas de build_runner.
- Pas de generated files.

## 11. Evidence pack

Git status initial :

```bash
git status --short --untracked-files=all
```

Résultat :

```text

```

Diff stat :

```bash
git diff --stat
```

Résultat :

```text
 ...ronment_generated_placement_hover_resolver.dart | 179 +++++++++++++++------
 ...ronment_generated_placement_edit_use_cases.dart |  48 +-----
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |  10 +-
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  13 +-
 ...ent_generated_placement_hover_preview_test.dart |   7 +-
 5 files changed, 156 insertions(+), 101 deletions(-)
```

Diff name-only :

```bash
git diff --name-only
```

Résultat :

```text
packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
```

Fichiers non suivis créés par le lot :

```bash
git ls-files --others --exclude-standard
```

Résultat :

```text
packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_canvas_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_painter_test.dart
packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart
```

Git diff check :

```bash
git diff --check
```

Résultat :

```text

```

Git status final :

```bash
git status --short --untracked-files=all
```

Résultat :

```text
 M packages/map_editor/lib/src/application/services/environment_generated_placement_hover_resolver.dart
 M packages/map_editor/lib/src/application/use_cases/tile_layer_environment_generated_placement_edit_use_cases.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/environment_studio/environment_generated_placement_hover_preview_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_canvas_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_painter_test.dart
?? packages/map_editor/test/environment_studio/tile_layer_environment_individual_add_preview_resolver_test.dart
?? reports/environment_studio/environment_46_tile_layer_individual_generated_placement_ghost_preview.md
```

## 12. Diff pertinent

### `environment_generated_placement_hover_resolver.dart`

```diff
+  final GridSize footprint;
+  final bool isValid;
+  final String? invalidReason;
...
+  String? selectedElementId,
...
-  final envLayer = _activeEnvironmentLayer(map, activeLayerId);
+  final envLayer = _activeOrAttachedEnvironmentLayer(map, activeLayerId);
...
+  if (area.generatedPlacementIds.isEmpty) return null;
...
+  final selection = _resolveAddPreviewPaletteSelection(
+    manifest: manifest,
+    preset: preset,
+    selectedElementId: selectedElementId,
+    targetTilesetId: targetTilesetId,
+  );
...
+  final isInBounds = isEnvironmentGeneratedPlacementFootprintInBounds(
+    pos: pos,
+    footprint: footprint,
+    mapSize: map.size,
+  );
...
+  final placedId = uniqueGeneratedEnvironmentPlacementId(
+    map,
+    area: area,
+    pos: pos,
+    elementId: selection.item.elementId,
+  );
...
+    footprint: footprint,
+    isValid: isInBounds && isCompatible,
+    invalidReason: !isCompatible
+        ? 'Élément incompatible avec ce layer'
+        : !isInBounds
+            ? 'Position hors carte'
+            : null,
```

### `tile_layer_environment_generated_placement_edit_use_cases.dart`

```diff
-    final footprint = _elementFootprint(element);
-    if (!_elementFootprintInBounds(
+    final footprint = environmentGeneratedPlacementElementFootprint(element);
+    if (!isEnvironmentGeneratedPlacementFootprintInBounds(
...
-    final placedId = _uniqueGeneratedEnvironmentPlacementId(
+    final placedId = uniqueGeneratedEnvironmentPlacementId(
```

Les helpers privés équivalents ont été retirés du use case après extraction dans le resolver applicatif partagé.

### `map_canvas.dart`

```diff
+import '../../features/editor/state/environment_generated_placement_add_element_provider.dart';
...
+    final selectedGeneratedPlacementElementId =
+        ref.watch(environmentGeneratedPlacementAddElementProvider);
...
+                        selectedElementId: selectedGeneratedPlacementElementId,
...
-                          hoveredTile: environmentBrushCursorOverlay == null
+                          hoveredTile: environmentBrushCursorOverlay == null &&
+                                  state.environmentMaskEditMode !=
+                                      EnvironmentMaskEditMode.generatedAdd
...
-                              environmentGeneratedAddPreview?.placed,
+                              environmentGeneratedAddPreview,
```

### `map_grid_painter.dart`

```diff
-  final MapPlacedElement? environmentGeneratedAddPreview;
+  final EnvironmentGeneratedPlacementAddPreview? environmentGeneratedAddPreview;
...
+    final placed = preview.placed;
...
-      preview,
+      placed,
...
-      opacity: 0.48,
+      opacity: preview.isValid ? 0.52 : 0.34,
...
-      color: Colors.cyanAccent,
-      fillAlpha: 0.08,
+      color: preview.isValid ? Colors.cyanAccent : Colors.deepOrangeAccent,
+      fillAlpha: preview.isValid ? 0.08 : 0.14,
```

### `environment_generated_placement_hover_preview_test.dart`

```diff
-    test('does not preview add when the element footprint leaves the map', () {
+    test('previews add as invalid when the element footprint leaves the map',
+        () {
...
-      expect(preview, isNull);
+      expect(preview, isNotNull);
+      expect(preview!.isValid, isFalse);
+      expect(preview.invalidReason, contains('Position hors carte'));
```

### Nouveaux tests

`tile_layer_environment_individual_add_preview_resolver_test.dart` ajoute les assertions suivantes :

```dart
expect(preview!.isValid, isTrue);
expect(preview.placed.layerId, 'tiles');
expect(preview.placed.elementId, 'bush');
expect(preview.footprint, const GridSize(width: 1, height: 1));
expect(preview, isNull);
expect(preview!.isValid, isFalse);
expect(preview.invalidReason, contains('Position hors carte'));
expect(ctx.map.placedElements, beforePlaced);
```

`tile_layer_environment_individual_add_preview_painter_test.dart` couvre :

```dart
await _paint(preview, images: {'nature': await _tilesetImage()});
await _paint(preview, images: const <String, ui.Image?>{});
expect(second.shouldRepaint(first), isTrue);
await _paint(null, images: const <String, ui.Image?>{});
```

`tile_layer_environment_individual_add_preview_canvas_test.dart` couvre :

```dart
expect(painter.environmentGeneratedAddPreview, isNotNull);
expect(painter.environmentGeneratedAddPreview!.placed.elementId, 'big_tree');
expect(painter.environmentGeneratedAddPreview!.placed.pos, const GridPos(x: 1, y: 1));
expect(painter.environmentGeneratedAddPreview!.isValid, isTrue);
expect(container.read(editorNotifierProvider).activeMap, same(map));
expect(exitedPainter.environmentGeneratedAddPreview, isNull);
```

Les helpers de fixtures dans ces nouveaux tests construisent uniquement des `MapData`, `ProjectManifest`, `EnvironmentPreset` et `ProjectElementEntry` minimaux pour exercer les assertions ci-dessus.

## 13. Auto-review

- Le ghost preview apparaît-il seulement en mode generatedAdd ? Oui, construit par `MapCanvas` seulement dans le switch `EnvironmentMaskEditMode.generatedAdd`.
- Le ghost preview utilise-t-il l’élément sélectionné ? Oui, via `environmentGeneratedPlacementAddElementProvider` passé au resolver.
- Le ghost preview utilise-t-il le footprint réel ? Oui, via `environmentGeneratedPlacementElementFootprint`.
- Le preview valide/invalide est-il distinguable ? Oui, `isValid` et `invalidReason`, rendu cyan ou orange.
- L’image réelle est-elle utilisée si disponible ? Oui, `_paintPlacedElement` réutilise `tilesetImagesById`.
- Le fallback fonctionne-t-il si l’image est absente ? Oui, le painter garde le footprint même si le sprite n’est pas résolu.
- Hover ne mute-t-il pas MapData ? Oui, couvert par tests resolver et canvas.
- Clic réel reste-t-il géré par le Lot 45 ? Oui, `onTapUp` continue d’appeler `notifier.addGeneratedEnvironmentPlacementAt(gridPos)`.
- Le flow delete reste-t-il intact ? Oui, test `tile_layer_environment_individual_delete_canvas_test.dart` passe.
- Le flow legacy reste-t-il intact ? Oui, `environment_generated_placement_hover_preview_test.dart` passe avec le nouveau contrat invalide hors bounds.
- Les tests ciblés passent-ils ? Oui.
- L’analyse ciblée passe-t-elle ? Oui.
- Aucun commit n’a-t-il été fait ? Oui, aucun commit fait dans Environment-46.

## 14. Critique du prompt et du lot

Clair :
- le scope est strictement limité au ghost preview ;
- le preview doit partir de la même source que l’ajout réel ;
- l’invalidité hors carte doit être lisible ;
- le hover ne doit jamais muter `MapData`.

Ambigu :
- le prompt autorise `null` ou invalide pour élément absent de palette / manifest ; V0 choisit `null` pour éviter un ghost mensonger sans élément résolvable.
- l’invalidité tileset mismatch explicite est représentée si l’élément est sélectionné, mais les sélections implicites filtrent les items incompatibles.

À trancher avant Environment-47 :
- conserver le prochain lot `Hide / Group Technical EnvironmentLayer V0` ou ajouter d’abord un tooltip / label textuel sur le ghost invalide pour afficher `invalidReason` dans l’UI.

## 15. Verdict

```text
Environment-46 livré
Code produit modifié : oui
Code UI/canvas modifié : oui
Tests ciblés : pass
Analyze ciblé : pass
Prochain lot recommandé : Environment-47 — Hide / Group Technical EnvironmentLayer V0
```

## Checklist finale

- [x] Je n’ai fait aucun commit.
- [x] Je n’ai pas utilisé git add.
- [x] Je n’ai pas utilisé git reset/restore/checkout/stash.
- [x] Je n’ai pas lancé build_runner.
- [x] Je n’ai modifié aucun generated file.
- [x] Je n’ai pas modifié map_core.
- [x] Je n’ai pas modifié runtime/gameplay/battle.
- [x] J’ai ajouté uniquement le ghost preview d’ajout.
- [x] Je n’ai pas ajouté de nouvelle action d’ajout.
- [x] Je n’ai pas lancé de génération complète.
- [x] Je n’ai pas modifié le mask.
- [x] Je n’ai pas modifié les params locaux.
- [x] Je n’ai pas modifié le preset global.
- [x] Je n’ai pas créé/supprimé/renommé d’area.
- [x] Hover ne mute pas MapData.
- [x] Le clic réel reste géré par le Lot 45.
- [x] Le flow legacy reste intact.
- [x] Les tests ciblés passent.
- [x] L’analyse ciblée est documentée.
- [x] Le rapport distingue les fichiers préexistants des fichiers du lot.
