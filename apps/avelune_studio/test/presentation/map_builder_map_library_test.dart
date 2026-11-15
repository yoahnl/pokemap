import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_map_library_harness.dart';

void main() {
  Finder map(String id) => find.byKey(ValueKey('map-library-map-$id'));
  Finder folder(String id) => find.byKey(ValueKey('map-library-folder-$id'));

  Future<void> openMenu(WidgetTester tester, Finder row) async {
    await tester.tapAt(tester.getCenter(row), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
  }

  testWidgets('the add button creates a named map in a folder and opens it', (
    tester,
  ) async {
    final (controller, catalog) = await pumpMapLibrary(tester);
    await tester.tap(find.byKey(const ValueKey('map-library-add')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Nouvelle carte…'));
    await tester.pumpAndSettle();
    expect(
      find.text('Carte 2D, comme toutes les cartes de ce projet.'),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('map-library-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(find.text('Donnez un nom.'), findsOneWidget);
    expect(catalog.calls, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('map-library-new-name')),
      'Route 31',
    );
    await tester.enterText(
      find.byKey(const ValueKey('map-library-new-width')),
      '24',
    );
    await tester.enterText(
      find.byKey(const ValueKey('map-library-new-height')),
      '18',
    );
    await tester.tap(find.byType(StudioSelect));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Johto').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-library-dialog-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('map-library-dialog')), findsNothing);
    expect(catalog.calls.single.$1, 'map.create');
    expect(catalog.calls.single.$2, {
      'mapId': 'route-31',
      'name': 'Route 31',
      'width': 24,
      'height': 18,
      'groupId': 'johto',
    });
    expect(controller.active!.base.mapId, 'route-31');
    expect(map('route-31'), findsOneWidget);
  });

  testWidgets('right-click shows the map actions and duplicates', (
    tester,
  ) async {
    final (controller, catalog) = await pumpMapLibrary(tester);
    await openMenu(tester, map('b'));
    for (final label in [
      'Ouvrir',
      'Renommer',
      'Dupliquer',
      'Déplacer vers…',
      'Supprimer…',
    ]) {
      expect(find.text(label), findsOneWidget);
    }
    expect(find.text('F2'), findsOneWidget);
    await tester.tap(find.text('Dupliquer'));
    await tester.pumpAndSettle();
    expect(catalog.calls.single.$1, 'map.duplicate');
    expect(catalog.calls.single.$2['name'], 'Jardin (copie)');
    expect(controller.active!.base.mapId, 'jardin-copie');
    expect(find.text('Jardin (copie)'), findsOneWidget);
  });

  testWidgets('a double click renames inline, Escape cancels', (tester) async {
    final (controller, catalog) = await pumpMapLibrary(tester);
    await tester.tap(map('b'));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(map('b'));
    await tester.pumpAndSettle();
    final field = find.byKey(const ValueKey('map-library-rename-field'));
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Jardin du soir');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(catalog.calls.single.$1, 'map.update_metadata');
    expect(controller.project!.maps.last.name, 'Jardin du soir');
    expect(find.text('Jardin du soir'), findsOneWidget);

    await tester.sendKeyEvent(LogicalKeyboardKey.f2);
    await tester.pumpAndSettle();
    expect(field, findsOneWidget);
    await tester.enterText(field, 'Abandon');
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(field, findsNothing);
    expect(catalog.calls, hasLength(1));
    expect(find.text('Jardin du soir'), findsOneWidget);
  });

  testWidgets(
    'a double click focuses the rename field so typing replaces the name',
    (tester) async {
      final (controller, catalog) = await pumpMapLibrary(tester);
      expect(controller.active!.base.mapId, 'a');
      await tester.tap(map('b'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(map('b'));
      await tester.pumpAndSettle();
      expect(controller.active!.base.mapId, 'b');
      final field = find.descendant(
        of: find.byKey(const ValueKey('map-library-rename-field')),
        matching: find.byType(EditableText),
      );
      expect(tester.widget<EditableText>(field).focusNode.hasFocus, isTrue);
      tester.testTextInput.updateEditingValue(
        const TextEditingValue(text: 'Jardin du matin'),
      );
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();
      expect(catalog.calls.single.$2['name'], 'Jardin du matin');
    },
  );

  testWidgets('a right click opens the menu without opening the map', (
    tester,
  ) async {
    final (controller, _) = await pumpMapLibrary(tester);
    expect(controller.active!.base.mapId, 'a');
    await openMenu(tester, map('b'));
    expect(controller.active!.base.mapId, 'a');
    await tester.tap(find.text('Ouvrir'));
    await tester.pumpAndSettle();
    expect(controller.active!.base.mapId, 'b');
  });

  testWidgets(
    'deleting a used map lists its users by name and offers no delete',
    (tester) async {
      final (controller, catalog) = await pumpMapLibrary(tester);
      catalog.usages['b'] = [
        {
          'kind': 'sourceMap',
          'id': 'w',
          'scope': 'map',
          'parentId': 'a',
          'sourceKind': 'warp',
        },
        {
          'kind': 'sourceMap',
          'id': 'newGame',
          'scope': 'project',
          'sourceKind': 'newGame',
        },
      ];
      await openMenu(tester, map('b'));
      await tester.tap(find.text('Supprimer…'));
      await tester.pumpAndSettle();
      expect(find.text('« Jardin » est utilisée'), findsOneWidget);
      expect(
        find.text(
          'Carte « Clairière » : passage, liaison ou élément vers cette carte',
        ),
        findsOneWidget,
      );
      expect(
        find.text('Nouvelle partie : carte de départ du joueur'),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('map-library-delete-confirm')),
        findsNothing,
      );
      await tester.tap(find.byKey(const ValueKey('map-library-delete-close')));
      await tester.pumpAndSettle();
      expect(catalog.calls, isEmpty);
      expect(controller.project!.maps, hasLength(2));
    },
  );

  testWidgets('an unused map is deleted from the keyboard after confirmation', (
    tester,
  ) async {
    final (controller, catalog) = await pumpMapLibrary(tester);
    await tester.tap(map('b'));
    await tester.pumpAndSettle();
    await tester.pump(kDoubleTapTimeout);
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    expect(find.text('Supprimer « Jardin » ?'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('map-library-delete-confirm')));
    await tester.pumpAndSettle();
    expect(catalog.calls.single.$1, 'map.delete_apply');
    expect(map('b'), findsNothing);
    expect(controller.project!.maps.map((m) => m.id), ['a']);
  });

  testWidgets('folders get subfolders, move targets and an explained refusal', (
    tester,
  ) async {
    final (controller, catalog) = await pumpMapLibrary(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-library-folder-menu-johto')),
    );
    await tester.pumpAndSettle();
    final delete = find.byKey(const ValueKey('map-library-menu-delete-folder'));
    expect(
      find.ancestor(
        of: delete,
        matching: find.byWidgetPredicate(
          (w) =>
              w is Tooltip && w.message?.startsWith('Videz ce dossier') == true,
        ),
      ),
      findsOneWidget,
    );
    await tester.tap(find.text('Nouveau sous-dossier…'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('map-library-folder-name')),
      'Routes',
    );
    await tester.tap(find.byKey(const ValueKey('map-library-dialog-confirm')));
    await tester.pumpAndSettle();
    final routes = controller.project!.groups.singleWhere(
      (g) => g.name == 'Routes',
    );
    expect(routes.parentGroupId, 'johto');

    await openMenu(tester, map('b'));
    await tester.tap(find.text('Déplacer vers…'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(StudioSelect));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Johto / Routes').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('map-library-dialog-confirm')));
    await tester.pumpAndSettle();
    expect(catalog.calls.last.$1, 'map.library.reorganize');
    expect(controller.project!.maps.last.groupId, routes.id);
    expect(folder(routes.id), findsOneWidget);
  });

  testWidgets('the library speaks English when the Studio does', (
    tester,
  ) async {
    await pumpMapLibrary(tester, locale: const Locale('en'));
    await openMenu(tester, map('b'));
    expect(find.text('Duplicate'), findsOneWidget);
    expect(find.text('Move to…'), findsOneWidget);
    expect(find.text('Delete…'), findsOneWidget);
  });
}
