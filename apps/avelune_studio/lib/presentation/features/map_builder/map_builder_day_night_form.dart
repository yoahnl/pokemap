import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_tile_grid.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

String mapBuilderClock(int minute) =>
    '${(minute ~/ 60).toString().padLeft(2, '0')}:'
    '${(minute % 60).toString().padLeft(2, '0')}';

String mapBuilderProjectClock(
  SpatialVisualPatch project,
  SpatialDayNightCycle? scene,
  AppLocalizations l10n,
) {
  final mode =
      project.choice(SpatialVisualParameter.timeMode) ??
      (project.enabled(SpatialVisualParameter.dayNightEnabled) == true ||
              scene != null
          ? WorldTimeMode.cycle.name
          : null);
  final start =
      project.number(SpatialVisualParameter.minuteOfDay)?.round() ??
      scene?.startMinuteOfDay ??
      720;
  final duration =
      project.number(SpatialVisualParameter.dayDurationSeconds) ??
      scene?.durationSeconds ??
      1200;
  if (mode == WorldTimeMode.real.name) return l10n.dayNightProjectReal;
  if (mode == WorldTimeMode.fixed.name) {
    return l10n.dayNightProjectFixed(mapBuilderClock(start % 1440));
  }
  if (mode == WorldTimeMode.cycle.name) {
    final minutes = duration / 60;
    return l10n.dayNightProjectCycle(
      minutes == minutes.roundToDouble()
          ? '${minutes.round()}'
          : minutes.toStringAsFixed(1),
    );
  }
  return l10n.dayNightProjectOff;
}

class MapBuilderDayNightForm extends StatelessWidget {
  const MapBuilderDayNightForm({
    super.key,
    required this.binding,
    required this.editing,
    required this.enabled,
  });

  final MapBuilderAmbianceBinding binding;
  final SpatialVisualEditing editing;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final source = editing.mapTimeSource;
    final minute = editing.mapMinuteOfDay;
    void choose(MapTimeSource value) =>
        binding.editing?.setMapTimeSource(value);
    void at(int value) => binding.editing?.setMapMinuteOfDay(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mapBuilderProjectClock(
            binding.inherited,
            binding.maps.active?.current.spatialScene?.dayNightCycle,
            l10n,
          ),
          key: const ValueKey('map-ambiance-project-clock'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (source == MapTimeSource.custom) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(l10n.dayNightCustom),
        ],
        const SizedBox(height: StudioSpacing.m),
        StudioChoice(
          key: const ValueKey('map-ambiance-time-inherit'),
          leading: const Icon(Icons.public, size: 18),
          label: l10n.dayNightInherit,
          selected: source == MapTimeSource.inherit,
          onTap: enabled ? () => choose(MapTimeSource.inherit) : null,
        ),
        StudioChoice(
          key: const ValueKey('map-ambiance-time-fixed'),
          leading: const Icon(Icons.schedule, size: 18),
          label: l10n.dayNightFixed,
          subtitle: l10n.dayNightFixedHint,
          selected: source == MapTimeSource.fixed,
          onTap: enabled ? () => choose(MapTimeSource.fixed) : null,
        ),
        if (source == MapTimeSource.fixed) ...[
          const SizedBox(height: StudioSpacing.l),
          MapBuilderTileGrid<int>(
            columns: 2,
            tiles: [
              for (final (label, icon, value) in [
                (l10n.dayNightDawn, Icons.wb_twilight, 6 * 60),
                (l10n.dayNightNoon, Icons.wb_sunny_outlined, 12 * 60),
                (l10n.dayNightDusk, Icons.nights_stay_outlined, 19 * 60),
                (l10n.dayNightNight, Icons.dark_mode_outlined, 23 * 60),
              ])
                MapBuilderTile(
                  value: value,
                  icon: icon,
                  label: label,
                  key: ValueKey('map-ambiance-time-preset-$value'),
                ),
            ],
            selected: minute,
            onSelected: enabled ? at : null,
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSlider(
            key: const ValueKey('map-ambiance-time-hour'),
            label: l10n.dayNightHour,
            value: (minute ~/ 15 * 15).toDouble(),
            max: 1425,
            divisions: 95,
            valueLabel: mapBuilderClock(minute),
            onChangeStart: enabled ? (_) => binding.beginGesture() : null,
            onChangeEnd: enabled ? (_) => binding.endGesture() : null,
            onChanged: enabled ? (value) => at(value.round()) : null,
          ),
        ],
      ],
    );
  }
}
