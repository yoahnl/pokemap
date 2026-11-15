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

void main() {
  testWidgets(
    '⌘Z of a paste drops the pasted elements from the selection, ⌘⇧Z keeps it consistent',
    (tester) async {
      final host = await openSelectionHost(tester);
      await host.click('oak_1');
      await host.click('oak_2', shift: true);
      await _command(tester, LogicalKeyboardKey.keyC);
      await _command(tester, LogicalKeyboardKey.keyV);
      await host.settle();
      final pasted = host.instances
          .map((item) => item.id)
          .where((id) => !const {'oak_1', 'oak_2', 'mill'}.contains(id))
          .toList();
      expect(pasted, hasLength(2));
      expect(find.text('2 éléments sélectionnés'), findsOneWidget);

      await _command(tester, LogicalKeyboardKey.keyZ);
      await host.settle();

      expect(
        host.instances.map((item) => item.id),
        isNot(contains(pasted.first)),
      );
      expect(find.text('2 éléments sélectionnés'), findsNothing);
      expect(find.byKey(const ValueKey('selection-inspector')), findsNothing);

      await _command(tester, LogicalKeyboardKey.keyZ, shift: true);
      await host.settle();
      expect(host.instances.map((item) => item.id), contains(pasted.first));
      expect(find.text('2 éléments sélectionnés'), findsNothing);
    },
  );
}
