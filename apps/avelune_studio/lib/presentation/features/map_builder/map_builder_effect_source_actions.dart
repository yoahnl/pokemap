part of 'map_builder_effect_sources.dart';

extension _MapBuilderEffectSourceActions on MapBuilderEffectSources {
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
