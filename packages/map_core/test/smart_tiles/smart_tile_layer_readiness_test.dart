import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('unassigned and intentional empty remain distinct', () {
    const layer = SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass', 'void'],
      field: SmartTileField.cell(semanticCells: <int>[0, 2]),
    );
    final report = analyzeSmartTileLayerReadiness(
      map: _mapWith(layer),
      layer: layer,
      preset: _terrainPreset(),
      materials: _materials,
    );

    expect(report.unassignedCellCount, 1);
    expect(report.intentionalEmptyCellCount, 1);
    expect(report.unresolvedCellCount, 0);
    expect(report.hasErrors, isTrue);
    expect(
      report.diagnostics.map((item) => item.code),
      contains('smart_tiles.layer.unassigned_cell'),
    );
  });

  test('sparse empty cells are ready for terrain and path layers', () {
    for (final usage in <SmartTileUsage>[
      SmartTileUsage.terrain,
      SmartTileUsage.path,
    ]) {
      final layer = SmartTileLayer(
        id: '${usage.name}-layer',
        name: usage.name,
        presetId: '${usage.name}-preset',
        usage: usage,
        materialPalette: const <String>[''],
        field: const SmartTileField.cell(semanticCells: <int>[0, 0]),
      );
      final preset = _terrainPreset(
        id: layer.presetId,
        usage: usage,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
      );
      expect(
        () => _validateStructure(
          layer: layer,
          preset: preset,
          size: const GridSize(width: 2, height: 1),
        ),
        returnsNormally,
        reason: usage.name,
      );
      final report = analyzeSmartTileLayerReadiness(
        map: _mapWith(layer),
        layer: layer,
        preset: preset,
        materials: _materials,
      );

      expect(report.unassignedCellCount, 2, reason: usage.name);
      expect(report.unresolvedCellCount, 0, reason: usage.name);
      expect(report.hasErrors, isFalse, reason: usage.name);
    }
  });

  test('intent without a matching rule is contextualized as unresolved', () {
    const layer = SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1]),
    );
    final report = analyzeSmartTileLayerReadiness(
      map: _mapWith(
        layer,
        size: const GridSize(width: 1, height: 1),
      ),
      layer: layer,
      preset: _terrainPreset(rules: const <SmartTileRule>[]),
      materials: _materials,
    );

    expect(report.unresolvedCellCount, 1);
    expect(report.hasErrors, isTrue);
    expect(report.diagnostics, hasLength(1));
    expect(report.diagnostics.single.code, 'smart_tiles.layer.unresolved_cell');
    expect(
      report.diagnostics.single.path,
      r'$.maps["map"].layers["terrain"].cells[0,0]',
    );
    expect(report.diagnostics.single.presetId, 'terrain');
    expect(
      () => report.diagnostics.add(report.diagnostics.single),
      throwsUnsupportedError,
    );
  });

  test('Wang lattice intent is resolved even over an intentional empty cell',
      () {
    const layer = SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'void', 'grass'],
      field: SmartTileField.edge(
        semanticCells: <int>[1],
        horizontalEdges: <int>[2, 0],
        verticalEdges: <int>[0, 0],
      ),
    );
    final report = analyzeSmartTileLayerReadiness(
      map: _mapWith(
        layer,
        size: const GridSize(width: 1, height: 1),
      ),
      layer: layer,
      preset: _terrainPreset(
        topology: SmartTileTopology.wangEdge4,
        rules: const <SmartTileRule>[],
      ),
      materials: _materials,
    );

    expect(report.intentionalEmptyCellCount, 1);
    expect(report.unresolvedCellCount, 1);
    expect(
      report.diagnostics.single.code,
      'smart_tiles.layer.unresolved_cell',
    );
  });

  test('fallback-only readiness follows the persisted profile', () {
    const layer = SmartTileLayer(
      id: 'terrain',
      name: 'Terrain',
      presetId: 'terrain',
      usage: SmartTileUsage.terrain,
      materialPalette: <String>['', 'grass'],
      field: SmartTileField.cell(semanticCells: <int>[1]),
    );
    const fallback = SmartTileRule(
      id: 'fallback',
      centerMatch: SmartTileSlotMatch.any(),
      candidates: <SmartTileCandidate>[
        SmartTileCandidate(id: 'fallback'),
      ],
    );

    SmartTileLayerReadinessReport analyze(bool allowFallback) =>
        analyzeSmartTileLayerReadiness(
          map: _mapWith(
            layer,
            size: const GridSize(width: 1, height: 1),
          ),
          layer: layer,
          preset: _terrainPreset(
            rules: const <SmartTileRule>[fallback],
            fallbackRuleId: fallback.id,
            allowFallback: allowFallback,
          ),
          materials: _materials,
        );

    final forbidden = analyze(false);
    final allowed = analyze(true);
    expect(forbidden.unresolvedCellCount, 1);
    expect(
      forbidden.diagnostics.single.code,
      'smart_tiles.layer.fallback_only',
    );
    expect(allowed.unresolvedCellCount, 0);
    expect(allowed.hasErrors, isFalse);
  });

  group('Smart Tile structural validation', () {
    test('rejects a palette index outside the layer palette', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[2]),
      );

      expect(
        () => _validateStructure(
          layer: layer,
          preset: _terrainPreset(),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('invalid material palette index 2'),
          ),
        ),
      );
    });

    test('rejects incorrect field lattice sizes', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.edge(
          semanticCells: <int>[1],
          horizontalEdges: <int>[1],
          verticalEdges: <int>[1, 1],
        ),
      );

      expect(
        () => _validateStructure(
          layer: layer,
          preset: _terrainPreset(topology: SmartTileTopology.wangEdge4),
        ),
        throwsA(
          isA<ValidationException>().having(
            (error) => error.message,
            'message',
            contains('invalid horizontalEdges count: expected 2, got 1'),
          ),
        ),
      );
    });

    test('reports both terrain provider ids', () {
      const first = SmartTileLayer(
        id: 'terrain-a',
        name: 'Terrain A',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      const second = SmartTileLayer(
        id: 'terrain-b',
        name: 'Terrain B',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass'],
        field: SmartTileField.cell(semanticCells: <int>[1]),
      );
      const map = MapData(
        id: 'map',
        name: 'Map',
        version: ProjectVersion.v6,
        size: GridSize(width: 1, height: 1),
        layers: <MapLayer>[first, second],
      );

      expect(
        () => MapValidator.validate(map),
        throwsA(
          isA<ValidationException>()
              .having(
                (error) => error.code,
                'code',
                'smart_tile_terrain_provider_already_exists',
              )
              .having(
                (error) => error.message,
                'message',
                allOf(contains('terrain-a'), contains('terrain-b')),
              )
              .having(
            (error) => error.details['layerIds'],
            'layerIds',
            <String>['terrain-a', 'terrain-b'],
          ),
        ),
      );
    });

    test('accepts a multi-material uniform terrain', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass', 'dirt'],
        field: SmartTileField.cell(semanticCells: <int>[1, 2]),
      );

      expect(
        () => _validateStructure(
          layer: layer,
          preset: _terrainPreset(
            allowedMaterialIds: const <String>['grass', 'dirt', 'void'],
          ),
          size: const GridSize(width: 2, height: 1),
        ),
        returnsNormally,
      );
    });

    test('accepts a matching multi-material Wang terrain field', () {
      const layer = SmartTileLayer(
        id: 'terrain',
        name: 'Terrain',
        presetId: 'terrain',
        usage: SmartTileUsage.terrain,
        materialPalette: <String>['', 'grass', 'dirt'],
        field: SmartTileField.mixed(
          semanticCells: <int>[1],
          horizontalEdges: <int>[1, 2],
          verticalEdges: <int>[2, 1],
          corners: <int>[1, 2, 2, 1],
        ),
      );

      expect(
        () => _validateStructure(
          layer: layer,
          preset: _terrainPreset(
            topology: SmartTileTopology.wang8,
            allowedMaterialIds: const <String>['grass', 'dirt', 'void'],
          ),
        ),
        returnsNormally,
      );
    });
  });
}

const List<ProjectSmartTileMaterial> _materials = <ProjectSmartTileMaterial>[
  ProjectSmartTileMaterial(
    id: 'grass',
    name: 'Grass',
    connectionGroupId: 'grass',
  ),
  ProjectSmartTileMaterial(
    id: 'void',
    name: 'Void',
    connectionGroupId: 'void',
    isEmpty: true,
  ),
  ProjectSmartTileMaterial(
    id: 'dirt',
    name: 'Dirt',
    connectionGroupId: 'dirt',
  ),
];

MapData _mapWith(
  SmartTileLayer layer, {
  GridSize size = const GridSize(width: 2, height: 1),
}) =>
    MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: size,
      layers: <MapLayer>[layer],
    );

ProjectSmartTilePreset _terrainPreset({
  String id = 'terrain',
  SmartTileUsage usage = SmartTileUsage.terrain,
  SmartTileTopology topology = SmartTileTopology.uniform,
  SmartTileCoveragePolicy coveragePolicy = SmartTileCoveragePolicy.complete,
  List<String> allowedMaterialIds = const <String>['grass', 'void'],
  List<SmartTileRule>? rules,
  String? fallbackRuleId,
  bool allowFallback = false,
}) =>
    ProjectSmartTilePreset(
      id: id,
      name: 'Terrain',
      usage: usage,
      topology: topology,
      coveragePolicy: coveragePolicy,
      coverageProfile: SmartTileCoverageProfile(
        mode: SmartTileCoverageMode.explicit,
        allowFallback: allowFallback,
      ),
      transformPolicy: const SmartTileTransformPolicy(),
      defaultMaterialId: 'grass',
      allowedMaterialIds: allowedMaterialIds,
      rules: rules ??
          const <SmartTileRule>[
            SmartTileRule(
              id: 'grass',
              centerMatch: SmartTileSlotMatch.material('grass'),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(id: 'grass'),
              ],
            ),
          ],
      fallbackRuleId: fallbackRuleId,
    );

void _validateStructure({
  required SmartTileLayer layer,
  required ProjectSmartTilePreset preset,
  GridSize size = const GridSize(width: 1, height: 1),
}) {
  final map = _mapWith(layer, size: size);
  final manifest = ProjectManifest(
    name: 'Project',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    smartTileCatalog: ProjectSmartTileCatalog(
      materials: _materials,
      presets: <ProjectSmartTilePreset>[preset],
    ),
  );
  MapValidator.validate(map, projectDialogueContext: manifest);
}
