import '../../psdk/domain/psdk_battle_timeline.dart';
import 'battle_timeline.dart';
import 'battle_timeline_event.dart';

final class BattleTimelineBuilder {
  final List<BattleTimelineEvent> _events = <BattleTimelineEvent>[];

  void add(BattleTimelineEvent event) {
    _events.add(event);
  }

  void addAll(Iterable<BattleTimelineEvent> events) {
    _events.addAll(events);
  }

  void addPsdk(PsdkBattleEvent event) {
    add(BattleTimelineEvent.fromPsdk(event));
  }

  void addPsdkAll(Iterable<PsdkBattleEvent> events) {
    for (final event in events) {
      addPsdk(event);
    }
  }

  BattleTimeline build() {
    return BattleTimeline(events: _events);
  }
}
