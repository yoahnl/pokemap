import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';

import '../tool/refine_selbrume_port_brisants_visuals.dart';

void main() {
  test('accepts only the declared visual refinement surface', () {
    final before = _fixtureMap();
    final after = _clone(before);

    _layer(after, portPrimaryPathLayerId)['cells'] = List<bool>.filled(
      portVisualMapCellCount,
      true,
    );
    _layer(after, 'l_path_secondary')['cells'] = List<bool>.filled(
      portVisualMapCellCount,
      true,
    );
    for (final layerId in portVisualTileLayerIds) {
      _layer(after, layerId)['tiles'] = List<int>.filled(
        portVisualMapCellCount,
        7,
      );
    }
    (after['placedElements'] as List).removeWhere(
      (entry) => portVisualReplaceablePlacementIds.contains(
        (entry as Map)['id'],
      ),
    );
    (after['properties'] as Map<String, dynamic>)
      ..['visualRefinerVersion'] = 2
      ..['visualRefinerManifestSchema'] = 1
      ..['visualRefinerComposition'] = 'port_reference_v3_photo_pass'
      ..['visualRefinerStatus'] = 'candidate_pending_owner_approval';

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      returnsNormally,
    );
  });

  test('rejects a change outside the visual whitelist', () {
    final before = _fixtureMap();
    final after = _clone(before)..['name'] = 'Renamed';

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects a non-cell change on the pavement layer', () {
    final before = _fixtureMap();
    final after = _clone(before);
    _layer(after, portPrimaryPathLayerId)['opacity'] = 0.5;

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects a non-cell change on the visual water layer', () {
    final before = _fixtureMap();
    final after = _clone(before);
    _layer(after, 'l_path_secondary')['opacity'] = 0.5;

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects movement of a protected placement', () {
    final before = _fixtureMap();
    final after = _clone(before);
    final protected = (after['placedElements'] as List)
        .cast<Map<String, dynamic>>()
        .singleWhere((entry) => entry['id'] == 'pe_port_protected');
    protected['pos'] = <String, dynamic>{'x': 4, 'y': 4};

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });

  test('rejects undeclared visualRefiner metadata', () {
    final before = _fixtureMap();
    final after = _clone(before);
    (after['properties'] as Map<String, dynamic>)['visualRefinerUnknown'] =
        true;

    expect(
      () => verifyOnlyPortVisualChanges(before: before, after: after),
      throwsStateError,
    );
  });
}

Map<String, dynamic> _fixtureMap() {
  return <String, dynamic>{
    'id': portVisualMapId,
    'name': 'Port des Brisants',
    'size': <String, dynamic>{
      'width': portVisualMapWidth,
      'height': portVisualMapHeight,
    },
    'properties': <String, dynamic>{'authoringGenerator': 'fixture'},
    'layers': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': portPrimaryPathLayerId,
        'runtimeType': 'path',
        'opacity': 1.0,
        'cells': List<bool>.filled(portVisualMapCellCount, false),
      },
      <String, dynamic>{
        'id': 'l_path_secondary',
        'runtimeType': 'path',
        'opacity': 1.0,
        'presetId': 'path_selbrume_port_water_v3',
        'cells': <bool>[
          ...List<bool>.filled(portVisualMapCellCount - 1, false),
          true,
        ],
      },
      for (final id in portVisualTileLayerIds)
        <String, dynamic>{
          'id': id,
          'runtimeType': 'tile',
          'opacity': 1.0,
          'tiles': List<int>.filled(portVisualMapCellCount, 0),
        },
      <String, dynamic>{
        'id': 'l_visual_protected',
        'runtimeType': 'tile',
        'tiles': List<int>.filled(portVisualMapCellCount, 0),
      },
    ],
    'placedElements': <Map<String, dynamic>>[
      <String, dynamic>{
        'id': portVisualReplaceablePlacementIds.first,
        'pos': <String, dynamic>{'x': 1, 'y': 1},
      },
      <String, dynamic>{
        'id': portVisualMovablePropPlacementIds.first,
        'pos': <String, dynamic>{'x': 2, 'y': 2},
      },
      <String, dynamic>{
        'id': 'pe_port_protected',
        'pos': <String, dynamic>{'x': 3, 'y': 3},
      },
    ],
    'opaqueContract': <String, dynamic>{'unchanged': true},
  };
}

Map<String, dynamic> _layer(Map<String, dynamic> map, String id) {
  return (map['layers'] as List)
      .cast<Map<String, dynamic>>()
      .singleWhere((layer) => layer['id'] == id);
}

Map<String, dynamic> _clone(Map<String, dynamic> value) {
  return jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
}
