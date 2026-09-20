import 'package:avelune_studio/presentation/features/stories/story_graph_canvas.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

class StoryCanvasTestHarness {
  StoryCanvasTestHarness({ProjectManifest? project})
    : project = project ?? storyCanvasProject();
  ProjectManifest project;
  final view = StoryViewState();
  final requests = <StorylineProgressionConnectRequest>[];
  final results = <StorylineProgressionMutationResult>[];
  StoryGraphSelection? selection;
  late StateSetter refresh;
  int disconnects = 0;
  Future<void> mount(WidgetTester tester, {bool textField = false}) async {
    tester.view.physicalSize = const Size(1200, 860);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(view.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              refresh = setState;
              return Column(
                children: [
                  if (textField)
                    const TextField(key: ValueKey('story-test-text')),
                  Expanded(
                    child: StoryGraphCanvas(
                      project: project,
                      storyId: 'main',
                      viewState: view,
                      selection: selection,
                      onSelect: (value) => refresh(() => selection = value),
                      onConnect: (request) {
                        requests.add(request);
                        final result = connectStorylineProgressionEdge(
                          project,
                          request,
                        );
                        results.add(result);
                        refresh(() => project = result.after);
                      },
                      onDisconnect: (edge) {
                        disconnects++;
                        final result = disconnectStorylineProgressionEdge(
                          project,
                          storylineId: 'main',
                          edgeId: edge.id,
                        );
                        results.add(result);
                        refresh(() => project = result.after);
                      },
                      onAddStep: (_) {},
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> connect(
    WidgetTester tester,
    String source,
    String target,
    String choice,
  ) async {
    final start = tester.getCenter(
      find.byKey(ValueKey('story-graph-output-$source')),
    );
    final end = tester.getCenter(
      find.byKey(ValueKey('story-graph-input-$target')),
    );
    final gesture = await tester.startGesture(start);
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text(choice));
    await tester.pumpAndSettle();
  }
}
