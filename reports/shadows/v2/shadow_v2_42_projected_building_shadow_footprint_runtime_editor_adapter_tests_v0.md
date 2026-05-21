# ShadowV2-42 — Projected Building Shadow Footprint Runtime / Editor Adapter Tests V0

## 1. Résumé exécutif

ShadowV2-42 a ajouté uniquement des tests runtime/editor. Aucun fichier de production n'a été modifié.

Résultat : GREEN-on-add confirmé. Les adapters existants consomment déjà Footprint Geometry V0 sans changement de production :

- runtime adapter direct : footprint converti en `ShadowRuntimeShapeKind.projectedPolygon` ;
- runtime collection : preset footprint in-memory résolu via `map_core` et transmis en instruction runtime ;
- runtime V1 suppression : la legacy V1 same-element reste supprimée avec footprint ;
- editor preview : preset footprint in-memory résolu via `map_core` et transmis en preview `projectedPolygon` ;
- editor V1 suppression : la legacy preview V1 same-element reste supprimée avec footprint.

Conclusion : les chemins runtime/editor sont compatibles pour un POC in-memory. Le risque JSON/persistence reste séparé.

## 2. Objectif du lot

Objectif exact :

```text
Prouver par des tests runtime/editor que Footprint Geometry V0,
déjà implémenté dans map_core,
traverse les adapters existants sans modification de production runtime/editor.
```

Ce lot est test-only. Il ne crée pas d'image, pas de baseline, pas de fixture Selbrume, pas de codec JSON.

## 3. Rappel ShadowV2-40 / ShadowV2-41

ShadowV2-40 a ajouté le core footprint dans `map_core` :

```text
ProjectedBuildingShadowGeometryMode
ProjectedShadowFootprintTuning
ProjectBuildingShadowPreset.geometryMode
ProjectBuildingShadowPreset.footprint
resolveProjectedBuildingShadowGeometry(...)
```

Micro-fixture footprint attendue :

```text
frontLeft  = (28.80, 146.56)
frontRight = (99.20, 146.56)
rearRight  = (108.80, 173.44)
rearLeft   = (32.00, 173.44)

bounds:
left = 28.80
top = 146.56
width = 80.00
height = 26.88
```

ShadowV2-41 a conclu :

```text
runtime adapter : déjà compatible
editor preview : déjà compatible
renderer : pas besoin de modification
painter : pas besoin de modification
JSON : risque séparé, non bloquant pour un POC in-memory
V1 same-element suppression : à prouver par tests footprint
```

## 4. État initial du worktree

Commande :

```bash
cd /Users/karim/Project/pokemonProject
git status --short --untracked-files=all
```

Sortie initiale :

```text
```

Le worktree était propre avant ShadowV2-42.

Fichiers préexistants hors scope :

```text
Aucun
```

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sorties utiles :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Le design gate était déjà satisfait par ShadowV2-41. Ce lot applique le plan test-only.

## 6. Fichiers créés / modifiés / supprimés

Fichiers modifiés par ShadowV2-42 :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Fichier créé par ShadowV2-42 :

```text
reports/shadows/v2/shadow_v2_42_projected_building_shadow_footprint_runtime_editor_adapter_tests_v0.md
```

Fichiers supprimés par ShadowV2-42 :

```text
Aucun
```

Fichiers de production modifiés :

```text
Aucun
```

## 7. Audit initial runtime/editor/core

Commandes exécutées :

```bash
rg -n "ProjectedBuildingShadowGeometryMode|ProjectedShadowFootprintTuning|geometryMode|footprint|resolveProjectedBuildingShadowGeometry|frontLeft|frontRight|rearRight|rearLeft" packages/map_core/lib packages/map_core/test/shadow_v2 reports/shadows/v2
rg -n "createProjectedBuildingShadowRuntimeInstruction|buildRuntimeProjectedBuildingShadowCollection|resolveProjectedBuildingShadowGeometry|ShadowRuntimeRenderInstruction|ShadowRuntimePoint|projectedPolygon|polygonPoints|colorHexRgb|opacity" packages/map_runtime/lib packages/map_runtime/test/shadow
rg -n "buildEditorProjectedBuildingShadowPreviewInstructions|resolveProjectedBuildingShadowGeometry|EditorStaticShadowPreviewInstruction|EditorStaticShadowPreviewPoint|projectedPolygon|polygonPoints|colorHexRgb|opacity" packages/map_editor/lib packages/map_editor/test
rg -n "_hasResolvableProjectedBuildingShadow|projectedBuildingShadowCatalog|shadowOverride|legacy static shadow|same-element|buildRuntimeStaticPlacedElementShadowSources|buildEditorStaticShadowPreviewInstructions" packages/map_runtime/lib packages/map_runtime/test/shadow packages/map_editor/lib packages/map_editor/test reports/shadows/v2
```

Constats :

- `map_core` expose déjà Footprint Geometry V0.
- `buildRuntimeProjectedBuildingShadowCollection(...)` passe par le resolver map_core.
- `createProjectedBuildingShadowRuntimeInstruction(...)` convertit génériquement les points.
- `buildEditorProjectedBuildingShadowPreviewInstructions(...)` passe par le resolver map_core.
- La preview editor convertit génériquement les points.
- Les règles V1 same-element existent déjà côté runtime/editor.
- JSON/persistence n'est pas utilisé dans ces tests.

## 8. Fixture footprint commune

Fixture utilisée dans les tests :

```text
preset id: pokemon-building-shadow-footprint-v0
preset name: Pokemon-like footprint building shadow V0
geometryMode: ProjectedBuildingShadowGeometryMode.footprint
footprint: ProjectedShadowFootprintTuning()
appearance.opacity: 0.28
appearance.colorHexRgb: 606060
```

Config :

```text
enabled: true
presetId: pokemon-building-shadow-footprint-v0
anchor: valid, ignored by footprint V0
localOffset: (0, 0)
```

Points vérifiés :

```text
(28.80, 146.56)
(99.20, 146.56)
(108.80, 173.44)
(32.00, 173.44)
```

Bounds vérifiés :

```text
left = 28.80
top = 146.56
width = 80.00
height = 26.88
```

## 9. Test runtime adapter footprint

Fichier :

```text
packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Test ajouté :

```text
converts footprint geometry to runtime projected polygon instruction
```

Preuve :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
00:00 +0: createProjectedBuildingShadowRuntimeInstruction converts geometry to a ground projected polygon instruction
00:00 +1: createProjectedBuildingShadowRuntimeInstruction converts footprint geometry to runtime projected polygon instruction
00:00 +2: createProjectedBuildingShadowRuntimeInstruction preserves point order exactly
00:00 +3: createProjectedBuildingShadowRuntimeInstruction preserves appearance values
00:00 +4: createProjectedBuildingShadowRuntimeInstruction keeps runtime validation for degenerate polygons
00:00 +5: createProjectedBuildingShadowRuntimeInstruction adapter source stays independent from render and traversal layers
00:00 +6: All tests passed!
```

Assertions ajoutées :

```text
shape == projectedPolygon
renderPass == groundStatic
opacity == 0.28
colorHexRgb == 606060
worldLeft ~= 28.80
worldTop ~= 146.56
width ~= 80.00
height ~= 26.88
polygonPoints.length == 4
points footprint exacts avec tolérance 0.02
```

## 10. Test runtime collection footprint

Fichier :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
```

Test ajouté :

```text
buildRuntimeProjectedBuildingShadowCollection resolves footprint preset through map_core geometry
```

Preuve :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
00:00 +0: buildRuntimeProjectedBuildingShadowCollection returns an empty collection when no element has a projected shadow
00:00 +1: buildRuntimeProjectedBuildingShadowCollection builds one ground projected polygon for a valid projected shadow
00:00 +2: buildRuntimeProjectedBuildingShadowCollection buildRuntimeProjectedBuildingShadowCollection resolves footprint preset through map_core geometry
00:00 +3: buildRuntimeProjectedBuildingShadowCollection skips disabled projected shadow config
00:00 +4: buildRuntimeProjectedBuildingShadowCollection skips missing preset without throwing
00:00 +5: buildRuntimeProjectedBuildingShadowCollection skips missing element without throwing
00:00 +6: buildRuntimeProjectedBuildingShadowCollection skips hidden or transparent placement layers and zero opacity placement
00:00 +7: buildRuntimeProjectedBuildingShadowCollection does not multiply preset opacity by placement opacity
00:00 +8: buildRuntimeProjectedBuildingShadowCollection preserves source placement order
00:00 +9: buildRuntimeProjectedBuildingShadowCollection does not block V2 when the element also has a V1 shadow
00:00 +10: buildRuntimeProjectedBuildingShadowCollection builder source stays independent from renderer and diagnostics layers
00:00 +11: All tests passed!
```

Assertions ajoutées :

```text
collection.length == 1
groundStatic.length == 1
actorContact empty
shape == projectedPolygon
renderPass == groundStatic
opacity == 0.28
colorHexRgb == 606060
bounds footprint attendus
points footprint attendus
```

## 11. Test runtime V1 suppression footprint

Fichier :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Test ajouté :

```text
skips legacy static shadow when same element has resolvable footprint projected building shadow
```

Preuve :

```text
00:00 +3: buildRuntimeStaticPlacedElementShadowSources skips legacy static shadow when same element has resolvable projected building shadow
00:00 +4: buildRuntimeStaticPlacedElementShadowSources skips legacy static shadow when same element has resolvable footprint projected building shadow
00:00 +33: All tests passed!
```

Assertions ajoutées :

```text
buildRuntimeStaticPlacedElementShadowSources(...) == empty
buildRuntimeStaticPlacedElementShadowCollectionForBundle(...).isEmpty == true
```

## 12. Test editor preview footprint

Fichier :

```text
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Test ajouté :

```text
buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint projected polygon preview
```

Preuve :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
00:00 +0: buildEditorProjectedBuildingShadowPreviewInstructions builds a projected polygon preview
00:00 +1: buildEditorProjectedBuildingShadowPreviewInstructions buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint projected polygon preview
00:00 +2: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when element has no projectedBuildingShadow config
00:00 +3: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when projectedBuildingShadow is disabled
00:00 +4: buildEditorProjectedBuildingShadowPreviewInstructions skips missing projected building shadow preset without throwing
00:00 +5: buildEditorProjectedBuildingShadowPreviewInstructions skips hidden or transparent tile layers
00:00 +6: buildEditorProjectedBuildingShadowPreviewInstructions skips zero opacity placements
00:00 +7: buildEditorProjectedBuildingShadowPreviewInstructions skips invalid visual source dimensions
00:00 +8: buildEditorProjectedBuildingShadowPreviewInstructions preserves placed element source order
00:00 +9: buildEditorProjectedBuildingShadowPreviewInstructions does not depend on runtime or auto projection
00:00 +10: All tests passed!
```

Assertions ajoutées :

```text
instructions.length == 1
shape == projectedPolygon
opacity == 0.28
colorHexRgb == 606060
left ~= 28.80
top ~= 146.56
width ~= 80.00
height ~= 26.88
polygonPoints.length == 4
points footprint attendus
```

## 13. Test editor V1 suppression footprint

Fichier :

```text
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Test ajouté :

```text
skips legacy static shadow preview when same element has resolvable footprint projected building shadow
```

Preuve :

```text
00:00 +9: buildEditorStaticShadowPreviewInstructions skips legacy static shadow preview when same element has resolvable projected building shadow
00:00 +10: buildEditorStaticShadowPreviewInstructions skips legacy static shadow preview when same element has resolvable footprint projected building shadow
00:00 +25: All tests passed!
```

Assertion ajoutée :

```text
buildEditorStaticShadowPreviewInstructions(...) retourne empty
```

## 14. RED / GREEN observé

GREEN-on-add observé.

Les nouveaux tests ont été ajoutés après audit. Ils ont passé sans modification de production runtime/editor/core.

Raison :

```text
Les adapters existants appellent déjà resolveProjectedBuildingShadowGeometry(...)
et convertissent déjà les points génériquement en projectedPolygon.
```

## 15. Résultats des tests

Tests ciblés runtime :

```bash
cd packages/map_runtime && flutter test test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

```text
00:00 +6: All tests passed!
```

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_collection_test.dart
```

```text
00:00 +11: All tests passed!
```

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

```text
00:00 +33: All tests passed!
```

Tests ciblés editor :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

```text
00:00 +10: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

```text
00:00 +25: All tests passed!
```

Régressions utiles :

```bash
cd packages/map_core && dart test test/shadow_v2 --reporter json
```

```json
{
  "success": true,
  "type": "done",
  "time": 840
}
```

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

```text
00:02 +12: All tests passed!
```

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart
```

```text
00:00 +21: All tests passed!
```

## 16. Résultat analyze

Runtime :

```bash
cd packages/map_runtime && flutter analyze test/shadow/projected_building_shadow_runtime_adapter_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

```text
Analyzing 3 items...
No issues found! (ran in 1.6s)
```

Editor :

```bash
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart test/application/shadow/editor_static_shadow_preview_test.dart
```

```text
Analyzing 2 items...
No issues found! (ran in 0.9s)
```

## 17. Audit anti-dérive

Commande :

```bash
rg -n "packages/map_core/lib|packages/map_runtime/lib|packages/map_editor/lib|matchesGoldenFile|reports/shadows/baselines|SHADOW_SCREENSHOT|selbrume|genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|build_runner" packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Sortie :

```text
```

Résultat : aucun hit.

## 18. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

## 19. Ce qui n’a volontairement pas été créé

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

## 20. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 ...tor_projected_building_shadow_preview_test.dart | 59 ++++++++++++++++++++++
 .../shadow/editor_static_shadow_preview_test.dart  | 47 ++++++++++++++++-
 ...ected_building_shadow_runtime_adapter_test.dart | 39 ++++++++++++++
 ..._projected_building_shadow_collection_test.dart | 57 +++++++++++++++++++++
 ...atic_placed_element_shadow_collection_test.dart | 48 +++++++++++++++++-
 5 files changed, 246 insertions(+), 4 deletions(-)
```

Note : le rapport ShadowV2-42 est non suivi, donc il n'apparaît pas dans `git diff --stat`.

## 21. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
M	packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
M	packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
M	packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

## 22. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

Résultat : propre.

## 23. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
?? reports/shadows/v2/shadow_v2_42_projected_building_shadow_footprint_runtime_editor_adapter_tests_v0.md
```

Conformité scope :

```text
5 fichiers de test modifiés
1 rapport Markdown créé
0 fichier de production modifié
0 fichier map_core modifié
0 fichier runtime lib modifié
0 fichier editor lib modifié
0 screenshot
0 baseline
0 Selbrume
0 codec JSON
```

## 24. Risques / réserves

- JSON/persistence reste non traité. Footprint V0 est prouvé in-memory, pas encore prouvé via `project.json`.
- Le prochain artifact visuel doit encore vérifier le rendu artistique réel du footprint.
- Les bandes hard-edge existantes restent actives, car Footprint V0 produit 4 points.

## 25. Auto-critique

- Le lot est-il bien test-only ?
  Oui. Cinq fichiers de test modifiés, un rapport créé, aucun fichier production.

- Les tests prouvent-ils réellement que les adapters existants supportent footprint ?
  Oui. Runtime collection et editor preview construisent des presets footprint in-memory et vérifient les points issus du resolver map_core.

- Les tests évitent-ils toute modification production ?
  Oui.

- Les tests utilisent-ils la même micro-fixture footprint ?
  Oui pour les tests collection/preview avec `placed.pos = (1,2)` et dimensions `2x3`.

- V1 same-element suppression est-elle vérifiée avec footprint ?
  Oui côté runtime et editor.

- Le risque JSON/persistence est-il toujours séparé ?
  Oui.

- Le lot évite-t-il images / baseline / Selbrume ?
  Oui.

- Le rapport contient-il toutes les preuves ?
  Oui : commandes, résultats, audit, diff, status final.

## 26. Regard critique sur le prompt

Le prompt était bien borné. Le point important est le GREEN-on-add : il confirme que le design Footprint V0 a été posé au bon niveau, dans `map_core`, sans forcer une modification production runtime/editor.

Le prochain lot ne devrait pas partir directement sur JSON. La meilleure suite est un micro artifact visuel footprint, car la compatibilité technique est maintenant prouvée in-memory.

## 27. Prochain lot recommandé

Recommandation :

```text
ShadowV2-43 — Projected Building Shadow Footprint Micro Visual Artifact V0
```

Objectif :

```text
Générer une image micro-fixture avec le vrai Footprint V0,
rendu par le runtime,
pour vérifier visuellement si l’ombre se rapproche de la référence Pokémon-like.
```

Hors scope du Lot 43 recommandé :

```text
Selbrume
baseline
golden
JSON persistence
renderer/painter changes
shader
blur
UI authoring
```

## 28. Code complet des fichiers créés/modifiés

Le rapport courant est le fichier créé par ce lot.

Diff complet des fichiers de test modifiés :

```diff
diff --git a/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart b/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
index a4998361..06789b97 100644
--- a/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
+++ b/packages/map_runtime/test/shadow/projected_building_shadow_runtime_adapter_test.dart
@@ -40,6 +40,36 @@ void main() {
       );
     });
 
+    test('converts footprint geometry to runtime projected polygon instruction',
+        () {
+      final instruction = createProjectedBuildingShadowRuntimeInstruction(
+        _geometry(
+          [
+            ProjectedBuildingShadowPoint(x: 28.80, y: 146.56),
+            ProjectedBuildingShadowPoint(x: 99.20, y: 146.56),
+            ProjectedBuildingShadowPoint(x: 108.80, y: 173.44),
+            ProjectedBuildingShadowPoint(x: 32.00, y: 173.44),
+          ],
+          opacity: 0.28,
+          colorHexRgb: '606060',
+        ),
+      );
+
+      expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
+      expect(instruction.renderPass, ShadowRenderPass.groundStatic);
+      expect(instruction.opacity, 0.28);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.worldLeft, closeTo(28.80, 0.02));
+      expect(instruction.worldTop, closeTo(146.56, 0.02));
+      expect(instruction.width, closeTo(80.00, 0.02));
+      expect(instruction.height, closeTo(26.88, 0.02));
+      expect(instruction.polygonPoints, hasLength(4));
+      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
+      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
+      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
+      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
+    });
+
     test('preserves point order exactly', () {
       final instruction = createProjectedBuildingShadowRuntimeInstruction(
         _geometry(
@@ -141,3 +171,12 @@ ProjectedBuildingShadowGeometry _geometry(
     colorHexRgb: colorHexRgb,
   );
 }
+
+void _expectPointClose(
+  ShadowRuntimePoint point, {
+  required double x,
+  required double y,
+}) {
+  expect(point.worldX, closeTo(x, 0.02));
+  expect(point.worldY, closeTo(y, 0.02));
+}

diff --git a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
index 5ddbe379..8fed90b3 100644
--- a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_collection_test.dart
@@ -51,6 +51,43 @@ void main() {
       _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
     });
 
+    test(
+        'buildRuntimeProjectedBuildingShadowCollection resolves footprint preset through map_core geometry',
+        () {
+      final collection = buildRuntimeProjectedBuildingShadowCollection(
+        manifest: _manifest(
+          catalog: _catalog([_footprintPreset()]),
+          elements: [
+            _element(
+              projectedBuildingShadow:
+                  _config(presetId: 'pokemon-building-shadow-footprint-v0'),
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
+      expect(instruction.opacity, 0.28);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.worldLeft, closeTo(28.80, 0.02));
+      expect(instruction.worldTop, closeTo(146.56, 0.02));
+      expect(instruction.width, closeTo(80.00, 0.02));
+      expect(instruction.height, closeTo(26.88, 0.02));
+      expect(instruction.polygonPoints, hasLength(4));
+      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
+      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
+      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
+      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
+    });
+
     test('skips disabled projected shadow config', () {
       final collection = buildRuntimeProjectedBuildingShadowCollection(
         manifest: _manifest(
@@ -345,6 +382,26 @@ ProjectBuildingShadowPreset _preset({
   );
 }
 
+ProjectBuildingShadowPreset _footprintPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'pokemon-building-shadow-footprint-v0',
+    name: 'Pokemon-like footprint building shadow V0',
+    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+    direction: ProjectedShadowDirection(x: 1, y: 0),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.5,
+      nearWidthRatio: 1,
+      farWidthRatio: 0.5,
+    ),
+    footprint: ProjectedShadowFootprintTuning(),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.28,
+      colorHexRgb: '606060',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
 ProjectElementProjectedBuildingShadowConfig _config({
   bool enabled = true,
   String presetId = 'shadow-a',

diff --git a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
index cd86c370..cc7b9e75 100644
--- a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
@@ -58,6 +58,26 @@ void main() {
       );
     });
 
+    test(
+        'skips legacy static shadow when same element has resolvable footprint projected building shadow',
+        () {
+      final bundle = _bundle(
+        projectedBuildingShadow: _projectedConfig(
+          presetId: 'pokemon-building-shadow-footprint-v0',
+        ),
+        projectedPreset: _projectedFootprintPreset(),
+      );
+
+      expect(buildRuntimeStaticPlacedElementShadowSources(bundle: bundle),
+          isEmpty);
+      expect(
+        buildRuntimeStaticPlacedElementShadowCollectionForBundle(
+          bundle: bundle,
+        ).isEmpty,
+        isTrue,
+      );
+    });
+
     test('keeps legacy static shadow when element has no projected shadow', () {
       final sources = buildRuntimeStaticPlacedElementShadowSources(
         bundle: _bundle(),
@@ -666,6 +686,7 @@ RuntimeMapBundle _bundle({
   bool includeProjectedPreset = true,
   bool includeLegacyOnlyElement = false,
   MapPlacedElementShadowOverride? placedOverride,
+  ProjectBuildingShadowPreset? projectedPreset,
 }) {
   return RuntimeMapBundle(
     manifest: ProjectManifest(
@@ -718,7 +739,9 @@ RuntimeMapBundle _bundle({
       surfaceCatalog: ProjectSurfaceCatalog(),
       shadowCatalog: _catalog(),
       projectedBuildingShadowCatalog: includeProjectedPreset
-          ? ProjectBuildingShadowPresetCatalog(presets: [_projectedPreset()])
+          ? ProjectBuildingShadowPresetCatalog(
+              presets: [projectedPreset ?? _projectedPreset()],
+            )
           : const ProjectBuildingShadowPresetCatalog.empty(),
     ),
     map: MapData(
@@ -771,10 +794,11 @@ RuntimeMapBundle _bundle({
 
 ProjectElementProjectedBuildingShadowConfig _projectedConfig({
   bool enabled = true,
+  String presetId = 'shadow-a',
 }) {
   return ProjectElementProjectedBuildingShadowConfig(
     enabled: enabled,
-    presetId: 'shadow-a',
+    presetId: presetId,
     anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
     localOffset: ProjectedShadowOffset(x: 0, y: 0),
   );
@@ -798,6 +822,26 @@ ProjectBuildingShadowPreset _projectedPreset() {
   );
 }
 
+ProjectBuildingShadowPreset _projectedFootprintPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'pokemon-building-shadow-footprint-v0',
+    name: 'Pokemon-like footprint building shadow V0',
+    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+    direction: ProjectedShadowDirection(x: 1, y: 0),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.5,
+      nearWidthRatio: 1,
+      farWidthRatio: 0.5,
+    ),
+    footprint: ProjectedShadowFootprintTuning(),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.28,
+      colorHexRgb: '606060',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
 ProjectShadowCatalog _catalog() {
   return ProjectShadowCatalog(
     profiles: [

diff --git a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
index 87f3fa92..aa808f90 100644
--- a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
@@ -38,6 +38,45 @@ void main() {
       _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
     });
 
+    test(
+        'buildEditorProjectedBuildingShadowPreviewInstructions builds a footprint projected polygon preview',
+        () {
+      final instructions =
+          buildEditorProjectedBuildingShadowPreviewInstructions(
+        manifest: _manifest(
+          catalog: _catalog([_footprintPreset()]),
+          elements: [
+            _element(
+              projectedBuildingShadow: _config(
+                presetId: 'pokemon-building-shadow-footprint-v0',
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
+      expect(instruction.opacity, 0.28);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.left, closeTo(28.80, 0.02));
+      expect(instruction.top, closeTo(146.56, 0.02));
+      expect(instruction.width, closeTo(80.00, 0.02));
+      expect(instruction.height, closeTo(26.88, 0.02));
+      expect(instruction.polygonPoints, hasLength(4));
+      _expectPointClose(instruction.polygonPoints[0], x: 28.80, y: 146.56);
+      _expectPointClose(instruction.polygonPoints[1], x: 99.20, y: 146.56);
+      _expectPointClose(instruction.polygonPoints[2], x: 108.80, y: 173.44);
+      _expectPointClose(instruction.polygonPoints[3], x: 32.00, y: 173.44);
+    });
+
     test('returns empty when element has no projectedBuildingShadow config',
         () {
       final instructions =
@@ -318,6 +357,26 @@ ProjectBuildingShadowPreset _preset({
   );
 }
 
+ProjectBuildingShadowPreset _footprintPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'pokemon-building-shadow-footprint-v0',
+    name: 'Pokemon-like footprint building shadow V0',
+    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.32,
+      nearWidthRatio: 0.90,
+      farWidthRatio: 0.72,
+    ),
+    footprint: ProjectedShadowFootprintTuning(),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.28,
+      colorHexRgb: '606060',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
 ProjectElementProjectedBuildingShadowConfig _config({
   bool enabled = true,
   String presetId = 'pokemon-building-shadow-v0',

diff --git a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
index 1622fa74..42ada273 100644
--- a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
@@ -276,6 +276,25 @@ void main() {
       expect(instructions, isEmpty);
     });
 
+    test(
+        'skips legacy static shadow preview when same element has resolvable footprint projected building shadow',
+        () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          projectedBuildingShadow: _projectedConfig(
+            presetId: 'pokemon-building-shadow-footprint-v0',
+          ),
+          includeProjectedPreset: true,
+          projectedPreset: _projectedFootprintPreset(),
+        ),
+        map: _map(),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(instructions, isEmpty);
+    });
+
     test(
         'keeps legacy static shadow preview when element has no projected building shadow',
         () {
@@ -935,6 +954,7 @@ ProjectManifest _manifest({
   bool includeProjectedPreset = false,
   bool omitElementShadow = false,
   List<TilesetVisualFrame>? frames,
+  ProjectBuildingShadowPreset? projectedPreset,
 }) {
   return ProjectManifest(
     name: 'Project',
@@ -946,7 +966,9 @@ ProjectManifest _manifest({
         ),
     surfaceCatalog: ProjectSurfaceCatalog(),
     projectedBuildingShadowCatalog: includeProjectedPreset
-        ? ProjectBuildingShadowPresetCatalog(presets: [_projectedPreset()])
+        ? ProjectBuildingShadowPresetCatalog(
+            presets: [projectedPreset ?? _projectedPreset()],
+          )
         : const ProjectBuildingShadowPresetCatalog.empty(),
     elements: [
       ProjectElementEntry(
@@ -1025,10 +1047,11 @@ ProjectShadowProfile _profile(
 
 ProjectElementProjectedBuildingShadowConfig _projectedConfig({
   bool enabled = true,
+  String presetId = 'shadow-a',
 }) {
   return ProjectElementProjectedBuildingShadowConfig(
     enabled: enabled,
-    presetId: 'shadow-a',
+    presetId: presetId,
     anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
     localOffset: ProjectedShadowOffset(x: 0, y: 0),
   );
@@ -1051,3 +1074,23 @@ ProjectBuildingShadowPreset _projectedPreset() {
     timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
   );
 }
+
+ProjectBuildingShadowPreset _projectedFootprintPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'pokemon-building-shadow-footprint-v0',
+    name: 'Pokemon-like footprint building shadow V0',
+    geometryMode: ProjectedBuildingShadowGeometryMode.footprint,
+    direction: ProjectedShadowDirection(x: 1, y: 0),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.5,
+      nearWidthRatio: 1,
+      farWidthRatio: 0.5,
+    ),
+    footprint: ProjectedShadowFootprintTuning(),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.28,
+      colorHexRgb: '606060',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
```

Checklist finale :

- [x] Aucun fichier de production modifié
- [x] Aucun fichier map_core modifié
- [x] Aucun fichier runtime lib modifié
- [x] Aucun fichier editor lib modifié
- [x] Aucun renderer modifié
- [x] Aucun painter modifié
- [x] Aucun JSON/codec modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Runtime adapter footprint testé
- [x] Runtime collection footprint testée
- [x] Runtime V1 suppression footprint testée
- [x] Editor preview footprint testée
- [x] Editor V1 suppression footprint testée
- [x] Points footprint vérifiés
- [x] Bounds footprint vérifiés
- [x] Opacity 0.28 vérifiée
- [x] Color 606060 vérifiée
- [x] Tests ciblés passés
- [x] Régressions utiles passées
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
