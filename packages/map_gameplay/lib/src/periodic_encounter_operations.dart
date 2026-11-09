import 'package:map_core/map_core.dart';

import 'gameplay_calendar.dart';

final class PeriodicEncounterOccurrence {
  const PeriodicEncounterOccurrence._({
    required this.definition,
    required this.calendar,
    required this.baseCalendar,
    required this.baseRewardState,
    required this.expectedClaimRevision,
    required this.saveId,
  });

  final PeriodicEncounterDefinition definition;
  final GameplayCalendarState calendar;
  final GameplayCalendarState baseCalendar;
  final PeriodicRewardState baseRewardState;
  final int expectedClaimRevision;
  final String saveId;
}

PeriodicEncounterOccurrence beginPeriodicEncounter(
  GameState state, {
  required PeriodicEncounterDefinition definition,
  required String localDay,
}) {
  final observed = observeGameplayCalendar(state, localDay: localDay);
  try {
    observed.periodicRewardState.validateCalendar(observed.gameplayCalendarState);
  } on FormatException {
    throw StateError('Periodic encounter calendar is inconsistent.');
  }
  final availability = readPeriodicRewardAvailability(
    calendar: observed.gameplayCalendarState,
    rewardState: observed.periodicRewardState,
    rewardId: definition.rewardId,
  );
  if (availability != PeriodicRewardAvailability.available) {
    throw StateError('Periodic encounter is unavailable: ${availability.name}.');
  }
  final revision = state.periodicRewardState.claimFor(definition.rewardId)?.revision ?? 0;
  if (revision >= GameplayCalendarState.maximumRevision) {
    throw StateError('Periodic encounter claim revision overflow.');
  }
  return PeriodicEncounterOccurrence._(
    definition: definition, calendar: observed.gameplayCalendarState,
    baseCalendar: state.gameplayCalendarState, baseRewardState: state.periodicRewardState,
    expectedClaimRevision: revision,
    saveId: state.saveId,
  );
}

GameState completePeriodicEncounter(
  GameState finalState, {
  required PeriodicEncounterOccurrence occurrence,
  required PeriodicEncounterOutcome? outcome,
}) {
  if (finalState.saveId != occurrence.saveId ||
      finalState.gameplayCalendarState != occurrence.baseCalendar ||
      finalState.periodicRewardState != occurrence.baseRewardState) {
    throw StateError('Periodic encounter state changed during battle.');
  }
  final observed = finalState.copyWith(gameplayCalendarState: occurrence.calendar);
  if (outcome == null || !occurrence.definition.consumeOnOutcomes.contains(outcome)) return observed;
  if (occurrence.expectedClaimRevision >= GameplayCalendarState.maximumRevision) {
    throw StateError('Periodic encounter claim revision overflow.');
  }
  return observed.copyWith(periodicRewardState: observed.periodicRewardState.withClaim(
    occurrence.definition.rewardId,
    PeriodicRewardClaim(revision: occurrence.expectedClaimRevision + 1,
      lastClaimDayRevision: occurrence.calendar.dayRevision,
      lastClaimLocalDay: occurrence.calendar.observedLocalDay!),
  ));
}
