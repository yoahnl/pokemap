import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_builder_harness.dart';

const _tree = ValueKey('map-resource-element:tree');

void main() {
  Future<MapBuilderHarness> openObjects(WidgetTester tester) async {
    final harness = await MapBuilderHarness.open(tester);
    await tester.tap(
      find.byKey(const ValueKey('map-resource-category-object')),
    );
    await harness.settle();
    return harness;
  }

  testWidgets('categories show only their resources', (tester) async {
    await MapBuilderHarness.open(tester);

    expect(find.byKey(_tree), findsNothing);
    expect(find.text('Aucune ressource ici'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('map-resource-category-object')),
    );
    await tester.pump();

    expect(find.byKey(_tree), findsOneWidget);
    expect(find.text('Objets · 1'), findsOneWidget);
  });

  testWidgets('search, scope and context filter the objects', (tester) async {
    final harness = await openObjects(tester);

    await tester.enterText(
      find.byKey(const ValueKey('map-resource-search')),
      'rocher',
    );
    await harness.settle();
    expect(find.byKey(_tree), findsNothing);

    await tester.enterText(
      find.byKey(const ValueKey('map-resource-search')),
      'arb',
    );
    await harness.settle();
    expect(find.byKey(_tree), findsOneWidget);
    expect(find.text('Réservées  0'), findsOneWidget);
    expect(find.text('Communes  1'), findsOneWidget);

    await tester.tap(find.text('Réservées  0'));
    await harness.settle();
    expect(find.byKey(_tree), findsNothing);

    await tester.tap(find.text('Communes  1'));
    await harness.settle();
    await tester.tap(find.text('Intérieur'));
    await harness.settle();
    expect(find.byKey(_tree), findsOneWidget);
  });

  testWidgets('choosing an object arms placement and builds on the map', (
    tester,
  ) async {
    final harness = await openObjects(tester);
    final document = harness.controller.active!;
    final before = document.current.placedElements.length;

    await tester.tap(find.byKey(_tree));
    await harness.settle();

    expect(
      find.byKey(const ValueKey('map-inspector-active-tool')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('map-inspector-active-tool')),
        matching: find.text('Arbre'),
      ),
      findsOneWidget,
    );

    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('map-canvas'))),
    );
    await harness.settle();
    expect(harness.controller.active!.current.placedElements.length, before + 1);

    await tester.tap(find.byKey(const ValueKey('map-inspector-release')));
    await harness.settle();
    expect(
      find.byKey(const ValueKey('map-inspector-active-tool')),
      findsNothing,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('map-status-tool'))).data,
      'Sélection',
    );
  });

  testWidgets('zoom and grid controls act on the 2D view', (tester) async {
    await MapBuilderHarness.open(tester);
    String zoom() => tester
        .widget<Text>(find.byKey(const ValueKey('map-status-zoom')))
        .data!;
    final initial = zoom();

    await tester.tap(find.byKey(const ValueKey('map-status-zoom-in')));
    await tester.pump();
    expect(zoom(), isNot(initial));

    final grid = find.byKey(const ValueKey('map-status-grid'));
    expect(tester.widget<IconButton>(grid).isSelected, isFalse);
    await tester.tap(grid);
    await tester.pump();
    expect(tester.widget<IconButton>(grid).isSelected, isTrue);
  });
}
