import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'map_lifecycle_adapter.dart';
import 'map_validation_diagnostics.dart';

final class SemanticMapEdit {
  SemanticMapEdit({
    required this.map,
    required this.layerId,
    required this.operation,
    required this.changedCells,
    Map<String, Object?> preview = const {},
  }) : preview = Map.unmodifiable(preview);

  final MapData map;
  final String layerId;
  final String operation;
  final int changedCells;
  final Map<String, Object?> preview;
}

final class SemanticMapActionContext {
  SemanticMapActionContext._({
    required this.planning,
    required this.parameters,
    required this.map,
    required this.storageKey,
    required this.resource,
    required this.beforeBytes,
  });

  factory SemanticMapActionContext.read(
    AuthoringPlanningContext planning, {
    required Set<String> allowedParameters,
  }) {
    if (planning.request.actionVersion != 1) {
      throw semanticFailure(
        'map.action_version_unsupported',
        'The requested semantic map action version is unsupported.',
        details: {'actionVersion': planning.request.actionVersion},
      );
    }
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: {'mapId', ...allowedParameters},
    );
    final mapId = parameters.string('mapId');
    final map = planning.snapshot.mapById(mapId);
    if (map == null) {
      throw semanticFailure(
        'map.not_found',
        'The requested map does not exist.',
        details: {'mapId': mapId},
      );
    }
    final entry = planning.snapshot.manifest.maps
        .where((candidate) => candidate.id == mapId)
        .firstOrNull;
    if (entry == null) {
      throw semanticFailure(
        'map.manifest_entry_missing',
        'The map has no project manifest storage entry.',
        details: {'mapId': mapId},
      );
    }
    final revision = planning.snapshot.resourceFingerprints['map:$mapId'];
    if (revision == null) {
      throw semanticFailure(
        'map.resource_preimage_missing',
        'The map resource revision is unavailable.',
        details: {'mapId': mapId},
      );
    }
    return SemanticMapActionContext._(
      planning: planning,
      parameters: parameters,
      map: map,
      storageKey: entry.relativePath,
      resource: AuthoringResourceRef(
        kind: 'map',
        id: mapId,
        revision: revision,
      ),
      beforeBytes: planning.snapshot.resourceBytes('map:$mapId'),
    );
  }

  final AuthoringPlanningContext planning;
  final SemanticParameters parameters;
  final MapData map;
  final String storageKey;
  final AuthoringResourceRef resource;
  final List<int> beforeBytes;

  ProjectManifest get manifest => planning.snapshot.manifest;

  AuthoringMutationDraft draft(
    SemanticMapEdit edit, {
    MapMutationDelta? delta,
  }) {
    if (!edit.map.layers.any((layer) => layer.id == edit.layerId)) {
      throw semanticFailure(
        'map.layer_missing',
        'The semantic operation target layer does not exist.',
        details: {'layerId': edit.layerId},
      );
    }
    final validation = delta == null
        ? inspectMapValidation(
            edit.map,
            manifest: planning.snapshot.manifest,
            fallbackCode: 'map.semantic_projected_state_invalid',
            fallbackMessage:
                'The semantic operation would produce invalid PokeMap data.',
          )
        : _inspectMapDeltaValidation(
            before: map,
            after: edit.map,
            delta: delta,
            manifest: planning.snapshot.manifest,
          );
    if (validation != null) {
      throw validation.toFailure(validationState: 'projected');
    }
    final afterBytes = encodeMapAuthoringDocument(edit.map);
    if (_sameBytes(beforeBytes, afterBytes)) {
      throw semanticFailure(
        'map.no_change',
        'The semantic operation changes nothing.',
      );
    }
    final beforeLayer = map.layers.singleWhere(
      (layer) => layer.id == edit.layerId,
    );
    final afterLayer = edit.map.layers.singleWhere(
      (layer) => layer.id == edit.layerId,
    );
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: storageKey,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/layers/${edit.layerId}',
            before: semanticLayerSummary(beforeLayer),
            after: semanticLayerSummary(afterLayer),
          ),
        ]),
      ),
      preview: {
        'operation': edit.operation,
        'mapId': map.id,
        'layerId': edit.layerId,
        'seed': planning.seed,
        'changedCellCount': edit.changedCells,
        ...edit.preview,
      },
    );
  }

  /// Builds one atomic map-wide change for semantic operations that also
  /// affect spatial collections (placements, entities, warps) or map size.
  AuthoringMutationDraft draftMap({
    required MapData after,
    required String operation,
    required int changedItems,
    String? layerId,
    Map<String, Object?> preview = const {},
  }) {
    final validation = inspectMapValidation(
      after,
      manifest: planning.snapshot.manifest,
      fallbackCode: 'map.semantic_projected_state_invalid',
      fallbackMessage:
          'The semantic operation would produce invalid PokeMap data.',
    );
    if (validation != null) {
      throw validation.toFailure(validationState: 'projected');
    }
    final afterBytes = encodeMapAuthoringDocument(after);
    if (_sameBytes(beforeBytes, afterBytes)) {
      throw semanticFailure(
        'map.no_change',
        'The semantic operation changes nothing.',
      );
    }
    return AuthoringMutationDraft(
      changeSet: AuthoringChangeSet(
        changes: [
          AuthoringResourceChange(
            resource: resource,
            storageKey: storageKey,
            beforeBytes: beforeBytes,
            afterBytes: afterBytes,
          ),
        ],
        diff: AuthoringDiff([
          AuthoringDiffEntry(
            operation: AuthoringDiffOperation.replace,
            resource: resource,
            path: '/maps/${map.id}',
            before: semanticMapSummary(map),
            after: semanticMapSummary(after),
          ),
        ]),
      ),
      preview: {
        'operation': operation,
        'mapId': map.id,
        if (layerId != null) 'layerId': layerId,
        'seed': planning.seed,
        'changedItemCount': changedItems,
        ...preview,
      },
    );
  }
}

MapValidationIssue? _inspectMapDeltaValidation({
  required MapData before,
  required MapData after,
  required MapMutationDelta delta,
  required ProjectManifest manifest,
}) {
  try {
    MapDeltaValidator.validate(
      DeltaValidationContext(
        before: before,
        after: after,
        delta: delta,
        project: manifest,
      ),
    );
    return null;
  } on Object catch (error) {
    return MapValidationIssue.fromError(
      error,
      fallbackCode: 'map.semantic_projected_state_invalid',
      fallbackMessage:
          'The semantic operation would produce invalid PokeMap data.',
    );
  }
}

final class SemanticParameters {
  SemanticParameters(
    Map<String, Object?> values, {
    required Set<String> allowed,
  }) : _values = values {
    final unknown = values.keys.where((key) => !allowed.contains(key)).toList()
      ..sort();
    if (unknown.isNotEmpty) {
      throw semanticFailure(
        'map.request_invalid',
        'The semantic map action contains unsupported parameters.',
        details: {'unknownParameters': unknown},
      );
    }
  }

  final Map<String, Object?> _values;

  Map<String, Object?> get values => _values;

  bool contains(String key) => _values.containsKey(key);

  Object? value(String key) => _values[key];

  String string(String key) {
    final value = _values[key];
    if (value is! String || value.trim() != value || value.isEmpty) {
      throw invalidSemanticField(key, 'a nonblank trimmed string');
    }
    return value;
  }

  String? optionalString(String key) =>
      _values[key] == null ? null : string(key);

  int integer(String key) {
    final value = _values[key];
    if (value is! int) throw invalidSemanticField(key, 'an integer');
    return value;
  }

  int? optionalInteger(String key) =>
      _values[key] == null ? null : integer(key);

  bool boolean(String key) {
    final value = _values[key];
    if (value is! bool) throw invalidSemanticField(key, 'a boolean');
    return value;
  }

  Map<String, Object?> object(String key) {
    final value = _values[key];
    if (value is! Map || value.keys.any((candidate) => candidate is! String)) {
      throw invalidSemanticField(key, 'a JSON object');
    }
    return Map<String, Object?>.from(value);
  }

  List<Object?> list(String key) {
    final value = _values[key];
    if (value is! List) throw invalidSemanticField(key, 'a JSON list');
    return List<Object?>.from(value);
  }
}

AuthoringActionDescriptor semanticActionDescriptor(
  String id,
  String summary,
) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'schema.$id.input.v1',
      outputSchemaId: 'schema.map.semantic_mutation.output.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const ['map', 'preset'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'semanticIds': true,
        'rawTilesetRequired': false,
      },
    );

Map<String, Object?> semanticLayerSummary(MapLayer layer) => switch (layer) {
      SmartTileLayer value => {
          'kind': 'smart_tile',
          'id': value.id,
          'presetId': value.presetId,
          'authoredCellCount': smartTileAuthoredValueCount(value),
        },
      _ => {'kind': layer.runtimeType.toString(), 'id': layer.id},
    };

Map<String, Object?> semanticMapSummary(MapData map) => {
      'id': map.id,
      'width': map.size.width,
      'height': map.size.height,
      'layerCount': map.layers.length,
      'placedElementCount': map.placedElements.length,
      'entityCount': map.entities.length,
      'warpCount': map.warps.length,
      'connectionCount': map.connections.length,
      'triggerCount': map.triggers.length,
      'gameplayZoneCount': map.gameplayZones.length,
    };

MapAuthoringException invalidSemanticField(String field, String expected) =>
    semanticFailure(
      'map.request_invalid',
      'Parameter "$field" must be $expected.',
      details: {'parameter': field, 'expected': expected},
    );

MapAuthoringException semanticFailure(
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

bool _sameBytes(List<int> left, List<int> right) {
  if (left.length != right.length) return false;
  for (var index = 0; index < left.length; index++) {
    if (left[index] != right[index]) return false;
  }
  return true;
}
