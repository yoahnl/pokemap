# ShadowV2-24 — Projected Building Shadow Runtime Render Integration V0

## 1. Résumé exécutif

ShadowV2-24 branche la collection runtime ShadowV2 dans le provider interne de `PlayableMapGame`, sans créer de nouveau chemin de rendu.

Le raccord appliqué est exactement celui validé en ShadowV2-23 :

```text
buildRuntimeProjectedBuildingShadowCollection(...)
-> stockage privé par map dans PlayableMapGame
-> merge avec collections internes existantes
-> provider interne du background MapLayersComponent
-> ShadowRuntimeRenderer existant
```

Le renderer n'a pas été modifié. `MapLayersComponent` n'a pas été modifié. `map_core` n'a pas été modifié. Aucun screenshot, baseline, fixture Selbrume ou generated file n'a été créé.

## 2. Objectif du lot

Objectif exact :

```text
Brancher la collection runtime ShadowV2 déjà construite
dans le provider interne de PlayableMapGame,
afin que MapLayersComponent la rende via le pipeline shadow existant,
sans modifier le renderer,
sans modifier MapLayersComponent,
sans modifier map_core.
```

## 3. Rappel ShadowV2-22 / ShadowV2-23

ShadowV2-22 a créé :

```dart
ShadowRuntimeInstructionCollection
    buildRuntimeProjectedBuildingShadowCollection({
  required ProjectManifest manifest,
  required MapData mapData,
})
```

ShadowV2-23 a validé :

```text
- ShadowRuntimeRenderer sait déjà rendre projectedPolygon ;
- MapLayersComponent sait déjà rendre une ShadowRuntimeInstructionCollection ;
- PlayableMapGame est le point d'intégration ;
- V2 doit être mergée avant V1 static placed shadows ;
- external shadowCollectionProvider reste prioritaire ;
- enableStaticPlacedElementShadows=false désactive aussi V2 en V0.
```

## 4. État initial du worktree

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
```

Fichiers préexistants non liés au lot :

```text
Aucun.
```

Le rapport du Lot 23 n'apparaissait pas comme untracked dans cette session.

## 5. Décision AGENTS / design gate déjà satisfait

Commandes :

```bash
find .. -name AGENTS.md -print
```

Sortie :

```text
../pokemonProject/AGENTS.md
../free-claude-code/AGENTS.md
```

Commande :

```bash
rg -n "Do not invoke implementation skills|design has been presented|creative|structural|architectural|product-facing" AGENTS.md
```

Sortie :

```text
765:Before structural changes, read the nearest:
848:1. Brainstorming (`superpowers:brainstorming`) before creative work.
1094:Do not invoke implementation skills, write code, scaffold a project, or take implementation action until a design has been presented and approved when the task is creative, structural, architectural, or product-facing.
1096:For creative work such as features, components, behavior changes, or UI:
```

Interprétation : le design gate est déjà satisfait par ShadowV2-23, explicitement validé par l'utilisateur. ShadowV2-24 applique ce design sans élargir le périmètre.

## 6. Fichiers créés / modifiés / supprimés

Créés :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
reports/shadows/v2/shadow_v2_24_projected_building_shadow_runtime_render_integration.md
```

Modifiés :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

Supprimés :

```text
Aucun.
```

Generated :

```text
Aucun.
```

Screenshots / baselines / Selbrume :

```text
Aucun.
```

## 7. Audit initial du pipeline PlayableMapGame

Commande :

```bash
rg -n "buildRuntimeProjectedBuildingShadowCollection|mergeShadowRuntimeInstructionCollections|_provideShadowCollectionForMap|_refreshStaticPlacedElementShadowCollection|enableStaticPlacedElementShadows|ShadowRuntimeInstructionCollectionProvider|shadowCollectionProvider" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow
```

Sortie utile :

```text
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:130:    this.shadowCollectionProvider,
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:132:    this.enableStaticPlacedElementShadows = true,
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:164:  final ShadowRuntimeInstructionCollectionProvider? shadowCollectionProvider;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:166:  final bool enableStaticPlacedElementShadows;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:572:  ShadowRuntimeInstructionCollectionProvider?
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:576:          _shadowCollectionProviderForMap(mapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1660:  ShadowRuntimeInstructionCollectionProvider? _shadowCollectionProviderForMap(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1663:    final externalProvider = shadowCollectionProvider;
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1667:    if (!enableActorContactShadows && !enableStaticPlacedElementShadows) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1670:    return () => _provideShadowCollectionForMap(mapId);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1673:  ShadowRuntimeInstructionCollection? _provideShadowCollectionForMap(
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1677:    if (enableStaticPlacedElementShadows) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1692:    return mergeShadowRuntimeInstructionCollections(collections);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1709:  void _refreshStaticPlacedElementShadowCollection(RuntimeMapBundle bundle) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1710:    if (shadowCollectionProvider != null || !enableStaticPlacedElementShadows) {
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:5089:        _refreshStaticPlacedElementShadowCollection(_bundle);
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6547:      shadowCollectionProvider: _shadowCollectionProviderForMap(bundle.map.id),
packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6645:    _refreshStaticPlacedElementShadowCollection(bundle);
```

Constats :

```text
- PlayableMapGame avait déjà un provider interne par map.
- _provideShadowCollectionForMap(...) fusionnait déjà static V1 et actorContact.
- _refreshStaticPlacedElementShadowCollection(...) construisait déjà V1 par RuntimeMapBundle.
- l'external shadowCollectionProvider était déjà prioritaire.
- enableStaticPlacedElementShadows pilotait déjà les shadows ground static internes.
```

## 8. Implémentation réalisée

Dans `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart` :

```text
- import du builder V2 runtime ;
- ajout d'un stockage privé _projectedBuildingShadowCollectionByMapId ;
- ajout de _refreshProjectedBuildingShadowCollection(RuntimeMapBundle bundle) ;
- refresh V2 au montage de chaque map ;
- refresh V2 lors du chemin existant qui rafraîchit V1 après mise à jour de bundle active ;
- cleanup V2 au démontage d'une map ;
- insertion de la collection V2 dans _provideShadowCollectionForMap(...) avant V1.
```

## 9. Refresh V2 par map

La méthode ajoutée :

```text
_refreshProjectedBuildingShadowCollection(RuntimeMapBundle bundle)
```

comportement :

```text
- si shadowCollectionProvider externe existe : remove + return ;
- si enableStaticPlacedElementShadows == false : remove + return ;
- sinon construit buildRuntimeProjectedBuildingShadowCollection(manifest, mapData) ;
- si collection vide : remove ;
- sinon stocke par bundle.map.id.
```

Ce comportement garde le runtime tolérant :

```text
- pas de throw si catalogue vide ;
- pas de throw si preset manquant ;
- pas de diagnostic appelé ;
- pas de fallback ;
- pas de genericProjection V2.
```

## 10. Merge V2 + V1 + actorContact

L'ordre de merge final est :

```text
1. V2 projected building shadow collection
2. V1 static placed element shadow collection
3. actorContact collection existante
```

Ainsi :

```text
- V2 atteint collection.groundStatic ;
- V2 est avant V1 dans collection.groundStatic ;
- V1 reste inchangée ;
- actorContact reste inchangé ;
- MapLayersComponent reçoit toujours une collection unique.
```

## 11. External shadowCollectionProvider priority

Le comportement existant reste prioritaire :

```text
if (externalProvider != null) return externalProvider;
```

Le refresh V2 retire aussi toute collection interne V2 si un provider externe est présent. Le test host vérifie que le background layer utilise bien le provider externe et que la collection V2 interne n'est pas observable dans le provider final.

## 12. enableStaticPlacedElementShadows behavior

Décision V0 appliquée :

```text
enableStaticPlacedElementShadows=false désactive les shadows ground static authorées V1 et V2.
```

Le nom est historiquement V1, mais le comportement est volontaire pour ce lot afin d'éviter un nouveau flag public.

## 13. Tests ajoutés

Nouveau fichier :

```text
packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Tests couverts :

```text
- V2 atteint le provider du background MapLayersComponent ;
- absence de config V2 -> pas d'instruction V2 ;
- preset V2 manquant -> skip silencieux ;
- V1 + V2 coexistent ;
- V2 est mergée avant V1 ;
- external shadowCollectionProvider reste prioritaire ;
- enableStaticPlacedElementShadows=false désactive V2 ;
- RuntimeMapGame reste passif ;
- audit source anti diagnostics / auto projection.
```

## 14. TDD RED initial

Commande RED :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Sortie RED initiale :

```text
00:00 +0: loading /Users/karim/Project/pokemonProject/packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
00:00 +0: runtime projected building shadow host integration PlayableMapGame provides projected building shadows to the background layer
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +0 -1: runtime projected building shadow host integration PlayableMapGame provides projected building shadows to the background layer [E]
  Null check operator used on a null value
  test/shadow/runtime_projected_building_shadow_host_integration_test.dart 33:64  main.<fn>.<fn>
  
00:00 +0 -1: runtime projected building shadow host integration PlayableMapGame does not create projected building shadows without projected config
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +1 -1: runtime projected building shadow host integration PlayableMapGame skips projected building shadow when preset is missing
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +2 -1: runtime projected building shadow host integration PlayableMapGame merges V2 projected shadows with V1 static placed shadows
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +2 -2: runtime projected building shadow host integration PlayableMapGame merges V2 projected shadows with V1 static placed shadows [E]
  Expected: an object with length of <2>
    Actual: [Instance of 'ShadowRuntimeRenderInstruction']
     Which: has length of <1>
  
  package:matcher                                                                expect
  package:flutter_test/src/widget_tester.dart 473:18                             expect
  test/shadow/runtime_projected_building_shadow_host_integration_test.dart 91:7  main.<fn>.<fn>
  
00:00 +2 -2: runtime projected building shadow host integration PlayableMapGame merges projected building shadows before V1 static shadows
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +2 -3: runtime projected building shadow host integration PlayableMapGame merges projected building shadows before V1 static shadows [E]
  Expected: an object with length of <2>
    Actual: [Instance of 'ShadowRuntimeRenderInstruction']
     Which: has length of <1>
  
  package:matcher                                                                 expect
  package:flutter_test/src/widget_tester.dart 473:18                              expect
  test/shadow/runtime_projected_building_shadow_host_integration_test.dart 111:7  main.<fn>.<fn>
  
00:00 +2 -3: runtime projected building shadow host integration PlayableMapGame keeps external shadow provider priority over internal projected shadows
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +3 -3: runtime projected building shadow host integration PlayableMapGame disables projected building ground shadows when static placed shadows are disabled
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +4 -3: runtime projected building shadow host integration RuntimeMapGame remains passive for projected building shadows
00:00 +5 -3: runtime projected building shadow host integration projected building render integration does not call diagnostics or auto projection
00:00 +6 -3: Some tests failed.
```

Le RED échoue pour la bonne raison : le provider interne ne contient pas encore V2, et le merge ne contient encore que V1 dans les cas de coexistence.

## 15. Résultats des tests

Test ciblé final :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Sortie complète :

```text
00:00 +0: runtime projected building shadow host integration PlayableMapGame provides projected building shadows to the background layer
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +1: runtime projected building shadow host integration PlayableMapGame does not create projected building shadows without projected config
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +2: runtime projected building shadow host integration PlayableMapGame skips projected building shadow when preset is missing
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +3: runtime projected building shadow host integration PlayableMapGame merges V2 projected shadows with V1 static placed shadows
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +4: runtime projected building shadow host integration PlayableMapGame merges projected building shadows before V1 static shadows
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +5: runtime projected building shadow host integration PlayableMapGame keeps external shadow provider priority over internal projected shadows
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +6: runtime projected building shadow host integration PlayableMapGame disables projected building ground shadows when static placed shadows are disabled
[runtime] Map loaded: projected-building-shadow-test, spawn at (0, 0)
00:00 +7: runtime projected building shadow host integration RuntimeMapGame remains passive for projected building shadows
00:00 +8: runtime projected building shadow host integration projected building render integration does not call diagnostics or auto projection
00:00 +9: All tests passed!
```

Régression V1 host :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_static_placed_element_shadow_host_integration_test.dart
```

Ligne finale exacte :

```text
00:00 +11: All tests passed!
```

Régression runtime shadow :

```bash
cd packages/map_runtime && flutter test test/shadow
```

Ligne finale exacte :

```text
00:02 +257: All tests passed!
```

Régression ShadowV2 core :

```bash
cd packages/map_core && dart test test/shadow_v2
```

Ligne finale exacte :

```text
00:00 +150: All tests passed!
```

## 16. Résultat analyze

Commande :

```bash
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/playable_map_game.dart test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Sortie complète :

```text
Analyzing 2 items...

No issues found! (ran in 1.4s)
```

## 17. Audit anti-dérive

Commande :

```bash
rg -n "genericProjection|applyElementAutoShadowPolicyToProject|diagnoseProjectedBuildingShadows|ProjectValidator|MapValidator|resolveProjectedStaticShadowGeometry|resolveStaticShadowFamilyProjectionSpec|static_shadow_family_projection|element_auto_shadow_policy" packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
```

Sortie :

```text
```

Interprétation : aucune ligne détectée.

Le test anti-dérive utilise des chaînes concaténées pour éviter que le test ne se détecte lui-même dans la commande `rg`, tout en vérifiant le contenu réel de `playable_map_game.dart`.

## 18. Ce qui n’a volontairement pas été modifié

```text
packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_renderer.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_render_instruction.dart
packages/map_runtime/lib/src/shadow/shadow_runtime_instruction_collection.dart
packages/map_runtime/lib/src/shadow/runtime_shadow_collection_merge.dart
packages/map_runtime/lib/src/shadow/runtime_projected_building_shadow_collection.dart
packages/map_runtime/lib/src/shadow/projected_building_shadow_runtime_adapter.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_collection.dart
packages/map_runtime/lib/src/shadow/runtime_static_placed_element_shadow_sources.dart
packages/map_runtime/lib/src/shadow/static_placed_element_shadow_runtime_resolver.dart
packages/map_core/**
packages/map_editor/**
packages/map_gameplay/**
packages/map_battle/**
examples/**
packages/map_runtime/tool/**
/Users/karim/Desktop/selbrume/project.json
/Users/karim/Desktop/selbrume/maps/Selbrume.json
```

Non créés :

```text
screenshot
baseline
fixture Selbrume
nouveau renderer
nouveau provider public
nouveau modèle
nouveau codec
nouveau diagnostic
nouveau generated file
```

## 19. git diff --stat

Commande :

```bash
git diff --stat
```

Sortie :

```text
 .../src/presentation/flame/playable_map_game.dart  | 29 ++++++++++++++++++++++
 1 file changed, 29 insertions(+)
```

Note : les fichiers nouveaux non suivis sont listés dans `git status final`.

## 20. git diff --name-status

Commande :

```bash
git diff --name-status
```

Sortie :

```text
M	packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
```

## 21. git diff --check

Commande :

```bash
git diff --check
```

Sortie :

```text
```

## 22. git status final

Commande :

```bash
git status --short --untracked-files=all
```

Sortie :

```text
 M packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
?? packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart
?? reports/shadows/v2/shadow_v2_24_projected_building_shadow_runtime_render_integration.md
```

## 23. Risques / réserves

Risque : `enableStaticPlacedElementShadows` contrôle V2 en V0 alors que son nom est historiquement V1. C'est volontaire pour éviter un nouveau flag public, mais un lot futur pourrait renommer ou séparer ce contrôle si le produit le demande.

Risque : V1 + V2 coexistent et peuvent assombrir visuellement certains bâtiments. Le runtime ne corrige pas ce cas automatiquement ; le diagnostic authoring `v1AndV2Coexistence` reste le garde-fou prévu.

Risque : le test host vérifie que l'instruction atteint le provider final, pas une capture visuelle. C'est conforme au lot 24. Le visual gate doit venir dans un lot dédié.

## 24. Auto-critique

Review séparée :

```text
- Le code respecte-t-il exactement ShadowV2-23 ?
  Oui : raccord dans PlayableMapGame, merge via helper existant, pas de nouveau rendu.

- Le lot a-t-il touché un fichier interdit ?
  Non : seul PlayableMapGame est modifié côté production.

- Le test prouve-t-il vraiment que V2 atteint le provider final ?
  Oui : il interroge le shadowCollectionProvider du background MapLayersComponent monté par PlayableMapGame.

- Le test distingue-t-il correctement V1 et V2 ?
  Oui : V2 est identifiée par projectedPolygon + colorHexRgb 123ABC + opacity 0.18 + points attendus ; V1 par colorHexRgb 010203 + opacity 0.35.

- Le test external provider prouve-t-il bien la priorité ?
  Oui : le background provider est same(provider) et la collection finale ne contient pas l'instruction V2.

- Le test anti-dérive ne masque-t-il pas une vraie dérive ?
  Oui : il lit playable_map_game.dart et cherche les termes reconstitués ; la commande rg externe confirme aussi aucune ligne.

- Le rapport contient-il toutes les preuves ?
  Oui : status initial/final, RED, test ciblé complet, lignes finales des régressions, analyze, audit anti-dérive, diff complet et code du test.
```

## 25. Regard critique sur le prompt

Le prompt a bien verrouillé le risque principal : il empêche de traiter "render integration" comme une invitation à modifier `ShadowRuntimeRenderer` ou `MapLayersComponent`.

Le point le plus délicat est le flag `enableStaticPlacedElementShadows`. Le prompt tranche clairement que ce flag pilote V1 et V2 en V0, ce qui évite d'ajouter une option publique.

Le test anti-dérive demandé est utile, mais il impose de contourner l'auto-détection du test lui-même avec des chaînes concaténées. C'est acceptable ici parce que le rapport documente cette raison et qu'une commande `rg` indépendante est aussi exécutée.

## 26. Prochain lot recommandé

```text
ShadowV2-25 — Projected Building Shadow Runtime Visual Gate Design
```

Objectif recommandé :

```text
concevoir une micro fixture visuelle ciblée pour confirmer le rendu V2
sans modifier Selbrume massif ni introduire une baseline large prématurée.
```

## 27. Code complet des fichiers créés/modifiés

### Diff complet de `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`

```diff
diff --git a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
index a2892479..101d2527 100644
--- a/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
+++ b/packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart
@@ -60,6 +60,7 @@ import '../../application/trainer_battle_request.dart';
 import '../../infrastructure/runtime_tileset_image.dart';
 import '../../infrastructure/tile_image_loader.dart';
 import '../../shadow/runtime_actor_contact_shadow_collection.dart';
+import '../../shadow/runtime_projected_building_shadow_collection.dart';
 import '../../shadow/runtime_shadow_collection_merge.dart';
 import '../../shadow/runtime_static_placed_element_shadow_sources.dart';
 import '../../shadow/shadow_runtime_collection_provider.dart';
@@ -187,6 +188,9 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   final List<OverworldActorComponent> _npcActors = [];
   final ShadowRuntimeCollectionController _actorShadowCollectionController =
       ShadowRuntimeCollectionController();
+  final Map<String, ShadowRuntimeInstructionCollection>
+      _projectedBuildingShadowCollectionByMapId =
+      <String, ShadowRuntimeInstructionCollection>{};
   final Map<String, ShadowRuntimeInstructionCollection>
       _staticShadowCollectionByMapId =
       <String, ShadowRuntimeInstructionCollection>{};
@@ -1675,6 +1679,12 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
   ) {
     final collections = <ShadowRuntimeInstructionCollection>[];
     if (enableStaticPlacedElementShadows) {
+      final projectedBuildingCollection =
+          _projectedBuildingShadowCollectionByMapId[mapId];
+      if (projectedBuildingCollection != null &&
+          projectedBuildingCollection.isNotEmpty) {
+        collections.add(projectedBuildingCollection);
+      }
       final staticCollection = _staticShadowCollectionByMapId[mapId];
       if (staticCollection != null && staticCollection.isNotEmpty) {
         collections.add(staticCollection);
@@ -1706,6 +1716,22 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
     );
   }
 
+  void _refreshProjectedBuildingShadowCollection(RuntimeMapBundle bundle) {
+    if (shadowCollectionProvider != null || !enableStaticPlacedElementShadows) {
+      _projectedBuildingShadowCollectionByMapId.remove(bundle.map.id);
+      return;
+    }
+    final collection = buildRuntimeProjectedBuildingShadowCollection(
+      manifest: bundle.manifest,
+      mapData: bundle.map,
+    );
+    if (collection.isEmpty) {
+      _projectedBuildingShadowCollectionByMapId.remove(bundle.map.id);
+      return;
+    }
+    _projectedBuildingShadowCollectionByMapId[bundle.map.id] = collection;
+  }
+
   void _refreshStaticPlacedElementShadowCollection(RuntimeMapBundle bundle) {
     if (shadowCollectionProvider != null || !enableStaticPlacedElementShadows) {
       _staticShadowCollectionByMapId.remove(bundle.map.id);
@@ -5086,6 +5112,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
           npcActors: activeLoaded.npcActors,
           npcActorByEntityId: activeLoaded.npcActorByEntityId,
         );
+        _refreshProjectedBuildingShadowCollection(_bundle);
         _refreshStaticPlacedElementShadowCollection(_bundle);
       }
       debugPrint(
@@ -6529,6 +6556,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       actor.removeFromParent();
       _npcActors.remove(actor);
     }
+    _projectedBuildingShadowCollectionByMapId.remove(mapId);
     _staticShadowCollectionByMapId.remove(mapId);
   }
 
@@ -6642,6 +6670,7 @@ class PlayableMapGame extends FlameGame with KeyboardEvents {
       npcActorByEntityId: npcActorByEntityId,
     );
     _loadedMapsById[bundle.map.id] = loaded;
+    _refreshProjectedBuildingShadowCollection(bundle);
     _refreshStaticPlacedElementShadowCollection(bundle);
     _applyNpcVisibilityToLoadedMap(loaded);
     return loaded;
```

### Code complet de `packages/map_runtime/test/shadow/runtime_projected_building_shadow_host_integration_test.dart`

```dart
import 'dart:io';

import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_map_bundle.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/map_layers_component.dart';
import 'package:map_runtime/src/presentation/flame/playable_map_game.dart';
import 'package:map_runtime/src/presentation/flame/runtime_map_game.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_instruction_collection.dart';
import 'package:map_runtime/src/shadow/shadow_runtime_render_instruction.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('runtime projected building shadow host integration', () {
    test(
        'PlayableMapGame provides projected building shadows to the background layer',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);
      final collection = background.shadowCollectionProvider!()!;

      expect(background.shadowCollectionProvider, isNotNull);
      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.groundStatic, hasLength(1));
      expect(collection.actorContact, isEmpty);

      final instruction = collection.groundStatic.single;
      _expectProjectedBuildingInstruction(instruction);
    });

    test(
        'PlayableMapGame does not create projected building shadows without projected config',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(withProjectedConfig: false),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);

      expect(_backgroundLayer(game).shadowCollectionProvider!(), isNull);
    });

    test(
        'PlayableMapGame skips projected building shadow when preset is missing',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(includeProjectedPreset: false),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);

      expect(_backgroundLayer(game).shadowCollectionProvider!(), isNull);
    });

    test(
        'PlayableMapGame merges V2 projected shadows with V1 static placed shadows',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(withV1Shadow: true),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final collection = _backgroundLayer(game).shadowCollectionProvider!()!;

      expect(collection.groundStatic, hasLength(2));
      expect(_projectedBuildingInstructions(collection), hasLength(1));
      expect(_legacyStaticInstructions(collection), hasLength(1));
    });

    test(
        'PlayableMapGame merges projected building shadows before V1 static shadows',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(withV1Shadow: true),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final groundStatic =
          _backgroundLayer(game).shadowCollectionProvider!()!.groundStatic;

      expect(groundStatic, hasLength(2));
      _expectProjectedBuildingInstruction(groundStatic[0]);
      _expectLegacyStaticInstruction(groundStatic[1]);
    });

    test(
        'PlayableMapGame keeps external shadow provider priority over internal projected shadows',
        () async {
      ShadowRuntimeInstructionCollection? provider() {
        return ShadowRuntimeInstructionCollection(
          instructions: [
            _externalShadow(),
          ],
        );
      }

      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        shadowCollectionProvider: provider,
        enableActorContactShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);
      final background = _backgroundLayer(game);
      final foreground = _foregroundLayer(game);
      final collection = background.shadowCollectionProvider!()!;

      expect(background.shadowCollectionProvider, same(provider));
      expect(foreground.shadowCollectionProvider, isNull);
      expect(collection.instructions, [_externalShadow()]);
      expect(_projectedBuildingInstructions(collection), isEmpty);
    });

    test(
        'PlayableMapGame disables projected building ground shadows when static placed shadows are disabled',
        () async {
      final game = PlayableMapGame(
        bundle: _bundle(),
        projectFilePath: '/tmp/project.json',
        runtimeTilesetImageLoader: _emptyImageLoader,
        enableActorContactShadows: false,
        enableStaticPlacedElementShadows: false,
      );

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      game.update(0);

      expect(_backgroundLayer(game).shadowCollectionProvider, isNull);
    });

    test('RuntimeMapGame remains passive for projected building shadows',
        () async {
      final game = RuntimeMapGame(bundle: _bundle());

      game.onGameResize(Vector2(160, 160));
      await game.onLoad();
      final layer = game.world.children.whereType<MapLayersComponent>().single;

      expect(game.shadowCollectionProvider, isNull);
      expect(layer.shadowCollectionProvider, isNull);
    });

    test(
        'projected building render integration does not call diagnostics or auto projection',
        () {
      final source = File(
        'lib/src/presentation/flame/playable_map_game.dart',
      ).readAsStringSync();
      final forbiddenSnippets = [
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

RuntimeMapBundle _bundle({
  bool withProjectedConfig = true,
  bool includeProjectedPreset = true,
  bool withV1Shadow = false,
}) {
  return RuntimeMapBundle(
    manifest: ProjectManifest(
      name: 'Runtime Projected Building Shadow Test',
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
          projectedBuildingShadow:
              withProjectedConfig ? _projectedConfig() : null,
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
      projectedBuildingShadowCatalog: includeProjectedPreset
          ? ProjectBuildingShadowPresetCatalog(presets: [_preset()])
          : const ProjectBuildingShadowPresetCatalog.empty(),
    ),
    map: const MapData(
      id: 'projected-building-shadow-test',
      name: 'Projected Building Shadow Test',
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
    projectRootDirectory: '/tmp/runtime-projected-building-shadow-test',
    tilesetAbsolutePathsById: const <String, String>{},
  );
}

ProjectElementProjectedBuildingShadowConfig _projectedConfig() {
  return ProjectElementProjectedBuildingShadowConfig(
    enabled: true,
    presetId: 'shadow-a',
    anchor: ProjectedShadowAnchor(xRatio: 0.5, yRatio: 1),
    localOffset: ProjectedShadowOffset(x: 0, y: 0),
  );
}

ProjectBuildingShadowPreset _preset() {
  return ProjectBuildingShadowPreset(
    id: 'shadow-a',
    name: 'Shadow A',
    direction: ProjectedShadowDirection(x: 1, y: 0),
    shape: ProjectedShadowShapeTuning(
      lengthRatio: 0.5,
      nearWidthRatio: 1,
      farWidthRatio: 0.5,
    ),
    appearance: ProjectedShadowAppearance(
      opacity: 0.18,
      colorHexRgb: '123ABC',
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

MapLayersComponent _foregroundLayer(PlayableMapGame game) {
  return game.world.children.whereType<MapLayersComponent>().singleWhere(
        (layer) => layer.renderPass == MapLayerRenderPass.foreground,
      );
}

List<ShadowRuntimeRenderInstruction> _projectedBuildingInstructions(
  ShadowRuntimeInstructionCollection collection,
) {
  return collection.groundStatic
      .where(
        (instruction) =>
            instruction.shape == ShadowRuntimeShapeKind.projectedPolygon &&
            instruction.colorHexRgb == '123ABC' &&
            instruction.opacity == 0.18,
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
  expect(instruction.opacity, 0.18);
  expect(instruction.colorHexRgb, '123ABC');
  expect(instruction.polygonPoints, hasLength(4));
  _expectPointClose(instruction.polygonPoints[0], x: 64, y: 128);
  _expectPointClose(instruction.polygonPoints[1], x: 64, y: 192);
  _expectPointClose(instruction.polygonPoints[2], x: 112, y: 176);
  _expectPointClose(instruction.polygonPoints[3], x: 112, y: 144);
}

void _expectLegacyStaticInstruction(
  ShadowRuntimeRenderInstruction instruction,
) {
  expect(instruction.renderPass, ShadowRenderPass.groundStatic);
  expect(instruction.opacity, 0.35);
  expect(instruction.colorHexRgb, '010203');
}

void _expectPointClose(
  ShadowRuntimePoint point, {
  required double x,
  required double y,
}) {
  expect(point.worldX, closeTo(x, 0.000001));
  expect(point.worldY, closeTo(y, 0.000001));
}

ShadowRuntimeRenderInstruction _externalShadow() {
  return ShadowRuntimeRenderInstruction(
    shape: ShadowRuntimeShapeKind.ellipse,
    renderPass: ShadowRenderPass.groundStatic,
    worldLeft: 4,
    worldTop: 4,
    width: 24,
    height: 24,
    opacity: 1,
    colorHexRgb: 'FF0000',
  );
}
```

Le rapport est le fichier courant :

```text
reports/shadows/v2/shadow_v2_24_projected_building_shadow_runtime_render_integration.md
```

Checklist finale :

- [x] Uniquement PlayableMapGame modifié côté production
- [x] Nouveau test host V2 créé
- [x] Rapport Lot 24 créé
- [x] MapLayersComponent non modifié
- [x] ShadowRuntimeRenderer non modifié
- [x] ShadowRuntimeInstructionCollection non modifié
- [x] Builder V2 Lot 22 non modifié
- [x] Adapter V2 Lot 20 non modifié
- [x] map_core non modifié
- [x] Aucun generated modifié
- [x] Aucun Selbrume modifié
- [x] Aucun screenshot/baseline créé
- [x] External provider prioritaire testé
- [x] enableStaticPlacedElementShadows=false testé
- [x] V1 + V2 coexistence testée
- [x] Ordre V2 avant V1 testé
- [x] Anti-dérive genericProjection/diagnostics vérifié
- [x] Tests ciblés passés
- [x] Régression test/shadow passée
- [x] Régression shadow_v2 passée
- [x] Analyze ciblé OK
- [x] Evidence Pack complet
- [x] git status final conforme
