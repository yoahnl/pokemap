# ShadowV2-54 — Projected Building Shadow V2 Adaptive Depth Candidate Matrix Artifact

## 1. Résumé exécutif

ShadowV2-54 a créé un artifact visuel contrôlé, manuel et non-baseline pour comparer Standard V2 fixe, Fixed C, Fixed C+, Adaptive C, Adaptive C+ et Reference-like.

Résultat :

```text
Harness créé : packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
PNG créé : reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
Rapport créé : reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
```

Le PNG fait `1200 x 928` et contient les 6 colonnes A-F et les 4 lignes prévues. Les candidats adaptive restent entièrement locaux au harness. Aucun fichier de production, aucun test existant, aucun map_core, aucun renderer/painter, aucun JSON/codec, aucun Selbrume et aucune baseline/golden n'ont été modifiés ou créés.

## 2. Objectif du lot

Objectif exact :

```text
Générer un artifact PNG contrôlé comparant :
- la calibration Standard V2 fixe ;
- le candidat C tall deeper softer ;
- une variante C+ plus longue ;
- une formule Adaptive C ;
- une formule Adaptive C+ ;
- une variante E reference-like ;
afin de vérifier visuellement si une profondeur adaptative bornée est préférable à un profil tall fixe.
```

Le lot ne choisit pas définitivement de stratégie. Il produit une preuve visuelle pour alimenter le prochain design gate.

## 3. Rappel ShadowV2-53

ShadowV2-53 a tranché :

```text
depth = metrics.visualHeight * footprint.depthRatio
```

Donc la profondeur actuelle est déjà proportionnelle à `visualHeight`. Le problème potentiel est que `depthRatio` reste constant et peut sous-réagir sur un bâtiment haut.

Décision ShadowV2-53 :

```text
Ne pas choisir directement C.
Ne pas créer de profil tall officiel.
Ne pas passer à JSON/persistence.
Créer un artifact comparant Standard / C / C+ / Adaptive C / Adaptive C+ / Reference-like.
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Interprétation :

```text
Aucun fichier préexistant non suivi au début du Lot 54.
Aucune modification suivie préexistante.
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills consultés :

```text
superpowers:using-superpowers
superpowers:test-driven-development
superpowers:verification-before-completion
karpathy-guidelines
dart-add-unit-test
dart-run-static-analysis
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté.
Les pratiques Flutter/Dart ont été vérifiées avec les skills génériques disponibles,
les patterns locaux des harnesses ShadowV2, flutter_test, dart:ui PictureRecorder/toImage/ImageByteFormat,
et flutter analyze ciblé.
```

Sub-agents utilisés :

```text
Audit sub-agent : utilisé.
Flutter/Dart visual harness sub-agent : utilisé.
Adaptive visual comparison sub-agent : utilisé.
Test/analyze/evidence sub-agent : utilisé.
```

Synthèse :

```text
Audit : worktree initial propre, seulement les trois fichiers Lot 54 autorisés.
Harness : reprendre Lot52 pour la matrice et Lot50 pour les bâtiments de contrôle.
Visual comparison : fixed vs adaptive est pertinent ; low guards doivent prouver l'égalité adaptive/standard.
Evidence : test ciblé, analyze ciblé, hash PNG, file, ls, anti-dérive et git final requis.
```

## 6. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Lignes AGENTS pertinentes :

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
Le design gate ShadowV2-53 a autorisé ShadowV2-54 comme artifact contrôlé.
Le lot peut créer uniquement un harness manuel, un PNG et un rapport.
```

## 7. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
```

Fichiers modifiés :

```text
Aucun fichier préexistant modifié.
```

Fichiers supprimés :

```text
Aucun.
```

Fichiers de production modifiés :

```text
Aucun.
```

Fichiers de test existants modifiés :

```text
Aucun.
```

## 8. Stratégie d’artifact adaptive depth

Stratégie :

```text
6 colonnes de 200 px.
4 lignes de 224 px après un header de 32 px.
Ligne 1 : tall_shop_4x7 shadow-only.
Ligne 2 : tall_shop_4x7 shadow + building.
Ligne 3 : simple_house_4x5 shadow + building.
Ligne 4 : small_kiosk_3x4 shadow + building.
```

Ce que l'image prouve :

```text
Les colonnes B/C sont des profils fixes tall.
Les colonnes D/E sont les versions adaptive locales.
Sur tall_shop_4x7, D égale B et E égale C.
Sur les low guards, D/E reviennent à Standard.
```

## 9. Building cases contrôlés

Building cases :

```text
tall_shop_4x7:
  left = 68
  top = 48
  visualWidth = 64
  visualHeight = 112

simple_house_4x5:
  left = 68
  top = 80
  visualWidth = 64
  visualHeight = 80

small_kiosk_3x4:
  left = 76
  top = 96
  visualWidth = 48
  visualHeight = 64
```

Les bâtiments restent constants entre colonnes. Seule la formule d'ombre varie.

## 10. Candidats générés

Colonnes :

```text
A = candidate-a-standard-v2-fixed
B = candidate-b-fixed-c-tall-deeper-softer
C = candidate-c-fixed-c-plus
D = candidate-d-adaptive-c
E = candidate-e-adaptive-c-plus
F = candidate-f-fixed-e-reference-like
```

Paramètres tall principaux :

```text
A Standard:
  attachYRatio 0.82, frontWidthRatio 1.30, rearWidthRatio 1.42, depthRatio 0.26, skewXRatio 0.08, opacity 0.24

B Fixed C:
  attachYRatio 0.80, frontWidthRatio 1.30, rearWidthRatio 1.45, depthRatio 0.38, skewXRatio 0.08, opacity 0.23

C Fixed C+:
  attachYRatio 0.80, frontWidthRatio 1.30, rearWidthRatio 1.47, depthRatio 0.42, skewXRatio 0.08, opacity 0.22

D Adaptive C:
  base standard -> target Fixed C

E Adaptive C+:
  base standard -> target Fixed C+

F Reference-like:
  attachYRatio 0.78, frontWidthRatio 1.34, rearWidthRatio 1.50, depthRatio 0.40, skewXRatio 0.10, opacity 0.23
```

## 11. Formule adaptive locale au harness

Formule locale :

```text
heightGate = clamp((visualHeight - 80) / 32, 0, 1)
ratioGate = clamp((visualHeight / visualWidth - 1.25) / 0.50, 0, 1)
adaptiveT = heightGate * ratioGate

effectiveDepthRatio = lerp(depthBase, depthTarget, adaptiveT)
effectiveAttachYRatio = lerp(attachBase, attachTarget, adaptiveT)
effectiveRearWidthRatio = lerp(rearWidthBase, rearWidthTarget, adaptiveT)
effectiveOpacity = lerp(opacityBase, opacityTarget, adaptiveT)

frontWidthRatio = 1.30
skewXRatio = 0.08
colorHexRgb = 606060
```

Résultats attendus :

```text
tall_shop_4x7:
  visualHeight = 112
  visualWidth = 64
  heightGate = 1
  ratioGate = 1
  adaptiveT = 1
  Adaptive C = Fixed C
  Adaptive C+ = Fixed C+

simple_house_4x5:
  heightGate = 0
  adaptiveT = 0
  Adaptive C / C+ = Standard

small_kiosk_3x4:
  heightGate = 0
  adaptiveT = 0
  Adaptive C / C+ = Standard
```

Cette formule n'existe que dans le harness. Elle n'est pas ajoutée à map_core, à un modèle persistant ou à un codec.

## 12. Description de l’image générée

Image :

```text
Chemin : reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
Dimensions : 1200 x 928
Colonnes : A/B/C/D/E/F
Lignes : tall shadow-only, tall + building, simple house guard, small kiosk guard
Fond : #D8E0C8
Grille : #E6ECD8
Séparateurs : #B5BEA7
Labels : vectoriels simples
```

## 13. Pipeline de rendu utilisé

Pipeline utilisé pour chaque cellule :

```text
ProjectBuildingShadowPreset
ProjectElementProjectedBuildingShadowConfig
StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

Audit source :

```text
23:        resolveProjectedBuildingShadowGeometry;
456:  const ShadowRuntimeRenderer().renderCollectionPass(
477:  return createProjectedBuildingShadowRuntimeInstruction(
486:  final geometry = resolveProjectedBuildingShadowGeometry(
551:  final heightGate = _clamp01((building.height - 80) / 32);
552:  final ratioGate = _clamp01((building.height / building.width - 1.25) / 0.50);
553:  final adaptiveT = heightGate * ratioGate;
```

## 14. Géométries / points générés — tall_shop_4x7

Metrics :

```text
left = 68
top = 48
visualWidth = 64
visualHeight = 112
```

A — Standard :

```text
frontLeft  = (58.40, 139.84)
frontRight = (141.60, 139.84)
rearRight  = (150.56, 168.96)
rearLeft   = (59.68, 168.96)
bounds: left=58.40 top=139.84 width=92.16 height=29.12
opacity=0.24 colorHexRgb=606060
```

B — Fixed C :

```text
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (151.52, 180.16)
rearLeft   = (58.72, 180.16)
bounds: left=58.40 top=137.60 width=93.12 height=42.56
opacity=0.23 colorHexRgb=606060
```

C — Fixed C+ :

```text
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (152.16, 184.64)
rearLeft   = (58.08, 184.64)
bounds: left=58.08 top=137.60 width=94.08 height=47.04
opacity=0.22 colorHexRgb=606060
```

D — Adaptive C :

```text
Identique à Fixed C sur tall_shop_4x7.
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (151.52, 180.16)
rearLeft   = (58.72, 180.16)
bounds: left=58.40 top=137.60 width=93.12 height=42.56
opacity=0.23 colorHexRgb=606060
```

E — Adaptive C+ :

```text
Identique à Fixed C+ sur tall_shop_4x7.
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (152.16, 184.64)
rearLeft   = (58.08, 184.64)
bounds: left=58.08 top=137.60 width=94.08 height=47.04
opacity=0.22 colorHexRgb=606060
```

F — Reference-like :

```text
frontLeft  = (57.12, 135.36)
frontRight = (142.88, 135.36)
rearRight  = (154.40, 180.16)
rearLeft   = (58.40, 180.16)
bounds: left=57.12 top=135.36 width=97.28 height=44.80
opacity=0.23 colorHexRgb=606060
```

## 15. Géométries / points générés — low guards

simple_house_4x5 standard/adaptive attendu pour A, D et E :

```text
frontLeft  = (58.40, 145.60)
frontRight = (141.60, 145.60)
rearRight  = (150.56, 166.40)
rearLeft   = (59.68, 166.40)
bounds: left=58.40 top=145.60 width=92.16 height=20.80
opacity=0.24 colorHexRgb=606060
```

small_kiosk_3x4 standard/adaptive attendu pour A, D et E :

```text
frontLeft  = (68.80, 148.48)
frontRight = (131.20, 148.48)
rearRight  = (137.92, 165.12)
rearLeft   = (69.76, 165.12)
bounds: left=68.80 top=148.48 width=69.12 height=16.64
opacity=0.24 colorHexRgb=606060
```

Preuve :

```text
Le test vérifie A/D/E sur simple_house_4x5 et small_kiosk_3x4 contre ces points/bounds standard.
```

## 16. Assertions du test

Assertions principales :

```text
image.width == 1200
image.height == 928
PNG écrit
fichier existe
fichier size > 0
background pixel == #D8E0C8
tall shadow-only centroid != background
tall building body pixel == #E9D7B9
tall visible shadow pixel != background
simple house body pixel == #E9D7B9
kiosk body pixel == #E9D7B9
tall points/bounds/opacité/couleur vérifiés pour A-F
simple/kiosk A/D/E points/bounds identiques à Standard
```

RED observé avant création :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
00:00 +0 -1: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart [E]
  Failed to load "/Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart": Does not exist.
00:00 +0 -1: Some tests failed.
```

## 17. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
00:00 +0: generates projected building shadow v2 adaptive depth candidate matrix artifact
00:00 +1: All tests passed!
```

## 18. Hash / taille / chemin du PNG

Commande `ls -lh` :

```text
-rw-r--r--  1 karim  staff    20K May 22 18:13 reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
```

Commande `shasum -a 256` :

```text
cff1a297270ab5b83f29ea15e1afbbf9f55481115bb71ff12151620a81261f58  reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
```

Commande `file` :

```text
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png: PNG image data, 1200 x 928, 8-bit/color RGBA, non-interlaced
```

## 19. Résultats des tests

Test ciblé final :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
00:00 +0: generates projected building shadow v2 adaptive depth candidate matrix artifact
00:00 +1: All tests passed!
```

## 20. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart...

No issues found! (ran in 1.3s)
```

## 21. Audit anti-dérive

Commande :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
```

Sortie :

```text
```

Interprétation :

```text
Aucun hit dans le harness Lot 54.
```

## 22. Ce qui n’a volontairement pas été modifié

Non modifié :

```text
packages/map_core/**
packages/map_runtime/lib/**
packages/map_runtime/test/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
reports/shadows/baselines/**
project.json
```

## 23. Ce qui n’a volontairement pas été créé

Non créé :

```text
baseline
golden
matchesGoldenFile
nouveau renderer
nouveau painter
nouveau modèle persistant
nouveau codec JSON
formule adaptive persistée
profil tall officiel
fixture Selbrume
shader
blur
auto-shadow policy
migration
```

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
```

Interprétation :

```text
Aucune modification suivie. Les fichiers Lot 54 sont non suivis.
```

## 25. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
```

## 26. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
```

Interprétation :

```text
Propre.
```

## 27. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
?? reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
```

## 28. Analyse visuelle provisoire

Lecture de l'image :

```text
A Standard est le plus court sur le bâtiment haut.
B Fixed C et D Adaptive C sont visuellement identiques sur tall_shop_4x7, comme attendu.
C Fixed C+ et E Adaptive C+ sont visuellement identiques sur tall_shop_4x7, comme attendu, et plus longs que C.
F Reference-like est plus large et plus avancé vers l'attache haute, avec risque plaque.
Sur simple_house_4x5 et small_kiosk_3x4, D/E reviennent visuellement à Standard.
```

Lecture produit :

```text
L'adaptive depth est prometteur en tant que stratégie bornée :
elle peut atteindre C/C+ pour tall_shop_4x7 sans grossir les bâtiments bas de contrôle.
Mais l'image prouve surtout la cohérence endpoint/guard, pas encore la supériorité finale de l'adaptive.
```

## 29. Risques / réserves

Risques :

```text
Adaptive C/C+ égalent les profils fixes au point cible tall ; l'image ne prouve pas seule qu'adaptive est meilleure que fixed.
Les low guards A/D/E couvrent simple_house et small_kiosk, mais pas toutes les silhouettes possibles.
wide_house_6x5 n'est pas inclus dans cette image malgré la suggestion du sub-agent ; le prompt strict ne l'autorisait pas dans le corpus.
F Reference-like peut biaiser visuellement vers des ombres trop larges.
Les métriques contrôlées ne couvrent pas les sprites réels avec padding transparent.
```

## 30. Auto-critique

Questions obligatoires :

```text
Le lot a-t-il créé une baseline par accident ?
Non.

Le PNG est-il bien un artifact manuel ?
Oui.

Le test écrit-il seulement l'image autorisée ?
Oui.

L'image permet-elle vraiment de comparer fixed vs adaptive ?
Oui, avec la nuance que les endpoints tall sont volontairement identiques entre B/D et C/E.

Les low guards prouvent-ils que l'adaptive ne casse pas les bâtiments bas ?
Oui pour simple_house_4x5 et small_kiosk_3x4.

Les variantes sont-elles rendues via resolver + adapter + renderer ?
Oui.

Le harness dépend-il de Selbrume ou d'un asset externe ?
Non.

Les defaults ProjectedShadowFootprintTuning() sont-ils inchangés ?
Oui, aucun fichier map_core modifié.

JSON/persistence est-il hors scope ?
Oui.

Le lot évite-t-il les petits props / lampadaires / objets fins ?
Oui.

Les skills Flutter/Dart disponibles ont-ils été utilisés ?
Oui, via skills génériques Dart/Flutter disponibles ; aucun Google-nommé détecté.

Les sub-agents ou passes équivalentes ont-ils été utilisés ?
Oui.

Le rapport contient-il toutes les preuves ?
Oui.
```

Checklist finale :

```text
- [x] Harness manuel créé sous packages/map_runtime/tool/shadow
- [x] PNG artifact créé
- [x] PNG dans reports/shadows/screenshots
- [x] Aucun fichier baseline créé
- [x] Aucun matchesGoldenFile
- [x] Aucun Selbrume modifié ou lu pour générer l'image
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] Image 1200x928 ou taille documentée
- [x] Colonne A Standard présente
- [x] Colonne B Fixed C présente
- [x] Colonne C Fixed C+ présente
- [x] Colonne D Adaptive C présente
- [x] Colonne E Adaptive C+ présente
- [x] Colonne F Reference-like présente
- [x] Ligne tall shadow-only présente
- [x] Ligne tall shadow + building présente
- [x] Ligne simple house guard présente
- [x] Ligne small kiosk guard présente
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] ProjectedShadowFootprintTuning explicite utilisé
- [x] Aucun ProjectedShadowFootprintTuning() default utilisé pour les variantes
- [x] Points tall des 6 candidats vérifiés
- [x] Bounds tall des 6 candidats vérifiés
- [x] Adaptive C low guards vérifiés
- [x] Adaptive C+ low guards vérifiés
- [x] Opacity vérifiée
- [x] colorHexRgb 606060 vérifié
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
```

## 31. Regard critique sur le prompt

Le prompt est bien borné : il force une preuve visuelle sans transformer l'adaptive depth en modèle persistant. Le point le plus utile est l'exigence des low guards, car elle empêche de valider une formule tall qui grossirait silencieusement les bâtiments bas.

Réserve :

```text
Le prompt exclut wide_house_6x5 du corpus Lot 54.
Cela garde l'image lisible, mais un lot ultérieur pourrait tester width-only / wide guard si l'adaptive devient candidate officielle.
```

## 32. Prochain lot recommandé

Si l'adaptive C+ ressort visuellement meilleur :

```text
ShadowV2-55 — Projected Building Shadow V2 Adaptive Depth Visual Review / Selection Design Gate
```

Objectif :

```text
Décider si une formule adaptiveHeightDepth bornée doit devenir la stratégie recommandée pour bâtiments hauts.
```

Si Fixed C ou Fixed C+ ressort clairement :

```text
ShadowV2-55 — Projected Building Shadow V2 Tall Fixed Variant Selection Design Gate
```

Si Standard V2 reste suffisant :

```text
ShadowV2-55 — Projected Building Shadow V2 Persistence Design Gate
```

## 33. Code complet des fichiers créés/modifiés

### packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart

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

const _artifactWidth = 1200;
const _artifactHeight = 928;
const _columnWidth = 200;
const _headerHeight = 32;
const _rowHeight = 224;
const _row0Top = _headerHeight;
const _row1Top = 256;
const _row2Top = 480;
const _row3Top = 704;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png';

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

const _candidates = [
  _ShadowCandidate.fixed(
    id: 'candidate-a-standard-v2-fixed',
    label: 'A',
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
    opacity: 0.24,
    tallExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 139.84),
        _ExpectedPoint(x: 141.60, y: 139.84),
        _ExpectedPoint(x: 150.56, y: 168.96),
        _ExpectedPoint(x: 59.68, y: 168.96),
      ],
      left: 58.40,
      top: 139.84,
      width: 92.16,
      height: 29.12,
    ),
  ),
  _ShadowCandidate.fixed(
    id: 'candidate-b-fixed-c-tall-deeper-softer',
    label: 'B',
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.45,
    depthRatio: 0.38,
    skewXRatio: 0.08,
    opacity: 0.23,
    tallExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 137.60),
        _ExpectedPoint(x: 141.60, y: 137.60),
        _ExpectedPoint(x: 151.52, y: 180.16),
        _ExpectedPoint(x: 58.72, y: 180.16),
      ],
      left: 58.40,
      top: 137.60,
      width: 93.12,
      height: 42.56,
    ),
  ),
  _ShadowCandidate.fixed(
    id: 'candidate-c-fixed-c-plus',
    label: 'C',
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
    opacity: 0.22,
    tallExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 137.60),
        _ExpectedPoint(x: 141.60, y: 137.60),
        _ExpectedPoint(x: 152.16, y: 184.64),
        _ExpectedPoint(x: 58.08, y: 184.64),
      ],
      left: 58.08,
      top: 137.60,
      width: 94.08,
      height: 47.04,
    ),
  ),
  _ShadowCandidate.adaptive(
    id: 'candidate-d-adaptive-c',
    label: 'D',
    attachYRatio: 0.82,
    targetAttachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    targetRearWidthRatio: 1.45,
    depthRatio: 0.26,
    targetDepthRatio: 0.38,
    skewXRatio: 0.08,
    opacity: 0.24,
    targetOpacity: 0.23,
    tallExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 137.60),
        _ExpectedPoint(x: 141.60, y: 137.60),
        _ExpectedPoint(x: 151.52, y: 180.16),
        _ExpectedPoint(x: 58.72, y: 180.16),
      ],
      left: 58.40,
      top: 137.60,
      width: 93.12,
      height: 42.56,
    ),
  ),
  _ShadowCandidate.adaptive(
    id: 'candidate-e-adaptive-c-plus',
    label: 'E',
    attachYRatio: 0.82,
    targetAttachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    targetRearWidthRatio: 1.47,
    depthRatio: 0.26,
    targetDepthRatio: 0.42,
    skewXRatio: 0.08,
    opacity: 0.24,
    targetOpacity: 0.22,
    tallExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 137.60),
        _ExpectedPoint(x: 141.60, y: 137.60),
        _ExpectedPoint(x: 152.16, y: 184.64),
        _ExpectedPoint(x: 58.08, y: 184.64),
      ],
      left: 58.08,
      top: 137.60,
      width: 94.08,
      height: 47.04,
    ),
  ),
  _ShadowCandidate.fixed(
    id: 'candidate-f-fixed-e-reference-like',
    label: 'F',
    attachYRatio: 0.78,
    frontWidthRatio: 1.34,
    rearWidthRatio: 1.50,
    depthRatio: 0.40,
    skewXRatio: 0.10,
    opacity: 0.23,
    tallExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 57.12, y: 135.36),
        _ExpectedPoint(x: 142.88, y: 135.36),
        _ExpectedPoint(x: 154.40, y: 180.16),
        _ExpectedPoint(x: 58.40, y: 180.16),
      ],
      left: 57.12,
      top: 135.36,
      width: 97.28,
      height: 44.80,
    ),
  ),
];

const _buildingCases = [
  _BuildingCase(
    id: 'tall_shop_4x7',
    left: 68,
    top: 48,
    width: 64,
    height: 112,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 139.84),
        _ExpectedPoint(x: 141.60, y: 139.84),
        _ExpectedPoint(x: 150.56, y: 168.96),
        _ExpectedPoint(x: 59.68, y: 168.96),
      ],
      left: 58.40,
      top: 139.84,
      width: 92.16,
      height: 29.12,
    ),
  ),
  _BuildingCase(
    id: 'simple_house_4x5',
    left: 68,
    top: 80,
    width: 64,
    height: 80,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 145.60),
        _ExpectedPoint(x: 141.60, y: 145.60),
        _ExpectedPoint(x: 150.56, y: 166.40),
        _ExpectedPoint(x: 59.68, y: 166.40),
      ],
      left: 58.40,
      top: 145.60,
      width: 92.16,
      height: 20.80,
    ),
  ),
  _BuildingCase(
    id: 'small_kiosk_3x4',
    left: 76,
    top: 96,
    width: 48,
    height: 64,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 68.80, y: 148.48),
        _ExpectedPoint(x: 131.20, y: 148.48),
        _ExpectedPoint(x: 137.92, y: 165.12),
        _ExpectedPoint(x: 69.76, y: 165.12),
      ],
      left: 68.80,
      top: 148.48,
      width: 69.12,
      height: 16.64,
    ),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow v2 adaptive depth candidate matrix artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _candidates.length; index += 1) {
      final candidate = _candidates[index];
      final columnLeft = index * _columnWidth;
      final tall = _buildingCases[0];
      final tallGeometry = _geometryForCandidateAndBuilding(candidate, tall);
      final tallInstruction = _instructionForCandidateAndBuilding(candidate, tall);
      final tallValues = _effectiveCandidateForBuilding(candidate, tall);

      expect(tallGeometry.opacity, closeTo(tallValues.opacity, 0.000001));
      expect(tallGeometry.colorHexRgb, '606060');
      _expectGeometryClose(tallGeometry, candidate.tallExpected);
      _expectBoundsClose(tallInstruction, candidate.tallExpected);

      final centroid = _centroid(tallGeometry);
      final shadowOnlyPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _row0Top + centroid.y.round(),
      );
      expect(
        shadowOnlyPixel,
        isNot(backgroundPixel),
        reason: '${candidate.id} tall shadow-only should render',
      );

      final tallBodyPixel = await _buildingBodyPixel(
        image,
        columnLeft: columnLeft,
        rowTop: _row1Top,
        building: tall,
      );
      expect(
        tallBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.id} tall body should render above shadow',
      );

      final visibleShadowPoint = _visibleShadowPoint(tallGeometry);
      final visibleShadowPixel = await _pixelAt(
        image,
        columnLeft + visibleShadowPoint.x.round(),
        _row1Top + visibleShadowPoint.y.round(),
      );
      expect(
        visibleShadowPixel,
        isNot(backgroundPixel),
        reason: '${candidate.id} visible tall shadow should render',
      );
      expect(
        visibleShadowPixel,
        isNot(_rgba(_buildingBodyColor)),
        reason: '${candidate.id} visible tall shadow should not be covered',
      );

      final simpleBodyPixel = await _buildingBodyPixel(
        image,
        columnLeft: columnLeft,
        rowTop: _row2Top,
        building: _buildingCases[1],
      );
      expect(
        simpleBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.id} simple house body should render',
      );

      final kioskBodyPixel = await _buildingBodyPixel(
        image,
        columnLeft: columnLeft,
        rowTop: _row3Top,
        building: _buildingCases[2],
      );
      expect(
        kioskBodyPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.id} kiosk body should render',
      );
    }

    for (final candidate in [_candidates[0], _candidates[3], _candidates[4]]) {
      for (final building in [_buildingCases[1], _buildingCases[2]]) {
        final geometry = _geometryForCandidateAndBuilding(candidate, building);
        final instruction = _instructionForCandidateAndBuilding(candidate, building);
        final values = _effectiveCandidateForBuilding(candidate, building);
        expect(geometry.opacity, closeTo(0.24, 0.000001));
        expect(values.opacity, closeTo(0.24, 0.000001));
        expect(geometry.colorHexRgb, '606060');
        _expectGeometryClose(geometry, building.standardExpected);
        _expectBoundsClose(instruction, building.standardExpected);
      }
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
    _drawMatrixCell(canvas, candidate, _buildingCases[0], columnLeft, _row0Top.toDouble(), false);
    _drawMatrixCell(canvas, candidate, _buildingCases[0], columnLeft, _row1Top.toDouble(), true);
    _drawMatrixCell(canvas, candidate, _buildingCases[1], columnLeft, _row2Top.toDouble(), true);
    _drawMatrixCell(canvas, candidate, _buildingCases[2], columnLeft, _row3Top.toDouble(), true);
  }

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawMatrixCell(
  ui.Canvas canvas,
  _ShadowCandidate candidate,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
  bool drawBuilding,
) {
  _drawCellBackground(canvas, columnLeft, rowTop);
  _drawShadow(canvas, candidate, building, columnLeft, rowTop);
  if (drawBuilding) {
    _drawBuilding(canvas, building, columnLeft, rowTop);
  }
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
  for (final y in [_headerHeight, _row1Top, _row2Top, _row3Top]) {
    canvas.drawLine(
      ui.Offset(0, y - 0.5),
      ui.Offset(_artifactWidth + 0.0, y - 0.5),
      paint,
    );
  }
}

void _drawShadow(
  ui.Canvas canvas,
  _ShadowCandidate candidate,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionForCandidateAndBuilding(candidate, building),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionForCandidateAndBuilding(
  _ShadowCandidate candidate,
  _BuildingCase building,
) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionForCandidateAndBuilding(candidate, building)],
  );
}

ShadowRuntimeRenderInstruction _instructionForCandidateAndBuilding(
  _ShadowCandidate candidate,
  _BuildingCase building,
) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryForCandidateAndBuilding(candidate, building),
  );
}

ProjectedBuildingShadowGeometry _geometryForCandidateAndBuilding(
  _ShadowCandidate candidate,
  _BuildingCase building,
) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _shadowConfigForCandidate(candidate),
    preset: _shadowPresetForCandidate(candidate, building),
    metrics: _metricsForBuilding(building),
  );
  if (geometry == null) {
    throw StateError('${candidate.id}/${building.id} did not produce geometry');
  }
  return geometry;
}

StaticShadowVisualMetrics _metricsForBuilding(_BuildingCase building) {
  return StaticShadowVisualMetrics(
    left: building.left,
    top: building.top,
    visualWidth: building.width,
    visualHeight: building.height,
  );
}

ProjectBuildingShadowPreset _shadowPresetForCandidate(
  _ShadowCandidate candidate,
  _BuildingCase building,
) {
  final values = _effectiveCandidateForBuilding(candidate, building);
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
      attachYRatio: values.attachYRatio,
      frontWidthRatio: values.frontWidthRatio,
      rearWidthRatio: values.rearWidthRatio,
      depthRatio: values.depthRatio,
      skewXRatio: values.skewXRatio,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: values.opacity,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

_EffectiveShadowValues _effectiveCandidateForBuilding(
  _ShadowCandidate candidate,
  _BuildingCase building,
) {
  if (!candidate.isAdaptive) {
    return _EffectiveShadowValues(
      attachYRatio: candidate.attachYRatio,
      frontWidthRatio: candidate.frontWidthRatio,
      rearWidthRatio: candidate.rearWidthRatio,
      depthRatio: candidate.depthRatio,
      skewXRatio: candidate.skewXRatio,
      opacity: candidate.opacity,
    );
  }

  final heightGate = _clamp01((building.height - 80) / 32);
  final ratioGate = _clamp01((building.height / building.width - 1.25) / 0.50);
  final adaptiveT = heightGate * ratioGate;
  return _EffectiveShadowValues(
    attachYRatio: _lerp(candidate.attachYRatio, candidate.targetAttachYRatio, adaptiveT),
    frontWidthRatio: candidate.frontWidthRatio,
    rearWidthRatio: _lerp(candidate.rearWidthRatio, candidate.targetRearWidthRatio, adaptiveT),
    depthRatio: _lerp(candidate.depthRatio, candidate.targetDepthRatio, adaptiveT),
    skewXRatio: candidate.skewXRatio,
    opacity: _lerp(candidate.opacity, candidate.targetOpacity, adaptiveT),
  );
}

ProjectElementProjectedBuildingShadowConfig _shadowConfigForCandidate(
  _ShadowCandidate candidate,
) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: candidate.id,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _drawBuilding(
  ui.Canvas canvas,
  _BuildingCase building,
  double columnLeft,
  double rowTop,
) {
  switch (building.id) {
    case 'tall_shop_4x7':
      _drawTallShop(canvas, building, columnLeft, rowTop);
    case 'simple_house_4x5':
      _drawSimpleHouse(canvas, building, columnLeft, rowTop);
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
    case 'E':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left, top), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right - 4, middle), paint);
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(right, bottom), paint);
    case 'F':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right, top), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right - 4, middle), paint);
  }
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 adaptive depth matrix artifact as PNG');
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

Future<_Rgba> _buildingBodyPixel(
  ui.Image image, {
  required int columnLeft,
  required int rowTop,
  required _BuildingCase building,
}) {
  return _pixelAt(
    image,
    columnLeft + (building.left + building.width / 2).round(),
    rowTop + (building.top + math.min(40, building.height / 2)).round(),
  );
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

double _clamp01(double value) => value.clamp(0, 1).toDouble();

double _lerp(double start, double end, double t) => start + (end - start) * t;

void _expectGeometryClose(
  ProjectedBuildingShadowGeometry geometry,
  _ExpectedGeometry expected,
) {
  expect(geometry.points, hasLength(4));
  for (var pointIndex = 0; pointIndex < expected.points.length; pointIndex += 1) {
    _expectPointClose(
      geometry.points[pointIndex],
      x: expected.points[pointIndex].x,
      y: expected.points[pointIndex].y,
    );
  }
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
  _ExpectedGeometry expected,
) {
  expect(instruction.worldLeft, closeTo(expected.left, 0.02));
  expect(instruction.worldTop, closeTo(expected.top, 0.02));
  expect(instruction.width, closeTo(expected.width, 0.02));
  expect(instruction.height, closeTo(expected.height, 0.02));
}

final class _ShadowCandidate {
  const _ShadowCandidate.fixed({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
    required this.tallExpected,
  })  : isAdaptive = false,
        targetAttachYRatio = attachYRatio,
        targetRearWidthRatio = rearWidthRatio,
        targetDepthRatio = depthRatio,
        targetOpacity = opacity;

  const _ShadowCandidate.adaptive({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.targetAttachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.targetRearWidthRatio,
    required this.depthRatio,
    required this.targetDepthRatio,
    required this.skewXRatio,
    required this.opacity,
    required this.targetOpacity,
    required this.tallExpected,
  }) : isAdaptive = true;

  final String id;
  final String label;
  final bool isAdaptive;
  final double attachYRatio;
  final double targetAttachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double targetRearWidthRatio;
  final double depthRatio;
  final double targetDepthRatio;
  final double skewXRatio;
  final double opacity;
  final double targetOpacity;
  final _ExpectedGeometry tallExpected;
}

final class _EffectiveShadowValues {
  const _EffectiveShadowValues({
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
  });

  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
  final double opacity;
}

final class _BuildingCase {
  const _BuildingCase({
    required this.id,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.standardExpected,
  });

  final String id;
  final double left;
  final double top;
  final double width;
  final double height;
  final _ExpectedGeometry standardExpected;
}

final class _ExpectedGeometry {
  const _ExpectedGeometry({
    required this.points,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final List<_ExpectedPoint> points;
  final double left;
  final double top;
  final double width;
  final double height;
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

Le rapport courant est le fichier rapport créé. Il n'est pas reproduit récursivement dans lui-même.
