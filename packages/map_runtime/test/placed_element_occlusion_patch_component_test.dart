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
    sourceWidthPx: 2,
    sourceHeightPx: 2,
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
