import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_intro_animation_planner.dart';

const _stats = BattleStatsSnapshot(
  attack: 10,
  defense: 10,
  specialAttack: 10,
  specialDefense: 10,
  speed: 10,
);

BattleSession _session({required bool isTrainerBattle}) {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'sproutle',
        level: 10,
        maxHp: 24,
        stats: _stats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'tackle', name: 'Tackle', power: 10),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'sparkitten',
        level: 7,
        maxHp: 18,
        stats: _stats,
        moves: <BattleMoveData>[
          BattleMoveData(id: 'scratch', name: 'Scratch', power: 10),
        ],
      ),
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'rocket_grunt' : null,
    ),
  );
}

void main() {
  // BETA-BAT-016, critères 3 et 4 : la séquence complète existe et un combat
  // de dresseur a une séquence d'envoi que le sauvage n'a pas.
  test('sauvage : fondu, glissement parallèle, apparition, envoi joueur', () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(isTrainerBattle: false),
      slideDistancePx: 1080,
    );

    expect(plan.steps, hasLength(4));
    expect(
      plan.steps[0],
      isA<WaitStep>().having((s) => s.durationSeconds, 'fondu', 0.25),
    );
    final slide = plan.steps[1] as AnimationGroupStep;
    expect(slide.mode, BattleAnimationGroupMode.parallel);
    expect(
      slide.steps,
      everyElement(
        isA<CombatantMotionStep>()
            .having((s) => s.motionKind, 'motion',
                BattleCombatantMotionKind.introSlide)
            .having((s) => s.durationSeconds, 'durée', 0.8)
            .having((s) => s.distancePx, 'distance', 1080),
      ),
    );
    expect(
      (slide.steps.first as CombatantMotionStep).side,
      isNot((slide.steps.last as CombatantMotionStep).side),
      reason: 'les deux camps glissent',
    );
    expect(
      plan.steps[2],
      isA<ShowMessageStep>()
          .having((s) => s.message, 'message', contains('sauvage apparaît')),
    );
    expect(
      plan.steps[3],
      isA<ShowMessageStep>()
          .having((s) => s.message, 'message', startsWith('Vas-y')),
    );
  });

  test('dresseur : le défi PUIS l’envoi ennemi PUIS l’envoi joueur', () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(isTrainerBattle: true),
      slideDistancePx: 1080,
    );

    expect(plan.steps, hasLength(5));
    expect(plan.steps[0], isA<WaitStep>());
    expect(plan.steps[1], isA<AnimationGroupStep>());
    expect(
      plan.steps[2],
      isA<ShowMessageStep>()
          .having((s) => s.message, 'message', contains('te défie')),
    );
    expect(
      plan.steps[3],
      isA<ShowMessageStep>()
          .having((s) => s.message, 'message', contains('envoie')),
      reason: 'critère 4 : le dresseur a une séquence d’envoi ennemi',
    );
    expect(
      plan.steps[4],
      isA<ShowMessageStep>()
          .having((s) => s.message, 'message', startsWith('Vas-y')),
    );
  });
}
