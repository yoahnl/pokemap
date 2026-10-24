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
    completed: false,
    hasFailure: hasFailure,
  );
}
