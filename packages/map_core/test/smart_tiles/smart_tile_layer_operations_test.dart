import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  const mapSize = GridSize(width: 2, height: 2);

  test('map-only Smart Tile creation requires the canonical action', () {
    const map = MapData(
      id: 'map',
      name: 'Map',
      size: mapSize,
      version: ProjectVersion.v6,
    );

    expect(
      () => addSmartTileLayer(
        map,
        id: 'terrain',
        name: 'Terrain',
        presetId: 'preset',
        usage: SmartTileUsage.terrain,
        defaultMaterialId: 'grass',
      ),
      throwsA(
        isA<ValidationException>().having(
          (error) => error.code,
          'code',
          'smart_tile_canonical_layer_action_required',
        ),
      ),
    );
  });

  group('map-only Smart Tile replacement boundary', () {
    final source = _layer(
      const SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
    );

    test('preserves v6 while replacing an existing native layer', () {
      final map = MapData(
        id: 'map',
        name: 'Map',
        size: mapSize,
        version: ProjectVersion.v6,
        layers: <MapLayer>[source],
      );

      final result = replaceSmartTileLayer(
        map,
        layer: source.copyWith(name: 'Normalized'),
      );

      expect(result.version, ProjectVersion.v6);
      expect((result.layers.single as SmartTileLayer).name, 'Normalized');
    });
  });

  group('topology-specific mutation', () {
    test('cell mutation preserves the cell variant', () {
      final source = _layer(
        const SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
      );

      final result = setSmartTileCellMaterial(
        source,
        mapSize: mapSize,
        x: 1,
        y: 0,
        materialId: 'grass',
      );

      expect(result.field, isA<SmartTileCellField>());
      expect(smartTileSemanticCells(result), <int>[0, 1, 0, 0]);
      expect(smartTileHorizontalEdges(result), isEmpty);
      expect(smartTileVerticalEdges(result), isEmpty);
      expect(smartTileCorners(result), isEmpty);
    });

    test('edge mutation preserves both edge lattices and has no corners', () {
      final source = _layer(
        const SmartTileField.edge(
          semanticCells: <int>[0, 0, 0, 0],
          horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
          verticalEdges: <int>[0, 0, 0, 0, 0, 0],
        ),
      );

      final horizontal = setSmartTileHorizontalEdgeMaterial(
        source,
        mapSize: mapSize,
        x: 1,
        y: 2,
        materialId: 'grass',
      );
      final result = setSmartTileVerticalEdgeMaterial(
        horizontal,
        mapSize: mapSize,
        x: 2,
        y: 1,
        materialId: 'grass',
      );

      expect(result.field, isA<SmartTileEdgeField>());
      expect(smartTileHorizontalEdges(result), <int>[0, 0, 0, 0, 0, 1]);
      expect(smartTileVerticalEdges(result), <int>[0, 0, 0, 0, 0, 1]);
      expect(smartTileCorners(result), isEmpty);
    });

    test('corner mutation preserves the corner variant and has no edges', () {
      final source = _layer(
        const SmartTileField.corner(
          semanticCells: <int>[0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );

      final result = setSmartTileCornerMaterial(
        source,
        mapSize: mapSize,
        x: 2,
        y: 2,
        materialId: 'grass',
      );

      expect(result.field, isA<SmartTileCornerField>());
      expect(smartTileCorners(result), <int>[0, 0, 0, 0, 0, 0, 0, 0, 1]);
      expect(smartTileHorizontalEdges(result), isEmpty);
      expect(smartTileVerticalEdges(result), isEmpty);
    });

    test('inactive lattice writes are rejected instead of changing variant',
        () {
      final source = _layer(
        const SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
      );

      expect(
        () => setSmartTileCornerMaterial(
          source,
          mapSize: mapSize,
          x: 0,
          y: 0,
          materialId: 'grass',
        ),
        throwsA(isA<ValidationException>()),
      );
      expect(source.field, isA<SmartTileCellField>());
    });
  });

  group('atomic material gesture projection', () {
    test('projects one cell onto every active edge lattice slot', () {
      final source = _layer(
        const SmartTileField.edge(
          semanticCells: <int>[0, 0, 0, 0],
          horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
          verticalEdges: <int>[0, 0, 0, 0, 0, 0],
        ),
      );

      final result = applySmartTileMaterialGesture(
        source,
        mapSize: mapSize,
        cells: const <GridPos>[GridPos(x: 0, y: 0)],
        materialId: 'grass',
      );

      expect(smartTileSemanticCells(result), <int>[1, 0, 0, 0]);
      expect(smartTileHorizontalEdges(result), <int>[1, 0, 1, 0, 0, 0]);
      expect(smartTileVerticalEdges(result), <int>[1, 1, 0, 0, 0, 0]);
      expect(smartTileCorners(result), isEmpty);
    });

    test('projects one cell onto every active corner lattice slot', () {
      final source = _layer(
        const SmartTileField.corner(
          semanticCells: <int>[0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );

      final result = applySmartTileMaterialGesture(
        source,
        mapSize: mapSize,
        cells: const <GridPos>[GridPos(x: 0, y: 0)],
        materialId: 'grass',
      );

      expect(smartTileSemanticCells(result), <int>[1, 0, 0, 0]);
      expect(smartTileHorizontalEdges(result), isEmpty);
      expect(smartTileVerticalEdges(result), isEmpty);
      expect(smartTileCorners(result), <int>[1, 1, 0, 1, 1, 0, 0, 0, 0]);
    });

    test('mixed projection is duplicate- and order-independent', () {
      final source = _layer(
        const SmartTileField.mixed(
          semanticCells: <int>[0, 0, 0, 0],
          horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
          verticalEdges: <int>[0, 0, 0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );

      final forward = applySmartTileMaterialGesture(
        source,
        mapSize: mapSize,
        cells: const <GridPos>[
          GridPos(x: 0, y: 0),
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        materialId: 'grass',
      );
      final reverse = applySmartTileMaterialGesture(
        source,
        mapSize: mapSize,
        cells: const <GridPos>[
          GridPos(x: 1, y: 0),
          GridPos(x: 0, y: 0),
        ],
        materialId: 'grass',
      );

      expect(forward, reverse);
      expect(smartTileSemanticCells(forward), <int>[1, 1, 0, 0]);
      expect(
        smartTileHorizontalEdges(forward),
        <int>[1, 1, 1, 1, 0, 0],
      );
      expect(smartTileVerticalEdges(forward), <int>[1, 1, 1, 0, 0, 0]);
      expect(smartTileCorners(forward), <int>[1, 1, 1, 1, 1, 1, 0, 0, 0]);
    });

    test('erase clears the same mixed slots and rejects invalid cells', () {
      final source = _layer(
        const SmartTileField.mixed(
          semanticCells: <int>[1, 1, 1, 1],
          horizontalEdges: <int>[1, 1, 1, 1, 1, 1],
          verticalEdges: <int>[1, 1, 1, 1, 1, 1],
          corners: <int>[1, 1, 1, 1, 1, 1, 1, 1, 1],
        ),
      );

      final erased = applySmartTileMaterialGesture(
        source,
        mapSize: mapSize,
        cells: const <GridPos>[GridPos(x: 0, y: 0)],
        materialId: null,
      );

      expect(smartTileSemanticCells(erased), <int>[0, 1, 1, 1]);
      expect(smartTileHorizontalEdges(erased), <int>[0, 1, 0, 1, 1, 1]);
      expect(smartTileVerticalEdges(erased), <int>[0, 0, 1, 1, 1, 1]);
      expect(smartTileCorners(erased), <int>[0, 0, 1, 0, 0, 1, 1, 1, 1]);
      expect(
        () => applySmartTileMaterialGesture(
          source,
          mapSize: mapSize,
          cells: const <GridPos>[GridPos(x: 2, y: 0)],
          materialId: null,
        ),
        throwsRangeError,
      );
      expect(smartTileSemanticCells(source), <int>[1, 1, 1, 1]);
    });
  });

  test('normalization reindexes only active lattices and keeps the variant',
      () {
    final source = _layer(
      const SmartTileField.corner(
        semanticCells: <int>[3, 0, 1, 3],
        corners: <int>[0, 3, 0, 0, 1, 0, 3, 0, 0],
      ),
      materialPalette: const <String>['', 'dirt', 'unused', 'stone'],
    );

    final result = normalizeSmartTileLayer(source);

    expect(result.layer.field, isA<SmartTileCornerField>());
    expect(result.layer.materialPalette, <String>['', 'dirt', 'stone']);
    expect(smartTileSemanticCells(result.layer), <int>[2, 0, 1, 2]);
    expect(
      smartTileCorners(result.layer),
      <int>[0, 2, 0, 0, 1, 0, 2, 0, 0],
    );
    expect(result.removedPaletteEntries.single.materialId, 'unused');
    expect(
        result.reindexedEntryCounts.keys, <String>{'semanticCells', 'corners'});
  });

  group('union', () {
    test('merges compatible fields without materializing inactive grids', () {
      final target = _layer(
        const SmartTileField.cell(semanticCells: <int>[1, 0, 0, 1]),
      );
      final source = _layer(
        const SmartTileField.cell(semanticCells: <int>[0, 1, 0, 0]),
      );

      final result = unionSmartTileLayers(
          target: target, sources: <SmartTileLayer>[source]);

      expect(result.layer.field, isA<SmartTileCellField>());
      expect(smartTileSemanticCells(result.layer), <int>[1, 1, 0, 1]);
      expect(smartTileCorners(result.layer), isEmpty);
      expect(result.mergedEntryCounts, <String, int>{'semanticCells': 1});
    });

    test('rejects fields with different topology storage', () {
      final target = _layer(
        const SmartTileField.cell(semanticCells: <int>[0, 0, 0, 0]),
      );
      final source = _layer(
        const SmartTileField.corner(
          semanticCells: <int>[0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      );

      expect(
        () => unionSmartTileLayers(
          target: target,
          sources: <SmartTileLayer>[source],
        ),
        throwsA(isA<ValidationException>()),
      );
    });
  });

  group('authored lattice inspection', () {
    test('counts authored values across every active lattice', () {
      final layer = _layer(
        const SmartTileField.mixed(
          semanticCells: <int>[1, 0, 0, 0],
          horizontalEdges: <int>[0, 1, 0, 0, 0, 0],
          verticalEdges: <int>[0, 0, 0, 0, 1, 0],
          corners: <int>[0, 0, 0, 0, 1, 0, 0, 0, 0],
        ),
      );

      expect(smartTileAuthoredValueCount(layer), 4);
    });

    test('maps edge and corner lattice values to adjacent map cells', () {
      final edge = _layer(
        const SmartTileField.edge(
          semanticCells: <int>[0, 0],
          horizontalEdges: <int>[0, 1, 0, 0],
          verticalEdges: <int>[0, 0, 0],
        ),
      );
      final corner = _layer(
        const SmartTileField.corner(
          semanticCells: <int>[0, 0],
          corners: <int>[0, 0, 1, 0, 0, 0],
        ),
      );
      const size = GridSize(width: 2, height: 1);

      expect(
        smartTileCellHasAuthoredValue(edge, mapSize: size, x: 0, y: 0),
        isFalse,
      );
      expect(
        smartTileCellHasAuthoredValue(edge, mapSize: size, x: 1, y: 0),
        isTrue,
      );
      expect(
        smartTileCellHasAuthoredValue(corner, mapSize: size, x: 0, y: 0),
        isFalse,
      );
      expect(
        smartTileCellHasAuthoredValue(corner, mapSize: size, x: 1, y: 0),
        isTrue,
      );
    });
  });

  group('resize', () {
    final fields = <SmartTileField>[
      const SmartTileField.cell(semanticCells: <int>[0, 0, 0, 1]),
      const SmartTileField.corner(
        semanticCells: <int>[0, 0, 0, 1],
        corners: <int>[0, 0, 0, 0, 1, 0, 0, 0, 0],
      ),
      const SmartTileField.edge(
        semanticCells: <int>[0, 0, 0, 1],
        horizontalEdges: <int>[0, 0, 0, 1, 0, 0],
        verticalEdges: <int>[0, 0, 0, 0, 1, 0],
      ),
      const SmartTileField.mixed(
        semanticCells: <int>[0, 0, 0, 1],
        horizontalEdges: <int>[0, 0, 0, 1, 0, 0],
        verticalEdges: <int>[0, 0, 0, 0, 1, 0],
        corners: <int>[0, 0, 0, 0, 1, 0, 0, 0, 0],
      ),
    ];

    for (final field in fields) {
      test('${field.runtimeType} creates no inactive grid', () {
        final source = MapData(
          id: 'map',
          name: 'Map',
          version: ProjectVersion.v6,
          size: mapSize,
          layers: <MapLayer>[_layer(field)],
        );

        final result = resizeMapData(source, width: 3, height: 3).layers.single
            as SmartTileLayer;

        expect(result.field.runtimeType, field.runtimeType);
        expect(smartTileSemanticCells(result), hasLength(9));
        expect(
          smartTileHorizontalEdges(result),
          field is SmartTileEdgeField || field is SmartTileMixedField
              ? hasLength(12)
              : isEmpty,
        );
        expect(
          smartTileVerticalEdges(result),
          field is SmartTileEdgeField || field is SmartTileMixedField
              ? hasLength(12)
              : isEmpty,
        );
        expect(
          smartTileCorners(result),
          field is SmartTileCornerField || field is SmartTileMixedField
              ? hasLength(16)
              : isEmpty,
        );
      });
    }
  });
}

SmartTileLayer _layer(
  SmartTileField field, {
  List<String> materialPalette = const <String>['', 'grass'],
}) =>
    MapLayer.smartTile(
      id: 'layer',
      name: 'Layer',
      presetId: 'preset',
      usage: SmartTileUsage.path,
      materialPalette: materialPalette,
      field: field,
    ) as SmartTileLayer;
