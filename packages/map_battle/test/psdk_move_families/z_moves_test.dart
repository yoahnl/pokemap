import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK offensive signature Z-Moves', () {
    test('Catastropika requires its signature crystal and source move', () {
      final result = _runZMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'pikanium_z',
        zMove: _zMove(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
        ),
        sourceMove: _sourceMove(id: 'volt_tackle', type: 'electric'),
      );

      expect(_damageEvents(result, moveId: 'catastropika'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Z-Move attempts fail before PP without the matching crystal', () {
      final result = _runZMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'leftovers',
        zMove: _zMove(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
        ),
        sourceMove: _sourceMove(id: 'volt_tackle', type: 'electric'),
      );

      final failures =
          result.timeline.events.whereType<BattleMoveFailedTimelineEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'unusable_by_user');
      expect(_damageEvents(result, moveId: 'catastropika'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
        result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank),
        isFalse,
      );
    });

    test('Z-Move attempts fail before PP when the source move is absent', () {
      final result = _runZMove(
        playerSpeciesId: 'pikachu',
        playerHeldItemId: 'pikanium_z',
        zMove: _zMove(
          id: 'catastropika',
          type: 'electric',
          category: PsdkBattleMoveCategory.physical,
          power: 210,
        ),
      );

      final failures =
          result.timeline.events.whereType<BattleMoveFailedTimelineEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'unusable_by_user');
      expect(_damageEvents(result, moveId: 'catastropika'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
        result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank),
        isFalse,
      );
    });

    test('a bank can use only one offensive signature Z-Move', () {
      final engine = BattleEngine(
        setup: _setup(
          playerSpeciesId: 'pikachu',
          playerHeldItemId: 'pikanium_z',
          playerMoves: <PsdkBattleMoveData>[
            _zMove(
              id: 'catastropika',
              type: 'electric',
              category: PsdkBattleMoveCategory.physical,
              power: 40,
              pp: 2,
            ),
            _sourceMove(id: 'volt_tackle', type: 'electric'),
          ],
        ),
      );

      final first = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final second = engine.submit(const BattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(first, moveId: 'catastropika'), hasLength(1));
      expect(
        second.timeline.events
            .whereType<BattleMoveFailedTimelineEvent>()
            .single
            .reason,
        'unusable_by_user',
      );
      expect(_damageEvents(second, moveId: 'catastropika'), isEmpty);
      expect(second.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
          second.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Searing Sunraze Smash corrects Studio user target to the foe', () {
      final result = _runZMove(
        playerSpeciesId: 'solgaleo',
        playerHeldItemId: 'solganium_z',
        zMove: _zMove(
          id: 'searing_sunraze_smash',
          type: 'steel',
          category: PsdkBattleMoveCategory.physical,
          power: 200,
          target: PsdkBattleMoveTarget.user,
        ),
        sourceMove: _sourceMove(id: 'sunsteel_strike', type: 'steel'),
      );

      expect(
          _damageEvents(result, moveId: 'searing_sunraze_smash'), hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
    });

    test('Stoked Sparksurfer applies its guaranteed paralysis rider', () {
      final result = _runZMove(
        playerSpeciesId: 'raichu_alola',
        playerHeldItemId: 'aloraichium_z',
        zMove: _zMove(
          id: 'stoked_sparksurfer',
          type: 'electric',
          category: PsdkBattleMoveCategory.special,
          power: 175,
          effectChance: 100,
          statuses: <PsdkBattleMoveStatus>[
            PsdkBattleMoveStatus(
              status: PsdkBattleMajorStatus.paralysis,
              chance: 100,
            ),
          ],
        ),
        sourceMove: _sourceMove(id: 'thunderbolt', type: 'electric'),
      );

      expect(_damageEvents(result, moveId: 'stoked_sparksurfer'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).majorStatus,
        PsdkBattleMajorStatus.paralysis,
      );
    });

    test('Clangorous Soulblaze damages then raises all user battle stats', () {
      final result = _runZMove(
        playerSpeciesId: 'kommo_o',
        playerHeldItemId: 'kommonium_z',
        zMove: _zMove(
          id: 'clangorous_soulblaze',
          type: 'dragon',
          category: PsdkBattleMoveCategory.special,
          power: 185,
          battleEngineMethod: 's_self_stat_z_move',
          target: PsdkBattleMoveTarget.allAdjacentFoes,
          sound: true,
          stageMods: _allCombatStatMods(1),
        ),
        sourceMove: _sourceMove(id: 'clanging_scales', type: 'dragon'),
      );

      expect(
          _damageEvents(result, moveId: 'clangorous_soulblaze'), hasLength(1));
      final stages = result.state.battlerAt(psdkPlayerSlot).statStages;
      expect(stages.valueOf('attack'), 1);
      expect(stages.valueOf('defense'), 1);
      expect(stages.valueOf('specialAttack'), 1);
      expect(stages.valueOf('specialDefense'), 1);
      expect(stages.valueOf('speed'), 1);
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Extreme Evoboost raises all user battle stats by two', () {
      final result = _runZMove(
        playerSpeciesId: 'eevee',
        playerHeldItemId: 'eevium_z',
        zMove: _zMove(
          id: 'extreme_evoboost',
          type: 'normal',
          category: PsdkBattleMoveCategory.status,
          power: 0,
          battleEngineMethod: 's_self_stat_z_move',
          target: PsdkBattleMoveTarget.user,
          stageMods: _allCombatStatMods(2),
          kingRockUtility: false,
        ),
        sourceMove: _sourceMove(id: 'last_resort', type: 'normal'),
      );

      expect(_damageEvents(result, moveId: 'extreme_evoboost'), isEmpty);
      final stages = result.state.battlerAt(psdkPlayerSlot).statStages;
      expect(stages.valueOf('attack'), 2);
      expect(stages.valueOf('defense'), 2);
      expect(stages.valueOf('specialAttack'), 2);
      expect(stages.valueOf('specialDefense'), 2);
      expect(stages.valueOf('speed'), 2);
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Genesis Supernova damages then sets Psychic Terrain', () {
      final result = _runZMove(
        playerSpeciesId: 'mew',
        playerHeldItemId: 'mewnium_z',
        zMove: _zMove(
          id: 'genesis_supernova',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 185,
          battleEngineMethod: 's_genesis_supernova',
        ),
        sourceMove: _sourceMove(id: 'psychic', type: 'psychic'),
      );

      expect(_damageEvents(result, moveId: 'genesis_supernova'), hasLength(1));
      expect(result.state.psdkState.field.terrain?.id,
          PsdkBattleTerrainId.psychicTerrain);
      expect(result.state.psdkState.field.terrain?.remainingTurns, 4);
    });

    test('Guardian of Alola deals three quarters of current target HP', () {
      final result = _runZMove(
        playerSpeciesId: 'tapu_koko',
        playerHeldItemId: 'tapunium_z',
        zMove: _zMove(
          id: 'guardian_of_alola',
          type: 'fairy',
          category: PsdkBattleMoveCategory.special,
          power: 0,
          battleEngineMethod: 's_guardian_of_alola',
        ),
        sourceMove: _sourceMove(id: 'nature_s_madness', type: 'fairy'),
      );

      final damage = _damageEvents(result, moveId: 'guardian_of_alola').single;
      expect(damage.damage, 75);
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, 25);
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Hyperspace Hole bypasses Protect without consuming a Z-Move', () {
      final result = _runZMove(
        playerSpeciesId: 'hoopa',
        playerHeldItemId: 'leftovers',
        zMove: _zMove(
          id: 'hyperspace_hole',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 80,
          pp: 5,
          battleEngineMethod: 's_hyperspace_hole',
        ),
        opponentMove: _sourceMove(
          id: 'protect',
          type: 'normal',
          power: 0,
          battleEngineMethod: 's_protect',
          target: PsdkBattleMoveTarget.user,
          priority: 4,
        ),
      );

      expect(_damageEvents(result, moveId: 'hyperspace_hole'), hasLength(1));
      expect(
        result.state.battlerAt(psdkOpponentSlot).effects.contains('protect'),
        isFalse,
      );
      expect(
        result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank),
        isFalse,
      );
    });

    test(
        'Light That Burns the Sky corrects target and uses Photon Geyser stats',
        () {
      final result = _runZMove(
        playerSpeciesId: 'necrozma',
        playerHeldItemId: 'ultranecrozium_z',
        playerForm: 30,
        playerAttack: 180,
        playerSpecialAttack: 40,
        zMove: _zMove(
          id: 'light_that_burns_the_sky',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 200,
          battleEngineMethod: 's_light_that_burns_the_sky',
          target: PsdkBattleMoveTarget.user,
        ),
        sourceMove: _sourceMove(id: 'photon_geyser', type: 'psychic'),
      );

      expect(_damageEvents(result, moveId: 'light_that_burns_the_sky'),
          hasLength(1));
      expect(result.state.battlerAt(psdkOpponentSlot).currentHp, lessThan(100));
      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 100);
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Malicious Moonsault damages and consumes the Incinium Z slot', () {
      final result = _runZMove(
        playerSpeciesId: 'incineroar',
        playerHeldItemId: 'incinium_z',
        zMove: _zMove(
          id: 'malicious_moonsault',
          type: 'dark',
          category: PsdkBattleMoveCategory.physical,
          power: 180,
          battleEngineMethod: 's_malicious_moonsault',
        ),
        sourceMove: _sourceMove(id: 'darkest_lariat', type: 'dark'),
      );

      expect(
          _damageEvents(result, moveId: 'malicious_moonsault'), hasLength(1));
      expect(
          result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank), isTrue);
    });

    test('Splintered Stormshards damages then clears active terrain', () {
      final result = _runZMove(
        playerSpeciesId: 'lycanroc_dusk',
        playerHeldItemId: 'lycanium_z',
        field: const PsdkBattleFieldState(
          terrain: PsdkBattleTerrainState(
            id: PsdkBattleTerrainId.grassyTerrain,
            remainingTurns: 4,
          ),
        ),
        zMove: _zMove(
          id: 'splintered_stormshards',
          type: 'rock',
          category: PsdkBattleMoveCategory.physical,
          power: 190,
          battleEngineMethod: 's_splintered_stormshards',
        ),
        sourceMove: _sourceMove(id: 'stone_edge', type: 'rock'),
      );

      expect(_damageEvents(result, moveId: 'splintered_stormshards'),
          hasLength(1));
      expect(result.state.psdkState.field.terrain, isNull);
    });

    test('custom Studio signature Z-Moves use the same item and source gates',
        () {
      final result = _runZMove(
        playerSpeciesId: 'mew',
        playerHeldItemId: 'leftovers',
        zMove: _zMove(
          id: 'genesis_supernova',
          type: 'psychic',
          category: PsdkBattleMoveCategory.special,
          power: 185,
          battleEngineMethod: 's_genesis_supernova',
        ),
        sourceMove: _sourceMove(id: 'psychic', type: 'psychic'),
      );

      final failures =
          result.timeline.events.whereType<BattleMoveFailedTimelineEvent>();
      expect(failures, hasLength(1));
      expect(failures.single.reason, 'unusable_by_user');
      expect(_damageEvents(result, moveId: 'genesis_supernova'), isEmpty);
      expect(result.state.battlerAt(psdkPlayerSlot).moves.first.currentPp, 1);
      expect(
        result.state.psdkState.hasZMoveUsedBank(psdkPlayerSlot.bank),
        isFalse,
      );
    });
  });
}

BattleEngineTurnResult _runZMove({
  required String playerSpeciesId,
  required String playerHeldItemId,
  required PsdkBattleMoveData zMove,
  PsdkBattleMoveData? sourceMove,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  int playerForm = 0,
  int playerAttack = 80,
  int playerSpecialAttack = 80,
}) {
  final engine = BattleEngine(
    setup: _setup(
      playerSpeciesId: playerSpeciesId,
      playerHeldItemId: playerHeldItemId,
      playerForm: playerForm,
      playerAttack: playerAttack,
      playerSpecialAttack: playerSpecialAttack,
      playerMoves: <PsdkBattleMoveData>[
        zMove,
        if (sourceMove != null) sourceMove,
      ],
      opponentMove: opponentMove,
      field: field,
    ),
  );
  return engine.submit(const BattleDecision.fight(moveSlot: 0));
}

BattleEngineSetup _setup({
  required String playerSpeciesId,
  required String playerHeldItemId,
  required List<PsdkBattleMoveData> playerMoves,
  PsdkBattleMoveData? opponentMove,
  PsdkBattleFieldState field = const PsdkBattleFieldState(),
  int playerForm = 0,
  int playerAttack = 80,
  int playerSpecialAttack = 80,
}) {
  return BattleEngineSetup.singles(
    player: _combatant(
      id: 'player',
      speciesId: playerSpeciesId,
      form: playerForm,
      heldItemId: playerHeldItemId,
      speed: 100,
      attack: playerAttack,
      specialAttack: playerSpecialAttack,
      types: const PsdkBattleTypes(primary: 'electric'),
      moves: playerMoves,
    ),
    opponent: _combatant(
      id: 'opponent',
      speciesId: 'opponent',
      speed: 1,
      types: const PsdkBattleTypes(primary: 'water'),
      moves: <PsdkBattleMoveData>[
        opponentMove ??
            _sourceMove(id: 'opponent_wait', type: 'normal', power: 0),
      ],
    ),
    field: field,
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
  required int speed,
  required PsdkBattleTypes types,
  required List<PsdkBattleMoveData> moves,
  int form = 0,
  int attack = 80,
  int specialAttack = 80,
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    form: form,
    displayName: id,
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: attack,
      defense: 70,
      specialAttack: specialAttack,
      specialDefense: 70,
      speed: speed,
    ),
    heldItemId: heldItemId,
    moves: moves,
  );
}

PsdkBattleMoveData _zMove({
  required String id,
  required String type,
  required PsdkBattleMoveCategory category,
  required int power,
  int pp = 1,
  int criticalRate = 1,
  int? effectChance,
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  List<PsdkBattleMoveStatus> statuses = const <PsdkBattleMoveStatus>[],
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
  String battleEngineMethod = 's_z_move',
  bool sound = false,
  bool kingRockUtility = true,
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 0,
    pp: pp,
    priority: 0,
    criticalRate: criticalRate,
    effectChance: effectChance,
    battleEngineMethod: battleEngineMethod,
    target: target,
    protectable: false,
    sound: sound,
    kingRockUtility: kingRockUtility,
    statuses: statuses,
    stageMods: stageMods,
  );
}

PsdkBattleMoveData _sourceMove({
  required String id,
  required String type,
  int power = 90,
  String? battleEngineMethod,
  PsdkBattleMoveTarget? target,
  int priority = 0,
}) {
  final category = power == 0
      ? PsdkBattleMoveCategory.status
      : PsdkBattleMoveCategory.physical;
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: power == 0 ? 0 : 100,
    pp: 15,
    priority: priority,
    battleEngineMethod:
        battleEngineMethod ?? (power == 0 ? 's_status' : 's_basic'),
    target: target ??
        (power == 0
            ? PsdkBattleMoveTarget.self
            : PsdkBattleMoveTarget.adjacentFoe),
  );
}

List<PsdkBattleMoveStageMod> _allCombatStatMods(int stages) {
  return <PsdkBattleMoveStageMod>[
    PsdkBattleMoveStageMod(stat: 'attack', stages: stages),
    PsdkBattleMoveStageMod(stat: 'defense', stages: stages),
    PsdkBattleMoveStageMod(stat: 'speed', stages: stages),
    PsdkBattleMoveStageMod(stat: 'specialAttack', stages: stages),
    PsdkBattleMoveStageMod(stat: 'specialDefense', stages: stages),
  ];
}

List<BattleDamageTimelineEvent> _damageEvents(
  BattleEngineTurnResult result, {
  required String moveId,
}) {
  return result.timeline.events
      .whereType<BattleDamageTimelineEvent>()
      .where((event) => event.moveId == moveId)
      .toList(growable: false);
}
