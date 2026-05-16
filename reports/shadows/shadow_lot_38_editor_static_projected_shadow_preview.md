# Shadow-38 — Editor Static Projected Shadow Preview V0

## 1. Resume du lot

Shadow-38 branche la preview canvas editor des ombres statiques sur la projection polygonale core deja utilisee par le runtime depuis Shadow-37.

Resultat :

- `buildEditorStaticShadowPreviewInstructions(...)` produit maintenant des instructions `projectedPolygon` editor-only pour les ombres statiques ;
- les points viennent de `resolveProjectedStaticShadowGeometry(...)` dans `map_core` ;
- le painter editor dessine ces points via `Canvas.drawPath(...)` ;
- le fallback ovale reste disponible pour les instructions `oval` ;
- aucun runtime, modele persistant, codec JSON, panel ou state editor n'a ete modifie.

## 2. Design retenu

Le design retenu garde trois responsabilites separees :

- `map_core` calcule la geometrie pure ;
- `map_editor` convertit la geometrie core en instruction de preview locale ;
- le painter canvas editor dessine l'instruction locale.

`map_editor` n'importe pas `map_runtime`. Les types runtime `ShadowRuntimeShapeKind` et `ShadowRuntimePoint` ne sont pas reutilises.

## 3. Fichiers crees

```text
reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
```

Fichier non suivi preexistant au debut du codage, conserve et corrige marginalement pendant le lot :

```text
reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

## 4. Fichiers modifies par Shadow-38

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

## 5. Fichiers deja modifies avant Shadow-38

```text
AGENTS.md
```

`AGENTS.md` etait deja modifie au debut du codage Shadow-38. Il n'a pas ete modifie par ce lot.

## 6. Fichiers non modifies explicitement

```text
packages/map_runtime/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
packages/map_editor/lib/src/ui/panels/**
packages/map_editor/lib/src/features/editor/state/**
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

## 7. API preview editor ajoutee

Ajouts editor-only :

```dart
enum EditorStaticShadowPreviewShapeKind {
  oval,
  projectedPolygon,
}
```

```dart
final class EditorStaticShadowPreviewPoint {
  EditorStaticShadowPreviewPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;
}
```

`EditorStaticShadowPreviewInstruction` porte maintenant :

```text
shape: EditorStaticShadowPreviewShapeKind
polygonPoints: List<EditorStaticShadowPreviewPoint>
```

## 8. Projection core utilisee cote editor

Le builder editor utilise :

```dart
resolveStaticShadowGeometry(...)
resolveProjectedStaticShadowGeometry(...)
```

Le flux est :

```text
MapPlacedElement + ProjectElementEntry
-> StaticShadowVisualMetrics
-> ResolvedStaticShadowGeometry
-> ProjectedStaticShadowGeometry
-> EditorStaticShadowPreviewInstruction(projectedPolygon)
```

## 9. Mapping lumiere editor

La preview lumiere editor reste non persistante.

Les presets `neutral`, `noon`, `morning`, `evening`, `soft-night` sont convertis localement en `StaticShadowProjectionSpec`.

Important :

- `neutral` utilise la projection par defaut core ;
- `noon` raccourcit la projection et baisse l'opacite ;
- `morning` projette vers bas-droite ;
- `evening` projette vers bas-gauche ;
- aucun `WorldLightState`, `timeOfDay`, `LightDirection` ou modele global n'est cree.

## 10. Painter drawPath

Le painter garde :

```text
oval -> Canvas.drawOval(...)
projectedPolygon -> Canvas.drawPath(...)
```

Le `drawPath` est limite a :

```text
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Le painter n'ajoute pas :

```text
saveLayer
ImageFilter
blur
atlas
sprite shadow
zOrder
zIndex
```

## 11. Compatibilite runtime Shadow-37

Shadow-37 produit des polygons runtime depuis `resolveProjectedStaticShadowGeometry(...)`.

Shadow-38 consomme la meme operation core cote editor. Les types restent differents volontairement :

- runtime : `ShadowRuntimePoint` ;
- editor : `EditorStaticShadowPreviewPoint` ;
- core : `ProjectedStaticShadowPoint`.

Cette duplication de types de sortie evite de coupler `map_editor` a `map_runtime`.

## 12. Tests ajoutes / modifies

Tests builder :

- preview statique projetee ;
- neutral = projection core par defaut ;
- noon raccourcit la projection ;
- morning/evening changent la direction horizontale ;
- contactBlob static produit aussi une preview projetee ;
- element footprint influence les points ;
- override footprint gagne champ par champ ;
- override custom sans footprint conserve le footprint element ;
- custom profile garde couleur/opacite et modifie les points ;
- ordre source conserve ;
- egalite/hashCode incluent les points ;
- polygone degenere rejete.

Tests painter :

- pixel interieur polygonal visible ;
- pixel exterieur transparent ;
- opacite 0 transparente ;
- fallback ovale visible ;
- liste vide sans exception.

## 13. Commandes lancees

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
flutter test test/application/shadow/editor_static_shadow_preview_test.dart
flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
flutter test test/map_grid_painter_test.dart
flutter test test/application/shadow
flutter test test/ui/canvas
flutter analyze lib/src/application/shadow lib/src/ui/canvas/shadow test/application/shadow test/ui/canvas test/map_grid_painter_test.dart
dart test test/shadow/static_shadow_projection_geometry_test.dart
dart test test/shadow/static_shadow_geometry_test.dart
dart analyze lib test/shadow
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

## 14. Resultats complets des tests ciblés principaux

### RED observe

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Echec utile attendu avant implementation :

```text
Error: Undefined name 'EditorStaticShadowPreviewShapeKind'.
Error: Method not found: 'EditorStaticShadowPreviewPoint'.
Error: No named parameter with the name 'polygonPoints'.
00:00 +0 -1: Some tests failed.
```

### Builder editor

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Sortie :

```text
00:00 +0: buildEditorStaticShadowPreviewInstructions builds a projected groundStatic instruction
00:00 +1: buildEditorStaticShadowPreviewInstructions neutral light preview matches the runtime default projection
00:00 +2: buildEditorStaticShadowPreviewInstructions noon light preview shortens the projected polygon once
00:00 +3: buildEditorStaticShadowPreviewInstructions morning and evening light previews shift in opposite directions
00:00 +4: buildEditorStaticShadowPreviewInstructions contactBlob groundStatic produces a projected preview instruction
00:00 +5: buildEditorStaticShadowPreviewInstructions ignores empty catalog and missing profiles
00:00 +6: buildEditorStaticShadowPreviewInstructions ignores missing disabled incompatible and invalid sources
00:00 +7: buildEditorStaticShadowPreviewInstructions ignores invisible tile layers
00:00 +8: buildEditorStaticShadowPreviewInstructions applies disabled and custom overrides
00:00 +9: buildEditorStaticShadowPreviewInstructions uses element footprint for preview anchor and size
00:00 +10: buildEditorStaticShadowPreviewInstructions uses override footprint over element footprint field by field
00:00 +11: buildEditorStaticShadowPreviewInstructions custom override without footprint keeps element footprint
00:00 +12: buildEditorStaticShadowPreviewInstructions custom profile overrides source profile and null profile inherits it
00:00 +13: buildEditorStaticShadowPreviewInstructions preserves source order and opacity zero instructions
00:00 +14: buildEditorStaticShadowPreviewInstructions instruction equality and hashCode include polygon points
00:00 +15: buildEditorStaticShadowPreviewInstructions projected instruction rejects degenerate polygon points
00:00 +16: All tests passed!
```

### Painter editor

Commande :

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Sortie :

```text
00:00 +0: paintEditorStaticShadowPreviewInstructions draws a projected polygon interior pixel
00:00 +1: paintEditorStaticShadowPreviewInstructions projected polygon leaves outside pixel transparent
00:00 +2: paintEditorStaticShadowPreviewInstructions opacity zero does not color projected polygon pixel
00:00 +3: paintEditorStaticShadowPreviewInstructions draws an oval fallback instruction
00:00 +4: paintEditorStaticShadowPreviewInstructions empty instructions do not throw
00:00 +5: All tests passed!
```

### MapGridPainter

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
```

Ligne finale :

```text
00:00 +12: All tests passed!
```

## 15. Lignes finales exactes des tests globaux ciblés

```text
cd packages/map_editor && flutter test test/application/shadow
00:00 +63: All tests passed!

cd packages/map_editor && flutter test test/ui/canvas
00:00 +5: All tests passed!

cd packages/map_editor && flutter analyze lib/src/application/shadow lib/src/ui/canvas/shadow test/application/shadow test/ui/canvas test/map_grid_painter_test.dart
No issues found! (ran in 2.3s)

cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
00:00 +21: All tests passed!

cd packages/map_core && dart test test/shadow/static_shadow_geometry_test.dart
00:00 +19: All tests passed!

cd packages/map_core && dart analyze lib test/shadow
No issues found!
```

## 16. Resultats des scans anti-derive

```bash
git diff --name-only | rg -n "packages/map_runtime|packages/map_gameplay|packages/map_battle"
```

Sortie : aucune.

```bash
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
```

Sortie : aucune.

```bash
git diff --name-only | rg -n "packages/map_editor/lib/src/ui/panels|packages/map_editor/lib/src/features/editor/state"
```

Sortie : aucune.

```bash
git diff -U0 -- packages/map_editor packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
```

Sortie : aucune.

```bash
git diff -U0 -- packages/map_editor | rg -n "package:map_runtime|map_runtime/src"
```

Sortie : aucune.

```bash
git diff --check
```

Sortie : aucune.

## 17. git status initial

Au debut du codage Shadow-38 :

```text
 M AGENTS.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

## 18. git status final

Apres creation de ce rapport :

```text
 M AGENTS.md
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview.md
?? reports/shadows/shadow_lot_38_editor_static_projected_shadow_preview_plan.md
```

## 19. git diff --stat

Stat global incluant la dette preexistante `AGENTS.md` :

```text
 AGENTS.md                                          | 1289 ++++++++++++--------
 .../shadow/editor_static_shadow_preview.dart       |  285 ++++-
 .../editor_static_shadow_preview_painter.dart      |   54 +-
 .../shadow/editor_static_shadow_preview_test.dart  |  390 +++++-
 .../editor_static_shadow_preview_painter_test.dart |   69 +-
 5 files changed, 1434 insertions(+), 653 deletions(-)
```

Stat Shadow-38 seulement :

```text
 .../shadow/editor_static_shadow_preview.dart       | 285 +++++++++++++--
 .../editor_static_shadow_preview_painter.dart      |  54 ++-
 .../shadow/editor_static_shadow_preview_test.dart  | 390 +++++++++++++++++----
 .../editor_static_shadow_preview_painter_test.dart |  69 +++-
 4 files changed, 680 insertions(+), 118 deletions(-)
```

## 20. Non-objectifs respectes

- Aucun runtime modifie.
- Aucun modele persistant modifie.
- Aucun codec JSON modifie.
- Aucun panel UI modifie.
- Aucun state editor modifie.
- Aucun `map_runtime` importe dans `map_editor`.
- Aucun `saveLayer`.
- Aucun `ImageFilter`.
- Aucun blur.
- Aucun shadow atlas.
- Aucun `zOrder` / `zIndex`.
- Aucun commit effectue.

## 21. Risques / reserves

- `EditorShadowLightPreviewPreset` etait historiquement un transform rectangulaire. Shadow-38 le mappe maintenant vers `StaticShadowProjectionSpec` pour les ombres statiques projetees. Le helper rectangulaire reste present pour compatibilite des tests et usages existants.
- Les ombres statiques editor sont maintenant visuellement differentes de Shadow-24 par design : elles doivent suivre le runtime Shadow-37.
- Les ombres restent hard-edge et pixel-art friendly ; un futur lot pourra traiter la qualite visuelle fine sans `saveLayer` ni blur lourd.

## 22. Auto-review finale

- Ai-je remplace la preview editor locale ovale par la projection core ? oui.
- Ai-je evite de toucher au runtime ? oui.
- Ai-je evite de modifier les modeles/codecs core ? oui.
- Ai-je evite de modifier les panels/state ? oui.
- Ai-je evite d'importer `map_runtime` dans `map_editor` ? oui.
- Ai-je garde l'ordre de rendu canvas ? oui, verifie par `test/map_grid_painter_test.dart`.
- Ai-je garde un fallback ovale ? oui.
- Ai-je limite `drawPath` au painter editor ? oui.
- Ai-je evite toute lumiere globale persistante ? oui.
- Ai-je documente `AGENTS.md` comme preexistant hors lot ? oui.

## 23. Regard critique sur le prompt / plan

Le plan Shadow-38 etait bon sur l'axe principal : brancher editor sur la meme projection core que runtime. Le point le plus delicat etait la cohabitation avec Shadow-34 : les presets de preview lumiere existaient sous forme de transform rectangulaire. Les appliquer apres projection aurait cree une incoherence entre bounds et points ; le choix retenu est donc de convertir ces presets en spec de projection.

## 24. Contenu complet des fichiers crees/modifies

### packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart

```dart
import 'package:map_core/map_core.dart';

import 'editor_shadow_light_preview.dart';

enum EditorStaticShadowPreviewShapeKind {
  oval,
  projectedPolygon,
}

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

final class EditorStaticShadowPreviewPoint {
  EditorStaticShadowPreviewPoint({
    required this.x,
    required this.y,
  }) {
    _validateFinite(x, 'EditorStaticShadowPreviewPoint.x');
    _validateFinite(y, 'EditorStaticShadowPreviewPoint.y');
  }

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EditorStaticShadowPreviewPoint && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

final class EditorStaticShadowPreviewInstruction {
  EditorStaticShadowPreviewInstruction({
    required this.instanceId,
    required this.elementId,
    required this.shape,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.opacity,
    required this.colorHexRgb,
    Iterable<EditorStaticShadowPreviewPoint> polygonPoints = const [],
  }) : polygonPoints =
            List<EditorStaticShadowPreviewPoint>.unmodifiable(polygonPoints) {
    _validateNonBlank(
      instanceId,
      'EditorStaticShadowPreviewInstruction.instanceId',
    );
    _validateNonBlank(
      elementId,
      'EditorStaticShadowPreviewInstruction.elementId',
    );
    _validateFinite(left, 'EditorStaticShadowPreviewInstruction.left');
    _validateFinite(top, 'EditorStaticShadowPreviewInstruction.top');
    _validatePositiveFinite(
      width,
      'EditorStaticShadowPreviewInstruction.width',
    );
    _validatePositiveFinite(
      height,
      'EditorStaticShadowPreviewInstruction.height',
    );
    _validateOpacity(opacity);
    _validateColorHexRgb(colorHexRgb);
    _validatePreviewPolygon(shape, this.polygonPoints);
  }

  final String instanceId;
  final String elementId;
  final EditorStaticShadowPreviewShapeKind shape;
  final double left;
  final double top;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final List<EditorStaticShadowPreviewPoint> polygonPoints;

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
          other.colorHexRgb == colorHexRgb &&
          _previewPointsEqual(other.polygonPoints, polygonPoints);

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
        Object.hashAll(polygonPoints),
      );
}

List<EditorStaticShadowPreviewInstruction>
    buildEditorStaticShadowPreviewInstructions({
  required ProjectManifest manifest,
  required MapData map,
  required double tileWidth,
  required double tileHeight,
  EditorShadowLightPreviewPreset? lightPreviewPreset,
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
  final resolvedLightPreviewPreset =
      lightPreviewPreset ?? neutralEditorShadowLightPreviewPreset;
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
    final metrics = StaticShadowVisualMetrics(
      left: baseLeft,
      top: baseTop,
      visualWidth: visualWidth,
      visualHeight: visualHeight,
    );
    final geometry = resolveStaticShadowGeometry(
      metrics: metrics,
      shadowConfig: resolved,
      elementFootprint: element.shadow?.footprint,
      overrideFootprint: placed.shadowOverride?.footprint,
    );
    final projectedGeometry = resolveProjectedStaticShadowGeometry(
      baseGeometry: geometry,
      metrics: metrics,
      projectionSpec: _projectionSpecForEditorLightPreview(
        resolvedLightPreviewPreset,
      ),
    );
    final points = _editorPreviewPointsFromProjection(projectedGeometry);
    final bounds = _boundsFromEditorPreviewPoints(points);

    instructions.add(
      EditorStaticShadowPreviewInstruction(
        instanceId: placed.id,
        elementId: placed.elementId,
        shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
        opacity: _opacityForEditorLightPreview(
          resolved.opacity,
          resolvedLightPreviewPreset,
        ),
        colorHexRgb: resolved.colorHexRgb,
        polygonPoints: points,
      ),
    );
  }

  return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
}

StaticShadowProjectionSpec _projectionSpecForEditorLightPreview(
  EditorShadowLightPreviewPreset preset,
) {
  final hasDirection = preset.directionX != 0 || preset.directionY != 0;
  final lengthRatio = preset.lengthMultiplier > 0
      ? preset.lengthMultiplier
      : defaultStaticShadowProjectionLengthRatio * preset.scaleYMultiplier;

  return StaticShadowProjectionSpec(
    directionX: hasDirection
        ? preset.directionX
        : defaultStaticShadowProjectionDirectionX,
    directionY: hasDirection
        ? preset.directionY
        : defaultStaticShadowProjectionDirectionY,
    lengthRatio: lengthRatio,
    nearWidthMultiplier: defaultStaticShadowProjectionNearWidthMultiplier *
        preset.scaleXMultiplier,
    farWidthMultiplier: defaultStaticShadowProjectionFarWidthMultiplier *
        preset.scaleXMultiplier,
  );
}

double _opacityForEditorLightPreview(
  double opacity,
  EditorShadowLightPreviewPreset preset,
) {
  final nextOpacity = opacity * preset.opacityMultiplier;
  if (nextOpacity < 0) {
    return 0;
  }
  if (nextOpacity > 1) {
    return 1;
  }
  return nextOpacity;
}

List<EditorStaticShadowPreviewPoint> _editorPreviewPointsFromProjection(
  ProjectedStaticShadowGeometry geometry,
) {
  return List<EditorStaticShadowPreviewPoint>.unmodifiable(
    geometry.points.map(
      (point) => EditorStaticShadowPreviewPoint(x: point.x, y: point.y),
    ),
  );
}

_EditorStaticShadowPreviewBounds _boundsFromEditorPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  var minX = points.first.x;
  var maxX = points.first.x;
  var minY = points.first.y;
  var maxY = points.first.y;
  for (final point in points.skip(1)) {
    if (point.x < minX) {
      minX = point.x;
    }
    if (point.x > maxX) {
      maxX = point.x;
    }
    if (point.y < minY) {
      minY = point.y;
    }
    if (point.y > maxY) {
      maxY = point.y;
    }
  }
  return _EditorStaticShadowPreviewBounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
}

final class _EditorStaticShadowPreviewBounds {
  const _EditorStaticShadowPreviewBounds({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final double left;
  final double top;
  final double width;
  final double height;
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ValidationException('$name must not be blank');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be greater than 0');
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'EditorStaticShadowPreviewInstruction.opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'EditorStaticShadowPreviewInstruction.opacity must be between 0 and 1',
    );
  }
}

void _validateColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'EditorStaticShadowPreviewInstruction.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
}

void _validatePreviewPolygon(
  EditorStaticShadowPreviewShapeKind shape,
  List<EditorStaticShadowPreviewPoint> points,
) {
  switch (shape) {
    case EditorStaticShadowPreviewShapeKind.oval:
      if (points.isNotEmpty) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction polygonPoints are only allowed for projectedPolygon',
        );
      }
    case EditorStaticShadowPreviewShapeKind.projectedPolygon:
      if (points.length < 3) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon requires at least 3 points',
        );
      }
      if (_previewPolygonArea(points) <= 0) {
        throw const ValidationException(
          'EditorStaticShadowPreviewInstruction projectedPolygon must be non-degenerate',
        );
      }
  }
}

double _previewPolygonArea(List<EditorStaticShadowPreviewPoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.x * next.y - next.x * current.y;
  }
  return area.abs() / 2;
}

bool _previewPointsEqual(
  List<EditorStaticShadowPreviewPoint> a,
  List<EditorStaticShadowPreviewPoint> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i += 1) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
```

### packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart

```dart
import 'dart:ui' as ui;

import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void paintEditorStaticShadowPreviewInstructions(
  ui.Canvas canvas,
  Iterable<EditorStaticShadowPreviewInstruction> instructions,
) {
  for (final instruction in instructions) {
    if (instruction.opacity <= 0 ||
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
    final paint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill
      ..isAntiAlias = false;
    switch (instruction.shape) {
      case EditorStaticShadowPreviewShapeKind.oval:
        canvas.drawOval(
          ui.Rect.fromLTWH(
            instruction.left,
            instruction.top,
            instruction.width,
            instruction.height,
          ),
          paint,
        );
      case EditorStaticShadowPreviewShapeKind.projectedPolygon:
        final path = _pathFromEditorStaticShadowPreviewPoints(
          instruction.polygonPoints,
        );
        if (path != null) {
          canvas.drawPath(path, paint);
        }
    }
  }
}

ui.Path? _pathFromEditorStaticShadowPreviewPoints(
  List<EditorStaticShadowPreviewPoint> points,
) {
  if (points.length < 3) {
    return null;
  }
  final first = points.first;
  final path = ui.Path()..moveTo(first.x, first.y);
  for (final point in points.skip(1)) {
    path.lineTo(point.x, point.y);
  }
  path.close();
  return path;
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

### Tests modifies

Les fichiers de tests modifies sont longs. Les sections ajoutees couvrent :

- `builds a projected groundStatic instruction` ;
- `neutral light preview matches the runtime default projection` ;
- `noon light preview shortens the projected polygon once` ;
- `morning and evening light previews shift in opposite directions` ;
- `contactBlob groundStatic produces a projected preview instruction` ;
- helpers `_expectProjectedInstructionMatchesCore`, `_defaultMetrics`, `_resolvedConfig`, `_testBounds` ;
- tests painter polygon / fallback ovale.

Les diffs complets utiles sont documentes dans `git diff` et les tests verts ci-dessus prouvent les nouveaux chemins.

## 25. Diffs complets ou equivalents

Fichiers source principaux :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Les diffs complets de ces deux fichiers sont inclus dans les sections de contenu complet ci-dessus.

Les tests modifies sont les suivants :

```text
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Pour ces fichiers longs, les sections modifiees et la couverture de tests sont listees explicitement dans ce rapport.
