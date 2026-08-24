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
      // BETA-BAT-025 : les secousses décidées par la formule sont désormais
      // REJOUÉES par la séquence de Ball — le step les porte telles quelles.
      final capture =
          steps.whereType<PlayBallCaptureSequenceStep>().single;
      expect(capture.shakes, 2);
      expect(capture.caught, isFalse);
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
      final captureIndex = steps.indexOf(capture);
      expect(captureIndex, greaterThan(throwIndex));
      expect(captureIndex, lessThan(verdictIndex));
      expect(
        steps.whereType<CombatantShakeStep>(),
        isEmpty,
        reason: 'recette du 2026-08-24 : c’est la BALL qui tremble, plus le '
            'Pokémon',
      );
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

      final capture =
          plan.steps.whereType<PlayBallCaptureSequenceStep>().single;
      expect(
        capture.shakes,
        3,
        reason: 'la quatrième « secousse » d’une capture est le clic de '
            'verrouillage, porté par le verdict',
      );
      expect(capture.caught, isTrue);
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

      // BETA-BAT-022 : le remplacement passe par la Poké Ball, comme la
      // référence — rappel, échange du visuel, Ball posée, grossissement.
      final motions = plan.steps.whereType<CombatantMotionStep>().toList();
      expect(motions, hasLength(2));
      expect(
        motions.first.motionKind,
        BattleCombatantMotionKind.materializeOut,
        reason: 'le sortant rétrécit dans sa Ball (go_back_ball_animation)',
      );
      expect(
        motions.last.motionKind,
        BattleCombatantMotionKind.materializeIn,
        reason: 'le remplaçant grandit hors de sa Ball',
      );
      final balls = plan.steps.whereType<PlayBallSequenceStep>().toList();
      expect(balls, hasLength(2));
      expect(balls.first.kind, BattleBallSequenceKind.recall);
      expect(balls.last.kind, BattleBallSequenceKind.sendOutHeld);
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
          .map((step) => step is ShowMessageStep
              ? step.message
              : step.runtimeType.toString())
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
          reason:
              'un clignotement de cible hors groupe repartirait avec les FX');
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
      final se = damageGroupOf(planFor()).steps.whereType<PlaySeStep>().single;

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

  // Recette du 2026-08-24 — le feedback manquant : une attaque ratée, une
  // immunité, un move de statut et une fuite ratée devaient tous SE DIRE. Les
  // textes sont ceux de la référence (Data/Text/Dialogs 100019/100018).
  group('recette 2026-08-24 — le feedback manquant', () {
    BattleSession sessionFor() => _session(
          player: _combatant(
            speciesId: 'pikachu',
            lineupIndex: 0,
            moves: <BattleMoveData>[
              _move(id: 'sweet_kiss', name: 'Doux Baiser', type: 'fairy'),
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

    String displayName(String speciesId) =>
        speciesId == 'pikachu' ? 'Pikachu' : 'Machoc';

    BattleAnimationPlan planForTimeline(
      List<BattleTurnEvent> timeline, {
      List<BattleMoveExecution> executions = const <BattleMoveExecution>[],
    }) {
      final before = sessionFor();
      return BattleTurnAnimationPlanner(speciesDisplayName: displayName)
          .buildForTurn(
        playerBefore: before.state.player,
        enemyBefore: before.state.enemy,
        turnResult: BattleTurnResult(
          playerAction: const BattleActionNone(),
          enemyAction: const BattleActionNone(),
          executions: executions,
          timeline: timeline,
        ),
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );
    }

    List<String> messagesOf(BattleAnimationPlan plan) => <String>[
          for (final step in plan.flattenedSteps)
            if (step is ShowMessageStep) step.message,
        ];

    BattleMoveExecution executionFor({
      required BattleMove move,
      required bool didHit,
      int damage = 0,
      double typeEffectivenessMultiplier = 1.0,
    }) {
      return BattleMoveExecution(
        attackerSlot: BattleSlotRef.active(BattleSideId.player),
        move: move,
        targetKind: BattleMoveExecutionTargetKind.combatant,
        targetSlot: BattleSlotRef.active(BattleSideId.enemy),
        damage: damage,
        didHit: didHit,
        typeEffectivenessMultiplier: typeEffectivenessMultiplier,
      );
    }

    test('une attaque ratée annonce « évite l’attaque ! » sans impact', () {
      final execution = executionFor(
        move: const BattleMove(id: 'pound', name: 'Écras’Face', power: 40),
        didHit: false,
      );
      final plan =
          planForTimeline(<BattleTurnEvent>[BattleTurnExecutionEvent(execution)]);

      expect(messagesOf(plan), contains('Machoc évite l’attaque !'));
      expect(plan.flattenedSteps.whereType<HudHpTweenStep>(), isEmpty);
      expect(plan.flattenedSteps.whereType<PlaySeStep>(), isEmpty);
    });

    test('une immunité annonce « Ça n’affecte pas X… » sans son ni barre', () {
      final execution = executionFor(
        move: const BattleMove(id: 'lick', name: 'Léchouille', power: 30),
        didHit: true,
        typeEffectivenessMultiplier: 0.0,
      );
      final plan =
          planForTimeline(<BattleTurnEvent>[BattleTurnExecutionEvent(execution)]);

      expect(messagesOf(plan), contains('Ça n’affecte pas Machoc…'));
      expect(plan.flattenedSteps.whereType<PlaySeStep>(), isEmpty);
      expect(plan.flattenedSteps.whereType<HudHpTweenStep>(), isEmpty);
      expect(plan.flattenedSteps.whereType<CombatantFlashStep>(), isEmpty);
    });

    test('un move de statut garde son message d’usage mais aucun impact', () {
      final execution = executionFor(
        move: const BattleMove(id: 'sweet_kiss', name: 'Doux Baiser', power: 0),
        didHit: true,
      );
      final plan =
          planForTimeline(<BattleTurnEvent>[BattleTurnExecutionEvent(execution)]);

      expect(messagesOf(plan), contains('Pikachu utilise Doux Baiser !'));
      expect(plan.flattenedSteps.whereType<PlaySeStep>(), isEmpty);
      expect(plan.flattenedSteps.whereType<HudHpTweenStep>(), isEmpty);
      expect(plan.flattenedSteps.whereType<CombatantFlashStep>(), isEmpty);
    });

    test('le self-hit de confusion parle sa langue, pas « utilise effect: »',
        () {
      final execution = BattleMoveExecution(
        attackerSlot: BattleSlotRef.active(BattleSideId.enemy),
        move: const BattleMove(
          id: 'effect:confusion',
          name: 'effect:confusion',
          power: 40,
        ),
        targetKind: BattleMoveExecutionTargetKind.combatant,
        targetSlot: BattleSlotRef.active(BattleSideId.enemy),
        damage: 8,
        didHit: true,
      );
      final plan =
          planForTimeline(<BattleTurnEvent>[BattleTurnExecutionEvent(execution)]);
      final messages = messagesOf(plan);

      expect(messages, contains('Il se blesse dans sa confusion.'));
      expect(
        messages.where((message) => message.contains('utilise')),
        isEmpty,
        reason: 'un proc d’effet n’est pas l’usage d’une attaque',
      );
      expect(plan.flattenedSteps.whereType<HudHpTweenStep>(), isNotEmpty,
          reason: 'les dégâts du self-hit restent visibles sur la barre');
    });

    test('un statut appliqué se dit avec le nom et le texte de la référence',
        () {
      final plan = planForTimeline(<BattleTurnEvent>[
        BattleTurnStatusEvent(
          BattleStatusEvent.applied(
            targetSlot: BattleSlotRef.active(BattleSideId.enemy),
            status: BattleMajorStatusId.psn,
            sourceMoveId: 'poison_powder',
          ),
        ),
      ]);

      expect(messagesOf(plan), contains('Machoc est empoisonné !'));
    });

    test('la confusion a ses trois temps : appliquée, active, terminée', () {
      final actorSlot = BattleSlotRef.active(BattleSideId.enemy);
      final plan = planForTimeline(<BattleTurnEvent>[
        BattleTurnVolatileEvent(
          BattleVolatileEvent.confusionApplied(actorSlot: actorSlot),
        ),
        BattleTurnVolatileEvent(
          BattleVolatileEvent.confusionActive(actorSlot: actorSlot),
        ),
        BattleTurnVolatileEvent(
          BattleVolatileEvent.confusionEnded(actorSlot: actorSlot),
        ),
      ]);
      final messages = messagesOf(plan);

      expect(messages, contains('Ça rend Machoc confus !'));
      expect(messages, contains('Machoc est confus !'));
      expect(messages, contains('Machoc n’est plus confus !'));
    });

    test('une fuite ratée se dit', () {
      final plan = planForTimeline(<BattleTurnEvent>[
        const BattleTurnFleeFailedEvent(side: BattleSideId.player),
      ]);

      expect(messagesOf(plan), contains('Vous n’avez pas réussi à fuir.'));
    });

    test(
        'BETA-BAT-030 : un hôte qui présente la fin en scène garde le SON de '
        'la fuite mais PLUS son annonce', () {
      // La recette du 2026-08-24 montrait trois annonces successives pour une
      // seule fuite : celle du plan de tour, celle du coordinator, et le
      // « Combat terminé. » d'attente. Le plan de tour se tait, le son reste.
      final before = sessionFor();
      final after = before.applyChoice(const PlayerBattleChoiceRun());
      final plan = BattleTurnAnimationPlanner(
        speciesDisplayName: displayName,
        announcesOutcome: false,
      ).build(
        previousSession: before,
        newSession: after,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );

      expect(
        plan.steps.whereType<PlaySeStep>().single.seName,
        'flee',
        reason: 'le son est un accent du tour, pas une annonce',
      );
      expect(
        plan.steps.whereType<ShowMessageStep>(),
        isEmpty,
        reason: 'l’annonce revient au coordinator, qui la joue en scène',
      );
    });

    test('une fuite réussie joue le son de la référence avec son annonce', () {
      final before = sessionFor();
      final after = before.applyChoice(const PlayerBattleChoiceRun());
      final plan = BattleTurnAnimationPlanner(speciesDisplayName: displayName)
          .build(
        previousSession: before,
        newSession: after,
        moveCatalog:
            RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
        resolver: _resolver(),
      );
      final fleeIndex = plan.steps.indexWhere(
        (step) => step is PlaySeStep && step.seName == 'flee',
      );
      final messageIndex = plan.steps.indexWhere(
        (step) =>
            step is ShowMessageStep && step.message == 'Tu as pris la fuite !',
      );

      expect(fleeIndex, greaterThan(-1));
      final fleeStep = plan.steps[fleeIndex] as PlaySeStep;
      expect(fleeStep.volume, 80);
      expect(fleeStep.pitch, 70);
      expect(messageIndex, greaterThan(fleeIndex));
    });
  });
}

String _rawSpecies(String speciesId) => speciesId;

String _rawMove(String moveId, String fallbackName) => fallbackName;
