import 'package:map_core/map_core.dart';

import 'map_border_drawing_draft.dart';
import 'map_cliff_levels.dart';

enum MapCliffStep { height, profile, contour, review }

final class MapCliffGuideState {
  const MapCliffGuideState(this.step, this.message, {this.levels});

  final MapCliffStep step;
  final String message;
  final MapCliffLevels? levels;
}

String _level(double value) => value == value.roundToDouble()
    ? value.round().toString()
    : value.toStringAsFixed(1);

String mapCliffLevelsSummary(MapCliffLevels levels) {
  final side = switch (levels.highSide) {
    MapCliffSide.left => 'paroi à gauche du tracé',
    MapCliffSide.right => 'paroi à droite du tracé',
    MapCliffSide.mixed => 'le côté haut change en chemin',
    null => 'aucun dénivelé',
  };
  final covered = levels.coveredDecorIds.length;
  return 'Bas ${_level(levels.lowLevel)} · haut ${_level(levels.highLevel)} · $side'
      '${covered == 0 ? '' : ' · $covered ${covered > 1 ? 'décors' : 'décor'} le long du tracé'}';
}

MapCliffGuideState mapCliffGuideState({
  required MapData map,
  required BorderBlueprintPublishedDefinition? definition,
  required MapBorderDrawingDraft? draft,
}) {
  if (definition == null) {
    return const MapCliffGuideState(
      MapCliffStep.profile,
      'Profil : choisissez un modèle de falaise publié.',
    );
  }
  if (draft == null || draft.anchors.length < 2) {
    return const MapCliffGuideState(
      MapCliffStep.contour,
      'Contour : cliquez sur la limite entre le bas et le haut, puis placez les angles.',
    );
  }
  final levels = mapCliffLevels(
    map,
    draft.anchors,
    alignment: draft.alignment,
    closed: draft.closed,
  );
  if (levels == null || levels.flat) {
    return MapCliffGuideState(
      MapCliffStep.height,
      'Hauteur : le sol est plat le long du tracé. Relevez un côté avec Relief avant d’appliquer.',
      levels: levels,
    );
  }
  return MapCliffGuideState(
    MapCliffStep.review,
    'Revue : ${mapCliffLevelsSummary(levels)}.',
    levels: levels,
  );
}
