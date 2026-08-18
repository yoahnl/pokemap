import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/application/runtime_psdk_battle_session_adapter.dart';

import 'support/battle_gate_diagnostics.dart';

/// « Un échec fournit timeline et snapshot exploitables » (BETA-BAT-008).
///
/// Ce critère est facile à croire tenu et difficile à vérifier : on ne voit un
/// message d'échec que quand un test échoue. D'où ces cas, qui vérifient le
/// RENDU lui-même — sans quoi l'exploitabilité resterait une affirmation.
///
/// Ce qu'un diagnostic doit permettre : reproduire (les graines), comprendre
/// (l'issue et les PV), et situer (la timeline). Chacun est vérifié séparément,
/// parce qu'un rendu qui perdrait juste les graines resterait plausible à l'œil.
void main() {
  group('BETA-BAT-008 a failing gate hands over something usable', () {
    test('the diagnostic carries the seeds needed to reproduce', () {
      final report = describeBattleFailure(session: _finishedSession(), initialSeeds: _seeds);

      // Les graines INITIALES, celles qui permettent de rejouer. Les lire sur
      // l'état final ne servirait à rien : chaque tirage les a fait avancer.
      expect(report, contains('seeds (initial, replay with these)'));
      expect(report, contains('moveCritical=99999'));
      expect(report, contains('generic=4'));
      expect(report, contains('seeds (now, already advanced)'));
    });

    test('the diagnostic carries the outcome and both sides', () {
      final report = describeBattleFailure(session: _finishedSession(), initialSeeds: _seeds);

      expect(report, contains('outcome: victory'));
      expect(report, contains('finished=true'));
      expect(report, contains('player:'));
      expect(report, contains('enemy:'));
      expect(report, contains('hp='));
    });

    test('the diagnostic carries the timeline of every turn played', () {
      final session = RuntimePsdkBattleSessionAdapter.fromSetup(_setup());
      final turns = <BattleEngineTurnResult>[
        session.submitDecision(const BattleDecision.fight(moveSlot: 0)),
      ];

      final report = describeBattleFailure(session: session, initialSeeds: _seeds, turns: turns);

      expect(report, contains('turn 1:'));
      expect(report, contains('turn_started'));
      expect(report, contains('damage'));
    });

    test('an unfinished battle is described as unfinished, not as a victory',
        () {
      // Un diagnostic qui annoncerait une issue sur un combat en cours
      // enverrait le lecteur chercher au mauvais endroit.
      final report = describeBattleFailure(
        session: RuntimePsdkBattleSessionAdapter.fromSetup(_setup()),
        initialSeeds: _seeds,
      );

      expect(report, contains('outcome: unfinished'));
      expect(report, contains('finished=false'));
    });

    test('the note comes first so the reason is readable before the data', () {
      final report = describeBattleFailure(
        session: _finishedSession(),
        initialSeeds: _seeds,
        note: 'displayed outcome disagrees with the kernel',
      );

      expect(
        report.split('\n').first,
        'displayed outcome disagrees with the kernel',
      );
    });
  });
}

RuntimePsdkBattleSessionAdapter _finishedSession() {
  final session = RuntimePsdkBattleSessionAdapter.fromSetup(_setup());
  var turns = 0;
  while (!session.state.isFinished && turns < 20) {
    session.submitDecision(const BattleDecision.fight(moveSlot: 0));
    turns++;
  }
  return session;
}

const _seeds = PsdkBattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 1,
  generic: 4,
);

PsdkBattleSetup _setup() {
  return PsdkBattleSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(id: 'player', hp: 200, power: 150, speed: 200),
    opponent: _combatant(id: 'opponent', hp: 60, power: 1, speed: 1),
    rngSeeds: _seeds,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int hp,
  required int power,
  required int speed,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 50,
    maxHp: hp,
    currentHp: hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: speed,
    ),
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: power,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
