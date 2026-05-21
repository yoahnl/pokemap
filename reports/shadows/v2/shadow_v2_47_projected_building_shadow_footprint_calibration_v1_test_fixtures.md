# ShadowV2-47 — Projected Building Shadow Footprint Calibration V1 Test Fixtures

## 1. Résumé exécutif

Lot exécuté : **ShadowV2-47 — Projected Building Shadow Footprint Calibration V1 Test Fixtures**.

Résultat :

```text
Calibration F — Broad shallow propagée en preset explicite pokemon-building-shadow-footprint-v1.
4 fichiers de test ciblés modifiés.
0 fichier de production modifié.
0 default ProjectedShadowFootprintTuning() modifié.
0 JSON / codec modifié.
0 Selbrume.
0 screenshot.
0 baseline / golden.
1 rapport Markdown créé.
```

La calibration V1 testée est :

```text
id: pokemon-building-shadow-footprint-v1
name: Pokemon-like footprint building shadow V1
attachYRatio: 0.82
frontWidthRatio: 1.30
rearWidthRatio: 1.42
depthRatio: 0.26
skewXRatio: 0.08
opacity: 0.24
colorHexRgb: 606060
```

Points V1 vérifiés :

```text
frontLeft  = (22.40, 142.72)
frontRight = (105.60, 142.72)
rearRight  = (114.56, 167.68)
rearLeft   = (23.68, 167.68)
```

Bounds V1 vérifiés :

```text
left = 22.40
top = 142.72
width = 92.16
height = 24.96
```

## 2. Objectif du lot

Objectif exact :

```text
Propager la calibration footprint retenue au Lot 46,
c'est-à-dire F — Broad shallow,
dans les tests/fixtures ciblés,
en tant que preset explicite pokemon-building-shadow-footprint-v1,
sans modifier la production,
sans modifier les defaults core,
sans modifier renderer/painter,
sans modifier JSON/persistence,
sans Selbrume,
sans image,
sans baseline.
```

## 3. Rappel ShadowV2-46

ShadowV2-46 a retenu :

```text
Option A — Sélectionner F exact.
Propagation : preset-only.
Ne pas modifier ProjectedShadowFootprintTuning() defaults.
Ne pas traiter JSON/persistence au Lot 47.
Ne pas toucher renderer/painter.
Ne pas toucher Selbrume ou baselines.
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

Fichiers préexistants non liés au lot :

```text
Aucun fichier modifié ou non suivi au départ.
```

Fichiers hors scope déjà présents :

```text
Aucun fichier hors scope modifié ou non suivi au départ.
```

## 5. Skills Google Flutter/Dart et sub-agents utilisés

Skills utilisés :

```text
superpowers:using-superpowers
karpathy-guidelines
superpowers:test-driven-development
superpowers:verification-before-completion
superpowers:subagent-driven-development
dart-add-unit-test
```

Skills Google Flutter/Dart :

```text
Aucun skill explicitement nommé Google Flutter ou Google Dart n'a été détecté dans la liste des skills disponibles.
Des skills Dart/Flutter génériques existent et ont été utilisés pour guider l'ajout de tests.
```

Sub-agents utilisés :

```text
Audit sub-agent : utilisé en lecture seule.
Test fixture sub-agent : utilisé en lecture seule.
Runtime/editor proof sub-agent : utilisé en lecture seule.
Evidence/report sub-agent : passe équivalente faite localement pour contrôler l'unique rapport créé.
```

Synthèse sub-agents :

```text
Audit : worktree propre, AGENTS.md racine vérifié, aucun AGENTS.md plus profond pertinent, scope autorisé confirmé.
Test fixture : les helpers V0 existent ; V1 doit rester explicite et ne pas utiliser ProjectedShadowFootprintTuning() nu.
Runtime/editor proof : les tests same-element optionnels ne nécessitent pas de modification car ils prouvent seulement qu'un footprint résoluble supprime la V1 legacy.
Evidence/report : exécuté localement pour intégrer les sorties de test/analyze/diff dans ce rapport.
```

## 6. Décision AGENTS / design gate déjà satisfait

Décision d'exécution :

```text
Le design gate ShadowV2-46 est satisfait.
Le Lot 47 est une implémentation test-only / fixture-only.
Les modifications sont limitées aux tests autorisés.
Aucun fichier production n'a été modifié.
Aucune commande git d'écriture n'a été lancée.
```

## 7. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
reports/shadows/v2/shadow_v2_47_projected_building_shadow_footprint_calibration_v1_test_fixtures.md
```

Fichiers modifiés :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichiers supprimés :

```text
Aucun
```

Fichiers optionnels non modifiés :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

## 8. Audit initial des fixtures footprint

Commandes exécutées avant modification :

```bash
find .. -name AGENTS.md -print
rg -n "skills|Flutter|Dart|Google|sub-agent|subagent|Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
rg -n "pokemon-building-shadow-footprint-v0|pokemon-building-shadow-footprint-v1|ProjectedShadowFootprintTuning\(|attachYRatio|frontWidthRatio|rearWidthRatio|depthRatio|skewXRatio|0\.86|1\.10|1\.20|0\.28|0\.10|0\.82|1\.30|1\.42|0\.26|0\.08|0\.24" packages/map_core/test/shadow_v2 packages/map_runtime/test/shadow packages/map_editor/test/application reports/shadows/v2
rg -n "projected building shadow|footprint|geometryMode|ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|colorHexRgb|opacity|bounds|polygonPoints|606060" packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
rg -n "footprint|pokemon-building-shadow-footprint|ProjectedShadowFootprintTuning|same element|same-element|legacy static shadow|shadowOverride" packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Constats :

```text
Les tests existants V0 utilisent pokemon-building-shadow-footprint-v0 avec ProjectedShadowFootprintTuning().
Le default V0 reste couvert par projected_building_shadow_footprint_tuning_test.dart.
Les tests runtime/editor ciblés avaient déjà des tests footprint V0 avec opacity 0.28 et points V0.
Les tests same-element optionnels utilisent V0 uniquement pour prouver qu'un preset footprint résoluble supprime la legacy same-element.
```

## 9. Calibration V1 appliquée

V1 appliqué explicitement dans les tests :

```dart
ProjectedShadowFootprintTuning(
  attachYRatio: 0.82,
  frontWidthRatio: 1.30,
  rearWidthRatio: 1.42,
  depthRatio: 0.26,
  skewXRatio: 0.08,
)
```

Appearance V1 :

```dart
ProjectedShadowAppearance(
  opacity: 0.24,
  colorHexRgb: '606060',
)
```

Preset V1 :

```text
id: pokemon-building-shadow-footprint-v1
name: Pokemon-like footprint building shadow V1
geometryMode: footprint
```

Points et bounds :

```text
points:
  (22.40, 142.72)
  (105.60, 142.72)
  (114.56, 167.68)
  (23.68, 167.68)
bounds:
  left = 22.40
  top = 142.72
  width = 92.16
  height = 24.96
```

## 10. Defaults core conservés

Le Lot 47 ne modifie aucun fichier `packages/map_core/lib/**`.

Les defaults restent :

```text
ProjectedShadowFootprintTuning()
attachYRatio = 0.86
frontWidthRatio = 1.10
rearWidthRatio = 1.20
depthRatio = 0.28
skewXRatio = 0.10
```

Preuve par régression :

```text
cd packages/map_core && dart test test/shadow_v2
ligne finale : 00:00 +168: All tests passed!
```

Le premier test de cette régression couvre explicitement :

```text
ProjectedShadowFootprintTuning uses footprint V0 defaults
```

## 11. Test map_core footprint V1

Fichier modifié :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Test ajouté :

```text
resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points
```

Ce test :

```text
construit un ProjectBuildingShadowPreset V1 explicite ;
utilise ProjectedShadowFootprintTuning(...) avec les valeurs F ;
vérifie opacity 0.24 ;
vérifie colorHexRgb 606060 ;
vérifie les 4 points V1 attendus ;
ne recalcule pas les points attendus avec la formule testée.
```

## 12. Test runtime adapter footprint V1

Fichier modifié :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Test ajouté :

```text
converts footprint v1 geometry to runtime projected polygon instruction
```

Ce test :

```text
crée directement une ProjectedBuildingShadowGeometry V1 ;
vérifie projectedPolygon ;
vérifie groundStatic ;
vérifie opacity 0.24 ;
vérifie colorHexRgb 606060 ;
vérifie bounds 22.40 / 142.72 / 92.16 / 24.96 ;
vérifie les 4 polygonPoints V1.
```

## 13. Test runtime collection footprint V1

Fichier modifié :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Test ajouté :

```text
buildRuntimeProjectedBuildingShadowCollection resolves footprint v1 preset through map_core geometry
```

Ce test :

```text
construit un ProjectManifest in-memory avec pokemon-building-shadow-footprint-v1 ;
résout la géométrie via map_core ;
convertit via l'adapter runtime existant ;
vérifie projectedPolygon, groundStatic, opacity, color, bounds et points V1.
```

## 14. Test editor preview footprint V1

Fichier modifié :

```text
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Test ajouté :

```text
buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint v1 projected polygon preview
```

Ce test :

```text
construit un ProjectManifest in-memory avec pokemon-building-shadow-footprint-v1 ;
vérifie la preview projectedPolygon ;
vérifie opacity 0.24 ;
vérifie colorHexRgb 606060 ;
vérifie bounds et polygonPoints V1.
```

## 15. Tests V1 same-element optionnels

Fichiers audités mais non modifiés :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Décision :

```text
Non modifiés.
```

Pourquoi :

```text
Ces tests prouvent déjà qu'un preset footprint résoluble supprime la legacy same-element.
Ils ne représentent pas la calibration officielle V1.
Les modifier aurait mélangé preuve de suppression V1 legacy et calibration visuelle V1.
```

## 16. RED / GREEN observé

Résultat :

```text
GREEN-on-add.
```

Explication :

```text
Les tests V1 ajoutés passent sans modification production.
Cela confirme que la calibration explicite V1 traverse déjà map_core, runtime adapter, runtime collection et editor preview.
```

## 17. Résultats des tests

### Test ciblé map_core

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

### Tests ciblés runtime

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
00:00 +0: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart: createProjectedBuildingShadowRuntimeInstruction converts geometry to a ground projected polygon instruction
00:00 +1: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +2: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +3: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +4: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +5: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +6: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +7: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart: createProjectedBuildingShadowRuntimeInstruction adapter source stays independent from render and traversal layers
00:00 +8: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection builds one ground projected polygon for a valid projected shadow
00:00 +9: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection buildRuntimeProjectedBuildingShadowCollection resolves footprint preset through map_core geometry
00:00 +10: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection buildRuntimeProjectedBuildingShadowCollection resolves footprint v1 preset through map_core geometry
00:00 +11: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection skips disabled projected shadow config
00:00 +12: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection skips missing preset without throwing
00:00 +13: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection skips missing element without throwing
00:00 +14: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection skips hidden or transparent placement layers and zero opacity placement
00:00 +15: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection does not multiply preset opacity by placement opacity
00:00 +16: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection preserves source placement order
00:00 +17: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection does not block V2 when the element also has a V1 shadow
00:00 +18: /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart: buildRuntimeProjectedBuildingShadowCollection builder source stays independent from renderer and diagnostics layers
00:00 +19: All tests passed!
```

### Test ciblé editor

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
00:00 +0: buildEditorProjectedBuildingShadowPreviewInstructions builds a projected polygon preview
00:00 +1: buildEditorProjectedBuildingShadowPreviewInstructions buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint projected polygon preview
00:00 +2: buildEditorProjectedBuildingShadowPreviewInstructions buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint v1 projected polygon preview
00:00 +3: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when element has no projectedBuildingShadow config
00:00 +4: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when projectedBuildingShadow is disabled
00:00 +5: buildEditorProjectedBuildingShadowPreviewInstructions skips missing projected building shadow preset without throwing
00:00 +6: buildEditorProjectedBuildingShadowPreviewInstructions skips hidden or transparent tile layers
00:00 +7: buildEditorProjectedBuildingShadowPreviewInstructions skips zero opacity placements
00:00 +8: buildEditorProjectedBuildingShadowPreviewInstructions skips invalid visual source dimensions
00:00 +9: buildEditorProjectedBuildingShadowPreviewInstructions preserves placed element source order
00:00 +10: buildEditorProjectedBuildingShadowPreviewInstructions does not depend on runtime or auto projection
00:00 +11: All tests passed!
```

### Régressions utiles

Commandes :

```bash
cd packages/map_core && dart test test/shadow_v2
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_collection_test.dart test/shadow/projected_building_shadow_runtime_adapter_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart test/application/shadow/editor_static_shadow_preview_test.dart
```

Lignes finales exactes :

```text
map_core shadow_v2: 00:00 +168: All tests passed!
map_runtime targeted regression: 00:00 +19: All tests passed!
map_editor targeted regression: 00:00 +36: All tests passed!
```

## 18. Résultat analyze

Commande :

```bash
cd packages/map_core && dart analyze test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie complète :

```text
Analyzing projected_building_shadow_geometry_test.dart...
No issues found!
```

Commande :

```bash
cd packages/map_runtime && flutter analyze test/shadow/projected_building_shadow_runtime_adapter_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Sortie complète :

```text
Analyzing 2 items...

No issues found! (ran in 1.2s)
```

Commande :

```bash
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie complète :

```text
Analyzing editor_projected_building_shadow_preview_test.dart...

No issues found! (ran in 0.9s)
```

## 19. Audit anti-dérive

Commande :

```bash
rg -n "packages/map_core/lib|packages/map_runtime/lib|packages/map_editor/lib|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie :

```text
(no output)
```

Résultat :

```text
Aucun hit interdit dans les fichiers modifiés.
```

## 20. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
ProjectedShadowFootprintTuning() defaults
JSON/codecs
renderer
painter
MapGridPainter
```

## 21. Ce qui n’a volontairement pas été créé

```text
screenshot
baseline
golden
fixture Selbrume
nouveau renderer
nouveau painter
nouveau modèle
nouveau codec JSON
generated file
migration
UI authoring
shader
blur
alpha mask
author-defined polygon UI
```

## 22. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie finale :

```text
 .../projected_building_shadow_geometry_test.dart   | 74 ++++++++++++++++++++++
 ...tor_projected_building_shadow_preview_test.dart | 65 +++++++++++++++++++
 ...ected_building_shadow_runtime_adapter_test.dart | 31 +++++++++
 ..._projected_building_shadow_collection_test.dart | 63 ++++++++++++++++++
 4 files changed, 233 insertions(+)
```

## 23. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie finale :

```text
M	packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
M	packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
M	packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
M	packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
```

## 24. git diff --check

Commande :

```bash
git diff --check
```

Sortie finale :

```text
(no output)
```

Résultat :

```text
Propre.
```

## 25. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale :

```text
 M packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
 M packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
 M packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
?? reports/shadows/v2/shadow_v2_47_projected_building_shadow_footprint_calibration_v1_test_fixtures.md
```

## 26. Risques / réserves

```text
La calibration V1 est propagée dans des tests/fixtures in-memory seulement.
JSON/persistence reste non traité.
Selbrume/project.json réel reste non traité.
Les defaults core restent V0, donc les tests officiels V1 doivent continuer à utiliser un tuning explicite.
Un futur lot visuel doit vérifier que le preset V1 testé correspond bien au rendu attendu en PNG.
```

## 27. Auto-critique

Le lot est-il bien test-only / fixture-only ?

```text
Oui. Seuls des fichiers de test ciblés et ce rapport ont été modifiés/créés.
```

Les defaults core sont-ils vraiment inchangés ?

```text
Oui. Aucun fichier packages/map_core/lib/** n'a été modifié, et la régression shadow_v2 passe.
```

La calibration V1 est-elle explicite partout où elle est officielle ?

```text
Oui. Les nouveaux tests V1 utilisent ProjectedShadowFootprintTuning(...) avec les cinq valeurs F nommées.
```

Les tests évitent-ils d'utiliser ProjectedShadowFootprintTuning() comme V1 implicite ?

```text
Oui. ProjectedShadowFootprintTuning() sans argument reste uniquement dans les fixtures V0 existantes.
```

Les points attendus sont-ils explicites et non recalculés ?

```text
Oui. Les points V1 sont écrits comme valeurs attendues dans chaque test.
```

Runtime/editor production sont-ils intacts ?

```text
Oui. Aucun fichier packages/map_runtime/lib/** ni packages/map_editor/lib/** n'est modifié.
```

JSON/persistence est-il bien hors scope ?

```text
Oui. Aucun codec ou project.json n'est modifié.
```

Selbrume/images/baselines sont-ils évités ?

```text
Oui. Aucun fichier Selbrume, screenshot, baseline ou golden n'est créé/modifié.
```

Le rapport contient-il toutes les preuves ?

```text
Oui. Les commandes, sorties, diff, statut, contenu complet des fichiers modifiés et checklist sont documentés.
```

## 28. Regard critique sur le prompt

Le prompt est utilement strict :

```text
Il protège la décision Lot 46 : V1 est preset-only, pas default core.
Il évite de mélanger calibration, renderer, JSON et Selbrume.
Il force les preuves runtime/editor sans production change.
```

Point de vigilance :

```text
Le nom "V1 same-element" peut être confus, car V1 désigne ici parfois legacy static shadow et parfois footprint calibration V1.
Le rapport distingue donc "same-element optionnels" et "calibration V1 officielle".
```

## 29. Prochain lot recommandé

Prochain lot probable :

```text
ShadowV2-48 — Projected Building Shadow Footprint V1 Micro Visual Artifact
```

Objectif probable :

```text
Générer un artifact micro avec la calibration officielle pokemon-building-shadow-footprint-v1,
pour confirmer visuellement que les tests/fixtures V1 correspondent bien au rendu choisi.
```

Alternative si la priorité devient persistence :

```text
ShadowV2-48 — Projected Building Shadow Footprint JSON Codec Design Gate
```

## 30. Code complet des fichiers créés/modifiés

Le rapport courant est le fichier créé par ce lot.

### Diff complet des fichiers modifiés

```diff
diff --git a/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart b/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
index fc1b2b05..24bef5d9 100644
--- a/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
+++ b/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
@@ -269,6 +269,80 @@ void main() {
       );
     });
 
+    test(
+        'resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points',
+        () {
+      final preset = ProjectBuildingShadowPreset(
+        id: 'pokemon-building-shadow-footprint-v1',
+        name: 'Pokemon-like footprint building shadow V1',
+        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
+        shape: ProjectedShadowShapeTuning(
+          lengthRatio: 0.32,
+          nearWidthRatio: 0.90,
+          farWidthRatio: 0.72,
+        ),
+        footprint: ProjectedShadowFootprintTuning(
+          attachYRatio: 0.82,
+          frontWidthRatio: 1.30,
+          rearWidthRatio: 1.42,
+          depthRatio: 0.26,
+          skewXRatio: 0.08,
+        ),
+        appearance: ProjectedShadowAppearance(
+          opacity: 0.24,
+          colorHexRgb: '606060',
+        ),
+        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+      );
+      final config = ProjectElementProjectedBuildingShadowConfig(
+        enabled: true,
+        presetId: 'pokemon-building-shadow-footprint-v1',
+        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
+        localOffset: ProjectedShadowOffset(x: 0, y: 0),
+      );
+      final metrics = StaticShadowVisualMetrics(
+        left: 32,
+        top: 64,
+        visualWidth: 64,
+        visualHeight: 96,
+      );
+      final geometry = resolveProjectedBuildingShadowGeometry(
+        config: config,
+        preset: preset,
+        metrics: metrics,
+      );
+
+      expect(geometry, isNotNull);
+      expect(geometry!.opacity, 0.24);
+      expect(geometry.colorHexRgb, '606060');
+      expect(geometry.points, hasLength(4));
+      _expectPointClose(
+        geometry.points[0],
+        x: 22.40,
+        y: 142.72,
+        tolerance: 0.02,
+      );
+      _expectPointClose(
+        geometry.points[1],
+        x: 105.60,
+        y: 142.72,
+        tolerance: 0.02,
+      );
+      _expectPointClose(
+        geometry.points[2],
+        x: 114.56,
+        y: 167.68,
+        tolerance: 0.02,
+      );
+      _expectPointClose(
+        geometry.points[3],
+        x: 23.68,
+        y: 167.68,
+        tolerance: 0.02,
+      );
+    });
+
     test('footprint geometry localOffset shifts all points', () {
       final preset = _footprintPreset();
       final withoutOffset = resolveProjectedBuildingShadowGeometry(
diff --git a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
index aa808f90..92e09c7f 100644
--- a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
@@ -77,6 +77,45 @@ void main() {
       _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
     });
 
+    test(
+        'buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint v1 projected polygon preview',
+        () {
+      final instructions =
+          buildEditorProjectedBuildingShadowPreviewInstructions(
+        manifest: _manifest(
+          catalog: _catalog([_footprintV1Preset()]),
+          elements: [
+            _element(
+              projectedBuildingShadow: _config(
+                presetId: 'pokemon-building-shadow-footprint-v1',
+              ),
+            ),
+          ],
+        ),
+        map: _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
+        tileWidth: 32,
+        tileHeight: 32,
+      );
+
+      expect(instructions, hasLength(1));
+      final instruction = instructions.single;
+      expect(
+        instruction.shape,
+        EditorStaticShadowPreviewShapeKind.projectedPolygon,
+      );
+      expect(instruction.opacity, 0.24);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.left, closeTo(22.40, 0.02));
+      expect(instruction.top, closeTo(142.72, 0.02));
+      expect(instruction.width, closeTo(92.16, 0.02));
+      expect(instruction.height, closeTo(24.96, 0.02));
+      expect(instruction.polygonPoints, hasLength(4));
+      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
+      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
+      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
+      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
+    });
+
     test('returns empty when element has no projectedBuildingShadow config',
         () {
       final instructions =
@@ -377,6 +416,32 @@ ProjectBuildingShadowPreset _footprintPreset() {
   );
 }
 
+ProjectBuildingShadowPreset _footprintV1Preset() {
+  return ProjectBuildingShadowPreset(
+    id: 'pokemon-building-shadow-footprint-v1',
+    name: 'Pokemon-like footprint building shadow V1',
+    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.32,
+      nearWidthRatio: 0.90,
+      farWidthRatio: 0.72,
+    ),
+    footprint: ProjectedShadowFootprintTuning(
+      attachYRatio: 0.82,
+      frontWidthRatio: 1.30,
+      rearWidthRatio: 1.42,
+      depthRatio: 0.26,
+      skewXRatio: 0.08,
+    ),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.24,
+      colorHexRgb: '606060',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
 ProjectElementProjectedBuildingShadowConfig _config({
   bool enabled = true,
   String presetId = 'pokemon-building-shadow-v0',
diff --git a/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart b/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
index 06789b97..3e086310 100644
--- a/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
+++ b/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
@@ -70,6 +70,37 @@ void main() {
       _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
     });
 
+    test(
+        'converts footprint v1 geometry to runtime projected polygon instruction',
+        () {
+      final instruction = createProjectedBuildingShadowRuntimeInstruction(
+        _geometry(
+          [
+            ProjectedBuildingShadowPoint(x: 22.40, y: 142.72),
+            ProjectedBuildingShadowPoint(x: 105.60, y: 142.72),
+            ProjectedBuildingShadowPoint(x: 114.56, y: 167.68),
+            ProjectedBuildingShadowPoint(x: 23.68, y: 167.68),
+          ],
+          opacity: 0.24,
+          colorHexRgb: '606060',
+        ),
+      );
+
+      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
+      expect(instruction.opacity, 0.24);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.worldLeft, closeTo(22.40, 0.02));
+      expect(instruction.worldTop, closeTo(142.72, 0.02));
+      expect(instruction.width, closeTo(92.16, 0.02));
+      expect(instruction.height, closeTo(24.96, 0.02));
+      expect(instruction.polygonPoints, hasLength(4));
+      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
+      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
+      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
+      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
+    });
+
     test('preserves point order exactly', () {
       final instruction = createProjectedBuildingShadowRuntimeInstruction(
         _geometry(
diff --git a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
index 8fed90b3..6257c87a 100644
--- a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
@@ -88,6 +88,43 @@ void main() {
       _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
     });
 
+    test(
+        'buildRuntimeProjectedBuildingShadowCollection resolves footprint v1 preset through map_core geometry',
+        () {
+      final collection = buildRuntimeProjectedBuildingShadowCollection(
+        manifest: _manifest(
+          catalog: _catalog([_footprintV1Preset()]),
+          elements: [
+            _element(
+              projectedBuildingShadow:
+                  _config(presetId: 'pokemon-building-shadow-footprint-v1'),
+            ),
+          ],
+        ),
+        mapData:
+            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
+      );
+
+      expect(collection.length, 1);
+      expect(collection.groundStatic, hasLength(1));
+      expect(collection.actorContact, isEmpty);
+
+      final instruction = collection.groundStatic.single;
+      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
+      expect(instruction.opacity, 0.24);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.worldLeft, closeTo(22.40, 0.02));
+      expect(instruction.worldTop, closeTo(142.72, 0.02));
+      expect(instruction.width, closeTo(92.16, 0.02));
+      expect(instruction.height, closeTo(24.96, 0.02));
+      expect(instruction.polygonPoints, hasLength(4));
+      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
+      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
+      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
+      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
+    });
+
     test('skips disabled projected shadow config', () {
       final collection = buildRuntimeProjectedBuildingShadowCollection(
         manifest: _manifest(
@@ -402,6 +439,32 @@ ProjectBuildingShadowPreset _footprintPreset() {
   );
 }
 
+ProjectBuildingShadowPreset _footprintV1Preset() {
+  return ProjectBuildingShadowPreset(
+    id: 'pokemon-building-shadow-footprint-v1',
+    name: 'Pokemon-like footprint building shadow V1',
+    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.32,
+      nearWidthRatio: 0.90,
+      farWidthRatio: 0.72,
+    ),
+    footprint: ProjectedShadowFootprintTuning(
+      attachYRatio: 0.82,
+      frontWidthRatio: 1.30,
+      rearWidthRatio: 1.42,
+      depthRatio: 0.26,
+      skewXRatio: 0.08,
+    ),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.24,
+      colorHexRgb: '606060',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
 ProjectElementProjectedBuildingShadowConfig _config({
   bool enabled = true,
   String presetId = 'shadow-a',
```

### Contenu complet — packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart

```dart
import 'dart:io';

import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Projected building shadow geometry', () {
    test('disabled config returns null', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(enabled: false),
        preset: _preset(),
        metrics: _metrics(),
      );

      expect(geometry, isNull);
    });

    test('resolves basic horizontal geometry with stable point order', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          direction: ProjectedShadowDirection(x: 1, y: 0),
          shape: ProjectedShadowShapeTuning(
            lengthRatio: 0.5,
            nearWidthRatio: 1,
            farWidthRatio: 0.5,
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 60, y: 50);
      _expectPointClose(geometry.points[1], x: 60, y: 150);
      _expectPointClose(geometry.points[2], x: 100, y: 125);
      _expectPointClose(geometry.points[3], x: 100, y: 75);
    });

    test('normalizes direction before applying length', () {
      final unit = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 1, y: 0)),
        metrics: _metrics(),
      );
      final scaled = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 2, y: 0)),
        metrics: _metrics(),
      );

      expect(scaled, unit);
    });

    test('resolves vertical direction geometry', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(direction: ProjectedShadowDirection(x: 0, y: 1)),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 110, y: 100);
      _expectPointClose(geometry.points[1], x: 10, y: 100);
      _expectPointClose(geometry.points[2], x: 35, y: 140);
      _expectPointClose(geometry.points[3], x: 85, y: 140);
    });

    test('localOffset shifts all points', () {
      final withoutOffset = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(),
        metrics: _metrics(),
      );
      final withOffset = resolveProjectedBuildingShadowGeometry(
        config: _config(offset: ProjectedShadowOffset(x: 5, y: -3)),
        preset: _preset(),
        metrics: _metrics(),
      );

      expect(withoutOffset, isNotNull);
      expect(withOffset, isNotNull);
      for (var index = 0; index < withoutOffset!.points.length; index += 1) {
        _expectPointClose(
          withOffset!.points[index],
          x: withoutOffset.points[index].x + 5,
          y: withoutOffset.points[index].y - 3,
        );
      }
    });

    test('shape ratios control length and widths', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          shape: ProjectedShadowShapeTuning(
            lengthRatio: 0.25,
            nearWidthRatio: 0.5,
            farWidthRatio: 0.75,
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      _expectPointClose(geometry!.points[0], x: 60, y: 75);
      _expectPointClose(geometry.points[1], x: 60, y: 125);
      _expectPointClose(geometry.points[2], x: 80, y: 137.5);
      _expectPointClose(geometry.points[3], x: 80, y: 62.5);
    });

    test('propagates preset appearance', () {
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(
          appearance: ProjectedShadowAppearance(
            opacity: 0.42,
            colorHexRgb: '445566',
          ),
        ),
        metrics: _metrics(),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.42);
      expect(geometry.colorHexRgb, '445566');
    });

    test('followsSun uses preset direction as fixed in V0', () {
      final fixed = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed),
        metrics: _metrics(),
      );
      final followsSun = resolveProjectedBuildingShadowGeometry(
        config: _config(),
        preset: _preset(timeOfDayMode: ProjectedShadowTimeOfDayMode.followsSun),
        metrics: _metrics(),
      );

      expect(followsSun, fixed);
    });

    test('resolves pokemon-building-shadow-v0 geometry with calibrated points',
        () {
      final preset = ProjectBuildingShadowPreset(
        id: 'pokemon-building-shadow-v0',
        name: 'Pokemon-like building shadow V0',
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.90,
          farWidthRatio: 0.72,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.30,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
      final config = ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'pokemon-building-shadow-v0',
        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
        localOffset: ProjectedShadowOffset(x: 0, y: 0),
      );
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: config,
        preset: preset,
        metrics: StaticShadowVisualMetrics(
          left: 32,
          top: 64,
          visualWidth: 64,
          visualHeight: 96,
        ),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.30);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      _expectPointClose(
        geometry.points[0],
        x: 75.54,
        y: 129.77,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[1],
        x: 52.46,
        y: 182.55,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[2],
        x: 82.91,
        y: 189.58,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[3],
        x: 101.38,
        y: 147.36,
        tolerance: 0.02,
      );
    });

    test('resolves footprint geometry with attached skewed rectangle points',
        () {
      final preset = ProjectBuildingShadowPreset(
        id: 'pokemon-building-shadow-footprint-v0',
        name: 'Pokemon-like footprint building shadow V0',
        direction: ProjectedShadowDirection(x: 1, y: 0),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0,
          nearWidthRatio: 1,
          farWidthRatio: 1,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.28,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        footprint: ProjectedShadowFootprintTuning(),
      );
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: ProjectElementProjectedBuildingShadowConfig(
          enabled: true,
          presetId: 'pokemon-building-shadow-footprint-v0',
          anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
          localOffset: ProjectedShadowOffset(x: 0, y: 0),
        ),
        preset: preset,
        metrics: StaticShadowVisualMetrics(
          left: 32,
          top: 64,
          visualWidth: 64,
          visualHeight: 96,
        ),
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.28);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      _expectPointClose(
        geometry.points[0],
        x: 28.80,
        y: 146.56,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[1],
        x: 99.20,
        y: 146.56,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[2],
        x: 108.80,
        y: 173.44,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[3],
        x: 32.00,
        y: 173.44,
        tolerance: 0.02,
      );
    });

    test(
        'resolves pokemon-building-shadow-footprint-v1 geometry with selected calibration points',
        () {
      final preset = ProjectBuildingShadowPreset(
        id: 'pokemon-building-shadow-footprint-v1',
        name: 'Pokemon-like footprint building shadow V1',
        geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
        shape: ProjectedShadowShapeTuning(
          lengthRatio: 0.32,
          nearWidthRatio: 0.90,
          farWidthRatio: 0.72,
        ),
        footprint: ProjectedShadowFootprintTuning(
          attachYRatio: 0.82,
          frontWidthRatio: 1.30,
          rearWidthRatio: 1.42,
          depthRatio: 0.26,
          skewXRatio: 0.08,
        ),
        appearance: ProjectedShadowAppearance(
          opacity: 0.24,
          colorHexRgb: '606060',
        ),
        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
      );
      final config = ProjectElementProjectedBuildingShadowConfig(
        enabled: true,
        presetId: 'pokemon-building-shadow-footprint-v1',
        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
        localOffset: ProjectedShadowOffset(x: 0, y: 0),
      );
      final metrics = StaticShadowVisualMetrics(
        left: 32,
        top: 64,
        visualWidth: 64,
        visualHeight: 96,
      );
      final geometry = resolveProjectedBuildingShadowGeometry(
        config: config,
        preset: preset,
        metrics: metrics,
      );

      expect(geometry, isNotNull);
      expect(geometry!.opacity, 0.24);
      expect(geometry.colorHexRgb, '606060');
      expect(geometry.points, hasLength(4));
      _expectPointClose(
        geometry.points[0],
        x: 22.40,
        y: 142.72,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[1],
        x: 105.60,
        y: 142.72,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[2],
        x: 114.56,
        y: 167.68,
        tolerance: 0.02,
      );
      _expectPointClose(
        geometry.points[3],
        x: 23.68,
        y: 167.68,
        tolerance: 0.02,
      );
    });

    test('footprint geometry localOffset shifts all points', () {
      final preset = _footprintPreset();
      final withoutOffset = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(),
        preset: preset,
        metrics: _footprintMetrics(),
      );
      final withOffset = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(
          offset: ProjectedShadowOffset(x: 5, y: -3),
        ),
        preset: preset,
        metrics: _footprintMetrics(),
      );

      expect(withoutOffset, isNotNull);
      expect(withOffset, isNotNull);
      for (var index = 0; index < withoutOffset!.points.length; index += 1) {
        _expectPointClose(
          withOffset!.points[index],
          x: withoutOffset.points[index].x + 5,
          y: withoutOffset.points[index].y - 3,
          tolerance: 0.02,
        );
      }
    });

    test('footprint geometry ignores anchor', () {
      final preset = _footprintPreset();
      final centeredAnchor = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(
          anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
        ),
        preset: preset,
        metrics: _footprintMetrics(),
      );
      final shiftedAnchor = resolveProjectedBuildingShadowGeometry(
        config: _footprintConfig(
          anchor: ProjectedShadowAnchor(xRatio: 0.1, yRatio: 0.2),
        ),
        preset: preset,
        metrics: _footprintMetrics(),
      );

      expect(shiftedAnchor, centeredAnchor);
    });

    test('geometry defensively copies points and exposes an immutable list',
        () {
      final source = [
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ];
      final geometry = ProjectedBuildingShadowGeometry(
        points: source,
        opacity: 0.5,
        colorHexRgb: '000000',
      );

      source[0] = ProjectedBuildingShadowPoint(x: 99, y: 99);

      expect(geometry.points[0], ProjectedBuildingShadowPoint(x: 0, y: 0));
      expect(
        () => geometry.points.add(ProjectedBuildingShadowPoint(x: 1, y: 1)),
        throwsUnsupportedError,
      );
    });

    test('point and geometry equality include ordered values', () {
      final firstPoint = ProjectedBuildingShadowPoint(x: 1, y: 2);
      final samePoint = ProjectedBuildingShadowPoint(x: 1, y: 2);
      final differentPoint = ProjectedBuildingShadowPoint(x: 2, y: 2);

      expect(firstPoint, samePoint);
      expect(firstPoint.hashCode, samePoint.hashCode);
      expect(firstPoint, isNot(differentPoint));

      final first = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);
      final same = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);
      final reordered = _geometry([
        ProjectedBuildingShadowPoint(x: 0, y: 10),
        ProjectedBuildingShadowPoint(x: 0, y: 0),
        ProjectedBuildingShadowPoint(x: 10, y: 10),
        ProjectedBuildingShadowPoint(x: 10, y: 0),
      ]);

      expect(first, same);
      expect(first.hashCode, same.hashCode);
      expect(first, isNot(reordered));
    });

    test('geometry validates points, opacity, and color', () {
      expect(
        () => ProjectedBuildingShadowPoint(x: double.nan, y: 0),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: [
            ProjectedBuildingShadowPoint(x: 0, y: 0),
            ProjectedBuildingShadowPoint(x: 1, y: 1),
            ProjectedBuildingShadowPoint(x: 2, y: 2),
          ],
          opacity: 0.5,
          colorHexRgb: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: _validPoints(),
          opacity: 1.1,
          colorHexRgb: '000000',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => ProjectedBuildingShadowGeometry(
          points: _validPoints(),
          opacity: 0.5,
          colorHexRgb: '00000G',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('geometry source stays independent from runtime editor and manifest',
        () {
      final source = File(
        'lib/src/operations/projected_building_shadow_geometry.dart',
      ).readAsStringSync();

      expect(source, isNot(contains('map_runtime')));
      expect(source, isNot(contains('map_editor')));
      expect(source, isNot(contains('ProjectManifest')));
      expect(source, isNot(contains('ProjectElementEntry')));
      expect(source, isNot(contains('ProjectBuildingShadowPresetCatalog')));
      expect(source, isNot(contains('projected_building_shadow_diagnostics')));
    });
  });
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  ProjectedShadowOffset? offset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: 'short-west',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: offset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset({
  ProjectedShadowDirection? direction,
  ProjectedShadowShapeTuning? shape,
  ProjectedShadowAppearance? appearance,
  ProjectedShadowTimeOfDayMode timeOfDayMode =
      ProjectedShadowTimeOfDayMode.fixed,
}) {
  return ProjectBuildingShadowPreset(
    id: 'short-west',
    name: 'Short west shadow',
    direction: direction ?? ProjectedShadowDirection(x: 1, y: 0),
    shape: shape ??
        ProjectedShadowShapeTuning(
          lengthRatio: 0.5,
          nearWidthRatio: 1,
          farWidthRatio: 0.5,
        ),
    appearance: appearance ?? ProjectedShadowAppearance(opacity: 0.18),
    timeOfDayMode: timeOfDayMode,
  );
}

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0,
      nearWidthRatio: 1,
      farWidthRatio: 1,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    footprint: ProjectedShadowFootprintTuning(),
  );
}

ProjectElementProjectedBuildingShadowConfig _footprintConfig({
  ProjectedShadowAnchor? anchor,
  ProjectedShadowOffset? offset,
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-footprint-v0',
    anchor: anchor ?? ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: offset ?? ProjectedShadowOffset(x: 0, y: 0),
  );
}

StaticShadowVisualMetrics _footprintMetrics() {
  return StaticShadowVisualMetrics(
    left: 32,
    top: 64,
    visualWidth: 64,
    visualHeight: 96,
  );
}

StaticShadowVisualMetrics _metrics() {
  return StaticShadowVisualMetrics(
    left: 10,
    top: 20,
    visualWidth: 100,
    visualHeight: 80,
  );
}

ProjectedBuildingShadowGeometry _geometry(
  List<ProjectedBuildingShadowPoint> points,
) {
  return ProjectedBuildingShadowGeometry(
    points: points,
    opacity: 0.5,
    colorHexRgb: '000000',
  );
}

List<ProjectedBuildingShadowPoint> _validPoints() {
  return [
    ProjectedBuildingShadowPoint(x: 0, y: 0),
    ProjectedBuildingShadowPoint(x: 0, y: 10),
    ProjectedBuildingShadowPoint(x: 10, y: 10),
    ProjectedBuildingShadowPoint(x: 10, y: 0),
  ];
}

void _expectPointClose(
  ProjectedBuildingShadowPoint actual, {
  required double x,
  required double y,
  double tolerance = 0.000001,
}) {
  expect(actual.x, closeTo(x, tolerance));
  expect(actual.y, closeTo(y, tolerance));
}
```

### Contenu complet — packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/projected_building_shadow_runtime_adapter.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('createProjectedBuildingShadowRuntimeInstruction', () {
    test('converts geometry to a ground projected polygon instruction', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 0, y: 0),
            ProjectedBuildingShadowPoint(x: 10, y: 0),
            ProjectedBuildingShadowPoint(x: 10, y: 5),
            ProjectedBuildingShadowPoint(x: 0, y: 5),
          ],
          opacity: 0.18,
          colorHexRgb: '000000',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '000000');
      expect(instruction.worldLeft, 0);
      expect(instruction.worldTop, 0);
      expect(instruction.width, 10);
      expect(instruction.height, 5);
      expect(
        instruction.polygonPoints,
        [
          ShadowRuntimePoint(worldX: 0, worldY: 0),
          ShadowRuntimePoint(worldX: 10, worldY: 0),
          ShadowRuntimePoint(worldX: 10, worldY: 5),
          ShadowRuntimePoint(worldX: 0, worldY: 5),
        ],
      );
    });

    test('converts footprint geometry to runtime projected polygon instruction',
        () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 28.80, y: 146.56),
            ProjectedBuildingShadowPoint(x: 99.20, y: 146.56),
            ProjectedBuildingShadowPoint(x: 108.80, y: 173.44),
            ProjectedBuildingShadowPoint(x: 32.00, y: 173.44),
          ],
          opacity: 0.28,
          colorHexRgb: '606060',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.28);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.worldLeft, closeTo(28.80, 0.02));
      expect(instruction.worldTop, closeTo(146.56, 0.02));
      expect(instruction.width, closeTo(80.00, 0.02));
      expect(instruction.height, closeTo(26.88, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
    });

    test(
        'converts footprint v1 geometry to runtime projected polygon instruction',
        () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 22.40, y: 142.72),
            ProjectedBuildingShadowPoint(x: 105.60, y: 142.72),
            ProjectedBuildingShadowPoint(x: 114.56, y: 167.68),
            ProjectedBuildingShadowPoint(x: 23.68, y: 167.68),
          ],
          opacity: 0.24,
          colorHexRgb: '606060',
        ),
      );

      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.24);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.worldLeft, closeTo(22.40, 0.02));
      expect(instruction.worldTop, closeTo(142.72, 0.02));
      expect(instruction.width, closeTo(92.16, 0.02));
      expect(instruction.height, closeTo(24.96, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
    });

    test('preserves point order exactly', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: 1, y: 2),
            ProjectedBuildingShadowPoint(x: 3, y: 5),
            ProjectedBuildingShadowPoint(x: 8, y: 13),
            ProjectedBuildingShadowPoint(x: 21, y: 34),
          ],
        ),
      );

      expect(
        instruction.polygonPoints,
        [
          ShadowRuntimePoint(worldX: 1, worldY: 2),
          ShadowRuntimePoint(worldX: 3, worldY: 5),
          ShadowRuntimePoint(worldX: 8, worldY: 13),
          ShadowRuntimePoint(worldX: 21, worldY: 34),
        ],
      );
    });

    test('preserves appearance values', () {
      final instruction = createProjectedBuildingShadowRuntimeInstruction(
        _geometry(
          [
            ProjectedBuildingShadowPoint(x: -5, y: 2),
            ProjectedBuildingShadowPoint(x: 6, y: 3),
            ProjectedBuildingShadowPoint(x: 8, y: 14),
            ProjectedBuildingShadowPoint(x: -3, y: 12),
          ],
          opacity: 0.42,
          colorHexRgb: '123ABC',
        ),
      );

      expect(instruction.opacity, 0.42);
      expect(instruction.colorHexRgb, '123ABC');
    });

    test('keeps runtime validation for degenerate polygons', () {
      expect(
        () => createProjectedBuildingShadowRuntimeInstruction(
          _geometry(
            [
              ProjectedBuildingShadowPoint(x: 0, y: 0),
              ProjectedBuildingShadowPoint(x: 1, y: 1),
              ProjectedBuildingShadowPoint(x: 2, y: 2),
              ProjectedBuildingShadowPoint(x: 3, y: 3),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('adapter source stays independent from render and traversal layers',
        () {
      final source = File(
        'lib/src/shadow/projected_building_shadow_runtime_adapter.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'dart:' 'ui',
        'package:' 'flutter',
        'package:' 'flame',
        'Can' 'vas',
        'Pa' 'th',
        'Pa' 'int',
        'generic' 'Projection',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'Project' 'Manifest',
        'ProjectElement' 'Entry',
        'Map' 'Data',
        'MapPlaced' 'Element',
        'static_shadow_family' '_projection',
        'static_shadow_projection' '_geometry',
        'static_shadow_contact_ledge' '_geometry',
        'element_auto_shadow' '_policy',
        'projected_building_shadow' '_diagnostics',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectedBuildingShadowGeometry _geometry(
  List<ProjectedBuildingShadowPoint> points, {
  double opacity = 0.18,
  String colorHexRgb = '000000',
}) {
  return ProjectedBuildingShadowGeometry(
    points: points,
    opacity: opacity,
    colorHexRgb: colorHexRgb,
  );
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.02));
  expect(point.worldY, closeTo(y, 0.02));
}
```

### Contenu complet — packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/shadow/runtime_projected_building_shadow_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  group('buildRuntimeProjectedBuildingShadowCollection', () {
    test('returns an empty collection when no element has a projected shadow',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(elements: [_element()]),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection, ShadowRuntimeInstructionCollection());
      expect(collection.groundStatic, isEmpty);
      expect(collection.actorContact, isEmpty);
    });

    test('builds one ground projected polygon for a valid projected shadow',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData:
            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.18);
      expect(instruction.colorHexRgb, '123ABC');
      expect(instruction.worldLeft, closeTo(64, 0.000001));
      expect(instruction.worldTop, closeTo(128, 0.000001));
      expect(instruction.width, closeTo(48, 0.000001));
      expect(instruction.height, closeTo(64, 0.000001));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
      _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
      _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
      _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
    });

    test(
        'buildRuntimeProjectedBuildingShadowCollection resolves footprint preset through map_core geometry',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_footprintPreset()]),
          elements: [
            _element(
              projectedBuildingShadow:
                  _config(presetId: 'pokemon-building-shadow-footprint-v0'),
            ),
          ],
        ),
        mapData:
            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.28);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.worldLeft, closeTo(28.80, 0.02));
      expect(instruction.worldTop, closeTo(146.56, 0.02));
      expect(instruction.width, closeTo(80.00, 0.02));
      expect(instruction.height, closeTo(26.88, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
    });

    test(
        'buildRuntimeProjectedBuildingShadowCollection resolves footprint v1 preset through map_core geometry',
        () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_footprintV1Preset()]),
          elements: [
            _element(
              projectedBuildingShadow:
                  _config(presetId: 'pokemon-building-shadow-footprint-v1'),
            ),
          ],
        ),
        mapData:
            _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
      );

      expect(collection.length, 1);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
      expect(instruction.opacity, 0.24);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.worldLeft, closeTo(22.40, 0.02));
      expect(instruction.worldTop, closeTo(142.72, 0.02));
      expect(instruction.width, closeTo(92.16, 0.02));
      expect(instruction.height, closeTo(24.96, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
    });

    test('skips disabled projected shadow config', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(projectedBuildingShadow: _config(enabled: false)),
          ],
        ),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection.isEmpty, isTrue);
    });

    test('skips missing preset without throwing', () {
      late ShadowRuntimeInstructionCollection collection;

      expect(
        () {
          collection = buildRuntimeProjectedBuildingShadowCollection(
            manifest: _manifest(
              catalog: _catalog([]),
              elements: [
                _element(projectedBuildingShadow: _config(presetId: 'missing')),
              ],
            ),
            mapData: _map(placedElements: [_placed()]),
          );
        },
        returnsNormally,
      );
      expect(collection.isEmpty, isTrue);
    });

    test('skips missing element without throwing', () {
      late ShadowRuntimeInstructionCollection collection;

      expect(
        () {
          collection = buildRuntimeProjectedBuildingShadowCollection(
            manifest: _manifest(
              catalog: _catalog([_preset()]),
              elements: const [],
            ),
            mapData: _map(
              placedElements: [_placed(elementId: 'missing-element')],
            ),
          );
        },
        returnsNormally,
      );
      expect(collection.isEmpty, isTrue);
    });

    test(
        'skips hidden or transparent placement layers and zero opacity placement',
        () {
      final manifest = _manifest(
        catalog: _catalog([_preset()]),
        elements: [_element(projectedBuildingShadow: _config())],
      );

      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(
            layers: [_layer(isVisible: false)],
            placedElements: [_placed()],
          ),
        ).isEmpty,
        isTrue,
      );
      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(
            layers: [_layer(opacity: 0)],
            placedElements: [_placed()],
          ),
        ).isEmpty,
        isTrue,
      );
      expect(
        buildRuntimeProjectedBuildingShadowCollection(
          manifest: manifest,
          mapData: _map(placedElements: [_placed(opacity: 0)]),
        ).isEmpty,
        isTrue,
      );
    });

    test('does not multiply preset opacity by placement opacity', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData: _map(placedElements: [_placed(opacity: 0.5)]),
      );

      expect(collection.groundStatic.single.opacity, 0.18);
    });

    test('preserves source placement order', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        mapData: _map(
          placedElements: [
            _placed(id: 'late-left', pos: const GridPos(x: 5, y: 2)),
            _placed(id: 'early-left', pos: const GridPos(x: 1, y: 2)),
          ],
        ),
      );

      expect(collection.groundStatic, hasLength(2));
      expect(collection.groundStatic[0].worldLeft, greaterThan(100));
      expect(collection.groundStatic[1].worldLeft, lessThan(100));
    });

    test('does not block V2 when the element also has a V1 shadow', () {
      final collection = buildRuntimeProjectedBuildingShadowCollection(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(
              shadow: ProjectElementShadowConfig(
                castsShadow: true,
                shadowProfileId: 'legacy-shadow',
              ),
              projectedBuildingShadow: _config(),
            ),
          ],
        ),
        mapData: _map(placedElements: [_placed()]),
      );

      expect(collection.groundStatic, hasLength(1));
    });

    test(
        'builder source stays independent from renderer and diagnostics layers',
        () {
      final source = File(
        'lib/src/shadow/runtime_projected_building_shadow_collection.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'generic' 'Projection',
        'applyElementAutoShadow' 'PolicyToProject',
        'diagnoseProjectedBuilding' 'Shadows',
        'Project' 'Validator',
        'Map' 'Validator',
        'resolveProjected' 'StaticShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'Can' 'vas',
        'Pa' 'th',
        'Pa' 'int',
        'dart:' 'ui',
        'package:' 'flutter',
        'package:' 'flame',
        'static_shadow_family' '_projection',
        'static_shadow_projection' '_geometry',
        'static_shadow_contact_ledge' '_geometry',
        'element_auto_shadow' '_policy',
        'projected_building_shadow' '_diagnostics',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

MapData _map({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 10, height: 10),
    layers: layers ?? [_layer()],
    placedElements: placedElements,
  );
}

MapLayer _layer({
  String id = 'objects',
  bool isVisible = true,
  double opacity = 1,
}) {
  return MapLayer.tile(
    id: id,
    name: 'Objects',
    tilesetId: 'tileset',
    isVisible: isVisible,
    opacity: opacity,
  );
}

ProjectElementEntry _element({
  String id = 'building',
  ProjectElementShadowConfig? shadow,
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
  int sourceWidth = 2,
  int sourceHeight = 3,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'Building',
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(
          x: 0,
          y: 0,
          width: sourceWidth,
          height: sourceHeight,
        ),
      ),
    ],
    shadow: shadow,
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

MapPlacedElement _placed({
  String id = 'building-placed',
  String layerId = 'objects',
  String elementId = 'building',
  GridPos pos = const GridPos(x: 1, y: 2),
  double opacity = 1,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    opacity: opacity,
  );
}

ProjectBuildingShadowPresetCatalog _catalog(
  List<ProjectBuildingShadowPreset> presets,
) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  String id = 'shadow-a',
  double opacity = 0.18,
  String colorHexRgb = '123ABC',
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: opacity,
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    footprint: ProjectedShadowFootprintTuning(),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _footprintV1Preset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v1',
    name: 'Pokemon-like footprint building shadow V1',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(
      attachYRatio: 0.82,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.42,
      depthRatio: 0.26,
      skewXRatio: 0.08,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.24,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'shadow-a',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}
```

### Contenu complet — packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart

```dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/shadow/editor_projected_building_shadow_preview.dart';
import 'package:map_editor/src/application/shadow/editor_static_shadow_preview.dart';

void main() {
  group('buildEditorProjectedBuildingShadowPreviewInstructions', () {
    test('builds a projected polygon preview', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(
        instruction.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
      expect(instruction.opacity, 0.30);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.left, closeTo(52.46, 0.02));
      expect(instruction.top, closeTo(129.77, 0.02));
      expect(instruction.width, closeTo(48.92, 0.02));
      expect(instruction.height, closeTo(59.81, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 75.54, y: 129.77);
      _expectPointClose(instruction.polygonPoints[1], x: 52.46, y: 182.55);
      _expectPointClose(instruction.polygonPoints[2], x: 82.91, y: 189.58);
      _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
    });

    test(
        'buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint projected polygon preview',
        () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_footprintPreset()]),
          elements: [
            _element(
              projectedBuildingShadow: _config(
                presetId: 'pokemon-building-shadow-footprint-v0',
              ),
            ),
          ],
        ),
        map: _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(
        instruction.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
      expect(instruction.opacity, 0.28);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.left, closeTo(28.80, 0.02));
      expect(instruction.top, closeTo(146.56, 0.02));
      expect(instruction.width, closeTo(80.00, 0.02));
      expect(instruction.height, closeTo(26.88, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
    });

    test(
        'buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint v1 projected polygon preview',
        () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_footprintV1Preset()]),
          elements: [
            _element(
              projectedBuildingShadow: _config(
                presetId: 'pokemon-building-shadow-footprint-v1',
              ),
            ),
          ],
        ),
        map: _map(placedElements: [_placed(pos: const GridPos(x: 1, y: 2))]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, hasLength(1));
      final instruction = instructions.single;
      expect(
        instruction.shape,
        EditorStaticShadowPreviewShapeKind.projectedPolygon,
      );
      expect(instruction.opacity, 0.24);
      expect(instruction.colorHexRgb, '606060');
      expect(instruction.left, closeTo(22.40, 0.02));
      expect(instruction.top, closeTo(142.72, 0.02));
      expect(instruction.width, closeTo(92.16, 0.02));
      expect(instruction.height, closeTo(24.96, 0.02));
      expect(instruction.polygonPoints, hasLength(4));
      _expectPointClose(instruction.polygonPoints[0], x: 22.40, y: 142.72);
      _expectPointClose(instruction.polygonPoints[1], x: 105.60, y: 142.72);
      _expectPointClose(instruction.polygonPoints[2], x: 114.56, y: 167.68);
      _expectPointClose(instruction.polygonPoints[3], x: 23.68, y: 167.68);
    });

    test('returns empty when element has no projectedBuildingShadow config',
        () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element()],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('returns empty when projectedBuildingShadow is disabled', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(projectedBuildingShadow: _config(enabled: false)),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips missing projected building shadow preset without throwing', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          elements: [
            _element(projectedBuildingShadow: _config(presetId: 'missing')),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips hidden or transparent tile layers', () {
      final manifest = _manifest(
        catalog: _catalog([_preset()]),
        elements: [_element(projectedBuildingShadow: _config())],
      );

      expect(
        buildEditorProjectedBuildingShadowPreviewInstructions(
          manifest: manifest,
          map: _map(
            layers: [_layer(isVisible: false)],
            placedElements: [_placed()],
          ),
          tileWidth: 32,
          tileHeight: 32,
        ),
        isEmpty,
      );
      expect(
        buildEditorProjectedBuildingShadowPreviewInstructions(
          manifest: manifest,
          map: _map(
            layers: [_layer(opacity: 0)],
            placedElements: [_placed()],
          ),
          tileWidth: 32,
          tileHeight: 32,
        ),
        isEmpty,
      );
    });

    test('skips zero opacity placements', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(placedElements: [_placed(opacity: 0)]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('skips invalid visual source dimensions', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [
            _element(
              projectedBuildingShadow: _config(),
              sourceWidth: 0,
            ),
          ],
        ),
        map: _map(placedElements: [_placed()]),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(instructions, isEmpty);
    });

    test('preserves placed element source order', () {
      final instructions =
          buildEditorProjectedBuildingShadowPreviewInstructions(
        manifest: _manifest(
          catalog: _catalog([_preset()]),
          elements: [_element(projectedBuildingShadow: _config())],
        ),
        map: _map(
          placedElements: [
            _placed(id: 'first', pos: const GridPos(x: 1, y: 2)),
            _placed(id: 'second', pos: const GridPos(x: 3, y: 2)),
          ],
        ),
        tileWidth: 32,
        tileHeight: 32,
      );

      expect(
        instructions.map((instruction) => instruction.instanceId),
        ['first', 'second'],
      );
    });

    test('does not depend on runtime or auto projection', () {
      final source = File(
        'lib/src/application/shadow/editor_projected_building_shadow_preview.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'map_' 'runtime',
        'Shadow' 'Runtime',
        'buildRuntimeProjected' 'BuildingShadowCollection',
        'Shadow' 'Runtime' 'Renderer',
        'generic' 'Projection',
        'applyElementAutoShadowPolicy' 'ToProject',
        'diagnoseProjectedBuilding' 'Shadows',
        'resolveProjectedStatic' 'ShadowGeometry',
        'resolveStaticShadowFamily' 'ProjectionSpec',
        'static_shadow_family' '_projection',
        'element_auto_shadow' '_policy',
      ];

      for (final snippet in forbiddenSnippets) {
        expect(source, isNot(contains(snippet)));
      }
    });
  });
}

ProjectManifest _manifest({
  ProjectBuildingShadowPresetCatalog? catalog,
  List<ProjectElementEntry> elements = const [],
}) {
  return ProjectManifest(
    name: 'Project',
    maps: const [],
    tilesets: const [],
    elements: elements,
    settings: const ProjectSettings(
      tileWidth: 16,
      tileHeight: 16,
      displayScale: 2,
    ),
    surfaceCatalog: ProjectSurfaceCatalog(),
    projectedBuildingShadowCatalog:
        catalog ?? const ProjectBuildingShadowPresetCatalog.empty(),
  );
}

MapData _map({
  List<MapLayer>? layers,
  List<MapPlacedElement> placedElements = const [],
}) {
  return MapData(
    id: 'map',
    name: 'Map',
    size: const GridSize(width: 10, height: 10),
    layers: layers ?? [_layer()],
    placedElements: placedElements,
  );
}

MapLayer _layer({
  String id = 'objects',
  bool isVisible = true,
  double opacity = 1,
}) {
  return MapLayer.tile(
    id: id,
    name: 'Objects',
    tilesetId: 'tileset',
    isVisible: isVisible,
    opacity: opacity,
  );
}

MapPlacedElement _placed({
  String id = 'building-placed',
  String layerId = 'objects',
  String elementId = 'building',
  GridPos pos = const GridPos(x: 1, y: 2),
  double opacity = 1,
}) {
  return MapPlacedElement(
    id: id,
    layerId: layerId,
    elementId: elementId,
    pos: pos,
    opacity: opacity,
  );
}

ProjectElementEntry _element({
  String id = 'building',
  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
  int sourceWidth = 2,
  int sourceHeight = 3,
}) {
  return ProjectElementEntry(
    id: id,
    name: 'Building',
    tilesetId: 'tileset',
    categoryId: 'building',
    frames: [
      TilesetVisualFrame(
        source: TilesetSourceRect(
          x: 0,
          y: 0,
          width: sourceWidth,
          height: sourceHeight,
        ),
      ),
    ],
    projectedBuildingShadow: projectedBuildingShadow,
  );
}

ProjectBuildingShadowPresetCatalog _catalog(
  List<ProjectBuildingShadowPreset> presets,
) {
  return ProjectBuildingShadowPresetCatalog(presets: presets);
}

ProjectBuildingShadowPreset _preset({
  String id = 'pokemon-building-shadow-v0',
  double opacity = 0.30,
  String colorHexRgb = '606060',
}) {
  return ProjectBuildingShadowPreset(
    id: id,
    name: 'Pokemon-like building shadow V0',
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: opacity,
      colorHexRgb: colorHexRgb,
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _footprintPreset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v0',
    name: 'Pokemon-like footprint building shadow V0',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(),
    appearance: ProjectedShadowAppearance(
      opacity: 0.28,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectBuildingShadowPreset _footprintV1Preset() {
  return ProjectBuildingShadowPreset(
    id: 'pokemon-building-shadow-footprint-v1',
    name: 'Pokemon-like footprint building shadow V1',
    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.32,
      nearWidthRatio: 0.90,
      farWidthRatio: 0.72,
    ),
    footprint: ProjectedShadowFootprintTuning(
      attachYRatio: 0.82,
      frontWidthRatio: 1.30,
      rearWidthRatio: 1.42,
      depthRatio: 0.26,
      skewXRatio: 0.08,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.24,
      colorHexRgb: '606060',
    ),
    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
  );
}

ProjectElementProjectedBuildingShadowConfig _config({
  bool enabled = true,
  String presetId = 'pokemon-building-shadow-v0',
}) {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: enabled,
    presetId: presetId,
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

void _expectPointClose(
  EditorStaticShadowPreviewPoint point, {
  required double x,
  required double y,
}) {
  expect(point.x, closeTo(x, 0.02));
  expect(point.y, closeTo(y, 0.02));
}
```

Checklist finale :
- [x] Aucun fichier de production modifié
- [x] Aucun fichier map_core/lib modifié
- [x] Aucun fichier runtime lib modifié
- [x] Aucun fichier editor lib modifié
- [x] Aucun renderer modifié
- [x] Aucun painter modifié
- [x] Aucun JSON/codec modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Defaults ProjectedShadowFootprintTuning() inchangés
- [x] Preset pokemon-building-shadow-footprint-v1 utilisé
- [x] attachYRatio 0.82 utilisé
- [x] frontWidthRatio 1.30 utilisé
- [x] rearWidthRatio 1.42 utilisé
- [x] depthRatio 0.26 utilisé
- [x] skewXRatio 0.08 utilisé
- [x] opacity 0.24 utilisée
- [x] colorHexRgb 606060 utilisé
- [x] Points V1 vérifiés
- [x] Bounds V1 vérifiés
- [x] Runtime adapter V1 testé
- [x] Runtime collection V1 testée
- [x] Editor preview V1 testée
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
