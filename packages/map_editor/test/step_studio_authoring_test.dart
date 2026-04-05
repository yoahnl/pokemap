import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core.dart';
import 'package:map_editor/src/features/narrative/application/step_studio_authoring.dart';

void main() {
  group('Step Studio authoring', () {
    test('parses legacy step metadata as fallback document', () {
      const scenario = ScenarioAsset(
        id: 'global_main',
        name: 'Global Main',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
        metadata: <String, String>{
          'step.id': 'step.emma_intro',
          'step.name': 'Rencontrer Emma',
          'step.description': 'Parler à Emma dehors',
          'step.cutsceneIds': 'emma_intro_outside',
        },
        declaredOutcomes: <String>['emma.intro.completed'],
      );

      final parse = parseStepStudioDocumentFromGlobalScenario(scenario);

      expect(parse.document.steps, hasLength(1));
      expect(parse.usedLegacyFallback, isTrue);
      final step = parse.document.steps.first;
      expect(step.id, 'step.emma_intro');
      expect(step.cutscenes.first.cutsceneId, 'emma_intro_outside');
      expect(step.outcomes.first.outcomeId, 'emma.intro.completed');
    });

    test('apply + parse roundtrip keeps explicit Step Studio document', () {
      const sourceScenario = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      );

      const document = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_rencontrer_emma',
            name: 'Rencontrer Emma',
            description: 'Parler avec Emma à l’extérieur',
            order: 0,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.whenCutsceneEnds,
              cutsceneId: 'emma_intro_outside',
            ),
            cutscenes: <StepStudioCutsceneLink>[
              StepStudioCutsceneLink(
                cutsceneId: 'emma_intro_outside',
                role: StepStudioCutsceneRole.main,
              ),
            ],
            outcomes: <StepStudioOutcomeDefinition>[
              StepStudioOutcomeDefinition(
                label: 'Emma rencontrée',
                scope: StepStudioOutcomeScope.progression,
                outcomeId: 'progression.step_rencontrer_emma.emma_rencontree',
              ),
            ],
            worldChanges: <StepStudioWorldChange>[
              StepStudioWorldChange(
                mapId: 'bourivka_center',
                entityId: 'emma_outside',
                presenceRule: StepStudioPresenceRule.hiddenAfterStepCompletion,
              ),
            ],
          ),
        ],
      );

      final updated = applyStepStudioDocumentToGlobalScenario(
        sourceScenario,
        document,
      );
      final parse = parseStepStudioDocumentFromGlobalScenario(updated);

      expect(
        updated.metadata[kStepStudioSchemaMetadataKey],
        kStepStudioSchemaVersion,
      );
      expect(parse.usedLegacyFallback, isFalse);
      expect(parse.document.steps, hasLength(1));
      expect(parse.document.steps.first.name, 'Rencontrer Emma');
      expect(
        parse.document.steps.first.worldChanges.first.entityId,
        'emma_outside',
      );
    });

    test('generates stable user-friendly ids', () {
      final stepId = generateUniqueStepId(
        'Rencontrer Emma',
        existingIds: const <String>{'rencontrer_emma'},
      );
      final outcomeId = generateOutcomeIdFromLabel(
        stepId: stepId,
        label: 'Emma dans le labo',
        scope: StepStudioOutcomeScope.world,
      );

      expect(stepId, 'rencontrer_emma_1');
      expect(outcomeId, 'world.rencontrer_emma_1.emma_dans_le_labo');
    });

    test('apply + parse roundtrip keeps Step Studio flow labels + exit link', () {
      const sourceScenario = ScenarioAsset(
        id: 'global_story',
        name: 'Global Story',
        scope: ScenarioScope.globalStory,
        entryNodeId: 'start',
      );

      const document = StepStudioDocument(
        globalStoryScenarioId: 'global_story',
        steps: <StepStudioStep>[
          StepStudioStep(
            id: 'step_starter',
            name: 'Choix du starter',
            description: 'Exemple produit',
            order: 0,
            flowEntryLabel: 'Professeur rencontré.',
            flowObjectiveLabel: 'Choisir un starter.',
            flowValidationLabel: 'Starter attribué.',
            flowExitLabel: 'Débloquer combat rival.',
            flowUnlocksStepId: 'step_rival',
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: StepStudioCompletionRule(
              mode: StepStudioCompletionMode.whenOutcomeEmitted,
              outcomeId: 'chapter_1.starter_chosen',
            ),
            cutscenes: <StepStudioCutsceneLink>[],
            outcomes: <StepStudioOutcomeDefinition>[],
            worldChanges: <StepStudioWorldChange>[],
          ),
        ],
      );

      final updated = applyStepStudioDocumentToGlobalScenario(
        sourceScenario,
        document,
      );
      final parse = parseStepStudioDocumentFromGlobalScenario(updated);
      final step = parse.document.steps.single;

      expect(step.flowEntryLabel, 'Professeur rencontré.');
      expect(step.flowObjectiveLabel, 'Choisir un starter.');
      expect(step.flowValidationLabel, 'Starter attribué.');
      expect(step.flowExitLabel, 'Débloquer combat rival.');
      expect(step.flowUnlocksStepId, 'step_rival');
    });
  });
}
