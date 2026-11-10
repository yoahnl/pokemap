import 'package:flutter/material.dart';
import 'package:map_core/map_core.dart';

import '../../../features/map_workspace/application/editable_map_document.dart';
import '../../../features/map_workspace/application/map_border_drawing_draft.dart';
import '../../../features/map_workspace/application/map_cliff_guidance.dart';

export '../../../features/map_workspace/application/map_cliff_guidance.dart';
import '../../../features/map_workspace/application/spatial_terrain_stroke.dart';
import '../../shared/widgets/buttons/studio_button.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'map_workspace_view_state.dart';

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
