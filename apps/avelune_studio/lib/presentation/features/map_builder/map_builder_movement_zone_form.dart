import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderMovementZoneForm extends StatefulWidget {
  const MapBuilderMovementZoneForm({
    super.key,
    required this.binding,
    required this.zone,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapGameplayZone zone;
  final bool enabled;

  @override
  State<MapBuilderMovementZoneForm> createState() =>
      _MapBuilderMovementZoneFormState();
}

class _MapBuilderMovementZoneFormState
    extends State<MapBuilderMovementZoneForm> {
  late final _cost = TextEditingController(text: '$_currentCost');

  int get _currentCost => widget.zone.movementEffect?.movementCost ?? 1;

  @override
  void didUpdateWidget(MapBuilderMovementZoneForm old) {
    super.didUpdateWidget(old);
    if (old.zone.movementEffect?.movementCost != _currentCost) {
      _cost.text = '$_currentCost';
    }
  }

  @override
  void dispose() {
    _cost.dispose();
    super.dispose();
  }

  int? get _draftCost {
    final value = int.tryParse(_cost.text.trim());
    return value == null || value < 1 ? null : value;
  }

  void _applyCost() {
    final cost = _draftCost;
    if (cost == null || cost == _currentCost) return;
    widget.binding.editZones(
      (commands) =>
          commands.updateMovementEffect(widget.zone.id, movementCost: cost),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final l10n = context.l10n;
    final binding = widget.binding;
    final zone = widget.zone;
    final enabled = widget.enabled;
    final movement = zone.movement;
    final effect = zone.movementEffect;
    return Column(
      key: const ValueKey('map-gameplay-zone-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.movementZoneEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          zone.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          l10n.zoneArea(
            zone.area.pos.x,
            zone.area.pos.y,
            zone.area.size.width,
            zone.area.size.height,
          ),
          style: muted,
        ),
        const SizedBox(height: StudioSpacing.l),
        MapBuilderNameField(
          key: const ValueKey('map-gameplay-zone-name'),
          value: zone.name,
          label: l10n.zoneName,
          enabled: enabled,
          onCommit: (name) =>
              binding.editZones((commands) => commands.rename(zone.id, name)),
        ),
        if (movement != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            key: const ValueKey('map-gameplay-zone-mode'),
            label: l10n.movementRequiredMode,
            value: movement.requiredMode.name,
            options: {
              for (final mode in MovementMode.values)
                mode.name: l10n.movementMode(mode),
            },
            onChanged: enabled
                ? (value) => binding.editZones(
                    (commands) => commands.updateMovement(
                      zone.id,
                      requiredMode: MovementMode.values.byName(value),
                    ),
                  )
                : null,
          ),
        ],
        if (effect != null) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            key: const ValueKey('map-gameplay-zone-effect'),
            label: l10n.movementEffectKind,
            value: effect.effectKind.name,
            options: {
              for (final kind in MovementEffectZoneKind.values)
                if (kind != MovementEffectZoneKind.directedJump ||
                    effect.effectKind == kind)
                  kind.name: l10n.movementEffect(kind),
            },
            onChanged: enabled
                ? (value) => binding.editZones(
                    (commands) => commands.updateMovementEffect(
                      zone.id,
                      effectKind: MovementEffectZoneKind.values.byName(value),
                    ),
                  )
                : null,
          ),
          if (effect.effectKind == MovementEffectZoneKind.movementCost) ...[
            const SizedBox(height: StudioSpacing.m),
            TextField(
              key: const ValueKey('map-gameplay-zone-cost'),
              controller: _cost,
              enabled: enabled,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => _applyCost(),
              decoration: InputDecoration(
                isDense: true,
                labelText: l10n.movementCost,
                errorText: _draftCost == null ? l10n.movementCostInvalid : null,
              ),
            ),
            const SizedBox(height: StudioSpacing.m),
            StudioButton(
              key: const ValueKey('map-gameplay-zone-cost-apply'),
              label: l10n.apply,
              icon: Icons.check,
              onPressed:
                  enabled && _draftCost != null && _draftCost != _currentCost
                  ? _applyCost
                  : null,
            ),
          ],
        ],
        if (binding.zoneError case final error?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(error, isError: true),
        ],
        const SizedBox(height: StudioSpacing.l),
        StudioButton(
          key: const ValueKey('map-gameplay-zone-delete'),
          label: l10n.zoneDelete,
          icon: Icons.delete_outline,
          variant: StudioButtonVariant.secondary,
          onPressed: enabled
              ? () => binding.editZones((commands) => commands.delete(zone.id))
              : null,
        ),
      ],
    );
  }
}
