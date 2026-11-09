import '../models/civil_weekday.dart';
import '../models/gameplay_calendar.dart';
import 'narrative_condition_expression_evaluator.dart';

NarrativeConditionEvaluation evaluateCivilWeekdayCondition({
  required CivilWeekday weekday,
  required bool expectedValue,
  required GameplayCalendarState calendar,
}) {
  final day = calendar.observedLocalDay;
  if (day == null) {
    return const NarrativeConditionEvaluation(passed: false, unavailable: true);
  }
  try {
    final dayNumber = GameplayCalendarState.localDayNumber(day);
    final actual = CivilWeekday.values[(dayNumber + 3) % 7];
    return NarrativeConditionEvaluation(
      passed: (actual == weekday) == expectedValue,
    );
  } on FormatException {
    return const NarrativeConditionEvaluation(passed: false, unavailable: true);
  }
}
