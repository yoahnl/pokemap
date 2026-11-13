import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_panel.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

String mapBuilderBehaviourAfter(
  NarrativeEventRecord record,
  AppLocalizations l10n,
) => switch ((record.reusePolicy, record.resetPolicy)) {
  (null, _) => l10n.storyReuseUnset,
  (NarrativeEventReusePolicy.reusable, _) => l10n.storyEachTime,
  (_, NarrativeEventResetOnMapReentry()) => l10n.storyOncePerVisit,
  (_, NarrativeEventResetOnOutcomeReceived()) => l10n.storyOnceUntilOutcome,
  _ => l10n.storyOnce,
};

String mapBuilderBehaviourState(
  NarrativeEventRecord record,
  AppLocalizations l10n,
) => switch (record.enabledOrNull) {
  null => l10n.storyDraft,
  true => l10n.storyActive,
  false => l10n.storyDisabled,
};

class MapBuilderStoryInspector extends StatelessWidget {
  const MapBuilderStoryInspector({
    super.key,
    required this.binding,
    required this.element,
    this.enabled = true,
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final position = element.position;
    final mapName = binding.map?.name ?? '';
    return Column(
      key: ValueKey('map-story-inspector-${element.key}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(l10n.storyKindEyebrow(element.kind.name)),
        const SizedBox(height: StudioSpacing.xs),
        Row(
          children: [
            Icon(mapBuilderStoryIcon(element.kind), size: 18),
            const SizedBox(width: StudioSpacing.s),
            Expanded(
              child: Text(
                mapBuilderStoryName(element, l10n),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        Text(
          position == null
              ? mapName
              : '$mapName · ${l10n.storyPosition(position.x, position.y)}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: muted,
        ),
        const SizedBox(height: StudioSpacing.l),
        SegmentedButton<MapStoryTab>(
          key: const ValueKey('map-story-tabs'),
          showSelectedIcon: false,
          segments: [
            ButtonSegment(
              value: MapStoryTab.behaviour,
              label: Text(l10n.storyTabBehaviour),
            ),
            ButtonSegment(
              value: MapStoryTab.properties,
              label: Text(l10n.storyTabProperties),
            ),
          ],
          selected: {binding.tab},
          onSelectionChanged: (value) => binding.openTab(value.single),
        ),
        const SizedBox(height: StudioSpacing.l),
        KeyedSubtree(
          key: ValueKey('map-story-attempt-${binding.attempts}'),
          child: binding.tab == MapStoryTab.behaviour
              ? _Behaviours(
                  binding: binding,
                  element: element,
                  enabled: enabled,
                )
              : _Properties(
                  binding: binding,
                  element: element,
                  enabled: enabled,
                ),
        ),
      ],
    );
  }
}

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
          StudioNotice(_storyError(error, l10n), isError: true),
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
        for (final (index, record) in behaviours.indexed)
          StudioChoice(
            key: ValueKey('map-story-behaviour-$index'),
            dense: true,
            label: '${index + 1} · ${record.name}',
            subtitle: mapBuilderBehaviourState(record, l10n),
            selected: identical(record, current),
            onTap: () => binding.openBehaviour(index),
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
          StudioSelect(
            key: const ValueKey('map-story-when'),
            label: l10n.storyWhenField,
            value: current.source?.kind.name ?? '',
            options: {
              if (current.source == null) '': l10n.storyTrigger('none'),
              for (final kind in binding.triggerKinds(element))
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
          _Fact(
            l10n.storyIf,
            current.expression.leaves.isEmpty
                ? l10n.storyAlways
                : l10n.storyConditions(current.expression.leaves.length),
            key: const ValueKey('map-story-if'),
          ),
          StudioSelect(
            key: const ValueKey('map-story-then'),
            label: l10n.storyThenField,
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
          const SizedBox(height: StudioSpacing.m),
          StudioSelect(
            key: const ValueKey('map-story-after'),
            label: l10n.storyAfterField,
            value: _after(current)?.name ?? '',
            options: {
              if (_after(current) == null) '': l10n.storyReuseUnset,
              MapStoryAfter.once.name: l10n.storyOnce,
              MapStoryAfter.eachTime.name: l10n.storyEachTime,
              MapStoryAfter.oncePerVisit.name: l10n.storyOncePerVisit,
            },
            onChanged: editable
                ? (value) => binding.setAfter(
                    current,
                    MapStoryAfter.values.byName(value),
                  )
                : null,
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

  MapStoryAfter? _after(NarrativeEventRecord record) =>
      switch ((record.reusePolicy, record.resetPolicy)) {
        (null, _) => null,
        (NarrativeEventReusePolicy.reusable, _) => MapStoryAfter.eachTime,
        (_, NarrativeEventResetOnMapReentry()) => MapStoryAfter.oncePerVisit,
        (_, NarrativeEventResetNever()) => MapStoryAfter.once,
        _ => null,
      };
}

String _storyError(String error, AppLocalizations l10n) => switch (error) {
  MapBuilderStoryBinding.outOfMap => l10n.storyOutOfMap,
  'publish-unavailable' => l10n.storyPublishUnavailable,
  _ when error.startsWith(MapBuilderStoryBinding.deactivated) =>
    '${l10n.storyDeactivated} ${error.substring(MapBuilderStoryBinding.deactivated.length)}'
        .trim(),
  _ => error,
};

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
          StudioNotice(_storyError(error, l10n), isError: true),
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

class _Pair extends StatelessWidget {
  const _Pair({required this.first, required this.second});

  final Widget first;
  final Widget second;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: StudioSpacing.m),
    child: Row(
      children: [
        Expanded(child: first),
        const SizedBox(width: StudioSpacing.m),
        Expanded(child: second),
      ],
    ),
  );
}

class _Fact extends StatelessWidget {
  const _Fact(this.label, this.value, {super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: StudioSpacing.m),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Eyebrow(label),
          const SizedBox(height: StudioSpacing.xxs),
          Text(value, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _Caption extends StatelessWidget {
  const _Caption(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      style: theme.textTheme.bodySmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Text(
      text,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: theme.textTheme.labelSmall?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
        letterSpacing: 1,
      ),
    );
  }
}
