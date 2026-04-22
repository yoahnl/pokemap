import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_presentation.dart';

BattleStatsSnapshot _stats({
  int attack = 60,
  int defense = 60,
  int specialAttack = 60,
  int specialDefense = 60,
  int speed = 50,
}) {
  return BattleStatsSnapshot(
    attack: attack,
    defense: defense,
    specialAttack: specialAttack,
    specialDefense: specialDefense,
    speed: speed,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int maxHp = 40,
  int? currentHp,
  BattleStatsSnapshot? stats,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: stats ?? _stats(),
    moves: moves,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
  int power = 40,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: power,
    type: 'normal',
    category:
        power <= 0 ? BattleMoveCategory.status : BattleMoveCategory.physical,
    target: power <= 0 ? BattleMoveTarget.self : BattleMoveTarget.opponent,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  required BattleCombatantData enemy,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      enemyPokemon: enemy,
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

void main() {
  group('buildBattleTurnPresentationSteps', () {
    test('creates a damaging step with the target side and hp transition', () {
      final beforeSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 40,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'tackle',
            name: 'Tackle',
            power: 40,
            target: BattleMoveTarget.opponent,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              target: BattleMoveTarget.opponent,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 12,
            didHit: true,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                target: BattleMoveTarget.opponent,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 12,
              didHit: true,
            ),
          ),
        ],
      );

      final steps = buildBattleTurnPresentationSteps(
        playerBefore: beforeSession.state.player,
        enemyBefore: beforeSession.state.enemy,
        turnResult: turn,
      );

      expect(steps, hasLength(1));
      expect(steps.single.message, equals('Joueur utilise Tackle !'));
      expect(steps.single.flashTargetSide, equals(BattleSideId.enemy));
      expect(steps.single.hpFrom, equals(50));
      expect(steps.single.hpTo, equals(38));
      expect(steps.single.animatesDamage, isTrue);
    });

    test('tracks hp cumulatively across multiple damaging executions', () {
      final beforeSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          maxHp: 42,
          currentHp: 42,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'tackle',
            name: 'Tackle',
            power: 40,
            target: BattleMoveTarget.opponent,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionFight(
          BattleMove(
            id: 'scratch',
            name: 'Scratch',
            power: 35,
            target: BattleMoveTarget.opponent,
          ),
          moveIndex: 0,
        ),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'tackle',
              name: 'Tackle',
              power: 40,
              target: BattleMoveTarget.opponent,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            damage: 12,
            didHit: true,
          ),
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(
              id: 'scratch',
              name: 'Scratch',
              power: 35,
              target: BattleMoveTarget.opponent,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 9,
            didHit: true,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'tackle',
                name: 'Tackle',
                power: 40,
                target: BattleMoveTarget.opponent,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              damage: 12,
              didHit: true,
            ),
          ),
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
              move: BattleMove(
                id: 'scratch',
                name: 'Scratch',
                power: 35,
                target: BattleMoveTarget.opponent,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.player),
              damage: 9,
              didHit: true,
            ),
          ),
        ],
      );

      final steps = buildBattleTurnPresentationSteps(
        playerBefore: beforeSession.state.player,
        enemyBefore: beforeSession.state.enemy,
        turnResult: turn,
      );

      expect(steps, hasLength(2));
      expect(steps.first.hpFrom, equals(50));
      expect(steps.first.hpTo, equals(38));
      expect(steps.last.hpFrom, equals(42));
      expect(steps.last.hpTo, equals(33));
    });

    test(
        'renders potion use as a committed turn step before the enemy response',
        () {
      final beforeSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          maxHp: 40,
          currentHp: 12,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionBagHpHealItemUse(
          itemKind: BattleBagHpHealItemKind.potion,
          targetLineupIndex: 0,
          healAmount: 20,
        ),
        enemyAction: BattleActionFight(
          BattleMove(
            id: 'scratch',
            name: 'Scratch',
            power: 35,
            target: BattleMoveTarget.opponent,
          ),
          moveIndex: 0,
        ),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(
              id: 'scratch',
              name: 'Scratch',
              power: 35,
              target: BattleMoveTarget.opponent,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 9,
            didHit: true,
          ),
        ],
        bagHpHealItemEvents: <BattleBagHpHealItemEvent>[
          BattleBagHpHealItemEvent(
            itemKind: BattleBagHpHealItemKind.potion,
            side: BattleSideId.player,
            targetLineupIndex: 0,
            targetSpeciesId: 'sproutle',
            hpBefore: 12,
            hpAfter: 32,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnBagHpHealItemEvent(
            BattleBagHpHealItemEvent(
              itemKind: BattleBagHpHealItemKind.potion,
              side: BattleSideId.player,
              targetLineupIndex: 0,
              targetSpeciesId: 'sproutle',
              hpBefore: 12,
              hpAfter: 32,
            ),
          ),
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
              move: BattleMove(
                id: 'scratch',
                name: 'Scratch',
                power: 35,
                target: BattleMoveTarget.opponent,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.player),
              damage: 9,
              didHit: true,
            ),
          ),
        ],
      );

      final steps = buildBattleTurnPresentationSteps(
        playerBefore: beforeSession.state.player,
        enemyBefore: beforeSession.state.enemy,
        turnResult: turn,
      );

      expect(steps, hasLength(3));
      expect(steps[0].message, equals('Joueur utilise Potion sur sproutle !'));
      expect(steps[0].animatesDamage, isFalse);
      expect(steps[1].message, equals('sproutle récupère 20 PV.'));
      expect(steps[1].animatesHpChange, isTrue);
      expect(steps[1].flashTargetSide, isNull);
      expect(steps[1].hpFrom, equals(12));
      expect(steps[1].hpTo, equals(32));
      expect(steps[2].message, equals('Ennemi utilise Scratch !'));
      expect(steps[2].hpFrom, equals(32));
      expect(steps[2].hpTo, equals(23));
    });

    test(
        'renders super potion use as a committed turn step before the enemy response',
        () {
      final beforeSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          maxHp: 80,
          currentHp: 12,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionBagHpHealItemUse(
          itemKind: BattleBagHpHealItemKind.superPotion,
          targetLineupIndex: 0,
          healAmount: 50,
        ),
        enemyAction: BattleActionFight(
          BattleMove(
            id: 'scratch',
            name: 'Scratch',
            power: 35,
            target: BattleMoveTarget.opponent,
          ),
          moveIndex: 0,
        ),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(
              id: 'scratch',
              name: 'Scratch',
              power: 35,
              target: BattleMoveTarget.opponent,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 9,
            didHit: true,
          ),
        ],
        bagHpHealItemEvents: <BattleBagHpHealItemEvent>[
          BattleBagHpHealItemEvent(
            itemKind: BattleBagHpHealItemKind.superPotion,
            side: BattleSideId.player,
            targetLineupIndex: 0,
            targetSpeciesId: 'sproutle',
            hpBefore: 12,
            hpAfter: 62,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnBagHpHealItemEvent(
            BattleBagHpHealItemEvent(
              itemKind: BattleBagHpHealItemKind.superPotion,
              side: BattleSideId.player,
              targetLineupIndex: 0,
              targetSpeciesId: 'sproutle',
              hpBefore: 12,
              hpAfter: 62,
            ),
          ),
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
              move: BattleMove(
                id: 'scratch',
                name: 'Scratch',
                power: 35,
                target: BattleMoveTarget.opponent,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.player),
              damage: 9,
              didHit: true,
            ),
          ),
        ],
      );

      final steps = buildBattleTurnPresentationSteps(
        playerBefore: beforeSession.state.player,
        enemyBefore: beforeSession.state.enemy,
        turnResult: turn,
      );

      expect(steps, hasLength(3));
      expect(
        steps[0].message,
        equals('Joueur utilise Super Potion sur sproutle !'),
      );
      expect(steps[1].message, equals('sproutle récupère 50 PV.'));
      expect(steps[1].hpFrom, equals(12));
      expect(steps[1].hpTo, equals(62));
      expect(steps[2].hpFrom, equals(62));
      expect(steps[2].hpTo, equals(53));
    });

    test(
        'renders hyper potion use as a committed turn step before the enemy response',
        () {
      final beforeSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          maxHp: 260,
          currentHp: 12,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionBagHpHealItemUse(
          itemKind: BattleBagHpHealItemKind.hyperPotion,
          targetLineupIndex: 0,
          healAmount: 200,
        ),
        enemyAction: BattleActionFight(
          BattleMove(
            id: 'scratch',
            name: 'Scratch',
            power: 35,
            target: BattleMoveTarget.opponent,
          ),
          moveIndex: 0,
        ),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
            move: BattleMove(
              id: 'scratch',
              name: 'Scratch',
              power: 35,
              target: BattleMoveTarget.opponent,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 9,
            didHit: true,
          ),
        ],
        bagHpHealItemEvents: <BattleBagHpHealItemEvent>[
          BattleBagHpHealItemEvent(
            itemKind: BattleBagHpHealItemKind.hyperPotion,
            side: BattleSideId.player,
            targetLineupIndex: 0,
            targetSpeciesId: 'sproutle',
            hpBefore: 12,
            hpAfter: 212,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnBagHpHealItemEvent(
            BattleBagHpHealItemEvent(
              itemKind: BattleBagHpHealItemKind.hyperPotion,
              side: BattleSideId.player,
              targetLineupIndex: 0,
              targetSpeciesId: 'sproutle',
              hpBefore: 12,
              hpAfter: 212,
            ),
          ),
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
              move: BattleMove(
                id: 'scratch',
                name: 'Scratch',
                power: 35,
                target: BattleMoveTarget.opponent,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.player),
              damage: 9,
              didHit: true,
            ),
          ),
        ],
      );

      final steps = buildBattleTurnPresentationSteps(
        playerBefore: beforeSession.state.player,
        enemyBefore: beforeSession.state.enemy,
        turnResult: turn,
      );

      expect(steps, hasLength(3));
      expect(
        steps[0].message,
        equals('Joueur utilise Hyper Potion sur sproutle !'),
      );
      expect(steps[1].message, equals('sproutle récupère 200 PV.'));
      expect(steps[1].hpFrom, equals(12));
      expect(steps[1].hpTo, equals(212));
      expect(steps[2].hpFrom, equals(212));
      expect(steps[2].hpTo, equals(203));
    });

    test('keeps status-like executions as message-only steps', () {
      final beforeSession = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'wait', name: 'Wait', power: 0)],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'wait',
            name: 'Wait',
            power: 0,
            category: BattleMoveCategory.status,
            target: BattleMoveTarget.self,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[
          BattleMoveExecution(
            attackerSlot: BattleSlotRef.active(BattleSideId.player),
            move: BattleMove(
              id: 'wait',
              name: 'Wait',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
            ),
            targetKind: BattleMoveExecutionTargetKind.combatant,
            targetSlot: BattleSlotRef.active(BattleSideId.player),
            damage: 0,
            didHit: true,
          ),
        ],
        timeline: <BattleTurnEvent>[
          BattleTurnExecutionEvent(
            BattleMoveExecution(
              attackerSlot: BattleSlotRef.active(BattleSideId.player),
              move: BattleMove(
                id: 'wait',
                name: 'Wait',
                power: 0,
                category: BattleMoveCategory.status,
                target: BattleMoveTarget.self,
              ),
              targetKind: BattleMoveExecutionTargetKind.combatant,
              targetSlot: BattleSlotRef.active(BattleSideId.player),
              damage: 0,
              didHit: true,
            ),
          ),
        ],
      );

      final steps = buildBattleTurnPresentationSteps(
        playerBefore: beforeSession.state.player,
        enemyBefore: beforeSession.state.enemy,
        turnResult: turn,
      );

      expect(steps, hasLength(1));
      expect(steps.single.message, equals('Joueur utilise Wait !'));
      expect(steps.single.animatesDamage, isFalse);
      expect(steps.single.flashTargetSide, isNull);
      expect(steps.single.hpFrom, isNull);
      expect(steps.single.hpTo, isNull);
    });
  });
}
