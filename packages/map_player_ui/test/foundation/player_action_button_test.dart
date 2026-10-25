import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets(
    'menu actions fit a 48 pixel footer without changing focus size',
    (tester) async {
      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);
      const key = ValueKey('menu-footer-action');
      await tester.pumpWidget(
        MaterialApp(
          theme: PokeMapPlayerTheme.light(),
          home: PlayerMenuThemeScope(
            child: Center(
              child: SizedBox(
                width: 220,
                child: PlayerActionButton(
                  key: key,
                  label: 'Utiliser',
                  icon: Icons.check,
                  focusNode: focusNode,
                  onPressed: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(key)), const Size(220, 48));
      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(key)), const Size(220, 48));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('focus preserves button geometry throughout entry and exit', (
    tester,
  ) async {
    final focusNode = FocusNode();
    addTearDown(focusNode.dispose);
    const key = ValueKey('focus-stable-action');
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: PlayerActionButton(
                key: key,
                label: 'Nouvelle partie',
                icon: Icons.add,
                focusNode: focusNode,
                onPressed: () {},
              ),
            ),
          ),
        ),
      ),
    );
    final restingSize = tester.getSize(find.byKey(key));
    for (final focused in [true, false]) {
      if (focused) {
        focusNode.requestFocus();
      } else {
        focusNode.unfocus();
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(focusNode.hasFocus, focused);
      expect(tester.getSize(find.byKey(key)), restingSize);
      await tester.pumpAndSettle();
      expect(tester.getSize(find.byKey(key)), restingSize);
    }
    expect(tester.takeException(), isNull);
  });
}
