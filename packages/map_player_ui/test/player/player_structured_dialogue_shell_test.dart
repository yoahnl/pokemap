import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

/// Les interactions structurées dans le shell dialogue — BETA-CIN-075.
///
/// Choice, text, confirmation et selection rendent dans le même shell
/// visuel ancré en bas que les messages paginés : thématisé rôle dialogue,
/// composition visible, clavier virtuel qui ne masque jamais le champ en
/// 9:16, saisie par graphèmes entiers, résultats appliqués exclusivement
/// par le port (jamais d'écriture directe du draft), et un enchaînement
/// message→choix→message→saisie→confirmation déterministe.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(_loadFixtureFont);

  Widget app({
    required SceneInteractionRequest request,
    required List<SceneInteractionResult> results,
    EdgeInsets viewInsets = EdgeInsets.zero,
  }) =>
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: PokeMapPlayerTheme.dark(reducedMotion: true),
        home: MediaQuery(
          data: MediaQueryData(
            disableAnimations: true,
            viewInsets: viewInsets,
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

  SceneInteractionPrompt prompt(String text) => SceneInteractionPrompt(
        localizationKey: 'test.prompt',
        fallbackText: text,
      );

  testWidgets('every structured kind renders inside the dialogue shell',
      (tester) async {
    final requests = <SceneInteractionRequest>[
      SceneInteractionRequest.choice(
        requestId: 'choice',
        revision: 1,
        prompt: prompt('Choisissez'),
        options: [
          SceneInteractionOption(
            id: 'north',
            label: prompt('Nord'),
          ),
        ],
      ),
      SceneInteractionRequest.text(
        requestId: 'text',
        revision: 2,
        prompt: prompt('Votre nom ?'),
      ),
      SceneInteractionRequest.confirmation(
        requestId: 'confirm',
        revision: 3,
        prompt: prompt('Sûr ?'),
      ),
      SceneInteractionRequest.selection(
        requestId: 'select',
        revision: 4,
        prompt: prompt('Composez'),
        options: [
          SceneInteractionOption(id: 'only', label: prompt('Seul')),
        ],
        constraints: SceneSelectionConstraints(
          minSelections: 1,
          maxSelections: 1,
        ),
      ),
    ];
    for (final request in requests) {
      await tester.pumpWidget(
        app(request: request, results: <SceneInteractionResult>[]),
      );
      final panel = find.byKey(
        const ValueKey<String>('scene-interaction-panel'),
      );
      expect(panel, findsOneWidget, reason: '${request.kind.name} panel');
      final surfaceSize = tester.getSize(find.byType(MaterialApp));
      final panelBottom = tester.getBottomLeft(panel).dy;
      expect(
        panelBottom,
        greaterThanOrEqualTo(surfaceSize.height - 80),
        reason: '${request.kind.name} hugs the bottom edge, over the '
            'maintained composition — never a centered modal',
      );
      expect(
        find.descendant(
          of: panel,
          matching: find.byType(PlayerSurfacePaletteScope),
        ),
        findsWidgets,
        reason: '${request.kind.name} is themed through the dialogue surface '
            'role, like the message box',
      );
    }
  });

  testWidgets('the virtual keyboard never hides the text field in 9:16',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 780));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(
        request: SceneInteractionRequest.text(
          requestId: 'text',
          revision: 1,
          prompt: prompt('Votre nom ?'),
        ),
        results: results,
        viewInsets: const EdgeInsets.only(bottom: 300),
      ),
    );
    await tester.pumpAndSettle();
    final field = find.byKey(
      const ValueKey<String>('scene-interaction-text-field'),
    );
    expect(field, findsOneWidget);
    expect(
      tester.getBottomLeft(field).dy,
      lessThanOrEqualTo(780 - 300),
      reason: 'the shell lifts above the keyboard inset: the field stays '
          'visible while typing one-handed',
    );
  });

  testWidgets('text input counts whole graphemes through the IME',
      (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(
        request: SceneInteractionRequest.text(
          requestId: 'text',
          revision: 1,
          prompt: prompt('Votre nom ?'),
          constraints: SceneTextInputConstraints(
            minGraphemes: 1,
            maxGraphemes: 5,
          ),
        ),
        results: results,
      ),
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
      'Zoé🐉‍🔥AB',
    );
    await tester.pump();
    final field = tester.widget<TextField>(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
    );
    expect(
      field.controller!.text.characters.length,
      lessThanOrEqualTo(5),
      reason: 'the limit counts graphemes, never code units',
    );
    expect(
      field.controller!.text.characters.take(4).toString(),
      'Zoé🐉‍🔥',
      reason: 'the composed emoji survives the truncation whole',
    );
  });

  testWidgets('a double tap on a choice writes exactly one result',
      (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      app(
        request: SceneInteractionRequest.choice(
          requestId: 'choice',
          revision: 1,
          prompt: prompt('Choisissez'),
          options: [
            SceneInteractionOption(id: 'north', label: prompt('Nord')),
          ],
        ),
        results: results,
      ),
    );
    final option = find.text('Nord');
    await tester.tap(option);
    await tester.tap(option, warnIfMissed: false);
    await tester.pump();
    expect(
      results,
      hasLength(1),
      reason: 'a stale or duplicated tap can never write twice — the draft '
          'is applied once by the coordinator, never by the widget',
    );
  });

  testWidgets(
      'message, choice, message, text, confirmation flow deterministically',
      (tester) async {
    final results = <SceneInteractionResult>[];
    final flow = <SceneInteractionRequest>[
      SceneInteractionRequest.message(
        requestId: 'intro',
        revision: 1,
        prompt: prompt('Bienvenue !'),
      ),
      SceneInteractionRequest.choice(
        requestId: 'avatar',
        revision: 2,
        prompt: prompt('Votre avatar ?'),
        options: [
          SceneInteractionOption(id: 'hero', label: prompt('Héros')),
        ],
      ),
      SceneInteractionRequest.message(
        requestId: 'nice',
        revision: 3,
        prompt: prompt('Excellent choix !'),
      ),
      SceneInteractionRequest.text(
        requestId: 'name',
        revision: 4,
        prompt: prompt('Votre nom ?'),
      ),
      SceneInteractionRequest.confirmation(
        requestId: 'confirm',
        revision: 5,
        prompt: prompt('On garde ce nom ?'),
      ),
    ];

    Future<void> pumpStep(int index) async {
      await tester.pumpWidget(app(request: flow[index], results: results));
      await tester.pump();
    }

    await pumpStep(0);
    await tester.tap(
      find.byKey(const ValueKey<String>('dialogue-tap-zone')).first,
    );
    await tester.pump();
    expect(results, hasLength(1));

    await pumpStep(1);
    expect(
      find.byKey(const ValueKey<String>('dialogue-tap-zone')),
      findsNothing,
      reason: 'the previous page left no residue',
    );
    await tester.tap(find.text('Héros'));
    await tester.pump();
    expect(results, hasLength(2));

    await pumpStep(2);
    await tester.tap(
      find.byKey(const ValueKey<String>('dialogue-tap-zone')).first,
    );
    await tester.pump();
    expect(results, hasLength(3));

    await pumpStep(3);
    expect(
      tester
          .widget<TextField>(
            find.byKey(
              const ValueKey<String>('scene-interaction-text-field'),
            ),
          )
          .controller!
          .text,
      isEmpty,
      reason: 'the text field starts clean at its step',
    );
    await tester.enterText(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
      'Zoé',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump();
    expect(results, hasLength(4));

    await pumpStep(4);
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-confirm-yes')),
    );
    await tester.pump();
    expect(
      results.map((result) => result.requestId),
      <String>['intro', 'avatar', 'nice', 'name', 'confirm'],
      reason: 'the canonical pre-session chain resolves in exact order',
    );
  });

  for (final (orientation, size) in <(String, Size)>[
    ('landscape', Size(960, 540)),
    ('portrait', Size(540, 960)),
  ]) {
    for (final kind in <String>['choice', 'text']) {
      testWidgets('golden: $kind in the shell in $orientation',
          (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final request = kind == 'choice'
            ? SceneInteractionRequest.choice(
                requestId: 'choice',
                revision: 1,
                prompt: prompt('Quel chemin prendre ?'),
                options: [
                  SceneInteractionOption(id: 'north', label: prompt('Nord')),
                  SceneInteractionOption(id: 'south', label: prompt('Sud')),
                ],
              )
            : SceneInteractionRequest.text(
                requestId: 'text',
                revision: 1,
                prompt: prompt('Quel est ton prénom ?'),
              );
        await tester.pumpWidget(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: PokeMapPlayerTheme.dark(reducedMotion: true),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: RepaintBoundary(
                key: const ValueKey<String>('structured-shell-golden'),
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: <Color>[
                            Color(0xFF1B2A4A),
                            Color(0xFF3A1B4A),
                          ],
                        ),
                      ),
                    ),
                    PlayerSceneInteractionSurface(
                      request: request,
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
          find.byKey(const ValueKey<String>('structured-shell-golden')),
          matchesGoldenFile(
            'goldens/structured_dialogue_shell/${orientation}_$kind.png',
          ),
        );
      });
    }
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
