import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import '../../theme/studio_tokens.dart';
import '../../shared/widgets/inputs/studio_select.dart';
import '../../shared/widgets/inputs/studio_slider.dart';
import '../../shared/widgets/inputs/studio_toggle_row.dart';
import '../../shared/widgets/layout/studio_panel.dart';
import '../project_settings/spatial_visual_controls.dart';

class MapWeatherControls extends StatelessWidget {
  const MapWeatherControls({
    super.key,
    required this.patch,
    required this.inherited,
    required this.onChanged,
    this.onEditStart,
    this.onEditEnd,
  });
  final SpatialVisualPatch patch, inherited;
  final ValueChanged<SpatialVisualPatch>? onChanged;
  final VoidCallback? onEditStart, onEditEnd;
  SpatialVisualPatch get effective => inherited.overriddenBy(patch);
  String get source =>
      patch.choice(SpatialVisualParameter.weatherMode) == 'fixed'
      ? patch.choice(SpatialVisualParameter.weatherKind) == 'clear' ||
                patch.enabled(SpatialVisualParameter.weatherEnabled) == false
            ? 'clear'
            : 'fixed'
      : patch.values.keys.any((p) => p.isWeather)
      ? 'custom'
      : 'inherit';
  void setSource(String value) {
    var next = SpatialVisualPatch({
      for (final entry in patch.values.entries)
        if (!entry.key.isWeather) entry.key: entry.value,
    });
    if (value != 'inherit') {
      final currentKind = effective.choice(SpatialVisualParameter.weatherKind);
      next = next
          .set(SpatialVisualParameter.weatherMode, 'fixed')
          .set(SpatialVisualParameter.weatherEnabled, value != 'clear')
          .set(
            SpatialVisualParameter.weatherKind,
            value == 'clear'
                ? 'clear'
                : currentKind == null || currentKind == 'clear'
                ? 'rain'
                : currentKind,
          );
      if (value != 'clear') {
        next = next.set(
          SpatialVisualParameter.weatherIntensity,
          effective.number(SpatialVisualParameter.weatherIntensity) ?? .7,
        );
      }
    }
    onChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) => StudioPanel(
    title: 'Météo du lieu',
    icon: Icons.cloud_outlined,
    accent: StudioAccent.water,
    children: [
      StudioSelect(
        key: const ValueKey('map-weather-source'),
        label: 'Sur cette carte',
        value: source,
        options: {
          'inherit': 'Suivre la météo du projet',
          'fixed': 'Forcer une météo',
          'clear': 'Forcer un ciel dégagé',
          if (source == 'custom') 'custom': 'Réglage local personnalisé',
        },
        onChanged: onChanged == null ? null : setSource,
      ),
      if (source == 'fixed') ...[
        StudioSelect(
          key: const ValueKey('map-weather-kind'),
          label: 'Météo imposée',
          value: effective.choice(SpatialVisualParameter.weatherKind) ?? 'rain',
          options: {
            for (final preset in SpatialVisualControls.weatherPresets)
              if (preset.$1 != SpatialWeatherKind.clear)
                preset.$1.name: preset.$2,
          },
          onChanged: onChanged == null
              ? null
              : (kind) => onChanged!(
                  patch.set(SpatialVisualParameter.weatherKind, kind),
                ),
        ),
        StudioSlider(
          key: const ValueKey('map-weather-intensity'),
          label: 'Intensité',
          min: 0,
          max: 1,
          value:
              effective.number(SpatialVisualParameter.weatherIntensity) ?? .7,
          onChangeStart: onEditStart == null ? null : (_) => onEditStart!(),
          onChangeEnd: onEditEnd == null ? null : (_) => onEditEnd!(),
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(
                  patch.set(SpatialVisualParameter.weatherIntensity, value),
                ),
        ),
        StudioToggleRow(
          label: 'Éclairs dans le ciel',
          icon: Icons.bolt_outlined,
          accent: StudioAccent.daylight,
          value:
              effective.enabled(SpatialVisualParameter.weatherLightning) ??
              false,
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(
                  patch.set(SpatialVisualParameter.weatherLightning, value),
                ),
        ),
        StudioToggleRow(
          label: 'Ambiance sonore',
          icon: Icons.volume_up_outlined,
          accent: StudioAccent.water,
          value:
              effective.enabled(SpatialVisualParameter.weatherSoundEnabled) ??
              false,
          onChanged: onChanged == null
              ? null
              : (value) => onChanged!(
                  patch.set(SpatialVisualParameter.weatherSoundEnabled, value),
                ),
        ),
      ],
      const Text(
        'Les scènes, cinématiques et faits du monde peuvent temporairement remplacer ce choix. Les intérieurs restent protégés par défaut.',
      ),
    ],
  );
}
