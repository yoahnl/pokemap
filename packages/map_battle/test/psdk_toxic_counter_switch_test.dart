import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('BETA-BAT-004 the toxic counter across a switch', () {
    test('a badly poisoned battler keeps its status when it comes back', () {
      // Le statut majeur est persistant : il traverse le changement. C'est le
      // compteur, et lui seul, qui est en question dans le test suivant.
      final engine = _engine();
      _tickToRaiseTheCounter(engine);

      engine.submit(const BattleDecision.switchPokemon(partyIndex: 1));
      final back = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 0),
      );

      expect(
        back.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.toxic,
        reason: 'toxic is a persistent status, a switch does not cure it',
      );
    });

    test('the counter dies with the trip to the bench', () {
      // Le compteur de poison grave repart de zéro au retour, comme dans PSDK
      // et dans la série principale. Il vit ici sur le combattant et non dans
      // l'effet de statut, si bien que vider la pile d'effets ne suffisait pas :
      // un Pokémon qui sortait à 4/16 revenait à 4/16, soit quatre fois trop de
      // dégâts résiduels. Corrigé le 2026-08-18 après arbitrage de Yoahn.
      final engine = _engine();
      final raised = _tickToRaiseTheCounter(engine);
      final counterBefore = raised.state.battlerAt(psdkPlayerSlot).toxicCounter;
      expect(
        counterBefore,
        greaterThan(1),
        reason: 'the vector is pointless if the counter never grew',
      );

      engine.submit(const BattleDecision.switchPokemon(partyIndex: 1));
      final back = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 0),
      );

      expect(
        back.state.battlerAt(psdkPlayerSlot).toxicCounter,
        lessThan(counterBefore),
        reason: 'coming back must not resume where the poison left off',
      );
      expect(
        back.state.battlerAt(psdkPlayerSlot).majorStatus,
        PsdkBattleMajorStatus.toxic,
        reason: 'resetting the counter must not cure the status itself',
      );
    });

    test('the replacement that comes in is not poisoned itself', () {
      // Contrôle que le changement a réellement eu lieu : sans lui, les deux
      // cas précédents pourraient lire le même combattant du début à la fin.
      final engine = _engine();
      _tickToRaiseTheCounter(engine);

      final benched = engine.submit(
        const BattleDecision.switchPokemon(partyIndex: 1),
      );

      expect(benched.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(benched.state.battlerAt(psdkPlayerSlot).toxicCounter, 0);
    });

  });
}

BattleEngine _engine() {
  return BattleEngine(
    setup: BattleEngineSetup.singlesPokeMapBetaV1ForTest(
      player: _combatant(
        id: 'poisoned',
        majorStatus: PsdkBattleMajorStatus.toxic,
        toxicCounter: 1,
      ),
      playerReserves: <PsdkBattleCombatantSetup>[
        _combatant(id: 'reserve'),
      ],
      opponent: _combatant(id: 'opponent', speed: 1),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
    ),
  );
}

/// Fait tourner assez de tours pour que le compteur dépasse sa valeur initiale.
BattleEngineTurnResult _tickToRaiseTheCounter(BattleEngine engine) {
  late BattleEngineTurnResult result;
  for (var turn = 0; turn < 3; turn += 1) {
    result = engine.submit(const BattleDecision.fight(moveSlot: 0));
  }
  return result;
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  int speed = 50,
  PsdkBattleMajorStatus? majorStatus,
  int toxicCounter = 0,
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
    toxicCounter: toxicCounter,
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
