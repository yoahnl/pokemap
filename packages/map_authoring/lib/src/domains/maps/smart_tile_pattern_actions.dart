import 'package:map_core/map_core.dart';

import '../../contracts/action_descriptor.dart';
import '../../transactions/action_planner.dart';
import '../../transactions/authoring_plan.dart';
import 'semantic_map_action_support.dart';
import 'smart_tile_cell_actions.dart';
import 'smart_tile_native_transition_guard.dart';

/// Canonical reusable-pattern painting shared by direct, JSONL, editor and MCP.
final class SmartTilePatternActions {
  const SmartTilePatternActions();

  static final List<AuthoringActionDescriptor> descriptors = List.unmodifiable(
    <AuthoringActionDescriptor>[
      _descriptor(
        'smart_tile.pattern.paint',
        'Paint one reusable Smart Tile pattern as an atomic stroke',
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
        'smart_tile.pattern.erase' => _erase(planning),
        _ => throw semanticFailure(
            'smart_tile.pattern.action_unsupported',
            'The requested Smart Tile pattern action is unsupported.',
            details: <String, Object?>{
              'actionId': planning.request.actionId,
            },
          ),
      };

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
      allowedParameters: const <String>{'layerId', 'cells', 'selection'},
    );
    final layerId = context.parameters.string('layerId');
    requireExistingNativeSmartTileProject(
      planning.snapshot,
      operation: 'smart_tile.pattern.erase',
      layerId: layerId,
    );
    final layer = _patternLayer(context.map, layerId);
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
    );
    final afterCount = projectedLayer.patternStrokes.fold<int>(
      0,
      (sum, stroke) => sum + stroke.cells.length,
    );
    return context.draft(
      SemanticMapEdit(
        map: _replaceLayer(context.map, projectedLayer),
        layerId: layerId,
        operation: 'smart_tile.pattern.erase',
        changedCells: beforeCount - afterCount,
        preview: <String, Object?>{
          'gestureSelection': gesture.selectionKind,
          'gestureCellCount': gesture.cells.length,
          'erasedOwnershipCount': beforeCount - afterCount,
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
      extensions: const <String, Object?>{
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
      },
    );

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
