import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_editing_state.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderEncounterZoneForm extends StatelessWidget {
  const MapBuilderEncounterZoneForm({
    super.key,
    required this.binding,
    required this.zone,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapGameplayZone zone;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final l10n = context.l10n;
    final encounter = zone.encounter ?? const EncounterZonePayload();
    final ready = binding.encounterTablesReady;
    final problem = ready ? binding.zones?.coverageProblem(zone) : null;
    return Column(
      key: const ValueKey('map-gameplay-encounter-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.encounterZoneEyebrow,
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
        const SizedBox(height: StudioSpacing.l),
        StudioSelect(
          key: const ValueKey('map-gameplay-encounter-table'),
          label: l10n.encounterTable,
          value: encounter.encounterTableId,
          options: {
            for (final table in binding.encounterTables) table.id: table.name,
          },
          onChanged: enabled && ready
              ? (value) => binding.editZones(
                  (commands) => commands.updateEncounter(zone.id, tableId: value),
                )
              : null,
        ),
        if (!ready) Text(l10n.encounterTablesLoading, style: muted),
        const SizedBox(height: StudioSpacing.m),
        StudioSelect(
          key: const ValueKey('map-gameplay-encounter-kind'),
          label: l10n.encounterKind,
          value: encounter.encounterKind.name,
          options: {
            for (final kind in EncounterKind.values)
              kind.name: l10n.encounterKindName(kind),
          },
          onChanged: enabled
              ? (value) => binding.editZones(
                  (commands) => commands.updateEncounter(
                    zone.id,
                    encounterKind: EncounterKind.values.byName(value),
                  ),
                )
              : null,
        ),
        if (problem != null) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(problem),
        ],
        if (binding.paintsEncounters) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioChoice(
            key: const ValueKey('map-gameplay-encounter-paint-into'),
            leading: const Icon(Icons.brush_outlined, size: 18),
            label: l10n.encounterPaintInto,
            selected: binding.tool == StudioMapTool.encounterPaint,
            onTap: enabled
                ? () => binding.armEncounterBrush(erase: false)
                : null,
          ),
          StudioChoice(
            key: const ValueKey('map-gameplay-encounter-erase-from'),
            leading: const Icon(Icons.auto_fix_off_outlined, size: 18),
            label: l10n.encounterEraseFrom,
            selected: binding.tool == StudioMapTool.encounterErase,
            onTap: enabled
                ? () => binding.armEncounterBrush(erase: true)
                : null,
          ),
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
