part of 'map_builder_story_inspector.dart';

class MapBuilderStoryBehaviourEditor extends StatelessWidget {
  const MapBuilderStoryBehaviourEditor({
    super.key,
    required this.binding,
    required this.element,
    required this.enabled,
    this.sectionBuilder,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final bool enabled;
  final Widget Function(String section, Widget content)? sectionBuilder;

  Widget _section(String id, String label, List<Widget> children) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
    return sectionBuilder?.call(id, content) ??
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Eyebrow(label),
            const SizedBox(height: StudioSpacing.xs),
            content,
          ],
        );
  }

  Widget _identity(
    NarrativeEventRecord current,
    bool editable,
    AppLocalizations l10n,
  ) {
    final name = MapBuilderNameField(
      key: ValueKey('map-story-behaviour-name-${current.id}'),
      value: current.name,
      label: l10n.storyBehaviourNameField,
      enabled: editable,
      onCommit: (value) => binding.renameBehaviour(current, value),
    );
    final active = StudioToggleRow(
      key: const ValueKey('map-story-behaviour-active'),
      label: l10n.storyBehaviourActive,
      value: current.enabledOrNull == true,
      onChanged: editable ? (value) => binding.setActive(current, value) : null,
    );
    return sectionBuilder == null
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [name, active],
          )
        : Row(
            children: [
              Expanded(flex: 3, child: name),
              const SizedBox(width: StudioSpacing.l),
              Expanded(flex: 2, child: active),
            ],
          );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final behaviours = element.behaviours;
    final current = binding.selectedBehaviour;
    final editable =
        enabled &&
        !binding.editingBlocked &&
        binding.ready &&
        binding.editing?.problem == null;
    final scenes = [...?binding.project?.scenes]
      ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      key: const ValueKey('map-story-behaviours'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (binding.error ?? binding.editing?.problem case final error?) ...[
          StudioNotice(mapBuilderStoryError(error, l10n), isError: true),
          const SizedBox(height: StudioSpacing.m),
        ],
        if (!binding.ready) ...[
          _Caption(
            binding.preparing ? l10n.storyPreparing : l10n.storyNotPrepared,
          ),
          const SizedBox(height: StudioSpacing.m),
        ],
        StudioSection(
          title: l10n.storyBehavioursTitle(behaviours.length),
          collapsible: sectionBuilder != null && current != null,
          initiallyExpanded: sectionBuilder == null,
          children: [
            if (behaviours.isEmpty) _Caption(l10n.storyNoBehaviour),
            MapBuilderStoryCaseList(
              binding: binding,
              element: element,
              current: current,
              editable: editable,
              state: mapBuilderBehaviourState,
            ),
            const SizedBox(height: StudioSpacing.s),
            Align(
              alignment: Alignment.centerLeft,
              child: StudioButton(
                key: const ValueKey('map-story-behaviour-add'),
                variant: StudioButtonVariant.quiet,
                icon: Icons.add,
                label: l10n.storyAddBehaviour,
                onPressed: editable
                    ? () => binding.addBehaviour(element)
                    : null,
              ),
            ),
          ],
        ),
        if (current != null) ...[
          const SizedBox(height: StudioSpacing.l),
          _identity(current, editable, l10n),
          const SizedBox(height: StudioSpacing.s),
          _section('when', l10n.storyWhen, [
            StudioSelect(
              key: const ValueKey('map-story-when'),
              label: l10n.storyWhenField,
              value: current.source?.kind.name ?? '',
              options: {
                if (current.source == null) '': l10n.storyTrigger('none'),
                for (final kind in binding.triggerKinds(element))
                  kind.name: l10n.storyTrigger(kind.name),
                if (current.source?.kind case final kind?
                    when !binding.triggerKinds(element).contains(kind))
                  kind.name: l10n.storyTrigger(kind.name),
              },
              onChanged: editable
                  ? (value) => binding.setTrigger(
                      element,
                      current,
                      NarrativeEventSourceKind.values.byName(value),
                    )
                  : null,
            ),
          ]),
          const SizedBox(height: StudioSpacing.m),
          _section('if', l10n.storyIf, [
            MapBuilderStoryConditions(
              key: ValueKey('map-story-conditions-${current.id}'),
              binding: binding,
              record: current,
              editable: editable,
            ),
          ]),
          const SizedBox(height: StudioSpacing.m),
          _section('then', l10n.storyThen, [
            MapBuilderStoryLineField(
              binding: binding,
              element: element,
              record: current,
              editable: editable,
              scenePicker: (label) => StudioSelect(
                key: const ValueKey('map-story-then'),
                label: label,
                value: current.sceneId ?? '',
                options: {
                  '': l10n.storySceneMissing,
                  if (current.sceneId != null &&
                      !scenes.any((scene) => scene.id == current.sceneId))
                    current.sceneId!: current.sceneId!,
                  for (final scene in scenes) scene.id: scene.name,
                },
                onChanged: editable
                    ? (value) => binding.setScene(
                        current,
                        value.isEmpty ? null : value,
                      )
                    : null,
              ),
            ),
            const SizedBox(height: StudioSpacing.m),
            MapBuilderStoryMilestoneField(
              key: ValueKey('map-story-milestone-${current.id}'),
              binding: binding,
              record: current,
              editable: editable,
            ),
          ]),
          const SizedBox(height: StudioSpacing.m),
          _section('repeat', l10n.storyAfter, [
            MapBuilderStoryAfter(
              binding: binding,
              record: current,
              editable: editable,
            ),
          ]),
          const SizedBox(height: StudioSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('map-story-simulate'),
              variant: StudioButtonVariant.secondary,
              icon: Icons.play_circle_outline,
              label: binding.simulating == current.id
                  ? l10n.simulationClose
                  : l10n.simulationOpen,
              onPressed: binding.ready
                  ? () => binding.toggleSimulation(current.id)
                  : null,
            ),
          ),
          if (binding.simulating == current.id)
            MapBuilderStorySimulation(binding: binding, record: current),
          const SizedBox(height: StudioSpacing.l),
          Align(
            alignment: Alignment.centerLeft,
            child: StudioButton(
              key: const ValueKey('map-story-behaviour-delete'),
              variant: StudioButtonVariant.destructive,
              icon: Icons.delete_outline,
              label: l10n.storyDeleteBehaviour,
              onPressed: editable
                  ? () => binding.deleteBehaviour(current)
                  : null,
            ),
          ),
        ],
      ],
    );
  }
}
