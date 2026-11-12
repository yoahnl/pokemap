import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_tile_grid.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const mapBuilderWeatherKinds = [
  (SpatialWeatherKind.clear, Icons.wb_sunny_outlined),
  (SpatialWeatherKind.partlyCloudy, Icons.wb_cloudy_outlined),
  (SpatialWeatherKind.cloudy, Icons.cloud_outlined),
  (SpatialWeatherKind.windy, Icons.air),
  (SpatialWeatherKind.mist, Icons.blur_on),
  (SpatialWeatherKind.fog, Icons.foggy),
  (SpatialWeatherKind.drizzle, Icons.grain),
  (SpatialWeatherKind.rain, Icons.water_drop_outlined),
  (SpatialWeatherKind.downpour, Icons.umbrella_outlined),
  (SpatialWeatherKind.storm, Icons.thunderstorm_outlined),
  (SpatialWeatherKind.tempest, Icons.cyclone),
  (SpatialWeatherKind.snow, Icons.ac_unit),
  (SpatialWeatherKind.heavySnow, Icons.snowing),
  (SpatialWeatherKind.sleet, Icons.cloudy_snowing),
  (SpatialWeatherKind.blizzard, Icons.severe_cold),
  (SpatialWeatherKind.hail, Icons.scatter_plot_outlined),
  (SpatialWeatherKind.dust, Icons.blur_circular),
  (SpatialWeatherKind.sandstorm, Icons.tornado),
  (SpatialWeatherKind.petals, Icons.local_florist_outlined),
  (SpatialWeatherKind.leaves, Icons.eco_outlined),
];

const _stormy = {
  SpatialWeatherKind.drizzle,
  SpatialWeatherKind.rain,
  SpatialWeatherKind.downpour,
  SpatialWeatherKind.storm,
  SpatialWeatherKind.tempest,
};

String mapBuilderProjectWeather(
  SpatialVisualPatch project,
  AppLocalizations l10n,
) {
  final mode = project.choice(SpatialVisualParameter.weatherMode);
  if (mode == WorldWeatherMode.real.name) return l10n.weatherProjectReal;
  if (mode == WorldWeatherMode.automatic.name) {
    return l10n.weatherProjectAutomatic;
  }
  if (mode == WorldWeatherMode.occasional.name) {
    return l10n.weatherProjectOccasional;
  }
  final kind = project.choice(SpatialVisualParameter.weatherKind);
  if (project.enabled(SpatialVisualParameter.weatherEnabled) != true ||
      kind == null ||
      kind == SpatialWeatherKind.clear.name) {
    return l10n.weatherProjectClear;
  }
  return l10n.weatherProjectFixed(l10n.weatherKindName(kind));
}

class MapBuilderWeatherForm extends StatelessWidget {
  const MapBuilderWeatherForm({
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
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final source = editing.mapWeatherSource;
    final fixed = source == 'fixed' || source == 'clear';
    final kind = source == 'clear'
        ? SpatialWeatherKind.clear
        : SpatialWeatherKind.parse(
            editing.effective.choice(SpatialVisualParameter.weatherKind) ??
                SpatialWeatherKind.rain.name,
          );
    SpatialVisualEditing? current() => binding.editing;
    void pick(SpatialWeatherKind value) => value == SpatialWeatherKind.clear
        ? current()?.setMapWeatherSource('clear')
        : current()?.selectWeather(value);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          mapBuilderProjectWeather(binding.inherited, l10n),
          key: const ValueKey('map-ambiance-project-weather'),
          style: muted,
        ),
        if (source == 'custom') ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(l10n.weatherCustom),
        ],
        const SizedBox(height: StudioSpacing.m),
        StudioChoice(
          key: const ValueKey('map-ambiance-weather-inherit'),
          leading: const Icon(Icons.public, size: 18),
          label: l10n.weatherInherit,
          selected: source == 'inherit',
          onTap: enabled
              ? () => current()?.setMapWeatherSource('inherit')
              : null,
        ),
        StudioChoice(
          key: const ValueKey('map-ambiance-weather-fixed'),
          leading: const Icon(Icons.cloud_outlined, size: 18),
          label: l10n.weatherFixed,
          subtitle: l10n.weatherFixedHint,
          selected: fixed,
          onTap: enabled
              ? () {
                  if (!fixed) current()?.setMapWeatherSource('fixed');
                }
              : null,
        ),
        if (fixed) ...[
          const SizedBox(height: StudioSpacing.l),
          MapBuilderTileGrid<SpatialWeatherKind>(
            tiles: [
              for (final (value, icon) in mapBuilderWeatherKinds)
                MapBuilderTile(
                  value: value,
                  icon: icon,
                  label: l10n.weatherKindName(value.name),
                  key: ValueKey('map-ambiance-weather-kind-${value.name}'),
                ),
            ],
            selected: kind,
            onSelected: enabled ? pick : null,
          ),
          if (kind != SpatialWeatherKind.clear) ...[
            const SizedBox(height: StudioSpacing.l),
            StudioSlider(
              key: const ValueKey('map-ambiance-weather-intensity'),
              label: l10n.weatherIntensity,
              value: editing.number(SpatialVisualParameter.weatherIntensity),
              onChangeStart: enabled ? (_) => binding.beginGesture() : null,
              onChangeEnd: enabled ? (_) => binding.endGesture() : null,
              onChanged: enabled
                  ? (value) => current()?.change(
                      SpatialVisualParameter.weatherIntensity,
                      value,
                    )
                  : null,
            ),
            if (_stormy.contains(kind))
              StudioToggleRow(
                key: const ValueKey('map-ambiance-weather-lightning'),
                label: l10n.weatherLightning,
                value: editing.flag(SpatialVisualParameter.weatherLightning),
                onChanged: enabled
                    ? (value) => current()?.change(
                        SpatialVisualParameter.weatherLightning,
                        value,
                      )
                    : null,
              ),
            StudioToggleRow(
              key: const ValueKey('map-ambiance-weather-sound'),
              label: l10n.weatherSound,
              value: editing.flag(SpatialVisualParameter.weatherSoundEnabled),
              onChanged: enabled
                  ? (value) => current()?.change(
                      SpatialVisualParameter.weatherSoundEnabled,
                      value,
                    )
                  : null,
            ),
          ],
          const SizedBox(height: StudioSpacing.m),
          Text(l10n.weatherPreviewHint, style: muted),
        ],
      ],
    );
  }
}
