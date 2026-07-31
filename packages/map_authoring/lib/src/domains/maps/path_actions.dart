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
