# ShadowV2-61 — Projected Building Shadow Adaptive Depth Preset Integration Design Gate

## 1. Résumé exécutif

Option recommandée : phased integration.

Décision :
- `ProjectBuildingShadowPreset` doit porter plus tard un champ optionnel `footprintStrategy`.
- `geometryMode` reste `footprint`; aucun nouveau `geometryMode` adaptive ne doit être créé.
- Le champ existant `footprint` ne doit pas être supprimé au prochain lot : il reste la source de vérité fixed legacy en V0.
- `footprintStrategy` devient la source de vérité pour les presets adaptive.
- `appearance.colorHexRgb` reste commun à fixed et adaptive.
- `appearance.opacity` reste l'opacité fixed/fallback pour le fixed legacy; l'adaptive utilise `baseOpacity` / `targetOpacity` dans `ProjectedShadowFootprintAdaptiveDepthTuning`.
- JSON/persistence, resolver géométrique, runtime, editor, diagnostics, screenshots, baselines et Selbrume restent hors scope.

Le Lot 62 recommandé est :

```text
ShadowV2-62 — Projected Building Shadow Adaptive Depth Preset Model V0
```

Il doit ajouter seulement `footprintStrategy` optionnel au modèle `ProjectBuildingShadowPreset`, avec tests de validation/equality/hashCode, sans brancher JSON ni resolver.

## 2. Objectif du lot

Objectif exact exécuté : définir comment intégrer proprement `ProjectedShadowFootprintTuningStrategy` dans `ProjectBuildingShadowPreset`, sans implémenter encore.

Ce lot est design-only. Aucune image, baseline, fixture, migration, test, opération, renderer, painter, runtime, editor, JSON/persistence ou modification `map_core` n'a été créé ou modifié.

## 3. Rappel ShadowV2-58 à ShadowV2-60

ShadowV2-58 a introduit les value objects purs :

```text
ProjectedShadowFootprintTuningStrategy
ProjectedShadowFootprintFixedTuning
ProjectedShadowFootprintAdaptiveDepthTuning
ProjectedShadowAdaptiveDepthGate
ProjectedBuildingShadowCasterKind
```

ShadowV2-59 a décidé une opération pure séparée du resolver géométrique :

```text
resolveProjectedShadowFootprintEffectiveTuning(...)
```

ShadowV2-60 a créé cette opération pure avec un résultat `resolved/blocked` :

```text
Fixed -> tuning + fixedOpacity + adaptiveT = 0
Adaptive sans casterKind -> blocked(adaptiveDepthRequiresCasterKind)
Adaptive building / largeVolume -> tuning interpolé + opacity interpolée
wide_house_6x5 -> adaptiveT = 0
medium_shop_5x6 -> adaptiveT = 0
tall_shop_4x7 -> adaptiveT = 1
thin_prop_like_2x6 -> adaptiveT = 0.5 canary
```

Le resolver géométrique, `ProjectBuildingShadowPreset`, JSON/persistence, runtime et editor n'ont pas été branchés par le Lot 60.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
?? packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
?? reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
?? reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
```

Fichiers préexistants non liés au Lot 61 :

```text
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
```

Ces fichiers étaient déjà non suivis avant le Lot 61 et n'ont pas été modifiés par ce lot.

## 5. Lecture AGENTS.md et méthode suivie

Commandes :

```bash
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
```

Sortie `find` :

```text
../pokemonProject-worktree/AGENTS.md
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Points appliqués depuis `AGENTS.md` :
- monorepo Dart/Flutter sans orchestrateur;
- `map_core` est pur Dart;
- préserver les boundaries;
- Git write interdit;
- rapports sous `reports/` seulement quand demandé;
- inventaire complet des fichiers créés/modifiés/supprimés;
- sorties finales Git obligatoires;
- `skills/README.md` seulement si présent.

La commande `test -f skills/README.md && sed -n '1,220p' skills/README.md || true` n'a produit aucune sortie, donc aucun README local de skills n'a été appliqué. Les skills disponibles dans l'environnement utilisés pour la méthode ont été :

```text
superpowers:using-superpowers
karpathy-guidelines
superpowers:verification-before-completion
```

Méthode réellement suivie :

```text
Pass 1 — Audit modèle preset actuel
Pass 2 — Audit stratégie/effective tuning
Pass 3 — Design options
Pass 4 — Evidence/report
```

Il n'y a pas eu de sub-agent technique séparé dans cette session; les passes équivalentes ont été réalisées directement.

## 6. Fichiers créés / modifiés / supprimés

Créé par ShadowV2-61 :

```text
reports/shadows/v2/shadow_v2_61_projected_building_shadow_adaptive_depth_preset_integration_design.md
```

Modifié par ShadowV2-61 :

```text
Aucun
```

Supprimé par ShadowV2-61 :

```text
Aucun
```

Fichiers hors scope déjà présents :

```text
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
```

Problèmes introduits par ShadowV2-61 :

```text
Aucun identifié
```

## 7. Audit ProjectBuildingShadowPreset actuel

Commande :

```bash
rg -n "class ProjectBuildingShadowPreset|ProjectBuildingShadowPreset|ProjectedBuildingShadowGeometryMode|geometryMode|footprint|ProjectedShadowFootprintTuning|ProjectedShadowFootprintTuningStrategy|ProjectedShadowFootprintFixedTuning|ProjectedShadowFootprintAdaptiveDepthTuning|appearance|timeOfDayMode|categoryId|sortOrder|operator ==|hashCode" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
```

Preuves directes :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:16 enum ProjectedBuildingShadowGeometryMode { directional, footprint }
packages/map_core/lib/src/models/projected_building_shadow.dart:21 enum ProjectedBuildingShadowCasterKind { building, largeVolume }
packages/map_core/lib/src/models/projected_building_shadow.dart:185 final class ProjectedShadowFootprintTuning
packages/map_core/lib/src/models/projected_building_shadow.dart:455 final class ProjectBuildingShadowPreset
packages/map_core/lib/src/models/projected_building_shadow.dart:512 final ProjectedBuildingShadowGeometryMode geometryMode
packages/map_core/lib/src/models/projected_building_shadow.dart:513 final ProjectedShadowFootprintTuning? footprint
packages/map_core/lib/src/models/projected_building_shadow.dart:724 _validateProjectedBuildingShadowGeometryMode(...)
```

Forme actuelle de `ProjectBuildingShadowPreset` :

```text
id
name
direction
shape
appearance
timeOfDayMode
geometryMode
footprint
categoryId
sortOrder
```

Validation actuelle :

```text
geometryMode.directional => footprint doit être null
geometryMode.footprint => footprint est requis
```

Equality/hashCode actuels :

```text
id
name
direction
shape
appearance
timeOfDayMode
geometryMode
footprint
categoryId
sortOrder
```

Tests actuels dépendants de `footprint` :

```text
projected_building_shadow_footprint_tuning_test.dart:
- defaults to directional geometry mode
- accepts directional without footprint
- rejects directional with footprint
- accepts footprint with footprint tuning
- rejects footprint without footprint tuning
- equality and hashCode include geometryMode and footprint

projected_building_shadow_geometry_test.dart:
- construit des presets footprint avec ProjectedShadowFootprintTuning(...)
- vérifie la géométrie footprint fixe
- vérifie que opacity/colorHexRgb de ProjectedShadowAppearance sont propagés
```

Ce qui casserait si `footprint` était supprimé brutalement :
- les constructeurs actuels de presets footprint;
- les tests de validation `geometryMode/footprint`;
- les tests de géométrie fixed footprint;
- les codecs et tests JSON actuels qui round-trip des presets sans stratégie;
- les fixtures artistiques et rapports précédents qui parlent de `footprint` fixe;
- la compatibilité mentale du modèle actuel.

## 8. Audit opération effective Lot 60

Commande :

```bash
rg -n "resolveProjectedShadowFootprintEffectiveTuning|ProjectedShadowFootprintEffectiveTuningResult|ProjectedShadowEffectiveFootprintTuning|ProjectedShadowFootprintEffectiveTuningResolved|ProjectedShadowFootprintEffectiveTuningBlocked|fixedOpacity|adaptiveT|strategyKind|ProjectedBuildingShadowCasterKind|ProjectedShadowFootprintTuningStrategy" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
```

Preuves directes :

```text
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:15 ProjectedShadowEffectiveFootprintTuning
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:68 ProjectedShadowFootprintEffectiveTuningResult
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:72 ProjectedShadowFootprintEffectiveTuningResolved
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:90 ProjectedShadowFootprintEffectiveTuningBlocked
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:108 resolveProjectedShadowFootprintEffectiveTuning
```

Inputs actuels de l'opération :

```text
strategy: ProjectedShadowFootprintTuningStrategy
metrics: StaticShadowVisualMetrics
fixedOpacity: double
casterKind: ProjectedBuildingShadowCasterKind?
```

Output actuel :

```text
ProjectedShadowFootprintEffectiveTuningResult
  - ProjectedShadowFootprintEffectiveTuningResolved(value)
  - ProjectedShadowFootprintEffectiveTuningBlocked(reason)
```

Rôle de `fixedOpacity` :
- appliqué seulement à `ProjectedShadowFootprintFixedTuning`;
- validé dans `[0, 1]`;
- ignoré pour l'adaptive, qui utilise `baseOpacity/targetOpacity`.

Rôle de `casterKind` :
- ignoré pour fixed;
- obligatoire pour adaptive;
- compatible actuellement avec `building` et `largeVolume`;
- `null` bloque l'adaptive avec `adaptiveDepthRequiresCasterKind`.

Ce qu'un futur preset devra fournir :
- soit un `ProjectedShadowFootprintFixedTuning` dérivé du `footprint` legacy;
- soit un `ProjectedShadowFootprintAdaptiveDepthTuning`;
- une opacité fixed via `appearance.opacity`;
- une couleur commune via `appearance.colorHexRgb`;
- un `casterKind` fourni ailleurs, pas par le preset seul.

## 9. Audit JSON/persistence actuel

Commande :

```bash
rg -n "ProjectBuildingShadowPreset JSON|encodeProjectBuildingShadowPreset|decodeProjectBuildingShadowPreset|geometryMode|footprint|appearance|opacity|colorHexRgb|categoryId|sortOrder|projectedBuildingShadowCatalog|round-trips|unknown|omits|toJson|fromJson" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
```

Preuves directes :

```text
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart:63 encodeProjectBuildingShadowPreset(...)
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart:87 decodeProjectBuildingShadowPreset(...)
packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart:5 ProjectBuildingShadowPreset JSON codec
packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart:90 round-trips preset instances through canonical JSON
packages/map_core/test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart:5 ProjectBuildingShadowPresetCatalog JSON codec
```

Constat important : le codec actuel encode ces champs :

```text
id
name
direction
shape
appearance
timeOfDayMode
categoryId si non null
sortOrder
```

Le codec actuel ne persiste pas :

```text
geometryMode
footprint
footprintStrategy
adaptiveHeightDepth
casterKind
```

Conséquence : changer `ProjectBuildingShadowPreset` sans lot JSON dédié reste possible côté modèle, mais la persistance doit rester explicitement hors scope jusqu'à une étape séparée. Il ne faut pas mélanger le premier champ modèle `footprintStrategy` avec une migration JSON dans le même lot.

Ordre recommandé :

```text
1. Preset model integration V0.
2. JSON/persistence design gate.
3. JSON/persistence implementation.
4. Resolver/preset connection.
5. Guard/config/editor/runtime étapes séparées.
```

## 10. Audit diagnostics / manifest / config

Commande :

```bash
rg -n "ProjectElementEntry|ProjectElementProjectedBuildingShadowConfig|projectedBuildingShadow|ProjectBuildingShadowPresetCatalog|projectedBuildingShadowCatalog|diagnoseProjectedBuildingShadows|missing preset|unused preset|V1|V2|categoryId|presetKind|casterKind|building|largeVolume" packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
```

Preuves directes :

```text
packages/map_core/lib/src/models/project_manifest.dart:443 ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow
packages/map_core/lib/src/models/projected_building_shadow.dart:635 ProjectElementProjectedBuildingShadowConfig
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:20 missingPreset
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:22 unusedPreset
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:23 v1AndV2Coexistence
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:49 diagnoseProjectedBuildingShadows(...)
```

`ProjectElementProjectedBuildingShadowConfig` contient actuellement :

```text
enabled
presetId
anchor
localOffset
```

Il ne contient pas :

```text
casterKind
building
largeVolume
allowAdaptiveDepth
```

Diagnostics actuels :
- preset manquant;
- preset manquant sur config désactivée;
- preset inutilisé;
- coexistence Shadow V1 / V2;
- `followsSun` sans système time-of-day.

Impact futur d'un preset adaptive sans `casterKind` :
- le modèle preset seul ne protège pas les props fins;
- l'opération effective Lot 60 bloque déjà l'adaptive sans caster compatible;
- le champ guard doit être traité dans un lot séparé avant tout branchement resolver/runtime/editor.

`ProjectElementEntry.categoryId` n'est pas un guard sémantique suffisant : c'est un regroupement/catalogage existant, pas une approbation building/largeVolume explicite.

## 11. Problème à résoudre

Le modèle actuel a une source fixe :

```text
ProjectBuildingShadowPreset.geometryMode = footprint
ProjectBuildingShadowPreset.footprint = ProjectedShadowFootprintTuning
```

Le modèle cible doit pouvoir exprimer :

```text
ProjectBuildingShadowPreset.geometryMode = footprint
ProjectBuildingShadowPreset.footprintStrategy = fixed | adaptiveHeightDepth
```

Le risque principal est de créer deux sources de vérité incohérentes :

```text
footprint
footprintStrategy.fixed.tuning
footprintStrategy.adaptive.base
```

Le deuxième risque est de rendre un preset adaptive authorable sans guard building/largeVolume. Le Lot 60 permet de bloquer l'adaptive au calcul effectif, mais le modèle d'authoring doit quand même rester clair.

## 12. Options d’intégration preset

Option A — garder `footprint` tel quel, ne pas intégrer `footprintStrategy`.

Verdict : rejeté comme stratégie finale. C'est l'état transitoire actuel, mais il laisse l'adaptive déconnecté du preset et pousserait vers une logique externe cachée.

Option B — ajouter `footprintStrategy` en parallèle de `footprint`.

Verdict : acceptable seulement avec règles de phase strictes. Avantage : compat douce. Risque : deux sources de vérité si fixed impose à la fois `footprint` et `footprintStrategy.fixed`.

Option C — remplacer `footprint` par `footprintStrategy`.

Verdict : rejeté pour le prochain lot. Trop breaking pour les tests fixed, les call sites et les fixtures conceptuelles existantes.

Option D — stocker `footprintStrategy`, exposer `footprint` comme alias de compat.

Verdict : rejeté pour V0. Le getter `footprint` serait ambigu pour l'adaptive : base, target, effective ou null.

Option E — ajouter `adaptiveFootprintStrategy` sans toucher `footprint`.

Verdict : rejeté. Nom trop spécifique, deux chemins parallèles, moins général que `footprintStrategy`.

Option F — phased integration.

Verdict : recommandé.

Phases :

```text
Phase 1 :
  footprint reste le champ fixed legacy.
  footprintStrategy optionnel est ajouté.
  geometryMode footprint + footprintStrategy null => fixed depuis footprint.

Phase 2 :
  nouveaux presets adaptive utilisent footprintStrategy adaptiveHeightDepth.
  footprint legacy continue de marcher.

Phase 3 :
  JSON/persistence encode explicitement footprintStrategy.
  footprint legacy reste accepté en lecture / compat.

Phase 4 éventuelle :
  footprint cesse d'être source primaire, mais seulement après migration explicite.
```

## 13. Source de vérité fixed

Décision V0 : `footprint` reste source de vérité fixed pour compat immédiate.

Règle recommandée :

```text
geometryMode == footprint
footprintStrategy == null
footprint != null
=> stratégie dérivée plus tard : ProjectedShadowFootprintFixedTuning(tuning: footprint)
```

Pourquoi ne pas basculer immédiatement vers `footprintStrategy.fixed` :
- suppression ou déplacement de `footprint` casserait trop de tests;
- le JSON actuel ne connaît pas `footprintStrategy`;
- les presets fixed existants n'ont aucun besoin fonctionnel de migrer maintenant.

Pourquoi ne pas exiger `footprint` et `footprintStrategy.fixed` ensemble :
- double source de vérité;
- validation de synchronisation fragile;
- test churn sans gain produit immédiat.

Le modèle long terme peut devenir `footprintStrategy.fixed`, mais pas au Lot 62 V0.

## 14. Adaptive dans preset

Décision conceptuelle :

```text
geometryMode: footprint
footprintStrategy: ProjectedShadowFootprintAdaptiveDepthTuning(...)
footprint: null en V0 adaptive
```

Rôles :

```text
appearance.colorHexRgb:
  couleur commune fixed/adaptive.

appearance.opacity:
  fixedOpacity pour fixed legacy.
  pas la source de vérité adaptive.

ProjectedShadowFootprintAdaptiveDepthTuning.baseOpacity:
  opacité adaptive au point base.

ProjectedShadowFootprintAdaptiveDepthTuning.targetOpacity:
  opacité adaptive au point target.

footprint:
  source fixed legacy.
  pas source adaptive.

footprintStrategy:
  source adaptive.
```

Pourquoi `footprint` doit être `null` pour adaptive V0 :
- évite l'ambiguïté base vs effective;
- empêche de croire que `footprint` décrit la géométrie rendue;
- force le futur resolver à passer par la stratégie.

Réserve : le Lot 62 devra ajuster la validation `geometryMode.footprint` pour permettre `footprint == null` seulement lorsque `footprintStrategy` est adaptive.

## 15. Validation preset future

Règles recommandées pour Lot 62 :

```text
geometryMode.directional:
  footprint == null
  footprintStrategy == null

geometryMode.footprint fixed legacy:
  footprint != null
  footprintStrategy == null

geometryMode.footprint strategy fixed:
  à éviter en V0, ou autoriser seulement footprint == null si le lot choisit explicitement de tester cette voie.

geometryMode.footprint strategy adaptive:
  footprint == null
  footprintStrategy is ProjectedShadowFootprintAdaptiveDepthTuning
```

Règle V0 la plus sûre :

```text
Autoriser exactement deux états footprint :
1. legacy fixed : footprint présent, footprintStrategy null.
2. adaptive : footprint null, footprintStrategy adaptive.
```

Cela évite :
- `footprint` + `footprintStrategy.fixed` incohérents;
- `footprint` + `footprintStrategy.adaptive` ambigus;
- migration fixed massive au premier lot.

Equality/hashCode futurs :

```text
ProjectBuildingShadowPreset equality/hashCode doit inclure footprintStrategy.
```

## 16. Effective tuning connection future

Le branchement futur ne doit pas construire la géométrie directement depuis le preset. Il doit d'abord dériver/résoudre une stratégie effective.

Flux conceptuel futur :

```text
if preset.geometryMode == footprint:
  strategy = deriveStrategyFromPreset(preset)
  effectiveResult = resolveProjectedShadowFootprintEffectiveTuning(
    strategy: strategy,
    metrics: metrics,
    fixedOpacity: preset.appearance.opacity,
    casterKind: casterKind,
  )
```

Une opération pure séparée est recommandée plus tard :

```text
resolveProjectBuildingShadowPresetFootprintStrategy(...)
```

ou, si le lot de branchement veut directement produire le payload effectif :

```text
resolveProjectBuildingShadowPresetEffectiveFootprintTuning(...)
```

Le Lot 62 ne doit pas créer ces opérations. Il doit seulement rendre le modèle capable de porter la stratégie.

## 17. Guard building / largeVolume

Décision : l'intégration preset ne suffit pas à protéger les props fins.

Le guard building/largeVolume devra vivre dans une donnée d'élément/config/authoring explicite, puis être transmis à `resolveProjectedShadowFootprintEffectiveTuning(...)` comme `ProjectedBuildingShadowCasterKind?`.

Séquence recommandée :

```text
Lot 62 :
  intégrer le champ modèle footprintStrategy au preset.
  ne pas brancher resolver.
  ne pas rendre l'adaptive actif.

Lot ultérieur :
  décider/intégrer le guard casterKind sur ProjectElementProjectedBuildingShadowConfig ou modèle voisin.

Lot ultérieur :
  brancher preset + guard vers effective tuning.
```

Pourquoi le guard ne doit pas passer avant le preset model :
- le preset peut porter l'intention adaptive sans être résolu;
- l'opération Lot 60 bloque déjà sans caster compatible;
- le Lot 62 reste plus petit si le guard est séparé.

Pourquoi le guard reste obligatoire avant runtime/editor :
- `thin_prop_like_2x6` déclenche `adaptiveT = 0.5`;
- ce n'est pas un bug de calcul;
- cela prouve que les props fins, lampadaires, poteaux et panneaux ne doivent pas recevoir Adaptive C+ automatiquement.

## 18. JSON / persistence order

Décision : Preset model integration d'abord, JSON ensuite.

Option retenue :

```text
A. Preset model integration d'abord, JSON ensuite.
```

Pourquoi :
- les invariants modèle doivent être testés avant de figer une forme JSON;
- le codec actuel ne persiste pas `geometryMode`/`footprint`, donc l'ajout JSON demande une réflexion de compat à part entière;
- mélanger modèle + JSON augmenterait fortement le risque de casser les round-trips existants;
- aucun generated/build_runner ne doit être déclenché pour ce shadow lot.

Lot 62 ne doit donc pas modifier :

```text
project_building_shadow_preset_json_codec.dart
project_building_shadow_preset_catalog_json_codec.dart
projected_shadow_value_object_json_codecs.dart
ProjectElementEntry JSON
ProjectManifest JSON
generated files
```

## 19. Nommage recommandé

Noms recommandés :

```text
footprintStrategy
ProjectedShadowFootprintTuningStrategy
ProjectedShadowFootprintFixedTuning
ProjectedShadowFootprintAdaptiveDepthTuning
ProjectedShadowAdaptiveDepthGate
ProjectedBuildingShadowCasterKind
```

Tests futurs :

```text
packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_adaptive_depth_integration_test.dart
```

Rapport Lot 62 :

```text
reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
```

Noms à éviter :

```text
adaptiveFootprint geometryMode
autoShadow
genericProjection
dynamicSun
sunShadow
legacyV1
footprintV1
magic
```

## 20. Option recommandée

Option recommandée : phased integration.

Décision :

```text
phased integration
```

Design recommandé :

```text
source de vérité fixed:
  footprint reste source de vérité fixed legacy en V0.

source de vérité adaptive:
  footprintStrategy adaptiveHeightDepth.

rôle de footprint:
  fixed legacy uniquement.
  null pour adaptive V0.

rôle de footprintStrategy:
  optionnel.
  null pour fixed legacy.
  adaptiveHeightDepth pour adaptive.

rôle de appearance.opacity:
  fixedOpacity pour fixed legacy.
  non-source adaptive.

rôle de appearance.colorHexRgb:
  couleur commune fixed/adaptive.

validation directional:
  footprint null.
  footprintStrategy null.

validation footprint fixed:
  footprint requis si footprintStrategy null.

validation footprint adaptive:
  footprint null.
  footprintStrategy adaptiveHeightDepth requis.

guard building-only:
  traité séparément, obligatoire avant branchement resolver/runtime/editor.

JSON/persistence:
  hors scope Lot 62, design/codecs séparés ensuite.
```

Pourquoi :
- compatibilité fixed maximale;
- pas de suppression prématurée du champ `footprint`;
- pas de nouveau `geometryMode`;
- source adaptive explicite;
- pas de fallback silencieux pour les props fins;
- surface du Lot 62 assez petite.

Pourquoi les autres options sont rejetées :
- fixed only : garde l'adaptive externe et caché;
- ajout parallèle non phasé : double source de vérité;
- remplacement immédiat : breaking change trop fort;
- alias getter : ambigu pour adaptive;
- `adaptiveFootprintStrategy` : chemin parallèle trop spécifique.

## 21. Design conceptuel recommandé

Forme conceptuelle du preset fixed legacy :

```text
ProjectBuildingShadowPreset(
  geometryMode: footprint,
  footprint: ProjectedShadowFootprintTuning(...),
  footprintStrategy: null,
  appearance: ProjectedShadowAppearance(opacity: fixedOpacity, colorHexRgb: ...)
)
```

Forme conceptuelle du preset adaptive :

```text
ProjectBuildingShadowPreset(
  geometryMode: footprint,
  footprint: null,
  footprintStrategy: ProjectedShadowFootprintAdaptiveDepthTuning(
    base: ...,
    target: ...,
    gate: ...,
    baseOpacity: ...,
    targetOpacity: ...,
  ),
  appearance: ProjectedShadowAppearance(colorHexRgb: ...)
)
```

Point à clarifier au Lot 62 : `ProjectedShadowAppearance` exige aujourd'hui une `opacity` valide. Même si l'adaptive ne l'utilise pas comme source effective, le champ existe. Recommandation V0 : conserver une opacité valide dans `appearance` comme fallback/compat, mais documenter que pour adaptive elle n'est pas la source effective.

Invariant clef :

```text
footprintStrategy adaptiveHeightDepth ne doit jamais être interprété sans casterKind compatible.
```

## 22. Plan précis du Lot 62

Nom :

```text
ShadowV2-62 — Projected Building Shadow Adaptive Depth Preset Model V0
```

Objectif :

```text
Ajouter footprintStrategy optionnel à ProjectBuildingShadowPreset,
avec compat fixed legacy,
sans JSON,
sans resolver,
sans runtime/editor,
sans screenshot/baseline.
```

Modifier uniquement :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Créer uniquement :

```text
packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
```

Tests attendus :

```text
ProjectBuildingShadowPreset legacy footprint fixed keeps footprint as source of truth
ProjectBuildingShadowPreset directional rejects footprintStrategy
ProjectBuildingShadowPreset footprint rejects missing footprint and missing footprintStrategy
ProjectBuildingShadowPreset adaptive footprintStrategy accepts null footprint
ProjectBuildingShadowPreset adaptive footprintStrategy rejects non-null footprint
ProjectBuildingShadowPreset equality includes footprintStrategy
ProjectBuildingShadowPreset hashCode includes footprintStrategy
Existing projected_building_shadow_footprint_tuning_test remains green
Existing projected_building_shadow_geometry_test remains green
```

Commandes recommandées Lot 62 :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
```

Lot 62 ne doit pas faire :
- ne pas modifier `resolveProjectedBuildingShadowGeometry(...)`;
- ne pas modifier `resolveProjectedShadowFootprintEffectiveTuning(...)`;
- ne pas modifier JSON/codecs;
- ne pas modifier generated;
- ne pas modifier runtime/editor;
- ne pas modifier diagnostics;
- ne pas créer screenshot/baseline;
- ne pas toucher Selbrume.

## 23. Fichiers explicitement interdits au Lot 62

```text
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/project_manifest.freezed.dart
packages/map_core/lib/src/models/project_manifest.g.dart
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_data.freezed.dart
packages/map_core/lib/src/models/map_data.g.dart
packages/map_runtime/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
/Users/karim/Desktop/selbrume/**
project.json
```

## 24. Risques / réserves

Risques :
- `appearance.opacity` reste obligatoire même si l'adaptive utilise `baseOpacity/targetOpacity`; cela doit être documenté clairement au Lot 62.
- `footprintStrategy.fixed` est utile à long terme, mais l'autoriser dès V0 peut réintroduire une double source de vérité si `footprint` reste présent.
- Le guard building/largeVolume n'est pas résolu par le preset; il doit arriver avant tout branchement resolver/runtime/editor.
- Le codec JSON actuel ne persiste pas `geometryMode`/`footprint`; le prochain lot modèle ne doit pas promettre une persistence qui n'existe pas.

Réserves :
- Le design recommandé assume que `footprintStrategy` peut être ajouté optionnellement sans toucher au barrel public; si le style du repo exige une autre exposition, le Lot 62 devra le documenter avant de modifier.
- Les props fins, lampadaires, poteaux et panneaux restent hors scope.

## 25. Auto-critique

Le lot est-il bien design-only ?

```text
Oui. Un seul rapport Markdown est créé.
```

Le rapport évite-t-il de coder dans un design gate ?

```text
Oui. Aucune modification Dart, aucun test, aucun script.
```

Le rapport évite-t-il de supprimer `footprint` trop tôt ?

```text
Oui. `footprint` reste source de vérité fixed legacy au Lot 62.
```

Le rapport évite-t-il une double source de vérité dangereuse ?

```text
Oui. La règle V0 recommandée évite `footprint` + `footprintStrategy.fixed` simultanés et interdit `footprint` non null pour adaptive.
```

Le rapport garde-t-il JSON/persistence hors implémentation ?

```text
Oui. JSON est repoussé après le modèle V0.
```

Le rapport garde-t-il le resolver géométrique hors scope ?

```text
Oui. Le Lot 62 interdit explicitement le resolver géométrique.
```

Le rapport traite-t-il le guard building-only correctement ?

```text
Oui. Il dit que le preset ne suffit pas et qu'un guard element/config séparé est obligatoire avant branchement.
```

Le plan Lot 62 est-il assez petit ?

```text
Oui. Un fichier modèle, un test ciblé, un rapport.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Les commandes d'audit, sorties utiles, git diff/check/status et inventaire sont inclus.
```

## 26. Regard critique sur le prompt

Le prompt est utilement strict sur le design-only et évite de mélanger modèle, JSON et resolver. La seule tension relevée est que la section "modèle actuel à respecter" suggère que `geometryMode/footprint` sont persistés, alors que l'audit du codec actuel montre que `encodeProjectBuildingShadowPreset(...)` n'émet ni `geometryMode` ni `footprint`. Cela renforce la décision de séparer le Lot 62 modèle et un futur lot JSON.

Le prompt demande aussi de choisir entre guard-first et preset-model-first. La recommandation preset-model-first reste prudente uniquement parce que le resolver n'est pas branché : un preset adaptive peut exister comme donnée modèle sans devenir actif. Avant tout branchement effectif, le guard doit être introduit.

## 27. Commandes lancées

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
test -f skills/README.md && sed -n '1,220p' skills/README.md || true
rg -n "class ProjectBuildingShadowPreset|ProjectBuildingShadowPreset|ProjectedBuildingShadowGeometryMode|geometryMode|footprint|ProjectedShadowFootprintTuning|ProjectedShadowFootprintTuningStrategy|ProjectedShadowFootprintFixedTuning|ProjectedShadowFootprintAdaptiveDepthTuning|appearance|timeOfDayMode|categoryId|sortOrder|operator ==|hashCode" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
rg -n "resolveProjectedShadowFootprintEffectiveTuning|ProjectedShadowFootprintEffectiveTuningResult|ProjectedShadowEffectiveFootprintTuning|ProjectedShadowFootprintEffectiveTuningResolved|ProjectedShadowFootprintEffectiveTuningBlocked|fixedOpacity|adaptiveT|strategyKind|ProjectedBuildingShadowCasterKind|ProjectedShadowFootprintTuningStrategy" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
rg -n "ProjectBuildingShadowPreset JSON|encodeProjectBuildingShadowPreset|decodeProjectBuildingShadowPreset|geometryMode|footprint|appearance|opacity|colorHexRgb|categoryId|sortOrder|projectedBuildingShadowCatalog|round-trips|unknown|omits|toJson|fromJson" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
rg -n "ProjectElementEntry|ProjectElementProjectedBuildingShadowConfig|projectedBuildingShadow|ProjectBuildingShadowPresetCatalog|projectedBuildingShadowCatalog|diagnoseProjectedBuildingShadows|missing preset|unused preset|V1|V2|categoryId|presetKind|casterKind|building|largeVolume" packages/map_core/lib/src/models packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
sed -n '430,560p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '700,745p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '1,240p' packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
sed -n '1,220p' packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
sed -n '1,40p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '620,690p' packages/map_core/lib/src/models/projected_building_shadow.dart
sed -n '420,465p' packages/map_core/lib/src/models/project_manifest.dart
sed -n '140,190p' packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
wc -l reports/shadows/v2/shadow_v2_61_projected_building_shadow_adaptive_depth_preset_integration_design.md
```

Tests lancés :

```text
Aucun. Le prompt interdit les tests pour ce lot design-only.
```

Contrôle des formulations interdites :

```text
La commande rg dédiée n'a trouvé aucune occurrence.
```

Taille du rapport :

```text
1089 lignes
```

## 28. git diff --stat

```text
(aucune sortie)
```

## 29. git diff --name-status

```text
(aucune sortie)
```

## 30. git diff --check

```text
(aucune sortie)
```

## 31. git status final

```text
?? packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
?? packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
?? reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
?? reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
?? reports/shadows/v2/shadow_v2_61_projected_building_shadow_adaptive_depth_preset_integration_design.md
```

Conformité : le seul fichier ajouté par ShadowV2-61 est le rapport courant. Les quatre autres fichiers étaient présents avant le lot et sont documentés comme préexistants.

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
- [x] ProjectBuildingShadowPreset actuel audité
- [x] Opération effective Lot 60 auditée
- [x] JSON/persistence actuel audité
- [x] Diagnostics/manifest/config audités
- [x] Options d’intégration preset comparées
- [x] footprint vs footprintStrategy tranché
- [x] Source de vérité fixed tranchée
- [x] Adaptive dans preset tranché
- [x] Guard building-only traité
- [x] JSON/persistence order tranché
- [x] Option recommandée unique
- [x] Plan ShadowV2-62 précis
- [x] Fichiers interdits au Lot 62 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
