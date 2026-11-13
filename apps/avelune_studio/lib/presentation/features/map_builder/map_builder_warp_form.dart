import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';

import 'package:avelune_studio/features/map_workspace/application/map_arrival_choices.dart';
import 'package:avelune_studio/l10n/app_localizations.dart';
import 'package:avelune_studio/presentation/features/map_builder/map_builder_gameplay_binding.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

Map<String, String> _transitions(AppLocalizations l10n) => {
  'fade': l10n.transitionFade,
  'hgss': l10n.transitionHgss,
  'none': l10n.transitionNone,
};

class MapBuilderWarpForm extends StatefulWidget {
  const MapBuilderWarpForm({
    super.key,
    required this.binding,
    required this.warp,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapWarp warp;
  final bool enabled;

  @override
  State<MapBuilderWarpForm> createState() => _MapBuilderWarpFormState();
}

class _MapBuilderWarpFormState extends State<MapBuilderWarpForm> {
  late final _x = TextEditingController(text: '${widget.warp.targetPos.x}');
  late final _y = TextEditingController(text: '${widget.warp.targetPos.y}');
  late final _duration = TextEditingController(
    text: '${(widget.warp.transition.durationSeconds * 1000).round()}',
  );

  @override
  void didUpdateWidget(MapBuilderWarpForm old) {
    super.didUpdateWidget(old);
    final warp = widget.warp;
    if (old.warp.targetPos != warp.targetPos) {
      _x.text = '${warp.targetPos.x}';
      _y.text = '${warp.targetPos.y}';
    }
    if (old.warp.transition != warp.transition) {
      _duration.text = '${(warp.transition.durationSeconds * 1000).round()}';
    }
  }

  @override
  void dispose() {
    _x.dispose();
    _y.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _apply() {
    final warp = widget.warp;
    final x = int.tryParse(_x.text.trim());
    final y = int.tryParse(_y.text.trim());
    final duration = int.tryParse(_duration.text.trim());
    if (duration != null && (duration <= 0 || duration > 5000)) {
      widget.binding.rejectWarp(context.l10n.warpDurationRange);
      return;
    }
    widget.binding.editWarp((commands) {
      if (x != null && y != null && GridPos(x: x, y: y) != warp.targetPos) {
        commands.retarget(
          warp.id,
          targetPos: GridPos(x: x, y: y),
        );
      }
      if (duration != null &&
          duration / 1000 != warp.transition.durationSeconds) {
        commands.configureTransition(
          warp.id,
          warp.transition.copyWith(durationSeconds: duration / 1000),
        );
      }
    });
  }

  bool get _pending {
    final warp = widget.warp;
    return _x.text.trim() != '${warp.targetPos.x}' ||
        _y.text.trim() != '${warp.targetPos.y}' ||
        _duration.text.trim() !=
            '${(warp.transition.durationSeconds * 1000).round()}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final muted = theme.textTheme.bodySmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    final binding = widget.binding;
    final warp = widget.warp;
    final arrival = warp.triggerMode == MapWarpTriggerMode.sceneOnly;
    final commands = binding.warps!;
    final enabled = widget.enabled;
    final l10n = context.l10n;
    return Column(
      key: const ValueKey('map-gameplay-warp-form'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          arrival ? l10n.arrivalEyebrow : l10n.warpBetweenMaps,
          style: theme.textTheme.labelSmall?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: StudioSpacing.m),
        Text(
          binding.warpLabel(warp),
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(l10n.warpOnThisMap(warp.pos.x, warp.pos.y), style: muted),
        if (!arrival) ...[
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            key: const ValueKey('map-gameplay-warp-target'),
            label: l10n.warpDestination,
            value: warp.targetMapId,
            options: {
              for (final entry in commands.destinations()) entry.id: entry.name,
            },
            onChanged: enabled
                ? (value) => binding.editWarp(
                    (commands) =>
                        commands.retarget(warp.id, targetMapId: value),
                  )
                : null,
          ),
          const SizedBox(height: StudioSpacing.l),
          Text(l10n.warpArrivalOnDestination, style: muted),
          const SizedBox(height: StudioSpacing.s),
          Row(
            children: [
              Expanded(child: _number('map-gameplay-warp-x', 'X', _x)),
              const SizedBox(width: StudioSpacing.m),
              Expanded(child: _number('map-gameplay-warp-y', 'Y', _y)),
            ],
          ),
          _ArrivalChoices(
            key: ValueKey('arrivals-${warp.targetMapId}'),
            binding: binding,
            warp: warp,
            enabled: enabled,
          ),
          const SizedBox(height: StudioSpacing.l),
          StudioSelect(
            key: const ValueKey('map-gameplay-warp-transition'),
            label: l10n.warpScreenTransition,
            value: warp.transition.type.name,
            options: _transitions(l10n),
            onChanged: enabled
                ? (value) => binding.editWarp(
                    (commands) => commands.configureTransition(
                      warp.id,
                      warp.transition.copyWith(
                        type: MapWarpTransitionType.values.byName(value),
                      ),
                    ),
                  )
                : null,
          ),
          const SizedBox(height: StudioSpacing.m),
          _number(
            'map-gameplay-warp-duration',
            l10n.warpTransitionDuration,
            _duration,
            suffix: 'ms',
          ),
          const SizedBox(height: StudioSpacing.m),
          StudioButton(
            key: const ValueKey('map-gameplay-warp-apply'),
            label: l10n.apply,
            icon: Icons.check,
            onPressed: enabled && _pending ? _apply : null,
          ),
        ],
        if (binding.warpError case final error?) ...[
          const SizedBox(height: StudioSpacing.m),
          StudioNotice(error, isError: true),
        ],
        const SizedBox(height: StudioSpacing.l),
        StudioButton(
          key: const ValueKey('map-gameplay-warp-delete'),
          label: arrival ? l10n.warpDeletePoint : l10n.warpDeletePassage,
          icon: Icons.delete_outline,
          variant: StudioButtonVariant.secondary,
          onPressed: enabled
              ? () => binding.editWarp((commands) => commands.delete(warp.id))
              : null,
        ),
      ],
    );
  }

  Widget _number(
    String key,
    String label,
    TextEditingController controller, {
    String? suffix,
  }) => TextField(
    key: ValueKey(key),
    controller: controller,
    enabled: widget.enabled,
    keyboardType: TextInputType.number,
    onChanged: (_) => setState(() {}),
    decoration: InputDecoration(
      isDense: true,
      labelText: label,
      suffixText: suffix,
      errorText: int.tryParse(controller.text.trim()) == null
          ? context.l10n.numberExpected
          : null,
    ),
  );
}

class _ArrivalChoices extends StatefulWidget {
  const _ArrivalChoices({
    super.key,
    required this.binding,
    required this.warp,
    required this.enabled,
  });

  final MapBuilderGameplayBinding binding;
  final MapWarp warp;
  final bool enabled;

  @override
  State<_ArrivalChoices> createState() => _ArrivalChoicesState();
}

class _ArrivalChoicesState extends State<_ArrivalChoices> {
  late final _destination = widget.binding.maps.previewMap(
    widget.warp.targetMapId,
  );

  @override
  Widget build(BuildContext context) => FutureBuilder<MapData?>(
    future: _destination,
    builder: (context, snapshot) {
      final destination = snapshot.data;
      if (destination == null) return const SizedBox.shrink();
      final warp = widget.warp;
      final problem = mapArrivalProblem(destination, warp.targetPos);
      final choices = mapArrivalChoices(
        destination,
        fromMapId: widget.binding.map?.id ?? '',
      ).where((choice) => choice.pos != warp.targetPos).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (problem != null) ...[
            const SizedBox(height: StudioSpacing.m),
            StudioNotice(problem, isError: true),
          ],
          for (final choice in choices)
            StudioChoice(
              leading: const Icon(Icons.place_outlined, size: 18),
              label: choice.label,
              subtitle: choice.detail,
              onTap: widget.enabled
                  ? () => widget.binding.editWarp(
                      (commands) =>
                          commands.retarget(warp.id, targetPos: choice.pos),
                    )
                  : null,
            ),
        ],
      );
    },
  );
}
