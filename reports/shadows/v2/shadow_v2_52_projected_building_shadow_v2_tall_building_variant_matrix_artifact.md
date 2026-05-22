# ShadowV2-52 — Projected Building Shadow V2 Tall Building Variant Matrix Artifact

## 1. Résumé exécutif

ShadowV2-52 a produit un artifact visuel contrôlé comparant 5 variantes tall-building pour le même bâtiment `tall_shop_4x7`.

Résultat :

```text
Harness manuel créé : packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
PNG créé : reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
Rapport créé : reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
```

Validation :

```text
PNG : 1000 x 480
SHA-256 : 9f6ccb75df10c5116d3cf2e332576b593d10eed6706ad4b75dd875d3b94a4226
Test ciblé : passé
Analyze ciblé : No issues found
Audit anti-dérive final : no output
```

Ce lot ne choisit pas un profil tall officiel. Il produit seulement la preuve visuelle pour le prochain design gate.

## 2. Objectif du lot

Objectif exact :

```text
Générer un artifact PNG contrôlé comparant plusieurs variantes d’ombre ShadowV2 footprint
pour un bâtiment haut / façade verticale,
afin de déterminer si la calibration standard est suffisante
ou si un profil tall-building doit être introduit.
```

Ce lot reste :

```text
manuel
contrôlé
non-baseline
sans production
sans JSON/persistence
sans Selbrume
sans profil tall officiel
```

## 3. Rappel ShadowV2-51

ShadowV2-51 a tranché :

```text
Ne pas aller vers JSON/persistence maintenant.
Ne pas modifier la calibration standard.
Ne pas créer de profil tall officiel maintenant.
Créer d’abord une matrice contrôlée pour le bâtiment C.
```

Diagnostic Lot 51 :

```text
A simple_house_4x5 : standard V2 suffisante.
B wide_house_6x5 : standard V2 suffisante.
C tall_shop_4x7 : standard V2 prometteuse mais potentiellement trop timide.
D small_kiosk_3x4 : standard V2 suffisante.
```

## 4. État initial du worktree

Commande initiale :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/shadows/v2/shadow_v2_51_projected_building_shadow_v2_multi_building_visual_review_tall_variant_decision.md
```

Fichiers préexistants avant ShadowV2-52 :

```text
reports/shadows/v2/shadow_v2_51_projected_building_shadow_v2_multi_building_visual_review_tall_variant_decision.md
```

Fichiers hors scope déjà présents :

```text
Aucun fichier hors scope modifié ; le rapport Lot 51 est un rapport précédent non suivi.
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills consultés ou appliqués :

```text
superpowers:using-superpowers
superpowers:test-driven-development
superpowers:verification-before-completion
superpowers:subagent-driven-development
karpathy-guidelines
dart-add-unit-test
dart-run-static-analysis
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté.
Les vérifications Flutter/Dart ont été faites via les skills génériques disponibles,
les patterns locaux des harnesses ShadowV2, flutter_test et flutter analyze ciblé.
```

Sub-agents utilisés :

```text
Audit sub-agent : utilisé.
Flutter/Dart visual harness sub-agent : utilisé.
Tall visual comparison sub-agent : utilisé.
Test/analyze/evidence sub-agent : utilisé.
```

Synthèse :

```text
Audit : Lot 51 préexistant non suivi, trois cibles Lot 52 absentes avant création, scope confirmé.
Harness : reprendre PictureRecorder -> Canvas -> toImage -> ImageByteFormat png/rawRgba ; pipeline resolver -> adapter -> renderer.
Visual comparison : A-E assez distincts, même tall_shop_4x7 partout, B/C/E proches mais comparables.
Evidence : test, analyze, hash, file, ls, anti-dérive et git final requis.
```

## 6. Décision AGENTS / design gate déjà satisfait

Commandes AGENTS :

```bash
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

AGENTS trouvés :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Lignes pertinentes :

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
```

Décision :

```text
Le design gate ShadowV2-51 a autorisé la matrice tall-building.
ShadowV2-52 peut créer uniquement le harness manuel, le PNG et le rapport.
```

## 7. Fichiers créés / modifiés / supprimés

Fichiers créés par ShadowV2-52 :

```text
packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
```

Fichiers modifiés :

```text
Aucun fichier préexistant modifié.
```

Fichiers supprimés :

```text
Aucun
```

Fichiers préexistants encore non suivis :

```text
reports/shadows/v2/shadow_v2_51_projected_building_shadow_v2_multi_building_visual_review_tall_variant_decision.md
```

Fichiers de production modifiés :

```text
Aucun
```

Fichiers de test existants modifiés :

```text
Aucun
```

## 8. Stratégie d’artifact tall-building

Stratégie :

```text
Même bâtiment C dans chaque colonne.
Même métrique dans chaque variante : left 68, top 48, visualWidth 64, visualHeight 112.
Seule la calibration footprint varie.
Deux lignes : shadow-only et shadow + tall building.
Labels vectoriels A-E.
Pas de texte, police externe, asset, Selbrume ou baseline.
```

But :

```text
Comparer la standard V2 actuelle à plusieurs variantes plus profondes ou plus attachées,
sans introduire un profil tall officiel.
```

## 9. Bâtiment C contrôlé

Bâtiment unique utilisé :

```text
id: tall_shop_4x7
width: 64
height: 112
left: 68
top: 48
bottom: 160
```

Style :

```text
corps haut
toit / enseigne
porte basse
fenêtres verticales
contour visible
```

Couleurs :

```text
body    = #E9D7B9
roof    = #B7655A
outline = #343A3D
door    = #7E5547
windows = #8EC6D8
sign    = #D5C185
```

Contrôle :

```text
Le même dessin tall_shop_4x7 est utilisé dans toutes les colonnes.
```

## 10. Variantes générées

A — Standard V2 current :

```text
id: candidate-a-standard-v2-current
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

B — Tall deeper :

```text
id: candidate-b-tall-deeper
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.34
skewXRatio: 0.08
opacity: 0.25
colorHexRgb: 606060
```

C — Tall deeper softer :

```text
id: candidate-c-tall-deeper-softer
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.45
depthRatio: 0.38
skewXRatio: 0.08
opacity: 0.23
colorHexRgb: 606060
```

D — Tall attached :

```text
id: candidate-d-tall-attached
attachYRatio: 0.76
frontWidthRatio: 1.24
rearWidthRatio: 1.38
depthRatio: 0.34
skewXRatio: 0.08
opacity: 0.25
colorHexRgb: 606060
```

E — Tall reference-like :

```text
id: candidate-e-tall-reference-like
attachYRatio: 0.78
frontWidthRatio: 1.34
rearWidthRatio: 1.50
depthRatio: 0.40
skewXRatio: 0.10
opacity: 0.23
colorHexRgb: 606060
```

## 11. Description de l’image générée

Chemin :

```text
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Dimensions :

```text
width = 1000
height = 480
```

Organisation :

```text
5 colonnes de 200 px : A, B, C, D, E
header = 32 px
ligne 1 = shadow-only, top 32, height 224
ligne 2 = shadow + tall_shop_4x7, top 256, height 224
```

## 12. Pipeline de rendu utilisé

Pipeline utilisé :

```text
ProjectBuildingShadowPreset
+ ProjectElementProjectedBuildingShadowConfig
+ StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

Audit du harness :

```text
23:        resolveProjectedBuildingShadowGeometry;
314:  const ShadowRuntimeRenderer().renderCollectionPass(
333:  return createProjectedBuildingShadowRuntimeInstruction(
341:  final geometry = resolveProjectedBuildingShadowGeometry(
374:    footprint: ProjectedShadowFootprintTuning(
```

## 13. Géométries / points générés par variante

A — Standard V2 current :

```text
frontLeft  = (58.40, 139.84)
frontRight = (141.60, 139.84)
rearRight  = (150.56, 168.96)
rearLeft   = (59.68, 168.96)
bounds     = left 58.40, top 139.84, width 92.16, height 29.12
opacity    = 0.24
color      = 606060
```

B — Tall deeper :

```text
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (150.56, 175.68)
rearLeft   = (59.68, 175.68)
bounds     = left 58.40, top 137.60, width 92.16, height 38.08
opacity    = 0.25
color      = 606060
```

C — Tall deeper softer :

```text
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (151.52, 180.16)
rearLeft   = (58.72, 180.16)
bounds     = left 58.40, top 137.60, width 93.12, height 42.56
opacity    = 0.23
color      = 606060
```

D — Tall attached :

```text
frontLeft  = (60.32, 133.12)
frontRight = (139.68, 133.12)
rearRight  = (149.28, 171.20)
rearLeft   = (60.96, 171.20)
bounds     = left 60.32, top 133.12, width 88.96, height 38.08
opacity    = 0.25
color      = 606060
```

E — Tall reference-like :

```text
frontLeft  = (57.12, 135.36)
frontRight = (142.88, 135.36)
rearRight  = (154.40, 180.16)
rearLeft   = (58.40, 180.16)
bounds     = left 57.12, top 135.36, width 97.28, height 44.80
opacity    = 0.23
color      = 606060
```

## 14. Assertions du test

Assertions globales :

```text
image.width == 1000
image.height == 480
PNG écrit
fichier existe
fichier size > 0
background pixel == #D8E0C8
```

Assertions par variante :

```text
shadow-only pixel au centroïde != background
shadow + building : building body pixel == #E9D7B9
shadow + building : visible shadow pixel below building != background
visible shadow pixel != body color
points attendus vérifiés avec tolérance 0.02
bounds attendus vérifiés avec tolérance 0.02
opacity attendue vérifiée
colorHexRgb == 606060
```

## 15. Résultat de génération PNG

Commande :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
00:00 +0: generates projected building shadow v2 tall building variant matrix artifact
00:00 +1: All tests passed!
```

## 16. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   9.9K May 22 16:42 reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Commande :

```bash
shasum -a 256 reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Sortie :

```text
9f6ccb75df10c5116d3cf2e332576b593d10eed6706ad4b75dd875d3b94a4226  reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png: PNG image data, 1000 x 480, 8-bit/color RGBA, non-interlaced
```

## 17. Résultats des tests

Commande finale :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
00:00 +0: generates projected building shadow v2 tall building variant matrix artifact
00:00 +1: All tests passed!
```

RED/GREEN observé :

```text
Premier test ciblé passé.
Analyze a ensuite signalé deux prefer_const_declarations.
Après correction locale dans le harness, test ciblé et analyze ciblé sont passés.
```

## 18. Résultat analyze

Commande finale :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_tall_building_variant_matrix_artifact_test.dart...     
No issues found! (ran in 1.0s)
```

## 19. Audit anti-dérive

Commande :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
```

Sortie :

```text
(no output)
```

Conclusion :

```text
Aucun matchesGoldenFile.
Aucun chemin baseline.
Aucun SHADOW_SCREENSHOT.
Aucun Selbrume.
Aucun genericProjection.
Aucun applyElementAutoShadowPolicyToProject.
Aucun diagnoseProjectedBuildingShadows.
Aucun build_runner.
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
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
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
profil tall officiel persistant
image autre que le PNG artifact autorisé
```

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale observée pour les fichiers suivis :

```text
(no output)
```

Note :

```text
Les fichiers Lot 52 sont non suivis ; git diff --stat ne liste pas les fichiers non suivis.
```

## 23. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale observée pour les fichiers suivis :

```text
(no output)
```

Note :

```text
Les fichiers Lot 52 sont non suivis ; git diff --name-status ne liste pas les fichiers non suivis.
```

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale observée :

```text
(no output)
```

## 25. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale observée :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
?? reports/shadows/v2/shadow_v2_51_projected_building_shadow_v2_multi_building_visual_review_tall_variant_decision.md
?? reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
```

Note :

```text
Le rapport Lot 51 était préexistant avant ShadowV2-52.
Les trois autres fichiers sont les créations ShadowV2-52.
```

## 26. Analyse visuelle provisoire

Lecture de l'image générée :

```text
A Standard V2 est le témoin le plus court.
B Tall deeper augmente nettement la profondeur sans changer la largeur.
C Tall deeper softer descend davantage avec opacité plus basse ; différence visible mais subtile face à B/E.
D Tall attached remonte l'attache et réduit la largeur, ce qui donne une masse plus tenue sous le volume.
E Tall reference-like est la plus large/profonde et la plus proche d'une ombre de grand bâtiment, avec risque de plaque à surveiller.
```

Conclusion provisoire :

```text
La matrice permet de comparer standard vs tall.
Le bâtiment C est identique dans toutes les colonnes.
Les variantes sont assez distinctes pour un design gate Lot 53.
```

## 27. Risques / réserves

```text
L'artifact ne choisit pas la variante finale.
B/C/E sont visibles mais pas spectaculairement différentes ; le Lot 53 doit juger avec prudence.
Un profil tall pourrait ajouter de la complexité d'authoring plus tard.
La persistence JSON reste hors scope.
Selbrume reste hors scope.
Les petits props, lampadaires, poteaux et objets fins restent hors scope.
```

## 28. Auto-critique

Le lot a-t-il créé une baseline par accident ?

```text
Non. Aucun fichier baseline ou golden créé.
```

Le PNG est-il bien un artifact manuel ?

```text
Oui. Il est généré par un harness sous packages/map_runtime/tool/shadow et placé dans reports/shadows/screenshots.
```

Le test écrit-il seulement l’image autorisée ?

```text
Oui. Il écrit uniquement shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png.
```

L’image permet-elle vraiment de comparer Standard V2 vs variantes tall ?

```text
Oui. A est le témoin standard ; B-E explorent profondeur, attache, largeur et opacité.
```

Le bâtiment C est-il identique dans toutes les colonnes ?

```text
Oui. Les métriques et le dessin tall_shop_4x7 sont constants.
```

Les variantes sont-elles rendues via resolver + adapter + renderer ?

```text
Oui. Le harness appelle resolveProjectedBuildingShadowGeometry, createProjectedBuildingShadowRuntimeInstruction et ShadowRuntimeRenderer.renderCollectionPass.
```

Le panel bâtiment aide-t-il à juger l’attachement au volume ?

```text
Oui. Chaque colonne a shadow-only et shadow + tall building.
```

Le harness dépend-il de Selbrume ou d’un asset externe ?

```text
Non. Tout est dessiné en dart:ui.
```

Les defaults ProjectedShadowFootprintTuning() sont-ils inchangés ?

```text
Oui. Aucun fichier map_core/lib n'a été modifié et chaque variante utilise un ProjectedShadowFootprintTuning explicite.
```

JSON/persistence est-il hors scope ?

```text
Oui.
```

Le lot évite-t-il les petits props / lampadaires / objets fins ?

```text
Oui. Il se limite au tall_shop_4x7.
```

Les skills Flutter/Dart disponibles ont-ils été utilisés ?

```text
Oui pour les skills génériques Dart/Flutter disponibles. Aucun skill explicitement nommé Google Flutter/Dart n'a été détecté.
```

Les sub-agents ou passes équivalentes ont-ils été utilisés ?

```text
Oui. Audit, harness, visual comparison et evidence.
```

Le rapport contient-il toutes les preuves ?

```text
Oui.
```

## 29. Regard critique sur le prompt

Le prompt est strict et utile.

Point important :

```text
Le prompt demande 1000x480. Un sub-agent a suggéré 800x480, mais le harness respecte bien 1000x480.
```

Point de vigilance :

```text
Les labels A-E sont volontairement vectoriels et courts ; la légende de ce rapport est nécessaire pour associer chaque colonne à son variant.
```

## 30. Prochain lot recommandé

Si une variante tall ressort clairement :

```text
ShadowV2-53 — Projected Building Shadow V2 Tall Variant Visual Review / Selection Design Gate
```

Objectif :

```text
Choisir si un profil tall-building doit être introduit,
ou si la calibration standard reste suffisante.
```

Si aucune variante tall n’est meilleure que la standard :

```text
ShadowV2-53 — Projected Building Shadow V2 Persistence Design Gate
```

Objectif :

```text
Préparer la persistance JSON/preset ShadowV2 footprint officielle,
sans Selbrume,
sans rollout map,
sans renderer/painter.
```

## 31. Code complet des fichiers créés/modifiés

Fichier rapport courant :

```text
reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
```

Ce rapport courant est le fichier rapport créé. Il n'est pas recopié récursivement dans lui-même.

Fichier binaire créé :

```text
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
size: 9.9K
sha256: 9f6ccb75df10c5116d3cf2e332576b593d10eed6706ad4b75dd875d3b94a4226
file: PNG image data, 1000 x 480, 8-bit/color RGBA, non-interlaced
```

Fichier tool créé :

```dart
import 'dart:io';
import 'dart:math' as math;
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

const _artifactWidth = 1000;
const _artifactHeight = 480;
const _columnWidth = 200;
const _headerHeight = 32;
const _rowHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = 256;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _labelColor = ui.Color(0xFF343A3D);
const _buildingBodyColor = ui.Color(0xFFE9D7B9);
const _buildingRoofColor = ui.Color(0xFFB7655A);
const _buildingOutlineColor = ui.Color(0xFF343A3D);
const _buildingDoorColor = ui.Color(0xFF7E5547);
const _buildingWindowColor = ui.Color(0xFF8EC6D8);
const _buildingSignColor = ui.Color(0xFFD5C185);

const _buildingLeft = 68.0;
const _buildingTop = 48.0;
const _buildingWidth = 64.0;
const _buildingHeight = 112.0;

const _candidates = [
  _TallShadowCandidate(
    id: 'candidate-a-standard-v2-current',
    label: 'A',
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
    opacity: 0.24,
    expectedPoints: [
      _ExpectedPoint(x: 58.40, y: 139.84),
      _ExpectedPoint(x: 141.60, y: 139.84),
      _ExpectedPoint(x: 150.56, y: 168.96),
      _ExpectedPoint(x: 59.68, y: 168.96),
    ],
    expectedLeft: 58.40,
    expectedTop: 139.84,
    expectedWidth: 92.16,
    expectedHeight: 29.12,
  ),
  _TallShadowCandidate(
    id: 'candidate-b-tall-deeper',
    label: 'B',
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.34,
    skewXRatio: 0.08,
    opacity: 0.25,
    expectedPoints: [
      _ExpectedPoint(x: 58.40, y: 137.60),
      _ExpectedPoint(x: 141.60, y: 137.60),
      _ExpectedPoint(x: 150.56, y: 175.68),
      _ExpectedPoint(x: 59.68, y: 175.68),
    ],
    expectedLeft: 58.40,
    expectedTop: 137.60,
    expectedWidth: 92.16,
    expectedHeight: 38.08,
  ),
  _TallShadowCandidate(
    id: 'candidate-c-tall-deeper-softer',
    label: 'C',
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.45,
    depthRatio: 0.38,
    skewXRatio: 0.08,
    opacity: 0.23,
    expectedPoints: [
      _ExpectedPoint(x: 58.40, y: 137.60),
      _ExpectedPoint(x: 141.60, y: 137.60),
      _ExpectedPoint(x: 151.52, y: 180.16),
      _ExpectedPoint(x: 58.72, y: 180.16),
    ],
    expectedLeft: 58.40,
    expectedTop: 137.60,
    expectedWidth: 93.12,
    expectedHeight: 42.56,
  ),
  _TallShadowCandidate(
    id: 'candidate-d-tall-attached',
    label: 'D',
    attachYRatio: 0.76,
    frontWidthRatio: 1.24,
    rearWidthRatio: 1.38,
    depthRatio: 0.34,
    skewXRatio: 0.08,
    opacity: 0.25,
    expectedPoints: [
      _ExpectedPoint(x: 60.32, y: 133.12),
      _ExpectedPoint(x: 139.68, y: 133.12),
      _ExpectedPoint(x: 149.28, y: 171.20),
      _ExpectedPoint(x: 60.96, y: 171.20),
    ],
    expectedLeft: 60.32,
    expectedTop: 133.12,
    expectedWidth: 88.96,
    expectedHeight: 38.08,
  ),
  _TallShadowCandidate(
    id: 'candidate-e-tall-reference-like',
    label: 'E',
    attachYRatio: 0.78,
    frontWidthRatio: 1.34,
    rearWidthRatio: 1.50,
    depthRatio: 0.40,
    skewXRatio: 0.10,
    opacity: 0.23,
    expectedPoints: [
      _ExpectedPoint(x: 57.12, y: 135.36),
      _ExpectedPoint(x: 142.88, y: 135.36),
      _ExpectedPoint(x: 154.40, y: 180.16),
      _ExpectedPoint(x: 58.40, y: 180.16),
    ],
    expectedLeft: 57.12,
    expectedTop: 135.36,
    expectedWidth: 97.28,
    expectedHeight: 44.80,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow v2 tall building variant matrix artifact',
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
      final instruction = _instructionForCandidate(candidate);

      expect(geometry.opacity, candidate.opacity);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      for (var pointIndex = 0; pointIndex < candidate.expectedPoints.length; pointIndex += 1) {
        _expectPointClose(
          geometry.points[pointIndex],
          x: candidate.expectedPoints[pointIndex].x,
          y: candidate.expectedPoints[pointIndex].y,
        );
      }
      _expectBoundsClose(instruction, candidate);

      final centroid = _centroid(geometry);
      final shadowOnlyPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowOnlyPixel,
        isNot(backgroundPixel),
        reason: '${candidate.id} shadow-only should render',
      );

      final buildingBodyPixel = await _pixelAt(
        image,
        columnLeft + 76,
        _buildingRowTop + 104,
      );
      expect(
        buildingBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.id} body should render above shadow',
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
        reason: '${candidate.id} visible shadow should render below building',
      );
      expect(
        visibleShadowPixel,
        isNot(_rgba(_buildingBodyColor)),
        reason: '${candidate.id} visible shadow should not be covered by body',
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
    _drawLabel(canvas, candidate.label, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _buildingRowTop.toDouble());
    _drawTallShop(canvas, columnLeft, _buildingRowTop.toDouble());
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
  for (var x = left; x <= left + _columnWidth; x += 32) {
    canvas.drawLine(ui.Offset(x, top), ui.Offset(x, top + _rowHeight), paint);
  }
  for (var y = top; y <= top + _rowHeight; y += 32) {
    canvas.drawLine(ui.Offset(left, y), ui.Offset(left + _columnWidth, y), paint);
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;
  for (var x = _columnWidth; x < _artifactWidth; x += _columnWidth) {
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
  _TallShadowCandidate candidate,
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
  _TallShadowCandidate candidate,
) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionForCandidate(candidate)],
  );
}

ShadowRuntimeRenderInstruction _instructionForCandidate(
  _TallShadowCandidate candidate,
) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryForCandidate(candidate),
  );
}

ProjectedBuildingShadowGeometry _geometryForCandidate(
  _TallShadowCandidate candidate,
) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _shadowConfigForCandidate(candidate),
    preset: _shadowPresetForCandidate(candidate),
    metrics: _metrics(),
  );
  if (geometry == null) {
    throw StateError('${candidate.id} did not produce geometry');
  }
  return geometry;
}

StaticShadowVisualMetrics _metrics() {
  return StaticShadowVisualMetrics(
    left: _buildingLeft,
    top: _buildingTop,
    visualWidth: _buildingWidth,
    visualHeight: _buildingHeight,
  );
}

ProjectBuildingShadowPreset _shadowPresetForCandidate(
  _TallShadowCandidate candidate,
) {
  return ProjectBuildingShadowPreset(
    id: candidate.id,
    name: candidate.id,
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
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _shadowConfigForCandidate(
  _TallShadowCandidate candidate,
) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: candidate.id,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _drawTallShop(ui.Canvas canvas, double columnLeft, double rowTop) {
  final left = columnLeft + _buildingLeft;
  final top = rowTop + _buildingTop;
  const width = _buildingWidth;
  const height = _buildingHeight;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);
  final sign = _fillPaint(_buildingSignColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 16, width, height - 16), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 16, width, height - 16), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 18), roof);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 18), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 22, width - 16, 12), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 22, width - 16, 12), outline);
  _drawDoor(canvas, left + width / 2 - 8, top + height - 32, 16, 32);
  _drawWindow(canvas, left + 12, top + 58, 14, 22);
  _drawWindow(canvas, left + width - 26, top + 58, 14, 22);
}

void _drawDoor(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_buildingDoorColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

void _drawWindow(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_buildingWindowColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

ui.Paint _fillPaint(ui.Color color) {
  return ui.Paint()
    ..color = color
    ..style = ui.PaintingStyle.fill;
}

ui.Paint _outlinePaint() {
  return ui.Paint()
    ..color = _buildingOutlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
}

void _drawLabel(
  ui.Canvas canvas,
  String label, {
  required double columnLeft,
}) {
  final paint = ui.Paint()
    ..color = _labelColor
    ..strokeWidth = 3
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.square;
  final x = columnLeft + 90;
  const top = 8.0;
  const bottom = 24.0;
  const width = 20.0;
  const middle = 16.0;
  final left = x;
  final right = x + width;
  switch (label) {
    case 'A':
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(x + width / 2, top), paint);
      canvas.drawLine(ui.Offset(x + width / 2, top), ui.Offset(right, bottom), paint);
      canvas.drawLine(ui.Offset(left + 4, middle), ui.Offset(right - 4, middle), paint);
    case 'B':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top + 3), paint);
      canvas.drawLine(ui.Offset(right - 3, top + 3), ui.Offset(right - 3, middle - 2), paint);
      canvas.drawLine(ui.Offset(right - 3, middle - 2), ui.Offset(left, middle), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle + 3), paint);
      canvas.drawLine(ui.Offset(right, middle + 3), ui.Offset(right - 2, bottom - 2), paint);
      canvas.drawLine(ui.Offset(right - 2, bottom - 2), ui.Offset(left, bottom), paint);
    case 'C':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left + 3, top), paint);
      canvas.drawLine(ui.Offset(left + 3, top), ui.Offset(left, middle), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(left + 3, bottom), paint);
      canvas.drawLine(ui.Offset(left + 3, bottom), ui.Offset(right, bottom), paint);
    case 'D':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 2, top + 4), paint);
      canvas.drawLine(ui.Offset(right - 2, top + 4), ui.Offset(right - 2, bottom - 4), paint);
      canvas.drawLine(ui.Offset(right - 2, bottom - 4), ui.Offset(left, bottom), paint);
    case 'E':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left, top), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right - 4, middle), paint);
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(right, bottom), paint);
  }
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 tall building matrix artifact as PNG');
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
    _colorByte(color.r),
    _colorByte(color.g),
    _colorByte(color.b),
    _colorByte(color.a),
  );
}

int _colorByte(double value) {
  return (value * 255.0).round().clamp(0, 255).toInt();
}

ProjectedBuildingShadowPoint _centroid(ProjectedBuildingShadowGeometry geometry) {
  var totalX = 0.0;
  var totalY = 0.0;
  for (final point in geometry.points) {
    totalX += point.x;
    totalY += point.y;
  }
  return ProjectedBuildingShadowPoint(
    x: totalX / geometry.points.length,
    y: totalY / geometry.points.length,
  );
}

ProjectedBuildingShadowPoint _visibleShadowPoint(ProjectedBuildingShadowGeometry geometry) {
  final rearCenterX = (geometry.points[2].x + geometry.points[3].x) / 2;
  final rearY = math.max(geometry.points[2].y, geometry.points[3].y);
  return ProjectedBuildingShadowPoint(
    x: rearCenterX,
    y: math.max(163, rearY.round() - 3).toDouble(),
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

void _expectBoundsClose(
  ShadowRuntimeRenderInstruction instruction,
  _TallShadowCandidate candidate,
) {
  expect(instruction.worldLeft, closeTo(candidate.expectedLeft, 0.02));
  expect(instruction.worldTop, closeTo(candidate.expectedTop, 0.02));
  expect(instruction.width, closeTo(candidate.expectedWidth, 0.02));
  expect(instruction.height, closeTo(candidate.expectedHeight, 0.02));
}

final class _TallShadowCandidate {
  const _TallShadowCandidate({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
    required this.expectedPoints,
    required this.expectedLeft,
    required this.expectedTop,
    required this.expectedWidth,
    required this.expectedHeight,
  });

  final String id;
  final String label;
  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
  final double opacity;
  final List<_ExpectedPoint> expectedPoints;
  final double expectedLeft;
  final double expectedTop;
  final double expectedWidth;
  final double expectedHeight;
}

final class _ExpectedPoint {
  const _ExpectedPoint({
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
- [x] Image 1000x480 ou taille documentée
- [x] Colonne A Standard V2 présente
- [x] Colonne B Tall deeper présente
- [x] Colonne C Tall deeper softer présente
- [x] Colonne D Tall attached présente
- [x] Colonne E Tall reference-like présente
- [x] Shadow-only présent
- [x] Shadow + building présent
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] ProjectedShadowFootprintTuning explicite utilisé
- [x] Aucun ProjectedShadowFootprintTuning() default utilisé pour les variantes
- [x] Points des 5 variantes vérifiés
- [x] Bounds des 5 variantes vérifiés
- [x] Opacity des 5 variantes vérifiée
- [x] colorHexRgb 606060 vérifié
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
