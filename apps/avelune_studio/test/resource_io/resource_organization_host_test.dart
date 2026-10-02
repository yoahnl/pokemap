import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu_resource_host.dart';

void main() {
  testWidgets(
    'real folder create rename move resource refuse occupied and delete empty',
    (tester) async {
      final host = await UwUResourceHost.open(tester);
      await host.family(ResourceKind.images);
      await host.tap('resource-manage-containers');
      await host.tap('resource-container-create');
      await host.enter('resource-container-name', 'Forêt lumineuse');
      await host.tap('resource-management-save');
      final id = host.fixture.controller.project!.tilesetFolders.single.id;
      expect(
        find.byKey(ValueKey('resource-container-images-$id')),
        findsOneWidget,
      );
      await host.tap('resource-container-edit-$id');
      await host.enter('resource-container-name', 'Forêt d’été');
      await host.tap('resource-management-save');
      await tester.tap(find.text('Retour aux ressources').last);
      await pumpIo(tester, frames: 4);
      await host.action('images:atelier', 'Déplacer vers…');
      await host.choose('resource-move-destination', 'Forêt d’été');
      await host.tap('resource-management-save');
      expect((await host.reopen()).tilesets.single.folderId, id);
      await host.tap('resource-manage-containers');
      await host.tap('resource-container-delete-$id');
      expect(find.textContaining('1 ressource(s)'), findsWidgets);
      expect(find.text('Supprimer le dossier vide'), findsNothing);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester, frames: 3);
      await host.fixture.capture(tester, 'uwu3-folder-occupied');
      await tester.tap(find.text('Retour aux ressources').last);
      await pumpIo(tester, frames: 4);
      await host.action('images:atelier', 'Déplacer vers…');
      await host.choose('resource-move-destination', 'Sans dossier');
      await host.tap('resource-management-save');
      await host.tap('resource-manage-containers');
      await host.tap('resource-container-delete-$id');
      await tester.tap(find.text('Supprimer le dossier vide').last);
      await pumpIo(tester, frames: 16);
      expect((await host.reopen()).tilesetFolders, isEmpty);
      expect((await host.reopen()).tilesets.single.id, 'atelier');
    },
  );

  for (final family in [ResourceKind.decors, ResourceKind.terrains]) {
    testWidgets(
      'real ${family.name} empty categories remain listed and survive reopen',
      (tester) async {
        final host = await UwUResourceHost.open(tester);
        await host.family(family);
        await host.tap('resource-manage-containers');
        await host.tap('resource-container-create');
        await host.enter('resource-container-name', 'Catégorie encore vide');
        if (family == ResourceKind.terrains) {
          expect(
            find.byKey(const ValueKey('resource-container-parent')),
            findsNothing,
          );
        }
        await host.tap('resource-management-save');
        final project = await host.reopen();
        final id = family == ResourceKind.decors
            ? project.elementCategories
                  .singleWhere((entry) => entry.name == 'Catégorie encore vide')
                  .id
            : project.smartTileCatalog.categories.single.id;
        await host.tap('resource-container-${family.name}-$id');
        expect(host.navigation.library.category, id);
        expect(
          find.text(
            family == ResourceKind.terrains
                ? 'Cette famille ne contient aucune ressource.'
                : 'Aucune ressource correspondante.',
          ),
          findsOneWidget,
        );
        await host.fixture.capture(
          tester,
          'uwu3-${family.name}-empty-category',
        );
      },
    );
  }
}
