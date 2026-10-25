import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  testWidgets('renders progression and emits an exact decision', (
    tester,
  ) async {
    PostBattlePresentationCommand? command;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerPostBattleOverlay(
            snapshot: _snapshot(),
            onCommand: (value) => command = value,
          ),
        ),
      ),
    );

    expect(find.text('Pikachu veut apprendre Tonnerre.'), findsOneWidget);
    expect(find.text('3 / 4'), findsOneWidget);
    await tester.tap(find.text('Ne pas apprendre'));
    expect(
      command,
      isA<PostBattleSelectDecisionCommand>()
          .having((value) => value.snapshotRevision, 'revision', 15)
          .having((value) => value.decisionIndex, 'index', 1),
    );
  });

  testWidgets('result keeps actions reachable without an inner scroll', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(844, 390));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerPostBattleOverlay(
            snapshot: _snapshot(),
            onCommand: (_) {},
          ),
        ),
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(
      tester.getRect(find.byKey(const ValueKey('post-battle-choice-1'))).bottom,
      lessThanOrEqualTo(390),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('groups published rewards and preserves the required decision', (
    tester,
  ) async {
    PostBattlePresentationCommand? command;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerPostBattleOverlay(
            snapshot: _snapshot(
              summaryMessages: const [
                RuntimePostBattleMessage(
                  kind: RuntimePostBattleMessageKind.experience,
                  text: 'Compagnon gagne 84 EXP.',
                ),
                RuntimePostBattleMessage(
                  kind: RuntimePostBattleMessageKind.money,
                  text: 'Vous obtenez 120 pièces.',
                ),
              ],
            ),
            onCommand: (value) => command = value,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Compagnon gagne 84 EXP.'), findsOneWidget);
    expect(find.text('Vous obtenez 120 pièces.'), findsOneWidget);
    expect(find.text('Pikachu veut apprendre Tonnerre.'), findsOneWidget);
    expect(find.byKey(const ValueKey('post-battle-advance')), findsNothing);
    await tester.tap(find.byKey(const ValueKey('post-battle-choice-0')));
    expect(
      command,
      isA<PostBattleSelectDecisionCommand>().having(
        (command) => command.decisionIndex,
        'choice',
        0,
      ),
    );
    expect(find.byType(Scrollable), findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final viewport in const [Size(390, 844), Size(844, 390)]) {
    testWidgets('grouped result follows the reference bounds at $viewport', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(viewport);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await _pump(
        tester,
        _snapshot(
          summaryMessages: const [
            RuntimePostBattleMessage(
              kind: RuntimePostBattleMessageKind.experience,
              text: 'Compagnon gagne 84 EXP.',
            ),
            RuntimePostBattleMessage(
              kind: RuntimePostBattleMessageKind.money,
              text: 'Vous obtenez 120 pièces.',
            ),
          ],
        ),
      );
      final panel = tester.getRect(
        find.byKey(const ValueKey('post-battle-result-panel')),
      );
      if (viewport.width > viewport.height) {
        expect(panel.width, 400);
        expect(panel.right, viewport.width - 20);
        expect(panel.top, 20);
      } else {
        expect(panel.height, 460);
        expect(panel.bottom, viewport.height);
        expect(panel.width, viewport.width);
      }
      expect(find.text('Compagnon gagne 84 EXP.'), findsOneWidget);
      expect(find.text('Vous obtenez 120 pièces.'), findsOneWidget);
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets(
    'replacement choices preserve published indices and completed snapshots cannot submit',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(844, 390));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final commands = <PostBattlePresentationCommand>[];
      final choices = [
        for (final index in [7, 2, 9, 13, 5])
          PostBattlePresentationChoice(
            index: index,
            label: 'Choix $index',
            selected: index == 7,
          ),
      ];
      await _pump(tester, _snapshot(choices: choices), onCommand: commands.add);
      for (final index in [7, 2, 9, 13, 5]) {
        final choice = find.byKey(ValueKey('post-battle-choice-$index'));
        expect(tester.getSize(choice).height, greaterThanOrEqualTo(48));
        await tester.tap(choice);
        expect(
          (commands.last as PostBattleSelectDecisionCommand).decisionIndex,
          index,
        );
        expect(commands.last.snapshotRevision, 15);
      }
      expect(find.byType(Scrollable), findsNothing);
      expect(tester.takeException(), isNull);
      await _pump(
        tester,
        _snapshot(choices: choices, completed: true),
        onCommand: commands.add,
      );
      await tester.tap(
        find.byKey(const ValueKey('post-battle-choice-7')),
        warnIfMissed: false,
      );
      expect(commands, hasLength(5));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('error result is announced and acknowledged', (tester) async {
    PostBattlePresentationCommand? command;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('fr'),
        supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
        localizationsDelegates:
            PokeMapPlayerLocalizations.localizationsDelegates,
        theme: PokeMapPlayerTheme.dark(),
        home: Scaffold(
          body: PlayerPostBattleOverlay(
            snapshot: _snapshot(
              hasFailure: true,
              choices: const <PostBattlePresentationChoice>[],
            ),
            onCommand: (value) => command = value,
          ),
        ),
      ),
    );

    expect(find.text('Continuer'), findsOneWidget);
    await tester.tap(find.text('Continuer'));
    expect(command, isA<PostBattleAdvanceCommand>());
  });
}

PostBattlePresentationSnapshot _snapshot({
  bool hasFailure = false,
  bool completed = false,
  List<RuntimePostBattleMessage> summaryMessages = const [],
  List<PostBattlePresentationChoice>
  choices = const <PostBattlePresentationChoice>[
    PostBattlePresentationChoice(index: 0, label: 'Apprendre', selected: true),
    PostBattlePresentationChoice(
      index: 1,
      label: 'Ne pas apprendre',
      selected: false,
    ),
  ],
}) {
  return PostBattlePresentationSnapshot(
    revision: 15,
    summaryMessages: summaryMessages,
    messageIndex: 2,
    messageCount: 4,
    messageKind: hasFailure
        ? RuntimePostBattleMessageKind.error
        : RuntimePostBattleMessageKind.moveLearningPrompt,
    message: hasFailure
        ? 'La progression ne peut pas être appliquée.'
        : 'Pikachu veut apprendre Tonnerre.',
    choices: choices,
    completed: completed,
    hasFailure: hasFailure,
  );
}

Future<void> _pump(
  WidgetTester tester,
  PostBattlePresentationSnapshot snapshot, {
  ValueChanged<PostBattlePresentationCommand>? onCommand,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('fr'),
      supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
      localizationsDelegates: PokeMapPlayerLocalizations.localizationsDelegates,
      theme: PokeMapPlayerTheme.dark(),
      home: Scaffold(
        body: PlayerPostBattleOverlay(
          snapshot: snapshot,
          onCommand: onCommand ?? (_) {},
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
