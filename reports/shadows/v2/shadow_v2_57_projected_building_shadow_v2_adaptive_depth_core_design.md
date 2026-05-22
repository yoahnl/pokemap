# ShadowV2-57 — Projected Building Shadow V2 Adaptive Depth Core Design Gate

## 1. Résumé exécutif

ShadowV2-57 est un design gate pur. Aucun code, aucune image, aucun test, aucun JSON, aucune baseline et aucun fichier de production n'ont été modifiés.

Décision :

```text
Option recommandée : Option F — hybrid strategy + explicit building guard.

Adaptive C+ doit devenir une stratégie officielle candidate ShadowV2,
mais pas comme nouveau geometryMode.

Le bon axe conceptuel est :
- geometryMode reste footprint ;
- le preset porte une stratégie de footprint tuning explicite ;
- l'adaptive n'est autorisé que pour des buildings / gros volumes approuvés ;
- l'éditeur empêche les choix incohérents ;
- les diagnostics signalent les données incohérentes ;
- JSON/persistence reste hors implémentation au Lot 57.
```

Conclusion courte :

```text
Adaptive C+ mérite une représentation map_core, mais pas encore une activation runtime/editor.
Le prochain lot recommandé est ShadowV2-58 — Projected Building Shadow Adaptive Depth Core Model V0.
Ce Lot 58 doit rester un V0 pur modèle/value objects + tests map_core, sans resolver, sans JSON, sans runtime, sans editor, sans renderer/painter.
```

## 2. Objectif du lot

Objectif exact :

```text
Définir comment représenter proprement une stratégie Adaptive C+ dans le modèle ShadowV2,
sans implémenter encore,
en gardant un système explicite, borné, limité aux bâtiments / gros volumes validés,
compatible avec l'authoring editor futur et JSON/persistence futur,
sans application automatique aux props fins.
```

Réponses aux questions obligatoires :

```text
1. Adaptive C+ doit-il devenir une stratégie officielle ShadowV2 ?
   Oui, comme stratégie candidate officielle, non activée par défaut.

2. Si oui, doit-elle vivre dans map_core ?
   Oui, car c'est un contrat partagé et une dérivation géométrique pure.

3. Faut-il représenter ça comme un nouveau geometryMode ?
   Non. La géométrie reste un footprint polygon.

4. Faut-il représenter ça comme une stratégie de footprint tuning ?
   Oui. C'est le coeur du design recommandé.

5. Faut-il garder un preset fixe standard + un preset adaptive ?
   Oui. Fixed reste la base stable ; adaptive devient un preset explicite séparé.

6. Comment éviter l'application aux props fins / lampadaires / poteaux ?
   Par une combinaison : caster kind explicite dans la donnée, validation/diagnostics core, et garde-fou éditeur.

7. Le garde-fou doit-il être une catégorie d'élément, un opt-in du preset, un opt-in de l'instance, ou une combinaison ?
   Une combinaison : preset adaptive explicite + élément approuvé comme building/gros volume. L'instance peut plus tard désactiver ou spécialiser, mais ne doit pas être le premier guard.

8. Comment préparer JSON/persistence sans l'implémenter ?
   Concevoir des noms et formes JSON stables : footprintStrategy.type = fixed/adaptiveHeightDepth, gate explicite, base/target explicites, casterKind explicite.

9. Comment préserver les presets fixed existants ?
   Ne pas changer ProjectedShadowFootprintTuning(), ne pas changer geometryMode footprint, ne pas changer le resolver fixed, et traiter fixed comme le comportement par défaut.

10. Quel doit être exactement le Lot 58 ?
   ShadowV2-58 — Projected Building Shadow Adaptive Depth Core Model V0.
```

## 3. Rappel ShadowV2-53 à ShadowV2-56

ShadowV2-53 :

```text
depth = metrics.visualHeight * footprint.depthRatio
```

La profondeur absolue est donc déjà proportionnelle à `visualHeight`. Le problème visuel identifié n'est pas l'absence de proportion, mais le fait que `depthRatio` reste constant.

ShadowV2-54 :

```text
Standard V2 fixed
Fixed C
Fixed C+
Adaptive C
Adaptive C+
Reference-like
```

Résultat : Adaptive C+ devient le meilleur candidat visuel/stratégique, mais seulement comme hypothèse contrôlée.

ShadowV2-55 :

```text
Adaptive C+ est conceptuellement préféré,
mais un guard artifact wide / mid-height est requis avant tout modèle core.
```

ShadowV2-56 :

```text
wide_house_6x5      -> adaptiveT = 0 -> Standard
medium_shop_5x6     -> adaptiveT = 0 -> Standard
tall_shop_4x7       -> adaptiveT = 1 -> C+
thin_prop_like_2x6  -> adaptiveT = 0.5 -> canary de risque
```

Décision validée par Lot 56 :

```text
Adaptive C+ passe les guards bâtiments contrôlés.
Le canary thin_prop_like prouve qu'un guard de catégorie / authoring approval est obligatoire.
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Fichiers préexistants non liés au Lot 57 :

```text
Aucun.
```

Fichiers ShadowV2 précédents non suivis avant Lot 57 :

```text
Aucun.
```

Fichiers hors scope apparus au status final pendant l'exécution du Lot 57 :

```text
reports/gameplay/fg_000_bis_evidence_clarification.md
reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
```

Lecture :

```text
Ces deux fichiers ne faisaient pas partie du status initial capturé pour ShadowV2-57.
Ils ne sont pas créés, modifiés ou supprimés par ce lot ShadowV2-57.
Ils restent hors scope et n'ont pas été touchés.
```

Fichiers créés par ShadowV2-57 :

```text
reports/shadows/v2/shadow_v2_57_projected_building_shadow_v2_adaptive_depth_core_design.md
```

Fichiers modifiés par ShadowV2-57 :

```text
Aucun.
```

Fichiers supprimés par ShadowV2-57 :

```text
Aucun.
```

Problèmes introduits par ShadowV2-57 :

```text
Aucun identifié.
```

## 5. Lecture AGENTS.md et méthode suivie

Commandes :

```bash
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject-worktree/AGENTS.md
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Extraits AGENTS.md lus et appliqués :

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

Vérification skills locaux demandée par AGENTS :

```bash
if [ -f skills/README.md ]; then sed -n '1,220p' skills/README.md; else printf 'skills/README.md absent\n'; fi
```

Sortie :

```text
skills/README.md absent
```

Méthode réellement suivie :

```text
Pass 1 — Audit modèle actuel :
  AGENTS.md lu, status initial capturé, modèle Projected Building Shadow audité.

Pass 2 — Analyse stratégie Adaptive C+ :
  Lots 54/55/56 et harnesses Adaptive C+ audités en lecture seule.

Pass 3 — Design options :
  Options fixed-only, new geometryMode, footprint strategy, external resolver,
  editor-only policy et hybrid guard comparées.

Pass 4 — Evidence/report :
  Rapport unique créé, git diff/status final collectés.
```

Sub-agents :

```text
AGENTS.md actuel ne mentionne pas de sub-agents.
Le lot a donc utilisé les passes séparées équivalentes demandées.
```

## 6. Décision AGENTS / design gate

Le lot reste conforme à AGENTS.md :

```text
Changement strictement borné au rapport demandé.
Git utilisé uniquement en lecture.
Aucun package de production modifié.
Aucun test lancé, conformément au prompt design-only.
Aucun générateur lancé.
```

Le design gate est cohérent avec l'architecture :

```text
map_core doit porter les futurs contrats purs.
map_runtime ne doit pas cacher la stratégie adaptive.
map_editor doit guider l'authoring, mais ne doit pas être le seul endroit qui protège les données.
JSON/persistence doit venir après clarification du modèle.
```

## 7. Fichiers audités

Audit modèle Shadow actuel :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/shadow.dart
packages/map_core/lib/src/validation/validators.dart
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Audit Adaptive C+ :

```text
reports/shadows/v2/shadow_v2_54_projected_building_shadow_v2_adaptive_depth_candidate_matrix_artifact.md
reports/shadows/v2/shadow_v2_55_projected_building_shadow_v2_adaptive_depth_visual_review_selection_design.md
reports/shadows/v2/shadow_v2_56_projected_building_shadow_v2_adaptive_depth_width_guard_artifact.md
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart
```

Commandes d'audit principales :

```bash
rg -n "ProjectBuildingShadowPreset|ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|ProjectedShadowAppearance|ProjectElementProjectedBuildingShadowConfig|resolveProjectedBuildingShadowGeometry|footprint|geometryMode|depthRatio|attachYRatio|frontWidthRatio|rearWidthRatio|skewXRatio|opacity" packages/map_core/lib packages/map_core/test packages/map_runtime/test packages/map_editor/test
rg -n "Adaptive C\\+|heightGate|ratioGate|adaptiveT|wide_house_6x5|medium_shop_5x6|tall_shop_4x7|thin_prop_like|category guard|authoring approval|building-only|props fins|lampadaire|poteau|JSON|persistence|map_core|fixed|adaptive" reports/shadows/v2 packages/map_runtime/tool/shadow
rg -n "projectedBuildingShadow|shadowOverride|shadowCaster|casterKind|element kind|category|placed element|ProjectElementEntry|MapPlacedElement|shadow profile|shadow catalog" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_core/test
```

## 8. Audit modèle Shadow actuel

Structure actuelle de `ProjectBuildingShadowPreset` :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:294-354

Champs :
- id
- name
- direction
- shape
- appearance
- timeOfDayMode
- geometryMode
- footprint
- categoryId
- sortOrder
```

`ProjectedBuildingShadowGeometryMode` :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:16-19

Valeurs actuelles :
- directional
- footprint
```

`ProjectedShadowFootprintTuning` :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:180-254

Defaults actuels :
attachYRatio = 0.86
frontWidthRatio = 1.10
rearWidthRatio = 1.20
depthRatio = 0.28
skewXRatio = 0.10
```

Validation actuelle :

```text
attachYRatio doit être dans [0, 1].
frontWidthRatio doit être > 0 et <= 2.0.
rearWidthRatio doit être > 0 et <= 2.0.
depthRatio doit être > 0 et <= 1.0.
skewXRatio doit être entre -0.5 et 0.5.
```

Validation `geometryMode` :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:563-581

directional => footprint doit être null.
footprint => footprint est requis.
```

Rôle actuel du resolver :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:63-85

resolveProjectedBuildingShadowGeometry(...) :
- retourne null si config.enabled == false ;
- route selon preset.geometryMode ;
- directional utilise direction/shape/anchor/localOffset ;
- footprint utilise preset.footprint.
```

Formule footprint actuelle :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart:140-180

centerX = metrics.left + metrics.visualWidth * 0.5 + config.localOffset.x
frontY = metrics.top + metrics.visualHeight * footprint.attachYRatio + config.localOffset.y
frontWidth = metrics.visualWidth * footprint.frontWidthRatio
rearWidth = metrics.visualWidth * footprint.rearWidthRatio
depth = metrics.visualHeight * footprint.depthRatio
rearCenterX = centerX + metrics.visualWidth * footprint.skewXRatio
rearY = frontY + depth
```

Rôle actuel de `ProjectElementProjectedBuildingShadowConfig` :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:474-521

Champs :
- enabled
- presetId
- anchor
- localOffset
```

Il ne contient actuellement :

```text
ni casterKind ;
ni allowAdaptiveDepth ;
ni instance approval ;
ni stratégie adaptive ;
ni guard building-only.
```

Intégration actuelle dans `ProjectElementEntry` :

```text
packages/map_core/lib/src/models/project_manifest.dart:421-448

ProjectElementEntry porte :
- categoryId ;
- presetKind ;
- shadow ;
- projectedBuildingShadow.
```

Important :

```text
categoryId est une catégorie utilisateur existante, pas un type sémantique fiable.
presetKind existe, mais n'est pas un guard ShadowV2 building-only.
projectedBuildingShadow est aujourd'hui l'opt-in élémentaire le plus proche du bon emplacement.
```

Instance placée :

```text
packages/map_core/lib/src/models/map_data.dart:99-116

MapPlacedElement porte shadowOverride pour l'ancien système Static Shadow,
mais ne porte pas encore d'override Projected Building Shadow V2.
```

Modèle shadow V0 existant :

```text
packages/map_core/lib/src/models/shadow.dart:44-50

StaticShadowFamily contient :
- genericProjection
- compactProp
- tallProp
- building
- foliage
```

Lecture :

```text
StaticShadowFamily.building confirme qu'un vocabulaire building existe déjà,
mais il appartient au système static shadow V0.
Le design Adaptive C+ ne doit pas le réutiliser implicitement sans décision dédiée.
```

Codecs JSON existants :

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart:83-145

Le codec preset encode actuellement :
- id
- name
- direction
- shape
- appearance
- timeOfDayMode
- categoryId si présent
- sortOrder
```

Point critique :

```text
Le codec preset actuel n'encode pas geometryMode.
Le codec preset actuel n'encode pas footprint.
Le codec preset actuel n'encode aucune footprintStrategy.
Le decode reconstruit donc les presets selon le default constructor, soit geometryMode: directional.
```

Tests existants qui caractérisent le fixed footprint :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:207-270
  footprint V0 avec ProjectedShadowFootprintTuning().

packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:272-344
  footprint V1 avec calibration attachYRatio 0.82, frontWidthRatio 1.30,
  rearWidthRatio 1.42, depthRatio 0.26, skewXRatio 0.08.

packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart:43-102
  conversion footprint vers instruction runtime polygon.

packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart:54-126
  traversée runtime collection via géométrie map_core.

packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart:41-117
  preview editor footprint et footprint v1.
```

Points d'extension possibles sans casser l'existant :

```text
1. Ajouter des value objects purs pour stratégie de footprint.
2. Garder ProjectedShadowFootprintTuning() intact.
3. Garder geometryMode: footprint.
4. Introduire une stratégie fixed qui encapsule le tuning actuel.
5. Introduire une stratégie adaptiveHeightDepth sans l'activer dans le resolver au premier lot.
6. Ajouter plus tard un guard explicite dans ProjectElementProjectedBuildingShadowConfig.
```

## 9. Audit lots Adaptive C+

Lot 54 :

```text
Le harness shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart définit :
- Standard fixed ;
- Fixed C ;
- Fixed C+ ;
- Adaptive C ;
- Adaptive C+ ;
- Reference-like.
```

Preuve utile :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart:145-169

Adaptive C+ :
base depthRatio = 0.26
target depthRatio = 0.42
base attachYRatio = 0.82
target attachYRatio = 0.80
base rearWidthRatio = 1.42
target rearWidthRatio = 1.47
base opacity = 0.24
target opacity = 0.22
```

Lot 55 :

```text
Décision : Adaptive C+ est le meilleur candidat conceptuel,
mais il faut un guard artifact wide / mid-height avant modèle core.
```

Lot 56 :

```text
packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart:81-226

Guards :
- wide_house_6x5 : expectedAdaptiveT = 0
- medium_shop_5x6 : expectedAdaptiveT = 0
- tall_shop_4x7 : expectedAdaptiveT = 1
- thin_prop_like_2x6 : expectedAdaptiveT = 0.5
```

Formule locale au harness Lot 56 :

```text
heightGate = clamp((visualHeight - 80) / 32, 0, 1)
ratioGate = clamp((visualHeight / visualWidth - 1.25) / 0.50, 0, 1)
adaptiveT = heightGate * ratioGate
```

Ce que Lot 56 valide :

```text
wide_house_6x5 ne déclenche pas l'adaptive.
medium_shop_5x6 ne déclenche pas l'adaptive.
tall_shop_4x7 atteint C+.
Le pipeline resolver -> adapter -> renderer a été utilisé dans le harness.
```

Ce que Lot 56 ne valide pas :

```text
Il ne valide pas un modèle map_core.
Il ne valide pas JSON/persistence.
Il ne valide pas editor authoring.
Il ne valide pas runtime production.
Il ne prouve pas que les props fins sont supportés.
```

Pourquoi `thin_prop_like_2x6` impose un guard :

```text
thin_prop_like_2x6 a visualHeight = 96 et visualWidth = 32.
Le ratio height/width = 3.00 déclenche ratioGate = 1.
heightGate = 0.5, donc adaptiveT = 0.5.

La formule réagit donc partiellement à une silhouette haute et fine.
Ce n'est pas un bug mathématique : c'est le comportement attendu de la formule.
Mais c'est indésirable pour un prop fin si aucune donnée ne dit "ceci est un building/gros volume".
```

Pourquoi JSON/persistence est encore à différer :

```text
Le codec actuel ne persiste pas footprint.
La stratégie adaptive implique un union model et des defaults de compatibilité.
Le guard building-only doit être défini avant d'encoder des données durables.
```

## 10. Problème à résoudre

Le problème n'est pas de créer une nouvelle forme géométrique.

```text
La forme reste un quadrilatère footprint attaché.
Le renderer sait déjà dessiner un projectedPolygon.
Le runtime adapter sait déjà convertir une géométrie map_core en instruction runtime.
Le preview editor sait déjà afficher le footprint.
```

Le problème réel :

```text
Comment dériver un ProjectedShadowFootprintTuning effectif,
et éventuellement une opacity effective,
à partir de metrics.visualHeight / visualWidth,
sans appliquer cette dérivation à des silhouettes fines non-building.
```

Donc le design doit représenter :

```text
- une stratégie fixed ;
- une stratégie adaptiveHeightDepth ;
- des gates bornés ;
- une approbation building-only explicite ;
- un chemin JSON futur ;
- une compatibilité fixed totale.
```

## 11. Options de design étudiées

### Option A — Fixed only

Principe :

```text
Garder ProjectedShadowFootprintTuning fixe.
Pour les bâtiments hauts, l'auteur choisit un preset fixed C+.
```

Avantages :

```text
Très simple.
Aucune formule automatique.
Facile à persister.
Facile à comprendre.
Peu de risque sur props fins si l'auteur choisit correctement.
```

Inconvénients :

```text
Moins progressif.
Multiplie les presets.
Ne répond pas aussi bien à l'intuition hauteur/ratio.
Risque d'authoring manuel répétitif.
```

Verdict :

```text
Option de repli saine, mais pas la meilleure après les preuves Lot 54-56.
```

### Option B — Nouveau geometryMode adaptiveFootprint

Principe :

```text
Ajouter ProjectedBuildingShadowGeometryMode.adaptiveFootprint.
```

Avantages :

```text
Très visible.
Sépare fixed et adaptive dans un enum existant.
```

Inconvénients :

```text
Conceptuellement mauvais.
La géométrie reste footprint.
Ce qui change est le tuning effectif, pas le type géométrique.
Risque de multiplier geometryMode pour chaque stratégie de calibration.
```

Verdict :

```text
Rejeté.
geometryMode doit rester réservé à la forme géométrique, pas aux stratégies de tuning.
```

### Option C — Stratégie de tuning dans le preset

Principe :

```text
ProjectBuildingShadowPreset garde geometryMode: footprint.
Le preset reçoit une stratégie explicite :
- fixed ;
- adaptiveHeightDepth.
```

Avantages :

```text
Bonne séparation conceptuelle.
Fixed reste possible.
Adaptive devient explicite.
Prépare JSON/persistence.
Testable en pure Dart.
```

Inconvénients :

```text
Nouveau modèle.
Nouveau codec futur.
Nouveaux tests.
Ne suffit pas seul à protéger les props fins.
```

Verdict :

```text
Base du design recommandé, mais doit être combinée avec un guard building-only.
```

### Option D — Resolver externe / wrapper runtime-only

Principe :

```text
Ne pas changer ProjectBuildingShadowPreset.
Créer une opération externe qui dérive le tuning effectif depuis metrics.
```

Avantages :

```text
Moins de modèle immédiat.
Peut être testé comme pure operation.
```

Inconvénients :

```text
Logique cachée.
Moins authorable.
Moins persistable.
Moins lisible pour l'éditeur.
Risque que runtime/editor divergent.
```

Verdict :

```text
Rejeté comme stratégie principale.
Peut exister plus tard comme helper interne, mais pas comme représentation produit.
```

### Option E — Policy editor-only

Principe :

```text
L'éditeur choisit automatiquement Standard ou Fixed C+.
Le runtime/core ne connaît pas adaptive.
```

Avantages :

```text
Pas de magie runtime.
UX contrôlée.
Rollback facile.
```

Inconvénients :

```text
La règle ne vit pas dans la donnée.
Données importées ou modifiées hors éditeur non protégées.
Peut créer des overrides silencieux.
Ne prépare pas bien JSON/persistence.
```

Verdict :

```text
Rejeté comme solution unique.
L'éditeur doit aider, mais pas être le seul guard.
```

### Option F — Hybrid strategy + explicit building guard

Principe :

```text
Le preset porte une stratégie adaptive explicite.
L'élément ou sa config ShadowV2 indique explicitement un caster kind compatible building/gros volume.
L'éditeur empêche les choix incohérents.
Les diagnostics signalent les données incohérentes.
Le runtime ne devine pas.
```

Avantages :

```text
Répond au besoin visuel.
Protège contre thin_prop_like.
Reste explicite.
Prépare l'authoring.
Prépare JSON/persistence.
Évite l'application globale automatique.
```

Inconvénients :

```text
Plus de modèle.
Plus de tests.
Plusieurs lots nécessaires avant activation complète.
```

Verdict :

```text
Option recommandée.
```

## 12. Guard building-only étudié

### Guard A — Dans le preset

```text
preset intendedFor: building
```

Analyse :

```text
Utile comme metadata.
Insuffisant comme guard, car un preset peut toujours être appliqué à un prop fin.
```

### Guard B — Dans l'élément

```text
ProjectElementProjectedBuildingShadowConfig ou ProjectElementEntry déclare :
casterKind: building
ou allowAdaptiveDepth: true
```

Analyse :

```text
Bon emplacement principal.
L'approbation est liée à l'asset / élément réutilisable.
Cela protège toutes les instances normales du même asset.
```

Réserve :

```text
categoryId ne suffit pas, car c'est une catégorie utilisateur libre.
Il faut un champ sémantique dédié.
```

### Guard C — Dans l'instance placée

```text
MapPlacedElement ou override futur déclare allowAdaptiveDepth: true.
```

Analyse :

```text
Contrôle fin.
Trop lourd comme premier guard.
Peut devenir utile plus tard pour disable/override local.
```

### Guard D — Dans l'éditeur uniquement

```text
L'éditeur empêche de choisir adaptive sur un objet non-building.
```

Analyse :

```text
Indispensable pour l'UX.
Insuffisant pour la validité des données.
```

### Guard E — Combinaison recommandée

```text
Core porte un caster kind explicite.
Preset adaptive reste explicite.
Editor empêche les associations incohérentes.
Diagnostics signalent adaptive sans caster compatible.
Runtime ne fait pas de devinette.
```

Verdict :

```text
Oui, cette combinaison est la meilleure.
```

Guard conceptuel recommandé :

```text
ProjectElementProjectedBuildingShadowConfig.casterKind = building | largeVolume
```

ou, si le prochain lot préfère séparer approval et kind :

```text
ProjectElementProjectedBuildingShadowConfig.allowAdaptiveDepth = true
ProjectedBuildingShadowCasterKind = building | largeVolume
```

Recommandation de ce rapport :

```text
Privilégier ProjectedBuildingShadowCasterKind.
Un booléen allowAdaptiveDepth est trop opaque et dit moins bien pourquoi l'élément est autorisé.
```

## 13. JSON / persistence — implications

Décision Lot 57 :

```text
Ne pas implémenter JSON.
Mais ne pas choisir un design incompatible JSON.
```

Encodage conceptuel fixed futur :

```text
geometryMode: footprint
footprintStrategy:
  type: fixed
  tuning:
    attachYRatio: 0.82
    frontWidthRatio: 1.30
    rearWidthRatio: 1.42
    depthRatio: 0.26
    skewXRatio: 0.08
appearance:
  opacity: 0.24
  colorHexRgb: 606060
```

Encodage conceptuel adaptive futur :

```text
geometryMode: footprint
footprintStrategy:
  type: adaptiveHeightDepth
  base:
    attachYRatio: 0.82
    frontWidthRatio: 1.30
    rearWidthRatio: 1.42
    depthRatio: 0.26
    skewXRatio: 0.08
  target:
    attachYRatio: 0.80
    frontWidthRatio: 1.30
    rearWidthRatio: 1.47
    depthRatio: 0.42
    skewXRatio: 0.08
  gate:
    referenceHeight: 80
    targetHeight: 112
    referenceRatio: 1.25
    targetRatio: 1.75
  baseOpacity: 0.24
  targetOpacity: 0.22
appearance:
  colorHexRgb: 606060
```

Compatibilité anciens presets :

```text
Les presets directionnels existants doivent rester décodables.
Les presets fixed footprint doivent rester représentables sans stratégie adaptive.
Un futur codec doit éviter de casser les JSON existants.
```

Risque actuel :

```text
Le codec ProjectBuildingShadowPreset actuel n'encode pas geometryMode/footprint.
Un lot JSON futur doit donc traiter footprint fixed avant ou en même temps que adaptive.
```

Versionnement :

```text
Préférer une compatibilité additive par champ `footprintStrategy.type`.
Ne pas ajouter build_runner pour ce sujet.
Utiliser un codec manuel strict comme les codecs ShadowV2 existants.
```

Union / sealed-like manual model :

```text
Recommandé.
Le code actuel utilise des value objects manuels pour ShadowV2.
Un model manual union-like par `type` est plus cohérent qu'un generated union.
```

## 14. Nommage recommandé

Noms recommandés :

```text
ProjectedShadowFootprintTuningStrategy
ProjectedShadowFootprintFixedTuning
ProjectedShadowFootprintAdaptiveDepthTuning
ProjectedShadowAdaptiveDepthGate
ProjectedBuildingShadowCasterKind
```

Noms à éviter :

```text
V1
legacy V1
genericProjection
autoShadow
magicShadow
sunSimulation
dynamicSun
```

Noms JSON recommandés :

```text
footprintStrategy
type: fixed
type: adaptiveHeightDepth
base
target
gate
referenceHeight
targetHeight
referenceRatio
targetRatio
baseOpacity
targetOpacity
casterKind
```

Noms de tests futurs :

```text
projected_shadow_footprint_strategy_test.dart
projected_building_shadow_adaptive_depth_gate_test.dart
projected_building_shadow_caster_kind_test.dart
```

Nom de rapport Lot 58 recommandé :

```text
reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md
```

## 15. Compatibilité fixed existante

Garanties du design recommandé :

```text
ProjectedShadowFootprintTuning() reste utilisable.
Ses defaults ne changent pas.
ProjectedBuildingShadowGeometryMode.footprint reste le geometryMode.
La géométrie fixed ne change pas.
Les render instructions ne changent pas.
ShadowRuntimeRenderer ne change pas.
Les painters ne changent pas.
Les tests Lot 47 / 50 / 52 / 54 / 56 ne doivent pas être modifiés sans justification.
```

Règle de compatibilité conceptuelle :

```text
fixed footprint actuel == footprintStrategy fixed.
adaptiveHeightDepth est opt-in, jamais fallback silencieux.
```

Pourquoi ne pas modifier les defaults :

```text
Les defaults ProjectedShadowFootprintTuning() caractérisent le footprint historique.
La calibration officielle ShadowV2 standard est explicite dans les presets/tests.
Adaptive C+ est une nouvelle stratégie, pas une mutation de Standard.
```

## 16. Frontière props fins

Les lampadaires, poteaux, panneaux et props fins ne doivent pas recevoir Adaptive C+.

Constat Lot 56 :

```text
thin_prop_like_2x6 :
visualHeight = 96
visualWidth = 32
heightGate = 0.5
ratioGate = 1
adaptiveT = 0.5
```

Pourquoi ce n'est pas un bug de la formule :

```text
La formule mesure hauteur et ratio.
Un prop fin est haut et très vertical.
Mathématiquement, il ressemble à un candidat tall.
Artistiquement, il ne doit pas recevoir une ombre footprint de bâtiment.
```

Pourquoi il faut une catégorie/approval :

```text
La géométrie seule ne sait pas si une silhouette haute est un bâtiment ou un lampadaire.
Le modèle doit porter l'intention d'authoring.
```

Futur probable hors scope :

```text
Props fins : hors scope.
Futur probable : tallThinContact / propContact / asset-shadow authoré.
```

## 17. Option recommandée

Option recommandée : Option F — hybrid strategy + explicit building guard.

Décision :

```text
hybrid strategy + explicit building guard
```

Pourquoi :

```text
Adaptive C+ a assez de preuves visuelles pour mériter une représentation core.
Le guard width/mid-height est positif pour les bâtiments contrôlés.
thin_prop_like impose une protection sémantique.
Un nouveau geometryMode serait une mauvaise séparation conceptuelle.
Une policy editor-only serait insuffisante.
Un fixed-only serait plus simple mais moins adapté au besoin validé par les artifacts.
```

Design recommandé :

```text
modèle conceptuel :
  ProjectBuildingShadowPreset garde geometryMode: footprint.
  Une future footprintStrategy explicite décrit fixed ou adaptiveHeightDepth.

guard conceptuel :
  ProjectElementProjectedBuildingShadowConfig porte un ProjectedBuildingShadowCasterKind compatible.
  Adaptive est valide seulement si casterKind indique building/gros volume.

resolver conceptuel :
  Le resolver calcule un effective tuning uniquement après validation du guard.
  Fixed reste inchangé.

JSON conceptuel :
  footprintStrategy.type encode fixed/adaptiveHeightDepth.
  casterKind encode l'approbation building-only.
  JSON reste hors implémentation au Lot 57 et probablement hors Lot 58.

editor conceptuel :
  L'éditeur propose Adaptive C+ seulement pour les éléments approuvés building/gros volume.
  Il explique le guard, au lieu de l'inférer silencieusement.

diagnostics conceptuels :
  Signaler adaptiveHeightDepth sans casterKind compatible.
  Signaler usage sur prop fin ou catégorie non approuvée.
```

Pourquoi les autres options sont rejetées :

```text
fixed only :
  trop manuel, moins progressif, ne capture pas la stratégie Adaptive C+ validée.

new geometryMode :
  mélange forme géométrique et stratégie de tuning.

external resolver :
  cache la règle et prépare mal JSON/editor.

editor-only policy :
  ne protège pas les données importées ou modifiées hors éditeur.

JSON/persistence maintenant :
  prématuré tant que le modèle core V0 n'existe pas.
```

Lot 58 doit faire :

```text
Créer un V0 modèle pur map_core pour les value objects de stratégie Adaptive C+ :
- stratégie fixed ;
- stratégie adaptiveHeightDepth ;
- gate adaptive ;
- caster kind building-only.

Ajouter des tests de validation/equality/pure model.
Ne pas brancher le resolver.
Ne pas modifier JSON.
Ne pas modifier runtime/editor.
```

Lot 58 ne doit pas faire :

```text
Pas de renderer/painter.
Pas de runtime.
Pas d'editor.
Pas de JSON/persistence.
Pas de Selbrume.
Pas de screenshots/baselines.
Pas d'application aux props fins.
Pas de changement des defaults ProjectedShadowFootprintTuning().
```

## 18. Design conceptuel recommandé

Modèle conceptuel :

```text
ProjectedShadowFootprintTuningStrategy
  - fixed(ProjectedShadowFootprintTuning tuning)
  - adaptiveHeightDepth(
      ProjectedShadowFootprintTuning base,
      ProjectedShadowFootprintTuning target,
      ProjectedShadowAdaptiveDepthGate gate,
      double baseOpacity,
      double targetOpacity,
    )
```

Gate conceptuel :

```text
ProjectedShadowAdaptiveDepthGate(
  referenceHeight: 80,
  targetHeight: 112,
  referenceRatio: 1.25,
  targetRatio: 1.75,
)
```

Caster kind conceptuel :

```text
ProjectedBuildingShadowCasterKind.building
ProjectedBuildingShadowCasterKind.largeVolume
```

Formule conceptuelle future :

```text
heightGate = clamp((visualHeight - referenceHeight) / (targetHeight - referenceHeight), 0, 1)
ratioGate = clamp((visualHeight / visualWidth - referenceRatio) / (targetRatio - referenceRatio), 0, 1)
adaptiveT = heightGate * ratioGate

effectiveFootprint = lerp(base, target, adaptiveT)
effectiveOpacity = lerp(baseOpacity, targetOpacity, adaptiveT)
```

Invariant critique :

```text
adaptiveHeightDepth ne peut être résolu que pour un caster kind explicitement compatible.
```

Séparation recommandée :

```text
Lot 58 :
  value objects purs.

Lot 59 ou plus tard :
  integration dans ProjectBuildingShadowPreset.

Lot ultérieur :
  resolver effectif.

Lot ultérieur :
  JSON/persistence.

Lot ultérieur :
  editor authoring.
```

## 19. Plan précis du Lot 58

Nom recommandé :

```text
ShadowV2-58 — Projected Building Shadow Adaptive Depth Core Model V0
```

Objectif :

```text
Créer uniquement les value objects purs nécessaires à la stratégie Adaptive C+ dans map_core,
sans resolver,
sans JSON,
sans runtime,
sans editor,
sans renderer/painter,
sans Selbrume.
```

Fichiers à modifier :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Fichiers à créer :

```text
packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart
reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md
```

Types conceptuels à introduire :

```text
ProjectedShadowFootprintTuningStrategy
ProjectedShadowFootprintFixedTuning
ProjectedShadowFootprintAdaptiveDepthTuning
ProjectedShadowAdaptiveDepthGate
ProjectedBuildingShadowCasterKind
```

Tests à couvrir :

```text
fixed strategy conserve exactement le ProjectedShadowFootprintTuning.
adaptive strategy conserve base/target/gate/baseOpacity/targetOpacity.
gate refuse targetHeight <= referenceHeight.
gate refuse targetRatio <= referenceRatio.
opacity base/target doit rester entre 0 et 1.
value equality/hashCode incluent tous les champs.
ProjectedShadowFootprintTuning() defaults restent inchangés.
```

Commandes probables Lot 58 :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_strategy_test.dart
cd packages/map_core && dart analyze test/shadow_v2/projected_shadow_footprint_strategy_test.dart
git diff --check
git status --short --untracked-files=all
```

JSON au Lot 58 :

```text
Hors scope.
```

Resolver au Lot 58 :

```text
Hors scope.
```

Runtime/editor au Lot 58 :

```text
Hors scope.
```

Pourquoi V0 est acceptable :

```text
Le design est assez clair pour créer des value objects purs.
Il n'est pas encore assez mature pour brancher resolver, JSON, runtime ou editor dans le même lot.
```

## 20. Fichiers explicitement interdits au Lot 58

```text
packages/map_runtime/lib/**
packages/map_runtime/test/**
packages/map_editor/lib/**
packages/map_editor/test/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/**
project.json
```

Fichiers à ne probablement pas modifier au Lot 58 :

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_data.freezed.dart
packages/map_core/lib/src/models/map_data.g.dart
```

Interdictions conceptuelles Lot 58 :

```text
Ne pas changer geometryMode.
Ne pas brancher Adaptive C+ dans resolveProjectedBuildingShadowGeometry(...).
Ne pas persister footprintStrategy.
Ne pas créer de baseline.
Ne pas créer d'image.
Ne pas traiter props fins.
```

## 21. Risques / réserves

```text
Le design recommande un V0 modèle pur, donc il ne prouvera pas encore l'intégration complète.
La question exacte "casterKind sur ProjectElementProjectedBuildingShadowConfig ou sur ProjectElementEntry" devra être confirmée avant branchement JSON/editor.
L'opacity adaptive traverse une frontière entre footprint tuning et appearance ; elle doit être modélisée explicitement pour éviter une règle cachée.
Les codecs actuels n'encodent pas footprint ; le futur lot JSON devra traiter cette dette avec prudence.
Les props fins restent hors scope et ne doivent pas être "résolus" par Adaptive C+.
```

## 22. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Seul ce rapport Markdown est créé.
```

Le rapport évite-t-il de coder dans un design gate ?

```text
Oui. Aucun fichier Dart, test, JSON, screenshot ou baseline n'est créé.
```

Le rapport choisit-il une option unique ?

```text
Oui. Option F — hybrid strategy + explicit building guard.
```

Le rapport évite-t-il de créer un nouveau geometryMode injustifié ?

```text
Oui. Il rejette adaptiveFootprint comme geometryMode.
```

Le rapport protège-t-il vraiment les props fins ?

```text
Oui conceptuellement : adaptive nécessite caster kind compatible et validation/diagnostics/editor guard.
```

Le rapport garde-t-il JSON/persistence hors implémentation ?

```text
Oui. JSON est uniquement analysé conceptuellement.
```

Le rapport garantit-il la compatibilité fixed ?

```text
Oui. Defaults et resolver fixed restent inchangés dans la recommandation.
```

Le plan Lot 58 est-il assez petit ?

```text
Oui. Il limite Lot 58 aux value objects purs map_core et tests ciblés.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Il inclut status initial, lecture AGENTS, commandes d'audit, modèle actuel, lots Adaptive C+, option recommandée, plan Lot 58 et git final.
```

## 23. Regard critique sur le prompt

Le prompt est strict et utile :

```text
Il force à séparer design core, JSON, renderer, editor et Selbrume.
Il oblige à traiter le canary thin_prop_like comme risque produit, pas comme bug isolé.
Il évite un nouveau geometryMode prématuré.
```

Point de vigilance :

```text
Le prompt demande de préparer JSON/persistence sans implémenter.
Cette frontière est saine, mais le prochain lot doit rester discipliné :
un V0 modèle pur avant tout codec.
```

## 24. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
if [ -f skills/README.md ]; then sed -n '1,220p' skills/README.md; else printf 'skills/README.md absent\n'; fi
rg -n "ProjectBuildingShadowPreset|ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|ProjectedShadowAppearance|ProjectElementProjectedBuildingShadowConfig|resolveProjectedBuildingShadowGeometry|footprint|geometryMode|depthRatio|attachYRatio|frontWidthRatio|rearWidthRatio|skewXRatio|opacity" packages/map_core/lib packages/map_core/test packages/map_runtime/test packages/map_editor/test
rg -n "Adaptive C\\+|heightGate|ratioGate|adaptiveT|wide_house_6x5|medium_shop_5x6|tall_shop_4x7|thin_prop_like|category guard|authoring approval|building-only|props fins|lampadaire|poteau|JSON|persistence|map_core|fixed|adaptive" reports/shadows/v2 packages/map_runtime/tool/shadow
rg -n "projectedBuildingShadow|shadowOverride|shadowCaster|casterKind|element kind|category|placed element|ProjectElementEntry|MapPlacedElement|shadow profile|shadow catalog" packages/map_core/lib packages/map_editor/lib packages/map_runtime/lib packages/map_core/test
nl -ba packages/map_core/lib/src/models/projected_building_shadow.dart | sed -n '1,640p'
nl -ba packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart | sed -n '1,260p'
nl -ba packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart | sed -n '1,320p'
nl -ba packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart | sed -n '1,220p'
nl -ba packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart | sed -n '1,360p'
nl -ba packages/map_core/lib/src/models/project_manifest.dart | sed -n '400,470p'
nl -ba packages/map_core/lib/src/models/map_data.dart | sed -n '1,140p'
nl -ba packages/map_core/lib/src/models/shadow.dart | sed -n '1,360p'
nl -ba packages/map_core/lib/src/validation/validators.dart | sed -n '490,570p'
nl -ba packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart | sed -n '200,430p'
nl -ba packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart | sed -n '1,320p'
nl -ba packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart | sed -n '1,260p'
nl -ba packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart | sed -n '1,300p'
nl -ba packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart | sed -n '1,320p'
nl -ba packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_candidate_matrix_artifact_test.dart | sed -n '1,360p'
nl -ba packages/map_runtime/tool/shadow/shadow_v2_adaptive_depth_width_guard_artifact_test.dart | sed -n '1,420p'
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests :

```text
Aucun test lancé.
Lot 57 est design-only et le prompt demande explicitement de ne pas lancer les tests.
```

## 25. git diff --stat

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
Le rapport Lot 57 est non suivi tant que l'utilisateur ne l'ajoute pas.
```

## 26. git diff --name-status

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

## 27. git diff --check

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

## 28. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
?? reports/gameplay/fg_000_bis_evidence_clarification.md
?? reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md
?? reports/shadows/v2/shadow_v2_57_projected_building_shadow_v2_adaptive_depth_core_design.md
```

Inventaire final :

```text
Fichiers créés par Lot 57 :
- reports/shadows/v2/shadow_v2_57_projected_building_shadow_v2_adaptive_depth_core_design.md

Fichiers préexistants hors Lot 57 :
- Aucun dans le status initial.

Fichiers hors scope présents au status final, non créés par Lot 57 :
- reports/gameplay/fg_000_bis_evidence_clarification.md
- reports/gameplay/fg_000_fangame_mechanics_readiness_audit.md

Fichiers modifiés par Lot 57 :
- Aucun.

Fichiers supprimés par Lot 57 :
- Aucun.

Fichiers generated créés/modifiés par Lot 57 :
- Aucun.

Screenshots créés par Lot 57 :
- Aucun.

Baselines créées par Lot 57 :
- Aucune.

Fichiers de production modifiés :
- Aucun.
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
- [x] AGENTS.md lu
- [x] Modèle Shadow actuel audité
- [x] Lots Adaptive C+ audités
- [x] Options de design comparées
- [x] geometryMode vs footprint strategy tranché
- [x] building-only guard tranché conceptuellement
- [x] JSON/persistence traité conceptuellement
- [x] Props fins / lampadaires exclus
- [x] Compatibilité fixed garantie
- [x] Option recommandée unique
- [x] Plan ShadowV2-58 précis
- [x] Fichiers interdits au Lot 58 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers utilisateur documentés
