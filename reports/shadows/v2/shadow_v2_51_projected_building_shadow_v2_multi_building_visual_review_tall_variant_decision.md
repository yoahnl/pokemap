# ShadowV2-51 — Projected Building Shadow V2 Multi-Building Visual Review / Tall Variant Decision Gate

## 1. Résumé exécutif

ShadowV2-51 est un design gate audit-only.

Décision unique :

```text
Option recommandée : produire un artifact tall-building ciblé au Lot 52.
La calibration ShadowV2 footprint standard est conservée pour les bâtiments simples / larges / compacts.
La calibration standard ne doit pas être modifiée maintenant.
JSON/persistence est repoussé.
Renderer/painter, Selbrume, authoring editor, petits props et baselines restent hors scope.
```

Diagnostic court :

```text
A simple_house_4x5 : fonctionne.
B wide_house_6x5 : fonctionne, même si l'ombre reste volontairement peu profonde.
C tall_shop_4x7 : fonctionne, mais la masse paraît possiblement trop prudente pour un volume haut.
D small_kiosk_3x4 : fonctionne comme cas compact discret.
```

Conclusion :

```text
Le cas C ne justifie pas une modification globale de la V2 standard.
Il justifie une matrice tall-building avant de persister quoi que ce soit.
```

## 2. Objectif du lot

Objectif exact :

```text
Analyser l’artifact multi-bâtiments ShadowV2-50,
confirmer ce qui fonctionne sur plusieurs silhouettes,
identifier précisément si le bâtiment haut C nécessite une variante d’ombre plus profonde / plus grande,
puis décider si le prochain lot doit aller vers JSON/persistence ou vers une matrice tall-building contrôlée.
```

Ce lot ne produit aucun code, aucune image, aucun test et aucune baseline.

## 3. Rappel ShadowV2-49 / ShadowV2-50

ShadowV2-49 :

```text
Direction globale canonique stylisée.
Pas de soleil dynamique.
Pas de direction contextuelle.
Pas de JSON/persistence avant validation visuelle multi-bâtiments.
Pas de Selbrume immédiat.
Pas de renderer/painter.
Pas d'editor authoring.
```

ShadowV2-50 :

```text
Artifact : reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
width = 800
height = 480
colonnes = A | B | C | D
ligne 1 = shadow-only
ligne 2 = shadow + building
```

Corpus Lot 50 :

```text
A = simple_house_4x5
B = wide_house_6x5
C = tall_shop_4x7
D = small_kiosk_3x4
```

Calibration utilisée :

```text
pokemon-building-shadow-footprint-v2
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
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

Fichiers préexistants avant ShadowV2-51 :

```text
Aucun fichier modifié ou non suivi au départ.
```

Fichiers créés par ShadowV2-51 :

```text
reports/shadows/v2/shadow_v2_51_projected_building_shadow_v2_multi_building_visual_review_tall_variant_decision.md
```

Fichiers modifiés par ShadowV2-51 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-51 :

```text
Aucun
```

Fichiers hors scope déjà présents :

```text
Aucun fichier hors scope modifié ou non suivi au départ.
```

Problèmes introduits par ShadowV2-51 :

```text
Aucun
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills consultés ou appliqués :

```text
superpowers:using-superpowers
superpowers:verification-before-completion
karpathy-guidelines
dart-run-static-analysis
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté.
La revue reste fondée sur les artifacts locaux, les rapports ShadowV2, les commandes d'audit et les patterns Flutter/Dart déjà validés au Lot 50.
```

Sub-agents :

```text
Visual Review sub-agent : lancé et complété.
Tall Building Analysis sub-agent : lancé ; pas de résultat exploitable avant finalisation, passe équivalente faite localement.
Scope / Architecture sub-agent : lancé et complété.
Evidence/report sub-agent : lancé et complété.
```

Constats sub-agents :

```text
Visual Review : A fonctionne, B fonctionne mais peut lire un peu bande, C est le plus massif/attaché, D est propre mais discret.
Tall locale : C n'est pas cassé, mais la question tall est assez ouverte pour un artifact comparatif dédié.
Scope / Architecture : avis dissident recommandant JSON/persistence narrow au Lot 52, au motif que Lot 50 serait déjà suffisant.
Evidence/report : Lot51 doit créer exactement un rapport, ne lancer aucun test, inclure metadata PNG et git final.
Décision retenue malgré dissensus : reporter JSON après matrice tall, car la demande utilisateur vise explicitement la question C.
```

## 6. Décision AGENTS / design gate

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

AGENTS trouvés :

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
ShadowV2-51 est audit-only.
Le seul fichier créé est ce rapport Markdown.
```

## 7. Fichiers audités

Fichiers audités en lecture seule :

```text
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
reports/shadows/v2/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
reports/shadows/v2/shadow_v2_49_projected_building_shadow_v2_controlled_building_application_design.md
```

Commandes principales :

```bash
file reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
rg -n "simple_house_4x5|wide_house_6x5|tall_shop_4x7|small_kiosk_3x4|pokemon-building-shadow-footprint-v2|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|opacity|colorHexRgb|points|bounds" reports/shadows/v2 packages/map_runtime/tool
rg -n "tall|building C|C — tall|depthRatio|reference|Pokémon-like|Pokemon-like|persistence|JSON|Selbrume|renderer|painter" reports/shadows/v2 packages/map_runtime/tool
```

## 8. Audit artifact Lot 50

PNG :

```text
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Commande `file` :

```text
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png: PNG image data, 800 x 480, 8-bit/color RGBA, non-interlaced
```

Commande `ls -lh` :

```text
-rw-r--r--@ 1 karim  staff   9.2K May 22 15:23 reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Commande SHA-256 :

```text
85d2d3ab03c6a1db7a405d25736aee148f14f226c81d77b2be16773b8897f845  reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
```

Présence image :

```text
Colonnes A/B/C/D présentes.
Ligne shadow-only présente.
Ligne shadow + building présente.
Fond, grille et séparateurs présents.
Analyse visuelle directe effectuée localement.
```

Pipeline documenté au Lot 50 :

```text
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Limites :

```text
Artifact contrôlé, pas vraie map.
Silhouettes vectorielles simplifiées.
Aucune validation Selbrume.
Aucune validation JSON/persistence.
Pas de petits props, arbres, lampadaires ou silhouettes alpha.
```

## 9. Analyse A — simple_house_4x5

Géométrie :

```text
frontLeft  = (58.40, 145.60)
frontRight = (141.60, 145.60)
rearRight  = (150.56, 166.40)
rearLeft   = (59.68, 166.40)
bounds     = left 58.40, top 145.60, width 92.16, height 20.80
```

Analyse :

```text
A est le cas standard le plus stable.
L'ombre est large pour la largeur du bâtiment, courte, attachée et lisible.
La profondeur reste sobre, ce qui évite l'effet plaque.
```

Décision :

```text
Calibration standard validée pour petite maison simple.
```

## 10. Analyse B — wide_house_6x5

Géométrie :

```text
frontLeft  = (37.60, 145.60)
frontRight = (162.40, 145.60)
rearRight  = (175.84, 166.40)
rearLeft   = (39.52, 166.40)
bounds     = left 37.60, top 145.60, width 138.24, height 20.80
```

Analyse :

```text
B conserve une bonne assise horizontale.
La largeur renforcée fonctionne : l'ombre soutient le bâtiment large sans dépasser de manière sale.
La profondeur faible donne une lecture un peu bande, mais elle reste cohérente avec l'objectif large/court.
```

Décision :

```text
Calibration standard suffisante pour bâtiment large contrôlé.
Pas de profil wide maintenant.
```

## 11. Analyse C — tall_shop_4x7

Géométrie :

```text
frontLeft  = (58.40, 139.84)
frontRight = (141.60, 139.84)
rearRight  = (150.56, 168.96)
rearLeft   = (59.68, 168.96)
bounds     = left 58.40, top 139.84, width 92.16, height 29.12
```

Questions obligatoires :

```text
1. Cette ombre est-elle assez grande pour un bâtiment haut ?
Partiellement. Elle fonctionne, mais elle paraît prudente par rapport au volume vertical.

2. Le depthRatio 0.26 sous-réagit-il pour visualHeight = 112 ?
Possiblement oui. Mathématiquement la profondeur augmente à 29.12 px, mais visuellement elle ne compense pas totalement la hauteur perçue du shop.

3. Le front edge est-il bien positionné ?
Oui. Le front edge à y = 139.84 reste attaché sous le volume et ne flotte pas.

4. L’ombre devrait-elle descendre davantage ?
Probablement à tester. Une profondeur autour de 0.34 à 0.40 mérite comparaison.

5. L’opacité 0.24 reste-t-elle suffisante ?
Probablement oui pour la standard. Pour tall, 0.25 peut être testé, mais le premier levier est depthRatio.

6. La largeur est-elle correcte ?
Oui. width 92.16 pour un bâtiment de 64 px soutient bien le volume.

7. Est-ce un problème de profondeur seulement, ou aussi d’opacité / attache / largeur ?
Principalement profondeur. Attache et largeur sont correctes ; opacité secondaire.
```

Décision :

```text
C n'est pas un échec.
C est assez ambigu pour bloquer JSON/persistence et justifier un artifact tall-building comparatif.
```

## 12. Analyse D — small_kiosk_3x4

Géométrie :

```text
frontLeft  = (68.80, 148.48)
frontRight = (131.20, 148.48)
rearRight  = (137.92, 165.12)
rearLeft   = (69.76, 165.12)
bounds     = left 68.80, top 148.48, width 69.12, height 16.64
```

Analyse :

```text
D est discret mais cohérent.
Le petit volume ne reçoit pas une plaque trop grande.
La faible profondeur est acceptable pour un kiosk compact.
```

Décision :

```text
Calibration standard suffisante pour petit volume compact contrôlé.
```

## 13. Comparaison avec référence Pokémon-like

Comparaison conceptuelle, sans recherche internet ni téléchargement d'image externe :

```text
Bâtiments bas : la V2 standard correspond bien à la cible large, courte, grise, dure.
Bâtiments larges : la V2 standard garde l'assise sans devenir une projection réaliste.
Bâtiments hauts : la référence Pokémon-like tolère souvent une masse au sol plus assumée.
Ombres de grands bâtiments : elles peuvent être plus profondes sans devenir floues ou réalistes.
Stylisation vs réalisme : le bon levier reste un profil contrôlé, pas un soleil dynamique.
```

Lecture :

```text
La V2 standard est bonne comme profil de base.
La cible n'impose pas une ombre physiquement proportionnelle à la hauteur.
Mais C suggère qu'un profil tall pourrait mieux soutenir les façades verticales.
```

## 14. Diagnostic principal

Diagnostic :

```text
La calibration ShadowV2 footprint standard est validée pour A/B/D.
Elle est prometteuse mais non définitivement validée pour C.
Le problème C est un problème de profil tall potentiel, surtout depthRatio.
```

Ce qui n'est pas le problème principal :

```text
Pas un problème renderer/painter.
Pas un problème JSON.
Pas un problème de direction solaire.
Pas un problème de largeur globale standard.
Pas un problème de petits props.
```

Niveau de confiance :

```text
Standard A/B/D : élevé.
C tall : moyen ; nécessite comparaison visuelle ciblée.
JSON maintenant : confiance basse, car on risquerait de persister avant de trancher tall.
```

## 15. Options étudiées

Option A — Garder uniquement la calibration standard :

```text
Rejetée comme décision finale maintenant.
La standard reste utile, mais C laisse une question ouverte.
```

Option B — Créer une variante tall-building :

```text
Retenue sous forme de matrice à tester.
Ne pas figer encore la variante tall sans image comparative.
```

Option C — Créer trois profils standard / wide / tall :

```text
Rejetée maintenant.
B ne justifie pas un profil wide.
Créer trois profils ouvrirait trop tôt une logique d'authoring/presets.
```

Option D — Modifier la calibration standard pour tout le monde :

```text
Rejetée.
Risque de dégrader A/B/D pour résoudre seulement C.
```

Option E — Aller directement vers JSON/persistence :

```text
Repoussée.
La décision tall doit précéder la persistence.
Un sub-agent scope a recommandé JSON/persistence narrow maintenant ; cet avis est documenté mais non retenu,
car le présent design gate a pour objet de trancher le doute visuel C avant d'encoder une stratégie durable.
```

Option F — Renderer / painter / banding :

```text
Rejetée.
Le sujet est la profondeur/profil, pas le fill ou le renderer.
```

## 16. Variantes tall proposées si nécessaire

Une matrice tall-building est recommandée. Variantes proposées :

Candidate A — Standard V2 current :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
expected: témoin actuel, peut-être trop timide pour C.
```

Candidate B — Tall deeper :

```text
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.34
skewXRatio: 0.08
opacity: 0.25
colorHexRgb: 606060
expected: plus de profondeur pour soutenir un bâtiment haut.
```

Candidate C — Tall deeper softer :

```text
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.45
depthRatio: 0.38
skewXRatio: 0.08
opacity: 0.23
colorHexRgb: 606060
expected: plus long mais plus doux, éviter plaque grise.
```

Candidate D — Tall attached :

```text
attachYRatio: 0.76
frontWidthRatio: 1.24
rearWidthRatio: 1.38
depthRatio: 0.34
skewXRatio: 0.08
opacity: 0.25
colorHexRgb: 606060
expected: plus attaché sous le bâtiment, moins large.
```

Candidate E — Tall reference-like :

```text
attachYRatio: 0.78
frontWidthRatio: 1.34
rearWidthRatio: 1.50
depthRatio: 0.40
skewXRatio: 0.10
opacity: 0.23
colorHexRgb: 606060
expected: plus proche grands bâtiments de la référence, à surveiller pour risque plaque.
```

Pourquoi ne pas ajuster ces valeurs maintenant :

```text
Le Lot 51 ne crée pas d'image.
Ces valeurs couvrent assez l'espace : profondeur moyenne, profondeur longue douce, attache haute, référence plus massive.
```

## 17. Option recommandée

Option recommandée :

```text
Option B — créer une matrice tall-building contrôlée au Lot 52.
```

Décision :

```text
matrice tall-building nécessaire
```

Analyse par bâtiment :

```text
A : standard V2 suffisante.
B : standard V2 suffisante ; pas de profil wide maintenant.
C : standard V2 prometteuse mais possiblement trop timide ; cas à isoler.
D : standard V2 suffisante ; petit volume discret acceptable.
```

Analyse spécifique C :

```text
problème identifié : profondeur potentiellement insuffisante pour un volume haut.
paramètres à explorer : depthRatio d'abord, attachYRatio ensuite, opacity légèrement, largeur en garde-fou.
niveau de confiance : moyen.
```

Pourquoi :

```text
Le Lot 50 a prouvé la robustesse générale.
C soulève une question visuelle assez précise pour un artifact ciblé.
Il serait prématuré de persister JSON avant de savoir si le produit a besoin d'un preset tall.
```

Pourquoi les autres options sont rejetées :

```text
Standard seule : trop tôt pour déclarer C final.
Trois profils : trop complexe maintenant.
Modifier standard : risque de casser A/B/D.
JSON/persistence : techniquement pertinent bientôt, mais prématuré tant que la variante tall n'est pas comparée.
Renderer/painter : hors sujet.
```

Lot 52 doit faire :

```text
Générer une matrice contrôlée pour tall_shop_4x7.
Comparer standard V2 vs tall variants A-E.
Utiliser le pipeline resolver -> adapter -> renderer.
Ne modifier aucun modèle, renderer, painter, JSON ou Selbrume.
Ne créer aucune baseline.
```

Lot 52 ne doit pas faire :

```text
Ne pas traiter JSON/persistence.
Ne pas modifier la calibration standard.
Ne pas introduire standard/wide/tall officiellement.
Ne pas toucher Selbrume.
Ne pas toucher renderer/painter.
Ne pas traiter petits props / lampadaires / poteaux.
```

## 18. Plan précis du Lot 52

Nom recommandé :

```text
ShadowV2-52 — Projected Building Shadow V2 Tall Building Variant Matrix Artifact
```

Objectif :

```text
Générer un artifact contrôlé comparant plusieurs variantes d’ombre pour le bâtiment haut C,
avec une comparaison standard vs tall,
sans modifier le modèle,
sans renderer/painter,
sans JSON,
sans Selbrume,
sans baseline.
```

Image recommandée :

```text
width = 800 ou 960 selon nombre de colonnes
height = 480
colonnes = A Standard | B Tall deeper | C Tall deeper softer | D Tall attached | E Tall reference-like
ligne 1 = shadow-only
ligne 2 = shadow + tall_shop_4x7
```

Fichiers probables :

```text
packages/map_runtime/tool/shadow/shadow_v2_tall_building_variant_matrix_artifact_test.dart
reports/shadows/screenshots/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix.png
reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
```

Validations obligatoires :

```text
PNG dimensions documentées.
Colonnes A-E présentes.
Pipeline resolver -> adapter -> renderer utilisé.
Points/bounds vérifiés par variante.
Test ciblé passé.
Analyze ciblé OK.
SHA-256 documenté.
Audit anti-dérive propre.
git diff --check propre.
```

## 19. Fichiers explicitement interdits au Lot 52

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
project.json
JSON/codecs
renderer/painter
generated files
```

## 20. Risques / réserves

```text
La lecture de C est visuelle, pas mesurée par une métrique artistique.
Une variante tall peut améliorer C mais ouvrir une question de règle d'utilisation.
Il faut éviter une explosion de profils.
Le Lot 52 doit rester un artifact, pas une décision de persistence.
Avis dissident documenté : la persistence JSON est un prochain pas plausible si le produit accepte C standard,
mais ce rapport juge qu'une matrice tall est le plus petit pas utile avant persistence.
```

## 21. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Aucun code, test, image ou baseline créé.
```

Le rapport répond-il vraiment à la remarque utilisateur sur C ?

```text
Oui. C est analysé séparément et la décision Lot 52 répond directement à cette incertitude.
```

Le rapport évite-t-il de lancer JSON trop tôt ?

```text
Oui. JSON/persistence est repoussé jusqu'après la matrice tall.
```

Le rapport évite-t-il de multiplier les profils sans preuve ?

```text
Oui. Il ne recommande pas standard/wide/tall officiel ; il recommande seulement une matrice tall.
```

Les variantes tall proposées sont-elles assez précises si elles sont recommandées ?

```text
Oui. A-E ont attachYRatio, frontWidthRatio, rearWidthRatio, depthRatio, skewXRatio, opacity et colorHexRgb.
```

Le plan Lot 52 évite-t-il Selbrume / baseline / production / renderer / painter ?

```text
Oui.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Métadonnées PNG, commandes, analyses A/B/C/D, options, décision et git final sont documentés.
```

## 22. Regard critique sur le prompt

Le prompt est correctement borné.

Point utile :

```text
Il empêche de sauter vers JSON alors que le cas C n'est pas tranché.
```

Point de vigilance :

```text
Le terme "variante tall-building" ne doit pas devenir automatiquement un modèle ou une règle d'authoring.
Le prochain lot doit rester une matrice visuelle.
```

## 23. Commandes lancées

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

file reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png

rg -n "simple_house_4x5|wide_house_6x5|tall_shop_4x7|small_kiosk_3x4|pokemon-building-shadow-footprint-v2|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|opacity|colorHexRgb|points|bounds" reports/shadows/v2 packages/map_runtime/tool
rg -n "tall|building C|C — tall|depthRatio|reference|Pokémon-like|Pokemon-like|persistence|JSON|Selbrume|renderer|painter" reports/shadows/v2 packages/map_runtime/tool

git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests lancés :

```text
Aucun. Lot 51 est design-only.
```

## 24. git diff --stat

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
Le rapport Lot 51 est non suivi ; git diff --stat ne liste pas les fichiers non suivis.
```

## 25. git diff --name-status

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
Le rapport Lot 51 est non suivi ; git diff --name-status ne liste pas les fichiers non suivis.
```

## 26. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale observée :

```text
(no output)
```

## 27. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale observée :

```text
?? reports/shadows/v2/shadow_v2_51_projected_building_shadow_v2_multi_building_visual_review_tall_variant_decision.md
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
- [x] Artifact Lot 50 audité
- [x] A simple_house_4x5 analysé
- [x] B wide_house_6x5 analysé
- [x] C tall_shop_4x7 analysé
- [x] D small_kiosk_3x4 analysé
- [x] Référence Pokémon-like comparée
- [x] Question C trop petite explicitement tranchée
- [x] Standard vs tall variant tranché
- [x] JSON/persistence tranché
- [x] Renderer/painter explicitement exclus
- [x] Petits props / lampadaires hors scope
- [x] Option recommandée unique
- [x] Plan ShadowV2-52 précis
- [x] Fichiers interdits au Lot 52 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
