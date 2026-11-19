import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_selection_harness.dart';

void main() {
  testWidgets(
    'the project library browses families and components without a map',
    (tester) async {
      final project = selectionProject().copyWith(
        maps: [],
        tilesets: [
          ProjectTilesetEntry(
            id: 'wheel-image',
            name: 'Roue',
            relativePath: 'assets/roue.png',
          ),
        ],
        resourceLibraryCatalog: ResourceLibraryCatalog(
          families: [
            ResourceFamily(id: 'workshop', name: 'Atelier'),
            ResourceFamily(id: 'wheels', name: 'Roues', parentId: 'workshop'),
          ],
          entries: [
            ResourceLibraryEntry(
              resourceKind: 'tileset',
              resourceId: 'wheel-image',
              familyId: 'wheels',
              role: ResourceLibraryRole.component,
              description: 'Pièce détachée',
            ),
            ResourceLibraryEntry(
              resourceKind: 'model3d',
              resourceId: 'windmill',
              familyId: 'workshop',
            ),
          ],
        ),
      );
      final host = await openSelectionHost(tester, manifest: project);
      Finder keyed(String key) => find.byKey(ValueKey(key));
      Future<void> tap(String key) async {
        await tester.tap(keyed(key));
        await host.settle();
      }

      await tap('studio-rail-resources');
      final unclassified = keyed(
        'library-item-model3d:${project.models3d.first.id}',
      );
      expect(unclassified, findsOneWidget);
      await tester.tap(find.text('Toutes les familles').first);
      await host.settle();
      await tester.tap(find.text('Atelier').last);
      await host.settle();
      expect(unclassified, findsNothing);
      expect(keyed('library-item-model3d:windmill'), findsOneWidget);
      expect(keyed('library-item-tileset:wheel-image'), findsNothing);
      await tap('library-role-component');
      expect(keyed('library-item-model3d:windmill'), findsNothing);
      expect(keyed('library-item-tileset:wheel-image'), findsOneWidget);
      final search = find.descendant(
        of: keyed('library-search'),
        matching: find.byType(TextField),
      );
      await tester.enterText(search, 'piece detachee');
      await host.settle();
      await tap('library-item-tileset:wheel-image');
      expect(find.text('Pièce détachée'), findsOneWidget);
      await tester.enterText(search, 'introuvable');
      await host.settle();
      expect(keyed('library-item-tileset:wheel-image'), findsNothing);
      expect(find.text('Aucune ressource trouvée'), findsOneWidget);
      await tap('studio-rail-map');
      expect(keyed('library-search'), findsNothing);
      expect(host.maps.active, isNull);
    },
  );

  testWidgets('returning from the library keeps the open map and its draft', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    final map = host.maps.active!;
    map.commit(map.current.copyWith(name: 'Carte en cours'));
    await tester.tap(find.byKey(const ValueKey('studio-rail-resources')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('studio-rail-map')));
    await host.settle();
    expect(host.maps.active, same(map));
    expect(map.current.name, 'Carte en cours');
    expect(map.dirty, isTrue);
  });

  testWidgets('a model remains readable when its 3D preview is unavailable', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await tester.tap(find.byKey(const ValueKey('studio-rail-resources')));
    await host.settle();
    await tester.tap(
      find.byKey(const ValueKey('library-item-model3d:windmill')),
    );
    await host.settle();
    expect(tester.takeException(), isNull);
    expect(find.text('Moulin animé'), findsNWidgets(2));
  });
}
