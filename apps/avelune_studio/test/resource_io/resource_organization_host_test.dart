import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/application/resource_containers.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/authoring_resource_fixture.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<AuthoringResourceFixture> open() async {
    final fixture = await AuthoringResourceFixture.create();
    addTearDown(fixture.dispose);
    return fixture;
  }

  Future<String?> upsert(
    AuthoringResourceFixture fixture,
    ResourceKind family,
    ResourceContainer entry,
  ) async => publishResourceManagementChange(
    fixture.navigation,
    await fixture.navigation.captureResourceRevision(),
    containerAction(family, 'upsert'),
    containerParameters(family, entry),
  );

  Future<String?> move(AuthoringResourceFixture fixture, String? id) async {
    final item = resourceCatalog(fixture.workspace.project!)
        .singleWhere((item) => item.tileset != null);
    final (action, parameters) = resourceMoveParameters(item, id);
    return publishResourceManagementChange(
      fixture.navigation,
      await fixture.navigation.captureResourceRevision(),
      action,
      parameters,
      reveal: item,
    );
  }

  test('folder create rename move occupied refusal and empty deletion persist without changing maps', () async {
    final fixture = await open();
    final navigation = fixture.navigation;
    final maps = await fixture.mapFiles();
    final tileset = fixture.workspace.project!.tilesets.single;
    const initial = ResourceContainer('forest', 'Forêt lumineuse', null, 0);
    const renamed = ResourceContainer('forest', 'Forêt d’été', null, 0);
    expect(await upsert(fixture, ResourceKind.images, initial), isNull);
    expect(await upsert(fixture, ResourceKind.images, renamed), isNull);
    expect((await fixture.reopen()).tilesetFolders.single.name, renamed.name);
    expect(await move(fixture, initial.id), isNull);
    expect((await fixture.reopen()).tilesets.single.folderId, initial.id);
    selectResourceContainer(navigation, ResourceKind.images, initial.id);
    expect(
      await deleteResourceContainer(navigation, ResourceKind.images, renamed),
      isNotNull,
    );
    expect(navigation.library.category, initial.id);
    expect((await fixture.reopen()).tilesetFolders.single.id, initial.id);
    expect(await move(fixture, null), isNull);
    selectResourceContainer(navigation, ResourceKind.images, initial.id);
    expect(
      await deleteResourceContainer(navigation, ResourceKind.images, renamed),
      isNull,
    );
    final reopened = await fixture.reopen();
    expect(reopened.tilesetFolders, isEmpty);
    expect(reopened.tilesets.single, tileset);
    expect(navigation.library.category, '');
    expect(await fixture.mapFiles(), maps);
  });

  test('a parent with a child cannot be deleted and another family selection is preserved', () async {
    final fixture = await open();
    const parent = ResourceContainer('parent', 'Parent', null, 0);
    const child = ResourceContainer('child', 'Enfant', 'parent', 0);
    expect(await upsert(fixture, ResourceKind.images, parent), isNull);
    expect(await upsert(fixture, ResourceKind.images, child), isNull);
    expect(
      await deleteResourceContainer(
        fixture.navigation,
        ResourceKind.images,
        parent,
      ),
      isNotNull,
    );
    expect(
      (await fixture.reopen()).tilesetFolders.map((entry) => entry.id).toSet(),
      {'parent', 'child'},
    );
    selectResourceContainer(fixture.navigation, ResourceKind.decors, 'atelier');
    expect(
      await deleteResourceContainer(
        fixture.navigation,
        ResourceKind.images,
        child,
      ),
      isNull,
    );
    expect(
      await deleteResourceContainer(
        fixture.navigation,
        ResourceKind.images,
        parent,
      ),
      isNull,
    );
    expect(fixture.navigation.library.kind, ResourceKind.decors);
    expect(fixture.navigation.library.category, 'atelier');
    expect((await fixture.reopen()).tilesetFolders, isEmpty);
  });

  for (final family in [ResourceKind.decors, ResourceKind.terrains]) {
    test(
      'empty ${family.name} categories persist and remain selectable without changing their resources',
      () async {
        final fixture = await open();
        final before = fixture.workspace.project!;
        final maps = await fixture.mapFiles();
        final category = ResourceContainer(
          'empty-${family.name}',
          'Catégorie encore vide',
          null,
          0,
        );
        expect(await upsert(fixture, family, category), isNull);
        final reopened = await fixture.reopen();
        final stored = resourceContainers(
          reopened,
          family,
        ).singleWhere((entry) => entry.id == category.id);
        expect(stored.name, category.name);
        expect(stored.parentId, isNull);
        selectResourceContainer(fixture.navigation, family, stored.id);
        expect(fixture.navigation.library.kind, family);
        expect(fixture.navigation.library.category, stored.id);
        expect(reopened.elements, before.elements);
        expect(
          reopened.smartTileCatalog.presets,
          before.smartTileCatalog.presets,
        );
        expect(await fixture.mapFiles(), maps);
      },
    );
  }
}
