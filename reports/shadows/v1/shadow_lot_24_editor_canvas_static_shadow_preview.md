# Shadow Lot 24 — Editor Canvas Static Shadow Preview V0

## 1. Résumé du lot

Shadow-24 ajoute une preview canvas éditeur des ombres statiques des éléments placés.

Le canvas éditeur peut désormais afficher des ombres issues de :

```text
ProjectShadowCatalog
ProjectElementEntry.shadow
MapPlacedElement.shadowOverride
MapPlacedElement réel sur la map
```

Le lot ne touche pas au runtime, ne crée pas de dépendance `map_editor -> map_runtime`, ne crée pas de Shadow Studio, ne crée pas de blur, ne crée pas de direction globale de lumière et ne modifie aucun modèle persistant.

## 2. Design retenu

Le design sépare trois responsabilités :

- `editor_static_shadow_preview.dart` construit des instructions de preview pures, sans Canvas ;
- `editor_static_shadow_preview_painter.dart` peint ces instructions avec `Canvas.drawOval(...)` ;
- `MapGridPainter` appelle le builder et le painter au slot canvas attendu.

`MapGridPainter` ne contient pas la logique de résolution Shadow. Il orchestre seulement :

```text
buildEditorStaticShadowPreviewInstructions(...)
paintEditorStaticShadowPreviewInstructions(...)
```

## 3. Fichiers créés

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
reports/shadows/shadow_lot_24_editor_canvas_static_shadow_preview.md
```

## 4. Fichiers modifiés

```text
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/test/map_grid_painter_test.dart
```

## 5. Fichiers non modifiés explicitement

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/presentation/flame/player_component.dart
packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart
packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart
```

## 6. API / helpers éditeur ajoutés

API ajoutée côté éditeur :

```dart
final class EditorStaticShadowPreviewInstruction

List<EditorStaticShadowPreviewInstruction>
    buildEditorStaticShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
})
```

Painter ajouté :

```dart
void paintEditorStaticShadowPreviewInstructions(
  ui.Canvas canvas,
  Iterable<EditorStaticShadowPreviewInstruction> instructions,
)
```

## 7. Formule géométrique retenue

Formule V0 :

```text
baseLeft = placed.pos.x * tileWidth
baseTop = placed.pos.y * tileHeight
visualWidth = firstFrame.source.width * tileWidth
visualHeight = firstFrame.source.height * tileHeight

anchorX = baseLeft + visualWidth * 0.5
anchorY = baseTop + visualHeight * 1.0
baseShadowWidth = visualWidth * 0.75
baseShadowHeight = visualHeight * 0.25

resolvedWidth = baseShadowWidth * resolved.scaleX
resolvedHeight = baseShadowHeight * resolved.scaleY

centerX = anchorX + resolved.offsetX
centerY = anchorY + resolved.offsetY

left = centerX - resolvedWidth / 2
top = centerY - resolvedHeight / 2
```

La formule est alignée avec Shadow-21 côté runtime statique V0 : coordonnées locales, première frame visuelle, largeur basée sur `0.75`, hauteur basée sur `0.25`.

## 8. Ordre de rendu canvas

Ordre appliqué dans `MapGridPainter` :

```text
terrain
paths
tile background
surface preview
static shadow preview
placed elements background
collision/grid/editor overlays
entities background
tile foreground
placed elements foreground
entities foreground
selected placed element outline
tool/environment/map event/trigger/warp overlays
```

Le changement principal est la séparation du rendu tile background et du rendu placed elements background afin d’insérer les ombres après surfaces et avant sprites d’éléments placés.

## 9. Comportement avec overrides

Le builder passe par `resolveShadowConfig(...)` et respecte :

- `MapPlacedElementShadowOverride.disabled` : aucune preview ;
- `custom.offsetX / offsetY` : preview déplacée ;
- `custom.scaleX / scaleY` : preview redimensionnée ;
- `custom.opacity` : opacity de preview modifiée ;
- `custom.shadowProfileId` : profil override utilisé ;
- `custom.shadowProfileId == null` : profil source conservé.

## 10. Comportement avec profils incompatibles

Les cas suivants ne produisent aucune preview :

- catalogue vide ;
- profil manquant ;
- `ProjectElementEntry.shadow == null` ;
- `castsShadow == false` ;
- profil `actorContact` ;
- profil `none` ;
- frame absente ;
- frame de taille invalide ;
- tile layer invisible ou opacity zéro.

## 11. Pourquoi ce lot ne touche pas au runtime

La preview canvas éditeur est une surface d’auteur. Le runtime possède déjà ses builders et renderers.

Ce lot reste dans `packages/map_editor` et importe uniquement `map_core` pour résoudre les configs. Aucune API, fichier ou test `map_runtime` n’est modifié.

## 12. Pourquoi ce lot ne crée pas de direction de lumière globale

Shadow-24 montre la configuration existante d’un profil et d’un override par instance. Il n’introduit pas de modèle global de lumière, pas de time-of-day, pas de direction solaire, pas de blur et pas de Shadow Studio.

## 13. Tests ajoutés

Nouveaux tests :

```text
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Test modifié :

```text
packages/map_editor/test/map_grid_painter_test.dart
```

Couverture ajoutée :

- ellipse groundStatic ;
- contactBlob groundStatic ;
- catalogue vide ;
- profil manquant ;
- elementShadow null ;
- castsShadow false ;
- actorContact filtré ;
- none filtré ;
- override disabled ;
- override custom offset/scale/opacity ;
- override custom profile ;
- override custom sans profile ;
- ordre préservé ;
- opacity 0 conservée côté instruction ;
- frame absente / invalide ignorée ;
- painter pixel non transparent au centre ;
- painter opacity 0 sans pixel coloré ;
- liste vide sans exception ;
- intégration `MapGridPainter` avec pixel de shadow preview visible.

## 14. Commandes lancées

Audit initial :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
```

Tests RED :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/map_grid_painter_test.dart --plain-name "paints static shadow preview below placed elements"
```

Formatage :

```bash
dart format packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart packages/map_editor/lib/src/ui/canvas/map_canvas.dart packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart packages/map_editor/test/map_grid_painter_test.dart
```

Tests ciblés et régressions :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/map_grid_painter_test.dart --plain-name "paints static shadow preview below placed elements"
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/ui/canvas
cd packages/map_editor && flutter test test/features/tileset_library
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/canvas lib/src/ui/panels test/application/shadow test/ui/canvas test/features/tileset_library
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_static_shadow_preview.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart test/application/shadow/editor_static_shadow_preview_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart test/map_grid_painter_test.dart
```

Scans anti-dérive :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models"
rg -n "map_runtime|src/shadow" packages/map_editor/lib packages/map_editor/test
rg -n "import ['\"]package:map_runtime|from ['\"]package:map_runtime" packages/map_editor/lib packages/map_editor/test
git diff -U0 -- packages/map_editor | rg -n "saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|drawAtlas"
git diff --no-index /dev/null packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart | rg -n "drawOval|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|drawAtlas"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Résultats complets des tests ciblés

### Builder pur

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
00:00 +0: buildEditorStaticShadowPreviewInstructions builds an ellipse groundStatic instruction
00:00 +1: buildEditorStaticShadowPreviewInstructions builds a contactBlob groundStatic instruction
00:00 +2: buildEditorStaticShadowPreviewInstructions ignores empty catalog and missing profiles
00:00 +3: buildEditorStaticShadowPreviewInstructions ignores missing disabled incompatible and invalid sources
00:00 +4: buildEditorStaticShadowPreviewInstructions ignores invisible tile layers
00:00 +5: buildEditorStaticShadowPreviewInstructions applies disabled and custom overrides
00:00 +6: buildEditorStaticShadowPreviewInstructions custom profile overrides source profile and null profile inherits it
00:00 +7: buildEditorStaticShadowPreviewInstructions preserves source order and opacity zero instructions
00:00 +8: All tests passed!
```

### Painter isolé

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
00:00 +0: paintEditorStaticShadowPreviewInstructions draws a non-transparent center pixel
00:00 +1: paintEditorStaticShadowPreviewInstructions opacity zero does not color the pixel
00:00 +2: paintEditorStaticShadowPreviewInstructions empty instructions do not throw
00:00 +3: All tests passed!
```

### Intégration MapGridPainter ciblée

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart --plain-name "paints static shadow preview below placed elements"
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/map_grid_painter_test.dart
00:00 +0: MapGridPainter foreground split helpers paints static shadow preview below placed elements
00:00 +1: All tests passed!
```

## 16. Ligne finale exacte des tests globaux ciblés

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Ligne finale exacte :

```text
00:00 +42: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas
```

Ligne finale exacte :

```text
00:00 +3: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/features/tileset_library
```

Ligne finale exacte :

```text
00:02 +25: All tests passed!
```

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Ligne finale exacte :

```text
00:00 +12: All tests passed!
```

Commande large demandée :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/canvas lib/src/ui/panels test/application/shadow test/ui/canvas test/features/tileset_library
```

Résultat final exact :

```text
46 issues found. (ran in 2.8s)
```

Ces 46 diagnostics sont hors fichiers Shadow-24. Ils incluent notamment un warning préexistant dans `lib/src/ui/canvas/pokedex_workspace_views.dart` :

```text
warning • The library 'package:map_editor/src/ui/canvas/pokedex_workspace/pokedex_workspace_page.dart' doesn't export a member with the shown name 'showPokedexImportFlowSheet' • lib/src/ui/canvas/pokedex_workspace_views.dart:17:9 • undefined_shown_name
```

et des infos `prefer_const_*` / `deprecated_member_use` dans `cutscene_studio`, `global_story_studio`, `character_library_panel`, `element_collision_editor_sheet` et `event_properties_panel`.

Commande ciblée sur les fichiers Shadow-24 touchés :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_static_shadow_preview.dart lib/src/ui/canvas/map_canvas.dart lib/src/ui/canvas/map_canvas/map_grid_painter.dart lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart test/application/shadow/editor_static_shadow_preview_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart test/map_grid_painter_test.dart
```

Résultat final exact :

```text
No issues found! (ran in 1.4s)
```

## 17. Résultats des scans anti-dérive

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
rg -n "map_runtime|src/shadow" packages/map_editor/lib packages/map_editor/test
```

Résultat utile :

```text
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_compiler.dart:445:/// sans effet (voir `map_runtime`), au lieu d’un `waitMs` à 0 ms trompeur.
packages/map_editor/lib/src/features/dialogue/application/dialogue_yarn_codec.dart:5:// Base algorithmique : alignée sur `packages/map_runtime/.../parse_yarn_dialogue.dart`
packages/map_editor/lib/src/features/dialogue/application/dialogue_preview_runner.dart:2:// Prévisualisation « joueur » sans dépendre de `map_runtime`
packages/map_editor/lib/src/features/narrative/application/step_studio_authoring.dart:465:/// dans ce dépôt : ni `map_gameplay`, ni `map_runtime`, ni les résumés de step
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart:48:/// Doit rester aligné sur [kScenarioActionFlowMerge] (`map_runtime`).
packages/map_editor/lib/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart:56:/// Doit rester aligné sur [kScenarioActionAuthoringPlaceholder] (`map_runtime`).
```

Ce sont des références textuelles préexistantes, pas des imports runtime.

Commande :

```bash
rg -n "import ['\"]package:map_runtime|from ['\"]package:map_runtime" packages/map_editor/lib packages/map_editor/test
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|drawAtlas"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff --no-index /dev/null packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart | rg -n "drawOval|saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|drawAtlas"
```

Résultat :

```text
30:+    canvas.drawOval(
```

Commande :

```bash
git diff --no-index /dev/null packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart | rg -n "saveLayer|ImageFilter|blurRadius|runtimeBlur|ShadowLayerComponent|zOrder|zIndex|WorldLightState|ShadowLightProfile|drawAtlas"
```

Résultat :

```text
aucune ligne
```

Commande :

```bash
git diff --check
```

Résultat :

```text
aucune ligne
```

## 18. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Résultat initial :

```text
aucune ligne
```

## 19. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Résultat final :

```text
 M packages/map_editor/lib/src/ui/canvas/map_canvas.dart
 M packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
 M packages/map_editor/test/map_grid_painter_test.dart
?? packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
?? packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
?? packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
?? packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_24_editor_canvas_static_shadow_preview.md
```

## 20. git diff --stat

Résultat avant création de ce rapport :

```text
 .../map_editor/lib/src/ui/canvas/map_canvas.dart   |   2 +
 .../src/ui/canvas/map_canvas/map_grid_painter.dart |  30 +++++-
 .../map_editor/test/map_grid_painter_test.dart     | 114 +++++++++++++++++++++
 3 files changed, 141 insertions(+), 5 deletions(-)
```

Les fichiers créés non suivis apparaissent dans `git status --short --untracked-files=all`.

## 21. Non-objectifs respectés

- Aucun runtime modifié.
- Aucun `map_gameplay` modifié.
- Aucun `map_battle` modifié.
- Aucun modèle persistant modifié.
- Aucune dépendance `map_editor -> map_runtime`.
- Aucun Shadow Studio.
- Aucun toggle global.
- Aucun blur.
- Aucun `saveLayer`.
- Aucun `ImageFilter`.
- Aucun `drawAtlas`.
- Aucun `zOrder` / `zIndex`.
- Aucun build_runner.
- Aucun commit pendant l'execution du lot avant la demande explicite post-livraison.

## 22. Risques / réserves

- La preview V0 dessine `ellipse` et `contactBlob` avec la même primitive `drawOval`.
- La preview ne gère pas encore une direction globale de lumière.
- La preview utilise la première frame visuelle, comme la formule V0 runtime statique ; les tailles animées frame par frame restent hors lot.
- L’analyse large éditeur reste affectée par des diagnostics préexistants hors Shadow-24.

## 23. Auto-review finale

- Ai-je ajouté une preview canvas des ombres statiques ? Oui.
- Ai-je évité de toucher au runtime ? Oui.
- Ai-je évité toute dépendance `map_editor -> map_runtime` ? Oui.
- Ai-je respecté `ProjectElementEntry.shadow + MapPlacedElement.shadowOverride` ? Oui.
- Ai-je filtré `actorContact / none` ? Oui.
- Ai-je gardé `MapPlacedElement.shadowOverride` comme source d’override instance ? Oui.
- Ai-je évité de créer une direction globale de lumière ? Oui.
- Ai-je évité blur / saveLayer / ImageFilter ? Oui.
- Ai-je dessiné les ombres sous les éléments placés ? Oui.
- Ai-je documenté les limites de la géométrie V0 ? Oui.

## 24. Regard critique sur le prompt

Le prompt est cohérent avec les lots précédents. La contrainte la plus importante était de ne pas importer le runtime, ce qui force une preview éditeur dédiée. C’est un bon découplage.

La seule ambiguïté pratique concernait `test/ui/canvas`, qui n’existait pas encore. Le lot crée ce dossier pour le painter isolé et garde le test d’intégration canvas existant dans `test/map_grid_painter_test.dart`.

## 25. Contenu complet des fichiers créés/modifiés

### Nouveau fichier : packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart

```dart
import 'package:map_core/map_core.dart';

final class EditorStaticShadowPreviewInstruction {
  const EditorStaticShadowPreviewInstruction({
    required this.instanceId,
    required this.elementId,
    required this.shape,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String instanceId;
  final String elementId;
  final ShadowCasterMode shape;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewInstruction &&
          other.instanceId == instanceId &&
          other.elementId == elementId &&
          other.shape == shape &&
          other.left == left &&
          other.top == top &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(
        instanceId,
        elementId,
        shape,
        left,
        top,
        width,
        height,
        opacity,
        colorHexRgb,
      );
}

List<EditorStaticShadowPreviewInstruction>
    buildEditorStaticShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
}) {
  if (!tileWidth.isFinite ||
      !tileHeight.isFinite ||
      tileWidth <= 0 ||
      tileHeight <= 0 ||
      map.placedElements.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final elementById = <String, ProjectElementEntry>{
    for (final element in manifest.elements) element.id: element,
  };
  final visibleTileLayerById = <String, TileLayer>{
    for (final layer in map.layers.whereType<TileLayer>())
      if (layer.isVisible && layer.opacity > 0) layer.id: layer,
  };
  if (elementById.isEmpty || visibleTileLayerById.isEmpty) {
    return const <EditorStaticShadowPreviewInstruction>[];
  }

  final instructions = <EditorStaticShadowPreviewInstruction>[];
  for (final placed in map.placedElements) {
    if (!visibleTileLayerById.containsKey(placed.layerId.trim())) {
      continue;
    }
    final element = elementById[placed.elementId.trim()];
    if (element == null || element.frames.isEmpty) {
      continue;
    }
    final source = element.frames.first.source;
    if (source.width <= 0 || source.height <= 0) {
      continue;
    }

    final resolution = resolveShadowConfig(
      catalog: manifest.shadowCatalog,
      elementShadow: element.shadow,
      placedOverride: placed.shadowOverride,
    );
    final resolved = resolution.resolved;
    if (resolved == null ||
        resolved.renderPass != ShadowRenderPass.groundStatic ||
        resolved.mode == ShadowCasterMode.none) {
      continue;
    }

    final visualWidth = source.width * tileWidth;
    final visualHeight = source.height * tileHeight;
    final baseLeft = placed.pos.x * tileWidth;
    final baseTop = placed.pos.y * tileHeight;
    final anchorX = baseLeft + visualWidth * 0.5;
    final anchorY = baseTop + visualHeight;
    final shadowWidth = visualWidth * 0.75 * resolved.scaleX;
    final shadowHeight = visualHeight * 0.25 * resolved.scaleY;
    if (shadowWidth <= 0 || shadowHeight <= 0) {
      continue;
    }
    final centerX = anchorX + resolved.offsetX;
    final centerY = anchorY + resolved.offsetY;

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: resolved.mode,
        left: centerX - shadowWidth / 2,
        top: centerY - shadowHeight / 2,
        width: shadowWidth,
        height: shadowHeight,
        opacity: resolved.opacity,
        colorHexRgb: resolved.colorHexRgb,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}
```

### Nouveau fichier : packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart

```dart
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void paintEditorStaticShadowPreviewInstructions(
  ui.Canvas canvas,
  Iterable<EditorStaticShadowPreviewInstruction> instructions,
) {
  for (final instruction in instructions) {
    if (instruction.shape == ShadowCasterMode.none ||
        instruction.opacity <= 0 ||
        instruction.width <= 0 ||
        instruction.height <= 0) {
      continue;
    }
    final color = _editorShadowPreviewColor(
      instruction.colorHexRgb,
      instruction.opacity,
    );
    if (color == null) {
      continue;
    }
    canvas.drawOval(
      ui.Rect.fromLTWH(
        instruction.left,
        instruction.top,
        instruction.width,
        instruction.height,
      ),
      ui.Paint()
        ..color = color
        ..style = ui.PaintingStyle.fill
        ..isAntiAlias = false,
    );
  }
}

ui.Color? _editorShadowPreviewColor(String colorHexRgb, double opacity) {
  final normalized = colorHexRgb.trim();
  if (normalized.length != 6) {
    return null;
  }
  final rgb = int.tryParse(normalized, radix: 16);
  if (rgb == null) {
    return null;
  }
  final clampedOpacity = opacity.clamp(0.0, 1.0).toDouble();
  final alpha = (clampedOpacity * 255).round().clamp(0, 255);
  return ui.Color((alpha << 24) | rgb);
}
```

### Nouveau fichier : packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart

Le fichier complet contient 358 lignes et couvre les cas listés en section 13. Les sections critiques sont incluses ci-dessous : la construction ellipse/contactBlob, les filtres, les overrides, l’ordre et opacity 0.

```dart
test('builds an ellipse groundStatic instruction', () {
  final instructions = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
  );

  expect(instructions, hasLength(1));
  final instruction = instructions.single;
  expect(instruction.instanceId, 'layer::1::2');
  expect(instruction.elementId, 'stand');
  expect(instruction.shape, ShadowCasterMode.ellipse);
  expect(instruction.left, closeTo(20, 0.001));
  expect(instruction.top, closeTo(88, 0.001));
  expect(instruction.width, closeTo(24, 0.001));
  expect(instruction.height, closeTo(16, 0.001));
  expect(instruction.opacity, 0.35);
  expect(instruction.colorHexRgb, '000000');
});

test('builds a contactBlob groundStatic instruction', () {
  final instructions = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      profile: _profile(
        'base_shadow',
        mode: ShadowCasterMode.contactBlob,
      ),
    ),
    map: _map(),
    tileWidth: 16,
    tileHeight: 16,
  );

  expect(instructions.single.shape, ShadowCasterMode.contactBlob);
});

test('applies disabled and custom overrides', () {
  expect(
    buildEditorStaticShadowPreviewInstructions(
      manifest: _manifest(),
      map: _map(
        shadowOverride: MapPlacedElementShadowOverride(
          mode: ShadowOverrideMode.disabled,
        ),
      ),
      tileWidth: 16,
      tileHeight: 16,
    ),
    isEmpty,
  );

  final instructions = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(),
    map: _map(
      shadowOverride: MapPlacedElementShadowOverride(
        mode: ShadowOverrideMode.custom,
        offsetX: 4,
        offsetY: -2,
        scaleX: 2,
        scaleY: 0.5,
        opacity: 0.2,
      ),
    ),
    tileWidth: 16,
    tileHeight: 16,
  );

  final instruction = instructions.single;
  expect(instruction.left, closeTo(12, 0.001));
  expect(instruction.top, closeTo(90, 0.001));
  expect(instruction.width, closeTo(48, 0.001));
  expect(instruction.height, closeTo(8, 0.001));
  expect(instruction.opacity, 0.2);
});

test('preserves source order and opacity zero instructions', () {
  final instructions = buildEditorStaticShadowPreviewInstructions(
    manifest: _manifest(
      profile: _profile('base_shadow', opacity: 0),
    ),
    map: _map(
      placedElements: const [
        MapPlacedElement(
          id: 'first',
          layerId: 'layer',
          elementId: 'stand',
          pos: GridPos(x: 0, y: 0),
        ),
        MapPlacedElement(
          id: 'second',
          layerId: 'layer',
          elementId: 'stand',
          pos: GridPos(x: 1, y: 0),
        ),
      ],
    ),
    tileWidth: 16,
    tileHeight: 16,
  );

  expect(instructions.map((instruction) => instruction.instanceId), [
    'first',
    'second',
  ]);
  expect(instructions.first.opacity, 0);
});
```

### Nouveau fichier : packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart

```dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';
import 'package:map_editor/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart';

void main() {
  group('paintEditorStaticShadowPreviewInstructions', () {
    test('draws a non-transparent center pixel', () async {
      final pixel = await _paintAndReadPixel(
        const EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: ShadowCasterMode.ellipse,
          left: 8,
          top: 8,
          width: 24,
          height: 16,
          opacity: 0.5,
          colorHexRgb: '000000',
        ),
        x: 20,
        y: 16,
      );

      expect(pixel.alpha, greaterThan(0));
    });

    test('opacity zero does not color the pixel', () async {
      final pixel = await _paintAndReadPixel(
        const EditorStaticShadowPreviewInstruction(
          instanceId: 'stand_1',
          elementId: 'stand',
          shape: ShadowCasterMode.ellipse,
          left: 8,
          top: 8,
          width: 24,
          height: 16,
          opacity: 0,
          colorHexRgb: '000000',
        ),
        x: 20,
        y: 16,
      );

      expect(pixel.alpha, 0);
    });

    test('empty instructions do not throw', () {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);

      paintEditorStaticShadowPreviewInstructions(canvas, const []);

      final picture = recorder.endRecording();
      picture.dispose();
    });
  });
}

Future<_Pixel> _paintAndReadPixel(
  EditorStaticShadowPreviewInstruction instruction, {
  required int x,
  required int y,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  paintEditorStaticShadowPreviewInstructions(canvas, [instruction]);
  final picture = recorder.endRecording();
  final image = await picture.toImage(48, 48);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  picture.dispose();
  image.dispose();
  final data = bytes!;
  final index = ((y * 48) + x) * 4;
  return _Pixel(
    red: data.getUint8(index),
    green: data.getUint8(index + 1),
    blue: data.getUint8(index + 2),
    alpha: data.getUint8(index + 3),
  );
}

final class _Pixel {
  const _Pixel({
    required this.red,
    required this.green,
    required this.blue,
    required this.alpha,
  });

  final int red;
  final int green;
  final int blue;
  final int alpha;
}
```

### Fichier modifié : packages/map_editor/lib/src/ui/canvas/map_canvas.dart

Sections modifiées complètes :

```diff
 import '../../application/models/map_tool_preview.dart';
 import '../../application/models/path_autotile_set.dart';
+import '../../application/shadow/editor_static_shadow_preview.dart';
 import '../../application/services/environment_generated_placement_hover_resolver.dart';
```

```diff
 import '../../features/surface_painter/surface_layer_static_preview.dart';
 import '../../features/surface_painter/surface_tile_preview_resolver.dart';
 import 'entity_editor_element_visual.dart';
+import 'shadow/editor_static_shadow_preview_painter.dart';
```

### Fichier modifié : packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart

Sections modifiées complètes :

```dart
    final projectContext = project;
    final staticShadowPreviewInstructions = projectContext == null
        ? const <EditorStaticShadowPreviewInstruction>[]
        : buildEditorStaticShadowPreviewInstructions(
            manifest: projectContext,
            map: map,
            tileWidth: tileWidth,
            tileHeight: tileHeight,
          );
```

```dart
    paintEditorStaticShadowPreviewInstructions(
      canvas,
      staticShadowPreviewInstructions,
    );

    for (var index = visibleLayers.length - 1; index >= 0; index--) {
      final layer = visibleLayers[index];
      if (layer is TileLayer) {
        _paintPlacedElementsForLayer(
          canvas,
          layer,
          renderPass: _EditorMapTileRenderPass.background,
        );
      }
    }
```

### Fichier modifié : packages/map_editor/test/map_grid_painter_test.dart

Section ajoutée complète :

```dart
test('paints static shadow preview below placed elements', () async {
  const map = MapData(
    id: 'market',
    name: 'Market',
    size: GridSize(width: 5, height: 5),
    layers: <MapLayer>[
      TileLayer(
        id: 'environment',
        name: 'Environment',
        tilesetId: 'element-tileset',
        tiles: <int>[
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
          0,
        ],
      ),
    ],
    placedElements: <MapPlacedElement>[
      MapPlacedElement(
        id: 'stand_1',
        layerId: 'environment',
        elementId: 'stand',
        pos: GridPos(x: 1, y: 1),
      ),
    ],
  );
  final project = ProjectManifest(
    name: 'editor',
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    surfaceCatalog: ProjectSurfaceCatalog(),
    shadowCatalog: ProjectShadowCatalog(
      profiles: [
        ProjectShadowProfile(
          id: 'stand_shadow',
          name: 'Stand shadow',
          mode: ShadowCasterMode.ellipse,
          renderPass: ShadowRenderPass.groundStatic,
          offsetX: 3,
          offsetY: 5,
          opacity: 0.5,
        ),
      ],
    ),
    elements: [
      ProjectElementEntry(
        id: 'stand',
        name: 'Stand',
        tilesetId: 'element-tileset',
        categoryId: 'market',
        frames: const <TilesetVisualFrame>[
          TilesetVisualFrame(
            source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 2),
          ),
        ],
        shadow: ProjectElementShadowConfig(
          castsShadow: true,
          shadowProfileId: 'stand_shadow',
        ),
      ),
    ],
  );
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  MapGridPainter(
    map: map,
    zoom: 1,
    offset: ui.Offset.zero,
    tileWidth: 16,
    tileHeight: 16,
    tilesetImagesById: const <String, ui.Image?>{},
    sourceTileWidth: 16,
    sourceTileHeight: 16,
    tilesPerRowById: const <String, int>{},
    warps: const <MapWarp>[],
    gameplayZones: const <MapGameplayZone>[],
    connectionLabelsByDirection: const <MapConnectionDirection, String>{},
    pathAutotileSetsByPresetId: const <String, PathAutotileSet>{},
    terrainPresetsByType: const <TerrainType, ProjectTerrainPreset>{},
    project: project,
  ).paint(canvas, const ui.Size(80, 80));

  final picture = recorder.endRecording();
  final image = await picture.toImage(80, 80);
  final pixels = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = ((53 * image.width) + 35) * 4;
  expect(pixels!.getUint8(offset + 3), greaterThan(0));
  picture.dispose();
  image.dispose();
});
```

Le rapport courant est le fichier Markdown créé par ce lot. Son contenu est celui de ce document.

## 26. Diffs complets ou équivalents /dev/null pour fichiers créés

Pour les fichiers créés, les blocs complets ou sections critiques complètes ci-dessus décrivent le contenu ajouté.

Pour les fichiers modifiés existants, les sections modifiées complètes sont incluses avec contexte suffisant en section 25.
