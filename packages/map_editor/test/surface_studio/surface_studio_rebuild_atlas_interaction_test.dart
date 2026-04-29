import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'surface_studio_rebuild_test_harness.dart';

void main() {
  testWidgets('atlas panel exposes zoom slider and column selection microcopy',
      (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.atlas.zoomSlider')),
        findsOneWidget);
    expect(find.text('100%'), findsOneWidget);

    await tester.drag(
      find.byKey(const Key('surfaceStudio.atlas.zoomSlider')),
      const Offset(120, 0),
    );
    await tester.pump();
    expect(find.text('100%'), findsNothing);

    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.4')));
    await tester.pump();
    expect(
      find.text('Colonne 4 sélectionnée — glissez vers un rôle du schéma.'),
      findsOneWidget,
    );

    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.5')));
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.pump();
    expect(
      find.text('Colonnes 4–5 sélectionnées — glissez vers un rôle du schéma.'),
      findsOneWidget,
    );
  });

  testWidgets('atlas selection is draggable with a visible ghost payload', (
    tester,
  ) async {
    await pumpSurfaceStudioForTest(tester);
    await tester.pump();

    await tester.tap(find.byKey(const Key('surfaceStudio.atlas.column.4')));
    await tester.pump();

    expect(find.byKey(const Key('surfaceStudio.atlas.dragHandle')),
        findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const Key('surfaceStudio.atlas.dragHandle'))),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.moveBy(const Offset(40, 0));
    await tester.pump();

    expect(
        find.byKey(const Key('surfaceStudio.atlas.dragGhost')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
