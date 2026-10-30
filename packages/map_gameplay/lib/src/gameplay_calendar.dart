import 'package:map_core/map_core.dart';

GameState observeGameplayCalendar(
  GameState state, {
  required String localDay,
  bool rebase = false,
}) {
  final observed = GameplayCalendarState.localDayNumber(localDay);
  final previous = state.gameplayCalendarState;
  if (previous.observedLocalDay == localDay) return state;
  var revision = previous.dayRevision;
  final day = previous.observedLocalDay;
  if (!rebase && day != null) {
    final delta = observed - GameplayCalendarState.localDayNumber(day);
    if (delta > 0) {
      if (revision > GameplayCalendarState.maximumRevision - delta) {
        throw const FormatException('Gameplay calendar revision overflow.');
      }
      revision += delta;
    }
  }
  return state.copyWith(
    gameplayCalendarState: GameplayCalendarState(
      observedLocalDay: localDay,
      dayRevision: revision,
    ),
  );
}
