import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/cupertino.dart';
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
    await tester.pumpAndSettle();

    final focusDetector = find.descendant(
      of: find.byKey(const ValueKey<String>('guided-slider')),
      matching: find.byType(FocusableActionDetector),
    );
    expect(focusDetector, findsOneWidget);
    final focusIndicator = find.descendant(
      of: find.byKey(const ValueKey<String>('guided-slider')),
      matching: find.byKey(
        const ValueKey<String>('pokemap-guided-slider-focus-indicator'),
      ),
    );
    expect(focusIndicator, findsOneWidget);
    final colors = tester.element(focusIndicator).pokeMapColors;
    final slider = find.descendant(
      of: find.byKey(const ValueKey<String>('guided-slider')),
      matching: find.byType(CupertinoSlider),
    );
    final restingSliderRect = tester.getRect(slider);
    expect(
      _paintedFocusBorderColor(tester, focusIndicator),
      colors.brandPrimary.withValues(alpha: 0),
    );
    final sliderFocus =
        tester.widget<FocusableActionDetector>(focusDetector).focusNode!;

    leadingFocus.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pumpAndSettle();
    expect(sliderFocus.hasFocus, isTrue);
    expect(
      _paintedFocusBorderColor(tester, focusIndicator),
      colors.brandPrimary,
    );
    expect(tester.getRect(slider), restingSliderRect);

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();

    expect(value, 51);
    expect(events, const ['start:50', 'change:51', 'end:51']);
  });

  testWidgets(
      'mouse focus keeps the painted ring hidden without moving the slider',
      (tester) async {
    final previousStrategy = FocusManager.instance.highlightStrategy;
    FocusManager.instance.highlightStrategy =
        FocusHighlightStrategy.alwaysTraditional;
    addTearDown(() {
      FocusManager.instance.highlightStrategy = previousStrategy;
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: PokeMapGuidedSlider(
            key: const ValueKey<String>('guided-slider'),
            label: 'Opacité',
            value: 50,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final root = find.byKey(const ValueKey<String>('guided-slider'));
    final focusDetector = find.descendant(
      of: root,
      matching: find.byType(FocusableActionDetector),
    );
    final slider = find.descendant(
      of: root,
      matching: find.byType(CupertinoSlider),
    );
    final focusIndicator = find.descendant(
      of: root,
      matching: find.byKey(
        const ValueKey<String>('pokemap-guided-slider-focus-indicator'),
      ),
    );
    final colors = tester.element(focusIndicator).pokeMapColors;
    final restingSliderRect = tester.getRect(slider);

    final gesture = await tester.startGesture(
      tester.getCenter(slider),
      kind: PointerDeviceKind.mouse,
    );
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      tester.widget<FocusableActionDetector>(focusDetector).focusNode!.hasFocus,
      isTrue,
    );
    expect(
      _paintedFocusBorderColor(tester, focusIndicator),
      colors.brandPrimary.withValues(alpha: 0),
    );
    expect(tester.getRect(slider), restingSliderRect);
  });

  testWidgets('inline layout stays compact without losing its accessible value',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapTheme.dark(),
        home: Scaffold(
          body: SizedBox(
            width: 220,
            child: PokeMapGuidedSlider(
              key: const ValueKey<String>('inline-guided-slider'),
              label: 'Opacité',
              value: 75,
              layout: PokeMapGuidedSliderLayout.inline,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final slider = find.byKey(
      const ValueKey<String>('inline-guided-slider'),
    );
    expect(tester.getSize(slider).height, lessThanOrEqualTo(44));
    final semantics = tester.getSemantics(slider);
    expect(semantics.label, contains('Opacité'));
    expect(semantics.label, contains('75 %'));
    expect(tester.takeException(), isNull);
  });
}

Color _paintedFocusBorderColor(WidgetTester tester, Finder indicator) {
  final decoration =
      tester.widget<DecoratedBox>(indicator).decoration as BoxDecoration;
  return (decoration.border! as Border).top.color;
}
