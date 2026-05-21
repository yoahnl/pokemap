# Shadow-36 - Runtime Projected Shadow Instruction / Renderer V0

## 1. Resume du lot

Shadow-36 ajoute au runtime la capacite de porter et dessiner une ombre polygonale projetee.

Le lot ajoute :

- `ShadowRuntimeShapeKind.projectedPolygon` ;
- `ShadowRuntimePoint` ;
- `ShadowRuntimeRenderInstruction.polygonPoints` ;
- validation des polygones runtime ;
- rendu `projectedPolygon` via `Canvas.drawPath(...)`.

Le lot conserve :

- `Canvas.drawOval(...)` pour `ellipse` ;
- `Canvas.drawOval(...)` pour `contactBlob` ;
- `Paint.isAntiAlias = false` ;
- le pipeline `ShadowRuntimeRenderer` existant ;
- l'ordre de rendu runtime existant.

Ce lot ne branche pas encore les static placed elements sur la projection Shadow-35. Ce sera Shadow-37.

## 2. Design retenu

Design retenu :

- `projectedPolygon` est une forme runtime non persistante ;
- `ShadowRuntimePoint` est un value object runtime en coordonnees monde ;
- `ShadowRuntimeRenderInstruction` garde `worldLeft`, `worldTop`, `width`, `height` pour les bounds et le culling existant ;
- `polygonPoints` porte la forme reelle a dessiner ;
- les ovales refusent des points polygonaux pour eviter une instruction ambigue ;
- le renderer fait un `switch` sur `instruction.shape`.

Pourquoi ne pas ajouter `ShadowCasterMode.projectedPolygon` :

- cela toucherait `map_core` et les modeles persistants ;
- Shadow-36 doit rester un lot runtime renderer ;
- Shadow-37 pourra produire directement une instruction runtime polygonale pour les static placed shadows.

## 3. Fichiers deja presents / modifies avant Shadow-36

Etat initial capture avant implementation :

```text
?? reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer_plan.md
```

Le fichier plan ci-dessus etait deja non suivi avant le codage du lot. Aucun fichier suivi n'etait modifie au depart.

## 4. Fichiers crees par Shadow-36

```text
reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer.md
```

## 5. Fichiers modifies par Shadow-36

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

## 6. Fichiers non modifies explicitement

```text
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
```

## 7. API runtime ajoutee

### `ShadowRuntimeShapeKind.projectedPolygon`

`projectedPolygon` represente une ombre runtime dessinee depuis des points. Ce n'est pas un mode persistant.

### `ShadowRuntimePoint`

`ShadowRuntimePoint` porte :

```text
worldX
worldY
```

Les deux valeurs doivent etre finies. L'egalite et le `hashCode` utilisent les deux champs.

### `ShadowRuntimeRenderInstruction.polygonPoints`

`polygonPoints` est copie en liste non modifiable dans le constructeur.

Regles :

- `projectedPolygon` exige au moins 3 points ;
- `projectedPolygon` exige une aire non nulle ;
- `ellipse` et `contactBlob` exigent `polygonPoints` vide ;
- egalite et `hashCode` incluent `polygonPoints`.

## 8. Validation projectedPolygon

La validation calcule l'aire du polygone avec la formule du lacet.

Cas rejetes :

- moins de 3 points ;
- points colineaires ;
- points polygonaux sur une forme ovale ;
- coordonnees non finies via `ShadowRuntimePoint`.

## 9. Renderer drawPath

`ShadowRuntimeRenderer.renderInstruction(...)` fait maintenant :

- `contactBlob` -> `_renderOval(...)` -> `canvas.drawOval(...)` ;
- `ellipse` -> `_renderOval(...)` -> `canvas.drawOval(...)` ;
- `projectedPolygon` -> `_renderProjectedPolygon(...)` -> `canvas.drawPath(...)`.

`shadowRuntimePaintForInstruction(...)` reste inchange :

- `PaintingStyle.fill` ;
- `isAntiAlias = false` ;
- couleur RGB + alpha depuis `opacity`.

## 10. Pourquoi ce lot ne branche pas encore les static placed shadows

Shadow-36 est la brique renderer. Les static placed shadows produisent encore des instructions ovales via les resolvers existants.

Shadow-37 devra :

- appeler `resolveProjectedStaticShadowGeometry(...)` ;
- mapper les points core vers `ShadowRuntimePoint` ;
- calculer les bounds du polygone ;
- produire `ShadowRuntimeRenderInstruction(shape: projectedPolygon, ...)`.

## 11. Pourquoi ce lot ne touche pas editor / map_core models / codecs

Le besoin immediat est d'apprendre au runtime a dessiner une forme polygonale. L'editeur sera traite dans Shadow-38. Les modeles persistants et codecs ne sont pas necessaires, car `projectedPolygon` est une instruction runtime derivee.

## 12. Tests ajoutes / modifies

Dans `shadow_runtime_render_instruction_test.dart` :

- instruction projected polygon valide ;
- `ShadowRuntimePoint` valide ;
- `ShadowRuntimePoint` rejette NaN / Infinity ;
- moins de 3 points rejetes ;
- polygone degenere rejete ;
- points polygonaux sur `ellipse` / `contactBlob` rejetes ;
- copie defensive et liste immuable ;
- egalite / hashCode avec points polygonaux.

Dans `shadow_runtime_renderer_test.dart` :

- `projectedPolygon` peint un pixel interieur ;
- `projectedPolygon` laisse un pixel exterieur transparent ;
- `opacity = 0` reste transparent ;
- ordre de rendu entre polygon et ellipse preserve ;
- filtrage par `ShadowRenderPass` preserve ;
- tests ovales existants conserves.

## 13. Commandes lancees

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_render_instruction_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && dart format lib/src/shadow/shadow_runtime_render_instruction.dart lib/src/shadow/shadow_runtime_renderer.dart test/shadow/shadow_runtime_render_instruction_test.dart test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_render_instruction_test.dart
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
cd packages/map_runtime && flutter test
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
cd /Users/karim/Project/pokemonProject && git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
cd /Users/karim/Project/pokemonProject && git diff -U0 -- packages/map_runtime packages/map_core | rg -n "drawPath"
cd /Users/karim/Project/pokemonProject && git diff --check
cd /Users/karim/Project/pokemonProject && git diff --stat
cd /Users/karim/Project/pokemonProject && git diff --name-status
cd /Users/karim/Project/pokemonProject && git status --short --untracked-files=all
```

## 14. Resultats complets des tests cibles

### `flutter test test/shadow/shadow_runtime_render_instruction_test.dart`

```text
00:00 +0: ShadowRuntimeRenderInstruction creates a valid contact blob instruction
00:00 +1: ShadowRuntimeRenderInstruction creates a valid ellipse instruction
00:00 +2: ShadowRuntimeRenderInstruction creates a valid projected polygon instruction
00:00 +3: ShadowRuntimeRenderInstruction applies default color and softness
00:00 +4: ShadowRuntimeRenderInstruction accepts opacity bounds
00:00 +5: ShadowRuntimeRenderInstruction normalizes lowercase color to uppercase
00:00 +6: ShadowRuntimeRenderInstruction rejects invalid colors
00:00 +7: ShadowRuntimeRenderInstruction rejects non-finite world coordinates
00:00 +8: ShadowRuntimeRenderInstruction rejects invalid width
00:00 +9: ShadowRuntimeRenderInstruction rejects invalid height
00:00 +10: ShadowRuntimeRenderInstruction rejects invalid opacity
00:00 +11: ShadowRuntimeRenderInstruction rejects non hard-edge softness in V0 if one appears later
00:00 +12: ShadowRuntimeRenderInstruction rejects projected polygons with fewer than three points
00:00 +13: ShadowRuntimeRenderInstruction rejects degenerate projected polygons
00:00 +14: ShadowRuntimeRenderInstruction rejects polygon points on oval shapes
00:00 +15: ShadowRuntimeRenderInstruction keeps polygon points immutable after construction
00:00 +16: ShadowRuntimeRenderInstruction has value equality and stable hashCode
00:00 +17: ShadowRuntimeRenderInstruction has value equality and stable hashCode for polygon points
00:00 +18: ShadowRuntimePoint creates a valid point
00:00 +19: ShadowRuntimePoint rejects non-finite coordinates
00:00 +20: ShadowRuntimePoint has value equality and stable hashCode
00:00 +21: shadowRuntimeShapeFromCasterMode maps contactBlob and ellipse
00:00 +22: shadowRuntimeShapeFromCasterMode rejects none because render instructions must be drawable
00:00 +23: All tests passed!
```

### `flutter test test/shadow/shadow_runtime_renderer_test.dart`

```text
00:00 +0: shadowRuntimeColorForInstruction converts RGB hex and opacity to runtime color
00:00 +1: shadowRuntimeColorForInstruction converts opacity zero to transparent color
00:00 +2: shadowRuntimeColorForInstruction uses stable rounded alpha for fractional opacity
00:00 +3: shadowRuntimePaintForInstruction creates a hard-edge fill paint
00:00 +4: shadowRuntimePaintForInstruction accepts hardEdge softness
00:00 +5: ShadowRuntimeRenderer.renderInstruction draws an ellipse with visible center and transparent outside pixels
00:00 +6: ShadowRuntimeRenderer.renderInstruction draws contactBlob through the same V0 oval path
00:00 +7: ShadowRuntimeRenderer.renderInstruction keeps opacity zero transparent at the center
00:00 +8: ShadowRuntimeRenderer.renderInstruction draws projectedPolygon with visible interior and transparent outside
00:00 +9: ShadowRuntimeRenderer.renderInstruction keeps projectedPolygon opacity zero transparent inside
00:00 +10: ShadowRuntimeRenderer.renderInstructions draws multiple instructions in input order
00:00 +11: ShadowRuntimeRenderer.renderInstructions draws projectedPolygon and ellipse in input order
00:00 +12: ShadowRuntimeRenderer.renderCollectionPass draws only groundStatic instructions for the groundStatic pass
00:00 +13: ShadowRuntimeRenderer.renderCollectionPass draws only actorContact instructions for the actorContact pass
00:00 +14: ShadowRuntimeRenderer.renderCollectionPass filters projectedPolygon instructions by render pass
00:00 +15: All tests passed!
```

## 15. Ligne finale exacte des tests globaux

```text
cd packages/map_runtime && flutter test test/shadow
00:04 +220: All tests passed!

cd packages/map_runtime && flutter test
00:16 +1141: All tests passed!

cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
00:00 +21: All tests passed!
```

## 16. Analyze

```text
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
No issues found! (ran in 2.2s)
```

## 17. Resultats des scans anti-derive

```text
find .. -name AGENTS.md -print
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

```text
git diff --name-only | rg -n "packages/map_editor|packages/map_gameplay|packages/map_battle"
aucune sortie
```

```text
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec"
aucune sortie
```

```text
git diff --name-only | rg -n "\.g\.dart|\.freezed\.dart"
aucune sortie
```

```text
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas"
aucune sortie
```

```text
git diff -U0 -- packages/map_runtime packages/map_core | rg -n "drawPath"
127:+    canvas.drawPath(path, shadowRuntimePaintForInstruction(instruction));
```

`drawPath` apparait uniquement dans `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`, ce qui est attendu pour Shadow-36.

```text
git diff --check
aucune sortie
```

## 18. git status initial

```text
?? reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer_plan.md
```

## 19. git status final

```text
 M packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
 M packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
 M packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
 M packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
?? reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer.md
?? reports/shadows/shadow_lot_36_runtime_projected_shadow_renderer_plan.md
```

## 20. git diff --stat

```text
 .../shadow/shadow_runtime_render_instruction.dart  |  85 ++++++++++++-
 .../lib/src/shadow/shadow_runtime_renderer.dart    |  26 ++++
 .../shadow_runtime_render_instruction_test.dart    | 134 +++++++++++++++++++++
 .../test/shadow/shadow_runtime_renderer_test.dart  | 101 ++++++++++++++++
 4 files changed, 344 insertions(+), 2 deletions(-)
```

## 21. git diff --name-status

```text
M	packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
M	packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
M	packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
M	packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
```

## 22. Non-objectifs respectes

- Aucun `map_editor`.
- Aucun `map_gameplay`.
- Aucun `map_battle`.
- Aucun modele persistant `map_core`.
- Aucun codec JSON.
- Aucun generated file.
- Aucun `build_runner`.
- Aucun `MapLayersComponent`.
- Aucun `PlayableMapGame`.
- Aucun nouveau Flame Component.
- Aucun `saveLayer`.
- Aucun `ImageFilter`.
- Aucun blur.
- Aucun atlas / sprite d'ombre.
- Aucun `zOrder` / `zIndex`.
- Aucune lumiere globale persistante.
- Aucune integration static placed.

## 23. Risques / reserves

- Le rendu visuel utilisateur ne change pas encore pour les objets statiques : Shadow-37 doit produire des instructions `projectedPolygon`.
- Les bounds `worldLeft/worldTop/width/height` restent obligatoires pour les polygons. Shadow-37 devra les calculer correctement depuis les points projetes.
- Le rendu reste hard-edge sans anti-aliasing, coherent avec le V0 pixel art, mais une future passe visuelle pourra juger si un adoucissement discret est necessaire.

## 24. Auto-review finale

```text
- Ai-je ajoute ShadowRuntimeShapeKind.projectedPolygon ? oui.
- Ai-je ajoute ShadowRuntimePoint ? oui.
- Ai-je ajoute polygonPoints a ShadowRuntimeRenderInstruction ? oui.
- Ai-je valide au moins 3 points et une aire non degeneree ? oui.
- Ai-je conserve drawOval pour ellipse/contactBlob ? oui.
- Ai-je rendu projectedPolygon via drawPath ? oui.
- Ai-je garde Paint.isAntiAlias false ? oui.
- Ai-je evite saveLayer / ImageFilter / blur ? oui.
- Ai-je evite de modifier map_editor ? oui.
- Ai-je evite de modifier map_core models/codecs ? oui.
- Ai-je evite de modifier static placed runtime integration ? oui.
- Ai-je evite toute lumiere globale persistante ? oui.
```

## 25. Regard critique sur le prompt / plan

Le plan Shadow-36 est bien borne. Il donne une brique utile mais non visible seule, ce qui peut etre frustrant apres les lots precedents. La separation reste toutefois correcte : si Shadow-36 avait aussi branche les static placed shadows, on aurait melange contrat de rendu et production de geometrie, avec plus de risque sur le runtime.

Point a surveiller pour Shadow-37 : calculer les bounds du polygone sans reintroduire une ellipse finale ni appliquer offset/scale deux fois.

## 26. Code complet des fichiers crees/modifies

### `packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart`

```dart
import 'package:map_core/map_core.dart';

import '../presentation/flame/shadow_runtime_render_order_contract.dart';

enum ShadowRuntimeShapeKind {
  contactBlob,
  ellipse,
  projectedPolygon,
}

final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

final class ShadowRuntimePoint {
  ShadowRuntimePoint({
    required this.worldX,
    required this.worldY,
  }) {
    _validateFinite(worldX, 'ShadowRuntimePoint.worldX');
    _validateFinite(worldY, 'ShadowRuntimePoint.worldY');
  }

  final double worldX;
  final double worldY;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimePoint &&
          other.worldX == worldX &&
          other.worldY == worldY;

  @override
  int get hashCode => Object.hash(worldX, worldY);
}

/// Pure runtime draw instruction for one resolved V0 shadow.
///
/// The rectangle is already expressed in world coordinates. This model does
/// not resolve map data, load images, or draw anything.
final class ShadowRuntimeRenderInstruction {
  ShadowRuntimeRenderInstruction({
    required this.shape,
    required this.renderPass,
    required this.worldLeft,
    required this.worldTop,
    required this.width,
    required this.height,
    required this.opacity,
    String colorHexRgb = '000000',
    this.softnessMode = ShadowSoftnessMode.hardEdge,
    Iterable<ShadowRuntimePoint> polygonPoints = const [],
  })  : colorHexRgb = _normalizeColorHexRgb(colorHexRgb),
        polygonPoints = List<ShadowRuntimePoint>.unmodifiable(polygonPoints) {
    _validateFinite(worldLeft, 'worldLeft');
    _validateFinite(worldTop, 'worldTop');
    _validatePositiveFinite(width, 'width');
    _validatePositiveFinite(height, 'height');
    _validateOpacity(opacity);
    _validateSoftnessMode(softnessMode);
    _validatePolygonPoints(shape, this.polygonPoints);
  }

  final ShadowRuntimeShapeKind shape;
  final ShadowRenderPass renderPass;
  final double worldLeft;
  final double worldTop;
  final double width;
  final double height;
  final double opacity;
  final String colorHexRgb;
  final ShadowSoftnessMode softnessMode;
  final List<ShadowRuntimePoint> polygonPoints;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ShadowRuntimeRenderInstruction &&
          other.shape == shape &&
          other.renderPass == renderPass &&
          other.worldLeft == worldLeft &&
          other.worldTop == worldTop &&
          other.width == width &&
          other.height == height &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb &&
          other.softnessMode == softnessMode &&
          _shadowRuntimePointsEqual(other.polygonPoints, polygonPoints);

  @override
  int get hashCode => Object.hash(
        shape,
        renderPass,
        worldLeft,
        worldTop,
        width,
        height,
        opacity,
        colorHexRgb,
        softnessMode,
        Object.hashAll(polygonPoints),
      );
}

ShadowRuntimeShapeKind shadowRuntimeShapeFromCasterMode(
  ShadowCasterMode mode,
) {
  return switch (mode) {
    ShadowCasterMode.contactBlob => ShadowRuntimeShapeKind.contactBlob,
    ShadowCasterMode.ellipse => ShadowRuntimeShapeKind.ellipse,
    ShadowCasterMode.none => throw const ValidationException(
        'ShadowCasterMode.none cannot produce a drawable runtime shadow shape',
      ),
  };
}

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForPass(
  ShadowRenderPass pass,
) {
  return switch (pass) {
    ShadowRenderPass.groundStatic =>
      RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
    ShadowRenderPass.actorContact =>
      RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
  };
}

RuntimeShadowRenderOrderSlot runtimeShadowRenderSlotForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) =>
    runtimeShadowRenderSlotForPass(instruction.renderPass);

String _normalizeColorHexRgb(String value) {
  if (!_colorHexRgbPattern.hasMatch(value)) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.colorHexRgb must be a 6-character RGB hex string without #',
    );
  }
  return value.toUpperCase();
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException(
      'ShadowRuntimeRenderInstruction.$name must be finite',
    );
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException(
      'ShadowRuntimeRenderInstruction.$name must be greater than 0',
    );
  }
}

void _validateOpacity(double value) {
  _validateFinite(value, 'opacity');
  if (value < 0 || value > 1) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.opacity must be between 0 and 1',
    );
  }
}

void _validateSoftnessMode(ShadowSoftnessMode value) {
  if (value != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderInstruction.softnessMode only supports hardEdge in V0',
    );
  }
}

void _validatePolygonPoints(
  ShadowRuntimeShapeKind shape,
  List<ShadowRuntimePoint> points,
) {
  switch (shape) {
    case ShadowRuntimeShapeKind.contactBlob:
    case ShadowRuntimeShapeKind.ellipse:
      if (points.isNotEmpty) {
        throw const ValidationException(
          'ShadowRuntimeRenderInstruction polygonPoints are only allowed for projectedPolygon',
        );
      }
    case ShadowRuntimeShapeKind.projectedPolygon:
      if (points.length < 3) {
        throw const ValidationException(
          'ShadowRuntimeRenderInstruction projectedPolygon requires at least 3 points',
        );
      }
      if (_polygonArea(points) <= 0) {
        throw const ValidationException(
          'ShadowRuntimeRenderInstruction projectedPolygon must be non-degenerate',
        );
      }
  }
}

double _polygonArea(List<ShadowRuntimePoint> points) {
  var area = 0.0;
  for (var i = 0; i < points.length; i += 1) {
    final current = points[i];
    final next = points[(i + 1) % points.length];
    area += current.worldX * next.worldY - next.worldX * current.worldY;
  }
  return area.abs() / 2;
}

bool _shadowRuntimePointsEqual(
  List<ShadowRuntimePoint> a,
  List<ShadowRuntimePoint> b,
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

### `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`

```dart
import 'dart:ui' as ui;

import 'package:map_core/map_core.dart';

import 'shadow_runtime_instruction_collection.dart';
import 'shadow_runtime_render_instruction.dart';

final class ShadowRuntimeRenderer {
  const ShadowRuntimeRenderer();

  void renderInstruction(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    _validateHardEdge(instruction);
    switch (instruction.shape) {
      case ShadowRuntimeShapeKind.contactBlob:
      case ShadowRuntimeShapeKind.ellipse:
        _renderOval(canvas, instruction);
      case ShadowRuntimeShapeKind.projectedPolygon:
        _renderProjectedPolygon(canvas, instruction);
    }
  }

  void _renderOval(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    final rect = ui.Rect.fromLTWH(
      instruction.worldLeft,
      instruction.worldTop,
      instruction.width,
      instruction.height,
    );
    canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
  }

  void _renderProjectedPolygon(
    ui.Canvas canvas,
    ShadowRuntimeRenderInstruction instruction,
  ) {
    final points = instruction.polygonPoints;
    final path = ui.Path()..moveTo(points.first.worldX, points.first.worldY);
    for (final point in points.skip(1)) {
      path.lineTo(point.worldX, point.worldY);
    }
    path.close();
    canvas.drawPath(path, shadowRuntimePaintForInstruction(instruction));
  }

  void renderInstructions(
    ui.Canvas canvas,
    Iterable<ShadowRuntimeRenderInstruction> instructions,
  ) {
    for (final instruction in instructions) {
      renderInstruction(canvas, instruction);
    }
  }

  void renderCollectionPass(
    ui.Canvas canvas,
    ShadowRuntimeInstructionCollection collection,
    ShadowRenderPass pass,
  ) {
    final instructions = switch (pass) {
      ShadowRenderPass.groundStatic => collection.groundStatic,
      ShadowRenderPass.actorContact => collection.actorContact,
    };
    renderInstructions(canvas, instructions);
  }
}

ui.Color shadowRuntimeColorForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  final rgb = int.parse(instruction.colorHexRgb, radix: 16);
  final alpha = (instruction.opacity * 255).round().clamp(0, 255).toInt();
  return ui.Color((alpha << 24) | rgb);
}

ui.Paint shadowRuntimePaintForInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  _validateHardEdge(instruction);
  return ui.Paint()
    ..style = ui.PaintingStyle.fill
    ..isAntiAlias = false
    ..color = shadowRuntimeColorForInstruction(instruction);
}

void _validateHardEdge(ShadowRuntimeRenderInstruction instruction) {
  if (instruction.softnessMode != ShadowSoftnessMode.hardEdge) {
    throw const ValidationException(
      'ShadowRuntimeRenderer only supports hardEdge shadows in V0',
    );
  }
}
```

### `packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart`

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('ShadowRuntimeRenderInstruction', () {
    test('creates a valid contact blob instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.contactBlob,
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.contactBlob);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.worldLeft, 12);
      expect(instruction.worldTop, 24);
      expect(instruction.width, 32);
      expect(instruction.height, 16);
      expect(instruction.opacity, 0.4);
    });

    test('creates a valid ellipse instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.ellipse,
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
    });

    test('creates a valid projected polygon instruction', () {
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        polygonPoints: _polygonPoints(),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.polygonPoints, _polygonPoints());
    });

    test('applies default color and softness', () {
      final instruction = _instruction();

      expect(instruction.colorHexRgb, '000000');
      expect(instruction.softnessMode, ShadowSoftnessMode.hardEdge);
    });

    test('accepts opacity bounds', () {
      expect(_instruction(opacity: 0).opacity, 0);
      expect(_instruction(opacity: 1).opacity, 1);
    });

    test('normalizes lowercase color to uppercase', () {
      final instruction = _instruction(colorHexRgb: '0a0b0c');

      expect(instruction.colorHexRgb, '0A0B0C');
    });

    test('rejects invalid colors', () {
      for (final color in <String>[
        '',
        '#000000',
        '00000',
        '0000000',
        'GGGGGG',
      ]) {
        expect(
          () => _instruction(colorHexRgb: color),
          throwsA(isA<ValidationException>()),
          reason: 'color $color should be rejected',
        );
      }
    });

    test('rejects non-finite world coordinates', () {
      expect(
        () => _instruction(worldLeft: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldLeft: double.infinity),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldTop: double.nan),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => _instruction(worldTop: double.infinity),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid width', () {
      for (final width in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(width: width),
          throwsA(isA<ValidationException>()),
          reason: 'width $width should be rejected',
        );
      }
    });

    test('rejects invalid height', () {
      for (final height in <double>[
        0,
        -1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(height: height),
          throwsA(isA<ValidationException>()),
          reason: 'height $height should be rejected',
        );
      }
    });

    test('rejects invalid opacity', () {
      for (final opacity in <double>[
        -0.1,
        1.1,
        double.nan,
        double.infinity,
      ]) {
        expect(
          () => _instruction(opacity: opacity),
          throwsA(isA<ValidationException>()),
          reason: 'opacity $opacity should be rejected',
        );
      }
    });

    test('rejects non hard-edge softness in V0 if one appears later', () {
      for (final softnessMode in ShadowSoftnessMode.values) {
        if (softnessMode == ShadowSoftnessMode.hardEdge) {
          expect(_instruction(softnessMode: softnessMode).softnessMode,
              ShadowSoftnessMode.hardEdge);
        } else {
          expect(
            () => _instruction(softnessMode: softnessMode),
            throwsA(isA<ValidationException>()),
          );
        }
      }
    });

    test('rejects projected polygons with fewer than three points', () {
      expect(
        () => _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          polygonPoints: _polygonPoints().take(2).toList(),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects degenerate projected polygons', () {
      expect(
        () => _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          polygonPoints: [
            ShadowRuntimePoint(worldX: 0, worldY: 0),
            ShadowRuntimePoint(worldX: 4, worldY: 4),
            ShadowRuntimePoint(worldX: 8, worldY: 8),
          ],
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects polygon points on oval shapes', () {
      for (final shape in <ShadowRuntimeShapeKind>[
        ShadowRuntimeShapeKind.contactBlob,
        ShadowRuntimeShapeKind.ellipse,
      ]) {
        expect(
          () => _instruction(shape: shape, polygonPoints: _polygonPoints()),
          throwsA(isA<ValidationException>()),
          reason: '$shape should not accept polygon points',
        );
      }
    });

    test('keeps polygon points immutable after construction', () {
      final points = _polygonPoints();
      final instruction = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        polygonPoints: points,
      );

      points.add(ShadowRuntimePoint(worldX: 24, worldY: 24));

      expect(instruction.polygonPoints, _polygonPoints());
      expect(
        () => instruction.polygonPoints.add(
          ShadowRuntimePoint(worldX: 32, worldY: 32),
        ),
        throwsUnsupportedError,
      );
    });

    test('has value equality and stable hashCode', () {
      final a = _instruction(colorHexRgb: '0a0b0c');
      final b = _instruction(colorHexRgb: '0A0B0C');
      final c = _instruction(opacity: 0.5);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('has value equality and stable hashCode for polygon points', () {
      final a = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        polygonPoints: _polygonPoints(),
      );
      final b = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        polygonPoints: _polygonPoints(),
      );
      final c = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        polygonPoints: [
          ShadowRuntimePoint(worldX: 0, worldY: 0),
          ShadowRuntimePoint(worldX: 12, worldY: 0),
          ShadowRuntimePoint(worldX: 16, worldY: 8),
          ShadowRuntimePoint(worldX: 4, worldY: 8),
        ],
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('ShadowRuntimePoint', () {
    test('creates a valid point', () {
      final point = ShadowRuntimePoint(worldX: 4, worldY: 8);

      expect(point.worldX, 4);
      expect(point.worldY, 8);
    });

    test('rejects non-finite coordinates', () {
      for (final value in <double>[double.nan, double.infinity]) {
        expect(
          () => ShadowRuntimePoint(worldX: value, worldY: 0),
          throwsA(isA<ValidationException>()),
          reason: 'worldX $value should be rejected',
        );
        expect(
          () => ShadowRuntimePoint(worldX: 0, worldY: value),
          throwsA(isA<ValidationException>()),
          reason: 'worldY $value should be rejected',
        );
      }
    });

    test('has value equality and stable hashCode', () {
      final a = ShadowRuntimePoint(worldX: 4, worldY: 8);
      final b = ShadowRuntimePoint(worldX: 4, worldY: 8);
      final c = ShadowRuntimePoint(worldX: 8, worldY: 4);

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });
  });

  group('shadowRuntimeShapeFromCasterMode', () {
    test('maps contactBlob and ellipse', () {
      expect(
        shadowRuntimeShapeFromCasterMode(ShadowCasterMode.contactBlob),
        ShadowRuntimeShapeKind.contactBlob,
      );
      expect(
        shadowRuntimeShapeFromCasterMode(ShadowCasterMode.ellipse),
        ShadowRuntimeShapeKind.ellipse,
      );
    });

    test('rejects none because render instructions must be drawable', () {
      expect(
        () => shadowRuntimeShapeFromCasterMode(ShadowCasterMode.none),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRuntimeShapeKind shape = ShadowRuntimeShapeKind.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 12,
  double worldTop = 24,
  double width = 32,
  double height = 16,
  double opacity = 0.4,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
  List<ShadowRuntimePoint> polygonPoints = const [],
}) {
  return ShadowRuntimeRenderInstruction(
    shape: shape,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
    polygonPoints: polygonPoints,
  );
}

List<ShadowRuntimePoint> _polygonPoints() {
  return [
    ShadowRuntimePoint(worldX: 0, worldY: 0),
    ShadowRuntimePoint(worldX: 16, worldY: 0),
    ShadowRuntimePoint(worldX: 20, worldY: 8),
    ShadowRuntimePoint(worldX: 2, worldY: 8),
  ];
}
```

### `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`

```dart
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('shadowRuntimeColorForInstruction', () {
    test('converts RGB hex and opacity to runtime color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 1),
      );

      expect(color, const ui.Color(0xFF336699));
    });

    test('converts opacity zero to transparent color', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '336699', opacity: 0),
      );

      expect(color, const ui.Color(0x00336699));
    });

    test('uses stable rounded alpha for fractional opacity', () {
      final color = shadowRuntimeColorForInstruction(
        _instruction(colorHexRgb: '000000', opacity: 0.35),
      );

      expect(color, const ui.Color(0x59000000));
    });
  });

  group('shadowRuntimePaintForInstruction', () {
    test('creates a hard-edge fill paint', () {
      final paint = shadowRuntimePaintForInstruction(_instruction());

      expect(paint.style, ui.PaintingStyle.fill);
      expect(paint.isAntiAlias, isFalse);
      expect(paint.color.toARGB32(), 0x59000000);
    });

    test('accepts hardEdge softness', () {
      expect(
        () => shadowRuntimePaintForInstruction(
          _instruction(softnessMode: ShadowSoftnessMode.hardEdge),
        ),
        returnsNormally,
      );
    });
  });

  group('ShadowRuntimeRenderer.renderInstruction', () {
    test('draws an ellipse with visible center and transparent outside pixels',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.ellipse,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('draws contactBlob through the same V0 oval path', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.contactBlob,
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps opacity zero transparent at the center', () async {
      final image = await _renderInstruction(
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 0,
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });

    test('draws projectedPolygon with visible interior and transparent outside',
        () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 1,
          polygonPoints: _polygonPoints(),
        ),
      );

      expect(await _alphaAt(image, 10, 8), greaterThan(0));
      expect(await _alphaAt(image, 1, 1), 0);
    });

    test('keeps projectedPolygon opacity zero transparent inside', () async {
      final image = await _renderInstruction(
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 0,
          polygonPoints: _polygonPoints(),
        ),
      );

      expect(await _alphaAt(image, 10, 8), 0);
    });
  });

  group('ShadowRuntimeRenderer.renderInstructions', () {
    test('draws multiple instructions in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
        ),
        _instruction(
          worldLeft: 2,
          worldTop: 2,
          width: 8,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 6, 6), _rgba(0, 0, 255, 255));
    });

    test('draws projectedPolygon and ellipse in input order', () async {
      final image = await _renderInstructions([
        _instruction(
          shape: ShadowRuntimeShapeKind.projectedPolygon,
          worldLeft: 2,
          worldTop: 4,
          width: 18,
          height: 8,
          opacity: 1,
          colorHexRgb: 'FF0000',
          polygonPoints: _polygonPoints(),
        ),
        _instruction(
          worldLeft: 4,
          worldTop: 4,
          width: 12,
          height: 8,
          opacity: 1,
          colorHexRgb: '0000FF',
        ),
      ]);

      expect(await _rgbaAt(image, 10, 8), _rgba(0, 0, 255, 255));
    });
  });

  group('ShadowRuntimeRenderer.renderCollectionPass', () {
    test('draws only groundStatic instructions for the groundStatic pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.groundStatic,
      );

      expect(await _alphaAt(image, 6, 6), greaterThan(0));
      expect(await _alphaAt(image, 18, 6), 0);
    });

    test('draws only actorContact instructions for the actorContact pass',
        () async {
      final ground = _instruction(
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 6, 6), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });

    test('filters projectedPolygon instructions by render pass', () async {
      final ground = _instruction(
        shape: ShadowRuntimeShapeKind.projectedPolygon,
        renderPass: ShadowRenderPass.groundStatic,
        worldLeft: 2,
        worldTop: 4,
        width: 18,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
        polygonPoints: _polygonPoints(),
      );
      final actor = _instruction(
        renderPass: ShadowRenderPass.actorContact,
        worldLeft: 14,
        worldTop: 2,
        width: 8,
        height: 8,
        opacity: 1,
        colorHexRgb: '000000',
      );

      final image = await _renderCollectionPass(
        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
        ShadowRenderPass.actorContact,
      );

      expect(await _alphaAt(image, 10, 8), 0);
      expect(await _alphaAt(image, 18, 6), greaterThan(0));
    });
  });
}

ShadowRuntimeRenderInstruction _instruction({
  ShadowRuntimeShapeKind shape = ShadowRuntimeShapeKind.ellipse,
  ShadowRenderPass renderPass = ShadowRenderPass.groundStatic,
  double worldLeft = 0,
  double worldTop = 0,
  double width = 8,
  double height = 4,
  double opacity = 0.35,
  String colorHexRgb = '000000',
  ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
  List<ShadowRuntimePoint> polygonPoints = const [],
}) {
  return ShadowRuntimeRenderInstruction(
    shape: shape,
    renderPass: renderPass,
    worldLeft: worldLeft,
    worldTop: worldTop,
    width: width,
    height: height,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
    softnessMode: softnessMode,
    polygonPoints: polygonPoints,
  );
}

List<ShadowRuntimePoint> _polygonPoints() {
  return [
    ShadowRuntimePoint(worldX: 4, worldY: 4),
    ShadowRuntimePoint(worldX: 16, worldY: 4),
    ShadowRuntimePoint(worldX: 20, worldY: 12),
    ShadowRuntimePoint(worldX: 2, worldY: 12),
  ];
}

Future<ui.Image> _renderInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  return _renderInstructions([instruction]);
}

Future<ui.Image> _renderInstructions(
  Iterable<ShadowRuntimeRenderInstruction> instructions,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderInstructions(canvas, instructions);
  return recorder.endRecording().toImage(24, 16);
}

Future<ui.Image> _renderCollectionPass(
  ShadowRuntimeInstructionCollection collection,
  ShadowRenderPass pass,
) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(canvas, collection, pass);
  return recorder.endRecording().toImage(24, 16);
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  return (await _rgbaAt(image, x, y))[3];
}

Future<List<int>> _rgbaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return [
    data!.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  ];
}

List<int> _rgba(int red, int green, int blue, int alpha) {
  return [red, green, blue, alpha];
}
```

## 27. Diffs complets

```diff
diff --git a/packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart b/packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
index 012a1706..395a5e2c 100644
--- a/packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
+++ b/packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
@@ -5,10 +5,34 @@ import '../presentation/flame/shadow_runtime_render_order_contract.dart';
 enum ShadowRuntimeShapeKind {
   contactBlob,
   ellipse,
+  projectedPolygon,
 }

 final _colorHexRgbPattern = RegExp(r'^[0-9a-fA-F]{6}$');

+final class ShadowRuntimePoint {
+  ShadowRuntimePoint({
+    required this.worldX,
+    required this.worldY,
+  }) {
+    _validateFinite(worldX, 'ShadowRuntimePoint.worldX');
+    _validateFinite(worldY, 'ShadowRuntimePoint.worldY');
+  }
+
+  final double worldX;
+  final double worldY;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ShadowRuntimePoint &&
+          other.worldX == worldX &&
+          other.worldY == worldY;
+
+  @override
+  int get hashCode => Object.hash(worldX, worldY);
+}
+
 /// Pure runtime draw instruction for one resolved V0 shadow.
 ///
 /// The rectangle is already expressed in world coordinates. This model does
@@ -24,13 +48,16 @@ final class ShadowRuntimeRenderInstruction {
     required this.opacity,
     String colorHexRgb = '000000',
     this.softnessMode = ShadowSoftnessMode.hardEdge,
-  }) : colorHexRgb = _normalizeColorHexRgb(colorHexRgb) {
+    Iterable<ShadowRuntimePoint> polygonPoints = const [],
+  })  : colorHexRgb = _normalizeColorHexRgb(colorHexRgb),
+        polygonPoints = List<ShadowRuntimePoint>.unmodifiable(polygonPoints) {
     _validateFinite(worldLeft, 'worldLeft');
     _validateFinite(worldTop, 'worldTop');
     _validatePositiveFinite(width, 'width');
     _validatePositiveFinite(height, 'height');
     _validateOpacity(opacity);
     _validateSoftnessMode(softnessMode);
+    _validatePolygonPoints(shape, this.polygonPoints);
   }

   final ShadowRuntimeShapeKind shape;
@@ -42,6 +69,7 @@ final class ShadowRuntimeRenderInstruction {
   final double opacity;
   final String colorHexRgb;
   final ShadowSoftnessMode softnessMode;
+  final List<ShadowRuntimePoint> polygonPoints;

   @override
   bool operator ==(Object other) =>
@@ -55,7 +83,8 @@ final class ShadowRuntimeRenderInstruction {
           other.height == height &&
           other.opacity == opacity &&
           other.colorHexRgb == colorHexRgb &&
-          other.softnessMode == softnessMode;
+          other.softnessMode == softnessMode &&
+          _shadowRuntimePointsEqual(other.polygonPoints, polygonPoints);

   @override
   int get hashCode => Object.hash(
@@ -68,6 +97,7 @@ final class ShadowRuntimeRenderInstruction {
         opacity,
         colorHexRgb,
         softnessMode,
+        Object.hashAll(polygonPoints),
       );
 }

@@ -141,3 +171,54 @@ void _validateSoftnessMode(ShadowSoftnessMode value) {
     );
   }
 }
+
+void _validatePolygonPoints(
+  ShadowRuntimeShapeKind shape,
+  List<ShadowRuntimePoint> points,
+) {
+  switch (shape) {
+    case ShadowRuntimeShapeKind.contactBlob:
+    case ShadowRuntimeShapeKind.ellipse:
+      if (points.isNotEmpty) {
+        throw const ValidationException(
+          'ShadowRuntimeRenderInstruction polygonPoints are only allowed for projectedPolygon',
+        );
+      }
+    case ShadowRuntimeShapeKind.projectedPolygon:
+      if (points.length < 3) {
+        throw const ValidationException(
+          'ShadowRuntimeRenderInstruction projectedPolygon requires at least 3 points',
+        );
+      }
+      if (_polygonArea(points) <= 0) {
+        throw const ValidationException(
+          'ShadowRuntimeRenderInstruction projectedPolygon must be non-degenerate',
+        );
+      }
+  }
+}
+
+double _polygonArea(List<ShadowRuntimePoint> points) {
+  var area = 0.0;
+  for (var i = 0; i < points.length; i += 1) {
+    final current = points[i];
+    final next = points[(i + 1) % points.length];
+    area += current.worldX * next.worldY - next.worldX * current.worldY;
+  }
+  return area.abs() / 2;
+}
+
+bool _shadowRuntimePointsEqual(
+  List<ShadowRuntimePoint> a,
+  List<ShadowRuntimePoint> b,
+) {
+  if (a.length != b.length) {
+    return false;
+  }
+  for (var i = 0; i < a.length; i += 1) {
+    if (a[i] != b[i]) {
+      return false;
+    }
+  }
+  return true;
+}
diff --git a/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart b/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
index 3ce9f3b5..dd5cf0f0 100644
--- a/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
+++ b/packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
@@ -13,6 +13,19 @@ final class ShadowRuntimeRenderer {
     ShadowRuntimeRenderInstruction instruction,
   ) {
     _validateHardEdge(instruction);
+    switch (instruction.shape) {
+      case ShadowRuntimeShapeKind.contactBlob:
+      case ShadowRuntimeShapeKind.ellipse:
+        _renderOval(canvas, instruction);
+      case ShadowRuntimeShapeKind.projectedPolygon:
+        _renderProjectedPolygon(canvas, instruction);
+    }
+  }
+
+  void _renderOval(
+    ui.Canvas canvas,
+    ShadowRuntimeRenderInstruction instruction,
+  ) {
     final rect = ui.Rect.fromLTWH(
       instruction.worldLeft,
       instruction.worldTop,
@@ -22,6 +35,19 @@ final class ShadowRuntimeRenderer {
     canvas.drawOval(rect, shadowRuntimePaintForInstruction(instruction));
   }

+  void _renderProjectedPolygon(
+    ui.Canvas canvas,
+    ShadowRuntimeRenderInstruction instruction,
+  ) {
+    final points = instruction.polygonPoints;
+    final path = ui.Path()..moveTo(points.first.worldX, points.first.worldY);
+    for (final point in points.skip(1)) {
+      path.lineTo(point.worldX, point.worldY);
+    }
+    path.close();
+    canvas.drawPath(path, shadowRuntimePaintForInstruction(instruction));
+  }
+
   void renderInstructions(
     ui.Canvas canvas,
     Iterable<ShadowRuntimeRenderInstruction> instructions,
```

```diff
diff --git a/packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart b/packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
index 15ee8313..7e91ad94 100644
--- a/packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
+++ b/packages/map_runtime/test/shadow/shadow_runtime_render_instruction_test.dart
@@ -26,6 +26,16 @@ void main() {
       expect(instruction.shape, ShadowRuntimeShapeKind.ellipse);
     });

+    test('creates a valid projected polygon instruction', () {
+      final instruction = _instruction(
+        shape: ShadowRuntimeShapeKind.projectedPolygon,
+        polygonPoints: _polygonPoints(),
+      );
+
+      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.polygonPoints, _polygonPoints());
+    });
+
     test('applies default color and softness', () {
       final instruction = _instruction();

@@ -138,6 +148,61 @@ void main() {
       }
     });

+    test('rejects projected polygons with fewer than three points', () {
+      expect(
+        () => _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          polygonPoints: _polygonPoints().take(2).toList(),
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects degenerate projected polygons', () {
+      expect(
+        () => _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          polygonPoints: [
+            ShadowRuntimePoint(worldX: 0, worldY: 0),
+            ShadowRuntimePoint(worldX: 4, worldY: 4),
+            ShadowRuntimePoint(worldX: 8, worldY: 8),
+          ],
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects polygon points on oval shapes', () {
+      for (final shape in <ShadowRuntimeShapeKind>[
+        ShadowRuntimeShapeKind.contactBlob,
+        ShadowRuntimeShapeKind.ellipse,
+      ]) {
+        expect(
+          () => _instruction(shape: shape, polygonPoints: _polygonPoints()),
+          throwsA(isA<ValidationException>()),
+          reason: '$shape should not accept polygon points',
+        );
+      }
+    });
+
+    test('keeps polygon points immutable after construction', () {
+      final points = _polygonPoints();
+      final instruction = _instruction(
+        shape: ShadowRuntimeShapeKind.projectedPolygon,
+        polygonPoints: points,
+      );
+
+      points.add(ShadowRuntimePoint(worldX: 24, worldY: 24));
+
+      expect(instruction.polygonPoints, _polygonPoints());
+      expect(
+        () => instruction.polygonPoints.add(
+          ShadowRuntimePoint(worldX: 32, worldY: 32),
+        ),
+        throwsUnsupportedError,
+      );
+    });
+
     test('has value equality and stable hashCode', () {
       final a = _instruction(colorHexRgb: '0a0b0c');
       final b = _instruction(colorHexRgb: '0A0B0C');
@@ -147,6 +212,64 @@ void main() {
       expect(a.hashCode, b.hashCode);
       expect(a, isNot(c));
     });
+
+    test('has value equality and stable hashCode for polygon points', () {
+      final a = _instruction(
+        shape: ShadowRuntimeShapeKind.projectedPolygon,
+        polygonPoints: _polygonPoints(),
+      );
+      final b = _instruction(
+        shape: ShadowRuntimeShapeKind.projectedPolygon,
+        polygonPoints: _polygonPoints(),
+      );
+      final c = _instruction(
+        shape: ShadowRuntimeShapeKind.projectedPolygon,
+        polygonPoints: [
+          ShadowRuntimePoint(worldX: 0, worldY: 0),
+          ShadowRuntimePoint(worldX: 12, worldY: 0),
+          ShadowRuntimePoint(worldX: 16, worldY: 8),
+          ShadowRuntimePoint(worldX: 4, worldY: 8),
+        ],
+      );
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
+  });
+
+  group('ShadowRuntimePoint', () {
+    test('creates a valid point', () {
+      final point = ShadowRuntimePoint(worldX: 4, worldY: 8);
+
+      expect(point.worldX, 4);
+      expect(point.worldY, 8);
+    });
+
+    test('rejects non-finite coordinates', () {
+      for (final value in <double>[double.nan, double.infinity]) {
+        expect(
+          () => ShadowRuntimePoint(worldX: value, worldY: 0),
+          throwsA(isA<ValidationException>()),
+          reason: 'worldX $value should be rejected',
+        );
+        expect(
+          () => ShadowRuntimePoint(worldX: 0, worldY: value),
+          throwsA(isA<ValidationException>()),
+          reason: 'worldY $value should be rejected',
+        );
+      }
+    });
+
+    test('has value equality and stable hashCode', () {
+      final a = ShadowRuntimePoint(worldX: 4, worldY: 8);
+      final b = ShadowRuntimePoint(worldX: 4, worldY: 8);
+      final c = ShadowRuntimePoint(worldX: 8, worldY: 4);
+
+      expect(a, b);
+      expect(a.hashCode, b.hashCode);
+      expect(a, isNot(c));
+    });
   });

   group('shadowRuntimeShapeFromCasterMode', () {
@@ -180,6 +303,7 @@ ShadowRuntimeRenderInstruction _instruction({
   double opacity = 0.4,
   String colorHexRgb = '000000',
   ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
+  List<ShadowRuntimePoint> polygonPoints = const [],
 }) {
   return ShadowRuntimeRenderInstruction(
     shape: shape,
@@ -191,5 +315,15 @@ ShadowRuntimeRenderInstruction _instruction({
     opacity: opacity,
     colorHexRgb: colorHexRgb,
     softnessMode: softnessMode,
+    polygonPoints: polygonPoints,
   );
 }
+
+List<ShadowRuntimePoint> _polygonPoints() {
+  return [
+    ShadowRuntimePoint(worldX: 0, worldY: 0),
+    ShadowRuntimePoint(worldX: 16, worldY: 0),
+    ShadowRuntimePoint(worldX: 20, worldY: 8),
+    ShadowRuntimePoint(worldX: 2, worldY: 8),
+  ];
+}
diff --git a/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart b/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
index d8e8d6a0..a413a81b 100644
--- a/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
+++ b/packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
@@ -101,6 +101,40 @@ void main() {

       expect(await _alphaAt(image, 10, 8), 0);
     });
+
+    test('draws projectedPolygon with visible interior and transparent outside',
+        () async {
+      final image = await _renderInstruction(
+        _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          worldLeft: 2,
+          worldTop: 4,
+          width: 18,
+          height: 8,
+          opacity: 1,
+          polygonPoints: _polygonPoints(),
+        ),
+      );
+
+      expect(await _alphaAt(image, 10, 8), greaterThan(0));
+      expect(await _alphaAt(image, 1, 1), 0);
+    });
+
+    test('keeps projectedPolygon opacity zero transparent inside', () async {
+      final image = await _renderInstruction(
+        _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          worldLeft: 2,
+          worldTop: 4,
+          width: 18,
+          height: 8,
+          opacity: 0,
+          polygonPoints: _polygonPoints(),
+        ),
+      );
+
+      expect(await _alphaAt(image, 10, 8), 0);
+    });
   });

   group('ShadowRuntimeRenderer.renderInstructions', () {
@@ -126,6 +160,31 @@ void main() {

       expect(await _rgbaAt(image, 6, 6), _rgba(0, 0, 255, 255));
     });
+
+    test('draws projectedPolygon and ellipse in input order', () async {
+      final image = await _renderInstructions([
+        _instruction(
+          shape: ShadowRuntimeShapeKind.projectedPolygon,
+          worldLeft: 2,
+          worldTop: 4,
+          width: 18,
+          height: 8,
+          opacity: 1,
+          colorHexRgb: 'FF0000',
+          polygonPoints: _polygonPoints(),
+        ),
+        _instruction(
+          worldLeft: 4,
+          worldTop: 4,
+          width: 12,
+          height: 8,
+          opacity: 1,
+          colorHexRgb: '0000FF',
+        ),
+      ]);
+
+      expect(await _rgbaAt(image, 10, 8), _rgba(0, 0, 255, 255));
+    });
   });

   group('ShadowRuntimeRenderer.renderCollectionPass', () {
@@ -188,6 +247,37 @@ void main() {
       expect(await _alphaAt(image, 6, 6), 0);
       expect(await _alphaAt(image, 18, 6), greaterThan(0));
     });
+
+    test('filters projectedPolygon instructions by render pass', () async {
+      final ground = _instruction(
+        shape: ShadowRuntimeShapeKind.projectedPolygon,
+        renderPass: ShadowRenderPass.groundStatic,
+        worldLeft: 2,
+        worldTop: 4,
+        width: 18,
+        height: 8,
+        opacity: 1,
+        colorHexRgb: '000000',
+        polygonPoints: _polygonPoints(),
+      );
+      final actor = _instruction(
+        renderPass: ShadowRenderPass.actorContact,
+        worldLeft: 14,
+        worldTop: 2,
+        width: 8,
+        height: 8,
+        opacity: 1,
+        colorHexRgb: '000000',
+      );
+
+      final image = await _renderCollectionPass(
+        ShadowRuntimeInstructionCollection(instructions: [ground, actor]),
+        ShadowRenderPass.actorContact,
+      );
+
+      expect(await _alphaAt(image, 10, 8), 0);
+      expect(await _alphaAt(image, 18, 6), greaterThan(0));
+    });
   });
 }

@@ -201,6 +291,7 @@ ShadowRuntimeRenderInstruction _instruction({
   double opacity = 0.35,
   String colorHexRgb = '000000',
   ShadowSoftnessMode softnessMode = ShadowSoftnessMode.hardEdge,
+  List<ShadowRuntimePoint> polygonPoints = const [],
 }) {
   return ShadowRuntimeRenderInstruction(
     shape: shape,
@@ -212,9 +303,19 @@ ShadowRuntimeRenderInstruction _instruction({
     opacity: opacity,
     colorHexRgb: colorHexRgb,
     softnessMode: softnessMode,
+    polygonPoints: polygonPoints,
   );
 }

+List<ShadowRuntimePoint> _polygonPoints() {
+  return [
+    ShadowRuntimePoint(worldX: 4, worldY: 4),
+    ShadowRuntimePoint(worldX: 16, worldY: 4),
+    ShadowRuntimePoint(worldX: 20, worldY: 12),
+    ShadowRuntimePoint(worldX: 2, worldY: 12),
+  ];
+}
+
 Future<ui.Image> _renderInstruction(
   ShadowRuntimeRenderInstruction instruction,
 ) {
```
