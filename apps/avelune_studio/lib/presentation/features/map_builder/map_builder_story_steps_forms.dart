part of 'map_builder_story_steps.dart';

Widget? _formOf(_Steps steps, SceneNode node) => switch (node.payload) {
  SceneActionPayload(consequence: final SceneSetFactConsequence fact)
      when fact.narrativeValue.kind == NarrativeValueKind.boolean =>
    _FactForm(steps: steps, node: node, fact: fact),
  SceneActionPayload(
    consequence: final SceneSetNpcPresenceConsequence change,
  ) =>
    _PresenceForm(steps: steps, node: node, change: change),
  SceneYarnDialoguePayload() => _DialogueView(steps: steps, node: node),
  SceneBattlePayload(battleKind: 'trainer') => _TrainerForm(
    steps: steps,
    node: node,
  ),
  SceneConditionPayload() => _ConditionForm(steps: steps, node: node),
  _ => null,
};

Map<String, Object?> _payloadJson(SceneNode node) =>
    Map<String, Object?>.from(node.toJson()['payload'] as Map);

void _editPayload(
  _Steps steps,
  SceneNode node,
  Map<String, Object?> Function(Map<String, Object?> payload) change,
) => steps.edit(
  SceneNode.fromJson({...node.toJson(), 'payload': change(_payloadJson(node))}),
);

Map<String, String> _withMissing(Map<String, String> options, String? id) => {
  if (id != null && !options.containsKey(id)) id: id,
  ...options,
};

Map<String, String> _booleanFacts(ProjectManifest project) => {
  for (final fact in project.facts)
    if (fact.initialValue.kind == NarrativeValueKind.boolean)
      fact.id: fact.label,
};

class _FactForm extends StatelessWidget {
  const _FactForm({
    required this.steps,
    required this.node,
    required this.fact,
  });

  final _Steps steps;
  final SceneNode node;
  final SceneSetFactConsequence fact;

  void _set({String? factId, bool? value}) => _editPayload(
    steps,
    node,
    (payload) => {
      ...payload,
      'consequence': {
        ...Map<String, Object?>.from(payload['consequence']! as Map),
        'factId': ?factId,
        'value': ?value,
      },
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = steps.l10n;
    return _Pair(
      first: StudioSelect(
        key: ValueKey('story-step-fact-${node.id}'),
        label: l10n.storyStepFactField,
        value: fact.factId,
        options: _withMissing(_booleanFacts(steps.project), fact.factId),
        onChanged: steps.editable ? (id) => _set(factId: id) : null,
      ),
      second: StudioSelect(
        key: ValueKey('story-step-value-${node.id}'),
        label: l10n.storyStepValueField,
        value: '${fact.value}',
        options: {'true': l10n.storyStepYes, 'false': l10n.storyStepNo},
        onChanged: steps.editable
            ? (value) => _set(value: value == 'true')
            : null,
      ),
    );
  }
}

class _PresenceForm extends StatelessWidget {
  const _PresenceForm({
    required this.steps,
    required this.node,
    required this.change,
  });

  final _Steps steps;
  final SceneNode node;
  final SceneSetNpcPresenceConsequence change;

  void _set({String? entityId, bool? present}) => _editPayload(
    steps,
    node,
    (payload) => {
      ...payload,
      'consequence': {
        ...Map<String, Object?>.from(payload['consequence']! as Map),
        'entityId': ?entityId,
        'present': ?present,
      },
    },
  );

  @override
  Widget build(BuildContext context) {
    final l10n = steps.l10n;
    final map = steps.map;
    final sameMap = map != null && map.id == change.mapId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!sameMap)
          _Caption(
            '${l10n.storyStepOtherMap(change.mapId)} · ${change.entityId}',
          ),
        _Pair(
          first: StudioSelect(
            key: ValueKey('story-step-entity-${node.id}'),
            label: l10n.storyStepCharacterField,
            value: change.entityId,
            options: _withMissing({
              if (sameMap)
                for (final entity in map.entities)
                  if (entity.npc != null)
                    entity.id: entity.name.isEmpty ? entity.id : entity.name,
            }, change.entityId),
            onChanged: steps.editable && sameMap
                ? (id) => _set(entityId: id)
                : null,
          ),
          second: StudioSelect(
            key: ValueKey('story-step-presence-${node.id}'),
            label: l10n.storyStepPresenceField,
            value: '${change.present}',
            options: {
              'true': l10n.storyStepAppear,
              'false': l10n.storyStepDisappear,
            },
            onChanged: steps.editable
                ? (value) => _set(present: value == 'true')
                : null,
          ),
        ),
      ],
    );
  }
}

class _DialogueView extends StatelessWidget {
  const _DialogueView({required this.steps, required this.node});

  final _Steps steps;
  final SceneNode node;

  @override
  Widget build(BuildContext context) {
    final payload = node.payload as SceneYarnDialoguePayload;
    final dialogue = steps.project.dialogues
        .where((entry) => entry.id == payload.dialogueId)
        .firstOrNull;
    return Column(
      key: ValueKey('story-step-dialogue-${node.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caption(steps.l10n.storyStepDialogue),
        Text(dialogue?.name ?? payload.dialogueId),
        if (payload.speakerHints.isNotEmpty) ...[
          const SizedBox(height: StudioSpacing.xs),
          _Caption(steps.l10n.storyStepSpeaker),
          Text(payload.speakerHints.join(', ')),
        ],
      ],
    );
  }
}

class _TrainerForm extends StatelessWidget {
  const _TrainerForm({required this.steps, required this.node});

  final _Steps steps;
  final SceneNode node;

  @override
  Widget build(BuildContext context) {
    final trainerId = (node.payload as SceneBattlePayload).trainerId;
    return StudioSelect(
      key: ValueKey('story-step-trainer-${node.id}'),
      label: steps.l10n.storyStepTrainerField,
      value: trainerId,
      options: _withMissing({
        for (final trainer in steps.project.trainers) trainer.id: trainer.name,
      }, trainerId),
      onChanged: steps.editable
          ? (id) => _editPayload(
              steps,
              node,
              (payload) => {...payload, 'trainerId': id},
            )
          : null,
    );
  }
}

class _ConditionForm extends StatelessWidget {
  const _ConditionForm({required this.steps, required this.node});

  final _Steps steps;
  final SceneNode node;

  @override
  Widget build(BuildContext context) {
    final l10n = steps.l10n;
    final payload = node.payload as SceneConditionPayload;
    final source = payload.conditionSource;
    if (source == null ||
        source.sourceKind != SceneConditionSourceKind.fact ||
        source.operator == SceneConditionOperator.equals) {
      return _Caption(
        '${l10n.storyStepAdvancedCondition}'
        '${payload.conditionLabel == null ? '' : ' · ${payload.conditionLabel}'}',
      );
    }
    void set(String factId, SceneConditionOperator operator) {
      final label = _booleanFacts(steps.project)[factId];
      final updated = updateSceneConditionSource(
        steps.widget.scene,
        nodeId: node.id,
        source: SceneConditionSource(
          sourceKind: SceneConditionSourceKind.fact,
          sourceId: factId,
          operator: operator,
          label: factId == source.sourceId ? source.label : label,
        ),
      );
      steps.edit(updated.updatedNode);
    }

    return _Pair(
      first: StudioSelect(
        key: ValueKey('story-step-condition-fact-${node.id}'),
        label: '${l10n.storyStepIf} · ${l10n.storyStepFactField}',
        value: source.sourceId,
        options: _withMissing(_booleanFacts(steps.project), source.sourceId),
        onChanged: steps.editable ? (id) => set(id, source.operator) : null,
      ),
      second: StudioSelect(
        key: ValueKey('story-step-condition-value-${node.id}'),
        label: l10n.storyStepConditionField,
        value: source.operator.name,
        options: {
          SceneConditionOperator.isTrue.name: l10n.storyStepConditionTrue,
          SceneConditionOperator.isFalse.name: l10n.storyStepConditionFalse,
        },
        onChanged: steps.editable
            ? (value) => set(
                source.sourceId,
                SceneConditionOperator.values.byName(value),
              )
            : null,
      ),
    );
  }
}

class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: StudioSpacing.m),
      Expanded(child: second),
    ],
  );
}
