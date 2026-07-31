# PMCP-035 — Annexe des fichiers créés

Cette annexe reproduit intégralement les fichiers source et test créés par le lot.

## `packages/map_authoring/lib/src/domains/maps/warp_connection_actions.dart`

```dart
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
```

## `packages/map_authoring/lib/src/domains/maps/world_graph_queries.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../workspace/project_snapshot.dart';
import 'map_lifecycle_adapter.dart';

enum WorldGraphEdgeKind {
  connection,
  warp,
}

final class WorldGraphEdge {
  const WorldGraphEdge({
    required this.sourceMapId,
    required this.targetMapId,
    required this.kind,
    required this.sourceId,
  });

  final String sourceMapId;
  final String targetMapId;
  final WorldGraphEdgeKind kind;
  final String sourceId;

  Map<String, Object?> toJson() => {
        'sourceMapId': sourceMapId,
        'targetMapId': targetMapId,
        'kind': kind.name,
        'sourceId': sourceId,
      };
}

final class WorldGraphIssue {
  WorldGraphIssue({
    required this.code,
    required this.message,
    required this.mapId,
    this.targetMapId,
    this.sourceId,
  });

  final String code;
  final String message;
  final String mapId;
  final String? targetMapId;
  final String? sourceId;

  Map<String, Object?> toJson() => {
        'code': code,
        'message': message,
        'mapId': mapId,
        if (targetMapId != null) 'targetMapId': targetMapId,
        if (sourceId != null) 'sourceId': sourceId,
      };
}

final class WorldGraphInspection {
  WorldGraphInspection({
    required Iterable<String> nodes,
    required Iterable<WorldGraphEdge> edges,
    required Iterable<WorldGraphIssue> issues,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges),
        issues = List.unmodifiable(issues);

  final List<String> nodes;
  final List<WorldGraphEdge> edges;
  final List<WorldGraphIssue> issues;

  bool get isConsistent => issues.isEmpty;

  Map<String, Object?> toJson() => {
        'nodes': nodes,
        'edges': [for (final edge in edges) edge.toJson()],
        'issues': [for (final issue in issues) issue.toJson()],
        'isConsistent': isConsistent,
      };
}

/// Logical rendering model only. PokeMap currently persists no map coordinates.
final class WorldGraphRenderModel {
  WorldGraphRenderModel({
    required Iterable<String> nodes,
    required Iterable<WorldGraphEdge> edges,
  })  : nodes = List.unmodifiable(nodes),
        edges = List.unmodifiable(edges);

  final List<String> nodes;
  final List<WorldGraphEdge> edges;

  bool get hasPersistentLayout => false;

  Map<String, Object?> toJson() => {
        'nodes': nodes,
        'edges': [for (final edge in edges) edge.toJson()],
        'hasPersistentLayout': hasPersistentLayout,
        'layoutPolicy': 'logical_graph_only',
      };
}

/// Deterministic directed graph queries over authored warps and connections.
final class WorldGraphQueries {
  const WorldGraphQueries();

  WorldGraphInspection inspect(ProjectSnapshot snapshot) {
    final nodes = <String>{
      for (final entry in snapshot.manifest.maps) entry.id,
      for (final map in snapshot.maps) map.id,
    }.toList()
      ..sort();
    final knownMapIds = {for (final map in snapshot.maps) map.id};
    final manifestMapIds = {
      for (final entry in snapshot.manifest.maps) entry.id,
    };
    final edges = <WorldGraphEdge>[];
    final issues = <WorldGraphIssue>[];

    for (final mapId in manifestMapIds.difference(knownMapIds).toList()
      ..sort()) {
      issues.add(WorldGraphIssue(
        code: 'world_graph.map_document_missing',
        message: 'A declared map has no loaded document.',
        mapId: mapId,
      ));
    }
    for (final mapId in knownMapIds.difference(manifestMapIds).toList()
      ..sort()) {
      issues.add(WorldGraphIssue(
        code: 'world_graph.manifest_entry_missing',
        message: 'A loaded map has no project manifest entry.',
        mapId: mapId,
      ));
    }

    for (final map in snapshot.maps) {
      for (final connection in map.connections) {
        edges.add(WorldGraphEdge(
          sourceMapId: map.id,
          targetMapId: connection.targetMapId,
          kind: WorldGraphEdgeKind.connection,
          sourceId: connection.direction.name,
        ));
        final target = snapshot.mapById(connection.targetMapId);
        if (target == null) {
          issues.add(_missingTarget(
            mapId: map.id,
            targetMapId: connection.targetMapId,
            sourceId: connection.direction.name,
            kind: 'connection',
          ));
          continue;
        }
        final reciprocal = findMapConnection(
          target,
          connection.direction.opposite,
        );
        if (reciprocal == null ||
            reciprocal.targetMapId != map.id ||
            reciprocal.offset != -connection.offset) {
          issues.add(WorldGraphIssue(
            code: 'world_graph.connection_reciprocal_mismatch',
            message: 'A connection has no exact reciprocal connection.',
            mapId: map.id,
            targetMapId: target.id,
            sourceId: connection.direction.name,
          ));
        }
        if (!hasMapConnectionOverlap(
          sourceSize: map.size,
          targetSize: target.size,
          direction: connection.direction,
          offset: connection.offset,
        )) {
          issues.add(WorldGraphIssue(
            code: 'world_graph.connection_no_overlap',
            message: 'A connection has no overlapping border cells.',
            mapId: map.id,
            targetMapId: target.id,
            sourceId: connection.direction.name,
          ));
        }
      }
      for (final warp in map.warps) {
        edges.add(WorldGraphEdge(
          sourceMapId: map.id,
          targetMapId: warp.targetMapId,
          kind: WorldGraphEdgeKind.warp,
          sourceId: warp.id,
        ));
        final target = snapshot.mapById(warp.targetMapId);
        if (target == null) {
          issues.add(_missingTarget(
            mapId: map.id,
            targetMapId: warp.targetMapId,
            sourceId: warp.id,
            kind: 'warp',
          ));
        } else if (!_inBounds(warp.targetPos, target.size)) {
          issues.add(WorldGraphIssue(
            code: 'world_graph.warp_target_out_of_bounds',
            message: 'A warp targets a position outside its target map.',
            mapId: map.id,
            targetMapId: target.id,
            sourceId: warp.id,
          ));
        }
      }
    }

    edges.sort(_compareEdges);
    issues.sort(_compareIssues);
    return WorldGraphInspection(
      nodes: nodes,
      edges: edges,
      issues: issues,
    );
  }

  List<String> listConnected(
    ProjectSnapshot snapshot, {
    required String fromMapId,
  }) {
    final inspection = inspect(snapshot);
    _requireNode(inspection, fromMapId);
    final adjacency = _adjacency(inspection);
    final visited = <String>{fromMapId};
    final queue = <String>[fromMapId];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      for (final target in adjacency[current] ?? const <String>[]) {
        if (visited.add(target)) queue.add(target);
      }
    }
    return List.unmodifiable(visited.toList()..sort());
  }

  List<String> listDisconnected(
    ProjectSnapshot snapshot, {
    required String fromMapId,
  }) {
    final inspection = inspect(snapshot);
    final connected = listConnected(snapshot, fromMapId: fromMapId).toSet();
    return List.unmodifiable([
      for (final node in inspection.nodes)
        if (!connected.contains(node)) node,
    ]);
  }

  List<String>? findPath(
    ProjectSnapshot snapshot, {
    required String sourceMapId,
    required String targetMapId,
  }) {
    final inspection = inspect(snapshot);
    _requireNode(inspection, sourceMapId);
    _requireNode(inspection, targetMapId);
    final adjacency = _adjacency(inspection);
    final previous = <String, String?>{sourceMapId: null};
    final queue = <String>[sourceMapId];
    var cursor = 0;
    while (cursor < queue.length) {
      final current = queue[cursor++];
      if (current == targetMapId) break;
      for (final target in adjacency[current] ?? const <String>[]) {
        if (!previous.containsKey(target)) {
          previous[target] = current;
          queue.add(target);
        }
      }
    }
    if (!previous.containsKey(targetMapId)) return null;
    final reverse = <String>[];
    String? current = targetMapId;
    while (current != null) {
      reverse.add(current);
      current = previous[current];
    }
    return List.unmodifiable(reverse.reversed);
  }

  List<WorldGraphIssue> validateConsistency(ProjectSnapshot snapshot) =>
      inspect(snapshot).issues;

  WorldGraphRenderModel render(ProjectSnapshot snapshot) {
    final inspection = inspect(snapshot);
    return WorldGraphRenderModel(
      nodes: inspection.nodes,
      edges: inspection.edges,
    );
  }
}

WorldGraphIssue _missingTarget({
  required String mapId,
  required String targetMapId,
  required String sourceId,
  required String kind,
}) =>
    WorldGraphIssue(
      code: 'world_graph.${kind}_target_missing',
      message: 'A $kind references a map that is not loaded.',
      mapId: mapId,
      targetMapId: targetMapId,
      sourceId: sourceId,
    );

Map<String, List<String>> _adjacency(WorldGraphInspection inspection) {
  final known = inspection.nodes.toSet();
  final values = <String, Set<String>>{
    for (final node in inspection.nodes) node: <String>{},
  };
  for (final edge in inspection.edges) {
    if (known.contains(edge.targetMapId)) {
      values[edge.sourceMapId]?.add(edge.targetMapId);
    }
  }
  return {
    for (final entry in values.entries)
      entry.key: List.unmodifiable(entry.value.toList()..sort()),
  };
}

void _requireNode(WorldGraphInspection inspection, String mapId) {
  if (!inspection.nodes.contains(mapId)) {
    throw MapAuthoringException(
      code: 'world_graph.map_missing',
      message: 'The requested map is absent from the world graph.',
      details: {'mapId': mapId},
    );
  }
}

bool _inBounds(GridPos pos, GridSize size) =>
    pos.x >= 0 && pos.y >= 0 && pos.x < size.width && pos.y < size.height;

int _compareEdges(WorldGraphEdge left, WorldGraphEdge right) {
  for (final comparison in <int>[
    left.sourceMapId.compareTo(right.sourceMapId),
    left.targetMapId.compareTo(right.targetMapId),
    left.kind.name.compareTo(right.kind.name),
    left.sourceId.compareTo(right.sourceId),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}

int _compareIssues(WorldGraphIssue left, WorldGraphIssue right) {
  for (final comparison in <int>[
    left.mapId.compareTo(right.mapId),
    (left.targetMapId ?? '').compareTo(right.targetMapId ?? ''),
    left.code.compareTo(right.code),
    (left.sourceId ?? '').compareTo(right.sourceId ?? ''),
  ]) {
    if (comparison != 0) return comparison;
  }
  return 0;
}
```

## `packages/map_authoring/lib/src/ports/map_render_port.dart`

```dart
import 'package:map_core/map_core.dart';

import '../contracts/resource_ref.dart';
import '../workspace/project_snapshot.dart';

enum MapRenderOverlay {
  collision,
  zones,
  warps,
  entities,
}

/// Immutable, path-free request for a revision-bound map preview.
final class MapRenderRequest {
  MapRenderRequest({
    required this.mapResource,
    required this.manifest,
    required this.map,
    MapRect? region,
    Iterable<String> layerIds = const [],
    Iterable<MapRenderOverlay> overlays = const [],
    this.cellPixelSize = 8,
  })  : region = region ??
            MapRect(
              pos: const GridPos(x: 0, y: 0),
              size: map.size,
            ),
        layerIds = _validatedLayerIds(map, layerIds),
        overlays = _sortedOverlays(overlays) {
    if (mapResource.kind != 'map' || mapResource.id != map.id) {
      throw ArgumentError.value(
        mapResource.toJson(),
        'mapResource',
        'must identify the supplied map',
      );
    }
    final revision = mapResource.revision;
    if (revision == null ||
        !RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(revision)) {
      throw ArgumentError.value(
        revision,
        'mapResource.revision',
        'must bind the render to a lowercase SHA-256 revision',
      );
    }
    if (!manifest.maps.any((entry) => entry.id == map.id)) {
      throw ArgumentError.value(
        map.id,
        'map',
        'must be owned by the supplied project manifest',
      );
    }
    _validateRegion(map, this.region);
    if (cellPixelSize < 1 || cellPixelSize > 64) {
      throw ArgumentError.value(
        cellPixelSize,
        'cellPixelSize',
        'must be between 1 and 64',
      );
    }
  }

  final AuthoringResourceRef mapResource;
  final ProjectManifest manifest;
  final MapData map;
  final MapRect region;
  final List<String> layerIds;
  final List<MapRenderOverlay> overlays;
  final int cellPixelSize;

  String get revision => mapResource.revision!;

  Map<String, Object?> toJson() => {
        'map': mapResource.toJson(),
        'region': _rectJson(region),
        'layerIds': layerIds,
        'overlays': [for (final overlay in overlays) overlay.name],
        'cellPixelSize': cellPixelSize,
      };
}

/// Rendered artifact whose source revision and visible scope are explicit.
final class MapRenderResult {
  MapRenderResult({
    required String mimeType,
    required Iterable<int> bytes,
    required this.width,
    required this.height,
    required String sourceRevision,
    required this.region,
    required Iterable<String> layerIds,
    required Iterable<MapRenderOverlay> overlays,
    Map<MapRenderOverlay, int> overlayCounts = const {},
  })  : mimeType = _nonBlank(mimeType, 'mimeType'),
        bytes = List<int>.unmodifiable(bytes),
        sourceRevision = _revision(sourceRevision),
        layerIds = List<String>.unmodifiable(layerIds),
        overlays = List<MapRenderOverlay>.unmodifiable(overlays),
        overlayCounts = Map.unmodifiable(overlayCounts) {
    if (!this.mimeType.startsWith('image/')) {
      throw ArgumentError.value(
        mimeType,
        'mimeType',
        'must describe an image artifact',
      );
    }
    if (this.bytes.isEmpty ||
        this.bytes.any((value) => value < 0 || value > 255)) {
      throw ArgumentError.value(bytes, 'bytes', 'must be nonempty bytes');
    }
    if (width < 1 || height < 1) {
      throw ArgumentError.value(
        '$width x $height',
        'dimensions',
        'must be positive',
      );
    }
    if (overlayCounts.values.any((value) => value < 0)) {
      throw ArgumentError.value(
        overlayCounts,
        'overlayCounts',
        'counts must not be negative',
      );
    }
  }

  final String mimeType;
  final List<int> bytes;
  final int width;
  final int height;
  final String sourceRevision;
  final MapRect region;
  final List<String> layerIds;
  final List<MapRenderOverlay> overlays;
  final Map<MapRenderOverlay, int> overlayCounts;

  Map<String, Object?> toJson() => {
        'mimeType': mimeType,
        'byteLength': bytes.length,
        'width': width,
        'height': height,
        'sourceRevision': sourceRevision,
        'region': _rectJson(region),
        'layerIds': layerIds,
        'overlays': [for (final overlay in overlays) overlay.name],
        'overlayCounts': {
          for (final entry in overlayCounts.entries)
            entry.key.name: entry.value,
        },
      };
}

abstract interface class MapRenderPort {
  Future<MapRenderResult> render(MapRenderRequest request);
}

/// Snapshot adapter for `map.render` and `map.render_region` query handlers.
final class MapRenderQueries {
  const MapRenderQueries(this._port);

  final MapRenderPort _port;

  Future<MapRenderResult> renderMap({
    required ProjectSnapshot snapshot,
    required String mapId,
    Iterable<String> layerIds = const [],
    Iterable<MapRenderOverlay> overlays = const [],
    int cellPixelSize = 8,
  }) =>
      _render(
        snapshot: snapshot,
        mapId: mapId,
        layerIds: layerIds,
        overlays: overlays,
        cellPixelSize: cellPixelSize,
      );

  Future<MapRenderResult> renderRegion({
    required ProjectSnapshot snapshot,
    required String mapId,
    required MapRect region,
    Iterable<String> layerIds = const [],
    Iterable<MapRenderOverlay> overlays = const [],
    int cellPixelSize = 8,
  }) =>
      _render(
        snapshot: snapshot,
        mapId: mapId,
        region: region,
        layerIds: layerIds,
        overlays: overlays,
        cellPixelSize: cellPixelSize,
      );

  Future<MapRenderResult> _render({
    required ProjectSnapshot snapshot,
    required String mapId,
    required Iterable<String> layerIds,
    required Iterable<MapRenderOverlay> overlays,
    required int cellPixelSize,
    MapRect? region,
  }) {
    final map = snapshot.mapById(mapId);
    final revision = snapshot.resourceFingerprints['map:$mapId'];
    if (map == null || revision == null) {
      throw ProjectSnapshotException(
        'map.render_source_missing',
        'The requested revision-bound map cannot be rendered.',
      );
    }
    final request = MapRenderRequest(
      mapResource: AuthoringResourceRef(
        kind: 'map',
        id: map.id,
        revision: revision,
      ),
      manifest: snapshot.manifest,
      map: map,
      region: region,
      layerIds: layerIds,
      overlays: overlays,
      cellPixelSize: cellPixelSize,
    );
    return _checkedRender(request);
  }

  Future<MapRenderResult> _checkedRender(MapRenderRequest request) async {
    final result = await _port.render(request);
    if (result.sourceRevision != request.revision) {
      throw const ProjectSnapshotException(
        'map.render_revision_mismatch',
        'The render result does not match the requested map revision.',
      );
    }
    if (result.region != request.region ||
        result.width != request.region.size.width * request.cellPixelSize ||
        result.height != request.region.size.height * request.cellPixelSize) {
      throw const ProjectSnapshotException(
        'map.render_scope_mismatch',
        'The render result does not match the requested map scope.',
      );
    }
    return result;
  }
}

List<String> _validatedLayerIds(MapData map, Iterable<String> values) {
  final known = {for (final layer in map.layers) layer.id};
  final result = <String>{};
  for (final value in values) {
    final normalized = _nonBlank(value, 'layerId');
    if (!known.contains(normalized)) {
      throw ArgumentError.value(
        value,
        'layerIds',
        'must identify a layer on the supplied map',
      );
    }
    result.add(normalized);
  }
  return List.unmodifiable(result.toList()..sort());
}

List<MapRenderOverlay> _sortedOverlays(Iterable<MapRenderOverlay> values) {
  final result = values.toSet().toList()
    ..sort((left, right) => left.name.compareTo(right.name));
  return List.unmodifiable(result);
}

void _validateRegion(MapData map, MapRect region) {
  final right = region.pos.x + region.size.width;
  final bottom = region.pos.y + region.size.height;
  if (region.size.width < 1 ||
      region.size.height < 1 ||
      region.pos.x < 0 ||
      region.pos.y < 0 ||
      right > map.size.width ||
      bottom > map.size.height) {
    throw ArgumentError.value(
      _rectJson(region),
      'region',
      'must be a positive rectangle inside the supplied map',
    );
  }
}

Map<String, Object?> _rectJson(MapRect value) => {
      'x': value.pos.x,
      'y': value.pos.y,
      'width': value.size.width,
      'height': value.size.height,
    };

String _nonBlank(String value, String field) {
  final normalized = value.trim();
  if (normalized.isEmpty || normalized != value) {
    throw ArgumentError.value(value, field, 'must be nonblank and trimmed');
  }
  return normalized;
}

String _revision(String value) {
  final normalized = _nonBlank(value, 'sourceRevision');
  if (!RegExp(r'^sha256:[0-9a-f]{64}$').hasMatch(normalized)) {
    throw ArgumentError.value(
      value,
      'sourceRevision',
      'must be a lowercase SHA-256 revision',
    );
  }
  return normalized;
}
```

## `packages/map_authoring/test/domains/maps/warp_connection_transaction_test.dart`

```dart
import 'dart:convert';
import 'dart:io';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('WarpConnectionActions', () {
    test('reciprocal warp is one recoverable two-map change set', () async {
      final source = _map('alpha');
      final target = _map('beta');
      final snapshot = _snapshot([source, target]);
      final request = _request(
        snapshot,
        actionId: 'warp.create_reciprocal_apply',
        parameters: {
          'mapId': 'alpha',
          'warp': const MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'beta',
            targetPos: GridPos(x: 2, y: 1),
            allowedApproachFacings: [EntityFacing.east],
          ).toJson(),
          'reciprocalWarpId': 'to_alpha',
        },
      );
      final actions = const WarpConnectionActions();
      final draft = actions.build(_context(snapshot, request));

      expect(
        draft.changeSet.changes.map((change) => change.resource.id),
        ['alpha', 'beta'],
      );
      expect(draft.preview['multiMapGuarantee'], 'recoverable');
      final projected = _projectedMaps(draft);
      expect(projected['alpha']!.warps.single.id, 'to_beta');
      expect(
          projected['beta']!.warps.single,
          const MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 2, y: 1),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 1, y: 1),
            allowedApproachFacings: [EntityFacing.west],
          ));
      expect(
        actions.validateWarpPairs(projected.values.toList()),
        isEmpty,
      );

      await _proveRecovery(snapshot, request);
    });

    test('invalid warp target is rejected before a draft exists', () {
      final snapshot = _snapshot([_map('alpha')]);
      final request = _request(
        snapshot,
        actionId: 'warp.create',
        parameters: {
          'mapId': 'alpha',
          'warp': const MapWarp(
            id: 'missing',
            pos: GridPos(x: 0, y: 0),
            targetMapId: 'missing_map',
            targetPos: GridPos(x: 0, y: 0),
          ).toJson(),
        },
      );

      expect(
        () => const WarpConnectionActions().build(
          _context(snapshot, request),
        ),
        throwsA(
          isA<MapAuthoringException>().having(
            (error) => error.code,
            'code',
            'warp.target_map_missing',
          ),
        ),
      );
    });

    test('bidirectional connection updates both maps and previews overlap', () {
      final snapshot = _snapshot([
        _map('alpha', width: 4, height: 3),
        _map('beta', width: 3, height: 3),
      ]);
      final request = _request(
        snapshot,
        actionId: 'connection.create_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
          'targetMapId': 'beta',
          'offset': 1,
        },
      );

      final draft = const WarpConnectionActions().build(
        _context(snapshot, request),
      );
      final projected = _projectedMaps(draft);

      expect(
          projected['alpha']!.connections.single,
          const MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'beta',
            offset: 1,
          ));
      expect(
          projected['beta']!.connections.single,
          const MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'alpha',
            offset: -1,
          ));
      expect(draft.preview['overlapLength'], 2);
      expect(draft.changeSet.changes, hasLength(2));
    });

    test('pair update and delete keep reciprocal warp fields coherent', () {
      final source = _map('alpha').copyWith(
        warps: const [
          MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'beta',
            targetPos: GridPos(x: 2, y: 1),
            allowedApproachFacings: [EntityFacing.east],
          ),
        ],
      );
      final target = _map('beta').copyWith(
        warps: const [
          MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 2, y: 1),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 1, y: 1),
            allowedApproachFacings: [EntityFacing.west],
          ),
        ],
      );
      final snapshot = _snapshot([source, target]);
      final update = _request(
        snapshot,
        actionId: 'warp.update_pair_apply',
        parameters: {
          'mapId': 'alpha',
          'warpId': 'to_beta',
          'reciprocalWarpId': 'to_alpha',
          'warp': const MapWarp(
            id: 'to_beta',
            pos: GridPos(x: 0, y: 1),
            targetMapId: 'beta',
            targetPos: GridPos(x: 1, y: 0),
            triggerMode: MapWarpTriggerMode.onBump,
            allowedApproachFacings: [EntityFacing.north],
          ).toJson(),
        },
      );
      final updated = _projectedMaps(
        const WarpConnectionActions().build(_context(snapshot, update)),
      );

      expect(
          updated['beta']!.warps.single,
          const MapWarp(
            id: 'to_alpha',
            pos: GridPos(x: 1, y: 0),
            targetMapId: 'alpha',
            targetPos: GridPos(x: 0, y: 1),
            triggerMode: MapWarpTriggerMode.onBump,
            allowedApproachFacings: [EntityFacing.south],
          ));

      final updatedSnapshot = _snapshot(updated.values.toList());
      final deletion = _request(
        updatedSnapshot,
        actionId: 'warp.delete_pair_apply',
        parameters: const {
          'mapId': 'alpha',
          'warpId': 'to_beta',
          'reciprocalWarpId': 'to_alpha',
        },
      );
      final deleted = _projectedMaps(
        const WarpConnectionActions().build(
          _context(updatedSnapshot, deletion),
        ),
      );
      expect(deleted['alpha']!.warps, isEmpty);
      expect(deleted['beta']!.warps, isEmpty);
    });

    test('bidirectional update and delete keep inverse offsets coherent', () {
      final source = _map('alpha').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'beta',
          ),
        ],
      );
      final target = _map('beta').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'alpha',
          ),
        ],
      );
      final snapshot = _snapshot([source, target]);
      final update = _request(
        snapshot,
        actionId: 'connection.update_bidirectional_apply',
        parameters: const {
          'mapId': 'alpha',
          'direction': 'east',
          'targetMapId': 'beta',
          'offset': 1,
        },
      );
      final updated = _projectedMaps(
        const WarpConnectionActions().build(_context(snapshot, update)),
      );
      expect(updated['alpha']!.connections.single.offset, 1);
      expect(updated['beta']!.connections.single.offset, -1);

      final updatedSnapshot = _snapshot(updated.values.toList());
      final deletion = _request(
        updatedSnapshot,
        actionId: 'connection.delete_bidirectional_apply',
        parameters: const {'mapId': 'alpha', 'direction': 'east'},
      );
      final deleted = _projectedMaps(
        const WarpConnectionActions().build(
          _context(updatedSnapshot, deletion),
        ),
      );
      expect(deleted['alpha']!.connections, isEmpty);
      expect(deleted['beta']!.connections, isEmpty);
    });

    test('dispatcher exposes canonical warp and connection mutations', () {
      final ids = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id)
          .toSet();
      expect(
        ids,
        containsAll({
          'warp.create',
          'warp.update',
          'warp.delete',
          'warp.create_reciprocal_apply',
          'warp.update_pair_apply',
          'warp.delete_pair_apply',
          'connection.upsert',
          'connection.delete',
          'connection.create_bidirectional_apply',
          'connection.update_bidirectional_apply',
          'connection.delete_bidirectional_apply',
        }),
      );
    });
  });

  group('WorldGraphQueries', () {
    test('is deterministic and keeps disconnected maps explicit', () {
      final alpha = _map('alpha').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.east,
            targetMapId: 'beta',
          ),
        ],
      );
      final beta = _map('beta').copyWith(
        connections: const [
          MapConnection(
            direction: MapConnectionDirection.west,
            targetMapId: 'alpha',
          ),
        ],
        warps: const [
          MapWarp(
            id: 'to_gamma',
            pos: GridPos(x: 1, y: 1),
            targetMapId: 'gamma',
            targetPos: GridPos(x: 0, y: 0),
          ),
        ],
      );
      final snapshot = _snapshot([
        _map('isolated'),
        _map('gamma'),
        beta,
        alpha,
      ]);
      const queries = WorldGraphQueries();

      final first = queries.inspect(snapshot);
      final second = queries.inspect(snapshot);
      expect(second.toJson(), first.toJson());
      expect(first.nodes, ['alpha', 'beta', 'gamma', 'isolated']);
      expect(queries.listConnected(snapshot, fromMapId: 'alpha'),
          ['alpha', 'beta', 'gamma']);
      expect(
          queries.listDisconnected(snapshot, fromMapId: 'alpha'), ['isolated']);
      expect(
          queries.findPath(
            snapshot,
            sourceMapId: 'alpha',
            targetMapId: 'gamma',
          ),
          ['alpha', 'beta', 'gamma']);
      expect(queries.validateConsistency(snapshot), isEmpty);

      final renderModel = queries.render(snapshot).toJson();
      expect(renderModel['hasPersistentLayout'], isFalse);
      expect(renderModel.containsKey('worldLayout'), isFalse);
    });
  });

  test('map render requests require a revision-bound map resource', () {
    final map = _map('alpha');
    final snapshot = _snapshot([map]);
    final revision = snapshot.resourceFingerprints['map:alpha']!;
    final request = MapRenderRequest(
      mapResource: AuthoringResourceRef(
        kind: 'map',
        id: 'alpha',
        revision: revision,
      ),
      manifest: snapshot.manifest,
      map: map,
      region: const MapRect(
        pos: GridPos(x: 0, y: 0),
        size: GridSize(width: 2, height: 2),
      ),
      overlays: const {
        MapRenderOverlay.collision,
        MapRenderOverlay.zones,
        MapRenderOverlay.warps,
        MapRenderOverlay.entities,
      },
    );

    expect(request.revision, revision);
    expect(request.region.size, const GridSize(width: 2, height: 2));
    expect(
      () => MapRenderRequest(
        mapResource: AuthoringResourceRef(kind: 'map', id: 'alpha'),
        manifest: snapshot.manifest,
        map: map,
      ),
      throwsArgumentError,
    );
  });

  test('map render queries bind the exact snapshot revision and region',
      () async {
    final map = _map('alpha');
    final snapshot = _snapshot([map]);
    final port = _RecordingMapRenderPort();
    final result = await MapRenderQueries(port).renderRegion(
      snapshot: snapshot,
      mapId: 'alpha',
      region: const MapRect(
        pos: GridPos(x: 1, y: 0),
        size: GridSize(width: 2, height: 1),
      ),
      layerIds: const ['base'],
      overlays: const [MapRenderOverlay.warps],
      cellPixelSize: 3,
    );

    expect(
      port.request!.revision,
      snapshot.resourceFingerprints['map:alpha'],
    );
    expect(port.request!.region.pos, const GridPos(x: 1, y: 0));
    expect(result.sourceRevision, port.request!.revision);
  });

  test('map render queries reject a stale adapter result', () async {
    final map = _map('alpha');
    final snapshot = _snapshot([map]);
    final port = _RecordingMapRenderPort(sourceRevision: _fakeRevision('f'));

    await expectLater(
      () => MapRenderQueries(port).renderMap(
        snapshot: snapshot,
        mapId: 'alpha',
      ),
      throwsA(
        isA<ProjectSnapshotException>().having(
          (error) => error.code,
          'code',
          'map.render_revision_mismatch',
        ),
      ),
    );
  });
}

final class _RecordingMapRenderPort implements MapRenderPort {
  _RecordingMapRenderPort({this.sourceRevision});

  final String? sourceRevision;
  MapRenderRequest? request;

  @override
  Future<MapRenderResult> render(MapRenderRequest request) async {
    this.request = request;
    return MapRenderResult(
      mimeType: 'image/png',
      bytes: const [1],
      width: request.region.size.width * request.cellPixelSize,
      height: request.region.size.height * request.cellPixelSize,
      sourceRevision: sourceRevision ?? request.revision,
      region: request.region,
      layerIds: request.layerIds,
      overlays: request.overlays,
    );
  }
}

Future<void> _proveRecovery(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) async {
  final directory = await Directory.systemTemp.createTemp('pmcp_035_pair_');
  addTearDown(() => directory.delete(recursive: true));
  final mapsDirectory = await Directory(
    '${directory.path}${Platform.pathSeparator}maps',
  ).create();
  for (final map in snapshot.maps) {
    await File('${mapsDirectory.path}${Platform.pathSeparator}${map.id}.json')
        .writeAsBytes(snapshot.resourceBytes('map:${map.id}'));
  }

  final now = DateTime.utc(2026, 7, 31, 15);
  var token = 0;
  final store = AuthoringPlanStore(clock: () => now);
  final plan = await AuthoringActionPlanner(
    store: store,
    tokenFactory: (prefix) => '$prefix${token++}',
    seedFactory: () => 35,
  ).plan(
    request: request,
    snapshot: snapshot,
    build: const WarpConnectionActions().build,
  );
  final gateway = await LocalTransactionFileGateway.open(
    projectRoot: directory.path,
  );
  final ledgerPath = [
    directory.path,
    '.pokemap',
    'authoring',
    'idempotency.jsonl',
  ].join(Platform.pathSeparator);
  final scope = AuthoringIdempotencyScope(
    actorId: 'pmcp-035',
    projectId: 'pair-project',
    actionId: request.actionId,
    actionVersion: request.actionVersion,
    key: request.idempotencyKey!,
  );
  var crashed = false;
  final transaction = JournaledAuthoringTransaction(
    plans: store,
    gateway: gateway,
    idempotency: AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(filePath: ledgerPath),
      clock: () => now,
    ),
    clock: () => now,
    faultInjector: (context) {
      if (!crashed &&
          context.checkpoint ==
              AuthoringTransactionCheckpoint.afterResourcePromoted &&
          context.promotionIndex == 0) {
        crashed = true;
        throw const AuthoringTransactionSimulatedCrash();
      }
    },
  );

  await expectLater(
    () => transaction.apply(
      planId: plan.planId,
      request: request,
      currentProjectRevision: snapshot.revision,
      scope: scope,
      operationId: 'operation-pmcp-035',
    ),
    throwsA(isA<AuthoringTransactionSimulatedCrash>()),
  );

  final alphaAfterCrash = await _readMap(directory, 'alpha');
  final betaAfterCrash = await _readMap(directory, 'beta');
  expect(alphaAfterCrash.warps, hasLength(1));
  expect(betaAfterCrash.warps, isEmpty);

  final recovery = AuthoringRecoveryService(
    gateway: await LocalTransactionFileGateway.open(
      projectRoot: directory.path,
    ),
    idempotency: AuthoringIdempotencyLedger(
      store: FileIdempotencyStore(filePath: ledgerPath),
      clock: () => now,
    ),
    clock: () => now,
  );
  final receipt = await recovery.resume('operation-pmcp-035');
  expect(receipt.status, AuthoringReceiptStatus.recovered);
  expect((await _readMap(directory, 'alpha')).warps.single.id, 'to_beta');
  expect((await _readMap(directory, 'beta')).warps.single.id, 'to_alpha');
}

Future<MapData> _readMap(Directory root, String id) async {
  final bytes = await File([
    root.path,
    'maps',
    '$id.json',
  ].join(Platform.pathSeparator))
      .readAsBytes();
  return MapData.fromJson(
    jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>,
  );
}

Map<String, MapData> _projectedMaps(AuthoringMutationDraft draft) => {
      for (final change in draft.changeSet.changes)
        change.resource.id: MapData.fromJson(
          jsonDecode(utf8.decode(change.afterBytes!)) as Map<String, dynamic>,
        ),
    };

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot,
  AuthoringRequest request,
) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: request,
      planId: 'plan-pmcp-035',
      seed: 35,
    );

AuthoringRequest _request(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringRequest(
      requestId: 'request-$actionId',
      actionId: actionId,
      actionVersion: 1,
      workspaceHandle: 'workspace:pmcp-035',
      parameters: parameters,
      expectedRevision: snapshot.revision,
      idempotencyKey: 'idempotency-$actionId',
    );

ProjectSnapshot _snapshot(List<MapData> maps) {
  final entries = [
    for (final map in maps)
      ProjectMapEntry(
        id: map.id,
        name: map.name,
        relativePath: 'maps/${map.id}.json',
      ),
  ];
  final manifest = ProjectManifest(
    name: 'PMCP-035',
    maps: entries,
    tilesets: const [],
  );
  final bytes = <String, List<int>>{
    'project': utf8.encode(jsonEncode(manifest.toJson())),
    for (final map in maps) 'map:${map.id}': encodeMapAuthoringDocument(map),
  };
  final fingerprints = <String, String>{
    'project': computeAuthoringBytesFingerprint(
      bytes['project']!,
      logicalName: 'project.json',
    ),
    for (final map in maps)
      'map:${map.id}': computeAuthoringBytesFingerprint(
        bytes['map:${map.id}']!,
        logicalName: 'maps/${map.id}.json',
      ),
  };
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('project:pmcp-035'),
    revision: computeAuthoringJsonFingerprint(
      fingerprints,
      logicalName: 'pmcp-035-snapshot.json',
    ),
    manifest: manifest,
    maps: maps,
    resourceFingerprints: fingerprints,
    resourceBytes: bytes,
  );
}

MapData _map(
  String id, {
  int width = 4,
  int height = 3,
}) =>
    MapData(
      id: id,
      name: id,
      size: GridSize(width: width, height: height),
      layers: [
        MapLayer.tile(
          id: 'base',
          name: 'Base',
          tiles: List<int>.filled(width * height, 0),
        ),
      ],
    );

String _fakeRevision(String digit) =>
    'sha256:${List<String>.filled(64, digit).join()}';
```

## `packages/map_runtime/lib/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart`

```dart
import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';

/// Runtime-owned deterministic raster adapter for authoring map previews.
///
/// It deliberately renders from immutable typed data and never receives a
/// project path. Production asset-accurate screenshots can replace this
/// adapter without changing the revision-bound authoring port.
final class RuntimeAuthoringMapRenderAdapter implements MapRenderPort {
  const RuntimeAuthoringMapRenderAdapter();

  @override
  Future<MapRenderResult> render(MapRenderRequest request) async {
    final scale = request.cellPixelSize;
    final bitmap = img.Image(
      width: request.region.size.width * scale,
      height: request.region.size.height * scale,
      numChannels: 4,
    );
    _paintBackground(bitmap, request);
    final layers = _selectedLayers(request);
    for (final layer in layers) {
      _paintLayer(bitmap, request, layer);
    }
    final overlayCounts = <MapRenderOverlay, int>{};
    for (final overlay in request.overlays) {
      overlayCounts[overlay] = switch (overlay) {
        MapRenderOverlay.collision => _paintCollisionOverlay(bitmap, request),
        MapRenderOverlay.zones => _paintZoneOverlay(bitmap, request),
        MapRenderOverlay.warps => _paintWarpOverlay(bitmap, request),
        MapRenderOverlay.entities => _paintEntityOverlay(bitmap, request),
      };
    }
    return MapRenderResult(
      mimeType: 'image/png',
      bytes: img.encodePng(bitmap, level: 6),
      width: bitmap.width,
      height: bitmap.height,
      sourceRevision: request.revision,
      region: request.region,
      layerIds: [for (final layer in layers) layer.id],
      overlays: request.overlays,
      overlayCounts: overlayCounts,
    );
  }
}

List<MapLayer> _selectedLayers(MapRenderRequest request) {
  final selected = request.layerIds.toSet();
  final layers = request.map.layers.where(
    (layer) => selected.isEmpty ? layer.isVisible : selected.contains(layer.id),
  );
  return layers.toList(growable: false);
}

void _paintBackground(img.Image bitmap, MapRenderRequest request) {
  for (var y = 0; y < request.region.size.height; y++) {
    for (var x = 0; x < request.region.size.width; x++) {
      final even = (x + y).isEven;
      _paintCell(
        bitmap,
        request,
        request.region.pos.x + x,
        request.region.pos.y + y,
        even ? const (27, 32, 43, 255) : const (31, 37, 49, 255),
      );
    }
  }
}

void _paintLayer(
  img.Image bitmap,
  MapRenderRequest request,
  MapLayer layer,
) {
  for (var y = request.region.pos.y;
      y < request.region.pos.y + request.region.size.height;
      y++) {
    for (var x = request.region.pos.x;
        x < request.region.pos.x + request.region.size.width;
        x++) {
      final value = _layerCellValue(request.map, layer, x, y);
      if (value == 0) continue;
      final base = _layerColor(layer, value);
      final alpha = (base.$4 * layer.opacity.clamp(0.0, 1.0)).round();
      _paintCell(
        bitmap,
        request,
        x,
        y,
        (base.$1, base.$2, base.$3, alpha),
      );
    }
  }
}

int _layerCellValue(MapData map, MapLayer layer, int x, int y) {
  final index = y * map.size.width + x;
  return switch (layer) {
    TileLayer value => _intCell(value.tiles, index),
    CollisionLayer value => _boolCell(value.collisions, index) ? 1 : 0,
    TerrainLayer value =>
      index < value.terrains.length ? value.terrains[index].index : 0,
    PathLayer value => _boolCell(value.cells, index) ? 1 : 0,
    SurfaceLayer value => value.placements.any(
        (placement) => placement.x == x && placement.y == y,
      )
          ? 1
          : 0,
    SmartTileLayer value => _intCell(value.materialCells, index),
    ObjectLayer _ => 0,
    EnvironmentLayer _ => 0,
    BorderLayer _ => 0,
  };
}

(int, int, int, int) _layerColor(MapLayer layer, int value) {
  final int variation =
      (value.abs() * 37 + layer.id.codeUnits.fold<int>(0, (a, b) => a + b)) %
          72;
  return switch (layer) {
    TileLayer _ => (58 + variation, 100 + variation ~/ 2, 72, 230),
    CollisionLayer _ => (180, 52, 64, 120),
    TerrainLayer _ => (58, 118 + variation, 74, 170),
    PathLayer _ => (148 + variation, 112, 72, 190),
    SurfaceLayer _ => (48, 108 + variation, 154, 190),
    SmartTileLayer _ => (72, 138 + variation, 118, 200),
    ObjectLayer _ => (116, 116, 136, 160),
    EnvironmentLayer _ => (68, 136, 100, 140),
    BorderLayer _ => (128, 96, 68, 180),
  };
}

int _paintCollisionOverlay(img.Image bitmap, MapRenderRequest request) {
  final collision = const EffectiveCollisionInspector().queryRegion(
    manifest: request.manifest,
    map: request.map,
    x: request.region.pos.x,
    y: request.region.pos.y,
    width: request.region.size.width,
    height: request.region.size.height,
  );
  var count = 0;
  for (final cell in collision.cells) {
    if (!cell.isBlocked) continue;
    count++;
    _paintMarker(
      bitmap,
      request,
      cell.pos.x,
      cell.pos.y,
      const (225, 56, 68, 220),
    );
  }
  return count;
}

int _paintZoneOverlay(img.Image bitmap, MapRenderRequest request) {
  var count = 0;
  for (final zone in request.map.gameplayZones) {
    if (!_rectsIntersect(zone.area, request.region)) continue;
    count++;
    final left = zone.area.pos.x.clamp(
      request.region.pos.x,
      request.region.pos.x + request.region.size.width,
    );
    final top = zone.area.pos.y.clamp(
      request.region.pos.y,
      request.region.pos.y + request.region.size.height,
    );
    final right = (zone.area.pos.x + zone.area.size.width).clamp(
      request.region.pos.x,
      request.region.pos.x + request.region.size.width,
    );
    final bottom = (zone.area.pos.y + zone.area.size.height).clamp(
      request.region.pos.y,
      request.region.pos.y + request.region.size.height,
    );
    for (var y = top; y < bottom; y++) {
      for (var x = left; x < right; x++) {
        _paintMarker(
          bitmap,
          request,
          x,
          y,
          const (244, 181, 48, 210),
        );
      }
    }
  }
  return count;
}

int _paintWarpOverlay(img.Image bitmap, MapRenderRequest request) {
  var count = 0;
  for (final warp in request.map.warps) {
    if (!_contains(request.region, warp.pos)) continue;
    count++;
    _paintMarker(
      bitmap,
      request,
      warp.pos.x,
      warp.pos.y,
      const (204, 70, 214, 245),
    );
  }
  return count;
}

int _paintEntityOverlay(img.Image bitmap, MapRenderRequest request) {
  var count = 0;
  for (final entity in request.map.entities) {
    final area = MapRect(pos: entity.pos, size: entity.size);
    if (!_rectsIntersect(area, request.region)) continue;
    count++;
    for (var y = entity.pos.y; y < entity.pos.y + entity.size.height; y++) {
      for (var x = entity.pos.x; x < entity.pos.x + entity.size.width; x++) {
        if (!_contains(request.region, GridPos(x: x, y: y))) continue;
        _paintMarker(
          bitmap,
          request,
          x,
          y,
          const (44, 196, 214, 245),
        );
      }
    }
  }
  return count;
}

void _paintMarker(
  img.Image bitmap,
  MapRenderRequest request,
  int mapX,
  int mapY,
  (int, int, int, int) color,
) {
  final inset = request.cellPixelSize >= 4 ? 1 : 0;
  _paintCell(
    bitmap,
    request,
    mapX,
    mapY,
    color,
    inset: inset,
  );
}

void _paintCell(
  img.Image bitmap,
  MapRenderRequest request,
  int mapX,
  int mapY,
  (int, int, int, int) color, {
  int inset = 0,
}) {
  if (!_contains(request.region, GridPos(x: mapX, y: mapY))) return;
  final left = (mapX - request.region.pos.x) * request.cellPixelSize + inset;
  final top = (mapY - request.region.pos.y) * request.cellPixelSize + inset;
  final right =
      (mapX - request.region.pos.x + 1) * request.cellPixelSize - inset;
  final bottom =
      (mapY - request.region.pos.y + 1) * request.cellPixelSize - inset;
  for (var y = top; y < bottom; y++) {
    for (var x = left; x < right; x++) {
      _blendPixel(bitmap, x, y, color);
    }
  }
}

void _blendPixel(
  img.Image bitmap,
  int x,
  int y,
  (int, int, int, int) color,
) {
  final alpha = color.$4 / 255.0;
  final previous = bitmap.getPixel(x, y);
  final red = (color.$1 * alpha + previous.r * (1 - alpha)).round();
  final green = (color.$2 * alpha + previous.g * (1 - alpha)).round();
  final blue = (color.$3 * alpha + previous.b * (1 - alpha)).round();
  bitmap.setPixelRgba(x, y, red, green, blue, 255);
}

bool _contains(MapRect rect, GridPos pos) =>
    pos.x >= rect.pos.x &&
    pos.y >= rect.pos.y &&
    pos.x < rect.pos.x + rect.size.width &&
    pos.y < rect.pos.y + rect.size.height;

bool _rectsIntersect(MapRect left, MapRect right) =>
    left.pos.x < right.pos.x + right.size.width &&
    right.pos.x < left.pos.x + left.size.width &&
    left.pos.y < right.pos.y + right.size.height &&
    right.pos.y < left.pos.y + left.size.height;

int _intCell(List<int> values, int index) =>
    index >= 0 && index < values.length ? values[index] : 0;

bool _boolCell(List<bool> values, int index) =>
    index >= 0 && index < values.length && values[index];
```

## `packages/map_runtime/test/application/authoring_preview/runtime_authoring_map_render_adapter_test.dart`

```dart
import 'dart:typed_data';

import 'package:image/image.dart' as img;
import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/authoring_preview/runtime_authoring_map_render_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('renders revision-bound collision, zone, warp and entity overlays',
      () async {
    final fixture = _fixture();
    final result = await const RuntimeAuthoringMapRenderAdapter().render(
      MapRenderRequest(
        mapResource: AuthoringResourceRef(
          kind: 'map',
          id: fixture.map.id,
          revision: _revision('a'),
        ),
        manifest: fixture.manifest,
        map: fixture.map,
        layerIds: const ['base'],
        overlays: const {
          MapRenderOverlay.collision,
          MapRenderOverlay.zones,
          MapRenderOverlay.warps,
          MapRenderOverlay.entities,
        },
        cellPixelSize: 4,
      ),
    );

    expect(result.mimeType, 'image/png');
    expect(result.sourceRevision, _revision('a'));
    expect(result.width, 12);
    expect(result.height, 8);
    expect(result.bytes.take(8), [137, 80, 78, 71, 13, 10, 26, 10]);
    expect(result.overlayCounts, {
      MapRenderOverlay.collision: 1,
      MapRenderOverlay.zones: 1,
      MapRenderOverlay.warps: 1,
      MapRenderOverlay.entities: 1,
    });

    final bitmap = img.decodePng(Uint8List.fromList(result.bytes))!;
    final collision = bitmap.getPixel(2, 2);
    final zone = bitmap.getPixel(6, 2);
    final warp = bitmap.getPixel(10, 2);
    final entity = bitmap.getPixel(2, 6);
    expect(_rgba(collision), isNot(_rgba(zone)));
    expect(_rgba(zone), isNot(_rgba(warp)));
    expect(_rgba(warp), isNot(_rgba(entity)));
  });

  test('renders only the requested region and counts visible overlays',
      () async {
    final fixture = _fixture();
    final result = await const RuntimeAuthoringMapRenderAdapter().render(
      MapRenderRequest(
        mapResource: AuthoringResourceRef(
          kind: 'map',
          id: fixture.map.id,
          revision: _revision('b'),
        ),
        manifest: fixture.manifest,
        map: fixture.map,
        region: const MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 2, height: 1),
        ),
        overlays: const {
          MapRenderOverlay.collision,
          MapRenderOverlay.zones,
          MapRenderOverlay.warps,
          MapRenderOverlay.entities,
        },
        cellPixelSize: 4,
      ),
    );

    expect(result.width, 8);
    expect(result.height, 4);
    expect(result.region.pos, const GridPos(x: 1, y: 0));
    expect(result.overlayCounts, {
      MapRenderOverlay.collision: 0,
      MapRenderOverlay.zones: 1,
      MapRenderOverlay.warps: 1,
      MapRenderOverlay.entities: 0,
    });
  });
}

({ProjectManifest manifest, MapData map}) _fixture() {
  const map = MapData(
    id: 'preview',
    name: 'Preview',
    size: GridSize(width: 3, height: 2),
    layers: [
      TileLayer(
        id: 'base',
        name: 'Base',
        tiles: [1, 2, 3, 4, 5, 6],
      ),
      CollisionLayer(
        id: 'collision',
        name: 'Collision',
        collisions: [true, false, false, false, false, false],
      ),
    ],
    entities: [
      MapEntity(
        id: 'npc',
        kind: MapEntityKind.custom,
        pos: GridPos(x: 0, y: 1),
        blocksMovement: false,
      ),
    ],
    warps: [
      MapWarp(
        id: 'door',
        pos: GridPos(x: 2, y: 0),
        targetMapId: 'preview',
        targetPos: GridPos(x: 0, y: 0),
      ),
    ],
    gameplayZones: [
      MapGameplayZone(
        id: 'zone',
        kind: GameplayZoneKind.custom,
        area: MapRect(
          pos: GridPos(x: 1, y: 0),
          size: GridSize(width: 1, height: 1),
        ),
        special: SpecialZonePayload(),
      ),
    ],
  );
  const manifest = ProjectManifest(
    name: 'Runtime preview',
    maps: [
      ProjectMapEntry(
        id: 'preview',
        name: 'Preview',
        relativePath: 'maps/preview.json',
      ),
    ],
    tilesets: [],
  );
  return (manifest: manifest, map: map);
}

String _revision(String digit) => 'sha256:${List.filled(64, digit).join()}';

List<num> _rgba(img.Pixel pixel) => [pixel.r, pixel.g, pixel.b, pixel.a];
```
