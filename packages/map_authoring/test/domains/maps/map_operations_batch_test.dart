import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _tile6 = <String, Object?>{
  'tilesetId': 'tileset',
  'localTileId': 6,
};
const _tile7 = <String, Object?>{
  'tilesetId': 'tileset',
  'localTileId': 7,
};
const _tile8 = <String, Object?>{
  'tilesetId': 'tileset',
  'localTileId': 8,
};
const _tile9 = <String, Object?>{
  'tilesetId': 'tileset',
  'localTileId': 9,
};
const _tile11 = <String, Object?>{
  'tilesetId': 'tileset',
  'localTileId': 11,
};
const _testTileset = ProjectTilesetEntry(
  id: 'tileset',
  name: 'Tileset',
  relativePath: 'assets/tileset.png',
  source: ProjectRegularAtlasTilesetSource(
    assetId: 'tileset-image',
    pixelWidth: 16,
    pixelHeight: 1,
    tileWidth: 1,
    tileHeight: 1,
  ),
);

void main() {
  group('MapOperationsActions', () {
    test('advertises one bounded atomic mutation action', () {
      expect(MapOperationsActions.descriptors, hasLength(1));
      final descriptor = MapOperationsActions.descriptors.single;
      expect(descriptor.id, 'map.apply_operations');
      expect(descriptor.guarantees, contains(AuthoringGuarantee.dryRun));
      expect(descriptor.guarantees, contains(AuthoringGuarantee.undoable));
      expect(descriptor.extensions['batchAtomicity'], 'all_or_nothing');
      expect(descriptor.extensions['tileLayerEncoding'], 'tile_palette_v1');
      expect(
        descriptor.extensions['tileLayerAddParameters'],
        isNot(contains('tilesetId')),
      );
      expect(
        descriptor.extensions['tileCellValue'],
        const <String, Object?>{
          'empty': null,
          'entrySchema': 'tile_palette_entry_v1',
        },
      );
      expect(
        descriptor.extensions['boundedRegionQuery'],
        containsPair('requestExtension', 'region'),
      );
    });

    test('builds a complete map fixture as one compact map change', () {
      final map = _map();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {
          'kind': 'layer.add',
          'layerKind': 'collision',
          'layerId': 'collision',
          'name': 'Collision',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'object',
          'layerId': 'objects',
          'name': 'Objects',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'environment',
          'layerId': 'environment',
          'name': 'Environment',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'border',
          'layerId': 'border',
          'name': 'Border',
        },
        {
          'kind': 'region.fill',
          'layerId': 'tiles',
          'x': 0,
          'y': 0,
          'width': 4,
          'height': 3,
          'value': _tile11,
        },
        {
          'kind': 'shape.line',
          'layerId': 'collision',
          'from': {'x': 0, 'y': 0},
          'to': {'x': 3, 'y': 2},
          'value': true,
        },
      ]);

      final draft = const MapOperationsActions().build(
        _context(snapshot, request),
      );

      expect(draft.changeSet.changes, hasLength(1));
      expect(draft.changeSet.diff.entries, hasLength(1));
      final change = draft.changeSet.changes.single;
      expect(change.storageKey, 'maps/fixture.json');
      expect(change.beforeBytes, snapshot.resourceBytes('map:fixture'));
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
      );
      expect(updated.layers, hasLength(5));
      expect(updated.version, ProjectVersion.v6);
      expect(
        _resolvedLocalIds(updated.layers.first as TileLayer),
        everyElement(11),
      );
      expect(draft.preview['operationCount'], 6);
      expect(draft.preview['changedCellCount'], lessThanOrEqualTo(24));
      expect(
        jsonEncode(draft.preview).length,
        lessThan(4096),
        reason: 'receipts/previews must summarize rather than embed cell data',
      );
    });

    test('paints only requested cells on a regular tile layer', () {
      final map = _map();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 1,
          'y': 1,
          'value': _tile6,
        },
        {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 2,
          'y': 1,
          'value': _tile6,
        },
        {
          'kind': 'region.erase',
          'layerId': 'tiles',
          'x': 2,
          'y': 1,
        },
      ]);

      final draft = const MapOperationsActions().build(
        _context(snapshot, request),
      );
      final change = draft.changeSet.changes.single;
      final updated = MapData.fromJson(
        jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
      );
      final tiles = (updated.layers.single as TileLayer).cells;

      expect(
        resolveTileLayerCell(updated.layers.single as TileLayer, 5)
            ?.localTileId,
        6,
      );
      expect(tiles[6], 0);
      expect(tiles.where((cell) => cell != 0), hasLength(1));
    });

    test('rejects the complete batch when one operation is invalid', () {
      final map = _map();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 0,
          'y': 0,
          'value': _tile9,
        },
        {
          'kind': 'region.paint',
          'layerId': 'tiles',
          'x': 99,
          'y': 0,
          'value': _tile8,
        },
      ]);

      expect(
        () => const MapOperationsActions().build(_context(snapshot, request)),
        throwsA(
          isA<MapAuthoringException>()
              .having((error) => error.code, 'code', 'map.operation_invalid')
              .having((error) => error.details['operationIndex'], 'index', 1),
        ),
      );
      expect((map.layers.single as TileLayer).cells, everyElement(0));
      expect(
        snapshot.resourceBytes('map:fixture'),
        _encode(map.toJson()),
      );
    });

    test('clears every active Smart Tile field lattice exhaustively', () {
      final fields = <({String name, SmartTileField field})>[
        (
          name: 'cell',
          field: const SmartTileField.cell(semanticCells: [1, 0, 0, 0]),
        ),
        (
          name: 'corner',
          field: const SmartTileField.corner(
            semanticCells: [1, 0, 0, 0],
            corners: [1, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ),
        (
          name: 'edge',
          field: const SmartTileField.edge(
            semanticCells: [1, 0, 0, 0],
            horizontalEdges: [1, 0, 0, 0, 0, 0],
            verticalEdges: [1, 0, 0, 0, 0, 0],
          ),
        ),
        (
          name: 'mixed',
          field: const SmartTileField.mixed(
            semanticCells: [1, 0, 0, 0],
            horizontalEdges: [1, 0, 0, 0, 0, 0],
            verticalEdges: [1, 0, 0, 0, 0, 0],
            corners: [1, 0, 0, 0, 0, 0, 0, 0, 0],
          ),
        ),
      ];

      for (final testCase in fields) {
        final map = _nativeSmartTileV5Map(testCase.field);
        final snapshot = _snapshot(map);
        final beforeBytes = snapshot.resourceBytes('map:fixture');
        final request = _request(snapshot, const [
          {'kind': 'layer.clear', 'layerId': 'smart'},
        ]);

        final draft = const MapOperationsActions().build(
          _context(snapshot, request),
        );
        final change = draft.changeSet.changes.single;
        final updated = MapData.fromJson(
          jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
        );
        final cleared = updated.layers.last as SmartTileLayer;

        expect(cleared.field.runtimeType, testCase.field.runtimeType);
        expect(smartTileSemanticCells(cleared), everyElement(0));
        expect(smartTileHorizontalEdges(cleared), everyElement(0));
        expect(smartTileVerticalEdges(cleared), everyElement(0));
        expect(smartTileCorners(cleared), everyElement(0));
        expect(snapshot.resourceBytes('map:fixture'), beforeBytes);
      }
    });

    test('preserves a precise forbidden Smart Tile material diagnostic', () {
      final map = _legacyPaletteMap();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {
          'kind': 'layer.rename',
          'layerId': 'smart_path',
          'name': 'Renamed path',
        },
      ]);

      expect(
        () => const MapOperationsActions().build(_context(snapshot, request)),
        throwsA(
          isA<MapAuthoringException>()
              .having(
                (error) => error.code,
                'code',
                'map.smart_tile_material_not_allowed',
              )
              .having(
                (error) => error.message,
                'message',
                allOf(
                  contains('smart_material_empty'),
                  contains('smart_path'),
                ),
              )
              .having(
                (error) => error.details['layerId'],
                'layerId',
                'smart_path',
              )
              .having(
                (error) => error.details['field'],
                'field',
                'materialPalette',
              )
              .having(
                (error) => error.details['materialId'],
                'materialId',
                'smart_material_empty',
              )
              .having(
                (error) => error.details['presetId'],
                'presetId',
                'smart_path',
              )
              .having(
                (error) => error.details['validationState'],
                'validationState',
                'pre_existing',
              )
              .having(
                (error) => error.remediation,
                'remediation',
                contains('Run smart_tile.layer.normalize for smart_path.'),
              ),
        ),
      );
    });

    test('reports an initial Smart Tile issue repaired by the projected batch',
        () {
      final map = _legacyPaletteMap();
      final snapshot = _snapshot(map);
      final request = _request(snapshot, const [
        {'kind': 'layer.delete', 'layerId': 'smart_path'},
      ]);

      final draft = const MapOperationsActions().build(
        _context(snapshot, request),
      );
      final validation = draft.preview['validation']! as Map<String, Object?>;

      expect(validation['initialStatus'], 'invalid');
      expect(validation['projectedStatus'], 'valid');
      expect(validation['repaired'], isTrue);
      expect(
        (validation['initialIssue']! as Map<String, Object?>)['code'],
        'map.smart_tile_material_not_allowed',
      );
      expect(
        snapshot.resourceBytes('map:fixture'),
        _encode(map.toJson()),
        reason: 'planning and validation must not mutate the source snapshot',
      );
    });

    test('layer lifecycle supports canonical non-Smart-Tile kinds', () {
      var map = _map();
      const operations = MapLayerOperations();
      for (final operation in const [
        {
          'kind': 'layer.add',
          'layerKind': 'collision',
          'layerId': 'collision',
          'name': 'Collision',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'object',
          'layerId': 'objects',
          'name': 'Objects',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'environment',
          'layerId': 'environment',
          'name': 'Environment',
        },
        {
          'kind': 'layer.add',
          'layerKind': 'border',
          'layerId': 'border',
          'name': 'Border',
        },
      ]) {
        map = operations.apply(map, operation).map;
      }
      map = operations.apply(map, const {
        'kind': 'layer.rename',
        'layerId': 'collision',
        'name': 'Walls',
      }).map;
      map = operations.apply(map, const {
        'kind': 'layer.set_visibility',
        'layerId': 'collision',
        'isVisible': false,
      }).map;
      map = operations.apply(map, const {
        'kind': 'layer.set_opacity',
        'layerId': 'collision',
        'opacity': 0.5,
      }).map;
      map = operations.apply(map, const {
        'kind': 'layer.reorder',
        'oldIndex': 4,
        'newIndex': 1,
      }).map;

      expect(
          map.layers.map((layer) => layer.runtimeType).toSet(), hasLength(5));
      final collision = map.layers.whereType<CollisionLayer>().single;
      expect(collision.name, 'Walls');
      expect(collision.isVisible, isFalse);
      expect(collision.opacity, 0.5);
      expect(map.version, ProjectVersion.v6);
    });

    test('applies one transaction receipt and undoes the complete batch',
        () async {
      final setup = await _TransactionSetup.create();
      addTearDown(setup.dispose);
      final beforeBytes = await setup.mapFile.readAsBytes();
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final request = AuthoringRequest(
        requestId: 'request_apply_batch',
        actionId: 'map.apply_operations',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        parameters: const {
          'mapId': 'fixture',
          'operations': [
            {
              'kind': 'region.fill',
              'layerId': 'tiles',
              'x': 0,
              'y': 0,
              'width': 4,
              'height': 3,
              'value': _tile6,
            },
            {
              'kind': 'region.erase',
              'layerId': 'tiles',
              'x': 1,
              'y': 1,
            },
          ],
        },
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_apply_batch',
        dryRun: false,
      );

      final planned = await setup.mutations.plan(setup.projectHandle, request);
      final applied = await setup.mutations.apply(
        setup.projectHandle,
        planId: planned['planId']! as String,
        operationId: 'operation_apply_batch',
      );

      final receipt = applied['receipt']! as Map<String, Object?>;
      expect(receipt['actionId'], 'map.apply_operations');
      expect(receipt['status'], 'applied');
      final updated = MapData.fromJson(
        jsonDecode(await setup.mapFile.readAsString()) as Map<String, dynamic>,
      );
      expect(
        resolveTileLayerCell(updated.layers.single as TileLayer, 0)
            ?.localTileId,
        6,
      );
      expect((updated.layers.single as TileLayer).cells[5], 0);

      final undone = await setup.mutations.undo(
        setup.projectHandle,
        entryId: receipt['receiptId']! as String,
        idempotencyKey: 'idem_undo_batch',
      );
      expect(
        (undone['receipt']! as Map<String, Object?>)['actionId'],
        'history.undo',
      );
      expect(await setup.mapFile.readAsBytes(), beforeBytes);
    });

    test('invalid transaction batch never changes the map file', () async {
      final setup = await _TransactionSetup.create();
      addTearDown(setup.dispose);
      final beforeBytes = await setup.mapFile.readAsBytes();
      final snapshot = await setup.snapshots.load(setup.projectHandle);
      final request = AuthoringRequest(
        requestId: 'request_invalid_batch',
        actionId: 'map.apply_operations',
        actionVersion: 1,
        workspaceHandle: setup.workspaceHandle.value,
        parameters: const {
          'mapId': 'fixture',
          'operations': [
            {
              'kind': 'region.paint',
              'layerId': 'tiles',
              'x': 0,
              'y': 0,
              'value': _tile6,
            },
            {
              'kind': 'region.paint',
              'layerId': 'tiles',
              'x': -1,
              'y': 0,
              'value': _tile7,
            },
          ],
        },
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_invalid_batch',
        dryRun: false,
      );

      await expectLater(
        () => setup.mutations.plan(setup.projectHandle, request),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'map.operation_invalid',
          ),
        ),
      );
      expect(await setup.mapFile.readAsBytes(), beforeBytes);
    });
  });
}

final class _TransactionSetup {
  _TransactionSetup._({
    required this.root,
    required this.mapFile,
    required this.mutations,
    required this.workspaceHandle,
    required this.projectHandle,
    required this.snapshots,
  });

  static Future<_TransactionSetup> create() async {
    final root = await Directory.systemTemp.createTemp('map-batch-');
    final map = _map();
    final manifest = ProjectManifest(
      name: 'Map Batch Transaction Fixture',
      version: ProjectVersion.v6,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [_testTileset],
    );
    await File('${root.path}/project.json').writeAsBytes(
      _encode(manifest.toJson()),
      flush: true,
    );
    await Directory('${root.path}/maps').create();
    final mapFile = File('${root.path}/maps/fixture.json');
    await mapFile.writeAsBytes(_encode(map.toJson()), flush: true);
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
      allowedRootPaths: [root.path],
      fileReader: reader,
    );
    final handles = WorkspaceHandleStore(
      tokenFactory: (prefix) => '${prefix}batchfixture',
    );
    final open = ProjectOpenService(
      policy: policy,
      fileReader: reader,
      handles: handles,
    );
    final opened = await open.openProject(root.path);
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final mutations = LocalMapAuthoringMutationApi(
      policy: policy,
      snapshotLoader: snapshots,
    );
    await mutations.attachProject(
      projectRootPath: root.path,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
    );
    return _TransactionSetup._(
      root: root,
      mapFile: mapFile,
      mutations: mutations,
      workspaceHandle: opened.workspaceHandle,
      projectHandle: opened.projectHandle,
      snapshots: snapshots,
    );
  }

  final Directory root;
  final File mapFile;
  final LocalMapAuthoringMutationApi mutations;
  final WorkspaceHandle workspaceHandle;
  final ProjectHandle projectHandle;
  final ProjectSnapshotLoader snapshots;

  Future<void> dispose() async {
    await mutations.detachWorkspace(workspaceHandle);
    if (await root.exists()) await root.delete(recursive: true);
  }
}

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: 'plan_batch',
      seed: 123,
    );

AuthoringRequest _request(
  ProjectSnapshot snapshot,
  List<Map<String, Object?>> operations,
) =>
    AuthoringRequest(
      requestId: 'request_batch',
      actionId: 'map.apply_operations',
      actionVersion: 1,
      workspaceHandle: 'ws_fixture',
      parameters: {'mapId': 'fixture', 'operations': operations},
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idem_batch',
      dryRun: true,
    );

ProjectSnapshot _snapshot(MapData map) {
  final smartPathTopology =
      switch (map.layers.whereType<SmartTileLayer>().firstOrNull?.field) {
    SmartTileCornerField() => SmartTileTopology.wangCorner4,
    SmartTileEdgeField() => SmartTileTopology.wangEdge4,
    SmartTileMixedField() => SmartTileTopology.wang8,
    SmartTileCellField() || null => SmartTileTopology.cardinal4,
  };
  final isNativeSmartTileProject = map.version == ProjectVersion.v6;
  final manifest = ProjectManifest(
    name: 'Batch Fixture',
    version: isNativeSmartTileProject ? ProjectVersion.v6 : ProjectVersion.v6,
    maps: const [
      ProjectMapEntry(
        id: 'fixture',
        name: 'Fixture',
        relativePath: 'maps/fixture.json',
      ),
    ],
    tilesets: const [_testTileset],
    smartTileCatalog: isNativeSmartTileProject
        ? ProjectSmartTileCatalog(
            materials: const [
              ProjectSmartTileMaterial(
                id: 'road',
                name: 'Road',
                connectionGroupId: 'road',
              ),
              ProjectSmartTileMaterial(
                id: 'smart_material_empty',
                name: 'Legacy empty',
                connectionGroupId: 'empty',
                isEmpty: true,
              ),
              ProjectSmartTileMaterial(
                id: 'grass',
                name: 'Grass',
                connectionGroupId: 'grass',
              ),
            ],
            presets: [
              ProjectSmartTilePreset(
                id: 'smart_path',
                name: 'Smart Path',
                usage: SmartTileUsage.path,
                topology: smartPathTopology,
                coveragePolicy: SmartTileCoveragePolicy.complete,
                coverageProfile: const SmartTileCoverageProfile(
                  mode: SmartTileCoverageMode.template,
                ),
                transformPolicy: const SmartTileTransformPolicy(),
                defaultMaterialId: 'road',
                allowedMaterialIds: const ['road'],
              ),
              const ProjectSmartTilePreset(
                id: 'smart_terrain',
                name: 'Smart Terrain',
                usage: SmartTileUsage.terrain,
                topology: SmartTileTopology.cardinal4,
                coveragePolicy: SmartTileCoveragePolicy.complete,
                coverageProfile: SmartTileCoverageProfile(
                  mode: SmartTileCoverageMode.template,
                ),
                transformPolicy: SmartTileTransformPolicy(),
                defaultMaterialId: 'grass',
                allowedMaterialIds: ['grass'],
              ),
            ],
          )
        : const ProjectSmartTileCatalog.empty(),
  );
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(map.toJson());
  final mapRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'maps/fixture.json',
      bytes: mapBytes,
    ),
  ]);
  final projectRevision = computeNarrativeProjectFingerprint([
    NarrativeProjectFingerprintEntry(
      relativePath: 'project.json',
      bytes: manifestBytes,
    ),
  ]);
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: [map],
    resourceFingerprints: {
      'project': projectRevision,
      'map:fixture': mapRevision
    },
    resourceBytes: {'project': manifestBytes, 'map:fixture': mapBytes},
  );
}

MapData _map() => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: const GridSize(width: 4, height: 3),
      version: ProjectVersion.v6,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          cells: List<int>.filled(12, 0),
        ),
      ],
    );

MapData _nativeSmartTileV5Map(SmartTileField field) => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: const GridSize(width: 2, height: 2),
      version: ProjectVersion.v6,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        const MapLayer.tile(
          id: 'base',
          name: 'Base',
          cells: [0, 0, 0, 0],
        ),
        SmartTileLayer(
          id: 'smart',
          name: 'Smart',
          presetId: 'smart_path',
          usage: SmartTileUsage.path,
          materialPalette: const ['', 'road'],
          field: field,
        ),
      ],
    );

MapData _legacyPaletteMap() => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: const GridSize(width: 4, height: 3),
      version: ProjectVersion.v6,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.tile(
          id: 'tiles',
          name: 'Tiles',
          cells: List<int>.filled(12, 0),
        ),
        MapLayer.smartTile(
          id: 'smart_path',
          name: 'Smart path',
          presetId: 'smart_path',
          usage: SmartTileUsage.path,
          materialPalette: const ['', 'road', 'smart_material_empty'],
          field: SmartTileField.cell(
            semanticCells: List<int>.filled(12, 0),
          ),
        ),
      ],
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));

List<int> _resolvedLocalIds(TileLayer layer) => <int>[
      for (var index = 0; index < layer.cells.length; index++)
        resolveTileLayerCell(layer, index)?.localTileId ?? 0,
    ];
