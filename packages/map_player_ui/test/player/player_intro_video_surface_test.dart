import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets('keeps captions and skip reachable on a narrow player surface',
      (tester) async {
    tester.view.physicalSize = const Size(320, 520);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var skipped = false;

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoSurface(
          media: const ColoredBox(
            key: ValueKey<String>('video-frame'),
            color: Colors.black,
          ),
          caption: 'Une nouvelle aventure commence.',
          onSkip: () => skipped = true,
        ),
      ),
    );

    expect(find.text('Une nouvelle aventure commence.'), findsOneWidget);
    expect(find.text('Passer'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Passer'));
    expect(skipped, isTrue);
  });

  testWidgets('poster fallback offers continue and optional replay',
      (tester) async {
    var continued = false;
    var replayed = false;

    await tester.pumpWidget(
      _app(
        PlayerIntroVideoSurface(
          media: const SizedBox(
            key: ValueKey<String>('intro-poster'),
            width: 200,
            height: 100,
          ),
          isPoster: true,
          onSkip: () {},
          onContinue: () => continued = true,
          onReplay: () => replayed = true,
        ),
      ),
    );

    expect(find.text('Continuer'), findsOneWidget);
    expect(find.text('Rejouer'), findsOneWidget);

    await tester.tap(find.text('Rejouer'));
    await tester.tap(find.text('Continuer'));
    expect(replayed, isTrue);
    expect(continued, isTrue);
  });

  testWidgets('missing media remains a safe path to the title', (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerIntroVideoSurface(
          media: null,
          isPoster: true,
          failureMessage: 'La vidéo ne peut pas être lue.',
          onSkip: () {},
          onContinue: () {},
        ),
      ),
    );

    expect(find.text('La vidéo ne peut pas être lue.'), findsOneWidget);
    expect(find.text('Continuer'), findsOneWidget);
  });

  testWidgets('default presentation copy follows the player locale',
      (tester) async {
    await tester.pumpWidget(
      _app(
        PlayerIntroVideoSurface(
          media: null,
          isPoster: true,
          onSkip: () {},
          onContinue: () {},
          onReplay: () {},
        ),
        locale: const Locale('en'),
      ),
    );

    expect(find.text('Video playback is unavailable.'), findsOneWidget);
    expect(find.text('Replay'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Continuer'), findsNothing);
  });
}

Widget _app(
  Widget child, {
  Locale locale = const Locale('fr'),
}) =>
    MaterialApp(
      locale: locale,
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(body: child),
    );
