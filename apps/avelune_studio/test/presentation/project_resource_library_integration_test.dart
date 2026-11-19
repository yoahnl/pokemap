import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_selection_harness.dart';

void main() {
  Finder keyed(String value) => find.byKey(ValueKey(value));

  testWidgets('Studio surfaces catalogue names, families and technical roles', (
    tester,
  ) async {
    final project = selectionProject().copyWith(
      maps: [],
      tilesets: [
        ProjectTilesetEntry(
          id: 'wheel',
          name: 'Roue',
          relativePath: 'assets/roue.png',
        ),
      ],
      resourceLibraryCatalog: ResourceLibraryCatalog(
        families: [
          ResourceFamily(
            id: 'wheel-family',
            name: 'Roues',
            parentId: 'workshop',
          ),
          ResourceFamily(id: 'workshop', name: 'Atelier'),
        ],
        entries: [
          ResourceLibraryEntry(
            resourceKind: 'model3d',
            resourceId: 'windmill',
            familyId: 'workshop',
          ),
          ResourceLibraryEntry(
            resourceKind: 'tileset',
            resourceId: 'wheel',
            familyId: 'wheel-family',
            role: ResourceLibraryRole.component,
            description: 'Pièce détachée',
          ),
        ],
      ),
    );
    final host = await openSelectionHost(tester, manifest: project);
    Future<void> tap(String key) async {
      await tester.tap(keyed(key));
      await host.settle();
    }

    expect(keyed('library-search'), findsNothing);
    await tap('studio-rail-resources');
    expect(keyed('library-item-model3d:windmill'), findsOneWidget);
    expect(keyed('library-item-tileset:wheel'), findsNothing);
    expect(find.text('Pas encore utilisée'), findsNothing);

    await tap('library-role-component');
    expect(keyed('library-item-tileset:wheel'), findsOneWidget);
    expect(keyed('library-item-model3d:windmill'), findsNothing);
    final search = find.descendant(
      of: keyed('library-search'),
      matching: find.byType(TextField),
    );
    await tester.enterText(search, 'piece detachee');
    await host.settle();
    await tap('library-item-tileset:wheel');
    expect(find.text('Atelier › Roues'), findsWidgets);
    expect(find.text('Pièce détachée'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('returning from Resources retains the open map and its draft', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    final active = host.maps.active!;
    active.commit(active.current.copyWith(name: 'Carte en cours'));

    await tester.tap(keyed('studio-rail-resources'));
    await host.settle();
    expect(keyed('library-search'), findsOneWidget);
    await tester.tap(keyed('studio-rail-map'));
    await host.settle();

    expect(host.maps.active, same(active));
    expect(active.current.name, 'Carte en cours');
    expect(active.dirty, isTrue);
  });

  testWidgets('a resource detail fits within a narrow Studio window', (
    tester,
  ) async {
    final project = selectionProject().copyWith(
      tilesets: [
        ProjectTilesetEntry(
          id: 'paving',
          name: 'Pavés',
          relativePath: 'assets/paving.png',
        ),
      ],
    );
    final host = await openSelectionHost(tester, manifest: project);
    const window = Size(1000, 720);
    tester.view.physicalSize = window;
    await host.settle();

    await tester.tap(keyed('studio-rail-resources'));
    await host.settle();
    await tester.enterText(
      find.descendant(
        of: keyed('library-search'),
        matching: find.byType(TextField),
      ),
      'Pavés',
    );
    await host.settle();
    await tester.tap(keyed('library-item-tileset:paving'));
    await host.settle();

    final detail = tester.getRect(keyed('library-detail-tileset:paving'));
    expect(detail.right, lessThanOrEqualTo(window.width));
    expect(tester.takeException(), isNull);
  });
}
