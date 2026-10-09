import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_native_transition_guard.dart';

/// Canonical, transport-neutral Smart Tile material gesture actions.
///
/// One request represents one complete editor gesture. This keeps a drag
/// atomic and gives direct Dart, JSONL, editor and MCP the same undo boundary.
final class SmartTileCellActions {
  const SmartTileCellActions();

  static const int maximumExplicitCellsPerGesture =
      smartTileMaximumCellsPerGesture;
  static const int maximumCellsPerGesture = maximumExplicitCellsPerGesture;
  static const int maximumStrokesPerBatch = 4096;
  static const int maximumCellsPerBatch = 65536;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable([
    _descriptor(
      'smart_tile.cell.paint',
      'Paint one atomic Smart Tile material gesture',
    ),
    _batchDescriptor(),
    _descriptor(
      'smart_tile.cell.erase',
      'Erase one atomic Smart Tile material gesture',
    ),
    _cornerDescriptor(
        'smart_tile.corner.paint', 'Paint precise Smart Tile corners'),
    _cornerDescriptor(
        'smart_tile.corner.erase', 'Erase precise Smart Tile corners'),
  ]);

  AuthoringMutationDraft build(AuthoringPlanningContext planning) {
    return switch (planning.request.actionId) {
      'smart_tile.cell.paint' => _mutate(planning, erase: false),
      'smart_tile.cell.paint_batch' => _paintBatch(planning),
      'smart_tile.cell.erase' => _mutate(planning, erase: true),
      'smart_tile.corner.paint' => _mutateCorners(planning, erase: false),
      'smart_tile.corner.erase' => _mutateCorners(planning, erase: true),
      _ => throw semanticFailure(
          'map.action_unsupported',
          'The requested Smart Tile cell action is unsupported.',
          details: <String, Object?>{
            'actionId': planning.request.actionId,
          },
        ),
    };
  }

  AuthoringMutationDraft _paintBatch(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const {'layerId', 'strokes'},
    );
    final operation = planning.request.actionId;
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: operation,
      layerId: layerId,
    );
    final layer = _layer(context.map, layerId);
    final preset = _preset(context.manifest, layer.presetId);
    final rawStrokes = context.parameters.list('strokes');
    if (rawStrokes.isEmpty) {
      throw invalidSemanticField(
          'strokes', 'a non-empty list of paint strokes');
    }
    if (rawStrokes.length > maximumStrokesPerBatch) {
      throw semanticFailure(
        'smart_tile.cell.batch_too_large',
        'The Smart Tile batch exceeds the bounded stroke limit.',
        details: {
          'strokeCount': rawStrokes.length,
          'maximumStrokeCount': maximumStrokesPerBatch,
        },
      );
    }
    final ownership = <(int, int), String>{};
    final strokes = <({String materialId, List<({int x, int y})> cells})>[];
    var inputCellCount = 0;
    for (var strokeIndex = 0; strokeIndex < rawStrokes.length; strokeIndex++) {
      final raw = rawStrokes[strokeIndex];
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw invalidSemanticField(
            'strokes[$strokeIndex]', 'a paint stroke object');
      }
      final parameters = SemanticParameters(
        Map<String, Object?>.from(raw),
        allowed: const {'materialId', 'cells'},
      );
      final materialId = parameters.string('materialId');
      _requireAllowedMaterial(
        context: context,
        layer: layer,
        preset: preset,
        materialId: materialId,
      );
      final rawCells = parameters.list('cells');
      inputCellCount += rawCells.length;
      if (inputCellCount > maximumCellsPerBatch) {
        throw semanticFailure(
          'smart_tile.cell.batch_too_large',
          'The Smart Tile batch exceeds the bounded total cell limit.',
          details: {
            'inputCellCount': inputCellCount,
            'maximumTotalCellCount': maximumCellsPerBatch,
          },
        );
      }
      final parsedCells = _cells(
        rawCells,
        mapSize: context.map.size,
        maximumCellCount: maximumCellsPerBatch,
        deduplicate: true,
      );
      final cells = <({int x, int y})>[];
      for (final cell in parsedCells) {
        final position = (cell.x, cell.y);
        final existing = ownership[position];
        if (existing != null && existing != materialId) {
          throw semanticFailure(
            'smart_tile.cell.batch_conflict',
            'Different materials claim the same cell in the Smart Tile batch.',
            details: {
              'strokeIndex': strokeIndex,
              'x': cell.x,
              'y': cell.y,
              'firstMaterialId': existing,
              'materialId': materialId,
            },
          );
        }
        if (existing != null) continue;
        ownership[position] = materialId;
        cells.add(cell);
      }
      if (cells.isNotEmpty) strokes.add((materialId: materialId, cells: cells));
    }

    var projected = context.map;
    for (final stroke in strokes) {
      projected = applySmartTileMapMaterialGesture(
        projected,
        layer: _layer(projected, layerId),
        cells: [for (final cell in stroke.cells) GridPos(x: cell.x, y: cell.y)],
        materialId: stroke.materialId,
      );
    }
    final changedCellCount = ownership.keys.where((cell) {
      for (var index = 0; index < context.map.layers.length; index++) {
        final before = context.map.layers[index];
        final after = projected.layers[index];
        if (before is! SmartTileLayer || after is! SmartTileLayer) continue;
        if (smartTileMaterialIdAt(before,
                mapSize: context.map.size, x: cell.$1, y: cell.$2) !=
            smartTileMaterialIdAt(after,
                mapSize: context.map.size, x: cell.$1, y: cell.$2)) {
          return true;
        }
      }
      return false;
    }).length;
    return context.draft(
      SemanticMapEdit(
        map: projected,
        layerId: layerId,
        operation: operation,
        changedCells: changedCellCount,
        preview: {
          'presetId': preset.id,
          'usage': preset.usage.name,
          'topology': preset.topology.name,
          'fieldKind': _fieldKind(layer.field),
          'strokeCount': rawStrokes.length,
          'inputCellCount': inputCellCount,
          'uniqueCellCount': ownership.length,
          'materialIds': ownership.values.toSet().toList(),
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'batch',
        },
      ),
      delta: context.map.spatialScene != null &&
              layer.usage == SmartTileUsage.terrain
          ? null
          : MapMutationDelta.smartTileCells(
              layerId: layerId,
              cellIndices: {
                for (final cell in ownership.keys)
                  cell.$2 * context.map.size.width + cell.$1,
              },
            ),
    );
  }

  AuthoringMutationDraft _mutateCorners(
    AuthoringPlanningContext planning, {
    required bool erase,
  }) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: erase
          ? const <String>{'layerId', 'corners'}
          : const <String>{'layerId', 'materialId', 'corners'},
    );
    final operation = planning.request.actionId;
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: operation,
      layerId: layerId,
    );
    final layer = _layer(context.map, layerId);
    if (layer.field is! SmartTileCornerField &&
        layer.field is! SmartTileMixedField) {
      throw semanticFailure(
        'smart_tile.corner.field_invalid',
        'The Smart Tile layer has no corner lattice.',
        details: <String, Object?>{'layerId': layerId},
      );
    }
    final size = context.map.size;
    final corners = _corners(context.parameters.list('corners'), mapSize: size);
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
    var changedCornerCount = 0;
    final affectedCells = <int>{};
    final changedCells = <int>{};
    for (final corner in corners) {
      final adjacentCells = <int>{
        for (var y = corner.y - 1; y <= corner.y; y++)
          for (var x = corner.x - 1; x <= corner.x; x++)
            if (x >= 0 && y >= 0 && x < size.width && y < size.height)
              y * size.width + x,
      };
      affectedCells.addAll(adjacentCells);
      if (smartTileCornerMaterialIdAt(
            layer,
            mapSize: size,
            x: corner.x,
            y: corner.y,
          ) ==
          materialId) {
        continue;
      }
      projectedLayer = setSmartTileCornerMaterial(
        projectedLayer,
        mapSize: size,
        x: corner.x,
        y: corner.y,
        materialId: materialId,
      );
      changedCornerCount++;
      changedCells.addAll(adjacentCells);
    }
    return context.draft(
      SemanticMapEdit(
        map: replaceSmartTileLayer(context.map, layer: projectedLayer),
        layerId: layerId,
        operation: operation,
        changedCells: changedCells.length,
        preview: <String, Object?>{
          'presetId': preset.id,
          'fieldKind': _fieldKind(layer.field),
          'materialId': materialId,
          'gestureCornerCount': corners.length,
          'changedCornerCount': changedCornerCount,
          'semanticCellsPreserved': true,
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'gesture',
        },
      ),
      delta: MapMutationDelta.smartTileCells(
        layerId: layerId,
        cellIndices: affectedCells,
      ),
    );
  }

  AuthoringMutationDraft _mutate(
    AuthoringPlanningContext planning, {
    required bool erase,
  }) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: erase
          ? const <String>{'layerId', 'cells', 'selection'}
          : const <String>{'layerId', 'materialId', 'cells', 'selection'},
    );
    final operation = erase ? 'smart_tile.cell.erase' : 'smart_tile.cell.paint';
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: operation,
      layerId: layerId,
    );
    final layer = _layer(context.map, layerId);

    final gesture = smartTileGestureCells(
      context.parameters,
      layer: layer,
      mapSize: context.map.size,
    );
    final cells = gesture.cells;
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

    final projected = applySmartTileMapMaterialGesture(
      context.map,
      layer: layer,
      cells: <GridPos>[
        for (final cell in cells) GridPos(x: cell.x, y: cell.y),
      ],
      materialId: materialId,
    );
    final changedCellCount = cells.where((cell) {
      for (var index = 0; index < context.map.layers.length; index++) {
        final before = context.map.layers[index];
        final after = projected.layers[index];
        if (before is! SmartTileLayer || after is! SmartTileLayer) continue;
        if (smartTileMaterialIdAt(before,
                mapSize: context.map.size, x: cell.x, y: cell.y) !=
            smartTileMaterialIdAt(after,
                mapSize: context.map.size, x: cell.x, y: cell.y)) {
          return true;
        }
      }
      return false;
    }).length;
    return context.draft(
      SemanticMapEdit(
        map: projected,
        layerId: layerId,
        operation: operation,
        changedCells: changedCellCount,
        preview: <String, Object?>{
          'presetId': preset.id,
          'usage': preset.usage.name,
          'topology': preset.topology.name,
          'fieldKind': _fieldKind(layer.field),
          'materialId': materialId,
          'gestureSelection': gesture.selectionKind,
          'gestureCellCount': cells.length,
          'cells': <Map<String, int>>[
            for (final cell in cells) <String, int>{'x': cell.x, 'y': cell.y},
          ],
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'gesture',
        },
      ),
      delta: context.map.spatialScene != null &&
              layer.usage == SmartTileUsage.terrain &&
              !erase
          ? null
          : MapMutationDelta.smartTileCells(
              layerId: layerId,
              cellIndices: <int>{
                for (final cell in cells)
                  cell.y * context.map.size.width + cell.x,
              },
            ),
    );
  }
}

AuthoringActionDescriptor _batchDescriptor() => AuthoringActionDescriptor(
      id: 'smart_tile.cell.paint_batch',
      version: 1,
      summary:
          'Paint bounded material strokes on one layer in one atomic map mutation',
      inputSchemaId: 'pokemap.authoring.smart_tile.cell.paint_batch.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.cell.mutation.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const [
        'map',
        'smartTileLayer',
        'smartTilePreset',
        'smartTileMaterial'
      ],
      capabilityIds: const ['authoring.smart_tiles'],
      requiredPermissions: const [AuthoringPermission.projectWrite],
      guarantees: const [
        AuthoringGuarantee.dryRun,
        AuthoringGuarantee.idempotent,
        AuthoringGuarantee.atomic,
        AuthoringGuarantee.revisionChecked,
        AuthoringGuarantee.undoable,
      ],
      extensions: const {
        'semanticIds': true,
        'rawTilesetRequired': false,
        'batchAtomicity': 'all_or_nothing',
        'undoBoundary': 'batch',
        'maximumStrokeCount': SmartTileCellActions.maximumStrokesPerBatch,
        'maximumTotalCellCount': SmartTileCellActions.maximumCellsPerBatch,
        'sameMaterialDuplicates': 'deduplicate',
        'differentMaterialConflicts': 'reject',
        'supportedFieldKinds': ['cell', 'edge', 'corner', 'mixed'],
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': ['mapId', 'layerId', 'strokes'],
          'properties': {
            'mapId': {'type': 'string', 'minLength': 1},
            'layerId': {'type': 'string', 'minLength': 1},
            'strokes': {
              'type': 'array',
              'minItems': 1,
              'maxItems': SmartTileCellActions.maximumStrokesPerBatch,
              'items': {
                'type': 'object',
                'additionalProperties': false,
                'required': ['materialId', 'cells'],
                'properties': {
                  'materialId': {'type': 'string', 'minLength': 1},
                  'cells': {
                    'type': 'array',
                    'minItems': 1,
                    'maxItems': SmartTileCellActions.maximumCellsPerBatch,
                    'items': {
                      'type': 'object',
                      'additionalProperties': false,
                      'required': ['x', 'y'],
                      'properties': {
                        'x': {'type': 'integer', 'minimum': 0},
                        'y': {'type': 'integer', 'minimum': 0},
                      },
                    },
                  },
                },
              },
            },
          },
        },
      },
    );

AuthoringActionDescriptor _cornerDescriptor(String id, String summary) =>
    AuthoringActionDescriptor(
      id: id,
      version: 1,
      summary: summary,
      inputSchemaId: 'pokemap.authoring.$id.input.v1',
      outputSchemaId: 'pokemap.authoring.smart_tile.corner.mutation.v1',
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
        'semanticCellsPreserved': true,
        'supportedSelections': <String>['corners'],
        'supportedFieldKinds': <String>['corner', 'mixed'],
        'maximumExplicitCornerCount': 4096,
        'coordinateExtent': 'mapCornerLatticeInclusive',
      },
    );

List<GridPos> _corners(List<Object?> raw, {required GridSize mapSize}) {
  if (raw.isEmpty) {
    throw invalidSemanticField('corners', 'a non-empty list of coordinates');
  }
  if (raw.length > SmartTileCellActions.maximumExplicitCellsPerGesture) {
    throw semanticFailure(
      'smart_tile.corner.gesture_too_large',
      'The Smart Tile gesture exceeds the bounded corner limit.',
    );
  }
  final corners = <GridPos>[];
  final seen = <(int, int)>{};
  for (var index = 0; index < raw.length; index++) {
    final value = raw[index];
    if (value is! Map ||
        value.length != 2 ||
        value['x'] is! int ||
        value['y'] is! int) {
      throw invalidSemanticField('corners[$index]', 'exactly integer {x, y}');
    }
    final x = value['x'] as int;
    final y = value['y'] as int;
    if (x < 0 || y < 0 || x > mapSize.width || y > mapSize.height) {
      throw semanticFailure(
        'smart_tile.corner.out_of_bounds',
        'A Smart Tile corner is outside the map corner lattice.',
        details: <String, Object?>{'index': index, 'x': x, 'y': y},
      );
    }
    if (!seen.add((x, y))) {
      throw semanticFailure(
        'smart_tile.corner.duplicate',
        'A Smart Tile gesture repeats a corner coordinate.',
        details: <String, Object?>{'x': x, 'y': y},
      );
    }
    corners.add(GridPos(x: x, y: y));
  }
  corners.sort((left, right) {
    final byY = left.y.compareTo(right.y);
    return byY != 0 ? byY : left.x.compareTo(right.x);
  });
  return corners;
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
        'cellFieldOnly': false,
        'supportedSelections': <String>[
          'cells',
          'line',
          'rectangle',
          'floodFill',
        ],
        'maximumExplicitCellCount':
            SmartTileCellActions.maximumExplicitCellsPerGesture,
        'geometricSelectionLimit': 'mapExtent',
        'supportedFieldKinds': <String>['cell', 'edge', 'corner', 'mixed'],
      },
    );

String _fieldKind(SmartTileField field) => switch (field) {
      SmartTileCellField() => 'cell',
      SmartTileEdgeField() => 'edge',
      SmartTileCornerField() => 'corner',
      SmartTileMixedField() => 'mixed',
    };

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

({List<({int x, int y})> cells, String selectionKind}) smartTileGestureCells(
  SemanticParameters parameters, {
  required SmartTileLayer layer,
  required GridSize mapSize,
}) {
  final hasCells = parameters.contains('cells');
  final hasSelection = parameters.contains('selection');
  if (hasCells == hasSelection) {
    throw semanticFailure(
      'smart_tile.cell.selection_invalid',
      'Provide exactly one explicit cell list or geometric selection.',
      details: <String, Object?>{
        'hasCells': hasCells,
        'hasSelection': hasSelection,
      },
    );
  }
  if (hasCells) {
    return (
      cells: _cells(parameters.list('cells'), mapSize: mapSize),
      selectionKind: 'cells',
    );
  }

  final raw = parameters.object('selection');
  final kind = raw['kind'];
  if (kind is! String || kind.trim() != kind || kind.isEmpty) {
    throw invalidSemanticField('selection.kind', 'a supported shape');
  }
  final selection = switch (kind) {
    'line' => () {
        _requireSelectionKeys(raw, const <String>{'kind', 'start', 'end'});
        return SmartTileGestureSelection.line(
          start: _selectionCoordinate(
            raw['start'],
            field: 'selection.start',
            mapSize: mapSize,
          ),
          end: _selectionCoordinate(
            raw['end'],
            field: 'selection.end',
            mapSize: mapSize,
          ),
        );
      }(),
    'rectangle' => () {
        _requireSelectionKeys(raw, const <String>{'kind', 'start', 'end'});
        return SmartTileGestureSelection.rectangle(
          start: _selectionCoordinate(
            raw['start'],
            field: 'selection.start',
            mapSize: mapSize,
          ),
          end: _selectionCoordinate(
            raw['end'],
            field: 'selection.end',
            mapSize: mapSize,
          ),
        );
      }(),
    'floodFill' => () {
        _requireSelectionKeys(raw, const <String>{'kind', 'seed'});
        return SmartTileGestureSelection.floodFill(
          seed: _selectionCoordinate(
            raw['seed'],
            field: 'selection.seed',
            mapSize: mapSize,
          ),
        );
      }(),
    _ => throw invalidSemanticField(
        'selection.kind',
        'line, rectangle, or floodFill',
      ),
  };
  try {
    final compiled = compileSmartTileGestureSelection(
      layer,
      mapSize: mapSize,
      selection: selection,
    );
    return (
      cells: <({int x, int y})>[
        for (final cell in compiled) (x: cell.x, y: cell.y),
      ],
      selectionKind: kind,
    );
  } on SmartTileGestureLimitException catch (error) {
    throw semanticFailure(
      'smart_tile.cell.gesture_too_large',
      'The Smart Tile gesture exceeds the bounded cell limit.',
      details: <String, Object?>{
        'maximumCellCount': error.maximumCellCount,
        'selectionKind': kind,
      },
    );
  }
}

void _requireSelectionKeys(
  Map<String, Object?> selection,
  Set<String> expected,
) {
  final actual = selection.keys.toSet();
  if (actual.length == expected.length && actual.containsAll(expected)) return;
  throw invalidSemanticField(
    'selection',
    'exactly ${expected.toList()..sort()}',
  );
}

GridPos _selectionCoordinate(
  Object? raw, {
  required String field,
  required GridSize mapSize,
}) {
  if (raw is! Map || raw.keys.any((key) => key is! String)) {
    throw invalidSemanticField(field, 'an {x, y} object');
  }
  final value = Map<String, Object?>.from(raw);
  if (value.length != 2 || !value.containsKey('x') || !value.containsKey('y')) {
    throw invalidSemanticField(field, 'exactly {x, y}');
  }
  final x = value['x'];
  final y = value['y'];
  if (x is! int || y is! int) {
    throw invalidSemanticField(field, 'integer x and y values');
  }
  if (x < 0 || y < 0 || x >= mapSize.width || y >= mapSize.height) {
    throw semanticFailure(
      'smart_tile.cell.out_of_bounds',
      'A Smart Tile gesture coordinate is outside the map.',
      details: <String, Object?>{
        'field': field,
        'x': x,
        'y': y,
        'mapWidth': mapSize.width,
        'mapHeight': mapSize.height,
      },
    );
  }
  return GridPos(x: x, y: y);
}

List<({int x, int y})> _cells(
  List<Object?> raw, {
  required GridSize mapSize,
  int maximumCellCount = SmartTileCellActions.maximumExplicitCellsPerGesture,
  bool deduplicate = false,
}) {
  if (raw.isEmpty) {
    throw invalidSemanticField('cells', 'a non-empty list of coordinates');
  }
  if (raw.length > maximumCellCount) {
    throw semanticFailure(
      'smart_tile.cell.gesture_too_large',
      'The Smart Tile gesture exceeds the bounded cell limit.',
      details: <String, Object?>{
        'cellCount': raw.length,
        'maximumCellCount': maximumCellCount,
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
      if (deduplicate) continue;
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
