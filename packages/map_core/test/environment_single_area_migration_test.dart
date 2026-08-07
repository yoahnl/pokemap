import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

Map<String, dynamic> _area(String id, {int painted = 0, int generated = 0}) {
  return <String, dynamic>{
    'id': id,
    'name': 'Zone $id',
    'presetId': 'preset_$id',
    'mask': <String, dynamic>{
      'width': 2,
      'height': 2,
      'cells': <bool>[painted > 0, false, false, false],
    },
    'seed': 1,
    'generatedPlacementIds': <String>[
      for (var i = 0; i < generated; i++) 'p_${id}_$i',
    ],
  };
}

Map<String, dynamic> _mapWith(List<Map<String, dynamic>> areas) {
  return <String, dynamic>{
    'id': 'm',
    'name': 'M',
    'version': 'v6',
    'size': <String, dynamic>{'width': 2, 'height': 2},
    'layers': <Object?>[
      <String, dynamic>{
        'runtimeType': 'environment',
        'id': 'env',
        'name': 'Env',
        'content': <String, dynamic>{
          'targetTileLayerId': 'tiles',
          'areas': areas,
        },
      },
    ],
  };
}

void main() {
  test('drops the empty extras and keeps the authored zone', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[
        _area('a1'),
        _area('a2', painted: 1, generated: 3),
        _area('a3'),
      ]),
    );

    final layers = migrated['layers'] as List<Object?>;
    expect(layers, hasLength(1));
    final areas =
        ((layers.single as Map)['content'] as Map)['areas'] as List<Object?>;
    expect(areas, hasLength(1));
    expect((areas.single as Map)['id'], 'a2');
  });

  test('splits several authored zones into one layer each', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[
        _area('a1', painted: 1),
        _area('a2', generated: 2),
      ]),
    );

    final layers =
        (migrated['layers'] as List<Object?>).cast<Map<String, dynamic>>();
    expect(layers, hasLength(2));
    expect(layers[0]['id'], 'env');
    expect(layers[1]['id'], 'env__a2');
    for (final layer in layers) {
      expect((layer['content'] as Map)['areas'] as List, hasLength(1));
      expect((layer['content'] as Map)['targetTileLayerId'], 'tiles');
    }
  });

  test('keeps a single empty zone rather than emptying the layer', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[_area('a1')]),
    );

    final layers = migrated['layers'] as List<Object?>;
    final areas =
        ((layers.single as Map)['content'] as Map)['areas'] as List<Object?>;
    expect(areas, hasLength(1));
  });

  test('keeps one layer when every zone is empty', () {
    final migrated = migrateEnvironmentSingleAreaMapJson(
      _mapWith(<Map<String, dynamic>>[_area('a1'), _area('a2')]),
    );

    final layers = migrated['layers'] as List<Object?>;
    expect(layers, hasLength(1));
    final areas =
        ((layers.single as Map)['content'] as Map)['areas'] as List<Object?>;
    expect(areas, hasLength(1));
    expect((areas.single as Map)['id'], 'a1');
  });

  test('returns the same instance when nothing needs repairing', () {
    final json = _mapWith(<Map<String, dynamic>>[_area('a1', painted: 1)]);
    expect(identical(migrateEnvironmentSingleAreaMapJson(json), json), isTrue);
  });
}
