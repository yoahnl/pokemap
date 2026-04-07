import 'dart:convert';

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

    test(
      'persist worldChanges: mapId "Bourivka center", step_2, entityId emma dans le JSON',
      () {
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
              id: 'step_2',
              name: 'Étape 2',
              description: 'Cas produit réel (ids authoring)',
              order: 1,
              activation: StepStudioActivationRule(
                mode: StepStudioActivationMode.atGameStart,
              ),
              completion: const StepStudioCompletionRule(
                mode: StepStudioCompletionMode.manual,
              ),
              worldChanges: <StepStudioWorldChange>[
                StepStudioWorldChange(
                  mapId: 'Bourivka center',
                  entityId: 'emma',
                  presenceRule:
                      StepStudioPresenceRule.hiddenAfterStepCompletion,
                ),
              ],
            ),
          ],
        );

        final updated = applyStepStudioDocumentToGlobalScenario(
          sourceScenario,
          document,
        );
        final raw = updated.metadata[kStepStudioDocumentMetadataKey]!;
        expect(raw, contains('"mapId":"Bourivka center"'));
        expect(raw, contains('"entityId":"emma"'));
        expect(raw, contains('"id":"step_2"'));
        expect(raw, contains('"presenceRule":"hiddenAfterStepCompletion"'));
      },
    );

    test(
      'réouverture: relire la chaîne metadata (comme après reload project.json) restaure Emma',
      () {
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
              id: 'step_2',
              name: 'Étape 2',
              description: 'Réhydratation',
              order: 1,
              activation: StepStudioActivationRule(
                mode: StepStudioActivationMode.atGameStart,
              ),
              completion: const StepStudioCompletionRule(
                mode: StepStudioCompletionMode.manual,
              ),
              worldChanges: <StepStudioWorldChange>[
                StepStudioWorldChange(
                  mapId: 'Bourivka center',
                  entityId: 'emma',
                  presenceRule:
                      StepStudioPresenceRule.hiddenAfterStepCompletion,
                ),
              ],
            ),
          ],
        );

        final updated = applyStepStudioDocumentToGlobalScenario(
          sourceScenario,
          document,
        );
        final blob = updated.metadata[kStepStudioDocumentMetadataKey]!;

        final roundTripDoc = StepStudioDocument.fromJson(
          jsonDecode(blob) as Map<String, dynamic>,
        );
        final wc = roundTripDoc.steps.single.worldChanges.single;
        expect(roundTripDoc.steps.single.id, 'step_2');
        expect(wc.mapId, 'Bourivka center');
        expect(wc.entityId, 'emma');
        expect(
          wc.presenceRule,
          StepStudioPresenceRule.hiddenAfterStepCompletion,
        );

        final parse = parseStepStudioDocumentFromGlobalScenario(updated);
        expect(
          parse.document.steps.single.worldChanges.single.entityId,
          'emma',
        );
        expect(
          parse.document.steps.single.worldChanges.single.mapId,
          'Bourivka center',
        );
      },
    );

    test(
      'apply + parse roundtrip keeps worldChanges when entityId is still empty',
      () {
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
            id: 'step_map_change',
            name: 'Carte',
            description: 'Test persistance worldChanges',
            order: 0,
            activation: StepStudioActivationRule(
              mode: StepStudioActivationMode.atGameStart,
            ),
            completion: const StepStudioCompletionRule(
              mode: StepStudioCompletionMode.manual,
            ),
            worldChanges: <StepStudioWorldChange>[
              StepStudioWorldChange(
                mapId: 'route_1',
                entityId: '',
                presenceRule:
                    StepStudioPresenceRule.visibleAfterStepCompletion,
                note: 'brouillon',
              ),
            ],
          ),
        ],
      );

      final updated = applyStepStudioDocumentToGlobalScenario(
        sourceScenario,
        document,
      );
      final raw = updated.metadata[kStepStudioDocumentMetadataKey];
      expect(raw, isNotNull);
      final decoded = jsonDecode(raw!) as Map<String, dynamic>;
      final steps = decoded['steps'] as List<dynamic>;
      final worldChangesJson =
          (steps.first as Map<String, dynamic>)['worldChanges'] as List;
      expect(worldChangesJson, hasLength(1));

      final parse = parseStepStudioDocumentFromGlobalScenario(updated);
      expect(parse.document.steps.single.worldChanges, hasLength(1));
      expect(parse.document.steps.single.worldChanges.first.mapId, 'route_1');
      expect(parse.document.steps.single.worldChanges.first.entityId, '');
      expect(parse.document.steps.single.worldChanges.first.note, 'brouillon');
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
