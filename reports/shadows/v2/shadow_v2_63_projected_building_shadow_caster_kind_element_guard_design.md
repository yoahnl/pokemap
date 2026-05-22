# ShadowV2-63 — Projected Building Shadow Caster Kind Element Guard Design Gate

## 1. Résumé exécutif

Option recommandée : guard dans `ProjectElementProjectedBuildingShadowConfig`.

Décision :

- ajouter plus tard `casterKind: ProjectedBuildingShadowCasterKind?` à la config ShadowV2 élément ;
- garder ce champ optionnel en V0 ;
- ne pas utiliser `categoryId` comme vérité métier ;
- ne pas utiliser `ElementPresetKind` comme guard ShadowV2 ;
- ne pas porter le guard dans `MapPlacedElement` en V0 ;
- ne pas ouvrir JSON au Lot 63 ;
- préparer un Lot 64 modèle pur, sans JSON, diagnostics, resolver, runtime/editor.

Raison centrale : le guard doit suivre l’activation ShadowV2 et le `presetId`, afin que le futur branchement puisse transmettre explicitement `casterKind` à `resolveProjectedShadowFootprintEffectiveTuning(...)`. C’est le plus petit emplacement capable de protéger l’adaptive sans polluer le modèle global d’élément ni alourdir chaque instance placée.

## 2. Objectif du lot

Objectif exécuté :

```text
Décider où et comment intégrer ProjectedBuildingShadowCasterKind
pour protéger les presets adaptiveHeightDepth contre une application naïve aux props fins,
sans implémenter encore,
sans modifier ProjectElementProjectedBuildingShadowConfig,
sans modifier ProjectElementEntry,
sans modifier MapPlacedElement,
sans modifier JSON/persistence,
sans modifier resolver/runtime/editor,
sans screenshot/baseline.
```

Ce lot est design-only. Aucun test n’a été lancé, conformément au prompt.

## 3. Rappel ShadowV2-58 à ShadowV2-62

ShadowV2-58 :

- ajoute les value objects purs `ProjectedShadowFootprintTuningStrategy`, `ProjectedShadowFootprintFixedTuning`, `ProjectedShadowFootprintAdaptiveDepthTuning`, `ProjectedShadowAdaptiveDepthGate`, `ProjectedBuildingShadowCasterKind`.
- `ProjectedBuildingShadowCasterKind` contient `building` et `largeVolume`.

ShadowV2-60 :

- ajoute `resolveProjectedShadowFootprintEffectiveTuning(...)`.
- fixed ignore `casterKind`.
- adaptive sans `casterKind` retourne `blocked(adaptiveDepthRequiresCasterKind)`.
- adaptive avec `building` ou `largeVolume` retourne un tuning effectif.

ShadowV2-62 :

- ajoute `footprintStrategy` optionnel à `ProjectBuildingShadowPreset`.
- garde `footprint` comme source fixed legacy.
- accepte `footprint == null + footprintStrategy adaptiveHeightDepth`.
- ne branche pas JSON, resolver, runtime/editor ou diagnostics.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
?? reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
```

Interprétation :

- Ces trois entrées sont préexistantes avant ShadowV2-63 et correspondent au Lot 62.
- ShadowV2-63 ne les modifie pas.
- Aucun autre fichier hors scope n’était présent au démarrage.

## 5. Lecture AGENTS.md et méthode suivie

Commandes exécutées :

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

Instructions retenues :

- `map_core` reste pure Dart.
- Les lots doivent rester chirurgicaux.
- Git write interdit sans demande explicite.
- Les rapports doivent inclure inventaire, commandes, résultats et limites.
- Les grands audits peuvent être résumés avec le signal utile et la commande exacte.
- Les rapports sous `reports/` ne sont modifiés que quand la tâche le demande.

`skills/README.md` :

```text
skills/README.md not found
```

Méthode réellement suivie :

- Pass 1 — Audit modèles élément / config / placement.
- Pass 2 — Audit adaptive preset + effective tuning.
- Pass 3 — Design options.
- Pass 4 — Evidence/report.

Skills consultés :

- `superpowers:using-superpowers`
- `karpathy-guidelines`
- `superpowers:verification-before-completion`

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés par ShadowV2-63 :

```text
reports/shadows/v2/shadow_v2_63_projected_building_shadow_caster_kind_element_guard_design.md
```

Fichiers modifiés par ShadowV2-63 :

```text
Aucun
```

Fichiers supprimés par ShadowV2-63 :

```text
Aucun
```

Fichiers préexistants non liés au Lot 63 :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
```

## 7. Audit ProjectElementProjectedBuildingShadowConfig

Commande obligatoire exécutée :

```bash
rg -n "ProjectElementProjectedBuildingShadowConfig|enabled|presetId|anchor|localOffset|casterKind|building|largeVolume|operator ==|hashCode|projectedBuildingShadow" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
```

Signal retenu :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:642:final class ProjectElementProjectedBuildingShadowConfig
packages/map_core/lib/src/models/projected_building_shadow.dart:644:required bool enabled
packages/map_core/lib/src/models/projected_building_shadow.dart:645:required String presetId
packages/map_core/lib/src/models/projected_building_shadow.dart:646:required ProjectedShadowAnchor anchor
packages/map_core/lib/src/models/projected_building_shadow.dart:647:required ProjectedShadowOffset localOffset
packages/map_core/lib/src/models/projected_building_shadow.dart:674:bool operator ==(Object other)
packages/map_core/lib/src/models/projected_building_shadow.dart:683:int get hashCode
```

Structure actuelle :

- `enabled`
- `presetId`
- `anchor`
- `localOffset`

Validation actuelle :

- `presetId` non blank.
- `anchor` et `localOffset` valident leurs propres value objects.
- Aucun `casterKind`.

Tests actuels :

- stockage des quatre champs ;
- `enabled false` conserve l’intention de preset ;
- rejet `presetId` blank ;
- equality/hashCode incluent les quatre champs actuels.

Codec JSON actuel :

- encode `enabled`, `presetId`, `anchor`, `localOffset`.
- decode exige les quatre champs.
- ignore les clés inconnues.
- ne porte pas `casterKind`.

Impact d’un futur champ optionnel :

- modèle : ajout local, faible surface.
- equality/hashCode : devront inclure `casterKind`.
- fixed legacy : pas de bruit si default `null`.
- JSON : différé pour éviter un changement de schéma dans le même lot.

## 8. Audit ProjectElementEntry

Commande obligatoire exécutée :

```bash
rg -n "class ProjectElementEntry|ProjectElementEntry|categoryId|presetKind|shadow|projectedBuildingShadow|collision|tilesetId|element|ElementPresetKind|copyWith|fromJson|toJson" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow_v2
```

Signal retenu :

```text
packages/map_core/lib/src/models/project_manifest.dart:422:class ProjectElementEntry with _$ProjectElementEntry
packages/map_core/lib/src/models/project_manifest.dart:425:required String id
packages/map_core/lib/src/models/project_manifest.dart:426:required String name
packages/map_core/lib/src/models/project_manifest.dart:427:required String tilesetId
packages/map_core/lib/src/models/project_manifest.dart:428:required String categoryId
packages/map_core/lib/src/models/project_manifest.dart:433:@Default(ElementPresetKind.generic) ElementPresetKind presetKind
packages/map_core/lib/src/models/project_manifest.dart:434:ElementCollisionProfile? collisionProfile
packages/map_core/lib/src/models/project_manifest.dart:436:ProjectElementShadowConfig? shadow
packages/map_core/lib/src/models/project_manifest.dart:443:ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow
```

Rôle actuel :

- `ProjectElementEntry` est l’asset/catalogue élément.
- `categoryId` relie l’élément à une catégorie catalogue.
- `presetKind` donne une classification générale existante (`generic`, `tree`, `building`, `rock`, `cliff`, `tallDecoration`).
- `projectedBuildingShadow` porte déjà la config ShadowV2 optionnelle.

Pourquoi `categoryId` ne suffit pas :

- c’est une chaîne libre ;
- elle dépend du catalogue/UI ;
- elle peut être renommée ;
- elle ne garantit pas une sémantique `building/largeVolume` stable ;
- elle introduirait une inférence magique contraire à la cible produit.

Pourquoi `presetKind` ne suffit probablement pas :

- il ne distingue pas `largeVolume` ;
- `tallDecoration` peut inclure des props fins ;
- il est plus global que ShadowV2 ;
- il ne dit pas qu’un auteur approuve Adaptive C+ pour ce preset précis.

## 9. Audit MapPlacedElement / instance overrides

Commande obligatoire exécutée :

```bash
rg -n "MapPlacedElement|shadowOverride|MapPlacedElementShadowOverride|placed element|elementId|instance|override|projectedBuildingShadow|casterKind" packages/map_core/lib/src/models packages/map_core/test
```

Signal retenu :

```text
packages/map_core/lib/src/models/map_data.dart:99:class MapPlacedElement with _$MapPlacedElement
packages/map_core/lib/src/models/map_data.dart:104:required String elementId
packages/map_core/lib/src/models/map_data.dart:109:@MapPlacedElementShadowOverrideJsonConverter()
packages/map_core/lib/src/models/map_data.dart:110:MapPlacedElementShadowOverride? shadowOverride
packages/map_core/lib/src/models/shadow.dart:257:final class MapPlacedElementShadowOverride
```

`MapPlacedElement` porte aujourd’hui :

- `id`
- `layerId`
- `elementId`
- `pos`
- `applyCollision`
- `opacity`
- `animation`
- `shadowOverride`
- `behaviors`
- `properties`

`MapPlacedElementShadowOverride` V1 porte :

- `mode`
- `shadowProfileId`
- offsets/scales/opacité ;
- `family`
- `footprint`

Analyse :

- Un guard instance-level est possible, mais trop lourd pour V0.
- Il ferait répéter `building/largeVolume` sur chaque placement.
- Il rendrait l’authoring pénible pour un cas qui est normalement lié à l’asset ou à sa config ShadowV2.
- Il reste utile plus tard pour des cas rares où un même élément doit être autorisé différemment selon placement.

## 10. Audit preset adaptive / effective tuning

Commande obligatoire exécutée :

```bash
rg -n "footprintStrategy|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowFootprintFixedTuning|ProjectedBuildingShadowCasterKind|resolveProjectedShadowFootprintEffectiveTuning|adaptiveDepthRequiresCasterKind|adaptiveDepthUnsupportedCasterKind|building|largeVolume|thin_prop_like|adaptiveT" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2 reports/shadows/v2
```

Signal retenu :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:21:enum ProjectedBuildingShadowCasterKind
packages/map_core/lib/src/models/projected_building_shadow.dart:22:building
packages/map_core/lib/src/models/projected_building_shadow.dart:23:largeVolume
packages/map_core/lib/src/models/projected_building_shadow.dart:466:ProjectedShadowFootprintTuningStrategy? footprintStrategy
packages/map_core/lib/src/models/projected_building_shadow.dart:760:case ProjectedShadowFootprintAdaptiveDepthTuning()
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:108:resolveProjectedShadowFootprintEffectiveTuning
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:155:if (casterKind == null)
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:157:adaptiveDepthRequiresCasterKind
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:161:if (!_isAdaptiveCompatibleCasterKind(casterKind))
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:164:adaptiveDepthUnsupportedCasterKind
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:222:ProjectedBuildingShadowCasterKind.building => true
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart:223:ProjectedBuildingShadowCasterKind.largeVolume => true
```

Analyse :

- Un preset adaptive existe maintenant dans le modèle via `footprintStrategy`.
- L’opération effective sait résoudre seulement si un `ProjectedBuildingShadowCasterKind?` compatible est fourni.
- Sans caster, l’opération retourne `blocked`.
- Le guard doit donc exister avant tout branchement resolver/runtime/editor, sinon l’adaptive resterait soit bloqué, soit exposé à un fallback dangereux.

## 11. Audit diagnostics actuels

Commande obligatoire exécutée :

```bash
rg -n "diagnoseProjectedBuildingShadows|ProjectedBuildingShadowDiagnostic|ProjectedBuildingShadowDiagnosticKind|missingPreset|unusedPreset|v1AndV2Coexistence|followsSun|warning|error|info|projectedBuildingShadow|preset" packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Signal retenu :

```text
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:10:enum ProjectedBuildingShadowDiagnosticKind
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:11:missingPreset
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:12:missingPresetForDisabledConfig
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:13:unusedPreset
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:14:v1AndV2Coexistence
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:15:followsSunWithoutTimeOfDay
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart:66:diagnoseProjectedBuildingShadows
```

Diagnostics actuels :

- missing preset actif : error.
- missing preset sur config disabled : warning.
- preset inutilisé : warning.
- coexistence Shadow V1 + Shadow V2 actif : warning.
- followsSun sans système time-of-day : info.

Manques actuels :

- pas de diagnostic adaptive preset sans `casterKind`.
- pas de diagnostic caster incompatible.
- pas de diagnostic caster présent sur fixed legacy.

## 12. Audit JSON/persistence actuel

Commande obligatoire exécutée :

```bash
rg -n "ProjectElementProjectedBuildingShadowConfig JSON|encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig|presetId|anchor|localOffset|enabled|casterKind|ProjectBuildingShadowPreset JSON|footprintStrategy|geometryMode|footprint|toJson|fromJson" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
```

Signal retenu :

```text
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:62:encodeProjectElementProjectedBuildingShadowConfig
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:66:'enabled': config.enabled
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:67:'presetId': config.presetId
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:68:'anchor': encodeProjectedShadowAnchor(config.anchor)
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:69:'localOffset': encodeProjectedShadowOffset(config.localOffset)
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:79:decodeProjectElementProjectedBuildingShadowConfig
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart:84:encodeProjectBuildingShadowPreset
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart:105:decodeProjectBuildingShadowPreset
```

État actuel :

- `ProjectElementProjectedBuildingShadowConfig` JSON ne persiste pas `casterKind`.
- `ProjectBuildingShadowPreset` JSON ne persiste pas `footprintStrategy`.
- Les clés inconnues sont ignorées sur la config élément.
- Les tests caractérisent le round-trip sans réémission de clés inconnues.

Décision Lot 63 :

- ne pas ouvrir JSON maintenant.
- recommander modèle guard d’abord, JSON ensuite.

## 13. Problème à résoudre

Le preset adaptive existe :

```text
ProjectBuildingShadowPreset(
  geometryMode: footprint,
  footprint: null,
  footprintStrategy: ProjectedShadowFootprintAdaptiveDepthTuning(...)
)
```

L’opération effective exige un signal compatible :

```text
adaptiveHeightDepth + casterKind == null
=> blocked(adaptiveDepthRequiresCasterKind)
```

Le modèle actuel ne porte pas encore :

```text
cet élément est building
cet élément est largeVolume
cet élément n’est pas un prop fin
```

Le design doit donc placer ce signal sans créer d’inférence automatique par taille, catégorie libre ou runtime.

## 14. Options d’emplacement du guard

Option A — Guard dans `ProjectElementProjectedBuildingShadowConfig`

- Avantages : local ShadowV2, suit `presetId`, suit `enabled`, faible surface, transmis directement au futur resolver effectif.
- Inconvénient : le concept décrit partiellement l’asset, mais vit dans une config d’ombre.
- Verdict : recommandé.

Option B — Guard dans `ProjectElementEntry`

- Avantages : sémantique asset globale, possiblement réutilisable.
- Inconvénients : plus large, touche JSON/freezed/generated, pollue l’élément avec une décision encore ShadowV2, prématuré.
- Verdict : rejeté pour V0.

Option C — Guard dans `MapPlacedElement` / instance

- Avantages : contrôle très fin.
- Inconvénients : duplication par placement, authoring pénible, trop lourd pour V0.
- Verdict : rejeté pour V0.

Option D — Guard via `categoryId` / `presetKind`

- Avantages : aucun champ nouveau.
- Inconvénients : inférence fragile, `categoryId` libre, `presetKind` trop grossier, aucun author approval explicite.
- Verdict : rejeté.

Option E — Diagnostics/editor-only

- Avantages : pas de modèle immédiat.
- Inconvénients : données incohérentes possibles hors editor, operation reçoit toujours `null`, runtime/imports non protégés.
- Verdict : rejeté comme solution principale.

Option F — Hybrid V0

- Principe : `casterKind` optionnel dans `ProjectElementProjectedBuildingShadowConfig`, editor/diagnostics/resolver branchés plus tard.
- Verdict : recommandé.

## 15. Optionnel vs requis

Décision : `casterKind` optionnel en V0.

Pourquoi :

- required partout casserait inutilement le fixed legacy.
- required seulement si adaptive demande de connaître le preset dans le constructeur config, ce qui couplerait config et catalogue.
- optionnel + diagnostics futurs garde le modèle simple.
- l’opération effective existe déjà pour bloquer explicitement adaptive sans caster.

Règle sémantique future :

```text
Si config.enabled == true
et config.presetId pointe vers un preset adaptiveHeightDepth,
alors casterKind doit être présent et compatible.
```

Cette règle doit vivre dans les diagnostics et le futur branchement resolver, pas dans le constructeur config V0.

## 16. Valeur par défaut

Décision : aucune valeur par défaut autre que `null`.

Pourquoi :

- default `building` serait dangereux.
- default `largeVolume` serait dangereux.
- `null` force une décision authoring/diagnostic explicite.
- `null` préserve les configs fixed legacy sans bruit.

## 17. JSON / persistence order

Option recommandée : modèle d’abord, JSON ensuite.

Ordre recommandé :

1. Lot 64 : ajouter `casterKind` optionnel dans le modèle config, avec tests modèle uniquement.
2. Lot 65 ou design dédié : JSON/persistence pour `casterKind`, avec compat lecture des JSON existants.
3. Lot diagnostics : signaler adaptive sans caster.
4. Lot resolver integration : transmettre `casterKind` à l’opération effective.

Pourquoi ne pas faire modèle + JSON ensemble :

- surface de casse plus large ;
- JSON manuel à tester soigneusement ;
- cohérent avec `footprintStrategy`, qui a d’abord été intégré au modèle sans JSON ;
- pas de generated/build_runner dans ce lot.

## 18. Diagnostics futurs

Indispensable :

- `adaptivePresetRequiresCasterKind` : error ou warning fort quand un élément actif référence un preset adaptive sans `casterKind`.

Probablement utile :

- `adaptivePresetUnsupportedCasterKind` : error si l’enum évolue et que le caster n’est plus compatible.
- `casterKindSetButPresetIsFixed` : info ou warning faible, car ce n’est pas dangereux mais peut indiquer un authoring inutile.

Pas urgent :

- `casterKindSetButConfigDisabled` : plutôt info faible ou aucun diagnostic, car une config disabled peut conserver une intention authoring.

## 19. Option recommandée

Option recommandée : Hybrid V0, guard dans `ProjectElementProjectedBuildingShadowConfig`.

Décision :

- guard dans `ProjectElementProjectedBuildingShadowConfig`.
- pas de guard dans `ProjectElementEntry` en V0.
- pas de guard dans `MapPlacedElement` en V0.
- pas de guard editor-only.
- pas de guard par `categoryId`.
- pas de guard par `presetKind`.

Pourquoi :

- le champ est proche de `presetId` et de l’activation ShadowV2 ;
- le futur resolver peut lire la config élément et transmettre `casterKind`;
- fixed legacy reste léger avec `null`;
- les props fins restent protégés car adaptive ne peut pas être résolu sans approbation explicite ;
- le champ ne pollue pas l’asset global pour un besoin encore ShadowV2.

Pourquoi les autres options sont rejetées :

- `ProjectElementEntry` est trop global pour V0.
- `MapPlacedElement` est trop fin et trop coûteux en authoring.
- `categoryId` est libre et fragile.
- `presetKind` est trop grossier et ne représente pas l’approbation Adaptive C+.
- editor-only ne protège pas les imports, tests et données manipulées hors editor.

## 20. Design conceptuel recommandé

Champ :

```text
casterKind
```

Type :

```text
ProjectedBuildingShadowCasterKind?
```

Optionnel/requis :

```text
Optionnel dans le modèle V0.
Obligatoire sémantiquement seulement pour config active + preset adaptive.
```

Valeur par défaut :

```text
null
```

Relation avec preset adaptive :

```text
adaptiveHeightDepth exige casterKind building ou largeVolume pour être résolu.
```

Relation avec fixed legacy :

```text
fixed legacy ignore casterKind.
casterKind null reste normal.
casterKind non null sur fixed peut devenir diagnostic info/warning faible.
```

Relation avec disabled config :

```text
disabled + casterKind peut rester autorisé pour conserver l’intention authoring.
Pas de diagnostic urgent.
```

Relation avec JSON futur :

```text
casterKind sera encodé comme string stable, probablement "building" / "largeVolume".
Les anciens JSON sans casterKind doivent décoder null.
Les nouveaux JSON ne doivent pas inférer depuis categoryId.
```

Relation avec diagnostics futurs :

```text
diagnoseProjectedBuildingShadows(manifest) devra joindre element config + preset catalog.
Si preset adaptive actif et casterKind null => adaptivePresetRequiresCasterKind.
```

Relation avec resolver futur :

```text
Le futur branchement construira ou dérivera la stratégie du preset, puis appellera :
resolveProjectedShadowFootprintEffectiveTuning(
  strategy: strategy,
  metrics: metrics,
  fixedOpacity: preset.appearance.opacity,
  casterKind: config.casterKind,
)
```

## 21. Plan précis du Lot 64

Nom recommandé :

```text
ShadowV2-64 — Projected Building Shadow Caster Kind Config Model V0
```

Lot 64 doit faire :

- modifier uniquement `packages/map_core/lib/src/models/projected_building_shadow.dart`;
- ajouter `casterKind: ProjectedBuildingShadowCasterKind?` à `ProjectElementProjectedBuildingShadowConfig`;
- inclure `casterKind` dans stockage, equality et hashCode ;
- garder default `null` ;
- ne pas rendre `casterKind` required ;
- créer un test modèle ciblé, probablement `packages/map_core/test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart` ou compléter prudemment le test config existant si le lot l’autorise ;
- créer le rapport Lot 64.

Lot 64 ne doit pas faire :

- modifier JSON/codecs ;
- modifier diagnostics ;
- modifier resolver géométrique ;
- modifier opération effective ;
- modifier runtime/editor ;
- modifier `ProjectElementEntry`;
- modifier `MapPlacedElement`;
- créer screenshot/baseline ;
- toucher Selbrume ;
- lancer build_runner.

## 22. Fichiers explicitement interdits au Lot 64

À ne pas modifier au Lot 64 :

```text
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
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

## 23. Risques / réserves

- Le guard dans la config ShadowV2 décrit un aspect de l’asset, mais reste local à l’ombre.
- Si d’autres systèmes ont besoin de `building/largeVolume`, un futur refactor pourra remonter le concept vers l’élément.
- Tant que JSON n’est pas branché, le guard modèle ne sera pas persistant.
- Tant que diagnostics ne sont pas branchés, une config adaptive sans caster restera seulement bloquée par l’opération effective si elle est appelée.
- Tant que resolver/runtime/editor ne sont pas branchés, cette décision prépare le système sans changer le rendu.

## 24. Auto-critique

- Le lot est-il bien design-only ? Oui, seul ce rapport est créé.
- Le rapport évite-t-il de coder dans un design gate ? Oui.
- Le rapport choisit-il un emplacement clair pour `casterKind` ? Oui, `ProjectElementProjectedBuildingShadowConfig`.
- Le rapport évite-t-il d’utiliser `categoryId` comme vérité métier ? Oui.
- Le rapport évite-t-il d’alourdir `MapPlacedElement` prématurément ? Oui.
- Le rapport garde-t-il JSON/persistence hors implémentation ? Oui.
- Le rapport garde-t-il resolver/runtime/editor hors scope ? Oui.
- Le plan Lot 64 est-il assez petit ? Oui, modèle config pur + tests modèle.
- Le rapport contient-il toutes les preuves ? Oui : état initial, commandes d’audit, décisions, Git final.

## 25. Regard critique sur le prompt

Le prompt est cohérent avec la séquence ShadowV2 : Lot 62 a rendu l’adaptive exprimable dans le preset, et Lot 63 force maintenant la décision de guard avant toute intégration resolver/runtime. Le point le plus important est de ne pas confondre guard sémantique et catégorie catalogue libre : le prompt insiste correctement sur l’interdiction d’une inférence magique.

## 26. Commandes lancées

Commandes exécutées :

```bash
git status --short --untracked-files=all
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
if [ -f skills/README.md ]; then sed -n '1,220p' skills/README.md; else printf 'skills/README.md not found\n'; fi
rg -n "ProjectElementProjectedBuildingShadowConfig|enabled|presetId|anchor|localOffset|casterKind|building|largeVolume|operator ==|hashCode|projectedBuildingShadow" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2
rg -n "class ProjectElementEntry|ProjectElementEntry|categoryId|presetKind|shadow|projectedBuildingShadow|collision|tilesetId|element|ElementPresetKind|copyWith|fromJson|toJson" packages/map_core/lib/src/models/project_manifest.dart packages/map_core/test/shadow_v2
rg -n "MapPlacedElement|shadowOverride|MapPlacedElementShadowOverride|placed element|elementId|instance|override|projectedBuildingShadow|casterKind" packages/map_core/lib/src/models packages/map_core/test
rg -n "footprintStrategy|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowFootprintFixedTuning|ProjectedBuildingShadowCasterKind|resolveProjectedShadowFootprintEffectiveTuning|adaptiveDepthRequiresCasterKind|adaptiveDepthUnsupportedCasterKind|building|largeVolume|thin_prop_like|adaptiveT" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2 reports/shadows/v2
rg -n "diagnoseProjectedBuildingShadows|ProjectedBuildingShadowDiagnostic|ProjectedBuildingShadowDiagnosticKind|missingPreset|unusedPreset|v1AndV2Coexistence|followsSun|warning|error|info|projectedBuildingShadow|preset" packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
rg -n "ProjectElementProjectedBuildingShadowConfig JSON|encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig|presetId|anchor|localOffset|enabled|casterKind|ProjectBuildingShadowPreset JSON|footprintStrategy|geometryMode|footprint|toJson|fromJson" packages/map_core/lib/src/operations packages/map_core/test/shadow_v2
nl -ba packages/map_core/lib/src/models/projected_building_shadow.dart | sed -n '1,80p;450,790p'
nl -ba packages/map_core/lib/src/models/project_manifest.dart | sed -n '420,452p'
nl -ba packages/map_core/lib/src/models/map_data.dart | sed -n '1,220p'
nl -ba packages/map_core/lib/src/models/shadow.dart | sed -n '1,390p'
nl -ba packages/map_core/lib/src/models/enums.dart | sed -n '410,430p'
nl -ba packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart | sed -n '1,240p'
nl -ba packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart | sed -n '1,220p'
nl -ba packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart | sed -n '1,140p'
nl -ba packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart | sed -n '1,170p'
nl -ba packages/map_core/test/shadow_v2/projected_building_shadow_element_config_test.dart | sed -n '1,140p'
nl -ba packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart | sed -n '1,220p'
nl -ba packages/map_core/test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart | sed -n '1,230p'
git diff --stat
git diff --name-status
git diff --check
git status --short --untracked-files=all
```

Tests :

```text
Aucun test lancé. Lot 63 est design-only et le prompt demande explicitement de ne pas lancer les tests.
```

## 27. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../lib/src/models/projected_building_shadow.dart  | 32 ++++++++++++++++++++--
 1 file changed, 29 insertions(+), 3 deletions(-)
```

Interprétation :

- Le diff suivi correspond au Lot 62 préexistant.
- Le rapport Lot 63 est un fichier non suivi et apparaît dans `git status`.

## 28. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

Interprétation :

- Modification suivie préexistante du Lot 62.
- Aucun fichier Dart n’a été modifié par ShadowV2-63.

## 29. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 30. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
?? reports/shadows/v2/shadow_v2_62_projected_building_shadow_adaptive_depth_preset_model_v0.md
?? reports/shadows/v2/shadow_v2_63_projected_building_shadow_caster_kind_element_guard_design.md
```

Conformité scope :

- Les trois premières entrées sont préexistantes au Lot 63 et documentées en section 4.
- La seule création ShadowV2-63 est le rapport courant.

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
- [x] ProjectElementProjectedBuildingShadowConfig audité
- [x] ProjectElementEntry audité
- [x] MapPlacedElement audité
- [x] Preset adaptive / effective tuning audité
- [x] Diagnostics actuels audités
- [x] JSON/persistence actuel audité
- [x] Options d’emplacement comparées
- [x] Optionnel vs requis tranché
- [x] Valeur par défaut tranchée
- [x] JSON/persistence order tranché
- [x] Diagnostics futurs proposés
- [x] Option recommandée unique
- [x] Plan ShadowV2-64 précis
- [x] Fichiers interdits au Lot 64 listés
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
