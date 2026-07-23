import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:pokemap_loader/src/in_game_heal_flow.dart';

void main() {
  testWidgets('heals HP status and PP and confirms completion', (tester) async {
    var committed = const GameState(
      saveId: 'heal-ui',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            knownMoveIds: <String>['tackle'],
            currentPpByMoveId: <String, int>{'tackle': 1},
            currentHp: 0,
            statusId: 'poison',
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGameHealFlow(
          gameState: committed,
          recoveryCaps: const PlayerServiceRecoveryCaps(
            maxHpByPartyIndex: <int, int>{0: 25},
            maxPpByPartyIndex: <int, Map<String, int>>{
              0: <String, int>{'tackle': 35},
            },
          ),
          onStateCommitted: (state) async => committed = state,
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('heal-party-button')));
    await tester.pumpAndSettle();

    expect(committed.party.members.single.currentHp, 25);
    expect(committed.party.members.single.statusId, isEmpty);
    expect(
      committed.party.members.single.currentPpByMoveId,
      const <String, int>{'tackle': 35},
    );
    expect(
        find.textContaining('équipe est entièrement soignée'), findsOneWidget);
  });

  testWidgets('does not publish a partial state when commit fails',
      (tester) async {
    const initial = GameState(
      saveId: 'heal-failure-ui',
      party: PlayerParty(
        members: <PlayerPokemon>[
          PlayerPokemon(
            speciesId: 'sproutle',
            natureId: 'hardy',
            abilityId: 'overgrow',
            currentHp: 1,
          ),
        ],
      ),
    );
    await tester.pumpWidget(
      MaterialApp(
        home: InGameHealFlow(
          gameState: initial,
          recoveryCaps: const PlayerServiceRecoveryCaps(
            maxHpByPartyIndex: <int, int>{0: 25},
          ),
          onStateCommitted: (_) => Future<void>.error(StateError('disk')),
        ),
      ),
    );

    await tester.tap(find.byKey(const Key('heal-party-button')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Échec du soin'), findsOneWidget);
    expect(find.text('PV 1'), findsOneWidget);
  });
}
