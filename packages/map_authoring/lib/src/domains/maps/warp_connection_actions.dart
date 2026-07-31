import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import '../../workspace/project_snapshot.dart';
import 'map_lifecycle_adapter.dart';
import 'semantic_map_action_support.dart';
import 'world_graph_queries.dart';

final class ConnectionAlignmentPreview {
  const ConnectionAlignmentPreview({
    required this.direction,
    required this.offset,
    required this.sourceStart,
    required this.targetStart,
    required this.overlapLength,
  });

  final MapConnectionDirection direction;
  final int offset;
  final int sourceStart;
  final int targetStart;
  final int overlapLength;

  bool get hasOverlap => overlapLength > 0;

  Map<String, Object?> toJson() => {
        'direction': direction.name,
        'offset': offset,
        'sourceStart': sourceStart,
        'targetStart': targetStart,
        'overlapLength': overlapLength,
        'hasOverlap': hasOverlap,
      };
}

final class WarpPairIssue {
  const WarpPairIssue({
    required this.code,
    required this.sourceMapId,
    required this.warpId,
    required this.targetMapId,
  });

  final String code;
  final String sourceMapId;
  final String warpId;
  final String targetMapId;

  Map<String, Object?> toJson() => {
        'code': code,
        'sourceMapId': sourceMapId,
        'warpId': warpId,
        'targetMapId': targetMapId,
      };
}

/// Canonical single-map and recoverable paired warp/connection mutations.
final class WarpConnectionActions {
  const WarpConnectionActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    for (final entry in const <(String, String, AuthoringRiskLevel)>[
      ('warp.create', 'Create a validated warp', AuthoringRiskLevel.low),
      ('warp.update', 'Replace a validated warp', AuthoringRiskLevel.low),
      ('warp.delete', 'Delete a warp', AuthoringRiskLevel.low),
      (
        'warp.create_reciprocal_apply',
        'Create a recoverable reciprocal warp pair',
        AuthoringRiskLevel.medium,
      ),
      (
        'warp.update_pair_apply',
        'Update both ends of a reciprocal warp pair',
        AuthoringRiskLevel.medium,
      ),
      (
        'warp.delete_pair_apply',
        'Delete both ends of a reciprocal warp pair',
        AuthoringRiskLevel.medium,
      ),
      (
        'connection.upsert',
        'Create or replace a validated connection',
        AuthoringRiskLevel.low,
      ),
      (
        'connection.delete',
        'Delete one map connection',
        AuthoringRiskLevel.low,
      ),
      (
        'connection.create_bidirectional_apply',
        'Create a recoverable bidirectional connection',
        AuthoringRiskLevel.medium,
      ),
      (
        'connection.update_bidirectional_apply',
        'Update both ends of a bidirectional connection',
        AuthoringRiskLevel.medium,
      ),
      (
        'connection.delete_bidirectional_apply',
        'Delete both ends of a bidirectional connection',
        AuthoringRiskLevel.medium,
      ),
    ])
      _descriptor(entry.$1, entry.$2, entry.$3),
  ]);

  List<MapWarp> listWarps(MapData map) => List.unmodifiable(
        map.warps.toList()..sort((left, right) => left.id.compareTo(right.id)),
      );

  MapWarp getWarp(MapData map, String warpId) => _warp(map, warpId);

  List<MapConnection> listConnections(MapData map) => List.unmodifiable(
        map.connections.toList()
          ..sort((left, right) =>
              left.direction.index.compareTo(right.direction.index)),
      );

  MapConnection getConnection(
    MapData map,
    MapConnectionDirection direction,
  ) =>
      _connection(map, direction);

  ConnectionAlignmentPreview previewAlignment({
    required GridSize sourceSize,
    required GridSize targetSize,
    required MapConnectionDirection direction,
    required int offset,
  }) {
    final overlap = computeMapConnectionOverlapLength(
      sourceSize: sourceSize,
      targetSize: targetSize,
      direction: direction,
      offset: offset,
    );
    return ConnectionAlignmentPreview(
      direction: direction,
      offset: offset,
      sourceStart: offset < 0 ? 0 : offset,
      targetStart: offset < 0 ? -offset : 0,
      overlapLength: overlap,
    );
  }

  MapData validateWarpTarget(
    ProjectSnapshot snapshot, {
    required String sourceMapId,
    required MapWarp warp,
  }) {
    final source = snapshot.mapById(sourceMapId);
    if (source == null) {
      throw _failure(
        'warp.source_map_missing',
        'The source map does not exist in the current project snapshot.',
        details: {'sourceMapId': sourceMapId},
      );
    }
    return _validateWarpTargetInSnapshot(snapshot, source, warp);
  }

  List<WorldGraphIssue> validateConnections(ProjectSnapshot snapshot) =>
      List.unmodifiable(
        const WorldGraphQueries()
            .validateConsistency(snapshot)
            .where((issue) => issue.code.contains('.connection_')),
      );

  List<WarpPairIssue> validateWarpPairs(Iterable<MapData> maps) {
    final byId = {for (final map in maps) map.id: map};
    final issues = <WarpPairIssue>[];
    final orderedMaps = maps.toList()
      ..sort((left, right) => left.id.compareTo(right.id));
    for (final map in orderedMaps) {
      final warps = map.warps.toList()
        ..sort((left, right) => left.id.compareTo(right.id));
      for (final warp in warps) {
        final target = byId[warp.targetMapId];
        final code = target == null
            ? 'warp.target_map_missing'
            : _matchingReciprocals(target, map, warp).length == 1
                ? null
                : 'warp.reciprocal_mismatch';
        if (code != null) {
          issues.add(WarpPairIssue(
            code: code,
            sourceMapId: map.id,
            warpId: warp.id,
            targetMapId: warp.targetMapId,
          ));
        }
      }
    }
    return List.unmodifiable(issues);
  }

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    if (planning.request.actionVersion != 1) {
      throw _failure(
        'map.action_version_unsupported',
        'The requested warp or connection action version is unsupported.',
      );
    }
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'warp.create' => const {'warp'},
      'warp.create_reciprocal_apply' => const {'warp', 'reciprocalWarpId'},
      'warp.update' => const {'warpId', 'warp'},
      'warp.update_pair_apply' => const {
          'warpId',
          'warp',
          'reciprocalWarpId',
        },
      'warp.delete' => const {'warpId'},
      'warp.delete_pair_apply' => const {'warpId', 'reciprocalWarpId'},
      'connection.upsert' ||
      'connection.create_bidirectional_apply' ||
      'connection.update_bidirectional_apply' =>
        const {'direction', 'targetMapId', 'offset'},
      'connection.delete' || 'connection.delete_bidirectional_apply' => const {
          'direction',
        },
      _ => throw _failure(
          'map.action_unsupported',
          'The requested warp or connection action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;

    switch (actionId) {
      case 'warp.create':
        final warp = _parseWarp(parameters.object('warp'));
        _validateWarpTarget(planning, context.map, warp);
        return context.draftMap(
          after: _addWarp(context.map, warp),
          operation: 'warp.create',
          changedItems: 1,
          preview: {'warpId': warp.id, 'targetMapId': warp.targetMapId},
        );
      case 'warp.update':
        final warpId = parameters.string('warpId');
        final warp = _parseWarp(parameters.object('warp'));
        _validateWarpTarget(planning, context.map, warp);
        return context.draftMap(
          after: _replaceWarp(context.map, warpId, warp),
          operation: 'warp.update',
          changedItems: 1,
          preview: {'warpId': warp.id, 'targetMapId': warp.targetMapId},
        );
      case 'warp.delete':
        final warpId = parameters.string('warpId');
        return context.draftMap(
          after: _removeWarp(context.map, warpId),
          operation: 'warp.delete',
          changedItems: 1,
          preview: {'warpId': warpId},
        );
      case 'warp.create_reciprocal_apply':
        return _createReciprocal(planning, context);
      case 'warp.update_pair_apply':
        return _updateWarpPair(planning, context);
      case 'warp.delete_pair_apply':
        return _deleteWarpPair(planning, context);
      case 'connection.upsert':
        return _upsertConnection(planning, context);
      case 'connection.delete':
        final direction = _direction(parameters.string('direction'));
        return context.draftMap(
          after: _removeConnection(context.map, direction),
          operation: 'connection.delete',
          changedItems: 1,
          preview: {'direction': direction.name},
        );
      case 'connection.create_bidirectional_apply':
        return _upsertBidirectional(planning, context, createOnly: true);
      case 'connection.update_bidirectional_apply':
        return _upsertBidirectional(planning, context, createOnly: false);
      case 'connection.delete_bidirectional_apply':
        return _deleteBidirectional(planning, context);
    }
    throw StateError('unreachable action: $actionId');
  }

  AuthoringMutationDraft _createReciprocal(
    AuthoringPlanningContext planning,
    SemanticMapActionContext context,
  ) {
    final sourceWarp = _parseWarp(context.parameters.object('warp'));
    final target = _validateWarpTarget(planning, context.map, sourceWarp);
    _requireDistinctMaps(context.map, target, kind: 'warp pair');
    final reciprocalId =
        context.parameters.optionalString('reciprocalWarpId') ??
            _uniqueWarpId(target, '${sourceWarp.id}_return');
    final reciprocal = _reciprocalWarp(
      sourceMap: context.map,
      sourceWarp: sourceWarp,
      id: reciprocalId,
    );
    final sourceAfter = _addWarp(context.map, sourceWarp);
    final targetAfter = _addWarp(target, reciprocal);
    return _draftPair(
      planning: planning,
      sourceBefore: context.map,
      sourceAfter: sourceAfter,
      targetBefore: target,
      targetAfter: targetAfter,
      operation: 'warp.create_reciprocal_apply',
      collection: 'warps',
      preview: {
        'warpId': sourceWarp.id,
        'reciprocalWarpId': reciprocal.id,
      },
    );
  }

  AuthoringMutationDraft _updateWarpPair(
    AuthoringPlanningContext planning,
    SemanticMapActionContext context,
  ) {
    final warpId = context.parameters.string('warpId');
    final current = _warp(context.map, warpId);
    final updated = _parseWarp(context.parameters.object('warp'));
    if (updated.targetMapId != current.targetMapId) {
      throw _failure(
        'warp.pair_target_change_unsupported',
        'Pair updates cannot move an existing pair to another target map.',
      );
    }
    final target = _validateWarpTarget(planning, context.map, updated);
    _requireDistinctMaps(context.map, target, kind: 'warp pair');
    final reciprocal = _requireReciprocal(
      sourceMap: context.map,
      sourceWarp: current,
      targetMap: target,
      explicitId: context.parameters.optionalString('reciprocalWarpId'),
    );
    final sourceAfter = _replaceWarp(context.map, warpId, updated);
    final targetAfter = _replaceWarp(
      target,
      reciprocal.id,
      _reciprocalWarp(
        sourceMap: context.map,
        sourceWarp: updated,
        id: reciprocal.id,
      ),
    );
    return _draftPair(
      planning: planning,
      sourceBefore: context.map,
      sourceAfter: sourceAfter,
      targetBefore: target,
      targetAfter: targetAfter,
      operation: 'warp.update_pair_apply',
      collection: 'warps',
      preview: {
        'warpId': updated.id,
        'reciprocalWarpId': reciprocal.id,
      },
    );
  }

  AuthoringMutationDraft _deleteWarpPair(
    AuthoringPlanningContext planning,
    SemanticMapActionContext context,
  ) {
    final warpId = context.parameters.string('warpId');
    final sourceWarp = _warp(context.map, warpId);
    final target = _targetMap(planning, sourceWarp.targetMapId, kind: 'warp');
    _requireDistinctMaps(context.map, target, kind: 'warp pair');
    final reciprocal = _requireReciprocal(
      sourceMap: context.map,
      sourceWarp: sourceWarp,
      targetMap: target,
      explicitId: context.parameters.optionalString('reciprocalWarpId'),
    );
    return _draftPair(
      planning: planning,
      sourceBefore: context.map,
      sourceAfter: _removeWarp(context.map, sourceWarp.id),
      targetBefore: target,
      targetAfter: _removeWarp(target, reciprocal.id),
      operation: 'warp.delete_pair_apply',
      collection: 'warps',
      preview: {
        'warpId': sourceWarp.id,
        'reciprocalWarpId': reciprocal.id,
      },
    );
  }

  AuthoringMutationDraft _upsertConnection(
    AuthoringPlanningContext planning,
    SemanticMapActionContext context,
  ) {
    final connection = _connectionFrom(context.parameters);
    final target = _targetMap(
      planning,
      connection.targetMapId,
      kind: 'connection',
    );
    final alignment = previewAlignment(
      sourceSize: context.map.size,
      targetSize: target.size,
      direction: connection.direction,
      offset: connection.offset,
    );
    _requireOverlap(alignment, context.map.id, target.id);
    return context.draftMap(
      after: _upsertConnectionOnMap(context.map, connection),
      operation: 'connection.upsert',
      changedItems: 1,
      preview: {
        'targetMapId': target.id,
        ...alignment.toJson(),
      },
    );
  }

  AuthoringMutationDraft _upsertBidirectional(
    AuthoringPlanningContext planning,
    SemanticMapActionContext context, {
    required bool createOnly,
  }) {
    final sourceConnection = _connectionFrom(context.parameters);
    final target = _targetMap(
      planning,
      sourceConnection.targetMapId,
      kind: 'connection',
    );
    _requireDistinctMaps(context.map, target, kind: 'connection');
    final targetConnection = MapConnection(
      direction: sourceConnection.direction.opposite,
      targetMapId: context.map.id,
      offset: -sourceConnection.offset,
    );
    final alignment = previewAlignment(
      sourceSize: context.map.size,
      targetSize: target.size,
      direction: sourceConnection.direction,
      offset: sourceConnection.offset,
    );
    _requireOverlap(alignment, context.map.id, target.id);
    final sourceExisting = findMapConnection(
      context.map,
      sourceConnection.direction,
    );
    final targetExisting = findMapConnection(
      target,
      targetConnection.direction,
    );
    if (createOnly && (sourceExisting != null || targetExisting != null)) {
      throw _failure(
        'connection.pair_already_exists',
        'A connection already occupies one direction of the requested pair.',
      );
    }
    if (!createOnly &&
        (sourceExisting == null ||
            targetExisting == null ||
            sourceExisting.targetMapId != target.id ||
            targetExisting.targetMapId != context.map.id)) {
      throw _failure(
        'connection.pair_missing',
        'An exact bidirectional connection pair is required for update.',
      );
    }
    return _draftPair(
      planning: planning,
      sourceBefore: context.map,
      sourceAfter: _upsertConnectionOnMap(context.map, sourceConnection),
      targetBefore: target,
      targetAfter: _upsertConnectionOnMap(target, targetConnection),
      operation: createOnly
          ? 'connection.create_bidirectional_apply'
          : 'connection.update_bidirectional_apply',
      collection: 'connections',
      preview: {
        'direction': sourceConnection.direction.name,
        'reciprocalDirection': targetConnection.direction.name,
        ...alignment.toJson(),
      },
    );
  }

  AuthoringMutationDraft _deleteBidirectional(
    AuthoringPlanningContext planning,
    SemanticMapActionContext context,
  ) {
    final direction = _direction(context.parameters.string('direction'));
    final sourceConnection = _connection(context.map, direction);
    final target = _targetMap(
      planning,
      sourceConnection.targetMapId,
      kind: 'connection',
    );
    _requireDistinctMaps(context.map, target, kind: 'connection');
    final targetConnection = findMapConnection(target, direction.opposite);
    if (targetConnection == null ||
        targetConnection.targetMapId != context.map.id ||
        targetConnection.offset != -sourceConnection.offset) {
      throw _failure(
        'connection.pair_mismatch',
        'The reciprocal connection does not exactly match the source.',
      );
    }
    return _draftPair(
      planning: planning,
      sourceBefore: context.map,
      sourceAfter: _removeConnection(context.map, direction),
      targetBefore: target,
      targetAfter: _removeConnection(target, direction.opposite),
      operation: 'connection.delete_bidirectional_apply',
      collection: 'connections',
      preview: {
        'direction': direction.name,
        'reciprocalDirection': direction.opposite.name,
      },
    );
  }
}

AuthoringActionDescriptor _descriptor(
  String id,
  String summary,
  AuthoringRiskLevel risk,
) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'schema.$id.input.v1',
      outputSchemaId: 'schema.map.inter_map_mutation.output.v1',
      riskLevel: risk,
      resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'multiFileGuarantee': 'recoverable',
      },
    );

AuthoringMutationDraft _draftPair({
  required AuthoringPlanningContext planning,
  required MapData sourceBefore,
  required MapData sourceAfter,
  required MapData targetBefore,
  required MapData targetAfter,
  required String operation,
  required String collection,
  required Map<String, Object?> preview,
}) {
  _validateProjected(planning, sourceAfter);
  _validateProjected(planning, targetAfter);
  final changes = <AuthoringResourceChange>[];
  final diffs = <AuthoringDiffEntry>[];
  void addChange(MapData before, MapData after) {
    if (before == after) return;
    final change = _mapChange(planning, before, after);
    changes.add(change);
    diffs.add(AuthoringDiffEntry(
      operation: AuthoringDiffOperation.replace,
      resource: change.resource,
      path: '/$collection',
      before: semanticMapSummary(before),
      after: semanticMapSummary(after),
    ));
  }

  addChange(sourceBefore, sourceAfter);
  addChange(targetBefore, targetAfter);
  if (changes.isEmpty) {
    throw _failure(
      'map.no_change',
      'The inter-map operation changes nothing.',
    );
  }
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(
      changes: changes,
      diff: AuthoringDiff(diffs),
    ),
    preview: {
      'operation': operation,
      'sourceMapId': sourceBefore.id,
      'targetMapId': targetBefore.id,
      'changedMapCount': changes.length,
      'multiMapGuarantee': 'recoverable',
      'seed': planning.seed,
      ...preview,
    },
  );
}

AuthoringResourceChange _mapChange(
  AuthoringPlanningContext planning,
  MapData before,
  MapData after,
) {
  final entry = planning.snapshot.manifest.maps
      .where((candidate) => candidate.id == before.id)
      .firstOrNull;
  final revision = planning.snapshot.resourceFingerprints['map:${before.id}'];
  if (entry == null || revision == null) {
    throw _failure(
      'map.resource_preimage_missing',
      'An inter-map mutation resource pre-image is unavailable.',
      details: {'mapId': before.id},
    );
  }
  return AuthoringResourceChange(
    resource: AuthoringResourceRef(
      kind: 'map',
      id: before.id,
      revision: revision,
    ),
    storageKey: entry.relativePath,
    beforeBytes: planning.snapshot.resourceBytes('map:${before.id}'),
    afterBytes: encodeMapAuthoringDocument(after),
  );
}

void _validateProjected(AuthoringPlanningContext planning, MapData map) {
  try {
    MapValidator.validate(
      map,
      projectDialogueContext: planning.snapshot.manifest,
    );
  } on Object catch (error) {
    throw _failure(
      'map.inter_map_projected_state_invalid',
      'The inter-map mutation would produce invalid PokeMap data.',
      details: {
        'mapId': map.id,
        'validationType': error.runtimeType.toString(),
      },
    );
  }
}

MapData _targetMap(
  AuthoringPlanningContext planning,
  String targetMapId, {
  required String kind,
}) =>
    _targetMapInSnapshot(planning.snapshot, targetMapId, kind: kind);

MapData _targetMapInSnapshot(
  ProjectSnapshot snapshot,
  String targetMapId, {
  required String kind,
}) {
  if (targetMapId.trim() != targetMapId || targetMapId.isEmpty) {
    throw _failure(
      '$kind.target_map_invalid',
      'The target map ID must be nonblank and trimmed.',
    );
  }
  final manifestOwns =
      snapshot.manifest.maps.any((entry) => entry.id == targetMapId);
  final target = snapshot.mapById(targetMapId);
  if (!manifestOwns || target == null) {
    throw _failure(
      '$kind.target_map_missing',
      'The target map does not exist in the current project snapshot.',
      details: {'targetMapId': targetMapId},
    );
  }
  return target;
}

MapData _validateWarpTarget(
  AuthoringPlanningContext planning,
  MapData source,
  MapWarp warp,
) =>
    _validateWarpTargetInSnapshot(planning.snapshot, source, warp);

MapData _validateWarpTargetInSnapshot(
  ProjectSnapshot snapshot,
  MapData source,
  MapWarp warp,
) {
  final target = _targetMapInSnapshot(
    snapshot,
    warp.targetMapId,
    kind: 'warp',
  );
  if (!_inBounds(warp.targetPos, target.size)) {
    throw _failure(
      'warp.target_position_out_of_bounds',
      'The warp target position is outside the target map.',
      details: {
        'sourceMapId': source.id,
        'targetMapId': target.id,
        'x': warp.targetPos.x,
        'y': warp.targetPos.y,
      },
    );
  }
  return target;
}

MapWarp _parseWarp(Map<String, Object?> value) {
  const allowed = {
    'id',
    'pos',
    'targetMapId',
    'targetPos',
    'triggerMode',
    'allowedApproachFacings',
    'triggerPadding',
  };
  final unknown = value.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw _failure(
      'warp.payload_invalid',
      'The warp payload contains unsupported fields.',
      details: {'unknownFields': unknown},
    );
  }
  try {
    return MapWarp.fromJson(Map<String, dynamic>.from(value));
  } on Object {
    throw _failure(
      'warp.payload_invalid',
      'The warp payload is not valid typed PokeMap data.',
    );
  }
}

MapConnection _connectionFrom(SemanticParameters parameters) => MapConnection(
      direction: _direction(parameters.string('direction')),
      targetMapId: parameters.string('targetMapId'),
      offset: parameters.integer('offset'),
    );

MapConnectionDirection _direction(String value) {
  for (final direction in MapConnectionDirection.values) {
    if (direction.name == value) return direction;
  }
  throw _failure(
    'connection.direction_invalid',
    'The connection direction is unsupported.',
    details: {'direction': value},
  );
}

MapData _addWarp(MapData map, MapWarp warp) {
  try {
    return addWarpToMap(map, warp: warp);
  } on Object catch (error) {
    throw _coreFailure('warp.create_invalid', error);
  }
}

MapData _replaceWarp(MapData map, String warpId, MapWarp warp) {
  try {
    return updateWarpOnMap(
      map,
      warpId: warpId,
      id: warp.id,
      pos: warp.pos,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      triggerMode: warp.triggerMode,
      allowedApproachFacings: warp.allowedApproachFacings,
      triggerPadding: warp.triggerPadding,
    );
  } on Object catch (error) {
    throw _coreFailure('warp.update_invalid', error);
  }
}

MapData _removeWarp(MapData map, String warpId) {
  try {
    return removeWarpFromMap(map, warpId: warpId);
  } on Object catch (error) {
    throw _coreFailure('warp.delete_invalid', error);
  }
}

MapData _upsertConnectionOnMap(MapData map, MapConnection connection) {
  try {
    return upsertMapConnectionOnMap(map, connection: connection);
  } on Object catch (error) {
    throw _coreFailure('connection.upsert_invalid', error);
  }
}

MapData _removeConnection(
  MapData map,
  MapConnectionDirection direction,
) {
  try {
    return removeMapConnectionFromMap(map, direction: direction);
  } on Object catch (error) {
    throw _coreFailure('connection.delete_invalid', error);
  }
}

MapWarp _warp(MapData map, String warpId) {
  for (final warp in map.warps) {
    if (warp.id == warpId) return warp;
  }
  throw _failure(
    'warp.not_found',
    'The requested warp does not exist.',
    details: {'mapId': map.id, 'warpId': warpId},
  );
}

MapConnection _connection(
  MapData map,
  MapConnectionDirection direction,
) {
  final connection = findMapConnection(map, direction);
  if (connection != null) return connection;
  throw _failure(
    'connection.not_found',
    'The requested connection does not exist.',
    details: {'mapId': map.id, 'direction': direction.name},
  );
}

MapWarp _reciprocalWarp({
  required MapData sourceMap,
  required MapWarp sourceWarp,
  required String id,
}) =>
    MapWarp(
      id: id,
      pos: sourceWarp.targetPos,
      targetMapId: sourceMap.id,
      targetPos: sourceWarp.pos,
      triggerMode: sourceWarp.triggerMode,
      allowedApproachFacings: [
        for (final facing in sourceWarp.allowedApproachFacings)
          _oppositeFacing(facing),
      ],
      triggerPadding: sourceWarp.triggerPadding,
    );

MapWarp _requireReciprocal({
  required MapData sourceMap,
  required MapWarp sourceWarp,
  required MapData targetMap,
  required String? explicitId,
}) {
  final matches = _matchingReciprocals(targetMap, sourceMap, sourceWarp);
  if (explicitId != null) {
    final explicit = targetMap.warps.where((warp) => warp.id == explicitId);
    if (explicit.length == 1 && matches.contains(explicit.single)) {
      return explicit.single;
    }
  } else if (matches.length == 1) {
    return matches.single;
  }
  throw _failure(
    'warp.reciprocal_mismatch',
    'The reciprocal warp is missing or ambiguous.',
    details: {
      'sourceMapId': sourceMap.id,
      'warpId': sourceWarp.id,
      'targetMapId': targetMap.id,
      'candidateCount': matches.length,
    },
  );
}

List<MapWarp> _matchingReciprocals(
  MapData targetMap,
  MapData sourceMap,
  MapWarp sourceWarp,
) =>
    targetMap.warps
        .where(
          (candidate) =>
              candidate.pos == sourceWarp.targetPos &&
              candidate.targetMapId == sourceMap.id &&
              candidate.targetPos == sourceWarp.pos &&
              candidate.triggerMode == sourceWarp.triggerMode &&
              candidate.triggerPadding == sourceWarp.triggerPadding &&
              _sameFacings(
                candidate.allowedApproachFacings,
                [
                  for (final facing in sourceWarp.allowedApproachFacings)
                    _oppositeFacing(facing),
                ],
              ),
        )
        .toList();

bool _sameFacings(List<EntityFacing> left, List<EntityFacing> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

String _uniqueWarpId(MapData target, String preferred) {
  final existing = {for (final warp in target.warps) warp.id};
  if (!existing.contains(preferred)) return preferred;
  var suffix = 2;
  while (existing.contains('${preferred}_$suffix')) {
    suffix++;
  }
  return '${preferred}_$suffix';
}

void _requireDistinctMaps(
  MapData source,
  MapData target, {
  required String kind,
}) {
  if (source.id == target.id) {
    throw _failure(
      'map.inter_map_self_target',
      'A recoverable $kind must target a distinct map.',
      details: {'mapId': source.id},
    );
  }
}

void _requireOverlap(
  ConnectionAlignmentPreview preview,
  String sourceMapId,
  String targetMapId,
) {
  if (!preview.hasOverlap) {
    throw _failure(
      'connection.no_overlap',
      'The requested connection has no overlapping border cells.',
      details: {
        'sourceMapId': sourceMapId,
        'targetMapId': targetMapId,
        ...preview.toJson(),
      },
    );
  }
}

EntityFacing _oppositeFacing(EntityFacing value) => switch (value) {
      EntityFacing.north => EntityFacing.south,
      EntityFacing.south => EntityFacing.north,
      EntityFacing.east => EntityFacing.west,
      EntityFacing.west => EntityFacing.east,
    };

bool _inBounds(GridPos pos, GridSize size) =>
    pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;

MapAuthoringException _coreFailure(String code, Object error) => _failure(
      code,
      'The requested spatial relation mutation is invalid.',
      details: {'validationType': error.runtimeType.toString()},
    );

MapAuthoringException _failure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
}) =>
    MapAuthoringException(
      code: code,
      message: message,
      details: details,
    );
