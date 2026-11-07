import 'package:map_core/map_core_domain.dart';

String traversalDurationLabel(int milliseconds) {
  final seconds = milliseconds / 1000;
  final text = seconds == seconds.roundToDouble()
      ? seconds.toStringAsFixed(0)
      : seconds
            .toStringAsFixed(3)
            .replaceFirst(RegExp(r'0+$'), '')
            .replaceAll('.', ',');
  return '$text s';
}

String ledgeJumpSummary(BorderJumpBehavior jump) =>
    'Saut de ${jump.distanceCells} cases en ${traversalDurationLabel(jump.durationMs)}, '
    'hauteur ${jump.peakHeightPx} px. Le rebord ne se franchit que depuis le côté choisi ; '
    'l’autre côté reste bloquant.';
