import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SmartTileCellActions paint batch', () {
    test('discovers the bounded atomic semantic contract', () {
      final descriptor = SmartTileCellActions.descriptors
          .singleWhere((item) => item.id == 'smart_tile.cell.paint_batch');
      expect(descriptor.version, 1);
      expect(descriptor.guarantees, contains(AuthoringGuarantee.atomic));
      expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      expect(descriptor.extensions['maximumStrokeCount'], 4096);
      expect(descriptor.extensions['maximumTotalCellCount'], 65536);
      expect(descriptor.extensions['inputSchema'], isA<Map>());
    });

    for (final spatial in [false, true]) {
      test('projects two materials once with spatial=$spatial', () {
        final fixture = _fixture(spatial: spatial);
        final draft = _build(fixture.snapshot, [
          _stroke('grass', [(0, 0), (1, 0)]),
          _stroke('path', [(0, 1), (1, 1)]),
        ]);
        final painted = _map(draft);
        expect(smartTileSemanticCells(painted.layers.first as SmartTileLayer),
            [1, 1, 2, 2]);
        expect(painted.spatialScene, fixture.map.spatialScene);
        expect(painted.properties, fixture.map.properties);
        expect(painted.layers.last, fixture.map.layers.last);
        expect(draft.changeSet.changes, hasLength(1));
        expect(draft.preview['changedCellCount'], 4);
        expect(draft.preview['strokeCount'], 2);
        expect(draft.preview['uniqueCellCount'], 4);
        expect(draft.preview['batchAtomicity'], 'all_or_nothing');
        expect(draft.preview['undoBoundary'], 'batch');
      });
    }

    test('deduplicates repeated cells of the same material across strokes', () {
      final draft = _build(_fixture().snapshot, [
        _stroke('grass', [(0, 0), (0, 0)]),
        _stroke('grass', [(0, 0), (1, 0)]),
      ]);
      expect(draft.preview['inputCellCount'], 4);
      expect(draft.preview['uniqueCellCount'], 2);
      expect(draft.preview['changedCellCount'], 2);
      expect(smartTileSemanticCells(_map(draft).layers.first as SmartTileLayer),
          [1, 1, 0, 0]);
    });

    test('clears higher 3D terrain through the existing canonical gesture', () {
      final fixture = _fixture(spatial: true, higherSoil: true);
      final draft = _build(fixture.snapshot, [
        _stroke('grass', [(0, 0)]),
        _stroke('path', [(1, 0)]),
      ]);
      final painted = _map(draft);
      expect(smartTileSemanticCells(painted.layers[0] as SmartTileLayer),
          [1, 2, 0, 0]);
      expect(smartTileSemanticCells(painted.layers[1] as SmartTileLayer),
          [0, 0, 1, 1]);
      expect(draft.changeSet.diff.entries.single.path, '/layers');
      expect(draft.preview['changedCellCount'], 2);
    });

    test('rejects conflicting materials before creating a draft', () {
      final fixture = _fixture();
      final before = fixture.snapshot.resourceBytes('map:map').toList();
      expect(
          () => _build(fixture.snapshot, [
                _stroke('grass', [(0, 0)]),
                _stroke('path', [(0, 0)]),
              ]),
          _throwsCode('smart_tile.cell.batch_conflict'));
      expect(fixture.snapshot.resourceBytes('map:map'), before);
      expect(smartTileSemanticCells(fixture.map.layers.first as SmartTileLayer),
          [0, 0, 0, 0]);
    });

    final invalidStrokes = <String, Object?>{
      'missing material': {
        'cells': [
          {'x': 0, 'y': 1}
        ]
      },
      'empty cells': {'materialId': 'path', 'cells': []},
      'floating coordinate': {
        'materialId': 'path',
        'cells': [
          {'x': 0.0, 'y': 1}
        ]
      },
      'extra coordinate property': {
        'materialId': 'path',
        'cells': [
          {'x': 0, 'y': 1, 'z': 0}
        ]
      },
      'extra stroke property': {
        'materialId': 'path',
        'cells': [
          {'x': 0, 'y': 1}
        ],
        'layerId': 'other'
      },
      'non-object stroke': 'path',
    };
    for (final entry in invalidStrokes.entries) {
      test('rejects a trailing ${entry.key} without changing the snapshot', () {
        final fixture = _fixture();
        final before = fixture.snapshot.resourceBytes('map:map').toList();
        expect(
            () => _build(fixture.snapshot, [
                  _stroke('grass', [(0, 0)]),
                  entry.value
                ]),
            _throwsCode('map.request_invalid'));
        expect(fixture.snapshot.resourceBytes('map:map'), before);
      });
    }

    test('rejects a trailing material outside the target preset', () {
      expect(
          () => _build(_fixture().snapshot, [
                _stroke('grass', [(0, 0)]),
                _stroke('missing', [(0, 1)]),
              ]),
          _throwsCode('smart_tile.cell.material_not_allowed'));
    });

    test('rejects a trailing coordinate outside the map', () {
      expect(
          () => _build(_fixture().snapshot, [
                _stroke('grass', [(0, 0)]),
                _stroke('path', [(2, 1)]),
              ]),
          _throwsCode('smart_tile.cell.out_of_bounds'));
    });

    test('requires one to 4096 strokes', () {
      expect(() => _build(_fixture().snapshot, []),
          _throwsCode('map.request_invalid'));
      expect(
          () => _build(_fixture().snapshot,
              List.filled(4097, _stroke('grass', [(0, 0)]))),
          _throwsCode('smart_tile.cell.batch_too_large'));
    });

    test('limits input cells even when they would deduplicate', () {
      expect(
          () => _build(_fixture().snapshot, [
                _stroke('grass', List.filled(65537, (0, 0))),
              ]),
          _throwsCode('smart_tile.cell.batch_too_large'));
    });

    test('accepts more than 4096 cells within one bounded batch stroke', () {
      final fixture = _fixture(size: const GridSize(width: 65, height: 65));
      final draft = _build(fixture.snapshot, [
        _stroke('grass', [
          for (var y = 0; y < 65; y++)
            for (var x = 0; x < 65; x++) (x, y)
        ]),
      ]);
      expect(draft.preview['uniqueCellCount'], 4225);
      expect(draft.preview['changedCellCount'], 4225);
      expect(draft.changeSet.changes, hasLength(1));
    });

    test('accepts 4096 strokes and a total of 65536 incoming cells', () {
      final fixture = _fixture();
      final draft = _build(fixture.snapshot,
          List.filled(4096, _stroke('grass', List.filled(16, (0, 0)))));
      expect(draft.preview['inputCellCount'], 65536);
      expect(draft.preview['strokeCount'], 4096);
      expect(draft.preview['uniqueCellCount'], 1);
    });
  });
}

Matcher _throwsCode(String code) => throwsA(
    isA<MapAuthoringException>().having((error) => error.code, 'code', code));

Map<String, Object?> _stroke(String material, List<(int, int)> cells) => {
      'materialId': material,
      'cells': [
        for (final (x, y) in cells) {'x': x, 'y': y}
      ],
    };

AuthoringMutationDraft _build(
        ProjectSnapshot snapshot, List<Object?> strokes) =>
    const SmartTileCellActions().build(AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'batch-request',
        actionId: 'smart_tile.cell.paint_batch',
        actionVersion: 1,
        workspaceHandle: 'workspace:batch',
        parameters: {'mapId': 'map', 'layerId': 'ground', 'strokes': strokes},
        expectedRevision: snapshot.revision,
        idempotencyKey: 'batch-request',
      ),
      planId: 'batch-plan',
      seed: 17,
    ));

MapData _map(AuthoringMutationDraft draft) => MapData.fromJson(
    jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
        as Map<String, dynamic>);

({ProjectSnapshot snapshot, MapData map}) _fixture({
  GridSize size = const GridSize(width: 2, height: 2),
  bool spatial = false,
  bool higherSoil = false,
}) {
  final count = size.width * size.height;
  final map = MapData(
    id: 'map',
    name: 'Map',
    size: size,
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    spatialScene: spatial
        ? MapSpatialScene(
            width: size.width,
            depth: size.height,
            heightLevels: List.filled(count, 1))
        : null,
    properties: const {
      'tileLayerOrder': 'bottom_to_top',
      'custom': 'preserved'
    },
    layers: [
      SmartTileLayer(
          id: 'ground',
          name: 'Ground',
          presetId: 'ground-preset',
          usage: SmartTileUsage.terrain,
          materialPalette: const ['', 'grass', 'path'],
          field: SmartTileField.cell(semanticCells: List.filled(count, 0))),
      if (higherSoil)
        SmartTileLayer(
            id: 'higher',
            name: 'Higher',
            presetId: 'ground-preset',
            usage: SmartTileUsage.terrain,
            materialPalette: const ['', 'grass', 'path'],
            field: SmartTileField.cell(semanticCells: List.filled(count, 1))),
      CollisionLayer(
          id: 'collision',
          name: 'Collision',
          collisions: List.filled(count, false)),
    ],
  );
  final manifest = ProjectManifest(
    name: 'Batch fixture',
    version: spatial ? ProjectVersion.v9 : ProjectVersion.v8,
    settings: spatial
        ? ProjectSettings(
            dimension: ProjectDimension.threeD,
            spatialCamera: SpatialCameraProfile())
        : const ProjectSettings(),
    maps: const [
      ProjectMapEntry(id: 'map', name: 'Map', relativePath: 'maps/map.json')
    ],
    tilesets: const [
      ProjectTilesetEntry(
          id: 'tileset', name: 'Tileset', relativePath: 'assets/tileset.png')
    ],
    smartTileCatalog: ProjectSmartTileCatalog(
      atlases: [
        ProjectSmartTileAtlas(
            id: 'atlas',
            name: 'Atlas',
            tilesetId: 'tileset',
            columns: 1,
            rows: 1)
      ],
      materials: [
        for (final id in ['grass', 'path'])
          ProjectSmartTileMaterial(
              id: id, name: id, connectionGroupId: 'ground')
      ],
      presets: [
        ProjectSmartTilePreset(
          id: 'ground-preset',
          name: 'Ground',
          usage: SmartTileUsage.terrain,
          topology: SmartTileTopology.uniform,
          templateHint: SmartTileTemplateHint.simple,
          status: SmartTilePresetStatus.published,
          coveragePolicy: SmartTileCoveragePolicy.sparse,
          coverageProfile:
              SmartTileCoverageProfile(mode: SmartTileCoverageMode.template),
          transformPolicy: SmartTileTransformPolicy(),
          defaultMaterialId: 'grass',
          allowedMaterialIds: const ['grass', 'path'],
          rules: [
            for (final id in ['grass', 'path'])
              SmartTileRule(
                  id: id,
                  centerMatch: SmartTileSlotMatch.material(id),
                  signature: SmartTileSignature(),
                  candidates: [
                    SmartTileCandidate(id: id, parts: [
                      SmartTileVisualPart(
                          source: SmartTileVisualSource.frame(
                              frame: SmartTileFrameRef(
                                  atlasId: 'atlas', column: 0, row: 0)))
                    ])
                  ])
          ],
        )
      ],
    ),
  );
  final resources = <String, List<int>>{
    'project': utf8.encode(jsonEncode(manifest.toJson())),
    'map:map': utf8.encode(jsonEncode(map.toJson())),
  };
  return (
    map: map,
    snapshot: ProjectSnapshot(
      projectHandle: const ProjectHandle('project:batch'),
      revision: computeAuthoringBytesFingerprint(resources['map:map']!,
          logicalName: 'batch-fixture'),
      manifest: manifest,
      maps: [map],
      resourceBytes: resources,
      resourceFingerprints: {
        for (final entry in resources.entries)
          entry.key: computeAuthoringBytesFingerprint(entry.value,
              logicalName:
                  entry.key == 'project' ? 'project.json' : 'maps/map.json')
      },
      resourceStorageKeys: const {
        'project': 'project.json',
        'map:map': 'maps/map.json'
      },
    )
  );
}
