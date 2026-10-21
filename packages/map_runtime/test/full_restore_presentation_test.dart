import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_overlay_component.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

void main() {
  for (final target in [0, 1]) {
    test('combined healing announces each actual target once: $target', () {
      final turn = BattleTurnResult(
        playerAction: const BattleActionNone(),
        enemyAction: const BattleActionNone(),
        executions: const [],
        timeline: [
          const BattleTurnBagHpHealItemEvent(
            BattleBagHpHealItemEvent(
              itemId: 'full-restore',
              displayName: 'Soin Total',
              side: BattleSideId.player,
              targetLineupIndex: 0,
              targetSpeciesId: 'eevee',
              hpBefore: 20,
              hpAfter: 100,
            ),
          ),
          BattleTurnStatusCuredItemEvent(
            side: BattleSideId.player,
            itemId: 'full-restore',
            displayName: 'Soin Total',
            targetSpeciesId: 'eevee',
            targetLineupIndex: target,
          ),
        ],
      );
      final lines = buildBattleTurnLinesForOverlay(turn);
      final expectedUses = target == 0 ? 1 : 2;
      expect(
        lines.where((line) => line.contains('utilise Soin Total')),
        hasLength(expectedUses),
      );
      expect(lines, contains('eevee récupère 80 PV'));
      expect(lines, contains('eevee est guéri de son problème de statut'));
      final player = BattleCombatantData(
        speciesId: 'eevee',
        lineupIndex: 0,
        level: 20,
        maxHp: 100,
        currentHp: 20,
        stats: const BattleStatsSnapshot(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 50,
        ),
        moves: const [],
      );
      final session = createBattleSession(
        BattleSetup.pokeMapBetaV1ForTest(
          playerPokemon: player,
          enemyPokemon: player,
          isTrainerBattle: false,
          trainerId: null,
        ),
      );
      final catalog = RuntimeMoveCatalog.fromEntries({});
      final plan = BattleTurnAnimationPlanner().buildForTurn(
        playerBefore: session.state.player,
        enemyBefore: session.state.enemy,
        turnResult: turn,
        moveCatalog: catalog,
        resolver: BattleMoveVisualResolver(catalog),
      );
      expect(
        plan.steps.whereType<ShowMessageStep>().where(
          (step) => step.message.contains('utilise Soin Total'),
        ),
        hasLength(expectedUses),
      );
    });
  }
}
