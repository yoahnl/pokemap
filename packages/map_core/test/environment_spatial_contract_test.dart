import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'palette identities are exclusive and preserve typed model references',
    () {
      final item = EnvironmentPaletteItem(
        modelId: 'tree',
        weight: 3,
        cellOffsetWorld: Model3dVector3(x: -.5, y: .1875, z: .75),
        collisionMode: EnvironmentCollisionMode.forceDisabled,
      );
      expect(item.visualKind, EnvironmentVisualKind.model3d);
      expect(item.resourceId, 'tree');
      expect(
        decodeEnvironmentPaletteItem(encodeEnvironmentPaletteItem(item)),
        item,
      );
      expect(encodeEnvironmentPaletteItem(item), isNot(contains('elementId')));
      for (final value in [
        {'weight': 1},
        {'elementId': 'tree', 'modelId': 'tree', 'weight': 1},
        {'modelId': null, 'weight': 1},
        {'modelId': 'tree', 'weight': 1, 'unknown': true},
        {
          'elementId': 'tree',
          'weight': 1,
          'cellOffsetWorld': {'x': 0, 'y': 0, 'z': 0},
        },
        {
          'modelId': 'tree',
          'weight': 1,
          'cellOffsetWorld': {'x': 0, 'y': 0, 'z': 0, 'extra': 1},
        },
        {
          'modelId': 'tree',
          'weight': 1,
          'cellOffsetWorld': {'x': double.nan, 'y': 0, 'z': 0},
        },
        {'modelId': 'tree', 'weight': 1, 'cellOffsetWorld': 1},
      ]) {
        expect(
          () => decodeEnvironmentPaletteItem(value),
          throwsFormatException,
        );
      }
    },
  );

  test(
    'automatic ownership IDs preserve canonical anchor cells independently of world offsets',
    () {
      const anchor = GridPos(x: 4, y: 1);
      final id = environmentSpatialPlacementId(
        layerId: 'env',
        areaId: 'forest',
        modelId: 'tree',
        anchor: anchor,
      );
      expect(
        environmentSpatialPlacementAnchor(
          placementId: id,
          layerId: 'env',
          areaId: 'forest',
          modelId: 'tree',
        ),
        anchor,
      );
      expect(
        () => environmentSpatialPlacementAnchor(
          placementId: id,
          layerId: 'other',
          areaId: 'forest',
          modelId: 'tree',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => environmentSpatialPlacementAnchor(
          placementId: id,
          layerId: 'env',
          areaId: 'forest',
          modelId: 'other',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => environmentSpatialPlacementAnchor(
          placementId: 'free-id',
          layerId: 'env',
          areaId: 'forest',
          modelId: 'tree',
        ),
        throwsA(isA<ValidationException>()),
      );
    },
  );

  test('presets reject mixed dimensions and layers reject mixed surfaces', () {
    expect(
      () => EnvironmentPreset(
        id: 'forest',
        name: 'Forest',
        templateId: 'forest',
        palette: [
          EnvironmentPaletteItem(elementId: 'tree', weight: 1),
          EnvironmentPaletteItem(modelId: 'tree', weight: 1),
        ],
        defaultParams: EnvironmentGenerationParams.standard(),
        sortOrder: 0,
      ),
      throwsArgumentError,
    );
    expect(
      () => EnvironmentLayerContent(
        targetTileLayerId: 'ground',
        targetsSpatialTerrain: true,
      ),
      throwsArgumentError,
    );
    expect(
      () => decodeEnvironmentLayerContent({'targetsSpatialTerrain': 'true'}),
      throwsFormatException,
    );
    expect(
      () => EnvironmentGenerationParams(
        density: double.nan,
        variation: 0,
        edgeDensity: 1,
        minSpacingCells: 0,
      ),
      throwsArgumentError,
    );
  });

  test(
    'spatial ownership and manual overrides roundtrip without instance format changes',
    () {
      final area = EnvironmentArea(
        id: 'forest',
        name: 'Forest',
        presetId: 'trees',
        mask: EnvironmentAreaMask(
          width: 2,
          height: 2,
          cells: List.filled(4, true),
        ),
        seed: 7,
        generatedPlacementIds: ['tree'],
        manualPlacementIds: ['tree'],
      );
      final content = EnvironmentLayerContent(
        targetsSpatialTerrain: true,
        areas: [area],
      );
      expect(content.targetKind, EnvironmentTargetKind.spatialTerrain);
      expect(
        decodeEnvironmentLayerContent(encodeEnvironmentLayerContent(content)),
        content,
      );
      expect(
        () => EnvironmentArea(
          id: 'forest',
          name: 'Forest',
          presetId: 'trees',
          mask: area.mask,
          seed: 7,
          manualPlacementIds: ['unowned'],
        ),
        throwsArgumentError,
      );
    },
  );
}
