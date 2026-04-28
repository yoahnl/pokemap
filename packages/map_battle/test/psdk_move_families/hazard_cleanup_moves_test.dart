import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK hazard cleanup move families', () {
    test('s_rapid_spin clears user rapid-spin effects and own-bank hazards',
        () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'rapid_spin',
            power: 50,
            battleEngineMethod: 's_rapid_spin',
          ),
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            const BindEffect(
              scope: BattlerBattleEffectScope(psdkPlayerSlot),
              origin: psdkOpponentSlot,
            ),
          ),
          opponentEffects: const PsdkBattleEffectStack.empty()
              .addEffect(
                const GenericBattleEffect(
                  id: 'spikes',
                  scope: BankBattleEffectScope(0),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'stealth_rock',
                  scope: BankBattleEffectScope(1),
                ),
              ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(result.state.battlerAt(psdkPlayerSlot).effects.contains('bind'),
          isFalse);
      expect(_hasBankEffect(result.state, 'spikes', bank: 0), isFalse);
      expect(_hasBankEffect(result.state, 'stealth_rock', bank: 1), isTrue);
      expect(_damageEvents(result, moveId: 'rapid_spin'), hasLength(1));
    });

    test('s_defog clears rapid-spin hazards and opposing screens', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'defog',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_defog',
            target: PsdkBattleMoveTarget.adjacentFoe,
            stageMods: const <PsdkBattleMoveStageMod>[
              PsdkBattleMoveStageMod(stat: 'evasion', stages: -1),
            ],
          ),
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            const GenericBattleEffect(
              id: 'spikes',
              scope: BankBattleEffectScope(0),
            ),
          ),
          opponentEffects: const PsdkBattleEffectStack.empty()
              .addEffect(
                const GenericBattleEffect(
                  id: 'sticky_web',
                  scope: BankBattleEffectScope(1),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'reflect',
                  scope: BankBattleEffectScope(1),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'tailwind',
                  scope: BankBattleEffectScope(1),
                ),
              ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_hasBankEffect(result.state, 'spikes', bank: 0), isFalse);
      expect(_hasBankEffect(result.state, 'sticky_web', bank: 1), isFalse);
      expect(_hasBankEffect(result.state, 'reflect', bank: 1), isFalse);
      expect(_hasBankEffect(result.state, 'tailwind', bank: 1), isTrue);
      expect(
          result.state.battlerAt(psdkOpponentSlot).statStages.valueOf(
                'evasion',
              ),
          -1);
    });

    test('s_brick_break damages then clears opposing screen markers', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'brick_break',
            type: 'fighting',
            power: 75,
            battleEngineMethod: 's_brick_break',
          ),
          opponentEffects: const PsdkBattleEffectStack.empty()
              .addEffect(
                const GenericBattleEffect(
                  id: 'reflect',
                  scope: BankBattleEffectScope(1),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'light_screen',
                  scope: BankBattleEffectScope(1),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'tailwind',
                  scope: BankBattleEffectScope(1),
                ),
              ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(result, moveId: 'brick_break'), hasLength(1));
      expect(_hasBankEffect(result.state, 'reflect', bank: 1), isFalse);
      expect(_hasBankEffect(result.state, 'light_screen', bank: 1), isFalse);
      expect(_hasBankEffect(result.state, 'tailwind', bank: 1), isTrue);
    });

    test('entry hazards damage a grounded switch-in', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerMove: _move(id: 'tackle', power: 40),
          playerEffects: const PsdkBattleEffectStack.empty()
              .addEffect(
                const GenericBattleEffect(
                  id: 'spikes',
                  scope: BankBattleEffectScope(0),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'stealth_rock',
                  scope: BankBattleEffectScope(0),
                ),
              ),
        ),
      );

      final result = const BattleSwitchHandler().applyEntryHazards(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
      );

      expect(result.state.battlerAt(psdkPlayerSlot).currentHp, 76);
      expect(
        result.events.whereType<PsdkBattleDamageEvent>().map(
              (event) => event.moveId,
            ),
        containsAllInOrder(<String>['effect:spikes', 'effect:stealth_rock']),
      );
    });

    test('s_spike empowers Spikes up to three layers', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'spikes',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_spike',
            target: PsdkBattleMoveTarget.foeSide,
          ),
        ),
      );

      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final effect = _bankEffect(result.state, 'spikes', bank: 1);

      expect(effect, isA<SpikesEffect>());
      expect((effect as SpikesEffect).layers, 3);
    });

    test('maxed hazards fail instead of replacing existing bank effects', () {
      final cases = <({
        PsdkBattleMoveData move,
        PsdkBattleEffectStack effects,
        String effectId,
      })>[
        (
          move: _move(
            id: 'spikes',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_spike',
            target: PsdkBattleMoveTarget.foeSide,
          ),
          effects: PsdkBattleEffectStack().addEffect(
            SpikesEffect(bank: 1, layers: 3),
          ),
          effectId: 'spikes',
        ),
        (
          move: _move(
            id: 'toxic_spikes',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_toxic_spike',
            target: PsdkBattleMoveTarget.foeSide,
          ),
          effects: PsdkBattleEffectStack().addEffect(
            ToxicSpikesEffect(bank: 1, layers: 2),
          ),
          effectId: 'toxic_spikes',
        ),
        (
          move: _move(
            id: 'stealth_rock',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_stealth_rock',
            target: PsdkBattleMoveTarget.foeSide,
          ),
          effects: PsdkBattleEffectStack().addEffect(
            StealthRockEffect(bank: 1),
          ),
          effectId: 'stealth_rock',
        ),
        (
          move: _move(
            id: 'sticky_web',
            category: PsdkBattleMoveCategory.status,
            power: 0,
            battleEngineMethod: 's_sticky_web',
            target: PsdkBattleMoveTarget.foeSide,
          ),
          effects: PsdkBattleEffectStack().addEffect(
            StickyWebEffect(bank: 1),
          ),
          effectId: 'sticky_web',
        ),
      ];

      for (final entry in cases) {
        final engine = PsdkBattleEngine(
          setup: _setup(
            playerMove: entry.move,
            playerEffects: entry.effects,
          ),
        );

        final result =
            engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

        expect(
          result.timeline.events.whereType<PsdkBattleMoveFailedEvent>().map(
                (event) => event.moveId,
              ),
          contains(entry.move.id),
        );
        expect(_hasBankEffect(result.state, entry.effectId, bank: 1), isTrue);
      }
    });

    test('s_stone_axe damages then installs Stealth Rock', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'stone_axe',
            type: 'rock',
            power: 65,
            battleEngineMethod: 's_stone_axe',
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));

      expect(_damageEvents(result, moveId: 'stone_axe'), hasLength(1));
      expect(_bankEffect(result.state, 'stealth_rock', bank: 1),
          isA<StealthRockEffect>());
    });

    test('s_ceaseless_edge damages then installs and empowers Spikes', () {
      final engine = PsdkBattleEngine(
        setup: _setup(
          playerMove: _move(
            id: 'ceaseless_edge',
            type: 'dark',
            power: 65,
            battleEngineMethod: 's_ceaseless_edge',
          ),
          playerEffects: PsdkBattleEffectStack().addEffect(
            SpikesEffect(bank: 1, layers: 1),
          ),
        ),
      );

      final result = engine.submit(const PsdkBattleDecision.fight(moveSlot: 0));
      final effect = _bankEffect(result.state, 'spikes', bank: 1);

      expect(_damageEvents(result, moveId: 'ceaseless_edge'), hasLength(1));
      expect(effect, isA<SpikesEffect>());
      expect((effect as SpikesEffect).layers, 2);
    });

    test('layered Spikes and Toxic Spikes use their PSDK entry power', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerMove: _move(id: 'tackle', power: 40),
          playerEffects: PsdkBattleEffectStack()
              .addEffect(SpikesEffect(bank: 0, layers: 2))
              .addEffect(ToxicSpikesEffect(bank: 0, layers: 2)),
        ),
      );

      final result = const BattleSwitchHandler().applyEntryHazards(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 84);
      expect(player.majorStatus, PsdkBattleMajorStatus.toxic);
    });

    test('Heavy-Duty Boots prevents all entry hazards', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerMove: _move(id: 'tackle', power: 40),
          playerHeldItemId: 'heavy_duty_boots',
          playerEffects: PsdkBattleEffectStack()
              .addEffect(SpikesEffect(bank: 0, layers: 3))
              .addEffect(StealthRockEffect(bank: 0))
              .addEffect(ToxicSpikesEffect(bank: 0, layers: 2))
              .addEffect(StickyWebEffect(bank: 0)),
        ),
      );

      final result = const BattleSwitchHandler().applyEntryHazards(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 100);
      expect(player.majorStatus, isNull);
      expect(player.statStages.valueOf('speed'), 0);
      expect(result.events, isEmpty);
    });

    test('Magic Guard blocks hazard damage but not hazard status or stat drops',
        () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerMove: _move(id: 'tackle', power: 40),
          playerAbilityId: 'magic_guard',
          playerEffects: PsdkBattleEffectStack()
              .addEffect(SpikesEffect(bank: 0, layers: 3))
              .addEffect(StealthRockEffect(bank: 0))
              .addEffect(ToxicSpikesEffect(bank: 0, layers: 2))
              .addEffect(StickyWebEffect(bank: 0)),
        ),
      );

      final result = const BattleSwitchHandler().applyEntryHazards(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.currentHp, 100);
      expect(player.majorStatus, PsdkBattleMajorStatus.toxic);
      expect(player.statStages.valueOf('speed'), -1);
      expect(result.events.whereType<PsdkBattleDamageEvent>(), isEmpty);
    });

    test('entry hazards apply Toxic Spikes poison and Sticky Web speed drop',
        () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerMove: _move(id: 'tackle', power: 40),
          playerEffects: const PsdkBattleEffectStack.empty()
              .addEffect(
                const GenericBattleEffect(
                  id: 'toxic_spikes',
                  scope: BankBattleEffectScope(0),
                ),
              )
              .addEffect(
                const GenericBattleEffect(
                  id: 'sticky_web',
                  scope: BankBattleEffectScope(0),
                ),
              ),
        ),
      );

      final result = const BattleSwitchHandler().applyEntryHazards(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
      );
      final player = result.state.battlerAt(psdkPlayerSlot);

      expect(player.majorStatus, PsdkBattleMajorStatus.poison);
      expect(player.statStages.valueOf('speed'), -1);
      expect(result.events.whereType<PsdkBattleStatusEvent>(), hasLength(1));
      expect(result.events.whereType<PsdkBattleStatStageEvent>(), hasLength(1));
    });

    test('grounded Poison switch-ins absorb Toxic Spikes on their bank', () {
      final state = PsdkBattleState.fromSetup(
        _setup(
          playerMove: _move(id: 'tackle', power: 40),
          playerTypes: const PsdkBattleTypes(primary: 'poison'),
          playerEffects: const PsdkBattleEffectStack.empty().addEffect(
            const GenericBattleEffect(
              id: 'toxic_spikes',
              scope: BankBattleEffectScope(0),
            ),
          ),
        ),
      );

      final result = const BattleSwitchHandler().applyEntryHazards(
        context: BattleHandlerContext(
          state: state,
          rng: _rng(),
          turn: 1,
          user: psdkOpponentSlot,
        ),
        target: psdkPlayerSlot,
      );

      expect(result.state.battlerAt(psdkPlayerSlot).majorStatus, isNull);
      expect(_hasBankEffect(result.state, 'toxic_spikes', bank: 0), isFalse);
    });
  });
}

PsdkBattleSetup _setup({
  required PsdkBattleMoveData playerMove,
  PsdkBattleTypes playerTypes = const PsdkBattleTypes(primary: 'normal'),
  String? playerAbilityId,
  String? playerHeldItemId,
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
  PsdkBattleEffectStack opponentEffects = const PsdkBattleEffectStack.empty(),
}) {
  return PsdkBattleSetup.singles(
    player: _combatant(
      id: 'player',
      types: playerTypes,
      speed: 100,
      move: playerMove,
      effects: playerEffects,
      abilityId: playerAbilityId,
      heldItemId: playerHeldItemId,
    ),
    opponent: _combatant(
      id: 'opponent',
      types: const PsdkBattleTypes(primary: 'normal'),
      speed: 1,
      move: _move(
        id: 'opponent_wait',
        power: 0,
        accuracy: 1,
        battleEngineMethod: 's_basic',
      ),
      effects: opponentEffects,
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 0,
    ),
  );
}

PsdkBattleCombatantSetup _combatant({
  required String id,
  required PsdkBattleTypes types,
  required int speed,
  required PsdkBattleMoveData move,
  required PsdkBattleEffectStack effects,
  String? abilityId,
  String? heldItemId,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: id,
    displayName: id,
    level: 20,
    maxHp: 100,
    currentHp: 100,
    types: types,
    stats: PsdkBattleStats(
      attack: 50,
      defense: 50,
      specialAttack: 50,
      specialDefense: 50,
      speed: speed,
    ),
    abilityId: abilityId,
    heldItemId: heldItemId,
    moves: <PsdkBattleMoveData>[move],
    effects: effects,
  );
}

PsdkBattleMoveData _move({
  required String id,
  String type = 'normal',
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  required int power,
  int accuracy = 100,
  String battleEngineMethod = 's_basic',
  PsdkBattleMoveTarget target = PsdkBattleMoveTarget.adjacentFoe,
  List<PsdkBattleMoveStageMod> stageMods = const <PsdkBattleMoveStageMod>[],
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
    priority: 0,
    criticalRate: 1,
    battleEngineMethod: battleEngineMethod,
    target: target,
    stageMods: stageMods,
  );
}

BattleRngStreams _rng() {
  return BattleRngStreams.fromPsdkSeeds(
    const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 99999,
      moveAccuracy: 3,
      generic: 0,
    ),
  );
}

bool _hasBankEffect(
  PsdkBattleState state,
  String effectId, {
  required int bank,
}) {
  return state.combatants.values.any(
    (combatant) => combatant.effects.effects.any(
      (effect) =>
          effect.id == effectId &&
          effect.scope is BankBattleEffectScope &&
          (effect.scope as BankBattleEffectScope).bank == bank,
    ),
  );
}

BattleEffect _bankEffect(
  PsdkBattleState state,
  String effectId, {
  required int bank,
}) {
  return state.combatants.values
      .expand((combatant) => combatant.effects.effects)
      .singleWhere(
        (effect) =>
            effect.id == effectId &&
            effect.scope is BankBattleEffectScope &&
            (effect.scope as BankBattleEffectScope).bank == bank,
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
