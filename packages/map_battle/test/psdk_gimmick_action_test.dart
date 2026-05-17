import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Mega and form gimmick actions', () {
    test('eligible battler mega evolves before a regular move', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-charizard',
            speciesId: 'charizard',
            hp: 120,
            currentHp: 80,
            abilityId: 'blaze',
          ),
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      final result = engine.submit(
        BattleDecision.mega(form: _megaForm()),
      );

      final active = result.state.battlerAt(psdkPlayerSlot);
      expect(active.speciesId, 'charizard_mega_x');
      expect(active.displayName, 'Charizard Mega X');
      expect(active.types.primary, 'fire');
      expect(active.types.secondary, 'dragon');
      expect(active.stats.attack, 130);
      expect(active.abilityId, 'tough_claws');
      expect(active.currentHp, 80);
      expect(active.maxHp, 120);
      expect(result.state.psdkState.hasMegaEvolvedBank(0), isTrue);
      expect(
        result.timeline.events
            .whereType<BattleEffectTimelineEvent>()
            .map((event) => event.effectId),
        contains('mega:charizard_mega_x'),
      );

      final megaIndex = result.timeline.events.indexWhere(
        (event) =>
            event is BattleEffectTimelineEvent &&
            event.effectId == 'mega:charizard_mega_x',
      );
      final moveIndex = result.timeline.events.indexWhere(
        (event) => event is BattleMovePpSpentTimelineEvent,
      );
      expect(megaIndex, lessThan(moveIndex));
    });

    test('ineligible battler fails without mutating the turn', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-venusaur',
            speciesId: 'venusaur',
            hp: 100,
            abilityId: 'overgrow',
          ),
        ),
      );

      expect(
        () => engine.submit(BattleDecision.mega(form: _megaForm())),
        throwsStateError,
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().battlerAt(psdkPlayerSlot).speciesId, 'venusaur');
      expect(engine.snapshot().psdkState.hasMegaEvolvedBank(0), isFalse);
    });

    test('once-per-battle rule rejects a second mega action for the bank', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-charizard',
            speciesId: 'charizard',
            hp: 120,
            abilityId: 'blaze',
          ),
          opponentMoves: <PsdkBattleMoveData>[_move(id: 'wait', power: 0)],
        ),
      );

      engine.submit(BattleDecision.mega(form: _megaForm()));

      expect(
        () => engine.submit(
          BattleDecision.mega(
            form: _megaForm(
              speciesId: 'charizard_mega_y',
              displayName: 'Charizard Mega Y',
            ),
          ),
        ),
        throwsStateError,
      );
      expect(engine.snapshot().battlerAt(psdkPlayerSlot).speciesId,
          'charizard_mega_x');
      expect(engine.snapshot().psdkState.hasMegaEvolvedBank(0), isTrue);
    });
  });
}

PsdkBattleMegaEvolution _megaForm({
  String speciesId = 'charizard_mega_x',
  String displayName = 'Charizard Mega X',
}) {
  return PsdkBattleMegaEvolution(
    requiredSpeciesId: 'charizard',
    speciesId: speciesId,
    displayName: displayName,
    types: const PsdkBattleTypes(primary: 'fire', secondary: 'dragon'),
    stats: const PsdkBattleStats(
      attack: 130,
      defense: 111,
      specialAttack: 130,
      specialDefense: 85,
      speed: 100,
    ),
    abilityId: 'tough_claws',
  );
}

BattleEngineSetup _setup({
  required PsdkBattleCombatantSetup player,
  PsdkBattleCombatantSetup? opponent,
  List<PsdkBattleMoveData>? opponentMoves,
}) {
  return BattleEngineSetup.singles(
    player: player,
    opponent: opponent ??
        _combatant(
          id: 'opponent-rattata',
          speciesId: 'rattata',
          hp: 70,
          moves: opponentMoves,
        ),
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
  required String speciesId,
  required int hp,
  int? currentHp,
  String? abilityId,
  List<PsdkBattleMoveData>? moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 50,
    maxHp: hp,
    currentHp: currentHp ?? hp,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 80,
      defense: 80,
      specialAttack: 80,
      specialDefense: 80,
      speed: 80,
    ),
    abilityId: abilityId,
    moves: moves ?? <PsdkBattleMoveData>[_move(id: 'tackle', power: 40)],
  );
}

PsdkBattleMoveData _move({
  required String id,
  required int power,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
