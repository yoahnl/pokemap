# ShadowV2-44 — Projected Building Shadow Footprint Visual Review / Calibration Decision Gate

## 1. Résumé exécutif

Conclusion : Footprint V0 est nettement meilleur que Directional V0 pour l'intention Pokémon-like, mais il ne doit pas encore être déclaré final.

L'artifact Lot 43 montre que Directional V0 lit encore comme une languette diagonale, alors que Footprint V0 lit comme une masse courte, large et attachée au bâtiment. La colonne C est la preuve la plus utile : le bâtiment recouvre la partie haute de l'ombre, la bande visible sous le volume donne un meilleur effet de poids au sol.

Option recommandée : **Option B — créer une matrice de variantes footprint**. Le prochain lot doit comparer plusieurs calibrations Footprint V0 dans une image contrôlée, sans modifier le modèle, sans modifier renderer/painter, sans baseline, sans Selbrume et sans JSON.

## 2. Objectif du lot

Objectif exact :

```text
Analyser l'artifact visuel ShadowV2-43,
décider si Footprint V0 est la bonne direction visuelle,
identifier précisément ce qui doit être calibré,
puis préparer un Lot 45 strictement borné.
```

Ce lot est design-only. Il ne code rien, ne crée aucune image, ne modifie pas l'artifact Lot 43 et ne crée aucune baseline.

Questions tranchées :

```text
1. Footprint V0 est-il meilleur que Directional V0 ? Oui.
2. Footprint V0 est-il suffisamment proche de la référence Pokémon-like ? Prometteur, mais pas final.
3. Quels paramètres doivent être ajustés ? attachYRatio, depthRatio, front/rearWidthRatio, skewXRatio, opacity.
4. Faut-il créer une matrice de variantes footprint ? Oui.
5. Faut-il changer le modèle Footprint V0 ? Non.
6. Faut-il toucher au renderer/painter ? Non.
7. Faut-il déjà parler de JSON/persistence ? Non, seulement comme risque séparé.
8. Quel doit être le prochain lot ? ShadowV2-45 — Projected Building Shadow Footprint Candidate Matrix Artifact V0.
```

## 3. Rappel ShadowV2-40 à ShadowV2-43

ShadowV2-40 a ajouté le core Footprint V0 dans `map_core` :

```text
geometryMode: footprint
ProjectedShadowFootprintTuning()
attachYRatio = 0.86
frontWidthRatio = 1.10
rearWidthRatio = 1.20
depthRatio = 0.28
skewXRatio = 0.10
opacity = 0.28
colorHexRgb = 606060
```

Micro-fixture core :

```text
frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)
```

ShadowV2-42 a prouvé par tests runtime/editor que Footprint V0 traverse les adapters existants in-memory sans modification de production.

ShadowV2-43 a produit l'artifact :

```text
reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
```

Image :

```text
width = 480
height = 256
A = Directional V0 + building
B = Footprint V0 only
C = Footprint V0 + building
```

Pipeline Lot 43 :

```text
ProjectBuildingShadowPreset
+ ProjectElementProjectedBuildingShadowConfig
+ StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
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

Fichiers préexistants avant ShadowV2-44 :

```text
Aucun fichier modifié ou non suivi détecté par git status initial.
```

Fichiers créés par ShadowV2-44 :

```text
reports/shadows/v2/shadow_v2_44_projected_building_shadow_footprint_visual_review_calibration_decision.md
```

Fichiers modifiés par ShadowV2-44 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-44 :

```text
Aucun
```

Fichiers hors scope déjà présents :

```text
Aucun fichier hors scope modifié ou non suivi dans l'état initial.
```

Problèmes introduits par ShadowV2-44 :

```text
Aucun connu.
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
Des skills Dart/Flutter génériques existent dans l'environnement, mais le lot est design-only et interdit les tests.
Le serveur Dart MCP est disponible, mais il n'a pas été utilisé car le Lot 44 ne doit lancer aucun test.
```

Sub-agents utilisés :

```text
1. Visual Review sub-agent : utilisé.
2. Flutter/Dart Artifact Audit sub-agent : utilisé.
3. Calibration Design sub-agent : utilisé.
4. Evidence/report sub-agent : non lancé, limite de threads atteinte ; passe équivalente faite localement.
```

Synthèse des sub-agents :

```text
Visual Review :
- Directional V0 lit comme une languette diagonale.
- Footprint only est plus court, large, posé au sol.
- Footprint + building est la lecture la plus convaincante.
- Footprint V0 est prometteur mais pas final.

Flutter/Dart Artifact Audit :
- Le harness Lot 43 utilise bien resolveProjectedBuildingShadowGeometry -> createProjectedBuildingShadowRuntimeInstruction -> ShadowRuntimeRenderer.renderCollectionPass.
- L'artifact n'est pas une baseline/golden.
- Le harness ne dépend pas de Selbrume.
- L'image est adaptée à une revue humaine micro, avec limites documentées.

Calibration Design :
- Recommande une matrice de variantes, pas une propagation directe.
- Rejette renderer/painter, JSON et author-defined polygon pour ce lot.
- Confirme que Footprint V0 doit rester témoin/benchmark.
```

## 6. Décision AGENTS / design gate

L'AGENTS.md impose de préserver le scope des lots, de ne pas élargir seul, de garder les changements minimaux, de documenter les rapports avec preuves, et de ne pas invoquer d'action d'implémentation avant design approuvé sur les sujets product-facing.

Décision :

```text
ShadowV2-44 reste un design gate pur.
Un seul fichier rapport est créé.
Aucun code, test, screenshot, baseline, renderer, painter, map_core, map_runtime, map_editor ou Selbrume n'est modifié.
```

AGENTS trouvé :

```text
../pokemonProject/AGENTS.md
```

Extraits d'audit AGENTS pertinents :

```text
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
860:1. Use `superpowers:subagent-driven-development` when applicable.
861:2. Dispatch one fresh subagent per task.
862:3. Each subagent implements, tests, reports final git status, and self-reviews.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

## 7. Fichiers audités

Fichiers audités en lecture seule :

```text
reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
reports/shadows/v2/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
reports/shadows/v2/shadow_v2_40_projected_building_shadow_footprint_geometry_core_v0.md
```

Commandes d'audit utilisées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
file reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
rg -n "ProjectedShadowFootprintTuning|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|ProjectedBuildingShadowGeometryMode.footprint|resolveProjectedBuildingShadowGeometry|frontLeft|frontRight|rearRight|rearLeft" packages/map_core/lib packages/map_core/test reports/shadows/v2
rg -n "shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact|Directional V0|Footprint V0|Footprint only|Footprint \+ building|opacity 0.28|606060|banding|Pokémon-like|Pokemon-like" reports/shadows/v2 packages/map_runtime/tool
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 8. Audit artifact Lot 43

Métadonnées PNG :

```text
reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png: PNG image data, 480 x 256, 8-bit/color RGBA, non-interlaced
-rw-r--r--@ 1 karim  staff   2.6K May 21 23:36 reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
ee13ddc8701d8b540ed4e23daa2468939ee9afaa2421ecf63f2bbeae6d4ccf32  reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
```

Colonnes observées :

```text
A — Directional V0 reference + building
B — Footprint V0 only
C — Footprint V0 + building
```

Pipeline confirmé dans le harness Lot 43 :

```text
resolveProjectedBuildingShadowGeometry importé et appelé.
createProjectedBuildingShadowRuntimeInstruction appelé via helper d'instruction.
ShadowRuntimeRenderer().renderCollectionPass(...) appelé pour rendre les passes.
ProjectedBuildingShadowGeometryMode.footprint et ProjectedShadowFootprintTuning() utilisés.
```

Preuves ligne par ligne relevées par audit :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart:22 imports resolveProjectedBuildingShadowGeometry.
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart:211 appelle ShadowRuntimeRenderer().renderCollectionPass(...).
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart:232 appelle createProjectedBuildingShadowRuntimeInstruction(...).
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart:241 appelle resolveProjectedBuildingShadowGeometry(...).
```

Limites de l'image :

```text
Micro-fixture seulement.
Bâtiment simplifié.
Pas Selbrume.
Pas asset réel.
Pas baseline.
Pas validation artistique finale.
Banding visible mais non isolé dans une matrice.
```

Lecture visuelle provisoire :

```text
Footprint V0 est une meilleure direction que Directional V0.
La colonne C est suffisamment prometteuse pour justifier une matrice de calibrations footprint.
L'image ne suffit pas à choisir une calibration finale.
```

## 9. Analyse Directional V0

Directional V0 reste utile comme référence négative.

Constat visuel :

```text
La forme part en diagonale vers bas-droite.
La masse est trop étroite par rapport au bâtiment.
L'ombre lit comme une projection directionnelle / languette.
Le lien avec le pied du bâtiment est moins convaincant.
```

Réponse à la question direction :

```text
Footprint V0 lit mieux que Directional V0.
```

Pourquoi :

```text
Directional V0 met en avant la direction du rayon.
Footprint V0 met en avant l'emprise au sol.
La cible utilisateur demande une masse attachée, pas une forme lancée en biais.
```

## 10. Analyse Footprint V0 only

Footprint only montre la forme brute.

Constat visuel :

```text
La forme est courte, large et posée.
Le skew reste discret.
Le rendu lit plus comme une emprise au sol que comme un rayon projeté.
La forme isolée reste très géométrique.
Le banding est visible sous forme de bandes horizontales / hard-edge.
```

Ce que la colonne B permet de juger :

```text
largeur : probablement dans la bonne zone, mais à comparer avec plus large ;
profondeur : correcte à prometteuse, mais peut-être un peu courte pour certains bâtiments ;
skew : assez faible pour ne pas redevenir languette ;
banding : visible, mais secondaire tant que la calibration de forme n'est pas choisie.
```

## 11. Analyse Footprint V0 + building

Footprint + building est la lecture principale du Lot 43.

Constat visuel :

```text
Le bâtiment se dessine au-dessus de l'ombre.
La partie haute de l'ombre passe sous le volume.
La partie visible sous le bâtiment donne une sensation de poids au sol.
L'ombre paraît plus attachée que Directional V0.
Le côté droit dépasse légèrement, ce qui donne une direction bas-droite sans effet languette.
```

Analyse d'attachement :

```text
front edge actuel : y = 146.56.
bottom bâtiment micro-fixture : y = 160.00.
rear edge actuel : y = 173.44.
La moitié haute de l'ombre est donc sous le bâtiment, et la moitié basse reste visible.
```

Décision :

```text
L'attachement est suffisamment bon pour continuer avec Footprint V0.
Il n'est pas assez prouvé pour figer les paramètres.
```

## 12. Analyse des paramètres actuels

Valeurs actuelles :

```text
attachYRatio = 0.86
frontWidthRatio = 1.10
rearWidthRatio = 1.20
depthRatio = 0.28
skewXRatio = 0.10
opacity = 0.28
colorHexRgb = 606060
```

Formule footprint actuelle :

```text
centerX = metrics.left + metrics.visualWidth * 0.5 + config.localOffset.x
frontY = metrics.top + metrics.visualHeight * footprint.attachYRatio + config.localOffset.y
frontWidth = metrics.visualWidth * footprint.frontWidthRatio
rearWidth = metrics.visualWidth * footprint.rearWidthRatio
depth = metrics.visualHeight * footprint.depthRatio
rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio
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

Micro-fixture actuelle :

```text
metrics.left = 32
metrics.top = 64
metrics.visualWidth = 64
metrics.visualHeight = 96

frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)

bounds.left = 28.80
bounds.top = 146.56
bounds.width = 80.00
bounds.height = 26.88
```

Paramètres à explorer :

```text
attachYRatio :
- actuel 0.86 prometteur ;
- explorer 0.80 à 0.84 pour une ombre plus haute / plus sous le volume ;
- explorer avec prudence, car trop haut peut salir le bâtiment.

frontWidthRatio :
- actuel 1.10 fonctionne ;
- explorer 1.22 à 1.30 pour un socle plus large.

rearWidthRatio :
- actuel 1.20 fonctionne ;
- explorer 1.25 à 1.42 pour renforcer la masse arrière.

depthRatio :
- actuel 0.28 fonctionne ;
- explorer 0.30 à 0.36 pour plus de présence ;
- explorer aussi une option 0.26 large et sobre.

skewXRatio :
- actuel 0.10 discret et acceptable ;
- explorer 0.08 pour réduire la direction ;
- explorer 0.18 pour vérifier si une direction bas-droite plus lisible reste non-languette.

opacity :
- actuel 0.28 lisible ;
- explorer 0.24 à 0.27 sur les variantes plus larges pour éviter une plaque sale.

colorHexRgb :
- garder 606060 pour la matrice ;
- ne pas mélanger calibration couleur et géométrie sauf variantes où l'opacité compense la largeur.
```

Banding :

```text
Le banding reste visible.
Il devient plus perceptible parce que la forme est meilleure et plus large.
Il reste secondaire pour le Lot 45 : comparer les variantes footprint d'abord, puis décider si renderer/painter doivent être audités.
```

## 13. Options étudiées

### Option A — Garder Footprint V0 actuel

Analyse :

```text
Pour :
- déjà meilleur que Directional V0 ;
- stable ;
- validé core/adapters/artifact micro.

Contre :
- une seule image ne suffit pas à figer une calibration ;
- la forme isolée reste mécanique ;
- banding et profondeur doivent être jugés sur plusieurs profils.
```

Décision : rejetée comme décision finale, conservée comme témoin.

### Option B — Créer une matrice de variantes footprint

Analyse :

```text
Pour :
- répond exactement à la question visuelle restante ;
- ne change pas le modèle ;
- ne change pas renderer/painter ;
- ne touche pas JSON/Selbrume ;
- évite de répéter l'erreur Candidate C, choisie trop vite dans un espace trop restreint.

Contre :
- demande un artifact supplémentaire ;
- ne rend pas encore Footprint V0 persistable dans project.json.
```

Décision : recommandée.

### Option C — Ajuster directement les tests/calibration

Analyse :

```text
Pour :
- plus rapide.

Contre :
- prématuré ;
- confond preuve micro et calibration finale ;
- risque de choisir une valeur "moins mauvaise" sans comparaison.
```

Décision : rejetée.

### Option D — Modifier renderer/painter / banding

Analyse :

```text
Pour :
- le banding est visible.

Contre :
- Footprint V0 utilise déjà projectedPolygon ;
- la forme doit d'abord être calibrée ;
- modifier renderer/painter changerait le sujet du lot.
```

Décision : rejetée pour Lot 45.

### Option E — Author-defined polygon / asset shadow

Analyse :

```text
Pour :
- meilleur contrôle artistique long terme.

Contre :
- beaucoup plus lourd ;
- demande modèle/persistence/UI/authoring ;
- prématuré tant que le footprint paramétrique est prometteur.
```

Décision : rejetée maintenant.

### Option F — JSON / persistence maintenant

Analyse :

```text
Pour :
- nécessaire avant vraie utilisation project.json/Selbrume.

Contre :
- ne répond pas à "est-ce beau ?" ;
- risque de persister un profil non choisi ;
- doit venir après décision visuelle.
```

Décision : rejetée maintenant.

## 14. Variantes footprint recommandées

La matrice Lot 45 doit inclure au minimum ces six candidats. Candidate A est le témoin actuel.

### Candidate A — Current Footprint V0

```text
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
expected: témoin actuel, mieux que Directional V0 mais pas final.
```

### Candidate B — Deeper footprint

```text
attachYRatio: 0.84
frontWidthRatio: 1.10
rearWidthRatio: 1.22
depthRatio: 0.36
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
expected: plus visible derrière le bâtiment, plus de masse.
```

### Candidate C — Wider footprint

```text
attachYRatio: 0.86
frontWidthRatio: 1.22
rearWidthRatio: 1.35
depthRatio: 0.30
skewXRatio: 0.10
opacity: 0.26
colorHexRgb: 606060
expected: plus large, plus proche référence, moins sale grâce à opacity 0.26.
```

### Candidate D — Higher attached footprint

```text
attachYRatio: 0.80
frontWidthRatio: 1.12
rearWidthRatio: 1.25
depthRatio: 0.32
skewXRatio: 0.10
opacity: 0.27
colorHexRgb: 606060
expected: plus attachée sous le volume, moins "bande basse".
```

### Candidate E — Stronger skew footprint

```text
attachYRatio: 0.84
frontWidthRatio: 1.12
rearWidthRatio: 1.25
depthRatio: 0.32
skewXRatio: 0.18
opacity: 0.27
colorHexRgb: 606060
expected: direction bas-droite plus lisible sans redevenir languette.
```

### Candidate F — Broad shallow Pokémon-like

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
expected: masse large et sobre, à comparer au risque plaque.
```

Pourquoi ces variantes :

```text
A garde le témoin actuel.
B isole la profondeur.
C isole la largeur.
D teste une attache plus haute.
E teste la direction bas-droite.
F teste l'hypothèse "large mais peu profonde", très proche d'un socle Pokémon-like.
```

## 15. Option recommandée

Option recommandée : **Option B — Créer une matrice de variantes footprint**.

Diagnostic visuel :

```text
Directional V0 :
- trop directionnel ;
- trop languette ;
- moins attaché ;
- utile seulement comme référence comparative.

Footprint V0 only :
- meilleur langage de forme ;
- court, large, dur, gris ;
- encore mécanique isolé ;
- banding visible.

Footprint V0 + building :
- meilleur panneau de l'artifact ;
- ombre attachée au pied / sous le volume ;
- plus proche Pokémon-like ;
- prometteur mais non final.
```

Paramètres à explorer :

```text
attachYRatio : explorer 0.80, 0.82, 0.84, 0.86.
frontWidthRatio : explorer 1.10, 1.12, 1.22, 1.30.
rearWidthRatio : explorer 1.20, 1.22, 1.25, 1.35, 1.42.
depthRatio : explorer 0.26, 0.28, 0.30, 0.32, 0.36.
skewXRatio : explorer 0.08, 0.10, 0.18.
opacity : explorer 0.24 à 0.28 selon largeur.
colorHexRgb : garder 606060.
```

Pourquoi :

```text
Footprint V0 a déplacé le problème du modèle vers la calibration.
Le prochain apprentissage doit être visuel.
Une matrice évite de choisir trop vite une calibration unique.
Le renderer/painter existant suffit pour comparer les formes.
```

Pourquoi les autres options sont rejetées :

```text
Option A : trop tôt pour figer le V0.
Option C : trop tôt pour propager une calibration.
Option D : banding secondaire tant que la forme n'est pas choisie.
Option E : trop lourde et prématurée.
Option F : nécessaire plus tard, pas avant la décision visuelle.
```

Lot 45 doit faire :

```text
Créer une matrice visuelle Footprint V0 avec les candidats A-F.
Utiliser le pipeline resolver -> adapter -> renderer.
Inclure une référence Directional V0 si l'espace le permet.
Afficher footprint only et footprint + building pour chaque candidat.
Écrire un seul PNG artifact contrôlé.
Créer un rapport d'evidence complet.
Ne pas créer de baseline.
```

Lot 45 ne doit pas faire :

```text
Modifier map_core.
Modifier map_runtime/lib.
Modifier map_editor.
Modifier renderer/painter.
Modifier JSON/codecs/project.json.
Toucher Selbrume.
Créer une baseline/golden.
Choisir une calibration finale sans revue.
```

## 16. Plan précis du Lot 45

Nom recommandé :

```text
ShadowV2-45 — Projected Building Shadow Footprint Candidate Matrix Artifact V0
```

Objectif :

```text
Générer une matrice visuelle comparant plusieurs calibrations Footprint V0,
sans modifier le modèle,
sans modifier renderer/painter,
sans baseline,
sans Selbrume,
pour choisir une calibration footprint officielle ou presque officielle.
```

Fichiers probables à créer :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
```

Périmètre technique :

```text
Harness manuel sous packages/map_runtime/tool/shadow.
PNG sous reports/shadows/screenshots.
Rapport sous reports/shadows/v2.
Pas de modification de production.
Pas de modification de test existant.
Pas de baseline.
```

Pipeline à utiliser :

```text
ProjectBuildingShadowPreset
+ ProjectElementProjectedBuildingShadowConfig
+ StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

Contenu recommandé de l'image :

```text
Candidate A-F.
Pour chaque candidate : footprint only + footprint + building.
Ajouter Directional V0 comme référence séparée si la composition reste lisible.
Garder le même bâtiment micro-fixture que Lot 43.
Garder fond/grille constants pour comparaison.
```

Commandes à prévoir :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
```

## 17. Fichiers explicitement interdits au Lot 45

Fichiers et dossiers interdits :

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

Interdictions spécifiques :

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
ProjectManifest codecs
project.json
```

Ne pas créer :

```text
baseline
golden
fixture Selbrume
asset
shader
blur
nouveau renderer
nouveau painter
nouveau modèle
nouveau codec
migration
UI authoring
```

## 18. Risques / réserves

Risques :

```text
Le micro-building simplifié peut favoriser Footprint V0 plus qu'un vrai asset.
Le banding peut devenir plus visible sur des variantes plus larges.
Une calibration large peut devenir une plaque grise si l'opacité reste trop forte.
Une calibration profonde ou skewée peut revenir vers une lecture "ombre projetée".
JSON/persistence reste non traité pour une vraie utilisation project.json.
Selbrume n'est pas encore testé visuellement.
```

Réserves :

```text
Le Lot 44 ne valide pas une calibration finale.
Il valide seulement que Footprint V0 mérite une matrice dédiée.
Le renderer/painter ne doivent être reconsidérés qu'après comparaison des variantes.
```

## 19. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Aucun code, test, screenshot, baseline ou fichier de production n'est modifié. Le seul fichier créé est ce rapport.
```

La revue visuelle est-elle honnête ?

```text
Oui. Elle reconnaît que Footprint V0 est meilleur que Directional V0, mais refuse de le déclarer final.
```

Le rapport évite-t-il de déclarer Footprint V0 final trop tôt ?

```text
Oui. L'option recommandée est une matrice de variantes, pas une propagation directe.
```

Les paramètres à ajuster sont-ils clairement identifiés ?

```text
Oui : attachYRatio, frontWidthRatio, rearWidthRatio, depthRatio, skewXRatio, opacity ; colorHexRgb reste stable.
```

Les variantes proposées sont-elles assez différentes pour apprendre quelque chose ?

```text
Oui. Elles isolent profondeur, largeur, attache verticale, skew et profil large peu profond.
```

Le plan Lot 45 évite-t-il production / Selbrume / baseline ?

```text
Oui. Le plan est artifact-only, sans production, sans Selbrume, sans baseline.
```

Le rapport contient-il toutes les preuves ?

```text
Oui : état git initial, audit AGENTS, métadonnées PNG, pipeline Lot 43, analyse visuelle A/B/C, options, variantes, plan Lot 45, git diff/status final.
```

## 20. Regard critique sur le prompt

Le prompt est strict et utile : il force la distinction entre progrès visuel et validation finale. Il évite deux pièges importants :

```text
1. déclarer Footprint V0 final parce qu'il est meilleur que Directional V0 ;
2. attaquer le banding / renderer avant d'avoir comparé les formes.
```

Point de vigilance :

```text
Le prompt demande des sub-agents, mais l'environnement a atteint la limite de threads au quatrième agent.
La passe Evidence/report a donc été faite localement et documentée.
```

Le prochain prompt Lot 45 devrait préciser :

```text
- taille et organisation de la matrice ;
- whether Directional V0 reference is mandatory or optional ;
- pixels / assertions minimales ;
- si les opacités candidates doivent être figées ou testées ;
- si une analyse visuelle humaine post-image est incluse ou reportée au Lot 46.
```

## 21. Commandes lancées

```bash
sed -n '1,220p' /Users/karim/.codex/skills/karpathy-guidelines/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/verification-before-completion/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/subagent-driven-development/SKILL.md
sed -n '1,180p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/using-superpowers/SKILL.md
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
file reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.png
rg -n "ProjectedShadowFootprintTuning|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|ProjectedBuildingShadowGeometryMode.footprint|resolveProjectedBuildingShadowGeometry|frontLeft|frontRight|rearRight|rearLeft" packages/map_core/lib packages/map_core/test reports/shadows/v2
rg -n "shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact|Directional V0|Footprint V0|Footprint only|Footprint \+ building|opacity 0.28|606060|banding|Pokémon-like|Pokemon-like" reports/shadows/v2 packages/map_runtime/tool
rg -n -C 3 "final class ProjectedShadowFootprintTuning|attachYRatio = 0.86|frontWidthRatio = 1.10|rearWidthRatio = 1.20|depthRatio = 0.28|skewXRatio = 0.10" packages/map_core/lib/src/models/projected_building_shadow.dart
rg -n -C 3 "_resolveFootprintProjectedBuildingShadowGeometry|frontY =|frontWidth =|rearWidth =|depth =|rearCenterX =|frontLeft|rearRight" packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
rg -n -C 2 "resolveProjectedBuildingShadowGeometry|createProjectedBuildingShadowRuntimeInstruction|ShadowRuntimeRenderer|renderCollectionPass|matchesGoldenFile|reports/shadows/baselines|selbrume" packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
rg -n -C 2 "Analyse visuelle provisoire|Directional V0 reference|Footprint V0 rendered|pipeline|480 x 256|ee13ddc|All tests passed|No issues found" reports/shadows/v2/shadow_v2_43_projected_building_shadow_footprint_micro_visual_artifact.md
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests lancés :

```text
Aucun. Le Lot 44 est design-only et interdit de lancer les tests.
```

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
(no output)
```

Note :

```text
Le rapport Lot 44 est non suivi, donc il apparaît dans git status mais pas dans git diff --stat.
```

## 23. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
(no output)
```

Note :

```text
Le rapport Lot 44 est non suivi, donc il apparaît dans git status mais pas dans git diff --name-status.
```

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
(no output)
```

Résultat :

```text
Propre.
```

## 25. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
?? reports/shadows/v2/shadow_v2_44_projected_building_shadow_footprint_visual_review_calibration_decision.md
```

Conformité scope :

```text
Conforme. Le seul fichier visible dans le status final est le rapport Lot 44 créé par ce lot.
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
- [x] Artifact Lot 43 audité
- [x] Directional V0 analysé
- [x] Footprint V0 only analysé
- [x] Footprint V0 + building analysé
- [x] Paramètres footprint analysés
- [x] Options comparées
- [x] Option recommandée unique
- [x] Variantes footprint précises
- [x] Plan ShadowV2-45 précis
- [x] Fichiers interdits au Lot 45 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
