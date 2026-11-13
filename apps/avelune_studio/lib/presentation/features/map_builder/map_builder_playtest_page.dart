import 'dart:async';

import 'package:avelune_design_system/avelune_design_system.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:map_core/map_core.dart';

import 'package:avelune_studio/features/playtest/contracts/studio_playtest_builders.dart';
import 'package:avelune_studio/features/playtest/contracts/studio_playtest_controls.dart';
import 'package:avelune_studio/presentation/features/map_builder/studio_playtest_performance.dart';
import 'package:avelune_studio/presentation/shared/localization/studio_locale.dart';

class MapBuilderPlaytestPage extends StatefulWidget {
  const MapBuilderPlaytestPage({
    super.key,
    required this.entry,
    required this.revision,
    required this.runtime,
    required this.onClose,
    this.performance,
  });

  final ProjectMapEntry entry;
  final String revision;
  final StudioRuntimeBuilder runtime;
  final VoidCallback onClose;
  final StudioPlaytestPerformanceMonitor? performance;

  @override
  State<MapBuilderPlaytestPage> createState() => _MapBuilderPlaytestPageState();
}

class _MapBuilderPlaytestPageState extends State<MapBuilderPlaytestPage> {
  final _controls = StudioPlaytestControls();
  late final _performance =
      widget.performance ?? StudioPlaytestPerformanceMonitor();
  late final Widget _game = widget.runtime(
    widget.entry,
    widget.revision,
    _controls,
    widget.onClose,
  );
  var _speed = PlaytestSpeed.normal;
  var _wasReady = false;

  @override
  void initState() {
    super.initState();
    _controls.addListener(_statusChanged);
    _performance.addListener(_statusChanged);
  }

  void _statusChanged() {
    if (!mounted) return;
    final ready = _controls.status.ready;
    if (ready && !_wasReady) _speed = PlaytestSpeed.normal;
    _wasReady = ready;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controls.removeListener(_statusChanged);
    _controls.dispose();
    _performance.removeListener(_statusChanged);
    if (widget.performance == null) _performance.dispose();
    super.dispose();
  }

  void _setSpeed(PlaytestSpeed speed) {
    _controls.setTestSpeed(speed);
    setState(() => _speed = speed);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _controls.status;
    final available = _controls.available;
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      key: const ValueKey('map-playtest'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            key: const ValueKey('map-playtest-bar'),
            padding: const EdgeInsets.symmetric(
              horizontal: StudioSpacing.xl,
              vertical: StudioSpacing.m,
            ),
            decoration: BoxDecoration(
              color: scheme.surface,
              border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
            ),
            child: Wrap(
              spacing: StudioSpacing.m,
              runSpacing: StudioSpacing.s,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                StudioButton(
                  key: const ValueKey('map-playtest-back'),
                  label: l10n.playtestBack,
                  icon: Icons.arrow_back,
                  variant: StudioButtonVariant.secondary,
                  onPressed: _controls.requestClose,
                ),
                Text(
                  l10n.playtestTitle(widget.entry.name),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                StudioButton(
                  key: const ValueKey('map-playtest-new-game'),
                  label: l10n.playtestNewGame,
                  icon: Icons.restart_alt,
                  variant: StudioButtonVariant.quiet,
                  onPressed: available
                      ? () => unawaited(_controls.newGame())
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('map-playtest-save'),
                  label: l10n.playtestSave,
                  icon: Icons.save_outlined,
                  variant: StudioButtonVariant.quiet,
                  onPressed: available
                      ? () => unawaited(_controls.save())
                      : null,
                ),
                StudioButton(
                  key: const ValueKey('map-playtest-resume'),
                  label: l10n.playtestResume,
                  icon: Icons.restore,
                  variant: StudioButtonVariant.quiet,
                  onPressed: _controls.canResume
                      ? () => unawaited(_controls.resume())
                      : null,
                ),
                if (status.spatial) ...[
                  StudioButton(
                    key: const ValueKey('map-playtest-pause'),
                    label: status.paused
                        ? l10n.playtestContinue
                        : l10n.playtestPause,
                    icon: status.paused ? Icons.play_arrow : Icons.pause,
                    variant: StudioButtonVariant.quiet,
                    onPressed: available
                        ? () => unawaited(_controls.togglePause())
                        : null,
                  ),
                  StudioButton(
                    key: const ValueKey('map-playtest-diagonal'),
                    label: status.diagonal
                        ? l10n.playtestDiagonalOff
                        : l10n.playtestDiagonalOn,
                    icon: Icons.open_with,
                    variant: StudioButtonVariant.quiet,
                    onPressed: available ? _controls.toggleDiagonal : null,
                  ),
                ] else if (status.ready)
                  for (final speed in PlaytestSpeed.values)
                    StudioButton(
                      key: ValueKey('map-playtest-speed-${speed.multiplier}'),
                      label: l10n.playtestSpeed(speed.multiplier),
                      variant: speed == _speed
                          ? StudioButtonVariant.secondary
                          : StudioButtonVariant.quiet,
                      onPressed: available && speed != _speed
                          ? () => _setSpeed(speed)
                          : null,
                    ),
                if (_performance.sample case final sample?)
                  Text(
                    l10n.playtestPerformance(
                      sample.fps.toStringAsFixed(0),
                      sample.buildMs.toStringAsFixed(1),
                      sample.rasterMs.toStringAsFixed(1),
                    ),
                    key: const ValueKey('map-playtest-performance'),
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                if (status.message case final message?)
                  Text(
                    message,
                    key: const ValueKey('map-playtest-message'),
                    style: Theme.of(context).textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
          Expanded(child: _game),
        ],
      ),
    );
  }
}
