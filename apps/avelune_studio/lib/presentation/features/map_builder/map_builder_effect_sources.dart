import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_atmosphere_editing.dart';
import 'package:avelune_studio/features/project_visuals/application/map_effect_editing.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_ambiance_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const mapBuilderHaloLimit = 32;

bool _sameTarget(
  SpatialAtmosphereMaterialTarget a,
  SpatialAtmosphereMaterialTarget b,
) => a.instanceId == b.instanceId && a.materialName == b.materialName;

class MapBuilderEffectSources extends StatelessWidget {
  const MapBuilderEffectSources({
    super.key,
    required this.binding,
    required this.effect,
    required this.enabled,
  });

  final MapBuilderAmbianceBinding binding;
  final MapEffect effect;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final sources = binding.sources;
    if (sources == null || effect == MapEffect.fog) {
      return const SizedBox.shrink();
    }
    final settings = sources.controller.current;
    final selected = binding.selectedModel;
    return Column(
      key: const ValueKey('map-ambiance-effect-sources-panel'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Caption(switch (effect) {
          MapEffect.halos => l10n.effectHaloSources(settings.halos.length),
          MapEffect.fireflies => l10n.effectFireflySources(
            settings.fireflyZones.length,
          ),
          MapEffect.water => l10n.effectWaterSources(
            settings.waterTargets.length,
          ),
          _ => l10n.effectWindowSources(settings.windows.length),
        }, key: const ValueKey('map-ambiance-effect-sources')),
        const SizedBox(height: StudioSpacing.s),
        ..._rows(context, sources, settings, selected),
        const SizedBox(height: StudioSpacing.m),
        ..._actions(context, sources, settings, selected),
      ],
    );
  }

  List<Widget> _rows(
    BuildContext context,
    MapAtmosphereEditing sources,
    SpatialAtmosphereSettings settings,
    String? selected,
  ) {
    final l10n = context.l10n;
    String modelName(String id) =>
        sources.modelOf(id)?.name ?? l10n.effectUnknownModel;
    String targetName(SpatialAtmosphereMaterialTarget target) {
      final instance = target.instanceId;
      if (instance != null) {
        return '${target.materialName} · ${modelName(instance)}';
      }
      final ground = sources
          .groundMaterials()
          .where((entry) => _sameTarget(entry.$2, target))
          .firstOrNull;
      return l10n.effectGroundSource(ground?.$1 ?? target.materialName);
    }

    Widget row(
      int index, {
      required String label,
      String? instance,
      required void Function(MapAtmosphereEditing sources) remove,
    }) => StudioChoice(
      key: ValueKey('map-ambiance-source-$index'),
      dense: true,
      label: label,
      selected: instance != null && instance == selected,
      onTap: instance == null ? null : () => binding.locate(instance),
      trailing: IconButton(
        key: ValueKey('map-ambiance-source-remove-$index'),
        tooltip: l10n.effectRemove,
        visualDensity: VisualDensity.compact,
        iconSize: 16,
        icon: const Icon(Icons.close),
        onPressed: enabled ? () => binding.editSources(remove) : null,
      ),
    );

    return switch (effect) {
      MapEffect.halos => [
        for (final (index, halo) in settings.halos.indexed)
          row(
            index,
            label: modelName(halo.instanceId),
            instance: halo.instanceId,
            remove: (sources) => sources.removeHalo(index),
          ),
      ],
      MapEffect.water => [
        for (final (index, target) in settings.waterTargets.indexed)
          row(
            index,
            label: targetName(target),
            instance: target.instanceId,
            remove: (sources) => sources.removeWater(index),
          ),
      ],
      MapEffect.windows => [
        for (final (index, window) in settings.windows.indexed)
          row(
            index,
            label: targetName(window.target),
            instance: window.target.instanceId,
            remove: (sources) => sources.removeWindow(index),
          ),
      ],
      MapEffect.fireflies => [
        for (final (index, zone) in settings.fireflyZones.indexed)
          row(
            index,
            label: _coversMap(zone, sources.map)
                ? l10n.effectWholeMap
                : l10n.effectZone(index + 1),
            remove: (sources) => sources.removeFireflyZone(index),
          ),
      ],
      MapEffect.fog => const [],
    };
  }

  List<Widget> _actions(
    BuildContext context,
    MapAtmosphereEditing sources,
    SpatialAtmosphereSettings settings,
    String? selected,
  ) {
    final l10n = context.l10n;
    if (effect == MapEffect.fireflies) {
      if (settings.fireflyZones.isNotEmpty) return const [];
      return [
        StudioButton(
          key: const ValueKey('map-ambiance-source-cover-map'),
          variant: StudioButtonVariant.secondary,
          icon: Icons.add,
          label: l10n.effectCoverMap,
          onPressed: enabled
              ? () => binding.editSources((sources) => sources.addFireflyZone())
              : null,
        ),
      ];
    }
    final ground = effect == MapEffect.water
        ? sources.groundMaterials()
        : const <(String, SpatialAtmosphereMaterialTarget)>[];
    return [
      if (selected == null)
        _Caption(
          l10n.effectPickModel,
          key: const ValueKey('map-ambiance-source-hint'),
        )
      else ...[
        _Eyebrow(l10n.effectSelectedModel),
        const SizedBox(height: StudioSpacing.xs),
        Text(
          sources.modelOf(selected)?.name ?? l10n.effectUnknownModel,
          key: const ValueKey('map-ambiance-source-model'),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: StudioSpacing.s),
        if (effect == MapEffect.halos)
          _haloAction(context, settings, selected)
        else
          ..._materialChoices(
            context,
            settings,
            sources.instanceMaterials(selected),
            empty: l10n.effectNoMaterials,
          ),
      ],
      if (ground.isNotEmpty) ...[
        const SizedBox(height: StudioSpacing.m),
        _Eyebrow(l10n.effectGround),
        const SizedBox(height: StudioSpacing.xs),
        ..._materialChoices(
          context,
          settings,
          [for (final (_, target) in ground) target],
          labels: [for (final (name, _) in ground) name],
        ),
      ],
    ];
  }

  Widget _haloAction(
    BuildContext context,
    SpatialAtmosphereSettings settings,
    String selected,
  ) {
    final l10n = context.l10n;
    final full = settings.halos.length >= mapBuilderHaloLimit;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioButton(
          key: const ValueKey('map-ambiance-source-add-halo'),
          variant: StudioButtonVariant.secondary,
          icon: Icons.add,
          label: l10n.effectAddHalo,
          onPressed: enabled && !full
              ? () =>
                    binding.editSources((sources) => sources.addHalo(selected))
              : null,
        ),
        if (full) ...[
          const SizedBox(height: StudioSpacing.xs),
          _Caption(l10n.effectHaloLimit(mapBuilderHaloLimit)),
        ],
      ],
    );
  }

  List<Widget> _materialChoices(
    BuildContext context,
    SpatialAtmosphereSettings settings,
    List<SpatialAtmosphereMaterialTarget> targets, {
    List<String>? labels,
    String? empty,
  }) {
    if (targets.isEmpty) {
      return [if (empty != null) _Caption(empty)];
    }
    final current = effect == MapEffect.water
        ? settings.waterTargets
        : [for (final window in settings.windows) window.target];
    return [
      for (final (index, target) in targets.indexed)
        StudioChoice(
          key: ValueKey(
            'map-ambiance-material-${target.instanceId ?? 'ground'}-${target.materialName}',
          ),
          dense: true,
          label: labels?[index] ?? target.materialName,
          selected: current.any((item) => _sameTarget(item, target)),
          trailing: Icon(
            current.any((item) => _sameTarget(item, target))
                ? Icons.check_box
                : Icons.check_box_outline_blank,
            size: 16,
          ),
          onTap: enabled ? () => _toggle(target) : null,
        ),
    ];
  }

  void _toggle(SpatialAtmosphereMaterialTarget target) =>
      binding.editSources((sources) {
        final settings = sources.controller.current;
        if (effect == MapEffect.water) {
          final index = settings.waterTargets.indexWhere(
            (item) => _sameTarget(item, target),
          );
          index < 0 ? sources.addWater(target) : sources.removeWater(index);
        } else {
          final index = settings.windows.indexWhere(
            (item) => _sameTarget(item.target, target),
          );
          index < 0 ? sources.addWindow(target) : sources.removeWindow(index);
        }
      });
}

bool _coversMap(SpatialAtmosphereFireflyZone zone, MapData map) =>
    zone.bounds.min.x <= 0 &&
    zone.bounds.min.z <= 0 &&
    zone.bounds.max.x >= map.size.width &&
    zone.bounds.max.z >= map.size.height;

IconData mapBuilderEffectIcon(MapEffect effect) => switch (effect) {
  MapEffect.halos => Icons.lightbulb_outline,
  MapEffect.fog => Icons.blur_on,
  MapEffect.fireflies => Icons.auto_awesome_outlined,
  MapEffect.water => Icons.waves,
  MapEffect.windows => Icons.window_outlined,
};

class _Caption extends StatelessWidget {
  const _Caption(this.text, {super.key});

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
