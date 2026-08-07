import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pokemap_hub/pokemap_hub_ui.dart';

void main() {
  testWidgets(
      'console uses one frontal raster composition and centered anchors',
      (tester) async {
    await tester.pumpWidget(
      _app(
        const SizedBox(
          key: ValueKey<String>('console-frame'),
          width: 616,
          child: AveluneConsole(),
        ),
      ),
    );

    final frame = find.byKey(const ValueKey<String>('console-frame'));
    final size = tester.getSize(frame);
    expect(
        size.width / size.height, closeTo(kAveluneConsoleAspectRatio, 0.001));

    final consoleCenter = tester.getCenter(frame);
    final slot = find.byKey(const ValueKey<String>('avelune-console-slot'));
    final led = find.byKey(const ValueKey<String>('avelune-console-led'));
    expect(tester.getCenter(slot).dx, closeTo(consoleCenter.dx, 0.01));
    expect(tester.getCenter(led).dx, closeTo(consoleCenter.dx, 0.01));
    expect(tester.getCenter(slot).dy, lessThan(tester.getCenter(led).dy));

    final expectedLayers = <String, String>{
      'avelune-console-body-layer': 'assets/avelune/objects/console/body.webp',
      'avelune-console-slot-layer': 'assets/avelune/objects/console/slot.webp',
      'avelune-console-wear-layer': 'assets/avelune/objects/console/wear.webp',
      'avelune-console-contact-shadow-layer':
          'assets/avelune/objects/console/contact_shadow.webp',
    };
    for (final MapEntry(key: key, value: path) in expectedLayers.entries) {
      final image = tester.widget<Image>(
        find.byKey(ValueKey<String>(key)),
      );
      expect((image.image as AssetImage).assetName, path);
      expect(image.excludeFromSemantics, isTrue);
    }

    expect(
      find.descendant(of: frame, matching: find.byType(RepaintBoundary)),
      findsOneWidget,
    );
    expect(find.descendant(of: frame, matching: find.byType(ClipPath)),
        findsNothing);
    expect(find.descendant(of: frame, matching: find.byType(Transform)),
        findsNothing);
    expect(find.descendant(of: frame, matching: find.byType(InkWell)),
        findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('console LED follows every physical runtime state',
      (tester) async {
    final colors = AveluneThemeData.standard.colors;
    final cases = <AveluneConsoleState, Color>{
      AveluneConsoleState.idle: colors.accent,
      AveluneConsoleState.inserting: colors.warning,
      AveluneConsoleState.latched: colors.success,
      AveluneConsoleState.launching: colors.accentBright,
      AveluneConsoleState.error: colors.error,
    };

    for (final MapEntry(key: state, value: expectedColor) in cases.entries) {
      await tester.pumpWidget(
        _app(
          SizedBox(
            width: 616,
            child: AveluneConsole(state: state),
          ),
        ),
      );
      final led = tester.widget<AnimatedContainer>(
        find.byKey(const ValueKey<String>('avelune-console-led')),
      );
      final decoration = led.decoration! as BoxDecoration;
      final gradient = decoration.gradient! as LinearGradient;
      expect(gradient.colors, contains(expectedColor));
    }
  });

  testWidgets('legacy insertion progress maps to inserting then latched',
      (tester) async {
    final colors = AveluneThemeData.standard.colors;

    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 616,
          child: AveluneConsole(insertionProgress: 0.5),
        ),
      ),
    );
    expect(_ledColors(tester), contains(colors.warning));

    await tester.pumpWidget(
      _app(
        const SizedBox(
          width: 616,
          child: AveluneConsole(insertionProgress: 1),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(_ledColors(tester), contains(colors.success));
  });
}

List<Color> _ledColors(WidgetTester tester) {
  final led = tester.widget<AnimatedContainer>(
    find.byKey(const ValueKey<String>('avelune-console-led')),
  );
  return (led.decoration! as BoxDecoration).gradient!.colors;
}

Widget _app(Widget child) {
  final theme = AveluneThemeData.standard.applyTo(ThemeData.dark());
  return MaterialApp(
    theme: theme,
    home: Scaffold(
      body: Align(
        alignment: Alignment.topLeft,
        child: child,
      ),
    ),
  );
}
