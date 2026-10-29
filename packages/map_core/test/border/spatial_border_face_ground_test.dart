import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../support/spatial_border_ground_surface_fixture.dart';

const _crown = 'border.spatial.face_crown_mismatch';
const _base = 'border.spatial.face_base_mismatch';

void main() {
  test('crown-anchored faces that bridge their step stay silent', () {
    final fixture = spatialCliffFixture(geometry: _plateauRegion());
    final resolved = _resolve(fixture);
    expect(resolved.result.canApply, isTrue);
    expect(resolved.modelInstances, isNotEmpty);
    expect(_faceDiagnostics(resolved), isEmpty);
  });

  test('flat ground reports every sunken face base without blocking', () {
    final fixture = spatialCliffFixture(
      geometry: _plateauRegion(),
      levels: List.filled(36, 1),
    );
    final resolved = _resolve(fixture);
    expect(resolved.result.canApply, isTrue);
    expect(resolved.result.status, BorderResolutionStatus.warning);
    final diagnostics = _faceDiagnostics(resolved);
    final slots = resolved.result.materialization!.spatialPlacements
        .map((placement) => placement.slotKey)
        .toSet();
    expect(diagnostics.map((d) => d.code).toSet(), {_base});
    expect(diagnostics.map((d) => d.slotKey).toSet(), slots);
    final first = diagnostics.first;
    expect(first.severity, BorderDiagnosticSeverity.warning);
    expect(first.phase, BorderDiagnosticPhase.resolution);
    expect(first.scope, BorderDiagnosticScope.slot);
    expect(first.featureId, 'fence');
    expect(first.cell, isNotNull);
    expect(first.parameters['crownHeight'], 1.0);
    expect(first.parameters['baseHeight'], 0.0);
    expect(first.parameters['upperGroundHeight'], 1.0);
    expect(first.parameters['lowerGroundHeight'], 1.0);
    expect(first.parameters['tolerance'], .5);
  });

  test('faces buried by less than half their height stay silent', () {
    final skirt = _resolve(
      spatialCliffFixture(
        geometry: _plateauRegion(),
        face: (minY: -1.4, maxY: 0, anchorY: 0),
      ),
    );
    expect(skirt.result.canApply, isTrue);
    expect(_faceDiagnostics(skirt), isEmpty);

    final floating = _resolve(
      spatialCliffFixture(
        geometry: _plateauRegion(),
        face: (minY: -.6, maxY: 0, anchorY: 0),
      ),
    );
    final diagnostics = _faceDiagnostics(floating);
    expect(diagnostics.map((d) => d.code).toSet(), {_base});
    expect(diagnostics.first.parameters['baseHeight'], closeTo(.4, 1e-9));
    expect(diagnostics.first.parameters['tolerance'], closeTo(.15, 1e-9));
  });

  test('cell-centred directed faces compare both neighbouring cells', () {
    final stroke = BorderStrokeGeometry(
      alignment: BorderStrokeAlignment.cellCenters,
      strokes: [
        BorderStroke(
          id: 'centre',
          points: [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 2)],
          closed: false,
        ),
      ],
    );
    final levels = [
      for (var z = 0; z < 6; z++)
        for (var x = 0; x < 6; x++) z >= 3 ? 1 : 0,
    ];
    final bridged = _resolve(spatialCliffFixture(geometry: stroke, levels: levels));
    expect(bridged.result.canApply, isTrue);
    expect(bridged.modelInstances, hasLength(4));
    expect(_faceDiagnostics(bridged), isEmpty);

    final lifted = _resolve(
      spatialCliffFixture(
        geometry: stroke,
        levels: levels,
        offset: Model3dVector3(x: 0, y: 1, z: 0),
      ),
    );
    final crowns = _faceDiagnostics(lifted).where((d) => d.code == _crown);
    expect(crowns, hasLength(4));
    expect(crowns.first.parameters['landCell'], {'x': 1, 'y': 3});
    expect(crowns.first.parameters['outsideCell'], {'x': 1, 'y': 1});
  });

  test('contexts without modeled ground never read extra heights', () {
    final fixture = spatialCliffFixture(
      geometry: _plateauRegion(),
      levels: List.filled(36, 1),
    );
    final scene = fixture.map.spatialScene!;
    final samples = <(double, double)>[];
    final resolved = resolveSpatialBorderFeatureInContext(
      manifest: fixture.project,
      context: SpatialBorderResolutionContext(
        mapId: fixture.map.id,
        size: fixture.map.size,
        layers: fixture.map.layers,
        instances: scene.instances,
        worldHeightAt: (x, z) {
          samples.add((x, z));
          return scene.worldHeightAt(x, z);
        },
        fingerprintContext: () => {'samples': samples.length},
      ),
      layerId: 'border',
      featureId: 'fence',
    );
    expect(resolved.result.canApply, isTrue);
    expect(_faceDiagnostics(resolved), isEmpty);
    expect(samples, hasLength(resolved.modelInstances.length));
    expect(
      samples.every(
        (sample) =>
            sample.$1 > 1 && sample.$1 < 5 && sample.$2 > 1 && sample.$2 < 5,
      ),
      isTrue,
    );
  });

  test('crowns lifted above the upper ground are reported', () {
    final fixture = spatialCliffFixture(
      geometry: _plateauRegion(),
      offset: Model3dVector3(x: 0, y: 1, z: 0),
    );
    final resolved = _resolve(fixture);
    expect(resolved.result.canApply, isTrue);
    final crowns = _faceDiagnostics(resolved).where((d) => d.code == _crown);
    expect(
      crowns.map((d) => d.slotKey).toSet(),
      resolved.result.materialization!.spatialPlacements
          .map((placement) => placement.slotKey)
          .toSet(),
    );
    expect(crowns.first.parameters['crownHeight'], 2.0);
    expect(crowns.first.parameters['upperGroundHeight'], 1.0);
  });

  test('compensated reversed strokes stay silent until their low side moves', () {
    final stroke = BorderStrokeGeometry(
      alignment: BorderStrokeAlignment.gridEdges,
      strokes: [
        BorderStroke(
          id: 'edge',
          points: [for (var x = 4; x >= 1; x--) GridPos(x: x, y: 1)],
          closed: false,
        ),
      ],
    );
    final offset = Model3dVector3(x: 0, y: 1, z: 0);
    final compensated = spatialCliffFixture(geometry: stroke, offset: offset);
    final silent = _resolve(compensated);
    expect(silent.result.canApply, isTrue);
    expect(silent.modelInstances, hasLength(4));
    expect(_faceDiagnostics(silent), isEmpty);

    final raised = spatialCliffFixture(
      geometry: stroke,
      offset: offset,
      surfaces: SpatialTerrainSurfaceSet.fromJson({
        'schemaVersion': 1,
        'surfaces': [
          {
            'id': 'raised-low-side',
            'x': 0.0,
            'z': 0.0,
            'height': .5,
            'gradientX': 0.0,
            'gradientZ': 0.0,
            'footprints': [
              [
                {'x': 2.0, 'z': 0.0},
                {'x': 4.0, 'z': 0.0},
                {'x': 4.0, 'z': 1.0},
                {'x': 2.0, 'z': 1.0},
              ],
            ],
          },
        ],
      }),
    );
    final drifted = _resolve(raised);
    expect(drifted.result.canApply, isTrue);
    final diagnostics = _faceDiagnostics(drifted);
    expect(diagnostics.map((d) => d.code).toSet(), {_crown});
    expect(diagnostics.map((d) => d.cell).toSet(), {
      const GridPos(x: 4, y: 1),
      const GridPos(x: 3, y: 1),
    });
    expect(diagnostics.first.parameters['crownHeight'], 1.5);
    expect(diagnostics.first.parameters['upperGroundHeight'], 1.0);
    expect(diagnostics.first.parameters['lowerGroundHeight'], .5);
  });

  test('unmodeled ground beside a face is never compared', () {
    final plateau = spatialTestSurface('plateau', height: 1, left: 1, top: 1, size: 4);
    final lifted = _resolve(
      spatialCliffFixture(
        geometry: _plateauRegion(),
        levels: List.filled(36, 0),
        offset: Model3dVector3(x: 0, y: 1, z: 0),
        surfaces: SpatialTerrainSurfaceSet(surfaces: [plateau]),
      ),
    );
    expect(lifted.result.canApply, isTrue);
    final diagnostics = _faceDiagnostics(lifted);
    expect(diagnostics, isNotEmpty);
    expect(diagnostics.map((d) => d.code).toSet(), {_crown});

    final unsupported = _resolve(
      spatialCliffFixture(
        geometry: BorderStrokeGeometry(
          alignment: BorderStrokeAlignment.gridEdges,
          strokes: [
            BorderStroke(
              id: 'edge',
              points: [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 3)],
              closed: false,
            ),
          ],
        ),
        levels: List.filled(36, 0),
        offset: Model3dVector3(x: 0, y: 1, z: 0),
        surfaces: SpatialTerrainSurfaceSet(
          surfaces: [spatialTestSurface('far', height: 1, left: 5, top: 0, size: 1)],
        ),
      ),
    );
    expect(unsupported.result.canApply, isTrue);
    expect(unsupported.modelInstances, hasLength(4));
    expect(_faceDiagnostics(unsupported), isEmpty);
  });

  test('modules that are not crown-anchored faces are never checked', () {
    final fixture = spatialCliffFixture(
      geometry: _plateauRegion(),
      levels: List.filled(36, 1),
      face: (minY: 0, maxY: 1, anchorY: 2),
    );
    final resolved = _resolve(fixture);
    expect(resolved.result.canApply, isTrue);
    expect(_faceDiagnostics(resolved), isEmpty);
  });

  test('undirected blueprints are never checked', () {
    final fixture = spatialCliffFixture(
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: [
          BorderStroke(
            id: 'edge',
            points: [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 1)],
            closed: false,
          ),
        ],
      ),
      levels: List.filled(36, 1),
      directed: false,
    );
    final resolved = _resolve(fixture);
    expect(resolved.result.canApply, isTrue);
    expect(resolved.modelInstances, isNotEmpty);
    expect(_faceDiagnostics(resolved), isEmpty);
  });

  test('edges on the map boundary skip their missing outside ground', () {
    final fixture = spatialCliffFixture(
      geometry: BorderStrokeGeometry(
        alignment: BorderStrokeAlignment.gridEdges,
        strokes: [
          BorderStroke(
            id: 'edge',
            points: [for (var x = 1; x <= 4; x++) GridPos(x: x, y: 0)],
            closed: false,
          ),
        ],
      ),
      levels: List.filled(36, 1),
    );
    final resolved = _resolve(fixture);
    expect(resolved.result.canApply, isTrue);
    expect(resolved.modelInstances, hasLength(4));
    expect(_faceDiagnostics(resolved), isEmpty);
  });
}

List<BorderDiagnostic> _faceDiagnostics(
  SpatialBorderResolutionResult resolved,
) => resolved.result.diagnostics
    .where((diagnostic) => diagnostic.code == _crown || diagnostic.code == _base)
    .toList();

SpatialBorderResolutionResult _resolve(
  ({ProjectManifest project, MapData map}) fixture,
) => resolveSpatialBorderFeature(
  manifest: fixture.project,
  map: fixture.map,
  layerId: 'border',
  featureId: 'fence',
);

SpatialTerrainSurface spatialTestSurface(
  String id, {
  required double height,
  required double left,
  required double top,
  required double size,
}) => SpatialTerrainSurface.fromJson({
  'id': id,
  'x': 0.0,
  'z': 0.0,
  'height': height,
  'gradientX': 0.0,
  'gradientZ': 0.0,
  'footprints': [
    [
      {'x': left, 'z': top},
      {'x': left + size, 'z': top},
      {'x': left + size, 'z': top + size},
      {'x': left, 'z': top + size},
    ],
  ],
});

BorderRegionGeometry _plateauRegion() => BorderRegionGeometry(
  width: 6,
  height: 6,
  cells: [
    for (var z = 0; z < 6; z++)
      for (var x = 0; x < 6; x++) x >= 1 && x <= 4 && z >= 1 && z <= 4,
  ],
);

({ProjectManifest project, MapData map}) spatialCliffFixture({
  required BorderFeatureGeometry geometry,
  List<int>? levels,
  Model3dVector3? offset,
  bool directed = true,
  ({double minY, double maxY, double anchorY}) face = (
    minY: -1,
    maxY: 0,
    anchorY: 0,
  ),
  SpatialTerrainSurfaceSet surfaces = const SpatialTerrainSurfaceSet.empty(),
}) {
  final fixture = spatialBorderFixture();
  final raw = encodeBorderBlueprintRecordJson(
    fixture.project.borderCatalog.records.single,
    formatVersion: 5,
  );
  for (final key in ['draft', 'latestPublished']) {
    final definition = (raw[key] as Map)['definition'] as Map;
    definition['followContourDirection'] = directed;
    final primitives = definition['primitives'] as List;
    for (final primitive in primitives.cast<Map>()) {
      primitive['authoredOrientation'] = 'east';
      primitive['anchorWorld'] = {'x': 0.0, 'y': face.anchorY, 'z': 0.0};
    }
    if (directed) {
      final corner = Map<String, Object?>.from(
        primitives.singleWhere((p) => p['role'] == 'lineCorner') as Map,
      );
      primitives.removeWhere((p) => p['role'] == 'lineCorner');
      primitives.add({...corner, 'id': 'corner-right', 'cornerTurn': 'right'});
      primitives.add({...corner, 'id': 'corner-left', 'cornerTurn': 'left'});
    }
  }
  final source = fixture.project.models3d.single;
  final project = fixture.project.copyWith(
    models3d: [
      ProjectModel3dEntry(
        id: source.id,
        name: source.name,
        sourceAssetId: source.sourceAssetId,
        relativePath: source.relativePath,
        inspection: Model3dInspection(
          bounds: Model3dBounds(
            min: Model3dVector3(x: -.2, y: face.minY, z: -.2),
            max: Model3dVector3(x: .2, y: face.maxY, z: .2),
          ),
          meshCount: 1,
          triangleCount: 1,
        ),
      ),
    ],
    borderCatalog: ProjectBorderCatalog(
      formatVersion: 5,
      records: [decodeBorderBlueprintRecordJson(raw, formatVersion: 5)],
    ),
  );
  final original =
      (fixture.map.layers.single as BorderLayer).content.features.single;
  final map = upsertBorderFeature(
    fixture.map.copyWith(
      spatialScene: MapSpatialScene(
        width: 6,
        depth: 6,
        heightLevels:
            levels ??
            [
              for (var z = 0; z < 6; z++)
                for (var x = 0; x < 6; x++)
                  x >= 1 && x <= 4 && z >= 1 && z <= 4 ? 1 : 0,
            ],
        terrainSurfaces: surfaces,
      ),
    ),
    layerId: 'border',
    feature: BorderFeature(
      id: original.id,
      name: original.name,
      blueprintId: original.blueprintId,
      seed: original.seed,
      geometry: geometry,
      spatialOffsetWorld: offset,
      overrides: const [],
      keepOutRegions: const [],
    ),
  );
  return (project: project, map: map);
}
