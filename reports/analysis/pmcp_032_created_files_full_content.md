# PMCP-032 — Created Files Full Content

This appendix preserves the exact full content of every production and test file created by PMCP-032. The evidence pack and this appendix are excluded to avoid recursive report content.

## `packages/map_authoring/lib/src/domains/maps/semantic_map_action_support.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_diff.dart';
import '../../contracts/resource_ref.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import '../../transactions/change_set.dart';
import 'map_lifecycle_adapter.dart';

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

  AuthoringMutationDraft draft(SemanticMapEdit edit) {
    if (!edit.map.layers.any((layer) => layer.id == edit.layerId)) {
      throw semanticFailure(
        'map.layer_missing',
        'The semantic operation target layer does not exist.',
        details: {'layerId': edit.layerId},
      );
    }
    try {
      MapValidator.validate(
        edit.map,
        projectDialogueContext: planning.snapshot.manifest,
      );
    } on Object catch (error) {
      throw semanticFailure(
        'map.semantic_projected_state_invalid',
        'The semantic operation would produce invalid PokeMap data.',
        details: {'validationType': error.runtimeType.toString()},
      );
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
      TerrainLayer value => {
          'kind': 'terrain',
          'id': value.id,
          'authoredCellCount':
              value.terrains.where((cell) => cell != TerrainType.none).length,
        },
      PathLayer value => {
          'kind': 'path',
          'id': value.id,
          'presetId': value.presetId,
          'authoredCellCount': value.cells.where((cell) => cell).length,
          'propertyCount': value.properties.length,
        },
      SurfaceLayer value => {
          'kind': 'surface',
          'id': value.id,
          'authoredCellCount': value.placements.length,
        },
      SmartTileLayer value => {
          'kind': 'smart_tile',
          'id': value.id,
          'presetId': value.presetId,
          'authoredCellCount':
              value.materialCells.where((cell) => cell != 0).length,
        },
      _ => {'kind': layer.runtimeType.toString(), 'id': layer.id},
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
```
## `packages/map_authoring/lib/src/domains/maps/terrain_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'region_operations.dart';
import 'semantic_map_action_support.dart';

final class TerrainActions {
  const TerrainActions({
    MapRegionOperations regions = const MapRegionOperations(),
  }) : _regions = regions;

  final MapRegionOperations _regions;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor(
        'terrain.erase', 'Erase one semantic terrain cell'),
    semanticActionDescriptor(
      'terrain.erase_pattern',
      'Erase a semantic terrain rectangle',
    ),
    semanticActionDescriptor('terrain.fill', 'Fill a semantic terrain region'),
    semanticActionDescriptor(
        'terrain.paint', 'Paint one semantic terrain cell'),
    semanticActionDescriptor(
      'terrain.paint_pattern',
      'Stamp semantic terrain preset identities',
    ),
    semanticActionDescriptor(
      'terrain.replace',
      'Replace one semantic terrain preset type',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'terrain.paint' => const {'layerId', 'presetId', 'x', 'y'},
      'terrain.paint_pattern' => const {
          'layerId',
          'x',
          'y',
          'width',
          'height',
          'presetIds',
        },
      'terrain.erase' => const {'layerId', 'x', 'y'},
      'terrain.erase_pattern' => const {
          'layerId',
          'x',
          'y',
          'width',
          'height',
        },
      'terrain.fill' => const {
          'layerId',
          'presetId',
          'x',
          'y',
          'width',
          'height',
        },
      'terrain.replace' => const {
          'layerId',
          'fromPresetId',
          'toPresetId',
          'x',
          'y',
          'width',
          'height',
        },
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested terrain action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    final layerId = parameters.string('layerId');
    late final Map<String, Object?> operation;
    final preview = <String, Object?>{};
    switch (actionId) {
      case 'terrain.paint':
        final preset = _terrainPreset(
          context.manifest,
          parameters.string('presetId'),
        );
        operation = {
          'kind': 'region.paint',
          'layerId': layerId,
          'x': parameters.integer('x'),
          'y': parameters.integer('y'),
          'value': preset.terrainType.name,
        };
        preview['presetId'] = preset.id;
      case 'terrain.paint_pattern':
        final rawIds = parameters.list('presetIds');
        final terrainNames = <String>[];
        final presetIds = <String>[];
        for (var index = 0; index < rawIds.length; index++) {
          final raw = rawIds[index];
          if (raw is! String || raw.trim() != raw || raw.isEmpty) {
            throw invalidSemanticField(
              'presetIds[$index]',
              'a nonblank trimmed preset ID',
            );
          }
          final preset = _terrainPreset(context.manifest, raw);
          terrainNames.add(preset.terrainType.name);
          presetIds.add(preset.id);
        }
        operation = {
          'kind': 'region.stamp',
          'layerId': layerId,
          'x': parameters.integer('x'),
          'y': parameters.integer('y'),
          'width': parameters.integer('width'),
          'height': parameters.integer('height'),
          'values': terrainNames,
        };
        preview['presetIds'] = presetIds.toSet().toList()..sort();
      case 'terrain.erase':
        operation = {
          'kind': 'region.erase',
          'layerId': layerId,
          'x': parameters.integer('x'),
          'y': parameters.integer('y'),
        };
      case 'terrain.erase_pattern':
        operation = {
          'kind': 'region.erase',
          'layerId': layerId,
          'x': parameters.integer('x'),
          'y': parameters.integer('y'),
          'width': parameters.integer('width'),
          'height': parameters.integer('height'),
        };
      case 'terrain.fill':
        final preset = _terrainPreset(
          context.manifest,
          parameters.string('presetId'),
        );
        operation = {
          'kind': 'region.fill',
          'layerId': layerId,
          'x': parameters.integer('x'),
          'y': parameters.integer('y'),
          'width': parameters.integer('width'),
          'height': parameters.integer('height'),
          'value': preset.terrainType.name,
        };
        preview['presetId'] = preset.id;
      case 'terrain.replace':
        final from = _terrainPreset(
          context.manifest,
          parameters.string('fromPresetId'),
        );
        final to = _terrainPreset(
          context.manifest,
          parameters.string('toPresetId'),
        );
        operation = {
          'kind': 'region.replace',
          'layerId': layerId,
          'from': from.terrainType.name,
          'to': to.terrainType.name,
          if (parameters.contains('x')) 'x': parameters.integer('x'),
          if (parameters.contains('y')) 'y': parameters.integer('y'),
          if (parameters.contains('width'))
            'width': parameters.integer('width'),
          if (parameters.contains('height'))
            'height': parameters.integer('height'),
        };
        preview.addAll({
          'fromPresetId': from.id,
          'toPresetId': to.id,
        });
      default:
        throw StateError('unreachable terrain action');
    }
    final result = _regions.apply(context.map, operation);
    return context.draft(
      SemanticMapEdit(
        map: result.map,
        layerId: layerId,
        operation: actionId,
        changedCells: result.changedCells,
        preview: preview,
      ),
    );
  }
}

ProjectTerrainPreset _terrainPreset(ProjectManifest manifest, String presetId) {
  for (final preset in manifest.terrainPresets) {
    if (preset.id == presetId) return preset;
  }
  throw semanticFailure(
    'terrain.preset_missing',
    'The requested terrain preset does not exist.',
    details: {'presetId': presetId},
    remediation: const [
      'Create the terrain preset or choose an ID returned by project inspection.',
    ],
  );
}
```

## `packages/map_authoring/lib/src/domains/maps/path_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'region_operations.dart';
import 'semantic_map_action_support.dart';

final class PathActions {
  const PathActions({
    MapRegionOperations regions = const MapRegionOperations(),
  }) : _regions = regions;

  final MapRegionOperations _regions;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor(
      'path.assign_preset',
      'Assign one semantic preset to a path layer',
    ),
    semanticActionDescriptor('path.erase', 'Erase one semantic path cell'),
    semanticActionDescriptor(
      'path.erase_pattern',
      'Erase a semantic path rectangle',
    ),
    semanticActionDescriptor('path.fill', 'Fill a semantic path region'),
    semanticActionDescriptor('path.paint', 'Paint one semantic path cell'),
    semanticActionDescriptor(
      'path.paint_pattern',
      'Stamp one semantic path occupancy pattern',
    ),
    semanticActionDescriptor(
      'path.set_animation_mode',
      'Set semantic path animation mode',
    ),
    semanticActionDescriptor(
      'path.set_properties',
      'Replace semantic path properties',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'path.paint' => const {'layerId', 'presetId', 'x', 'y'},
      'path.paint_pattern' => const {
          'layerId',
          'presetId',
          'x',
          'y',
          'width',
          'height',
          'cells',
        },
      'path.erase' => const {'layerId', 'x', 'y'},
      'path.erase_pattern' => const {
          'layerId',
          'x',
          'y',
          'width',
          'height',
        },
      'path.fill' => const {
          'layerId',
          'presetId',
          'x',
          'y',
          'width',
          'height',
        },
      'path.assign_preset' => const {'layerId', 'presetId'},
      'path.set_properties' => const {'layerId', 'properties'},
      'path.set_animation_mode' => const {'layerId', 'animationMode'},
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested path action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    final layerId = parameters.string('layerId');
    var map = context.map;
    var changedCells = 0;
    final preview = <String, Object?>{};

    switch (actionId) {
      case 'path.paint':
      case 'path.paint_pattern':
      case 'path.fill':
        final preset = _pathPreset(
          context.manifest,
          parameters.string('presetId'),
        );
        map = _assignForPainting(map, layerId: layerId, preset: preset);
        preview['presetId'] = preset.id;
        late final Map<String, Object?> operation;
        if (actionId == 'path.paint') {
          operation = {
            'kind': 'region.paint',
            'layerId': layerId,
            'x': parameters.integer('x'),
            'y': parameters.integer('y'),
            'value': true,
          };
        } else if (actionId == 'path.fill') {
          operation = {
            'kind': 'region.fill',
            'layerId': layerId,
            'x': parameters.integer('x'),
            'y': parameters.integer('y'),
            'width': parameters.integer('width'),
            'height': parameters.integer('height'),
            'value': true,
          };
        } else {
          final cells = parameters.list('cells');
          for (var index = 0; index < cells.length; index++) {
            if (cells[index] is! bool) {
              throw invalidSemanticField('cells[$index]', 'a boolean');
            }
          }
          operation = {
            'kind': 'region.stamp',
            'layerId': layerId,
            'x': parameters.integer('x'),
            'y': parameters.integer('y'),
            'width': parameters.integer('width'),
            'height': parameters.integer('height'),
            'values': cells,
          };
        }
        final result = _regions.apply(map, operation);
        map = result.map;
        changedCells = result.changedCells;
      case 'path.erase':
      case 'path.erase_pattern':
        final operation = <String, Object?>{
          'kind': 'region.erase',
          'layerId': layerId,
          'x': parameters.integer('x'),
          'y': parameters.integer('y'),
          if (actionId == 'path.erase_pattern')
            'width': parameters.integer('width'),
          if (actionId == 'path.erase_pattern')
            'height': parameters.integer('height'),
        };
        final result = _regions.apply(map, operation);
        map = result.map;
        changedCells = result.changedCells;
      case 'path.assign_preset':
        final preset = _pathPreset(
          context.manifest,
          parameters.string('presetId'),
        );
        _requirePathLayer(map, layerId);
        map =
            assignPathPresetToLayer(map, layerId: layerId, presetId: preset.id);
        preview['presetId'] = preset.id;
      case 'path.set_properties':
        final raw = parameters.object('properties');
        final properties = <String, String>{};
        for (final entry in raw.entries) {
          if (entry.value is! String) {
            throw invalidSemanticField(
              'properties.${entry.key}',
              'a string',
            );
          }
          properties[entry.key] = entry.value! as String;
        }
        _requirePathLayer(map, layerId);
        map = setPathLayerProperties(
          map,
          layerId: layerId,
          properties: properties,
        );
        preview['propertyCount'] = properties.length;
      case 'path.set_animation_mode':
        final mode = _animationMode(parameters.string('animationMode'));
        _requirePathLayer(map, layerId);
        map = setPathLayerAnimationModeInMap(
          map,
          layerId: layerId,
          mode: mode,
        );
        preview['animationMode'] = _animationModeWireName(mode);
      default:
        throw StateError('unreachable path action');
    }

    return context.draft(
      SemanticMapEdit(
        map: map,
        layerId: layerId,
        operation: actionId,
        changedCells: changedCells,
        preview: preview,
      ),
    );
  }
}

ProjectPathPreset _pathPreset(ProjectManifest manifest, String presetId) {
  for (final preset in manifest.pathPresets) {
    if (preset.id == presetId) return preset;
  }
  throw semanticFailure(
    'path.preset_missing',
    'The requested path preset does not exist.',
    details: {'presetId': presetId},
    remediation: const [
      'Create the path preset or choose an ID returned by project inspection.',
    ],
  );
}

MapData _assignForPainting(
  MapData map, {
  required String layerId,
  required ProjectPathPreset preset,
}) {
  final layer = _requirePathLayer(map, layerId);
  if (layer.presetId.isNotEmpty &&
      layer.presetId != preset.id &&
      layer.cells.any((cell) => cell)) {
    throw semanticFailure(
      'path.preset_conflict',
      'The path layer already contains cells authored with another preset.',
      details: {
        'layerId': layerId,
        'currentPresetId': layer.presetId,
        'requestedPresetId': preset.id,
      },
      remediation: const [
        'Clear the layer or call path.assign_preset to restyle it explicitly.',
      ],
    );
  }
  return assignPathPresetToLayer(map, layerId: layerId, presetId: preset.id);
}

PathLayer _requirePathLayer(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      if (layer is PathLayer) return layer;
      break;
    }
  }
  throw semanticFailure(
    'path.layer_invalid',
    'The requested layer is not a path layer.',
    details: {'layerId': layerId},
  );
}

PathAnimationMode _animationMode(String value) {
  if (value == 'always_active') return PathAnimationMode.alwaysActive;
  if (value == 'triggered') return PathAnimationMode.triggered;
  throw invalidSemanticField(
      'animationMode', 'a supported path animation mode');
}

String _animationModeWireName(PathAnimationMode mode) => switch (mode) {
      PathAnimationMode.alwaysActive => 'always_active',
      PathAnimationMode.triggered => 'triggered',
    };
```

## `packages/map_authoring/lib/src/domains/maps/surface_actions.dart`

```dart
import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'region_operations.dart';
import 'semantic_map_action_support.dart';

final class SurfaceActions {
  const SurfaceActions({
    MapRegionOperations regions = const MapRegionOperations(),
  }) : _regions = regions;

  final MapRegionOperations _regions;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor('surface.clear', 'Clear a semantic surface layer'),
    semanticActionDescriptor(
        'surface.erase', 'Erase one semantic surface cell'),
    semanticActionDescriptor(
      'surface.erase_area',
      'Erase a semantic surface rectangle',
    ),
    semanticActionDescriptor(
      'surface.paint',
      'Paint one semantic surface preset identity',
    ),
    semanticActionDescriptor(
      'surface.replace_placements',
      'Replace semantic surface placements atomically',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    final actionId = planning.request.actionId;
    final allowed = switch (actionId) {
      'surface.paint' => const {'layerId', 'presetId', 'x', 'y'},
      'surface.erase' => const {'layerId', 'x', 'y'},
      'surface.erase_area' => const {
          'layerId',
          'x',
          'y',
          'width',
          'height',
        },
      'surface.clear' => const {'layerId'},
      'surface.replace_placements' => const {'layerId', 'placements'},
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested surface action is unsupported.',
          details: {'actionId': actionId},
        ),
    };
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: allowed,
    );
    final parameters = context.parameters;
    final layerId = parameters.string('layerId');
    var map = context.map;
    var changedCells = 0;
    final preview = <String, Object?>{};

    if (actionId == 'surface.replace_placements') {
      final beforeLayer = _surfaceLayer(map, layerId);
      final rawPlacements = parameters.list('placements');
      final placements = <SurfaceCellPlacement>[];
      final presetIds = <String>{};
      for (var index = 0; index < rawPlacements.length; index++) {
        final raw = rawPlacements[index];
        if (raw is! Map || raw.keys.any((key) => key is! String)) {
          throw invalidSemanticField(
            'placements[$index]',
            'a placement object',
          );
        }
        final placement = Map<String, Object?>.from(raw);
        final unknown = placement.keys
            .where((key) => !const {'x', 'y', 'presetId'}.contains(key))
            .toList()
          ..sort();
        if (unknown.isNotEmpty) {
          throw semanticFailure(
            'map.request_invalid',
            'A surface placement contains unsupported fields.',
            details: {'placementIndex': index, 'unknownFields': unknown},
          );
        }
        final x = placement['x'];
        final y = placement['y'];
        final presetId = placement['presetId'];
        if (x is! int) {
          throw invalidSemanticField('placements[$index].x', 'an integer');
        }
        if (y is! int) {
          throw invalidSemanticField('placements[$index].y', 'an integer');
        }
        if (presetId is! String ||
            presetId.trim() != presetId ||
            presetId.isEmpty) {
          throw invalidSemanticField(
            'placements[$index].presetId',
            'a nonblank trimmed preset ID',
          );
        }
        _surfacePreset(context.manifest, presetId);
        presetIds.add(presetId);
        placements.add(
          SurfaceCellPlacement(x: x, y: y, surfacePresetId: presetId),
        );
      }
      final replaced = replaceSurfacePlacements(
        layer: beforeLayer,
        mapSize: map.size,
        placements: placements,
      ) as SurfaceLayer;
      final layers = List<MapLayer>.of(map.layers);
      final layerIndex = layers.indexWhere((layer) => layer.id == layerId);
      layers[layerIndex] = replaced;
      map = map.copyWith(layers: layers);
      changedCells = _changedSurfaceCells(beforeLayer, replaced);
      preview.addAll({
        'presetIds': presetIds.toList()..sort(),
        'placementCount': placements.length,
      });
    } else {
      _surfaceLayer(map, layerId);
      late final Map<String, Object?> operation;
      switch (actionId) {
        case 'surface.paint':
          final presetId = parameters.string('presetId');
          _surfacePreset(context.manifest, presetId);
          operation = {
            'kind': 'region.paint',
            'layerId': layerId,
            'x': parameters.integer('x'),
            'y': parameters.integer('y'),
            'value': presetId,
          };
          preview['presetId'] = presetId;
        case 'surface.erase':
          operation = {
            'kind': 'region.erase',
            'layerId': layerId,
            'x': parameters.integer('x'),
            'y': parameters.integer('y'),
          };
        case 'surface.erase_area':
          operation = {
            'kind': 'region.erase',
            'layerId': layerId,
            'x': parameters.integer('x'),
            'y': parameters.integer('y'),
            'width': parameters.integer('width'),
            'height': parameters.integer('height'),
          };
        case 'surface.clear':
          operation = {
            'kind': 'region.erase',
            'layerId': layerId,
            'x': 0,
            'y': 0,
            'width': map.size.width,
            'height': map.size.height,
          };
        default:
          throw StateError('unreachable surface action');
      }
      final result = _regions.apply(map, operation);
      map = result.map;
      changedCells = result.changedCells;
    }

    return context.draft(
      SemanticMapEdit(
        map: map,
        layerId: layerId,
        operation: actionId,
        changedCells: changedCells,
        preview: preview,
      ),
    );
  }
}

ProjectSurfacePreset _surfacePreset(
  ProjectManifest manifest,
  String presetId,
) {
  final preset = manifest.surfaceCatalog.presetById(presetId);
  if (preset != null) return preset;
  throw semanticFailure(
    'surface.preset_missing',
    'The requested surface preset does not exist.',
    details: {'presetId': presetId},
    remediation: const [
      'Create the surface preset or choose an ID returned by project inspection.',
    ],
  );
}

SurfaceLayer _surfaceLayer(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId) {
      if (layer is SurfaceLayer) return layer;
      break;
    }
  }
  throw semanticFailure(
    'surface.layer_invalid',
    'The requested layer is not a surface layer.',
    details: {'layerId': layerId},
  );
}

int _changedSurfaceCells(SurfaceLayer before, SurfaceLayer after) {
  final beforeByCell = {
    for (final placement in before.placements)
      '${placement.x}:${placement.y}': placement.surfacePresetId,
  };
  final afterByCell = {
    for (final placement in after.placements)
      '${placement.x}:${placement.y}': placement.surfacePresetId,
  };
  final coordinates = {...beforeByCell.keys, ...afterByCell.keys};
  return coordinates
      .where(
          (coordinate) => beforeByCell[coordinate] != afterByCell[coordinate])
      .length;
}
```

## `packages/map_authoring/lib/src/domains/maps/autotile_actions.dart`

```dart
import 'dart:convert';

import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../contracts/authoring_request.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'path_actions.dart';
import 'semantic_map_action_support.dart';
import 'surface_actions.dart';
import 'terrain_actions.dart';

final class SemanticAutotileRegion {
  const SemanticAutotileRegion({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  final int x;
  final int y;
  final int width;
  final int height;

  int get right => x + width;
  int get bottom => y + height;

  Map<String, Object?> toJson() => {
        'x': x,
        'y': y,
        'width': width,
        'height': height,
      };
}

final class SemanticAutotileArtifact {
  SemanticAutotileArtifact({
    required this.mapId,
    required this.layerId,
    required this.layerKind,
    required this.seed,
    required this.requestedRegion,
    required this.resolutionRegion,
    required Iterable<Map<String, Object?>> entries,
    required Iterable<Map<String, Object?>> diagnostics,
  })  : entries = List.unmodifiable(
          entries.map((entry) => Map<String, Object?>.unmodifiable(entry)),
        ),
        diagnostics = List.unmodifiable(
          diagnostics.map((entry) => Map<String, Object?>.unmodifiable(entry)),
        ) {
    fingerprint = computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'semantic-autotile.json',
        bytes: utf8.encode(jsonEncode(_payload())),
      ),
    ]);
  }

  final String mapId;
  final String layerId;
  final String layerKind;
  final int seed;
  final SemanticAutotileRegion requestedRegion;
  final SemanticAutotileRegion resolutionRegion;
  final List<Map<String, Object?>> entries;
  final List<Map<String, Object?>> diagnostics;
  late final String fingerprint;

  bool get isValid => diagnostics.isEmpty;

  Map<String, Object?> _payload() => {
        'mapId': mapId,
        'layerId': layerId,
        'layerKind': layerKind,
        'seed': seed,
        'requestedRegion': requestedRegion.toJson(),
        'resolutionRegion': resolutionRegion.toJson(),
        'entryCount': entries.length,
        'entries': entries,
        'diagnosticCount': diagnostics.length,
        'diagnostics': diagnostics,
        'rawTilesetRequired': false,
      };

  Map<String, Object?> toJson() => {
        ..._payload(),
        'fingerprint': fingerprint,
      };
}

/// Renderer-neutral semantic resolution for terrain, path, surface, and native
/// Smart Tile layers. Derived roles and variants are never persisted in maps.
final class SemanticAutotileResolver {
  const SemanticAutotileResolver();

  static const int maxResolutionCells = 4096;

  SemanticAutotileArtifact preview({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    SemanticAutotileRegion? region,
  }) =>
      resolve(
        manifest: manifest,
        map: map,
        layerId: layerId,
        seed: seed,
        preferredPresetId: preferredPresetId,
        region: region,
      );

  SemanticAutotileArtifact rebuildRegion({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    required SemanticAutotileRegion region,
  }) =>
      resolve(
        manifest: manifest,
        map: map,
        layerId: layerId,
        seed: seed,
        preferredPresetId: preferredPresetId,
        region: region,
      );

  List<Map<String, Object?>> validate({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    SemanticAutotileRegion? region,
  }) =>
      resolve(
        manifest: manifest,
        map: map,
        layerId: layerId,
        seed: seed,
        preferredPresetId: preferredPresetId,
        region: region,
      ).diagnostics;

  SemanticAutotileArtifact resolve({
    required ProjectManifest manifest,
    required MapData map,
    required String layerId,
    required int seed,
    String? preferredPresetId,
    SemanticAutotileRegion? region,
  }) {
    final requested = region ??
        SemanticAutotileRegion(
          x: 0,
          y: 0,
          width: map.size.width,
          height: map.size.height,
        );
    _requireRegion(requested, map.size);
    final resolution = _expandHalo(requested, map.size);
    if (resolution.width * resolution.height > maxResolutionCells) {
      throw semanticFailure(
        'autotile.region_too_large',
        'The autotile resolution region exceeds the bounded preview limit.',
        details: {
          'cellCount': resolution.width * resolution.height,
          'maxResolutionCells': maxResolutionCells,
        },
        remediation: const ['Request a smaller region and rebuild in chunks.'],
      );
    }
    final layer =
        map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
    if (layer == null) {
      throw semanticFailure(
        'map.layer_missing',
        'The requested autotile layer does not exist.',
        details: {'layerId': layerId},
      );
    }
    final entries = <Map<String, Object?>>[];
    final diagnostics = <Map<String, Object?>>[];
    final diagnosticKeys = <String>{};
    void diagnose(
      String key,
      String code,
      String message,
      List<String> remediation, {
      Map<String, Object?> details = const {},
    }) {
      if (!diagnosticKeys.add(key)) return;
      diagnostics.add({
        'code': code,
        'message': message,
        'details': details,
        'remediation': remediation,
      });
    }

    late final String layerKind;
    switch (layer) {
      case TerrainLayer terrain:
        layerKind = 'terrain';
        ProjectTerrainPreset? preferred;
        if (preferredPresetId != null) {
          preferred = manifest.terrainPresets
              .where((preset) => preset.id == preferredPresetId)
              .firstOrNull;
          if (preferred == null) {
            diagnose(
              'terrain.preferred.$preferredPresetId',
              'terrain.preset_missing',
              'The preferred terrain preset does not exist.',
              const [
                'Create the preset or choose an ID returned by project inspection.',
              ],
              details: {'presetId': preferredPresetId},
            );
          }
        }
        final presets = manifest.terrainPresets.toList()
          ..sort((left, right) => left.id.compareTo(right.id));
        for (var y = resolution.y; y < resolution.bottom; y++) {
          for (var x = resolution.x; x < resolution.right; x++) {
            final terrainType = terrain.terrains[y * map.size.width + x];
            if (terrainType == TerrainType.none) continue;
            final preset = preferred?.terrainType == terrainType
                ? preferred
                : presets
                    .where((candidate) => candidate.terrainType == terrainType)
                    .firstOrNull;
            if (preset == null) {
              diagnose(
                'terrain.type.${terrainType.name}',
                'terrain.preset_missing',
                'No terrain preset resolves this authored terrain type.',
                const [
                  'Create a terrain preset for the reported terrain type.',
                ],
                details: {'terrainType': terrainType.name},
              );
              continue;
            }
            if (preset.variants.isEmpty) {
              diagnose(
                'terrain.variants.${preset.id}',
                'terrain.preset_variants_missing',
                'The terrain preset has no visual variants.',
                const [
                  'Add at least one visual variant to the terrain preset.'
                ],
                details: {'presetId': preset.id},
              );
              continue;
            }
            final chosen = pickTerrainPresetVariantForMapCell(
              variants: preset.variants,
              mapX: x,
              mapY: y,
              phase: seed,
            );
            final variantIndex = preset.variants.indexOf(chosen);
            entries.add({
              'x': x,
              'y': y,
              'presetId': preset.id,
              'terrainType': terrainType.name,
              'role': resolveTerrainPathVariantAt(
                terrains: terrain.terrains,
                mapSize: map.size,
                pos: GridPos(x: x, y: y),
                terrain: terrainType,
              ).name,
              'variantIndex': variantIndex,
              'variantRef': {
                'kind': 'terrain_preset_variant',
                'presetId': preset.id,
                'index': variantIndex,
              },
              'frameCount': chosen.frames.length,
            });
          }
        }
      case PathLayer path:
        layerKind = 'path';
        final preset = manifest.pathPresets
            .where((candidate) => candidate.id == path.presetId)
            .firstOrNull;
        if (preset == null) {
          diagnose(
            'path.preset.${path.presetId}',
            'path.preset_missing',
            'The path layer references a missing preset.',
            const [
              'Assign a valid preset with path.assign_preset before rebuilding.',
            ],
            details: {'presetId': path.presetId},
          );
        } else {
          final patternPreset = manifest.pathPatternPresets
              .where((candidate) => candidate.basePathPresetId == preset.id)
              .firstOrNull;
          for (var y = resolution.y; y < resolution.bottom; y++) {
            for (var x = resolution.x; x < resolution.right; x++) {
              if (!path.cells[y * map.size.width + x]) continue;
              final role = resolvePathVariantAt(
                cells: path.cells,
                mapSize: map.size,
                pos: GridPos(x: x, y: y),
              );
              final mapping = preset.variants
                  .where((candidate) => candidate.variant == role)
                  .firstOrNull;
              final patternResolution = patternPreset == null
                  ? null
                  : resolvePathPatternVisual(
                      pathPatternPreset: patternPreset,
                      basePathPreset: preset,
                      resolvedVariant: role,
                      mapX: x,
                      mapY: y,
                    );
              if (mapping == null && patternResolution == null) {
                diagnose(
                  'path.variant.${preset.id}.${role.name}',
                  'path.variant_missing',
                  'The path preset does not map a resolved autotile role.',
                  const ['Map the reported role in the path preset.'],
                  details: {'presetId': preset.id, 'role': role.name},
                );
              }
              entries.add({
                'x': x,
                'y': y,
                'presetId': preset.id,
                'role': role.name,
                'variantRef': {
                  'kind': 'path_preset_variant',
                  'presetId': preset.id,
                  'role': role.name,
                },
                'frameCount': patternResolution?.frames.length ??
                    mapping?.frames.length ??
                    0,
                if (patternResolution != null)
                  'resolutionKind': patternResolution.kind.name,
              });
            }
          }
        }
      case SurfaceLayer surface:
        layerKind = 'surface';
        final placements = surface.placements.toList()
          ..sort((left, right) {
            final y = left.y.compareTo(right.y);
            return y != 0 ? y : left.x.compareTo(right.x);
          });
        for (final placement in placements) {
          if (!_contains(resolution, placement.x, placement.y)) continue;
          final preset =
              manifest.surfaceCatalog.presetById(placement.surfacePresetId);
          if (preset == null) {
            diagnose(
              'surface.preset.${placement.surfacePresetId}',
              'surface.preset_missing',
              'A surface placement references a missing preset.',
              const [
                'Create the preset or repaint the placement with a valid preset.',
              ],
              details: {'presetId': placement.surfacePresetId},
            );
            continue;
          }
          final role = resolveSurfaceVariantRoleForPlacement(
            placements: surface.placements,
            x: placement.x,
            y: placement.y,
            surfacePresetId: placement.surfacePresetId,
          );
          final animationId = _surfaceAnimationId(preset, role);
          if (animationId == null) {
            diagnose(
              'surface.role.${preset.id}.${role.name}',
              'surface.variant_missing',
              'The surface preset cannot resolve this autotile role.',
              const ['Add the reported role or an isolated fallback.'],
              details: {'presetId': preset.id, 'role': role.name},
            );
          }
          if (animationId != null &&
              manifest.surfaceCatalog.animationById(animationId) == null) {
            diagnose(
              'surface.animation.$animationId',
              'surface.animation_missing',
              'The resolved surface animation does not exist.',
              const ['Create the animation or update the surface preset role.'],
              details: {'presetId': preset.id, 'animationId': animationId},
            );
          }
          entries.add({
            'x': placement.x,
            'y': placement.y,
            'presetId': preset.id,
            'role': role.name,
            if (animationId != null) ...{
              'animationId': animationId,
              'variantRef': {
                'kind': 'surface_animation',
                'animationId': animationId,
              },
            },
          });
        }
      case SmartTileLayer smart:
        layerKind = 'smart_tile';
        final preset = manifest.smartTileCatalog.presets
            .where((candidate) => candidate.id == smart.presetId)
            .firstOrNull;
        if (preset == null) {
          diagnose(
            'smart.preset.${smart.presetId}',
            'autotile.preset_missing',
            'The Smart Tile layer references a missing preset.',
            const ['Assign a published Smart Tile preset to the layer.'],
            details: {'presetId': smart.presetId},
          );
        } else {
          for (var y = resolution.y; y < resolution.bottom; y++) {
            for (var x = resolution.x; x < resolution.right; x++) {
              final neighborhood = smartTileNeighborhoodForLayerCell(
                layer: smart,
                map: map,
                preset: preset,
                x: x,
                y: y,
              );
              final resolved = resolveSmartTile(
                preset: preset,
                materials: manifest.smartTileCatalog.materials,
                neighborhood: neighborhood,
                x: x,
                y: y,
                mapId: map.id,
                layerId: layerId,
                projectSeed: seed,
                layerSeed: smart.layerSeed,
              );
              if (resolved.status ==
                  SmartTileResolutionStatus.noCenterMaterial) {
                continue;
              }
              if (resolved.status != SmartTileResolutionStatus.resolved) {
                diagnose(
                  'smart.resolve.${resolved.status.name}',
                  'autotile.unresolved',
                  resolved.message,
                  const ['Repair the Smart Tile rules or candidate weights.'],
                  details: {'status': resolved.status.name},
                );
              }
              entries.add({
                'x': x,
                'y': y,
                'presetId': preset.id,
                'status': resolved.status.name,
                if (resolved.ruleId != null) 'ruleId': resolved.ruleId,
                if (resolved.candidate != null)
                  'candidateId': resolved.candidate!.id,
                if (resolved.candidate != null)
                  'variantRef': {
                    'kind': 'smart_tile_candidate',
                    'presetId': preset.id,
                    'candidateId': resolved.candidate!.id,
                  },
                if (resolved.deterministicHash != null)
                  'deterministicHash': resolved.deterministicHash,
              });
            }
          }
        }
      case TileLayer() ||
            CollisionLayer() ||
            ObjectLayer() ||
            EnvironmentLayer() ||
            BorderLayer():
        throw semanticFailure(
          'autotile.layer_unsupported',
          'This layer kind has no semantic autotile resolver.',
          details: {'layerId': layerId},
        );
    }
    return SemanticAutotileArtifact(
      mapId: map.id,
      layerId: layerId,
      layerKind: layerKind,
      seed: seed,
      requestedRegion: requested,
      resolutionRegion: resolution,
      entries: entries,
      diagnostics: diagnostics,
    );
  }
}

final class AutotileActions {
  const AutotileActions({
    SemanticAutotileResolver resolver = const SemanticAutotileResolver(),
  }) : _resolver = resolver;

  final SemanticAutotileResolver _resolver;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    semanticActionDescriptor(
      'autotile.apply',
      'Apply a semantic edit with a deterministic autotile preview',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    if (planning.request.actionId != 'autotile.apply') {
      throw semanticFailure(
        'map.action_unsupported',
        'The requested autotile mutation action is unsupported.',
        details: {'actionId': planning.request.actionId},
      );
    }
    if (planning.request.actionVersion != 1) {
      throw semanticFailure(
        'map.action_version_unsupported',
        'The requested autotile action version is unsupported.',
      );
    }
    final parameters = SemanticParameters(
      planning.request.parameters,
      allowed: const {
        'mapId',
        'semanticActionId',
        'semanticParameters',
        'previewRegion',
      },
    );
    final mapId = parameters.string('mapId');
    final semanticActionId = parameters.string('semanticActionId');
    final semanticParameters = parameters.object('semanticParameters');
    if (semanticParameters.containsKey('mapId')) {
      throw semanticFailure(
        'map.request_invalid',
        'semanticParameters must not override the outer mapId.',
      );
    }
    final innerRequest = AuthoringRequest(
      requestId: '${planning.request.requestId}_semantic',
      actionId: semanticActionId,
      actionVersion: 1,
      workspaceHandle: planning.request.workspaceHandle,
      parameters: {'mapId': mapId, ...semanticParameters},
      expectedRevision: planning.request.expectedRevision,
      idempotencyKey: planning.request.idempotencyKey,
      dryRun: true,
    );
    final innerContext = AuthoringPlanningContext(
      snapshot: planning.snapshot,
      request: innerRequest,
      planId: planning.planId,
      seed: planning.seed,
    );
    final semanticDraft = switch (semanticActionId.split('.').first) {
      'terrain' => const TerrainActions().build(innerContext),
      'path' => const PathActions().build(innerContext),
      'surface' => const SurfaceActions().build(innerContext),
      _ => throw semanticFailure(
          'autotile.semantic_action_unsupported',
          'Autotile apply accepts only terrain, path, or surface actions.',
          details: {'semanticActionId': semanticActionId},
        ),
    };
    final afterBytes = semanticDraft.changeSet.changes.single.afterBytes;
    if (afterBytes == null) {
      throw StateError('semantic mutation unexpectedly deletes its map');
    }
    late final MapData projected;
    try {
      projected = MapData.fromJson(
        jsonDecode(utf8.decode(afterBytes)) as Map<String, dynamic>,
      );
    } on Object {
      throw semanticFailure(
        'autotile.projected_map_invalid',
        'The semantic action did not produce a readable map preview.',
      );
    }
    final layerId = semanticParameters['layerId'];
    if (layerId is! String || layerId.trim() != layerId || layerId.isEmpty) {
      throw invalidSemanticField(
        'semanticParameters.layerId',
        'a nonblank trimmed string',
      );
    }
    final previewRegion = parameters.contains('previewRegion')
        ? _regionFromJson(parameters.object('previewRegion'))
        : _inferSemanticRegion(semanticParameters, projected.size);
    final preferredPresetId = semanticParameters['presetId'];
    final artifact = _resolver.preview(
      manifest: planning.snapshot.manifest,
      map: projected,
      layerId: layerId,
      seed: planning.seed,
      preferredPresetId: preferredPresetId is String ? preferredPresetId : null,
      region: previewRegion,
    );
    return AuthoringMutationDraft(
      changeSet: semanticDraft.changeSet,
      preview: {
        ...semanticDraft.preview,
        'operation': 'autotile.apply',
        'semanticActionId': semanticActionId,
        'autotile': artifact.toJson(),
      },
      referenceImpact: semanticDraft.referenceImpact,
      artifacts: semanticDraft.artifacts,
    );
  }
}

SemanticAutotileRegion _regionFromJson(Map<String, Object?> value) {
  final unknown = value.keys
      .where((key) => !const {'x', 'y', 'width', 'height'}.contains(key))
      .toList()
    ..sort();
  if (unknown.isNotEmpty) {
    throw semanticFailure(
      'map.request_invalid',
      'The autotile preview region contains unsupported fields.',
      details: {'unknownFields': unknown},
    );
  }
  int read(String key) {
    final raw = value[key];
    if (raw is! int) {
      throw invalidSemanticField('previewRegion.$key', 'an integer');
    }
    return raw;
  }

  return SemanticAutotileRegion(
    x: read('x'),
    y: read('y'),
    width: read('width'),
    height: read('height'),
  );
}

SemanticAutotileRegion? _inferSemanticRegion(
  Map<String, Object?> parameters,
  GridSize mapSize,
) {
  final x = parameters['x'];
  final y = parameters['y'];
  if (x is! int || y is! int) return null;
  final rawWidth = parameters['width'];
  final rawHeight = parameters['height'];
  if (rawWidth != null && rawWidth is! int) return null;
  if (rawHeight != null && rawHeight is! int) return null;
  final region = SemanticAutotileRegion(
    x: x,
    y: y,
    width: rawWidth as int? ?? 1,
    height: rawHeight as int? ?? 1,
  );
  _requireRegion(region, mapSize);
  return region;
}

void _requireRegion(SemanticAutotileRegion region, GridSize mapSize) {
  if (region.x < 0 ||
      region.y < 0 ||
      region.width <= 0 ||
      region.height <= 0 ||
      region.right > mapSize.width ||
      region.bottom > mapSize.height) {
    throw semanticFailure(
      'autotile.region_out_of_bounds',
      'The autotile region is outside map bounds.',
      details: region.toJson(),
    );
  }
}

SemanticAutotileRegion _expandHalo(
  SemanticAutotileRegion region,
  GridSize mapSize,
) {
  final x = region.x > 0 ? region.x - 1 : 0;
  final y = region.y > 0 ? region.y - 1 : 0;
  final right = region.right < mapSize.width ? region.right + 1 : mapSize.width;
  final bottom =
      region.bottom < mapSize.height ? region.bottom + 1 : mapSize.height;
  return SemanticAutotileRegion(
    x: x,
    y: y,
    width: right - x,
    height: bottom - y,
  );
}

bool _contains(SemanticAutotileRegion region, int x, int y) =>
    x >= region.x && y >= region.y && x < region.right && y < region.bottom;

String? _surfaceAnimationId(
  ProjectSurfacePreset preset,
  SurfaceVariantRole role,
) {
  final exact = preset.animationIdForRole(role)?.trim();
  if (exact != null && exact.isNotEmpty) return exact;
  final isolated =
      preset.animationIdForRole(SurfaceVariantRole.isolated)?.trim();
  if (isolated != null && isolated.isNotEmpty) return isolated;
  for (final reference in preset.variantAnimations.refs) {
    final id = reference.animationId.trim();
    if (id.isNotEmpty) return id;
  }
  return null;
}
```

## `packages/map_authoring/test/domains/maps/semantic_painting_test.dart`

```dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('semantic map actions', () {
    test('advertises typed preset-based terrain, path, and surface actions',
        () {
      expect(
        TerrainActions.descriptors.map((descriptor) => descriptor.id),
        [
          'terrain.erase',
          'terrain.erase_pattern',
          'terrain.fill',
          'terrain.paint',
          'terrain.paint_pattern',
          'terrain.replace',
        ],
      );
      expect(
        PathActions.descriptors.map((descriptor) => descriptor.id),
        containsAll([
          'path.paint',
          'path.erase',
          'path.fill',
          'path.assign_preset',
          'path.set_properties',
          'path.set_animation_mode',
        ]),
      );
      expect(
        SurfaceActions.descriptors.map((descriptor) => descriptor.id),
        containsAll([
          'surface.paint',
          'surface.erase',
          'surface.erase_area',
          'surface.clear',
          'surface.replace_placements',
        ]),
      );
      final dispatcherIds = MapMutationDispatcher.canonical()
          .descriptors
          .map((descriptor) => descriptor.id);
      expect(dispatcherIds, contains('terrain.paint'));
      expect(dispatcherIds, contains('path.paint'));
      expect(dispatcherIds, contains('surface.paint'));
      expect(dispatcherIds, contains('autotile.apply'));
    });

    test('terrain fill resolves a preset ID into semantic terrain cells', () {
      final snapshot = _snapshot();
      final draft = const TerrainActions().build(
        _context(
          snapshot,
          actionId: 'terrain.fill',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'presetId': 'grass_visual',
            'x': 1,
            'y': 0,
            'width': 2,
            'height': 2,
          },
        ),
      );

      final updated = _afterMap(draft);
      final cells = (updated.layers[0] as TerrainLayer).terrains;
      expect(cells[1], TerrainType.grass);
      expect(cells[2], TerrainType.grass);
      expect(cells[5], TerrainType.grass);
      expect(cells[6], TerrainType.grass);
      expect(draft.preview['presetId'], 'grass_visual');
      expect(jsonEncode(draft.preview), isNot(contains('tilesetId')));
    });

    test('terrain pattern, replace, and erase remain preset-driven', () {
      final stampedDraft = const TerrainActions().build(
        _context(
          _snapshot(),
          actionId: 'terrain.paint_pattern',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 2,
            'presetIds': [
              'grass_visual',
              'dirt_visual',
              'dirt_visual',
              'grass_visual',
            ],
          },
        ),
      );
      final stamped = _afterMap(stampedDraft);
      expect(
        (stamped.layers[0] as TerrainLayer).terrains.take(2),
        [TerrainType.grass, TerrainType.dirt],
      );

      final replacedDraft = const TerrainActions().build(
        _context(
          _snapshot(map: stamped),
          actionId: 'terrain.replace',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'fromPresetId': 'dirt_visual',
            'toPresetId': 'grass_visual',
          },
        ),
      );
      final replaced = _afterMap(replacedDraft);
      expect(
        (replaced.layers[0] as TerrainLayer)
            .terrains
            .where((cell) => cell == TerrainType.dirt),
        isEmpty,
      );

      final erasedDraft = const TerrainActions().build(
        _context(
          _snapshot(map: replaced),
          actionId: 'terrain.erase_pattern',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'terrain',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 2,
          },
        ),
      );
      expect(
        (_afterMap(erasedDraft).layers[0] as TerrainLayer).terrains[0],
        TerrainType.none,
      );
    });

    test('path paint validates and assigns its preset without raw tiles', () {
      final snapshot = _snapshot();
      final draft = const PathActions().build(
        _context(
          snapshot,
          actionId: 'path.paint',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'presetId': 'road_path',
            'x': 2,
            'y': 1,
          },
        ),
      );

      final path = _afterMap(draft).layers[1] as PathLayer;
      expect(path.presetId, 'road_path');
      expect(path.cells[6], isTrue);
      expect(draft.preview['presetId'], 'road_path');
      expect(jsonEncode(draft.preview), isNot(contains('tilesetId')));
    });

    test('path fill, properties, and animation mode preserve semantic preset',
        () {
      final filledDraft = const PathActions().build(
        _context(
          _snapshot(),
          actionId: 'path.fill',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'presetId': 'road_path',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 1,
          },
        ),
      );
      final filled = _afterMap(filledDraft);
      expect((filled.layers[1] as PathLayer).cells.take(2), [true, true]);

      final propertiesDraft = const PathActions().build(
        _context(
          _snapshot(map: filled),
          actionId: 'path.set_properties',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'properties': {'movement': 'slow'},
          },
        ),
      );
      final withProperties = _afterMap(propertiesDraft);
      expect(
        (withProperties.layers[1] as PathLayer).properties,
        {'movement': 'slow'},
      );

      final animationDraft = const PathActions().build(
        _context(
          _snapshot(map: withProperties),
          actionId: 'path.set_animation_mode',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'path',
            'animationMode': 'always_active',
          },
        ),
      );
      final path = _afterMap(animationDraft).layers[1] as PathLayer;
      expect(path.animationMode, PathAnimationMode.alwaysActive);
      expect(path.presetId, 'road_path');
    });

    test('surface paint and clear use catalog preset identities', () {
      final snapshot = _snapshot();
      final paintedDraft = const SurfaceActions().build(
        _context(
          snapshot,
          actionId: 'surface.paint',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
            'presetId': 'water_surface',
            'x': 3,
            'y': 2,
          },
        ),
      );
      final painted = _afterMap(paintedDraft);
      final surface = painted.layers[2] as SurfaceLayer;
      expect(surface.placements.single.surfacePresetId, 'water_surface');

      final paintedSnapshot = _snapshot(map: painted);
      final clearedDraft = const SurfaceActions().build(
        _context(
          paintedSnapshot,
          actionId: 'surface.clear',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
          },
        ),
      );
      expect(
        (_afterMap(clearedDraft).layers[2] as SurfaceLayer).placements,
        isEmpty,
      );
    });

    test('surface replacement and area erase validate every preset ID', () {
      final replacedDraft = const SurfaceActions().build(
        _context(
          _snapshot(),
          actionId: 'surface.replace_placements',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
            'placements': [
              {'x': 0, 'y': 0, 'presetId': 'water_surface'},
              {'x': 1, 'y': 0, 'presetId': 'water_surface'},
              {'x': 3, 'y': 2, 'presetId': 'water_surface'},
            ],
          },
        ),
      );
      final replaced = _afterMap(replacedDraft);
      expect((replaced.layers[2] as SurfaceLayer).placements, hasLength(3));

      final erasedDraft = const SurfaceActions().build(
        _context(
          _snapshot(map: replaced),
          actionId: 'surface.erase_area',
          parameters: const {
            'mapId': 'fixture',
            'layerId': 'surface',
            'x': 0,
            'y': 0,
            'width': 2,
            'height': 1,
          },
        ),
      );
      final remaining =
          (_afterMap(erasedDraft).layers[2] as SurfaceLayer).placements;
      expect(remaining, hasLength(1));
      expect(remaining.single.x, 3);
    });

    test('missing semantic presets return stable repairable diagnostics', () {
      final snapshot = _snapshot();
      for (final action in [
        (
          build: (AuthoringPlanningContext context) =>
              const TerrainActions().build(context),
          actionId: 'terrain.paint',
          layerId: 'terrain',
          code: 'terrain.preset_missing',
        ),
        (
          build: (AuthoringPlanningContext context) =>
              const PathActions().build(context),
          actionId: 'path.paint',
          layerId: 'path',
          code: 'path.preset_missing',
        ),
        (
          build: (AuthoringPlanningContext context) =>
              const SurfaceActions().build(context),
          actionId: 'surface.paint',
          layerId: 'surface',
          code: 'surface.preset_missing',
        ),
      ]) {
        expect(
          () => action.build(
            _context(
              snapshot,
              actionId: action.actionId,
              parameters: {
                'mapId': 'fixture',
                'layerId': action.layerId,
                'presetId': 'missing_preset',
                'x': 0,
                'y': 0,
              },
            ),
          ),
          throwsA(
            isA<MapAuthoringException>()
                .having((error) => error.code, 'code', action.code)
                .having(
                  (error) => error.remediation,
                  'remediation',
                  isNotEmpty,
                ),
          ),
        );
      }
    });
  });
}

MapData _afterMap(AuthoringMutationDraft draft) => MapData.fromJson(
      jsonDecode(utf8.decode(draft.changeSet.changes.single.afterBytes!))
          as Map<String, dynamic>,
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_${actionId.replaceAll('.', '_')}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'ws_fixture',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
        dryRun: true,
      ),
      planId: 'plan_${actionId.replaceAll('.', '_')}',
      seed: 17,
    );

ProjectSnapshot _snapshot({MapData? map}) {
  final resolvedMap = map ?? _map();
  final manifest = _manifest();
  final manifestBytes = _encode(manifest.toJson());
  final mapBytes = _encode(resolvedMap.toJson());
  return ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: manifestBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: manifest,
    maps: [resolvedMap],
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: manifestBytes,
        ),
      ]),
      'map:fixture': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/fixture.json',
          bytes: mapBytes,
        ),
      ]),
    },
    resourceBytes: {'project': manifestBytes, 'map:fixture': mapBytes},
  );
}

ProjectManifest _manifest() => ProjectManifest(
      name: 'Semantic Fixture',
      version: ProjectVersion.v3,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [],
      terrainPresets: [
        ProjectTerrainPreset(
          id: 'grass_visual',
          name: 'Grass',
          terrainType: TerrainType.grass,
          variants: [
            TerrainPresetVariant(
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 0, y: 0)),
              ],
              weight: 1,
            ),
            TerrainPresetVariant(
              frames: const [
                TilesetVisualFrame(source: TilesetSourceRect(x: 1, y: 0)),
              ],
              weight: 2,
            ),
          ],
        ),
        const ProjectTerrainPreset(
          id: 'dirt_visual',
          name: 'Dirt',
          terrainType: TerrainType.dirt,
        ),
      ],
      pathPresets: const [
        ProjectPathPreset(
          id: 'road_path',
          name: 'Road',
          variants: [],
        ),
      ],
      surfaceCatalog: ProjectSurfaceCatalog(
        presets: [
          ProjectSurfacePreset(
            id: 'water_surface',
            name: 'Water',
            variantAnimations: SurfaceVariantAnimationRefSet(
              refs: [
                SurfaceVariantAnimationRef(
                  role: SurfaceVariantRole.isolated,
                  animationId: 'water_idle',
                ),
              ],
            ),
          ),
        ],
      ),
    );

MapData _map() => MapData(
      id: 'fixture',
      name: 'Fixture',
      size: const GridSize(width: 4, height: 3),
      version: ProjectVersion.v3,
      visualStack: MapVisualStackConfig.canonicalV1,
      layers: [
        MapLayer.terrain(
          id: 'terrain',
          name: 'Terrain',
          terrains: List.filled(12, TerrainType.none),
        ),
        MapLayer.path(
          id: 'path',
          name: 'Path',
          cells: List.filled(12, false),
        ),
        const MapLayer.surface(id: 'surface', name: 'Surface'),
      ],
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
```

## `packages/map_authoring/test/domains/maps/autotile_determinism_test.dart`

```dart
import 'dart:convert';

import 'package:map_authoring/map_authoring.dart';
import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('SemanticAutotileResolver', () {
    test('same seed produces the same bounded semantic artifact', () {
      final fixture = _fixture();
      const resolver = SemanticAutotileResolver();

      final first = resolver.preview(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 41,
        preferredPresetId: 'grass_visual',
        region: const SemanticAutotileRegion(x: 1, y: 1, width: 2, height: 2),
      );
      final second = resolver.resolve(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 41,
        preferredPresetId: 'grass_visual',
        region: const SemanticAutotileRegion(x: 1, y: 1, width: 2, height: 2),
      );

      expect(second.toJson(), first.toJson());
      expect(second.fingerprint, first.fingerprint);
      expect(first.seed, 41);
      expect(first.requestedRegion.width, 2);
      expect(first.resolutionRegion.width, 4, reason: 'one-cell halo');
      expect(first.entries, isNotEmpty);
      expect(jsonEncode(first.toJson()), isNot(contains('tilesetId')));
      expect(jsonEncode(first.toJson()), isNot(contains('sourceRect')));
    });

    test('weighted terrain variants are deterministically seed-sensitive', () {
      final fixture = _fixture();
      const resolver = SemanticAutotileResolver();
      final first = resolver.resolve(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 0,
        preferredPresetId: 'grass_visual',
      );
      final shifted = resolver.resolve(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 1,
        preferredPresetId: 'grass_visual',
      );

      expect(first.fingerprint, isNot(shifted.fingerprint));
      expect(
        first.entries.map((entry) => entry['variantIndex']).toList(),
        isNot(shifted.entries.map((entry) => entry['variantIndex']).toList()),
      );
    });

    test('rebuild and validation expose repairable missing-preset diagnostics',
        () {
      final fixture = _fixture(manifest: _manifest(terrainPresets: const []));
      const resolver = SemanticAutotileResolver();

      final artifact = resolver.rebuildRegion(
        manifest: fixture.snapshot.manifest,
        map: fixture.map,
        layerId: 'terrain',
        seed: 7,
        region: const SemanticAutotileRegion(x: 0, y: 0, width: 2, height: 2),
      );

      expect(artifact.diagnostics, isNotEmpty);
      expect(artifact.diagnostics.first['code'], 'terrain.preset_missing');
      expect(artifact.diagnostics.first['remediation'], isNotEmpty);
      expect(
        resolver.validate(
          manifest: fixture.snapshot.manifest,
          map: fixture.map,
          layerId: 'terrain',
          seed: 7,
        ),
        isNotEmpty,
      );
    });
  });

  group('AutotileActions', () {
    test('preview/apply wraps the exact semantic change set and freezes seed',
        () {
      final fixture = _fixture(emptyTerrain: true);
      final directContext = _context(
        fixture.snapshot,
        actionId: 'terrain.fill',
        parameters: const {
          'mapId': 'fixture',
          'layerId': 'terrain',
          'presetId': 'grass_visual',
          'x': 0,
          'y': 0,
          'width': 2,
          'height': 2,
        },
        seed: 99,
      );
      final direct = const TerrainActions().build(directContext);
      final wrapped = const AutotileActions().build(
        _context(
          fixture.snapshot,
          actionId: 'autotile.apply',
          parameters: const {
            'mapId': 'fixture',
            'semanticActionId': 'terrain.fill',
            'semanticParameters': {
              'layerId': 'terrain',
              'presetId': 'grass_visual',
              'x': 0,
              'y': 0,
              'width': 2,
              'height': 2,
            },
            'previewRegion': {'x': 0, 'y': 0, 'width': 2, 'height': 2},
          },
          seed: 99,
        ),
      );

      expect(
        wrapped.changeSet.changes.single.afterBytes,
        direct.changeSet.changes.single.afterBytes,
      );
      expect(wrapped.changeSet.diff.toJson(), direct.changeSet.diff.toJson());
      final artifact = wrapped.preview['autotile']! as Map<String, Object?>;
      expect(artifact['seed'], 99);
      expect(artifact['fingerprint'], startsWith('sha256:'));
      expect(jsonEncode(artifact), isNot(contains('tilesetId')));
    });
  });
}

({ProjectSnapshot snapshot, MapData map}) _fixture({
  ProjectManifest? manifest,
  bool emptyTerrain = false,
}) {
  final map = MapData(
    id: 'fixture',
    name: 'Fixture',
    size: const GridSize(width: 4, height: 4),
    version: ProjectVersion.v3,
    visualStack: MapVisualStackConfig.canonicalV1,
    layers: [
      MapLayer.terrain(
        id: 'terrain',
        name: 'Terrain',
        terrains: List.filled(
          16,
          emptyTerrain ? TerrainType.none : TerrainType.grass,
        ),
      ),
    ],
  );
  final resolvedManifest = manifest ?? _manifest();
  final projectBytes = _encode(resolvedManifest.toJson());
  final mapBytes = _encode(map.toJson());
  final snapshot = ProjectSnapshot(
    projectHandle: const ProjectHandle('prj_fixture'),
    revision: computeNarrativeProjectFingerprint([
      NarrativeProjectFingerprintEntry(
        relativePath: 'project.json',
        bytes: projectBytes,
      ),
      NarrativeProjectFingerprintEntry(
        relativePath: 'maps/fixture.json',
        bytes: mapBytes,
      ),
    ]),
    manifest: resolvedManifest,
    maps: [map],
    resourceFingerprints: {
      'project': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'project.json',
          bytes: projectBytes,
        ),
      ]),
      'map:fixture': computeNarrativeProjectFingerprint([
        NarrativeProjectFingerprintEntry(
          relativePath: 'maps/fixture.json',
          bytes: mapBytes,
        ),
      ]),
    },
    resourceBytes: {'project': projectBytes, 'map:fixture': mapBytes},
  );
  return (snapshot: snapshot, map: map);
}

ProjectManifest _manifest({
  List<ProjectTerrainPreset>? terrainPresets,
}) =>
    ProjectManifest(
      name: 'Autotile Fixture',
      version: ProjectVersion.v3,
      maps: const [
        ProjectMapEntry(
          id: 'fixture',
          name: 'Fixture',
          relativePath: 'maps/fixture.json',
        ),
      ],
      tilesets: const [],
      terrainPresets: terrainPresets ??
          [
            ProjectTerrainPreset(
              id: 'grass_visual',
              name: 'Grass',
              terrainType: TerrainType.grass,
              variants: [
                TerrainPresetVariant(
                  frames: const [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 0, y: 0),
                    ),
                  ],
                  weight: 1,
                ),
                TerrainPresetVariant(
                  frames: const [
                    TilesetVisualFrame(
                      source: TilesetSourceRect(x: 1, y: 0),
                    ),
                  ],
                  weight: 1,
                ),
              ],
            ),
          ],
    );

AuthoringPlanningContext _context(
  ProjectSnapshot snapshot, {
  required String actionId,
  required Map<String, Object?> parameters,
  required int seed,
}) =>
    AuthoringPlanningContext(
      snapshot: snapshot,
      request: AuthoringRequest(
        requestId: 'request_${actionId.replaceAll('.', '_')}',
        actionId: actionId,
        actionVersion: 1,
        workspaceHandle: 'ws_fixture',
        parameters: parameters,
        expectedRevision: snapshot.revision,
        idempotencyKey: 'idem_${actionId.replaceAll('.', '_')}',
        dryRun: true,
      ),
      planId: 'plan_${actionId.replaceAll('.', '_')}',
      seed: seed,
    );

List<int> _encode(Object? value) =>
    utf8.encode(const JsonEncoder.withIndent('  ').convert(value));
```
