import '../models/gameplay_calendar.dart';
import '../models/periodic_reward.dart';

enum PeriodicRewardAvailability {
  available,
  alreadyClaimed,
  calendarUninitialized,
  calendarInconsistent;

  bool? get value => switch (this) {
    available => true,
    alreadyClaimed => false,
    calendarUninitialized || calendarInconsistent => null,
  };

  bool matches({required bool expectedValue}) {
    final resolved = value;
    return resolved != null && resolved == expectedValue;
  }
}

PeriodicRewardAvailability readPeriodicRewardAvailability({
  required GameplayCalendarState calendar,
  required PeriodicRewardState rewardState,
  required String rewardId,
}) {
  final day = calendar.observedLocalDay;
  if (day == null) {
    return PeriodicRewardAvailability.calendarUninitialized;
  }
  final previous = rewardState.claimFor(rewardId);
  if (previous == null) return PeriodicRewardAvailability.available;
  if (calendar.dayRevision < previous.lastClaimDayRevision) {
    return PeriodicRewardAvailability.calendarInconsistent;
  }
  if (calendar.dayRevision == previous.lastClaimDayRevision ||
      GameplayCalendarState.localDayNumber(day) <=
          GameplayCalendarState.localDayNumber(previous.lastClaimLocalDay)) {
    return PeriodicRewardAvailability.alreadyClaimed;
  }
  return PeriodicRewardAvailability.available;
}
