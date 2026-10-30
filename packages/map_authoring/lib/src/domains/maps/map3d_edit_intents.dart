import 'dart:math' as math;

import 'package:map_core/map_core.dart';

import 'semantic_map_action_support.dart';

const mapEditIntentActionIds = {
  'intent.ground.fill',
  'intent.border.remove_keeping_ground',
  'intent.border.trace_step',
  'intent.border.clear_over_object',
};

Map<String, Object?> mapEditIntentContracts() {
  const id = {'type': 'string', 'minLength': 1};
  const cell = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['x', 'y'],
    'properties': {
      'x': {'type': 'integer', 'minimum': 0},
      'y': {'type': 'integer', 'minimum': 0}
    }
  };
  const region = {
    'type': 'object',
    'additionalProperties': false,
    'required': ['x', 'y', 'width', 'height'],
    'properties': {
      'x': {'type': 'integer', 'minimum': 0},
      'y': {'type': 'integer', 'minimum': 0},
      'width': {'type': 'integer', 'minimum': 1},
      'height': {'type': 'integer', 'minimum': 1}
    }
  };
  return {
    for (final action in mapEditIntentActionIds)
      action: {
        'actionVersion': 1,
        'inputSchema': {
          'type': 'object',
          'additionalProperties': false,
          'required': action == 'intent.ground.fill'
              ? <String>[]
              : [
                  'layerId',
                  'featureId',
                  if (action == 'intent.border.clear_over_object') 'instanceId',
                  if (action == 'intent.border.trace_step') ...[
                    'blueprintId',
                    'lowerHeight',
                    'upperHeight'
                  ]
                ],
          if (action == 'intent.ground.fill')
            'oneOf': [
              {
                'required': ['cells']
              },
              {
                'required': ['region']
              }
            ],
          'properties': {
            'mapId': id,
            if (action == 'intent.ground.fill') ...{
              'layerId': id,
              'materialId': id,
              'cells': {
                'type': 'array',
                'minItems': 1,
                'maxItems': 4096,
                'items': cell
              },
              'region': region
            } else ...{
              'layerId': id,
              'featureId': id
            },
            if (action == 'intent.border.remove_keeping_ground') ...{
              'groundLayerId': id,
              'materialId': id
            },
            if (action == 'intent.border.clear_over_object') 'instanceId': id,
            if (action == 'intent.border.trace_step') ...{
              'blueprintId': id,
              'name': id,
              'seed': {'type': 'integer', 'minimum': 0, 'maximum': 2147483647},
              'region': region,
              'lowerHeight': {'type': 'number'},
              'upperHeight': {'type': 'number'}
            },
          },
        },
        'inputExample': switch (action) {
          'intent.ground.fill' => {
              'cells': [
                {'x': 12, 'y': 8}
              ],
              'layerId': 'terrain'
            },
          'intent.border.remove_keeping_ground' => {
              'layerId': 'border',
              'featureId': 'fence',
              'groundLayerId': 'terrain'
            },
          'intent.border.clear_over_object' => {
              'layerId': 'border',
              'featureId': 'fence',
              'instanceId': 'dock'
            },
          _ => {
              'layerId': 'border',
              'featureId': 'new-step',
              'blueprintId': 'fence',
              'lowerHeight': 0,
              'upperHeight': 1
            },
        },
      }
  };
}

String normalizeMapEditMaterialName(String name) =>
    name.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

Set<String> requestedMapEditMaterialNames(Object? parameters) {
  final names = <String>{};
  void visit(Object? value) {
    if (value is Map) {
      final material = value['material'];
      if (material is Map && material['name'] is String) {
        names.add(normalizeMapEditMaterialName(material['name'] as String));
      }
      for (final child in value.values) {
        visit(child);
      }
    } else if (value is List) {
      for (final child in value) {
        visit(child);
      }
    }
  }

  visit(parameters);
  return names;
}

List<Map<String, Object?>> expandMapEditIntent({
  required ProjectManifest manifest,
  required MapData map,
  required Map<String, Object?> operation,
}) {
  final action = operation['actionId'] as String;
  final raw = Map<String, Object?>.from(operation['parameters'] as Map);
  if (raw.containsKey('mapId') && raw['mapId'] != map.id) {
    throw semanticFailure(
        'map3d.edit_batch.foreign_resource', 'The intent targets another map.');
  }
  if (!action.startsWith('intent.')) {
    if (!action.startsWith('smart_tile.')) return [operation];
    Map<String, Object?> resolve(Map<String, Object?> value) {
      if (!value.containsKey('material')) return value;
      if (value.containsKey('materialId')) {
        throw semanticFailure('intent.material_conflict',
            'Choose a material name or identity, not both.');
      }
      final nameValue =
          SemanticParameters(_object(value['material']), allowed: {'name'})
              .value('name');
      if (nameValue is! String || nameValue.trim().isEmpty) {
        throw semanticFailure(
            'intent.material_name_invalid', 'Choose a nonblank material name.');
      }
      final name = nameValue.trim();
      final result = resolveMaterialByName(manifest, name);
      if (result.materialId == null) {
        throw semanticFailure(
            result.candidates.isEmpty
                ? 'intent.material_not_found'
                : 'intent.material_ambiguous',
            'Choose an unambiguous material from the project catalogue.',
            details: {
              'name': name,
              'candidates': [
                for (final id in result.candidates)
                  {
                    'id': id,
                    'name': manifest.smartTileCatalog.materials
                        .singleWhere((material) => material.id == id)
                        .name
                  }
              ],
            });
      }
      final resolved = Map<String, Object?>.from(value)..remove('material');
      return {...resolved, 'materialId': result.materialId};
    }

    final parameters = resolve(raw);
    if (parameters['strokes'] case final List strokes) {
      parameters['strokes'] = [
        for (final stroke in strokes) resolve(_object(stroke))
      ];
    }
    return [
      {...operation, 'parameters': parameters}
    ];
  }
  if (!mapEditIntentActionIds.contains(action)) {
    throw semanticFailure(
        'intent.unsupported', 'The requested map intent is unsupported.');
  }
  if (operation['actionVersion'] != 1) {
    throw semanticFailure('intent.version_unsupported','This map intent supports actionVersion 1 only.');
  }
  final allowed = switch (action) {
    'intent.ground.fill' => {'cells', 'region', 'layerId', 'materialId'},
    'intent.border.remove_keeping_ground' => {
        'layerId',
        'featureId',
        'groundLayerId',
        'materialId'
      },
    'intent.border.clear_over_object' => {'layerId', 'featureId', 'instanceId'},
    _ => {
        'layerId',
        'featureId',
        'blueprintId',
        'seed',
        'region',
        'lowerHeight',
        'upperHeight',
        'name'
      },
  };
  final parameters = SemanticParameters(raw, allowed: {'mapId', ...allowed});
  String? optional(String field) =>
      parameters.contains(field) ? parameters.string(field) : null;
  if (action == 'intent.ground.fill') {
    final hasCells = parameters.contains('cells');
    if (hasCells == parameters.contains('region')) {
      throw semanticFailure(
          'intent.ground.selection_invalid', 'Provide cells or a region.');
    }
    final cells = hasCells
        ? _cells(parameters.list('cells'))
        : _regionCells(_region(parameters.object('region')));
    return groundFillOperations(map, cells,
        layerId: optional('layerId'), materialId: optional('materialId'));
  }
  final layerId = parameters.string('layerId'),
      featureId = parameters.string('featureId');
  final layer = map.layers
      .whereType<BorderLayer>()
      .where((layer) => layer.id == layerId)
      .firstOrNull;
  if (layer == null) {
    throw semanticFailure(
        'border.layer_missing', 'Choose an existing Border layer.');
  }
  final feature = layer.content.featureById(featureId);
  if (action == 'intent.border.remove_keeping_ground') {
    if (feature == null) {
      return [
        _operation('border_layer.feature_delete',
            {'layerId': layerId, 'featureId': featureId})
      ];
    }
    final isolated = map.copyWith(layers: [
      for (final current in map.layers)
        if (current is BorderLayer)
          current.copyWith(
              content: BorderLayerContent(
                  formatVersion: current.content.formatVersion,
                  features: current.id == layerId ? [feature] : const []))
        else
          current
    ]);
    final cells = <GridPos>{};
    final materialByCell = <GridPos, Set<String>>{};
    final sources =
        resolveSpatialBorderGroundSurfaces(manifest: manifest, map: isolated);
    for (final source in sources) {
      for (final footprint in source.footprints) {
        final xs = footprint.points.map((point) => point.x),
            zs = footprint.points.map((point) => point.z);
        for (var y = math.max(0, zs.reduce(math.min).floor());
            y < math.min(map.size.height, zs.reduce(math.max).ceil());
            y++) {
          for (var x = math.max(0, xs.reduce(math.min).floor());
              x < math.min(map.size.width, xs.reduce(math.max).ceil());
              x++) {
            if (footprint.contains(x + .5, y + .5)) {
              final cell = GridPos(x: x, y: y);
              cells.add(cell);
              materialByCell.putIfAbsent(cell, () => {}).add(source.materialId);
            }
          }
        }
      }
    }
    for (final replacement in resolveSpatialBorderGroundReplacements(
        manifest: manifest, map: isolated)) {
      for (var y = math.max(0, replacement.top.floor());
          y < math.min(map.size.height, replacement.bottom.ceil());
          y++) {
        for (var x = math.max(0, replacement.left.floor());
            x < math.min(map.size.width, replacement.right.ceil());
            x++) {
          if (replacement.contains(x + .5, y + .5)) {
            cells.add(GridPos(x: x, y: y));
          }
        }
      }
    }
    cells.addAll(
        resolveSpatialBorderGroundMaskCells(manifest: manifest, map: isolated)
            .map((cell) => GridPos(x: cell.$1, y: cell.$2)));
    final after =
        removeBorderFeature(map, layerId: layerId, featureId: featureId);
    final remainingMask = resolveSpatialBorderGroundMaskCellsByLayer(
        manifest: manifest, map: after);
    final unpainted = cells
        .where((cell) => !after.layers.whereType<SmartTileLayer>().any(
            (layer) =>
                layer.isVisible &&
                layer.opacity > 0 &&
                !(remainingMask[layer.id]?.contains((cell.x, cell.y)) ??
                    false) &&
                (smartTileMaterialIdAt(layer,
                            mapSize: map.size, x: cell.x, y: cell.y)
                        ?.isNotEmpty ??
                    false)))
        .toList();
    final generated = <Map<String, Object?>>[];
    final groups = <(String?, String?), List<GridPos>>{};
    for (final cell in unpainted) {
      final source = materialByCell[cell];
      final key = (
        optional('groundLayerId'),
        optional('materialId') ?? (source?.length == 1 ? source!.single : null)
      );
      groups.putIfAbsent(key, () => []).add(cell);
    }
    for (final entry in groups.entries) {
      generated.addAll(groundFillOperations(map, entry.value,
          layerId: entry.key.$1, materialId: entry.key.$2));
    }
    return [
      ...generated,
      _operation('border_layer.feature_delete',
          {'layerId': layerId, 'featureId': featureId})
    ];
  }
  if (action == 'intent.border.clear_over_object') {
    final instanceId = parameters.string('instanceId');
    if (!map.spatialScene!.instances
        .any((instance) => instance.id == instanceId)) {
      throw semanticFailure(
          'intent.instance_missing', 'Choose an existing placed object.');
    }
    final report = inspectSpatialMapIntegrity(manifest: manifest, map: map);
    final slots = {
      for (final overlap in report.borderObjectOverlaps)
        if (overlap.layerId == layerId &&
            overlap.featureId == featureId &&
            overlap.instanceId == instanceId)
          ...overlap.slotKeys
    }.toList()
      ..sort();
    return [
      for (final slot in slots)
        _operation('border_layer.feature_set_suppressed', {
          'layerId': layerId,
          'featureId': featureId,
          'slotKey': slot,
          'suppressed': true
        })
    ];
  }
  final lower = parameters.value('lowerHeight'),
      upper = parameters.value('upperHeight');
  if (lower is! num || upper is! num) {
    throw semanticFailure(
        'intent.height_invalid', 'Choose lowerHeight and upperHeight.');
  }
  final contours = computeHeightStepEdges(map,
      lowerHeight: lower.toDouble(),
      upperHeight: upper.toDouble(),
      region: parameters.contains('region')
          ? _region(parameters.object('region'))
          : null);
  if (contours.status != SpatialIntentResolutionState.resolved) {
    throw semanticFailure('intent.step_ambiguous',
        'This step needs an explicit contour or a different region.',
        details: {
          'reason': contours.reason ?? contours.status.name,
          'vertices': [
            for (final cell in contours.ambiguousVertices.take(20))
              cell.toJson()
          ],
        });
  }
  final blueprintId = parameters.string('blueprintId');
  final geometry = feature?.geometry;
  if (feature != null &&
      (feature.blueprintId != blueprintId ||
          geometry is! BorderStrokeGeometry)) {
    throw semanticFailure('intent.feature_incompatible',
        'Relink the profile or choose a linear feature explicitly.');
  }
  final strokes = [
    for (final (index, points) in contours.strokes.indexed)
      {
        'id':
            geometry is BorderStrokeGeometry && index < geometry.strokes.length
                ? geometry.strokes[index].id
                : 'step-$index',
        'closed': points.first == points.last,
        'points': [
          for (final point in points.first == points.last
              ? points.sublist(0, points.length - 1)
              : points)
            point.toJson()
        ],
      }
  ];
  if (feature == null) {
    return [
      _operation('border_layer.feature_create', {
        'layerId': layerId,
        'featureId': featureId,
        'name': optional('name') ?? featureId,
        'blueprintId': blueprintId,
        'seed': parameters.contains('seed') ? parameters.value('seed') : 0,
        'geometry': {
          'kind': 'stroke',
          'alignment': 'gridEdges',
          'strokes': strokes
        },
      })
    ];
  }
  return [
    _operation('border_layer.feature_update', {
      'layerId': layerId,
      'featureId': featureId,
      'geometry': {
        'kind': 'stroke',
        'alignment': 'gridEdges',
        'strokes': strokes
      },
    })
  ];
}

List<Map<String, Object?>> groundFillOperations(
    MapData map, Iterable<GridPos> cells,
    {String? layerId, String? materialId}) {
  final suggestion =
      suggestGroundFill(map, cells, layerId: layerId, materialId: materialId);
  if (suggestion.status != SpatialIntentResolutionState.resolved) {
    throw semanticFailure(
        suggestion.status == SpatialIntentResolutionState.noSource
            ? 'intent.ground.no_source'
            : 'intent.ground.ambiguous',
        'Choose a ground layer and material explicitly.',
        details: {
          'ambiguousCells': [
            for (final cell in suggestion.ambiguousCells.take(20)) cell.toJson()
          ],
          'noSourceCells': [
            for (final cell in suggestion.noSourceCells.take(20)) cell.toJson()
          ],
          'candidateGroups': [
            for (final entry in suggestion.candidates.entries.take(20))
              {
                'cell': entry.key.toJson(),
                'candidates': [
                  for (final value in entry.value)
                    {
                      'layerId': value.layerId,
                      'materialId': value.materialId,
                      'votes': value.votes
                    }
                ],
              }
          ],
        });
  }
  return [
    for (final stroke in suggestion.strokes)
      _operation('smart_tile.cell.paint_batch', {
        'layerId': stroke.layerId,
        'strokes': [
          {
            'materialId': stroke.materialId,
            'cells': [for (final cell in stroke.cells) cell.toJson()]
          }
        ],
      })
  ];
}

Map<String, Object?> _operation(
        String actionId, Map<String, Object?> parameters) =>
    {'actionId': actionId, 'actionVersion': 1, 'parameters': parameters};

Map<String, Object?> _object(Object? value) {
  if (value is! Map || value.keys.any((key) => key is! String)) {
    throw semanticFailure(
        'intent.parameters_invalid', 'Expected an object with named fields.');
  }
  return Map<String, Object?>.from(value);
}

List<GridPos> _cells(List<Object?> values) => [
      for (final value in values)
        () {
          final parameters =
              SemanticParameters(_object(value), allowed: {'x', 'y'});
          return GridPos(
              x: parameters.integer('x'), y: parameters.integer('y'));
        }()
    ];

MapRect _region(Map<String, Object?> raw) {
  final values =
      SemanticParameters(raw, allowed: {'x', 'y', 'width', 'height'});
  return MapRect(
      pos: GridPos(x: values.integer('x'), y: values.integer('y')),
      size: GridSize(
          width: values.integer('width'), height: values.integer('height')));
}

List<GridPos> _regionCells(MapRect region) {
  if (region.size.width < 1 ||
      region.size.height < 1 ||
      region.size.width * region.size.height > 4096) {
    throw semanticFailure(
        'intent.region_invalid', 'Choose a bounded nonempty region.');
  }
  return [
    for (var y = region.pos.y; y < region.pos.y + region.size.height; y++)
      for (var x = region.pos.x; x < region.pos.x + region.size.width; x++)
        GridPos(x: x, y: y)
  ];
}
