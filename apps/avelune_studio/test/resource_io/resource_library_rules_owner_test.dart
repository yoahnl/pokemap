import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_category_tree.dart';
import 'package:avelune_studio/features/resources/application/resource_library_rules.dart';
import 'package:avelune_studio/features/resources/application/resource_open_map_usage.dart';
import 'package:avelune_studio/features/resources/application/resource_palette_reveal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/border_catalog_fixture.dart';
import '../support/map_workspace_fixture.dart';

final _project = workspaceProject.copyWith(
  elementCategories: const [
    ProjectElementCategory(id: 'decor', name: 'Décor de jardin'),
  ],
  resourceLibraryCatalog: ResourceLibraryCatalog(
    families: [ResourceFamily(id: 'jardin', name: 'Jardins')],
  ),
);

void main() {
  test('only the border, 3D model and environment workshops leave the regular catalogue', () {
    for (final family in ResourceLibraryFamily.values) {
      expect(
        resourceLibraryRegular(atelierVisible: false, family: family),
        isTrue,
        reason: '$family without workshop',
      );
      expect(
        resourceLibraryRegular(atelierVisible: true, family: family),
        !{
          ResourceLibraryFamily.borders,
          ResourceLibraryFamily.models3d,
          ResourceLibraryFamily.environments,
        }.contains(family),
        reason: '$family with workshop',
      );
    }
  });

  test('family label resolves custom families, the unclassified bucket and unknown ids', () {
    expect(resourceLibraryFamilyName(_project, 'jardin'), 'Jardins');
    expect(resourceLibraryFamilyName(_project, 'trees'), 'Arbres');
    expect(
      resourceLibraryFamilyName(_project, unclassifiedResourceFamily),
      'Sans famille',
    );
    expect(resourceLibraryFamilyName(_project, ''), isNull);
    expect(resourceLibraryFamilyName(_project, 'inconnue'), isNull);
  });

  test('category label exists only inside a workshop and resolves the uncategorized bucket', () {
    final tree = ResourceCategoryTree(
      _project,
      ResourceKind.decors,
      resourceCatalog(_project),
    );
    String? label(bool atelier, String category) => resourceLibraryCategoryName(
      atelierVisible: atelier,
      category: category,
      tree: tree,
    );
    expect(label(true, 'decor'), 'Décor de jardin');
    expect(label(false, 'decor'), isNull);
    expect(label(true, ''), isNull);
    expect(label(true, uncategorizedResourceCategory), 'Sans catégorie');
    expect(label(true, 'absente'), isNull);
  });

  test('using a resource reveals the palette tab matching its kind', () {
    const kind = ResourceKind.decors;
    final terrain = ResourceItem(
      id: 'p',
      name: 'P',
      kind: ResourceKind.terrains,
      terrain: ProjectSmartTilePreset(
        id: 'p',
        name: 'P',
        usage: SmartTileUsage.path,
        topology: SmartTileTopology.uniform,
        coveragePolicy: SmartTileCoveragePolicy.complete,
        coverageProfile: const SmartTileCoverageProfile(
          mode: SmartTileCoverageMode.template,
        ),
        transformPolicy: const SmartTileTransformPolicy(),
        defaultMaterialId: 'p',
        allowedMaterialIds: ['p'],
      ),
    );
    expect(resourcePaletteReveal(terrain), (tab: null));
    final borderProject = workspaceProject.copyWith(
      borderCatalog: testBorderCatalog(),
    );
    expect(
      resourcePaletteReveal(
        resourceCatalog(
          borderProject,
        ).singleWhere((item) => item.border != null),
      ),
      (tab: 'Bordures'),
    );
    expect(
      resourcePaletteReveal(
        const ResourceItem(
          id: 'tree',
          name: 'Arbre',
          kind: kind,
          element: workspaceElement,
        ),
      ),
      (tab: 'Décors'),
    );
    expect(
      resourcePaletteReveal(
        ResourceItem(
          id: 'atlas',
          name: 'Exemple',
          kind: ResourceKind.images,
          tileset: workspaceProject.tilesets.single,
        ),
      ),
      isNull,
    );
    expect(
      resourcePaletteReveal(
        const ResourceItem(
          id: 'guide',
          name: 'Guide',
          kind: ResourceKind.images,
          character: ProjectCharacterEntry(
            id: 'guide',
            name: 'Guide',
            tilesetId: 'atlas',
          ),
        ),
      ),
      isNull,
    );
  });

  test('open map usage counts placed decors and painted sheets on the open maps only', () {
    final withTrees = workspaceMap('a').copyWith(
      placedElements: const [
        MapPlacedElement(
          id: 'p1',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 1, y: 1),
        ),
        MapPlacedElement(
          id: 'p2',
          layerId: 'ground',
          elementId: 'tree',
          pos: GridPos(x: 2, y: 1),
        ),
        MapPlacedElement(
          id: 'p3',
          layerId: 'ground',
          elementId: 'rock',
          pos: GridPos(x: 3, y: 1),
        ),
      ],
    );
    final other = workspaceMap('b');
    const decor = ResourceItem(
      id: 'tree',
      name: 'Arbre',
      kind: ResourceKind.decors,
      element: workspaceElement,
    );
    final sheet = ResourceItem(
      id: 'atlas',
      name: 'Exemple',
      kind: ResourceKind.images,
      tileset: workspaceProject.tilesets.single,
    );
    expect(resourceOpenMapUsage(decor, [withTrees, other]), 2);
    expect(resourceOpenMapUsage(decor, [other]), 0);
    expect(resourceOpenMapUsage(decor, const []), 0);
    expect(resourceOpenMapUsage(sheet, [withTrees, other]), 2);
  });
}
