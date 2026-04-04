import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/editor/state/editor_notifier.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/narrative_workspace_projection.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart'
    show
        StepStudioActivationMode,
        StepStudioActivationRule,
        StepStudioCompletionMode,
        StepStudioCompletionRule,
        StepStudioDocument,
        StepStudioStep,
        kStepStudioDocumentMetadataKey;
import 'package:map_editor/src/ui/canvas/global_story_studio_workspace.dart';

/// Reproduit la réorganisation des ids de steps (ordre global) après
/// [_insertExistingStepAfter] : retire [existingId] puis réinsère après [afterId].
List<String> _simulateOrderedStepIdsAfterInsertExisting(
  List<String> orderedIds,
  String afterId,
  String existingId,
) {
  final list = List<String>.from(orderedIds);
  final existingIndex = list.indexOf(existingId);
  final afterIndex = list.indexOf(afterId);
  if (existingIndex < 0 || afterIndex < 0) return orderedIds;
  list.removeAt(existingIndex);
  final newAfterIndex = list.indexOf(afterId);
  final insertionIndex =
      newAfterIndex < 0 ? list.length : newAfterIndex + 1;
  list.insert(insertionIndex, existingId);
  return list;
}

void main() {
  group('Global Story chapter step order (pure)', () {
    test('reorderChapterStepIdsAfterMovingWithinSameChapter moves after ref',
        () {
      const ids = <String>['a', 'b', 'c'];
      final out = reorderChapterStepIdsAfterMovingWithinSameChapter(
        ids,
        referenceStepId: 'a',
        stepIdToMove: 'c',
      );
      expect(out, <String>['a', 'c', 'b']);
    });

    test('reorderChapterStepIdsAfterMovingWithinSameChapter returns null if id missing',
        () {
      expect(
        reorderChapterStepIdsAfterMovingWithinSameChapter(
          <String>['a', 'b'],
          referenceStepId: 'x',
          stepIdToMove: 'a',
        ),
        isNull,
      );
    });

    test('cross-chapter: remove then insert after — no duplicate in target', () {
      const fromChapter = <String>['x', 'y'];
      const toChapter = <String>['a', 'b'];
      final without = chapterStepIdsRemovingOnce(fromChapter, 'y');
      expect(without, <String>['x']);
      final merged = chapterStepIdsInsertingAfterReference(toChapter, 'a', 'y');
      expect(merged, <String>['a', 'y', 'b']);
      expect(merged!.toSet().length, merged.length);
    });

    test('chapterStepIdsInsertingAfterReference rejects duplicate insert', () {
      expect(
        chapterStepIdsInsertingAfterReference(
          <String>['a', 'b'],
          'a',
          'b',
        ),
        isNull,
      );
    });
  });

  group('Global Story insert existing — order invariants', () {
    test('same-chapter: global step id order and chapter.stepIds stay aligned', () {
      const ordered = <String>['s0', 's1', 's2'];
      final globalIds = _simulateOrderedStepIdsAfterInsertExisting(
        ordered,
        's0',
        's2',
      );
      expect(globalIds, <String>['s0', 's2', 's1']);

      final chapterIds = <String>['s0', 's1', 's2'];
      final visual = reorderChapterStepIdsAfterMovingWithinSameChapter(
        chapterIds,
        referenceStepId: 's0',
        stepIdToMove: 's2',
      );
      expect(visual, globalIds);
    });

    test('cross-chapter: global order vs chapter membership', () {
      const ordered = <String>['s0', 's1', 's2'];
      final globalIds = _simulateOrderedStepIdsAfterInsertExisting(
        ordered,
        's0',
        's2',
      );
      expect(globalIds, <String>['s0', 's2', 's1']);

      final chA = <String>['s0', 's1'];
      final chB = <String>['s2'];
      final bWithout = chapterStepIdsRemovingOnce(chB, 's2');
      expect(bWithout, isEmpty);
      final aWith = chapterStepIdsInsertingAfterReference(chA, 's0', 's2');
      expect(aWith, <String>['s0', 's2', 's1']);
    });
  });

  group('Insert picker eligibility', () {
    test('eligibleStepIdsForGlobalStoryInsertPicker lists all except current', () {
      final steps = <StepStudioStep>[
        StepStudioStep(
          id: 'a',
          name: 'A',
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
          id: 'b',
          name: 'B',
          description: '',
          order: 1,
          activation: const StepStudioActivationRule(
            mode: StepStudioActivationMode.afterPreviousStep,
          ),
          completion: const StepStudioCompletionRule(
            mode: StepStudioCompletionMode.manual,
          ),
        ),
        StepStudioStep(
          id: 'c',
          name: 'C',
          description: '',
          order: 2,
          activation: const StepStudioActivationRule(
            mode: StepStudioActivationMode.afterPreviousStep,
          ),
          completion: const StepStudioCompletionRule(
            mode: StepStudioCompletionMode.manual,
          ),
        ),
      ];
      final eligible = eligibleStepIdsForGlobalStoryInsertPicker(steps, 'b');
      expect(eligible, <String>['a', 'c']);
    });
  });

  group('Global Story Studio widget — header & rename', () {
    testWidgets('tap chevron toggles expansion; add chapter does not only collapse',
        (tester) async {
      final stepDoc = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_intro',
            name: 'Introduction',
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
      final globalDoc = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_intro',
        nodes: const <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_intro',
            exitMode: GlobalStoryStepExitMode.linear,
            links: <GlobalStoryStepLink>[],
          ),
        ],
        chapters: <GlobalStoryChapter>[
          GlobalStoryChapter(
            id: 'c1',
            name: 'Acte I',
            description: '',
            stepIds: const <String>['step_intro'],
            order: 0,
          ),
        ],
      );
      final project = ProjectManifest(
        name: 't',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[
          ScenarioAsset(
            id: 'global_story',
            name: 'G',
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

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(editorNotifierProvider.notifier);
              return MaterialApp(
                home: Scaffold(
                  body: SizedBox(
                    width: 1200,
                    height: 800,
                    child: GlobalStoryStudioWorkspace(
                      editorNotifier: notifier,
                      project: project,
                      projection: projection,
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
      await tester.pump();

      expect(find.text('Introduction'), findsNothing);

      await tester.tap(find.byIcon(CupertinoIcons.chevron_right).first);
      await tester.pumpAndSettle();
      expect(find.text('Introduction'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.chevron_right).first);
      await tester.pumpAndSettle();
      expect(find.text('Introduction'), findsNothing);

      await tester.tap(find.byIcon(CupertinoIcons.chevron_right).first);
      await tester.pumpAndSettle();
      expect(find.text('Introduction'), findsOneWidget);

      await tester.tap(find.byIcon(CupertinoIcons.add_circled).first);
      await tester.pumpAndSettle();
      expect(find.text('Introduction'), findsOneWidget);
      expect(find.textContaining('CH.'), findsWidgets);
    });

    testWidgets('double-tap chapter title opens field; enter commits rename',
        (tester) async {
      final stepDoc = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_intro',
            name: 'Introduction',
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
      final globalDoc = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_intro',
        nodes: const <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_intro',
            exitMode: GlobalStoryStepExitMode.linear,
            links: <GlobalStoryStepLink>[],
          ),
        ],
        chapters: <GlobalStoryChapter>[
          GlobalStoryChapter(
            id: 'c1',
            name: 'Acte I',
            description: '',
            stepIds: const <String>['step_intro'],
            order: 0,
          ),
        ],
      );
      final project = ProjectManifest(
        name: 't',
        maps: const <ProjectMapEntry>[],
        tilesets: const <ProjectTilesetEntry>[],
        scenarios: <ScenarioAsset>[
          ScenarioAsset(
            id: 'global_story',
            name: 'G',
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

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final notifier = ref.read(editorNotifierProvider.notifier);
              return MaterialApp(
                home: Scaffold(
                  body: SizedBox(
                    width: 1200,
                    height: 800,
                    child: GlobalStoryStudioWorkspace(
                      editorNotifier: notifier,
                      project: project,
                      projection: projection,
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
      await tester.pump();
      await tester.tap(find.byIcon(CupertinoIcons.chevron_right).first);
      await tester.pumpAndSettle();

      await tester.tap(find.text('Acte I'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.text('Acte I'));
      await tester.pumpAndSettle();

      final field = find.byType(CupertinoTextField);
      expect(field, findsOneWidget);
      await tester.enterText(field, 'Acte I bis');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Acte I bis'), findsWidgets);
    });
  });

  group('Insert picker widget', () {
    testWidgets('Insérer opens sheet listing other project steps', (tester) async {
      final data = _buildThreeStepProject();
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
      await tester.pump();
      final chevrons = find.byIcon(CupertinoIcons.chevron_right);
      for (var i = 0; i < chevrons.evaluate().length; i++) {
        await tester.tap(chevrons.at(i));
        await tester.pump();
      }
      await tester.pumpAndSettle();

      await tester.tap(find.text('Insérer').first);
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Insérer une step existante après celle-ci'),
        findsOneWidget,
      );
      // Première option du picker = première step du projet hors step courante (ordre global).
      expect(find.textContaining('#2. Rencontre du professeur'), findsOneWidget);
      // Step courante toujours visible dans la carte au-dessus du picker.
      expect(find.text('Introduction'), findsWidgets);
    });
  });
}

({
  ProjectManifest project,
  NarrativeWorkspaceProjection projection,
}) _buildThreeStepProject() {
  final stepDoc = StepStudioDocument(
    globalStoryScenarioId: 'global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'step_intro',
        name: 'Introduction',
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
        id: 'step_professor',
        name: 'Rencontre du professeur',
        description: '',
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
        description: '',
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
      const GlobalStoryStepNode(
        stepId: 'step_intro',
        exitMode: GlobalStoryStepExitMode.linear,
        links: <GlobalStoryStepLink>[
          GlobalStoryStepLink(toStepId: 'step_professor'),
        ],
      ),
      const GlobalStoryStepNode(
        stepId: 'step_professor',
        exitMode: GlobalStoryStepExitMode.linear,
        links: <GlobalStoryStepLink>[
          GlobalStoryStepLink(toStepId: 'step_starter'),
        ],
      ),
      const GlobalStoryStepNode(
        stepId: 'step_starter',
        exitMode: GlobalStoryStepExitMode.linear,
        links: <GlobalStoryStepLink>[],
      ),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'chapter_prologue',
        name: 'Prologue',
        description: '',
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
          kGlobalStoryStudioDocumentMetadataKey: globalDoc.toMetadataJson(),
        },
      ),
    ],
  );
  return (
    project: project,
    projection: buildNarrativeWorkspaceProjection(project),
  );
}
