import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_sdk_rmxp_animation_catalog.dart';
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
    BattleSetup.pokeMapBetaV1ForTest(
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
      'tackle': const PokemonMove(
        id: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PokemonMoveCategory.physical,
        accuracy: PokemonMoveAccuracy.percent(value: 100),
        sourceRefs: PokemonMoveSourceRefs(showdownMoveId: 'tackle'),
      ),
      'raindance': const PokemonMove(
        id: 'raindance',
        name: 'Rain Dance',
        type: 'water',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.self,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setWeather(weatherId: 'rain'),
        ],
        sourceRefs: PokemonMoveSourceRefs(showdownMoveId: 'raindance'),
      ),
      'stealthrock': const PokemonMove(
        id: 'stealthrock',
        name: 'Stealth Rock',
        type: 'rock',
        category: PokemonMoveCategory.status,
        target: PokemonMoveTarget.foeSide,
        accuracy: PokemonMoveAccuracy.alwaysHits(),
        effects: <PokemonMoveEffect>[
          PokemonMoveEffect.setSideCondition(conditionId: 'stealthrock'),
        ],
        sourceRefs: PokemonMoveSourceRefs(showdownMoveId: 'stealthrock'),
      ),
    }),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(BattleSdkRmxpAnimationCatalog.ensureLoaded);

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


    test('a failed capture plays exactly the transmitted shake count', () {
      // ENC-005 : deux secousses décidées par la formule -> deux
      // CombatantShakeStep entre le lancer et le verdict. Un planner qui
      // dériverait la séquence de `caught` en jouerait zéro et casserait ici.
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
      const event = BattleCaptureAttemptEvent(
        attemptId: 'capture-attempt-1',
        targetSpeciesId: 'sparkitten',
        ballId: canonicalPokeBallItemId,
        caught: false,
        shakes: 2,
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionCapture(
          attemptId: 'capture-attempt-1',
          itemId: canonicalPokeBallItemId,
          caught: false,
          shakes: 2,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[],
        captureAttemptEvents: <BattleCaptureAttemptEvent>[event],
        timeline: <BattleTurnEvent>[BattleTurnCaptureAttemptEvent(event)],
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

      final steps = plan.steps;
      expect(steps.whereType<CombatantShakeStep>(), hasLength(2));
      final messages = steps
          .whereType<ShowMessageStep>()
          .map((step) => step.message)
          .toList(growable: false);
      expect(messages.first, contains('est lancée'));
      expect(messages.last, contains('s’échappe'));
      final throwIndex = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('lancée'),
      );
      final verdictIndex = steps.indexWhere(
        (step) => step is ShowMessageStep && step.message.contains('échappe'),
      );
      for (final (index, step) in steps.indexed) {
        if (step is CombatantShakeStep) {
          expect(index, greaterThan(throwIndex));
          expect(index, lessThan(verdictIndex));
          expect(step.side, BattleSideId.enemy);
        }
      }
    });

    test('a successful capture caps visual shakes at three before the click',
        () {
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
      const event = BattleCaptureAttemptEvent(
        attemptId: 'capture-attempt-1',
        targetSpeciesId: 'sparkitten',
        ballId: canonicalPokeBallItemId,
        caught: true,
        shakes: 4,
      );
      const turn = BattleTurnResult(
        playerAction: BattleActionCapture(
          attemptId: 'capture-attempt-1',
          itemId: canonicalPokeBallItemId,
          caught: true,
          shakes: 4,
        ),
        enemyAction: BattleActionNone(),
        executions: <BattleMoveExecution>[],
        captureAttemptEvents: <BattleCaptureAttemptEvent>[event],
        timeline: <BattleTurnEvent>[BattleTurnCaptureAttemptEvent(event)],
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

      expect(plan.steps.whereType<CombatantShakeStep>(), hasLength(3));
      expect(
        plan.steps
            .whereType<ShowMessageStep>()
            .map((step) => step.message)
            .toList(growable: false)
            .last,
        contains('est capturé'),
      );
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
      // BETA-BAT-013 : la barre de PV vit désormais dans le groupe parallèle
      // qui porte aussi le clignotement, donc on la cherche à plat.
      expect(plan.flattenedSteps.whereType<HudHpTweenStep>(), hasLength(1));
      expect(plan.steps.whereType<PlayRmxpAnimationStep>(), isNotEmpty);
    });

    test('damage that faints the target adds KO narration', () {
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
          speciesId: 'roucoups',
          lineupIndex: 0,
          maxHp: 12,
          currentHp: 12,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      final after = before.applyChoice(const PlayerBattleChoiceFight(0));
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.build(
        previousSession: before,
        newSession: after,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      final messages =
          plan.steps.whereType<ShowMessageStep>().map((step) => step.message);
      expect(after.state.outcome!.isVictory, isTrue);
      expect(messages, contains('roucoups est K.O. !'));
      // BETA-BAT-012 : ce combat est SAUVAGE (`_session` construit un setup non
      // dresseur), et une victoire sauvage ne s'annonce plus — décision de
      // Yoahn du 2026-08-23, alignée sur la référence où `show_wild_victory` ne
      // fait qu'un changement de musique et l'XP. Le K.O. reste annoncé.
      expect(messages, isNot(contains('Tu as gagné le combat !')));
      expect(plan.steps.whereType<FaintCombatantStep>().single.side,
          BattleSideId.enemy);
    });

    test('finished no-turn runaway still produces a final narration plan', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle', type: 'normal')
          ],
        ),
        enemy: _combatant(
          speciesId: 'roucoups',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'scratch', name: 'Scratch', type: 'normal')
          ],
        ),
      );
      final after = before.applyChoice(const PlayerBattleChoiceRun());
      final planner = BattleTurnAnimationPlanner();

      final plan = planner.build(
        previousSession: before,
        newSession: after,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(after.state.currentTurn, isNull);
      expect(
        plan.steps.whereType<ShowMessageStep>().map((step) => step.message),
        contains('Tu as pris la fuite !'),
      );
    });

    test('replacement-required KO does not duplicate faint animation', () {
      final before = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle', type: 'normal')
          ],
        ),
        enemy: _combatant(
          speciesId: 'roucoups',
          lineupIndex: 0,
          maxHp: 10,
          currentHp: 10,
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
            damage: 10,
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
              damage: 10,
              didHit: true,
            ),
          ),
          BattleTurnSwitchEvent(
            BattleSwitchEvent.replacementRequired(
              side: BattleSideId.enemy,
              fromSpeciesId: 'roucoups',
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

      expect(
        plan.steps.whereType<ShowMessageStep>().map((step) => step.message),
        contains('roucoups est K.O. !'),
      );
      expect(plan.steps.whereType<FaintCombatantStep>(), hasLength(1));
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

  // BETA-BAT-011 : le journal parle la langue du joueur.
  //
  // Les deux résolveurs de noms alimentaient déjà le HUD et le menu de
  // commandes ; le plan d'animation les contournait, et le joueur lisait
  // « machop utilise Low Kick ! » à côté d'un HUD disant « Machoc ». Ces tests
  // pinnent que le plan les traverse, et que critique et efficacité sont dits
  // à la place que la référence leur donne.
  group('BETA-BAT-011 — noms localisés et messages de dégâts', () {
    BattleAnimationPlan planFor({
      bool didCrit = false,
      double effectiveness = 1.0,
      int damage = 12,
      BattleTurnSpeciesDisplayName? speciesDisplayName,
      BattleTurnMoveDisplayName? moveDisplayName,
    }) {
      final before = _session(
        player: _combatant(
          speciesId: 'froakie',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'water_gun', name: 'Water Gun', type: 'water'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'machop',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'low_kick', name: 'Low Kick', type: 'fighting'),
          ],
        ),
      );
      final execution = BattleMoveExecution(
        attackerSlot: BattleSlotRef.active(BattleSideId.player),
        move: const BattleMove(
          id: 'water_gun',
          name: 'Water Gun',
          power: 40,
          target: BattleMoveTarget.opponent,
        ),
        targetKind: BattleMoveExecutionTargetKind.combatant,
        targetSlot: BattleSlotRef.active(BattleSideId.enemy),
        damage: damage,
        didHit: true,
        didCrit: didCrit,
        typeEffectivenessMultiplier: effectiveness,
      );
      final planner = BattleTurnAnimationPlanner(
        speciesDisplayName: speciesDisplayName ?? _rawSpecies,
        moveDisplayName: moveDisplayName ?? _rawMove,
      );
      return planner.buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: BattleTurnResult(
          playerAction: BattleActionFight(execution.move, moveIndex: 0),
          enemyAction: const BattleActionNone(),
          executions: <BattleMoveExecution>[execution],
          timeline: <BattleTurnEvent>[BattleTurnExecutionEvent(execution)],
        ),
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );
    }

    List<String> messagesOf(BattleAnimationPlan plan) => plan.steps
        .whereType<ShowMessageStep>()
        .map((step) => step.message)
        .toList(growable: false);

    test('le nom d’espèce et le nom de capacité passent par les résolveurs',
        () {
      final plan = planFor(
        speciesDisplayName: (id) => id == 'froakie' ? 'Grenousse' : 'Machoc',
        moveDisplayName: (id, fallback) =>
            id == 'water_gun' ? 'Pistolet à O' : fallback,
      );

      expect(
        messagesOf(plan).first,
        'Grenousse utilise Pistolet à O !',
        reason: 'le plan doit citer les noms affichables, pas les identifiants',
      );
    });

    test('aucun message ne contient un identifiant brut', () {
      final plan = planFor(
        damage: 40,
        speciesDisplayName: (id) => id == 'froakie' ? 'Grenousse' : 'Machoc',
        moveDisplayName: (id, fallback) =>
            id == 'water_gun' ? 'Pistolet à O' : fallback,
      );

      for (final message in messagesOf(plan)) {
        for (final raw in const <String>[
          'froakie',
          'machop',
          'water_gun',
          'Water Gun',
        ]) {
          expect(
            message,
            isNot(contains(raw)),
            reason: '« $message » laisse passer « $raw »',
          );
        }
      }
    });

    test('sans résolveur fourni, le texte est inchangé', () {
      // La compatibilité compte : un appelant qui n'injecte rien doit obtenir
      // exactement l'ancien message, sinon ce correctif casse des surfaces qui
      // n'ont pas demandé à changer.
      expect(messagesOf(planFor()).first, 'froakie utilise Water Gun !');
    });

    test('un coup critique est annoncé, après les PV et avant le K.O.', () {
      final plan = planFor(didCrit: true, damage: 40);
      final kinds = plan.steps
          .map((step) => step is ShowMessageStep ? step.message : step.runtimeType.toString())
          .toList(growable: false);
      final hpIndex = plan.steps.indexWhere((step) => step is HudHpTweenStep);
      final critIndex = kinds.indexOf('Coup critique !');
      final koIndex = kinds.indexWhere((label) => label.endsWith('est K.O. !'));

      expect(critIndex, greaterThan(hpIndex));
      expect(koIndex, greaterThan(critIndex));
    });

    test('le critique précède l’efficacité', () {
      final plan = planFor(didCrit: true, effectiveness: 2.0);
      final messages = messagesOf(plan);

      expect(
        messages.indexOf('C’est super efficace !'),
        greaterThan(messages.indexOf('Coup critique !')),
      );
    });

    test('une efficacité neutre ne dit rien', () {
      final messages = messagesOf(planFor(effectiveness: 1.0));

      expect(messages, isNot(contains('C’est super efficace !')));
      expect(messages, isNot(contains('Ce n’est pas très efficace…')));
    });

    test('une efficacité faible le dit', () {
      expect(
        messagesOf(planFor(effectiveness: 0.5)),
        contains('Ce n’est pas très efficace…'),
      );
    });
  });
  // BETA-BAT-013 : la chorégraphie d'un coup suit la référence PSDK.
  //
  // Arbitrage de Yoahn du 2026-08-23 : clignotement et barre de PV EN MÊME
  // TEMPS, comme le `Yuki::Animation::Handler` de la référence, et non l'un
  // après l'autre.
  group('BETA-BAT-013 — chorégraphie d’un coup', () {
    BattleAnimationPlan planFor({
      int damage = 12,
      int enemyMaxHp = 40,
    }) {
      final before = _session(
        player: _combatant(
          speciesId: 'froakie',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'water_gun', name: 'Water Gun', type: 'water'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'machop',
          lineupIndex: 0,
          maxHp: enemyMaxHp,
          moves: <BattleMoveData>[
            _move(id: 'low_kick', name: 'Low Kick', type: 'fighting'),
          ],
        ),
      );
      final execution = BattleMoveExecution(
        attackerSlot: BattleSlotRef.active(BattleSideId.player),
        move: const BattleMove(
          id: 'water_gun',
          name: 'Water Gun',
          power: 40,
          target: BattleMoveTarget.opponent,
        ),
        targetKind: BattleMoveExecutionTargetKind.combatant,
        targetSlot: BattleSlotRef.active(BattleSideId.enemy),
        damage: damage,
        didHit: true,
      );
      return BattleTurnAnimationPlanner().buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: BattleTurnResult(
          playerAction: BattleActionFight(execution.move, moveIndex: 0),
          enemyAction: const BattleActionNone(),
          executions: <BattleMoveExecution>[execution],
          timeline: <BattleTurnEvent>[BattleTurnExecutionEvent(execution)],
        ),
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );
    }

    AnimationGroupStep damageGroupOf(BattleAnimationPlan plan) =>
        plan.steps.whereType<AnimationGroupStep>().firstWhere(
              (group) => group.steps.any((step) => step is HudHpTweenStep),
            );

    test('le clignotement et la barre de PV sont dans le MÊME groupe parallèle',
        () {
      final group = damageGroupOf(planFor());

      expect(group.mode, BattleAnimationGroupMode.parallel);
      expect(group.steps.whereType<CombatantFlashStep>(), hasLength(1));
      expect(group.steps.whereType<HudHpTweenStep>(), hasLength(1));
    });

    test('plus aucun clignotement de la cible ne traîne hors du groupe', () {
      // C'est le cœur du ticket : la recette l'émettait dans sa propre suite
      // d'accents, donc il partait avec l'impact et non avec les PV.
      final plan = planFor();

      expect(plan.steps.whereType<CombatantFlashStep>(), isEmpty,
          reason: 'un clignotement de cible hors groupe repartirait avec les FX');
      expect(
        damageGroupOf(plan).steps.whereType<CombatantFlashStep>(),
        hasLength(1),
      );
    });

    test('le clignotement dure 0,6 s — 3 flashs de 0,2 s', () {
      final flash =
          damageGroupOf(planFor()).steps.whereType<CombatantFlashStep>().single;

      expect(flash.durationSeconds, closeTo(0.6, 1e-9));
      expect(flash.side, BattleSideId.enemy);
    });

    test('la descente des PV vaut le dégât divisé par 60, bornée', () {
      // La durée suit les PV RÉELLEMENT perdus, pas le dégât brut : la cible
      // reçoit donc assez de PV pour que le plafond soit atteignable.
      int drainMsFor(int damage) =>
          damageGroupOf(planFor(damage: damage, enemyMaxHp: 200))
              .steps
              .whereType<HudHpTweenStep>()
              .single
              .durationMs;

      expect(drainMsFor(30), 500);
      expect(drainMsFor(6), 200);
      expect(drainMsFor(90), 1000);
    });

    test('un maintien suit la descente, court quand la cible tombe', () {
      final holdSurvives = planFor(damage: 12, enemyMaxHp: 40)
          .steps
          .whereType<WaitStep>()
          .first
          .durationSeconds;
      final holdFaints = planFor(damage: 40, enemyMaxHp: 40)
          .steps
          .whereType<WaitStep>()
          .first
          .durationSeconds;

      expect(holdSurvives, closeTo(0.8, 1e-9));
      expect(holdFaints, closeTo(0.1, 1e-9));
    });

    test('un coup à 0 dégât clignote quand même et consomme une seconde', () {
      // Le bloc entier était sauté quand le dégât valait zéro : ni
      // clignotement, ni temps, donc un coup encaissé sans dégât ne se voyait
      // pas du tout.
      final group = damageGroupOf(planFor(damage: 0));

      expect(group.steps.whereType<CombatantFlashStep>(), hasLength(1));
      expect(group.steps.whereType<HudHpTweenStep>().single.durationMs, 1000);
    });

    test('la chute de K.O. dure 0,1 s', () {
      final faint = planFor(damage: 40, enemyMaxHp: 40)
          .steps
          .whereType<FaintCombatantStep>()
          .single;

      expect(faint.durationSeconds, closeTo(0.1, 1e-9));
    });

    test('l’ordre reste message, puis dégâts, puis K.O.', () {
      final plan = planFor(damage: 40, enemyMaxHp: 40);
      final groupIndex = plan.steps.indexOf(damageGroupOf(plan));
      final firstMessage =
          plan.steps.indexWhere((step) => step is ShowMessageStep);
      final faintIndex =
          plan.steps.indexWhere((step) => step is FaintCombatantStep);

      expect(firstMessage, lessThan(groupIndex));
      expect(faintIndex, greaterThan(groupIndex));
    });
  });
  // BETA-BAT-012 : le texte de fin arrive quand le tour est FINI, et une
  // victoire sauvage ne s'annonce pas.
  //
  // Décision de Yoahn du 2026-08-23 : on suit la référence, où
  // `show_wild_victory` ne fait qu'un changement de musique et l'XP.
  group('BETA-BAT-012 — annonce de fin de combat', () {
    test('une victoire sauvage ne produit aucun texte', () {
      final outcome = BattleOutcome(
        type: BattleOutcomeType.victory,
        finalState: _session(
          player: _combatant(
            speciesId: 'froakie',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'water_gun', name: 'Water Gun', type: 'water'),
            ],
          ),
          enemy: _combatant(
            speciesId: 'machop',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'low_kick', name: 'Low Kick', type: 'fighting'),
            ],
          ),
        ).state,
      );

      expect(
        battleOutcomeIsAnnounced(outcome, isTrainerBattle: false),
        isFalse,
        reason: 'la référence n’annonce pas une victoire sauvage',
      );
      expect(
        battleOutcomeIsAnnounced(outcome, isTrainerBattle: true),
        isTrue,
        reason: 'un combat de dresseur garde son texte',
      );
    });

    test('les autres issues gardent leur texte, sauvage ou non', () {
      final state = _session(
        player: _combatant(
          speciesId: 'froakie',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'water_gun', name: 'Water Gun', type: 'water'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'machop',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'low_kick', name: 'Low Kick', type: 'fighting'),
          ],
        ),
      ).state;

      for (final type in const <BattleOutcomeType>[
        BattleOutcomeType.defeat,
        BattleOutcomeType.runaway,
        BattleOutcomeType.captured,
      ]) {
        // Une capture doit identifier son objet et sa tentative : le domaine
        // le refuse autrement, et c'est une bonne assertion.
        final outcome = type == BattleOutcomeType.captured
            ? BattleOutcome(
                type: type,
                finalState: state,
                captureItemId: 'poke_ball',
                captureAttemptId: 'attempt-1',
              )
            : BattleOutcome(type: type, finalState: state);
        for (final trainer in const <bool>[false, true]) {
          expect(
            battleOutcomeIsAnnounced(outcome, isTrainerBattle: trainer),
            isTrue,
            reason: '$type doit rester annoncé (dresseur=$trainer)',
          );
        }
      }
    });
  });
  // BETA-BAT-014 : le combat s'entend.
  //
  // Le son du coup part sur la même frame que le clignotement et la descente
  // des PV — les trois sont les entrées du même handler parallèle chez la
  // référence — et son nom suit l'efficacité. Le K.O. joue `down` à pitch 80
  // avant que la chute ne démarre. La référence n'a AUCUN son de critique.
  group('BETA-BAT-014 — sons du plan', () {
    BattleAnimationPlan planFor({
      int damage = 12,
      int enemyMaxHp = 40,
      double effectiveness = 1.0,
      bool didCrit = false,
    }) {
      final before = _session(
        player: _combatant(
          speciesId: 'froakie',
          lineupIndex: 0,
          moves: <BattleMoveData>[
            _move(id: 'water_gun', name: 'Water Gun', type: 'water'),
          ],
        ),
        enemy: _combatant(
          speciesId: 'machop',
          lineupIndex: 0,
          maxHp: enemyMaxHp,
          moves: <BattleMoveData>[
            _move(id: 'low_kick', name: 'Low Kick', type: 'fighting'),
          ],
        ),
      );
      final execution = BattleMoveExecution(
        attackerSlot: BattleSlotRef.active(BattleSideId.player),
        move: const BattleMove(
          id: 'water_gun',
          name: 'Water Gun',
          power: 40,
          target: BattleMoveTarget.opponent,
        ),
        targetKind: BattleMoveExecutionTargetKind.combatant,
        targetSlot: BattleSlotRef.active(BattleSideId.enemy),
        damage: damage,
        didHit: true,
        didCrit: didCrit,
        typeEffectivenessMultiplier: effectiveness,
      );
      return BattleTurnAnimationPlanner().buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: BattleTurnResult(
          playerAction: BattleActionFight(execution.move, moveIndex: 0),
          enemyAction: const BattleActionNone(),
          executions: <BattleMoveExecution>[execution],
          timeline: <BattleTurnEvent>[BattleTurnExecutionEvent(execution)],
        ),
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );
    }

    AnimationGroupStep damageGroupOf(BattleAnimationPlan plan) =>
        plan.steps.whereType<AnimationGroupStep>().firstWhere(
              (group) => group.steps.any((step) => step is HudHpTweenStep),
            );

    test('le son du coup part dans le groupe du clignotement et des PV', () {
      final se = damageGroupOf(planFor())
          .steps
          .whereType<PlaySeStep>()
          .single;

      expect(se.seName, 'hit');
      expect(se.volume, 100);
      expect(se.pitch, 100);
    });

    test('le nom du son suit l’efficacité', () {
      String seFor(double effectiveness) =>
          damageGroupOf(planFor(effectiveness: effectiveness))
              .steps
              .whereType<PlaySeStep>()
              .single
              .seName;

      expect(seFor(2.0), 'hitplus');
      expect(seFor(0.5), 'hitlow');
      expect(seFor(1.0), 'hit');
    });

    test('le K.O. joue down à pitch 80, avant la chute', () {
      final plan = planFor(damage: 40, enemyMaxHp: 40);
      final steps = plan.steps;
      final downIndex = steps.indexWhere(
        (step) => step is PlaySeStep && step.seName == 'down',
      );
      final faintIndex = steps.indexWhere(
        (step) => step is FaintCombatantStep,
      );

      expect(downIndex, greaterThan(-1));
      expect((steps[downIndex] as PlaySeStep).pitch, 80);
      expect(faintIndex, greaterThan(downIndex));
    });

    test('pas de K.O., pas de down ; et jamais de son de critique', () {
      // La référence n'a aucun son de coup critique : le critique est un texte
      // seul, décision notée au ticket.
      final plan = planFor(damage: 12, enemyMaxHp: 40, didCrit: true);
      final seNames = <String>[
        for (final step in plan.flattenedSteps)
          if (step is PlaySeStep) step.seName,
      ];

      expect(seNames, <String>['hit']);
    });
  });
}

String _rawSpecies(String speciesId) => speciesId;

String _rawMove(String moveId, String fallbackName) => fallbackName;
