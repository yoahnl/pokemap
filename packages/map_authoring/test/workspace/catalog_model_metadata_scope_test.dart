import 'package:map_authoring/src/workspace/catalog/catalog_workshop_selection.dart';
import 'package:test/test.dart';

void main() {
  for (final fields in <Map<String, Object?>>[
    {'collisionBounds': null},
    {
      'collisionBounds': {
        'min': {'x': -.2, 'y': 0, 'z': -.2},
        'max': {'x': .2, 'y': 2, 'z': .2}
      }
    },
    {'light': null, 'collisionBounds': null},
  ]) {
    test('bounded model metadata admits exactly $fields', () {
      expect(
          CatalogWorkshopSelection.supports('model3d.configure',
              parameters: {'modelId': 'tree', ...fields}),
          isTrue);
    });
  }
  for (final extra in ['scale', 'pivot', 'name', 'castsShadowsByDefault']) {
    test('bounded model metadata refuses an added $extra field', () {
      expect(
          CatalogWorkshopSelection.supports('model3d.configure', parameters: {
            'modelId': 'tree',
            'collisionBounds': null,
            extra: null
          }),
          isFalse);
    });
  }
  test('model identity alone is not an admitted metadata mutation', () {
    expect(
        CatalogWorkshopSelection.supports('model3d.configure',
            parameters: {'modelId': 'tree'}),
        isFalse);
  });
}
