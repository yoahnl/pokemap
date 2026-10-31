import 'dart:convert';

import 'package:map_core/map_core_domain.dart';
import 'package:test/test.dart';

void main() {
  final claimed = PeriodicRewardState(
    claimsById: {
      'daily-fruit': PeriodicRewardClaim(
        revision: 3,
        lastClaimDayRevision: 4,
        lastClaimLocalDay: '2026-10-30',
      ),
    },
  );

  PeriodicRewardAvailability read(
    GameplayCalendarState calendar, {
    PeriodicRewardState? rewards,
    String rewardId = 'daily-fruit',
  }) => readPeriodicRewardAvailability(
    calendar: calendar,
    rewardState: rewards ?? claimed,
    rewardId: rewardId,
  );

  test('uninitialized calendar remains unknown with or without a claim', () {
    for (final rewards in [const PeriodicRewardState.empty(), claimed]) {
      final result = read(
        const GameplayCalendarState.empty(),
        rewards: rewards,
      );
      expect(result, PeriodicRewardAvailability.calendarUninitialized);
      expect(result.value, isNull);
      expect(result.matches(expectedValue: true), isFalse);
      expect(result.matches(expectedValue: false), isFalse);
    }
  });

  test('initialized calendar makes an unclaimed reward available', () {
    final result = read(
      GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: 0),
      rewards: const PeriodicRewardState.empty(),
    );
    expect(result, PeriodicRewardAvailability.available);
    expect(result.value, isTrue);
    expect(result.matches(expectedValue: true), isTrue);
    expect(result.matches(expectedValue: false), isFalse);
  });

  test('another reward claim does not affect the selected reward', () {
    expect(
      read(
        GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: 4),
        rewardId: 'another-reward',
      ),
      PeriodicRewardAvailability.available,
    );
  });

  for (final entry in [
    (name: 'same civil day and revision', day: '2026-10-30', revision: 4),
    (
      name: 'later day without revision advance',
      day: '2026-10-31',
      revision: 4,
    ),
    (name: 'same day after revision advance', day: '2026-10-30', revision: 5),
    (
      name: 'earlier day after revision advance',
      day: '2026-10-29',
      revision: 5,
    ),
  ]) {
    test('${entry.name} remains claimed', () {
      final result = read(
        GameplayCalendarState(
          observedLocalDay: entry.day,
          dayRevision: entry.revision,
        ),
      );
      expect(result, PeriodicRewardAvailability.alreadyClaimed);
      expect(result.value, isFalse);
      expect(result.matches(expectedValue: true), isFalse);
      expect(result.matches(expectedValue: false), isTrue);
    });
  }

  for (final day in ['2026-10-29', '2026-10-30', '2026-10-31']) {
    test('regressed revision is unknown on $day', () {
      final result = read(
        GameplayCalendarState(observedLocalDay: day, dayRevision: 3),
      );
      expect(result, PeriodicRewardAvailability.calendarInconsistent);
      expect(result.value, isNull);
      expect(result.matches(expectedValue: true), isFalse);
      expect(result.matches(expectedValue: false), isFalse);
    });
  }

  for (final days in [
    ('2026-10-30', '2026-10-31'),
    ('2026-12-31', '2027-01-01'),
    ('2028-02-28', '2028-02-29'),
    ('2028-02-29', '2028-03-01'),
  ]) {
    test(
      'strictly later civil day and revision restore availability $days',
      () {
        final result = read(
          GameplayCalendarState(observedLocalDay: days.$2, dayRevision: 5),
          rewards: PeriodicRewardState(
            claimsById: {
              'daily-fruit': PeriodicRewardClaim(
                revision: 3,
                lastClaimDayRevision: 4,
                lastClaimLocalDay: days.$1,
              ),
            },
          ),
        );
        expect(result, PeriodicRewardAvailability.available);
        expect(result.matches(expectedValue: true), isTrue);
      },
    );
  }

  test('reading preserves calendar and claims byte for byte', () {
    final calendar = GameplayCalendarState(
      observedLocalDay: '2026-10-31',
      dayRevision: 5,
    );
    final before = jsonEncode([calendar.toJson(), claimed.toJson()]);
    read(calendar);
    read(calendar, rewardId: 'another-reward');
    expect(jsonEncode([calendar.toJson(), claimed.toJson()]), before);
    expect(claimed.claimsById.length, 1);
  });
}
