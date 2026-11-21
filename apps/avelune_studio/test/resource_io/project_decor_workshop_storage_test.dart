import 'dart:io';

import 'package:avelune_studio/features/decors/application/decor_draft.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/platform/files/native_resource_image_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import 'working_catalog_classification_fixture.dart';

void main() {
  test('publishes and edits a cutout while preserving the map draft', () async {
    final fixture = await ClassificationFixture.create(unrelated: 80);
    addTearDown(fixture.dispose);
    await fixture.openWorkspace();
    final maps = fixture.maps;
    final session = fixture.session;
    final resources = fixture.resources;
    final file = File('${fixture.root.path}/maps/jardin.json');
    final stored = await file.readAsBytes();
    final existingDraft = fixture.workspace.active!;
    existingDraft.commit(
      existingDraft.current.copyWith(name: 'Brouillon indépendant'),
    );
    final library = await maps.readResourceLibrary(session);
    final settings = fixture.workspace.project!.settings;
    final imported = await resources.importResource(
      await const NativeResourceImagePicker().inspectLibraryFile(
        '${fixture.root.path}/assets/atelier.png',
      ),
      name: 'Planche des décors',
      tileSize: (width: settings.tileWidth, height: settings.tileHeight),
      expectedRevision: library.revision!,
    );
    fixture.accept(imported.receipt);
    final source = await resources.readWorkshopDecor(
      'tileset',
      imported.item.id,
    );
    expect(source.project.elementCategories.single.id, 'atelier');
    final draft = DecorDraft(tileset: source.project.tilesets.single)
      ..name = 'Jardinière'
      ..selection = const TilesetSourceRect(x: 2, y: 0, width: 2, height: 3)
      ..setBlocked(true);
    final proposed = draft.build().copyWith(categoryId: 'atelier');
    final published = await resources.publishDecor(
      proposed,
      expectedRevision: source.revision,
    );
    expect(published.item.name, 'Jardinière');
    expect(published.receipt.changedElement, proposed);
    expect(published.receipt.changedMaps, isEmpty);
    expect(published.receipt.changedPaths, contains('catalog/HEAD.json'));
    fixture.workspace.acceptResources(
      published.receipt.before,
      published.receipt.manifest,
      changedElement: published.receipt.changedElement,
    );
    expect(existingDraft.current.name, 'Brouillon indépendant');
    expect(await file.readAsBytes(), stored);

    final updated = proposed.copyWith(collisionProfile: null);
    await expectLater(
      resources.publishDecor(updated, expectedRevision: source.revision),
      throwsA(isA<ResourceFailure>()),
    );
    final changed = await resources.publishDecor(
      updated,
      expectedRevision: published.receipt.revision,
    );
    expect(changed.receipt.changedElement, updated);
    await fixture.reopen();
    final loaded = await fixture.resources.readWorkshopDecor(
      'element',
      published.item.id,
    );
    expect(loaded.project.elements.single, updated);
    expect(loaded.project.tilesets.single.id, imported.item.id);
    expect(await file.readAsBytes(), stored);
  });
}
