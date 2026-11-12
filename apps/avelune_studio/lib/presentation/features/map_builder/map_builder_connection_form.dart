import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/map_workspace/application/map_workspace_connection_actions.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_labels.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderConnectionForm extends StatefulWidget {
  const MapBuilderConnectionForm({
    super.key,
    required this.binding,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final bool enabled;

  @override
  State<MapBuilderConnectionForm> createState() =>
      _MapBuilderConnectionFormState();
}

class _MapBuilderConnectionFormState extends State<MapBuilderConnectionForm> {
  String? _target;
  MapConnectionDirection? _direction;
  late final _offset = TextEditingController(
    text: '${widget.binding.selectedConnection?.offset ?? 0}',
  );

  @override
  void dispose() {
    _offset.dispose();
    super.dispose();
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
    final map = binding.map!;
    final existing = binding.selectedConnection;
    final destinations = mapConnectionDestinations(
      binding.maps.project!,
      map.id,
    );
    final taken = {for (final entry in map.connections) entry.direction};
    final free = [
      for (final direction in MapConnectionDirection.values)
        if (!taken.contains(direction)) direction,
    ];
    final direction =
        existing?.direction ??
        (free.contains(_direction) ? _direction : free.firstOrNull);
    final target =
        existing?.targetMapId ?? mapConnectionTarget(destinations, _target);
    final offset = mapConnectionOffset(_offset.text);
    final links = binding.links;
    final dirty = binding.maps.active?.dirty == true;
    final ready =
        widget.enabled &&
        !links.busy &&
        !dirty &&
        direction != null &&
        target != null &&
        offset != null &&
        (existing == null || existing.offset != offset);
    return Column(
      key: const ValueKey('map-gameplay-connection-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.neighbourEyebrow,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          existing == null ? l10n.neighbourLinkEdges : binding.mapName(target!),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        if (existing == null)
          StudioSelect(
            key: const ValueKey('map-gameplay-connection-target'),
            label: l10n.neighbourMap,
            value: target,
            options: {for (final entry in destinations) entry.id: entry.name},
            onChanged: (value) => setState(() => _target = value),
          ),
        const SizedBox(height: StudioSpacing.l),
        Text(l10n.neighbourActiveEdge, style: muted),
        const SizedBox(height: StudioSpacing.s),
        Wrap(
          spacing: StudioSpacing.s,
          runSpacing: StudioSpacing.s,
          children: [
            for (final value in MapConnectionDirection.values)
              ChoiceChip(
                key: ValueKey('map-gameplay-connection-edge-${value.name}'),
                label: Text(l10n.direction(value)),
                selected: value == direction,
                onSelected: existing == null && free.contains(value)
                    ? (_) => setState(() => _direction = value)
                    : null,
              ),
          ],
        ),
        const SizedBox(height: StudioSpacing.l),
        TextField(
          key: const ValueKey('map-gameplay-connection-offset'),
          controller: _offset,
          keyboardType: const TextInputType.numberWithOptions(signed: true),
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            labelText: l10n.neighbourOffset,
            suffixText: l10n.cellsUnit,
            errorText: offset == null ? l10n.integerExpected : null,
          ),
        ),
        const SizedBox(height: StudioSpacing.l),
        if (direction != null && target != null)
          Text(
            l10n.neighbourRoundTrip(
              l10n.direction(direction),
              map.name,
              l10n.direction(direction.opposite),
              binding.mapName(target),
            ),
            style: muted,
          ),
        if (existing == null && free.isEmpty)
          StudioNotice(l10n.neighbourAllLinked),
        if (dirty) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(l10n.neighbourSaveFirst),
        ],
        if (links.error case final error?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(error, isError: true),
        ],
        const SizedBox(height: StudioSpacing.l),
        StudioButton(
          key: const ValueKey('map-gameplay-connection-apply'),
          label: existing == null ? l10n.neighbourLink : l10n.neighbourUpdate,
          icon: Icons.link,
          onPressed: ready
              ? () => unawaited(binding.link(direction, target, offset))
              : null,
        ),
        if (existing != null) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioButton(
            key: const ValueKey('map-gameplay-connection-remove'),
            label: l10n.neighbourRemove,
            icon: Icons.link_off,
            variant: StudioButtonVariant.secondary,
            onPressed: widget.enabled && !links.busy && !dirty
                ? () => unawaited(binding.unlink(existing.direction))
                : null,
          ),
        ],
      ],
    );
  }
}
