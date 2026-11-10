import 'package:map_core/map_core.dart';

ProjectManifest storyCanvasProject({
  int chapterCount = 2,
  int stepsPerChapter = 2,
  bool volume = false,
}) {
  final chapters = [
    for (var c = 0; c < chapterCount; c++)
      StorylineChapter(
        id: 'chapter$c',
        title: 'Chapitre ${c + 1}',
        order: c,
        steps: [
          for (var s = 0; s < stepsPerChapter; s++)
            StorylineStep(
              id: 'step${c}_$s',
              title: 'Étape ${s + 1}',
              order: s,
              entryCondition: volume && s.isOdd
                  ? ScriptConditionFactory.flagIsSet('fact')
                  : null,
            ),
        ],
      ),
  ];
  return ProjectManifest(
    name: 'Histoires',
    maps: [],
    tilesets: [],
    facts: [
      NarrativeFactDefinition(id: 'fact', label: 'Le passage est ouvert'),
    ],
    scenarios: [
      ScenarioAsset(
        id: 'scenario',
        name: 'Rencontre',
        entryNodeId: 'start',
        declaredOutcomes: ['accepted'],
      ),
    ],
    storylines: [
      StorylineAsset(
        id: 'main',
        title: 'Le voyage',
        type: StorylineType.main,
        chapters: chapters,
        sceneLinks: [
          StorylineSceneLink(
            id: 'link',
            chapterId: 'chapter0',
            stepId: 'step0_0',
            label: 'Rencontre',
            state: StorylineSceneLinkState.linkedScenario,
            role: StorylineSceneLinkRole.primary,
            order: 0,
            sceneRef: StorylineSceneRef(
              kind: StorylineSceneRefKind.scenario,
              targetId: 'scenario',
            ),
            outcomeLinks: [
              StorylineSceneOutcomeLink(
                id: 'result',
                outcomeId: 'accepted',
                label: 'Invitation acceptée',
                effects: [
                  StorylineEffect(
                    type: StorylineEffectType.emitFact,
                    targetId: 'fact',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      for (var i = 0; i < (volume ? 9 : 1); i++)
        StorylineAsset(
          id: 'side$i',
          title: 'Histoire secondaire ${i + 1}',
          type: StorylineType.sideQuest,
        ),
    ],
  );
}
