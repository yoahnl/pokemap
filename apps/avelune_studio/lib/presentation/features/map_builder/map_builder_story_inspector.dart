import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/events/domain/event_record_view.dart';
import 'package:avelune_studio/features/map_workspace/application/map_story_elements.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
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
  });

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;

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
        if (binding.tab == MapStoryTab.behaviour)
          _Behaviours(binding: binding, element: element)
        else
          _Properties(binding: binding, element: element),
      ],
    );
  }
}

class _Behaviours extends StatelessWidget {
  const _Behaviours({required this.binding, required this.element});

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final behaviours = element.behaviours;
    final current = binding.selectedBehaviour;
    final scenes = binding.maps.project?.scenes ?? const <SceneAsset>[];
    return Column(
      key: const ValueKey('map-story-behaviours'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Eyebrow(l10n.storyBehavioursTitle(behaviours.length)),
        const SizedBox(height: StudioSpacing.s),
        if (behaviours.isEmpty)
          _Caption(l10n.storyNoBehaviour)
        else ...[
          for (final (index, record) in behaviours.indexed)
            StudioChoice(
              key: ValueKey('map-story-behaviour-$index'),
              dense: true,
              label: '${index + 1} · ${record.name}',
              subtitle: mapBuilderBehaviourState(record, l10n),
              selected: identical(record, current),
              onTap: () => binding.openBehaviour(index),
            ),
          if (current != null) ...[
            const SizedBox(height: StudioSpacing.l),
            _Fact(
              l10n.storyWhen,
              l10n.storyTrigger(current.source?.kind.name ?? 'none'),
              key: const ValueKey('map-story-when'),
            ),
            _Fact(
              l10n.storyIf,
              current.expression.leaves.isEmpty
                  ? l10n.storyAlways
                  : l10n.storyConditions(current.expression.leaves.length),
              key: const ValueKey('map-story-if'),
            ),
            _Fact(
              l10n.storyThen,
              scenes
                      .where((scene) => scene.id == current.sceneId)
                      .firstOrNull
                      ?.name ??
                  current.sceneId ??
                  l10n.storySceneMissing,
              key: const ValueKey('map-story-then'),
            ),
            _Fact(
              l10n.storyAfter,
              mapBuilderBehaviourAfter(current, l10n),
              key: const ValueKey('map-story-after'),
            ),
          ],
        ],
      ],
    );
  }
}

class _Properties extends StatelessWidget {
  const _Properties({required this.binding, required this.element});

  final MapBuilderStoryBinding binding;
  final MapStoryElement element;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final map = binding.map;
    final project = binding.maps.project;
    final position = element.position;
    final entity = element.target == MapStoryElementTarget.entity
        ? map?.entities.where((item) => item.id == element.id).firstOrNull
        : null;
    final npc = entity?.npc;
    final sign = entity?.sign;
    final area = element.area;
    String? characterName(String? id) => id == null
        ? null
        : project?.characters
                  .where((character) => character.id == id)
                  .firstOrNull
                  ?.name ??
              id;
    String? trainerName(String? id) => id == null
        ? null
        : project?.trainers
                  .where((trainer) => trainer.id == id)
                  .firstOrNull
                  ?.name ??
              id;
    if (element.kind == MapStoryElementKind.map) {
      return _Caption(l10n.storyMapProperties);
    }
    return Column(
      key: const ValueKey('map-story-properties'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Fact(l10n.storyName, element.name),
        if (position != null)
          _Fact(
            l10n.storyPositionLabel,
            l10n.storyPosition(position.x, position.y),
          ),
        if (area != null)
          _Fact(
            l10n.storyAreaLabel,
            l10n.storyAreaSize(area.size.width, area.size.height),
          ),
        if (npc != null) ...[
          _Fact(
            l10n.storyAppearance,
            characterName(npc.characterId) ?? l10n.storyNone,
          ),
          _Fact(l10n.storyFacing, l10n.storyFacingName(npc.facing.name)),
          _Fact(
            l10n.storyCollision,
            entity!.blocksMovement ? l10n.storyYes : l10n.storyNo,
          ),
          _Fact(
            l10n.storyMovement,
            l10n.storyMovementName(npc.movement.mode.name),
          ),
          _Fact(
            l10n.storyTrainer,
            trainerName(npc.trainerId) ?? l10n.storyNoTrainer,
          ),
        ],
        if (sign != null && sign.plainText.trim().isNotEmpty)
          _Fact(l10n.storySignText, sign.plainText.trim()),
      ],
    );
  }
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
