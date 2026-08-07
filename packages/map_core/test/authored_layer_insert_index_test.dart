import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

/// A canonical map serializes its stack front-first, so `layers.first` paints
/// in front. A legacy `bottom_to_top` map serializes back-first.
MapData _canonicalMap(List<String> layerIds) => MapData(
      id: 'target',
      name: 'Target',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: <MapLayer>[
        for (final id in layerIds)
          MapLayer.tile(
            id: id,
            name: id,
            cells: const <int>[0],
          ),
      ],
    );

MapData _legacyBottomToTopMap(List<String> layerIds) => MapData(
      id: 'target',
      name: 'Target',
      version: ProjectVersion.v6,
      size: const GridSize(width: 1, height: 1),
      properties: const <String, dynamic>{'tileLayerOrder': 'bottom_to_top'},
      layers: <MapLayer>[
        for (final id in layerIds)
          MapLayer.tile(
            id: id,
            name: id,
            cells: const <int>[0],
          ),
      ],
    );

void main() {
  group('resolveAuthoredLayerInsertIndex', () {
    test('places a new layer in front of the active one on a front-first map',
        () {
      final map = _canonicalMap(<String>['top', 'middle', 'bottom']);

      final index = resolveAuthoredLayerInsertIndex(
        map,
        activeLayerId: 'middle',
      );

      // Front-first: inserting at the active index pushes the active layer
      // back by one, so the new layer lands directly in front of it.
      expect(index, 1);
    });

    test('places a new layer in front of the active one on a back-first map',
        () {
      final map = _legacyBottomToTopMap(<String>['bottom', 'middle', 'top']);

      final index = resolveAuthoredLayerInsertIndex(
        map,
        activeLayerId: 'middle',
      );

      // Back-first: "in front" is the higher index, so the new layer goes
      // immediately after the active one.
      expect(index, 2);
    });

    test('falls back to the very front when no layer is active', () {
      expect(
        resolveAuthoredLayerInsertIndex(
          _canonicalMap(<String>['top', 'bottom']),
          activeLayerId: null,
        ),
        0,
      );
      expect(
        resolveAuthoredLayerInsertIndex(
          _legacyBottomToTopMap(<String>['bottom', 'top']),
          activeLayerId: null,
        ),
        2,
      );
    });

    test('falls back to the very front when the active layer is unknown', () {
      expect(
        resolveAuthoredLayerInsertIndex(
          _canonicalMap(<String>['top', 'bottom']),
          activeLayerId: 'deleted-layer',
        ),
        0,
      );
    });

    test('sends a background layer to the very back on either convention', () {
      expect(
        resolveAuthoredLayerInsertIndex(
          _canonicalMap(<String>['top', 'bottom']),
          activeLayerId: 'top',
          sendToBack: true,
        ),
        2,
      );
      expect(
        resolveAuthoredLayerInsertIndex(
          _legacyBottomToTopMap(<String>['bottom', 'top']),
          activeLayerId: 'top',
          sendToBack: true,
        ),
        0,
      );
    });

    test('handles an empty stack', () {
      expect(
        resolveAuthoredLayerInsertIndex(
          _canonicalMap(const <String>[]),
          activeLayerId: null,
        ),
        0,
      );
      expect(
        resolveAuthoredLayerInsertIndex(
          _canonicalMap(const <String>[]),
          activeLayerId: null,
          sendToBack: true,
        ),
        0,
      );
    });
  });

  group('planNativeSmartTileLayerCreation insertIndex', () {
    test('appends the new Smart Tile layer when no index is given', () {
      final map = _canonicalMap(<String>['front', 'back']);

      final result = planNativeSmartTileLayerCreation(
        projectMaps: <MapData>[map],
        targetMapId: map.id,
        manifest: _manifest(),
        preset: _preset(),
        layerId: 'smart',
        layerName: 'Smart',
      ) as SmartTileLayerCreationSuccess;

      expect(
        result.map.layers.map((layer) => layer.id),
        <String>['front', 'back', 'smart'],
      );
    });

    test('honours an explicit insert index', () {
      final map = _canonicalMap(<String>['front', 'back']);

      final result = planNativeSmartTileLayerCreation(
        projectMaps: <MapData>[map],
        targetMapId: map.id,
        manifest: _manifest(),
        preset: _preset(),
        layerId: 'smart',
        layerName: 'Smart',
        insertIndex: 1,
      ) as SmartTileLayerCreationSuccess;

      expect(
        result.map.layers.map((layer) => layer.id),
        <String>['front', 'smart', 'back'],
      );
    });

    test('clamps an out-of-range insert index', () {
      final map = _canonicalMap(<String>['front', 'back']);

      final tooLow = planNativeSmartTileLayerCreation(
        projectMaps: <MapData>[map],
        targetMapId: map.id,
        manifest: _manifest(),
        preset: _preset(),
        layerId: 'smart',
        layerName: 'Smart',
        insertIndex: -5,
      ) as SmartTileLayerCreationSuccess;
      final tooHigh = planNativeSmartTileLayerCreation(
        projectMaps: <MapData>[map],
        targetMapId: map.id,
        manifest: _manifest(),
        preset: _preset(),
        layerId: 'smart',
        layerName: 'Smart',
        insertIndex: 99,
      ) as SmartTileLayerCreationSuccess;

      expect(tooLow.map.layers.first.id, 'smart');
      expect(tooHigh.map.layers.last.id, 'smart');
    });
  });
}

ProjectSmartTilePreset _preset() => const ProjectSmartTilePreset(
      id: 'preset',
      name: 'Preset',
      usage: SmartTileUsage.terrain,
      topology: SmartTileTopology.uniform,
      templateHint: SmartTileTemplateHint.simple,
      coveragePolicy: SmartTileCoveragePolicy.sparse,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.template,
      ),
      transformPolicy: SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: <String>['grass'],
    );

ProjectManifest _manifest() => ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v6,
      maps: const <ProjectMapEntry>[
        ProjectMapEntry(
          id: 'target',
          name: 'Target',
          relativePath: 'maps/target.json',
        ),
      ],
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
          ProjectSmartTileMaterial(
            id: 'grass',
            name: 'Grass',
            connectionGroupId: 'ground',
          ),
        ],
      ),
    );
