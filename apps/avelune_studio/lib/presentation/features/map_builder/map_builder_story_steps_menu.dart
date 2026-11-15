part of 'map_builder_story_steps.dart';

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
          for (final family in sceneInsertableStepFamilies)
            MenuItemButton(
              key: ValueKey('story-step-new-${family.name}'),
              leadingIcon: Icon(_familyIcon(family), size: 18),
              onPressed: switch (sceneStepTemplateOf(
                family,
                steps.project,
                steps.map,
              )) {
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
