import 'dart:convert';
import 'dart:math' as math;

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('AuthoringQueryRequest', () {
    test('round-trips strict canonical JSON', () {
      final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.search,
        view: AuthoringQueryView.detail,
        searchTerm: ' field ',
        fieldMask: const ['size.width', 'name', 'name'],
        filters: const {'version': 'v6'},
        sort: const [
          AuthoringQuerySort(field: 'name', descending: true),
        ],
        pageSize: 2,
      );

      final decoded = AuthoringQueryRequest.fromJson(
        Map<String, dynamic>.from(
          jsonDecode(jsonEncode(request.toJson())) as Map,
        ),
      );

      expect(decoded.toJson(), request.toJson());
      expect(decoded.searchTerm, 'field');
      expect(decoded.fieldMask, ['name', 'size.width']);
      expect(decoded.signature, request.signature);
    });

    test('rejects unknown fields and operation-specific invalid input', () {
      expect(
        () => AuthoringQueryRequest.fromJson({
          'resourceKind': 'map',
          'operation': 'list',
          'view': 'summary',
          'ids': <Object?>[],
          'fieldMask': <Object?>[],
          'filters': <String, Object?>{},
          'sort': <Object?>[],
          'pageSize': 10,
          'unknown': true,
        }),
        throwsFormatException,
      );
      expect(
        () => AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
        ),
        throwsArgumentError,
      );
      expect(
        () => AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: ' ',
        ),
        throwsArgumentError,
      );
    });
  });

  group('ProjectQueryService pagination', () {
    test('paginates deterministically across a frozen snapshot', () {
      final snapshot = _snapshot();
      final request = AuthoringQueryRequest(
        resourceKind: 'map',
        operation: AuthoringQueryOperation.list,
        pageSize: 1,
      );

      final first = const ProjectQueryService().query(snapshot, request);
      final second = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
          cursor: first.nextCursor,
        ),
      );
      final third = const ProjectQueryService().query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
          cursor: second.nextCursor,
        ),
      );

      expect(
        [
          first.items.single['id'],
          second.items.single['id'],
          third.items.single['id']
        ],
        ['a-map', 'b-map', 'c-map'],
      );
      expect(first.snapshotRevision, snapshot.revision);
      expect(first.totalAvailable, 3);
      expect(third.nextCursor, isNull);
    });

    test('rejects a cursor bound to another revision', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();
      final first = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          pageSize: 1,
        ),
      );
      final changed = _snapshot(revisionDigit: 'b');

      expect(
        () => service.query(
          changed,
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.list,
            pageSize: 1,
            cursor: first.nextCursor,
          ),
        ),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.cursor_stale',
          ),
        ),
      );
    });

    test('rejects a cursor reused with a different normalized query', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();
      final first = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'map',
          pageSize: 1,
        ),
      );

      expect(
        () => service.query(
          snapshot,
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.search,
            searchTerm: 'bravo',
            pageSize: 1,
            cursor: first.nextCursor,
          ),
        ),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.cursor_mismatch',
          ),
        ),
      );
    });
  });

  group('ProjectQueryService operations', () {
    test('lists visual folders and categories as first-class resources', () {
      const service = ProjectQueryService();
      final snapshot = _snapshot();
      final folders = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'tilesetFolder',
          operation: AuthoringQueryOperation.list,
        ),
      );
      final categories = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'elementCategory',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );

      expect(folders.items.single, {
        'id': 'm02',
        'name': 'M02',
        'resourceKind': 'tilesetFolder',
        'parentFolderId': null,
        'sortOrder': 2,
      });
      expect(categories.items.single['id'], 'nature');
      expect(categories.items.single['parentCategoryId'], isNull);
    });

    test('supports get, batch_get, search, and project summary', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();

      final get = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: ['b-map'],
        ),
      );
      final batch = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.batchGet,
          ids: ['c-map', 'a-map'],
        ),
      );
      final search = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'bravo',
        ),
      );
      final summary = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.summary,
        ),
      );

      expect(get.items.single['id'], 'b-map');
      expect(batch.items.map((item) => item['id']), ['a-map', 'c-map']);
      expect(search.items.single['name'], 'Bravo Field');
      expect(summary.items.single, containsPair('mapCount', 3));
    });

    test('lists and gets map connections as first-class resources', () {
      final snapshot = _snapshot(withConnections: true);
      const service = ProjectQueryService();

      final listed = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'mapConnection',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
        ),
      );
      final fetched = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'mapConnection',
          operation: AuthoringQueryOperation.get,
          ids: const ['a-map:east'],
          view: AuthoringQueryView.detail,
        ),
      );

      expect(
        listed.items.map((item) => item['id']),
        ['a-map:east', 'b-map:west'],
      );
      expect(fetched.items.single, {
        'id': 'a-map:east',
        'name': 'Alpha Field — East',
        'resourceKind': 'mapConnection',
        'mapId': 'a-map',
        'direction': 'east',
        'targetMapId': 'b-map',
        'offset': 0,
      });
    });

    test('exposes map connections through the documented field mask', () {
      final page = const ProjectQueryService().query(
        _snapshot(withConnections: true),
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: const ['a-map'],
          fieldMask: const ['connections'],
        ),
      );

      expect(page.items.single['connections'], [
        {
          'direction': 'east',
          'targetMapId': 'b-map',
          'offset': 0,
        },
      ]);
    });

    test('previews a hypothetical connection alignment through query actions',
        () {
      final page = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'mapConnection',
          operation: AuthoringQueryOperation.summary,
          view: AuthoringQueryView.detail,
          extensions: const {
            'actionId': 'connection.preview_alignment',
            'parameters': {
              'mapId': 'a-map',
              'targetMapId': 'b-map',
              'direction': 'east',
              'offset': 1,
            },
          },
        ),
      );

      expect(page.items.single, {
        'id': 'a-map:east:b-map:1',
        'name': 'Alpha Field — East alignment',
        'resourceKind': 'mapConnection',
        'actionId': 'connection.preview_alignment',
        'mapId': 'a-map',
        'targetMapId': 'b-map',
        'direction': 'east',
        'offset': 1,
        'sourceStart': 1,
        'targetStart': 0,
        'overlapLength': 1,
        'hasOverlap': true,
      });
    });

    test('validates authored connections through query actions', () {
      final page = const ProjectQueryService().query(
        _snapshot(withBrokenConnection: true),
        AuthoringQueryRequest(
          resourceKind: 'mapConnection',
          operation: AuthoringQueryOperation.summary,
          view: AuthoringQueryView.detail,
          extensions: const {
            'actionId': 'connection.validate',
            'parameters': <String, Object?>{},
          },
        ),
      );

      final item = page.items.single;
      expect(item['id'], 'connection-validation');
      expect(item['valid'], isFalse);
      expect(item['connectionCount'], 1);
      expect(
        (item['issues']! as List).cast<Map>().map((issue) => issue['code']),
        containsAll([
          'world_graph.connection_no_overlap',
          'world_graph.connection_reciprocal_mismatch',
        ]),
      );
    });

    test('projects a bounded world graph through paginated resources', () {
      final snapshot = _snapshot(withConnections: true);
      const service = ProjectQueryService();
      final graph = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'worldGraph',
          operation: AuthoringQueryOperation.get,
          ids: const ['world-graph'],
          view: AuthoringQueryView.detail,
        ),
      );
      final firstEdge = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'worldGraphEdge',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 1,
        ),
      );
      final secondEdge = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'worldGraphEdge',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 1,
          cursor: firstEdge.nextCursor,
        ),
      );

      expect(graph.items.single, {
        'id': 'world-graph',
        'name': 'World graph',
        'resourceKind': 'worldGraph',
        'nodeCount': 3,
        'edgeCount': 2,
        'issueCount': 0,
        'isConsistent': true,
        'resources': {
          'nodes': 'worldGraphNode',
          'edges': 'worldGraphEdge',
          'issues': 'worldGraphIssue',
        },
        'render': {
          'hasPersistentLayout': false,
          'layoutPolicy': 'logical_graph_only',
          'nodeResourceKind': 'worldGraphNode',
          'edgeResourceKind': 'worldGraphEdge',
        },
      });
      expect(firstEdge.returned, 1);
      expect(firstEdge.totalAvailable, 2);
      expect(firstEdge.nextCursor, isNotNull);
      expect(secondEdge.returned, 1);
      expect(secondEdge.nextCursor, isNull);
    });

    test('runs bounded world graph traversal query actions', () {
      final snapshot = _snapshot(withConnections: true);
      const service = ProjectQueryService();

      AuthoringQueryPage traverse(
        String actionId,
        Map<String, Object?> parameters,
      ) =>
          service.query(
            snapshot,
            AuthoringQueryRequest(
              resourceKind: 'worldGraphNode',
              operation: AuthoringQueryOperation.list,
              view: AuthoringQueryView.detail,
              extensions: {
                'actionId': actionId,
                'parameters': parameters,
              },
            ),
          );

      expect(
        traverse(
          'world_graph.list_connected',
          const {'fromMapId': 'a-map'},
        ).items.map((item) => item['mapId']),
        ['a-map', 'b-map'],
      );
      expect(
        traverse(
          'world_graph.list_disconnected',
          const {'fromMapId': 'a-map'},
        ).items.map((item) => item['mapId']),
        ['c-map'],
      );
      final path = traverse(
        'world_graph.find_path',
        const {'sourceMapId': 'a-map', 'targetMapId': 'b-map'},
      );
      expect(path.items.map((item) => item['mapId']), ['a-map', 'b-map']);
      expect(path.items.map((item) => item['pathIndex']), [0, 1]);
    });

    test('exposes world graph consistency issues as bounded resources', () {
      final page = const ProjectQueryService().query(
        _snapshot(withBrokenConnection: true),
        AuthoringQueryRequest(
          resourceKind: 'worldGraphIssue',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          pageSize: 1,
        ),
      );

      expect(page.returned, 1);
      expect(page.totalAvailable, 2);
      expect(page.nextCursor, isNotNull);
      expect(
        page.items.single['code'],
        startsWith('world_graph.connection_'),
      );
    });

    test('applies filters, descending sort, and dotted field masks', () {
      final page = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          view: AuthoringQueryView.detail,
          filters: {'size.width': 2},
          sort: [
            AuthoringQuerySort(field: 'name', descending: true),
          ],
          fieldMask: ['size.width'],
        ),
      );

      expect(page.items.map((item) => item['id']), ['c-map', 'b-map']);
      expect(page.items.first.keys, ['id', 'name', 'resourceKind', 'size']);
      expect(page.items.first['size'], {'width': 2});
    });

    test('compares composite JSON filter values deeply', () {
      final page = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.list,
          filters: {
            'properties.tags': ['forest', 'day'],
          },
        ),
      );

      expect(page.items.map((item) => item['id']), ['a-map']);
    });

    test('summary is smaller than detail without losing identity', () {
      final snapshot = _snapshot();
      const service = ProjectQueryService();
      final summary = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: ['a-map'],
        ),
      );
      final detail = service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: ['a-map'],
          view: AuthoringQueryView.detail,
        ),
      );
      final summaryJson = jsonEncode(summary.toJson());
      final detailJson = jsonEncode(detail.toJson());

      expect(summary.items.single['id'], detail.items.single['id']);
      expect(summary.items.single['name'], detail.items.single['name']);
      expect(summary.items.single['resourceKind'], 'map');
      expect(summaryJson.length, lessThan(detailJson.length));
    });

    test('does not expose manifest paths or the persisted editor API key', () {
      final page = const ProjectQueryService().query(
        _snapshot(withApiKey: true),
        AuthoringQueryRequest(
          resourceKind: 'project',
          operation: AuthoringQueryOperation.get,
          ids: ['project'],
          view: AuthoringQueryView.detail,
        ),
      );
      final encoded = jsonEncode(page.toJson());

      expect(encoded, isNot(contains('relativePath')));
      expect(encoded, isNot(contains('mistralApiKey')));
      expect(encoded, isNot(contains('super-secret')));
    });

    test('projects one bounded canonical tile-palette region', () {
      final page = const ProjectQueryService().query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'map',
          operation: AuthoringQueryOperation.get,
          ids: const <String>['a-map'],
          view: AuthoringQueryView.detail,
          extensions: const <String, Object?>{
            'region': <String, Object?>{
              'x': 0,
              'y': 0,
              'width': 2,
              'height': 1,
            },
          },
        ),
      );

      final region = page.items.single;
      final layer =
          (region['layers']! as List).cast<Map<String, Object?>>().single;
      expect(region['mapId'], 'a-map');
      expect(layer['encoding'], 'tile_palette_v1');
      expect(layer['rows'], <Object?>[
        <Object?>[1, 2],
      ]);
      expect(
        (layer['palette']! as List)
            .cast<Map<String, Object?>>()
            .take(2)
            .map((entry) => entry['localTileId']),
        <int>[0, 1],
      );
      expect(page.totalAvailable, 1);
      expect(page.nextCursor, isNull);
    });
  });

  group('AuthoringQueryPage', () {
    test('rejects a serialized returned count that does not match items', () {
      final page = const ProjectQueryService()
          .query(
            _snapshot(),
            AuthoringQueryRequest(
              resourceKind: 'map',
              operation: AuthoringQueryOperation.list,
              pageSize: 1,
            ),
          )
          .toJson();

      expect(
        () => AuthoringQueryPage.fromJson({...page, 'returned': 99}),
        throwsFormatException,
      );
    });

    test('rejects a malformed continuation cursor', () {
      expect(
        () => const ProjectQueryService().query(
          _snapshot(),
          AuthoringQueryRequest(
            resourceKind: 'map',
            operation: AuthoringQueryOperation.list,
            cursor: 'not-base64-json',
          ),
        ),
        throwsA(
          isA<AuthoringQueryException>().having(
            (error) => error.code,
            'code',
            'query.cursor_invalid',
          ),
        ),
      );
    });
  });
}

ProjectSnapshot _snapshot({
  String revisionDigit = 'a',
  bool withApiKey = false,
  bool withConnections = false,
  bool withBrokenConnection = false,
}) {
  final maps = [
    _map(
      id: 'c-map',
      name: 'Charlie Field',
      width: 2,
      tiles: const [1, 2, 3, 4],
    ),
    _map(
      id: 'a-map',
      name: 'Alpha Field',
      width: 3,
      tiles: const [1, 2, 3, 4, 5, 6],
      connections: withBrokenConnection
          ? const [
              MapConnection(
                direction: MapConnectionDirection.east,
                targetMapId: 'b-map',
                offset: 4,
              ),
            ]
          : withConnections
              ? const [
                  MapConnection(
                    direction: MapConnectionDirection.east,
                    targetMapId: 'b-map',
                  ),
                ]
              : const [],
    ),
    _map(
      id: 'b-map',
      name: 'Bravo Field',
      width: 2,
      tiles: const [7, 8, 9, 10],
      connections: withConnections && !withBrokenConnection
          ? const [
              MapConnection(
                direction: MapConnectionDirection.west,
                targetMapId: 'a-map',
              ),
            ]
          : const [],
    ),
  ];
  final manifest = ProjectManifest(
    name: 'Query Project',
    version: ProjectVersion.v6,
    maps: [
      for (final map in maps)
        ProjectMapEntry(
          id: map.id,
          name: map.name,
          relativePath: 'maps/${map.id}.json',
        ),
    ],
    tilesets: const [],
    tilesetFolders: const [
      ProjectTilesetFolder(id: 'm02', name: 'M02', sortOrder: 2),
    ],
    elementCategories: const [
      ProjectElementCategory(id: 'nature', name: 'Nature'),
    ],
    settings: ProjectSettings(
      mistralApiKey: withApiKey ? 'super-secret' : null,
    ),
  );
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_query'),
    revision: 'sha256:${List.filled(64, revisionDigit).join()}',
    manifest: manifest,
    maps: maps,
    resourceFingerprints: {
      'project': 'sha256:${List.filled(64, '1').join()}',
      for (final map in maps)
        'map:${map.id}':
            'sha256:${List.filled(64, map.id.codeUnitAt(0).isEven ? '2' : '3').join()}',
    },
  );
}

MapData _map({
  required String id,
  required String name,
  required int width,
  required List<int> tiles,
  List<MapConnection> connections = const [],
}) {
  return MapData(
    id: id,
    name: name,
    size: GridSize(width: width, height: 2),
    version: ProjectVersion.v6,
    layers: [
      MapLayer.tile(
        id: '$id-ground',
        name: 'Ground',
        palette: [
          for (var tileId = 1; tileId <= tiles.reduce(math.max); tileId++)
            TileLayerPaletteEntry(
              tilesetId: 'tileset',
              localTileId: tileId - 1,
            ),
        ],
        cells: tiles,
      ),
    ],
    properties: {
      'description': 'A detailed projection carries this field.',
      'tags': id == 'a-map' ? ['forest', 'day'] : ['city'],
    },
    connections: connections,
  );
}
