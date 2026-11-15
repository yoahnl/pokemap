import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_selection_properties.dart';
import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

String _number(double value) {
  final rounded = (value * 100).round() / 100;
  return rounded == rounded.roundToDouble()
      ? rounded.toInt().toString()
      : rounded.toString();
}

double? parseSelectionNumber(String text) {
  final value = double.tryParse(text.trim().replaceAll(',', '.'));
  return value != null && value.isFinite ? value : null;
}

class MapBuilderSelectionInspector extends StatelessWidget {
  const MapBuilderSelectionInspector({
    super.key,
    required this.properties,
    required this.enabled,
    required this.onSpatial,
    required this.onAnimated,
    required this.onGrid,
    required this.onInvalid,
  });

  final MapSelectionProperties properties;
  final bool enabled;
  final bool Function(
    SpatialModelProperties model, {
    double? x,
    double? y,
    double? z,
    double? rotation,
    double? scale,
  })
  onSpatial;
  final void Function(SpatialModelProperties model, bool animated) onAnimated;
  final bool Function(GridElementProperties element, GridPos position) onGrid;
  final VoidCallback onInvalid;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final properties = this.properties;
    return Column(
      key: const ValueKey('selection-inspector'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: switch (properties) {
        SpatialModelProperties() => _spatial(context, l10n, properties),
        GridElementProperties() => _grid(context, l10n, properties),
        GroupSelectionProperties(:final count) => [
          _Heading(
            title: l10n.selectionCount(count),
            subtitle: l10n.selectionGroupHint,
            titleKey: const ValueKey('selection-count'),
          ),
        ],
      },
    );
  }

  Widget _field(
    String key,
    String label,
    double value,
    bool Function(double value) commit,
  ) => Padding(
    padding: const EdgeInsets.only(top: StudioSpacing.m),
    child: MapBuilderNameField(
      key: ValueKey(key),
      label: label,
      value: _number(value),
      enabled: enabled,
      onSubmit: (text) async {
        final parsed = parseSelectionNumber(text);
        if (parsed == null) {
          onInvalid();
          return false;
        }
        return commit(parsed);
      },
    ),
  );

  List<Widget> _spatial(
    BuildContext context,
    AppLocalizations l10n,
    SpatialModelProperties model,
  ) => [
    _Heading(title: model.name, subtitle: l10n.selectionKind3d),
    _field(
      'selection-x',
      l10n.selectionX,
      model.x,
      (v) => onSpatial(model, x: v),
    ),
    _field(
      'selection-y',
      l10n.selectionY,
      model.y,
      (v) => onSpatial(model, y: v),
    ),
    _field(
      'selection-z',
      l10n.selectionZ,
      model.z,
      (v) => onSpatial(model, z: v),
    ),
    _field(
      'selection-rotation',
      l10n.selectionRotation,
      model.rotation,
      (v) => onSpatial(model, rotation: v),
    ),
    _field(
      'selection-scale',
      l10n.selectionScale,
      model.scale,
      (v) => onSpatial(model, scale: v),
    ),
    if (model.animated case final animated?)
      StudioToggleRow(
        key: const ValueKey('selection-animations'),
        label: l10n.selectionAnimations,
        description: l10n.selectionAnimationsHint,
        value: animated,
        onChanged: enabled ? (value) => onAnimated(model, value) : null,
      ),
  ];

  List<Widget> _grid(
    BuildContext context,
    AppLocalizations l10n,
    GridElementProperties element,
  ) => [
    _Heading(
      title: element.name,
      subtitle: switch (element.target.family) {
        MapSelectionFamily.decor => l10n.selectionKindDecor,
        MapSelectionFamily.character => l10n.selectionKindCharacter,
        MapSelectionFamily.marker => l10n.selectionKindMarker,
        MapSelectionFamily.warp => l10n.selectionKindWarp,
        MapSelectionFamily.zone => l10n.selectionKindZone,
        MapSelectionFamily.trigger => l10n.selectionKindTrigger,
      },
    ),
    _field(
      'selection-x',
      l10n.selectionX,
      element.position.x.toDouble(),
      (v) => onGrid(element, element.position.copyWith(x: v.round())),
    ),
    _field(
      'selection-y',
      l10n.selectionY,
      element.position.y.toDouble(),
      (v) => onGrid(element, element.position.copyWith(y: v.round())),
    ),
  ];
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title, required this.subtitle, this.titleKey});

  final String title;
  final String subtitle;
  final Key? titleKey;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.selectionEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          title,
          key: titleKey,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
