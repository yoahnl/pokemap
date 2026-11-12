import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderSpawnForm extends StatefulWidget {
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
  State<MapBuilderSpawnForm> createState() => _MapBuilderSpawnFormState();
}

class _MapBuilderSpawnFormState extends State<MapBuilderSpawnForm> {
  late final _name = TextEditingController(text: widget.spawn.name);
  late final _focus = FocusNode()..addListener(_leaveName);

  @override
  void didUpdateWidget(MapBuilderSpawnForm old) {
    super.didUpdateWidget(old);
    if (old.spawn.name != widget.spawn.name && !_focus.hasFocus) {
      _name.text = widget.spawn.name;
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    _name.dispose();
    super.dispose();
  }

  void _leaveName() {
    if (!_focus.hasFocus) _rename();
  }

  void _rename() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      _name.text = widget.spawn.name;
      return;
    }
    if (name == widget.spawn.name) return;
    widget.binding.editEntities(
      (commands) => commands.rename(widget.spawn.id, name),
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
    final spawn = widget.spawn;
    final data = spawn.spawn ?? const MapEntitySpawnData();
    final enabled = widget.enabled;
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
        TextField(
          key: const ValueKey('map-gameplay-spawn-name'),
          controller: _name,
          focusNode: _focus,
          enabled: enabled,
          onSubmitted: (_) => _rename(),
          decoration: InputDecoration(isDense: true, labelText: l10n.spawnName),
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
