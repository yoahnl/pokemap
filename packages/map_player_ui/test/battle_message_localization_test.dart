import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_player_ui/map_player_ui.dart';
import 'package:map_runtime/map_runtime.dart';

void main() {
  test('battle catalog uses the interface language and supplied names', () {
    expect(
      localizeRuntimeBattleMessage(
        'fr-CA',
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.moveUsed,
          'fallback',
          actor: 'Pousse',
          move: 'Charge',
        ),
      ),
      'Pousse utilise Charge !',
    );
    expect(
      localizeRuntimeBattleMessage(
        'en',
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.moveUsed,
          'fallback',
          actor: 'Sproutle',
          move: 'Tackle',
        ),
      ),
      'Sproutle used Tackle!',
    );
    expect(
      localizeRuntimeBattleMessage(
        'fr',
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.captureCaught,
          'fallback',
          target: 'Étincelle',
        ),
      ),
      'Étincelle est capturé !',
    );
    expect(
      localizeRuntimeBattleMessage(
        'en',
        const RuntimeBattleMessage(
          RuntimeBattleMessageId.postBattleItem,
          'fallback',
          item: 'Moon Stone',
          amount: 3,
        ),
      ),
      'You received Moon Stone ×3.',
    );
  });

  test('damage quantities and stat changes follow catalog grammar', () {
    const damage = RuntimeBattleMessage(
      RuntimeBattleMessageId.moveDamageSummary,
      'fallback',
      actor: 'Pip',
      move: 'Charge',
      amount: 1,
    );
    expect(
      localizeRuntimeBattleMessage('fr', damage),
      'Pip utilise Charge et inflige 1 dégât.',
    );
    expect(
      localizeRuntimeBattleMessage('es-MX', damage),
      'Pip used Charge and dealt 1 damage.',
    );

    const stat = RuntimeBattleMessage(
      RuntimeBattleMessageId.statLowered,
      'fallback',
      target: 'Pip',
      stat: BattleStatId.defense,
      amount: 2,
    );
    expect(
      localizeRuntimeBattleMessage('fr', stat),
      'La Défense de Pip baisse beaucoup !',
    );
    expect(
      localizeRuntimeBattleMessage('en', stat),
      'Pip’s Defense fell sharply!',
    );
  });

  testWidgets(
    'progression copy and choices fit a narrow phone after switching language',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      PostBattlePresentationCommand? command;

      Future<void> pump(String language, String move) {
        String render(RuntimeBattleMessage message) =>
            localizeRuntimeBattleMessage(language, message);
        return tester.pumpWidget(
          MaterialApp(
            locale: Locale(language),
            supportedLocales: PokeMapPlayerLocalizations.supportedLocales,
            localizationsDelegates:
                PokeMapPlayerLocalizations.localizationsDelegates,
            theme: PokeMapPlayerTheme.dark(),
            home: Scaffold(
              body: PlayerPostBattleOverlay(
                snapshot: PostBattlePresentationSnapshot(
                  revision: 12,
                  messageIndex: 0,
                  messageCount: 1,
                  messageKind: RuntimePostBattleMessageKind.moveLearningPrompt,
                  message: render(
                    RuntimeBattleMessage(
                      RuntimeBattleMessageId.postBattleMoveLearning,
                      'fallback',
                      target: 'Pip',
                      move: move,
                    ),
                  ),
                  choices: [
                    PostBattlePresentationChoice(
                      index: 0,
                      label: render(
                        const RuntimeBattleMessage(
                          RuntimeBattleMessageId.postBattleLearn,
                          'fallback',
                        ),
                      ),
                      selected: true,
                    ),
                    PostBattlePresentationChoice(
                      index: 1,
                      label: render(
                        const RuntimeBattleMessage(
                          RuntimeBattleMessageId.postBattleDeclineMove,
                          'fallback',
                        ),
                      ),
                      selected: false,
                    ),
                  ],
                  completed: false,
                  hasFailure: false,
                ),
                onCommand: (value) => command = value,
              ),
            ),
          ),
        );
      }

      await pump('fr', 'Vive-Attaque');
      await tester.pumpAndSettle();
      expect(find.text('Pip peut apprendre Vive-Attaque.'), findsOneWidget);
      await pump('en', 'Quick Attack');
      await tester.pumpAndSettle();
      expect(find.text('Pip can learn Quick Attack.'), findsOneWidget);
      await tester.tap(find.text('Don’t learn'));
      expect(
        command,
        isA<PostBattleSelectDecisionCommand>()
            .having((value) => value.snapshotRevision, 'revision', 12)
            .having((value) => value.decisionIndex, 'index', 1),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
