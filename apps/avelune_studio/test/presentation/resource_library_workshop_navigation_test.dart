import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_items.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view.dart';
import 'package:avelune_studio/presentation/features/resources/library/resource_library_view_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'returning from a workshop restores the selected result and scroll',
    (tester) async {
      String? opened;
      await _library(tester, const Size(1200, 900), (id) => opened = id);
      final field = find.descendant(
        of: find.byKey(const ValueKey('library-search')),
        matching: find.byType(TextField),
      );
      await tester.enterText(field, 'Arbre');
      await tester.pumpAndSettle();
      final scroll = tester
          .widget<CustomScrollView>(
            find.byKey(const PageStorageKey('resource-library-results')),
          )
          .controller!;
      scroll.jumpTo(630);
      await tester.pumpAndSettle();
      final tile = find.byType(ResourceLibraryTile).hitTestable().first;
      final id = tester.widget<ResourceLibraryTile>(tile).item.id;
      await tester.tap(tile);
      await tester.pumpAndSettle();
      final before = scroll.offset;
      await tester.tap(find.text('Atelier 3D'));
      await tester.pumpAndSettle();
      expect(opened, id);
      expect(find.text('Réglages du modèle'), findsOneWidget);
      await tester.tap(find.text('Retour à la bibliothèque'));
      await tester.pumpAndSettle();
      expect(find.byKey(ValueKey('library-detail-$id')), findsOneWidget);
      expect(scroll.offset, closeTo(before, 1));
      scroll.jumpTo(0);
      await tester.pumpAndSettle();
      expect(tester.widget<TextField>(field).controller!.text, 'Arbre');
    },
  );

  testWidgets('the compact inspector closes when opening a workshop', (
    tester,
  ) async {
    String? opened;
    await _library(tester, const Size(850, 900), (id) => opened = id);
    await tester.tap(find.byKey(const ValueKey('library-item-model3d:0')));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsOneWidget);
    await tester.tap(find.text('Atelier 3D'));
    await tester.pumpAndSettle();
    expect(find.byType(BottomSheet), findsNothing);
    expect(opened, 'model3d:0');
    expect(find.text('Réglages du modèle'), findsOneWidget);
  });

  testWidgets(
    'classification selection survives list and grid and has exact ids',
    (tester) async {
      final classified = <Set<String>>[];
      await _library(
        tester,
        const Size(1200, 900),
        (_) {},
        onClassifySelection: (_, ids) async => classified.add(ids),
      );
      await tester.tap(find.text('Sélectionner'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('library-item-model3d:0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Vue en liste'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('library-item-model3d:1')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Classer la sélection'));
      await tester.pumpAndSettle();
      expect(classified, [
        {'model3d:0', 'model3d:1'},
      ]);
      expect(find.text('2 ressources sélectionnées'), findsOneWidget);
    },
  );
}

Future<void> _library(
  WidgetTester tester,
  Size size,
  ValueChanged<String> open, {
  Future<void> Function(BuildContext, Set<String>)? onClassifySelection,
}) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = size;
  addTearDown(tester.view.resetDevicePixelRatio);
  addTearDown(tester.view.resetPhysicalSize);
  await tester.pumpWidget(
    MaterialApp(
      theme: studioTheme(),
      home: Scaffold(
        body: ResourceLibraryView(
          items: [
            for (var i = 0; i < 48; i++)
              ResourceLibraryItemView(
                id: 'model3d:$i',
                name: 'Arbre $i',
                category: ResourceLibraryCategory.vegetation,
                type: 'Modèle 3D',
                dimension: ResourceLibraryDimension.threeDimensional,
              ),
          ],
          maps: const {},
          showMapScopes: false,
          workshopAction: (item) => (
            label: 'Atelier 3D',
            icon: Icons.view_in_ar_outlined,
            open: () => open(item.id),
          ),
          buildWorkshops: (back, _) => Column(
            children: [
              const Text('Réglages du modèle'),
              StudioButton(label: 'Retour à la bibliothèque', onPressed: back),
            ],
          ),
          onClassifySelection: onClassifySelection,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
