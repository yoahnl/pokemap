import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _app(Widget child) => MaterialApp(
  theme: studioTheme(),
  home: Scaffold(body: child),
);

void main() {
  testWidgets('a tab bar selects a tab by tap and by keyboard', (tester) async {
    final chosen = <String>[];
    var selected = 'memory';
    late StateSetter rebuild;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return StudioTabBar<String>(
              tabs: const [
                StudioTab(value: 'plot', label: 'Trame'),
                StudioTab(value: 'memory', label: 'Mémoire du jeu'),
              ],
              selected: selected,
              onSelected: (value) {
                chosen.add(value);
                rebuild(() => selected = value);
              },
            );
          },
        ),
      ),
    );

    expect(
      tester.getSemantics(find.bySemanticsLabel('Mémoire du jeu')),
      matchesSemantics(
        label: 'Mémoire du jeu',
        isButton: true,
        isSelected: true,
        hasSelectedState: true,
        hasTapAction: true,
        hasFocusAction: true,
        isFocusable: true,
      ),
    );
    await tester.tap(find.text('Trame'));
    await tester.pump();
    expect(chosen, ['plot']);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(chosen.last, 'memory');
  });

  testWidgets('a filter chip reports its toggled state and can be disabled', (
    tester,
  ) async {
    final toggles = <bool>[];
    var enabled = true;
    late StateSetter rebuild;
    await tester.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) {
            rebuild = setState;
            return Center(
              child: StudioFilterChip(
                label: 'Jamais lu',
                selected: false,
                onSelected: enabled ? toggles.add : null,
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Jamais lu'));
    expect(toggles, [true]);
    rebuild(() => enabled = false);
    await tester.pump();
    await tester.tap(find.text('Jamais lu'));
    expect(toggles, [true]);
  });

  testWidgets('a loading state announces its label', (tester) async {
    await tester.pumpWidget(
      _app(const StudioLoadingState(label: 'Lecture des états…')),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.getSemantics(find.bySemanticsLabel('Lecture des états…')),
      matchesSemantics(label: 'Lecture des états…', isLiveRegion: true),
    );
  });
}
