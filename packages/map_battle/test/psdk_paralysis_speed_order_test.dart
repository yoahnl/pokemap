import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BETA-BAT-004 paralysis halves speed on the real turn order', () {
    // La correction 9948c9c08 a fait passer la vitesse sous paralysie de 0.25
    // (générations 1 à 6) à 0.5 (Gen 7+), la valeur de la génération que le
    // ruleset déclare. Elle est restée SANS TEST, ce que la clôture de
    // BETA-BAT-001 a consigné explicitement : la verrouiller demandait un test
    // d'ordonnancement par le vrai chemin de combat plutôt qu'une API de
    // production ajoutée pour l'occasion.
    //
    // Les trois vitesses ci-dessous encadrent la valeur des deux côtés :
    //   90 -> 45 sous paralysie, donc sous les 60 de l'adversaire ;
    //   130 -> 65, donc encore au-dessus ;
    //   240 -> 60 sous l'ancien 0.25, ce qui n'aurait pas suffi à départager.
    // Un 0.25 rendrait le premier cas identique et ferait basculer le second.

    test('a paralyzed attacker loses the initiative it had', () {
      expect(_firstMover(playerSpeed: 90), 'player');
      expect(_firstMover(playerSpeed: 90, paralyzed: true), 'opponent');
    });

    test('halving is not enough to lose a large speed advantage', () {
      // 130 / 2 = 65 > 60. Sous l'ancien quart, 130 / 4 = 32 aurait perdu
      // l'initiative : ce cas distingue 0.5 de 0.25 dans l'autre sens.
      expect(_firstMover(playerSpeed: 130, paralyzed: true), 'player');
    });

    test('the halving is pinned to the point by a tight bracket', () {
      // Adversaire à 60. 118 / 2 = 59, juste en dessous ; 122 / 2 = 61, juste
      // au-dessus. Cet encadrement ne laisse passer aucun autre facteur :
      // sous 0.25 les deux passeraient second, sans halving les deux
      // passeraient premier.
      expect(_firstMover(playerSpeed: 118, paralyzed: true), 'opponent');
      expect(_firstMover(playerSpeed: 122, paralyzed: true), 'player');
    });

    test('a barely mobile paralyzed attacker still resolves its turn', () {
      // Le plancher à 1 de la vitesse paralysée n'est pas observable par
      // l'ordre des tours : à 0 comme à 1, l'adversaire passe devant. Ce que
      // ce cas garantit, c'est qu'une vitesse écrasée ne rend pas le tour
      // indéterminé ni ne le fait échouer.
      expect(_firstMover(playerSpeed: 1, paralyzed: true), 'opponent');
    });

  });
}

String _firstMover({required int playerSpeed, bool paralyzed = false}) {
  final setup = BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(
      id: 'player',
      speed: playerSpeed,
      majorStatus: paralyzed ? PsdkBattleMajorStatus.paralysis : null,
    ),
    opponent: _combatant(id: 'opponent', speed: 60),
    rngSeeds: const BattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      // La paralysie totale est un tirage sur 1/4 ; cette graine le passe, si
      // bien que le test mesure l'ordre et non un tour perdu.
      generic: 7,
    ).psdkSeeds,
  );

  final result = BattleEngine(setup: setup)
      .submit(const BattleDecision.fight(moveSlot: 0));
  final declarations = result.timeline.psdkTimeline.events
      .whereType<PsdkBattleMoveDeclaredEvent>()
      .toList(growable: false);

  expect(
    declarations,
    isNotEmpty,
    reason: 'a turn with no declared move cannot be ordered',
  );
  return declarations.first.user == psdkPlayerSlot ? 'player' : 'opponent';
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int speed,
  PsdkBattleMajorStatus? majorStatus,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 200,
    currentHp: 200,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    majorStatus: majorStatus,
    moves: <PsdkBattleMoveData>[
      PsdkBattleMoveData(
        id: 'tackle',
        dbSymbol: 'tackle',
        name: 'Tackle',
        type: 'normal',
        category: PsdkBattleMoveCategory.physical,
        power: 40,
        accuracy: 100,
        pp: 35,
        priority: 0,
        battleEngineMethod: 's_basic',
        target: PsdkBattleMoveTarget.adjacentFoe,
      ),
    ],
  );
}
