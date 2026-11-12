import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_name_field.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

const _noObstacle = 'none';

MapEntityFieldObstacleData mapBuilderObstacle(
  FieldObstacleKind kind,
  FieldObstacleResetPolicy policy,
) => MapEntityFieldObstacleData(
  kind: kind,
  resetPolicy: kind == FieldObstacleKind.iceBlock
      ? FieldObstacleResetPolicy.mapInstance
      : policy,
);

class MapBuilderObstacleForm extends StatelessWidget {
  const MapBuilderObstacleForm({
    super.key,
    required this.binding,
    required this.entity,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapEntity entity;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final obstacle = entity.fieldObstacle!;
    void configure(MapEntityFieldObstacleData value) => binding.editEntities(
      (commands) => commands.setFieldObstacle(entity.id, value),
    );
    return _ObstacleColumn(
      formKey: 'map-gameplay-obstacle-form',
      eyebrow: l10n.obstacleEyebrow,
      title: entity.name,
      subtitle: l10n.warpOnThisMap(entity.pos.x, entity.pos.y),
      error: binding.entityError,
      children: [
        MapBuilderNameField(
          key: const ValueKey('map-gameplay-obstacle-name'),
          value: entity.name,
          label: l10n.zoneName,
          enabled: enabled,
          onCommit: (name) => binding.editEntities(
            (commands) => commands.rename(entity.id, name),
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        _ObstacleChoices(
          obstacle: obstacle,
          allowsNone: false,
          onChanged: enabled ? (value) => configure(value!) : null,
        ),
        const SizedBox(height: StudioSpacing.l),
        StudioButton(
          key: const ValueKey('map-gameplay-obstacle-delete'),
          label: l10n.obstacleDelete,
          icon: Icons.delete_outline,
          variant: StudioButtonVariant.secondary,
          onPressed: enabled
              ? () => binding.editEntities(
                  (commands) => commands.delete(entity.id),
                )
              : null,
        ),
      ],
    );
  }
}

class MapBuilderInstanceObstacleForm extends StatelessWidget {
  const MapBuilderInstanceObstacleForm({
    super.key,
    required this.binding,
    required this.instance,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final SpatialModelInstance instance;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final obstacle = binding.boundEntity(instance)?.fieldObstacle;
    final refusal = obstacle == null ? binding.obstacleRefusal(instance) : null;
    final model = binding.maps.project?.models3d
        .where((entry) => entry.id == instance.modelId)
        .firstOrNull;
    return _ObstacleColumn(
      formKey: 'map-gameplay-instance-obstacle-form',
      eyebrow: l10n.decorEyebrow,
      title: model?.name ?? instance.modelId,
      subtitle: l10n.warpOnThisMap(
        instance.position.x.floor(),
        instance.position.z.floor(),
      ),
      error: binding.entityError,
      children: [
        if (refusal != null) StudioNotice(refusal),
        if (refusal == null)
          _ObstacleChoices(
            obstacle: obstacle,
            allowsNone: true,
            onChanged: enabled
                ? (value) => unawaited(
                    binding.configureInstanceObstacle(instance.id, value),
                  )
                : null,
          ),
      ],
    );
  }
}

class MapBuilderObstaclePlacement extends StatelessWidget {
  const MapBuilderObstaclePlacement({
    super.key,
    required this.binding,
    required this.kind,
    required this.enabled,
    required this.cancel,
  });

  final MapBuilderGameplayBinding binding;
  final FieldObstacleKind kind;
  final bool enabled;
  final Widget cancel;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final visuals = binding.obstacleVisuals;
    final visual = binding.obstacleVisual;
    return _ObstacleColumn(
      formKey: 'map-gameplay-obstacle-placement',
      eyebrow: l10n.obstacleEyebrow,
      title: l10n.obstacleKindName(kind),
      subtitle: visual == null ? l10n.obstaclePlaceHint : l10n.obstaclePlaceClick,
      children: [
        if (visuals.isEmpty)
          StudioNotice(l10n.obstacleNoElement)
        else
          StudioSelect(
            key: const ValueKey('map-gameplay-obstacle-visual'),
            label: l10n.obstacleVisual,
            value: visual?.id,
            options: {for (final entry in visuals) entry.id: entry.name},
            onChanged: enabled
                ? (value) => binding.chooseObstacleVisual(
                    visuals.firstWhere((entry) => entry.id == value),
                  )
                : null,
          ),
        const SizedBox(height: StudioSpacing.m),
        cancel,
      ],
    );
  }
}

class _ObstacleChoices extends StatelessWidget {
  const _ObstacleChoices({
    required this.obstacle,
    required this.allowsNone,
    required this.onChanged,
  });

  final MapEntityFieldObstacleData? obstacle;
  final bool allowsNone;
  final ValueChanged<MapEntityFieldObstacleData?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final current = obstacle;
    final change = onChanged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StudioSelect(
          key: const ValueKey('map-gameplay-obstacle-kind'),
          label: l10n.obstacleKind,
          value: current?.kind.name ?? _noObstacle,
          options: {
            if (allowsNone) _noObstacle: l10n.obstacleKindNone,
            for (final kind in FieldObstacleKind.values)
              kind.name: l10n.obstacleKindName(kind),
          },
          onChanged: change == null
              ? null
              : (value) => change(
                  value == _noObstacle
                      ? null
                      : mapBuilderObstacle(
                          FieldObstacleKind.values.byName(value),
                          current?.resetPolicy ??
                              FieldObstacleResetPolicy.mapInstance,
                        ),
                ),
        ),
        if (current != null && current.kind != FieldObstacleKind.iceBlock) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioSelect(
            key: const ValueKey('map-gameplay-obstacle-reset'),
            label: l10n.obstacleReset,
            value: current.resetPolicy.name,
            options: {
              for (final policy in FieldObstacleResetPolicy.values)
                policy.name: l10n.obstacleResetName(policy),
            },
            onChanged: change == null
                ? null
                : (value) => change(
                    mapBuilderObstacle(
                      current.kind,
                      FieldObstacleResetPolicy.values.byName(value),
                    ),
                  ),
          ),
        ],
      ],
    );
  }
}

class _ObstacleColumn extends StatelessWidget {
  const _ObstacleColumn({
    required this.formKey,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.children,
    this.error,
  });

  final String formKey;
  final String eyebrow;
  final String title;
  final String subtitle;
  final List<Widget> children;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      key: ValueKey(formKey),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          eyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          title,
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
        const SizedBox(height: StudioSpacing.l),
        ...children,
        if (error case final message?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(message, isError: true),
        ],
      ],
    );
  }
}
