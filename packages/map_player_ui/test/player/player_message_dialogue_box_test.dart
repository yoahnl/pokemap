import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// La boîte de dialogue riche des messages pré-session — BETA-CIN-074.
///
/// Les messages passent par le MÊME PlayerDialogueSurface que le Hub : la
/// machine à écrire révèle par graphèmes entiers, le premier appui complète,
/// le suivant valide exactement une fois, reduced motion révèle tout
/// immédiatement, le locuteur s'affiche quand la requête le porte, et les
/// compositions 16:9 comme 9:16 tiennent à 200% de taille de texte sans
/// overflow. Les goldens figent les deux orientations.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFixtureFont);

  Widget app({
    required SceneInteractionRequest request,
    required List<SceneInteractionResult> results,
    bool reduceMotion = false,
    double textScale = 1,
  }) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PokeMapPlayerTheme.dark(reducedMotion: reduceMotion),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: reduceMotion,
            textScaler: TextScaler.linear(textScale),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              const ColoredBox(color: Color(0xFF223344)),
              PlayerSceneInteractionSurface(
                request: request,
                onResult: results.add,
              ),
            ],
          ),
        ),
      );

  SceneInteractionRequest message({
    String text = 'Bonjour Zoé 🐉‍🔥 !',
    String? speakerName,
  }) =>
      SceneInteractionRequest.message(
        requestId: 'message',
        revision: 1,
        speakerName: speakerName,
        prompt: SceneInteractionPrompt(
          localizationKey: 'test.message',
          fallbackText: text,
        ),
      );

  Finder tapZone() =>
      find.byKey(const ValueKey<String>('dialogue-tap-zone')).first;

  testWidgets('the typewriter reveals whole graphemes, never torn emoji',
      (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(request: message(text: 'A🐉‍🔥B'), results: results),
    );
    await tester.pump(const Duration(milliseconds: 18));
    await tester.pump(const Duration(milliseconds: 18));

    final texts = tester
        .widgetList<Text>(
          find.descendant(
            of: find.byKey(
              const ValueKey<String>('scene-interaction-message-dialogue'),
            ),
            matching: find.byType(Text),
          ),
        )
        .map((text) => text.data)
        .whereType<String>()
        .toList();
    const wholePrefixes = <String>['', 'A', 'A🐉‍🔥', 'A🐉‍🔥B'];
    for (final text in texts) {
      if (text.startsWith('A') || text.isEmpty) {
        expect(
          wholePrefixes,
          contains(text),
          reason: 'every intermediate state is a whole-grapheme prefix — the '
              'ZWJ emoji must never appear torn apart',
        );
      }
    }
    expect(
      texts.where(wholePrefixes.contains),
      isNotEmpty,
      reason: 'the revealed line is rendered inside the dialogue box',
    );

    await tester.tap(tapZone());
    await tester.pump();
    expect(find.text('A🐉‍🔥B'), findsOneWidget);
    expect(results, isEmpty);
  });

  testWidgets('reduced motion reveals the full page immediately',
      (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(request: message(), results: results, reduceMotion: true),
    );
    expect(
      find.text('Bonjour Zoé 🐉‍🔥 !'),
      findsOneWidget,
      reason: 'no typewriter under reduced motion — the page is readable at '
          'the first frame',
    );
    await tester.tap(tapZone());
    await tester.pump();
    expect(results.single, isA<SceneAcknowledgedInteractionResult>());
  });

  testWidgets('a rapid double press validates exactly once', (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(request: message(), results: results, reduceMotion: true),
    );
    await tester.tap(tapZone());
    await tester.tap(tapZone(), warnIfMissed: false);
    await tester.pump();
    expect(
      results,
      hasLength(1),
      reason: 'one validation event per page, whatever the press cadence',
    );
  });

  testWidgets('an acknowledged page stops advertising a dead Suite action',
      (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(request: message(), results: results, reduceMotion: true),
    );

    await tester.tap(tapZone());
    await tester.pump();

    expect(results, hasLength(1));
    expect(find.text('Suite'), findsNothing);
    expect(
      find.byKey(
        const ValueKey<String>('dialogue-progress-indicator-pending'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('the speaker shows when the request carries one', (tester) async {
    await tester.pumpWidget(
      app(
        request: message(speakerName: 'Professeur Aube'),
        results: <SceneInteractionResult>[],
        reduceMotion: true,
      ),
    );
    expect(find.text('Professeur Aube'), findsOneWidget);
  });

  for (final (label, size) in <(String, Size)>[
    ('16:9', Size(780, 360)),
    ('9:16', Size(360, 780)),
  ]) {
    testWidgets('long text at 200% scale stays readable in $label',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        app(
          request: message(
            text: 'Il était une fois, dans la région de Hanazuki, une '
                'aventure ferroviaire qui commençait par un très long '
                'paragraphe de présentation destiné à éprouver la mise en '
                'page de la boîte de dialogue sur un téléphone étroit.',
            speakerName: 'Narrateur des trains de dix-sept heures '
                'quarante-deux',
          ),
          results: <SceneInteractionResult>[],
          reduceMotion: true,
          textScale: 2,
        ),
      );
      await tester.pump();
      expect(
        tester.takeException(),
        isNull,
        reason: 'no overflow: portrait-less layout, long locale, long text '
            'and 200% scale must all stay readable',
      );
    });
  }

  for (final (orientation, size) in <(String, Size)>[
    ('landscape', Size(960, 540)),
    ('portrait', Size(540, 960)),
  ]) {
    testWidgets('golden: the message box over the frame in $orientation',
        (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: PokeMapPlayerTheme.dark(reducedMotion: true),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: RepaintBoundary(
              key: const ValueKey<String>('message-dialogue-golden'),
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: <Color>[Color(0xFF1B2A4A), Color(0xFF3A1B4A)],
                      ),
                    ),
                  ),
                  PlayerSceneInteractionSurface(
                    request: message(
                      text: 'Bienvenue dans le monde de Hanazuki !',
                      speakerName: 'Professeur Aube',
                    ),
                    onResult: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey<String>('message-dialogue-golden')),
        matchesGoldenFile(
          'goldens/message_dialogue_box/${orientation}_message.png',
        ),
      );
    });
  }
}

Future<void> _loadFixtureFont() async {
  final bytes = await File(
    '${Directory.current.path}/../../examples/playable_runtime_host/'
    'golden_personalization_v3/assets/presentation/fonts/display.ttf',
  ).readAsBytes();
  await _loadFont('Aube Display', bytes);
  await _loadFont('Avenir Next', bytes);
}

Future<void> _loadFont(String family, Uint8List bytes) async {
  await (FontLoader(family)
        ..addFont(Future<ByteData>.value(ByteData.sublistView(bytes))))
      .load();
}
