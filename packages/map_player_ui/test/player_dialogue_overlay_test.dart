import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('Ligue dialogue preserves an authored surface palette', (
    tester,
  ) async {
    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      palettes: const ProjectPresentationSurfacePalettesProfile(
        dialogue: ProjectSurfacePaletteProfile(
          surface: '#102030',
          text: '#F0F0F0',
          accent: '#90A0B0',
        ),
      ),
      onCommand: (_) {},
    );
    final panel = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('player-dialogue-ligue-panel')),
    );
    final decoration = panel.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFF102030));
    expect((decoration.border! as Border).left.color, const Color(0xFF90A0B0));
    final body = tester.widget<Text>(
      find.byKey(const ValueKey('dialogue-page-text')),
    );
    expect(body.style?.color, const Color(0xFFF0F0F0));
  });

  testWidgets('long choice questions paginate without advancing the runtime', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final commands = <DialoguePresentationCommand>[];
    final text = 'Prépare ton équipe avant de traverser la forêt. ' * 20;
    await _pump(
      tester,
      snapshot: DialoguePresentationSnapshot(
        revision: 31,
        mode: DialoguePresentationMode.choices,
        nodeTitle: 'route',
        speaker: 'Léa',
        text: text,
        fullText: text,
        isCurrentLineFullyRevealed: true,
        isLastContent: false,
        choices: const [
          DialoguePresentationChoice(index: 0, label: 'Forêt', selected: true),
          DialoguePresentationChoice(
            index: 1,
            label: 'Rivière',
            selected: false,
          ),
        ],
      ),
      onCommand: commands.add,
    );
    final chunks = <String>[];
    for (var page = 0; page < 80; page++) {
      chunks.add(
        tester
            .widget<Text>(find.byKey(const ValueKey('dialogue-page-text')))
            .textSpan!
            .toPlainText(),
      );
      final next = find.byKey(const ValueKey('dialogue-question-next'));
      if (next.evaluate().isEmpty ||
          tester.widget<IconButton>(next).onPressed == null) {
        break;
      }
      await tester.tap(next);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(chunks.length, greaterThan(1));
    expect(chunks.join(), text);
    expect(commands, isEmpty);
    expect(find.byType(Scrollable), findsNothing);
    await tester.tap(find.byKey(const ValueKey('dialogue-choice-1')));
    expect(
      commands.single,
      isA<DialogueSelectChoiceCommand>().having(
        (value) => value.snapshotRevision,
        'revision',
        31,
      ),
    );
  });

  for (final size in [
    const Size(390, 844),
    const Size(844, 390),
    const Size(768, 432),
  ]) {
    testWidgets(
      'runtime choices retain their question and canonical command at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        DialoguePresentationCommand? command;
        const question =
            'Le sentier traverse la forêt. Quelle route veux-tu prendre ?';
        await _pump(
          tester,
          snapshot: const DialoguePresentationSnapshot(
            revision: 17,
            mode: DialoguePresentationMode.choices,
            nodeTitle: 'route',
            speaker: 'Léa',
            text: question,
            fullText: question,
            isCurrentLineFullyRevealed: true,
            isLastContent: false,
            choices: [
              DialoguePresentationChoice(
                index: 0,
                label: 'Traverser la forêt',
                selected: true,
              ),
              DialoguePresentationChoice(
                index: 1,
                label: 'Suivre la rivière',
                selected: false,
              ),
            ],
          ),
          onCommand: (value) => command = value,
        );
        await tester.pumpAndSettle();
        expect(find.text('Léa'), findsOneWidget);
        final prompt = find.byKey(const ValueKey('dialogue-page-text'));
        expect(tester.widget<Text>(prompt).textSpan!.toPlainText(), question);
        final first = find.byKey(const ValueKey('dialogue-choice-0'));
        final second = find.byKey(const ValueKey('dialogue-choice-1'));
        expect(first.hitTestable(), findsOneWidget);
        expect(second.hitTestable(), findsOneWidget);
        expect(tester.getSize(first).height, greaterThanOrEqualTo(48));
        if (size.width >= 600) {
          expect(
            tester.getRect(first).top,
            closeTo(tester.getRect(second).top, .1),
          );
          expect(
            tester.getRect(second).left - tester.getRect(first).right,
            greaterThanOrEqualTo(8),
          );
          expect(
            tester.getRect(prompt).bottom,
            lessThanOrEqualTo(tester.getRect(first).top - 8),
          );
        } else {
          expect(
            tester.getRect(second).top - tester.getRect(first).bottom,
            greaterThanOrEqualTo(8),
          );
        }
        expect(find.byType(Scrollable), findsNothing);
        await tester.tap(second);
        await tester.pump();
        expect(
          command,
          isA<DialogueSelectChoiceCommand>()
              .having((value) => value.snapshotRevision, 'revision', 17)
              .having((value) => value.choiceIndex, 'choice', 1),
        );
        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets(
    'EV04 ten choices keep the keyboard selection visible in a small viewport',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      DialoguePresentationSnapshot snapshot(int selected) =>
          DialoguePresentationSnapshot(
            revision: selected + 1,
            mode: DialoguePresentationMode.choices,
            nodeTitle: 'Start',
            speaker: null,
            text: '',
            fullText: '',
            isCurrentLineFullyRevealed: true,
            isLastContent: false,
            choices: [
              for (var i = 0; i < 10; i++)
                DialoguePresentationChoice(
                  index: i,
                  label: 'Destination $i',
                  selected: i == selected,
                ),
            ],
          );
      DialoguePresentationCommand? command;
      await _pump(
        tester,
        snapshot: snapshot(0),
        onCommand: (value) => command = value,
      );
      await tester.pumpAndSettle();
      await _pump(
        tester,
        snapshot: snapshot(9),
        onCommand: (value) => command = value,
      );
      await tester.pumpAndSettle();
      final last = find.byKey(const ValueKey<String>('dialogue-choice-9'));
      expect(tester.getRect(last).top, greaterThanOrEqualTo(0));
      expect(tester.getRect(last).bottom, lessThanOrEqualTo(568));
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(
        command,
        isA<DialogueSelectChoiceCommand>().having(
          (value) => value.choiceIndex,
          'choice',
          9,
        ),
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'revealing letters keeps the dialogue opaque and commands current',
    (tester) async {
      DialoguePresentationCommand? command;
      for (var revision = 1; revision <= 8; revision++) {
        final text = 'Bonjour !'.substring(0, revision);
        await _pump(
          tester,
          snapshot: DialoguePresentationSnapshot(
            revision: revision,
            mode: DialoguePresentationMode.line,
            nodeTitle: 'intro',
            speaker: 'Lysa',
            text: text,
            fullText: 'Bonjour !',
            isCurrentLineFullyRevealed: false,
            isLastContent: false,
            choices: const [],
          ),
          onCommand: (value) => command = value,
        );
        await tester.pump(const Duration(milliseconds: 30));
        expect(find.text('Lysa'), findsOneWidget);
        for (final fade in tester.widgetList<FadeTransition>(
          find.ancestor(
            of: find.text(text),
            matching: find.byType(FadeTransition),
          ),
        )) {
          expect(fade.opacity.value, 1.0);
        }
      }
      await tester.tap(find.byKey(const ValueKey<String>('dialogue-tap-zone')));
      expect(
        command,
        isA<DialogueAdvanceCommand>().having(
          (value) => value.snapshotRevision,
          'revision',
          8,
        ),
      );
    },
  );

  testWidgets('renders speaker and advances the current revision', (
    tester,
  ) async {
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

  testWidgets('choices are direct, focusable commands and scale safely', (
    tester,
  ) async {
    DialoguePresentationCommand? command;
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      snapshot: _choiceSnapshot(),
      textScaler: const TextScaler.linear(1.8),
      onCommand: (value) => command = value,
    );

    while (find.text('Prendre Bulbizarre').evaluate().isEmpty) {
      await tester.tap(find.byKey(const ValueKey('player-page-next')));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Prendre Bulbizarre'));
    expect(
      command,
      isA<DialogueSelectChoiceCommand>()
          .having((value) => value.snapshotRevision, 'revision', 12)
          .having((value) => value.choiceIndex, 'index', 1),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('dialogue text consumes the semantic dialogue role', (
    tester,
  ) async {
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
          visibleSecondaryElements:
              const <ProjectPresentationSecondaryElement>[],
        ),
      ),
    );
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      layouts: layouts,
      portraitBuilder: (_) =>
          const SizedBox(key: ValueKey<String>('dialogue-portrait')),
      onCommand: (_) {},
    );

    expect(
      find.byKey(const ValueKey<String>('player-dialogue-responsive-regular')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dialogue-portrait')),
      findsNothing,
    );
  });

  testWidgets('V9 dialogue geometry overrides every legacy surface measure', (
    tester,
  ) async {
    const dialogue = ProjectDialoguePresentationProfile(
      placement: ProjectDialoguePlacement.top,
      maxWidthFactor: .64,
      margin: 20,
      contentPadding: 24,
      shape: ProjectWindowShape.speech,
      cornerRadius: 18,
      borderWidth: 3,
      fillOpacity: .82,
      surfaceColor: '#102030',
      borderColor: '#A0B0C0',
      textColor: '#F0F0F0',
    );
    await tester.binding.setSurfaceSize(const Size(1000, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _pump(
      tester,
      snapshot: _lineSnapshot(),
      dialogue: dialogue,
      onCommand: (_) {},
    );

    final align = tester.widget<Align>(
      find.byKey(const ValueKey<String>('player-dialogue-authored-bubble')),
    );
    final constrained = tester.widget<ConstrainedBox>(
      find
          .descendant(
            of: find.byKey(
              const ValueKey<String>('player-dialogue-authored-bubble'),
            ),
            matching: find.byType(ConstrainedBox),
          )
          .first,
    );
    final material = tester.widget<Material>(
      find.descendant(
        of: find.byType(PlayerPanel),
        matching: find.byType(Material),
      ),
    );
    final padding = tester.widget<Padding>(
      find.descendant(
        of: find.byType(PlayerPanel),
        matching: find.byType(Padding),
      ),
    );

    expect(align.alignment, Alignment.topCenter);
    expect(constrained.constraints.maxWidth, 640);
    expect(material.color, const Color(0xFF102030).withValues(alpha: .82));
    expect(material.shape?.dimensions.resolve(TextDirection.ltr).bottom, 13);
    expect(padding.padding, const EdgeInsets.all(24));
    expect(
      tester.widget<Text>(find.text('Bienvenue à PokeMap.')).style?.color,
      const Color(0xFFF0F0F0),
    );
  });

  for (final count in <int>[2, 4, 8]) {
    testWidgets('styles $count dialogue choices including disabled state', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final snapshot = _choiceSnapshotForCount(count);
      await _pump(
        tester,
        snapshot: snapshot,
        textScaler: const TextScaler.linear(1.5),
        dialogue: const ProjectDialoguePresentationProfile(
          choiceSpacing: 14,
          choiceShape: ProjectDialogueChoiceShape.cutCorner,
          choiceDisabledOpacity: .35,
          choiceSelectedColor: '#FFAA00',
        ),
        onCommand: (_) {},
      );

      expect(
        find.byType(PlayerActionButton, skipOffstage: false),
        findsNWidgets(count),
      );
      final selected = tester.widget<PlayerActionButton>(
        find.byKey(const ValueKey<String>('dialogue-choice-0')),
      );
      final disabled = tester.widget<PlayerActionButton>(
        find.byKey(
          const ValueKey<String>('dialogue-choice-1'),
          skipOffstage: false,
        ),
      );
      expect(selected.selected, isTrue);
      expect(selected.shape, isA<BeveledRectangleBorder>());
      expect(selected.backgroundColor, const Color(0xFFFFAA00));
      expect(disabled.onPressed, isNull);
      expect(disabled.disabledOpacity, .35);
      expect(
        tester.widget<PlayerPagedList>(find.byType(PlayerPagedList)).spacing,
        14,
      );
      expect(tester.takeException(), isNull);
    });
  }

  for (final indicator in ProjectDialogueProgressIndicator.values) {
    testWidgets('renders the ${indicator.name} dialogue progress indicator', (
      tester,
    ) async {
      await _pump(
        tester,
        snapshot: _lineSnapshot(),
        dialogue: ProjectDialoguePresentationProfile(
          progressIndicator: indicator,
          progressIndicatorColor: '#00FFAA',
        ),
        onCommand: (_) {},
      );

      expect(
        find.byKey(
          ValueKey<String>('dialogue-progress-indicator-${indicator.name}'),
        ),
        findsOneWidget,
      );
      if (indicator != ProjectDialogueProgressIndicator.none) {
        expect(
          tester
              .widget<Icon>(
                find.byKey(
                  ValueKey<String>(
                    'dialogue-progress-indicator-${indicator.name}',
                  ),
                ),
              )
              .color,
          const Color(0xFF00FFAA),
        );
      }
    });
  }
}

Future<void> _pump(
  WidgetTester tester, {
  required DialoguePresentationSnapshot snapshot,
  required ValueChanged<DialoguePresentationCommand> onCommand,
  TextScaler textScaler = TextScaler.noScaling,
  PokeMapPlayerTypography? typography,
  ProjectPresentationWindowsProfile? windows,
  ProjectPresentationSurfacePalettesProfile? palettes,
  ProjectPresentationLayoutsProfile? layouts,
  ProjectDialoguePresentationProfile? dialogue,
  Widget Function(String speaker)? portraitBuilder,
  bool reducedMotion = false,
}) {
  var theme = typography == null
      ? PokeMapPlayerTheme.dark(reducedMotion: reducedMotion)
      : PokeMapPlayerTheme.withTypography(
          PokeMapPlayerTheme.dark(reducedMotion: reducedMotion),
          typography,
        );
  if (palettes != null) {
    theme = PokeMapPlayerTheme.withSurfacePalettes(theme, palettes);
  }
  if (windows != null) {
    theme = PokeMapPlayerTheme.withWindowProfile(theme, windows);
  }
  if (layouts != null) {
    theme = PokeMapPlayerTheme.withLayoutProfile(theme, layouts);
  }
  if (dialogue != null) {
    theme = PokeMapPlayerTheme.withDialogueProfile(theme, dialogue);
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
      .then((_) async {
        await tester.pumpAndSettle();
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

DialoguePresentationSnapshot _choiceSnapshotForCount(int count) {
  return DialoguePresentationSnapshot(
    revision: 18,
    mode: DialoguePresentationMode.choices,
    nodeTitle: 'many-choices',
    speaker: null,
    text: '',
    fullText: '',
    isCurrentLineFullyRevealed: true,
    isLastContent: false,
    choices: <DialoguePresentationChoice>[
      for (var index = 0; index < count; index++)
        DialoguePresentationChoice(
          index: index,
          label: 'Option ${index + 1} avec un libellé volontairement très long',
          selected: index == 0,
          enabled: index != 1,
        ),
    ],
  );
}
