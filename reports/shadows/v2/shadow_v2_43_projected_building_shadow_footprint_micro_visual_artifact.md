# ShadowV2-43 — Projected Building Shadow Footprint Micro Visual Artifact V0

## 1. Résumé exécutif

ShadowV2-43 a produit un artifact PNG micro-fixture Footprint V0, manuel et non-baseline.

Fichiers créés :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
reports/shadows/v2/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.md
```

Résultat :

```text
PNG créé
taille image : 480x256
test ciblé : passé
flutter analyze ciblé : OK
audit anti-dérive : propre
aucune baseline
aucun matchesGoldenFile
aucun Selbrume
aucun fichier de production modifié
```

Analyse visuelle provisoire : Footprint V0 lit bien plus comme une emprise courte et attachée que Directional V0. Ce lot ne valide pas artistiquement le rendu final ; il fournit l'image de revue humaine.

## 2. Objectif du lot

Objectif exact :

```text
Produire une image PNG micro-fixture montrant le vrai rendu Footprint Geometry V0,
rendu par le pipeline runtime ShadowV2 existant,
afin de vérifier visuellement si l’ombre se rapproche enfin de la cible Pokémon-like :
large, courte, grise, dure, attachée au bâtiment.
```

Ce lot est un artifact manuel. Il ne crée pas de golden, ne fige pas de baseline et ne modifie pas le renderer.

## 3. Rappel ShadowV2-40 / ShadowV2-42

ShadowV2-40 :

```text
ProjectedBuildingShadowGeometryMode.footprint
ProjectedShadowFootprintTuning()
resolveProjectedBuildingShadowGeometry(...)
```

Micro-fixture Footprint V0 :

```text
metrics.left = 32
metrics.top = 64
metrics.visualWidth = 64
metrics.visualHeight = 96

frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)
```

ShadowV2-42 :

```text
GREEN-on-add.
Les adapters runtime/editor existants supportent Footprint V0 in-memory.
```

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Le worktree était propre avant ShadowV2-43.

Fichiers préexistants hors scope :

```text
Aucun
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills/process utilisés :

```text
superpowers:using-superpowers
superpowers:test-driven-development
superpowers:verification-before-completion
karpathy-guidelines
```

Skills Google Flutter/Dart :

```text
Skill Google Flutter/Dart dédié : non détecté dans la liste des skills disponibles.
Dart MCP détecté : mcp__dart__.
Tentative run_tests : échec car aucun project root enregistré côté MCP.
Fallback utilisé : commandes Flutter demandées via context-mode.
```

Sortie de la tentative Dart MCP :

```text
Invalid root file:///Users/karim/Project/pokemonProject/packages/map_runtime, must be under one of the registered project roots:
```

Sub-agents utilisés :

```text
Audit sub-agent : Dalton
Flutter/Dart visual harness sub-agent : Avicenna
Evidence/report sub-agent : Aristotle
```

Résumé sub-agents :

```text
Dalton : scope propre, worktree initial clean, ne pas toucher Selbrume/baselines.
Avicenna : recommandations harness dart:ui / flutter_test, resolver + adapter + renderer, pixels.
Aristotle : checklist Evidence Pack, commandes, pièges rapport.
```

## 6. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties utiles :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
5:This repository is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.
21:    - Flutter + Flame runtime.
24:    - Flutter desktop authoring app.
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
860:1. Use `superpowers:subagent-driven-development` when applicable.
861:2. Dispatch one fresh subagent per task.
862:3. Each subagent implements, tests, reports final git status, and self-reviews.
863:4. Each subagent must not run Git write operations.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1240:### 20.1 TDD for Dart/Flutter
```

Le design gate est déjà satisfait par les lots 39 à 42. Le Lot 43 exécute l'artifact visuel prévu.

## 7. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
reports/shadows/v2/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.md
```

Modifiés :

```text
Aucun fichier existant
```

Supprimés :

```text
Aucun
```

Production modifiée :

```text
Aucun
```

## 8. Stratégie d’artifact visuel

L'image compare trois panels :

```text
A — Directional V0 reference
B — Footprint only
C — Footprint + building
```

Objectif :

```text
Comparer l'ancien rendu directionnel/languette au nouveau Footprint V0,
et juger si le footprint se lit comme une ombre courte, large et attachée.
```

Le harness écrit une seule image PNG. Il ne fait aucune comparaison baseline.

## 9. Description de l’image générée

Image :

```text
width = 480
height = 256
header = 32
3 colonnes de 160 px
zone visuelle = 224 px
```

Fond :

```text
#D8E0C8
grille #E6ECD8
séparateurs #B5BEA7
```

Panels :

```text
A : Directional V0 + bâtiment
B : Footprint V0 seul
C : Footprint V0 + bâtiment
```

## 10. Pipeline de rendu utilisé

Pipeline utilisé dans le harness :

```text
ProjectBuildingShadowPreset
+ ProjectElementProjectedBuildingShadowConfig
+ StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

Le harness utilise explicitement :

```text
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeRenderer.renderCollectionPass(...)
```

## 11. Directional V0 reference

Preset Directional V0 :

```text
id: pokemon-building-shadow-v0
geometryMode: directional
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
anchor: (0.5, 0.96)
opacity: 0.30
colorHexRgb: 606060
```

Il sert uniquement de référence comparative.

## 12. Footprint V0 rendered

Preset Footprint V0 :

```text
id: pokemon-building-shadow-footprint-v0
geometryMode: footprint
footprint: ProjectedShadowFootprintTuning()
opacity: 0.28
colorHexRgb: 606060
```

Points attendus vérifiés :

```text
(28.80, 146.56)
(99.20, 146.56)
(108.80, 173.44)
(32.00, 173.44)
```

## 13. Assertions du test

Assertions :

```text
image.width == 480
image.height == 256
PNG écrit
fichier existe
fichier size > 0
background pixel == #D8E0C8
directional shadow pixel != background
footprint shadow-only pixel != background
footprint visible-below-building pixel != background
building body pixel == #E9D7B9
footprint points attendus vérifiés
```

Pixels :

```text
background: (12, 44)
directional shadow: (80, 214)
footprint only: (224, 192)
footprint below building: (410, 198)
building body: (400, 152)
```

## 14. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
00:00 +0: generates projected building shadow footprint micro visual artifact
00:00 +1: All tests passed!
```

## 15. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
file reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   2.6K May 21 23:36 reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
ee13ddc8701d8b540ed4e23daa2468939ee9afaa2421ecf63f2bbeae6d4ccf32  reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png: PNG image data, 480 x 256, 8-bit/color RGBA, non-interlaced
```

## 16. Résultats des tests

Test ciblé :

```text
00:00 +1: All tests passed!
```

Aucun test global lancé. Le lot demande un harness ciblé.

## 17. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_footprint_micro_visual_artifact_test.dart...
No issues found! (ran in 1.3s)
```

## 18. Audit anti-dérive

Commande :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
```

Sortie :

```text
```

Résultat : propre.

Hits préexistants hors nouveau harness :

```text
packages/map_runtime/tool/shadow/README.md
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
reports/shadows/**
```

Ces fichiers sont préexistants et hors scope. Ils n'ont pas été modifiés.

## 19. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/**
packages/map_runtime/lib/**
packages/map_runtime/test/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
ShadowRuntimeRenderer
MapLayersComponent
PlayableMapGame
runtime_projected_building_shadow_collection.dart
projected_building_shadow_runtime_adapter.dart
editor_static_shadow_preview_painter.dart
MapGridPainter
resolveProjectedBuildingShadowGeometry(...)
createProjectedStaticShadowOpacityBands(...)
```

## 20. Ce qui n’a volontairement pas été créé

```text
*.golden
baseline_manifest.json
nouveau renderer
nouveau painter
nouveau modèle
nouveau codec
generated file
UI authoring
shader
blur
auto-shadow policy
migration
fixture Selbrume
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
```

Note : les trois fichiers ShadowV2-43 sont nouveaux/non suivis, donc `git diff --stat` ne les liste pas.

## 22. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
```

Note : les fichiers créés non suivis sont listés dans `git status final`.

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Résultat : propre.

## 24. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
?? reports/shadows/v2/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.md
```

Conforme au scope :

```text
1 harness manuel créé
1 PNG artifact créé
1 rapport Markdown créé
0 fichier de production modifié
0 fichier de test existant modifié
0 baseline
0 Selbrume
```

## 25. Analyse visuelle provisoire

L'image générée montre :

```text
A : l'ancien rendu Directional V0 reste lisible comme une languette diagonale.
B : Footprint V0 est court, large, bas, et moins directionnel.
C : Footprint V0 sous le bâtiment paraît attaché au pied / derrière le volume.
```

Lecture provisoire :

```text
Footprint V0 se rapproche nettement mieux de la cible Pokémon-like que Directional V0.
La masse est plus compacte et moins lancée en biais.
Le banding reste visible mais secondaire.
```

Ce n'est pas une validation artistique finale.

## 26. Risques / réserves

- Image micro seulement, pas Selbrume.
- Pas de persistance JSON prouvée.
- Le rendu garde les bandes hard-edge existantes.
- Le bâtiment reste simplifié.
- La revue humaine doit décider si Footprint V0 est prometteur.

## 27. Auto-critique

- Le lot a-t-il créé une baseline par accident ?
  Non.

- Le PNG est-il bien un artifact manuel ?
  Oui.

- Le test écrit-il seulement l’image autorisée ?
  Oui.

- L’image permet-elle vraiment de comparer Directional V0 et Footprint V0 ?
  Oui : A référence directionnelle, B footprint seul, C footprint + bâtiment.

- Le footprint est-il rendu via resolver + adapter + renderer ?
  Oui.

- Le panel bâtiment aide-t-il à juger l’attachement au volume ?
  Oui.

- Le harness dépend-il de Selbrume ou d’un asset externe ?
  Non.

- Les skills Flutter/Dart disponibles ont-ils été utilisés ?
  Skill Google dédié non détecté ; Dart MCP tenté mais root non enregistré ; fallback Flutter CLI via context-mode documenté.

- Les sub-agents ou passes équivalentes ont-ils été utilisés ?
  Oui, trois sub-agents réels.

- Le rapport contient-il toutes les preuves ?
  Oui.

## 28. Regard critique sur le prompt

Le prompt force le bon niveau de preuve : après tests adapter, une image micro contrôlée. La contrainte de comparaison avec Directional V0 est utile, car elle rend immédiatement visible le pivot visuel.

Point de vigilance : le prochain lot doit rester une décision de revue visuelle, pas une modification de calibration immédiate.

## 29. Prochain lot recommandé

Si l'image est jugée prometteuse :

```text
ShadowV2-44 — Projected Building Shadow Footprint Visual Review / Calibration Decision Gate
```

Objectif :

```text
Décider si Footprint V0 devient la base visuelle officielle,
ou s’il faut ajuster attachYRatio / depthRatio / width ratios / skew / opacity.
```

Si l'image est jugée mauvaise :

```text
ShadowV2-44 — Projected Building Shadow Author-Defined Polygon / Asset Shadow Design Gate
```

## 30. Code complet des fichiers créés/modifiés

Le rapport courant est le fichier rapport créé.

Contenu complet du fichier tool créé :

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart'
    show
        ProjectBuildingShadowPreset,
        ProjectElementProjectedBuildingShadowConfig,
        ProjectedBuildingShadowGeometry,
        ProjectedBuildingShadowGeometryMode,
        ProjectedBuildingShadowPoint,
        ProjectedShadowAnchor,
        ProjectedShadowAppearance,
        ProjectedShadowDirection,
        ProjectedShadowFootprintTuning,
        ProjectedShadowOffset,
        ProjectedShadowShapeTuning,
        ProjectedShadowTimeOfDayMode,
        ShadowRenderPass,
        StaticShadowVisualMetrics,
        resolveProjectedBuildingShadowGeometry;
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 480;
const _artifactHeight = 256;
const _columnWidth = 160;
const _headerHeight = 32;
const _visualHeight = 224;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _labelColor = ui.Color(0xFF343A3D);
const _buildingBodyColor = ui.Color(0xFFE9D7B9);
const _buildingRoofColor = ui.Color(0xFFB7655A);
const _buildingOutlineColor = ui.Color(0xFF343A3D);
const _buildingDoorColor = ui.Color(0xFF7E5547);
const _buildingWindowColor = ui.Color(0xFF8EC6D8);

final _metrics = StaticShadowVisualMetrics(
  left: 32,
  top: 64,
  visualWidth: 64,
  visualHeight: 96,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow footprint micro visual artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, _headerHeight + 12);
    expect(backgroundPixel, _rgba(_backgroundColor));

    final directionalShadowPixel =
        await _pixelAt(image, 80, _headerHeight + 182);
    expect(directionalShadowPixel, isNot(backgroundPixel));

    final footprintOnlyPixel =
        await _pixelAt(image, _columnWidth + 64, _headerHeight + 160);
    expect(footprintOnlyPixel, isNot(backgroundPixel));

    final footprintBelowBuildingPixel =
        await _pixelAt(image, (_columnWidth * 2) + 90, _headerHeight + 166);
    expect(footprintBelowBuildingPixel, isNot(backgroundPixel));

    final buildingBodyPixel =
        await _pixelAt(image, (_columnWidth * 2) + 80, _headerHeight + 120);
    expect(buildingBodyPixel, _rgba(_buildingBodyColor));

    final footprintGeometry = _geometryFor(
      preset: _footprintPreset(),
      config: _footprintConfig(),
    );
    expect(footprintGeometry.points, hasLength(4));
    _expectPointClose(footprintGeometry.points[0], x: 28.80, y: 146.56);
    _expectPointClose(footprintGeometry.points[1], x: 99.20, y: 146.56);
    _expectPointClose(footprintGeometry.points[2], x: 108.80, y: 173.44);
    _expectPointClose(footprintGeometry.points[3], x: 32.00, y: 173.44);

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

// Manual artifact harness: writes one PNG for human visual review.
// It is not a golden test and does not compare against any image file.
Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < 3; index += 1) {
    final columnLeft = (index * _columnWidth).toDouble();
    _drawCandidateLabel(canvas, _labelForIndex(index), columnLeft: columnLeft);
    _drawPanelBackground(canvas, columnLeft);
  }

  _drawShadow(
    canvas,
    collection: _collectionFor(
      preset: _directionalPreset(),
      config: _directionalConfig(),
    ),
    columnLeft: 0,
  );
  _drawSimpleBuilding(canvas, columnLeft: 0);

  _drawShadow(
    canvas,
    collection: _collectionFor(
      preset: _footprintPreset(),
      config: _footprintConfig(),
    ),
    columnLeft: _columnWidth.toDouble(),
  );

  _drawShadow(
    canvas,
    collection: _collectionFor(
      preset: _footprintPreset(),
      config: _footprintConfig(),
    ),
    columnLeft: (_columnWidth * 2).toDouble(),
  );
  _drawSimpleBuilding(canvas, columnLeft: (_columnWidth * 2).toDouble());

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawPanelBackground(ui.Canvas canvas, double columnLeft) {
  canvas.drawRect(
    ui.Rect.fromLTWH(
      columnLeft,
      _headerHeight.toDouble(),
      _columnWidth.toDouble(),
      _visualHeight.toDouble(),
    ),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, columnLeft: columnLeft);
}

void _drawGrid(ui.Canvas canvas, {required double columnLeft}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;

  for (var x = 32.0; x < _columnWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(columnLeft + x, _headerHeight.toDouble()),
      ui.Offset(columnLeft + x, _artifactHeight.toDouble()),
      paint,
    );
  }
  for (var y = 32.0; y < _visualHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(columnLeft, _headerHeight + y),
      ui.Offset(columnLeft + _columnWidth, _headerHeight + y),
      paint,
    );
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;

  canvas.drawLine(
    const ui.Offset(0, _headerHeight - 0.5),
    const ui.Offset(_artifactWidth + 0.0, _headerHeight - 0.5),
    paint,
  );
  for (var x = _columnWidth.toDouble(); x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(
      ui.Offset(x - 0.5, 0),
      ui.Offset(x - 0.5, _artifactHeight.toDouble()),
      paint,
    );
  }
}

void _drawShadow(
  ui.Canvas canvas, {
  required ShadowRuntimeInstructionCollection collection,
  required double columnLeft,
}) {
  canvas.save();
  canvas.translate(columnLeft, _headerHeight.toDouble());
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    collection,
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionFor({
  required ProjectBuildingShadowPreset preset,
  required ProjectElementProjectedBuildingShadowConfig config,
}) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionFor(preset: preset, config: config)],
  );
}

ShadowRuntimeRenderInstruction _instructionFor({
  required ProjectBuildingShadowPreset preset,
  required ProjectElementProjectedBuildingShadowConfig config,
}) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryFor(preset: preset, config: config),
  );
}

ProjectedBuildingShadowGeometry _geometryFor({
  required ProjectBuildingShadowPreset preset,
  required ProjectElementProjectedBuildingShadowConfig config,
}) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: config,
    preset: preset,
    metrics: _metrics,
  );
  if (geometry == null) {
    throw StateError('${preset.id} did not produce geometry');
  }
  return geometry;
}

ProjectBuildingShadowPreset _directionalPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-v0',
    name: 'Pokemon-like building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.directional,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.30,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _directionalConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-v0',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _footprintConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-footprint-v0',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _drawSimpleBuilding(ui.Canvas canvas, {required double columnLeft}) {
  const left = 32.0;
  const top = _headerHeight + 64.0;
  const width = 64.0;
  const height = 96.0;
  final body = ui.Paint()..color = _buildingBodyColor;
  final roof = ui.Paint()..color = _buildingRoofColor;
  final outline = ui.Paint()
    ..color = _buildingOutlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
  final door = ui.Paint()..color = _buildingDoorColor;
  final window = ui.Paint()..color = _buildingWindowColor;

  final x = columnLeft + left;
  canvas.drawRect(ui.Rect.fromLTWH(x, top, width, height), body);
  canvas.drawRect(ui.Rect.fromLTWH(x, top, width, 22), roof);
  canvas.drawRect(ui.Rect.fromLTWH(x, top, width, height), outline);
  canvas.drawLine(
    ui.Offset(x, top + 22),
    ui.Offset(x + width, top + 22),
    outline,
  );
  canvas.drawRect(ui.Rect.fromLTWH(x + 26, top + 62, 12, 30), door);
  canvas.drawRect(ui.Rect.fromLTWH(x + 10, top + 36, 14, 10), window);
  canvas.drawRect(ui.Rect.fromLTWH(x + 40, top + 36, 14, 10), window);
}

void _drawCandidateLabel(
  ui.Canvas canvas,
  String letter, {
  required double columnLeft,
}) {
  final paint = ui.Paint()
    ..color = _labelColor
    ..strokeWidth = 2
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.square
    ..isAntiAlias = false;
  final x = columnLeft + 72;
  const y = 7.0;
  const width = 16.0;
  const height = 18.0;
  final left = x;
  final right = x + width;
  const top = y;
  const middle = y + height / 2;
  const bottom = y + height;

  switch (letter) {
    case 'A':
      canvas.drawLine(
          ui.Offset(left, bottom), ui.Offset(x + width / 2, top), paint);
      canvas.drawLine(
          ui.Offset(x + width / 2, top), ui.Offset(right, bottom), paint);
      canvas.drawLine(
          ui.Offset(left + 4, middle), ui.Offset(right - 4, middle), paint);
    case 'B':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle), paint);
      canvas.drawLine(
          ui.Offset(left, bottom), ui.Offset(right - 3, bottom), paint);
      canvas.drawLine(
          ui.Offset(right, top + 3), ui.Offset(right, middle - 1), paint);
      canvas.drawLine(
          ui.Offset(right, middle + 1), ui.Offset(right, bottom - 3), paint);
    case 'C':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left, top), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(right, bottom), paint);
  }
}

String _labelForIndex(int index) {
  return switch (index) {
    0 => 'A',
    1 => 'B',
    2 => 'C',
    _ => throw ArgumentError.value(index, 'index'),
  };
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 footprint artifact as PNG');
  }
  return byteData.buffer.asUint8List(
    byteData.offsetInBytes,
    byteData.lengthInBytes,
  );
}

Future<void> _writePng(Uint8List bytes) async {
  final file = File(_artifactPath);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes, flush: true);
}

Future<_Rgba> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    throw StateError('Could not read raw pixels from artifact image');
  }
  final offset = (y * image.width + x) * 4;
  return _Rgba(
    data.getUint8(offset),
    data.getUint8(offset + 1),
    data.getUint8(offset + 2),
    data.getUint8(offset + 3),
  );
}

void _expectPointClose(
  ProjectedBuildingShadowPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.02));
  expect(point.y, closeTo(y, 0.02));
}

_Rgba _rgba(ui.Color color) {
  return _Rgba(
    _colorChannelByte(color.r),
    _colorChannelByte(color.g),
    _colorChannelByte(color.b),
    _colorChannelByte(color.a),
  );
}

int _colorChannelByte(double channel) {
  return (channel * 255.0).round().clamp(0, 255).toInt();
}

final class _Rgba {
  const _Rgba(this.r, this.g, this.b, this.a);

  final int r;
  final int g;
  final int b;
  final int a;

  @override
  bool operator ==(Object other) {
    return other is _Rgba &&
        other.r == r &&
        other.g == g &&
        other.b == b &&
        other.a == a;
  }

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'rgba($r, $g, $b, $a)';
}
```

Checklist finale :

- [x] Harness manuel créé sous packages/map_runtime/tool/shadow
- [x] PNG artifact créé
- [x] PNG dans reports/shadows/screenshots
- [x] Aucun fichier baseline créé
- [x] Aucun matchesGoldenFile
- [x] Aucun Selbrume modifié ou lu pour générer l’image
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] Image 480x256 ou taille documentée
- [x] Colonne A Directional V0 présente
- [x] Colonne B Footprint only présente
- [x] Colonne C Footprint + building présente
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] ProjectedShadowFootprintTuning utilisé
- [x] Footprint opacity 0.28 utilisée
- [x] Footprint colorHexRgb 606060 utilisée
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
