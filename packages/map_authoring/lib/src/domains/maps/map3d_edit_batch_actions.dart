import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/map_authoring_exception.dart';
import '../../contracts/map_edit_operation.dart';
import '../../support/authoring_fingerprint.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'border_actions.dart';
import 'map3d_edit_projection.dart';
import 'map3d_edit_intents.dart';
import 'map_lifecycle_adapter.dart' show encodeMapAuthoringDocument;
import 'map_validation_diagnostics.dart';
import 'semantic_map_action_support.dart';

final class Map3dEditBatchActions {
  const Map3dEditBatchActions({
    this.encodeMap = encodeMapAuthoringDocument,
    this.inspectIntegrity = inspectSpatialMapIntegrity,
  });

  final List<int> Function(MapData) encodeMap;
  final SpatialMapIntegrityReport Function(
      {required ProjectManifest manifest,
      required MapData map}) inspectIntegrity;

  static const actionId = 'map3d.edit_batch';
  static final descriptor = AuthoringActionDescriptor(
    id: actionId,
    version: 1,
    summary: 'Compose 1 to 64 map edits atomically with final integrity guards',
    inputSchemaId: 'schema.map3d.edit_batch.input.v1',
    outputSchemaId: 'schema.map.semantic_mutation.output.v1',
    riskLevel: AuthoringRiskLevel.low,
    resourceKinds: const ['map'],
    requiredPermissions: const [AuthoringPermission.projectWrite],
    guarantees: const [
      AuthoringGuarantee.dryRun,
      AuthoringGuarantee.idempotent,
      AuthoringGuarantee.revisionChecked,
      AuthoringGuarantee.undoable,
      AuthoringGuarantee.atomic,
    ],
    extensions: {
      'maximumOperationCount': 64,
      'admittedActions': Map3dEditProjection.admittedActions.toList()..sort(),
      'admittedIntents': mapEditIntentActionIds.toList()..sort(),
      'intentContracts': mapEditIntentContracts(),
      'materialNameSelector': {
        'scope': 'smart_tile operations inside edit_batch only',
        'field': 'material',
        'schema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['name'],
          'properties': {
            'name': {'type': 'string', 'minLength': 1}
          }
        },
        'resolution':
            'normalized exact ID, label or preset default; ambiguity refuses without writes'
      },
      'maximumExpandedOperationCount': 64,
      'batchAtomicity': 'all_or_nothing',
      'undoBoundary': 'batch',
      'defaultSeed': 0,
      'defaultGuards': MapEditOperation.defaultGuards,
      'inputExample': {
        'mapId': 'field',
        'operations': [
          {
            'actionId': 'smart_tile.cell.paint',
            'actionVersion': 1,
            'parameters': {
              'layerId': 'ground',
              'materialId': 'grass',
              'cells': [
                {'x': 1, 'y': 1}
              ]
            }
          }
        ]
      },
      'inputSchema': {
        'type': 'object',
        'additionalProperties': false,
        'required': ['mapId', 'operations'],
        'properties': {
          'mapId': {'type': 'string', 'minLength': 1},
          'seed': {
            'type': 'integer',
            'minimum': 0,
            'maximum': 2147483647,
            'default': 0
          },
          'operations': {
            'type': 'array',
            'minItems': 1,
            'maxItems': 64,
            'items': {
              'type': 'object',
              'additionalProperties': false,
              'required': ['actionId', 'actionVersion', 'parameters'],
              'properties': {
                'actionId': {
                  'type': 'string',
                  'enum': {
                    ...Map3dEditProjection.admittedActions,
                    ...mapEditIntentActionIds
                  }.toList()
                    ..sort()
                },
                'actionVersion': {'type': 'integer', 'const': 1},
                'parameters': {'type': 'object'},
              }
            }
          },
          'guards': {
            'type': 'object',
            'additionalProperties': false,
            'properties': {
              for (final entry in MapEditOperation.defaultGuards.entries)
                entry.key: {
                  'type': 'string',
                  'default': entry.value,
                  'enum': entry.key == 'staleBorders'
                      ? ['rematerialize', 'refuse', 'report']
                      : ['refuse', 'report']
                }
            }
          },
        }
      },
    },
  );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(planning,
        allowedParameters: {'operations', 'guards', 'seed'});
    if (context.map.spatialScene == null ||
        context.manifest.settings.dimension != ProjectDimension.threeD) {
      throw semanticFailure('map3d.dimension_required',
          'Atomic 3D edits require a spatial map and 3D project.');
    }
    final MapEditOperation request;
    try {
      request = MapEditOperation(
        operationId: 'batch',
        mapId: context.map.id,
        operations: context.parameters.list('operations').map((value) {
          if (value is! Map) {
            throw const FormatException('Each operation must be an object.');
          }
          return Map<String, Object?>.from(value);
        }),
        seed: context.parameters.optionalInteger('seed') ?? 0,
        guards: context.parameters.contains('guards')
            ? context.parameters.object('guards')
            : const {},
      );
    } on FormatException catch (error) {
      throw semanticFailure('map3d.edit_batch.request_invalid', error.message);
    }
    var map = context.map;
    final operations = <Map<String, Object?>>[];
    final materializations = <(String, String), Map<String, Object?>>{};
    var expandedCount = 0, intentIntegrityInspections = 0;
    for (final (index, operation) in request.operations.indexed) {
      try {
        if (operation['actionId'] == 'intent.border.clear_over_object') {
          intentIntegrityInspections++;
        }
        final expanded = expandMapEditIntent(
            manifest: context.manifest, map: map, operation: operation);
        expandedCount += expanded.length;
        if (expandedCount > 64) {
          throw semanticFailure('map3d.edit_batch.expansion_limit',
              'The atomic edit expands beyond 64 semantic operations.',
              details: {'maximumExpandedOperationCount': 64});
        }
        final beforeOperation = map;
        var changedItems = 0, deferredCount = 0;
        for (final (subindex, suboperation) in expanded.indexed) {
          final projected = const Map3dEditProjection().project(
              planning: planning,
              map: map,
              operation: suboperation,
              operationIndex: index * 64 + subindex,
              seed: request.seed);
          final deferred = projected.preview['deferredMaterializationTargets'];
          if (deferred is List) {
            deferredCount += deferred.length;
            for (final target in deferred.whereType<Map>()) {
              materializations[(
                target['layerId'] as String,
                target['featureId'] as String
              )] = Map<String, Object?>.from(target);
            }
          }
          if (projected.map != map) changedItems += projected.changedItems;
          map = projected.map;
        }
        operations.add({
          'index': index,
          'actionId': operation['actionId'],
          'status': map != beforeOperation
              ? 'changed'
              : deferredCount > 0
                  ? 'deferred'
                  : 'unchanged',
          'changedItems': changedItems,
          'expandedOperationCount': expanded.length,
          if(mapEditIntentActionIds.contains(operation['actionId'])||
              requestedMapEditMaterialNames(operation).isNotEmpty)
            'resolvedOperations':expanded,
        });
      } on MapAuthoringException catch (error) {
        throw semanticFailure('map3d.edit_batch.operation_failed',
            'An operation failed; the entire atomic map edit was rejected.',
            details: {
              'operationIndex': index,
              'actionId': operation['actionId'],
              'cause': {
                'code': error.code,
                'message': error.message,
                'details': error.details
              }
            });
      } on ValidationException catch (error) {
        throw semanticFailure('map3d.edit_batch.operation_failed',
            'An operation failed; the entire atomic map edit was rejected.',
            details: {
              'operationIndex': index,
              'actionId': operation['actionId'],
              'cause': {
                'code': error.code ?? 'map.validation_failed',
                'message': error.message,
                'details': error.details
              }
            });
      } on FormatException catch (error) {
        throw semanticFailure('map3d.edit_batch.operation_failed',
            'An operation has invalid fields.',
            details: {
              'operationIndex': index,
              'actionId': operation['actionId'],
              'cause': {'code': 'map.request_invalid', 'message': error.message}
            });
      }
    }
    final touched = {
      ..._touchedFeatures(context.map, map),
      ...materializations.keys
    };
    final rematerialized = <Map<String, Object?>>[];
    final beforeDiagnostics =
        _diagnostics(context.manifest, context.map, touched);
    {
      for (final key in touched) {
        final materialization = materializations[key];
        if (request.guards['staleBorders'] != 'rematerialize' &&
            materialization == null) {
          continue;
        }
        final feature = _feature(map, key);
        if (feature == null) continue;
        final diagnostics = _diagnostics(context.manifest, map, [key]);
        if (materialization == null && !diagnostics.any(_stale)) continue;
        final artifact = const BorderActions().preview(
          manifest: context.manifest,
          map: map,
          layerId: key.$1,
          featureId: key.$2,
          projectRevision: context.resource.revision!,
          tileSizePx: GridSize(
              width: context.manifest.settings.tileWidth,
              height: context.manifest.settings.tileHeight),
          resolverVersion: materialization?['resolverVersion'] as int? ??
              borderResolverVersion,
        );
        if (!artifact.result.canApply) {
          throw semanticFailure('map3d.edit_batch.guard_refused',
              'A touched Border cannot be materialized.',
              details: {
                'guard': 'staleBorders',
                'layerId': key.$1,
                'featureId': key.$2,
                'diagnostics':
                    artifact.result.diagnostics.map((d) => d.code).toList()
              });
        }
        if (!artifact.isSpatial) {
          throw semanticFailure('map3d.edit_batch.foreign_resource',
              'Atomic 3D edits require spatial Borders.');
        }
        map = applySpatialBorderFeaturePreview(map,
            manifest: context.manifest,
            proposedResult: SpatialBorderResolutionResult(
                mapId: map.id,
                layerId: key.$1,
                featureId: key.$2,
                result: artifact.result,
                modelInstances: artifact.modelInstances));
        rematerialized.add({'layerId': key.$1, 'featureId': key.$2});
      }
    }
    final validation = inspectMapValidation(map,
        manifest: context.manifest,
        fallbackCode: 'map.semantic_projected_state_invalid',
        fallbackMessage: 'The atomic edit would produce invalid map data.');
    if (validation != null) {
      throw validation.toFailure(validationState: 'projected');
    }
    final beforeIntegrity =
        inspectIntegrity(manifest: context.manifest, map: context.map);
    final afterIntegrity =
        inspectIntegrity(manifest: context.manifest, map: map);
    final introduced = afterIntegrity.introducedSince(beforeIntegrity);
    final afterDiagnostics = _diagnostics(context.manifest, map, touched);
    final tracedFeatures = {
      for (final operation in request.operations)
        if (operation['actionId'] == 'intent.border.trace_step')
          (
            (operation['parameters'] as Map)['layerId'],
            (operation['parameters'] as Map)['featureId']
          )
    };
    final unsupportedTrace = afterDiagnostics
        .where((diagnostic) =>
            tracedFeatures
                .contains((diagnostic['layerId'], diagnostic['featureId'])) &&
            (diagnostic['severity'] == 'error' ||
                const {
                  'border.spatial.face_crown_mismatch',
                  'border.spatial.face_base_mismatch',
                  'border.spatial.face_on_land_side',
                  'border.spatial.face_mass_on_land_side',
                }.contains(diagnostic['code'])))
        .toList();
    if (unsupportedTrace.isNotEmpty) {
      throw semanticFailure('intent.step_profile_incompatible',
          'The selected profile does not resolve this height step safely.',
          details: {
            'diagnostics': unsupportedTrace.take(20).toList(),
            'diagnosticCount': unsupportedTrace.length
          });
    }
    final previousIssues = beforeDiagnostics.map(_diagnosticIdentity).toSet();
    final newDiagnostics = afterDiagnostics
        .where((d) => !previousIssues.contains(_diagnosticIdentity(d)))
        .toList();
    final failures = <String>[];
    if (request.guards['groundGaps'] == 'refuse' &&
        introduced.exposedCellCount > 0) {
      failures.add('groundGaps');
    }
    if (request.guards['borderObjectOverlaps'] == 'refuse' &&
        introduced.borderObjectOverlaps.isNotEmpty) {
      failures.add('borderObjectOverlaps');
    }
    if (request.guards['staleBorders'] != 'report' &&
        afterDiagnostics.any(_stale)) {
      failures.add('staleBorders');
    }
    if (request.guards['newBorderErrors'] == 'refuse' &&
        afterDiagnostics.any((d) => d['severity'] == 'error')) {
      failures.add('newBorderErrors');
    }
    if (request.guards['newBorderWarnings'] == 'refuse' &&
        newDiagnostics.any((d) => d['severity'] == 'warning')) {
      failures.add('newBorderWarnings');
    }
    final preview = <String, Object?>{
      'operation': actionId,
      'mapId': map.id,
      'seed': request.seed,
      'operationCount': operations.length,
      'operations': operations,
      'rematerializedFeatureCount': rematerialized.length,
      'rematerializedFeatures':
          rematerialized.take(maximumIntegrityPreviewCount).toList(),
      'detailQuery': {
        'resourceKind': 'spatialMapIntegrity',
        'operation': 'get',
        'ids': [map.id],
        'view': 'detail'
      },
      'groundGapsIntroducedCount': introduced.groundGaps.length,
      'groundGapsIntroduced': introduced.groundGaps
          .take(maximumIntegrityPreviewCount)
          .map((g) => g.toJson())
          .toList(),
      'borderObjectOverlapsIntroduced': introduced.borderObjectOverlaps
          .take(maximumIntegrityPreviewCount)
          .map((o) => o.toJson())
          .toList(),
      'introducedBorderDiagnostics':
          newDiagnostics.take(maximumIntegrityPreviewCount).toList(),
      'finalIntegrity': {
        'exposedCellCount': afterIntegrity.exposedCellCount,
        'unprovenCellCount': afterIntegrity.unprovenCellCount,
        'overlapCount': afterIntegrity.borderObjectOverlaps.length
      },
      'work': {
        'mapEncodings': 0,
        'integrityInspections': 2 + intentIntegrityInspections,
        'finalIntegrityInspections': 2,
        'intentIntegrityInspections': intentIntegrityInspections,
        'integrityScope': 'whole_selected_map',
        'localCostAcceptance': 'PARTIAL',
        'borderResolutions': 'not_measured',
        'invalidations': 'not_measured'
      },
    };
    if (failures.isNotEmpty) {
      throw semanticFailure('map3d.edit_batch.guard_refused',
          'Final integrity guards rejected the atomic map edit.',
          details: {'guards': failures, 'preview': preview});
    }
    if (map == context.map) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: {...preview, 'status': 'unchanged'});
    }
    (preview['work'] as Map<String, Object?>)['mapEncodings'] = 1;
    final afterBytes = encodeMap(map);
    if (computeAuthoringBytesFingerprint(afterBytes,
            logicalName: context.storageKey) ==
        context.resource.revision) {
      return AuthoringMutationDraft(
          changeSet: AuthoringChangeSet.noChanges(),
          preview: {...preview, 'status': 'unchanged'});
    }
    return AuthoringMutationDraft(
        changeSet: AuthoringChangeSet(
            changes: [
              AuthoringResourceChange(
                  resource: context.resource,
                  storageKey: context.storageKey,
                  beforeBytes: context.beforeBytes,
                  afterBytes: afterBytes),
            ],
            diff: AuthoringDiff([
              AuthoringDiffEntry(
                  operation: AuthoringDiffOperation.replace,
                  resource: context.resource,
                  path: '/maps/${map.id}',
                  before: {'id': context.map.id},
                  after: {'id': map.id, 'operationCount': operations.length})
            ])),
        preview: {...preview, 'status': 'changed'});
  }
}

Set<(String, String)> _touchedFeatures(MapData before, MapData after) {
  final previous = {
    for (final layer in before.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        (layer.id, feature.id): feature
  };
  final previousScene = before.spatialScene!, nextScene = after.spatialScene!;
  final terrainChanged = previousScene.levelHeight != nextScene.levelHeight ||
      previousScene.heightLevels.length != nextScene.heightLevels.length ||
      previousScene.heightLevels.indexed
          .any((entry) => entry.$2 != nextScene.heightLevels[entry.$1]) ||
      previousScene.terrainSurfaces != nextScene.terrainSurfaces;
  return {
    for (final layer in after.layers.whereType<BorderLayer>())
      for (final feature in layer.content.features)
        if (terrainChanged || previous[(layer.id, feature.id)] != feature)
          (layer.id, feature.id)
  };
}

BorderFeature? _feature(MapData map, (String, String) key) => map.layers
    .whereType<BorderLayer>()
    .where((layer) => layer.id == key.$1)
    .firstOrNull
    ?.content
    .featureById(key.$2);

List<Map<String, Object?>> _diagnostics(ProjectManifest manifest, MapData map,
        Iterable<(String, String)> keys) =>
    [
      for (final key in keys)
        if (_feature(map, key) != null)
          for (final diagnostic in diagnoseSpatialBorderFeature(
                  manifest: manifest,
                  map: map,
                  layerId: key.$1,
                  featureId: key.$2,
                  requireMaterialization: false)
              .diagnostics)
            {
              'layerId': key.$1,
              'featureId': key.$2,
              'code': diagnostic.code,
              'severity': diagnostic.severity.name,
              if (diagnostic.slotKey != null) 'slotKey': diagnostic.slotKey,
              if (diagnostic.cell case final cell?)
                'cell': {'x': cell.x, 'y': cell.y},
              'parameters': diagnostic.parameters
            },
    ];

bool _stale(Map<String, Object?> diagnostic) => const {
      'border.materialization.missing',
      'border.spatial.materialization_stale'
    }.contains(diagnostic['code']);

String _diagnosticIdentity(Map<String, Object?> diagnostic) =>
    computeAuthoringJsonFingerprint(diagnostic,
        logicalName: 'border-diagnostic.json');
