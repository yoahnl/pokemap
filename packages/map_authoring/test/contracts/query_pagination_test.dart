import 'dart:convert';

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
    ),
    _map(
      id: 'b-map',
      name: 'Bravo Field',
      width: 2,
      tiles: const [7, 8, 9, 10],
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
        tiles: tiles,
      ),
    ],
    properties: {
      'description': 'A detailed projection carries this field.',
      'tags': id == 'a-map' ? ['forest', 'day'] : ['city'],
    },
  );
}
