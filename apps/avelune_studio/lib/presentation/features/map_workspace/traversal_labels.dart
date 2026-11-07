import 'package:map_core/map_core.dart';

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

String spatialLedgeSummary(SpatialLedge ledge) {
  final direction = switch (ledge.direction) {
    SpatialRampDirection.north => 'vers le haut',
    SpatialRampDirection.south => 'vers le bas',
    SpatialRampDirection.east => 'vers la droite',
    SpatialRampDirection.west => 'vers la gauche',
  };
  final height = ledge.height
      .toStringAsFixed(2)
      .replaceFirst(RegExp(r'\.?0+$'), '')
      .replaceAll('.', ',');
  return 'Saut de ${ledge.distance} cases $direction en '
      '${traversalDurationLabel(ledge.durationMs)}, hauteur $height case ; '
      'le retour est bloqué.';
}
