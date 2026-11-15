import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_selection_harness.dart';

Future<void> _command(
  WidgetTester tester,
  LogicalKeyboardKey key, {
  bool shift = false,
}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyEvent(key);
  if (shift) await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
}

Iterable<String> _ids(SelectionHost host) =>
    host.instances.map((item) => item.id);

Future<void> _deleteOak(WidgetTester tester, SelectionHost host) async {
  await host.click('oak_1');
  await tester.sendKeyEvent(LogicalKeyboardKey.delete);
  await host.settle();
  expect(_ids(host), isNot(contains('oak_1')));
}

Future<void> _clickPanelBackground(
  WidgetTester tester,
  SelectionHost host,
) async {
  final panel = find.byKey(const ValueKey('map-space-panel'));
  await tester.tapAt(tester.getTopLeft(panel) + const Offset(200, 24));
  await host.settle();
}

void main() {
  final macOS = TargetPlatformVariant.only(TargetPlatform.macOS);

  testWidgets(
    'in the Jeu space ⌘Z and ⌘⇧Z work after leaving a side panel field',
    (tester) async {
      final host = await openSelectionHost(tester);
      await _deleteOak(tester, host);
      await tester.tap(find.byKey(const ValueKey('map-space-gameplay')));
      await host.settle();
      await tester.tap(find.byKey(const ValueKey('map-gameplay-search')));
      await host.settle();
      await _clickPanelBackground(tester, host);
      final focused = FocusManager.instance.primaryFocus?.context?.widget;
      expect(focused, isNot(isA<EditableText>()));

      await _command(tester, LogicalKeyboardKey.keyZ);
      await host.settle();
      expect(_ids(host), contains('oak_1'));

      await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
      await host.settle();
      expect(_ids(host), isNot(contains('oak_1')));
    },
    variant: macOS,
  );

  testWidgets('a side panel field being edited keeps ⌘Z for its own text', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await _deleteOak(tester, host);
    await tester.tap(find.byKey(const ValueKey('map-space-gameplay')));
    await host.settle();
    await tester.tap(find.byKey(const ValueKey('map-gameplay-search')));
    await host.settle();

    await _command(tester, LogicalKeyboardKey.keyZ);
    await host.settle();

    expect(_ids(host), isNot(contains('oak_1')));
  }, variant: macOS);

  testWidgets(
    'leaving the Cartes tree for the Jeu space keeps ⌘Z at the page',
    (tester) async {
      final host = await openSelectionHost(tester);
      await _deleteOak(tester, host);
      await tester.tap(find.byKey(const ValueKey('map-library-tab-Cartes')));
      await host.settle();
      await tester.tap(find.byKey(const ValueKey('map-library-search')));
      await host.settle();
      await tester.tap(find.byKey(const ValueKey('map-space-gameplay')));
      await host.settle();

      await _command(tester, LogicalKeyboardKey.keyZ);
      await host.settle();

      expect(_ids(host), contains('oak_1'));
    },
    variant: macOS,
  );
}
