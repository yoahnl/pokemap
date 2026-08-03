import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileObservedSignature', () {
    const signature = SmartTileObservedSignature(
      northEdge: SmartTileObservedSlot.inside(materialId: 'n'),
      northEastCorner: SmartTileObservedSlot.inside(materialId: 'ne'),
      eastEdge: SmartTileObservedSlot.inside(materialId: 'e'),
      southEastCorner: SmartTileObservedSlot.inside(materialId: 'se'),
      southEdge: SmartTileObservedSlot.inside(materialId: 's'),
      southWestCorner: SmartTileObservedSlot.inside(materialId: 'sw'),
      westEdge: SmartTileObservedSlot.inside(materialId: 'w'),
      northWestCorner: SmartTileObservedSlot.inside(materialId: 'nw'),
    );

    test('mixed signature exposes canonical ordered slots', () {
      expect(
        signature
            .activeSlots(SmartTileTopology.wang8)
            .map((slot) => slot.materialId),
        <String?>['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      );
    });

    test('each topology exposes only its active slots in canonical order', () {
      expect(signature.activeSlots(SmartTileTopology.uniform), isEmpty);
      for (final topology in const <SmartTileTopology>[
        SmartTileTopology.cardinal4,
        SmartTileTopology.wangEdge4,
      ]) {
        expect(
          signature.activeSlots(topology).map((slot) => slot.materialId),
          <String?>['n', 'e', 's', 'w'],
        );
      }
      expect(
        signature
            .activeSlots(SmartTileTopology.wangCorner4)
            .map((slot) => slot.materialId),
        <String?>['ne', 'se', 'sw', 'nw'],
      );
      expect(
        signature
            .activeSlots(SmartTileTopology.blob8)
            .map((slot) => slot.materialId),
        <String?>['n', 'ne', 'e', 'se', 's', 'sw', 'w', 'nw'],
      );
    });
  });

  group('SmartTileCellContext', () {
    test('cell grid distinguishes outside from an empty in-map cell', () {
      final context = SmartTileCellContext.fromCellGrid(
        width: 2,
        height: 1,
        x: 0,
        y: 0,
        materialAt: (x, y) => x == 0 ? 'grass' : null,
      );

      expect(context.centerMaterialId, 'grass');
      expect(context.observed.eastEdge.isInsideMap, isTrue);
      expect(context.observed.eastEdge.materialId, isNull);
      expect(context.observed.westEdge.isInsideMap, isFalse);
      expect(context.observed.westEdge.materialId, isNull);
    });

    test('cell grid rejects a center outside the map', () {
      expect(
        () => SmartTileCellContext.fromCellGrid(
          width: 1,
          height: 1,
          x: 1,
          y: 0,
          materialAt: (_, __) => null,
        ),
        throwsRangeError,
      );
    });

    test('wang8 layer projection preserves all eight named lattices', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'mixed',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>[
          '',
          'center',
          'n',
          'ne',
          'e',
          'se',
          's',
          'sw',
          'w',
          'nw',
        ],
        field: SmartTileField.mixed(
          semanticCells: <int>[1],
          horizontalEdges: <int>[2, 6],
          verticalEdges: <int>[8, 4],
          corners: <int>[9, 3, 7, 5],
        ),
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[layer],
      );
      const preset = ProjectSmartTilePreset(
        id: 'mixed',
        name: 'Mixed',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.wang8,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'center',
        allowedMaterialIds: <String>[
          'center',
          'n',
          'ne',
          'e',
          'se',
          's',
          'sw',
          'w',
          'nw',
        ],
      );

      final context = smartTileCellContextForLayerCell(
        layer: layer,
        map: map,
        preset: preset,
        x: 0,
        y: 0,
      );

      expect(context.centerMaterialId, 'center');
      expect(context.observed.northEdge.materialId, 'n');
      expect(context.observed.northEastCorner.materialId, 'ne');
      expect(context.observed.eastEdge.materialId, 'e');
      expect(context.observed.southEastCorner.materialId, 'se');
      expect(context.observed.southEdge.materialId, 's');
      expect(context.observed.southWestCorner.materialId, 'sw');
      expect(context.observed.westEdge.materialId, 'w');
      expect(context.observed.northWestCorner.materialId, 'nw');
      expect(
        context.observed.activeSlots(preset.topology),
        everyElement(
          isA<SmartTileObservedSlot>()
              .having((slot) => slot.isInsideMap, 'isInsideMap', isTrue),
        ),
      );
    });

    test('wang lattice boundary remains inside when it is empty', () {
      const layer = SmartTileLayer(
        id: 'path',
        name: 'Path',
        presetId: 'edge',
        usage: SmartTileUsage.path,
        materialPalette: <String>['', 'path'],
        field: SmartTileField.edge(
          semanticCells: <int>[1],
          horizontalEdges: <int>[0, 0],
          verticalEdges: <int>[0, 0],
        ),
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[layer],
      );
      const preset = ProjectSmartTilePreset(
        id: 'edge',
        name: 'Edge',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangEdge4,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'path',
        allowedMaterialIds: <String>['path'],
      );

      final context = smartTileCellContextForLayerCell(
        layer: layer,
        map: map,
        preset: preset,
        x: 0,
        y: 0,
      );

      for (final slot in context.observed.activeSlots(preset.topology)) {
        expect(slot.isInsideMap, isTrue);
        expect(slot.materialId, isNull);
      }
    });

    test('layer projection requires the field variant for the topology', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'mixed',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[layer],
      );
      const preset = ProjectSmartTilePreset(
        id: 'mixed',
        name: 'Mixed',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.wang8,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      );

      expect(
        () => smartTileCellContextForLayerCell(
          layer: layer,
          map: map,
          preset: preset,
          x: 0,
          y: 0,
        ),
        throwsArgumentError,
      );
    });

    test('layer projection rejects a cell outside the map', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'uniform',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[layer],
      );
      const preset = ProjectSmartTilePreset(
        id: 'uniform',
        name: 'Uniform',
        usage: SmartTileUsage.terrain,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'grass',
        allowedMaterialIds: <String>['grass'],
      );

      expect(
        () => smartTileCellContextForLayerCell(
          layer: layer,
          map: map,
          preset: preset,
          x: -1,
          y: 0,
        ),
        throwsRangeError,
      );
    });
  });
}
