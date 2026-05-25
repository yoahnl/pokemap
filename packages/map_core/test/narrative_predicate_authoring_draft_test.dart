import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative predicate authoring draft', () {
    test('creates predicate drafts from reference picker options', () {
      final storyFlag =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.storyFlag,
          referenceId: 'p4.flag.visible',
        ),
      );
      expect(storyFlag.kind, NarrativePredicateAuthoringKind.storyFlagSet);
      expect(storyFlag.refId, 'p4.flag.visible');

      final storyStep =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.storyStep,
          referenceId: 'p4.step.visible',
        ),
      );
      expect(storyStep.kind, NarrativePredicateAuthoringKind.stepCompleted);
      expect(storyStep.refId, 'p4.step.visible');

      final cutscene =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.cutscene,
          referenceId: 'p4_cutscene_visible',
        ),
      );
      expect(cutscene.kind, NarrativePredicateAuthoringKind.cutsceneCompleted);
      expect(cutscene.refId, 'p4_cutscene_visible');

      final scenarioOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.scenarioOutcome,
          referenceId: narrativeScenarioOutcomeFlagReference('p4.outcome.done'),
        ),
      );
      expect(
          scenarioOutcome.kind, NarrativePredicateAuthoringKind.storyFlagSet);
      expect(scenarioOutcome.refId, 'scenario.outcome.p4.outcome.done');

      final battleOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.battleOutcome,
          referenceId: narrativeBattleOutcomeFlagReference(
            'p4_battle',
            NarrativeBattleOutcomeKind.victory,
          ),
        ),
      );
      expect(battleOutcome.kind, NarrativePredicateAuthoringKind.storyFlagSet);
      expect(battleOutcome.refId, 'battle:p4_battle:victory');
    });

    test('compiles predicate drafts to runtime predicates', () {
      final predicate =
          compileNarrativePredicateAuthoringDraftToRuntimePredicate(
        const NarrativePredicateAuthoringDraft(
          kind: NarrativePredicateAuthoringKind.chapterCompleted,
          refId: ' p4.chapter.done ',
        ),
      );

      expect(predicate.kind, MapEntityRuntimePredicateKind.chapterCompleted);
      expect(predicate.refId, 'p4.chapter.done');
    });

    test('diagnoses empty predicate reference ids', () {
      final diagnostics = validateNarrativePredicateAuthoringDraft(
        const NarrativePredicateAuthoringDraft(
          kind: NarrativePredicateAuthoringKind.storyFlagSet,
          refId: ' ',
        ),
      );

      expect(
        _diagnosticKinds(diagnostics),
        [NarrativePredicateAuthoringDiagnosticKind.emptyReferenceId],
      );
    });

    test('compiles visibleWhen visibility rule to NPC visibility rule', () {
      final rule =
          compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
        const NarrativeVisibilityRuleAuthoringDraft.visibleWhen(
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.storyFlagSet,
            refId: 'p4.flag.visible',
          ),
        ),
      );

      expect(rule.mode, MapEntityNpcVisibilityMode.visibleWhen);
      expect(rule.predicate!.kind, MapEntityRuntimePredicateKind.storyFlagSet);
      expect(rule.predicate!.refId, 'p4.flag.visible');
    });

    test('diagnoses conditional visibility rule without predicate', () {
      final diagnostics = validateNarrativeVisibilityRuleAuthoringDraft(
        const NarrativeVisibilityRuleAuthoringDraft.visibleWhen(),
      );

      expect(
        _diagnosticKinds(diagnostics),
        [NarrativePredicateAuthoringDiagnosticKind.missingPredicate],
      );
    });

    test('compiles conditional dialogue to runtime conditional dialogue', () {
      final dialogue =
          compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
        const NarrativeConditionalDialogueAuthoringDraft(
          dialogueId: ' p4.dialogue.flag ',
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.stepCompleted,
            refId: ' p4.step.visible ',
          ),
        ),
      );

      expect(dialogue.dialogue.dialogueId, 'p4.dialogue.flag');
      expect(dialogue.dialogue.scriptPathRelative, '');
      expect(dialogue.when.kind, MapEntityRuntimePredicateKind.stepCompleted);
      expect(dialogue.when.refId, 'p4.step.visible');
    });

    test('diagnoses empty dialogue ids and missing conditional predicates', () {
      final diagnostics = validateNarrativeConditionalDialogueAuthoringDraft(
        const NarrativeConditionalDialogueAuthoringDraft(dialogueId: ' '),
      );

      expect(
        _diagnosticKinds(diagnostics),
        containsAll([
          NarrativePredicateAuthoringDiagnosticKind.emptyDialogueId,
          NarrativePredicateAuthoringDiagnosticKind.missingPredicate,
        ]),
      );
    });

    test('accepts scenario outcome and battle outcome as technical flag refs',
        () {
      final scenarioOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.scenarioOutcome,
          referenceId: narrativeScenarioOutcomeFlagReference('p4.outcome.done'),
        ),
      );
      final battleOutcome =
          createNarrativePredicateAuthoringDraftFromReferenceOption(
        _predicateOption(
          kind: NarrativePredicateReferenceKind.battleOutcome,
          referenceId: narrativeBattleOutcomeFlagReference(
            'p4_battle',
            NarrativeBattleOutcomeKind.defeat,
          ),
        ),
      );

      expect(
          validateNarrativePredicateAuthoringDraft(scenarioOutcome), isEmpty);
      expect(validateNarrativePredicateAuthoringDraft(battleOutcome), isEmpty);
      expect(
        compileNarrativePredicateAuthoringDraftToRuntimePredicate(
          scenarioOutcome,
        ).kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(
        compileNarrativePredicateAuthoringDraftToRuntimePredicate(battleOutcome)
            .kind,
        MapEntityRuntimePredicateKind.storyFlagSet,
      );
      expect(scenarioOutcome.refId.startsWith('battle:'), isFalse);
      expect(battleOutcome.refId.startsWith('scenario.outcome.'), isFalse);
    });

    test('diagnoses technical outcome refs used as non-flag predicates', () {
      final diagnostics = validateNarrativePredicateAuthoringDraft(
        const NarrativePredicateAuthoringDraft(
          kind: NarrativePredicateAuthoringKind.stepCompleted,
          refId: 'battle:p4_battle:victory',
        ),
      );

      expect(
        _diagnosticKinds(diagnostics),
        [
          NarrativePredicateAuthoringDiagnosticKind
              .scenarioOutcomeBattleOutcomeConfusion,
        ],
      );
    });

    test('does not create registries or hardcode Selbrume identifiers', () {
      final visibility =
          compileNarrativeVisibilityRuleAuthoringDraftToNpcVisibilityRule(
        const NarrativeVisibilityRuleAuthoringDraft.hiddenWhen(
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.storyFlagSet,
            refId: 'battle:p4_battle:victory',
          ),
        ),
      );
      final dialogue =
          compileNarrativeConditionalDialogueAuthoringDraftToConditionalDialogue(
        const NarrativeConditionalDialogueAuthoringDraft(
          dialogueId: 'p4.dialogue.battle',
          predicate: NarrativePredicateAuthoringDraft(
            kind: NarrativePredicateAuthoringKind.storyFlagSet,
            refId: 'scenario.outcome.p4.outcome.done',
          ),
        ),
      );

      final serialized = {
        visibility.toJson().toString(),
        dialogue.toJson().toString(),
      }.join('\n').toLowerCase();

      expect(serialized, isNot(contains('registry')));
      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativePredicateReferencePickerOption _predicateOption({
  required NarrativePredicateReferenceKind kind,
  required String referenceId,
}) {
  return NarrativePredicateReferencePickerOption(
    referenceId: referenceId,
    referenceKind: kind,
    humanLabel: referenceId,
    sourceScenarioIds: const ['p4_source'],
    debugTechnicalLabel: referenceId,
  );
}

List<NarrativePredicateAuthoringDiagnosticKind> _diagnosticKinds(
  List<NarrativePredicateAuthoringDiagnostic> diagnostics,
) {
  return diagnostics.map((diagnostic) => diagnostic.kind).toList();
}
