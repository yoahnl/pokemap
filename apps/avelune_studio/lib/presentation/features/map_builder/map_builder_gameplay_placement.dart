part of 'map_builder_gameplay_inspector.dart';

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
          hint: binding.placingWarp
              ? l10n.warpPlaceClick
              : l10n.warpPlaceChoose,
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
