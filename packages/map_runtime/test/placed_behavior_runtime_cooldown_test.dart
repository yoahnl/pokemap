import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/placed_behavior_runtime_cooldown.dart';

void main() {
  group('PlacedBehaviorCooldownGate', () {
    const keyShowMessage = PlacedBehaviorRuntimeKey(
      instanceId: 'instance_a',
      behaviorId: 'behavior_a',
      trigger: MapPlacedElementTriggerType.onNear,
      effectType: MapPlacedElementEffectType.showMessage,
    );
    const keyDialogue = PlacedBehaviorRuntimeKey(
      instanceId: 'instance_a',
      behaviorId: 'behavior_b',
      trigger: MapPlacedElementTriggerType.onAction,
      effectType: MapPlacedElementEffectType.openDialogue,
    );
    const keyAnimationToggle = PlacedBehaviorRuntimeKey(
      instanceId: 'instance_a',
      behaviorId: 'behavior_c',
      trigger: MapPlacedElementTriggerType.onAction,
      effectType: MapPlacedElementEffectType.setAnimationEnabled,
    );

    test('showMessage is blocked until cooldown expires', () {
      final gate = PlacedBehaviorCooldownGate();
      expect(gate.canTrigger(key: keyShowMessage, nowMs: 0), isTrue);
      gate.markTriggered(key: keyShowMessage, nowMs: 0);
      expect(gate.canTrigger(key: keyShowMessage, nowMs: 100), isFalse);
      expect(gate.remainingMs(key: keyShowMessage, nowMs: 100), greaterThan(0));
      expect(gate.canTrigger(key: keyShowMessage, nowMs: 700), isTrue);
    });

    test('openDialogue has longer guard than playAnimationOnce defaults', () {
      final gate = PlacedBehaviorCooldownGate();
      gate.markTriggered(key: keyDialogue, nowMs: 0);
      expect(gate.canTrigger(key: keyDialogue, nowMs: 800), isFalse);
      expect(gate.canTrigger(key: keyDialogue, nowMs: 950), isTrue);
    });

    test('explicit cooldown override replaces effect default', () {
      final gate = PlacedBehaviorCooldownGate();
      gate.markTriggered(
        key: keyDialogue,
        nowMs: 0,
        overrideDuration: const Duration(milliseconds: 250),
      );
      expect(gate.canTrigger(key: keyDialogue, nowMs: 200), isFalse);
      expect(gate.canTrigger(key: keyDialogue, nowMs: 260), isTrue);
    });

    test('explicit zero cooldown disables blocking', () {
      final gate = PlacedBehaviorCooldownGate();
      gate.markTriggered(
        key: keyShowMessage,
        nowMs: 0,
        overrideDuration: Duration.zero,
      );
      expect(gate.canTrigger(key: keyShowMessage, nowMs: 0), isTrue);
      expect(gate.canTrigger(key: keyShowMessage, nowMs: 1), isTrue);
    });

    test('setAnimationEnabled remains immediate and idempotent-friendly', () {
      final gate = PlacedBehaviorCooldownGate();
      gate.markTriggered(key: keyAnimationToggle, nowMs: 0);
      expect(gate.canTrigger(key: keyAnimationToggle, nowMs: 0), isTrue);
      expect(gate.canTrigger(key: keyAnimationToggle, nowMs: 1), isTrue);
    });

    test('cooldown key isolates behaviors by behaviorId', () {
      final gate = PlacedBehaviorCooldownGate();
      const otherBehaviorKey = PlacedBehaviorRuntimeKey(
        instanceId: 'instance_a',
        behaviorId: 'behavior_other',
        trigger: MapPlacedElementTriggerType.onNear,
        effectType: MapPlacedElementEffectType.showMessage,
      );
      gate.markTriggered(key: keyShowMessage, nowMs: 0);
      expect(gate.canTrigger(key: keyShowMessage, nowMs: 100), isFalse);
      expect(gate.canTrigger(key: otherBehaviorKey, nowMs: 100), isTrue);
    });
  });
}
