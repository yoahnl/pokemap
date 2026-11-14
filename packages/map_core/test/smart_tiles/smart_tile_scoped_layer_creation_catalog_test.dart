import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('scoped native layer creation catalog', () {
    for (final spatial in [false, true]) {
      test(
        'ignores listed presets without their materials, spatial=$spatial',
        () {
          final result = planNativeSmartTileLayerCreationForMap(
            map: _map(spatial: spatial),
            manifest: _manifest(
              spatial: spatial,
              presets: [_preset('listed-only', material: 'shop-floor')],
            ),
            preset: _preset('selected', material: 'dirt'),
            layerId: 'path',
            layerName: 'Path',
          );

          expect(result, isA<SmartTileLayerCreationSuccess>());
          final layer =
              (result as SmartTileLayerCreationSuccess).map.layers.single
                  as SmartTileLayer;
          expect(layer.presetId, 'selected');
          expect(layer.materialPalette, ['', 'dirt']);
        },
      );
    }

    test('still rejects the selected preset when its material is missing', () {
      final result = planNativeSmartTileLayerCreationForMap(
        map: _map(spatial: true),
        manifest: _manifest(spatial: true, presets: const []),
        preset: _preset('selected', material: 'shop-floor'),
        layerId: 'path',
        layerName: 'Path',
      );

      expect(result, isA<SmartTileLayerCreationFailure>());
      expect(
        (result as SmartTileLayerCreationFailure).code,
        'smart_tile_native_catalog_materials_required',
      );
    });

    test(
      'still rejects a selected preset whose material category is missing',
      () {
        final base = _manifest(spatial: false, presets: const []);
        final manifest = base.copyWith(
          smartTileCatalog: ProjectSmartTileCatalog(
            materials: [
              for (final material in base.smartTileCatalog.materials)
                material.id == 'dirt'
                    ? material.copyWith(categoryId: 'missing-category')
                    : material,
            ],
          ),
        );

        final result = planNativeSmartTileLayerCreationForMap(
          map: _map(spatial: false),
          manifest: manifest,
          preset: _preset('selected', material: 'dirt'),
          layerId: 'path',
          layerName: 'Path',
        );

        expect(
          (result as SmartTileLayerCreationFailure).code,
          'smart_tiles.reference.category_missing',
        );
      },
    );
  });
}

MapData _map({required bool spatial}) => MapData(
  id: 'target',
  name: 'Target',
  version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
  size: const GridSize(width: 2, height: 2),
  spatialScene: spatial ? MapSpatialScene(width: 2, depth: 2) : null,
);

ProjectManifest _manifest({
  required bool spatial,
  required List<ProjectSmartTilePreset> presets,
}) => ProjectManifest(
  name: 'Project',
  version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
  maps: const [
    ProjectMapEntry(
      id: 'target',
      name: 'Target',
      relativePath: 'maps/target.json',
    ),
  ],
  tilesets: const [],
  settings: spatial
      ? ProjectSettings(
          dimension: ProjectDimension.threeD,
          spatialCamera: SpatialCameraProfile(),
        )
      : const ProjectSettings(),
  smartTileCatalog: ProjectSmartTileCatalog(
    materials: const [
      ProjectSmartTileMaterial(
        id: 'grass',
        name: 'Grass',
        connectionGroupId: 'ground',
      ),
      ProjectSmartTileMaterial(
        id: 'dirt',
        name: 'Dirt',
        connectionGroupId: 'ground',
      ),
    ],
    presets: presets,
  ),
);

ProjectSmartTilePreset _preset(String id, {required String material}) =>
    ProjectSmartTilePreset(
      id: id,
      name: id,
      usage: SmartTileUsage.path,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      boundaryPolicy: SmartTileBoundaryPolicy.empty,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: const SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: material,
      allowedMaterialIds: [material],
    );
