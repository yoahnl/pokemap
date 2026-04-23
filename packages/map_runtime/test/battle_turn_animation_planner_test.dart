import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

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
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: moves,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
  required String type,
  int power = 40,
  BattleMoveCategory category = BattleMoveCategory.physical,
  BattleMoveTarget target = BattleMoveTarget.opponent,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: power,
    type: type,
    category: category,
    target: target,
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

BattleMoveVisualResolver _resolver() {
  return BattleMoveVisualResolver(
    RuntimeMoveCatalog.fromEntries(<String, PokemonMove>{
      'tackle': PokemonMove(
        id: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        accuracy: const PokemonMoveAccuracy.percent(value: 100),
        sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: 'tackle'),
      ),
      'raindance': PokemonMove(
        id: 'raindance',
        name: 'Rain Dance',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        accuracy: const PokemonMoveAccuracy.alwaysHits(),
        effects: const <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(weatherId: 'rain'),
        ],
        sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: 'raindance'),
      ),
      'stealthrock': PokemonMove(
        id: 'stealthrock',
        name: 'Stealth Rock',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        accuracy: const PokemonMoveAccuracy.alwaysHits(),
        effects: const <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
        ],
        sourceRefs: const PokemonMoveSourceRefs(showdownMoveId: 'stealthrock'),
      ),
    }),
  );
}

void main() {
  group('BattleTurnAnimationPlanner', () {
    test('build returns empty plan when currentTurn is null', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle', type: 'normal')
          ],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.build(
        previousSession: session,
        newSession: session,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(plan.isEmpty, isTrue);
    });

    test('execution with damage produces recipe and hp tween', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 40,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle', type: 'normal')
          ],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          maxHp: 50,
          currentHp: 50,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
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
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: turn,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(plan.steps.whereType<ShowMessageStep>(), isNotEmpty);
      expect(plan.steps.whereType<HudHpTweenStep>(), hasLength(1));
      expect(plan.steps.whereType<CombatantMotionStep>(), isNotEmpty);
      expect(plan.steps.whereType<CombatantFlashStep>(), isNotEmpty);
    });

    test('switch event produces switchOut swap switchIn', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle', type: 'normal')
          ],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionSwitch(reserveIndex: 0),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[],
        timeline: <BattleTurnEvent>[
          BattleTurnSwitchEvent(
            BattleSwitchEvent.switched(
              side: BattleSideId.player,
              fromSpeciesId: 'sproutle',
              toSpeciesId: 'aquaffe',
              wasForced: false,
            ),
          ),
        ],
      );
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: turn,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(plan.steps.whereType<CombatantMotionStep>(), hasLength(2));
      expect(plan.steps.whereType<SwapCombatantVisualStep>(), hasLength(1));
    });

    test('field event produces screen effect', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(
              id: 'raindance',
              name: 'Rain Dance',
              type: 'water',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.self,
            )
          ],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'raindance',
            name: 'Rain Dance',
            power: 0,
            target: BattleMoveTarget.field,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[],
        timeline: <BattleTurnEvent>[
          BattleTurnFieldEvent(
            BattleFieldEvent.weatherSet(
              weather: BattleWeatherId.rain,
              sourceMoveId: 'raindance',
            ),
          ),
        ],
      );
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: turn,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(plan.steps.whereType<ScreenFlashStep>(), isNotEmpty);
    });

    test('stealth rock set produces hazard recipe', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(
              id: 'stealthrock',
              name: 'Stealth Rock',
              type: 'rock',
              power: 0,
              category: BattleMoveCategory.status,
              target: BattleMoveTarget.opponentSide,
            )
          ],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionFight(
          BattleMove(
            id: 'stealthrock',
            name: 'Stealth Rock',
            power: 0,
            target: BattleMoveTarget.opponentSide,
            setsStealthRock: true,
          ),
          moveIndex: 0,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[],
        timeline: <BattleTurnEvent>[
          BattleTurnStealthRockEvent(
            BattleStealthRockEvent.set(
              side: BattleSideId.enemy,
              sourceMoveId: 'stealthrock',
            ),
          ),
        ],
      );
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: turn,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(plan.requiredFxIds, isNotEmpty);
      expect(plan.steps.whereType<SpawnFxStep>(), isNotEmpty);
    });

    test('unsupported event degrades to message-only', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle', type: 'normal')
          ],
        ),
        enemy: _combatant(
          speciesId: 'sparkitten',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionNone(),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[],
        timeline: <BattleTurnEvent>[
          BattleTurnVolatileEvent(
            BattleVolatileEvent.protectBroken(
              actorSlot: BattleSlotRef.active(BattleSideId.player),
              targetSlot: BattleSlotRef.active(BattleSideId.enemy),
              sourceMoveId: 'feint',
            ),
          ),
        ],
      );
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: turn,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(plan.steps.whereType<ShowMessageStep>(), isNotEmpty);
      expect(plan.steps.whereType<SpawnFxStep>(), isEmpty);
    });
  });
}
