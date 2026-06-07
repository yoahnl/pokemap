# NS-SCENES-V1-94 — Evidence Pack

## 1. Gate 0

Contexte :

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main
```

Etat initial avant modifications V1-94, repris du journal de session :

```text
git status --short --untracked-files=all
<aucune sortie>

git diff --stat
<aucune sortie>

git diff --name-only
<aucune sortie>
```

Log HEAD :

```text
76a312ec feat(narrative): auto-commit changes
9c5db6f0 feat(narrative): auto-commit changes
eb05d109 feat(narrative): auto-commit changes
3e767d80 feat(narrative): auto-commit changes
3a3689df feat(narrative): auto-commit changes
12e52f7a update selbrume
1ac4186f update selbrume
a085d128 feat(narrative): auto-commit changes
103cc837 feat(narrative): auto-commit changes
fd10cce7 feat(narrative): auto-commit changes
c730bef3 feat(narrative): auto-commit changes
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
```

## 2. RED test

Premier test ajouté avant implémentation :

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'builds extended backdrop bitmap instructions for neutral terrain path surface and placed elements'
```

Résultat attendu avant code :

```text
Exit 1
missing files:
  cinematic_map_backdrop_layer_render_plan.dart
  cinematic_map_backdrop_render_pass.dart
type CinematicMapBackdropLayerRenderPlan not found
function buildCinematicMapBackdropLayerRenderPlan not found
enum CinematicMapBackdropRenderPass undefined
no named parameter backdropLayerRenderPlan on CinematicBuilderWorkspace
```

## 3. GREEN tests ciblés

```text
flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
```

Résultat :

```text
00:25 +174: All tests passed!
```

```text
flutter test --reporter=compact test/cinematics_library_workspace_test.dart
```

Résultat :

```text
00:06 +21: All tests passed!
```

## 4. Visual Gate

Commande :

```text
flutter test --update-goldens --dart-define=NS_SCENES_V1_94_CAPTURE_CINEMATIC_EXTENDED_MAP_BACKDROP=true --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'captures V1-94 cinematic extended map backdrop visual gate when requested'
```

Résultat : test vert.

Fichier :

```text
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png
```

Preuve fichier :

```text
-rw-r--r--  1 karim  staff  248436 Jun  7 03:21 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png: PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced
3cc17a0b4a9d986df0bf9b262014489185693b473501f52436c8ebde4dfa649c  reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png
```

## 5. Validation core

Commande :

```text
dart test --reporter=compact
```

Package :

```text
packages/map_core
```

Résultat :

```text
00:05 +2438: All tests passed!
```

## 6. Analyze ciblé

Commande :

```text
flutter analyze --no-fatal-infos \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_plan_loader.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_renderer.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart \
  lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_viewport_transform.dart \
  lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart \
  lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart \
  test/cinematic_builder_workspace_test.dart \
  test/cinematics_library_workspace_test.dart
```

Résultat :

```text
Analyzing 14 items...
No issues found! (ran in 1.5s)
```

## 7. Vérifications larges

Commande :

```text
flutter test --reporter=compact
```

Package :

```text
packages/map_editor
```

Résultat :

```text
01:39 +2220 -18: Some tests failed.
```

Échecs observés hors lot :

```text
Golden "../../../reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_29_storyline_step_scene_link_v0.png":
Pixel test failed, 0.61%, 7671px diff detected.

pokemon_sdk_move_catalog_converter_test.dart:
compilation errors on PokemonMoveAimedTarget / PokemonMoveFlags / PokemonMoveBattleStageMod / PokemonMoveStatus.
```

Commande :

```text
flutter analyze
```

Package :

```text
packages/map_editor
```

Résultat :

```text
344 issues found. (ran in 4.2s)
```

Premiers erreurs hors lot :

```text
pokemon_sdk_move_catalog_converter.dart: undefined named parameters dbSymbol, battleEngineAimedTarget, battleEngineMethod, effectChance, studioFlags, battleStageMods, moveStatuses
pokemon_sdk_move_catalog_converter.dart: Undefined class/name PokemonMoveAimedTarget, PokemonMoveFlags, PokemonMoveBattleStageMod, PokemonMoveStatus
sync_pokemon_sdk_moves_catalog_use_case.dart: fetchPokemonSdkStudioProjectPayload undefined
```

## 8. Checks anti-scope

Diff hors packages autorisés :

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<aucune sortie>
```

Runtime/Flame/MapCanvas brut :

```text
rg "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|MapLayersComponent|PlayerComponent|OverworldActorComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime" <fichiers V1-94>
<aucune sortie>

rg "MapCanvas\\(|MapGridPainter\\(" <fichiers V1-94>
<aucune sortie>
```

Playback :

```text
rg "startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|seek|scrub|scrubber" <fichiers V1-94>
packages/map_editor/test/cinematic_builder_workspace_test.dart:5043:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:5044:    expect(find.text('scrub'), findsNothing);
```

Interprétation : les deux hits sont des assertions négatives.

Sprites acteurs :

```text
rg "CharacterSprite|ActorSprite|Sprite|ImageProvider|AssetImage|rootBundle|actorSprite|characterSprite" <sources V1-94>
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart:1424:  'characterAssetMissingSprite',
```

Interprétation : diagnostic existant, pas rendu de sprite acteur.

Chargement image dans build/paint :

```text
rg "readAsBytes|instantiateImageCodec|decodeImageFromList|File\\(" <sources V1-94>
<aucune sortie>
```

Selbrume/hardcode :

```text
rg "Selbrume|selbrume|Lysa|lysa|Mael|Maël|mael|port_brisants|bourg_selbrume|marais|phare" <sources V1-94>
<aucune sortie>
```

Fakes :

```text
rg "fakeTerrain|fakePath|fakeEnvironment|fakePlaced|mockTerrain|mockPath|hardcoded.*terrain|hardcoded.*path|hardcoded.*environment" <sources V1-94>
<aucune sortie>
```

Image IA :

```text
rg "gpt-image-2|image_generation|generate image|AI image|image model" <fichiers V1-94>
<aucune sortie>
```

Couleurs :

```text
rg "Color\\(0x|Colors\\." <sources V1-94>
cinematic_builder_workspace.dart: plusieurs hits préexistants

git diff -- <sources V1-94> | rg "^\\+.*(Color\\(0x|Colors\\.)"
<aucune sortie>
```

Interprétation : V1-94 n'ajoute pas de couleur hardcodée.

## 9. Code généré — cinematic_map_backdrop_render_pass.dart

```dart
enum CinematicMapBackdropRenderPass {
  terrain,
  path,
  tileBackground,
  surface,
  placedBackground,
  tileForeground,
  placedForeground,
}

extension CinematicMapBackdropRenderPassX on CinematicMapBackdropRenderPass {
  int get order => switch (this) {
        CinematicMapBackdropRenderPass.terrain => 0,
        CinematicMapBackdropRenderPass.path => 1,
        CinematicMapBackdropRenderPass.tileBackground => 2,
        CinematicMapBackdropRenderPass.surface => 3,
        CinematicMapBackdropRenderPass.placedBackground => 4,
        CinematicMapBackdropRenderPass.tileForeground => 5,
        CinematicMapBackdropRenderPass.placedForeground => 6,
      };

  bool get paintsBeforeActorOverlay =>
      order < CinematicMapBackdropRenderPass.tileForeground.order;

  bool get paintsAfterActorOverlay => !paintsBeforeActorOverlay;
}
```

## 10. Code généré — cinematic_map_backdrop_layer_plan_loader.dart

```dart
import 'package:map_core/map_core.dart';

import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_tile_plan_loader.dart';
import 'cinematic_map_backdrop_tile_render_plan.dart';
import 'cinematic_tileset_asset_registry.dart';

final class CinematicMapBackdropLayerPlanLoader {
  CinematicMapBackdropLayerPlanLoader({
    CinematicTilesetAssetRegistry? registry,
  }) : _registry = registry ?? CinematicTilesetAssetRegistry();

  final CinematicTilesetAssetRegistry _registry;

  Future<CinematicMapBackdropLayerRenderPlan?> load({
    required ProjectManifest manifest,
    required MapData? mapData,
    required CinematicMapBackdropPreviewModel? previewModel,
    required ResolveCinematicBackdropTilesetPath resolveTilesetPath,
  }) async {
    if (mapData == null || previewModel == null || !previewModel.isAvailable) {
      return null;
    }
    final tilesetIds = collectCinematicMapBackdropLayerTilesetIds(
      mapData: mapData,
      manifest: manifest,
    );
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
    return buildCinematicMapBackdropLayerRenderPlan(
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

## 11. Code généré — cinematic_map_backdrop_layer_renderer.dart

```dart
import 'dart:ui' as ui;

import 'package:flutter/cupertino.dart';

import 'cinematic_map_backdrop_layer_render_plan.dart';
import 'cinematic_map_backdrop_render_pass.dart';
import 'cinematic_map_backdrop_tile_renderer.dart';

final class CinematicMapBackdropLayerRenderPainter extends CustomPainter {
  CinematicMapBackdropLayerRenderPainter({
    required this.plan,
    required this.palette,
    this.passes,
    this.paintBackground = true,
    this.paintGridAndBorder = true,
  });

  final CinematicMapBackdropLayerRenderPlan plan;
  final CinematicMapBackdropTileRenderPalette palette;
  final Set<CinematicMapBackdropRenderPass>? passes;
  final bool paintBackground;
  final bool paintGridAndBorder;

  @override
  void paint(Canvas canvas, Size size) {
    final scaleX = size.width / plan.pixelWidth;
    final scaleY = size.height / plan.pixelHeight;
    if (paintBackground) {
      canvas.drawRect(Offset.zero & size, Paint()..color = palette.background);
    }

    for (final instruction in plan.instructions) {
      if (passes != null && !passes!.contains(instruction.renderPass)) {
        continue;
      }
      final image = plan.tilesets[instruction.tilesetId]?.image;
      if (image == null) {
        continue;
      }
      final paint = Paint()
        ..isAntiAlias = false
        ..filterQuality = ui.FilterQuality.none;
      final opacity = instruction.opacity.clamp(0.0, 1.0).toDouble();
      if (opacity < 1) {
        paint.colorFilter = ColorFilter.mode(
          Color.fromRGBO(255, 255, 255, opacity),
          BlendMode.modulate,
        );
      }
      final destination = ui.Rect.fromLTWH(
        instruction.destinationRect.left * scaleX,
        instruction.destinationRect.top * scaleY,
        instruction.destinationRect.width * scaleX,
        instruction.destinationRect.height * scaleY,
      );
      canvas.drawImageRect(
        image,
        instruction.sourceRect,
        destination,
        paint,
      );
    }

    if (paintGridAndBorder) {
      _paintGrid(canvas, size);
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..color = palette.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _paintGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = palette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final cellWidth = size.width / plan.mapWidth;
    final cellHeight = size.height / plan.mapHeight;
    for (var x = 1; x < plan.mapWidth; x += 1) {
      final dx = x * cellWidth;
      canvas.drawLine(Offset(dx, 0), Offset(dx, size.height), gridPaint);
    }
    for (var y = 1; y < plan.mapHeight; y += 1) {
      final dy = y * cellHeight;
      canvas.drawLine(Offset(0, dy), Offset(size.width, dy), gridPaint);
    }
  }

  @override
  bool shouldRepaint(CinematicMapBackdropLayerRenderPainter oldDelegate) {
    return oldDelegate.plan != plan ||
        oldDelegate.palette != palette ||
        oldDelegate.passes != passes ||
        oldDelegate.paintBackground != paintBackground ||
        oldDelegate.paintGridAndBorder != paintGridAndBorder;
  }
}
```

## 12. Code généré — plan multi-layer structurant

Fichier complet :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
1037 lignes
```

Extrait principal :

```dart
final class CinematicMapBackdropLayerBitmapInstruction {
  const CinematicMapBackdropLayerBitmapInstruction({
    required this.id,
    required this.layerId,
    required this.layerLabel,
    required this.layerKind,
    required this.renderPass,
    required this.zOrder,
    required this.tilesetId,
    required this.sourceRect,
    required this.destinationRect,
    required this.opacity,
    required this.sourceFamily,
    required this.sourceId,
    this.tileId,
  });

  final String id;
  final String layerId;
  final String layerLabel;
  final CinematicMapBackdropLayerKind layerKind;
  final CinematicMapBackdropRenderPass renderPass;
  final int zOrder;
  final String tilesetId;
  final ui.Rect sourceRect;
  final ui.Rect destinationRect;
  final double opacity;
  final String sourceFamily;
  final String sourceId;
  final int? tileId;
}

final class CinematicMapBackdropLayerRenderPlan {
  const CinematicMapBackdropLayerRenderPlan({
    required this.mapWidth,
    required this.mapHeight,
    required this.tileWidth,
    required this.tileHeight,
    required this.tilesets,
    required this.instructions,
    required this.diagnostics,
  });

  final int mapWidth;
  final int mapHeight;
  final int tileWidth;
  final int tileHeight;
  final Map<String, CinematicResolvedTilesetAsset> tilesets;
  final List<CinematicMapBackdropLayerBitmapInstruction> instructions;
  final List<CinematicMapBackdropTileDiagnostic> diagnostics;

  bool get hasBitmapInstructions => instructions.isNotEmpty;
  bool get hasForegroundInstructions => instructions.any(
        (instruction) => instruction.renderPass.paintsAfterActorOverlay,
      );
  double get pixelWidth => mapWidth * tileWidth.toDouble();
  double get pixelHeight => mapHeight * tileHeight.toDouble();
}
```

Build entry :

```dart
CinematicMapBackdropLayerRenderPlan buildCinematicMapBackdropLayerRenderPlan({
  required MapData mapData,
  required ProjectManifest manifest,
  required Map<String, CinematicResolvedTilesetAsset> tilesets,
}) {
  final tileWidth = manifest.settings.tileWidth;
  final tileHeight = manifest.settings.tileHeight;
  final diagnostics = <CinematicMapBackdropTileDiagnostic>[];
  final instructions = <CinematicMapBackdropLayerBitmapInstruction>[];
  final manifestTilesetIds = {
    for (final tileset in manifest.tilesets) tileset.id.trim(),
  }..remove('');

  final foregroundTileCells = buildCinematicBackdropForegroundTileCellIndices(
    map: mapData,
    manifest: manifest,
  );
  final generatedPlacementIds =
      collectCinematicBackdropGeneratedPlacementIds(mapData);

  for (final layer in mapData.layers) {
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    switch (layer) {
      case TerrainLayer():
        // terrain pass
      case PathLayer():
        // path pass
      case TileLayer():
        // tile background/foreground pass
      case SurfaceLayer():
        // surface pass
      case CollisionLayer():
      case ObjectLayer():
      case EnvironmentLayer():
        break;
    }
  }

  // placed elements and generated placements
  instructions.sort((a, b) {
    final passCompare = a.renderPass.order.compareTo(b.renderPass.order);
    if (passCompare != 0) {
      return passCompare;
    }
    return a.zOrder.compareTo(b.zOrder);
  });

  return CinematicMapBackdropLayerRenderPlan(
    mapWidth: mapData.size.width,
    mapHeight: mapData.size.height,
    tileWidth: tileWidth,
    tileHeight: tileHeight,
    tilesets: Map<String, CinematicResolvedTilesetAsset>.unmodifiable(tilesets),
    instructions: List<CinematicMapBackdropLayerBitmapInstruction>.unmodifiable(
      instructions,
    ),
    diagnostics:
        List<CinematicMapBackdropTileDiagnostic>.unmodifiable(diagnostics),
  );
}
```

Environment rule :

```dart
Set<String> collectCinematicBackdropGeneratedPlacementIds(MapData mapData) {
  final generatedIds = <String>{};
  for (final layer in mapData.layers.whereType<EnvironmentLayer>()) {
    if (!layer.isVisible || layer.opacity <= 0) {
      continue;
    }
    generatedIds.addAll(layer.content.generatedPlacementIds);
  }
  return Set<String>.unmodifiable(generatedIds);
}
```

## 13. Code modifié — Builder wiring

```diff
+import 'cinematic_map_backdrop_layer_render_plan.dart';
 ...
+    this.backdropLayerRenderPlan,
 ...
+  final CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan;
 ...
+                                backdropLayerRenderPlan:
+                                    widget.backdropLayerRenderPlan,
 ...
+              layerRenderPlan: backdropLayerRenderPlan,
```

## 14. Code modifié — Library loader wiring

```diff
+import 'cinematic_map_backdrop_layer_plan_loader.dart';
+import 'cinematic_map_backdrop_layer_render_plan.dart';
 ...
-  final _backdropTilePlanLoader = CinematicMapBackdropTilePlanLoader();
+  final _backdropLayerPlanLoader = CinematicMapBackdropLayerPlanLoader();
 ...
+  CinematicMapBackdropLayerRenderPlan? _backdropLayerRenderPlan;
+  String? _backdropLayerRenderPlanMapId;
 ...
+      final backdropLayerRenderPlan = _buildBackdropLayerRenderPlan(
+        builderAsset,
+      );
 ...
+        backdropLayerRenderPlan: backdropLayerRenderPlan,
```

## 15. Code modifié — Preview composition

```dart
final backgroundPasses = {
  for (final pass in CinematicMapBackdropRenderPass.values)
    if (pass.paintsBeforeActorOverlay) pass,
};
final foregroundPasses = {
  for (final pass in CinematicMapBackdropRenderPass.values)
    if (pass.paintsAfterActorOverlay) pass,
};

Stack(
  children: [
    CustomPaint(
      painter: CinematicMapBackdropLayerRenderPainter(
        plan: plan,
        palette: palette,
        passes: backgroundPasses,
        paintGridAndBorder: false,
      ),
      child: const SizedBox.expand(),
    ),
    if (actorDisplayPreviewModel != null)
      CinematicActorDisplayPreviewOverlay(
        model: actorDisplayPreviewModel!,
        mapWidth: plan.mapWidth,
        mapHeight: plan.mapHeight,
        compact: compact,
      ),
    CustomPaint(
      painter: CinematicMapBackdropLayerRenderPainter(
        plan: plan,
        palette: palette,
        passes: foregroundPasses,
        paintBackground: false,
      ),
      child: const SizedBox.expand(),
    ),
  ],
)
```

## 16. File inventory

Créés :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_render_plan.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_renderer.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_94_cinematic_extended_map_backdrop_visual_gate_v0.png
```

Modifiés :

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 17. Auto-review checklist

```text
map_runtime modifie ? non
map_gameplay/map_battle/examples modifies ? non
selbrume modifie ? non
Flame importe ? non
map_runtime importe ? non
PlayableMapGame/GameState utilises ? non
MapCanvas complet branche ? non
MapGridPainter brut instancie ? non
playback ajoute ? non
currentTimeMs/playbackTimeMs/isPlaying ajoutes ? non
actorMove execute/interpole ? non
pathfinding/collision runtime ajoute ? non
TerrainLayer rendu ? oui
PathLayer rendu ? oui
SurfaceLayer rendu ? oui
MapPlacedElement rendu ? oui
EnvironmentLayer rendu brut ? non
Actor Display V1-92 preserve ? oui
Visual Gate generee ? oui
```

## 18. Conclusion

V1-94 rend le décor cinematic beaucoup plus proche du Map Editor. V1-94 ne lance toujours pas la cinématique.
