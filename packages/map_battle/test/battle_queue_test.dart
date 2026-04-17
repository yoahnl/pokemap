import 'package:map_battle/map_battle.dart';
import 'package:map_battle/src/battle_queue.dart';
import 'package:test/test.dart';

void main() {
  group('BattleTurnQueue Phase F', () {
    test(
        'preserves FIFO order while allowing explicit post-turn work to be appended dynamically',
        () {
      final queue = BattleTurnQueue(
        <BattleQueueStep>[
          BattleQueueActionStep(
            side: BattleSideId.player,
            slot: const BattleSlotRef.active(BattleSideId.player),
            action: const BattleActionSwitch(
              reserveIndex: 0,
            ),
          ),
          BattleQueueActionStep(
            side: BattleSideId.enemy,
            slot: const BattleSlotRef.active(BattleSideId.enemy),
            action: const BattleActionRecharge(),
          ),
        ],
      );

      expect(queue.isEmpty, isFalse);
      expect(queue.takeNext(), isA<BattleQueueActionStep>());

      queue.pushBack(const BattleQueueEndOfTurnStep());
      queue.pushBack(const BattleQueuePostTurnChecksStep());
      queue.pushBack(
        BattleQueueAutoSwitchStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          reserveIndex: 1,
        ),
      );
      queue.pushBack(
        BattleQueueReplacementRequiredStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          faintedSpeciesId: 'lead_player',
        ),
      );

      expect(queue.takeNext(), isA<BattleQueueActionStep>());
      expect(queue.takeNext(), isA<BattleQueueEndOfTurnStep>());
      expect(queue.takeNext(), isA<BattleQueuePostTurnChecksStep>());
      expect(queue.takeNext(), isA<BattleQueueAutoSwitchStep>());
      expect(queue.takeNext(), isA<BattleQueueReplacementRequiredStep>());
      expect(queue.isEmpty, isTrue);
    });

    test('queue steps reject mismatched side and slot attachments', () {
      expect(
        () => BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          action: const BattleActionRecharge(),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleQueueAutoSwitchStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.player),
          reserveIndex: 0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('queue-managed action steps reject out-of-turn actions', () {
      expect(
        () => BattleQueueActionStep(
          side: BattleSideId.player,
          slot: const BattleSlotRef.active(BattleSideId.player),
          action: const BattleActionRun(),
        ),
        throwsA(isA<ArgumentError>()),
      );

      expect(
        () => BattleQueueActionStep(
          side: BattleSideId.enemy,
          slot: const BattleSlotRef.active(BattleSideId.enemy),
          action: const BattleActionNone(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
