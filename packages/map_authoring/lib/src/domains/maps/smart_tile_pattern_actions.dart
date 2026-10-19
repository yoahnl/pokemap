import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_cell_actions.dart';
import 'smart_tile_native_transition_guard.dart';
import 'smart_tile_construction_contract.dart';

/// Canonical reusable-pattern painting shared by direct, JSONL, editor and MCP.
final class SmartTilePatternActions {
  const SmartTilePatternActions();

  static const maximumStrokesPerBatch = 250;
  static const maximumCellsPerBatch = 65536;

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _descriptor(
        'smart_tile.pattern.paint',
        'Paint one reusable Smart Tile pattern as an atomic stroke',
      ),
      _descriptor(
        'smart_tile.pattern.paint_batch',
        'Paint an ordered bounded batch of reusable Smart Tile patterns',
      ),
      _descriptor(
        'smart_tile.pattern.erase',
        'Erase reusable Smart Tile pattern ownership from selected cells',
      ),
    ],
  );

  AuthoringMutationDraft build(AuthoringPlanningContext planning) =>
      switch (planning.request.actionId) {
        'smart_tile.pattern.paint' => _paint(planning),
        'smart_tile.pattern.paint_batch' => _paintBatch(planning),
        'smart_tile.pattern.erase' => _erase(planning),
        _ => throw semanticFailure(
            'smart_tile.pattern.action_unsupported',
            'The requested Smart Tile pattern action is unsupported.',
            details: <String, Object?>{
              'actionId': planning.request.actionId,
            },
          ),
      };

  AuthoringMutationDraft _paintBatch(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const {'layerId', 'strokes', 'collisionLayerId'},
    );
    final operation = planning.request.actionId;
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: operation,
      layerId: layerId,
    );
    var layer = _patternLayer(context.map, layerId);
    final strokes = context.parameters.list('strokes');
    if (strokes.isEmpty) {
      throw invalidSemanticField(
          'strokes', 'a nonempty list of pattern strokes');
    }
    if (strokes.length > maximumStrokesPerBatch) {
      throw semanticFailure(
        'smart_tile.pattern.batch_too_large',
        'The Smart Tile pattern batch exceeds the bounded stroke limit.',
        details: {'maximumStrokeCount': maximumStrokesPerBatch},
      );
    }
    final patterns = {
      for (final pattern in context.manifest.smartTileCatalog.patterns)
        pattern.id: pattern,
    };
    final strokeIds = <String>{};
    final collisions = <SmartTilePatternCollisionUpdate>[];
    var affectedCellCount = 0;
    for (var index = 0; index < strokes.length; index++) {
      final raw = strokes[index];
      if (raw is! Map || raw.keys.any((key) => key is! String)) {
        throw invalidSemanticField(
            'strokes[$index]', 'a pattern stroke object');
      }
      final parameters = SemanticParameters(
        Map<String, Object?>.from(raw),
        allowed: const {
          'patternId',
          'strokeId',
          'selection',
          'phaseX',
          'phaseY',
          'materialId',
        },
      );
      final strokeId = parameters.string('strokeId');
      if (!strokeIds.add(strokeId)) {
        throw semanticFailure(
          'smart_tile.pattern.batch_duplicate_stroke',
          'Pattern stroke IDs must be unique within the batch.',
          details: {'strokeId': strokeId},
        );
      }
      final patternId = parameters.string('patternId');
      final pattern = patterns[patternId];
      if (pattern == null) {
        throw semanticFailure(
          'smart_tile.pattern.unknown',
          'The requested Smart Tile pattern does not exist.',
          details: {'patternId': patternId},
        );
      }
      final selection = _patternSelection(
        parameters.object('selection'),
        mapSize: context.map.size,
      );
      _requireConstructionDimension(context.map, pattern);
      final materialId = _patternMaterial(context, layer, parameters);
      if (affectedCellCount == maximumCellsPerBatch) {
        throw semanticFailure(
          'smart_tile.pattern.batch_too_large',
          'The Smart Tile pattern batch exceeds the bounded total cell limit.',
          details: {'maximumTotalCellCount': maximumCellsPerBatch},
        );
      }
      late final SmartTilePatternApplication application;
      try {
        application = applySmartTilePatternGesture(
          layer,
          pattern: pattern,
          mapSize: context.map.size,
          selection: selection,
          strokeId: strokeId,
          phaseX: parameters.optionalInteger('phaseX') ?? 0,
          phaseY: parameters.optionalInteger('phaseY') ?? 0,
          materialId: materialId,
          maximumCellCount: pattern.construction != null &&
                  maximumCellsPerBatch - affectedCellCount > smartTileMaximumCellsPerGesture
              ? smartTileMaximumCellsPerGesture
              : maximumCellsPerBatch - affectedCellCount,
        );
      } on SmartTileGestureLimitException {
        throw semanticFailure(
          'smart_tile.pattern.batch_too_large',
          'The Smart Tile pattern batch exceeds the bounded total cell limit.',
          details: {'maximumTotalCellCount': maximumCellsPerBatch},
        );
      } on ValidationException catch (error) {
        throw semanticFailure(
          error.code ?? 'smart_tile.pattern.invalid',
          error.message,
        );
      }
      layer = application.layer;
      affectedCellCount += application.affectedCells.length;
      collisions.addAll(application.collisionUpdates);
    }
    var projected = _replaceLayer(context.map, layer);
    final collisionLayerId =
        context.parameters.optionalString('collisionLayerId');
    if (collisionLayerId != null && collisions.isNotEmpty) {
      projected = _applyCollisionUpdates(
        projected,
        collisionLayerId: collisionLayerId,
        updates: collisions,
      );
    }
    return context.draftMap(
      after: projected,
      operation: operation,
      changedItems: affectedCellCount,
      layerId: layerId,
      preview: {
        'strokeCount': strokes.length,
        'gestureCellCount': affectedCellCount,
        'collisionUpdateCount': collisions.length,
        'collisionApplied': collisionLayerId != null,
        'overlapPolicy': 'ordered_strokes',
        'batchAtomicity': 'all_or_nothing',
        'undoBoundary': 'batch',
      },
    );
  }

  AuthoringMutationDraft _paint(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const <String>{
        'layerId',
        'patternId',
        'strokeId',
        'selection',
        'phaseX',
        'phaseY',
        'collisionLayerId',
        'materialId',
      },
    );
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: 'smart_tile.pattern.paint',
      layerId: layerId,
    );
    final layer = _patternLayer(context.map, layerId);
    final patternId = context.parameters.string('patternId');
    final pattern = context.manifest.smartTileCatalog.patterns
        .where((candidate) => candidate.id == patternId)
        .firstOrNull;
    if (pattern == null) {
      throw semanticFailure(
        'smart_tile.pattern.unknown',
        'The requested Smart Tile pattern does not exist.',
        details: <String, Object?>{'patternId': patternId},
      );
    }
    final selection = _patternSelection(
      context.parameters.object('selection'),
      mapSize: context.map.size,
    );
    _requireConstructionDimension(context.map, pattern);
    final materialId = _patternMaterial(context, layer, context.parameters);
    late final SmartTilePatternApplication application;
    try {
      application = applySmartTilePatternGesture(
        layer,
        pattern: pattern,
        mapSize: context.map.size,
        selection: selection,
        strokeId: context.parameters.string('strokeId'),
        phaseX: context.parameters.optionalInteger('phaseX') ?? 0,
        phaseY: context.parameters.optionalInteger('phaseY') ?? 0,
        materialId: materialId,
      );
    } on SmartTileGestureLimitException catch (error) {
      throw semanticFailure(
        'smart_tile.pattern.gesture_too_large',
        'The Smart Tile pattern gesture exceeds the bounded cell limit.',
        details: <String, Object?>{
          'maximumCellCount': error.maximumCellCount,
        },
      );
    } on ValidationException catch (error) {
      throw semanticFailure(
        error.code ?? 'smart_tile.pattern.invalid',
        error.message,
      );
    }

    var projected = _replaceLayer(context.map, application.layer);
    final collisionLayerId = context.parameters.optionalString(
      'collisionLayerId',
    );
    if (collisionLayerId != null && application.collisionUpdates.isNotEmpty) {
      projected = _applyCollisionUpdates(
        projected,
        collisionLayerId: collisionLayerId,
        updates: application.collisionUpdates,
      );
    }
    final preview = <String, Object?>{
      'patternId': pattern.id,
      'usage': pattern.usage.name,
      'repeatMode': pattern.repeatMode.name,
      if (pattern.construction != null) ...{
        'construction': pattern.construction!.toJson(),
        'constructionBounds': application.layer.patternStrokes
            .singleWhere((stroke) => stroke.id == context.parameters.string('strokeId'))
            .toJson()['constructionBounds'],
      },
      if (pattern.clippingPolicy == SmartTilePatternClippingPolicy.reject)
        'clippingPolicy': 'reject',
      'gestureSelection': selection.kind.name,
      'gestureCellCount': application.affectedCells.length,
      'collisionUpdateCount': application.collisionUpdates.length,
      'collisionApplied': collisionLayerId != null,
      'batchAtomicity': 'all_or_nothing',
      'undoBoundary': 'gesture',
    };
    if (collisionLayerId != null && application.collisionUpdates.isNotEmpty) {
      return context.draftMap(
        after: projected,
        operation: 'smart_tile.pattern.paint',
        changedItems: application.affectedCells.length,
        layerId: layerId,
        preview: preview,
      );
    }
    return context.draft(
      SemanticMapEdit(
        map: projected,
        layerId: layerId,
        operation: 'smart_tile.pattern.paint',
        changedCells: application.affectedCells.length,
        preview: preview,
      ),
    );
  }

  AuthoringMutationDraft _erase(AuthoringPlanningContext planning) {
    final context = SemanticMapActionContext.read(
      planning,
      allowedParameters: const <String>{
        'layerId',
        'cells',
        'selection',
        'strokeIds',
        'clearMaterial',
      },
    );
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: 'smart_tile.pattern.erase',
      layerId: layerId,
    );
    final layer = _patternLayer(context.map, layerId);
    final strokeIds = context.parameters.contains('strokeIds')
        ? _eraseStrokeIds(context.parameters.list('strokeIds'), layer)
        : null;
    final gesture = smartTileGestureCells(
      context.parameters,
      layer: layer,
      mapSize: context.map.size,
    );
    final beforeCount = layer.patternStrokes.fold<int>(
      0,
      (sum, stroke) => sum + stroke.cells.length,
    );
    final projectedLayer = eraseSmartTilePatternCells(
      layer,
      mapSize: context.map.size,
      cells: <GridPos>[
        for (final cell in gesture.cells) GridPos(x: cell.x, y: cell.y),
      ],
      strokeIds: strokeIds,
      clearMaterial: context.parameters.contains('clearMaterial')
          ? context.parameters.boolean('clearMaterial')
          : false,
    );
    final afterCount = projectedLayer.patternStrokes.fold<int>(
      0,
      (sum, stroke) => sum + stroke.cells.length,
    );
    final beforeMaterials = smartTileSemanticCells(layer);
    final afterMaterials = smartTileSemanticCells(projectedLayer);
    final clearedMaterialCellCount = gesture.cells.where((cell) {
      final index = cell.y * context.map.size.width + cell.x;
      return beforeMaterials[index] != afterMaterials[index];
    }).length;
    return context.draft(
      SemanticMapEdit(
        map: _replaceLayer(context.map, projectedLayer),
        layerId: layerId,
        operation: 'smart_tile.pattern.erase',
        changedCells: beforeCount - afterCount + clearedMaterialCellCount,
        preview: <String, Object?>{
          'gestureSelection': gesture.selectionKind,
          'gestureCellCount': gesture.cells.length,
          'erasedOwnershipCount': beforeCount - afterCount,
          'clearedMaterialCellCount': clearedMaterialCellCount,
          'clearMaterial': context.parameters.contains('clearMaterial')
              ? context.parameters.boolean('clearMaterial')
              : false,
          if (strokeIds != null) 'targetStrokeIds': strokeIds,
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
      outputSchemaId: 'pokemap.authoring.smart_tile.pattern.mutation.v1',
      riskLevel: AuthoringRiskLevel.low,
      resourceKinds: const <String>[
        'map',
        'smartTileLayer',
        'smartTilePattern',
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
      extensions: <String, Object?>{
        if (id != 'smart_tile.pattern.erase')
          'adaptiveConstruction2d': adaptiveSmartTileConstructionContract,
        if (id != 'smart_tile.pattern.erase')
          'patternClipping': smartTilePatternClippingContract,
        if (id != 'smart_tile.pattern.erase')
          'materialPalettePolicy': 'append_catalog_material_allowed_by_preset',
        'semanticIds': true,
        'rawTilesetRequired': false,
        'gestureAtomic': true,
        'supportedPaintSelections': <String>['stamp', 'line', 'rectangle'],
        'supportedEraseSelections': <String>[
          'cells',
          'line',
          'rectangle',
          'floodFill',
        ],
        'optionalCollisionLayer': true,
        if (id != 'smart_tile.pattern.erase') ...{
          'optionalPatternMaterial': true,
          'materialIdSchema': {'type': 'string', 'minLength': 1},
          'materialCoveragePolicy':
              'occupied_cells_except_explicit_material_holes',
          'preserveMaterialsWhenAbsent': true,
        },
        if (id == 'smart_tile.pattern.paint_batch') ...{
          'maximumStrokeCount': SmartTilePatternActions.maximumStrokesPerBatch,
          'maximumTotalCellCount': SmartTilePatternActions.maximumCellsPerBatch,
          'overlapPolicy': 'ordered_strokes',
          'duplicateStrokeIds': 'reject',
          'batchAtomicity': 'all_or_nothing',
          'undoBoundary': 'batch',
          'inputSchema': {
            'type': 'object',
            'required': ['mapId', 'layerId', 'strokes'],
            'additionalProperties': false,
            'properties': {
              'mapId': {'type': 'string', 'minLength': 1},
              'layerId': {'type': 'string', 'minLength': 1},
              'collisionLayerId': {'type': 'string', 'minLength': 1},
              'strokes': {
                'type': 'array',
                'minItems': 1,
                'maxItems': SmartTilePatternActions.maximumStrokesPerBatch,
                'items': {
                  'type': 'object',
                  'additionalProperties': false,
                  'required': ['patternId', 'strokeId', 'selection'],
                  'properties': {
                    'patternId': {'type': 'string', 'minLength': 1},
                    'strokeId': {'type': 'string', 'minLength': 1},
                    'phaseX': {'type': 'integer'},
                    'phaseY': {'type': 'integer'},
                    'materialId': {'type': 'string', 'minLength': 1},
                    'selection': {
                      'oneOf': [
                        {
                          'type': 'object',
                          'additionalProperties': false,
                          'required': ['kind', 'anchor'],
                          'properties': {
                            'kind': {'const': 'stamp'},
                            'anchor': _coordinateSchema,
                          },
                        },
                        {
                          'type': 'object',
                          'additionalProperties': false,
                          'required': ['kind', 'start', 'end'],
                          'properties': {
                            'kind': {
                              'enum': ['line', 'rectangle']
                            },
                            'start': _coordinateSchema,
                            'end': _coordinateSchema,
                          },
                        },
                      ],
                    },
                  },
                },
              },
            },
          },
        },
        if (id == 'smart_tile.pattern.erase') ...{
          'optionalClearMaterial': true,
          'clearMaterialSchema': {'type': 'boolean', 'default': false},
          'clearMaterialPolicy': 'preserve_remaining_pattern_ownership',
          'optionalEraseStrokeIds': true,
          'eraseStrokeIdsSchema': const <String, Object?>{
            'type': 'array',
            'minItems': 1,
            'uniqueItems': true,
            'items': <String, Object?>{'type': 'string', 'minLength': 1},
          },
          'eraseWithoutStrokeIds': 'all_overlapping_strokes',
        },
      },
    );

void _requireConstructionDimension(MapData map, ProjectSmartTilePattern pattern) {
  if (map.spatialScene != null && pattern.construction != null) {
    throw semanticFailure(
      'smart_tile.pattern.construction_2d_only',
      'Adaptive native construction is available on 2D maps only.',
    );
  }
}

const _coordinateSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['x', 'y'],
  'properties': {
    'x': {'type': 'integer', 'minimum': 0},
    'y': {'type': 'integer', 'minimum': 0},
  },
};

String? _patternMaterial(SemanticMapActionContext context, SmartTileLayer layer,
    SemanticParameters parameters) {
  final id = parameters.optionalString('materialId');
  if (id == null) return null;
  final preset = context.manifest.smartTileCatalog.presets
      .where((preset) => preset.id == layer.presetId)
      .firstOrNull;
  if (!(preset?.allowedMaterialIds.contains(id) ?? false) ||
      !context.manifest.smartTileCatalog.materials
          .any((material) => material.id == id)) {
    throw semanticFailure('smart_tile.pattern.material_not_allowed',
        'The pattern material is not available in the target layer.',
        details: {'layerId': layer.id, 'materialId': id});
  }
  return id;
}

List<String> _eraseStrokeIds(List<Object?> raw, SmartTileLayer layer) {
  final existingIds = layer.patternStrokes.map((stroke) => stroke.id).toSet();
  final ids = <String>{};
  if (raw.isEmpty) {
    throw invalidSemanticField(
        'strokeIds', 'a nonempty list of existing stroke IDs');
  }
  for (final value in raw) {
    if (value is! String ||
        value.isEmpty ||
        value.trim() != value ||
        !ids.add(value) ||
        !existingIds.contains(value)) {
      throw invalidSemanticField('strokeIds', 'unique existing stroke IDs');
    }
  }
  return ids.toList(growable: false);
}

SmartTilePatternSelection _patternSelection(
  Map<String, Object?> raw, {
  required GridSize mapSize,
}) {
  final kind = raw['kind'];
  if (kind is! String || kind.trim() != kind || kind.isEmpty) {
    throw invalidSemanticField('selection.kind', 'stamp, line, or rectangle');
  }
  return switch (kind) {
    'stamp' => () {
        _requireExactKeys(raw, const <String>{'kind', 'anchor'});
        return SmartTilePatternSelection.stamp(
          anchor: _coordinate(
            raw['anchor'],
            field: 'selection.anchor',
            mapSize: mapSize,
          ),
        );
      }(),
    'line' => () {
        _requireExactKeys(raw, const <String>{'kind', 'start', 'end'});
        return SmartTilePatternSelection.line(
          start: _coordinate(
            raw['start'],
            field: 'selection.start',
            mapSize: mapSize,
          ),
          end: _coordinate(
            raw['end'],
            field: 'selection.end',
            mapSize: mapSize,
          ),
        );
      }(),
    'rectangle' => () {
        _requireExactKeys(raw, const <String>{'kind', 'start', 'end'});
        return SmartTilePatternSelection.rectangle(
          start: _coordinate(
            raw['start'],
            field: 'selection.start',
            mapSize: mapSize,
          ),
          end: _coordinate(
            raw['end'],
            field: 'selection.end',
            mapSize: mapSize,
          ),
        );
      }(),
    _ => throw invalidSemanticField(
        'selection.kind',
        'stamp, line, or rectangle',
      ),
  };
}

void _requireExactKeys(Map<String, Object?> raw, Set<String> expected) {
  final keys = raw.keys.toSet();
  if (keys.length == expected.length && keys.containsAll(expected)) return;
  throw invalidSemanticField(
      'selection', 'exactly ${expected.toList()..sort()}');
}

GridPos _coordinate(
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
      'smart_tile.pattern.out_of_bounds',
      'A Smart Tile pattern coordinate is outside the map.',
      details: <String, Object?>{'field': field, 'x': x, 'y': y},
    );
  }
  return GridPos(x: x, y: y);
}

SmartTileLayer _patternLayer(MapData map, String layerId) {
  final layer =
      map.layers.where((candidate) => candidate.id == layerId).firstOrNull;
  if (layer is SmartTileLayer) return layer;
  throw semanticFailure(
    'smart_tile.layer_invalid',
    'The requested layer is not a Smart Tile layer.',
    details: <String, Object?>{'layerId': layerId},
  );
}

MapData _replaceLayer(MapData map, SmartTileLayer replacement) => map.copyWith(
      layers: <MapLayer>[
        for (final layer in map.layers)
          if (layer.id == replacement.id) replacement else layer,
      ],
    );

MapData _applyCollisionUpdates(
  MapData map, {
  required String collisionLayerId,
  required List<SmartTilePatternCollisionUpdate> updates,
}) {
  final collision =
      map.layers.where((layer) => layer.id == collisionLayerId).firstOrNull;
  if (collision is! CollisionLayer) {
    throw semanticFailure(
      'smart_tile.pattern.collision_layer_invalid',
      'The requested collision target is not a Collision layer.',
      details: <String, Object?>{'collisionLayerId': collisionLayerId},
    );
  }
  final cells = List<bool>.of(collision.collisions);
  for (final update in updates) {
    cells[update.cell.y * map.size.width + update.cell.x] = update.blocked;
  }
  return map.copyWith(
    layers: <MapLayer>[
      for (final layer in map.layers)
        if (layer.id == collisionLayerId)
          collision.copyWith(collisions: cells)
        else
          layer,
    ],
  );
}
