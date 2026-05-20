# ShadowV2-36 — Projected Building Shadow Candidate Matrix Artifact V0

## 1. Résumé exécutif

ShadowV2-36 a créé un artifact visuel manuel comparatif, sans baseline CI et sans Selbrume :

- `packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart`
- `reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png`
- le présent rapport

Le harness génère une image PNG `800x480` avec 5 candidats ShadowV2, chacun en `shadow-only` puis `shadow + building`.

La génération utilise :

- `resolveProjectedBuildingShadowGeometry(...)` côté `map_core` pour calculer les points ;
- `ShadowRuntimeRenderer.renderCollectionPass(...)` côté `map_runtime` pour rendre chaque ombre ;
- aucun asset externe ;
- aucune donnée Selbrume ;
- aucune baseline ;
- aucun `matchesGoldenFile`.

Conclusion visuelle provisoire : le candidat C (`Short broad`) est le plus proche de l'intention "socle / footprint-like" sans changer le moteur. Le candidat D reste intéressant comme variante plus large, mais plus directionnelle. Le candidat A confirme le problème initial de languette diagonale.

## 2. Objectif du lot

Objectif exact :

```text
Générer une image comparative micro-fixture avec plusieurs variantes de shape/preset ShadowV2,
sans modifier le renderer,
sans modifier le painter,
sans modifier map_core geometry,
sans baseline,
sans Selbrume,
afin de choisir visuellement une forme plus Pokémon-like.
```

Le lot ne sélectionne pas définitivement un nouveau preset. Il produit une matrice lisible pour revue humaine.

## 3. Rappel ShadowV2-35

ShadowV2-35 a conclu que l'artifact du Lot 34 fonctionnait techniquement mais que le rendu ne visait pas encore correctement la référence Pokémon-like :

- problème principal : forme / direction / anchor / largeur ;
- problème secondaire : banding hard-edge ;
- recommandation : comparer plusieurs presets candidats avant de toucher au renderer, au painter ou à la géométrie `map_core`.

ShadowV2-36 applique cette recommandation : mêmes renderer et géométrie, plusieurs valeurs candidates.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

Fichier préexistant non lié au Lot 36 :

```text
reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

Ce fichier n'a pas été modifié par ShadowV2-36.

## 5. Décision AGENTS / design gate déjà satisfait

Commande :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision : le design gate a été satisfait par ShadowV2-35 et validé dans le prompt du Lot 36. Le Lot 36 est donc une exécution bornée d'un artifact manuel, pas une décision créative nouvelle.

Compétences / rituels utilisés :

- `superpowers:using-superpowers` : discipline de workflow.
- `karpathy-guidelines` : scope chirurgical et absence de dérive.
- `superpowers:test-driven-development` : adapté au contexte ; le harness lui-même est un test ciblé qui génère l'artifact.
- `superpowers:verification-before-completion` : vérifications fraîches avant conclusion.
- `superpowers:systematic-debugging` : utilisé après l'échec initial d'analyse dû aux `prefer_const_*`.

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés par ShadowV2-36 :

```text
packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
```

Fichiers modifiés par ShadowV2-36 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-36 :

```text
Aucun
```

Fichiers préexistants hors scope conservés :

```text
reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

## 7. Stratégie de matrice visuelle

Le harness crée une image `800x480` :

- largeur : 5 colonnes de `160px`, une par candidat ;
- hauteur : header `32px`, ligne `shadow-only` `224px`, ligne `shadow + building` `224px` ;
- fond : `#D8E0C8` ;
- grille : `#E6ECD8`, 32x32 ;
- séparateurs : `#B5BEA7` ;
- labels A/B/C/D/E dessinés en traits vectoriels sans dépendance de police ;
- bâtiment simple identique dans chaque cellule.

Le rendu de chaque ombre passe par :

```dart
ShadowRuntimeRenderer.renderCollectionPass(...)
```

La géométrie de chaque candidat passe par :

```dart
resolveProjectedBuildingShadowGeometry(...)
```

Le fichier est placé sous `tool/shadow` pour rester un harness manuel qui écrit volontairement un artifact PNG sur disque.

## 8. Variantes candidates générées

| Colonne | Candidat | Direction | lengthRatio | nearWidthRatio | farWidthRatio | anchor | opacity | color |
|---|---|---:|---:|---:|---:|---:|---:|---|
| A | Current V0 | `(0.8, 0.35)` | `0.32` | `0.90` | `0.72` | `(0.5, 0.96)` | `0.30` | `606060` |
| B | Downward attached | `(0.45, 0.90)` | `0.34` | `1.05` | `0.95` | `(0.5, 0.92)` | `0.30` | `606060` |
| C | Short broad | `(0.35, 0.70)` | `0.24` | `1.15` | `1.05` | `(0.5, 0.95)` | `0.28` | `606060` |
| D | Wide trapezoid | `(0.55, 0.65)` | `0.30` | `1.20` | `1.10` | `(0.5, 0.94)` | `0.28` | `606060` |
| E | Low side cast | `(0.70, 0.45)` | `0.26` | `1.10` | `0.95` | `(0.5, 0.98)` | `0.30` | `606060` |

## 9. Description de l’image générée

Chemin :

```text
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Dimensions :

```text
800 x 480
```

Organisation :

```text
Header : A | B | C | D | E
Ligne haute : shadow-only
Ligne basse : shadow + simple building block
```

Le bâtiment simple est dessiné avec :

```text
body    = #E9D7B9
roof    = #B7655A
outline = #343A3D
door    = #7E5547
windows = #8EC6D8
```

## 10. Géométrie / points générés par candidat

Calculs avec les mêmes formules que `resolveProjectedBuildingShadowGeometry(...)` et les mêmes metrics :

```text
StaticShadowVisualMetrics(
  left: 32,
  top: 64,
  visualWidth: 64,
  visualHeight: 96,
)
```

Candidate A — Current V0 :

```text
p0: (75.54, 129.77)
p1: (52.46, 182.55)
p2: (82.91, 189.58)
p3: (101.38, 147.36)
bounds: left=52.46, top=129.77, width=48.92, height=59.81
centroid: (78.07, 162.32)
opacity: 0.30
```

Candidate B — Downward attached :

```text
p0: (94.05, 137.29)
p1: (33.95, 167.35)
p2: (51.41, 195.11)
p3: (105.79, 167.92)
bounds: left=33.95, top=137.29, width=71.84, height=57.82
centroid: (71.30, 166.92)
opacity: 0.30
```

Candidate C — Short broad :

```text
p0: (96.91, 138.74)
p1: (31.09, 171.66)
p2: (44.25, 190.83)
p3: (104.36, 160.78)
bounds: left=31.09, top=138.74, width=73.27, height=52.09
centroid: (69.15, 165.50)
opacity: 0.28
```

Candidate D — Wide trapezoid :

```text
p0: (93.31, 129.44)
p1: (34.69, 179.04)
p2: (55.73, 198.96)
p3: (109.47, 153.49)
bounds: left=34.69, top=129.44, width=74.79, height=69.53
centroid: (73.30, 165.23)
opacity: 0.28
```

Candidate E — Low side cast :

```text
p0: (83.03, 128.47)
p1: (44.97, 187.69)
p2: (68.56, 197.15)
p3: (101.43, 146.01)
bounds: left=44.97, top=128.47, width=56.47, height=68.68
centroid: (74.50, 164.83)
opacity: 0.30
```

## 11. Harness manuel créé

Fichier :

```text
packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Rôle :

- définit les 5 candidats ;
- calcule leur géométrie via `map_core` ;
- convertit chaque géométrie en `ShadowRuntimeRenderInstruction` ;
- rend chaque cellule via `ShadowRuntimeRenderer.renderCollectionPass(...)` ;
- écrit un seul PNG ;
- vérifie que l'image n'est pas vide avec quelques pixels utiles.

Le harness ne lit pas Selbrume, ne charge aucun asset externe et ne compare aucune image de référence.

## 12. Assertions du test

Assertions incluses :

- image width == `800` ;
- image height == `480` ;
- pixel fond == `#D8E0C8` ;
- pour chaque candidat, le pixel au centroïde de l'ombre diffère du fond ;
- pour chaque candidat, un pixel du corps du bâtiment vaut `#E9D7B9`, prouvant que le bâtiment est dessiné au-dessus ;
- PNG écrit ;
- fichier existe ;
- taille du fichier > 0.

## 13. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
00:00 +0: generates projected building shadow V2 candidate matrix artifact
00:00 +1: All tests passed!
```

## 14. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff    10K May 21 00:02 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Commande :

```bash
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Sortie :

```text
4d008034024bf201fa63ce4ee0cb5fc19003c02764479fb9791d2679f97c3f5a  reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png: PNG image data, 800 x 480, 8-bit/color RGBA, non-interlaced
```

## 15. Résultats des tests

Test ciblé :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
00:00 +0: generates projected building shadow V2 candidate matrix artifact
00:00 +1: All tests passed!
```

## 16. Résultat analyze

Première analyse :

```text
Analyzing shadow_v2_candidate_matrix_artifact_test.dart...

   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:52:3 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:66:3 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:80:3 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:94:3 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:108:3 • prefer_const_constructors
   info • Use 'const' for final variables initialized to a constant value • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:246:3 • prefer_const_declarations
   info • Use 'const' for final variables initialized to a constant value • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:247:3 • prefer_const_declarations
   info • Use 'const' for final variables initialized to a constant value • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:248:3 • prefer_const_declarations
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:287:5 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:288:5 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:292:5 • prefer_const_constructors
   info • Use 'const' with the constructor to improve performance • tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart:293:5 • prefer_const_constructors

12 issues found. (ran in 1.7s)
```

Correction appliquée :

- `_candidates` passé en `const` ;
- `top/middle/bottom` de label passés en `const` ;
- offsets constants de séparateurs passés en `const` ;
- formatage ciblé du fichier créé.

Commande de formatage ciblé :

```bash
cd packages/map_runtime && dart format tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Sortie :

```text
Formatted tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
Formatted 1 file (1 changed) in 0.01 seconds.
```

Analyse finale :

```bash
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_candidate_matrix_artifact_test.dart...
No issues found! (ran in 1.2s)
```

## 17. Audit anti-dérive

Commande finale :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows" packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Sortie :

```text

```

Interprétation :

- aucune baseline ;
- aucun `matchesGoldenFile` ;
- aucun Selbrume ;
- aucun `SHADOW_SCREENSHOT` ;
- aucun `genericProjection` ;
- aucune auto-policy ;
- aucun diagnostic utilisé comme logique de rendu.

L'audit initial large sur `packages/map_runtime/tool`, `packages/map_runtime/test` et `reports/shadows` a trouvé des hits historiques dans des rapports et outils Selbrume plus anciens. Ces hits sont préexistants et ne concernent pas le harness créé par ShadowV2-36.

## 18. Ce qui n’a volontairement pas été modifié

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

En particulier :

- `ShadowRuntimeRenderer` non modifié ;
- `MapLayersComponent` non modifié ;
- `PlayableMapGame` non modifié ;
- `runtime_projected_building_shadow_collection.dart` non modifié ;
- `projected_building_shadow_runtime_adapter.dart` non modifié ;
- `editor_static_shadow_preview_painter.dart` non modifié ;
- `MapGridPainter` non modifié ;
- `resolveProjectedBuildingShadowGeometry(...)` non modifié ;
- `createProjectedStaticShadowOpacityBands(...)` non modifié.

## 19. Ce qui n’a volontairement pas été créé

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

Un seul PNG artifact a été créé, dans `reports/shadows/screenshots/`.

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text

```

Note : les fichiers créés par le lot sont non suivis, donc `git diff --stat` ne les liste pas.

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text

```

Note : les fichiers créés par le lot sont non suivis, donc `git diff --name-status` ne les liste pas.

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text

```

Résultat : propre.

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
?? reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
?? reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
```

`shadow_v2_35_projected_building_shadow_shape_banding_review_design.md` est préexistant et hors scope ShadowV2-36.

## 24. Analyse visuelle comparative

Inspection visuelle de l'image générée :

- A — Current V0 : confirme le problème Lot 34. La forme reste une languette diagonale étroite, latérale, peu attachée au bâtiment.
- B — Downward attached : plus large et plus basse que A, mais encore assez directionnelle. L'attachement est meilleur, sans devenir franchement un socle.
- C — Short broad : la plus proche d'une lecture "socle court". Elle est plus large, plus courte, moins détachée, et reste simple sans changer la géométrie.
- D — Wide trapezoid : large et lisible, mais plus longue et plus présente. Elle peut marcher pour certains bâtiments, mais risque davantage la plaque grise.
- E — Low side cast : améliore A en largeur, mais garde trop la lecture latérale. Elle semble moins alignée avec la référence Pokémon-like fournie.

Le banding reste visible sur tous les candidats, mais l'image confirme que la forme pèse davantage sur la perception que les bandes. C'est cohérent avec le diagnostic du Lot 35.

## 25. Candidat recommandé ou conclusion provisoire

Conclusion provisoire :

```text
Candidat C — Short broad
```

Pourquoi :

- il réduit le côté "languette diagonale" ;
- il lit davantage comme une ombre courte attachée au bâtiment ;
- il reste compatible avec le moteur actuel ;
- il ne demande ni nouveau mode géométrique, ni modification renderer/painter ;
- son opacité `0.28` rend la forme moins sale que les variantes à `0.30`.

Réserve :

```text
Le choix doit rester soumis à review humaine de l'image.
```

Alternative à garder dans la discussion :

```text
D — Wide trapezoid
```

D est plus présent et peut mieux lire sur certains volumes, mais il est aussi plus risqué si l'objectif est d'éviter une grosse plaque grise.

## 26. Risques / réserves

- Le bâtiment du harness est volontairement simple ; il aide à juger l'attachement mais ne remplace pas un sprite réel.
- Les labels vectoriels A-E sont fonctionnels, mais minimalistes.
- La matrice ne prouve pas la qualité sur des bâtiments larges, hauts ou asymétriques.
- Le banding reste inchangé ; si le meilleur candidat semble encore dégradé par les bandes, un lot dédié banding restera nécessaire.
- Le PNG est un artifact manuel, pas une baseline. Il ne faut pas le transformer implicitement en oracle CI.

## 27. Auto-critique

- Le lot a-t-il créé une baseline par accident ? Non.
- Le PNG est-il bien un artifact manuel ? Oui, généré par un harness ciblé sous `tool/shadow`.
- Le test écrit-il seulement l’image autorisée ? Oui, un seul chemin `_artifactPath`.
- L’image permet-elle vraiment de comparer les 5 candidats ? Oui, chaque candidat est visible en shadow-only et avec bâtiment.
- Les candidats sont-ils suffisamment différents ? Oui : direction, longueur, largeur proche/lointaine, ancre et opacité varient.
- Le panel bâtiment aide-t-il à juger l’attachement au volume ? Oui, surtout pour comparer A avec B/C/D.
- Le harness dépend-il de Selbrume ou d’un asset externe ? Non.
- Le renderer utilisé est-il bien `ShadowRuntimeRenderer` ? Oui.
- La géométrie utilisée correspond-elle au système actuel ? Oui, via `resolveProjectedBuildingShadowGeometry(...)`.
- Le rapport contient-il toutes les preuves ? Oui : status initial, génération, analyze, hash, file, anti-dérive, git final, contenu complet du harness.

## 28. Regard critique sur le prompt

Le prompt est bien borné et cohérent avec les lots précédents. Son point le plus important est d'empêcher une bascule prématurée vers la géométrie ou le renderer. La matrice donne une meilleure information qu'un seul artifact, tout en restant non destructive.

Petit risque : demander une conclusion visuelle dans un lot d'artifact peut faire croire que le choix est définitif. Le rapport garde donc une conclusion provisoire et recommande un design gate de sélection.

## 29. Prochain lot recommandé

Si la review humaine confirme le candidat C :

```text
ShadowV2-37 — Projected Building Shadow Candidate Selection / Calibration Update Design Gate
```

Objectif :

```text
Décider comment remplacer la calibration V0 par le candidat retenu
dans les tests / fixtures,
sans encore toucher aux données réelles,
sans Selbrume,
sans baseline,
sans renderer/painter.
```

Si aucun candidat ne convient :

```text
ShadowV2-37 — Projected Building Shadow Footprint Geometry Design Gate
```

Si un candidat convient mais que les bandes restent le problème principal :

```text
ShadowV2-37 — Projected Building Shadow Banding Adjustment Design Gate
```

## 30. Code complet des fichiers créés/modifiés

### `packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart`

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
        ProjectedShadowAnchor,
        ProjectedShadowAppearance,
        ProjectedShadowDirection,
        ProjectedShadowOffset,
        ProjectedShadowShapeTuning,
        ProjectedShadowTimeOfDayMode,
        ShadowRenderPass,
        StaticShadowVisualMetrics,
        resolveProjectedBuildingShadowGeometry;
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 800;
const _artifactHeight = 480;
const _columnWidth = 160;
const _headerHeight = 32;
const _cellHeight = 224;
const _shadowOnlyRowTop = _headerHeight;
const _buildingRowTop = _headerHeight + _cellHeight;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png';

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

const _candidates = [
  _ShadowCandidate(
    id: 'candidate-a-current-v0',
    label: 'A — Current V0',
    letter: 'A',
    directionX: 0.8,
    directionY: 0.35,
    lengthRatio: 0.32,
    nearWidthRatio: 0.90,
    farWidthRatio: 0.72,
    anchorXRatio: 0.5,
    anchorYRatio: 0.96,
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-b-downward-attached',
    label: 'B — Downward attached',
    letter: 'B',
    directionX: 0.45,
    directionY: 0.90,
    lengthRatio: 0.34,
    nearWidthRatio: 1.05,
    farWidthRatio: 0.95,
    anchorXRatio: 0.5,
    anchorYRatio: 0.92,
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-c-short-broad',
    label: 'C — Short broad',
    letter: 'C',
    directionX: 0.35,
    directionY: 0.70,
    lengthRatio: 0.24,
    nearWidthRatio: 1.15,
    farWidthRatio: 1.05,
    anchorXRatio: 0.5,
    anchorYRatio: 0.95,
    opacity: 0.28,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-d-wide-trapezoid',
    label: 'D — Wide trapezoid',
    letter: 'D',
    directionX: 0.55,
    directionY: 0.65,
    lengthRatio: 0.30,
    nearWidthRatio: 1.20,
    farWidthRatio: 1.10,
    anchorXRatio: 0.5,
    anchorYRatio: 0.94,
    opacity: 0.28,
    colorHexRgb: '606060',
  ),
  _ShadowCandidate(
    id: 'candidate-e-low-side-cast',
    label: 'E — Low side cast',
    letter: 'E',
    directionX: 0.70,
    directionY: 0.45,
    lengthRatio: 0.26,
    nearWidthRatio: 1.10,
    farWidthRatio: 0.95,
    anchorXRatio: 0.5,
    anchorYRatio: 0.98,
    opacity: 0.30,
    colorHexRgb: '606060',
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow V2 candidate matrix artifact',
      () async {
    final image = await _renderCandidateMatrix();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, _shadowOnlyRowTop + 12);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var index = 0; index < _candidates.length; index += 1) {
      final candidate = _candidates[index];
      final columnLeft = index * _columnWidth;
      final geometry = _geometryForCandidate(candidate);
      final centroid = _centroid(geometry);
      final shadowPixel = await _pixelAt(
        image,
        columnLeft + centroid.x.round(),
        _shadowOnlyRowTop + centroid.y.round(),
      );
      expect(
        shadowPixel,
        isNot(backgroundPixel),
        reason: '${candidate.label} should render a visible shadow',
      );

      final buildingPixel = await _pixelAt(
        image,
        columnLeft + 80,
        _buildingRowTop + 150,
      );
      expect(
        buildingPixel,
        _rgba(_buildingBodyColor),
        reason: '${candidate.label} building body should render over shadow',
      );
    }

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

// Manual artifact harness: this writes one controlled PNG for human review of
// candidate ShadowV2 shapes. It is not an image comparison test.
Future<ui.Image> _renderCandidateMatrix() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < _candidates.length; index += 1) {
    final candidate = _candidates[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawCandidateLabel(canvas, candidate.letter, columnLeft: columnLeft);
    _drawCellBackground(canvas, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawCellBackground(canvas, columnLeft, _buildingRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _shadowOnlyRowTop.toDouble());
    _drawShadow(canvas, candidate, columnLeft, _buildingRowTop.toDouble());
    _drawSimpleBuilding(canvas, columnLeft, _buildingRowTop.toDouble());
  }

  _drawMatrixDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawCellBackground(ui.Canvas canvas, double left, double top) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, _columnWidth + 0.0, _cellHeight + 0.0),
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
      ui.Offset(left + x, top + _cellHeight),
      paint,
    );
  }
  for (var y = 32.0; y < _cellHeight; y += 32) {
    canvas.drawLine(
      ui.Offset(left, top + y),
      ui.Offset(left + _columnWidth, top + y),
      paint,
    );
  }
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
  }
}

void _drawMatrixDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;
  for (var x = _columnWidth.toDouble(); x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(ui.Offset(x - 0.5, 0),
        ui.Offset(x - 0.5, _artifactHeight + 0.0), paint);
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
    instructions: [_runtimeInstructionForCandidate(candidate)],
  );
}

ShadowRuntimeRenderInstruction _runtimeInstructionForCandidate(
  _ShadowCandidate candidate,
) {
  final geometry = _geometryForCandidate(candidate);
  final bounds = _boundsForGeometry(geometry);

  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.projectedPolygon,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: bounds.left,
    worldTop: bounds.top,
    width: bounds.width,
    height: bounds.height,
    opacity: geometry.opacity,
    colorHexRgb: geometry.colorHexRgb,
    polygonPoints: [
      for (final point in geometry.points)
        ShadowRuntimePoint(worldX: point.x, worldY: point.y),
    ],
  );
}

ProjectedBuildingShadowGeometry _geometryForCandidate(
  _ShadowCandidate candidate,
) {
  final preset = ProjectBuildingShadowPreset(
    id: candidate.id,
    name: candidate.label,
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
  final config = ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: candidate.id,
    anchor: ProjectedShadowAnchor(
      xRatio: candidate.anchorXRatio,
      yRatio: candidate.anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: config,
    preset: preset,
    metrics: _metrics,
  );
  if (geometry == null) {
    throw StateError('${candidate.label} did not produce geometry');
  }
  return geometry;
}

_Bounds _boundsForGeometry(ProjectedBuildingShadowGeometry geometry) {
  var minX = geometry.points.first.x;
  var maxX = geometry.points.first.x;
  var minY = geometry.points.first.y;
  var maxY = geometry.points.first.y;

  for (final point in geometry.points.skip(1)) {
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

  return _Bounds(
    left: minX,
    top: minY,
    width: maxX - minX,
    height: maxY - minY,
  );
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

void _drawSimpleBuilding(ui.Canvas canvas, double columnLeft, double rowTop) {
  final left = columnLeft + 32;
  final top = rowTop + 64;
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
    throw StateError('Could not encode ShadowV2 candidate matrix as PNG');
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
    throw StateError('Could not read raw pixels from matrix image');
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
    required this.directionX,
    required this.directionY,
    required this.lengthRatio,
    required this.nearWidthRatio,
    required this.farWidthRatio,
    required this.anchorXRatio,
    required this.anchorYRatio,
    required this.opacity,
    required this.colorHexRgb,
  });

  final String id;
  final String label;
  final String letter;
  final double directionX;
  final double directionY;
  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;
  final double anchorXRatio;
  final double anchorYRatio;
  final double opacity;
  final String colorHexRgb;
}

final class _Bounds {
  const _Bounds({
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

Le PNG est un fichier binaire ; son contenu complet est représenté par le chemin, la taille, les dimensions et le SHA-256 listés plus haut.

Le rapport courant est le fichier créé :

```text
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
```

Checklist finale :
- [x] Harness manuel créé sous packages/map_runtime/tool/shadow
- [x] PNG matrix artifact créé
- [x] PNG dans reports/shadows/screenshots
- [x] Aucun fichier baseline créé
- [x] Aucun matchesGoldenFile
- [x] Aucun Selbrume modifié ou lu pour générer l’image
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] 5 candidats affichés
- [x] Shadow-only affiché pour chaque candidat
- [x] Shadow + building affiché pour chaque candidat
- [x] Candidate A Current V0 inclus
- [x] Candidate B Downward attached inclus
- [x] Candidate C Short broad inclus
- [x] Candidate D Wide trapezoid inclus
- [x] Candidate E Low side cast inclus
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] resolveProjectedBuildingShadowGeometry utilisé ou équivalent documenté
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope
