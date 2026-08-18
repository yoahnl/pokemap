import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Invariants de terminaison d'un tour (BETA-BAT-006).
///
/// L'invariant en rouge du ticket : « une session ne doit jamais être à la fois
/// attente de switch et terminée ». Il tient par l'ORDRE DES GARDES de
/// `_buildDecisionRequest`, où `finished` est testé avant que les choix de
/// remplacement soient calculés. Rien ne retenait cet ordre : le réordonner
/// aurait fait demander un remplaçant dans un combat déjà gagné, sans qu'aucun
/// test ne bronche.
///
/// Le cas qui le prouve demande une situation précise, et c'est là que l'ancien
/// test de double KO s'arrête : un double KO où L'ADVERSAIRE N'A PAS DE RÉSERVE
/// mais où LE JOUEUR EN A UNE. Le combat est gagné, et des remplaçants sont
/// pourtant disponibles. C'est la seule configuration où les deux branches
/// peuvent se disputer la réponse.
void main() {
  group('BETA-BAT-006 a finished battle never asks for a switch', () {
    test('a won battle with a fainted active and reserves says finished', () {
      final afterTurn = _doubleKnockOut(
        playerHasReserve: true,
        enemyHasReserve: false,
      );

      expect(afterTurn.state.isFinished, isTrue);
      expect(afterTurn.state.outcome!.isVictory, isTrue);
      expect(
        afterTurn.state.player.isFainted,
        isTrue,
        reason: 'the vector only means something with a fainted active',
      );

      // Le point du ticket : des remplaçants existent, et pourtant aucune
      // demande de remplacement ne doit sortir.
      final request = afterTurn.decisionRequest;
      expect(request, isA<BattleWaitRequest>());
      expect(request, isNot(isA<BattleForcedReplacementRequest>()));
      expect(
        (request as BattleWaitRequest).reason,
        BattleWaitReason.battleFinished,
      );
    });

    test('a lost battle with a fainted active and no reserve says finished', () {
      final afterTurn = _doubleKnockOut(
        playerHasReserve: false,
        enemyHasReserve: true,
      );

      expect(afterTurn.state.isFinished, isTrue);
      expect(afterTurn.state.outcome!.isDefeat, isTrue);
      expect(
        afterTurn.decisionRequest,
        isA<BattleWaitRequest>(),
      );
    });

    test('an unfinished battle with a fainted active does ask for a switch', () {
      // Contraste indispensable : sans lui, les deux cas précédents passeraient
      // aussi avec une demande de remplacement supprimée partout.
      final afterTurn = _doubleKnockOut(
        playerHasReserve: true,
        enemyHasReserve: true,
      );

      expect(afterTurn.state.isFinished, isFalse);
      expect(afterTurn.state.player.isFainted, isTrue);
      expect(afterTurn.decisionRequest, isA<BattleForcedReplacementRequest>());
    });
  });

  group('BETA-BAT-006 no action survives the end of a battle', () {
    test('a finished session refuses every further choice', () {
      final finished = _doubleKnockOut(
        playerHasReserve: true,
        enemyHasReserve: false,
      );

      for (final choice in <PlayerBattleChoice>[
        const PlayerBattleChoiceFight(0),
        const PlayerBattleChoiceSwitch(0),
      ]) {
        expect(
          () => finished.applyChoice(choice),
          throwsA(isA<StateError>()),
          reason: '${choice.runtimeType} must not reopen a finished battle',
        );
      }
    });

    test('a battle waiting for a replacement refuses a fight command', () {
      // « Commande UI arrivée après changement de phase » : le menu affichait
      // un tour libre, le moteur est passé en remplacement forcé. La décision
      // est revalidée contre la demande COURANTE, donc elle est refusée.
      final awaitingSwitch = _doubleKnockOut(
        playerHasReserve: true,
        enemyHasReserve: true,
      );

      expect(awaitingSwitch.decisionRequest,
          isA<BattleForcedReplacementRequest>());
      expect(
        () => awaitingSwitch.applyChoice(const PlayerBattleChoiceFight(0)),
        throwsA(isA<StateError>()),
      );
      expect(
        awaitingSwitch.applyChoice(const PlayerBattleChoiceSwitch(0)).state
            .player
            .isFainted,
        isFalse,
        reason: 'the legal choice must still go through',
      );
    });

    test('a fainted reserve is not offered as a replacement', () {
      // « Aucune cible KO illégale ». Le vecteur demande une réserve KO À CÔTÉ
      // d'une valide : avec une seule réserve KO, le joueur perd et le garde
      // `finished` court-circuite avant même la branche de remplacement, si bien
      // que le filtre n'est jamais consulté. Première version de ce test :
      // verte quel que soit le filtre.
      //
      // L'index est celui de la RÉSERVE, pas du lineup — autre piège de la
      // première version.
      final awaitingSwitch = _doubleKnockOut(
        playerHasReserve: true,
        enemyHasReserve: true,
        playerFaintedExtraReserve: true,
      );

      final request = awaitingSwitch.decisionRequest;
      expect(request, isA<BattleForcedReplacementRequest>());
      final choices = (request as BattleForcedReplacementRequest)
          .switchChoices
          .map((choice) => choice.reserveIndex);

      expect(choices, contains(1), reason: 'the healthy reserve is legal');
      expect(choices, isNot(contains(0)),
          reason: 'the fainted one never is');
    });
  });

  group('BETA-BAT-006 a turn produces one outcome', () {
    test('the outcome is stable once the battle is finished', () {
      final finished = _doubleKnockOut(
        playerHasReserve: true,
        enemyHasReserve: false,
      );
      final outcome = finished.state.outcome!;

      // Relire la session ne doit pas produire une seconde issue, ni une issue
      // différente : un tour a une seule fin.
      expect(finished.state.outcome!.isVictory, outcome.isVictory);
      expect(finished.state.outcome!.isDefeat, outcome.isDefeat);
      expect(finished.state.isFinished, isTrue);
    });
  });
}

/// Double KO par poison résiduel, avec ou sans réserve de chaque côté.
///
/// Les deux actifs sont à 1 PV et empoisonnés : le résiduel de fin de tour les
/// fait tomber ensemble, ce qui est la seule façon simple de mettre la
/// terminaison et le remplacement en concurrence.
BattleSession _doubleKnockOut({
  required bool playerHasReserve,
  required bool enemyHasReserve,
  bool playerFaintedExtraReserve = false,
}) {
  final session = createBattleSession(
    BattleSetup.pokeMapBetaV1ForTest(
      playerPokemon: _dyingCombatant('lead_player', 0),
      playerReservePokemon: <BattleCombatantData>[
        // Réserve 0 volontairement K.O. quand le vecteur le demande, pour que
        // le filtre ait quelque chose à écarter à côté d'un choix valide.
        if (playerFaintedExtraReserve)
          _combatant('bench_fainted', 1, currentHp: 0),
        if (playerHasReserve)
          _combatant('bench_player', playerFaintedExtraReserve ? 2 : 1),
      ],
      enemyPokemon: _dyingCombatant('lead_enemy', 0),
      enemyReservePokemon: <BattleCombatantData>[
        if (enemyHasReserve) _combatant('bench_enemy', 1),
      ],
      isTrainerBattle: true,
      trainerId: 'trainer',
    ),
  );
  return session.applyChoice(const PlayerBattleChoiceFight(0));
}

BattleCombatantData _dyingCombatant(String speciesId, int lineupIndex) {
  return _combatant(
    speciesId,
    lineupIndex,
    currentHp: 1,
    majorStatus: const BattleMajorStatusState.psn(),
  );
}

BattleCombatantData _combatant(
  String speciesId,
  int lineupIndex, {
  int? currentHp,
  BattleMajorStatusState? majorStatus,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: 30,
    maxHp: 40,
    currentHp: currentHp,
    majorStatus: majorStatus,
    stats: const BattleStatsSnapshot(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: 50,
    ),
    moves: const <BattleMoveData>[
      BattleMoveData(
        id: 'wait',
        name: 'Wait',
        power: 0,
        category: BattleMoveCategory.status,
        target: BattleMoveTarget.self,
        accuracy: BattleMoveAccuracy.alwaysHits(),
      ),
    ],
  );
}
