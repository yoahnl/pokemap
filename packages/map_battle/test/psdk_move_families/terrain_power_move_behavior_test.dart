import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK terrain-powered move families', () {
    test('s_terrain_boosting boosts Psyblade only on Electric Terrain', () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'psyblade',
          type: 'psychic',
          power: 80,
          battleEngineMethod: 's_terrain_boosting',
        ),
      );
      final electricTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'psyblade',
          type: 'psychic',
          power: 80,
          battleEngineMethod: 's_terrain_boosting',
        ),
      );
      final grassyTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'psyblade',
          type: 'psychic',
          power: 80,
          battleEngineMethod: 's_terrain_boosting',
        ),
      );

      expect(
        _damage(electricTerrain, moveId: 'psyblade'),
        greaterThan(_damage(noTerrain, moveId: 'psyblade')),
      );
      expect(
        _damage(grassyTerrain, moveId: 'psyblade'),
        _damage(noTerrain, moveId: 'psyblade'),
      );
    });

    test(
        's_expanding_force is boosted only for grounded user on Psychic Terrain',
        () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'expanding_force',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_expanding_force',
        ),
      );
      final psychicTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.psychicTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'expanding_force',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_expanding_force',
        ),
      );
      final airborneUser = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.psychicTerrain,
            remainingTurns: 5,
          ),
        ),
        playerTypes: const PsdkBattleTypes(primary: 'flying'),
        playerMove: _move(
          id: 'expanding_force',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          battleEngineMethod: 's_expanding_force',
        ),
      );

      expect(
        _damage(psychicTerrain, moveId: 'expanding_force'),
        greaterThan(_damage(noTerrain, moveId: 'expanding_force')),
      );
      expect(
        _damage(airborneUser, moveId: 'expanding_force'),
        _damage(noTerrain, moveId: 'expanding_force'),
      );
    });

    test(
        's_rising_voltage doubles power only against grounded targets on Electric Terrain',
        () {
      final groundedNoTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'rising_voltage',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 70,
          battleEngineMethod: 's_rising_voltage',
        ),
      );
      final airborneNoTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        opponentHeldItemId: 'air_balloon',
        playerMove: _move(
          id: 'rising_voltage',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 70,
          battleEngineMethod: 's_rising_voltage',
        ),
      );
      final groundedTarget = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'rising_voltage',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 70,
          battleEngineMethod: 's_rising_voltage',
        ),
      );
      final airborneTarget = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        opponentHeldItemId: 'air_balloon',
        playerMove: _move(
          id: 'rising_voltage',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 70,
          battleEngineMethod: 's_rising_voltage',
        ),
      );

      expect(
        _damage(groundedTarget, moveId: 'rising_voltage'),
        greaterThan(_damage(groundedNoTerrain, moveId: 'rising_voltage')),
      );
      expect(
        _damage(airborneTarget, moveId: 'rising_voltage'),
        greaterThan(_damage(airborneNoTerrain, moveId: 'rising_voltage')),
      );
      expect(
        _damage(groundedTarget, moveId: 'rising_voltage'),
        greaterThan(_damage(airborneTarget, moveId: 'rising_voltage')),
      );
    });

    test('s_terrain_pulse changes type and doubles power on active terrain',
        () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'terrain_pulse',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_terrain_pulse',
        ),
      );
      final electricTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'terrain_pulse',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_terrain_pulse',
        ),
      );
      final airborneUser = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerTypes: const PsdkBattleTypes(primary: 'flying'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'terrain_pulse',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_terrain_pulse',
        ),
      );

      expect(
        _damage(electricTerrain, moveId: 'terrain_pulse'),
        greaterThan(_damage(noTerrain, moveId: 'terrain_pulse')),
      );
      expect(
        _damage(airborneUser, moveId: 'terrain_pulse'),
        greaterThan(_damage(noTerrain, moveId: 'terrain_pulse')),
      );
      expect(
        _damage(electricTerrain, moveId: 'terrain_pulse'),
        greaterThan(_damage(airborneUser, moveId: 'terrain_pulse')),
      );
    });

    test('s_terrain_pulse keeps terrain type changes for airborne users', () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerTypes: const PsdkBattleTypes(primary: 'flying'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'terrain_pulse',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_terrain_pulse',
        ),
      );
      final airborneElectricTerrain = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerTypes: const PsdkBattleTypes(primary: 'flying'),
        opponentTypes: const PsdkBattleTypes(primary: 'water'),
        playerMove: _move(
          id: 'terrain_pulse',
          type: 'normal',
          category: PsdkBattleMoveCategory.special,
          power: 50,
          battleEngineMethod: 's_terrain_pulse',
        ),
      );

      expect(
        _damage(airborneElectricTerrain, moveId: 'terrain_pulse'),
        greaterThan(_damage(noTerrain, moveId: 'terrain_pulse')),
      );
    });

    test('Electric Terrain boosts grounded Electric moves only', () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'thunderbolt',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      );
      final grounded = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'thunderbolt',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      );
      final airborne = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerTypes: const PsdkBattleTypes(primary: 'flying'),
        playerMove: _move(
          id: 'thunderbolt',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 90,
        ),
      );

      expect(
        _damage(grounded, moveId: 'thunderbolt'),
        greaterThan(_damage(noTerrain, moveId: 'thunderbolt')),
      );
      expect(
        _damage(airborne, moveId: 'thunderbolt'),
        _damage(noTerrain, moveId: 'thunderbolt'),
      );
    });

    test('Misty Terrain halves Dragon damage against grounded targets only',
        () {
      final noTerrain = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'dragon_pulse',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 85,
        ),
      );
      final groundedTarget = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.mistyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'dragon_pulse',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 85,
        ),
      );
      final airborneTarget = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.mistyTerrain,
            remainingTurns: 5,
          ),
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        playerMove: _move(
          id: 'dragon_pulse',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 85,
        ),
      );

      expect(
        _damage(groundedTarget, moveId: 'dragon_pulse'),
        lessThan(_damage(noTerrain, moveId: 'dragon_pulse')),
      );
      expect(
        _damage(airborneTarget, moveId: 'dragon_pulse'),
        _damage(noTerrain, moveId: 'dragon_pulse'),
      );
    });

    test('s_grassy_glide gains priority for grounded users on Grassy Terrain',
        () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerSpeed: 1,
        opponentSpeed: 100,
        playerMove: _move(
          id: 'grassy_glide',
          type: 'grass',
          power: 55,
          battleEngineMethod: 's_grassy_glide',
        ),
        opponentMove: _move(
          id: 'opponent_tackle',
          power: 40,
        ),
      );

      expect(
        _declaredMoveIds(result).take(2).toList(growable: false),
        <String>['grassy_glide', 'opponent_tackle'],
      );
    });

    test('Psychic Terrain blocks priority moves against grounded targets', () {
      final groundedTarget = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.psychicTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'quick_attack',
          power: 40,
          priority: 1,
        ),
      );
      final airborneTarget = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.psychicTerrain,
            remainingTurns: 5,
          ),
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        playerMove: _move(
          id: 'quick_attack',
          power: 40,
          priority: 1,
        ),
      );

      expect(_damageEvents(groundedTarget, moveId: 'quick_attack'), isEmpty);
      expect(
        groundedTarget.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isNotEmpty,
      );
      expect(
        _damage(airborneTarget, moveId: 'quick_attack'),
        greaterThan(0),
      );
    });

    test('Grassy Terrain heals grounded battlers at end turn before expiring',
        () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 2,
          ),
        ),
        playerCurrentHp: 50,
        opponentCurrentHp: 50,
        opponentTypes: const PsdkBattleTypes(primary: 'flying'),
        playerMove: _move(
          id: 'splash',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 56);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 50);
      expect(
        result.timeline.events
            .whereType<PsdkBattleHealEvent>()
            .map((event) => event.moveId),
        contains('terrain:grassy_terrain'),
      );
      expect(result.state.field.terrain?.remainingTurns, 1);
    });

    test('s_terrain applies Terrain Extender duration', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(),
        playerHeldItemId: 'terrain_extender',
        playerMove: _move(
          id: 'electric_terrain',
          type: 'electric',
          power: 0,
          accuracy: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_terrain',
          target: PsdkBattleMoveTarget.user,
        ),
      );

      expect(
          result.state.field.terrain?.id, PsdkBattleTerrainId.electricTerrain);
      expect(result.state.field.terrain?.remainingTurns, 7);
      expect(
        result.timeline.events
            .whereType<PsdkBattleTerrainChangedEvent>()
            .single
            .remainingTurns,
        8,
      );
    });

    test('s_ice_spinner clears active terrain after a successful hit', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.electricTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'ice_spinner',
          type: 'ice',
          power: 80,
          battleEngineMethod: 's_ice_spinner',
        ),
      );

      expect(_damage(result, moveId: 'ice_spinner'), greaterThan(0));
      expect(result.state.field.terrain, isNull);
      expect(
        result.timeline.events
            .whereType<PsdkBattleTerrainChangedEvent>()
            .map((event) => event.terrain),
        contains(null),
      );
    });

    test('s_steel_roller fails before damage when no terrain is active', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(),
        playerMove: _move(
          id: 'steel_roller',
          type: 'steel',
          power: 130,
          battleEngineMethod: 's_steel_roller',
        ),
      );

      expect(
        result.timeline.events.whereType<PsdkBattleDamageEvent>(),
        isEmpty,
      );
      expect(
        result.timeline.events.whereType<PsdkBattleMoveFailedEvent>(),
        isNotEmpty,
      );
    });

    test('s_steel_roller clears active terrain after a successful hit', () {
      final result = _runMove(
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 5,
          ),
        ),
        playerMove: _move(
          id: 'steel_roller',
          type: 'steel',
          power: 130,
          battleEngineMethod: 's_steel_roller',
        ),
      );

      expect(_damage(result, moveId: 'steel_roller'), greaterThan(0));
      expect(result.state.field.terrain, isNull);
      expect(
        result.timeline.events
            .whereType<PsdkBattleTerrainChangedEvent>()
            .map((event) => event.terrain),
        contains(null),
      );
    });
  });
}

PsdkBattleTurnResult _runMove({
  required PsdkBattleFieldState field,
  required PsdkBattleMoveData playerMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'fire'),
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
  int playerCurrentHp = 100,
  int opponentCurrentHp = 100,
  int playerSpeed = 100,
  int opponentSpeed = 1,
  String? playerHeldItemId,
  String? opponentHeldItemId,
}) {
  final engine = PsdkBattleEngine(
    setup: PsdkBattleSetup.singles(
      player: _combatant(
        id: 'player',
        types: playerTypes,
        speed: playerSpeed,
        move: playerMove,
        currentHp: playerCurrentHp,
        heldItemId: playerHeldItemId,
      ),
      opponent: _combatant(
        id: 'opponent',
        types: opponentTypes,
        speed: opponentSpeed,
        currentHp: opponentCurrentHp,
        heldItemId: opponentHeldItemId,
        move: opponentMove ??
            _move(
              id: 'opponent_wait',
              power: 0,
              accuracy: 0,
              category: PsdkBattleMoveCategory.status,
              battleEngineMethod: 's_splash',
            ),
      ),
      rngSeeds: const PsdkBattleRngSeeds(
        moveDamage: 1,
        moveCritical: 99999,
        moveAccuracy: 3,
        generic: 4,
      ),
      field: field,
    ),
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  required int speed,
  required PsdkBattleMoveData move,
  int currentHp = 100,
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: currentHp,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    heldItemId: heldItemId,
    moves: <PsdkBattleMoveData>[move],
  );
}

List<String> _declaredMoveIds(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleMoveDeclaredEvent>()
      .map((event) => event.moveId)
      .toList(growable: false);
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  int priority = 0,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: accuracy,
    pp: 35,
    priority: priority,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
  );
}

List<PsdkBattleDamageEvent> _damageEvents(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}

int _damage(
  PsdkBattleTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .singleWhere((event) => event.moveId == moveId)
      .damage;
}
