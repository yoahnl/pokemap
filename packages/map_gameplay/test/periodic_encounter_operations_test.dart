import 'dart:convert';

import 'package:map_core/map_core.dart';
import 'package:map_gameplay/map_gameplay.dart';
import 'package:test/test.dart';

void main() {
  const base = GameState(saveId: 'periodic-battle');
  final definition = PeriodicEncounterDefinition(
    rewardId: 'weekly-creature', label: 'Créature',
    consumeOnOutcomes: PeriodicEncounterOutcome.values.toSet(),
  );

  for (final outcome in [...PeriodicEncounterOutcome.values, null]) {
    test('full result preserved and claim policy applies for $outcome', () {
      final occurrence = beginPeriodicEncounter(base, definition: definition, localDay: '2026-11-06');
      final battle = base.copyWith(storyFlags: const StoryFlags(activeFlags: {'full-result'}));
      final result = completePeriodicEncounter(battle, occurrence: occurrence, outcome: outcome);
      expect(result.storyFlags, battle.storyFlags);
      expect(result.party, battle.party);
      expect(result.pokemonStorage, battle.pokemonStorage);
      expect(result.bag, battle.bag);
      expect(result.gameplayCalendarState.observedLocalDay, '2026-11-06');
      expect(result.periodicRewardState.claimFor(definition.rewardId) != null, outcome != null);
      final restored = gameStateFromStrictSaveJson(jsonDecode(jsonEncode(strictGameStateSaveJson(result))) as Map<String, dynamic>);
      expect(restored, result);
      if (outcome != null) {
        for (final day in ['2026-11-06', '2026-11-05']) {
          expect(() => beginPeriodicEncounter(restored, definition: definition, localDay: day), throwsStateError);
        }
        final nextWeek = beginPeriodicEncounter(restored, definition: definition, localDay: '2026-11-13');
        expect(completePeriodicEncounter(restored, occurrence: nextWeek, outcome: outcome).periodicRewardState.claimFor(definition.rewardId)!.revision, 2);
      }
    });
  }

  test('flee consumption is configurable and never invents an item', () {
    final policy = PeriodicEncounterDefinition(rewardId: 'rare', label: 'Rare', consumeOnOutcomes: {PeriodicEncounterOutcome.captured});
    final occurrence = beginPeriodicEncounter(base, definition: policy, localDay: '2026-11-06');
    final result = completePeriodicEncounter(base, occurrence: occurrence, outcome: PeriodicEncounterOutcome.fled);
    expect(result.periodicRewardState, base.periodicRewardState);
    expect(result.bag, base.bag);
    expect(beginPeriodicEncounter(result, definition: policy, localDay: '2026-11-06').calendar, occurrence.calendar);
  });

  test('launch occurrence is frozen across midnight and conflict fails closed', () {
    final occurrence = beginPeriodicEncounter(base, definition: definition, localDay: '2026-11-06');
    expect(completePeriodicEncounter(base, occurrence: occurrence, outcome: PeriodicEncounterOutcome.captured).periodicRewardState.claimFor(definition.rewardId)!.lastClaimLocalDay, '2026-11-06');
    final changed = observeGameplayCalendar(base, localDay: '2026-11-07');
    expect(() => completePeriodicEncounter(changed, occurrence: occurrence, outcome: PeriodicEncounterOutcome.captured), throwsStateError);
    final foreign = base.copyWith(periodicRewardState: PeriodicRewardState(claimsById: {
      'other': PeriodicRewardClaim(revision: 1, lastClaimDayRevision: 0, lastClaimLocalDay: '2026-11-06'),
    }), gameplayCalendarState: GameplayCalendarState(observedLocalDay: '2026-11-06', dayRevision: 0));
    expect(() => completePeriodicEncounter(foreign, occurrence: occurrence, outcome: PeriodicEncounterOutcome.captured), throwsStateError);
  });

  test('unrepresentable claim and inconsistent calendar refuse before battle', () {
    final calendar = GameplayCalendarState(observedLocalDay: '2026-10-30', dayRevision: 0);
    final exhausted = base.copyWith(gameplayCalendarState: calendar, periodicRewardState: PeriodicRewardState(claimsById: {
      definition.rewardId: PeriodicRewardClaim(revision: GameplayCalendarState.maximumRevision, lastClaimDayRevision: 0, lastClaimLocalDay: '2026-10-30'),
    }));
    expect(() => beginPeriodicEncounter(exhausted, definition: definition, localDay: '2026-11-06'), throwsStateError);
    final corrupt = base.copyWith(gameplayCalendarState: calendar, periodicRewardState: PeriodicRewardState(claimsById: {
      'foreign': PeriodicRewardClaim(revision: 1, lastClaimDayRevision: 20, lastClaimLocalDay: '2026-11-13'),
    }));
    expect(() => beginPeriodicEncounter(corrupt, definition: definition, localDay: '2026-11-06'), throwsStateError);
  });
}
