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
