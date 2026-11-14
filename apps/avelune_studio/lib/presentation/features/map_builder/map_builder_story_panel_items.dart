part of 'map_builder_story_panel.dart';

class _Orphan extends StatelessWidget {
  const _Orphan({super.key, required this.behaviour, required this.binding});

  final NarrativeEventRecord behaviour;
  final MapBuilderStoryBinding binding;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final targets = binding.repairTargets;
    final enabled = binding.ready && !binding.publishing;
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            behaviour.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            l10n.storyRepairMissing,
            style: theme.textTheme.bodySmall?.copyWith(
              color: StudioTone.warning.color(context),
            ),
          ),
          const SizedBox(height: StudioSpacing.s),
          StudioSelect(
            key: ValueKey('map-story-orphan-reassign-${behaviour.id}'),
            label: l10n.storyReassign,
            value: null,
            options: {
              for (final element in targets)
                element.key: mapBuilderStoryName(element, l10n),
            },
            onChanged: enabled && targets.isNotEmpty
                ? (key) {
                    final element = targets
                        .where((element) => element.key == key)
                        .firstOrNull;
                    if (element != null) binding.reassign(behaviour, element);
                  }
                : null,
          ),
          const SizedBox(height: StudioSpacing.s),
          StudioButton(
            key: ValueKey('map-story-orphan-delete-${behaviour.id}'),
            label: l10n.storyRepairDelete,
            icon: Icons.delete_outline,
            variant: StudioButtonVariant.secondary,
            onPressed: enabled ? () => binding.deleteOrphan(behaviour) : null,
          ),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    super.key,
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.labelMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 14, color: theme.colorScheme.onSurfaceVariant),
          const SizedBox(width: StudioSpacing.s),
          Expanded(child: Text(label, style: style)),
          Text('$count', style: style),
        ],
      ),
    );
  }
}
