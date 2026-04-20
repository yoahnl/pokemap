import 'package:flutter_test/flutter_test.dart';
import 'package:map_battle/map_battle.dart';
import 'package:map_runtime/src/presentation/flame/battle_party_menu_model.dart';

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
  bool isTrainerBattle = true,
}) {
  return createBattleSession(
    BattleSetup(
      playerPokemon: player,
      playerReservePokemon: playerReserve,
      enemyPokemon: enemy,
      isTrainerBattle: isTrainerBattle,
      trainerId: isTrainerBattle ? 'trainer' : null,
    ),
  );
}

void main() {
  group('BattlePartyMenuModel', () {
    test('turn libre avec réserve valide expose un switch sélectionnable', () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench',
            lineupIndex: 1,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.mode, equals(BattlePartyMenuMode.voluntarySwitch));
      expect(model.activeEntry.speciesId, equals('lead'));
      expect(model.activeEntry.isActive, isTrue);
      expect(model.activeEntry.isSelectable, isFalse);
      expect(
        model.activeEntry.disabledReason,
        equals(BattlePartyMenuDisabledReason.activePokemon),
      );
      expect(model.reserveEntries, hasLength(1));
      expect(model.reserveEntries.single.speciesId, equals('bench'));
      expect(model.reserveEntries.single.isSelectable, isTrue);
      expect(model.reserveEntries.single.visualIndex, equals(1));
      expect(model.reserveEntries.single.reserveIndex, equals(0));
      expect(
        model.reserveEntries.single.playerChoice,
        isA<PlayerBattleChoiceSwitch>()
            .having((choice) => choice.reserveIndex, 'reserveIndex', 0),
      );
    });

    test('tour libre avec réserve K.O. garde les entrées visibles mais grisées',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'fainted_bench',
            lineupIndex: 1,
            currentHp: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.mode, equals(BattlePartyMenuMode.unavailable));
      expect(model.activeEntry.isSelectable, isFalse);
      expect(
        model.activeEntry.disabledReason,
        equals(BattlePartyMenuDisabledReason.activePokemon),
      );
      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        equals(BattlePartyMenuDisabledReason.fainted),
      );
      expect(model.reserveEntries.single.playerChoice, isNull);
      expect(model.hasSelectableEntries, isFalse);
    });

    test('remplacement forcé après K.O. expose seulement les switches valides',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench',
            lineupIndex: 1,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.mode, equals(BattlePartyMenuMode.forcedReplacement));
      expect(model.activeEntry.isFainted, isTrue);
      expect(model.activeEntry.isSelectable, isFalse);
      expect(model.reserveEntries.single.isSelectable, isTrue);
      expect(
        model.reserveEntries.single.playerChoice,
        isA<PlayerBattleChoiceSwitch>()
            .having((choice) => choice.reserveIndex, 'reserveIndex', 0),
      );
      expect(model.allEntries.where((entry) => entry.playerChoice != null),
          hasLength(1));
    });

    test(
        'remplacement forcé garde les reserveIndex exacts quand une réserve précédente est K.O.',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead',
          lineupIndex: 0,
          currentHp: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'fainted_one',
            lineupIndex: 1,
            currentHp: 0,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
          _combatant(
            speciesId: 'healthy_two',
            lineupIndex: 2,
            moves: <BattleMoveData>[_move(id: 'slash', name: 'Slash')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.mode, equals(BattlePartyMenuMode.forcedReplacement));
      expect(model.reserveEntries[0].reserveIndex, equals(0));
      expect(model.reserveEntries[0].isSelectable, isFalse);
      expect(
        model.reserveEntries[0].disabledReason,
        equals(BattlePartyMenuDisabledReason.fainted),
      );
      expect(model.reserveEntries[1].reserveIndex, equals(1));
      expect(model.reserveEntries[1].isSelectable, isTrue);
      expect(
        model.reserveEntries[1].playerChoice,
        isA<PlayerBattleChoiceSwitch>()
            .having((choice) => choice.reserveIndex, 'reserveIndex', 1),
      );
    });

    test('continue request rend le modèle non actionnable', () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead',
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
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench',
            lineupIndex: 1,
            moves: <BattleMoveData>[_move(id: 'slash', name: 'Slash')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.mode, equals(BattlePartyMenuMode.unavailable));
      expect(model.hasSelectableEntries, isFalse);
      expect(model.reserveEntries.single.isSelectable, isFalse);
      expect(
        model.reserveEntries.single.disabledReason,
        equals(BattlePartyMenuDisabledReason.notAllowedByCurrentRequest),
      );
      expect(model.reserveEntries.single.playerChoice, isNull);
    });

    test('équipe avec seulement l’actif ne crash pas et reste non actionnable',
        () {
      final session = _session(
        player: _combatant(
          speciesId: 'solo',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.activeEntry.speciesId, equals('solo'));
      expect(model.reserveEntries, isEmpty);
      expect(model.hasSelectableEntries, isFalse);
    });

    test('anti-confusion d’index garde le reserveIndex battle exact', () {
      final session = _session(
        player: _combatant(
          speciesId: 'lead',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'tackle', name: 'Tackle')],
        ),
        playerReserve: <BattleCombatantData>[
          _combatant(
            speciesId: 'bench_one',
            lineupIndex: 1,
            moves: <BattleMoveData>[_move(id: 'scratch', name: 'Scratch')],
          ),
          _combatant(
            speciesId: 'bench_two',
            lineupIndex: 2,
            moves: <BattleMoveData>[_move(id: 'slash', name: 'Slash')],
          ),
        ],
        enemy: _combatant(
          speciesId: 'enemy',
          lineupIndex: 0,
          moves: <BattleMoveData>[_move(id: 'growl', name: 'Growl', power: 0)],
        ),
      );

      final model = buildBattlePartyMenuModel(session: session);

      expect(model.mode, equals(BattlePartyMenuMode.voluntarySwitch));
      expect(model.reserveEntries[1].visualIndex, equals(2));
      expect(model.reserveEntries[1].reserveIndex, equals(1));
      expect(
        model.reserveEntries[1].playerChoice,
        isA<PlayerBattleChoiceSwitch>()
            .having((choice) => choice.reserveIndex, 'reserveIndex', 1),
      );
    });
  });
}
