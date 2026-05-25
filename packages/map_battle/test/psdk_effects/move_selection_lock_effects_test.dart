import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/domain/effect/move/embargo_effect.dart';
import 'package:map_battle/src/domain/effect/move/heal_block_effect.dart';
import 'package:map_battle/src/domain/effect/move/imprison_effect.dart';
import 'package:map_battle/src/domain/effect/move/torment_effect.dart';
import 'package:map_battle/src/domain/move/battle_move_prevention.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK move selection lock effects', () {
    test('Torment disables only the last successful non-Struggle move', () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          TormentEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
        ),
        playerMoveHistory: PsdkBattleMoveHistory(
          successes: <PsdkBattleMoveHistoryEntry>[
            PsdkBattleMoveHistoryEntry(
              moveId: 'tackle',
              turn: 4,
              targets: <PsdkBattleSlotRef>[psdkOpponentSlot],
            ),
          ],
        ),
      );

      expect(_selection(state, _move(id: 'tackle')), isNotNull);
      expect(_selection(state, _move(id: 'ember')), isNull);
      expect(_selection(state, _move(id: 'struggle')), isNull);
    });

    test('Heal Block disables healing moves during selection', () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          HealBlockEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
        ),
      );

      expect(
        _selection(
          state,
          _move(
            id: 'recover',
            category: PsdkBattleMoveCategory.status,
            battleEngineMethod: 's_heal',
          ),
        ),
        isNotNull,
      );
      expect(_selection(state, _move(id: 'tackle')), isNull);
    });

    test('Imprison disables shared foe moves during selection', () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          ImprisonEffect(
            scope: BattlerBattleEffectScope(psdkPlayerSlot),
            imprisonedMoveIds: <String>{'tackle'},
          ),
        ),
      );

      expect(_selection(state, _move(id: 'tackle')), isNotNull);
      expect(_selection(state, _move(id: 'ember')), isNull);
      expect(_selection(state, _move(id: 'struggle')), isNull);
    });

    test('Throat Chop disables sound moves during selection', () {
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(
          ThroatChopEffect(scope: BattlerBattleEffectScope(psdkPlayerSlot)),
        ),
      );

      expect(
        _selection(
          state,
          _move(id: 'hyper_voice', flags: const BattleMoveFlags(sound: true)),
        ),
        isNotNull,
      );
      expect(_selection(state, _move(id: 'tackle')), isNull);
    });

    test('Embargo suppresses item effects and transfers through Baton Pass',
        () {
      const effect = EmbargoEffect(
        scope: BattlerBattleEffectScope(psdkPlayerSlot),
        remainingTurns: 4,
      );
      final state = _state(
        playerEffects: const PsdkBattleEffectStack.empty().addEffect(effect),
      );

      expect(state.battlerAt(psdkPlayerSlot).itemEffectsSuppressed, isTrue);

      final transferred = effect.onBatonPassTransfer(
        const BattleEffectBatonPassContext(
          source: psdkPlayerSlot,
          target: psdkOpponentSlot,
        ),
      );

      expect(transferred, isA<EmbargoEffect>());
      final transferredScope = transferred!.scope;
      expect(transferredScope, isA<BattlerBattleEffectScope>());
      expect((transferredScope as BattlerBattleEffectScope).slot,
          psdkOpponentSlot);
      expect(transferred.remainingTurns, 4);
    });
  });
}

BattleMoveSelectionPreventionResult? _selection(
  PsdkBattleState state,
  PsdkBattleMoveData move,
) {
  return state.battlerAt(psdkPlayerSlot).effects.moveSelectionPrevention(
        state: state,
        user: psdkPlayerSlot,
        target: psdkOpponentSlot,
        move: BattleMoveDefinition.fromPsdk(move),
      );
}

PsdkBattleState _state({
  PsdkBattleEffectStack playerEffects = const PsdkBattleEffectStack.empty(),
  PsdkBattleMoveHistory? playerMoveHistory,
}) {
  return PsdkBattleState(
    combatants: <PsdkBattleSlotRef, PsdkBattleCombatant>{
      psdkPlayerSlot: PsdkBattleCombatant.fromSetup(
        _combatant(
          effects: playerEffects,
          moveHistory: playerMoveHistory,
        ),
      ),
      psdkOpponentSlot: PsdkBattleCombatant.fromSetup(_combatant()),
    },
  );
}

PsdkBattleCombatantSetup _combatant({
  PsdkBattleEffectStack effects = const PsdkBattleEffectStack.empty(),
  PsdkBattleMoveHistory? moveHistory,
}) {
  return PsdkBattleCombatantSetup(
    id: 'mon',
    speciesId: 'mon',
    displayName: 'Mon',
    level: 50,
    maxHp: 100,
    currentHp: 100,
    types: const PsdkBattleTypes(primary: 'normal'),
    stats: const PsdkBattleStats(
      attack: 100,
      defense: 100,
      specialAttack: 100,
      specialDefense: 100,
      speed: 100,
    ),
    moves: <PsdkBattleMoveData>[_move(id: 'tackle')],
    effects: effects,
    moveHistory: moveHistory,
  );
}

PsdkBattleMoveData _move({
  required String id,
  PsdkBattleMoveCategory category = PsdkBattleMoveCategory.physical,
  String battleEngineMethod = 's_basic',
  BattleMoveFlags flags = const BattleMoveFlags(),
}) {
  return PsdkBattleMoveData(
    id: id,
    dbSymbol: id,
    name: id,
    type: 'normal',
    category: category,
    power: category == PsdkBattleMoveCategory.status ? 0 : 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: battleEngineMethod,
    target: PsdkBattleMoveTarget.adjacentFoe,
    sound: flags.sound,
    protectable: flags.protectable,
  );
}
