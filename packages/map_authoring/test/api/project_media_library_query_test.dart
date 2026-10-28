import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test('asset audio candidates include legacy extensions without opening maps',
      () async {
    final fixture = await _Library.create();
    addTearDown(fixture.dispose);
    final artifact = ContentArtifactRef.fromBytes([1, 2],
        mediaType: 'application/octet-stream');
    final catalog = File('${fixture.root.path}/$assetCatalogStorageKey');
    await catalog.writeAsString(jsonEncode(AssetCatalog(records: [
      AssetRecord(
          id: 'legacy', logicalPath: 'audio/old.WAV', artifact: artifact),
      AssetRecord(
          id: 'image', logicalPath: 'images/other.png', artifact: artifact),
      AssetRecord(
          id: 'modern',
          logicalPath: 'audio/no-extension',
          artifact: ContentArtifactRef.fromBytes([3], mediaType: 'audio/ogg')),
    ]).toJson()));
    final page = await fixture.read.queryProject(
        fixture.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.list,
            filters: {'audioOnly': true},
            pageSize: 1));
    expect(page.items.single['id'], 'legacy');
    expect(page.totalAvailable, 2);
    final next = await fixture.read.queryProject(
        fixture.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.list,
            filters: const {'audioOnly': true},
            pageSize: 1,
            cursor: page.nextCursor));
    expect(next.items.single['id'], 'modern');
    final sorted = await fixture.read.queryProject(
        fixture.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.list,
            filters: const {'audioOnly': true},
            sort: const [AuthoringQuerySort(field: 'id', descending: true)]));
    expect(sorted.items.map((row) => row['id']), ['modern', 'legacy']);
    final sortedFirst = await fixture.read.queryProject(
        fixture.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.list,
            filters: const {'audioOnly': true},
            sort: const [AuthoringQuerySort(field: 'name')],
            pageSize: 1));
    await expectLater(
        fixture.read.queryProject(
            fixture.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'asset',
                operation: AuthoringQueryOperation.list,
                filters: const {'audioOnly': false},
                sort: const [AuthoringQuerySort(field: 'name')],
                pageSize: 1,
                cursor: sortedFirst.nextCursor)),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_stale')));
    final sortedNext = await fixture.read.queryProject(
        fixture.opened.projectHandle,
        AuthoringQueryRequest(
            resourceKind: 'asset',
            operation: AuthoringQueryOperation.list,
            filters: const {'audioOnly': true},
            sort: const [AuthoringQuerySort(field: 'name')],
            pageSize: 1,
            cursor: sortedFirst.nextCursor));
    expect(sortedNext.items.single['id'], 'legacy');
    final emptyCursor = jsonDecode(utf8.decode(
            base64Url.decode(base64Url.normalize(sortedFirst.nextCursor!))))
        as Map<String, dynamic>;
    emptyCursor['genericCursor'] = ' ';
    await expectLater(
        fixture.read.queryProject(
            fixture.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'asset',
                operation: AuthoringQueryOperation.list,
                filters: const {'audioOnly': true},
                sort: const [AuthoringQuerySort(field: 'name')],
                pageSize: 1,
                cursor:
                    base64Url.encode(utf8.encode(jsonEncode(emptyCursor))))),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_invalid')));
    await expectLater(
        fixture.read.queryProject(
            fixture.opened.projectHandle,
            AuthoringQueryRequest(
                resourceKind: 'asset',
                operation: AuthoringQueryOperation.list,
                filters: {'audioOnly': 'true'})),
        throwsA(isA<AuthoringQueryException>()
            .having((e) => e.code, 'code', 'query.filter_invalid')));
  });
  test('default identifier order precedes page slicing', () async {
    final fixture = await _Library.create();
    addTearDown(fixture.dispose);
    var page = await fixture.query(pageSize: 1);
    final ids = <Object?>[page.items.single['id']];
    while (page.nextCursor != null) {
      page = await fixture.query(pageSize: 1, cursor: page.nextCursor);
      ids.add(page.items.single['id']);
    }
    expect(ids, ['a', 'm', 'z']);
    expect(page.totalAvailable, 3);
  });
  test('summary always returns summary even when detail view was requested',
      () async {
    final fixture = await _Library.create();
    addTearDown(fixture.dispose);
    final page = await fixture.query(
        operation: AuthoringQueryOperation.summary,
        view: AuthoringQueryView.detail);
    expect(page.items.first.keys,
        containsAll(['id', 'name', 'kind', 'sourceAssetId']));
    expect(page.items.first.containsKey('label'), isFalse);
  });
  test('search matches identifier or label independently', () async {
    final fixture = await _Library.create();
    addTearDown(fixture.dispose);
    final acrossFields = await fixture.query(
        operation: AuthoringQueryOperation.search, term: 'a Alpha');
    expect(acrossFields.items, isEmpty);
    final unsearched = await fixture.query(term: 'absent');
    expect(unsearched.totalAvailable, 3);
    final label = await fixture.query(
        operation: AuthoringQueryOperation.search, term: 'ALPHA');
    expect(label.items.single['id'], 'a');
    final identifier = await fixture.query(
        operation: AuthoringQueryOperation.search, term: 'z');
    expect(identifier.items.single['id'], 'z');
  });
  test(
      'cursor rejects changed criteria and catalog but permits a new page size',
      () async {
    final fixture = await _Library.create();
    addTearDown(fixture.dispose);
    final first = await fixture.query(pageSize: 1);
    final rest = await fixture.query(pageSize: 2, cursor: first.nextCursor);
    expect(rest.items.map((item) => item['id']), ['m', 'z']);
    await expectLater(
        fixture.query(cursor: first.nextCursor, mask: ['id']),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_stale')));
    await expectLater(
        fixture.query(
            cursor: first.nextCursor,
            operation: AuthoringQueryOperation.search,
            term: 'Alpha'),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_stale')));
    final raw =
        jsonDecode(await fixture.media.readAsString()) as Map<String, dynamic>;
    (raw['entries'] as List).add(ProjectMediaAsset(
            id: 'next',
            label: 'Next',
            kind: ProjectMediaKind.audio,
            sourceAssetId: 'asset.next')
        .toJson());
    await fixture.media.writeAsString(jsonEncode(raw));
    await expectLater(
        fixture.query(cursor: first.nextCursor),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_stale')));
  });
  test('detail gets and masks preserve shape without reading missing maps',
      () async {
    final fixture = await _Library.create();
    addTearDown(fixture.dispose);
    final detail = await fixture.query(
        operation: AuthoringQueryOperation.get,
        ids: ['m'],
        view: AuthoringQueryView.detail);
    expect(detail.items.single['label'], 'Middle');
    final masked = await fixture.query(mask: ['id', 'name']);
    expect(masked.items.first,
        {'id': 'a', 'name': 'Alpha', 'resourceKind': 'presentationMedia'});
    final invalid = base64Url.encode(utf8.encode(jsonEncode(
        {'revision': detail.snapshotRevision, 'query': '{}', 'offset': -1})));
    await expectLater(fixture.query(cursor: invalid),
        throwsA(isA<AuthoringQueryException>()));
    await expectLater(
        fixture.query(operation: AuthoringQueryOperation.get, ids: ['missing']),
        throwsA(isA<AuthoringQueryException>().having(
            (error) => error.code, 'code', 'query.resource_not_found')));
  });
}

class _Library {
  _Library(this.root, this.media, this.read, this.opened);
  final Directory root;
  final File media;
  final AuthoringReadApi read;
  final OpenedProject opened;
  static Future<_Library> create() async {
    final root = await Directory.systemTemp.createTemp('media-query-');
    await File('${root.path}/project.json')
        .writeAsString(jsonEncode(const ProjectManifest(name: 'Media', maps: [
      ProjectMapEntry(
          id: 'missing', name: 'Missing', relativePath: 'maps/missing.json')
    ], tilesets: []).toJson()));
    final media = File('${root.path}/$projectMediaCatalogStorageKey');
    await media.parent.create(recursive: true);
    await media.writeAsString(jsonEncode({
      'schemaVersion': 1,
      'entries': [
        ProjectMediaAsset(
                id: 'z',
                label: 'Last',
                kind: ProjectMediaKind.audio,
                sourceAssetId: 'asset.z')
            .toJson(),
        ProjectMediaAsset(
                id: 'a',
                label: 'Alpha',
                kind: ProjectMediaKind.audio,
                sourceAssetId: 'asset.a')
            .toJson(),
        ProjectMediaAsset(
                id: 'm',
                label: 'Middle',
                kind: ProjectMediaKind.audio,
                sourceAssetId: 'asset.m')
            .toJson(),
      ]
    }));
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final snapshots = ProjectSnapshotLoader(handles: handles);
    final opener = ProjectOpenService(
        policy: policy,
        fileReader: reader,
        handles: handles,
        workshopScope: true);
    final read =
        AuthoringReadApi(openService: opener, snapshotLoader: snapshots);
    return _Library(root, media, read, await read.openProject(root.path));
  }

  Future<AuthoringQueryPage> query(
          {AuthoringQueryOperation operation = AuthoringQueryOperation.list,
          AuthoringQueryView view = AuthoringQueryView.summary,
          List<String> ids = const [],
          String? term,
          int pageSize = 50,
          String? cursor,
          List<String> mask = const []}) =>
      read.queryProject(
          opened.projectHandle,
          AuthoringQueryRequest(
              resourceKind: 'presentationMedia',
              operation: operation,
              view: view,
              ids: ids,
              searchTerm: term,
              filters: const {'kind': 'audio'},
              pageSize: pageSize,
              cursor: cursor,
              fieldMask: mask));
  Future<void> dispose() async {
    await root.delete(recursive: true);
  }
}
