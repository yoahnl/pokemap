import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_player_ui/src/player/player_pause_illustrated_root.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  for (final size in [
    const Size(1440, 900),
    const Size(844, 390),
    const Size(390, 844),
  ]) {
    for (final mode in [
      (
        name: 'full',
        effects: RuntimePlayerMenuEffects.full,
        highContrast: false
      ),
      (
        name: 'reduced',
        effects: RuntimePlayerMenuEffects.reduced,
        highContrast: false
      ),
      (
        name: 'opaque',
        effects: RuntimePlayerMenuEffects.opaque,
        highContrast: false
      ),
      (
        name: 'high contrast',
        effects: RuntimePlayerMenuEffects.full,
        highContrast: true
      ),
    ]) {
      for (final artwork in [Colors.white, Colors.black]) {
        testWidgets(
            'root hint has composed AA contrast in ${mode.name} over $artwork at $size',
            (tester) async {
          tester.view.devicePixelRatio = 1;
          tester.view.physicalSize = size;
          addTearDown(tester.view.resetDevicePixelRatio);
          addTearDown(tester.view.resetPhysicalSize);
          const hint = 'Votre aventure continue';
          await tester.pumpWidget(MaterialApp(
            theme: PokeMapPlayerTheme.dark(),
            home: MediaQuery(
              data: MediaQueryData(size: size, highContrast: mode.highContrast),
              child: PlayerMenuEffectsScope(
                effects: mode.effects,
                child: PlayerMenuThemeScope(
                  child: PlayerPauseIllustratedRoot(
                    gameTitle: 'Contraste',
                    menuTitle: 'Menu',
                    hint: hint,
                    showSummary: false,
                    navigation: const SizedBox.shrink(),
                    background: ColoredBox(color: artwork),
                  ),
                ),
              ),
            ),
          ));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);

          final text = find.text(hint);
          final foreground = tester.widget<Text>(text).style!.color!;
          final bounds = tester.getRect(text);
          for (final point in [
            Offset(bounds.center.dx, bounds.top + 1),
            bounds.center,
            Offset(bounds.center.dx, bounds.bottom - 1),
          ]) {
            final background = _composedBackgroundAt(
              find.byType(PlayerPauseIllustratedRoot),
              point,
            );
            final contrast = _contrast(foreground, background);
            expect(contrast, greaterThanOrEqualTo(4.5),
                reason: '${mode.name}, artwork $artwork, at $point: '
                    '$foreground over $background = $contrast:1');
          }
        });
      }
    }
  }
}

Color _composedBackgroundAt(Finder root, Offset point) {
  var composed = Colors.transparent;
  final layers = find.descendant(
      of: root,
      matching: find.byWidgetPredicate(
          (widget) => widget is ColoredBox || widget is DecoratedBox));
  for (final element in layers.evaluate()) {
    final render = element.findRenderObject()! as RenderBox;
    final bounds = render.localToGlobal(Offset.zero) & render.size;
    if (!bounds.contains(point)) continue;
    final widget = element.widget;
    if (widget is ColoredBox) {
      composed = Color.alphaBlend(widget.color, composed);
    } else if (widget is DecoratedBox) {
      final decoration = widget.decoration as BoxDecoration;
      if (decoration.color case final color?) {
        composed = Color.alphaBlend(color, composed);
      }
      if (decoration.gradient case final LinearGradient gradient) {
        final direction = Directionality.of(element);
        final begin = gradient.begin.resolve(direction).alongSize(bounds.size);
        final end = gradient.end.resolve(direction).alongSize(bounds.size);
        final vector = end - begin;
        final local = point - bounds.topLeft - begin;
        final position = ((local.dx * vector.dx + local.dy * vector.dy) /
                vector.distanceSquared)
            .clamp(0.0, 1.0);
        final stops = gradient.stops ??
            List.generate(gradient.colors.length,
                (index) => index / (gradient.colors.length - 1));
        var color = gradient.colors.last;
        if (position <= stops.first) {
          color = gradient.colors.first;
        } else {
          for (var index = 1; index < stops.length; index++) {
            if (position <= stops[index]) {
              final fraction = (position - stops[index - 1]) /
                  (stops[index] - stops[index - 1]);
              color = Color.lerp(gradient.colors[index - 1],
                  gradient.colors[index], fraction)!;
              break;
            }
          }
        }
        composed = Color.alphaBlend(color, composed);
      }
    }
  }
  expect(composed.a, 1);
  return composed;
}

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  return (first > second ? first + .05 : second + .05) /
      (first > second ? second + .05 : first + .05);
}
