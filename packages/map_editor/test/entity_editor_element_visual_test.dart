import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/ui/canvas/entity_editor_element_visual.dart';

void main() {
  group('entity editor element visual helpers', () {
    test('falls back to the default frame duration when absent or invalid', () {
      const withoutDuration = TilesetVisualFrame(
        source: TilesetSourceRect(x: 0, y: 0),
      );
      const invalidDuration = TilesetVisualFrame(
        source: TilesetSourceRect(x: 1, y: 0),
        durationMs: 0,
      );
      const validDuration = TilesetVisualFrame(
        source: TilesetSourceRect(x: 2, y: 0),
        durationMs: 120,
      );

      expect(
        entityEditorFrameDurationMs(withoutDuration),
        kEntityEditorFrameDurationFallbackMs,
      );
      expect(
        entityEditorFrameDurationMs(invalidDuration),
        kEntityEditorFrameDurationFallbackMs,
      );
      expect(entityEditorFrameDurationMs(validDuration), 120);
    });

    test('picks the expected animation frame from elapsed time', () {
      const frames = [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0),
          durationMs: 200,
        ),
      ];

      expect(entityEditorPickFrame(frames, 0), frames[0]);
      expect(entityEditorPickFrame(frames, 99), frames[0]);
      expect(entityEditorPickFrame(frames, 100), frames[1]);
      expect(entityEditorPickFrame(frames, 299), frames[1]);
      expect(entityEditorPickFrame(frames, 300), frames[0]);
    });

    test('keeps a placed element without autoplay on its configured frame', () {
      const frames = [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0),
          durationMs: 100,
        ),
      ];
      const staticInstance = MapPlacedElement(
        id: 'door',
        layerId: 'buildings',
        elementId: 'door-element',
        pos: GridPos(x: 2, y: 3),
      );
      const fixedInstance = MapPlacedElement(
        id: 'door-offset',
        layerId: 'buildings',
        elementId: 'door-element',
        pos: GridPos(x: 2, y: 3),
        animation: MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
          autoplay: false,
          startOffsetMs: 100,
        ),
      );

      expect(
        entityEditorPickPlacedElementFrame(staticInstance, frames, 150),
        frames[0],
      );
      expect(
        entityEditorPickPlacedElementFrame(fixedInstance, frames, 0),
        frames[1],
      );
      expect(
        entityEditorPickPlacedElementFrame(fixedInstance, frames, 150),
        frames[1],
      );
      expect(
        entityEditorPlacedElementNeedsFrameAnimation(staticInstance, frames),
        isFalse,
      );
      expect(
        entityEditorPlacedElementNeedsFrameAnimation(fixedInstance, frames),
        isFalse,
      );
    });

    test('animates a placed element only when autoplay is enabled', () {
      const frames = [
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 0, y: 0),
          durationMs: 100,
        ),
        TilesetVisualFrame(
          source: TilesetSourceRect(x: 1, y: 0),
          durationMs: 100,
        ),
      ];
      const instance = MapPlacedElement(
        id: 'waterfall',
        layerId: 'environment',
        elementId: 'waterfall-element',
        pos: GridPos(x: 4, y: 5),
        animation: MapPlacedElementAnimation(
          enabled: true,
          mode: MapPlacedElementAnimationMode.loop,
        ),
      );

      expect(
        entityEditorPickPlacedElementFrame(instance, frames, 0),
        frames[0],
      );
      expect(
        entityEditorPickPlacedElementFrame(instance, frames, 100),
        frames[1],
      );
      expect(
        entityEditorPlacedElementNeedsFrameAnimation(instance, frames),
        isTrue,
      );
    });

    test('throws explicitly when no frame is available', () {
      expect(
        () => entityEditorPickFrame(const [], 0),
        throwsA(isA<StateError>()),
      );
    });
  });
}
