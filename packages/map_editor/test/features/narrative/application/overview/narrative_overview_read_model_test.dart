import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/dialogue/application/dialogue_editor_validation.dart';
import 'package:map_editor/src/features/narrative/application/cutscene_studio/cutscene_studio_models.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/overview/narrative_overview_read_model.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';

void main() {
  group('buildNarrativeOverviewReadModel', () {
    test('represents a minimal project without inventing unavailable data', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(name: 'test_project'),
      );

      expect(model.projectName, 'test_project');
      expect(model.mainStory.availability, NarrativeOverviewAvailability.empty);
      expect(
          model.mainStory.sourceStatus, NarrativeOverviewSourceStatus.missing);
      expect(model.mainStory.canEdit, isFalse);

      expect(model.metrics.dialogues.count, 0);
      expect(model.metrics.dialogues.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.dialogueLines.count, isNull);
      expect(
        model.metrics.dialogueLines.availability,
        NarrativeOverviewAvailability.unavailable,
      );
      expect(model.metrics.quests.count, isNull);
      expect(model.metrics.quests.availability,
          NarrativeOverviewAvailability.outOfScope);
      expect(model.metrics.facts.count, 0);
      expect(model.metrics.facts.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.openIssues.count, isNull);
      expect(
        model.metrics.openIssues.availability,
        NarrativeOverviewAvailability.notEvaluated,
      );

      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.notEvaluated);
      expect(model.editorialStatus.notEvaluated, isTrue);
      expect(model.projectHealth.healthKind,
          NarrativeProjectHealthKind.notEvaluated);
      expect(model.recentActivity.availability,
          NarrativeOverviewAvailability.outOfScope);
      expect(model.notifications.availability,
          NarrativeOverviewAvailability.outOfScope);
    });

    test('projects one explicit global story with authoring metrics', () {
      final project = _project(
        name: 'test_project',
        scenarios: <ScenarioAsset>[
          _globalStoryWithDocuments(),
          _cutsceneScenario(
            id: 'test_cutscene_1',
            dialogueId: 'test_dialogue_1',
          ),
        ],
        dialogues: const <ProjectDialogueEntry>[
          ProjectDialogueEntry(
            id: 'test_dialogue_1',
            name: 'Test Dialogue',
            relativePath: 'dialogues/test_dialogue_1.yarn',
          ),
        ],
        cinematics: [
          CinematicAsset(
            id: 'test_cinematic_1',
            title: 'Test Cinematic',
            timeline: CinematicTimeline(),
          ),
        ],
      );

      final model = buildNarrativeOverviewReadModel(project: project);

      expect(model.metrics.chapters.count, 2);
      expect(model.metrics.chapters.availability,
          NarrativeOverviewAvailability.available);
      expect(
        model.metrics.chapters.sourceStatus,
        NarrativeOverviewSourceStatus.explicit,
      );
      expect(model.metrics.scenes.count, 1);
      expect(model.metrics.cutscenes.count, 1);
      expect(model.metrics.dialogues.count, 1);
      expect(model.metrics.conditions.count, 3);
      expect(model.metrics.worldRules.count, 0);

      expect(model.mainStory.availability,
          NarrativeOverviewAvailability.available);
      expect(model.mainStory.title, 'Test Global Story');
      expect(model.mainStory.description, 'A generic test story.');
      expect(model.mainStory.canEdit, isTrue);
      expect(model.mainStory.chapters, hasLength(2));
      expect(model.mainStory.chapters.first.id, 'test_chapter_1');
      expect(model.mainStory.chapters.first.label, 'Chapter One');
      expect(model.mainStory.linkedScenes.count, 1);
      expect(model.mainStory.linkedDialogues.count, 1);
      expect(model.mainStory.openIssues.availability,
          NarrativeOverviewAvailability.notEvaluated);

      final cutsceneModule = model.modules.singleWhere(
          (module) => module.id == NarrativeOverviewModuleIds.cutscenes);
      expect(cutsceneModule.count, 1);
      expect(cutsceneModule.destination, 'cinematics_library');
      expect(cutsceneModule.secondaryStats.single.count, 1);
      expect(
          cutsceneModule.availability, NarrativeOverviewAvailability.available);

      final factsModule = model.modules.singleWhere(
          (module) => module.id == NarrativeOverviewModuleIds.facts);
      expect(factsModule.count, 0);
      expect(factsModule.availability, NarrativeOverviewAvailability.empty);
    });

    test('marks chapters as fallback when Global Story metadata is absent', () {
      final project = _project(
        scenarios: const <ScenarioAsset>[
          ScenarioAsset(
            id: 'test_global_story',
            name: 'Fallback Global Story',
            description: 'Fallback metadata test.',
            scope: ScenarioScope.globalStory,
            entryNodeId: 'start',
            metadata: <String, String>{
              'step.id': 'test_step_1',
              'step.name': 'Fallback Step',
              'step.cutsceneIds': 'test_cutscene_1',
            },
          ),
          ScenarioAsset(
            id: 'test_cutscene_1',
            name: 'Test Cutscene',
            scope: ScenarioScope.localEventFlow,
            entryNodeId: 'start',
            metadata: <String, String>{
              kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
            },
          ),
        ],
      );

      final model = buildNarrativeOverviewReadModel(project: project);

      expect(model.mainStory.title, 'Fallback Global Story');
      expect(
          model.mainStory.sourceStatus, NarrativeOverviewSourceStatus.explicit);
      expect(model.metrics.chapters.count, 1);
      expect(model.metrics.chapters.sourceStatus,
          NarrativeOverviewSourceStatus.fallback);
      expect(model.mainStory.chapters.single.sourceStatus,
          NarrativeOverviewSourceStatus.fallback);
    });

    test('does not choose a main story when multiple global stories exist', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'test_global_story_a',
              name: 'A',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
            ScenarioAsset(
              id: 'test_global_story_b',
              name: 'B',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        ),
      );

      expect(model.mainStory.availability,
          NarrativeOverviewAvailability.unavailable);
      expect(model.mainStory.sourceStatus,
          NarrativeOverviewSourceStatus.ambiguous);
      expect(model.mainStory.canEdit, isFalse);
      expect(model.mainStory.title, isNull);
    });

    test('maps warning diagnostics to review status', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(),
        narrativeValidationReport: NarrativeValidationReport(
          diagnostics: const <NarrativeValidationDiagnostic>[
            NarrativeValidationDiagnostic(
              severity: NarrativeValidationSeverity.warning,
              kind: NarrativeValidationDiagnosticKind
                  .scenarioChoiceNodeRuntimeUnsupported,
              message: 'Choice node is not runtime-supported yet.',
              path: 'scenarios.test.nodes.choice',
            ),
          ],
        ),
      );

      expect(model.metrics.openIssues.count, 1);
      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.toReview);
      expect(model.editorialStatus.toReview, 1);
      expect(model.editorialStatus.blocking, 0);
      expect(model.projectHealth.healthKind,
          NarrativeProjectHealthKind.reviewNeeded);
    });

    test('maps error diagnostics to blocking status', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(),
        dialogueIssues: const <DialogueValidationIssue>[
          DialogueValidationIssue(
            severity: DialogueValidationSeverity.error,
            message: 'Réplique vide.',
          ),
        ],
      );

      expect(model.metrics.openIssues.count, 1);
      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.blocking);
      expect(model.editorialStatus.blocking, 1);
      expect(
          model.projectHealth.healthKind, NarrativeProjectHealthKind.blocked);
    });

    test('keeps zero real counts distinct from unavailable data', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(
          name: 'plain_test_project',
          scenarios: const <ScenarioAsset>[
            ScenarioAsset(
              id: 'plain_global_story',
              name: 'Plain Story',
              scope: ScenarioScope.globalStory,
              entryNodeId: 'start',
            ),
          ],
        ),
        narrativeValidationReport: NarrativeValidationReport(
            diagnostics: const <NarrativeValidationDiagnostic>[]),
      );

      expect(model.metrics.dialogues.count, 0);
      expect(model.metrics.dialogues.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.cutscenes.count, 0);
      expect(model.metrics.cutscenes.availability,
          NarrativeOverviewAvailability.empty);
      expect(model.metrics.openIssues.count, 0);
      expect(model.metrics.openIssues.availability,
          NarrativeOverviewAvailability.available);
      expect(model.editorialStatus.validationState,
          NarrativeEditorialValidationState.upToDate);

      expect(model.metrics.dialogueLines.count, isNull);
      expect(model.metrics.dialogueLines.availability,
          NarrativeOverviewAvailability.unavailable);
    });

    test('does not hardcode image or Selbrume values', () {
      final model = buildNarrativeOverviewReadModel(
        project: _project(
          name: 'plain_test_project',
          scenarios: <ScenarioAsset>[
            _globalStoryWithDocuments(
              name: 'Plain Test Story',
              description: 'No image copy here.',
            ),
          ],
          dialogues: const <ProjectDialogueEntry>[
            ProjectDialogueEntry(
              id: 'test_dialogue_1',
              name: 'Test Dialogue',
              relativePath: 'dialogues/test_dialogue_1.yarn',
            ),
          ],
        ),
      );

      expect(model.projectName, 'plain_test_project');
      expect(model.mainStory.title, 'Plain Test Story');
      expect(model.mainStory.description, 'No image copy here.');
      expect(model.projectName, isNot('Selbrume'));
      expect(model.mainStory.title, isNot('La brume du phare'));

      final realCounts = <int?>[
        model.metrics.chapters.count,
        model.metrics.scenes.count,
        model.metrics.cutscenes.count,
        model.metrics.quests.count,
        model.metrics.dialogues.count,
        model.metrics.dialogueLines.count,
        model.metrics.openIssues.count,
        model.metrics.conditions.count,
        model.metrics.worldRules.count,
        model.metrics.facts.count,
      ].whereType<int>().toSet();

      expect(realCounts.contains(42), isFalse);
      expect(realCounts.contains(1236), isFalse);
      expect(realCounts.contains(24), isFalse);
      expect(realCounts.contains(12), isFalse);
    });
  });
}

ProjectManifest _project({
  String name = 'test_project',
  List<ScenarioAsset> scenarios = const <ScenarioAsset>[],
  List<ProjectDialogueEntry> dialogues = const <ProjectDialogueEntry>[],
  List<CinematicAsset> cinematics = const <CinematicAsset>[],
}) {
  return ProjectManifest(
    surfaceCatalog: const ProjectSurfaceCatalog.empty(),
    name: name,
    maps: const <ProjectMapEntry>[],
    tilesets: const <ProjectTilesetEntry>[],
    scenarios: scenarios,
    dialogues: dialogues,
    cinematics: cinematics,
  );
}

ScenarioAsset _globalStoryWithDocuments({
  String name = 'Test Global Story',
  String description = 'A generic test story.',
}) {
  const stepDocument = StepStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    steps: <StepStudioStep>[
      StepStudioStep(
        id: 'test_step_1',
        name: 'Step One',
        description: 'First test step.',
        order: 0,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.atGameStart,
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenCutsceneEnds,
          cutsceneId: 'test_cutscene_1',
        ),
        cutscenes: <StepStudioCutsceneLink>[
          StepStudioCutsceneLink(
            cutsceneId: 'test_cutscene_1',
            role: StepStudioCutsceneRole.main,
          ),
        ],
        worldChanges: <StepStudioWorldChange>[
          StepStudioWorldChange(
            mapId: 'test_map',
            entityId: 'test_entity',
            presenceRule: StepStudioPresenceRule.visibleAfterStepCompletion,
          ),
        ],
      ),
      StepStudioStep(
        id: 'test_step_2',
        name: 'Step Two',
        description: 'Second test step.',
        order: 1,
        activation: StepStudioActivationRule(
          mode: StepStudioActivationMode.afterStep,
          stepId: 'test_step_1',
        ),
        completion: StepStudioCompletionRule(
          mode: StepStudioCompletionMode.whenOutcomeEmitted,
          outcomeId: 'progression.test_step_2.done',
        ),
        outcomes: <StepStudioOutcomeDefinition>[
          StepStudioOutcomeDefinition(
            label: 'Done',
            scope: StepStudioOutcomeScope.progression,
            outcomeId: 'progression.test_step_2.done',
          ),
        ],
      ),
    ],
  );

  const globalStoryDocument = GlobalStoryStudioDocument(
    globalStoryScenarioId: 'test_global_story',
    entryStepId: 'test_step_1',
    nodes: <GlobalStoryStepNode>[
      GlobalStoryStepNode(
        stepId: 'test_step_1',
        links: <GlobalStoryStepLink>[
          GlobalStoryStepLink(toStepId: 'test_step_2'),
        ],
      ),
      GlobalStoryStepNode(stepId: 'test_step_2'),
    ],
    chapters: <GlobalStoryChapter>[
      GlobalStoryChapter(
        id: 'test_chapter_1',
        name: 'Chapter One',
        description: 'First chapter.',
        stepIds: <String>['test_step_1'],
        order: 0,
      ),
      GlobalStoryChapter(
        id: 'test_chapter_2',
        name: 'Chapter Two',
        description: 'Second chapter.',
        stepIds: <String>['test_step_2'],
        order: 1,
      ),
    ],
  );

  return ScenarioAsset(
    id: 'test_global_story',
    name: name,
    description: description,
    scope: ScenarioScope.globalStory,
    entryNodeId: 'start',
    metadata: <String, String>{
      kStepStudioSchemaMetadataKey: kStepStudioSchemaVersion,
      kStepStudioDocumentMetadataKey: stepDocument.toMetadataJson(),
      kGlobalStoryStudioSchemaMetadataKey: kGlobalStoryStudioSchemaVersion,
      kGlobalStoryStudioDocumentMetadataKey:
          globalStoryDocument.toMetadataJson(),
    },
  );
}

ScenarioAsset _cutsceneScenario({
  required String id,
  String? dialogueId,
}) {
  return ScenarioAsset(
    id: id,
    name: 'Test Cutscene',
    scope: ScenarioScope.localEventFlow,
    entryNodeId: 'start',
    metadata: const <String, String>{
      kCutsceneStudioSchemaMetadataKey: kCutsceneStudioSchemaVersion,
    },
    nodes: <ScenarioNode>[
      if (dialogueId != null)
        ScenarioNode(
          id: 'open_dialogue',
          payload: const ScenarioNodePayload(actionKind: 'openDialogue'),
          binding: ScenarioNodeBinding(dialogueId: dialogueId),
        ),
    ],
  );
}
