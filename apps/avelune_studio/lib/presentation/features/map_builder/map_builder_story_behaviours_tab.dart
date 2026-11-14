part of 'map_builder_story_inspector.dart';

class _Behaviours extends StatelessWidget {
  const _Behaviours({
    required this.binding,
    required this.element,
    required this.enabled,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final behaviours = element.behaviours;
    final current = binding.selectedBehaviour;
    final editable = enabled && !binding.publishing && binding.ready;
    final scenes = [...?binding.maps.project?.scenes]
      ..sort((a, b) => a.name.compareTo(b.name));
    return Column(
      key: const ValueKey('map-story-behaviours'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (binding.error case final error?) ...[
          StudioNotice(mapBuilderStoryError(error, l10n), isError: true),
          const SizedBox(height: StudioSpacing.m),
        ],
        if (!binding.ready) ...[
          _Caption(
            binding.preparing ? l10n.storyPreparing : l10n.storyNotPrepared,
          ),
          const SizedBox(height: StudioSpacing.m),
        ],
        _Eyebrow(l10n.storyBehavioursTitle(behaviours.length)),
        const SizedBox(height: StudioSpacing.s),
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
            onPressed: editable ? () => binding.addBehaviour(element) : null,
          ),
        ),
        if (current != null) ...[
          const SizedBox(height: StudioSpacing.l),
          MapBuilderNameField(
            key: ValueKey('map-story-behaviour-name-${current.id}'),
            value: current.name,
            label: l10n.storyBehaviourNameField,
            enabled: editable,
            onCommit: (name) => binding.renameBehaviour(current, name),
          ),
          StudioToggleRow(
            key: const ValueKey('map-story-behaviour-active'),
            label: l10n.storyBehaviourActive,
            value: current.enabledOrNull == true,
            onChanged: editable
                ? (value) => binding.setActive(current, value)
                : null,
          ),
          const SizedBox(height: StudioSpacing.s),
          _Eyebrow(l10n.storyWhen),
          const SizedBox(height: StudioSpacing.xs),
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
          const SizedBox(height: StudioSpacing.m),
          _Eyebrow(l10n.storyIf),
          const SizedBox(height: StudioSpacing.xs),
          MapBuilderStoryConditions(
            key: ValueKey('map-story-conditions-${current.id}'),
            binding: binding,
            record: current,
            editable: editable,
          ),
          const SizedBox(height: StudioSpacing.m),
          _Eyebrow(l10n.storyThen),
          const SizedBox(height: StudioSpacing.xs),
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
                  ? (value) =>
                        binding.setScene(current, value.isEmpty ? null : value)
                  : null,
            ),
          ),
          const SizedBox(height: StudioSpacing.m),
          _Eyebrow(l10n.storyAfter),
          const SizedBox(height: StudioSpacing.xs),
          MapBuilderStoryAfter(
            binding: binding,
            record: current,
            editable: editable,
          ),
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
