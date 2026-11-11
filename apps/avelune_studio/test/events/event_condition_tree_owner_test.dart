import 'package:avelune_studio/features/events/application/event_condition_editing.dart';
import 'package:avelune_studio/features/events/application/event_condition_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:map_core/map_core_domain.dart';

void main() {
  final facts = [NarrativeFactDefinition(id: 'ticket', label: 'Billet')];
  final ticket = NarrativeEventCondition.fact('ticket', true);
  final other = NarrativeEventCondition.fact('ticket', false);
  final ticketLeaf = NarrativeEventConditionExpression.leaf(ticket);
  final otherLeaf = NarrativeEventConditionExpression.leaf(other);

  test('only a leaf or a non empty group can be inverted', () {
    expect(canInvertEventCondition(ticketLeaf), isTrue);
    expect(
      canInvertEventCondition(NarrativeEventConditionExpression.all([ticketLeaf])),
      isTrue,
    );
    expect(
      canInvertEventCondition(NarrativeEventConditionExpression.any([otherLeaf])),
      isTrue,
    );
    expect(
      canInvertEventCondition(NarrativeEventConditionExpression.all([])),
      isFalse,
    );
    expect(
      canInvertEventCondition(NarrativeEventConditionExpression.not(ticketLeaf)),
      isFalse,
    );
  });

  test('inverting wraps the expression and keeps it intact', () {
    final group = NarrativeEventConditionExpression.all([ticketLeaf]);
    final inverted = invertedEventCondition(group);
    expect(inverted, NarrativeEventConditionExpression.not(group));
    expect(
      (inverted as NarrativeEventConditionNot).child,
      NarrativeEventConditionExpression.all([ticketLeaf]),
    );
  });

  test('adding to a leaf replaces it while adding to a group appends and keeps its kind', () {
    expect(withAddedEventCondition(ticketLeaf, other), otherLeaf);
    expect(
      withAddedEventCondition(
        NarrativeEventConditionExpression.any([ticketLeaf]),
        other,
      ),
      NarrativeEventConditionExpression.any([ticketLeaf, otherLeaf]),
    );
    expect(
      withAddedEventCondition(NarrativeEventConditionExpression.all([]), ticket),
      NarrativeEventConditionExpression.all([ticketLeaf]),
    );
  });

  test('adding a group nests the new condition in an all group', () {
    expect(
      withAddedEventConditionGroup(
        NarrativeEventConditionExpression.any([ticketLeaf]),
        other,
      ),
      NarrativeEventConditionExpression.any([
        ticketLeaf,
        NarrativeEventConditionExpression.all([otherLeaf]),
      ]),
    );
  });

  test('a leaf grouped with another condition becomes an all group of both', () {
    expect(
      groupedEventCondition(ticketLeaf, other),
      NarrativeEventConditionExpression.all([ticketLeaf, otherLeaf]),
    );
  });

  test('replacing or removing a child keeps the group kind and the other children', () {
    final group = NarrativeEventConditionExpression.any([ticketLeaf, otherLeaf]);
    final replacement = NarrativeEventConditionExpression.not(otherLeaf);
    expect(
      withEventConditionChild(group, 1, replacement),
      NarrativeEventConditionExpression.any([ticketLeaf, replacement]),
    );
    expect(
      removeEventConditionChild(group, 0),
      NarrativeEventConditionExpression.any([otherLeaf]),
    );
    expect(
      group,
      NarrativeEventConditionExpression.any([ticketLeaf, otherLeaf]),
    );
  });

  test('only groups expose children', () {
    expect(eventConditionGroupChildren(ticketLeaf), isEmpty);
    expect(
      eventConditionGroupChildren(
        NarrativeEventConditionExpression.not(ticketLeaf),
      ),
      isEmpty,
    );
    expect(
      eventConditionGroupChildren(
        NarrativeEventConditionExpression.all([ticketLeaf, otherLeaf]),
      ),
      [ticketLeaf, otherLeaf],
    );
  });

  test('each node kind has its own title', () {
    expect(
      eventConditionNodeTitle(NarrativeEventConditionExpression.all([]), facts, const []),
      'Sans condition',
    );
    expect(
      eventConditionNodeTitle(
        NarrativeEventConditionExpression.all([ticketLeaf]),
        facts,
        const [],
      ),
      'Toutes ces conditions',
    );
    expect(
      eventConditionNodeTitle(
        NarrativeEventConditionExpression.any([]),
        facts,
        const [],
      ),
      'Au moins une condition',
    );
    expect(
      eventConditionNodeTitle(
        NarrativeEventConditionExpression.not(ticketLeaf),
        facts,
        const [],
      ),
      'Inverser cette condition',
    );
    expect(
      eventConditionNodeTitle(ticketLeaf, facts, const []),
      eventConditionLabel(ticket, facts, const []),
    );
    expect(eventConditionLabel(ticket, facts, const []), contains('Billet'));
  });
}
