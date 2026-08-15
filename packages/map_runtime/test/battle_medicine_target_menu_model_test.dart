import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/presentation/flame/battle_medicine_target_menu_model.dart';

const _healUse = ProjectItemUseDefinition(
  contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
  target: ProjectItemTargetKind.partyMember,
  consumption: ProjectItemConsumptionPolicy.onApplied,
  effect: ProjectItemEffectDefinition.healHp(
    mode: ProjectItemAmountMode.flat,
    amount: 20,
  ),
);

const _cureUse = ProjectItemUseDefinition(
  contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
  target: ProjectItemTargetKind.partyMember,
  consumption: ProjectItemConsumptionPolicy.onApplied,
  effect: ProjectItemEffectDefinition.cureStatus(
    mode: ProjectItemStatusCureMode.listed,
    statusIds: <String>{'poison'},
  ),
);

const _reviveUse = ProjectItemUseDefinition(
  contexts: <ProjectItemUseContext>{ProjectItemUseContext.battle},
  target: ProjectItemTargetKind.partyMember,
  consumption: ProjectItemConsumptionPolicy.onApplied,
  effect: ProjectItemEffectDefinition.revive(
    rateNumerator: 1,
    rateDenominator: 2,
  ),
);

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
  BattleMajorStatusState? majorStatus,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: lineupIndex,
    level: level,
    maxHp: maxHp,
    currentHp: currentHp,
    majorStatus: majorStatus,
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
    BattleSetup.pokeMapBetaV1ForTest(
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
        displayName: 'Potion',
        use: _healUse,
      );

      expect(model.itemId, equals('potion'));
      expect(model.displayName, equals('Potion'));
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
        displayName: 'Potion',
        use: _healUse,
      );

      expect(model.activeEntry.isSelectable, isTrue);
      expect(model.activeEntry.disabledReason, isNull);
      expect(model.hasSelectableEntries, isTrue);
    });

    test('carries max potion metadata while preserving target selectability',
        () {
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
        itemId: 'max-potion',
        displayName: 'Max Potion',
        use: _healUse,
      );

      expect(model.itemId, equals('max-potion'));
      expect(model.displayName, equals('Max Potion'));
      expect(model.activeEntry.isSelectable, isTrue);
      expect(model.activeEntry.disabledReason, isNull);
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
        displayName: 'Potion',
        use: _healUse,
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
        displayName: 'Potion',
        use: _healUse,
      );

      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        equals(BattleMedicineTargetDisabledReason.fainted),
      );
    });

    test('current request policy can keep damaged reserves visible but blocked',
        () {
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
              speciesId: 'bench_one',
              lineupIndex: 1,
              currentHp: 10,
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
        displayName: 'Potion',
        use: _healUse,
        isTargetAllowed: (combatant) => combatant.lineupIndex == 0,
      );

      expect(model.activeEntry.isSelectable, isTrue);
      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        equals(BattleMedicineTargetDisabledReason.notAllowedByCurrentRequest),
      );
      expect(model.hasSelectableEntries, isTrue);
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
        displayName: 'Potion',
        use: _healUse,
      );

      expect(model.hasSelectableEntries, isFalse);
      expect(
        model.entries.map((entry) => entry.isSelectable),
        const <bool>[false, false, false],
      );
    });

    test('status medicine selects only targets with a compatible status', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            majorStatus: const BattleMajorStatusState.psn(),
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'healthy_bench',
              lineupIndex: 1,
              moves: <BattleMoveData>[
                _move(id: 'scratch', name: 'Scratch'),
              ],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'antidote',
        displayName: 'Antidote',
        use: _cureUse,
      );

      expect(model.activeEntry.isSelectable, isTrue);
      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        BattleMedicineTargetDisabledReason.noCompatibleStatus,
      );
    });

    test('revive selects only fainted targets, including reserves', () {
      final model = buildBattleMedicineTargetMenuModel(
        session: _session(
          player: _combatant(
            speciesId: 'sproutle',
            lineupIndex: 0,
            currentHp: 40,
            moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
          ),
          playerReserve: <BattleCombatantData>[
            _combatant(
              speciesId: 'fainted_bench',
              lineupIndex: 1,
              currentHp: 0,
              moves: <BattleMoveData>[
                _move(id: 'scratch', name: 'Scratch'),
              ],
            ),
          ],
          enemy: _combatant(
            speciesId: 'wild_enemy',
            lineupIndex: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ),
        itemId: 'revive',
        displayName: 'Revive',
        use: _reviveUse,
      );

      expect(model.activeEntry.isSelectable, isFalse);
      expect(
        model.activeEntry.disabledReason,
        BattleMedicineTargetDisabledReason.notFainted,
      );
      expect(model.reserveEntries.single.isSelectable, isTrue);
      expect(model.hasSelectableEntries, isTrue);
    });
  });
}
