import 'package:avelune_studio/presentation/features/resources/resource_catalog.dart';
import 'package:avelune_studio/presentation/features/resources/resource_navigation.dart';
import 'package:avelune_studio/presentation/shared/widgets/buttons/studio_button.dart';
import 'package:avelune_studio/presentation/features/resources/decor_editor_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../support/m2_ui_fixture.dart';
import '../support/uwu4_resource_host.dart';

void main() {
  testWidgets('decor duplicate action opens independent definition dialog', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    final before = host.fixture.controller.project!;
    final source = before.elements.first;
    await host.action('decors:${source.id}', 'Dupliquer la définition…');
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
    expect(find.byType(DecorEditorScreen), findsOneWidget);
  });

  testWidgets('used decor removal refuses and leaves definitions untouched', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester, placed: true);
    final before = host.fixture.controller.project!;
    final source = before.elements.first;
    await host.action('decors:${source.id}', 'Supprimer la définition…');
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

  testWidgets('image source replacement is reachable without placing image', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    await host.family(ResourceKind.images);
    final imported = host.fixture.controller.project!.tilesets.single;
    final before = host.fixture.controller.active!.current;
    await host.action('images:${imported.id}', 'Remplacer l’image source…');
    await pumpIo(tester, frames: 6);
    expect(host.navigation.error, isNull);
    expect(host.fixture.controller.active!.current, before);
    expect(find.text('Remplacer l’image source'), findsOneWidget);
    expect(find.text('Actuellement'), findsOneWidget);
    expect(find.text('Après remplacement'), findsOneWidget);
    await host.fixture.capture(tester, 'uwu4-host-replacement-comparison');
    await host.tap('resource-management-cancel');
  });

  testWidgets('free definition then planche removal preserve source and map', (
    tester,
  ) async {
    final host = await openUwU4ResourceHost(tester);
    final before = await host.reopen();
    final map = host.fixture.controller.active!.current;
    await host.action('decors:tree', 'Supprimer la définition…');
    await host.tap('resource-removal-confirm');
    await host.tap('resource-management-save');
    expect((await host.reopen()).elements, isEmpty);
    expect((await host.reopen()).tilesets, before.tilesets);
    expect(host.fixture.controller.active!.current, map);
    await host.family(ResourceKind.images);
    await host.action(
      'images:${before.tilesets.single.id}',
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
      final edit = find.text('Modifier le décor').last;
      await tester.ensureVisible(edit);
      await tester.tap(edit);
      await pumpIo(tester, frames: 4);
      await tester.enterText(
        find.widgetWithText(TextField, 'Nom du décor'),
        'Arbre à copier',
      );
      await tester.tap(find.text('Retour aux ressources').last);
      await pumpIo(tester, frames: 4);
      await host.action('decors:tree', 'Dupliquer la définition…');
      expect(find.text('Enregistrer et dupliquer'), findsOneWidget);
      await tester.tap(find.text('Annuler').last);
      await pumpIo(tester);
      expect(host.navigation.decorDraftFor('tree')!.name, 'Arbre à copier');
      expect((await host.reopen()).elements.single.name, source.name);
      await host.action('decors:tree', 'Dupliquer la définition…');
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
