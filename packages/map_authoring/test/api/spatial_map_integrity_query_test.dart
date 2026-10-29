import 'package:map_authoring/map_authoring.dart';
import 'package:map_authoring/src/api/spatial_map_integrity_query.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

const _revision =
    'sha256:0000000000000000000000000000000000000000000000000000000000000002';

void main() {
  test('summary counts gaps; detail lists clusters, gaps and overlaps', () async {
    final summary = await _query(AuthoringQueryRequest(
      resourceKind: 'spatialMapIntegrity',
      operation: AuthoringQueryOperation.get,
      ids: const ['field'],
    ));
    expect(summary.snapshotRevision, _revision);
    final item = summary.items.single;
    expect(item['mapId'], 'field');
    expect(item['status'], 'error');
    expect(item['groundGapCount'], 2);
    expect(item['exposedCellCount'], 2);
    expect(item['gapClusterCount'], 1);
    expect(item.containsKey('groundGaps'), isFalse);

    final detail = (await _query(AuthoringQueryRequest(
      resourceKind: 'spatialMapIntegrity',
      operation: AuthoringQueryOperation.get,
      view: AuthoringQueryView.detail,
      ids: const ['field'],
    ))).items.single;
    expect(detail['gapClusters'], [
      {
        'center': {'x': 2.0, 'z': 1.5},
        'cellCount': 2,
        'exposedCellCount': 2,
        'firstCell': {'x': 1, 'y': 1},
      }
    ]);
    expect((detail['groundGaps'] as List).length, 2);
    expect(detail['borderObjectOverlaps'], isEmpty);
  });

  test('list by mapId matches get; a 2D map is not applicable', () async {
    final listed = await _query(AuthoringQueryRequest(
        resourceKind: 'spatialMapIntegrity',
        operation: AuthoringQueryOperation.list,
        filters: const {'mapId': 'field'}));
    expect(listed.items.single['groundGapCount'], 2);
    final flat = await _query(
        AuthoringQueryRequest(
            resourceKind: 'spatialMapIntegrity',
            operation: AuthoringQueryOperation.get,
            ids: const ['field']),
        flat: true);
    expect(flat.items.single, {'id': 'field', 'mapId': 'field', 'status': 'not_applicable'});
  });

  test('other shapes are refused', () async {
    for (final request in [
      AuthoringQueryRequest(
          resourceKind: 'spatialMapIntegrity',
          operation: AuthoringQueryOperation.get,
          ids: const ['field'],
          filters: const {'mapId': 'field'}),
      AuthoringQueryRequest(
          resourceKind: 'spatialMapIntegrity',
          operation: AuthoringQueryOperation.search,
          searchTerm: 'field',
          filters: const {'mapId': 'field'}),
    ]) {
      await expectLater(
          _query(request),
          throwsA(isA<AuthoringQueryException>().having(
              (error) => error.code, 'code', 'query.spatial_map_integrity_unsupported')));
    }
    await expectLater(
        _query(AuthoringQueryRequest(
            resourceKind: 'spatialMapIntegrity', operation: AuthoringQueryOperation.list)),
        throwsA(isA<AuthoringQueryException>().having(
            (error) => error.code, 'code', 'query.spatial_map_integrity_map_required')));
  });

  test('the snapshot service routes the query asynchronously', () async {
    const service = ProjectQueryService();
    expect(
      () => service.query(
          _snapshot,
          AuthoringQueryRequest(
              resourceKind: 'spatialMapIntegrity',
              operation: AuthoringQueryOperation.get,
              ids: const ['field'])),
      throwsA(isA<AuthoringQueryException>()
          .having((error) => error.code, 'code', 'query.async_required')),
    );
  });
}

final _map = MapData(
  version: ProjectVersion.v9,
  id: 'field',
  name: 'Field',
  size: const GridSize(width: 4, height: 3),
  spatialScene: MapSpatialScene(width: 4, depth: 3, heightLevels: List.filled(12, 0)),
  layers: [
    SmartTileLayer(
      id: 'ground',
      name: 'Ground',
      presetId: 'grass',
      usage: SmartTileUsage.terrain,
      materialPalette: const ['', 'grass'],
      field: SmartTileField.cell(semanticCells: [
        1, 1, 1, 1,
        1, 0, 0, 1,
        1, 1, 1, 1,
      ]),
    ),
  ],
);

const _manifest = ProjectManifest(name: 'Field', maps: [], tilesets: []);

final _snapshot = ProjectSnapshot(
  projectHandle: const ProjectHandle('field'),
  revision: _revision,
  manifest: _manifest,
  maps: [_map],
  resourceFingerprints: const {},
);

Future<AuthoringQueryPage> _query(AuthoringQueryRequest request, {bool flat = false}) =>
    querySpatialMapIntegrity(
      request: request,
      readMap: (mapId) async => (
        map: flat ? _map.copyWith(spatialScene: null) : _map,
        manifest: _manifest,
        revision: _revision,
      ),
    );
