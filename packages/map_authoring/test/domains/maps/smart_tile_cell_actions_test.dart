import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileCellActions', () {
    test('registers atomic paint and erase contracts', () {
      expect(
        SmartTileCellActions.descriptors.map((descriptor) => descriptor.id),
        <String>['smart_tile.cell.paint', 'smart_tile.cell.erase'],
      );
      for (final descriptor in SmartTileCellActions.descriptors) {
        expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
        expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
        expect(descriptor.extensions['gestureAtomic'], isTrue);
        expect(descriptor.extensions['cellFieldOnly'], isFalse);
        expect(
          descriptor.extensions['supportedSelections'],
          <String>['cells', 'line', 'rectangle', 'floodFill'],
        );
        expect(
          descriptor.extensions['supportedFieldKinds'],
          <String>['cell', 'edge', 'corner', 'mixed'],
        );
        expect(descriptor.extensions['maximumExplicitCellCount'], 4096);
        expect(descriptor.extensions['geometricSelectionLimit'], 'mapExtent');
      }
    });

    test('pattern action stamps visuals and collision in one undo boundary',
        () {
      final fixture = _fixture(
        field: const SmartTileField.cell(
          semanticCells: <int>[1, 0, 0, 0],
        ),
        includePattern: true,
        includeCollision: true,
      );
      final draft = _buildPattern(
        fixture.snapshot,
        actionId: 'smart_tile.pattern.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'patternId': 'rock-stamp',
          'strokeId': 'stroke-1',
          'collisionLayerId': 'collision',
          'selection': <String, Object?>{
            'kind': 'stamp',
            'anchor': <String, int>{'x': 0, 'y': 0},
          },
        },
      );
      final projected = _map(draft);
      final layer = projected.layers.whereType<SmartTileLayer>().single;
      final collision = projected.layers.whereType<CollisionLayer>().single;

      expect(layer.patternStrokes.single.patternId, 'rock-stamp');
      expect(smartTileSemanticCells(layer).first, 0);
      expect(collision.collisions.first, isTrue);
      expect(draft.preview['collisionApplied'], isTrue);
      expect(draft.preview['undoBoundary'], 'gesture');
    });

    test('paints one whole gesture independent of coordinate order', () {
      final fixture = _fixture();
      final forward = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 1, 'y': 1},
            <String, int>{'x': 0, 'y': 0},
          ],
        },
      );
      final reverse = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 0},
            <String, int>{'x': 1, 'y': 1},
          ],
        },
      );

      expect(_mapBytes(forward), _mapBytes(reverse));
      expect(forward.preview['changedCellCount'], 2);
      expect(forward.preview['gestureCellCount'], 2);
      expect(forward.preview['undoBoundary'], 'gesture');
      expect(
        forward.preview['cells'],
        const <Map<String, int>>[
          <String, int>{'x': 0, 'y': 0},
          <String, int>{'x': 1, 'y': 1},
        ],
      );
      final layer = _map(forward).layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[1, 0, 0, 1]);
    });

    test('validates only the declared Smart Tile cell delta', () {
      final fixture = _fixture(includeInvalidUnrelatedLayer: true);
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 1, 'y': 1},
          ],
        },
      );

      final layer = _map(draft).layers.first as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[0, 0, 0, 1]);
    });

    test('erases a gesture through the same canonical boundary', () {
      final fixture = _fixture(
        field: const SmartTileField.cell(
          semanticCells: <int>[1, 1, 1, 1],
        ),
      );
      final draft = _build(
        fixture.snapshot,
        actionId: 'smart_tile.cell.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 1},
            <String, int>{'x': 1, 'y': 1},
          ],
        },
      );

      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[1, 1, 0, 0]);
      expect(draft.preview['materialId'], isNull);
      expect(draft.preview['changedCellCount'], 2);
    });

    test('compiles line and rectangle selections inside the atomic action', () {
      final snapshot = _fixture().snapshot;
      final line = _build(
        snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'selection': <String, Object?>{
            'kind': 'line',
            'start': <String, int>{'x': 0, 'y': 0},
            'end': <String, int>{'x': 1, 'y': 1},
          },
        },
      );
      expect(
        smartTileSemanticCells(_map(line).layers.single as SmartTileLayer),
        <int>[1, 0, 0, 1],
      );
      expect(line.preview['gestureSelection'], 'line');

      final rectangle = _build(
        snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'selection': <String, Object?>{
            'kind': 'rectangle',
            'start': <String, int>{'x': 1, 'y': 1},
            'end': <String, int>{'x': 0, 'y': 0},
          },
        },
      );
      expect(
        smartTileSemanticCells(
          _map(rectangle).layers.single as SmartTileLayer,
        ),
        <int>[1, 1, 1, 1],
      );
      expect(rectangle.preview['gestureCellCount'], 4);
    });

    test(
        'geometric selection may cover a map beyond the explicit payload limit',
        () {
      const mapSize = GridSize(width: 65, height: 64);
      final draft = _build(
        _fixture(mapSize: mapSize).snapshot,
        actionId: 'smart_tile.cell.paint',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'selection': <String, Object?>{
            'kind': 'rectangle',
            'start': <String, int>{'x': 0, 'y': 0},
            'end': <String, int>{'x': 64, 'y': 63},
          },
        },
      );

      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(draft.preview['gestureCellCount'], 4160);
      expect(smartTileSemanticCells(layer), hasLength(4160));
      expect(smartTileSemanticCells(layer).every((cell) => cell == 1), isTrue);
    });

    test('explicit cell payloads remain bounded to 4096 coordinates', () {
      const mapSize = GridSize(width: 65, height: 64);
      final cells = <Map<String, int>>[
        for (var index = 0; index < 4097; index++)
          <String, int>{
            'x': index % mapSize.width,
            'y': index ~/ mapSize.width,
          },
      ];

      expect(
        () => _build(
          _fixture(mapSize: mapSize).snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': cells,
          },
        ),
        _failure('smart_tile.cell.gesture_too_large'),
      );
    });

    test('flood fill follows the source semantic region', () {
      final draft = _build(
        _fixture(
          field: const SmartTileField.cell(
            semanticCells: <int>[1, 1, 0, 1],
          ),
        ).snapshot,
        actionId: 'smart_tile.cell.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'selection': <String, Object?>{
            'kind': 'floodFill',
            'seed': <String, int>{'x': 0, 'y': 0},
          },
        },
      );

      final layer = _map(draft).layers.single as SmartTileLayer;
      expect(smartTileSemanticCells(layer), <int>[0, 0, 0, 0]);
      expect(draft.preview['gestureSelection'], 'floodFill');
      expect(draft.preview['gestureCellCount'], 3);
    });

    test('requires exactly one cells or geometric selection input', () {
      final snapshot = _fixture().snapshot;
      for (final parameters in <Map<String, Object?>>[
        const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
        },
        const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'materialId': 'grass',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 0},
          ],
          'selection': <String, Object?>{
            'kind': 'floodFill',
            'seed': <String, int>{'x': 0, 'y': 0},
          },
        },
      ]) {
        expect(
          () => _build(
            snapshot,
            actionId: 'smart_tile.cell.paint',
            parameters: parameters,
          ),
          _failure('smart_tile.cell.selection_invalid'),
        );
      }
    });

    test('rejects duplicates, out-of-bounds cells, and unavailable materials',
        () {
      final snapshot = _fixture().snapshot;

      expect(
        () => _build(
          snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': <Map<String, int>>[
              <String, int>{'x': 0, 'y': 0},
              <String, int>{'x': 0, 'y': 0},
            ],
          },
        ),
        _failure('smart_tile.cell.duplicate'),
      );
      expect(
        () => _build(
          snapshot,
          actionId: 'smart_tile.cell.erase',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'cells': <Map<String, int>>[
              <String, int>{'x': 2, 'y': 0},
            ],
          },
        ),
        _failure('smart_tile.cell.out_of_bounds'),
      );
      expect(
        () => _build(
          snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'water',
            'cells': <Map<String, int>>[
              <String, int>{'x': 0, 'y': 0},
            ],
          },
        ),
        _failure('smart_tile.cell.material_not_allowed'),
      );
    });

    test('projects paint across edge, corner and mixed Wang fields', () {
      final cases =
          <({SmartTileField field, List<int> edges, List<int> corners})>[
        (
          field: const SmartTileField.edge(
            semanticCells: <int>[0, 0, 0, 0],
            horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
            verticalEdges: <int>[0, 0, 0, 0, 0, 0],
          ),
          edges: <int>[1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0],
          corners: <int>[],
        ),
        (
          field: const SmartTileField.corner(
            semanticCells: <int>[0, 0, 0, 0],
            corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          edges: <int>[],
          corners: <int>[1, 1, 0, 1, 1, 0, 0, 0, 0],
        ),
        (
          field: const SmartTileField.mixed(
            semanticCells: <int>[0, 0, 0, 0],
            horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
            verticalEdges: <int>[0, 0, 0, 0, 0, 0],
            corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
          edges: <int>[1, 0, 1, 0, 0, 0, 1, 1, 0, 0, 0, 0],
          corners: <int>[1, 1, 0, 1, 1, 0, 0, 0, 0],
        ),
      ];

      for (final paintCase in cases) {
        final draft = _build(
          _fixture(field: paintCase.field).snapshot,
          actionId: 'smart_tile.cell.paint',
          parameters: const <String, Object?>{
            'mapId': 'map',
            'layerId': 'ground',
            'materialId': 'grass',
            'cells': <Map<String, int>>[
              <String, int>{'x': 0, 'y': 0},
            ],
          },
        );
        final layer = _map(draft).layers.single as SmartTileLayer;

        expect(
          smartTileSemanticCells(layer),
          <int>[1, 0, 0, 0],
          reason: paintCase.field.runtimeType.toString(),
        );
        expect(
          <int>[
            ...smartTileHorizontalEdges(layer),
            ...smartTileVerticalEdges(layer),
          ],
          paintCase.edges,
          reason: paintCase.field.runtimeType.toString(),
        );
        expect(
          smartTileCorners(layer),
          paintCase.corners,
          reason: paintCase.field.runtimeType.toString(),
        );
        expect(draft.preview['changedCellCount'], 1);
        expect(draft.preview['fieldKind'], isNotEmpty);
      }
    });

    test('erases a mixed Wang gesture through the same undo boundary', () {
      final draft = _build(
        _fixture(
          field: const SmartTileField.mixed(
            semanticCells: <int>[0, 0, 0, 0],
            horizontalEdges: <int>[1, 1, 1, 1, 1, 1],
            verticalEdges: <int>[1, 1, 1, 1, 1, 1],
            corners: <int>[1, 1, 1, 1, 1, 1, 1, 1, 1],
          ),
        ).snapshot,
        actionId: 'smart_tile.cell.erase',
        parameters: const <String, Object?>{
          'mapId': 'map',
          'layerId': 'ground',
          'cells': <Map<String, int>>[
            <String, int>{'x': 0, 'y': 0},
          ],
        },
      );
      final layer = _map(draft).layers.single as SmartTileLayer;

      expect(smartTileHorizontalEdges(layer), <int>[0, 1, 0, 1, 1, 1]);
      expect(smartTileVerticalEdges(layer), <int>[0, 0, 1, 1, 1, 1]);
      expect(smartTileCorners(layer), <int>[0, 0, 1, 0, 0, 1, 1, 1, 1]);
      expect(draft.preview['undoBoundary'], 'gesture');
    });
  });
}

Matcher _failure(String code) => throwsA(
      isA<MapAuthoringException>().having(
        (failure) => failure.code,
        'code',
        code,
      ),
    );

AuthoringMutationDraft _build(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    const SmartTileCellActions().build(
      AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
          requestId: 'request',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: 'workspace:cells',
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'idempotency-$actionId',
        ),
        planId: 'plan-cells',
        seed: 17,
      ),
    );

({ProjectSnapshot snapshot, ProjectManifest manifest, MapData map}) _fixture({
  SmartTileField? field,
  GridSize mapSize = const GridSize(width: 2, height: 2),
  bool includePattern = false,
  bool includeCollision = false,
  bool includeInvalidUnrelatedLayer = false,
}) {
  final resolvedField = field ??
      SmartTileField.cell(
        semanticCells: List<int>.filled(mapSize.width * mapSize.height, 0),
      );
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: mapSize,
    layers: <MapLayer>[
      MapLayer.smartTile(
        id: 'ground',
        name: 'Ground',
        presetId: 'grass-preset',
        usage: SmartTileUsage.terrain,
        materialPalette: const <String>['', 'grass'],
        field: resolvedField,
      ),
      if (includeCollision)
        MapLayer.collision(
          id: 'collision',
          name: 'Collision',
          collisions: List<bool>.filled(
            mapSize.width * mapSize.height,
            false,
          ),
        ),
      if (includeInvalidUnrelatedLayer)
        const MapLayer.collision(
          id: 'unrelated-invalid',
          name: 'Unrelated invalid collision',
          collisions: <bool>[],
        ),
    ],
  );
  final (topology, templateHint) = switch (resolvedField) {
    SmartTileCellField() => (
        SmartTileTopology.uniform,
        SmartTileTemplateHint.simple,
      ),
    SmartTileEdgeField() => (
        SmartTileTopology.wangEdge4,
        SmartTileTemplateHint.edge16,
      ),
    SmartTileCornerField() => (
        SmartTileTopology.wangCorner4,
        SmartTileTemplateHint.corner16,
      ),
    SmartTileMixedField() => (
        SmartTileTopology.wang8,
        SmartTileTemplateHint.mixed256,
      ),
  };
  final manifest = ProjectManifest(
    name: 'Cell actions fixture',
    version: ProjectVersion.v6,
    maps: const <ProjectMapEntry>[
      ProjectMapEntry(
        id: 'map',
        name: 'Map',
        relativePath: 'maps/map.json',
      ),
    ],
    tilesets: const <ProjectTilesetEntry>[
      ProjectTilesetEntry(
        id: 'tileset',
        name: 'Tileset',
        relativePath: 'assets/tileset.png',
      ),
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: <ProjectSmartTileAtlas>[
        ProjectSmartTileAtlas(
          id: 'atlas',
          name: 'Atlas',
          tilesetId: 'tileset',
          columns: 1,
          rows: 1,
        ),
      ],
      materials: <ProjectSmartTileMaterial>[
        ProjectSmartTileMaterial(
          id: 'grass',
          name: 'Grass',
          connectionGroupId: 'ground',
        ),
      ],
      presets: <ProjectSmartTilePreset>[
        ProjectSmartTilePreset(
          id: 'grass-preset',
          name: 'Grass',
          usage: SmartTileUsage.terrain,
          topology: topology,
          templateHint: templateHint,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile: SmartTileCoverageProfile(
            mode: SmartTileCoverageMode.template,
          ),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: <String>['grass'],
          rules: <SmartTileRule>[
            SmartTileRule(
              id: 'base',
              centerMatch: SmartTileSlotMatch.material('grass'),
              signature: SmartTileSignature(),
              candidates: <SmartTileCandidate>[
                SmartTileCandidate(
                  id: 'base',
                  parts: <SmartTileVisualPart>[
                    SmartTileVisualPart(
                      source: SmartTileVisualSource.frame(
                        frame: SmartTileFrameRef(
                          atlasId: 'atlas',
                          column: 0,
                          row: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      patterns: <ProjectSmartTilePattern>[
        if (includePattern) _rockPattern,
      ],
    ),
  );
  final projectBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  return (
    manifest: manifest,
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project_cells'),
      revision: computeAuthoringBytesFingerprint(
        utf8.encode('cell-snapshot-${map.toJson()}'),
        logicalName: 'snapshot',
      ),
      manifest: manifest,
      maps: <MapData>[map],
      resourceFingerprints: <String, String>{
        'project': computeAuthoringBytesFingerprint(
          projectBytes,
          logicalName: 'project.json',
        ),
        'map:map': computeAuthoringBytesFingerprint(
          mapBytes,
          logicalName: 'maps/map.json',
        ),
      },
      resourceBytes: <String, List<int>>{
        'project': projectBytes,
        'map:map': mapBytes,
      },
      resourceStorageKeys: const <String, String>{
        'project': 'project.json',
        'map:map': 'maps/map.json',
      },
    ),
  );
}

AuthoringMutationDraft _buildPattern(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    const SmartTilePatternActions().build(
      AuthoringPlanningContext(
        snapshot: snapshot,
        request: AuthoringRequest(
          requestId: 'request-pattern',
          actionId: actionId,
          actionVersion: 1,
          workspaceHandle: 'workspace:patterns',
          parameters: parameters,
          expectedRevision: snapshot.revision,
          idempotencyKey: 'idempotency-$actionId',
        ),
        planId: 'plan-patterns',
        seed: 19,
      ),
    );

const _rockPattern = ProjectSmartTilePattern(
  id: 'rock-stamp',
  name: 'Rock stamp',
  usage: SmartTileUsage.terrain,
  width: 1,
  height: 1,
  repeatMode: SmartTilePatternRepeatMode.stamp,
  cells: <SmartTilePatternCell>[
    SmartTilePatternCell(
      x: 0,
      y: 0,
      eraseMaterial: true,
      collision: SmartTilePatternCollision.blocked,
      parts: <SmartTileVisualPart>[
        SmartTileVisualPart(
          source: SmartTileVisualSource.frame(
            frame: SmartTileFrameRef(
              atlasId: 'atlas',
              column: 0,
              row: 0,
            ),
          ),
        ),
      ],
    ),
  ],
);

MapData _map(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(_mapBytes(draft))) as Map<String, dynamic>,
    );

List<int> _mapBytes(AuthoringMutationDraft draft) => draft.changeSet.changes
    .singleWhere((change) => change.resource.kind == 'map')
    .afterBytes!;

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
