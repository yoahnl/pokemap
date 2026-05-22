# ShadowV2-64 — Projected Building Shadow Caster Kind Config Model V0

## 1. Résumé exécutif

ShadowV2-64 ajoute `casterKind` à `ProjectElementProjectedBuildingShadowConfig` comme champ modèle pur optionnel.

Le champ :

- est de type `ProjectedBuildingShadowCasterKind?` ;
- vaut `null` par défaut ;
- stocke `building` et `largeVolume` ;
- reste conservé même quand la config est disabled ;
- est inclus dans `operator ==` et `hashCode` ;
- n'ajoute aucune validation liée au preset, au catalogue, au JSON, aux diagnostics ou au resolver.

Le lot est resté limité à `map_core` modèle pur et au test ciblé associé.

## 2. Objectif du lot

Objectif exact exécuté :

```text
Ajouter casterKind optionnel à ProjectElementProjectedBuildingShadowConfig,
avec tests modèle/equality/hashCode,
sans JSON,
sans diagnostics,
sans resolver,
sans runtime,
sans editor,
sans renderer/painter,
sans Selbrume,
sans screenshot,
sans baseline.
```

## 3. Rappel ShadowV2-63

Le Lot 63 a recommandé le guard dans `ProjectElementProjectedBuildingShadowConfig`.

Décision appliquée au Lot 64 :

- `casterKind: ProjectedBuildingShadowCasterKind?` sur la config ShadowV2 élément ;
- champ optionnel en V0 ;
- valeur par défaut `null` ;
- aucune inférence depuis `categoryId` ou `presetKind` ;
- aucun champ sur `MapPlacedElement` ;
- pas de JSON ;
- pas de diagnostics ;
- pas de branchement resolver.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Interprétation :

- fichier préexistant hors scope avant ShadowV2-64 : aucun signalé par `git status` ;
- modification préexistante avant ShadowV2-64 : aucune signalée ;
- fichier non suivi préexistant avant ShadowV2-64 : aucun signalé.

## 5. Lecture AGENTS.md et méthode suivie

Commandes :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject-worktree/AGENTS.md
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Preuve de lecture `AGENTS.md` :

```text
PokeMap is a Dart/Flutter monorepo for a Pokemon-like no-code fangame editor/runtime/battle stack.
Keep work practical: small scoped changes, package boundaries, explicit roadmap lots, tests, and evidence.
Never run Git write operations unless the user explicitly asks.
Run commands package by package.
Reports under reports/ are tracked engineering artifacts.
```

Méthode réellement suivie :

- Pass 1 — Audit config modèle / tests existants : exécuté avant modification.
- Pass 2 — Tests RED : nouveau test créé puis lancé avant le patch modèle.
- Pass 3 — Implémentation modèle V0 : ajout minimal du champ `casterKind`.
- Pass 4 — Tests / analyze / evidence : tests ciblés, régressions, groupe `shadow_v2`, analyze, audit anti-dérive, git final.

Skills utilisés :

- `using-superpowers` pour respecter le workflow de démarrage demandé par `AGENTS.md` ;
- `karpathy-guidelines` pour maintenir le changement chirurgical ;
- `test-driven-development` pour le cycle RED/GREEN ;
- `dart-add-unit-test` pour le style `package:test` ;
- `dart-run-static-analysis` pour l'analyse ciblée ;
- `verification-before-completion` avant toute conclusion.

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés par ShadowV2-64 :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
reports/shadows/v2/shadow_v2_64_projected_building_shadow_caster_kind_config_model_v0.md
```

Fichiers modifiés par ShadowV2-64 :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Fichiers supprimés par ShadowV2-64 :

```text
Aucun
```

Fichiers hors scope déjà présents avant ShadowV2-64 :

```text
Aucun d'après le git status initial.
```

## 7. Audit initial

Commandes d'audit exécutées avant modification :

```bash
rg -n "ProjectElementProjectedBuildingShadowConfig|enabled|presetId|anchor|localOffset|casterKind|ProjectedBuildingShadowCasterKind|building|largeVolume|operator ==|hashCode|projectedBuildingShadow" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2

rg -n "ProjectElementProjectedBuildingShadowConfig JSON|encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig|presetId|anchor|localOffset|enabled|casterKind|toJson|fromJson" packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart

rg -n "resolveProjectedShadowFootprintEffectiveTuning|ProjectedBuildingShadowCasterKind|adaptiveDepthRequiresCasterKind|adaptiveDepthUnsupportedCasterKind|casterKind" packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart

rg -n "diagnoseProjectedBuildingShadows|adaptivePresetRequiresCasterKind|casterKind|ProjectedBuildingShadowDiagnosticKind" packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart packages/map_core/test/shadow_v2/projected_building_shadow_diagnostics_test.dart
```

Constats :

- `ProjectedBuildingShadowCasterKind` existe déjà avec `building` et `largeVolume`.
- `ProjectElementProjectedBuildingShadowConfig` stockait `enabled`, `presetId`, `anchor`, `localOffset`.
- `ProjectElementProjectedBuildingShadowConfig` validait déjà `presetId` non blank.
- Le codec JSON de config encode/décode uniquement `enabled`, `presetId`, `anchor`, `localOffset`.
- `resolveProjectedShadowFootprintEffectiveTuning(...)` existe déjà et accepte `ProjectedBuildingShadowCasterKind? casterKind`.
- Les diagnostics actuels ne contiennent pas encore de diagnostic adaptive/caster kind.

## 8. Champ casterKind ajouté

Ajout modèle :

```dart
ProjectedBuildingShadowCasterKind? casterKind
```

Le champ est passé dans le constructeur factory, stocké dans le constructeur privé, exposé en final immutable, et inclus dans `Object.hash`.

## 9. Comportement default null

Le paramètre est optionnel et nullable. Un appel existant sans `casterKind` produit :

```text
config.casterKind == null
```

Les tests existants restent compatibles sans modification.

## 10. Comportement building / largeVolume

Le test ciblé couvre :

```text
casterKind: ProjectedBuildingShadowCasterKind.building
casterKind: ProjectedBuildingShadowCasterKind.largeVolume
```

Les deux valeurs sont stockées telles quelles.

## 11. Disabled config + casterKind

Le constructeur ne rejette pas `casterKind` quand `enabled == false`.

Raison :

```text
Une config disabled peut conserver une intention authoring.
La règle adaptive actif + casterKind requis sera portée plus tard par diagnostics / resolver integration.
```

## 12. Equality / hashCode

`operator ==` inclut maintenant :

```text
other.casterKind == casterKind
```

`hashCode` inclut maintenant :

```text
casterKind
```

Les tests ciblés couvrent `null`, `building`, `largeVolume`, égalité identique et différence de valeur.

## 13. Ce qui n’a volontairement pas été branché

Non branché volontairement :

- JSON / codecs ;
- diagnostics ;
- `resolveProjectedBuildingShadowGeometry(...)` ;
- `resolveProjectedShadowFootprintEffectiveTuning(...)` ;
- `ProjectBuildingShadowPreset` ;
- `ProjectElementEntry` ;
- `MapPlacedElement` ;
- runtime ;
- editor ;
- renderer / painter ;
- Selbrume ;
- screenshots / baselines ;
- generated files.

## 14. Résultats tests ciblés

Commande RED :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
```

Sortie RED complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
00:00 +0 -1: loading test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart [E]
  Failed to load "test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart":
  test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart:9:21: Error: The getter 'casterKind' isn't defined for the type 'ProjectElementProjectedBuildingShadowConfig'.
   - 'ProjectElementProjectedBuildingShadowConfig' is from 'package:map_core/src/models/projected_building_shadow.dart' ('lib/src/models/projected_building_shadow.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'casterKind'.
        expect(config.casterKind, isNull);
                      ^^^^^^^^^^
  test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart:17:21: Error: The getter 'casterKind' isn't defined for the type 'ProjectElementProjectedBuildingShadowConfig'.
   - 'ProjectElementProjectedBuildingShadowConfig' is from 'package:map_core/src/models/projected_building_shadow.dart' ('lib/src/models/projected_building_shadow.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'casterKind'.
        expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
                      ^^^^^^^^^^
  test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart:25:21: Error: The getter 'casterKind' isn't defined for the type 'ProjectElementProjectedBuildingShadowConfig'.
   - 'ProjectElementProjectedBuildingShadowConfig' is from 'package:map_core/src/models/projected_building_shadow.dart' ('lib/src/models/projected_building_shadow.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'casterKind'.
        expect(config.casterKind, ProjectedBuildingShadowCasterKind.largeVolume);
                      ^^^^^^^^^^
  test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart:35:21: Error: The getter 'casterKind' isn't defined for the type 'ProjectElementProjectedBuildingShadowConfig'.
   - 'ProjectElementProjectedBuildingShadowConfig' is from 'package:map_core/src/models/projected_building_shadow.dart' ('lib/src/models/projected_building_shadow.dart').
  Try correcting the name to the name of an existing getter, or defining a getter or field named 'casterKind'.
        expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
                      ^^^^^^^^^^
  test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart:94:5: Error: No named parameter with the name 'casterKind'.
      casterKind: casterKind,
      ^^^^^^^^^^
  lib/src/models/projected_building_shadow.dart:643:11: Context: Found this candidate, but the arguments don't match.
    factory ProjectElementProjectedBuildingShadowConfig({
            ^

To run this test again: dart test test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart -p vm --plain-name 'loading test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart'
00:00 +0 -1: Some tests failed.
```

Commande GREEN :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
```

Sortie GREEN complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
00:00 +0: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null
00:00 +1: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null
00:00 +1: ProjectElementProjectedBuildingShadowConfig casterKind stores building casterKind
00:00 +2: ProjectElementProjectedBuildingShadowConfig casterKind stores building casterKind
00:00 +2: ProjectElementProjectedBuildingShadowConfig casterKind stores largeVolume casterKind
00:00 +3: ProjectElementProjectedBuildingShadowConfig casterKind stores largeVolume casterKind
00:00 +3: ProjectElementProjectedBuildingShadowConfig casterKind disabled config preserves casterKind
00:00 +4: ProjectElementProjectedBuildingShadowConfig casterKind disabled config preserves casterKind
00:00 +4: ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind
00:00 +5: ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind
00:00 +5: ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind
00:00 +6: ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind
00:00 +6: ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind
00:00 +7: ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind
00:00 +7: All tests passed!
```

## 15. Résultats régressions utiles

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_element_config_test.dart
```

Sortie complète :

```text
00:01 +0: loading test/shadow_v2/projected_building_shadow_element_config_test.dart
00:01 +0: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values
00:01 +1: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values
00:01 +1: ProjectElementProjectedBuildingShadowConfig accepts enabled false and preserves preset intent
00:01 +2: ProjectElementProjectedBuildingShadowConfig accepts enabled false and preserves preset intent
00:01 +2: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids
00:01 +3: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids
00:01 +3: ProjectElementProjectedBuildingShadowConfig stores spaced preset ids unchanged
00:01 +4: ProjectElementProjectedBuildingShadowConfig stores spaced preset ids unchanged
00:01 +4: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets
00:01 +5: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets
00:01 +5: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode
00:01 +6: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode
00:01 +6: ProjectElementProjectedBuildingShadowConfig value equality includes enabled
00:01 +7: ProjectElementProjectedBuildingShadowConfig value equality includes enabled
00:01 +7: ProjectElementProjectedBuildingShadowConfig value equality includes presetId
00:01 +8: ProjectElementProjectedBuildingShadowConfig value equality includes presetId
00:01 +8: ProjectElementProjectedBuildingShadowConfig value equality includes anchor
00:01 +9: ProjectElementProjectedBuildingShadowConfig value equality includes anchor
00:01 +9: ProjectElementProjectedBuildingShadowConfig value equality includes localOffset
00:01 +10: ProjectElementProjectedBuildingShadowConfig value equality includes localOffset
00:01 +10: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Sortie complète :

```text
00:00 +0: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:01 +0: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:01 +1: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:01 +1: ProjectElementProjectedBuildingShadowConfig JSON codec encodes enabled false while keeping explicit preset and placement
00:01 +2: ProjectElementProjectedBuildingShadowConfig JSON codec encodes enabled false while keeping explicit preset and placement
00:01 +2: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true
00:01 +3: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true
00:01 +3: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled false
00:01 +4: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled false
00:01 +4: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config instances through canonical JSON
00:01 +5: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config instances through canonical JSON
00:01 +5: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips JSON without re-emitting unknown keys
00:01 +6: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips JSON without re-emitting unknown keys
00:01 +6: ProjectElementProjectedBuildingShadowConfig JSON codec rejects missing required fields
00:01 +7: ProjectElementProjectedBuildingShadowConfig JSON codec rejects missing required fields
00:01 +7: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid field types
00:01 +8: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid field types
00:01 +8: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid values delegated to model and value objects
00:01 +9: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid values delegated to model and value objects
00:01 +9: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
```

Sortie complète :

```text
00:01 +0: loading test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
00:01 +0: ShadowV2 manifest and element persistence integration ProjectManifest without projectedBuildingShadowCatalog decodes an empty catalog and omits the root on toJson
00:01 +1: ShadowV2 manifest and element persistence integration ProjectManifest without projectedBuildingShadowCatalog decodes an empty catalog and omits the root on toJson
00:01 +1: ShadowV2 manifest and element persistence integration ProjectManifest with projectedBuildingShadowCatalog null decodes empty and omits the root on toJson
00:01 +2: ShadowV2 manifest and element persistence integration ProjectManifest with projectedBuildingShadowCatalog null decodes empty and omits the root on toJson
00:01 +2: ShadowV2 manifest and element persistence integration ProjectManifest rejects an object projectedBuildingShadowCatalog without presets
00:01 +3: ShadowV2 manifest and element persistence integration ProjectManifest rejects an object projectedBuildingShadowCatalog without presets
00:01 +3: ShadowV2 manifest and element persistence integration ProjectManifest with empty projectedBuildingShadowCatalog presets decodes empty and omits the root on toJson
00:01 +4: ShadowV2 manifest and element persistence integration ProjectManifest with empty projectedBuildingShadowCatalog presets decodes empty and omits the root on toJson
00:01 +4: ShadowV2 manifest and element persistence integration ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root
00:01 +5: ShadowV2 manifest and element persistence integration ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root
00:01 +5: ShadowV2 manifest and element persistence integration ProjectElementEntry without projectedBuildingShadow decodes null and omits the field on toJson
00:01 +6: ShadowV2 manifest and element persistence integration ProjectElementEntry without projectedBuildingShadow decodes null and omits the field on toJson
00:01 +6: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow null decodes null and omits the field on toJson
00:01 +7: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow null decodes null and omits the field on toJson
00:01 +7: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow round-trips and emits the field
00:01 +8: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow round-trips and emits the field
00:01 +8: ShadowV2 manifest and element persistence integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together
00:01 +9: ShadowV2 manifest and element persistence integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together
00:01 +9: ShadowV2 manifest and element persistence integration existing V1-only manifest round-trip stays free of projected building shadow output
00:01 +10: ShadowV2 manifest and element persistence integration existing V1-only manifest round-trip stays free of projected building shadow output
00:01 +10: ShadowV2 manifest and element persistence integration copyWith can replace manifest catalog and element config
00:01 +11: ShadowV2 manifest and element persistence integration copyWith can replace manifest catalog and element config
00:01 +11: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Sortie complète :

```text
00:01 +0: loading test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
00:01 +0: resolveProjectedShadowFootprintEffectiveTuning fixed resolves fixed tuning with fixed opacity
00:01 +1: resolveProjectedShadowFootprintEffectiveTuning fixed resolves fixed tuning with fixed opacity
00:01 +1: resolveProjectedShadowFootprintEffectiveTuning fixed ignores casterKind for fixed tuning
00:01 +2: resolveProjectedShadowFootprintEffectiveTuning fixed ignores casterKind for fixed tuning
00:01 +2: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity below 0
00:01 +3: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity below 0
00:01 +3: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity above 1
00:01 +4: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity above 1
00:01 +4: resolveProjectedShadowFootprintEffectiveTuning adaptive blocks adaptive depth without casterKind
00:01 +5: resolveProjectedShadowFootprintEffectiveTuning adaptive blocks adaptive depth without casterKind
00:01 +5: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for building caster
00:01 +6: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for building caster
00:01 +6: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for largeVolume caster
00:01 +7: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for largeVolume caster
00:01 +7: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps wide_house_6x5 at base tuning
00:01 +8: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps wide_house_6x5 at base tuning
00:01 +8: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps medium_shop_5x6 at base tuning
00:01 +9: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps medium_shop_5x6 at base tuning
00:01 +9: resolveProjectedShadowFootprintEffectiveTuning adaptive partially adapts thin_prop_like_2x6 canary
00:01 +10: resolveProjectedShadowFootprintEffectiveTuning adaptive partially adapts thin_prop_like_2x6 canary
00:01 +10: resolveProjectedShadowFootprintEffectiveTuning adaptive interpolates both gates multiplicatively
00:01 +11: resolveProjectedShadowFootprintEffectiveTuning adaptive interpolates both gates multiplicatively
00:01 +11: ProjectedShadowEffectiveFootprintTuning equality includes all fields
00:01 +12: ProjectedShadowEffectiveFootprintTuning equality includes all fields
00:01 +12: ProjectedShadowEffectiveFootprintTuning rejects opacity below 0
00:01 +13: ProjectedShadowEffectiveFootprintTuning rejects opacity below 0
00:01 +13: ProjectedShadowEffectiveFootprintTuning rejects opacity above 1
00:01 +14: ProjectedShadowEffectiveFootprintTuning rejects opacity above 1
00:01 +14: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT below 0
00:01 +15: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT below 0
00:01 +15: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT above 1
00:01 +16: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT above 1
00:01 +16: ProjectedShadowFootprintEffectiveTuningResult resolved equality includes value
00:01 +17: ProjectedShadowFootprintEffectiveTuningResult resolved equality includes value
00:01 +17: ProjectedShadowFootprintEffectiveTuningResult blocked equality includes reason
00:01 +18: ProjectedShadowFootprintEffectiveTuningResult blocked equality includes reason
00:01 +18: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
```

Sortie complète :

```text
00:01 +0: loading test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
00:01 +0: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth
00:01 +1: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth
00:01 +1: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null
00:01 +2: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null
00:01 +2: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy
00:01 +3: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy
00:01 +3: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint
00:01 +4: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint
00:01 +4: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy
00:01 +5: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy
00:01 +5: ProjectBuildingShadowPreset footprintStrategy footprint rejects missing footprint and missing footprintStrategy
00:01 +6: ProjectBuildingShadowPreset footprintStrategy footprint rejects missing footprint and missing footprintStrategy
00:01 +6: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint
00:01 +7: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint
00:01 +7: ProjectBuildingShadowPreset footprintStrategy footprint adaptive rejects non-null footprint
00:01 +8: ProjectBuildingShadowPreset footprintStrategy footprint adaptive rejects non-null footprint
00:01 +8: ProjectBuildingShadowPreset footprintStrategy footprint rejects fixed footprintStrategy in V0
00:01 +9: ProjectBuildingShadowPreset footprintStrategy footprint rejects fixed footprintStrategy in V0
00:01 +9: ProjectBuildingShadowPreset footprintStrategy equality includes footprintStrategy
00:01 +10: ProjectBuildingShadowPreset footprintStrategy equality includes footprintStrategy
00:01 +10: ProjectBuildingShadowPreset footprintStrategy hashCode includes footprintStrategy
00:01 +11: ProjectBuildingShadowPreset footprintStrategy hashCode includes footprintStrategy
00:01 +11: All tests passed!
```

## 16. Résultat dart test test/shadow_v2

Commande obligatoire :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Sortie compacte utile de la commande obligatoire :

```text
00:00 +228: All tests passed!
```

Commande de preuve lisible complémentaire :

```bash
cd packages/map_core && dart test test/shadow_v2 --reporter expanded --no-color -j 1
```

Sortie complète de la preuve complémentaire :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
00:00 +0: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning uses footprint V0 defaults
00:00 +1: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning uses value equality and matching hashCode
00:00 +2: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid attachYRatio values
00:00 +3: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid frontWidthRatio values
00:00 +4: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid rearWidthRatio values
00:00 +5: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid depthRatio values
00:00 +6: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid skewXRatio values
00:00 +7: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode defaults to directional geometry mode
00:00 +8: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts directional without footprint
00:00 +9: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects directional with footprint
00:00 +10: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts footprint with footprint tuning
00:00 +11: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects footprint without footprint tuning
00:00 +12: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode equality and hashCode include geometryMode and footprint
00:00 +13: loading test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart
00:00 +24: loading test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart
00:00 +33: loading test/shadow_v2/projected_building_shadow_value_objects_test.dart
00:00 +55: loading test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
00:00 +74: loading test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
00:00 +98: loading test/shadow_v2/projected_building_shadow_element_config_test.dart
00:00 +108: loading test/shadow_v2/projected_building_shadow_json_characterization_test.dart
00:00 +115: loading test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
00:00 +133: loading test/shadow_v2/projected_building_shadow_preset_test.dart
00:01 +148: loading test/shadow_v2/projected_building_shadow_diagnostics_test.dart
00:01 +162: loading test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
00:01 +162: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null
00:01 +163: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind stores building casterKind
00:01 +164: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind stores largeVolume casterKind
00:01 +165: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind disabled config preserves casterKind
00:01 +166: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind
00:01 +167: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind
00:01 +168: test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart: ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind
00:01 +169: loading test/shadow_v2/projected_shadow_footprint_strategy_test.dart
00:01 +193: loading test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
00:01 +204: loading test/shadow_v2/projected_building_shadow_geometry_test.dart
00:01 +221: loading test/shadow_v2/projected_building_shadow_preset_catalog_test.dart
00:01 +228: All tests passed!
```

## 17. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
```

Sortie complète :

```text
Analyzing projected_building_shadow.dart, projected_building_shadow_element_caster_kind_test.dart...
No issues found!
```

## 18. Audit anti-dérive

Commande :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "toJson|fromJson|Json|json|diagnoseProjectedBuildingShadows|resolveProjectedBuildingShadowGeometry\(|resolveProjectedShadowFootprintEffectiveTuning\(|ProjectElementEntry|MapPlacedElement|runtime|editor|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|build_runner|adaptiveFootprint" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
```

Sortie complète :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:10:/// inspect the clock, or affect runtime rendering.
packages/map_core/lib/src/models/projected_building_shadow.dart:28:/// The raw values are intentionally preserved so the editor can keep the
packages/map_core/lib/src/models/projected_building_shadow.dart:452:/// This model is intentionally not connected to JSON, manifests, runtime
packages/map_core/lib/src/models/projected_building_shadow.dart:453:/// resolution, or editor UI in ShadowV2-5.
packages/map_core/lib/src/models/projected_building_shadow.dart:557:/// manifest integration, default presets, editor behavior, or runtime behavior.
packages/map_core/lib/src/models/projected_building_shadow.dart:640:/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
```

Justification :

- les hits sont des commentaires préexistants dans le fichier modèle ;
- aucun hit dans le nouveau test ;
- aucun hit indiquant modification JSON, diagnostics, resolver, runtime, editor, screenshot, baseline, Selbrume, build_runner ou nouveau `adaptiveFootprint`.

## 19. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/models/map_data.dart
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

## 20. Ce qui n’a volontairement pas été créé

```text
*.g.dart
*.freezed.dart
*.golden
baseline_manifest.json
renderer
painter
codec JSON
migration
fixture Selbrume
screenshot
image
```

## 21. git diff --stat

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --stat
```

Sortie :

```text
 packages/map_core/lib/src/models/projected_building_shadow.dart | 8 +++++++-
 1 file changed, 7 insertions(+), 1 deletion(-)
```

## 22. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

## 23. git diff --check

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --check
```

Sortie :

```text
```

## 24. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale complète après création du rapport :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
?? reports/shadows/v2/shadow_v2_64_projected_building_shadow_caster_kind_config_model_v0.md
```

## 25. Risques / réserves

- `casterKind` existe dans le modèle mais n'est pas persisté : tout JSON existant continue donc à produire `null`.
- Aucun diagnostic n'impose encore `casterKind` pour un preset adaptive.
- Aucun resolver ne transmet encore `casterKind` à `resolveProjectedShadowFootprintEffectiveTuning(...)`.
- Ces réserves sont volontaires et correspondent au périmètre du Lot 64.

## 26. Auto-critique

- Le lot est-il bien limité au modèle `ProjectElementProjectedBuildingShadowConfig` ? Oui : seule cette classe a été modifiée dans le modèle.
- Le resolver géométrique est-il réellement intact ? Oui : aucun fichier resolver modifié.
- L'opération effective est-elle réellement intacte ? Oui : aucun fichier operation modifié.
- JSON/persistence est-il réellement hors scope ? Oui : aucun codec modifié, régression JSON lancée.
- Diagnostics sont-ils réellement hors scope ? Oui : aucun fichier diagnostic modifié.
- Runtime/editor sont-ils réellement hors scope ? Oui : aucun fichier runtime/editor modifié.
- `casterKind` est-il optionnel ? Oui.
- `casterKind` reste-t-il `null` par défaut ? Oui, testé.
- Les tests existants restent-ils verts ? Oui, régressions utiles et groupe `shadow_v2` passés.
- Le rapport contient-il toutes les preuves principales ? Oui : commandes, sorties, diff, inventaire, test RED/GREEN, analyse, audit et statut final.

## 27. Regard critique sur le prompt

Le prompt est très précis et protège correctement le périmètre : modèle pur uniquement, pas de JSON, pas de diagnostics, pas de resolver. Le point de vigilance principal est que `casterKind` ajouté au modèle sans JSON crée volontairement une période où l'information n'est pas persistée ; le prochain lot doit donc traiter l'ordre JSON/diagnostics sans élargir prématurément le runtime.

## 28. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-65 — Projected Building Shadow Caster Kind Config JSON Design Gate
```

Objectif probable :

```text
Définir comment persister casterKind dans ProjectElementProjectedBuildingShadowConfig JSON,
sans implémenter encore,
en gardant la compat avec les anciens JSON sans casterKind.
```

Alternative possible si JSON est différé :

```text
ShadowV2-65 — Projected Building Shadow Adaptive Guard Diagnostics Design Gate
```

## 29. Code complet des fichiers créés/modifiés

### Diff complet — `packages/map_core/lib/src/models/projected_building_shadow.dart`

```diff
diff --git a/packages/map_core/lib/src/models/projected_building_shadow.dart b/packages/map_core/lib/src/models/projected_building_shadow.dart
index e0bd7ec9..b1fbddcb 100644
--- a/packages/map_core/lib/src/models/projected_building_shadow.dart
+++ b/packages/map_core/lib/src/models/projected_building_shadow.dart
@@ -645,6 +645,7 @@ final class ProjectElementProjectedBuildingShadowConfig {
     required String presetId,
     required ProjectedShadowAnchor anchor,
     required ProjectedShadowOffset localOffset,
+    ProjectedBuildingShadowCasterKind? casterKind,
   }) {
     _validateNonBlank(
       presetId,
@@ -655,6 +656,7 @@ final class ProjectElementProjectedBuildingShadowConfig {
       presetId: presetId,
       anchor: anchor,
       localOffset: localOffset,
+      casterKind: casterKind,
     );
   }
 
@@ -663,12 +665,14 @@ final class ProjectElementProjectedBuildingShadowConfig {
     required this.presetId,
     required this.anchor,
     required this.localOffset,
+    required this.casterKind,
   });
 
   final bool enabled;
   final String presetId;
   final ProjectedShadowAnchor anchor;
   final ProjectedShadowOffset localOffset;
+  final ProjectedBuildingShadowCasterKind? casterKind;
 
   @override
   bool operator ==(Object other) =>
@@ -677,7 +681,8 @@ final class ProjectElementProjectedBuildingShadowConfig {
           other.enabled == enabled &&
           other.presetId == presetId &&
           other.anchor == anchor &&
-          other.localOffset == localOffset;
+          other.localOffset == localOffset &&
+          other.casterKind == casterKind;
 
   @override
   int get hashCode => Object.hash(
@@ -685,6 +690,7 @@ final class ProjectElementProjectedBuildingShadowConfig {
         presetId,
         anchor,
         localOffset,
+        casterKind,
       );
 }
```

### Contenu complet du bloc modèle modifié — `ProjectElementProjectedBuildingShadowConfig`

```dart
@immutable
final class ProjectElementProjectedBuildingShadowConfig {
  factory ProjectElementProjectedBuildingShadowConfig({
    required bool enabled,
    required String presetId,
    required ProjectedShadowAnchor anchor,
    required ProjectedShadowOffset localOffset,
    ProjectedBuildingShadowCasterKind? casterKind,
  }) {
    _validateNonBlank(
      presetId,
      'ProjectElementProjectedBuildingShadowConfig.presetId',
    );
    return ProjectElementProjectedBuildingShadowConfig._(
      enabled: enabled,
      presetId: presetId,
      anchor: anchor,
      localOffset: localOffset,
      casterKind: casterKind,
    );
  }

  const ProjectElementProjectedBuildingShadowConfig._({
    required this.enabled,
    required this.presetId,
    required this.anchor,
    required this.localOffset,
    required this.casterKind,
  });

  final bool enabled;
  final String presetId;
  final ProjectedShadowAnchor anchor;
  final ProjectedShadowOffset localOffset;
  final ProjectedBuildingShadowCasterKind? casterKind;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectElementProjectedBuildingShadowConfig &&
          other.enabled == enabled &&
          other.presetId == presetId &&
          other.anchor == anchor &&
          other.localOffset == localOffset &&
          other.casterKind == casterKind;

  @override
  int get hashCode => Object.hash(
        enabled,
        presetId,
        anchor,
        localOffset,
        casterKind,
      );
}
```

### Contenu complet — `packages/map_core/test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig casterKind', () {
    test('defaults to null', () {
      final config = _config();

      expect(config.casterKind, isNull);
    });

    test('stores building casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
    });

    test('stores largeVolume casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(config.casterKind, ProjectedBuildingShadowCasterKind.largeVolume);
    });

    test('disabled config preserves casterKind', () {
      final config = _config(
        enabled: false,
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      expect(config.enabled, isFalse);
      expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
    });

    test('equality includes casterKind', () {
      final withoutCaster = _config();
      final sameWithoutCaster = _config();
      final withBuilding = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final sameWithBuilding = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final withLargeVolume = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(withoutCaster, sameWithoutCaster);
      expect(withBuilding, sameWithBuilding);
      expect(withoutCaster, isNot(withBuilding));
      expect(withBuilding, isNot(withLargeVolume));
    });

    test('hashCode includes casterKind', () {
      final first = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final same = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );
      final changed = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(first.hashCode, same.hashCode);
      expect(first, isNot(changed));
    });

    test('still rejects blank presetId with casterKind', () {
      expect(
        () => _config(
          presetId: '',
          casterKind: ProjectedBuildingShadowCasterKind.building,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'pokemon-building-shadow-footprint-adaptive',
  ProjectedBuildingShadowCasterKind? casterKind,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
    casterKind: casterKind,
  );
}
```

Checklist finale :
- [x] AGENTS.md lu
- [x] Aucun git write effectué
- [x] Aucun fichier runtime modifié
- [x] Aucun fichier editor modifié
- [x] Aucun resolver géométrique modifié
- [x] Aucune opération effective modifiée
- [x] Aucun JSON/codec modifié
- [x] Aucun diagnostics modifié
- [x] Aucun generated créé
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] casterKind ajouté
- [x] casterKind optionnel
- [x] casterKind default null
- [x] casterKind building testé
- [x] casterKind largeVolume testé
- [x] disabled config + casterKind testé
- [x] Equality inclut casterKind
- [x] HashCode inclut casterKind
- [x] presetId blank reste rejeté avec casterKind
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] dart test test/shadow_v2 passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
