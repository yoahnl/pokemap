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

    test('hits grid-edge strokes by screen-pixel distance', () {
      final layer = _layer(<BorderFeature>[
        BorderFeature(
          id: 'edge-stroke',
          name: 'Edge stroke',
          blueprintId: 'stone-chain',
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            alignment: BorderStrokeAlignment.gridEdges,
            strokes: <BorderStroke>[
              BorderStroke(
                id: 'coast-edge',
                points: const <GridPos>[
                  GridPos(x: 1, y: 0),
                  GridPos(x: 1, y: 1),
                  GridPos(x: 1, y: 2),
                  GridPos(x: 1, y: 3),
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
        hitTestBorderFeatureAtScreenPosition(
          layer: layer,
          localPosition: const Offset(28, 42),
          pan: const Offset(10, 10),
          zoom: 0.5,
          tileWidth: 32,
          tileHeight: 32,
          toleranceScreenPx: 3,
        )?.id,
        'edge-stroke',
      );
      expect(
        hitTestBorderFeatureAtScreenPosition(
          layer: layer,
          localPosition: const Offset(36, 42),
          pan: const Offset(10, 10),
          zoom: 0.5,
          tileWidth: 32,
          tileHeight: 32,
          toleranceScreenPx: 3,
        ),
        isNull,
      );
    });

    test('hits inclusive right and bottom grid edges at every supported zoom',
        () {
      final layer = _layer(<BorderFeature>[
        BorderFeature(
          id: 'map-boundary',
          name: 'Map boundary',
          blueprintId: 'stone-chain',
          seed: BorderSignedInt64.zero,
          geometry: BorderStrokeGeometry(
            alignment: BorderStrokeAlignment.gridEdges,
            strokes: <BorderStroke>[
              BorderStroke(
                id: 'right-and-bottom',
                points: const <GridPos>[
                  GridPos(x: 5, y: 0),
                  GridPos(x: 5, y: 1),
                  GridPos(x: 5, y: 2),
                  GridPos(x: 5, y: 3),
                  GridPos(x: 5, y: 4),
                  GridPos(x: 4, y: 4),
                  GridPos(x: 3, y: 4),
                  GridPos(x: 2, y: 4),
                  GridPos(x: 1, y: 4),
                  GridPos(x: 0, y: 4),
                ],
                closed: false,
              ),
            ],
          ),
          overrides: const <BorderSlotOverride>[],
          keepOutRegions: const <BorderKeepOutRegion>[],
        ),
      ]);
      const pan = Offset(13, 17);

      for (final zoom in <double>[0.3, 0.5, 1]) {
        final rightEdgeX = pan.dx + 5 * 32 * zoom;
        final rightEdgeMidY = pan.dy + 2 * 32 * zoom;
        final bottomEdgeMidX = pan.dx + 2 * 32 * zoom;
        final bottomEdgeY = pan.dy + 4 * 32 * zoom;

        expect(
          hitTestBorderFeatureAtScreenPosition(
            layer: layer,
            localPosition: Offset(rightEdgeX - 2, rightEdgeMidY),
            pan: pan,
            zoom: zoom,
            tileWidth: 32,
            tileHeight: 32,
            toleranceScreenPx: 3,
          )?.id,
          'map-boundary',
          reason: 'right edge at zoom=$zoom',
        );
        expect(
          hitTestBorderFeatureAtScreenPosition(
            layer: layer,
            localPosition: Offset(bottomEdgeMidX, bottomEdgeY - 2),
            pan: pan,
            zoom: zoom,
            tileWidth: 32,
            tileHeight: 32,
            toleranceScreenPx: 3,
          )?.id,
          'map-boundary',
          reason: 'bottom edge at zoom=$zoom',
        );
      }
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
