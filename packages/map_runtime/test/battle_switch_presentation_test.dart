import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_move_catalog_loader.dart';
import 'package:map_runtime/src/presentation/flame/battle_animation_plan.dart';
import 'package:map_runtime/src/presentation/flame/battle_move_visual_resolver.dart';
import 'package:map_runtime/src/presentation/flame/battle_turn_animation_planner.dart';

BattleSession _session() {
  return createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: const BattleCombatantData(
        speciesId: 'grenousse',
        level: 5,
        maxHp: 20,
        currentHp: 20,
        stats: BattleStatsSnapshot(
          attack: 10,
          defense: 10,
          specialAttack: 10,
          specialDefense: 10,
          speed: 90,
        ),
        moves: <BattleMoveData>[
          BattleMoveData(id: 'tackle', name: 'Charge', power: 20),
        ],
      ),
      enemyPokemon: const BattleCombatantData(
        speciesId: 'machop',
        level: 5,
        maxHp: 20,
        currentHp: 20,
        stats: BattleStatsSnapshot(
          attack: 10,
          defense: 10,
          specialAttack: 10,
          specialDefense: 10,
          speed: 10,
        ),
        moves: <BattleMoveData>[
          BattleMoveData(id: 'growl', name: 'Rugissement', power: 0),
        ],
      ),
      isTrainerBattle: false,
      trainerId: null,
    ),
  );
}

BattleAnimationPlan _planFor(List<BattleTurnEvent> timeline) {
  final before = _session();
  return BattleTurnAnimationPlanner(
    speciesDisplayName: (speciesId) =>
        speciesId == 'grenousse' ? 'Grenousse' : 'Machoc',
  ).buildForTurn(
    playerBefore: before.state.player,
    enemyBefore: before.state.enemy,
    turnResult: BattleTurnResult(
      playerAction: const BattleActionNone(),
      enemyAction: const BattleActionNone(),
      executions: const <BattleMoveExecution>[],
      timeline: timeline,
    ),
    moveCatalog: RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
    resolver: BattleMoveVisualResolver(
      RuntimeMoveCatalog.fromEntries(const <String, PokemonMove>{}),
    ),
  );
}

/// BETA-BAT-036 — recette du 2026-08-25.
///
/// Deux symptômes, une cause : l'adaptateur PSDK ne traduisait AUCUN
/// événement de changement de Pokémon. Le planner porte pourtant la séquence
/// complète depuis BETA-BAT-022 — elle n'était simplement jamais atteinte.
///
/// Conséquence la plus visible : le gel du sprite se calcule sur les étapes
/// de swap du plan. Sans événement, ce gel restait vide, et le remplaçant
/// apparaissait AVANT que le K.O. qui le provoque ait été joué : « on a
/// battu le pokémon suivant, c'est le bordel ».

void main() {
  group('la présentation d’un changement de Pokémon', () {
    test('joue le rappel, l’échange puis le nouvel envoi, dans cet ordre', () {
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnSwitchEvent(
          BattleSwitchEvent.switched(
            side: BattleSideId.enemy,
            fromSpeciesId: 'roucool',
            toSpeciesId: 'rattata',
            wasForced: true,
          ),
        ),
      ]);

      final kinds = plan.flattenedSteps
          .map(
            (step) => switch (step) {
              PlayBallSequenceStep(:final kind) => 'ball:${kind.name}',
              CombatantMotionStep(:final motionKind) =>
                'motion:${motionKind.name}',
              SwapCombatantVisualStep() => 'swap',
              _ => null,
            },
          )
          .whereType<String>()
          .toList();

      expect(
        kinds,
        <String>[
          'ball:recall',
          'motion:materializeOut',
          'swap',
          'ball:sendOutHeld',
          'motion:materializeIn',
        ],
        reason: 'la référence rappelle DANS la Ball, échange, puis renvoie',
      );
    });

    test('l’échange du sprite arrive APRÈS la disparition du sortant', () {
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnSwitchEvent(
          BattleSwitchEvent.switched(
            side: BattleSideId.enemy,
            fromSpeciesId: 'roucool',
            toSpeciesId: 'rattata',
            wasForced: true,
          ),
        ),
      ]);

      final steps = plan.flattenedSteps.toList();
      final out = steps.indexWhere(
        (step) =>
            step is CombatantMotionStep &&
            step.motionKind == BattleCombatantMotionKind.materializeOut,
      );
      final swap = steps.indexWhere((step) => step is SwapCombatantVisualStep);

      expect(out, greaterThanOrEqualTo(0));
      expect(
        swap,
        greaterThan(out),
        reason: 'échanger le sprite AVANT la disparition, c’est montrer le '
            'remplaçant à la place du Pokémon qu’on est en train de battre',
      );
    });

    test('le plan porte une étape de swap, donc le sprite peut être gelé', () {
      // C'est CETTE étape que l'overlay cherche pour décider quels côtés
      // garder figés pendant que le tour se joue. Sans elle, le sprite suit
      // l'état de session et bascule trop tôt.
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnSwitchEvent(
          BattleSwitchEvent.switched(
            side: BattleSideId.enemy,
            fromSpeciesId: 'roucool',
            toSpeciesId: 'rattata',
            wasForced: true,
          ),
        ),
      ]);

      expect(
        plan.flattenedSteps
            .whereType<SwapCombatantVisualStep>()
            .map((step) => step.side),
        <BattleSideId>[BattleSideId.enemy],
      );
    });

    test('une demande de remplacement ne rejoue pas la Ball', () {
      // `replacementRequired` annonce seulement qu'il faut choisir : la Ball
      // ne part qu'au changement effectif.
      final plan = _planFor(<BattleTurnEvent>[
        const BattleTurnSwitchEvent(
          BattleSwitchEvent.replacementRequired(
            side: BattleSideId.player,
            fromSpeciesId: 'grenousse',
          ),
        ),
      ]);

      expect(plan.flattenedSteps.whereType<PlayBallSequenceStep>(), isEmpty);
      expect(plan.flattenedSteps.whereType<SwapCombatantVisualStep>(), isEmpty);
    });
  });
}
