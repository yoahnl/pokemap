# ShadowV2-30-bis — V2 Suppresses Same-Element Legacy Static Shadow V0 / Scope Fix

## 1. Résumé exécutif

ShadowV2-30-bis implémente la règle validée par ShadowV2-29 et débloquée par le scope fix du Lot 30 :

```text
V2 active + preset résoluble
=> aucune shadow V1 static placed same-element produite
=> runtime et editor preview alignés.
```

La règle ne supprime aucune donnée. Elle ne modifie pas `map_core`, ne touche pas au renderer, ne touche pas `PlayableMapGame`, ne touche pas `MapGridPainter` production, ne crée aucun screenshot, aucune baseline, aucun generated.

## 2. Objectif du lot

Objectif exact :

```text
Quand un ProjectElementEntry possède projectedBuildingShadow.enabled == true
ET que le preset ShadowV2 référencé est résoluble,
alors la shadow V1 static placed du même élément / placement ne doit plus être produite,
ni côté runtime,
ni côté editor preview.
```

## 3. Rappel ShadowV2-29 / ShadowV2-30

ShadowV2-29 a identifié que les vieilles ombres V1 venaient principalement de :

```text
ProjectElementEntry.shadow
MapPlacedElement.shadowOverride
runtime static placed V1
editor static shadow preview V1
```

ShadowV2-30 a correctement bloqué parce que `runtime_projected_building_shadow_visual_poc_test.dart` encodait encore l’ancien contrat `V2 + V1 same-element coexistent`.

ShadowV2-30-bis ajoute ce fichier au scope et applique l’objectif initial.

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie initiale :

```text
Aucune ligne.
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Résultats utiles :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Le design a déjà été validé par ShadowV2-29. Le lot est une implémentation bornée, exécutée en TDD.

## 6. Fichiers créés / modifiés / supprimés

Fichiers créés :

```text
reports/shadows/v2/shadow_v2_30_bis_v2_suppresses_same_element_legacy_static_shadow_scope_fix.md
```

Fichiers modifiés :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
```

Fichiers supprimés :

```text
Aucun.
```

Fichiers autorisés mais non modifiés :

```text
packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
packages/map_editor/test/map_grid_painter_test.dart
```

## 7. Audit initial runtime/editor V1

Runtime V1 :

```text
runtime_static_placed_element_shadow_sources.dart construit RuntimeStaticPlacedElementShadowSource
depuis element.shadow et placed.shadowOverride.
Le skip doit être placé après résolution de element et avant ajout de la source V1.
```

Editor V1 :

```text
editor_static_shadow_preview.dart résout element.shadow / placed.shadowOverride
via resolveShadowConfig(...).
Le skip doit être placé après résolution de element et avant resolveShadowConfig(...).
```

Chemins V2 :

```text
Le test host et le visual POC prouvaient encore l’ancien comportement same-element V1 + V2.
Le builder V2 runtime/editor n’a pas besoin d’être modifié.
```

## 8. Tests hors périmètre du Lot 30 maintenant corrigés

Le fichier maintenant autorisé et corrigé :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Ancien test :

```text
runtime projected building visual POC keeps V2 before V1 in merged collection
```

Nouveau test :

```text
runtime projected building visual POC suppresses same-element V1 when V2 is resolvable
```

Le test vérifie maintenant :

```text
groundStatic length == 1
instruction unique == V2 projectedPolygon
aucune instruction V1 colorHexRgb == 010203 / opacity == 0.35
```

## 9. Règle métier implémentée

La règle est identique runtime/editor :

```dart
config = element.projectedBuildingShadow
if config == null -> false
if !config.enabled -> false
if manifest.projectedBuildingShadowCatalog.presetById(config.presetId) == null -> false
return true
```

Quand le helper retourne `true`, la V1 same-element est ignorée.

## 10. Implémentation runtime

Fichier :

```text
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
```

Changement :

```text
Ajout de _hasResolvableProjectedBuildingShadow(...)
Skip de la source V1 avant construction de RuntimeStaticPlacedElementShadowSource.
```

Le helper ne résout pas la géométrie, ne construit pas V2, n’appelle aucun diagnostic, ne mute aucune donnée.

## 11. Implémentation editor preview

Fichier :

```text
packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
```

Changement :

```text
Ajout du même helper privé.
Skip de la preview V1 avant resolveShadowConfig(...).
```

`map_editor` continue à ne pas importer `map_runtime`.

## 12. Comportement shadowOverride

Testé runtime et editor :

```text
placed.shadowOverride mode custom
+ element.projectedBuildingShadow enabled
+ preset V2 présent
=> aucune V1 produite.
```

Le `shadowOverride` reste une donnée persistée intacte, mais il ne force plus une V1 same-element face à une V2 authorée résoluble.

## 13. Cas V2 disabled / preset manquant

Testé runtime et editor :

```text
V2 absent => V1 reste
V2 disabled => V1 reste
preset V2 manquant => V1 reste
```

Un preset V2 cassé ne masque donc pas une V1 existante.

## 14. Tests runtime ajoutés/modifiés

Ajoutés dans `runtime_static_placed_element_shadow_collection_test.dart` :

```text
skips legacy static shadow when same element has resolvable projected building shadow
keeps legacy static shadow when element has no projected shadow
keeps legacy static shadow when projected building shadow is disabled
keeps legacy static shadow when projected building shadow preset is missing
skips custom placed legacy shadow override when same element has resolvable projected building shadow
keeps legacy V1 static shadow for another element without V2
```

Modifiés dans `runtime_projected_building_shadow_host_integration_test.dart` :

```text
PlayableMapGame suppresses same-element V1 static shadow when projected building shadow is resolvable
PlayableMapGame keeps V1 static shadows for elements without V2
```

Modifié dans `runtime_projected_building_shadow_visual_poc_test.dart` :

```text
runtime projected building visual POC suppresses same-element V1 when V2 is resolvable
```

## 15. Tests editor ajoutés/modifiés

Ajoutés dans `editor_static_shadow_preview_test.dart` :

```text
skips legacy static shadow preview when same element has resolvable projected building shadow
keeps legacy static shadow preview when element has no projected building shadow
keeps legacy static shadow preview when projected building shadow is disabled
keeps legacy static shadow preview when projected building shadow preset is missing
skips custom placed legacy shadow preview override when same element has resolvable projected building shadow
```

`map_grid_painter_test.dart` n’a pas été modifié : la règle est dans le builder V1 preview que `MapGridPainter` consomme déjà, et les tests canvas existants restent verts.

## 16. Tests host / visual POC ajustés

Host runtime :

```text
same-element V1 + V2 valide => V2 seule
élément A V2 + élément B V1 seulement => V2 de A + V1 de B
```

Visual POC :

```text
Le test pixel V2 reste inchangé.
Le test de coexistence same-element devient un test de suppression.
```

## 17. TDD RED initial

Runtime RED :

```text
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

Sortie utile :

```text
00:00 +3 -1: buildRuntimeStaticPlacedElementShadowSources skips legacy static shadow when same element has resolvable projected building shadow [E]
  Expected: empty
    Actual: [Instance of 'RuntimeStaticPlacedElementShadowSource']

00:00 +6 -2: buildRuntimeStaticPlacedElementShadowSources skips custom placed legacy shadow override when same element has resolvable projected building shadow [E]
  Expected: empty
    Actual: [Instance of 'RuntimeStaticPlacedElementShadowSource']

00:00 +6 -3: buildRuntimeStaticPlacedElementShadowSources keeps legacy V1 static shadow for another element without V2 [E]
  Expected: ['legacy-tree']
    Actual: ['tree', 'legacy-tree']

00:00 +29 -3: Some tests failed.
```

Editor RED :

```text
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
```

Sortie utile :

```text
00:00 +9 -1: buildEditorStaticShadowPreviewInstructions skips legacy static shadow preview when same element has resolvable projected building shadow [E]
  Expected: empty
    Actual: [Instance of 'EditorStaticShadowPreviewInstruction']

00:00 +12 -2: buildEditorStaticShadowPreviewInstructions skips custom placed legacy shadow preview override when same element has resolvable projected building shadow [E]
  Expected: empty
    Actual: [Instance of 'EditorStaticShadowPreviewInstruction']

00:00 +22 -2: Some tests failed.
```

Visual POC RED :

```text
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
```

Sortie utile :

```text
00:00 +1 -1: runtime projected building shadow visual POC runtime projected building visual POC suppresses same-element V1 when V2 is resolvable [E]
  Expected: an object with length of <1>
    Actual: [
              Instance of 'ShadowRuntimeRenderInstruction',
              Instance of 'ShadowRuntimeRenderInstruction'
            ]
     Which: has length of <2>

00:00 +2 -1: Some tests failed.
```

## 18. Résultats des tests

Runtime ciblé source/collection :

```text
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_collection_test.dart
00:00 +32: All tests passed!
```

Runtime host V2 :

```text
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart
00:00 +9: All tests passed!
```

Runtime visual POC :

```text
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
00:00 +3: All tests passed!
```

Runtime host V1 :

```text
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
00:00 +11: All tests passed!
```

Editor preview V1 :

```text
cd packages/map_editor && flutter test test/application/shadow/editor_static_shadow_preview_test.dart
00:00 +24: All tests passed!
```

Editor canvas :

```text
cd packages/map_editor && flutter test test/map_grid_painter_test.dart
00:00 +14: All tests passed!
```

Régression runtime shadow complète :

```text
cd packages/map_runtime && flutter test test/shadow
00:03 +266: All tests passed!
```

Régressions editor utiles :

```text
cd packages/map_editor && flutter test test/application/shadow/editor_projected_building_shadow_preview_test.dart test/application/shadow/editor_shadow_render_order_contract_test.dart test/ui/canvas/editor_static_shadow_preview_painter_test.dart
00:00 +21: All tests passed!
```

## 19. Résultat analyze

Runtime analyze ciblé :

```text
cd packages/map_runtime && flutter analyze lib/src/shadow/runtime_static_placed_element_shadow_sources.dart test/shadow/runtime_static_placed_element_shadow_collection_test.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart test/shadow/runtime_projected_building_shadow_visual_poc_test.dart test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
Analyzing 5 items...

No issues found! (ran in 3.4s)
```

Editor analyze ciblé :

```text
cd packages/map_editor && flutter analyze lib/src/application/shadow/editor_static_shadow_preview.dart test/application/shadow/editor_static_shadow_preview_test.dart test/map_grid_painter_test.dart
Analyzing 3 items...

No issues found! (ran in 1.9s)
```

Note : un premier analyze runtime a signalé `prefer_const_constructors` dans le test host modifié. La correction a été limitée à `const MapLayer.tile(...)`, puis l’analyze a été relancé avec succès.

## 20. Audit anti-dérive

Commande :

```bash
rg -n "diagnoseProjectedBuildingShadows|applyElementAutoShadowPolicyToProject|matchesGoldenFile|SHADOW_SCREENSHOT|selbrume|reports/shadows/baselines" packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart packages/map_editor/test/map_grid_painter_test.dart
```

Sortie :

```text
Aucune ligne.
```

## 21. Ce qui n’a volontairement pas été modifié

```text
packages/map_core/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
packages/map_editor/lib/src/application/shadow/editor_projected_building_shadow_preview.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/shadow/editor_static_shadow_preview_painter.dart
packages/map_editor/lib/src/models/**
packages/map_editor/lib/src/data/**
packages/map_editor/test/fixtures/**
/Users/karim/Desktop/selbrume/**
```

## 22. Ce qui n’a volontairement pas été créé

```text
migration
outil de cleanup
nouveau modèle persistant
nouveau codec
nouveau generated file
screenshot
baseline
fixture Selbrume
nouveau renderer
nouveau painter
nouvelle UI
nouveau flag public
```

## 23. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie avant ajout du rapport :

```text
 .../shadow/editor_static_shadow_preview.dart       |  20 ++
 .../shadow/editor_static_shadow_preview_test.dart  | 115 +++++++++++
 ...ntime_static_placed_element_shadow_sources.dart |  20 ++
 ...cted_building_shadow_host_integration_test.dart |  52 +++--
 ..._projected_building_shadow_visual_poc_test.dart |  30 +--
 ...atic_placed_element_shadow_collection_test.dart | 228 +++++++++++++++++++++
 6 files changed, 438 insertions(+), 27 deletions(-)
```

## 24. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie avant ajout du rapport :

```text
M	packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
M	packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
M	packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
M	packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
M	packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
M	packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
```

## 25. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
Aucune ligne.
```

## 26. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie finale attendue après création du rapport :

```text
 M packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
 M packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
 M packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
 M packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
 M packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
?? reports/shadows/v2/shadow_v2_30_bis_v2_suppresses_same_element_legacy_static_shadow_scope_fix.md
```

## 27. Risques / réserves

```text
- La règle se base sur "V2 active + preset présent", pas sur une géométrie V2 rendable.
- C’est conforme au prompt 30-bis, mais cela signifie qu’un élément avec preset présent et source visuelle invalide masquerait V1. Dans les chemins actuels, une source invalide bloque déjà les shadows, donc le risque pratique est limité.
- Les données V1 restent présentes. C’est volontaire : ce lot neutralise le rendu/preview same-element, pas les données.
```

## 28. Auto-critique

```text
- Le lot respecte ShadowV2-29 : oui, il neutralise la V1 same-element runtime/editor sans migration.
- Le scope fix du Lot 30 est limité au test manquant : oui, seul visual_poc a été ajusté côté scope corrigé.
- La règle est identique runtime/editor : oui, même helper privé et même lookup de preset.
- V2 disabled garde V1 : testé runtime/editor.
- V2 preset manquant garde V1 : testé runtime/editor.
- shadowOverride custom est masqué par V2 valide : testé runtime/editor.
- Les éléments sans V2 gardent leurs V1 utiles : testé au niveau runtime source et host.
- Le visual POC est cohérent avec la nouvelle règle : oui, il attend V2 seule pour same-element V1 + V2.
- Aucune migration/destruction de données : oui.
- Aucun Selbrume/screenshot/baseline : oui.
- Les tests évitent les pixels fragiles pour la suppression : oui, suppression vérifiée par collections/builders.
- Le rapport contient les preuves demandées : oui.
```

## 29. Regard critique sur le prompt

Le scope fix est justifié : `runtime_projected_building_shadow_visual_poc_test.dart` devait être modifié pour que le contrat global `test/shadow` reflète la nouvelle règle. Le prompt reste strict et empêche d’élargir vers calibration, données réelles ou renderer.

Point de vigilance : si le prochain lot veut une règle plus fine du type "V2 géométriquement résolue masque V1", il faudra autoriser explicitement l’appel à une résolution pure ou documenter pourquoi le simple lookup de preset ne suffit plus.

## 30. Prochain lot recommandé

```text
ShadowV2-31 — Projected Building Shadow Visual Calibration Design Gate
```

Objectif recommandé :

```text
Définir une calibration artistique V2 simple :
direction cohérente,
gris neutre,
opacité lisible,
forme dure,
sans blur,
sans shader,
sans réintroduire d’automatique.
```

## 31. Code complet des fichiers créés/modifiés

### Diff complet — runtime_static_placed_element_shadow_sources.dart

```diff
diff --git a/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
index bc2da17f..d982d4e4 100644
--- a/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
+++ b/packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
@@ -33,6 +33,12 @@ List<RuntimeStaticPlacedElementShadowSource>
     if (element == null || element.frames.isEmpty) {
       continue;
     }
+    if (_hasResolvableProjectedBuildingShadow(
+      manifest: bundle.manifest,
+      element: element,
+    )) {
+      continue;
+    }
     final frame = element.frames.first;
     final source = frame.source;
     if (source.width <= 0 || source.height <= 0) {
@@ -62,6 +68,20 @@ List<RuntimeStaticPlacedElementShadowSource>
   return List<RuntimeStaticPlacedElementShadowSource>.unmodifiable(sources);
 }
 
+bool _hasResolvableProjectedBuildingShadow({
+  required ProjectManifest manifest,
+  required ProjectElementEntry element,
+}) {
+  final config = element.projectedBuildingShadow;
+  if (config == null || !config.enabled) {
+    return false;
+  }
+  return manifest.projectedBuildingShadowCatalog.presetById(
+        config.presetId,
+      ) !=
+      null;
+}
+
 ShadowRuntimeInstructionCollection
     buildRuntimeStaticPlacedElementShadowCollectionForBundle({
   required RuntimeMapBundle bundle,
```

### Diff complet — editor_static_shadow_preview.dart

```diff
diff --git a/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart b/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
index 1c182bff..ea3e0da3 100644
--- a/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
+++ b/packages/map_editor/lib/src/application/shadow/editor_static_shadow_preview.dart
@@ -146,6 +146,12 @@ List<EditorStaticShadowPreviewInstruction>
     if (element == null || element.frames.isEmpty) {
       continue;
     }
+    if (_hasResolvableProjectedBuildingShadow(
+      manifest: manifest,
+      element: element,
+    )) {
+      continue;
+    }
     final source = element.frames.first.source;
     if (source.width <= 0 || source.height <= 0) {
       continue;
@@ -223,6 +229,20 @@ List<EditorStaticShadowPreviewInstruction>
   return List<EditorStaticShadowPreviewInstruction>.unmodifiable(instructions);
 }
 
+bool _hasResolvableProjectedBuildingShadow({
+  required ProjectManifest manifest,
+  required ProjectElementEntry element,
+}) {
+  final config = element.projectedBuildingShadow;
+  if (config == null || !config.enabled) {
+    return false;
+  }
+  return manifest.projectedBuildingShadowCatalog.presetById(
+        config.presetId,
+      ) !=
+      null;
+}
+
 StaticShadowProjectionSpec _projectionSpecForEditorLightPreview(
   EditorShadowLightPreviewPreset preset,
 ) {
```

### Diff complet — runtime_static_placed_element_shadow_collection_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
index 38ed46eb..cd86c370 100644
--- a/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_static_placed_element_shadow_collection_test.dart
@@ -1,6 +1,8 @@
 import 'package:flutter_test/flutter_test.dart';
 import 'package:map_core/map_core.dart';
+import 'package:map_runtime/src/application/runtime_map_bundle.dart';
 import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_collection.dart';
+import 'package:map_runtime/src/shadow/runtime_static_placed_element_shadow_sources.dart';
 import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
 import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';
 import 'package:map_runtime/src/shadow/static_placed_element_shadow_runtime_resolver.dart';
@@ -40,6 +42,95 @@ void main() {
     });
   });
 
+  group('buildRuntimeStaticPlacedElementShadowSources', () {
+    test(
+        'skips legacy static shadow when same element has resolvable projected building shadow',
+        () {
+      final bundle = _bundle(projectedBuildingShadow: _projectedConfig());
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
+    test('keeps legacy static shadow when element has no projected shadow', () {
+      final sources = buildRuntimeStaticPlacedElementShadowSources(
+        bundle: _bundle(),
+      );
+
+      expect(sources, hasLength(1));
+      expect(sources.single.elementId, 'tree');
+    });
+
+    test(
+        'keeps legacy static shadow when projected building shadow is disabled',
+        () {
+      final sources = buildRuntimeStaticPlacedElementShadowSources(
+        bundle: _bundle(
+          projectedBuildingShadow: _projectedConfig(enabled: false),
+        ),
+      );
+
+      expect(sources, hasLength(1));
+      expect(sources.single.elementId, 'tree');
+    });
+
+    test(
+        'keeps legacy static shadow when projected building shadow preset is missing',
+        () {
+      final sources = buildRuntimeStaticPlacedElementShadowSources(
+        bundle: _bundle(
+          projectedBuildingShadow: _projectedConfig(),
+          includeProjectedPreset: false,
+        ),
+      );
+
+      expect(sources, hasLength(1));
+      expect(sources.single.elementId, 'tree');
+    });
+
+    test(
+        'skips custom placed legacy shadow override when same element has resolvable projected building shadow',
+        () {
+      final sources = buildRuntimeStaticPlacedElementShadowSources(
+        bundle: _bundle(
+          projectedBuildingShadow: _projectedConfig(),
+          placedOverride: MapPlacedElementShadowOverride(
+            mode: ShadowOverrideMode.custom,
+            shadowProfileId: 'plain_ellipse',
+            opacity: 0.2,
+          ),
+        ),
+      );
+
+      expect(sources, isEmpty);
+    });
+
+    test('keeps legacy V1 static shadow for another element without V2', () {
+      final sources = buildRuntimeStaticPlacedElementShadowSources(
+        bundle: _bundle(
+          projectedBuildingShadow: _projectedConfig(),
+          includeLegacyOnlyElement: true,
+        ),
+      );
+
+      expect(sources.map((source) => source.elementId), ['legacy-tree']);
+      final collection =
+          buildRuntimeStaticPlacedElementShadowCollectionForBundle(
+        bundle: _bundle(
+          projectedBuildingShadow: _projectedConfig(),
+          includeLegacyOnlyElement: true,
+        ),
+      );
+      expect(collection.groundStatic, hasLength(1));
+    });
+  });
+
   group('buildRuntimeStaticPlacedElementShadowCollection', () {
     test(
         'visible active element shadow with ellipse groundStatic creates one projected instruction',
@@ -570,6 +661,143 @@ StaticPlacedElementShadowRuntimeMetrics _metrics({
   );
 }
 
+RuntimeMapBundle _bundle({
+  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
+  bool includeProjectedPreset = true,
+  bool includeLegacyOnlyElement = false,
+  MapPlacedElementShadowOverride? placedOverride,
+}) {
+  return RuntimeMapBundle(
+    manifest: ProjectManifest(
+      name: 'Runtime Static Shadow Source Test',
+      maps: const <ProjectMapEntry>[],
+      tilesets: const <ProjectTilesetEntry>[],
+      settings: const ProjectSettings(
+        tileWidth: 16,
+        tileHeight: 16,
+        displayScale: 2,
+        defaultPlayerCharacterId: 'player',
+      ),
+      elements: [
+        ProjectElementEntry(
+          id: 'tree',
+          name: 'Tree',
+          tilesetId: 'props',
+          categoryId: 'nature',
+          frames: const [
+            TilesetVisualFrame(
+              source: TilesetSourceRect(x: 0, y: 0, width: 2, height: 3),
+            ),
+          ],
+          shadow: _elementShadow(),
+          projectedBuildingShadow: projectedBuildingShadow,
+        ),
+        if (includeLegacyOnlyElement)
+          ProjectElementEntry(
+            id: 'legacy-tree',
+            name: 'Legacy Tree',
+            tilesetId: 'props',
+            categoryId: 'nature',
+            frames: const [
+              TilesetVisualFrame(
+                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
+              ),
+            ],
+            shadow: _elementShadow(),
+          ),
+      ],
+      characters: const [
+        ProjectCharacterEntry(
+          id: 'player',
+          name: 'Player',
+          tilesetId: 'player',
+          frameWidth: 2,
+          frameHeight: 2,
+        ),
+      ],
+      surfaceCatalog: ProjectSurfaceCatalog(),
+      shadowCatalog: _catalog(),
+      projectedBuildingShadowCatalog: includeProjectedPreset
+          ? ProjectBuildingShadowPresetCatalog(presets: [_projectedPreset()])
+          : const ProjectBuildingShadowPresetCatalog.empty(),
+    ),
+    map: MapData(
+      id: 'static-shadow-source-test',
+      name: 'Static Shadow Source Test',
+      size: const GridSize(width: 4, height: 4),
+      layers: [
+        MapLayer.tile(
+          id: 'decor',
+          name: 'Decor',
+          tilesetId: 'props',
+          tiles: List<int>.filled(16, 0),
+        ),
+      ],
+      placedElements: [
+        MapPlacedElement(
+          id: 'tree-1',
+          layerId: 'decor',
+          elementId: 'tree',
+          pos: const GridPos(x: 1, y: 1),
+          shadowOverride: placedOverride,
+        ),
+        if (includeLegacyOnlyElement)
+          const MapPlacedElement(
+            id: 'legacy-tree-1',
+            layerId: 'decor',
+            elementId: 'legacy-tree',
+            pos: GridPos(x: 2, y: 1),
+          ),
+      ],
+      entities: const [
+        MapEntity(
+          id: 'spawn',
+          name: 'Spawn',
+          kind: MapEntityKind.spawn,
+          pos: GridPos(x: 0, y: 0),
+          blocksMovement: false,
+          spawn: MapEntitySpawnData(
+            role: EntitySpawnRole.playerStart,
+            facing: EntityFacing.south,
+          ),
+        ),
+      ],
+      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
+    ),
+    projectRootDirectory: '/tmp/runtime-static-shadow-source-test',
+    tilesetAbsolutePathsById: const <String, String>{},
+  );
+}
+
+ProjectElementProjectedBuildingShadowConfig _projectedConfig({
+  bool enabled = true,
+}) {
+  return ProjectElementProjectedBuildingShadowConfig(
+    enabled: enabled,
+    presetId: 'shadow-a',
+    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
+    localOffset: ProjectedShadowOffset(x: 0, y: 0),
+  );
+}
+
+ProjectBuildingShadowPreset _projectedPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'shadow-a',
+    name: 'Shadow A',
+    direction: ProjectedShadowDirection(x: 1, y: 0),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.5,
+      nearWidthRatio: 1,
+      farWidthRatio: 0.5,
+    ),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.18,
+      colorHexRgb: '123ABC',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
+
 ProjectShadowCatalog _catalog() {
   return ProjectShadowCatalog(
     profiles: [
```

### Diff complet — runtime_projected_building_shadow_host_integration_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
index 5ee3945e..0bc20aa8 100644
--- a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
@@ -76,7 +76,7 @@ void main() {
     });
 
     test(
-        'PlayableMapGame merges V2 projected shadows with V1 static placed shadows',
+        'PlayableMapGame suppresses same-element V1 static shadow when projected building shadow is resolvable',
         () async {
       final game = PlayableMapGame(
         bundle: _bundle(withV1Shadow: true),
@@ -90,16 +90,18 @@ void main() {
       game.update(0);
       final collection = _backgroundLayer(game).shadowCollectionProvider!()!;
 
-      expect(collection.groundStatic, hasLength(2));
+      expect(collection.groundStatic, hasLength(1));
       expect(_projectedBuildingInstructions(collection), hasLength(1));
-      expect(_legacyStaticInstructions(collection), hasLength(1));
+      expect(_legacyStaticInstructions(collection), isEmpty);
     });
 
-    test(
-        'PlayableMapGame merges projected building shadows before V1 static shadows',
+    test('PlayableMapGame keeps V1 static shadows for elements without V2',
         () async {
       final game = PlayableMapGame(
-        bundle: _bundle(withV1Shadow: true),
+        bundle: _bundle(
+          withV1Shadow: true,
+          includeLegacyOnlyElement: true,
+        ),
         projectFilePath: '/tmp/project.json',
         runtimeTilesetImageLoader: _emptyImageLoader,
         enableActorContactShadows: false,
@@ -205,6 +207,7 @@ RuntimeMapBundle _bundle({
   bool withProjectedConfig = true,
   bool includeProjectedPreset = true,
   bool withV1Shadow = false,
+  bool includeLegacyOnlyElement = false,
 }) {
   return RuntimeMapBundle(
     manifest: ProjectManifest(
@@ -237,6 +240,22 @@ RuntimeMapBundle _bundle({
           projectedBuildingShadow:
               withProjectedConfig ? _projectedConfig() : null,
         ),
+        if (includeLegacyOnlyElement)
+          ProjectElementEntry(
+            id: 'legacy-building',
+            name: 'Legacy Building',
+            tilesetId: 'props',
+            categoryId: 'building',
+            frames: const [
+              TilesetVisualFrame(
+                source: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
+              ),
+            ],
+            shadow: ProjectElementShadowConfig(
+              castsShadow: true,
+              shadowProfileId: 'legacy-shadow',
+            ),
+          ),
       ],
       characters: const [
         ProjectCharacterEntry(
@@ -248,19 +267,19 @@ RuntimeMapBundle _bundle({
         ),
       ],
       surfaceCatalog: ProjectSurfaceCatalog(),
-      shadowCatalog: withV1Shadow
+      shadowCatalog: withV1Shadow || includeLegacyOnlyElement
           ? _legacyShadowCatalog()
           : const ProjectShadowCatalog.empty(),
       projectedBuildingShadowCatalog: includeProjectedPreset
           ? ProjectBuildingShadowPresetCatalog(presets: [_preset()])
           : const ProjectBuildingShadowPresetCatalog.empty(),
     ),
-    map: const MapData(
+    map: MapData(
       id: 'projected-building-shadow-test',
       name: 'Projected Building Shadow Test',
-      size: GridSize(width: 4, height: 4),
+      size: const GridSize(width: 4, height: 4),
       layers: [
-        MapLayer.tile(
+        const MapLayer.tile(
           id: 'objects',
           name: 'Objects',
           tilesetId: 'props',
@@ -268,15 +287,22 @@ RuntimeMapBundle _bundle({
         ),
       ],
       placedElements: [
-        MapPlacedElement(
+        const MapPlacedElement(
           id: 'building-1',
           layerId: 'objects',
           elementId: 'building',
           pos: GridPos(x: 1, y: 2),
         ),
+        if (includeLegacyOnlyElement)
+          const MapPlacedElement(
+            id: 'legacy-building-1',
+            layerId: 'objects',
+            elementId: 'legacy-building',
+            pos: GridPos(x: 2, y: 2),
+          ),
       ],
       entities: [
-        MapEntity(
+        const MapEntity(
           id: 'spawn',
           name: 'Spawn',
           kind: MapEntityKind.spawn,
@@ -288,7 +314,7 @@ RuntimeMapBundle _bundle({
           ),
         ),
       ],
-      mapMetadata: MapMetadata(defaultSpawnId: 'spawn'),
+      mapMetadata: const MapMetadata(defaultSpawnId: 'spawn'),
     ),
     projectRootDirectory: '/tmp/runtime-projected-building-shadow-test',
     tilesetAbsolutePathsById: const <String, String>{},
```

### Diff complet — runtime_projected_building_shadow_visual_poc_test.dart

```diff
diff --git a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
index f7e6d9a7..643c390f 100644
--- a/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
+++ b/packages/map_runtime/test/shadow/runtime_projected_building_shadow_visual_poc_test.dart
@@ -38,21 +38,20 @@ void main() {
     });
 
     test(
-        'runtime projected building visual POC keeps V2 before V1 in merged collection',
+        'runtime projected building visual POC suppresses same-element V1 when V2 is resolvable',
         () async {
       final collection = await _hostShadowCollection(withV1Shadow: true);
       final groundStatic = collection!.groundStatic;
 
-      expect(groundStatic, hasLength(2));
-      _expectProjectedBuildingInstruction(groundStatic[0]);
-      _expectLegacyStaticInstruction(groundStatic[1]);
+      expect(groundStatic, hasLength(1));
+      _expectProjectedBuildingInstruction(groundStatic.single);
+      expect(_legacyStaticInstructions(collection), isEmpty);
     });
 
     test(
         'runtime projected building visual POC does not use screenshots '
         'base'
-        'lines or auto projection',
-        () {
+        'lines or auto projection', () {
       final source = File(
         'test/shadow/runtime_projected_building_shadow_visual_poc_test.dart',
       ).readAsStringSync();
@@ -258,6 +257,17 @@ List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
       .toList(growable: false);
 }
 
+List<ShadowRuntimeRenderInstruction> _legacyStaticInstructions(
+  ShadowRuntimeInstructionCollection collection,
+) {
+  return collection.groundStatic
+      .where(
+        (instruction) =>
+            instruction.colorHexRgb == '010203' && instruction.opacity == 0.35,
+      )
+      .toList(growable: false);
+}
+
 void _expectProjectedBuildingInstruction(
   ShadowRuntimeRenderInstruction instruction,
 ) {
@@ -272,14 +282,6 @@ void _expectProjectedBuildingInstruction(
   _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
 }
 
-void _expectLegacyStaticInstruction(
-  ShadowRuntimeRenderInstruction instruction,
-) {
-  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
-  expect(instruction.opacity, 0.35);
-  expect(instruction.colorHexRgb, '010203');
-}
-
 void _expectPointClose(
   ShadowRuntimePoint point, {
   required double x,
```

### Diff complet — editor_static_shadow_preview_test.dart

```diff
diff --git a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
index 068034a4..1622fa74 100644
--- a/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
+++ b/packages/map_editor/test/application/shadow/editor_static_shadow_preview_test.dart
@@ -260,6 +260,86 @@ void main() {
       );
     });
 
+    test(
+        'skips legacy static shadow preview when same element has resolvable projected building shadow',
+        () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          projectedBuildingShadow: _projectedConfig(),
+          includeProjectedPreset: true,
+        ),
+        map: _map(),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(instructions, isEmpty);
+    });
+
+    test(
+        'keeps legacy static shadow preview when element has no projected building shadow',
+        () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(),
+        map: _map(),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(instructions, hasLength(1));
+    });
+
+    test(
+        'keeps legacy static shadow preview when projected building shadow is disabled',
+        () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          projectedBuildingShadow: _projectedConfig(enabled: false),
+          includeProjectedPreset: true,
+        ),
+        map: _map(),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(instructions, hasLength(1));
+    });
+
+    test(
+        'keeps legacy static shadow preview when projected building shadow preset is missing',
+        () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(projectedBuildingShadow: _projectedConfig()),
+        map: _map(),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(instructions, hasLength(1));
+    });
+
+    test(
+        'skips custom placed legacy shadow preview override when same element has resolvable projected building shadow',
+        () {
+      final instructions = buildEditorStaticShadowPreviewInstructions(
+        manifest: _manifest(
+          projectedBuildingShadow: _projectedConfig(),
+          includeProjectedPreset: true,
+        ),
+        map: _map(
+          shadowOverride: MapPlacedElementShadowOverride(
+            mode: ShadowOverrideMode.custom,
+            shadowProfileId: 'base_shadow',
+            opacity: 0.2,
+          ),
+        ),
+        tileWidth: 16,
+        tileHeight: 16,
+      );
+
+      expect(instructions, isEmpty);
+    });
+
     test('uses element footprint for preview anchor and size', () {
       final instructions = buildEditorStaticShadowPreviewInstructions(
         manifest: _manifest(
@@ -851,6 +931,8 @@ ProjectManifest _manifest({
   ProjectShadowCatalog? catalog,
   ProjectShadowProfile? profile,
   ProjectElementShadowConfig? elementShadow,
+  ProjectElementProjectedBuildingShadowConfig? projectedBuildingShadow,
+  bool includeProjectedPreset = false,
   bool omitElementShadow = false,
   List<TilesetVisualFrame>? frames,
 }) {
@@ -863,6 +945,9 @@ ProjectManifest _manifest({
           profiles: [profile ?? _profile('base_shadow')],
         ),
     surfaceCatalog: ProjectSurfaceCatalog(),
+    projectedBuildingShadowCatalog: includeProjectedPreset
+        ? ProjectBuildingShadowPresetCatalog(presets: [_projectedPreset()])
+        : const ProjectBuildingShadowPresetCatalog.empty(),
     elements: [
       ProjectElementEntry(
         id: 'stand',
@@ -882,6 +967,7 @@ ProjectManifest _manifest({
                   castsShadow: true,
                   shadowProfileId: 'base_shadow',
                 ),
+        projectedBuildingShadow: projectedBuildingShadow,
       ),
     ],
   );
@@ -936,3 +1022,32 @@ ProjectShadowProfile _profile(
     colorHexRgb: colorHexRgb,
   );
 }
+
+ProjectElementProjectedBuildingShadowConfig _projectedConfig({
+  bool enabled = true,
+}) {
+  return ProjectElementProjectedBuildingShadowConfig(
+    enabled: enabled,
+    presetId: 'shadow-a',
+    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
+    localOffset: ProjectedShadowOffset(x: 0, y: 0),
+  );
+}
+
+ProjectBuildingShadowPreset _projectedPreset() {
+  return ProjectBuildingShadowPreset(
+    id: 'shadow-a',
+    name: 'Shadow A',
+    direction: ProjectedShadowDirection(x: 1, y: 0),
+    shape: ProjectedShadowShapeTuning(
+      lengthRatio: 0.5,
+      nearWidthRatio: 1,
+      farWidthRatio: 0.5,
+    ),
+    appearance: ProjectedShadowAppearance(
+      opacity: 0.18,
+      colorHexRgb: '123ABC',
+    ),
+    timeOfDayMode: ProjectedShadowTimeOfDayMode.fixed,
+  );
+}
```

### Rapport créé

Le présent fichier est :

```text
reports/shadows/v2/shadow_v2_30_bis_v2_suppresses_same_element_legacy_static_shadow_scope_fix.md
```

Checklist finale :
- [x] V2 valide masque V1 same-element runtime
- [x] V2 valide masque V1 same-element editor preview
- [x] V2 disabled ne masque pas V1
- [x] V2 preset manquant ne masque pas V1
- [x] V1 non-V2 reste fonctionnelle
- [x] shadowOverride custom ne force pas V1 si V2 valide existe
- [x] runtime_projected_building_shadow_visual_poc_test corrigé
- [x] Aucune donnée supprimée
- [x] Aucun fichier map_core modifié
- [x] Aucun renderer runtime modifié
- [x] PlayableMapGame non modifié
- [x] MapLayersComponent non modifié
- [x] MapGridPainter production non modifié
- [x] Builder V2 runtime non modifié
- [x] Builder V2 editor non modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot créé
- [x] Aucune baseline créée
- [x] Tests runtime ciblés passés
- [x] Tests editor ciblés passés
- [x] Régressions utiles passées
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
