import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const emptyMap = MapData(
    id: 'hanazuki',
    name: 'Hanazuki',
    version: ProjectVersion.v3,
    size: GridSize(width: 2, height: 2),
  );

  group('addSmartTileLayer', () {
    test('creates the single fully-covered terrain provider and upgrades to v4',
        () {
      final updated = addSmartTileLayer(
        emptyMap,
        id: 'base',
        name: 'Terrain',
        presetId: 'han_grass',
        usage: SmartTileUsage.terrain,
        defaultMaterialId: 'grass',
        layerSeed: 7,
      );
      final layer = updated.layers.single as SmartTileLayer;

      expect(updated.version, ProjectVersion.v4);
      expect(layer.materialPalette, <String>['', 'grass']);
      expect(layer.materialCells, <int>[1, 1, 1, 1]);
      expect(layer.horizontalEdges, hasLength(6));
      expect(layer.verticalEdges, hasLength(6));
      expect(layer.corners, hasLength(9));
      expect(layer.layerSeed, 7);

      expect(
        () => addSmartTileLayer(
          updated,
          id: 'base_2',
          name: 'Terrain 2',
          presetId: 'han_grass',
          usage: SmartTileUsage.terrain,
          defaultMaterialId: 'grass',
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('creates sparse path and forest layers', () {
      for (final usage in <SmartTileUsage>[
        SmartTileUsage.path,
        SmartTileUsage.forestSurface,
      ]) {
        final updated = addSmartTileLayer(
          emptyMap,
          id: usage.name,
          name: usage.name,
          presetId: 'preset',
          usage: usage,
          defaultMaterialId: 'material',
        );
        final layer = updated.layers.single as SmartTileLayer;
        expect(layer.materialCells, everyElement(0));
      }
    });
  });

  group('Smart Tile paint storage', () {
    late SmartTileLayer layer;

    setUp(() {
      layer = (addSmartTileLayer(
        emptyMap,
        id: 'path',
        name: 'Path',
        presetId: 'han_path',
        usage: SmartTileUsage.path,
        defaultMaterialId: 'dirt',
      ).layers.single as SmartTileLayer);
    });

    test('interns materials and paints cell indices immutably', () {
      final first = setSmartTileCellMaterial(
        layer,
        mapSize: emptyMap.size,
        x: 1,
        y: 0,
        materialId: 'dirt',
      );
      final second = setSmartTileCellMaterial(
        first,
        mapSize: emptyMap.size,
        x: 0,
        y: 1,
        materialId: 'grass',
      );

      expect(layer.materialPalette, <String>['', 'dirt']);
      expect(layer.materialCells, everyElement(0));
      expect(first.materialPalette, <String>['', 'dirt']);
      expect(first.materialCells, <int>[0, 1, 0, 0]);
      expect(second.materialPalette, <String>['', 'dirt', 'grass']);
      expect(second.materialCells, <int>[0, 1, 2, 0]);
      expect(
        smartTileMaterialIdAt(
          second,
          mapSize: emptyMap.size,
          x: 0,
          y: 1,
        ),
        'grass',
      );
    });

    test('uses the documented horizontal, vertical, and corner grids', () {
      final horizontal = setSmartTileHorizontalEdgeMaterial(
        layer,
        mapSize: emptyMap.size,
        x: 1,
        y: 2,
        materialId: 'grass',
      );
      final vertical = setSmartTileVerticalEdgeMaterial(
        horizontal,
        mapSize: emptyMap.size,
        x: 2,
        y: 1,
        materialId: 'grass',
      );
      final corner = setSmartTileCornerMaterial(
        vertical,
        mapSize: emptyMap.size,
        x: 2,
        y: 2,
        materialId: 'grass',
      );

      expect(horizontal.horizontalEdges, <int>[0, 0, 0, 0, 0, 2]);
      expect(vertical.verticalEdges, <int>[0, 0, 0, 0, 0, 2]);
      expect(corner.corners, <int>[0, 0, 0, 0, 0, 0, 0, 0, 2]);
    });
  });

  test('resizeMapData preserves the overlapping Smart Tile lattices', () {
    var layer = (addSmartTileLayer(
      emptyMap,
      id: 'path',
      name: 'Path',
      presetId: 'han_path',
      usage: SmartTileUsage.path,
      defaultMaterialId: 'dirt',
    ).layers.single as SmartTileLayer);
    layer = setSmartTileCellMaterial(
      layer,
      mapSize: emptyMap.size,
      x: 1,
      y: 1,
      materialId: 'dirt',
    );
    layer = setSmartTileHorizontalEdgeMaterial(
      layer,
      mapSize: emptyMap.size,
      x: 1,
      y: 1,
      materialId: 'dirt',
    );
    layer = setSmartTileVerticalEdgeMaterial(
      layer,
      mapSize: emptyMap.size,
      x: 1,
      y: 1,
      materialId: 'dirt',
    );
    layer = setSmartTileCornerMaterial(
      layer,
      mapSize: emptyMap.size,
      x: 1,
      y: 1,
      materialId: 'dirt',
    );
    final source = emptyMap.copyWith(
      version: ProjectVersion.v4,
      layers: <MapLayer>[layer],
    );

    final resized = resizeMapData(source, width: 3, height: 3);
    final result = resized.layers.single as SmartTileLayer;

    expect(result.materialCells, hasLength(9));
    expect(result.materialCells[4], 1);
    expect(result.horizontalEdges, hasLength(12));
    expect(result.horizontalEdges[4], 1);
    expect(result.verticalEdges, hasLength(12));
    expect(result.verticalEdges[5], 1);
    expect(result.corners, hasLength(16));
    expect(result.corners[5], 1);
  });

  group('SmartTileLayer validation', () {
    MapData mapWith(SmartTileLayer layer) => emptyMap.copyWith(
          version: ProjectVersion.v4,
          layers: <MapLayer>[layer],
        );

    SmartTileLayer validLayer() => addSmartTileLayer(
          emptyMap,
          id: 'path',
          name: 'Path',
          presetId: 'han_path',
          usage: SmartTileUsage.path,
          defaultMaterialId: 'dirt',
        ).layers.single as SmartTileLayer;

    test('rejects invalid array lengths and palette indices', () {
      final valid = validLayer();
      expect(
        () => MapValidator.validate(
          mapWith(valid.copyWith(materialCells: const <int>[0])),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(
          mapWith(
            valid.copyWith(materialCells: const <int>[0, 0, 0, 99]),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('rejects empty terrain coverage and duplicate terrain providers', () {
      final terrain = addSmartTileLayer(
        emptyMap,
        id: 'terrain',
        name: 'Terrain',
        presetId: 'han_grass',
        usage: SmartTileUsage.terrain,
        defaultMaterialId: 'grass',
      ).layers.single as SmartTileLayer;

      expect(
        () => MapValidator.validate(
          mapWith(
            terrain.copyWith(materialCells: const <int>[1, 1, 0, 1]),
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(
        () => MapValidator.validate(
          emptyMap.copyWith(
            version: ProjectVersion.v4,
            layers: <MapLayer>[
              terrain,
              terrain.copyWith(id: 'terrain_2'),
            ],
          ),
        ),
        throwsA(isA<ValidationException>()),
      );
    });

    test('validates preset existence and usage against project context', () {
      final layer = validLayer();
      final manifest = ProjectManifest(
        name: 'Project',
        version: ProjectVersion.v4,
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        smartTileCatalog: ProjectSmartTileCatalog(
          materials: const <ProjectSmartTileMaterial>[
            ProjectSmartTileMaterial(
              id: 'dirt',
              name: 'Dirt',
              connectionGroupId: 'dirt',
            ),
          ],
          presets: const <ProjectSmartTilePreset>[
            ProjectSmartTilePreset(
              id: 'han_path',
              name: 'Han path',
              usage: SmartTileUsage.terrain,
              topology: SmartTileTopology.cardinal4,
              defaultMaterialId: 'dirt',
              allowedMaterialIds: <String>['dirt'],
            ),
          ],
        ),
      );

      expect(
        () => MapValidator.validate(
          mapWith(layer),
          projectDialogueContext: manifest,
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('usage'),
          ),
        ),
      );
    });
  });
}
