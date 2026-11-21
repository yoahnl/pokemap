part of 'project_character_animation_editor.dart';

extension _CharacterTimeline on _ProjectCharacterAnimationEditorState {
  Widget _timeline(
    BuildContext context,
    ProjectCharacterEntry character,
    ProjectRegularAtlasTilesetSource? atlas,
  ) {
    final poses = _poses;
    final elapsed = <int>[];
    var duration = 0;
    for (final pose in poses) {
      elapsed.add(duration);
      duration += pose.durationMs;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Séquence',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            Text(
              '$duration ms au total',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (atlas != null && poses.length < 24) ...[
              const SizedBox(width: StudioSpacing.m),
              StudioTool(
                label: 'Ajouter une pose',
                icon: Icons.add,
                onPressed: widget.enabled
                    ? () => _choosePose(poses.length, atlas)
                    : null,
              ),
            ],
          ],
        ),
        const SizedBox(height: StudioSpacing.m),
        SizedBox(
          height: 94,
          child: Scrollbar(
            controller: _timelineScroll,
            thumbVisibility: true,
            child: ListView.separated(
              controller: _timelineScroll,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(bottom: StudioSpacing.l),
              itemCount: poses.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: StudioSpacing.s),
              itemBuilder: (context, index) => _PoseCard(
                key: ValueKey('character-pose-$index'),
                index: index,
                duration: poses[index].durationMs,
                selected: _position == index,
                preview: _poseThumbnail(character, elapsed[index]),
                onTap: widget.enabled ? () => _selectPose(index) : null,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _poseThumbnail(ProjectCharacterEntry character, int elapsed) {
    const size = 42.0;
    final visuals = widget.visuals;
    if (visuals is ScopedResourcePreviewVisuals) {
      return (visuals as ScopedResourcePreviewVisuals).scopedResourcePreview(
        CharacterPreviewSource(
          character,
          facing: _facing,
          animationState: _state,
          elapsedMs: elapsed,
        ),
        widget.project,
        size: size,
      );
    }
    return const Icon(Icons.person_outline, size: size);
  }

  Widget _poseActions() => StudioContextMenuButton(
    tooltip: 'Actions de la pose',
    items: () => [
      StudioContextMenuEntry(
        label: 'Déplacer vers la gauche',
        icon: Icons.arrow_back,
        onSelected: widget.enabled && _position > 0
            ? () => _movePose(-1)
            : null,
      ),
      StudioContextMenuEntry(
        label: 'Déplacer vers la droite',
        icon: Icons.arrow_forward,
        onSelected: widget.enabled && _position + 1 < _poses.length
            ? () => _movePose(1)
            : null,
      ),
      const StudioContextMenuSeparator(),
      StudioContextMenuEntry(
        label: 'Retirer de la séquence',
        icon: Icons.remove_circle_outline,
        destructive: true,
        onSelected: widget.enabled ? _removePose : null,
      ),
    ],
  );

  void _movePose(int shift) => _change(() {
    final poses = _poses.toList();
    final pose = poses.removeAt(_position);
    _position += shift;
    poses.insert(_position, pose);
    _replacePoses(poses);
  });

  void _removePose() => _change(() {
    final poses = _poses.toList()..removeAt(_position);
    _position = _position.clamp(0, poses.isEmpty ? 0 : poses.length - 1);
    _replacePoses(poses);
  });
}

class _PoseCard extends StatelessWidget {
  const _PoseCard({
    super.key,
    required this.index,
    required this.duration,
    required this.selected,
    required this.preview,
    required this.onTap,
  });

  final int index;
  final int duration;
  final bool selected;
  final Widget preview;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final radius = BorderRadius.circular(StudioMetrics.controlRadius);
    return Semantics(
      label: 'Pose ${index + 1}, $duration millisecondes',
      selected: selected,
      button: true,
      enabled: onTap != null,
      child: Material(
        color: selected ? colors.primaryContainer : colors.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: selected ? colors.primary : colors.outlineVariant,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: ExcludeSemantics(
            child: SizedBox(
              width: 86,
              child: Padding(
                padding: const EdgeInsets.all(StudioSpacing.xs),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(child: Center(child: preview)),
                    Text(
                      '${index + 1}  ·  $duration ms',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
