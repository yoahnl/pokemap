part of 'map_builder_story_binding.dart';

extension MapStoryConditionEditing on MapBuilderStoryBinding {
  BehaviourConditions conditionsOf(NarrativeEventRecord record) =>
      readBehaviourConditions(record);

  List<NarrativeFactDefinition> get conditionFacts {
    final project = maps.project;
    if (project == null) return const [];
    final facts = behaviours.project(project).facts;
    final cached = _lines.facts;
    if (cached != null && identical(cached.$1, facts)) return cached.$2;
    final usable = List<NarrativeFactDefinition>.unmodifiable(
      [
        for (final fact in facts)
          if (behaviourConditionTests(fact.initialValue.kind).isNotEmpty) fact,
      ]..sort((a, b) => a.label.toLowerCase().compareTo(b.label.toLowerCase())),
    );
    _lines.facts = (facts, usable);
    return usable;
  }

  NarrativeFactDefinition? conditionFact(String id) {
    final project = maps.project;
    return project == null
        ? null
        : behaviours.draft.effective(
            StoryDraftKind.fact,
            id,
            behaviours.saved(project),
          );
  }

  bool setConditions(NarrativeEventRecord record, BehaviourConditions next) =>
      _operate([record], [_expression(record, next)]);

  bool addConditionOnNewFact(
    NarrativeEventRecord record,
    String label,
    NarrativeValueKind kind,
  ) {
    final project = maps.project;
    if (project == null || label.trim().isEmpty) return false;
    final fact = addNarrativeFact(
      behaviours.project(project),
      label: label,
      initialValue: kind == NarrativeValueKind.integer
          ? NarrativeValue.integer(0)
          : const NarrativeValue.boolean(false),
    ).createdFact;
    final condition = kind == NarrativeValueKind.integer
        ? BehaviourEditableCondition.equalsNumber(fact.id, 0)
        : BehaviourEditableCondition.isTrue(fact.id);
    return _operate(
      [record],
      [_expression(record, readBehaviourConditions(record).adding(condition))],
      stage: (draft) {
        draft.load(StoryDraftKind.fact, fact.id, null);
        draft.put(StoryDraftKind.fact, fact);
      },
    );
  }

  MapStoryBehaviourOperation _expression(
    NarrativeEventRecord record,
    BehaviourConditions next,
  ) =>
      (c) => setNarrativeEventConditionExpression(
        context: c,
        expectedRevision: c.revision,
        eventId: record.id,
        expression: next.expression,
      );
}
