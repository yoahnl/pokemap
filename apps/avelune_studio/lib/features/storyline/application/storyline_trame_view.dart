import 'package:map_core/map_core_domain.dart';

import '../../events/domain/event_record_view.dart';

typedef StorylineMilestoneAt = ({
  StorylineOutlineStoryline storyline,
  StorylineOutlineChapter chapter,
  StorylineOutlineMilestone milestone,
});

final class StorylineTrameView {
  StorylineTrameView(this.outline, NarrativeEventRegistry? registry)
    : _records = registry?.records ?? const [] {
    for (final storyline in outline.storylines) {
      for (final chapter in storyline.chapters) {
        for (final milestone in chapter.milestones) {
          final at = (
            storyline: storyline,
            chapter: chapter,
            milestone: milestone,
          );
          milestones.add(at);
          _byId[milestone.id] = at;
          for (final sceneId in milestone.sceneIds) {
            _byScene[sceneId] = at;
          }
          if (milestone.completionFactId case final factId?) {
            _byFact.putIfAbsent(factId, () => at);
          }
        }
      }
    }
    for (final record in _records) {
      if (record.sceneId case final sceneId?) {
        _bySceneRecords.putIfAbsent(sceneId, () => []).add(record);
      }
    }
  }

  final StorylineOutline outline;
  final List<NarrativeEventRecord> _records;
  final milestones = <StorylineMilestoneAt>[];
  final _byId = <String, StorylineMilestoneAt>{};
  final _byScene = <String, StorylineMilestoneAt>{};
  final _byFact = <String, StorylineMilestoneAt>{};
  final _bySceneRecords = <String, List<NarrativeEventRecord>>{};

  StorylineMilestoneAt? milestone(String id) => _byId[id];

  StorylineMilestoneAt? milestoneOfScene(String? sceneId) =>
      sceneId == null ? null : _byScene[sceneId];

  StorylineMilestoneAt? milestoneOfFact(String factId) => _byFact[factId];

  List<NarrativeEventRecord> behavioursOfScene(String sceneId) =>
      _bySceneRecords[sceneId] ?? const [];

  List<NarrativeEventRecord> behavioursOf(
    StorylineOutlineMilestone milestone,
  ) => [
    for (final sceneId in milestone.sceneIds) ...behavioursOfScene(sceneId),
  ];

  bool outside(NarrativeEventRecord record) =>
      milestoneOfScene(record.sceneId) == null;

  List<NarrativeEventRecord> get outsideBehaviours => [
    for (final record in _records)
      if (outside(record)) record,
  ];
}
