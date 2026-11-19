import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/map_runtime.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_intro_animation_planner.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

void main() {
  test(
    'formatting the turn keeps event order, camera, slots and HP timing',
    () {
      final session = _session();
      final state = session.state;
      const playerSlot = BattleSlotRef.active(BattleSideId.player);
      const enemySlot = BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1);
      final events = <BattleTurnEvent>[
        BattleTurnExecutionEvent(
          BattleMoveExecution(
            attackerSlot: playerSlot,
            targetSlot: enemySlot,
            targetKind: BattleMoveExecutionTargetKind.combatant,
            move: state.player.moves.single,
            damage: 2,
            didHit: true,
          ),
        ),
        BattleTurnExecutionEvent(
          BattleMoveExecution(
            attackerSlot: enemySlot,
            targetSlot: playerSlot,
            targetKind: BattleMoveExecutionTargetKind.combatant,
            move: state.player.moves.single,
            damage: 0,
            didHit: false,
          ),
        ),
        const BattleTurnMoveFailedEvent(
          slot: enemySlot,
          moveId: 'tackle',
          reason: 'blocked',
        ),
        const BattleTurnBagHpHealItemEvent(
          BattleBagHpHealItemEvent(
            itemId: 'custom-tonic',
            displayName: 'Tonic',
            side: BattleSideId.player,
            targetLineupIndex: 0,
            targetSpeciesId: 'sproutle',
            hpBefore: 10,
            hpAfter: 20,
          ),
        ),
        const BattleTurnSwitchEvent(
          BattleSwitchEvent.switched(
            side: BattleSideId.enemy,
            slotIndex: 1,
            fromSpeciesId: 'sparkitten',
            toSpeciesId: 'duskling',
            wasForced: false,
          ),
        ),
      ];
      final turn = BattleTurnResult(
        playerAction: const BattleActionNone(),
        enemyAction: const BattleActionNone(),
        executions: events
            .whereType<BattleTurnExecutionEvent>()
            .map((event) => event.execution)
            .toList(),
        timeline: events,
      );
      final catalog = RuntimeMoveCatalog.fromEntries({});
      var french = true;
      final seen = <RuntimeBattleMessage>[];
      final planner = BattleTurnAnimationPlanner(
        speciesDisplayName: (id) => switch (id) {
          'sproutle' => french ? 'Pousse' : 'Sproutle',
          'sparkitten' => french ? 'Étincelle' : 'Sparkitten',
          _ => french ? 'Crépuscule' : 'Duskling',
        },
        moveDisplayName: (id, fallback) => french ? 'Charge' : 'Tackle',
        recipeBuilder: (_, _) => const [
          CameraFocusStep(
            target: BattleCameraFocusTarget.target,
            durationSeconds: .25,
          ),
        ],
        formatBattleMessage: (message) {
          seen.add(message);
          return french ? message.fallbackText : message.id.name;
        },
      );
      BattleAnimationPlan build() => planner.buildForTurn(
        playerBefore: state.player,
        enemyBefore: state.enemy,
        combatantsBefore: {playerSlot: state.player, enemySlot: state.enemy},
        turnResult: turn,
        moveCatalog: catalog,
        resolver: BattleMoveVisualResolver(catalog),
      );
      final fr = build();
      final frenchMessages = seen.toList();
      seen.clear();
      french = false;
      final en = build();
      expect(_stepSignature(en), _stepSignature(fr));
      expect(turn.timeline, events);
      expect(
        frenchMessages.map((message) => message.id),
        seen.map((message) => message.id),
      );
      final used = seen.firstWhere(
        (message) => message.id == RuntimeBattleMessageId.moveUsed,
      );
      final heal = seen.firstWhere(
        (message) => message.id == RuntimeBattleMessageId.hpRecovered,
      );
      final switched = seen.firstWhere(
        (message) => message.id == RuntimeBattleMessageId.switched,
      );
      expect((used.actor, used.move), ('Sproutle', 'Tackle'));
      final damage = seen.singleWhere(
        (message) => message.id == RuntimeBattleMessageId.moveDamageSummary,
      );
      expect(
        (damage.actor, damage.move, damage.amount),
        ('Sproutle', 'Tackle', 2),
      );
      expect(
        fr.flattenedSteps
            .whereType<ShowMessageStep>()
            .map((step) => step.summaryMessage)
            .nonNulls,
        ['Pousse utilise Charge et inflige 2 dégâts.'],
      );

      expect((heal.target, heal.amount), ('Sproutle', 10));
      expect(
        (switched.target, switched.replacement),
        ('Sparkitten', 'Duskling'),
      );
      expect(
        seen.map((message) => message.id),
        contains(RuntimeBattleMessageId.moveFailed),
      );
      expect(
        fr.flattenedSteps.whereType<ShowMessageStep>().first.message,
        'Pousse utilise Charge !',
      );
      expect(
        en.flattenedSteps.whereType<ShowMessageStep>().first.message,
        'moveUsed',
      );
    },
  );

  test(
    'opening preserves a player nickname and gives the formatter both sides',
    () {
      final session = _session();
      final seen = <RuntimeBattleMessage>[];
      final plan = buildBattleIntroAnimationPlan(
        session: session,
        slideDistancePx: 200,
        resolveSpeciesDisplayName: (id) =>
            id == 'sparkitten' ? 'Sparkitten' : id,
        resolveCombatantDisplayName: (side, combatant) =>
            side == BattleSideId.player ? 'Pip' : 'Sparkitten',
        formatBattleMessage: (message) {
          seen.add(message);
          return message.id.name;
        },
      );
      expect(
        plan.flattenedSteps.whereType<ShowMessageStep>().map(
          (step) => step.message,
        ),
        ['wildAppeared', 'go'],
      );
      expect(seen.map((message) => message.target), ['Sparkitten', 'Pip']);
    },
  );
}

Iterable<Object> _stepSignature(BattleAnimationPlan plan) =>
    plan.flattenedSteps.map(
      (step) => switch (step) {
        AnimationGroupStep(:final mode) => (step.runtimeType, mode),
        CameraFocusStep(
          :final side,
          :final slotIndex,
          :final durationSeconds,
        ) =>
          (step.runtimeType, side, slotIndex, durationSeconds),
        BattleCameraResetStep(:final durationSeconds) => (
          step.runtimeType,
          durationSeconds,
        ),
        HudHpTweenStep(
          :final slot,
          :final fromHp,
          :final toHp,
          :final durationMs,
        ) =>
          (step.runtimeType, slot, fromHp, toHp, durationMs),
        WaitStep(:final durationSeconds) => (step.runtimeType, durationSeconds),
        PlayBallSequenceStep(:final slot, :final kind) => (
          step.runtimeType,
          slot,
          kind,
        ),
        CombatantMotionStep(
          :final slot,
          :final motionKind,
          :final durationSeconds,
        ) =>
          (step.runtimeType, slot, motionKind, durationSeconds),
        SwapCombatantVisualStep(:final slot, :final initialHp) => (
          step.runtimeType,
          slot,
          initialHp,
        ),
        _ => step.runtimeType,
      },
    );

BattleSession _session() {
  const stats = BattleStatsSnapshot(
    attack: 10,
    defense: 10,
    specialAttack: 10,
    specialDefense: 10,
    speed: 10,
  );
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'sproutle',
        level: 5,
        maxHp: 20,
        currentHp: 10,
        stats: stats,
        moves: [BattleMoveData(id: 'tackle', name: 'Tackle', power: 40)],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'sparkitten',
        level: 5,
        maxHp: 20,
        currentHp: 20,
        stats: stats,
        moves: [],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}
