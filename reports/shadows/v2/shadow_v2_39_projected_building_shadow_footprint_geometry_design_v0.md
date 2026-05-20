# ShadowV2-39 — Projected Building Shadow Footprint Geometry Design V0

## 1. Résumé exécutif

ShadowV2-39 est un design gate / audit-only.

Décision recommandée :

```text
Option recommandée : Footprint 4 points / skewed rectangle.
Modèle recommandé : ajouter un geometryMode au preset existant, avec un tuning footprint dédié.
Lot 40 recommandé : ShadowV2-40 — Projected Building Shadow Footprint Geometry Core V0.
```

Pourquoi :

- l'intention artistique demande une masse grise large et attachée, pas une projection depuis un anchor ;
- un quadrilatère footprint large et court correspond mieux à la référence Pokémon-like ;
- 4 points gardent l'impact minimal : `ProjectedBuildingShadowGeometry` accepte déjà exactement 4 points ;
- runtime et editor peuvent réutiliser `projectedPolygon` sans nouveau `shape kind` ;
- les bandes actuelles restent présentes, mais le banding a déjà été classé secondaire par rapport à la forme ;
- 6 points et alpha-mask seraient prématurés pour V0.

Footprint V0 recommandé :

```text
geometryMode: footprint
points: 4
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
appearance.opacity: 0.28
appearance.colorHexRgb: 606060
```

Micro-fixture calculée :

```text
frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)
```

## 2. Objectif du lot

Objectif exact :

```text
Définir précisément un nouveau mode de géométrie ShadowV2 footprint-like,
capable de produire une ombre large, simple, dure, grise et attachée au bâtiment,
plus proche des références Pokémon-like,
sans modifier le renderer,
sans modifier le painter editor,
sans modifier map_core dans ce lot,
sans créer de nouvelle image,
sans baseline,
sans Selbrume.
```

Question tranchée :

```text
Comment représenter une ombre de bâtiment comme une emprise au sol / footprint,
plutôt que comme une projection trapézoïdale directionnelle depuis un anchor ?
```

Réponse :

```text
Utiliser un nouveau mode footprint dans le preset,
résolu en quadrilatère large et court depuis les bounds visuels du bâtiment.
Le renderer/painter restent sur projectedPolygon.
```

## 3. Rappel ShadowV2-34 à ShadowV2-38

ShadowV2-34 :

```text
Premier artifact micro.
Le rendu était techniquement valide, mais l'ombre lisait comme une languette diagonale.
```

ShadowV2-35 :

```text
Diagnostic principal : forme / direction / anchor / largeur.
Diagnostic secondaire : banding.
```

ShadowV2-36 :

```text
Matrice A/B/C/D/E de candidats trapézoïdaux.
Candidate C était le meilleur candidat dans le modèle actuel.
```

ShadowV2-37 :

```text
Candidate C proposée comme nouvelle calibration test-only.
Décision ensuite remise en cause : C reste une projection directionnelle.
```

ShadowV2-38 :

```text
Décision canonique :
- ne pas propager Candidate C maintenant ;
- concevoir Footprint Geometry V0 ;
- garder Candidate C comme benchmark/fallback du mode directionnel.
```

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

Fichiers préexistants non liés au Lot 39 :

```text
reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

Interprétation :

```text
Le rapport Lot 38 était déjà non suivi avant ShadowV2-39.
Il est documenté comme préexistant et n'est pas modifié par ce lot.
```

Fichiers créés par ShadowV2-39 :

```text
reports/shadows/v2/shadow_v2_39_projected_building_shadow_footprint_geometry_design_v0.md
```

Fichiers modifiés par ShadowV2-39 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-39 :

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

Sortie utile :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Décision :

```text
Le lot est un design gate.
Le seul fichier créé est le rapport demandé.
Aucune implémentation, aucun test, aucune image, aucune baseline et aucun fichier Selbrume ne sont créés.
```

Compétences / rituels utilisés :

- `superpowers:using-superpowers` ;
- `superpowers:brainstorming` ;
- `karpathy-guidelines` ;
- `superpowers:verification-before-completion`.

## 6. Fichiers audités

Modèle / géométrie :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Renderer / painter :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
```

Historique design :

```text
reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
reports/shadows/v2/shadow_v2_37_projected_building_shadow_candidate_selection_design.md
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

Commandes d'audit exécutées :

```bash
rg -n "ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAppearance|ProjectedShadowAnchor|ProjectedShadowOffset|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|resolveProjectedBuildingShadowGeometry|lengthRatio|nearWidthRatio|farWidthRatio|anchor|localOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2
rg -n "ShadowRuntimeRenderer|ShadowRuntimeRenderInstruction|ShadowRuntimeShapeKind.projectedPolygon|polygonPoints|drawPath|renderCollectionPass|paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewShapeKind.projectedPolygon|createProjectedStaticShadowOpacityBands|polygonPoints.length" packages/map_runtime/lib packages/map_editor/lib packages/map_core/lib packages/map_runtime/test packages/map_editor/test
rg -n "candidate-c-short-broad|Short broad|Footprint Geometry|footprint|silhouette|alpha mask|author-defined|projected building shadow|languette|socle" reports/shadows/v2 packages/map_runtime/tool packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib
```

Lectures ciblées exécutées :

```bash
sed -n '1,260p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '1,180p' packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
sed -n '1,220p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,210p' packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
sed -n '1,180p' packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
sed -n '220,290p' packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
sed -n '1,260p' reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

## 7. Audit modèle ShadowV2 actuel

Types actuels :

```text
ProjectedShadowTimeOfDayMode
ProjectedShadowDirection
ProjectedShadowAnchor
ProjectedShadowOffset
ProjectedShadowShapeTuning
ProjectedShadowAppearance
ProjectBuildingShadowPreset
ProjectElementProjectedBuildingShadowConfig
ProjectedBuildingShadowPoint
ProjectedBuildingShadowGeometry
```

Validations actuelles utiles :

- `ProjectedShadowDirection` refuse le vecteur zéro et les valeurs non finies.
- `ProjectedShadowAnchor` valide `xRatio` et `yRatio` entre `0` et `1`.
- `ProjectedShadowOffset` valide des valeurs finies.
- `ProjectedShadowShapeTuning` valide `lengthRatio >= 0`, `nearWidthRatio > 0`, `farWidthRatio > 0`.
- `ProjectedShadowAppearance` valide `opacity` entre `0` et `1` et normalise `colorHexRgb`.
- `ProjectedBuildingShadowGeometry` impose exactement 4 points.

Invariant actuel :

```text
ProjectedBuildingShadowGeometry.points must contain exactly 4 points
```

Formule directionnelle actuelle :

```text
direction = preset.direction.normalized
perpendicular = (-direction.y, direction.x)
anchorWorldX = metrics.left + metrics.visualWidth * anchor.xRatio + localOffset.x
anchorWorldY = metrics.top + metrics.visualHeight * anchor.yRatio + localOffset.y
length = metrics.visualHeight * lengthRatio
nearHalfWidth = metrics.visualWidth * nearWidthRatio / 2
farHalfWidth = metrics.visualWidth * farWidthRatio / 2
farCenter = anchor + direction * length
points = nearLeft, nearRight, farRight, farLeft
```

Ce qui peut être réutilisé :

- `ProjectedShadowAppearance` ;
- `ProjectBuildingShadowPreset` comme conteneur de preset ;
- `ProjectElementProjectedBuildingShadowConfig.enabled` ;
- `ProjectElementProjectedBuildingShadowConfig.presetId` ;
- `ProjectElementProjectedBuildingShadowConfig.localOffset` comme translation finale ;
- `ProjectedBuildingShadowGeometry` si Footprint V0 reste à 4 points ;
- pipeline runtime/editor existant qui consomme des polygons.

Ce qui doit être étendu :

- une façon de distinguer `directional` et `footprint` ;
- un tuning footprint dédié ;
- la résolution pure `resolveProjectedBuildingShadowGeometry(...)` ;
- les tests map_core de validation et de points.

Ce qui ne doit pas être réinterprété :

```text
anchor ne doit pas devenir silencieusement attachYRatio.
Cela brouillerait le vocabulaire authoring.
```

Position recommandée :

```text
Pour Footprint V0, anchor reste un champ du config actuel mais devient directional-only.
localOffset reste commun et translate le footprint résolu.
Le Lot 40 devra documenter ce comportement dans les tests.
```

Risques de compatibilité :

- ajout de champs au preset peut impacter codecs JSON existants ;
- si `geometryMode` est ajouté sans default `directional`, les fixtures existantes peuvent casser ;
- si `footprint` est optionnel sans règle stricte, les presets peuvent devenir ambigus ;
- si 6 points sont retenus, l'invariant map_core doit changer.

## 8. Audit renderer / painter

Runtime :

```text
ShadowRuntimeRenderer.renderCollectionPass(...)
ShadowRuntimeShapeKind.projectedPolygon
ShadowRuntimeRenderInstruction.polygonPoints
```

Comportement runtime :

- `projectedPolygon` avec 4 points déclenche les bandes.
- `projectedPolygon` avec un nombre de points différent de 4 dessine un path rempli plat.
- `ShadowRuntimeRenderInstruction` accepte `projectedPolygon` avec au moins 3 points non dégénérés.
- `shadowRuntimePaintForInstruction` utilise `PaintingStyle.fill`.
- `isAntiAlias = false`.

Editor :

```text
paintEditorStaticShadowPreviewInstructions(...)
EditorStaticShadowPreviewShapeKind.projectedPolygon
```

Comportement editor :

- 4 points déclenchent les bandes ;
- non-4 points dessinent un path plat ;
- `isAntiAlias = false` ;
- couleur/opacité viennent de l'instruction preview.

Banding actuel :

```text
defaultProjectedStaticShadowFillBandCount = 7
defaultProjectedStaticShadowNearOpacityScale = 1.0
defaultProjectedStaticShadowFarOpacityScale = 0.52
```

Réutilisation de `projectedPolygon` :

```text
Oui. Footprint V0 peut produire un projectedPolygon sans nouveau renderer shape kind.
```

4 points ou plus de 4 points ?

```text
Recommandation : 4 points en V0.
```

Pourquoi 4 points :

- impact minimal ;
- conserve l'invariant map_core actuel ;
- évite de modifier renderer/painter ;
- rend le Lot 40 core-only réaliste ;
- le problème principal est la forme, pas encore le banding.

Pourquoi ne pas choisir 6 points maintenant :

- changer l'invariant map_core pour contourner les bandes serait une décision de rendu déguisée ;
- le renderer/painter dessinent non-4 en fill plat, mais ce comportement n'a pas été conçu comme mode artistique footprint ;
- plus de points demanderaient plus de validations et tests ;
- cela mélange géométrie footprint et décision banding.

Nouveau shape kind :

```text
Prématuré et inutile en V0.
Le mode géométrique doit changer côté modèle/résolution,
pas côté renderer/painter.
```

## 9. Familles de géométrie étudiées

### Option A — Footprint 4 points / parallelogram

Principe :

```text
Quadrilatère large et court,
front edge attaché au pied du bâtiment,
rear edge légèrement plus bas et décalé.
```

Forces :

- impact minimal ;
- compatible avec l'invariant 4 points ;
- compatible runtime/editor ;
- simple à tester ;
- proche de l'intention footprint.

Faiblesses :

- garde les bandes actuelles ;
- peut rester trop géométrique si ratios mal choisis ;
- ne représente pas une silhouette de toit.

Décision :

```text
Retenue.
```

### Option B — Footprint 6 points / polygon plus naturel

Forces :

- plus expressif ;
- peut éviter le banding 4-points actuel ;
- permet une masse moins rectangulaire.

Faiblesses :

- nécessite de lever l'invariant 4 points dans map_core ;
- change implicitement le comportement renderer/painter vers fill plat ;
- plus lourd à valider ;
- prématuré avant un V0 simple.

Décision :

```text
Rejetée pour V0.
À réexaminer si le 4-points reste trop bandé ou trop rigide.
```

### Option C — Footprint rectangle axis-aligned

Forces :

- très simple ;
- stable ;
- facile à calculer ;
- proche d'un socle.

Faiblesses :

- trop statique ;
- risque de plaque ;
- ne porte aucune direction bas-droite ;
- moins proche des références où l'ombre a souvent un léger décalage.

Décision :

```text
Rejetée comme option principale.
```

### Option D — Footprint skewed rectangle

Forces :

- garde la simplicité du rectangle ;
- ajoute une direction bas-droite discrète ;
- reste attaché au bâtiment ;
- produit 4 points ;
- bon compromis V0.

Faiblesses :

- peut encore être trop propre / mécanique ;
- banding présent si 4 points.

Décision :

```text
Retenue comme forme exacte de Footprint V0.
```

### Option E — Alpha mask / silhouette projection

Forces :

- correspond littéralement à “reprendre la forme de l'objet” ;
- pourrait être excellent avec assets propres.

Faiblesses :

- dépend des images ;
- coûteux ;
- fragile ;
- trop détaillé pour pixel-art ;
- hors V0 ;
- demande runtime/editor/asset pipeline.

Décision :

```text
Rejetée pour V0.
```

### Option F — Author-defined polygon

Forces :

- contrôle artistique maximal ;
- probablement bon long terme.

Faiblesses :

- demande UI authoring ;
- demande stockage de points ;
- trop manuel pour le prochain lot ;
- trop large pour une étape core-only.

Décision :

```text
Rejetée pour V0.
```

## 10. Modèle de données recommandé

Options comparées :

```text
A — Ajouter geometryMode au preset existant
B — Créer une union de tuning
C — Ajouter uniquement des champs footprint optionnels
D — Créer un nouveau preset séparé
```

Option recommandée :

```text
Option modèle A — Ajouter geometryMode au preset existant,
avec un tuning footprint optionnel mais strictement gouverné par geometryMode.
```

Structure conceptuelle :

```dart
enum ProjectedBuildingShadowGeometryMode {
  directional,
  footprint,
}

final class ProjectedShadowFootprintTuning {
  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
}
```

Preset conceptuel :

```dart
ProjectBuildingShadowPreset(
  id: 'pokemon-building-shadow-footprint-v0',
  name: 'Pokemon-like footprint building shadow V0',
  geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
  shape: ProjectedShadowShapeTuning(...), // conservé pour compat directional
  footprint: ProjectedShadowFootprintTuning(...),
  appearance: ProjectedShadowAppearance(...),
  timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
)
```

Règles recommandées :

- `geometryMode` default `directional` pour compatibilité.
- `shape` reste le tuning directional existant.
- `footprint` est requis quand `geometryMode == footprint`.
- `footprint` est ignoré ou refusé quand `geometryMode == directional`; le Lot 40 devra trancher entre tolérance et validation stricte.
- `appearance` reste commun.
- `timeOfDayMode` reste présent mais n'influence pas Footprint V0.

Pourquoi pas option B :

```text
Une union sealed serait propre, mais trop lourde pour l'étape.
Elle augmenterait le coût modèle / JSON / tests.
```

Pourquoi pas option C :

```text
Des champs footprint optionnels sans geometryMode créeraient une ambiguïté.
```

Pourquoi pas option D :

```text
Un preset séparé dupliquerait catalogues, codecs et authoring futur.
```

## 11. Paramètres Footprint V0 recommandés

Paramètres nécessaires :

```text
geometryMode
attachYRatio
frontWidthRatio
rearWidthRatio
depthRatio
skewXRatio
opacity
colorHexRgb
```

Paramètres existants conservés :

```text
enabled
presetId
localOffset
appearance.opacity
appearance.colorHexRgb
```

Paramètres à ne pas ajouter en V0 :

```text
offsetXRatio
offsetYRatio
frontInsetRatio
rearInsetRatio
widthRatio unique
alphaMask
authorPoints
```

Raisons :

- `skewXRatio` suffit pour une direction horizontale discrète ;
- `depthRatio` suffit pour l'extension verticale ;
- `localOffset` existe déjà pour une correction pixel ;
- `frontInsetRatio` / `rearInsetRatio` rendraient l'authoring trop riche ;
- un `widthRatio` unique ne contrôle pas assez le léger élargissement arrière.

Validations recommandées :

```text
attachYRatio: 0.0 <= value <= 1.0
frontWidthRatio: 0.1 <= value <= 2.0
rearWidthRatio: 0.1 <= value <= 2.0
depthRatio: 0.01 <= value <= 1.0
skewXRatio: -0.5 <= value <= 0.5
opacity: 0.0 <= value <= 1.0
colorHexRgb: six hex digits, no '#'
```

Valeurs par défaut recommandées :

```text
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Statut de `anchor` :

```text
Directional-only en V0 footprint.
Ne pas le réinterpréter.
```

Statut de `localOffset` :

```text
Commun aux deux modes.
Il translate tous les points résolus après calcul.
```

## 12. Formule Footprint V0

Entrées :

```text
metrics.left
metrics.top
metrics.visualWidth
metrics.visualHeight
localOffset.x
localOffset.y
attachYRatio
frontWidthRatio
rearWidthRatio
depthRatio
skewXRatio
```

Formule :

```text
centerX = metrics.left + metrics.visualWidth * 0.5 + localOffset.x
frontY = metrics.top + metrics.visualHeight * attachYRatio + localOffset.y

frontWidth = metrics.visualWidth * frontWidthRatio
rearWidth = metrics.visualWidth * rearWidthRatio
depth = metrics.visualHeight * depthRatio

rearCenterX = centerX + metrics.visualWidth * skewXRatio
rearY = frontY + depth

frontLeft.x = centerX - frontWidth / 2
frontLeft.y = frontY

frontRight.x = centerX + frontWidth / 2
frontRight.y = frontY

rearRight.x = rearCenterX + rearWidth / 2
rearRight.y = rearY

rearLeft.x = rearCenterX - rearWidth / 2
rearLeft.y = rearY
```

Ordre des points :

```text
frontLeft
frontRight
rearRight
rearLeft
```

Pourquoi cet ordre :

- cohérent avec l'ordre actuel nearLeft / nearRight / farRight / farLeft ;
- polygon non dégénéré ;
- compatible avec le renderer actuel ;
- les bandes, si appliquées, se propagent de front vers rear.

Bounds :

```text
left = min(point.x)
top = min(point.y)
right = max(point.x)
bottom = max(point.y)
width = right - left
height = bottom - top
```

Effet visuel :

- front edge part du bas du bâtiment ;
- rear edge descend peu ;
- rear edge est légèrement plus large ;
- rear edge est légèrement décalé vers la droite ;
- la forme lit comme une emprise au sol plutôt qu'une languette.

Comment éviter de recouvrir trop le bâtiment :

- `attachYRatio` reste bas mais inférieur au bas exact (`0.86`) ;
- le bâtiment est dessiné au-dessus au runtime/editor ;
- la partie avant est cachée par le sprite, ce qui renforce l'attachement.

Comment éviter la plaque grise :

- `depthRatio` reste court (`0.28`) ;
- opacity abaissée à `0.28` ;
- pas de largeur supérieure à `1.20` en default ;
- skew discret (`0.10`) seulement.

## 13. Micro-fixture calculée

Micro-fixture :

```text
metrics.left = 32
metrics.top = 64
metrics.visualWidth = 64
metrics.visualHeight = 96
localOffset = (0, 0)
```

Default Footprint V0 :

```text
geometryMode: footprint
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Calculs intermédiaires :

```text
centerX = 64.00
frontY = 146.56
frontWidth = 70.40
rearWidth = 76.80
depth = 26.88
rearCenterX = 70.40
rearY = 173.44
```

Points attendus :

```text
point[0] frontLeft  = (28.80, 146.56)
point[1] frontRight = (99.20, 146.56)
point[2] rearRight  = (108.80, 173.44)
point[3] rearLeft   = (32.00, 173.44)
```

Bounds attendus :

```text
left = 28.80
top = 146.56
right = 108.80
bottom = 173.44
width = 80.00
height = 26.88
```

Commande de calcul utilisée :

```text
ctx_execute JavaScript, calcul pur en mémoire, aucune écriture fichier.
```

## 14. Relation avec Candidate C

Statut recommandé :

```text
Candidate C devient le meilleur benchmark du mode directional.
Footprint V0 devient la direction recommandée pour les bâtiments.
```

Candidate C n'est pas abandonnée :

- utile comme comparaison ;
- utile si un asset a vraiment besoin d'une projection directionnelle ;
- utile pour vérifier que Footprint V0 est une amélioration réelle.

Candidate C ne doit pas être propagée maintenant :

- elle reste un trapèze directionnel ;
- elle ne part pas de l'emprise au sol ;
- elle a été choisie comme moins mauvaise dans une matrice limitée ;
- l'utilisateur a explicitement demandé un pivot de design.

## 15. Impact package par package

### map_core

Impact probable du Lot 40 :

- ajouter `ProjectedBuildingShadowGeometryMode` ;
- ajouter `ProjectedShadowFootprintTuning` ;
- ajouter `geometryMode` et `footprint` au preset ;
- préserver le default `directional` ;
- étendre `resolveProjectedBuildingShadowGeometry(...)` ;
- conserver `ProjectedBuildingShadowGeometry` à 4 points ;
- ajouter tests value object / validation ;
- ajouter test micro-fixture footprint avec points explicites.

Risque :

```text
Les codecs JSON existants peuvent devoir être mis à jour dans map_core si le modèle change.
Le Lot 40 doit garder cela dans map_core uniquement et ne pas modifier les données réelles.
```

### map_runtime

Impact probable du Lot 40 :

```text
Aucun si Lot 40 reste core-only.
```

Impact futur après Lot 40 :

- adapter runtime V2 si les presets footprint apparaissent dans les données ;
- vérifier que `projectedPolygon` reçoit les points footprint ;
- conserver `ShadowRuntimeRenderer` inchangé ;
- ajuster visual POC plus tard.

### map_editor

Impact probable du Lot 40 :

```text
Aucun si Lot 40 reste core-only.
```

Impact futur après Lot 40 :

- adapter builder preview pour résoudre Footprint V0 ;
- garder painter inchangé ;
- ajouter test editor preview footprint ;
- cacher `anchor` dans une UI future si mode footprint.

### JSON / manifest

À analyser au Lot 40 :

- compatibilité des presets existants sans `geometryMode` ;
- encodage/decoding de `footprint` ;
- règles si `geometryMode=footprint` sans `footprint` ;
- règles si `geometryMode=directional` avec `footprint`.

Non-objectifs :

- modifier Selbrume ;
- modifier project.json réel ;
- créer migration ;
- changer manifest réel.

## 16. Option recommandée

Option recommandée :

```text
Footprint 4 points / skewed rectangle + geometryMode sur preset existant.
```

Design Footprint V0 recommandé :

```text
geometry mode : ProjectedBuildingShadowGeometryMode.footprint
nombre de points : 4
paramètres :
- attachYRatio
- frontWidthRatio
- rearWidthRatio
- depthRatio
- skewXRatio
- appearance.opacity
- appearance.colorHexRgb
valeurs par défaut :
- attachYRatio: 0.86
- frontWidthRatio: 1.10
- rearWidthRatio: 1.20
- depthRatio: 0.28
- skewXRatio: 0.10
- opacity: 0.28
- colorHexRgb: 606060
formule : front edge attachée, rear edge courte, plus large, skew bas-droite discret
ordre des points : frontLeft, frontRight, rearRight, rearLeft
relation renderer : réutilise ShadowRuntimeShapeKind.projectedPolygon
relation painter : réutilise EditorStaticShadowPreviewShapeKind.projectedPolygon
relation Candidate C : benchmark/fallback directional
```

Pourquoi :

- plus proche de l'intention utilisateur ;
- plus attaché au bâtiment ;
- conserve une surface large et courte ;
- ne change pas renderer/painter ;
- ne demande pas de lever l'invariant 4 points ;
- limite le scope du futur Lot 40.

Pourquoi les autres options sont rejetées :

- 6 points : trop tôt, change l'invariant et contourne le banding par hasard.
- rectangle axis-aligned : trop statique, risque de plaque.
- alpha mask : trop complexe, asset-dependent.
- author-defined polygon : trop UI / authoring.
- nouveau preset séparé : duplication inutile.
- union sealed : propre mais trop lourde pour V0.

Lot 40 doit faire :

- implémenter uniquement la géométrie pure Footprint V0 dans `map_core` ;
- ajouter les value objects / validations nécessaires ;
- ajouter ou ajuster tests `map_core` ciblés ;
- calculer les points micro-fixture explicitement ;
- préserver la compatibilité directionnelle.

Lot 40 ne doit pas faire :

- modifier runtime/editor ;
- modifier renderer/painter ;
- modifier Selbrume ;
- créer image ;
- créer baseline ;
- créer UI authoring ;
- traiter alpha mask ;
- traiter author-defined polygon.

## 17. Plan précis du Lot 40

Nom recommandé :

```text
ShadowV2-40 — Projected Building Shadow Footprint Geometry Core V0
```

Objectif :

```text
Ajouter le modèle et la résolution pure Footprint V0 dans map_core uniquement,
avec tests ciblés,
sans runtime/editor,
sans renderer/painter,
sans Selbrume,
sans image.
```

Fichiers probablement à modifier :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Fichiers potentiellement à modifier si les tests/exports l'exigent :

```text
packages/map_core/lib/map_core.dart
packages/map_core/test/shadow_v2/projected_building_shadow_value_objects_test.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Fichier rapport à créer :

```text
reports/shadows/v2/shadow_v2_40_projected_building_shadow_footprint_geometry_core_v0.md
```

Tests à ajouter/modifier :

- value object footprint tuning accepte les defaults ;
- footprint tuning refuse ratios invalides ;
- preset footprint exige un tuning footprint ;
- directional reste compatible ;
- micro-fixture produit :
  - `(28.80, 146.56)`
  - `(99.20, 146.56)`
  - `(108.80, 173.44)`
  - `(32.00, 173.44)`
- `opacity == 0.28` ;
- `colorHexRgb == '606060'`.

Commandes à lancer :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart test test/shadow_v2
cd packages/map_core && dart analyze test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Critères de validation :

- aucun fichier runtime/editor modifié ;
- aucun renderer/painter modifié ;
- aucun Selbrume ;
- aucun screenshot/baseline ;
- tests map_core ciblés verts ;
- `git diff --check` propre ;
- status final conforme au scope.

## 18. Fichiers explicitement interdits au Lot 40

Interdits hors map_core :

```text
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Interdits spécifiques :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

Créations interdites :

```text
screenshot
baseline
image
fixture Selbrume
UI authoring
shader
blur
alpha mask runtime
author-defined polygon UI
```

## 19. Risques / réserves

Risque principal :

```text
Footprint 4 points garde les bandes actuelles.
Si le résultat visuel reste laid, il faudra un lot banding séparé.
```

Risque modèle :

```text
Ajouter geometryMode au preset impose une discipline codec/compat.
Le default directional est indispensable.
```

Risque authoring :

```text
Anchor devient directional-only.
Il faudra éviter une UI qui expose anchor comme réglage footprint.
```

Risque artistique :

```text
Les defaults peuvent encore être trop plaque ou trop bas selon assets.
Un artifact footprint comparatif pourra être nécessaire après le core.
```

## 20. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Un seul rapport Markdown est créé.
```

Le Footprint V0 recommandé est-il réellement plus proche de l'intention utilisateur ?

```text
Oui. Il part du pied et des bounds du bâtiment, pas d'un anchor projeté.
```

Le modèle proposé est-il trop complexe ?

```text
Non. Cinq paramètres footprint suffisent.
Les paramètres plus riches sont repoussés.
```

Les paramètres sont-ils authorables ?

```text
Oui. Ils correspondent à attache, largeur avant, largeur arrière, profondeur, skew.
```

La formule est-elle suffisamment précise pour être implémentée ?

```text
Oui. Points, ordre, bounds et micro-fixture sont explicites.
```

Le choix 4 points / 6 points est-il justifié ?

```text
Oui. 4 points minimise l'impact et évite de mélanger géométrie avec décision banding.
```

Le plan Lot 40 est-il strictement borné ?

```text
Oui. map_core uniquement, tests ciblés, pas runtime/editor.
```

Le plan évite-t-il Selbrume / baseline / production inutile ?

```text
Oui. Selbrume, images, baseline, runtime/editor et painter sont interdits.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Il inclut status initial, audits, formule, calcul micro-fixture, impacts, plan et sorties git finales.
```

## 21. Regard critique sur le prompt

Point fort :

```text
Le prompt force à résoudre la question conceptuelle avant de coder.
C'est exactement ce qu'il fallait après la matrice trapézoïdale.
```

Point de vigilance :

```text
"Silhouette" peut attirer vers alpha-mask.
Le V0 recommandé reste volontairement footprint-like, pas silhouette pixel-perfect.
```

Point de scope :

```text
Le prochain lot core-only devra être très strict.
Si les codecs sont touchés, cela doit rester map_core et test-only autour des contrats.
```

## 22. Commandes lancées

Commandes obligatoires :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

rg -n "ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAppearance|ProjectedShadowAnchor|ProjectedShadowOffset|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|resolveProjectedBuildingShadowGeometry|lengthRatio|nearWidthRatio|farWidthRatio|anchor|localOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2

rg -n "ShadowRuntimeRenderer|ShadowRuntimeRenderInstruction|ShadowRuntimeShapeKind.projectedPolygon|polygonPoints|drawPath|renderCollectionPass|paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewShapeKind.projectedPolygon|createProjectedStaticShadowOpacityBands|polygonPoints.length" packages/map_runtime/lib packages/map_editor/lib packages/map_core/lib packages/map_runtime/test packages/map_editor/test

rg -n "candidate-c-short-broad|Short broad|Footprint Geometry|footprint|silhouette|alpha mask|author-defined|projected building shadow|languette|socle" reports/shadows/v2 packages/map_runtime/tool packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib

git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Commandes complémentaires :

```bash
sed -n '1,260p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '1,180p' packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
sed -n '1,220p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,210p' packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
sed -n '1,180p' packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
sed -n '220,290p' packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
sed -n '1,260p' reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

Calcul micro-fixture :

```text
ctx_execute JavaScript :
- metrics et tuning Footprint V0 ;
- calcul des 4 points ;
- calcul des bounds ;
- aucune écriture fichier.
```

Tests lancés :

```text
Aucun. Le lot est design-only et aucun fichier de code/test n'a été modifié.
```

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text

```

Interprétation :

```text
Aucun tracked diff.
Les rapports Lot 38 et Lot 39 sont non suivis et apparaissent dans git status,
pas dans git diff --stat.
```

## 24. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text

```

Interprétation :

```text
Aucun fichier suivi modifié, supprimé ou ajouté dans l'index.
```

## 25. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text

```

Interprétation :

```text
git diff --check est propre.
```

## 26. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
?? reports/shadows/v2/shadow_v2_39_projected_building_shadow_footprint_geometry_design_v0.md
```

Confirmation du scope :

```text
Conforme :
- le rapport Lot 38 était préexistant avant ShadowV2-39 ;
- le seul fichier créé par ShadowV2-39 est le rapport Lot 39 ;
- aucun fichier Dart, test, production, Selbrume, screenshot ou baseline n'est créé ou modifié.
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
- [x] Modèle ShadowV2 actuel audité
- [x] Renderer/painter audités
- [x] Familles de géométrie comparées
- [x] Modèle de données recommandé
- [x] Paramètres Footprint V0 recommandés
- [x] Formule Footprint V0 explicite
- [x] Micro-fixture calculée
- [x] Candidate C positionnée clairement
- [x] Impact package par package documenté
- [x] Option recommandée unique
- [x] Plan ShadowV2-40 précis
- [x] Fichiers interdits au Lot 40 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
