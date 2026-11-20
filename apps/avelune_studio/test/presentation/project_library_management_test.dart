import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_controller.dart';
import 'package:avelune_studio/features/project_session/domain/project_session.dart';
import 'package:avelune_studio/features/resources/application/project_resource_library.dart';
import 'package:avelune_studio/features/resources/domain/project_library_editor.dart';
import 'package:avelune_studio/features/resources/domain/resource_mutation_preparation.dart';
import 'package:avelune_studio/features/resources/domain/resource_port.dart';
import 'package:avelune_studio/presentation/features/resources/project_library_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import '../support/scoped_map_workspace_port.dart';

part 'project_library_management_fixture.dart';

void main() {
  testWidgets('browsing and editing work while composite dimensions arrive', (
    tester,
  ) async {
    final port = _DimensionLibraryPort();
    final (_, editor) = await _open(tester, port);
    final dimension = find.byWidgetPredicate(
      (widget) => widget is StudioSelect && widget.label == 'Dimension',
    );
    final tree = find.byKey(const ValueKey('library-item-element:tree'));
    final woodland = find.byKey(
      const ValueKey('library-item-environmentPreset:woodland'),
    );
    expect(find.text('Calcul…'), findsOneWidget);
    expect(tester.widget<StudioSelect>(dimension).onChanged, isNull);
    expect(find.text('Ateliers'), findsOneWidget);
    expect(tree, findsOneWidget);
    expect(woodland, findsOneWidget);

    final search = find.descendant(
      of: find.byKey(const ValueKey('library-search')),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'bosquet');
    await tester.pumpAndSettle();
    expect(tree, findsNothing);
    expect(woodland, findsOneWidget);

    await tester.enterText(search, '');
    await tester.pumpAndSettle();
    await tester.tap(tree);
    await tester.pumpAndSettle();
    await _chooseAction(tester, 'Renommer');
    await tester.enterText(
      find.byKey(const ValueKey('library-edit-name')),
      'Chêne',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(editor.revisions, ['library-r0']);
    expect(port.dimensionRevisions, ['library-r0']);

    port.firstDimensions.complete(null);
    await tester.pumpAndSettle();
    expect(port.dimensionRevisions, ['library-r0', 'library-r1']);
    expect(tester.widget<StudioSelect>(dimension).onChanged, isNull);
    port.updatedDimensions.complete({
      'environmentPreset:woodland': {ProjectDimension.threeD},
    });
    await tester.pumpAndSettle();

    await tester.tap(dimension);
    await tester.pumpAndSettle();
    await tester.tap(find.text('3D').last);
    await tester.pumpAndSettle();
    expect(tree, findsNothing);
    expect(woodland, findsOneWidget);
    expect(port.libraryReads, 1);
    expect(port.dimensionRevisions, ['library-r0', 'library-r1']);
  });

  testWidgets('library actions persist and reveal a reclassified item', (
    tester,
  ) async {
    final port = _LibraryPort();
    final (maps, editor) = await _open(tester, port);
    tester.view.physicalSize = const Size(1000, 720);
    await tester.pumpAndSettle();
    final map = maps.active!;
    map.commit(map.current.copyWith(name: 'Brouillon en cours'));

    expect(find.text('Importer'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('library-item-element:tree')));
    await tester.pumpAndSettle();
    final modify = find.text('Modifier');
    final actions = find.byTooltip('Autres actions');
    expect(modify, findsOneWidget);
    expect(actions, findsOneWidget);
    expect(find.bySemanticsLabel('Autres actions'), findsOneWidget);
    expect(tester.getCenter(modify).dy, tester.getCenter(actions).dy);
    expect(find.text('Renommer'), findsNothing);
    expect(find.text('Classer'), findsNothing);
    expect(find.text('Dupliquer'), findsNothing);
    expect(find.text('Supprimer…'), findsNothing);
    await tester.tap(actions);
    await tester.pumpAndSettle();
    final menu = tester.widget<StudioContextMenuPanel>(
      find.byType(StudioContextMenuPanel),
    );
    expect(
      menu.items.whereType<StudioContextMenuEntry>().map((item) => item.label),
      ['Renommer', 'Classer', 'Dupliquer', 'Supprimer…'],
    );
    expect(menu.items[3], isA<StudioContextMenuSeparator>());
    expect((menu.items.last as StudioContextMenuEntry).destructive, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();
    expect(find.byType(StudioContextMenuPanel), findsNothing);
    expect(editor.revisions, isEmpty);
    await _chooseAction(tester, 'Renommer');
    await tester.enterText(
      find.byKey(const ValueKey('library-edit-name')),
      'Chêne',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Chêne'), findsNWidgets(2));
    expect(editor.revisions, ['library-r0']);

    await _chooseAction(tester, 'Classer');
    await tester.tap(find.byKey(const ValueKey('library-edit-role')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Composant technique').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('library-item-element:tree')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('library-detail-element:tree')),
      findsOneWidget,
    );
    expect(editor.revisions, ['library-r0', 'library-r1']);
    expect(editor.role, ResourceLibraryRole.component);
    port.usages.complete({
      'element:tree': {map.base.mapId},
    });
    await tester.pumpAndSettle();
    expect(find.text('Chêne'), findsNWidgets(3));
    expect(find.text('Utilisation dans les cartes'), findsOneWidget);
    expect(port.libraryReads, 1);
    expect(maps.active, same(map));
    expect(map.current.name, 'Brouillon en cours');
    expect(map.dirty, isTrue);
  });

  testWidgets(
    'import selects the new item and a published edit cannot replay',
    (tester) async {
      final port = _LibraryPort();
      final (_, editor) = await _open(
        tester,
        port,
        file: const PickedProjectLibraryFile(
          path: '/picked.png',
          name: 'Planche',
          imageSize: (width: 160, height: 64),
        ),
      );
      await tester.tap(find.text('Importer'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Importer dans la bibliothèque'));
      await tester.pumpAndSettle();
      expect(editor.importTileSize, (width: 160, height: 64));
      expect(
        find.byKey(const ValueKey('library-detail-tileset:imported')),
        findsOneWidget,
      );

      await _chooseAction(tester, 'Renommer');
      await tester.enterText(
        find.byKey(const ValueKey('library-edit-name')),
        'Nouvelle planche',
      );
      await tester.pump();
      editor.failure = const ResourceFailure(
        'Écriture momentanément indisponible.',
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(find.text('Écriture momentanément indisponible.'), findsOneWidget);
      expect(find.text('Nouvelle planche'), findsOneWidget);

      editor.failure = ResourceFailure(
        'Relecture indisponible',
        partialReceipt: editor.receipt,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(
        find.textContaining('La modification a été enregistrée'),
        findsOneWidget,
      );
      await tester.tap(find.text('Enregistrer'));
      await tester.pumpAndSettle();
      expect(editor.renameAttempts, 2);
      await tester.tap(find.text('Fermer'));
      await tester.pumpAndSettle();
      expect(port.libraryReads, 2);
    },
  );

  testWidgets('modifying, copying and confirming a withdrawal update one row', (
    tester,
  ) async {
    final port = _LibraryPort();
    final (_, editor) = await _open(tester, port);
    await tester.tap(find.byKey(const ValueKey('library-item-element:tree')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Modifier'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('library-edit-description')),
      'Un arbre pour le jardin.',
    );
    await tester.pump();
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();
    expect(find.text('Un arbre pour le jardin.'), findsOneWidget);

    await _chooseAction(tester, 'Dupliquer');
    expect(find.text('Arbre — copie'), findsOneWidget);
    await tester.tap(find.text('Créer la copie'));
    await tester.pumpAndSettle();
    final detail = find.byKey(
      const ValueKey('library-detail-element:tree-copy'),
    );
    expect(detail, findsOneWidget);
    final confirm = find.text('Supprimer la fiche');
    editor.used = true;
    await _chooseAction(tester, 'Supprimer…');
    expect(find.text('Cette ressource est encore utilisée.'), findsOneWidget);
    await tester.tap(confirm);
    await tester.pump();
    expect(editor.deletions, 0);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(detail, findsOneWidget);

    editor.used = false;
    await _chooseAction(tester, 'Supprimer…');
    expect(find.text('Aucun usage relevé'), findsOneWidget);
    await tester.tap(find.text('Annuler'));
    await tester.pumpAndSettle();
    expect(editor.released, 1);
    expect(editor.deletions, 0);
    await _chooseAction(tester, 'Supprimer…');
    await tester.tap(confirm);
    await tester.pumpAndSettle();
    expect(detail, findsNothing);
    expect(
      find.byKey(const ValueKey('library-item-element:tree-copy')),
      findsNothing,
    );
    expect(editor.deletions, 1);
    expect(editor.revisions, ['library-r0', 'library-r1', 'library-r2']);
    expect(port.libraryReads, 1);
  });
}

Future<void> _chooseAction(WidgetTester tester, String label) async {
  await tester.tap(find.byTooltip('Autres actions'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}
