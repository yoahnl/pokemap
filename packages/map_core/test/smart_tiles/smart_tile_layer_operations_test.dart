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

  group('Smart Tile palette normalization', () {
    test('removes unused materials and preserves all four semantic lattices',
        () {
      final layer = _smartLayer(
        id: 'path',
        name: 'Path metadata',
        isVisible: false,
        opacity: 0.35,
        presetId: 'han_path',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt', 'unused', 'stone'],
        materialCells: const [3, 0, 1, 3],
        horizontalEdges: const [0, 3, 0, 1, 0, 3],
        verticalEdges: const [3, 0, 0, 1, 3, 0],
        corners: const [0, 3, 0, 0, 1, 0, 3, 0, 0],
        layerSeed: 97,
        properties: const {'role': 'main_path', 'note': 'keep'},
      );
      final semanticBefore = _semanticLattices(layer);

      final result = normalizeSmartTileLayer(layer);

      expect(result.layer.materialPalette, ['', 'dirt', 'stone']);
      expect(result.layer.materialCells, [2, 0, 1, 2]);
      expect(result.layer.horizontalEdges, [0, 2, 0, 1, 0, 2]);
      expect(result.layer.verticalEdges, [2, 0, 0, 1, 2, 0]);
      expect(result.layer.corners, [0, 2, 0, 0, 1, 0, 2, 0, 0]);
      expect(_semanticLattices(result.layer), semanticBefore);
      expect(
        result.removedPaletteEntries.map((entry) => entry.toJson()).toList(),
        [
          {'materialId': 'unused', 'oldIndex': 2},
        ],
      );
      expect(result.reindexedEntryCounts, {
        'materialCells': 2,
        'horizontalEdges': 2,
        'verticalEdges': 2,
        'corners': 2,
      });
      expect(result.reindexedEntryCount, 8);

      expect(result.layer.id, layer.id);
      expect(result.layer.name, layer.name);
      expect(result.layer.isVisible, layer.isVisible);
      expect(result.layer.opacity, layer.opacity);
      expect(result.layer.presetId, layer.presetId);
      expect(result.layer.usage, layer.usage);
      expect(result.layer.layerSeed, layer.layerSeed);
      expect(result.layer.properties, layer.properties);
    });

    test('is idempotent once the palette is canonical', () {
      final layer = _smartLayer(
        id: 'path',
        name: 'Path',
        presetId: 'han_path',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt', 'unused'],
        materialCells: const [1, 0, 0, 0],
        horizontalEdges: const [0, 0, 0, 0, 0, 0],
        verticalEdges: const [0, 0, 0, 0, 0, 0],
        corners: const [0, 0, 0, 0, 0, 0, 0, 0, 0],
      );

      final once = normalizeSmartTileLayer(layer).layer;
      final twice = normalizeSmartTileLayer(once);

      expect(twice.layer, once);
      expect(twice.removedPaletteEntries, isEmpty);
      expect(twice.reindexedEntryCount, 0);
    });
  });

  group('Smart Tile layer union', () {
    test('unites crossing paths and every edge/corner lattice', () {
      final target = _smartLayer(
        id: 'path_dirt',
        name: 'Target metadata',
        isVisible: false,
        opacity: 0.6,
        presetId: 'path_preset',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt'],
        materialCells: const [0, 0, 0, 1, 1, 1, 0, 0, 0],
        horizontalEdges: const [0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        verticalEdges: const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        corners: const [0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
        layerSeed: 11,
        properties: const {'role': 'primary'},
      );
      final source = _smartLayer(
        id: 'path_compacted',
        name: 'Source',
        presetId: 'path_preset',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt'],
        materialCells: const [0, 1, 0, 0, 1, 0, 0, 1, 0],
        horizontalEdges: const [0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0],
        verticalEdges: const [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0],
        corners: const [0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1],
      );

      final result = unionSmartTileLayers(
        target: target,
        sources: [source],
      );

      expect(result.layer.materialPalette, ['', 'dirt']);
      expect(result.layer.materialCells, [0, 1, 0, 1, 1, 1, 0, 1, 0]);
      expect(result.layer.horizontalEdges[1], 1);
      expect(result.layer.horizontalEdges[9], 1);
      expect(result.layer.verticalEdges[4], 1);
      expect(result.layer.corners[5], 1);
      expect(result.layer.corners[15], 1);
      expect(result.mergedEntryCounts, {
        'materialCells': 2,
        'horizontalEdges': 1,
        'verticalEdges': 1,
        'corners': 2,
      });
      expect(result.mergedEntryCount, 6);

      expect(result.layer.id, target.id);
      expect(result.layer.name, target.name);
      expect(result.layer.isVisible, target.isVisible);
      expect(result.layer.opacity, target.opacity);
      expect(result.layer.presetId, target.presetId);
      expect(result.layer.usage, target.usage);
      expect(result.layer.layerSeed, target.layerSeed);
      expect(result.layer.properties, target.properties);
    });

    test('rejects an ambiguous non-empty material conflict', () {
      final target = _smartLayer(
        id: 'target',
        name: 'Target',
        presetId: 'path_preset',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'dirt'],
        materialCells: const [1],
        horizontalEdges: const [0, 0],
        verticalEdges: const [0, 0],
        corners: const [0, 0, 0, 0],
      );
      final source = _smartLayer(
        id: 'source',
        name: 'Source',
        presetId: 'path_preset',
        usage: SmartTileUsage.path,
        materialPalette: const ['', 'stone'],
        materialCells: const [1],
        horizontalEdges: const [0, 0],
        verticalEdges: const [0, 0],
        corners: const [0, 0, 0, 0],
      );

      expect(
        () => unionSmartTileLayers(target: target, sources: [source]),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            allOf(contains('materialCells[0]'), contains('source')),
          ),
        ),
      );
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

SmartTileLayer _smartLayer({
  required String id,
  required String name,
  bool isVisible = true,
  double opacity = 1,
  required String presetId,
  required SmartTileUsage usage,
  required List<String> materialPalette,
  required List<int> materialCells,
  required List<int> horizontalEdges,
  required List<int> verticalEdges,
  required List<int> corners,
  int layerSeed = 0,
  Map<String, String> properties = const {},
}) =>
    MapLayer.smartTile(
      id: id,
      name: name,
      isVisible: isVisible,
      opacity: opacity,
      presetId: presetId,
      usage: usage,
      materialPalette: materialPalette,
      materialCells: materialCells,
      horizontalEdges: horizontalEdges,
      verticalEdges: verticalEdges,
      corners: corners,
      layerSeed: layerSeed,
      properties: properties,
    ) as SmartTileLayer;

Map<String, List<String?>> _semanticLattices(SmartTileLayer layer) => {
      'materialCells': _semanticValues(layer, layer.materialCells),
      'horizontalEdges': _semanticValues(layer, layer.horizontalEdges),
      'verticalEdges': _semanticValues(layer, layer.verticalEdges),
      'corners': _semanticValues(layer, layer.corners),
    };

List<String?> _semanticValues(SmartTileLayer layer, List<int> values) => [
      for (final index in values)
        if (index == 0) null else layer.materialPalette[index],
    ];
