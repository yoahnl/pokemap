import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
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

class MapBuilderAmbianceInspector extends StatelessWidget {
  const MapBuilderAmbianceInspector({
    super.key,
    required this.binding,
    required this.enabled,
  });

  final MapBuilderAmbianceBinding binding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final editing = binding.editing;
    return Column(
      key: const ValueKey('map-ambiance-inspector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.ambianceInspectorEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          l10n.ambianceDayNight,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        if (!binding.spatial)
          StudioNotice(l10n.ambiance2dOnly)
        else if (binding.error case final error?)
          StudioNotice(error, isError: true)
        else if (editing == null)
          Text(l10n.ambianceLoading, style: muted)
        else
          ..._dayNight(context, editing, muted),
      ],
    );
  }

  List<Widget> _dayNight(
    BuildContext context,
    SpatialVisualEditing editing,
    TextStyle? muted,
  ) {
    final l10n = context.l10n;
    final source = editing.mapTimeSource;
    final minute = editing.mapMinuteOfDay;
    void choose(MapTimeSource value) =>
        binding.editing?.setMapTimeSource(value);
    void at(int value) => binding.editing?.setMapMinuteOfDay(value);
    return [
      Text(
        mapBuilderProjectClock(
          binding.inherited,
          binding.maps.active?.current.spatialScene?.dayNightCycle,
          l10n,
        ),
        key: const ValueKey('map-ambiance-project-clock'),
        style: muted,
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
        const SizedBox(height: StudioSpacing.s),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          children: [
            for (final (label, value) in [
              (l10n.dayNightDawn, 6 * 60),
              (l10n.dayNightNoon, 12 * 60),
              (l10n.dayNightDusk, 19 * 60),
              (l10n.dayNightNight, 23 * 60),
            ])
              ChoiceChip(
                key: ValueKey('map-ambiance-time-preset-$value'),
                label: Text(label),
                selected: minute == value,
                onSelected: enabled ? (_) => at(value) : null,
              ),
          ],
        ),
      ],
    ];
  }
}
