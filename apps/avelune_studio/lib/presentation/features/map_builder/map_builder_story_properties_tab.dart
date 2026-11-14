part of 'map_builder_story_inspector.dart';

class _Properties extends StatelessWidget {
  const _Properties({
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
    final project = binding.maps.project;
    final position = element.position;
    final entity = binding.entityOf(element);
    final npc = entity?.npc;
    final sign = entity?.sign;
    final area = element.area;
    final editable =
        enabled &&
        (element.target == MapStoryElementTarget.entity ||
            element.target == MapStoryElementTarget.trigger);
    if (element.kind == MapStoryElementKind.map) {
      return _Caption(l10n.storyMapProperties);
    }
    int? number(String text) => int.tryParse(text.trim());
    final trainers = [...?project?.trainers]
      ..sort((a, b) => a.name.compareTo(b.name));
    final character = npc?.characterId == null
        ? null
        : project?.characters
                  .where((entry) => entry.id == npc!.characterId)
                  .firstOrNull
                  ?.name ??
              npc!.characterId;
    return Column(
      key: ValueKey('map-story-properties-${element.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (binding.error case final error?) ...[
          StudioNotice(mapBuilderStoryError(error, l10n), isError: true),
          const SizedBox(height: StudioSpacing.m),
        ],
        if (editable)
          MapBuilderNameField(
            key: const ValueKey('map-story-name'),
            value: element.name,
            label: l10n.storyNameField,
            enabled: enabled,
            onCommit: (name) => binding.rename(element, name),
          )
        else
          _Fact(l10n.storyName, element.name),
        const SizedBox(height: StudioSpacing.m),
        if (position != null && editable)
          _Pair(
            first: MapBuilderNameField(
              key: const ValueKey('map-story-x'),
              value: '${position.x}',
              label: 'X',
              enabled: enabled,
              onCommit: (text) => switch (number(text)) {
                final x? => binding.moveTo(
                  element,
                  GridPos(x: x, y: position.y),
                ),
                null => null,
              },
            ),
            second: MapBuilderNameField(
              key: const ValueKey('map-story-y'),
              value: '${position.y}',
              label: 'Y',
              enabled: enabled,
              onCommit: (text) => switch (number(text)) {
                final y? => binding.moveTo(
                  element,
                  GridPos(x: position.x, y: y),
                ),
                null => null,
              },
            ),
          )
        else if (position != null)
          _Fact(
            l10n.storyPositionLabel,
            l10n.storyPosition(position.x, position.y),
          ),
        if (area != null && editable)
          _Pair(
            first: MapBuilderNameField(
              key: const ValueKey('map-story-width'),
              value: '${area.size.width}',
              label: l10n.storyWidth,
              enabled: enabled,
              onCommit: (text) => switch (number(text)) {
                final width? => binding.resize(
                  element,
                  GridSize(width: width, height: area.size.height),
                ),
                null => null,
              },
            ),
            second: MapBuilderNameField(
              key: const ValueKey('map-story-height'),
              value: '${area.size.height}',
              label: l10n.storyHeight,
              enabled: enabled,
              onCommit: (text) => switch (number(text)) {
                final height? => binding.resize(
                  element,
                  GridSize(width: area.size.width, height: height),
                ),
                null => null,
              },
            ),
          ),
        if (npc != null) ...[
          if (binding.characters.isNotEmpty)
            StudioSelect(
              key: const ValueKey('map-story-appearance'),
              label: l10n.storyAppearanceField,
              value: npc.characterId ?? '',
              options: {
                if (npc.characterId == null) '': l10n.storyNone,
                if (npc.characterId != null &&
                    !binding.characters.any(
                      (entry) => entry.id == npc.characterId,
                    ))
                  npc.characterId!: character!,
                for (final entry in binding.characters) entry.id: entry.name,
              },
              onChanged: enabled
                  ? (value) => switch (binding.characters
                        .where((entry) => entry.id == value)
                        .firstOrNull) {
                      final entry? => binding.setCharacter(element, entry),
                      null => null,
                    }
                  : null,
            )
          else ...[
            _Fact(l10n.storyAppearance, character ?? l10n.storyNone),
            if (enabled)
              Align(
                alignment: Alignment.centerLeft,
                child: StudioButton(
                  key: const ValueKey('map-story-load-characters'),
                  variant: StudioButtonVariant.quiet,
                  label: binding.charactersLoading
                      ? l10n.storyCharactersLoading
                      : l10n.storyChangeAppearance,
                  onPressed: binding.charactersLoading
                      ? null
                      : binding.loadCharacters,
                ),
              ),
          ],
          const SizedBox(height: StudioSpacing.m),
          StudioSelect(
            key: const ValueKey('map-story-facing'),
            label: l10n.storyFacingField,
            value: npc.facing.name,
            options: {
              for (final facing in const [
                EntityFacing.north,
                EntityFacing.east,
                EntityFacing.south,
                EntityFacing.west,
              ])
                facing.name: l10n.storyFacingName(facing.name),
            },
            onChanged: enabled
                ? (value) => binding.setFacing(
                    element,
                    EntityFacing.values.byName(value),
                  )
                : null,
          ),
          const SizedBox(height: StudioSpacing.s),
          StudioToggleRow(
            key: const ValueKey('map-story-blocks'),
            label: l10n.storyCollisionField,
            value: entity!.blocksMovement,
            onChanged: enabled
                ? (value) => binding.setBlocks(element, value)
                : null,
          ),
          StudioSelect(
            key: const ValueKey('map-story-movement'),
            label: l10n.storyMovementField,
            value: npc.movement.mode.name,
            options: {
              for (final mode in MapEntityNpcMovementMode.values)
                if (mode != MapEntityNpcMovementMode.fixedRoute ||
                    npc.movement.mode == mode)
                  mode.name: l10n.storyMovementName(mode.name),
            },
            onChanged: enabled
                ? (value) => binding.setMovement(
                    element,
                    MapEntityNpcMovementMode.values.byName(value),
                  )
                : null,
          ),
          const SizedBox(height: StudioSpacing.m),
          StudioSelect(
            key: const ValueKey('map-story-trainer'),
            label: l10n.storyTrainerField,
            value: npc.trainerId ?? '',
            options: {
              '': l10n.storyTrainerNone,
              if (npc.trainerId != null &&
                  !trainers.any((trainer) => trainer.id == npc.trainerId))
                npc.trainerId!: npc.trainerId!,
              for (final trainer in trainers) trainer.id: trainer.name,
            },
            onChanged: enabled
                ? (value) =>
                      binding.setTrainer(element, value.isEmpty ? null : value)
                : null,
          ),
          const SizedBox(height: StudioSpacing.xs),
          _Caption(l10n.storyTrainerHint),
        ],
        if (sign != null)
          MapBuilderNameField(
            key: const ValueKey('map-story-sign-text'),
            value: sign.plainText,
            label: l10n.storySignTextField,
            enabled: enabled,
            lines: 3,
            onCommit: (text) => binding.setSignText(element, text),
          ),
      ],
    );
  }
}
