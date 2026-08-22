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
          reason: '"$word" needs ${painter.width.toStringAsFixed(1)}pt but the '
              'title box offers ${available.toStringAsFixed(1)}pt, so Flutter '
              'breaks inside the word',
        );
        painter.dispose();
      }
    });
  }
}
