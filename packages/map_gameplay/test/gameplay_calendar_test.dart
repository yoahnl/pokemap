import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const initial = GameState(saveId: 'calendar');
  test('first observation anchors without granting day changes', () {
    final observed = observeGameplayCalendar(initial, localDay: '2026-10-30');
    expect(observed.gameplayCalendarState.observedLocalDay, '2026-10-30');
    expect(observed.gameplayCalendarState.dayRevision, 0);
    expect(initial.gameplayCalendarState.isInitialized, isFalse);
    expect(observeGameplayCalendar(observed, localDay: '2026-10-30'),
        same(observed));
  });
  test('positive date difference increments the persistent revision', () {
    final first = observeGameplayCalendar(initial, localDay: '2026-10-30');
    final later = observeGameplayCalendar(first, localDay: '2026-11-02');
    expect(later.gameplayCalendarState.dayRevision, 3);
    final restored = GameState.fromJson(later.toJson());
    expect(
        observeGameplayCalendar(restored, localDay: '2026-11-03')
            .gameplayCalendarState
            .dayRevision,
        4);
  });
  test('clock rollback reanchors without reward then the next advance counts',
      () {
    final first = observeGameplayCalendar(initial, localDay: '2026-10-30');
    final backwards = observeGameplayCalendar(first, localDay: '2026-10-29');
    expect(backwards.gameplayCalendarState.dayRevision, 0);
    expect(backwards.gameplayCalendarState.observedLocalDay, '2026-10-29');
    expect(
        observeGameplayCalendar(backwards, localDay: '2026-10-30')
            .gameplayCalendarState
            .dayRevision,
        1);
  });
  test('explicit timezone or clock-context rebase never credits elapsed days',
      () {
    final first = observeGameplayCalendar(initial, localDay: '2026-10-30');
    final reanchored =
        observeGameplayCalendar(first, localDay: '2026-11-02', rebase: true);
    expect(reanchored.gameplayCalendarState.dayRevision, 0);
    expect(
        observeGameplayCalendar(reanchored, localDay: '2026-11-03')
            .gameplayCalendarState
            .dayRevision,
        1);
  });
  test('civil days use Gregorian dates rather than 24-hour or DST durations',
      () {
    final leap = observeGameplayCalendar(initial, localDay: '2028-02-28');
    expect(
        observeGameplayCalendar(leap, localDay: '2028-03-01')
            .gameplayCalendarState
            .dayRevision,
        2);
    final dst = observeGameplayCalendar(initial, localDay: '2026-03-28');
    expect(
        observeGameplayCalendar(dst, localDay: '2026-03-30')
            .gameplayCalendarState
            .dayRevision,
        2);
  });
  for (final day in [
    '2026-02-29',
    '2026-00-01',
    '2026-13-01',
    '2026-10-00',
    '2026-10-30T23:59:59Z',
    '2026-1-01',
    '0000-01-01'
  ]) {
    test('invalid date $day is rejected without changing state', () {
      expect(() => observeGameplayCalendar(initial, localDay: day),
          throwsFormatException);
      expect(
          initial.gameplayCalendarState, const GameplayCalendarState.empty());
    });
  }
  test('calendar revision overflow is rejected before creating a new state',
      () {
    final state = initial.copyWith(
        gameplayCalendarState: GameplayCalendarState(
            observedLocalDay: '2026-10-30',
            dayRevision: GameplayCalendarState.maximumRevision));
    expect(() => observeGameplayCalendar(state, localDay: '2026-10-31'),
        throwsFormatException);
    expect(state.gameplayCalendarState.dayRevision,
        GameplayCalendarState.maximumRevision);
  });
}
