import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK battle topology', () {
    test('builds banks, active slots and battlers from a singles setup', () {
      final topology = BattleTopology.fromPsdkSetup(_singlesSetup());

      expect(topology.banks.map((bank) => bank.index), <int>[0, 1]);
      expect(topology.activeBattlers.map((battler) => battler.speciesId),
          <String>['bulbasaur', 'squirtle']);
      expect(
          topology
              .battlerAt(const BattlePositionRef(bank: 0, position: 0))
              ?.partyIndex,
          0);
      expect(
          topology
              .battlerAt(const BattlePositionRef(bank: 1, position: 0))
              ?.slot,
          const BattlePositionRef(bank: 1, position: 0));
    });

    test('groups multiple active positions from a PSDK state by bank', () {
      final state = PsdkBattleState(
        combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
          const PsdkBattleSlotRef(bank: 0, position: 0):
              PsdkBattleCombatant.fromSetup(
            _combatantSetup(
              id: 'bank0-left',
              speciesId: 'left',
              moves: <PsdkBattleMoveData>[_move(power: 40)],
            ),
          ),
          const PsdkBattleSlotRef(bank: 0, position: 1):
              PsdkBattleCombatant.fromSetup(
            _combatantSetup(
              id: 'bank0-right',
              speciesId: 'right',
              moves: <PsdkBattleMoveData>[_move(power: 40)],
            ),
          ),
        },
      );

      final topology = BattleTopology.fromPsdkState(state);

      expect(topology.banks, hasLength(1));
      expect(topology.banks.single.slots.map((slot) => slot.position),
          <int>[0, 1]);
      expect(topology.activeBattlers.map((battler) => battler.instanceId),
          <String>['bank0-left', 'bank0-right']);
    });

    test('resolves allies foes and adjacent foes by bank and position', () {
      final topology = BattleTopology(
        banks: <BattleBank>[
          _bank(
            0,
            positions: <int>[0, 1],
            active: <BattleBattler>[
              _battler('ally-left', bank: 0, position: 0, partyIndex: 0),
              _battler('ally-right', bank: 0, position: 1, partyIndex: 1),
            ],
          ),
          _bank(
            1,
            positions: <int>[0, 1, 2],
            active: <BattleBattler>[
              _battler('foe-left', bank: 1, position: 0, partyIndex: 0),
              _battler('foe-mid', bank: 1, position: 1, partyIndex: 1),
              _battler('foe-right', bank: 1, position: 2, partyIndex: 2),
            ],
          ),
        ],
      );
      final actor =
          topology.battlerAt(const BattlePositionRef(bank: 0, position: 0))!;

      expect(topology.alliesOf(actor).map((battler) => battler.instanceId),
          <String>['ally-right']);
      expect(topology.foesOf(actor).map((battler) => battler.instanceId),
          <String>['foe-left', 'foe-mid', 'foe-right']);
      expect(
        topology.adjacentFoesOf(actor).map((battler) => battler.instanceId),
        <String>['foe-left', 'foe-mid'],
      );
    });

    test(
        'reports empty slots and replacement candidates without moving party ids',
        () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final bench = _battler('bench', bank: 0, position: -1, partyIndex: 1);
      final faintedBench = _battler(
        'fainted-bench',
        bank: 0,
        position: -1,
        partyIndex: 2,
        hp: 0,
      );
      final topology = BattleTopology(
        banks: <BattleBank>[
          BattleBank(
            index: 0,
            slots: <BattleSlot>[
              BattleSlot(position: 0, activeBattler: active),
              BattleSlot(position: 1),
            ],
            parties: <BattleParty>[
              BattleParty(id: 0, battlers: <BattleBattler>[
                active,
                bench,
                faintedBench,
              ]),
            ],
          ),
        ],
      );

      expect(topology.emptySlots.map((slot) => slot.ref),
          <BattlePositionRef>[const BattlePositionRef(bank: 0, position: 1)]);
      expect(
        topology
            .replacementsFor(const BattlePositionRef(bank: 0, position: 0))
            .map((battler) => battler.instanceId),
        <String>['bench'],
      );
      expect(
        topology.replacementsFor(
          const BattlePositionRef(bank: 0, position: 99),
        ),
        isEmpty,
      );

      topology.placeBattler(
        battler: bench,
        slot: const BattlePositionRef(bank: 0, position: 1),
      );

      expect(bench.partyIndex, 1);
      expect(bench.position, 1);
      expect(bench.slot, const BattlePositionRef(bank: 0, position: 1));
    });

    test('refuses non-atomic active battler moves between slots', () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final topology = BattleTopology(
        banks: <BattleBank>[
          BattleBank(
            index: 0,
            slots: <BattleSlot>[
              BattleSlot(position: 0, activeBattler: active),
              BattleSlot(position: 1),
            ],
            parties: <BattleParty>[
              BattleParty(id: 0, battlers: <BattleBattler>[active]),
            ],
          ),
        ],
      );

      expect(
        () => topology.placeBattler(
          battler: active,
          slot: const BattlePositionRef(bank: 0, position: 1),
        ),
        throwsStateError,
      );
      expect(
        topology.battlerAt(const BattlePositionRef(bank: 0, position: 0)),
        same(active),
      );
      expect(active.position, 0);
    });

    test('refuses replacing an occupied slot with a different battler', () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final bench = _battler('bench', bank: 0, position: -1, partyIndex: 1);
      final topology = BattleTopology(
        banks: <BattleBank>[
          BattleBank(
            index: 0,
            slots: <BattleSlot>[BattleSlot(position: 0, activeBattler: active)],
            parties: <BattleParty>[
              BattleParty(id: 0, battlers: <BattleBattler>[active, bench]),
            ],
          ),
        ],
      );

      expect(
        () => topology.placeBattler(
          battler: bench,
          slot: const BattlePositionRef(bank: 0, position: 0),
        ),
        throwsStateError,
      );
      expect(
        topology.battlerAt(const BattlePositionRef(bank: 0, position: 0)),
        same(active),
      );
      expect(bench.position, -1);
    });

    test('rejects duplicate banks slots parties and battler identities', () {
      expect(
        () => BattleTopology(
          banks: <BattleBank>[
            _bank(0),
            _bank(0),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BattleBank(
          index: 0,
          slots: <BattleSlot>[
            BattleSlot(position: 0),
            BattleSlot(position: 0),
          ],
          parties: const <BattleParty>[],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BattleBank(
          index: 0,
          slots: <BattleSlot>[BattleSlot(position: 0)],
          parties: <BattleParty>[
            BattleParty(id: 0, battlers: const <BattleBattler>[]),
            BattleParty(id: 0, battlers: const <BattleBattler>[]),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BattleParty(
          id: 0,
          battlers: <BattleBattler>[
            _battler('duplicate', bank: 0, position: 0, partyIndex: 0),
            _battler('duplicate', bank: 0, position: -1, partyIndex: 1),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BattleParty(
          id: 0,
          battlers: <BattleBattler>[
            _battler('first', bank: 0, position: 0, partyIndex: 0),
            _battler('second', bank: 0, position: -1, partyIndex: 0),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BattleBank(
          index: 0,
          slots: <BattleSlot>[BattleSlot(position: 0)],
          parties: <BattleParty>[
            BattleParty(
              id: 1,
              battlers: <BattleBattler>[
                _battler(
                  'wrong-party-bank',
                  bank: 1,
                  position: -1,
                  partyIndex: 0,
                ),
              ],
            ),
          ],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects slot battlers assigned to another bank or position', () {
      expect(
        () => BattleBank(
          index: 1,
          slots: <BattleSlot>[
            BattleSlot(
              position: 0,
              activeBattler:
                  _battler('wrong-bank', bank: 0, position: 0, partyIndex: 0),
            ),
          ],
          parties: const <BattleParty>[],
        ),
        throwsA(isA<ArgumentError>()),
      );
      expect(
        () => BattleBank(
          index: 0,
          slots: <BattleSlot>[
            BattleSlot(
              position: 1,
              activeBattler: _battler('wrong-position',
                  bank: 0, position: 0, partyIndex: 0),
            ),
          ],
          parties: const <BattleParty>[],
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('does not treat reserve battlers as active targetable slots', () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final reserve = _battler('reserve', bank: 0, position: -1, partyIndex: 1);
      final topology = BattleTopology(
        banks: <BattleBank>[
          BattleBank(
            index: 0,
            slots: <BattleSlot>[BattleSlot(position: 0, activeBattler: active)],
            parties: <BattleParty>[
              BattleParty(id: 0, battlers: <BattleBattler>[active, reserve]),
            ],
          ),
        ],
      );

      expect(topology.activeBattlers.map((battler) => battler.instanceId),
          <String>['active']);
      expect(
        topology.battlerAt(const BattlePositionRef(bank: 0, position: 1)),
        isNull,
      );
      expect(topology.emptySlots, isEmpty);
    });

    test('public topology collections are immutable snapshots', () {
      final active = _battler('active', bank: 0, position: 0, partyIndex: 0);
      final slots = <BattleSlot>[
        BattleSlot(position: 0, activeBattler: active)
      ];
      final parties = <BattleParty>[
        BattleParty(id: 0, battlers: <BattleBattler>[active]),
      ];
      final bank = BattleBank(index: 0, slots: slots, parties: parties);
      final topology = BattleTopology(banks: <BattleBank>[bank]);

      slots.clear();
      parties.clear();

      expect(topology.banks.single.slots, hasLength(1));
      expect(topology.banks.single.parties, hasLength(1));
      expect(() => topology.banks.clear(), throwsUnsupportedError);
      expect(() => topology.banks.single.slots.clear(), throwsUnsupportedError);
      expect(
        () => topology.banks.single.parties.single.battlers.clear(),
        throwsUnsupportedError,
      );
    });

    test('PSDK topology refs do not shadow legacy BattleSlotRef', () {
      const legacy = BattleSlotRef.active(BattleSideId.player);
      const psdk = BattlePositionRef(bank: 0, position: 0);

      expect(legacy.side, BattleSideId.player);
      expect(legacy.slotIndex, 0);
      expect(psdk.bank, 0);
      expect(psdk.position, 0);
    });

    test('BattleEngine public snapshot exposes topology for the current state',
        () {
      final engine = BattleEngine(setup: _engineSetup());

      final before = engine.snapshot().topology;
      final result = engine.submit(const BattleDecision.fight(moveSlot: 0));
      final after = result.state.topology;

      expect(
          before.battlerAt(const BattlePositionRef(bank: 1, position: 0))?.hp,
          40);
      expect(after.battlerAt(const BattlePositionRef(bank: 1, position: 0))?.hp,
          lessThan(40));
    });
  });
}

BattleBank _bank(
  int index, {
  List<int> positions = const <int>[0],
  List<BattleBattler>? active,
}) {
  final activeByPosition = <int, BattleBattler>{
    for (final battler in active ?? <BattleBattler>[])
      battler.position: battler,
  };
  return BattleBank(
    index: index,
    slots: <BattleSlot>[
      for (final position in positions)
        BattleSlot(
          position: position,
          activeBattler: activeByPosition[position],
        ),
    ],
    parties: <BattleParty>[
      BattleParty(
        id: index,
        battlers: active ?? <BattleBattler>[],
      ),
    ],
  );
}

BattleBattler _battler(
  String id, {
  required int bank,
  required int position,
  required int partyIndex,
  int hp = 40,
}) {
  return BattleBattler(
    instanceId: id,
    speciesId: id,
    displayName: id,
    bank: bank,
    position: position,
    partyId: bank,
    partyIndex: partyIndex,
    level: 10,
    types: const BattleTypes(primary: 'normal'),
    stats: const BattleComputedStats(
      attack: 10,
      defense: 10,
      specialAttack: 10,
      specialDefense: 10,
      speed: 10,
    ),
    hp: hp,
    maxHp: 40,
    moves: <BattleMoveInstance>[
      BattleMoveInstance(
        id: 'tackle',
        dbSymbol: 'tackle',
        pp: 35,
        maxPp: 35,
      ),
    ],
  );
}

BattleEngineSetup _engineSetup() {
  return BattleEngineSetup.singles(
    player: _combatantSetup(
      id: 'player-bulbasaur',
      speciesId: 'bulbasaur',
      moves: <PsdkBattleMoveData>[_move(power: 90)],
    ),
    opponent: _combatantSetup(
      id: 'opponent-squirtle',
      speciesId: 'squirtle',
      moves: <PsdkBattleMoveData>[_move(power: 40)],
    ),
    rngSeeds: const PsdkBattleRngSeeds(
      moveDamage: 1,
      moveCritical: 2,
      moveAccuracy: 3,
      generic: 4,
    ),
  );
}

PsdkBattleSetup _singlesSetup() => _engineSetup().psdkSetup;

PsdkBattleCombatantSetup _combatantSetup({
  required String id,
  required String speciesId,
  required List<PsdkBattleMoveData> moves,
}) {
  return PsdkBattleCombatantSetup(
    id: id,
    speciesId: speciesId,
    displayName: speciesId,
    level: 10,
    maxHp: 40,
    currentHp: 40,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 49,
      defense: 49,
      specialAttack: 65,
      specialDefense: 65,
      speed: 45,
    ),
    moves: moves,
  );
}

PsdkBattleMoveData _move({required int power}) {
  return PsdkBattleMoveData(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
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
