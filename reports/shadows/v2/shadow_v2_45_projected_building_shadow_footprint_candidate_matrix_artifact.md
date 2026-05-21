# ShadowV2-45 — Projected Building Shadow Footprint Candidate Matrix Artifact V0

## 1. Résumé exécutif

Lot exécuté : **ShadowV2-45 — Projected Building Shadow Footprint Candidate Matrix Artifact V0**.

Résultat :

```text
1 harness manuel créé sous packages/map_runtime/tool/shadow.
1 PNG artifact contrôlé créé sous reports/shadows/screenshots.
1 rapport Markdown créé sous reports/shadows/v2.
0 fichier de production modifié.
0 test existant modifié.
0 baseline/golden.
0 Selbrume.
0 JSON/codec.
```

L'image générée compare `R | A | B | C | D | E | F` sur deux lignes :

```text
ligne 1 = shadow-only
ligne 2 = shadow + building
```

Le pipeline de rendu utilisé est le pipeline demandé :

```text
resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

## 2. Objectif du lot

Objectif exact :

```text
Générer une matrice visuelle comparant plusieurs calibrations Footprint V0,
afin de choisir une calibration footprint officielle ou presque officielle,
sans modifier le modèle,
sans modifier renderer/painter,
sans baseline,
sans Selbrume,
sans JSON,
sans production.
```

Ce lot ne choisit pas définitivement la calibration finale. Il produit une image de comparaison pour une revue visuelle ultérieure.

## 3. Rappel ShadowV2-44

ShadowV2-44 a recommandé :

```text
Option B — Créer une matrice de variantes footprint.
```

Raisons :

```text
Footprint V0 est meilleur que Directional V0.
Footprint V0 n'est pas encore final.
Les paramètres footprint doivent être comparés visuellement avant propagation.
Le modèle, le renderer, le painter, JSON, Selbrume et les baselines restent hors scope.
```

Candidates à comparer :

```text
R — Directional V0 reference
A — Current Footprint V0
B — Deeper footprint
C — Wider footprint
D — Higher attached footprint
E — Stronger skew footprint
F — Broad shallow Pokémon-like
```

## 4. État initial du worktree

Commande initiale :

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
Aucun fichier modifié ou non suivi au départ.
```

État préexistant notable :

```text
Le rapport Lot 44 est maintenant tracked dans le dépôt au début du Lot 45,
alors que son propre rapport final documentait un état non suivi à la fin du Lot 44.
Cet état est préexistant au Lot 45 et n'a pas été modifié.
```

Fichiers Lot 45 absents avant création :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills utilisés :

```text
superpowers:using-superpowers
karpathy-guidelines
superpowers:subagent-driven-development
superpowers:verification-before-completion
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter / Google Dart n'a été détecté dans la liste des skills disponibles.
Des skills Dart/Flutter génériques existent, mais aucun skill Google spécifique n'a été détecté.
```

Dart MCP :

```text
Le serveur Dart MCP était disponible, mais son run_tests a refusé la racine projet :
Invalid root file:///Users/karim/Project/pokemonProject, must be under one of the registered project roots:

La vérification test a donc été lancée via la commande Flutter shell obligatoire du lot.
```

Sub-agents utilisés :

```text
1. Audit sub-agent : utilisé.
2. Flutter/Dart visual harness sub-agent : utilisé.
3. Visual comparison sub-agent : utilisé.
4. Test/analyze/evidence sub-agent : passe équivalente faite localement.
```

Pourquoi la passe 4 est locale :

```text
Les commandes test/analyze/evidence écrivent ou vérifient l'artifact PNG autorisé.
Elles ont été gardées dans le thread principal pour contrôler exactement les fichiers créés et les preuves finales.
```

Synthèse sub-agents :

```text
Audit :
- AGENTS.md unique détecté.
- git status initial clean.
- Lot 44 tracked au départ, état préexistant.
- Fichiers Lot 45 absents avant création.

Flutter/Dart visual harness :
- Recommande de reprendre le harness Lot 43.
- Recommande le pipeline resolver -> adapter -> renderer.
- Rejette la construction manuelle de ShadowRuntimeRenderInstruction.
- Confirme PictureRecorder / toImage / ImageByteFormat comme pattern local.

Visual comparison :
- 1120x480 et 7 colonnes de 160 px sont lisibles.
- Deux lignes shadow-only / shadow+building permettent de comparer forme brute et attachement.
- Les labels doivent rester simples R A B C D E F.
```

## 6. Décision AGENTS / design gate déjà satisfait

AGENTS impose :

```text
préserver les boundaries package ;
ne pas élargir le scope ;
ne pas faire de git write ;
documenter les lots avec preuves ;
utiliser skills et sub-agents quand applicable.
```

Décision :

```text
Le Lot 45 reste artifact-only.
Le harness est créé uniquement sous packages/map_runtime/tool/shadow.
Le PNG est créé uniquement sous reports/shadows/screenshots.
Le rapport est créé uniquement sous reports/shadows/v2.
Aucun fichier de production n'est modifié.
```

## 7. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
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

Tests existants modifiés :

```text
Aucun
```

## 8. Stratégie de matrice visuelle

Stratégie :

```text
7 colonnes de 160 px : R | A | B | C | D | E | F.
1 header de 32 px avec label vectoriel.
1 ligne shadow-only de 224 px.
1 ligne shadow + building de 224 px.
Même fond, même grille, même bâtiment, mêmes métriques pour toutes les colonnes.
```

Pourquoi :

```text
La ligne shadow-only expose la forme brute.
La ligne shadow + building montre l'attachement au volume.
R garde une référence négative Directional V0.
A-F isolent les paramètres footprint à comparer.
```

## 9. Candidats générés

Reference R — Directional V0 :

```text
id: reference-directional-v0
label: R — Directional V0
geometryMode: directional
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
anchor: (0.5, 0.96)
opacity: 0.30
colorHexRgb: 606060
```

Candidate A — Current Footprint V0 :

```text
id: candidate-a-current-footprint-v0
label: A — Current
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Candidate B — Deeper footprint :

```text
id: candidate-b-deeper-footprint
label: B — Deeper
attachYRatio: 0.84
frontWidthRatio: 1.10
rearWidthRatio: 1.22
depthRatio: 0.36
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Candidate C — Wider footprint :

```text
id: candidate-c-wider-footprint
label: C — Wider
attachYRatio: 0.86
frontWidthRatio: 1.22
rearWidthRatio: 1.35
depthRatio: 0.30
skewXRatio: 0.10
opacity: 0.26
colorHexRgb: 606060
```

Candidate D — Higher attached footprint :

```text
id: candidate-d-higher-attached-footprint
label: D — Higher
attachYRatio: 0.80
frontWidthRatio: 1.12
rearWidthRatio: 1.25
depthRatio: 0.32
skewXRatio: 0.10
opacity: 0.27
colorHexRgb: 606060
```

Candidate E — Stronger skew footprint :

```text
id: candidate-e-stronger-skew-footprint
label: E — Skew
attachYRatio: 0.84
frontWidthRatio: 1.12
rearWidthRatio: 1.25
depthRatio: 0.32
skewXRatio: 0.18
opacity: 0.27
colorHexRgb: 606060
```

Candidate F — Broad shallow Pokémon-like :

```text
id: candidate-f-broad-shallow-footprint
label: F — Broad shallow
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

## 10. Description de l’image générée

Chemin :

```text
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Dimensions :

```text
width = 1120
height = 480
```

Organisation :

```text
R | A | B | C | D | E | F
ligne 1 : shadow-only
ligne 2 : shadow + building
```

Lecture visuelle directe :

```text
R reste la référence directionnelle diagonale.
A montre le Footprint V0 courant.
B augmente la profondeur.
C augmente la largeur.
D remonte l'attache.
E augmente le skew vers la droite.
F teste une forme très large et peu profonde.
```

## 11. Pipeline de rendu utilisé

Le harness utilise :

```text
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeInstructionCollection(...)
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Le harness ne construit pas manuellement `ShadowRuntimeRenderInstruction` en dupliquant l'adapter. Il appelle `createProjectedBuildingShadowRuntimeInstruction(...)`.

Le PNG est généré par :

```text
ui.PictureRecorder
ui.Canvas
recorder.endRecording().toImage(1120, 480)
image.toByteData(format: ui.ImageByteFormat.png)
```

## 12. Géométries / points générés par candidat

Micro-fixture :

```text
metrics.left = 32
metrics.top = 64
metrics.visualWidth = 64
metrics.visualHeight = 96
```

R — Directional V0 :

```text
points:
  (75.54, 129.77)
  (52.46, 182.55)
  (82.91, 189.58)
  (101.38, 147.36)
bounds:
  left = 52.46
  top = 129.77
  width = 48.92
  height = 59.81
opacity = 0.30
```

A — Current :

```text
points:
  (28.80, 146.56)
  (99.20, 146.56)
  (108.80, 173.44)
  (32.00, 173.44)
bounds:
  left = 28.80
  top = 146.56
  width = 80.00
  height = 26.88
opacity = 0.28
```

B — Deeper :

```text
points:
  (28.80, 144.64)
  (99.20, 144.64)
  (109.44, 179.20)
  (31.36, 179.20)
bounds:
  left = 28.80
  top = 144.64
  width = 80.64
  height = 34.56
opacity = 0.28
```

C — Wider :

```text
points:
  (24.96, 146.56)
  (103.04, 146.56)
  (113.60, 175.36)
  (27.20, 175.36)
bounds:
  left = 24.96
  top = 146.56
  width = 88.64
  height = 28.80
opacity = 0.26
```

D — Higher :

```text
points:
  (28.16, 140.80)
  (99.84, 140.80)
  (110.40, 171.52)
  (30.40, 171.52)
bounds:
  left = 28.16
  top = 140.80
  width = 82.24
  height = 30.72
opacity = 0.27
```

E — Skew :

```text
points:
  (28.16, 144.64)
  (99.84, 144.64)
  (115.52, 175.36)
  (35.52, 175.36)
bounds:
  left = 28.16
  top = 144.64
  width = 87.36
  height = 30.72
opacity = 0.27
```

F — Broad shallow :

```text
points:
  (22.40, 142.72)
  (105.60, 142.72)
  (114.56, 167.68)
  (23.68, 167.68)
bounds:
  left = 22.40
  top = 142.72
  width = 92.16
  height = 24.96
opacity = 0.24
```

## 13. Assertions du test

Assertions principales :

```text
image.width == 1120
image.height == 480
background pixel == #D8E0C8
pour chaque colonne :
  shadow-only pixel au centroïde != background
  building body pixel == #E9D7B9
  visible shadow pixel below building != background
PNG écrit
fichier existe
fichier size > 0
```

Le test ne vérifie pas une baseline et ne compare aucune image existante.

## 14. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
00:00 +0: generates projected building shadow footprint candidate matrix artifact
00:00 +1: All tests passed!
```

Résultat :

```text
PNG généré.
Test ciblé passé.
```

## 15. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Sortie :

```text
-rw-r--r--  1 karim  staff   8.6K May 22 00:15 reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Commande :

```bash
shasum -a 256 reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Sortie :

```text
76f4079a4cce27effc8aac9272894501ecec2324fba4d96654d4c318e5df9e99  reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png: PNG image data, 1120 x 480, 8-bit/color RGBA, non-interlaced
```

## 16. Résultats des tests

Test ciblé Lot 45 :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
00:00 +0: generates projected building shadow footprint candidate matrix artifact
00:00 +1: All tests passed!
```

Autres tests :

```text
Aucun. Le lot demande uniquement le test/génération artifact ciblé.
```

## 17. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_footprint_candidate_matrix_artifact_test.dart...

No issues found! (ran in 1.3s)
```

## 18. Audit anti-dérive

Commande :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
```

Sortie :

```text
(no output)
```

Résultat :

```text
Aucun matchesGoldenFile.
Aucune baseline.
Aucun SHADOW_SCREENSHOT.
Aucun Selbrume.
Aucun genericProjection.
Aucun applyElementAutoShadowPolicyToProject.
Aucun diagnoseProjectedBuildingShadows.
Aucun build_runner.
```

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
ProjectManifest codecs
project.json
```

## 20. Ce qui n’a volontairement pas été créé

```text
baseline
golden
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

Sortie avant création du rapport :

```text
(no output)
```

Note :

```text
Les fichiers créés sont non suivis ; ils apparaissent dans git status, pas dans git diff --stat.
```

## 22. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie avant création du rapport :

```text
(no output)
```

Note :

```text
Les fichiers créés sont non suivis ; ils apparaissent dans git status, pas dans git diff --name-status.
```

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie avant création du rapport :

```text
(no output)
```

Résultat :

```text
Propre.
```

## 24. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
?? reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
```

Conformité scope :

```text
Conforme. Les seuls fichiers visibles sont les trois fichiers créés par ShadowV2-45.
```

## 25. Analyse visuelle provisoire

L'image générée permet une comparaison utile :

```text
R : reste clairement la référence directionnelle diagonale.
A : témoin Footprint V0, plus propre que R mais prudent.
B : masse plus profonde, plus présente derrière le bâtiment.
C : largeur plus visible, opacité réduite utile.
D : attache plus haute, ombre davantage sous le volume.
E : skew plus marqué, direction bas-droite plus lisible.
F : plus large et plus peu profonde, très proche d'un socle mais à surveiller comme plaque.
```

Lecture provisoire :

```text
La matrice remplit son rôle : elle rend les différences A-F comparables.
Elle ne choisit pas la calibration finale.
Le banding reste visible, mais il ne doit pas encore piloter la décision.
```

## 26. Risques / réserves

```text
Les opacités 0.24 à 0.28 sont subtiles ; l'image doit être regardée à taille réelle.
La micro-fixture ne prouve pas le rendu sur assets réels.
Le bâtiment simplifié ne couvre pas les cas de silhouettes complexes.
Les bandes du renderer peuvent influencer la perception des candidats plus larges.
JSON/persistence reste hors scope.
Selbrume reste hors scope.
```

## 27. Auto-critique

Le lot a-t-il créé une baseline par accident ?

```text
Non. Aucun fichier baseline ou golden n'est créé.
```

Le PNG est-il bien un artifact manuel ?

```text
Oui. Il est écrit sous reports/shadows/screenshots et n'est comparé à aucune baseline.
```

Le test écrit-il seulement l'image autorisée ?

```text
Oui. Il écrit uniquement reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png.
```

L'image permet-elle vraiment de comparer R + A-F ?

```text
Oui. Les colonnes ont la même largeur, le même fond, la même grille, les mêmes métriques et le même bâtiment.
```

Les candidats sont-ils suffisamment différents ?

```text
Oui. Ils isolent profondeur, largeur, attache verticale, skew et profil broad shallow.
```

Chaque candidat utilise-t-il le vrai pipeline resolver + adapter + renderer ?

```text
Oui. Le harness appelle resolveProjectedBuildingShadowGeometry, createProjectedBuildingShadowRuntimeInstruction et ShadowRuntimeRenderer.renderCollectionPass.
```

Le panel bâtiment aide-t-il à juger l'attachement au volume ?

```text
Oui. La deuxième ligne montre chaque ombre recouverte par le même bâtiment simple.
```

Le harness dépend-il de Selbrume ou d'un asset externe ?

```text
Non.
```

Les skills Flutter/Dart disponibles ont-ils été utilisés ?

```text
Aucun skill Google Flutter/Dart spécifique n'a été détecté.
Les patterns Flutter/dart:ui locaux ont été audités via les harnesses existants.
Le MCP Dart a été tenté mais sa racine projet n'était pas enregistrée ; la commande Flutter shell a été utilisée pour vérifier.
```

Les sub-agents ou passes équivalentes ont-ils été utilisés ?

```text
Oui. Trois sub-agents ont été utilisés et une passe test/analyze/evidence a été faite localement.
```

Le rapport contient-il toutes les preuves ?

```text
Oui : status initial, fichiers créés, test, analyze, PNG ls/hash/file, anti-dérive, git diff/check/status, code complet du harness.
```

## 28. Regard critique sur le prompt

Le prompt est strict et utile. Il empêche :

```text
la modification prématurée du modèle ;
la modification du renderer/painter ;
l'introduction d'une baseline ;
l'utilisation de Selbrume ;
la confusion entre artifact visuel et calibration finale.
```

Point de vigilance :

```text
Le prompt demande un quatrième sub-agent test/analyze/evidence.
La vérification principale a été faite localement pour contrôler les écritures de l'artifact et le status final.
```

Pour le Lot 46, le prompt devrait demander explicitement :

```text
une revue visuelle de l'image Lot 45 ;
un choix unique ou une courte liste de finalistes ;
une décision sur le banding : toujours secondaire ou prochain audit ;
la séparation stricte entre calibration visuelle et JSON/persistence.
```

## 29. Prochain lot recommandé

Recommandation :

```text
ShadowV2-46 — Projected Building Shadow Footprint Calibration Selection Design Gate
```

Objectif :

```text
Analyser visuellement la matrice Lot 45,
choisir officiellement la calibration footprint retenue ou une dernière micro-variation,
avant de propager les valeurs dans les tests / fixtures.
```

Lot 46 ne doit pas encore :

```text
modifier Selbrume ;
modifier JSON/codecs ;
créer une baseline ;
modifier renderer/painter ;
changer le modèle Footprint V0 ;
propager une calibration sans revue visuelle documentée.
```

## 30. Code complet des fichiers créés/modifiés

Le rapport courant est le fichier rapport créé :

```text
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
```

Le PNG est un fichier binaire créé et n'est pas inliné. Inventaire binaire :

```text
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
size: 8.6K
sha256: 76f4079a4cce27effc8aac9272894501ecec2324fba4d96654d4c318e5df9e99
file: PNG image data, 1120 x 480, 8-bit/color RGBA, non-interlaced
```

### packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart

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

const _artifactWidth = 1120;
const _artifactHeight = 480;
const _columnWidth = 160;
const _headerHeight = 32;
const _rowHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = 256;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png';

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
  _referenceDirectionalCandidate(),
  ..._footprintCandidates(),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow footprint candidate matrix artifact',
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
        footprint: ProjectedShadowFootprintTuning(
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

_ShadowCandidate _referenceDirectionalCandidate() {
  return const _ShadowCandidate(
    id: 'reference-directional-v0',
    label: 'R — Directional V0',
    letter: 'R',
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

List<_ShadowCandidate> _footprintCandidates() {
  return const [
    _ShadowCandidate(
      id: 'candidate-a-current-footprint-v0',
      label: 'A — Current',
      letter: 'A',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.86,
      frontWidthRatio: 1.10,
      rearWidthRatio: 1.20,
      depthRatio: 0.28,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-b-deeper-footprint',
      label: 'B — Deeper',
      letter: 'B',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.84,
      frontWidthRatio: 1.10,
      rearWidthRatio: 1.22,
      depthRatio: 0.36,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-c-wider-footprint',
      label: 'C — Wider',
      letter: 'C',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.86,
      frontWidthRatio: 1.22,
      rearWidthRatio: 1.35,
      depthRatio: 0.30,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.26,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-d-higher-attached-footprint',
      label: 'D — Higher',
      letter: 'D',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.80,
      frontWidthRatio: 1.12,
      rearWidthRatio: 1.25,
      depthRatio: 0.32,
      skewXRatio: 0.10,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.27,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-e-stronger-skew-footprint',
      label: 'E — Skew',
      letter: 'E',
      geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
      attachYRatio: 0.84,
      frontWidthRatio: 1.12,
      rearWidthRatio: 1.25,
      depthRatio: 0.32,
      skewXRatio: 0.18,
      anchorXRatio: 0.5,
      anchorYRatio: 1,
      opacity: 0.27,
      colorHexRgb: '606060',
    ),
    _ShadowCandidate(
      id: 'candidate-f-broad-shallow-footprint',
      label: 'F — Broad shallow',
      letter: 'F',
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
    ),
  ];
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
    case 'R':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top), paint);
      canvas.drawLine(
          ui.Offset(right, top + 3), ui.Offset(right, middle - 1), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle), paint);
      canvas.drawLine(ui.Offset(left + 6, middle), ui.Offset(right, bottom), paint);
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
    case 'D':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 2, top), paint);
      canvas.drawLine(
          ui.Offset(right, top + 3), ui.Offset(right, bottom - 3), paint);
      canvas.drawLine(
          ui.Offset(left, bottom), ui.Offset(right - 2, bottom), paint);
    case 'E':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right, top), paint);
      canvas.drawLine(
          ui.Offset(left, middle), ui.Offset(right - 3, middle), paint);
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(right, bottom), paint);
    case 'F':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right, top), paint);
      canvas.drawLine(
          ui.Offset(left, middle), ui.Offset(right - 3, middle), paint);
  }
}

_Point _centroid(ProjectedBuildingShadowGeometry geometry) {
  var totalX = 0.0;
  var totalY = 0.0;
  for (final point in geometry.points) {
    totalX += point.x;
    totalY += point.y;
  }
  return _Point(
    x: totalX / geometry.points.length,
    y: totalY / geometry.points.length,
  );
}

_Point _visibleShadowPoint(ProjectedBuildingShadowGeometry geometry) {
  final rearRight = geometry.points[2];
  final rearLeft = geometry.points[3];
  return _Point(
    x: (rearRight.x + rearLeft.x) / 2,
    y: (rearRight.y + rearLeft.y) / 2 - 3,
  );
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 footprint matrix as PNG');
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
    throw StateError('Could not read raw pixels from footprint matrix image');
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

final class _ShadowCandidate {
  const _ShadowCandidate({
    required this.id,
    required this.label,
    required this.letter,
    required this.geometryMode,
    this.directionX = 0,
    this.directionY = 1,
    this.lengthRatio = 0,
    this.nearWidthRatio = 1,
    this.farWidthRatio = 1,
    this.attachYRatio = 0.86,
    this.frontWidthRatio = 1.10,
    this.rearWidthRatio = 1.20,
    this.depthRatio = 0.28,
    this.skewXRatio = 0.10,
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String id;
  final String label;
  final String letter;
  final ProjectedBuildingShadowGeometryMode geometryMode;
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

final class _Point {
  const _Point({
    required this.x,
    required this.y,
  });

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

Checklist finale :
- [x] Harness manuel créé sous packages/map_runtime/tool/shadow
- [x] PNG artifact créé
- [x] PNG dans reports/shadows/screenshots
- [x] Aucun fichier baseline créé
- [x] Aucun matchesGoldenFile
- [x] Aucun Selbrume modifié ou lu pour générer l’image
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] Image 1120x480 ou taille documentée
- [x] Colonne R Directional V0 présente
- [x] Colonne A Current Footprint présente
- [x] Colonne B Deeper présente
- [x] Colonne C Wider présente
- [x] Colonne D Higher présente
- [x] Colonne E Skew présente
- [x] Colonne F Broad shallow présente
- [x] Shadow-only présent pour chaque colonne
- [x] Shadow + building présent pour chaque colonne
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] ProjectedShadowFootprintTuning utilisé
- [x] colorHexRgb 606060 utilisé
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
