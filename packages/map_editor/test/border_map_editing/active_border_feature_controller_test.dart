import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/border_map_editing/application/active_border_feature_controller.dart';
import 'package:map_editor/src/features/border_map_editing/state/border_map_editing_providers.dart';

void main() {
  group('ActiveBorderFeatureController', () {
    test('selects the uppermost authored feature for an active Border layer',
        () {
      final controller = ActiveBorderFeatureController();
      final map = _map(
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border-a',
            name: 'Bordures',
            content: BorderLayerContent(
              features: <BorderFeature>[
                _feature('lower'),
                _feature('upper'),
              ],
            ),
          ),
        ],
      );

      controller.reconcile(map: map, activeLayerId: 'border-a');

      expect(controller.state.activeLayerId, 'border-a');
      expect(controller.state.activeFeatureId, 'upper');
    });

    test('preserves a surviving selection and reconciles deletion', () {
      final controller = ActiveBorderFeatureController();
      final initial = _map(
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border-a',
            name: 'Bordures',
            content: BorderLayerContent(
              features: <BorderFeature>[
                _feature('first'),
                _feature('second'),
              ],
            ),
          ),
        ],
      );
      controller.reconcile(map: initial, activeLayerId: 'border-a');
      controller.selectFeature(
        map: initial,
        layerId: 'border-a',
        featureId: 'first',
      );

      controller.reconcile(
        map: _map(
          layers: <MapLayer>[
            MapLayer.border(
              id: 'border-a',
              name: 'Bordures',
              content: BorderLayerContent(
                features: <BorderFeature>[
                  _feature('second'),
                  _feature('first'),
                ],
              ),
            ),
          ],
        ),
        activeLayerId: 'border-a',
      );
      expect(controller.state.activeFeatureId, 'first');

      controller.reconcile(
        map: _map(
          layers: <MapLayer>[
            MapLayer.border(
              id: 'border-a',
              name: 'Bordures',
              content: BorderLayerContent(
                features: <BorderFeature>[_feature('second')],
              ),
            ),
          ],
        ),
        activeLayerId: 'border-a',
      );
      expect(controller.state.activeFeatureId, 'second');
    });

    test('clears selection outside a Border layer or without a map', () {
      final controller = ActiveBorderFeatureController();
      final border = MapLayer.border(
        id: 'border-a',
        name: 'Bordures',
        content: BorderLayerContent(
          features: <BorderFeature>[_feature('feature')],
        ),
      );
      controller.reconcile(
        map: _map(layers: <MapLayer>[border]),
        activeLayerId: border.id,
      );

      controller.reconcile(
        map: _map(
          layers: const <MapLayer>[
            MapLayer.tile(
              id: 'tiles',
              name: 'Tiles',
              tilesetId: 'tileset',
            ),
          ],
        ),
        activeLayerId: 'tiles',
      );
      expect(controller.state, const ActiveBorderFeatureState.empty());

      controller.reconcile(map: null, activeLayerId: null);
      expect(controller.state, const ActiveBorderFeatureState.empty());
    });

    test('rejects selecting a feature outside the requested Border layer', () {
      final controller = ActiveBorderFeatureController();
      final map = _map(
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border-a',
            name: 'Bordures',
            content: BorderLayerContent(
              features: <BorderFeature>[_feature('known')],
            ),
          ),
        ],
      );

      expect(
        () => controller.selectFeature(
          map: map,
          layerId: 'border-a',
          featureId: 'missing',
        ),
        throwsArgumentError,
      );
    });

    test('provider follows active map/layer without serializing selection', () {
      final map = _map(
        layers: <MapLayer>[
          MapLayer.border(
            id: 'border-a',
            name: 'Bordures',
            content: BorderLayerContent(
              features: <BorderFeature>[_feature('selected')],
            ),
          ),
        ],
      );
      final beforeJson = map.toJson();
      final container = ProviderContainer(
        overrides: <Override>[
          activeBorderFeatureSourceProvider.overrideWithValue(
            (map: map, activeLayerId: 'border-a'),
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(
        container.read(activeBorderFeatureControllerProvider).activeFeatureId,
        'selected',
      );
      expect(map.toJson(), beforeJson);
    });
  });
}

MapData _map({required List<MapLayer> layers}) => MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v2,
      size: const GridSize(width: 4, height: 4),
      layers: layers,
    );

BorderFeature _feature(String id) => BorderFeature(
      id: id,
      name: id,
      blueprintId: 'coast',
      seed: BorderSignedInt64.zero,
      geometry: BorderRegionGeometry(
        width: 4,
        height: 4,
        cells: List<bool>.filled(16, false),
      ),
      overrides: const <BorderSlotOverride>[],
      keepOutRegions: const <BorderKeepOutRegion>[],
    );
