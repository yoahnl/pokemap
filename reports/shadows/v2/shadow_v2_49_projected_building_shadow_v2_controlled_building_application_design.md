# ShadowV2-49 — Projected Building Shadow V2 Controlled Building Application Design Gate

## 1. Résumé exécutif

ShadowV2-49 est un design gate audit-only. Aucun code, test, screenshot, baseline, fixture, JSON, Selbrume, renderer ou painter n'a été modifié.

Décision principale :

```text
Option recommandée : Option 1 — artifact multi-bâtiments contrôlé.
Politique de lumière : Option A — direction globale canonique stylisée.
Lot 50 recommandé : ShadowV2-50 — Projected Building Shadow V2 Controlled Multi-Building Artifact.
```

La calibration officielle issue de F — Broad shallow est assez bonne pour quitter le micro-labo mono-bâtiment, mais pas encore pour une application Selbrume réelle ou une persistance JSON immédiate.

Position :

```text
Oui, passer à plusieurs bâtiments contrôlés.
Non, ne pas passer directement à Selbrume.
Non, ne pas ouvrir JSON/persistence au Lot 50.
Non, ne pas toucher renderer/painter.
Non, ne pas ouvrir editor authoring.
Non, ne pas changer les defaults ProjectedShadowFootprintTuning().
```

Note de nommage :

```text
Les lots 46-48 parlent dans les fichiers de pokemon-building-shadow-footprint-v1.
Le présent prompt élève la même calibration produit au vocabulaire footprint V2, avec id intentionnel pokemon-building-shadow-footprint-v2.
Ce rapport traite V2 comme le nom produit de la même calibration F exacte.
Aucun renommage persistant n'est effectué dans ce lot.
```

## 2. Objectif du lot

Objectif exact :

```text
Quitter le micro-labo abstrait,
prendre la calibration officielle footprint V2 déjà retenue,
définir une stratégie simple et durable d'application sur de vrais bâtiments contrôlés,
trancher la politique de direction de lumière,
sélectionner un petit corpus de bâtiments de référence,
puis préparer un Lot 50 strictement borné pour produire un artifact multi-bâtiments.
```

Ce lot répond aux questions de stratégie uniquement. Il ne produit pas de nouvel artifact visuel.

## 3. Rappel ShadowV2-46 à ShadowV2-48

ShadowV2-46 :

```text
F — Broad shallow retenu tel quel.
Calibration :
attachYRatio 0.82
frontWidthRatio 1.30
rearWidthRatio 1.42
depthRatio 0.26
skewXRatio 0.08
opacity 0.24
colorHexRgb 606060
```

ShadowV2-47 :

```text
Calibration propagée en preset explicite dans les tests/fixtures ciblés.
Production non modifiée.
Defaults ProjectedShadowFootprintTuning() conservés.
JSON/persistence hors scope.
```

ShadowV2-48 :

```text
Artifact micro 480x480 créé.
Colonnes : A Directional V0, B Footprint V0, C Footprint V1/V2 officielle.
Lignes : shadow-only, shadow + building.
Pipeline : resolveProjectedBuildingShadowGeometry -> createProjectedBuildingShadowRuntimeInstruction -> ShadowRuntimeRenderer.renderCollectionPass.
Conclusion : la calibration officielle est plus large, plus sobre et plus Pokémon-like que V0, mais elle n'a été vue que sur une silhouette simplifiée.
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

Fichiers préexistants avant ShadowV2-49 :

```text
Aucun fichier modifié ou non suivi au départ.
```

Fichiers hors scope déjà présents :

```text
Aucun fichier hors scope modifié ou non suivi au départ.
```

Fichiers créés par ShadowV2-49 :

```text
reports/shadows/v2/shadow_v2_49_projected_building_shadow_v2_controlled_building_application_design.md
```

Fichiers modifiés par ShadowV2-49 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-49 :

```text
Aucun
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills consultés ou appliqués :

```text
superpowers:using-superpowers
superpowers:brainstorming
superpowers:writing-plans
karpathy-guidelines
superpowers:verification-before-completion
```

Mise à jour chemins skills :

```text
Les chemins annoncés pour certains skills Superpowers sous 36878fcb étaient absents.
Les fichiers réels ont été trouvés sous :
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté.
Les décisions Flutter/Dart restent guidées par les patterns locaux et par les skills génériques disponibles.
```

Sub-agents :

```text
Visual policy sub-agent : utilisé.
Building corpus sub-agent : utilisé.
Scope / architecture sub-agent : utilisé.
Evidence/report sub-agent : non lancé, limite de threads atteinte ; passe équivalente faite localement.
```

Synthèse sub-agents :

```text
Visual policy : recommande une direction fixe globale stylisée, aucun soleil/contextuel, V2 prête pour application contrôlée.
Building corpus : recommande 4 silhouettes vectorielles contrôlées, sans assets réels ni Selbrume.
Scope / architecture : recommande JSON/persistence au Lot 50, avis noté comme dissensus utile mais non retenu pour ce lot.
Evidence/report : passe locale avec commandes obligatoires et git final.
```

## 6. Décision AGENTS / design gate

AGENTS.md audité :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Extraits pertinents de la commande AGENTS :

```text
5:This repository is a Dart/Flutter monorepo for a Pokemon-style editor/runtime/battle stack.
21:    - Flutter + Flame runtime.
24:    - Flutter desktop authoring app.
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
589:Flutter packages and apps:
611:For pure Dart packages, use `dart analyze`.
613:For Flutter packages and apps, use `flutter analyze`.
860:1. Use `superpowers:subagent-driven-development` when applicable.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

```text
ShadowV2-49 est audit-only.
Le design gate précédent autorise une décision, pas une implémentation.
Le seul fichier créé est ce rapport Markdown.
```

## 7. Fichiers audités

Fichiers audités en lecture seule :

```text
reports/shadows/v2/shadow_v2_46_projected_building_shadow_footprint_calibration_selection_design.md
reports/shadows/v2/shadow_v2_47_projected_building_shadow_footprint_calibration_v1_test_fixtures.md
reports/shadows/v2/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.md
reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
packages/map_runtime/tool/shadow/shadow_v2_footprint_candidate_matrix_artifact_test.dart
packages/map_runtime/tool/shadow/shadow_v2_footprint_micro_visual_artifact_test.dart
```

Commandes d'audit principales :

```bash
rg -n "footprint-v1|footprint-v2|Broad shallow|directional|light direction|controlled multi-building|artifact|persistence|Selbrume|renderer|painter" reports/shadows/v2 packages/map_runtime/tool
rg -n "building|house|roof|tileset|placed element|footprint|shadow" packages/map_runtime/tool packages/map_editor/test packages/map_runtime/test reports/shadows/v2
```

Constats :

```text
Les harnesses ShadowV2 existants construisent des bâtiments vectoriels contrôlés via dart:ui.
Le Lot 48 utilise bien le pipeline resolver -> adapter -> renderer.
Le repo contient des chemins Selbrume et baselines historiques, mais ils restent hors scope.
Le support JSON footprint reste une dette séparée, non requise pour un artifact in-memory contrôlé.
```

## 8. Audit artifact Lot 48

Commandes obligatoires :

```bash
file reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Sorties :

```text
reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png: PNG image data, 480 x 480, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff   5.0K May 22 01:29 reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
a04c37c962970dbd7edf35752f8ce83dd49bb8e1de836f6b05e65f951f56d073  reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
```

Rappel image :

```text
A = Directional V0
B = Footprint V0
C = Footprint V1/V2 officielle
ligne 1 = shadow-only
ligne 2 = shadow + building
```

Pipeline utilisé :

```text
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeRenderer.renderCollectionPass(...)
```

Lecture visuelle :

```text
Directional V0 reste trop languette / directionnel.
Footprint V0 améliore la lecture footprint, mais reste moins large et plus dense.
La calibration officielle est plus large, plus courte visuellement, plus sobre et plus lisible comme socle.
```

Limite :

```text
Une seule silhouette simplifiée a été testée.
Il manque encore une validation contrôlée sur plusieurs proportions de bâtiments.
```

## 9. État de validation actuel de la calibration V2

Déjà suffisamment validé :

```text
La formule footprint fonctionne en core.
Les adapters runtime/editor consomment les points footprint.
Le renderer existant dessine la forme via projectedPolygon.
La calibration F exacte est visuellement meilleure que Directional V0 et Footprint V0 sur micro-fixture.
Les points/bounds attendus sont testés côté fixtures.
```

Pas encore validé :

```text
Robustesse sur plusieurs silhouettes de bâtiments.
Comportement sur bâtiments très larges, hauts, petits ou moins centrés.
Persistence JSON de geometryMode/footprint.
Application à une vraie map.
Authoring no-code côté editor.
```

Conclusion :

```text
La calibration est assez bonne pour un artifact multi-bâtiments contrôlé.
Elle n'est pas encore assez validée pour Selbrume, JSON/persistence ou rollout production.
```

## 10. Politique de direction de lumière — options

Option A — Direction globale canonique stylisée :

```text
Toutes les ombres de bâtiments suivent une convention visuelle globale.
La direction est simple, cohérente et stylisée.
Dans la calibration footprint, elle se manifeste surtout par un skew faible vers bas-droite : skewXRatio 0.08.
```

Option B — Direction configurable par preset :

```text
La direction globale reste recommandée, mais quelques presets pourraient porter des variantes.
Cette option est tolérable plus tard si un besoin réel apparaît.
```

Option C — Direction contextuelle / map / scène / soleil :

```text
La direction dépendrait de la map, d'une heure, d'une scène ou d'un soleil.
C'est prématuré et contraire à la simplicité produit actuelle.
```

## 11. Politique de direction de lumière — option recommandée

Option recommandée : **Option A — direction globale canonique stylisée**.

Décision :

```text
globale : oui
preset-only variants : pas au Lot 50
contextuelle / soleil : non
```

Politique :

```text
Fixed stylized footprint.
Broad, shallow, low-opacity gray.
Slight down-right skew.
No contextual sun.
No time-of-day behavior.
No runtime inference.
```

Justification :

```text
Pokémon-like privilégie la cohérence et la lisibilité plutôt que le réalisme.
Le skewXRatio 0.08 donne une direction subtile sans redevenir une projection diagonale.
Une direction contextuelle créerait une charge produit et technique disproportionnée.
Le Lot 50 doit valider la robustesse de la calibration, pas rouvrir un système de lumière.
```

## 12. Options de prochain lot

Option 1 — Artifact multi-bâtiments contrôlé :

```text
Recommandé.
Permet de tester la calibration sur plusieurs proportions en isolant les variables.
Reste sans Selbrume, sans JSON, sans renderer/painter, sans baseline.
```

Option 2 — Application directe sur vraie map / Selbrume :

```text
Rejeté.
Trop tôt : mélange assets réels, persistence, placement, authoring, rendu et data réelle.
Le codec JSON footprint n'est pas encore le bon support de rollout.
```

Option 3 — Passer directement à JSON/persistence :

```text
Rejeté pour Lot 50.
Le risque JSON est réel, mais il répond à "peut-on persister ?" alors que le blocage actuel du prompt est "la calibration tient-elle sur des bâtiments contrôlés ?".
À programmer après le gate visuel multi-bâtiments, sauf changement de priorité explicite.
```

## 13. Corpus de bâtiments recommandé

Source recommandée :

```text
Reconstruction simplifiée contrôlée en dart:ui Canvas.
Pas d'asset réel.
Pas de Selbrume.
Pas de map pipeline.
```

Corpus Lot 50 recommandé : **4 bâtiments**.

```text
1. simple_house_4x5
   size: 64 x 80 px
   shape: corps rectangulaire, roof cap, porte centrée
   purpose: baseline maison Pokémon-like proche micro-fixture

2. wide_house_6x5
   size: 96 x 80 px
   shape: façade plus large, roof cap, deux fenêtres
   purpose: tester les façades larges sans asset Selbrume

3. tall_shop_4x7
   size: 64 x 112 px
   shape: bâtiment plus vertical avec bande roof/sign
   purpose: tester la hauteur et l'attachement sous volume élevé

4. small_kiosk_3x4
   size: 48 x 64 px
   shape: petit kiosque/stall compact, toit peu profond
   purpose: tester un petit cas contrôlé proche puits/kiosque sans copier les assets réels
```

Cas optionnel non retenu pour Lot 50 :

```text
very_wide_center_8x5
size: 128 x 80 px
raison du rejet provisoire: utile comme stress case futur, mais augmente le zoo visuel alors que 4 silhouettes suffisent pour le prochain gate.
```

## 14. JSON / persistence — décision

Décision :

```text
Ne pas démarrer JSON/persistence au Lot 50.
```

Justification :

```text
JSON/persistence est nécessaire avant vraie utilisation project.json / Selbrume.
Mais le Lot 50 doit d'abord répondre à la robustesse visuelle multi-bâtiments.
Le défaut JSON renforce l'interdiction de Selbrume au Lot 50, il ne bloque pas un artifact in-memory contrôlé.
```

## 15. Renderer / painter — décision

Décision :

```text
Ne pas toucher renderer/painter au Lot 50.
```

Justification :

```text
Le renderer runtime dessine déjà projectedPolygon.
Le painter editor n'est pas requis pour un artifact runtime contrôlé.
Modifier le banding ou le fill maintenant mélangerait forme, calibration et rendu.
```

## 16. Editor authoring — décision

Décision :

```text
Ne pas ouvrir l'authoring UI maintenant.
```

Justification :

```text
La calibration doit encore être validée sur plusieurs silhouettes.
L'authoring no-code viendra après persistence et après décision de rollout.
```

## 17. Defaults core — décision

Décision :

```text
Ne pas remplacer les defaults ProjectedShadowFootprintTuning().
```

Justification :

```text
Les defaults core restent V0 pour compatibilité.
La calibration officielle reste preset-driven.
Lot 50 doit utiliser un preset explicite in-memory avec les valeurs V2/F.
```

## 18. Option recommandée

Option recommandée : **Option 1 — artifact multi-bâtiments contrôlé**.

Politique de direction de lumière :

```text
globale : oui
preset-only : non pour Lot 50
contextuelle : non
justification : cohérence Pokémon-like, faible charge mentale, aucun système soleil à introduire
```

Corpus recommandé pour Lot 50 :

```text
bâtiment 1 : simple_house_4x5, 64 x 80
bâtiment 2 : wide_house_6x5, 96 x 80
bâtiment 3 : tall_shop_4x7, 64 x 112
bâtiment 4 : small_kiosk_3x4, 48 x 64
bâtiment 5 éventuel : non retenu au Lot 50
```

Pourquoi :

```text
Le passage micro-fixture -> plusieurs silhouettes est le plus petit pas utile.
Il valide la calibration sur formes diverses sans engager persistence, real map ou authoring.
Il garde le diagnostic visuel lisible.
```

Pourquoi les autres options sont rejetées :

```text
Selbrume : trop tôt, dépend de JSON et de données réelles.
JSON/persistence : utile ensuite, mais répond à une autre question.
Renderer/painter : prématuré.
Editor authoring : prématuré.
Direction contextuelle : trop complexe.
```

Lot 50 doit faire :

```text
Créer un artifact contrôlé multi-bâtiments en mémoire.
Utiliser la calibration officielle footprint V2.
Utiliser la politique globale stylisée.
Rendre via resolver -> adapter -> renderer.
Vérifier dimensions, PNG, pixels utiles, hash.
Produire un rapport complet.
```

Lot 50 ne doit pas faire :

```text
Ne pas modifier production.
Ne pas modifier JSON/codecs.
Ne pas toucher Selbrume.
Ne pas créer baseline/golden.
Ne pas modifier renderer/painter.
Ne pas modifier editor authoring.
Ne pas changer les defaults core.
```

## 19. Plan précis du Lot 50

Nom :

```text
ShadowV2-50 — Projected Building Shadow V2 Controlled Multi-Building Artifact
```

Objectif :

```text
Générer un artifact visuel contrôlé,
montrant plusieurs bâtiments de silhouettes différentes,
rendus avec la calibration officielle footprint V2 et une direction de lumière canonique simple,
afin de confirmer la robustesse visuelle avant JSON/persistence et avant vraie map.
```

Fichiers probables à créer :

```text
packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
reports/shadows/v2/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.md
```

Nombre exact de bâtiments :

```text
4
```

Nombre de panneaux :

```text
8 panneaux : 4 colonnes x 2 lignes.
```

Organisation d'image recommandée :

```text
width = 800
height = 480
columnWidth = 200
headerHeight = 32
rowHeight = 224
row 1 = shadow-only
row 2 = shadow + building
columns = simple_house_4x5 | wide_house_6x5 | tall_shop_4x7 | small_kiosk_3x4
```

Comparaison V0/V2 :

```text
Non dans l'image principale.
Le Lot 48 a déjà comparé Directional V0 / Footprint V0 / V2 officielle.
Le Lot 50 doit se concentrer sur la robustesse de V2 sur plusieurs silhouettes.
```

Chaque bâtiment doit-il être montré shadow-only + building ?

```text
Oui.
La ligne shadow-only juge la forme brute.
La ligne shadow + building juge l'attachement au volume.
```

Calibration à utiliser :

```text
id in-memory recommandé : pokemon-building-shadow-footprint-v2
name : Pokemon-like footprint building shadow V2
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
timeOfDayMode: fixed
```

Note :

```text
Si le Lot 50 préfère éviter le rename local, il peut nommer le preset pokemon-building-shadow-footprint-v1-official dans le harness.
Mais le rapport Lot 50 doit expliciter le mapping V1 file history -> V2 product intention.
```

Tests / commandes à prévoir :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
ls -lh reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
file reports/shadows/screenshots/shadow_v2_50_projected_building_shadow_v2_controlled_multi_building_artifact.png
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Validations obligatoires :

```text
image dimensions exactes
PNG écrit sous reports/shadows/screenshots
fichier size > 0
hash SHA-256 documenté
background pixel vérifié
shadow-only visible pour chaque bâtiment
shadow + building visible pour chaque bâtiment
building body pixel vérifié pour chaque bâtiment
V2 values explicitement utilisées
resolver + adapter + renderer explicitement utilisés
aucune baseline/golden
aucun Selbrume
```

Ce que le Lot 50 ne doit absolument pas faire :

```text
Ne pas modifier packages/map_core/lib/**
Ne pas modifier packages/map_runtime/lib/**
Ne pas modifier packages/map_editor/**
Ne pas modifier JSON/codecs
Ne pas modifier project.json
Ne pas toucher /Users/karim/Desktop/selbrume/**
Ne pas créer reports/shadows/baselines/**
Ne pas utiliser matchesGoldenFile
Ne pas ouvrir editor authoring
Ne pas changer ProjectedShadowFootprintTuning() defaults
```

## 20. Fichiers explicitement interdits au Lot 50

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/baselines/**
project.json
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
```

## 21. Risques / réserves

```text
Le nom V2 est une intention produit ; les fichiers récents portent encore v1.
Le support JSON/persistence reste une dette réelle avant toute vraie map.
Un artifact vectoriel contrôlé ne prouve pas encore le rendu sur assets définitifs.
Les bâtiments du Lot 50 doivent rester peu nombreux pour ne pas transformer le gate en zoo visuel.
Le renderer conserve le banding actuel ; ce n'est pas un sujet Lot 50.
```

## 22. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Seul ce rapport Markdown est créé.
```

La politique de direction de lumière est-elle vraiment tranchée ?

```text
Oui. Option A est retenue : direction globale canonique stylisée, sans soleil/contextuel.
```

Le rapport évite-t-il une dérive vers une logique soleil/contextuelle inutile ?

```text
Oui. Option C est rejetée explicitement.
```

Le corpus recommandé est-il assez petit et assez utile ?

```text
Oui. 4 silhouettes couvrent simple, large, haut et petit sans dépendre d'assets réels.
```

Le plan Lot 50 évite-t-il Selbrume, JSON, renderer/painter et authoring ?

```text
Oui. Le plan est limité à un harness artifact contrôlé, un PNG et un rapport.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Il inclut status initial, commandes, métadonnées Lot 48, décisions, plan Lot 50 et git final.
```

## 23. Regard critique sur le prompt

Le prompt est volontairement strict et bien ciblé : il force à quitter le micro-labo sans sauter directement dans Selbrume ou JSON. La tension principale est le mot "V2" alors que les fichiers récents nomment encore l'id `pokemon-building-shadow-footprint-v1`. Le rapport résout cela comme une distinction entre historique de fichiers et intention produit.

Le prompt demande un corpus de bâtiments et une politique de lumière ; il est donc cohérent de choisir un Lot 50 artifact multi-bâtiments contrôlé. L'avis du sub-agent scope en faveur de JSON est techniquement pertinent, mais répond à une étape ultérieure.

## 24. Commandes lancées

```bash
sed -n '1,180p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/brainstorming/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/writing-plans/SKILL.md
sed -n '1,180p' /Users/karim/.codex/skills/karpathy-guidelines/SKILL.md
sed -n '1,180p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/36878fcb/skills/verification-before-completion/SKILL.md
rg --files /Users/karim/.codex | rg '/(using-superpowers|brainstorming|writing-plans|verification-before-completion)/SKILL\.md$'
sed -n '1,140p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/brainstorming/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/writing-plans/SKILL.md
sed -n '1,160p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/verification-before-completion/SKILL.md
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
file reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
ls -lh reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png || sha256sum reports/shadows/screenshots/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.png
rg -n "footprint-v1|footprint-v2|Broad shallow|directional|light direction|controlled multi-building|artifact|persistence|Selbrume|renderer|painter" reports/shadows/v2 packages/map_runtime/tool
rg -n "building|house|roof|tileset|placed element|footprint|shadow" packages/map_runtime/tool packages/map_editor/test packages/map_runtime/test reports/shadows/v2
sed -n '1,220p' reports/shadows/v2/shadow_v2_46_projected_building_shadow_footprint_calibration_selection_design.md
sed -n '1,240p' reports/shadows/v2/shadow_v2_48_projected_building_shadow_footprint_v1_micro_visual_artifact.md
sed -n '1,220p' reports/shadows/v2/shadow_v2_47_projected_building_shadow_footprint_calibration_v1_test_fixtures.md
sed -n '300,420p' packages/map_runtime/tool/shadow/shadow_v2_footprint_v1_micro_visual_artifact_test.dart
ls -1 reports/shadows/screenshots | rg 'shadow_v2_(43|45|48)|shadow_v2_50'
find packages/map_runtime/tool/shadow -maxdepth 1 -type f -name '*artifact_test.dart' -print | sort
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

## 25. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale observée :

```text
(no output)
```

Note :

```text
Le rapport créé est non suivi ; git diff --stat ne liste pas les fichiers non suivis.
```

## 26. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale observée :

```text
(no output)
```

Note :

```text
Le rapport créé est non suivi ; git diff --name-status ne liste pas les fichiers non suivis.
```

## 27. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale observée :

```text
(no output)
```

## 28. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale observée :

```text
?? reports/shadows/v2/shadow_v2_49_projected_building_shadow_v2_controlled_building_application_design.md
```

Confirmation :

```text
Un seul rapport Markdown est créé par ShadowV2-49.
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
- [x] Artifact Lot 48 audité
- [x] État de validation V2 analysé
- [x] Politique de direction de lumière tranchée
- [x] Options de prochain lot comparées
- [x] Corpus de bâtiments recommandé
- [x] JSON/persistence tranché
- [x] Renderer/painter explicitement exclus
- [x] Editor authoring explicitement exclu
- [x] Defaults core explicitement exclus
- [x] Option recommandée unique
- [x] Plan ShadowV2-50 précis
- [x] Fichiers interdits au Lot 50 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope
