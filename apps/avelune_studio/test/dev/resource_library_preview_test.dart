import 'package:avelune_studio/presentation/features/resources/library/resource_library_items.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../dev/resource_library_preview.dart';

void main() {
  Future<void> open(
    WidgetTester tester, {
    Size size = const Size(1440, 940),
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ResourceLibraryPreviewApp());
    await tester.pumpAndSettle();
  }

  testWidgets('scope shows shared, exclusive and unplaced demo resources', (
    tester,
  ) async {
    await open(tester);
    final oak = find.byKey(const ValueKey('library-item-oak'));
    final mill = find.byKey(const ValueKey('library-item-mill'));
    expect(oak, findsOneWidget);
    expect(mill, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-scope-used')));
    await tester.pumpAndSettle();
    expect(oak, findsOneWidget);
    expect(mill, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-scope-exclusive')));
    await tester.pumpAndSettle();
    expect(oak, findsNothing);
    expect(mill, findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('library-scope-project')));
    await tester.pumpAndSettle();
    expect(oak, findsOneWidget);
  });

  testWidgets('search supports keyboard focus, an empty view and clearing', (
    tester,
  ) async {
    await open(tester);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyK);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await tester.pump();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).focusNode.hasFocus,
      isTrue,
    );
    await tester.enterText(find.byType(TextField), 'chene');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-item-oak')), findsOneWidget);
    expect(find.byKey(const ValueKey('library-item-mill')), findsNothing);
    await tester.enterText(find.byType(TextField), 'introuvable');
    await tester.pumpAndSettle();
    expect(find.text('Aucune ressource trouvée'), findsOneWidget);
    await tester.tap(find.byTooltip('Effacer la recherche'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-item-mill')), findsOneWidget);
  });

  testWidgets('source and atelier navigation keep the library usable', (
    tester,
  ) async {
    await open(tester);
    final source = find.byKey(const ValueKey('library-source-mill-source'));
    await tester.ensureVisible(source);
    await tester.tap(source);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('library-detail-mill-source')),
      findsOneWidget,
    );

    final consumer = find.byKey(const ValueKey('library-source-mill'));
    await tester.ensureVisible(consumer);
    await tester.tap(consumer);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-detail-mill')), findsOneWidget);

    await tester.tap(find.text('Créer'));
    await tester.pumpAndSettle();
    expect(find.text('Ateliers de création'), findsOneWidget);
    await tester.tap(find.text('Bibliothèque'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-detail-mill')), findsOneWidget);
  });

  testWidgets('a narrow window can open resource details', (tester) async {
    await open(tester, size: const Size(520, 750));
    expect(find.byKey(const ValueKey('library-detail-mill')), findsNothing);
    final mill = find.byKey(const ValueKey('library-item-mill'));
    final resultsScroll = find.descendant(
      of: find.byKey(const PageStorageKey('resource-library-results')),
      matching: find.byType(Scrollable),
    );
    await tester.scrollUntilVisible(mill, 170, scrollable: resultsScroll.first);
    await Scrollable.ensureVisible(tester.element(mill), alignment: .5);
    await tester.pumpAndSettle();
    await tester.tap(mill);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-detail-mill')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('reference map and list view update the demo results', (
    tester,
  ) async {
    await open(tester);
    await tester.tap(find.byKey(const ValueKey('library-scope-used')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Clairière d’Aube').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sentier des Pins').last);
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('library-item-mill')), findsNothing);

    await tester.tap(find.byTooltip('Vue en liste'));
    await tester.pumpAndSettle();
    final oak = tester.widget<ResourceLibraryTile>(
      find.byKey(const ValueKey('library-item-oak')),
    );
    expect(oak.grid, isFalse);
  });
}
