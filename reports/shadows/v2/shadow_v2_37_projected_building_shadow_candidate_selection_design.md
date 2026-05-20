# ShadowV2-37 — Projected Building Shadow Candidate Selection / Calibration Update Design Gate

## 1. Résumé exécutif

ShadowV2-37 est un design gate / audit-only.

Décision recommandée :

```text
Candidat recommandé : C — Short broad
Décision : accepter Candidate C comme nouvelle calibration ShadowV2 V0 à appliquer en test-only au Lot 38.
```

Pourquoi :

- C réduit clairement le problème de languette diagonale visible sur A ;
- C est le plus court et le plus proche d'un socle / footprint-like parmi les candidats existants ;
- C reste suffisamment large pour lire comme attaché au bâtiment ;
- C utilise une opacité `0.28`, moins sale que `0.30` sur la micro-fixture ;
- C ne demande aucune modification de renderer, painter, modèle, codec, géométrie `map_core`, baseline ou donnée Selbrume.

Lot 38 recommandé :

```text
ShadowV2-38 — Projected Building Shadow Calibration Update V1
```

Objectif : remplacer la calibration V0 test-only par Candidate C dans les micro-fixtures `map_core`, `map_runtime` et `map_editor`, sans toucher à la production.

## 2. Objectif du lot

Objectif exact :

```text
Analyser la matrice comparative ShadowV2-36,
choisir officiellement le meilleur candidat de calibration,
ou conclure qu'aucun candidat trapézoïdal ne suffit,
puis préparer un Lot 38 strictement borné.
```

Ce lot ne modifie aucun test, aucun preset, aucun artifact et aucune image.

Question tranchée :

```text
Un candidat trapézoïdal suffit-il ?
```

Réponse :

```text
Oui, Candidate C est suffisamment meilleur que A pour devenir la prochaine calibration test-only.
La géométrie trapézoïdale reste imparfaite, mais il est prématuré de concevoir un nouveau mode footprint-like avant d'avoir propagé et vérifié C.
```

## 3. Rappel ShadowV2-34 à ShadowV2-36

ShadowV2-34 :

```text
Artifact micro 320x224 :
- panel gauche shadow-only ;
- panel droit shadow + bâtiment simple ;
- rendu par ShadowRuntimeRenderer.renderCollectionPass(...) ;
- pas de baseline ;
- pas de Selbrume.
```

Constat humain :

```text
Le rendu technique marche, mais l'ombre V0 ressemble trop à une languette diagonale.
```

ShadowV2-35 :

```text
Diagnostic principal : forme / direction / anchor / largeur.
Diagnostic secondaire : banding hard-edge visible.
Recommandation : générer une matrice de candidats avant de toucher au renderer ou à la géométrie.
```

ShadowV2-36 :

```text
Artifact matrix 800x480 :
- A — Current V0 ;
- B — Downward attached ;
- C — Short broad ;
- D — Wide trapezoid ;
- E — Low side cast ;
- ligne haute shadow-only ;
- ligne basse shadow + simple building block.
```

Conclusion provisoire du Lot 36 :

```text
Candidat C — Short broad
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

Interprétation :

```text
Le worktree était propre avant ShadowV2-37.
Les fichiers ShadowV2-35 et ShadowV2-36 sont déjà présents dans l'état de référence local au moment du Lot 37.
```

Fichiers préexistants non liés au Lot 37 :

```text
Aucun fichier modifié ou non suivi signalé par git status initial.
```

Fichiers créés par ShadowV2-37 :

```text
reports/shadows/v2/shadow_v2_37_projected_building_shadow_candidate_selection_design.md
```

Fichiers modifiés par ShadowV2-37 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-37 :

```text
Aucun
```

## 5. Décision AGENTS / design gate

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

Décision :

```text
Le Lot 37 est explicitement un design gate / audit-only.
Le rapport demandé est la spec de décision.
Aucun fichier docs/superpowers, aucun commit et aucun plan d'implémentation séparé ne sont créés, car le prompt impose un seul rapport Markdown et Git en lecture seule.
```

Compétences / rituels utilisés :

- `superpowers:using-superpowers` ;
- `superpowers:brainstorming`, adapté au design gate déjà cadré par les Lots 35/36 ;
- `karpathy-guidelines` pour éviter de sur-élargir vers géométrie ou renderer ;
- `superpowers:verification-before-completion` pour vérifier avant conclusion.

## 6. Fichiers audités

Artifact Lot 36 :

```text
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
```

Rapport Lot 35 :

```text
reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

Harness Lot 36 :

```text
packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
```

Commandes d'audit exécutées :

```bash
file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
rg -n "candidate-a-current-v0|candidate-b-downward-attached|candidate-c-short-broad|candidate-d-wide-trapezoid|candidate-e-low-side-cast|directionX|directionY|lengthRatio|nearWidthRatio|farWidthRatio|anchorXRatio|anchorYRatio|opacity|colorHexRgb" packages/map_runtime/tool reports/shadows/v2
rg -n "Projected Building Shadow Candidate Matrix|Candidat C|Short broad|Wide trapezoid|languette|footprint|socle|banding|ShadowV2-36" reports/shadows/v2
```

Le premier `rg` est volontairement large : il retourne aussi des hits historiques dans les rapports ShadowV2 antérieurs. Les hits utiles au présent lot sont ceux du harness Lot 36 et des rapports Lot 35/36.

## 7. Audit artifact matrix Lot 36

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png: PNG image data, 800 x 480, 8-bit/color RGBA, non-interlaced
```

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
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Sortie :

```text
4d008034024bf201fa63ce4ee0cb5fc19003c02764479fb9791d2679f97c3f5a  reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Métadonnées :

```text
dimensions: 800 x 480
taille: 10K
format: PNG RGBA non-interlaced
sha256: 4d008034024bf201fa63ce4ee0cb5fc19003c02764479fb9791d2679f97c3f5a
```

Présence des candidats :

```text
Oui : colonnes A, B, C, D, E.
```

Présence des deux lignes :

```text
Oui :
- ligne haute : shadow-only ;
- ligne basse : shadow + simple building block.
```

Analyse visuelle directe :

```text
A reste une languette diagonale latérale.
B améliore l'attachement mais reste directionnel.
C lit le plus comme une ombre courte et large, proche d'un socle.
D est très lisible, mais plus longue et plus présente.
E améliore A mais garde une lecture latérale.
```

Limites de l'artifact :

- bâtiment simplifié, non sprite réel ;
- fond clair quadrillé, pas une vraie carte ;
- pas de variété de tailles de bâtiments ;
- banding inchangé ;
- artifact manuel, pas baseline.

Conclusion provisoire Lot 36 confirmée :

```text
Candidate C est le meilleur candidat existant pour une calibration test-only V1.
```

## 8. Analyse candidat A

Valeurs :

```text
id: candidate-a-current-v0
label: A — Current V0
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
anchor: (0.5, 0.96)
opacity: 0.30
colorHexRgb: 606060
```

Géométrie documentée au Lot 36 :

```text
bounds: left=52.46, top=129.77, width=48.92, height=59.81
centroid: (78.07, 162.32)
```

Diagnostic visuel :

```text
A confirme le problème initial.
La forme est étroite, fortement latérale, et donne l'impression d'une languette détachée du bâtiment.
```

Forces :

- témoin technique connu ;
- couleur/opacité déjà verrouillées par le Lot 32 ;
- compatible moteur actuel.

Faiblesses :

- trop étroit ;
- trop latéral ;
- pas assez attaché au volume ;
- `farWidthRatio` inférieur à `nearWidthRatio`, ce qui affine la forme ;
- opacité `0.30` un peu plus sale dans une forme déjà compacte.

Décision :

```text
Rejeté comme calibration V1.
```

## 9. Analyse candidat B

Valeurs :

```text
id: candidate-b-downward-attached
label: B — Downward attached
direction: (0.45, 0.90)
lengthRatio: 0.34
nearWidthRatio: 1.05
farWidthRatio: 0.95
anchor: (0.5, 0.92)
opacity: 0.30
colorHexRgb: 606060
```

Géométrie documentée au Lot 36 :

```text
bounds: left=33.95, top=137.29, width=71.84, height=57.82
centroid: (71.30, 166.92)
```

Diagnostic visuel :

```text
B est nettement meilleur que A pour l'attachement et la largeur.
La direction plus verticale évite la languette latérale pure.
Cependant B reste assez allongé et directionnel.
```

Forces :

- meilleur ancrage apparent que A ;
- largeur plus adaptée ;
- direction plus compatible top-down / 3/4 ;
- compatible moteur actuel.

Faiblesses :

- `lengthRatio: 0.34` rend la forme encore assez longue ;
- opacité `0.30` peut rester un peu présente ;
- moins "socle court" que C.

Décision :

```text
Rejeté comme calibration principale, mais utile comme référence de direction plus verticale.
```

## 10. Analyse candidat C

Valeurs :

```text
id: candidate-c-short-broad
label: C — Short broad
direction: (0.35, 0.70)
lengthRatio: 0.24
nearWidthRatio: 1.15
farWidthRatio: 1.05
anchor: (0.5, 0.95)
opacity: 0.28
colorHexRgb: 606060
```

Géométrie documentée au Lot 36 :

```text
bounds: left=31.09, top=138.74, width=73.27, height=52.09
centroid: (69.15, 165.50)
```

Diagnostic visuel :

```text
C est le meilleur compromis parmi les candidats existants.
Il est court, large, moins détaché, et se rapproche d'une masse grise attachée au pied du bâtiment.
```

Forces :

- forme plus "socle" que A/B/E ;
- plus courte que B/D ;
- largeur suffisante pour éviter la languette ;
- opacité `0.28` plus sobre ;
- `farWidthRatio` proche du `nearWidthRatio`, donc moins de pincement ;
- compatible moteur actuel sans nouveau mode géométrique.

Faiblesses :

- reste une géométrie trapézoïdale directionnelle ;
- peut être un peu trop courte pour certains bâtiments très hauts ;
- ne résout pas le banding, seulement sa perception par meilleure forme.

Décision :

```text
Retenu.
```

## 11. Analyse candidat D

Valeurs :

```text
id: candidate-d-wide-trapezoid
label: D — Wide trapezoid
direction: (0.55, 0.65)
lengthRatio: 0.30
nearWidthRatio: 1.20
farWidthRatio: 1.10
anchor: (0.5, 0.94)
opacity: 0.28
colorHexRgb: 606060
```

Géométrie documentée au Lot 36 :

```text
bounds: left=34.69, top=129.44, width=74.79, height=69.53
centroid: (73.30, 165.23)
```

Diagnostic visuel :

```text
D est très lisible et corrige fortement la largeur.
Mais il est plus long et plus présent que C, avec davantage de risque de plaque grise.
```

Forces :

- largeur excellente ;
- bonne lisibilité ;
- opacité `0.28` sobre ;
- peut fonctionner sur des bâtiments plus grands.

Faiblesses :

- trop présent pour un preset V0 unique ;
- plus susceptible de voler l'attention au bâtiment ;
- le risque "grosse plaque grise" augmente ;
- moins proche du socle court que C.

Décision :

```text
Rejeté comme calibration V1 unique, conservé comme alternative future pour grands bâtiments.
```

## 12. Analyse candidat E

Valeurs :

```text
id: candidate-e-low-side-cast
label: E — Low side cast
direction: (0.70, 0.45)
lengthRatio: 0.26
nearWidthRatio: 1.10
farWidthRatio: 0.95
anchor: (0.5, 0.98)
opacity: 0.30
colorHexRgb: 606060
```

Géométrie documentée au Lot 36 :

```text
bounds: left=44.97, top=128.47, width=56.47, height=68.68
centroid: (74.50, 164.83)
```

Diagnostic visuel :

```text
E améliore A par la largeur et l'ancre plus basse, mais conserve trop la lecture side-cast.
```

Forces :

- plus large que A ;
- plus court que A en ratio ;
- conserve une direction latérale qui peut convenir à certains sprites.

Faiblesses :

- trop proche de la logique qui a échoué visuellement en V0 ;
- width inférieure à C/D ;
- opacité `0.30` plus présente ;
- moins attaché qu'un socle court.

Décision :

```text
Rejeté.
```

## 13. Comparaison synthétique

| Candidat | Attachement | Lecture Pokémon-like | Sobriété | Compatibilité moteur | Décision |
|---|---|---|---|---|---|
| A | Faible | Faible | Moyen | Forte | Rejeté |
| B | Moyen+ | Moyen | Moyen | Forte | Rejeté |
| C | Bon | Bon | Bon | Forte | Retenu |
| D | Bon | Moyen+ | Moyen- | Forte | Rejeté pour V1 unique |
| E | Moyen- | Moyen- | Moyen | Forte | Rejeté |

Lecture principale :

```text
C est meilleur que A, pas seulement différent.
```

Pourquoi :

- A est étroit et latéral ;
- C est large et court ;
- C met la largeur au service de l'attachement ;
- C réduit la sensation de projection depuis un point diagonal ;
- C reste discret grâce à `opacity: 0.28`.

Pourquoi ne pas abandonner la géométrie actuelle maintenant :

```text
La matrice montre qu'une simple calibration améliore nettement le rendu.
Il faut d'abord propager Candidate C dans les tests calibrés avant de conclure que le trapèze est insuffisant.
```

## 14. Option recommandée

Candidat recommandé :

```text
Candidate C — Short broad
```

Décision :

```text
Accepter Candidate C comme nouvelle calibration ShadowV2 V0/V1 test-only.
```

Valeurs à retenir :

```text
id: pokemon-building-shadow-v1
name: Pokemon-like building shadow V1
direction: ProjectedShadowDirection(x: 0.35, y: 0.70)
shape.lengthRatio: 0.24
shape.nearWidthRatio: 1.15
shape.farWidthRatio: 1.05
appearance.opacity: 0.28
appearance.colorHexRgb: 606060
timeOfDayMode: fixed
anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.95)
localOffset: ProjectedShadowOffset(x: 0, y: 0)
```

Pourquoi :

- meilleure lecture socle ;
- plus courte ;
- plus large ;
- plus sobre ;
- compatible runtime/editor par les mêmes données ;
- ne nécessite aucune modification production.

Pourquoi les autres options sont rejetées :

- Candidate A : témoin actuel, trop languette.
- Candidate B : meilleure que A, mais encore trop allongée pour être le choix V1.
- Candidate D : forte candidate visuelle, mais trop présente pour un preset standard unique.
- Candidate E : conserve trop la lecture latérale de A.
- Hybride C/D : non visualisé dans la matrice ; créer un nouveau candidat retarderait la décision alors que C est déjà acceptable.
- Nouvelle géométrie footprint-like : prématurée ; elle doit rester une piste si C échoue après propagation test-only.

Lot 38 doit faire :

- remplacer les micro-fixtures calibrées par Candidate C ;
- recalculer les points attendus explicitement ;
- mettre à jour les assertions runtime/editor ;
- garder le renderer, le painter et la géométrie intacts ;
- produire un rapport avec evidence pack.

Lot 38 ne doit pas faire :

- modifier Selbrume ;
- créer une baseline ;
- créer un nouveau screenshot ;
- modifier production ;
- modifier renderer/painter ;
- modifier `resolveProjectedBuildingShadowGeometry(...)` ;
- créer UI authoring.

## 15. Plan précis du Lot 38

Nom recommandé :

```text
ShadowV2-38 — Projected Building Shadow Calibration Update V1
```

Objectif :

```text
Remplacer la calibration V0 test-only par Candidate C dans les micro-fixtures map_core / map_runtime / map_editor,
sans modifier la production,
sans Selbrume,
sans baseline,
sans renderer/painter.
```

Fichiers à modifier :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichier à créer :

```text
reports/shadows/v2/shadow_v2_38_projected_building_shadow_calibration_update_v1.md
```

Fichiers à ne pas modifier :

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
```

Valeurs à appliquer :

```text
preset id: pokemon-building-shadow-v1
preset name: Pokemon-like building shadow V1
direction: (0.35, 0.70)
lengthRatio: 0.24
nearWidthRatio: 1.15
farWidthRatio: 1.05
anchor: (0.5, 0.95)
localOffset: (0, 0)
opacity: 0.28
colorHexRgb: 606060
```

Points attendus pour la micro-fixture historique :

```text
p0: (96.91, 138.74)
p1: (31.09, 171.66)
p2: (44.25, 190.83)
p3: (104.36, 160.78)
bounds: left=31.09, top=138.74, width=73.27, height=52.09
```

Tests ciblés à lancer :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Régressions utiles :

```bash
cd packages/map_core && dart test test/shadow_v2
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart test/shadow/projected_building_shadow_runtime_adapter_test.dart
cd packages/map_editor && flutter test test/map_grid_painter_test.dart test/application/shadow/editor_static_shadow_preview_test.dart
```

Analyze ciblé :

```bash
cd packages/map_core && dart analyze test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_runtime && flutter analyze test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Critères de validation :

- aucun fichier de production modifié ;
- Candidate C utilisée dans les trois micro-fixtures ;
- points explicites vérifiés avec `closeTo` ;
- runtime visual POC continue à produire pixel intérieur visible / extérieur stable ;
- editor preview vérifie points, bounds, opacité, couleur ;
- tests ciblés passent ;
- régressions utiles passent ;
- analyzes ciblés OK ;
- git diff --check propre ;
- status final conforme.

## 16. Fichiers explicitement interdits au Lot 38

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Le Lot 38 ne doit pas créer :

```text
fichier Dart production
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
baseline
screenshot
```

Le Lot 38 ne doit pas modifier :

```text
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

## 17. Risques / réserves

- Candidate C est validée sur une micro-fixture simplifiée, pas sur des bâtiments réels.
- Candidate C ne supprime pas le banding ; elle rend seulement les bandes moins centrales dans la perception.
- Un seul preset standard peut être insuffisant pour des bâtiments très hauts, très larges ou asymétriques.
- Candidate D pourrait être utile plus tard pour des bâtiments plus grands, mais elle est trop présente comme default unique.
- Le prochain lot doit rester test-only ; appliquer à Selbrume serait prématuré.

## 18. Auto-critique

- Le lot est-il bien design-only ? Oui, seul ce rapport est créé.
- La décision est-elle vraiment justifiée par l’image ? Oui : C est visiblement plus court, plus large et plus attaché que A.
- Le candidat retenu est-il meilleur que A, pas juste différent ? Oui : il corrige les défauts principaux identifiés au Lot 35.
- Le plan Lot 38 évite-t-il production / Selbrume / baseline ? Oui.
- Le plan Lot 38 évite-t-il de modifier le renderer/painter trop tôt ? Oui.
- Le rapport distingue-t-il préférence artistique et preuve technique ? Oui : la préférence est Candidate C ; les preuves techniques sont la matrice, les valeurs, les bounds et la compatibilité moteur.
- Le rapport contient-il toutes les preuves ? Oui : status initial, métadonnées artifact, audits, décision, plan, git final.

## 19. Regard critique sur le prompt

Le prompt est utilement strict : il empêche de sauter trop vite vers une géométrie footprint-like ou un réglage renderer. Le point le plus important est de forcer une décision avant d'écrire un nouveau lot test-only.

La seule tension est que l'image reste une micro-fixture. Elle suffit pour choisir un prochain test-only update, mais pas pour déclarer la calibration finale du produit.

## 20. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
rg -n "candidate-a-current-v0|candidate-b-downward-attached|candidate-c-short-broad|candidate-d-wide-trapezoid|candidate-e-low-side-cast|directionX|directionY|lengthRatio|nearWidthRatio|farWidthRatio|anchorXRatio|anchorYRatio|opacity|colorHexRgb" packages/map_runtime/tool reports/shadows/v2
rg -n "Projected Building Shadow Candidate Matrix|Candidat C|Short broad|Wide trapezoid|languette|footprint|socle|banding|ShadowV2-36" reports/shadows/v2
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests non lancés :

```text
Aucun test lancé, conformément au prompt design-only.
Aucun fichier de code ou test n'a été modifié.
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text

```

Note : le rapport ShadowV2-37 est un fichier non suivi ; `git diff --stat` ne liste pas les fichiers non suivis.

## 22. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text

```

Note : le rapport ShadowV2-37 est un fichier non suivi ; `git diff --name-status` ne le liste pas.

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text

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
?? reports/shadows/v2/shadow_v2_37_projected_building_shadow_candidate_selection_design.md
```

Checklist finale :
- [x] Design-only respecté
- [x] Aucun fichier de production modifié
- [x] Aucun test créé/modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier map_runtime modifié
- [x] Aucun fichier map_editor modifié
- [x] Aucun fichier Selbrume modifié
- [x] Aucun generated modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Artifact Lot 36 audité
- [x] Candidat A analysé
- [x] Candidat B analysé
- [x] Candidat C analysé
- [x] Candidat D analysé
- [x] Candidat E analysé
- [x] Comparaison synthétique faite
- [x] Option recommandée unique
- [x] Plan ShadowV2-38 précis
- [x] Fichiers interdits au Lot 38 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
