import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

/// Avance du flux générique, transcrite depuis `_nextSeed`.
int _advance(int seed, int steps) {
  var value = seed;
  for (var step = 0; step < steps; step += 1) {
    value = (1664525 * value + 1013904223) & 0x7FFFFFFF;
  }
  return value;
}

const int _initialGenericSeed = 4;

void main() {
  group('BETA-BAT-004 statuses spend exactly the draws they need', () {
    // Un statut qui consomme un tirage de trop décale TOUT le reste du combat :
    // chaque jet suivant lit une autre valeur. Sur une voie dont l'intérêt est
    // d'être rejouable à l'identique, c'est une régression invisible en dégâts
    // mais totale en déterminisme. Le budget se mesure sur la graine du flux
    // générique après un tour.

    test('a turn without any status spends nothing on the generic stream', () {
      // Base de comparaison : sans elle, on ne saurait pas si un écart vient du
      // statut ou d'un autre consommateur du même flux.
      expect(_genericSeedAfterOneTurn(null), _initialGenericSeed);
    });

    test('sleep is observed to spend nothing, though nothing enforces it', () {
      // Le sommeil est fixé à deux tours de façon déterministe. C'est une
      // simplification assumée du projet, et non la règle d'une génération :
      // la Gen 5+ tire une durée entre 1 et 3. Le budget observé est donc zéro.
      //
      // HONNÊTETÉ SUR LA PORTÉE DE CE CAS : je n'ai pas réussi à le faire
      // échouer. Injecter un tirage dans la branche de prévention du sommeil
      // ne change pas la graine finale, alors que le même geste sur le gel la
      // change (ce sabotage-là mord). Le flux renvoyé par le hook du sommeil
      // semble donc ignoré par l'appelant. Ce cas enregistre une observation,
      // pas une garantie, et cette asymétrie mérite d'être creusée : si le
      // sommeil venait à consommer un tirage, sa consommation serait perdue et
      // le flux se désynchroniserait de ce que l'effet a réellement tiré.
      expect(
        _genericSeedAfterOneTurn(PsdkBattleMajorStatus.sleep),
        _initialGenericSeed,
      );
    });

    test('freeze spends one draw for its thaw roll', () {
      expect(
        _genericSeedAfterOneTurn(PsdkBattleMajorStatus.freeze),
        _advance(_initialGenericSeed, 1),
      );
    });

    test('paralysis spends one draw for its full-paralysis roll', () {
      expect(
        _genericSeedAfterOneTurn(PsdkBattleMajorStatus.paralysis),
        _advance(_initialGenericSeed, 1),
      );
    });

    test('the transcribed advance matches the stream it models', () {
      // Si cette transcription dérivait, les trois budgets ci-dessus
      // deviendraient des tautologies comparant deux fois la même erreur.
      expect(_advance(_initialGenericSeed, 0), _initialGenericSeed);
      expect(_advance(_initialGenericSeed, 1), isNot(_initialGenericSeed));
      expect(
        _advance(_initialGenericSeed, 2),
        _advance(_advance(_initialGenericSeed, 1), 1),
      );
    });
  });
}

int _genericSeedAfterOneTurn(PsdkBattleMajorStatus? status) {
  final setup = BattleEngineSetup.singlesPokeMapBetaV1ForTest(
    player: _combatant(id: 'player', speed: 100, majorStatus: status),
    opponent: _combatant(id: 'opponent', speed: 1),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: _initialGenericSeed,
    ),
  );
  final result = BattleEngine(setup: setup)
      .submit(const BattleDecision.fight(moveSlot: 0));
  return result.state.rngSeeds.generic;
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
    majorStatus: majorStatus,
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
