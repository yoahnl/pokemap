import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../contracts/query_page.dart';
import '../contracts/query_request.dart';
import '../workspace/project_query_service.dart';
import '../workspace/project_snapshot.dart';

typedef BorderFeatureMapRead
    = Future<({MapData map, ProjectManifest manifest, String revision})>
        Function(String mapId);

const maximumBorderFeatureQueryDiagnostics = 512;

Future<AuthoringQueryPage> queryBorderFeaturesInSnapshot(
  ProjectSnapshot snapshot,
  AuthoringQueryRequest request,
) =>
    queryBorderFeatures(
      request: request,
      readMap: (mapId) async {
        final map = snapshot.maps.where((map) => map.id == mapId).firstOrNull;
        if (map == null) {
          throw const AuthoringQueryException('query.resource_not_found',
              'The requested map does not exist in this project.');
        }
        return (
          map: map,
          manifest: snapshot.manifest,
          revision: snapshot.revision,
        );
      },
    );

Future<AuthoringQueryPage> queryBorderFeatures({
  required AuthoringQueryRequest request,
  required BorderFeatureMapRead readMap,
}) async {
  if (!const {
        AuthoringQueryOperation.list,
        AuthoringQueryOperation.get,
        AuthoringQueryOperation.batchGet,
      }.contains(request.operation) ||
      request.sort.isNotEmpty ||
      request.fieldMask.isNotEmpty ||
      request.extensions.isNotEmpty) {
    throw const AuthoringQueryException(
      'query.border_feature_unsupported',
      'Border features support list, get and batch_get without sort, '
          'fieldMask or extensions.',
    );
  }
  final mapId = request.filters['mapId'];
  final layerId = request.filters['layerId'];
  if (mapId is! String ||
      mapId.isEmpty ||
      (layerId != null && (layerId is! String || layerId.isEmpty)) ||
      request.filters.keys.any((key) => key != 'mapId' && key != 'layerId')) {
    throw const AuthoringQueryException(
      'query.border_feature_map_required',
      'Border feature queries require filters.mapId and accept only an '
          'optional filters.layerId.',
    );
  }
  final read = await readMap(mapId);
  final features = [
    for (final layer in read.map.layers.whereType<BorderLayer>())
      if (layerId == null || layer.id == layerId)
        for (final feature in layer.content.features)
          (layerId: layer.id, feature: feature),
  ];
  final detail = request.view == AuthoringQueryView.detail;
  if (request.operation != AuthoringQueryOperation.list) {
    if (request.ids.length > request.pageSize) {
      throw const AuthoringQueryException(
        'query.border_feature_batch_too_large',
        'Request at most pageSize Border feature ids at once.',
      );
    }
    final byId = {
      for (final entry in features) '${entry.layerId}/${entry.feature.id}': entry,
    };
    if (request.operation == AuthoringQueryOperation.get &&
        !byId.containsKey(request.ids.single)) {
      throw const AuthoringQueryException(
        'query.resource_not_found',
        'The requested Border feature does not exist on this map. Use '
            'ids of the form <layerId>/<featureId>.',
      );
    }
    final selected = [
      for (final id in request.ids.toSet())
        if (byId[id] case final entry?) entry,
    ];
    return AuthoringQueryPage(
      snapshotRevision: read.revision,
      items: [
        for (final entry in selected)
          _borderFeatureItem(read, entry.layerId, entry.feature,
              detail: detail),
      ],
      totalAvailable: selected.length,
    );
  }
  var offset = 0;
  final cursor = request.cursor;
  if (cursor != null) {
    final Object? decoded;
    try {
      decoded = jsonDecode(
          utf8.decode(base64Url.decode(base64Url.normalize(cursor))));
    } on Object {
      throw const AuthoringQueryException(
          'query.cursor_invalid', 'The Border feature page cursor is invalid.');
    }
    if (decoded is! Map ||
        decoded['kind'] != 'borderFeature' ||
        decoded['mapId'] != mapId ||
        decoded['layerId'] != layerId ||
        decoded['offset'] is! int) {
      throw const AuthoringQueryException(
          'query.cursor_invalid', 'The Border feature page cursor is invalid.');
    }
    if (decoded['revision'] != read.revision) {
      throw const AuthoringQueryException('query.cursor_stale',
          'The map changed after the previous Border feature page.');
    }
    offset = decoded['offset'] as int;
    if (offset < 0 || offset > features.length) {
      throw const AuthoringQueryException(
          'query.cursor_invalid', 'The Border feature page cursor is invalid.');
    }
  }
  final end = (offset + request.pageSize).clamp(0, features.length);
  final page = offset < features.length
      ? features.sublist(offset, end)
      : const <({String layerId, BorderFeature feature})>[];
  return AuthoringQueryPage(
    snapshotRevision: read.revision,
    items: [
      for (final entry in page)
        _borderFeatureItem(read, entry.layerId, entry.feature, detail: detail),
    ],
    totalAvailable: features.length,
    nextCursor: end < features.length
        ? base64Url
            .encode(utf8.encode(jsonEncode({
              'kind': 'borderFeature',
              'mapId': mapId,
              'layerId': layerId,
              'revision': read.revision,
              'offset': end,
            })))
            .replaceAll('=', '')
        : null,
  );
}

Map<String, Object?> _borderFeatureItem(
  ({MapData map, ProjectManifest manifest, String revision}) read,
  String layerId,
  BorderFeature feature, {
  required bool detail,
}) {
  final scene = read.map.spatialScene;
  final placements =
      feature.materialization?.spatialPlacements ?? const <BorderSpatialPlacement>[];
  final base = <String, Object?>{
    'id': '$layerId/${feature.id}',
    'mapId': read.map.id,
    'layerId': layerId,
    'featureId': feature.id,
    'name': feature.name,
    'blueprintId': feature.blueprintId,
    'spatial': scene != null,
    'slotCount': placements.length,
  };
  if (scene == null) {
    return {...base, 'status': 'notInspected', 'reason': 'spatialMapsOnly'};
  }
  late final List<BorderDiagnostic> diagnostics;
  try {
    diagnostics = diagnoseSpatialBorderFeature(
      manifest: read.manifest,
      map: read.map,
      layerId: layerId,
      featureId: feature.id,
    ).diagnostics;
  } on Object {
    return {
      ...base,
      'status': 'error',
      'materialization': 'unknown',
      'errorCount': 1,
      'warningCount': 0,
      if (detail)
        'diagnostics': [
          {
            'code': 'border.query.inspection_failed',
            'severity': BorderDiagnosticSeverity.error.name,
            'suggestedAction': 'border.action.preview_and_apply_materialization',
          },
        ],
    };
  }
  final codes = diagnostics.map((diagnostic) => diagnostic.code).toSet();
  final errorCount = diagnostics
      .where((d) => d.severity == BorderDiagnosticSeverity.error)
      .length;
  final warningCount = diagnostics
      .where((d) => d.severity == BorderDiagnosticSeverity.warning)
      .length;
  final item = <String, Object?>{
    ...base,
    'status': errorCount > 0
        ? 'error'
        : warningCount > 0
            ? 'warning'
            : 'success',
    'materialization': codes.contains('border.materialization.missing')
        ? 'missing'
        : codes.contains('border.spatial.materialization_stale')
            ? 'stale'
            : 'fresh',
    'errorCount': errorCount,
    'warningCount': warningCount,
  };
  if (!detail) return item;
  final primitives = {
    for (final primitive in read.manifest.borderCatalog
            .recordById(feature.blueprintId)
            ?.latestPublished
            ?.definition
            .primitives ??
        const <BorderPublishedPrimitive>[])
      primitive.id: primitive,
  };
  final instances = {
    for (final instance in scene.instances) instance.id: instance,
  };
  return {
    ...item,
    'diagnostics': [
      for (final diagnostic
          in diagnostics.take(maximumBorderFeatureQueryDiagnostics))
        {
          'code': diagnostic.code,
          'severity': diagnostic.severity.name,
          'phase': diagnostic.phase.name,
          'scope': diagnostic.scope.name,
          if (diagnostic.slotKey != null) 'slotKey': diagnostic.slotKey,
          if (diagnostic.cell case final cell?)
            'cell': {'x': cell.x, 'y': cell.y},
          if (diagnostic.parameters.isNotEmpty)
            'parameters': diagnostic.parameters,
          'suggestedAction': diagnostic.suggestedAction,
        },
    ],
    if (diagnostics.length > maximumBorderFeatureQueryDiagnostics)
      'diagnosticsTruncated': true,
    'slots': [
      for (final placement in placements)
        {
          'slotKey': placement.slotKey,
          'primitiveId': placement.primitiveId,
          if (primitives[placement.primitiveId] case final primitive?)
            'role': primitive.role.name,
          'instanceId': placement.instanceId,
          if (instances[placement.instanceId] case final instance?) ...{
            'modelId': instance.modelId,
            'position': {
              'x': instance.position.x,
              'y': instance.position.y,
              'z': instance.position.z,
            },
            'rotationDegrees': instance.rotationDegrees,
          },
        },
    ],
  };
}
