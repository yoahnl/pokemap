import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('renders speaker and advances the current revision',
      (tester) async {
    DialoguePresentationCommand? command;
    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      onCommand: (value) => command = value,
    );

    expect(find.text('Lysa'), findsOneWidget);
    expect(find.text('Bienvenue à PokeMap.'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey<String>('dialogue-tap-zone')));
    expect(
      command,
      isA<DialogueAdvanceCommand>().having(
        (value) => value.snapshotRevision,
        'revision',
        4,
      ),
    );
  });

  testWidgets('choices are direct, focusable commands and scale safely',
      (tester) async {
    DialoguePresentationCommand? command;
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      snapshot: _choiceSnapshot(),
      textScaler: const TextScaler.linear(1.8),
      onCommand: (value) => command = value,
    );

    await tester.tap(find.text('Prendre Bulbizarre'));
    expect(
      command,
      isA<DialogueSelectChoiceCommand>()
          .having((value) => value.snapshotRevision, 'revision', 12)
          .having((value) => value.choiceIndex, 'index', 1),
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required DialoguePresentationSnapshot snapshot,
  required ValueChanged<DialoguePresentationCommand> onCommand,
  TextScaler textScaler = TextScaler.noScaling,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: PokeMapPlayerTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: snapshot,
            onCommand: onCommand,
          ),
        ),
      ),
    ),
  );
}

DialoguePresentationSnapshot _lineSnapshot() {
  return const DialoguePresentationSnapshot(
    revision: 4,
    mode: DialoguePresentationMode.line,
    nodeTitle: 'intro',
    speaker: 'Lysa',
    text: 'Bienvenue à PokeMap.',
    fullText: 'Bienvenue à PokeMap.',
    isCurrentLineFullyRevealed: true,
    isLastContent: false,
    choices: <DialoguePresentationChoice>[],
  );
}

DialoguePresentationSnapshot _choiceSnapshot() {
  return const DialoguePresentationSnapshot(
    revision: 12,
    mode: DialoguePresentationMode.choices,
    nodeTitle: 'starter',
    speaker: null,
    text: '',
    fullText: '',
    isCurrentLineFullyRevealed: true,
    isLastContent: false,
    choices: <DialoguePresentationChoice>[
      DialoguePresentationChoice(
        index: 0,
        label: 'Prendre Salamèche',
        selected: true,
      ),
      DialoguePresentationChoice(
        index: 1,
        label: 'Prendre Bulbizarre',
        selected: false,
      ),
    ],
  );
}
