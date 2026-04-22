import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_medicine_target_menu_model.dart';

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
}) {
  return BattleMoveData(
    id: id,
    name: name,
    power: 40,
    type: 'normal',
    category: BattleMoveCategory.physical,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required int lineupIndex,
  int level = 30,
  int maxHp = 40,
  int? currentHp,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    stats: _stats(),
    moves: moves,
  );
}

BattleSession _session({
  required BattleCombatantData player,
  List<BattleCombatantData> playerReserve = const <BattleCombatantData>[],
  required BattleCombatantData enemy,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: true,
      trainerId: 'trainer',
    ),
  );
}

void main() {
  group('BattleMedicineTargetMenuModel', () {
    test('lists the active pokemon then reserves in battle lineup order', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 4,
            currentHp: 25,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'bench_one',
              lineupIndex: 7,
              currentHp: 10,
              maxHp: 35,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
            _combatant(
              speciesId: 'bench_two',
              lineupIndex: 9,
              currentHp: 35,
              maxHp: 35,
              moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.itemId, equals('potion'));
      expect(model.categoryId, equals('medicine'));
      expect(model.entries.map((entry) => entry.speciesId), const <String>[
        'sproutle',
        'bench_one',
        'bench_two',
      ]);
      expect(model.entries.map((entry) => entry.visualIndex), const <int>[
        0,
        1,
        2,
      ]);
      expect(model.entries.map((entry) => entry.lineupIndex), const <int>[
        4,
        7,
        9,
      ]);
      expect(model.entries.map((entry) => entry.reserveIndex), const <int?>[
        null,
        0,
        1,
      ]);
    });

    test('damaged living pokemon are selectable', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 15,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.activeEntry.isSelectable, isTrue);
      expect(model.activeEntry.disabledReason, isNull);
      expect(model.hasSelectableEntries, isTrue);
    });

    test('full hp pokemon stay visible but non-selectable', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.activeEntry.isSelectable, isFalse);
      expect(
        model.activeEntry.disabledReason,
        equals(BattleMedicineTargetDisabledReason.fullHp),
      );
    });

    test('fainted pokemon stay visible but non-selectable', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 20,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'fainted_bench',
              lineupIndex: 2,
              currentHp: 0,
              maxHp: 30,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        equals(BattleMedicineTargetDisabledReason.fainted),
      );
    });

    test('hasSelectableEntries is false when everyone is full hp or fainted',
        () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 40,
            maxHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'full_bench',
              lineupIndex: 1,
              currentHp: 30,
              maxHp: 30,
              moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
            ),
            _combatant(
              speciesId: 'fainted_bench',
              lineupIndex: 2,
              currentHp: 0,
              maxHp: 30,
              moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl')],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'potion',
        categoryId: 'medicine',
      );

      expect(model.hasSelectableEntries, isFalse);
      expect(
        model.entries.map((entry) => entry.isSelectable),
        const <bool>[false, false, false],
      );
    });
  });
}
