import 'package:map_core/map_core.dart' show borderResolverVersion;

Map<String, Object?>? mapActionInputExample(String actionId) {
  const border = {'mapId': 'map', 'layerId': 'border', 'featureId': 'fence'};
  const points = [
    {'x': 3, 'y': 4},
    {'x': 4, 'y': 4},
    {'x': 5, 'y': 4},
    {'x': 6, 'y': 4}
  ];
  return switch (actionId) {
    'map.create' => {
        'mapId': 'new-field',
        'name': 'New field',
        'width': 24,
        'height': 16
      },
    'smart_tile.layer.create' => {
        'mapId': 'map',
        'layerId': 'new-ground',
        'name': 'Ground',
        'presetId': 'ground'
      },
    'smart_tile.cell.paint' => {
        'mapId': 'map',
        'layerId': 'terrain',
        'materialId': 'grass',
        'cells': [
          {'x': 12, 'y': 8}
        ]
      },
    'smart_tile.cell.erase' => {
        'mapId': 'map',
        'layerId': 'terrain',
        'cells': [
          {'x': 12, 'y': 8}
        ]
      },
    'smart_tile.cell.paint_batch' => {
        'mapId': 'map',
        'layerId': 'terrain',
        'strokes': [
          {
            'materialId': 'grass',
            'cells': [
              {'x': 12, 'y': 8}
            ]
          }
        ]
      },
    'map3d.terrain.surface.upsert_batch' => {
        'mapId': 'map',
        'surfaces': [
          {
            'id': 'lower-ground',
            'x': 0,
            'z': 0,
            'height': 0,
            'footprints': [
              [
                {'x': 0, 'z': 0},
                {'x': 24, 'z': 0},
                {'x': 24, 'z': 4},
                {'x': 0, 'z': 4}
              ]
            ]
          }
        ]
      },
    'map3d.terrain.surface.delete_batch' => {
        'mapId': 'map',
        'surfaceIds': ['lower-ground']
      },
    'map3d.instance.upsert_batch' => {
        'mapId': 'map',
        'instances': [
          {
            'id': 'marker',
            'modelId': 'tree',
            'position': {'x': 15, 'y': 1, 'z': 12},
            'rotationDegrees': 0,
            'scale': 1,
            'blocksMovement': false
          }
        ]
      },
    'map3d.instance.delete_batch' => {
        'mapId': 'map',
        'instanceIds': ['unrelated-object']
      },
    'border_layer.feature_create' => {
        ...border,
        'featureId': 'new-cliff',
        'name': 'Cliff',
        'blueprintId': 'fence',
        'seed': '42',
        'geometry': {
          'kind': 'stroke',
          'strokes': [
            {'id': 'step', 'points': points, 'closed': false}
          ]
        }
      },
    'border_layer.feature_update' => {...border, 'name': 'Edited cliff'},
    'border_layer.feature_delete' => {...border},
    'border_layer.feature_move' => {...border, 'dx': 1, 'dy': 0},
    'border_layer.stroke_add' => {
        ...border,
        'strokeId': 'second-step',
        'points': [
          {'x': 8, 'y': 4},
          {'x': 9, 'y': 4}
        ],
        'closed': false
      },
    'border_layer.stroke_update' => {
        ...border,
        'strokeId': 'step',
        'points': points,
        'closed': false
      },
    'border_layer.stroke_delete' => {...border, 'strokeId': 'step'},
    'border_layer.stroke_erase' => {
        ...border,
        'points': [
          {'x': 4, 'y': 4}
        ]
      },
    'border_layer.region_fill' || 'border_layer.region_clear' => {
        ...border,
        'x': 3,
        'y': 4,
        'width': 1,
        'height': 1
      },
    'border_layer.feature_set_replacement' => {
        ...border,
        'slotKey': '<slotKey from borderFeature>',
        'primitiveId': null
      },
    'border_layer.feature_set_suppressed' => {
        ...border,
        'slotKey': '<slotKey from borderFeature>',
        'suppressed': true
      },
    'border_layer.feature_clear_slot_override' => {
        ...border,
        'slotKey': '<slotKey from borderFeature>'
      },
    'border_layer.feature_set_keep_out' => {...border, 'regions': []},
    'border_layer.relink_apply' || 'border_layer.feature_set_blueprint' => {
        ...border,
        'targetBlueprintId': 'replacement'
      },
    'border_layer.materialize_batch_apply' => {
        'mapId': 'map',
        'features': [
          {'layerId': 'border', 'featureId': 'fence'}
        ],
        'tileWidthPx': 16,
        'tileHeightPx': 16,
        'resolverVersion': borderResolverVersion
      },
    _ => null,
  };
}
