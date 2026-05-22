# ShadowV2-50 — Projected Building Shadow V2 Controlled Multi-Building Artifact

## 1. Résumé exécutif

ShadowV2-50 a produit un artifact visuel contrôlé multi-bâtiments.

Résultat :

```text
Harness manuel créé : packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
PNG créé : reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
Rapport créé : reports/shadows/v2/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.md
```

Décision tenue :

```text
La calibration ShadowV2 footprint officielle est testée sur 4 silhouettes contrôlées.
Aucun fichier de production n'est modifié.
Aucun test existant n'est modifié.
Aucun JSON, Selbrume, baseline, golden, renderer ou painter n'est touché.
```

Validation :

```text
PNG : 800 x 480
SHA-256 : 85d2d3ab03c6a1db7a405d25736aee148f14f226c81d77b2be16773b8897f845
Test ciblé : passé
Analyze ciblé : No issues found
Audit anti-dérive final : no output
git diff --check : no output
```

## 2. Objectif du lot

Objectif exact :

```text
Générer un artifact PNG contrôlé montrant plusieurs silhouettes de bâtiments différentes,
toutes rendues avec la calibration officielle ShadowV2 footprint,
afin de vérifier que la calibration tient visuellement au-delà du micro-bâtiment unique.
```

Ce lot reste un artifact manuel non-baseline. Il ne choisit pas une nouvelle calibration et ne traite pas la persistence.

## 3. Rappel ShadowV2-49

ShadowV2-49 a recommandé :

```text
Option : artifact multi-bâtiments contrôlé.
Politique lumière : direction globale canonique stylisée.
Pas de Selbrume.
Pas de JSON/persistence.
Pas de renderer/painter.
Pas d'authoring editor.
Pas de changement des defaults ProjectedShadowFootprintTuning().
```

Calibration officielle à utiliser :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

Nommage appliqué dans ce lot :

```text
pokemon-building-shadow-footprint-v2
```

Les anciens fichiers `footprint-v1` n'ont pas été renommés.

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

Fichiers préexistants avant ShadowV2-50 :

```text
Aucun fichier modifié ou non suivi au départ.
```

Fichiers hors scope déjà présents :

```text
Aucun fichier hors scope modifié ou non suivi au départ.
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
Visual corpus sub-agent : utilisé.
Test/analyze/evidence sub-agent : utilisé.
```

Synthèse :

```text
Audit : worktree initial clean, fichiers cibles absents, scope confirmé.
Harness : reprendre le pattern Lot 48 / Lot 45, PictureRecorder, toImage, ImageByteFormat, resolver -> adapter -> renderer.
Corpus : 4 bâtiments validés, bon stress largeur/hauteur/compact, pas de props fins.
Evidence : checklist rapport/test/analyze/hash/git confirmée.
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
Le design gate ShadowV2-49 a présenté et approuvé l'artifact contrôlé.
ShadowV2-50 peut créer uniquement le harness manuel, le PNG et le rapport.
```

## 7. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
reports/shadows/v2/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.md
```

Fichiers modifiés :

```text
Aucun fichier préexistant modifié.
```

Fichiers supprimés :

```text
Aucun
```

Fichiers de production modifiés :

```text
Aucun
```

Fichiers de test existants modifiés :

```text
Aucun
```

## 8. Stratégie d’artifact multi-bâtiments

Stratégie :

```text
Créer une image contrôlée 800x480.
Utiliser 4 colonnes de 200 px.
Garder deux lignes : shadow-only et shadow + building.
Rendre toutes les ombres avec la même calibration ShadowV2 footprint officielle.
Garder un fond neutre et une grille discrète.
Ne dépendre d'aucun asset externe.
```

Pourquoi :

```text
Le Lot 48 a validé un micro-bâtiment unique.
Le Lot 50 vérifie largeur, hauteur et petit volume sans mélanger Selbrume, JSON ou map réelle.
```

## 9. Corpus de bâtiments contrôlés

Corpus utilisé :

```text
A — simple_house_4x5
left 68, top 80, width 64, height 80
Rôle : maison simple standard.

B — wide_house_6x5
left 52, top 80, width 96, height 80
Rôle : bâtiment large.

C — tall_shop_4x7
left 68, top 48, width 64, height 112
Rôle : bâtiment plus haut / façade verticale.

D — small_kiosk_3x4
left 76, top 96, width 48, height 64
Rôle : petit volume compact.
```

Baseline commune :

```text
bottom = 160 dans chaque panel
```

## 10. Description de l’image générée

Chemin :

```text
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Dimensions :

```text
width = 800
height = 480
```

Organisation :

```text
4 colonnes de 200 px : A, B, C, D
header = 32 px
ligne 1 = shadow-only, top 32, height 224
ligne 2 = shadow + building, top 256, height 224
```

Fond et dessin :

```text
fond #D8E0C8
grille #E6ECD8
séparateurs #B5BEA7
labels vectoriels A/B/C/D
bâtiments vectoriels simplifiés, sans police ni asset externe
```

## 11. Pipeline de rendu utilisé

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

Audit du harness :

```text
23:        resolveProjectedBuildingShadowGeometry;
282:  const ShadowRuntimeRenderer().renderCollectionPass(
297:  return createProjectedBuildingShadowRuntimeInstruction(
303:  final geometry = resolveProjectedBuildingShadowGeometry(
```

## 12. Calibration ShadowV2 footprint utilisée

Preset dans le harness :

```text
id: pokemon-building-shadow-footprint-v2
name: Pokemon-like footprint building shadow V2
geometryMode: footprint
```

Tuning :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
```

Appearance :

```text
opacity: 0.24
colorHexRgb: 606060
```

Champs inertiels :

```text
direction: (0.8, 0.35)
shape: lengthRatio 0.32 / nearWidthRatio 0.90 / farWidthRatio 0.72
timeOfDayMode: fixed
```

Audit du harness :

```text
325:    id: 'pokemon-building-shadow-footprint-v2',
335:      attachYRatio: 0.82,
336:      frontWidthRatio: 1.30,
337:      rearWidthRatio: 1.42,
338:      depthRatio: 0.26,
339:      skewXRatio: 0.08,
342:      opacity: 0.24,
343:      colorHexRgb: '606060',
352:    presetId: 'pokemon-building-shadow-footprint-v2',
```

## 13. Géométries / points générés par bâtiment

A — simple_house_4x5 :

```text
frontLeft  = (58.40, 145.60)
frontRight = (141.60, 145.60)
rearRight  = (150.56, 166.40)
rearLeft   = (59.68, 166.40)
bounds     = left 58.40, top 145.60, width 92.16, height 20.80
```

B — wide_house_6x5 :

```text
frontLeft  = (37.60, 145.60)
frontRight = (162.40, 145.60)
rearRight  = (175.84, 166.40)
rearLeft   = (39.52, 166.40)
bounds     = left 37.60, top 145.60, width 138.24, height 20.80
```

C — tall_shop_4x7 :

```text
frontLeft  = (58.40, 139.84)
frontRight = (141.60, 139.84)
rearRight  = (150.56, 168.96)
rearLeft   = (59.68, 168.96)
bounds     = left 58.40, top 139.84, width 92.16, height 29.12
```

D — small_kiosk_3x4 :

```text
frontLeft  = (68.80, 148.48)
frontRight = (131.20, 148.48)
rearRight  = (137.92, 165.12)
rearLeft   = (69.76, 165.12)
bounds     = left 68.80, top 148.48, width 69.12, height 16.64
```

## 14. Assertions du test

Assertions générales :

```text
image.width == 800
image.height == 480
PNG écrit
fichier existe
fichier size > 0
background pixel == #D8E0C8
```

Assertions par bâtiment :

```text
shadow-only pixel au centroïde != background
shadow + building : building body pixel == #E9D7B9
shadow + building : visible shadow pixel below building != background
visible shadow pixel != body color
points attendus vérifiés avec tolérance 0.02
bounds attendus vérifiés avec tolérance 0.02
opacity == 0.24
colorHexRgb == 606060
```

## 15. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
```

Sortie finale :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
00:00 +0: generates projected building shadow v2 controlled multi building artifact
00:00 +1: All tests passed!
```

Résultat :

```text
PNG généré.
Test ciblé passé.
```

## 16. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff   9.2K May 22 15:23 reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Commande :

```bash
shasum -a 256 reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Sortie :

```text
85d2d3ab03c6a1db7a405d25736aee148f14f226c81d77b2be16773b8897f845  reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png: PNG image data, 800 x 480, 8-bit/color RGBA, non-interlaced
```

## 17. Résultats des tests

Commande finale :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter test tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
00:00 +0: generates projected building shadow v2 controlled multi building artifact
00:00 +1: All tests passed!
```

Notes RED/GREEN :

```text
GREEN final obtenu.
Deux ajustements locaux du harness ont été faits avant le résultat final :
1. remplacement des expected points const par une valeur locale const, car ProjectedBuildingShadowPoint n'a pas de constructeur const ;
2. déplacement de petits éléments décoratifs tall_shop/small_kiosk pour que le pixel body vérifie bien #E9D7B9.
```

## 18. Résultat analyze

Commande finale :

```bash
cd /Users/karim/Project/pokemonProject/packages/map_runtime && flutter analyze tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_controlled_multi_building_artifact_test.dart...     
No issues found! (ran in 1.3s)
```

Note :

```text
Une première passe analyze avait signalé Color.red/green/blue/alpha dépréciés.
Le harness utilise maintenant color.r/g/b/a convertis en octets.
```

## 19. Audit anti-dérive

Commande finale :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
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
asset externe
fixture durable
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
Les fichiers Lot 50 sont non suivis ; git diff --stat ne liste pas les fichiers non suivis.
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
Les fichiers Lot 50 sont non suivis ; git diff --name-status ne liste pas les fichiers non suivis.
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
?? packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
?? reports/shadows/v2/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.md
```

## 26. Analyse visuelle provisoire

Lecture visuelle de l'image générée :

```text
Les 4 colonnes sont visibles.
Les ombres sont larges, courtes, dures, grises et sobres.
Le skew reste discret vers la droite.
La maison large donne une ombre plus large sans effet de plaque sale.
Le tall_shop donne logiquement une profondeur plus visible, sans redevenir projection diagonale.
Le small_kiosk reste lisible malgré l'opacité 0.24, mais c'est le cas le plus discret.
Les panels shadow + building aident à juger l'attachement au volume.
```

Conclusion provisoire :

```text
La calibration ShadowV2 footprint tient sur ces 4 silhouettes contrôlées.
Un design gate visuel Lot 51 peut décider si le prochain pas est JSON/persistence ou un stress-case multi-background.
```

## 27. Risques / réserves

```text
L'image reste un artifact contrôlé, pas une vraie map.
Le corpus ne couvre pas les props fins, arbres, lampadaires, statues complexes ou silhouettes alpha.
Le small_kiosk est volontairement discret ; à surveiller au Lot 51.
Le tall_shop montre que depthRatio suit la hauteur ; cela semble acceptable ici mais doit être revu si des tours plus hautes apparaissent.
La persistence JSON reste hors scope et non validée par ce lot.
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
Oui. Le harness écrit uniquement shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png.
```

L’image permet-elle vraiment de comparer plusieurs proportions de bâtiments ?

```text
Oui. Elle couvre maison standard, maison large, bâtiment haut et kiosque compact.
```

La calibration V2 est-elle rendue via resolver + adapter + renderer ?

```text
Oui. Le harness appelle resolveProjectedBuildingShadowGeometry, createProjectedBuildingShadowRuntimeInstruction et ShadowRuntimeRenderer.renderCollectionPass.
```

Le panel bâtiment aide-t-il à juger l’attachement au volume ?

```text
Oui. Chaque colonne a une ligne shadow-only et une ligne shadow + building.
```

Le harness dépend-il de Selbrume ou d’un asset externe ?

```text
Non. Les bâtiments sont dessinés en dart:ui.
```

Les defaults ProjectedShadowFootprintTuning() sont-ils inchangés ?

```text
Oui. Aucun fichier map_core/lib n'a été modifié.
```

JSON/persistence est-il hors scope ?

```text
Oui. Aucun codec, JSON ou project.json n'a été modifié.
```

Le lot évite-t-il les petits props / lampadaires / objets fins ?

```text
Oui. Le corpus se limite aux bâtiments / volumes contrôlés.
```

Les skills Flutter/Dart disponibles ont-ils été utilisés ?

```text
Oui pour les skills génériques Dart disponibles. Aucun skill explicitement nommé Google Flutter/Dart n'a été détecté.
```

Les sub-agents ou passes équivalentes ont-ils été utilisés ?

```text
Oui. Audit, harness, corpus visuel, evidence/report.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Test, analyze, hash, file, ls, anti-dérive, git final, inventaire et code complet du harness sont inclus.
```

## 29. Regard critique sur le prompt

Le prompt est strict et utile.

Point à noter :

```text
La transition de nom v1 vers v2 est intentionnelle côté produit mais non persistée.
Le lot a respecté la règle : utiliser v2 uniquement dans le nouveau harness et le nouveau rapport.
```

Risque évité :

```text
Ne pas confondre artifact multi-bâtiments avec persistence réelle ou application Selbrume.
```

## 30. Prochain lot recommandé

Si l’image multi-bâtiments confirme la bonne direction :

```text
ShadowV2-51 — Projected Building Shadow V2 Multi-Building Visual Review / Persistence Decision Gate
```

Objectif :

```text
Décider si la V2 officielle est assez robuste pour passer au support JSON/persistence,
ou s'il faut encore un artifact multi-background / stress-case.
```

Si l’image multi-bâtiments révèle un problème :

```text
ShadowV2-51 — Projected Building Shadow V2 Calibration Adjustment Design Gate
```

## 31. Code complet des fichiers créés/modifiés

Fichier rapport courant :

```text
reports/shadows/v2/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.md
```

Ce rapport courant est le fichier rapport créé. Il n'est pas recopié récursivement dans lui-même.

Fichier binaire créé :

```text
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
size: 9.2K
sha256: 85d2d3ab03c6a1db7a405d25736aee148f14f226c81d77b2be16773b8897f845
file: PNG image data, 800 x 480, 8-bit/color RGBA, non-interlaced
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

const _artifactWidth = 800;
const _artifactHeight = 480;
const _columnWidth = 200;
const _headerHeight = 32;
const _rowHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = 256;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png';

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

const _buildingCases = [
  _BuildingCase(
    id: 'simple_house_4x5',
    label: 'A',
    left: 68,
    top: 80,
    width: 64,
    height: 80,
    expectedPoints: [
      _ExpectedPoint(x: 58.40, y: 145.60),
      _ExpectedPoint(x: 141.60, y: 145.60),
      _ExpectedPoint(x: 150.56, y: 166.40),
      _ExpectedPoint(x: 59.68, y: 166.40),
    ],
    expectedLeft: 58.40,
    expectedTop: 145.60,
    expectedWidth: 92.16,
    expectedHeight: 20.80,
  ),
  _BuildingCase(
    id: 'wide_house_6x5',
    label: 'B',
    left: 52,
    top: 80,
    width: 96,
    height: 80,
    expectedPoints: [
      _ExpectedPoint(x: 37.60, y: 145.60),
      _ExpectedPoint(x: 162.40, y: 145.60),
      _ExpectedPoint(x: 175.84, y: 166.40),
      _ExpectedPoint(x: 39.52, y: 166.40),
    ],
    expectedLeft: 37.60,
    expectedTop: 145.60,
    expectedWidth: 138.24,
    expectedHeight: 20.80,
  ),
  _BuildingCase(
    id: 'tall_shop_4x7',
    label: 'C',
    left: 68,
    top: 48,
    width: 64,
    height: 112,
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
  _BuildingCase(
    id: 'small_kiosk_3x4',
    label: 'D',
    left: 76,
    top: 96,
    width: 48,
    height: 64,
    expectedPoints: [
      _ExpectedPoint(x: 68.80, y: 148.48),
      _ExpectedPoint(x: 131.20, y: 148.48),
      _ExpectedPoint(x: 137.92, y: 165.12),
      _ExpectedPoint(x: 69.76, y: 165.12),
    ],
    expectedLeft: 68.80,
    expectedTop: 148.48,
    expectedWidth: 69.12,
    expectedHeight: 16.64,
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow v2 controlled multi building artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _buildingCases.length; index += 1) {
      final building = _buildingCases[index];
      final columnLeft = index * _columnWidth;
      final geometry = _geometryForCase(building);
      final instruction = _instructionForCase(building);

      expect(geometry.opacity, 0.24);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      for (var pointIndex = 0; pointIndex < building.expectedPoints.length; pointIndex += 1) {
        _expectPointClose(
          geometry.points[pointIndex],
          x: building.expectedPoints[pointIndex].x,
          y: building.expectedPoints[pointIndex].y,
        );
      }
      _expectBoundsClose(instruction, building);

      final centroid = _centroid(geometry);
      final shadowOnlyPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowOnlyPixel,
        isNot(backgroundPixel),
        reason: '${building.id} shadow-only should render',
      );

      final buildingBodyPixel = await _pixelAt(
        image,
        columnLeft + (building.left + building.width / 2).round(),
        _buildingRowTop +
            (building.top + math.min(40, building.height / 2)).round(),
      );
      expect(
        buildingBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${building.id} body should render above shadow',
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
        reason: '${building.id} visible shadow should render below building',
      );
      expect(
        visibleShadowPixel,
        isNot(_rgba(_buildingBodyColor)),
        reason: '${building.id} visible shadow should not be covered by body',
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

  for (var index = 0; index < _buildingCases.length; index += 1) {
    final building = _buildingCases[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawLabel(canvas, building.label, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, building, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, building, columnLeft, _buildingRowTop.toDouble());
    _drawControlledBuilding(canvas, building, columnLeft, _buildingRowTop.toDouble());
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
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionForCase(building),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionForCase(_BuildingCase building) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionForCase(building)],
  );
}

ShadowRuntimeRenderInstruction _instructionForCase(_BuildingCase building) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryForCase(building),
  );
}

ProjectedBuildingShadowGeometry _geometryForCase(_BuildingCase building) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _shadowConfig(),
    preset: _shadowPreset(),
    metrics: _metricsForCase(building),
  );
  if (geometry == null) {
    throw StateError('${building.id} did not produce geometry');
  }
  return geometry;
}

StaticShadowVisualMetrics _metricsForCase(_BuildingCase building) {
  return StaticShadowVisualMetrics(
    left: building.left,
    top: building.top,
    visualWidth: building.width,
    visualHeight: building.height,
  );
}

ProjectBuildingShadowPreset _shadowPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v2',
    name: 'Pokemon-like footprint building shadow V2',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(
      attachYRatio: 0.82,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.42,
      depthRatio: 0.26,
      skewXRatio: 0.08,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.24,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _shadowConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-footprint-v2',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _drawControlledBuilding(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  switch (building.id) {
    case 'simple_house_4x5':
      _drawSimpleHouse(canvas, building, columnLeft, rowTop);
    case 'wide_house_6x5':
      _drawWideHouse(canvas, building, columnLeft, rowTop);
    case 'tall_shop_4x7':
      _drawTallShop(canvas, building, columnLeft, rowTop);
    case 'small_kiosk_3x4':
      _drawSmallKiosk(canvas, building, columnLeft, rowTop);
  }
}

void _drawSimpleHouse(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 22, width, height - 22), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 22, width, height - 22), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 6, top + 24)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 6, top + 24)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 6, top + 24)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 6, top + 24)
      ..close(),
    outline,
  );
  _drawDoor(canvas, left + width / 2 - 7, top + height - 28, 14, 28);
  _drawWindow(canvas, left + 10, top + 42, 14, 14);
  _drawWindow(canvas, left + width - 24, top + 42, 14, 14);
}

void _drawWideHouse(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 20, width, height - 20), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 20, width, height - 20), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 8, top + 22)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 8, top + 22)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 8, top + 22)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 8, top + 22)
      ..close(),
    outline,
  );
  _drawDoor(canvas, left + width / 2 - 8, top + height - 28, 16, 28);
  _drawWindow(canvas, left + 10, top + 40, 14, 14);
  _drawWindow(canvas, left + 30, top + 40, 14, 14);
  _drawWindow(canvas, left + width - 44, top + 40, 14, 14);
  _drawWindow(canvas, left + width - 24, top + 40, 14, 14);
}

void _drawTallShop(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
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

void _drawSmallKiosk(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + building.left;
  final top = rowTop + building.top;
  final width = building.width;
  final height = building.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_buildingBodyColor);
  final roof = _fillPaint(_buildingRoofColor);
  final sign = _fillPaint(_buildingSignColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 5, top + 20)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 5, top + 20)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 5, top + 20)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 5, top + 20)
      ..close(),
    outline,
  );
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 20, width - 16, 8), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 20, width - 16, 8), outline);
  _drawDoor(canvas, left + width - 18, top + height - 24, 12, 24);
  _drawWindow(canvas, left + 8, top + 44, 14, 12);
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
  }
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 controlled multi-building artifact as PNG');
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
    y: math.max(161, rearY.round() - 3).toDouble(),
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
  _BuildingCase building,
) {
  expect(instruction.worldLeft, closeTo(building.expectedLeft, 0.02));
  expect(instruction.worldTop, closeTo(building.expectedTop, 0.02));
  expect(instruction.width, closeTo(building.expectedWidth, 0.02));
  expect(instruction.height, closeTo(building.expectedHeight, 0.02));
}

final class _BuildingCase {
  const _BuildingCase({
    required this.id,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.expectedPoints,
    required this.expectedLeft,
    required this.expectedTop,
    required this.expectedWidth,
    required this.expectedHeight,
  });

  final String id;
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
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
- [x] Image 800x480 ou taille documentée
- [x] Colonne A simple_house_4x5 présente
- [x] Colonne B wide_house_6x5 présente
- [x] Colonne C tall_shop_4x7 présente
- [x] Colonne D small_kiosk_3x4 présente
- [x] Shadow-only présent
- [x] Shadow + building présent
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] pokemon-building-shadow-footprint-v2 utilisé dans le harness
- [x] attachYRatio 0.82 utilisé
- [x] frontWidthRatio 1.30 utilisé
- [x] rearWidthRatio 1.42 utilisé
- [x] depthRatio 0.26 utilisé
- [x] skewXRatio 0.08 utilisé
- [x] opacity 0.24 utilisée
- [x] colorHexRgb 606060 utilisé
- [x] Points des 4 bâtiments vérifiés
- [x] Bounds des 4 bâtiments vérifiés
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
