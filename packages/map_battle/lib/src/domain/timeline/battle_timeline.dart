import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_timeline_event.dart';

/// Ordered descriptive output produced by the clean battle engine.
///
/// Runtime animation should consume this kind of timeline instead of inferring
/// order from state diffs.
final class BattleTimeline {
  BattleTimeline({
    required List<BattleTimelineEvent> events,
  }) : _events = List<BattleTimelineEvent>.unmodifiable(events);

  factory BattleTimeline.empty() {
    return BattleTimeline(events: const <BattleTimelineEvent>[]);
  }

  factory BattleTimeline.fromPsdkEvents(Iterable<PsdkBattleEvent> events) {
    return BattleTimeline(
      events: events.map(BattleTimelineEvent.fromPsdk).toList(growable: false),
    );
  }

  final List<BattleTimelineEvent> _events;

  List<BattleTimelineEvent> get events =>
      List<BattleTimelineEvent>.unmodifiable(_events);

  List<Map<String, Object?>> toJson() {
    return events.map((event) => event.toJson()).toList(growable: false);
  }

  PsdkBattleTimeline get psdkTimeline {
    return PsdkBattleTimeline(
      events: events
          .map((event) => event.toPsdkEvent())
          .whereType<PsdkBattleEvent>()
          .toList(growable: false),
    );
  }
}
