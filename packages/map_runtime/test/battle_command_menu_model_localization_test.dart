import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_command_menu_model.dart';

void main() {
  BattleSession session() {
    return createBattleSession(
      BattleSetup.pokeMapBetaV1ForTest(
        playerPokemon: _combatant(
          speciesId: 'pikachu',
          moves: <BattleMoveData>[
            _move(id: 'thunderbolt', name: 'Thunderbolt'),
          ],
        ),
        enemyPokemon: _combatant(
          speciesId: 'squirtle',
          moves: <BattleMoveData>[
            _move(id: 'tackle', name: 'Tackle'),
          ],
        ),
        isTrainerBattle: true,
        trainerId: 'trainer',
      ),
    );
  }

  test('a move entry uses the resolved display name', () {
    final model = buildBattleCommandMenuModel(
      session: session(),
      mode: BattleCommandMenuMode.fight,
      selectedRootIndex: 0,
      selectedChoiceIndex: 0,
      resolveMoveDisplayName: (moveId, fallbackName) =>
          moveId == 'thunderbolt' ? 'Tonnerre' : fallbackName,
    );

    expect(model.choiceEntries.first.title, 'Tonnerre');
  });

  test('a move entry falls back to the battle name', () {
    final model = buildBattleCommandMenuModel(
      session: session(),
      mode: BattleCommandMenuMode.fight,
      selectedRootIndex: 0,
      selectedChoiceIndex: 0,
      resolveMoveDisplayName: (moveId, fallbackName) => fallbackName,
    );

    expect(model.choiceEntries.first.title, 'Thunderbolt');
  });

  test('the resolver is optional and defaults to the battle name', () {
    final model = buildBattleCommandMenuModel(
      session: session(),
      mode: BattleCommandMenuMode.fight,
      selectedRootIndex: 0,
      selectedChoiceIndex: 0,
    );

    expect(model.choiceEntries.first.title, 'Thunderbolt');
  });
}

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
    power: 90,
    type: 'electric',
    category: BattleMoveCategory.special,
    target: BattleMoveTarget.opponent,
  );
}

BattleCombatantData _combatant({
  required String speciesId,
  required List<BattleMoveData> moves,
}) {
  return BattleCombatantData(
    speciesId: speciesId,
    lineupIndex: 0,
    level: 30,
    maxHp: 40,
    catchRate: 45,
    stats: _stats(),
    volatileState: const BattleVolatileState(),
    moves: moves,
  );
}
