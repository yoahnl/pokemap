import 'package:avelune_studio/features/stories/application/story_step_outcomes.dart';
import 'package:avelune_studio/features/stories/application/story_workspace_controller.dart';
import 'package:avelune_studio/presentation/features/stories/story_library_panel.dart';
import 'package:avelune_studio/presentation/features/stories/story_step_outcomes.dart';
import 'package:avelune_studio/presentation/features/stories/story_metadata_fields.dart';
import 'package:avelune_studio/presentation/shared/widgets/inputs/studio_choice.dart';
import 'package:avelune_studio/presentation/theme/studio_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

import '../support/story_backend_fixture.dart';

void main() {
  final stories = [
    StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Aventure',
      chapters: [
        StorylineChapter(
          id: 'departure',
          title: 'Départ du bourg',
          order: 0,
          steps: [
            StorylineStep(
              id: 'got_dex',
              title: 'Recevoir le Pokédex',
              order: 0,
            ),
          ],
        ),
      ],
    ),
    StorylineAsset(
      id: 'side',
      type: StorylineType.sideQuest,
      title: 'Le phare',
      chapters: [
        StorylineChapter(
          id: 'lighthouse',
          title: 'Rallumer le phare',
          order: 0,
          steps: [StorylineStep(id: 'oil', title: 'Trouver l’huile', order: 0)],
        ),
      ],
    ),
  ];

  Future<TextEditingController> pump(WidgetTester tester) async {
    final search = TextEditingController();
    addTearDown(search.dispose);
    tester.view.physicalSize = const Size(500, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => StoryLibraryPanel(
              stories: stories,
              activeId: null,
              search: search,
              type: null,
              dirtyIds: const {},
              onSearch: () => setState(() {}),
              onType: (_) {},
              onOpen: (_) {},
              onCreate: () {},
            ),
          ),
        ),
      ),
    );
    return search;
  }

  testWidgets('the story library finds a story through its steps', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'pokédex');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-library-main')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-library-side')), findsNothing);
    final choice = tester.widget<StudioChoice>(
      find.byKey(const ValueKey('story-library-main')),
    );
    expect(choice.subtitle, contains('Étape : Recevoir le Pokédex'));
    expect(choice.subtitle, contains('Départ du bourg'));
  });

  testWidgets('the story library finds a story through its chapters', (
    tester,
  ) async {
    await pump(tester);
    await tester.enterText(find.byType(TextField), 'rallumer');
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('story-library-side')), findsOneWidget);
    expect(find.byKey(const ValueKey('story-library-main')), findsNothing);
    expect(
      tester
          .widget<StudioChoice>(
            find.byKey(const ValueKey('story-library-side')),
          )
          .subtitle,
      contains('Chapitre : Rallumer le phare'),
    );
  });

  test('a step condition names a fact through its runtime flag', () {
    final project = ProjectManifest(
      name: 'Exemple',
      maps: const [],
      tilesets: const [],
      facts: [
        NarrativeFactDefinition(
          id: 'rival_seen',
          label: 'Rival rencontré',
          legacyFlagName: 'rival_flag',
        ),
      ],
    );
    expect(
      storyConditionText(
        ScriptCondition(
          type: ScriptConditionType.flagIsSet,
          params: const {ScriptConditionParams.flagName: 'rival_flag'},
        ),
        project,
      ),
      'Rival rencontré = Oui',
    );
    expect(
      storyConditionText(
        ScriptCondition(
          type: ScriptConditionType.flagIsUnset,
          params: const {ScriptConditionParams.flagName: 'ghost'},
        ),
        project,
      ),
      'État introuvable conservé : ghost = Non',
    );
  });

  test('a step names its expected outcomes and keeps an unknown one', () {
    final scene = SceneAsset(
      id: 'lab',
      name: 'Le laboratoire',
      graph: SceneGraph(
        startNodeId: 'start',
        nodes: [SceneNode(id: 'start', kind: SceneNodeKind.start)],
        edges: [],
      ),
      declaredOutcomes: [
        SceneOutcome(id: 'starter_given', label: 'Starter reçu'),
      ],
    );
    final step = StorylineStep(
      id: 'got_starter',
      title: 'Recevoir un starter',
      order: 0,
      sceneLinkIds: const ['lab'],
      expectedOutcomeIds: const ['starter_given', 'ghost'],
    );
    final story = StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Aventure',
      chapters: [
        StorylineChapter(id: 'c', title: 'C', order: 0, steps: [step]),
      ],
      sceneLinks: [
        StorylineSceneLink(
          id: 'link',
          chapterId: 'c',
          stepId: 'got_starter',
          label: 'Rencontre',
          state: StorylineSceneLinkState.linkedScenario,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'legacy',
          ),
          order: 0,
          outcomeLinks: [
            StorylineSceneOutcomeLink(
              id: 'o',
              outcomeId: 'ready',
              label: 'Prêt à partir',
              effects: [
                StorylineEffect(
                  type: StorylineEffectType.activateStep,
                  targetId: 'got_starter',
                ),
              ],
            ),
          ],
        ),
      ],
    );
    final project = ProjectManifest(
      name: 'P',
      maps: const [],
      tilesets: const [],
      scenes: [scene],
      scenarios: const [
        ScenarioAsset(
          id: 'legacy',
          name: 'Rencontre',
          entryNodeId: 'start',
          declaredOutcomes: ['ready', 'late'],
        ),
      ],
      storylines: [story],
    );
    final choices = storyStepOutcomeChoices(project, story, 'c', step);
    expect([for (final c in choices) c.id], [
      'starter_given',
      'ready',
      'late',
      'ghost',
    ]);
    expect(choices[0].label, 'Starter reçu');
    expect(choices[0].source, 'Scène « Le laboratoire »');
    expect(choices[0].expected, isTrue);
    expect(choices[1].label, 'Prêt à partir');
    expect(choices[1].source, 'Scénario « Rencontre »');
    expect(choices[1].expected, isFalse);
    expect(choices[3].missing, isTrue);
    expect(choices[3].expected, isTrue);
  });

  testWidgets('checking an expected outcome edits only that step', (
    tester,
  ) async {
    final step = StorylineStep(
      id: 'ready_step',
      title: 'Se préparer',
      order: 0,
      expectedOutcomeIds: const ['ghost'],
    );
    final story = StorylineAsset(
      id: 'main',
      type: StorylineType.main,
      title: 'Aventure',
      chapters: [
        StorylineChapter(id: 'c', title: 'C', order: 0, steps: [step]),
      ],
      sceneLinks: [
        StorylineSceneLink(
          id: 'link',
          chapterId: 'c',
          stepId: 'ready_step',
          label: 'Rencontre',
          state: StorylineSceneLinkState.linkedScenario,
          role: StorylineSceneLinkRole.primary,
          sceneRef: StorylineSceneRef(
            kind: StorylineSceneRefKind.scenario,
            targetId: 'legacy',
          ),
          order: 0,
        ),
      ],
    );
    late StoryBackendFixture fixture;
    await tester.runAsync(() async {
      fixture = await StoryBackendFixture.create(
        stories: [story],
        scenarios: const [
          ScenarioAsset(
            id: 'legacy',
            name: 'Rencontre',
            entryNodeId: 'start',
            declaredOutcomes: ['ready'],
          ),
        ],
      );
    });
    addTearDown(() => tester.runAsync(fixture.dispose));
    StateSetter? rebuild;
    final controller = StoryWorkspaceController(
      fixture.narrative,
      fixture.port,
      changed: () => rebuild?.call(() {}),
    )..open(story.id);
    addTearDown(controller.dispose);
    StorylineStep current() => controller.stories
        .singleWhere((s) => s.id == 'main')
        .chapters
        .single
        .steps
        .single;
    await tester.pumpWidget(
      MaterialApp(
        theme: studioTheme(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              rebuild = setState;
              return SingleChildScrollView(
                child: StoryStepOutcomes(
                  controller: controller,
                  story: controller.stories.singleWhere((s) => s.id == 'main'),
                  chapterId: 'c',
                  step: current(),
                ),
              );
            },
          ),
        ),
      ),
    );
    expect(find.text('ready'), findsOneWidget);
    expect(find.text('Scénario « Rencontre »'), findsOneWidget);
    expect(find.textContaining('Introuvable'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('story-step-outcome-ready')));
    await tester.pump();
    expect(current().expectedOutcomeIds, ['ghost', 'ready']);
    expect(current().title, 'Se préparer');
  });
}
