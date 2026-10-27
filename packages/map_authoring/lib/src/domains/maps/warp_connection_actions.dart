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
      ('warp.transition.configure', 'Configure the native screen transition of one warp', AuthoringRiskLevel.low),
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

  MapData previewCreate(MapData map, {required Map<String, Object?> warp}) =>
      _addWarp(map, _parseWarp(map, warp));

  MapData previewConnection(MapData map, {required String direction,
      required String targetMapId, required int offset}) =>
      _upsertConnectionOnMap(map, MapConnection(direction: _direction(direction),
          targetMapId: targetMapId, offset: offset));

  MapData previewUpdate(MapData map, {required String warpId,
      required Map<String, Object?> warp}) =>
      _replaceWarp(map, warpId, _parseWarp(map, warp));

  List<MapWarp> listWarps(MapData map) => List.unmodifiable(
        map.warps.toList()..sort((left, right) => left.id.compareTo(right.id)),
      );

  MapWarp getWarp(MapData map, String warpId) => _warp(map, warpId);

  List<MapConnection> listConnections(MapData map) => List.unmodifiable(
        map.connections.toList()
          ..sort((left, right) =>
              left.direction.index.compareTo(right.direction.index)),
      );

  MapConnection getConnection(MapData map, MapConnectionDirection direction,
          {String? targetMapId}) =>
      _connection(map, direction, targetMapId: targetMapId);

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
        if (warp.triggerMode == MapWarpTriggerMode.sceneOnly) continue;
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
      'warp.transition.configure' => const {'warpId', 'transition'},
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
          'targetMapId',
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
        final warp = _parseWarp(context.map, parameters.object('warp'));
        _validateWarpTarget(planning, context.map, warp);
        final after = _addWarp(context.map, warp);
        validateMapWarpDoor(after, warp, models: planning.snapshot.manifest.models3d);
        return _draftRelation(
          planning: planning, before: context.map, after: after,
          operation: 'warp.create',
          preview: {'warpId': warp.id, 'targetMapId': warp.targetMapId},
        );
      case 'warp.update':
        final warpId = parameters.string('warpId');
        final after = previewUpdate(context.map, warpId: warpId, warp: parameters.object('warp'));
        final warp = after.warps[context.map.warps.indexWhere((entry) => entry.id == warpId)];
        _validateWarpTarget(planning, context.map, warp);
        return context.draftWarpUpdate(
          after: after,
          warpId: warpId,
          changedItems: 1,
          preview: {'warpId': warp.id, 'targetMapId': warp.targetMapId},
        );
      case 'warp.transition.configure':
        final warpId = parameters.string('warpId');
        final current = _warp(context.map, warpId);
        if (current.triggerMode == MapWarpTriggerMode.sceneOnly) {
          throw _failure('warp.transition_requires_active_warp',
              'A passive scene arrival does not own an automatic screen transition.');
        }
        final MapWarpTransition transition;
        try {
          transition = MapWarpTransition.fromJson(
              Map<String, dynamic>.from(parameters.object('transition')));
        } on Object {
          throw _failure('warp.transition_invalid',
              'Choose a valid native transition and a duration greater than zero and at most five seconds.');
        }
        return context.draftMap(
          after: updateWarpOnMap(context.map, warpId: current.id, transition: transition),
          operation: 'warp.transition.configure',
          changedItems: 1,
          preview: {'warpId': current.id, 'transition': transition.toJson()},
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
          after: _removeConnection(context.map, direction,
              targetMapId: parameters.optionalString('targetMapId')),
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
    final sourceWarp =
        _parseWarp(context.map, context.parameters.object('warp'));
    _requireActivePairWarp(sourceWarp);
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
    _requireActivePairWarp(current);
    final updated = _parseWarp(context.map, context.parameters.object('warp'));
    _requireActivePairWarp(updated);
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
      ).copyWith(door: reciprocal.door, transition: reciprocal.transition),
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
    _requireActivePairWarp(sourceWarp);
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
    _requireFreeSpan(planning.snapshot, context.map, connection);
    return _draftRelation(
      planning: planning, before: context.map,
      after: _upsertConnectionOnMap(context.map, connection),
      operation: 'connection.upsert',
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
      targetMapId: target.id,
    );
    final targetExisting = findMapConnection(
      target,
      targetConnection.direction,
      targetMapId: context.map.id,
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
    _requireFreeSpan(planning.snapshot, context.map, sourceConnection);
    _requireFreeSpan(planning.snapshot, target, targetConnection);
    return _draftPair(
      planning: planning,
      sourceBefore: context.map,
      sourceAfter: _upsertConnectionOnMap(context.map, sourceConnection),
      targetBefore: target,
      targetAfter: _upsertConnectionOnMap(target, targetConnection),
      validateMaps: !createOnly,
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
    final sourceConnection = _connection(context.map, direction,
        targetMapId: context.parameters.optionalString('targetMapId'));
    final target = _targetMap(
      planning,
      sourceConnection.targetMapId,
      kind: 'connection',
    );
    _requireDistinctMaps(context.map, target, kind: 'connection');
    final targetConnection = findMapConnection(target, direction.opposite,
        targetMapId: context.map.id);
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
      sourceAfter:
          _removeConnection(context.map, direction, targetMapId: target.id),
      targetBefore: target,
      targetAfter: _removeConnection(target, direction.opposite,
          targetMapId: context.map.id),
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
      extensions: {
        'multiFileGuarantee': 'recoverable',
        if (id.startsWith('warp.'))
          'screenTransition': const {
            'field': 'transition',
            'types': ['fade', 'hgss', 'none'],
            'default': {'type': 'fade', 'durationSeconds': .2},
            'durationMeaning': 'perFadePhase',
            'durationIgnoredFor': 'none',
            'doorBindingIndependent': true,
            'sceneOnly': 'unsupported',
            'sceneOrCinematicRequired': false,
          },
        if (id == 'warp.transition.configure')
          'inputSchema': const {
            'type': 'object',
            'additionalProperties': false,
            'required': ['mapId', 'warpId', 'transition'],
            'properties': {
              'mapId': {'type': 'string', 'minLength': 1},
              'warpId': {'type': 'string', 'minLength': 1},
              'transition': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['type', 'durationSeconds'],
                'properties': {
                  'type': {'type': 'string', 'enum': ['fade', 'hgss', 'none']},
                  'durationSeconds': {'type': 'number', 'exclusiveMinimum': 0, 'maximum': 5},
                },
              },
            },
          },
        if (id.startsWith('connection.'))
          'connectionIdentity': const {
            'fields': ['direction', 'targetMapId'],
            'multipleNeighbors': 'nonOverlapping2d',
            'ambiguousDirectionOnly': 'rejected'
          },
        if (id.startsWith('warp.'))
          'nativeDoor': const {
            'field': 'door',
            'projectDimension': 'threeD',
            'required': [
              'instanceId',
              'openAnimationIndex',
              'closeAnimationIndex',
              'exitPos'
            ],
            'properties': {
              'instanceId': {'type': 'string', 'minLength': 1},
              'openAnimationIndex': {'type': 'integer', 'minimum': 0},
              'closeAnimationIndex': {'type': 'integer', 'minimum': 0},
              'exitPos': {
                'type': 'object',
                'required': ['x', 'y'],
                'properties': {
                  'x': {'type': 'integer', 'minimum': 0},
                  'y': {'type': 'integer', 'minimum': 0}
                }
              },
            },
            'playbackOwner': 'nativeWarpTransition',
            'instanceAnimationIndex': null,
            'entry': 'openThenTransfer',
            'arrival': 'uniqueDoorAtTargetPosThenOpenExitClose',
            'exit': 'adjacentCardinalTraversableCell',
            'sceneOnly': 'unsupported',
            'sceneOrCinematicRequired': false,
          },
        if (id.startsWith('warp.'))
          'warpDestinationContract': const {
            'triggerModeValues': ['on_enter', 'on_bump', 'scene_only'],
            'activeRequiredFields': ['targetMapId', 'targetPos'],
            'sceneOnly': {
              'automaticTraversal': false,
              'reciprocal': false,
              'targetMapId': 'owningMapId',
              'targetPos': 'pos',
              'explicitConflictingTarget': 'rejected',
            },
            'sceneOnlyToActiveRequiresExplicitDestination': true,
          },
      },
    );

AuthoringMutationDraft _draftRelation({
  required AuthoringPlanningContext planning,
  required MapData before,
  required MapData after,
  required String operation,
  required Map<String, Object?> preview,
}) {
  if (before == after) {
    throw _failure('map.no_change', 'The inter-map operation changes nothing.');
  }
  final change = _mapChange(planning, before, after);
  return AuthoringMutationDraft(
    changeSet: AuthoringChangeSet(changes: [change], diff: AuthoringDiff([
      AuthoringDiffEntry(operation: AuthoringDiffOperation.replace,
          resource: change.resource, path: '/maps/${before.id}',
          before: semanticMapSummary(before), after: semanticMapSummary(after)),
    ])),
    preview: {'operation': operation, 'mapId': before.id,
      'changedItemCount': 1, 'seed': planning.seed, ...preview},
  );
}

AuthoringMutationDraft _draftPair({
  required AuthoringPlanningContext planning,
  required MapData sourceBefore,
  required MapData sourceAfter,
  required MapData targetBefore,
  required MapData targetAfter,
  required String operation,
  required String collection,
  required Map<String, Object?> preview,
  bool validateMaps = true,
}) {
  if (validateMaps) {
    _validateProjected(planning, sourceAfter);
    _validateProjected(planning, targetAfter);
  }
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

MapWarp _parseWarp(MapData map, Map<String, Object?> value) {
  const allowed = {
    'id',
    'pos',
    'targetMapId',
    'targetPos',
    'triggerMode',
    'allowedApproachFacings',
    'triggerPadding',
    'door',
    'transition',
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
    final payload = Map<String, dynamic>.from(value);
    if (value['triggerMode'] == 'scene_only') {
      for (final key in ['targetMapId', 'targetPos']) {
        if (value.containsKey(key) && value[key] == null) {
          throw FormatException('Scene-only $key cannot be null');
        }
      }
      payload.putIfAbsent('targetMapId', () => map.id);
      payload.putIfAbsent('targetPos', () => value['pos']);
    }
    final warp = MapWarp.fromJson(payload);
    return createMapWarp(
      map.copyWith(warps: const []),
      id: warp.id,
      pos: warp.pos,
      triggerMode: warp.triggerMode,
      targetMapId: warp.targetMapId,
      targetPos: warp.targetPos,
      allowedApproachFacings: warp.allowedApproachFacings,
      triggerPadding: warp.triggerPadding,
      door: warp.door,
      transition: warp.transition,
    );
  } on Object {
    throw _failure(
      'warp.payload_invalid',
      'The warp payload is not valid typed PokeMap data.',
    );
  }
}

void _requireActivePairWarp(MapWarp warp) {
  if (warp.triggerMode == MapWarpTriggerMode.sceneOnly) {
    throw _failure(
      'warp.scene_only_not_reciprocal',
      'A Scene-only arrival point cannot participate in a reciprocal portal pair.',
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
      door: warp.door,
      transition: warp.transition,
      clearDoor: warp.door == null,
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

MapData _removeConnection(MapData map, MapConnectionDirection direction,
    {String? targetMapId}) {
  try {
    return removeMapConnectionFromMap(map,
        direction: direction, targetMapId: targetMapId);
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

MapConnection _connection(MapData map, MapConnectionDirection direction,
    {String? targetMapId}) {
  MapConnection? connection;
  try {
    connection = findMapConnection(map, direction, targetMapId: targetMapId);
  } on ValidationException {
    throw _failure('connection.ambiguous',
        'Select targetMapId for an ambiguous map edge.');
  }
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
              candidate.triggerMode != MapWarpTriggerMode.sceneOnly &&
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

void _requireFreeSpan(
    ProjectSnapshot snapshot, MapData source, MapConnection connection) {
  final target = snapshot.mapById(connection.targetMapId)!;
  for (final other in source.connections) {
    if (other.direction != connection.direction ||
        other.targetMapId == connection.targetMapId) {
      continue;
    }
    if (source.spatialScene != null) {
      throw _failure('connection.multiple_spatial_neighbors_unsupported',
          'Multiple neighbors on a 3D map edge are unsupported.');
    }
    final otherTarget = snapshot.mapById(other.targetMapId);
    if (otherTarget == null) {
      throw _failure('connection.target_geometry_missing',
          'Every neighbor on this edge requires a known map size.');
    }
    if (mapConnectionSpansOverlap(
        sourceSize: source.size,
        first: connection,
        firstTargetSize: target.size,
        second: other,
        secondTargetSize: otherTarget.size)) {
      throw _failure('connection.edge_overlap',
          'Connected maps cannot overlap on the same edge.');
    }
  }
}
