import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_connection_form.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_space_outline.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_warp_form.dart';

Widget? mapBuilderSpaceInspector(
  MapBuilderSpace space,
  MapBuilderGameplayBinding binding, {
  required bool enabled,
}) => switch ((space, mapBuilderSpaceOutline(space))) {
  (MapBuilderSpace.gameplay, final outline?) => MapBuilderGameplayInspector(
    binding: binding,
    outline: outline,
    enabled: enabled,
  ),
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
    return Column(
      key: const ValueKey('map-gameplay-warp-placement'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Heading(
          eyebrow: 'PASSAGE ENTRE CARTES',
          title: 'Nouveau passage',
          hint: binding.placingWarp
              ? 'Cliquez sur la case du passage, sur la carte.'
              : 'Choisissez la carte de destination, puis cliquez sur la '
                    'case du passage.',
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioSelect(
          key: const ValueKey('map-gameplay-warp-placement-target'),
          label: 'Destination',
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
          label: 'Placer plutôt un point d’arrivée',
          icon: Icons.place_outlined,
          variant: StudioButtonVariant.secondary,
          onPressed: enabled ? binding.armArrival : null,
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioButton(
          key: const ValueKey('map-gameplay-placement-cancel'),
          label: 'Annuler',
          icon: Icons.close,
          variant: StudioButtonVariant.secondary,
          onPressed: () {
            binding.leave();
            binding.changed();
          },
        ),
      ],
    );
  }
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
