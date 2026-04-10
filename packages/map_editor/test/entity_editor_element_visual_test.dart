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

    test('throws explicitly when no frame is available', () {
      expect(
        () => entityEditorPickFrame(const [], 0),
        throwsA(isA<StateError>()),
      );
    });
  });
}
