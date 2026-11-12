import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_day_night_form.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_weather_form.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

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
    final editing = binding.editing;
    final weather = binding.rubric == 'weather';
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
          weather ? l10n.ambianceWeather : l10n.ambianceDayNight,
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
          Text(
            l10n.ambianceLoading,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          )
        else if (weather)
          MapBuilderWeatherForm(
            binding: binding,
            editing: editing,
            enabled: enabled,
          )
        else
          MapBuilderDayNightForm(
            binding: binding,
            editing: editing,
            enabled: enabled,
          ),
      ],
    );
  }
}
