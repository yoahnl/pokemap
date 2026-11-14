part of 'map_builder_story_steps.dart';

class _StepView extends StatelessWidget {
  const _StepView({
    required this.steps,
    required this.step,
    required this.slot,
  });

  final _Steps steps;
  final SceneStep step;
  final SceneStepSlot slot;

  @override
  Widget build(BuildContext context) {
    final node = steps.node(step.nodeId);
    final card = _StepCard(
      steps: steps,
      node: node,
      nodeId: step.nodeId,
      slot: slot,
    );
    final current = step;
    if (current is! SceneBlockStep) return card;
    final family = node == null
        ? SceneStepFamily.other
        : sceneStepFamilyOfNode(node);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        card,
        for (final (index, branch) in current.branches.indexed)
          Padding(
            key: ValueKey('story-step-branch-${current.nodeId}-$index'),
            padding: const EdgeInsets.only(
              left: StudioSpacing.xl,
              top: StudioSpacing.xs,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    width: 2,
                  ),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(left: StudioSpacing.m),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Eyebrow(_branchLabel(steps.l10n, branch, family)),
                    _Sequence(
                      steps: steps,
                      sequence: branch.sequence,
                      blockNodeId: current.nodeId,
                      branchIndex: index,
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

String _branchLabel(
  AppLocalizations l10n,
  SceneStepBranch branch,
  SceneStepFamily family,
) => switch (branch.role) {
  SceneStepBranchRole.whenTrue => l10n.storyStepThen,
  SceneStepBranchRole.whenFalse => l10n.storyStepElse,
  SceneStepBranchRole.main => l10n.storyStepMain,
  SceneStepBranchRole.failure => l10n.storyStepOnFailure(
    branch.portIds
        .map(
          (port) => l10n.storyStepFailureReason(
            family == SceneStepFamily.musicAndSound && port == 'blocked'
                ? 'soundBlocked'
                : port,
          ),
        )
        .join(', '),
  ),
  SceneStepBranchRole.outcome => l10n.storyStepOutcome(
    branch.portIds.join(', '),
  ),
};

class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.steps,
    required this.node,
    required this.nodeId,
    required this.slot,
  });

  final _Steps steps;
  final SceneNode? node;
  final String nodeId;
  final SceneStepSlot? slot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = steps.l10n;
    final current = node;
    final family = current == null
        ? SceneStepFamily.other
        : sceneStepFamilyOfNode(current);
    final form = current == null ? null : _formOf(steps, current);
    final title = form == null
        ? l10n.storyStepAdvanced
        : l10n.storyStepFamily(family.name);
    final subtitle =
        current?.title ?? (form == null ? _commandOf(current) : null);
    final onPath = steps.widget.highlighted?.contains(nodeId);
    return Container(
      key: ValueKey(
        form == null ? 'story-step-advanced-$nodeId' : 'story-step-$nodeId',
      ),
      padding: const EdgeInsets.all(StudioSpacing.m),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        border: Border.all(
          color: onPath == true
              ? theme.colorScheme.primary
              : theme.colorScheme.outlineVariant,
          width: onPath == true ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
      ),
      foregroundDecoration: onPath == false
          ? BoxDecoration(
              color: theme.colorScheme.surface.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(StudioMetrics.panelRadius),
            )
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (steps.editable && slot != null)
                Draggable<String>(
                  data: nodeId,
                  feedback: Material(
                    color: theme.colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(
                      StudioMetrics.controlRadius,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(StudioSpacing.m),
                      child: Text(subtitle ?? title),
                    ),
                  ),
                  child: Tooltip(
                    message: l10n.storyStepDrag,
                    child: Icon(
                      Icons.drag_indicator,
                      key: ValueKey('story-step-drag-$nodeId'),
                      size: 18,
                    ),
                  ),
                ),
              const SizedBox(width: StudioSpacing.xs),
              Icon(_familyIcon(family), size: 18),
              const SizedBox(width: StudioSpacing.s),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (steps.editable && slot != null)
                _StepActions(steps: steps, nodeId: nodeId, slot: slot!),
            ],
          ),
          if (form != null) ...[
            const SizedBox(height: StudioSpacing.s),
            form,
          ] else if (current != null) ...[
            const SizedBox(height: StudioSpacing.xs),
            _Caption(l10n.storyStepAdvancedHint),
          ],
        ],
      ),
    );
  }
}

String? _commandOf(SceneNode? node) =>
    node == null ? null : sceneStepCommandIdOf(node) ?? node.kind.name;

IconData _familyIcon(SceneStepFamily family) => switch (family) {
  SceneStepFamily.rememberFact => Icons.bookmark_outline,
  SceneStepFamily.talk => Icons.chat_bubble_outline,
  SceneStepFamily.showOrHide => Icons.visibility_outlined,
  SceneStepFamily.musicAndSound => Icons.music_note_outlined,
  SceneStepFamily.battle => Icons.sports_martial_arts_outlined,
  SceneStepFamily.giveItem => Icons.card_giftcard_outlined,
  SceneStepFamily.conditions => Icons.call_split,
  SceneStepFamily.other => Icons.tune,
};

class _StepActions extends StatelessWidget {
  const _StepActions({
    required this.steps,
    required this.nodeId,
    required this.slot,
  });

  final _Steps steps;
  final String nodeId;
  final SceneStepSlot slot;

  @override
  Widget build(BuildContext context) {
    final l10n = steps.l10n;
    final condition = _defaultCondition(steps.project);
    return MenuAnchor(
      menuChildren: [
        MenuItemButton(
          key: ValueKey('story-step-wrap-$nodeId'),
          leadingIcon: const Icon(Icons.call_split, size: 18),
          onPressed: condition == null
              ? null
              : () => steps.wrap(slot, condition),
          child: Text(l10n.storyStepWrap),
        ),
        MenuItemButton(
          key: ValueKey('story-step-remove-$nodeId'),
          leadingIcon: const Icon(Icons.delete_outline, size: 18),
          onPressed: () => steps.remove(nodeId),
          child: Text(l10n.storyStepRemove),
        ),
      ],
      builder: (context, menu, _) => IconButton(
        key: ValueKey('story-step-actions-$nodeId'),
        tooltip: l10n.storyStepActions,
        icon: const Icon(Icons.more_horiz, size: 18),
        onPressed: () => menu.isOpen ? menu.close() : menu.open(),
      ),
    );
  }
}
