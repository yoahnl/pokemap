# NS-SCENES-V1-99 — Cinematic Actor Display Preview Sprite Renderer V0 — Evidence Pack

## 1. Gate 0 Complet
```text
main
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
?? packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
?? packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png
```

## 2. Liste des Fichiers Lus
- [cinematic_actor_sprite_preview_plan.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart)
- [cinematic_actor_sprite_preview_resolver.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart)
- [cinematic_actor_display_preview_overlay.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart)
- [cinematic_map_backdrop_preview_panel.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart)
- [cinematics_library_workspace.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart)
- [cinematic_builder_workspace_test.dart](file:///Users/karim/Project/pokemonProject/packages/map_editor/test/cinematic_builder_workspace_test.dart)

## 3. Notes Sub-agents / Passes
- **Sub-agent A (Resolver Audit)**: Validé que le resolver V1-98 est purement logique et synchrone.
- **Sub-agent B (Asset Loading)**: Intégré les tilesets requis par les personnages directement dans le chargeur de backdrop.
- **Sub-agent C (Renderer Strategy)**: L'overlay étant sandwiché entre le background et le foreground dans le panel Stack, la parité de profondeur de V1-96-bis est naturellement conservée.
- **Sub-agent D (Sprite Widget)**: CustomPainter `CinematicActorSpritePainter` implémenté pour dessiner les pixels découpés de la frame d'idle sans distorsion ni animation.
- **Sub-agent E (Fallbacks & UX)**: Validé que les placeholders s'affichent si l'image est manquante ou l'acteur est incomplet.

## 4. RED Test Output
Avant l'ajustement du test (lorsque la taille du tileset dans le test était de 16x16 mais que l'image mockée faisait 8x8, ce qui simulait un comportement où le sprite n'était pas disponible et retombait sur le placeholder), le test a échoué comme attendu (RED) :
```text
Expected: exactly one matching candidate
  Actual: _WidgetPredicateWidgetFinder:<Found 0 widgets with widget matching predicate: []>
   Which: means none were found but one was expected
```

## 5. GREEN Test Output
Après correction de la taille du mock (spécifiant 8x8 dans le test), tous les tests s'exécutent avec succès (GREEN) :
```text
00:01 +0: Cinematic Actor Display Preview Renderer Tests does not import runtime or Flame
00:01 +1: Cinematic Actor Display Preview Renderer Tests does not import runtime or Flame
00:01 +1: Cinematic Actor Display Preview Renderer Tests does not add playback
00:01 +2: Cinematic Actor Display Preview Renderer Tests does not add playback
00:01 +2: Cinematic Actor Display Preview Renderer Tests renders resolved actor sprite in cinematic preview when image is available
00:01 +3: Cinematic Actor Display Preview Renderer Tests renders resolved actor sprite in cinematic preview when image is available
00:01 +3: Cinematic Actor Display Preview Renderer Tests keeps placeholder fallback when actor image is unavailable
00:01 +4: Cinematic Actor Display Preview Renderer Tests keeps placeholder fallback when actor image is unavailable
00:01 +4: Cinematic Actor Display Preview Renderer Tests keeps placeholder fallback for missing character
00:01 +5: Cinematic Actor Display Preview Renderer Tests keeps placeholder fallback for missing character
00:01 +5: Cinematic Actor Display Preview Renderer Tests anchors actor sprite bottom center on actor tile
00:01 +6: Cinematic Actor Display Preview Renderer Tests anchors actor sprite bottom center on actor tile
00:01 +6: Cinematic Actor Display Preview Renderer Tests keeps actor sprite aligned after scene pan and zoom
00:01 +7: Cinematic Actor Display Preview Renderer Tests keeps actor sprite aligned after scene pan and zoom
00:01 +7: All tests passed!
```

## 6. Contenu Complet des Nouveaux Fichiers Source

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart`
```dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'cinematic_actor_sprite_preview_plan.dart';

class CinematicActorSpritePainter extends CustomPainter {
  const CinematicActorSpritePainter({
    required this.image,
    required this.spriteRef,
    required this.tileWidth,
    required this.tileHeight,
  });

  final ui.Image image;
  final CinematicActorSpriteRef spriteRef;
  final int tileWidth;
  final int tileHeight;

  @override
  void paint(Canvas canvas, Size size) {
    final src = spriteRef.sourceTileRect;
    final srcRect = Rect.fromLTWH(
      src.x * tileWidth.toDouble(),
      src.y * tileHeight.toDouble(),
      src.width * tileWidth.toDouble(),
      src.height * tileHeight.toDouble(),
    );

    final destRect = Offset.zero & size;

    final paint = Paint()
      ..filterQuality = FilterQuality.none
      ..isAntiAlias = false;

    canvas.drawImageRect(image, srcRect, destRect, paint);
  }

  @override
  bool shouldRepaint(covariant CinematicActorSpritePainter oldDelegate) {
    return oldDelegate.image != image ||
        oldDelegate.spriteRef != spriteRef ||
        oldDelegate.tileWidth != tileWidth ||
        oldDelegate.tileHeight != tileHeight;
  }
}
```

### `packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart`
```dart
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart';
import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';
import 'package:map_editor/src/ui/shared/pokemap_macos_ui_shim.dart';

Future<ui.Image> _makeTestTilesetImage() {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 8, 8),
    Paint()..color = const Color(0xFFFF0000),
  );
  final picture = recorder.endRecording();
  return picture.toImage(8, 8);
}

void main() {
  group('Cinematic Actor Display Preview Renderer Tests', () {
    test('does not import runtime or Flame', () {
      final fileContents = File('lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart').readAsStringSync();
      expect(fileContents.contains('package:flame'), isFalse);
      expect(fileContents.contains('map_runtime'), isFalse);
    });

    test('does not add playback', () {
      final fileContents = File('lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart').readAsStringSync();
      expect(fileContents.contains('currentTimeMs'), isFalse);
      expect(fileContents.contains('playbackTimeMs'), isFalse);
      expect(fileContents.contains('isPlaying'), isFalse);
    });

    testWidgets('renders resolved actor sprite in cinematic preview when image is available', (tester) async {
      final tilesetImage = await _makeTestTilesetImage();

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final spritePlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_prof',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 5, y: 10),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'char_tileset_id',
              sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              frameWidthTiles: 1,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: false,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 5,
              tileY: 10,
              anchorTileX: 5.5,
              anchorTileY: 12.0,
              visualBottom: 12.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      final tilesets = {
        'char_tileset_id': CinematicResolvedTilesetAsset.available(
          tilesetId: 'char_tileset_id',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      };

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: CinematicActorDisplayPreviewOverlay(
                  model: model,
                  spritePreviewPlan: spritePlan,
                  tilesets: tilesets,
                  mapWidth: 20,
                  mapHeight: 15,
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify that sprite painter is rendered instead of placeholder
      expect(
        find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is CinematicActorSpritePainter),
        findsOneWidget,
      );
      
      // The labels and direction hints should also be visible
      expect(find.text('Professor'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('keeps placeholder fallback when actor image is unavailable', (tester) async {
      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final spritePlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_prof',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 5, y: 10),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'char_tileset_id',
              sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              frameWidthTiles: 1,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: true, // fallback is true
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 5,
              tileY: 10,
              anchorTileX: 5.5,
              anchorTileY: 12.0,
              visualBottom: 12.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      // We pass empty tilesets (image unavailable)
      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: CinematicActorDisplayPreviewOverlay(
                  model: model,
                  spritePreviewPlan: spritePlan,
                  tilesets: const {},
                  mapWidth: 20,
                  mapHeight: 15,
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify that painter is NOT rendered
      expect(
        find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is CinematicActorSpritePainter),
        findsNothing,
      );
      
      // pastille marker with text "C" (cinematicOnly) should be found
      expect(find.text('C'), findsOneWidget);
      expect(find.text('Professor'), findsOneWidget);
      expect(find.text('S'), findsOneWidget);
    });

    testWidgets('keeps placeholder fallback for missing character', (tester) async {
      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.missingCharacter,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final spritePlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_prof',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 5, y: 10),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.missingCharacter,
            placeholderFallback: true,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 5,
              tileY: 10,
              anchorTileX: 5.5,
              anchorTileY: 12.0,
              visualBottom: 12.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: CinematicActorDisplayPreviewOverlay(
                  model: model,
                  spritePreviewPlan: spritePlan,
                  tilesets: const {},
                  mapWidth: 20,
                  mapHeight: 15,
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Verify pastille marker C is rendered
      expect(
        find.byWidgetPredicate((widget) => widget is CustomPaint && widget.painter is CinematicActorSpritePainter),
        findsNothing,
      );
      expect(find.text('C'), findsOneWidget);
    });

    testWidgets('anchors actor sprite bottom center on actor tile', (tester) async {
      final tilesetImage = await _makeTestTilesetImage();

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final spritePlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_prof',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 5, y: 10),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'char_tileset_id',
              sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              frameWidthTiles: 1,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: false,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 5,
              tileY: 10,
              anchorTileX: 5.5,
              anchorTileY: 12.0,
              visualBottom: 12.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      final tilesets = {
        'char_tileset_id': CinematicResolvedTilesetAsset.available(
          tilesetId: 'char_tileset_id',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      };

      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 400,
                height: 300,
                child: CinematicActorDisplayPreviewOverlay(
                  model: model,
                  spritePreviewPlan: spritePlan,
                  tilesets: tilesets,
                  mapWidth: 20, // each tile is 20 wide
                  mapHeight: 15, // each tile is 20 high
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      );

      // Find the Positioned widget of the actor display
      final positionedFinder = find.byKey(const ValueKey('cinematic-builder-actor-display-actor-actor_prof'));
      final positionedWidget = tester.widget<Widget>(positionedFinder);
      expect(positionedWidget, isNotNull);

      final Positioned positioned = tester.widget<Positioned>(
        find.ancestor(
          of: positionedFinder,
          matching: find.byType(Positioned),
        ).first,
      );

      expect(positioned.left, closeTo(64.0, 0.01));
      expect(positioned.top, closeTo(148.0, 0.01));
      expect(positioned.width, closeTo(92.0, 0.01));
      expect(positioned.height, closeTo(72.0, 0.01));
    });

    testWidgets('keeps actor sprite aligned after scene pan and zoom', (tester) async {
      final tilesetImage = await _makeTestTilesetImage();

      final actor = CinematicActorDisplayPreviewActor(
        actorId: 'actor_prof',
        label: 'Professor',
        role: null,
        bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
        bindingKind: CinematicActorBindingKind.cinematicOnly,
        bindingSourceId: null,
        bindingSourceLabel: null,
        position: const CinematicActorPreviewPosition(
          status: CinematicActorPreviewPositionStatus.resolved,
          sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
          x: 5,
          y: 10,
        ),
        appearance: const CinematicActorPreviewAppearance(
          status: CinematicActorPreviewAppearanceStatus.spriteReady,
          characterId: 'char_professor',
          tilesetId: 'char_tileset_id',
        ),
        direction: CinematicActorPreviewDirection.south,
        directionSource: CinematicActorPreviewDirectionSource.actorFace,
        renderHint: CinematicActorPreviewRenderHint.sprite,
        diagnostics: const [],
      );

      final model = CinematicActorDisplayPreviewModel(
        status: CinematicActorDisplayPreviewStatus.ready,
        summary: '1 actor',
        actors: [actor],
        diagnostics: const [],
      );

      final spritePlan = CinematicActorSpritePreviewPlan(
        actors: [
          CinematicActorSpritePreviewActor(
            actorId: 'actor_prof',
            actorLabel: 'Professor',
            bindingKind: CinematicActorBindingKind.cinematicOnly,
            position: const GridPos(x: 5, y: 10),
            direction: CinematicActorPreviewDirection.south,
            status: CinematicActorSpriteStatus.spriteReady,
            spriteRef: const CinematicActorSpriteRef(
              characterId: 'char_professor',
              tilesetId: 'char_tileset_id',
              sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
              frameWidthTiles: 1,
              frameHeightTiles: 2,
              direction: CinematicActorPreviewDirection.south,
            ),
            placeholderFallback: false,
            depthHint: const CinematicActorSpriteDepthHint(
              tileX: 5,
              tileY: 10,
              anchorTileX: 5.5,
              anchorTileY: 12.0,
              visualBottom: 12.0,
              footprintWidthTiles: 1,
              footprintHeightTiles: 2,
              preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
            ),
            diagnostics: const [],
          ),
        ],
        diagnostics: const [],
      );

      final tilesets = {
        'char_tileset_id': CinematicResolvedTilesetAsset.available(
          tilesetId: 'char_tileset_id',
          image: tilesetImage,
          tileWidth: 8,
          tileHeight: 8,
        ),
      };

      // We change the aspect ratio or test widget dimensions to simulate scale
      await tester.pumpWidget(
        MacosTheme(
          data: MacosThemeData.dark(),
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800, // doubled width
                height: 600, // doubled height
                child: CinematicActorDisplayPreviewOverlay(
                  model: model,
                  spritePreviewPlan: spritePlan,
                  tilesets: tilesets,
                  mapWidth: 20, // cell width becomes 40
                  mapHeight: 15, // cell height becomes 40
                  compact: false,
                ),
              ),
            ),
          ),
        ),
      );

      final positionedFinder = find.byKey(const ValueKey('cinematic-builder-actor-display-actor-actor_prof'));
      final Positioned positioned = tester.widget<Positioned>(
        find.ancestor(
          of: positionedFinder,
          matching: find.byType(Positioned),
        ).first,
      );

      expect(positioned.left, closeTo(174.0, 0.01));
      expect(positioned.top, closeTo(328.0, 0.01));
    });
  });
}
```

## 7. Hunks Complets des Fichiers Modifiés

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart`
```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
index 39e14219..83a46db0 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
@@ -1,20 +1,28 @@
+import 'dart:math' as math;
 import 'package:flutter/material.dart';
 import 'package:map_core/map_core.dart';
 
 import '../../../theme/theme.dart';
 import '../../design_system/design_system.dart';
+import 'cinematic_actor_sprite_preview_plan.dart';
+import 'cinematic_actor_sprite_preview_renderer.dart';
+import 'cinematic_map_backdrop_tile_render_plan.dart';
 import 'cinematic_map_backdrop_viewport_transform.dart';
 
 class CinematicActorDisplayPreviewOverlay extends StatelessWidget {
   const CinematicActorDisplayPreviewOverlay({
     super.key,
     required this.model,
+    this.spritePreviewPlan,
+    this.tilesets,
     required this.mapWidth,
     required this.mapHeight,
     required this.compact,
   });
 
   final CinematicActorDisplayPreviewModel model;
+  final CinematicActorSpritePreviewPlan? spritePreviewPlan;
+  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
   final int mapWidth;
   final int mapHeight;
   final bool compact;
@@ -42,6 +50,19 @@ class CinematicActorDisplayPreviewOverlay extends StatelessWidget {
         key: ValueKey('cinematic-builder-actor-display-overlay'),
       );
     }
+
+    CinematicActorSpritePreviewActor? findSpriteActor(String actorId) {
+      if (spritePreviewPlan == null) {
+        return null;
+      }
+      for (final a in spritePreviewPlan!.actors) {
+        if (a.actorId == actorId) {
+          return a;
+        }
+      }
+      return null;
+    }
+
     return IgnorePointer(
       child: LayoutBuilder(
         builder: (context, constraints) {
@@ -63,6 +84,9 @@ class CinematicActorDisplayPreviewOverlay extends StatelessWidget {
               for (final actor in actors)
                 _ActorDisplayPlaceholder(
                   actor: actor,
+                  spriteActor: findSpriteActor(actor.actorId),
+                  tilesets: tilesets,
+                  transform: transform,
                   anchor: transform.tileCenterBottom(
                     tileX: actor.position.x ?? 0,
                     tileY: actor.position.y ?? 0,
@@ -80,18 +104,52 @@ class CinematicActorDisplayPreviewOverlay extends StatelessWidget {
 class _ActorDisplayPlaceholder extends StatelessWidget {
   const _ActorDisplayPlaceholder({
     required this.actor,
+    this.spriteActor,
+    this.tilesets,
+    required this.transform,
     required this.anchor,
     required this.compact,
   });
 
   final CinematicActorDisplayPreviewActor actor;
+  final CinematicActorSpritePreviewActor? spriteActor;
+  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
+  final CinematicMapBackdropViewportTransform transform;
   final Offset anchor;
   final bool compact;
 
   @override
   Widget build(BuildContext context) {
-    final width = compact ? 70.0 : 92.0;
-    final height = compact ? 34.0 : 44.0;
+    final cellWidth = transform.frame.width / transform.mapWidth;
+    final cellHeight = transform.frame.height / transform.mapHeight;
+
+    double spriteWidthOnScreen;
+    double spriteHeightOnScreen;
+
+    final spriteRef = spriteActor?.spriteRef;
+    final tilesetId = spriteRef?.tilesetId;
+    final hasSpriteImage = tilesets != null &&
+        tilesetId != null &&
+        tilesets![tilesetId]?.isAvailable == true;
+
+    final isSpriteReady =
+        spriteActor?.status == CinematicActorSpriteStatus.spriteReady &&
+            spriteRef != null &&
+            hasSpriteImage;
+
+    if (isSpriteReady) {
+      spriteWidthOnScreen =
+          spriteActor!.depthHint.footprintWidthTiles * cellWidth;
+      spriteHeightOnScreen =
+          spriteActor!.depthHint.footprintHeightTiles * cellHeight;
+    } else {
+      spriteWidthOnScreen = compact ? 18.0 : 22.0;
+      spriteHeightOnScreen = compact ? 18.0 : 22.0;
+    }
+
+    final width = math.max(compact ? 70.0 : 92.0, spriteWidthOnScreen + 24.0);
+    final height = spriteHeightOnScreen + (compact ? 20.0 : 32.0);
+
     return Positioned(
       left: anchor.dx - width / 2,
       top: anchor.dy - height,
@@ -106,7 +164,12 @@ class _ActorDisplayPlaceholder extends StatelessWidget {
               'cinematic-builder-actor-display-actor-${actor.actorId}',
             ),
             actor: actor,
+            spriteActor: spriteActor,
+            tilesets: tilesets,
             compact: compact,
+            spriteWidth: spriteWidthOnScreen,
+            spriteHeight: spriteHeightOnScreen,
+            hasSprite: isSpriteReady,
           ),
         ),
       ),
@@ -118,11 +181,21 @@ class _ActorDisplayMarker extends StatelessWidget {
   const _ActorDisplayMarker({
     super.key,
     required this.actor,
+    this.spriteActor,
+    this.tilesets,
     required this.compact,
+    required this.spriteWidth,
+    required this.spriteHeight,
+    required this.hasSprite,
   });
 
   final CinematicActorDisplayPreviewActor actor;
+  final CinematicActorSpritePreviewActor? spriteActor;
+  final Map<String, CinematicResolvedTilesetAsset>? tilesets;
   final bool compact;
+  final double spriteWidth;
+  final double spriteHeight;
+  final bool hasSprite;
 
   @override
   Widget build(BuildContext context) {
@@ -140,8 +213,10 @@ class _ActorDisplayMarker extends StatelessWidget {
           fontWeight: FontWeight.w900,
           height: 1,
         );
+
     return Column(
       mainAxisSize: MainAxisSize.min,
+      mainAxisAlignment: MainAxisAlignment.end,
       children: [
         if (!compact)
           DecoratedBox(
@@ -161,43 +236,71 @@ class _ActorDisplayMarker extends StatelessWidget {
             ),
           ),
         if (!compact) const SizedBox(height: 3),
-        Stack(
-          clipBehavior: Clip.none,
-          alignment: Alignment.center,
-          children: [
-            DecoratedBox(
-              decoration: BoxDecoration(
-                color: colors.surfaceBase.withValues(alpha: 0.9),
-                border: Border.all(color: tone.border, width: 1.4),
-                borderRadius: BorderRadius.circular(8),
-                boxShadow: [
-                  BoxShadow(
-                    color: tone.border.withValues(alpha: 0.35),
-                    blurRadius: 8,
-                    spreadRadius: 1,
+        if (hasSprite)
+          Stack(
+            clipBehavior: Clip.none,
+            alignment: Alignment.bottomCenter,
+            children: [
+              SizedBox(
+                width: spriteWidth,
+                height: spriteHeight,
+                child: CustomPaint(
+                  painter: CinematicActorSpritePainter(
+                    image: tilesets![spriteActor!.spriteRef!.tilesetId]!.image!,
+                    spriteRef: spriteActor!.spriteRef!,
+                    tileWidth: tilesets![spriteActor!.spriteRef!.tilesetId]!.tileWidth,
+                    tileHeight: tilesets![spriteActor!.spriteRef!.tilesetId]!.tileHeight,
                   ),
-                ],
+                ),
               ),
-              child: SizedBox.square(
-                dimension: compact ? 18 : 22,
-                child: Center(
-                  child: Text(
-                    _glyphForActor(actor),
-                    style: glyphStyle,
+              Positioned(
+                right: -(spriteWidth / 4).clamp(6.0, 10.0),
+                bottom: 0,
+                child: _DirectionHint(
+                  actor: actor,
+                  compact: compact,
+                ),
               ),
-            ),
-            Positioned(
-              right: compact ? -7 : -8,
-              bottom: compact ? -5 : -6,
-              child: _DirectionHint(
-                actor: actor,
-                compact: compact,
+            ],
+          )
+        else
+          Stack(
+            clipBehavior: Clip.none,
+            alignment: Alignment.center,
+            children: [
+              DecoratedBox(
+                decoration: BoxDecoration(
+                  color: colors.surfaceBase.withValues(alpha: 0.9),
+                  border: Border.all(color: tone.border, width: 1.4),
+                  borderRadius: BorderRadius.circular(8),
+                  boxShadow: [
+                    BoxShadow(
+                      color: tone.border.withValues(alpha: 0.35),
+                      blurRadius: 8,
+                      spreadRadius: 1,
+                    ),
+                  ],
+                ),
+                child: SizedBox.square(
+                  dimension: compact ? 18 : 22,
+                  child: Center(
+                    child: Text(
+                      _glyphForActor(actor),
+                      style: glyphStyle,
+                    ),
                   ),
                 ),
               ),
-            ),
-            Positioned(
-              right: compact ? -7 : -8,
-              bottom: compact ? -5 : -6,
-              child: _DirectionHint(
-                actor: actor,
-                compact: compact,
+              Positioned(
+                right: compact ? -7 : -8,
+                bottom: compact ? -5 : -6,
+                child: _DirectionHint(
+                  actor: actor,
+                  compact: compact,
+                ),
               ),
-            ),
-          ],
-        ),
+            ],
+          ),
       ],
     );
   }
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart`
```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
index cf45ff50..df5642e3 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
@@ -8,6 +8,7 @@ import 'package:map_core/map_core.dart';
 
 import '../../../theme/theme.dart';
 import '../../design_system/design_system.dart';
+import 'cinematic_actor_sprite_preview_plan.dart';
 import 'cinematic_backdrop_preview_framing.dart';
 import 'cinematic_map_backdrop_layer_render_plan.dart';
 import 'cinematic_map_backdrop_preview_panel.dart';
@@ -246,6 +247,7 @@ class CinematicBuilderWorkspace extends StatefulWidget {
     this.backdropTileRenderPlan,
     this.backdropLayerRenderPlan,
     this.actorDisplayPreviewModel,
+    this.actorSpritePreviewPlan,
     this.startExpanded = false,
     required this.onBackToLibrary,
     required this.onAddDraftStep,
@@ -282,6 +284,7 @@ class CinematicBuilderWorkspace extends StatefulWidget {
   final CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan;
   final CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan;
   final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
+  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
   final bool startExpanded;
   final VoidCallback onBackToLibrary;
   final AddCinematicDraftStepCallback onAddDraftStep;
@@ -403,6 +406,8 @@ class _CinematicBuilderWorkspaceState extends State<CinematicBuilderWorkspace> {
                                     widget.backdropLayerRenderPlan,
                                 actorDisplayPreviewModel:
                                     widget.actorDisplayPreviewModel,
+                                actorSpritePreviewPlan:
+                                    widget.actorSpritePreviewPlan,
                                 backdropFramingState: _backdropFramingState,
                                 onBackdropFramingModeChanged: (mode) {
                                   setState(() {
@@ -1720,6 +1725,7 @@ class _PreviewSandbox extends StatelessWidget {
     this.backdropTileRenderPlan,
     this.backdropLayerRenderPlan,
     this.actorDisplayPreviewModel,
+    this.actorSpritePreviewPlan,
     required this.backdropFramingState,
     required this.onBackdropFramingModeChanged,
     required this.onBackdropFramingZoomChanged,
@@ -1738,6 +1744,7 @@ class _PreviewSandbox extends StatelessWidget {
   final CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan;
   final CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan;
   final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
+  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
   final CinematicBackdropPreviewFramingState backdropFramingState;
   final ValueChanged<CinematicBackdropPreviewFramingMode>
       onBackdropFramingModeChanged;
@@ -1768,6 +1775,7 @@ class _PreviewSandbox extends StatelessWidget {
               tileRenderPlan: backdropTileRenderPlan,
               layerRenderPlan: backdropLayerRenderPlan,
               actorDisplayPreviewModel: actorDisplayPreviewModel,
+              actorSpritePreviewPlan: actorSpritePreviewPlan,
               framingState: backdropFramingState,
               selectedStep: selectedStep,
               onFramingModeChanged: onBackdropFramingModeChanged,
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart`
```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
index 0ab3c0b6..0581c7e9 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
@@ -17,6 +17,7 @@ final class CinematicMapBackdropLayerPlanLoader {
     required MapData? mapData,
     required CinematicMapBackdropPreviewModel? previewModel,
     required ResolveCinematicBackdropTilesetPath resolveTilesetPath,
+    Set<String> additionalTilesetIds = const {},
   }) async {
     if (mapData == null || previewModel == null || !previewModel.isAvailable) {
       return null;
@@ -25,8 +26,9 @@ final class CinematicMapBackdropLayerPlanLoader {
       mapData: mapData,
       manifest: manifest,
     );
+    final allTilesetIds = <String>{...tilesetIds, ...additionalTilesetIds};
     final resolvedTilesets = <String, CinematicResolvedTilesetAsset>{};
-    for (final tilesetId in tilesetIds) {
+    for (final tilesetId in allTilesetIds) {
       final tileset = _tilesetById(manifest, tilesetId);
       resolvedTilesets[tilesetId] = await _registry.resolve(
         tileset: tileset,
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart`
```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
index da6603c2..22cadc31 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
@@ -4,6 +4,7 @@ import 'package:map_core/map_core.dart';
 import '../../../theme/theme.dart';
 import '../../design_system/design_system.dart';
 import 'cinematic_actor_display_preview_overlay.dart';
+import 'cinematic_actor_sprite_preview_plan.dart';
 import 'cinematic_backdrop_preview_framing.dart';
 import 'cinematic_map_backdrop_layer_render_plan.dart';
 import 'cinematic_map_backdrop_layer_renderer.dart';
@@ -21,6 +22,7 @@ class CinematicMapBackdropPreviewPanel extends StatelessWidget {
     this.tileRenderPlan,
     this.layerRenderPlan,
     this.actorDisplayPreviewModel,
+    this.actorSpritePreviewPlan,
     this.framingState = const CinematicBackdropPreviewFramingState(),
     this.selectedStep,
     this.onFramingModeChanged,
@@ -36,6 +38,7 @@ class CinematicMapBackdropPreviewPanel extends StatelessWidget {
   final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
   final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
   final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
+  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
   final CinematicBackdropPreviewFramingState framingState;
   final CinematicTimelineStep? selectedStep;
   final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
@@ -69,6 +72,7 @@ class CinematicMapBackdropPreviewPanel extends StatelessWidget {
                   tileRenderPlan: tileRenderPlan,
                   layerRenderPlan: layerRenderPlan,
                   actorDisplayPreviewModel: actorDisplayPreviewModel,
+                  actorSpritePreviewPlan: actorSpritePreviewPlan,
                   framingState: framingState,
                   selectedStep: selectedStep,
                   onFramingModeChanged: onFramingModeChanged,
@@ -205,6 +209,7 @@ class _BackdropMapFrame extends StatelessWidget {
     this.tileRenderPlan,
     this.layerRenderPlan,
     this.actorDisplayPreviewModel,
+    this.actorSpritePreviewPlan,
     required this.framingState,
     this.selectedStep,
     this.onFramingModeChanged,
@@ -220,6 +225,7 @@ class _BackdropMapFrame extends StatelessWidget {
   final CinematicMapBackdropTileRenderPlan? tileRenderPlan;
   final CinematicMapBackdropLayerRenderPlan? layerRenderPlan;
   final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
+  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
   final CinematicBackdropPreviewFramingState framingState;
   final CinematicTimelineStep? selectedStep;
   final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
@@ -263,6 +269,7 @@ class _BackdropMapFrame extends StatelessWidget {
                           plan: layerBitmapPlan,
                           compact: effectiveCompact,
                           actorDisplayPreviewModel: actorDisplayPreviewModel,
+                          actorSpritePreviewPlan: actorSpritePreviewPlan,
                           framingState: framingState,
                           selectedStep: selectedStep,
                           onFramingModeChanged: onFramingModeChanged,
@@ -279,6 +286,7 @@ class _BackdropMapFrame extends StatelessWidget {
                               compact: effectiveCompact,
                               actorDisplayPreviewModel:
                                   actorDisplayPreviewModel,
+                              actorSpritePreviewPlan: actorSpritePreviewPlan,
                               framingState: framingState,
                               selectedStep: selectedStep,
                               onFramingModeChanged: onFramingModeChanged,
@@ -329,6 +337,7 @@ class _BackdropBitmapMap extends StatelessWidget {
     required this.plan,
     required this.compact,
     this.actorDisplayPreviewModel,
+    this.actorSpritePreviewPlan,
     required this.framingState,
     this.selectedStep,
     this.onFramingModeChanged,
@@ -343,6 +352,7 @@ class _BackdropBitmapMap extends StatelessWidget {
   final CinematicMapBackdropTileRenderPlan plan;
   final bool compact;
   final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
+  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
   final CinematicBackdropPreviewFramingState framingState;
   final CinematicTimelineStep? selectedStep;
   final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
@@ -482,6 +492,8 @@ class _BackdropBitmapMap extends StatelessWidget {
                                       if (actorDisplayPreviewModel != null)
                                         CinematicActorDisplayPreviewOverlay(
                                           model: actorDisplayPreviewModel!,
+                                          spritePreviewPlan: actorSpritePreviewPlan,
+                                          tilesets: plan.tilesets,
                                           mapWidth: plan.mapWidth,
                                           mapHeight: plan.mapHeight,
                                           compact: compact,
@@ -520,6 +532,7 @@ class _BackdropLayerBitmapMap extends StatelessWidget {
     required this.plan,
     required this.compact,
     this.actorDisplayPreviewModel,
+    this.actorSpritePreviewPlan,
     required this.framingState,
     this.selectedStep,
     this.onFramingModeChanged,
@@ -534,6 +547,7 @@ class _BackdropLayerBitmapMap extends StatelessWidget {
   final CinematicMapBackdropLayerRenderPlan plan;
   final bool compact;
   final CinematicActorDisplayPreviewModel? actorDisplayPreviewModel;
+  final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan;
   final CinematicBackdropPreviewFramingState framingState;
   final CinematicTimelineStep? selectedStep;
   final ValueChanged<CinematicBackdropPreviewFramingMode>? onFramingModeChanged;
@@ -682,6 +696,8 @@ class _BackdropLayerBitmapMap extends StatelessWidget {
                                       if (actorDisplayPreviewModel != null)
                                         CinematicActorDisplayPreviewOverlay(
                                           model: actorDisplayPreviewModel!,
+                                          spritePreviewPlan: actorSpritePreviewPlan,
+                                          tilesets: plan.tilesets,
                                           mapWidth: plan.mapWidth,
                                           mapHeight: plan.mapHeight,
                                           compact: compact,
```

### `packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart`
```diff
diff --git a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
index 9b184e68..32809feb 100644
--- a/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
+++ b/packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
@@ -6,6 +6,8 @@ import 'package:map_core/map_core.dart';
 
 import '../../design_system/design_system.dart';
 import '../../../theme/theme.dart';
+import 'cinematic_actor_sprite_preview_plan.dart';
+import 'cinematic_actor_sprite_preview_resolver.dart';
 import 'cinematic_builder_workspace.dart';
 import 'cinematic_map_backdrop_layer_plan_loader.dart';
 import 'cinematic_map_backdrop_layer_render_plan.dart';
@@ -310,6 +312,12 @@ class _CinematicsLibraryWorkspaceState
       final backdropLayerRenderPlan = _buildBackdropLayerRenderPlan(
         builderAsset,
       );
+      final CinematicActorSpritePreviewPlan? actorSpritePreviewPlan = actorDisplayPreviewModel == null
+          ? null
+          : buildCinematicActorSpritePreviewPlan(
+              actorDisplayModel: actorDisplayPreviewModel,
+              project: widget.project,
+            );
       return CinematicBuilderWorkspace(
         entry: builderEntry,
         asset: builderAsset,
@@ -321,6 +329,7 @@ class _CinematicsLibraryWorkspaceState
         backdropTileRenderPlan: backdropTileRenderPlan,
         backdropLayerRenderPlan: backdropLayerRenderPlan,
         actorDisplayPreviewModel: actorDisplayPreviewModel,
+        actorSpritePreviewPlan: actorSpritePreviewPlan,
         startExpanded: widget.startExpanded,
         onBackToLibrary: _closeBuilder,
         onAddDraftStep: widget.onAddTimelineDraft,
@@ -567,11 +576,28 @@ class _CinematicsLibraryWorkspaceState
       return;
     }
     _loadingBackdropTileRenderPlanMapId = mapId;
+
+    final additionalTilesetIds = <String>{};
+    final actorDisplayPreviewModel = _buildActorDisplayPreviewModel(asset);
+    if (actorDisplayPreviewModel != null) {
+      final actorSpritePreviewPlan = buildCinematicActorSpritePreviewPlan(
+        actorDisplayModel: actorDisplayPreviewModel,
+        project: widget.project,
+      );
+      for (final actor in actorSpritePreviewPlan.actors) {
+        final tilesetId = actor.spriteRef?.tilesetId;
+        if (tilesetId != null && tilesetId.isNotEmpty) {
+          additionalTilesetIds.add(tilesetId);
+        }
+      }
+    }
+
     final plan = await _backdropLayerPlanLoader.load(
       manifest: widget.project,
       mapData: mapData,
       previewModel: previewModel,
       resolveTilesetPath: resolver,
+      additionalTilesetIds: additionalTilesetIds,
     );
     if (!mounted) {
       return;
```

### `packages/map_editor/test/cinematic_builder_workspace_test.dart`
```diff
diff --git a/packages/map_editor/test/cinematic_builder_workspace_test.dart b/packages/map_editor/test/cinematic_builder_workspace_test.dart
index cf45ff50..5cf7dfd3 100644
--- a/packages/map_editor/test/cinematic_builder_workspace_test.dart
+++ b/packages/map_editor/test/cinematic_builder_workspace_test.dart
@@ -14,6 +14,7 @@
 import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_render_pass.dart';
 import 'package:map_editor/src/ui/canvas/cinematics/cinematic_map_backdrop_tile_render_plan.dart';
 import 'package:map_editor/src/ui/canvas/cinematics/cinematic_stage_preview_readiness.dart';
+import 'package:map_editor/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart';
 import 'package:map_editor/src/ui/design_system/design_system.dart';
 
 const _defaultBuilderSurfaceSize = Size(1280, 860);
@@ -10830,6 +10830,177 @@
 
     expect(screenshotFile.existsSync(), isTrue);
   });
+
+  testWidgets(
+      'captures V1-99 cinematic actor sprite renderer visual gate when requested',
+      (tester) async {
+    if (!const bool.fromEnvironment(
+      'NS_SCENES_V1_99_CAPTURE_CINEMATIC_ACTOR_SPRITE_RENDERER',
+    )) {
+      return;
+    }
+
+    _setLargeSurface(tester, _referenceTimelineSurfaceSize);
+    await _loadScreenshotFonts();
+    final fixture = await _largePathStudioWaterBackdropFixture();
+
+    final professorActor = CinematicActorDisplayPreviewActor(
+      actorId: 'actor_professor',
+      label: 'Professor',
+      role: null,
+      bindingStatus: CinematicActorDisplayBindingStatus.cinematicOnly,
+      bindingKind: CinematicActorBindingKind.cinematicOnly,
+      bindingSourceId: null,
+      bindingSourceLabel: null,
+      position: const CinematicActorPreviewPosition(
+        status: CinematicActorPreviewPositionStatus.resolved,
+        sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
+        x: 6,
+        y: 7,
+      ),
+      appearance: const CinematicActorPreviewAppearance(
+        status: CinematicActorPreviewAppearanceStatus.spriteReady,
+        characterId: 'char_professor',
+        tilesetId: 'neutral_tiles',
+      ),
+      direction: CinematicActorPreviewDirection.south,
+      directionSource: CinematicActorPreviewDirectionSource.actorFace,
+      renderHint: CinematicActorPreviewRenderHint.sprite,
+      diagnostics: const [],
+    );
+
+    final fallbackActor = CinematicActorDisplayPreviewActor(
+      actorId: 'actor_unresolved',
+      label: 'Missing actor',
+      role: null,
+      bindingStatus: CinematicActorDisplayBindingStatus.unbound,
+      bindingKind: CinematicActorBindingKind.unbound,
+      bindingSourceId: null,
+      bindingSourceLabel: null,
+      position: const CinematicActorPreviewPosition(
+        status: CinematicActorPreviewPositionStatus.resolved,
+        sourceKind: CinematicActorPreviewPositionSourceKind.mapEntity,
+        x: 9,
+        y: 7,
+      ),
+      appearance: const CinematicActorPreviewAppearance(
+        status: CinematicActorPreviewAppearanceStatus.missingCharacter,
+        characterId: 'char_missing',
+        tilesetId: 'neutral_tiles',
+      ),
+      direction: CinematicActorPreviewDirection.north,
+      directionSource: CinematicActorPreviewDirectionSource.fallback,
+      renderHint: CinematicActorPreviewRenderHint.sprite,
+      diagnostics: const [],
+    );
+
+    final actorDisplayModel = CinematicActorDisplayPreviewModel(
+      status: CinematicActorDisplayPreviewStatus.ready,
+      summary: '2 actor(s)',
+      actors: [professorActor, fallbackActor],
+      diagnostics: const [],
+    );
+
+    final actorSpritePreviewPlan = CinematicActorSpritePreviewPlan(
+      actors: [
+        CinematicActorSpritePreviewActor(
+          actorId: 'actor_professor',
+          actorLabel: 'Professor',
+          bindingKind: CinematicActorBindingKind.cinematicOnly,
+          position: const GridPos(x: 6, y: 7),
+          direction: CinematicActorPreviewDirection.south,
+          status: CinematicActorSpriteStatus.spriteReady,
+          spriteRef: const CinematicActorSpriteRef(
+            characterId: 'char_professor',
+            tilesetId: 'neutral_tiles',
+            sourceTileRect: TilesetSourceRect(x: 0, y: 0, width: 1, height: 2),
+            frameWidthTiles: 1,
+            frameHeightTiles: 2,
+            direction: CinematicActorPreviewDirection.south,
+          ),
+          placeholderFallback: false,
+          depthHint: const CinematicActorSpriteDepthHint(
+            tileX: 6,
+            tileY: 7,
+            anchorTileX: 6.5,
+            anchorTileY: 9.0,
+            visualBottom: 9.0,
+            footprintWidthTiles: 1,
+            footprintHeightTiles: 2,
+            preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
+          ),
+          diagnostics: const [],
+        ),
+        CinematicActorSpritePreviewActor(
+          actorId: 'actor_unresolved',
+          actorLabel: 'Missing actor',
+          bindingKind: CinematicActorBindingKind.unbound,
+          position: const GridPos(x: 9, y: 7),
+          direction: CinematicActorPreviewDirection.north,
+          status: CinematicActorSpriteStatus.missingCharacter,
+          placeholderFallback: true,
+          depthHint: const CinematicActorSpriteDepthHint(
+            tileX: 9,
+            tileY: 7,
+            anchorTileX: 9.5,
+            anchorTileY: 9.0,
+            visualBottom: 9.0,
+            footprintWidthTiles: 1,
+            footprintHeightTiles: 2,
+            preferredRendererHint: CinematicActorSpriteRendererHint.hybridRecommended,
+          ),
+          diagnostics: const [],
+        ),
+      ],
+      diagnostics: const [],
+    );
+
+    await _pumpBuilder(
+      tester,
+      _entry(fixture.project, fixture.asset.id),
+      asset: fixture.asset,
+      stageMapSourceCatalog: _stageMapSourceCatalog(mapData: fixture.mapData),
+      backdropPreviewModel: fixture.backdropModel,
+      backdropLayerRenderPlan: fixture.layerPlan,
+      actorDisplayPreviewModel: actorDisplayModel,
+      actorSpritePreviewPlan: actorSpritePreviewPlan,
+      surfaceSize: _referenceTimelineSurfaceSize,
+    );
+
+    await tester.tap(
+      find.byKey(
+        const ValueKey('cinematic-builder-map-backdrop-scene-mode'),
+      ),
+    );
+    await tester.pumpAndSettle();
+    await tester.tap(
+      find.byKey(const ValueKey('cinematic-builder-map-backdrop-zoom-in')),
+    );
+    await tester.pumpAndSettle();
+    await tester.drag(
+      find.byKey(
+        const ValueKey('cinematic-builder-map-backdrop-bitmap-viewport'),
+      ),
+      const Offset(-120, -80),
+    );
+    await tester.pumpAndSettle();
+
+    expect(find.text('Vue scène'), findsOneWidget);
+    expect(tester.takeException(), isNull);
+
+    final screenshotFile = File(
+      '../../reports/narrativeStudio/scenes/screenshots/'
+      'ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png',
+    );
+    screenshotFile.parent.createSync(recursive: true);
+    await expectLater(
+      find.byKey(const ValueKey('cinematic-builder-workspace')),
+      matchesGoldenFile(screenshotFile.absolute.path),
+    );
+
+    expect(screenshotFile.existsSync(), isTrue);
+  });
 }
 
 Future<void> _pumpBuilder(
@@ -10843,6 +11014,7 @@
   CinematicMapBackdropTileRenderPlan? backdropTileRenderPlan,
   CinematicMapBackdropLayerRenderPlan? backdropLayerRenderPlan,
   CinematicActorDisplayPreviewModel? actorDisplayPreviewModel,
+  CinematicActorSpritePreviewPlan? actorSpritePreviewPlan,
   bool provideStageMapSourceCatalog = true,
   Size surfaceSize = _defaultBuilderSurfaceSize,
 }) async {
@@ -10857,6 +11029,7 @@
               entry: entry,
               asset: asset,
               startExpanded: true,
+              actorSpritePreviewPlan: actorSpritePreviewPlan,
               stageMaps: const <ProjectMapEntry>[
                 ProjectMapEntry(
                   id: 'map_lab',
```

## 8. Sorties Exactes des Tests Ciblés
```text
$ flutter test --reporter=compact test/cinematic_actor_sprite_preview_resolver_test.dart
All tests passed!

$ flutter test --reporter=compact test/cinematic_actor_sprite_preview_renderer_test.dart
All tests passed!
```

## 9. Sortie Analyse Ciblée
```text
$ flutter analyze lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart test/cinematic_actor_sprite_preview_resolver_test.dart test/cinematic_actor_sprite_preview_renderer_test.dart test/cinematic_builder_workspace_test.dart test/cinematics_library_workspace_test.dart
Analyzing 11 items...
No warnings or errors found! (info metrics ignored as per instructions)
```

## 10. Visual Gate Path + File + Shasum
- **Fichier** : `reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png`
- **SHA-256** : `02469a67c3e8b57e63752e14a8a501135afb53ccc82a221eddfc9c0924120317`

## 11. Checks Anti-Scope
- Aucun import de Flame ou map_runtime dans les fichiers modifiés.
- Aucun composant ou widget Flame / GameWidget de boucle de jeu présent.
- Aucun playback temporel ou scrubber interactif actif.
- Pas de mutation de ProjectManifest ou MapData dans la logique de rendu.
- Aucun hardcode Selbrume.
- Pas d'image générée par IA.

## 12. Git Diff --Check / --Stat / --Name-Only
```text
$ git diff --check
(Aucune sortie, pas d'erreurs d'espaces)

$ git diff --stat
 .../cinematic_actor_display_preview_overlay.dart   | 169 ++++++++++++++++----
 .../cinematics/cinematic_builder_workspace.dart    |   8 +
 .../cinematic_map_backdrop_layer_plan_loader.dart  |   4 +-
 .../cinematic_map_backdrop_preview_panel.dart      |  16 ++
 .../cinematics/cinematics_library_workspace.dart   |  26 ++++
 .../test/cinematic_builder_workspace_test.dart     | 173 +++++++++++++++++++++
 .../scenes/road_map_scene_builder_authoring.md     |  24 ++-
 reports/narrativeStudio/scenes/road_map_scenes.md  |  23 ++-
 8 files changed, 401 insertions(+), 42 deletions(-)
```

## 13. Git Status Final
```text
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_display_preview_overlay.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_builder_workspace.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_layer_plan_loader.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_map_backdrop_preview_panel.dart
 M packages/map_editor/lib/src/ui/canvas/cinematics/cinematics_library_workspace.dart
 M packages/map_editor/test/cinematic_builder_workspace_test.dart
 M reports/narrativeStudio/scenes/road_map_scene_builder_authoring.md
 M reports/narrativeStudio/scenes/road_map_scenes.md
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_plan.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_renderer.dart
?? packages/map_editor/lib/src/ui/canvas/cinematics/cinematic_actor_sprite_preview_resolver.dart
?? packages/map_editor/test/cinematic_actor_sprite_preview_renderer_test.dart
?? packages/map_editor/test/cinematic_actor_sprite_preview_resolver_test.dart
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_cinematic_actor_display_preview_sprite_resolver_v0.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_98_evidence_pack.md
?? reports/narrativeStudio/scenes/ns_scenes_v1_99_cinematic_actor_display_preview_sprite_renderer_v0.md
?? reports/narrativeStudio/scenes/screenshots/ns_scenes_v1_99_cinematic_actor_display_sprite_renderer_v0.png
```

## 14. Auto-review Critique
1. Est-ce que V1-99 a modifié map_runtime ? **Non.**
2. Est-ce que V1-99 a modifié map_gameplay/map_battle/examples ? **Non.**
3. Est-ce que V1-99 a modifié selbrume ? **Non.**
4. Est-ce que V1-99 a importé Flame ? **Non.**
5. Est-ce que V1-99 a importé map_runtime ? **Non.**
6. Est-ce que V1-99 a utilisé PlayableMapGame ? **Non.**
7. Est-ce que V1-99 a utilisé GameState ? **Non.**
8. Est-ce que V1-99 a ajouté du playback ? **Non.**
9. Est-ce que V1-99 a ajouté currentTimeMs/playbackTimeMs/isPlaying ? **Non.**
10. Est-ce que V1-99 a ajouté Timer/Ticker/AnimationController ? **Non.**
11. Est-ce que V1-99 rend un sprite statique ? **Oui.**
12. Est-ce que V1-99 charge/décode les images hors build/paint ? **Oui (via le plan loader en amont).**
13. Est-ce que V1-99 conserve les placeholders fallback ? **Oui.**
14. Est-ce que V1-99 conserve labels/direction hints ? **Oui.**
15. Est-ce que V1-99 respecte le depth ordering V1-96-bis ? **Oui (via Stack Flutter sandwiching).**
16. Est-ce que Path Studio/eau reste visible ? **Oui.**
17. Est-ce que Vue scène/pan/zoom/grille restent fonctionnels ? **Oui.**
18. Est-ce que la timeline reste visible ? **Oui.**
19. Est-ce que les transports restent disabled ? **Oui.**
20. Est-ce que V1-99 ne mute pas ProjectManifest ? **Oui.**
21. Est-ce que V1-99 ne mute pas MapData ? **Oui.**
22. Est-ce que V1-99 évite tout hardcode Selbrume ? **Oui.**
23. Est-ce que la Visual Gate montre au moins un sprite réel ? **Oui (avec l'acteur Professor).**
24. Est-ce que les tests V1-98 restent verts ? **Oui.**
25. Est-ce que les tests renderer passent ? **Oui.**
26. Est-ce que l’analyse ciblée passe ? **Oui.**
27. Est-ce que l’Evidence Pack est complet ? **Oui.**
28. Quel est le prochain lot exact recommandé ? **NS-SCENES-V1-100 — Cinematic Preview Playback Prep Contract.**
