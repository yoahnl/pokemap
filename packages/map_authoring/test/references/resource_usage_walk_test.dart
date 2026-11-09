import 'package:map_authoring/src/references/resource_usage_walk.dart';
import 'package:test/test.dart';

void main() {
  test(
      'reference walking preserves ambiguous fields, array paths and ignored text',
      () {
    expect(
        resourceReferences({
          'name': 'not-a-reference',
          'assetId': 'shared',
          'nested': {
            'modelId': 'tree',
            'tilesetIds': ['first', 'second']
          },
          'script': 'assetId modelId tilesetId',
        }).toList(),
        [
          (kind: 'cinematicMedia', id: 'shared', path: r'$.assetId'),
          (kind: 'asset', id: 'shared', path: r'$.assetId'),
          (kind: 'model3d', id: 'tree', path: r'$.nested.modelId'),
          (kind: 'tileset', id: 'first', path: r'$.nested.tilesetIds[0]'),
          (kind: 'tileset', id: 'second', path: r'$.nested.tilesetIds[1]'),
        ]);
  });
}
