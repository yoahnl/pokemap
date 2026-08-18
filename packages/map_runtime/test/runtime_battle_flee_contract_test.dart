import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

import 'support/battle_gate_diagnostics.dart';

/// Contrat de fuite de la gate de combat (BETA-BAT-008).
///
/// Le ticket demande le scénario « fuite échouée PUIS réussie ». IL N'EST PAS
/// ATTEIGNABLE, et ce n'est pas un trou de couverture mais une propriété du
/// moteur, mesurée le 2026-08-18. Deux couches s'y opposent, et la seconde n'est
/// apparue qu'en écrivant ces cas.
///
/// COUCHE 1, la façade. `BattleSessionFacade.submit` refuse une décision de
/// fuite que la demande courante n'autorise pas, en levant
/// `BattleDecisionRejectedError`. Dans un combat de dresseur, ou dans un combat
/// sauvage où la fuite est interdite, la tentative N'ATTEINT JAMAIS le moteur :
/// il n'y a donc même pas d'échec de fuite à observer.
///
/// COUCHE 2, le moteur. Quand la fuite est permise, `battle_turn_runner` la
/// résout ainsi :
///
///     succeeded = !isTrainerBattle && (canFlee || fleePassthrough(user))
///
/// Aucune formule de vitesse, aucun compteur de tentatives — là où la série
/// principale calcule des chances d'évasion croissantes. Les trois entrées sont
/// fixées au setup : `isTrainerBattle` et `canFlee` ne bougent pas, et le passage
/// en force vient d'un talent ou d'un objet tenu, qui ne s'acquièrent pas à
/// mi-combat. Une fuite permise réussit donc du premier coup et termine le
/// combat sur place.
///
/// Les deux branches excluent le scénario : là où la fuite est permise il n'y a
/// pas de place pour un échec préalable, et là où elle ne l'est pas il n'y a
/// aucune tentative. Ces cas figent les deux, pour que l'introduction d'une
/// formule d'évasion les fasse échouer et ramène quelqu'un ici.
///
/// UNE PRÉCISION SUR LE PARTAGE DES RÔLES, trouvée en sabotant. La façade
/// protège si bien le runtime que la branche « dresseur » de l'expression du
/// moteur est INATTEIGNABLE par ce chemin : la fausser ne change rien ici,
/// puisque la décision est refusée avant. Cette branche n'est vivante que pour
/// un appelant qui parle au moteur sans passer par la façade, ce que fait
/// `psdk_misc_action_test` dans map_battle. Ce fichier certifie donc la surface
/// runtime, et cet autre test la seconde ligne de défense — aucun des deux ne
/// couvre le rôle de l'autre.

void main() {
  group('BETA-BAT-008 fleeing is deterministic, not a dice roll', () {
    test('a trainer battle refuses the decision before the engine sees it', () {
      final session = _session(isTrainerBattle: true);

      expect(
        () => session.submitDecision(const BattleDecision.flee()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(
        session.state.isFinished,
        isFalse,
        reason: describeBattleFailure(session: session, initialSeeds: _seeds),
      );
      expect(session.state.outcome, isNull);
    });

    test('a wild battle that forbids flight refuses it the same way', () {
      final session = _session(isTrainerBattle: false, canFlee: false);

      expect(
        () => session.submitDecision(const BattleDecision.flee()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      // Et une seconde fois : rien n'accumule, rien ne s'améliore.
      expect(
        () => session.submitDecision(const BattleDecision.flee()),
        throwsA(isA<BattleDecisionRejectedError>()),
      );
      expect(session.state.isFinished, isFalse);
      expect(session.state.outcome, isNull);
    });

    test('a permitted flight succeeds on the very first attempt', () {
      final session = _session(isTrainerBattle: false, canFlee: true);

      final result = session.submitDecision(const BattleDecision.flee());

      expect(_fleeSucceeded(result), isTrue);
      expect(session.state.outcome?.kind, BattleEngineOutcomeKind.fled);
    });

    test('there is no second attempt after a permitted flight', () {
      // La preuve directe que « échouée puis réussie » n'existe pas : la
      // première tentative permise met fin au combat, donc il n'y a pas de tour
      // suivant où une seconde tentative pourrait vivre.
      final session = _session(isTrainerBattle: false, canFlee: true);
      session.submitDecision(const BattleDecision.flee());

      expect(session.state.isFinished, isTrue);
      expect(
        () => session.submitDecision(const BattleDecision.flee()),
        throwsA(anything),
        reason: 'a finished battle accepts nothing more',
      );
    });
  });
}

bool _fleeSucceeded(BattleEngineTurnResult result) {
  final attempts = result.timeline.events
      .whereType<BattleFleeAttemptTimelineEvent>()
      .toList(growable: false);
  expect(attempts, isNotEmpty, reason: 'the turn must record its attempt');
  return attempts.last.succeeded;
}

const _seeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 1,
  generic: 4,
);

RuntimePsdkBattleSessionAdapter _session({
  required bool isTrainerBattle,
  bool canFlee = false,
}) {
  return RuntimePsdkBattleSessionAdapter.fromSetup(
    PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(id: 'player', speed: 200),
      opponent: _combatant(id: 'opponent', speed: 1),
      rngSeeds: _seeds,
      isTrainerBattle: isTrainerBattle,
      canFlee: canFlee,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: 400,
    currentHp: 400,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 20,
      defense: 200,
      specialAttack: 20,
      specialDefense: 200,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 10,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
