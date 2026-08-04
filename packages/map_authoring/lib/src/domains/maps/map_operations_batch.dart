import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'layer_actions.dart';
import 'map_lifecycle_adapter.dart';
import 'map_validation_diagnostics.dart';
import 'region_operations.dart';
import 'smart_tile_transition_guards.dart';

/// Canonical compact batch action for layer and bounded region authoring.
final class MapOperationsActions {
  const MapOperationsActions({
    MapLayerOperations layerOperations = const MapLayerOperations(),
    MapRegionOperations regionOperations = const MapRegionOperations(),
  })  : _layerOperations = layerOperations,
        _regionOperations = regionOperations;

  static const int maxOperations = 256;
  static const int maxMapCells = 1000000;
  static const int maxCumulativeChangedCells = 1000000;

  final MapLayerOperations _layerOperations;
  final MapRegionOperations _regionOperations;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    AuthoringActionDescriptor(
      id: 'map.apply_operations',
      version: 1,
      summary: 'Apply one bounded atomic batch of layer and region operations',
      inputSchemaId: 'schema.map.apply_operations.input.v1',
      outputSchemaId: 'schema.map.mutation.output.v1',
      riskLevel: AuthoringRiskLevel.medium,
      resourceKinds: const ['map'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'batchAtomicity': 'all_or_nothing',
        'maxOperations': maxOperations,
        'maxMapCells': maxMapCells,
        'receiptPayload': 'bounded_summary',
        'tileLayerEncoding': 'tile_palette_v1',
        'tileLayerAddParameters': <String>[
          'kind',
          'layerKind',
          'layerId',
          'name',
          'insertIndex',
        ],
        'tileCellValue': <String, Object?>{
          'empty': null,
          'entrySchema': 'tile_palette_entry_v1',
        },
        'boundedRegionQuery': <String, Object?>{
          'resourceKind': 'map',
          'operation': 'get',
          'view': 'detail',
          'requestExtension': 'region',
        },
      },
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext context) {
    if (context.request.actionId != 'map.apply_operations') {
      throw _failure(
        'map.action_unsupported',
        'The requested map operations action is unsupported.',
        details: {'actionId': context.request.actionId},
      );
    }
    if (context.request.actionVersion != 1) {
      throw _failure(
        'map.action_version_unsupported',
        'The requested map operations action version is unsupported.',
        details: {'actionVersion': context.request.actionVersion},
      );
    }
    final parameters = context.request.parameters;
    _only(parameters, const {'mapId', 'operations'});
    final mapId = _string(parameters, 'mapId');
    final before = context.snapshot.mapById(mapId);
    if (before == null) {
      throw _failure(
        'map.not_found',
        'The requested map does not exist.',
        details: {'mapId': mapId},
      );
    }
    final cellCount = before.size.width * before.size.height;
    if (cellCount > maxMapCells) {
      throw _failure(
        'map.batch_bounds_exceeded',
        'The map is too large for one bounded operation batch.',
        details: {'mapCellCount': cellCount, 'maxMapCells': maxMapCells},
      );
    }
    final rawOperations = parameters['operations'];
    if (rawOperations is! List || rawOperations.isEmpty) {
      throw _invalid('operations', 'a non-empty list');
    }
    if (rawOperations.length > maxOperations) {
      throw _failure(
        'map.batch_bounds_exceeded',
        'The operation batch exceeds the supported operation count.',
        details: {
          'operationCount': rawOperations.length,
          'maxOperations': maxOperations,
        },
      );
    }

    // Initial invalidity is evidence, not permission to persist invalid data.
    // Capturing it lets the final diagnostic distinguish a pre-existing issue
    // from one introduced by the projected batch, while the final validation
    // remains strictly fail-closed.
    final initialValidation = inspectMapValidation(
      before,
      manifest: context.snapshot.manifest,
      fallbackCode: 'map.batch_initial_state_invalid',
      fallbackMessage: 'The initial map state is invalid PokeMap data.',
    );

    var current = before;
    var changedCells = 0;
    final touchedLayers = <String>{};
    final summaries = <Map<String, Object?>>[];
    final clipboard = MapRegionClipboard();
    for (var index = 0; index < rawOperations.length; index++) {
      final raw = rawOperations[index];
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw _operationFailure(
          index,
          '<invalid>',
          _invalid('operations[$index]', 'a JSON object'),
        );
      }
      final operation = Map<String, Object?>.from(raw);
      final kindValue = operation['kind'];
      final kind = kindValue is String ? kindValue : '<invalid>';
      try {
        late final MapOperationStepResult result;
        if (MapLayerOperations.supportedKinds.contains(kind)) {
          result = _layerOperations.apply(current, operation);
        } else if (MapRegionOperations.supportedKinds.contains(kind)) {
          result = _regionOperations.apply(
            current,
            operation,
            clipboard: clipboard,
          );
        } else {
          throw _failure(
            'map.operation_unsupported',
            'The requested batch operation kind is unsupported.',
            details: {'kind': kind},
          );
        }
        current = result.map;
        changedCells += result.changedCells;
        touchedLayers.addAll(result.touchedLayerIds);
        if (changedCells > maxCumulativeChangedCells) {
          throw _failure(
            'map.batch_bounds_exceeded',
            'The batch exceeds the cumulative changed-cell limit.',
            details: {
              'changedCellCount': changedCells,
              'maxChangedCells': maxCumulativeChangedCells,
            },
          );
        }
        if (summaries.length < 64) {
          summaries.add({
            'index': index,
            'kind': kind,
            'changedCells': result.changedCells,
            'touchedLayerIds': result.touchedLayerIds.toList()..sort(),
            ...result.metadata,
          });
        }
      } on MapAuthoringException catch (error) {
        if (isSmartTileTransitionGuardCode(error.code)) rethrow;
        throw _operationFailure(index, kind, error);
      }
    }

    final projectedValidation = inspectMapValidation(
      current,
      manifest: context.snapshot.manifest,
      fallbackCode: 'map.batch_projected_state_invalid',
      fallbackMessage:
          'The complete operation batch would produce invalid PokeMap data.',
    );
    if (projectedValidation != null) {
      final state = initialValidation == null
          ? 'introduced'
          : projectedValidation.equivalentTo(initialValidation)
              ? 'pre_existing'
              : 'changed';
      throw projectedValidation.toFailure(
        validationState: state,
        initialIssue: initialValidation,
      );
    }
    final beforeBytes = context.snapshot.resourceBytes('map:$mapId');
    final afterBytes = encodeMapAuthoringDocument(current);
    if (_sameBytes(beforeBytes, afterBytes)) {
      throw _failure('map.no_change', 'The operation batch changes nothing.');
    }
    final entry = context.snapshot.manifest.maps
        .where((candidate) => candidate.id == mapId)
        .firstOrNull;
    if (entry == null) {
      throw _failure(
        'map.manifest_entry_missing',
        'The map has no project manifest storage entry.',
        details: {'mapId': mapId},
      );
    }
    final revision = context.snapshot.resourceFingerprints['map:$mapId'];
    if (revision == null) {
      throw _failure(
        'map.resource_preimage_missing',
        'The map resource revision is unavailable.',
        details: {'mapId': mapId},
      );
    }
    final resource = AuthoringResourceRef(
      kind: 'map',
      id: mapId,
      revision: revision,
    );
    final sortedLayers = touchedLayers.toList()..sort();
    final beforeSummary = _mapLayerSummary(before);
    final afterSummary = _mapLayerSummary(current);
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: entry.relativePath,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/layers',
            before: beforeSummary,
            after: afterSummary,
          ),
        ]),
      ),
      preview: {
        'operation': 'apply_operations',
        'mapId': mapId,
        'operationCount': rawOperations.length,
        'changedCellCount': changedCells,
        'touchedLayerCount': sortedLayers.length,
        'touchedLayerIds': sortedLayers.take(64).toList(growable: false),
        'operationSummaries': summaries,
        'summariesTruncated': rawOperations.length > summaries.length,
        'batchAtomicity': 'all_or_nothing',
        'validation': {
          'initialStatus': initialValidation == null ? 'valid' : 'invalid',
          'projectedStatus': 'valid',
          'repaired': initialValidation != null,
          if (initialValidation != null)
            'initialIssue': initialValidation.toJson(),
        },
      },
    );
  }
}

Map<String, Object?> _mapLayerSummary(MapData map) => {
      'mapId': map.id,
      'width': map.size.width,
      'height': map.size.height,
      'layerCount': map.layers.length,
      'layerIds': map.layers.map((layer) => layer.id).take(64).toList(),
      'layerIdsTruncated': map.layers.length > 64,
    };

MapAuthoringException _operationFailure(
  int index,
  String kind,
  MapAuthoringException cause,
) =>
    _failure(
      'map.operation_invalid',
      'The operation batch was rejected without applying any operation.',
      details: {
        'operationIndex': index,
        'operationKind': kind,
        'causeCode': cause.code,
        'causeDetails': cause.details,
      },
      remediation: cause.remediation,
    );

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}

void _only(Map<String, Object?> values, Set<String> allowed) {
  final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw _failure(
      'map.request_invalid',
      'The map operations request contains unsupported parameters.',
      details: {'unknownParameters': unknown},
    );
  }
}

String _string(Map<String, Object?> values, String key) {
  final value = values[key];
  if (value is! String || value.trim() != value || value.isEmpty) {
    throw _invalid(key, 'a nonblank trimmed string');
  }
  return value;
}

MapAuthoringException _invalid(String field, String expected) => _failure(
      'map.request_invalid',
      'Parameter "$field" must be $expected.',
      details: {'parameter': field, 'expected': expected},
    );

MapAuthoringException _failure(
  String code,
  String message, {
  Map<String, Object?> details = const {},
  Iterable<String> remediation = const [],
}) =>
    MapAuthoringException(
      code: code,
      message: message,
      details: details,
      remediation: remediation,
    );
