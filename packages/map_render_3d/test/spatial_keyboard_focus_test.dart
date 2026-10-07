import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_render_3d/map_render_3d.dart';

void main() {
  testWidgets('shared scene surface leaves held keys to its exploration host', (
    tester,
  ) async {
    final focus = FocusNode();
    addTearDown(focus.dispose);
    var pressed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Focus(
          autofocus: true,
          focusNode: focus,
          onKeyEvent: (_, event) {
            if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
              pressed = event is! KeyUpEvent;
              return KeyEventResult.handled;
            }
            return KeyEventResult.ignored;
          },
          child: SpatialGameSurface(
            game: FlameGame(),
            loadingBuilder: (_) => const SizedBox(),
            errorBuilder: (_, error) => Text('$error'),
          ),
        ),
      ),
    );
    await tester.pump();
    final gameWidget = tester.widget<GameWidget>(
      find.byWidgetPredicate((widget) => widget is GameWidget),
    );
    expect(gameWidget.autofocus, isFalse);
    expect(focus.hasPrimaryFocus, isTrue);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowUp);
    await tester.pump(const Duration(milliseconds: 500));
    expect(pressed, isTrue);
    expect(focus.hasPrimaryFocus, isTrue);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowUp);
    expect(pressed, isFalse);
    await tester.pumpWidget(const SizedBox());
  });
}
