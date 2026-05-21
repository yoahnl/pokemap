# ShadowV2-46 — Projected Building Shadow Footprint Calibration Selection Design Gate

## 1. Résumé exécutif

Lot exécuté : **ShadowV2-46 — Projected Building Shadow Footprint Calibration Selection Design Gate**.

Conclusion :

```text
Option recommandée : Option A — sélectionner F exact.
Calibration retenue : pokemon-building-shadow-footprint-v1.
F — Broad shallow est le meilleur candidat de la matrice Lot 45.
F est retenu tel quel, sans hybride F/C ni F/D.
Lot 47 doit propager cette calibration en preset test/fixture explicite.
Lot 47 ne doit pas modifier les defaults core ProjectedShadowFootprintTuning().
Lot 47 ne doit pas traiter JSON, Selbrume, renderer, painter, baseline ou screenshot.
```

Pourquoi :

```text
F donne la lecture la plus proche de la cible Pokémon-like :
large, courte, sobre, grise, peu directionnelle, attachée sous le bâtiment.
C est intéressant mais plus visible et plus "ombre ajoutée".
D est intéressant pour l'attachement mais moins large et plus caché sous le sprite.
Un hybride F/C ou F/D n'a pas été visualisé dans la matrice ; le retenir maintenant introduirait une calibration non prouvée.
```

## 2. Objectif du lot

Objectif exact :

```text
Analyser visuellement la matrice ShadowV2-45,
choisir officiellement la meilleure calibration Footprint V0,
ou définir une ultime micro-variante précise,
puis préparer un Lot 47 strictement borné pour propager cette calibration.
```

Ce lot est design-only :

```text
Aucun code.
Aucun test.
Aucune image.
Aucune baseline.
Aucune modification de production.
Aucune modification Selbrume.
Un seul rapport Markdown créé.
```

## 3. Rappel ShadowV2-43 à ShadowV2-45

ShadowV2-43 :

```text
Artifact micro 480x256 créé.
Colonnes : Directional V0, Footprint only, Footprint + building.
Pipeline : resolveProjectedBuildingShadowGeometry(...) -> createProjectedBuildingShadowRuntimeInstruction(...) -> ShadowRuntimeRenderer.renderCollectionPass(...).
Conclusion : Footprint V0 est meilleur que Directional V0, mais non final.
```

ShadowV2-44 :

```text
Design gate de revue visuelle.
Décision : ne pas figer Footprint V0.
Recommandation : créer une matrice A-F de variantes footprint.
Renderer, painter, JSON, Selbrume et baselines restent hors scope.
```

ShadowV2-45 :

```text
Artifact candidate matrix 1120x480 créé.
Colonnes : R | A | B | C | D | E | F.
Ligne 1 : shadow-only.
Ligne 2 : shadow + building.
Pipeline réel runtime utilisé.
Conclusion provisoire : F semble être le meilleur candidat ; C et D restent intéressants.
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

Fichiers préexistants avant ShadowV2-46 :

```text
Aucun fichier modifié ou non suivi au départ.
```

Fichiers Lot 45 audités et déjà présents au début du Lot 46 :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
```

Fichiers créés par ShadowV2-46 :

```text
reports/shadows/v2/shadow_v2_46_projected_building_shadow_footprint_calibration_selection_design.md
```

Fichiers modifiés par ShadowV2-46 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-46 :

```text
Aucun
```

Fichiers hors scope déjà présents :

```text
Aucun fichier modifié ou non suivi au départ.
Les artifacts Lot 45 sont des fichiers suivis / présents dans le dépôt au moment du Lot 46.
```

Problèmes introduits par ShadowV2-46 :

```text
Aucun identifié.
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
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté dans la liste des skills disponibles.
Des skills Dart/Flutter génériques existent, mais aucun skill Google spécifique n'a été détecté.
```

Sub-agents utilisés :

```text
Visual Review sub-agent : utilisé.
Calibration Decision sub-agent : utilisé.
Scope / Architecture sub-agent : utilisé.
Evidence/report sub-agent : passe équivalente faite localement.
```

Synthèse Visual Review sub-agent :

```text
Classement proposé : F > D > C > A > B > E > R.
F est le meilleur candidat visuel.
C est un bon comparatif de largeur.
D est un bon comparatif d'attachement.
R est à rejeter pour les bâtiments.
Le sub-agent a noté qu'un F/D hybrid pourrait être intéressant, mais seulement comme piste.
```

Synthèse Calibration Decision sub-agent :

```text
Recommandation : retenir F exact.
Justification : F couvre déjà la cible ; créer un hybride non visualisé serait moins prouvé que la matrice.
```

Synthèse Scope / Architecture sub-agent :

```text
Le sub-agent a signalé le risque de garder deux defaults concurrents si les tests continuent à utiliser ProjectedShadowFootprintTuning().
La décision retenue pour Lot 47 est de ne pas changer le default core immédiatement, mais d'éviter l'ambiguïté en utilisant un tuning explicite dans le preset officiel V1.
JSON, Selbrume, renderer et painter restent hors scope.
```

Pourquoi la passe evidence/report est locale :

```text
Le lot ne doit créer qu'un seul rapport.
La passe finale de preuve a donc été gardée dans le thread principal pour contrôler exactement le fichier créé et l'état git final.
```

## 6. Décision AGENTS / design gate

AGENTS.md rappelle notamment :

```text
Le dépôt est un monorepo Dart/Flutter.
Les packages purs ne doivent pas importer Flutter ou Flame.
Les lots doivent rester minimaux et factuels.
Les rapports doivent inclure inventaire, commandes, preuves, limites et auto-review.
Les opérations git d'écriture sont interdites sans demande explicite.
Les skills doivent être consultés avant d'agir.
Les travaux créatifs / product-facing doivent passer par un design avant implémentation.
```

Décision d'exécution :

```text
ShadowV2-46 est un design gate, pas une implémentation.
Aucune commande de test n'a été lancée.
Aucun script screenshot n'a été lancé.
Aucun fichier de production n'a été modifié.
Aucun artifact Lot 45 n'a été modifié.
```

## 7. Fichiers audités

Fichiers obligatoires audités en lecture seule :

```text
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
reports/shadows/v2/shadow_v2_44_projected_building_shadow_footprint_visual_review_calibration_decision.md
```

Sources utilisées :

```text
Méta PNG : file, ls -lh, shasum -a 256.
Paramètres candidats : harness Lot 45.
Points et bounds : rapport Lot 45, section "Géométries / points générés par candidat".
Analyse visuelle : image affichée dans l'environnement Codex.
Contraintes de scope : AGENTS.md et prompt Lot 46.
```

## 8. Audit artifact Lot 45

Commande :

```bash
file reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Sortie :

```text
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png: PNG image data, 1120 x 480, 8-bit/color RGBA, non-interlaced
```

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
shasum -a 256 reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Sortie :

```text
76f4079a4cce27effc8aac9272894501ecec2324fba4d96654d4c318e5df9e99  reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Métadonnées :

```text
width = 1120
height = 480
format = PNG RGBA non-interlaced
taille = 8.6K
hash SHA-256 = 76f4079a4cce27effc8aac9272894501ecec2324fba4d96654d4c318e5df9e99
```

Présence des colonnes :

```text
R, A, B, C, D, E, F présents.
```

Présence des lignes :

```text
ligne 1 = shadow-only.
ligne 2 = shadow + building.
```

Pipeline Lot 45 confirmé :

```text
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeInstructionCollection(...)
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Limites de l'image :

```text
Micro-fixture unique.
Fond clair unique.
Bâtiment simple unique.
Pas une golden.
Pas une revue Selbrume.
Pas une validation artistique exhaustive sur tous les tilesets.
```

Lecture visuelle provisoire :

```text
R montre clairement l'ancien problème de languette directionnelle.
A est propre mais timide.
B devient plus profond et plus présent.
C améliore la largeur.
D améliore l'attachement.
E réintroduit trop de direction.
F donne le meilleur équilibre large / court / sobre.
```

## 9. Analyse R — Directional V0

Paramètres :

```text
geometryMode: directional
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
anchor: (0.5, 0.96)
opacity: 0.30
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Référence négative de l'ancien rendu directionnel.
```

Forces :

```text
Montre clairement la direction de projection.
Utile comme comparaison historique.
```

Faiblesses :

```text
Lit comme une languette diagonale.
N'a pas l'effet socle / emprise au sol.
Attire l'oeil par sa direction plutôt que soutenir le bâtiment.
```

Décision :

```text
Rejeté pour bâtiments.
À conserver seulement comme référence négative ou fallback directionnel pour d'autres cas.
```

## 10. Analyse A — Current Footprint

Paramètres :

```text
attachYRatio: 0.86
frontWidthRatio: 1.10
rearWidthRatio: 1.20
depthRatio: 0.28
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Témoin Footprint V0 actuel.
```

Forces :

```text
Propre.
Court.
Déjà meilleur que R.
Compatible avec la cible footprint.
```

Faiblesses :

```text
Trop prudent.
Largeur encore timide pour soutenir visuellement le bâtiment.
Attachement moins convaincant que D.
Masse moins sobre et moins large que F.
```

Décision :

```text
Rejeté comme calibration finale.
Conserver comme baseline historique Current Footprint V0.
```

## 11. Analyse B — Deeper

Paramètres :

```text
attachYRatio: 0.84
frontWidthRatio: 1.10
rearWidthRatio: 1.22
depthRatio: 0.36
skewXRatio: 0.10
opacity: 0.28
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Tester l'effet d'une ombre plus profonde.
```

Forces :

```text
Plus visible que A.
Donne davantage de masse arrière.
```

Faiblesses :

```text
Risque de plaque grise.
Profondeur plus dominante que l'intention Pokémon-like.
Moins sobre que F.
```

Décision :

```text
Rejeté.
La profondeur supplémentaire n'améliore pas autant que la largeur sobre de F.
```

## 12. Analyse C — Wider

Paramètres :

```text
attachYRatio: 0.86
frontWidthRatio: 1.22
rearWidthRatio: 1.35
depthRatio: 0.30
skewXRatio: 0.10
opacity: 0.26
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Tester une largeur accrue avec opacité réduite.
```

Forces :

```text
Bon candidat.
Largeur plus convaincante que A.
Reste assez court.
Opacity 0.26 limite la salissure.
```

Faiblesses :

```text
Le front reste plus bas que D ou F.
Lit un peu plus comme une ombre ajoutée que comme un socle discret.
Moins sobre que F.
```

Décision :

```text
Finaliste, mais non retenu.
À garder comme référence de largeur si F se révèle trop discret dans un futur contexte.
```

## 13. Analyse D — Higher

Paramètres :

```text
attachYRatio: 0.80
frontWidthRatio: 1.12
rearWidthRatio: 1.25
depthRatio: 0.32
skewXRatio: 0.10
opacity: 0.27
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Tester une attache plus haute sous le bâtiment.
```

Forces :

```text
Meilleure sensation d'ombre glissée sous le volume.
Attachement visuel convaincant dans la ligne shadow + building.
```

Faiblesses :

```text
Moins large que F et C.
Une partie importante peut être cachée sous le bâtiment.
Risque de devenir moins lisible sur sprites plus larges ou fonds plus chargés.
```

Décision :

```text
Finaliste d'attachement, mais non retenu.
F reprend assez d'attache tout en donnant une masse plus large et plus sobre.
```

## 14. Analyse E — Skew

Paramètres :

```text
attachYRatio: 0.84
frontWidthRatio: 1.12
rearWidthRatio: 1.25
depthRatio: 0.32
skewXRatio: 0.18
opacity: 0.27
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Tester une direction bas-droite plus visible.
```

Forces :

```text
Montre que le skew est contrôlable.
Peut être utile pour d'autres intentions plus directionnelles.
```

Faiblesses :

```text
Réintroduit une lecture de projection.
S'éloigne de la cible "emprise au sol".
Moins naturel que F pour les bâtiments Pokémon-like.
```

Décision :

```text
Rejeté.
Le skew plus fort va dans la mauvaise direction pour cette calibration.
```

## 15. Analyse F — Broad shallow

Paramètres :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

Géométrie :

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

Rôle :

```text
Tester une ombre large, peu profonde, moins opaque et très peu directionnelle.
```

Forces :

```text
Meilleure lecture de socle / footprint.
Plus large que C tout en restant plus courte.
Plus sobre grâce à opacity 0.24.
Skew 0.08 garde une légère orientation sans revenir vers une languette.
Dans la ligne shadow + building, le bâtiment lit au-dessus de l'ombre et l'ombre soutient le volume.
```

Faiblesses :

```text
Peut devenir trop discret sur certains fonds ou sous certains sprites.
La micro-fixture ne prouve pas encore tous les contextes de tileset.
Le banding du renderer reste visible, mais secondaire pour le Lot 47.
```

Décision :

```text
Retenu.
F exact devient la calibration footprint V1 recommandée.
```

## 16. Comparaison synthétique

Classement visuel retenu :

```text
F > C ~= D > A > B > E > R
```

Lecture par critère :

```text
Meilleur abandon de la languette : F.
Meilleure largeur : F, puis C.
Meilleur attachement strict : D, puis F.
Meilleure sobriété : F.
Meilleure lisibilité brute : C, puis F.
Plus mauvais retour à la projection : R et E.
Plus gros risque de plaque : B.
```

Réponse aux questions :

```text
1. Quel candidat est le meilleur ? F.
2. F — Broad shallow est-il le meilleur candidat ? Oui.
3. F doit-il être retenu tel quel ? Oui.
4. F doit-il être hybridé avec C ou D ? Non pour le Lot 47.
5. Faut-il modifier les defaults ProjectedShadowFootprintTuning ? Non au Lot 47.
6. Faut-il seulement modifier les fixtures/presets de test ? Oui au Lot 47.
7. Faut-il toucher au renderer/painter ? Non.
8. Faut-il traiter JSON/persistence maintenant ? Non.
9. Quel doit être le Lot 47 ? ShadowV2-47 — Projected Building Shadow Footprint Calibration V1 Test Fixtures.
```

## 17. F exact vs hybride

F exact :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

F/C hybrid considéré :

```text
attachYRatio: 0.82
frontWidthRatio: 1.28
rearWidthRatio: 1.38
depthRatio: 0.28
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

Analyse :

```text
L'hybride F/C augmenterait légèrement la profondeur et réduirait un peu la largeur.
Il pourrait améliorer la visibilité si F est trop discret.
Mais il n'a pas été rendu dans la matrice.
C exact montre déjà que plus de profondeur / présence rend l'ombre plus "ajoutée".
```

F/D hybrid considéré :

```text
attachYRatio: 0.80
frontWidthRatio: 1.26
rearWidthRatio: 1.36
depthRatio: 0.28
skewXRatio: 0.08
opacity: 0.25
colorHexRgb: 606060
```

Analyse :

```text
L'hybride F/D remonterait encore l'attache et augmenterait légèrement l'opacité.
Il pourrait renforcer la lecture sous le bâtiment.
Mais D exact montre déjà le risque d'une ombre plus cachée et moins large.
```

Décision :

```text
Choisir F exact.
Un hybride serait une calibration non visualisée.
Le Lot 45 a produit une matrice pour choisir parmi des images réellement rendues ; le Lot 46 ne doit pas contourner cette preuve.
```

## 18. Default core vs preset-only

Question :

```text
La calibration retenue doit-elle devenir le default ProjectedShadowFootprintTuning(),
ou seulement un preset officiel dans les tests/fixtures ?
```

Décision :

```text
Preset-only pour le Lot 47.
Ne pas modifier les defaults ProjectedShadowFootprintTuning() au Lot 47.
```

Justification :

```text
Modifier les defaults core est une modification de production map_core.
Le Lot 47 recommandé est un lot de propagation test/fixture, pas un lot de changement de contrat core.
Un preset officiel pokemon-building-shadow-footprint-v1 peut porter explicitement les valeurs F sans changer le constructeur générique.
Les defaults actuels restent le témoin Footprint V0 tant qu'un lot core dédié ne décide pas leur remplacement.
```

Réserve :

```text
Le Scope / Architecture sub-agent a signalé un vrai risque : si les tests continuent à utiliser ProjectedShadowFootprintTuning() sans arguments, deux defaults implicites coexisteront.
La mitigation du Lot 47 doit être stricte :
utiliser ProjectedShadowFootprintTuning(...) avec les valeurs F explicites pour pokemon-building-shadow-footprint-v1,
et ne pas appeler ProjectedShadowFootprintTuning() quand l'intention est la calibration officielle V1.
```

JSON/persistence :

```text
Non pour le Lot 47.
La persistance devra être traitée avant Selbrume / project.json réel, mais elle ne répond pas à la sélection visuelle.
```

Renderer/painter :

```text
Non.
Le banding reste visible, mais le Lot 47 doit propager la calibration, pas changer le rendu.
```

## 19. Options étudiées

### Option A — Sélectionner F exact

Analyse :

```text
Meilleur candidat de la matrice.
Large, court, sobre, peu directionnel.
Opacity 0.24 réduit la salissure.
Risque : peut être trop discret sur certains fonds.
```

Décision :

```text
Retenue.
```

### Option B — Sélectionner C exact

Analyse :

```text
Plus visible que F.
Bonne largeur.
Opacity 0.26 encore raisonnable.
Mais lit davantage comme une ombre ajoutée, moins comme un socle naturel.
```

Décision :

```text
Rejetée.
```

### Option C — Sélectionner D exact

Analyse :

```text
Très bon attachement.
Mais moins large et parfois trop caché sous le sprite.
Moins convaincant que F comme calibration générale.
```

Décision :

```text
Rejetée.
```

### Option D — Sélectionner un hybride F/C ou F/D

Analyse :

```text
Peut combiner les qualités.
Mais n'a pas été visualisé dans la matrice.
Créer un hybride maintenant retarderait ou fragiliserait la décision.
```

Décision :

```text
Rejetée pour le Lot 47.
À reconsidérer seulement si F échoue dans un contexte visuel plus large.
```

### Option E — Ne rien sélectionner

Analyse :

```text
Impliquerait author-defined polygon, asset shadow ou renderer work.
Trop tôt : F est prometteur et répond déjà mieux que les alternatives.
```

Décision :

```text
Rejetée.
```

## 20. Option recommandée

Option recommandée :

```text
Option A — Sélectionner F exact.
```

Calibration retenue :

```text
id: pokemon-building-shadow-footprint-v1
name: Pokemon-like footprint building shadow V1
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
default core ou preset-only: preset-only pour le Lot 47
```

Pourquoi :

```text
F est la forme la plus large et la plus courte sans devenir sale.
F soutient le bâtiment comme une emprise au sol.
F évite le retour à une projection diagonale.
F est visualisé dans la matrice Lot 45, contrairement aux hybrides.
```

Pourquoi les autres options sont rejetées :

```text
C exact : bon finaliste, mais moins sobre que F.
D exact : bon attachement, mais moins large et plus caché.
Hybride F/C ou F/D : plausible mais non prouvé par l'image Lot 45.
Ne rien sélectionner : prématuré, car F fonctionne assez bien pour avancer.
Renderer/painter : hors sujet pour une propagation calibration.
JSON/persistence : nécessaire plus tard, pas pour cette preuve test/fixture.
```

Lot 47 doit faire :

```text
Créer ou mettre à jour un preset test/fixture pokemon-building-shadow-footprint-v1 avec les valeurs F explicites.
Mettre à jour les attentes de points/bounds/opacité/couleur dans les tests ciblés.
Prouver que runtime/editor continuent à transporter cette calibration via les adapters existants.
Garder ProjectedShadowFootprintTuning() default inchangé.
```

Lot 47 ne doit pas faire :

```text
Modifier renderer/painter.
Modifier runtime/editor production.
Modifier JSON/codecs.
Modifier Selbrume.
Créer baseline/golden/screenshot Selbrume.
Modifier project.json.
Changer le modèle footprint structurel.
Traiter banding.
```

## 21. Plan précis du Lot 47

Nom recommandé :

```text
ShadowV2-47 — Projected Building Shadow Footprint Calibration V1 Test Fixtures
```

Objectif :

```text
Propager la calibration footprint retenue F exact dans les tests/fixtures ciblés,
en tant que preset officiel pokemon-building-shadow-footprint-v1,
sans modifier renderer/painter,
sans Selbrume,
sans baseline,
sans JSON/persistence,
sans production runtime/editor.
```

Décision de scope :

```text
1. Fixtures/presets de test : oui.
2. Defaults ProjectedShadowFootprintTuning : non au Lot 47.
3. Les deux : non.
```

Valeurs à propager :

```text
ProjectedShadowFootprintTuning(
  attachYRatio: 0.82,
  frontWidthRatio: 1.30,
  rearWidthRatio: 1.42,
  depthRatio: 0.26,
  skewXRatio: 0.08,
)
ProjectedShadowAppearance(
  opacity: 0.24,
  colorHexRgb: '606060',
)
```

Points attendus micro-fixture F :

```text
frontLeft  = (22.40, 142.72)
frontRight = (105.60, 142.72)
rearRight  = (114.56, 167.68)
rearLeft   = (23.68, 167.68)
bounds:
  left = 22.40
  top = 142.72
  width = 92.16
  height = 24.96
```

Fichiers probablement concernés si preset-only :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichiers à considérer seulement si les tests V1 same-element réutilisent explicitement l'ancien preset V0 :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Fichiers à ne pas modifier au Lot 47 dans le scope recommandé :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
reports/shadows/screenshots/**
```

Tests ciblés à prévoir :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Analyze ciblé à prévoir si des fichiers de test Dart sont modifiés :

```bash
cd packages/map_core && dart analyze test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_runtime && flutter analyze test/shadow/projected_building_shadow_runtime_adapter_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Critères de réussite Lot 47 :

```text
Preset V1 explicite présent dans les tests ciblés.
Points F vérifiés.
Bounds F vérifiés quand exposés.
Opacity 0.24 vérifiée.
Color 606060 vérifiée.
Adapters runtime/editor toujours sans modification production.
Defaults core non modifiés.
JSON/Selbrume/baselines/screenshots non touchés.
```

## 22. Fichiers explicitement interdits au Lot 47

Interdits sauf demande explicite d'un autre lot :

```text
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
reports/shadows/screenshots/**
```

Interdits dans le scope recommandé preset-only :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/map_core.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

Interdits en création :

```text
baseline
golden
screenshot Selbrume
fixture Selbrume
nouveau renderer
nouveau painter
nouveau modèle
nouveau codec JSON
generated file
script screenshot
```

## 23. Risques / réserves

Risques :

```text
F peut être trop discret sur des fonds plus sombres ou plus chargés.
La micro-fixture ne couvre pas des bâtiments de tailles différentes.
Ne pas changer les defaults core crée un écart temporaire entre le default générique V0 et le preset officiel V1.
La persistance JSON ne sait pas encore forcément porter geometryMode/footprint dans project.json réel.
Le banding 4-points reste visible mais ne doit pas piloter le Lot 47.
```

Mitigations :

```text
Lot 47 doit utiliser des valeurs F explicites dans le preset V1, pas ProjectedShadowFootprintTuning() par défaut.
Un lot ultérieur pourra décider si le default core doit devenir V1.
Un lot JSON/persistence devra arriver avant Selbrume/project.json réel.
Un lot visual review élargi pourra vérifier F sur plusieurs fonds et bâtiments.
```

## 24. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Aucun code, test, screenshot, baseline, production ou asset n'a été modifié.
```

La décision F est-elle justifiée visuellement ?

```text
Oui. L'image Lot 45 montre que F est le meilleur équilibre large / court / sobre / peu directionnel.
```

Le rapport évite-t-il de choisir F uniquement parce qu'il a été pressenti ?

```text
Oui. C et D sont comparés comme finalistes réels, et les faiblesses de F sont conservées.
```

Le rapport compare-t-il vraiment F, C et D ?

```text
Oui. C gagne en largeur visible, D gagne en attachement strict, F gagne en équilibre global.
```

Le rapport tranche-t-il clairement default core vs preset-only ?

```text
Oui. Preset-only au Lot 47, avec tuning F explicite.
```

Le plan Lot 47 évite-t-il JSON/Selbrume/baseline/renderer/painter ?

```text
Oui. Ces sujets sont explicitement interdits ou repoussés.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. État git initial, métadonnées image, hash, paramètres, points, bounds, décision, plan, commandes et statut final sont documentés.
```

## 25. Regard critique sur le prompt

Le prompt est très bien borné :

```text
Il sépare clairement sélection visuelle, propagation de calibration, JSON/persistence et rendu.
Il impose la comparaison F/C/D et évite une validation paresseuse.
Il force à trancher default core vs preset-only, ce qui est le vrai point d'architecture.
```

Point de vigilance :

```text
Le prompt laisse ouverte la possibilité de modifier les defaults core au Lot 47.
Pour limiter le risque, ce rapport recommande explicitement preset-only au Lot 47 et réserve le default core à un lot ultérieur si nécessaire.
```

## 26. Commandes lancées

Commandes obligatoires lancées :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

file reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png || sha256sum reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png

rg -n "candidate-a-current-footprint-v0|candidate-b-deeper-footprint|candidate-c-wider-footprint|candidate-d-higher-attached-footprint|candidate-e-stronger-skew-footprint|candidate-f-broad-shallow-footprint|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|opacity|colorHexRgb|bounds|points" packages/map_runtime/tool reports/shadows/v2

rg -n "F — Broad shallow|Broad shallow|C — Wider|D — Higher|Directional V0|Footprint Calibration|candidate-f|candidate-c|candidate-d|pokemon-building-shadow-footprint" reports/shadows/v2 packages/map_runtime/tool

git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Sortie `find .. -name AGENTS.md -print` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Sorties AGENTS pertinentes :

```text
5:This repository is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.
21:    - Flutter + Flame runtime.
24:    - Flutter desktop authoring app.
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
808:Core principle: skills guide how to execute work. User instructions define what to do.
860:1. Use `superpowers:subagent-driven-development` when applicable.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Sorties image Lot 45 :

```text
reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png: PNG image data, 1120 x 480, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff   8.6K May 22 00:15 reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
76f4079a4cce27effc8aac9272894501ecec2324fba4d96654d4c318e5df9e99  reports/shadows/screenshots/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix.png
```

Sorties d'audit candidate utilisées :

```text
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart:310:    label: 'R — Directional V0',
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart:358:      id: 'candidate-c-wider-footprint',
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart:373:      id: 'candidate-d-higher-attached-footprint',
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart:403:      id: 'candidate-f-broad-shallow-footprint',
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md:347:Candidate F — Broad shallow Pokémon-like :
reports/shadows/v2/shadow_v2_45_projected_building_shadow_footprint_candidate_matrix_artifact.md:525:F — Broad shallow :
```

Tests lancés :

```text
Aucun. Le Lot 46 est design-only.
```

## 27. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
(no output)
```

Note :

```text
Le rapport Lot 46 est non suivi ; il apparaît dans git status, pas dans git diff --stat.
```

## 28. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
(no output)
```

Note :

```text
Le rapport Lot 46 est non suivi ; il apparaît dans git status, pas dans git diff --name-status.
```

## 29. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
(no output)
```

Résultat :

```text
Propre.
```

## 30. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/shadows/v2/shadow_v2_46_projected_building_shadow_footprint_calibration_selection_design.md
```

Conformité :

```text
Un seul fichier créé par ShadowV2-46.
Aucun fichier Dart modifié.
Aucun test créé/modifié.
Aucun screenshot créé.
Aucune baseline créée.
Aucun fichier map_core, map_runtime, map_editor, Selbrume ou production modifié.
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
- [x] Artifact Lot 45 audité
- [x] R Directional V0 analysé
- [x] A Current analysé
- [x] B Deeper analysé
- [x] C Wider analysé
- [x] D Higher analysé
- [x] E Skew analysé
- [x] F Broad shallow analysé
- [x] F exact vs hybride tranché
- [x] Default core vs preset-only tranché
- [x] Option recommandée unique
- [x] Plan ShadowV2-47 précis
- [x] Fichiers interdits au Lot 47 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
