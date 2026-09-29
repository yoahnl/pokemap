import 'package:avelune_studio/presentation/features/map_workspace/map_workspace_canvas.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/map_host_fixture.dart';

void main() {
  testWidgets('the selected decor follows the mouse without editing the map', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(tester);
    final before = fixture.document.current;
    final undo = fixture.document.undoCount;
    await tester.tap(find.byKey(const ValueKey('decor-arbre')));
    await tester.pump();

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
        .widget<MapWorkspaceCanvas>(find.byType(MapWorkspaceCanvas))
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

    await tester.tap(find.byKey(const ValueKey('Sélectionner')));
    await tester.pump();
    expect(preview, findsNothing);
  });

  testWidgets('the preview clears when the pointer leaves the map', (
    tester,
  ) async {
    final fixture = await MapHostFixture.open(tester);
    await tester.tap(find.byKey(const ValueKey('decor-arbre')));
    await tester.pump();
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
