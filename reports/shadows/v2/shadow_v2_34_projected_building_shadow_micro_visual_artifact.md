# ShadowV2-34 — Projected Building Shadow Micro Visual Artifact V0

## 1. Résumé exécutif

ShadowV2-34 a créé un artifact PNG micro-fixture ShadowV2 calibré, inspectable humainement :

```text
reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

Le PNG fait `320x224`, avec deux panels :

```text
left panel  = shadow-only
right panel = shadow + simple building block
```

Le rendu utilise le vrai renderer runtime :

```text
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Ce lot n'a pas créé de baseline, n'a pas utilisé de golden, n'a pas lu Selbrume pour générer l'image et n'a modifié aucun fichier de production.

## 2. Objectif du lot

Objectif exact :

```text
Produire une image PNG micro-fixture ShadowV2 calibrée,
inspectable humainement,
pour décider si le banding hard-edge actuel est visuellement acceptable,
sans baseline CI,
sans Selbrume,
sans modifier le renderer,
sans modifier le painter,
sans modifier les données projet.
```

Statut :

```text
Objectif atteint.
```

## 3. Rappel ShadowV2-33

ShadowV2-33 a décidé :

```text
Le banding actuel est réel, volontaire, partagé runtime/editor, et techniquement stable.
Il n'est pas encore validé artistiquement.
```

Option retenue :

```text
Créer un micro visual artifact contrôlé,
lisible humainement,
sans baseline CI,
sans Selbrume.
```

Le Lot 34 applique cette décision : il produit une seule image contrôlée, sans comparer à une baseline.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text

```

Interprétation :

```text
Le worktree était propre au début du Lot 34.
```

Fichiers préexistants non liés au lot :

```text
Aucun
```

Le fichier suivant n'existait pas au début du Lot 34 :

```text
packages/map_battle/tmp_mirror.dart
```

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties utiles :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

```text
Le design gate a déjà été satisfait par ShadowV2-33.
ShadowV2-34 est une exécution strictement bornée de ce design.
```

Fichiers package lus avant création :

```text
packages/map_runtime/pubspec.yaml
packages/map_runtime/README.md
packages/map_runtime/tool/shadow/README.md
packages/map_runtime/tool/shadow/selbrume_shadow_capture_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
```

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés par ShadowV2-34 :

```text
packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
reports/shadows/v2/shadow_v2_34_projected_building_shadow_micro_visual_artifact.md
```

Fichiers modifiés par ShadowV2-34 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-34 :

```text
Aucun
```

Fichiers de production modifiés :

```text
Aucun
```

Tests existants modifiés :

```text
Aucun
```

## 7. Stratégie d’artifact visuel

Le harness est placé sous :

```text
packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Raison :

```text
Le fichier écrit volontairement une image PNG sur disque.
Il doit rester un harness manuel ciblé, hors suite standard.
```

La génération est lancée explicitement :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Le test ne compare pas l'image à une référence. Il vérifie seulement que l'artifact est non vide et qu'il contient les éléments attendus.

## 8. Description de l’image générée

Chemin :

```text
/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

Dimensions :

```text
width = 320
height = 224
```

Découpage :

```text
left panel  = 160 x 224 : shadow-only
right panel = 160 x 224 : shadow + simple building block
```

Fond :

```text
fond opaque #D8E0C8
grille discrète #E6ECD8 tous les 32 px
séparateur vertical #B5BEA7
```

Panel gauche :

```text
Ombre ShadowV2 calibrée seule.
But : regarder la forme et les bandes hard-edge.
```

Panel droit :

```text
Même ombre ShadowV2 calibrée.
Bâtiment simple dessiné par-dessus.
But : juger si l'ombre se lit sous/derrière un volume.
```

Bâtiment :

```text
left = 32
top = 64
width = 64
height = 96
corps = #E9D7B9
toit = #B7655A
contour = #343A3D
```

## 9. Calibration utilisée

Calibration ShadowV2 V0 :

```text
preset id: pokemon-building-shadow-v0
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
opacity: 0.30
colorHexRgb: 606060
anchor: (0.5, 0.96)
localOffset: (0, 0)
```

Instruction runtime directe :

```text
shape = ShadowRuntimeShapeKind.projectedPolygon
renderPass = ShadowRenderPass.groundStatic
worldLeft = 52.46
worldTop = 129.77
width = 48.92
height = 59.81
opacity = 0.30
colorHexRgb = 606060
```

Points calibrés :

```text
nearLeft  = (75.54, 129.77)
nearRight = (52.46, 182.55)
farRight  = (82.91, 189.58)
farLeft   = (101.38, 147.36)
```

Note :

```text
Le harness importe map_core uniquement pour le type ShadowRenderPass, requis par ShadowRuntimeRenderInstruction.
Il ne recalcule pas la géométrie, n'appelle pas de resolver map_core et ne modifie aucun contrat partagé.
```

## 10. Harness manuel créé

Fichier :

```text
packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Responsabilités :

```text
1. créer une image en mémoire via ui.PictureRecorder ;
2. dessiner les deux panels ;
3. dessiner le fond et la grille ;
4. dessiner l'ombre calibrée dans chaque panel ;
5. dessiner le bâtiment simple par-dessus l'ombre dans le panel droit ;
6. encoder en PNG ;
7. écrire un seul fichier dans reports/shadows/screenshots ;
8. vérifier les dimensions et quelques pixels utiles.
```

Le rendu des ombres passe par :

```text
ShadowRuntimeRenderer.renderCollectionPass(...)
```

## 11. Assertions du test

Assertions :

```text
image.width == 320
image.height == 224
background pixel == #D8E0C8
shadow pixel != background pixel
shadow pixel alpha == 255 sur fond opaque
building-over-shadow pixel == #E9D7B9
building-over-shadow pixel != shadow pixel
PNG écrit
fichier existe
file.lengthSync() > 0
```

Pixels choisis :

```text
background = (12, 12)
shadow-only interior = (80, 150)
building over shadow = (240, 150)
```

## 12. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
00:00 +0: generates projected building shadow V2 micro visual artifact
00:00 +1: All tests passed!
```

Résultat :

```text
PNG généré avec succès.
```

## 13. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
stat -f '%z bytes' reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
file reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

Sorties :

```text
-rw-r--r--@ 1 karim  staff   2.1K May 20 23:31 reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
de6a2c5fa0e02da89f7f61daa4429e5ba67e4d37983e6f8443b3dfb1284bd1aa  reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
2154 bytes
reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png: PNG image data, 320 x 224, 8-bit/color RGBA, non-interlaced
```

Chemin absolu :

```text
/Users/karim/Project/pokemonProject/reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

## 14. Résultats des tests

Commande ciblée :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter test tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
00:00 +0: generates projected building shadow V2 micro visual artifact
00:00 +1: All tests passed!
```

Tests globaux :

```text
Non lancés. Le lot demande un harness manuel ciblé, hors suite globale.
```

## 15. Résultat analyze

Premier résultat analyze :

```text
Analyzing shadow_v2_micro_visual_artifact_test.dart...          

   info • 'red' is deprecated and shouldn't be used. Use (*.r * 255.0).round().clamp(0, 255) • tool/shadow/shadow_v2_micro_visual_artifact_test.dart:205:22 • deprecated_member_use
   info • 'green' is deprecated and shouldn't be used. Use (*.g * 255.0).round().clamp(0, 255) • tool/shadow/shadow_v2_micro_visual_artifact_test.dart:205:33 • deprecated_member_use
   info • 'blue' is deprecated and shouldn't be used. Use (*.b * 255.0).round().clamp(0, 255) • tool/shadow/shadow_v2_micro_visual_artifact_test.dart:205:46 • deprecated_member_use
   info • 'alpha' is deprecated and shouldn't be used. Use (*.a * 255.0).round().clamp(0, 255) • tool/shadow/shadow_v2_micro_visual_artifact_test.dart:205:58 • deprecated_member_use

4 issues found. (ran in 1.7s)
```

Correction appliquée :

```text
Remplacement de Color.red/green/blue/alpha par Color.r/g/b/a convertis en bytes.
```

Commande finale :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime
flutter analyze tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Sortie complète finale :

```text
Analyzing shadow_v2_micro_visual_artifact_test.dart...          
No issues found! (ran in 1.3s)
```

## 16. Audit anti-dérive

Commande :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows" packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

Sortie :

```text

```

Interprétation :

```text
Aucun hit.
La commande rg retourne exit 1 quand aucun résultat n'est trouvé.
```

## 17. Ce qui n’a volontairement pas été modifié

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
```

Également non modifiés :

```text
ShadowRuntimeRenderer
MapLayersComponent
PlayableMapGame
runtime_projected_building_shadow_collection.dart
projected_building_shadow_runtime_adapter.dart
editor_static_shadow_preview_painter.dart
MapGridPainter
```

## 18. Ce qui n’a volontairement pas été créé

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

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Interprétation :

```text
Aucune sortie car les fichiers créés par ce lot sont non suivis.
Les fichiers créés sont listés explicitement dans l'inventaire du rapport.
```

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text

```

Interprétation :

```text
Aucune sortie car les fichiers créés par ce lot sont non suivis.
```

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Interprétation :

```text
git diff --check est propre.
```

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale attendue :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
?? reports/shadows/v2/shadow_v2_34_projected_building_shadow_micro_visual_artifact.md
```

Interprétation :

```text
Le statut final est conforme au scope : trois fichiers créés, aucun fichier suivi modifié.
```

## 23. Risques / réserves

```text
1. L'artifact manuel ne valide pas définitivement le rendu artistique.
2. L'image ne crée pas de garde-fou CI.
3. Le banding peut paraître acceptable sur micro-fixture mais moins bon sur vraie carte.
4. Le bâtiment simple est volontairement schématique ; il sert de volume de lecture, pas de sprite final.
5. Le harness importe map_core uniquement pour ShadowRenderPass, qui est requis par l'instruction runtime.
```

## 24. Auto-critique

Le lot a-t-il créé une baseline par accident ?

```text
Non. Aucun fichier sous reports/shadows/baselines n'a été créé.
```

Le PNG est-il bien un artifact manuel ?

```text
Oui. Il est écrit par un harness sous packages/map_runtime/tool/shadow.
```

Le test écrit-il seulement l'image autorisée ?

```text
Oui. Il écrit uniquement reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png.
```

L'image permet-elle vraiment de voir le banding ?

```text
Oui. Le panel gauche montre l'ombre seule sur fond clair.
```

Le panel bâtiment aide-t-il à juger l'ombre sous un volume ?

```text
Oui. Le panel droit dessine un bâtiment opaque au-dessus de la même ombre.
```

Le harness dépend-il de Selbrume ou d'un asset externe ?

```text
Non. Il ne lit aucune donnée projet, aucune map et aucun asset externe.
```

Le renderer utilisé est-il bien ShadowRuntimeRenderer ?

```text
Oui. Le rendu passe par ShadowRuntimeRenderer.renderCollectionPass(...).
```

La calibration utilisée correspond-elle au Lot 32 ?

```text
Oui. Les points, bounds, opacity 0.30 et colorHexRgb 606060 correspondent à la calibration V0.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Il inclut inventaire, commandes, sorties, taille/hash PNG, audit anti-dérive et code complet du harness.
```

## 25. Regard critique sur le prompt

Le prompt est bien cadré : il distingue correctement artifact manuel, screenshot et baseline. La contrainte de placer le fichier sous `tool/shadow` est saine, car le test écrit sur disque et ne doit pas entrer dans la suite standard.

Point de nuance :

```text
Une instruction runtime directe nécessite quand même ShadowRenderPass, défini dans map_core.
Le harness limite donc l'import map_core à ce seul symbole et ne recalcule pas la géométrie.
```

## 26. Prochain lot recommandé

Le prochain lot dépend de la revue humaine de l'image générée.

Si l'image est visuellement acceptable :

```text
ShadowV2-35 — Projected Building Shadow Micro Baseline Design Gate
```

Objectif :

```text
Décider si l'artifact micro peut devenir une baseline ciblée ou s'il doit rester manuel.
```

Si le banding est trop visible ou laid :

```text
ShadowV2-35 — Projected Building Shadow Hard-Edge Banding Adjustment Design Gate
```

Objectif :

```text
Comparer fill plat, bandes réduites, bandes plus nombreuses, ou autre stratégie hard-edge,
sans blur et sans shader.
```

Ne pas implémenter cela dans le Lot 34.

## 27. Code complet des fichiers créés/modifiés

Le rapport courant est le fichier créé :

```text
reports/shadows/v2/shadow_v2_34_projected_building_shadow_micro_visual_artifact.md
```

Le PNG est un fichier binaire et n'est pas inliné. Métadonnées :

```text
path: reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
size: 2154 bytes
sha256: de6a2c5fa0e02da89f7f61daa4429e5ba67e4d37983e6f8443b3dfb1284bd1aa
format: PNG image data, 320 x 224, 8-bit/color RGBA, non-interlaced
```

### `packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart`

```dart
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart' show ShadowRenderPass;
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 320;
const _artifactHeight = 224;
const _panelWidth = 160;
const _panelHeight = 224;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _buildingBodyColor = ui.Color(0xFFE9D7B9);
const _buildingRoofColor = ui.Color(0xFFB7655A);
const _buildingOutlineColor = ui.Color(0xFF343A3D);
const _buildingDoorColor = ui.Color(0xFF7E5547);
const _buildingWindowColor = ui.Color(0xFF8EC6D8);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow V2 micro visual artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 12);
    final shadowPixel = await _pixelAt(image, 80, 150);
    final buildingOverShadowPixel = await _pixelAt(image, _panelWidth + 80, 150);

    expect(backgroundPixel, _rgba(_backgroundColor));
    expect(shadowPixel, isNot(backgroundPixel));
    expect(shadowPixel.a, 255);
    expect(buildingOverShadowPixel, _rgba(_buildingBodyColor));
    expect(buildingOverShadowPixel, isNot(shadowPixel));

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

// Manual artifact harness: this intentionally writes one PNG for human review
// of the calibrated V2 hard-edge banding. It is not a golden comparison.
Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  _drawPanelBackground(canvas, 0);
  _drawPanelBackground(canvas, _panelWidth.toDouble());

  canvas.drawRect(
    ui.Rect.fromLTWH(_panelWidth.toDouble() - 0.5, 0, 1, _artifactHeight + 0.0),
    ui.Paint()..color = _dividerColor,
  );

  _drawShadow(canvas, panelLeft: 0);
  _drawShadow(canvas, panelLeft: _panelWidth.toDouble());
  _drawSimpleBuilding(canvas, panelLeft: _panelWidth.toDouble());

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawPanelBackground(ui.Canvas canvas, double panelLeft) {
  canvas.drawRect(
    ui.Rect.fromLTWH(panelLeft, 0, _panelWidth.toDouble(), _panelHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, panelLeft: panelLeft);
}

void _drawGrid(ui.Canvas canvas, {required double panelLeft}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;

  for (var x = 32.0; x < _panelWidth; x += 32) {
    canvas.drawLine(
      ui.Offset(panelLeft + x, 0),
      ui.Offset(panelLeft + x, _panelHeight.toDouble()),
      paint,
    );
  }
  for (var y = 32.0; y < _panelHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(panelLeft, y),
      ui.Offset(panelLeft + _panelWidth, y),
      paint,
    );
  }
}

void _drawShadow(ui.Canvas canvas, {required double panelLeft}) {
  canvas.save();
  canvas.translate(panelLeft, 0);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _calibratedShadowCollection(),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _calibratedShadowCollection() {
  return ShadowRuntimeInstructionCollection(
    instructions: [_calibratedShadowInstruction()],
  );
}

ShadowRuntimeRenderInstruction _calibratedShadowInstruction() {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 52.46,
    worldTop: 129.77,
    width: 48.92,
    height: 59.81,
    opacity: 0.30,
    colorHexRgb: '606060',
    polygonPoints: [
      ShadowRuntimePoint(worldX: 75.54, worldY: 129.77),
      ShadowRuntimePoint(worldX: 52.46, worldY: 182.55),
      ShadowRuntimePoint(worldX: 82.91, worldY: 189.58),
      ShadowRuntimePoint(worldX: 101.38, worldY: 147.36),
    ],
  );
}

void _drawSimpleBuilding(ui.Canvas canvas, {required double panelLeft}) {
  final left = panelLeft + 32;
  const top = 64.0;
  const width = 64.0;
  const height = 96.0;

  final body = ui.Rect.fromLTWH(left, top, width, height);
  canvas.drawRect(body, ui.Paint()..color = _buildingBodyColor);

  final roof = ui.Rect.fromLTWH(left, top, width, 22);
  canvas.drawRect(roof, ui.Paint()..color = _buildingRoofColor);

  final door = ui.Rect.fromLTWH(left + 26, top + 62, 12, 32);
  canvas.drawRect(door, ui.Paint()..color = _buildingDoorColor);

  final windowPaint = ui.Paint()..color = _buildingWindowColor;
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 36, 14, 12), windowPaint);
  canvas.drawRect(ui.Rect.fromLTWH(left + 40, top + 36, 14, 12), windowPaint);

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

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 micro visual artifact as PNG');
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
- [x] Image 320x224
- [x] Panel shadow-only présent
- [x] Panel shadow + building présent
- [x] Calibration pokemon-building-shadow-v0 utilisée
- [x] colorHexRgb 606060 utilisé
- [x] opacity 0.30 utilisée
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
