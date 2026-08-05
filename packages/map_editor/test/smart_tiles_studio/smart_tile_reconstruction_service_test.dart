import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/smart_tiles_studio/application/smart_tile_reconstruction_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('plans, confirms and adopts a non-destructive canonical reconstruction',
      () async {
    final before = _snapshot(_map());
    const native = SmartTileLayer(
      id: 'native',
      name: 'Native path',
      isVisible: false,
      presetId: 'edge',
      usage: SmartTileUsage.path,
      materialPalette: <String>['', 'dirt'],
      field: SmartTileField.edge(
        semanticCells: <int>[1],
        horizontalEdges: <int>[0, 0],
        verticalEdges: <int>[0, 0],
      ),
    );
    final afterMap = _map().copyWith(
      layers: <MapLayer>[..._map().layers, native],
    );
    final gateway = _Gateway(
      snapshots: <SmartTileReconstructionCanonicalSnapshot>[
        before,
        _snapshot(afterMap, revision: 'revision-after'),
      ],
    );
    final service = SmartTileReconstructionService(gateway: gateway);
    const request = SmartTileReconstructionRequest(
      mapId: 'map',
      sourceLayerId: 'literal',
      presetId: 'edge',
      targetLayerId: 'native',
      targetLayerName: 'Native path',
    );

    final plan = await service.plan(
      projectRootPath: '/project',
      request: request,
    );

    expect(gateway.parameters, request.toActionParameters());
    expect(plan.coverage, 1);
    expect(plan.exactVisualMatchCount, 1);
    expect(plan.sourcePreserved, isTrue);
    expect(plan.confirmationRequired, isTrue);

    final result = await service.apply(
      plan,
      projectRootPath: '/project',
    );

    expect(gateway.applied, isTrue);
    expect(result.map.layers.first, _map().layers.first);
    expect(result.layerId, 'native');
    expect(result.mapRevision, 'map-revision');
  });

  test('refuses to apply when the canonical transaction changed the source',
      () async {
    final before = _snapshot(_map());
    final changedSource = (_map().layers.single as TileLayer).copyWith(
      name: 'Changed behind the assistant',
    );
    final gateway = _Gateway(
      snapshots: <SmartTileReconstructionCanonicalSnapshot>[
        before,
        _snapshot(
          _map().copyWith(layers: <MapLayer>[changedSource]),
          revision: 'revision-after',
        ),
      ],
    );
    final service = SmartTileReconstructionService(gateway: gateway);
    final plan = await service.plan(
      projectRootPath: '/project',
      request: const SmartTileReconstructionRequest(
        mapId: 'map',
        sourceLayerId: 'literal',
        presetId: 'edge',
        targetLayerId: 'native',
        targetLayerName: 'Native path',
      ),
    );

    expect(
      () => service.apply(plan, projectRootPath: '/project'),
      throwsA(
        isA<SmartTileReconstructionServiceException>().having(
          (error) => error.code,
          'code',
          'smart_tile.reconstruction.source_changed',
        ),
      ),
    );
  });
}

final class _Gateway implements SmartTileReconstructionGateway {
  _Gateway({required this.snapshots});

  final List<SmartTileReconstructionCanonicalSnapshot> snapshots;
  Map<String, Object?>? parameters;
  bool applied = false;
  var _loadIndex = 0;

  @override
  Future<SmartTileReconstructionCanonicalSnapshot> load({
    required String projectRootPath,
  }) async =>
      snapshots[_loadIndex++];

  @override
  Future<SmartTileReconstructionCanonicalPlan> plan({
    required String projectRootPath,
    required Map<String, Object?> parameters,
    required String expectedRevision,
    required String idempotencyKey,
  }) async {
    this.parameters = parameters;
    return SmartTileReconstructionCanonicalPlan(
      token: Object(),
      planId: 'plan',
      snapshotRevision: expectedRevision,
      preview: const <String, Object?>{
        'sourceCellCount': 1,
        'reconstructedCellCount': 1,
        'coverage': 1.0,
        'unresolvedCellCount': 0,
        'ambiguousCellCount': 0,
        'conflictCount': 0,
        'exactVisualMatchCount': 1,
        'visualMismatchCellCount': 0,
        'sourcePreserved': true,
        'confirmationRequired': true,
        'assessmentChecksum': 'sha256:test',
      },
    );
  }

  @override
  Future<String> confirmAndApply({
    required SmartTileReconstructionCanonicalPlan plan,
    required String operationId,
  }) async {
    applied = true;
    return 'revision-after';
  }
}

SmartTileReconstructionCanonicalSnapshot _snapshot(
  MapData map, {
  String revision = 'revision-before',
}) =>
    SmartTileReconstructionCanonicalSnapshot(
      snapshotRevision: revision,
      manifest: _manifest,
      maps: <MapData>[map],
      mapRevisions: const <String, String>{'map': 'map-revision'},
    );

MapData _map() => const MapData(
      id: 'map',
      name: 'Map',
      version: ProjectVersion.v6,
      size: GridSize(width: 1, height: 1),
      layers: <MapLayer>[
        MapLayer.tile(
          id: 'literal',
          name: 'Literal',
          palette: <TileLayerPaletteEntry>[
            TileLayerPaletteEntry(tilesetId: 'tiles', localTileId: 1),
          ],
          cells: <int>[1],
        ),
      ],
    );

final _manifest = ProjectManifest(
  name: 'Project',
  maps: const <ProjectMapEntry>[
    ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json'),
  ],
  tilesets: const <ProjectTilesetEntry>[],
  smartTileCatalog: ProjectSmartTileCatalog(
    presets: const <ProjectSmartTilePreset>[
      ProjectSmartTilePreset(
        id: 'edge',
        name: 'Edge',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.wangEdge4,
        status: SmartTilePresetStatus.published,
        coveragePolicy: SmartTileCoveragePolicy.sparse,
        coverageProfile: SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.explicit,
          requiredScenarios: <SmartTileCoverageScenario>[
            SmartTileCoverageScenario(id: 'scenario'),
          ],
        ),
        transformPolicy: SmartTileTransformPolicy(),
        defaultMaterialId: 'dirt',
        allowedMaterialIds: <String>['dirt'],
      ),
    ],
  ),
);
