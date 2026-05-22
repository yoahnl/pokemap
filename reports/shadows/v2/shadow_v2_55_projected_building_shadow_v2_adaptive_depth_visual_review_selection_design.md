# ShadowV2-55 — Projected Building Shadow V2 Adaptive Depth Visual Review / Selection Design Gate

## 1. Résumé exécutif

ShadowV2-55 est un design gate strictement documentaire. Aucun code, aucune image, aucune baseline et aucun fichier de production ne sont créés ou modifiés.

Décision :

```text
Option recommandée : Guard artifact before implementation.
```

Lecture principale :

```text
Standard V2 reste bon pour les bâtiments bas, mais il est trop court pour tall_shop_4x7.
Fixed C+ donne le meilleur endpoint tall fixe.
Adaptive C+ n'est pas visuellement meilleur que Fixed C+ sur tall_shop_4x7, car il lui est identique à l'endpoint.
Adaptive C+ est toutefois la meilleure stratégie produit candidate, parce qu'il atteint C+ sur le tall tout en revenant à Standard sur simple_house_4x5 et small_kiosk_3x4.
Reference-like est intéressant mais trop risqué comme stratégie générale.
wide_house_6x5 absent bloque une sélection finale avant implémentation.
```

Conclusion :

```text
Ne pas passer à JSON/persistence maintenant.
Ne pas implémenter Adaptive C+ maintenant.
Ne pas créer de profil tall officiel maintenant.
Produire d'abord un Lot 56 guard wide/mid-height.
```

## 2. Objectif du lot

Objectif exact :

```text
Analyser visuellement l'artifact ShadowV2-54,
comparer Standard V2 fixe, Fixed C, Fixed C+, Adaptive C, Adaptive C+ et Reference-like,
puis décider si la stratégie recommandée doit être :
- Standard V2 unique ;
- profil tall fixe ;
- adaptive depth bornée ;
- nouvel artifact de garde-fou wide/mid-height ;
- ou persistence JSON.
```

Réponses courtes :

```text
1. Standard V2 est-il définitivement insuffisant pour tall_shop_4x7 ?
   Oui pour l'objectif tall-building actuel : trop court / trop timide.

2. Fixed C est-il suffisant ?
   Suffisant comme compromis sûr, mais moins convaincant que C+ pour le tall pur.

3. Fixed C+ est-il meilleur que Fixed C ?
   Oui sur tall_shop_4x7 : plus présent, encore maîtrisé.

4. Adaptive C+ est-il préférable à Fixed C+ ?
   Pas visuellement sur tall, où il est identique ; oui conceptuellement comme stratégie bornée, sous réserve d'un guard wide/mid-height.

5. Reference-like est-il trop plaque / trop risqué ?
   Oui comme stratégie générale.

6. Les low guards prouvent-ils assez que l'adaptive ne casse pas les bâtiments bas ?
   Oui pour simple_house_4x5 et small_kiosk_3x4 seulement.

7. L'absence de wide_house_6x5 bloque-t-elle une sélection finale ?
   Oui, elle bloque l'implémentation et la persistence.

8. Faut-il sélectionner Adaptive C+ maintenant ?
   Non comme stratégie implémentable ; oui comme candidat principal à stress-tester.

9. Faut-il faire un artifact wide/mid-height guard avant implémentation ?
   Oui.

10. Faut-il passer à JSON/persistence maintenant ?
   Non.

11. Quel doit être exactement le Lot 56 ?
   ShadowV2-56 — Projected Building Shadow V2 Adaptive Depth Width Guard Artifact.
```

## 3. Rappel ShadowV2-53 / ShadowV2-54

ShadowV2-53 a rappelé le fait technique central :

```text
depth = metrics.visualHeight * footprint.depthRatio
```

Donc la profondeur est déjà proportionnelle à `visualHeight`. Le problème identifié n'est pas l'absence de proportion à la hauteur, mais le fait que `depthRatio` reste constant. Pour un bâtiment haut, un ratio fixe de `0.26` peut rester trop timide visuellement.

ShadowV2-54 a créé l'artifact :

```text
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
```

Structure :

```text
width = 1200
height = 928

Colonnes :
A = Standard V2 fixed
B = Fixed C
C = Fixed C+
D = Adaptive C
E = Adaptive C+
F = Reference-like

Lignes :
1 = tall_shop_4x7 shadow-only
2 = tall_shop_4x7 shadow + building
3 = simple_house_4x5 shadow + building
4 = small_kiosk_3x4 shadow + building
```

Résultat important :

```text
Sur tall_shop_4x7 :
D Adaptive C == B Fixed C
E Adaptive C+ == C Fixed C+

Sur simple_house_4x5 :
D/E Adaptive == Standard

Sur small_kiosk_3x4 :
D/E Adaptive == Standard
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
Aucune modification suivie préexistante.
Aucun fichier non suivi préexistant.
Les fichiers Lot 54 sont présents dans le dépôt au moment du Lot 55.
```

Fichiers préexistants non liés au Lot 55 :

```text
Aucun fichier non suivi.
```

Fichiers créés par ShadowV2-55 :

```text
reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
```

Fichiers modifiés par ShadowV2-55 :

```text
Aucun.
```

Fichiers supprimés par ShadowV2-55 :

```text
Aucun fichier final.
Deux fichiers transitoires hors scope apparus pendant les passes sub-agent / tooling ont été supprimés avant finalisation :
- skills/generate_project_overview.sh
- skills/project_overview.txt
Un troisième fichier transitoire hors scope apparu après le status initial a aussi été supprimé avant finalisation :
- pokemap_roadmap_mecaniques_fangame.md
```

Problèmes introduits par ShadowV2-55 :

```text
Deux fichiers non prévus sous skills/ sont apparus après les passes sub-agent / tooling :
- skills/generate_project_overview.sh
- skills/project_overview.txt
Un fichier racine non prévu est apparu après le status initial :
- pokemap_roadmap_mecaniques_fangame.md

Ces fichiers n'étaient pas présents au git status initial.
Ils ont été supprimés avant finalisation pour restaurer le périmètre strict.
Après ce nettoyage, deux changements hors-scope distincts sont apparus dans le workspace :
- AGENTS.md modifié ;
- skills/skills_README.md non suivi.

Ces deux changements ne font pas partie de ShadowV2-55 et n'ont pas été modifiés ou supprimés par le lot.
Le git status final les documente explicitement.
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills réellement consultés :

```text
superpowers:using-superpowers
superpowers:verification-before-completion
karpathy-guidelines
```

Note de chemin :

```text
Les chemins .system/superpowers annoncés dans certains environnements n'étaient pas présents localement.
Les skills Superpowers ont été lus depuis :
/Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté dans AGENTS.md.
Des skills Dart/Flutter génériques existent dans l'environnement, mais ce lot est design-only :
aucun test, aucune analyse ciblée et aucun changement Dart ne devaient être lancés.
Les points Flutter/Dart ont donc été vérifiés par audit du harness Lot 54 existant :
PictureRecorder/toImage/ImageByteFormat, artifact manuel sans golden, formule locale au harness,
et séparation entre artifact contrôlé et production runtime.
```

Sub-agents utilisés :

```text
Visual review sub-agent : Pauli, terminé.
Adaptive strategy sub-agent : Wegener, terminé.
Guard / risk sub-agent : Avicenna, terminé.
Scope / evidence sub-agent : Nietzsche, terminé.
```

Synthèse des sub-agents terminés :

```text
Visual review :
Standard est insuffisant pour tall_shop_4x7.
Adaptive C et Fixed C sont identiques sur tall ; Adaptive C+ et Fixed C+ sont identiques sur tall.
Reference-like a un risque plaque.

Adaptive strategy :
Adaptive C+ n'est pas visuellement meilleur que Fixed C+ au point tall, car c'est le même endpoint.
Son avantage est stratégique : il protège les bâtiments bas si la règle reste bornée.

Scope / evidence :
Lot55 doit créer exactement un rapport Markdown.
Aucun test, aucune image, aucun Dart, aucun JSON, aucun Selbrume, aucun renderer/painter.

Guard / risk :
Lot56 guard est recommandé avant toute implémentation ou persistence.
wide_house_6x5 est nécessaire pour vérifier que largeur seule ne déclenche pas l'adaptive.
medium_shop_5x6 est utile comme boundary case.
thin_prop_like doit rester un canary de mauvaise application, pas une cible supportée.
```

## 6. Décision AGENTS / design gate

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
37:4. Relevant skills and workflow rules.
401:Use this when starting work so agents find and invoke relevant skills before responding, clarifying, exploring, or editing.
860:1. Use `superpowers:subagent-driven-development` when applicable.
861:2. Dispatch one fresh subagent per task.
862:3. Each subagent implements, tests, reports final git status, and self-reviews.
863:4. Each subagent must not run Git write operations.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

```text
Le Lot 55 est un design gate.
La seule écriture autorisée est le rapport Markdown du Lot 55.
Les règles AGENTS renforcent l'interdiction de dériver vers code, persistence, renderer/painter, Selbrume ou tests.
```

## 7. Fichiers audités

Fichiers audités en lecture seule :

```text
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
```

Fichiers de contexte audités en lecture seule :

```text
reports/shadows/v2/shadow_v2_53_projected_building_shadow_v2_adaptive_footprint_depth_design.md
reports/shadows/v2/shadow_v2_52_projected_building_shadow_v2_tall_building_variant_matrix_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_controlled_multi_building_artifact_test.dart
```

## 8. Audit artifact Lot 54

Commandes :

```bash
file reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
```

Sorties :

```text
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png: PNG image data, 1200 x 928, 8-bit/color RGBA, non-interlaced
-rw-r--r--  1 karim  staff    20K May 22 18:13 reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
cff1a297270ab5b83f29ea15e1afbbf9f55481115bb71ff12151620a81261f58  reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
```

Contenu audité :

```text
Dimensions : 1200 x 928.
Colonnes : A/B/C/D/E/F.
Lignes : tall shadow-only, tall + building, simple house guard, small kiosk guard.
Pipeline déclaré : resolver -> adapter -> collection -> ShadowRuntimeRenderer.renderCollectionPass(...).
Low guards : simple_house_4x5 et small_kiosk_3x4.
Limite : wide_house_6x5 absent.
```

Analyse visuelle directe :

```text
L'image a pu être visualisée localement.
A est nettement plus court sur tall_shop_4x7.
B/D donnent une ombre tall plus crédible, encore sobre.
C/E donnent une ombre tall plus assumée, plus proche du besoin exprimé après Lot52.
F est plus large/haute-attache et peut lire comme une plaque plus risquée.
Sur les deux low guards, D/E ne grossissent pas l'ombre par rapport à A.
```

## 9. Audit formule adaptive locale

Commande :

```bash
rg -n "heightGate|ratioGate|adaptiveT|_clamp01|_lerp|effectiveDepthRatio|effectiveAttachYRatio|effectiveRearWidthRatio|effectiveOpacity|adaptive" packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
```

Lignes probantes du harness :

```text
551:  final heightGate = _clamp01((building.height - 80) / 32);
552:  final ratioGate = _clamp01((building.height / building.width - 1.25) / 0.50);
553:  final adaptiveT = heightGate * ratioGate;
555:    attachYRatio: _lerp(candidate.attachYRatio, candidate.targetAttachYRatio, adaptiveT),
557:    rearWidthRatio: _lerp(candidate.rearWidthRatio, candidate.targetRearWidthRatio, adaptiveT),
558:    depthRatio: _lerp(candidate.depthRatio, candidate.targetDepthRatio, adaptiveT),
560:    opacity: _lerp(candidate.opacity, candidate.targetOpacity, adaptiveT),
860:double _clamp01(double value) => value.clamp(0, 1).toDouble();
862:double _lerp(double start, double end, double t) => start + (end - start) * t;
```

Formule exacte :

```text
heightGate = clamp((visualHeight - 80) / 32, 0, 1)
ratioGate = clamp((visualHeight / visualWidth - 1.25) / 0.50, 0, 1)
adaptiveT = heightGate * ratioGate

effectiveDepthRatio = lerp(depthBase, depthTarget, adaptiveT)
effectiveAttachYRatio = lerp(attachBase, attachTarget, adaptiveT)
effectiveRearWidthRatio = lerp(rearWidthBase, rearWidthTarget, adaptiveT)
effectiveOpacity = lerp(opacityBase, opacityTarget, adaptiveT)
```

Décisions de scope :

```text
La formule est locale au harness Lot 54.
Elle n'est pas un modèle map_core.
Elle n'est pas persistée.
Elle n'est pas exposée à l'editor.
Elle n'est pas appliquée aux props fins.
Elle ne doit pas devenir un backfill silencieux.
```

Pourquoi elle protège `simple_house_4x5` :

```text
visualHeight = 80
visualWidth = 64
heightGate = 0
adaptiveT = 0
Donc Adaptive C / C+ reviennent à Standard.
```

Pourquoi elle protège `small_kiosk_3x4` :

```text
visualHeight = 64
visualWidth = 48
heightGate = 0
adaptiveT = 0
Donc Adaptive C / C+ reviennent à Standard.
```

Pourquoi elle ne prouve pas encore `wide_house_6x5` :

```text
wide_house_6x5 n'est pas dans l'image Lot 54.
Théoriquement, width=96 height=80 donne heightGate=0 et adaptiveT=0.
Mais la preuve visuelle contrôlée n'existe pas encore dans l'artifact Lot 54.
```

Pourquoi elle ne doit pas s'appliquer aux props fins :

```text
Une silhouette fine peut avoir un ratio height/width élevé sans être un bâtiment.
La formule a besoin d'un garde-fou de catégorie bâtiment / authoring approval.
Sans garde-fou de catégorie, un prop vertical pourrait déclencher à tort une ombre tall.
```

## 10. Analyse A — Standard V2 fixed

Paramètres :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
```

Géométrie tall :

```text
bounds: left=58.40 top=139.84 width=92.16 height=29.12
```

Analyse :

```text
Standard V2 est propre, sobre et reste bon pour les bâtiments bas.
Sur tall_shop_4x7, il sous-communique le volume vertical.
Il est donc insuffisant comme réponse finale au cas tall.
```

Décision :

```text
Suffisant comme base low-building.
Trop court pour tall_shop_4x7.
```

## 11. Analyse B — Fixed C

Paramètres :

```text
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.45
depthRatio: 0.38
skewXRatio: 0.08
opacity: 0.23
```

Géométrie tall :

```text
bounds: left=58.40 top=137.60 width=93.12 height=42.56
```

Analyse :

```text
Fixed C corrige clairement la timidité de Standard.
L'ombre reste sobre, attachée et lisible.
Elle est moins longue que C+, donc plus sûre, mais peut encore paraître un peu retenue si l'objectif est une présence tall plus affirmée.
```

Décision :

```text
Bon compromis sûr.
Pas le meilleur endpoint tall si C+ reste propre visuellement.
```

## 12. Analyse C — Fixed C+

Paramètres :

```text
attachYRatio: 0.80
frontWidthRatio: 1.30
rearWidthRatio: 1.47
depthRatio: 0.42
skewXRatio: 0.08
opacity: 0.22
```

Géométrie tall :

```text
bounds: left=58.08 top=137.60 width=94.08 height=47.04
```

Analyse :

```text
Fixed C+ est le meilleur endpoint tall pur dans l'image Lot 54.
Il donne davantage de profondeur que Fixed C sans basculer aussi largement que Reference-like.
Son opacité plus basse évite partiellement l'effet plaque.
```

Limite :

```text
Comme profil fixe, il exige une règle humaine ou editor-approved pour ne pas s'appliquer aux bâtiments bas.
```

Décision :

```text
Meilleur endpoint tall visuel.
Pas encore une stratégie complète.
```

## 13. Analyse D — Adaptive C

Règle :

```text
D == B sur tall_shop_4x7.
D == A sur simple_house_4x5 et small_kiosk_3x4.
```

Analyse :

```text
Adaptive C prouve que la formule peut atteindre un endpoint tall contrôlé tout en gardant Standard sur les low guards.
Visuellement, il n'est pas meilleur que Fixed C sur tall, puisqu'il est identique.
Son intérêt est stratégique : éviter une application fixe trop large.
```

Décision :

```text
Très bon candidat prudent.
Moins expressif que Adaptive C+ pour le tall.
```

## 14. Analyse E — Adaptive C+

Règle :

```text
E == C sur tall_shop_4x7.
E == A sur simple_house_4x5 et small_kiosk_3x4.
```

Analyse :

```text
Adaptive C+ combine le meilleur endpoint tall observé dans Lot54 avec le retour à Standard sur les deux low guards.
Il n'est pas visuellement meilleur que Fixed C+ sur tall, mais il est conceptuellement meilleur comme stratégie candidate si la cible produit est "tall seulement, low inchangé".
```

Limite :

```text
Cette conclusion ne couvre pas encore wide_house_6x5 ni les hauteurs intermédiaires.
```

Décision :

```text
Favori conceptuel actuel.
Pas encore sélectionnable pour implémentation.
```

## 15. Analyse F — Reference-like

Paramètres :

```text
attachYRatio: 0.78
frontWidthRatio: 1.34
rearWidthRatio: 1.50
depthRatio: 0.40
skewXRatio: 0.10
opacity: 0.23
```

Géométrie tall :

```text
bounds: left=57.12 top=135.36 width=97.28 height=44.80
```

Analyse :

```text
Reference-like a une masse intéressante et rappelle davantage certains grands bâtiments de référence.
Mais son attache plus haute, sa largeur plus importante et son skew renforcé augmentent le risque de plaque grise.
Il est moins sobre que C+ et moins facile à généraliser.
```

Décision :

```text
À rejeter comme stratégie générale.
Peut rester une référence de borne haute, pas un candidat officiel.
```

## 16. Low guards : simple_house et small_kiosk

simple_house_4x5 :

```text
Expected A/D/E:
frontLeft  = (58.40, 145.60)
frontRight = (141.60, 145.60)
rearRight  = (150.56, 166.40)
rearLeft   = (59.68, 166.40)
bounds: left=58.40 top=145.60 width=92.16 height=20.80
```

small_kiosk_3x4 :

```text
Expected A/D/E:
frontLeft  = (68.80, 148.48)
frontRight = (131.20, 148.48)
rearRight  = (137.92, 165.12)
rearLeft   = (69.76, 165.12)
bounds: left=68.80 top=148.48 width=69.12 height=16.64
```

Interprétation :

```text
Les low guards prouvent que la formule locale Lot54 ne grossit pas ces deux bâtiments bas.
Ils ne prouvent pas tous les bâtiments bas.
Ils ne prouvent pas les bâtiments larges.
Ils ne prouvent pas les sprites réels avec padding transparent.
```

Décision :

```text
Preuve suffisante pour dire "adaptive ne casse pas simple_house et small_kiosk".
Preuve insuffisante pour passer à implémentation ou persistence.
```

## 17. Réserve : wide_house absent

Constat :

```text
wide_house_6x5 n'est pas inclus dans l'artifact Lot 54.
```

Pourquoi c'est important :

```text
wide_house_6x5 est large et bas.
Il doit rester Standard.
Il vérifie que la largeur seule ne déclenche pas une réponse tall.
Il était présent dans Lot50 mais absent du guard Lot54.
Le risque est faible côté crash/runtime, mais medium-high côté calibration visuelle.
```

Calcul conceptuel attendu :

```text
width = 96
height = 80
heightGate = clamp((80 - 80) / 32, 0, 1) = 0
ratio = 80 / 96 = 0.83
ratioGate = clamp((0.83 - 1.25) / 0.50, 0, 1) = 0
adaptiveT = 0
```

Impact :

```text
Le calcul protège wide_house en théorie.
Mais le Lot 54 ne donne pas de preuve visuelle.
Son footprint large peut révéler une ombre trop plate ou trop large que simple_house et small_kiosk ne montrent pas.
L'absence de wide_house bloque une sélection finale avant implémentation.
```

## 18. Options étudiées

### Option A — Standard V2 unique

Analyse :

```text
Avantage : simplicité maximale, déjà validée pour les bâtiments bas.
Inconvénient : trop court pour tall_shop_4x7.
```

Décision :

```text
Rejetée comme stratégie finale.
```

### Option B — Fixed C+ tall profile

Analyse :

```text
Avantage : endpoint tall clair, simple, authorable.
Inconvénient : demande un choix manuel de profil tall et peut multiplier les presets.
```

Décision :

```text
Candidate viable, mais moins intéressante que l'adaptive si celle-ci passe les guards.
```

### Option C — Adaptive C+ strategy

Analyse :

```text
Avantage : atteint C+ sur tall, revient à Standard sur low guards, répond à l'intuition hauteur/ratio.
Inconvénient : règle automatique à borner, wide_house absent, props fins à exclure.
```

Décision :

```text
Meilleur candidat conceptuel.
Pas encore sélectionnable pour implémentation.
```

### Option D — Wide / mid-height guard artifact avant sélection

Analyse :

```text
Avantage : répond à la principale réserve du Lot 54.
Inconvénient : ajoute un lot avant modèle/persistence.
```

Décision :

```text
Option recommandée.
```

### Option E — JSON/persistence maintenant

Analyse :

```text
Avantage : avance vers usage réel.
Inconvénient : trop tôt tant que adaptive vs fixed tall et wide guard ne sont pas tranchés.
Risque additionnel : persister trop tôt peut figer une stratégie incomplète avant la preuve de round-trip footprint/adaptive.
```

Décision :

```text
Rejetée.
```

### Option F — Renderer / painter / banding

Analyse :

```text
Avantage : pourrait améliorer l'aspect plus tard.
Inconvénient : hors sujet ; le sujet actuel est la stratégie de profondeur.
```

Décision :

```text
Rejetée.
```

## 19. Adaptive C+ vs Fixed C+

Tranchage :

```text
Adaptive C+ n'est pas visuellement supérieur à Fixed C+ sur tall_shop_4x7.
Il est identique à Fixed C+ sur ce bâtiment.
```

Mais :

```text
Adaptive C+ est stratégiquement préférable à Fixed C+ si l'alternative est d'appliquer C+ trop largement.
Il garde l'endpoint C+ pour le tall et revient à Standard sur les deux low guards.
```

Comparaison :

```text
Fixed C+ :
  + très simple
  + endpoint tall clair
  - nécessite authoring/choix de profil
  - ne règle pas automatiquement les hauteurs intermédiaires

Adaptive C+ :
  + endpoint tall C+
  + low guards Standard
  + trajectoire progressive possible
  - automatisme à borner
  - wide/mid-height non prouvés
  - catégorie bâtiment obligatoire
```

Décision :

```text
Adaptive C+ devient le candidat stratégique principal.
Le Lot 55 ne le sélectionne pas encore pour implémentation.
```

## 20. Guard artifact vs implémentation directe

Question :

```text
Adaptive C+ est-il assez convaincant pour être sélectionné comme stratégie recommandée ?
```

Réponse :

```text
Il est assez convaincant pour devenir le candidat principal.
Il n'est pas assez prouvé pour être implémenté.
```

Question :

```text
Faut-il encore un artifact wide/mid-height guard avant toute implémentation ?
```

Réponse :

```text
Oui.
```

Pourquoi :

```text
Le Lot54 prouve endpoint tall et deux low guards.
Il ne prouve pas wide_house_6x5.
Il ne prouve pas un bâtiment moyen.
Il ne montre pas le comportement de la transition adaptiveT entre 0 et 1.
Il ne documente pas assez le risque des props fins.
```

Décision unique :

```text
Guard artifact before implementation.
```

## 21. Option recommandée

Option recommandée :

```text
Guard artifact before implementation.
```

Décision :

```text
Adaptive C+ strategy est le candidat conceptuel principal.
Mais le prochain lot doit être un artifact guard, pas une implémentation.
```

Classement visuel / stratégique :

```text
1. E — Adaptive C+
2. C — Fixed C+
3. D — Adaptive C
4. B — Fixed C
5. F — Reference-like
6. A — Standard V2 fixed
```

Note sur le classement :

```text
E et C sont identiques sur tall.
D et B sont identiques sur tall.
Le classement départage les ex aequo par stratégie produit : protection des low guards et risque de généralisation.
```

Analyse :

```text
Standard :
  bon low-building, insuffisant tall.

Fixed C :
  bon compromis, mais moins convaincant que C+ pour tall.

Fixed C+ :
  meilleur endpoint tall fixe.

Adaptive C :
  stratégie sûre, mais endpoint moins affirmé.

Adaptive C+ :
  meilleur candidat conceptuel ; endpoint C+ + low guards Standard.

Reference-like :
  visuellement intéressant mais trop risqué / plaque.
```

Low guards :

```text
simple_house :
  D/E reviennent à Standard, preuve positive.

small_kiosk :
  D/E reviennent à Standard, preuve positive.

wide_house absent :
  réserve majeure.

impact :
  bloque implémentation, modèle core et JSON/persistence.
```

Pourquoi :

```text
La stratégie Adaptive C+ répond le mieux à la cible produit : ombre tall plus assumée, mais pas de grossissement des bâtiments bas.
Cependant, une règle automatique sans wide/mid-height guard serait une décision trop rapide.
```

Pourquoi les autres options sont rejetées :

```text
Standard V2 unique : trop court pour tall.
Fixed C+ direct : viable mais moins no-code friendly si l'adaptive passe les guards.
Adaptive C+ direct : prometteur mais pas assez prouvé.
JSON/persistence : prématuré.
Renderer/painter : hors sujet.
Reference-like : trop risqué comme base.
```

Lot 56 doit faire :

```text
Créer un artifact contrôlé Adaptive Depth Width Guard.
Comparer Standard vs Adaptive C+ sur :
- wide_house_6x5 ;
- medium_shop_5x6 ;
- tall_shop_4x7 ;
- thin_prop_like_2x6 comme cas de risque non-officiel.
Vérifier que width seul ne déclenche pas l'adaptive.
Vérifier la transition mid-height.
Documenter que les props fins sont hors scope sans category guard.
```

Lot 56 ne doit pas faire :

```text
Ne pas implémenter map_core.
Ne pas persister JSON.
Ne pas créer de profil officiel.
Ne pas toucher renderer/painter.
Ne pas toucher Selbrume.
Ne pas créer baseline/golden.
Ne pas appliquer aux props fins.
```

## 22. Plan précis du Lot 56

Nom recommandé :

```text
ShadowV2-56 — Projected Building Shadow V2 Adaptive Depth Width Guard Artifact
```

Objectif :

```text
Générer un artifact contrôlé prouvant que la formule Adaptive C+ :
- reste Standard sur bâtiments larges/bas ;
- ne réagit pas à la largeur seule ;
- atteint C+ sur bâtiment haut ;
- expose clairement le risque des silhouettes fines non-bâtiments ;
- reste locale au harness.
```

Fichiers probables :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md
```

Corpus recommandé :

```text
Guard A — wide_house_6x5
width = 96
height = 80
ratio = 0.83
expected adaptiveT = 0
rôle = vérifier que largeur seule ne déclenche pas tall.

Guard B — medium_shop_5x6
width = 80
height = 96
ratio = 1.20
expected adaptiveT proche 0 selon ratioGate
rôle = vérifier un bâtiment moyen.

Guard C — tall_shop_4x7
width = 64
height = 112
ratio = 1.75
expected adaptiveT = 1
rôle = endpoint tall validé.

Guard D — thin_prop_like_2x6
width = 32
height = 96
ratio = 3.00
expected = ne pas valider automatiquement comme bâtiment sans category guard
rôle = documenter le risque.
```

Validations obligatoires :

```text
PNG contrôlé, manuel, non-baseline.
Pipeline resolver -> adapter -> renderer.
Standard vs Adaptive C+ sur chaque guard.
Calcul et documentation de heightGate, ratioGate, adaptiveT.
Preuve que wide_house reste Standard.
Preuve que tall_shop atteint C+.
Mention explicite que thin_prop_like n'est pas une ombre officielle de prop.
```

## 23. Fichiers explicitement interdits au Lot 56

Fichiers / zones interdits :

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
```

Interdictions techniques :

```text
matchesGoldenFile
golden toolkit
baseline
JSON/persistence
renderer/painter
editor authoring
map_core model
official tall profile
official adaptive formula
Selbrume screenshot harness
build_runner
```

## 24. Risques / réserves

Risques principaux :

```text
Adaptive C+ peut être choisi parce qu'il paraît "plus intelligent", alors que Lot54 prouve surtout une équivalence endpoint + low guards.
Fixed C+ reste plus simple qu'une formule adaptive.
wide_house_6x5 absent empêche une validation finale.
Les hauteurs intermédiaires ne sont pas visualisées.
Les sprites réels avec padding transparent peuvent changer les métriques perçues.
Les props fins doivent rester exclus sans category guard.
```

Réserve produit :

```text
La stratégie adaptive ne doit pas devenir une simulation physique.
Elle doit rester une calibration artistique bornée pour bâtiments contrôlés.
```

## 25. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Un seul rapport Markdown est créé. Aucun code, aucune image, aucun test, aucune baseline.
```

Le rapport compare-t-il réellement Adaptive C+ et Fixed C+ ?

```text
Oui. Il dit explicitement qu'ils sont identiques sur tall_shop_4x7 et que la différence est stratégique, pas visuelle sur ce cas.
```

Le rapport évite-t-il de sélectionner l'adaptive juste parce que c'est plus "intelligent" ?

```text
Oui. Il recommande un guard artifact avant implémentation.
```

Le rapport reconnaît-il que D/E égalent B/C sur tall ?

```text
Oui. C'est un point central du diagnostic.
```

Les low guards sont-ils interprétés correctement ?

```text
Oui. Ils prouvent simple_house et small_kiosk, pas tous les bâtiments.
```

L'absence de wide_house_6x5 est-elle traitée honnêtement ?

```text
Oui. Elle bloque l'implémentation et JSON/persistence.
```

Le plan Lot 56 évite-t-il Selbrume / baseline / production / renderer / painter ?

```text
Oui. Le Lot 56 recommandé est un artifact contrôlé sous tool + screenshot + rapport.
```

Le rapport contient-il toutes les preuves ?

```text
Oui : status initial, AGENTS, métadonnées image, formule adaptive, analyses A-F, low guards, wide absent, options, recommandation, plan Lot56, git final.
```

## 26. Regard critique sur le prompt

Le prompt est bien borné : il force une revue visuelle et empêche de transformer trop vite Adaptive C+ en modèle persistant.

Le point le plus utile est la question explicite :

```text
Adaptive C+ est-il préférable à Fixed C+ ?
```

Elle évite une confusion importante : sur tall_shop_4x7, Adaptive C+ n'est pas plus beau que Fixed C+, il est identique. Son avantage n'existe que comme stratégie de sélection automatique bornée.

Le prompt a aussi raison de rappeler `wide_house_6x5`. C'est la réserve la plus importante avant toute implémentation.

Limite du prompt :

```text
Il demande une décision unique, alors que la décision saine est en deux étages :
Adaptive C+ comme candidat conceptuel principal,
mais guard artifact comme prochain lot obligatoire.
```

La recommandation respecte cette tension en choisissant :

```text
Guard artifact before implementation.
```

## 27. Commandes lancées

Commandes de skills :

```bash
sed -n '1,220p' /Users/karim/.codex/skills/.system/superpowers/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/skills/.system/superpowers/verification-before-completion/SKILL.md
sed -n '1,220p' /Users/karim/.codex/skills/karpathy-guidelines/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/using-superpowers/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/verification-before-completion/SKILL.md
sed -n '1,220p' /Users/karim/.codex/plugins/cache/openai-curated/superpowers/004da724/skills/subagent-driven-development/SKILL.md
```

Sorties notables :

```text
Les deux premiers chemins .system/superpowers n'existaient pas.
Le skill karpathy-guidelines a été lu depuis /Users/karim/.codex/skills/karpathy-guidelines/SKILL.md.
Les skills Superpowers ont été lus depuis le cache plugin openai-curated.
```

Commandes d'audit obligatoires :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md

file reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
ls -lh reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png

rg -n "candidate-a-standard-v2-fixed|candidate-b-fixed-c-tall-deeper-softer|candidate-c-fixed-c-plus|candidate-d-adaptive-c|candidate-e-adaptive-c-plus|candidate-f-fixed-e-reference-like|heightGate|ratioGate|adaptiveT|simple_house_4x5|small_kiosk_3x4|wide_house_6x5|Reference-like|Fixed C\\+|Adaptive C\\+" reports/shadows/v2 packages/map_runtime/tool

rg -n "adaptive|heightGate|ratioGate|visualHeight|visualWidth|width|wide|persistence|JSON|Selbrume|renderer|painter|lampadaire|prop|asset-driven|editor-approved" reports/shadows/v2 packages/map_runtime/tool packages/map_core/lib

rg -n "heightGate|ratioGate|adaptiveT|_clamp01|_lerp|effectiveDepthRatio|effectiveAttachYRatio|effectiveRearWidthRatio|effectiveOpacity|adaptive" packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
```

Commandes de lecture ciblée :

```bash
sed -n '1,130p' reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
sed -n '240,470p' reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
sed -n '680,720p' reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
sed -n '52,180p' packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
sed -n '540,565p' packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
```

Commandes finales :

```bash
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Commandes / actions de nettoyage de scope :

```bash
ls -l skills/generate_project_overview.sh skills/project_overview.txt
ls -l pokemap_roadmap_mecaniques_fangame.md
git status --short --untracked-files=all
apply_patch delete skills/generate_project_overview.sh
apply_patch delete skills/project_overview.txt
apply_patch delete pokemap_roadmap_mecaniques_fangame.md
```

Sortie de contrôle avant nettoyage :

```text
-rwxr-xr-x  1 karim  staff    2984 May 22 18:51 skills/generate_project_overview.sh
-rw-r--r--  1 karim  staff  290713 May 22 18:51 skills/project_overview.txt
?? reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
?? skills/generate_project_overview.sh
?? skills/project_overview.txt
```

Sortie de contrôle du fichier racine avant nettoyage :

```text
-rw-r--r--  1 karim  staff  53855 May 22 18:58 pokemap_roadmap_mecaniques_fangame.md
```

Tests :

```text
Aucun test lancé. Lot 55 est design-only.
```

Analyze :

```text
Aucun analyze lancé. Lot 55 est design-only.
```

## 28. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
AGENTS.md | 1541 ++++++++-----------------------------------------------------
1 file changed, 199 insertions(+), 1342 deletions(-)
```

Interprétation :

```text
AGENTS.md est modifié hors scope.
Le rapport Lot 55 est non suivi tant qu'il n'est pas ajouté par l'utilisateur.
```

## 29. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
M	AGENTS.md
```

Interprétation :

```text
AGENTS.md est modifié hors scope.
```

## 30. git diff --check

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

## 31. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M AGENTS.md
?? reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
?? skills/skills_README.md
```

Inventaire final :

```text
Fichiers créés par Lot 55 :
- reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md

Fichiers modifiés par Lot 55 :
- Aucun.

Fichiers modifiés hors scope, apparus après le status initial :
- AGENTS.md

Fichiers non suivis hors scope, apparus après le status initial :
- skills/skills_README.md

Fichiers supprimés par Lot 55 :
- Aucun fichier final.
- skills/generate_project_overview.sh, fichier transitoire hors scope supprimé avant finalisation.
- skills/project_overview.txt, fichier transitoire hors scope supprimé avant finalisation.
- pokemap_roadmap_mecaniques_fangame.md, fichier transitoire hors scope supprimé avant finalisation.

Fichiers generated créés/modifiés par Lot 55 :
- Aucun.

Screenshots créés par Lot 55 :
- Aucun.

Baselines créées par Lot 55 :
- Aucune.

Fichiers de production modifiés :
- Aucun.

Fichiers map_core modifiés :
- Aucun.

Fichiers map_runtime modifiés :
- Aucun.

Fichiers map_editor modifiés :
- Aucun.

Fichiers Selbrume modifiés :
- Aucun.
```

Confirmation :

```text
Un seul rapport Markdown a été créé par ShadowV2-55.
Le status final n'est pas strictement limité au rapport à cause de changements hors scope apparus après le status initial :
AGENTS.md et skills/skills_README.md.
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
- [x] Artifact Lot 54 audité
- [x] Formule adaptive locale auditée
- [x] A Standard analysé
- [x] B Fixed C analysé
- [x] C Fixed C+ analysé
- [x] D Adaptive C analysé
- [x] E Adaptive C+ analysé
- [x] F Reference-like analysé
- [x] Adaptive C+ vs Fixed C+ tranché
- [x] Low guards analysés
- [x] Absence wide_house_6x5 traitée
- [x] Guard artifact vs implémentation directe tranché
- [x] JSON/persistence tranché
- [x] Renderer/painter explicitement exclus
- [x] Petits props / lampadaires hors scope
- [x] Option recommandée unique
- [x] Plan ShadowV2-56 précis
- [x] Fichiers interdits au Lot 56 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [ ] git status final conforme au scope
