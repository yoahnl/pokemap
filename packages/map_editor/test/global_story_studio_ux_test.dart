import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';
import 'package:map_editor/src/ui/canvas/global_story_studio_workspace.dart';

void main() {
  group('Global Story Studio UX', () {
    // Helper to create a minimal project with a Global Story scenario
    // and a Step Studio document containing multiple steps.
    ({
      ProjectManifest project,
      NarrativeWorkspaceProjection projection,
      StepStudioDocument stepDoc,
      GlobalStoryStudioDocument globalDoc,
    }) _createProjectWithChapters() {
      final stepDoc = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_intro',
            name: 'Introduction',
            description: 'Le joueur commence son aventure',
            order: 0,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_professor',
            name: 'Rencontre du professeur',
            description: 'Le professeur Oak explique les bases',
            order: 1,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_starter',
            name: 'Choix du starter',
            description: 'Feu, Eau ou Plante?',
            order: 2,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      final globalDoc = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_intro',
        nodes: <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_intro',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_professor'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'step_professor',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_starter'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'step_starter',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[],
          ),
        ],
        chapters: <GlobalStoryChapter>[
          GlobalStoryChapter(
            id: 'chapter_prologue',
            name: 'Prologue',
            description: 'Le debut de l aventure',
            stepIds: const <String>['step_intro', 'step_professor'],
            order: 0,
          ),
          GlobalStoryChapter(
            id: 'chapter_depart',
            name: 'Depart',
            description: '',
            stepIds: const <String>['step_starter'],
            order: 1,
          ),
        ],
      );

      final project = ProjectManifest(
        name: 'test',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[
          ScenarioAsset(
            id: 'global_story',
            name: 'Global Story',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
            metadata: <String, String>{
              kStepStudioDocumentMetadataKey: stepDoc.toMetadataJson(),
              kGlobalStoryStudioDocumentMetadataKey:
                  globalDoc.toMetadataJson(),
            },
          ),
        ],
      );

      final projection = buildNarrativeWorkspaceProjection(project);

      return (
        project: project,
        projection: projection,
        stepDoc: stepDoc,
        globalDoc: globalDoc,
      );
    }

    testWidgets(
      'renders chapter-based narrative tree (not form-like step editor)',
      (tester) async {
        final data = _createProjectWithChapters();

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1280,
                      height: 900,
                      child: GlobalStoryStudioWorkspace(
                        editorNotifier: notifier,
                        project: data.project,
                        projection: data.projection,
                        selectedGlobalStoryId: 'global_story',
                        selectedStepId: null,
                        onSelectGlobalStory: (_) {},
                        onSelectStep: (_) {},
                        onOpenStepStudio: (_) {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Flush post-frame callbacks.
        await tester.pump();

        // Verify no overflow or exceptions.
        expect(tester.takeException(), isNull);

        // Chapitres (titres éditables) + liste projet + steps dans chapitres.
        expect(find.textContaining('Prologue'), findsWidgets);
        expect(find.textContaining('Depart'), findsWidgets);

        expect(find.textContaining('Introduction'), findsWidgets);
        expect(find.textContaining('Rencontre du professeur'), findsWidgets);
        expect(find.textContaining('Choix du starter'), findsWidgets);

        // Check that the macro summary is displayed.
        expect(find.textContaining('chapitre'), findsWidgets);
        expect(find.textContaining('step'), findsWidgets);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'opens Step Studio when "Ouvrir Step" button is pressed',
      (tester) async {
        final data = _createProjectWithChapters();
        var stepStudioOpened = false;
        String? openedStepId;

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1280,
                      height: 900,
                      child: GlobalStoryStudioWorkspace(
                        editorNotifier: notifier,
                        project: data.project,
                        projection: data.projection,
                        selectedGlobalStoryId: 'global_story',
                        selectedStepId: null,
                        onSelectGlobalStory: (_) {},
                        onSelectStep: (_) {},
                        onOpenStepStudio: (stepId) {
                          stepStudioOpened = true;
                          openedStepId = stepId;
                        },
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pump();

        // Find and tap "Ouvrir Step" button (liste projet ou chapitre).
        final ouvrirStepButtons = find.text('Ouvrir Step');
        expect(ouvrirStepButtons, findsWidgets);
        await tester.tap(ouvrirStepButtons.first);
        await tester.pump();

        expect(stepStudioOpened, isTrue);
        expect(openedStepId, isNotNull);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'unique global story rule is respected',
      (tester) async {
        // Project with NO Global Story.
        const project = ProjectManifest(
          name: 'test',
          maps: <ProjectMapEntry>[],
          tilesets: <ProjectTilesetEntry>[],
          scenarios: <ScenarioAsset>[],
        );
        final projection = buildNarrativeWorkspaceProjection(project);

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1280,
                      height: 900,
                      child: GlobalStoryStudioWorkspace(
                        editorNotifier: notifier,
                        project: project,
                        projection: projection,
                        selectedGlobalStoryId: null,
                        selectedStepId: null,
                        onSelectGlobalStory: (_) {},
                        onSelectStep: (_) {},
                        onOpenStepStudio: (_) {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);

        // Should show "no global story" state with create button.
        expect(find.textContaining('Aucun'), findsWidgets);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    testWidgets(
      'structure with multiple steps in chapters displays correctly',
      (tester) async {
        final data = _createProjectWithChapters();

        await tester.pumpWidget(
          ProviderScope(
            child: Consumer(
              builder: (context, ref, _) {
                final notifier = ref.read(editorNotifierProvider.notifier);
                return MaterialApp(
                  home: Scaffold(
                    body: SizedBox(
                      width: 1280,
                      height: 900,
                      child: GlobalStoryStudioWorkspace(
                        editorNotifier: notifier,
                        project: data.project,
                        projection: data.projection,
                        selectedGlobalStoryId: 'global_story',
                        selectedStepId: 'step_intro',
                        onSelectGlobalStory: (_) {},
                        onSelectStep: (_) {},
                        onOpenStepStudio: (_) {},
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pump();
        expect(tester.takeException(), isNull);

        expect(find.textContaining('Prologue'), findsWidgets);
        expect(find.textContaining('Depart'), findsWidgets);

        expect(find.textContaining('Introduction'), findsWidgets);
        expect(find.textContaining('Choix du starter'), findsWidgets);

        // Entry step indicator should be visible.
        expect(find.byIcon(CupertinoIcons.location_solid), findsWidgets);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test('GlobalStoryChapter serializes and deserializes correctly', () {
      const chapter = GlobalStoryChapter(
        id: 'chapter_test',
        name: 'Test Chapter',
        description: 'A test chapter',
        stepIds: <String>['step_a', 'step_b'],
        order: 2,
      );

      final json = chapter.toJson();
      final restored = GlobalStoryChapter.fromJson(json);

      expect(restored, equals(chapter));
      expect(restored.id, 'chapter_test');
      expect(restored.name, 'Test Chapter');
      expect(restored.stepIds, ['step_a', 'step_b']);
      expect(restored.order, 2);
    });

    test('GlobalStoryStudioDocument includes chapters in serialization', () {
      const doc = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_a',
        nodes: <GlobalStoryStepNode>[],
        chapters: <GlobalStoryChapter>[
          GlobalStoryChapter(
            id: 'ch1',
            name: 'Chapter One',
            description: '',
            stepIds: <String>['step_a'],
            order: 0,
          ),
        ],
      );

      final json = doc.toJson();
      expect(json['chapters'], isA<List>());
      expect(json['chapters'], hasLength(1));
      expect(json['chapters'][0]['name'], 'Chapter One');

      final restored = GlobalStoryStudioDocument.fromJson(json);
      expect(restored.chapters, hasLength(1));
      expect(restored.chapters.first.name, 'Chapter One');
    });

    test('normalizeGlobalStoryStudioDocument creates default chapter when none exist', () {
      final stepDoc = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_a',
            name: 'Step A',
            description: '',
            order: 0,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_b',
            name: 'Step B',
            description: '',
            order: 1,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      // Document without chapters.
      final doc = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_a',
        nodes: <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_a',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_b'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'step_b',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[],
          ),
        ],
        chapters: const <GlobalStoryChapter>[],
      );

      final normalized = normalizeGlobalStoryStudioDocument(
        document: doc,
        stepDocument: stepDoc,
      );

      // Should have created a default chapter.
      expect(normalized.chapters, isNotEmpty);
      expect(normalized.chapters.first.id, 'chapter_main');
      expect(normalized.chapters.first.stepIds, ['step_a', 'step_b']);
    });

    test('createDefaultGlobalStoryStudioDocument creates default chapter', () {
      final stepDoc = StepStudioDocument(
        globalStoryScenarioId: 'gs',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 's1',
            name: 'S1',
            description: '',
            order: 0,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      final doc = createDefaultGlobalStoryStudioDocument(
        globalStoryScenarioId: 'gs',
        stepDocument: stepDoc,
      );

      expect(doc.chapters, hasLength(1));
      expect(doc.chapters.first.id, 'chapter_main');
      expect(doc.chapters.first.stepIds, ['s1']);
    });

    test('normalizeGlobalStoryStudioDocument assigns unassigned steps to default chapter', () {
      final stepDoc = StepStudioDocument(
        globalStoryScenarioId: 'gs',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 's1',
            name: 'S1',
            description: '',
            order: 0,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 's2',
            name: 'S2',
            description: '',
            order: 1,
            activation: const StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      // Document with a chapter that only has s1 — s2 is unassigned.
      final doc = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'gs',
        entryStepId: 's1',
        nodes: <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 's1',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 's2'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 's2',
            exitMode: GlobalStoryStepExitMode.linear,
            links: const <GlobalStoryStepLink>[],
          ),
        ],
        chapters: <GlobalStoryChapter>[
          GlobalStoryChapter(
            id: 'ch1',
            name: 'Ch1',
            description: '',
            stepIds: const <String>['s1'],
            order: 0,
          ),
        ],
      );

      final normalized = normalizeGlobalStoryStudioDocument(
        document: doc,
        stepDocument: stepDoc,
      );

      // s2 should have been assigned to the default chapter.
      final allStepIds = normalized.chapters
          .expand((c) => c.stepIds)
          .toSet();
      expect(allStepIds, contains('s1'));
      expect(allStepIds, contains('s2'));
    });
  });
}
