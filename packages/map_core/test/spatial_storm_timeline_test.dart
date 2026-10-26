import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  test(
    'storm events are deterministic, irregular and have delayed thunder',
    () {
      final events = [
        for (var i = 0; i < 15; i++) spatialStormEventAt(i * 24 + 23),
      ];
      final intervals = <int>{};
      final variants = <int>{};
      for (var i = 0; i < events.length; i++) {
        final event = events[i];
        expect(event.id, i);
        expect(
          event.thunderSeconds - event.strikeSeconds,
          inInclusiveRange(.45, 3.5),
        );
        expect(spatialStormEventAt(event.strikeSeconds + .01).id, event.id);
        expect(event.strength, inInclusiveRange(.65, 1));
        variants.add(event.soundVariant);
        if (i > 0) {
          intervals.add(
            ((event.strikeSeconds - events[i - 1].strikeSeconds) * 1000)
                .round(),
          );
        }
      }
      expect(intervals.length, greaterThan(8));
      expect(variants, {0, 1, 2});
      expect(() => spatialStormEventAt(double.nan), throwsArgumentError);
      expect(() => spatialStormEventAt(-1), throwsArgumentError);
    },
  );
}
