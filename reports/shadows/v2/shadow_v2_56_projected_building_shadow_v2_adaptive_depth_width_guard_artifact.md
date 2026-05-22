# ShadowV2-56 — Projected Building Shadow V2 Adaptive Depth Width Guard Artifact

## 1. Résumé exécutif

ShadowV2-56 a créé un artifact visuel contrôlé, manuel et non-baseline pour tester les garde-fous de la stratégie Adaptive C+.

Résultat :

```text
Harness créé : packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
PNG créé : reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
Rapport créé : reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md
```

Le PNG fait `800 x 928` et contient les colonnes A-D et les 4 lignes prévues :

```text
A = wide_house_6x5
B = medium_shop_5x6
C = tall_shop_4x7
D = thin_prop_like_2x6

Ligne 1 = Standard shadow-only
Ligne 2 = Adaptive C+ shadow-only
Ligne 3 = Standard shadow + object
Ligne 4 = Adaptive C+ shadow + object
```

Décision de ce lot :

```text
L'artifact confirme les garde-fous attendus :
- wide_house_6x5 reste Standard ;
- medium_shop_5x6 reste Standard ;
- tall_shop_4x7 atteint C+ ;
- thin_prop_like_2x6 déclenche partiellement la formule et expose le risque d'une application naïve aux props fins.
```

Le lot ne choisit pas définitivement Adaptive C+. Il prépare un prochain design gate côté modèle.

## 2. Objectif du lot

Objectif exact :

```text
Générer un artifact PNG contrôlé prouvant que la stratégie Adaptive C+ :
- reste Standard sur les bâtiments larges/bas ;
- ne réagit pas à la largeur seule ;
- ne réagit pas à une hauteur moyenne si le ratio ne correspond pas à un vrai bâtiment haut ;
- atteint C+ sur un bâtiment haut validé ;
- expose clairement le risque des silhouettes fines non-bâtiments ;
- reste locale au harness.
```

Réponses :

```text
wide_house_6x5 ne déclenche pas Adaptive C+ : oui, adaptiveT = 0.
medium_shop_5x6 ne déclenche pas Adaptive C+ : oui, heightGate = 0.5 mais ratioGate = 0, donc adaptiveT = 0.
tall_shop_4x7 atteint C+ : oui, adaptiveT = 1.
thin_prop_like_2x6 montre le risque : oui, adaptiveT = 0.5.
La formule reste locale au harness : oui.
```

## 3. Rappel ShadowV2-55

ShadowV2-55 a conclu :

```text
Adaptive C+ est le meilleur candidat conceptuel.
Mais il ne doit pas être implémenté maintenant.
Il faut d'abord un guard artifact wide / mid-height.
```

Le Lot 56 devait donc vérifier :

```text
wide_house_6x5 ne déclenche pas l'adaptive ;
medium_shop_5x6 ne déclenche pas l'adaptive si le ratio n'est pas assez tall ;
tall_shop_4x7 atteint bien C+ ;
thin_prop_like_2x6 montre le risque si on applique la formule à un prop fin sans category guard.
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
```

Fichiers préexistants avant ShadowV2-56 :

```text
reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
```

Fichiers hors scope déjà présents :

```text
reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
```

Fichiers créés par ShadowV2-56 :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md
```

Fichiers modifiés par ShadowV2-56 :

```text
Aucun.
```

Fichiers supprimés par ShadowV2-56 :

```text
Aucun.
```

Problèmes introduits par ShadowV2-56 :

```text
Aucun identifié.
```

## 5. Lecture AGENTS.md et méthode suivie

Commandes :

```bash
find .. -name AGENTS.md -print
sed -n '1,260p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Extraits AGENTS.md lus :

```text
Instruction priority:
1. Direct user request.
2. Nearest AGENTS.md in the edited directory tree.
3. This root AGENTS.md.
4. User-referenced specs, roadmaps, reports, or lot files.
5. Local skills in skills/: skim skills/README.md, then read the selected skills/<skill-name>/SKILL.md.
6. MCP/docs/tooling guidance.
7. Default agent behavior.
```

```text
Never run Git write operations unless the user explicitly asks.
Allowed read-only commands:
git status --short --untracked-files=all
git diff
git diff --name-only
git log
git show
git branch
git worktree list
```

```text
Do not claim green status without fresh command evidence.
```

Vérification skills locaux :

```bash
if [ -f skills/README.md ]; then sed -n '1,220p' skills/README.md; else printf 'skills/README.md absent\n'; fi
```

Sortie :

```text
skills/README.md absent
```

Méthode réellement suivie :

```text
Pass 1 — Audit :
  AGENTS.md lu, status initial capturé, fichiers Lot54/Lot55/harnesses existants audités.

Pass 2 — Harness :
  Harness manuel créé uniquement sous packages/map_runtime/tool/shadow.
  Formule Adaptive C+ locale au harness.

Pass 3 — Visual guard review :
  Image générée puis inspectée visuellement.
  A/B restent Standard, C atteint C+, D montre le canary.

Pass 4 — Tests / analyze / evidence :
  Test ciblé lancé.
  Analyze ciblé lancé.
  PNG hash/taille/file collectés.
  Audit anti-dérive lancé.
  Git final lancé.
```

Sub-agents :

```text
AGENTS.md actuel ne les impose pas.
Le lot a donc utilisé les passes séparées équivalentes demandées.
```

## 6. Décision AGENTS / design gate déjà satisfait

Décision :

```text
Le design gate ShadowV2-55 était déjà satisfait.
ShadowV2-56 est un artifact manuel contrôlé.
Le lot n'ouvre pas map_core, JSON, persistence, renderer/painter, editor authoring ou Selbrume.
```

## 7. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md
```

Modifiés :

```text
Aucun fichier suivi.
```

Supprimés :

```text
Aucun.
```

Generated :

```text
Aucun generated.
```

Fichiers de production :

```text
Aucun.
```

## 8. Stratégie d’artifact width guard

La matrice teste deux modes sur quatre colonnes de garde :

```text
Modes :
- Standard V2 fixed ;
- Adaptive C+.

Guards :
- wide_house_6x5 ;
- medium_shop_5x6 ;
- tall_shop_4x7 ;
- thin_prop_like_2x6.
```

L'objectif n'est pas de choisir définitivement Adaptive C+. L'objectif est de vérifier que ses gates ne réagissent pas à la largeur seule, ni à une hauteur moyenne avec ratio insuffisant, et de rendre visible le risque d'un prop fin.

## 9. Guard cases contrôlés

```text
A — wide_house_6x5
width = 96
height = 80
left = 52
top = 80
heightGate = 0
ratioGate = 0
adaptiveT = 0
Expected Adaptive C+ = Standard

B — medium_shop_5x6
width = 80
height = 96
left = 60
top = 64
heightGate = 0.5
ratioGate = 0
adaptiveT = 0
Expected Adaptive C+ = Standard

C — tall_shop_4x7
width = 64
height = 112
left = 68
top = 48
heightGate = 1
ratioGate = 1
adaptiveT = 1
Expected Adaptive C+ = C+

D — thin_prop_like_2x6
width = 32
height = 96
left = 84
top = 64
heightGate = 0.5
ratioGate = 1
adaptiveT = 0.5
Expected = canary de risque, pas support officiel.
```

## 10. Shadow modes générés

Standard V2 fixed :

```text
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

Adaptive C+ :

```text
base:
  attachYRatio: 0.82
  frontWidthRatio: 1.30
  rearWidthRatio: 1.42
  depthRatio: 0.26
  skewXRatio: 0.08
  opacity: 0.24

target:
  attachYRatio: 0.80
  rearWidthRatio: 1.47
  depthRatio: 0.42
  opacity: 0.22

frontWidthRatio: 1.30
skewXRatio: 0.08
colorHexRgb: 606060
```

## 11. Formule Adaptive C+ locale au harness

Formule :

```text
heightGate = clamp((visualHeight - 80) / 32, 0, 1)
ratioGate = clamp((visualHeight / visualWidth - 1.25) / 0.50, 0, 1)
adaptiveT = heightGate * ratioGate

effectiveDepthRatio = lerp(0.26, 0.42, adaptiveT)
effectiveAttachYRatio = lerp(0.82, 0.80, adaptiveT)
effectiveRearWidthRatio = lerp(1.42, 1.47, adaptiveT)
effectiveOpacity = lerp(0.24, 0.22, adaptiveT)

frontWidthRatio = 1.30
skewXRatio = 0.08
colorHexRgb = 606060
```

Cette formule est uniquement dans :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
```

Elle n'est pas dans `map_core`, pas persistée, pas exposée à l'editor, et pas appliquée à Selbrume.

## 12. Description de l’image générée

```text
Chemin : reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
Dimensions : 800 x 928
Colonnes : A/B/C/D
Lignes : Standard shadow-only, Adaptive shadow-only, Standard shadow + object, Adaptive shadow + object
Fond : #D8E0C8
Grille : #E6ECD8
Séparateurs : #B5BEA7
Labels : vectoriels simples
```

## 13. Pipeline de rendu utilisé

Pipeline utilisé pour chaque cellule :

```text
ProjectBuildingShadowPreset
ProjectElementProjectedBuildingShadowConfig
StaticShadowVisualMetrics
-> resolveProjectedBuildingShadowGeometry(...)
-> createProjectedBuildingShadowRuntimeInstruction(...)
-> ShadowRuntimeInstructionCollection
-> ShadowRuntimeRenderer.renderCollectionPass(...)
```

Audit source du harness :

```text
resolveProjectedBuildingShadowGeometry(...)
createProjectedBuildingShadowRuntimeInstruction(...)
ShadowRuntimeRenderer().renderCollectionPass(...)
ProjectedShadowFootprintTuning(...)
```

Le harness ne construit pas manuellement `ShadowRuntimeRenderInstruction`.

## 14. Gates calculés : heightGate / ratioGate / adaptiveT

```text
wide_house_6x5:
heightGate = 0
ratioGate = 0
adaptiveT = 0

medium_shop_5x6:
heightGate = 0.5
ratioGate = 0
adaptiveT = 0

tall_shop_4x7:
heightGate = 1
ratioGate = 1
adaptiveT = 1

thin_prop_like_2x6:
heightGate = 0.5
ratioGate = 1
adaptiveT = 0.5
```

Ces valeurs sont vérifiées dans le test avec `_expectGateClose(...)`.

## 15. Géométries / points générés — Standard

A — wide_house_6x5 Standard :

```text
frontLeft  = (37.60, 145.60)
frontRight = (162.40, 145.60)
rearRight  = (175.84, 166.40)
rearLeft   = (39.52, 166.40)
bounds: left=37.60 top=145.60 width=138.24 height=20.80
opacity=0.24 colorHexRgb=606060
```

B — medium_shop_5x6 Standard :

```text
frontLeft  = (48.00, 142.72)
frontRight = (152.00, 142.72)
rearRight  = (163.20, 167.68)
rearLeft   = (49.60, 167.68)
bounds: left=48.00 top=142.72 width=115.20 height=24.96
opacity=0.24 colorHexRgb=606060
```

C — tall_shop_4x7 Standard :

```text
frontLeft  = (58.40, 139.84)
frontRight = (141.60, 139.84)
rearRight  = (150.56, 168.96)
rearLeft   = (59.68, 168.96)
bounds: left=58.40 top=139.84 width=92.16 height=29.12
opacity=0.24 colorHexRgb=606060
```

D — thin_prop_like_2x6 Standard :

```text
frontLeft  = (79.20, 142.72)
frontRight = (120.80, 142.72)
rearRight  = (125.28, 167.68)
rearLeft   = (79.84, 167.68)
bounds: left=79.20 top=142.72 width=46.08 height=24.96
opacity=0.24 colorHexRgb=606060
```

## 16. Géométries / points générés — Adaptive C+

A — wide_house_6x5 Adaptive C+ :

```text
Identique au Standard.
frontLeft  = (37.60, 145.60)
frontRight = (162.40, 145.60)
rearRight  = (175.84, 166.40)
rearLeft   = (39.52, 166.40)
bounds: left=37.60 top=145.60 width=138.24 height=20.80
adaptiveT=0 opacity=0.24 colorHexRgb=606060
```

B — medium_shop_5x6 Adaptive C+ :

```text
Identique au Standard.
frontLeft  = (48.00, 142.72)
frontRight = (152.00, 142.72)
rearRight  = (163.20, 167.68)
rearLeft   = (49.60, 167.68)
bounds: left=48.00 top=142.72 width=115.20 height=24.96
adaptiveT=0 opacity=0.24 colorHexRgb=606060
```

C — tall_shop_4x7 Adaptive C+ :

```text
Atteint C+.
frontLeft  = (58.40, 137.60)
frontRight = (141.60, 137.60)
rearRight  = (152.16, 184.64)
rearLeft   = (58.08, 184.64)
bounds: left=58.08 top=137.60 width=94.08 height=47.04
adaptiveT=1 opacity=0.22 colorHexRgb=606060
```

D — thin_prop_like_2x6 Adaptive C+ :

```text
Déclenchement partiel canary.
frontLeft  = (79.20, 141.76)
frontRight = (120.80, 141.76)
rearRight  = (125.68, 174.40)
rearLeft   = (79.44, 174.40)
bounds: left=79.20 top=141.76 width=46.48 height=32.64
adaptiveT=0.5 opacity=0.23 colorHexRgb=606060
```

Tuning effectif D :

```text
attachYRatio = 0.81
frontWidthRatio = 1.30
rearWidthRatio = 1.445
depthRatio = 0.34
skewXRatio = 0.08
opacity = 0.23
```

## 17. Analyse canary thin_prop_like

`thin_prop_like_2x6` n'est pas un bâtiment officiellement supporté par la stratégie building shadow.

Le canary montre :

```text
heightGate = 0.5
ratioGate = 1
adaptiveT = 0.5
```

Donc une application naïve de la formule à une silhouette fine déclencherait une ombre partiellement approfondie. Ce résultat est utile comme signal de risque, pas comme validation de support.

Décision :

```text
Toute future stratégie Adaptive C+ devra être limitée aux bâtiments contrôlés.
Un category guard / authoring approval est obligatoire avant tout modèle ou persistence.
Les props fins, lampadaires et poteaux restent hors scope.
```

## 18. Assertions du test

Le test vérifie :

```text
image.width == 800
image.height == 928
PNG écrit
fichier existe
fichier size > 0
background pixel == #D8E0C8

Pour chaque colonne :
  Standard shadow-only pixel au centroïde != background
  Adaptive shadow-only pixel au centroïde != background
  Standard shadow + object : object pixel visible
  Adaptive shadow + object : object pixel visible
  visible shadow pixel != background

Pour chaque guard :
  Standard points et bounds
  Adaptive C+ points et bounds
  opacity attendue
  colorHexRgb == 606060
  heightGate
  ratioGate
  adaptiveT

Cas spécifiques :
  wide_house Adaptive C+ == Standard
  medium_shop Adaptive C+ == Standard
  tall_shop Adaptive C+ == C+
  thin_prop_like tuning canary
```

## 19. Résultat de génération PNG

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
00:00 +0: generates projected building shadow v2 adaptive depth width guard artifact
00:00 +1: All tests passed!
```

## 20. Hash / taille / chemin du PNG

Commande :

```bash
ls -lh reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
shasum -a 256 reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
file reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
```

Sortie :

```text
-rw-r--r--@ 1 karim  staff    15K May 22 19:25 reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
32f578b4f0306c0bb01442c5f6e415cbe86620312a08c2f78c18ca74aaab297f  reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png: PNG image data, 800 x 928, 8-bit/color RGBA, non-interlaced
```

## 21. Résultats des tests

Commande :

```bash
cd packages/map_runtime && flutter test tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
```

Résultat :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
00:00 +0: generates projected building shadow v2 adaptive depth width guard artifact
00:00 +1: All tests passed!
```

## 22. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
```

Sortie complète :

```text
Analyzing shadow_v2_adaptive_depth_width_guard_artifact_test.dart...
No issues found! (ran in 1.4s)
```

## 23. Audit anti-dérive

Commande :

```bash
rg -n "matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
```

Sortie :

```text
```

Interprétation :

```text
Aucun hit dans le harness Lot 56.
```

## 24. Ce qui n’a volontairement pas été modifié

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
reports/shadows/screenshots/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix.png
project.json
ShadowRuntimeRenderer
MapLayersComponent
PlayableMapGame
runtime_projected_building_shadow_collection.dart
projected_building_shadow_runtime_adapter.dart
editor_static_shadow_preview_painter.dart
MapGridPainter
resolveProjectedBuildingShadowGeometry(...)
createProjectedStaticShadowOpacityBands(...)
ProjectedShadowFootprintTuning defaults
```

## 25. Ce qui n’a volontairement pas été créé

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
profil tall officiel persistant
formule adaptive persistée
support officiel pour props fins
```

## 26. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
```

Interprétation :

```text
Aucune modification suivie.
Les fichiers Lot56 sont non suivis tant que l'utilisateur ne les ajoute pas.
```

## 27. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
```

Interprétation :

```text
Aucune modification suivie.
```

## 28. git diff --check

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

## 29. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
?? reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
?? reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
?? reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md
```

Inventaire final :

```text
Fichiers créés par Lot 56 :
- packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
- reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png
- reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md

Fichiers préexistants hors Lot 56 :
- reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md

Fichiers modifiés par Lot 56 :
- Aucun.

Fichiers supprimés par Lot 56 :
- Aucun.

Fichiers generated créés/modifiés par Lot 56 :
- Aucun.

Screenshots créés par Lot 56 :
- reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png

Baselines créées par Lot 56 :
- Aucune.

Fichiers de production modifiés :
- Aucun.
```

## 30. Analyse visuelle provisoire

Lecture de l'image :

```text
A wide_house_6x5 :
  Standard et Adaptive C+ sont visuellement identiques.
  La largeur seule ne déclenche pas l'adaptive.

B medium_shop_5x6 :
  Standard et Adaptive C+ sont visuellement identiques.
  La hauteur moyenne seule ne suffit pas lorsque le ratio n'est pas tall.

C tall_shop_4x7 :
  Adaptive C+ est plus profond que Standard et atteint le profil C+ attendu.

D thin_prop_like_2x6 :
  Adaptive C+ s'approfondit partiellement.
  L'image montre le risque d'une application naïve aux silhouettes fines.
```

Lecture produit :

```text
Adaptive C+ passe ce guard artifact pour les bâtiments contrôlés A/B/C.
Le canary D confirme que la stratégie doit être limitée aux bâtiments par category guard / authoring approval.
```

## 31. Risques / réserves

```text
L'artifact reste contrôlé et ne teste pas des sprites réels avec padding transparent.
Il ne teste pas Selbrume.
Il ne valide pas encore le modèle map_core.
Il ne valide pas la persistence JSON.
Il ne définit pas comment l'editor autorisera ou refusera l'adaptive.
Le canary thin_prop_like confirme le besoin d'un garde-fou de catégorie.
```

## 32. Auto-critique

Le lot a-t-il créé une baseline par accident ?

```text
Non. Aucun fichier sous reports/shadows/baselines.
```

Le PNG est-il bien un artifact manuel ?

```text
Oui. Il est écrit par un harness ciblé sous packages/map_runtime/tool/shadow.
```

Le test écrit-il seulement l'image autorisée ?

```text
Oui. Un seul PNG est écrit : shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png.
```

L'image permet-elle vraiment de tester width-only / mid-height / tall endpoint / thin canary ?

```text
Oui. Les quatre colonnes correspondent exactement aux quatre guards.
```

Les guards prouvent-ils que width seul ne déclenche pas l'adaptive ?

```text
Oui pour wide_house_6x5 : adaptiveT = 0 et Adaptive C+ == Standard.
```

Le thin_prop_like est-il bien présenté comme risque, pas comme support officiel ?

```text
Oui. Le rapport le qualifie explicitement de canary et exclut le support officiel des props fins.
```

Les variantes sont-elles rendues via resolver + adapter + renderer ?

```text
Oui. Le harness appelle resolveProjectedBuildingShadowGeometry, createProjectedBuildingShadowRuntimeInstruction et ShadowRuntimeRenderer.renderCollectionPass.
```

Le harness dépend-il de Selbrume ou d'un asset externe ?

```text
Non.
```

Les defaults ProjectedShadowFootprintTuning() sont-ils inchangés ?

```text
Oui. Le harness utilise des ProjectedShadowFootprintTuning explicites et ne modifie aucun default.
```

JSON/persistence est-il hors scope ?

```text
Oui.
```

Le rapport contient-il toutes les preuves ?

```text
Oui : status initial/final, AGENTS, commandes, test, analyze, PNG metadata, anti-dérive, code complet.
```

## 33. Regard critique sur le prompt

Le prompt est strict et utile : il force la preuve visuelle avant tout passage au modèle ou à la persistence.

Le point le plus important est l'inclusion de `thin_prop_like_2x6`. Sans ce canary, on pourrait conclure trop vite que la formule adaptive est sûre. Le résultat partiel sur D montre précisément qu'une future implémentation devra avoir une condition de catégorie bâtiment.

La contrainte de ne pas choisir définitivement est également saine : le Lot 56 prouve un guard, mais ne définit pas encore l'API core, l'authoring, ni la persistence.

## 34. Prochain lot recommandé

Si l'Adaptive C+ passe le guard :

```text
ShadowV2-57 — Projected Building Shadow V2 Adaptive Depth Core Design Gate
```

Objectif recommandé :

```text
Définir comment représenter proprement une stratégie Adaptive C+ dans map_core,
sans implémenter encore :
- preset strategy ;
- derived tuning resolver ;
- building-only guard ;
- category / authoring approval ;
- JSON/persistence implications.
```

Recommandation :

```text
Passer au design gate core.
Ne pas implémenter directement.
```

## 35. Code complet des fichiers créés/modifiés

### packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart

```dart
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart'
    show
        ProjectBuildingShadowPreset,
        ProjectElementProjectedBuildingShadowConfig,
        ProjectedBuildingShadowGeometry,
        ProjectedBuildingShadowGeometryMode,
        ProjectedBuildingShadowPoint,
        ProjectedShadowAnchor,
        ProjectedShadowAppearance,
        ProjectedShadowDirection,
        ProjectedShadowFootprintTuning,
        ProjectedShadowOffset,
        ProjectedShadowShapeTuning,
        ProjectedShadowTimeOfDayMode,
        ShadowRenderPass,
        StaticShadowVisualMetrics,
        resolveProjectedBuildingShadowGeometry;
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

const _artifactWidth = 800;
const _artifactHeight = 928;
const _columnWidth = 200;
const _headerHeight = 32;
const _rowHeight = 224;
const _row0Top = _headerHeight;
const _row1Top = 256;
const _row2Top = 480;
const _row3Top = 704;
const _artifactPath =
    '../../reports/shadows/screenshots/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard.png';

const _backgroundColor = ui.Color(0xFFD8E0C8);
const _gridColor = ui.Color(0xFFE6ECD8);
const _dividerColor = ui.Color(0xFFB5BEA7);
const _labelColor = ui.Color(0xFF343A3D);
const _bodyColor = ui.Color(0xFFE9D7B9);
const _roofColor = ui.Color(0xFFB7655A);
const _outlineColor = ui.Color(0xFF343A3D);
const _doorColor = ui.Color(0xFF7E5547);
const _windowColor = ui.Color(0xFF8EC6D8);
const _signColor = ui.Color(0xFFD5C185);
const _metalColor = ui.Color(0xFF6B7480);

const _standardMode = _ShadowMode.fixed(
  id: 'standard-v2-fixed',
  label: 'Standard',
  attachYRatio: 0.82,
  frontWidthRatio: 1.30,
  rearWidthRatio: 1.42,
  depthRatio: 0.26,
  skewXRatio: 0.08,
  opacity: 0.24,
);

const _adaptiveCPlusMode = _ShadowMode.adaptive(
  id: 'adaptive-c-plus',
  label: 'Adaptive C+',
  attachYRatio: 0.82,
  targetAttachYRatio: 0.80,
  frontWidthRatio: 1.30,
  rearWidthRatio: 1.42,
  targetRearWidthRatio: 1.47,
  depthRatio: 0.26,
  targetDepthRatio: 0.42,
  skewXRatio: 0.08,
  opacity: 0.24,
  targetOpacity: 0.22,
);

const _shadowModes = [_standardMode, _adaptiveCPlusMode];

const _guardCases = [
  _GuardCase(
    id: 'wide_house_6x5',
    label: 'A',
    left: 52,
    top: 80,
    width: 96,
    height: 80,
    expectedHeightGate: 0,
    expectedRatioGate: 0,
    expectedAdaptiveT: 0,
    objectKind: _GuardObjectKind.wideHouse,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 37.60, y: 145.60),
        _ExpectedPoint(x: 162.40, y: 145.60),
        _ExpectedPoint(x: 175.84, y: 166.40),
        _ExpectedPoint(x: 39.52, y: 166.40),
      ],
      left: 37.60,
      top: 145.60,
      width: 138.24,
      height: 20.80,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 37.60, y: 145.60),
        _ExpectedPoint(x: 162.40, y: 145.60),
        _ExpectedPoint(x: 175.84, y: 166.40),
        _ExpectedPoint(x: 39.52, y: 166.40),
      ],
      left: 37.60,
      top: 145.60,
      width: 138.24,
      height: 20.80,
    ),
  ),
  _GuardCase(
    id: 'medium_shop_5x6',
    label: 'B',
    left: 60,
    top: 64,
    width: 80,
    height: 96,
    expectedHeightGate: 0.5,
    expectedRatioGate: 0,
    expectedAdaptiveT: 0,
    objectKind: _GuardObjectKind.mediumShop,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 48.00, y: 142.72),
        _ExpectedPoint(x: 152.00, y: 142.72),
        _ExpectedPoint(x: 163.20, y: 167.68),
        _ExpectedPoint(x: 49.60, y: 167.68),
      ],
      left: 48.00,
      top: 142.72,
      width: 115.20,
      height: 24.96,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 48.00, y: 142.72),
        _ExpectedPoint(x: 152.00, y: 142.72),
        _ExpectedPoint(x: 163.20, y: 167.68),
        _ExpectedPoint(x: 49.60, y: 167.68),
      ],
      left: 48.00,
      top: 142.72,
      width: 115.20,
      height: 24.96,
    ),
  ),
  _GuardCase(
    id: 'tall_shop_4x7',
    label: 'C',
    left: 68,
    top: 48,
    width: 64,
    height: 112,
    expectedHeightGate: 1,
    expectedRatioGate: 1,
    expectedAdaptiveT: 1,
    objectKind: _GuardObjectKind.tallShop,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 139.84),
        _ExpectedPoint(x: 141.60, y: 139.84),
        _ExpectedPoint(x: 150.56, y: 168.96),
        _ExpectedPoint(x: 59.68, y: 168.96),
      ],
      left: 58.40,
      top: 139.84,
      width: 92.16,
      height: 29.12,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 58.40, y: 137.60),
        _ExpectedPoint(x: 141.60, y: 137.60),
        _ExpectedPoint(x: 152.16, y: 184.64),
        _ExpectedPoint(x: 58.08, y: 184.64),
      ],
      left: 58.08,
      top: 137.60,
      width: 94.08,
      height: 47.04,
    ),
  ),
  _GuardCase(
    id: 'thin_prop_like_2x6',
    label: 'D',
    left: 84,
    top: 64,
    width: 32,
    height: 96,
    expectedHeightGate: 0.5,
    expectedRatioGate: 1,
    expectedAdaptiveT: 0.5,
    objectKind: _GuardObjectKind.thinPropLike,
    standardExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 79.20, y: 142.72),
        _ExpectedPoint(x: 120.80, y: 142.72),
        _ExpectedPoint(x: 125.28, y: 167.68),
        _ExpectedPoint(x: 79.84, y: 167.68),
      ],
      left: 79.20,
      top: 142.72,
      width: 46.08,
      height: 24.96,
    ),
    adaptiveExpected: _ExpectedGeometry(
      points: [
        _ExpectedPoint(x: 79.20, y: 141.76),
        _ExpectedPoint(x: 120.80, y: 141.76),
        _ExpectedPoint(x: 125.68, y: 174.40),
        _ExpectedPoint(x: 79.44, y: 174.40),
      ],
      left: 79.20,
      top: 141.76,
      width: 46.48,
      height: 32.64,
    ),
  ),
];

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('generates projected building shadow v2 adaptive depth width guard artifact',
      () async {
    final image = await _renderArtifact();
    expect(image.width, _artifactWidth);
    expect(image.height, _artifactHeight);

    final backgroundPixel = await _pixelAt(image, 12, 44);
    expect(backgroundPixel, _rgba(_backgroundColor));

    for (var guardIndex = 0; guardIndex < _guardCases.length; guardIndex += 1) {
      final guard = _guardCases[guardIndex];
      final columnLeft = guardIndex * _columnWidth;
      final gates = _gatesFor(guard);
      _expectGateClose(gates.heightGate, guard.expectedHeightGate);
      _expectGateClose(gates.ratioGate, guard.expectedRatioGate);
      _expectGateClose(gates.adaptiveT, guard.expectedAdaptiveT);

      for (final mode in _shadowModes) {
        final expected = mode.isAdaptive ? guard.adaptiveExpected : guard.standardExpected;
        final geometry = _geometryFor(mode, guard);
        final instruction = _instructionFor(mode, guard);
        final tuning = _effectiveTuningFor(mode, guard);

        expect(geometry.opacity, closeTo(tuning.opacity, 0.000001));
        expect(geometry.colorHexRgb, '606060');
        _expectGeometryClose(geometry, expected);
        _expectBoundsClose(instruction, expected);

        final shadowOnlyRowTop = mode.isAdaptive ? _row1Top : _row0Top;
        final centroid = _centroid(geometry);
        final shadowOnlyPixel = await _pixelAt(
          image,
          columnLeft + centroid.x.round(),
          shadowOnlyRowTop + centroid.y.round(),
        );
        expect(
          shadowOnlyPixel,
          isNot(backgroundPixel),
          reason: '${guard.id}/${mode.id} shadow-only should render',
        );

        final objectRowTop = mode.isAdaptive ? _row3Top : _row2Top;
        final objectPixel = await _objectPixel(
          image,
          columnLeft: columnLeft,
          rowTop: objectRowTop,
          guard: guard,
        );
        expect(
          objectPixel,
          isNot(backgroundPixel),
          reason: '${guard.id}/${mode.id} object should render',
        );

        final visibleShadowPoint = _visibleShadowPoint(geometry);
        final visibleShadowPixel = await _pixelAt(
          image,
          columnLeft + visibleShadowPoint.x.round(),
          objectRowTop + visibleShadowPoint.y.round(),
        );
        expect(
          visibleShadowPixel,
          isNot(backgroundPixel),
          reason: '${guard.id}/${mode.id} visible shadow should render',
        );
      }
    }

    final wideStandard = _geometryFor(_standardMode, _guardCases[0]);
    final wideAdaptive = _geometryFor(_adaptiveCPlusMode, _guardCases[0]);
    _expectGeometryClose(wideAdaptive, _guardCases[0].standardExpected);
    _expectGeometryClose(wideStandard, _guardCases[0].standardExpected);

    final mediumStandard = _geometryFor(_standardMode, _guardCases[1]);
    final mediumAdaptive = _geometryFor(_adaptiveCPlusMode, _guardCases[1]);
    _expectGeometryClose(mediumAdaptive, _guardCases[1].standardExpected);
    _expectGeometryClose(mediumStandard, _guardCases[1].standardExpected);

    final tallAdaptive = _geometryFor(_adaptiveCPlusMode, _guardCases[2]);
    _expectGeometryClose(tallAdaptive, _guardCases[2].adaptiveExpected);

    final thinTuning = _effectiveTuningFor(_adaptiveCPlusMode, _guardCases[3]);
    expect(thinTuning.attachYRatio, closeTo(0.81, 0.000001));
    expect(thinTuning.frontWidthRatio, closeTo(1.30, 0.000001));
    expect(thinTuning.rearWidthRatio, closeTo(1.445, 0.000001));
    expect(thinTuning.depthRatio, closeTo(0.34, 0.000001));
    expect(thinTuning.skewXRatio, closeTo(0.08, 0.000001));
    expect(thinTuning.opacity, closeTo(0.23, 0.000001));

    final pngBytes = await _pngBytes(image);
    await _writePng(pngBytes);

    final file = File(_artifactPath);
    expect(file.existsSync(), isTrue);
    expect(file.lengthSync(), greaterThan(0));
  });
}

Future<ui.Image> _renderArtifact() async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);

  canvas.drawRect(
    const ui.Rect.fromLTWH(0, 0, _artifactWidth + 0.0, _artifactHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );

  for (var index = 0; index < _guardCases.length; index += 1) {
    final guard = _guardCases[index];
    final columnLeft = (index * _columnWidth).toDouble();
    _drawLabel(canvas, guard.label, columnLeft: columnLeft);
    _drawCell(canvas, _standardMode, guard, columnLeft, _row0Top.toDouble(), false);
    _drawCell(canvas, _adaptiveCPlusMode, guard, columnLeft, _row1Top.toDouble(), false);
    _drawCell(canvas, _standardMode, guard, columnLeft, _row2Top.toDouble(), true);
    _drawCell(canvas, _adaptiveCPlusMode, guard, columnLeft, _row3Top.toDouble(), true);
  }

  _drawDividers(canvas);

  return recorder.endRecording().toImage(_artifactWidth, _artifactHeight);
}

void _drawCell(
  ui.Canvas canvas,
  _ShadowMode mode,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
  bool drawObject,
) {
  _drawCellBackground(canvas, columnLeft, rowTop);
  _drawShadow(canvas, mode, guard, columnLeft, rowTop);
  if (drawObject) {
    _drawGuardObject(canvas, guard, columnLeft, rowTop);
  }
}

void _drawCellBackground(ui.Canvas canvas, double left, double top) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, _columnWidth + 0.0, _rowHeight + 0.0),
    ui.Paint()..color = _backgroundColor,
  );
  _drawGrid(canvas, left: left, top: top);
}

void _drawGrid(ui.Canvas canvas, {required double left, required double top}) {
  final paint = ui.Paint()
    ..color = _gridColor
    ..strokeWidth = 1;
  for (var x = left; x <= left + _columnWidth; x += 32) {
    canvas.drawLine(ui.Offset(x, top), ui.Offset(x, top + _rowHeight), paint);
  }
  for (var y = top; y <= top + _rowHeight; y += 32) {
    canvas.drawLine(ui.Offset(left, y), ui.Offset(left + _columnWidth, y), paint);
  }
}

void _drawDividers(ui.Canvas canvas) {
  final paint = ui.Paint()
    ..color = _dividerColor
    ..strokeWidth = 1;
  for (var x = _columnWidth; x < _artifactWidth; x += _columnWidth) {
    canvas.drawLine(
      ui.Offset(x - 0.5, 0),
      ui.Offset(x - 0.5, _artifactHeight + 0.0),
      paint,
    );
  }
  for (final y in [_headerHeight, _row1Top, _row2Top, _row3Top]) {
    canvas.drawLine(
      ui.Offset(0, y - 0.5),
      ui.Offset(_artifactWidth + 0.0, y - 0.5),
      paint,
    );
  }
}

void _drawShadow(
  ui.Canvas canvas,
  _ShadowMode mode,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  canvas.save();
  canvas.translate(columnLeft, rowTop);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    _collectionFor(mode, guard),
    ShadowRenderPass.groundStatic,
  );
  canvas.restore();
}

ShadowRuntimeInstructionCollection _collectionFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  return ShadowRuntimeInstructionCollection(
    instructions: [_instructionFor(mode, guard)],
  );
}

ShadowRuntimeRenderInstruction _instructionFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  return createProjectedBuildingShadowRuntimeInstruction(
    _geometryFor(mode, guard),
  );
}

ProjectedBuildingShadowGeometry _geometryFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  final geometry = resolveProjectedBuildingShadowGeometry(
    config: _shadowConfigFor(mode),
    preset: _shadowPresetFor(mode, guard),
    metrics: _metricsForGuard(guard),
  );
  if (geometry == null) {
    throw StateError('${mode.id}/${guard.id} did not produce geometry');
  }
  return geometry;
}

StaticShadowVisualMetrics _metricsForGuard(_GuardCase guard) {
  return StaticShadowVisualMetrics(
    left: guard.left,
    top: guard.top,
    visualWidth: guard.width,
    visualHeight: guard.height,
  );
}

ProjectBuildingShadowPreset _shadowPresetFor(
  _ShadowMode mode,
  _GuardCase guard,
) {
  final tuning = _effectiveTuningFor(mode, guard);
  return ProjectBuildingShadowPreset(
    id: mode.id,
    name: mode.label,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(
      attachYRatio: tuning.attachYRatio,
      frontWidthRatio: tuning.frontWidthRatio,
      rearWidthRatio: tuning.rearWidthRatio,
      depthRatio: tuning.depthRatio,
      skewXRatio: tuning.skewXRatio,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: tuning.opacity,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _shadowConfigFor(_ShadowMode mode) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: mode.id,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

_EffectiveTuning _effectiveTuningFor(_ShadowMode mode, _GuardCase guard) {
  if (!mode.isAdaptive) {
    return _EffectiveTuning(
      attachYRatio: mode.attachYRatio,
      frontWidthRatio: mode.frontWidthRatio,
      rearWidthRatio: mode.rearWidthRatio,
      depthRatio: mode.depthRatio,
      skewXRatio: mode.skewXRatio,
      opacity: mode.opacity,
    );
  }

  final gates = _gatesFor(guard);
  return _EffectiveTuning(
    attachYRatio: _lerp(mode.attachYRatio, mode.targetAttachYRatio, gates.adaptiveT),
    frontWidthRatio: mode.frontWidthRatio,
    rearWidthRatio: _lerp(mode.rearWidthRatio, mode.targetRearWidthRatio, gates.adaptiveT),
    depthRatio: _lerp(mode.depthRatio, mode.targetDepthRatio, gates.adaptiveT),
    skewXRatio: mode.skewXRatio,
    opacity: _lerp(mode.opacity, mode.targetOpacity, gates.adaptiveT),
  );
}

_AdaptiveGates _gatesFor(_GuardCase guard) {
  final heightGate = _clamp01((guard.height - 80) / 32);
  final ratioGate = _clamp01((guard.height / guard.width - 1.25) / 0.50);
  return _AdaptiveGates(
    heightGate: heightGate,
    ratioGate: ratioGate,
    adaptiveT: heightGate * ratioGate,
  );
}

void _drawGuardObject(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  switch (guard.objectKind) {
    case _GuardObjectKind.wideHouse:
      _drawWideHouse(canvas, guard, columnLeft, rowTop);
    case _GuardObjectKind.mediumShop:
      _drawMediumShop(canvas, guard, columnLeft, rowTop);
    case _GuardObjectKind.tallShop:
      _drawTallShop(canvas, guard, columnLeft, rowTop);
    case _GuardObjectKind.thinPropLike:
      _drawThinPropLike(canvas, guard, columnLeft, rowTop);
  }
}

void _drawWideHouse(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + guard.left;
  final top = rowTop + guard.top;
  final width = guard.width;
  final height = guard.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_bodyColor);
  final roof = _fillPaint(_roofColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 20, width, height - 20), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 20, width, height - 20), outline);
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 8, top + 22)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 8, top + 22)
      ..close(),
    roof,
  );
  canvas.drawPath(
    ui.Path()
      ..moveTo(left - 8, top + 22)
      ..lineTo(left + width / 2, top)
      ..lineTo(left + width + 8, top + 22)
      ..close(),
    outline,
  );
  _drawDoor(canvas, left + width / 2 - 8, top + height - 28, 16, 28);
  _drawWindow(canvas, left + 10, top + 40, 14, 14);
  _drawWindow(canvas, left + 30, top + 40, 14, 14);
  _drawWindow(canvas, left + width - 44, top + 40, 14, 14);
  _drawWindow(canvas, left + width - 24, top + 40, 14, 14);
}

void _drawMediumShop(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + guard.left;
  final top = rowTop + guard.top;
  final width = guard.width;
  final height = guard.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_bodyColor);
  final roof = _fillPaint(_roofColor);
  final sign = _fillPaint(_signColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 18, width, height - 18), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 20), roof);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 20), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 26, width - 20, 12), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 10, top + 26, width - 20, 12), outline);
  _drawDoor(canvas, left + width / 2 - 8, top + height - 30, 16, 30);
  _drawWindow(canvas, left + 14, top + 54, 14, 18);
  _drawWindow(canvas, left + width - 28, top + 54, 14, 18);
}

void _drawTallShop(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final left = columnLeft + guard.left;
  final top = rowTop + guard.top;
  final width = guard.width;
  final height = guard.height;
  final outline = _outlinePaint();
  final fill = _fillPaint(_bodyColor);
  final roof = _fillPaint(_roofColor);
  final sign = _fillPaint(_signColor);

  canvas.drawRect(ui.Rect.fromLTWH(left, top + 16, width, height - 16), fill);
  canvas.drawRect(ui.Rect.fromLTWH(left, top + 16, width, height - 16), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 18), roof);
  canvas.drawRect(ui.Rect.fromLTWH(left - 4, top, width + 8, 18), outline);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 22, width - 16, 12), sign);
  canvas.drawRect(ui.Rect.fromLTWH(left + 8, top + 22, width - 16, 12), outline);
  _drawDoor(canvas, left + width / 2 - 8, top + height - 32, 16, 32);
  _drawWindow(canvas, left + 12, top + 58, 14, 22);
  _drawWindow(canvas, left + width - 26, top + 58, 14, 22);
}

void _drawThinPropLike(
  ui.Canvas canvas,
  _GuardCase guard,
  double columnLeft,
  double rowTop,
) {
  final centerX = columnLeft + guard.left + guard.width / 2;
  final top = rowTop + guard.top;
  final bottom = top + guard.height;
  final outline = _outlinePaint();
  final metal = _fillPaint(_metalColor);
  final lamp = _fillPaint(_signColor);

  canvas.drawRect(ui.Rect.fromLTWH(centerX - 5, top + 26, 10, guard.height - 26), metal);
  canvas.drawRect(ui.Rect.fromLTWH(centerX - 5, top + 26, 10, guard.height - 26), outline);
  canvas.drawRect(ui.Rect.fromLTWH(centerX - 14, top + 10, 28, 18), lamp);
  canvas.drawRect(ui.Rect.fromLTWH(centerX - 14, top + 10, 28, 18), outline);
  canvas.drawLine(
    ui.Offset(centerX - 12, bottom),
    ui.Offset(centerX + 12, bottom),
    outline,
  );
}

void _drawDoor(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_doorColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

void _drawWindow(ui.Canvas canvas, double left, double top, double width, double height) {
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _fillPaint(_windowColor),
  );
  canvas.drawRect(
    ui.Rect.fromLTWH(left, top, width, height),
    _outlinePaint(),
  );
}

ui.Paint _fillPaint(ui.Color color) {
  return ui.Paint()
    ..color = color
    ..style = ui.PaintingStyle.fill;
}

ui.Paint _outlinePaint() {
  return ui.Paint()
    ..color = _outlineColor
    ..style = ui.PaintingStyle.stroke
    ..strokeWidth = 2
    ..isAntiAlias = false;
}

void _drawLabel(
  ui.Canvas canvas,
  String label, {
  required double columnLeft,
}) {
  final paint = ui.Paint()
    ..color = _labelColor
    ..strokeWidth = 3
    ..style = ui.PaintingStyle.stroke
    ..strokeCap = ui.StrokeCap.square;
  final x = columnLeft + 90;
  const top = 8.0;
  const bottom = 24.0;
  const width = 20.0;
  const middle = 16.0;
  final left = x;
  final right = x + width;
  switch (label) {
    case 'A':
      canvas.drawLine(ui.Offset(left, bottom), ui.Offset(x + width / 2, top), paint);
      canvas.drawLine(ui.Offset(x + width / 2, top), ui.Offset(right, bottom), paint);
      canvas.drawLine(ui.Offset(left + 4, middle), ui.Offset(right - 4, middle), paint);
    case 'B':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 3, top + 3), paint);
      canvas.drawLine(ui.Offset(right - 3, top + 3), ui.Offset(right - 3, middle - 2), paint);
      canvas.drawLine(ui.Offset(right - 3, middle - 2), ui.Offset(left, middle), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(right, middle + 3), paint);
      canvas.drawLine(ui.Offset(right, middle + 3), ui.Offset(right - 2, bottom - 2), paint);
      canvas.drawLine(ui.Offset(right - 2, bottom - 2), ui.Offset(left, bottom), paint);
    case 'C':
      canvas.drawLine(ui.Offset(right, top), ui.Offset(left + 3, top), paint);
      canvas.drawLine(ui.Offset(left + 3, top), ui.Offset(left, middle), paint);
      canvas.drawLine(ui.Offset(left, middle), ui.Offset(left + 3, bottom), paint);
      canvas.drawLine(ui.Offset(left + 3, bottom), ui.Offset(right, bottom), paint);
    case 'D':
      canvas.drawLine(ui.Offset(left, top), ui.Offset(left, bottom), paint);
      canvas.drawLine(ui.Offset(left, top), ui.Offset(right - 2, top + 4), paint);
      canvas.drawLine(ui.Offset(right - 2, top + 4), ui.Offset(right - 2, bottom - 4), paint);
      canvas.drawLine(ui.Offset(right - 2, bottom - 4), ui.Offset(left, bottom), paint);
  }
}

Future<Uint8List> _pngBytes(ui.Image image) async {
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  if (byteData == null) {
    throw StateError('Could not encode ShadowV2 adaptive depth width guard artifact as PNG');
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

Future<_Rgba> _objectPixel(
  ui.Image image, {
  required int columnLeft,
  required int rowTop,
  required _GuardCase guard,
}) {
  return _pixelAt(
    image,
    columnLeft + (guard.left + guard.width / 2).round(),
    rowTop + (guard.top + math.min(40, guard.height / 2)).round(),
  );
}

Future<_Rgba> _pixelAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) {
    throw StateError('Could not read raw pixels from artifact image');
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
    _colorByte(color.r),
    _colorByte(color.g),
    _colorByte(color.b),
    _colorByte(color.a),
  );
}

int _colorByte(double value) {
  return (value * 255.0).round().clamp(0, 255).toInt();
}

ProjectedBuildingShadowPoint _centroid(ProjectedBuildingShadowGeometry geometry) {
  var totalX = 0.0;
  var totalY = 0.0;
  for (final point in geometry.points) {
    totalX += point.x;
    totalY += point.y;
  }
  return ProjectedBuildingShadowPoint(
    x: totalX / geometry.points.length,
    y: totalY / geometry.points.length,
  );
}

ProjectedBuildingShadowPoint _visibleShadowPoint(ProjectedBuildingShadowGeometry geometry) {
  final rearCenterX = (geometry.points[2].x + geometry.points[3].x) / 2;
  final rearY = math.max(geometry.points[2].y, geometry.points[3].y);
  return ProjectedBuildingShadowPoint(
    x: rearCenterX,
    y: math.max(161, rearY.round() - 3).toDouble(),
  );
}

double _clamp01(double value) => value.clamp(0, 1).toDouble();

double _lerp(double start, double end, double t) => start + (end - start) * t;

void _expectGeometryClose(
  ProjectedBuildingShadowGeometry geometry,
  _ExpectedGeometry expected,
) {
  expect(geometry.points, hasLength(4));
  for (var pointIndex = 0; pointIndex < expected.points.length; pointIndex += 1) {
    _expectPointClose(
      geometry.points[pointIndex],
      x: expected.points[pointIndex].x,
      y: expected.points[pointIndex].y,
    );
  }
}

void _expectPointClose(
  ProjectedBuildingShadowPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.02));
  expect(point.y, closeTo(y, 0.02));
}

void _expectBoundsClose(
  ShadowRuntimeRenderInstruction instruction,
  _ExpectedGeometry expected,
) {
  expect(instruction.worldLeft, closeTo(expected.left, 0.02));
  expect(instruction.worldTop, closeTo(expected.top, 0.02));
  expect(instruction.width, closeTo(expected.width, 0.02));
  expect(instruction.height, closeTo(expected.height, 0.02));
}

void _expectGateClose(double actual, double expected) {
  expect(actual, closeTo(expected, 0.000001));
}

final class _ShadowMode {
  const _ShadowMode.fixed({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
  })  : isAdaptive = false,
        targetAttachYRatio = attachYRatio,
        targetRearWidthRatio = rearWidthRatio,
        targetDepthRatio = depthRatio,
        targetOpacity = opacity;

  const _ShadowMode.adaptive({
    required this.id,
    required this.label,
    required this.attachYRatio,
    required this.targetAttachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.targetRearWidthRatio,
    required this.depthRatio,
    required this.targetDepthRatio,
    required this.skewXRatio,
    required this.opacity,
    required this.targetOpacity,
  }) : isAdaptive = true;

  final String id;
  final String label;
  final bool isAdaptive;
  final double attachYRatio;
  final double targetAttachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double targetRearWidthRatio;
  final double depthRatio;
  final double targetDepthRatio;
  final double skewXRatio;
  final double opacity;
  final double targetOpacity;
}

final class _GuardCase {
  const _GuardCase({
    required this.id,
    required this.label,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
    required this.expectedHeightGate,
    required this.expectedRatioGate,
    required this.expectedAdaptiveT,
    required this.objectKind,
    required this.standardExpected,
    required this.adaptiveExpected,
  });

  final String id;
  final String label;
  final double left;
  final double top;
  final double width;
  final double height;
  final double expectedHeightGate;
  final double expectedRatioGate;
  final double expectedAdaptiveT;
  final _GuardObjectKind objectKind;
  final _ExpectedGeometry standardExpected;
  final _ExpectedGeometry adaptiveExpected;
}

enum _GuardObjectKind {
  wideHouse,
  mediumShop,
  tallShop,
  thinPropLike,
}

final class _EffectiveTuning {
  const _EffectiveTuning({
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
    required this.opacity,
  });

  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;
  final double opacity;
}

final class _AdaptiveGates {
  const _AdaptiveGates({
    required this.heightGate,
    required this.ratioGate,
    required this.adaptiveT,
  });

  final double heightGate;
  final double ratioGate;
  final double adaptiveT;
}

final class _ExpectedGeometry {
  const _ExpectedGeometry({
    required this.points,
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });

  final List<_ExpectedPoint> points;
  final double left;
  final double top;
  final double width;
  final double height;
}

final class _ExpectedPoint {
  const _ExpectedPoint({
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
    return other is _Rgba && r == other.r && g == other.g && b == other.b && a == other.a;
  }

  @override
  int get hashCode => Object.hash(r, g, b, a);

  @override
  String toString() => 'rgba($r, $g, $b, $a)';
}
```

Le rapport courant est le fichier rapport créé par ShadowV2-56.

Checklist finale :
- [x] Harness manuel créé sous packages/map_runtime/tool/shadow
- [x] PNG artifact créé
- [x] PNG dans reports/shadows/screenshots
- [x] Aucun fichier baseline créé
- [x] Aucun matchesGoldenFile
- [x] Aucun Selbrume modifié ou lu pour générer l’image
- [x] Aucun fichier de production modifié
- [x] Aucun test existant modifié
- [x] Image 800x928 ou taille documentée
- [x] Colonne A wide_house_6x5 présente
- [x] Colonne B medium_shop_5x6 présente
- [x] Colonne C tall_shop_4x7 présente
- [x] Colonne D thin_prop_like_2x6 présente
- [x] Ligne Standard shadow-only présente
- [x] Ligne Adaptive shadow-only présente
- [x] Ligne Standard shadow + object présente
- [x] Ligne Adaptive shadow + object présente
- [x] resolveProjectedBuildingShadowGeometry utilisé
- [x] createProjectedBuildingShadowRuntimeInstruction utilisé
- [x] ShadowRuntimeRenderer.renderCollectionPass utilisé
- [x] ProjectedShadowFootprintTuning explicite utilisé
- [x] Aucun ProjectedShadowFootprintTuning() default utilisé
- [x] wide_house Adaptive C+ == Standard vérifié
- [x] medium_shop Adaptive C+ == Standard vérifié
- [x] tall_shop Adaptive C+ == C+ vérifié
- [x] thin_prop_like canary documenté
- [x] heightGate vérifié
- [x] ratioGate vérifié
- [x] adaptiveT vérifié
- [x] Opacity vérifiée
- [x] colorHexRgb 606060 vérifié
- [x] Test targeted passé
- [x] Analyze ciblé OK
- [x] SHA-256 du PNG documenté
- [x] Evidence Pack complet
- [x] git status final conforme au scope ou changements utilisateur documentés
