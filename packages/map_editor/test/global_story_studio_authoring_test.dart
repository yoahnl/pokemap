import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/global_story_studio_authoring.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';

void main() {
  group('Global Story Studio authoring', () {
    test('builds a linear fallback flow when no global metadata is present',
        () {
      const stepDocument = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_intro',
            name: 'Introduction',
            description: '',
            order: 0,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_starter',
            name: 'Choisir starter',
            description: '',
            order: 1,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      const scenario = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      );

      final parse = parseGlobalStoryStudioDocumentFromGlobalScenario(
        scenario,
        stepDocument: stepDocument,
      );

      expect(parse.usedLegacyFallback, isTrue);
      expect(parse.document.entryStepId, 'step_intro');
      expect(parse.document.nodes, hasLength(2));
      expect(parse.document.nodes.first.stepId, 'step_intro');
      expect(parse.document.nodes.first.links.single.toStepId, 'step_starter');
      expect(parse.document.nodes.last.links, isEmpty);
    });

    test('normalizes invalid links, unknown steps, and self loops', () {
      const stepDocument = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_a',
            name: 'A',
            description: '',
            order: 0,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_b',
            name: 'B',
            description: '',
            order: 1,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      const raw = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'missing_step',
        nodes: <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_a',
            exitMode: GlobalStoryStepExitMode.linear,
            links: <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_a'),
              GlobalStoryStepLink(toStepId: 'unknown'),
              GlobalStoryStepLink(toStepId: 'step_b'),
              GlobalStoryStepLink(toStepId: 'step_b'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'ghost_step',
            links: <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_b'),
            ],
          ),
        ],
      );

      final normalized = normalizeGlobalStoryStudioDocument(
        document: raw,
        stepDocument: stepDocument,
      );

      expect(normalized.entryStepId, 'step_a');
      expect(normalized.nodes, hasLength(2));
      expect(normalized.nodes.first.stepId, 'step_a');
      // linear mode => at most one link after normalization.
      expect(normalized.nodes.first.links, hasLength(1));
      expect(normalized.nodes.first.links.single.toStepId, 'step_b');
      expect(normalized.nodes.last.stepId, 'step_b');
    });

    test('preserves branch conditional links and emits diagnostics', () {
      const stepDocument = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_intro',
            name: 'Intro',
            description: '',
            order: 0,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_fire',
            name: 'Route feu',
            description: '',
            order: 1,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_water',
            name: 'Route eau',
            description: '',
            order: 2,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      const document = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_intro',
        nodes: <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_intro',
            exitMode: GlobalStoryStepExitMode.branchConditional,
            links: <GlobalStoryStepLink>[
              GlobalStoryStepLink(
                toStepId: 'step_fire',
                conditionLabel: 'Starter feu',
                requiredOutcomeId: 'starter.selected.fire',
              ),
              GlobalStoryStepLink(
                toStepId: 'step_water',
                // Intentionally no condition metadata to verify diagnostics.
              ),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'step_fire',
            exitMode: GlobalStoryStepExitMode.converge,
            links: <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_water'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'step_water',
            exitMode: GlobalStoryStepExitMode.linear,
          ),
        ],
      );

      final normalized = normalizeGlobalStoryStudioDocument(
        document: document,
        stepDocument: stepDocument,
      );
      final warnings = computeGlobalStoryStudioDiagnostics(
        document: normalized,
        stepDocument: stepDocument,
      );

      expect(normalized.nodes.first.links, hasLength(2));
      expect(normalized.nodes.first.links.first.requiredOutcomeId,
          'starter.selected.fire');
      expect(
        warnings.any((warning) =>
            warning.contains('Branche conditionnelle incomplète') ||
            warning.contains('Branche conditionnelle incomplete')),
        isTrue,
      );
    });

    test('apply + parse roundtrip keeps global story macro structure', () {
      const sourceScenario = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      );

      const stepDocument = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_intro',
            name: 'Intro',
            description: '',
            order: 0,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
          StepStudioStep(
            id: 'step_lab',
            name: 'Labo',
            description: '',
            order: 1,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.afterPreviousStep,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
          ),
        ],
      );

      const globalDocument = GlobalStoryStudioDocument(
        globalStoryScenarioId: 'global_story',
        entryStepId: 'step_intro',
        nodes: <GlobalStoryStepNode>[
          GlobalStoryStepNode(
            stepId: 'step_intro',
            exitMode: GlobalStoryStepExitMode.linear,
            links: <GlobalStoryStepLink>[
              GlobalStoryStepLink(toStepId: 'step_lab'),
            ],
          ),
          GlobalStoryStepNode(
            stepId: 'step_lab',
            exitMode: GlobalStoryStepExitMode.linear,
          ),
        ],
      );

      final updated = applyGlobalStoryStudioDocumentToGlobalScenario(
        sourceScenario,
        globalDocument,
        stepDocument: stepDocument,
      );
      final parse = parseGlobalStoryStudioDocumentFromGlobalScenario(
        updated,
        stepDocument: stepDocument,
      );

      expect(
        updated.metadata[kGlobalStoryStudioSchemaMetadataKey],
        kGlobalStoryStudioSchemaVersion,
      );
      expect(parse.usedLegacyFallback, isFalse);
      expect(parse.document.entryStepId, 'step_intro');
      expect(parse.document.nodes.first.links.single.toStepId, 'step_lab');
    });
  });
}
