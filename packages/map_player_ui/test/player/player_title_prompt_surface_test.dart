import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('tap, Enter and Space expose the same primary action',
      (tester) async {
    var starts = 0;

    await tester.pumpWidget(
      _app(
        PlayerTitlePromptSurface(
          gameTitle: 'Le Train de 17h42',
          onStart: () => starts++,
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('player-title-prompt-hit-area')),
    );
    expect(starts, 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(starts, 2);

    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(starts, 3);
  });

  testWidgets('replay remains separate from the start action', (tester) async {
    var starts = 0;
    var replays = 0;

    await tester.pumpWidget(
      _app(
        PlayerTitlePromptSurface(
          gameTitle: 'Le Train de 17h42',
          onStart: () => starts++,
          onReplayIntro: () => replays++,
        ),
      ),
    );

    await tester.tap(find.text('Rejouer l’intro'));
    expect(replays, 1);
    expect(starts, 0);
  });
}

Widget _app(Widget child) => MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: child,
    );
