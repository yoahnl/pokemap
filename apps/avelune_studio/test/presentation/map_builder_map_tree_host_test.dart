import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_map_library_harness.dart';
import 'map_builder_selection_harness.dart';

Finder _map(String id) => find.byKey(ValueKey('map-library-map-$id'));

EditableText _renameField(WidgetTester tester) => tester.widget(
  find.descendant(
    of: find.byKey(const ValueKey('map-library-rename-field')),
    matching: find.byType(EditableText),
  ),
);

Future<SelectionHost> _openTree(WidgetTester tester) async {
  final host = await openSelectionHost(
    tester,
    catalog: MemoryMapCatalogPort(selectionProject()),
  );
  await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
  await host.settle();
  return host;
}

Future<void> _doubleClick(WidgetTester tester, Finder row) async {
  await tester.tap(row);
  await tester.pump(const Duration(milliseconds: 60));
  await tester.tap(row);
}

void main() {
  testWidgets(
    'a double click on an already loaded map keeps the rename field focused',
    (tester) async {
      final host = await _openTree(tester);
      await tester.tap(_map('b'));
      await host.settle();
      await tester.tap(_map('a'));
      await host.settle();
      expect(host.maps.active!.base.mapId, 'a');

      await _doubleClick(tester, _map('b'));
      await host.settle();
      await tester.pump(const Duration(milliseconds: 500));
      await host.settle();

      expect(host.maps.active!.base.mapId, 'b');
      expect(_renameField(tester).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets(
    'a double click on a map still loading focuses the field once it opens',
    (tester) async {
      final host = await _openTree(tester);
      final gate = host.port.loadGate = Completer<void>();

      await _doubleClick(tester, _map('b'));
      await host.settle();
      gate.complete();
      await host.settle();
      await tester.pump(const Duration(milliseconds: 500));
      await host.settle();

      expect(host.maps.active!.base.mapId, 'b');
      expect(_renameField(tester).focusNode.hasFocus, isTrue);
    },
  );

  testWidgets('a library failure notice disappears when another map opens', (
    tester,
  ) async {
    final host = await _openTree(tester);
    await _doubleClick(tester, _map('a'));
    await host.settle();
    tester.testTextInput.updateEditingValue(const TextEditingValue(text: ' '));
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await host.settle();
    expect(find.byKey(const ValueKey('map-library-notice')), findsOneWidget);

    await tester.tap(_map('b'));
    await host.settle();

    expect(host.maps.active!.base.mapId, 'b');
    expect(find.byKey(const ValueKey('map-library-notice')), findsNothing);
  });
}
