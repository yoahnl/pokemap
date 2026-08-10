import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
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

  testWidgets('dialogue text consumes the semantic dialogue role',
      (tester) async {
    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      typography: const PokeMapPlayerTypography(
        dialogueFamily: 'Aube Dialogue',
      ),
      onCommand: (_) {},
    );

    expect(
      tester.widget<Text>(find.text('Bienvenue à PokeMap.')).style?.fontFamily,
      'Aube Dialogue',
    );
  });

  testWidgets('dialogue consumes its authored window geometry', (tester) async {
    final windows = legacyProjectPresentationWindows.copyWith(
      styles: legacyProjectPresentationWindows.styles
          .map(
            (style) => style.id == 'dialogue'
                ? style.copyWith(
                    cornerRadius: 8,
                    contentPadding: 12,
                    shadowElevation: 3,
                  )
                : style,
          )
          .toList(growable: false),
    );
    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      windows: windows,
      onCommand: (_) {},
    );

    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(PlayerPanel),
        matching: find.byType(Material),
      ),
    );
    final shape = material.shape! as RoundedRectangleBorder;
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(PlayerPanel),
        matching: find.byType(Padding),
      ),
    );
    expect(shape.borderRadius, BorderRadius.circular(8));
    expect(material.elevation, 3);
    expect(padding.padding, const EdgeInsets.all(12));
  });

  testWidgets('authored dialogue layout resolves top position and visibility', (
    tester,
  ) async {
    final base = suggestedProjectPresentationLayouts('standard');
    final layouts = base.copyWith(
      dialogue: base.dialogue.copyWith(
        regular: base.dialogue.regular.copyWith(
          slot: ProjectPresentationLayoutSlot.topCenter,
          visibleSecondaryElements: const <ProjectPresentationSecondaryElement>[],
        ),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      layouts: layouts,
      portraitBuilder: (_) => const SizedBox(
        key: ValueKey<String>('dialogue-portrait'),
      ),
      onCommand: (_) {},
    );

    expect(
      find.byKey(const ValueKey<String>('player-dialogue-responsive-regular')),
      findsOneWidget,
    );
    expect(
        find.byKey(const ValueKey<String>('dialogue-portrait')), findsNothing);
  });
}

Future<void> _pump(
  WidgetTester tester, {
  required DialoguePresentationSnapshot snapshot,
  required ValueChanged<DialoguePresentationCommand> onCommand,
  TextScaler textScaler = TextScaler.noScaling,
  PokeMapPlayerTypography? typography,
  ProjectPresentationWindowsProfile? windows,
  ProjectPresentationLayoutsProfile? layouts,
  Widget Function(String speaker)? portraitBuilder,
}) {
  var theme = typography == null
      ? PokeMapPlayerTheme.dark()
      : PokeMapPlayerTheme.withTypography(
          PokeMapPlayerTheme.dark(),
          typography,
        );
  if (windows != null) {
    theme = PokeMapPlayerTheme.withWindowProfile(theme, windows);
  }
  if (layouts != null) {
    theme = PokeMapPlayerTheme.withLayoutProfile(theme, layouts);
  }
  return tester
      .pumpWidget(
    MaterialApp(
      theme: theme,
      home: MediaQuery(
        data: MediaQueryData(textScaler: textScaler),
        child: Scaffold(
          body: PlayerDialogueOverlay(
            snapshot: snapshot,
            onCommand: onCommand,
            portraitBuilder: portraitBuilder,
          ),
        ),
      ),
    ),
  )
      .then((_) {
    expect(find.byType(PlayerDialogueSurface), findsOneWidget);
  });
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
