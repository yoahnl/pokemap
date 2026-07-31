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
