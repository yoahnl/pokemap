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

    test('the counter carried by the battler survives the switch', () {
      // ÉCART AVEC PSDK ET LA SÉRIE PRINCIPALE, mesuré le 2026-08-18.
      //
      // Dans PSDK le compteur vit DANS l'effet de statut, et _switchOutSnapshot
      // vide la pile d'effets : le compteur repart donc de zéro au retour.
      // Ici, `toxicCounter` est un champ du combattant, que le snapshot de
      // sortie ne touche pas. Un Pokémon qui sort à 4/16 revient à 4/16 au lieu
      // de 1/16.
      //
      // Le ticket demande que le compteur « conserve ou réinitialise selon le
      // ruleset ». Ce test fige le comportement observé pour que l'arbitrage
      // soit fait sur une valeur, pas sur une impression.
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

      final counterAfter = back.state.battlerAt(psdkPlayerSlot).toxicCounter;
      expect(
        counterAfter,
        greaterThanOrEqualTo(counterBefore),
        reason: 'the counter is not reset by the switch, it keeps climbing',
      );
      expect(
        counterAfter,
        isNot(1),
        reason: 'PSDK would show 1 here, its counter dying with the effect',
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
