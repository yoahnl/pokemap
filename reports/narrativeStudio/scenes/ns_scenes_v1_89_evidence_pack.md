# NS-SCENES-V1-89 — Evidence Pack

Date : 2026-06-06

## 1. Gate 0 complet

```text
pwd
/Users/karim/Project/pokemonProject
```

```text
git branch --show-current
main
```

```text
git status --short --untracked-files=all
(aucune sortie)
```

```text
git diff --stat
(aucune sortie)
```

```text
git diff --name-only
(aucune sortie)
```

```text
git log --oneline -n 15
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic workspace and add test failure assets (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
```

Note : plus tard pendant le travail, `git log --oneline -n 15` montrait deux commits `update selbrume` au-dessus de `a085d128`. Aucune commande Git d'écriture n'a été exécutée par Codex.

## 2. Fichiers lus

```text
AGENTS.md
skills/README.md
skills/systematic-debugging/SKILL.md
skills/test-driven-development/SKILL.md
skills/verification-before-completion/SKILL.md
skills/writing-plans/SKILL.md
skills/subagent-driven-development/SKILL.md
skills/dispatching-parallel-agents/SKILL.md
/Users/karim/.codex/attachments/01ce44bc-4e75-42d9-8b5b-9c967fd8b8d9/pasted-text.txt
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/ns_scenes_v1_88_cinematic_map_backdrop_real_tile_renderer_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_88_evidence_pack.md
reports/narrativeStudio/scenes/ns_scenes_v1_87_cinematic_map_backdrop_real_tile_rendering_prep_contract.md
reports/narrativeStudio/scenes/ns_scenes_v1_86_cinematic_map_backdrop_visual_composition_polish_v0.md
packages/map_core/lib/src/models/map_data.dart
packages/map_core/lib/src/models/map_layer.dart
packages/map_core/lib/src/models/project_manifest.dart
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_editor/lib/src/application/notifiers/editor_notifier.dart
packages/map_editor/lib/src/ui/canvas/map_canvas.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_canvas_assets.dart
packages/map_editor/lib/src/ui/canvas/map_canvas/map_grid_painter.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
```

## 3. Subagents / passes spécialisées

Sub-agent A — Workspace / Asset Wiring :

```text
CinematicTilesetAssetRegistry existe mais V1-88 ne l'instancie pas dans le flux produit.
CinematicsLibraryWorkspace possède ProjectManifest, MapData snapshot et le modèle preview.
NarrativeWorkspaceCanvas peut fournir EditorNotifier.getTilesetAbsolutePathById.
Recommandation : créer un loader editor-only dans la Library, alimenté par un resolver parent.
```

Sub-agent B — Tile Render Plan Fidelity :

```text
V1-88 rend TileLayer visible avec tileId 1-based, visibilité et opacité.
Gaps : wiring produit absent, diagnostics métriques absents, diagnostics partiels peu visibles.
Recommandation : ajouter tileMetricMismatch, noBitmapInstructions et tests sourceRectOutOfBounds/fallback mapData.tilesetId.
```

Sub-agent C — Visual Fidelity / UI :

```text
Le label "Carte du projet (statique)" est correct.
"Fallback structurel" ne doit pas apparaître si des vraies tiles bitmap sont rendues.
Les diagnostics de plan doivent être visibles.
Timeline et inspector doivent rester visibles.
```

Sub-agent D — Tests / Anti-scope :

```text
Tests recommandés : success path via parent, fallback asset manquant, collecteur de tilesets, plan fidelity, transports disabled, non-mutation, Visual Gate.
Scans anti-scope : runtime/Flame, playback, actor rendering, MapCanvas, File/decode hors registry, couleurs hardcodées, image IA.
```

Sub-agent E — Product Reviewer :

```text
No-go vers Actor Display après V1-88 seul.
Go vers Actor Display Prep après V1-89 si le workspace réel fournit le plan bitmap, les fallbacks sont diagnostiqués, la timeline reste visible et aucun runtime/acteur n'est ajouté.
```

## 4. RED test output

Premier RED après ajout du test `wires project tileset assets into cinematic real tile backdrop plan` :

```text
Error: No named parameter with the name 'onResolveBackdropTilesetPath'.
...
lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:173:9: Context: Found this candidate, but the arguments don't match.
  const CinematicsLibraryWorkspace({
        ^^^^^^^^^^^^^^^^^^^^^^^^^^
Some tests failed.
```

RED intermédiaire après signature ajoutée mais avant attente async correcte :

```text
Expected: exactly one matching candidate
  Actual: _KeyWidgetFinder:<Found 0 widgets with key [<'cinematic-builder-map-backdrop-bitmap'>]: []>
Which: means none were found but one was expected
```

Root cause confirmée : le loader isolé passait, mais le test widget devait déclencher le pump qui démarre le codec dans `tester.runAsync`.

RED fidelity sur fixture de plan :

```text
Expected: contains 'tileMetricMismatch'
  Actual: MappedListIterable<CinematicMapBackdropTileDiagnostic, String>:[
            'missingTilesetEntry',
            'sourceRectOutOfBounds',
            'missingTilesetEntry'
          ]
Which: does not contain 'tileMetricMismatch'
```

Cause : la fixture avait ajouté `wide_tiles` au mauvais manifeste de test. Correction : ajouter `ProjectTilesetEntry(id: 'wide_tiles', ...)` dans le manifeste exact du test.

## 5. Code généré

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart`

```dart
import 'package:map_core/map_core.dart';

import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_tileset_asset_registry.dart';

typedef ResolveCinematicBackdropTilesetPath = String? Function(
  String tilesetId,
);

final class CinematicMapBackdropTilePlanLoader {
  CinematicMapBackdropTilePlanLoader({
    CinematicTilesetAssetRegistry? registry,
  }) : _registry = registry ?? CinematicTilesetAssetRegistry();

  final CinematicTilesetAssetRegistry _registry;

  Future<CinematicMapBackdropTileRenderPlan?> load({
    required ProjectManifest manifest,
    required MapData? mapData,
    required CinematicMapBackdropPreviewModel? previewModel,
    required ResolveCinematicBackdropTilesetPath resolveTilesetPath,
  }) async {
    if (mapData == null || previewModel == null || !previewModel.isAvailable) {
      return null;
    }
    final tilesetIds = collectCinematicMapBackdropTileLayerTilesetIds(mapData);
    final resolvedTilesets = <String, CinematicResolvedTilesetAsset>{};
    for (final tilesetId in tilesetIds) {
      final tileset = _tilesetById(manifest, tilesetId);
      resolvedTilesets[tilesetId] = await _registry.resolve(
        tileset: tileset,
        absolutePath: tileset == null ? null : resolveTilesetPath(tilesetId),
        tileWidth: manifest.settings.tileWidth,
        tileHeight: manifest.settings.tileHeight,
      );
    }
    return buildCinematicMapBackdropTileRenderPlan(
      mapData: mapData,
      manifest: manifest,
      tilesets: resolvedTilesets,
    );
  }

  void invalidateTileset(String tilesetId) {
    _registry.invalidateTileset(tilesetId);
  }

  void clear() {
    _registry.clear();
  }
}

Set<String> collectCinematicMapBackdropTileLayerTilesetIds(MapData mapData) {
  final ids = <String>{};
  for (final layer in mapData.layers) {
    if (layer is! TileLayer || !layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    if (!layer.tiles.any((tileId) => tileId > 0)) {
      continue;
    }
    final tilesetId = (layer.tilesetId ?? mapData.tilesetId).trim();
    if (tilesetId.isNotEmpty) {
      ids.add(tilesetId);
    }
  }
  return ids;
}

ProjectTilesetEntry? _tilesetById(
  ProjectManifest manifest,
  String tilesetId,
) {
  for (final tileset in manifest.tilesets) {
    if (tileset.id.trim() == tilesetId) {
      return tileset;
    }
  }
  return null;
}
```

## 6. Hunk inventory

`cinematics_library_workspace.dart` :

```text
Import du loader.
Nouveau paramètre onResolveBackdropTilesetPath.
Nouveau state : _backdropTilePlanLoader, _backdropTileRenderPlan, _backdropTileRenderPlanMapId, _loadingBackdropTileRenderPlanMapId.
Chargement du preview model et du plan bitmap après onLoadStageMapSnapshot.
Fallback vers onBuildBackdropTileRenderPlan si un callback explicite est encore fourni.
Reset du plan au close/invalidation/dispose.
```

`narrative_workspace_canvas.dart` :

```text
CinematicsLibraryWorkspace reçoit onResolveBackdropTilesetPath: widget.editorNotifier.getTilesetAbsolutePathById.
```

`cinematic_map_backdrop_tile_render_plan.dart` :

```text
Diagnostic tileMetricMismatch si les métriques resolved tileset diffèrent des settings projet.
Diagnostic noBitmapInstructions si aucun bitmap et aucun diagnostic n'existaient.
```

`cinematic_map_backdrop_preview_panel.dart` :

```text
Les diagnostics du plan sont affichés même quand le plan contient aussi des instructions bitmap.
```

`cinematics_library_workspace_test.dart` :

```text
Ajout du test d'intégration parent/resolver.
Ajout du fallback asset manquant.
Ajout du test loader réel avec PNG de fixture.
Ajout du test collecteur layer/default tileset.
Ajout du Visual Gate V1-89.
Harness agrandi à 1663 x 926 pour la capture.
```

`cinematic_builder_workspace_test.dart` :

```text
Extension du test plan avec sourceRectOutOfBounds et tileMetricMismatch.
```

## 7. GREEN test output

`cinematics_library_workspace_test.dart` complet :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
00:06 +20: All tests passed!
```

`cinematic_builder_workspace_test.dart` complet :

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
00:24 +155: All tests passed!
```

Visual Gate V1-89 :

```text
cd packages/map_editor && flutter test --update-goldens --reporter=compact --dart-define=NS_SCENES_V1_89_CAPTURE_CINEMATIC_MAP_BACKDROP_REAL_TILE_INTEGRATION=true test/cinematics_library_workspace_test.dart --plain-name 'captures V1-89 real tile backdrop integration screenshot when requested'
00:07 +1: All tests passed!
```

Core :

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
00:00 +19: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
00:00 +7: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
00:00 +14: All tests passed!
```

```text
cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
00:00 +9: All tests passed!
```

```text
cd packages/map_core && dart analyze
Analyzing map_core...
No issues found!
```

Analyse ciblée editor :

```text
cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart lib/src/ui/canvas/narrative_workspace_canvas.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 10 items...
No issues found! (ran in 2.0s)
```

Analyse globale editor :

```text
cd packages/map_editor && flutter analyze
Analyzing map_editor...
344 issues found. (ran in 2.9s)
```

Premières erreurs globales hors scope :

```text
error • The named parameter 'dbSymbol' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:58:7 • undefined_named_parameter
error • The named parameter 'battleEngineAimedTarget' isn't defined • lib/src/application/services/pokemon_sdk_move_catalog_converter.dart:64:7 • undefined_named_parameter
error • The method 'fetchPokemonSdkStudioProjectPayload' isn't defined for the type 'PokemonExternalSourceRepository' • lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart:58:10 • undefined_method
```

## 8. Visual Gate proof

```text
file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
```

```text
shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png
ef160c2febfd96a9fbc8cdcfe8d2e140238bf7f12020e6c4892df5226ef1844f  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png
```

## 9. Checks anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
(aucune sortie)
```

```text
rg -n "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|MapLayersComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
(aucune sortie)
```

```text
rg -n "startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|seek|scrub|scrubber" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
packages/map_editor/test/cinematic_builder_workspace_test.dart:4141:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:4142:    expect(find.text('scrub'), findsNothing);
```

Interprétation : ces deux occurrences sont des assertions de non-présence, pas du playback.

```text
rg -n "PlayerComponent|OverworldActorComponent|CharacterSprite|ActorSprite|renderActor|drawActor|actorRenderer|sprite actor|CharacterAnimation" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
(aucune sortie)
```

```text
rg -n "MapCanvas\\(|MapGridPainter\\(" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart || true
(aucune sortie)
```

```text
rg -n "readAsBytes|instantiateImageCodec|decodeImageFromList|File\\(" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:80:      final file = File(absolutePath);
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:88:      final bytes = await file.readAsBytes();
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_tileset_asset_registry.dart:108:      final codec = await ui.instantiateImageCodec(displayBytes);
```

Interprétation : chargement limité au registry/cache, hors `build()`/`paint()`.

```text
rg -n "fakeMap|fakeTile|mockTile|hardcoded.*map|bourg_selbrume|port_brisants|lysa|mael|maël" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
(aucune sortie)
```

```text
rg -n "Color\\(0x|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart || true
(aucune sortie)
```

```text
rg -n "gpt-image-2|image_generation|generate image|AI image|image model" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md reports/narrativeStudio/scenes/road_map_scenes.md || true
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md:189:Limites : le rendu reste structurel et non jouable. Aucun tileset asset final, acteur rendu, runtime, Flame, playback, pathfinding/collision, mutation map/projet, donnee Selbrume, image IA ou `gpt-image-2` n'est ajoute.
reports/narrativeStudio/scenes/road_map_scenes.md:224:Limites : rendu toujours structurel ; les vraies tiles/assets ne sont pas rendues. Aucun acteur, runtime, Flame, playback, pathfinding/collision, mutation map/projet, donnee Selbrume, image IA ou modele `gpt-image-2` n'est ajoute.
```

Interprétation : occurrences historiques de limites anti-image IA, aucune utilisation d'image IA.

## 10. Sorties Git finales

```text
git diff --check
(aucune sortie)
```

```text
git diff --stat
 .../cinematic_map_backdrop_preview_panel.dart      |   4 +-
 .../cinematic_map_backdrop_tile_render_plan.dart   |  21 +
 .../cinematics/cinematics_library_workspace.dart   | 134 ++++++-
 .../src/ui/canvas/narrative_workspace_canvas.dart  |   2 +
 .../test/cinematic_builder_workspace_test.dart     |  31 ++
 .../test/cinematics_library_workspace_test.dart    | 431 ++++++++++++++++++++-
 .../scenes/road_map_scene_builder_authoring.md     |  27 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  33 +-
 8 files changed, 646 insertions(+), 37 deletions(-)
```

```text
git diff --name-only
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

```text
git status --short --untracked-files=all
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/narrative_workspace_canvas.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_89_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_89_cinematic_map_backdrop_real_tile_renderer_integration_fidelity_polish_v0.png
?? selbrume/assets/tilesets/bateau_selbrume.png
```

Note : `selbrume/assets/tilesets/bateau_selbrume.png` n'appartient pas au lot V1-89 et n'a pas été modifié par Codex.

## 11. Auto-review critique

1. map_runtime modifié ? Non.
2. map_gameplay/map_battle/examples modifiés ? Non.
3. selbrume modifié ? Non.
4. Flame importé ? Non.
5. map_runtime importé ? Non.
6. PlayableMapGame utilisé ? Non.
7. MapCanvas complet branché ? Non.
8. MapGridPainter brut branché ? Non.
9. Chargement image dans build ? Non.
10. Chargement image dans paint ? Non.
11. Playback ajouté ? Non.
12. currentTimeMs/playbackTimeMs/isPlaying ajoutés ? Non.
13. Acteurs rendus ? Non.
14. Collisions/triggers/events/entities rendus ? Non.
15. Registry réel câblé depuis parent ? Oui.
16. TileLayer via vraies images quand disponibles ? Oui.
17. Fallback structurel réduit ? Oui pour les cas V1-89.
18. Diagnostics asset visibles ? Oui.
19. Timeline visible ? Oui.
20. Transports disabled ? Oui.
21. Duration editor/resize ? Couvert par suite builder verte.
22. Probe/navigation clavier ? Couvert par suite builder verte.
23. Pickers mapEntity/mapEvent ? Couvert par suite builder verte.
24. Character Library picker ? Couvert par suite builder verte.
25. Visual Gate utile ? Oui.
26. Evidence Pack sans placeholders ? Oui.
27. Prochain lot exact : `NS-SCENES-V1-90 — Cinematic Actor Display Preview Prep Contract`.
