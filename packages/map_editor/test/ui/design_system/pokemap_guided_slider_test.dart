import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_editor/src/theme/theme.dart';
import 'package:map_editor/src/ui/design_system/design_system.dart';

void main() {
  testWidgets('joins focus traversal and closes each arrow-key adjustment',
      (tester) async {
    final leadingFocus = FocusNode();
    addTearDown(leadingFocus.dispose);
    var value = 50;
    final events = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return Column(
                children: [
                  Focus(
                    focusNode: leadingFocus,
                    child: const SizedBox(
                      width: 20,
                      height: 20,
                    ),
                  ),
                  PokeMapGuidedSlider(
                    key: const ValueKey<String>('guided-slider'),
                    label: 'Opacité',
                    value: value,
                    onChangeStart: (current) => events.add('start:$current'),
                    onChanged: (next) {
                      events.add('change:$next');
                      setState(() => value = next);
                    },
                    onChangeEnd: (current) => events.add('end:$current'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );

    final focusDetector = find.descendant(
      of: find.byKey(const ValueKey<String>('guided-slider')),
      matching: find.byType(FocusableActionDetector),
    );
    expect(focusDetector, findsOneWidget);
    final sliderFocus =
        tester.widget<FocusableActionDetector>(focusDetector).focusNode!;

    leadingFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(sliderFocus.hasFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(value, 51);
    expect(events, const ['start:50', 'change:51', 'end:51']);
  });
}
