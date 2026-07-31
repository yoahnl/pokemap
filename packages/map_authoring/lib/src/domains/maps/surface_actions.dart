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
