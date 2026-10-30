import 'package:flutter_test/flutter_test.dart';
import 'package:map_runtime/src/presentation/flame/battle_idle_motion.dart';

void main() {
  test('waiting moves laterally and an attack holds the current pose', () {
    final motion = BattleIdleMotion(periodSeconds: 4);
    expect(motion.offsetRatio, 0);
    expect(motion.advance(1, waiting: true), closeTo(1, .00001));
    expect(motion.advance(20, waiting: false), closeTo(1, .00001));
    expect(motion.advance(1, waiting: true), closeTo(0, .00001));
    expect(motion.advance(1, waiting: true), closeTo(-1, .00001));
  });

  test('waiting is deterministic across refresh rates and pausing', () {
    final slow = BattleIdleMotion(periodSeconds: 4.8);
    final fast = BattleIdleMotion(periodSeconds: 4.8);
    for (var i = 0; i < 30; i++) {
      slow.advance(1 / 30, waiting: true);
    }
    fast.advance(20, waiting: false);
    for (var i = 0; i < 120; i++) {
      fast.advance(1 / 120, waiting: true);
    }
    expect(slow.offsetRatio, closeTo(fast.offsetRatio, .00001));
    expect(slow.advance(0, waiting: true), closeTo(fast.offsetRatio, .00001));
  });
}
