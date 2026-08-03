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
        expect(descriptor.extensions['cellFieldOnly'], isTrue);
      }
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

    test('refuses edge, corner and mixed Wang fields with the STN-05 code', () {
      final fields = <SmartTileField>[
        const SmartTileField.edge(
          semanticCells: <int>[0, 0, 0, 0],
          horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
          verticalEdges: <int>[0, 0, 0, 0, 0, 0],
        ),
        const SmartTileField.corner(
          semanticCells: <int>[0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
        const SmartTileField.mixed(
          semanticCells: <int>[0, 0, 0, 0],
          horizontalEdges: <int>[0, 0, 0, 0, 0, 0],
          verticalEdges: <int>[0, 0, 0, 0, 0, 0],
          corners: <int>[0, 0, 0, 0, 0, 0, 0, 0, 0],
        ),
      ];

      for (final field in fields) {
        expect(
          () => _build(
            _fixture(field: field).snapshot,
            actionId: 'smart_tile.cell.paint',
            parameters: const <String, Object?>{
              'mapId': 'map',
              'layerId': 'ground',
              'materialId': 'grass',
              'cells': <Map<String, int>>[
                <String, int>{'x': 0, 'y': 0},
              ],
            },
          ),
          _failure(smartTileWangPaintRequiresStn05Code),
          reason: field.runtimeType.toString(),
        );
      }
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
  SmartTileField field = const SmartTileField.cell(
    semanticCells: <int>[0, 0, 0, 0],
  ),
}) {
  final map = MapData(
    id: 'map',
    name: 'Map',
    version: ProjectVersion.v6,
    size: const GridSize(width: 2, height: 2),
    layers: <MapLayer>[
      MapLayer.smartTile(
        id: 'ground',
        name: 'Ground',
        presetId: 'grass-preset',
        usage: SmartTileUsage.terrain,
        materialPalette: const <String>['', 'grass'],
        field: field,
      ),
    ],
  );
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
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
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

MapData _map(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(_mapBytes(draft))) as Map<String, dynamic>,
    );

List<int> _mapBytes(AuthoringMutationDraft draft) => draft.changeSet.changes
    .singleWhere((change) => change.resource.kind == 'map')
    .afterBytes!;

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
