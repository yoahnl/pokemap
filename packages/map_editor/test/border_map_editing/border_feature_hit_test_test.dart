import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/border_feature_hit_test.dart';

void main() {
  group('hitTestBorderFeature', () {
    test('returns the visually uppermost overlapping region feature', () {
      final layer = _layer(<BorderFeature>[
        _regionFeature('lower', const <GridPos>[GridPos(x: 1, y: 1)]),
        _regionFeature('upper', const <GridPos>[GridPos(x: 1, y: 1)]),
      ]);

      final hit = hitTestBorderFeature(
        layer: layer,
        position: const GridPos(x: 1, y: 1),
      );

      expect(hit?.id, 'upper');
    });

    test('treats persisted stroke points as explicit hit cells', () {
      final layer = _layer(<BorderFeature>[
        _regionFeature('region', const <GridPos>[GridPos(x: 2, y: 1)]),
        BorderFeature(
          id: 'stroke',
          name: 'Stroke',
          blueprintId: 'wall',
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            strokes: <BorderStroke>[
              BorderStroke(
                id: 'stroke-a',
                points: const <GridPos>[
                  GridPos(x: 1, y: 1),
                  GridPos(x: 2, y: 1),
                ],
                closed: false,
              ),
            ],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
      ]);

      expect(
        hitTestBorderFeature(
          layer: layer,
          position: const GridPos(x: 2, y: 1),
        )?.id,
        'stroke',
      );
      expect(
        hitTestBorderFeature(
          layer: layer,
          position: const GridPos(x: 0, y: 0),
        ),
        isNull,
      );
    });
  });
}

BorderLayer _layer(List<BorderFeature> features) => MapLayer.border(
      id: 'borders',
      name: 'Bordures',
      content: BorderLayerContent(features: features),
    ) as BorderLayer;

BorderFeature _regionFeature(String id, List<GridPos> filled) {
  final cells = List<bool>.filled(9, false);
  for (final position in filled) {
    cells[position.y * 3 + position.x] = true;
  }
  return BorderFeature(
    id: id,
    name: id,
    blueprintId: 'coast',
    seed: BorderSignedInt64.zero,
    geometry: BorderRegionGeometry(width: 3, height: 3, cells: cells),
    overrides: const <BorderSlotOverride>[],
    keepOutRegions: const <BorderKeepOutRegion>[],
  );
}
