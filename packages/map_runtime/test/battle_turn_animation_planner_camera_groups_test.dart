import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

BattleAnimationPlan _planFor({
  required List<BattleAnimationStep> recipe,
  required BattleSlotRef attacker,
  BattleSlotRef? target,
}) {
  final session = createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: BattleCombatantData(
        speciesId: 'player',
        lineupIndex: 0,
        level: 30,
        maxHp: 40,
        stats: const BattleStatsSnapshot(
          attack: 60,
          defense: 60,
          specialAttack: 60,
          specialDefense: 60,
          speed: 50,
        ),
        moves: [],
      ),
      enemyPokemon: BattleCombatantData(
        speciesId: 'enemy',
        lineupIndex: 0,
        level: 30,
        maxHp: 40,
        stats: const BattleStatsSnapshot(
          attack: 60,
          defense: 60,
          specialAttack: 60,
          specialDefense: 60,
          speed: 50,
        ),
        moves: [],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
  final execution = BattleMoveExecution(
    attackerSlot: attacker,
    move: const BattleMove(id: 'splash', name: 'Splash', power: 0),
    targetKind: target == null
        ? BattleMoveExecutionTargetKind.field
        : BattleMoveExecutionTargetKind.combatant,
    targetSlot: target,
    damage: 0,
    didHit: true,
  );
  final catalog = RuntimeMoveCatalog.fromEntries({});
  return BattleTurnAnimationPlanner(recipeBuilder: (_, _) => recipe)
      .buildForTurn(
        playerBefore: session.state.player,
        enemyBefore: session.state.enemy,
        turnResult: BattleTurnResult(
          playerAction: const BattleActionNone(),
          enemyAction: const BattleActionNone(),
          executions: [execution],
          timeline: [BattleTurnExecutionEvent(execution)],
        ),
        moveCatalog: catalog,
        resolver: BattleMoveVisualResolver(catalog),
      );
}

void main() {
  for (final side in BattleSideId.values) {
    for (final slotIndex in [0, 1]) {
      final attacker = BattleSlotRef(side: side, slotIndex: slotIndex);
      final target = BattleSlotRef(
        side: side == BattleSideId.player
            ? BattleSideId.enemy
            : BattleSideId.player,
        slotIndex: 1 - slotIndex,
      );

      test('nested focus resolves user and target for $attacker', () {
        const before = WaitStep(durationSeconds: .17);
        const between = WaitStep(durationSeconds: .23);
        const after = WaitStep(durationSeconds: .41);
        const scene = CameraFocusStep(
          target: BattleCameraFocusTarget.scene,
          durationSeconds: .61,
        );
        const explicit = CameraFocusStep(
          target: BattleCameraFocusTarget.target,
          side: BattleSideId.player,
          slotIndex: 1,
          durationSeconds: .73,
        );
        final plan = _planFor(
          attacker: attacker,
          target: target,
          recipe: const [
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.sequence,
              steps: [
                before,
                AnimationGroupStep(
                  mode: BattleAnimationGroupMode.parallel,
                  steps: [
                    between,
                    AnimationGroupStep(
                      mode: BattleAnimationGroupMode.sequence,
                      steps: [
                        CameraFocusStep(
                          target: BattleCameraFocusTarget.user,
                          durationSeconds: .29,
                        ),
                        CameraFocusStep(
                          target: BattleCameraFocusTarget.target,
                          durationSeconds: .37,
                        ),
                        scene,
                        explicit,
                      ],
                    ),
                  ],
                ),
                after,
              ],
            ),
          ],
        );

        final focus = plan.flattenedSteps.whereType<CameraFocusStep>().toList();
        final user = focus.firstWhere(
          (step) => step.target == BattleCameraFocusTarget.user,
        );
        final resolvedTarget = focus.firstWhere(
          (step) => step.durationSeconds == .37,
        );
        expect(user.side, attacker.side);
        expect(user.slotIndex, attacker.slotIndex);
        expect(user.durationSeconds, .29);
        expect(resolvedTarget.side, target.side);
        expect(resolvedTarget.slotIndex, target.slotIndex);
        expect(focus, hasLength(4));
        expect(focus[2], same(scene));
        expect(focus[3], same(explicit));
        expect(plan.steps, hasLength(3));
        final outer = plan.steps[1] as AnimationGroupStep;
        expect(outer.mode, BattleAnimationGroupMode.sequence);
        expect(outer.steps, hasLength(3));
        expect(outer.steps.first, same(before));
        expect(outer.steps.last, same(after));
        final middle = outer.steps[1] as AnimationGroupStep;
        expect(middle.mode, BattleAnimationGroupMode.parallel);
        expect(middle.steps, hasLength(2));
        expect(middle.steps.first, same(between));
        final inner = middle.steps[1] as AnimationGroupStep;
        expect(inner.mode, BattleAnimationGroupMode.sequence);
        expect(inner.steps, hasLength(4));
        expect(inner.steps[0], same(user));
        expect(inner.steps[1], same(resolvedTarget));
        expect(
          plan.flattenedSteps.whereType<BattleCameraResetStep>(),
          hasLength(1),
        );
      });

      test(
        'nested camera movement suppresses automatic focus for $attacker',
        () {
          const movement = BattleCameraMoveStep(
            offsetX: 17,
            offsetY: -9,
            scale: .83,
            durationSeconds: .47,
            curve: BattleFxMotionCurve.arcOver,
          );
          const recipe = [
            AnimationGroupStep(
              mode: BattleAnimationGroupMode.parallel,
              steps: [
                AnimationGroupStep(
                  mode: BattleAnimationGroupMode.sequence,
                  steps: [WaitStep(durationSeconds: .19), movement],
                ),
              ],
            ),
          ];
          final plan = _planFor(
            attacker: attacker,
            target: target,
            recipe: recipe,
          );

          expect(plan.flattenedSteps.whereType<CameraFocusStep>(), isEmpty);
          expect(
            plan.flattenedSteps.whereType<BattleCameraMoveStep>().single,
            same(movement),
          );
          expect(plan.steps, hasLength(3));
          final outer = plan.steps[1] as AnimationGroupStep;
          expect(outer.mode, BattleAnimationGroupMode.parallel);
          expect(outer.steps, hasLength(1));
          final inner = outer.steps.single as AnimationGroupStep;
          expect(inner.mode, BattleAnimationGroupMode.sequence);
          expect((inner.steps.first as WaitStep).durationSeconds, .19);
          expect(inner.steps.last, same(movement));
        },
      );

      test('camera-free nested recipe keeps automatic focus for $attacker', () {
        const recipe = [
          AnimationGroupStep(
            mode: BattleAnimationGroupMode.sequence,
            steps: [
              WaitStep(durationSeconds: .13),
              AnimationGroupStep(
                mode: BattleAnimationGroupMode.parallel,
                steps: [WaitStep(durationSeconds: .31)],
              ),
            ],
          ),
        ];
        final plan = _planFor(
          attacker: attacker,
          target: target,
          recipe: recipe,
        );
        final focus = plan.flattenedSteps.whereType<CameraFocusStep>().single;

        expect(focus.target, BattleCameraFocusTarget.target);
        expect(focus.side, target.side);
        expect(focus.slotIndex, target.slotIndex);
        expect(focus.durationSeconds, 16 / 60);
        final group = plan.steps[2] as AnimationGroupStep;
        expect(group.mode, BattleAnimationGroupMode.sequence);
        expect(group.steps.first, same(recipe.single.steps.first));
        final inner = group.steps[1] as AnimationGroupStep;
        expect(inner.mode, BattleAnimationGroupMode.parallel);
        expect((inner.steps.single as WaitStep).durationSeconds, .31);
      });

      test('scene focus keeps its scope and duration for $attacker', () {
        const scene = CameraFocusStep(
          target: BattleCameraFocusTarget.scene,
          durationSeconds: .53,
        );
        final plan = _planFor(
          attacker: attacker,
          target: target,
          recipe: const [scene],
        );

        expect(
          plan.flattenedSteps.whereType<CameraFocusStep>().single,
          same(scene),
        );
        expect(plan.steps, hasLength(3));
      });
    }
  }
}
