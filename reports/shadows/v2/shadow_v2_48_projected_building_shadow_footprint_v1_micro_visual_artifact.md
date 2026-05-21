# ShadowV2-48 — Projected Building Shadow Footprint V1 Micro Visual Artifact

## 1. Résumé exécutif

ShadowV2-48 a créé un artifact PNG micro-fixture dédié à la calibration officielle `pokemon-building-shadow-footprint-v1`.

Résultat :

```text
PNG créé : reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
Dimensions : 480 x 480
Colonnes : A Directional V0, B Footprint V0, C Footprint V1
Lignes : shadow-only, shadow + building
Pipeline : resolveProjectedBuildingShadowGeometry -> createProjectedBuildingShadowRuntimeInstruction -> ShadowRuntimeRenderer.renderCollectionPass
Baseline/golden : aucune
Selbrume : non utilisé
Production : non modifiée
```

La V1 rendue est bien la calibration retenue au Lot 46 et propagée au Lot 47 :

```text
attachYRatio 0.82
frontWidthRatio 1.30
rearWidthRatio 1.42
depthRatio 0.26
skewXRatio 0.08
opacity 0.24
colorHexRgb 606060
```

## 2. Objectif du lot

Objectif exact :

```text
Générer un artifact PNG micro-fixture avec la calibration officielle
pokemon-building-shadow-footprint-v1,
afin de confirmer visuellement que les tests/fixtures V1 correspondent bien au rendu choisi,
sans modifier la production,
sans modifier JSON/persistence,
sans Selbrume,
sans baseline,
sans renderer/painter.
```

Le lot ne sélectionne pas une nouvelle calibration. Il produit une preuve visuelle manuelle.

## 3. Rappel ShadowV2-47

ShadowV2-47 a propagé la calibration V1 dans les tests/fixtures ciblés :

```text
map_core geometry V1
runtime adapter V1
runtime collection V1
editor preview V1
```

Points V1 validés :

```text
frontLeft  = (22.40, 142.72)
frontRight = (105.60, 142.72)
rearRight  = (114.56, 167.68)
rearLeft   = (23.68, 167.68)
```

Bounds V1 validés :

```text
left = 22.40
top = 142.72
width = 92.16
height = 24.96
```

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
(no output)
```

Fichiers préexistants non liés au lot :

```text
Aucun
```

Fichiers hors scope déjà présents :

```text
Aucun
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills utilisés :

```text
superpowers:using-superpowers
karpathy-guidelines
superpowers:test-driven-development
superpowers:verification-before-completion
superpowers:subagent-driven-development
dart-add-unit-test
dart-run-static-analysis
flutter-add-widget-test
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté dans la liste des skills disponibles.
Des skills Dart/Flutter génériques ont été lus et utilisés pour guider le test Flutter, l'usage de flutter_test et l'analyse ciblée.
```

Flame docs :

```text
Le lot touche un harness runtime/rendu. flame_docs a été interrogé avec :
- rendering canvas render method Flame Flutter canvas
- Flame render Canvas component render method

Les deux recherches n'ont retourné aucun résultat. Le lot s'est donc appuyé sur les patterns runtime locaux existants et n'a modifié aucune API Flame ni aucun composant Flame.
```

Sub-agents :

```text
Audit sub-agent : utilisé en lecture seule.
Flutter/Dart visual harness sub-agent : utilisé en lecture seule.
Visual evidence sub-agent : utilisé en lecture seule.
Test/analyze/evidence sub-agent : non lancé, limite de threads atteinte ; passe équivalente faite localement.
```

Synthèse :

```text
Audit : AGENTS.md racine vérifié, worktree initial propre, scope autorisé confirmé.
Harness : reprendre le pipeline resolver -> adapter -> renderer et les helpers des Lots 43/45.
Visual evidence : conserver le format Lot 45 deux lignes, avec trois colonnes ciblées A/B/C.
Evidence : test, analyze, hash PNG, file, anti-dérive et git final exécutés localement.
```

## 6. Décision AGENTS / design gate déjà satisfait

AGENTS.md vérifié :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Extraits pertinents :

```text
5:This repository is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.
21:    - Flutter + Flame runtime.
24:    - Flutter desktop authoring app.
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
581:Pure Dart packages:
589:Flutter packages and apps:
611:For pure Dart packages, use `dart analyze`.
613:For Flutter packages and apps, use `flutter analyze`.
860:1. Use `superpowers:subagent-driven-development` when applicable.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1240:### 20.1 TDD for Dart/Flutter
```

Décision :

```text
Le design gate ShadowV2-46 et la fixture propagation ShadowV2-47 sont déjà satisfaits.
ShadowV2-48 est autorisé à créer uniquement un harness manuel, un PNG et un rapport.
```

## 7. Fichiers créés / modifiés / supprimés

Fichiers créés par ShadowV2-48 :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
reports/shadows/v2/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.md
```

Fichiers modifiés :

```text
Aucun
```

Fichiers supprimés :

```text
Aucun
```

Fichiers de production modifiés :

```text
Aucun
```

## 8. Stratégie d’artifact visuel

La stratégie reprend le format comparatif du Lot 45, réduit aux trois états qui comptent maintenant :

```text
A = Directional V0 reference
B = Footprint V0 default reference
C = Footprint V1 official
```

L'image a deux lignes :

```text
ligne 1 = shadow-only
ligne 2 = shadow + building
```

Cette organisation permet de lire séparément :

```text
- la forme brute ;
- l'attachement au bâtiment ;
- la différence V0 default / V1 officielle.
```

## 9. Description de l’image générée

Image :

```text
width = 480
height = 480
columns = 3 x 160 px
header = 32 px
row 1 = 224 px
row 2 = 224 px
```

Fond et grille :

```text
background #D8E0C8
grid #E6ECD8
dividers #B5BEA7
```

Bâtiment :

```text
left = 32
top = 64
width = 64
height = 96
body #E9D7B9
roof #B7655A
outline #343A3D
door #7E5547
windows #8EC6D8
```

## 10. Pipeline de rendu utilisé

Chaque ombre passe par :

```text
ProjectBuildingShadowPreset
+ ProjectElementProjectedBuildingShadowConfig
+ StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

Le harness ne construit pas manuellement de `ShadowRuntimeRenderInstruction` hors adapter.

## 11. Directional V0 reference

Colonne A :

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

Rôle :

```text
Référence négative historique : forme plus directionnelle et moins footprint.
```

## 12. Footprint V0 reference

Colonne B :

```text
id: pokemon-building-shadow-footprint-v0
geometryMode: footprint
footprint: ProjectedShadowFootprintTuning()
opacity: 0.28
colorHexRgb: 606060
```

Points V0 attendus :

```text
(28.80, 146.56)
(99.20, 146.56)
(108.80, 173.44)
(32.00, 173.44)
```

Rôle :

```text
Référence default core / V0.
```

## 13. Footprint V1 official rendered

Colonne C :

```text
id: pokemon-building-shadow-footprint-v1
geometryMode: footprint
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

Points V1 vérifiés par le test :

```text
(22.40, 142.72)
(105.60, 142.72)
(114.56, 167.68)
(23.68, 167.68)
```

Bounds V1 vérifiés :

```text
left = 22.40
top = 142.72
width = 92.16
height = 24.96
```

## 14. Assertions du test

Assertions :

```text
image.width == 480
image.height == 480
background pixel == #D8E0C8
pour chaque colonne : shadow-only pixel au centroïde != background
pour chaque colonne : building body pixel == #E9D7B9
pour chaque colonne : visible shadow below building pixel != background
V1 opacity == 0.24
V1 colorHexRgb == 606060
V1 points attendus vérifiés
V1 bounds attendus vérifiés
PNG écrit
fichier existe
fichier size > 0
```

## 15. Résultat de génération PNG

RED initial, avant création du harness :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart": Does not exist.
00:00 +0 -1: Some tests failed.
```

GREEN après création du harness :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
00:00 +0: generates projected building shadow footprint v1 micro visual artifact
00:00 +1: All tests passed!
```

## 16. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff   5.0K May 22 01:29 reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Commande :

```bash
shasum -a 256 reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Sortie :

```text
a04c37c962970dbd7edf35752f8ce83dd49bb8e1de836f6b05e65f951f56d073  reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png: PNG image data, 480 x 480, 8-bit/color RGBA, non-interlaced
```

## 17. Résultats des tests

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
00:00 +0: generates projected building shadow footprint v1 micro visual artifact
00:00 +1: All tests passed!
```

## 18. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_footprint_v1_micro_visual_artifact_test.dart...

No issues found! (ran in 1.4s)
```

## 19. Audit anti-dérive

Commande :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
```

Sortie :

```text
(no output)
```

Résultat :

```text
Aucun hit interdit dans le harness créé.
```

## 20. Ce qui n’a volontairement pas été modifié

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
ProjectedShadowFootprintTuning defaults
JSON/codecs
project.json
```

## 21. Ce qui n’a volontairement pas été créé

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

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
(no output)
```

Note :

```text
Les fichiers créés par ce lot sont non suivis ; git diff --stat ne liste pas les fichiers non suivis.
Ils sont inventoriés dans les sections 7 et 25.
```

## 23. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
(no output)
```

Note :

```text
Les fichiers créés par ce lot sont non suivis ; git diff --name-status ne liste pas les fichiers non suivis.
Ils sont inventoriés dans les sections 7 et 25.
```

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
(no output)
```

Résultat :

```text
Propre.
```

## 25. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
?? reports/shadows/v2/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.md
```

## 26. Analyse visuelle provisoire

Lecture de l'artifact :

```text
A Directional V0 : la forme reste plus inclinée et plus proche d'une languette.
B Footprint V0 : l'emprise au sol est déjà plus lisible, mais moins large que la calibration officielle.
C Footprint V1 : la forme est plus large, plus basse en opacité, et lit davantage comme un socle court sous le bâtiment.
```

La V1 confirme visuellement le choix du Lot 46 à l'échelle micro-fixture : elle soutient mieux le volume que V0 tout en restant moins sale grâce à `opacity 0.24`.

## 27. Risques / réserves

```text
L'artifact est une micro-fixture, pas une validation multi-map.
La V1 n'est pas encore persistée en JSON/project.json.
Selbrume n'a pas été touché ni relu pour générer l'image.
Le renderer/painter et le banding restent inchangés.
Un futur lot doit décider s'il faut passer à JSON/persistence ou produire un artifact multi-size / multi-background.
```

## 28. Auto-critique

Le lot a-t-il créé une baseline par accident ?

```text
Non. Un seul PNG a été écrit sous reports/shadows/screenshots, aucun fichier reports/shadows/baselines.
```

Le PNG est-il bien un artifact manuel ?

```text
Oui. Il est généré par un harness tool/shadow et n'est comparé à aucune image de référence.
```

Le test écrit-il seulement l'image autorisée ?

```text
Oui. Le chemin d'écriture est uniquement reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png.
```

L'image permet-elle vraiment de comparer Directional V0 / Footprint V0 / Footprint V1 ?

```text
Oui. Les trois colonnes partagent les mêmes metrics, le même fond, le même bâtiment et les deux lignes shadow-only / shadow+building.
```

V1 est-il rendu via resolver + adapter + renderer ?

```text
Oui. Le code appelle resolveProjectedBuildingShadowGeometry, createProjectedBuildingShadowRuntimeInstruction et ShadowRuntimeRenderer.renderCollectionPass.
```

Le panel bâtiment aide-t-il à juger l'attachement au volume ?

```text
Oui. La deuxième ligne dessine le même bâtiment par-dessus chaque ombre.
```

Le harness dépend-il de Selbrume ou d'un asset externe ?

```text
Non. Le harness utilise uniquement dart:ui et des formes vectorielles locales.
```

Les defaults ProjectedShadowFootprintTuning() sont-ils inchangés ?

```text
Oui. Aucun fichier map_core/lib n'a été modifié. V0 utilise ProjectedShadowFootprintTuning() ; V1 utilise un tuning explicite.
```

JSON/persistence est-il hors scope ?

```text
Oui. Aucun codec, project.json ou fixture Selbrume n'a été modifié.
```

Les skills Flutter/Dart disponibles ont-ils été utilisés ?

```text
Oui pour les skills Dart/Flutter génériques disponibles. Aucun skill explicitement nommé Google Flutter/Dart n'était disponible.
```

Les sub-agents ou passes équivalentes ont-ils été utilisés ?

```text
Oui. Trois sub-agents ont été utilisés et la quatrième passe a été faite localement à cause de la limite de threads.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Test, analyze, hash, file, anti-dérive, git final et code complet du harness sont inclus.
```

## 29. Regard critique sur le prompt

Le prompt est très borné et évite les dérives classiques : pas de renderer/painter, pas de JSON, pas de Selbrume, pas de baseline. Le format 480x480 avec deux lignes est plus fort que le Lot 43 pour comparer l'attachement, car il évite de mélanger une colonne shadow-only avec deux colonnes shadow+building.

La contrainte "Aucun commentaire dans le code Dart créé" est respectée. Elle rend le harness un peu moins auto-documenté, mais le rapport compense ce contexte.

## 30. Prochain lot recommandé

Si l'image V1 confirme la bonne direction :

```text
ShadowV2-49 — Projected Building Shadow Footprint V1 Visual Review / Persistence Decision Gate
```

Objectif probable :

```text
Décider si la V1 est suffisamment validée visuellement pour passer au support JSON/persistence,
ou s'il faut encore un artifact multi-size / multi-background.
```

## 31. Code complet des fichiers créés/modifiés

### packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart

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
const _artifactHeight = 480;
const _columnWidth = 160;
const _headerHeight = 32;
const _rowHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = 256;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png';

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

final _candidates = [
  _directionalCandidate(),
  _footprintV0Candidate(),
  _footprintV1Candidate(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow footprint v1 micro visual artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _candidates.length; index += 1) {
      final candidate = _candidates[index];
      final columnLeft = index * _columnWidth;
      final geometry = _geometryForCandidate(candidate);
      final centroid = _centroid(geometry);
      final shadowOnlyPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowOnlyPixel,
        isNot(backgroundPixel),
        reason: '${candidate.label} shadow-only should render',
      );

      final buildingBodyPixel = await _pixelAt(
        image,
        columnLeft + 80,
        _buildingRowTop + 120,
      );
      expect(
        buildingBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.label} building body should render above shadow',
      );

      final visibleShadowPoint = _visibleShadowPoint(geometry);
      final visibleShadowPixel = await _pixelAt(
        image,
        columnLeft + visibleShadowPoint.x.round(),
        _buildingRowTop + visibleShadowPoint.y.round(),
      );
      expect(
        visibleShadowPixel,
        isNot(backgroundPixel),
        reason: '${candidate.label} shadow should remain visible below building',
      );
    }

    final v1Geometry = _geometryForCandidate(_candidates[2]);
    expect(v1Geometry.opacity, 0.24);
    expect(v1Geometry.colorHexRgb, '606060');
    expect(v1Geometry.points, hasLength(4));
    _expectPointClose(v1Geometry.points[0], x: 22.40, y: 142.72);
    _expectPointClose(v1Geometry.points[1], x: 105.60, y: 142.72);
    _expectPointClose(v1Geometry.points[2], x: 114.56, y: 167.68);
    _expectPointClose(v1Geometry.points[3], x: 23.68, y: 167.68);

    final v1Instruction = _instructionForCandidate(_candidates[2]);
    expect(v1Instruction.worldLeft, closeTo(22.40, 0.02));
    expect(v1Instruction.worldTop, closeTo(142.72, 0.02));
    expect(v1Instruction.width, closeTo(92.16, 0.02));
    expect(v1Instruction.height, closeTo(24.96, 0.02));

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < _candidates.length; index += 1) {
    final candidate = _candidates[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawLabel(canvas, candidate.letter, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _buildingRowTop.toDouble());
    _drawSimpleBuilding(canvas, columnLeft, _buildingRowTop.toDouble());
  }

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawCellBackground(ui.Canvas canvas, double left, double top) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, _columnWidth + 0.0, _rowHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, left: left, top: top);
}

void _drawGrid(ui.Canvas canvas, {required double left, required double top}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;

  for (var x = 32.0; x < _columnWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(left + x, top),
      ui.Offset(left + x, top + _rowHeight),
      paint,
    );
  }
  for (var y = 32.0; y < _rowHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(left, top + y),
      ui.Offset(left + _columnWidth, top + y),
      paint,
    );
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;

  for (var x = _columnWidth.toDouble(); x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(
      ui.Offset(x - 0.5, 0),
      ui.Offset(x - 0.5, _artifactHeight + 0.0),
      paint,
    );
  }
  canvas.drawLine(
    const ui.Offset(0, _headerHeight - 0.5),
    const ui.Offset(_artifactWidth + 0.0, _headerHeight - 0.5),
    paint,
  );
  canvas.drawLine(
    const ui.Offset(0, _buildingRowTop - 0.5),
    const ui.Offset(_artifactWidth + 0.0, _buildingRowTop - 0.5),
    paint,
  );
}

void _drawShadow(
  ui.Canvas canvas,
  _ShadowCandidate candidate,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionForCandidate(candidate),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionForCandidate(
  _ShadowCandidate candidate,
) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionForCandidate(candidate)],
  );
}

ShadowRuntimeRenderInstruction _instructionForCandidate(
  _ShadowCandidate candidate,
) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryForCandidate(candidate),
  );
}

ProjectedBuildingShadowGeometry _geometryForCandidate(
  _ShadowCandidate candidate,
) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _configForCandidate(candidate),
    preset: _presetForCandidate(candidate),
    metrics: _metrics,
  );
  if (geometry == null) {
    throw StateError('${candidate.label} did not produce geometry');
  }
  return geometry;
}

ProjectBuildingShadowPreset _presetForCandidate(_ShadowCandidate candidate) {
  switch (candidate.geometryMode) {
    case ProjectedBuildingShadowGeometryMode.directional:
      return ProjectBuildingShadowPreset(
        id: candidate.id,
        name: candidate.label,
        geometryMode: ProjectedBuildingShadowGeometryMode.directional,
        direction: ProjectedShadowDirection(
          x: candidate.directionX,
          y: candidate.directionY,
        ),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: candidate.lengthRatio,
          nearWidthRatio: candidate.nearWidthRatio,
          farWidthRatio: candidate.farWidthRatio,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: candidate.opacity,
          colorHexRgb: candidate.colorHexRgb,
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
    case ProjectedBuildingShadowGeometryMode.footprint:
      return ProjectBuildingShadowPreset(
        id: candidate.id,
        name: candidate.label,
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.90,
          farWidthRatio: 0.72,
        ),
        footprint: candidate.usesDefaultFootprint
            ? ProjectedShadowFootprintTuning()
            : ProjectedShadowFootprintTuning(
                attachYRatio: candidate.attachYRatio,
                frontWidthRatio: candidate.frontWidthRatio,
                rearWidthRatio: candidate.rearWidthRatio,
                depthRatio: candidate.depthRatio,
                skewXRatio: candidate.skewXRatio,
              ),
        appearance: ProjectedShadowAppearance(
          opacity: candidate.opacity,
          colorHexRgb: candidate.colorHexRgb,
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
  }
}

ProjectElementProjectedBuildingShadowConfig _configForCandidate(
  _ShadowCandidate candidate,
) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: candidate.id,
    anchor: ProjectedShadowAnchor(
      xRatio: candidate.anchorXRatio,
      yRatio: candidate.anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

_ShadowCandidate _directionalCandidate() {
  return const _ShadowCandidate(
    id: 'pokemon-building-shadow-v0',
    label: 'A - Directional V0',
    letter: 'A',
    geometryMode: ProjectedBuildingShadowGeometryMode.directional,
    directionX: 0.8,
    directionY: 0.35,
    lengthRatio: 0.32,
    nearWidthRatio: 0.90,
    farWidthRatio: 0.72,
    anchorXRatio: 0.5,
    anchorYRatio: 0.96,
    opacity: 0.30,
    colorHexRgb: '606060',
  );
}

_ShadowCandidate _footprintV0Candidate() {
  return const _ShadowCandidate(
    id: 'pokemon-building-shadow-footprint-v0',
    label: 'B - Footprint V0',
    letter: 'B',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    usesDefaultFootprint: true,
    attachYRatio: 0.86,
    frontWidthRatio: 1.10,
    rearWidthRatio: 1.20,
    depthRatio: 0.28,
    skewXRatio: 0.10,
    anchorXRatio: 0.5,
    anchorYRatio: 1,
    opacity: 0.28,
    colorHexRgb: '606060',
  );
}

_ShadowCandidate _footprintV1Candidate() {
  return const _ShadowCandidate(
    id: 'pokemon-building-shadow-footprint-v1',
    label: 'C - Footprint V1',
    letter: 'C',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
    anchorXRatio: 0.5,
    anchorYRatio: 1,
    opacity: 0.24,
    colorHexRgb: '606060',
  );
}

void _drawSimpleBuilding(ui.Canvas canvas, double columnLeft, double rowTop) {
  final left = columnLeft + 32;
  final top = rowTop + 64;
  const width = 64.0;
  const height = 96.0;

  final body = ui.Rect.fromLTWH(left, top, width, height);
  canvas.drawRect(body, ui.Paint()..color = _buildingBodyColor);

  final roof = ui.Rect.fromLTWH(left, top, width, 22);
  canvas.drawRect(roof, ui.Paint()..color = _buildingRoofColor);

  final door = ui.Rect.fromLTWH(left + 26, top + 62, 12, 30);
  canvas.drawRect(door, ui.Paint()..color = _buildingDoorColor);

  final windowPaint = ui.Paint()..color = _buildingWindowColor;
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 36, 14, 10), windowPaint);
  canvas.drawRect(ui.Rect.fromLTWH(left + 40, top + 36, 14, 10), windowPaint);

  final outline = ui.Paint()
    ..color = _buildingOutlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
  canvas.drawRect(body, outline);
  canvas.drawLine(
    ui.Offset(left, top + 22),
    ui.Offset(left + width, top + 22),
    outline,
  );
}

void _drawLabel(
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

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 footprint V1 artifact as PNG');
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

_MicroPoint _centroid(ProjectedBuildingShadowGeometry geometry) {
  final count = geometry.points.length;
  final sum = geometry.points.fold(
    const _MicroPoint(0, 0),
    (total, point) => _MicroPoint(total.x + point.x, total.y + point.y),
  );
  return _MicroPoint(sum.x / count, sum.y / count);
}

_MicroPoint _visibleShadowPoint(ProjectedBuildingShadowGeometry geometry) {
  final rearMidpoint = _MicroPoint(
    (geometry.points[2].x + geometry.points[3].x) / 2,
    (geometry.points[2].y + geometry.points[3].y) / 2,
  );
  final centroid = _centroid(geometry);
  return _MicroPoint(
    (rearMidpoint.x * 0.82) + (centroid.x * 0.18),
    (rearMidpoint.y * 0.88) + (centroid.y * 0.12),
  );
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

final class _ShadowCandidate {
  const _ShadowCandidate({
    required this.id,
    required this.label,
    required this.letter,
    required this.geometryMode,
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.opacity,
    required this.colorHexRgb,
    this.usesDefaultFootprint = false,
    this.directionX = 0,
    this.directionY = 0,
    this.lengthRatio = 0,
    this.nearWidthRatio = 0,
    this.farWidthRatio = 0,
    this.attachYRatio = 0,
    this.frontWidthRatio = 0,
    this.rearWidthRatio = 0,
    this.depthRatio = 0,
    this.skewXRatio = 0,
  });

  final String id;
  final String label;
  final String letter;
  final ProjectedBuildingShadowGeometryMode geometryMode;
  final bool usesDefaultFootprint;
  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;
  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
  final double anchorXRatio;
  final double anchorYRatio;
  final double opacity;
  final String colorHexRgb;
}

final class _MicroPoint {
  const _MicroPoint(this.x, this.y);

  final double x;
  final double y;
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

Le rapport courant est le fichier rapport créé par le lot ; il n'est pas recopié récursivement dans cette section.

Checklist finale :
- [x] Harness manuel créé sous packages/map_runtime/tool/shadow
- [x] PNG artifact créé
- [x] PNG dans reports/shadows/screenshots
- [x] Aucun fichier baseline créé
- [x] Aucun matchesGoldenFile
- [x] Aucun Selbrume modifié ou lu pour générer l'image
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] Image 480x480 ou taille documentée
- [x] Colonne A Directional V0 présente
- [x] Colonne B Footprint V0 présente
- [x] Colonne C Footprint V1 présente
- [x] Shadow-only présent
- [x] Shadow + building présent
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] pokemon-building-shadow-footprint-v1 utilisé
- [x] attachYRatio 0.82 utilisé
- [x] frontWidthRatio 1.30 utilisé
- [x] rearWidthRatio 1.42 utilisé
- [x] depthRatio 0.26 utilisé
- [x] skewXRatio 0.08 utilisé
- [x] opacity 0.24 utilisée
- [x] colorHexRgb 606060 utilisé
- [x] Points V1 vérifiés
- [x] Bounds V1 vérifiés
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
