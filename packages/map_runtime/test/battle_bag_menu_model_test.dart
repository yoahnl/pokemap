import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_bag_menu_model.dart';

BattleStatsSnapshot _stats() {
  return const BattleStatsSnapshot(
    attack: 60,
    defense: 60,
    specialAttack: 60,
    specialDefense: 60,
    speed: 60,
  );
}

BattleMoveData _move({
  required String id,
  required String name,
  int power = 40,
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: power,
    type: 'normal',
    category:
        power <= 0 ? BattleMoveCategory.status : BattleMoveCategory.physical,
    target: power <= 0 ? BattleMoveTarget.self : BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int level = 30,
  int maxHp = 40,
  int? currentHp,
  BattleVolatileState volatileState = const BattleVolatileState(),
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    volatileState: volatileState,
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
  bool isTrainerBattle = false,
  bool allowCapture = false,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
      allowCapture: allowCapture,
    ),
  );
}

PlayerPokemon _partyMember({
  required String speciesId,
  int level = 10,
  int currentHp = 20,
}) {
  return PlayerPokemon(
    speciesId: speciesId,
    natureId: 'hardy',
    abilityId: 'pressure',
    level: level,
    knownMoveIds: const <String>['tackle'],
    currentHp: currentHp,
  );
}

GameState _gameState({
  Bag bag = const Bag(),
  List<PlayerPokemon> partyMembers = const <PlayerPokemon>[],
}) {
  return GameState(
    saveId: 'save-bag-contract',
    bag: bag,
    party: PlayerParty(members: partyMembers),
  );
}

BagEntry _entry({
  required String itemId,
  required String categoryId,
  required int quantity,
}) {
  return BagEntry(
    itemId: itemId,
    categoryId: categoryId,
    quantity: quantity,
  );
}

void main() {
  group('BattleBagMenuModel', () {
    test('empty bag builds a non-actionable empty model', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(),
        session: session,
      );

      expect(model.mode, equals(BattleBagMenuMode.empty));
      expect(model.entries, isEmpty);
      expect(model.hasEntries, isFalse);
      expect(model.hasSelectableEntries, isFalse);
    });

    test(
        'wild battle with poke-ball and allowed capture exposes a selectable capture entry',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 3),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(model.mode, equals(BattleBagMenuMode.available));
      expect(model.hasEntries, isTrue);
      expect(model.hasSelectableEntries, isTrue);
      expect(entry.itemId, equals('poke-ball'));
      expect(entry.quantity, equals(3));
      expect(entry.kind, equals(BattleBagItemKind.captureBall));
      expect(entry.isSelectable, isTrue);
      expect(entry.disabledReason, isNull);
      expect(
        entry.action,
        isA<BattleBagMenuActionCapture>().having(
          (action) => action.playerChoice,
          'playerChoice',
          isA<PlayerBattleChoiceCapture>(),
        ),
      );
    });

    test('trainer battle keeps poke-ball visible but disabled', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'trainermon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        isTrainerBattle: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.captureBall));
      expect(entry.isSelectable, isFalse);
      expect(
        entry.disabledReason,
        equals(BattleBagMenuDisabledReason.trainerBattle),
      );
      expect(entry.action, isNull);
    });

    test(
        'wild battle with poke-ball but full party keeps capture disabled with an explicit reason',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: false,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'a'),
            _partyMember(speciesId: 'b'),
            _partyMember(speciesId: 'c'),
            _partyMember(speciesId: 'd'),
            _partyMember(speciesId: 'e'),
            _partyMember(speciesId: 'f'),
          ],
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.isSelectable, isFalse);
      expect(
        entry.disabledReason,
        equals(BattleBagMenuDisabledReason.partyFull),
      );
      expect(entry.action, isNull);
    });

    test('forced replacement keeps bag visible but non-actionable', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmon',
            lineupIndex: 1,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            ],
          ),
        ),
        session: session,
      );

      expect(model.mode, equals(BattleBagMenuMode.unavailable));
      expect(model.hasEntries, isTrue);
      expect(model.hasSelectableEntries, isFalse);
      expect(
        model.entries.single.disabledReason,
        equals(BattleBagMenuDisabledReason.currentRequestDisallowsBag),
      );
      expect(model.entries.single.action, isNull);
    });

    test('continue request never exposes a fake capture action', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          volatileState: const BattleVolatileState(mustRecharge: true),
          moves: <BattleMoveData>[
            const BattleMoveData(
              id: 'hyper_beam',
              name: 'Hyper Beam',
              power: 150,
              requiresRecharge: true,
            ),
          ],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
            ],
          ),
        ),
        session: session,
      );

      expect(model.hasSelectableEntries, isFalse);
      expect(model.entries.single.action, isNull);
      expect(
        model.entries.single.disabledReason,
        equals(BattleBagMenuDisabledReason.currentRequestDisallowsBag),
      );
    });

    test(
        'supported potion is selectable in a free turn and opens a medicine target action',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'potion', categoryId: 'medicine', quantity: 4),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.medicine));
      expect(entry.quantity, equals(4));
      expect(entry.isSelectable, isTrue);
      expect(entry.disabledReason, isNull);
      expect(
        entry.action,
        isA<BattleBagMenuActionMedicineTarget>()
            .having((action) => action.itemId, 'itemId', equals('potion'))
            .having(
              (action) => action.categoryId,
              'categoryId',
              equals('medicine'),
            )
            .having((action) => action.quantity, 'quantity', equals(4)),
      );
    });

    test(
        'supported super potion is selectable in a free turn and opens a medicine target action',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(
                itemId: 'super-potion',
                categoryId: 'medicine',
                quantity: 2,
              ),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.medicine));
      expect(entry.quantity, equals(2));
      expect(entry.isSelectable, isTrue);
      expect(entry.disabledReason, isNull);
      expect(
        entry.action,
        isA<BattleBagMenuActionMedicineTarget>()
            .having(
              (action) => action.itemId,
              'itemId',
              equals('super-potion'),
            )
            .having(
              (action) => action.categoryId,
              'categoryId',
              equals('medicine'),
            )
            .having((action) => action.quantity, 'quantity', equals(2)),
      );
    });

    test(
        'supported hyper potion is selectable in a free turn and opens a medicine target action',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(
                itemId: 'hyper-potion',
                categoryId: 'medicine',
                quantity: 1,
              ),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.medicine));
      expect(entry.quantity, equals(1));
      expect(entry.isSelectable, isTrue);
      expect(entry.disabledReason, isNull);
      expect(
        entry.action,
        isA<BattleBagMenuActionMedicineTarget>()
            .having(
              (action) => action.itemId,
              'itemId',
              equals('hyper-potion'),
            )
            .having(
              (action) => action.categoryId,
              'categoryId',
              equals('medicine'),
            )
            .having((action) => action.quantity, 'quantity', equals(1)),
      );
    });

    test('unsupported medicine stays visible but disabled', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: true,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'antidote', categoryId: 'medicine', quantity: 2),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.medicine));
      expect(entry.quantity, equals(2));
      expect(entry.isSelectable, isFalse);
      expect(
        entry.disabledReason,
        equals(BattleBagMenuDisabledReason.unsupportedMedicine),
      );
      expect(entry.action, isNull);
    });

    test('potion is non-selectable when the current request disallows bag', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'benchmon',
            lineupIndex: 1,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.medicine));
      expect(entry.isSelectable, isFalse);
      expect(
        entry.disabledReason,
        equals(BattleBagMenuDisabledReason.currentRequestDisallowsBag),
      );
      expect(entry.action, isNull);
    });

    test('unknown items stay visible but unsupported', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'mystery-box', categoryId: 'quest', quantity: 1),
            ],
          ),
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.unsupported));
      expect(entry.isSelectable, isFalse);
      expect(
        entry.disabledReason,
        equals(BattleBagMenuDisabledReason.unsupportedItem),
      );
      expect(entry.action, isNull);
    });

    test('duplicate bag entries are merged through Bag.normalized()', () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'potion', categoryId: 'medicine', quantity: 1),
              _entry(itemId: 'potion', categoryId: 'medicine', quantity: 3),
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 1),
            ],
          ),
        ),
        session: session,
      );

      expect(model.entries, hasLength(2));
      expect(model.entries[0].itemId, equals('poke-ball'));
      expect(model.entries[0].quantity, equals(3));
      expect(model.entries[1].itemId, equals('potion'));
      expect(model.entries[1].quantity, equals(4));
    });

    test(
        'capture action is never synthesized when the current request does not allow it',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'sproutle',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'wildmon',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
        ),
        allowCapture: false,
      );

      final model = buildBattleBagMenuModel(
        gameState: _gameState(
          bag: Bag(
            entries: <BagEntry>[
              _entry(itemId: 'poke-ball', categoryId: 'items', quantity: 2),
            ],
          ),
          partyMembers: <PlayerPokemon>[
            _partyMember(speciesId: 'a'),
            _partyMember(speciesId: 'b'),
          ],
        ),
        session: session,
      );

      final entry = model.entries.single;
      expect(entry.kind, equals(BattleBagItemKind.captureBall));
      expect(entry.isSelectable, isFalse);
      expect(
        entry.disabledReason,
        equals(BattleBagMenuDisabledReason.captureUnavailable),
      );
      expect(entry.action, isNull);
    });
  });
}
