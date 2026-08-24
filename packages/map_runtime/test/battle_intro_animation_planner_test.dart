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
  //
  // BETA-BAT-027 (recette du 2026-08-24) a corrigé l'ORDRE de ce plan : les
  // messages ne sont plus groupés à la fin, ils ponctuent les temps de la
  // référence (annonce après l'entrée, envois chacun avec son message). Ce
  // fichier garde les invariants de CONTRAT (durées, distances, planches) ;
  // l'ordre lui-même est verrouillé par battle_intro_parity_test.dart.
  test('sauvage : fondu, entrée de l’adversaire, apparition, envoi joueur',
      () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(isTrainerBattle: false),
      slideDistancePx: 1080,
    );

    expect(
      plan.steps.first,
      isA<WaitStep>().having((s) => s.durationSeconds, 'fondu', 0.25),
    );
    final slides =
        plan.steps.whereType<CombatantMotionStep>().toList(growable: false);
    expect(
      slides,
      everyElement(
        isA<CombatantMotionStep>()
            .having((s) => s.motionKind, 'motion',
                BattleCombatantMotionKind.introSlide)
            .having((s) => s.durationSeconds, 'durée', 0.8)
            .having((s) => s.distancePx, 'distance', 1080),
      ),
    );
    expect(
      slides.map((step) => step.side).toSet(),
      <BattleSideId>{BattleSideId.enemy, BattleSideId.player},
      reason: 'les deux camps entrent, chacun à son temps de la référence',
    );
    final messages = plan.steps
        .whereType<ShowMessageStep>()
        .map((step) => step.message)
        .toList(growable: false);
    expect(messages.first, contains('sauvage apparaît'));
    expect(messages.last, startsWith('Vas-y'));
  });

  test('dresseur : le défi PUIS l’envoi ennemi PUIS l’envoi joueur', () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(isTrainerBattle: true),
      slideDistancePx: 1080,
    );

    final messages = plan.steps
        .whereType<ShowMessageStep>()
        .map((step) => step.message)
        .toList(growable: false);
    expect(messages, hasLength(3));
    expect(messages[0], contains('te défie'));
    expect(
      messages[1],
      contains('envoie'),
      reason: 'critère 4 : le dresseur a une séquence d’envoi ennemi',
    );
    expect(messages[2], startsWith('Vas-y'));
  });

  test(
      'BETA-BAT-022 : avec une planche de Ball, le joueur sort de sa Poké '
      'Ball — adversaire d’abord, lancer, ouverture, grossissement', () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(isTrainerBattle: false),
      slideDistancePx: 1080,
      playerBallSheetName: 'ball_1',
    );
    final steps = plan.steps;

    expect(steps.first, isA<WaitStep>());
    expect(
      steps[1],
      isA<CombatantMotionStep>()
          .having((s) => s.side, 'camp', BattleSideId.enemy)
          .having((s) => s.motionKind, 'mouvement',
              BattleCombatantMotionKind.introSlide),
      reason: 'la référence joue le mouvement adverse PUIS l’envoi joueur '
          '(create_sprite_move_animation puis create_player_send_animation)',
    );
    expect(
      steps.whereType<PlayBallSequenceStep>().single,
      isA<PlayBallSequenceStep>()
          .having((s) => s.side, 'camp', BattleSideId.player)
          .having((s) => s.kind, 'emploi', BattleBallSequenceKind.sendOutThrown)
          .having((s) => s.sheetName, 'planche', 'ball_1')
          .having((s) => s.durationSeconds, 'durée', 0.6),
      reason: 'vol en arc 0,5 s + ouverture 0,1 s — la parité de '
          'actor_ball_animation',
    );
    expect(
      steps
          .whereType<CombatantMotionStep>()
          .where((step) => step.side == BattleSideId.player)
          .single,
      isA<CombatantMotionStep>()
          .having((s) => s.motionKind, 'mouvement',
              BattleCombatantMotionKind.materializeIn)
          .having((s) => s.durationSeconds, 'durée', 0.1),
      reason: 'ya.scalar(0.1, self, :zoom=, 0, sprite_zoom)',
    );
  });

  test(
      'BETA-BAT-022 : sans planche de Ball, l’intro garde le glissement '
      'historique des deux camps', () {
    final plan = buildBattleIntroAnimationPlan(
      session: _session(isTrainerBattle: false),
      slideDistancePx: 1080,
    );
    expect(
      plan.steps
          .whereType<CombatantMotionStep>()
          .map((step) => step.motionKind)
          .toSet(),
      <BattleCombatantMotionKind>{BattleCombatantMotionKind.introSlide},
      reason: 'critère 4 : la planche absente ne casse jamais l’entrée — '
          'les deux camps glissent, comme avant BAT-022',
    );
    expect(plan.steps.whereType<PlayBallSequenceStep>(), isEmpty);
  });
}
