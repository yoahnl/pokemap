import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/project_visuals/application/map_effect_editing.dart';
import 'package:avelune_studio/features/project_visuals/application/spatial_visual_editing.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_effect_sources.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

String _levelLabel(SpatialVisualParameter level, AppLocalizations l10n) =>
    switch (level) {
      SpatialVisualParameter.haloSpread => l10n.effectSpread,
      SpatialVisualParameter.fogOpacity => l10n.effectOpacity,
      SpatialVisualParameter.fireflyDensity => l10n.effectDensity,
      SpatialVisualParameter.waterSpeed => l10n.effectSpeed,
      _ => l10n.effectStrength,
    };

class MapBuilderEffectsForm extends StatelessWidget {
  const MapBuilderEffectsForm({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final effect in MapEffect.values) ...[
          StudioChoice(
            key: ValueKey('map-ambiance-effect-${effect.name}'),
            leading: Icon(mapBuilderEffectIcon(effect), size: 18),
            label: l10n.effectName(effect.name),
            subtitle: l10n.effectState(
              editing.flag(effect.toggle) ? l10n.effectOn : l10n.effectOff,
              editing.overridesEffect(effect)
                  ? l10n.effectFromMap
                  : l10n.effectFromProject,
            ),
            selected: effect == binding.effect,
            onTap: () => binding.openEffect(effect),
          ),
          if (effect == binding.effect)
            _EffectDetail(
              binding: binding,
              editing: editing,
              effect: effect,
              enabled: enabled,
            ),
        ],
      ],
    );
  }
}

class _EffectDetail extends StatelessWidget {
  const _EffectDetail({
    required this.binding,
    required this.editing,
    required this.effect,
    required this.enabled,
  });

  final MapBuilderAmbianceBinding binding;
  final SpatialVisualEditing editing;
  final MapEffect effect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final overridden = editing.overridesEffect(effect);
    final on = editing.flag(effect.toggle);
    SpatialVisualEditing? current() => binding.editing;
    return Padding(
      key: ValueKey('map-ambiance-effect-detail-${effect.name}'),
      padding: const EdgeInsets.fromLTRB(
        StudioSpacing.m,
        StudioSpacing.s,
        0,
        StudioSpacing.l,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<bool>(
            key: const ValueKey('map-ambiance-effect-origin'),
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: false, label: Text(l10n.effectInherit)),
              ButtonSegment(value: true, label: Text(l10n.effectOverride)),
            ],
            selected: {overridden},
            onSelectionChanged: enabled
                ? (value) => current()?.setEffectOverride(
                    effect,
                    override: value.single,
                  )
                : null,
          ),
          if (overridden) ...[
            StudioToggleRow(
              key: const ValueKey('map-ambiance-effect-toggle'),
              label: l10n.effectOn,
              value: on,
              onChanged: enabled
                  ? (value) => current()?.change(effect.toggle, value)
                  : null,
            ),
            if (on)
              for (final level in effect.levels)
                StudioSlider(
                  key: ValueKey('map-ambiance-effect-level-${level.name}'),
                  label: _levelLabel(level, l10n),
                  value: editing.number(level),
                  min: level.minimum,
                  max: level.maximum,
                  onChangeStart: enabled ? (_) => binding.beginGesture() : null,
                  onChangeEnd: enabled ? (_) => binding.endGesture() : null,
                  onChanged: enabled
                      ? (value) => current()?.change(level, value)
                      : null,
                ),
          ],
          if (effect != MapEffect.fog) ...[
            const SizedBox(height: StudioSpacing.l),
            MapBuilderEffectSources(
              binding: binding,
              effect: effect,
              enabled: enabled,
            ),
          ],
        ],
      ),
    );
  }
}
