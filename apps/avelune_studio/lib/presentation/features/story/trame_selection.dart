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
