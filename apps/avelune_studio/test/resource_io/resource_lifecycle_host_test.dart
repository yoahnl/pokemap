import 'dart:io';
import 'dart:typed_data';

import 'package:avelune_studio/features/resources/application/resource_catalog.dart';
import 'package:avelune_studio/features/resources/coordination/resource_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as image;
import 'package:avelune_studio/features/resources/domain/resource_image_picker.dart';

import '../support/resource_replacement_fixture.dart';
import '../support/run_resource_replacement.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu4_resource_host.dart';

void main() {
  testWidgets('decor duplicate action opens independent definition dialog', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    final before = host.fixture.controller.project!;
    final source = before.elements.first;
    await host.action('element:${source.id}', 'Dupliquer la définition…');
    expect(find.text('${source.name} — copie'), findsOneWidget);
    expect(find.textContaining('les instances déjà posées'), findsOneWidget);
    await host.enter('resource-duplicate-name', 'Copie indépendante');
    await host.fixture.capture(tester, 'uwu4-host-duplicate');
    await host.tap('resource-management-save');
    expect(
      find.byKey(const ValueKey('resource-management-error')),
      findsNothing,
      reason: find
          .byKey(const ValueKey('resource-management-error'))
          .evaluate()
          .map((e) => (e.widget as Text).data)
          .join(),
    );
    final reopened = await host.reopen();
    final copied = reopened.elements.singleWhere(
      (entry) => entry.name == 'Copie indépendante',
    );
    expect(copied.id, isNot(source.id));
    expect(copied.tilesetId, source.tilesetId);
    expect(copied.frames, source.frames);
    expect(reopened.tilesets, before.tilesets);
    expect(
      find.byKey(const ValueKey('resource-decor-workshop-unavailable-state')),
      findsOneWidget,
    );
    final draft = host.navigation.decor;
    expect(draft!.original!.id, copied.id);
    await host.tap('resource-decor-return-to-catalog');
    expect(host.navigation.page, ResourcePage.library);
    expect(host.navigation.decor, same(draft));
    expect((await host.reopen()).elements, reopened.elements);
  });

  testWidgets('used decor removal refuses and leaves definitions untouched', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester, placed: true);
    final before = host.fixture.controller.project!;
    final source = before.elements.first;
    await host.action('element:${source.id}', 'Supprimer la définition…');
    await pumpIo(tester, frames: 20);
    expect(find.textContaining('Définition de décor'), findsWidgets);
    expect(
      find.byKey(const ValueKey('resource-management-save')),
      findsOneWidget,
    );
    final button = tester.widget<StudioButton>(
      find.byKey(const ValueKey('resource-management-save')),
    );
    expect(button.onPressed, isNull);
    expect(
      find.byKey(const ValueKey('resource-removal-refusal')),
      findsOneWidget,
    );
    await host.fixture.capture(tester, 'uwu4-host-removal-refusal');
    await host.tap('resource-management-cancel');
    expect((await host.reopen()).elements, before.elements);
    expect((await host.reopen()).tilesets, before.tilesets);
  });

  test(
    'source replacement can be prepared without an active map or placement',
    () async {
      final host = await ResourceReplacementFixture.create(withMap: false);
      final fixture = host.fixture;
      final navigation = host.navigation;
      final imported = host.item.tileset!;
      final file = File('${fixture.root.path}/${imported.relativePath}');
      final bytes = Uint8List.fromList(await file.readAsBytes());
      final pixels = image.decodeImage(bytes)!;
      final before = await host.reopen();
      final maps = await fixture.mapFile.readAsBytes();
      expect(host.workspace.active, isNull);
      await runReplacementForTest(
        navigation: navigation,
        item: resourceCatalog(host.workspace.project!)
            .singleWhere((item) => item.tileset?.id == imported.id),
        picker: () async => PickedResourceImage(
          file.path,
          'Source compatible',
          bytes,
          pixels.width,
          pixels.height,
        ),
        isActive: () => true,
        present: (session) async {
          expect(session.preview.preparation.noChange, isTrue);
          expect(navigation.error, isNull);
          expect(host.workspace.active, isNull);
        },
      );
      expect(await host.reopen(), before);
      expect(await fixture.mapFile.readAsBytes(), maps);
      expect(await file.readAsBytes(), bytes);
      expect(navigation.managementDialogActive, isFalse);
    },
  );

  testWidgets('free definition then planche removal preserve source and map', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    final before = await host.reopen();
    final map = host.fixture.controller.active!.current;
    await host.action('element:tree', 'Supprimer la définition…');
    await host.tap('resource-removal-confirm');
    await host.tap('resource-management-save');
    expect((await host.reopen()).elements, isEmpty);
    expect((await host.reopen()).tilesets, before.tilesets);
    expect(host.fixture.controller.active!.current, map);
    await host.family(ResourceKind.images);
    await host.action(
      'tileset:${before.tilesets.single.id}',
      'Supprimer la planche…',
    );
    expect(
      tester
          .widget<CheckboxListTile>(
            find.byKey(const ValueKey('resource-removal-source')),
          )
          .value,
      isFalse,
    );
    await host.tap('resource-removal-confirm');
    await host.tap('resource-management-save');
    final reopened = await host.reopen();
    expect(reopened.tilesets, isEmpty);
    expect(reopened.elements, isEmpty);
    expect(host.fixture.controller.active!.current, map);
  });

  testWidgets(
    'duplicate saves only its focused decor owner after explicit choice',
    (tester) async {
      final host = await openUwU4ResourceHost(tester);
      final source = host.fixture.controller.project!.elements.single;
      host.navigation.edit(
        resourceCatalog(host.fixture.controller.project!)
            .singleWhere((item) => item.element?.id == source.id),
      );
      await pumpIo(tester, frames: 4);
      final draft = host.navigation.decor!..name = 'Arbre à copier';
      await host.tap('resource-decor-return-to-catalog');
      await pumpIo(tester, frames: 4);
      expect(host.navigation.decor, same(draft));
      await host.action('element:tree', 'Dupliquer la définition…');
      expect(find.text('Enregistrer et dupliquer'), findsOneWidget);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester);
      expect(host.navigation.decorDraftFor('tree')!.name, 'Arbre à copier');
      expect((await host.reopen()).elements.single.name, source.name);
      await host.action('element:tree', 'Dupliquer la définition…');
      await tester.tap(find.text('Enregistrer et dupliquer').last);
      await pumpIo(tester);
      expect(find.text('Arbre à copier — copie'), findsOneWidget);
      await host.tap('resource-management-save');
      final reopened = await host.reopen();
      expect(
        reopened.elements.singleWhere((entry) => entry.id == 'tree').name,
        'Arbre à copier',
      );
      expect(
        reopened.elements.where(
          (entry) => entry.name == 'Arbre à copier — copie',
        ),
        hasLength(1),
      );
    },
  );
}
