import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('planNativeSmartTileLayerCreation', () {
    test('rejects a manifest map omitted from the project snapshot', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      const omittedLegacy = MapData(
        id: 'legacy',
        name: 'Legacy',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[MapLayer.path(id: 'path', name: 'Path')],
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
          ProjectMapEntry(
            id: 'legacy',
            name: 'Legacy',
            relativePath: 'maps/legacy.json',
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(failure.code, 'smart_tile_project_maps_missing');
      expect(
        failure.message,
        r'projectMaps: missing manifest map ids [legacy].',
      );
      expect(omittedLegacy.layers.single, isA<PathLayer>());
      expect(target.layers, isEmpty);
    });

    test('rejects a project snapshot map absent from the manifest', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      const extra = MapData(
        id: 'extra',
        name: 'Extra',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target, extra],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(failure.code, 'smart_tile_project_maps_extra');
      expect(
        failure.message,
        r'projectMaps: map ids absent from manifest.maps [extra].',
      );
    });

    test('rejects duplicate map ids in the project snapshot', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target, target],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(failure.code, 'smart_tile_project_maps_duplicate');
      expect(failure.message, r'projectMaps: duplicate map ids [target].');
    });

    test('rejects duplicate map ids in the manifest', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target A',
            relativePath: 'maps/target-a.json',
          ),
          ProjectMapEntry(
            id: 'target',
            name: 'Target B',
            relativePath: 'maps/target-b.json',
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(failure.code, 'smart_tile_manifest_maps_duplicate');
      expect(failure.message, r'manifest.maps: duplicate map ids [target].');
    });

    test('returns a structured failure for an invalid field size', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 0, height: 1),
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(failure.code, 'smart_tile_field_size_invalid');
      expect(
        failure.message,
        'Smart Tile field size must be positive; received 0x1.',
      );
    });

    test('rejects an excessive field product before allocating lists', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 2147483648, height: 2147483648),
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
        ],
      );
      late SmartTileLayerCreationResult result;

      expect(
        () => result = planNativeSmartTileLayerCreation(
          projectMaps: const <MapData>[target],
          targetMapId: target.id,
          manifest: manifest,
          preset: _preset(topology: SmartTileTopology.uniform),
          layerId: 'terrain',
          layerName: 'Terrain',
        ),
        returnsNormally,
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(failure.code, 'smart_tile_field_allocation_limit_exceeded');
      expect(failure.message, contains('topology=uniform'));
      expect(failure.message, contains('size=2147483648x2147483648'));
    });

    test('Simple allocates only semantic cells', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 2, height: 3),
      );
      final manifest = _manifestWithMaterials(
        maps: const <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );
      expect(
        result,
        isA<SmartTileLayerCreationSuccess>(),
        reason: result is SmartTileLayerCreationFailure
            ? '${result.code}: ${result.message}'
            : null,
      );
      final success = result as SmartTileLayerCreationSuccess;
      final layer = success.map.layers.single as SmartTileLayer;

      expect(layer.field, isA<SmartTileCellField>());
      expect(smartTileSemanticCells(layer), hasLength(6));
      expect(smartTileHorizontalEdges(layer), isEmpty);
      expect(smartTileVerticalEdges(layer), isEmpty);
      expect(smartTileCorners(layer), isEmpty);
    });

    test('projects the target map and manifest to v5 without mutating inputs',
        () {
      const sourceMap = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 2, height: 2),
      );
      final manifest = _manifestWithMaterials(
        drafts: const <ProjectSmartTileAuthoringDraft>[_draft],
      );
      final preset = _preset(
        topology: SmartTileTopology.cardinal4,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        allowedMaterialIds: const <String>['grass', 'dirt', 'grass'],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[sourceMap],
        targetMapId: sourceMap.id,
        manifest: manifest,
        preset: preset,
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final success = result as SmartTileLayerCreationSuccess;
      final layer = success.map.layers.single as SmartTileLayer;
      expect(sourceMap.layers, isEmpty);
      expect(sourceMap.version, ProjectVersion.v4);
      expect(manifest.version, ProjectVersion.v5);
      expect(success.map.version, ProjectVersion.v5);
      expect(success.manifest.version, ProjectVersion.v5);
      expect(success.manifest.smartTileCatalog.presets, contains(preset));
      expect(
        success.manifest.smartTileCatalog.drafts,
        const <ProjectSmartTileAuthoringDraft>[_draft],
      );
      expect(layer.materialPalette, <String>['', 'grass', 'dirt']);
      expect(
        smartTileSemanticCells(layer),
        <int>[0, 0, 0, 0],
      );
      expect(layer.field, isA<SmartTileCellField>());
    });

    test('rejects a projected catalog with missing material definitions', () {
      const sourceMap = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      const manifest = ProjectManifest(
        name: 'Project',
        version: ProjectVersion.v4,
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[sourceMap],
        targetMapId: sourceMap.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.uniform),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      expect(result, isA<SmartTileLayerCreationFailure>());
      expect(
        (result as SmartTileLayerCreationFailure).code,
        'smart_tile_native_catalog_materials_required',
      );
      expect(sourceMap.layers, isEmpty);
      expect(manifest.smartTileCatalog, isEmpty);
    });

    test('preserves the projected catalog diagnostic code', () {
      const sourceMap = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      final manifest = _manifestWithMaterials();
      final invalidPreset = _preset(
        topology: SmartTileTopology.wang8,
      ).copyWith(
        rules: const <SmartTileRule>[
          SmartTileRule(
            id: 'disallowed-center',
            centerMatch: SmartTileSlotMatch.material('dirt'),
          ),
        ],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[sourceMap],
        targetMapId: sourceMap.id,
        manifest: manifest,
        preset: invalidPreset,
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      final failure = result as SmartTileLayerCreationFailure;
      expect(
        failure.code,
        'smart_tiles.reference.material_not_allowed',
      );
      expect(failure.message, contains('centerMatch.materialId'));
      expect(sourceMap.layers, isEmpty);
      expect(manifest.smartTileCatalog.presets, isEmpty);
    });

    test('refuses legacy in any map and leaves the snapshot untouched', () {
      const target = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
      );
      const legacy = MapData(
        id: 'legacy',
        name: 'Legacy',
        version: ProjectVersion.v4,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[
          MapLayer.path(id: 'path', name: 'Path'),
        ],
      );
      const manifest = ProjectManifest(
        name: 'Project',
        version: ProjectVersion.v4,
        maps: <ProjectMapEntry>[
          ProjectMapEntry(
            id: 'target',
            name: 'Target',
            relativePath: 'maps/target.json',
          ),
          ProjectMapEntry(
            id: 'legacy',
            name: 'Legacy',
            relativePath: 'maps/legacy.json',
          ),
        ],
        tilesets: <ProjectTilesetEntry>[],
      );

      final result = planNativeSmartTileLayerCreation(
        projectMaps: const <MapData>[target, legacy],
        targetMapId: target.id,
        manifest: manifest,
        preset: _preset(topology: SmartTileTopology.cardinal4),
        layerId: 'terrain',
        layerName: 'Terrain',
      );

      expect(result, isA<SmartTileLayerCreationFailure>());
      expect(
        (result as SmartTileLayerCreationFailure).code,
        'smart_tile_legacy_project_unsupported',
      );
      expect(target.layers, isEmpty);
      expect(legacy.layers.single, isA<PathLayer>());
      expect(manifest.version, ProjectVersion.v4);
    });

    test('refuses a second terrain provider', () {
      final existing = MapData(
        id: 'target',
        name: 'Target',
        version: ProjectVersion.v5,
        size: const GridSize(width: 1, height: 1),
        layers: const <MapLayer>[
          MapLayer.smartTile(
            id: 'terrain-1',
            name: 'Terrain 1',
            presetId: 'preset',
            usage: SmartTileUsage.terrain,
            materialPalette: <String>['', 'grass'],
            field: SmartTileField.cell(semanticCells: <int>[1]),
          ),
        ],
      );
      final preset = _preset(topology: SmartTileTopology.cardinal4);
      final manifest = _manifestWithMaterials(presets: <ProjectSmartTilePreset>[
        preset,
      ]);

      final result = planNativeSmartTileLayerCreation(
        projectMaps: <MapData>[existing],
        targetMapId: existing.id,
        manifest: manifest,
        preset: preset,
        layerId: 'terrain-2',
        layerName: 'Terrain 2',
      );

      expect(result, isA<SmartTileLayerCreationFailure>());
      expect(
        (result as SmartTileLayerCreationFailure).code,
        'smart_tile_terrain_provider_already_exists',
      );
    });

    for (final topology in const <SmartTileTopology>[
      SmartTileTopology.wangEdge4,
      SmartTileTopology.wangCorner4,
      SmartTileTopology.wang8,
    ]) {
      for (final boundary in SmartTileBoundaryPolicy.values) {
        test(
            'complete ${topology.name} field initializes active lattices for '
            '${boundary.name}', () {
          const map = MapData(
            id: 'target',
            name: 'Target',
            version: ProjectVersion.v4,
            size: GridSize(width: 2, height: 2),
          );
          final manifest = _manifestWithMaterials();
          final result = planNativeSmartTileLayerCreation(
            projectMaps: const <MapData>[map],
            targetMapId: map.id,
            manifest: manifest,
            preset: _preset(
              topology: topology,
              coveragePolicy: SmartTileCoveragePolicy.complete,
              boundaryPolicy: boundary,
            ),
            layerId: 'terrain',
            layerName: 'Terrain',
          ) as SmartTileLayerCreationSuccess;
          final layer = result.map.layers.single as SmartTileLayer;
          final perimeterValue =
              boundary == SmartTileBoundaryPolicy.connected ? 1 : 0;
          final hasEdges = topology != SmartTileTopology.wangCorner4;
          final hasCorners = topology != SmartTileTopology.wangEdge4;

          expect(smartTileSemanticCells(layer), <int>[1, 1, 1, 1]);
          expect(
            smartTileHorizontalEdges(layer),
            hasEdges
                ? <int>[
                    perimeterValue,
                    perimeterValue,
                    1,
                    1,
                    perimeterValue,
                    perimeterValue,
                  ]
                : isEmpty,
          );
          expect(
            smartTileVerticalEdges(layer),
            hasEdges
                ? <int>[
                    perimeterValue,
                    1,
                    perimeterValue,
                    perimeterValue,
                    1,
                    perimeterValue,
                  ]
                : isEmpty,
          );
          expect(
            smartTileCorners(layer),
            hasCorners
                ? <int>[
                    perimeterValue,
                    perimeterValue,
                    perimeterValue,
                    perimeterValue,
                    1,
                    perimeterValue,
                    perimeterValue,
                    perimeterValue,
                    perimeterValue,
                  ]
                : isEmpty,
          );
        });
      }
    }
  });
}

ProjectManifest _manifestWithMaterials({
  List<ProjectMapEntry> maps = const <ProjectMapEntry>[
    ProjectMapEntry(
      id: 'target',
      name: 'Target',
      relativePath: 'maps/target.json',
    ),
  ],
  List<ProjectSmartTilePreset> presets = const <ProjectSmartTilePreset>[],
  List<ProjectSmartTileAuthoringDraft> drafts =
      const <ProjectSmartTileAuthoringDraft>[],
}) =>
    ProjectManifest(
      name: 'Project',
      version: ProjectVersion.v5,
      maps: maps,
      tilesets: const <ProjectTilesetEntry>[],
      smartTileCatalog: ProjectSmartTileCatalog(
        materials: const <ProjectSmartTileMaterial>[
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
        drafts: drafts,
      ),
    );

const _draft = ProjectSmartTileAuthoringDraft(
  id: 'draft-grass',
  targetPresetId: 'future-grass',
  name: 'Future grass',
  usage: SmartTileUsage.terrain,
  lastStage: SmartTileAuthoringStage.image,
);

ProjectSmartTilePreset _preset({
  required SmartTileTopology topology,
  SmartTileCoveragePolicy coveragePolicy = SmartTileCoveragePolicy.sparse,
  SmartTileBoundaryPolicy boundaryPolicy = SmartTileBoundaryPolicy.empty,
  List<String> allowedMaterialIds = const <String>['grass'],
}) {
  final templateHint = switch (topology) {
    SmartTileTopology.uniform => SmartTileTemplateHint.simple,
    SmartTileTopology.cardinal4 => SmartTileTemplateHint.free,
    SmartTileTopology.blob8 => SmartTileTemplateHint.blob47,
    SmartTileTopology.wangEdge4 => SmartTileTemplateHint.edge16,
    SmartTileTopology.wangCorner4 => SmartTileTemplateHint.corner16,
    SmartTileTopology.wang8 => SmartTileTemplateHint.mixed256,
  };
  final coverageProfile = topology == SmartTileTopology.cardinal4
      ? const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(
              id: 'grass-center',
              centerMaterialId: 'grass',
            ),
          ],
        )
      : const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        );
  return ProjectSmartTilePreset(
    id: 'preset',
    name: 'Preset',
    usage: SmartTileUsage.terrain,
    topology: topology,
    templateHint: templateHint,
    boundaryPolicy: boundaryPolicy,
    coveragePolicy: coveragePolicy,
    coverageProfile: coverageProfile,
    transformPolicy: const SmartTileTransformPolicy(),
    defaultMaterialId: 'grass',
    allowedMaterialIds: allowedMaterialIds,
  );
}
