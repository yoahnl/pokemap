import 'package:flutter/material.dart';
import 'package:map_player_ui/map_player_ui.dart';

import 'avelune_runtime_diagnostics.dart';

class AveluneDebugHud extends StatelessWidget {
  const AveluneDebugHud({super.key, required this.diagnostics});

  final AveluneRuntimeDiagnostics diagnostics;
  static final _theme = PokeMapPlayerTheme.dark();

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: diagnostics,
    builder: (context, _) {
      if (!diagnostics.visible) return const SizedBox.shrink();
      return IgnorePointer(
        child: SafeArea(
          child: Align(
            alignment: Alignment.topRight,
            child: Theme(
              data: _theme,
              child: Builder(
                builder: (context) {
                  final colors = context.playerColors;
                  final sample = diagnostics.snapshot;
                  final frames = sample.frames;
                  final process = sample.process;
                  return Container(
                    key: const ValueKey('avelune-debug-hud'),
                    width: 220,
                    margin: const EdgeInsets.all(10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: colors.background.withValues(alpha: .92),
                      border: Border.all(color: colors.outline),
                      borderRadius: BorderRadius.circular(PlayerRadii.sm),
                    ),
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.3,
                      child: DefaultTextStyle(
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 11,
                          fontFamily: 'monospace',
                          height: 1.45,
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'DEBUG · MOTEUR',
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'FPS ${_number(frames.fps)} · rendu ${_number(frames.latencyMs)} ms',
                            ),
                            Text('p95 ${_number(frames.p95Ms)} ms'),
                            Text(
                              'UI ${_number(frames.buildMs)} · raster ${_number(frames.rasterMs)} ms',
                            ),
                            Text(
                              'RAM ${_number(process.memoryMiB)} MiB${process.memoryKind == 'pss'
                                  ? ' (PSS)'
                                  : process.memoryKind == 'footprint'
                                  ? ' (empreinte)'
                                  : ''}',
                            ),
                            Text('CPU ${_number(sample.cpuPercent)} %'),
                            Text(
                              'Chauffe : ${_thermal(process.thermalState)}',
                              style: TextStyle(
                                color: switch (process.thermalState) {
                                  'serious' || 'critical' => colors.danger,
                                  'fair' => colors.warning,
                                  _ => colors.textPrimary,
                                },
                              ),
                            ),
                            Text(
                              'Économie : ${process.lowPowerMode == null
                                  ? 'N/D'
                                  : process.lowPowerMode!
                                  ? 'oui'
                                  : 'non'}',
                            ),
                            Text(
                              'Latence de rendu · CPU 100 % = 1 cœur',
                              style: TextStyle(
                                color: colors.textSecondary,
                                fontSize: 9,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
    },
  );

  static String _number(double? value) => value?.toStringAsFixed(1) ?? 'N/D';

  static String _thermal(String? state) => switch (state) {
    'nominal' => 'normale',
    'fair' => 'modérée',
    'serious' => 'élevée',
    'critical' => 'critique',
    _ => 'N/D',
  };
}
