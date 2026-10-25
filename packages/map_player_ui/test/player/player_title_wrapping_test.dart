import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// A game title must never break mid-word.
///
/// On a real iPhone in portrait the attract surface rendered "The Clockwork
/// Harbor" as "The Clo / ckwork / Harbor". Flutter only breaks inside a word
/// when that single word is wider than the line, so the invariant worth pinning
/// is exactly that: every word of the title has to fit the width the surface
/// gives it. Asserting that instead of a line count means the test says which
/// word overflows and by how much.
void main() {
  testWidgets('startup title fits complete long words beside its action menu', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: MediaQuery(
          data: const MediaQueryData(),
          child: PlayerTitleSurface(
            data: PlayerTitleSurfaceData(
              gameTitle: 'Pokémon — Version Or HeartGold',
              author: '',
              layoutVariant: PlayerTitleLayoutVariant.runtimeStartupCinematic,
              actions: {
                PlayerTitleMenuAction.newGame: PlayerActionAvailability.enabled,
              },
            ),
            onSelected: (_) {},
          ),
        ),
      ),
    );
    final sidebar = find.byKey(const ValueKey('player-title-startup-menu'));
    expect(tester.getSize(sidebar).width, 310);
    final titleBox = find.byKey(const ValueKey('player-title-premium-title'));
    final richText = find.descendant(
      of: titleBox,
      matching: find.byType(RichText),
    );
    final paragraph = tester.renderObject<RenderParagraph>(richText);
    expect(
      paragraph.text.toPlainText().replaceAll('\n', ' '),
      'Pokémon — Version Or HeartGold',
    );
    expect(
      paragraph.didExceedMaxLines,
      isFalse,
      reason: 'the title must not silently discard its final words',
    );
    final bounds = tester.getRect(titleBox);
    final textBounds = tester.getRect(richText);
    expect(textBounds.left, greaterThanOrEqualTo(bounds.left - .1));
    expect(textBounds.right, lessThanOrEqualTo(bounds.right + .1));
    expect(textBounds.top, greaterThanOrEqualTo(bounds.top - .1));
    expect(textBounds.bottom, lessThanOrEqualTo(bounds.bottom + .1));
    expect(tester.takeException(), isNull);
  });

  const title = 'The Clockwork Harbor';

  Future<void> pumpPrompt(WidgetTester tester, Size size) async {
    tester.view
      ..physicalSize = size * tester.view.devicePixelRatio
      ..devicePixelRatio = tester.view.devicePixelRatio;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        theme: PokeMapPlayerTheme.dark(),
        home: PlayerTitlePromptSurface(
          gameTitle: title,
          eyebrow: 'UNE EXPÉRIENCE DE JEU',
          onStart: () {},
        ),
      ),
    );
    await tester.pump();
  }

  // 393x852 is the iPhone that produced the defect; the others are the phones
  // a portrait title has to survive.
  for (final size in const <Size>[
    Size(360, 800),
    Size(393, 852),
    Size(412, 915),
  ]) {
    testWidgets('every word of the title fits at ${size.width.toInt()}pt '
        'wide', (tester) async {
      await pumpPrompt(tester, size);

      final paragraph = tester.renderObject<RenderParagraph>(find.text(title));
      final available = paragraph.constraints.maxWidth;
      final style = (paragraph.text as TextSpan).style;
      expect(style, isNotNull);

      for (final word in title.split(' ')) {
        final painter = TextPainter(
          text: TextSpan(text: word, style: style),
          textDirection: TextDirection.ltr,
          textScaler: paragraph.textScaler,
        )..layout();
        expect(
          painter.width,
          lessThanOrEqualTo(available),
          reason:
              '"$word" needs ${painter.width.toStringAsFixed(1)}pt but the '
              'title box offers ${available.toStringAsFixed(1)}pt, so Flutter '
              'breaks inside the word',
        );
        painter.dispose();
      }
    });
  }
}
