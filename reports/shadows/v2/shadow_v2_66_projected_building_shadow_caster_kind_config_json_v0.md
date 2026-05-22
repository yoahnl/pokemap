# ShadowV2-66 — Projected Building Shadow Caster Kind Config JSON V0

## 1. Résumé exécutif

Lot implémenté dans `map_core` uniquement.

`ProjectedBuildingShadowCasterKind` dispose maintenant d'un codec JSON dédié :

- `building` encode/décode `"building"`;
- `largeVolume` encode/décode `"largeVolume"`;
- les valeurs inconnues, types non string et `null` sont rejetés par le codec dédié.

`ProjectElementProjectedBuildingShadowConfig` persiste maintenant `casterKind` :

- `null` est omis à l'encodage;
- absence ou `null` explicite au décodage produit `casterKind == null`;
- les anciens JSON sans `casterKind` restent compatibles et ne réémettent pas la clé.

Aucun modèle, preset JSON, resolver, diagnostic, runtime, editor, generated, screenshot, baseline ou fichier Selbrume n'a été modifié.

## 2. Objectif du lot

Objectif exact exécuté :

```text
Persister casterKind dans ProjectElementProjectedBuildingShadowConfig JSON,
avec compatibilité totale des anciens JSON sans casterKind,
sans diagnostics,
sans resolver,
sans runtime,
sans editor,
sans renderer/painter,
sans Selbrume,
sans screenshot,
sans baseline.
```

## 3. Rappel ShadowV2-65

Le Lot 65 a verrouillé le contrat suivant :

- clé JSON : `casterKind`;
- valeurs JSON : `building`, `largeVolume`;
- encodage `null` : clé omise;
- décodage clé absente : `null`;
- décodage `null` explicite : `null`;
- valeur inconnue : `ValidationException`;
- type non string non null : `ValidationException`;
- codec dédié dans `projected_shadow_value_object_json_codecs.dart`;
- intégration dans `project_element_projected_building_shadow_config_json_codec.dart`.

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
?? reports/gameplay/narrative_studio_readiness_audit.md
```

Fichiers préexistants non liés au Lot 66 :

```text
reports/gameplay/narrative_studio_readiness_audit.md
```

Ce fichier était déjà non suivi avant les modifications du Lot 66 et n'a pas été touché.

## 5. Lecture AGENTS.md et méthode suivie

Commandes exécutées :

```bash
cd /Users/karim/Project/pokemonProject
find .. -name AGENTS.md -print
sed -n '1,320p' AGENTS.md
```

Sortie `find` :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Preuve de lecture AGENTS.md :

```text
# Repository Guidelines

## 1. Purpose and Priority

PokeMap is a Dart/Flutter monorepo for a Pokemon-like no-code fangame editor/runtime/battle stack.
No workspace orchestrator is present: `melos.yaml` is absent. Run commands package by package.
Never run Git write operations unless the user explicitly asks.
Use root-level `skills/` as a workflow library when it materially applies.
Run commands from the relevant package directory.
Reports under `reports/` are tracked engineering artifacts. Modify them only when the task asks for a report, audit, review, lot closure, or roadmap/status evidence.
```

Méthode réellement suivie :

- Pass 1 — audit codecs JSON actuels et modèle `casterKind`;
- Pass 2 — tests RED sur codec enum et codec config;
- Pass 3 — implémentation minimale du codec JSON V0;
- Pass 4 — tests ciblés, régressions, `dart test test/shadow_v2`, analyse ciblée, audit anti-dérive et inventaire Git.

Skills utilisés en amont de l'implémentation :

- `superpowers:using-superpowers`;
- `karpathy-guidelines`;
- `superpowers:test-driven-development`;
- `dart-add-unit-test`;
- `superpowers:verification-before-completion`.

## 6. Fichiers créés / modifiés / supprimés

Créés par ShadowV2-66 :

```text
reports/shadows/v2/shadow_v2_66_projected_building_shadow_caster_kind_config_json_v0.md
```

Modifiés par ShadowV2-66 :

```text
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Supprimés par ShadowV2-66 :

```text
Aucun
```

Fichiers hors scope déjà présents :

```text
reports/gameplay/narrative_studio_readiness_audit.md
```

Problèmes introduits par ShadowV2-66 :

```text
Aucun identifié.
```

## 7. Audit initial

Commandes d'audit exécutées avant modification :

```bash
rg -n "ProjectedBuildingShadowCasterKind|building|largeVolume|ProjectElementProjectedBuildingShadowConfig|casterKind" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart

rg -n "encodeProjectedShadowTimeOfDayMode|decodeProjectedShadowTimeOfDayMode|ProjectedShadowTimeOfDayMode|encodeProjected|decodeProjected|ValidationException|unknown value|must be a String" packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart

rg -n "encodeProjectElementProjectedBuildingShadowConfig|decodeProjectElementProjectedBuildingShadowConfig|enabled|presetId|anchor|localOffset|casterKind|unknown|round-trips|re-emitting|missing|required|invalid" packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart

rg -n "ProjectBuildingShadowPreset JSON|footprintStrategy|geometryMode|footprint|encodeProjectBuildingShadowPreset|decodeProjectBuildingShadowPreset" packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart packages/map_core/test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Constats :

- `ProjectedBuildingShadowCasterKind` existe déjà dans le modèle avec `building` et `largeVolume`.
- `ProjectElementProjectedBuildingShadowConfig` stocke déjà `casterKind`.
- Les tests modèle Lot 64 couvrent default null, `building`, `largeVolume`, disabled config, equality/hashCode et validation `presetId`.
- Les value-object codecs avaient déjà le style strict de `ProjectedShadowTimeOfDayMode`.
- Le codec config encodait/décodait seulement `enabled`, `presetId`, `anchor`, `localOffset`.
- `ProjectBuildingShadowPreset JSON` et `footprintStrategy JSON` restent hors scope.

## 8. Codec ProjectedBuildingShadowCasterKind ajouté

Ajouts :

```text
String encodeProjectedBuildingShadowCasterKind(ProjectedBuildingShadowCasterKind casterKind)
ProjectedBuildingShadowCasterKind decodeProjectedBuildingShadowCasterKind(Object? json)
```

Comportement :

- `ProjectedBuildingShadowCasterKind.building` -> `"building"`;
- `ProjectedBuildingShadowCasterKind.largeVolume` -> `"largeVolume"`;
- `"building"` -> `ProjectedBuildingShadowCasterKind.building`;
- `"largeVolume"` -> `ProjectedBuildingShadowCasterKind.largeVolume`;
- valeur inconnue -> `ValidationException`;
- type non string -> `ValidationException`;
- `null` -> `ValidationException`.

## 9. Encodage casterKind dans config JSON

`encodeProjectElementProjectedBuildingShadowConfig(...)` écrit maintenant :

```text
casterKind == null => clé omise
casterKind == building => "casterKind": "building"
casterKind == largeVolume => "casterKind": "largeVolume"
```

Les champs existants restent inchangés :

```text
enabled
presetId
anchor
localOffset
```

## 10. Décodage casterKind dans config JSON

`decodeProjectElementProjectedBuildingShadowConfig(...)` lit maintenant `casterKind` comme champ optionnel :

```text
clé absente => null
clé présente avec null => null
"building" => ProjectedBuildingShadowCasterKind.building
"largeVolume" => ProjectedBuildingShadowCasterKind.largeVolume
"lampPost" => ValidationException
1 / true / {} / [] => ValidationException
```

La validation des champs requis existants n'a pas changé.

## 11. Compatibilité anciens JSON

Ancien JSON sans `casterKind` :

```json
{
  "enabled": true,
  "presetId": "short-west-building-shadow",
  "anchor": { "xRatio": 0.5, "yRatio": 0.98 },
  "localOffset": { "x": 0, "y": 0 }
}
```

Comportement validé :

- decode => `casterKind == null`;
- encode après decode => la clé `casterKind` reste absente;
- les clés inconnues restent ignorées et non réémises selon le comportement existant.

## 12. Rejet valeurs inconnues / types invalides

Tests ajoutés :

- codec dédié rejette `"lampPost"`;
- codec dédié rejette `1`;
- codec dédié rejette `null`;
- codec config rejette `"lampPost"`;
- codec config rejette `1`, `true`, `{}`, `[]`;
- codec config accepte `null` explicite parce que le champ config est optionnel.

## 13. Ce qui n’a volontairement pas été branché

Non branché volontairement :

- `ProjectBuildingShadowPreset JSON`;
- `footprintStrategy JSON`;
- diagnostics adaptive guard;
- resolver géométrique;
- opération effective tuning;
- runtime;
- editor;
- renderer/painter;
- generated files;
- migration;
- screenshots/baselines;
- Selbrume.

## 14. Résultats tests ciblés

Commande obligatoire exécutée :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
```

Résultat :

```text
00:00 +31: All tests passed!
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: ProjectedShadowDirection JSON codec encodes the canonical x/y object
00:00 +1: ProjectedShadowDirection JSON codec decodes the canonical x/y object and ignores unknown keys
00:00 +2: ProjectedShadowDirection JSON codec round-trips through the canonical object
00:00 +3: ProjectedShadowDirection JSON codec rejects invalid JSON shape and required fields
00:00 +4: ProjectedShadowAnchor JSON codec encodes the canonical xRatio/yRatio object
00:00 +5: ProjectedShadowAnchor JSON codec decodes the canonical ratio object and ignores unknown keys
00:00 +6: ProjectedShadowAnchor JSON codec round-trips through the canonical object
00:00 +7: ProjectedShadowAnchor JSON codec rejects missing fields and invalid ratios
00:00 +8: ProjectedShadowOffset JSON codec encodes the canonical x/y object
00:00 +9: ProjectedShadowOffset JSON codec decodes positive, zero, and negative offsets with unknown keys ignored
00:00 +10: ProjectedShadowOffset JSON codec round-trips through the canonical object
00:00 +11: ProjectedShadowOffset JSON codec rejects missing and non-numeric coordinates
00:00 +12: ProjectedShadowShapeTuning JSON codec encodes the canonical shape object
00:00 +13: ProjectedShadowShapeTuning JSON codec decodes the canonical shape object and ignores unknown keys
00:00 +14: ProjectedShadowShapeTuning JSON codec round-trips through the canonical object
00:00 +15: ProjectedShadowShapeTuning JSON codec rejects missing fields and invalid ratios
00:00 +16: ProjectedShadowAppearance JSON codec encodes the canonical appearance object with uppercase color
00:00 +17: ProjectedShadowAppearance JSON codec decodes the canonical appearance object and ignores unknown keys
00:00 +18: ProjectedShadowAppearance JSON codec round-trips lowercase color as uppercase
00:00 +19: ProjectedShadowAppearance JSON codec accepts opacity boundaries
00:00 +20: ProjectedShadowAppearance JSON codec rejects missing fields and invalid appearance values
00:00 +21: ProjectedShadowTimeOfDayMode JSON codec encodes fixed and followsSun
00:00 +22: ProjectedShadowTimeOfDayMode JSON codec decodes fixed and followsSun
00:00 +23: ProjectedShadowTimeOfDayMode JSON codec rejects unknown, non-string, and wrongly-cased values
00:00 +24: ProjectedBuildingShadowCasterKind JSON codec encodes building
00:00 +25: ProjectedBuildingShadowCasterKind JSON codec encodes largeVolume
00:00 +26: ProjectedBuildingShadowCasterKind JSON codec decodes building
00:00 +27: ProjectedBuildingShadowCasterKind JSON codec decodes largeVolume
00:00 +28: ProjectedBuildingShadowCasterKind JSON codec rejects unknown string
00:00 +29: ProjectedBuildingShadowCasterKind JSON codec rejects non-string
00:00 +30: ProjectedBuildingShadowCasterKind JSON codec rejects null
00:00 +31: All tests passed!
```

Commande obligatoire exécutée :

```bash
cd packages/map_core && dart test test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Résultat :

```text
00:00 +18: All tests passed!
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:00 +1: ProjectElementProjectedBuildingShadowConfig JSON codec encodes enabled false while keeping explicit preset and placement
00:00 +2: ProjectElementProjectedBuildingShadowConfig JSON codec omits casterKind when null
00:00 +3: ProjectElementProjectedBuildingShadowConfig JSON codec encodes building casterKind
00:00 +4: ProjectElementProjectedBuildingShadowConfig JSON codec encodes largeVolume casterKind
00:00 +5: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true
00:00 +6: ProjectElementProjectedBuildingShadowConfig JSON codec decodes missing casterKind as null
00:00 +7: ProjectElementProjectedBuildingShadowConfig JSON codec decodes explicit null casterKind as null
00:00 +8: ProjectElementProjectedBuildingShadowConfig JSON codec decodes building casterKind
00:00 +9: ProjectElementProjectedBuildingShadowConfig JSON codec decodes largeVolume casterKind
00:00 +10: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled false
00:00 +11: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config instances through canonical JSON
00:00 +12: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config with casterKind
00:00 +13: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips JSON without re-emitting unknown keys
00:00 +14: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips legacy JSON without re-emitting casterKind
00:00 +15: ProjectElementProjectedBuildingShadowConfig JSON codec rejects missing required fields
00:00 +16: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid field types
00:00 +17: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid values delegated to model and value objects
00:00 +18: All tests passed!
```

## 15. Résultats régressions utiles

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_element_caster_kind_test.dart
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: ProjectElementProjectedBuildingShadowConfig casterKind defaults to null
00:00 +1: ProjectElementProjectedBuildingShadowConfig casterKind stores building casterKind
00:00 +2: ProjectElementProjectedBuildingShadowConfig casterKind stores largeVolume casterKind
00:00 +3: ProjectElementProjectedBuildingShadowConfig casterKind disabled config preserves casterKind
00:00 +4: ProjectElementProjectedBuildingShadowConfig casterKind equality includes casterKind
00:00 +5: ProjectElementProjectedBuildingShadowConfig casterKind hashCode includes casterKind
00:00 +6: ProjectElementProjectedBuildingShadowConfig casterKind still rejects blank presetId with casterKind
00:00 +7: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_element_config_test.dart
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values
00:00 +1: ProjectElementProjectedBuildingShadowConfig accepts enabled false and preserves preset intent
00:00 +2: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids
00:00 +3: ProjectElementProjectedBuildingShadowConfig stores spaced preset ids unchanged
00:00 +4: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets
00:00 +5: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode
00:00 +6: ProjectElementProjectedBuildingShadowConfig value equality includes enabled
00:00 +7: ProjectElementProjectedBuildingShadowConfig value equality includes presetId
00:00 +8: ProjectElementProjectedBuildingShadowConfig value equality includes anchor
00:00 +9: ProjectElementProjectedBuildingShadowConfig value equality includes localOffset
00:00 +10: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_effective_tuning_test.dart
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: resolveProjectedShadowFootprintEffectiveTuning fixed resolves fixed tuning with fixed opacity
00:00 +1: resolveProjectedShadowFootprintEffectiveTuning fixed ignores casterKind for fixed tuning
00:00 +2: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity below 0
00:00 +3: resolveProjectedShadowFootprintEffectiveTuning fixed rejects invalid fixedOpacity above 1
00:00 +4: resolveProjectedShadowFootprintEffectiveTuning adaptive blocks adaptive depth without casterKind
00:00 +5: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for building caster
00:00 +6: resolveProjectedShadowFootprintEffectiveTuning adaptive resolves adaptive depth for largeVolume caster
00:00 +7: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps wide_house_6x5 at base tuning
00:00 +8: resolveProjectedShadowFootprintEffectiveTuning adaptive keeps medium_shop_5x6 at base tuning
00:00 +9: resolveProjectedShadowFootprintEffectiveTuning adaptive partially adapts thin_prop_like_2x6 canary
00:00 +10: resolveProjectedShadowFootprintEffectiveTuning adaptive interpolates both gates multiplicatively
00:00 +11: ProjectedShadowEffectiveFootprintTuning equality includes all fields
00:00 +12: ProjectedShadowEffectiveFootprintTuning rejects opacity below 0
00:00 +13: ProjectedShadowEffectiveFootprintTuning rejects opacity above 1
00:00 +14: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT below 0
00:00 +15: ProjectedShadowEffectiveFootprintTuning rejects adaptiveT above 1
00:00 +16: ProjectedShadowFootprintEffectiveTuningResult resolved equality includes value
00:00 +17: ProjectedShadowFootprintEffectiveTuningResult blocked equality includes reason
00:00 +18: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: loading test/shadow_v2/project_building_shadow_preset_footprint_strategy_test.dart
00:00 +0: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprint as source of truth
00:00 +1: ProjectBuildingShadowPreset footprintStrategy legacy footprint fixed keeps footprintStrategy null
00:00 +2: ProjectBuildingShadowPreset footprintStrategy directional rejects footprintStrategy
00:00 +3: ProjectBuildingShadowPreset footprintStrategy directional still rejects footprint
00:00 +4: ProjectBuildingShadowPreset footprintStrategy directional accepts no footprint and no footprintStrategy
00:00 +5: ProjectBuildingShadowPreset footprintStrategy footprint rejects missing footprint and missing footprintStrategy
00:00 +6: ProjectBuildingShadowPreset footprintStrategy footprint accepts adaptive footprintStrategy with null footprint
00:00 +7: ProjectBuildingShadowPreset footprintStrategy footprint adaptive rejects non-null footprint
00:00 +8: ProjectBuildingShadowPreset footprintStrategy footprint rejects fixed footprintStrategy in V0
00:00 +9: ProjectBuildingShadowPreset footprintStrategy equality includes footprintStrategy
00:00 +10: ProjectBuildingShadowPreset footprintStrategy hashCode includes footprintStrategy
00:00 +11: All tests passed!
```

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Sortie complète lisible relancée avec `--reporter expanded --no-color` :

```text
00:00 +0: loading test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
00:00 +0: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId
00:00 +1: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder
00:00 +2: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals
00:00 +3: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null
00:00 +4: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON
00:00 +5: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON
00:00 +7: ProjectBuildingShadowPreset JSON codec rejects missing required fields
00:00 +8: ProjectBuildingShadowPreset JSON codec rejects invalid field types
00:00 +9: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs
00:00 +10: All tests passed!
```

## 16. Résultat dart test test/shadow_v2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +244: All tests passed!
```

## 17. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/operations/projected_shadow_value_object_json_codecs.dart lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Sortie complète :

```text
Analyzing projected_shadow_value_object_json_codecs.dart, project_element_projected_building_shadow_config_json_codec.dart, projected_shadow_value_object_json_codecs_test.dart, project_element_projected_building_shadow_config_json_codec_test.dart...
No issues found!
```

## 18. Audit anti-dérive

Commande :

```bash
cd /Users/karim/Project/pokemonProject
rg -n "footprintStrategy|ProjectBuildingShadowPreset|diagnoseProjectedBuildingShadows|resolveProjectedBuildingShadowGeometry\(|resolveProjectedShadowFootprintEffectiveTuning\(|ProjectElementEntry|MapPlacedElement|runtime|editor|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|build_runner|adaptiveFootprint" packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
```

Sortie complète :

```text
packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart:20:      '$label JSON must be an Object, got ${json.runtimeType}',
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart:19:      '$label JSON must be an Object, got ${json.runtimeType}',
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart:207:      'ProjectedShadowTimeOfDayMode must be a String, got ${json.runtimeType}',
packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart:233:      'ProjectedBuildingShadowCasterKind must be a String, got ${json.runtimeType}',
packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart:83:        'editorLabel': 'south door',
```

Justification des hits :

- `runtimeType` est une propriété Dart utilisée dans des messages de validation, pas une référence à `map_runtime`.
- `editorLabel` est une clé inconnue de test déjà utilisée pour vérifier l'ignorance des champs inconnus, pas une référence à `map_editor`.
- Aucun hit sur `footprintStrategy`, `ProjectBuildingShadowPreset`, diagnostics, resolver, `ProjectElementEntry`, `MapPlacedElement`, screenshot, baseline, Selbrume, `build_runner` ou `adaptiveFootprint`.

## 19. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
packages/map_core/lib/src/operations/projected_building_shadow_diagnostics.dart
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_core/lib/src/operations/projected_shadow_footprint_effective_tuning.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart
packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart
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
 ...rojected_building_shadow_config_json_codec.dart |   7 ++
 .../projected_shadow_value_object_json_codecs.dart |  26 +++++
 ...ted_building_shadow_config_json_codec_test.dart | 114 +++++++++++++++++++++
 ...ected_shadow_value_object_json_codecs_test.dart |  55 ++++++++++
 4 files changed, 202 insertions(+)
```

## 22. git diff --name-status

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
M	packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
M	packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
M	packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
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

Résultat : aucun problème whitespace détecté.

## 24. git status final

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie finale réelle après création du rapport Lot 66 :

```text
 M packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart
 M packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart
 M packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart
 M packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart
?? reports/gameplay/narrative_studio_readiness_audit.md
?? reports/shadows/v2/shadow_v2_66_projected_building_shadow_caster_kind_config_json_v0.md
```

## 25. Risques / réserves

- `casterKind` est maintenant durable dans le JSON de config élément, mais aucun diagnostic adaptive guard n'est encore branché.
- Le codec dédié rejette `null`; ce choix est volontaire, car le `null` optionnel appartient au codec config.
- `ProjectBuildingShadowPreset JSON` et `footprintStrategy JSON` restent explicitement non modifiés.
- Les futurs diagnostics devront relier `casterKind` au preset adaptive via catalogue/config.

## 26. Auto-critique

- Le lot est bien limité au JSON `casterKind` config : oui.
- Le modèle est réellement intact : oui, `projected_building_shadow.dart` n'a pas été modifié.
- `ProjectBuildingShadowPreset JSON` est réellement intact : oui, le fichier codec preset n'a pas été modifié.
- `footprintStrategy JSON` est réellement hors scope : oui, aucun test ou codec ajouté pour ce champ.
- Diagnostics hors scope : oui.
- Resolver/runtime/editor hors scope : oui.
- Compat anciens JSON garantie : oui, tests absents/null/round-trip legacy.
- Null omis à l'encodage : oui, test `omits casterKind when null`.
- Valeurs invalides rejetées : oui, tests unknown string et non-string.
- Le rapport contient les preuves demandées : oui.

## 27. Regard critique sur le prompt

Le prompt est très cadré et protège bien contre deux dérives probables :

- brancher trop tôt `footprintStrategy JSON`;
- transformer un champ optionnel de config en règle diagnostic/resolver.

La seule nuance pratique est que les sorties de `dart test` avec reporter par défaut contiennent des séquences de contrôle difficiles à citer proprement. J'ai donc exécuté les commandes obligatoires, puis relancé les mêmes tests ciblés/régressions avec `--reporter expanded --no-color` pour produire des preuves lisibles dans ce rapport.

## 28. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-67 — Projected Building Shadow Adaptive Guard Diagnostics Design Gate
```

Objectif probable :

```text
Définir les diagnostics nécessaires pour signaler :
- config active qui référence un preset adaptive sans casterKind ;
- casterKind incompatible futur ;
- casterKind présent sur preset fixed legacy ;
sans implémenter encore.
```

À ne pas faire dans le prochain lot si c'est un design gate :

- ne pas brancher le resolver;
- ne pas modifier runtime/editor;
- ne pas ouvrir `footprintStrategy JSON`;
- ne pas modifier les fixtures/Selbrume;
- ne pas créer screenshot/baseline.

## 29. Code complet des fichiers créés/modifiés

Le rapport courant n'est pas recopié récursivement dans sa propre section. Les quatre fichiers Dart modifiés sont reproduits intégralement ci-dessous.

### packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

Map<String, Object?> _requiredObject(Object? json, String label) {
  if (json is! Map) {
    throw ValidationException(
      '$label JSON must be an Object, got ${json.runtimeType}',
    );
  }
  return _stringKeyMapFrom(json);
}

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldKey is required');
  }
  return json[key];
}

double _requiredDouble(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! num) {
    throw ValidationException('$fieldKey must be a num');
  }
  final result = value.toDouble();
  if (!result.isFinite) {
    throw ValidationException('$fieldKey must be finite');
  }
  return result;
}

String _requiredString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

/// Encodes the authored direction of a projected building shadow.
Map<String, dynamic> encodeProjectedShadowDirection(
  ProjectedShadowDirection direction,
) {
  return <String, dynamic>{
    'x': direction.x,
    'y': direction.y,
  };
}

/// Decodes the authored direction of a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowDirection decodeProjectedShadowDirection(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowDirection');
  return ProjectedShadowDirection(
    x: _requiredDouble(map, 'x', 'ProjectedShadowDirection.x'),
    y: _requiredDouble(map, 'y', 'ProjectedShadowDirection.y'),
  );
}

/// Encodes the local asset anchor for a projected building shadow.
Map<String, dynamic> encodeProjectedShadowAnchor(
  ProjectedShadowAnchor anchor,
) {
  return <String, dynamic>{
    'xRatio': anchor.xRatio,
    'yRatio': anchor.yRatio,
  };
}

/// Decodes the local asset anchor for a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowAnchor decodeProjectedShadowAnchor(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowAnchor');
  return ProjectedShadowAnchor(
    xRatio: _requiredDouble(map, 'xRatio', 'ProjectedShadowAnchor.xRatio'),
    yRatio: _requiredDouble(map, 'yRatio', 'ProjectedShadowAnchor.yRatio'),
  );
}

/// Encodes the local offset applied after anchor resolution.
Map<String, dynamic> encodeProjectedShadowOffset(
  ProjectedShadowOffset offset,
) {
  return <String, dynamic>{
    'x': offset.x,
    'y': offset.y,
  };
}

/// Decodes the local offset applied after anchor resolution.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowOffset decodeProjectedShadowOffset(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowOffset');
  return ProjectedShadowOffset(
    x: _requiredDouble(map, 'x', 'ProjectedShadowOffset.x'),
    y: _requiredDouble(map, 'y', 'ProjectedShadowOffset.y'),
  );
}

/// Encodes the parametric shape tuning for a projected building shadow.
Map<String, dynamic> encodeProjectedShadowShapeTuning(
  ProjectedShadowShapeTuning shape,
) {
  return <String, dynamic>{
    'lengthRatio': shape.lengthRatio,
    'nearWidthRatio': shape.nearWidthRatio,
    'farWidthRatio': shape.farWidthRatio,
  };
}

/// Decodes the parametric shape tuning for a projected building shadow.
///
/// Unknown keys are ignored. Known keys keep strict numeric types.
ProjectedShadowShapeTuning decodeProjectedShadowShapeTuning(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowShapeTuning');
  return ProjectedShadowShapeTuning(
    lengthRatio: _requiredDouble(
      map,
      'lengthRatio',
      'ProjectedShadowShapeTuning.lengthRatio',
    ),
    nearWidthRatio: _requiredDouble(
      map,
      'nearWidthRatio',
      'ProjectedShadowShapeTuning.nearWidthRatio',
    ),
    farWidthRatio: _requiredDouble(
      map,
      'farWidthRatio',
      'ProjectedShadowShapeTuning.farWidthRatio',
    ),
  );
}

/// Encodes the simple visual appearance of a projected building shadow.
Map<String, dynamic> encodeProjectedShadowAppearance(
  ProjectedShadowAppearance appearance,
) {
  return <String, dynamic>{
    'opacity': appearance.opacity,
    'colorHexRgb': appearance.colorHexRgb,
  };
}

/// Decodes the simple visual appearance of a projected building shadow.
///
/// Unknown keys are ignored. The value object normalizes color to uppercase.
ProjectedShadowAppearance decodeProjectedShadowAppearance(Object? json) {
  final map = _requiredObject(json, 'ProjectedShadowAppearance');
  return ProjectedShadowAppearance(
    opacity: _requiredDouble(
      map,
      'opacity',
      'ProjectedShadowAppearance.opacity',
    ),
    colorHexRgb: _requiredString(
      map,
      'colorHexRgb',
      'ProjectedShadowAppearance.colorHexRgb',
    ),
  );
}

/// Encodes the future time-of-day behavior flag.
String encodeProjectedShadowTimeOfDayMode(
  ProjectedShadowTimeOfDayMode mode,
) {
  return switch (mode) {
    ProjectedShadowTimeOfDayMode.fixed => 'fixed',
    ProjectedShadowTimeOfDayMode.followsSun => 'followsSun',
  };
}

/// Decodes the future time-of-day behavior flag.
///
/// Values are intentionally strict: no silent fallback and no case folding.
ProjectedShadowTimeOfDayMode decodeProjectedShadowTimeOfDayMode(Object? json) {
  if (json is! String) {
    throw ValidationException(
      'ProjectedShadowTimeOfDayMode must be a String, got ${json.runtimeType}',
    );
  }
  return switch (json) {
    'fixed' => ProjectedShadowTimeOfDayMode.fixed,
    'followsSun' => ProjectedShadowTimeOfDayMode.followsSun,
    _ => throw ValidationException(
        'ProjectedShadowTimeOfDayMode has unknown value "$json"',
      ),
  };
}

String encodeProjectedBuildingShadowCasterKind(
  ProjectedBuildingShadowCasterKind casterKind,
) {
  return switch (casterKind) {
    ProjectedBuildingShadowCasterKind.building => 'building',
    ProjectedBuildingShadowCasterKind.largeVolume => 'largeVolume',
  };
}

ProjectedBuildingShadowCasterKind decodeProjectedBuildingShadowCasterKind(
  Object? json,
) {
  if (json is! String) {
    throw ValidationException(
      'ProjectedBuildingShadowCasterKind must be a String, got ${json.runtimeType}',
    );
  }
  return switch (json) {
    'building' => ProjectedBuildingShadowCasterKind.building,
    'largeVolume' => ProjectedBuildingShadowCasterKind.largeVolume,
    _ => throw ValidationException(
        'ProjectedBuildingShadowCasterKind has unknown value "$json"',
      ),
  };
}
```

### packages/map_core/lib/src/operations/project_element_projected_building_shadow_config_json_codec.dart

```dart
import '../exceptions/map_exceptions.dart';
import '../models/projected_building_shadow.dart';
import 'projected_shadow_value_object_json_codecs.dart';

Map<String, Object?> _stringKeyMapFrom(Object mapLike) {
  final map = mapLike as Map<dynamic, dynamic>;
  return Map<String, Object?>.from(
    map.map(
      (dynamic key, dynamic value) => MapEntry(
        key is String ? key : key.toString(),
        value as Object?,
      ),
    ),
  );
}

Map<String, Object?> _requiredObject(Object? json, String label) {
  if (json is! Map) {
    throw ValidationException(
      '$label JSON must be an Object, got ${json.runtimeType}',
    );
  }
  return _stringKeyMapFrom(json);
}

Object? _valueForRequiredKey(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  if (!json.containsKey(key)) {
    throw ValidationException('$fieldKey is required');
  }
  return json[key];
}

bool _requiredBool(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! bool) {
    throw ValidationException('$fieldKey must be a bool');
  }
  return value;
}

String _requiredString(
  Map<String, Object?> json,
  String key,
  String fieldKey,
) {
  final value = _valueForRequiredKey(json, key, fieldKey);
  if (value is! String) {
    throw ValidationException('$fieldKey must be a non-null String');
  }
  return value;
}

/// Encodes an element-level authored projected building shadow config.
Map<String, dynamic> encodeProjectElementProjectedBuildingShadowConfig(
  ProjectElementProjectedBuildingShadowConfig config,
) {
  final casterKind = config.casterKind;
  return <String, dynamic>{
    'enabled': config.enabled,
    'presetId': config.presetId,
    'anchor': encodeProjectedShadowAnchor(config.anchor),
    'localOffset': encodeProjectedShadowOffset(config.localOffset),
    if (casterKind != null)
      'casterKind': encodeProjectedBuildingShadowCasterKind(casterKind),
  };
}

/// Decodes an element-level authored projected building shadow config.
///
/// All fields are required, including `presetId` when `enabled` is false.
/// Unknown keys are ignored; anchor and offset are delegated to the ShadowV2
/// atomic value-object codecs.
ProjectElementProjectedBuildingShadowConfig
    decodeProjectElementProjectedBuildingShadowConfig(Object? json) {
  final map = _requiredObject(
    json,
    'ProjectElementProjectedBuildingShadowConfig',
  );
  final casterKindJson = map['casterKind'];
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: _requiredBool(
      map,
      'enabled',
      'ProjectElementProjectedBuildingShadowConfig.enabled',
    ),
    presetId: _requiredString(
      map,
      'presetId',
      'ProjectElementProjectedBuildingShadowConfig.presetId',
    ),
    anchor: decodeProjectedShadowAnchor(
      _valueForRequiredKey(
        map,
        'anchor',
        'ProjectElementProjectedBuildingShadowConfig.anchor',
      ),
    ),
    localOffset: decodeProjectedShadowOffset(
      _valueForRequiredKey(
        map,
        'localOffset',
        'ProjectElementProjectedBuildingShadowConfig.localOffset',
      ),
    ),
    casterKind: casterKindJson == null
        ? null
        : decodeProjectedBuildingShadowCasterKind(casterKindJson),
  );
}
```

### packages/map_core/test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowDirection JSON codec', () {
    test('encodes the canonical x/y object', () {
      final direction = ProjectedShadowDirection(x: -0.55, y: 0.35);

      expect(
        encodeProjectedShadowDirection(direction),
        <String, Object?>{'x': -0.55, 'y': 0.35},
      );
    });

    test('decodes the canonical x/y object and ignores unknown keys', () {
      final direction = decodeProjectedShadowDirection(<String, Object?>{
        'x': -0.55,
        'y': 0.35,
        'debug': true,
      });

      expect(direction, ProjectedShadowDirection(x: -0.55, y: 0.35));
      expect(
        encodeProjectedShadowDirection(direction),
        <String, Object?>{'x': -0.55, 'y': 0.35},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowDirection(
        ProjectedShadowDirection(x: -0.55, y: 0.35),
      );

      expect(
        encodeProjectedShadowDirection(
          decodeProjectedShadowDirection(encoded),
        ),
        encoded,
      );
    });

    test('rejects invalid JSON shape and required fields', () {
      expect(
        () => decodeProjectedShadowDirection(null),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'y': 0.35}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'x': -0.55}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{
          'x': 'west',
          'y': 0.35,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowDirection(<String, Object?>{'x': 0, 'y': 0}),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowAnchor JSON codec', () {
    test('encodes the canonical xRatio/yRatio object', () {
      final anchor = ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98);

      expect(
        encodeProjectedShadowAnchor(anchor),
        <String, Object?>{'xRatio': 0.5, 'yRatio': 0.98},
      );
    });

    test('decodes the canonical ratio object and ignores unknown keys', () {
      final anchor = decodeProjectedShadowAnchor(<String, Object?>{
        'xRatio': 0.5,
        'yRatio': 0.98,
        'editorLabel': 'south door',
      });

      expect(anchor, ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98));
      expect(
        encodeProjectedShadowAnchor(anchor),
        <String, Object?>{'xRatio': 0.5, 'yRatio': 0.98},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowAnchor(
        ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98),
      );

      expect(
        encodeProjectedShadowAnchor(decodeProjectedShadowAnchor(encoded)),
        encoded,
      );
    });

    test('rejects missing fields and invalid ratios', () {
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{'yRatio': 0.98}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{'xRatio': 0.5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{
          'xRatio': 1.01,
          'yRatio': 0.98,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAnchor(<String, Object?>{
          'xRatio': 0.5,
          'yRatio': 'bottom',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowOffset JSON codec', () {
    test('encodes the canonical x/y object', () {
      final offset = ProjectedShadowOffset(x: 0, y: -2.5);

      expect(
        encodeProjectedShadowOffset(offset),
        <String, Object?>{'x': 0, 'y': -2.5},
      );
    });

    test(
        'decodes positive, zero, and negative offsets with unknown keys ignored',
        () {
      final offset = decodeProjectedShadowOffset(<String, Object?>{
        'x': 3.25,
        'y': -2.5,
        'note': 'local tweak',
      });

      expect(offset, ProjectedShadowOffset(x: 3.25, y: -2.5));
      expect(
        encodeProjectedShadowOffset(offset),
        <String, Object?>{'x': 3.25, 'y': -2.5},
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowOffset(
        ProjectedShadowOffset(x: 0, y: -2.5),
      );

      expect(
        encodeProjectedShadowOffset(decodeProjectedShadowOffset(encoded)),
        encoded,
      );
    });

    test('rejects missing and non-numeric coordinates', () {
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{'y': -2.5}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{'x': 0}),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowOffset(<String, Object?>{
          'x': 0,
          'y': double.infinity,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowShapeTuning JSON codec', () {
    test('encodes the canonical shape object', () {
      final shape = ProjectedShadowShapeTuning(
        lengthRatio: 0.28,
        nearWidthRatio: 0.85,
        farWidthRatio: 0.75,
      );

      expect(
        encodeProjectedShadowShapeTuning(shape),
        <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        },
      );
    });

    test('decodes the canonical shape object and ignores unknown keys', () {
      final shape = decodeProjectedShadowShapeTuning(<String, Object?>{
        'lengthRatio': 0.28,
        'nearWidthRatio': 0.85,
        'farWidthRatio': 0.75,
        'legacyWidth': 12,
      });

      expect(
        shape,
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );
      expect(
        encodeProjectedShadowShapeTuning(shape),
        <String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        },
      );
    });

    test('round-trips through the canonical object', () {
      final encoded = encodeProjectedShadowShapeTuning(
        ProjectedShadowShapeTuning(
          lengthRatio: 0.28,
          nearWidthRatio: 0.85,
          farWidthRatio: 0.75,
        ),
      );

      expect(
        encodeProjectedShadowShapeTuning(
          decodeProjectedShadowShapeTuning(encoded),
        ),
        encoded,
      );
    });

    test('rejects missing fields and invalid ratios', () {
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': -0.01,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0,
          'farWidthRatio': 0.75,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowShapeTuning(<String, Object?>{
          'lengthRatio': 0.28,
          'nearWidthRatio': 0.85,
          'farWidthRatio': 'wide',
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowAppearance JSON codec', () {
    test('encodes the canonical appearance object with uppercase color', () {
      final appearance = ProjectedShadowAppearance(
        opacity: 0.18,
        colorHexRgb: 'abcdef',
      );

      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': 'ABCDEF'},
      );
    });

    test('decodes the canonical appearance object and ignores unknown keys',
        () {
      final appearance = decodeProjectedShadowAppearance(<String, Object?>{
        'opacity': 0.18,
        'colorHexRgb': '000000',
        'debugColorName': 'soft black',
      });

      expect(
        appearance,
        ProjectedShadowAppearance(opacity: 0.18, colorHexRgb: '000000'),
      );
      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': '000000'},
      );
    });

    test('round-trips lowercase color as uppercase', () {
      final appearance = decodeProjectedShadowAppearance(<String, Object?>{
        'opacity': 0.18,
        'colorHexRgb': 'abcdef',
      });

      expect(appearance.colorHexRgb, 'ABCDEF');
      expect(
        encodeProjectedShadowAppearance(appearance),
        <String, Object?>{'opacity': 0.18, 'colorHexRgb': 'ABCDEF'},
      );
    });

    test('accepts opacity boundaries', () {
      expect(
        decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0,
          'colorHexRgb': '000000',
        }).opacity,
        0,
      );
      expect(
        decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 1,
          'colorHexRgb': 'FFFFFF',
        }).opacity,
        1,
      );
    });

    test('rejects missing fields and invalid appearance values', () {
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': -0.01,
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 1.01,
          'colorHexRgb': '000000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': '00000',
        }),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowAppearance(<String, Object?>{
          'opacity': 0.18,
          'colorHexRgb': 0,
        }),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowTimeOfDayMode JSON codec', () {
    test('encodes fixed and followsSun', () {
      expect(
        encodeProjectedShadowTimeOfDayMode(ProjectedShadowTimeOfDayMode.fixed),
        'fixed',
      );
      expect(
        encodeProjectedShadowTimeOfDayMode(
          ProjectedShadowTimeOfDayMode.followsSun,
        ),
        'followsSun',
      );
    });

    test('decodes fixed and followsSun', () {
      expect(
        decodeProjectedShadowTimeOfDayMode('fixed'),
        ProjectedShadowTimeOfDayMode.fixed,
      );
      expect(
        decodeProjectedShadowTimeOfDayMode('followsSun'),
        ProjectedShadowTimeOfDayMode.followsSun,
      );
    });

    test('rejects unknown, non-string, and wrongly-cased values', () {
      expect(
        () => decodeProjectedShadowTimeOfDayMode('moonlight'),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowTimeOfDayMode(0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectedShadowTimeOfDayMode('FollowsSun'),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedBuildingShadowCasterKind JSON codec', () {
    test('encodes building', () {
      expect(
        encodeProjectedBuildingShadowCasterKind(
          ProjectedBuildingShadowCasterKind.building,
        ),
        'building',
      );
    });

    test('encodes largeVolume', () {
      expect(
        encodeProjectedBuildingShadowCasterKind(
          ProjectedBuildingShadowCasterKind.largeVolume,
        ),
        'largeVolume',
      );
    });

    test('decodes building', () {
      expect(
        decodeProjectedBuildingShadowCasterKind('building'),
        ProjectedBuildingShadowCasterKind.building,
      );
    });

    test('decodes largeVolume', () {
      expect(
        decodeProjectedBuildingShadowCasterKind('largeVolume'),
        ProjectedBuildingShadowCasterKind.largeVolume,
      );
    });

    test('rejects unknown string', () {
      expect(
        () => decodeProjectedBuildingShadowCasterKind('lampPost'),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-string', () {
      expect(
        () => decodeProjectedBuildingShadowCasterKind(1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects null', () {
      expect(
        () => decodeProjectedBuildingShadowCasterKind(null),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}
```

### packages/map_core/test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectElementProjectedBuildingShadowConfig JSON codec', () {
    test('encodes canonical config with enabled true', () {
      final config = _config();

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(),
      );
    });

    test('encodes enabled false while keeping explicit preset and placement',
        () {
      final config = _config(enabled: false);

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(enabled: false),
      );
    });

    test('omits casterKind when null', () {
      final encoded = encodeProjectElementProjectedBuildingShadowConfig(
        _config(),
      );

      expect(encoded.containsKey('casterKind'), isFalse);
      expect(encoded, _configJson());
    });

    test('encodes building casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(casterKind: 'building'),
      );
    });

    test('encodes largeVolume casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.largeVolume,
      );

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(config),
        _configJson(casterKind: 'largeVolume'),
      );
    });

    test('decodes canonical config with enabled true', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(),
      );

      expect(config.enabled, isTrue);
      expect(config.presetId, 'short-west-building-shadow');
      expect(config.anchor, ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.98));
      expect(config.localOffset, ProjectedShadowOffset(x: 0, y: 0));
    });

    test('decodes missing casterKind as null', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(),
      );

      expect(config.casterKind, isNull);
    });

    test('decodes explicit null casterKind as null', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(casterKind: null),
      );

      expect(config.casterKind, isNull);
    });

    test('decodes building casterKind', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(casterKind: 'building'),
      );

      expect(config.casterKind, ProjectedBuildingShadowCasterKind.building);
    });

    test('decodes largeVolume casterKind', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(casterKind: 'largeVolume'),
      );

      expect(config.casterKind, ProjectedBuildingShadowCasterKind.largeVolume);
    });

    test('decodes canonical config with enabled false', () {
      final config = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(enabled: false),
      );

      expect(config, _config(enabled: false));
    });

    test('round-trips config instances through canonical JSON', () {
      final config = _config(
        enabled: false,
        presetId: 'long-east-building-shadow',
        anchorXRatio: 0.25,
        anchorYRatio: 0.9,
        offsetX: 3,
        offsetY: -2.5,
      );

      expect(
        decodeProjectElementProjectedBuildingShadowConfig(
          encodeProjectElementProjectedBuildingShadowConfig(config),
        ),
        config,
      );
    });

    test('round-trips config with casterKind', () {
      final config = _config(
        casterKind: ProjectedBuildingShadowCasterKind.building,
      );

      expect(
        decodeProjectElementProjectedBuildingShadowConfig(
          encodeProjectElementProjectedBuildingShadowConfig(config),
        ),
        config,
      );
    });

    test('round-trips JSON without re-emitting unknown keys', () {
      final json = _configJson(
        localOffset: _offsetJson(x: 3, y: -2.5),
      )
        ..['futureField'] = 'ignored'
        ..['anchor'] = (_anchorJson()..['futureAnchorField'] = true)
        ..['localOffset'] =
            (_offsetJson(x: 3, y: -2.5)..['futureOffsetField'] = true);

      expect(
        encodeProjectElementProjectedBuildingShadowConfig(
          decodeProjectElementProjectedBuildingShadowConfig(json),
        ),
        _configJson(localOffset: _offsetJson(x: 3, y: -2.5)),
      );
    });

    test('round-trips legacy JSON without re-emitting casterKind', () {
      final decoded = decodeProjectElementProjectedBuildingShadowConfig(
        _configJson(),
      );
      final encoded = encodeProjectElementProjectedBuildingShadowConfig(
        decoded,
      );

      expect(decoded.casterKind, isNull);
      expect(encoded.containsKey('casterKind'), isFalse);
      expect(encoded, _configJson());
    });

    test('rejects missing required fields', () {
      for (final field in <String>[
        'enabled',
        'presetId',
        'anchor',
        'localOffset',
      ]) {
        expect(
          () => decodeProjectElementProjectedBuildingShadowConfig(
            _without(_configJson(), field),
          ),
          throwsA(isA<ValidationException>()),
          reason: '$field should be required',
        );
      }
    });

    test('rejects invalid field types', () {
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(enabled: 'yes'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(presetId: 42),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(anchor: 'south-door'),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(localOffset: 'origin'),
        ),
        throwsA(isA<ValidationException>()),
      );
      for (final casterKind in <Object?>[
        1,
        true,
        <String, Object?>{},
        <Object?>[],
      ]) {
        expect(
          () => decodeProjectElementProjectedBuildingShadowConfig(
            _configJson(casterKind: casterKind),
          ),
          throwsA(isA<ValidationException>()),
        );
      }
    });

    test('rejects invalid values delegated to model and value objects', () {
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(presetId: ''),
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(
            anchor: _anchorJson(xRatio: 1.01),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(
            localOffset: _offsetJson(x: double.nan),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => decodeProjectElementProjectedBuildingShadowConfig(
          _configJson(casterKind: 'lampPost'),
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });
}

const Object _absent = Object();

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'short-west-building-shadow',
  double anchorXRatio = 0.5,
  double anchorYRatio = 0.98,
  double offsetX = 0,
  double offsetY = 0,
  ProjectedBuildingShadowCasterKind? casterKind,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(
      xRatio: anchorXRatio,
      yRatio: anchorYRatio,
    ),
    localOffset: ProjectedShadowOffset(x: offsetX, y: offsetY),
    casterKind: casterKind,
  );
}

Map<String, Object?> _configJson({
  Object? enabled = true,
  Object? presetId = 'short-west-building-shadow',
  Object? anchor,
  Object? localOffset,
  Object? casterKind = _absent,
}) {
  return <String, Object?>{
    'enabled': enabled,
    'presetId': presetId,
    'anchor': anchor ?? _anchorJson(),
    'localOffset': localOffset ?? _offsetJson(),
    if (!identical(casterKind, _absent)) 'casterKind': casterKind,
  };
}

Map<String, Object?> _anchorJson({
  Object? xRatio = 0.5,
  Object? yRatio = 0.98,
}) {
  return <String, Object?>{
    'xRatio': xRatio,
    'yRatio': yRatio,
  };
}

Map<String, Object?> _offsetJson({
  Object? x = 0,
  Object? y = 0,
}) {
  return <String, Object?>{
    'x': x,
    'y': y,
  };
}

Map<String, Object?> _without(Map<String, Object?> source, String key) {
  return Map<String, Object?>.from(source)..remove(key);
}
```

Checklist finale :

- [x] AGENTS.md lu
- [x] Aucun git write effectué
- [x] Aucun fichier runtime modifié
- [x] Aucun fichier editor modifié
- [x] Aucun resolver géométrique modifié
- [x] Aucune opération effective modifiée
- [x] Aucun diagnostics modifié
- [x] Aucun ProjectBuildingShadowPreset JSON modifié
- [x] Aucun footprintStrategy JSON ajouté
- [x] Aucun generated créé
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Codec casterKind dédié ajouté
- [x] building encode testé
- [x] largeVolume encode testé
- [x] building decode testé
- [x] largeVolume decode testé
- [x] Valeur inconnue rejetée
- [x] Type non string rejeté
- [x] Null rejeté par codec dédié
- [x] Config JSON omet casterKind null
- [x] Config JSON encode building
- [x] Config JSON encode largeVolume
- [x] Config JSON decode casterKind absent en null
- [x] Config JSON decode casterKind null explicite en null
- [x] Config JSON decode building
- [x] Config JSON decode largeVolume
- [x] Config JSON rejette casterKind inconnu
- [x] Config JSON rejette casterKind non string
- [x] Round-trip config avec casterKind testé
- [x] Round-trip legacy sans réémission casterKind testé
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] dart test test/shadow_v2 passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
