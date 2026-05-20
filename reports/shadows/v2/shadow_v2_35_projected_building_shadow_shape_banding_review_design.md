# ShadowV2-35 — Projected Building Shadow Shape / Banding Review Design Gate

## 1. Résumé exécutif

ShadowV2-35 est un lot design-only. Aucun fichier de production, aucun test, aucune image, aucune baseline et aucun fichier Selbrume n'ont été modifiés ou créés.

Diagnostic principal :

```text
Le problème visuel principal vient d'abord de la forme / direction / largeur / ancre du trapèze V0.
Le banding hard-edge est visible, mais il est secondaire : il accentue une forme déjà trop étroite et trop détachée.
```

Option recommandée :

```text
Option B — Créer une matrice d'artifacts candidats.
```

Pourquoi :

- l'artifact Lot 34 montre une ombre techniquement correcte mais trop "languette diagonale" ;
- la direction V0 normalisée est très latérale `(0.916, 0.401)` ;
- le `farWidthRatio` V0 est plus petit que le `nearWidthRatio`, ce qui affine encore la projection ;
- la cible Pokémon-like lit plutôt comme une masse grise attachée au pied / derrière le volume ;
- il faut comparer plusieurs presets avant de modifier renderer, painter ou géométrie map_core.

Lot 36 recommandé :

```text
ShadowV2-36 — Projected Building Shadow Candidate Matrix Artifact V0
```

## 2. Objectif du lot

Objectif exact :

```text
Analyser l'artifact visuel ShadowV2-34,
identifier pourquoi l'ombre calibrée V0 ne paraît pas encore belle,
distinguer les problèmes de forme / direction / ancre / largeur / longueur / banding / artifact harness,
puis recommander un prochain lot strictement borné.
```

Question à trancher :

```text
Le problème visuel principal vient-il :
1. de la géométrie de l'ombre ;
2. du banding hard-edge ;
3. de la calibration du preset ;
4. de la micro-fixture / bâtiment simplifié ;
5. d'un mélange de ces facteurs ?
```

Réponse :

```text
Le problème est mixte, mais l'ordre de priorité est :
1. calibration de forme/direction/ancre/largeur ;
2. limites de la géométrie trapézoïdale actuelle ;
3. banding visible mais secondaire ;
4. micro-fixture simplifiée qui amplifie la lecture pauvre, sans être la cause principale.
```

## 3. Rappel ShadowV2-31 à ShadowV2-34

ShadowV2-31 :

```text
preset id: pokemon-building-shadow-v0
direction: ProjectedShadowDirection(x: 0.8, y: 0.35)
shape.lengthRatio: 0.32
shape.nearWidthRatio: 0.90
shape.farWidthRatio: 0.72
appearance.opacity: 0.30
appearance.colorHexRgb: 606060
timeOfDayMode: fixed
anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96)
localOffset: ProjectedShadowOffset(x: 0, y: 0)
```

ShadowV2-32 :

```text
map_core    -> points calibrés
map_runtime -> pixel intérieur alpha > 0 / extérieur stable
map_editor  -> preview editor calibrée
```

ShadowV2-33 :

```text
Ne pas créer de baseline tout de suite.
Générer un artifact manuel pour revue humaine.
```

ShadowV2-34 :

```text
PNG 320x224 ;
deux panels ;
vraie utilisation de ShadowRuntimeRenderer.renderCollectionPass(...) ;
pas de baseline ;
pas de Selbrume ;
pas de modification production.
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
Le worktree était propre avant ShadowV2-35.
Les fichiers du Lot 34 sont maintenant suivis et ne sont pas des modifications préexistantes.
```

Fichiers préexistants non liés au lot :

```text
Aucun
```

Fichiers créés par ShadowV2-35 :

```text
reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

Fichiers modifiés par ShadowV2-35 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-35 :

```text
Aucun
```

## 5. Décision AGENTS / design gate

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
Le Lot 35 est explicitement un design gate / audit-only.
Aucune implémentation n'a été faite.
Aucun test n'a été lancé, car aucun fichier de code ou test n'a été modifié.
```

## 6. Fichiers audités

Artifact Lot 34 :

```text
reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
reports/shadows/v2/shadow_v2_34_projected_building_shadow_micro_visual_artifact.md
```

Géométrie ShadowV2 :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
reports/shadows/v2/shadow_v2_31_projected_building_shadow_visual_calibration_design.md
reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
```

Banding / renderer / painter :

```text
packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_runtime/test/shadow/shadow_runtime_renderer_test.dart
packages/map_editor/test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

Harness Lot 34 :

```text
packages/map_runtime/tool/shadow/shadow_v2_micro_visual_artifact_test.dart
```

## 7. Audit artifact ShadowV2-34

Commandes :

```bash
file reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

Sorties :

```text
reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png: PNG image data, 320 x 224, 8-bit/color RGBA, non-interlaced
-rw-r--r--@ 1 karim  staff   2.1K May 20 23:31 reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
de6a2c5fa0e02da89f7f61daa4429e5ba67e4d37983e6f8443b3dfb1284bd1aa  reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
```

Métadonnées :

```text
dimensions: 320 x 224
format: PNG RGBA non-interlaced
taille affichée: 2.1K
sha256: de6a2c5fa0e02da89f7f61daa4429e5ba67e4d37983e6f8443b3dfb1284bd1aa
```

Présence des deux panels :

```text
Oui.
Panel gauche: shadow-only sur fond clair quadrillé.
Panel droit: même ombre + bâtiment rectangulaire simple par-dessus.
```

Analyse visuelle directe :

```text
L'ombre lit comme une languette diagonale étroite, inclinée vers la droite.
Le panel gauche rend bien visible une forme trapézoïdale fine.
Le panel droit montre que l'ombre existe sous le bloc bâtiment, mais elle ne donne pas encore une assise de volume.
Le banding est perceptible, surtout parce que la forme est petite et striée.
```

Points visuellement utiles :

```text
Le pixel intérieur historique (80,150) tombe bien dans l'ombre.
La grille 32x32 aide à voir que l'ombre est courte et très latérale.
Le bâtiment simple confirme l'ordre de paint, mais ne ressemble pas à un asset Pokémon-like.
```

Limites de l'artifact :

```text
Le bâtiment est volontairement schématique.
Il n'a pas de toit isométrique ni de silhouette pixel-art réelle.
Le fond est plat et clair.
L'artifact ne prétend pas représenter Selbrume ni une vraie map.
```

## 8. Audit géométrie actuelle

Commande :

```bash
rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAnchor|ProjectedShadowOffset|lengthRatio|nearWidthRatio|farWidthRatio|anchor|localOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2
```

Fichier principal :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
```

Formule actuelle :

```text
direction = preset.direction.normalized
perpendicular = (-direction.y, direction.x)
anchorWorldX = metrics.left + metrics.visualWidth * config.anchor.xRatio + localOffset.x
anchorWorldY = metrics.top + metrics.visualHeight * config.anchor.yRatio + localOffset.y
length = metrics.visualHeight * preset.shape.lengthRatio
nearHalfWidth = metrics.visualWidth * preset.shape.nearWidthRatio / 2
farHalfWidth = metrics.visualWidth * preset.shape.farWidthRatio / 2
farCenter = anchor + direction * length
points = nearLeft, nearRight, farRight, farLeft
```

Rôle de chaque paramètre :

```text
direction: oriente l'axe de projection ; V0 (0.8,0.35) se normalise en (0.916,0.401), donc très latéral.
lengthRatio: longueur de projection relative à la hauteur visuelle du sprite.
nearWidthRatio: largeur de départ relative à la largeur visuelle.
farWidthRatio: largeur d'arrivée relative à la largeur visuelle.
anchor: point local du sprite depuis lequel part la projection.
localOffset: déplacement manuel après résolution de l'ancre.
```

Calcul V0 sur la micro-fixture :

```text
metrics.left = 32
metrics.top = 64
visualWidth = 64
visualHeight = 96
anchor = (64.00, 156.16)
direction normalized = (0.916, 0.401)
length = 30.72
nearWidth = 57.60
farWidth = 46.08
bounds = (52.46, 129.77), width 48.92, height 59.81
```

Points V0 :

```text
nearLeft  = (75.54,129.77)
nearRight = (52.46,182.55)
farRight  = (82.91,189.58)
farLeft   = (101.38,147.36)
```

Pourquoi cela produit la forme vue :

```text
La direction est surtout horizontale vers la droite.
Le trapèze commence à une ancre proche du bas du bâtiment, mais sa near edge est perpendiculaire à la direction.
Comme la direction est très latérale, cette near edge devient une diagonale raide qui monte dans la silhouette.
Le farWidth plus petit que nearWidth resserre la forme et la fait lire comme une bande / languette.
```

La géométrie actuelle peut-elle produire une ombre plus attachée avec seulement un preset ?

```text
Oui, probablement jusqu'à un V0 meilleur.
Une direction plus verticale, des largeurs near/far plus larges et moins divergentes, une longueur plus courte/modérée et une ancre légèrement ajustée peuvent produire une masse plus posée.
Mais la géométrie actuelle restera un quadrilatère directionnel : elle ne pourra pas produire une silhouette asset-specific, une ombre en L, une empreinte parfaitement horizontale, ni une découpe de toit.
```

## 9. Audit banding actuel

Commande :

```bash
rg -n "createProjectedStaticShadowOpacityBands|ProjectedStaticShadowOpacityBand|defaultProjectedStaticShadowFillBandCount|defaultProjectedStaticShadowNearOpacityScale|defaultProjectedStaticShadowFarOpacityScale|drawPath|isAntiAlias|projectedPolygon|opacityScale" packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib packages/map_runtime/test packages/map_editor/test
```

Constantes :

```text
defaultProjectedStaticShadowFillBandCount = 7
defaultProjectedStaticShadowNearOpacityScale = 1.0
defaultProjectedStaticShadowFarOpacityScale = 0.52
```

Rendu runtime :

```text
ShadowRuntimeRenderer._renderProjectedPolygon(...)
si points.length == 4 -> boucle sur createProjectedStaticShadowOpacityBands(...)
chaque bande est drawPath(...)
shadowRuntimePaintForInstruction(...).isAntiAlias = false
```

Rendu editor :

```text
paintEditorStaticShadowPreviewInstructions(...)
si projectedPolygon et 4 points -> même helper createProjectedStaticShadowOpacityBands(...)
chaque bande est drawPath(...)
bandPaint.isAntiAlias = false
```

Effet avec opacity V0 `0.30` :

```text
near approx 0.30
far approx 0.166
7 bandes hard-edge
pas de blur
pas d'antialiasing
```

Les bandes sont-elles visibles dans l'artifact ?

```text
Oui, elles sont visibles sur le panel shadow-only.
Elles se lisent comme des stries dans une petite forme diagonale.
```

Les bandes sont-elles la cause principale ?

```text
Non.
Le banding aggrave la perception, mais le premier problème est la forme :
ombre trop étroite, trop latérale, trop détachée, avec farWidth plus étroit.
Si la forme était plus large et plus attachée, le même banding serait moins gênant ou plus facile à juger.
```

Conclusion banding :

```text
Ne pas modifier le renderer/painter avant une matrice de formes.
Le banding doit être revu après comparaison de presets candidats, pas avant.
```

## 10. Comparaison avec cible Pokémon-like

Référence utilisateur :

```text
bâtiments Pokémon-like avec ombres grises simples,
souvent dures,
souvent larges,
attachées au pied / derrière le volume,
et cohérentes en direction.
```

Différences principales :

```text
Largeur:
L'artifact V0 est étroit. La référence montre souvent une masse plus large et plus ancrée.

Attachement:
L'artifact V0 semble partir d'une diagonale interne plutôt que du pied du bâtiment.
La référence lit comme une ombre accrochée au volume ou à son socle.

Direction:
V0 part surtout vers la droite. La référence paraît plus basse / arrière, selon les bâtiments.

Longueur:
La longueur V0 n'est pas énorme, mais comme la forme est étroite, elle lit comme une traînée.

Forme:
V0 est un trapèze directionnel très identifiable.
La référence lit plutôt comme une plaque/empreinte dure et simple, parfois polygonale mais moins ruban.

Lisibilité:
V0 est lisible techniquement, mais pas encore comme belle ombre de bâtiment.

Banding:
La référence ne met pas en avant de strates visibles.
V0 montre des bandes visibles parce que le rendu est hard-edge bandé et la forme est petite.

Couleur/opacité:
606060 à 0.30 n'est pas le premier problème. La valeur est plausible, même si elle devra être retestée après une meilleure forme.
```

## 11. Diagnostic principal

Diagnostic principal :

```text
Le rendu actuel échoue surtout par géométrie/calibration de forme :
direction trop latérale, forme trop étroite, farWidth trop réduit, ancre qui fait lire la near edge comme une diagonale détachée.
```

Diagnostic secondaire :

```text
Le banding est visible et pas très Pokémon-like dans l'artifact,
mais il n'est pas encore prouvé qu'il faille modifier le renderer.
Il peut devenir acceptable ou moins visible avec une forme plus large, plus courte et plus attachée.
```

Diagnostic harness :

```text
Le bâtiment rectangulaire simplifié amplifie le côté prototype,
mais il n'explique pas l'aspect languette du shadow-only panel.
Le panel gauche suffit à montrer que la forme doit être explorée avant une baseline.
```

## 12. Options étudiées

### Option A — Recalibrer seulement le preset actuel

Principe :

```text
Changer direction / lengthRatio / nearWidthRatio / farWidthRatio / anchor / opacity,
sans toucher à la géométrie ni au renderer.
```

Avantages :

```text
plus petit changement ;
compatible système actuel ;
peut suffire pour V0 ;
ne touche pas production si testé via artifacts.
```

Risques :

```text
une seule recalibration à l'aveugle risque de répéter Lot 31 ;
la forme trapézoïdale peut rester insuffisante ;
pas assez comparatif.
```

Décision :

```text
Bonne direction technique, mais insuffisante seule. À inclure dans une matrice.
```

### Option B — Créer une matrice d’artifacts candidats

Principe :

```text
Générer plusieurs variantes contrôlées de la même micro-fixture :
direction plus verticale ;
ombre plus large ;
ombre plus courte ;
anchor plus bas ou plus haut selon lecture ;
farWidth plus proche du nearWidth ;
fill/banding inchangé.
```

Avantages :

```text
permet une revue humaine comparative ;
ne modifie pas renderer/painter ;
ne fige rien ;
teste si la géométrie actuelle suffit ;
sépare forme et banding.
```

Risques :

```text
crée un nouvel artifact manuel ;
ne valide pas encore en CI ;
demande de choisir une variante après inspection.
```

Décision :

```text
Option recommandée.
```

### Option C — Changer la géométrie ShadowV2

Principe :

```text
Modifier resolveProjectedBuildingShadowGeometry(...)
ou ajouter un nouveau mode de géométrie plus footprint-like.
```

Avantages :

```text
pourrait produire une ombre plus attachée au bâtiment ;
peut permettre un vrai mode footprint.
```

Risques :

```text
touche map_core ;
implique runtime + editor + tests ;
change les contrats ;
prématuré avant comparaison de presets.
```

Décision :

```text
Rejetée pour le Lot 36.
À rouvrir seulement si aucune variante preset ne donne une forme acceptable.
```

### Option D — Changer le rendu des bandes

Principe :

```text
Modifier createProjectedStaticShadowOpacityBands(...)
ou le renderer/painter pour réduire / augmenter / supprimer le banding.
```

Avantages :

```text
peut réduire les strates visibles ;
peut rapprocher d'un fill plat Pokémon-like.
```

Risques :

```text
ne corrige pas la forme languette ;
touche runtime + editor ;
risque de casser des tests existants ;
doit être séparé si le banding reste visible après forme correcte.
```

Décision :

```text
Rejetée pour le Lot 36.
Le banding est secondaire à ce stade.
```

### Option E — Utiliser une ombre rectangulaire / footprint-like simple

Principe :

```text
Au lieu d'une projection directionnelle trapézoïdale,
créer une ombre type footprint élargie et décalée derrière le bâtiment.
```

Avantages :

```text
peut être plus proche de certaines références ;
stable ;
moins rayon projeté.
```

Risques :

```text
nécessite probablement nouveau modèle/shape/mode ;
pas simple preset ;
plus lourd que nécessaire pour apprendre.
```

Décision :

```text
Rejetée pour le Lot 36.
À envisager après échec d'une matrice preset.
```

### Option F — Garder le rendu actuel et passer à l’authoring UI

Principe :

```text
Considérer l'artifact acceptable et avancer vers les contrôles editor.
```

Avantages :

```text
avance vite.
```

Risques :

```text
construit l'UI autour d'un rendu encore moche ;
risque de figer une mauvaise expérience ;
contredit la revue humaine de l'artifact.
```

Décision :

```text
Rejetée.
```

## 13. Option recommandée

Option recommandée :

```text
Option B — Créer une matrice d'artifacts candidats.
```

Diagnostic principal :

```text
forme / direction / anchor / largeur.
```

Diagnostic secondaire :

```text
banding visible, mais pas encore priorité renderer.
```

Pourquoi :

```text
- La géométrie actuelle peut probablement produire une variante plus attachée sans changer map_core.
- Une matrice permet de comparer visuellement plusieurs directions et largeurs.
- Elle évite de modifier renderer/painter trop tôt.
- Elle évite une baseline sur un rendu non choisi.
- Elle garde le travail hors Selbrume et hors production.
```

Pourquoi les autres options sont rejetées :

```text
Option A seule : trop peu comparative.
Option C : trop lourde et prématurée.
Option D : traite un problème secondaire avant la forme.
Option E : probablement nouveau mode/shape, trop tôt.
Option F : avance vers l'UI alors que le rendu n'est pas satisfaisant.
```

Lot 36 doit faire :

```text
- générer une image comparative micro-fixture avec plusieurs variants ;
- garder le renderer/painter inchangés ;
- garder le banding actuel pour isoler l'effet de forme ;
- inclure le bâtiment simple et, si possible, un shadow-only par candidat ;
- documenter quelle variante lit le mieux comme ombre Pokémon-like.
```

Lot 36 ne doit pas faire :

```text
- modifier production ;
- modifier map_core geometry ;
- modifier renderer/painter ;
- créer baseline ;
- utiliser Selbrume ;
- créer UI authoring ;
- traiter followsSun ou cycle jour/nuit.
```

## 14. Plan précis du Lot 36

Nom recommandé :

```text
ShadowV2-36 — Projected Building Shadow Candidate Matrix Artifact V0
```

Objectif :

```text
Générer une image comparative micro-fixture avec plusieurs variantes de shape/preset,
sans modifier renderer/painter,
sans baseline,
sans Selbrume,
pour choisir visuellement une forme plus Pokémon-like.
```

Fichiers à créer :

```text
packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
reports/shadows/v2/shadow_v2_36_projected_building_shadow_candidate_matrix_artifact.md
```

Fichiers à modifier :

```text
Aucun fichier de production.
Aucun test existant.
```

Fichiers interdits :

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

Variantes à comparer :

```text
A — Current V0
B — More downward / attached
C — Short broad footprint-like
D — Wider soft trapezoid without changing renderer
E — Low side cast
```

Commandes à lancer :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "shadow_v2_micro_visual_artifact|ShadowRuntimeRenderer|renderCollectionPass|pokemon-building-shadow-v0" packages/map_runtime/tool reports/shadows/v2
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
cd /Users/karim/Project/pokemonProject
file reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_36_projected_building_shadow_candidate_matrix.png
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
cd /Users/karim/Project/pokemonProject
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows" packages/map_runtime/tool/shadow/shadow_v2_candidate_matrix_artifact_test.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Critères de validation :

```text
- un artifact PNG matrice est créé ;
- aucune baseline ;
- aucun matchesGoldenFile ;
- aucun Selbrume ;
- aucun fichier production ;
- toutes les variantes utilisent ShadowRuntimeRenderer.renderCollectionPass(...) ;
- les variantes sont visibles et étiquetées ou documentées ;
- le rapport compare explicitement les variantes ;
- le Lot 37 recommandé découle de la meilleure variante ou d'un échec clair.
```

## 15. Variantes candidates recommandées

### Candidate A — Current V0

```text
direction: (0.8, 0.35)
normalized: (0.916, 0.401)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
anchor: (0.5, 0.96)
opacity: 0.30
color: 606060
expected: témoin actuel, languette latérale
```

### Candidate B — More downward / attached

```text
direction: (0.45, 0.90)
normalized: (0.447, 0.894)
lengthRatio: 0.34
nearWidthRatio: 1.05
farWidthRatio: 0.95
anchor: (0.5, 0.92)
opacity: 0.30
color: 606060
expected: plus basse, plus attachée, moins ruban latéral
```

### Candidate C — Short broad footprint-like

```text
direction: (0.35, 0.70)
normalized: (0.447, 0.894)
lengthRatio: 0.24
nearWidthRatio: 1.15
farWidthRatio: 1.05
anchor: (0.5, 0.95)
opacity: 0.28
color: 606060
expected: plus courte, plus socle, proche footprint sans nouveau mode
```

### Candidate D — Wider soft trapezoid without changing renderer

```text
direction: (0.55, 0.65)
normalized: (0.646, 0.763)
lengthRatio: 0.30
nearWidthRatio: 1.20
farWidthRatio: 1.10
anchor: (0.5, 0.94)
opacity: 0.28
color: 606060
expected: trapèze plus large, encore directionnel, moins détaché
```

### Candidate E — Low side cast

```text
direction: (0.70, 0.45)
normalized: (0.841, 0.541)
lengthRatio: 0.26
nearWidthRatio: 1.10
farWidthRatio: 0.95
anchor: (0.5, 0.98)
opacity: 0.30
color: 606060
expected: conserve une lecture latérale mais plus basse et plus large que V0
```

Justification des variantes :

```text
B/C testent une projection plus verticale et attachée.
C teste le plus fort compromis footprint-like sans nouveau modèle.
D teste une masse large mais encore trapézoïdale.
E vérifie si le style latéral peut être sauvé avec largeur/ancre plus basse.
A garde le témoin V0.
```

## 16. Fichiers explicitement interdits au Lot 36

```text
packages/map_core/lib/**
packages/map_core/test/**
packages/map_runtime/lib/**
packages/map_runtime/test/**
packages/map_editor/lib/**
packages/map_editor/test/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
```

Interdits fonctionnels :

```text
renderer/painter
map_core geometry
modèles
codecs
generated
UI authoring
Selbrume
baseline
golden
matchesGoldenFile
shader
blur
auto-shadow
followsSun
cycle jour/nuit
```

## 17. Risques / réserves

```text
1. La matrice peut montrer qu'aucun preset trapézoïdal ne suffit.
2. Si toutes les variantes échouent, il faudra rouvrir un design gate géométrie/footprint.
3. Si une variante est bonne malgré les bandes, le banding pourra être laissé à plus tard.
4. Si une variante est bonne sauf stries visibles, le prochain lot devra isoler le banding.
5. Les artifacts micro ne remplacent pas une validation sur vrais assets.
```

## 18. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Le seul fichier créé est le rapport Lot 35.
```

Le diagnostic distingue-t-il clairement forme et banding ?

```text
Oui. La forme est diagnostiquée comme cause principale ; le banding est secondaire mais visible.
```

La recommandation évite-t-elle de modifier le renderer trop tôt ?

```text
Oui. Le Lot 36 garde renderer/painter inchangés.
```

Le plan Lot 36 permet-il une vraie comparaison visuelle ?

```text
Oui. Il propose une matrice d'artifacts avec témoin et variantes assez différentes.
```

Les variantes proposées sont-elles assez différentes pour apprendre quelque chose ?

```text
Oui. Elles couvrent latéral, vertical, large, court, footprint-like et trapèze large.
```

Le plan évite-t-il Selbrume / baseline / production ?

```text
Oui. Ces éléments sont explicitement interdits.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Il inclut état git, métadonnées artifact, audit géométrie, audit banding, comparaison référence, options, plan Lot 36 et git final.
```

## 19. Regard critique sur le prompt

Le prompt est bien calibré : il empêche de sauter trop vite vers une correction renderer ou une baseline. Il force à distinguer la forme du banding, ce qui est exactement le piège après le Lot 34.

Point de vigilance :

```text
Le Lot 36 devra probablement créer une image plus grande que 320x224 pour afficher 5 variantes lisibles.
Cela doit être autorisé explicitement dans le prompt Lot 36.
```

Autre point :

```text
La comparaison Pokémon-like reste conceptuelle, sans image externe. C'est approprié ici, car la référence utilisateur est déjà présente dans la conversation et le lot interdit les recherches/téléchargements.
```

## 20. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
file reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_34_projected_building_shadow_micro_visual_artifact.png
rg -n "resolveProjectedBuildingShadowGeometry|ProjectedBuildingShadowGeometry|ProjectedBuildingShadowPoint|ProjectedShadowDirection|ProjectedShadowShapeTuning|ProjectedShadowAnchor|ProjectedShadowOffset|lengthRatio|nearWidthRatio|farWidthRatio|anchor|localOffset" packages/map_core/lib packages/map_core/test reports/shadows/v2
rg -n "createProjectedStaticShadowOpacityBands|ProjectedStaticShadowOpacityBand|defaultProjectedStaticShadowFillBandCount|defaultProjectedStaticShadowNearOpacityScale|defaultProjectedStaticShadowFarOpacityScale|drawPath|isAntiAlias|projectedPolygon|opacityScale" packages/map_core/lib packages/map_runtime/lib packages/map_editor/lib packages/map_runtime/test packages/map_editor/test
rg -n "pokemon-building-shadow-v0|606060|0.30|shadow_v2_34_projected_building_shadow_micro_visual_artifact|ShadowRuntimeRenderer|renderCollectionPass|PictureRecorder|projectedPolygon|band" packages/map_runtime/tool packages/map_runtime/test packages/map_editor/test reports/shadows
sed -n '1,260p' packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
sed -n '1,310p' packages/map_core/lib/src/operations/static_shadow_projection_geometry.dart
sed -n '1,180p' packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
sed -n '1,130p' packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
sed -n '1,220p' reports/shadows/v2/shadow_v2_34_projected_building_shadow_micro_visual_artifact.md
sed -n '1,220p' reports/shadows/v2/shadow_v2_31_projected_building_shadow_visual_calibration_design.md
sed -n '1,220p' reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
node - <<'NODE'
// Calcul read-only des bounds et points candidats.
NODE
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests lancés :

```text
Aucun. Le lot est design-only et aucun fichier de code/test n'a été modifié.
```

## 21. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant création du rapport :

```text

```

Sortie finale attendue :

```text

```

Interprétation :

```text
Le rapport Lot 35 est non suivi, donc git diff --stat ne l'affiche pas.
```

## 22. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie avant création du rapport :

```text

```

Sortie finale attendue :

```text

```

Interprétation :

```text
Aucun fichier suivi n'est modifié.
```

## 23. git diff --check

Commande :

```bash
git diff --check
```

Sortie attendue :

```text

```

Interprétation :

```text
git diff --check est propre.
```

## 24. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale attendue :

```text
?? reports/shadows/v2/shadow_v2_35_projected_building_shadow_shape_banding_review_design.md
```

Interprétation :

```text
Le seul fichier créé par ShadowV2-35 est le rapport demandé.
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
- [x] Artifact Lot 34 audité
- [x] Géométrie actuelle auditée
- [x] Banding actuel audité
- [x] Cible Pokémon-like comparée
- [x] Diagnostic principal explicite
- [x] Options comparées
- [x] Option recommandée unique
- [x] Plan ShadowV2-36 précis
- [x] Variantes candidates proposées
- [x] Fichiers interdits au Lot 36 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
