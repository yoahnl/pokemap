import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view_data.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_catalog_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  test(
    'moving a family updates its descendants and leaves unrelated rows intact',
    () {
      final catalog = ProjectLibraryCatalogView(
        ProjectResourceLibrary(
          ResourceLibraryCatalog(
            families: [
              ResourceFamily(id: 'decors', name: 'Décors', parentId: 'props'),
              ResourceFamily(id: 'lampes', name: 'Lampes', parentId: 'decors'),
            ],
          ),
          [
            ProjectLibraryItem(
              kind: 'model3d',
              id: 'lampe',
              name: 'Lampe',
              familyId: 'lampes',
            ),
            ProjectLibraryItem(
              kind: 'model3d',
              id: 'arbre',
              name: 'Arbre',
              familyId: 'trees',
            ),
          ],
        ),
        mapUsages: {
          'model3d:lampe': {'maison'},
        },
      );
      final unaffected = catalog.items.last;
      catalog.updateFamily(
        'decors',
        ResourceFamily(id: 'decors', name: 'Extérieurs', parentId: 'buildings'),
      );
      expect(catalog.items.first.familyIds, ['buildings', 'decors', 'lampes']);
      expect(catalog.items.first.familyPath, 'Bâtiments › Extérieurs › Lampes');
      expect(catalog.items.first.category, ResourceLibraryCategory.buildings);
      expect(catalog.items.first.usedOn, {'maison'});
      expect(catalog.items.last, same(unaffected));
    },
  );
}
