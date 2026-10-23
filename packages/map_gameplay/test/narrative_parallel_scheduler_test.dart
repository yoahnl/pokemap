import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

NarrativeParallelOwner owner(String id,
        {String activation = 'map:1', String? variant, int cadence = 100}) =>
    NarrativeParallelOwner(
      mapActivationId: activation,
      eventId: id,
      variantId: variant,
      policy: NarrativeEventParallelPolicy(cadenceMs: cadence),
    );

void main() {
  test('waits full cadence, executes once per update and never catches up', () {
    final scheduler = NarrativeParallelScheduler()..reconcile([owner('a')]);
    expect(scheduler.advance(0.099), isEmpty);
    expect(scheduler.advance(0.001).map((value) => value.eventId), ['a']);
    expect(scheduler.advance(60).map((value) => value.eventId), ['a']);
    expect(scheduler.advance(0), isEmpty);
  });

  test('limits update work and rotates fair owners', () {
    final scheduler = NarrativeParallelScheduler()
      ..reconcile([for (var i = 0; i < 8; i++) owner('$i')]);
    expect(scheduler.advance(0.1).map((value) => value.eventId),
        ['0', '1', '2', '3']);
    expect(scheduler.advance(0).map((value) => value.eventId),
        ['4', '5', '6', '7']);
  });

  test('page and map changes restart cadence and remove stale owners', () {
    final scheduler = NarrativeParallelScheduler()
      ..reconcile([owner('a', variant: 'page0')]);
    scheduler.advance(0.05);
    scheduler.reconcile([owner('a', variant: 'page1')]);
    expect(scheduler.advance(0.05), isEmpty);
    expect(scheduler.advance(0.05).single.variantId, 'page1');
    scheduler.reconcile([owner('a', activation: 'map:2')]);
    expect(scheduler.advance(0.05), isEmpty);
    scheduler.clear();
    expect(scheduler.advance(10), isEmpty);
  });

  test('suspension restarts full cadence and rejects nonfinite time', () {
    final scheduler = NarrativeParallelScheduler()..reconcile([owner('a')]);
    scheduler.advance(0.05);
    expect(scheduler.advance(10, suspended: true), isEmpty);
    expect(scheduler.advance(0.05), isEmpty);
    expect(scheduler.advance(0.05).length, 1);
    for (final delta in [double.nan, double.infinity, -1.0]) {
      expect(() => scheduler.advance(delta), throwsArgumentError);
    }
  });
}
