import 'package:map_core/map_core_domain.dart';

import 'narrative_interaction.dart';
import 'narrative_overview.dart';
import 'narrative_overview_context.dart';

class NarrativeOverviewReferences {
  NarrativeOverviewReferences(this.context);
  final NarrativeOverviewContext context;
  final _items = <String, NarrativeOverviewReference>{};
  Iterable<NarrativeOverviewReference> get values => _items.values;

  String add(NarrativeOverviewReferenceKind kind, String id) {
    final ref = context.reference(kind, id);
    _items[ref.identity] = ref;
    return ref.label;
  }

  void known(NarrativeOverviewReferenceKind kind, String id, String label) {
    final ref = NarrativeOverviewReference(kind, id, label, false);
    _items[ref.identity] = ref;
  }

  String condition(NarrativeEventCondition condition) => condition.whenTyped(
    fact: (id, operator, value) {
      final label = add(NarrativeOverviewReferenceKind.fact, id);
      final comparison = switch (operator) {
        NarrativeFactOperator.equals => 'vaut',
        NarrativeFactOperator.notEquals => 'ne vaut pas',
        NarrativeFactOperator.greaterThan => 'est supérieur à',
        NarrativeFactOperator.greaterThanOrEqual => 'est au moins',
        NarrativeFactOperator.lessThan => 'est inférieur à',
        NarrativeFactOperator.lessThanOrEqual => 'est au plus',
      };
      return '$label $comparison ${value.kind == NarrativeValueKind.boolean
          ? value.boolValue
                ? 'vrai'
                : 'faux'
          : value.toJson()}';
    },
    narrativeEventConsumed: (id, value) =>
        '${add(NarrativeOverviewReferenceKind.event, id)} ${value ? 'a déjà été jouée' : 'n’a pas encore été jouée'}',
  );

  String step(NarrativeSequenceStep step) => switch (step.kind) {
    NarrativeSequenceKind.dialogue =>
      'Afficher le dialogue « ${add(NarrativeOverviewReferenceKind.dialogue, step.targetId)} »',
    NarrativeSequenceKind.setFact =>
      '${add(NarrativeOverviewReferenceKind.fact, step.targetId)} devient ${step.value ? 'vrai' : 'faux'}',
    NarrativeSequenceKind.completeStep =>
      'Terminer l’étape « ${add(NarrativeOverviewReferenceKind.step, step.targetId)} »',
    NarrativeSequenceKind.wait => 'Attendre ${step.milliseconds} ms',
    NarrativeSequenceKind.facing => 'Orienter un personnage',
  };

  void scene(SceneAsset scene) {
    for (final node in scene.graph.nodes) {
      switch (node.payload) {
        case SceneYarnDialoguePayload(:final dialogueId):
          add(NarrativeOverviewReferenceKind.dialogue, dialogueId);
        case SceneActionPayload(:final consequence):
          switch (consequence) {
            case SceneCompleteStoryStepConsequence(:final stepId):
              add(NarrativeOverviewReferenceKind.step, stepId);
            case SceneSetFactConsequence(:final factId):
              add(NarrativeOverviewReferenceKind.fact, factId);
            case SceneMarkEventConsumedConsequence(:final eventId):
              add(NarrativeOverviewReferenceKind.event, eventId);
            default:
              break;
          }
        case SceneCinematicPayload(:final cinematicId):
          add(NarrativeOverviewReferenceKind.cinematic, cinematicId);
        case SceneConditionPayload(:final conditionSource):
          if (conditionSource != null) {
            final kind = switch (conditionSource.sourceKind) {
              SceneConditionSourceKind.fact =>
                NarrativeOverviewReferenceKind.fact,
              SceneConditionSourceKind.storyStepCompletion ||
              SceneConditionSourceKind.storyStepActive =>
                NarrativeOverviewReferenceKind.step,
              SceneConditionSourceKind.consumedEvent =>
                NarrativeOverviewReferenceKind.event,
              _ => null,
            };
            if (kind != null) add(kind, conditionSource.sourceId);
          }
        default:
          break;
      }
    }
  }
}
