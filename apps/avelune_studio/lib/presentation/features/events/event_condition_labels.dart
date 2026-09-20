import 'package:map_core/map_core_domain.dart';
import 'event_labels.dart';

String eventOperatorLabel(NarrativeFactOperator operator) => switch (operator) {
  NarrativeFactOperator.equals => 'est égal à',
  NarrativeFactOperator.notEquals => 'est différent de',
  NarrativeFactOperator.greaterThan => 'est supérieur à',
  NarrativeFactOperator.greaterThanOrEqual => 'est au moins',
  NarrativeFactOperator.lessThan => 'est inférieur à',
  NarrativeFactOperator.lessThanOrEqual => 'est au plus',
};

String eventValueLabel(NarrativeValue value) =>
    value.kind == NarrativeValueKind.boolean
    ? value.boolValue
          ? 'Oui'
          : 'Non'
    : value.toJson().toString();

String eventConditionLabel(
  NarrativeEventCondition condition,
  List<NarrativeFactDefinition> facts,
  List<NarrativeEventRecord> records,
) => condition.whenTyped(
  fact: (id, operator, value) =>
      '${facts.where((f) => f.id == id).firstOrNull?.label ?? 'État absent : $id'} '
      '${eventOperatorLabel(operator)} ${eventValueLabel(value)}',
  narrativeEventConsumed: (id, expected) =>
      '${records.where((r) => r.id == id).map(eventName).firstOrNull ?? 'Événement absent : $id'} '
      '${expected ? 'a déjà été joué' : 'n’a pas encore été joué'}',
);

String eventExpressionLabel(
  NarrativeEventConditionExpression expression,
  List<NarrativeFactDefinition> facts,
  List<NarrativeEventRecord> records,
) => switch (expression) {
  NarrativeEventConditionLeaf(:final condition) => eventConditionLabel(
    condition,
    facts,
    records,
  ),
  NarrativeEventConditionAll(:final children) =>
    children.isEmpty
        ? 'Sans condition'
        : 'Toutes : ${children.map((e) => '(${eventExpressionLabel(e, facts, records)})').join(' et ')}',
  NarrativeEventConditionAny(:final children) =>
    'Au moins une : ${children.map((e) => '(${eventExpressionLabel(e, facts, records)})').join(' ou ')}',
  NarrativeEventConditionNot(:final child) =>
    'Inverser (${eventExpressionLabel(child, facts, records)})',
};
