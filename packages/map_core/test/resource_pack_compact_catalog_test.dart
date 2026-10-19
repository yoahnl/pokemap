import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  for (final custom in [false, true]) {
    test(
      'portable catalog omits redundant values and preserves ${custom ? 'custom' : 'default'} Smart Tile semantics',
      () {
        final smart = ProjectSmartTileCatalog.fromJson({
          'formatVersion': ProjectSmartTileCatalog.currentFormatVersion,
          'materials': [
            {'id': 'grass', 'name': 'Grass', 'connectionGroupId': 'ground'},
          ],
          'presets': [
            {
              'id': 'terrain',
              'name': 'Terrain',
              'usage': 'terrain',
              'status': 'published',
              'topology': 'uniform',
              'coveragePolicy': 'complete',
              'coverageProfile': {'mode': 'template'},
              'transformPolicy': <String, dynamic>{},
              'defaultMaterialId': 'grass',
              'allowedMaterialIds': ['grass'],
              'rules': [
                {
                  'id': 'rule',
                  'centerMatch': {'kind': 'material', 'materialId': 'grass'},
                  'candidates': [
                    {
                      'id': 'candidate',
                      if (custom) 'weight': 3,
                      if (custom) 'label': 'Whole object',
                      'parts': [
                        {
                          'source': {
                            'kind': 'frame',
                            'frame': {
                              'atlasId': 'atlas',
                              'column': 2,
                              'row': 3,
                              if (custom) 'columnSpan': 2,
                              if (custom) 'rowSpan': 3,
                            },
                          },
                          if (custom) 'channel': 'foreground',
                          if (custom) 'offsetX': 7,
                          if (custom) 'offsetY': -4,
                          if (custom) 'drawOrder': 5,
                          if (custom)
                            'transform': {'quarterTurns': 1, 'flipX': true},
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          ],
        });
        final catalog = ResourcePackCatalog(smartTileCatalog: smart);
        final encoded = catalog.toJson();
        final encodedSmart = encoded['smartTileCatalog'] as Map;
        final expanded = smart.toJson(compact: false)..remove('drafts');
        expect(_nodes(encodedSmart), lessThan(_nodes(expanded)));
        expect(encodedSmart.containsKey('drafts'), isFalse);
        final restored = ResourcePackCatalog.fromJson(encoded);
        expect(restored.smartTileCatalog, smart);
        expect(
          restored.smartTileCatalog.toJson(compact: false),
          smart.toJson(compact: false),
        );
      },
    );
  }
}

int _nodes(Object? value) =>
    1 +
    switch (value) {
      Map() => value.values.fold<int>(0, (sum, child) => sum + _nodes(child)),
      List() => value.fold<int>(0, (sum, child) => sum + _nodes(child)),
      _ => 0,
    };
