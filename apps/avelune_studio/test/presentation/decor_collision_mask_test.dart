import 'package:avelune_studio/presentation/features/resources/decor_collision_mask.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  testWidgets('six cells remain visible and compact; last cell can toggle', (
    tester,
  ) async {
    final selected = <GridPos>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 280,
              child: DecorCollisionMask(
                width: 2,
                height: 3,
                blocked: {const GridPos(x: 0, y: 0)},
                onToggle: selected.add,
              ),
            ),
          ),
        ),
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('collision-0-0')));
    final last = tester.getRect(find.byKey(const ValueKey('collision-1-2')));
    expect(first.width, lessThanOrEqualTo(36));
    expect(last.bottom - first.top, lessThanOrEqualTo(200));
    expect(find.byType(InkWell), findsNWidgets(6));
    await tester.tap(find.byKey(const ValueKey('collision-1-2')));
    expect(selected, [const GridPos(x: 1, y: 2)]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('narrow tall mask fits every row within 200 pixels', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Align(
            alignment: Alignment.topLeft,
            child: SizedBox(
              width: 90,
              child: DecorCollisionMask(
                width: 8,
                height: 20,
                blocked: {},
                onToggle: (_) {},
              ),
            ),
          ),
        ),
      ),
    );
    final first = tester.getRect(find.byKey(const ValueKey('collision-0-0')));
    final last = tester.getRect(find.byKey(const ValueKey('collision-7-19')));
    expect(last.bottom - first.top, lessThanOrEqualTo(200.001));
    expect(last.right - first.left, lessThanOrEqualTo(90.001));
    expect(find.byType(InkWell), findsNWidgets(160));
    expect(tester.takeException(), isNull);
  });
}
