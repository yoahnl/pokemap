import 'package:map_core/map_core.dart';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot.dart';
import 'border_feature_query.dart';

const maximumSpatialMapIntegrityItems = 512;

Future<AuthoringQueryPage> querySpatialMapIntegrityInSnapshot(
  ProjectSnapshot snapshot,
  AuthoringQueryRequest request,
) =>
    querySpatialMapIntegrity(
      request: request,
      readMap: (mapId) async {
        final map = snapshot.maps.where((map) => map.id == mapId).firstOrNull;
        if (map == null) {
          throw const AuthoringQueryException('query.resource_not_found',
              'The requested map does not exist in this project.');
        }
        return (map: map, manifest: snapshot.manifest, revision: snapshot.revision);
      },
    );

/// Reports enclosed cells without proven ground and placed objects crossing
/// Border modules on one 3D map; `ids` holds the single map id.
Future<AuthoringQueryPage> querySpatialMapIntegrity({
  required AuthoringQueryRequest request,
  required BorderFeatureMapRead readMap,
}) async {
  final filteredMapId = request.filters['mapId'];
  final byGet = request.operation == AuthoringQueryOperation.get &&
      request.ids.length == 1 &&
      request.filters.isEmpty;
  final byList = request.operation == AuthoringQueryOperation.list &&
      request.ids.isEmpty &&
      request.filters.length == 1 &&
      filteredMapId is String &&
      filteredMapId.isNotEmpty;
  if (request.operation == AuthoringQueryOperation.list && request.filters.isEmpty) {
    throw const AuthoringQueryException(
      'query.spatial_map_integrity_map_required',
      'Spatial map integrity lists require filters.mapId.',
    );
  }
  if ((!byGet && !byList) ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty) {
    throw const AuthoringQueryException(
      'query.spatial_map_integrity_unsupported',
      'Spatial map integrity supports get with ids: [mapId] or list with '
          'filters.mapId only.',
    );
  }
  final read = await readMap(byGet ? request.ids.single : filteredMapId as String);
  if (read.map.spatialScene == null) {
    return AuthoringQueryPage(
      snapshotRevision: read.revision,
      items: [
        {'id': read.map.id, 'mapId': read.map.id, 'status': 'not_applicable'},
      ],
      totalAvailable: 1,
    );
  }
  final report = inspectSpatialMapIntegrity(manifest: read.manifest, map: read.map);
  final clusters = report.gapClusters;
  final detail = request.view == AuthoringQueryView.detail;
  return AuthoringQueryPage(
    snapshotRevision: read.revision,
    items: [
      {
        'id': read.map.id,
        'mapId': read.map.id,
        'status': report.exposedCellCount > 0
            ? 'error'
            : report.groundGaps.isNotEmpty || report.borderObjectOverlaps.isNotEmpty
                ? 'warning'
                : 'success',
        'groundGapCount': report.groundGaps.length,
        'exposedCellCount': report.exposedCellCount,
        'unprovenCellCount': report.unprovenCellCount,
        'gapClusterCount': clusters.length,
        'borderObjectOverlapCount': report.borderObjectOverlaps.length,
        if (detail) ...{
          'gapClusters': [
            for (final cluster in clusters.take(maximumSpatialMapIntegrityItems))
              cluster.toJson(),
          ],
          'groundGaps': [
            for (final gap in report.groundGaps.take(maximumSpatialMapIntegrityItems))
              gap.toJson(),
          ],
          'borderObjectOverlaps': [
            for (final overlap
                in report.borderObjectOverlaps.take(maximumSpatialMapIntegrityItems))
              overlap.toJson(),
          ],
          if (report.groundGaps.length > maximumSpatialMapIntegrityItems ||
              clusters.length > maximumSpatialMapIntegrityItems ||
              report.borderObjectOverlaps.length > maximumSpatialMapIntegrityItems)
            'truncated': true,
        },
      },
    ],
    totalAvailable: 1,
  );
}
