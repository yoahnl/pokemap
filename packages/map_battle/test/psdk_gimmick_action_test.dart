import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK Mega and form gimmick actions', () {
    test('canonical beta ruleset refuses an eligible mega action', () {
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

      expect(
        () => engine.submit(BattleDecision.mega(form: _megaForm())),
        throwsA(isA<PokemonRulesetFeatureDisabledError>()),
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(
          engine.snapshot().battlerAt(psdkPlayerSlot).speciesId, 'charizard');
      expect(engine.snapshot().psdkState.hasMegaEvolvedBank(0), isFalse);
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
        throwsA(isA<PokemonRulesetFeatureDisabledError>()),
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().battlerAt(psdkPlayerSlot).speciesId, 'venusaur');
      expect(engine.snapshot().psdkState.hasMegaEvolvedBank(0), isFalse);
    });

    test('repeated disabled mega commands stay side-effect free', () {
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

      for (var attempt = 0; attempt < 2; attempt += 1) {
        expect(
          () => engine.submit(BattleDecision.mega(form: _megaForm())),
          throwsA(isA<PokemonRulesetFeatureDisabledError>()),
        );
      }

      expect(engine.snapshot().turnNumber, 0);
      expect(
          engine.snapshot().battlerAt(psdkPlayerSlot).speciesId, 'charizard');
      expect(engine.snapshot().psdkState.hasMegaEvolvedBank(0), isFalse);
    });

    test('canonical beta ruleset refuses a direct Z-move command', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-pikachu',
            speciesId: 'pikachu',
            hp: 80,
            moves: <PsdkBattleMoveData>[
              _move(
                id: 'catastropika',
                power: 210,
                battleEngineMethod: 's_z_move',
              ),
            ],
          ),
        ),
      );

      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<PokemonRulesetFeatureDisabledError>()),
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().psdkState.hasZMoveUsedBank(0), isFalse);
    });

    test('canonical beta ruleset refuses an opponent Z-move command', () {
      final engine = BattleEngine(
        setup: _setup(
          player: _combatant(
            id: 'player-pikachu',
            speciesId: 'pikachu',
            hp: 80,
          ),
          opponentMoves: <PsdkBattleMoveData>[
            _move(
              id: 'catastropika',
              power: 210,
              battleEngineMethod: 's_z_move',
            ),
          ],
        ),
      );

      expect(
        () => engine.submit(const BattleDecision.fight(moveSlot: 0)),
        throwsA(isA<PokemonRulesetFeatureDisabledError>()),
      );
      expect(engine.snapshot().turnNumber, 0);
      expect(engine.snapshot().psdkState.hasZMoveUsedBank(1), isFalse);
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
  return BattleEngineSetup.singlesPokeMapBetaV1ForTest(
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
  String battleEngineMethod = 's_basic',
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
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}
