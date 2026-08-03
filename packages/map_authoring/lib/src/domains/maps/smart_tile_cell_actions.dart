import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_native_transition_guard.dart';

/// Stable refusal returned while Wang edge/corner painting remains reserved
/// for STN-05. Publication and read-only resolution stay available.
const String smartTileWangPaintRequiresStn05Code =
    'smart_tile.wang_paint_requires_stn05';

/// Canonical, transport-neutral cell-field painting actions.
///
/// One request represents one complete editor gesture. This keeps a drag
/// atomic and gives direct Dart, JSONL, editor and MCP the same undo boundary.
final class SmartTileCellActions {
  const SmartTileCellActions();

  static const int maximumCellsPerGesture = 4096;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor(
      'smart_tile.cell.paint',
      'Paint one atomic Smart Tile cell-field gesture',
    ),
    _descriptor(
      'smart_tile.cell.erase',
      'Erase one atomic Smart Tile cell-field gesture',
    ),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    return switch (planning.request.actionId) {
      'smart_tile.cell.paint' => _mutate(planning, erase: false),
      'smart_tile.cell.erase' => _mutate(planning, erase: true),
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested Smart Tile cell action is unsupported.',
          details: <String, Object?>{
            'actionId': planning.request.actionId,
          },
        ),
    };
  }

  AuthoringMutationDraft _mutate(
    AuthoringPlanningContext planning, {
    required bool erase,
  }) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: erase
          ? const <String>{'layerId', 'cells'}
          : const <String>{'layerId', 'materialId', 'cells'},
    );
    final operation = erase ? 'smart_tile.cell.erase' : 'smart_tile.cell.paint';
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: operation,
      layerId: layerId,
    );
    final layer = _layer(context.map, layerId);
    if (layer.field is! SmartTileCellField) {
      throw semanticFailure(
        smartTileWangPaintRequiresStn05Code,
        'Drawing on Wang edge, corner, and mixed fields is available with '
        'STN-05.',
        details: <String, Object?>{
          'mapId': context.map.id,
          'layerId': layerId,
          'fieldKind': layer.field.runtimeType.toString(),
          'operation': operation,
        },
        remediation: const <String>[
          'Test or publish this preset now, then draw it on a map after STN-05.',
        ],
      );
    }

    final cells = _cells(
      context.parameters.list('cells'),
      mapSize: context.map.size,
    );
    final materialId = erase ? null : context.parameters.string('materialId');
    final preset = _preset(context.manifest, layer.presetId);
    if (materialId != null) {
      _requireAllowedMaterial(
        context: context,
        layer: layer,
        preset: preset,
        materialId: materialId,
      );
    }

    var projectedLayer = layer;
    var changedCellCount = 0;
    for (final cell in cells) {
      final before = smartTileMaterialIdAt(
        projectedLayer,
        mapSize: context.map.size,
        x: cell.x,
        y: cell.y,
      );
      if (before == materialId) continue;
      projectedLayer = setSmartTileCellMaterial(
        projectedLayer,
        mapSize: context.map.size,
        x: cell.x,
        y: cell.y,
        materialId: materialId,
      );
      changedCellCount++;
    }
    final projected = replaceSmartTileLayer(
      context.map,
      layer: projectedLayer,
    );
    return context.draft(
      SemanticMapEdit(
        map: projected,
        layerId: layerId,
        operation: operation,
        changedCells: changedCellCount,
        preview: <String, Object?>{
          'presetId': preset.id,
          'usage': preset.usage.name,
          'materialId': materialId,
          'gestureCellCount': cells.length,
          'cells': <Map<String, int>>[
            for (final cell in cells) <String, int>{'x': cell.x, 'y': cell.y},
          ],
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'gesture',
        },
      ),
    );
  }
}

AuthoringActionDescriptor _descriptor(String id, String summary) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.cell.mutation.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const <String>[
        'map',
        'smartTileLayer',
        'smartTilePreset',
        'smartTileMaterial',
      ],
      capabilityIds: const <String>['authoring.smart_tiles'],
      requiredPermissions: const <AuthoringPermission>[
        AuthoringPermission.projectWrite,
      ],
      guarantees: const <AuthoringGuarantee>[
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const <String, Object?>{
        'semanticIds': true,
        'rawTilesetRequired': false,
        'gestureAtomic': true,
        'cellFieldOnly': true,
      },
    );

SmartTileLayer _layer(MapData map, String layerId) {
  for (final layer in map.layers) {
    if (layer.id == layerId && layer is SmartTileLayer) return layer;
  }
  throw semanticFailure(
    'smart_tile.layer_invalid',
    'The requested layer is not a Smart Tile layer.',
    details: <String, Object?>{'layerId': layerId},
  );
}

ProjectSmartTilePreset _preset(ProjectManifest manifest, String presetId) {
  for (final preset in manifest.smartTileCatalog.presets) {
    if (preset.id == presetId) return preset;
  }
  throw semanticFailure(
    'smart_tile.preset_missing',
    'The Smart Tile layer references an unknown preset.',
    details: <String, Object?>{'presetId': presetId},
  );
}

void _requireAllowedMaterial({
  required SemanticMapActionContext context,
  required SmartTileLayer layer,
  required ProjectSmartTilePreset preset,
  required String materialId,
}) {
  final catalogContains = context.manifest.smartTileCatalog.materials
      .any((material) => material.id == materialId);
  final presetAllows = preset.allowedMaterialIds.contains(materialId);
  final paletteContains = layer.materialPalette.contains(materialId);
  if (catalogContains && presetAllows && paletteContains) return;
  throw semanticFailure(
    'smart_tile.cell.material_not_allowed',
    'The material is not available in this Smart Tile layer.',
    details: <String, Object?>{
      'layerId': layer.id,
      'presetId': preset.id,
      'materialId': materialId,
      'catalogContains': catalogContains,
      'presetAllows': presetAllows,
      'paletteContains': paletteContains,
    },
    remediation: const <String>[
      'Choose a material exposed by the published preset.',
    ],
  );
}

List<({int x, int y})> _cells(
  List<Object?> raw, {
  required GridSize mapSize,
}) {
  if (raw.isEmpty) {
    throw invalidSemanticField('cells', 'a non-empty list of coordinates');
  }
  if (raw.length > SmartTileCellActions.maximumCellsPerGesture) {
    throw semanticFailure(
      'smart_tile.cell.gesture_too_large',
      'The Smart Tile gesture exceeds the bounded cell limit.',
      details: <String, Object?>{
        'cellCount': raw.length,
        'maximumCellCount': SmartTileCellActions.maximumCellsPerGesture,
      },
    );
  }
  final cells = <({int x, int y})>[];
  final seen = <(int, int)>{};
  for (var index = 0; index < raw.length; index++) {
    final value = raw[index];
    if (value is! Map || value.keys.any((key) => key is! String)) {
      throw invalidSemanticField('cells[$index]', 'an {x, y} object');
    }
    final cell = Map<String, Object?>.from(value);
    if (cell.length != 2 || !cell.containsKey('x') || !cell.containsKey('y')) {
      throw invalidSemanticField('cells[$index]', 'exactly {x, y}');
    }
    final x = cell['x'];
    final y = cell['y'];
    if (x is! int || y is! int) {
      throw invalidSemanticField('cells[$index]', 'integer x and y values');
    }
    if (x < 0 || y < 0 || x >= mapSize.width || y >= mapSize.height) {
      throw semanticFailure(
        'smart_tile.cell.out_of_bounds',
        'A Smart Tile gesture coordinate is outside the map.',
        details: <String, Object?>{
          'index': index,
          'x': x,
          'y': y,
          'mapWidth': mapSize.width,
          'mapHeight': mapSize.height,
        },
      );
    }
    if (!seen.add((x, y))) {
      throw semanticFailure(
        'smart_tile.cell.duplicate',
        'A Smart Tile gesture contains the same coordinate more than once.',
        details: <String, Object?>{'x': x, 'y': y},
      );
    }
    cells.add((x: x, y: y));
  }
  cells.sort((left, right) {
    final byY = left.y.compareTo(right.y);
    return byY != 0 ? byY : left.x.compareTo(right.x);
  });
  return List.unmodifiable(cells);
}
