import 'package:map_core/map_core_domain.dart';

import '../../domain/event_record_view.dart';
import 'behaviour_record_edit.dart';

enum BehaviourAfter { eachTime, once, oncePerVisit, onceUntilOutcome }

enum BehaviourAfterRefusal {
  wouldDropOutcomeRearm,
  outcomeRequired,
  parallelNeedsEachTime,
  visitNeedsPlace,
}

final class BehaviourAfterStep {
  const BehaviourAfterStep.reuse(NarrativeEventReusePolicy this.reusePolicy)
    : resetPolicy = null;

  const BehaviourAfterStep.reset(NarrativeEventResetPolicy this.resetPolicy)
    : reusePolicy = null;

  final NarrativeEventReusePolicy? reusePolicy;
  final NarrativeEventResetPolicy? resetPolicy;
}

sealed class BehaviourAfterChange {
  const BehaviourAfterChange();
}

final class BehaviourAfterUnchanged extends BehaviourAfterChange {
  const BehaviourAfterUnchanged();
}

final class BehaviourAfterRefused extends BehaviourAfterChange {
  const BehaviourAfterRefused(this.reason, {this.outcome});

  final BehaviourAfterRefusal reason;
  final NarrativeOutcomeRef? outcome;
}

final class BehaviourAfterApplied extends BehaviourAfterChange {
  BehaviourAfterApplied(this.record, List<BehaviourAfterStep> steps)
    : steps = List.unmodifiable(steps);

  final NarrativeEventRecord record;
  final List<BehaviourAfterStep> steps;
}

BehaviourAfter? readBehaviourAfter(NarrativeEventRecord record) =>
    switch ((record.reusePolicy, record.resetPolicy)) {
      (null, _) => null,
      (NarrativeEventReusePolicy.reusable, _) => BehaviourAfter.eachTime,
      (_, NarrativeEventResetNever()) => BehaviourAfter.once,
      (_, NarrativeEventResetOnMapReentry()) => BehaviourAfter.oncePerVisit,
      (_, NarrativeEventResetOnOutcomeReceived()) =>
        BehaviourAfter.onceUntilOutcome,
    };

NarrativeOutcomeRef? behaviourRearmOutcome(NarrativeEventRecord record) =>
    switch (record.resetPolicy) {
      NarrativeEventResetOnOutcomeReceived(:final outcome) => outcome,
      _ => null,
    };

BehaviourAfterChange changeBehaviourAfter(
  NarrativeEventRecord record,
  BehaviourAfter after, {
  bool dropOutcomeRearm = false,
  NarrativeOutcomeRef? outcome,
}) {
  final current = readBehaviourAfter(record);
  final kept = behaviourRearmOutcome(record);
  if (after == BehaviourAfter.onceUntilOutcome) {
    if (outcome == null) {
      return kept == null
          ? const BehaviourAfterRefused(BehaviourAfterRefusal.outcomeRequired)
          : const BehaviourAfterUnchanged();
    }
    if (outcome == kept) return const BehaviourAfterUnchanged();
  } else if (after == current) {
    return const BehaviourAfterUnchanged();
  }
  if (after != BehaviourAfter.onceUntilOutcome &&
      kept != null &&
      !dropOutcomeRearm) {
    return BehaviourAfterRefused(
      BehaviourAfterRefusal.wouldDropOutcomeRearm,
      outcome: kept,
    );
  }
  if (after != BehaviourAfter.eachTime && record.parallelPolicy != null) {
    return const BehaviourAfterRefused(
      BehaviourAfterRefusal.parallelNeedsEachTime,
    );
  }
  if (after == BehaviourAfter.oncePerVisit &&
      record.source?.kind == NarrativeEventSourceKind.outcomeReceived) {
    return const BehaviourAfterRefused(BehaviourAfterRefusal.visitNeedsPlace);
  }
  final reuse = after == BehaviourAfter.eachTime
      ? NarrativeEventReusePolicy.reusable
      : NarrativeEventReusePolicy.oneShot;
  final reset = switch (after) {
    BehaviourAfter.eachTime ||
    BehaviourAfter.once => const NarrativeEventResetPolicy.never(),
    BehaviourAfter.oncePerVisit =>
      const NarrativeEventResetPolicy.onMapReentry(),
    BehaviourAfter.onceUntilOutcome =>
      NarrativeEventResetPolicy.onOutcomeReceived(outcome!),
  };
  final reuseStep = [
    if (reuse != record.reusePolicy) BehaviourAfterStep.reuse(reuse),
  ];
  final resetStep = [
    if (reset != record.resetPolicy) BehaviourAfterStep.reset(reset),
  ];
  return BehaviourAfterApplied(
    editBehaviourRecord(record, policy: (reuse: reuse, reset: reset)),
    reuse == NarrativeEventReusePolicy.reusable
        ? [...resetStep, ...reuseStep]
        : [...reuseStep, ...resetStep],
  );
}
