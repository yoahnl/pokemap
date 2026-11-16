import 'package:map_core/map_core_domain.dart';

enum TrameItem { storyline, chapter, milestone, outside }

typedef TrameSelection = ({
  TrameItem item,
  String? storylineId,
  String? chapterId,
  String? milestoneId,
});

const TrameSelection trameOutside = (
  item: TrameItem.outside,
  storylineId: null,
  chapterId: null,
  milestoneId: null,
);

TrameSelection? visibleTrameSelection(
  StorylineOutline outline,
  TrameSelection? selection,
) {
  if (selection == null) return null;
  final story = outline.storylines
      .where((story) => story.id == selection.storylineId)
      .firstOrNull;
  if (story == null) return selection;
  if (story.status == StorylineStatus.archived) return null;
  final chapter = story.chapters
      .where((chapter) => chapter.id == selection.chapterId)
      .firstOrNull;
  if (chapter?.status == StorylineStatus.archived) {
    return (
      item: TrameItem.storyline,
      storylineId: story.id,
      chapterId: null,
      milestoneId: null,
    );
  }
  final milestone = chapter?.milestones
      .where((milestone) => milestone.id == selection.milestoneId)
      .firstOrNull;
  if (chapter != null && milestone?.status == StorylineStatus.archived) {
    return (
      item: TrameItem.chapter,
      storylineId: story.id,
      chapterId: chapter.id,
      milestoneId: null,
    );
  }
  return selection;
}
