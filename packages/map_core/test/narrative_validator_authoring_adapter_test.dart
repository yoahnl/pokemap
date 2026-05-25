import 'package:map_core/map_core.dart';
import 'package:test/test.dart';

void main() {
  group('Narrative validator authoring adapter', () {
    test('maps declaredOutcomeNeverEmitted to outcome authoring view', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted,
          severity: NarrativeValidationSeverity.warning,
          path: 'scenarios.p4_scene.declaredOutcomes.0',
          referencedId: 'p4.outcome.done',
          scenarioId: 'p4_scene',
        ),
      );

      expect(view.technicalKind,
          NarrativeValidationDiagnosticKind.declaredOutcomeNeverEmitted);
      expect(view.severity, NarrativeValidationSeverity.warning);
      expect(
          view.category, NarrativeAuthoringDiagnosticCategory.outcomeAuthoring);
      expect(
          view.actionKind, NarrativeAuthoringDiagnosticActionKind.emitOutcome);
      expect(view.title, 'Outcome declared but never emitted');
      expect(view.actionHint, contains('emitOutcome'));
    });

    test('maps emitOutcomeNotDeclared to outcome authoring view', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared,
          severity: NarrativeValidationSeverity.warning,
          referencedId: 'p4.outcome.done',
        ),
      );

      expect(
          view.category, NarrativeAuthoringDiagnosticCategory.outcomeAuthoring);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.declareOutcome);
      expect(view.title, 'Outcome emitted without declaration');
      expect(view.message, contains('is emitted but is not declared'));
    });

    test('maps predicate diagnostics to predicate authoring views', () {
      final visibility = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .visibilityRuleConditionalMissingPredicate,
          severity: NarrativeValidationSeverity.error,
          path: 'maps.p4_map.entities.p4_npc.visibilityRule.predicate',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );
      final emptyRef = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.worldRulePredicateEmptyRefId,
          severity: NarrativeValidationSeverity.error,
          path: 'maps.p4_map.entities.p4_npc.visibilityRule.predicate.refId',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );

      expect(visibility.category,
          NarrativeAuthoringDiagnosticCategory.predicateAuthoring);
      expect(visibility.actionKind,
          NarrativeAuthoringDiagnosticActionKind.fixPredicate);
      expect(visibility.title, 'Visibility rule has no condition');
      expect(emptyRef.category,
          NarrativeAuthoringDiagnosticCategory.predicateAuthoring);
      expect(emptyRef.actionKind,
          NarrativeAuthoringDiagnosticActionKind.fixPredicate);
      expect(emptyRef.title, 'Predicate reference is incomplete');
    });

    test('maps unsupported choice node to runtime support view', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .scenarioChoiceNodeRuntimeUnsupported,
          severity: NarrativeValidationSeverity.warning,
          scenarioId: 'p4_scene',
          nodeId: 'p4_choice',
        ),
      );

      expect(
          view.category, NarrativeAuthoringDiagnosticCategory.runtimeSupport);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.replaceUnsupportedNode);
      expect(view.title, 'Choice node is not runtime-supported yet');
    });

    test('preserves severity and technical context fields', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .openDialogueReferencesUnknownDialogue,
          severity: NarrativeValidationSeverity.error,
          path: 'scenarios.p4_scene.nodes.p4_dialogue.binding.dialogueId',
          referencedId: 'p4_missing_dialogue',
          scenarioId: 'p4_scene',
          nodeId: 'p4_dialogue',
          mapId: 'p4_map',
          entityId: 'p4_npc',
        ),
      );

      expect(view.category,
          NarrativeAuthoringDiagnosticCategory.dialogueReference);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.selectValidReference);
      expect(view.severity, NarrativeValidationSeverity.error);
      expect(
          view.path, 'scenarios.p4_scene.nodes.p4_dialogue.binding.dialogueId');
      expect(view.referencedId, 'p4_missing_dialogue');
      expect(view.scenarioId, 'p4_scene');
      expect(view.nodeId, 'p4_dialogue');
      expect(view.mapId, 'p4_map');
      expect(view.entityId, 'p4_npc');
      expect(
        view.debugTechnicalLabel,
        contains('openDialogueReferencesUnknownDialogue'),
      );
    });

    test('maps trainer battle diagnostics to trainer battle reference view',
        () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .startTrainerBattleReferencesUnknownTrainer,
          severity: NarrativeValidationSeverity.error,
          referencedId: 'p4_missing_trainer',
        ),
      );

      expect(view.category,
          NarrativeAuthoringDiagnosticCategory.trainerBattleReference);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.selectValidReference);
      expect(view.title, 'Trainer battle reference is invalid');
      expect(view.actionHint, contains('trainer'));
    });

    test('maps unmapped diagnostics to unknown without automatic fix', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.flagReadNeverProduced,
          severity: NarrativeValidationSeverity.warning,
          referencedId: 'p4.flag.never.produced',
        ),
      );

      expect(view.category, NarrativeAuthoringDiagnosticCategory.unknown);
      expect(view.actionKind,
          NarrativeAuthoringDiagnosticActionKind.noAutomaticFix);
      expect(view.title, 'Narrative diagnostic');
      expect(view.actionHint, contains('Inspect this diagnostic manually'));
    });

    test('builds stable immutable lists without auto-fix metadata', () {
      final diagnostics = [
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.emitOutcomeNotDeclared,
          severity: NarrativeValidationSeverity.warning,
          referencedId: 'p4.outcome.done',
        ),
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind.scenarioGraphHasNoSource,
          severity: NarrativeValidationSeverity.error,
          scenarioId: 'p4_scene',
        ),
      ];

      final first = buildNarrativeAuthoringDiagnosticViews(diagnostics);
      final second = buildNarrativeAuthoringDiagnosticViews(diagnostics);

      expect(first.map((view) => view.debugTechnicalLabel),
          second.map((view) => view.debugTechnicalLabel));
      expect(
        () => first.add(first.first),
        throwsA(isA<UnsupportedError>()),
      );
      expect(first.every((view) => !view.hasAutomaticFix), isTrue);
    });

    test('does not hardcode Selbrume identifiers', () {
      final view = buildNarrativeAuthoringDiagnosticView(
        _diagnostic(
          kind: NarrativeValidationDiagnosticKind
              .scenarioChoiceNodeRuntimeUnsupported,
          severity: NarrativeValidationSeverity.warning,
          scenarioId: 'p4_scene',
          nodeId: 'p4_choice',
        ),
      );

      final serialized = [
        view.title,
        view.message,
        view.actionHint,
        view.debugTechnicalLabel,
      ].join('\n').toLowerCase();

      expect(serialized, isNot(contains('selbrume')));
      expect(serialized, isNot(contains('lysa')));
      expect(serialized, isNot(contains('mael')));
      expect(serialized, isNot(contains('maël')));
      expect(serialized, isNot(contains('mado')));
    });
  });
}

NarrativeValidationDiagnostic _diagnostic({
  required NarrativeValidationDiagnosticKind kind,
  required NarrativeValidationSeverity severity,
  String path = 'p4.path',
  String? referencedId,
  String? scenarioId,
  String? nodeId,
  String? mapId,
  String? entityId,
}) {
  return NarrativeValidationDiagnostic(
    severity: severity,
    kind: kind,
    message: 'technical message for ${kind.name}',
    path: path,
    referencedId: referencedId,
    scenarioId: scenarioId,
    nodeId: nodeId,
    mapId: mapId,
    entityId: entityId,
  );
}
