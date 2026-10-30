import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot.dart';
import 'border_feature_query.dart';

const mapHealthPolicyVersion = 1;
const maximumMapHealthIssues = 20;

Future<AuthoringQueryPage> queryMapHealthInSnapshot(
        ProjectSnapshot snapshot, AuthoringQueryRequest request) =>
    queryMapHealth(
        request: request,
        readMap: (mapId) async {
          final map = snapshot.mapById(mapId);
          if (map == null) {
            throw const AuthoringQueryException('query.resource_not_found',
                'The requested map does not exist in this project.');
          }
          return (
            map: map,
            manifest: snapshot.manifest,
            revision: snapshot.revision
          );
        });

Future<AuthoringQueryPage> queryMapHealth({
  required AuthoringQueryRequest request,
  required BorderFeatureMapRead readMap,
}) async {
  final filtered = request.filters['mapId'];
  final get = request.operation == AuthoringQueryOperation.get &&
      request.ids.length == 1 &&
      request.filters.isEmpty;
  final list = request.operation == AuthoringQueryOperation.list &&
      request.ids.isEmpty &&
      request.filters.length == 1 &&
      filtered is String &&
      filtered.isNotEmpty;
  final offset = request.extensions['issueOffset'] ?? 0;
  if ((!get && !list) ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.cursor != null ||
      request.extensions.keys.any((key) =>
          !const {'issueOffset', 'expectedReportRevision'}.contains(key)) ||
      offset is! int ||
      offset < 0) {
    throw const AuthoringQueryException('query.map_health_unsupported',
        'Map health supports get ids:[mapId] or list filters.mapId, and an optional nonnegative issueOffset extension.');
  }
  final read = await readMap(get ? request.ids.single : filtered as String);
  if (request.extensions['expectedReportRevision'] case final revision?) {
    if (revision != read.revision) {
      throw const AuthoringQueryException('query.cursor_stale',
          'The map changed after the previous issue page.');
    }
  }
  final health = inspectMapHealth(read);
  final issues = health['issues'] as List<Map<String, Object?>>;
  if (offset > issues.length) {
    throw const AuthoringQueryException('query.map_health_offset_invalid',
        'The issue offset exceeds the current map report.');
  }
  final end = (offset + maximumMapHealthIssues).clamp(0, issues.length);
  final next = end < issues.length ? end : null;
  return AuthoringQueryPage(
    snapshotRevision: read.revision,
    totalAvailable: 1,
    items: [
      {
        ...health,
        'issueCount': issues.length,
        'issues': issues.sublist(offset, end),
        'issueOffset': offset,
        if (next != null)
          'nextIssueRequest': {
            'resourceKind': 'mapHealth',
            'operation': 'get',
            'ids': [read.map.id],
            'view': 'detail',
            'extensions': {
              'issueOffset': next,
              'expectedReportRevision': read.revision
            },
          },
      }
    ],
  );
}

Map<String, Object?> inspectMapHealth(AuthoringMapView read) {
  final issues = <Map<String, Object?>>[];
  final scene = read.map.spatialScene;
  var failed = false;
  var borderFailed = false;
  var incomplete = false;
  var features = 0, stale = 0, errors = 0, warnings = 0;
  if (scene == null) {
    incomplete = true;
    issues.add(
        {'code': 'map_health.spatial_map_required', 'severity': 'unknown'});
  }
  for (final layer in read.map.layers.whereType<BorderLayer>()) {
    for (final feature in layer.content.features) {
      features++;
      if (scene == null) continue;
      try {
        final diagnostics = diagnoseSpatialBorderFeature(
                manifest: read.manifest,
                map: read.map,
                layerId: layer.id,
                featureId: feature.id)
            .diagnostics;
        for (final diagnostic in diagnostics) {
          final error = diagnostic.severity == BorderDiagnosticSeverity.error;
          final warning =
              diagnostic.severity == BorderDiagnosticSeverity.warning;
          if (!error && !warning) continue;
          if (error) errors++;
          if (warning) warnings++;
          final structural = error ||
              const {
                'border.materialization.missing',
                'border.spatial.materialization_stale',
                'border.spatial.face_crown_mismatch',
                'border.spatial.face_base_mismatch',
              }.contains(diagnostic.code);
          if (diagnostic.code == 'border.materialization.missing' ||
              diagnostic.code == 'border.spatial.materialization_stale') {
            stale++;
          }
          if (structural) {
            failed = true;
            borderFailed = true;
          } else {
            incomplete = true;
          }
          issues.add({
            'code': diagnostic.code,
            'severity': structural ? 'error' : 'unknown',
            'diagnosticSeverity': diagnostic.severity.name,
            'layerId': layer.id,
            'featureId': feature.id,
            if (diagnostic.slotKey != null) 'slotKey': diagnostic.slotKey,
            if (diagnostic.cell case final cell?)
              'cell': {'x': cell.x, 'y': cell.y},
            if (diagnostic.parameters.isNotEmpty)
              'parameters': diagnostic.parameters,
            'suggestedAction': diagnostic.suggestedAction,
          });
        }
      } on Object {
        incomplete = true;
        issues.add({
          'code': 'map_health.border_inspection_failed',
          'severity': 'unknown',
          'layerId': layer.id,
          'featureId': feature.id
        });
      }
    }
  }
  final report =
      inspectSpatialMapIntegrity(manifest: read.manifest, map: read.map);
  for (final gap in report.groundGaps) {
    final exposed = gap.state == SpatialGroundGapState.exposed;
    if (exposed) {
      failed = true;
    } else {
      incomplete = true;
    }
    issues.add({
      'code': exposed ? 'map.ground.exposed' : 'map.ground.unproven',
      'severity': exposed ? 'error' : 'unknown',
      ...gap.toJson()
    });
  }
  for (final overlap in report.borderObjectOverlaps) {
    incomplete = true;
    issues.add({
      'code': 'map.border_object_overlap.unexplained',
      'severity': 'unknown',
      ...overlap.toJson()
    });
  }
  issues.sort((left, right) {
    final severity = (left['severity'] == 'error' ? 0 : 1)
        .compareTo(right['severity'] == 'error' ? 0 : 1);
    return severity != 0
        ? severity
        : jsonEncode(left).compareTo(jsonEncode(right));
  });
  final verdict = failed
      ? 'fail'
      : incomplete
          ? 'incomplete'
          : 'pass';
  return {
    'id': read.map.id,
    'mapId': read.map.id,
    'revision': read.revision,
    'policyVersion': mapHealthPolicyVersion,
    'verdict': verdict,
    'checks': {
      'structure': {
        'status': report.exposedCellCount > 0
            ? 'fail'
            : scene == null
                ? 'incomplete'
                : 'pass'
      },
      'borders': {
        'status': borderFailed
            ? 'fail'
            : warnings > 0
                ? 'incomplete'
                : 'pass',
        'count': features,
        'stale': stale,
        'errors': errors,
        'warnings': warnings,
        'unexplainedWarningCount': warnings,
        'unexplainedWarnings': issues
            .where((issue) => issue['diagnosticSeverity'] == 'warning')
            .take(maximumMapHealthIssues)
            .toList()
      },
      'integrity': {
        'exposedCellCount': report.exposedCellCount,
        'unprovenCellCount': report.unprovenCellCount,
        'borderObjectOverlapCount': report.borderObjectOverlaps.length
      },
      'visual': {'status': 'not_run'},
    },
    'coverage': {
      'kind': 'structural',
      'mapRevision': read.revision,
      'visualProof': false,
      'inspectionScope': 'selectedMapAndReferences'
    },
    'issues': issues,
    'suggestedOperations': <Map<String, Object?>>[],
  };
}
