# ShadowV2-58 — Projected Building Shadow Adaptive Depth Core Model V0

## 1. Résumé exécutif

ShadowV2-58 ajoute uniquement des value objects purs dans `map_core` pour préparer la future stratégie Adaptive C+ sans la brancher. Le modèle conserve `ProjectedBuildingShadowGeometryMode.footprint`; aucun `adaptiveFootprint` n'a été créé.

Types ajoutés :

- `ProjectedShadowFootprintTuningStrategy`
- `ProjectedShadowFootprintFixedTuning`
- `ProjectedShadowFootprintAdaptiveDepthTuning`
- `ProjectedShadowAdaptiveDepthGate`
- `ProjectedBuildingShadowCasterKind`

Le lot ajoute aussi un test ciblé `projected_shadow_footprint_strategy_test.dart` couvrant stockage, validations, equality/hashCode, defaults du gate, opacités, caster kind, et conservation des defaults `ProjectedShadowFootprintTuning()`.

## 2. Objectif du lot

Objectif exécuté :

```text
Créer les value objects purs nécessaires à la future stratégie Adaptive C+ dans map_core,
sans brancher le resolver,
sans JSON,
sans runtime,
sans editor,
sans renderer/painter,
sans Selbrume,
sans screenshot,
sans baseline.
```

Ce lot reste volontairement limité au modèle pur. La dérivation du tuning effectif, le guard building-only / largeVolume, le resolver, le JSON, le runtime et l'éditeur restent hors scope.

## 3. Rappel ShadowV2-57

Le Lot 57 a retenu :

- pas de nouveau `ProjectedBuildingShadowGeometryMode.adaptiveFootprint` ;
- `geometryMode` reste `footprint` ;
- l'adaptive devient une stratégie de tuning explicite ;
- `fixed` reste la base stable ;
- `adaptiveHeightDepth` est un candidat explicite ;
- un futur guard `building` / `largeVolume` est obligatoire ;
- JSON/persistence et resolver restent hors scope du Lot 58.

## 4. État initial du worktree

Commande exécutée avant modification :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Fichiers préexistants non liés au lot : Aucun.

## 5. Lecture AGENTS.md et méthode suivie

Commandes exécutées avant modification :

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

Preuve de lecture AGENTS.md, éléments appliqués :

- monorepo sans orchestrateur, commandes package par package ;
- `map_core` est pure Dart et ne doit pas importer Flutter / Flame ;
- git write interdit ;
- vérifier le worktree avant et après ;
- pour les lots, inclure inventaire complet, commandes, résultats et contenu complet des fichiers texte/code créés ou modifiés ;
- utiliser les skills pertinents avant l'exécution ;
- appliquer TDD pour les nouveaux comportements quand faisable ;
- vérifier avant d'annoncer la complétion.

`skills/README.md` a été vérifié :

```bash
if [ -f skills/README.md ]; then sed -n '1,220p' skills/README.md; else printf 'skills/README.md absent\n'; fi
```

Sortie :

```text
skills/README.md absent
```

Skills réellement utilisés :

- `superpowers:using-superpowers` : discipline de chargement des skills.
- `superpowers:test-driven-development` : test créé avant le code modèle, échec RED observé.
- `superpowers:verification-before-completion` : validations fraîches avant clôture.
- `superpowers:systematic-debugging` : chargé pour traiter toute erreur éventuelle, non nécessaire car les validations finales passent.
- `karpathy-guidelines` : scope minimal, pas d'abstraction spéculative, pas de modifications hors lot.

AGENTS.md ne demandait pas de sub-agent obligatoire pour ce lot. Méthode réellement suivie :

- Pass 1 — Audit modèle actuel.
- Pass 2 — Implémentation value objects.
- Pass 3 — Tests/analyze.
- Pass 4 — Evidence/report.

## 6. Fichiers créés / modifiés / supprimés

Créés par ShadowV2-58 :

- `packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart`
- `reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md`

Modifiés par ShadowV2-58 :

- `packages/map_core/lib/src/models/projected_building_shadow.dart`

Supprimés par ShadowV2-58 : Aucun.

Fichiers hors scope préexistants : Aucun détecté au `git status` initial.

Generated créés : Aucun.

Screenshots / baselines créés : Aucun.

## 7. Audit initial modèle / style

Commande d'audit exécutée avant modification :

```bash
rg -n "ProjectedShadowFootprintTuning|ProjectedBuildingShadowGeometryMode|ProjectBuildingShadowPreset|ProjectedShadowAppearance|ProjectElementProjectedBuildingShadowConfig|ProjectedShadowTimeOfDayMode|Object.hash|operator ==|hashCode|throw ArgumentError|validate" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/lib/src/validation/validators.dart
```

Constats :

- `projected_building_shadow.dart` regroupe déjà les value objects ShadowV2.
- Les value objects existants utilisent `@immutable`, `final class`, factory publique validante et constructeur privé `const`.
- L'equality est manuelle via `operator ==`.
- Les hashCode utilisent `Object.hash`, `Object.hashAll`, ou le hash du champ quand un seul champ suffit.
- Les validations réutilisent des helpers locaux et `ValidationException`, avec quelques `ArgumentError.value` existants pour les listes/catalogues.
- `ProjectedShadowFootprintTuning()` possède déjà ses defaults fixes et ne devait pas changer.
- `sealed class` est compatible avec le package : `map_core` utilise déjà des `sealed class` et le SDK est `>=3.0.0 <4.0.0`.

Commande contexte Adaptive C+ :

```bash
rg -n "Adaptive C\\+|ProjectedShadowFootprintTuningStrategy|ProjectedShadowAdaptiveDepthGate|ProjectedBuildingShadowCasterKind|adaptiveHeightDepth|building-only|largeVolume|thin_prop_like|caster kind|footprintStrategy" reports/shadows/v2 packages/map_runtime/tool/shadow packages/map_core/lib packages/map_core/test
```

Constats :

- Les rapports ShadowV2-54 à ShadowV2-57 documentent le candidat Adaptive C+.
- Le Lot 56 a validé les endpoints building et le canary `thin_prop_like`.
- Aucun type core `ProjectedShadowFootprintTuningStrategy`, `ProjectedShadowAdaptiveDepthGate` ou `ProjectedBuildingShadowCasterKind` n'existait avant ce lot.

Emplacement choisi :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart
```

Raison : c'est le fichier modèle ShadowV2 existant, et le lot interdit la création d'un fichier modèle séparé sauf exigence du repo. Aucune exigence contraire n'a été trouvée.

## 8. Types ajoutés

Ajouts purs :

- `ProjectedBuildingShadowCasterKind`
- `ProjectedShadowFootprintTuningStrategy`
- `ProjectedShadowFootprintFixedTuning`
- `ProjectedShadowAdaptiveDepthGate`
- `ProjectedShadowFootprintAdaptiveDepthTuning`

Ces types ne sont branchés ni dans `ProjectBuildingShadowPreset`, ni dans `ProjectElementProjectedBuildingShadowConfig`, ni dans le resolver, ni dans JSON, ni dans runtime/editor.

## 9. ProjectedShadowFootprintTuningStrategy

`ProjectedShadowFootprintTuningStrategy` est une base `sealed class` immuable.

Choix :

```dart
@immutable
sealed class ProjectedShadowFootprintTuningStrategy {
  const ProjectedShadowFootprintTuningStrategy();
}
```

Raison :

- `sealed class` est disponible avec le SDK du package.
- Le design Lot 57 veut une stratégie explicite plutôt qu'un nouveau `geometryMode`.
- Le type ne transporte aucune logique de résolution dans ce lot.

## 10. ProjectedShadowFootprintFixedTuning

`ProjectedShadowFootprintFixedTuning` stocke un `ProjectedShadowFootprintTuning` explicite.

Garanties :

- immutable ;
- equality inclut `tuning` ;
- hashCode reflète `tuning` ;
- aucun fallback implicite vers `ProjectedShadowFootprintTuning()` n'est utilisé.

## 11. ProjectedShadowFootprintAdaptiveDepthTuning

`ProjectedShadowFootprintAdaptiveDepthTuning` stocke :

- `base` ;
- `target` ;
- `gate` ;
- `baseOpacity` ;
- `targetOpacity`.

Validations :

- `baseOpacity` doit rester dans `[0, 1]` ;
- `targetOpacity` doit rester dans `[0, 1]`.

Non-invariants volontaires :

- pas d'obligation `target.depthRatio > base.depthRatio` ;
- pas d'obligation `targetOpacity < baseOpacity`.

Raison : ces choix sont artistiques, pas des invariants métier universels.

## 12. ProjectedShadowAdaptiveDepthGate

Defaults ajoutés :

```text
referenceHeight = 80
targetHeight = 112
referenceRatio = 1.25
targetRatio = 1.75
```

Validations ajoutées :

- `referenceHeight > 0`
- `targetHeight > 0`
- `targetHeight > referenceHeight`
- `referenceRatio > 0`
- `targetRatio > 0`
- `targetRatio > referenceRatio`

Note de style : le prompt proposait une forme `const ProjectedShadowAdaptiveDepthGate(...)`. Le fichier modèle existant utilise des factories publiques validantes et des constructeurs privés `const`. J'ai donc conservé ce style pour respecter les validations obligatoires.

Aucun calcul `adaptiveT` n'a été ajouté.

## 13. ProjectedBuildingShadowCasterKind

Enum ajouté :

```dart
enum ProjectedBuildingShadowCasterKind {
  building,
  largeVolume,
}
```

Objectif : préparer le futur guard building-only / largeVolume.

Ce lot ne branche pas cet enum à un élément, une instance, un resolver, JSON, runtime ou editor.

Valeurs non ajoutées :

- pas de `thinProp` ;
- pas de `prop` ;
- pas de `lampPost`.

Raison : les props fins restent hors scope.

## 14. Defaults ProjectedShadowFootprintTuning conservés

Test ajouté :

```text
ProjectedShadowFootprintTuning defaults remain unchanged
```

Valeurs vérifiées :

```text
attachYRatio = 0.86
frontWidthRatio = 1.10
rearWidthRatio = 1.20
depthRatio = 0.28
skewXRatio = 0.10
```

Le constructeur existant `ProjectedShadowFootprintTuning()` n'a pas été modifié.

## 15. Ce qui n’a volontairement pas été branché

Non branché dans ce lot :

- `resolveProjectedBuildingShadowGeometry(...)`
- calcul `adaptiveT`
- tuning effectif
- JSON encode/decode
- `ProjectBuildingShadowPreset`
- `ProjectElementProjectedBuildingShadowConfig`
- `ProjectElementEntry`
- runtime adapter
- editor preview
- renderer/painter
- diagnostics
- Selbrume

## 16. Résultats des tests ciblés

RED TDD observé avant implémentation :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_strategy_test.dart
```

Sortie RED principale :

```text
Failed to load "test/shadow_v2/projected_shadow_footprint_strategy_test.dart":
Error: Type 'ProjectedShadowFootprintAdaptiveDepthTuning' not found.
Error: Type 'ProjectedShadowAdaptiveDepthGate' not found.
Error: Undefined name 'ProjectedBuildingShadowCasterKind'.
Some tests failed.
```

GREEN ciblé après implémentation :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_shadow_footprint_strategy_test.dart
```

Sortie complète :

```text
00:01 +0: loading test/shadow_v2/projected_shadow_footprint_strategy_test.dart
00:01 +0: ProjectedShadowFootprintFixedTuning stores explicit tuning
00:01 +1: ProjectedShadowFootprintFixedTuning stores explicit tuning
00:01 +1: ProjectedShadowFootprintFixedTuning equality includes tuning
00:01 +2: ProjectedShadowFootprintFixedTuning equality includes tuning
00:01 +2: ProjectedShadowFootprintFixedTuning hashCode includes tuning
00:01 +3: ProjectedShadowFootprintFixedTuning hashCode includes tuning
00:01 +3: ProjectedShadowAdaptiveDepthGate uses canonical defaults
00:01 +4: ProjectedShadowAdaptiveDepthGate uses canonical defaults
00:01 +4: ProjectedShadowAdaptiveDepthGate equality includes all fields
00:01 +5: ProjectedShadowAdaptiveDepthGate equality includes all fields
00:01 +5: ProjectedShadowAdaptiveDepthGate hashCode includes all fields
00:01 +6: ProjectedShadowAdaptiveDepthGate hashCode includes all fields
00:01 +6: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceHeight
00:01 +7: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceHeight
00:01 +7: ProjectedShadowAdaptiveDepthGate rejects non-positive targetHeight
00:01 +8: ProjectedShadowAdaptiveDepthGate rejects non-positive targetHeight
00:01 +8: ProjectedShadowAdaptiveDepthGate rejects targetHeight equal to referenceHeight
00:01 +9: ProjectedShadowAdaptiveDepthGate rejects targetHeight equal to referenceHeight
00:01 +9: ProjectedShadowAdaptiveDepthGate rejects targetHeight below referenceHeight
00:01 +10: ProjectedShadowAdaptiveDepthGate rejects targetHeight below referenceHeight
00:01 +10: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceRatio
00:01 +11: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceRatio
00:01 +11: ProjectedShadowAdaptiveDepthGate rejects non-positive targetRatio
00:01 +12: ProjectedShadowAdaptiveDepthGate rejects non-positive targetRatio
00:01 +12: ProjectedShadowAdaptiveDepthGate rejects targetRatio equal to referenceRatio
00:01 +13: ProjectedShadowAdaptiveDepthGate rejects targetRatio equal to referenceRatio
00:01 +13: ProjectedShadowAdaptiveDepthGate rejects targetRatio below referenceRatio
00:01 +14: ProjectedShadowAdaptiveDepthGate rejects targetRatio below referenceRatio
00:01 +14: ProjectedShadowFootprintAdaptiveDepthTuning stores base target gate and opacity endpoints
00:01 +15: ProjectedShadowFootprintAdaptiveDepthTuning stores base target gate and opacity endpoints
00:01 +15: ProjectedShadowFootprintAdaptiveDepthTuning equality includes every field
00:01 +16: ProjectedShadowFootprintAdaptiveDepthTuning equality includes every field
00:01 +16: ProjectedShadowFootprintAdaptiveDepthTuning hashCode includes every field
00:01 +17: ProjectedShadowFootprintAdaptiveDepthTuning hashCode includes every field
00:01 +17: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity below 0
00:01 +18: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity below 0
00:01 +18: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity above 1
00:01 +19: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity above 1
00:01 +19: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity below 0
00:01 +20: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity below 0
00:01 +20: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity above 1
00:01 +21: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity above 1
00:01 +21: ProjectedShadowFootprintAdaptiveDepthTuning accepts opacity endpoints 0 and 1
00:01 +22: ProjectedShadowFootprintAdaptiveDepthTuning accepts opacity endpoints 0 and 1
00:01 +22: ProjectedBuildingShadowCasterKind exposes building and largeVolume
00:01 +23: ProjectedBuildingShadowCasterKind exposes building and largeVolume
00:01 +23: ProjectedShadowFootprintTuning defaults remain unchanged
00:01 +24: ProjectedShadowFootprintTuning defaults remain unchanged
00:01 +24: All tests passed!
```

## 17. Résultats des régressions utiles

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_geometry_test.dart
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

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
```

Sortie complète :

```text
00:00 +0: loading test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
00:00 +0: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId
00:00 +1: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId
00:00 +1: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder
00:00 +2: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder
00:00 +2: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals
00:00 +3: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals
00:00 +3: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null
00:00 +4: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null
00:00 +4: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON
00:00 +5: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON
00:00 +5: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys
00:00 +6: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON
00:00 +7: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON
00:00 +7: ProjectBuildingShadowPreset JSON codec rejects missing required fields
00:00 +8: ProjectBuildingShadowPreset JSON codec rejects missing required fields
00:00 +8: ProjectBuildingShadowPreset JSON codec rejects invalid field types
00:00 +9: ProjectBuildingShadowPreset JSON codec rejects invalid field types
00:00 +9: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs
00:00 +10: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs
00:00 +10: All tests passed!
```

## 18. Résultat dart test test/shadow_v2

Commande obligatoire exécutée :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Résultat :

```text
00:01 +192: All tests passed!
```

Commande complémentaire compacte exécutée pour capturer une sortie plus lisible :

```bash
cd packages/map_core && dart test test/shadow_v2 --reporter compact
```

Sortie compacte :

```text
00:00 +0: loading test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart
00:00 +0: test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning uses footprint V0 defaults
00:00 +11: test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec decodes multiple presets preserving order and lookup behavior
00:00 +16: test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection accepts a valid direction and preserves authored values
00:00 +34: test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
00:00 +64: loading test/shadow_v2/project_building_shadow_preset_json_codec_test.dart
00:00 +77: test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec rejects invalid JSON shape and required fields
00:00 +90: test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data
00:00 +130: loading test/shadow_v2/projected_building_shadow_diagnostics_test.dart
00:00 +137: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning stores explicit tuning
00:00 +147: test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate uses canonical defaults
00:00 +164: test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts an empty catalog
00:00 +180: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points
00:00 +191: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +192: test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +192: All tests passed!
```

Commande complémentaire avec reporter GitHub pour sortie complète lisible :

```bash
cd packages/map_core && dart test test/shadow_v2 --reporter github
```

Sortie :

```text
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning uses footprint V0 defaults
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec encodes an empty catalog canonically
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning uses value equality and matching hashCode
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec decodes an empty catalog
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid attachYRatio values
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid frontWidthRatio values
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec encodes multiple presets preserving order
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectManifest without projectedBuildingShadowCatalog decodes an empty catalog and omits the root on toJson
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid rearWidthRatio values
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec decodes multiple presets preserving order and lookup behavior
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid depthRatio values
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectManifest with projectedBuildingShadowCatalog null decodes empty and omits the root on toJson
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectedShadowFootprintTuning rejects invalid skewXRatio values
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec round-trips catalog instances through canonical JSON
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectManifest rejects an object projectedBuildingShadowCatalog without presets
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec round-trips JSON without re-emitting unknown keys
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode defaults to directional geometry mode
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectManifest with empty projectedBuildingShadowCatalog presets decodes empty and omits the root on toJson
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts directional without footprint
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec rejects invalid catalog shape
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects directional with footprint
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec rejects invalid preset items
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode accepts footprint with footprint tuning
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode rejects footprint without footprint tuning
✅ test/shadow_v2/project_building_shadow_preset_catalog_json_codec_test.dart: ProjectBuildingShadowPresetCatalog JSON codec rejects duplicate preset ids through the catalog model
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection accepts a valid direction and preserves authored values
✅ test/shadow_v2/projected_building_shadow_footprint_tuning_test.dart: ProjectBuildingShadowPreset footprint mode equality and hashCode include geometryMode and footprint
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectManifest with non-empty projectedBuildingShadowCatalog round-trips and emits the root
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection refuses non-finite values
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectElementEntry without projectedBuildingShadow decodes null and omits the field on toJson
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection refuses zero vector
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow null decodes null and omits the field on toJson
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection exposes a normalized direction without mutating authored values
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowDirection uses value equality
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectElementEntry with projectedBuildingShadow round-trips and emits the field
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAnchor accepts boundary and authored anchor ratios
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAnchor refuses ratios outside zero to one
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAnchor refuses non-finite ratios
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration ProjectElementEntry preserves V1 shadow and V2 projectedBuildingShadow together
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAnchor uses value equality
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration existing V1-only manifest round-trip stays free of projected building shadow output
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowOffset accepts positive, negative, and zero values
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowOffset refuses non-finite values
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowOffset uses value equality
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes canonical config with enabled true
✅ test/shadow_v2/projected_building_shadow_manifest_element_integration_test.dart: ShadowV2 manifest and element persistence integration copyWith can replace manifest catalog and element config
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowShapeTuning accepts zero and positive length with positive widths
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec encodes enabled false while keeping explicit preset and placement
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowShapeTuning refuses invalid ratios
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled true
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowShapeTuning refuses non-finite ratios
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec decodes canonical config with enabled false
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowShapeTuning uses value equality
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips config instances through canonical JSON
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec round-trips JSON without re-emitting unknown keys
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAppearance accepts opacity boundaries and intermediate values
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAppearance refuses invalid opacity values
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec rejects missing required fields
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAppearance accepts and normalizes RGB hex colors
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAppearance refuses invalid RGB hex colors
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid field types
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowAppearance uses value equality with normalized color
✅ test/shadow_v2/project_element_projected_building_shadow_config_json_codec_test.dart: ProjectElementProjectedBuildingShadowConfig JSON codec rejects invalid values delegated to model and value objects
✅ test/shadow_v2/projected_building_shadow_value_objects_test.dart: ProjectedShadowTimeOfDayMode contains only fixed and followsSun placeholders
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes canonical preset JSON without categoryId
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec encodes categoryId when non-null and always emits sortOrder
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec decodes canonical preset JSON with defaults for omitted optionals
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec decodes categoryId null as null
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec round-trips preset instances through canonical JSON
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec round-trips JSON without re-emitting unknown keys
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects null and non-map preset JSON
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects missing required fields
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects invalid field types
✅ test/shadow_v2/project_building_shadow_preset_json_codec_test.dart: ProjectBuildingShadowPreset JSON codec rejects invalid values delegated to model and atomic codecs
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec encodes the canonical x/y object
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec decodes the canonical x/y object and ignores unknown keys
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec round-trips through the canonical object
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowDirection JSON codec rejects invalid JSON shape and required fields
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled true and stores all values
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAnchor JSON codec encodes the canonical xRatio/yRatio object
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig accepts enabled false and preserves preset intent
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAnchor JSON codec decodes the canonical ratio object and ignores unknown keys
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAnchor JSON codec round-trips through the canonical object
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig rejects blank preset ids
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAnchor JSON codec rejects missing fields and invalid ratios
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig stores spaced preset ids unchanged
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowOffset JSON codec encodes the canonical x/y object
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig composes valid anchor and positive or negative offsets
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowOffset JSON codec decodes positive, zero, and negative offsets with unknown keys ignored
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowOffset JSON codec round-trips through the canonical object
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowOffset JSON codec rejects missing and non-numeric coordinates
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig uses value equality and matching hashCode
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowShapeTuning JSON codec encodes the canonical shape object
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowShapeTuning JSON codec decodes the canonical shape object and ignores unknown keys
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes enabled
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowShapeTuning JSON codec round-trips through the canonical object
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes presetId
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes anchor
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowShapeTuning JSON codec rejects missing fields and invalid ratios
✅ test/shadow_v2/projected_building_shadow_element_config_test.dart: ProjectElementProjectedBuildingShadowConfig value equality includes localOffset
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec encodes the canonical appearance object with uppercase color
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec decodes the canonical appearance object and ignores unknown keys
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec round-trips lowercase color as uppercase
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec accepts opacity boundaries
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowAppearance JSON codec rejects missing fields and invalid appearance values
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowTimeOfDayMode JSON codec encodes fixed and followsSun
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowTimeOfDayMode JSON codec decodes fixed and followsSun
✅ test/shadow_v2/projected_shadow_value_object_json_codecs_test.dart: ProjectedShadowTimeOfDayMode JSON codec rejects unknown, non-string, and wrongly-cased values
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores the parametric projected building shadow fields
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset stores a non-null category id
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset uses sortOrder zero by default
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset refuses blank id values while preserving valid raw ids
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset refuses blank name values while preserving valid raw names
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset validates optional category id
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset uses value equality for identical presets
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes id
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes name
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes direction
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes shape
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes appearance
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes timeOfDayMode
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization ProjectManifest JSON without projected building shadow fields round-trips unchanged for known Shadow V1 data
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes categoryId
✅ test/shadow_v2/projected_building_shadow_preset_test.dart: ProjectBuildingShadowPreset value equality includes sortOrder
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization ProjectElementEntry JSON without projected building shadow keeps no V2 keys after round-trip
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization ProjectShadowCatalog JSON remains V1-only and does not emit V2 projected building presets
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization unknown root future catalog keys are accepted by ProjectManifest.fromJson and dropped by toJson
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization unknown element future projected shadow key is accepted and dropped by ProjectElementEntry.toJson
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization migrateProjectManifestJson currently preserves V2-like unknown keys by identity
✅ test/shadow_v2/projected_building_shadow_json_characterization_test.dart: ShadowV2 projected building shadow JSON characterization Selbrume-like synthetic V1 shadow sample round-trips without V2 keys
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returns no diagnostics for active element referencing existing preset
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports active missing preset as error
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports disabled missing preset as warning
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports unused preset as warning
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics disabled config counts as preset usage without extra noise
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports V1 and enabled V2 coexistence as warning
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports coexistence for any non-null V1 shadow config
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics does not report V1 and V2 coexistence when V2 is disabled
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports active followsSun preset as info
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics reports followsSun unused preset only as unused warning
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics does not report followsSun when referenced only by disabled configs
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics keeps stable element diagnostics then catalog diagnostics order
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics diagnostic equality includes all fields
✅ test/shadow_v2/projected_building_shadow_diagnostics_test.dart: Projected building shadow diagnostics returned diagnostics list is unmodifiable
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning stores explicit tuning
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning equality includes tuning
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintFixedTuning hashCode includes tuning
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate uses canonical defaults
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate equality includes all fields
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate hashCode includes all fields
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceHeight
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects non-positive targetHeight
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects targetHeight equal to referenceHeight
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects targetHeight below referenceHeight
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects non-positive referenceRatio
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects non-positive targetRatio
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects targetRatio equal to referenceRatio
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowAdaptiveDepthGate rejects targetRatio below referenceRatio
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning stores base target gate and opacity endpoints
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning equality includes every field
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning hashCode includes every field
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity below 0
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning rejects baseOpacity above 1
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity below 0
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning rejects targetOpacity above 1
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintAdaptiveDepthTuning accepts opacity endpoints 0 and 1
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry disabled config returns null
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedBuildingShadowCasterKind exposes building and largeVolume
✅ test/shadow_v2/projected_shadow_footprint_strategy_test.dart: ProjectedShadowFootprintTuning defaults remain unchanged
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves basic horizontal geometry with stable point order
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry normalizes direction before applying length
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts an empty catalog
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves vertical direction geometry
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry localOffset shifts all points
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry shape ratios control length and widths
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry propagates preset appearance
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog accepts presets and preserves order
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry followsSun uses preset direction as fixed in V0
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog looks up presets by exact id
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves footprint geometry with attached skewed rectangle points
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog rejects duplicate preset ids
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog defensively copies the source list
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog exposes an unmodifiable presets list
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry footprint geometry localOffset shifts all points
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry footprint geometry ignores anchor
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
✅ test/shadow_v2/projected_building_shadow_preset_catalog_test.dart: ProjectBuildingShadowPresetCatalog uses ordered value equality and matching hashCode
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry point and geometry equality include ordered values
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry validates points, opacity, and color
✅ test/shadow_v2/projected_building_shadow_geometry_test.dart: Projected building shadow geometry geometry source stays independent from runtime editor and manifest

🎉 192 tests passed.
```

## 19. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze lib/src/models/projected_building_shadow.dart test/shadow_v2/projected_shadow_footprint_strategy_test.dart
```

Sortie complète :

```text
Analyzing projected_building_shadow.dart, projected_shadow_footprint_strategy_test.dart...
No issues found!
```

## 20. Audit anti-dérive

Commande obligatoire :

```bash
rg -n "adaptiveFootprint|genericProjection|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|build_runner|toJson|fromJson|Json|json|runtime|editor" packages/map_core/lib/src/models/projected_building_shadow.dart packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart
```

Sortie :

```text
packages/map_core/lib/src/models/projected_building_shadow.dart:10:/// inspect the clock, or affect runtime rendering.
packages/map_core/lib/src/models/projected_building_shadow.dart:28:/// The raw values are intentionally preserved so the editor can keep the
packages/map_core/lib/src/models/projected_building_shadow.dart:452:/// This model is intentionally not connected to JSON, manifests, runtime
packages/map_core/lib/src/models/projected_building_shadow.dart:453:/// resolution, or editor UI in ShadowV2-5.
packages/map_core/lib/src/models/projected_building_shadow.dart:550:/// manifest integration, default presets, editor behavior, or runtime behavior.
packages/map_core/lib/src/models/projected_building_shadow.dart:633:/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
```

Justification :

- ces hits sont des commentaires de séparation déjà présents dans `projected_building_shadow.dart` ;
- aucun hit ne vient du fichier de test créé ;
- aucun hit interdit n'apparaît dans le diff ajouté par ShadowV2-58.

Commande complémentaire diff-scoped :

```bash
git diff -U0 -- packages/map_core/lib/src/models/projected_building_shadow.dart | rg -n "adaptiveFootprint|genericProjection|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|build_runner|toJson|fromJson|Json|json|runtime|editor" || true
```

Sortie :

```text
```

## 21. Ce qui n’a volontairement pas été modifié

Aucun changement dans :

- `packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_json_codec.dart`
- `packages/map_core/lib/src/operations/project_building_shadow_preset_catalog_json_codec.dart`
- `packages/map_core/lib/src/operations/projected_shadow_value_object_json_codecs.dart`
- `packages/map_core/lib/src/models/project_manifest.dart`
- `packages/map_core/lib/src/models/map_data.dart`
- `packages/map_runtime/**`
- `packages/map_editor/**`
- `packages/map_gameplay/**`
- `packages/map_battle/**`
- `examples/**`
- `reports/shadows/screenshots/**`
- `reports/shadows/baselines/**`
- `/Users/karim/Desktop/selbrume/**`
- `project.json`

## 22. Ce qui n’a volontairement pas été créé

Non créés :

- `*.g.dart`
- `*.freezed.dart`
- `*.golden`
- baseline
- screenshot
- image
- nouveau renderer
- nouveau painter
- nouveau codec JSON
- migration
- fixture Selbrume
- adaptive resolver
- runtime adapter support
- editor preview support

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../lib/src/models/projected_building_shadow.dart  | 161 +++++++++++++++++++++
 1 file changed, 161 insertions(+)
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Les fichiers créés non suivis sont listés dans `git status final` et dans l'inventaire du rapport.

## 24. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_core/lib/src/models/projected_building_shadow.dart
```

Note : `git diff --name-status` ne liste pas les fichiers non suivis. Les fichiers créés non suivis sont listés dans `git status final` et dans l'inventaire du rapport.

## 25. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 26. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_core/lib/src/models/projected_building_shadow.dart
?? packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart
?? reports/shadows/v2/shadow_v2_58_projected_building_shadow_adaptive_depth_core_model_v0.md
```

## 27. Risques / réserves

- `ProjectedShadowAdaptiveDepthGate` utilise une factory publique, pas un constructeur public `const`, pour conserver les validations obligatoires au style du fichier.
- Les nouveaux types sont exposés via le barrel existant indirectement parce que `projected_building_shadow.dart` est déjà dans l'API publique de `map_core`.
- Le futur placement du guard building-only / largeVolume n'est pas résolu par ce lot.
- Le calcul `adaptiveT` n'existe pas encore en core.
- JSON/persistence reste à concevoir plus tard.

## 28. Auto-critique

- Le lot est-il bien limité au modèle pur ? Oui : un fichier modèle modifié, un test map_core créé, un rapport créé.
- Le resolver est-il réellement intact ? Oui : aucun fichier d'opération de géométrie n'a été modifié.
- JSON/persistence est-il réellement hors scope ? Oui : aucun codec n'a été modifié et aucun `toJson` / `fromJson` n'a été ajouté.
- Les defaults `ProjectedShadowFootprintTuning()` sont-ils intacts ? Oui : test dédié ajouté et passé.
- L'adaptive est-il représenté comme stratégie et non geometryMode ? Oui : base `ProjectedShadowFootprintTuningStrategy`, pas de nouveau geometryMode.
- Le caster kind est-il présent sans être branché prématurément ? Oui : enum isolé `building` / `largeVolume`.
- Les validations sont-elles suffisantes ? Oui pour ce lot : gate positif/ordonné, opacités dans `[0, 1]`.
- Les tests prouvent-ils l'equality/hashCode ? Oui pour fixed, gate et adaptive.
- Le rapport contient-il toutes les preuves ? Oui, avec inventaire, commandes, sorties, diff et code complet ci-dessous.

## 29. Regard critique sur le prompt

Le prompt est très bien borné : il empêche de transformer une décision de modèle en branchement resolver/JSON trop tôt. Le seul point de tension est la proposition d'un constructeur `const` public pour `ProjectedShadowAdaptiveDepthGate` alors que les validations sont obligatoires et que le style existant du fichier repose sur des factories validantes. Le choix retenu respecte le style local et les validations.

## 30. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-59 — Projected Building Shadow Adaptive Depth Effective Tuning Resolver Design Gate
```

Objectif probable :

```text
Définir comment calculer un tuning effectif depuis ProjectedShadowFootprintAdaptiveDepthTuning,
sans encore brancher le renderer/runtime/editor,
et en intégrant le guard ProjectedBuildingShadowCasterKind.
```

Lot 59 ne doit pas faire :

- brancher le renderer/painter ;
- modifier runtime/editor ;
- ajouter JSON/persistence sans design gate ;
- appliquer Adaptive C+ aux props fins ;
- créer screenshot/baseline ;
- toucher Selbrume.

## 31. Code complet des fichiers créés/modifiés

### Diff complet — `packages/map_core/lib/src/models/projected_building_shadow.dart`

```diff
diff --git a/packages/map_core/lib/src/models/projected_building_shadow.dart b/packages/map_core/lib/src/models/projected_building_shadow.dart
index e826cc73..a985b2ac 100644
--- a/packages/map_core/lib/src/models/projected_building_shadow.dart
+++ b/packages/map_core/lib/src/models/projected_building_shadow.dart
@@ -18,6 +18,11 @@ enum ProjectedBuildingShadowGeometryMode {
   footprint,
 }
 
+enum ProjectedBuildingShadowCasterKind {
+  building,
+  largeVolume,
+}
+
 /// Authored 2D direction for a future projected building shadow.
 ///
 /// The raw values are intentionally preserved so the editor can keep the
@@ -253,6 +258,162 @@ final class ProjectedShadowFootprintTuning {
       );
 }
 
+@immutable
+sealed class ProjectedShadowFootprintTuningStrategy {
+  const ProjectedShadowFootprintTuningStrategy();
+}
+
+@immutable
+final class ProjectedShadowFootprintFixedTuning
+    extends ProjectedShadowFootprintTuningStrategy {
+  const ProjectedShadowFootprintFixedTuning({
+    required this.tuning,
+  });
+
+  final ProjectedShadowFootprintTuning tuning;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectedShadowFootprintFixedTuning && other.tuning == tuning;
+
+  @override
+  int get hashCode => tuning.hashCode;
+}
+
+@immutable
+final class ProjectedShadowAdaptiveDepthGate {
+  factory ProjectedShadowAdaptiveDepthGate({
+    double referenceHeight = 80,
+    double targetHeight = 112,
+    double referenceRatio = 1.25,
+    double targetRatio = 1.75,
+  }) {
+    _validatePositiveFinite(
+      referenceHeight,
+      'ProjectedShadowAdaptiveDepthGate.referenceHeight',
+    );
+    _validatePositiveFinite(
+      targetHeight,
+      'ProjectedShadowAdaptiveDepthGate.targetHeight',
+    );
+    if (targetHeight <= referenceHeight) {
+      throw const ValidationException(
+        'ProjectedShadowAdaptiveDepthGate.targetHeight must be greater than referenceHeight',
+      );
+    }
+    _validatePositiveFinite(
+      referenceRatio,
+      'ProjectedShadowAdaptiveDepthGate.referenceRatio',
+    );
+    _validatePositiveFinite(
+      targetRatio,
+      'ProjectedShadowAdaptiveDepthGate.targetRatio',
+    );
+    if (targetRatio <= referenceRatio) {
+      throw const ValidationException(
+        'ProjectedShadowAdaptiveDepthGate.targetRatio must be greater than referenceRatio',
+      );
+    }
+    return ProjectedShadowAdaptiveDepthGate._(
+      referenceHeight: referenceHeight,
+      targetHeight: targetHeight,
+      referenceRatio: referenceRatio,
+      targetRatio: targetRatio,
+    );
+  }
+
+  const ProjectedShadowAdaptiveDepthGate._({
+    required this.referenceHeight,
+    required this.targetHeight,
+    required this.referenceRatio,
+    required this.targetRatio,
+  });
+
+  final double referenceHeight;
+  final double targetHeight;
+  final double referenceRatio;
+  final double targetRatio;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectedShadowAdaptiveDepthGate &&
+          other.referenceHeight == referenceHeight &&
+          other.targetHeight == targetHeight &&
+          other.referenceRatio == referenceRatio &&
+          other.targetRatio == targetRatio;
+
+  @override
+  int get hashCode => Object.hash(
+        referenceHeight,
+        targetHeight,
+        referenceRatio,
+        targetRatio,
+      );
+}
+
+@immutable
+final class ProjectedShadowFootprintAdaptiveDepthTuning
+    extends ProjectedShadowFootprintTuningStrategy {
+  factory ProjectedShadowFootprintAdaptiveDepthTuning({
+    required ProjectedShadowFootprintTuning base,
+    required ProjectedShadowFootprintTuning target,
+    required ProjectedShadowAdaptiveDepthGate gate,
+    required double baseOpacity,
+    required double targetOpacity,
+  }) {
+    _validateOpacity(
+      baseOpacity,
+      'ProjectedShadowFootprintAdaptiveDepthTuning.baseOpacity',
+    );
+    _validateOpacity(
+      targetOpacity,
+      'ProjectedShadowFootprintAdaptiveDepthTuning.targetOpacity',
+    );
+    return ProjectedShadowFootprintAdaptiveDepthTuning._(
+      base: base,
+      target: target,
+      gate: gate,
+      baseOpacity: baseOpacity,
+      targetOpacity: targetOpacity,
+    );
+  }
+
+  const ProjectedShadowFootprintAdaptiveDepthTuning._({
+    required this.base,
+    required this.target,
+    required this.gate,
+    required this.baseOpacity,
+    required this.targetOpacity,
+  });
+
+  final ProjectedShadowFootprintTuning base;
+  final ProjectedShadowFootprintTuning target;
+  final ProjectedShadowAdaptiveDepthGate gate;
+  final double baseOpacity;
+  final double targetOpacity;
+
+  @override
+  bool operator ==(Object other) =>
+      identical(this, other) ||
+      other is ProjectedShadowFootprintAdaptiveDepthTuning &&
+          other.base == base &&
+          other.target == target &&
+          other.gate == gate &&
+          other.baseOpacity == baseOpacity &&
+          other.targetOpacity == targetOpacity;
+
+  @override
+  int get hashCode => Object.hash(
+        base,
+        target,
+        gate,
+        baseOpacity,
+        targetOpacity,
+      );
+}
+
 /// Simple visual appearance for a future projected building shadow.
 @immutable
 final class ProjectedShadowAppearance {
```

### Diff complet — `packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart`

```diff
diff --git a/packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart b/packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart
new file mode 100644
index 00000000..f7ff67bb
--- /dev/null
+++ b/packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart
@@ -0,0 +1,413 @@
+import 'package:map_core/map_core.dart';
+import 'package:test/test.dart';
+
+void main() {
+  group('ProjectedShadowFootprintFixedTuning', () {
+    test('stores explicit tuning', () {
+      final tuning = _standardTuning();
+
+      final strategy = ProjectedShadowFootprintFixedTuning(tuning: tuning);
+
+      expect(strategy.tuning, tuning);
+      expect(strategy, isA<ProjectedShadowFootprintTuningStrategy>());
+    });
+
+    test('equality includes tuning', () {
+      final first = ProjectedShadowFootprintFixedTuning(
+        tuning: _standardTuning(),
+      );
+      final same = ProjectedShadowFootprintFixedTuning(
+        tuning: _standardTuning(),
+      );
+      final changed = ProjectedShadowFootprintFixedTuning(
+        tuning: _targetTuning(),
+      );
+
+      expect(first, same);
+      expect(first, isNot(changed));
+    });
+
+    test('hashCode includes tuning', () {
+      final first = ProjectedShadowFootprintFixedTuning(
+        tuning: _standardTuning(),
+      );
+      final same = ProjectedShadowFootprintFixedTuning(
+        tuning: _standardTuning(),
+      );
+      final changed = ProjectedShadowFootprintFixedTuning(
+        tuning: _targetTuning(),
+      );
+
+      expect(first.hashCode, same.hashCode);
+      expect(first.hashCode, isNot(changed.hashCode));
+    });
+  });
+
+  group('ProjectedShadowAdaptiveDepthGate', () {
+    test('uses canonical defaults', () {
+      final gate = ProjectedShadowAdaptiveDepthGate();
+
+      expect(gate.referenceHeight, 80);
+      expect(gate.targetHeight, 112);
+      expect(gate.referenceRatio, 1.25);
+      expect(gate.targetRatio, 1.75);
+    });
+
+    test('equality includes all fields', () {
+      final first = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final same = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final changedReferenceHeight = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 80,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final changedTargetHeight = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 140,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final changedReferenceRatio = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.2,
+        targetRatio: 1.9,
+      );
+      final changedTargetRatio = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 2.0,
+      );
+
+      expect(first, same);
+      expect(first, isNot(changedReferenceHeight));
+      expect(first, isNot(changedTargetHeight));
+      expect(first, isNot(changedReferenceRatio));
+      expect(first, isNot(changedTargetRatio));
+    });
+
+    test('hashCode includes all fields', () {
+      final first = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final same = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final changedReferenceHeight = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 80,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final changedTargetHeight = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 140,
+        referenceRatio: 1.1,
+        targetRatio: 1.9,
+      );
+      final changedReferenceRatio = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.2,
+        targetRatio: 1.9,
+      );
+      final changedTargetRatio = ProjectedShadowAdaptiveDepthGate(
+        referenceHeight: 70,
+        targetHeight: 130,
+        referenceRatio: 1.1,
+        targetRatio: 2.0,
+      );
+
+      expect(first.hashCode, same.hashCode);
+      expect(first.hashCode, isNot(changedReferenceHeight.hashCode));
+      expect(first.hashCode, isNot(changedTargetHeight.hashCode));
+      expect(first.hashCode, isNot(changedReferenceRatio.hashCode));
+      expect(first.hashCode, isNot(changedTargetRatio.hashCode));
+    });
+
+    test('rejects non-positive referenceHeight', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(referenceHeight: 0),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(referenceHeight: -1),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects non-positive targetHeight', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(targetHeight: 0),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(targetHeight: -1),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects targetHeight equal to referenceHeight', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(
+          referenceHeight: 80,
+          targetHeight: 80,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects targetHeight below referenceHeight', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(
+          referenceHeight: 80,
+          targetHeight: 79,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects non-positive referenceRatio', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(referenceRatio: 0),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(referenceRatio: -0.1),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects non-positive targetRatio', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(targetRatio: 0),
+        throwsA(isA<ValidationException>()),
+      );
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(targetRatio: -0.1),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects targetRatio equal to referenceRatio', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(
+          referenceRatio: 1.25,
+          targetRatio: 1.25,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects targetRatio below referenceRatio', () {
+      expect(
+        () => ProjectedShadowAdaptiveDepthGate(
+          referenceRatio: 1.25,
+          targetRatio: 1.24,
+        ),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+  });
+
+  group('ProjectedShadowFootprintAdaptiveDepthTuning', () {
+    test('stores base target gate and opacity endpoints', () {
+      final base = _standardTuning();
+      final target = _targetTuning();
+      final gate = ProjectedShadowAdaptiveDepthGate();
+
+      final strategy = ProjectedShadowFootprintAdaptiveDepthTuning(
+        base: base,
+        target: target,
+        gate: gate,
+        baseOpacity: 0.24,
+        targetOpacity: 0.22,
+      );
+
+      expect(strategy.base, base);
+      expect(strategy.target, target);
+      expect(strategy.gate, gate);
+      expect(strategy.baseOpacity, 0.24);
+      expect(strategy.targetOpacity, 0.22);
+      expect(strategy, isA<ProjectedShadowFootprintTuningStrategy>());
+    });
+
+    test('equality includes every field', () {
+      final first = _adaptiveStrategy();
+      final same = _adaptiveStrategy();
+      final changedBase = _adaptiveStrategy(base: _alternateBaseTuning());
+      final changedTarget = _adaptiveStrategy(target: _alternateTargetTuning());
+      final changedGate = _adaptiveStrategy(
+        gate: ProjectedShadowAdaptiveDepthGate(
+          referenceHeight: 70,
+          targetHeight: 120,
+          referenceRatio: 1.2,
+          targetRatio: 1.8,
+        ),
+      );
+      final changedBaseOpacity = _adaptiveStrategy(baseOpacity: 0.25);
+      final changedTargetOpacity = _adaptiveStrategy(targetOpacity: 0.21);
+
+      expect(first, same);
+      expect(first, isNot(changedBase));
+      expect(first, isNot(changedTarget));
+      expect(first, isNot(changedGate));
+      expect(first, isNot(changedBaseOpacity));
+      expect(first, isNot(changedTargetOpacity));
+    });
+
+    test('hashCode includes every field', () {
+      final first = _adaptiveStrategy();
+      final same = _adaptiveStrategy();
+      final changedBase = _adaptiveStrategy(base: _alternateBaseTuning());
+      final changedTarget = _adaptiveStrategy(target: _alternateTargetTuning());
+      final changedGate = _adaptiveStrategy(
+        gate: ProjectedShadowAdaptiveDepthGate(
+          referenceHeight: 70,
+          targetHeight: 120,
+          referenceRatio: 1.2,
+          targetRatio: 1.8,
+        ),
+      );
+      final changedBaseOpacity = _adaptiveStrategy(baseOpacity: 0.25);
+      final changedTargetOpacity = _adaptiveStrategy(targetOpacity: 0.21);
+
+      expect(first.hashCode, same.hashCode);
+      expect(first.hashCode, isNot(changedBase.hashCode));
+      expect(first.hashCode, isNot(changedTarget.hashCode));
+      expect(first.hashCode, isNot(changedGate.hashCode));
+      expect(first.hashCode, isNot(changedBaseOpacity.hashCode));
+      expect(first.hashCode, isNot(changedTargetOpacity.hashCode));
+    });
+
+    test('rejects baseOpacity below 0', () {
+      expect(
+        () => _adaptiveStrategy(baseOpacity: -0.01),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects baseOpacity above 1', () {
+      expect(
+        () => _adaptiveStrategy(baseOpacity: 1.01),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects targetOpacity below 0', () {
+      expect(
+        () => _adaptiveStrategy(targetOpacity: -0.01),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('rejects targetOpacity above 1', () {
+      expect(
+        () => _adaptiveStrategy(targetOpacity: 1.01),
+        throwsA(isA<ValidationException>()),
+      );
+    });
+
+    test('accepts opacity endpoints 0 and 1', () {
+      final strategy = _adaptiveStrategy(baseOpacity: 0, targetOpacity: 1);
+
+      expect(strategy.baseOpacity, 0);
+      expect(strategy.targetOpacity, 1);
+    });
+  });
+
+  group('ProjectedBuildingShadowCasterKind', () {
+    test('exposes building and largeVolume', () {
+      expect(ProjectedBuildingShadowCasterKind.values, [
+        ProjectedBuildingShadowCasterKind.building,
+        ProjectedBuildingShadowCasterKind.largeVolume,
+      ]);
+    });
+  });
+
+  group('ProjectedShadowFootprintTuning defaults', () {
+    test('remain unchanged', () {
+      final tuning = ProjectedShadowFootprintTuning();
+
+      expect(tuning.attachYRatio, 0.86);
+      expect(tuning.frontWidthRatio, 1.10);
+      expect(tuning.rearWidthRatio, 1.20);
+      expect(tuning.depthRatio, 0.28);
+      expect(tuning.skewXRatio, 0.10);
+    });
+  });
+}
+
+ProjectedShadowFootprintTuning _standardTuning() {
+  return ProjectedShadowFootprintTuning(
+    attachYRatio: 0.82,
+    frontWidthRatio: 1.30,
+    rearWidthRatio: 1.42,
+    depthRatio: 0.26,
+    skewXRatio: 0.08,
+  );
+}
+
+ProjectedShadowFootprintTuning _targetTuning() {
+  return ProjectedShadowFootprintTuning(
+    attachYRatio: 0.80,
+    frontWidthRatio: 1.30,
+    rearWidthRatio: 1.47,
+    depthRatio: 0.42,
+    skewXRatio: 0.08,
+  );
+}
+
+ProjectedShadowFootprintTuning _alternateBaseTuning() {
+  return ProjectedShadowFootprintTuning(
+    attachYRatio: 0.81,
+    frontWidthRatio: 1.30,
+    rearWidthRatio: 1.42,
+    depthRatio: 0.26,
+    skewXRatio: 0.08,
+  );
+}
+
+ProjectedShadowFootprintTuning _alternateTargetTuning() {
+  return ProjectedShadowFootprintTuning(
+    attachYRatio: 0.80,
+    frontWidthRatio: 1.32,
+    rearWidthRatio: 1.47,
+    depthRatio: 0.42,
+    skewXRatio: 0.08,
+  );
+}
+
+ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy({
+  ProjectedShadowFootprintTuning? base,
+  ProjectedShadowFootprintTuning? target,
+  ProjectedShadowAdaptiveDepthGate? gate,
+  double baseOpacity = 0.24,
+  double targetOpacity = 0.22,
+}) {
+  return ProjectedShadowFootprintAdaptiveDepthTuning(
+    base: base ?? _standardTuning(),
+    target: target ?? _targetTuning(),
+    gate: gate ?? ProjectedShadowAdaptiveDepthGate(),
+    baseOpacity: baseOpacity,
+    targetOpacity: targetOpacity,
+  );
+}
```

### Contenu complet — `packages/map_core/lib/src/models/projected_building_shadow.dart`

```dart
import 'dart:math' as math;

import 'package:meta/meta.dart' show immutable;

import '../exceptions/map_exceptions.dart';

/// Minimal placeholder for future time-aware projected building shadows.
///
/// ShadowV2-4 only models the authoring intent. It does not interpolate light,
/// inspect the clock, or affect runtime rendering.
enum ProjectedShadowTimeOfDayMode {
  fixed,
  followsSun,
}

enum ProjectedBuildingShadowGeometryMode {
  directional,
  footprint,
}

enum ProjectedBuildingShadowCasterKind {
  building,
  largeVolume,
}

/// Authored 2D direction for a future projected building shadow.
///
/// The raw values are intentionally preserved so the editor can keep the
/// author's intent. Consumers that need a unit vector can use [normalized].
@immutable
final class ProjectedShadowDirection {
  factory ProjectedShadowDirection({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowDirection.x');
    _validateFinite(y, 'ProjectedShadowDirection.y');
    if (x == 0 && y == 0) {
      throw const ValidationException(
        'ProjectedShadowDirection must not be the zero vector',
      );
    }
    return ProjectedShadowDirection._(x: x, y: y);
  }

  const ProjectedShadowDirection._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  double get magnitude => math.sqrt(x * x + y * y);

  ProjectedShadowDirection get normalized {
    final length = magnitude;
    return ProjectedShadowDirection(x: x / length, y: y / length);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowDirection && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Local anchor on the source building asset, expressed as normalized ratios.
@immutable
final class ProjectedShadowAnchor {
  factory ProjectedShadowAnchor({
    required double xRatio,
    required double yRatio,
  }) {
    _validateRatio01(xRatio, 'ProjectedShadowAnchor.xRatio');
    _validateRatio01(yRatio, 'ProjectedShadowAnchor.yRatio');
    return ProjectedShadowAnchor._(xRatio: xRatio, yRatio: yRatio);
  }

  const ProjectedShadowAnchor._({
    required this.xRatio,
    required this.yRatio,
  });

  final double xRatio;
  final double yRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAnchor &&
          other.xRatio == xRatio &&
          other.yRatio == yRatio;

  @override
  int get hashCode => Object.hash(xRatio, yRatio);
}

/// Local authored offset applied after the anchor is resolved.
@immutable
final class ProjectedShadowOffset {
  factory ProjectedShadowOffset({
    required double x,
    required double y,
  }) {
    _validateFinite(x, 'ProjectedShadowOffset.x');
    _validateFinite(y, 'ProjectedShadowOffset.y');
    return ProjectedShadowOffset._(x: x, y: y);
  }

  const ProjectedShadowOffset._({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowOffset && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}

/// Parametric shape tuning for a simple projected building shadow.
@immutable
final class ProjectedShadowShapeTuning {
  factory ProjectedShadowShapeTuning({
    required double lengthRatio,
    required double nearWidthRatio,
    required double farWidthRatio,
  }) {
    _validateNonNegativeFinite(
      lengthRatio,
      'ProjectedShadowShapeTuning.lengthRatio',
    );
    _validatePositiveFinite(
      nearWidthRatio,
      'ProjectedShadowShapeTuning.nearWidthRatio',
    );
    _validatePositiveFinite(
      farWidthRatio,
      'ProjectedShadowShapeTuning.farWidthRatio',
    );
    return ProjectedShadowShapeTuning._(
      lengthRatio: lengthRatio,
      nearWidthRatio: nearWidthRatio,
      farWidthRatio: farWidthRatio,
    );
  }

  const ProjectedShadowShapeTuning._({
    required this.lengthRatio,
    required this.nearWidthRatio,
    required this.farWidthRatio,
  });

  final double lengthRatio;
  final double nearWidthRatio;
  final double farWidthRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowShapeTuning &&
          other.lengthRatio == lengthRatio &&
          other.nearWidthRatio == nearWidthRatio &&
          other.farWidthRatio == farWidthRatio;

  @override
  int get hashCode => Object.hash(
        lengthRatio,
        nearWidthRatio,
        farWidthRatio,
      );
}

/// Parametric footprint tuning for a broad building shadow attached to bounds.
@immutable
final class ProjectedShadowFootprintTuning {
  factory ProjectedShadowFootprintTuning({
    double attachYRatio = 0.86,
    double frontWidthRatio = 1.10,
    double rearWidthRatio = 1.20,
    double depthRatio = 0.28,
    double skewXRatio = 0.10,
  }) {
    _validateRatio01(
      attachYRatio,
      'ProjectedShadowFootprintTuning.attachYRatio',
    );
    _validatePositiveRatioMax(
      frontWidthRatio,
      'ProjectedShadowFootprintTuning.frontWidthRatio',
      2.0,
    );
    _validatePositiveRatioMax(
      rearWidthRatio,
      'ProjectedShadowFootprintTuning.rearWidthRatio',
      2.0,
    );
    _validatePositiveRatioMax(
      depthRatio,
      'ProjectedShadowFootprintTuning.depthRatio',
      1.0,
    );
    _validateFinite(skewXRatio, 'ProjectedShadowFootprintTuning.skewXRatio');
    if (skewXRatio < -0.5 || skewXRatio > 0.5) {
      throw const ValidationException(
        'ProjectedShadowFootprintTuning.skewXRatio must be between -0.5 and 0.5',
      );
    }
    return ProjectedShadowFootprintTuning._(
      attachYRatio: attachYRatio,
      frontWidthRatio: frontWidthRatio,
      rearWidthRatio: rearWidthRatio,
      depthRatio: depthRatio,
      skewXRatio: skewXRatio,
    );
  }

  const ProjectedShadowFootprintTuning._({
    required this.attachYRatio,
    required this.frontWidthRatio,
    required this.rearWidthRatio,
    required this.depthRatio,
    required this.skewXRatio,
  });

  final double attachYRatio;
  final double frontWidthRatio;
  final double rearWidthRatio;
  final double depthRatio;
  final double skewXRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintTuning &&
          other.attachYRatio == attachYRatio &&
          other.frontWidthRatio == frontWidthRatio &&
          other.rearWidthRatio == rearWidthRatio &&
          other.depthRatio == depthRatio &&
          other.skewXRatio == skewXRatio;

  @override
  int get hashCode => Object.hash(
        attachYRatio,
        frontWidthRatio,
        rearWidthRatio,
        depthRatio,
        skewXRatio,
      );
}

@immutable
sealed class ProjectedShadowFootprintTuningStrategy {
  const ProjectedShadowFootprintTuningStrategy();
}

@immutable
final class ProjectedShadowFootprintFixedTuning
    extends ProjectedShadowFootprintTuningStrategy {
  const ProjectedShadowFootprintFixedTuning({
    required this.tuning,
  });

  final ProjectedShadowFootprintTuning tuning;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintFixedTuning && other.tuning == tuning;

  @override
  int get hashCode => tuning.hashCode;
}

@immutable
final class ProjectedShadowAdaptiveDepthGate {
  factory ProjectedShadowAdaptiveDepthGate({
    double referenceHeight = 80,
    double targetHeight = 112,
    double referenceRatio = 1.25,
    double targetRatio = 1.75,
  }) {
    _validatePositiveFinite(
      referenceHeight,
      'ProjectedShadowAdaptiveDepthGate.referenceHeight',
    );
    _validatePositiveFinite(
      targetHeight,
      'ProjectedShadowAdaptiveDepthGate.targetHeight',
    );
    if (targetHeight <= referenceHeight) {
      throw const ValidationException(
        'ProjectedShadowAdaptiveDepthGate.targetHeight must be greater than referenceHeight',
      );
    }
    _validatePositiveFinite(
      referenceRatio,
      'ProjectedShadowAdaptiveDepthGate.referenceRatio',
    );
    _validatePositiveFinite(
      targetRatio,
      'ProjectedShadowAdaptiveDepthGate.targetRatio',
    );
    if (targetRatio <= referenceRatio) {
      throw const ValidationException(
        'ProjectedShadowAdaptiveDepthGate.targetRatio must be greater than referenceRatio',
      );
    }
    return ProjectedShadowAdaptiveDepthGate._(
      referenceHeight: referenceHeight,
      targetHeight: targetHeight,
      referenceRatio: referenceRatio,
      targetRatio: targetRatio,
    );
  }

  const ProjectedShadowAdaptiveDepthGate._({
    required this.referenceHeight,
    required this.targetHeight,
    required this.referenceRatio,
    required this.targetRatio,
  });

  final double referenceHeight;
  final double targetHeight;
  final double referenceRatio;
  final double targetRatio;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAdaptiveDepthGate &&
          other.referenceHeight == referenceHeight &&
          other.targetHeight == targetHeight &&
          other.referenceRatio == referenceRatio &&
          other.targetRatio == targetRatio;

  @override
  int get hashCode => Object.hash(
        referenceHeight,
        targetHeight,
        referenceRatio,
        targetRatio,
      );
}

@immutable
final class ProjectedShadowFootprintAdaptiveDepthTuning
    extends ProjectedShadowFootprintTuningStrategy {
  factory ProjectedShadowFootprintAdaptiveDepthTuning({
    required ProjectedShadowFootprintTuning base,
    required ProjectedShadowFootprintTuning target,
    required ProjectedShadowAdaptiveDepthGate gate,
    required double baseOpacity,
    required double targetOpacity,
  }) {
    _validateOpacity(
      baseOpacity,
      'ProjectedShadowFootprintAdaptiveDepthTuning.baseOpacity',
    );
    _validateOpacity(
      targetOpacity,
      'ProjectedShadowFootprintAdaptiveDepthTuning.targetOpacity',
    );
    return ProjectedShadowFootprintAdaptiveDepthTuning._(
      base: base,
      target: target,
      gate: gate,
      baseOpacity: baseOpacity,
      targetOpacity: targetOpacity,
    );
  }

  const ProjectedShadowFootprintAdaptiveDepthTuning._({
    required this.base,
    required this.target,
    required this.gate,
    required this.baseOpacity,
    required this.targetOpacity,
  });

  final ProjectedShadowFootprintTuning base;
  final ProjectedShadowFootprintTuning target;
  final ProjectedShadowAdaptiveDepthGate gate;
  final double baseOpacity;
  final double targetOpacity;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowFootprintAdaptiveDepthTuning &&
          other.base == base &&
          other.target == target &&
          other.gate == gate &&
          other.baseOpacity == baseOpacity &&
          other.targetOpacity == targetOpacity;

  @override
  int get hashCode => Object.hash(
        base,
        target,
        gate,
        baseOpacity,
        targetOpacity,
      );
}

/// Simple visual appearance for a future projected building shadow.
@immutable
final class ProjectedShadowAppearance {
  factory ProjectedShadowAppearance({
    double opacity = 0.18,
    String colorHexRgb = '000000',
  }) {
    _validateOpacity(opacity, 'ProjectedShadowAppearance.opacity');
    return ProjectedShadowAppearance._(
      opacity: opacity,
      colorHexRgb: _normalizeColorHexRgb(colorHexRgb),
    );
  }

  const ProjectedShadowAppearance._({
    required this.opacity,
    required this.colorHexRgb,
  });

  final double opacity;
  final String colorHexRgb;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectedShadowAppearance &&
          other.opacity == opacity &&
          other.colorHexRgb == colorHexRgb;

  @override
  int get hashCode => Object.hash(opacity, colorHexRgb);
}

/// Reusable parametric preset for a future authored building shadow.
///
/// This model is intentionally not connected to JSON, manifests, runtime
/// resolution, or editor UI in ShadowV2-5.
@immutable
final class ProjectBuildingShadowPreset {
  factory ProjectBuildingShadowPreset({
    required String id,
    required String name,
    required ProjectedShadowDirection direction,
    required ProjectedShadowShapeTuning shape,
    required ProjectedShadowAppearance appearance,
    required ProjectedShadowTimeOfDayMode timeOfDayMode,
    ProjectedBuildingShadowGeometryMode geometryMode =
        ProjectedBuildingShadowGeometryMode.directional,
    ProjectedShadowFootprintTuning? footprint,
    String? categoryId,
    int sortOrder = 0,
  }) {
    _validateNonBlank(id, 'ProjectBuildingShadowPreset.id');
    _validateNonBlank(name, 'ProjectBuildingShadowPreset.name');
    final category = categoryId;
    if (category != null) {
      _validateNonBlank(category, 'ProjectBuildingShadowPreset.categoryId');
    }
    _validateProjectedBuildingShadowGeometryMode(
      geometryMode: geometryMode,
      footprint: footprint,
    );
    return ProjectBuildingShadowPreset._(
      id: id,
      name: name,
      direction: direction,
      shape: shape,
      appearance: appearance,
      timeOfDayMode: timeOfDayMode,
      geometryMode: geometryMode,
      footprint: footprint,
      categoryId: categoryId,
      sortOrder: sortOrder,
    );
  }

  const ProjectBuildingShadowPreset._({
    required this.id,
    required this.name,
    required this.direction,
    required this.shape,
    required this.appearance,
    required this.timeOfDayMode,
    required this.geometryMode,
    required this.footprint,
    required this.categoryId,
    required this.sortOrder,
  });

  final String id;
  final String name;
  final ProjectedShadowDirection direction;
  final ProjectedShadowShapeTuning shape;
  final ProjectedShadowAppearance appearance;
  final ProjectedShadowTimeOfDayMode timeOfDayMode;
  final ProjectedBuildingShadowGeometryMode geometryMode;
  final ProjectedShadowFootprintTuning? footprint;
  final String? categoryId;
  final int sortOrder;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPreset &&
          other.id == id &&
          other.name == name &&
          other.direction == direction &&
          other.shape == shape &&
          other.appearance == appearance &&
          other.timeOfDayMode == timeOfDayMode &&
          other.geometryMode == geometryMode &&
          other.footprint == footprint &&
          other.categoryId == categoryId &&
          other.sortOrder == sortOrder;

  @override
  int get hashCode => Object.hash(
        id,
        name,
        direction,
        shape,
        appearance,
        timeOfDayMode,
        geometryMode,
        footprint,
        categoryId,
        sortOrder,
      );
}

/// Ordered in-memory catalog of future projected building shadow presets.
///
/// ShadowV2-6 keeps this as a pure domain collection. It has no JSON shape,
/// manifest integration, default presets, editor behavior, or runtime behavior.
@immutable
final class ProjectBuildingShadowPresetCatalog {
  ProjectBuildingShadowPresetCatalog({
    List<ProjectBuildingShadowPreset> presets = const [],
  }) : _presets = _copyBuildingShadowPresets(presets);

  const ProjectBuildingShadowPresetCatalog.empty() : _presets = const [];

  final List<ProjectBuildingShadowPreset> _presets;

  /// Presets in authored order. The returned list is unmodifiable.
  List<ProjectBuildingShadowPreset> get presets => _presets;

  int get length => _presets.length;

  bool get isEmpty => _presets.isEmpty;

  bool get isNotEmpty => !isEmpty;

  /// Exact, case-sensitive lookup by [ProjectBuildingShadowPreset.id].
  ProjectBuildingShadowPreset? presetById(String id) {
    for (final preset in _presets) {
      if (preset.id == id) {
        return preset;
      }
    }
    return null;
  }

  bool containsPresetId(String id) => presetById(id) != null;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectBuildingShadowPresetCatalog &&
          _projectBuildingShadowPresetsEqualInOrder(_presets, other._presets);

  @override
  int get hashCode => Object.hashAll(_presets);
}

List<ProjectBuildingShadowPreset> _copyBuildingShadowPresets(
  List<ProjectBuildingShadowPreset> presets,
) {
  final copiedPresets = List<ProjectBuildingShadowPreset>.from(presets);
  _rejectDuplicateBuildingShadowPresetIds(copiedPresets);
  return List<ProjectBuildingShadowPreset>.unmodifiable(copiedPresets);
}

void _rejectDuplicateBuildingShadowPresetIds(
  List<ProjectBuildingShadowPreset> presets,
) {
  final seen = <String>{};
  for (final preset in presets) {
    if (!seen.add(preset.id)) {
      throw ArgumentError.value(
        preset.id,
        'presets',
        'ProjectBuildingShadowPresetCatalog.presets must not contain duplicate ProjectBuildingShadowPreset.id',
      );
    }
  }
}

bool _projectBuildingShadowPresetsEqualInOrder(
  List<ProjectBuildingShadowPreset> a,
  List<ProjectBuildingShadowPreset> b,
) {
  if (a.length != b.length) {
    return false;
  }
  for (var index = 0; index < a.length; index += 1) {
    if (a[index] != b[index]) {
      return false;
    }
  }
  return true;
}

/// Element-level opt-in config for a future projected building shadow.
///
/// ShadowV2-7 keeps this as a pure domain value. It is not attached to
/// ProjectElementEntry, JSON, manifests, runtime resolution, or editor UI.
@immutable
final class ProjectElementProjectedBuildingShadowConfig {
  factory ProjectElementProjectedBuildingShadowConfig({
    required bool enabled,
    required String presetId,
    required ProjectedShadowAnchor anchor,
    required ProjectedShadowOffset localOffset,
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
    );
  }

  const ProjectElementProjectedBuildingShadowConfig._({
    required this.enabled,
    required this.presetId,
    required this.anchor,
    required this.localOffset,
  });

  final bool enabled;
  final String presetId;
  final ProjectedShadowAnchor anchor;
  final ProjectedShadowOffset localOffset;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProjectElementProjectedBuildingShadowConfig &&
          other.enabled == enabled &&
          other.presetId == presetId &&
          other.anchor == anchor &&
          other.localOffset == localOffset;

  @override
  int get hashCode => Object.hash(
        enabled,
        presetId,
        anchor,
        localOffset,
      );
}

void _validateNonBlank(String value, String name) {
  if (value.trim().isEmpty) {
    throw ArgumentError.value(value, name, '$name must be non-empty');
  }
}

void _validateFinite(double value, String name) {
  if (!value.isFinite) {
    throw ValidationException('$name must be finite');
  }
}

void _validateRatio01(double value, String name) {
  _validateFinite(value, name);
  if (value < 0 || value > 1) {
    throw ValidationException('$name must be between 0 and 1');
  }
}

void _validateNonNegativeFinite(double value, String name) {
  _validateFinite(value, name);
  if (value < 0) {
    throw ValidationException('$name must be >= 0');
  }
}

void _validatePositiveFinite(double value, String name) {
  _validateFinite(value, name);
  if (value <= 0) {
    throw ValidationException('$name must be > 0');
  }
}

void _validatePositiveRatioMax(double value, String name, double max) {
  _validatePositiveFinite(value, name);
  if (value > max) {
    throw ValidationException('$name must be <= $max');
  }
}

void _validateProjectedBuildingShadowGeometryMode({
  required ProjectedBuildingShadowGeometryMode geometryMode,
  required ProjectedShadowFootprintTuning? footprint,
}) {
  switch (geometryMode) {
    case ProjectedBuildingShadowGeometryMode.directional:
      if (footprint != null) {
        throw const ValidationException(
          'ProjectBuildingShadowPreset.footprint must be null for directional geometry',
        );
      }
    case ProjectedBuildingShadowGeometryMode.footprint:
      if (footprint == null) {
        throw const ValidationException(
          'ProjectBuildingShadowPreset.footprint is required for footprint geometry',
        );
      }
  }
}

void _validateOpacity(double value, String name) {
  _validateRatio01(value, name);
}

String _normalizeColorHexRgb(String value) {
  if (value.length != 6 || !_isHexRgb(value)) {
    throw ValidationException(
      'ProjectedShadowAppearance.colorHexRgb must contain exactly '
      '6 hexadecimal RGB characters without #',
    );
  }
  return value.toUpperCase();
}

bool _isHexRgb(String value) {
  for (var index = 0; index < value.length; index += 1) {
    final codeUnit = value.codeUnitAt(index);
    final isDigit = codeUnit >= 0x30 && codeUnit <= 0x39;
    final isUppercaseHex = codeUnit >= 0x41 && codeUnit <= 0x46;
    final isLowercaseHex = codeUnit >= 0x61 && codeUnit <= 0x66;
    if (!isDigit && !isUppercaseHex && !isLowercaseHex) {
      return false;
    }
  }
  return true;
}
```

### Contenu complet — `packages/map_core/test/shadow_v2/projected_shadow_footprint_strategy_test.dart`

```dart
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('ProjectedShadowFootprintFixedTuning', () {
    test('stores explicit tuning', () {
      final tuning = _standardTuning();

      final strategy = ProjectedShadowFootprintFixedTuning(tuning: tuning);

      expect(strategy.tuning, tuning);
      expect(strategy, isA<ProjectedShadowFootprintTuningStrategy>());
    });

    test('equality includes tuning', () {
      final first = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final same = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final changed = ProjectedShadowFootprintFixedTuning(
        tuning: _targetTuning(),
      );

      expect(first, same);
      expect(first, isNot(changed));
    });

    test('hashCode includes tuning', () {
      final first = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final same = ProjectedShadowFootprintFixedTuning(
        tuning: _standardTuning(),
      );
      final changed = ProjectedShadowFootprintFixedTuning(
        tuning: _targetTuning(),
      );

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changed.hashCode));
    });
  });

  group('ProjectedShadowAdaptiveDepthGate', () {
    test('uses canonical defaults', () {
      final gate = ProjectedShadowAdaptiveDepthGate();

      expect(gate.referenceHeight, 80);
      expect(gate.targetHeight, 112);
      expect(gate.referenceRatio, 1.25);
      expect(gate.targetRatio, 1.75);
    });

    test('equality includes all fields', () {
      final first = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final same = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 80,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedTargetHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 140,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.2,
        targetRatio: 1.9,
      );
      final changedTargetRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 2.0,
      );

      expect(first, same);
      expect(first, isNot(changedReferenceHeight));
      expect(first, isNot(changedTargetHeight));
      expect(first, isNot(changedReferenceRatio));
      expect(first, isNot(changedTargetRatio));
    });

    test('hashCode includes all fields', () {
      final first = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final same = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 80,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedTargetHeight = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 140,
        referenceRatio: 1.1,
        targetRatio: 1.9,
      );
      final changedReferenceRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.2,
        targetRatio: 1.9,
      );
      final changedTargetRatio = ProjectedShadowAdaptiveDepthGate(
        referenceHeight: 70,
        targetHeight: 130,
        referenceRatio: 1.1,
        targetRatio: 2.0,
      );

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changedReferenceHeight.hashCode));
      expect(first.hashCode, isNot(changedTargetHeight.hashCode));
      expect(first.hashCode, isNot(changedReferenceRatio.hashCode));
      expect(first.hashCode, isNot(changedTargetRatio.hashCode));
    });

    test('rejects non-positive referenceHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceHeight: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceHeight: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive targetHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetHeight: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetHeight: -1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetHeight equal to referenceHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 80,
          targetHeight: 80,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetHeight below referenceHeight', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 80,
          targetHeight: 79,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive referenceRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(referenceRatio: -0.1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects non-positive targetRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetRatio: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedShadowAdaptiveDepthGate(targetRatio: -0.1),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetRatio equal to referenceRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceRatio: 1.25,
          targetRatio: 1.25,
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetRatio below referenceRatio', () {
      expect(
        () => ProjectedShadowAdaptiveDepthGate(
          referenceRatio: 1.25,
          targetRatio: 1.24,
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('ProjectedShadowFootprintAdaptiveDepthTuning', () {
    test('stores base target gate and opacity endpoints', () {
      final base = _standardTuning();
      final target = _targetTuning();
      final gate = ProjectedShadowAdaptiveDepthGate();

      final strategy = ProjectedShadowFootprintAdaptiveDepthTuning(
        base: base,
        target: target,
        gate: gate,
        baseOpacity: 0.24,
        targetOpacity: 0.22,
      );

      expect(strategy.base, base);
      expect(strategy.target, target);
      expect(strategy.gate, gate);
      expect(strategy.baseOpacity, 0.24);
      expect(strategy.targetOpacity, 0.22);
      expect(strategy, isA<ProjectedShadowFootprintTuningStrategy>());
    });

    test('equality includes every field', () {
      final first = _adaptiveStrategy();
      final same = _adaptiveStrategy();
      final changedBase = _adaptiveStrategy(base: _alternateBaseTuning());
      final changedTarget = _adaptiveStrategy(target: _alternateTargetTuning());
      final changedGate = _adaptiveStrategy(
        gate: ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 70,
          targetHeight: 120,
          referenceRatio: 1.2,
          targetRatio: 1.8,
        ),
      );
      final changedBaseOpacity = _adaptiveStrategy(baseOpacity: 0.25);
      final changedTargetOpacity = _adaptiveStrategy(targetOpacity: 0.21);

      expect(first, same);
      expect(first, isNot(changedBase));
      expect(first, isNot(changedTarget));
      expect(first, isNot(changedGate));
      expect(first, isNot(changedBaseOpacity));
      expect(first, isNot(changedTargetOpacity));
    });

    test('hashCode includes every field', () {
      final first = _adaptiveStrategy();
      final same = _adaptiveStrategy();
      final changedBase = _adaptiveStrategy(base: _alternateBaseTuning());
      final changedTarget = _adaptiveStrategy(target: _alternateTargetTuning());
      final changedGate = _adaptiveStrategy(
        gate: ProjectedShadowAdaptiveDepthGate(
          referenceHeight: 70,
          targetHeight: 120,
          referenceRatio: 1.2,
          targetRatio: 1.8,
        ),
      );
      final changedBaseOpacity = _adaptiveStrategy(baseOpacity: 0.25);
      final changedTargetOpacity = _adaptiveStrategy(targetOpacity: 0.21);

      expect(first.hashCode, same.hashCode);
      expect(first.hashCode, isNot(changedBase.hashCode));
      expect(first.hashCode, isNot(changedTarget.hashCode));
      expect(first.hashCode, isNot(changedGate.hashCode));
      expect(first.hashCode, isNot(changedBaseOpacity.hashCode));
      expect(first.hashCode, isNot(changedTargetOpacity.hashCode));
    });

    test('rejects baseOpacity below 0', () {
      expect(
        () => _adaptiveStrategy(baseOpacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects baseOpacity above 1', () {
      expect(
        () => _adaptiveStrategy(baseOpacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetOpacity below 0', () {
      expect(
        () => _adaptiveStrategy(targetOpacity: -0.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects targetOpacity above 1', () {
      expect(
        () => _adaptiveStrategy(targetOpacity: 1.01),
        throwsA(isA<ValidationException>()),
      );
    });

    test('accepts opacity endpoints 0 and 1', () {
      final strategy = _adaptiveStrategy(baseOpacity: 0, targetOpacity: 1);

      expect(strategy.baseOpacity, 0);
      expect(strategy.targetOpacity, 1);
    });
  });

  group('ProjectedBuildingShadowCasterKind', () {
    test('exposes building and largeVolume', () {
      expect(ProjectedBuildingShadowCasterKind.values, [
        ProjectedBuildingShadowCasterKind.building,
        ProjectedBuildingShadowCasterKind.largeVolume,
      ]);
    });
  });

  group('ProjectedShadowFootprintTuning defaults', () {
    test('remain unchanged', () {
      final tuning = ProjectedShadowFootprintTuning();

      expect(tuning.attachYRatio, 0.86);
      expect(tuning.frontWidthRatio, 1.10);
      expect(tuning.rearWidthRatio, 1.20);
      expect(tuning.depthRatio, 0.28);
      expect(tuning.skewXRatio, 0.10);
    });
  });
}

ProjectedShadowFootprintTuning _standardTuning() {
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

ProjectedShadowFootprintTuning _alternateBaseTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.81,
    frontWidthRatio: 1.30,
    rearWidthRatio: 1.42,
    depthRatio: 0.26,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintTuning _alternateTargetTuning() {
  return ProjectedShadowFootprintTuning(
    attachYRatio: 0.80,
    frontWidthRatio: 1.32,
    rearWidthRatio: 1.47,
    depthRatio: 0.42,
    skewXRatio: 0.08,
  );
}

ProjectedShadowFootprintAdaptiveDepthTuning _adaptiveStrategy({
  ProjectedShadowFootprintTuning? base,
  ProjectedShadowFootprintTuning? target,
  ProjectedShadowAdaptiveDepthGate? gate,
  double baseOpacity = 0.24,
  double targetOpacity = 0.22,
}) {
  return ProjectedShadowFootprintAdaptiveDepthTuning(
    base: base ?? _standardTuning(),
    target: target ?? _targetTuning(),
    gate: gate ?? ProjectedShadowAdaptiveDepthGate(),
    baseOpacity: baseOpacity,
    targetOpacity: targetOpacity,
  );
}
```

Checklist finale :

- [x] AGENTS.md lu
- [x] Aucun git write effectué
- [x] Aucun fichier runtime modifié
- [x] Aucun fichier editor modifié
- [x] Aucun resolver modifié
- [x] Aucun JSON/codec modifié
- [x] Aucun generated créé
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Aucun nouveau geometryMode ajouté
- [x] ProjectedShadowFootprintTuningStrategy ajouté
- [x] ProjectedShadowFootprintFixedTuning ajouté
- [x] ProjectedShadowFootprintAdaptiveDepthTuning ajouté
- [x] ProjectedShadowAdaptiveDepthGate ajouté
- [x] ProjectedBuildingShadowCasterKind ajouté
- [x] Gate defaults testés
- [x] Gate validations testées
- [x] Opacity validations testées
- [x] Equality/hashCode testés
- [x] Defaults ProjectedShadowFootprintTuning() conservés
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] dart test test/shadow_v2 passé
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git diff --check propre
- [x] git status final conforme au scope ou fichiers hors scope documentés
