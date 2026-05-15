# Shadow Lot 10 — Shadow Render Order Regression V0

## 1. Résumé

Shadow-10 verrouille l'ordre futur des passes Shadow sans dessiner d'ombres.
Le lot ajoute des contrats purs et des tests de regression pour eviter que les
ombres futures soient rendues au-dessus des acteurs, des occlusions ou des
overlays.

Ce lot ne cree aucun renderer Shadow, aucun canvas preview, aucune instruction
runtime Shadow, et ne deplace aucun ordre de rendu existant. Il distingue
explicitement :

- l'ordre reel observe aujourd'hui dans l'editeur et le runtime ;
- l'ordre cible futur pour l'insertion des ombres.

## 2. Fichiers inspectés

- `packages/map_editor/lib/src/ui/canvas/map_canvas.dart`
- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart`
- `packages/map_editor/lib/src/application/shadow/element_shadow_read_model.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette_panel.dart`
- `packages/map_editor/lib/src/ui/panels/tileset_palette/widgets/shadow/element_shadow_section.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart`
- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/player_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/overworld_actor_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart`
- `packages/map_runtime/lib/src/presentation/flame/runtime_path_autotile.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_render_instruction.dart`
- `packages/map_runtime/lib/src/surface/surface_runtime_resolver.dart`
- `packages/map_runtime/lib/src/infrastructure/runtime_tileset_image.dart`

## 3. Fichiers créés

- `packages/map_editor/lib/src/application/shadow/editor_shadow_render_order_contract.dart`
- `packages/map_editor/test/application/shadow/editor_shadow_render_order_contract_test.dart`
- `packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart`
- `packages/map_runtime/test/shadow/runtime_shadow_render_order_contract_test.dart`
- `reports/shadows/shadow_lot_10_render_order_regression.md`

## 4. Fichiers modifiés

Aucun fichier existant n'a ete modifie. Shadow-10 ajoute seulement deux
contrats purs, deux tests de contrat, et ce rapport.

## 5. Ordre de rendu éditeur actuel

L'ordre reel observe dans `MapGridPainter.paint` est :

1. setup canvas : `save`, `translate`, `scale`
2. couches `TerrainLayer`
3. couches `PathLayer`
4. `TileLayer` background + placed elements background
5. preview des `SurfaceLayer` via `paintSurfaceLayerAtlasTilePreview`
6. `CollisionLayer`
7. grille et hover tile
8. gameplay zones
9. entites background
10. `TileLayer` foreground + placed elements foreground
11. entites foreground
12. selected placed element, tool preview, environment preview/mask/cursor
13. events, triggers, warps, connections
14. bordure de map, puis UI Flutter hors canvas

Preuve inspectee :

- `packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart:256`
- terrain : lignes 271-276
- paths : lignes 278-283
- tile/placed background : lignes 285-301
- surface preview : lignes 303-318
- collision/grid/hover : lignes 320-377
- gameplay/entities/foreground/overlays : lignes 379-413

Point important : l'editeur actuel rend les placed elements background avant la
surface preview. Shadow-10 ne deplace pas cette surface et ne modifie pas
`MapGridPainter`.

## 6. Ordre de rendu runtime Flame actuel

L'ordre reel observe dans `MapLayersComponent.render` et `PlayableMapGame` est :

1. `MapLayersComponent` background, priority `0`
2. dans le pass background : terrain
3. paths
4. surfaces
5. tile layers + placed elements
6. entites map
7. collision overlay runtime si active
8. acteurs Flame joueur/NPC avec priorite `1000 + foot/depth y`
9. `MapLayersComponent` foreground, priority `100000`
10. dans le pass foreground : tile layers + placed elements foreground, puis entites
11. occlusion patch component disponible avec priority proche de `1000 + bottomWorld`
12. HUD/UI Flame hors map layers

Preuve inspectee :

- `packages/map_runtime/lib/src/presentation/flame/map_layers_component.dart:245`
- foreground pass : lignes 248-270
- terrain/path/surface/tile/placed/entity/collision pass : lignes 272-320
- `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:6389`
- background priority `0` : ligne 6400
- foreground priority `100000` : ligne 6414
- actors ajoutes au world : lignes 6417-6455
- player/NPC priorities : `packages/map_runtime/lib/src/presentation/flame/playable_map_game.dart:1603`
- occlusion patch priority : `packages/map_runtime/lib/src/presentation/flame/placed_element_occlusion_patch_component.dart:17`

## 7. Contrat d’ordre futur pour les ombres

Le contrat cible editeur est :

1. `baseTerrain`
2. `groundPaths`
3. `surfacePreview`
4. `futureStaticElementShadows`
5. `futureDynamicActorShadows`
6. `placedElementsBackground`
7. `actorsOrEntitiesBackground`
8. `placedElementsForeground`
9. `actorsOrEntitiesForeground`
10. `foregroundOcclusion`
11. `debugAndSelectionOverlays`
12. `flutterUi`

Le contrat cible runtime est :

1. `baseTerrain`
2. `groundPaths`
3. `surfaceLayers`
4. `futureStaticPlacedElementShadows`
5. `futureDynamicActorContactShadows`
6. `placedElementSprites`
7. `actorsPlayerNpc`
8. `placedElementOcclusionPatches`
9. `debugOverlays`
10. `hudUi`

Regles verrouillees :

- les futures static shadows sont apres terrain/paths/surfaces ;
- les futures static shadows sont avant sprites, actors, occlusion, debug et UI ;
- les futures dynamic actor shadows sont avant actors ;
- les occlusion patches / foreground occlusion restent au-dessus des shadows ;
- les debug overlays et UI restent au-dessus des shadows.

Ce contrat est cible et non une declaration que l'ordre editeur actuel est deja
identique. En particulier, Shadow-10 ne deplace pas `SurfaceLayer` dans
l'editeur.

## 8. Divergences éditeur/runtime à surveiller

- Divergence actuelle : l'editeur peint aujourd'hui les placed elements
  background avant `SurfaceLayer`, alors que le runtime peint les surfaces avant
  les tile/placed elements du pass background.
- Divergence cible : le contrat Shadow place les surfaces/preview avant les
  futures ombres. Un futur lot de rendu devra inserer les shadows sans pretendre
  que l'ordre editeur existant a ete refondu dans Shadow-10.
- Occlusion : le runtime possede un composant `PlacedElementOcclusionPatchComponent`
  avec priorite y-sortee ; l'editeur a surtout des overlays/debug/foreground dans
  le painter. Cette divergence est acceptable tant que les shadows restent sous
  foreground/occlusion/debug.
- A surveiller avant un renderer Shadow : le futur code de rendu devra choisir un
  point d'ancrage concret qui respecte le contrat sans deplacer les passes
  existantes hors lot.

## 9. Tests ajoutés

Tests editeur :

- couverture de tous les slots enum exactement une fois ;
- static shadows apres terrain/paths/surface preview ;
- static shadows avant placed elements, actors/entities, foreground, debug et UI ;
- dynamic actor shadows avant actors/entities, foreground, debug et UI ;
- debug overlays et Flutter UI au-dessus de toutes les futures shadows.

Tests runtime :

- couverture de tous les slots enum exactement une fois ;
- static placed element shadows apres terrain/paths/surface layers ;
- static shadows avant placed sprites, actors, occlusion patches, debug et HUD ;
- dynamic actor contact shadows avant actors, occlusion, debug et HUD ;
- occlusion patches, debug et HUD au-dessus de toutes les futures shadows.

### Code généré — contrat éditeur

```dart
enum EditorShadowRenderOrderSlot {
  baseTerrain,
  groundPaths,
  surfacePreview,
  futureStaticElementShadows,
  futureDynamicActorShadows,
  placedElementsBackground,
  actorsOrEntitiesBackground,
  placedElementsForeground,
  actorsOrEntitiesForeground,
  foregroundOcclusion,
  debugAndSelectionOverlays,
  flutterUi,
}

const editorShadowRenderOrder = <EditorShadowRenderOrderSlot>[
  EditorShadowRenderOrderSlot.baseTerrain,
  EditorShadowRenderOrderSlot.groundPaths,
  EditorShadowRenderOrderSlot.surfacePreview,
  EditorShadowRenderOrderSlot.futureStaticElementShadows,
  EditorShadowRenderOrderSlot.futureDynamicActorShadows,
  EditorShadowRenderOrderSlot.placedElementsBackground,
  EditorShadowRenderOrderSlot.actorsOrEntitiesBackground,
  EditorShadowRenderOrderSlot.placedElementsForeground,
  EditorShadowRenderOrderSlot.actorsOrEntitiesForeground,
  EditorShadowRenderOrderSlot.foregroundOcclusion,
  EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
  EditorShadowRenderOrderSlot.flutterUi,
];

int editorShadowSlotIndex(EditorShadowRenderOrderSlot slot) =>
    editorShadowRenderOrder.indexOf(slot);

bool editorShadowSlotIsBefore(
  EditorShadowRenderOrderSlot a,
  EditorShadowRenderOrderSlot b,
) =>
    editorShadowSlotIndex(a) < editorShadowSlotIndex(b);

bool editorShadowSlotIsAfter(
  EditorShadowRenderOrderSlot a,
  EditorShadowRenderOrderSlot b,
) =>
    editorShadowSlotIndex(a) > editorShadowSlotIndex(b);
```

### Code généré — tests éditeur

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/application/shadow/editor_shadow_render_order_contract.dart';

void main() {
  group('editor shadow render order contract', () {
    test('covers every slot exactly once', () {
      expect(
        editorShadowRenderOrder.toSet(),
        EditorShadowRenderOrderSlot.values.toSet(),
      );
      expect(
        editorShadowRenderOrder.length,
        EditorShadowRenderOrderSlot.values.length,
      );
    });

    test('places static shadows after ground layers', () {
      expect(
        editorShadowSlotIsBefore(
          EditorShadowRenderOrderSlot.baseTerrain,
          EditorShadowRenderOrderSlot.futureStaticElementShadows,
        ),
        isTrue,
      );
      expect(
        editorShadowSlotIsBefore(
          EditorShadowRenderOrderSlot.groundPaths,
          EditorShadowRenderOrderSlot.futureStaticElementShadows,
        ),
        isTrue,
      );
      expect(
        editorShadowSlotIsBefore(
          EditorShadowRenderOrderSlot.surfacePreview,
          EditorShadowRenderOrderSlot.futureStaticElementShadows,
        ),
        isTrue,
      );
    });

    test('places static shadows below sprites foreground and debug overlays',
        () {
      for (final upperSlot in <EditorShadowRenderOrderSlot>[
        EditorShadowRenderOrderSlot.placedElementsBackground,
        EditorShadowRenderOrderSlot.actorsOrEntitiesBackground,
        EditorShadowRenderOrderSlot.placedElementsForeground,
        EditorShadowRenderOrderSlot.actorsOrEntitiesForeground,
        EditorShadowRenderOrderSlot.foregroundOcclusion,
        EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
        EditorShadowRenderOrderSlot.flutterUi,
      ]) {
        expect(
          editorShadowSlotIsBefore(
            EditorShadowRenderOrderSlot.futureStaticElementShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future static shadows must render before $upperSlot',
        );
      }
    });

    test('places dynamic actor shadows below actors and occlusion', () {
      for (final upperSlot in <EditorShadowRenderOrderSlot>[
        EditorShadowRenderOrderSlot.actorsOrEntitiesBackground,
        EditorShadowRenderOrderSlot.placedElementsForeground,
        EditorShadowRenderOrderSlot.actorsOrEntitiesForeground,
        EditorShadowRenderOrderSlot.foregroundOcclusion,
        EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
        EditorShadowRenderOrderSlot.flutterUi,
      ]) {
        expect(
          editorShadowSlotIsBefore(
            EditorShadowRenderOrderSlot.futureDynamicActorShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future dynamic shadows must render before $upperSlot',
        );
      }
    });

    test('keeps debug overlays and Flutter UI above all future shadows', () {
      for (final shadowSlot in <EditorShadowRenderOrderSlot>[
        EditorShadowRenderOrderSlot.futureStaticElementShadows,
        EditorShadowRenderOrderSlot.futureDynamicActorShadows,
      ]) {
        expect(
          editorShadowSlotIsAfter(
            EditorShadowRenderOrderSlot.debugAndSelectionOverlays,
            shadowSlot,
          ),
          isTrue,
        );
        expect(
          editorShadowSlotIsAfter(
            EditorShadowRenderOrderSlot.flutterUi,
            shadowSlot,
          ),
          isTrue,
        );
      }
    });
  });
}
```

### Code généré — contrat runtime

```dart
enum RuntimeShadowRenderOrderSlot {
  baseTerrain,
  groundPaths,
  surfaceLayers,
  futureStaticPlacedElementShadows,
  futureDynamicActorContactShadows,
  placedElementSprites,
  actorsPlayerNpc,
  placedElementOcclusionPatches,
  debugOverlays,
  hudUi,
}

const runtimeShadowRenderOrder = <RuntimeShadowRenderOrderSlot>[
  RuntimeShadowRenderOrderSlot.baseTerrain,
  RuntimeShadowRenderOrderSlot.groundPaths,
  RuntimeShadowRenderOrderSlot.surfaceLayers,
  RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
  RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
  RuntimeShadowRenderOrderSlot.placedElementSprites,
  RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
  RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
  RuntimeShadowRenderOrderSlot.debugOverlays,
  RuntimeShadowRenderOrderSlot.hudUi,
];

int runtimeShadowSlotIndex(RuntimeShadowRenderOrderSlot slot) =>
    runtimeShadowRenderOrder.indexOf(slot);

bool runtimeShadowSlotIsBefore(
  RuntimeShadowRenderOrderSlot a,
  RuntimeShadowRenderOrderSlot b,
) =>
    runtimeShadowSlotIndex(a) < runtimeShadowSlotIndex(b);

bool runtimeShadowSlotIsAfter(
  RuntimeShadowRenderOrderSlot a,
  RuntimeShadowRenderOrderSlot b,
) =>
    runtimeShadowSlotIndex(a) > runtimeShadowSlotIndex(b);
```

### Code généré — tests runtime

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/shadow_runtime_render_order_contract.dart';

void main() {
  group('runtime shadow render order contract', () {
    test('covers every slot exactly once', () {
      expect(
        runtimeShadowRenderOrder.toSet(),
        RuntimeShadowRenderOrderSlot.values.toSet(),
      );
      expect(
        runtimeShadowRenderOrder.length,
        RuntimeShadowRenderOrderSlot.values.length,
      );
    });

    test('places static placed element shadows after ground layers', () {
      expect(
        runtimeShadowSlotIsBefore(
          RuntimeShadowRenderOrderSlot.baseTerrain,
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        ),
        isTrue,
      );
      expect(
        runtimeShadowSlotIsBefore(
          RuntimeShadowRenderOrderSlot.groundPaths,
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        ),
        isTrue,
      );
      expect(
        runtimeShadowSlotIsBefore(
          RuntimeShadowRenderOrderSlot.surfaceLayers,
          RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        ),
        isTrue,
      );
    });

    test('places static shadows below sprites actors occlusion and debug', () {
      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.placedElementSprites,
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(
          runtimeShadowSlotIsBefore(
            RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future static shadows must render before $upperSlot',
        );
      }
    });

    test('places dynamic actor contact shadows below actors and occlusion', () {
      for (final upperSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.actorsPlayerNpc,
        RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
        RuntimeShadowRenderOrderSlot.debugOverlays,
        RuntimeShadowRenderOrderSlot.hudUi,
      ]) {
        expect(
          runtimeShadowSlotIsBefore(
            RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
            upperSlot,
          ),
          isTrue,
          reason: 'future dynamic shadows must render before $upperSlot',
        );
      }
    });

    test('keeps occlusion debug and HUD above all future shadows', () {
      for (final shadowSlot in <RuntimeShadowRenderOrderSlot>[
        RuntimeShadowRenderOrderSlot.futureStaticPlacedElementShadows,
        RuntimeShadowRenderOrderSlot.futureDynamicActorContactShadows,
      ]) {
        expect(
          runtimeShadowSlotIsAfter(
            RuntimeShadowRenderOrderSlot.placedElementOcclusionPatches,
            shadowSlot,
          ),
          isTrue,
        );
        expect(
          runtimeShadowSlotIsAfter(
            RuntimeShadowRenderOrderSlot.debugOverlays,
            shadowSlot,
          ),
          isTrue,
        );
        expect(
          runtimeShadowSlotIsAfter(
            RuntimeShadowRenderOrderSlot.hudUi,
            shadowSlot,
          ),
          isTrue,
        );
      }
    });
  });
}
```

## 10. Commandes lancées

```bash
git status --short --untracked-files=all
rg --files -g AGENTS.md
flutter test test/application/shadow/editor_shadow_render_order_contract_test.dart
flutter test test/shadow/runtime_shadow_render_order_contract_test.dart
dart format packages/map_editor/lib/src/application/shadow/editor_shadow_render_order_contract.dart packages/map_editor/test/application/shadow/editor_shadow_render_order_contract_test.dart packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart packages/map_runtime/test/shadow/runtime_shadow_render_order_contract_test.dart
cd packages/map_editor && flutter test test/application/shadow/editor_shadow_render_order_contract_test.dart
cd packages/map_runtime && flutter test test/shadow/runtime_shadow_render_order_contract_test.dart
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/shadow_runtime_render_order_contract.dart test/shadow/runtime_shadow_render_order_contract_test.dart
cd packages/map_editor && flutter test test/application/shadow
cd packages/map_runtime && flutter test test/shadow
cd packages/map_runtime && flutter test
cd packages/map_editor && flutter test
rg -n "ShadowRuntimeRenderInstruction|ShadowLayerComponent|ShadowRuntimeResolver|drawOval|drawPath|drawShadow|runtimeBlur|blurRadius|zOrder|zIndex" packages/map_editor/lib packages/map_runtime/lib
rg -n "visualMask|collisionMask|occlusionMask|cells|applyCollision" packages/map_editor/lib packages/map_runtime/lib packages/map_core/lib
find packages/map_editor/lib packages/map_runtime/lib -name "*shadow*.g.dart" -o -name "*shadow*.freezed.dart"
git diff --check
git diff --stat
git status --short --untracked-files=all
```

## 11. Résultats des tests ciblés éditeur

Commande :

```bash
cd packages/map_editor && flutter test test/application/shadow/editor_shadow_render_order_contract_test.dart
```

Resultat :

```text
00:00 +5: All tests passed!
```

Phase TDD RED observee avant implementation : le meme test echouait car
`editor_shadow_render_order_contract.dart` n'existait pas et les symboles
`EditorShadowRenderOrderSlot`, `editorShadowRenderOrder`,
`editorShadowSlotIsBefore` et `editorShadowSlotIsAfter` etaient introuvables.

## 12. Résultats des tests ciblés runtime

Commande :

```bash
cd packages/map_runtime && flutter test test/shadow/runtime_shadow_render_order_contract_test.dart
```

Resultat :

```text
00:00 +5: All tests passed!
```

Phase TDD RED observee avant implementation : le meme test echouait car
`shadow_runtime_render_order_contract.dart` n'existait pas et les symboles
`RuntimeShadowRenderOrderSlot`, `runtimeShadowRenderOrder`,
`runtimeShadowSlotIsBefore` et `runtimeShadowSlotIsAfter` etaient introuvables.

Suites Shadow :

```bash
cd packages/map_editor && flutter test test/application/shadow
```

```text
00:00 +28: All tests passed!
```

```bash
cd packages/map_runtime && flutter test test/shadow
```

```text
00:00 +5: All tests passed!
```

## 13. Résultat de flutter analyze / dart analyze

Analyse editeur :

```bash
cd packages/map_editor && flutter analyze lib/src/application/shadow test/application/shadow
```

```text
No issues found! (ran in 1.6s)
```

Analyse runtime :

```bash
cd packages/map_runtime && flutter analyze lib/src/presentation/flame/shadow_runtime_render_order_contract.dart test/shadow/runtime_shadow_render_order_contract_test.dart
```

```text
No issues found! (ran in 1.4s)
```

## 14. Résultats des tests complets, si lancés

Runtime complet :

```bash
cd packages/map_runtime && flutter test
```

```text
01:20 +926: All tests passed!
```

Editeur complet :

```bash
cd packages/map_editor && flutter test
```

Resultat :

```text
01:20 +1415 -45: Some tests failed.
```

Les premieres erreurs sont hors Shadow-10. Elles concernent notamment des tests
existants qui utilisent des expressions `const ProjectManifest(surfaceCatalog:
ProjectSurfaceCatalog())`, alors que `ProjectSurfaceCatalog()` /
`ProjectManifest(...)` ne sont pas const dans l'etat actuel du code. Exemples
vus dans la sortie :

- `test/pokemon_catalogs_workspace_ui_test.dart`
- `test/ui_panels_smoke_test.dart`
- `test/pokemon_catalogs_project_explorer_entry_test.dart`
- `test/project_scenario_use_cases_test.dart`
- `test/trainer_library_panel_test.dart`
- `test/pokedex_external_autocomplete_ui_test.dart`
- `test/pokedex_workspace_ui_test.dart`
- `test/step_studio_workspace_regression_test.dart`
- `test/terrain_preset_selection_coordinator_test.dart`

La suite expose aussi des echecs hors lot dans :

- `test/environment_studio/environment_layer_area_model_editing_test.dart`
- `test/environment_studio/environment_generation_params_draft_editor_test.dart`
- `test/update_pokedex_species_learnset_use_case_test.dart`

Ces echecs ne referencent pas les fichiers Shadow-10 ajoutes.

## 15. Vérifications anti-dérive

Commande :

```bash
rg -n "ShadowRuntimeRenderInstruction|ShadowLayerComponent|ShadowRuntimeResolver|drawOval|drawPath|drawShadow|runtimeBlur|blurRadius|zOrder|zIndex" packages/map_editor/lib packages/map_runtime/lib
```

Resultat : aucune occurrence de `ShadowRuntimeRenderInstruction`,
`ShadowLayerComponent`, `ShadowRuntimeResolver`, `runtimeBlur`, `zOrder` ou
`zIndex` ajoutee par Shadow-10.

La commande retourne des occurrences preexistantes hors Shadow-10 :

- `drawOval` dans des composants battle/runtime existants ;
- `drawPath` dans des composants battle/editor existants ;
- `drawShadow` dans `battle_scene_hud_component.dart` ;
- `blurRadius` dans des widgets/battle overlays existants.

Commande :

```bash
rg -n "visualMask|collisionMask|occlusionMask|cells|applyCollision" packages/map_editor/lib packages/map_runtime/lib packages/map_core/lib
```

Resultat : nombreuses occurrences existantes dans les modeles, generated files,
validators, composants runtime et outils editor. Aucune de ces zones n'a ete
modifiee par Shadow-10.

Commande :

```bash
find packages/map_editor/lib packages/map_runtime/lib -name "*shadow*.g.dart" -o -name "*shadow*.freezed.dart"
```

Resultat :

```text
aucune sortie
```

Confirmations anti-derive :

- aucun `ShadowRuntimeRenderInstruction` ;
- aucun `ShadowRuntimeResolver` ;
- aucun `ShadowLayerComponent` ;
- aucun renderer Shadow ;
- aucun `drawOval` / `drawPath` / `drawImageRect` ajoute pour une ombre ;
- aucun `runtimeBlur` ;
- aucun `blurRadius` ajoute ;
- aucun `zOrder` / `zIndex` libre ;
- aucun `map_core` modifie ;
- aucun `map_gameplay` modifie ;
- aucune collision modifiee ;
- aucune occlusion modifiee ;
- aucun `visualMask` / `collisionMask` / `occlusionMask` / `cells` modifie ;
- aucune UI nouvelle ;
- aucun `MapGridPainter` modifie ;
- aucun `MapLayersComponent` modifie ;
- aucun `PlayableMapGame` modifie ;
- aucun `PlayerComponent` modifie ;
- aucun `OverworldActorComponent` modifie ;
- aucun `PlacedElementOcclusionPatchComponent` modifie.

## 16. Git status initial

Commande :

```bash
git status --short --untracked-files=all
```

Resultat initial :

```text
aucune sortie
```

## 17. Git status final

Commande :

```bash
git status --short --untracked-files=all
```

Resultat final :

```text
?? packages/map_editor/lib/src/application/shadow/editor_shadow_render_order_contract.dart
?? packages/map_editor/test/application/shadow/editor_shadow_render_order_contract_test.dart
?? packages/map_runtime/lib/src/presentation/flame/shadow_runtime_render_order_contract.dart
?? packages/map_runtime/test/shadow/runtime_shadow_render_order_contract_test.dart
?? reports/shadows/shadow_lot_10_render_order_regression.md
```

## 18. Git diff stat final

Commande :

```bash
git diff --stat
```

Resultat final :

```text
aucune sortie
```

Note : `git diff --stat` ne liste pas les fichiers non suivis. Le status final
liste donc les fichiers crees.

## 19. Non-objectifs respectés

- pas d'ombre visible a l'ecran ;
- pas de renderer Shadow ;
- pas de preview canvas ;
- pas de `ShadowRuntimeRenderInstruction` ;
- pas de `ShadowLayerComponent` ;
- pas de modification de `MapGridPainter` ;
- pas de modification de `MapLayersComponent` ;
- pas de modification de `PlayableMapGame` ;
- pas de modification de `PlayerComponent` ;
- pas de modification de `OverworldActorComponent` ;
- pas de modification de `PlacedElementOcclusionPatchComponent` ;
- pas de deplacement des surfaces dans l'editeur ;
- pas de modification de `map_core` ;
- pas de modification de `map_gameplay` ;
- pas de collision / occlusion / gameplay change.

## 20. Risques / réserves

- Le contrat editeur est une cible future. L'ordre actuel du painter n'est pas
  refondu par ce lot, notamment parce que les placed elements background sont
  aujourd'hui peints avant la surface preview.
- Quand le renderer Shadow existera, il faudra remplacer ou completer ces
  tests de contrat par des tests comportementaux sur le point d'insertion reel.
- Le test complet `map_editor` echoue sur des dettes hors lot ; les tests
  cibles Shadow-10 et l'analyse ciblee passent.

## 21. Prochain lot recommandé

Shadow-11 — Runtime Shadow Render Instruction V0
