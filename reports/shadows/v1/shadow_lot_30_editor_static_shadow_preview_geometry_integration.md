# Shadow-30 - Editor Static Shadow Preview Geometry Integration V0

## 1. Resume du lot

Shadow-30 branche la preview canvas editor des ombres statiques sur la geometrie commune `map_core` ajoutee par Shadow-28.

Le builder editor `buildEditorStaticShadowPreviewInstructions(...)` ne maintient plus sa formule locale `anchorX / anchorY / width / height`. Il calcule toujours les metriques visuelles editor (`baseLeft`, `baseTop`, `visualWidth`, `visualHeight`), puis appelle `resolveStaticShadowGeometry(...)` avec :

- `StaticShadowVisualMetrics`
- `ResolvedShadowConfig`
- `ProjectElementShadowConfig.footprint`
- `MapPlacedElementShadowOverride.footprint`

Le mapping editor utilise directement `geometry.left`, `geometry.top`, `geometry.width`, `geometry.height`.

Aucun runtime n'a ete modifie. Aucun modele persistant ou codec core n'a ete modifie. Aucun panel/state editor n'a ete modifie. Aucun painter n'a ete modifie.

## 2. Design retenu

Design valide et applique :

- integration directe dans `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart` ;
- conservation des filtres existants : profil manquant, layer invisible, frame invalide, `renderPass != groundStatic`, `mode == none` ;
- conservation du calcul editor de base : `baseLeft`, `baseTop`, `visualWidth`, `visualHeight` ;
- appel a `resolveStaticShadowGeometry(...)` ;
- transmission de `element.shadow?.footprint` ;
- transmission de `placed.shadowOverride?.footprint` ;
- mapping final depuis `ResolvedStaticShadowGeometry`.

Approches rejetees :

- modifier `MapGridPainter` : l'ordre de rendu Shadow-24 est deja correct ;
- modifier le painter Shadow : le dessin `drawOval` est hors du probleme Shadow-30 ;
- creer un helper editor supplementaire : inutile pour ce remplacement localise ;
- importer `map_runtime` : interdit par l'architecture et inutile.

## 3. Fichiers crees

- `reports/shadows/shadow_lot_30_editor_static_shadow_preview_geometry_integration.md`

## 4. Fichiers modifies

- `packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart`
- `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart`

## 5. Fichiers non modifies explicitement

Non modifies :

- `packages/map_runtime/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `packages/map_core/lib/src/models/**`
- `packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart`
- `packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart`
- `packages/map_editor/lib/src/ui/panels/**`
- `packages/map_editor/lib/src/features/editor/state/**`
- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`

## 6. Integration de resolveStaticShadowGeometry cote editor

Avant Shadow-30, le builder editor calculait localement :

```text
anchorX = baseLeft + visualWidth * 0.5
anchorY = baseTop + visualHeight
shadowWidth = visualWidth * 0.75 * resolved.scaleX
shadowHeight = visualHeight * 0.25 * resolved.scaleY
centerX = anchorX + resolved.offsetX
centerY = anchorY + resolved.offsetY
```

Apres Shadow-30, le builder calcule :

```dart
final geometry = resolveStaticShadowGeometry(
  metrics: StaticShadowVisualMetrics(
    left: baseLeft,
    top: baseTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
  ),
  shadowConfig: resolved,
  elementFootprint: element.shadow?.footprint,
  overrideFootprint: placed.shadowOverride?.footprint,
);
```

Puis :

```dart
left: geometry.left,
top: geometry.top,
width: geometry.width,
height: geometry.height,
```

## 7. Transmission elementFootprint / overrideFootprint

Le builder transmet :

- `elementFootprint: element.shadow?.footprint`
- `overrideFootprint: placed.shadowOverride?.footprint`

Les regles de merge restent celles de `map_core` :

- defaults V0 ;
- puis footprint element champ par champ ;
- puis footprint override champ par champ.

## 8. Compatibilite sans footprint

Le test existant `builds an ellipse groundStatic instruction` garde les valeurs Shadow-24 :

```text
left = 20
top = 88
width = 24
height = 16
```

Ces valeurs prouvent que l'absence de footprint conserve la preview precedente.

## 9. Protection contre double offset/scale

Le test `custom override without footprint keeps element footprint` combine :

- un footprint element ;
- `offsetX: 4`
- `offsetY: -2`
- `scaleX: 2`
- `scaleY: 0.5`

Resultat attendu :

```text
left = 20
top = 54
width = 32
height = 16
```

Ces valeurs correspondent a une application unique de `offsetX / offsetY` et `scaleX / scaleY` par la geometrie core.

## 10. Pourquoi ce lot ne touche pas runtime

Shadow-29 a deja branche le runtime sur `resolveStaticShadowGeometry(...)`. Shadow-30 aligne uniquement l'editor preview sur la meme operation core. Modifier le runtime dans ce lot aurait melange deux surfaces deja separees et aurait augmente le risque sans besoin produit.

## 11. Pourquoi ce lot ne touche pas UI/panels/state

La configuration des footprints existe deja dans les modeles core depuis Shadow-27. Shadow-30 ne cree pas d'UI footprint et ne modifie aucun flux d'edition. Le travail se limite au builder de preview canvas.

## 12. Pourquoi ce lot ne change pas l'ordre de rendu canvas

L'ordre de rendu a ete pose par Shadow-24 :

```text
sol / surfaces -> static shadow preview -> placed elements -> overlays
```

Shadow-30 ne modifie pas `MapGridPainter` et ne change pas le painter. Le test `paints static shadow preview below placed elements` reste vert.

## 13. Tests ajoutes/modifies

Ajout dans `packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart` :

- `uses element footprint for preview anchor and size`
- `uses override footprint over element footprint field by field`
- `custom override without footprint keeps element footprint`

Ces tests couvrent :

- footprint element ;
- footprint override ;
- merge partiel champ par champ ;
- custom override sans footprint ;
- offset/scale appliques une seule fois.

## 14. Commandes lancees

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print

cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_editor && flutter test test/ui/canvas
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_static_shadow_preview.dart test/application/shadow/editor_static_shadow_preview_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart test/map_grid_painter_test.dart

cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow

cd /Users/karim/Project/pokemonProject
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/panels|packages/map_editor/lib/src/features/editor/state"
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
git diff --check
git diff --stat
git diff --name-status
git status --short --untracked-files=all
```

## 15. Resultats complets des tests cibles

### RED - editor_static_shadow_preview_test avant implementation

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Sortie utile complete :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
00:00 +0: buildEditorStaticShadowPreviewInstructions builds an ellipse groundStatic instruction
00:00 +1: buildEditorStaticShadowPreviewInstructions builds a contactBlob groundStatic instruction
00:00 +2: buildEditorStaticShadowPreviewInstructions ignores empty catalog and missing profiles
00:00 +3: buildEditorStaticShadowPreviewInstructions ignores missing disabled incompatible and invalid sources
00:00 +4: buildEditorStaticShadowPreviewInstructions ignores invisible tile layers
00:00 +5: buildEditorStaticShadowPreviewInstructions applies disabled and custom overrides
00:00 +6: buildEditorStaticShadowPreviewInstructions uses element footprint for preview anchor and size
00:00 +6 -1: buildEditorStaticShadowPreviewInstructions uses element footprint for preview anchor and size [E]
  Expected: a numeric value within <0.001> of <16>
    Actual: <20.0>
     Which:  differs by <4.0>

  package:matcher                                                       expect
  package:flutter_test/src/widget_tester.dart 473:18                    expect
  test/application/shadow/editor_static_shadow_preview_test.dart 213:7  main.<fn>.<fn>

00:00 +6 -1: buildEditorStaticShadowPreviewInstructions uses override footprint over element footprint field by field
00:00 +6 -2: buildEditorStaticShadowPreviewInstructions uses override footprint over element footprint field by field [E]
  Expected: a numeric value within <0.001> of <60>
    Actual: <88.0>
     Which:  differs by <28.0>

  package:matcher                                                       expect
  package:flutter_test/src/widget_tester.dart 473:18                    expect
  test/application/shadow/editor_static_shadow_preview_test.dart 248:7  main.<fn>.<fn>

00:00 +6 -2: buildEditorStaticShadowPreviewInstructions custom override without footprint keeps element footprint
00:00 +6 -3: buildEditorStaticShadowPreviewInstructions custom override without footprint keeps element footprint [E]
  Expected: a numeric value within <0.001> of <20>
    Actual: <12.0>
     Which:  differs by <8.0>

  package:matcher                                                       expect
  package:flutter_test/src/widget_tester.dart 473:18                    expect
  test/application/shadow/editor_static_shadow_preview_test.dart 281:7  main.<fn>.<fn>

00:00 +6 -3: buildEditorStaticShadowPreviewInstructions custom profile overrides source profile and null profile inherits it
00:00 +7 -3: buildEditorStaticShadowPreviewInstructions preserves source order and opacity zero instructions
00:00 +8 -3: Some tests failed.
```

### GREEN - editor_static_shadow_preview_test apres implementation

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Sortie complete :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
00:00 +0: buildEditorStaticShadowPreviewInstructions builds an ellipse groundStatic instruction
00:00 +1: buildEditorStaticShadowPreviewInstructions builds a contactBlob groundStatic instruction
00:00 +2: buildEditorStaticShadowPreviewInstructions ignores empty catalog and missing profiles
00:00 +3: buildEditorStaticShadowPreviewInstructions ignores missing disabled incompatible and invalid sources
00:00 +4: buildEditorStaticShadowPreviewInstructions ignores invisible tile layers
00:00 +5: buildEditorStaticShadowPreviewInstructions applies disabled and custom overrides
00:00 +6: buildEditorStaticShadowPreviewInstructions uses element footprint for preview anchor and size
00:00 +7: buildEditorStaticShadowPreviewInstructions uses override footprint over element footprint field by field
00:00 +8: buildEditorStaticShadowPreviewInstructions custom override without footprint keeps element footprint
00:00 +9: buildEditorStaticShadowPreviewInstructions custom profile overrides source profile and null profile inherits it
00:00 +10: buildEditorStaticShadowPreviewInstructions preserves source order and opacity zero instructions
00:00 +11: All tests passed!
```

### editor_static_shadow_preview_painter_test

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Sortie complete :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
00:00 +0: paintEditorStaticShadowPreviewInstructions draws a non-transparent center pixel
00:00 +1: paintEditorStaticShadowPreviewInstructions opacity zero does not color the pixel
00:00 +2: paintEditorStaticShadowPreviewInstructions empty instructions do not throw
00:00 +3: All tests passed!
```

### map_grid_painter_test

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Sortie complete :

```text
Waiting for another flutter command to release the startup lock...
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/map_grid_painter_test.dart
00:00 +0: MapGridPainter foreground split helpers marks only non-collision cells of multi-tile placed elements as foreground
00:00 +1: MapGridPainter foreground split helpers routes split cells to the correct render pass deterministically
00:00 +2: MapGridPainter foreground split helpers routes project-element entities to the requested render pass
00:00 +3: MapGridPainter foreground split helpers paints SurfaceLayer static preview without atlas tile images
00:00 +4: MapGridPainter foreground split helpers paints SurfaceLayer with resolved atlas tile image when available
00:00 +5: MapGridPainter foreground split helpers paints placed elements even when their TileLayer has no tiles
00:00 +6: MapGridPainter foreground split helpers paints static shadow preview below placed elements
00:00 +7: MapGridPainter foreground split helpers does not double-paint matching baked tiles under translucent elements
00:00 +8: MapGridPainter foreground split helpers keeps non-matching base tiles visible under translucent elements
00:00 +9: MapGridPainter foreground split helpers delete preview highlights sprite without footprint rectangle
00:00 +10: MapGridPainter foreground split helpers paints SurfaceLayer atlas tile from current editor elapsed time
00:00 +11: MapGridPainter foreground split helpers paints path layer with center-only 2x2 PathPattern in canvas
00:00 +12: All tests passed!
```

### static_shadow_geometry_test

Commande :

```bash
cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
```

Sortie complete :

```text
00:00 +0: loading test/shadow/static_shadow_geometry_test.dart
00:00 +0: StaticShadowVisualMetrics accepts valid metrics
00:00 +1: StaticShadowVisualMetrics rejects non-finite left and top
00:00 +2: StaticShadowVisualMetrics rejects invalid visual sizes
00:00 +3: StaticShadowVisualMetrics equality and hashCode include all fields
00:00 +4: ResolvedStaticShadowFootprint defaults match current V0 ratios
00:00 +5: ResolvedStaticShadowFootprint element footprint overrides defaults field by field
00:00 +6: ResolvedStaticShadowFootprint override footprint wins over element footprint field by field
00:00 +7: ResolvedStaticShadowFootprint rejects invalid direct resolved ratios
00:00 +8: ResolvedStaticShadowFootprint equality and hashCode include all fields
00:00 +9: resolveStaticShadowGeometry without footprint reproduces current V0 formula
00:00 +10: resolveStaticShadowGeometry element footprint changes anchor and footprint size
00:00 +11: resolveStaticShadowGeometry override footprint wins while partial override keeps element fields
00:00 +12: resolveStaticShadowGeometry offset and scale apply after footprint
00:00 +13: resolveStaticShadowGeometry mode renderPass opacity color and softness do not affect geometry
00:00 +14: resolveStaticShadowGeometry rejects invalid direct geometry values
00:00 +15: resolveStaticShadowGeometry equality and hashCode include all fields
00:00 +16: static shadow geometry integration with existing configs ProjectElementShadowConfig footprint can be passed directly
00:00 +17: static shadow geometry integration with existing configs MapPlacedElementShadowOverride footprint can be passed directly
00:00 +18: static shadow geometry integration with existing configs custom override with null footprint uses element or default footprint
00:00 +19: All tests passed!
```

## 16. Ligne finale exacte des tests globaux cibles

### test/application/shadow

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

Resultat : succes.

Ligne finale exacte :

```text
00:00 +51: All tests passed!
```

### test/ui/canvas

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas
```

Resultat : succes.

Ligne finale exacte :

```text
00:00 +3: All tests passed!
```

### map_core test/shadow

Commande :

```bash
cd packages/map_core && dart test test/shadow
```

Resultat : succes.

Ligne finale exacte :

```text
00:01 +204: All tests passed!
```

## 17. Resultats analyse

### map_editor analyse ciblee

Commande :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_static_shadow_preview.dart test/application/shadow/editor_static_shadow_preview_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart test/map_grid_painter_test.dart
```

Sortie complete :

```text
Analyzing 4 items...
No issues found! (ran in 2.3s)
```

### map_core analyse shadow

Commande :

```bash
cd packages/map_core && dart analyze lib test/shadow
```

Sortie complete :

```text
Analyzing lib, shadow...
No issues found!
```

## 18. Resultats des scans anti-derive

### AGENTS.md

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Seul `../pokemonProject/AGENTS.md` s'applique au repo courant.

### Diff-only runtime/gameplay/battle interdits

Commande :

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Resultat : aucune sortie, exit code 1 de `rg`.

### Diff-only core models/codecs interdits

Commande :

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Resultat : aucune sortie, exit code 1 de `rg`.

### Diff-only UI panels/state interdits

Commande :

```bash
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/panels|packages/map_editor/lib/src/features/editor/state"
```

Resultat : aucune sortie, exit code 1 de `rg`.

### Renderer avance interdit

Commande :

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Resultat : aucune sortie, exit code 1 de `rg`.

### Import runtime dans editor interdit

Commande :

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Resultat : aucune sortie, exit code 1 de `rg`.

### Whitespace

Commande :

```bash
git diff --check
```

Resultat : aucune sortie, exit code 0.

## 19. git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Sortie avant implementation Shadow-30 :

```text
```

Le worktree etait propre apres le commit/push Shadow-29.

## 20. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie avant ajout du rapport :

```text
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Sortie finale observee apres ajout de ce rapport :

```text
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
?? reports/shadows/shadow_lot_30_editor_static_shadow_preview_geometry_integration.md
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale observee pour les modifications suivies par `git diff` :

```text
 .../shadow/editor_static_shadow_preview.dart       | 28 ++++---
 .../shadow/editor_static_shadow_preview_test.dart  | 94 ++++++++++++++++++++++
 2 files changed, 109 insertions(+), 13 deletions(-)
```

## 22. Non-objectifs respectes

- Aucun runtime modifie.
- Aucun gameplay/battle modifie.
- Aucun modele persistant modifie.
- Aucun codec JSON modifie.
- Aucun panel/state editor modifie.
- Aucun painter modifie.
- Aucun `MapGridPainter` modifie.
- Aucun import `map_runtime` ajoute dans `map_editor`.
- Aucun blur, atlas, z-order, light direction, time-of-day, Shadow Studio ou UI footprint.
- Aucun commit effectue.

## 23. Risques / reserves

- Shadow-30 rend l'editor capable de consommer les footprints, mais ne fournit pas encore d'UI pour les authorer visuellement.
- La qualite visuelle dependra des footprints presents dans les donnees. Sans footprint, le comportement reste volontairement identique a Shadow-24.
- Le builder editor utilise maintenant la validation de `resolveStaticShadowGeometry(...)`. Les donnees invalides devraient deja etre bloquees par les modeles core.

## 24. Auto-review finale

- Ai-je remplace la formule editor preview locale par la geometrie core ? oui.
- Ai-je evite d'appliquer offset/scale deux fois ? oui.
- Ai-je conserve le comportement sans footprint ? oui.
- Ai-je transmis elementFootprint et overrideFootprint ? oui.
- Ai-je evite de toucher au runtime ? oui.
- Ai-je evite de toucher aux UI panels/state ? oui.
- Ai-je evite de modifier l'ordre de rendu canvas ? oui.
- Ai-je evite de modifier les modeles persistants/codecs ? oui.
- Ai-je evite toute lumiere globale ? oui.
- Ai-je evite tout import map_runtime dans map_editor ? oui.

## 25. Regard critique sur le prompt

Le prompt est coherent avec la trajectoire Shadow-28/29. Le point le plus important etait d'eviter une double application offset/scale : la difference runtime/editor impose deux usages distincts de la geometrie core. Runtime conserve son resolver final ; editor utilise directement `geometry.left/top/width/height`. Cette distinction est bonne et testee.

Le seul point a surveiller dans les prochains lots : si une UI footprint est ajoutee, elle devra produire des valeurs suffisamment ergonomiques pour que les donnees visibles changent reellement. Shadow-30 ne rend pas les ombres meilleures par lui-meme ; il garantit que l'editor verra les memes geometries que le runtime quand ces footprints existent.

## 26. Contenu complet des fichiers crees/modifies

### Fichier cree

`reports/shadows/shadow_lot_30_editor_static_shadow_preview_geometry_integration.md`

Ce rapport est le fichier cree par Shadow-30.

### Fichier modifie - editor_static_shadow_preview.dart

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
    final geometry = resolveStaticShadowGeometry(
      metrics: StaticShadowVisualMetrics(
        left: baseLeft,
        top: baseTop,
        visualWidth: visualWidth,
        visualHeight: visualHeight,
      ),
      shadowConfig: resolved,
      elementFootprint: element.shadow?.footprint,
      overrideFootprint: placed.shadowOverride?.footprint,
    );

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: resolved.mode,
        left: geometry.left,
        top: geometry.top,
        width: geometry.width,
        height: geometry.height,
        opacity: resolved.opacity,
        colorHexRgb: resolved.colorHexRgb,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}
```

### Fichier modifie - editor_static_shadow_preview_test.dart, sections Shadow-30 ajoutees

```dart
    test('uses element footprint for preview anchor and size', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: StaticShadowFootprintConfig(
              anchorXRatio: 0.25,
              anchorYRatio: 0.75,
              footprintWidthRatio: 0.5,
              footprintHeightRatio: 0.125,
            ),
          ),
        ),
        map: _map(),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      expect(instruction.left, closeTo(16, 0.001));
      expect(instruction.top, closeTo(76, 0.001));
      expect(instruction.width, closeTo(16, 0.001));
      expect(instruction.height, closeTo(8, 0.001));
    });

    test('uses override footprint over element footprint field by field', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: StaticShadowFootprintConfig(
              anchorXRatio: 0.25,
              anchorYRatio: 0.75,
              footprintWidthRatio: 0.5,
              footprintHeightRatio: 0.125,
            ),
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            footprint: StaticShadowFootprintConfig(
              anchorYRatio: 0.5,
              footprintWidthRatio: 0.25,
            ),
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      expect(instruction.left, closeTo(20, 0.001));
      expect(instruction.top, closeTo(60, 0.001));
      expect(instruction.width, closeTo(8, 0.001));
      expect(instruction.height, closeTo(8, 0.001));
    });

    test('custom override without footprint keeps element footprint', () {
      final instructions = buildEditorStaticShadowPreviewInstructions(
        manifest: _manifest(
          elementShadow: ProjectElementShadowConfig(
            castsShadow: true,
            shadowProfileId: 'base_shadow',
            footprint: StaticShadowFootprintConfig(
              anchorXRatio: 0.5,
              anchorYRatio: 0.5,
              footprintWidthRatio: 0.5,
              footprintHeightRatio: 0.5,
            ),
          ),
        ),
        map: _map(
          shadowOverride: MapPlacedElementShadowOverride(
            mode: ShadowOverrideMode.custom,
            offsetX: 4,
            offsetY: -2,
            scaleX: 2,
            scaleY: 0.5,
          ),
        ),
        tileWidth: 16,
        tileHeight: 16,
      );

      final instruction = instructions.single;
      expect(instruction.left, closeTo(20, 0.001));
      expect(instruction.top, closeTo(54, 0.001));
      expect(instruction.width, closeTo(32, 0.001));
      expect(instruction.height, closeTo(16, 0.001));
    });
```

## 27. Diffs complets ou equivalents /dev/null pour fichiers crees

### Diff complet des fichiers code/test modifies

```diff
diff --git a/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart b/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
index c32ace9c..2bbc2f52 100644
--- a/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
+++ b/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
@@ -107,25 +107,27 @@ List<EditorStaticShadowPreviewInstruction>
     final visualHeight = source.height * tileHeight;
     final baseLeft = placed.pos.x * tileWidth;
     final baseTop = placed.pos.y * tileHeight;
-    final anchorX = baseLeft + visualWidth * 0.5;
-    final anchorY = baseTop + visualHeight;
-    final shadowWidth = visualWidth * 0.75 * resolved.scaleX;
-    final shadowHeight = visualHeight * 0.25 * resolved.scaleY;
-    if (shadowWidth <= 0 || shadowHeight <= 0) {
-      continue;
-    }
-    final centerX = anchorX + resolved.offsetX;
-    final centerY = anchorY + resolved.offsetY;
+    final geometry = resolveStaticShadowGeometry(
+      metrics: StaticShadowVisualMetrics(
+        left: baseLeft,
+        top: baseTop,
+        visualWidth: visualWidth,
+        visualHeight: visualHeight,
+      ),
+      shadowConfig: resolved,
+      elementFootprint: element.shadow?.footprint,
+      overrideFootprint: placed.shadowOverride?.footprint,
+    );
 
     instructions.add(
       EditorStaticShadowPreviewInstruction(
         instanceId: placed.id,
         elementId: placed.elementId,
         shape: resolved.mode,
-        left: centerX - shadowWidth / 2,
-        top: centerY - shadowHeight / 2,
-        width: shadowWidth,
-        height: shadowHeight,
+        left: geometry.left,
+        top: geometry.top,
+        width: geometry.width,
+        height: geometry.height,
         opacity: resolved.opacity,
         colorHexRgb: resolved.colorHexRgb,
       ),
diff --git a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
index 8e9796a4..a284289c 100644
--- a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
@@ -190,6 +190,100 @@ void main() {
       expect(instruction.opacity, 0.2);
     });
 
+    test('uses element footprint for preview anchor and size', () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          elementShadow: ProjectElementShadowConfig(
+            castsShadow: true,
+            shadowProfileId: 'base_shadow',
+            footprint: StaticShadowFootprintConfig(
+              anchorXRatio: 0.25,
+              anchorYRatio: 0.75,
+              footprintWidthRatio: 0.5,
+              footprintHeightRatio: 0.125,
+            ),
+          ),
+        ),
+        map: _map(),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      final instruction = instructions.single;
+      expect(instruction.left, closeTo(16, 0.001));
+      expect(instruction.top, closeTo(76, 0.001));
+      expect(instruction.width, closeTo(16, 0.001));
+      expect(instruction.height, closeTo(8, 0.001));
+    });
+
+    test('uses override footprint over element footprint field by field', () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          elementShadow: ProjectElementShadowConfig(
+            castsShadow: true,
+            shadowProfileId: 'base_shadow',
+            footprint: StaticShadowFootprintConfig(
+              anchorXRatio: 0.25,
+              anchorYRatio: 0.75,
+              footprintWidthRatio: 0.5,
+              footprintHeightRatio: 0.125,
+            ),
+          ),
+        ),
+        map: _map(
+          shadowOverride: MapPlacedElementShadowOverride(
+            mode: ShadowOverrideMode.custom,
+            footprint: StaticShadowFootprintConfig(
+              anchorYRatio: 0.5,
+              footprintWidthRatio: 0.25,
+            ),
+          ),
+        ),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      final instruction = instructions.single;
+      expect(instruction.left, closeTo(20, 0.001));
+      expect(instruction.top, closeTo(60, 0.001));
+      expect(instruction.width, closeTo(8, 0.001));
+      expect(instruction.height, closeTo(8, 0.001));
+    });
+
+    test('custom override without footprint keeps element footprint', () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          elementShadow: ProjectElementShadowConfig(
+            castsShadow: true,
+            shadowProfileId: 'base_shadow',
+            footprint: StaticShadowFootprintConfig(
+              anchorXRatio: 0.5,
+              anchorYRatio: 0.5,
+              footprintWidthRatio: 0.5,
+              footprintHeightRatio: 0.5,
+            ),
+          ),
+        ),
+        map: _map(
+          shadowOverride: MapPlacedElementShadowOverride(
+            mode: ShadowOverrideMode.custom,
+            offsetX: 4,
+            offsetY: -2,
+            scaleX: 2,
+            scaleY: 0.5,
+          ),
+        ),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      final instruction = instructions.single;
+      expect(instruction.left, closeTo(20, 0.001));
+      expect(instruction.top, closeTo(54, 0.001));
+      expect(instruction.width, closeTo(32, 0.001));
+      expect(instruction.height, closeTo(16, 0.001));
+    });
+
     test('custom profile overrides source profile and null profile inherits it',
         () {
       final overrideProfile = _profile(
```

### /dev/null equivalent pour le fichier cree

```diff
--- /dev/null
+++ b/reports/shadows/shadow_lot_30_editor_static_shadow_preview_geometry_integration.md
@@
+Shadow-30 report added with Evidence Pack, commands, results, scans, status, content, and diffs.
```
