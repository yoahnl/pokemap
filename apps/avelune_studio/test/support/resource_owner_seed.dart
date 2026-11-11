import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:map_core/map_core_domain.dart';

import '../resource_io/resource_fixture.dart';

Future<void> seedFreeDecor(ResourceFixture fixture, {bool placed = false}) async {
  final project = await fixture.maps.loadProject(fixture.session);
  final tilesetId = project.tilesets.single.id;
  await fixture.resources.mutate('element_category.upsert', {
    'category': {'id': 'nature', 'name': 'Nature'},
  });
  await fixture.resources.saveElement(
    fixture.element(tilesetId).copyWith(categoryId: 'nature'),
  );
  if (placed) {
    final document = await fixture.loadMap();
    await fixture.maps.saveMap(
      fixture.session,
      document,
      document.map.copyWith(
        placedElements: const [
          MapPlacedElement(
            id: 'placed-tree',
            layerId: 'ground',
            elementId: 'tree',
            pos: GridPos(x: 1, y: 1),
          ),
        ],
      ),
    );
  }
}

ResourceItem decorItem(ProjectManifest project, {String id = 'tree'}) =>
    resourceCatalog(project).singleWhere((item) => item.element?.id == id);
