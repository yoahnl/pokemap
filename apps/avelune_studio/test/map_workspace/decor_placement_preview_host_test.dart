import 'package:avelune_studio/platform/rendering/viewports/map_editing_viewport_2d.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:avelune_studio/features/map_workspace/coordination/map_editing_viewport_session.dart';

import '../support/neutral_map_host_fixture.dart';

void main() {
  testWidgets('the selected decor follows the mouse without editing the map', (
    tester,
  ) async {
    final fixture = await NeutralMapHostFixture.open(tester);
    final before = fixture.document.current;
    final undo = fixture.document.undoCount;
    fixture.nativeView
      ..brush = fixture.maps.project!.elements.singleWhere(
        (e) => e.id == 'arbre',
      )
      ..tool = StudioMapTool.place;
    fixture.maps.notify();
    await fixture.pump();

    final mouse = TestPointer(25, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(fixture.cellAt(8, 7)));
    await tester.pump();
    final preview = find.byKey(const ValueKey('decor-placement-preview'));
    expect(preview, findsOneWidget);
    expect(tester.widget<Opacity>(preview).opacity, lessThan(1));
    final canvas = tester.getRect(find.byKey(const ValueKey('map-canvas')));
    final first = tester.getRect(preview);
    final size = fixture.document.current.size;
    final brush = tester
        .widget<MapEditingViewport2D>(find.byType(MapEditingViewport2D))
        .view
        .brush!;
    expect(first.left, closeTo(canvas.left + 8 * canvas.width / size.width, 1));
    expect(first.top, closeTo(canvas.top + 7 * canvas.height / size.height, 1));
    expect(
      first.width,
      closeTo(brush.frames.first.source.width * canvas.width / size.width, 1),
    );
    expect(
      first.height,
      closeTo(
        brush.frames.first.source.height * canvas.height / size.height,
        1,
      ),
    );

    await tester.sendEventToBinding(mouse.hover(fixture.cellAt(10, 9)));
    await tester.pump();
    final second = tester.getRect(preview);
    expect(second.left, greaterThan(first.left));
    expect(second.top, greaterThan(first.top));
    expect(fixture.document.current, before);
    expect(fixture.document.undoCount, undo);

    await fixture.tapCell(10, 9);
    expect(preview, findsNothing);
    expect(
      fixture.document.current.placedElements.length,
      before.placedElements.length + 1,
    );

    fixture.nativeView.tool = StudioMapTool.select;
    fixture.maps.notify();
    await fixture.pump();
    expect(preview, findsNothing);
  });

  testWidgets('the preview clears when the pointer leaves the map', (
    tester,
  ) async {
    final fixture = await NeutralMapHostFixture.open(tester);
    fixture.nativeView
      ..brush = fixture.maps.project!.elements.singleWhere(
        (e) => e.id == 'arbre',
      )
      ..tool = StudioMapTool.place;
    fixture.maps.notify();
    await fixture.pump();
    final mouse = TestPointer(26, PointerDeviceKind.mouse);
    await tester.sendEventToBinding(mouse.hover(fixture.cellAt(8, 7)));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('decor-placement-preview')),
      findsOneWidget,
    );

    await tester.sendEventToBinding(mouse.hover(const Offset(1, 1)));
    await tester.pump();
    expect(find.byKey(const ValueKey('decor-placement-preview')), findsNothing);
  });
}
