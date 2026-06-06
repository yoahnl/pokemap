# NS-SCENES-V1-85 — Evidence Pack

Lot : `NS-SCENES-V1-85 — Cinematic Map Backdrop Visual Primitives V0`

Objectif : remplacer le rendu V1-84 en bandes par une preview spatiale statique et read-only, derivee de `MapData`, sans runtime, Flame, playback, acteurs rendus, fake map, collision/pathfinding, donnees Selbrume ou image IA.

## 1. Gate 0

```text
pwd
/Users/karim/Project/pokemonProject

git branch --show-current
main

git status --short --untracked-files=all
<vide>

git diff --stat
<vide>

git diff --name-only
<vide>

git log --oneline -n 15
3b73a8fd feat(narrative): auto-commit changes
587b47f6 update selbrume
50a43df8 feat(narrative): add cinematic map backdrop preview model, tests, and roadmap updates (NS-SCENES-V1-83)
c76550a6 feat(narrative): update cinematic workspaces, tests, and roadmap reports (NS-SCENES-V1-82)
e32d5f2a update screenshot failures for ns_scenes_v1_29_storyline_step_scene_link_v0
1b311e81 feat(narrative): update cinematic workspace and add test failure assets (NS-SCENES-V1-29-81)
122fe0c7 feat(narrative): update cinematic builder workspace (NS-SCENES-V1-81-BIS)
747aa6e6 feat(narrative): add cinematic builder workspace updates and test failure assets (NS-SCENES-V1-35)
2da49606 feat(narrative): add cinematic actor appearance readiness drift diagnostics polish v0 (NS-SCENES-V1-81)
eea6dbff feat(narrative): add cinematic character library picker v0 (NS-SCENES-V1-80)
eb7d47aa feat(narrative): add cinematic character library binding core model v0 (NS-SCENES-V1-79)
92a6c95e feat(narrative): add cinematic character library binding prep contract (NS-SCENES-V1-78)
d5113ec2 feat(narrative): add cinematic stage map entity event pickers v0 (NS-SCENES-V1-77)
01a69fdd feat(narrative): add cinematic stage map source catalog v0 (NS-SCENES-V1-76)
bea04114 feat(narrative): add cinematic map entity event source audit picker prep contract (NS-SCENES-V1-75)
```

## 2. Sub-agents

Sub-agent A : audit `MapData`. Les coordonnees exploitables viennent de `TileLayer.tiles`, `TerrainLayer.terrains`, `PathLayer.cells`, `SurfaceLayer.placements`, `EnvironmentLayer.content.areas[].mask.cells` et `MapPlacedElement.pos`. `ObjectLayer` seul ne suffit pas sans placed element.

Sub-agent B : contrat pur `map_core`. Le read model doit exposer des primitives structurelles et garder les summaries pour les cas sans geometrie spatiale.

Sub-agent C : rendu editor. Le bon compromis est un mini `CustomPainter` dedie, pas `MapCanvas`, pas runtime, pas Flame.

Sub-agent D : tests. Couvrir RED/GREEN, exclusions, absence de fake tiles, fallback sans primitives et Visual Gate screenshot.

Sub-agent E : produit. V1-85 doit rendre une vraie structure spatiale proportionnelle, sinon le lot n'apporte rien par rapport a V1-84.

Arbitrage : primitives spatiales maintenant, rendu assets/tiles final plus tard. Prochain lot recommande : `NS-SCENES-V1-86 — Cinematic Actor Display Preview Prep Contract`.

## 3. TDD RED/GREEN

### Core RED

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart --plain-name 'builds visual primitives from positioned MapData layers'

Resultat : exit 1
Signal : failed to load, `CinematicMapBackdropVisualPrimitiveKind` et getter `visualPrimitives` non definis.
```

### Core GREEN

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart --plain-name 'builds visual primitives from positioned MapData layers'

Resultat : exit 0
+1: All tests passed!
```

### Object anchor RED

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart --plain-name 'builds object anchors only from placed element coordinates'

Resultat : exit 1
Signal : expected `objectAnchor`, actual `layerSummary`.
```

### Object anchor GREEN

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart --plain-name 'builds object anchors only from placed element coordinates'

Resultat : exit 0
+1: All tests passed!
```

### Editor RED

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'

Resultat : exit 1
Signal : expected key `cinematic-builder-map-backdrop-visual-primitives`, found 0.
```

### Editor GREEN

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'

Resultat : exit 0
+1: All tests passed!
```

## 4. Commandes de verification

### Format

```text
cd packages/map_core && dart format lib/src/read_models/cinematic_map_backdrop_preview_model.dart test/cinematic_map_backdrop_preview_model_test.dart

cd packages/map_editor && dart format lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
```

### Core

```text
cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
Resultat : exit 0
+19: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_stage_map_source_catalog_test.dart
Resultat : exit 0
+7: All tests passed!

cd packages/map_core && dart test --reporter=compact test/cinematic_asset_test.dart
Resultat : exit 0
+14: All tests passed!

cd packages/map_core && dart test --reporter=compact test/project_manifest_cinematics_test.dart
Resultat : exit 0
+9: All tests passed!

cd packages/map_core && dart analyze
Resultat : exit 0
No issues found!
```

### Editor

```text
cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'shows honest structural fallback when no spatial primitives exist'
Resultat : exit 0
+1: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart --plain-name 'wires loaded stage map snapshot into static backdrop preview'
Resultat : exit 0
+1: All tests passed!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Resultat : exit 0
No issues found!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart
Resultat : exit 0
00:21 +150: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematics_library_workspace_test.dart
Resultat : exit 0
+15: All tests passed!
```

Note : une execution Flutter parallele a echoue au demarrage natif avec `Failed to get the install name of LocalFile ... objective_c.dylib`. La commande concernee a ete relancee sequentiellement et a passe.

### Visual Gate

```text
cd packages/map_editor && flutter test --update-goldens --dart-define=NS_SCENES_V1_85_CAPTURE_CINEMATIC_MAP_BACKDROP_VISUAL_PRIMITIVES=true --reporter=compact test/cinematic_builder_workspace_test.dart
Resultat : exit 0
00:25 +150: All tests passed!

ls -lh reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png
-rw-r--r-- 1 karim staff 255K Jun 6 03:19 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png

file reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png
PNG image data, 1663 x 926, 8-bit/color RGBA, non-interlaced

shasum -a 256 reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png
1f24ba63853d3f6ce69c17f0e30111127ddcb0072a5c5699d732aa4b53c6fc57
```

## 5. Analyse globale editor

```text
cd packages/map_editor && flutter analyze
Resultat : exit 1
344 issues
```

Premiers signaux : dette preexistante Pokemon SDK hors lot, notamment :

```text
lib/src/application/services/pokemon_sdk_move_catalog_converter.dart
undefined named parameter `dbSymbol`
undefined named parameter `battleEngineAimedTarget`
undefined named parameter `battleEngineMethod`
undefined class `PokemonMoveAimedTarget`
undefined class `PokemonMoveFlags`
undefined class `PokemonMoveBattleStageMod`
undefined class `PokemonMoveStatus`

lib/src/application/use_cases/sync_pokemon_sdk_moves_catalog_use_case.dart
undefined method `fetchPokemonSdkStudioProjectPayload`
```

Analyse ciblee V1-85 : verte.

## 6. Checks anti-scope

```text
git diff --name-only -- packages/map_runtime packages/map_gameplay packages/map_battle examples selbrume
<vide>

rg -n "package:flame|GameWidget|FlameGame|PlayableMapGame|RuntimeMapGame|CameraComponent|Component|GameState|SceneCinematicRuntimeAwaitableAdapter|map_runtime" <fichiers V1-85>
<vide>

rg -n "startPlayback|stopPlayback|playbackTimeMs|currentTimeMs|isPlaying|Timer\\(|Ticker|AnimationController|seek|scrub|scrubber" <fichiers V1-85>
packages/map_editor/test/cinematic_builder_workspace_test.dart:3838:    expect(find.text('seek'), findsNothing);
packages/map_editor/test/cinematic_builder_workspace_test.dart:3839:    expect(find.text('scrub'), findsNothing);

rg -n "PlayerComponent|OverworldActorComponent|CharacterSprite|ActorSprite|renderActor|drawActor|actorRenderer|sprite actor|CharacterAnimation" <fichiers V1-85>
packages/map_editor/test/cinematic_builder_workspace_test.dart:1379...
packages/map_editor/test/cinematic_builder_workspace_test.dart:1551...

rg -n "fakeMap|fakeTile|mockTile|hardcoded.*map|Selbrume|bourg_selbrume|port_brisants|lysa|mael|maël" <fichiers V1-85>
<vide>

rg -n "Color\\(0x|Colors\\." packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart packages/map_editor/test/cinematic_builder_workspace_test.dart packages/map_editor/test/cinematics_library_workspace_test.dart
<vide>

rg -n "MapCanvas|map_canvas|surface_layer_static_preview|PlayableMapGame|RuntimeMapGame" packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart
<vide>
```

Les sorties actor/stageContext/playback non vides correspondent a des assertions ou fixtures historiques de tests, pas a un nouveau rendu d'acteurs, un runtime ou un playback.

## 7. Fichiers crees

```text
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart
reports/narrativeStudio/scenes/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.md
reports/narrativeStudio/scenes/ns_scenes_v1_85_evidence_pack.md
reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png
```

## 8. Fichiers modifies

```text
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scenes.md
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
```

## 9. Code genere — painter complet

```dart
import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:map_core/map_core.dart';

class CinematicMapBackdropPrimitivePalette {
  const CinematicMapBackdropPrimitivePalette({
    required this.background,
    required this.border,
    required this.grid,
    required this.tile,
    required this.terrain,
    required this.path,
    required this.surface,
    required this.object,
    required this.environment,
    required this.summary,
  });

  final Color background;
  final Color border;
  final Color grid;
  final Color tile;
  final Color terrain;
  final Color path;
  final Color surface;
  final Color object;
  final Color environment;
  final Color summary;
}

class CinematicMapBackdropVisualPrimitivesPainter extends CustomPainter {
  const CinematicMapBackdropVisualPrimitivesPainter({
    required this.mapWidth,
    required this.mapHeight,
    required this.primitives,
    required this.palette,
  });

  final int mapWidth;
  final int mapHeight;
  final List<CinematicMapBackdropVisualPrimitive> primitives;
  final CinematicMapBackdropPrimitivePalette palette;

  @override
  void paint(Canvas canvas, Size size) {
    if (mapWidth <= 0 || mapHeight <= 0 || size.isEmpty) {
      return;
    }

    final frame = _fittedMapRect(size);
    final background = Paint()
      ..color = palette.background
      ..style = PaintingStyle.fill;
    final border = Paint()
      ..color = palette.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas
      ..drawRect(frame, background)
      ..drawRect(frame, border);

    _paintGrid(canvas, frame);
    for (final primitive
        in primitives.where((primitive) => primitive.visible)) {
      _paintPrimitive(canvas, frame, primitive);
    }
  }

  Rect _fittedMapRect(Size size) {
    final horizontalScale = size.width / mapWidth;
    final verticalScale = size.height / mapHeight;
    final scale = math.min(horizontalScale, verticalScale);
    final width = mapWidth * scale;
    final height = mapHeight * scale;
    return Rect.fromLTWH(
      (size.width - width) / 2,
      (size.height - height) / 2,
      width,
      height,
    );
  }

  void _paintGrid(Canvas canvas, Rect frame) {
    final cellWidth = frame.width / mapWidth;
    final cellHeight = frame.height / mapHeight;
    final grid = Paint()
      ..color = palette.grid
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    if (cellWidth >= 6) {
      for (var x = 1; x < mapWidth; x++) {
        final dx = frame.left + x * cellWidth;
        canvas.drawLine(Offset(dx, frame.top), Offset(dx, frame.bottom), grid);
      }
    }
    if (cellHeight >= 6) {
      for (var y = 1; y < mapHeight; y++) {
        final dy = frame.top + y * cellHeight;
        canvas.drawLine(Offset(frame.left, dy), Offset(frame.right, dy), grid);
      }
    }
  }

  void _paintPrimitive(
    Canvas canvas,
    Rect frame,
    CinematicMapBackdropVisualPrimitive primitive,
  ) {
    final rect = _primitiveRect(frame, primitive);
    final opacity = primitive.opacity.clamp(0.16, 1.0).toDouble();
    final color = _colorFor(primitive.kind).withValues(alpha: 0.62 * opacity);
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    switch (primitive.kind) {
      case CinematicMapBackdropVisualPrimitiveKind.objectAnchor:
      case CinematicMapBackdropVisualPrimitiveKind.environmentAnchor:
        canvas.drawOval(
            rect.deflate(math.min(rect.width, rect.height) * 0.2), paint);
      case CinematicMapBackdropVisualPrimitiveKind.layerSummary:
      case CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer:
        final summaryPaint = Paint()
          ..color = _colorFor(primitive.kind).withValues(alpha: 0.16 * opacity)
          ..style = PaintingStyle.fill;
        canvas.drawRect(rect, summaryPaint);
        final outlinePaint = Paint()
          ..color = _colorFor(primitive.kind).withValues(alpha: 0.5 * opacity)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1;
        canvas.drawRect(rect.deflate(1), outlinePaint);
      case CinematicMapBackdropVisualPrimitiveKind.tileCell:
      case CinematicMapBackdropVisualPrimitiveKind.terrainCell:
      case CinematicMapBackdropVisualPrimitiveKind.pathCell:
      case CinematicMapBackdropVisualPrimitiveKind.surfaceCell:
        canvas.drawRect(rect.deflate(1), paint);
    }
  }

  Rect _primitiveRect(
    Rect frame,
    CinematicMapBackdropVisualPrimitive primitive,
  ) {
    final cellWidth = frame.width / mapWidth;
    final cellHeight = frame.height / mapHeight;
    return Rect.fromLTWH(
      frame.left + primitive.x * cellWidth,
      frame.top + primitive.y * cellHeight,
      math.max(cellWidth, cellWidth * primitive.width),
      math.max(cellHeight, cellHeight * primitive.height),
    );
  }

  Color _colorFor(CinematicMapBackdropVisualPrimitiveKind kind) {
    return switch (kind) {
      CinematicMapBackdropVisualPrimitiveKind.tileCell => palette.tile,
      CinematicMapBackdropVisualPrimitiveKind.terrainCell => palette.terrain,
      CinematicMapBackdropVisualPrimitiveKind.pathCell => palette.path,
      CinematicMapBackdropVisualPrimitiveKind.surfaceCell => palette.surface,
      CinematicMapBackdropVisualPrimitiveKind.objectAnchor => palette.object,
      CinematicMapBackdropVisualPrimitiveKind.environmentAnchor =>
        palette.environment,
      CinematicMapBackdropVisualPrimitiveKind.layerSummary ||
      CinematicMapBackdropVisualPrimitiveKind.unsupportedLayer =>
        palette.summary,
    };
  }

  @override
  bool shouldRepaint(
    covariant CinematicMapBackdropVisualPrimitivesPainter oldDelegate,
  ) {
    return oldDelegate.mapWidth != mapWidth ||
        oldDelegate.mapHeight != mapHeight ||
        oldDelegate.primitives != primitives ||
        oldDelegate.palette != palette;
  }
}
```

## 10. Code genere — contrat core principal

```dart
enum CinematicMapBackdropVisualPrimitiveKind {
  tileCell,
  terrainCell,
  pathCell,
  surfaceCell,
  objectAnchor,
  environmentAnchor,
  layerSummary,
  unsupportedLayer,
}

@immutable
final class CinematicMapBackdropVisualPrimitive {
  const CinematicMapBackdropVisualPrimitive({
    required this.id,
    required this.layerId,
    required this.layerLabel,
    required this.layerKind,
    required this.kind,
    required this.layerIndex,
    required this.localOrder,
    required this.visible,
    required this.opacity,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.label,
    required this.summary,
    required this.source,
  });

  final String id;
  final String layerId;
  final String layerLabel;
  final CinematicMapBackdropLayerKind layerKind;
  final CinematicMapBackdropVisualPrimitiveKind kind;
  final int layerIndex;
  final int localOrder;
  final bool visible;
  final double opacity;
  final int x;
  final int y;
  final int width;
  final int height;
  final String label;
  final String summary;
  final String source;
}
```

Projection ajoutee : `buildCinematicMapBackdropPreviewModel` remplit maintenant `mapWidth`, `mapHeight` et `visualPrimitives`, puis `_projectVisualPrimitives(MapData mapData)` derive les primitives depuis les layers et placed elements reels.

```dart
final layers = _projectVisualLayers(mapData);
final visualPrimitives = _projectVisualPrimitives(mapData);
```

Les branches de projection V1-85 couvrent `TileLayer`, `TerrainLayer`, `PathLayer`, `SurfaceLayer`, `ObjectLayer` via `mapData.placedElements`, et `EnvironmentLayer` via masks. `CollisionLayer` ne produit aucune primitive.

## 11. Code genere — bridge UI principal

```dart
return Stack(
  key: const ValueKey('cinematic-builder-map-backdrop-visual-primitives'),
  children: [
    Positioned.fill(
      child: ClipRect(
        child: CustomPaint(
          painter: CinematicMapBackdropVisualPrimitivesPainter(
            mapWidth: mapWidth,
            mapHeight: mapHeight,
            primitives: primitives,
            palette: palette,
          ),
          child: const SizedBox.expand(),
        ),
      ),
    ),
    Align(
      alignment: Alignment.topLeft,
      child: Wrap(
        spacing: 6,
        runSpacing: 5,
        children: [
          const PokeMapBadge(
            label: 'Aperçu spatial structurel',
            variant: PokeMapBadgeVariant.info,
          ),
          PokeMapBadge(
            label: '${primitives.length} primitive(s) spatiale(s)',
            variant: PokeMapBadgeVariant.mapAccent,
          ),
        ],
      ),
    ),
  ],
);
```

## 12. Screenshot

![V1-85 cinematic map backdrop visual primitives](/Users/karim/Project/pokemonProject/reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png)

## 13. Verification finale apres ajout des rapports

```text
git diff --check
Resultat : exit 0
<vide>

cd packages/map_core && dart test --reporter=compact test/cinematic_map_backdrop_preview_model_test.dart
Resultat : exit 0
00:00 +19: All tests passed!

cd packages/map_editor && flutter test --reporter=compact test/cinematic_builder_workspace_test.dart --plain-name 'renders static map backdrop preview when backdrop model is available'
Resultat : exit 0
00:02 +1: All tests passed!

cd packages/map_editor && flutter analyze --no-fatal-infos lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Resultat : exit 0
Analyzing 4 items...
No issues found! (ran in 1.2s)
```

## 14. Statut git final capture

```text
git status --short --untracked-files=all
 M packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
 M packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M packages/map_editor/test/cinematics_library_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_visual_primitives_painter.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_85_evidence_pack.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_85_cinematic_map_backdrop_visual_primitives_v0.png

git diff --stat
 .../cinematic_map_backdrop_preview_model.dart      | 342 +++++++++++++++++++++
 .../cinematic_map_backdrop_preview_model_test.dart | 134 ++++++++
 .../cinematic_map_backdrop_preview_panel.dart      | 260 +++++++++-------
 .../test/cinematic_builder_workspace_test.dart     | 111 ++++++-
 .../test/cinematics_library_workspace_test.dart    |  25 +-
 .../scenes/road_map_scene_builder_authoring.md     |  19 +-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 +-
 7 files changed, 793 insertions(+), 121 deletions(-)

git diff --name-only
packages/map_core/lib/src/read_models/cinematic_map_backdrop_preview_model.dart
packages/map_core/test/cinematic_map_backdrop_preview_model_test.dart
packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
packages/map_editor/test/cinematic_builder_workspace_test.dart
packages/map_editor/test/cinematics_library_workspace_test.dart
reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
reports/narrativeStudio/scenes/road_map_scenes.md
```

Note : `git diff --stat` et `git diff --name-only` listent seulement les fichiers suivis. Les nouveaux fichiers V1-85 sont visibles dans `git status --short --untracked-files=all`.
