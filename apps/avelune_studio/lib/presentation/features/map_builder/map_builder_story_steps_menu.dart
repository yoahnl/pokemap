part of 'map_builder_story_steps.dart';

typedef _NewStep = ({SceneNodeKind kind, SceneNodePayload payload});

SceneConditionPayload? _defaultCondition(ProjectManifest project) {
  final fact = project.facts
      .where((fact) => fact.initialValue.kind == NarrativeValueKind.boolean)
      .firstOrNull;
  if (fact == null) return null;
  return SceneConditionPayload(
    conditionLabel: fact.label,
    conditionRef: fact.id,
    conditionSource: SceneConditionSource(
      sourceKind: SceneConditionSourceKind.fact,
      sourceId: fact.id,
      operator: SceneConditionOperator.isTrue,
      label: fact.label,
    ),
  );
}

_NewStep? _newStepOf(SceneStepFamily family, _Steps steps) {
  final project = steps.project;
  final map = steps.map;
  switch (family) {
    case SceneStepFamily.rememberFact:
      final factId = _booleanFacts(project).keys.firstOrNull;
      return factId == null
          ? null
          : (
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setFact(factId: factId, value: true),
              ),
            );
    case SceneStepFamily.talk:
      final dialogue = project.dialogues.firstOrNull;
      return dialogue == null
          ? null
          : (
              kind: SceneNodeKind.yarnDialogue,
              payload: SceneYarnDialoguePayload(dialogueId: dialogue.id),
            );
    case SceneStepFamily.showOrHide:
      final entity = map?.entities
          .where((entity) => entity.npc != null)
          .firstOrNull;
      return map == null || entity == null
          ? null
          : (
              kind: SceneNodeKind.action,
              payload: SceneActionPayload.consequence(
                SceneConsequence.setNpcPresence(
                  mapId: map.id,
                  entityId: entity.id,
                  present: true,
                ),
              ),
            );
    case SceneStepFamily.battle:
      final trainer = project.trainers.firstOrNull;
      return trainer == null
          ? null
          : (
              kind: SceneNodeKind.battle,
              payload: SceneBattlePayload(
                battleKind: 'trainer',
                trainerId: trainer.id,
              ),
            );
    case SceneStepFamily.conditions:
      final condition = _defaultCondition(project);
      return condition == null
          ? null
          : (kind: SceneNodeKind.condition, payload: condition);
    case SceneStepFamily.musicAndSound:
    case SceneStepFamily.giveItem:
    case SceneStepFamily.other:
      return null;
  }
}

const _insertableFamilies = [
  SceneStepFamily.rememberFact,
  SceneStepFamily.talk,
  SceneStepFamily.showOrHide,
  SceneStepFamily.battle,
  SceneStepFamily.conditions,
];

class _AddStep extends StatelessWidget {
  const _AddStep({super.key, required this.steps, required this.slot});

  final _Steps steps;
  final SceneStepSlot slot;

  @override
  Widget build(BuildContext context) {
    final l10n = steps.l10n;
    return Align(
      alignment: Alignment.centerLeft,
      child: MenuAnchor(
        menuChildren: [
          for (final family in _insertableFamilies)
            MenuItemButton(
              key: ValueKey('story-step-new-${family.name}'),
              leadingIcon: Icon(_familyIcon(family), size: 18),
              onPressed: switch (_newStepOf(family, steps)) {
                final step? => () => steps.insert(slot, step),
                null => null,
              },
              child: Text(l10n.storyStepFamily(family.name)),
            ),
        ],
        builder: (context, menu, _) => StudioButton(
          variant: StudioButtonVariant.quiet,
          icon: Icons.add,
          label: l10n.storyStepAdd,
          onPressed: () => menu.isOpen ? menu.close() : menu.open(),
        ),
      ),
    );
  }
}

class _ReadOnlyGraph extends StatelessWidget {
  const _ReadOnlyGraph({
    super.key,
    required this.steps,
    required this.explanation,
  });

  final _Steps steps;
  final String explanation;

  @override
  Widget build(BuildContext context) {
    final nodes = steps.projection.graph.nodes.where(
      (node) => !const {
        SceneNodeKind.start,
        SceneNodeKind.end,
        SceneNodeKind.merge,
        SceneNodeKind.branchByOutcome,
      }.contains(node.kind),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioNotice(explanation),
        for (final node in nodes) ...[
          const SizedBox(height: StudioSpacing.s),
          _StepCard(steps: steps, node: node, nodeId: node.id, slot: null),
        ],
      ],
    );
  }
}
