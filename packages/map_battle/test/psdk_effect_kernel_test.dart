import 'package:map_battle/map_battle.dart';
import 'package:test/test.dart';

void main() {
  group('PSDK effect kernel', () {
    test('stores effect objects while preserving id-based compatibility', () {
      final stack = PsdkBattleEffectStack(
        values: const <String>[PsdkBattleEffectIds.protect],
      );

      expect(stack.contains(PsdkBattleEffectIds.protect), isTrue);
      expect(stack.values, <String>[PsdkBattleEffectIds.protect]);
      expect(stack.effects.single, isA<ProtectEffect>());
      expect(stack.clearTurnScopedEffects().values, isEmpty);
    });

    test('addEffect replaces an existing effect with the same id', () {
      final stack = const PsdkBattleEffectStack.empty()
          .addEffect(const GenericBattleEffect(id: 'gravity'))
          .addEffect(const GenericBattleEffect(id: 'gravity'));

      expect(stack.values, <String>['gravity']);
    });

    test('Protect effect blocks target moves but not self or non-protectable moves',
        () {
      final stack = const PsdkBattleEffectStack.empty().addEffect(
        const ProtectEffect(scope: LocalBattleEffectScope()),
      );
      const user = BattlePositionRef(bank: 1, position: 0);
      const target = BattlePositionRef(bank: 0, position: 0);

      expect(
        stack.targetMovePreventionReason(
          user: user,
          target: target,
          move: _move(protectable: true),
        ),
        BattleMoveFailureReason.protected,
      );
      expect(
        stack.targetMovePreventionReason(
          user: target,
          target: target,
          move: _move(protectable: true),
        ),
        isNull,
      );
      expect(
        stack.targetMovePreventionReason(
          user: user,
          target: target,
          move: _move(protectable: false),
        ),
        isNull,
      );
    });
  });
}

BattleMoveDefinition _move({required bool protectable}) {
  return BattleMoveDefinition(
    id: 'tackle',
    dbSymbol: 'tackle',
    name: 'Tackle',
    type: 'normal',
    category: PsdkBattleMoveCategory.physical,
    power: 40,
    accuracy: 100,
    pp: 35,
    priority: 0,
    battleEngineMethod: 's_basic',
    target: PsdkBattleMoveTarget.adjacentFoe,
    flags: BattleMoveFlags(protectable: protectable),
  );
}
