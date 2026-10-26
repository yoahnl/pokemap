import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  final base = SpatialVisualPatch.fromJson({
    'timeMode': 'cycle',
    'dayNightEnabled': true,
    'dayDurationSeconds': 1200,
    'minuteOfDay': 360,
    'weatherMode': 'automatic',
    'weatherIntervalSeconds': 60,
    'weatherSequence': ['clear', 'cloudy', 'rain'],
  });
  test('one clock survives maps, pauses and a fresh save instance', () {
    final clock = WorldEnvironmentClock(now: () => DateTime(2026, 1, 1, 15));
    clock.advance(120);
    expect(clock.resolve(base).minuteOfDay, 504);
    expect(clock.resolve(base).weatherKind, SpatialWeatherKind.rain);
    clock.advance(30, paused: true);
    expect(clock.elapsedSeconds, 120);
    final state = GameState(saveId: 'save', environmentState: clock.checkpoint);
    final reopened = WorldEnvironmentClock(
        now: () => DateTime(2026),
        initialState: GameState.fromJson(state.toJson()).environmentState);
    expect(reopened.resolve(base).minuteOfDay, 504);
    expect(reopened.resolve(base).weatherKind, SpatialWeatherKind.rain);
    reopened.advance(60);
    expect(reopened.resolve(base).weatherKind, SpatialWeatherKind.clear);
  });
  test('real local time ignores game acceleration and follows resume', () {
    var now = DateTime(2026, 10, 26, 18, 30);
    final clock = WorldEnvironmentClock(now: () => now);
    final settings = base.set(SpatialVisualParameter.timeMode, 'real');
    clock.advance(5000);
    expect(clock.resolve(settings).minuteOfDay, 1110);
    now = DateTime(2026, 10, 27, 7, 15);
    expect(clock.resolve(settings).minuteOfDay, 435);
  });
  test(
      'story overrides resolve per field then return to the active lower layer',
      () {
    final clock = WorldEnvironmentClock(now: () => DateTime(2026, 10, 26, 18));
    clock.advance(75);
    final fact = SpatialVisualPatch.fromJson(
        {'minuteOfDay': 1320, 'weatherKind': 'storm'});
    final cinematic = SpatialVisualPatch.fromJson({'minuteOfDay': 360});
    var overlay = fact.overriddenBy(cinematic);
    var frame = clock.resolve(base.overriddenBy(overlay), overrides: overlay);
    expect(frame.minuteOfDay, 360);
    expect(frame.weatherKind, isNull);
    frame = clock.resolve(base.overriddenBy(fact), overrides: fact);
    expect(frame.minuteOfDay, 1320);
    expect(frame.weatherKind, isNull);
    frame = clock.resolve(base);
    expect(frame.minuteOfDay, 450);
    expect(frame.weatherKind, SpatialWeatherKind.cloudy);
    expect(
        clock
            .resolve(
                base
                    .set(SpatialVisualParameter.timeMode, 'real')
                    .overriddenBy(fact),
                overrides: fact)
            .minuteOfDay,
        1320);
    expect(
        clock
            .resolve(base.set(SpatialVisualParameter.timeMode, 'real'))
            .minuteOfDay,
        1080);
  });
  test(
      'legacy projects keep legacy presentation timing and omit new save state',
      () {
    final clock = WorldEnvironmentClock(
        now: () => throw StateError('unexpected wall clock read'));
    clock.advance(20);
    expect(clock.resolve(SpatialVisualPatch()).minuteOfDay, isNull);
    expect(clock.checkpoint, isNull);
    expect(() => clock.advance(double.nan), throwsArgumentError);
  });
}
