import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle AI action selection', () {
    test('switches away from a bad matchup when a reserve has pressure', () {
      final state = _state(
        opponent: _combatant(
          id: 'opponent-active',
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(id: 'tackle', type: 'normal', power: 80),
          ],
        ),
        player: _combatant(
          id: 'player',
          types: const PsdkBattleTypes(primary: 'ghost'),
        ),
        opponentParty: <PsdkBattleCombatant>[
          PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'opponent-active',
              types: const PsdkBattleTypes(primary: 'normal'),
              moves: <PsdkBattleMoveData>[
                _move(id: 'tackle', type: 'normal', power: 80),
              ],
            ),
          ),
          PsdkBattleCombatant.fromSetup(
            _combatant(
              id: 'opponent-reserve',
              types: const PsdkBattleTypes(primary: 'ghost'),
              moves: <PsdkBattleMoveData>[
                _move(id: 'shadow_claw', type: 'ghost', power: 70),
              ],
            ),
          ),
        ],
      );

      final decision = const PsdkBattleAi(canSwitch: true).chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(decision, isA<BattleSwitchDecision>());
      expect((decision as BattleSwitchDecision).partyIndex, 1);
    });

    test('uses a configured healing item when it is useful', () {
      final state = _state(
        opponent: _combatant(
          id: 'opponent',
          hp: 100,
          currentHp: 20,
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(id: 'scratch', type: 'normal', power: 40),
          ],
        ),
        player: _combatant(
          id: 'player',
          types: const PsdkBattleTypes(primary: 'normal'),
        ),
      );

      final decision = const PsdkBattleAi(
        canUseItem: true,
        itemOptions: <PsdkBattleAiItemOption>[
          PsdkBattleAiItemOption.hpHeal(
            itemId: 'super_potion',
            amount: 60,
          ),
        ],
      ).chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(decision, isA<BattleItemDecision>());
      final item = decision as BattleItemDecision;
      expect(item.itemId, 'super_potion');
      expect(item.target, psdkOpponentSlot);
    });

    test('flees when allowed and no useful pressure or switch exists', () {
      final state = _state(
        opponent: _combatant(
          id: 'opponent',
          types: const PsdkBattleTypes(primary: 'normal'),
          moves: <PsdkBattleMoveData>[
            _move(id: 'tackle', type: 'normal', power: 80),
          ],
        ),
        player: _combatant(
          id: 'player',
          types: const PsdkBattleTypes(primary: 'ghost'),
        ),
      );

      final decision = const PsdkBattleAi(canFlee: true).chooseDecision(
        state: state,
        user: psdkOpponentSlot,
        target: psdkPlayerSlot,
      );

      expect(decision, isA<BattleFleeDecision>());
    });
  });
}

PsdkBattleState _state({
  required PsdkBattleCombatantSetup opponent,
  required PsdkBattleCombatantSetup player,
  List<PsdkBattleCombatant>? opponentParty,
}) {
  final opponentBattler = PsdkBattleCombatant.fromSetup(opponent);
  final playerBattler = PsdkBattleCombatant.fromSetup(player);
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkOpponentSlot: opponentBattler,
      psdkPlayerSlot: playerBattler,
    },
    parties: <int, List<PsdkBattleCombatant>>{
      psdkOpponentSlot.bank:
          opponentParty ?? <PsdkBattleCombatant>[opponentBattler],
      psdkPlayerSlot.bank: <PsdkBattleCombatant>[playerBattler],
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  int hp = 100,
  int? currentHp,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: currentHp ?? hp,
    types: types,
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: moves ??
        <PsdkBattleMoveData>[_move(id: 'wait', type: 'normal', power: 0)],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: power <= 0
        ? PsdkBattleMoveCategory.status
        : PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 15,
    priority: 0,
    battleEngineMethod: power <= 0 ? 's_status' : 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
