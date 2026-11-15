import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_editing_viewport_fixture.dart';

void main() {
  testWidgets('shift-click adds markers and story zones to a decor selection', (
    tester,
  ) async {
    final f = await MapEditingViewportFixture.open(tester);
    final mapId = f.document.current.id;
    final steps = f.document.undoCount;
    await f.tapCell(11, 5);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await f.tapCell(8, 9);
    await f.tapCell(11, 9);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(
      f.view.selectionIn(mapId).map((target) => (target.family, target.id)),
      [
        (MapSelectionFamily.decor, '$mapId-rocher'),
        (MapSelectionFamily.marker, 'depart'),
        (MapSelectionFamily.trigger, 'quai'),
      ],
    );
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await f.tapCell(8, 9);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    expect(f.view.selectionIn(mapId).map((target) => target.id), [
      '$mapId-rocher',
      'quai',
    ]);
    expect(f.document.undoCount, steps);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('a zoomed-out press that jitters a few pixels keeps the decor', (
    tester,
  ) async {
    final f = await MapEditingViewportFixture.open(tester);
    final mapId = f.document.current.id;
    f.view.transform.value = f.view.transform.value.clone()
      ..scaleByDouble(.15, .15, 1, 1);
    await tester.pump();
    final before = f.document.current;
    final steps = f.document.undoCount;
    final gesture = await tester.startGesture(f.cellAt(11, 5));
    await tester.pump();
    await gesture.moveBy(const Offset(1.5, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(1.5, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    expect(f.view.selectionIn(mapId).single.id, '$mapId-rocher');
    expect(f.document.current.placedElements, before.placedElements);
    expect(f.document.undoCount, steps);
  }, timeout: const Timeout(Duration(minutes: 3)));
}
