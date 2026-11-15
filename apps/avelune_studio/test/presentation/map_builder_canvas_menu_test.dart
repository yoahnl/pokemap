import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'map_builder_selection_harness.dart';

List<String> _menuLabels(WidgetTester tester) => [
  for (final entry
      in tester
          .widgetList<StudioContextMenuPanel>(
            find.byType(StudioContextMenuPanel),
          )
          .single
          .items
          .whereType<StudioContextMenuEntry>())
    entry.label,
];

StudioContextMenuEntry _entry(WidgetTester tester, String label) => tester
    .widget<StudioContextMenuPanel>(find.byType(StudioContextMenuPanel))
    .items
    .whereType<StudioContextMenuEntry>()
    .firstWhere((entry) => entry.label == label);

void main() {
  testWidgets('right-click on a selection offers the editing actions first', (
    tester,
  ) async {
    final host = await openSelectionHost(tester);
    await host.click('oak_1');
    await host.click('oak_2', shift: true);
    await host.rightClick(2, 2);
    expect(_menuLabels(tester), [
      'Couper',
      'Copier',
      'Coller',
      'Dupliquer',
      'Supprimer',
      'Rotation 90°',
      'Propriétés',
    ]);
    expect(_entry(tester, 'Coller').enabled, isFalse);
    expect(_entry(tester, 'Rotation 90°').enabled, isTrue);
    await tester.tap(find.text('Dupliquer'));
    await host.settle();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.byType(StudioContextMenuPanel), findsNothing);
    expect(host.instances.where((item) => item.modelId == 'oak'), hasLength(4));
    expect(host.maps.active!.undoCount, 1);
    final view = host.maps.active!.current.id;
    expect(host.maps.clipboard, isNull);
    expect(view, 'a');
  });

  testWidgets(
    'right-click on empty ground pastes there and the canvas stays live',
    (tester) async {
      final host = await openSelectionHost(tester);
      await host.click('mill');
      await host.rightClick(8, 2);
      await tester.tap(find.text('Copier'));
      await host.settle();
      expect(host.maps.clipboard?.items, hasLength(1));
      await host.rightClick(1, 8);
      expect(_menuLabels(tester), ['Coller']);
      await tester.tap(find.text('Coller'));
      await host.settle();
      final pasted = host.instances.where(
        (item) => item.modelId == 'windmill' && item.id != 'mill',
      );
      expect(pasted.single.position.x, 1.5);
      expect(pasted.single.position.z, 8.5);
      final ignoring = tester.widgetList<IgnorePointer>(
        find.ancestor(
          of: find.byType(host.scene.runtimeType),
          matching: find.byType(IgnorePointer),
        ),
      );
      expect(ignoring.any((widget) => widget.ignoring), isFalse);
    },
  );
}
