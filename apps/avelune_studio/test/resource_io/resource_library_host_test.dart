import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/authoring_resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  Future<AuthoringResourceFixture> open() async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    return fixture;
  }

  test(
    'individual description rejects oversize input, saves, reopens and clears',
    () async {
      final fixture = await open();
      final navigation = fixture.navigation;
      final item = resourceCatalog(fixture.workspace.project!)
          .firstWhere((item) => item.canonicalKind == 'element');
      final parameters = {
        'resourceKind': item.canonicalKind,
        'resourceId': item.id,
      };
      final invalid = await publishResourceLibraryChange(
        navigation,
        'resource.classify',
        {...parameters, 'description': 'x' * 2001},
      );
      expect(invalid, isNotNull);
      expect(
        (await fixture.reopen()).resourceLibraryCatalog.entryFor(
          item.canonicalKind,
          item.id,
        ),
        isNull,
      );
      expect(
        await publishResourceLibraryChange(navigation, 'resource.classify', {
          ...parameters,
          'description': 'Arbre pour les routes.',
        }),
        isNull,
      );
      expect(
        (await fixture.reopen()).resourceLibraryCatalog
            .entryFor(item.canonicalKind, item.id)
            ?.toJson()['description'],
        'Arbre pour les routes.',
      );
      expect(
        await publishResourceLibraryChange(navigation, 'resource.classify', {
          ...parameters,
          'description': null,
        }),
        isNull,
      );
      expect(
        (await fixture.reopen()).resourceLibraryCatalog
            .entryFor(item.canonicalKind, item.id)
            ?.toJson()['description'],
        isNull,
      );
    },
  );

  test(
    'component classification persists and filters hide it until requested',
    () async {
      final fixture = await open();
      final mapsBefore = await fixture.mapFiles();
      expect(
        await publishResourceLibraryChange(
          fixture.navigation,
          'resource.classify',
          {
            'resourceKind': 'element',
            'resourceId': 'arbre',
            'role': 'component',
          },
        ),
        isNull,
      );
      final project = await fixture.reopen();
      expect(
        project.resourceLibraryCatalog.entryFor('element', 'arbre')?.role,
        ResourceLibraryRole.component,
      );
      final items = resourceCatalog(project);
      final filters = ResourceCatalogFilterState();
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
        ).any((item) => item.identity == 'element:arbre'),
        isFalse,
      );
      filters.showComponents = true;
      expect(
        filterResourceCatalog(
          project,
          items,
          filters,
        ).any((item) => item.identity == 'element:arbre'),
        isTrue,
      );
      expect(
        await publishResourceLibraryChange(
          fixture.navigation,
          'resource.classify',
          {
            'resourceKind': 'element',
            'resourceId': 'arbre',
            'role': 'standard',
          },
        ),
        isNull,
      );
      expect(
        (await fixture.reopen()).resourceLibraryCatalog.entryFor(
          'element',
          'arbre',
        ),
        isNull,
      );
      expect(await fixture.mapFiles(), mapsBefore);
    },
  );

  test(
    'a captured classification revision cannot overwrite a newer change',
    () async {
      final fixture = await open();
      final revision = await fixture.navigation.captureResourceRevision();
      await fixture.resources.mutate('resource.classify', {
        'resourceKind': 'element',
        'resourceId': 'arbre',
        'familyId': 'vegetation',
      });
      expect(
        await fixture.navigation.captureResourceRevision(),
        isNot(revision),
      );
      expect(
        await publishResourceLibraryChange(
          fixture.navigation,
          'resource.classify',
          {
            'resourceKind': 'element',
            'resourceId': 'arbre',
            'familyId': 'trees',
          },
          expectedSnapshotRevision: revision,
        ),
        isNotNull,
      );
      expect(
        (await fixture.reopen()).resourceLibraryCatalog
            .entryFor('element', 'arbre')
            ?.familyId,
        'vegetation',
      );
    },
  );

  test('family and subfamily survive reopening and a parent with a child cannot be deleted', () async {
    final fixture = await open();
    expect(
      await publishResourceLibraryChange(
        fixture.navigation,
        'resource.family.create',
        {
          'familyId': 'personal-forest',
          'name': 'Forêt personnelle',
          'parentId': null,
        },
      ),
      isNull,
    );
    expect(
      await publishResourceLibraryChange(
        fixture.navigation,
        'resource.family.create',
        {
          'familyId': 'small-trees',
          'name': 'Petits arbres',
          'parentId': 'personal-forest',
        },
      ),
      isNull,
    );
    final catalog = (await fixture.reopen()).resourceLibraryCatalog;
    final root = catalog.families.singleWhere(
      (family) => family.id == 'personal-forest',
    );
    final child = catalog.families.singleWhere(
      (family) => family.id == 'small-trees',
    );
    expect(root.name, 'Forêt personnelle');
    expect(child.name, 'Petits arbres');
    expect(child.parentId, root.id);
    expect(catalog.descendantFamilyIds(root.id), {root.id, child.id});
    expect(
      await publishResourceLibraryChange(
        fixture.navigation,
        'resource.family.delete',
        {'familyId': root.id},
        destructive: true,
      ),
      isNotNull,
    );
    expect(
      (await fixture.reopen()).resourceLibraryCatalog.families
          .map((family) => family.id)
          .toSet(),
      {root.id, child.id},
    );
  });

  test(
    'an empty family can be deleted and the deletion survives reopening',
    () async {
      final fixture = await open();
      expect(
        await publishResourceLibraryChange(
          fixture.navigation,
          'resource.family.create',
          {
            'familyId': 'empty-family',
            'name': 'Famille vide',
            'parentId': null,
          },
        ),
        isNull,
      );
      expect(
        await publishResourceLibraryChange(
          fixture.navigation,
          'resource.family.delete',
          {'familyId': 'empty-family'},
          destructive: true,
        ),
        isNull,
      );
      expect(
        fixture.workspace.project!.resourceLibraryCatalog.families,
        isEmpty,
      );
      expect((await fixture.reopen()).resourceLibraryCatalog.families, isEmpty);
    },
  );

  test(
    'a shared definition cannot be silently reserved for one of its maps',
    () async {
      final fixture = await open();
      final before = await fixture.mapFiles();
      final failure = await publishResourceLibraryChange(
        fixture.navigation,
        'resource.classify',
        {
          'resourceKind': 'element',
          'resourceId': 'arbre',
          'familyId': null,
          'mapId': 'jardin',
        },
      );
      expect(failure, isNotNull);
      expect(
        (await fixture.reopen()).resourceLibraryCatalog.entryFor(
          'element',
          'arbre',
        ),
        isNull,
      );
      expect(await fixture.mapFiles(), before);
    },
  );
}
