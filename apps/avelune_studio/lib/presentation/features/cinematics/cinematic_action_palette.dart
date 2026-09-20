import 'package:flutter/material.dart';
import 'package:map_core/map_core_domain.dart';
import '../../shared/widgets/inputs/studio_choice.dart';
import '../../shared/widgets/feedback/studio_icon_tile.dart';
import '../../shared/widgets/feedback/studio_badge.dart';
import 'cinematic_labels.dart';

class CinematicActionPalette extends StatelessWidget {
  const CinematicActionPalette({super.key, required this.onAdd});
  final ValueChanged<CinematicTimelineStepKind> onAdd;
  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final kind in CinematicTimelineStepKind.values)
        SizedBox(
          width: 130,
          child: StudioChoice(
            label: cinematicActionLabel(kind),
            selected: false,
            leading: StudioIconTile(
              icon: cinematicActionIcon(kind),
              tone: switch (kind) {
                CinematicTimelineStepKind.actorMove => StudioTone.success,
                CinematicTimelineStepKind.wait ||
                CinematicTimelineStepKind.actorFace => StudioTone.warning,
                CinematicTimelineStepKind.camera ||
                CinematicTimelineStepKind.music => StudioTone.info,
                _ => StudioTone.feature,
              },
            ),
            onTap: () => onAdd(kind),
          ),
        ),
    ],
  );
}
