import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('resize handle exposes its affordance and reports drag deltas',
      (tester) async {
    var totalDelta = 0.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              height: 240,
              child: PokeMapHorizontalResizeHandle(
                key: const ValueKey<String>('resize-handle'),
                tooltip: 'Redimensionner le panneau droit',
                onDrag: (delta) => totalDelta += delta,
              ),
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(const ValueKey<String>('resize-handle'));
    expect(handle, findsOneWidget);
    expect(
      tester
          .widgetList<MouseRegion>(
            find.descendant(of: handle, matching: find.byType(MouseRegion)),
          )
          .any((region) => region.cursor == SystemMouseCursors.resizeColumn),
      isTrue,
    );
    expect(
      tester
          .widget<Tooltip>(
            find.descendant(of: handle, matching: find.byType(Tooltip)),
          )
          .message,
      'Redimensionner le panneau droit',
    );

    await tester.drag(
      handle,
      const Offset(48, 0),
      touchSlopX: 0,
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();

    expect(totalDelta, closeTo(48, 0.001));
    expect(tester.takeException(), isNull);
  });
}
