import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final operation in [
    AuthoringQueryOperation.list,
    AuthoringQueryOperation.summary,
    AuthoringQueryOperation.search,
  ]) {
    test('${operation.name} summaries do not build validation', () {
      final metrics = _Metrics();
      final page = metrics.service.query(
        _snapshot(),
        AuthoringQueryRequest(
          resourceKind: 'eventV2',
          operation: operation,
          searchTerm:
              operation == AuthoringQueryOperation.search ? 'Event' : null,
          pageSize: 2,
        ),
      );
      expect(page.totalAvailable, 12);
      expect(page.items.map((item) => item['id']), [_id(0), _id(1)]);
      expect(
          page.items.every((item) => !item.containsKey('validation')), isTrue);
      expect(metrics.catalogs, 0);
      expect(metrics.validations, isEmpty);
    });
  }

  test('full detail validates only the page and shares one catalog per query',
      () {
    final snapshot = _snapshot();
    final metrics = _Metrics();
    final first = metrics.service.query(snapshot, _request(pageSize: 2));
    expect(first.items, [_reference(snapshot, 0), _reference(snapshot, 1)]);
    expect(metrics.catalogs, 1);
    expect(metrics.validations, [_id(0), _id(1)]);
    final second = metrics.service.query(
      snapshot,
      _request(pageSize: 2, cursor: first.nextCursor),
    );
    expect(second.items, [_reference(snapshot, 2), _reference(snapshot, 3)]);
    expect(second.totalAvailable, 12);
    expect(metrics.catalogs, 2);
    expect(metrics.validations, [_id(0), _id(1), _id(2), _id(3)]);
  });

  test(
      'get and batch get enrich selected records and preserve canonical detail',
      () {
    final snapshot = _snapshot();
    for (final ids in [
      [_id(3)],
      [_id(5), _id(1)]
    ]) {
      final metrics = _Metrics();
      final page = metrics.service.query(
        snapshot,
        AuthoringQueryRequest(
          resourceKind: 'eventV2',
          operation: ids.length == 1
              ? AuthoringQueryOperation.get
              : AuthoringQueryOperation.batchGet,
          view: AuthoringQueryView.detail,
          ids: ids,
        ),
      );
      final indices = ids.length == 1 ? [3] : [1, 5];
      expect(page.items,
          [for (final index in indices) _reference(snapshot, index)]);
      expect(metrics.catalogs, 1);
      expect(metrics.validations, [for (final index in indices) _id(index)]);
    }
  });

  test('search and raw filters run before detail enrichment', () {
    final snapshot = _snapshot();
    final metrics = _Metrics();
    final page = metrics.service.query(
      snapshot,
      AuthoringQueryRequest(
        resourceKind: 'eventV2',
        operation: AuthoringQueryOperation.search,
        view: AuthoringQueryView.detail,
        searchTerm: 'Event 00',
        filters: const {'state': 'configured', 'enabled': true},
        sort: const [AuthoringQuerySort(field: 'name', descending: true)],
        pageSize: 1,
      ),
    );
    expect(page.totalAvailable, 2);
    expect(page.items, [_reference(snapshot, 9)]);
    expect(metrics.catalogs, 1);
    expect(metrics.validations, [_id(9)]);
  });

  test('raw field masks avoid validation even with detail view', () {
    final metrics = _Metrics();
    final page = metrics.service.query(
      _snapshot(),
      _request(fieldMask: const ['state'], pageSize: 2),
    );
    expect(page.items, [
      {
        'id': _id(0),
        'name': 'Event 000',
        'resourceKind': 'eventV2',
        'state': 'draft'
      },
      {
        'id': _id(1),
        'name': 'Event 001',
        'resourceKind': 'eventV2',
        'state': 'configured'
      },
    ]);
    expect(metrics.catalogs, 0);
    expect(metrics.validations, isEmpty);
  });

  test('nested validation field masks retain exact canonical diagnostics', () {
    final snapshot = _snapshot();
    final metrics = _Metrics();
    final page = metrics.service.query(
      snapshot,
      _request(fieldMask: const ['validation.diagnostics'], pageSize: 2),
    );
    for (var index = 0; index < 2; index++) {
      expect(page.items[index], {
        'id': _id(index),
        'name': 'Event ${index.toString().padLeft(3, '0')}',
        'resourceKind': 'eventV2',
        'validation': {
          'diagnostics':
              (_reference(snapshot, index)['validation'] as Map)['diagnostics'],
        },
      });
    }
    expect(metrics.catalogs, 1);
    expect(metrics.validations, [_id(0), _id(1)]);
  });

  test(
      'validation filters and sorting share cached reports for every candidate',
      () {
    final snapshot = _snapshot();
    final references = [
      for (var index = 0; index < 12; index++) _reference(snapshot, index)
    ];
    final errorCount = (references.first['validation'] as Map)['errorCount'];
    final matching = references
        .where((record) =>
            (record['validation'] as Map)['errorCount'] == errorCount)
        .toList()
      ..sort((left, right) =>
          (right['name'] as String).compareTo(left['name'] as String));
    final metrics = _Metrics();
    final page = metrics.service.query(
      snapshot,
      _request(
        filters: {'validation.errorCount': errorCount},
        sort: const [
          AuthoringQuerySort(field: 'validation.errorCount', descending: true),
          AuthoringQuerySort(field: 'name', descending: true),
        ],
        pageSize: 2,
      ),
    );
    expect(page.totalAvailable, matching.length);
    expect(page.items, matching.take(2).toList());
    expect(metrics.catalogs, 1);
    expect(metrics.validations.length, 12);
    expect(metrics.validations.toSet().length, 12);
  });

  test(
      'validation sort preserves descending ordering and stable ID tie-breaker',
      () {
    final snapshot = _snapshot();
    final expected = [
      for (var index = 0; index < 12; index++) _reference(snapshot, index)
    ]..sort((left, right) {
        final order = ((right['validation'] as Map)['errorCount'] as int)
            .compareTo((left['validation'] as Map)['errorCount'] as int);
        return order != 0
            ? order
            : (left['id'] as String).compareTo(right['id'] as String);
      });
    final metrics = _Metrics();
    final page = metrics.service.query(
      snapshot,
      _request(sort: const [
        AuthoringQuerySort(field: 'validation.errorCount', descending: true)
      ]),
    );
    expect(page.items, expected);
    expect(metrics.catalogs, 1);
    expect(metrics.validations.length, 12);
    expect(metrics.validations.toSet().length, 12);
  });

  test('unknown masks and absent IDs keep typed failures without validation',
      () {
    final snapshot = _snapshot();
    for (final entry in [
      (
        request: _request(fieldMask: const ['unknown']),
        code: 'query.field_mask_unknown'
      ),
      (
        request: AuthoringQueryRequest(
            resourceKind: 'eventV2',
            operation: AuthoringQueryOperation.get,
            ids: [_id(999)]),
        code: 'query.resource_not_found'
      ),
    ]) {
      final metrics = _Metrics();
      expect(
          () => metrics.service.query(snapshot, entry.request),
          throwsA(isA<AuthoringQueryException>()
              .having((error) => error.code, 'code', entry.code)));
      expect(metrics.catalogs, 0);
      expect(metrics.validations, isEmpty);
    }
  });

  test('cursors remain bound to revision and normalized query', () {
    final snapshot = _snapshot();
    const service = ProjectQueryService();
    final first = service.query(snapshot, _request(pageSize: 1));
    expect(
        () => service.query(_snapshot(revisionDigit: 'b'),
            _request(pageSize: 1, cursor: first.nextCursor)),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_stale')));
    expect(
        () => service.query(
            snapshot,
            _request(
                pageSize: 1,
                cursor: first.nextCursor,
                fieldMask: const ['state'])),
        throwsA(isA<AuthoringQueryException>()
            .having((error) => error.code, 'code', 'query.cursor_mismatch')));
  });

  test('typed API and JSONL preserve lazy results and query-local work',
      () async {
    final root = await Directory.systemTemp.createTemp('event-query-parity-');
    addTearDown(() => root.delete(recursive: true));
    final fixture = _snapshot();
    final manifestJson = jsonEncode(fixture.manifest.toJson());
    await File('${root.path}/project.json').writeAsString(manifestJson);
    await Directory('${root.path}/maps').create();
    for (final map in fixture.maps) {
      await File('${root.path}/maps/${map.id}.json')
          .writeAsString(jsonEncode(map.toJson()));
    }
    const reader = LocalProjectFileReader();
    final policy = await WorkspacePolicy.create(
        allowedRootPaths: [root.path], fileReader: reader);
    final handles = WorkspaceHandleStore();
    final metrics = _Metrics();
    final api = AuthoringReadApi(
      openService: ProjectOpenService(
          policy: policy, fileReader: reader, handles: handles),
      snapshotLoader: ProjectSnapshotLoader(handles: handles),
      queryService: metrics.service,
    );
    final opened = await api.openProject(root.path);
    addTearDown(() => api.closeWorkspace(opened.workspaceHandle));
    final worker = JsonlWorker(api: api);
    for (final scenario in [
      (request: _request(pageSize: 2), catalogs: 1, validations: 2),
      (
        request: _request(pageSize: 2, fieldMask: const ['state']),
        catalogs: 0,
        validations: 0
      ),
      (
        request: AuthoringQueryRequest(
            resourceKind: 'eventV2',
            operation: AuthoringQueryOperation.list,
            pageSize: 2),
        catalogs: 0,
        validations: 0
      ),
    ]) {
      metrics.catalogs = 0;
      metrics.validations.clear();
      final direct =
          await api.queryProject(opened.projectHandle, scenario.request);
      expect(metrics.catalogs, scenario.catalogs);
      expect(metrics.validations.length, scenario.validations);
      metrics.catalogs = 0;
      metrics.validations.clear();
      final wire = AuthoringResult.fromJson(
          jsonDecode(await worker.processLine(jsonEncode({
        'id': 'event-query',
        'command': 'query',
        'args': {
          'projectHandle': opened.projectHandle.value,
          'request': scenario.request.toJson()
        },
      }))) as Map<String, dynamic>);
      expect(wire.status, AuthoringResultStatus.success);
      expect(wire.data['items'], direct.items);
      expect(wire.data['totalAvailable'], direct.totalAvailable);
      expect(wire.data['nextCursor'], direct.nextCursor);
      expect(metrics.catalogs, scenario.catalogs);
      expect(metrics.validations.length, scenario.validations);
    }
    expect(
        await File('${root.path}/project.json').readAsString(), manifestJson);
  });

  test('queries leave the source snapshot unchanged', () {
    final snapshot = _snapshot();
    final before = jsonEncode(snapshot.manifest.toJson());
    const ProjectQueryService().query(snapshot, _request());
    expect(jsonEncode(snapshot.manifest.toJson()), before);
  });

  test('local EventV2 query measurements', () {
    final snapshot = _snapshot(eventCount: 200, mapCount: 24);
    for (final entry in [
      (
        name: 'summary',
        request: AuthoringQueryRequest(
            resourceKind: 'eventV2',
            operation: AuthoringQueryOperation.list,
            pageSize: 5)
      ),
      (name: 'detail-page-5', request: _request(pageSize: 5)),
      (
        name: 'raw-mask-page-5',
        request: _request(pageSize: 5, fieldMask: const ['state'])
      ),
    ]) {
      final metrics = _Metrics();
      final watch = Stopwatch()..start();
      final page = metrics.service.query(snapshot, entry.request);
      watch.stop();
      print(
          'EVENT_V2_QUERY ${entry.name} events=200 maps=24 returned=${page.items.length} catalogs=${metrics.catalogs} validations=${metrics.validations.length} elapsed_us=${watch.elapsedMicroseconds}');
      expect(page.totalAvailable, 200);
    }
  }, skip: Platform.environment['EVENT_V2_QUERY_BENCHMARK'] != '1');
}

final class _Metrics {
  var catalogs = 0;
  final validations = <String>[];

  ProjectQueryService get service => ProjectQueryService(
        onEventV2CatalogBuilt: () => catalogs++,
        onEventV2ValidationBuilt: validations.add,
      );
}

AuthoringQueryRequest _request({
  int pageSize = 50,
  String? cursor,
  List<String> fieldMask = const [],
  Map<String, Object?> filters = const {},
  List<AuthoringQuerySort> sort = const [],
}) =>
    AuthoringQueryRequest(
      resourceKind: 'eventV2',
      operation: AuthoringQueryOperation.list,
      view: AuthoringQueryView.detail,
      pageSize: pageSize,
      cursor: cursor,
      fieldMask: fieldMask,
      filters: filters,
      sort: sort,
    );

Map<String, Object?> _reference(ProjectSnapshot snapshot, int index) {
  final record = snapshot.manifest.eventRegistry!.records[index];
  final catalog = buildNarrativeEventProjectCatalog(
      project: snapshot.manifest, maps: snapshot.maps);
  return {
    ...record.toJson(),
    'id': record.id,
    'name': record.when(
        draft: (draft) => draft.name,
        configured: (definition, _) => definition.name),
    'resourceKind': 'eventV2',
    'validation': buildNarrativeEventValidationReportSubset(
        registry: snapshot.manifest.eventRegistry!,
        catalog: catalog,
        eventIds: {record.id}).toDebugJson(),
  };
}

String _id(int index) =>
    'evt_018f0f8c-7b8a-7def-8000-${(index + 1).toRadixString(16).padLeft(12, '0')}';

ProjectSnapshot _snapshot(
    {int eventCount = 12, int mapCount = 2, String revisionDigit = 'a'}) {
  final maps = [
    for (var index = 0; index < mapCount; index++)
      MapData(
          id: 'map-$index',
          name: 'Map $index',
          size: const GridSize(width: 40, height: 30),
          version: ProjectVersion.v8,
          layers: const []),
  ];
  final records = [
    for (var index = 0; index < eventCount; index++)
      if (index.isEven)
        NarrativeEventRecord.draft(NarrativeEventDraft(
            id: _id(index),
            name: 'Event ${index.toString().padLeft(3, '0')}',
            conditions: const [],
            priority: index,
            order: index))
      else
        NarrativeEventRecord.configuredStructurallyUnchecked(
          NarrativeEventDefinition(
              id: _id(index),
              name: 'Event ${index.toString().padLeft(3, '0')}',
              source: NarrativeEventSourceRef.mapEnter('map-0'),
              conditions: const [],
              sceneId: 'missing-scene',
              reusePolicy: NarrativeEventReusePolicy.oneShot,
              priority: index,
              order: index),
          enabled: index % 3 == 0,
        ),
  ];
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_event_query'),
    revision: 'sha256:${List.filled(64, revisionDigit).join()}',
    manifest: ProjectManifest(
      name: 'Event query fixture',
      maps: [
        for (final map in maps)
          ProjectMapEntry(
              id: map.id, name: map.name, relativePath: 'maps/${map.id}.json')
      ],
      tilesets: const [],
      eventRegistry: NarrativeEventRegistry(
          schemaVersion: 1,
          mode: EventSystemMode.v2Only,
          records: records,
          legacyClaims: const []),
    ),
    maps: maps,
    resourceFingerprints: const {},
  );
}
