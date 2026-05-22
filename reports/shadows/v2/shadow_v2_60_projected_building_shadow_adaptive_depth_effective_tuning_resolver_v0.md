# ShadowV2-60 — Projected Building Shadow Adaptive Depth Effective Tuning Resolver V0

## 1. Résumé exécutif

ShadowV2-60 implémente l'opération pure décidée au Lot 59 :

```text
resolveProjectedShadowFootprintEffectiveTuning(...)
```

Le lot reste limité à `map_core` :

- opération pure créée ;
- result objects `resolved/blocked` créés ;
- test ciblé créé ;
- barrel public `map_core.dart` modifié pour exporter l'opération ;
- rapport Markdown créé.

Aucun branchement n'a été fait dans `resolveProjectedBuildingShadowGeometry(...)`. Aucun modèle existant, JSON/codec, runtime, editor, renderer/painter, Selbrume, screenshot ou baseline n'a été modifié.

## 2. Objectif du lot

Objectif exécuté :

```text
Créer une opération pure dans map_core permettant de résoudre un tuning footprint effectif depuis :
- ProjectedShadowFootprintFixedTuning ;
- ProjectedShadowFootprintAdaptiveDepthTuning ;
- StaticShadowVisualMetrics ;
- ProjectedBuildingShadowCasterKind? ;
sans modifier le resolver géométrique existant.
```

Succès attendus couverts :

- fixed retourne tuning + `fixedOpacity` + `adaptiveT = 0` ;
- adaptive sans caster retourne `blocked(adaptiveDepthRequiresCasterKind)` ;
- adaptive avec `building` ou `largeVolume` résout le tuning interpolé ;
- `wide_house_6x5` et `medium_shop_5x6` restent au base tuning ;
- `tall_shop_4x7` atteint C+ ;
- `thin_prop_like_2x6` calcule le canary `adaptiveT = 0.5` sans officialiser les props fins ;
- interpolation intermédiaire testée ;
- opacité effective testée.

## 3. Rappel ShadowV2-59

Décision Lot 59 :

```text
Option B — opération pure dédiée resolveProjectedShadowFootprintEffectiveTuning(...)
+ Result D — union result success / blocked
```

Design retenu :

```text
Fixed -> resolved(tuning, fixedOpacity, adaptiveT = 0, strategyKind = fixed)
Adaptive + casterKind building/largeVolume -> resolved(interpolated tuning, interpolated opacity, adaptiveT, strategyKind = adaptiveHeightDepth)
Adaptive + casterKind null -> blocked(adaptiveDepthRequiresCasterKind)
Adaptive + casterKind incompatible futur -> blocked(adaptiveDepthUnsupportedCasterKind)
```

Lot 60 ne devait pas modifier le resolver géométrique, JSON, runtime, editor ou les modèles existants. Ce cadre a été respecté.

## 4. État initial du worktree

Commande initiale :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
```

Fichier préexistant non lié au Lot 60 :

- `reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md`

Ce fichier était déjà non suivi avant ShadowV2-60 et n'a pas été modifié par ce lot.

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

Règles appliquées depuis `AGENTS.md` :

- package par package ;
- `map_core` reste pure Dart ;
- changements chirurgicaux ;
- git write interdit ;
- tests ciblés puis validations élargies ;
- rapport avec inventaire, preuves, commandes et contenu complet des fichiers créés/modifiés.

`skills/README.md` :

```text
skills/README.md absent
```

Aucun `AGENTS.md` plus profond n'a été trouvé sous `packages/map_core`.

Skills utilisés :

- `superpowers:using-superpowers` ;
- `karpathy-guidelines` ;
- `superpowers:test-driven-development` ;
- `dart-add-unit-test` ;
- `dart-run-static-analysis` ;
- `superpowers:verification-before-completion`.

Passes réalisées :

- Pass 1 — Audit modèle / opérations existantes.
- Pass 2 — Tests RED.
- Pass 3 — Implémentation pure operation.
- Pass 4 — Tests / analyze / evidence.

## 6. Fichiers créés / modifiés / supprimés

Créés par ShadowV2-60 :

- `packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart`
- `packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart`
- `reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md`

Modifiés par ShadowV2-60 :

- `packages/map_core/lib/map_core.dart`

Supprimés par ShadowV2-60 : Aucun.

Fichiers préexistants hors scope non touchés :

- `reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md`

## 7. Audit initial

Commandes obligatoires exécutées avant modification :

```bash
rg -n "ProjectedShadowFootprintTuningStrategy|ProjectedShadowFootprintFixedTuning|ProjectedShadowFootprintAdaptiveDepthTuning|ProjectedShadowAdaptiveDepthGate|ProjectedBuildingShadowCasterKind|referenceHeight|targetHeight|referenceRatio|targetRatio|baseOpacity|targetOpacity" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md

rg -n "resolveProjectedBuildingShadowGeometry|_resolveFootprintProjectedBuildingShadowGeometry|StaticShadowVisualMetrics|visualWidth|visualHeight|ProjectedShadowFootprintTuning|opacity|colorHexRgb|geometryMode|footprint" packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart packages/map_core/lib/src/operations/static_shadow_geometry.dart packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart

rg -n "projected_building_shadow_geometry|static_shadow_geometry|operations" packages/map_core/lib/map_core.dart
```

Constats :

- Les types Lot 58 sont présents dans `projected_building_shadow.dart`.
- `StaticShadowVisualMetrics` valide `visualWidth > 0` et `visualHeight > 0`, donc l'opération peut diviser par `visualWidth` sans validation dupliquée.
- Le resolver géométrique existant reste centré sur `ProjectBuildingShadowPreset`, `ProjectedShadowAppearance` et `ProjectedShadowFootprintTuning`.
- `map_core.dart` exporte déjà les opérations publiques, donc l'export de la nouvelle opération est cohérent.

## 8. Operation créée

Fichier créé :

```text
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
```

Opération créée :

```dart
ProjectedShadowFootprintEffectiveTuningResult
    resolveProjectedShadowFootprintEffectiveTuning({
  required ProjectedShadowFootprintTuningStrategy strategy,
  required StaticShadowVisualMetrics metrics,
  required double fixedOpacity,
  ProjectedBuildingShadowCasterKind? casterKind,
})
```

Elle ne construit aucune géométrie et ne lit pas `ProjectBuildingShadowPreset`, `ProjectElementProjectedBuildingShadowConfig`, JSON, runtime ou editor.

## 9. Result objects créés

Types créés :

- `ProjectedShadowFootprintEffectiveTuningStrategyKind`
- `ProjectedShadowFootprintEffectiveTuningBlockReason`
- `ProjectedShadowEffectiveFootprintTuning`
- `ProjectedShadowFootprintEffectiveTuningResult`
- `ProjectedShadowFootprintEffectiveTuningResolved`
- `ProjectedShadowFootprintEffectiveTuningBlocked`

Validations :

- `ProjectedShadowEffectiveFootprintTuning.opacity` doit être dans `[0, 1]` ;
- `ProjectedShadowEffectiveFootprintTuning.adaptiveT` doit être dans `[0, 1]`.

Equality/hashCode :

- tous les champs utiles sont inclus.

## 10. Fixed strategy behavior

Pour `ProjectedShadowFootprintFixedTuning` :

```text
tuning = strategy.tuning
opacity = fixedOpacity
adaptiveT = 0
strategyKind = fixed
```

`casterKind` est ignoré pour fixed.

`fixedOpacity` est validée dans `[0, 1]`.

## 11. Adaptive strategy behavior

Pour `ProjectedShadowFootprintAdaptiveDepthTuning` avec caster compatible :

```text
heightGate = clamp((metrics.visualHeight - gate.referenceHeight) / (gate.targetHeight - gate.referenceHeight), 0, 1)
ratioGate = clamp((metrics.visualHeight / metrics.visualWidth - gate.referenceRatio) / (gate.targetRatio - gate.referenceRatio), 0, 1)
adaptiveT = heightGate * ratioGate
```

Champs interpolés :

- `attachYRatio`
- `frontWidthRatio`
- `rearWidthRatio`
- `depthRatio`
- `skewXRatio`
- `opacity`

Cas validés par tests :

- `wide_house_6x5` : base ;
- `medium_shop_5x6` : base ;
- `tall_shop_4x7` : C+ ;
- `thin_prop_like_2x6` : canary partiel `adaptiveT = 0.5` ;
- cas intermédiaire : `adaptiveT = 0.25`.

## 12. Guard blocked behavior

Cas `casterKind == null` :

```text
ProjectedShadowFootprintEffectiveTuningBlocked(
  reason: adaptiveDepthRequiresCasterKind,
)
```

Cas unsupported futur :

```text
ProjectedShadowFootprintEffectiveTuningBlocked(
  reason: adaptiveDepthUnsupportedCasterKind,
)
```

Avec l'enum actuelle, `building` et `largeVolume` sont les deux seules valeurs et elles sont compatibles. Le reason `adaptiveDepthUnsupportedCasterKind` est présent pour stabiliser le design si un caster kind non compatible est ajouté plus tard.

## 13. Opacité effective

Fixed :

```text
opacity = fixedOpacity
```

Adaptive :

```text
opacity = lerp(baseOpacity, targetOpacity, adaptiveT)
```

L'opération ne modifie pas `ProjectedShadowAppearance`. Elle retourne une opacité effective dans le payload résolu.

## 14. Clamp / lerp / metrics

Helpers privés créés :

- `_clamp01`
- `_lerp`
- `_validateUnitInterval`
- `_isAdaptiveCompatibleCasterKind`
- `_resolveFixedFootprintEffectiveTuning`
- `_resolveAdaptiveHeightDepthFootprintEffectiveTuning`

`StaticShadowVisualMetrics` garantit déjà :

```text
visualWidth > 0
visualHeight > 0
```

Donc l'opération ne duplique pas ces validations.

## 15. Exports map_core

`packages/map_core/lib/map_core.dart` a été modifié uniquement pour exporter :

```dart
export 'src/operations/projected_shadow_footprint_effective_tuning.dart';
```

Ce choix suit le style du package, où `static_shadow_geometry.dart` et `projected_building_shadow_geometry.dart` sont déjà exportés depuis le barrel public.

## 16. Ce qui n’a volontairement pas été branché

Non branché :

- `resolveProjectedBuildingShadowGeometry(...)`
- `ProjectBuildingShadowPreset`
- `ProjectElementProjectedBuildingShadowConfig`
- `ProjectElementEntry`
- `MapPlacedElement`
- JSON/persistence
- runtime
- editor
- renderer/painter
- diagnostics
- Selbrume
- screenshot/baseline

## 17. Résultats tests ciblés

Commande RED exécutée avant production code :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Résultat RED attendu :

```text
Failed to load "test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart":
Error: Type 'ProjectedShadowEffectiveFootprintTuning' not found.
Error: Type 'ProjectedShadowFootprintEffectiveTuningResult' not found.
Error: Method not found: 'resolveProjectedShadowFootprintEffectiveTuning'.
Some tests failed.
```

Commande GREEN finale :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Sortie :

```text
00:00 +0: loading test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
00:00 +0: resolveProjectedShadowFootprintEffectiveTuning fixed resolves fixed tuning with fixed opacity
00:00 +1: resolveProjectedShadowFootprintEffectiveTuning fixed resolves fixed tuning with fixed opacity
00:00 +1: resolveProjectedShadowFootprintEffectiveTuning fixed ignores casterKind for fixed tuning
00:00 +2: resolveProjectedShadowFootprintEffectiveTuning fixed ignores casterKind for fixed tuning
00:00 +2: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity below 0
00:00 +3: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity below 0
00:00 +3: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity above 1
00:00 +4: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity above 1
00:00 +4: resolveProjectedShadowFootprintEffectiveTuning adaptive blocks adaptive depth without casterKind
00:00 +5: resolveProjectedShadowFootprintEffectiveTuning adaptive blocks adaptive depth without casterKind
00:00 +5: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for building caster
00:00 +6: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for building caster
00:00 +6: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for largeVolume caster
00:00 +7: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for largeVolume caster
00:00 +7: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps wide_house_6x5 at base tuning
00:00 +8: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps wide_house_6x5 at base tuning
00:00 +8: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps medium_shop_5x6 at base tuning
00:00 +9: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps medium_shop_5x6 at base tuning
00:00 +9: resolveProjectedShadowFootprintEffectiveTuning adaptive partially adapts thin_prop_like_2x6 canary
00:00 +10: resolveProjectedShadowFootprintEffectiveTuning adaptive partially adapts thin_prop_like_2x6 canary
00:00 +10: resolveProjectedShadowFootprintEffectiveTuning adaptive interpolates both gates multiplicatively
00:00 +11: resolveProjectedShadowFootprintEffectiveTuning adaptive interpolates both gates multiplicatively
00:00 +11: ProjectedShadowEffectiveFootprintTuning equality includes all fields
00:00 +12: ProjectedShadowEffectiveFootprintTuning equality includes all fields
00:00 +12: ProjectedShadowEffectiveFootprintTuning rejects opacity below 0
00:00 +13: ProjectedShadowEffectiveFootprintTuning rejects opacity below 0
00:00 +13: ProjectedShadowEffectiveFootprintTuning rejects opacity above 1
00:00 +14: ProjectedShadowEffectiveFootprintTuning rejects opacity above 1
00:00 +14: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT below 0
00:00 +15: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT below 0
00:00 +15: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT above 1
00:00 +16: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT above 1
00:00 +16: ProjectedShadowFootprintEffectiveTuningResult resolved equality includes value
00:00 +17: ProjectedShadowFootprintEffectiveTuningResult resolved equality includes value
00:00 +17: ProjectedShadowFootprintEffectiveTuningResult blocked equality includes reason
00:00 +18: ProjectedShadowFootprintEffectiveTuningResult blocked equality includes reason
00:00 +18: All tests passed!
```

## 18. Résultats régressions utiles

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_strategy_test.dart
```

Sortie :

```text
00:00 +0: loading test/shadow_v2/projected_shadow_footprint_strategy_test.dart
00:00 +0: ProjectedShadowFootprintFixedTuning stores explicit tuning
00:00 +1: ProjectedShadowFootprintFixedTuning stores explicit tuning
00:00 +1: ProjectedShadowFootprintFixedTuning equality includes tuning
00:00 +2: ProjectedShadowFootprintFixedTuning equality includes tuning
00:00 +2: ProjectedShadowFootprintFixedTuning hashCode includes tuning
00:00 +3: ProjectedShadowFootprintFixedTuning hashCode includes tuning
00:00 +3: ProjectedShadowAdaptiveDepthGate uses canonical defaults
00:00 +4: ProjectedShadowAdaptiveDepthGate uses canonical defaults
00:00 +4: ProjectedShadowAdaptiveDepthGate equality includes all fields
00:00 +5: ProjectedShadowAdaptiveDepthGate equality includes all fields
00:00 +5: ProjectedShadowAdaptiveDepthGate hashCode includes all fields
00:00 +6: ProjectedShadowAdaptiveDepthGate hashCode includes all fields
00:00 +6: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceHeight
00:00 +7: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceHeight
00:00 +7: ProjectedShadowAdaptiveDepthGate rejects non-positive targetHeight
00:00 +8: ProjectedShadowAdaptiveDepthGate rejects non-positive targetHeight
00:00 +8: ProjectedShadowAdaptiveDepthGate rejects targetHeight equal to referenceHeight
00:00 +9: ProjectedShadowAdaptiveDepthGate rejects targetHeight equal to referenceHeight
00:00 +9: ProjectedShadowAdaptiveDepthGate rejects targetHeight below referenceHeight
00:00 +10: ProjectedShadowAdaptiveDepthGate rejects targetHeight below referenceHeight
00:00 +10: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceRatio
00:00 +11: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceRatio
00:00 +11: ProjectedShadowAdaptiveDepthGate rejects non-positive targetRatio
00:00 +12: ProjectedShadowAdaptiveDepthGate rejects non-positive targetRatio
00:00 +12: ProjectedShadowAdaptiveDepthGate rejects targetRatio equal to referenceRatio
00:00 +13: ProjectedShadowAdaptiveDepthGate rejects targetRatio equal to referenceRatio
00:00 +13: ProjectedShadowAdaptiveDepthGate rejects targetRatio below referenceRatio
00:00 +14: ProjectedShadowAdaptiveDepthGate rejects targetRatio below referenceRatio
00:00 +14: ProjectedShadowFootprintAdaptiveDepthTuning stores base target gate and opacity endpoints
00:00 +15: ProjectedShadowFootprintAdaptiveDepthTuning stores base target gate and opacity endpoints
00:00 +15: ProjectedShadowFootprintAdaptiveDepthTuning equality includes every field
00:00 +16: ProjectedShadowFootprintAdaptiveDepthTuning equality includes every field
00:00 +16: ProjectedShadowFootprintAdaptiveDepthTuning hashCode includes every field
00:00 +17: ProjectedShadowFootprintAdaptiveDepthTuning hashCode includes every field
00:00 +17: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity below 0
00:00 +18: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity below 0
00:00 +18: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity above 1
00:00 +19: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity above 1
00:00 +19: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity below 0
00:00 +20: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity below 0
00:00 +20: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity above 1
00:00 +21: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity above 1
00:00 +21: ProjectedShadowFootprintAdaptiveDepthTuning accepts opacity endpoints 0 and 1
00:00 +22: ProjectedShadowFootprintAdaptiveDepthTuning accepts opacity endpoints 0 and 1
00:00 +22: ProjectedBuildingShadowCasterKind exposes building and largeVolume
00:00 +23: ProjectedBuildingShadowCasterKind exposes building and largeVolume
00:00 +23: ProjectedShadowFootprintTuning defaults remain unchanged
00:00 +24: ProjectedShadowFootprintTuning defaults remain unchanged
00:00 +24: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie :

```text
00:00 +0: Projected building shadow geometry disabled config returns null
00:00 +1: Projected building shadow geometry disabled config returns null
00:00 +1: Projected building shadow geometry resolves basic horizontal geometry with stable point order
00:00 +2: Projected building shadow geometry resolves basic horizontal geometry with stable point order
00:00 +2: Projected building shadow geometry normalizes direction before applying length
00:00 +3: Projected building shadow geometry normalizes direction before applying length
00:00 +3: Projected building shadow geometry resolves vertical direction geometry
00:00 +4: Projected building shadow geometry resolves vertical direction geometry
00:00 +4: Projected building shadow geometry localOffset shifts all points
00:00 +5: Projected building shadow geometry localOffset shifts all points
00:00 +5: Projected building shadow geometry shape ratios control length and widths
00:00 +6: Projected building shadow geometry shape ratios control length and widths
00:00 +6: Projected building shadow geometry propagates preset appearance
00:00 +7: Projected building shadow geometry propagates preset appearance
00:00 +7: Projected building shadow geometry followsSun uses preset direction as fixed in V0
00:00 +8: Projected building shadow geometry followsSun uses preset direction as fixed in V0
00:00 +8: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points
00:00 +9: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points
00:00 +9: Projected building shadow geometry resolves footprint geometry with attached skewed rectangle points
00:00 +10: Projected building shadow geometry resolves footprint geometry with attached skewed rectangle points
00:00 +10: Projected building shadow geometry resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points
00:00 +11: Projected building shadow geometry resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points
00:00 +11: Projected building shadow geometry footprint geometry localOffset shifts all points
00:00 +12: Projected building shadow geometry footprint geometry localOffset shifts all points
00:00 +12: Projected building shadow geometry footprint geometry ignores anchor
00:00 +13: Projected building shadow geometry footprint geometry ignores anchor
00:00 +13: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
00:00 +14: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
00:00 +14: Projected building shadow geometry point and geometry equality include ordered values
00:00 +15: Projected building shadow geometry point and geometry equality include ordered values
00:00 +15: Projected building shadow geometry geometry validates points, opacity, and color
00:00 +16: Projected building shadow geometry geometry validates points, opacity, and color
00:00 +16: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +17: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +17: All tests passed!
```

## 19. Résultat dart test test/shadow_v2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Résultat :

```text
00:01 +210: All tests passed!
```

Commande complémentaire lisible :

```bash
cd packages/map_core && dart test --reporter expanded test/shadow_v2
```

Sortie finale :

```text
00:00 +210: All tests passed!
```

## 20. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/projected_shadow_footprint_effective_tuning.dart test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Sortie :

```text
Analyzing projected_shadow_footprint_effective_tuning.dart, projected_shadow_footprint_effective_tuning_test.dart...
No issues found!
```

Commande :

```bash
cd packages/map_core && dart analyze lib/map_core.dart
```

Sortie :

```text
Analyzing map_core.dart...
No issues found!
```

## 21. Audit anti-dérive

Commande :

```bash
rg -n "resolveProjectedBuildingShadowGeometry\\(|ProjectBuildingShadowPreset|ProjectElementProjectedBuildingShadowConfig|toJson|fromJson|Json|json|runtime|editor|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|build_runner|adaptiveFootprint" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart packages/map_core/lib/map_core.dart
```

Sortie :

```text
packages/map_core/lib/map_core.dart:11:export 'src/models/map_entity_editor_visual.dart';
packages/map_core/lib/map_core.dart:28:export 'src/models/visual_frame_json.dart';
packages/map_core/lib/map_core.dart:45:export 'src/operations/project_element_shadow_config_json_codec.dart';
packages/map_core/lib/map_core.dart:46:export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
packages/map_core/lib/map_core.dart:47:export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
packages/map_core/lib/map_core.dart:48:export 'src/operations/project_building_shadow_preset_json_codec.dart';
packages/map_core/lib/map_core.dart:50:export 'src/operations/project_path_pattern_preset_json_codec.dart';
packages/map_core/lib/map_core.dart:51:export 'src/operations/project_shadow_catalog_json_codec.dart';
packages/map_core/lib/map_core.dart:52:export 'src/operations/project_shadow_profile_json_codec.dart';
packages/map_core/lib/map_core.dart:53:export 'src/operations/projected_shadow_value_object_json_codecs.dart';
packages/map_core/lib/map_core.dart:54:export 'src/operations/static_shadow_family_json_codec.dart';
packages/map_core/lib/map_core.dart:55:export 'src/operations/static_shadow_footprint_config_json_codec.dart';
packages/map_core/lib/map_core.dart:56:export 'src/operations/project_json_migrations.dart';
packages/map_core/lib/map_core.dart:80:export 'src/operations/surface_atlas_json_codec.dart';
packages/map_core/lib/map_core.dart:81:export 'src/operations/surface_animation_frame_json_codec.dart';
packages/map_core/lib/map_core.dart:82:export 'src/operations/surface_animation_timeline_json_codec.dart';
packages/map_core/lib/map_core.dart:83:export 'src/operations/project_surface_animation_json_codec.dart';
packages/map_core/lib/map_core.dart:84:export 'src/operations/surface_variant_animation_ref_json_codec.dart';
packages/map_core/lib/map_core.dart:85:export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
packages/map_core/lib/map_core.dart:86:export 'src/operations/project_surface_preset_json_codec.dart';
packages/map_core/lib/map_core.dart:87:export 'src/operations/project_surface_catalog_json_codec.dart';
packages/map_core/lib/map_core.dart:98:export 'src/operations/environment_layer_content_json_codec.dart';
packages/map_core/lib/map_core.dart:99:export 'src/operations/environment_preset_json_codec.dart';
packages/map_core/lib/map_core.dart:116:export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
packages/map_core/lib/map_core.dart:128:export 'src/validation/entity_editor_visual_validation.dart';
```

Justification :

- aucun hit dans le nouveau fichier d'opération ;
- aucun hit dans le nouveau fichier de test ;
- les hits sont des exports préexistants de `map_core.dart`, dont des codecs JSON et un fichier de validation editor visual déjà présents avant ce lot ;
- le seul ajout au barrel est l'export de `projected_shadow_footprint_effective_tuning.dart`.

## 22. Ce qui n’a volontairement pas été modifié

- `packages/map_core/lib/src/models/projected_building_shadow.dart`
- `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart`
- `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_runtime/**`
- `packages/map_editor/**`
- `reports/shadows/screenshots/**`
- `reports/shadows/baselines/**`
- `/Users/karim/Desktop/selbrume/**`

## 23. Ce qui n’a volontairement pas été créé

- fichier generated ;
- codec JSON ;
- migration ;
- fixture Selbrume ;
- screenshot ;
- baseline ;
- renderer ;
- painter ;
- support officiel de props fins.

## 24. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/map_core.dart | 1 +
 1 file changed, 1 insertion(+)
```

Note : `git diff --stat` ne liste que les fichiers suivis. Les fichiers créés non suivis sont listés dans `git status final` et leur contenu complet est reproduit dans ce rapport.

## 25. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/map_core.dart
```

Note : les fichiers créés non suivis sont listés dans `git status final`.

## 26. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Interprétation : propre.

## 27. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/map_core.dart
?? packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
?? packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
?? reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md
?? reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md
```

Conformité scope :

- `packages/map_core/lib/map_core.dart` modifié uniquement pour l'export public autorisé ;
- `packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart` créé par ShadowV2-60 ;
- `packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart` créé par ShadowV2-60 ;
- `reports/shadows/v2/shadow_v2_60_projected_building_shadow_adaptive_depth_effective_tuning_resolver_v0.md` créé par ShadowV2-60 ;
- `reports/shadows/v2/shadow_v2_59_projected_building_shadow_adaptive_depth_effective_tuning_resolver_design.md` préexistant avant ShadowV2-60.

## 28. Risques / réserves

- `adaptiveDepthUnsupportedCasterKind` est présent mais non atteignable tant que `ProjectedBuildingShadowCasterKind` ne contient que `building` et `largeVolume`.
- Le futur lot d'intégration devra décider comment un result `blocked` remonte dans diagnostics ou authoring.
- L'export public est cohérent avec le barrel actuel, mais expose l'opération avant tout branchement preset/JSON.
- `thin_prop_like_2x6` reste un test de calcul canary, pas une validation produit pour props fins.

## 29. Auto-critique

- Le lot est-il bien limité à une opération pure ? Oui.
- Le resolver géométrique est-il réellement intact ? Oui, aucun changement dans `projected_building_shadow_geometry.dart`.
- JSON/persistence est-il réellement hors scope ? Oui, aucun codec ou modèle JSON modifié.
- Runtime/editor sont-ils réellement hors scope ? Oui, aucun fichier runtime/editor modifié.
- Le result blocked évite-t-il bien fallback silencieux et null ambigu ? Oui.
- L'opacité effective est-elle traitée explicitement ? Oui, dans `ProjectedShadowEffectiveFootprintTuning.opacity`.
- Les tests couvrent-ils endpoints et interpolation intermédiaire ? Oui.
- Les tests couvrent-ils les guards du Lot 56 ? Oui : wide, medium, tall, thin canary.
- Le rapport contient-il toutes les preuves ? Oui, avec commandes, outputs, diff et contenu des fichiers créés/modifiés.

## 30. Regard critique sur le prompt

Le prompt est bien borné : il permet d'ajouter l'opération pure sans précipiter l'intégration au modèle persistant ou au resolver géométrique. Le point le plus important est l'interdiction du fallback base en cas de guard absent : sans cela, l'adaptive pourrait masquer une donnée incohérente et rendre les diagnostics futurs faibles.

## 31. Prochain lot recommandé

Lot recommandé :

```text
ShadowV2-61 — Projected Building Shadow Adaptive Depth Preset Integration Design Gate
```

Objectif probable :

```text
Définir comment intégrer ProjectedShadowFootprintTuningStrategy dans ProjectBuildingShadowPreset,
sans casser les presets fixed,
sans JSON immédiat,
sans runtime/editor,
et en préparant le futur branchement du resolver géométrique.
```

Ne pas implémenter dans le Lot 60 :

- `footprintStrategy` dans `ProjectBuildingShadowPreset` ;
- JSON ;
- resolver géométrique adaptive ;
- runtime/editor ;
- diagnostics.

## 32. Code complet des fichiers créés/modifiés

### `packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart`

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'static_shadow_geometry.dart';

enum ProjectedShadowFootprintEffectiveTuningStrategyKind {
  fixed,
  adaptiveHeightDepth,
}

enum ProjectedShadowFootprintEffectiveTuningBlockReason {
  adaptiveDepthRequiresCasterKind,
  adaptiveDepthUnsupportedCasterKind,
}

final class ProjectedShadowEffectiveFootprintTuning {
  factory ProjectedShadowEffectiveFootprintTuning({
    required ProjectedShadowFootprintTuning tuning,
    required double opacity,
    required double adaptiveT,
    required ProjectedShadowFootprintEffectiveTuningStrategyKind strategyKind,
  }) {
    _validateUnitInterval(
      opacity,
      'ProjectedShadowEffectiveFootprintTuning.opacity',
    );
    _validateUnitInterval(
      adaptiveT,
      'ProjectedShadowEffectiveFootprintTuning.adaptiveT',
    );
    return ProjectedShadowEffectiveFootprintTuning._(
      tuning: tuning,
      opacity: opacity,
      adaptiveT: adaptiveT,
      strategyKind: strategyKind,
    );
  }

  const ProjectedShadowEffectiveFootprintTuning._({
    required this.tuning,
    required this.opacity,
    required this.adaptiveT,
    required this.strategyKind,
  });

  final ProjectedShadowFootprintTuning tuning;
  final double opacity;
  final double adaptiveT;
  final ProjectedShadowFootprintEffectiveTuningStrategyKind strategyKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowEffectiveFootprintTuning &&
          other.tuning == tuning &&
          other.opacity == opacity &&
          other.adaptiveT == adaptiveT &&
          other.strategyKind == strategyKind;

  @override
  int get hashCode => Object.hash(
        tuning,
        opacity,
        adaptiveT,
        strategyKind,
      );
}

sealed class ProjectedShadowFootprintEffectiveTuningResult {
  const ProjectedShadowFootprintEffectiveTuningResult();
}

final class ProjectedShadowFootprintEffectiveTuningResolved
    extends ProjectedShadowFootprintEffectiveTuningResult {
  const ProjectedShadowFootprintEffectiveTuningResolved({
    required this.value,
  });

  final ProjectedShadowEffectiveFootprintTuning value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintEffectiveTuningResolved &&
          other.value == value;

  @override
  int get hashCode => value.hashCode;
}

final class ProjectedShadowFootprintEffectiveTuningBlocked
    extends ProjectedShadowFootprintEffectiveTuningResult {
  const ProjectedShadowFootprintEffectiveTuningBlocked({
    required this.reason,
  });

  final ProjectedShadowFootprintEffectiveTuningBlockReason reason;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintEffectiveTuningBlocked &&
          other.reason == reason;

  @override
  int get hashCode => reason.hashCode;
}

ProjectedShadowFootprintEffectiveTuningResult
    resolveProjectedShadowFootprintEffectiveTuning({
  required ProjectedShadowFootprintTuningStrategy strategy,
  required StaticShadowVisualMetrics metrics,
  required double fixedOpacity,
  ProjectedBuildingShadowCasterKind? casterKind,
}) {
  return switch (strategy) {
    ProjectedShadowFootprintFixedTuning() =>
      _resolveFixedFootprintEffectiveTuning(
        strategy: strategy,
        fixedOpacity: fixedOpacity,
      ),
    ProjectedShadowFootprintAdaptiveDepthTuning() =>
      _resolveAdaptiveHeightDepthFootprintEffectiveTuning(
        strategy: strategy,
        metrics: metrics,
        casterKind: casterKind,
      ),
  };
}

ProjectedShadowFootprintEffectiveTuningResolved
    _resolveFixedFootprintEffectiveTuning({
  required ProjectedShadowFootprintFixedTuning strategy,
  required double fixedOpacity,
}) {
  _validateUnitInterval(
    fixedOpacity,
    'resolveProjectedShadowFootprintEffectiveTuning.fixedOpacity',
  );
  return ProjectedShadowFootprintEffectiveTuningResolved(
    value: ProjectedShadowEffectiveFootprintTuning(
      tuning: strategy.tuning,
      opacity: fixedOpacity,
      adaptiveT: 0,
      strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
    ),
  );
}

ProjectedShadowFootprintEffectiveTuningResult
    _resolveAdaptiveHeightDepthFootprintEffectiveTuning({
  required ProjectedShadowFootprintAdaptiveDepthTuning strategy,
  required StaticShadowVisualMetrics metrics,
  required ProjectedBuildingShadowCasterKind? casterKind,
}) {
  if (casterKind == null) {
    return const ProjectedShadowFootprintEffectiveTuningBlocked(
      reason: ProjectedShadowFootprintEffectiveTuningBlockReason
          .adaptiveDepthRequiresCasterKind,
    );
  }
  if (!_isAdaptiveCompatibleCasterKind(casterKind)) {
    return const ProjectedShadowFootprintEffectiveTuningBlocked(
      reason: ProjectedShadowFootprintEffectiveTuningBlockReason
          .adaptiveDepthUnsupportedCasterKind,
    );
  }

  final gate = strategy.gate;
  final heightGate = _clamp01(
    (metrics.visualHeight - gate.referenceHeight) /
        (gate.targetHeight - gate.referenceHeight),
  );
  final ratioGate = _clamp01(
    (metrics.visualHeight / metrics.visualWidth - gate.referenceRatio) /
        (gate.targetRatio - gate.referenceRatio),
  );
  final adaptiveT = heightGate * ratioGate;
  final base = strategy.base;
  final target = strategy.target;

  return ProjectedShadowFootprintEffectiveTuningResolved(
    value: ProjectedShadowEffectiveFootprintTuning(
      tuning: ProjectedShadowFootprintTuning(
        attachYRatio: _lerp(
          base.attachYRatio,
          target.attachYRatio,
          adaptiveT,
        ),
        frontWidthRatio: _lerp(
          base.frontWidthRatio,
          target.frontWidthRatio,
          adaptiveT,
        ),
        rearWidthRatio: _lerp(
          base.rearWidthRatio,
          target.rearWidthRatio,
          adaptiveT,
        ),
        depthRatio: _lerp(
          base.depthRatio,
          target.depthRatio,
          adaptiveT,
        ),
        skewXRatio: _lerp(
          base.skewXRatio,
          target.skewXRatio,
          adaptiveT,
        ),
      ),
      opacity: _lerp(strategy.baseOpacity, strategy.targetOpacity, adaptiveT),
      adaptiveT: adaptiveT,
      strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind
          .adaptiveHeightDepth,
    ),
  );
}

bool _isAdaptiveCompatibleCasterKind(
  ProjectedBuildingShadowCasterKind casterKind,
) {
  return switch (casterKind) {
    ProjectedBuildingShadowCasterKind.building => true,
    ProjectedBuildingShadowCasterKind.largeVolume => true,
  };
}

double _clamp01(double value) {
  if (value < 0) {
    return 0;
  }
  if (value > 1) {
    return 1;
  }
  return value;
}

double _lerp(double start, double end, double t) {
  return start + (end - start) * t;
}

void _validateUnitInterval(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}
```

### `packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('resolveProjectedShadowFootprintEffectiveTuning fixed', () {
    test('resolves fixed tuning with fixed opacity', () {
      final tuning = _baseTuning();

      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: ProjectedShadowFootprintFixedTuning(tuning: tuning),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
      );

      final value = _expectResolved(result);
      expect(value.tuning, tuning);
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
    });

    test('ignores casterKind for fixed tuning', () {
      final tuning = _baseTuning();

      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: ProjectedShadowFootprintFixedTuning(tuning: tuning),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      final value = _expectResolved(result);
      expect(value.tuning, tuning);
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
    });

    test('rejects invalid fixedOpacity below 0', () {
      expect(
        () => resolveProjectedShadowFootprintEffectiveTuning(
          strategy: ProjectedShadowFootprintFixedTuning(tuning: _baseTuning()),
          metrics: _tallShopMetrics(),
          fixedOpacity: -0.01,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects invalid fixedOpacity above 1', () {
      expect(
        () => resolveProjectedShadowFootprintEffectiveTuning(
          strategy: ProjectedShadowFootprintFixedTuning(tuning: _baseTuning()),
          metrics: _tallShopMetrics(),
          fixedOpacity: 1.01,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('resolveProjectedShadowFootprintEffectiveTuning adaptive', () {
    test('blocks adaptive depth without casterKind', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
      );

      final blocked = _expectBlocked(result);
      expect(
        blocked.reason,
        ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthRequiresCasterKind,
      );
    });

    test('resolves adaptive depth for building caster', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _targetTuning());
      expect(value.opacity, 0.22);
      expect(value.adaptiveT, 1);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.adaptiveHeightDepth,
      );
    });

    test('resolves adaptive depth for largeVolume caster', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: _tallShopMetrics(),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _targetTuning());
      expect(value.opacity, 0.22);
      expect(value.adaptiveT, 1);
      expect(
        value.strategyKind,
        ProjectedShadowFootprintEffectiveTuningStrategyKind.adaptiveHeightDepth,
      );
    });

    test('keeps wide_house_6x5 at base tuning', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 52,
          top: 80,
          visualWidth: 96,
          visualHeight: 80,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _baseTuning());
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
    });

    test('keeps medium_shop_5x6 at base tuning', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 60,
          top: 64,
          visualWidth: 80,
          visualHeight: 96,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      expect(value.tuning, _baseTuning());
      expect(value.opacity, 0.24);
      expect(value.adaptiveT, 0);
    });

    test('partially adapts thin_prop_like_2x6 canary', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 84,
          top: 64,
          visualWidth: 32,
          visualHeight: 96,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      _expectTuningClose(
        value.tuning,
        attachYRatio: 0.81,
        frontWidthRatio: 1.30,
        rearWidthRatio: 1.445,
        depthRatio: 0.34,
        skewXRatio: 0.08,
      );
      expect(value.opacity, closeTo(0.23, 0.000001));
      expect(value.adaptiveT, closeTo(0.5, 0.000001));
    });

    test('interpolates both gates multiplicatively', () {
      final result = resolveProjectedShadowFootprintEffectiveTuning(
        strategy: _adaptiveStrategy(),
        metrics: StaticShadowVisualMetrics(
          left: 68,
          top: 64,
          visualWidth: 64,
          visualHeight: 96,
        ),
        fixedOpacity: 0.24,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      final value = _expectResolved(result);
      _expectTuningClose(
        value.tuning,
        attachYRatio: 0.815,
        frontWidthRatio: 1.30,
        rearWidthRatio: 1.4325,
        depthRatio: 0.30,
        skewXRatio: 0.08,
      );
      expect(value.opacity, closeTo(0.235, 0.000001));
      expect(value.adaptiveT, closeTo(0.25, 0.000001));
    });
  });

  group('ProjectedShadowEffectiveFootprintTuning', () {
    test('equality includes all fields', () {
      final first = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.24,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final same = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.24,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final changedTuning = ProjectedShadowEffectiveFootprintTuning(
        tuning: _targetTuning(),
        opacity: 0.24,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final changedOpacity = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.25,
        adaptiveT: 0,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
      );
      final changedAdaptiveT = ProjectedShadowEffectiveFootprintTuning(
        tuning: _baseTuning(),
        opacity: 0.24,
        adaptiveT: 0.5,
        strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind
            .adaptiveHeightDepth,
      );

      expect(first, same);
      expect(first, isNot(changedTuning));
      expect(first, isNot(changedOpacity));
      expect(first, isNot(changedAdaptiveT));
      expect(first.hashCode, same.hashCode);
    });

    test('rejects opacity below 0', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: -0.01,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects opacity above 1', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 1.01,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects adaptiveT below 0', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: -0.01,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects adaptiveT above 1', () {
      expect(
        () => ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: 1.01,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowFootprintEffectiveTuningResult', () {
    test('resolved equality includes value', () {
      final first = ProjectedShadowFootprintEffectiveTuningResolved(
        value: ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
      );
      final same = ProjectedShadowFootprintEffectiveTuningResolved(
        value: ProjectedShadowEffectiveFootprintTuning(
          tuning: _baseTuning(),
          opacity: 0.24,
          adaptiveT: 0,
          strategyKind:
              ProjectedShadowFootprintEffectiveTuningStrategyKind.fixed,
        ),
      );
      final changed = ProjectedShadowFootprintEffectiveTuningResolved(
        value: ProjectedShadowEffectiveFootprintTuning(
          tuning: _targetTuning(),
          opacity: 0.22,
          adaptiveT: 1,
          strategyKind: ProjectedShadowFootprintEffectiveTuningStrategyKind
              .adaptiveHeightDepth,
        ),
      );

      expect(first, same);
      expect(first, isNot(changed));
      expect(first.hashCode, same.hashCode);
    });

    test('blocked equality includes reason', () {
      final first = ProjectedShadowFootprintEffectiveTuningBlocked(
        reason: ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthRequiresCasterKind,
      );
      final same = ProjectedShadowFootprintEffectiveTuningBlocked(
        reason: ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthRequiresCasterKind,
      );
      final changed = ProjectedShadowFootprintEffectiveTuningBlocked(
        reason: ProjectedShadowFootprintEffectiveTuningBlockReason
            .adaptiveDepthUnsupportedCasterKind,
      );

      expect(first, same);
      expect(first, isNot(changed));
      expect(first.hashCode, same.hashCode);
    });
  });
}

ProjectedShadowEffectiveFootprintTuning _expectResolved(
  ProjectedShadowFootprintEffectiveTuningResult result,
) {
  expect(result, isA<ProjectedShadowFootprintEffectiveTuningResolved>());
  return (result as ProjectedShadowFootprintEffectiveTuningResolved).value;
}

ProjectedShadowFootprintEffectiveTuningBlocked _expectBlocked(
  ProjectedShadowFootprintEffectiveTuningResult result,
) {
  expect(result, isA<ProjectedShadowFootprintEffectiveTuningBlocked>());
  return result as ProjectedShadowFootprintEffectiveTuningBlocked;
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy() {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: _baseTuning(),
    target: _targetTuning(),
    gate: ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: 0.24,
    targetOpacity: 0.22,
  );
}

ProjectedShadowFootprintTuning _baseTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.82,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _targetTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.80,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
  );
}

StaticShadowVisualMetrics _tallShopMetrics() {
  return StaticShadowVisualMetrics(
    left: 68,
    top: 48,
    visualWidth: 64,
    visualHeight: 112,
  );
}

void _expectTuningClose(
  ProjectedShadowFootprintTuning tuning, {
  required double attachYRatio,
  required double frontWidthRatio,
  required double rearWidthRatio,
  required double depthRatio,
  required double skewXRatio,
}) {
  expect(tuning.attachYRatio, closeTo(attachYRatio, 0.000001));
  expect(tuning.frontWidthRatio, closeTo(frontWidthRatio, 0.000001));
  expect(tuning.rearWidthRatio, closeTo(rearWidthRatio, 0.000001));
  expect(tuning.depthRatio, closeTo(depthRatio, 0.000001));
  expect(tuning.skewXRatio, closeTo(skewXRatio, 0.000001));
}
```

### `packages/map_core/lib/map_core.dart`

```dart
library map_core;

export 'src/models/enums.dart';
export 'src/models/geometry.dart';
export 'src/models/tileset.dart';
export 'src/models/tileset_transparent_color.dart';
export 'src/models/map_data.dart';
export 'src/models/element_collision_profile.dart';
export 'src/models/environment.dart';
export 'src/models/map_entity_payloads.dart';
export 'src/models/map_entity_editor_visual.dart';
export 'src/models/map_gameplay_zone_payloads.dart';
export 'src/models/map_layer.dart';
export 'src/models/map_metadata.dart';
export 'src/models/path_center_pattern.dart';
export 'src/models/project_path_pattern_preset.dart';
export 'src/models/project_manifest.dart';
export 'src/models/save_data.dart';
export 'src/models/game_state.dart';
export 'src/models/pokemon_move.dart';
export 'src/models/pokemon_move_accuracy.dart';
export 'src/models/pokemon_move_effect.dart';
export 'src/models/script_asset.dart';
export 'src/models/script_conditions.dart';
export 'src/models/map_event_definition.dart';
export 'src/models/project_trainer.dart';
export 'src/models/scenario_asset.dart';
export 'src/models/visual_frame_json.dart';
export 'src/models/shadow.dart';
export 'src/models/shadow_catalog.dart';
export 'src/models/projected_building_shadow.dart';
export 'src/models/surface.dart';
export 'src/models/surface_catalog.dart';
export 'src/operations/map_resize.dart';
export 'src/operations/map_paint.dart';
export 'src/operations/map_collision.dart';
export 'src/operations/map_path.dart';
export 'src/operations/map_terrain.dart';
export 'src/operations/map_terrain_autotile.dart';
export 'src/operations/terrain_preset_subtile_for_map_cell.dart';
export 'src/operations/terrain_preset_variant_pick.dart';
export 'src/operations/path_center_pattern_resolver.dart';
export 'src/operations/path_pattern_visual_resolution.dart';
export 'src/operations/project_path_preset_center_pattern_adapter.dart';
export 'src/operations/project_element_shadow_config_json_codec.dart';
export 'src/operations/project_element_projected_building_shadow_config_json_codec.dart';
export 'src/operations/project_building_shadow_preset_catalog_json_codec.dart';
export 'src/operations/project_building_shadow_preset_json_codec.dart';
export 'src/operations/project_manifest_shadow_catalog_operations.dart';
export 'src/operations/project_path_pattern_preset_json_codec.dart';
export 'src/operations/project_shadow_catalog_json_codec.dart';
export 'src/operations/project_shadow_profile_json_codec.dart';
export 'src/operations/projected_shadow_value_object_json_codecs.dart';
export 'src/operations/static_shadow_family_json_codec.dart';
export 'src/operations/static_shadow_footprint_config_json_codec.dart';
export 'src/operations/project_json_migrations.dart';
export 'src/operations/default_shadow_profiles.dart';
export 'src/operations/tile_visual_frame_timeline.dart';
export 'src/operations/tile_visual_frame_vertical_atlas.dart';
export 'src/operations/path_variant_vertical_atlas_mapping.dart';
export 'src/operations/path_preset_vertical_atlas_builder.dart';
export 'src/operations/terrain_path_variant_vertical_atlas_layout.dart';
export 'src/operations/standard_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_water_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_lava_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_ice_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_tall_grass_path_preset_vertical_atlas_builder.dart';
export 'src/operations/standard_surface_preset_builder.dart';
export 'src/operations/surface_catalog_diagnostics.dart';
export 'src/operations/surface_catalog_authoring_diagnostics.dart';
export 'src/operations/surface_catalog_diagnostics_summary.dart';
export 'src/operations/surface_catalog_diagnostics_presentation.dart';
export 'src/operations/static_shadow_geometry.dart';
export 'src/operations/static_shadow_family_projection.dart';
export 'src/operations/static_shadow_projection_geometry.dart';
export 'src/operations/static_shadow_contact_ledge_geometry.dart';
export 'src/operations/projected_building_shadow_geometry.dart';
export 'src/operations/projected_shadow_footprint_effective_tuning.dart';
export 'src/operations/element_auto_shadow_policy.dart';
export 'src/operations/surface_atlas_json_codec.dart';
export 'src/operations/surface_animation_frame_json_codec.dart';
export 'src/operations/surface_animation_timeline_json_codec.dart';
export 'src/operations/project_surface_animation_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_json_codec.dart';
export 'src/operations/surface_variant_animation_ref_set_json_codec.dart';
export 'src/operations/project_surface_preset_json_codec.dart';
export 'src/operations/project_surface_catalog_json_codec.dart';
export 'src/operations/project_manifest_surface_catalog_operations.dart';
export 'src/operations/project_manifest_path_pattern_preset_operations.dart';
export 'src/operations/surface_studio_read_model.dart';
export 'src/operations/tall_grass_authoring_view.dart';
export 'src/operations/path_animation_rules.dart';
export 'src/operations/element_collision_mask_codec.dart';
export 'src/operations/element_collision_profile_normalizer.dart';
export 'src/collision/pixel_rect.dart';
export 'src/collision/player_collision_conventions_v1.dart';
export 'src/operations/map_layers.dart';
export 'src/operations/environment_layer_content_json_codec.dart';
export 'src/operations/environment_preset_json_codec.dart';
export 'src/operations/project_manifest_environment_preset_operations.dart';
export 'src/operations/environment_preset_diagnostics.dart';
export 'src/operations/environment_layer_usage_diagnostics.dart';
export 'src/operations/environment_authoring_diagnostics.dart';
export 'src/operations/shadow_authoring_diagnostics.dart';
export 'src/operations/projected_building_shadow_diagnostics.dart';
export 'src/operations/shadow_config_resolver.dart';
export 'src/operations/surface_layer_placements.dart';
export 'src/operations/surface_to_gameplay_zone_generation_assessment.dart';
export 'src/operations/surface_to_gameplay_zone_generation_plan.dart';
export 'src/operations/surface_variant_role_resolver.dart';
export 'src/operations/map_connections.dart';
export 'src/operations/map_entities.dart';
export 'src/operations/map_events.dart';
export 'src/operations/map_placed_elements.dart';
export 'src/operations/map_placed_element_animation.dart';
export 'src/operations/map_placed_element_shadow_override_json_codec.dart';
export 'src/operations/map_entity_collision_footprint.dart';
export 'src/operations/map_triggers.dart';
export 'src/operations/map_warps.dart';
export 'src/operations/map_gameplay_zones.dart';
export 'src/operations/map_map_metadata.dart';
export 'src/operations/game_state_persistence.dart';
export 'src/operations/tileset_library_tree.dart';
export 'src/operations/dialogue_library_tree.dart';
export 'src/operations/project_dialogue_refs.dart';
export 'src/validation/validators.dart';
export 'src/validation/dialogue_validation.dart';
export 'src/validation/entity_editor_visual_validation.dart';
export 'src/exceptions/map_exceptions.dart';
```

Checklist finale :

- [x] AGENTS.md lu
- [x] Aucun git write effectué
- [x] Aucun fichier runtime modifié
- [x] Aucun fichier editor modifié
- [x] Aucun resolver géométrique modifié
- [x] Aucun ProjectBuildingShadowPreset modifié
- [x] Aucun JSON/codec modifié
- [x] Aucun generated créé
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] resolveProjectedShadowFootprintEffectiveTuning ajouté
- [x] Result union-like ajouté
- [x] Effective tuning payload ajouté
- [x] Block reasons ajoutés
- [x] Strategy kind ajouté
- [x] Fixed behavior testé
- [x] Adaptive missing caster blocked testé
- [x] Adaptive building testé
- [x] Adaptive largeVolume testé
- [x] wide_house guard testé
- [x] medium_shop guard testé
- [x] tall_shop endpoint testé
- [x] thin_prop_like canary calculé/testé
- [x] Interpolation intermédiaire testée
- [x] Opacity effective testée
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] dart test test/shadow_v2 passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
