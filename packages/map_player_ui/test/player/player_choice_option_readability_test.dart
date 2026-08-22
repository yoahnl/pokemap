import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// A player must be able to read the options they are choosing between.
///
/// On a phone in portrait the Night Watch choice rendered as "La gardienne de
/// l'au…" and "Le gardien du crépu…": a single-line label with an ellipsis, on
/// buttons that had room to spare vertically. Choosing blind is a functional
/// defect, not a cosmetic one.
///
/// `RenderParagraph.didExceedMaxLines` is the exact signal — it is what makes
/// the ellipsis appear — so the assertion is on the truncation itself rather
/// than on a pixel width or a golden.
void main() {
  const dawn = 'La gardienne de l’aube';
  const dusk = 'Le gardien du crépuscule';

  Future<void> pumpChoice(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size * tester.view.devicePixelRatio
      ..devicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: PlayerSceneInteractionSurface(
          request: SceneInteractionRequest.choice(
            requestId: 'choice',
            revision: 1,
            prompt: _prompt('Qui prend la veille ?'),
            options: <SceneInteractionOption>[
              SceneInteractionOption(id: 'dawn', label: _prompt(dawn)),
              SceneInteractionOption(id: 'dusk', label: _prompt(dusk)),
            ],
          ),
          onResult: (_) {},
        ),
      ),
    );
    await tester.pump();
  }

  for (final size in const <Size>[
    Size(360, 800),
    Size(393, 852),
    Size(412, 915),
  ]) {
    testWidgets('no option is truncated at ${size.width.toInt()}pt wide',
        (tester) async {
      await pumpChoice(tester, size);

      for (final label in const <String>[dawn, dusk]) {
        final paragraph = tester.renderObject<RenderParagraph>(
          find.text(label),
        );
        expect(
          paragraph.didExceedMaxLines,
          isFalse,
          reason: '"$label" is ellipsized, so the player cannot read the '
              'option they are about to pick',
        );
      }
    });
  }

  testWidgets('a command label still stays on one line', (tester) async {
    // The opt-in must remain opt-in: every other button in both apps keeps its
    // single-line label, or this change moves layouts nobody asked about.
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: const Scaffold(
          body: SizedBox(
            width: 120,
            child: PlayerActionButton(
              label: 'Une commande particulièrement longue',
              icon: Icons.check,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final paragraph = tester.renderObject<RenderParagraph>(
      find.text('Une commande particulièrement longue'),
    );
    expect(paragraph.didExceedMaxLines, isTrue);
  });
}

SceneInteractionPrompt _prompt(String text) => SceneInteractionPrompt(
      localizationKey: 'test.prompt',
      fallbackText: text,
    );
