import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_connection_form.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_encounter_zone_form.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_movement_zone_form.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_obstacle_form.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_panel.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_story_inspector.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_spawn_form.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_warp_form.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

Widget? mapBuilderSpaceInspector(
  MapBuilderSpace space,
  MapBuilderGameplayBinding binding,
  MapBuilderAmbianceBinding ambiance,
  AppLocalizations l10n, {
  required bool enabled,
  MapBuilderStoryBinding? story,
}) => switch ((space, mapBuilderSpaceOutline(space, l10n))) {
  (MapBuilderSpace.gameplay, final outline?) => MapBuilderGameplayInspector(
    binding: binding,
    outline: outline,
    enabled: enabled,
  ),
  (MapBuilderSpace.story, final outline?) when story != null =>
    switch (story.selected) {
      final element? => MapBuilderStoryInspector(
        binding: story,
        element: element,
      ),
      null => MapBuilderSpaceInspectorBody(outline: outline, live: true),
    },
  (MapBuilderSpace.ambiance, _) when ambiance.maps.active != null =>
    MapBuilderAmbianceInspector(binding: ambiance, enabled: enabled),
  _ => null,
};

class MapBuilderGameplayInspector extends StatelessWidget {
  const MapBuilderGameplayInspector({
    super.key,
    required this.binding,
    required this.outline,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapBuilderSpaceOutline outline;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final map = binding.map;
    if (map == null || binding.maps.project == null) {
      return const SizedBox.shrink();
    }
    final warp = binding.selectedWarp;
    if (warp != null) {
      return MapBuilderWarpForm(
        key: ValueKey('warp-${map.id}-${warp.id}'),
        binding: binding,
        warp: warp,
        enabled: enabled,
      );
    }
    final obstacle = binding.selectedObstacle;
    if (obstacle != null) {
      return MapBuilderObstacleForm(
        key: ValueKey('obstacle-${map.id}-${obstacle.id}'),
        binding: binding,
        entity: obstacle,
        enabled: enabled,
      );
    }
    final instance = binding.selectedInstance;
    if (instance != null && binding.rubric == 'fieldObjects') {
      return MapBuilderInstanceObstacleForm(
        key: ValueKey('instance-${map.id}-${instance.id}'),
        binding: binding,
        instance: instance,
        enabled: enabled,
      );
    }
    final spawn = binding.selectedSpawn;
    if (spawn != null) {
      return MapBuilderSpawnForm(
        key: ValueKey('spawn-${map.id}-${spawn.id}'),
        binding: binding,
        spawn: spawn,
        enabled: enabled,
      );
    }
    final zone = binding.selectedZone;
    if (zone != null && mapBuilderMovementZoneKinds.contains(zone.kind)) {
      return MapBuilderMovementZoneForm(
        key: ValueKey('zone-${map.id}-${zone.id}'),
        binding: binding,
        zone: zone,
        enabled: enabled,
      );
    }
    if (zone != null && zone.kind == GameplayZoneKind.encounter) {
      return MapBuilderEncounterZoneForm(
        key: ValueKey('zone-${map.id}-${zone.id}'),
        binding: binding,
        zone: zone,
        enabled: enabled,
      );
    }
    final connection = binding.selectedConnection;
    if (connection != null || binding.draftingConnection) {
      return MapBuilderConnectionForm(
        key: ValueKey(
          'connection-${map.id}-${connection?.direction.name ?? 'new'}',
        ),
        binding: binding,
        enabled: enabled,
      );
    }
    if (binding.draftingWarp) {
      return _WarpPlacement(binding: binding, enabled: enabled);
    }
    if (binding.draftingObstacle case final kind?) {
      return MapBuilderObstaclePlacement(
        binding: binding,
        kind: kind,
        enabled: enabled,
        cancel: _CancelPlacement(binding: binding),
      );
    }
    if (binding.draftingZone) {
      return _Placement(
        placementKey: 'map-gameplay-zone-placement',
        eyebrow: binding.view()?.zoneKind == GameplayZoneKind.encounter
            ? context.l10n.encounterZoneEyebrow
            : context.l10n.movementZoneEyebrow,
        title: context.l10n.zoneNew,
        hint: context.l10n.zoneDrawHint,
        binding: binding,
      );
    }
    if (binding.tool == StudioMapTool.encounterPaint) {
      return _Placement(
        placementKey: 'map-gameplay-encounter-brush',
        eyebrow: context.l10n.encounterZoneEyebrow,
        title: context.l10n.encounterPaintNew,
        hint: context.l10n.encounterBrushHint,
        binding: binding,
      );
    }
    if (binding.tool == StudioMapTool.collisionPaint ||
        binding.tool == StudioMapTool.collisionErase) {
      return _Placement(
        placementKey: 'map-gameplay-collision-brush',
        eyebrow: outline.inspectorEyebrow,
        title: binding.tool == StudioMapTool.collisionPaint
            ? context.l10n.movementPaint
            : context.l10n.movementErase,
        hint: context.l10n.movementBrushHint,
        binding: binding,
      );
    }
    if (binding.draftingSpawn) {
      return _Placement(
        placementKey: 'map-gameplay-spawn-placement',
        eyebrow: context.l10n.spawnEyebrow,
        title: context.l10n.spawnNew,
        hint: context.l10n.spawnPlaceHint,
        binding: binding,
      );
    }
    return _Heading(
      eyebrow: outline.inspectorEyebrow,
      title: outline.inspectorTitle,
      hint: outline.inspectorHint,
    );
  }
}

class _WarpPlacement extends StatelessWidget {
  const _WarpPlacement({required this.binding, required this.enabled});

  final MapBuilderGameplayBinding binding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final destinations = binding.warps!.destinations();
    final chosen = binding.view()?.warpDestination?.id;
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('map-gameplay-warp-placement'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          eyebrow: l10n.warpBetweenMaps,
          title: l10n.warpNew,
          hint: binding.placingWarp ? l10n.warpPlaceClick : l10n.warpPlaceChoose,
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioSelect(
          key: const ValueKey('map-gameplay-warp-placement-target'),
          label: l10n.warpDestination,
          value: chosen,
          options: {for (final entry in destinations) entry.id: entry.name},
          onChanged: enabled
              ? (value) => binding.armWarp(
                  destinations.firstWhere((entry) => entry.id == value),
                )
              : null,
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioButton(
          key: const ValueKey('map-gameplay-arrival-placement'),
          label: l10n.warpPlaceArrivalInstead,
          icon: Icons.place_outlined,
          variant: StudioButtonVariant.secondary,
          onPressed: enabled ? binding.armArrival : null,
        ),
        const SizedBox(height: StudioSpacing.m),
        _CancelPlacement(binding: binding),
      ],
    );
  }
}

class _Placement extends StatelessWidget {
  const _Placement({
    required this.placementKey,
    required this.eyebrow,
    required this.title,
    required this.hint,
    required this.binding,
  });

  final String placementKey;
  final String eyebrow;
  final String title;
  final String hint;
  final MapBuilderGameplayBinding binding;

  @override
  Widget build(BuildContext context) => Column(
    key: ValueKey(placementKey),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _Heading(eyebrow: eyebrow, title: title, hint: hint),
      const SizedBox(height: StudioSpacing.l),
      _CancelPlacement(binding: binding),
    ],
  );
}

class _CancelPlacement extends StatelessWidget {
  const _CancelPlacement({required this.binding});

  final MapBuilderGameplayBinding binding;

  @override
  Widget build(BuildContext context) => StudioButton(
    key: const ValueKey('map-gameplay-placement-cancel'),
    label: context.l10n.cancel,
    icon: Icons.close,
    variant: StudioButtonVariant.secondary,
    onPressed: () {
      binding.leave();
      binding.changed();
    },
  );
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.eyebrow,
    required this.title,
    required this.hint,
  });

  final String eyebrow;
  final String title;
  final String hint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      key: const ValueKey('map-space-inspector'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: StudioSpacing.s),
        Text(
          hint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
