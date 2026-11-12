import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_resource_panel.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/map_workspace_fixture.dart';

void main() {
  const selection = MapBuilderResourceSelection(
    category: ResourceUsageCategory.object,
    scope: ResourceCatalogScope.all,
    context: ResourceCatalogContext.all,
    query: '',
  );
  final library = ResourceLibraryCatalog(
    entries: [
      ResourceLibraryEntry(
        resourceKind: 'element',
        resourceId: 'tree',
        role: ResourceLibraryRole.component,
      ),
    ],
  );
  final visual = workspaceProject;
  final project = workspaceProject.copyWith(resourceLibraryCatalog: library);

  List<String> objects(ProjectManifest catalog) => [
    for (final item in mapBuilderResources(
      catalog,
      'a',
      mapBuilderCandidates(catalog, 'a', selection.category),
      selection,
    ))
      item.id,
  ];

  test('loaded definitions keep the library of the whole project', () {
    final catalog = mapBuilderCatalog(visual, project)!;

    expect(catalog.elements, visual.elements);
    expect(catalog.resourceLibraryCatalog, same(library));
    expect(objects(visual), ['tree']);
    expect(objects(catalog), isEmpty);
  });

  test('an already complete catalog is reused as is', () {
    expect(mapBuilderCatalog(project, project), same(project));
    expect(mapBuilderCatalog(null, project), same(project));
    expect(mapBuilderCatalog(visual, null), same(visual));
  });
}
