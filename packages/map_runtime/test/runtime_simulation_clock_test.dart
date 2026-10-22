import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_runtime/src/application/runtime_simulation_clock.dart';

void main() {
  test('new clocks start at normal speed and accept only test presets', () {
    final clock = RuntimeSimulationClock();
    expect(clock.speed.value, PlaytestSpeed.normal);
    expect(PlaytestSpeed.values.map((value) => value.multiplier), [
      1,
      2,
      5,
      10,
    ]);
    expect(() => PlaytestSpeed.fromMultiplier(100), throwsArgumentError);
    expect(() => PlaytestSpeed.fromMultiplier(1.5), throwsArgumentError);
    clock.dispose();
  });

  test(
    'normal frames preserve their delta and do not duplicate runtime work',
    () {
      final clock = RuntimeSimulationClock();
      final steps = <double>[];
      clock.advanceFrame(.016, steps.add);
      expect(steps, [.016]);
      clock.dispose();
    },
  );

  for (final multiplier in [1, 2, 5, 10]) {
    test('×$multiplier advances one clock in bounded identical steps', () {
      final clock = RuntimeSimulationClock();
      clock.speed.value = PlaytestSpeed.fromMultiplier(multiplier);
      final steps = <double>[];
      for (var i = 0; i < 60; i++) {
        clock.advanceFrame(1 / 60, steps.add);
      }
      expect(steps, hasLength(60 * multiplier));
      expect(steps.every((step) => step <= 1 / 60), isTrue);
      expect(
        steps.fold<double>(0, (total, step) => total + step),
        closeTo(multiplier, 1e-8),
      );
      clock.dispose();
    });
  }

  test('stalls are bounded without retaining a catch-up burst', () {
    final clock = RuntimeSimulationClock();
    clock.speed.value = PlaytestSpeed.fastest;
    var steps = 0;
    clock.advanceFrame(30, (_) => steps++);
    expect(steps, 600);
    clock.speed.value = PlaytestSpeed.normal;
    clock.advanceFrame(1 / 60, (_) => steps++);
    expect(steps, 601);
    for (final invalid in [-1.0, double.nan, double.infinity]) {
      expect(() => clock.advanceFrame(invalid, (_) {}), throwsArgumentError);
    }
    clock.dispose();
  });
}
