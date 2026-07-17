import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/application/services/map_focus_viewport_resolver.dart';

void main() {
  group('NS-EVENT-V2-24 focus viewport resolver', () {
    test('centers exact multi-cell bounds while preserving zoom', () {
      final pan = resolveMapFocusPanOffset(
        bounds: const MapRect(
          pos: GridPos(x: 4, y: 3),
          size: GridSize(width: 2, height: 4),
        ),
        viewportSize: const Size(800, 600),
        tileWidth: 32,
        tileHeight: 24,
        zoom: 1.5,
      );

      expect(pan, const Offset(160, 120));
    });

    test('map focus resolves to full-map bounds without a fake owner', () {
      const map = MapData(
        id: 'map_a',
        name: 'Map A',
        size: GridSize(width: 20, height: 12),
        layers: [ObjectLayer(id: 'objects', name: 'Objects')],
      );
      final focus = NarrativeEditorFocusTarget.map('map_a');

      final bounds = resolveNarrativeEventMapFocusBounds(
        focus: focus,
        map: map,
      );

      expect(
        bounds,
        const MapRect(
          pos: GridPos(x: 0, y: 0),
          size: GridSize(width: 20, height: 12),
        ),
      );
      expect(focus.ownerId, isNull);
    });

    test('rejects a focus target from another map', () {
      expect(
        () => resolveNarrativeEventMapFocusBounds(
          focus: NarrativeEditorFocusTarget.map('map_b'),
          map: const MapData(
            id: 'map_a',
            name: 'Map A',
            size: GridSize(width: 3, height: 3),
            layers: [ObjectLayer(id: 'objects', name: 'Objects')],
          ),
        ),
        throwsArgumentError,
      );
    });
  });
}
