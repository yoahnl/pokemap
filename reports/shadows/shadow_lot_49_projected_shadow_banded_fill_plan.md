# Shadow-49 — Projected Shadow Banded Fill / Pixel-Art Softening V0 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` (recommended) or `superpowers:executing-plans` to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** make projected static shadows look less like hard translucent slabs by rendering them as stable pixel-art opacity bands in runtime and editor preview.

**Architecture:** keep the current projected polygon geometry and render order, but change how projected polygons are filled. `map_core` provides a pure opacity-band contract. `map_runtime` and `map_editor` consume the same band contract when painting projected polygons with `Canvas.drawPath`, without blur, `saveLayer`, image filters, new Flame components, or model changes.

**Tech Stack:** Dart, Flutter `dart:ui.Canvas`, existing `ShadowRuntimeRenderer`, existing `EditorStaticShadowPreviewPainter`, pure `map_core` projection helpers.

---

## 1. Pourquoi ce lot

Shadow-35 à Shadow-48 ont construit une vraie chaîne :

```text
footprint -> family -> projected polygon -> runtime/editor rendering -> auto policy applied in runtime
```

Mais le rendu visible reste dur parce que le renderer remplit chaque projected polygon d’un seul aplat alpha :

```dart
canvas.drawPath(path, paint);
```

Sur un sol texturé, un grand polygone alpha uniforme lit visuellement comme une plaque posée sur la carte. C’est une des raisons pour lesquelles les captures restent peu naturelles même après les corrections géométriques.

Shadow-49 doit donc améliorer le rendu sans réouvrir les modèles persistants :

```text
un polygone projeté devient N bandes trapézoïdales,
avec une opacité plus forte près de l’objet et plus faible au bout de l’ombre.
```

Ce n’est pas du blur. Ce n’est pas une lumière globale. C’est un fill pixel-art déterministe, testable, compatible avec Flame/Canvas existant.

## 2. Documentation Flame

Le serveur `flame_docs` a été consulté avant ce plan, conformément à `AGENTS.md`, avec :

```text
Flame Canvas render drawPath drawOval component priority
Component priority render order
rendering canvas
```

Résultat :

```text
No results found
```

Décision : ce lot ne doit pas inventer d’API Flame. Il ne touche pas aux `Component`, au `GameWidget`, aux priorités Flame, ni aux couches. Il reste dans le renderer existant, qui utilise déjà `dart:ui.Canvas`.

## 3. Périmètre autorisé

Créer :

```text
reports/shadows/shadow_lot_49_projected_shadow_banded_fill.md
```

Modifier :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Modifier seulement si l’audit révèle une nécessité stricte :

```text
packages/map_core/lib/map_core.dart
```

Normalement ce fichier n’a pas besoin de changer, car `static_shadow_projection_geometry.dart` est déjà exporté.

## 4. Périmètre interdit

Ne pas modifier :

```text
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/project_element_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/map_placed_element_shadow_override_json_codec.dart
packages/map_core/lib/src/operations/static_shadow_footprint_config_json_codec.dart
packages/map_runtime/lib/src/presentation/flame/**
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_editor/lib/src/features/editor/state/**
packages/map_editor/lib/src/ui/canvas/map_canvas/**
packages/map_gameplay/**
packages/map_battle/**
examples/playable_runtime_host/**
```

Ne pas créer :

```text
Shadow Studio
nouveau renderer global
nouveau Flame Component
lumière globale
time-of-day
WorldLightState
ShadowLightProfile
LightDirection
blur
saveLayer
ImageFilter
sprite shadow atlas
zOrder / zIndex
build_runner
migration JSON
```

Ne pas faire :

```text
changer la géométrie projetée
changer la politique auto-shadow
changer les modèles persistants
changer le runtime load policy Shadow-48
```

## 5. Design retenu

### 5.1 Core opacity bands

Ajouter dans :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
```

un value object pur :

```dart
final class ProjectedStaticShadowOpacityBand {
  ProjectedStaticShadowOpacityBand({
    required this.startT,
    required this.endT,
    required this.opacityScale,
  }) {
    _validateBandT(startT, 'ProjectedStaticShadowOpacityBand.startT');
    _validateBandT(endT, 'ProjectedStaticShadowOpacityBand.endT');
    if (endT <= startT) {
      throw const ValidationException(
        'ProjectedStaticShadowOpacityBand.endT must be greater than startT',
      );
    }
    _validatePositiveFinite(
      opacityScale,
      'ProjectedStaticShadowOpacityBand.opacityScale',
    );
    if (opacityScale > 1) {
      throw const ValidationException(
        'ProjectedStaticShadowOpacityBand.opacityScale must be <= 1',
      );
    }
  }

  final double startT;
  final double endT;
  final double opacityScale;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedStaticShadowOpacityBand &&
          other.startT == startT &&
          other.endT == endT &&
          other.opacityScale == opacityScale;

  @override
  int get hashCode => Object.hash(startT, endT, opacityScale);
}
```

Ajouter les constantes :

```dart
const defaultProjectedStaticShadowFillBandCount = 7;
const defaultProjectedStaticShadowNearOpacityScale = 1.0;
const defaultProjectedStaticShadowFarOpacityScale = 0.34;
```

Ajouter la fonction pure :

```dart
List<ProjectedStaticShadowOpacityBand> createProjectedStaticShadowOpacityBands({
  int bandCount = defaultProjectedStaticShadowFillBandCount,
  double nearOpacityScale = defaultProjectedStaticShadowNearOpacityScale,
  double farOpacityScale = defaultProjectedStaticShadowFarOpacityScale,
}) {
  if (bandCount <= 0) {
    throw const ValidationException(
      'Projected static shadow bandCount must be greater than 0',
    );
  }
  _validatePositiveFinite(
    nearOpacityScale,
    'Projected static shadow nearOpacityScale',
  );
  _validatePositiveFinite(
    farOpacityScale,
    'Projected static shadow farOpacityScale',
  );
  if (nearOpacityScale > 1 || farOpacityScale > 1) {
    throw const ValidationException(
      'Projected static shadow opacity scales must be <= 1',
    );
  }
  if (farOpacityScale > nearOpacityScale) {
    throw const ValidationException(
      'Projected static shadow farOpacityScale must be <= nearOpacityScale',
    );
  }

  final bands = <ProjectedStaticShadowOpacityBand>[];
  for (var index = 0; index < bandCount; index += 1) {
    final startT = index / bandCount;
    final endT = (index + 1) / bandCount;
    final midT = (startT + endT) / 2;
    final opacityScale =
        nearOpacityScale + (farOpacityScale - nearOpacityScale) * midT;
    bands.add(
      ProjectedStaticShadowOpacityBand(
        startT: startT,
        endT: endT,
        opacityScale: opacityScale,
      ),
    );
  }
  return List<ProjectedStaticShadowOpacityBand>.unmodifiable(bands);
}
```

Ajouter :

```dart
void _validateBandT(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}
```

### 5.2 Runtime banded projected polygon rendering

Dans :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
```

remplacer seulement le chemin projected polygon :

```dart
void _renderProjectedPolygon(
  ui.Canvas canvas,
  ShadowRuntimeRenderInstruction instruction,
) {
  final points = instruction.polygonPoints;
  if (points.length != 4) {
    final path = _pathFromRuntimePoints(points);
    canvas.drawPath(path, shadowRuntimePaintForInstruction(instruction));
    return;
  }
  for (final band in createProjectedStaticShadowOpacityBands()) {
    final path = _projectedRuntimeBandPath(points, band);
    final paint = shadowRuntimePaintForInstruction(
      _instructionWithOpacityScale(instruction, band.opacityScale),
    );
    canvas.drawPath(path, paint);
  }
}
```

Ajouter des helpers privés :

```dart
ui.Path _pathFromRuntimePoints(List<ShadowRuntimePoint> points) {
  final path = ui.Path()
    ..moveTo(points.first.worldX, points.first.worldY);
  for (final point in points.skip(1)) {
    path.lineTo(point.worldX, point.worldY);
  }
  return path..close();
}

ui.Path _projectedRuntimeBandPath(
  List<ShadowRuntimePoint> points,
  ProjectedStaticShadowOpacityBand band,
) {
  final nearLeft = points[0];
  final nearRight = points[1];
  final farRight = points[2];
  final farLeft = points[3];
  final leftStart = _lerpRuntimePoint(nearLeft, farLeft, band.startT);
  final rightStart = _lerpRuntimePoint(nearRight, farRight, band.startT);
  final rightEnd = _lerpRuntimePoint(nearRight, farRight, band.endT);
  final leftEnd = _lerpRuntimePoint(nearLeft, farLeft, band.endT);
  return ui.Path()
    ..moveTo(leftStart.worldX, leftStart.worldY)
    ..lineTo(rightStart.worldX, rightStart.worldY)
    ..lineTo(rightEnd.worldX, rightEnd.worldY)
    ..lineTo(leftEnd.worldX, leftEnd.worldY)
    ..close();
}

ShadowRuntimePoint _lerpRuntimePoint(
  ShadowRuntimePoint a,
  ShadowRuntimePoint b,
  double t,
) {
  return ShadowRuntimePoint(
    worldX: a.worldX + (b.worldX - a.worldX) * t,
    worldY: a.worldY + (b.worldY - a.worldY) * t,
  );
}

ShadowRuntimeRenderInstruction _instructionWithOpacityScale(
  ShadowRuntimeRenderInstruction instruction,
  double opacityScale,
) {
  return ShadowRuntimeRenderInstruction(
    shape: instruction.shape,
    renderPass: instruction.renderPass,
    worldLeft: instruction.worldLeft,
    worldTop: instruction.worldTop,
    width: instruction.width,
    height: instruction.height,
    opacity: instruction.opacity * opacityScale,
    colorHexRgb: instruction.colorHexRgb,
    softnessMode: instruction.softnessMode,
    polygonPoints: instruction.polygonPoints,
  );
}
```

Important :

```text
ellipse/contactBlob restent inchangés.
projectedPolygon garde isAntiAlias false.
pas de saveLayer.
pas de ImageFilter.
pas de blur.
```

### 5.3 Editor painter banded projected polygon rendering

Dans :

```text
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

faire le même traitement pour `EditorStaticShadowPreviewShapeKind.projectedPolygon`, en utilisant les mêmes `ProjectedStaticShadowOpacityBand` de `map_core`.

Ajouter :

```dart
import 'package:map_core/map_core.dart';
```

Remplacer le draw unique par :

```dart
case EditorStaticShadowPreviewShapeKind.projectedPolygon:
  if (instruction.polygonPoints.length != 4) {
    final path = _pathFromEditorStaticShadowPreviewPoints(
      instruction.polygonPoints,
    );
    if (path != null) {
      canvas.drawPath(path, paint);
    }
    continue;
  }
  for (final band in createProjectedStaticShadowOpacityBands()) {
    final color = _editorShadowPreviewColor(
      instruction.colorHexRgb,
      instruction.opacity * band.opacityScale,
    );
    if (color == null) {
      continue;
    }
    final bandPaint = ui.Paint()
      ..color = color
      ..style = ui.PaintingStyle.fill
      ..isAntiAlias = false;
    canvas.drawPath(
      _projectedEditorBandPath(instruction.polygonPoints, band),
      bandPaint,
    );
  }
```

Ajouter les helpers privés :

```dart
ui.Path _projectedEditorBandPath(
  List<EditorStaticShadowPreviewPoint> points,
  ProjectedStaticShadowOpacityBand band,
) {
  final nearLeft = points[0];
  final nearRight = points[1];
  final farRight = points[2];
  final farLeft = points[3];
  final leftStart = _lerpEditorPoint(nearLeft, farLeft, band.startT);
  final rightStart = _lerpEditorPoint(nearRight, farRight, band.startT);
  final rightEnd = _lerpEditorPoint(nearRight, farRight, band.endT);
  final leftEnd = _lerpEditorPoint(nearLeft, farLeft, band.endT);
  return ui.Path()
    ..moveTo(leftStart.x, leftStart.y)
    ..lineTo(rightStart.x, rightStart.y)
    ..lineTo(rightEnd.x, rightEnd.y)
    ..lineTo(leftEnd.x, leftEnd.y)
    ..close();
}

EditorStaticShadowPreviewPoint _lerpEditorPoint(
  EditorStaticShadowPreviewPoint a,
  EditorStaticShadowPreviewPoint b,
  double t,
) {
  return EditorStaticShadowPreviewPoint(
    x: a.x + (b.x - a.x) * t,
    y: a.y + (b.y - a.y) * t,
  );
}
```

## 6. Tâches détaillées

### Task 1 — RED core opacity band tests

**Files:**

- Modify: `packages/map_core/test/shadow/static_shadow_projection_geometry_test.dart`

- [ ] Add tests under a new group `ProjectedStaticShadowOpacityBand`.

```dart
group('ProjectedStaticShadowOpacityBand', () {
  test('default opacity bands are stable and fade toward the far edge', () {
    final bands = createProjectedStaticShadowOpacityBands();

    expect(bands, hasLength(7));
    expect(bands.first.startT, 0);
    expect(bands.last.endT, 1);
    expect(bands.first.opacityScale, greaterThan(bands.last.opacityScale));
    expect(bands.last.opacityScale, closeTo(0.3871428571, 0.000001));
    expect(() => bands.add(bands.first), throwsUnsupportedError);
  });

  test('custom opacity bands cover 0..1 without overlap', () {
    final bands = createProjectedStaticShadowOpacityBands(
      bandCount: 4,
      nearOpacityScale: 0.8,
      farOpacityScale: 0.2,
    );

    expect(
      bands.map((band) => [band.startT, band.endT]),
      [
        [0.0, 0.25],
        [0.25, 0.5],
        [0.5, 0.75],
        [0.75, 1.0],
      ],
    );
    expect(bands.first.opacityScale, closeTo(0.725, 0.000001));
    expect(bands.last.opacityScale, closeTo(0.275, 0.000001));
  });

  test('rejects invalid opacity band inputs', () {
    expect(
      () => createProjectedStaticShadowOpacityBands(bandCount: 0),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createProjectedStaticShadowOpacityBands(nearOpacityScale: 1.2),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createProjectedStaticShadowOpacityBands(farOpacityScale: 1.2),
      throwsA(isA<ValidationException>()),
    );
    expect(
      () => createProjectedStaticShadowOpacityBands(
        nearOpacityScale: 0.2,
        farOpacityScale: 0.8,
      ),
      throwsA(isA<ValidationException>()),
    );
  });

  test('opacity band equality includes all fields', () {
    final first = ProjectedStaticShadowOpacityBand(
      startT: 0,
      endT: 0.5,
      opacityScale: 0.8,
    );
    final same = ProjectedStaticShadowOpacityBand(
      startT: 0,
      endT: 0.5,
      opacityScale: 0.8,
    );
    final different = ProjectedStaticShadowOpacityBand(
      startT: 0.5,
      endT: 1,
      opacityScale: 0.4,
    );

    expect(first, same);
    expect(first.hashCode, same.hashCode);
    expect(first, isNot(different));
  });
});
```

- [ ] Run RED:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
```

Expected:

```text
FAIL: Method not found: createProjectedStaticShadowOpacityBands
```

### Task 2 — Implement core opacity bands

**Files:**

- Modify: `packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart`

- [ ] Add `ProjectedStaticShadowOpacityBand`, constants, `createProjectedStaticShadowOpacityBands(...)`, and `_validateBandT(...)` exactly as described in section 5.1.

- [ ] Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart analyze lib test/shadow
```

Expected:

```text
All tests passed!
No issues found!
```

### Task 3 — RED runtime renderer band tests

**Files:**

- Modify: `packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart`

- [ ] Add tests in `ShadowRuntimeRenderer.renderInstruction`.

```dart
test('draws projectedPolygon with stronger near alpha than far alpha',
    () async {
  final image = await _renderInstruction(
    _instruction(
      shape: ShadowRuntimeShapeKind.projectedPolygon,
      worldLeft: 6,
      worldTop: 6,
      width: 28,
      height: 30,
      opacity: 1,
      polygonPoints: [
        ShadowRuntimePoint(worldX: 10, worldY: 10),
        ShadowRuntimePoint(worldX: 26, worldY: 10),
        ShadowRuntimePoint(worldX: 34, worldY: 34),
        ShadowRuntimePoint(worldX: 6, worldY: 34),
      ],
    ),
    width: 48,
    height: 48,
  );

  final nearAlpha = await _alphaAt(image, 18, 12);
  final farAlpha = await _alphaAt(image, 20, 32);

  expect(nearAlpha, greaterThan(farAlpha));
  expect(farAlpha, greaterThan(0));
});

test('projectedPolygon fallback still draws non four point polygons', () async {
  final image = await _renderInstruction(
    _instruction(
      shape: ShadowRuntimeShapeKind.projectedPolygon,
      worldLeft: 6,
      worldTop: 6,
      width: 28,
      height: 30,
      opacity: 1,
      polygonPoints: [
        ShadowRuntimePoint(worldX: 10, worldY: 10),
        ShadowRuntimePoint(worldX: 26, worldY: 10),
        ShadowRuntimePoint(worldX: 34, worldY: 22),
        ShadowRuntimePoint(worldX: 26, worldY: 34),
        ShadowRuntimePoint(worldX: 6, worldY: 34),
      ],
    ),
    width: 48,
    height: 48,
  );

  expect(await _alphaAt(image, 20, 20), greaterThan(0));
});
```

If `_renderInstruction` currently lacks optional canvas dimensions, extend it:

```dart
Future<ui.Image> _renderInstruction(
  ShadowRuntimeRenderInstruction instruction, {
  int width = 24,
  int height = 24,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderInstruction(canvas, instruction);
  final picture = recorder.endRecording();
  final image = await picture.toImage(width, height);
  picture.dispose();
  return image;
}
```

- [ ] Run RED:

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
```

Expected:

```text
FAIL: nearAlpha equals farAlpha under the current one-path fill
```

### Task 4 — Implement runtime banded fill

**Files:**

- Modify: `packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart`

- [ ] Implement the runtime painter changes from section 5.2.

- [ ] Keep `shadowRuntimePaintForInstruction(...)` unchanged for ovals and contact blobs.

- [ ] Run:

```bash
cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow
```

Expected:

```text
All tests passed!
No issues found!
```

### Task 5 — RED editor painter band tests

**Files:**

- Modify: `packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart`

- [ ] Add tests in `paintEditorStaticShadowPreviewInstructions`.

```dart
test('projected polygon preview has stronger near alpha than far alpha',
    () async {
  final near = await _paintAndReadPixel(
    _projectedInstruction(
      polygonPoints: [
        EditorStaticShadowPreviewPoint(x: 10, y: 10),
        EditorStaticShadowPreviewPoint(x: 26, y: 10),
        EditorStaticShadowPreviewPoint(x: 34, y: 34),
        EditorStaticShadowPreviewPoint(x: 6, y: 34),
      ],
      opacity: 1,
    ),
    x: 18,
    y: 12,
  );
  final far = await _paintAndReadPixel(
    _projectedInstruction(
      polygonPoints: [
        EditorStaticShadowPreviewPoint(x: 10, y: 10),
        EditorStaticShadowPreviewPoint(x: 26, y: 10),
        EditorStaticShadowPreviewPoint(x: 34, y: 34),
        EditorStaticShadowPreviewPoint(x: 6, y: 34),
      ],
      opacity: 1,
    ),
    x: 20,
    y: 32,
  );

  expect(near.alpha, greaterThan(far.alpha));
  expect(far.alpha, greaterThan(0));
});

test('projected polygon preview fallback draws non four point polygons',
    () async {
  final pixel = await _paintAndReadPixel(
    _projectedInstruction(
      polygonPoints: [
        EditorStaticShadowPreviewPoint(x: 10, y: 10),
        EditorStaticShadowPreviewPoint(x: 26, y: 10),
        EditorStaticShadowPreviewPoint(x: 34, y: 22),
        EditorStaticShadowPreviewPoint(x: 26, y: 34),
        EditorStaticShadowPreviewPoint(x: 6, y: 34),
      ],
      opacity: 1,
    ),
    x: 20,
    y: 20,
  );

  expect(pixel.alpha, greaterThan(0));
});
```

Update `_projectedInstruction` to accept custom points:

```dart
EditorStaticShadowPreviewInstruction _projectedInstruction({
  double opacity = 0.5,
  List<EditorStaticShadowPreviewPoint>? polygonPoints,
}) {
  return EditorStaticShadowPreviewInstruction(
    instanceId: 'stand_1',
    elementId: 'stand',
    shape: EditorStaticShadowPreviewShapeKind.projectedPolygon,
    left: 8,
    top: 8,
    width: 28,
    height: 30,
    opacity: opacity,
    colorHexRgb: '000000',
    polygonPoints: polygonPoints ??
        [
          EditorStaticShadowPreviewPoint(x: 10, y: 12),
          EditorStaticShadowPreviewPoint(x: 24, y: 10),
          EditorStaticShadowPreviewPoint(x: 34, y: 28),
          EditorStaticShadowPreviewPoint(x: 12, y: 26),
        ],
  );
}
```

- [ ] Run RED:

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Expected:

```text
FAIL: near alpha equals far alpha under the current one-path fill
```

### Task 6 — Implement editor banded fill

**Files:**

- Modify: `packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart`

- [ ] Implement the editor painter changes from section 5.3.

- [ ] Keep oval rendering unchanged.

- [ ] Run:

```bash
cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter analyze lib/src/ui/canvas/shadow test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Expected:

```text
All tests passed!
No issues found!
```

### Task 7 — Regression matrix

Run:

```bash
cd packages/map_core && dart test test/shadow/static_shadow_projection_geometry_test.dart
cd packages/map_core && dart test test/shadow
cd packages/map_core && dart analyze lib test/shadow

cd packages/map_runtime && flutter test test/shadow/shadow_runtime_renderer_test.dart
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter analyze lib/src/shadow test/shadow

cd packages/map_editor && flutter test test/ui/canvas/editor_static_shadow_preview_painter_test.dart
cd packages/map_editor && flutter test test/ui/canvas
cd packages/map_editor && flutter analyze lib/src/ui/canvas/shadow test/ui/canvas
```

Optional smoke if time allows:

```bash
cd packages/map_runtime && flutter test test/phase_a_golden_battle_slice_smoke_test.dart
cd examples/playable_runtime_host && flutter test test/phase_a_golden_slice_launch_test.dart
```

Expected:

```text
All targeted tests pass.
Analyzers are clean for touched areas, or pre-existing debt is documented.
```

### Task 8 — Anti-drift scans

Run:

```bash
git diff --name-only | rg -n "packages/map_gameplay|packages/map_battle"
git diff --name-only | rg -n "packages/map_core/lib/src/models|project_element_shadow_config_json_codec|map_placed_element_shadow_override_json_codec|static_shadow_footprint_config_json_codec|\\.g\\.dart|\\.freezed\\.dart"
git diff -U0 -- packages/map_runtime packages/map_editor packages/map_core \
  | rg -n "saveLayer|ImageFilter|runtimeBlur|WorldLightState|ShadowLightProfile|LightDirection|timeOfDay|zOrder|zIndex|drawAtlas|package:map_editor"
git diff --check
git status --short --untracked-files=all
```

Expected for Shadow-49-owned changes:

```text
No map_battle/map_gameplay changes.
No model/codec/generated changes.
No advanced renderer/lights/import map_editor in runtime.
No whitespace errors.
```

If unrelated dirty files exist, list them separately in the report and do not stage them unless the user explicitly asks.

### Task 9 — Report

**Files:**

- Create: `reports/shadows/shadow_lot_49_projected_shadow_banded_fill.md`

Include:

```text
1. Résumé du lot
2. Pourquoi le polygone plein restait laid
3. Design retenu
4. Fichiers créés
5. Fichiers modifiés
6. Fichiers hors lot préexistants
7. Contrat core des opacity bands
8. Rendu runtime bandé
9. Rendu preview éditeur bandé
10. Pourquoi ce lot ne touche pas Flame components/render order
11. Pourquoi ce lot évite blur/saveLayer/ImageFilter
12. Tests ajoutés/modifiés
13. Commandes lancées
14. Résultats complets utiles des tests ciblés
15. Résultats des tests globaux ciblés
16. Analyse
17. Scans anti-dérive
18. git status initial/final
19. git diff --stat
20. Non-objectifs respectés
21. Risques / réserves
22. Auto-review finale
23. Contenu complet des fichiers créés/modifiés
24. Diff complet ciblé Shadow-49
```

## 7. Critères d’acceptation

Shadow-49 est réussi si :

```text
- map_core expose un contrat pur de bandes d’opacité projetées ;
- les bandes couvrent 0..1 sans trou ni overlap ;
- l’opacité diminue du bord proche vers le bord lointain ;
- le runtime dessine les projectedPolygon en bandes ;
- la preview éditeur dessine les projectedPolygon en bandes ;
- les ovals/contactBlob restent inchangés ;
- aucun modèle/codec/generated modifié ;
- aucun Flame component/render order modifié ;
- aucun blur/saveLayer/ImageFilter ajouté ;
- tests ciblés verts ;
- analyze ciblé vert ou dette préexistante documentée ;
- rapport complet créé ;
- aucun commit sauf demande explicite.
```

## 8. Ce que ça devrait changer visuellement

Avant :

```text
Une ombre projetée = un seul grand polygone alpha uniforme.
Résultat : plaque dure, très lisible sur les chemins et l’herbe.
```

Après :

```text
Une ombre projetée = plusieurs bandes trapézoïdales.
Le pied près de l’objet reste lisible.
Le bout de l’ombre devient moins agressif.
Le rendu reste pixel-art, sans blur ni rendu coûteux.
```

Ce lot ne donne pas encore une silhouette Pokémon parfaite asset par asset. Il rend le rendu actuel nettement moins brutal et prépare le lot suivant : calibration par famille/asset avec captures Selbrume.

## 9. Roadmap après Shadow-49

Si Shadow-49 améliore bien le rendu mais que certains bâtiments restent étranges, continuer avec :

```text
Shadow-50 — Selbrume Visual Calibration Slice / Asset Class Thresholds V0
Shadow-51 — Static Shadow Contact Occlusion / Building Foot Attachment V0
Shadow-52 — Optional Hand-authored Shadow Mask Decision V0
```

Le plus important : ne plus ajouter de nouveaux réglages utilisateur tant que le rendu automatique reste le point faible.
