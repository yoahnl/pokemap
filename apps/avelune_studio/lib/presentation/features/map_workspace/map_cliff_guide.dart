import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_border_drawing_draft.dart';
import '../../../features/map_workspace/application/map_cliff_levels.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'map_workspace_view_state.dart';

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

class MapCliffGuide extends StatelessWidget {
  const MapCliffGuide({
    super.key,
    required this.document,
    required this.view,
    required this.definition,
    required this.draft,
    required this.onChanged,
  });

  final EditableMapDocument document;
  final MapWorkspaceViewState view;
  final BorderBlueprintPublishedDefinition? definition;
  final MapBorderDrawingDraft? draft;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final state = mapCliffGuideState(
      map: document.current,
      definition: definition,
      draft: draft,
    );
    StudioTone tone(MapCliffStep step) => switch (step) {
      MapCliffStep.height => switch (state.step) {
        MapCliffStep.height => StudioTone.warning,
        MapCliffStep.review => StudioTone.success,
        _ => StudioTone.neutral,
      },
      MapCliffStep.profile =>
        state.step == MapCliffStep.profile
            ? StudioTone.info
            : StudioTone.success,
      MapCliffStep.contour => switch (state.step) {
        MapCliffStep.contour => StudioTone.info,
        MapCliffStep.profile => StudioTone.neutral,
        _ => StudioTone.success,
      },
      MapCliffStep.review =>
        state.step == MapCliffStep.review
            ? StudioTone.info
            : StudioTone.neutral,
    };
    return SingleChildScrollView(
      key: const ValueKey('map-cliff-guide'),
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          StudioButton(
            key: const ValueKey('map-cliff-relief'),
            label: 'Régler le relief',
            icon: Icons.terrain,
            secondary: true,
            onPressed: () {
              view.spatialTerrainMode = SpatialTerrainMode.relief;
              view.tool = StudioMapTool.terrain;
              onChanged();
            },
          ),
          const SizedBox(width: 10),
          for (final (step, label) in const [
            (MapCliffStep.height, '1 Hauteur'),
            (MapCliffStep.profile, '2 Profil'),
            (MapCliffStep.contour, '3 Contour'),
            (MapCliffStep.review, '4 Revue'),
          ]) ...[
            StudioBadge(
              label,
              key: ValueKey('map-cliff-step-${step.name}'),
              tone: tone(step),
            ),
            const SizedBox(width: 6),
          ],
          const SizedBox(width: 4),
          Text(
            state.message,
            key: const ValueKey('map-cliff-guide-message'),
            maxLines: 1,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
