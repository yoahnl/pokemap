import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderSpawnForm extends StatelessWidget {
  const MapBuilderSpawnForm({
    super.key,
    required this.binding,
    required this.spawn,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapEntity spawn;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final l10n = context.l10n;
    final data = spawn.spawn ?? const MapEntitySpawnData();
    final isDefault = binding.entities?.isDefaultSpawn(spawn.id) ?? false;
    return Column(
      key: const ValueKey('map-gameplay-spawn-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.spawnEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          spawn.name,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(l10n.warpOnThisMap(spawn.pos.x, spawn.pos.y), style: muted),
        const SizedBox(height: StudioSpacing.l),
        MapBuilderNameField(
          key: const ValueKey('map-gameplay-spawn-name'),
          value: spawn.name,
          label: l10n.spawnName,
          enabled: enabled,
          onCommit: (name) => binding.editEntities(
            (commands) => commands.rename(spawn.id, name),
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioSelect(
          key: const ValueKey('map-gameplay-spawn-role'),
          label: l10n.spawnRole,
          value: data.role.name,
          options: {
            for (final role in EntitySpawnRole.values)
              role.name: l10n.spawnRoleName(role),
          },
          onChanged: enabled
              ? (value) => binding.editEntities(
                  (commands) => commands.updateSpawn(
                    spawn.id,
                    role: EntitySpawnRole.values.byName(value),
                  ),
                )
              : null,
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioSelect(
          key: const ValueKey('map-gameplay-spawn-facing'),
          label: l10n.spawnFacing,
          value: data.facing.name,
          options: {
            for (final facing in EntityFacing.values)
              facing.name: l10n.facing(facing),
          },
          onChanged: enabled
              ? (value) => binding.editEntities(
                  (commands) => commands.updateSpawn(
                    spawn.id,
                    facing: EntityFacing.values.byName(value),
                  ),
                )
              : null,
        ),
        const SizedBox(height: StudioSpacing.m),
        StudioToggleRow(
          key: const ValueKey('map-gameplay-spawn-default'),
          label: l10n.spawnDefault,
          description: l10n.spawnDefaultDetail,
          value: isDefault,
          onChanged: enabled
              ? (value) => binding.editEntities(
                  (commands) =>
                      commands.setDefaultSpawn(value ? spawn.id : null),
                )
              : null,
        ),
        if (binding.entityError case final error?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(error, isError: true),
        ],
        const SizedBox(height: StudioSpacing.l),
        StudioButton(
          key: const ValueKey('map-gameplay-spawn-delete'),
          label: l10n.spawnDelete,
          icon: Icons.delete_outline,
          variant: StudioButtonVariant.secondary,
          onPressed: enabled
              ? () => binding.editEntities(
                  (commands) => commands.delete(spawn.id),
                )
              : null,
        ),
      ],
    );
  }
}
