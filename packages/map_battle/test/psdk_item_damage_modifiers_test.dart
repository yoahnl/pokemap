import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK held item damage and speed modifiers', () {
    test('type boosting items increase matching move damage and persist', () {
      final baseline = _runMove(
        playerMove: _move(id: 'ember', type: 'fire', power: 40),
      );
      final boosted = _runMove(
        playerHeldItemId: 'charcoal',
        playerMove: _move(id: 'ember', type: 'fire', power: 40),
      );
      final mismatched = _runMove(
        playerHeldItemId: 'charcoal',
        playerMove: _move(id: 'water_gun', type: 'water', power: 40),
      );

      expect(_damage(boosted, moveId: 'ember'),
          greaterThan(_damage(baseline, moveId: 'ember')));
      expect(
        _damage(mismatched, moveId: 'water_gun'),
        _damage(
            _runMove(
                playerMove: _move(id: 'water_gun', type: 'water', power: 40)),
            moveId: 'water_gun'),
      );
      expect(boosted.state.battlerAt(psdkPlayerSlot).heldItemId, 'charcoal');
      expect(boosted.state.battlerAt(psdkPlayerSlot).itemConsumed, isFalse);
    });

    test('Choice Band and Choice Specs boost the matching offensive stat', () {
      final physical = _runMove(
        playerHeldItemId: 'choice_band',
        playerMove: _move(id: 'slash', type: 'normal', power: 70),
      );
      final physicalBaseline = _runMove(
        playerMove: _move(id: 'slash', type: 'normal', power: 70),
      );
      final special = _runMove(
        playerHeldItemId: 'choice_specs',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final specialBaseline = _runMove(
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );

      expect(_damage(physical, moveId: 'slash'),
          greaterThan(_damage(physicalBaseline, moveId: 'slash')));
      expect(_damage(special, moveId: 'swift'),
          greaterThan(_damage(specialBaseline, moveId: 'swift')));
    });

    test('Normal Gem boosts a matching hit and is consumed once', () {
      final baseline = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final gem = _runMove(
        playerHeldItemId: 'normal_gem',
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final player = gem.state.battlerAt(psdkPlayerSlot);

      expect(_damage(gem, moveId: 'tackle'),
          greaterThan(_damage(baseline, moveId: 'tackle')));
      expect(player.heldItemId, isNull);
      expect(player.consumedItemId, 'normal_gem');
      expect(player.itemConsumed, isTrue);
      expect(_itemEvents(gem).single.itemId, 'normal_gem');
    });

    test('Gem registry covers all PSDK gem types with matching-type consume',
        () {
      final baseline = _runMove(
        playerMove: _move(id: 'mud_shot', type: 'ground', power: 40),
      );
      final groundGem = _runMove(
        playerHeldItemId: 'ground_gem',
        playerMove: _move(id: 'mud_shot', type: 'ground', power: 40),
      );
      final wrongTypeGem = _runMove(
        playerHeldItemId: 'ice_gem',
        playerMove: _move(id: 'mud_shot', type: 'ground', power: 40),
      );

      expect(
        _damage(groundGem, moveId: 'mud_shot'),
        greaterThan(_damage(baseline, moveId: 'mud_shot')),
      );
      expect(groundGem.state.battlerAt(psdkPlayerSlot).heldItemId, isNull);
      expect(
        groundGem.state.battlerAt(psdkPlayerSlot).consumedItemId,
        'ground_gem',
      );
      expect(
        _damage(wrongTypeGem, moveId: 'mud_shot'),
        _damage(baseline, moveId: 'mud_shot'),
      );
      expect(
        wrongTypeGem.state.battlerAt(psdkPlayerSlot).heldItemId,
        'ice_gem',
      );
    });

    test('Life Orb boosts damage and applies recoil without consuming itself',
        () {
      final baseline = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final boosted = _runMove(
        playerHeldItemId: 'life_orb',
        playerMove: _move(id: 'tackle', type: 'normal', power: 40),
      );
      final player = boosted.state.battlerAt(psdkPlayerSlot);

      expect(_damage(boosted, moveId: 'tackle'),
          greaterThan(_damage(baseline, moveId: 'tackle')));
      expect(_damage(boosted, moveId: 'item:life_orb'), 10);
      expect(player.currentHp, 90);
      expect(player.heldItemId, 'life_orb');
      expect(player.itemConsumed, isFalse);
    });

    test('Choice Scarf speed modifier affects action order', () {
      final state = _state(
        playerHeldItemId: 'choice_scarf',
        playerSpeed: 80,
        opponentSpeed: 100,
      );
      const mapper = PsdkBattleActionDecisionMapper();
      const ordering = PsdkBattleActionOrdering();
      final playerAction = mapper.map(
        state: state,
        user: psdkPlayerSlot,
        decision: const BattleFightDecision(moveSlot: 0),
      );
      final opponentAction = mapper.map(
        state: state,
        user: psdkOpponentSlot,
        decision: const BattleFightDecision(moveSlot: 0),
      );

      final ordered = ordering.order(
        actions: <PsdkBattleAction>[opponentAction, playerAction],
        rng: BattleRngStreams.fromSeedSnapshot(_seeds),
      );

      expect(ordered.first.user.toJson(), psdkPlayerSlot.toJson());
      expect((playerAction as PsdkBattleFightAction).speed, 120);
    });

    test('HalfSpeed items halve speed and respect item suppression', () {
      const mapper = PsdkBattleActionDecisionMapper();
      PsdkBattleFightAction fightAction(PsdkBattleState state) {
        return mapper.map(
          state: state,
          user: psdkPlayerSlot,
          decision: const BattleFightDecision(moveSlot: 0),
        ) as PsdkBattleFightAction;
      }

      final ironBall = _state(
        playerHeldItemId: 'iron_ball',
        playerSpeed: 100,
      );
      final machoBrace = _state(
        playerHeldItemId: 'macho_brace',
        playerSpeed: 100,
      );
      final suppressedIronBall = _state(
        playerHeldItemId: 'iron_ball',
        playerEffects: PsdkBattleEffectStack(
          values: const <String>['magic_room'],
        ),
        playerSpeed: 100,
      );

      expect(fightAction(ironBall).speed, 50);
      expect(fightAction(machoBrace).speed, 50);
      expect(fightAction(suppressedIronBall).speed, 100);
    });

    test('Assault Vest boosts special defense and blocks status moves', () {
      final physical = _currentChoices(
        playerHeldItemId: 'assault_vest',
        playerMoves: <PsdkBattleMoveData>[
          _move(id: 'tackle', type: 'normal', power: 40),
          _move(
            id: 'growl',
            type: 'normal',
            power: 0,
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_status',
          ),
        ],
      );
      final baseline = _runMove(
        playerMove: _move(
          id: 'water_gun',
          type: 'water',
          power: 70,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentHeldItemId: null,
        opponentSpeciesId: 'clamperl',
      );
      final vested = _runMove(
        playerMove: _move(
          id: 'water_gun',
          type: 'water',
          power: 70,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentHeldItemId: 'assault_vest',
        opponentSpeciesId: 'clamperl',
      );

      expect(physical, <String>['tackle']);
      expect(
        _damage(vested, moveId: 'water_gun'),
        lessThan(_damage(baseline, moveId: 'water_gun')),
      );
    });

    test('Expert Belt boosts only super-effective damage', () {
      final neutral = _runMove(
        playerHeldItemId: 'expert_belt',
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
      );
      final superEffectiveBaseline = _runMove(
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final superEffective = _runMove(
        playerHeldItemId: 'expert_belt',
        playerMove: _move(id: 'ember', type: 'fire', power: 60),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      expect(
        _damage(neutral, moveId: 'ember'),
        _damage(
          _runMove(playerMove: _move(id: 'ember', type: 'fire', power: 60)),
          moveId: 'ember',
        ),
      );
      expect(
        _damage(superEffective, moveId: 'ember'),
        greaterThan(_damage(superEffectiveBaseline, moveId: 'ember')),
      );
    });

    test('legendary species items boost only their PSDK species and types', () {
      final dialgaDragon = _runMove(
        playerHeldItemId: 'adamant_orb',
        playerSpeciesId: 'dialga',
        playerMove: _move(id: 'dragon_breath', type: 'dragon', power: 60),
      );
      final dialgaSteel = _runMove(
        playerHeldItemId: 'adamant_orb',
        playerSpeciesId: 'dialga',
        playerMove: _move(id: 'metal_claw', type: 'steel', power: 60),
      );
      final palkiaWater = _runMove(
        playerHeldItemId: 'lustrous_orb',
        playerSpeciesId: 'palkia',
        playerMove: _move(id: 'water_pulse', type: 'water', power: 60),
      );
      final giratinaGhost = _runMove(
        playerHeldItemId: 'griseous_orb',
        playerSpeciesId: 'giratina',
        playerMove: _move(id: 'shadow_ball', type: 'ghost', power: 60),
        opponentTypes: const PsdkBattleTypes(primary: 'psychic'),
      );
      final latiasPsychic = _runMove(
        playerHeldItemId: 'soul_dew',
        playerSpeciesId: 'latias',
        playerMove: _move(
          id: 'confusion',
          type: 'psychic',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final latiosDragon = _runMove(
        playerHeldItemId: 'soul_dew',
        playerSpeciesId: 'latios',
        playerMove: _move(
          id: 'dragon_pulse',
          type: 'dragon',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final wrongSpecies = _runMove(
        playerHeldItemId: 'adamant_orb',
        playerSpeciesId: 'palkia',
        playerMove: _move(id: 'dragon_breath', type: 'dragon', power: 60),
      );
      final wrongType = _runMove(
        playerHeldItemId: 'adamant_orb',
        playerSpeciesId: 'dialga',
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
      );
      final baselineDragon = _runMove(
        playerSpeciesId: 'dialga',
        playerMove: _move(id: 'dragon_breath', type: 'dragon', power: 60),
      );
      final baselineNormal = _runMove(
        playerSpeciesId: 'dialga',
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
      );

      expect(
        _damage(dialgaDragon, moveId: 'dragon_breath'),
        greaterThan(_damage(baselineDragon, moveId: 'dragon_breath')),
      );
      expect(_damage(dialgaSteel, moveId: 'metal_claw'), greaterThan(0));
      expect(_damage(palkiaWater, moveId: 'water_pulse'), greaterThan(0));
      expect(_damage(giratinaGhost, moveId: 'shadow_ball'), greaterThan(0));
      expect(_damage(latiasPsychic, moveId: 'confusion'), greaterThan(0));
      expect(_damage(latiosDragon, moveId: 'dragon_pulse'), greaterThan(0));
      expect(
        _damage(wrongSpecies, moveId: 'dragon_breath'),
        _damage(baselineDragon, moveId: 'dragon_breath'),
      );
      expect(
        _damage(wrongType, moveId: 'tackle'),
        _damage(baselineNormal, moveId: 'tackle'),
      );
    });

    test('Drives change Genesect Techno Blast type only', () {
      final burnDrive = _runMove(
        playerHeldItemId: 'burn_drive',
        playerSpeciesId: 'genesect',
        playerMove: _move(
          id: 'techno_blast',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
          battleEngineMethod: 's_techno_blast',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final baseline = _runMove(
        playerSpeciesId: 'genesect',
        playerMove: _move(
          id: 'techno_blast',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
          battleEngineMethod: 's_techno_blast',
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final wrongMove = _runMove(
        playerHeldItemId: 'burn_drive',
        playerSpeciesId: 'genesect',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );
      final wrongMoveBaseline = _runMove(
        playerSpeciesId: 'genesect',
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentTypes: const PsdkBattleTypes(primary: 'grass'),
      );

      expect(
        _damage(burnDrive, moveId: 'techno_blast'),
        greaterThan(_damage(baseline, moveId: 'techno_blast')),
      );
      expect(
        _damage(wrongMove, moveId: 'swift'),
        _damage(wrongMoveBaseline, moveId: 'swift'),
      );
    });

    test('Eviolite boosts both defensive stats for evolvable species', () {
      final physicalBaseline = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
        opponentSpeciesId: 'chansey',
      );
      final physicalEviolite = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
        opponentHeldItemId: 'eviolite',
        opponentSpeciesId: 'chansey',
      );
      final specialBaseline = _runMove(
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentSpeciesId: 'chansey',
      );
      final specialEviolite = _runMove(
        playerMove: _move(
          id: 'swift',
          type: 'normal',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentHeldItemId: 'eviolite',
        opponentSpeciesId: 'chansey',
      );
      final nonEvolvable = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
        opponentHeldItemId: 'eviolite',
        opponentSpeciesId: 'mew',
      );
      final nonEvolvableBaseline = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
        opponentSpeciesId: 'mew',
      );

      expect(
        _damage(physicalEviolite, moveId: 'tackle'),
        lessThan(_damage(physicalBaseline, moveId: 'tackle')),
      );
      expect(
        _damage(specialEviolite, moveId: 'swift'),
        lessThan(_damage(specialBaseline, moveId: 'swift')),
      );
      expect(
        _damage(nonEvolvable, moveId: 'tackle'),
        _damage(nonEvolvableBaseline, moveId: 'tackle'),
      );
    });

    test('species passive items match PSDK stat modifier targets', () {
      final clamperlTooth = _runMove(
        playerHeldItemId: 'deep_sea_tooth',
        playerSpeciesId: 'clamperl',
        playerMove: _move(
          id: 'water_gun',
          type: 'water',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final nonClamperlTooth = _runMove(
        playerHeldItemId: 'deep_sea_tooth',
        playerSpeciesId: 'squirtle',
        playerMove: _move(
          id: 'water_gun',
          type: 'water',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
      );
      final clamperlScale = _runMove(
        playerMove: _move(
          id: 'water_gun',
          type: 'water',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentHeldItemId: 'deep_sea_scale',
        opponentSpeciesId: 'clamperl',
      );
      final clamperlScaleBaseline = _runMove(
        playerMove: _move(
          id: 'water_gun',
          type: 'water',
          power: 60,
          category: PsdkBattleMoveCategory.special,
        ),
        opponentSpeciesId: 'clamperl',
      );
      final cuboneClub = _runMove(
        playerHeldItemId: 'thick_club',
        playerSpeciesId: 'cubone',
        playerMove: _move(id: 'bone_club', type: 'ground', power: 65),
      );
      final nonCuboneClub = _runMove(
        playerHeldItemId: 'thick_club',
        playerSpeciesId: 'pikachu',
        playerMove: _move(id: 'bone_club', type: 'ground', power: 65),
      );
      final dittoPowder = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
        opponentHeldItemId: 'metal_powder',
        opponentSpeciesId: 'ditto',
      );
      final nonDittoPowder = _runMove(
        playerMove: _move(id: 'tackle', type: 'normal', power: 60),
        opponentHeldItemId: 'metal_powder',
        opponentSpeciesId: 'mew',
      );
      final quickPowderState = _state(
        playerHeldItemId: 'quick_powder',
        playerSpeciesId: 'ditto',
        playerSpeed: 60,
        opponentSpeed: 100,
      );
      const mapper = PsdkBattleActionDecisionMapper();
      final quickAction = mapper.map(
        state: quickPowderState,
        user: psdkPlayerSlot,
        decision: const BattleFightDecision(moveSlot: 0),
      );

      expect(
        _damage(clamperlTooth, moveId: 'water_gun'),
        greaterThan(_damage(nonClamperlTooth, moveId: 'water_gun')),
      );
      expect(
        _damage(clamperlScale, moveId: 'water_gun'),
        lessThan(_damage(clamperlScaleBaseline, moveId: 'water_gun')),
      );
      expect(
        _damage(cuboneClub, moveId: 'bone_club'),
        greaterThan(_damage(nonCuboneClub, moveId: 'bone_club')),
      );
      expect(
        _damage(dittoPowder, moveId: 'tackle'),
        lessThan(_damage(nonDittoPowder, moveId: 'tackle')),
      );
      expect((quickAction as PsdkBattleFightAction).speed, 120);
    });
  });
}

const _seeds = BattleRngSeeds(
  moveDamage: 1,
  moveCritical: 99999,
  moveAccuracy: 3,
  generic: 4,
);

PsdkBattleTurnResult _runMove({
  required PsdkBattleMoveData playerMove,
  String? playerHeldItemId,
  String playerSpeciesId = 'player',
  String? opponentHeldItemId,
  String opponentSpeciesId = 'opponent',
  PsdkBattleTypes opponentTypes = const PsdkBattleTypes(primary: 'normal'),
}) {
  final engine = PsdkBattleEngine(
    setup: BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        speciesId: playerSpeciesId,
        heldItemId: playerHeldItemId,
        speed: 100,
        move: playerMove,
      ),
      opponent: _combatant(
        id: 'opponent',
        speciesId: opponentSpeciesId,
        heldItemId: opponentHeldItemId,
        types: opponentTypes,
        speed: 1,
        currentHp: 200,
        move: _move(
          id: 'opponent_wait',
          type: 'normal',
          power: 0,
          category: PsdkBattleMoveCategory.status,
          battleEngineMethod: 's_splash',
        ),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
  return engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
}

PsdkBattleState _state({
  String? playerHeldItemId,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
  String playerSpeciesId = 'player',
  int playerSpeed = 100,
  int opponentSpeed = 50,
}) {
  return PsdkBattleState.fromSetup(
    BattleEngineSetup.singles(
      player: _combatant(
        id: 'player',
        speciesId: playerSpeciesId,
        heldItemId: playerHeldItemId,
        effects: playerEffects,
        speed: playerSpeed,
        move: _move(id: 'tackle', type: 'normal', power: 40),
      ),
      opponent: _combatant(
        id: 'opponent',
        speed: opponentSpeed,
        move: _move(id: 'scratch', type: 'normal', power: 40),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ).psdkSetup,
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleMoveData move,
  String? speciesId,
  String? heldItemId,
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
  PsdkBattleTypes types = const PsdkBattleTypes(primary: 'normal'),
  int currentHp = 100,
  int speed = 50,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId ?? id,
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
    effects: effects,
    moves: <PsdkBattleMoveData>[move],
  );
}

List<String> _currentChoices({
  required String playerHeldItemId,
  required List<PsdkBattleMoveData> playerMoves,
}) {
  final engine = BattleEngine(
    setup: BattleEngineSetup.singles(
      player: PsdkBattleCombatantSetup(
        id: 'player',
        speciesId: 'player',
        displayName: 'player',
        level: 20,
        maxHp: 100,
        currentHp: 100,
        types: const PsdkBattleTypes(primary: 'normal'),
        stats: const PsdkBattleStats(
          attack: 50,
          defense: 50,
          specialAttack: 50,
          specialDefense: 50,
          speed: 100,
        ),
        heldItemId: playerHeldItemId,
        moves: playerMoves,
      ),
      opponent: _combatant(
        id: 'opponent',
        move: _move(id: 'opponent_wait', type: 'normal', power: 0),
      ),
      rngSeeds: _seeds.psdkSeeds,
    ),
  );
  return engine.currentRequest.fightChoices
      .map((choice) => choice.moveId)
      .toList(growable: false);
}

PsdkBattleMoveData _move({
  required String id,
  required String type,
  required int power,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: type,
    category: category,
    power: power,
    accuracy: 100,
    pp: 35,
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
  );
}

int _damage(PsdkBattleTurnResult result, {required String moveId}) {
  return result.timeline.events
      .whereType<PsdkBattleDamageEvent>()
      .where((event) => event.moveId == moveId)
      .fold<int>(0, (sum, event) => sum + event.damage);
}

List<PsdkBattleItemEvent> _itemEvents(PsdkBattleTurnResult result) {
  return result.timeline.events
      .whereType<PsdkBattleItemEvent>()
      .toList(growable: false);
}
