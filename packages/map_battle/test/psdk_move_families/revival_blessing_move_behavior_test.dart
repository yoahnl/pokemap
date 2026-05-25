import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Revival Blessing move behavior', () {
    test('s_revival_blessing fails before PP when no ally is fainted', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(id: 'healthy-reserve', level: 30, currentHp: 40),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final failures = result.timeline.events
          .whereType<PsdkBattleMoveFailedEvent>()
          .where((event) => event.moveId == 'revival_blessing')
          .toList(growable: false);

      expect(failures, hasLength(1));
      expect(
        failures.single.reason,
        BattleMoveFailureReason.unusableByUser.jsonName,
      );
      expect(
        result.timeline.events
            .whereType<PsdkBattleMovePpSpentEvent>()
            .where((event) => event.moveId == 'revival_blessing'),
        isEmpty,
      );
      expect(result.state.partyForBank(0)[1].currentHp, 40);
    });

    test('s_revival_blessing revives the highest-level fainted ally to half HP',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'low-level-fainted',
              level: 10,
              maxHp: 80,
              currentHp: 0,
            ),
            _combatant(
              id: 'high-level-fainted',
              level: 50,
              maxHp: 101,
              currentHp: 0,
            ),
            _combatant(id: 'healthy-reserve', level: 60, currentHp: 100),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final party = result.state.partyForBank(0);
      final reviveEvents = result.timeline.events
          .where((event) => event.kind == 'revive')
          .toList(growable: false);

      expect(party[1].currentHp, 0);
      expect(party[2].id, 'high-level-fainted');
      expect(party[2].currentHp, 50);
      expect(party[3].currentHp, 100);
      expect(reviveEvents, hasLength(1));
      expect(reviveEvents.single.toJson(), containsPair('bank', 0));
      expect(reviveEvents.single.toJson(), containsPair('partyIndex', 2));
      expect(reviveEvents.single.toJson(), containsPair('amount', 50));
    });

    test('s_revival_blessing ignores fainted Pokemon on the opposing bank', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          opponentReserves: <PsdkBattleCombatantSetup>[
            _combatant(
              id: 'opponent-fainted',
              level: 70,
              currentHp: 0,
            ),
          ],
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(
        result.timeline.events
            .whereType<PsdkBattleMoveFailedEvent>()
            .where((event) => event.moveId == 'revival_blessing'),
        hasLength(1),
      );
      expect(result.state.partyForBank(1)[1].currentHp, 0);
    });
  });
}

PsdkBattleSetup _setup({
  List<PsdkBattleCombatantSetup> playerReserves =
      const <PsdkBattleCombatantSetup>[],
  List<PsdkBattleCombatantSetup> opponentReserves =
      const <PsdkBattleCombatantSetup>[],
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      level: 40,
      moves: <PsdkBattleMoveData>[_revivalBlessing()],
    ),
    opponent: _combatant(
      id: 'opponent',
      level: 40,
      speed: 1,
      moves: <PsdkBattleMoveData>[_splash()],
    ),
    playerReserves: playerReserves,
    opponentReserves: opponentReserves,
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required int level,
  int maxHp = 100,
  int currentHp = 100,
  int speed = 100,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    moves: moves ?? <PsdkBattleMoveData>[_splash()],
  );
}

PsdkBattleMoveData _revivalBlessing() {
  return PsdkBattleMoveData(
    id: 'revival_blessing',
    dbSymbol: 'revival_blessing',
    name: 'Revival Blessing',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 1,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_revival_blessing',
    target: PsdkBattleMoveTarget.user,
  );
}

PsdkBattleMoveData _splash() {
  return PsdkBattleMoveData(
    id: 'splash',
    dbSymbol: 'splash',
    name: 'Splash',
    type: 'normal',
    category: PsdkBattleMoveCategory.status,
    power: 0,
    accuracy: 0,
    pp: 40,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: 's_splash',
    target: PsdkBattleMoveTarget.none,
  );
}
