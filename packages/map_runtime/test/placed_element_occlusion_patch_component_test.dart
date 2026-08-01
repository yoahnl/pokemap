import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/infrastructure/runtime_tileset_image.dart';
import 'package:map_runtime/src/presentation/flame/placed_element_occlusion_patch_component.dart';
import 'package:map_runtime/src/presentation/flame/static_placed_element_occlusion_patch_resolution.dart';

import 'surface/surface_runtime_test_support.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlacedElementOcclusionPatchComponent', () {
    test('configures position size and priority from instruction', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 12,
          worldTop: 24,
          visualWidth: 32,
          visualHeight: 16,
          flamePriority: 1040,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      expect(component.position.x, 12);
      expect(component.position.y, 24);
      expect(component.size.x, 32);
      expect(component.size.y, 16);
      expect(component.priority, 1040);
    });

    test('renders only masked occlusion pixels', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      final image = await _render(component, width: 2, height: 2);

      expect(await pixelAt(image, 0, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 0, 1), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 1), rgba(255, 255, 0, 255));
    });

    for (var quarterTurns = 0; quarterTurns < 4; quarterTurns++) {
      test(
          'renders asymmetric masked source with exact core sampling at q$quarterTurns',
          () async {
        const sourceSize = GridSize(width: 6, height: 2);
        final destinationSize = quarterTurns.isEven
            ? const GridSize(width: 6, height: 2)
            : const GridSize(width: 3, height: 4);
        const solidPixels = <int>{0, 1, 4, 6, 8, 11};
        final component = PlacedElementOcclusionPatchComponent(
          instruction: _instruction(
            sourceWidthPx: sourceSize.width,
            sourceHeightPx: sourceSize.height,
            quarterTurns: quarterTurns,
            destinationWidthPx: destinationSize.width,
            destinationHeightPx: destinationSize.height,
            visualWidth: destinationSize.width.toDouble(),
            visualHeight: destinationSize.height.toDouble(),
            depthSortY: destinationSize.height.toDouble(),
            mask: _mask(
              widthPx: sourceSize.width,
              heightPx: sourceSize.height,
              solidPixels: solidPixels,
            ),
          ),
          tilesetImage: await _runtimeTilesetImage6x2(),
        );
        final transform = QuarterTurnPixelTransform(
          sourcePixelSize: sourceSize,
          destinationPixelSize: destinationSize,
          quarterTurns: quarterTurns,
        );

        final image = await _render(
          component,
          width: destinationSize.width,
          height: destinationSize.height,
        );

        for (var y = 0; y < destinationSize.height; y++) {
          for (var x = 0; x < destinationSize.width; x++) {
            final source = transform.destinationPixelToSourcePixel(
              GridPos(x: x, y: y),
            );
            final sourceIndex = source.y * sourceSize.width + source.x;
            final expected = solidPixels.contains(sourceIndex)
                ? _asymmetricPixel(source.x, source.y)
                : rgba(0, 0, 0, 0);
            expect(
              await pixelAt(image, x, y),
              expected,
              reason: 'q$quarterTurns destination ($x, $y) '
                  'samples source (${source.x}, ${source.y})',
            );
          }
        }
        expect(component.debugQuarterTurnDrawRunCount, greaterThan(0));
        expect(
          component.debugQuarterTurnDrawRunCount,
          lessThan(component.debugIncludedDestinationPixelCount),
          reason: 'q$quarterTurns must batch included destination pixels',
        );
      });
    }

    test('does not render when opacity is zero', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          opacity: 0,
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0, 3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      final image = await _render(component, width: 2, height: 2);

      expect(await pixelAt(image, 0, 0), rgba(0, 0, 0, 0));
      expect(await pixelAt(image, 1, 1), rgba(0, 0, 0, 0));
    });

    test('empty decoded mask produces no draw runs', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      expect(component.debugDrawRunCount, 0);
    });

    test('applies successive map origin deltas cumulatively', () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 100,
          worldTop: 200,
          depthSortY: 216,
          flamePriority: 1216,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      component.translateByMapOriginDelta(Vector2(32, 16));
      component.translateByMapOriginDelta(Vector2(32, -8));

      expect(component.position.x, 164);
      expect(component.position.y, 208);
      expect(component.priority, 1224);
    });

    test('zero map origin delta keeps position and priority unchanged',
        () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 100,
          worldTop: 200,
          depthSortY: 216,
          flamePriority: 1216,
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );

      component.translateByMapOriginDelta(Vector2.zero());

      expect(component.position.x, 100);
      expect(component.position.y, 200);
      expect(component.priority, 1216);
    });

    test('prepares once and replays the same plan across steady-state renders',
        () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0, 3}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
      );
      addTearDown(component.onRemove);
      final preparationSamples = component.debugQuarterTurnResampleCount;
      final first = ui.PictureRecorder();
      component.render(Canvas(first));
      first.endRecording().dispose();
      final second = ui.PictureRecorder();
      component.render(Canvas(second));
      second.endRecording().dispose();

      expect(component.debugRenderPlanPreparationCount, 1);
      expect(component.debugRenderPlanDrawCount, 2);
      expect(preparationSamples, greaterThan(0));
      expect(component.debugQuarterTurnResampleCount, preparationSamples);
    });

    test('culls outside the camera and keeps the one-pixel edge halo',
        () async {
      var visibleRect = const Rect.fromLTWH(20, 20, 2, 2);
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 10,
          worldTop: 10,
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
        visibleWorldRectProvider: () => visibleRect,
      );
      addTearDown(component.onRemove);
      final outside = ui.PictureRecorder();
      component.render(Canvas(outside));
      outside.endRecording().dispose();

      expect(component.debugRenderPlanDrawCount, 0);
      expect(component.debugCulledRenderCount, 1);

      visibleRect = const Rect.fromLTWH(8.5, 10, 0.75, 1);
      final edge = ui.PictureRecorder();
      component.render(Canvas(edge));
      edge.endRecording().dispose();

      expect(component.debugRenderPlanDrawCount, 1);
      expect(component.debugCulledRenderCount, 1);
    });

    test('culling follows the current position after an origin translation',
        () async {
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(
          worldLeft: 10,
          worldTop: 10,
          mask: _mask(widthPx: 2, heightPx: 2, solidPixels: const {0}),
        ),
        tilesetImage: await _runtimeTilesetImage2x2(),
        visibleWorldRectProvider: () => const Rect.fromLTWH(109, 9, 4, 4),
      );
      addTearDown(component.onRemove);
      final before = ui.PictureRecorder();
      component.render(Canvas(before));
      before.endRecording().dispose();
      expect(component.debugRenderPlanDrawCount, 0);

      component.translateByMapOriginDelta(Vector2(100, 0));
      final after = ui.PictureRecorder();
      component.render(Canvas(after));
      after.endRecording().dispose();

      expect(component.debugRenderPlanDrawCount, 1);
      expect(component.debugCulledRenderCount, 1);
    });

    test('disposes its render plan idempotently without owning the tileset',
        () async {
      final tileset = await _runtimeTilesetImage2x2();
      final component = PlacedElementOcclusionPatchComponent(
        instruction: _instruction(),
        tilesetImage: tileset,
      );

      component.onRemove();
      component.onRemove();

      expect(component.debugRenderPlanDisposed, isTrue);
      final recorder = ui.PictureRecorder();
      tileset.drawImageRect(
        Canvas(recorder),
        const Rect.fromLTWH(0, 0, 1, 1),
        const Rect.fromLTWH(0, 0, 1, 1),
        Paint(),
      );
      final image = await recorder.endRecording().toImage(1, 1);
      addTearDown(image.dispose);
      expect(await pixelAt(image, 0, 0), rgba(255, 0, 0, 255));
    });
  });
}

StaticPlacedElementOcclusionPatchInstruction _instruction({
  double worldLeft = 0,
  double worldTop = 0,
  double visualWidth = 2,
  double visualHeight = 2,
  double depthSortY = 2,
  int flamePriority = 1002,
  double opacity = 1,
  int sourceWidthPx = 2,
  int sourceHeightPx = 2,
  int quarterTurns = 0,
  int destinationWidthPx = 2,
  int destinationHeightPx = 2,
  ElementCollisionPixelMask? mask,
}) {
  return StaticPlacedElementOcclusionPatchInstruction(
    mapId: 'map',
    placedElementId: 'placed',
    elementId: 'element',
    layerId: 'objects',
    tilesetId: 'entity',
    sourceLeftPx: 0,
    sourceTopPx: 0,
    sourceWidthPx: sourceWidthPx,
    sourceHeightPx: sourceHeightPx,
    quarterTurns: quarterTurns,
    destinationWidthPx: destinationWidthPx,
    destinationHeightPx: destinationHeightPx,
    worldLeft: worldLeft,
    worldTop: worldTop,
    visualWidth: visualWidth,
    visualHeight: visualHeight,
    depthSortY: depthSortY,
    flamePriority: flamePriority,
    opacity: opacity,
    occlusionMask: mask ?? _mask(widthPx: 2, heightPx: 2),
  );
}

ElementCollisionPixelMask _mask({
  required int widthPx,
  required int heightPx,
  Set<int> solidPixels = const {0},
}) {
  final bits = List<bool>.filled(widthPx * heightPx, false);
  for (final index in solidPixels) {
    if (index >= 0 && index < bits.length) {
      bits[index] = true;
    }
  }
  return ElementCollisionPixelMask(
    widthPx: widthPx,
    heightPx: heightPx,
    dataBase64: ElementCollisionMaskCodec.encodePackedBits(
      widthPx: widthPx,
      heightPx: heightPx,
      solidPixels: bits,
    ),
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage2x2() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  canvas.drawRect(
    const Rect.fromLTWH(0, 0, 1, 1),
    Paint()..color = const Color(0xFFFF0000),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 0, 1, 1),
    Paint()..color = const Color(0xFF00FF00),
  );
  canvas.drawRect(
    const Rect.fromLTWH(0, 1, 1, 1),
    Paint()..color = const Color(0xFF0000FF),
  );
  canvas.drawRect(
    const Rect.fromLTWH(1, 1, 1, 1),
    Paint()..color = const Color(0xFFFFFF00),
  );
  final image = await recorder.endRecording().toImage(2, 2);
  return RuntimeTilesetImage(
    images: [image],
    chunks: const [
      RuntimeTilesetChunk(top: 0, height: 2, width: 2),
    ],
    width: 2,
    height: 2,
  );
}

Future<RuntimeTilesetImage> _runtimeTilesetImage6x2() async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  for (var y = 0; y < 2; y++) {
    for (var x = 0; x < 6; x++) {
      canvas.drawRect(
        Rect.fromLTWH(x.toDouble(), y.toDouble(), 1, 1),
        Paint()
          ..color = Color.fromARGB(
            255,
            20 + x * 30,
            40 + y * 120,
            10 + x * 7 + y * 3,
          ),
      );
    }
  }
  final image = await recorder.endRecording().toImage(6, 2);
  return RuntimeTilesetImage(
    images: [image],
    chunks: const [
      RuntimeTilesetChunk(top: 0, height: 2, width: 6),
    ],
    width: 6,
    height: 2,
  );
}

List<int> _asymmetricPixel(int x, int y) => rgba(
      20 + x * 30,
      40 + y * 120,
      10 + x * 7 + y * 3,
      255,
    );

Future<ui.Image> _render(
  PlacedElementOcclusionPatchComponent component, {
  required int width,
  required int height,
}) {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  component.render(canvas);
  return recorder.endRecording().toImage(width, height);
}
