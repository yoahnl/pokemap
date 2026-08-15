import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';

void main() {
  testWidgets(
      'message, choice, confirmation and selection publish typed results',
      (tester) async {
    final results = <SceneInteractionResult>[];

    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.message(
          requestId: 'message',
          revision: 1,
          prompt: _prompt('Bienvenue'),
        ),
        results: results,
      ),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('scene-interaction-message-submit'),
      ),
    );
    expect(results.single, isA<SceneAcknowledgedInteractionResult>());

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.choice(
          requestId: 'choice',
          revision: 2,
          prompt: _prompt('Choisissez une voie'),
          options: <SceneInteractionOption>[
            _option('north', 'Nord'),
            _option('south', 'Sud'),
          ],
        ),
        results: results,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-option-south')),
    );
    expect(
      results.single,
      isA<SceneChoiceSelectedInteractionResult>()
          .having((result) => result.selectedOptionId, 'option', 'south'),
    );

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.confirmation(
          requestId: 'confirmation',
          revision: 3,
          prompt: _prompt('Continuer ?'),
        ),
        results: results,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-confirm-no')),
    );
    expect(
      results.single,
      isA<SceneConfirmedInteractionResult>()
          .having((result) => result.value, 'value', isFalse),
    );

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.selection(
          requestId: 'selection',
          revision: 4,
          prompt: _prompt('Choisissez deux compagnons'),
          options: <SceneInteractionOption>[
            _option('a', 'Aube'),
            _option('b', 'Brume'),
            _option('c', 'Cendre'),
          ],
          constraints: SceneSelectionConstraints(
            minSelections: 2,
            maxSelections: 2,
          ),
        ),
        results: results,
      ),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-option-a')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-option-c')),
    );
    await tester.tap(
      find.byKey(
        const ValueKey<String>('scene-interaction-selection-submit'),
      ),
    );
    expect(
      results.single,
      isA<SceneSelectionSubmittedInteractionResult>().having(
        (result) => result.selectedOptionIds,
        'options',
        <String>['a', 'c'],
      ),
    );
  });

  testWidgets('text keeps IME composition and limits committed graphemes',
      (tester) async {
    final results = <SceneInteractionResult>[];
    final request = SceneInteractionRequest.text(
      requestId: 'name',
      revision: 5,
      prompt: _prompt('Votre nom'),
      constraints: SceneTextInputConstraints(
        minGraphemes: 2,
        maxGraphemes: 2,
      ),
    );

    await tester.pumpWidget(_app(request: request, results: results));
    final field = find.byKey(
      const ValueKey<String>('scene-interaction-text-field'),
    );
    await tester.tap(field);
    final composed = 'e\u0301👨‍👩‍👧‍👦a';
    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: composed,
        selection: TextSelection.collapsed(offset: composed.length),
        composing: TextRange(start: 0, end: composed.length),
      ),
    );
    await tester.pump();

    var editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, composed);
    expect(
      editable.controller.value.composing,
      TextRange(start: 0, end: composed.length),
    );

    tester.testTextInput.updateEditingValue(
      TextEditingValue(
        text: composed,
        selection: TextSelection.collapsed(offset: composed.length),
      ),
    );
    await tester.pump();

    editable = tester.widget<EditableText>(find.byType(EditableText));
    expect(editable.controller.text, 'e\u0301👨‍👩‍👧‍👦');
    expect(find.text('2 / 2'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-text-submit')),
    );
    expect(
      results.single,
      isA<SceneTextSubmittedInteractionResult>().having(
        (result) => result.value,
        'value',
        'e\u0301👨‍👩‍👧‍👦',
      ),
    );
  });

  testWidgets('invalid text stays open and exposes an accessible error',
      (tester) async {
    final results = <SceneInteractionResult>[];
    final request = SceneInteractionRequest.text(
      requestId: 'name',
      revision: 6,
      prompt: _prompt('Votre nom'),
      constraints: SceneTextInputConstraints(minGraphemes: 2),
    );

    await tester.pumpWidget(_app(request: request, results: results));
    await tester.enterText(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
      'A',
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-text-submit')),
    );
    await tester.pump();

    expect(results, isEmpty);
    expect(find.text('Saisissez au moins 2 caractères.'), findsOneWidget);
    final semantics = tester.getSemantics(
      find.byKey(const ValueKey<String>('scene-interaction-error')),
    );
    expect(semantics.flagsCollection.isLiveRegion, isTrue);
  });

  testWidgets('cancel emits a typed user cancellation exactly once',
      (tester) async {
    final results = <SceneInteractionResult>[];
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.message(
          requestId: 'cancel',
          revision: 7,
          prompt: _prompt('Attendre ?'),
        ),
        results: results,
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-cancel')),
    );
    await tester.tap(
      find.byKey(const ValueKey<String>('scene-interaction-cancel')),
      warnIfMissed: false,
    );

    expect(
      results.single,
      isA<SceneCancelledInteractionResult>()
          .having(
            (result) => result.reason,
            'reason',
            SceneInteractionCancellationReason.user,
          )
          .having((result) => result.revision, 'revision', 7),
    );
  });

  testWidgets('stale controls cannot publish into a newer request revision',
      (tester) async {
    final results = <SceneInteractionResult>[];
    Widget app(int revision) => _app(
          request: SceneInteractionRequest.message(
            requestId: 'same-request',
            revision: revision,
            prompt: _prompt('Révision $revision'),
          ),
          results: results,
        );

    await tester.pumpWidget(app(1));
    final staleCallback = tester
        .widget<PlayerActionButton>(
          find.byKey(
            const ValueKey<String>('scene-interaction-message-submit'),
          ),
        )
        .onPressed!;

    await tester.pumpWidget(app(2));
    staleCallback();
    await tester.pump();
    expect(results, isEmpty);

    await tester.tap(
      find.byKey(
        const ValueKey<String>('scene-interaction-message-submit'),
      ),
    );
    expect(results.single.revision, 2);
  });

  testWidgets(
      'keyboard and controller logical intents activate focused choices',
      (tester) async {
    final results = <SceneInteractionResult>[];
    final request = SceneInteractionRequest.choice(
      requestId: 'input',
      revision: 8,
      prompt: _prompt('Direction'),
      options: <SceneInteractionOption>[
        _option('left', 'Gauche'),
        _option('right', 'Droite'),
      ],
    );

    await tester.pumpWidget(_app(request: request, results: results));
    await tester.pump();
    expect(
      FocusManager.instance.primaryFocus?.debugLabel,
      'Player action: Gauche',
    );

    Actions.invoke(
      FocusManager.instance.primaryFocus!.context!,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.down,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();
    Actions.invoke(
      FocusManager.instance.primaryFocus!.context!,
      const RuntimePlayerLogicalIntent(
        PlayerInputAction.confirm,
        source: PlayerInputSource.controller,
      ),
    );
    await tester.pump();
    expect(
      (results.single as SceneChoiceSelectedInteractionResult).selectedOptionId,
      'right',
    );

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.choice(
          requestId: 'keyboard',
          revision: 9,
          prompt: _prompt('Direction'),
          options: <SceneInteractionOption>[
            _option('left', 'Gauche'),
            _option('right', 'Droite'),
          ],
        ),
        results: results,
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(
      (results.single as SceneChoiceSelectedInteractionResult).selectedOptionId,
      'right',
    );
  });

  testWidgets('controller completes message, text, confirmation and selection',
      (tester) async {
    final results = <SceneInteractionResult>[];

    void invoke(PlayerInputAction action) {
      Actions.invoke(
        FocusManager.instance.primaryFocus!.context!,
        RuntimePlayerLogicalIntent(
          action,
          source: PlayerInputSource.controller,
        ),
      );
    }

    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.message(
          requestId: 'controller-message',
          revision: 11,
          prompt: _prompt('Message'),
        ),
        results: results,
      ),
    );
    await tester.pump();
    invoke(PlayerInputAction.confirm);
    expect(results.single, isA<SceneAcknowledgedInteractionResult>());

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.text(
          requestId: 'controller-text',
          revision: 12,
          prompt: _prompt('Nom'),
        ),
        results: results,
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
      'Avelune',
    );
    invoke(PlayerInputAction.confirm);
    expect(
      results.single,
      isA<SceneTextSubmittedInteractionResult>()
          .having((result) => result.value, 'value', 'Avelune'),
    );

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.confirmation(
          requestId: 'controller-confirmation',
          revision: 13,
          prompt: _prompt('Continuer ?'),
        ),
        results: results,
      ),
    );
    await tester.pump();
    invoke(PlayerInputAction.confirm);
    expect(
      results.single,
      isA<SceneConfirmedInteractionResult>()
          .having((result) => result.value, 'value', isTrue),
    );

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.selection(
          requestId: 'controller-selection',
          revision: 14,
          prompt: _prompt('Sélection'),
          options: <SceneInteractionOption>[_option('only', 'Unique')],
        ),
        results: results,
      ),
    );
    await tester.pump();
    invoke(PlayerInputAction.confirm);
    await tester.pump();
    invoke(PlayerInputAction.down);
    await tester.pump();
    invoke(PlayerInputAction.confirm);
    expect(
      results.single,
      isA<SceneSelectionSubmittedInteractionResult>().having(
        (result) => result.selectedOptionIds,
        'options',
        <String>['only'],
      ),
    );
  });

  testWidgets('keyboard completes message, text, confirmation and selection',
      (tester) async {
    final results = <SceneInteractionResult>[];

    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.message(
          requestId: 'keyboard-message',
          revision: 15,
          prompt: _prompt('Message'),
        ),
        results: results,
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(results.single, isA<SceneAcknowledgedInteractionResult>());

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.text(
          requestId: 'keyboard-text',
          revision: 16,
          prompt: _prompt('Nom'),
        ),
        results: results,
      ),
    );
    await tester.pump();
    await tester.enterText(
      find.byKey(const ValueKey<String>('scene-interaction-text-field')),
      'Avelune',
    );
    await tester.testTextInput.receiveAction(TextInputAction.done);
    expect(results.single, isA<SceneTextSubmittedInteractionResult>());

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.confirmation(
          requestId: 'keyboard-confirmation',
          revision: 17,
          prompt: _prompt('Continuer ?'),
        ),
        results: results,
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(
      results.single,
      isA<SceneConfirmedInteractionResult>()
          .having((result) => result.value, 'value', isTrue),
    );

    results.clear();
    await tester.pumpWidget(
      _app(
        request: SceneInteractionRequest.selection(
          requestId: 'keyboard-selection',
          revision: 18,
          prompt: _prompt('Sélection'),
          options: <SceneInteractionOption>[_option('only', 'Unique')],
        ),
        results: results,
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(
      results.single,
      isA<SceneSelectionSubmittedInteractionResult>(),
    );
  });

  testWidgets('compact portrait and scaled text remain overflow-free',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(2)),
        child: _app(
          request: SceneInteractionRequest.choice(
            requestId: 'responsive',
            revision: 10,
            prompt: _prompt(
              'Une question volontairement longue pour le petit écran',
            ),
            options: <SceneInteractionOption>[
              _option('a', 'Une réponse elle aussi volontairement longue'),
              _option('b', 'Une autre réponse particulièrement bavarde'),
            ],
          ),
          results: <SceneInteractionResult>[],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey<String>('scene-interaction-panel')),
          )
          .width,
      lessThanOrEqualTo(390),
    );
  });
}

Widget _app({
  required SceneInteractionRequest request,
  required List<SceneInteractionResult> results,
}) =>
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: PlayerSceneInteractionSurface(
        request: request,
        onResult: results.add,
      ),
    );

SceneInteractionPrompt _prompt(String text) => SceneInteractionPrompt(
      localizationKey: 'test.prompt',
      fallbackText: text,
    );

SceneInteractionOption _option(String id, String label) =>
    SceneInteractionOption(id: id, label: _prompt(label));
