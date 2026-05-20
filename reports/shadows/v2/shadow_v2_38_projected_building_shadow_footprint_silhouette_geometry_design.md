# ShadowV2-38 — Projected Building Shadow Footprint / Silhouette Geometry Design Gate

## 1. Résumé exécutif

ShadowV2-38 est un design gate / audit-only.

Décision recommandée :

```text
Option recommandée : Option B — Concevoir un nouveau mode Footprint Geometry V0.
Décision : ne pas propager Candidate C comme calibration finale maintenant.
```

Pourquoi :

- Candidate C est le meilleur candidat dans le modèle trapézoïdal actuel, mais il reste une projection directionnelle.
- L'intention artistique demande une masse grise large, attachée au bâtiment, proche d'une emprise au sol.
- Le modèle actuel `direction + lengthRatio + nearWidthRatio + farWidthRatio` produit naturellement une bande orientée depuis un anchor, pas une silhouette de bâtiment.
- Le renderer runtime et le painter editor savent déjà dessiner un `projectedPolygon`; un Footprint V0 peut probablement réutiliser ce rendu en changeant les points produits.
- La piste silhouette / alpha mask est trop lourde pour V0.

Lot 39 recommandé :

```text
ShadowV2-39 — Projected Building Shadow Footprint Geometry Design V0
```

Objectif : définir précisément un nouveau mode footprint-like simple, ses paramètres, ses invariants et son plan d'implémentation, sans coder encore.

## 2. Objectif du lot

Objectif exact :

```text
Reprendre le problème des ombres projetées de bâtiments à partir de l'intention artistique réelle :
une ombre Pokémon-like large, attachée au bâtiment, proche d'un footprint / d'une silhouette au sol,
et non une simple languette trapézoïdale directionnelle.
```

Question tranchée :

```text
Le modèle ShadowV2 actuel basé sur direction + lengthRatio + nearWidthRatio + farWidthRatio suffit-il encore,
ou faut-il introduire un nouveau mode de géométrie footprint-like / silhouette-like ?
```

Réponse :

```text
Le modèle actuel ne suffit pas comme direction produit principale.
Il reste utile comme mode directionnel / fallback, mais la prochaine conception doit porter sur une géométrie footprint-like.
```

Ce lot ne modifie aucun code, aucun test, aucun preset, aucun renderer, aucun painter, aucune image, aucune baseline et aucune donnée Selbrume.

## 3. Rappel ShadowV2-34 à ShadowV2-37

ShadowV2-34 :

```text
Artifact micro :
- image 320x224 ;
- panel shadow-only ;
- panel shadow + bâtiment simple ;
- rendu via ShadowRuntimeRenderer.renderCollectionPass(...) ;
- pas de baseline ;
- pas de Selbrume.
```

Constat humain après ShadowV2-34 :

```text
Le rendu marche techniquement, mais l'ombre V0 ressemble à une languette diagonale détachée.
```

ShadowV2-35 :

```text
Diagnostic principal : forme / direction / anchor / largeur.
Diagnostic secondaire : banding hard-edge.
Recommandation : comparer plusieurs presets avant de toucher au renderer ou à la géométrie.
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
- ligne basse shadow + building.
```

ShadowV2-37 :

```text
Candidate C est retenue comme meilleur candidat trapézoïdal.
Le rapport recommande de la propager en test-only.
```

Décision produit réévaluée par ShadowV2-38 :

```text
Candidate C est meilleure que A dans la famille trapézoïdale,
mais cela ne prouve pas que la famille trapézoïdale est la bonne cible artistique.
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
Le worktree était propre avant ShadowV2-38.
Les artifacts et rapports ShadowV2-34 à ShadowV2-37 étaient déjà présents dans l'état local de référence.
```

Fichiers préexistants non liés au Lot 38 :

```text
Aucun fichier modifié ou non suivi signalé par git status initial.
```

Fichiers créés par ShadowV2-38 :

```text
reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

Fichiers modifiés par ShadowV2-38 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-38 :

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
Le Lot 38 est explicitement un design gate / audit-only.
Le seul fichier produit est le rapport demandé.
Aucune spec séparée, aucun plan de code, aucun fichier Dart et aucune image ne sont créés.
```

Compétences / rituels utilisés :

- `superpowers:using-superpowers` ;
- `superpowers:brainstorming`, adapté au design gate déjà cadré par le prompt ;
- `karpathy-guidelines`, pour éviter de choisir Candidate C par inertie ou de proposer une refonte excessive ;
- `superpowers:verification-before-completion`, pour vérifier le scope final avant conclusion.

## 6. Fichiers audités

Fichiers de géométrie / modèle :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Fichiers renderer / painter :

```text
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
```

Rapports et artifacts :

```text
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
reports/shadows/v2/shadow_v2_37_projected_building_shadow_candidate_selection_design.md
```

Commandes d'audit obligatoires exécutées :

```bash
rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAnchor|ProjectedShadowOffset|lengthRatio|nearWidthRatio|farWidthRatio|anchor|localOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2
rg -n "ShadowRuntimeRenderer|projectedPolygon|drawPath|createProjectedStaticShadowOpacityBands|isAntiAlias|paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewShapeKind.projectedPolygon" packages/map_runtime/lib packages/map_editor/lib packages/map_core/lib packages/map_runtime/test packages/map_editor/test
rg -n "candidate-c-short-broad|Short broad|footprint|silhouette|shape|languette|socle|Pokemon-like|Pokémon-like|projected building shadow" reports/shadows/v2 packages/map_runtime/tool packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib
file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
```

Métadonnées de l'artifact Lot 36 :

```text
file : PNG image data, 800 x 480, 8-bit/color RGBA, non-interlaced
ls   : -rw-r--r--@ 1 karim  staff    10K May 21 00:02 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
sha  : 4d008034024bf201fa63ce4ee0cb5fc19003c02764479fb9791d2679f97c3f5a
```

Observation visuelle locale :

```text
L'image affiche bien les colonnes A/B/C/D/E, une ligne shadow-only et une ligne shadow+building.
A et E restent très latérales.
B et C réduisent l'effet languette.
C est le meilleur compromis dans le modèle testé, mais reste un trapèze projeté.
D est plus massif, mais commence à lire comme une plaque.
```

## 7. Audit du modèle trapézoïdal actuel

Le modèle disponible dans `projected_building_shadow.dart` expose actuellement :

```text
ProjectedShadowDirection(x, y)
ProjectedShadowShapeTuning(lengthRatio, nearWidthRatio, farWidthRatio)
ProjectedShadowAppearance(opacity, colorHexRgb)
ProjectedShadowTimeOfDayMode(fixed, followsSun)
ProjectedShadowAnchor(xRatio, yRatio)
ProjectedShadowOffset(x, y)
ProjectBuildingShadowPreset(...)
ProjectElementProjectedBuildingShadowConfig(...)
```

La géométrie est résolue par :

```text
resolveProjectedBuildingShadowGeometry(...)
```

Formule actuelle :

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

Invariant actuel :

```text
ProjectedBuildingShadowGeometry.points must contain exactly 4 points.
```

Ce que le modèle permet :

- une projection directionnelle simple ;
- un trapèze court ou long ;
- une largeur proche et une largeur lointaine indépendantes ;
- un anchor déplacé dans le rectangle visuel du bâtiment ;
- un offset local ;
- une couleur et une opacité authorées ;
- une sortie déjà compatible runtime/editor via `projectedPolygon`.

Ce que le modèle ne permet pas bien :

- générer une masse qui part directement de l'emprise au sol complète ;
- exprimer une ombre attachée à la base du bâtiment plutôt qu'à un segment construit autour d'un anchor ;
- produire une silhouette large et stable indépendante d'une direction dominante ;
- représenter un footprint rectangulaire / parallélogramme avec paramètres dédiés ;
- produire une silhouette alpha ou une forme asset-specific ;
- choisir entre plusieurs familles de géométrie dans le preset.

Pourquoi il produit facilement des languettes :

```text
La forme est définie par un anchor unique, une direction et deux largeurs.
Même avec nearWidthRatio > 1, la lecture reste celle d'un segment projeté vers une direction.
Plus la direction est latérale, plus le polygone ressemble à une bande détachée.
Plus la longueur augmente, plus l'effet "ruban" domine.
```

Pourquoi Candidate C améliore sans résoudre :

```text
Candidate C réduit lengthRatio à 0.24, élargit nearWidthRatio à 1.15,
garde farWidthRatio proche à 1.05, baisse opacity à 0.28 et oriente davantage vers le bas.
Elle donne donc une masse plus courte et plus socle.
Mais elle reste générée par farCenter = anchor + direction * length.
Elle ne part pas d'une notion d'emprise au sol, de pied de bâtiment ou de silhouette.
```

Conclusion :

```text
Le modèle actuel peut améliorer une ombre directionnelle.
Il ne doit plus être considéré comme suffisant pour l'intention footprint / silhouette.
```

## 8. Audit renderer / painter existants

Runtime :

```text
ShadowRuntimeRenderer.renderInstruction(...)
ShadowRuntimeShapeKind.projectedPolygon
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Comportement observé :

- `projectedPolygon` avec 4 points utilise `createProjectedStaticShadowOpacityBands()`.
- `projectedPolygon` avec un nombre de points différent de 4 dessine un path rempli plat.
- `shadowRuntimePaintForInstruction(...)` utilise `PaintingStyle.fill`.
- `isAntiAlias = false`.
- `colorHexRgb` est appliquée directement après parsing RGB.
- `opacity` devient alpha global, puis peut être modulée par les bandes.

Editor :

```text
paintEditorStaticShadowPreviewInstructions(...)
EditorStaticShadowPreviewShapeKind.projectedPolygon
```

Comportement observé :

- le painter editor applique la même logique de bandes aux polygons de 4 points ;
- les polygons non-4 points sont dessinés en path plat ;
- `isAntiAlias = false` ;
- couleur et opacité suivent les champs de l'instruction editor.

Banding partagé :

```text
defaultProjectedStaticShadowFillBandCount = 7
defaultProjectedStaticShadowNearOpacityScale = 1.0
defaultProjectedStaticShadowFarOpacityScale = 0.52
```

Le renderer/painter peut-il déjà dessiner un footprint-like ?

```text
Oui, si le footprint-like est résolu en points polygonaux.
Un footprint V0 à 4 points peut réutiliser projectedPolygon directement.
Un footprint à 5 ou 6 points est aussi acceptable côté runtime/editor instruction,
mais ProjectedBuildingShadowGeometry map_core impose aujourd'hui exactement 4 points.
```

Faut-il modifier le renderer si on change seulement les points ?

```text
Pas pour un Footprint V0 à 4 points.
Le renderer et le painter dessinent déjà des polygons.
Le travail principal serait côté modèle/géométrie map_core et adaptations runtime/editor/tests.
```

Le banding s'appliquerait-il aussi à une géométrie footprint ?

```text
Oui si le footprint produit 4 points.
Non, ou plutôt pas via cette logique, si le futur modèle autorise plus de 4 points :
runtime/editor dessinent alors un fill plat pour projectedPolygon non-4 points.
Cette différence devra être décidée explicitement au Lot 39.
```

Faut-il un nouveau shape kind ?

```text
Pas nécessaire pour V0 si le nouveau mode continue à produire un projectedPolygon.
Un nouveau geometry mode côté preset/config est plus pertinent qu'un nouveau renderer shape kind.
```

## 9. Analyse de l'intention “reprendre la forme de l'objet”

L'intention utilisateur ne demande pas immédiatement :

```text
prendre le masque alpha exact du sprite,
projeter chaque pixel,
créer un shader,
créer un blur,
créer une ombre réaliste.
```

L'intention demande plutôt :

```text
une ombre qui lit comme l'emprise du bâtiment au sol,
large,
attachée,
simple,
grise,
dure,
artistiquement contrôlée.
```

Différence clé :

```text
Le trapèze actuel projette un segment depuis un anchor.
Une footprint shadow partirait des bounds visuels / du pied du bâtiment pour former une masse au sol.
```

Une interprétation V0 raisonnable de "reprendre la forme de l'objet" :

- utiliser `StaticShadowVisualMetrics` comme proxy de l'emprise visuelle ;
- définir un bord avant attaché à une zone basse du bâtiment ;
- définir un bord arrière court, large, éventuellement décalé bas-droite ;
- conserver une forme dure et grise ;
- éviter tout asset alpha, shader ou image externe.

Ce que cela améliorerait :

- l'attachement au volume ;
- la largeur perçue ;
- la lecture comme socle ;
- la proximité avec les références Pokémon-like fournies par l'utilisateur ;
- la stabilité artistique sur des bâtiments simples.

Ce que cela ne résout pas encore :

- silhouette réelle des toits ;
- assets avec ombres peintes ;
- variations par style de bâtiment ;
- authoring UI avancé ;
- banding si on reste à 4 points.

## 10. Familles de géométrie étudiées

### 10.1 Directional trapezoid actuel

Principe :

```text
anchor + direction + lengthRatio + nearWidthRatio + farWidthRatio
```

Forces :

- déjà implémenté ;
- simple ;
- testé ;
- compatible runtime/editor ;
- bon pour une projection directionnelle courte.

Faiblesses :

- tendance structurelle à produire des languettes ;
- attachement au bâtiment dépend trop d'un anchor unique ;
- ne raisonne pas en emprise au sol ;
- demande de forcer les ratios pour approcher un socle ;
- ne répond pas bien à "reprendre la forme de l'objet".

### 10.2 Footprint rectangle / parallelogram

Principe :

```text
partir des bounds du bâtiment,
créer une masse rectangulaire ou parallélogramme derrière / sous le bâtiment,
éventuellement décalée vers bas-droite.
```

Exemple conceptuel :

```text
baseX = metrics.left
baseY = metrics.top + metrics.visualHeight * footYRatio
width = metrics.visualWidth * widthRatio
height = metrics.visualHeight * heightRatio
offsetX = metrics.visualWidth * offsetXRatio
offsetY = metrics.visualHeight * offsetYRatio
```

Forces :

- proche de la référence ;
- simple ;
- stable ;
- indépendant des assets externes ;
- peut produire 4 points et donc réutiliser `projectedPolygon`.

Faiblesses :

- silhouette encore grossière ;
- peut devenir une plaque si trop large ou trop opaque ;
- demande un nouveau modèle de paramètres ;
- banding à décider si les 4 points sont conservés.

### 10.3 Footprint polygon à 4 ou 6 points

Principe :

```text
générer un polygone plus large et plus plat,
avec un bord avant attaché au bâtiment
et un bord arrière légèrement décalé / inset.
```

Forces :

- plus expressif qu'un rectangle pur ;
- permet d'éviter la plaque rectangulaire ;
- peut rester authorable ;
- peut s'adapter à une lecture bas-droite sans devenir un ruban.

Faiblesses :

- 4 points restent bandés par renderer/painter ;
- 6 points nécessitent de lever ou contourner l'invariant map_core actuel ;
- plus de paramètres peuvent rendre l'authoring moins simple.

### 10.4 Silhouette alpha mask projetée

Principe :

```text
prendre le masque alpha réel du sprite,
l'écraser / le projeter / le colorer en gris.
```

Forces :

- correspond littéralement à "reprendre la forme de l'objet" ;
- potentiellement très fidèle pour des assets propres.

Faiblesses :

- dépend des images ;
- coûteux à calculer et tester ;
- peut produire des ombres trop détaillées ;
- fragile avec sprites isométriques / toits / contours ;
- complique runtime/editor ;
- hors scope V0.

### 10.5 Author-defined shadow polygon

Principe :

```text
l'utilisateur ou l'asset définit directement les points du polygone d'ombre.
```

Forces :

- contrôle artistique maximal ;
- adapté aux assets importants ;
- compatible avec "pas d'automatisme magique".

Faiblesses :

- demande UI authoring ;
- demande stockage de points ;
- demande outils de preview / édition ;
- trop lourd pour le prochain petit lot.

### 10.6 Asset-provided shadow sprite / mask

Principe :

```text
l'asset fournit directement une ombre dédiée.
```

Forces :

- meilleur contrôle final ;
- très proche des pipelines pixel art classiques.

Faiblesses :

- pipeline asset lourd ;
- nécessite conventions d'assets ;
- pas adapté à une calibration moteur V0 ;
- ne doit pas précéder la clarification du mode footprint.

## 11. Comparaison Candidate C vs Footprint-like

Candidate C :

```text
direction: (0.35, 0.70)
lengthRatio: 0.24
nearWidthRatio: 1.15
farWidthRatio: 1.05
anchor: (0.5, 0.95)
opacity: 0.28
colorHexRgb: 606060
```

Forces de Candidate C :

- meilleure que A ;
- plus courte ;
- plus large ;
- moins latérale ;
- plus proche d'un socle que les autres trapèzes ;
- compatible moteur actuel ;
- ne nécessite aucun changement renderer/painter.

Limites de Candidate C :

- reste un trapèze directionnel ;
- reste pilotée par un anchor et une direction ;
- ne garantit pas une ombre attachée à l'emprise du bâtiment ;
- peut varier bizarrement selon dimensions d'asset ;
- ne répond pas complètement à la référence Pokémon-like fournie ;
- risque de devenir la "moins mauvaise" option plutôt que la bonne direction.

Footprint-like :

Forces :

- part explicitement de l'emprise visuelle du bâtiment ;
- rend l'attachement au volume central dans la formule ;
- peut rester simple et hard-edge ;
- peut réutiliser `projectedPolygon` ;
- peut limiter l'effet languette par construction ;
- s'aligne mieux avec la référence : masse grise large, attachée, posée au sol.

Limites :

- nécessite une conception de modèle ;
- nécessite d'établir nouveaux paramètres et invariants ;
- peut générer une plaque si mal calibré ;
- doit décider banding 4 points vs fill plat non-4 points ;
- devra être validé par micro-artifact avant production réelle.

Conclusion :

```text
Candidate C est un bon témoin et un fallback possible.
Mais le prochain lot ne doit pas propager Candidate C.
Il doit concevoir Footprint Geometry V0.
```

## 12. Option recommandée

Option recommandée :

```text
Option B — Concevoir un nouveau mode footprint-like simple.
```

Décision :

```text
Concevoir Footprint Geometry V0 au Lot 39.
Ne pas appliquer Candidate C comme nouvelle calibration finale maintenant.
Ne pas passer directement à silhouette/alpha mask.
Ne pas modifier renderer/painter avant d'avoir défini la géométrie.
```

Pourquoi :

- l'intention artistique est une emprise au sol, pas une projection en ruban ;
- Candidate C améliore la projection, mais reste dans la mauvaise famille conceptuelle ;
- un footprint V0 peut rester simple : bounds + ratios + offset + polygon ;
- le renderer/painter actuels peuvent déjà dessiner des polygons ;
- la décision garde le travail des lots précédents comme evidence, pas comme impasse ;
- elle évite d'industrialiser une calibration encore insatisfaisante.

Pourquoi les autres options sont rejetées :

- Option A — Continuer avec Candidate C :
  - rejetée comme direction principale, car elle optimise un modèle qui ne correspond pas pleinement à la cible ;
  - conservée seulement comme fallback / benchmark.
- Option C — Silhouette alpha mask :
  - rejetée pour V0, car trop asset-dependent, trop coûteuse et trop fragile.
- Option D — Author-defined polygon :
  - rejetée pour le prochain lot, car elle demande UI authoring et stockage manuel de points.
- Option E — Hybride court terme :
  - partiellement retenue dans l'esprit : Candidate C reste fallback ;
  - mais la recommandation unique est Footprint Geometry V0, pour éviter une demi-décision.

Lot 39 doit faire :

- définir un mode Footprint Geometry V0 ;
- décider s'il s'agit d'un enum de geometry mode, d'un preset kind ou d'une autre structure ;
- définir les paramètres minimums ;
- décider 4 points vs 6 points ;
- définir les invariants de bounds, attachement et offsets ;
- confirmer la réutilisation de `ProjectedBuildingShadowGeometry` ou documenter les changements requis ;
- confirmer que runtime/editor peuvent rester sur `projectedPolygon` ;
- préparer les tests attendus sans les écrire.

Lot 39 ne doit pas faire :

- coder le mode ;
- modifier map_core ;
- modifier runtime/editor ;
- modifier renderer/painter ;
- créer une baseline ;
- créer une image ;
- toucher Selbrume ;
- créer UI authoring ;
- traiter silhouette alpha mask en implémentation.

## 13. Plan précis du Lot 39

Nom recommandé :

```text
ShadowV2-39 — Projected Building Shadow Footprint Geometry Design V0
```

Objectif :

```text
Définir précisément un nouveau mode de géométrie footprint-like,
ses paramètres,
ses invariants,
son interaction avec le renderer existant,
et son plan d'implémentation,
sans coder encore.
```

Fichier à créer :

```text
reports/shadows/v2/shadow_v2_39_projected_building_shadow_footprint_geometry_design_v0.md
```

Fichiers à auditer :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

Questions à trancher :

- nouveau `geometryMode` ou nouveau preset kind ?
- coexistence avec le trapèze directionnel actuel ;
- paramètres V0 minimums :
  - `attachYRatio` ou équivalent ;
  - `widthRatio` ;
  - `heightRatio` ;
  - `offsetXRatio` ;
  - `offsetYRatio` ;
  - éventuel `rearInsetRatio` / `skewXRatio` ;
- sortie 4 points ou 6 points ;
- conservation ou assouplissement de l'invariant `ProjectedBuildingShadowGeometry.points.length == 4` ;
- banding : accepté sur 4 points, ou fill plat si polygon non-4 points ;
- compatibilité runtime/editor via `projectedPolygon` ;
- relation avec Candidate C comme fallback de mode directionnel ;
- tests map_core / runtime / editor attendus au lot d'implémentation suivant ;
- besoin ou non d'un nouvel artifact comparatif après design.

Plan de décision attendu :

```text
1. Définir le modèle conceptuel Footprint V0.
2. Définir les paramètres et leurs bornes.
3. Définir une formule de points explicite.
4. Définir les invariants de rendu.
5. Définir la coexistence avec directional trapezoid.
6. Définir le plan d'implémentation strictement borné du lot suivant.
```

Fichiers interdits au Lot 39 :

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_core/test/**
packages/map_runtime/test/**
packages/map_editor/test/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

Commandes à lancer au Lot 39 :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "ProjectedShadowShapeTuning|ProjectBuildingShadowPreset|ProjectedBuildingShadowGeometry|resolveProjectedBuildingShadowGeometry|ProjectedShadowAnchor|ProjectedShadowOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2
rg -n "projectedPolygon|ShadowRuntimeRenderer|paintEditorStaticShadowPreviewInstructions|createProjectedStaticShadowOpacityBands|polygonPoints.length" packages/map_runtime/lib packages/map_editor/lib packages/map_runtime/test packages/map_editor/test packages/map_core/lib
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation du Lot 39 :

- un seul rapport Markdown créé ;
- aucune implémentation ;
- aucune image ;
- aucun test modifié ;
- Footprint V0 défini avec paramètres précis ;
- interaction renderer/painter tranchée ;
- Candidate C positionnée comme fallback ou benchmark ;
- plan d'implémentation suivant concret ;
- git diff --check propre ;
- git status final conforme.

## 14. Fichiers explicitement interdits au Lot 39

Le Lot 39 recommandé doit rester design-only.

Interdits :

```text
packages/map_core/**
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
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
```

Créations interdites :

```text
fichier Dart
test Dart
fixture
screenshot
baseline
image
script
outil
migration
nouveau modèle persistant
nouveau codec
generated file
UI authoring
shader
blur
auto-shadow policy
```

## 15. Risques / réserves

Risques du pivot footprint :

- le futur modèle peut devenir trop riche si les paramètres ne sont pas sévèrement limités ;
- un footprint rectangle trop large peut créer une plaque grise ;
- un footprint à 4 points héritera du banding actuel ;
- un footprint à 6 points pourrait éviter les bandes mais demanderait un changement d'invariant map_core ;
- la bonne forme peut dépendre des assets réels, mais Selbrume ne doit pas encore être modifié.

Réserves sur Candidate C :

```text
Candidate C reste utile comme baseline mentale du meilleur trapèze actuel.
Elle ne doit pas être jetée.
Elle ne doit pas non plus être promue comme cible produit tant que l'intention footprint n'a pas été conçue.
```

Réserve sur silhouette/mask :

```text
La silhouette alpha est séduisante conceptuellement,
mais elle importerait de la complexité image/asset trop tôt.
Elle doit rester une piste long terme, pas une V0.
```

## 16. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Un seul rapport Markdown est créé. Aucun code, test, screenshot, baseline ou fichier Selbrume n'est modifié.
```

Le rapport répond-il vraiment à l'intuition “reprendre la forme de l'objet” ?

```text
Oui. Il distingue une silhouette alpha exacte d'une footprint V0 pragmatique fondée sur l'emprise visuelle du bâtiment.
```

Le rapport évite-t-il de choisir Candidate C juste parce qu'elle est moins mauvaise ?

```text
Oui. Candidate C est reconnue comme meilleur trapèze, mais rejetée comme prochaine direction principale.
```

La piste footprint-like est-elle assez concrète ?

```text
Oui pour un design gate : les paramètres à décider, les invariants, les fichiers à auditer et l'interaction renderer/painter sont listés.
Le Lot 39 devra fixer la formule exacte.
```

La piste silhouette/mask est-elle analysée sans être implémentée prématurément ?

```text
Oui. Elle est étudiée et rejetée pour V0 en raison du coût asset/image.
```

Le plan Lot 39 est-il strictement borné ?

```text
Oui. Il recommande un nouveau design gate, pas une implémentation.
```

Le plan évite-t-il Selbrume / baseline / production ?

```text
Oui. Ces éléments sont explicitement interdits.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Il inclut l'état initial, les fichiers audités, les métadonnées de l'artifact, les commandes exécutées, l'option recommandée, le plan Lot 39 et les sorties git finales.
```

## 17. Regard critique sur le prompt

Le prompt est cohérent avec le constat visuel de l'utilisateur :

```text
la comparaison ne porte plus seulement sur "quel trapèze choisir",
mais sur "est-ce qu'un trapèze est la bonne famille de forme".
```

Point fort :

```text
Le prompt impose de ne pas coder et de ne pas créer de nouvelle image,
ce qui évite de masquer une décision produit derrière un nouvel artifact.
```

Point de vigilance :

```text
Le mot "silhouette" peut pousser vers un alpha mask trop ambitieux.
La lecture recommandée pour V0 est footprint-like : une emprise simplifiée,
pas une projection pixel-perfect du sprite.
```

## 18. Commandes lancées

Commandes obligatoires :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAnchor|ProjectedShadowOffset|lengthRatio|nearWidthRatio|farWidthRatio|anchor|localOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2

rg -n "ShadowRuntimeRenderer|projectedPolygon|drawPath|createProjectedStaticShadowOpacityBands|isAntiAlias|paintEditorStaticShadowPreviewInstructions|EditorStaticShadowPreviewShapeKind.projectedPolygon" packages/map_runtime/lib packages/map_editor/lib packages/map_core/lib packages/map_runtime/test packages/map_editor/test

rg -n "candidate-c-short-broad|Short broad|footprint|silhouette|shape|languette|socle|Pokemon-like|Pokémon-like|projected building shadow" reports/shadows/v2 packages/map_runtime/tool packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib

file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png

git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Commandes de lecture ciblée complémentaires :

```bash
sed -n '1,180p' packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
sed -n '1,260p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '220,330p' packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
sed -n '1,220p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,220p' packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
sed -n '1,220p' packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
sed -n '1,220p' packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
sed -n '1,220p' reports/shadows/v2/shadow_v2_37_projected_building_shadow_candidate_selection_design.md
```

Tests lancés :

```text
Aucun. Le lot est design-only et aucun fichier de code/test n'a été modifié.
```

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text

```

Interprétation :

```text
Aucun tracked diff. Le rapport Lot 38 est un nouveau fichier non suivi,
donc il apparaît dans git status et non dans git diff --stat.
```

## 20. git diff --name-status

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
Le seul fichier créé par le lot est non suivi.
```

## 21. git diff --check

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

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/v2/shadow_v2_38_projected_building_shadow_footprint_silhouette_geometry_design.md
```

Confirmation du scope :

```text
Conforme : seul le rapport ShadowV2-38 est non suivi.
Aucun fichier Dart, test, production, Selbrume, screenshot ou baseline n'est créé ou modifié.
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
- [x] Modèle trapézoïdal actuel audité
- [x] Renderer/painter existants audités
- [x] Footprint-like analysé
- [x] Silhouette/mask analysé
- [x] Candidate C comparée honnêtement
- [x] Option recommandée unique
- [x] Plan ShadowV2-39 précis
- [x] Fichiers interdits au Lot 39 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
