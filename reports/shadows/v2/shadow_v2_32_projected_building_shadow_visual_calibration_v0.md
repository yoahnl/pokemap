# ShadowV2-32 — Projected Building Shadow Visual Calibration V0

## 1. Résumé exécutif

Lot 32 implémenté en test-only / micro-fixture calibration.

La calibration ShadowV2 V0 recommandée au Lot 31 est maintenant verrouillée dans :

- `packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart`
- `packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart`
- `packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart`

Calibration appliquée :

```text
preset id: pokemon-building-shadow-v0
preset name: Pokemon-like building shadow V0
direction: (0.8, 0.35)
lengthRatio: 0.32
nearWidthRatio: 0.90
farWidthRatio: 0.72
opacity: 0.30
colorHexRgb: 606060
timeOfDayMode: fixed
anchor: (0.5, 0.96)
localOffset: (0, 0)
```

Aucun fichier de production n'a été modifié. Aucun fichier `map_core/lib`, `map_runtime/lib` ou `map_editor/lib` n'a été modifié. Aucun Selbrume, screenshot, baseline, renderer, painter, modèle, codec ou generated n'a été touché.

## 2. Objectif du lot

Verrouiller la calibration ShadowV2 V0 dans des tests ciblés map_core / map_runtime / map_editor.

Chaîne prouvée :

```text
map_core:
preset V0 + config V0 + metrics
-> points calibrés attendus

map_runtime:
PlayableMapGame micro-fixture V2 calibrée
-> provider runtime
-> ShadowRuntimeRenderer
-> pixel intérieur alpha > 0
-> pixel extérieur alpha == 0

map_editor:
buildEditorProjectedBuildingShadowPreviewInstructions(...)
-> EditorStaticShadowPreviewInstruction calibrée
-> points/bounds/opacité/couleur attendus
```

## 3. Rappel ShadowV2-31

ShadowV2-31 a recommandé une calibration par preset uniquement, sans toucher :

- au renderer runtime ;
- au painter editor ;
- aux modèles ;
- aux codecs ;
- à Selbrume ;
- aux assets.

Le Lot 31 a aussi calculé les points attendus sur la micro-fixture historique :

```text
nearLeft  = (75.54, 129.77)
nearRight = (52.46, 182.55)
farRight  = (82.91, 189.58)
farLeft   = (101.38, 147.36)
```

Le pixel intérieur recommandé `(80,150)` reste dans le polygone calibré et le pixel extérieur `(10,10)` reste clairement hors ombre.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
(aucune ligne)
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

## 5. Décision AGENTS / design gate déjà satisfait

AGENTS trouvés :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Instruction pertinente :

```text
AGENTS.md:1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
```

Décision :

- le design gate a été satisfait par ShadowV2-31 ;
- le Lot 32 est une implémentation test-only bornée ;
- aucun design supplémentaire n'était nécessaire ;
- TDD appliqué avec un RED map_core avant GREEN.

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
```

Fichiers modifiés :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Fichiers supprimés :

```text
Aucun.
```

Generated / screenshots / baselines :

```text
Aucun.
```

Fichiers de production modifiés :

```text
Aucun.
```

## 7. Audit initial des anciennes/nouvelles valeurs

Commande anciennes valeurs :

```bash
rg -n "123ABC|0.18|shadow-a|ProjectedShadowDirection\(x: 1, y: 0\)|lengthRatio: 0.5|nearWidthRatio: 1|farWidthRatio: 0.5|ProjectedShadowAnchor\(xRatio: 0.5, yRatio: 1\)" packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Synthèse initiale :

- `map_core` utilisait les anciennes valeurs dans les tests historiques et helpers `_preset` / `_config`.
- `map_runtime` utilisait `shadow-a`, `(1,0)`, `0.5/1/0.5`, `0.18`, `123ABC`, anchor `yRatio: 1` dans la micro-fixture visual POC.
- `map_editor` utilisait `shadow-a`, `(1,0)`, `0.5/1/0.5`, `0.18`, `123ABC`, anchor `yRatio: 1` dans la micro-fixture preview.

Commande nouvelles valeurs :

```bash
rg -n "pokemon-building-shadow-v0|606060|0.30|lengthRatio: 0.32|nearWidthRatio: 0.90|farWidthRatio: 0.72|ProjectedShadowDirection\(x: 0.8, y: 0.35\)|ProjectedShadowAnchor\(xRatio: 0.5, yRatio: 0.96\)" packages/map_core/test packages/map_runtime/test packages/map_editor/test
```

Synthèse initiale :

- les valeurs V0 n'étaient pas encore présentes dans les trois micro-fixtures ciblées ;
- des valeurs numériques comme `0.30` ou `0.32` existaient ailleurs dans des tests sans lien avec ShadowV2 calibration.

Audit anti-dérive initial :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|matchesGoldenFile|SHADOW_SCREENSHOT|reports/shadows/baselines|selbrume" packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie initiale :

```text
(aucune ligne)
```

## 8. Calibration V0 appliquée

Calibration appliquée dans les micro-fixtures calibrées :

```text
preset id: pokemon-building-shadow-v0
preset name: Pokemon-like building shadow V0
direction: ProjectedShadowDirection(x: 0.8, y: 0.35)
shape.lengthRatio: 0.32
shape.nearWidthRatio: 0.90
shape.farWidthRatio: 0.72
appearance.opacity: 0.30
appearance.colorHexRgb: 606060
timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed
anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96)
localOffset: ProjectedShadowOffset(x: 0, y: 0)
```

Reliquats volontairement conservés :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Ce fichier conserve des anciennes valeurs dans des tests historiques non calibrés :

```text
direction: (1,0)
lengthRatio: 0.5
nearWidthRatio: 1
farWidthRatio: 0.5
anchor yRatio: 1
opacity: 0.18
```

Ces reliquats ne sont pas dans la micro-fixture calibrée `pokemon-building-shadow-v0`. Ils caractérisent encore la géométrie horizontale de base, la normalisation et les helpers existants.

## 9. Test map_core géométrie calibrée

Test ajouté :

```text
resolves pokemon-building-shadow-v0 geometry with calibrated points
```

Assertions ajoutées :

- `geometry != null`
- `geometry.opacity == 0.30`
- `geometry.colorHexRgb == '606060'`
- `geometry.points.length == 4`
- points attendus avec `closeTo(..., 0.02)`

Points vérifiés :

```text
(75.54, 129.77)
(52.46, 182.55)
(82.91, 189.58)
(101.38, 147.36)
```

## 10. Test runtime visual POC calibré

Le visual POC runtime utilise maintenant :

```text
presetId: pokemon-building-shadow-v0
colorHexRgb: 606060
opacity: 0.30
direction: (0.8, 0.35)
shape: 0.32 / 0.90 / 0.72
anchor: (0.5, 0.96)
```

Assertions runtime mises à jour :

- instruction V2 `projectedPolygon` ;
- render pass `groundStatic` ;
- couleur `606060` ;
- opacité `0.30` ;
- points calibrés ;
- pixel intérieur `(80,150)` alpha > 0 ;
- pixel extérieur `(10,10)` alpha == 0 ;
- same-element V1 supprimée quand V2 est résoluble.

Le pixel `(80,150)` n'a pas été changé : il reste intérieur après calibration.

## 11. Test editor preview calibrée

La preview editor utilise maintenant la même calibration V0.

Assertions editor mises à jour :

- instruction `EditorStaticShadowPreviewShapeKind.projectedPolygon` ;
- opacité `0.30` ;
- couleur `606060` ;
- points calibrés ;
- bounds calibrés.

Bounds vérifiés :

```text
left ≈ 52.46
top ≈ 129.77
width ≈ 48.92
height ≈ 59.81
```

Les tests de skip restent inchangés dans leur intention :

- config absente ;
- config disabled ;
- preset manquant ;
- layer invisible / transparent ;
- placement opacity 0 ;
- source invalide ;
- ordre source ;
- anti-dépendance runtime.

## 12. TDD RED initial

RED tentative 1 :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie :

```text
Failed to load "test/shadow_v2/projected_building_shadow_geometry_test.dart":
test/shadow_v2/projected_building_shadow_geometry_test.dart:148:24: Error: Cannot invoke a non-'const' constructor where a const expression is expected.
Try using a constructor or factory that is 'const'.
        metrics: const StaticShadowVisualMetrics(
                       ^^^^^^^^^^^^^^^^^^^^^^^^^
Some tests failed.
```

Analyse : ce RED était un échec de chargement dû à un `const` incorrect sur `StaticShadowVisualMetrics`, donc pas le RED utile attendu.

RED utile après correction du `const` :

```bash
cd packages/map_core && dart test test/shadow_v2/projected_building_shadow_geometry_test.dart
```

Sortie utile :

```text
00:00 +8 -1: Projected building shadow geometry resolves pokemon-building-shadow-v0 geometry with calibrated points [E]
  Expected: <0.3>
    Actual: <0.18>

  package:matcher                                                    expect
  test/shadow_v2/projected_building_shadow_geometry_test.dart 157:7  main.<fn>.<fn>

00:00 +12 -1: Some tests failed.
```

Conclusion RED :

```text
Le test échouait bien parce que le setup historique produisait encore l'opacité V2 0.18 au lieu de la calibration 0.30.
```

## 13. Résultats des tests

### Test map_core ciblé

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
00:00 +9: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
00:00 +10: Projected building shadow geometry geometry defensively copies points and exposes an immutable list
00:00 +10: Projected building shadow geometry point and geometry equality include ordered values
00:00 +11: Projected building shadow geometry point and geometry equality include ordered values
00:00 +11: Projected building shadow geometry geometry validates points, opacity, and color
00:00 +12: Projected building shadow geometry geometry validates points, opacity, and color
00:00 +12: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +13: Projected building shadow geometry geometry source stays independent from runtime editor and manifest
00:00 +13: All tests passed!
```

### Test runtime ciblé

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
00:00 +0: runtime projected building shadow visual POC runtime projected building visual POC renders host-provided V2 polygon pixels
[runtime] Map loaded: projected-building-shadow-visual-poc, spawn at (0, 0)
00:00 +1: runtime projected building shadow visual POC runtime projected building visual POC suppresses same-element V1 when V2 is resolvable
[runtime] Map loaded: projected-building-shadow-visual-poc, spawn at (0, 0)
00:00 +2: runtime projected building shadow visual POC runtime projected building visual POC does not use screenshots baselines or auto projection
00:00 +3: All tests passed!
```

### Test editor ciblé

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie complète :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
00:00 +0: buildEditorProjectedBuildingShadowPreviewInstructions builds a projected polygon preview
00:00 +1: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when element has no projectedBuildingShadow config
00:00 +2: buildEditorProjectedBuildingShadowPreviewInstructions returns empty when projectedBuildingShadow is disabled
00:00 +3: buildEditorProjectedBuildingShadowPreviewInstructions skips missing projected building shadow preset without throwing
00:00 +4: buildEditorProjectedBuildingShadowPreviewInstructions skips hidden or transparent tile layers
00:00 +5: buildEditorProjectedBuildingShadowPreviewInstructions skips zero opacity placements
00:00 +6: buildEditorProjectedBuildingShadowPreviewInstructions skips invalid visual source dimensions
00:00 +7: buildEditorProjectedBuildingShadowPreviewInstructions preserves placed element source order
00:00 +8: buildEditorProjectedBuildingShadowPreviewInstructions does not depend on runtime or auto projection
00:00 +9: All tests passed!
```

### Régression map_core shadow_v2

Commande :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +151: All tests passed!
```

Note : une première tentative de wrapper shell a échoué avant test avec `zsh:1: read-only variable: status`. La commande a été relancée avec `exit_code`.

### Régressions runtime utiles

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart test/shadow/runtime_projected_building_shadow_collection_test.dart test/shadow/projected_building_shadow_runtime_adapter_test.dart
```

Ligne finale exacte :

```text
00:00 +24: All tests passed!
```

### Régressions editor utiles

Commande :

```bash
cd packages/map_editor && flutter test test/map_grid_painter_test.dart test/application/shadow/editor_static_shadow_preview_test.dart
```

Ligne finale exacte :

```text
00:00 +38: All tests passed!
```

## 14. Résultat analyze

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
cd packages/map_runtime && flutter analyze test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie complète :

```text
Analyzing runtime_projected_building_shadow_visual_poc_test.dart...
No issues found! (ran in 2.8s)
```

Commande :

```bash
cd packages/map_editor && flutter analyze test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie complète :

```text
Analyzing editor_projected_building_shadow_preview_test.dart...
No issues found! (ran in 1.9s)
```

## 15. Audit anti-dérive

Commande finale :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|matchesGoldenFile|SHADOW_SCREENSHOT|reports/shadows/baselines|selbrume" packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
```

Sortie :

```text
(aucune ligne)
```

Audit final des anciennes valeurs :

```text
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:22: direction: ProjectedShadowDirection(x: 1, y: 0)
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:24: lengthRatio: 0.5
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:25: nearWidthRatio: 1
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:26: farWidthRatio: 0.5
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:42: ProjectedShadowDirection(x: 1, y: 0)
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:321: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1)
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:336: ProjectedShadowDirection(x: 1, y: 0)
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:339: lengthRatio: 0.5
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:340: nearWidthRatio: 1
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:341: farWidthRatio: 0.5
packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart:343: ProjectedShadowAppearance(opacity: 0.18)
```

Interprétation :

```text
Ces hits sont des tests/helpers historiques map_core non calibrés.
Les micro-fixtures calibrées runtime/editor et le nouveau test map_core utilisent bien la calibration V0.
```

## 16. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/lib/**
packages/map_runtime/lib/**
packages/map_editor/lib/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_core/lib/src/models/**
packages/map_core/lib/src/operations/projected_building_shadow_geometry.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
/Users/karim/Desktop/selbrume/**
reports/shadows/screenshots/**
reports/shadows/baselines/**
```

## 17. Ce qui n’a volontairement pas été créé

```text
screenshot
baseline
fixture Selbrume
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
outil de cleanup
```

## 18. git diff --stat

Sortie finale constatée :

```text
 .../projected_building_shadow_geometry_test.dart   | 69 +++++++++++++++++++++-
 ...tor_projected_building_shadow_preview_test.dart | 44 +++++++-------
 ..._projected_building_shadow_visual_poc_test.dart | 40 ++++++-------
 3 files changed, 109 insertions(+), 44 deletions(-)
```

## 19. git diff --name-status

Sortie finale constatée :

```text
M	packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
M	packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
M	packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

## 20. git diff --check

Sortie finale constatée :

```text
(aucune ligne)
```

## 21. git status final

Sortie finale constatée :

```text
 M packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
 M packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
?? reports/shadows/v2/shadow_v2_32_projected_building_shadow_visual_calibration_v0.md
```

## 22. Risques / réserves

- Le Lot 32 verrouille une micro-fixture, pas une application Selbrume.
- Les anciennes valeurs restent dans des tests map_core historiques non calibrés ; elles ne représentent pas la calibration V0.
- Le rendu reste bandé hard-edge comme décidé au Lot 31 ; aucun renderer/painter n'a été modifié.
- Le pixel runtime `(80,150)` est toujours intérieur au polygone calibré, mais une future modification de géométrie nécessitera de le revalider.

## 23. Auto-critique

- Le lot est-il bien test-only ? Oui, seuls trois tests et un rapport sont touchés.
- Les valeurs du preset correspondent-elles exactement au Lot 31 ? Oui.
- Les points attendus sont-ils explicites et non recalculés par le test ? Oui.
- Les tests runtime/editor restent-ils alignés ? Oui, mêmes preset/config/points.
- Le pixel intérieur est-il toujours dans le polygone ? Oui, `(80,150)` reste intérieur.
- Les anciennes couleurs sentinelles ne survivent-elles pas dans les tests calibrés ? Oui, `123ABC` n'est plus dans les micro-fixtures runtime/editor ; il ne reste pas dans le nouveau test map_core.
- Le lot évite-t-il production / Selbrume / screenshot / baseline ? Oui.
- Le rapport contient-il toutes les preuves ? Oui, avec le détail des commandes, sorties, diffs et code complet.

## 24. Regard critique sur le prompt

Le prompt est bien borné : trois tests autorisés, un rapport, aucune production. Le RED obligatoire était utile pour éviter un simple remplacement cosmétique.

Point de vigilance : demander que les anciennes valeurs ne restent pas dans les trois fichiers peut entrer en tension avec les tests historiques map_core qui caractérisent volontairement la géométrie horizontale. J'ai conservé ces tests hors micro-fixture calibrée et documenté les reliquats.

## 25. Prochain lot recommandé

Prochain lot recommandé :

```text
ShadowV2-33 — Projected Building Shadow Micro Visual Baseline Design Gate
```

Objectif probable :

```text
Définir une preuve visuelle micro-fixture contrôlée pour inspecter la calibration V0,
sans appliquer Selbrume,
sans screenshot massif,
sans baseline lourde,
et en décidant explicitement si les bandes hard-edge restent acceptables.
```

Alternative si la calibration révèle une gêne artistique :

```text
ShadowV2-33 — Projected Building Shadow Hard-Edge Banding Review Design Gate
```

## 26. Code complet des fichiers créés/modifiés

Le rapport courant est le fichier créé ; il ne s'auto-inclut pas récursivement.

### Diff complet — packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart

```diff
diff --git a/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart b/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
index ed3d3a3e..096753f8 100644
--- a/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
+++ b/packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart
@@ -140,6 +140,70 @@ void main() {
       expect(followsSun, fixed);
     });
 
+    test('resolves pokemon-building-shadow-v0 geometry with calibrated points',
+        () {
+      final preset = ProjectBuildingShadowPreset(
+        id: 'pokemon-building-shadow-v0',
+        name: 'Pokemon-like building shadow V0',
+        direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
+        shape: ProjectedShadowShapeTuning(
+          lengthRatio: 0.32,
+          nearWidthRatio: 0.90,
+          farWidthRatio: 0.72,
+        ),
+        appearance: ProjectedShadowAppearance(
+          opacity: 0.30,
+          colorHexRgb: '606060',
+        ),
+        timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+      );
+      final config = ProjectElementProjectedBuildingShadowConfig(
+        enabled: true,
+        presetId: 'pokemon-building-shadow-v0',
+        anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
+        localOffset: ProjectedShadowOffset(x: 0, y: 0),
+      );
+      final geometry = resolveProjectedBuildingShadowGeometry(
+        config: config,
+        preset: preset,
+        metrics: StaticShadowVisualMetrics(
+          left: 32,
+          top: 64,
+          visualWidth: 64,
+          visualHeight: 96,
+        ),
+      );
+
+      expect(geometry, isNotNull);
+      expect(geometry!.opacity, 0.30);
+      expect(geometry.colorHexRgb, '606060');
+      expect(geometry.points, hasLength(4));
+      _expectPointClose(
+        geometry.points[0],
+        x: 75.54,
+        y: 129.77,
+        tolerance: 0.02,
+      );
+      _expectPointClose(
+        geometry.points[1],
+        x: 52.46,
+        y: 182.55,
+        tolerance: 0.02,
+      );
+      _expectPointClose(
+        geometry.points[2],
+        x: 82.91,
+        y: 189.58,
+        tolerance: 0.02,
+      );
+      _expectPointClose(
+        geometry.points[3],
+        x: 101.38,
+        y: 147.36,
+        tolerance: 0.02,
+      );
+    });
+
     test('geometry defensively copies points and exposes an immutable list',
         () {
       final source = [
@@ -313,7 +377,8 @@ void _expectPointClose(
   ProjectedBuildingShadowPoint actual, {
   required double x,
   required double y,
+  double tolerance = 0.000001,
 }) {
-  expect(actual.x, closeTo(x, 0.000001));
-  expect(actual.y, closeTo(y, 0.000001));
+  expect(actual.x, closeTo(x, tolerance));
+  expect(actual.y, closeTo(y, tolerance));
 }
```

### Diff complet — packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
index 643c390f..c6a5a31f 100644
--- a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
@@ -190,25 +190,25 @@ RuntimeMapBundle _bundle({
 ProjectElementProjectedBuildingShadowConfig _projectedConfig() {
   return ProjectElementProjectedBuildingShadowConfig(
     enabled: true,
-    presetId: 'shadow-a',
-    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
+    presetId: 'pokemon-building-shadow-v0',
+    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
     localOffset: ProjectedShadowOffset(x: 0, y: 0),
   );
 }
 
 ProjectBuildingShadowPreset _preset() {
   return ProjectBuildingShadowPreset(
-    id: 'shadow-a',
-    name: 'Shadow A',
-    direction: ProjectedShadowDirection(x: 1, y: 0),
+    id: 'pokemon-building-shadow-v0',
+    name: 'Pokemon-like building shadow V0',
+    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
     shape: ProjectedShadowShapeTuning(
-      lengthRatio: 0.5,
-      nearWidthRatio: 1,
-      farWidthRatio: 0.5,
+      lengthRatio: 0.32,
+      nearWidthRatio: 0.90,
+      farWidthRatio: 0.72,
     ),
     appearance: ProjectedShadowAppearance(
-      opacity: 0.18,
-      colorHexRgb: '123ABC',
+      opacity: 0.30,
+      colorHexRgb: '606060',
     ),
     timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
   );
@@ -251,8 +251,8 @@ List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
         (instruction) =>
             instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
             instruction.renderPass == ShadowRenderPass.groundStatic &&
-            instruction.colorHexRgb == '123ABC' &&
-            instruction.opacity == 0.18,
+            instruction.colorHexRgb == '606060' &&
+            instruction.opacity == 0.30,
       )
       .toList(growable: false);
 }
@@ -273,13 +273,13 @@ void _expectProjectedBuildingInstruction(
 ) {
   expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
   expect(instruction.renderPass, ShadowRenderPass.groundStatic);
-  expect(instruction.opacity, 0.18);
-  expect(instruction.colorHexRgb, '123ABC');
+  expect(instruction.opacity, 0.30);
+  expect(instruction.colorHexRgb, '606060');
   expect(instruction.polygonPoints, hasLength(4));
-  _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
-  _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
-  _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
-  _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
+  _expectPointClose(instruction.polygonPoints[0], x: 75.54, y: 129.77);
+  _expectPointClose(instruction.polygonPoints[1], x: 52.46, y: 182.55);
+  _expectPointClose(instruction.polygonPoints[2], x: 82.91, y: 189.58);
+  _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
 }
 
 void _expectPointClose(
@@ -287,8 +287,8 @@ void _expectPointClose(
   required double x,
   required double y,
 }) {
-  expect(point.worldX, closeTo(x, 0.000001));
-  expect(point.worldY, closeTo(y, 0.000001));
+  expect(point.worldX, closeTo(x, 0.02));
+  expect(point.worldY, closeTo(y, 0.02));
 }
```

### Diff complet — packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart

```diff
diff --git a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
index eaa4945a..87f3fa92 100644
--- a/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart
@@ -25,17 +25,17 @@ void main() {
         instruction.shape,
         EditorStaticShadowPreviewShapeKind.projectedPolygon,
       );
-      expect(instruction.opacity, 0.18);
-      expect(instruction.colorHexRgb, '123ABC');
-      expect(instruction.left, 64);
-      expect(instruction.top, 128);
-      expect(instruction.width, 48);
-      expect(instruction.height, 64);
+      expect(instruction.opacity, 0.30);
+      expect(instruction.colorHexRgb, '606060');
+      expect(instruction.left, closeTo(52.46, 0.02));
+      expect(instruction.top, closeTo(129.77, 0.02));
+      expect(instruction.width, closeTo(48.92, 0.02));
+      expect(instruction.height, closeTo(59.81, 0.02));
       expect(instruction.polygonPoints, hasLength(4));
-      _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
-      _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
-      _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
-      _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
+      _expectPointClose(instruction.polygonPoints[0], x: 75.54, y: 129.77);
+      _expectPointClose(instruction.polygonPoints[1], x: 52.46, y: 182.55);
+      _expectPointClose(instruction.polygonPoints[2], x: 82.91, y: 189.58);
+      _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
     });
 
     test('returns empty when element has no projectedBuildingShadow config',
@@ -297,18 +297,18 @@ ProjectBuildingShadowPresetCatalog _catalog(
 }
 
 ProjectBuildingShadowPreset _preset({
-  String id = 'shadow-a',
-  double opacity = 0.18,
-  String colorHexRgb = '123ABC',
+  String id = 'pokemon-building-shadow-v0',
+  double opacity = 0.30,
+  String colorHexRgb = '606060',
 }) {
   return ProjectBuildingShadowPreset(
     id: id,
-    name: 'Shadow A',
-    direction: ProjectedShadowDirection(x: 1, y: 0),
+    name: 'Pokemon-like building shadow V0',
+    direction: ProjectedShadowDirection(x: 0.8, y: 0.35),
     shape: ProjectedShadowShapeTuning(
-      lengthRatio: 0.5,
-      nearWidthRatio: 1,
-      farWidthRatio: 0.5,
+      lengthRatio: 0.32,
+      nearWidthRatio: 0.90,
+      farWidthRatio: 0.72,
     ),
     appearance: ProjectedShadowAppearance(
       opacity: opacity,
@@ -320,12 +320,12 @@ ProjectBuildingShadowPreset _preset({
 
 ProjectElementProjectedBuildingShadowConfig _config({
   bool enabled = true,
-  String presetId = 'shadow-a',
+  String presetId = 'pokemon-building-shadow-v0',
 }) {
   return ProjectElementProjectedBuildingShadowConfig(
     enabled: enabled,
     presetId: presetId,
-    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
+    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
     localOffset: ProjectedShadowOffset(x: 0, y: 0),
   );
 }
@@ -335,6 +335,6 @@ void _expectPointClose(
   required double x,
   required double y,
 }) {
-  expect(point.x, closeTo(x, 0.000001));
-  expect(point.y, closeTo(y, 0.000001));
+  expect(point.x, closeTo(x, 0.02));
+  expect(point.y, closeTo(y, 0.02));
 }
```

### Code complet — packages/map_core/test/shadow_v2/projected_building_shadow_geometry_test.dart

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

### Code complet — packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart

```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_renderer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime projected building shadow visual POC', () {
    test(
        'runtime projected building visual POC renders host-provided V2 polygon pixels',
        () async {
      final collection = await _hostShadowCollection();

      expect(collection, isNotNull);
      final v2Instructions = _projectedBuildingInstructions(collection!);
      expect(v2Instructions, hasLength(1));
      final instruction = v2Instructions.single;
      _expectProjectedBuildingInstruction(instruction);

      final image = await _renderGroundStaticShadows(
        collection,
        width: 160,
        height: 224,
      );

      expect(await _alphaAt(image, 80, 150), greaterThan(0));
      expect(await _alphaAt(image, 10, 10), 0);
    });

    test(
        'runtime projected building visual POC suppresses same-element V1 when V2 is resolvable',
        () async {
      final collection = await _hostShadowCollection(withV1Shadow: true);
      final groundStatic = collection!.groundStatic;

      expect(groundStatic, hasLength(1));
      _expectProjectedBuildingInstruction(groundStatic.single);
      expect(_legacyStaticInstructions(collection), isEmpty);
    });

    test(
        'runtime projected building visual POC does not use screenshots '
        'base'
        'lines or auto projection', () {
      final source = File(
        'test/shadow/runtime_projected_building_shadow_visual_poc_test.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
        'matches' 'GoldenFile',
        'SHADOW_' 'SCREENSHOT',
        'sel' 'brume',
        'base' 'line_manifest' '.json',
        'reports/shadows/base' 'lines',
        'diagnoseProjectedBuilding' 'Shadows',
        'applyElementAutoShadow' 'PolicyToProject',
        'generic' 'Projection',
        'resolveProjected' 'StaticShadowGeometry',
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

Future<ShadowRuntimeInstructionCollection?> _hostShadowCollection({
  bool withV1Shadow = false,
}) async {
  final game = PlayableMapGame(
    bundle: _bundle(withV1Shadow: withV1Shadow),
    projectFilePath: '/tmp/project.json',
    runtimeTilesetImageLoader: _emptyImageLoader,
    enableActorContactShadows: false,
  );

  game.onGameResize(Vector2(160, 224));
  await game.onLoad();
  game.update(0);
  final background = _backgroundLayer(game);

  expect(background.shadowCollectionProvider, isNotNull);
  return background.shadowCollectionProvider!();
}

RuntimeMapBundle _bundle({
  bool withV1Shadow = false,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Projected Building Shadow Visual POC',
      maps: const <ProjectMapEntry>[],
      tilesets: const <ProjectTilesetEntry>[],
      settings: const ProjectSettings(
        tileWidth: 16,
        tileHeight: 16,
        displayScale: 2,
        defaultPlayerCharacterId: 'player',
      ),
      elements: [
        ProjectElementEntry(
          id: 'building',
          name: 'Building',
          tilesetId: 'props',
          categoryId: 'building',
          frames: const [
            TilesetVisualFrame(
              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
            ),
          ],
          shadow: withV1Shadow
              ? ProjectElementShadowConfig(
                  castsShadow: true,
                  shadowProfileId: 'legacy-shadow',
                )
              : null,
          projectedBuildingShadow: _projectedConfig(),
        ),
      ],
      characters: const [
        ProjectCharacterEntry(
          id: 'player',
          name: 'Player',
          tilesetId: 'player',
          frameWidth: 2,
          frameHeight: 2,
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(),
      shadowCatalog: withV1Shadow
          ? _legacyShadowCatalog()
          : const ProjectShadowCatalog.empty(),
      projectedBuildingShadowCatalog: ProjectBuildingShadowPresetCatalog(
        presets: [_preset()],
      ),
    ),
    map: const MapData(
      id: 'projected-building-shadow-visual-poc',
      name: 'Projected Building Shadow Visual POC',
      size: GridSize(width: 4, height: 4),
      layers: [
        MapLayer.tile(
          id: 'objects',
          name: 'Objects',
          tilesetId: 'props',
          tiles: <int>[],
        ),
      ],
      placedElements: [
        MapPlacedElement(
          id: 'building-1',
          layerId: 'objects',
          elementId: 'building',
          pos: GridPos(x: 1, y: 2),
        ),
      ],
      entities: [
        MapEntity(
          id: 'spawn',
          name: 'Spawn',
          kind: MapEntityKind.spawn,
          pos: GridPos(x: 0, y: 0),
          blocksMovement: false,
          spawn: MapEntitySpawnData(
            role: EntitySpawnRole.playerStart,
            facing: EntityFacing.south,
          ),
        ),
      ],
      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
    ),
    projectRootDirectory: '/tmp/runtime-projected-building-shadow-visual-poc',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

ProjectElementProjectedBuildingShadowConfig _projectedConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'pokemon-building-shadow-v0',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 0.96),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset() {
  return ProjectBuildingShadowPreset(
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
}

ProjectShadowCatalog _legacyShadowCatalog() {
  return ProjectShadowCatalog(
    profiles: [
      ProjectShadowProfile(
        id: 'legacy-shadow',
        name: 'Legacy Shadow',
        mode: ShadowCasterMode.ellipse,
        renderPass: ShadowRenderPass.groundStatic,
        opacity: 0.35,
        colorHexRgb: '010203',
      ),
    ],
  );
}

Future<Map<String, RuntimeTilesetImage>> _emptyImageLoader(
  Map<String, String> absolutePathByTilesetId, {
  Map<String, TilesetTransparentColor> transparentColorByTilesetId =
      const <String, TilesetTransparentColor>{},
}) async {
  return const <String, RuntimeTilesetImage>{};
}

MapLayersComponent _backgroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.background,
      );
}

List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
            instruction.renderPass == ShadowRenderPass.groundStatic &&
            instruction.colorHexRgb == '606060' &&
            instruction.opacity == 0.30,
      )
      .toList(growable: false);
}

List<ShadowRuntimeRenderInstruction> _legacyStaticInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.colorHexRgb == '010203' && instruction.opacity == 0.35,
      )
      .toList(growable: false);
}

void _expectProjectedBuildingInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.shape, ShadowRuntimeShapeKind.projectedPolygon);
  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
  expect(instruction.opacity, 0.30);
  expect(instruction.colorHexRgb, '606060');
  expect(instruction.polygonPoints, hasLength(4));
  _expectPointClose(instruction.polygonPoints[0], x: 75.54, y: 129.77);
  _expectPointClose(instruction.polygonPoints[1], x: 52.46, y: 182.55);
  _expectPointClose(instruction.polygonPoints[2], x: 82.91, y: 189.58);
  _expectPointClose(instruction.polygonPoints[3], x: 101.38, y: 147.36);
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.02));
  expect(point.worldY, closeTo(y, 0.02));
}

Future<int> _alphaAt(ui.Image image, int x, int y) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  final offset = (y * image.width + x) * 4;
  return data!.getUint8(offset + 3);
}

Future<ui.Image> _renderGroundStaticShadows(
  ShadowRuntimeInstructionCollection collection, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder);
  const ShadowRuntimeRenderer().renderCollectionPass(
    canvas,
    collection,
    ShadowRenderPass.groundStatic,
  );
  return recorder.endRecording().toImage(width, height);
}
```

### Code complet — packages/map_editor/test/application/shadow/editor_projected_building_shadow_preview_test.dart

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
- [x] Aucun fichier map_runtime/lib modifié
- [x] Aucun fichier map_editor/lib modifié
- [x] Aucun modèle modifié
- [x] Aucun codec modifié
- [x] Aucun generated modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Preset id pokemon-building-shadow-v0 utilisé
- [x] Direction (0.8, 0.35) utilisée
- [x] lengthRatio 0.32 utilisé
- [x] nearWidthRatio 0.90 utilisé
- [x] farWidthRatio 0.72 utilisé
- [x] opacity 0.30 utilisée
- [x] colorHexRgb 606060 utilisé
- [x] anchor (0.5, 0.96) utilisé
- [x] localOffset (0,0) utilisé
- [x] Points calibrés vérifiés
- [x] Pixel intérieur runtime alpha > 0
- [x] Pixel extérieur runtime alpha == 0
- [x] Test map_core ciblé passé
- [x] Test runtime ciblé passé
- [x] Test editor ciblé passé
- [x] Régressions utiles passées
- [x] Analyze ciblé OK
- [x] Audit anti-dérive OK
- [x] Evidence Pack complet
- [x] git status final conforme
