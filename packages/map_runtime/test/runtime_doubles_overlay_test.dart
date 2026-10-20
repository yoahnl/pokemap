import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_combatant_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_scene_layout.dart';
import 'package:map_runtime/src/presentation/flutter/battle_command_overlay_snapshot.dart';
import 'package:map_runtime/src/presentation/flutter/battle_mobile_command_overlay.dart';

import 'support/load_flame_component.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'four sprites and HUDs keep slots while choosing the second foe',
    () async {
      final adapter = _adapter();
      BattleDecision? submitted;
      BattleEngineDecisionRequest? submittedRequest;
      final overlay = BattleOverlayComponent(
        session: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
        viewportSize: Vector2(436, 800),
        onPlayerChoice: (_) => fail('A doubles choice must carry its request.'),
        onPlayerDecision: (decision, request) {
          submitted = decision;
          submittedRequest = request;
        },
      );
      await loadFlameComponent(overlay);
      await overlay.waitForPendingVisualSync();
      addTearDown(overlay.onRemove);

      expect(
        overlay.children.whereType<BattleSceneCombatantComponent>(),
        hasLength(4),
      );
      final initial = overlay.currentCommandOverlaySnapshot!;
      expect(initial.combatantHuds.map((hud) => hud.effectiveSlot).toSet(), {
        const BattleSlotRef.active(BattleSideId.player),
        const BattleSlotRef(side: BattleSideId.player, slotIndex: 1),
        const BattleSlotRef.active(BattleSideId.enemy),
        const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1),
      });
      expect(initial.combatantHuds.map((hud) => hud.combatantId).toSet(), {
        'player_0',
        'player_1',
        'opponent_0',
        'opponent_1',
      });
      expect(overlay.selectRootEntry(0), isTrue);
      expect(overlay.selectChoiceEntry(0), isTrue);
      final targets = overlay.currentCommandOverlaySnapshot!;
      expect(targets.mode, BattleCommandOverlayMode.moveTarget);
      expect(targets.entries.map((entry) => entry.primaryLabel), [
        'opponent_0',
        'opponent_1',
      ]);
      expect(overlay.selectMoveTargetEntry(1), isTrue);
      expect(identical(submittedRequest, adapter.decisionRequest), isTrue);
      expect(
        (submitted as BattleFightDecision).target,
        const PsdkBattleSlotRef(bank: 1, position: 1),
      );
      adapter.submitDecision(submitted!, request: submittedRequest);
      overlay.updateState(
        adapter.createLegacyDisplaySession(isTrainerBattle: true),
        presentation: adapter.presentation,
      );
      await overlay.waitForPendingVisualSync();
      expect(
        overlay.currentCommandOverlaySnapshot!.actorSlot,
        const BattleSlotRef(side: BattleSideId.player, slotIndex: 1),
      );
      expect(overlay.selectMoveTargetEntry(1), isFalse);
    },
  );

  test(
    'the single animation planner retains second-slot hits and switches',
    () {
      final catalog = RuntimeMoveCatalog.fromEntries(
        const <String, PokemonMove>{},
      );
      final adapter = _adapter(reserve: true);
      final before = adapter.presentation;
      final previous = adapter.createLegacyDisplaySession(
        isTrainerBattle: true,
      );
      adapter.submitDecision(
        const BattleDecision.fight(
          moveSlot: 0,
          target: PsdkBattleSlotRef(bank: 1, position: 1),
        ),
        request: adapter.decisionRequest,
      );
      adapter.submitDecision(
        const BattleDecision.switchPokemon(partyIndex: 2),
        request: adapter.decisionRequest,
      );
      final plan = BattleTurnAnimationPlanner().build(
        previousSession: previous,
        newSession: adapter.createLegacyDisplaySession(isTrainerBattle: true),
        combatantsBefore: before.combatantsBySlot,
        combatantsAfter: adapter.presentation.combatantsBySlot,
        moveCatalog: catalog,
        resolver: BattleMoveVisualResolver(catalog),
      );
      expect(
        plan.flattenedSteps.whereType<SwapCombatantVisualStep>().map(
          (step) => step.slot,
        ),
        [const BattleSlotRef(side: BattleSideId.player, slotIndex: 1)],
      );
      expect(
        plan.flattenedSteps
            .whereType<HudHpTweenStep>()
            .where((step) => step.side == BattleSideId.enemy)
            .map((step) => step.slot)
            .toSet(),
        {const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1)},
      );
      expect(
        plan.flattenedSteps.whereType<CombatantFlashStep>().any(
          (step) =>
              step.slot ==
              const BattleSlotRef(side: BattleSideId.enemy, slotIndex: 1),
        ),
        isTrue,
      );
      final replacementDrains = plan.flattenedSteps
          .whereType<HudHpTweenStep>()
          .where(
            (step) =>
                step.slot ==
                const BattleSlotRef(side: BattleSideId.player, slotIndex: 1),
          );
      expect(
        replacementDrains.last.toHp,
        adapter.state
            .battlerAt(const PsdkBattleSlotRef(bank: 0, position: 1))
            .currentHp,
      );
    },
  );

  for (final viewport in const [
    Size(390, 844),
    Size(844, 390),
    Size(1280, 720),
  ]) {
    testWidgets('four HUDs render within $viewport', (tester) async {
      tester.view.physicalSize = viewport;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final adapter = _adapter();
      final layout = BattleSceneLayout.forViewport(viewportSize: viewport);
      final huds = adapter.presentation.activeCombatants.map((active) {
        final rect = layout
            .combatantGeometry(active.slot, doubles: true)
            .hudRect;
        expect(rect.intersect(Offset.zero & viewport), rect);
        return BattleCommandOverlayHudSnapshot(
          rect: rect,
          slot: active.slot,
          combatantId: active.combatantId,
          ownerLabel: active.slot.side.name,
          speciesLabel: active.combatantId,
          level: 20,
          currentHp: 50,
          maxHp: 100,
          displayedHp: 50,
          isPlayerSide: active.slot.side == BattleSideId.player,
        );
      }).toList();
      for (var index = 0; index < huds.length; index++) {
        for (var other = index + 1; other < huds.length; other++) {
          expect(huds[index].rect.overlaps(huds[other].rect), isFalse);
        }
      }
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BattleMobileCommandOverlay(
              snapshot: BattleCommandOverlaySnapshot(
                viewportSize: viewport,
                panelRect: layout.commandPanelRect,
                mode: BattleCommandOverlayMode.moveTarget,
                prompt: 'Choisis une cible.',
                entries: const [],
                canGoBack: true,
                battleLabel: 'Combat double',
                title: 'Cible',
                narrationLines: const [],
                interactionsEnabled: true,
                playerHud: huds[0],
                enemyHud: huds[2],
                additionalHuds: [huds[1], huds[3]],
              ),
              onEntrySelected: (_) {},
            ),
          ),
        ),
      );
      for (final id in const [
        'player_0',
        'player_1',
        'opponent_0',
        'opponent_1',
      ]) {
        expect(
          find.text(
            id.replaceAll('_', ' ').replaceFirst(id[0], id[0].toUpperCase()),
          ),
          findsOneWidget,
        );
      }
      expect(tester.takeException(), isNull);
    });
  }
}

RuntimePsdkBattleSessionAdapter _adapter({bool reserve = false}) {
  PsdkBattleCombatantSetup combatant(String id) => PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: id == 'player_2' ? 80 : 50,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: [
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 10,
        currentPp: 10,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.doubles(
      ruleset: PokemonRulesetProfile.standardV1,
      player: [combatant('player_0'), combatant('player_1')],
      playerReserves: [if (reserve) combatant('player_2')],
      opponent: [combatant('opponent_0'), combatant('opponent_1')],
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 2,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}
