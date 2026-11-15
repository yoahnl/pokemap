import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';

import 'map_builder_selection_harness.dart';

SpatialModelInstance _instance(SelectionHost host, String id) =>
    host.instances.firstWhere((item) => item.id == id);

Future<void> _enter(WidgetTester tester, String key, String text) async {
  final field = find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );
  await tester.enterText(field, text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  testWidgets(
    'Propriétés edits the position, height, turn and size of a 3D decor',
    (tester) async {
      final host = await openSelectionHost(tester);
      expect(find.byKey(const ValueKey('selection-inspector')), findsNothing);
      await host.click('mill');
      expect(find.byKey(const ValueKey('selection-inspector')), findsOneWidget);
      expect(find.text('Moulin animé'), findsOneWidget);
      await _enter(tester, 'selection-x', '6,5');
      await _enter(tester, 'selection-y', '3.5');
      await _enter(tester, 'selection-z', '1.25');
      await _enter(tester, 'selection-rotation', '45');
      await _enter(tester, 'selection-scale', '2');
      final mill = _instance(host, 'mill');
      expect(mill.position.x, 6.5);
      expect(mill.position.z, 3.5);
      expect(mill.rotationDegrees, 45);
      expect(mill.scale, 2);
      final ground = host.maps.active!.current.spatialScene!.worldHeightAt(
        6.5,
        3.5,
      );
      expect(mill.position.y, closeTo(ground + 1.25, 1e-9));
      expect(host.maps.active!.undoCount, 5);
      await _enter(tester, 'selection-scale', 'abc');
      expect(_instance(host, 'mill').scale, 2);
      expect(host.maps.active!.undoCount, 5);
      host.maps.active!.restore(redo: false);
      await host.settle();
      expect(_instance(host, 'mill').scale, 1);
    },
  );

  testWidgets('the animation switch exists only for an animated model', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    expect(find.byKey(const ValueKey('selection-animations')), findsNothing);
    await host.click('mill');
    await tester.tap(find.byKey(const ValueKey('selection-animations')));
    await host.settle();
    expect(_instance(host, 'mill').animationIndex, 0);
    await tester.tap(find.byKey(const ValueKey('selection-animations')));
    await host.settle();
    expect(_instance(host, 'mill').animationIndex, isNull);
    expect(host.maps.active!.undoCount, 2);
  });

  testWidgets('a multiple selection shows its size instead of fields', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    await host.click('oak_2', shift: true);
    expect(find.byKey(const ValueKey('selection-count')), findsOneWidget);
    expect(find.text('2 éléments sélectionnés'), findsOneWidget);
    expect(find.byKey(const ValueKey('selection-x')), findsNothing);
  });

  testWidgets('Enter commits a Propriétés field, releases it and ⌘Z undoes', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('mill');
    await _enter(tester, 'selection-x', '6');
    expect(_instance(host, 'mill').position.x, 6);
    final focused = FocusManager.instance.primaryFocus?.context;
    expect(
      focused?.widget is EditableText ||
          focused?.findAncestorWidgetOfExactType<EditableText>() != null,
      isFalse,
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
    await host.settle();
    expect(_instance(host, 'mill').position.x, 8.5);
  });

  testWidgets('switching map leaves the other map selection behind', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    await host.click('oak_2', shift: true);
    expect(find.text('2 éléments sélectionnés'), findsOneWidget);
    await tester.runAsync(
      () => host.maps.activate(
        host.maps.project!.maps.firstWhere((entry) => entry.id == 'b'),
      ),
    );
    await host.settle();
    expect(host.maps.active!.base.mapId, 'b');
    expect(find.byKey(const ValueKey('selection-count')), findsNothing);
    expect(find.byKey(const ValueKey('selection-inspector')), findsNothing);
  });
}
