import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/api/border_feature_query.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

import '../domains/maps/border_face_ground_warning_actions_test.dart'
    show directedCliffAuthoringFixture;

const _revision =
    'sha256:0000000000000000000000000000000000000000000000000000000000000001';

void main() {
  test('list summarizes materialized features without detail payloads',
      () async {
    final read = _materialized();
    final page = await _query(read,
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.list,
            filters: const {'mapId': 'map'}));
    expect(page.snapshotRevision, _revision);
    expect(page.totalAvailable, 1);
    final item = page.items.single;
    expect(item['id'], 'border/fence');
    expect(item['spatial'], isTrue);
    expect(item['status'], 'warning');
    expect(item['materialization'], 'fresh');
    expect(item['warningCount'], 3);
    expect(item['errorCount'], 0);
    expect(item['slotCount'], 3);
    expect(item.containsKey('diagnostics'), isFalse);
    expect(item.containsKey('slots'), isFalse);
  });

  test('detail lists every placed slot and its slot diagnostics', () async {
    final read = _materialized();
    final page = await _query(read,
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['border/fence'],
            filters: const {'mapId': 'map'}));
    final item = page.items.single;
    final slots = (item['slots']! as List).cast<Map>();
    expect(slots, hasLength(3));
    for (final slot in slots) {
      expect(slot['modelId'], 'cliff');
      expect(slot['role'], isIn(['lineCap', 'lineStraight']));
      expect((slot['position'] as Map)['y'], 1.0);
      expect(slot['instanceId'], isA<String>());
    }
    final diagnostics = (item['diagnostics']! as List).cast<Map>();
    final faces = diagnostics
        .where((d) => d['code'] == 'border.spatial.face_base_mismatch')
        .toList();
    expect(faces.map((d) => d['slotKey']).toSet(),
        slots.map((slot) => slot['slotKey']).toSet());
    expect(faces.first['severity'], 'warning');
    expect(faces.first['cell'], isA<Map>());
    expect((faces.first['parameters'] as Map)['lowerGroundHeight'], 1.0);
    expect(jsonDecode(jsonEncode(page.toJson())), isA<Map>());
  });

  test('unmaterialized features report missing materialization', () async {
    final fixture = directedCliffAuthoringFixture(levels: List.filled(24, 1));
    final page = await _query(
        (map: fixture.map, manifest: fixture.project, revision: _revision),
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.get,
            view: AuthoringQueryView.detail,
            ids: const ['border/fence'],
            filters: const {'mapId': 'map', 'layerId': 'border'}));
    final item = page.items.single;
    expect(item['materialization'], 'missing');
    expect(item['slotCount'], 0);
    expect(item['slots'], isEmpty);
    expect(item['warningCount'], 3);
  });

  test('pages follow a revision-bound cursor', () async {
    final read = _materialized(features: 2);
    final first = await _query(read,
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.list,
            pageSize: 1,
            filters: const {'mapId': 'map'}));
    expect(first.items.single['featureId'], 'fence');
    expect(first.totalAvailable, 2);
    expect(first.nextCursor, isNotNull);
    final second = await _query(read,
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.list,
            pageSize: 1,
            cursor: first.nextCursor,
            filters: const {'mapId': 'map'}));
    expect(second.items.single['featureId'], 'fence-2');
    expect(second.nextCursor, isNull);
    await expectLater(
        _query(
            (
              map: read.map,
              manifest: read.manifest,
              revision:
                  'sha256:0000000000000000000000000000000000000000000000000000000000000002',
            ),
            AuthoringQueryRequest(
                resourceKind: 'borderFeature',
                operation: AuthoringQueryOperation.list,
                pageSize: 1,
                cursor: first.nextCursor,
                filters: const {'mapId': 'map'})),
        throwsA(isA<AuthoringQueryException>()
            .having((e) => e.code, 'code', 'query.cursor_stale')));
  });

  test('invalid requests fail closed with actionable codes', () async {
    final read = _materialized();
    for (final (request, code) in [
      (
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.list),
        'query.border_feature_map_required',
      ),
      (
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.list,
            filters: const {'mapId': 'map', 'blueprintId': 'fence'}),
        'query.border_feature_map_required',
      ),
      (
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.search,
            searchTerm: 'fence',
            filters: const {'mapId': 'map'}),
        'query.border_feature_unsupported',
      ),
      (
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.get,
            ids: const ['fence'],
            filters: const {'mapId': 'map'}),
        'query.resource_not_found',
      ),
    ]) {
      await expectLater(
          _query(read, request),
          throwsA(isA<AuthoringQueryException>()
              .having((e) => e.code, 'code', code)));
    }
  });

  test('batch_get skips absent ids and stays bounded by pageSize', () async {
    final read = _materialized(features: 2);
    final page = await _query(read,
        AuthoringQueryRequest(
            resourceKind: 'borderFeature',
            operation: AuthoringQueryOperation.batchGet,
            ids: const ['border/fence-2', 'border/absent'],
            filters: const {'mapId': 'map'}));
    expect(page.items.map((item) => item['featureId']), ['fence-2']);
    await expectLater(
        _query(read,
            AuthoringQueryRequest(
                resourceKind: 'borderFeature',
                operation: AuthoringQueryOperation.batchGet,
                pageSize: 1,
                ids: const ['border/fence', 'border/fence-2'],
                filters: const {'mapId': 'map'})),
        throwsA(isA<AuthoringQueryException>().having(
            (e) => e.code, 'code', 'query.border_feature_batch_too_large')));
  });

  test('forged cursors fail closed', () async {
    final read = _materialized(features: 2);
    final forged = base64Url
        .encode(utf8.encode(jsonEncode({
          'kind': 'borderFeature',
          'mapId': 'map',
          'layerId': null,
          'revision': _revision,
          'offset': -1,
        })))
        .replaceAll('=', '');
    await expectLater(
        _query(read,
            AuthoringQueryRequest(
                resourceKind: 'borderFeature',
                operation: AuthoringQueryOperation.list,
                cursor: forged,
                filters: const {'mapId': 'map'})),
        throwsA(isA<AuthoringQueryException>()
            .having((e) => e.code, 'code', 'query.cursor_invalid')));
  });

  test('the snapshot query service routes Border features asynchronously',
      () async {
    final read = _materialized();
    final snapshot = ProjectSnapshot(
        projectHandle: const ProjectHandle('prj_border_feature'),
        revision: _revision,
        manifest: read.manifest,
        maps: [read.map],
        resourceFingerprints: const {});
    final request = AuthoringQueryRequest(
        resourceKind: 'borderFeature',
        operation: AuthoringQueryOperation.list,
        filters: const {'mapId': 'map'});
    final page = await const ProjectQueryService().queryAsync(snapshot, request);
    expect(page.items.single['id'], 'border/fence');
    expect(page.items.single['warningCount'], 3);
    expect(
        () => const ProjectQueryService().query(snapshot, request),
        throwsA(isA<AuthoringQueryException>()
            .having((e) => e.code, 'code', 'query.async_required')));
  });
}

Future<AuthoringQueryPage> _query(
  ({MapData map, ProjectManifest manifest, String revision}) read,
  AuthoringQueryRequest request,
) =>
    queryBorderFeatures(request: request, readMap: (mapId) async {
      if (mapId != read.map.id) {
        throw const AuthoringQueryException(
            'query.resource_not_found', 'missing map');
      }
      return read;
    });

({MapData map, ProjectManifest manifest, String revision}) _materialized(
    {int features = 1}) {
  final fixture = directedCliffAuthoringFixture(levels: List.filled(24, 1));
  final layer = fixture.map.layers.whereType<BorderLayer>().single;
  final base = layer.content.features.single;
  var map = fixture.map;
  if (features > 1) {
    map = upsertBorderFeature(map,
        layerId: 'border',
        feature: BorderFeature(
            id: 'fence-2',
            name: 'Fence 2',
            blueprintId: base.blueprintId,
            seed: base.seed,
            geometry: BorderStrokeGeometry(strokes: [
              BorderStroke(
                  id: 'line-2',
                  points: const [
                    GridPos(x: 1, y: 3),
                    GridPos(x: 2, y: 3),
                    GridPos(x: 3, y: 3),
                  ],
                  closed: false),
            ]),
            overrides: const [],
            keepOutRegions: const []));
  }
  for (final id in ['fence', if (features > 1) 'fence-2']) {
    map = applySpatialBorderFeaturePreview(map,
        manifest: fixture.project,
        proposedResult: resolveSpatialBorderFeature(
            manifest: fixture.project,
            map: map,
            layerId: 'border',
            featureId: id));
  }
  return (map: map, manifest: fixture.project, revision: _revision);
}
