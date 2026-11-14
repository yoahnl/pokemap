import 'package:avelune_studio/features/storyline/domain/storyline_read_port.dart';
import 'package:map_core/map_core_domain.dart';

StorylineStep milestoneStep(
  String id,
  String title,
  int order, {
  String? factId,
  List<String> scenes = const [],
}) => StorylineStep(
  id: id,
  title: title,
  order: order,
  sceneLinkIds: scenes,
  completionCondition: factId == null
      ? null
      : ScriptConditionFactory.factEquals(
          factId,
          const NarrativeValue.boolean(true),
        ),
);

StorylineAsset mainStoryline({List<String> firstScenes = const ['talk']}) =>
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      status: StorylineStatus.active,
      title: 'Histoire',
      chapters: [
        StorylineChapter(
          id: 'chapter_one',
          title: 'Départ',
          order: 0,
          steps: [
            milestoneStep(
              'meet',
              'Rencontrer Léo',
              0,
              factId: 'met',
              scenes: firstScenes,
            ),
            milestoneStep('leave', 'Partir', 1),
          ],
        ),
        StorylineChapter(id: 'chapter_two', title: 'Voyage', order: 1),
      ],
    );

final class FakeStorylineRead implements StorylineReadPort {
  FakeStorylineRead({
    this.stories = const [],
    this.scenes = const [],
    this.facts = const [],
    this.proposed,
  });

  List<StorylineAsset> stories;
  List<SceneAsset> scenes;
  List<NarrativeFactDefinition> facts;
  StorylineAsset? proposed;
  NarrativeEventRegistry? registry;
  var outlines = 0;
  var storylineReads = 0;
  var proposals = 0;

  @override
  Future<StorylineOutline> outline() async {
    outlines++;
    return projectStorylineOutline(
      ProjectManifest(
        name: 'fake',
        maps: const [],
        tilesets: const [],
        storylines: stories,
        scenes: scenes,
        facts: facts,
        eventRegistry: registry,
      ),
    );
  }

  @override
  Future<StorylineProposalRead> proposal() async {
    proposals++;
    return (
      storyline: stories.isEmpty ? proposed : null,
      reason: stories.isEmpty ? null : 'storylinesExist',
    );
  }

  @override
  Future<List<StorylineAsset>> storylines() async {
    storylineReads++;
    return stories;
  }
}
